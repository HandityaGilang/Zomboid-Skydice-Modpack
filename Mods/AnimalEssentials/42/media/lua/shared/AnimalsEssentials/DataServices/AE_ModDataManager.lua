AE_ModDataManager = {}


local modDataCache = {}
local cacheMetadata = {}
local batchOperations = {}

local cacheGeneration = 0

local CACHE_TTL = 5000
local BATCH_SIZE = 10
local BATCH_DELAY = 100

function AE_ModDataManager.validateModDataAccess(animal, key)
    if not animal then
        print("[AE_ModDataManager] ERROR: Animal is nil")
        return false
    end
    
    if not key then
        print("[AE_ModDataManager] ERROR: ModData key is nil") 
        return false
    end
    
    local success, modData = pcall(function()
        return animal:getModData()
    end)
    
    if not success or not modData then
        print("[AE_ModDataManager] ERROR: Cannot access animal ModData")
        return false
    end
    
    return true
end

function AE_ModDataManager.getModDataCached(animal, key)
    if not AE_ModDataManager.validateModDataAccess(animal, key) then
        return nil
    end
    
    local animalID = animal:getID()
    local cacheKey = animalID .. ":" .. key
    
    local cached = modDataCache[cacheKey]
    local metadata = cacheMetadata[cacheKey]
    
    if cached and metadata and metadata.generation == cacheGeneration then
        metadata.hits = metadata.hits + 1
        return cached
    end
    
    local success, value = pcall(function()
        return animal:getModData()[key]
    end)
    
    if success then
        modDataCache[cacheKey] = value
        cacheMetadata[cacheKey] = {
            generation = cacheGeneration,
            hits = 1,
            misses = (metadata and metadata.misses or 0) + 1
        }
        return value
    end
    
    print("[AE_ModDataManager] ERROR reading ModData key '" .. key .. "': " .. tostring(value))
    return nil
end

function AE_ModDataManager.setModDataDirect(animal, key, value)
    if not AE_ModDataManager.validateModDataAccess(animal, key) then
        return false
    end
    
    local success, error = pcall(function()
        animal:getModData()[key] = value
    end)
    
    if success then
        local animalID = animal:getID()
        local cacheKey = animalID .. ":" .. key
        modDataCache[cacheKey] = nil
        cacheMetadata[cacheKey] = nil
        
        return true
    end
    
    print("[AE_ModDataManager] ERROR writing ModData key '" .. key .. "': " .. tostring(error))
    return false
end

function AE_ModDataManager.addToBatch(animal, key, value, operation)
    if not animal or not key then return false end
    
    local animalID = animal:getID()
    local batchKey = animalID
    
    if not batchOperations[batchKey] then
        local gameTimeInstance = GameTime and GameTime.getInstance and GameTime.getInstance()
        local scheduledMinutes = 1
        if gameTimeInstance and gameTimeInstance.getWorldAgeHours then
            scheduledMinutes = math.floor((gameTimeInstance:getWorldAgeHours() or 0) * 60) + 1
        end
        
        batchOperations[batchKey] = {
            animal = animal,
            operations = {},
            scheduledMinutes = scheduledMinutes
        }
    end
    
    table.insert(batchOperations[batchKey].operations, {
        key = key,
        value = value,
        operation = operation or "set"
    })
    
    if #batchOperations[batchKey].operations >= BATCH_SIZE then
        AE_ModDataManager.executeBatch(batchKey)
    end
    
    return true
end

