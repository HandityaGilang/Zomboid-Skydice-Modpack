--[[
    TMJukeboxTick.lua  (client)

    Playback engine for TM_Jukebox world objects.

    Follows the HiFiWorldTick pattern: every client runs its own positional
    audio from the object's shared modData (md.tmJukebox), synced via
    obj:transmitModData().  The playlist is rebuilt live from the jukebox
    container so dropping media in / taking it out is reflected right away.

    Discovery:
      - Registered when the jukebox window is opened / context option used
      - Periodic scan of nearby squares finds jukeboxes started by others
]]

require "TMJukeboxDefs"

if not TMJukeboxAudio then TMJukeboxAudio = {} end

-- Keyed by "x_y_z" -> state table
TMJukeboxAudio.objects = {}

local HEAR_RADIUS   = 100   -- beyond this -> silent (matches HiFi/boombox)
local FADE_RADIUS   = 80    -- inside this -> full device volume
local SCAN_DIST     = 30    -- discovery scan radius (tiles)
local TICK_INTERVAL = 10    -- audio management interval (ticks)
local SCAN_INTERVAL = 600   -- discovery scan interval (ticks, ~20s)
local tickCounter   = 0
local scanCounter   = 0

-- The FMOD engine CULLS file sounds beyond the sound script's distanceMax
-- (base packs now 120, third-party packs often 50-75). A culled sound
-- reports isPlaying=false, which is indistinguishable from a track that
-- finished. A far client must therefore NEVER treat "not playing" as a
-- track end - it would advance/stop the shared jukebox for EVERYONE.
-- Within FAR_TRUST_DIST the engine never culls (it's below every pack's
-- distanceMax), so "not playing" there is a real track end.
local FAR_TRUST_DIST = 45

------------------------------------------------------------------------
--  Registration
------------------------------------------------------------------------

local function keyOf(obj)
    return obj:getX() .. "_" .. obj:getY() .. "_" .. obj:getZ()
end

function TMJukeboxAudio.register(obj)
    if not obj or not instanceof(obj, "IsoObject") then return end
    TMJukebox.applyContainerSettings(obj)
    local key = keyOf(obj)
    if not TMJukeboxAudio.objects[key] then
        TMJukeboxAudio.objects[key] = {
            object       = obj,
            sound        = nil,
            emitter      = nil,
            volume       = 0,
            playingIndex = nil,
            soundName    = nil,
            title        = nil,
        }
    else
        TMJukeboxAudio.objects[key].object = obj
    end
end

------------------------------------------------------------------------
--  Helpers
------------------------------------------------------------------------

local function stopState(state)
    if state.emitter and state.sound then
        state.emitter:stopSound(state.sound)
    end
    if state.skipWaitEmitter and state.skipWaitSound then
        state.skipWaitEmitter:stopSound(state.skipWaitSound)
    end
    state.sound           = nil
    state.emitter         = nil
    state.playingIndex    = nil
    state.soundName       = nil
    state.uid             = nil
    state.playSeq         = nil
    state.title           = nil
    state.startMs         = nil
    state.skipDelay       = nil
    state.skipWaitSound   = nil
    state.skipWaitEmitter = nil
    state.farCulledDist   = nil
end

--- Stop this client's audio for a jukebox immediately (UI stop button).
function TMJukeboxAudio.stopLocal(obj)
    local state = obj and TMJukeboxAudio.objects[keyOf(obj)] or nil
    if state then stopState(state) end
end

--- Current track title for the window's Now Playing line.
function TMJukeboxAudio.getNowPlaying(obj)
    local state = obj and TMJukeboxAudio.objects[keyOf(obj)] or nil
    if state and state.sound then return state.title end
    return nil
end

local function calculateVolumeByDistance(obj, baseVol)
    local p = getPlayer()
    if not p then return 0 end
    local dx = p:getX() - obj:getX()
    local dy = p:getY() - obj:getY()
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance <= FADE_RADIUS then
        return baseVol
    elseif distance <= HEAR_RADIUS then
        return baseVol * (1 - (distance - FADE_RADIUS) / (HEAR_RADIUS - FADE_RADIUS))
    end
    return 0
end

local function distanceToPlayer(obj)
    local p = getPlayer()
    if not p then return 0 end
    local dx = p:getX() - obj:getX()
    local dy = p:getY() - obj:getY()
    return math.sqrt(dx * dx + dy * dy)
