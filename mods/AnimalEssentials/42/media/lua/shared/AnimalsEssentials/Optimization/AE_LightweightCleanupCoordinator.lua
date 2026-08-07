local AE_LightweightCleanupCoordinator = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
local CleanupConfig = {
    enabled = true,
    fallbackMode = false,
    staggeredExecution = true,
    debugLogging = false
}

-- Performance tracking
local PerformanceMetrics = {
    totalExecutions = 0,
    totalExecutionTime = 0,
    lastExecutionTime = 0,
    errorCount = 0
}

-- Fallback function references for emergency rollback
local FallbackRegistrations = {}

-- Initialize coordinator with feature flag support
function AE_LightweightCleanupCoordinator.initialize()
    if CleanupConfig.enabled and not CleanupConfig.fallbackMode then
        -- PHASE 3: Cleanup now handled by AE_DefensiveArchitectureCoordinator
        -- Events.EveryTenMinutes.Add(AE_LightweightCleanupCoordinator.performScheduledCleanup) -- Disabled - defensive architecture
        print("[AE_LightweightCleanupCoordinator] Cleanup now handled by defensive architecture")
        
        if CleanupConfig.debugLogging then
            print("[AE_LightweightCleanupCoordinator] Consolidated cleanup mode enabled")
        end
    else
        -- Fallback to individual registrations
        AE_LightweightCleanupCoordinator.enableFallbackMode()
    end
end

-- Main consolidated cleanup function with staggered execution
function AE_LightweightCleanupCoordinator.performScheduledCleanup()
    local startTime = getTimestamp()
    PerformanceMetrics.totalExecutions = PerformanceMetrics.totalExecutions + 1
    
    local success, errorMessage = pcall(function()
        if CleanupConfig.staggeredExecution then
            AE_LightweightCleanupCoordinator.executeStaggeredCleanup()
        else
            AE_LightweightCleanupCoordinator.executeImmediateCleanup()
        end
    end)
    
    -- Performance tracking
    local executionTime = getTimestamp() - startTime
    PerformanceMetrics.totalExecutionTime = PerformanceMetrics.totalExecutionTime + executionTime
    PerformanceMetrics.lastExecutionTime = executionTime
    
    if not success then
        PerformanceMetrics.errorCount = PerformanceMetrics.errorCount + 1
        print("[AE_LightweightCleanupCoordinator] ERROR during cleanup: " .. tostring(errorMessage))
        
        -- Auto-fallback on repeated errors
        if PerformanceMetrics.errorCount >= 3 then
            print("[AE_LightweightCleanupCoordinator] Multiple errors detected, switching to fallback mode")
            AE_LightweightCleanupCoordinator.emergencyRollback()
        end
    end
    
    if CleanupConfig.debugLogging and executionTime > 50 then
        print("[AE_LightweightCleanupCoordinator] Cleanup took " .. executionTime .. "ms")
    end
end

-- Staggered execution to minimize concurrent processing overhead
function AE_LightweightCleanupCoordinator.executeStaggeredCleanup()
    -- Phase 1: Context menu cache (fastest, most frequent)
    if _G.AE_ContextMenuIntegration and AE_ContextMenuIntegration.clearExpiredCache then
        AE_ContextMenuIntegration.clearExpiredCache()
    end
    
    -- Small delay to prevent concurrent execution spikes
    local delayStart = getTimestamp()
    while getTimestamp() - delayStart < 10 do
        -- 10ms micro-delay
    end
    
    if AE_EnvironmentDetector.isSinglePlayer() then
        if _G.AE_TimedActionServerHandler and AE_TimedActionServerHandler.cleanup then
            AE_TimedActionServerHandler.cleanup()
        end

        delayStart = getTimestamp()
        while getTimestamp() - delayStart < 10 do
        end
    else
        if not isClient() then
            if _G.AE_TimedActionServerHandler and AE_TimedActionServerHandler.cleanup then
                AE_TimedActionServerHandler.cleanup()
            end
            
            -- Another micro-delay for server operations
            delayStart = getTimestamp()
            while getTimestamp() - delayStart < 10 do
                -- 10ms micro-delay
            end
        end
    end
    
    if AE_EnvironmentDetector.isSinglePlayer() then
    elseif isClient() then
        if _G.AE_UIPerformanceOptimizer and AE_UIPerformanceOptimizer.performBasicMemoryCleanup then
            AE_UIPerformanceOptimizer.performBasicMemoryCleanup()
        end
    end
