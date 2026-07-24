--[[
    HiFiWorldTick.lua
    Background tick handler for placed (IsoObject) HiFi audio.

    Audio ALWAYS plays from the IsoObject emitter so it is positional
    at the world object's location, not the player's.

    Each client manages its own audio locally based on the shared modData
    on the IsoObject.  PZ syncs IsoObject modData via transmitModData().

    Discovery:
      - Registered when the HiFi window opens (HiFiWindow.readFromObject)
      - Registered when a timed action targets an IsoObject HiFi
      - Periodic scan of nearby squares finds HiFi started by other players
]]

require "TCMusicDefenitions"

if not HiFiWorldAudio then HiFiWorldAudio = {} end

-- Keyed by "x_y_z" → state table
HiFiWorldAudio.objects = {}

local HEAR_RADIUS   = 100    -- beyond this → volume = 0 (matches boombox)
local FADE_RADIUS   = 80     -- within this → full device volume
-- Perf: discovery scan iterates (2*SCAN_DIST+1)^2 squares; 30 = 3,721 squares vs.
-- 100 = 40,401. Players using a HiFi register the object directly (window open /
-- timed action), so the scan only needs to catch HiFis started by *other* players
-- nearby — which never need to be heard from far away anyway.
local SCAN_DIST     = 30     -- discovery scan radius (tiles)
local TICK_INTERVAL = 10     -- audio management interval (ticks, was 5)
local SCAN_INTERVAL = 600    -- discovery scan interval (ticks, ~20s — was 150)
local tickCounter   = 0
local scanCounter   = 0

------------------------------------------------------------------------
--  Registration
------------------------------------------------------------------------

function HiFiWorldAudio.register(object)
    if not object or not instanceof(object, "IsoObject") then return end
    local key = object:getX() .. "_" .. object:getY() .. "_" .. object:getZ()
    if not HiFiWorldAudio.objects[key] then
        HiFiWorldAudio.objects[key] = {
            object       = object,
            cdSound      = nil,
            cdEmitter    = nil,
            cdVolume     = 0,
            tapeSound    = nil,
            tapeEmitter  = nil,
            tapeVolume   = 0,
            vinylSound   = nil,
            vinylEmitter = nil,
            vinylVolume  = 0,
        }
    else
        HiFiWorldAudio.objects[key].object = object
    end
end

------------------------------------------------------------------------
--  Helpers
------------------------------------------------------------------------

local function stopSound(emitter, handle)
    if emitter and handle then
        emitter:stopSound(handle)
    end
end

local function getDistance(player, obj)
    local dx = player:getX() - obj:getX()
    local dy = player:getY() - obj:getY()
    return math.sqrt(dx * dx + dy * dy)
end

--- Fade volume by distance, matching TCMusic boombox behaviour.
--- Full volume inside FADE_RADIUS, linear fade to HEAR_RADIUS, silent beyond.
local function calculateVolumeByDistance(obj, baseVol)
    local p = getPlayer()
    if not p then return 0 end
    local distance = getDistance(p, obj)
    if distance <= FADE_RADIUS then
        return baseVol
    elseif distance <= HEAR_RADIUS then
        local fadeRange    = HEAR_RADIUS - FADE_RADIUS
        local fadeDistance  = distance - FADE_RADIUS
        return baseVol * (1 - fadeDistance / fadeRange)
    end
    return 0
end

-- IsoWaveSignal doesn't expose getEmitter() to Lua.
-- Use getWorld():getFreeEmitter() which creates a positional emitter at world coords.
-- IMPORTANT: playSoundImpl(name, nil) crashes because the free emitter has no
-- internal 'square'.  Always pass the source IsoObject so the engine reads the
-- position from the object's square instead of the emitter's (null) square.
local function getWorldEmitter(obj)
    local world = getWorld()
    if not world or not world.getFreeEmitter then return nil end
    local e = world:getFreeEmitter(obj:getX(), obj:getY(), obj:getZ())
    if e and e.setPos then e:setPos(obj:getX(), obj:getY(), obj:getZ()) end
    return e
end

local function playWorldSound(emitter, soundName, obj)
    if not emitter or not soundName then return nil end
    if emitter.playSoundImpl then
        local soundId = emitter:playSoundImpl(soundName, obj)
        if soundId and soundId ~= 0 then return soundId end
    end
    if emitter.playSound then
        local soundId = emitter:playSound(soundName)
        if soundId and soundId ~= 0 then return soundId end
    end
    return nil
end

------------------------------------------------------------------------
--  State stop helpers
------------------------------------------------------------------------

