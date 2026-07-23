AE_PickupDropEdgeCaseHandler = {}

AE_PickupDropEdgeCaseHandler.Config = {
    maxConcurrentPickups = 10,
    rapidPickupThresholdMs = 1000,
    duplicatePreservationTimeoutMs = 5000,
    networkFailureRetryAttempts = 3,
    throttling = {
        enabled = true,
        maxEventsPerMinute = 30,
        throttleWindowMs = 60000,
        throttleCooldownMs = 10000
    }
}

AE_PickupDropEdgeCaseHandler.ThrottlingData = {
    eventCounts = {},
    throttledUntil = {}
}

AE_PickupDropEdgeCaseHandler.RapidPickupTracking = {}
AE_PickupDropEdgeCaseHandler.NetworkFailures = {}
AE_PickupDropEdgeCaseHandler.DuplicatePreventions = {}

function AE_PickupDropEdgeCaseHandler.checkThrottling(playerID)
    if not AE_PickupDropEdgeCaseHandler.Config.throttling.enabled then return true end
    if not playerID then return false end
    
    local currentTime = getTimestampMs()
    
    if AE_PickupDropEdgeCaseHandler.ThrottlingData.throttledUntil[playerID] then
        if currentTime < AE_PickupDropEdgeCaseHandler.ThrottlingData.throttledUntil[playerID] then
            return false
        else
            AE_PickupDropEdgeCaseHandler.ThrottlingData.throttledUntil[playerID] = nil
        end
    end
    
    local windowStart = currentTime - AE_PickupDropEdgeCaseHandler.Config.throttling.throttleWindowMs
    local playerEvents = AE_PickupDropEdgeCaseHandler.ThrottlingData.eventCounts[playerID] or {}
    
    local recentEvents = {}
    for _, eventTime in ipairs(playerEvents) do
        if eventTime > windowStart then
            table.insert(recentEvents, eventTime)
        end
    end
    
    AE_PickupDropEdgeCaseHandler.ThrottlingData.eventCounts[playerID] = recentEvents
    
    if #recentEvents >= AE_PickupDropEdgeCaseHandler.Config.throttling.maxEventsPerMinute then
        AE_PickupDropEdgeCaseHandler.ThrottlingData.throttledUntil[playerID] = 
            currentTime + AE_PickupDropEdgeCaseHandler.Config.throttling.throttleCooldownMs
        return false
    end
    
    table.insert(AE_PickupDropEdgeCaseHandler.ThrottlingData.eventCounts[playerID], currentTime)
    return true
end

function AE_PickupDropEdgeCaseHandler.handleRapidPickupDrop(animal, player)
    if not animal or not player then return false end
    
    local animalID = tostring(animal:getOnlineID())
    local playerID = player:getOnlineID()
    local currentTime = getTimestampMs()
    
    if not AE_PickupDropEdgeCaseHandler.checkThrottling(playerID) then
        return false
    end
    
    local trackingKey = animalID .. "_" .. playerID
    local lastPickup = AE_PickupDropEdgeCaseHandler.RapidPickupTracking[trackingKey]
    
    if lastPickup and (currentTime - lastPickup) < AE_PickupDropEdgeCaseHandler.Config.rapidPickupThresholdMs then
        return false
    end
    
    AE_PickupDropEdgeCaseHandler.RapidPickupTracking[trackingKey] = currentTime
    return true
end

function AE_PickupDropEdgeCaseHandler.handleMultipleAnimals(animals, player)
    if not animals or not player then return {} end
    
    local processedAnimals = {}
    local maxProcessing = AE_PickupDropEdgeCaseHandler.Config.maxConcurrentPickups
    local processed = 0
    
    for _, animal in ipairs(animals) do
        if processed >= maxProcessing then
            break
        end
        
        if AE_PickupDropDetector and AE_PickupDropDetector.onAnimalPickup then
            local success = pcall(function()
                AE_PickupDropDetector.onAnimalPickup(animal, player)
            end)
            
            if success then
                table.insert(processedAnimals, {
                    animal = animal,
                    animalID = tostring(animal:getOnlineID()),
                    processed = true,
                    timestamp = getTimestampMs()
                })
                processed = processed + 1
            end
        end
    end
    
    return processedAnimals
end

function AE_PickupDropEdgeCaseHandler.handleDuplicatePreservation(animal, preservationData)
    if not animal or not preservationData then return false end
    
    local animalID = preservationData.stableID or tostring(animal:getOnlineID())
    local currentTime = getTimestampMs()
    
    local existingPrevention = AE_PickupDropEdgeCaseHandler.DuplicatePreventions[animalID]
    if existingPrevention then
        if (currentTime - existingPrevention.timestamp) < AE_PickupDropEdgeCaseHandler.Config.duplicatePreservationTimeoutMs then
            return false
        end
    end
    
    AE_PickupDropEdgeCaseHandler.DuplicatePreventions[animalID] = {
        preservationData = preservationData,
        timestamp = currentTime,
        correlationID = preservationData.correlationID
    }
    
    return true
