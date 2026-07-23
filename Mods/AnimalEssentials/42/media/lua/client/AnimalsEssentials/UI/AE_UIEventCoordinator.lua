
local AE_UIEventCoordinator = {}

local uiComponentRegistry = {}
local activeUISubscriptions = {}
local uiUpdateBatchQueue = {}
local coordinationEvents = {}

local serviceRegistry = {
    frameworkComponents = {},
    externalMods = {},
    uiServices = {}
}

local BATCH_UPDATE_INTERVAL = 50 -- milliseconds
local MAX_BATCH_SIZE = 20
local batchUpdateScheduled = false

function AE_UIEventCoordinator.initialize()
    local success, error = pcall(function()
        AE_UIEventCoordinator.setupEventHandlers()
        AE_UIEventCoordinator.initializeServiceDiscovery()
        AE_UIEventCoordinator.registerFrameworkComponents()
    end)
    
    if not success then
        print("[AE_UIEventCoordinator] WARNING: Initialization failed - " .. tostring(error))
        print("[AE_UIEventCoordinator] Running in minimal fallback mode")
        
        AE_UIEventCoordinator.fallbackMode = true
        AE_UIEventCoordinator.registeredComponents = AE_UIEventCoordinator.registeredComponents or {}
        AE_UIEventCoordinator.serviceStatus = AE_UIEventCoordinator.serviceStatus or {}
    end
end

function AE_UIEventCoordinator.setupEventHandlers()
    local AE_EventRegistry = nil
    local success, result = pcall(function()
        return require("AnimalsEssentials/Config/AE_EventRegistry")
    end)
    if success and result then
        AE_EventRegistry = result
        
        if AE_EventRegistry.subscribeEvent then
            AE_EventRegistry.subscribeEvent("OnAE_UI_ComponentRegistration", function(eventData)
                AE_UIEventCoordinator.registerUIComponent(eventData)
            end)
            
            AE_EventRegistry.subscribeEvent("OnAE_UI_DataRequest", function(eventData)
                AE_UIEventCoordinator.coordinateDataRequest(eventData)
            end)
            
            -- UI update event coordination
            AE_EventRegistry.subscribeEvent("OnAE_UI_UpdateRequest", function(eventData)
                AE_UIEventCoordinator.batchUIUpdate(eventData)
            end)
            
            -- Cross-mod UI communication
            AE_EventRegistry.subscribeEvent("OnAE_CrossMod_UIRequest", function(eventData)
                AE_UIEventCoordinator.handleCrossModUIRequest(eventData)
            end)
            
            -- Service availability changes
            AE_EventRegistry.subscribeEvent("OnAE_ServiceAvailabilityChanged", function(eventData)
                AE_UIEventCoordinator.updateServiceAvailability(eventData)
            end)
            
            -- External mod registration (defensive pattern)
            AE_EventRegistry.subscribeEvent("OnAE_ExternalModRegistration", function(eventData)
                AE_UIEventCoordinator.registerExternalMod(eventData)
            end)
        end
    else
        -- B42 fallback - no UI coordination events
        print("[AE_UIEventCoordinator] B42 Mode: UI coordination events not supported - enabling direct call mode")
        
        -- Set fallback mode flag for direct function calls
        AE_UIEventCoordinator.fallbackMode = true
        AE_UIEventCoordinator.eventSystemAvailable = false
        
        -- Initialize basic component registry for manual coordination
        if not AE_UIEventCoordinator.registeredComponents then
            AE_UIEventCoordinator.registeredComponents = {}
        end
    end
end

-- Register UI components for coordination
function AE_UIEventCoordinator.registerUIComponent(registrationData)
    if not registrationData or not registrationData.componentName then
        return false
    end
    
    local componentName = registrationData.componentName
    local componentInfo = {
        name = componentName,
        modSource = registrationData.modSource or "Unknown",
        capabilities = registrationData.capabilities or {},
        eventHandlers = registrationData.eventHandlers or {},
        dependencies = registrationData.dependencies or {},
        registrationTime = getTimestamp()
    }
    
    uiComponentRegistry[componentName] = componentInfo
    
    -- Notify other components of new registration (B42 compatibility)
    sendServerCommand("AE_UIFramework", "componentAvailable", {
        componentName = componentName,
        componentInfo = componentInfo
    })
    
    return true
end

-- Service discovery for framework-aware coordination
function AE_UIEventCoordinator.initializeServiceDiscovery()
    -- Framework component detection
    AE_UIEventCoordinator.detectFrameworkServices()
    
    -- External mod detection
    AE_UIEventCoordinator.detectExternalMods()
    
    -- PHASE 2 CONSOLIDATION: Timer moved to AE_UIHealthCoordinator
    -- Events.EveryTenMinutes.Add(function()
    --     AE_UIEventCoordinator.performServiceHealthCheck()
    -- end) -- Disabled - handled by UI Health Coordinator
