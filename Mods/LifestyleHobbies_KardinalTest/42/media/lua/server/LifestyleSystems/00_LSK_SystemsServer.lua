require "LifestyleSystems/LSK_SystemDefinitions"
require "LifestyleCore/LSK_Features"

LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.Systems = LifestyleSecure.Systems or {}

local Systems = LifestyleSecure.Systems

Systems.Music = require "LifestyleSystems/LSK_MusicAuthority"
Systems.Dance = require "LifestyleSystems/LSK_DanceAuthority"
Systems.Wellness = require "LifestyleSystems/LSK_WellnessAuthority"
Systems.Hygiene = require "LifestyleSystems/LSK_HygieneAuthority"
Systems.Art = require "LifestyleSystems/LSK_ArtAuthority"
Systems.Ambition = require "LifestyleSystems/LSK_AmbitionAuthority"
Systems.Invention = require "LifestyleSystems/LSK_InventionAuthority"
Systems.Comfort = require "LifestyleSystems/LSK_ComfortAuthority"
Systems.Social = require "LifestyleSystems/LSK_SocialAuthority"

local function cleanupPlayer(player)
    Systems.Music.setListenerState(player, false)
    Systems.Dance.cleanupPlayer(player)
    Systems.Wellness.cleanupPlayer(player)
    Systems.Hygiene.cleanupPlayer(player)
    Systems.Invention.cleanupPlayer(player)
    Systems.Social.cleanupPlayer(player)
end

local function cleanupDisconnected()
    -- B42 has no reliable server disconnect callback in all revisions.
    if not LifestyleSecure.Features.IsModActive() then
        return
    end
    local Defs = LifestyleSecure.SystemDefinitions
    local online = {}
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players then
        for i = 0, players:size() - 1 do
            local key = Defs.playerKey(players:get(i))
            if key then
                online[key] = true
            end
        end
    end

    Systems.Dance.cleanup()
    Systems.Social.cleanup()
    for key in pairs(Systems.Music.listeners) do
        if not online[key] then
            Systems.Music.listeners[key] = nil
        end
    end
    for key in pairs(Systems.Wellness.sessions) do
        if not online[key] then
            Systems.Wellness.sessions[key] = nil
        end
    end
    for key in pairs(Systems.Wellness.teachingRequests) do
        local request = Systems.Wellness.teachingRequests[key]
        if not online[key] or not online[request.teacherKey] or request.expiresAt < Defs.now() then
            Systems.Wellness.teachingRequests[key] = nil
        end
    end
    for key in pairs(Systems.Hygiene.cleaningQueues) do
        if not online[key] then
            Systems.Hygiene.cleaningQueues[key] = nil
        end
    end
    for key in pairs(Systems.Invention.sessions) do
        local session = Systems.Invention.sessions[key]
        if not online[key] or session.expiresAt < Defs.now() then
            Systems.Invention.sessions[key] = nil
        end
    end
end

Systems.CleanupPlayer = cleanupPlayer
Systems.CleanupDisconnected = cleanupDisconnected

if Events then
    if Events.EveryOneMinute then
        Events.EveryOneMinute.Remove(cleanupDisconnected)
        Events.EveryOneMinute.Add(cleanupDisconnected)
    end
    if Events.OnPlayerDeath then
        Events.OnPlayerDeath.Remove(cleanupPlayer)
        Events.OnPlayerDeath.Add(cleanupPlayer)
    end
end

print("[LifestyleSecure] server system adapters ready")

return Systems
