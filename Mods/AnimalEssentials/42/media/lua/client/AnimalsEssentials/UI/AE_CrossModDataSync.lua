-- SESSION 6B2: UI Data Synchronization Protocols
-- Advanced cross-mod data synchronization with efficient conflict resolution

local AE_CrossModDataSync = {}

-- Data synchronization state management
local syncRegistry = {}
local activeSyncOperations = {}
local conflictResolution = {}
local syncBatching = {}

-- Configuration
local SYNC_BATCH_INTERVAL = 100 -- milliseconds
local MAX_SYNC_BATCH_SIZE = 15
local CONFLICT_RESOLUTION_TIMEOUT = 5000 -- milliseconds
local DATA_SCOPE_FILTERS = {
    "animalData",
    "playerData", 
    "modSpecificData",
    "frameworkData"
}

-- Initialize data synchronization protocols
function AE_CrossModDataSync.initialize()
    AE_CrossModDataSync.setupEventHandlers()
    AE_CrossModDataSync.initializeSyncRegistry()
    AE_CrossModDataSync.initializeConflictResolution()
end

-- Setup event handlers for data synchronization
function AE_CrossModDataSync.setupEventHandlers()
    -- B42-compatible event handling via AE_EventRegistry
    local AE_EventRegistry = nil
    local success, result = pcall(function()
        return require("AnimalsEssentials/Config/AE_EventRegistry")
    end)
    if success and result then
        AE_EventRegistry = result
        
        -- Cross-mod data sync requests
        AE_EventRegistry.subscribeEvent("OnAE_CrossMod_DataSyncRequest", function(eventData)
            AE_CrossModDataSync.handleDataSyncRequest(eventData)
        end)
        
        -- Animal data changes requiring cross-mod sync
        AE_EventRegistry.subscribeEvent("OnAE_AnimalDataChanged", function(eventData)
            AE_CrossModDataSync.propagateDataChanges(eventData)
        end)
        
        -- Framework data service responses
        AE_EventRegistry.subscribeEvent("OnAE_UI_DataResponse", function(responseData)
            if responseData.syncOperation then
                AE_CrossModDataSync.processSyncResponse(responseData)
            end
        end)
        
        -- Conflict resolution events
        AE_EventRegistry.subscribeEvent("OnAE_DataConflictDetected", function(conflictData)
            AE_CrossModDataSync.handleDataConflict(conflictData)
        end)
    else
        -- B42 fallback - no cross-mod sync events
        print("[AE_CrossModDataSync] B42 Mode: Cross-mod sync events not supported - manual synchronization required")
    end
end

-- Initialize synchronization registry
function AE_CrossModDataSync.initializeSyncRegistry()
    syncRegistry = {
        registeredMods = {},
        dataScopes = {},
        syncPolicies = {},
        lastSyncTimes = {}
    }
    
    -- Register framework core
    AE_CrossModDataSync.registerModForSync({
        modName = "AE_Framework",
        supportedDataTypes = {"animalData", "frameworkData", "playerAnimalList"},
        syncPriority = "high",
        conflictResolutionStrategy = "authoritative"
    })
end

-- Initialize conflict resolution system
function AE_CrossModDataSync.initializeConflictResolution()
    -- Initialize conflict tracking
    if not AE_CrossModDataSync.activeConflicts then
        AE_CrossModDataSync.activeConflicts = {}
    end
    
    if not AE_CrossModDataSync.resolutionHistory then
        AE_CrossModDataSync.resolutionHistory = {}
    end
    
    -- Set default conflict resolution strategies
    AE_CrossModDataSync.defaultResolutionStrategy = "authoritative"
    AE_CrossModDataSync.conflictTimeoutMs = 30000 -- 30 seconds
    
    return true
end

-- Register mod for data synchronization
function AE_CrossModDataSync.registerModForSync(registrationData)
    if not registrationData or not registrationData.modName then return false end
    
    local modName = registrationData.modName
    
    syncRegistry.registeredMods[modName] = {
        supportedDataTypes = registrationData.supportedDataTypes or {},
        syncPriority = registrationData.syncPriority or "normal",
        conflictResolutionStrategy = registrationData.conflictResolutionStrategy or "merge",
        lastActivity = getTimestamp(),
        syncCapabilities = registrationData.syncCapabilities or {},
        dataFilters = registrationData.dataFilters or {}
    }
    
    -- Initialize data scopes for this mod
    for _, dataType in ipairs(registrationData.supportedDataTypes) do
        if not syncRegistry.dataScopes[dataType] then
            syncRegistry.dataScopes[dataType] = {}
        end
        table.insert(syncRegistry.dataScopes[dataType], modName)
    end
    
    return true