end

-- Positional world emitter (same approach as the HiFi world device).
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

local function getBaseVolume(d, obj)
    local vol = d.volume or TMJukebox.DEFAULT_VOLUME
    if TCMusic and TCMusic.getListenVolume then
        local key = (obj and TCMusic.worldVolKey) and TCMusic.worldVolKey(obj:getX(), obj:getY(), obj:getZ()) or nil
        vol = TCMusic.getListenVolume(vol, key)
    end
    -- Jukeboxes are loud: 100%% device volume = 2.0 (5x the old 0.4 scale).
    return vol * 2.0
end

------------------------------------------------------------------------
--  Per-jukebox management
------------------------------------------------------------------------

local function manage(obj, state)
    local md = obj:getModData()
    local d = md.tmJukebox
    if not d or not d.isPlaying then
        stopState(state)
        return
    end

    -- Needs power.
    if not TMJukebox.hasPower(obj:getSquare()) then
        d.isPlaying = false
        stopState(state)
        TMJukebox.transmit(obj)
        return
    end

    local playlist = TMJukebox.buildPlaylist(obj)
    if #playlist == 0 then
        d.isPlaying = false
        stopState(state)
        TMJukebox.transmit(obj)
        return
    end

    if (d.playIndex or 1) > #playlist then
        d.playIndex = 1
        TMJukebox.transmit(obj)
    end

    -- Drop queue entries whose media was removed from the box.
    if TMJukebox.pruneQueue(d, playlist) then
        TMJukebox.transmit(obj)
    end

    -- Playlist changed under the playing track (media added/removed).
    -- Matched by uid (the exact physical media item), so pulling out one
    -- of several copies of the same song is detected correctly.
    if state.sound and state.uid then
        local entry = playlist[state.playingIndex or 0]
        if not entry or entry.uid ~= state.uid then
            -- Find where the playing track moved to.
            local found = nil
            for i = 1, #playlist do
                if playlist[i].uid == state.uid then
                    found = i
                    break
                end
            end
            if found then
                -- Track just shifted position; follow it silently.
                state.playingIndex = found
                if d.playIndex ~= found then d.playIndex = found end
            else
                -- The playing media was pulled out: skip to the next entry
                -- (indices shifted, so the current playIndex already points
                -- at the following track).
                stopState(state)
                if (d.playIndex or 1) > #playlist then d.playIndex = 1 end
                return
            end
        end
    end

    -- Track changed elsewhere (skip button / other client) -> restart.
    -- playSeq catches explicit changes that land on the same index or the
    -- same sound name (duplicates of one song, queue jumps to itself).
    if state.sound and (state.playingIndex ~= d.playIndex
        or (state.playSeq or 0) ~= (d.playSeq or 0)) then
        stopState(state)
    end

    local vol = calculateVolumeByDistance(obj, getBaseVolume(d, obj))
    local dist = distanceToPlayer(obj)
    local trusted = dist <= FAR_TRUST_DIST

    -- Scratch skip effect playing: hold everything until it finishes,
    -- then advance to the next track.
    if state.skipWaitSound and state.skipWaitEmitter then
        -- User jumped elsewhere mid-effect: cancel it and play that instead.
        if state.playingIndex ~= d.playIndex
            or (state.playSeq or 0) ~= (d.playSeq or 0) then
            stopState(state)
        elseif state.skipWaitEmitter:isPlaying(state.skipWaitSound) then
            return
        elseif not trusted then
            -- Far: the effect was engine-culled, not finished. Suspend.
            stopState(state)
            state.farCulledDist = dist
            return
        else
            stopState(state)
            TMJukebox.stepTrack(d, playlist, 1)
            TMJukebox.transmit(obj)
            return
        end
    end

    -- Scratched CD track: force it to end once its rolled delay elapses.
    if state.sound and state.emitter and state.skipDelay and state.startMs then
        if (getTimestampMs() - state.startMs) >= state.skipDelay * 1000 then
            state.emitter:stopSound(state.sound)
            state.sound     = nil
            state.skipDelay = nil
            -- Play a random skip effect; the next track waits for it.
            local skipName = TCMusic and TCMusic.getRandomCDSkipSound and TCMusic.getRandomCDSkipSound() or nil
            local sid = skipName and playWorldSound(state.emitter, skipName, obj) or nil
            if sid then
                if state.emitter.set3D then state.emitter:set3D(sid, true) end
                state.emitter:setVolume(sid, vol)
                state.skipWaitSound   = sid
                state.skipWaitEmitter = state.emitter
                return
            end
            -- No skip effect available: advance immediately.
            stopState(state)
            TMJukebox.stepTrack(d, playlist, 1)
            TMJukebox.transmit(obj)
            return
        end
    end

    -- Track finished naturally -> advance and loop.
    if state.sound and state.emitter then
        if not state.emitter:isPlaying(state.sound) then
            if not trusted then
                -- Far: the engine culled our local sound (distanceMax), the
                -- track did NOT end. Suspend locally; near clients advance
                -- the shared state and we re-attach on approach.
                stopState(state)
                state.farCulledDist = dist
                return
            end
            stopState(state)
            TMJukebox.stepTrack(d, playlist, 1)
            TMJukebox.transmit(obj)
            return
        end
    end

    -- Mood: jukebox music is audible to the local player this tick.
    if state.sound and TMMood then TMMood.report(vol) end

    if not state.sound then
        -- Suspended after an engine cull: only retry once the player has
        -- actually come closer, otherwise we'd restart-loop a sound the
        -- engine instantly culls again.
        if state.farCulledDist then
            if dist >= state.farCulledDist - 5 then return end
            state.farCulledDist = nil
        end
        local entry = playlist[d.playIndex or 1]
        if not entry then return end
        local emitter = getWorldEmitter(obj)
        if not emitter then return end
        local soundId = playWorldSound(emitter, entry.soundName, obj)
        if soundId then
            if emitter.set3D then emitter:set3D(soundId, true) end
            emitter:setVolume(soundId, vol)
            state.sound        = soundId
            state.emitter      = emitter
            state.volume       = vol
            state.playingIndex = d.playIndex
            state.soundName    = entry.soundName
            state.uid          = entry.uid
            state.playSeq      = d.playSeq or 0
            state.title        = entry.title
            -- Per-song title above the jukebox, vanilla-radio style.
            -- Local-only: every client's jukebox tick runs this itself.
            if TMSpeech then
                TMSpeech.sayAt(obj:getX() + 0.5, obj:getY() + 0.5, obj:getZ(), TMSpeech.text("Playing", tostring(entry.title or entry.soundName or "")))
            end
            -- Scratched CD: roll this track's forced-skip timer.
            state.startMs   = getTimestampMs()
            state.skipDelay = nil
            if entry.scratch and TCMusic and TCMusic.getScratchSkipDelay then
                state.skipDelay = TCMusic.getScratchSkipDelay(entry.scratch,
                    entry.trackIndex or 1, entry.totalTracks or 1)
            end
        end
    else
        if math.abs((state.volume or 0) - vol) > 0.01 then
            state.emitter:setVolume(state.sound, vol)
            state.volume = vol
        end
    end
