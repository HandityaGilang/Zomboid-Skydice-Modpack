AE_TimedActionServerHandler = {}

local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")
local AE_PickupDropDetector = require("AnimalsEssentials/PickupDrop/AE_PickupDropDetector")
local AE_PickupDropPerformanceMonitor = require("AnimalsEssentials/PickupDrop/AE_PickupDropPerformanceMonitor")

AE_TimedActionServerHandler.pendingActions = {}
AE_TimedActionServerHandler.actionHistory = {}

AE_TimedActionServerHandler.Config = {
    actionTimeoutMs = 30000,
    maxHistoryEntries = 500,
    cleanupInterval = 300000
}

function AE_TimedActionServerHandler.initialize()
    Events.OnClientCommand.Add(AE_TimedActionServerHandler.onClientCommand)
    -- PHASE 2 CONSOLIDATION: Timer moved to AE_DataCleanupCoordinator
    -- Events.EveryTenMinutes.Add(AE_TimedActionServerHandler.cleanup) -- Disabled - handled by coordinator
end

function AE_TimedActionServerHandler.onClientCommand(module, command, player, args)
    if module ~= "AE_PickupDropDetection" then return end
    
    if command == "TimedActionDetected" then
        AE_TimedActionServerHandler.processTimedActionDetection(player, args)
    end
end

function AE_TimedActionServerHandler.processTimedActionDetection(player, actionData)
    if not AE_TimedActionServerHandler.validateActionData(player, actionData) then
        AE_PickupDropPerformanceMonitor.recordError("invalid_action_data", "TimedAction data validation failed")
        return
    end
    
    local actionID = AE_TimedActionServerHandler.generateActionID(player, actionData)
    
    local processedAction = {
        actionID = actionID,
        playerID = actionData.playerID,
        playerUsername = actionData.playerUsername,
        actionType = actionData.actionType,
        detectionMethod = actionData.detectionMethod,
        timestamp = actionData.timestamp,
        serverProcessTime = getTimestampMs(),
        animalData = actionData.animalData,
        playerPosition = actionData.playerPosition,
        processed = false
    }
    
    AE_TimedActionServerHandler.pendingActions[actionID] = processedAction
    
    AE_TimedActionServerHandler.analyzeAnimalInteraction(player, processedAction)
    
    AE_TimedActionServerHandler.recordActionHistory(processedAction)
end

function AE_TimedActionServerHandler.validateActionData(player, actionData)
    if not player or not actionData then return false end
    
    if not actionData.playerID or not actionData.actionType or not actionData.timestamp then
        return false
    end
    
    if actionData.playerID ~= player:getOnlineID() then
        return false
    end
    
    local timeDiff = math.abs(getTimestampMs() - actionData.timestamp)
    if timeDiff > AE_TimedActionServerHandler.Config.actionTimeoutMs then
        return false
    end
    
    if not actionData.animalData or type(actionData.animalData) ~= "table" then
        return false
    end
    
    return true
end

function AE_TimedActionServerHandler.generateActionID(player, actionData)
    return string.format("TA_%s_%s_%s", 
        actionData.playerID,
        actionData.timestamp,
        tostring(math.random(1000, 9999))
    )
end

function AE_TimedActionServerHandler.analyzeAnimalInteraction(player, actionData)
    local actionType = string.lower(actionData.actionType)
    local animalData = actionData.animalData
    
    if AE_TimedActionServerHandler.isPickupAction(actionType) then
        AE_TimedActionServerHandler.handlePickupAction(player, actionData, animalData)
    elseif AE_TimedActionServerHandler.isDropAction(actionType) then
        AE_TimedActionServerHandler.handleDropAction(player, actionData, animalData)
    end
end

function AE_TimedActionServerHandler.isPickupAction(actionType)
    local pickupPatterns = {"pickup", "take", "grab", "carry", "lift"}
    for _, pattern in ipairs(pickupPatterns) do
        if string.find(actionType, pattern) then
            return true
        end
    end
    return false
end

function AE_TimedActionServerHandler.isDropAction(actionType)
    local dropPatterns = {"drop", "place", "release", "put", "set"}
    for _, pattern in ipairs(dropPatterns) do
        if string.find(actionType, pattern) then
            return true
        end
    end
    return false
end