local function stopCD(state)
    stopSound(state.cdEmitter, state.cdSound)
    state.cdSound   = nil
    state.cdEmitter  = nil
end

local function stopTape(state)
    stopSound(state.tapeEmitter, state.tapeSound)
    state.tapeSound   = nil
    state.tapeEmitter  = nil
end

local function stopVinyl(state)
    stopSound(state.vinylEmitter, state.vinylSound)
    state.vinylSound   = nil
    state.vinylEmitter  = nil
end

------------------------------------------------------------------------
--  CD playback management
------------------------------------------------------------------------

local function manageCD(obj, md, dd, state)
    if not md.hifiCD then return end
    local isOn = dd:getIsTurnedOn()

    -- Power off → stop
    if not isOn and md.hifiCD.isPlaying then
        md.hifiCD.isPlaying = false
        stopCD(state)
        if obj.transmitModData then obj:transmitModData() end
        return
    end

    if not md.hifiCD.isPlaying or not md.hifiCD.tracks then
        stopCD(state)
        return
    end

    local emitter = state.cdEmitter or getWorldEmitter(obj)
    if not emitter then
        stopCD(state)
        return
    end
    local baseVol = dd:getDeviceVolume() * 0.4
    local vol = calculateVolumeByDistance(obj, baseVol)

    -- Check if track finished → advance
    if state.cdSound and state.cdEmitter then
        if not state.cdEmitter:isPlaying(state.cdSound) then
            state.cdSound   = nil
            state.cdEmitter  = nil
            if md.hifiCD.totalTracks and md.hifiCD.totalTracks > 1 then
                md.hifiCD.currentTrack = (md.hifiCD.currentTrack or 1) + 1
                if md.hifiCD.currentTrack > md.hifiCD.totalTracks then
                    md.hifiCD.currentTrack = 1
                end
                if obj.transmitModData then obj:transmitModData() end
            else
                md.hifiCD.isPlaying = false
                if obj.transmitModData then obj:transmitModData() end
                return
            end
        end
    end

    -- Start sound if not currently playing
    if not state.cdSound then
        local track = md.hifiCD.tracks[md.hifiCD.currentTrack or 1]
        if track and track.soundName then
            state.cdSound   = playWorldSound(emitter, track.soundName, obj)
            state.cdEmitter  = emitter
            if state.cdSound then
                if emitter.set3D then emitter:set3D(state.cdSound, true) end
                emitter:setVolume(state.cdSound, vol)
                state.cdVolume = vol
            end
        end
    else
        -- Adjust volume by distance (only if changed)
        if state.cdEmitter and state.cdSound then
            if math.abs((state.cdVolume or 0) - vol) > 0.01 then
                state.cdEmitter:setVolume(state.cdSound, vol)
                state.cdVolume = vol
            end
        end
    end
end

------------------------------------------------------------------------
--  Cassette playback management
------------------------------------------------------------------------

local function manageTape(obj, md, dd, state)
    if not md.hifiTape then return end
    local isOn = dd:getIsTurnedOn()

    if not isOn and md.hifiTape.isPlaying then
        md.hifiTape.isPlaying = false
        stopTape(state)
        if obj.transmitModData then obj:transmitModData() end
        return
    end

    if not md.hifiTape.isPlaying or not md.hifiTape.mediaItem then
        stopTape(state)
        return
    end

    local emitter = state.tapeEmitter or getWorldEmitter(obj)
    if not emitter then
        stopTape(state)
        return
    end
    local baseVol = dd:getDeviceVolume() * 0.4
    local vol = calculateVolumeByDistance(obj, baseVol)

    -- Check if sound finished
    if state.tapeSound and state.tapeEmitter then
        if not state.tapeEmitter:isPlaying(state.tapeSound) then
            md.hifiTape.isPlaying = false
            state.tapeSound   = nil
            state.tapeEmitter  = nil
            if obj.transmitModData then obj:transmitModData() end
            return
        end
    end

    -- Start if not playing
    if not state.tapeSound then
        local soundName = TCMusic and TCMusic.getSoundName and TCMusic.getSoundName(md.hifiTape.mediaItem) or md.hifiTape.mediaItem
        if soundName then
            state.tapeSound   = playWorldSound(emitter, soundName, obj)
            state.tapeEmitter  = emitter
            if state.tapeSound then
                if emitter.set3D then emitter:set3D(state.tapeSound, true) end
                emitter:setVolume(state.tapeSound, vol)
                state.tapeVolume = vol
            end
        end
    else
        if state.tapeEmitter and state.tapeSound then
            if math.abs((state.tapeVolume or 0) - vol) > 0.01 then
                state.tapeEmitter:setVolume(state.tapeSound, vol)
                state.tapeVolume = vol
            end
        end
    end
