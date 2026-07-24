--[[
    HiFiVehicleTick.lua
    Background tick handler that manages vehicle HiFi CD/Cassette audio.

    Audio ALWAYS plays from the VEHICLE emitter so it never restarts when
    the player enters or exits the vehicle.  Volume is adjusted every tick:
      - Player INSIDE the vehicle  → full set volume
      - Player OUTSIDE, all windows closed → half set volume
      - Player OUTSIDE, any window open/broken → full set volume
]]

require "TCMusicDefenitions"

if not HiFiVehicleAudio then HiFiVehicleAudio = {} end

-- Keyed by vehicle ID → {cdSound, tapeSound, lastCDTrack}
HiFiVehicleAudio.vehicles = {}

local HEAR_DIST = 30          -- max tile distance to manage audio
local TICK_INTERVAL = 20      -- run every N ticks (perf, was 10)
local tickCounter = 0

-- Audio-silence debug logs (toggled from sandbox option: PZTrueMoozicDebug page → AudioSilenceDebug)
-- Throttled: identical event prefixes only emit once per AUDIO_DBG_INTERVAL_MS.
local AUDIO_DBG_INTERVAL_MS = 1500
local audioDbgLastMs = {}
local function audioDbgKey(msg)
    if type(msg) ~= "string" then return tostring(msg) end
    local cut = msg:find("=", 1, true) or msg:find(" %d") or (#msg + 1)
    return msg:sub(1, cut - 1)
end
local function audioDbg(msg)
    if not (SandboxVars and SandboxVars.PZTrueMusicSandbox and SandboxVars.PZTrueMusicSandbox.AudioSilenceDebug) then
        return
    end
    local now = (getTimestampMs and getTimestampMs()) or 0
    local key = audioDbgKey(msg)
    local last = audioDbgLastMs[key] or 0
    if now - last < AUDIO_DBG_INTERVAL_MS then return end
    audioDbgLastMs[key] = now
    print(msg)
end

------------------------------------------------------------------------
--  Helpers
------------------------------------------------------------------------

local function getVehicleHiFiPart(vehicle)
    local matched = nil
    local totalParts = vehicle:getPartCount()
    for i = 0, totalParts - 1 do
        local part = vehicle:getPartByIndex(i)
        if part and part:getDeviceData() then
            local ii = part:getInventoryItem()
            local ft = ii and ii.getFullType and ii:getFullType() or nil
            if ft and HiFiDevices and HiFiDevices[ft] then
                matched = part
                break
            end
        end
    end
    return matched
end

-- Check if ALL non-destroyed windows on the vehicle are closed.
-- Returns true when every intact window is rolled up (closed).
local function areAllWindowsClosed(vehicle)
    local hasWindow = false
    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if part then
            local win = part:getWindow()
            if win then
                hasWindow = true
                if win:isOpen() or win:isDestroyed() then
                    return false   -- at least one window is open/broken
                end
            end
        end
    end
    return hasWindow   -- true only if we found windows and all are closed
end

-- Use a FREE positional emitter (same approach as HiFiWorldTick) instead of
-- vehicle:getEmitter(), which returns a VehicleEmitter that may not support
-- playSoundImpl for custom FMOD events.  Position is kept in sync via setPos.
local function getVehicleEmitter(vehicle)
    if not vehicle then return nil end
    local world = getWorld()
    if not world or not world.getFreeEmitter then return nil end
    local e = world:getFreeEmitter(vehicle:getX(), vehicle:getY(), vehicle:getZ())
    if e and e.setPos then e:setPos(vehicle:getX(), vehicle:getY(), vehicle:getZ()) end
    return e
end

local function stopSound(emitter, handle)
    if emitter and handle and handle ~= 0 then
        if emitter.isPlaying and emitter:isPlaying(handle) then
            emitter:stopSound(handle)
        else
            emitter:stopSound(handle)
        end
    end
end

local function distSq(player, vehicle)
    local dx = player:getX() - vehicle:getX()
    local dy = player:getY() - vehicle:getY()
    return dx * dx + dy * dy
end

local function playVehicleSound(emitter, soundName, vehicle)
    if not emitter or not soundName then return nil end
    if emitter.playSoundImpl then
        local soundId = emitter:playSoundImpl(soundName, vehicle)
        if soundId and soundId ~= 0 then return soundId end
    end
    if emitter.playSound then
        local soundId = emitter:playSound(soundName)
        if soundId and soundId ~= 0 then return soundId end
    end
    return nil
end

local function forEachVehicle(cell, callback)
    if not cell or not callback or not cell.getVehicles then return end
    local vehicles = cell:getVehicles()
    if not vehicles then return end

    -- Plain Lua table path
    if type(vehicles) == "table" then
        for _, vehicle in ipairs(vehicles) do
            if vehicle then callback(vehicle) end
        end
        return
    end

    -- Java collection: iterator-first (works for List, Set, HashSet, etc.).
    -- We avoid probing :size()/:get() with truthiness checks because Java
    -- method handles aren't truthy fields on userdata, and calling :get(0)
    -- on a non-List spams "Tried to call nil" engine logs even inside pcall.
    local okIt, iter = pcall(function() return vehicles:iterator() end)
    if okIt and iter then
        while true do
            local okHas, hasNext = pcall(function() return iter:hasNext() end)
            if not okHas or not hasNext then break end
            local okNext, vehicle = pcall(function() return iter:next() end)
            if not okNext then break end
            if vehicle then callback(vehicle) end
        end
        return
    end

    -- Fallback: indexed list (List<BaseVehicle>)
    local okSize, count = pcall(function() return vehicles:size() end)
    if okSize and count and count > 0 then
        for i = 0, count - 1 do
            local okGet, vehicle = pcall(function() return vehicles:get(i) end)
            if okGet and vehicle then callback(vehicle) end
        end
    end
end

------------------------------------------------------------------------
--  Per-vehicle audio state
------------------------------------------------------------------------

local function ensureState(vid)
    if not HiFiVehicleAudio.vehicles[vid] then
        HiFiVehicleAudio.vehicles[vid] = {
            cdSound      = nil,  -- sound handle
            tapeSound    = nil,
            cdEmitter    = nil,  -- emitter reference used for the sound
            tapeEmitter  = nil,
            lastCDTrack  = nil,
        }
    end
    return HiFiVehicleAudio.vehicles[vid]
end

local function stopCD(state)
    if state.cdSound and state.cdEmitter then
        stopSound(state.cdEmitter, state.cdSound)
    end
    state.cdSound = nil
    state.cdEmitter = nil
end

local function stopTape(state)
    if state.tapeSound and state.tapeEmitter then
        stopSound(state.tapeEmitter, state.tapeSound)
    end
    state.tapeSound = nil
    state.tapeEmitter = nil
end

------------------------------------------------------------------------
--  Choose volume (emitter is always the vehicle)
------------------------------------------------------------------------

local function getVolume(player, vehicle, deviceData)
    local setVol = deviceData:getDeviceVolume() * 0.4
    local insideThisVehicle = (player:getVehicle() == vehicle)

    if insideThisVehicle then
        return setVol
    else
        if areAllWindowsClosed(vehicle) then
            return setVol * 0.5
        else
            return setVol
        end
    end
end

------------------------------------------------------------------------
--  CD playback management
------------------------------------------------------------------------

local function manageCD(player, vehicle, part, md, deviceData, state)
    if not md.hifiCD then return end
    local isOn = deviceData:getIsTurnedOn()

    -- Power off → stop
    if not isOn and md.hifiCD.isPlaying then
        md.hifiCD.isPlaying = false
        stopCD(state)
        return
    end

    if not md.hifiCD.isPlaying or not md.hifiCD.tracks then
        stopCD(state)
        return
    end

    -- Keep free emitter in sync with vehicle position
    if state.cdEmitter and state.cdEmitter.setPos then
        state.cdEmitter:setPos(vehicle:getX(), vehicle:getY(), vehicle:getZ())
    end
    local vol = getVolume(player, vehicle, deviceData)

    -- Check if currently playing sound finished → advance track
    if state.cdSound and state.cdEmitter then
        if not state.cdEmitter:isPlaying(state.cdSound) then
            state.cdSound = nil
            state.cdEmitter = nil
            -- advance track
            if md.hifiCD.totalTracks and md.hifiCD.totalTracks > 1 then
                md.hifiCD.currentTrack = (md.hifiCD.currentTrack or 1) + 1
                if md.hifiCD.currentTrack > md.hifiCD.totalTracks then
                    md.hifiCD.currentTrack = 1
                end
            else
                md.hifiCD.isPlaying = false
                return
            end
        end
    end

    -- Start sound if not currently playing
    if not state.cdSound then
        local track = md.hifiCD.tracks[md.hifiCD.currentTrack or 1]
        if track and track.soundName then
            local emitter = getVehicleEmitter(vehicle)
            if not emitter then return end
            state.cdSound = playVehicleSound(emitter, track.soundName, vehicle)
            state.cdEmitter = emitter
            if state.cdSound then
                emitter:setVolume(state.cdSound, vol)
            end
        end
    else
        -- Adjust volume continuously (window state / enter-exit can change)
        if state.cdEmitter and state.cdSound then
            state.cdEmitter:setVolume(state.cdSound, vol)
        end
    end
end

------------------------------------------------------------------------
--  Cassette playback management
------------------------------------------------------------------------

local function manageTape(player, vehicle, part, md, deviceData, state)
    if not md.hifiTape then return end
    local isOn = deviceData:getIsTurnedOn()

    -- Power off → stop
    if not isOn and md.hifiTape.isPlaying then
        md.hifiTape.isPlaying = false
        stopTape(state)
        return
    end

    if not md.hifiTape.isPlaying or not md.hifiTape.mediaItem then
        stopTape(state)
        return
    end

    -- Keep free emitter in sync with vehicle position
    if state.tapeEmitter and state.tapeEmitter.setPos then
        state.tapeEmitter:setPos(vehicle:getX(), vehicle:getY(), vehicle:getZ())
    end
    local vol = getVolume(player, vehicle, deviceData)

    -- Check if sound finished
    if state.tapeSound and state.tapeEmitter then
        if not state.tapeEmitter:isPlaying(state.tapeSound) then
            md.hifiTape.isPlaying = false
            state.tapeSound = nil
            state.tapeEmitter = nil
            return
        end
    end

    -- Start if not playing
    if not state.tapeSound then
        local soundName = TCMusic and TCMusic.getSoundName and TCMusic.getSoundName(md.hifiTape.mediaItem) or md.hifiTape.mediaItem
        if soundName then
            local emitter = getVehicleEmitter(vehicle)
            if not emitter then return end
            state.tapeSound = playVehicleSound(emitter, soundName, vehicle)
            state.tapeEmitter = emitter
            if state.tapeSound then
                emitter:setVolume(state.tapeSound, vol)
            end
        end
    else
        -- Adjust volume continuously
        if state.tapeEmitter and state.tapeSound then
            state.tapeEmitter:setVolume(state.tapeSound, vol)
        end
    end
end

------------------------------------------------------------------------
--  Main tick
------------------------------------------------------------------------

local function onTick()
    tickCounter = tickCounter + 1
    if tickCounter < TICK_INTERVAL then return end
    tickCounter = 0

    local player = getPlayer()
    if not player then return end

    local cell = getCell()
    if not cell then return end

    -- Track which vehicle IDs we processed this tick
    local processed = {}

    -- Cache debug flag once per tick — Lua evaluates concat args BEFORE the
    -- audioDbg call, so the function's own internal check is too late to skip
    -- string allocation in hot per-vehicle loops.
    local AUDIO_DBG = SandboxVars and SandboxVars.PZTrueMusicSandbox
        and SandboxVars.PZTrueMusicSandbox.AudioSilenceDebug or false

    local seen = 0
    local hifiCount = 0
    forEachVehicle(cell, function(vehicle)
        seen = seen + 1
        if vehicle and distSq(player, vehicle) < HEAR_DIST * HEAR_DIST then
            local part = getVehicleHiFiPart(vehicle)
            if part then
                hifiCount = hifiCount + 1
                local vid = vehicle:getId()
                processed[vid] = true
                local state = ensureState(vid)
                local md = part:getModData()
                local dd = part:getDeviceData()
                if md and dd then
                    if AUDIO_DBG then
                        local cdPlay = md.hifiCD and md.hifiCD.isPlaying
                        local tpPlay = md.hifiTape and md.hifiTape.isPlaying
                        audioDbg("[HIFIDBG][VehTick] vid=" .. tostring(vid)
                            .. " cdPlaying=" .. tostring(cdPlay)
                            .. " tapePlaying=" .. tostring(tpPlay)
                            .. " cdHandle=" .. tostring(state.cdSound)
                            .. " tapeHandle=" .. tostring(state.tapeSound)
                            .. " on=" .. tostring(dd:getIsTurnedOn()))
                    end
                    manageCD(player, vehicle, part, md, dd, state)
                    manageTape(player, vehicle, part, md, dd, state)
                end
            end
        end
    end)
    if AUDIO_DBG and seen > 0 then
        audioDbg("[HIFIDBG][VehTick] scanned vehicles=" .. seen .. " hifi-parts-found=" .. hifiCount)
    end

    -- Clean up audio for vehicles that are no longer nearby
    for vid, state in pairs(HiFiVehicleAudio.vehicles) do
        if not processed[vid] then
            stopCD(state)
            stopTape(state)
            HiFiVehicleAudio.vehicles[vid] = nil
        end
    end
end

Events.OnTick.Add(onTick)
