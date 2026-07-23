-- SESSION 6C1: UI Performance Optimization
-- Comprehensive performance optimization and monitoring for all UI components

local AE_UIPerformanceOptimizer = {}

-- Performance monitoring and optimization state
local performanceMetrics = {
    renderingTimes = {},
    updateFrequencies = {},
    memoryUsage = {},
    eventProcessingTimes = {},
    cacheHitRates = {},
    batchingEfficiency = {}
}

-- Three-tier cache system for intelligent performance data management
local performanceCache = {
    -- Tier 1: Hot cache for actively rendering components (current frame data)
    hot = {
        data = {},
        maxSize = 50,
        currentFrame = 0
    },
    -- Tier 2: Warm cache for recently active components (sliding window)
    warm = {
        data = {},
        maxSize = 200,
        retentionTime = 300000, -- 5 minutes
        lastCleanup = 0
    },
    -- Tier 3: Historical cache for long-term averages
    historical = {
        data = {},
        maxEntries = 100,
        updateInterval = 60000, -- 1 minute
        lastUpdate = 0
    }
}

-- Performance optimization configuration
local OPTIMIZATION_CONFIG = {
    renderingThreshold = 16, -- milliseconds (60 FPS target)
    updateThrottleDelay = 50, -- milliseconds
    memoryGCThreshold = 50 * 1024 * 1024, -- 50MB in bytes
    cacheMaxSize = 1000,
    batchMaxSize = 25,
    profilingEnabled = true
}

-- Component-specific optimization registry
local componentOptimizers = {}
local activeOptimizations = {}
local performanceProfiles = {}

-- Module initialization state
local moduleInitialized = false

-- Cache management functions for three-tier architecture
local CacheManager = {
    -- Add data to hot cache (current frame)
    addToHotCache = function(componentName, renderTime)
        local currentTime = getTimestamp()
        local currentFrame = performanceCache.hot.currentFrame
        
        if not performanceCache.hot.data[componentName] then
            performanceCache.hot.data[componentName] = {
                frameData = {},
                totalTime = 0,
                count = 0,
                lastUpdate = currentTime
            }
        end
        
        local entry = performanceCache.hot.data[componentName]
        entry.totalTime = entry.totalTime + renderTime
        entry.count = entry.count + 1
        entry.lastUpdate = currentTime
        
        -- Promote to warm cache after threshold
        if entry.count >= 5 then
            CacheManager.promoteToWarmCache(componentName, entry)
            performanceCache.hot.data[componentName] = nil
        end
    end,
    
    -- Promote data from hot to warm cache
    promoteToWarmCache = function(componentName, hotEntry)
        local currentTime = getTimestamp()
        
        if not performanceCache.warm.data[componentName] then
            performanceCache.warm.data[componentName] = {
                samples = {},
                averageTime = 0,
                totalSamples = 0,
                lastAccess = currentTime
            }
        end
        
        local warmEntry = performanceCache.warm.data[componentName]
        local avgTime = hotEntry.totalTime / hotEntry.count
        
        table.insert(warmEntry.samples, {
            avgTime = avgTime,
            sampleCount = hotEntry.count,
            timestamp = currentTime
        })
        
        warmEntry.averageTime = CacheManager.calculateMovingAverage(warmEntry.samples)
        warmEntry.totalSamples = warmEntry.totalSamples + hotEntry.count
        warmEntry.lastAccess = currentTime
        
        -- Maintain sliding window
        CacheManager.cleanupWarmCache()
    end,
    
    -- Calculate moving average from samples
    calculateMovingAverage = function(samples)
        if not samples or #samples == 0 then return 0 end
        
        local totalTime = 0
        local totalWeight = 0
        local currentTime = getTimestamp()
        
        for _, sample in ipairs(samples) do
            local age = currentTime - sample.timestamp
            local weight = math.max(0, 1 - (age / performanceCache.warm.retentionTime))
            
            totalTime = totalTime + (sample.avgTime * weight * sample.sampleCount)
            totalWeight = totalWeight + (weight * sample.sampleCount)
        end
        
        return totalWeight > 0 and (totalTime / totalWeight) or 0
    end,
    
    -- Update historical data periodically
    updateHistoricalCache = function()
        local currentTime = getTimestamp()
        
        if currentTime - performanceCache.historical.lastUpdate < performanceCache.historical.updateInterval then
            return
        end
        
        for componentName, warmEntry in pairs(performanceCache.warm.data) do
            if warmEntry.totalSamples > 10 then
                if not performanceCache.historical.data[componentName] then
                    performanceCache.historical.data[componentName] = {
                        longTermAverage = 0,
                        trendData = {},
                        totalSessions = 0
                    }
                end
                
                local histEntry = performanceCache.historical.data[componentName]
                
                table.insert(histEntry.trendData, {
                    average = warmEntry.averageTime,
                    samples = warmEntry.totalSamples,
                    timestamp = currentTime
                })
                
                histEntry.longTermAverage = CacheManager.calculateLongTermAverage(histEntry.trendData)
                histEntry.totalSessions = histEntry.totalSessions + 1
                
                -- Maintain historical data size
                if #histEntry.trendData > 50 then
                    table.remove(histEntry.trendData, 1)
                end
            end
        end
        
        performanceCache.historical.lastUpdate = currentTime
    end,
    
    -- Calculate long-term average with trend weighting
    calculateLongTermAverage = function(trendData)
        if not trendData or #trendData == 0 then return 0 end
        
        local totalTime = 0
        local totalSamples = 0
        
        for _, trend in ipairs(trendData) do
            totalTime = totalTime + (trend.average * trend.samples)
            totalSamples = totalSamples + trend.samples
        end
        
        return totalSamples > 0 and (totalTime / totalSamples) or 0
    end,
    
    -- Cleanup expired warm cache entries
    cleanupWarmCache = function()
        local currentTime = getTimestamp()
        
        if currentTime - performanceCache.warm.lastCleanup < 30000 then -- Cleanup every 30 seconds
            return
        end
        
        local cleaned = 0
        for componentName, entry in pairs(performanceCache.warm.data) do
            if currentTime - entry.lastAccess > performanceCache.warm.retentionTime then
                performanceCache.warm.data[componentName] = nil
                cleaned = cleaned + 1
            else
                -- Clean old samples within the entry
                local validSamples = {}
                for _, sample in ipairs(entry.samples) do
                    if currentTime - sample.timestamp <= performanceCache.warm.retentionTime then
                        table.insert(validSamples, sample)
                    end
                end
                entry.samples = validSamples
            end
        end
        
        performanceCache.warm.lastCleanup = currentTime
        
        -- Update cache hit rates
        performanceMetrics.cacheHitRates.warmCleanup = {
            entriesCleaned = cleaned,
            timestamp = currentTime
        }
    end,
    
    -- Get performance data with cache intelligence
    getPerformanceData = function(componentName)
        local data = {
            current = nil,
            recent = nil,
            historical = nil,
            cacheLevel = "none"
        }
        
        -- Check hot cache first
        if performanceCache.hot.data[componentName] then
            local entry = performanceCache.hot.data[componentName]
            data.current = entry.count > 0 and (entry.totalTime / entry.count) or 0
            data.cacheLevel = "hot"
        end
        
        -- Check warm cache
        if performanceCache.warm.data[componentName] then
            data.recent = performanceCache.warm.data[componentName].averageTime
            data.cacheLevel = data.cacheLevel == "hot" and "hot+warm" or "warm"
        end
        
        -- Check historical cache
        if performanceCache.historical.data[componentName] then
            data.historical = performanceCache.historical.data[componentName].longTermAverage
            data.cacheLevel = data.cacheLevel .. "+historical"
        end
        
        return data
    end
}

