local AE_InitializationCoordinator = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

local initializationState = {
    started = false,
    completed = false,
    currentPhase = 0,
    onPlayerMoveTriggered = false,
    nextPhaseScheduled = false,
    nextPhaseNumber = 0,
    currentTickCount = 0,
    nextPhaseTickThreshold = 0
}

local configuration = {
    phaseDelayTicks = 30,
    verboseLogging = true,
    continueOnError = true,
    requiredSystems = {
        "AE_ModDataManager",
        "AE_NamespaceManager",
        "AE_AnimalRegistry"
    }
}

local phases = {
    [1] = {name = "Foundation", systems = {}},
    [2] = {name = "Detection", systems = {}},
    [3] = {name = "Core Gameplay", systems = {}},
    [4] = {name = "Subsystems", systems = {}},
    [5] = {name = "Cleanup", systems = {}},
    [6] = {name = "UI Systems", systems = {}}
}

local registeredSystems = {}

local function isRequiredSystem(systemName)
    for _, requiredName in ipairs(configuration.requiredSystems) do
        if requiredName == systemName then
            return true
        end
    end
    return false
end

local executePhaseInternal

local function phaseSchedulerTick()
    if not initializationState.nextPhaseScheduled then
        return
    end

    local success, errorMsg = pcall(function()
        initializationState.currentTickCount = initializationState.currentTickCount + 1

        if initializationState.currentTickCount >= initializationState.nextPhaseTickThreshold then
            if configuration.verboseLogging then
                print("[AE_InitCoordinator] Tick threshold reached, executing Phase " .. initializationState.nextPhaseNumber)
            end

            initializationState.nextPhaseScheduled = false
            initializationState.currentTickCount = 0
            local phaseToExecute = initializationState.nextPhaseNumber
            initializationState.nextPhaseNumber = 0
            initializationState.nextPhaseTickThreshold = 0
            executePhaseInternal(phaseToExecute)
        end
    end)

    if not success then
        print("[AE_InitCoordinator] ERROR in scheduler: " .. tostring(errorMsg))
        initializationState.nextPhaseScheduled = false
        initializationState.currentTickCount = 0
    end
end

local function scheduleNextPhase(nextPhaseNumber, delayTicks)
    if not phases[nextPhaseNumber] then
        print("[AE_InitCoordinator] ERROR: Cannot schedule invalid phase " .. tostring(nextPhaseNumber))
        return false
    end

    if configuration.verboseLogging then
        print("[AE_InitCoordinator] Scheduling Phase " .. nextPhaseNumber .. " in " .. delayTicks .. " ticks")
    end

    initializationState.nextPhaseScheduled = true
    initializationState.nextPhaseNumber = nextPhaseNumber
    initializationState.currentTickCount = 0
    initializationState.nextPhaseTickThreshold = delayTicks
    return true
end

local function validateDependencies(system)
    if not system.dependencies or #system.dependencies == 0 then
        return true
    end

    for _, dependencyName in ipairs(system.dependencies) do
        local dependency = registeredSystems[dependencyName]
        if not dependency then
            return false, "Dependency not registered: " .. dependencyName
        end
        if not dependency.initialized then
            return false, "Dependency not initialized: " .. dependencyName
        end
    end

    return true
end

local function initializeSystem(system)
    if system.initialized then
        return true
    end

    local dependenciesValid, dependencyError = validateDependencies(system)
    if not dependenciesValid then
        if configuration.verboseLogging then
            print("[AE_InitCoordinator] " .. system.name .. " - Dependencies not ready: " .. (dependencyError or "unknown"))
        end
        return false
    end

    local success, errorMsg = pcall(function()
        if type(system.initializeFunction) == "function" then
            local result = system.initializeFunction()
            if result == false then
                error("Initialization function returned false")
            end
        else
            error("Invalid initialization function")
        end
    end)

    if success then
        system.initialized = true
        system.initializationTime = getTimestamp()
        if configuration.verboseLogging then
            print("[AE_InitCoordinator] Phase " .. system.phase .. " - " .. system.name .. " initialized")
        end
        return true
    else
        if configuration.verboseLogging or isRequiredSystem(system.name) then
            print("[AE_InitCoordinator] ERROR: " .. system.name .. " failed - " .. tostring(errorMsg))
        end

        if isRequiredSystem(system.name) then
            print("[AE_InitCoordinator] CRITICAL: Required system " .. system.name .. " failed to initialize")
            if not configuration.continueOnError then
                error("Critical system initialization failed: " .. system.name)
            end
        end

        return false
    end
end