end

-- Register framework components for coordination
function AE_UIEventCoordinator.registerFrameworkComponents()
    -- Defensive check - only register if framework available
    if not AE_EventRegistry then
        return false -- Stay dormant when framework unavailable
    end
    
    local coreComponents = {
        "AE_StatusMenu", "AE_CommandsUI", "AE_ContextMenuIntegration"
    }
    
    for _, componentName in ipairs(coreComponents) do
        if _G[componentName] then -- Check component exists
            AE_UIEventCoordinator.registerUIComponent({
                componentName = componentName,
                component = _G[componentName],
                autoInitialize = true
            })
        end
    end
    
    return true
end

-- Detect available framework services
function AE_UIEventCoordinator.detectFrameworkServices()
    local frameworkServices = {
        "AE_DataService",
        "AE_StatusMenu", 
        "AE_CommandsUI",
        "AE_ContextMenuIntegration"
    }
    
    for _, serviceName in ipairs(frameworkServices) do
        local serviceAvailable = AE_UIEventCoordinator.checkServiceAvailability(serviceName)
        
        -- Using verified B42 API function
        local timestamp = getTimestamp()
        
        serviceRegistry.frameworkComponents[serviceName] = {
            available = serviceAvailable,
            lastCheck = timestamp,
            capabilities = AE_UIEventCoordinator.getServiceCapabilities(serviceName)
        }
        
        if serviceAvailable then
            -- Defensive server command triggering
            local eventSuccess = pcall(function()
                sendServerCommand("AE_ServiceRegistry", "serviceAvailable", {
                    serviceName = serviceName,
                    serviceType = "framework"
                })
            end)
            
            if not eventSuccess then
                print("[AE_UIEventCoordinator] Failed to trigger service available event for: " .. serviceName)
            end
        end
    end
end

-- Check if specific service is available
function AE_UIEventCoordinator.checkServiceAvailability(serviceName)
    local success, service = pcall(function()
        if serviceName == "AE_DataService" then
            return require("AnimalsEssentials/DataServices/AE_DataService")
        elseif serviceName == "AE_StatusMenu" then
            return require("AnimalsEssentials/UI/AE_StatusMenu")
        elseif serviceName == "AE_CommandsUI" then
            return require("AnimalsEssentials/UI/AE_CommandsUI")
        elseif serviceName == "AE_ContextMenuIntegration" then
            return require("AnimalsEssentials/UI/AE_ContextMenuIntegration")
        end
        return nil
    end)
    
    return success and service ~= nil
end

-- Get service capabilities for coordination
function AE_UIEventCoordinator.getServiceCapabilities(serviceName)
    local capabilities = {}
    
    if serviceName == "AE_DataService" then
        capabilities = {"dataRetrieval", "dataValidation", "eventNotification"}
    elseif serviceName == "AE_StatusMenu" then
        capabilities = {"animalStatus", "realTimeUpdates", "UIDisplay"}
    elseif serviceName == "AE_CommandsUI" then
        capabilities = {"commandExecution", "feedbackDisplay", "userInteraction"}
    elseif serviceName == "AE_ContextMenuIntegration" then
        capabilities = {"contextMenus", "dynamicOptions", "frameworkIntegration"}
    end
    
    return capabilities
end

-- External mod detection now uses passive registration pattern
function AE_UIEventCoordinator.detectExternalMods()
    -- External mods will self-register via OnAE_ExternalModRegistration event
    -- This maintains defensive architecture - no aggressive detection
end

-- Check external mod availability via registry (defensive pattern)
function AE_UIEventCoordinator.checkExternalModAvailability(modName)
    if serviceRegistry.externalMods[modName] then
        return serviceRegistry.externalMods[modName].available
    end
    
    return false
end

-- Register external mod via event (defensive pattern)
function AE_UIEventCoordinator.registerExternalMod(eventData)
    if not eventData or not eventData.modName then
        return false
    end
    
    serviceRegistry.externalMods[eventData.modName] = {
        available = true,
        integrationLevel = eventData.integrationLevel or "basic",
        lastCheck = getTimestamp(),
        capabilities = eventData.capabilities or {},
        version = eventData.version
    }
    
    sendServerCommand("AE_CrossModService", "statusUpdate", {
        modName = "AE_UIEventCoordinator",
        status = "externalModDetected",
        modName = eventData.modName,
        integrationSupported = true
    })
    
    return true
end

