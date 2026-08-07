local AE_DefensiveArchitectureCoordinator = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

-- PHASE 3: Defensive Architecture Implementation
-- Dynamic registration and event-driven activation for truly defensive systems

-- System activity tracking
local SystemActivity = {
    totalAnimals = 0,
    activeAnimals = 0,
    lastActivity = 0,
    dataOperations = 0,
    uiOperations = 0,
    cleanupRequired = false,
    playerInZones = false,
    lastPlayerPosition = nil,
    lastZoneCheck = 0
}

-- Dynamic registration state
local RegistrationState = {
    dataCleanupActive = false,
    uiHealthActive = false,
    zoneSystemActive = false,
    lastRegistrationCheck = 0,
    activityThreshold = 300000, -- 5 minutes of inactivity = dormant
    registrationCheckInterval = 60000, -- Check every minute
    zoneCheckInterval = 30000 -- Zone checks every 30 seconds (rate limited)
}

-- Performance scaling configuration
local ScalingConfig = {
    intervals = {
        high = 600000,    -- 10 minutes for high activity
        medium = 1800000, -- 30 minutes for medium activity  
        low = 3600000,    -- 60 minutes for low activity
        dormant = 0       -- No timer when dormant
    },
    thresholds = {
        high = 10,    -- 10+ animals = high activity
        medium = 3,   -- 3-9 animals = medium activity
        low = 1       -- 1-2 animals = low activity
    }
}

-- Event-driven activation system
function AE_DefensiveArchitectureCoordinator.initialize()
    -- Subscribe to core animal events for activity detection
    AE_DefensiveArchitectureCoordinator.subscribeToActivityEvents()
    
    -- Setup periodic activity assessment (minimal frequency)
    Events.EveryOneMinute.Add(AE_DefensiveArchitectureCoordinator.assessSystemActivity)
    
    -- Setup initial state
    AE_DefensiveArchitectureCoordinator.performInitialActivityAssessment()
    
    print("[AE_DefensiveArchitectureCoordinator] Defensive architecture initialized")
end

-- Subscribe to events that indicate system activity
function AE_DefensiveArchitectureCoordinator.subscribeToActivityEvents()
    local eventRegistrations = {
        "OnCreateLivingCharacter",
        "OnCharacterDeath", 
        "OnPlayerUpdate",
        "OnGameStart"
    }
    
    for _, eventName in ipairs(eventRegistrations) do
        if Events[eventName] then
            Events[eventName].Add(function(...)
                AE_DefensiveArchitectureCoordinator.recordActivity(eventName, {...})
            end)
        end
    end
    
    -- Framework-specific events if available
    if _G.AE_EventRegistry then
        local frameworkEvents = {
            "OnAE_AnimalRegistered",
            "OnAE_AnimalRemoved", 
            "OnAE_StateUpdated",
            "OnAE_DataModified"
        }
        
        for _, eventName in ipairs(frameworkEvents) do
            local success, error = pcall(function()
                AE_EventRegistry.subscribeEvent(eventName, function(eventData)
                    AE_DefensiveArchitectureCoordinator.recordActivity(eventName, eventData)
                end)
            end)
            
            if not success then
                print("[AE_DefensiveArchitectureCoordinator] WARNING: Could not subscribe to " .. eventName)
            end
        end
    end
end

-- Record system activity for defensive decision making
function AE_DefensiveArchitectureCoordinator.recordActivity(eventType, eventData)
    SystemActivity.lastActivity = getTimestamp()
    SystemActivity.dataOperations = SystemActivity.dataOperations + 1
    
    -- Analyze specific event types
    if eventType == "OnCreateLivingCharacter" or eventType == "OnAE_AnimalRegistered" then
        SystemActivity.totalAnimals = SystemActivity.totalAnimals + 1
        SystemActivity.activeAnimals = SystemActivity.activeAnimals + 1
        SystemActivity.cleanupRequired = true
        
    elseif eventType == "OnCharacterDeath" or eventType == "OnAE_AnimalRemoved" then
        SystemActivity.totalAnimals = math.max(0, SystemActivity.totalAnimals - 1)
        SystemActivity.activeAnimals = math.max(0, SystemActivity.activeAnimals - 1)
        SystemActivity.cleanupRequired = true
        
    elseif eventType == "OnPlayerUpdate" then
        -- Check for significant player movement for zone detection (hybrid approach)
        AE_DefensiveArchitectureCoordinator.checkPlayerZoneActivityHybrid()
        
    elseif eventType == "OnAE_StateUpdated" or eventType == "OnAE_DataModified" then
        SystemActivity.cleanupRequired = true
    end
    
    -- Trigger immediate reassessment if significant change
    if SystemActivity.dataOperations % 10 == 0 then
        AE_DefensiveArchitectureCoordinator.assessSystemActivity()
    end