end

------------------------------------------------------------------------
--  Discovery scan
------------------------------------------------------------------------

local function scanForJukeboxes(player)
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
                for i = 0, n - 1 do
                    local obj = objs:get(i)
                    if TMJukebox.isConverted(obj) then
                        -- Re-apply the media-only lock + capacity: the
                        -- accept-item function is not persisted in saves.
                        TMJukebox.applyContainerSettings(obj)
                        local omd = obj:getModData()
                        if omd.tmJukebox and omd.tmJukebox.isPlaying then
                            local key = keyOf(obj)
                            if not TMJukeboxAudio.objects[key] then
                                TMJukeboxAudio.register(obj)
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
    tickCounter = tickCounter + 1
    scanCounter = scanCounter + 1

    local player = getPlayer()
    if not player then return end

    if scanCounter >= SCAN_INTERVAL then
        scanCounter = 0
        scanForJukeboxes(player)
    end

    if tickCounter < TICK_INTERVAL then return end
    tickCounter = 0

    local toRemove = {}
    for key, state in pairs(TMJukeboxAudio.objects) do
        local obj = state.object
        if not obj or not obj:getSquare() then
            stopState(state)
            table.insert(toRemove, key)
        else
            manage(obj, state)
        end
    end
    for _, key in ipairs(toRemove) do
        TMJukeboxAudio.objects[key] = nil
    end
end

Events.OnTick.Add(onTick)