end

-- Handle cross-mod data synchronization requests
function AE_CrossModDataSync.handleDataSyncRequest(requestData)
    if not requestData or not requestData.sourceMod or not requestData.dataScope then
        return false
    end
    
    local sourceMod = requestData.sourceMod
    local dataScope = requestData.dataScope
    local syncType = requestData.syncType or "bidirectional"
    
    -- Validate mod registration
    if not syncRegistry.registeredMods[sourceMod] then
        AE_CrossModDataSync.handleSyncError(requestData, "Source mod not registered for sync")
        return false
    end
    
    -- Check data scope permissions
    if not AE_CrossModDataSync.validateDataScopeAccess(sourceMod, dataScope) then
        AE_CrossModDataSync.handleSyncError(requestData, "Access denied for data scope")
        return false
    end
    
    -- Process sync request based on type
    if syncType == "push" then
        return AE_CrossModDataSync.processPushSync(requestData)
    elseif syncType == "pull" then
        return AE_CrossModDataSync.processPullSync(requestData)
    elseif syncType == "bidirectional" then
        return AE_CrossModDataSync.processBidirectionalSync(requestData)
    else
        AE_CrossModDataSync.handleSyncError(requestData, "Unknown sync type: " .. syncType)
        return false
    end
end

-- Process push synchronization (mod to framework)
function AE_CrossModDataSync.processPushSync(requestData)
    local sourceMod = requestData.sourceMod
    local dataPayload = requestData.dataPayload
    local dataScope = requestData.dataScope
    
    if not dataPayload then
        AE_CrossModDataSync.handleSyncError(requestData, "No data payload provided")
        return false
    end
    
    -- Check for conflicts with existing data
    local conflictCheck = AE_CrossModDataSync.checkForDataConflicts(dataPayload, dataScope, sourceMod)
    if conflictCheck.hasConflicts then
        return AE_CrossModDataSync.initiateConflictResolution(requestData, conflictCheck)
    end
    
    -- Batch the sync operation for efficiency
    AE_CrossModDataSync.batchSyncOperation({
        operation = "push",
        sourceMod = sourceMod,
        dataScope = dataScope,
        dataPayload = dataPayload,
        requestData = requestData
    })
    
    return true
end

-- Process pull synchronization (framework to mod)
function AE_CrossModDataSync.processPullSync(requestData)
    local sourceMod = requestData.sourceMod
    local dataScope = requestData.dataScope
    local dataFilter = requestData.dataFilter or {}
    
    -- Request data from framework data service
    sendServerCommand("AE_UIService", "dataRequest", {
        requestType = "crossModSync",
        dataScope = dataScope,
        dataFilter = dataFilter,
        sourceMod = sourceMod,
        uiComponent = "AE_CrossModDataSync",
        syncOperation = true,
        responseHandler = function(responseData)
            if responseData.success then
                AE_CrossModDataSync.deliverPulledData(requestData, responseData)
            else
                AE_CrossModDataSync.handleSyncError(requestData, "Data pull failed")
            end
        end
    })
    
    return true
end

-- Process bidirectional synchronization
function AE_CrossModDataSync.processBidirectionalSync(requestData)
    -- First perform pull to get current framework data
    local pullSuccess = AE_CrossModDataSync.processPullSync({
        sourceMod = requestData.sourceMod,
        dataScope = requestData.dataScope,
        dataFilter = requestData.dataFilter,
        responseHandler = function(pullResponseData)
            -- Then perform push with potential conflict resolution
            if pullResponseData.success then
                local enrichedRequestData = requestData
                enrichedRequestData.frameworkData = pullResponseData.data
                AE_CrossModDataSync.processPushSync(enrichedRequestData)
            end
        end
    })
    
    return pullSuccess
end