function AE_ModDataManager.executeBatch(batchKey)
    local batch = batchOperations[batchKey]
    if not batch then return false end
    
    local animal = batch.animal
    if not AE_ModDataManager.validateModDataAccess(animal, "batch_check") then
        batchOperations[batchKey] = nil
        return false
    end
    
    local modData = animal:getModData()
    local successCount = 0
    
    for _, op in ipairs(batch.operations) do
        local success, error = pcall(function()
            if op.operation == "set" then
                modData[op.key] = op.value
            elseif op.operation == "delete" then
                modData[op.key] = nil
            end
        end)
        
        if success then
            successCount = successCount + 1
            local animalID = animal:getID()
            local cacheKey = animalID .. ":" .. op.key
            modDataCache[cacheKey] = nil
            cacheMetadata[cacheKey] = nil
        else
            print("[AE_ModDataManager] Batch operation failed for key '" .. op.key .. "': " .. tostring(error))
        end
    end
    
    batchOperations[batchKey] = nil
    
    if successCount > 0 and AE_EventRegistry then
        AE_EventRegistry.safeFireEvent("OnAE_StateUpdated", {
            animalID = animal:getID(),
            batchOperations = successCount,
            timestamp = GameTime.getServerTimeMills()
        })
    end
    
    return successCount > 0
end

function AE_ModDataManager.processPendingBatches()
    local hasPendingBatches = false
    for _ in pairs(batchOperations) do
        hasPendingBatches = true
        break
    end
    if not hasPendingBatches then
        return 0
    end
    
    local gameTimeInstance = GameTime and GameTime.getInstance and GameTime.getInstance()
    if not gameTimeInstance or not gameTimeInstance.getWorldAgeHours then
        return 0
    end
    
    local currentMinutes = math.floor((gameTimeInstance:getWorldAgeHours() or 0) * 60)
    local processedCount = 0
    
    for batchKey, batch in pairs(batchOperations) do
        if currentMinutes >= batch.scheduledMinutes then
            if AE_ModDataManager.executeBatch(batchKey) then
                processedCount = processedCount + 1
            end
        end
    end
    
    return processedCount
end

function AE_ModDataManager.validateModDataIntegrity(animal)
    if not animal then return false end
    
    local issues = {}
    local modData = animal:getModData()
    
    if not modData then
        table.insert(issues, "ModData is nil")
        return false, issues
    end
    
    for key, value in pairs(modData) do
        local namespace = AE_NamespaceManager.extractNamespace(key)
        if namespace == "UNKNOWN" and not string.find(key, "_") then
            table.insert(issues, "Key '" .. key .. "' lacks namespace prefix")
        end
        
        if AE_DataConfig and AE_DataConfig.ModDataKeys then
            for configKey, expectedKey in pairs(AE_DataConfig.ModDataKeys) do
                if key == expectedKey then
                    local valid = AE_ModDataManager.validateDataType(configKey, value)
                    if not valid then
                        table.insert(issues, "Invalid data type for key '" .. key .. "'")
                    end
                end
            end
        end
    end
    
    return #issues == 0, issues
end

function AE_ModDataManager.validateDataType(configKey, value)
    local expectedTypes = {
        Tameness = "number",
        IsTamed = "boolean", 
        OwnerID = "string",
        CurrentCommand = "string",
        BehaviorState = "string",
        Hunger = "number",
        Thirst = "number",
        Health = "number",
        Breed = "string",
        Equipment = "table",
        Attachments = "table",
        Genetics = "table"
    }
    
    local expectedType = expectedTypes[configKey]
    if not expectedType then return true end
    
    if expectedType == "table" then
        return type(value) == "table" or value == nil
    elseif expectedType == "number" then
        return type(value) == "number" and value >= 0 and value <= 100
    elseif expectedType == "boolean" then
        return type(value) == "boolean" or value == nil
    elseif expectedType == "string" then
        return type(value) == "string" or value == nil
    end
    
    return false
end

function AE_ModDataManager.invalidateCache(animalID)
    cacheGeneration = cacheGeneration + 1
end

function AE_ModDataManager.cleanupCache()
    local cleanupGeneration = cacheGeneration - 2
    local cleanedCount = 0
    
    for cacheKey, metadata in pairs(cacheMetadata) do
        if metadata.generation < cleanupGeneration then
            modDataCache[cacheKey] = nil
            cacheMetadata[cacheKey] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        print("[AE_ModDataManager] Cleaned " .. cleanedCount .. " expired cache entries")
    end
    
    return cleanedCount