end

-- Core defensive logic: Assess whether systems should be active
function AE_DefensiveArchitectureCoordinator.assessSystemActivity()
    local currentTime = getTimestamp()
    
    -- Skip if we just checked recently (rate limiting)
    if currentTime - RegistrationState.lastRegistrationCheck < RegistrationState.registrationCheckInterval then
        return
    end
    
    RegistrationState.lastRegistrationCheck = currentTime
    
    -- Update real animal count via world scanning (defensive approach)
    AE_DefensiveArchitectureCoordinator.updateRealAnimalCount()
    
    -- Determine current activity level
    local activityLevel = AE_DefensiveArchitectureCoordinator.calculateActivityLevel()
    
    -- Make registration decisions based on activity
    AE_DefensiveArchitectureCoordinator.updateSystemRegistrations(activityLevel)
    
    -- Reset activity counters
    SystemActivity.dataOperations = 0
    SystemActivity.uiOperations = 0
end

-- Defensive animal count update with early return
function AE_DefensiveArchitectureCoordinator.updateRealAnimalCount()
    local animalCount = 0
    
    -- Defensive world access
    local world = getWorld()
    if not world then return end
    
    local cell = world:getCell()
    if not cell then return end
    
    -- Quick scan with early return if no zombies
    local zombieList = cell:getZombieList()
    if not zombieList or zombieList:size() == 0 then
        SystemActivity.totalAnimals = 0
        SystemActivity.activeAnimals = 0
        return
    end
    
    -- Count actual animals (not zombies)
    for i = 0, zombieList:size() - 1 do
        local character = zombieList:get(i)
        if character and character:isAnimal() then
            animalCount = animalCount + 1
        end
    end
    
    SystemActivity.totalAnimals = animalCount
    SystemActivity.activeAnimals = animalCount
end

-- Defensive zone activity detection (minimal performance impact)
function AE_DefensiveArchitectureCoordinator.checkPlayerZoneActivity()
    local currentTime = getTimestamp()
    
    -- Rate limiting: Only check zones every 30 seconds
    if currentTime - SystemActivity.lastZoneCheck < RegistrationState.zoneCheckInterval then
        return
    end
    
    SystemActivity.lastZoneCheck = currentTime
    
    -- Get player position (defensive)
    local player = getPlayer()
    if not player then return end
    
    local playerX = player:getX()
    local playerY = player:getY()
    
    -- Early return if player hasn't moved significantly (>50 units)
    if SystemActivity.lastPlayerPosition then
        local deltaX = math.abs(playerX - SystemActivity.lastPlayerPosition.x)
        local deltaY = math.abs(playerY - SystemActivity.lastPlayerPosition.y)
        
        if deltaX < 50 and deltaY < 50 then
            return -- Not enough movement to matter
        end
    end
    
    -- Update player position
    SystemActivity.lastPlayerPosition = {x = playerX, y = playerY}
    
    -- Check if player is in any defined zones (minimal implementation)
    local wasInZones = SystemActivity.playerInZones
    SystemActivity.playerInZones = AE_DefensiveArchitectureCoordinator.isPlayerInAnyZone(playerX, playerY)
    
    -- Trigger zone system activation/deactivation if status changed
    if SystemActivity.playerInZones ~= wasInZones then
        AE_DefensiveArchitectureCoordinator.assessSystemActivity()
    end
end

-- Minimal zone detection (defensive approach)
function AE_DefensiveArchitectureCoordinator.isPlayerInAnyZone(playerX, playerY)
    -- Defensive check for zone definitions
    if not _G.AE_ZoneDefinitions then
        return false
    end
    
    -- Use actual zone detection from AE_ZoneDefinitions
    local success, result = pcall(function()
        if AE_ZoneDefinitions.spawnZones and AE_ZoneDefinitions.isPlayerInZone then
            -- Check if player is in any enabled zone
            for _, zone in ipairs(AE_ZoneDefinitions.spawnZones) do
                if zone.enabled and AE_ZoneDefinitions.isPlayerInZone(playerX, playerY, zone) then
                    return true
                end
            end
        end
        return false
    end)
    
    return success and result or false