-- Check for data conflicts during synchronization
function AE_CrossModDataSync.checkForDataConflicts(dataPayload, dataScope, sourceMod)
    local conflictInfo = {
        hasConflicts = false,
        conflicts = {},
        conflictLevel = "none"
    }
    
    -- Check timestamp-based conflicts
    if dataPayload.lastModified then
        local frameworkLastModified = AE_CrossModDataSync.getFrameworkDataTimestamp(dataScope, dataPayload.animalID)
        if frameworkLastModified and frameworkLastModified > dataPayload.lastModified then
            conflictInfo.hasConflicts = true
            conflictInfo.conflictLevel = "timestamp"
            table.insert(conflictInfo.conflicts, {
                type = "timestamp",
                frameworkTime = frameworkLastModified,
                modTime = dataPayload.lastModified
            })
        end
    end
    
    -- Check value-based conflicts for critical fields
    if dataPayload.animalID then
        local frameworkData = AE_CrossModDataSync.getFrameworkAnimalData(dataPayload.animalID)
        if frameworkData then
            for key, value in pairs(dataPayload) do
                if frameworkData[key] and frameworkData[key] ~= value then
                    if AE_CrossModDataSync.isCriticalField(key) then
                        conflictInfo.hasConflicts = true
                        conflictInfo.conflictLevel = "critical"
                        table.insert(conflictInfo.conflicts, {
                            type = "value",
                            field = key,
                            frameworkValue = frameworkData[key],
                            modValue = value
                        })
                    end
                end
            end
        end
    end
    
    return conflictInfo
end

-- Determine if field is critical for conflict resolution
function AE_CrossModDataSync.isCriticalField(fieldName)
    local criticalFields = {
        "animalID", "owner", "tameness", "health", "name"
    }
    
    for _, criticalField in ipairs(criticalFields) do
        if fieldName == criticalField then
            return true
        end
    end
    return false
end

-- Initiate conflict resolution process
function AE_CrossModDataSync.initiateConflictResolution(requestData, conflictInfo)
    local resolutionID = AE_CrossModDataSync.generateResolutionID()
    local sourceMod = requestData.sourceMod
    
    conflictResolution[resolutionID] = {
        requestData = requestData,
        conflictInfo = conflictInfo,
        sourceMod = sourceMod,
        startTime = getTimestamp(),
        status = "pending",
        strategy = syncRegistry.registeredMods[sourceMod].conflictResolutionStrategy
    }
    
    -- Apply conflict resolution strategy
    local strategy = conflictResolution[resolutionID].strategy
    
    if strategy == "authoritative" then
        -- Framework takes precedence
        AE_CrossModDataSync.resolveConflictAuthoritative(resolutionID)
    elseif strategy == "merge" then
        -- Attempt intelligent merge
        AE_CrossModDataSync.resolveConflictMerge(resolutionID)
    elseif strategy == "user" then
        -- Request user intervention
        AE_CrossModDataSync.requestUserConflictResolution(resolutionID)
    else
        -- Default to merge strategy
        AE_CrossModDataSync.resolveConflictMerge(resolutionID)
    end
    
    return true
end

-- Resolve conflict using authoritative strategy
function AE_CrossModDataSync.resolveConflictAuthoritative(resolutionID)
    local resolution = conflictResolution[resolutionID]
    if not resolution then return false end
    
    -- Framework data takes precedence, reject mod changes
    resolution.status = "resolved_framework"
    resolution.resolution = "Framework data maintained, mod data rejected"
    
    -- Notify mod of conflict resolution
    AE_CrossModDataSync.notifyConflictResolution(resolutionID)
    return true
end

-- Resolve conflict using merge strategy
function AE_CrossModDataSync.resolveConflictMerge(resolutionID)
    local resolution = conflictResolution[resolutionID]
    if not resolution then return false end
    
    local requestData = resolution.requestData
    local conflictInfo = resolution.conflictInfo
    
    -- Create merged data
    local mergedData = AE_CrossModDataSync.mergeConflictingData(
        requestData.dataPayload,
        conflictInfo.conflicts
    )
    
    if mergedData then
        -- Apply merged data
        requestData.dataPayload = mergedData
        AE_CrossModDataSync.batchSyncOperation({
            operation = "merge",
            sourceMod = requestData.sourceMod,
            dataScope = requestData.dataScope,
            dataPayload = mergedData,
            requestData = requestData,
            resolutionID = resolutionID
        })
        
        resolution.status = "resolved_merged"
        resolution.resolution = "Data successfully merged"
    else
        resolution.status = "failed"
        resolution.resolution = "Merge failed, conflicts unresolvable"
    end
    
    AE_CrossModDataSync.notifyConflictResolution(resolutionID)
    return resolution.status == "resolved_merged"
