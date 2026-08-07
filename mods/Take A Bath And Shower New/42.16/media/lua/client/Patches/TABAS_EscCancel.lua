local TABAS_EscCancel = {}

function TABAS_EscCancel.apply()
    if TABAS_EscCancel._applied then return end
    TABAS_EscCancel._applied = true

    local old_isPlayerDoingActionThatCanBeCancelled = isPlayerDoingActionThatCanBeCancelled

    function isPlayerDoingActionThatCanBeCancelled(player)
        if player then
            local queue = ISTimedActionQueue.getTimedActionQueue(player)
            local current = queue and queue.current
            if current and current.Type == "TABAS_TakeShower" then
                if player:getVariableBoolean("TABAS_ShowerStarted") then
                    return false
                end
            end
        end
        return old_isPlayerDoingActionThatCanBeCancelled(player)
    end
end

return TABAS_EscCancel