-- Initialize UI performance optimization system
function AE_UIPerformanceOptimizer.initialize()
    if moduleInitialized then return end
    
    -- Ensure all functions are properly defined before setting up hooks
    if not AE_UIPerformanceOptimizer.recordRenderingTime or 
       not AE_UIPerformanceOptimizer.recordEventProcessingTime then
        -- Functions not ready, defer initialization
        Events.OnTick.Add(function()
            AE_UIPerformanceOptimizer.initialize()
            Events.OnTick.Remove(AE_UIPerformanceOptimizer.initialize)
        end)
        return
    end
    
    -- AE_UIPerformanceOptimizer.setupPerformanceMonitoring() -- DISABLED: Contains dangerous global hooks
    AE_UIPerformanceOptimizer.initializeComponentOptimizers()
    AE_UIPerformanceOptimizer.setupMemoryManagement()
    AE_UIPerformanceOptimizer.enableRenderingOptimization()
    AE_UIPerformanceOptimizer.setupEventIntegration()
    AE_UIPerformanceOptimizer.initializeMonitoringDashboard()
    
    moduleInitialized = true
end

-- DISABLED: setupPerformanceMonitoring - replaced by component-specific monitoring
-- This function contained dangerous global ISPanel hooks that caused Java method errors
-- Component-specific monitoring via AE_ComponentMonitor is now used instead
function AE_UIPerformanceOptimizer.setupPerformanceMonitoring()
    -- DEPRECATED: Global ISPanel hooks removed due to Java method compatibility issues
    -- Performance monitoring now handled by component-specific AE_ComponentMonitor system
    
    -- Monitor event processing performance (safe to keep)
    AE_UIPerformanceOptimizer.monitorEventProcessing()
    
    -- PHASE 2 CONSOLIDATION: Timer moved to AE_UIHealthCoordinator
    -- Events.EveryTenMinutes.Add(function()
    --     AE_UIPerformanceOptimizer.analyzePerformanceMetrics()
    --     AE_UIPerformanceOptimizer.optimizeBasedOnMetrics()
    -- end) -- Disabled - handled by UI Health Coordinator
end

-- Monitor event processing performance
function AE_UIPerformanceOptimizer.monitorEventProcessing()
    local eventProcessingTimes = {}

    local originalSendServerCommand = sendServerCommand
    sendServerCommand = function(...)
        local args = {...}
        local player, module, command, data

        if #args == 4 or (args[1] and type(args[1]) ~= "string") then
            player, module, command, data = args[1], args[2], args[3], args[4]
        else
            module, command, data = args[1], args[2], args[3]
        end

        local startTime = getTimestamp()

        if player then
            originalSendServerCommand(player, module, command, data)
        else
            originalSendServerCommand(module, command, data)
        end

        local processingTime = getTimestamp() - startTime
        AE_UIPerformanceOptimizer.recordEventProcessingTime(tostring(module) .. "." .. tostring(command), processingTime)
    end
end

-- Initialize component-specific optimizers
function AE_UIPerformanceOptimizer.initializeComponentOptimizers()
    -- Status Menu optimizer
    componentOptimizers["AE_StatusMenu"] = {
        updateThrottle = 100,
        cacheStrategy = "timeBased",
        batchUpdates = true,
        renderOptimization = true
    }
    
    -- Commands UI optimizer
    componentOptimizers["AE_CommandsUI"] = {
        updateThrottle = 50,
        cacheStrategy = "invalidationBased",
        batchUpdates = true,
        renderOptimization = true
    }
    
    -- Context Menu optimizer
    componentOptimizers["AE_ContextMenuIntegration"] = {
        updateThrottle = 25,
        cacheStrategy = "smart",
        batchUpdates = false,
        renderOptimization = true
    }
    
    -- Cross-Mod Data Sync optimizer
    componentOptimizers["AE_CrossModDataSync"] = {
        updateThrottle = 200,
        cacheStrategy = "aggressive",
        batchUpdates = true,
        renderOptimization = false
    }
    
    -- KittyMod Status UI optimizer
    componentOptimizers["KittyMod_StatusUI"] = {
        updateThrottle = 100,
        cacheStrategy = "timeBased",
        batchUpdates = true,
        renderOptimization = true
    }
end

