AE_EventRegistry = {}

-- Core mod communication events for inter-mod coordination
-- These events enable communication between Framework Data, Framework Core, and KittyMod
AE_EventRegistry.EVENTS = {
    -- Data layer events - Framework Data mod authority
    OnAE_DataLayerInitialized = "OnAE_DataLayerInitialized",
    OnAE_AnimalRegistered = "OnAE_AnimalRegistered",
    OnAE_AnimalRemoved = "OnAE_AnimalRemoved", 
    OnAE_StateUpdated = "OnAE_StateUpdated",
    OnAE_DataIntegrityCheck = "OnAE_DataIntegrityCheck",
    
    -- Command processing events - Framework Core coordination
    OnAE_CommandRequest = "OnAE_CommandRequest",
    OnAE_CommandProcessed = "OnAE_CommandProcessed",
    OnAE_CommandValidation = "OnAE_CommandValidation",
    OnAE_BehaviorStateChange = "OnAE_BehaviorStateChange",
    
    -- Framework integration events - Cross-mod coordination
    OnAE_FrameworkAvailable = "OnAE_FrameworkAvailable",
    OnAE_ModRegistration = "OnAE_ModRegistration",
    OnAE_GracefulDegradation = "OnAE_GracefulDegradation",
    OnAE_ModuleLoaded = "OnAE_ModuleLoaded",
    
    -- System coordination events - Lifecycle management
    OnAE_SystemInitialized = "OnAE_SystemInitialized",
    OnAE_SystemShutdown = "OnAE_SystemShutdown",
    OnAE_PerformanceMonitor = "OnAE_PerformanceMonitor",
    OnAE_ConfigurationUpdate = "OnAE_ConfigurationUpdate"
}

-- Event registration and management - B42 graceful degradation
function AE_EventRegistry.initialize()
    -- B42 Note: Custom event creation not supported, using graceful degradation
    -- Internal event system will log events but not use PZ event system
    
    print("[AE_EventRegistry] B42 Mode: Using internal event logging (custom events not supported)")
    
    -- Log initialization complete
    print("[AE_EventRegistry] System initialized - " .. AE_EventRegistry.getEventCount() .. " event types registered")
end

-- B42 graceful degradation - internal event logging only
function AE_EventRegistry.safeFireEvent(eventName, data)
    -- Validate event exists in our registry
    if not AE_EventRegistry.EVENTS[eventName] and not eventName then
        print("[AE_EventRegistry] WARNING: Unknown event: " .. tostring(eventName))
        return false
    end
    
    -- B42 Mode: Log event instead of firing (custom events not supported)
    local actualEventName = eventName
    if AE_EventRegistry.EVENTS[eventName] then
        actualEventName = AE_EventRegistry.EVENTS[eventName]
    end
    
    -- Create safe timestamp without getGameTime dependency
    local timestamp = "N/A"
    if getGameTime then
        local success, timeResult = pcall(function()
            return GameTime.getServerTimeMills()
        end)
        if success then
            timestamp = timeResult
        end
    end
    
    -- Log event for debugging (graceful degradation)
    print("[AE_EventRegistry] Event logged: " .. actualEventName .. " at " .. timestamp)
    
    return true
end

-- Event subscription helper - B42 graceful degradation
function AE_EventRegistry.subscribeEvent(eventName, callback)
    if not AE_EventRegistry.EVENTS[eventName] then
        print("[AE_EventRegistry] WARNING: Subscribing to unknown event: " .. tostring(eventName))
        return false
    end
    
    -- B42 Mode: Log subscription but don't actually subscribe (custom events not supported)
    local actualEventName = AE_EventRegistry.EVENTS[eventName]
    print("[AE_EventRegistry] Event subscription logged: " .. actualEventName)
    return true
end

-- Utility functions for event system management
function AE_EventRegistry.getEventCount()
    local count = 0
    for _ in pairs(AE_EventRegistry.EVENTS) do
        count = count + 1
    end
    return count
end

function AE_EventRegistry.isEventRegistered(eventName)
    return AE_EventRegistry.EVENTS[eventName] ~= nil
end

-- Performance monitoring for event propagation
function AE_EventRegistry.trackEventPerformance(eventName, startTime)
    local duration = GameTime.getServerTimeMills() - startTime
    if duration > 100 then -- Alert if event takes over 100ms
        print("[AE_EventRegistry] PERFORMANCE: Event " .. eventName .. " took " .. duration .. "ms")
    end
end

-- Export for global access
_G.AE_EventRegistry = AE_EventRegistry

-- Initialize event registry on game boot
Events.OnGameBoot.Add(AE_EventRegistry.initialize)

return AE_EventRegistry