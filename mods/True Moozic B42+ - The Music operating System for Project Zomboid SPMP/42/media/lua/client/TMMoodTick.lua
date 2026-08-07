-- TMMoodTick.lua
-- Mood benefits while listening to music on ANY True MOOZIC device.
--
-- Every playback engine (walkman/boombox, world boombox, vehicle radio,
-- HiFi world + vehicle, jukebox, wired speakers) reports "the local player
-- can hear music right now" via TMMood.report()/TMMood.reportAt().
-- Once per in-game minute, if music was heard recently, boredom / stress /
-- unhappiness are reduced.
--
-- Trait rules:
--   Deaf        -> no effect (can't hear it)
--   HardOfHearing -> effect at half speed
--   Turemoozicfan    -> effect at double speed (costs 6 points)

require "TCMusicDefenitions"

TMMood = TMMood or {}

local lastHeardMs = 0

-- How close (tiles) a reported source must be when the caller can't
-- provide a distance-faded volume itself.
local HEAR_RANGE = 30

-- Minimum audible volume for a report to count. Conveniently, someone
-- ELSE's headphones report at 0.02 * volume, so they never qualify.
local MIN_VOL = 0.02

-- Fraction of each stat's maximum recovered per in-game minute of listening.
local BOREDOM_FRAC = 0.004
local STRESS_FRAC  = 0.003
local UNHAPPY_FRAC = 0.003

function TMMood.report(vol)
    if vol and vol > MIN_VOL then
        lastHeardMs = getTimestampMs()
    end
end

function TMMood.reportAt(x, y, vol)
    local p = getPlayer()
    if not p or not x or not y then return end
    if math.abs(p:getX() - x) <= HEAR_RANGE and math.abs(p:getY() - y) <= HEAR_RANGE then
        TMMood.report(vol)
    end
end

-- Own personal devices (walkman/boombox/HiFi panels) play on the player's
-- OWN emitter with handles stored in player modData - poll them directly.
local function selfListening(p)
    local emitter = p:getEmitter()
    if not emitter then return false end
    local md = p:getModData()
    if md.tcmusicid and emitter:isPlaying(md.tcmusicid) then return true end
    -- Walkman session (local-only playback).
    local ws = TCMusic and TCMusic.WalkmanSession or nil
    if ws and ws.soundId and emitter:isPlaying(ws.soundId) then return true end
    if md.customMusicIds then
        for _, id in pairs(md.customMusicIds) do
            if id and emitter:isPlaying(id) then return true end
        end
    end
    return false
end

local function applyMood()
    local p = getPlayer()
    if not p or p:isDead() then return end

    -- Heard anything in the last few real seconds? (engines report every
    -- tick while audible; EveryOneMinute fires roughly every 2.5s real)
    local heard = (getTimestampMs() - lastHeardMs) < 6000
    if not heard then
        heard = selfListening(p)
    end
    if not heard then return end

    -- Deaf: music does nothing.
    if TCMusic.playerHasTrait(p, "Deaf") then return end

    local mult = 1.0
    if TCMusic.playerHasTrait(p, "HardOfHearing") then mult = mult * 0.5 end
    if TCMusic.playerHasTrait(p, "truemoozicfan") then mult = mult * 2.0 end

    local stats = p:getStats()
    if not stats then return end

    local function relieve(stat, frac)
        local maxV = (stat and stat.getMaximumValue and stat:getMaximumValue()) or 100
        stats:remove(stat, maxV * frac * mult)
    end

    relieve(CharacterStat.BOREDOM,     BOREDOM_FRAC)
    relieve(CharacterStat.STRESS,      STRESS_FRAC)
    relieve(CharacterStat.UNHAPPINESS, UNHAPPY_FRAC)
end

Events.EveryOneMinute.Add(applyMood)
