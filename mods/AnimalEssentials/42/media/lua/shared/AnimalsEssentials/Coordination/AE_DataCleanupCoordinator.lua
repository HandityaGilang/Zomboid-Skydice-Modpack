local AE_DataCleanupCoordinator = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
-- Consolidates 5+ individual cleanup systems into single 30-minute timer

-- Configuration
local CleanupConfig = {
    enabled = true,
    interval = 30, -- 30 minutes (reduced from 10 minutes)
    debugMode = false,
    lastExecutionTime = 0
}

-- Performance tracking
local PerformanceMetrics = {
    totalExecutions = 0,
    totalExecutionTime = 0,
    lastExecutionDuration = 0,
    cleanupResults = {}
}

-- Centralized cleanup function that coordinates all data cleanup operations
function AE_DataCleanupCoordinator.performConsolidatedCleanup()
    if not CleanupConfig.enabled then
        return
    end
    
    local startTime = getTimestampMs()
    local currentTime = getTimestamp()
    
    -- Rate limiting: Only execute every 30 minutes
    if currentTime - CleanupConfig.lastExecutionTime < (CleanupConfig.interval * 60) then
        return
    end
    
    CleanupConfig.lastExecutionTime = currentTime
    PerformanceMetrics.totalExecutions = PerformanceMetrics.totalExecutions + 1
    
    if CleanupConfig.debugMode then
        print("[AE_DataCleanupCoordinator] Starting consolidated cleanup cycle")
    end
    
    local cleanupResults = {
        modDataCache = 0,
        stateTracking = 0,
        serverActions = 0,
        contextMenu = 0,
        totalCleaned = 0
    }
    
    -- 1. ModData Cache Cleanup
    local success1, result1 = pcall(function()
        if _G.AE_ModDataManager and AE_ModDataManager.cleanupCache then
            return AE_ModDataManager.cleanupCache()
        end
        return 0
    end)
    if success1 then
        cleanupResults.modDataCache = result1 or 0
    end
    
    -- 2. State Tracking Cleanup  
    local success2, result2 = pcall(function()
        if _G.AE_UnifiedStateTracker and AE_UnifiedStateTracker.cleanupExpiredTracking then
            return AE_UnifiedStateTracker.cleanupExpiredTracking()
        end
        return 0
    end)
    if success2 then
        cleanupResults.stateTracking = result2 or 0
    end
    
    if AE_EnvironmentDetector.isSinglePlayer() then
        local success3, result3 = pcall(function()
            if _G.AE_TimedActionServerHandler and AE_TimedActionServerHandler.cleanup then
                return AE_TimedActionServerHandler.cleanup()
            end
            return 0
        end)
        if success3 then
            cleanupResults.serverActions = result3 or 0
        end
    else
        if not isClient() then
            local success3, result3 = pcall(function()
                if _G.AE_TimedActionServerHandler and AE_TimedActionServerHandler.cleanup then
                    return AE_TimedActionServerHandler.cleanup()
                end
                return 0
            end)
            if success3 then
                cleanupResults.serverActions = result3 or 0
            end
        end
    end
    
    if AE_EnvironmentDetector.isSinglePlayer() then
    elseif isClient() then
        local success4, result4 = pcall(function()
            if _G.AE_ContextMenuIntegration and AE_ContextMenuIntegration.clearExpiredCache then
                return AE_ContextMenuIntegration.clearExpiredCache()
            end
            return 0
        end)
        if success4 then
            cleanupResults.contextMenu = result4 or 0
        end
    end
    
    -- Calculate totals
    cleanupResults.totalCleaned = cleanupResults.modDataCache + cleanupResults.stateTracking + 
                                  cleanupResults.serverActions + cleanupResults.contextMenu
    
    -- Performance tracking
    local endTime = getTimestampMs()
    local executionTime = endTime - startTime
    PerformanceMetrics.lastExecutionDuration = executionTime
    PerformanceMetrics.totalExecutionTime = PerformanceMetrics.totalExecutionTime + executionTime
    PerformanceMetrics.cleanupResults = cleanupResults
    
    if CleanupConfig.debugMode or cleanupResults.totalCleaned > 0 then
        print("[AE_DataCleanupCoordinator] Cleanup completed: " .. cleanupResults.totalCleaned .. 
              " items cleaned in " .. executionTime .. "ms")
    end
end

-- Configuration functions
function AE_DataCleanupCoordinator.setConfig(config)
    for key, value in pairs(config) do
        if CleanupConfig[key] ~= nil then
            CleanupConfig[key] = value
        end
    end
end

function AE_DataCleanupCoordinator.getPerformanceReport()
    local avgExecutionTime = PerformanceMetrics.totalExecutions > 0 and 
        (PerformanceMetrics.totalExecutionTime / PerformanceMetrics.totalExecutions) or 0
    
    return {
        enabled = CleanupConfig.enabled,
        totalExecutions = PerformanceMetrics.totalExecutions,
        averageExecutionTime = avgExecutionTime,
        lastExecutionDuration = PerformanceMetrics.lastExecutionDuration,
        lastCleanupResults = PerformanceMetrics.cleanupResults,
        intervalMinutes = CleanupConfig.interval
    }
end

-- System initialization
function AE_DataCleanupCoordinator.initialize()
    if not CleanupConfig.enabled then
        print("[AE_DataCleanupCoordinator] Data cleanup coordinator disabled")
        return
    end
    
    -- PHASE 3: Dynamic registration controlled by AE_DefensiveArchitectureCoordinator
    -- Events.EveryTenMinutes.Add(AE_DataCleanupCoordinator.performConsolidatedCleanup) -- Disabled - dynamic registration
    print("[AE_DataCleanupCoordinator] Ready for dynamic registration (controlled by defensive architecture)")
end

-- System shutdown
function AE_DataCleanupCoordinator.shutdown()
    if Events and Events.EveryTenMinutes then
        Events.EveryTenMinutes.Remove(AE_DataCleanupCoordinator.performConsolidatedCleanup)
    end
    print("[AE_DataCleanupCoordinator] Data cleanup coordinator shutdown")
end

-- Event registration
if Events then
    if Events.OnGameStart then
        Events.OnGameStart.Add(AE_DataCleanupCoordinator.initialize)
    end
    
    if Events.OnGameEnd then
        Events.OnGameEnd.Add(AE_DataCleanupCoordinator.shutdown)
    end
    
    if Events.OnDisconnect then
        Events.OnDisconnect.Add(AE_DataCleanupCoordinator.shutdown)
    end
else
    print("[AE_DataCleanupCoordinator] ERROR: Events table not available")
end

print("[AE_DataCleanupCoordinator] Data cleanup coordination system loaded")

return AE_DataCleanupCoordinator