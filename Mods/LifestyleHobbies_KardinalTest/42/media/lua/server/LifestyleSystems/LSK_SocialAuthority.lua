require "LifestyleSystems/LSK_SystemDefinitions"

LifestyleSecure = LifestyleSecure or {}
local Social = {}
local Defs = LifestyleSecure.SystemDefinitions
local Limits = Defs.Social

Social.requests = {}
Social.cooldowns = {}

local function cooldownKey(fromKey, toKey, actionName)
    return fromKey .. ":" .. toKey .. ":" .. actionName
end

function Social.request(requester, target, actionName)
    actionName = Defs.identifier(actionName)
    local fromKey = Defs.playerKey(requester)
    local toKey = Defs.playerKey(target)
    if not actionName or not Limits.actions[actionName]
        or not fromKey or not toKey or fromKey == toKey then
        return false, "invalid_request"
    end
    Social.cleanup()
    if not Defs.inRange(requester, target, Limits.requestRadius) then
        return false, "too_far"
    end
    local cdKey = cooldownKey(fromKey, toKey, actionName)
    if (Social.cooldowns[cdKey] or 0) > Defs.now() then
        return false, "cooldown"
    end
    if Social.requests[toKey] then
        return false, "request_pending"
    end
    Social.requests[toKey] = {
        fromKey = fromKey,
        actionName = actionName,
        expiresAt = Defs.now() + Limits.requestTtlMs,
    }
    return true
end

function Social.respond(target, requester, actionName, accepted)
    local toKey = Defs.playerKey(target)
    local fromKey = Defs.playerKey(requester)
    local request = toKey and Social.requests[toKey] or nil
    if toKey then
        Social.requests[toKey] = nil
    end
    if not request or request.fromKey ~= fromKey or request.actionName ~= actionName
        or request.expiresAt < Defs.now() then
        return false, "no_request"
    end
    if accepted ~= true then
        return true, "declined"
    end
    if not Defs.inRange(requester, target, Limits.requestRadius) then
        return false, "too_far"
    end
    local expiresAt = Defs.now() + Limits.cooldownMs
    Social.cooldowns[cooldownKey(fromKey, toKey, actionName)] = expiresAt
    Social.cooldowns[cooldownKey(toKey, fromKey, actionName)] = expiresAt
    return true, {
        actionName = actionName,
        requesterKey = fromKey,
        targetKey = toKey,
    }
end

function Social.cleanupPlayer(player)
    local key = Defs.playerKey(player)
    if not key then
        return
    end
    Social.requests[key] = nil
    for targetKey, request in pairs(Social.requests) do
        if request.fromKey == key then
            Social.requests[targetKey] = nil
        end
    end
    for keyName in pairs(Social.cooldowns) do
        if string.find(keyName, key .. ":", 1, true) == 1
            or string.find(keyName, ":" .. key .. ":", 1, true) then
            Social.cooldowns[keyName] = nil
        end
    end
end

function Social.cleanup()
    local now = Defs.now()
    for targetKey, request in pairs(Social.requests) do
        if request.expiresAt < now or not Defs.findOnlinePlayer(targetKey)
            or not Defs.findOnlinePlayer(request.fromKey) then
            Social.requests[targetKey] = nil
        end
    end
    for key, expiresAt in pairs(Social.cooldowns) do
        if expiresAt < now then
            Social.cooldowns[key] = nil
        end
    end
end

return Social
