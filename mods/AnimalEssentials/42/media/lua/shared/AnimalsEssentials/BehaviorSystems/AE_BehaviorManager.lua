-- CONVERTED: AE_BehaviorManager.lua
-- SESSION 3C: All ModData access replaced with AE_DataService calls
-- SESSION 4B: Inter-mod communication implementation

local AE_BehaviorManager = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
local AnimalRegistry = nil
local AE_CoreCommunication = nil
local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")

-- External dependencies (via inter-mod communication)
local Config = nil
local CommandsSystem = nil

-- Behavior system modules
local HomeLocation = nil
local WanderLust = nil
local ReturnHome = nil
local Flee = nil
local VirtualTracker = nil
local Retaliatory = nil
local Hostility = nil
local StuckDetection = nil

local Foraging = nil

-- Initialization state tracking
AE_BehaviorManager.isInitialized = false
AE_BehaviorManager.dependenciesLoaded = false
AE_BehaviorManager.initializationAttempted = false

-- ARCHITECTURAL FIX: Full initialization validation
AE_BehaviorManager.isFullyInitialized = function()
    return AE_BehaviorManager.isInitialized and 
           AE_BehaviorManager.dependenciesLoaded and
           AnimalRegistry and 
           AE_DataService and
           HomeLocation and
           WanderLust and
           ReturnHome and
           Flee and
           VirtualTracker and
           Retaliatory and
           Hostility and
           StuckDetection
end

-- Initialize local dependencies within FrameworkCore
AE_BehaviorManager.initializeLocalDependencies = function()
    local success, result
    
    -- Load AnimalRegistry from same mod
    success, result = pcall(function()
        return require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
    end)
    if success and result then
        AnimalRegistry = result
    end
    
    -- Load CoreCommunication from same mod
    success, result = pcall(function()
        return require("AnimalsEssentials/Communication/AE_CoreCommunication")
    end)
    if success and result then
        AE_CoreCommunication = result
    end
    
    -- Load all behavior system modules with error handling
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/Core/AE_Foraging")
    end)
    if success and result then
        Foraging = result
    end
    
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/Core/AE_HomeLocation")
    end)
    if success and result then
        HomeLocation = result
    end
    
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/Core/AE_WanderLust")
    end)
    if success and result then
        WanderLust = result
    end
    
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/Core/AE_ReturnHome")
    end)
    if success and result then
        ReturnHome = result
    end
    
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/Core/AE_Flee")
    end)
    if success and result then
        Flee = result
    end
    
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/Core/AE_StuckDetection")
    end)
    if success and result then
        StuckDetection = result
    end
    
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/Aggression/AE_Retaliatory")
    end)
    if success and result then
        Retaliatory = result
    end
    
    -- PHASE 1B: CommandsSystem integration for hunting priority coordination
    success, result = pcall(function()
        return require("AnimalsEssentials/CoreSystems/AE_CommandsSystem")
    end)
    if success and result then
        CommandsSystem = result
        print("[AE_BehaviorManager] CommandsSystem loaded successfully")
    else
        print("[AE_BehaviorManager] WARNING: CommandsSystem not available - manual command coordination disabled")
    end
    
    success, result = pcall(function()
        if AE_EnvironmentDetector.isSinglePlayer() then
            return require("AnimalsEssentials/BehaviorSystems/Aggression/AE_Hostility")
        else
            if not isClient() then
                return require("AnimalsEssentials/BehaviorSystems/Aggression/AE_Hostility")
            else
                -- Client should not have access to hostility system - return nil
                return nil
            end
        end
    end)
    if success and result then
        Hostility = result
    end
    
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/AE_VirtualTracker")
    end)
    if success and result then
        VirtualTracker = result
    end
    
    AE_BehaviorManager.dependenciesLoaded = true
end

-- Initialize inter-mod communication
AE_BehaviorManager.initializeInterModCommunication = function()
    if not AE_CoreCommunication then
        return false
    end
    
    -- Request Config data from FrameworkData mod
    AE_CoreCommunication.requestConfig = function(callback)
        AE_CoreCommunication.requestData("Config", nil, callback)
    end
    
    -- Request CommandsSystem data from FrameworkData mod  
    AE_CoreCommunication.requestCommandExecution = function(animal, command, callback)
        AE_CoreCommunication.requestData("CommandExecution", {
            animal = animal,
            command = command
        }, callback)
    end
    
    return true
end

local managedAnimals = {}
local lastUpdateTimes = {}
local UPDATE_FREQUENCY_TICKS = 30
local UPDATE_LIMIT_PER_TICK = 6
local MAX_TICKS_PER_UPDATE = 3
local nextAnimalIndex = 1
local animalProcessingOrder = {}
local performanceStats = {
    lastTickCount = 0,
    avgTickCount = 0,
    processedThisTick = 0,
    skippedThisTick = 0,
}

-- PHASE 3: Enhanced performance monitoring
local performanceMonitoring = {
    enabled = true,
    sampleWindow = 300,  -- 5 seconds of samples at 60fps
    samples = {},
    thresholds = {
        warningTickCount = MAX_TICKS_PER_UPDATE * 1.5,
        criticalTickCount = MAX_TICKS_PER_UPDATE * 2,
        warningProcessingTime = 16.67,  -- 1 frame at 60fps
        criticalProcessingTime = 33.33   -- 2 frames at 60fps
    }
}

-- PHASE 3: Health monitoring variables
local healthCheckCounter = 0
local HEALTH_CHECK_FREQUENCY = 1800  -- Every 30 seconds at 60fps

-- PHASE 1 SPAM FIX: Smart logging level system
local BehaviorManagerLogging = {
    enabled = true,
    logMissingFunctions = false,  -- Disable spam for missing functions
    logErrors = true,             -- Keep error logging for real issues
    logSuccess = false,           -- Disable success logging for performance
    logWarnings = true           -- Keep warnings for unexpected issues
}

-- Expected missing functions that should not generate warnings
local ExpectedMissingFunctions = {
    ["Update"] = true,           -- Update functions are optional for placeholder modules
    ["GetState"] = true,         -- Some modules may not have state queries
    ["OnComplete"] = true,       -- Optional completion handlers
    ["GetTarget"] = true,        -- Optional target queries
    ["IsActive"] = true          -- Optional activity state queries
}

local tickCounter = 0
local registrationTickCounter = 0
local REGISTRATION_SCAN_FREQUENCY = 150

-- PHASE 1+2 ARCHITECTURAL FIX: Dependency validation framework
local function validateCriticalDependencies()
    local missing = {}
    
    if not AnimalRegistry then table.insert(missing, "AnimalRegistry") end
    if not AE_DataService then table.insert(missing, "AE_DataService") end
    if not HomeLocation then table.insert(missing, "HomeLocation") end
    if not WanderLust then table.insert(missing, "WanderLust") end
    if not ReturnHome then table.insert(missing, "ReturnHome") end
    if not Flee then table.insert(missing, "Flee") end
    if not VirtualTracker then table.insert(missing, "VirtualTracker") end
    if not Retaliatory then table.insert(missing, "Retaliatory") end
    if not Hostility then table.insert(missing, "Hostility") end
    if not StuckDetection then table.insert(missing, "StuckDetection") end
    
    return #missing == 0, missing
