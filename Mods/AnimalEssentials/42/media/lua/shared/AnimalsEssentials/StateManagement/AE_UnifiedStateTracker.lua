AE_UnifiedStateTracker = {}

-- Centralized state tracking authority replacing scattered tracking systems
-- Event-driven tracking with categorized cache system for performance

-- Categorized cache system for cohesive state management
local trackedStates = {
    -- Position tracking cache
    positions = {},
    -- Behavior state cache  
    behaviors = {},
    -- Status data cache
    status = {},
    -- Equipment state cache
    equipment = {},
    -- Command state cache
    commands = {},
    -- Performance metrics cache
    performance = {}
}

-- Event-based state change detection
local stateChangeDetectors = {
    position = function(animalID, newPos, oldPos)
        if not newPos or not oldPos then return false end
        return math.abs(newPos.x - oldPos.x) > 0.1 or 
               math.abs(newPos.y - oldPos.y) > 0.1 or
               math.abs(newPos.z - oldPos.z) > 0.1
    end,
    
    behavior = function(animalID, newBehavior, oldBehavior)
        return newBehavior ~= oldBehavior
    end,
    
    status = function(animalID, newStatus, oldStatus)
        if not newStatus or not oldStatus then return true end
        return newStatus.hunger ~= oldStatus.hunger or 
               newStatus.thirst ~= oldStatus.thirst or
               newStatus.tameness ~= oldStatus.tameness or
               newStatus.health ~= oldStatus.health
    end,
    
    equipment = function(animalID, newEquip, oldEquip)
        if not newEquip and not oldEquip then return false end
        if not newEquip or not oldEquip then return true end
        
        -- Compare equipment tables
        for key, value in pairs(newEquip) do
            if oldEquip[key] ~= value then return true end
        end
        for key, value in pairs(oldEquip) do
            if newEquip[key] ~= value then return true end
        end
        return false
    end,
    
    commands = function(animalID, newCmd, oldCmd)
        if not newCmd and not oldCmd then return false end
        if not newCmd or not oldCmd then return true end
        return newCmd.command ~= oldCmd.command or
               newCmd.target ~= oldCmd.target or
               newCmd.status ~= oldCmd.status
    end
}

-- Tracking configuration for different categories
local trackingConfigs = {
    position = {
        updateFrequency = "event-based",
        retention = 300, -- 5 minutes
        triggerEvents = {"OnAnimalMove", "OnCommandIssued"}
    },
    behavior = {
        updateFrequency = "event-based", 
        retention = 600, -- 10 minutes
        triggerEvents = {"OnBehaviorStart", "OnBehaviorEnd", "OnTamenessChange"}
    },
    status = {
        updateFrequency = "event-based",
        retention = 180, -- 3 minutes  
        triggerEvents = {"OnHungerChange", "OnThirstChange", "OnHealthChange"}
    },
    equipment = {
        updateFrequency = "event-based",
        retention = 1800, -- 30 minutes (persistent)
        triggerEvents = {"OnEquipmentChange", "OnItemEquipped", "OnItemRemoved"}
    },
    commands = {
        updateFrequency = "event-based",
        retention = 120, -- 2 minutes
        triggerEvents = {"OnCommandIssued", "OnCommandCompleted", "OnCommandCanceled"}
    }
}

-- Unified tracking registration
function AE_UnifiedStateTracker.registerTrackingRequest(category, animalID, trackingConfig)
    if not trackedStates[category] then
        trackedStates[category] = {}
    end
    
    if not animalID or not trackingConfig then
        print("[AE_UnifiedStateTracker] ERROR: Invalid registration parameters")
        return false
    end
    
    trackedStates[category][animalID] = {
        lastState = trackingConfig.initialState,
        updateFrequency = trackingConfig.updateFrequency or "event-based",
        changeCallback = trackingConfig.onChangeCallback,
        validationCallback = trackingConfig.validationCallback,
        registrationTime = GameTime.getServerTimeMills(),
        lastUpdate = GameTime.getServerTimeMills()
    }
    
    return true
end

-- Event-based state updates (replaces polling)
function AE_UnifiedStateTracker.updateState(category, animalID, newState)
    if not category or not animalID then return false end
    
    local tracked = trackedStates[category] and trackedStates[category][animalID]
    if not tracked then 
        -- Auto-register with default configuration
        AE_UnifiedStateTracker.registerTrackingRequest(category, animalID, {
            initialState = newState,
            updateFrequency = "event-based"
        })
        tracked = trackedStates[category][animalID]
    end
    
    local detector = stateChangeDetectors[category]
    if detector and detector(animalID, newState, tracked.lastState) then
        -- State change detected - trigger callbacks
        if tracked.changeCallback then
            local success, error = pcall(tracked.changeCallback, animalID, newState, tracked.lastState)
            if not success then
                print("[AE_UnifiedStateTracker] Callback error for " .. category .. ": " .. tostring(error))
            end
        end
        
        -- Publish state change event
        if AE_EventRegistry then
            AE_EventRegistry.safeFireEvent("OnAE_StateUpdated", {
                animalID = animalID,
                category = category,
                newState = newState,
                oldState = tracked.lastState,
                timestamp = GameTime.getServerTimeMills()
            })
        end
        
        -- Update cached state
        tracked.lastState = newState
        tracked.lastUpdate = GameTime.getServerTimeMills()
        
        return true
    end
    
    return false