end

-- Calculate system activity level for scaling decisions
function AE_DefensiveArchitectureCoordinator.calculateActivityLevel()
    local currentTime = getTimestamp()
    local timeSinceActivity = currentTime - SystemActivity.lastActivity
    
    -- Check for dormancy first (highest priority)
    if timeSinceActivity > RegistrationState.activityThreshold and SystemActivity.totalAnimals == 0 then
        return "dormant"
    end
    
    -- Activity level based on animal count and recent operations
    if SystemActivity.totalAnimals >= ScalingConfig.thresholds.high or SystemActivity.dataOperations > 20 then
        return "high"
    elseif SystemActivity.totalAnimals >= ScalingConfig.thresholds.medium or SystemActivity.dataOperations > 5 then
        return "medium"  
    elseif SystemActivity.totalAnimals >= ScalingConfig.thresholds.low then
        return "low"
    else
        return "dormant"
    end
end

-- Update system registrations based on activity level (core defensive logic)
function AE_DefensiveArchitectureCoordinator.updateSystemRegistrations(activityLevel)
    local targetInterval = ScalingConfig.intervals[activityLevel] or 0
    
    -- Data cleanup system management
    local needsDataCleanup = activityLevel ~= "dormant" and (SystemActivity.cleanupRequired or SystemActivity.totalAnimals > 0)
    
    if needsDataCleanup and not RegistrationState.dataCleanupActive then
        AE_DefensiveArchitectureCoordinator.activateDataCleanupSystem(targetInterval)
        RegistrationState.dataCleanupActive = true
        print("[AE_DefensiveArchitectureCoordinator] Activated data cleanup system - " .. activityLevel .. " activity")
        
    elseif not needsDataCleanup and RegistrationState.dataCleanupActive then
        AE_DefensiveArchitectureCoordinator.deactivateDataCleanupSystem()
        RegistrationState.dataCleanupActive = false
        print("[AE_DefensiveArchitectureCoordinator] Deactivated data cleanup system - going dormant")
    end
    
    -- UI health system management (client only in MP)
    if AE_EnvironmentDetector.isSinglePlayer() then
        -- SP: No separate UI health needed
    elseif isClient() then
        local needsUIHealth = activityLevel ~= "dormant" and SystemActivity.uiOperations > 0
        
        if needsUIHealth and not RegistrationState.uiHealthActive then
            AE_DefensiveArchitectureCoordinator.activateUIHealthSystem(targetInterval)
            RegistrationState.uiHealthActive = true
            print("[AE_DefensiveArchitectureCoordinator] Activated UI health system - " .. activityLevel .. " activity")
            
        elseif not needsUIHealth and RegistrationState.uiHealthActive then
            AE_DefensiveArchitectureCoordinator.deactivateUIHealthSystem()
            RegistrationState.uiHealthActive = false
            print("[AE_DefensiveArchitectureCoordinator] Deactivated UI health system - going dormant")
        end
    end
    
    -- Zone spawning system management (defensive activation)
    local needsZoneSystem = activityLevel ~= "dormant" and SystemActivity.playerInZones
    
    if needsZoneSystem and not RegistrationState.zoneSystemActive then
        AE_DefensiveArchitectureCoordinator.activateZoneSystem(targetInterval)
        RegistrationState.zoneSystemActive = true
        print("[AE_DefensiveArchitectureCoordinator] Activated zone spawning system - player in zones")
        
    elseif not needsZoneSystem and RegistrationState.zoneSystemActive then
        AE_DefensiveArchitectureCoordinator.deactivateZoneSystem()
        RegistrationState.zoneSystemActive = false
        print("[AE_DefensiveArchitectureCoordinator] Deactivated zone spawning system - player left zones or dormant")
    end
    
    -- Reset cleanup flag after processing
    SystemActivity.cleanupRequired = false
end

