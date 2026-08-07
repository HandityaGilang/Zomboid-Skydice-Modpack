--[[
    TMJukeboxDefs.lua  (shared)

    TM_Jukebox: turns vanilla world jukebox tiles into a working music
    machine backed by the True MOOZIC media systems.

    The jukebox IS a container: players drop cassettes, vinyl records and
    CD albums straight into it through the loot window.  The playlist is
    built live from whatever playable media is inside the container:
      - CD albums   -> every track of the album (SWTCCDAlbums)
      - cassettes   -> one track            (GlobalMusic)
      - vinyl       -> one track            (GlobalMusic)

    Shared state lives on the object's modData (md.tmJukebox) and is synced
    with obj:transmitModData(), same pattern as the HiFi world device:
      md.tmJukebox = {
          isPlaying = bool,
          volume    = 0..1  (device volume, shared),
          playIndex = int   (1-based index into the built playlist),
      }
]]

require "TCMusicDefenitions"

TMJukebox = TMJukebox or {}

TMJukebox.CONTAINER_TYPE   = "tm_jukebox"
TMJukebox.DEFAULT_CAPACITY = 100
TMJukebox.DEFAULT_VOLUME   = 0.6

--- Container capacity, sandbox-configurable. The engine hard-caps
--- ItemContainer capacity at 100 (setCapacity WARNs and rejects above it).
function TMJukebox.getCapacity()
    local cap = SandboxVars and SandboxVars.PZTrueMusicSandbox
        and SandboxVars.PZTrueMusicSandbox.JukeboxCapacity or TMJukebox.DEFAULT_CAPACITY
    if type(cap) ~= "number" then cap = TMJukebox.DEFAULT_CAPACITY end
    if cap < 1 then cap = 1 end
    if cap > 100 then cap = 100 end
    return cap
end

------------------------------------------------------------------------
--  Object detection
------------------------------------------------------------------------

--- Vanilla map jukebox tile (sprite property CustomName == "Jukebox")
--- that has not yet been converted into a container jukebox.
function TMJukebox.isVanillaJukebox(obj)
    if not obj or obj:getContainer() then return false end
    local sprite = obj.getSprite and obj:getSprite() or nil
    if not sprite then return false end
    local props = sprite:getProperties()
    return props ~= nil and props:get("CustomName") == "Jukebox"
end

--- Already-converted TM jukebox (IsoThumpable with our container type).
function TMJukebox.isConverted(obj)
    if not obj then return false end
    local c = obj.getContainer and obj:getContainer() or nil
    return c ~= nil and c:getType() == TMJukebox.CONTAINER_TYPE
end

function TMJukebox.isJukebox(obj)
    return TMJukebox.isConverted(obj) or TMJukebox.isVanillaJukebox(obj)
end

--- First jukebox object (vanilla or converted) found on a square.
function TMJukebox.findOnSquare(square)
    if not square then return nil end
    local objects = square:getObjects()
    if not objects then return nil end
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if TMJukebox.isJukebox(obj) then
            if TMJukebox.isConverted(obj) then
                TMJukebox.applyContainerSettings(obj)
            end
            return obj
        end
    end
    return nil
end

------------------------------------------------------------------------
--  Container rules
------------------------------------------------------------------------

-- ONLY the three media types (cassette / vinyl / CD album) may go in.
-- Registered on the global AcceptItemFunction table; the engine calls it
-- by name for every attempted transfer into the container.
function TMJukebox.registerAcceptItem()
    AcceptItemFunction = AcceptItemFunction or {}
    function AcceptItemFunction.TM_Jukebox(container, item)
        return TMJukebox.isPlayableMedia(item)
    end