end

-- Merge conflicting data intelligently
function AE_CrossModDataSync.mergeConflictingData(modData, conflicts)
    local mergedData = {}
    
    -- Start with mod data
    for key, value in pairs(modData) do
        mergedData[key] = value
    end
    
    -- Apply conflict resolution rules
    for _, conflict in ipairs(conflicts) do
        if conflict.type == "value" then
            local field = conflict.field
            
            -- Apply field-specific merge rules
            if field == "tameness" or field == "affection" then
                -- Use higher value for progression fields
                mergedData[field] = math.max(conflict.frameworkValue, conflict.modValue)
            elseif field == "health" or field == "energy" then
                -- Use framework value for critical status
                mergedData[field] = conflict.frameworkValue
            elseif field == "name" then
                -- Prefer non-empty name
                if conflict.modValue and conflict.modValue ~= "" then
                    mergedData[field] = conflict.modValue
                else
                    mergedData[field] = conflict.frameworkValue
                end
            else
                -- Default to framework value for unknown fields
                mergedData[field] = conflict.frameworkValue
            end
        end
    end
    
    -- Update timestamp to current time
    mergedData.lastModified = getTimestamp()
    mergedData.mergeResolved = true
    
    return mergedData
end

-- Efficient batching system for sync operations
function AE_CrossModDataSync.batchSyncOperation(syncOperation)
    table.insert(syncBatching.queue, syncOperation)
    
    if not syncBatching.scheduled then
        syncBatching.scheduled = true
        
        Events.OnTick.Add(function()
            if getTimestamp() >= (syncBatching.lastBatch or 0) + SYNC_BATCH_INTERVAL then
                AE_CrossModDataSync.processBatchedSyncOperations()
                syncBatching.scheduled = false
                Events.OnTick.Remove(AE_CrossModDataSync.processBatchedSyncOperations)
            end
        end)
    end
end

-- Process batched synchronization operations
function AE_CrossModDataSync.processBatchedSyncOperations()
    if not syncBatching.queue or #syncBatching.queue == 0 then
        syncBatching.queue = {}
        return
    end
    
    -- Process up to max batch size
    local processed = 0
    local remainingOperations = {}
    
    for _, syncOp in ipairs(syncBatching.queue) do
        if processed < MAX_SYNC_BATCH_SIZE then
            AE_CrossModDataSync.executeIndividualSyncOperation(syncOp)
            processed = processed + 1
        else
            table.insert(remainingOperations, syncOp)
        end
    end
    
    syncBatching.queue = remainingOperations
    syncBatching.lastBatch = getTimestamp()
    
    -- Schedule next batch if needed
    if #remainingOperations > 0 then
        syncBatching.scheduled = true
        Events.OnTick.Add(function()
            if getTimestamp() >= syncBatching.lastBatch + SYNC_BATCH_INTERVAL then
                AE_CrossModDataSync.processBatchedSyncOperations()
                syncBatching.scheduled = false
                Events.OnTick.Remove(AE_CrossModDataSync.processBatchedSyncOperations)
            end
        end)
    end
end

-- Execute individual sync operation
function AE_CrossModDataSync.executeIndividualSyncOperation(syncOp)
    local operation = syncOp.operation
    local sourceMod = syncOp.sourceMod
    
    if operation == "push" or operation == "merge" then
        -- Send data to framework
        sendServerCommand("AE_UIService", "componentUpdate", {
            dataScope = syncOp.dataScope,
            dataPayload = syncOp.dataPayload,
            sourceMod = sourceMod,
            syncOperation = true,
            responseHandler = function(responseData)
                AE_CrossModDataSync.handleSyncOperationComplete(syncOp, responseData)
            end
        })
    end
    
    -- Update sync registry
    syncRegistry.lastSyncTimes[sourceMod] = getTimestamp()
end