-- Dynamically activate data cleanup system
function AE_DefensiveArchitectureCoordinator.activateDataCleanupSystem(interval)
    -- Use existing AE_DataCleanupCoordinator but override its rate limiting
    if _G.AE_DataCleanupCoordinator then
        -- Update coordinator's configuration for dynamic intervals
        AE_DataCleanupCoordinator.setConfig({
            interval = interval / 60, -- Convert ms to minutes
            lastExecutionTime = 0 -- Force immediate execution eligibility
        })
        
        -- Ensure coordinator is registered with timer system
        if Events and Events.EveryTenMinutes then
            Events.EveryTenMinutes.Add(AE_DataCleanupCoordinator.performConsolidatedCleanup)
        end
    end
end

-- Dynamically deactivate data cleanup system  
function AE_DefensiveArchitectureCoordinator.deactivateDataCleanupSystem()
    if _G.AE_DataCleanupCoordinator and Events and Events.EveryTenMinutes then
        Events.EveryTenMinutes.Remove(AE_DataCleanupCoordinator.performConsolidatedCleanup)
    end
end

-- Dynamically activate UI health system
function AE_DefensiveArchitectureCoordinator.activateUIHealthSystem(interval)
    if _G.AE_UIHealthCoordinator then
        AE_UIHealthCoordinator.setConfig({
            interval = interval / 60,
            lastExecutionTime = 0
        })
        
        if Events and Events.EveryTenMinutes then
            Events.EveryTenMinutes.Add(AE_UIHealthCoordinator.performConsolidatedHealthCheck)
        end
    end
end

-- Dynamically deactivate UI health system
function AE_DefensiveArchitectureCoordinator.deactivateUIHealthSystem()
    if _G.AE_UIHealthCoordinator and Events and Events.EveryTenMinutes then
        Events.EveryTenMinutes.Remove(AE_UIHealthCoordinator.performConsolidatedHealthCheck)
    end
end

-- Dynamically activate zone spawning system
function AE_DefensiveArchitectureCoordinator.activateZoneSystem(interval)
    -- Activate zone spawning timer with appropriate interval
    if _G.AE_ZoneSpawningCore then
        -- Use existing zone spawning function if available
        if AE_ZoneSpawningCore.checkTimedSpawnTimer then
            if Events and Events.EveryTenMinutes then
                Events.EveryTenMinutes.Add(AE_ZoneSpawningCore.checkTimedSpawnTimer)
            end
        end
    end
end

-- Dynamically deactivate zone spawning system  
function AE_DefensiveArchitectureCoordinator.deactivateZoneSystem()
    if _G.AE_ZoneSpawningCore and Events and Events.EveryTenMinutes then
        if AE_ZoneSpawningCore.checkTimedSpawnTimer then
            Events.EveryTenMinutes.Remove(AE_ZoneSpawningCore.checkTimedSpawnTimer)
        end
    end
end

-- Initial assessment to set proper startup state
function AE_DefensiveArchitectureCoordinator.performInitialActivityAssessment()
    -- Start in dormant state, let events activate systems as needed
    RegistrationState.dataCleanupActive = false
    RegistrationState.uiHealthActive = false
    RegistrationState.zoneSystemActive = false
    
    -- Initialize zone state
    SystemActivity.playerInZones = false
    SystemActivity.lastPlayerPosition = nil
    SystemActivity.lastZoneCheck = 0
    
    -- Record initial activity to trigger first assessment
    AE_DefensiveArchitectureCoordinator.recordActivity("OnGameStart", {})
    
    print("[AE_DefensiveArchitectureCoordinator] Initial state: dormant (event-driven activation enabled)")
end

-- Performance reporting for monitoring
function AE_DefensiveArchitectureCoordinator.getPerformanceReport()
    return {
        systemActivity = SystemActivity,
        registrationState = RegistrationState,
        currentActivityLevel = AE_DefensiveArchitectureCoordinator.calculateActivityLevel(),
        scalingConfig = ScalingConfig
    }
end