end
TMJukebox.registerAcceptItem()
-- Vanilla server/Items/AcceptItemFunction.lua does `AcceptItemFunction = {}`
-- (no `or {}`) and loads AFTER shared lua, wiping our entry - re-register
-- once everything has loaded. OnGameBoot never fires on a dedicated server,
-- so hook every relevant lifecycle event (server/TMJukeboxServer.lua also
-- re-registers at load time, after the vanilla wipe).
Events.OnGameBoot.Add(TMJukebox.registerAcceptItem)
Events.OnInitGlobalModData.Add(TMJukebox.registerAcceptItem)
if Events.OnServerStarted then
    Events.OnServerStarted.Add(TMJukebox.registerAcceptItem)
end

--- (Re)apply type, capacity and the accept-item lock.  The accept
--- function is not persisted with the save, so this runs every time a
--- jukebox is touched (context menu, window open, audio registration).
function TMJukebox.applyContainerSettings(obj)
    local container = obj and obj.getContainer and obj:getContainer() or nil
    if not container then return end
    TMJukebox.registerAcceptItem()   -- self-heal: never point at a missing fn
    if container:getType() ~= TMJukebox.CONTAINER_TYPE then
        container:setType(TMJukebox.CONTAINER_TYPE)
    end
    if container:getCapacity() ~= TMJukebox.getCapacity() then
        container:setCapacity(TMJukebox.getCapacity())
    end
    if container.setAcceptItemFunction then
        container:setAcceptItemFunction("AcceptItemFunction.TM_Jukebox")
    end
end

------------------------------------------------------------------------
--  Shared state
------------------------------------------------------------------------

function TMJukebox.getData(obj)
    local md = obj:getModData()
    if not md.tmJukebox then
        md.tmJukebox = {
            isPlaying = false,
            volume    = TMJukebox.DEFAULT_VOLUME,
            playIndex = 1,
        }
    end
    local d = md.tmJukebox
    if d.volume == nil then d.volume = TMJukebox.DEFAULT_VOLUME end
    if d.playIndex == nil then d.playIndex = 1 end
    if d.queue == nil then d.queue = {} end
    if d.queueMode == nil then d.queueMode = false end
    if d.queuePos == nil then d.queuePos = 0 end
    if d.playSeq == nil then d.playSeq = 0 end
    if d.shuffle == nil then d.shuffle = false end
    if d.shuffleRand == nil then d.shuffleRand = 12345 end
    return d
end

function TMJukebox.transmit(obj)
    if obj and obj.transmitModData then
        obj:transmitModData()
    end
end

------------------------------------------------------------------------
--  Media / playlist
------------------------------------------------------------------------

--- True when the item is playable jukebox media (CD album, cassette or vinyl).
--- IMPORTANT: this also runs SERVER-SIDE (accept-item validation of every
--- transfer into the container). Some add-on music packs register their
--- album/music tables in CLIENT lua only, leaving the dedicated server's
--- SWTCCDAlbums/GlobalMusic empty for those packs - the server would then
--- reject media the client accepted (transfer starts, rolls back instantly).
--- Fall back to the TrueMoozic media naming conventions so client and
--- server always agree.
function TMJukebox.isPlayableMedia(item)
    if not item then return false end
    local itemType = item:getType()
    if SWTCCDAlbums and SWTCCDAlbums[itemType] then return true end
    if GlobalMusic and GlobalMusic[itemType] then return true end
    -- Naming-convention fallback (non-Base modules only).
    local fullType = item.getFullType and item:getFullType() or nil
    if type(fullType) ~= "string" then return false end
    local module = string.match(fullType, "^([^%.]+)%.")
    if not module or module == "Base" then return false end
    local lower = string.lower(itemType)
    -- Exclude devices/cases that contain the media words.
    if string.find(lower, "player", 1, true) or string.find(lower, "case", 1, true)
        or string.find(lower, "bag", 1, true) or string.find(lower, "boombox", 1, true) then
        return false
    end
    if string.find(lower, "cassette", 1, true) then return true end
    if string.find(lower, "vinyl", 1, true) then return true end
    if string.sub(itemType, 1, 3) == "CD_" then return true end
    if string.len(itemType) > 2 and string.sub(itemType, -2) == "CD" then return true end
    return false
