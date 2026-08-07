-- CONVERTED: AE_BehaviorManager.lua
-- SESSION 3C: All ModData access replaced with AE_DataService calls
-- SESSION 4B: Inter-mod communication implementation

local AE_BehaviorManager = {}

-- Local module references (within FrameworkCore)
local AnimalRegistry = nil
local AE_CoreCommunication = nil

-- External dependencies (via inter-mod communication)
local Config = nil
local CommandsSystem = nil

-- Behavior system modules (to be moved in Session 4C)
local HomeLocation = nil
local WanderLust = nil
local ReturnHome = nil
local Flee = nil
local VirtualTracker = nil
local Retaliatory = nil
local Hostility = nil
local StuckDetection = nil

local Foraging = nil

-- Initialization state
AE_BehaviorManager.isInitialized = false
AE_BehaviorManager.dependenciesLoaded = false

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
    
    -- Temporary: Load Foraging with error handling
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/Core/AE_Foraging")
    end)
    if success and result then
        Foraging = result
    end
    
    -- Load HomeLocation module
    success, result = pcall(function()
        return require("AnimalsEssentials/BehaviorSystems/Core/AE_HomeLocation")
    end)
    if success and result then
        HomeLocation = result
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

local tickCounter = 0
local registrationTickCounter = 0
local REGISTRATION_SCAN_FREQUENCY = 150

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
        return false
    end
    
    local alreadyManaged, existingID = isAnimalAlreadyManaged(animal)
    if alreadyManaged then
        return true
    end
    
    local success, animalType = pcall(function()
        return animal:getAnimalType()
    end)
    
    local isCat = (animalType == "kttr" or animalType == "tom" or
                  animalType == "queen" or animalType == "babykitten")
    local isFrameworkAnimal = AnimalRegistry.IsFrameworkAnimal(animal)
    
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
    
    HomeLocation.Initialize(animal)
    WanderLust.Initialize(animal)
    ReturnHome.Initialize(animal)
    Flee.Initialize(animal)
    Retaliatory.Initialize(animal)
    Hostility.Initialize(animal)
    StuckDetection.Initialize(animal)
    VirtualTracker.Initialize(animal, animalID)
    
    managedAnimals[animalID] = animal
    lastUpdateTimes[animalID] = getTimestampMs()
    table.insert(animalProcessingOrder, animalID)
    
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
        VirtualTracker.Remove(animalID)
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
    
    if Foraging then
        -- CONVERTED: Use AE_DataService instead of direct ModData access
        local animalID = AE_DataService.getStableID(animal)
        if animalID and Foraging and Foraging.HasActiveForaging and Foraging.HasActiveForaging(animalID) then
            local foragingState = Foraging.GetForagingState(animalID)
            return "foraging_" .. foragingState
        end
    end
    
    if Retaliatory.IsFighting(animal) then
        return "retaliatory_fight"
    end
    if Retaliatory.IsFleeing(animal) then
        return "retaliatory_flight"
    end
    if Hostility.IsEngaged(animal) then
        return "hostile_engagement"
    end
    if Flee.IsFleeing(animal) then
        return "fleeing"
    end
    if ReturnHome.IsReturning(animal) then
        return "returning_home"
    end
    if ReturnHome.IsResting(animal) then
        return "resting"
    end
    if WanderLust.IsWandering(animal) then
        return "wandering"
    end
    return "idle"
end

-- Get movement target for an animal based on current behavior --
-- @param animal - the IsoAnimal object
-- @return number, number - targetX, targetY or nil
function AE_BehaviorManager.GetMovementTarget(animal)
    if not animal then return nil, nil end
    local behavior = AE_BehaviorManager.GetCurrentBehavior(animal)
    
    -- Handle foraging behaviors with highest priority
    if behavior:find("foraging_") then
        -- Foraging behaviors use internal pathfinding, don't override
        return nil, nil
    end
    
    if behavior == "retaliatory_fight" then
        local target = Retaliatory.GetFightTarget(animal)
        if target then
            return target:getX(), target:getY()
        end
    elseif behavior == "retaliatory_flight" then
        return Retaliatory.GetFleeTarget(animal)
    elseif behavior == "hostile_engagement" then
        return Hostility.GetTargetPosition(animal)
    elseif behavior == "fleeing" then
        return Flee.GetFleeTarget(animal)
    elseif behavior == "returning_home" then
        return ReturnHome.GetHomeTarget(animal)
    elseif behavior == "wandering" then
        return WanderLust.GetTarget(animal)
    end
    return nil, nil
end

