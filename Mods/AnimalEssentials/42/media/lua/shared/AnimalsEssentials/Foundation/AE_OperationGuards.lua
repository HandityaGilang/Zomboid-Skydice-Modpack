
local AE_OperationGuards = {}

local function getSafeTime()
    if GameTime and GameTime.getServerTimeMills then
        return GameTime.getServerTimeMills()
    elseif getTimestampMs then
        return getTimestampMs()
    else
        return os.time() * 1000
    end
end

if not _G.AE_OperationGuards then
    _G.AE_OperationGuards = {
        validatingAnimal = {},
        restoringSnapshot = {},
        makingTamed = {},
        lastCleanup = 0,
        timeout = 30000
    }
end

if not _G.AE_OperationLocks then
    _G.AE_OperationLocks = {
        snapshotOperations = {},
        tamingOperations = {},
        atomicTimeout = 10000,
        lastAtomicCleanup = getSafeTime()
    }
end

function AE_OperationGuards.withOperationGuard(animalID, operation, func)
    if not animalID or not operation or not func then
        return false, "Invalid parameters for operation guard"
    end
    
    local currentTime = getSafeTime()
    local guards = _G.AE_OperationGuards
    
    if guards[operation] and guards[operation][animalID] then
        local startTime = guards[operation][animalID]
        if currentTime - startTime < guards.timeout then
            return false, "Operation already in progress: " .. operation .. " for animal " .. animalID
        else
            guards[operation][animalID] = nil
        end
    end
    
    if not guards[operation] then
        guards[operation] = {}
    end
    guards[operation][animalID] = currentTime
    
    local success, result = pcall(func)
    
    guards[operation][animalID] = nil
    
    if currentTime - guards.lastCleanup > 60000 then
        AE_OperationGuards.cleanupStaleGuards()
        guards.lastCleanup = currentTime
    end
    
    if success then
        return true, result
    else
        return false, "Operation failed: " .. tostring(result)
    end
end

function AE_OperationGuards.cleanupStaleGuards()
    local currentTime = getSafeTime()
    local guards = _G.AE_OperationGuards
    local timeout = guards.timeout
    
    for operationType, operations in pairs(guards) do
        if type(operations) == "table" and operationType ~= "lastCleanup" and operationType ~= "timeout" then
            local staleEntries = {}
            for animalID, startTime in pairs(operations) do
                if currentTime - startTime > timeout then
                    table.insert(staleEntries, animalID)
                end
            end
            for _, animalID in ipairs(staleEntries) do
                operations[animalID] = nil
            end
        end
    end
end

function AE_OperationGuards.isOperationGuarded(animalID, operation)
    local guards = _G.AE_OperationGuards
    if not guards[operation] then return false end
    
    local currentTime = getSafeTime()
    local startTime = guards[operation][animalID]
    
    if startTime and (currentTime - startTime < guards.timeout) then
        return true
    end
    
    return false
end

function AE_OperationGuards.getOperationStats()
    local guards = _G.AE_OperationGuards
    local stats = {
        activeOperations = {},
        totalActive = 0
    }
    
    for operationType, operations in pairs(guards) do
        if type(operations) == "table" and operationType ~= "lastCleanup" and operationType ~= "timeout" then
            local count = 0
            for animalID, startTime in pairs(operations) do
                count = count + 1
            end
            if count > 0 then
                stats.activeOperations[operationType] = count
                stats.totalActive = stats.totalActive + count
            end
        end
    end
    
    return stats
end

function AE_OperationGuards.withAtomicOperation(animalID, operationType, func)
    if not animalID or not operationType or not func then
        return false, "Invalid parameters for atomic operation"
    end
    
    local currentTime = getSafeTime()
    local locks = _G.AE_OperationLocks
    local lockCategory = operationType == "taming" and "tamingOperations" or "snapshotOperations"
    
    if locks[lockCategory][animalID] then
        local lockInfo = locks[lockCategory][animalID]
        if currentTime - lockInfo.timestamp < locks.atomicTimeout then
            return false, "Atomic operation already in progress: " .. lockInfo.operationType .. " for animal " .. animalID
        else
            locks[lockCategory][animalID] = nil
        end
    end
    
    locks[lockCategory][animalID] = {
        timestamp = currentTime,
        operationType = operationType
    }
    
    local success, result = pcall(func)
    
    locks[lockCategory][animalID] = nil
    
    if currentTime - locks.lastAtomicCleanup > 30000 then
        AE_OperationGuards.cleanupAtomicLocks()
        locks.lastAtomicCleanup = currentTime
    end
    
    if success then
        return true, result
    else
        return false, "Atomic operation failed: " .. tostring(result)
    end
end

function AE_OperationGuards.cleanupAtomicLocks()
    local currentTime = getSafeTime()
    local locks = _G.AE_OperationLocks
    local timeout = locks.atomicTimeout
    
    for lockType, lockData in pairs(locks) do
        if type(lockData) == "table" and lockType ~= "lastAtomicCleanup" and lockType ~= "atomicTimeout" then
            local staleEntries = {}
            for animalID, lockInfo in pairs(lockData) do
                if type(lockInfo) == "table" and lockInfo.timestamp and (currentTime - lockInfo.timestamp > timeout) then
                    table.insert(staleEntries, animalID)
                end
            end
            for _, animalID in ipairs(staleEntries) do
                lockData[animalID] = nil
            end
        end
    end
end

function AE_OperationGuards.isAtomicOperationLocked(animalID, operationType)
    local locks = _G.AE_OperationLocks
    local lockCategory = operationType == "taming" and "tamingOperations" or "snapshotOperations"
    
    if not locks[lockCategory][animalID] then return false end
    
    local currentTime = getSafeTime()
    local lockInfo = locks[lockCategory][animalID]
    
    if lockInfo and lockInfo.timestamp and (currentTime - lockInfo.timestamp < locks.atomicTimeout) then
        return true
    end
    
    return false
end

function AE_OperationGuards.clearAllGuards()
    _G.AE_OperationGuards = {
        validatingAnimal = {},
        restoringSnapshot = {},
        makingTamed = {},
        lastCleanup = getSafeTime(),
        timeout = 30000
    }
    
    _G.AE_OperationLocks = {
        snapshotOperations = {},
        tamingOperations = {},
        atomicTimeout = 10000,
        lastAtomicCleanup = getSafeTime()
    }
end

_G.AE_OperationGuards = _G.AE_OperationGuards

return AE_OperationGuards