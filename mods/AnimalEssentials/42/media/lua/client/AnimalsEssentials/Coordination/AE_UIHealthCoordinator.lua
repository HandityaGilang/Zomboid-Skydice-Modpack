local AE_UIHealthCoordinator = {}

-- PHASE 2 CONSOLIDATION: Centralized UI health and performance coordinator
-- Consolidates 6+ individual UI monitoring systems into single 30-minute timer

-- Configuration
local UIHealthConfig = {
    enabled = true,
    interval = 30, -- 30 minutes (reduced from 10 minutes)
    debugMode = false,
    lastExecutionTime = 0,
    enablePerformanceAnalysis = true,
    enableArchitectureValidation = true,
    enableAutomatedTesting = false, -- Disabled by default to reduce overhead
    enableServiceHealthChecks = true
}

-- Performance tracking
local PerformanceMetrics = {
    totalExecutions = 0,
    totalExecutionTime = 0,
    lastExecutionDuration = 0,
    healthResults = {}
}

-- Centralized UI health monitoring function
function AE_UIHealthCoordinator.performConsolidatedHealthCheck()
    if not UIHealthConfig.enabled then
        return
    end
    
    local startTime = getTimestampMs()
    local currentTime = getTimestamp()
    
    -- Rate limiting: Only execute every 30 minutes
    if currentTime - UIHealthConfig.lastExecutionTime < (UIHealthConfig.interval * 60) then
        return
    end
    
    UIHealthConfig.lastExecutionTime = currentTime
    PerformanceMetrics.totalExecutions = PerformanceMetrics.totalExecutions + 1
    
    if UIHealthConfig.debugMode then
        print("[AE_UIHealthCoordinator] Starting consolidated UI health check cycle")
    end
    
    local healthResults = {
        performanceAnalysis = false,
        architectureValidation = false,
        automatedTesting = false,
        serviceHealthCheck = false,
        issuesDetected = 0
    }
    
    -- 1. UI Performance Analysis (from AE_UIPerformanceOptimizer)
    if UIHealthConfig.enablePerformanceAnalysis then
        local success1, result1 = pcall(function()
            if _G.AE_UIPerformanceOptimizer then
                if AE_UIPerformanceOptimizer.analyzePerformanceMetrics then
                    AE_UIPerformanceOptimizer.analyzePerformanceMetrics()
                end
                if AE_UIPerformanceOptimizer.optimizeBasedOnMetrics then
                    AE_UIPerformanceOptimizer.optimizeBasedOnMetrics()
                end
                return true
            end
            return false
        end)
        healthResults.performanceAnalysis = success1 and result1
    end
    
    -- 2. UI Architecture Validation (from AE_UIArchitectureValidator)
    if UIHealthConfig.enableArchitectureValidation then
        local success2, result2 = pcall(function()
            if _G.AE_UIArchitectureValidator and AE_UIArchitectureValidator.performPeriodicValidation then
                AE_UIArchitectureValidator.performPeriodicValidation()
                return true
            end
            return false
        end)
        healthResults.architectureValidation = success2 and result2
    end
    
    -- 3. Automated Testing (from AE_UITestingFramework) - Optional
    if UIHealthConfig.enableAutomatedTesting then
        local success3, result3 = pcall(function()
            if _G.AE_UITestingFramework and AE_UITestingFramework.runAutomatedTestSuite then
                AE_UITestingFramework.runAutomatedTestSuite()
                return true
            end
            return false
        end)
        healthResults.automatedTesting = success3 and result3
    end
    
    -- 4. Service Health Check (from AE_UIEventCoordinator)
    if UIHealthConfig.enableServiceHealthChecks then
        local success4, result4 = pcall(function()
            if _G.AE_UIEventCoordinator and AE_UIEventCoordinator.performServiceHealthCheck then
                AE_UIEventCoordinator.performServiceHealthCheck()
                return true
            end
            return false
        end)
        healthResults.serviceHealthCheck = success4 and result4
    end
    
    -- Count any issues detected
    healthResults.issuesDetected = 0
    for key, value in pairs(healthResults) do
        if key ~= "issuesDetected" and not value then
            healthResults.issuesDetected = healthResults.issuesDetected + 1
        end
    end
    
    -- Performance tracking
    local endTime = getTimestampMs()
    local executionTime = endTime - startTime
    PerformanceMetrics.lastExecutionDuration = executionTime
    PerformanceMetrics.totalExecutionTime = PerformanceMetrics.totalExecutionTime + executionTime
    PerformanceMetrics.healthResults = healthResults
    
    if UIHealthConfig.debugMode or healthResults.issuesDetected > 0 then
        print("[AE_UIHealthCoordinator] Health check completed: " .. healthResults.issuesDetected .. 
              " issues detected in " .. executionTime .. "ms")
    end
end

-- Configuration functions
function AE_UIHealthCoordinator.setConfig(config)
    for key, value in pairs(config) do
        if UIHealthConfig[key] ~= nil then
            UIHealthConfig[key] = value
        end
    end
end

function AE_UIHealthCoordinator.getPerformanceReport()
    local avgExecutionTime = PerformanceMetrics.totalExecutions > 0 and 
        (PerformanceMetrics.totalExecutionTime / PerformanceMetrics.totalExecutions) or 0
    
    return {
        enabled = UIHealthConfig.enabled,
        totalExecutions = PerformanceMetrics.totalExecutions,
        averageExecutionTime = avgExecutionTime,
        lastExecutionDuration = PerformanceMetrics.lastExecutionDuration,
        lastHealthResults = PerformanceMetrics.healthResults,
        intervalMinutes = UIHealthConfig.interval,
        enabledComponents = {
            performanceAnalysis = UIHealthConfig.enablePerformanceAnalysis,
            architectureValidation = UIHealthConfig.enableArchitectureValidation,
            automatedTesting = UIHealthConfig.enableAutomatedTesting,
            serviceHealthChecks = UIHealthConfig.enableServiceHealthChecks
        }
    }
end

-- System initialization
function AE_UIHealthCoordinator.initialize()
    if not UIHealthConfig.enabled then
        print("[AE_UIHealthCoordinator] UI health coordinator disabled")
        return
    end
    
    -- PHASE 3: Dynamic registration controlled by AE_DefensiveArchitectureCoordinator
    -- Events.EveryTenMinutes.Add(AE_UIHealthCoordinator.performConsolidatedHealthCheck) -- Disabled - dynamic registration
    print("[AE_UIHealthCoordinator] Ready for dynamic registration (controlled by defensive architecture)")
end

-- System shutdown
function AE_UIHealthCoordinator.shutdown()
    if Events and Events.EveryTenMinutes then
        Events.EveryTenMinutes.Remove(AE_UIHealthCoordinator.performConsolidatedHealthCheck)
    end
    print("[AE_UIHealthCoordinator] UI health coordinator shutdown")
end

-- Event registration
if Events then
    if Events.OnGameStart then
        Events.OnGameStart.Add(AE_UIHealthCoordinator.initialize)
    end
    
    if Events.OnGameEnd then
        Events.OnGameEnd.Add(AE_UIHealthCoordinator.shutdown)
    end
    
    if Events.OnDisconnect then
        Events.OnDisconnect.Add(AE_UIHealthCoordinator.shutdown)
    end
else
    print("[AE_UIHealthCoordinator] ERROR: Events table not available")
end

print("[AE_UIHealthCoordinator] UI health coordination system loaded")

return AE_UIHealthCoordinator