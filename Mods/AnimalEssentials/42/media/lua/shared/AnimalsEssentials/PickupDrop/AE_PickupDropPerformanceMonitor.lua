AE_PickupDropPerformanceMonitor = {}

AE_PickupDropPerformanceMonitor.Config = {
    metricsWindowMs = 60000,
    performanceUpdateIntervalMs = 10000,
    alertThresholds = {
        highDetectionFrequency = 50,
        lowSuccessRate = 0.7,
        highCorrelationTime = 5000,
        excessiveTrackedAnimals = 100
    }
}

AE_PickupDropPerformanceMonitor.Metrics = {
    detectionEvents = {},
    preservationAttempts = {},
    preservationSuccesses = {},
    correlationTimes = {},
    trackedAnimalCounts = {},
    errorCounts = {},
    startTime = nil
}

function AE_PickupDropPerformanceMonitor.initialize()
    if AE_PickupDropPerformanceMonitor.initialized then return end
    
    AE_PickupDropPerformanceMonitor.Metrics.startTime = getTimestampMs()
    
    Events.OnTick.Add(AE_PickupDropPerformanceMonitor.updateMetrics)
    
    AE_PickupDropPerformanceMonitor.initialized = true
end

function AE_PickupDropPerformanceMonitor.recordDetectionEvent(animal, eventType)
    if not animal then return end
    
    local currentTime = getTimestampMs()
    local eventData = {
        timestamp = currentTime,
        animalID = tostring(animal:getOnlineID()),
        eventType = eventType,
        animalType = animal:getAnimalType() or "unknown"
    }
    
    table.insert(AE_PickupDropPerformanceMonitor.Metrics.detectionEvents, eventData)
end

function AE_PickupDropPerformanceMonitor.recordPreservationAttempt(animal, correlationID)
    if not animal or not correlationID then return end
    
    local currentTime = getTimestampMs()
    local attemptData = {
        timestamp = currentTime,
        animalID = tostring(animal:getOnlineID()),
        correlationID = correlationID,
        startTime = currentTime
    }
    
    table.insert(AE_PickupDropPerformanceMonitor.Metrics.preservationAttempts, attemptData)
end

function AE_PickupDropPerformanceMonitor.recordPreservationSuccess(animal, correlationID, restorationTime)
    if not animal or not correlationID then return end
    
    local currentTime = getTimestampMs()
    local successData = {
        timestamp = currentTime,
        animalID = tostring(animal:getOnlineID()),
        correlationID = correlationID,
        restorationTime = restorationTime or 0
    }
    
    table.insert(AE_PickupDropPerformanceMonitor.Metrics.preservationSuccesses, successData)
end

function AE_PickupDropPerformanceMonitor.recordCorrelationTime(correlationID, startTime, endTime)
    if not correlationID or not startTime or not endTime then return end
    
    local correlationTime = endTime - startTime
    local correlationData = {
        timestamp = endTime,
        correlationID = correlationID,
        correlationTime = correlationTime
    }
    
    table.insert(AE_PickupDropPerformanceMonitor.Metrics.correlationTimes, correlationData)
end

function AE_PickupDropPerformanceMonitor.recordTrackedAnimalCount()
    local currentTime = getTimestampMs()
    local animalCount = 0
    
    if AE_PickupDropDetector and AE_PickupDropDetector.TrackedAnimals then
        for _ in pairs(AE_PickupDropDetector.TrackedAnimals) do
            animalCount = animalCount + 1
        end
    end
    
    local countData = {
        timestamp = currentTime,
        trackedCount = animalCount
    }
    
    table.insert(AE_PickupDropPerformanceMonitor.Metrics.trackedAnimalCounts, countData)
end

function AE_PickupDropPerformanceMonitor.recordError(errorType, details)
    local currentTime = getTimestampMs()
    local errorData = {
        timestamp = currentTime,
        errorType = errorType,
        details = details or "No details provided"
    }
    
    table.insert(AE_PickupDropPerformanceMonitor.Metrics.errorCounts, errorData)
end