end

-- Immediate execution (non-staggered fallback)
function AE_LightweightCleanupCoordinator.executeImmediateCleanup()
    -- Context menu cache cleanup
    if _G.AE_ContextMenuIntegration and AE_ContextMenuIntegration.clearExpiredCache then
        AE_ContextMenuIntegration.clearExpiredCache()
    end
    
    if AE_EnvironmentDetector.isSinglePlayer() then
        if _G.AE_TimedActionServerHandler and AE_TimedActionServerHandler.cleanup then
            AE_TimedActionServerHandler.cleanup()
        end
    else
        if not isClient() then
            if _G.AE_TimedActionServerHandler and AE_TimedActionServerHandler.cleanup then
                AE_TimedActionServerHandler.cleanup()
            end
        end
    end
    
    if AE_EnvironmentDetector.isSinglePlayer() then
    elseif isClient() then
        if _G.AE_UIPerformanceOptimizer and AE_UIPerformanceOptimizer.performBasicMemoryCleanup then
            AE_UIPerformanceOptimizer.performBasicMemoryCleanup()
        end
    end
end

-- Emergency rollback to individual registrations
function AE_LightweightCleanupCoordinator.emergencyRollback()
    print("[AE_LightweightCleanupCoordinator] Performing emergency rollback to individual registrations")
    
    -- Disable consolidated cleanup with defensive Events checking
    if Events and Events.EveryTenMinutes then
        Events.EveryTenMinutes.Remove(AE_LightweightCleanupCoordinator.performScheduledCleanup)
    end
    
    -- Re-enable original individual registrations with defensive Events checking
    -- PHASE 1 EMERGENCY FIX: Remove duplicate timer registrations
    -- These systems register themselves in their own files, no need to re-register here
    if Events and Events.EveryTenMinutes then
        print("[AE_LightweightCleanupCoordinator] Fallback mode - individual systems handle their own timer registration")
        -- Note: AE_ContextMenuIntegration and AE_TimedActionServerHandler register themselves
        -- Duplicate registration removed to prevent performance issues
    end
    
    -- Note: UI memory optimization is more complex, keeping consolidated for now
    
    CleanupConfig.fallbackMode = true
    print("[AE_LightweightCleanupCoordinator] Rollback completed, fallback mode enabled")
end

-- Manual fallback mode initialization
function AE_LightweightCleanupCoordinator.enableFallbackMode()
    print("[AE_LightweightCleanupCoordinator] Fallback mode enabled - individual systems register themselves")
    
    -- PHASE 1 EMERGENCY FIX: Remove duplicate timer registrations
    -- Individual systems handle their own registration in their respective files
    -- No need to re-register here to avoid performance overhead
    
    CleanupConfig.fallbackMode = true
end

-- Performance reporting
function AE_LightweightCleanupCoordinator.getPerformanceReport()
    local avgExecutionTime = PerformanceMetrics.totalExecutions > 0 and 
        (PerformanceMetrics.totalExecutionTime / PerformanceMetrics.totalExecutions) or 0
    
    return {
        totalExecutions = PerformanceMetrics.totalExecutions,
        averageExecutionTime = avgExecutionTime,
        lastExecutionTime = PerformanceMetrics.lastExecutionTime,
        errorCount = PerformanceMetrics.errorCount,
        fallbackMode = CleanupConfig.fallbackMode
    }
end

-- CleanupConfiguration management
function AE_LightweightCleanupCoordinator.setCleanupConfig(newCleanupConfig)
    for key, value in pairs(newCleanupConfig) do
        if CleanupConfig[key] ~= nil then
            CleanupConfig[key] = value
        end
    end
end

function AE_LightweightCleanupCoordinator.getCleanupConfig()
    return CleanupConfig
end

-- Initialize on game start with defensive Events checking
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(AE_LightweightCleanupCoordinator.initialize)
end

-- Shutdown cleanup with defensive Events checking
if Events and Events.OnGameEnd then
    Events.OnGameEnd.Add(function()
        if Events and Events.EveryTenMinutes then
            Events.EveryTenMinutes.Remove(AE_LightweightCleanupCoordinator.performScheduledCleanup)
        end
    end)
end

return AE_LightweightCleanupCoordinator