local TABAS_TimedActionQueue = {}

local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")

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
                    if bathSession.curStance ~= "Idle" then
                        local queue = ISTimedActionQueue.getTimedActionQueue(action.character)
                        local preAction = TABAS_TakeBathStanceChange:new(bathSession.character, "Idle", nil, 1.6)
                        queue:addToQueue(preAction)
                        bathSession.curStance = "Idle"
                    end
                end
            end
        end
        return old_ISTimedActionQueue_add(action)
    end
end

return TABAS_TimedActionQueue
