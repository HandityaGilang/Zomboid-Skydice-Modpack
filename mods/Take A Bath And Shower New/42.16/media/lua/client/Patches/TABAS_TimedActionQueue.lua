local TABAS_TimedActionQueue = {}

local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")

local function getQueuedBathStanceTarget(character, fallback)
    local queue = ISTimedActionQueue.getTimedActionQueue(character)
    queue = queue and queue.queue or nil
    if not queue then return fallback end

    local stance = fallback
    for i = 1, #queue do
        local queuedAction = queue[i]
        if queuedAction and queuedAction.Type == "TABAS_TakeBathStanceChange" then
            stance = queuedAction.stanceTo or stance
        end
    end
    return stance
end

function TABAS_TimedActionQueue.apply()
    if TABAS_TimedActionQueue._applied then return end
    TABAS_TimedActionQueue._applied = true

    local old_ISTimedActionQueue_add = ISTimedActionQueue.add

    -- Any actions not allowed during bathing will be skipped.
    function ISTimedActionQueue.add(action)
        if action and action.character and TABAS_BathingUtils.isTakingBath(action.character) then
            local bathSession = TABAS_TakeBathSession:get(action.character)
            if bathSession then
                if not TABAS_BathingUtils.isAllowedAction(action) then
                    if TABAS_BathingUtils.isDebugAllowedAllAction() then
                        TABAS_BathingUtils.noise("Debug Allowed Action", tostring(action.Type))
                    else
                        bathSession.pendingNotAllowedSay = true
                        TABAS_BathingUtils.noise("Skipped Action", tostring(action.Type))
                        return
                    end
                end
                
                if action.Type ~= "TABAS_TakeBathStanceChange" then
                    local effectiveStance = getQueuedBathStanceTarget(action.character, action.character:getVariableString("TABAS_BathStance"))
                    if effectiveStance ~= "Idle" then
                        local queue = ISTimedActionQueue.getTimedActionQueue(action.character)
                        local preAction = TABAS_TakeBathStanceChange:new(bathSession.character, bathSession, "Idle", effectiveStance, 1.6)
                        queue:addToQueue(preAction)
                    end
                end
            end
        end
        return old_ISTimedActionQueue_add(action)
    end
end

return TABAS_TimedActionQueue