end

------------------------------------------------------------------------
--  Vinyl playback management
------------------------------------------------------------------------

local function manageVinyl(obj, md, dd, state)
    if not md.hifiVinyl then return end
    local isOn = dd:getIsTurnedOn()

    if not isOn and md.hifiVinyl.isPlaying then
        md.hifiVinyl.isPlaying = false
        stopVinyl(state)
        if obj.transmitModData then obj:transmitModData() end
        return
    end

    if not md.hifiVinyl.isPlaying or not md.hifiVinyl.mediaItem then
        stopVinyl(state)
        return
    end

    local emitter = state.vinylEmitter or getWorldEmitter(obj)
    if not emitter then
        stopVinyl(state)
        return
    end
    local baseVol = dd:getDeviceVolume() * 0.4
    local vol = calculateVolumeByDistance(obj, baseVol)

    if state.vinylSound and state.vinylEmitter then
        if not state.vinylEmitter:isPlaying(state.vinylSound) then
            md.hifiVinyl.isPlaying = false
            state.vinylSound   = nil
            state.vinylEmitter  = nil
            if obj.transmitModData then obj:transmitModData() end
            return
        end
    end

    if not state.vinylSound then
        local soundName = TCMusic and TCMusic.getSoundName and TCMusic.getSoundName(md.hifiVinyl.mediaItem) or md.hifiVinyl.mediaItem
        if soundName then
            state.vinylSound   = playWorldSound(emitter, soundName, obj)
            state.vinylEmitter  = emitter
            if state.vinylSound then
                if emitter.set3D then emitter:set3D(state.vinylSound, true) end
                emitter:setVolume(state.vinylSound, vol)
                state.vinylVolume = vol
            end
        end
    else
        if state.vinylEmitter and state.vinylSound then
            if math.abs((state.vinylVolume or 0) - vol) > 0.01 then
                state.vinylEmitter:setVolume(state.vinylSound, vol)
                state.vinylVolume = vol
            end
        end
    end
end

------------------------------------------------------------------------
--  Discovery scan
------------------------------------------------------------------------

local function scanForHiFiObjects(player)
    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())
    local cell = getCell()
    if not cell then return end

    for dx = -SCAN_DIST, SCAN_DIST do
        for dy = -SCAN_DIST, SCAN_DIST do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then
                local objs = sq:getObjects()
                local n = objs and objs:size() or 0
                if n > 0 then
                    for i = 0, n - 1 do
                        local obj = objs:get(i)
                        if obj and instanceof(obj, "IsoWaveSignal") then
                            local omd = obj:getModData()
                            if omd and (omd.hifiDeviceType
                                or (omd.hifiCD and omd.hifiCD.isPlaying)
                                or (omd.hifiTape and omd.hifiTape.isPlaying)
                                or (omd.hifiVinyl and omd.hifiVinyl.isPlaying)) then
                                local key = obj:getX() .. "_" .. obj:getY() .. "_" .. obj:getZ()
                                if not HiFiWorldAudio.objects[key] then
                                    HiFiWorldAudio.register(obj)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------------
--  Main tick
------------------------------------------------------------------------

local function onTick()
    tickCounter  = tickCounter + 1
    scanCounter  = scanCounter + 1

    local player = getPlayer()
    if not player then return end

    -- Discovery scan (less frequent)
    if scanCounter >= SCAN_INTERVAL then
        scanCounter = 0
        scanForHiFiObjects(player)
    end

    -- Audio management
    if tickCounter < TICK_INTERVAL then return end
    tickCounter = 0

    local toRemove = {}

    for key, state in pairs(HiFiWorldAudio.objects) do
        local obj = state.object
        if not obj or not obj:getSquare() then
            -- Object removed from world → clean up
            stopCD(state)
            stopTape(state)
            stopVinyl(state)
            table.insert(toRemove, key)
        else
            local dd = obj.getDeviceData and obj:getDeviceData() or nil
            if dd then
                local md = obj:getModData()
                -- manage* functions handle distance-based volume (fade to 0 beyond HEAR_RADIUS)
                manageCD(obj, md, dd, state)
                manageTape(obj, md, dd, state)
                manageVinyl(obj, md, dd, state)
            end
        end
    end

    for _, key in ipairs(toRemove) do
        HiFiWorldAudio.objects[key] = nil
    end
end

Events.OnTick.Add(onTick)
