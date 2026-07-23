require "LifestyleCore/LSK_CommandRouter"
require "LifestyleCore/LSK_Metrics"

LSK_ActionAuthority = LSK_ActionAuthority or {}

local ALLOWED_ACTION_PREFIXES = {
    "LS",
    "PlayInstrument",
    "PlayDJ",
    "PlayerIsDancing",
    "CleanRoom",
    "Jukebox",
    "DiscoBall",
    "ToneDeaf",
    "Booing",
    "Praise",
    "Shoo",
}

local function allowedAction(actionName)
    if type(actionName) ~= "string" or string.len(actionName) > 64 then
        return false
    end
    for i = 1, #ALLOWED_ACTION_PREFIXES do
        if string.sub(actionName, 1, string.len(ALLOWED_ACTION_PREFIXES[i])) == ALLOWED_ACTION_PREFIXES[i] then
            return true
        end
    end
    return false
end

function LSK_ActionAuthority.begin(player, actionName, ttlMilliseconds, context)
    local nonce = LSK_CommandRouter.beginNonce(player, actionName, ttlMilliseconds, context)
    if nonce then
        LSK_Metrics.increment("action_begin")
    end
    return nonce
end

function LSK_ActionAuthority.registerClient(player, actionName, nonce, durationMilliseconds, context)
    if not player or not allowedAction(actionName) then
        return false, "action_not_allowed"
    end
    durationMilliseconds = tonumber(durationMilliseconds) or 30000
    durationMilliseconds = math.min(3600000, math.max(5000, durationMilliseconds))
    local registered = LSK_CommandRouter.registerNonce(
        player,
        actionName,
        nonce,
        durationMilliseconds + 30000,
        context
    )
    if not registered then
        return false, "invalid_action_session"
    end
    LSK_Metrics.increment("action_begin_client")
    return true
end

function LSK_ActionAuthority.validate(player, actionName, nonce)
    local valid, session = LSK_CommandRouter.validateNonce(player, actionName, nonce)
    if not valid then
        LSK_Metrics.increment("action_invalid")
        return false, nil
    end
    return true, session
end

function LSK_ActionAuthority.cancel(player, actionName)
    LSK_CommandRouter.cancelNonce(player, actionName)
    LSK_Metrics.increment("action_cancel")
end

function LSK_ActionAuthority.complete(player, actionName, nonce, transaction)
    local valid, context = LSK_CommandRouter.consumeNonce(player, actionName, nonce)
    if not valid then
        LSK_Metrics.increment("action_invalid")
        return false, "invalid_or_expired_nonce"
    end
    if type(transaction) ~= "function" then
        LSK_Metrics.increment("action_invalid")
        return false, "invalid_transaction"
    end
    local ok, result = pcall(transaction, player, context)
    if not ok then
        LSK_Metrics.increment("action_failed")
        print("[LSK Security] action transaction failed action=" .. tostring(actionName)
            .. " error=" .. tostring(result))
        return false, "transaction_failed"
    end
    LSK_Metrics.increment("action_complete")
    return true, result
end

function LSK_ActionAuthority.transaction(prepare, commit, rollback)
    if type(commit) ~= "function" then
        return false, "invalid_commit"
    end
    local state
    if prepare then
        local prepared, preparedState = pcall(prepare)
        if not prepared then
            return false, "prepare_failed"
        end
        state = preparedState
    end
    local committed, result = pcall(commit, state)
    if committed then
        return true, result
    end
    if type(rollback) == "function" then
        local rollbackOk, rollbackError = pcall(rollback, state)
        if not rollbackOk then
            print("[LSK Security] transaction rollback failed error=" .. tostring(rollbackError))
        end
    end
    return false, "commit_failed"
end

return LSK_ActionAuthority