end

-- Get current tracked state
function AE_UnifiedStateTracker.getTrackedState(category, animalID)
    if not trackedStates[category] or not trackedStates[category][animalID] then
        return nil
    end
    
    return trackedStates[category][animalID].lastState
end

-- Get all tracked animals in a category
function AE_UnifiedStateTracker.getTrackedAnimals(category)
    if not trackedStates[category] then return {} end
    
    local animals = {}
    for animalID, _ in pairs(trackedStates[category]) do
        table.insert(animals, animalID)
    end
    
    return animals
end

-- Remove tracking for an animal
function AE_UnifiedStateTracker.unregisterTracking(category, animalID)
    if trackedStates[category] and trackedStates[category][animalID] then
        trackedStates[category][animalID] = nil
        return true
    end
    return false
end

-- Remove all tracking for an animal across categories
function AE_UnifiedStateTracker.unregisterAnimal(animalID)
    if not animalID then return false end
    
    local removed = false
    for category, _ in pairs(trackedStates) do
        if trackedStates[category][animalID] then
            trackedStates[category][animalID] = nil
            removed = true
        end
    end
    
    if removed and AE_EventRegistry then
        AE_EventRegistry.safeFireEvent("OnAE_AnimalRemoved", {
            animalID = animalID,
            timestamp = GameTime.getServerTimeMills()
        })
    end
    
    return removed
end

-- Cleanup expired tracking entries
function AE_UnifiedStateTracker.cleanupExpiredTracking()
    local currentTime = GameTime.getServerTimeMills()
    local cleanedCount = 0
    
    for category, categoryData in pairs(trackedStates) do
        local config = trackingConfigs[category]
        if config and config.retention then
            local maxAge = config.retention * 1000 -- Convert to milliseconds
            
            for animalID, tracked in pairs(categoryData) do
                if currentTime - tracked.lastUpdate > maxAge then
                    categoryData[animalID] = nil
                    cleanedCount = cleanedCount + 1
                end
            end
        end
    end
    
    if cleanedCount > 0 then
        print("[AE_UnifiedStateTracker] Cleaned " .. cleanedCount .. " expired tracking entries")
    end
    
    return cleanedCount
end

-- Position tracking integration
function AE_UnifiedStateTracker.updatePosition(animal)
    if not animal then return false end
    
    local animalID = animal:getID()
    local position = {
        x = animal:getX(),
        y = animal:getY(), 
        z = animal:getZ(),
        facing = animal:getFacing(),
        timestamp = GameTime.getServerTimeMills()
    }
    
    return AE_UnifiedStateTracker.updateState("position", animalID, position)
end

-- Behavior tracking integration
function AE_UnifiedStateTracker.updateBehavior(animal, behaviorType, behaviorData)
    if not animal then return false end
    
    local animalID = animal:getID()
    local behavior = {
        type = behaviorType,
        data = behaviorData or {},
        startTime = GameTime.getServerTimeMills()
    }
    
    return AE_UnifiedStateTracker.updateState("behavior", animalID, behavior)
end

-- Status tracking integration
function AE_UnifiedStateTracker.updateStatus(animal)
    if not animal then return false end
    
    local animalID = animal:getID()
    local status = {
        hunger = 0,
        thirst = 0,
        health = 100,
        tameness = 0,
        timestamp = GameTime.getServerTimeMills()
    }
    
    if AE_DataService then
        local hungerSuccess, hungerResult = pcall(function()
            return AE_DataService.getHunger(animal)
        end)
        if hungerSuccess and hungerResult then
            status.hunger = hungerResult
        end
        
        local thirstSuccess, thirstResult = pcall(function()
            return AE_DataService.getThirst(animal)
        end)
        if thirstSuccess and thirstResult then
            status.thirst = thirstResult
        end
        
        local healthSuccess, healthResult = pcall(function()
            return AE_DataService.getHealth(animal)
        end)
        if healthSuccess and healthResult then
            status.health = healthResult
        end
        
        local tamenessSuccess, tamenessResult = pcall(function()
            return AE_DataService.getTameness(animal)
        end)
        if tamenessSuccess and tamenessResult then
            status.tameness = tamenessResult
        end
    end
    
    return AE_UnifiedStateTracker.updateState("status", animalID, status)
