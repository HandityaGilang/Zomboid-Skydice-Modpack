local AE_CoreCommunication = {}

AE_CoreCommunication.pendingRequests = {}
AE_CoreCommunication.nextRequestId = 1
AE_CoreCommunication.requestTimeout = 5000

AE_CoreCommunication.initialize = function()
    AE_CoreCommunication.registerResponseHandlers()
end

AE_CoreCommunication.registerResponseHandlers = function()
    if Events.AE_TamenessDataResponse then
        Events.AE_TamenessDataResponse.Add(AE_CoreCommunication.handleTamenessResponse)
    end
    
    if Events.AE_OwnerDataResponse then
        Events.AE_OwnerDataResponse.Add(AE_CoreCommunication.handleOwnerResponse)
    end
    
    if Events.AE_BehaviorStateResponse then
        Events.AE_BehaviorStateResponse.Add(AE_CoreCommunication.handleBehaviorStateResponse)
    end
    
    if Events.AE_ConfigDataResponse then
        Events.AE_ConfigDataResponse.Add(AE_CoreCommunication.handleConfigResponse)
    end
    
    if Events.AE_CommandExecutionDataResponse then
        Events.AE_CommandExecutionDataResponse.Add(AE_CoreCommunication.handleCommandExecutionResponse)
    end
end

AE_CoreCommunication.requestData = function(dataType, animal, callback)
    if not animal or not callback then
        return false
    end
    
    local requestId = AE_CoreCommunication.nextRequestId
    AE_CoreCommunication.nextRequestId = AE_CoreCommunication.nextRequestId + 1
    
    local requestData = {
        id = requestId,
        animal = animal,
        animalID = animal:getID(),
        timestamp = getTimestamp()
    }
    
    AE_CoreCommunication.pendingRequests[requestId] = {
        callback = callback,
        dataType = dataType,
        timestamp = getTimestamp()
    }
    
    AE_CoreCommunication.setTimeout(requestId)
    
    local eventName = "AE_Request" .. dataType .. "Data"
    if Events[eventName] then
        Events[eventName].Trigger(requestData)
        return true
    end
    
    return false
end

AE_CoreCommunication.setTimeout = function(requestId)
    local function timeoutOnTick()
        Events.OnTick.Remove(timeoutOnTick)
        local success = pcall(function()
            AE_CoreCommunication.timeoutRequest(requestId)
        end)
        if not success then
            print("[AE_CoreCommunication] Timeout failed for request: " .. tostring(requestId))
        end
    end
    
    local addSuccess = pcall(function()
        Events.OnTick.Add(timeoutOnTick)
    end)
    
    if not addSuccess then
        print("[AE_CoreCommunication] Failed to schedule timeout for request: " .. tostring(requestId))
    end
end

AE_CoreCommunication.timeoutRequest = function(requestId)
    local request = AE_CoreCommunication.pendingRequests[requestId]
    if request then
        local currentTime = getTimestamp()
        if currentTime - request.timestamp > AE_CoreCommunication.requestTimeout then
            AE_CoreCommunication.pendingRequests[requestId] = nil
        end
    end
end

AE_CoreCommunication.handleTamenessResponse = function(responseData)
    local request = AE_CoreCommunication.pendingRequests[responseData.requestId]
    if request then
        request.callback({
            tameness = responseData.tameness,
            success = true
        })
        AE_CoreCommunication.pendingRequests[responseData.requestId] = nil
    end
end

AE_CoreCommunication.handleOwnerResponse = function(responseData)
    local request = AE_CoreCommunication.pendingRequests[responseData.requestId]
    if request then
        request.callback({
            owner = responseData.owner,
            success = true
        })
        AE_CoreCommunication.pendingRequests[responseData.requestId] = nil
    end
end

AE_CoreCommunication.handleBehaviorStateResponse = function(responseData)
    local request = AE_CoreCommunication.pendingRequests[responseData.requestId]
    if request then
        request.callback({
            behaviorState = responseData.behaviorState,
            success = true
        })
        AE_CoreCommunication.pendingRequests[responseData.requestId] = nil
    end
end

AE_CoreCommunication.requestTameness = function(animal, callback)
    return AE_CoreCommunication.requestData("Tameness", animal, callback)
end

AE_CoreCommunication.requestOwner = function(animal, callback)
    return AE_CoreCommunication.requestData("Owner", animal, callback)
end

AE_CoreCommunication.requestBehaviorState = function(animal, callback)
    return AE_CoreCommunication.requestData("BehaviorState", animal, callback)
end

AE_CoreCommunication.handleConfigResponse = function(responseData)
    local request = AE_CoreCommunication.pendingRequests[responseData.requestId]
    if request then
        request.callback({
            config = responseData.config,
            RegisteredAnimals = responseData.RegisteredAnimals,
            success = true
        })
        AE_CoreCommunication.pendingRequests[responseData.requestId] = nil
    end
end

AE_CoreCommunication.handleCommandExecutionResponse = function(responseData)
    local request = AE_CoreCommunication.pendingRequests[responseData.requestId]
    if request then
        request.callback({
            result = responseData.result,
            success = responseData.success,
            message = responseData.message
        })
        AE_CoreCommunication.pendingRequests[responseData.requestId] = nil
    end
end

AE_CoreCommunication.requestConfig = function(callback)
    return AE_CoreCommunication.requestData("Config", nil, callback)
end

AE_CoreCommunication.requestCommandExecution = function(animal, command, params, callback)
    local requestData = {
        animal = animal,
        command = command,
        parameters = params
    }
    return AE_CoreCommunication.requestData("CommandExecution", requestData, callback)
end

return AE_CoreCommunication