-- CONVERTED: Update behaviors for a single animal with AE_DataService
-- @param animal - the IsoAnimal object
-- @param animalID - the animal's stable ID
-- @param deltaSeconds - time elapsed in seconds
-- @param deltaMinutes - time elapsed in minutes
local function updateAnimalBehaviors(animal, animalID, deltaSeconds, deltaMinutes)
    VirtualTracker.UpdateRenderState(animal, animalID)
    local virtualState = VirtualTracker.GetState(animalID)
    local inRender = virtualState and virtualState.inRender or false
    local isForaging = false
    
    if Foraging and Foraging.Update then
        -- CONVERTED: Use AE_DataService instead of direct ModData access
        local stableID = AE_DataService.getStableID(animal)
        if stableID then
            isForaging = Foraging.HasActiveForaging and Foraging.HasActiveForaging(stableID)
            if isForaging then
                Foraging.Update(animal, stableID, deltaMinutes)
                return
            end
        end
    end
    
    HomeLocation.Update(animal)
    Retaliatory.Update(animal, deltaSeconds)
    
    local hasManualCommand = CommandsSystem.HasManualCommand(animalID)
    if hasManualCommand and not isForaging then
        local isEngaged = Hostility.IsEngaged(animal)
        if isEngaged then
            Hostility.Disengage(animal)
        end
    end
    
    Hostility.Update(animal, deltaSeconds)
    Flee.Update(animal, deltaSeconds)
    ReturnHome.Update(animal)
    
    -- Only update WanderLust if animal is not actively foraging
    if not isForaging then
        WanderLust.Update(animal, deltaMinutes)
    end
    
    local wanderState = WanderLust.GetState(animal)
    if wanderState and not wanderState.isActive and wanderState.scale < 10 then
        local previousScale = wanderState.previousScale or 0
        if previousScale > 90 then
            ReturnHome.OnWanderCompleted(animal)
        end
        wanderState.previousScale = wanderState.scale
    end
    
    if not isForaging then
        StuckDetection.Update(animal, deltaSeconds)
    end
    
    local speedMultiplier = 1.0
    local currentBehavior = AE_BehaviorManager.GetCurrentBehavior(animal)
    if currentBehavior == "hostile_engagement" or currentBehavior == "retaliatory_fight" then
        speedMultiplier = 4.0
    elseif currentBehavior == "retaliatory_flight" or currentBehavior == "fleeing" then
        speedMultiplier = 2.0
    end
    
    if not inRender and virtualState then
        VirtualTracker.UpdateVirtualPosition(animalID, deltaSeconds)
        local targetX, targetY = AE_BehaviorManager.GetMovementTarget(animal)
        if targetX and targetY then
            local virtualSpeed = 1.5 * speedMultiplier
            VirtualTracker.SetVirtualTarget(animalID, targetX, targetY, virtualSpeed)
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
end

local function updateManagedAnimals()
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
            local isFramework = AnimalRegistry.IsFrameworkAnimal(animal)
            local success, animalType = pcall(function()
                return animal:getAnimalType()
            end)
            local isCat = success and (animalType == "kttr" or animalType == "tom" or
                                      animalType == "queen" or animalType == "babykitten")
            isValid = isFramework or isCat
        end
        
        if isValid then
            local lastUpdate = lastUpdateTimes[animalID] or currentTime
            local deltaMs = currentTime - lastUpdate
            local deltaSeconds = deltaMs / 1000.0
            local deltaMinutes = deltaSeconds / 60.0
            
            updateAnimalBehaviors(animal, animalID, deltaSeconds, deltaMinutes)
            lastUpdateTimes[animalID] = currentTime
            VirtualTracker.MarkUpdated(animalID, currentTick)
            processed = processed + 1
            performanceStats.processedThisTick = processed
        else
            AE_BehaviorManager.RemoveAnimal(animalID)
        end
    end
    
    -- Simple tick counting instead of millisecond timing
    local ticksUsed = tickCounter - startTick
    performanceStats.lastTickCount = ticksUsed
    performanceStats.avgTickCount = (performanceStats.avgTickCount * 0.9) + (ticksUsed * 0.1)
end

local function onTick()
    tickCounter = tickCounter + 1
    registrationTickCounter = registrationTickCounter + 1
    
    if tickCounter >= UPDATE_FREQUENCY_TICKS then
        updateManagedAnimals()
        
        -- Defensive HomeLocation update call
        if HomeLocation and HomeLocation.HourlyUpdate then
            local success = pcall(function()
                HomeLocation.HourlyUpdate()
            end)
            if not success then
                print("[AE_BehaviorManager] HomeLocation HourlyUpdate failed")
            end
        end
        
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
    local virtualStats = VirtualTracker.GetStats()
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

local function onAnimalTamed(animal, player)
    if not animal then
        return
    end

    -- Get animal type for debug
    local success, animalType = pcall(function()
        return animal:getAnimalType()
    end)

    local isFrameworkAnimal = AnimalRegistry.IsFrameworkAnimal(animal)

    if isFrameworkAnimal then
        AE_BehaviorManager.InitializeAnimal(animal)
    else
        -- Try direct cat type check as fallback
        local isCat = (animalType == "kttr" or animalType == "tom" or
                      animalType == "queen" or animalType == "babykitten")
        if isCat then
            AE_BehaviorManager.InitializeAnimal(animal)
        end
    end
end

-- CONVERTED: Animal death handling with AE_DataService
local function onAnimalDeath(character)
    -- Type safety: OnCharacterDeath fires for ALL characters (animals, zombies, players)
    -- Only process IsoAnimal objects
    if not instanceof(character, "IsoAnimal") then
        return
    end

    if character and AnimalRegistry.IsFrameworkAnimal(character) then
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
    if AE_BehaviorManager.isInitialized then
        return
    end
    
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
    
    -- Notify other systems that BehaviorManager is ready
    if Events and Events.AE_BehaviorManagerReady and Events.AE_BehaviorManagerReady.Trigger then
        local timestamp = getTimestamp()
        
        Events.AE_BehaviorManagerReady.Trigger({
            systemReady = true,
            timestamp = timestamp
        })
    end
end

-- Register for framework initialization events
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(AE_BehaviorManager.initialize)
end

-- Register for inter-mod coordination
if Events and Events.AE_FrameworkCoreReady then
    Events.AE_FrameworkCoreReady.Add(AE_BehaviorManager.initialize)
end

local function onGameTimeLoaded()
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
        
        local isCat = success and (animalType == "kttr" or animalType == "tom" or
                      animalType == "queen" or animalType == "babykitten")
        
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

return AE_BehaviorManager