-- Handle completion of sync operation
function AE_CrossModDataSync.handleSyncOperationComplete(syncOp, responseData)
    local requestData = syncOp.requestData
    
    if responseData.success then
        -- Notify requesting mod of successful sync
        sendServerCommand("AE_CrossModService", "syncComplete", {
            sourceMod = syncOp.sourceMod,
            dataScope = syncOp.dataScope,
            operation = syncOp.operation,
            success = true,
            syncTime = getTimestamp()
        })
        
        -- Trigger UI updates for interested parties
        sendServerCommand("AE_UIService", "broadcastUpdate", {
            dataScope = syncOp.dataScope,
            sourceMod = syncOp.sourceMod
        })
    else
        AE_CrossModDataSync.handleSyncError(requestData, "Sync operation failed")
    end
end

-- Propagate data changes to interested mods
function AE_CrossModDataSync.propagateDataChanges(eventData)
    if not eventData or not eventData.dataScope then return end
    
    local dataScope = eventData.dataScope
    local interestedMods = syncRegistry.dataScopes[dataScope] or {}
    
    for _, modName in ipairs(interestedMods) do
        if modName ~= eventData.sourceMod then
            -- Selective refresh based on data scope
            sendServerCommand("AE_UIService", "componentUpdate", {
                targetComponent = modName,
                updateType = "dataChanged",
                dataScope = dataScope,
                changedData = eventData.changedData,
                animalID = eventData.animalID,
                priority = "normal"
            })
        end
    end
end

-- Validate data scope access for mod
function AE_CrossModDataSync.validateDataScopeAccess(modName, dataScope)
    local modInfo = syncRegistry.registeredMods[modName]
    if not modInfo then return false end
    
    for _, supportedType in ipairs(modInfo.supportedDataTypes) do
        if supportedType == dataScope then
            return true
        end
    end
    return false
end

-- Error handling for synchronization operations
function AE_CrossModDataSync.handleSyncError(requestData, errorMessage)
    local errorInfo = {
        requestData = requestData,
        errorMessage = errorMessage,
        timestamp = getTimestamp(),
        source = "AE_CrossModDataSync"
    }
    
    sendServerCommand("AE_CrossModService", "statusUpdate", {
        modName = "AE_CrossModDataSync",
        status = "syncError",
        errorInfo = errorInfo
    })
    
    if requestData and requestData.responseHandler then
        requestData.responseHandler({
            success = false,
            error = errorMessage,
            timestamp = getTimestamp()
        })
    end
end

-- Utility functions
function AE_CrossModDataSync.generateResolutionID()
    return "conflict_" .. getTimestamp() .. "_" .. math.random(1000, 9999)
end

function AE_CrossModDataSync.getFrameworkDataTimestamp(dataScope, animalID)
    -- Request timestamp from framework
    local timestamp = nil
    sendServerCommand("AE_UIService", "dataRequest", {
        requestType = "dataTimestamp",
        dataScope = dataScope,
        animalID = animalID,
        responseHandler = function(responseData)
            if responseData.success then
                timestamp = responseData.timestamp
            end
        end
    })
    return timestamp
end

function AE_CrossModDataSync.getFrameworkAnimalData(animalID)
    -- Request current framework data
    local frameworkData = nil
    sendServerCommand("AE_UIService", "dataRequest", {
        requestType = "animalData",
        animalID = animalID,
        responseHandler = function(responseData)
            if responseData.success then
                frameworkData = responseData.animalData
            end
        end
    })
    return frameworkData
end

-- Public API functions
function AE_CrossModDataSync.getSyncRegistry()
    return syncRegistry
end

function AE_CrossModDataSync.getActiveSyncOperations()
    return activeSyncOperations
end

function AE_CrossModDataSync.isModRegistered(modName)
    return syncRegistry.registeredMods[modName] ~= nil
end

-- Cleanup function
function AE_CrossModDataSync.cleanup()
    syncRegistry = {}
    activeSyncOperations = {}
    conflictResolution = {}
    syncBatching = {queue = {}, scheduled = false}
end

-- Initialize batching system
syncBatching = {
    queue = {},
    scheduled = false,
    lastBatch = 0
}

-- Initialize on game start
Events.OnGameStart.Add(AE_CrossModDataSync.initialize)
Events.OnGameBoot.Add(AE_CrossModDataSync.cleanup)

return AE_CrossModDataSync