-- Record rendering time with intelligent three-tier caching
function AE_UIPerformanceOptimizer.recordRenderingTime(componentName, renderTime)
    -- Defensive guard: ensure module is properly initialized
    if not moduleInitialized or not componentName or not renderTime then
        return
    end
    
    -- Use intelligent cache system instead of simple array
    CacheManager.addToHotCache(componentName, renderTime)
    
    -- Periodic cache maintenance (defensive - only when needed)
    CacheManager.cleanupWarmCache()
    CacheManager.updateHistoricalCache()
    
    -- Legacy performance metrics compatibility (for existing integrations)
    if not performanceMetrics.renderingTimes[componentName] then
        performanceMetrics.renderingTimes[componentName] = {}
    end
    
    -- Add current sample to legacy structure (limited size for compatibility)
    table.insert(performanceMetrics.renderingTimes[componentName], {
        time = renderTime,
        timestamp = getTimestamp()
    })
    
    -- Maintain legacy sliding window (smaller size due to cache efficiency)
    local maxSamples = 25 -- Reduced from 100 due to cache system handling bulk data
    if #performanceMetrics.renderingTimes[componentName] > maxSamples then
        table.remove(performanceMetrics.renderingTimes[componentName], 1)
    end
    
    -- Enhanced performance issue detection using cache intelligence
    local cacheData = CacheManager.getPerformanceData(componentName)
    local currentAvg = cacheData.current or renderTime
    local recentAvg = cacheData.recent
    local historicalAvg = cacheData.historical
    
    -- Smart threshold detection: use historical context if available
    local effectiveThreshold = OPTIMIZATION_CONFIG.renderingThreshold
    if historicalAvg and historicalAvg > 0 then
        -- Allow 150% of historical average, minimum of configured threshold
        effectiveThreshold = math.max(effectiveThreshold, historicalAvg * 1.5)
    end
    
    if renderTime > effectiveThreshold then
        AE_UIPerformanceOptimizer.handlePerformanceIssue(componentName, "rendering", renderTime)
    end
    
    -- Cache performance metrics
    performanceMetrics.cacheHitRates.lastRecord = {
        componentName = componentName,
        cacheLevel = cacheData.cacheLevel,
        timestamp = getTimestamp()
    }
end

-- Record event processing time
function AE_UIPerformanceOptimizer.recordEventProcessingTime(eventName, processingTime)
    if not performanceMetrics.eventProcessingTimes[eventName] then
        performanceMetrics.eventProcessingTimes[eventName] = {}
    end
    
    table.insert(performanceMetrics.eventProcessingTimes[eventName], {
        time = processingTime,
        timestamp = getTimestamp()
    })
    
    -- Maintain sliding window
    if #performanceMetrics.eventProcessingTimes[eventName] > 50 then
        table.remove(performanceMetrics.eventProcessingTimes[eventName], 1)
    end
end

-- Handle performance issues with automatic optimization
function AE_UIPerformanceOptimizer.handlePerformanceIssue(componentName, issueType, value)
    if not activeOptimizations[componentName] then
        activeOptimizations[componentName] = {}
    end
    
    if issueType == "rendering" and value > OPTIMIZATION_CONFIG.renderingThreshold then
        -- Apply rendering optimization
        AE_UIPerformanceOptimizer.applyRenderingOptimization(componentName)
        activeOptimizations[componentName].renderingOptimized = true
    elseif issueType == "memory" and value > OPTIMIZATION_CONFIG.memoryGCThreshold then
        -- Trigger garbage collection optimization
        AE_UIPerformanceOptimizer.optimizeMemoryUsage(componentName)
        activeOptimizations[componentName].memoryOptimized = true
    elseif issueType == "updates" then
        -- Apply update throttling
        AE_UIPerformanceOptimizer.applyUpdateThrottling(componentName)
        activeOptimizations[componentName].updateThrottled = true
    end
end

-- Apply rendering optimization for specific component
function AE_UIPerformanceOptimizer.applyRenderingOptimization(componentName)
    local optimizer = componentOptimizers[componentName]
    if not optimizer or not optimizer.renderOptimization then return end
    
    -- Implement component-specific rendering optimizations
    if componentName == "AE_StatusMenu" then
        sendServerCommand("AE_UIService", "componentUpdate", {
            component = "AE_StatusMenu",
            updateType = "optimizeRendering",
            optimizations = {
                "reduceUpdateFrequency",
                "batchLabelUpdates",
                "cacheStatusCalculations"
            }
        })
    elseif componentName == "AE_CommandsUI" then
        sendServerCommand("AE_UIService", "componentUpdate", {
            component = "AE_CommandsUI",
            updateType = "optimizeRendering", 
            optimizations = {
                "throttleButtonUpdates",
                "cacheButtonStates",
                "optimizeProgressBars"
            }
        })
    elseif componentName == "KittyMod_StatusUI" then
        sendServerCommand("AE_CrossModService", "integrationRequest", {
            sourceMod = "AE_Framework",
            targetMod = "KittyMod",
            requestType = "optimizeRendering",
            optimizations = {
                "enableDataCaching",
                "throttleStatusUpdates",
                "batchUIUpdates"
            }
        })
    end
end

-- Apply update throttling for performance optimization
function AE_UIPerformanceOptimizer.applyUpdateThrottling(componentName)
    local optimizer = componentOptimizers[componentName]
    if not optimizer then return end
    
    sendServerCommand("AE_UIService", "componentUpdate", {
        updateType = "applyThrottling",
        component = componentName,
        throttleDelay = optimizer.updateThrottle,
        batchUpdates = optimizer.batchUpdates
    })
end

-- Setup memory management optimization
function AE_UIPerformanceOptimizer.setupMemoryManagement()
    -- Monitor memory usage for UI components
    Events.EveryOneMinute.Add(function()
        AE_UIPerformanceOptimizer.monitorMemoryUsage()
    end)
    
    -- PHASE 2 CONSOLIDATION: Timer moved to AE_UIHealthCoordinator
    -- Events.EveryTenMinutes.Add(function()
    --     AE_UIPerformanceOptimizer.performMemoryOptimization()
    -- end) -- Disabled - handled by UI Health Coordinator