end

local function trackTitle(album, track, index)
    local title = track.displayName and getText(track.displayName) or nil
    -- getText returns the raw key when no translation exists.
    if not title or title == track.displayName then
        title = (album.displayName or "CD") .. " - Track " .. index
    end
    return title
end

--- Build the live playlist from the container's contents.
--- Returns an array of { uid, soundName, title, kind }.
--- uid identifies the exact physical media item (+ track for CDs) so
--- duplicate copies of the same song stay distinguishable everywhere.
function TMJukebox.buildPlaylist(obj)
    local playlist = {}
    local container = obj and obj.getContainer and obj:getContainer() or nil
    if not container then return playlist end
    local items = container:getItems()
    if not items then return playlist end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local itemType = item:getType()
        local itemId = tostring(item:getID())
        local album = SWTCCDAlbums and SWTCCDAlbums[itemType] or nil
        if album and album.tracks then
            -- Scratched CD: carry the item's live scratch state onto every
            -- track entry so playback gets the forced skips + skip sounds.
            local scratch = nil
            local imd = item:getModData()
            if imd and imd.TMScratch and imd.TMScratch > 0 then
                scratch = {
                    scratch         = imd.TMScratch,
                    scratchDelay    = imd.TMScratchDelay,
                    scratchSafeRoll = imd.TMScratchSafeRoll,
                }
            end
            for t = 1, #album.tracks do
                local track = album.tracks[t]
                if track and track.soundName then
                    playlist[#playlist + 1] = {
                        uid         = itemId .. ":" .. t,
                        soundName   = track.soundName,
                        title       = trackTitle(album, track, t),
                        kind        = "cd",
                        scratch     = scratch,
                        trackIndex  = t,
                        totalTracks = #album.tracks,
                    }
                end
            end
        elseif GlobalMusic and GlobalMusic[itemType] then
            -- Cassette / vinyl: the sound script is named after the item type.
            local kind = "cassette"
            if string.find(string.lower(itemType), "vinyl", 1, true) then
                kind = "vinyl"
            end
            playlist[#playlist + 1] = {
                uid       = itemId,
                soundName = itemType,
                title     = item:getName(),
                kind      = kind,
            }
        end
    end
    return playlist
end

--- Display label for a playlist entry: title + media type (+ scratched).
function TMJukebox.entryLabel(entry)
    if not entry then return "" end
    local tag
    if entry.kind == "cd" then
        tag = getText("IGUI_TM_Jukebox_MediaCD")
    elseif entry.kind == "vinyl" then
        tag = getText("IGUI_TM_Jukebox_MediaVinyl")
    else
        tag = getText("IGUI_TM_Jukebox_MediaCassette")
    end
    if entry.scratch then
        tag = tag .. ", " .. getText("IGUI_TM_Jukebox_Scratched")
    end
    return (entry.title or entry.soundName or "?") .. "  [" .. tag .. "]"
end

------------------------------------------------------------------------
--  Queue
------------------------------------------------------------------------

function TMJukebox.findPlaylistIndex(playlist, uid)
    if not uid then return nil end
    for i = 1, #playlist do
        if playlist[i].uid == uid then return i end
    end
    return nil
end

--- Playlist index for a queue entry. Matches by uid (exact physical media
--- item); falls back to soundName for queue entries saved before uids.
function TMJukebox.findQueueEntryIndex(playlist, qEntry)
    if not qEntry then return nil end
    if qEntry.uid then
        local idx = TMJukebox.findPlaylistIndex(playlist, qEntry.uid)
        if idx then return idx end
        return nil
    end
    for i = 1, #playlist do
        if playlist[i].soundName == qEntry.soundName then return i end
    end
    return nil
end