end

function AE_ModDataManager.getCacheStatistics()
    local stats = {
        cacheSize = 0,
        totalHits = 0,
        totalMisses = 0,
        hitRatio = 0,
        pendingBatches = 0
    }
    
    for cacheKey, _ in pairs(modDataCache) do
        stats.cacheSize = stats.cacheSize + 1
    end
    
    for _, metadata in pairs(cacheMetadata) do
        stats.totalHits = stats.totalHits + (metadata.hits or 0)
        stats.totalMisses = stats.totalMisses + (metadata.misses or 0)
    end
    
    if stats.totalHits + stats.totalMisses > 0 then
        stats.hitRatio = stats.totalHits / (stats.totalHits + stats.totalMisses)
    end
    
    for _ in pairs(batchOperations) do
        stats.pendingBatches = stats.pendingBatches + 1
    end
    
    return stats
end

function AE_ModDataManager.flushCache()
    local count = 0
    for _ in pairs(modDataCache) do
        count = count + 1
    end
    
    modDataCache = {}
    cacheMetadata = {}
    
    print("[AE_ModDataManager] Cache flushed - " .. count .. " entries cleared")
    return count
end

function AE_ModDataManager.createModDataBackup(animal)
    if not AE_ModDataManager.validateModDataAccess(animal, "backup") then
        return nil
    end
    
    local animalID = animal:getID()
    local modData = animal:getModData()
    local backup = {}
    
    for key, value in pairs(modData) do
        if type(value) == "table" then
            backup[key] = {}
            for k, v in pairs(value) do
                backup[key][k] = v
            end
        else
            backup[key] = value
        end
    end
    
    backup._backupTimestamp = GameTime.getServerTimeMills()
    backup._animalID = animalID
    
    return backup
end

function AE_ModDataManager.restoreModDataBackup(animal, backup)
    if not AE_ModDataManager.validateModDataAccess(animal, "restore") then
        return false
    end
    
    if not backup or not backup._backupTimestamp then
        print("[AE_ModDataManager] ERROR: Invalid backup data")
        return false
    end
    
    local modData = animal:getModData()
    local restoredCount = 0
    
    for key, _ in pairs(modData) do
        if not string.find(key, "^_") then
            modData[key] = nil
        end
    end
    
    for key, value in pairs(backup) do
        if not string.find(key, "^_") then
            modData[key] = value
            restoredCount = restoredCount + 1
        end
    end
    
    local animalID = animal:getID()
    for cacheKey, _ in pairs(modDataCache) do
        if string.find(cacheKey, "^" .. animalID .. ":") then
            modDataCache[cacheKey] = nil
            cacheMetadata[cacheKey] = nil
        end
    end
    
    print("[AE_ModDataManager] Restored " .. restoredCount .. " ModData keys from backup")
    return restoredCount > 0
end

function AE_ModDataManager.initialize()
    Events.EveryOneMinute.Add(AE_ModDataManager.processPendingBatches)
    
    -- PHASE 2 CONSOLIDATION: Timer moved to AE_DataCleanupCoordinator
    -- Events.EveryTenMinutes.Add(AE_ModDataManager.cleanupCache) -- Disabled - handled by coordinator
    
    if AE_EventRegistry then
        if not _G.AE_InitSequence then _G.AE_InitSequence = 0 end
        _G.AE_InitSequence = _G.AE_InitSequence + 1
        
        AE_EventRegistry.safeFireEvent("OnAE_SystemInitialized", {
            module = "AE_ModDataManager",
            cacheEnabled = true,
            batchingEnabled = true,
            initSequence = _G.AE_InitSequence
        })
    end
    
    print("[AE_ModDataManager] ModData management system initialized")
    return true
end

_G.AE_ModDataManager = AE_ModDataManager

return AE_ModDataManager