end

local function validateOptionalDependencies()
    return {
        config = Config ~= nil,
        commands = CommandsSystem ~= nil,
        foraging = Foraging ~= nil,
        communication = AE_CoreCommunication ~= nil
    }
end

local function getDependencyReport()
    local criticalReady, missingCritical = validateCriticalDependencies()
    local optionalStatus = validateOptionalDependencies()
    
    return {
        criticalReady = criticalReady,
        missingCritical = missingCritical,
        optionalStatus = optionalStatus,
        systemReady = criticalReady and AE_BehaviorManager.isInitialized,
        timestamp = getTimestamp()
    }
end

-- PHASE 1 SPAM FIX: Logging configuration management
AE_BehaviorManager.setLoggingLevel = function(config)
    if config.logMissingFunctions ~= nil then
        BehaviorManagerLogging.logMissingFunctions = config.logMissingFunctions
    end
    if config.logErrors ~= nil then
        BehaviorManagerLogging.logErrors = config.logErrors
    end
    if config.logWarnings ~= nil then
        BehaviorManagerLogging.logWarnings = config.logWarnings
    end
    if config.enabled ~= nil then
        BehaviorManagerLogging.enabled = config.enabled
    end
    
    return BehaviorManagerLogging
end

AE_BehaviorManager.getLoggingConfig = function()
    return {
        enabled = BehaviorManagerLogging.enabled,
        logMissingFunctions = BehaviorManagerLogging.logMissingFunctions,
        logErrors = BehaviorManagerLogging.logErrors,
        logWarnings = BehaviorManagerLogging.logWarnings,
        expectedMissingFunctions = ExpectedMissingFunctions
    }
end

-- PHASE 2 ARCHITECTURAL FIX: Safe behavior system function calls
local function safeCallBehaviorFunction(behaviorModule, functionName, ...)
    -- PHASE 1 SPAM FIX: Enhanced safe calling with smart logging
    if not behaviorModule then
        if BehaviorManagerLogging.enabled and BehaviorManagerLogging.logErrors then
            print("[AE_BehaviorManager] ERROR: Behavior module is nil for " .. tostring(functionName))
        end
        return nil, false
    end
    
    if not behaviorModule[functionName] then
        -- PHASE 1 SPAM FIX: Only warn for unexpected missing functions
        if BehaviorManagerLogging.enabled and BehaviorManagerLogging.logMissingFunctions and not ExpectedMissingFunctions[functionName] then
            print("[AE_BehaviorManager] WARNING: Function " .. tostring(functionName) .. " not found on behavior module")
        elseif BehaviorManagerLogging.enabled and BehaviorManagerLogging.logWarnings and not ExpectedMissingFunctions[functionName] then
            print("[AE_BehaviorManager] WARNING: Unexpected missing function " .. tostring(functionName))
        end
        return nil, false
    end
    
    local success, result = pcall(behaviorModule[functionName], ...)
    if not success then
        if BehaviorManagerLogging.enabled and BehaviorManagerLogging.logErrors then
            print("[AE_BehaviorManager] ERROR in " .. tostring(functionName) .. ": " .. tostring(result))
        end
        return nil, false
    end
    
    return result, true
end

local function safeBatchInitialize(animal, animalID)
    local results = {}
    local overallSuccess = true
    
    local initOperations = {
        {HomeLocation, "Initialize", animal},
        {WanderLust, "Initialize", animal},
        {ReturnHome, "Initialize", animal},
        {Flee, "Initialize", animal},
        {Retaliatory, "Initialize", animal},
        {Hostility, "Initialize", animal},
        {StuckDetection, "Initialize", animal},
        {VirtualTracker, "Initialize", animal, animalID}
    }
    
    for i, operation in ipairs(initOperations) do
        local module, func, arg1, arg2 = operation[1], operation[2], operation[3], operation[4]
        local result, success = safeCallBehaviorFunction(module, func, arg1, arg2)
        
        results[i] = {
            module = tostring(module),
            function_name = func,
            success = success,
            result = result
        }
        
        if not success then
            overallSuccess = false
        end
    end
    
    return results, overallSuccess
end

-- PHASE 3: Enhanced performance monitoring functions
local function recordPerformanceSample(ticksUsed, processingTimeMs, animalsProcessed)
    if not performanceMonitoring.enabled then return end
    
    local sample = {
        timestamp = getTimestamp(),
        ticksUsed = ticksUsed,
        processingTime = processingTimeMs,
        animalsProcessed = animalsProcessed,
        efficiency = animalsProcessed / math.max(1, ticksUsed)
    }
    
    table.insert(performanceMonitoring.samples, sample)
    
    -- Maintain sample window size
    if #performanceMonitoring.samples > performanceMonitoring.sampleWindow then
        table.remove(performanceMonitoring.samples, 1)
    end
    
    -- Check performance thresholds
    if ticksUsed > performanceMonitoring.thresholds.criticalTickCount then
        print("[AE_BehaviorManager] PERFORMANCE CRITICAL: " .. ticksUsed .. " ticks used")
    elseif ticksUsed > performanceMonitoring.thresholds.warningTickCount then
        print("[AE_BehaviorManager] PERFORMANCE WARNING: " .. ticksUsed .. " ticks used")
    end
end