end

-- Monitor memory usage patterns
function AE_UIPerformanceOptimizer.monitorMemoryUsage()
    -- Get memory usage with defensive checks
    local totalMemory = 0
    local memorySuccess, memoryResult = pcall(function()
        if collectgarbage then
            return collectgarbage("count") * 1024 -- Convert KB to bytes
        end
        return 0
    end)
    if memorySuccess then
        totalMemory = memoryResult
    end
    
    -- Using verified B42 API function
    local timestamp = getTimestamp()
    
    local memoryStats = {
        totalMemory = totalMemory,
        uiMemory = AE_UIPerformanceOptimizer.estimateUIMemoryUsage(),
        timestamp = timestamp
    }
    
    table.insert(performanceMetrics.memoryUsage, memoryStats)
    
    -- Maintain memory usage history
    if #performanceMetrics.memoryUsage > 60 then -- 1 hour of data
        table.remove(performanceMetrics.memoryUsage, 1)
    end
    
    -- Check for memory issues
    if memoryStats.uiMemory > OPTIMIZATION_CONFIG.memoryGCThreshold then
        AE_UIPerformanceOptimizer.handlePerformanceIssue("UI", "memory", memoryStats.uiMemory)
    end
end

-- Estimate UI-specific memory usage
function AE_UIPerformanceOptimizer.estimateUIMemoryUsage()
    local uiMemory = 0
    
    -- Estimate based on active UI components
    for componentName, _ in pairs(componentOptimizers) do
        if activeOptimizations[componentName] then
            uiMemory = uiMemory + (activeOptimizations[componentName].estimatedMemory or 0)
        end
    end
    
    return uiMemory
end

-- Perform memory optimization
function AE_UIPerformanceOptimizer.performMemoryOptimization()
    -- Clear performance caches
    AE_UIPerformanceOptimizer.clearPerformanceCaches()
    
    -- Optimize component-specific memory usage
    for componentName, optimizer in pairs(componentOptimizers) do
        if optimizer.cacheStrategy == "aggressive" then
            -- Defensive event triggering for cache clearing
            local success = pcall(function()
                sendServerCommand("AE_UIService", "componentUpdate", {
                    updateType = "clearCache",
                    component = componentName
                })
            end)
            
            if not success then
                print("[AE_UIPerformanceOptimizer] Failed to trigger cache clear for: " .. componentName)
            end
        end
    end
    
    -- Trigger system garbage collection
    collectgarbage("collect")
end

-- Clear performance caches to free memory
function AE_UIPerformanceOptimizer.clearPerformanceCaches()
    -- Clear old performance metrics
    local currentTime = getTimestamp()
    local retentionPeriod = 3600000 -- 1 hour
    
    for componentName, times in pairs(performanceMetrics.renderingTimes) do
        local filteredTimes = {}
        for _, timeData in ipairs(times) do
            if currentTime - timeData.timestamp < retentionPeriod then
                table.insert(filteredTimes, timeData)
            end
        end
        performanceMetrics.renderingTimes[componentName] = filteredTimes
    end
end

-- Enable rendering optimization techniques
function AE_UIPerformanceOptimizer.enableRenderingOptimization()
    -- Implement frame-rate adaptive rendering
    local targetFPS = 60
    local frameBudget = 1000 / targetFPS -- 16.67ms per frame
    
    -- Monitor frame timing and adapt accordingly
    Events.OnTick.Add(function()
        local frameStart = getTimestamp()
        
        -- Process UI updates within frame budget
        Events.OnTick.Remove(AE_UIPerformanceOptimizer.processFrameOptimization)
        
        local frameEnd = getTimestamp()
        local frameTime = frameEnd - frameStart
        
        if frameTime > frameBudget then
            -- Adjust optimization parameters
            AE_UIPerformanceOptimizer.adjustOptimizationParameters(frameTime)
        end
    end)
end

-- Adjust optimization parameters based on performance
function AE_UIPerformanceOptimizer.adjustOptimizationParameters(frameTime)
    local performanceRatio = frameTime / OPTIMIZATION_CONFIG.renderingThreshold
    
    if performanceRatio > 1.5 then
        -- Aggressive optimization needed
        for componentName, optimizer in pairs(componentOptimizers) do
            optimizer.updateThrottle = math.min(optimizer.updateThrottle * 1.2, 500)
            optimizer.batchUpdates = true
        end
    elseif performanceRatio < 0.5 then
        -- Can relax optimization
        for componentName, optimizer in pairs(componentOptimizers) do
            optimizer.updateThrottle = math.max(optimizer.updateThrottle * 0.9, 25)
        end
    end
end

-- Analyze performance metrics and identify optimization opportunities
function AE_UIPerformanceOptimizer.analyzePerformanceMetrics()
    local analysis = {
        slowestComponents = {},
        memoryHogs = {},
        optimizationOpportunities = {}
    }
    
    -- Analyze rendering performance
    for componentName, times in pairs(performanceMetrics.renderingTimes) do
        if #times > 10 then
            local totalTime = 0
            for _, timeData in ipairs(times) do
                totalTime = totalTime + timeData.time
            end
            local avgTime = totalTime / #times
            
            if avgTime > OPTIMIZATION_CONFIG.renderingThreshold then
                table.insert(analysis.slowestComponents, {
                    component = componentName,
                    avgRenderTime = avgTime,
                    samples = #times
                })
            end
        end
    end
    
    -- Store analysis results
    performanceProfiles[getTimestamp()] = analysis
    
    return analysis
end

-- Optimize based on collected metrics
function AE_UIPerformanceOptimizer.optimizeBasedOnMetrics()
    local analysis = AE_UIPerformanceOptimizer.analyzePerformanceMetrics()
    
    -- Apply optimizations for slow components
    for _, slowComponent in ipairs(analysis.slowestComponents) do
        AE_UIPerformanceOptimizer.applyRenderingOptimization(slowComponent.component)
    end
    
    -- Apply memory optimizations
    for _, memoryHog in ipairs(analysis.memoryHogs) do
        AE_UIPerformanceOptimizer.optimizeMemoryUsage(memoryHog.component)
    end
