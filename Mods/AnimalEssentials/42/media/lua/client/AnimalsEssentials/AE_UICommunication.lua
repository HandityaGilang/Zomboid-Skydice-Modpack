-- AE_UICommunication.lua
-- CLIENT-SIDE inter-mod communication for UI systems
-- SESSION 4C: Client-side event-driven UI communication

local AE_UICommunication = {}

AE_UICommunication.pendingRequests = {}
AE_UICommunication.nextRequestId = 1
AE_UICommunication.requestTimeout = 3000
AE_UICommunication.uiUpdateCallbacks = {}

-- Initialize client-side UI communication
AE_UICommunication.initialize = function()
    AE_UICommunication.registerResponseHandlers()
    AE_UICommunication.registerUIUpdateHandlers()
end

-- Register response handlers for data requests
AE_UICommunication.registerResponseHandlers = function()
    if Events.AE_UIDataResponse then
        Events.AE_UIDataResponse.Add(AE_UICommunication.handleDataResponse)
    end
    
    if Events.AE_UICommandResponse then
        Events.AE_UICommandResponse.Add(AE_UICommunication.handleCommandResponse)
    end
end

-- Register real-time update handlers for UI
AE_UICommunication.registerUIUpdateHandlers = function()
    if Events.AE_TamenessChanged then
        Events.AE_TamenessChanged.Add(AE_UICommunication.handleTamenessUpdate)
    end
    
    if Events.AE_HungerChanged then
        Events.AE_HungerChanged.Add(AE_UICommunication.handleHungerUpdate)
    end
    
    if Events.AE_ThirstChanged then
        Events.AE_ThirstChanged.Add(AE_UICommunication.handleThirstUpdate)
    end
    
    if Events.AE_OwnerChanged then
        Events.AE_OwnerChanged.Add(AE_UICommunication.handleOwnerUpdate)
    end
end

-- Request animal data for UI display
AE_UICommunication.requestAnimalData = function(animal, dataTypes, callback)
    if not animal or not callback then
        return false
    end
    
    local requestId = AE_UICommunication.nextRequestId
    AE_UICommunication.nextRequestId = AE_UICommunication.nextRequestId + 1
    
    local requestData = {
        id = requestId,
        animalID = animal.getID and animal:getID() or "unknown",
        dataTypes = dataTypes or {"tameness", "hunger", "thirst", "owner"},
        timestamp = getTimestamp()
    }
    
    AE_UICommunication.pendingRequests[requestId] = {
        callback = callback,
        timestamp = getTimestamp(),
        animal = animal
    }
    
    AE_UICommunication.setTimeout(requestId)
    
    if Events.AE_UIDataRequest then
        Events.AE_UIDataRequest.Trigger(requestData)
        return true
    end
    
    return false
end

-- Send command via UI communication
AE_UICommunication.sendCommand = function(animal, command, parameters, callback)
    if not animal or not command then
        return false
    end
    
    local requestId = AE_UICommunication.nextRequestId
    AE_UICommunication.nextRequestId = AE_UICommunication.nextRequestId + 1
    
    local commandData = {
        id = requestId,
        animalID = animal.getID and animal:getID() or "unknown",
        command = command,
        parameters = parameters or {},
        timestamp = getTimestamp()
    }
    
    if callback then
        AE_UICommunication.pendingRequests[requestId] = {
            callback = callback,
            timestamp = getTimestamp(),
            type = "command"
        }
        AE_UICommunication.setTimeout(requestId)
    end
    
    if Events.AE_UICommandRequest then
        Events.AE_UICommandRequest.Trigger(commandData)
        return true
    end
    
    return false
end

-- Subscribe UI component to real-time updates
AE_UICommunication.subscribeToUpdates = function(animalID, updateTypes, callback)
    if not animalID or not callback then
        return false
    end
    
    local subscriptionKey = animalID .. "_" .. table.concat(updateTypes or {}, "_")
    AE_UICommunication.uiUpdateCallbacks[subscriptionKey] = {
        animalID = animalID,
        updateTypes = updateTypes,
        callback = callback
    }
    
    return subscriptionKey
end

-- Unsubscribe UI component from updates
AE_UICommunication.unsubscribeFromUpdates = function(subscriptionKey)
    if subscriptionKey and AE_UICommunication.uiUpdateCallbacks[subscriptionKey] then
        AE_UICommunication.uiUpdateCallbacks[subscriptionKey] = nil
        return true
    end
    return false
end