-- Coordinate data requests across UI components
function AE_UIEventCoordinator.coordinateDataRequest(requestData)
    if not requestData or not requestData.requestType then
        return false
    end
    
    local requestType = requestData.requestType
    local targetService = AE_UIEventCoordinator.determineTargetService(requestType)
    
    if not targetService then
        AE_UIEventCoordinator.handleRequestError(requestData, "No suitable service found")
        return false
    end
    
    -- Route request to appropriate service
    if targetService == "AE_DataService" then
        sendServerCommand("AE_UIService", "dataRequest", requestData)
    elseif serviceRegistry.frameworkComponents[targetService] and serviceRegistry.frameworkComponents[targetService].available then
        sendServerCommand("AE_ServiceRegistry", "serviceRequest", {
            targetService = targetService,
            requestData = requestData
        })
    else
        AE_UIEventCoordinator.handleRequestError(requestData, "Target service unavailable: " .. targetService)
        return false
    end
    
    return true
end

-- Determine target service for request coordination
function AE_UIEventCoordinator.determineTargetService(requestType)
    local serviceMapping = {
        animalStatus = "AE_DataService",
        animalState = "AE_DataService", 
        playerAnimalList = "AE_DataService",
        isFrameworkAnimal = "AE_DataService",
        commandExecution = "AE_CommandsUI",
        contextMenuOptions = "AE_ContextMenuIntegration"
    }
    
    return serviceMapping[requestType]
end

-- Efficient UI update batching system
function AE_UIEventCoordinator.batchUIUpdate(updateData)
    if not updateData then return end
    
    -- Add to batch queue
    table.insert(uiUpdateBatchQueue, {
        updateData = updateData,
        timestamp = getTimestamp(),
        priority = updateData.priority or "normal"
    })
    
    -- Schedule batch processing if not already scheduled
    if not batchUpdateScheduled and #uiUpdateBatchQueue > 0 then
        batchUpdateScheduled = true
        
        Events.OnTick.Add(function()
            if getTimestamp() >= (AE_UIEventCoordinator.lastBatchTime or 0) + BATCH_UPDATE_INTERVAL then
                AE_UIEventCoordinator.processBatchedUpdates()
                batchUpdateScheduled = false
                Events.OnTick.Remove(AE_UIEventCoordinator.processBatchedUpdates)
            end
        end)
    end
end

-- Process batched UI updates efficiently
function AE_UIEventCoordinator.processBatchedUpdates()
    if #uiUpdateBatchQueue == 0 then return end
    
    -- Sort by priority (high -> normal -> low)
    table.sort(uiUpdateBatchQueue, function(a, b)
        local priorityOrder = {high = 3, normal = 2, low = 1}
        return (priorityOrder[a.priority] or 2) > (priorityOrder[b.priority] or 2)
    end)
    
    -- Process up to MAX_BATCH_SIZE updates
    local processed = 0
    local remainingUpdates = {}
    
    for _, batchItem in ipairs(uiUpdateBatchQueue) do
        if processed < MAX_BATCH_SIZE then
            AE_UIEventCoordinator.processIndividualUpdate(batchItem.updateData)
            processed = processed + 1
        else
            table.insert(remainingUpdates, batchItem)
        end
    end
    
    -- Keep remaining updates for next batch
    uiUpdateBatchQueue = remainingUpdates
    AE_UIEventCoordinator.lastBatchTime = getTimestamp()
    
    -- Schedule next batch if needed
    if #uiUpdateBatchQueue > 0 then
        batchUpdateScheduled = true
        Events.OnTick.Add(function()
            if getTimestamp() >= AE_UIEventCoordinator.lastBatchTime + BATCH_UPDATE_INTERVAL then
                AE_UIEventCoordinator.processBatchedUpdates()
                batchUpdateScheduled = false
                Events.OnTick.Remove(AE_UIEventCoordinator.processBatchedUpdates)
            end
        end)
    end
end

-- Process individual UI update
function AE_UIEventCoordinator.processIndividualUpdate(updateData)
    local targetComponent = updateData.targetComponent
    local updateType = updateData.updateType
    
    if targetComponent and uiComponentRegistry[targetComponent] then
        sendServerCommand("AE_UIService", "componentUpdate", {
            targetComponent = targetComponent,
            updateData = updateData
        })
    elseif updateType then
        -- Broadcast to all compatible components
        sendServerCommand("AE_UIService", "broadcastUpdate", {
            updateType = updateType,
            updateData = updateData
        })
    end
end