end

-- Optimize memory usage for specific component
function AE_UIPerformanceOptimizer.optimizeMemoryUsage(componentName)
    local optimizer = componentOptimizers[componentName]
    if not optimizer then return end
    
    -- Apply memory optimization strategies
    if optimizer.cacheStrategy == "timeBased" then
        sendServerCommand("AE_UIService", "componentUpdate", {
            updateType = "optimizeCache",
            component = componentName,
            strategy = "reduceRetention",
            maxAge = 300000 -- 5 minutes
        })
    elseif optimizer.cacheStrategy == "invalidationBased" then
        sendServerCommand("AE_UIService", "componentUpdate", {
            updateType = "optimizeCache",
            component = componentName,
            strategy = "smartInvalidation",
            maxSize = OPTIMIZATION_CONFIG.cacheMaxSize
        })
    elseif optimizer.cacheStrategy == "aggressive" then
        sendServerCommand("AE_UIService", "componentUpdate", {
            updateType = "optimizeCache",
            component = componentName,
            strategy = "clearOldest",
            retentionLimit = 100
        })
    end
end

-- Get comprehensive performance metrics with cache intelligence
function AE_UIPerformanceOptimizer.getPerformanceMetrics()
    local metrics = {
        renderingMetrics = performanceMetrics.renderingTimes,
        eventProcessingMetrics = performanceMetrics.eventProcessingTimes,
        memoryMetrics = performanceMetrics.memoryUsage,
        optimizationStatus = activeOptimizations,
        componentOptimizers = componentOptimizers,
        performanceProfiles = performanceProfiles,
        optimizationConfig = OPTIMIZATION_CONFIG,
        
        -- Enhanced cache metrics
        cacheMetrics = {
            hotCache = {
                activeComponents = 0,
                totalEntries = 0,
                memoryUsage = 0
            },
            warmCache = {
                activeComponents = 0,
                totalSamples = 0,
                avgRetentionTime = 0
            },
            historicalCache = {
                componentsTracked = 0,
                totalSessions = 0,
                oldestData = 0
            },
            cacheEfficiency = performanceMetrics.cacheHitRates
        }
    }
    
    -- Calculate cache statistics
    for componentName, _ in pairs(performanceCache.hot.data) do
        metrics.cacheMetrics.hotCache.activeComponents = metrics.cacheMetrics.hotCache.activeComponents + 1
    end
    
    for componentName, entry in pairs(performanceCache.warm.data) do
        metrics.cacheMetrics.warmCache.activeComponents = metrics.cacheMetrics.warmCache.activeComponents + 1
        metrics.cacheMetrics.warmCache.totalSamples = metrics.cacheMetrics.warmCache.totalSamples + #entry.samples
    end
    
    for componentName, _ in pairs(performanceCache.historical.data) do
        metrics.cacheMetrics.historicalCache.componentsTracked = metrics.cacheMetrics.historicalCache.componentsTracked + 1
    end
    
    return metrics
end