--- Drop queue entries whose media is no longer in the box.
--- Returns true if the queue changed.
function TMJukebox.pruneQueue(d, playlist)
    if not d.queue or #d.queue == 0 then return false end
    local changed = false
    for i = #d.queue, 1, -1 do
        if not TMJukebox.findQueueEntryIndex(playlist, d.queue[i]) then
            table.remove(d.queue, i)
            if (d.queuePos or 0) >= i then
                d.queuePos = (d.queuePos or 0) - 1
            end
            changed = true
        end
    end
    if (d.queuePos or 0) < 0 then d.queuePos = 0 end
    if (d.queuePos or 0) > #d.queue then d.queuePos = 0 end
    return changed
end

--- Deterministic shared shuffle: a Park-Miller LCG whose state lives in
--- the synced modData (d.shuffleRand). Every client that advances a track
--- reads the same state and computes the SAME next pick, so simultaneous
--- advances on different clients converge instead of fighting (no
--- ZombRand here on purpose - per-client randomness would desync MP).
--- All intermediate values stay < 2^45, exact in Kahlua doubles.
function TMJukebox.shuffleNext(d, n, current)
    local r = d.shuffleRand or 12345
    r = (r * 16807) % 2147483647
    if r <= 0 then r = 12345 end
    d.shuffleRand = r
    local pick = (r % n) + 1
    -- Don't repeat the track that just played (n > 1 guaranteed by caller).
    if pick == current then pick = (pick % n) + 1 end
    return pick
end

--- Advance to the next (dir=1) or previous (dir=-1) track.
--- In queue mode with a non-empty queue this walks the queue (looping);
--- otherwise it walks the full playlist (looping). With shuffle on, the
--- destination is a deterministic shared random pick instead.
--- Always bumps playSeq so playback restarts even when the destination
--- track has the same playlist index / sound name as the current one.
function TMJukebox.stepTrack(d, playlist, dir)
    dir = dir or 1
    d.playSeq = (d.playSeq or 0) + 1
    if d.queueMode and d.queue and #d.queue > 0 then
        local n = #d.queue
        local qp
        if d.shuffle and n > 1 then
            qp = TMJukebox.shuffleNext(d, n, d.queuePos or 0)
        else
            qp = ((((d.queuePos or 0) - 1 + dir) % n) + n) % n + 1
        end
        d.queuePos = qp
        local idx = TMJukebox.findQueueEntryIndex(playlist, d.queue[qp])
        if idx then
            d.playIndex = idx
            return
        end
    end
    local n = #playlist
    if n == 0 then return end
    if d.shuffle and n > 1 then
        d.playIndex = TMJukebox.shuffleNext(d, n, d.playIndex or 1)
    else
        d.playIndex = ((((d.playIndex or 1) - 1 + dir) % n) + n) % n + 1
    end
end

------------------------------------------------------------------------
--  Speaker support
------------------------------------------------------------------------

--- Currently-playing song of a jukebox at x,y,z, for the TM speaker
--- system.  Returns { soundName, baseVol } like the HiFi reader, or nil.
function TMJukebox.getPlayingSong(x, y, z)
    local sq = getCell() and getCell():getGridSquare(x, y, z) or nil
    local obj = sq and TMJukebox.findOnSquare(sq) or nil
    if not obj or not TMJukebox.isConverted(obj) then return nil end
    local md = obj:getModData()
    local d = md.tmJukebox
    if not d or not d.isPlaying then return nil end
    local playlist = TMJukebox.buildPlaylist(obj)
    local entry = playlist[d.playIndex or 1]
    if not entry then return nil end
    return { soundName = entry.soundName, baseVol = (d.volume or TMJukebox.DEFAULT_VOLUME) * 2.0 }
end

------------------------------------------------------------------------
--  Power
------------------------------------------------------------------------

--- Grid power (pre-shutoff, indoors) or a running generator in range.
function TMJukebox.hasPower(square)
    if not square then return false end
    if square:haveElectricity() then return true end
    if SandboxVars.ElecShutModifier > -1
        and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier
        and not square:isOutside() then
        return true
    end
    return false
end