function AE_PickupDropPerformanceMonitor.calculateMetrics()
    local currentTime = getTimestampMs()
    local windowStart = currentTime - AE_PickupDropPerformanceMonitor.Config.metricsWindowMs
    
    local windowMetrics = {
        detectionFrequency = 0,
        preservationSuccessRate = 0,
        averageCorrelationTime = 0,
        currentTrackedAnimals = 0,
        errorFrequency = 0,
        performanceAlerts = {}
    }
    
    local recentDetections = 0
    for _, event in ipairs(AE_PickupDropPerformanceMonitor.Metrics.detectionEvents) do
        if event.timestamp > windowStart then
            recentDetections = recentDetections + 1
        end
    end
    windowMetrics.detectionFrequency = recentDetections
    
    local recentAttempts = 0
    local recentSuccesses = 0
    for _, attempt in ipairs(AE_PickupDropPerformanceMonitor.Metrics.preservationAttempts) do
        if attempt.timestamp > windowStart then
            recentAttempts = recentAttempts + 1
        end
    end
    for _, success in ipairs(AE_PickupDropPerformanceMonitor.Metrics.preservationSuccesses) do
        if success.timestamp > windowStart then
            recentSuccesses = recentSuccesses + 1
        end
    end
    
    if recentAttempts > 0 then
        windowMetrics.preservationSuccessRate = recentSuccesses / recentAttempts
    else
        windowMetrics.preservationSuccessRate = 1.0
    end
    
    local totalCorrelationTime = 0
    local correlationCount = 0
    for _, correlation in ipairs(AE_PickupDropPerformanceMonitor.Metrics.correlationTimes) do
        if correlation.timestamp > windowStart then
            totalCorrelationTime = totalCorrelationTime + correlation.correlationTime
            correlationCount = correlationCount + 1
        end
    end
    
    if correlationCount > 0 then
        windowMetrics.averageCorrelationTime = totalCorrelationTime / correlationCount
    end
    
    if #AE_PickupDropPerformanceMonitor.Metrics.trackedAnimalCounts > 0 then
        local latestCount = AE_PickupDropPerformanceMonitor.Metrics.trackedAnimalCounts[#AE_PickupDropPerformanceMonitor.Metrics.trackedAnimalCounts]
        windowMetrics.currentTrackedAnimals = latestCount.trackedCount
    end
    
    local recentErrors = 0
    for _, error in ipairs(AE_PickupDropPerformanceMonitor.Metrics.errorCounts) do
        if error.timestamp > windowStart then
            recentErrors = recentErrors + 1
        end
    end
    windowMetrics.errorFrequency = recentErrors
    
    local thresholds = AE_PickupDropPerformanceMonitor.Config.alertThresholds
    
    if windowMetrics.detectionFrequency > thresholds.highDetectionFrequency then
        table.insert(windowMetrics.performanceAlerts, "High detection frequency: " .. windowMetrics.detectionFrequency .. " events/minute")
    end
    
    if windowMetrics.preservationSuccessRate < thresholds.lowSuccessRate then
        table.insert(windowMetrics.performanceAlerts, "Low success rate: " .. string.format("%.2f", windowMetrics.preservationSuccessRate * 100) .. "%")
    end
    
    if windowMetrics.averageCorrelationTime > thresholds.highCorrelationTime then
        table.insert(windowMetrics.performanceAlerts, "High correlation time: " .. windowMetrics.averageCorrelationTime .. "ms")
    end
    
    if windowMetrics.currentTrackedAnimals > thresholds.excessiveTrackedAnimals then
        table.insert(windowMetrics.performanceAlerts, "Excessive tracked animals: " .. windowMetrics.currentTrackedAnimals)
    end
    
    return windowMetrics
end

function AE_PickupDropPerformanceMonitor.updateMetrics()
    local currentTime = getTimestampMs()
    
    if not AE_PickupDropPerformanceMonitor.lastUpdate then
        AE_PickupDropPerformanceMonitor.lastUpdate = currentTime
        return
    end
    
    if currentTime - AE_PickupDropPerformanceMonitor.lastUpdate < AE_PickupDropPerformanceMonitor.Config.performanceUpdateIntervalMs then
        return
    end
    
    AE_PickupDropPerformanceMonitor.recordTrackedAnimalCount()
    AE_PickupDropPerformanceMonitor.cleanupOldMetrics()
    
    AE_PickupDropPerformanceMonitor.lastUpdate = currentTime
end

function AE_PickupDropPerformanceMonitor.cleanupOldMetrics()
    local currentTime = getTimestampMs()
    local cutoffTime = currentTime - (AE_PickupDropPerformanceMonitor.Config.metricsWindowMs * 2)
    
    local cleanupArrays = {
        "detectionEvents",
        "preservationAttempts", 
        "preservationSuccesses",
        "correlationTimes",
        "trackedAnimalCounts",
        "errorCounts"
    }
    
    for _, arrayName in ipairs(cleanupArrays) do
        local array = AE_PickupDropPerformanceMonitor.Metrics[arrayName]
        local newArray = {}
        
        for _, item in ipairs(array) do
            if item.timestamp > cutoffTime then
                table.insert(newArray, item)
            end
        end
        
        AE_PickupDropPerformanceMonitor.Metrics[arrayName] = newArray
    end
end

function AE_PickupDropPerformanceMonitor.getPerformanceReport()
    local metrics = AE_PickupDropPerformanceMonitor.calculateMetrics()
    local currentTime = getTimestampMs()
    local uptime = currentTime - (AE_PickupDropPerformanceMonitor.Metrics.startTime or currentTime)
    
    local report = {
        timestamp = currentTime,
        uptimeMs = uptime,
        currentMetrics = metrics,
        systemHealth = "Good"
    }
    
    if #metrics.performanceAlerts > 0 then
        if #metrics.performanceAlerts >= 3 then
            report.systemHealth = "Poor"
        elseif #metrics.performanceAlerts >= 2 then
            report.systemHealth = "Warning"
        else
            report.systemHealth = "Caution"
        end
    end
    
    return report
end

Events.OnGameStart.Add(AE_PickupDropPerformanceMonitor.initialize)

return AE_PickupDropPerformanceMonitor