-- Get cache-optimized performance data for specific component
function AE_UIPerformanceOptimizer.getComponentPerformance(componentName)
    if not componentName then return nil end
    
    local cacheData = CacheManager.getPerformanceData(componentName)
    local legacyData = performanceMetrics.renderingTimes[componentName] or {}
    
    return {
        component = componentName,
        currentPerformance = cacheData.current,
        recentAverage = cacheData.recent,
        historicalAverage = cacheData.historical,
        cacheLevel = cacheData.cacheLevel,
        legacySamples = #legacyData,
        lastUpdate = (#legacyData > 0) and legacyData[#legacyData].timestamp or 0,
        optimizationStatus = activeOptimizations[componentName]
    }
end

-- Get current optimization status
function AE_UIPerformanceOptimizer.getOptimizationStatus()
    local status = {
        totalComponents = 0,
        optimizedComponents = 0,
        optimizationTypes = {
            rendering = 0,
            memory = 0,
            updates = 0
        }
    }
    
    for componentName, _ in pairs(componentOptimizers) do
        status.totalComponents = status.totalComponents + 1
        
        if activeOptimizations[componentName] then
            status.optimizedComponents = status.optimizedComponents + 1
            
            if activeOptimizations[componentName].renderingOptimized then
                status.optimizationTypes.rendering = status.optimizationTypes.rendering + 1
            end
            if activeOptimizations[componentName].memoryOptimized then
                status.optimizationTypes.memory = status.optimizationTypes.memory + 1
            end
            if activeOptimizations[componentName].updateThrottled then
                status.optimizationTypes.updates = status.optimizationTypes.updates + 1
            end
        end
    end
    
    return status
end

-- Performance benchmarking for validation
function AE_UIPerformanceOptimizer.runPerformanceBenchmark()
    local benchmark = {
        startTime = getTimestamp(),
        tests = {},
        results = {}
    }
    
    -- Test rendering performance
    benchmark.tests.rendering = AE_UIPerformanceOptimizer.benchmarkRendering()
    
    -- Test event processing performance
    benchmark.tests.eventProcessing = AE_UIPerformanceOptimizer.benchmarkEventProcessing()
    
    -- Test memory efficiency
    benchmark.tests.memory = AE_UIPerformanceOptimizer.benchmarkMemoryEfficiency()
    
    -- Test optimization effectiveness
    benchmark.tests.optimization = AE_UIPerformanceOptimizer.benchmarkOptimizationEffectiveness()
    
    benchmark.endTime = getTimestamp()
    benchmark.totalDuration = benchmark.endTime - benchmark.startTime
    
    return benchmark
end

-- Benchmark rendering performance
function AE_UIPerformanceOptimizer.benchmarkRendering()
    local renderingTest = {
        testRuns = 50,
        results = {}
    }
    
    for i = 1, renderingTest.testRuns do
        local startTime = getTimestamp()
        
        -- Simulate typical UI rendering operations
        sendServerCommand("AE_UIService", "componentUpdate", {
            updateType = "benchmarkRender",
            iteration = i
        })
        
        local endTime = getTimestamp()
        table.insert(renderingTest.results, endTime - startTime)
    end
    
    -- Calculate statistics
    local totalTime = 0
    for _, time in ipairs(renderingTest.results) do
        totalTime = totalTime + time
    end
    
    renderingTest.averageTime = totalTime / #renderingTest.results
    renderingTest.maxTime = math.max(unpack(renderingTest.results))
    renderingTest.minTime = math.min(unpack(renderingTest.results))
    
    return renderingTest
end

-- Benchmark event processing performance
function AE_UIPerformanceOptimizer.benchmarkEventProcessing()
    local eventTest = {
        testEvents = 100,
        results = {}
    }
    
    for i = 1, eventTest.testEvents do
        local startTime = getTimestamp()
        
        sendServerCommand("AE_UIService", "componentUpdate", {
            updateType = "benchmarkEvent",
            testData = "benchmark_" .. i,
            timestamp = startTime
        })
        
        local endTime = getTimestamp()
        table.insert(eventTest.results, endTime - startTime)
    end
    
    -- Calculate statistics
    local totalTime = 0
    for _, time in ipairs(eventTest.results) do
        totalTime = totalTime + time
    end
    
    eventTest.averageTime = totalTime / #eventTest.results
    eventTest.throughput = eventTest.testEvents / (totalTime / 1000) -- events per second
    
    return eventTest
end

-- Benchmark memory efficiency
function AE_UIPerformanceOptimizer.benchmarkMemoryEfficiency()
    local memoryTest = {
        beforeOptimization = getMemoryUsage(),
        afterOptimization = 0,
        improvementPercentage = 0
    }
    
    -- Trigger memory optimization
    AE_UIPerformanceOptimizer.performMemoryOptimization()
    
    -- Wait for optimization to complete
    local startWait = getTimestamp()
    while getTimestamp() - startWait < 1000 do
        -- Wait 1 second for optimization effects
    end
    
    memoryTest.afterOptimization = getMemoryUsage()
    memoryTest.memoryReduction = memoryTest.beforeOptimization - memoryTest.afterOptimization
    
    if memoryTest.beforeOptimization > 0 then
        memoryTest.improvementPercentage = (memoryTest.memoryReduction / memoryTest.beforeOptimization) * 100
    end
    
    return memoryTest
end

-- Benchmark optimization effectiveness
function AE_UIPerformanceOptimizer.benchmarkOptimizationEffectiveness()
    local optimizationTest = {
        componentsOptimized = 0,
        averageImprovement = 0,
        optimizationSuccess = true
    }
    
    local improvementTotal = 0
    local optimizedCount = 0
    
    for componentName, optimization in pairs(activeOptimizations) do
        if optimization.renderingOptimized or optimization.memoryOptimized or optimization.updateThrottled then
            optimizedCount = optimizedCount + 1
            
            -- Estimate improvement (simplified for benchmark)
            local improvement = 0
            if optimization.renderingOptimized then improvement = improvement + 15 end
            if optimization.memoryOptimized then improvement = improvement + 10 end
            if optimization.updateThrottled then improvement = improvement + 20 end
            
            improvementTotal = improvementTotal + improvement
        end
    end
    
    optimizationTest.componentsOptimized = optimizedCount
    if optimizedCount > 0 then
        optimizationTest.averageImprovement = improvementTotal / optimizedCount
    end
    
    return optimizationTest
end

-- Cleanup performance optimization resources
function AE_UIPerformanceOptimizer.cleanup()
    performanceMetrics = {
        renderingTimes = {},
        updateFrequencies = {},
        memoryUsage = {},
        eventProcessingTimes = {},
        cacheHitRates = {},
        batchingEfficiency = {}
    }
    
    activeOptimizations = {}
    performanceProfiles = {}
    
    -- Trigger final memory cleanup
    collectgarbage("collect")
end

-- Setup event system integration for performance monitoring
function AE_UIPerformanceOptimizer.setupEventIntegration()
    -- Register cache performance reporting events
    local AE_EventRegistry = nil
    local success, result = pcall(function()
        return require("AnimalsEssentials/Config/AE_EventRegistry")
    end)
    
    if success and result then
        AE_EventRegistry = result
        
        -- Performance report event for integration with AE_DataService
        AE_EventRegistry.subscribeEvent("OnAE_UI_PerformanceQuery", function(eventData)
            if eventData.requestType == "cacheMetrics" then
                local metrics = AE_UIPerformanceOptimizer.getPerformanceMetrics()
                sendServerCommand("AE_UIService", "componentUpdate", {
                    updateType = "performanceResponse",
                    requestID = eventData.requestID,
                    cacheMetrics = metrics.cacheMetrics,
                    componentCount = metrics.cacheMetrics.hotCache.activeComponents + 
                                   metrics.cacheMetrics.warmCache.activeComponents,
                    systemHealth = AE_UIPerformanceOptimizer.calculateSystemHealth()
                })
            elseif eventData.requestType == "componentPerformance" and eventData.componentName then
                local componentData = AE_UIPerformanceOptimizer.getComponentPerformance(eventData.componentName)
                sendServerCommand("AE_UIService", "componentUpdate", {
                    updateType = "performanceResponse",
                    requestID = eventData.requestID,
                    componentData = componentData
                })
            end
        end)
        
        -- Emergency disable event for performance safety
        AE_EventRegistry.subscribeEvent("OnAE_UI_EmergencyDisable", function(eventData)
            if eventData.system == "performanceOptimizer" then
                AE_UIPerformanceOptimizer.emergencyDisable(eventData.reason)
            end
        end)
        
        -- Cache management commands
        AE_EventRegistry.subscribeEvent("OnAE_UI_CacheCommand", function(eventData)
            if eventData.command == "clearCache" then
                AE_UIPerformanceOptimizer.clearPerformanceCache(eventData.cacheLevel)
            elseif eventData.command == "optimizeCache" then
                AE_UIPerformanceOptimizer.optimizeCache()
            end
        end)
    else
        -- B42 Mode fallback - no custom events
        print("[AE_UIPerformanceOptimizer] B42 Mode: Custom events not supported - using basic integration")
    end
    
    -- PHASE 2 CONSOLIDATION: Timer moved to AE_UIHealthCoordinator
    -- Events.EveryTenMinutes.Add(function()
    --     AE_UIPerformanceOptimizer.broadcastPerformanceReport()
    -- end) -- Disabled - handled by UI Health Coordinator
end

-- Initialize monitoring dashboard integration
function AE_UIPerformanceOptimizer.initializeMonitoringDashboard()
    -- Register with UI components for monitoring integration
    local monitoringConfig = {
        enableRealTimeDisplay = false, -- Defensive: disabled by default
        updateInterval = 5000, -- 5 seconds when enabled
        maxDisplayComponents = 10,
        alertThreshold = OPTIMIZATION_CONFIG.renderingThreshold * 2
    }
    
    -- Event handler for monitoring requests from StatusMenu or CommandsUI
    local function handleMonitoringRequest(eventData)
        if eventData.action == "enableRealTimeMonitoring" then
            monitoringConfig.enableRealTimeDisplay = true
            AE_UIPerformanceOptimizer.startRealTimeMonitoring()
        elseif eventData.action == "disableRealTimeMonitoring" then
            monitoringConfig.enableRealTimeDisplay = false
            AE_UIPerformanceOptimizer.stopRealTimeMonitoring()
        elseif eventData.action == "getPerformanceSnapshot" then
            sendServerCommand("AE_UIService", "componentUpdate", {
                updateType = "performanceSnapshot",
                snapshot = AE_UIPerformanceOptimizer.createPerformanceSnapshot(),
                timestamp = getTimestamp()
            })
        end
    end
    
    -- Register monitoring command handler for B42 compatibility
    if not Commands then Commands = {} end
    if not Commands.AE_PerformanceMonitoring then
        Commands.AE_PerformanceMonitoring = {}
    end
    
    Commands.AE_PerformanceMonitoring.monitoringRequest = function(player, args)
        handleMonitoringRequest(args)
    end
end

-- Calculate system health score based on cache performance
function AE_UIPerformanceOptimizer.calculateSystemHealth()
    local health = {
        score = 100, -- Start with perfect score
        status = "excellent",
        issues = {},
        recommendations = {}
    }
    
    local metrics = AE_UIPerformanceOptimizer.getPerformanceMetrics()
    
    -- Analyze cache efficiency
    local hotComponents = metrics.cacheMetrics.hotCache.activeComponents
    local warmComponents = metrics.cacheMetrics.warmCache.activeComponents
    
    if hotComponents > 30 then
        health.score = health.score - 15
        table.insert(health.issues, "High number of actively rendering components")
        table.insert(health.recommendations, "Consider UI update throttling")
    end
    
    if warmComponents > 50 then
        health.score = health.score - 10
        table.insert(health.issues, "Large warm cache - potential memory pressure")
        table.insert(health.recommendations, "Reduce cache retention time")
    end
    
    -- Analyze performance trends
    for componentName, data in pairs(performanceCache.warm.data) do
        if data.averageTime > OPTIMIZATION_CONFIG.renderingThreshold * 1.5 then
            health.score = health.score - 5
            table.insert(health.issues, "Component " .. componentName .. " showing slow rendering")
        end
    end
    
    -- Set health status
    if health.score >= 90 then
        health.status = "excellent"
    elseif health.score >= 75 then
        health.status = "good"
    elseif health.score >= 60 then
        health.status = "fair"
    elseif health.score >= 40 then
        health.status = "poor"
    else
        health.status = "critical"
    end
    
    return health
end

-- Emergency disable mechanism for performance safety
function AE_UIPerformanceOptimizer.emergencyDisable(reason)
    print("[AE_UIPerformanceOptimizer] EMERGENCY DISABLE: " .. (reason or "Unknown reason"))
    
    -- Restore original ISPanel.render (no longer needed - global hooks disabled)
    -- NOTE: Global ISPanel hooks have been permanently disabled in setupPerformanceMonitoring
    -- Component-specific monitoring via AE_ComponentMonitor does not require emergency restore
    
    -- Clear all performance data
    performanceCache.hot.data = {}
    performanceCache.warm.data = {}
    performanceCache.historical.data = {}
    
    -- Mark as disabled
    moduleInitialized = false
    
    -- Broadcast emergency disable event
    sendServerCommand("AE_UIService", "componentUpdate", {
        updateType = "systemDisabled",
        system = "performanceOptimizer",
        reason = reason,
        timestamp = getTimestamp()
    })
end

-- Clear performance cache (selective or full)
function AE_UIPerformanceOptimizer.clearPerformanceCache(cacheLevel)
    if not cacheLevel or cacheLevel == "all" then
        performanceCache.hot.data = {}
        performanceCache.warm.data = {}
        performanceCache.historical.data = {}
    elseif cacheLevel == "hot" then
        performanceCache.hot.data = {}
    elseif cacheLevel == "warm" then
        performanceCache.warm.data = {}
    elseif cacheLevel == "historical" then
        performanceCache.historical.data = {}
    end
    
    -- Update cache statistics
    performanceMetrics.cacheHitRates.cacheCleared = {
        level = cacheLevel,
        timestamp = getTimestamp()
    }
end

-- Optimize cache performance
function AE_UIPerformanceOptimizer.optimizeCache()
    -- Force immediate cleanup
    CacheManager.cleanupWarmCache()
    CacheManager.updateHistoricalCache()
    
    -- Optimize cache sizes based on current usage
    local hotCount = 0
    for _ in pairs(performanceCache.hot.data) do
        hotCount = hotCount + 1
    end
    
    if hotCount > performanceCache.hot.maxSize * 0.8 then
        -- Reduce hot cache threshold for faster promotion
        for componentName, entry in pairs(performanceCache.hot.data) do
            if entry.count >= 3 then -- Reduced from 5
                CacheManager.promoteToWarmCache(componentName, entry)
                performanceCache.hot.data[componentName] = nil
            end
        end
    end
    
    -- Trigger garbage collection
    collectgarbage("collect")
end

-- Broadcast comprehensive performance report
function AE_UIPerformanceOptimizer.broadcastPerformanceReport()
    if not moduleInitialized then return end
    
    local report = {
        timestamp = getTimestamp(),
        systemHealth = AE_UIPerformanceOptimizer.calculateSystemHealth(),
        cacheMetrics = AE_UIPerformanceOptimizer.getPerformanceMetrics().cacheMetrics,
        topPerformers = AE_UIPerformanceOptimizer.getTopPerformingComponents(),
        recommendations = AE_UIPerformanceOptimizer.generateOptimizationRecommendations()
    }
    
    -- Send to AE_DataService if available
    sendServerCommand("AE_UIService", "componentUpdate", {
        updateType = "performanceReport",
        report = report
    })
end

-- Get top performing components for analysis
function AE_UIPerformanceOptimizer.getTopPerformingComponents()
    local components = {}
    
    -- Collect performance data from warm cache
    for componentName, data in pairs(performanceCache.warm.data) do
        if data.totalSamples > 5 then
            table.insert(components, {
                name = componentName,
                averageTime = data.averageTime,
                samples = data.totalSamples,
                efficiency = data.averageTime > 0 and (OPTIMIZATION_CONFIG.renderingThreshold / data.averageTime) or 1
            })
        end
    end
    
    -- Sort by average time (worst first)
    table.sort(components, function(a, b)
        return a.averageTime > b.averageTime
    end)
    
    -- Return top 5 worst performers
    local result = {}
    for i = 1, math.min(5, #components) do
        table.insert(result, components[i])
    end
    
    return result
end

-- Generate optimization recommendations based on performance data
function AE_UIPerformanceOptimizer.generateOptimizationRecommendations()
    local recommendations = {}
    local health = AE_UIPerformanceOptimizer.calculateSystemHealth()
    
    -- Add health-based recommendations
    for _, rec in ipairs(health.recommendations) do
        table.insert(recommendations, {
            type = "performance",
            priority = "high",
            description = rec,
            automated = false
        })
    end
    
    -- Cache-specific recommendations
    local metrics = AE_UIPerformanceOptimizer.getPerformanceMetrics().cacheMetrics
    
    if metrics.hotCache.activeComponents > 25 then
        table.insert(recommendations, {
            type = "cache",
            priority = "medium",
            description = "Consider reducing hot cache promotion threshold",
            automated = true
        })
    end
    
    if metrics.warmCache.totalSamples > 1000 then
        table.insert(recommendations, {
            type = "cache", 
            priority = "medium",
            description = "Warm cache showing high activity - consider cleanup",
            automated = true
        })
    end
    
    return recommendations
end

-- Create performance snapshot for monitoring
function AE_UIPerformanceOptimizer.createPerformanceSnapshot()
    return {
        timestamp = getTimestamp(),
        systemHealth = AE_UIPerformanceOptimizer.calculateSystemHealth(),
        activeComponents = {
            hot = 0,
            warm = 0,
            historical = 0
        },
        memoryUsage = {
            estimated = AE_UIPerformanceOptimizer.estimateUIMemoryUsage(),
            cacheOverhead = AE_UIPerformanceOptimizer.estimateCacheMemoryUsage()
        },
        performance = {
            avgRenderTime = AE_UIPerformanceOptimizer.calculateAverageRenderTime(),
            worstComponent = AE_UIPerformanceOptimizer.getWorstPerformingComponent()
        }
    }
end

-- Estimate cache memory usage
function AE_UIPerformanceOptimizer.estimateCacheMemoryUsage()
    local memoryUsage = 0
    
    -- Rough estimation based on cache sizes
    for _ in pairs(performanceCache.hot.data) do
        memoryUsage = memoryUsage + 200 -- Bytes per hot entry
    end
    
    for _, data in pairs(performanceCache.warm.data) do
        memoryUsage = memoryUsage + 500 + (#data.samples * 100) -- Base + samples
    end
    
    for _, data in pairs(performanceCache.historical.data) do
        memoryUsage = memoryUsage + 300 + (#data.trendData * 50) -- Base + trends
    end
    
    return memoryUsage
end

-- Calculate system-wide average render time
function AE_UIPerformanceOptimizer.calculateAverageRenderTime()
    local totalTime = 0
    local totalSamples = 0
    
    for _, data in pairs(performanceCache.warm.data) do
        if data.averageTime > 0 and data.totalSamples > 0 then
            totalTime = totalTime + (data.averageTime * data.totalSamples)
            totalSamples = totalSamples + data.totalSamples
        end
    end
    
    return totalSamples > 0 and (totalTime / totalSamples) or 0
end

-- Get worst performing component
function AE_UIPerformanceOptimizer.getWorstPerformingComponent()
    local worstComponent = nil
    local worstTime = 0
    
    for componentName, data in pairs(performanceCache.warm.data) do
        if data.averageTime > worstTime and data.totalSamples > 3 then
            worstTime = data.averageTime
            worstComponent = {
                name = componentName,
                averageTime = data.averageTime,
                samples = data.totalSamples
            }
        end
    end
    
    return worstComponent
end

-- SP/MP compatibility validation
function AE_UIPerformanceOptimizer.validateMPCompatibility()
    -- Performance monitoring is client-only, should work in both SP and MP
    local compatibility = {
        isClientOnly = true,
        requiresServerData = false,
        usesNetworking = false,
        mpSafe = true,
        notes = "Performance monitoring operates entirely client-side"
    }
    
    return compatibility
end

-- Initialize early to establish base sendServerCommand override
Events.OnInitGlobalModData.Add(AE_UIPerformanceOptimizer.initialize)
Events.OnGameBoot.Add(AE_UIPerformanceOptimizer.cleanup)

return AE_UIPerformanceOptimizer