-- Handle cross-mod UI requests with enhanced communication protocols
function AE_UIEventCoordinator.handleCrossModUIRequest(requestData)
    if not requestData or not requestData.sourceMod or not requestData.requestType then
        return false
    end
    
    local sourceMod = requestData.sourceMod
    local requestType = requestData.requestType
    
    -- Enhanced mod validation with capability checking
    if not AE_UIEventCoordinator.validateCrossModRequest(sourceMod, requestType) then
        AE_UIEventCoordinator.handleRequestError(requestData, "Cross-mod request validation failed")
        return false
    end
    
    -- Advanced request routing with performance monitoring
    local startTime = getTimestamp()
    local success = false
    
    if requestType == "statusIntegration" then
        success = AE_UIEventCoordinator.handleStatusIntegrationRequest(requestData)
    elseif requestType == "contextMenuIntegration" then
        success = AE_UIEventCoordinator.handleContextMenuIntegrationRequest(requestData)
    elseif requestType == "dataSync" then
        success = AE_UIEventCoordinator.handleDataSyncRequest(requestData)
    elseif requestType == "showCommandInterface" then
        success = AE_UIEventCoordinator.handleCommandInterfaceRequest(requestData)
    elseif requestType == "enhancedCatStatus" then
        success = AE_UIEventCoordinator.handleEnhancedStatusRequest(requestData)
    elseif requestType == "uiServiceDiscovery" then
        success = AE_UIEventCoordinator.handleServiceDiscoveryRequest(requestData)
    elseif requestType == "performanceMonitoring" then
        success = AE_UIEventCoordinator.handlePerformanceMonitoringRequest(requestData)
    else
        AE_UIEventCoordinator.handleRequestError(requestData, "Unknown cross-mod request type: " .. requestType)
        return false
    end
    
    -- Performance monitoring
    local processingTime = getTimestamp() - startTime
    AE_UIEventCoordinator.recordCrossModPerformance(sourceMod, requestType, processingTime, success)
    
    return success
end

-- Validate cross-mod request with capability checking
function AE_UIEventCoordinator.validateCrossModRequest(sourceMod, requestType)
    -- Check if source mod is registered
    if not serviceRegistry.externalMods[sourceMod] then
        return false
    end
    
    -- Verify mod capabilities for request type
    local modCapabilities = serviceRegistry.externalMods[sourceMod].capabilities or {}
    local requiredCapabilities = AE_UIEventCoordinator.getRequiredCapabilities(requestType)
    
    for _, requiredCap in ipairs(requiredCapabilities) do
        local hasCapability = false
        for _, modCap in ipairs(modCapabilities) do
            if modCap == requiredCap then
                hasCapability = true
                break
            end
        end
        if not hasCapability then
            return false
        end
    end
    
    return true
end

-- Get required capabilities for request type
function AE_UIEventCoordinator.getRequiredCapabilities(requestType)
    local capabilityMap = {
        statusIntegration = {"catStatusDisplay", "frameworkIntegration"},
        contextMenuIntegration = {"frameworkIntegration"},
        dataSync = {"crossModDataSync"},
        showCommandInterface = {"frameworkIntegration", "crossModDataSync"},
        enhancedCatStatus = {"catStatusDisplay", "frameworkIntegration"},
        uiServiceDiscovery = {"frameworkIntegration"},
        performanceMonitoring = {}
    }
    
    return capabilityMap[requestType] or {}
end

-- Handle command interface requests
function AE_UIEventCoordinator.handleCommandInterfaceRequest(requestData)
    if not requestData.animal or not requestData.animalType then
        AE_UIEventCoordinator.handleRequestError(requestData, "Missing animal data for command interface")
        return false
    end
    
    -- Check if commands UI is available
    if not serviceRegistry.frameworkComponents["AE_CommandsUI"] or 
       not serviceRegistry.frameworkComponents["AE_CommandsUI"].available then
        AE_UIEventCoordinator.handleRequestError(requestData, "Commands UI not available")
        return false
    end
    
    -- Enhanced command interface with cross-mod specialization
    local enhancedRequestData = {
        animal = requestData.animal,
        animalID = requestData.animalID,
        animalType = requestData.animalType,
        sourceMod = requestData.sourceMod,
        specialization = requestData.specialization,
        enhancedMode = true,
        crossModIntegration = true
    }
    
    sendServerCommand("AE_UIService", "componentUpdate", {
        component = "AnimalCommands",
        updateType = "showAnimalCommands",
        data = enhancedRequestData
    })
    return true
end

-- Handle enhanced status requests
function AE_UIEventCoordinator.handleEnhancedStatusRequest(requestData)
    if not requestData.animalID then
        AE_UIEventCoordinator.handleRequestError(requestData, "Missing animal ID for enhanced status")
        return false
    end
    
    -- Request enhanced data from data service
    if serviceRegistry.frameworkComponents["AE_DataService"] and 
       serviceRegistry.frameworkComponents["AE_DataService"].available then
        
        sendServerCommand("AE_UIService", "dataRequest", {
            requestType = "enhancedAnimalStatus",
            animalID = requestData.animalID,
            sourceMod = requestData.sourceMod,
            enhancementLevel = "full",
            crossModData = true,
            uiComponent = "CrossModIntegration",
            responseHandler = function(responseData)
                if requestData.responseHandler then
                    requestData.responseHandler(responseData)
                else
                    -- Broadcast enhanced status data
                    sendServerCommand("AE_CrossModService", "integrationRequest", {
                        sourceMod = requestData.sourceMod,
                        animalID = requestData.animalID,
                        statusData = responseData,
                        timestamp = getTimestamp()
                    })
                end
            end
        })
        return true
    else
        AE_UIEventCoordinator.handleRequestError(requestData, "Data service unavailable for enhanced status")
        return false
    end