function executePhaseInternal(phaseNumber)
    if not phases[phaseNumber] then
        return
    end

    local phase = phases[phaseNumber]
    initializationState.currentPhase = phaseNumber

    if configuration.verboseLogging then
        print("[AE_InitCoordinator] Executing Phase " .. phaseNumber .. ": " .. phase.name)
    end

    local systemCount = #phase.systems
    local successCount = 0
    local failureCount = 0

    for _, system in ipairs(phase.systems) do
        if initializeSystem(system) then
            successCount = successCount + 1
        else
            failureCount = failureCount + 1
        end
    end

    if configuration.verboseLogging then
        print("[AE_InitCoordinator] Phase " .. phaseNumber .. " complete: " .. successCount .. " succeeded, " .. failureCount .. " failed")
    end

    local nextPhase = phaseNumber + 1
    if phases[nextPhase] and #phases[nextPhase].systems > 0 then
        scheduleNextPhase(nextPhase, configuration.phaseDelayTicks)
    else
        initializationState.completed = true
        print("[AE_InitCoordinator] All phases complete")
    end
end

function AE_InitializationCoordinator.registerSystem(phase, systemName, initializeFunction, dependencies)
    if not phases[phase] then
        print("[AE_InitCoordinator] ERROR: Invalid phase " .. tostring(phase))
        return false
    end

    if type(initializeFunction) ~= "function" then
        print("[AE_InitCoordinator] ERROR: " .. systemName .. " - initializeFunction must be a function")
        return false
    end

    if registeredSystems[systemName] then
        print("[AE_InitCoordinator] WARNING: " .. systemName .. " already registered, skipping")
        return false
    end

    local system = {
        name = systemName,
        phase = phase,
        initializeFunction = initializeFunction,
        dependencies = dependencies or {},
        initialized = false,
        initializationTime = 0
    }

    registeredSystems[systemName] = system
    table.insert(phases[phase].systems, system)

    if configuration.verboseLogging then
        print("[AE_InitCoordinator] Registered: " .. systemName .. " (Phase " .. phase .. ")")
    end

    return true
end

function AE_InitializationCoordinator.startInitialization()
    if initializationState.started then
        return
    end

    initializationState.started = true

    print("[AE_InitCoordinator] Starting phased initialization...")

    local totalSystems = 0
    for phaseNum, phase in pairs(phases) do
        totalSystems = totalSystems + #phase.systems
    end
    print("[AE_InitCoordinator] Total systems registered: " .. totalSystems)

    if AE_EnvironmentDetector then
        if configuration.verboseLogging then
            print("[AE_InitCoordinator] Triggering environment detection...")
        end

        local detectionSuccess, detectionError = pcall(function()
            local isSP = AE_EnvironmentDetector.isSinglePlayer()
            local isMP = AE_EnvironmentDetector.isMultiplayer()

            if configuration.verboseLogging then
                local envType = isSP and "SinglePlayer" or (isMP and "Multiplayer" or "Unknown")
                print("[AE_InitCoordinator] Environment detected: " .. envType)
            end
        end)

        if not detectionSuccess then
            print("[AE_InitCoordinator] WARNING: Environment detection had issues: " .. tostring(detectionError))
        end
    end

    if Events and Events.OnTick then
        Events.OnTick.Add(phaseSchedulerTick)
        print("[AE_InitCoordinator] Phase scheduler hooked to OnTick")
    else
        print("[AE_InitCoordinator] ERROR: Events.OnTick not available, scheduler cannot run!")
        return false
    end

    if phases[1] and #phases[1].systems > 0 then
        executePhaseInternal(1)
    else
        print("[AE_InitCoordinator] No systems registered in Phase 1")
        initializationState.completed = true
    end
end

function AE_InitializationCoordinator.onPlayerMove(player)
    if initializationState.onPlayerMoveTriggered then
        return
    end

    initializationState.onPlayerMoveTriggered = true

    if configuration.verboseLogging then
        print("[AE_InitCoordinator] OnPlayerMove triggered - beginning initialization sequence")
    end

    AE_InitializationCoordinator.startInitialization()
end

function AE_InitializationCoordinator.getStatus()
    return {
        started = initializationState.started,
        completed = initializationState.completed,
        currentPhase = initializationState.currentPhase,
        totalSystems = #registeredSystems,
        initializedSystems = (function()
            local count = 0
            for _, system in pairs(registeredSystems) do
                if system.initialized then
                    count = count + 1
                end
            end
            return count
        end)()
    }
end

function AE_InitializationCoordinator.setConfiguration(config)
    if config.phaseDelayTicks then
        configuration.phaseDelayTicks = config.phaseDelayTicks
    end
    if config.verboseLogging ~= nil then
        configuration.verboseLogging = config.verboseLogging
    end
    if config.continueOnError ~= nil then
        configuration.continueOnError = config.continueOnError
    end
end

function AE_InitializationCoordinator.getSystemStatus(systemName)
    local system = registeredSystems[systemName]
    if not system then
        return nil
    end

    return {
        name = system.name,
        phase = system.phase,
        initialized = system.initialized,
        initializationTime = system.initializationTime,
        dependencies = system.dependencies
    }
end

if Events and Events.OnPlayerMove then
    Events.OnPlayerMove.Add(AE_InitializationCoordinator.onPlayerMove)
end

return AE_InitializationCoordinator