-- Manual system state control for testing/debugging
function AE_DefensiveArchitectureCoordinator.forceSystemState(dataCleanup, uiHealth, zoneSystem)
    if dataCleanup ~= nil then
        if dataCleanup and not RegistrationState.dataCleanupActive then
            AE_DefensiveArchitectureCoordinator.activateDataCleanupSystem(ScalingConfig.intervals.medium)
            RegistrationState.dataCleanupActive = true
        elseif not dataCleanup and RegistrationState.dataCleanupActive then
            AE_DefensiveArchitectureCoordinator.deactivateDataCleanupSystem()
            RegistrationState.dataCleanupActive = false
        end
    end
    
    if uiHealth ~= nil then
        if AE_EnvironmentDetector.isSinglePlayer() then
            -- SP: No separate UI health needed
        elseif isClient() then
            if uiHealth and not RegistrationState.uiHealthActive then
                AE_DefensiveArchitectureCoordinator.activateUIHealthSystem(ScalingConfig.intervals.medium)
                RegistrationState.uiHealthActive = true
            elseif not uiHealth and RegistrationState.uiHealthActive then
                AE_DefensiveArchitectureCoordinator.deactivateUIHealthSystem()
                RegistrationState.uiHealthActive = false
            end
        end
    end
    
    if zoneSystem ~= nil then
        if zoneSystem and not RegistrationState.zoneSystemActive then
            AE_DefensiveArchitectureCoordinator.activateZoneSystem(ScalingConfig.intervals.medium)
            RegistrationState.zoneSystemActive = true
        elseif not zoneSystem and RegistrationState.zoneSystemActive then
            AE_DefensiveArchitectureCoordinator.deactivateZoneSystem()
            RegistrationState.zoneSystemActive = false
        end
    end
end

-- Zone detection orchestration for hybrid approach
function AE_DefensiveArchitectureCoordinator.requestZoneDetection(player, reason)
    if not player then return false end
    
    local playerX = player:getX()
    local playerY = player:getY()
    
    -- Evaluate context before triggering
    if AE_DefensiveArchitectureCoordinator.evaluateZoneDetectionContext(playerX, playerY) then
        return AE_DefensiveArchitectureCoordinator.triggerClientZoneCheck(player)
    end
    
    return false
end

-- Defensive evaluation before triggering zone detection
function AE_DefensiveArchitectureCoordinator.evaluateZoneDetectionContext(playerX, playerY)
    local currentTime = getTimestamp()
    
    -- Rate limiting: Only trigger if enough time passed
    if currentTime - SystemActivity.lastZoneCheck < RegistrationState.zoneCheckInterval then
        return false
    end
    
    -- Movement threshold check
    if SystemActivity.lastPlayerPosition then
        local deltaX = math.abs(playerX - SystemActivity.lastPlayerPosition.x)
        local deltaY = math.abs(playerY - SystemActivity.lastPlayerPosition.y)
        
        if deltaX < 5 and deltaY < 5 then
            return false -- Not enough movement
        end
    end
    
    -- Zone proximity check (only if zone definitions available)
    if _G.AE_ZoneDefinitions and AE_ZoneDefinitions.spawnZones then
        for _, zone in ipairs(AE_ZoneDefinitions.spawnZones) do
            if zone.enabled then
                -- Simple distance check to see if player is near any zone
                local distanceToZone = AE_ZoneDefinitions.getApproxDistanceToZone and 
                    AE_ZoneDefinitions.getApproxDistanceToZone(playerX, playerY, zone) or 999
                
                if distanceToZone <= 100 then -- Within proximity threshold
                    return true
                end
            end
        end
    end
    
    return false
end

-- Trigger client zone detection through callback system
function AE_DefensiveArchitectureCoordinator.triggerClientZoneCheck(player)
    local success = false
    
    -- Client-side detection callback
    if AE_EnvironmentDetector.isSinglePlayer() then
        -- SP: No client detection needed
    elseif isClient() then
        if _G.AE_ZoneResponseClient then
            -- Direct client detection call
            success = pcall(function()
                AE_ZoneResponseClient.performZoneCheck(player)
            end)
            
            if success then
                SystemActivity.lastZoneCheck = getTimestamp()
                SystemActivity.lastPlayerPosition = {x = player:getX(), y = player:getY()}
            end
        end
    end
    
    return success
end

-- Enhanced movement-based zone activity for hybrid approach
function AE_DefensiveArchitectureCoordinator.checkPlayerZoneActivityHybrid()
    local player = getPlayer()
    if not player then return end
    
    -- Request zone detection through orchestrated system
    AE_DefensiveArchitectureCoordinator.requestZoneDetection(player, "movement_triggered")
end

-- Event registration
Events.OnGameStart.Add(AE_DefensiveArchitectureCoordinator.initialize)

return AE_DefensiveArchitectureCoordinator