end

-- Handle service discovery requests
function AE_UIEventCoordinator.handleServiceDiscoveryRequest(requestData)
    local discoveryScope = requestData.discoveryScope or "all"
    local discoveryInfo = {}
    
    if discoveryScope == "all" or discoveryScope == "framework" then
        discoveryInfo.frameworkComponents = {}
        for serviceName, serviceInfo in pairs(serviceRegistry.frameworkComponents) do
            discoveryInfo.frameworkComponents[serviceName] = {
                available = serviceInfo.available,
                capabilities = serviceInfo.capabilities,
                lastCheck = serviceInfo.lastCheck
            }
        end
    end
    
    if discoveryScope == "all" or discoveryScope == "external" then
        discoveryInfo.externalMods = {}
        for modName, modInfo in pairs(serviceRegistry.externalMods) do
            discoveryInfo.externalMods[modName] = {
                available = modInfo.available,
                capabilities = modInfo.capabilities,
                integrationLevel = modInfo.integrationLevel,
                lastCheck = modInfo.lastCheck
            }
        end
    end
    
    if discoveryScope == "all" or discoveryScope == "ui" then
        discoveryInfo.uiComponents = {}
        for componentName, componentInfo in pairs(uiComponentRegistry) do
            discoveryInfo.uiComponents[componentName] = {
                modSource = componentInfo.modSource,
                capabilities = componentInfo.capabilities,
                dependencies = componentInfo.dependencies
            }
        end
    end
    
    -- Respond with discovery information
    if requestData.responseHandler then
        requestData.responseHandler({
            success = true,
            discoveryInfo = discoveryInfo,
            timestamp = getTimestamp()
        })
    else
        sendServerCommand("AE_CrossModService", "integrationRequest", {
            sourceMod = requestData.sourceMod,
            discoveryInfo = discoveryInfo,
            timestamp = getTimestamp()
        })
    end
    
    return true
end

-- Handle performance monitoring requests
function AE_UIEventCoordinator.handlePerformanceMonitoringRequest(requestData)
    local monitoringScope = requestData.monitoringScope or "crossMod"
    local performanceData = {}
    
    if monitoringScope == "crossMod" or monitoringScope == "all" then
        performanceData.crossModOperations = AE_UIEventCoordinator.getCrossModPerformanceStats()
    end
    
    if monitoringScope == "batching" or monitoringScope == "all" then
        performanceData.batchingStats = AE_UIEventCoordinator.getBatchingPerformanceStats()
    end
    
    if monitoringScope == "services" or monitoringScope == "all" then
        performanceData.serviceStats = AE_UIEventCoordinator.getServicePerformanceStats()
    end
    
    -- Respond with performance data
    if requestData.responseHandler then
        requestData.responseHandler({
            success = true,
            performanceData = performanceData,
            timestamp = getTimestamp()
        })
    else
        sendServerCommand("AE_CrossModService", "integrationRequest", {
            sourceMod = requestData.sourceMod,
            performanceData = performanceData,
            timestamp = getTimestamp()
        })
    end
    
    return true
end

-- Handle status integration requests
function AE_UIEventCoordinator.handleStatusIntegrationRequest(requestData)
    if serviceRegistry.frameworkComponents["AE_StatusMenu"] and serviceRegistry.frameworkComponents["AE_StatusMenu"].available then
        sendServerCommand("AE_UIService", "componentUpdate", {
            component = "StatusMenu",
            updateType = "crossModIntegration",
            requestData = requestData
        })
    else
        AE_UIEventCoordinator.handleRequestError(requestData, "Status menu not available for integration")
    end
end

-- Handle context menu integration requests
function AE_UIEventCoordinator.handleContextMenuIntegrationRequest(requestData)
    if serviceRegistry.frameworkComponents["AE_ContextMenuIntegration"] and serviceRegistry.frameworkComponents["AE_ContextMenuIntegration"].available then
        sendServerCommand("AE_UIService", "componentUpdate", {
            component = "ContextMenuIntegration",
            updateType = "crossMod",
            requestData = requestData
        })
    else
        AE_UIEventCoordinator.handleRequestError(requestData, "Context menu integration not available")
    end
end

-- Handle data synchronization requests
function AE_UIEventCoordinator.handleDataSyncRequest(requestData)
    if serviceRegistry.frameworkComponents["AE_DataService"] and serviceRegistry.frameworkComponents["AE_DataService"].available then
        sendServerCommand("AE_CrossModService", "syncComplete", {
            syncType = "dataService",
            requestData = requestData
        })
    else
        AE_UIEventCoordinator.handleRequestError(requestData, "Data service not available for sync")
    end