end

-- Equipment tracking integration
function AE_UnifiedStateTracker.updateEquipment(animal)
    if not animal then return false end
    
    local animalID = animal:getID()
    local equipment = {
        items = {},
        attachments = {},
        timestamp = GameTime.getServerTimeMills()
    }
    
    if AE_DataService then
        local itemsSuccess, itemsResult = pcall(function()
            return AE_DataService.getEquipment(animal)
        end)
        if itemsSuccess and itemsResult then
            equipment.items = itemsResult
        end
        
        local attachSuccess, attachResult = pcall(function()
            return AE_DataService.getAttachments(animal)
        end)
        if attachSuccess and attachResult then
            equipment.attachments = attachResult
        end
    end
    
    return AE_UnifiedStateTracker.updateState("equipment", animalID, equipment)
end

-- Command tracking integration
function AE_UnifiedStateTracker.updateCommand(animal, command, target, status)
    if not animal then return false end
    
    local animalID = animal:getID()
    local commandData = {
        command = command,
        target = target,
        status = status or "active",
        timestamp = GameTime.getServerTimeMills()
    }
    
    return AE_UnifiedStateTracker.updateState("commands", animalID, commandData)
end

-- Performance monitoring
function AE_UnifiedStateTracker.getTrackingStatistics()
    local stats = {
        totalTrackedAnimals = 0,
        categoryCounts = {},
        memoryUsage = 0,
        lastCleanup = GameTime.getServerTimeMills()
    }
    
    for category, categoryData in pairs(trackedStates) do
        local count = 0
        for _ in pairs(categoryData) do
            count = count + 1
        end
        stats.categoryCounts[category] = count
        stats.totalTrackedAnimals = stats.totalTrackedAnimals + count
    end
    
    return stats
end

-- Event integration for automatic tracking
function AE_UnifiedStateTracker.subscribeToTrackingEvents()
    if not AE_EventRegistry then return false end
    
    -- Animal registration events with defensive check
    if AE_EventRegistry and AE_EventRegistry.subscribeEvent then
        AE_EventRegistry.subscribeEvent("OnAE_AnimalRegistered", function(data)
            if data and data.animal then
                local animalID = data.animal:getID()
                
                -- Initialize tracking for all categories
                for category, config in pairs(trackingConfigs) do
                    AE_UnifiedStateTracker.registerTrackingRequest(category, animalID, {
                        initialState = nil,
                        updateFrequency = config.updateFrequency
                    })
                end
            end
        end)
        
        -- Animal removal events  
        AE_EventRegistry.subscribeEvent("OnAE_AnimalRemoved", function(data)
            if data and data.animalID then
                AE_UnifiedStateTracker.unregisterAnimal(data.animalID)
            end
        end)
    end
    
    return true
end

-- Initialize unified state tracker
function AE_UnifiedStateTracker.initialize()
    -- Defensive initialization with error handling
    local success, error = pcall(function()
        -- Subscribe to tracking events
        AE_UnifiedStateTracker.subscribeToTrackingEvents()
        
        -- Setup periodic cleanup (every 10 minutes)
        -- PHASE 2 CONSOLIDATION: Timer moved to AE_DataCleanupCoordinator
        -- Events.EveryTenMinutes.Add(AE_UnifiedStateTracker.cleanupExpiredTracking) -- Disabled - handled by coordinator
    end)
    
    if not success then
        print("[AE_UnifiedStateTracker] WARNING: Event subscription failed - " .. tostring(error))
        print("[AE_UnifiedStateTracker] Running in manual registration mode")
    end
    
    -- Fire initialization event with sequence counter (MP-safe)
    if AE_EventRegistry then
        -- Global initialization sequence counter
        if not _G.AE_InitSequence then _G.AE_InitSequence = 0 end
        _G.AE_InitSequence = _G.AE_InitSequence + 1
        
        AE_EventRegistry.safeFireEvent("OnAE_SystemInitialized", {
            module = "AE_UnifiedStateTracker",
            categoriesSupported = AE_UnifiedStateTracker.getCategoryCount(),
            initSequence = _G.AE_InitSequence
        })
    end
    
    print("[AE_UnifiedStateTracker] Unified state tracking system initialized")
    return true
end

-- Get category count for monitoring
function AE_UnifiedStateTracker.getCategoryCount()
    local count = 0
    for _ in pairs(trackingConfigs) do
        count = count + 1
    end
    return count
end

-- Export for global access
_G.AE_UnifiedStateTracker = AE_UnifiedStateTracker

-- Initialize on game start
Events.OnGameStart.Add(AE_UnifiedStateTracker.initialize)