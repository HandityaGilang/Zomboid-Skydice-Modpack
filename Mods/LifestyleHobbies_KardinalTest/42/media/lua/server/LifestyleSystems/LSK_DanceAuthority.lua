require "LifestyleSystems/LSK_SystemDefinitions"

LifestyleSecure = LifestyleSecure or {}
local Dance = {}
local Defs = LifestyleSecure.SystemDefinitions
local Limits = Defs.Dance

Dance.requests = {}
Dance.partners = {}

local function clearPair(key)
    local partner = Dance.partners[key]
    Dance.partners[key] = nil
    if partner and Dance.partners[partner] == key then
        Dance.partners[partner] = nil
    end
end

function Dance.requestPartner(requester, target)
    local fromKey = Defs.playerKey(requester)
    local toKey = Defs.playerKey(target)
    if not fromKey or not toKey or fromKey == toKey then
        return false, "invalid_players"
    end
    Dance.cleanup()
    if Dance.partners[fromKey] or Dance.partners[toKey] then
        return false, "already_partnered"
    end
    if not Defs.inRange(requester, target, Limits.requestRadius) then
        return false, "too_far"
    end
    Dance.requests[toKey] = {
        fromKey = fromKey,
        expiresAt = Defs.now() + Limits.requestTtlMs,
    }
    return true
end

function Dance.respond(target, requester, accepted)
    local toKey = Defs.playerKey(target)
    local fromKey = Defs.playerKey(requester)
    local request = toKey and Dance.requests[toKey] or nil
    if toKey then
        Dance.requests[toKey] = nil
    end
    if not request or request.fromKey ~= fromKey or request.expiresAt < Defs.now() then
        return false, "no_request"
    end
    if accepted ~= true then
        return true, "declined"
    end
    if Dance.partners[fromKey] or Dance.partners[toKey] then
        return false, "already_partnered"
    end
    if not Defs.inRange(requester, target, Limits.requestRadius) then
        return false, "too_far"
    end
    Dance.partners[fromKey] = toKey
    Dance.partners[toKey] = fromKey
    local now = Defs.now()
    local requesterState = Defs.systemState(requester, "Dance")
    local targetState = Defs.systemState(target, "Dance")
    requesterState.sessionStartedAt = now
    targetState.sessionStartedAt = now
    return true, "accepted"
end

function Dance.getPartner(player)
    local key = Defs.playerKey(player)
    local partnerKey = key and Dance.partners[key] or nil
    return partnerKey and Defs.findOnlinePlayer(partnerKey) or nil
end

function Dance.stop(player)
    local key = Defs.playerKey(player)
    if key then
        clearPair(key)
    end
end

function Dance.cleanupPlayer(player)
    local key = Defs.playerKey(player)
    if not key then
        return
    end
    clearPair(key)
    Dance.requests[key] = nil
    for targetKey, request in pairs(Dance.requests) do
        if request.fromKey == key then
            Dance.requests[targetKey] = nil
        end
    end
end

function Dance.cleanup()
    local now = Defs.now()
    for targetKey, request in pairs(Dance.requests) do
        if request.expiresAt < now
            or not Defs.findOnlinePlayer(targetKey)
            or not Defs.findOnlinePlayer(request.fromKey) then
            Dance.requests[targetKey] = nil
        end
    end
    for key, partnerKey in pairs(Dance.partners) do
        local player = Defs.findOnlinePlayer(key)
        local partner = Defs.findOnlinePlayer(partnerKey)
        local state = player and Defs.systemState(player, "Dance") or nil
        if not player or not partner or not Defs.inRange(player, partner, Limits.requestRadius + 2)
            or (state and now - (tonumber(state.sessionStartedAt) or now) > Limits.maxSessionMs) then
            clearPair(key)
        end
    end
end

return Dance