end

-- Update service availability status
function AE_UIEventCoordinator.updateServiceAvailability(eventData)
    if not eventData or not eventData.serviceName then return end
    
    local serviceName = eventData.serviceName
    local isAvailable = eventData.available
    
    if serviceRegistry.frameworkComponents[serviceName] then
        serviceRegistry.frameworkComponents[serviceName].available = isAvailable
        serviceRegistry.frameworkComponents[serviceName].lastCheck = getTimestamp()
        
        -- Notify registered UI components
        sendServerCommand("AE_UIService", "componentUpdate", {
            updateType = "serviceAvailabilityChanged",
            serviceName = serviceName,
            available = isAvailable,
            serviceType = "framework"
        })
    elseif serviceRegistry.externalMods[serviceName] then
        serviceRegistry.externalMods[serviceName].available = isAvailable
        serviceRegistry.externalMods[serviceName].lastCheck = getTimestamp()
        
        sendServerCommand("AE_UIService", "componentUpdate", {
            updateType = "serviceAvailabilityChanged",
            serviceName = serviceName,
            available = isAvailable,
            serviceType = "external"
        })
    end
end

-- Perform periodic service health checks
function AE_UIEventCoordinator.performServiceHealthCheck()
    -- Check framework components
    for serviceName, serviceInfo in pairs(serviceRegistry.frameworkComponents) do
        local currentAvailability = AE_UIEventCoordinator.checkServiceAvailability(serviceName)
        if currentAvailability ~= serviceInfo.available then
            AE_UIEventCoordinator.updateServiceAvailability({
                serviceName = serviceName,
                available = currentAvailability
            })
        end
    end
    
    -- Check external mods
    for modName, modInfo in pairs(serviceRegistry.externalMods) do
        local currentAvailability = AE_UIEventCoordinator.checkExternalModAvailability(modName)
        if currentAvailability ~= modInfo.available then
            AE_UIEventCoordinator.updateServiceAvailability({
                serviceName = modName,
                available = currentAvailability
            })
        end
    end
end

-- Comprehensive error handling
function AE_UIEventCoordinator.handleRequestError(requestData, errorMessage)
    local errorInfo = {
        requestData = requestData,
        errorMessage = errorMessage,
        timestamp = getTimestamp(),
        source = "AE_UIEventCoordinator"
    }
    
    -- Log error for debugging
    sendServerCommand("AE_UIService", "componentUpdate", {
        updateType = "requestError",
        errorInfo = errorInfo
    })
    
    -- Attempt to notify requesting component
    if requestData and requestData.responseHandler then
        requestData.responseHandler({
            success = false,
            error = errorMessage,
            timestamp = getTimestamp()
        })
    elseif requestData and requestData.uiComponent then
        sendServerCommand("AE_UIService", "componentUpdate", {
            updateType = "componentError",
            component = requestData.uiComponent,
            errorInfo = errorInfo
        })
    end
end

-- Public API functions
function AE_UIEventCoordinator.getServiceRegistry()
    return serviceRegistry
end

function AE_UIEventCoordinator.getUIComponentRegistry()
    return uiComponentRegistry
end

function AE_UIEventCoordinator.isServiceAvailable(serviceName)
    if serviceRegistry.frameworkComponents[serviceName] then
        return serviceRegistry.frameworkComponents[serviceName].available
    elseif serviceRegistry.externalMods[serviceName] then
        return serviceRegistry.externalMods[serviceName].available
    end
    return false
end

function AE_UIEventCoordinator.getServiceCapabilities(serviceName)
    if serviceRegistry.frameworkComponents[serviceName] then
        return serviceRegistry.frameworkComponents[serviceName].capabilities
    elseif serviceRegistry.externalMods[serviceName] then
        return serviceRegistry.externalMods[serviceName].capabilities
    end
    return {}
end

-- Performance monitoring for cross-mod operations
local crossModPerformance = {
    operationTimes = {},
    operationCounts = {},
    errorCounts = {},
    lastReset = getTimestamp()
}

-- Record cross-mod performance metrics
function AE_UIEventCoordinator.recordCrossModPerformance(sourceMod, requestType, processingTime, success)
    local key = sourceMod .. "_" .. requestType
    
    -- Initialize if needed
    if not crossModPerformance.operationTimes[key] then
        crossModPerformance.operationTimes[key] = {}
        crossModPerformance.operationCounts[key] = 0
        crossModPerformance.errorCounts[key] = 0
    end
    
    -- Record performance data
    table.insert(crossModPerformance.operationTimes[key], processingTime)
    crossModPerformance.operationCounts[key] = crossModPerformance.operationCounts[key] + 1
    
    if not success then
        crossModPerformance.errorCounts[key] = crossModPerformance.errorCounts[key] + 1
    end
    
    -- Maintain sliding window of recent operations
    local maxSamples = 100
    if #crossModPerformance.operationTimes[key] > maxSamples then
        table.remove(crossModPerformance.operationTimes[key], 1)
    end
