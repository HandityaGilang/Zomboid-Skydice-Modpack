AE_TimedActionDetector = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

AE_TimedActionDetector.isInitialized = false
AE_TimedActionDetector.trackedPlayers = {}
AE_TimedActionDetector.animalProximityCache = {}

AE_TimedActionDetector.Config = {
    scanInterval = 1000,
    proximityRadius = 3,
    actionStateCacheTime = 4000,
    maxProximityChecks = 50
}

function AE_TimedActionDetector.initialize()
    if AE_TimedActionDetector.isInitialized then return end
    
    AE_TimedActionDetector.isInitialized = true
    
    Events.OnPlayerUpdate.Add(AE_TimedActionDetector.onPlayerUpdate)
    Events.OnGameStart.Add(AE_TimedActionDetector.onGameStart)
end

function AE_TimedActionDetector.onGameStart()
    AE_TimedActionDetector.trackedPlayers = {}
    AE_TimedActionDetector.animalProximityCache = {}
end

function AE_TimedActionDetector.onPlayerUpdate(player)
    if not player or not AE_TimedActionDetector.shouldScanPlayer(player) then
        return
    end
    
    local currentTime = getTimestampMs()
    local playerID = player:getOnlineID()
    
    if not AE_TimedActionDetector.trackedPlayers[playerID] then
        AE_TimedActionDetector.trackedPlayers[playerID] = {
            lastScan = 0,
            lastActionCount = 0,
            lastActionName = nil,
            lastProximityCheck = 0
        }
    end
    
    local tracker = AE_TimedActionDetector.trackedPlayers[playerID]
    
    if currentTime - tracker.lastScan >= AE_TimedActionDetector.Config.scanInterval then
        AE_TimedActionDetector.scanPlayerTimedActions(player, tracker)
        tracker.lastScan = currentTime
    end
end

function AE_TimedActionDetector.shouldScanPlayer(player)
    if not player:hasTimedActions() then
        return false
    end
    
    local currentTime = getTimestampMs()
    local playerID = player:getOnlineID()
    
    local tracker = AE_TimedActionDetector.trackedPlayers[playerID]
    if tracker and currentTime - tracker.lastProximityCheck < AE_TimedActionDetector.Config.actionStateCacheTime then
        return AE_TimedActionDetector.animalProximityCache[playerID] or false
    end
    
    local hasNearbyAnimals = AE_TimedActionDetector.checkAnimalsInProximity(player)
    AE_TimedActionDetector.animalProximityCache[playerID] = hasNearbyAnimals
    
    if tracker then
        tracker.lastProximityCheck = currentTime
    end
    
    return hasNearbyAnimals
end

function AE_TimedActionDetector.checkAnimalsInProximity(player)
    local playerX = player:getX()
    local playerY = player:getY()
    local playerZ = player:getZ()
    local radius = AE_TimedActionDetector.Config.proximityRadius
    
    local checkCount = 0
    local maxChecks = AE_TimedActionDetector.Config.maxProximityChecks
    
    for x = math.floor(playerX) - radius, math.floor(playerX) + radius do
        for y = math.floor(playerY) - radius, math.floor(playerY) + radius do
            if checkCount >= maxChecks then
                return false
            end
            
            local square = getCell():getGridSquare(x, y, playerZ)
            if square then
                local movingObjects = square:getMovingObjects()
                for i = 0, movingObjects:size() - 1 do
                    local obj = movingObjects:get(i)
                    -- Defensive method existence check for isAnimal
                    if obj and obj.isAnimal and obj:isAnimal() then
                        return true
                    end
                    
                    checkCount = checkCount + 1
                    if checkCount >= maxChecks then
                        return false
                    end
                end
            end
        end
    end
    
    return false
end

function AE_TimedActionDetector.scanPlayerTimedActions(player, tracker)
    local actionStack = player:getCharacterActions()
    if actionStack:size() == 0 then return end
    
    local currentActionCount = actionStack:size()
    local currentActionName = player:getActionStateName()
    
    if currentActionCount ~= tracker.lastActionCount or 
       currentActionName ~= tracker.lastActionName then
        
        AE_TimedActionDetector.processActionChanges(player, actionStack, currentActionName)
        
        tracker.lastActionCount = currentActionCount
        tracker.lastActionName = currentActionName
    end
end

function AE_TimedActionDetector.processActionChanges(player, actionStack, currentActionName)
    local detectedActions = AE_TimedActionDetector.identifyAnimalActions(actionStack, currentActionName)
    
    if detectedActions then
        AE_TimedActionDetector.reportTimedActionToServer(player, detectedActions)
    end