-- PHASE 3: System recovery mechanisms
local function attemptSystemRecovery()
    print("[AE_BehaviorManager] Attempting automatic system recovery...")
    
    local recoveryStartTime = getTimestamp()
    local recoverySteps = {}
    
    -- Step 1: Re-attempt initialization
    if not AE_BehaviorManager.isInitialized then
        print("[AE_BehaviorManager] Recovery Step 1: Re-initializing system...")
        local initSuccess = AE_BehaviorManager.initialize()
        table.insert(recoverySteps, {step = "initialization", success = initSuccess})
    end
    
    -- Step 2: Validate critical dependencies
    local dependencyReport = getDependencyReport()
    table.insert(recoverySteps, {step = "dependency_validation", success = dependencyReport.criticalReady})
    
    -- Step 3: Re-load missing behavior modules
    if not dependencyReport.criticalReady then
        print("[AE_BehaviorManager] Recovery Step 3: Re-loading dependencies...")
        AE_BehaviorManager.initializeLocalDependencies()
        
        -- Re-validate after dependency reload
        dependencyReport = getDependencyReport()
        table.insert(recoverySteps, {step = "dependency_reload", success = dependencyReport.criticalReady})
    end
    
    -- Step 4: Validate managed animals
    local animalValidationSuccess = true
    local invalidAnimals = {}
    for animalID, animal in pairs(managedAnimals) do
        if not animal or not AE_DataService.isAnimalValid(animal) then
            table.insert(invalidAnimals, animalID)
            animalValidationSuccess = false
        end
    end
    
    -- Clean up invalid animals
    for _, animalID in ipairs(invalidAnimals) do
        AE_BehaviorManager.RemoveAnimal(animalID)
    end
    
    table.insert(recoverySteps, {step = "animal_validation", success = animalValidationSuccess, cleaned = #invalidAnimals})
    
    local recoveryEndTime = getTimestamp()
    local recoveryDuration = recoveryEndTime - recoveryStartTime
    
    print("[AE_BehaviorManager] Recovery completed in " .. recoveryDuration .. "ms")
    
    return {
        success = dependencyReport.criticalReady,
        duration = recoveryDuration,
        steps = recoverySteps
    }
end

-- PHASE 3: Graceful degradation strategy
local function enableGracefulDegradation()
    print("[AE_BehaviorManager] Enabling graceful degradation mode...")
    
    -- Disable non-critical features
    local degradationConfig = {
        disablePerformanceTracking = true,
        reduceUpdateFrequency = true,
        disableVirtualTracking = true,
        basicBehaviorOnly = true
    }
    
    -- Modify update frequency for degraded mode
    if degradationConfig.reduceUpdateFrequency then
        UPDATE_FREQUENCY_TICKS = UPDATE_FREQUENCY_TICKS * 2  -- Half the frequency
        UPDATE_LIMIT_PER_TICK = math.max(1, UPDATE_LIMIT_PER_TICK / 2)  -- Half the processing
    end
    
    return degradationConfig
end

-- PHASE 3: Comprehensive system health monitoring
AE_BehaviorManager.performHealthCheck = function()
    local currentTime = getTimestamp()
    local dependencyReport = getDependencyReport()
    
    local health = {
        timestamp = currentTime,
        systemReady = dependencyReport.systemReady,
        criticalReady = dependencyReport.criticalReady,
        missingCritical = dependencyReport.missingCritical,
        optionalStatus = dependencyReport.optionalStatus,
        managedAnimals = #animalProcessingOrder,
        initializationState = {
            isInitialized = AE_BehaviorManager.isInitialized,
            dependenciesLoaded = AE_BehaviorManager.dependenciesLoaded,
            initializationAttempted = AE_BehaviorManager.initializationAttempted
        },
        performanceMetrics = {
            lastTickCount = performanceStats.lastTickCount,
            avgTickCount = performanceStats.avgTickCount,
            processedThisTick = performanceStats.processedThisTick,
            skippedThisTick = performanceStats.skippedThisTick
        }
    }
    
    -- Health status determination
    health.status = "HEALTHY"
    if not health.criticalReady then
        health.status = "CRITICAL"
    elseif health.managedAnimals > 0 and not health.systemReady then
        health.status = "DEGRADED"
    elseif health.performanceMetrics.avgTickCount > MAX_TICKS_PER_UPDATE * 2 then
        health.status = "PERFORMANCE_WARNING"
    end
    
    return health
end

-- PHASE 3: Periodic health monitoring
local function periodicHealthCheck()
    healthCheckCounter = healthCheckCounter + 1
    
    if healthCheckCounter >= HEALTH_CHECK_FREQUENCY then
        local health = AE_BehaviorManager.performHealthCheck()
        
        if health.status ~= "HEALTHY" then
            print("[AE_BehaviorManager] HEALTH WARNING: System status is " .. health.status)
            
            if health.status == "CRITICAL" then
                print("  Missing critical dependencies: " .. table.concat(health.missingCritical, ", "))
                -- Trigger automatic recovery
                attemptSystemRecovery()
            end
        end
        
        healthCheckCounter = 0
    end
end

-- PHASE 3: Performance analysis function
AE_BehaviorManager.getPerformanceAnalysis = function()
    if #performanceMonitoring.samples == 0 then
        return {error = "No performance samples available"}
    end
    
    local totalTicks = 0
    local totalProcessingTime = 0
    local totalAnimals = 0
    local maxTicks = 0
    local maxProcessingTime = 0
    
    for _, sample in ipairs(performanceMonitoring.samples) do
        totalTicks = totalTicks + sample.ticksUsed
        totalProcessingTime = totalProcessingTime + sample.processingTime
        totalAnimals = totalAnimals + sample.animalsProcessed
        maxTicks = math.max(maxTicks, sample.ticksUsed)
        maxProcessingTime = math.max(maxProcessingTime, sample.processingTime)
    end
    
    local sampleCount = #performanceMonitoring.samples
    
    return {
        averageTicks = totalTicks / sampleCount,
        averageProcessingTime = totalProcessingTime / sampleCount,
        averageAnimalsPerSample = totalAnimals / sampleCount,
        peakTicks = maxTicks,
        peakProcessingTime = maxProcessingTime,
        efficiency = totalAnimals / math.max(1, totalTicks),
        sampleCount = sampleCount,
        timeSpanMs = performanceMonitoring.samples[sampleCount].timestamp - performanceMonitoring.samples[1].timestamp
    }
end

-- Defensive wrapper for AnimalRegistry scanning operations
local function safeScanNearbyAnimals(player, range)
    if not AnimalRegistry or not AnimalRegistry.ScanNearbyAnimals then
        return {}
    end
    
    local success, animals = pcall(function()
        return AnimalRegistry.ScanNearbyAnimals(player, range)
    end)
    
    return success and animals or {}
end

-- Helper: Check if animal is already managed (by object reference) --
-- @param animal - the IsoAnimal object to check
-- @return boolean, string - (isManaged, animalID)
local function isAnimalAlreadyManaged(animal)
    if not animal then return false, nil end
    for id, managedAnimal in pairs(managedAnimals) do
        if managedAnimal == animal then
            return true, id
        end
    end
    return false, nil
end

-- CONVERTED: Initialize behavior systems for an animal with AE_DataService
-- @param animal - the IsoAnimal object
-- @return boolean - true if successful
function AE_BehaviorManager.InitializeAnimal(animal)
    if not animal then
        print("[AE_BehaviorManager] ERROR: Animal parameter is nil")
        return false
    end
    
    -- PHASE 1+2: Dependency validation with auto-recovery
    local dependencyReport = getDependencyReport()
    if not dependencyReport.criticalReady then
        print("[AE_BehaviorManager] ERROR: Critical dependencies missing: " .. table.concat(dependencyReport.missingCritical, ", "))
        
        -- Attempt emergency initialization if not already attempted
        if not AE_BehaviorManager.isInitialized then
            print("[AE_BehaviorManager] Attempting emergency initialization...")
            local initResult = AE_BehaviorManager.initialize()
            
            -- Re-validate after emergency init
            dependencyReport = getDependencyReport()
            if not dependencyReport.criticalReady then
                print("[AE_BehaviorManager] CRITICAL: Emergency initialization failed - missing: " .. 
                      table.concat(dependencyReport.missingCritical, ", "))
                return false
            end
        else
            print("[AE_BehaviorManager] CRITICAL: System initialized but dependencies still missing")
            return false
        end
    end
    
    -- PHASE 2: Animal validation with safe AnimalRegistry calls
    local alreadyManaged, existingID = isAnimalAlreadyManaged(animal)
    if alreadyManaged then
        return true
    end
    
    local success, animalType = pcall(function()
        return animal:getAnimalType()
    end)
    
    if not success then
        print("[AE_BehaviorManager] ERROR: Cannot get animal type - animal may be invalid")
        return false
    end
    
    local isCat = (animalType == "kttr" or animalType == "kttrmanx" or 
                  animalType == "smokeykttr")
    
    -- Safe AnimalRegistry call with validation
    local isFrameworkAnimal = false
    if AnimalRegistry and AnimalRegistry.IsFrameworkAnimal then
        local success, result = pcall(AnimalRegistry.IsFrameworkAnimal, animal)
        if success then
            isFrameworkAnimal = result
        else
            print("[AE_BehaviorManager] WARNING: AnimalRegistry.IsFrameworkAnimal failed: " .. tostring(result))
        end
    end
    
    if not isFrameworkAnimal and not isCat then
        return false
    end
    
    -- CONVERTED: Use AE_DataService for animal validation and data access
    if not AE_DataService.isAnimalValid(animal) then
        return false
    end
    
    -- CONVERTED: Use AE_DataService instead of direct ModData access
    local animalID = AE_DataService.getStableID(animal)
    local isTamed = AE_DataService.isTamed(animal)
    
    if not animalID or animalID == "" or animalID == "unnamed" then
        if isCat then
            animalID = "wild_" .. tostring(animal:getOnlineID())
        else
            return false
        end
    end
    
    if managedAnimals[animalID] then
        if managedAnimals[animalID] ~= animal then
            animalID = animalID .. "_" .. tostring(os.time())
        else
            return true
        end
    end
    
    -- PHASE 2: Safe behavior system initialization
    local initResults, initSuccess = safeBatchInitialize(animal, animalID)
    
    if not initSuccess then
        print("[AE_BehaviorManager] WARNING: Some behavior systems failed initialization:")
        for i, result in ipairs(initResults) do
            if not result.success then
                print("  - " .. result.module .. "." .. result.function_name .. " failed")
            end
        end
    end
    
    -- PHASE 2: Registration and tracking
    managedAnimals[animalID] = animal
    lastUpdateTimes[animalID] = getTimestamp()  -- Use proper timing function
    table.insert(animalProcessingOrder, animalID)
    
    -- PHASE 2: Optional pathfinding initialization (existing code)
    if animal.pathToLocation then
        local currentX = animal:getX()
        local currentY = animal:getY()
        local currentZ = animal:getZ()
        local offsetX = ZombRand(-9, 10)
        local offsetY = ZombRand(-9, 10)
        local targetX = math.floor(currentX + offsetX)
        local targetY = math.floor(currentY + offsetY)
        if targetX >= 0 and targetY >= 0 then
            animal:pathToLocation(targetX, targetY, currentZ)
        end
    end
    
    return true
end

-- Remove animal from management (on death/despawn) --
-- @param animalID - the animal's stable ID
function AE_BehaviorManager.RemoveAnimal(animalID)
    if managedAnimals[animalID] then
        managedAnimals[animalID] = nil
        lastUpdateTimes[animalID] = nil
        safeCallBehaviorFunction(VirtualTracker, "Remove", animalID)
        for i, id in ipairs(animalProcessingOrder) do
            if id == animalID then
                table.remove(animalProcessingOrder, i)
                break
            end
        end
    end
end

-- CONVERTED: Get current behavior state for an animal with AE_DataService
-- @param animal - the IsoAnimal object
-- @return string - behavior state name
function AE_BehaviorManager.GetCurrentBehavior(animal)
    if not animal then return "none" end
    
    -- PHASE 2: Validate dependencies before behavior queries
    local dependencyReport = getDependencyReport()
    if not dependencyReport.criticalReady then
        print("[AE_BehaviorManager] WARNING: Cannot query behaviors - dependencies not ready")
        return "system_not_ready"
    end
    
    -- PHASE 2: Safe foraging behavior check
    if Foraging then
        local animalID = AE_DataService.getStableID(animal)
        if animalID then
            local hasActive, success = safeCallBehaviorFunction(Foraging, "HasActiveForaging", animalID)
            if success and hasActive then
                local foragingState, stateSuccess = safeCallBehaviorFunction(Foraging, "GetForagingState", animalID)
                if stateSuccess and foragingState then
                    return "foraging_" .. foragingState
                end
            end
        end
    end
    
    -- PHASE 2: Safe behavior state checks with validation
    local isFighting, success = safeCallBehaviorFunction(Retaliatory, "IsFighting", animal)
    if success and isFighting then
        return "retaliatory_fight"
    end
    
    local isFleeing, success = safeCallBehaviorFunction(Retaliatory, "IsFleeing", animal)
    if success and isFleeing then
        return "retaliatory_flight"
    end
    
    local isEngaged, success = safeCallBehaviorFunction(Hostility, "IsEngaged", animal)
    if success and isEngaged then
        return "hostile_engagement"
    end
    
    local isFleeingGeneral, success = safeCallBehaviorFunction(Flee, "IsFleeing", animal)
    if success and isFleeingGeneral then
        return "fleeing"
    end
    
    local isReturning, success = safeCallBehaviorFunction(ReturnHome, "IsReturning", animal)
    if success and isReturning then
        return "returning_home"
    end
    
    local isResting, success = safeCallBehaviorFunction(ReturnHome, "IsResting", animal)
    if success and isResting then
        return "resting"
    end
    
    local isWandering, success = safeCallBehaviorFunction(WanderLust, "IsWandering", animal)
    if success and isWandering then
        return "wandering"
    end
    
    return "idle"
end

-- Get movement target for an animal based on current behavior --
-- @param animal - the IsoAnimal object
-- @return number, number - targetX, targetY or nil
function AE_BehaviorManager.GetMovementTarget(animal)
    if not animal then return nil, nil end
    
    -- PHASE 2: Validate dependencies before movement queries
    local dependencyReport = getDependencyReport()
    if not dependencyReport.criticalReady then
        print("[AE_BehaviorManager] WARNING: Cannot get movement target - dependencies not ready")
        return nil, nil
    end
    
    local behavior = AE_BehaviorManager.GetCurrentBehavior(animal)
    
    -- Handle foraging behaviors with highest priority
    if behavior:find("foraging_") then
        -- Foraging behaviors use internal pathfinding, don't override
        return nil, nil
    end
    
    -- PHASE 2: Safe movement target queries with validation
    if behavior == "retaliatory_fight" then
        local target, success = safeCallBehaviorFunction(Retaliatory, "GetFightTarget", animal)
        if success and target then
            return target:getX(), target:getY()
        end
    elseif behavior == "retaliatory_flight" then
        local targetX, targetY, success = safeCallBehaviorFunction(Retaliatory, "GetFleeTarget", animal)
        if success then
            return targetX, targetY
        end
    elseif behavior == "hostile_engagement" then
        local targetX, targetY, success = safeCallBehaviorFunction(Hostility, "GetTargetPosition", animal)
        if success then
            return targetX, targetY
        end
    elseif behavior == "fleeing" then
        local targetX, targetY, success = safeCallBehaviorFunction(Flee, "GetFleeTarget", animal)
        if success then
            return targetX, targetY
        end
    elseif behavior == "returning_home" then
        local targetX, targetY, success = safeCallBehaviorFunction(ReturnHome, "GetHomeTarget", animal)
        if success then
            return targetX, targetY
        end
    elseif behavior == "wandering" then
        local targetX, targetY, success = safeCallBehaviorFunction(WanderLust, "GetTarget", animal)
        if success then
            return targetX, targetY
        end
    end
    return nil, nil
end

-- CONVERTED: Update behaviors for a single animal with AE_DataService
-- @param animal - the IsoAnimal object
-- @param animalID - the animal's stable ID
-- @param deltaSeconds - time elapsed in seconds
-- @param deltaMinutes - time elapsed in minutes
local function updateAnimalBehaviors(animal, animalID, deltaSeconds, deltaMinutes)
    -- PHASE 2: Validate dependencies before update
    local dependencyReport = getDependencyReport()
    if not dependencyReport.criticalReady then
        print("[AE_BehaviorManager] ERROR: Cannot update behaviors - dependencies not ready")
        return false
    end
    
    -- PHASE 2: Defensive timing validation
    if not deltaSeconds or not deltaMinutes or 
       type(deltaSeconds) ~= "number" or type(deltaMinutes) ~= "number" or
       deltaSeconds < 0 or deltaMinutes < 0 then
        print("[AE_BehaviorManager] ERROR: Invalid timing parameters")
        return false
    end
    
    -- PHASE 2: Safe VirtualTracker operations
    safeCallBehaviorFunction(VirtualTracker, "UpdateRenderState", animal, animalID)
    local virtualState, success = safeCallBehaviorFunction(VirtualTracker, "GetState", animalID)
    local inRender = success and virtualState and virtualState.inRender or false
    local isForaging = false
    
    -- PHASE 2: Safe foraging check and update
    if Foraging then
        local stableID = AE_DataService.getStableID(animal)
        if stableID then
            local hasActive, success = safeCallBehaviorFunction(Foraging, "HasActiveForaging", stableID)
            isForaging = success and hasActive or false
            if isForaging then
                safeCallBehaviorFunction(Foraging, "Update", animal, stableID, deltaMinutes)
                return true
            end
        end
    end
    
    -- PHASE 2: Safe behavior updates
    safeCallBehaviorFunction(HomeLocation, "Update", animal)
    safeCallBehaviorFunction(Retaliatory, "Update", animal, deltaSeconds)
    
    -- PHASE 2: Safe command system check
    local hasManualCommand = false
    if CommandsSystem then
        local hasCommand, success = safeCallBehaviorFunction(CommandsSystem, "HasManualCommand", animalID)
        hasManualCommand = success and hasCommand or false
    end
    
    if hasManualCommand and not isForaging then
        local isEngaged, success = safeCallBehaviorFunction(Hostility, "IsEngaged", animal)
        if success and isEngaged then
            safeCallBehaviorFunction(Hostility, "Disengage", animal)
        end
    end
    
    safeCallBehaviorFunction(Hostility, "Update", animal, deltaSeconds)
    safeCallBehaviorFunction(Flee, "Update", animal, deltaSeconds)
    safeCallBehaviorFunction(ReturnHome, "Update", animal)
    
    -- Only update WanderLust if animal is not actively foraging
    if not isForaging then
        safeCallBehaviorFunction(WanderLust, "Update", animal, deltaMinutes)
    end
    
    local wanderState, success = safeCallBehaviorFunction(WanderLust, "GetState", animal)
    if success and wanderState and not wanderState.isActive and wanderState.scale < 10 then
        local previousScale = wanderState.previousScale or 0
        if previousScale > 90 then
            safeCallBehaviorFunction(ReturnHome, "OnWanderCompleted", animal)
        end
        wanderState.previousScale = wanderState.scale
    end
    
    if not isForaging then
        safeCallBehaviorFunction(StuckDetection, "Update", animal, deltaSeconds)
    end
    
    -- PHASE 2: Safe speed calculation and movement handling
    local speedMultiplier = 1.0
    local currentBehavior = AE_BehaviorManager.GetCurrentBehavior(animal)
    if currentBehavior == "hostile_engagement" or currentBehavior == "retaliatory_fight" then
        speedMultiplier = 4.0
    elseif currentBehavior == "retaliatory_flight" or currentBehavior == "fleeing" then
        speedMultiplier = 2.0
    end
    
    -- PHASE 2: Safe virtual tracking operations
    if not inRender and virtualState then
        safeCallBehaviorFunction(VirtualTracker, "UpdateVirtualPosition", animalID, deltaSeconds)
        local targetX, targetY = AE_BehaviorManager.GetMovementTarget(animal)
        if targetX and targetY then
            local virtualSpeed = 1.5 * speedMultiplier
            safeCallBehaviorFunction(VirtualTracker, "SetVirtualTarget", animalID, targetX, targetY, virtualSpeed)
        end
    elseif inRender and virtualState then
        local currentBehavior = AE_BehaviorManager.GetCurrentBehavior(animal)
        -- Don't override foraging pathfinding with other movement targets
        if not currentBehavior:find("foraging_") then
            local targetX, targetY = AE_BehaviorManager.GetMovementTarget(animal)
            if targetX and targetY then
                if animal.pathToLocation then
                    local pathCalls = math.floor(speedMultiplier)
                    for i = 1, pathCalls do
                        animal:pathToLocation(math.floor(targetX), math.floor(targetY), animal:getZ())
                    end
                end
            end
        end
    end
    
    return true
end

local function updateManagedAnimals()
    local currentTime = getTimestamp()  -- PHASE 1 FIX: Add missing currentTime variable
    local currentTick = tickCounter
    performanceStats.processedThisTick = 0
    performanceStats.skippedThisTick = 0
    
    local animalCount = #animalProcessingOrder
    -- DEFENSIVE: Stay dormant when no animals exist
    if animalCount == 0 then
        return
    end
    
    -- Tick-based performance tracking
    local startTick = tickCounter
    
    local processed = 0
    local attempts = 0
    local maxAttempts = math.min(animalCount, UPDATE_LIMIT_PER_TICK)
    
    for i = 1, maxAttempts do
        -- Tick-based budget control
        if (tickCounter - startTick) >= MAX_TICKS_PER_UPDATE then
            break
        end
        
        if nextAnimalIndex > animalCount then
            nextAnimalIndex = 1
        end
        
        local animalID = animalProcessingOrder[nextAnimalIndex]
        nextAnimalIndex = nextAnimalIndex + 1
        local animal = managedAnimals[animalID]
        local isValid = false
        
        if animal then
            local isFramework = false
            if AnimalRegistry and AnimalRegistry.IsFrameworkAnimal then
                local success, result = pcall(AnimalRegistry.IsFrameworkAnimal, animal)
                isFramework = success and result or false
            end
            local success, animalType = pcall(function()
                return animal:getAnimalType()
            end)
            local isCat = success and (animalType == "kttr" or animalType == "kttrmanx" or
                                      animalType == "smokeykttr")
            isValid = isFramework or isCat
        end
        
        if isValid then
            local lastUpdate = lastUpdateTimes[animalID] 
            if not lastUpdate then
                lastUpdate = currentTime  -- Initialize on first update
            end
            
            -- PHASE 1 FIX: Defensive timing operations
            if currentTime and lastUpdate and type(currentTime) == "number" and type(lastUpdate) == "number" then
                local deltaMs = currentTime - lastUpdate
                local deltaSeconds = deltaMs / 1000.0
                local deltaMinutes = deltaSeconds / 60.0
                
                updateAnimalBehaviors(animal, animalID, deltaSeconds, deltaMinutes)
                lastUpdateTimes[animalID] = currentTime
            else
                print("[AE_BehaviorManager] WARNING: Invalid timing values for animal " .. tostring(animalID))
                lastUpdateTimes[animalID] = currentTime  -- Reset timing
            end
            safeCallBehaviorFunction(VirtualTracker, "MarkUpdated", animalID, currentTick)
            processed = processed + 1
            performanceStats.processedThisTick = processed
        else
            AE_BehaviorManager.RemoveAnimal(animalID)
        end
    end
    
    -- PHASE 3: Enhanced performance monitoring
    local ticksUsed = tickCounter - startTick
    performanceStats.lastTickCount = ticksUsed
    performanceStats.avgTickCount = (performanceStats.avgTickCount * 0.9) + (ticksUsed * 0.1)
    
    -- Record performance sample for analysis
    local processingTimeMs = 0  -- Could be enhanced with actual timing
    recordPerformanceSample(ticksUsed, processingTimeMs, processed)
end

local function onTick()
    tickCounter = tickCounter + 1
    registrationTickCounter = registrationTickCounter + 1
    
    -- PHASE 3: Periodic health monitoring
    periodicHealthCheck()
    
    if tickCounter >= UPDATE_FREQUENCY_TICKS then
        updateManagedAnimals()
        
        -- PHASE 2: Safe HomeLocation update call
        safeCallBehaviorFunction(HomeLocation, "HourlyUpdate")
        
        tickCounter = 0
    end
    
    if registrationTickCounter >= REGISTRATION_SCAN_FREQUENCY then
        AE_BehaviorManager.RegisterExistingAnimals()
        registrationTickCounter = 0 
    end
end

-- Get performance statistics --
-- @return table - performance stats
function AE_BehaviorManager.GetPerformanceStats()
    local virtualStats, success = safeCallBehaviorFunction(VirtualTracker, "GetStats")
    if not success then
        virtualStats = { virtualAnimals = 0, renderAnimals = 0 }
    end
    return {
        managedAnimals = #animalProcessingOrder,
        processedLastTick = performanceStats.processedThisTick,
        skippedLastTick = performanceStats.skippedThisTick,
        lastTickMs = performanceStats.lastTickMs,
        avgTickMs = math.floor(performanceStats.avgTickMs * 100) / 100,
        animalsInRender = virtualStats.inRender,
        animalsOutRender = virtualStats.outRender,
    }
end

function AE_BehaviorManager.PrintStats()
    local stats = AE_BehaviorManager.GetPerformanceStats()
end

-- RUNTIME TAMING HOOK: Initialize behavior systems when animal is tamed during gameplay
local function onAnimalTamed(animal, player)
    if not animal then
        return
    end

    if AE_EnvironmentDetector.isSinglePlayer() then
    elseif isClient() then
        -- MP Client: Skip processing
        return
    end

    -- Get animal type for validation
    local success, animalType = pcall(function()
        return animal:getAnimalType()
    end)

    local isFrameworkAnimal = false
    if AnimalRegistry and AnimalRegistry.IsFrameworkAnimal then
        local success, result = pcall(AnimalRegistry.IsFrameworkAnimal, animal)
        isFrameworkAnimal = success and result or false
    end

    if isFrameworkAnimal then
        -- Initialize behavior systems for newly tamed framework animal
        local initSuccess = AE_BehaviorManager.InitializeAnimal(animal)
        if initSuccess then
            print("[AE_BehaviorManager] Behavior systems initialized for newly tamed animal: " .. (animalType or "unknown"))
        end
    else
        -- Try direct cat type check as fallback
        local isCat = success and (animalType == "kttr" or animalType == "kttrmanx" or
                      animalType == "smokeykttr")
        if isCat then
            local initSuccess = AE_BehaviorManager.InitializeAnimal(animal)
            if initSuccess then
                print("[AE_BehaviorManager] Behavior systems initialized for newly tamed cat: " .. animalType)
            end
        end
    end
end

-- Register the runtime taming hook using custom event
if Events and Events.AE_AnimalTamed then
    Events.AE_AnimalTamed.Add(onAnimalTamed)
end

-- Fallback: Also listen for general animal events if available
if Events and Events.OnAnimalTamed then
    Events.OnAnimalTamed.Add(onAnimalTamed)
end

-- CONVERTED: Animal death handling with AE_DataService
local function onAnimalDeath(character)
    -- Type safety: OnCharacterDeath fires for ALL characters (animals, zombies, players)
    -- Only process IsoAnimal objects
    if not instanceof(character, "IsoAnimal") then
        return
    end

    local isFrameworkAnimal = false
    if character and AnimalRegistry and AnimalRegistry.IsFrameworkAnimal then
        local success, result = pcall(AnimalRegistry.IsFrameworkAnimal, character)
        isFrameworkAnimal = success and result or false
    end

    if character and isFrameworkAnimal then
        -- CONVERTED: Use AE_DataService instead of direct ModData access
        if AE_DataService.isAnimalValid(character) then
            local animalID = AE_DataService.getStableID(character)
            if animalID then
                AE_BehaviorManager.RemoveAnimal(animalID)
            end
        end
    end
end

-- Late-binding initialization to break circular dependencies
AE_BehaviorManager.initialize = function()
    -- ARCHITECTURAL FIX: Prevent multiple initialization attempts and race conditions
    if AE_BehaviorManager.initializationAttempted then
        return AE_BehaviorManager.isInitialized
    end
    
    AE_BehaviorManager.initializationAttempted = true
    
    if AE_BehaviorManager.isInitialized then
        return true
    end
    
    print("[AE_BehaviorManager] Starting initialization...")
    
    -- Phase 1: Initialize local dependencies first
    AE_BehaviorManager.initializeLocalDependencies()
    
    -- Phase 2: Initialize inter-mod communication
    AE_BehaviorManager.initializeInterModCommunication()
    
    -- Phase 3: Register core event handlers with defensive checks
    if Events and Events.OnTick and Events.OnTick.Add then
        Events.OnTick.Add(onTick)
    else
        print("[AE_BehaviorManager] WARNING: Events.OnTick not available")
    end
    
    if Events and Events.OnCharacterDeath and Events.OnCharacterDeath.Add then
        Events.OnCharacterDeath.Add(onAnimalDeath)
    else
        print("[AE_BehaviorManager] WARNING: Events.OnCharacterDeath not available")
    end
    
    AE_BehaviorManager.isInitialized = true
    
    -- ARCHITECTURAL FIX: Validate successful initialization
    if AE_BehaviorManager.isFullyInitialized() then
        print("[AE_BehaviorManager] Initialization completed successfully")
    else
        print("[AE_BehaviorManager] WARNING: Initialization completed but dependencies may be missing")
    end
    
    -- Notify other systems that BehaviorManager is ready
    if Events and Events.AE_BehaviorManagerReady and Events.AE_BehaviorManagerReady.Trigger then
        local timestamp = getTimestamp()
        
        Events.AE_BehaviorManagerReady.Trigger({
            systemReady = AE_BehaviorManager.isFullyInitialized(),
            timestamp = timestamp
        })
    end
    
    return AE_BehaviorManager.isInitialized
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        if AE_EnvironmentDetector.isSinglePlayer() then
            AE_BehaviorManager.initialize()
        end
    end)
end

if Events and Events.OnServerStarted then
    Events.OnServerStarted.Add(function()
        if AE_EnvironmentDetector.isMultiplayer() and not isClient() then
            AE_BehaviorManager.initialize()
        end
    end)
end

if Events and Events.OnPlayerConnect then
    Events.OnPlayerConnect.Add(function(player)
        if AE_EnvironmentDetector.isMultiplayer() and isClient() and player == getPlayer() then
            AE_BehaviorManager.initialize()
        end
    end)
end

-- Register for inter-mod coordination
if Events and Events.AE_FrameworkCoreReady then
    Events.AE_FrameworkCoreReady.Add(AE_BehaviorManager.initialize)
end

local function onGameTimeLoaded()
    if AE_EnvironmentDetector.isSinglePlayer() then
    elseif isClient() then
        -- MP Client: Skip processing
        return
    end
    
    local delayTicks = 0
    local scansCompleted = 0
    local TOTAL_INITIAL_SCANS = 3
    
    local function checkExisting()
        delayTicks = delayTicks + 1
        local scanInterval = 120
        if delayTicks >= scanInterval * (scansCompleted + 1) and scansCompleted < TOTAL_INITIAL_SCANS then
            scansCompleted = scansCompleted + 1
            AE_BehaviorManager.RegisterExistingAnimals()
            if scansCompleted >= TOTAL_INITIAL_SCANS then
                if Events and Events.OnTick and Events.OnTick.Remove then
                    Events.OnTick.Remove(checkExisting)
                end
            end
        else
            if delayTicks % 30 == 0 then
                local nextScan = scanInterval * (scansCompleted + 1)
            end
        end
    end
    if Events and Events.OnTick and Events.OnTick.Add then
        Events.OnTick.Add(checkExisting)
    else
        print("[AE_BehaviorManager] WARNING: Cannot schedule initial animal scan - Events.OnTick not available")
    end
end

-- Use reliable event for game time loading
if Events and Events.OnGameTimeLoaded then
    Events.OnGameTimeLoaded.Add(onGameTimeLoaded)
end

-- CONVERTED: Register existing animals with AE_DataService
function AE_BehaviorManager.RegisterExistingAnimals()
    local player = getPlayer()
    if not player then
        return
    end
    
    local nearbyAnimals = safeScanNearbyAnimals(player, 100)
    local catsFound = 0
    local catsAlreadyManaged = 0
    local catsNewlyRegistered = 0
    local wildCount = 0
    local failedCount = 0
    
    for i, animal in ipairs(nearbyAnimals) do
        local success, animalType = pcall(function()
            return animal:getAnimalType()
        end)
        
        local isCat = success and (animalType == "kttr" or animalType == "kttrmanx" or
                      animalType == "smokeykttr")
        
        if isCat then
            catsFound = catsFound + 1
            local ax, ay = animal:getX(), animal:getY()
            local distFromPlayer = math.sqrt((ax - player:getX())^2 + (ay - player:getY())^2)
            local alreadyManaged, existingID = isAnimalAlreadyManaged(animal)
            
            if alreadyManaged then
                catsAlreadyManaged = catsAlreadyManaged + 1
            else
                local initSuccess = AE_BehaviorManager.InitializeAnimal(animal)
                if initSuccess then
                    catsNewlyRegistered = catsNewlyRegistered + 1
                    -- CONVERTED: Use AE_DataService instead of direct ModData access
                    local isTamed = AE_DataService.isTamed(animal)
                    if not isTamed then
                        wildCount = wildCount + 1
                    end
                else
                    failedCount = failedCount + 1
                end
            end
        end
    end
end

AE_BehaviorManager.Systems = {
    HomeLocation = HomeLocation,
    WanderLust = WanderLust,
    ReturnHome = ReturnHome,
    Flee = Flee,
    Retaliatory = Retaliatory,
    Hostility = Hostility,
    StuckDetection = StuckDetection,
}

-- PHASE 1+3: CRITICAL INFRASTRUCTURE REPAIR + OPTIMIZATION
-- Centralized behavior processing with dynamic intervals
local lastBehaviorUpdate = 0
local behaviorUpdateInterval = 60000 + ZombRand(30000) -- Base: 60-90 seconds

local function calculateOptimalInterval()
    local managedCount = 0
    for _ in pairs(AE_BehaviorManager.managedAnimals or {}) do
        managedCount = managedCount + 1
    end
    
    -- Dynamic interval based on animal count
    if managedCount == 0 then
        return 120000 -- 2 minutes when no animals
    elseif managedCount <= 3 then
        return 60000 + ZombRand(30000) -- 60-90 seconds for few animals
    elseif managedCount <= 10 then
        return 45000 + ZombRand(30000) -- 45-75 seconds for moderate animals
    else
        return 30000 + ZombRand(30000) -- 30-60 seconds for many animals
    end
end

function AE_BehaviorManager.centralizedBehaviorUpdate()
    local currentTime = getTimestamp()
    if currentTime - lastBehaviorUpdate >= behaviorUpdateInterval then
        AE_BehaviorManager.scanAndRefreshAnimals()
        AE_BehaviorManager.periodicCheck()
        
        lastBehaviorUpdate = currentTime
        behaviorUpdateInterval = calculateOptimalInterval() -- Dynamic optimization
    end
end

function AE_BehaviorManager.scanAndRefreshAnimals()
    local cell = getCell()
    if not cell then return end
    
    -- PHASE 1 EMERGENCY FIX: Defensive early return to prevent expensive world scan
    local objectList = cell:getObjectList()
    if not objectList or objectList:size() == 0 then 
        return 
    end
    
    -- Quick pre-scan: Check if ANY animals exist before expensive iteration
    local hasAnimals = false
    local sampleSize = math.min(50, objectList:size()) -- Sample first 50 objects
    for i = 0, sampleSize - 1 do
        local obj = objectList:get(i)
        if obj and instanceof(obj, "IsoAnimal") then
            hasAnimals = true
            break
        end
    end
    
    -- Skip expensive full scan if no animals detected in sample
    if not hasAnimals then
        return
    end
    
    -- Initialize category mapping if needed
    if AnimalRegistry and AnimalRegistry.InitializeCategoryMapping and Config then
        AnimalRegistry.InitializeCategoryMapping()
    end
    
    local animalsFound = 0
    local animalsAdded = 0
    
    for i = 0, objectList:size() - 1 do
        local obj = objectList:get(i)
        if obj and instanceof(obj, "IsoAnimal") then
            animalsFound = animalsFound + 1
            local success, animalType = pcall(function()
                return obj:getAnimalType()
            end)
            if success and animalType then
                -- Check if this is a cat type using AnimalRegistry
                if AnimalRegistry and AnimalRegistry.GetAnimalType then
                    local category = AnimalRegistry.GetAnimalType(obj)
                    if category == "cat" then
                        if AE_BehaviorManager.InitializeAnimal(obj) then
                            animalsAdded = animalsAdded + 1
                        end
                    end
                end
            end
        end
    end
end

-- PHASE 3: Simplified hunting system - focus on basic functionality

function AE_BehaviorManager.periodicCheck()
    if not AE_BehaviorManager.isFullyInitialized() then
        return
    end
    
    local animalsProcessed = 0
    local processingStartTime = getTimestamp()
    
    -- Priority-based behavior coordination with hunting precedence
    for animalID, animal in pairs(AE_BehaviorManager.managedAnimals or {}) do
        if animal and not animal:isDead() then
            local activeBehavior = nil
            local highestPriority = 0
            
            -- PRIORITY 1: Check if animal has manual commands (highest priority)
            local hasManualCommand = false
            if CommandsSystem and CommandsSystem.HasManualCommand then
                local success, result = pcall(function()
                    return CommandsSystem.HasManualCommand(animalID)
                end)
                if success and result then
                    hasManualCommand = true
                    activeBehavior = "ManualCommand"
                    highestPriority = 100
                end
            end
            
            -- PRIORITY 2: Check hostility/hunting (high priority for hunting system)
            if not hasManualCommand and Hostility and Hostility.IsEngaged then
                local success, isEngaged = pcall(function()
                    return Hostility.IsEngaged(animal)
                end)
                if success and isEngaged then
                    activeBehavior = "Hostility"
                    highestPriority = 90
                end
            end
            
            -- PRIORITY 3: Check flee behaviors (emergency priority)
            if highestPriority < 80 then
                if Flee and Flee.IsFleeing then
                    local success, isFleeing = pcall(function()
                        return Flee.IsFleeing(animal)
                    end)
                    if success and isFleeing then
                        activeBehavior = "Flee"
                        highestPriority = 80
                    end
                end
                
                if Retaliatory and Retaliatory.IsFleeing then
                    local success, isFleeing = pcall(function()
                        return Retaliatory.IsFleeing(animal)
                    end)
                    if success and isFleeing then
                        activeBehavior = "Retaliatory"
                        highestPriority = 70
                    end
                end
            end
            
            -- PRIORITY 4: Check return home behaviors (lower priority)
            if highestPriority < 60 then
                if ReturnHome and ReturnHome.IsReturning then
                    local success, isReturning = pcall(function()
                        return ReturnHome.IsReturning(animal)
                    end)
                    if success and isReturning then
                        activeBehavior = "ReturnHome"
                        highestPriority = 60
                    end
                end
            end
            
            -- Execute behaviors based on priority (hunting gets precedence)
            if activeBehavior == "ManualCommand" then
                -- Manual commands override hunting - minimal behavior updates
                if Hostility and Hostility.Update then
                    pcall(function() Hostility.Update(animal, 1.0) end)
                end
            elseif activeBehavior == "Hostility" then
                -- HUNTING ACTIVE - highest priority, update hunting system and foraging
                if Hostility and Hostility.Update then
                    pcall(function() Hostility.Update(animal, 1.0) end)
                end
                -- Update foraging system for hunting behaviors
                if Foraging and Foraging.Update then
                    pcall(function() Foraging.Update(animal, animalID, 1.0) end)
                end
            elseif activeBehavior == "Flee" or activeBehavior == "Retaliatory" then
                -- Emergency behaviors - update flee and hostility (defensive)
                if activeBehavior == "Flee" and Flee and Flee.Update then
                    pcall(function() Flee.Update(animal, 1.0) end)
                end
                if activeBehavior == "Retaliatory" and Retaliatory and Retaliatory.Update then
                    pcall(function() Retaliatory.Update(animal, 1.0) end)
                end
                if Hostility and Hostility.Update then
                    pcall(function() Hostility.Update(animal, 1.0) end)
                end
            else
                -- No high-priority behavior active - run standard behavior updates
                if Hostility and Hostility.Update then
                    pcall(function() Hostility.Update(animal, 1.0) end)
                end
                if WanderLust and WanderLust.Update then
                    pcall(function() WanderLust.Update(animal, 1.0) end)
                end
                if ReturnHome and ReturnHome.Update then
                    pcall(function() ReturnHome.Update(animal) end)
                end
                if StuckDetection and StuckDetection.Update then
                    pcall(function() StuckDetection.Update(animal, 1.0) end)
                end
            end
            
            animalsProcessed = animalsProcessed + 1
        end
    end
    
    -- PHASE 3: Performance monitoring
    local processingEndTime = getTimestamp()
    local processingDuration = processingEndTime - processingStartTime
    if processingDuration > 100 then -- Log if processing takes over 100ms
        print("[AE_BehaviorManager] Performance: Processed " .. animalsProcessed .. " animals in " .. processingDuration .. "ms")
    end
end

-- PHASE 3: Event registration now handled by AE_DefensiveArchitectureCoordinator
-- Events.EveryTenMinutes.Add(AE_BehaviorManager.centralizedBehaviorUpdate) -- Disabled - event-driven architecture
if false and Events and Events.EveryTenMinutes then
    -- Legacy registration disabled - now handled by defensive architecture
    print("[AE_BehaviorManager] Behavior updates now event-driven")
else
    print("[AE_BehaviorManager] WARNING: Events.EveryTenMinutes not available - using fallback")
end

-- PHASE 2B: Add StartHuntingBehavior for hunting system restoration
function AE_BehaviorManager.StartHuntingBehavior(animal, animalID)
    if not animal or not animalID then 
        print("[AE_BehaviorManager] ERROR: Invalid parameters for StartHuntingBehavior")
        return false 
    end
    
    -- Validate animal exists in registry
    local registry = loadAnimalRegistry()
    if not registry then 
        print("[AE_BehaviorManager] ERROR: AnimalRegistry not available for hunting")
        return false 
    end
    
    local animalData = registry.GetAnimalModData and registry.GetAnimalModData(animal)
    if not animalData then 
        print("[AE_BehaviorManager] ERROR: Animal not registered for hunting: " .. tostring(animalID))
        return false 
    end
    
    -- Use globally loaded foraging system for hunting behavior
    if not Foraging then
        print("[AE_BehaviorManager] ERROR: Foraging system not available for hunting")
        return false
    end
    
    -- Start hunting via foraging system
    local huntSuccess = Foraging.StartForaging(animalID, "hunting")
    if not huntSuccess then
        print("[AE_BehaviorManager] ERROR: Failed to start hunting foraging")
        return false
    end
    
    -- Register animal for centralized behavior updates
    AE_BehaviorManager.activeAnimals[animalID] = {
        animal = animal,
        lastUpdate = getTimestamp(),
        behaviorsActive = { foraging = true, hunting = true },
        priority = "hunting" -- Hunting gets highest priority in centralized updates
    }
    
    print("[AE_BehaviorManager] Hunting behavior started successfully for " .. animalID)
    return true
end

-- Expose managedAnimals globally for periodicCheck access
AE_BehaviorManager.managedAnimals = managedAnimals

return AE_BehaviorManager