end

-- Get cross-mod performance statistics
function AE_UIEventCoordinator.getCrossModPerformanceStats()
    local stats = {
        totalOperations = 0,
        totalErrors = 0,
        operationsByMod = {},
        averageProcessingTime = {},
        errorRate = {}
    }
    
    for key, times in pairs(crossModPerformance.operationTimes) do
        local count = crossModPerformance.operationCounts[key] or 0
        local errors = crossModPerformance.errorCounts[key] or 0
        
        stats.totalOperations = stats.totalOperations + count
        stats.totalErrors = stats.totalErrors + errors
        
        -- Calculate average processing time
        if #times > 0 then
            local totalTime = 0
            for _, time in ipairs(times) do
                totalTime = totalTime + time
            end
            stats.averageProcessingTime[key] = totalTime / #times
        else
            stats.averageProcessingTime[key] = 0
        end
        
        -- Calculate error rate
        if count > 0 then
            stats.errorRate[key] = (errors / count) * 100
        else
            stats.errorRate[key] = 0
        end
        
        -- Group by mod
        local sourceMod = key:match("^(.-)_")
        if sourceMod then
            if not stats.operationsByMod[sourceMod] then
                stats.operationsByMod[sourceMod] = {operations = 0, errors = 0}
            end
            stats.operationsByMod[sourceMod].operations = stats.operationsByMod[sourceMod].operations + count
            stats.operationsByMod[sourceMod].errors = stats.operationsByMod[sourceMod].errors + errors
        end
    end
    
    return stats
end

-- Get batching performance statistics
function AE_UIEventCoordinator.getBatchingPerformanceStats()
    return {
        currentQueueSize = #uiUpdateBatchQueue,
        batchingActive = batchUpdateScheduled,
        lastBatchTime = AE_UIEventCoordinator.lastBatchTime,
        maxBatchSize = MAX_BATCH_SIZE,
        batchInterval = BATCH_UPDATE_INTERVAL
    }
end

-- Get service performance statistics
function AE_UIEventCoordinator.getServicePerformanceStats()
    local stats = {
        frameworkServices = {},
        externalMods = {},
        serviceHealth = {}
    }
    
    for serviceName, serviceInfo in pairs(serviceRegistry.frameworkComponents) do
        stats.frameworkServices[serviceName] = {
            available = serviceInfo.available,
            lastCheck = serviceInfo.lastCheck,
            capabilities = #(serviceInfo.capabilities or {}),
            uptime = serviceInfo.available and (getTimestamp() - (serviceInfo.lastCheck or 0)) or 0
        }
    end
    
    for modName, modInfo in pairs(serviceRegistry.externalMods) do
        stats.externalMods[modName] = {
            available = modInfo.available,
            integrationLevel = modInfo.integrationLevel,
            lastCheck = modInfo.lastCheck,
            capabilities = #(modInfo.capabilities or {}),
            uptime = modInfo.available and (getTimestamp() - (modInfo.lastCheck or 0)) or 0
        }
    end
    
    return stats
end

-- Advanced error handling with retry logic
function AE_UIEventCoordinator.handleRequestErrorWithRetry(requestData, errorMessage, retryCount)
    retryCount = retryCount or 0
    local maxRetries = 3
    
    if retryCount < maxRetries then
        -- Implement exponential backoff
        local delay = math.pow(2, retryCount) * 1000 -- milliseconds
        
        Events.OnTick.Add(function()
            local retryTime = getTimestamp() + delay
            if getTimestamp() >= retryTime then
                Events.OnTick.Remove(AE_UIEventCoordinator.retryRequest)
                AE_UIEventCoordinator.handleCrossModUIRequest(requestData)
            end
        end)
        
        return true
    else
        -- Max retries exceeded, handle as regular error
        AE_UIEventCoordinator.handleRequestError(requestData, errorMessage .. " (Max retries exceeded)")
        return false
    end
end

-- Enhanced UI experience coordination
function AE_UIEventCoordinator.coordinateMultiModUIExperience(coordinationData)
    if not coordinationData or not coordinationData.participatingMods then
        return false
    end
    
    local participatingMods = coordinationData.participatingMods
    local coordinationType = coordinationData.coordinationType or "statusSync"
    
    -- Validate all participating mods are available
    for _, modName in ipairs(participatingMods) do
        if not serviceRegistry.externalMods[modName] or not serviceRegistry.externalMods[modName].available then
            AE_UIEventCoordinator.handleRequestError(coordinationData, "Participating mod unavailable: " .. modName)
            return false
        end
    end
    
    -- Execute coordination based on type
    if coordinationType == "statusSync" then
        return AE_UIEventCoordinator.coordinateStatusSync(participatingMods, coordinationData)
    elseif coordinationType == "commandChaining" then
        return AE_UIEventCoordinator.coordinateCommandChaining(participatingMods, coordinationData)
    elseif coordinationType == "dataHarmonization" then
        return AE_UIEventCoordinator.coordinateDataHarmonization(participatingMods, coordinationData)
    else
        AE_UIEventCoordinator.handleRequestError(coordinationData, "Unknown coordination type: " .. coordinationType)
        return false
    end