end

function AE_TimedActionDetector.identifyAnimalActions(actionStack, currentActionName)
    local animalActionPatterns = {
        "Pickup", "Drop", "Take", "Place", "Grab", "Release"
    }
    
    if currentActionName then
        for _, pattern in ipairs(animalActionPatterns) do
            if string.find(string.lower(currentActionName), string.lower(pattern)) then
                return {
                    type = "current_action",
                    actionName = currentActionName,
                    detectionMethod = "action_state_name"
                }
            end
        end
    end
    
    local success, result = pcall(function()
        for i = 0, actionStack:size() - 1 do
            local action = nil
            
            if actionStack.elementAt then
                action = actionStack:elementAt(i)
            elseif actionStack.get then
                action = actionStack:get(i)
            end
            
            if action then
                local actionClassName = tostring(action)  -- Safe fallback
                
                -- BUGFIX: Use Project Zomboid compatible property access pattern
                -- getSimpleName() method does not exist in PZ Lua/Java context
                local success, result = pcall(function()
                    if action.class and action.class.name then
                        return action.class.name
                    elseif action.getClass then
                        local cls = action:getClass()
                        return tostring(cls)  -- Convert Java class to string
                    else
                        return tostring(action)  -- Final fallback
                    end
                end)
                
                if success and result then
                    actionClassName = result
                end
                
                for _, pattern in ipairs(animalActionPatterns) do
                    if string.find(string.lower(actionClassName), string.lower(pattern)) then
                        return {
                            type = "queued_action",
                            actionName = actionClassName,
                            detectionMethod = "action_queue_scan",
                            queuePosition = i
                        }
                    end
                end
            end
        end
        return nil
    end)
    
    if success and result then
        return result
    end
    
    return nil
end

function AE_TimedActionDetector.reportTimedActionToServer(player, detectedActions)
    local animalData = AE_TimedActionDetector.gatherNearbyAnimalData(player)
    
    sendServerCommand("AE_PickupDropDetection", "TimedActionDetected", {
        playerID = player:getOnlineID(),
        playerNum = player:getPlayerNum(),
        playerUsername = player:getUsername(),
        actionType = detectedActions.actionName,
        detectionMethod = detectedActions.detectionMethod,
        queuePosition = detectedActions.queuePosition,
        animalData = animalData,
        animalCount = animalData and #animalData or 0,
        timestamp = getTimestampMs(),
        playerPosition = {
            x = player:getX(),
            y = player:getY(),
            z = player:getZ()
        }
    })
end

function AE_TimedActionDetector.gatherNearbyAnimalData(player)
    local nearbyAnimals = {}
    local playerX = player:getX()
    local playerY = player:getY()
    local playerZ = player:getZ()
    local radius = AE_TimedActionDetector.Config.proximityRadius
    
    for x = math.floor(playerX) - radius, math.floor(playerX) + radius do
        for y = math.floor(playerY) - radius, math.floor(playerY) + radius do
            local square = getCell():getGridSquare(x, y, playerZ)
            if square then
                local movingObjects = square:getMovingObjects()
                for i = 0, movingObjects:size() - 1 do
                    local obj = movingObjects:get(i)
                    -- Defensive method existence check for isAnimal
                    if obj and obj.isAnimal and obj:isAnimal() then
                        -- Additional defensive checks for getOnlineID, getX, getY
                        local animalData = {
                            onlineID = obj.getOnlineID and obj:getOnlineID() or "unknown",
                            position = {
                                x = obj.getX and obj:getX() or 0,
                                y = obj.getY and obj:getY() or 0,
                                z = obj.getZ and obj:getZ() or 0
                            },
                            heldBy = obj.heldBy and obj.heldBy.getOnlineID and obj.heldBy:getOnlineID() or nil,
                            isCurrentlyHeld = obj.heldBy ~= nil
                        }
                        table.insert(nearbyAnimals, animalData)
                    end
                end
            end
        end
    end
    
    return nearbyAnimals
end

function AE_TimedActionDetector.cleanup()
    local currentTime = getTimestampMs()
    local timeoutThreshold = currentTime - (AE_TimedActionDetector.Config.actionStateCacheTime * 2)
    
    for playerID, tracker in pairs(AE_TimedActionDetector.trackedPlayers) do
        if tracker.lastScan < timeoutThreshold then
            AE_TimedActionDetector.trackedPlayers[playerID] = nil
            AE_TimedActionDetector.animalProximityCache[playerID] = nil
        end
    end
end

Events.OnGameStart.Add(AE_TimedActionDetector.initialize)

return AE_TimedActionDetector