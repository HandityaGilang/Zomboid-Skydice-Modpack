

if isClient() then return end

pcall(require, "TCStartWithDevice")
local TrueMCommands = {}
local PROBE = false
if PROBE then
    print("[TMDBG][BOOT][Server] TCServerCommands probe=" .. tostring(PROBE))
end

local function probe(msg)
    if PROBE then
        print("[TMDBG][ServerCmd] " .. tostring(msg))
    end
end

local function stringifyArgs(args)
    if not args then return "{}" end
    local out = {}
    for k, v in pairs(args) do
        out[#out + 1] = tostring(k) .. "=" .. tostring(v)
    end
    table.sort(out)
    return "{" .. table.concat(out, ", ") .. "}"
end

local function findPlayerInventoryItemById(player, itemId)
    if not player or not itemId then return nil, nil end
    local inv = player:getInventory()
    local items = inv and inv:getItems() or nil
    if not items then return inv, nil end
    local wanted = tonumber(itemId)
    if not wanted then return inv, nil end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getID and tonumber(it:getID()) == wanted then
            return inv, it
        end
    end
    return inv, nil
end

local function getNowPlayTable()
    local md = ModData.getOrCreate("trueMusicData")
    md["now_play"] = md["now_play"] or {}
    return md["now_play"]
end

local function resolveWorldMusicId(args)
    if args and args.radioItemID ~= nil and tostring(args.radioItemID) ~= "" then
        return "W:" .. tostring(args.radioItemID)
    end
    
    if args and args.x ~= nil and args.y ~= nil and args.z ~= nil and args.musicId and string.match(tostring(args.musicId), '^#') then
        return "W:C:" .. tostring(args.x) .. "-" .. tostring(args.y) .. "-" .. tostring(args.z)
    end
    if args and args.musicId and tostring(args.musicId) ~= "" then
        return tostring(args.musicId)
    end
    if args and args.x ~= nil and args.y ~= nil and args.z ~= nil then
        return "#" .. tostring(args.x) .. "-" .. tostring(args.y) .. "-" .. tostring(args.z)
    end
    return nil
end

local function isMalformedWorldArgs(args)
    if not args then return false end
    local hasCoords = (args.x ~= nil and args.y ~= nil and args.z ~= nil)
    local hasRadioItem = (args.radioItemID ~= nil and tostring(args.radioItemID) ~= "")
    local hasFallback = (args.musicId and string.match(tostring(args.musicId), '^#'))
    return hasCoords and (not hasRadioItem) and (not hasFallback)
end

local function clearLegacyWorldKeys(nowPlay, keepMusicId, args)
    if not nowPlay or not args then return end
    local keep = keepMusicId and tostring(keepMusicId) or nil
    local radioItemID = args.radioItemID and tostring(args.radioItemID) or nil
    local legacyCoordId = nil
    if args.x ~= nil and args.y ~= nil and args.z ~= nil then
        legacyCoordId = "#" .. tostring(args.x) .. "-" .. tostring(args.y) .. "-" .. tostring(args.z)
    end

    if legacyCoordId and legacyCoordId ~= keep then
        nowPlay[legacyCoordId] = nil
    end

    if radioItemID then
        for k, row in pairs(nowPlay) do
            if k ~= keep and string.sub(tostring(k), 1, 1) == "#" then
                local rowItem = row and row.itemid and tostring(row.itemid) or nil
                if rowItem == radioItemID then
                    nowPlay[k] = nil
                end
            end
        end
    end
end

local function hasJukeboxSourceAt(args)
    
    return true
end

local function clearWorldStateAndTransmit(musicId, args)
    if not musicId then return end
    local nowPlay = getNowPlayTable()
    nowPlay[musicId] = nil
    clearLegacyWorldKeys(nowPlay, musicId, args)
    ModData.transmit("trueMusicData")
end

------------------------------------------------------------
-- World-device state persistence.
-- now_play rows are LIVE audio bookkeeping; the only thing the server
-- actually persists across chunk unloads and restarts is the dropped
-- device ITEM on the floor. Client-side IsoRadio objects are often
-- client-local (the add-object packet can be dropped -> "object is
-- null" WARNs), so every playback/media/volume/power command now stamps
-- the authoritative state onto the world item's modData here on the
-- server. When a client re-streams the chunk and rebuilds the device
-- from the item, the cassette / power / volume are all still there.
------------------------------------------------------------
local NIL_FIELD = "__TM_NIL__"

local function stampWorldDeviceState(args, fields)
    if not args or args.x == nil or args.y == nil or args.z == nil then return end
    local sq = getSquare(args.x, args.y, args.z)
    if not sq then return end
    local wanted = tonumber(args.radioItemID)
    local best = nil
    local wobjs = sq.getWorldObjects and sq:getWorldObjects() or nil
    if wobjs then
        for i = 0, wobjs:size() - 1 do
            local wobj = wobjs:get(i)
            local item = wobj and wobj.getItem and wobj:getItem() or nil
            if item and item.getFullType and TCMusic and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer[item:getFullType()] then
                if wanted and item.getID and tonumber(item:getID()) == wanted then
                    best = item
                    break
                end
                best = best or item
            end
        end
    end
    if best then
        local md = best:getModData()
        md.tcmusic = md.tcmusic or {}
        for k, v in pairs(fields) do
            if v == NIL_FIELD then md.tcmusic[k] = nil else md.tcmusic[k] = v end
        end
    end
    -- Mirror onto the square's IsoRadio when this server has one, and
    -- broadcast so every connected client's copy agrees.
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if instanceof(o, "IsoRadio") then
            local omd = o:getModData()
            omd.tcmusic = omd.tcmusic or {}
            for k, v in pairs(fields) do
                if v == NIL_FIELD then omd.tcmusic[k] = nil else omd.tcmusic[k] = v end
            end
            if best and best.getID then omd.RadioItemID = best:getID() end
            if o.transmitModData then o:transmitModData() end
            break
        end
    end
end

-- Stale radioItemIDs (server-reassigned) make a row's KEY unkillable by
-- the usual musicId lookup: a rebuilt device stops under a NEW key while
-- the old row keeps blaring for everyone. Coordinates don't go stale.
local function clearRowsAtCoords(nowPlay, x, y, z, keepKey)
    if not nowPlay or x == nil or y == nil then return end
    local kill = {}
    for k, row in pairs(nowPlay) do
        if k ~= keepKey and type(row) == "table"
            and tonumber(row.x) == tonumber(x) and tonumber(row.y) == tonumber(y)
            and (row.z == nil or z == nil or tonumber(row.z) == tonumber(z)) then
            kill[#kill + 1] = k
        end
    end
    for i = 1, #kill do
        probe("clearRowsAtCoords removed key=" .. tostring(kill[i]))
        nowPlay[kill[i]] = nil
    end
end

------------------------------------------------------------
-- Server-side write protection.
-- Shared playback state used to trust every client command blindly; the
-- far-cull bug showed that a client acting on bad local information can
-- corrupt state for EVERYONE. Two independent server-side guards now
-- back up the client-side far-trust checks:
--
--  1) Stale-token rejection: automatic stop commands carry the startId of
--     the playback session they observed ending. If the device has since
--     begun a NEWER session (different startId), the stop is about a song
--     that no longer exists - reject it so a laggy client can't kill the
--     new track. User-initiated stops carry no startId and always pass.
--
--  2) Distance validation: only a player close enough to actually hear a
--     device is qualified to report anything about its playback. Stop
--     commands from senders far beyond earshot are dropped. The threshold
--     is looser than the client-side FAR_TRUST_DIST (45) to allow for
--     movement and latency between sending and processing.
------------------------------------------------------------
local SERVER_TRUST_DIST = 60

local function senderTooFar(player, x, y)
    if not player or x == nil or y == nil then return false end
    local dx = (tonumber(player:getX()) or 0) - (tonumber(x) or 0)
    local dy = (tonumber(player:getY()) or 0) - (tonumber(y) or 0)
    return math.sqrt(dx * dx + dy * dy) > SERVER_TRUST_DIST
end

local function staleStartId(argsStartId, currentStartId)
    if argsStartId == nil or tostring(argsStartId) == "" then return false end
    if currentStartId == nil or tostring(currentStartId) == "" then return false end
    return tostring(argsStartId) ~= tostring(currentStartId)
end

------------------------------------------------------------
-- Boot hygiene.
-- now_play rows describe LIVE audio sessions; none of them survived a
-- restart. Portable rows are especially dangerous: they're keyed by
-- onlineID, which the server reassigns after a restart, so a stale row
-- can glue "playing music" to a completely different player. Wipe the
-- portable rows at boot (world W:/# rows are keyed by stable item ids and
-- get refreshed by their device ticks, so they may keep their persistence)
-- and stamp a per-boot token so clients that live through a soft lua
-- reload can flush their local audio caches.
------------------------------------------------------------
Events.OnInitGlobalModData.Add(function()
    local md = ModData.getOrCreate("trueMusicData")
    md["now_play"] = md["now_play"] or {}
    local nowPlay = md["now_play"]
    local stale = {}
    for id in pairs(nowPlay) do
        local key = tostring(id)
        if not (string.match(key, '^W:') or string.match(key, '^#')) then
            stale[#stale + 1] = id
        end
    end
    for i = 1, #stale do
        nowPlay[stale[i]] = nil
    end
    md.bootToken = tostring((getTimestampMs and getTimestampMs()) or 0)
    probe("boot hygiene: cleared " .. tostring(#stale) .. " portable rows, bootToken=" .. tostring(md.bootToken))
end)

------------------------------------------------------------
-- Synchronized start READY-CHECK barrier.
-- Play pressed -> row created with a startId -> server broadcasts
-- 'prepareStart' ("HEY, WE'RE PLAYING THIS") -> every client replies
-- 'readyStart' ("ok, ready") -> when ALL connected clients have answered
-- (or SYNC_ACK_TIMEOUT_MS passes, so one lagging player can't block the
-- music) the server broadcasts 'goStart' ("everyone's ready - START").
-- Clients start the track a fixed small lead after receiving goStart, so
-- the spread between listeners is just their latency difference. Clients
-- also keep a local fallback timer in case goStart is lost entirely.
------------------------------------------------------------
local pendingStarts = {}
local SYNC_ACK_TIMEOUT_MS = 1500

local function sendGoStart(startId)
    local pend = pendingStarts[startId]
    if not pend then return end
    pendingStarts[startId] = nil
    probe("goStart startId=" .. tostring(startId) .. " acks=" .. tostring(pend.ackCount))
    sendServerCommand('truemusic', 'goStart', { startId = startId })
end

local function announceSyncStart(startId)
    if not startId then return end
    -- Handshake disabled (sandbox default): no ready-check round trip; every
    -- client starts on its own short fallback timer instead.
    if not (TCMusic and TCMusic.syncHandshakeEnabled and TCMusic.syncHandshakeEnabled()) then return end
    pendingStarts[startId] = {
        at = getTimestampMs(),
        acks = {},
        ackCount = 0,
    }
    probe("prepareStart startId=" .. tostring(startId))
    sendServerCommand('truemusic', 'prepareStart', { startId = startId })
end

function TrueMCommands.readyStart(player, args)
    local startId = args and args.startId or nil
    local pend = startId and pendingStarts[startId] or nil
    if not pend then return end
    local key = tostring(player and player.getOnlineID and player:getOnlineID() or (player and player:getUsername()) or "?")
    if not pend.acks[key] then
        pend.acks[key] = true
        pend.ackCount = pend.ackCount + 1
    end
    local online = getOnlinePlayers and getOnlinePlayers() or nil
    local total = online and online:size() or 0
    if pend.ackCount >= total then
        sendGoStart(startId)
    end
end

-- One lagging/desynced client must never hold the music hostage: fire the
-- go signal anyway after the ACK window closes.
local function syncStartTimeoutSweep()
    local hasAny = false
    for _ in pairs(pendingStarts) do hasAny = true break end
    if not hasAny then return end
    local now = getTimestampMs()
    for startId, pend in pairs(pendingStarts) do
        if now - pend.at >= SYNC_ACK_TIMEOUT_MS then
            sendGoStart(startId)
        end
    end
end
Events.OnTick.Add(syncStartTimeoutSweep)

function TrueMCommands.setMediaItemToVehiclePart(player, args)
    probe("setMediaItemToVehiclePart player=" .. tostring(player and player:getUsername()) .. " args=" .. stringifyArgs(args))
    local vehicle = getVehicleById(args.vehicle)
    if vehicle then
        local part = vehicle:getPartById("Radio");
        if part then
            if not part:getModData().tcmusic then
                part:getModData().tcmusic = {}
            end
            if not args.isPlaying then
                local cur = part:getModData().tcmusic
                if staleStartId(args.startId, cur and cur.startId) then
                    probe("setMediaItemToVehiclePart rejected reason=stale-startId args=" .. tostring(args.startId) .. " current=" .. tostring(cur and cur.startId))
                    return
                end
                if senderTooFar(player, vehicle:getX(), vehicle:getY()) then
                    probe("setMediaItemToVehiclePart rejected reason=sender-too-far player=" .. tostring(player and player:getUsername()))
                    return
                end
            end
            if args.mediaItem == "nil" then
                part:getModData().tcmusic.mediaItem = nil;
            else
                part:getModData().tcmusic.mediaItem = args.mediaItem;
            end
            part:getModData().tcmusic.isPlaying = args.isPlaying;
            if args.isPlaying and args.startId then
                part:getModData().tcmusic.startId = args.startId
                announceSyncStart(args.startId)
            end
            part:getModData().tcmusic.volume = part:getDeviceData():getDeviceVolume();
            part:getModData().tcmusic.deviceType = "VehiclePart";
            vehicle:transmitPartModData(part);
            vehicle:updateParts();
        end
    else
        noise('no such vehicle id='..tostring(args.vehicle))
    end
end

-- Placed HiFi deck state (md.hifiCD / hifiTape / hifiVinyl). The client's
-- IsoRadio is client-local so its transmitModData is dropped; the deck
-- state is stamped here onto the floor item (persisted) and any server-
-- side IsoRadio (broadcast).
local HIFI_SLOTS = { hifiCD = true, hifiTape = true, hifiVinyl = true }

function TrueMCommands.setHiFiSubtable(player, args)
    args = args or {}
    if not HIFI_SLOTS[args.slot] then return end
    if args.x == nil or args.y == nil then return end
    if senderTooFar(player, args.x, args.y) then
        probe("setHiFiSubtable rejected reason=sender-too-far")
        return
    end
    local sq = getSquare(args.x, args.y, args.z)
    if not sq then return end
    local data = nil
    if (not args.clear) and args.data then
        data = {}
        for k, v in pairs(args.data) do data[k] = v end
        data.isPlaying = (data.isPlaying == true)
    end
    probe("setHiFiSubtable slot=" .. tostring(args.slot) .. " clear=" .. tostring(args.clear == true) .. " player=" .. tostring(player and player:getUsername()))
    -- Floor item (survives chunk unload / restart).
    local wanted = tonumber(args.radioItemID)
    local wobjs = sq.getWorldObjects and sq:getWorldObjects() or nil
    if wobjs then
        local best = nil
        for i = 0, wobjs:size() - 1 do
            local wobj = wobjs:get(i)
            local item = wobj and wobj.getItem and wobj:getItem() or nil
            if item and item.getFullType and TCMusic and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer[item:getFullType()] then
                if wanted and item.getID and tonumber(item:getID()) == wanted then
                    best = item
                    break
                end
                best = best or item
            end
        end
        if best then
            best:getModData()[args.slot] = data
        end
    end
    -- Server-side IsoRadio (broadcasts to every connected client).
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if instanceof(o, "IsoRadio") then
            o:getModData()[args.slot] = data
            if o.transmitModData then o:transmitModData() end
            break
        end
    end
end

function TrueMCommands.deleteWO(player, args)
    probe("deleteWO player=" .. tostring(player and player:getUsername()) .. " args=" .. stringifyArgs(args))
    if senderTooFar(player, args.x, args.y) then
        probe("deleteWO rejected reason=sender-too-far")
        return
    end
    local sqr = getSquare(args.x, args.y, args.z)
    if sqr then
        local objects = sqr:getObjects()
        local objSize = objects:size()
        
        if objSize > 0 then
            for i = 0, objSize - 1 do
                local object = objects:get(i)
                if instanceof(object, "IsoWaveSignal") then
                    local sprite = object:getSprite()
                    if sprite then
                        local name_sprite = sprite:getName()
                        if name_sprite == args.nameSprite then
                            sqr:transmitRemoveItemFromSquare(object)
                            break
                        end
                    end
                end
            end
        end
    else
        noise('no such square')
    end
end

-- Device status text relay: the sender shows its line locally, then asks
-- the server to re-broadcast the semantic KEY so nearby clients render it
-- in their own language. Keys are whitelisted and args truncated so a
-- hostile client can't use this as a free chat/spam channel.
local SPEECH_KEYS = {
    Handshake = true, Waiting = true, Playing = true,
    StopSend = true, StopDone = true, Stopped = true,
    PowerOn = true, PowerOff = true,
    Insert = true, Eject = true, Next = true, Prev = true,
}

function TrueMCommands.speech(player, args)
    if not player or not args or not SPEECH_KEYS[args.key] then return end
    local arg = args.arg
    if arg ~= nil then
        arg = tostring(arg)
        if #arg > 64 then arg = string.sub(arg, 1, 64) end
    end
    local delay = tonumber(args.delay)
    if delay and (delay < 0 or delay > 5000) then delay = nil end
    sendServerCommand('truemusic', 'speech', {
        key = args.key,
        arg = arg,
        delay = delay,
        oid = player.getOnlineID and player:getOnlineID() or nil,
        x = tonumber(args.x), y = tonumber(args.y), z = tonumber(args.z),
    })
end

TrueMCommands.OnClientCommand = function(module, command, player, args)
    if module ~= 'truemusic' then
        return
    end
    probe("OnClientCommand module=" .. tostring(module) .. " command=" .. tostring(command) .. " player=" .. tostring(player and player:getUsername()) .. " args=" .. stringifyArgs(args))
    if TrueMCommands[command] then
        args = args or {}
        TrueMCommands[command](player, args)
    else
        probe("unknown-command command=" .. tostring(command))
    end
end

function TrueMCommands.RequestStartDevice(player, _args)
    probe("RequestStartDevice player=" .. tostring(player and player:getUsername()))
    if TCStartWithDevice and TCStartWithDevice.RequestStartDevice then
        TCStartWithDevice.RequestStartDevice(player)
    elseif TCStartWithDevice and TCStartWithDevice.GiveStartDevice then
        TCStartWithDevice.GiveStartDevice(player)
    end
end

function TrueMCommands.setVinylAlbumState(player, args)
    args = args or {}
    probe("setVinylAlbumState player=" .. tostring(player and player:getUsername()) .. " args=" .. stringifyArgs(args))
    local inv, album = findPlayerInventoryItemById(player, args.albumItemId)
    if not inv or not album then
        probe("setVinylAlbumState skipped reason=album-not-found-in-player-inventory albumItemId=" .. tostring(args.albumItemId))
        return
    end

    local md = album:getModData()
    md.tmVinylAlbum = md.tmVinylAlbum or {}
    local state = md.tmVinylAlbum
    if args.baseDisplayName ~= nil then state.baseDisplayName = tostring(args.baseDisplayName) end
    if args.matchingVinylFullType ~= nil then state.matchingVinylFullType = tostring(args.matchingVinylFullType) end
    state.empty = args.empty == true

    local base = state.baseDisplayName or album:getDisplayName() or "Vinyl Album"
    local label = state.empty and (base .. " (Empty)") or base
    if album.setName then
        album:setName(label)
    elseif album.setCustomName then
        album:setCustomName(label)
    end

    if args.grantVinyl and args.vinylFullType and args.vinylFullType ~= "" then
        local added = inv:AddItem(args.vinylFullType)
        if added and sendAddItemToContainer then
            sendAddItemToContainer(inv, added)
        end
        probe("setVinylAlbumState grantVinyl fullType=" .. tostring(args.vinylFullType) .. " added=" .. tostring(added ~= nil))
    end

    if args.consumeVinylItemId or args.consumeVinylFullType then
        local consume = nil
        if args.consumeVinylItemId then
            local _, byId = findPlayerInventoryItemById(player, args.consumeVinylItemId)
            consume = byId
        end
        if (not consume) and args.consumeVinylFullType and args.consumeVinylFullType ~= "" then
            local items = inv:getItems()
            for i = 0, items:size() - 1 do
                local it = items:get(i)
                if it and it.getFullType and it:getFullType() == args.consumeVinylFullType then
                    consume = it
                    break
                end
            end
        end
        if consume then
            if sendRemoveItemFromContainer then
                sendRemoveItemFromContainer(inv, consume)
            end
            inv:DoRemoveItem(consume)
            probe("setVinylAlbumState consumeVinyl removed=true")
        else
            probe("setVinylAlbumState consumeVinyl removed=false")
        end
    end

    if album.transmitModData then
        album:transmitModData()
    end
end

-- Server-authoritative portable (held boombox/walkman) now_play row.
-- The client mirrors its own row here after local mutation; the server merges
-- and broadcasts so every other client hears (or stops hearing) it.
-- ALSO stamps ABSOLUTE playback state onto the server's copy of the device
-- item modData. This is critical: the old server-side action complete*
-- TOGGLED the server copy, so any client/server disagreement flipped the two
-- copies in opposite directions forever (play/stop button flap, permanent
-- desync). Absolute writes are idempotent and always converge.
local function isPortableDeviceFullType(ft)
    if not ft then return false end
    if TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[ft] then return true end
    if TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[ft] then return true end
    return false
end

local function stampPortableDeviceState(player, args)
    local inv = player:getInventory()
    local items = inv and inv:getItems() or nil
    if not items then return end
    local wantedId = args.itemid and tonumber(args.itemid) or nil
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getFullType and isPortableDeviceFullType(it:getFullType()) then
            local md = it:getModData()
            md.tcmusic = md.tcmusic or {}
            if wantedId and it.getID and tonumber(it:getID()) == wantedId then
                -- The device this row is about: set absolute state.
                md.tcmusic.isPlaying = (args.isPlaying == true) or nil
                if args.isPlaying and args.musicName then
                    md.tcmusic.mediaItem = args.musicName
                end
                if args.isPlaying and args.startId then
                    md.tcmusic.startId = args.startId
                end
                md.tcmusic.deviceType = md.tcmusic.deviceType or "InventoryItem"
            elseif args.isPlaying then
                -- Only one portable can play per player; clear the others.
                if md.tcmusic.isPlaying then
                    md.tcmusic.isPlaying = nil
                end
            elseif not wantedId then
                -- Stop with no itemid: clear every playing portable.
                if md.tcmusic.isPlaying then
                    md.tcmusic.isPlaying = nil
                end
            end
        end
    end
end

function TrueMCommands.setPortablePlayback(player, args)
    args = args or {}
    if not player then return end
    -- Key derived server-side from the connection; clients can't spoof others' rows.
    local musicId = nil
    if player.getOnlineID then
        local id = tonumber(player:getOnlineID())
        if id and id > 0 then musicId = id end
    end
    if musicId == nil and player.getUsername then
        musicId = player:getUsername()
    end
    if musicId == nil then return end

    probe("setPortablePlayback player=" .. tostring(player:getUsername()) .. " musicId=" .. tostring(musicId) .. " isPlaying=" .. tostring(args.isPlaying) .. " media=" .. tostring(args.musicName))

    -- Keep the server's copy of the device item in sync (absolute, no toggle).
    pcall(stampPortableDeviceState, player, args)

    local nowPlay = getNowPlayTable()
    if args.isPlaying and args.musicName then
        nowPlay[musicId] = {
            volume = args.volume or 1.0,
            headphone = args.headphone == true,
            timestamp = "update",
            musicName = args.musicName,
            itemid = args.itemid,
            startId = args.startId,
        }
        if args.startId then announceSyncStart(args.startId) end
    else
        nowPlay[musicId] = nil
    end
    ModData.transmit("trueMusicData")
end

function TrueMCommands.setWorldDeviceMedia(player, args)
    args = args or {}
    if isMalformedWorldArgs(args) then
        probe("setWorldDeviceMedia skipped reason=missing-radioItemID args=" .. stringifyArgs(args))
        return
    end
    local musicId = resolveWorldMusicId(args)
    probe("setWorldDeviceMedia player=" .. tostring(player and player:getUsername()) .. " musicId=" .. tostring(musicId) .. " media=" .. tostring(args.media))
    if not musicId then return end
    if senderTooFar(player, args.x, args.y) then
        probe("setWorldDeviceMedia rejected reason=sender-too-far")
        return
    end
    
    local nowPlay = getNowPlayTable()
    clearLegacyWorldKeys(nowPlay, musicId, args)
    local row = nowPlay[musicId] or {}
    row.musicName = args.media
    row.timestamp = "update"
    row.x = args.x
    row.y = args.y
    row.z = args.z
    row.itemid = args.radioItemID or row.itemid
    -- Media changes do not start playback.
    row.isPlaying = (args.isPlaying == true)
    nowPlay[musicId] = row
    -- Persist onto the device item so the cassette survives chunk reload.
    stampWorldDeviceState(args, {
        mediaItem = args.media or NIL_FIELD,
        isPlaying = (args.isPlaying == true),
    })
    if args.media == nil then
        -- Eject also kills any live row for this device, stale keys included.
        nowPlay[musicId] = nil
        clearRowsAtCoords(nowPlay, args.x, args.y, args.z, nil)
    end
    ModData.transmit("trueMusicData")
end

function TrueMCommands.setWorldDeviceVolume(player, args)
    args = args or {}
    if isMalformedWorldArgs(args) then
        probe("setWorldDeviceVolume skipped reason=missing-radioItemID args=" .. stringifyArgs(args))
        return
    end
    local musicId = resolveWorldMusicId(args)
    probe("setWorldDeviceVolume player=" .. tostring(player and player:getUsername()) .. " musicId=" .. tostring(musicId) .. " volume=" .. tostring(args.volume))
    if not musicId then return end
    if senderTooFar(player, args.x, args.y) then
        probe("setWorldDeviceVolume rejected reason=sender-too-far")
        return
    end
    
    local nowPlay = getNowPlayTable()
    clearLegacyWorldKeys(nowPlay, musicId, args)
    local row = nowPlay[musicId]
    if row then
        row.volume = args.volume
        row.timestamp = "update"
        nowPlay[musicId] = row
        ModData.transmit("trueMusicData")
    end
    stampWorldDeviceState(args, { volume = args.volume })
end

function TrueMCommands.setWorldDevicePlayback(player, args)
    args = args or {}
    if isMalformedWorldArgs(args) then
        probe("setWorldDevicePlayback skipped reason=missing-radioItemID args=" .. stringifyArgs(args))
        return
    end
    local musicId = resolveWorldMusicId(args)
    probe("setWorldDevicePlayback player=" .. tostring(player and player:getUsername()) .. " musicId=" .. tostring(musicId) .. " isPlaying=" .. tostring(args.isPlaying) .. " media=" .. tostring(args.media))
    if not musicId then return end
    
    local nowPlay = getNowPlayTable()
    if args.isPlaying then
        clearLegacyWorldKeys(nowPlay, musicId, args)
        local row = nowPlay[musicId] or {}
        row.isPlaying = true
        row.volume = args.volume or row.volume or 1.0
        row.headphone = false
        row.timestamp = "update"
        row.musicName = args.media or row.musicName
        row.x = args.x
        row.y = args.y
        row.z = args.z
        row.itemid = args.radioItemID or row.itemid
        row.startId = args.startId or row.startId
        nowPlay[musicId] = row
        -- Playing implies powered on with this media - persist onto the item.
        stampWorldDeviceState(args, {
            isPlaying = true,
            turnedOn = true,
            mediaItem = args.media or NIL_FIELD,
            volume = args.volume,
        })
        if args.startId then announceSyncStart(args.startId) end
    else
        local row = nowPlay[musicId]
        if row then
            if staleStartId(args.startId, row.startId) then
                probe("setWorldDevicePlayback stop rejected reason=stale-startId args=" .. tostring(args.startId) .. " current=" .. tostring(row.startId))
                return
            end
            if senderTooFar(player, row.x or args.x, row.y or args.y) then
                probe("setWorldDevicePlayback stop rejected reason=sender-too-far player=" .. tostring(player and player:getUsername()))
                return
            end
        else
            if senderTooFar(player, args.x, args.y) then
                probe("setWorldDevicePlayback stop rejected reason=sender-too-far-no-row")
                return
            end
        end
        nowPlay[musicId] = nil
        clearLegacyWorldKeys(nowPlay, musicId, args)
        -- A rebuilt device stops under a NEW key while the original row
        -- (stale item-id key) keeps playing for everyone: kill by coords.
        clearRowsAtCoords(nowPlay, args.x, args.y, args.z, nil)
        stampWorldDeviceState(args, { isPlaying = false })
    end
    ModData.transmit("trueMusicData")
end

-- Placed-device power switch. Was previously never sent to the server at
-- all: the ON/OFF flip lived only on the acting client and evaporated on
-- chunk reload.
function TrueMCommands.setWorldDevicePower(player, args)
    args = args or {}
    probe("setWorldDevicePower player=" .. tostring(player and player:getUsername()) .. " on=" .. tostring(args.turnedOn) .. " x=" .. tostring(args.x) .. " y=" .. tostring(args.y))
    if args.x == nil or args.y == nil then return end
    if senderTooFar(player, args.x, args.y) then
        probe("setWorldDevicePower rejected reason=sender-too-far")
        return
    end
    local on = (args.turnedOn == true)
    local fields = { turnedOn = on }
    if not on then fields.isPlaying = false end
    stampWorldDeviceState(args, fields)
    if not on then
        -- Power off kills playback for every listener.
        local nowPlay = getNowPlayTable()
        clearRowsAtCoords(nowPlay, args.x, args.y, args.z, nil)
        ModData.transmit("trueMusicData")
    end
end

function TrueMCommands.TakeCDOut(player, args)
    args = args or {}
    if not player then return end
    local inv, caseItem = findPlayerInventoryItemById(player, args.caseItemId)
    if not inv or not caseItem then
        probe("TakeCDOut: case not found id=" .. tostring(args.caseItemId))
        return
    end
    local md = caseItem:getModData()
    local albumFt = md and md.tc_cdcase_album or nil
    if not albumFt or albumFt == "" then
        probe("TakeCDOut: case has no album stored")
        return
    end
    -- Validate the album item still exists in the script DB.
    local sm = getScriptManager()
    if sm and sm.FindItem and not sm:FindItem(albumFt) then
        probe("TakeCDOut: album fulltype not found in scripts: " .. tostring(albumFt))
        md.tc_cdcase_album = nil
        if TC_CDCase_UpdateName then TC_CDCase_UpdateName(caseItem) end
        return
    end
    local added = inv:AddItem(albumFt)
    if added then
        -- Restore the scratch state (data + name label) captured when the CD
        -- was put in, BEFORE broadcasting the item to the client.
        if TCMusic and TCMusic.applyScratchSnapshot then
            TCMusic.applyScratchSnapshot(added, md.tc_cdcase_scratch)
        end
        if sendAddItemToContainer then
            sendAddItemToContainer(inv, added)
        end
    end
    md.tc_cdcase_album = nil
    md.tc_cdcase_scratch = nil
    if TC_CDCase_UpdateName then
        TC_CDCase_UpdateName(caseItem)
    elseif caseItem.setName then
        caseItem:setName("CD Case - empty")
    end
    probe("TakeCDOut: gave album " .. tostring(albumFt) .. " to " .. tostring(player:getUsername()))
end

local function isCDAlbumFullType(ft)
    if type(ft) ~= "string" or ft == "" then return false end
    local _, name = ft:match("^([^%.]+)%.(.+)$")
    if not name then name = ft end
    return name:find("^CD_") ~= nil and name ~= "CDCase" and name ~= "CDCarryingCase"
end

-- A player or zombie stepped on a CD lying on the ground: raise its scratch
-- tier (0 -> 25 -> 50 -> 100). Authoritative on the server so the damage is
-- what the player gets when the CD is picked up.
function TrueMCommands.stompCD(player, args)
    args = args or {}
    if not args.x or not args.y or not args.z or not args.itemId then return end
    if senderTooFar(player, args.x, args.y) then return end
    local sq = getSquare(args.x, args.y, args.z)
    if not sq or not sq.getWorldObjects then return end
    local wobjs = sq:getWorldObjects()
    if not wobjs then return end
    for i = 0, wobjs:size() - 1 do
        local wobj = wobjs:get(i)
        if instanceof(wobj, "IsoWorldInventoryObject") then
            local it = wobj:getItem()
            if it and it.getID and tostring(it:getID()) == tostring(args.itemId)
                and TCMusic and TCMusic.isScratchableCDItem and TCMusic.isScratchableCDItem(it) then
                local md = it:getModData()
                -- Cooldown so standing on a CD doesn't insta-kill it.
                local now = getTimestampMs()
                if md.TMStompMs and (now - md.TMStompMs) < 1500 then return end
                md.TMStompMs = now
                local cur = md.TMScratch or 0
                if cur >= 100 then return end
                local nextTier = TCMusic.getStompNextTier(cur)
                TCMusic.setScratchTier(it, nextTier, true)
                probe("stompCD: item=" .. tostring(args.itemId) .. " " .. tostring(cur) .. " -> " .. tostring(nextTier))
                return
            end
        end
    end
end

function TrueMCommands.PutCDIn(player, args)
    args = args or {}
    if not player then return end
    local inv, caseItem = findPlayerInventoryItemById(player, args.caseItemId)
    if not inv or not caseItem then
        probe("PutCDIn: case not found id=" .. tostring(args.caseItemId))
        return
    end
    local _, albumItem = findPlayerInventoryItemById(player, args.albumItemId)
    if not albumItem then
        probe("PutCDIn: album not found id=" .. tostring(args.albumItemId))
        return
    end
    local md = caseItem:getModData()
    if md.tc_cdcase_album and md.tc_cdcase_album ~= "" then
        probe("PutCDIn: case already contains an album; aborting")
        return
    end
    local albumFt = albumItem.getFullType and albumItem:getFullType() or nil
    if not isCDAlbumFullType(albumFt) then
        probe("PutCDIn: item is not a CD album: " .. tostring(albumFt))
        return
    end
    md.tc_cdcase_album = albumFt
    if TCMusic and TCMusic.captureScratchSnapshot then
        md.tc_cdcase_scratch = TCMusic.captureScratchSnapshot(albumItem)
    end
    inv:DoRemoveItem(albumItem)
    if sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(inv, albumItem)
    end
    if TC_CDCase_UpdateName then
        TC_CDCase_UpdateName(caseItem)
    elseif caseItem.setName then
        caseItem:setName("CD Case - " .. tostring(albumFt))
    end
    probe("PutCDIn: stored " .. tostring(albumFt) .. " in case " .. tostring(args.caseItemId))
end

Events.OnClientCommand.Add(TrueMCommands.OnClientCommand)