end

-- Coordinate status synchronization across multiple mods
function AE_UIEventCoordinator.coordinateStatusSync(participatingMods, coordinationData)
    local animalID = coordinationData.animalID
    if not animalID then return false end
    
    -- Request status data from all participating mods
    local statusResponses = {}
    local responsesReceived = 0
    local expectedResponses = #participatingMods
    
    for _, modName in ipairs(participatingMods) do
        sendServerCommand("AE_CrossModService", "integrationRequest", {
            sourceMod = "AE_Framework",
            targetMod = modName,
            requestType = "getStatusData",
            animalID = animalID,
            responseHandler = function(responseData)
                statusResponses[modName] = responseData
                responsesReceived = responsesReceived + 1
                
                -- When all responses received, coordinate synchronization
                if responsesReceived >= expectedResponses then
                    AE_UIEventCoordinator.processSynchronizedStatus(statusResponses, coordinationData)
                end
            end
        })
    end
    
    return true
end

-- Process synchronized status from multiple mods
function AE_UIEventCoordinator.processSynchronizedStatus(statusResponses, coordinationData)
    local synchronizedData = {}
    local conflictFields = {}
    
    -- Merge status data from all mods
    for modName, responseData in pairs(statusResponses) do
        if responseData.success and responseData.statusData then
            for key, value in pairs(responseData.statusData) do
                if synchronizedData[key] and synchronizedData[key] ~= value then
                    -- Track conflicts for resolution
                    if not conflictFields[key] then
                        conflictFields[key] = {}
                    end
                    conflictFields[key][modName] = value
                else
                    synchronizedData[key] = value
                end
            end
        end
    end
    
    -- Resolve conflicts using priority or merge strategies
    for field, conflictData in pairs(conflictFields) do
        synchronizedData[field] = AE_UIEventCoordinator.resolveStatusConflict(field, conflictData)
    end
    
    -- Broadcast synchronized status to all participating mods
    sendServerCommand("AE_CrossModService", "syncComplete", {
        syncType = "statusSynchronized",
        animalID = coordinationData.animalID,
        synchronizedData = synchronizedData,
        participatingMods = coordinationData.participatingMods,
        timestamp = getTimestamp()
    })
end

-- Resolve status conflicts between mods
function AE_UIEventCoordinator.resolveStatusConflict(field, conflictData)
    -- Priority-based resolution for critical fields
    local criticalFields = {
        tameness = "highest",
        health = "average",
        owner = "framework",
        name = "nonEmpty"
    }
    
    local resolution = criticalFields[field]
    if not resolution then
        resolution = "latest" -- Default resolution
    end
    
    if resolution == "highest" then
        local maxValue = nil
        for modName, value in pairs(conflictData) do
            if type(value) == "number" and (not maxValue or value > maxValue) then
                maxValue = value
            end
        end
        return maxValue
    elseif resolution == "average" then
        local total = 0
        local count = 0
        for modName, value in pairs(conflictData) do
            if type(value) == "number" then
                total = total + value
                count = count + 1
            end
        end
        return count > 0 and (total / count) or 0
    elseif resolution == "framework" then
        return conflictData["AE_Framework"] or next(conflictData)
    elseif resolution == "nonEmpty" then
        for modName, value in pairs(conflictData) do
            if value and value ~= "" then
                return value
            end
        end
        return next(conflictData)
    else
        -- Latest timestamp or first available
        return next(conflictData)
    end
end

-- Reset performance monitoring data
function AE_UIEventCoordinator.resetPerformanceMonitoring()
    crossModPerformance = {
        operationTimes = {},
        operationCounts = {},
        errorCounts = {},
        lastReset = getTimestamp()
    }
end

-- Enhanced cleanup function
function AE_UIEventCoordinator.cleanup()
    activeUISubscriptions = {}
    uiUpdateBatchQueue = {}
    batchUpdateScheduled = false
    uiComponentRegistry = {}
    
    -- Clean up performance monitoring
    AE_UIEventCoordinator.resetPerformanceMonitoring()
end

-- Initialize on game start
Events.OnGameStart.Add(AE_UIEventCoordinator.initialize)

-- Cleanup on game end
Events.OnGameBoot.Add(AE_UIEventCoordinator.cleanup)

return AE_UIEventCoordinator