function AE_TimedActionServerHandler.handlePickupAction(player, actionData, animalData)
    for _, animalInfo in ipairs(animalData) do
        if not animalInfo.isCurrentlyHeld then
            local animal = AE_TimedActionServerHandler.findAnimalByID(animalInfo.onlineID)
            if animal then
                local preservationData = AE_TimedActionServerHandler.createPreservationData(player, animal, actionData, "pickup")
                AE_PickupDropDetector.preserveAnimalData(animal, preservationData)
                
                AE_PickupDropPerformanceMonitor.recordTimedActionEvent("pickup_detected", {
                    animalID = animalInfo.onlineID,
                    actionID = actionData.actionID,
                    detectionMethod = actionData.detectionMethod
                })
            end
        end
    end
    
    actionData.processed = true
end

function AE_TimedActionServerHandler.handleDropAction(player, actionData, animalData)
    for _, animalInfo in ipairs(animalData) do
        if animalInfo.isCurrentlyHeld and animalInfo.heldBy == actionData.playerID then
            local animal = AE_TimedActionServerHandler.findAnimalByID(animalInfo.onlineID)
            if animal then
                AE_PickupDropDetector.scheduleDropDetection(animal, player, actionData.timestamp)
                
                AE_PickupDropPerformanceMonitor.recordTimedActionEvent("drop_detected", {
                    animalID = animalInfo.onlineID,
                    actionID = actionData.actionID,
                    detectionMethod = actionData.detectionMethod
                })
            end
        end
    end
    
    actionData.processed = true
end

function AE_TimedActionServerHandler.createPreservationData(player, animal, actionData, actionType)
    return {
        correlationID = actionData.actionID,
        originalAnimalID = animal:getOnlineID(),
        playerID = player:getPlayerNum(),
        playerUsername = player:getUsername(),
        playerOnlineID = player:getOnlineID(),
        actionType = actionType,
        detectionMethod = actionData.detectionMethod,
        pickupTime = actionData.timestamp,
        serverProcessTime = getTimestampMs(),
        animalPosition = {
            x = animal:getX(),
            y = animal:getY(),
            z = animal:getZ()
        }
    }
end

function AE_TimedActionServerHandler.findAnimalByID(animalID)
    if not animalID or animalID == 0 then return nil end
    
    local cell = getWorld():getCell()
    if not cell then return nil end
    
    local zombieList = cell:getZombieList()
    for i = 0, zombieList:size() - 1 do
        local character = zombieList:get(i)
        if character and character:isAnimal() and character:getOnlineID() == animalID then
            return character
        end
    end
    
    return nil
end

function AE_TimedActionServerHandler.recordActionHistory(actionData)
    table.insert(AE_TimedActionServerHandler.actionHistory, {
        actionID = actionData.actionID,
        playerID = actionData.playerID,
        actionType = actionData.actionType,
        timestamp = actionData.serverProcessTime,
        animalCount = actionData.animalData and #actionData.animalData or 0
    })
    
    while #AE_TimedActionServerHandler.actionHistory > AE_TimedActionServerHandler.Config.maxHistoryEntries do
        table.remove(AE_TimedActionServerHandler.actionHistory, 1)
    end
end

function AE_TimedActionServerHandler.cleanup()
    local currentTime = getTimestampMs()
    local timeoutThreshold = currentTime - AE_TimedActionServerHandler.Config.actionTimeoutMs
    
    for actionID, actionData in pairs(AE_TimedActionServerHandler.pendingActions) do
        if actionData.serverProcessTime < timeoutThreshold then
            AE_TimedActionServerHandler.pendingActions[actionID] = nil
        end
    end
    
    local oldHistoryThreshold = currentTime - (AE_TimedActionServerHandler.Config.cleanupInterval * 6)
    local filteredHistory = {}
    for _, historyEntry in ipairs(AE_TimedActionServerHandler.actionHistory) do
        if historyEntry.timestamp > oldHistoryThreshold then
            table.insert(filteredHistory, historyEntry)
        end
    end
    AE_TimedActionServerHandler.actionHistory = filteredHistory
end

function AE_TimedActionServerHandler.getActionStats()
    return {
        pendingActionsCount = 0,
        historyCount = #AE_TimedActionServerHandler.actionHistory,
        lastCleanup = getTimestampMs()
    }
end

Events.OnGameStart.Add(AE_TimedActionServerHandler.initialize)

return AE_TimedActionServerHandler