-- Handle timeout for requests
AE_UICommunication.setTimeout = function(requestId)
    local function checkTimeoutOnTick()
        Events.OnTick.Remove(checkTimeoutOnTick)
        local success = pcall(function()
            AE_UICommunication.checkTimeout(requestId)
        end)
        if not success then
            print("[AE_UICommunication] Timeout check failed for request: " .. tostring(requestId))
        end
    end
    
    local addSuccess = pcall(function()
        Events.OnTick.Add(checkTimeoutOnTick)
    end)
    
    if not addSuccess then
        print("[AE_UICommunication] Failed to schedule timeout check for request: " .. tostring(requestId))
    end
end

AE_UICommunication.checkTimeout = function(requestId)
    local request = AE_UICommunication.pendingRequests[requestId]
    if request then
        local currentTime = getTimestamp()
        if currentTime - request.timestamp > AE_UICommunication.requestTimeout then
            if request.callback then
                request.callback({
                    success = false,
                    error = "Request timeout",
                    requestId = requestId
                })
            end
            AE_UICommunication.pendingRequests[requestId] = nil
        end
    end
end

-- Handle data response from FrameworkData
AE_UICommunication.handleDataResponse = function(responseData)
    local request = AE_UICommunication.pendingRequests[responseData.requestId]
    if request and request.callback then
        request.callback({
            success = true,
            data = responseData.data,
            animalID = responseData.animalID
        })
        AE_UICommunication.pendingRequests[responseData.requestId] = nil
    end
end

-- Handle command response from FrameworkData
AE_UICommunication.handleCommandResponse = function(responseData)
    local request = AE_UICommunication.pendingRequests[responseData.requestId]
    if request and request.callback then
        request.callback({
            success = responseData.success,
            result = responseData.result,
            message = responseData.message
        })
        AE_UICommunication.pendingRequests[responseData.requestId] = nil
    end
end

-- Handle real-time tameness updates
AE_UICommunication.handleTamenessUpdate = function(updateData)
    for key, subscription in pairs(AE_UICommunication.uiUpdateCallbacks) do
        if subscription.animalID == updateData.animalID then
            if not subscription.updateTypes or table.contains(subscription.updateTypes, "tameness") then
                subscription.callback({
                    type = "tameness",
                    animalID = updateData.animalID,
                    newValue = updateData.newTameness,
                    oldValue = updateData.oldTameness
                })
            end
        end
    end
end

-- Handle real-time hunger updates  
AE_UICommunication.handleHungerUpdate = function(updateData)
    for key, subscription in pairs(AE_UICommunication.uiUpdateCallbacks) do
        if subscription.animalID == updateData.animalID then
            if not subscription.updateTypes or table.contains(subscription.updateTypes, "hunger") then
                subscription.callback({
                    type = "hunger",
                    animalID = updateData.animalID,
                    newValue = updateData.newHunger,
                    oldValue = updateData.oldHunger
                })
            end
        end
    end
end

-- Handle real-time thirst updates
AE_UICommunication.handleThirstUpdate = function(updateData)
    for key, subscription in pairs(AE_UICommunication.uiUpdateCallbacks) do
        if subscription.animalID == updateData.animalID then
            if not subscription.updateTypes or table.contains(subscription.updateTypes, "thirst") then
                subscription.callback({
                    type = "thirst",
                    animalID = updateData.animalID,
                    newValue = updateData.newThirst,
                    oldValue = updateData.oldThirst
                })
            end
        end
    end
end

-- Handle real-time owner updates
AE_UICommunication.handleOwnerUpdate = function(updateData)
    for key, subscription in pairs(AE_UICommunication.uiUpdateCallbacks) do
        if subscription.animalID == updateData.animalID then
            if not subscription.updateTypes or table.contains(subscription.updateTypes, "owner") then
                subscription.callback({
                    type = "owner",
                    animalID = updateData.animalID,
                    newValue = updateData.newOwner,
                    oldValue = updateData.oldOwner
                })
            end
        end
    end
end

-- Convenience functions for common UI operations
AE_UICommunication.requestAnimalStatus = function(animal, callback)
    return AE_UICommunication.requestAnimalData(animal, {"tameness", "hunger", "thirst", "owner"}, callback)
end

AE_UICommunication.requestAnimalCommands = function(animal, callback)
    return AE_UICommunication.requestAnimalData(animal, {"availableCommands", "currentCommand"}, callback)
end

AE_UICommunication.requestAnimalEquipment = function(animal, callback)
    return AE_UICommunication.requestAnimalData(animal, {"equipment", "inventoryItems"}, callback)
end

local initSuccess = pcall(function()
    Events.OnGameStart.Add(AE_UICommunication.initialize)
end)
if not initSuccess then
    print("[AE_UICommunication] Failed to register OnGameStart event")
end

return AE_UICommunication