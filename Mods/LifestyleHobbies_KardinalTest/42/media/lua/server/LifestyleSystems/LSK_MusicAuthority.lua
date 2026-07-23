require "LifestyleSystems/LSK_SystemDefinitions"
require "LifestyleCore/LSK_SystemContracts"

LifestyleSecure = LifestyleSecure or {}
local Music = {}
local Defs = LifestyleSecure.SystemDefinitions
local Limits = Defs.Music

Music.listeners = {}
Music.registeredTracks = {}

function Music.registerTrack(instrument, trackId)
    if not Limits.instruments[instrument] then
        return false, "unknown_instrument"
    end
    trackId = Defs.identifier(trackId)
    if not trackId then
        return false, "invalid_track"
    end
    Music.registeredTracks[instrument] = Music.registeredTracks[instrument] or {}
    Music.registeredTracks[instrument][trackId] = true
    return true
end

function Music.isKnownTrack(instrument, trackId)
    return Limits.instruments[instrument] == true
        and Defs.identifier(trackId) ~= nil
        and Music.registeredTracks[instrument] ~= nil
        and Music.registeredTracks[instrument][trackId] == true
end

function Music.sanitizeLearnedTracks(instrument, tracks)
    if not Limits.instruments[instrument] then
        return nil, "unknown_instrument"
    end
    return Defs.boundedIdList(
        tracks,
        Music.registeredTracks[instrument] or {},
        Limits.maxLearnedPerInstrument
    )
end

function Music.learnTrack(player, instrument, trackId)
    if not Music.isKnownTrack(instrument, trackId) then
        return false, "unknown_track"
    end
    local state = Defs.systemState(player, "Music")
    if not state then
        return false, "invalid_player"
    end
    state.learned = type(state.learned) == "table" and state.learned or {}
    local learned = Music.sanitizeLearnedTracks(instrument, state.learned[instrument] or {})
    for i = 1, #learned do
        if learned[i] == trackId then
            state.learned[instrument] = learned
            return true, "already_learned"
        end
    end
    if #learned >= Limits.maxLearnedPerInstrument then
        return false, "track_limit"
    end
    learned[#learned + 1] = trackId
    state.learned[instrument] = learned
    return true, "learned"
end

function Music.setListenerState(player, active, sourceKey, radius)
    local key = Defs.playerKey(player)
    if not key then
        return false
    end
    if active ~= true then
        Music.listeners[key] = nil
        return true
    end
    Music.listeners[key] = {
        sourceKey = tostring(sourceKey or key),
        radius = Defs.clamp(radius, 1, Limits.listenerRadius) or Limits.listenerRadius,
        updatedAt = Defs.now(),
    }
    return true
end

function Music.getListenersNear(source)
    local result = {}
    for key, listener in pairs(Music.listeners) do
        local player = Defs.findOnlinePlayer(key)
        if player and Defs.inRange(source, player, listener.radius) then
            result[#result + 1] = player
        elseif not player or Defs.now() - listener.updatedAt > 120000 then
            Music.listeners[key] = nil
        end
    end
    return result
end

function Music.calculateReward(actionName, perkName, elapsedSeconds, requestedXp)
    local rate = LifestyleSecure.SystemContracts.GetActionRewardRate(actionName, perkName)
    local elapsed = Defs.clamp(elapsedSeconds, 0, 1800)
    local requested = Defs.clamp(requestedXp, 0, Limits.maxRewardPerAction)
    if not rate or not elapsed or not requested then
        return nil, "invalid_reward"
    end
    local timeCap = math.min(Limits.maxRewardPerAction, rate * elapsed / 60)
    return math.min(requested, timeCap)
end

function Music.grantReward(player, actionName, perkName, elapsedSeconds, requestedXp)
    local amount, err = Music.calculateReward(actionName, perkName, elapsedSeconds, requestedXp)
    local perk = nil
    if amount and Perks then
        if Perks.FromString then
            perk = Perks.FromString(perkName)
        end
        if not perk then
            perk = Perks[perkName]
        end
    end
    if not amount or not perk or not player then
        return false, err or "unknown_perk"
    end
    if addXp then
        addXp(player, perk, amount)
    elseif player.getXp then
        player:getXp():AddXP(perk, amount)
    else
        return false, "xp_api_missing"
    end
    return true, amount
end

return Music