end

function AE_PickupDropEdgeCaseHandler.handleNetworkFailure(animal, preservationData, attemptNumber)
    if not animal or not preservationData then return false end
    
    local animalID = preservationData.stableID or tostring(animal:getOnlineID())
    local failureKey = animalID .. "_network"
    
    if attemptNumber > AE_PickupDropEdgeCaseHandler.Config.networkFailureRetryAttempts then
        return false
    end
    
    AE_PickupDropEdgeCaseHandler.NetworkFailures[failureKey] = {
        attempts = attemptNumber,
        preservationData = preservationData,
        timestamp = getTimestampMs(),
        lastAttempt = getTimestampMs()
    }
    
    local retrySuccess = pcall(function()
        if not AE_EnvironmentDetector or not AE_EnvironmentDetector.isMultiplayer() then
            animal:transmitModData()
            return true
        else
            if not isClient() then
                animal:transmitModData()
            
            local retryNotification = {
                action = "animalDataRetry",
                animalID = animalID,
                attemptNumber = attemptNumber,
                preservationData = preservationData,
                timestamp = getTimestampMs()
            }
            sendServerCommand("AE_PickupDropNotification", "RetryRestore", retryNotification)
            return true
            end
        end
        return false
    end)
    
    if retrySuccess then
        AE_PickupDropEdgeCaseHandler.NetworkFailures[failureKey] = nil
        return true
    end
    
    return false
end

function AE_PickupDropEdgeCaseHandler.handleCorruptedPreservation(animal, preservationData)
    if not animal then return false end
    
    if not preservationData or not preservationData.animalType then
        return false
    end
    
    local reconstructedData = {
        animalType = animal:getAnimalType() or preservationData.animalType,
        correlationID = "corrupted_" .. getTimestampMs(),
        pickupTime = getTimestampMs(),
        playerID = 0,
        tameness = 0,
        isTamed = false,
        ownerID = nil
    }
    
    local nearbyPlayers = animal:getCurrentSquare():getWorldObjects()
    for i = 0, nearbyPlayers:size() - 1 do
        local obj = nearbyPlayers:get(i)
        if instanceof(obj, "IsoPlayer") then
            reconstructedData.playerID = obj:getOnlineID()
            break
        end
    end
    
    if AE_DataService then
        local success, result = pcall(function()
            reconstructedData.tameness = AE_DataService.getTameness and AE_DataService.getTameness(animal) or 0
            reconstructedData.isTamed = AE_DataService.isTamed and AE_DataService.isTamed(animal) or false
            reconstructedData.ownerID = AE_DataService.getOwner and AE_DataService.getOwner(animal)
            return true
        end)
        
        if success then
            return reconstructedData
        end
    end
    
    return reconstructedData
end


function AE_PickupDropEdgeCaseHandler.cleanup()
    local currentTime = getTimestampMs()
    local cleanupThreshold = 300000
    
    local cleanupKeys = {}
    
    for key, data in pairs(AE_PickupDropEdgeCaseHandler.RapidPickupTracking) do
        if currentTime - data > cleanupThreshold then
            table.insert(cleanupKeys, key)
        end
    end
    
    for _, key in ipairs(cleanupKeys) do
        AE_PickupDropEdgeCaseHandler.RapidPickupTracking[key] = nil
    end
    
    cleanupKeys = {}
    
    for key, data in pairs(AE_PickupDropEdgeCaseHandler.DuplicatePreventions) do
        if currentTime - data.timestamp > cleanupThreshold then
            table.insert(cleanupKeys, key)
        end
    end
    
    for _, key in ipairs(cleanupKeys) do
        AE_PickupDropEdgeCaseHandler.DuplicatePreventions[key] = nil
    end
    
    cleanupKeys = {}
    
    for key, data in pairs(AE_PickupDropEdgeCaseHandler.NetworkFailures) do
        if currentTime - data.timestamp > cleanupThreshold then
            table.insert(cleanupKeys, key)
        end
    end
    
    for _, key in ipairs(cleanupKeys) do
        AE_PickupDropEdgeCaseHandler.NetworkFailures[key] = nil
    end
end

Events.OnTick.Add(function()
    Events.OnTick.Remove(AE_PickupDropEdgeCaseHandler.cleanup)
    AE_PickupDropEdgeCaseHandler.cleanup()
end)

return AE_PickupDropEdgeCaseHandler