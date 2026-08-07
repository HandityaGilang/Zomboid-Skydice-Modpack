local TABAS_BathRadialUtils = {}

local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")

function TABAS_BathRadialUtils.canOpen(playerObj)
    if isGamePaused() then return false end
    if not playerObj or playerObj:isDead() then return false end
    if playerObj:getVehicle() then return false end
    if not TABAS_BathingUtils.isTakingBath(playerObj) then return false end
    return TABAS_TakeBathSession:get(playerObj) ~= nil
end

function TABAS_BathRadialUtils.getSession(playerObj)
    if not TABAS_BathRadialUtils.canOpen(playerObj) then
        return nil
    end
    return TABAS_TakeBathSession:get(playerObj)
end

function TABAS_BathRadialUtils.getCurrentAction(playerObj)
    local queue = playerObj and ISTimedActionQueue.getTimedActionQueue(playerObj) or nil
    return queue and queue.queue and queue.queue[1] or nil
end

function TABAS_BathRadialUtils.getQueuedBathStanceTarget(playerObj, fallback)
    local queue = playerObj and ISTimedActionQueue.getTimedActionQueue(playerObj) or nil
    queue = queue and queue.queue or nil
    if not queue then return fallback end

    local stance = fallback
    for i = 1, #queue do
        local action = queue[i]
        if action and action.Type == "TABAS_TakeBathStanceChange" then
            stance = action.stanceTo or stance
        end
    end
    return stance
end

function TABAS_BathRadialUtils.prepareAction(playerObj, session, clearQueue)
    if not playerObj or not session or session.isFinished then
        return false
    end

    local curAction = TABAS_BathRadialUtils.getCurrentAction(playerObj)
    if curAction and curAction.Type == "TABAS_TakeBathOut" then
        return false
    end

    session.isAutoMode = false
    session.isStopping = false
    session.curStance = playerObj:getVariableString("TABAS_BathStance")

    if clearQueue ~= false and curAction then
        ISTimedActionQueue.clear(playerObj)
    end

    return TABAS_BathingUtils.isTakingBath(playerObj)
end

function TABAS_BathRadialUtils.setInputActive(playerNum, active)
    if setPlayerMovementActive then
        setPlayerMovementActive(playerNum, active)
        return
    end
    if setPlayerButtonsActive then
        setPlayerButtonsActive(playerNum, active)
    end
end

return TABAS_BathRadialUtils
