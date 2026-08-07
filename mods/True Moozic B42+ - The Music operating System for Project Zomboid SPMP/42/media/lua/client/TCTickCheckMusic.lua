require "TCMusicClientFunctions"

local localWorldEmitterTable = TCMusic.worldEmitters
local localPlayerMusicTable = {}
local localVehicleMusicTable = {}
local PROBE = false
local BUILD_TAG = "2026-02-21-probeA"
if PROBE then
    print("[TMDBG][BOOT][Client] TCTickCheckMusic tag=" .. tostring(BUILD_TAG) .. " probe=" .. tostring(PROBE))
end
local function probe(msg)
    if PROBE then
        print("[TMDBG][TickClient] " .. tostring(msg))
    end
end
if PROBE then
    print("[TMDBG][Build] TCTickCheckMusic loaded tag=" .. BUILD_TAG .. " probe=" .. tostring(PROBE))
end

-- Audio-silence debug logs (toggled from sandbox option: PZTrueMoozicDebug page → AudioSilenceDebug)
-- Throttled: identical event types only emit once per AUDIO_DBG_INTERVAL_MS to
-- prevent log flooding from per-tick checks. The throttle key is the message
-- prefix up to the first "=" or numeric/id field, so distinct events still log.
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

local HEAR_RADIUS = 100
local FADE_RADIUS = 80

-- Music sound scripts now use distanceMax = 500 so the ENGINE never kills a
-- far (silent) copy inside the loaded world - that's what makes mid-song
-- fade-in on approach possible. Side effect: FMOD's own rolloff is nearly
-- flat within hearing range, so vehicle sources (which used to lean on it)
-- need the mod's 80->100 tile fade applied manually.
local function vehicleDistanceFade(vehicle)
    local p = getPlayer()
    if not p or not vehicle then return 1 end
    local dx = p:getX() - vehicle:getX()
    local dy = p:getY() - vehicle:getY()
    local d = math.sqrt(dx * dx + dy * dy)
    if d <= FADE_RADIUS then return 1 end
    if d >= HEAR_RADIUS then return 0 end
    return 1 - (d - FADE_RADIUS) / (HEAR_RADIUS - FADE_RADIUS)
end
local WORLD_TTL_MAX = 300
local worldTTL = {}

local tickControl = 160
local tickStart = 0

------------------------------------------------------------------------
-- Synchronized start ("HEY EVERYONE, WE'RE PLAYING THIS NOW").
-- Ready-check handshake: the server broadcasts 'prepareStart' when a row
-- with a startId is created; every client replies 'readyStart'; once ALL
-- clients answered (or the server's ACK timeout passes) the server
-- broadcasts 'goStart' and everyone starts the track GO_LEAD_MS later -
-- the spread between listeners is just their latency difference.
-- The local timer (SYNC_START_DELAY_MS from row creation, server-aged
-- row.timestamp compensated) is kept as a FALLBACK in case the go signal
-- is lost, and is the only mechanism in singleplayer.
------------------------------------------------------------------------
local SYNC_START_DELAY_MS = TCMusic.SYNC_START_DELAY_MS or 2000
local GO_LEAD_MS = 250
local syncPending = {}   -- musicId -> { startId, at }
local syncStarted = {}   -- musicId -> startId we already started
local syncGo = {}        -- startId -> { at } (goStart received)

-- Returns true when this client may start audio for the row NOW.
-- rowTs is the server-aged row.timestamp (seconds) used to compensate for
-- how long ago the row was actually created; non-numeric values count as 0.
local function syncGate(musicId, startId, rowTs)
    if not startId then return true end          -- legacy row: no sync info
    if syncStarted[musicId] == startId then return true end
    local now = (getTimestampMs and getTimestampMs()) or 0
    local go = syncGo[startId]
    if go and now >= go.at then
        -- Server said "everyone's ready - START".
        syncPending[musicId] = nil
        syncStarted[musicId] = startId
        return true
    end
    local pend = syncPending[musicId]
    if not pend or pend.startId ~= startId then
        -- MP with handshake ON: fallback ceiling while waiting for goStart.
        -- Handshake OFF (sandbox default) and SP: short fixed delay only.
        local baseDelay = (isClient() and TCMusic.syncHandshakeEnabled and TCMusic.syncHandshakeEnabled())
            and SYNC_START_DELAY_MS or 250
        local elapsedMs = (tonumber(rowTs) or 0) * 1000
        local remaining = baseDelay - elapsedMs
        if remaining < 0 then remaining = 0 end
        local at = now + remaining
        -- goStart may have arrived before we ever saw the row.
        if go and go.at < at then at = go.at end
        syncPending[musicId] = { startId = startId, at = at }
        return false
    end
    if now >= pend.at then
        syncPending[musicId] = nil
        syncStarted[musicId] = startId
        return true
    end
    return false
end

------------------------------------------------------------------------
-- Engine distance-cull handling. FMOD kills file sounds beyond the sound
-- script's distanceMax (base packs 120, third-party packs often 50-75); a
-- culled sound reports isPlaying=false, which looks exactly like a track
-- that ended. Beyond FAR_TRUST_DIST we never treat "not playing" as a real
-- stop/end (no server stop commands, no shared-state writes) - we suspend
-- the local handle and resume once the player has actually come closer.
------------------------------------------------------------------------
local FAR_TRUST_DIST = 45
local farCull = {}   -- key -> distance at which the engine culled us

local function distToLocalPlayer(x, y)
    local p = getPlayer()
    if not p or not x or not y then return 0 end
    local dx = p:getX() - x
    local dy = p:getY() - y
    return math.sqrt(dx * dx + dy * dy)
end

-- True while a previously culled source should stay suspended (player has
-- not yet come meaningfully closer than where the cull happened).
local function farCullBlocked(key, x, y)
    local fc = farCull[key]
    if not fc then return false end
    if distToLocalPlayer(x, y) < fc - 5 then
        farCull[key] = nil
        return false
    end
    return true
end

-- Ready-check handshake (client side).
local function onSyncStartServerCommand(module, command, args)
    if module ~= 'truemusic' then return end
    if command == 'prepareStart' then
        -- "HEY, WE'RE PLAYING THIS" -> answer "ok, ready".
        local playerObj = getPlayer()
        if playerObj and args and args.startId then
            sendClientCommand(playerObj, 'truemusic', 'readyStart', { startId = args.startId })
            -- Actor feedback: our own request reached the server's ready-check.
            if TMSpeech and TMSpeech.pendingCueStartId == args.startId then
                TMSpeech.announce(playerObj, "Waiting")
            end
        end
    elseif command == 'goStart' and args and args.startId then
        -- "EVERYONE'S READY - START": start GO_LEAD_MS from now.
        local goAt = ((getTimestampMs and getTimestampMs()) or 0) + GO_LEAD_MS
        syncGo[args.startId] = { at = goAt }
        -- Pull already-scheduled fallback timers forward to the go moment.
        for _, pend in pairs(syncPending) do
            if pend.startId == args.startId and goAt < pend.at then
                pend.at = goAt
            end
        end
        local po = TCMusic.pendingOwnerStart
        if po and po.startId == args.startId and goAt < po.at then
            po.at = goAt
        end
    end
end
if isClient() then
    Events.OnServerCommand.Add(onSyncStartServerCommand)
end

local function TCMusic_GetWorldEmitter(x, y, z)
    if getWorld() and getWorld().getFreeEmitter then
        local e = getWorld():getFreeEmitter(x, y, z)
        if e and e.setPos then e:setPos(x, y, z) end
        return e
    end
    return nil
end

-- Same free-emitter approach but anchored to the vehicle's current position.
-- Must call setPos each tick since vehicles move.
local function TCMusic_GetVehicleEmitter(vehicle)
    if not vehicle then return nil end
    return TCMusic_GetWorldEmitter(vehicle:getX(), vehicle:getY(), vehicle:getZ())
end

local function TCMusic_EmitterPlay(emitter, soundNameOrMediaItem, srcObj)
    if not emitter or not soundNameOrMediaItem then return nil end
    local src = srcObj or IsoObject.new()
    if emitter.playSoundImpl then
        local id = emitter:playSoundImpl(soundNameOrMediaItem, src)
        if id and id ~= 0 then return id end
    end
    if emitter.playSound then
        local id = emitter:playSound(soundNameOrMediaItem)
        if id and id ~= 0 then return id end
    end
    return nil
end

local function TCMusic_EmitterSetVolume(emitter, id, vol)
    if not emitter then return end
    if emitter.setVolume and id then
        emitter:setVolume(id, vol)
    elseif emitter.setVolumeAll then
        emitter:setVolumeAll(vol)
    end
end

local function TCMusic_EmitterStop(emitter, id)
    if not emitter then return end
    if emitter.stopSound and id then
        emitter:stopSound(id)
    elseif emitter.stopAll then
        emitter:stopAll()
    end
end

local function TCMusic_EmitterIsPlaying(emitter, id)
    if not emitter or not id then return false end
    if emitter.isPlaying then
        return emitter:isPlaying(id)
    end
    return false
end

local function TCMusic_ForEachVehicle(callback)
    if not callback then return end
    local cell = getCell()
    if not cell or not cell.getVehicles then
        audioDbg("[TMDBG][ForEachVeh] EARLY-EXIT cell=" .. tostring(cell) .. " hasGetVehicles=" .. tostring(cell and cell.getVehicles ~= nil))
        return
    end
    local vehicles = cell:getVehicles()
    if not vehicles then
        audioDbg("[TMDBG][ForEachVeh] EARLY-EXIT vehicles=nil from cell:getVehicles()")
        return
    end

    -- Iterator works for both java.util.List and java.util.Set; prefer it so we
    -- avoid noisy "Tried to call nil" log spam from probing :get() on Sets.
    local okIt, iter = pcall(function() return vehicles:iterator() end)
    if okIt and iter then
        while true do
            local okHas, hasNext = pcall(function() return iter:hasNext() end)
            if not (okHas and hasNext) then break end
            local okN, vehicle = pcall(function() return iter:next() end)
            if okN and vehicle then callback(vehicle) end
        end
        return
    end

    -- Fallback: indexed list.
    local okSize, count = pcall(function() return vehicles:size() end)
    if okSize and type(count) == "number" and count > 0 then
        for i = 0, count - 1 do
            local okV, vehicle = pcall(function() return vehicles:get(i) end)
            if okV and vehicle then callback(vehicle) end
        end
        return
    end

    if type(vehicles) == "table" then
        for _, vehicle in ipairs(vehicles) do
            if vehicle then callback(vehicle) end
        end
        return
    end

    audioDbg("[TMDBG][ForEachVeh] UNKNOWN vehicles type=" .. type(vehicles))
end

local function getPlayerByMusicIdClient(musicId)
    if not musicId then return nil end
    local onlineId = tonumber(musicId)
    if onlineId then
        local p = getPlayerByOnlineID(onlineId)
        if p then return p end
    end
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            if p and p.getUsername and p:getUsername() == tostring(musicId) then
                return p
            end
        end
    end
    for playerNum = 0, getNumActivePlayers() - 1 do
        local p = getSpecificPlayer(playerNum)
        if p and p.getUsername and p:getUsername() == tostring(musicId) then
            return p
        end
    end
    return nil
end

local function stopSiblingWorldEmittersByRadioItemId(currentMusicId, currentServerData, musicServerNowPlay)
    if not currentMusicId or not currentServerData or not musicServerNowPlay then return end
    local radioItemID = currentServerData["radioItemID"]
    if not radioItemID then return end
    radioItemID = tostring(radioItemID)

    for otherMusicId, localData in pairs(localWorldEmitterTable) do
        if otherMusicId ~= currentMusicId then
            local otherServerData = musicServerNowPlay[otherMusicId]
            local otherRadioItemID = otherServerData and otherServerData["radioItemID"]
            if otherRadioItemID and tostring(otherRadioItemID) == radioItemID then
                TCMusic_EmitterStop(localData.emitter, localData.localmusicid)
                localWorldEmitterTable[otherMusicId] = nil
                worldTTL[otherMusicId] = nil
                probe("stop world listener musicId=" .. tostring(otherMusicId) .. " reason=same-radioItemID-as-" .. tostring(currentMusicId))
            end
        end
    end
end

local function buildCanonicalWorldIndex(nowPlay)
    local canonicalByItemId = {}
    local canonicalByCoord = {}
    if not nowPlay then
        return canonicalByItemId, canonicalByCoord
    end

    for id, row in pairs(nowPlay) do
        local musicId = tostring(id)
        if string.match(musicId, '^W:') then
            local rid = (row and (row["itemid"] or row["radioItemID"])) or string.sub(musicId, 3)
            if rid ~= nil and tostring(rid) ~= "" then
                canonicalByItemId[tostring(rid)] = musicId
            end

            local x, y, z = string.match(tostring(musicId), '^#(%-?%d+)[-](%-?%d+)[-](%-?%d+)')
            if x then
                x, y, z = tonumber(x), tonumber(y), tonumber(z)
            elseif row then
                x = tonumber(row["x"])
                y = tonumber(row["y"])
                z = tonumber(row["z"])
            end
            if x ~= nil then
                canonicalByCoord[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)] = musicId
            end
        end
    end

    return canonicalByItemId, canonicalByCoord
end

local function findAttachedItemById(player, itemid)
    if not player or not itemid then return nil end
    local attachedItems = player.getAttachedItems and player:getAttachedItems() or nil
    if not attachedItems then return nil end
    for i = 0, attachedItems:size() - 1 do
        local attached = attachedItems:get(i)
        local attachedItem = attached and attached:getItem() or nil
        if attachedItem and attachedItem.getID and attachedItem:getID() == itemid then
            return attachedItem
        end
    end
    return nil
end

local function isBackAttachedItem(player, item)
    if not player or not item then return false end
    local attachedItems = player.getAttachedItems and player:getAttachedItems() or nil
    if not attachedItems then return false end
    for i = 0, attachedItems:size() - 1 do
        local attached = attachedItems:get(i)
        local attachedItem = attached and attached:getItem() or nil
        if attachedItem == item then
            local loc = attached.getLocation and attached:getLocation() or nil
            return loc == "Big Weapon On Back" or loc == "Big Weapon On Back with Bag" or loc == "Back"
        end
    end
    return false
end

------------------------------------------------------------------------
-- Delayed owner start: when the local player presses Play on a portable,
-- the action only ANNOUNCES the row (TCMusic.pendingOwnerStart holds the
-- start time). This fires the actual local audio once the shared sync
-- delay has elapsed, so the owner starts together with everyone else.
------------------------------------------------------------------------
local function runPendingOwnerStart(pending)
    TCMusic.pendingOwnerStart = nil
    local playerObj = getPlayer()
    if not playerObj or playerObj:isDead() then return end
    -- The client-local session is the play state (item modData is never
    -- written for play/stop, so a server ItemStats echo can't cancel a
    -- scheduled start anymore). Session gone/replaced = start was cancelled.
    local bs = TCMusic.BoomboxSession
    if not bs or bs.itemId ~= pending.itemid or bs.startId ~= pending.startId then return end
    local device = playerObj:getInventory() and playerObj:getInventory():getItemById(pending.itemid) or nil
    if not device then device = findAttachedItemById(playerObj, pending.itemid) end
    if not device then
        -- Device left the player during the sync window: cancel cleanly.
        TCMusic.BoomboxSession = nil
        local musicId = TCMusic.getPortableMusicId and TCMusic.getPortableMusicId(playerObj) or nil
        local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"]
        if musicId and nowPlay[musicId] then
            nowPlay[musicId] = nil
            if isClient() then TCMusic.transmitNowPlay(playerObj) end
        end
        return
    end
    local pmd = playerObj:getModData()
    if pmd.tcmusicid then
        playerObj:getEmitter():stopSound(pmd.tcmusicid)
        pmd.tcmusicid = nil
    end
    local id = playerObj:getEmitter():playSoundImpl(TCMusic.getSoundName(bs.media), playerObj)
    if id and id ~= 0 then
        pmd.tcmusicid = id
        bs.soundId = id
        -- Session volume first (echo-proof), device data as fallback.
        local vol = bs.volume
        if vol == nil then
            local dd = device.getDeviceData and device:getDeviceData() or nil
            vol = (dd and dd:getDeviceVolume()) or 1.0
        end
        vol = TCMusic.getListenVolume and TCMusic.getListenVolume(vol, "I:" .. tostring(pending.itemid)) or vol
        playerObj:getEmitter():setVolume(id, vol * 0.4)
        probe("owner sync-start fired itemId=" .. tostring(pending.itemid) .. " media=" .. tostring(pending.media))
        if TMSpeech then
            TMSpeech.stopHandshakeCue()
            if TMSpeech.pendingCueStartId == pending.startId then TMSpeech.pendingCueStartId = nil end
            TMSpeech.announce(playerObj, "Playing", TMSpeech.mediaLabel(pending.media))
        end
    else
        -- Sound failed to start: retire the session + row so state stays honest.
        TCMusic.BoomboxSession = nil
        local musicId = TCMusic.getPortableMusicId and TCMusic.getPortableMusicId(playerObj) or nil
        local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"]
        if musicId and nowPlay[musicId] then
            nowPlay[musicId] = nil
            if isClient() then TCMusic.transmitNowPlay(playerObj) end
        end
    end
end

------------------------------------------------------------------------
-- Owner-side self-healing for portable (held/worn) devices.
--
-- The local sound handle (player modData tcmusicid), the device item's
-- tcmusic.isPlaying flag and the shared now_play row can fall out of step in
-- MP (server echoes, media pulled mid-song, row timeout). Every tick cycle
-- this reconciles all three:
--   * device says playing but the sound ended  -> clear state everywhere
--     (natural song end; also un-sticks the Stop button)
--   * sound playing but NO device claims it    -> stop the ghost audio
--   * playing fine but the server row vanished -> republish the row so
--     other players keep hearing us (strike-gated to ride out poll races)
------------------------------------------------------------------------
local ownerRowMissStrikes = 0

local function findOwnerPlayingPortable(playerObj)
    local function check(item, requireEquipped)
        if not item or not item.getModData or not item.getFullType then return nil end
        local ft = item:getFullType()
        local isBoombox = TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[ft]
        local isWalkman = TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[ft]
        if not isBoombox and not isWalkman then return nil end
        if requireEquipped and isBoombox and not isWalkman then return nil end
        local tcm = item:getModData().tcmusic
        if tcm and tcm.isPlaying and tcm.mediaItem then return item end
        return nil
    end

    local it = check(playerObj:getPrimaryHandItem(), false)
    if it then return it end
    it = check(playerObj:getSecondaryHandItem(), false)
    if it then return it end

    local attachedItems = playerObj.getAttachedItems and playerObj:getAttachedItems() or nil
    if attachedItems then
        for i = 0, attachedItems:size() - 1 do
            local attached = attachedItems:get(i)
            it = check(attached and attached:getItem() or nil, false)
            if it then return it end
        end
    end

    -- Walkmans keep playing from the main inventory (pocket); boomboxes must
    -- be in hand or on the back, so they're excluded here (requireEquipped).
    local inv = playerObj:getInventory()
    local items = inv and inv:getItems() or nil
    if items then
        for i = 0, items:size() - 1 do
            it = check(items:get(i), true)
            if it then return it end
        end
    end
    return nil
end

local function reconcileOwnerPortable(nowPlay)
    local playerObj = getPlayer()
    if not playerObj or playerObj:isDead() then return end
    local pmd = playerObj:getModData()
    local emitter = playerObj:getEmitter()

    -- WALKMAN SESSION upkeep (local-only playback; state lives OUTSIDE the
    -- item so server item echoes can't roll it back - Tal-style). Fully
    -- self-contained: never mixes with the boombox handle logic below.
    local ws = TCMusic.WalkmanSession
    if ws then
        local wsPlaying = ws.soundId and emitter and emitter:isPlaying(ws.soundId)
        if not wsPlaying then
            -- Natural song end (or handle lost): the session simply ends.
            TCMusic.WalkmanSession = nil
            probe("walkman session ended itemId=" .. tostring(ws.itemId))
        else
            -- The walkman must still be on the player (main inventory,
            -- hands or attached). Dropped/transferred away = stop.
            local item = playerObj:getInventory() and playerObj:getInventory():getItemById(ws.itemId) or nil
            if not item then item = findAttachedItemById(playerObj, ws.itemId) end
            if not item then
                emitter:stopSound(ws.soundId)
                TCMusic.WalkmanSession = nil
                probe("walkman session stopped: device left player itemId=" .. tostring(ws.itemId))
            end
        end
    end

    -- A synchronized start is scheduled but hasn't fired yet: the session
    -- exists while no sound runs ON PURPOSE. Don't treat it as a desync.
    if TCMusic.pendingOwnerStart then return end

    -- BOOMBOX SESSION upkeep (play state lives OUTSIDE the item - Tal-style;
    -- the session owns the sound handle and the shared now_play row).
    local bs = TCMusic.BoomboxSession
    if bs then
        local musicId = TCMusic.getPortableMusicId and TCMusic.getPortableMusicId(playerObj) or nil
        local bsPlaying = bs.soundId and emitter and emitter:isPlaying(bs.soundId)
        if not bsPlaying then
            -- Natural song end (or handle lost): the session ends; retire row.
            TCMusic.BoomboxSession = nil
            if pmd.tcmusicid == bs.soundId then pmd.tcmusicid = nil end
            if musicId ~= nil and nowPlay and nowPlay[musicId] then
                nowPlay[musicId] = nil
                if isClient() then TCMusic.transmitNowPlay(playerObj) end
            end
            probe("boombox session ended itemId=" .. tostring(bs.itemId))
        else
            -- The boombox must still be in hand or on the back.
            local item = playerObj:getInventory() and playerObj:getInventory():getItemById(bs.itemId) or nil
            if not item then item = findAttachedItemById(playerObj, bs.itemId) end
            local carried = item and (playerObj:getPrimaryHandItem() == item
                or playerObj:getSecondaryHandItem() == item
                or isBackAttachedItem(playerObj, item))
            if not carried then
                emitter:stopSound(bs.soundId)
                TCMusic.BoomboxSession = nil
                if pmd.tcmusicid == bs.soundId then pmd.tcmusicid = nil end
                if musicId ~= nil and nowPlay and nowPlay[musicId] then
                    nowPlay[musicId] = nil
                    if isClient() then TCMusic.transmitNowPlay(playerObj) end
                end
                probe("boombox session stopped: device left player itemId=" .. tostring(bs.itemId))
            elseif isClient() and musicId ~= nil and nowPlay and not nowPlay[musicId] then
                -- Playing fine but the server row vanished: republish it so
                -- other players keep hearing us (strike-gated for poll races).
                ownerRowMissStrikes = ownerRowMissStrikes + 1
                if ownerRowMissStrikes >= 3 then
                    local dd = item.getDeviceData and item:getDeviceData() or nil
                    nowPlay[musicId] = {
                        volume = bs.volume or (dd and dd:getDeviceVolume()) or 1.0,
                        headphone = (dd and dd.getHeadphoneType and dd:getHeadphoneType() >= 0) or false,
                        timestamp = "update",
                        musicName = bs.media,
                        itemid = bs.itemId,
                        startId = bs.startId,
                    }
                    TCMusic.transmitNowPlay(playerObj)
                    ownerRowMissStrikes = 0
                    probe("boombox session: republished missing now_play row itemId=" .. tostring(bs.itemId))
                end
            else
                ownerRowMissStrikes = 0
            end
        end
        -- The session owns portable playback; the legacy item-flag logic
        -- below is migration-only and must not fight the session.
        return
    end

    local tmId = pmd.tcmusicid
    local soundPlaying = (tmId and emitter and emitter:isPlaying(tmId)) or false
    local device = findOwnerPlayingPortable(playerObj)
    local musicId = TCMusic.getPortableMusicId and TCMusic.getPortableMusicId(playerObj) or nil

    if device then
        -- Legacy migration: an old build (or a server echo of one) left
        -- isPlaying stamped on the item. Sessions own playback now - clear
        -- the stale flag once (and sync so the server copy matches).
        local tcm = device:getModData().tcmusic
        tcm.isPlaying = false
        if isClient() and device.syncItemFields then
            local cont = device.getContainer and device:getContainer() or nil
            if not (cont and cont.getContainingItem and cont:getContainingItem() ~= nil) then
                device:syncItemFields()
            end
        end
        ownerRowMissStrikes = 0
        probe("owner reconcile: cleared legacy portable isPlaying itemId=" .. tostring(device:getID()))
    else
        ownerRowMissStrikes = 0
        if soundPlaying then
            -- Ghost audio: a portable sound is running but no session owns
            -- it (sessions can't be rolled back, so there is nothing to
            -- heal). Kill it and clear our row.
            emitter:stopSound(tmId)
            pmd.tcmusicid = nil
            pmd.tcWalkmanItemId = nil
            pmd.tcWalkmanMedia = nil
            if musicId ~= nil and nowPlay and nowPlay[musicId] then
                nowPlay[musicId] = nil
                if isClient() then TCMusic.transmitNowPlay(playerObj) end
            end
            probe("owner reconcile: stopped ghost portable audio")
        end
    end
end

local function resolveRemotePortableMusicPlayer(player, serverData)
    if not player or not serverData then return nil, "no-player-or-data" end
    local itemid = serverData["itemid"]
    local secondary = player:getSecondaryHandItem()
    local primary = player:getPrimaryHandItem()

    if secondary and secondary.getID and secondary:getID() == itemid then
        return secondary, "secondary-id-match"
    end
    if primary and primary.getID and primary:getID() == itemid then
        return primary, "primary-id-match"
    end
    if itemid then
        local attached = findAttachedItemById(player, itemid)
        if attached and isBackAttachedItem(player, attached) then
            return attached, "back-id-match"
        end
    end

    -- MP fallback when remote IDs desync.
    local expectedMedia = serverData["musicName"]
    local function candidateMatches(item)
        if not item or not item.getModData or not item.getDeviceData then return false end
        local md = item:getModData()
        local tcm = md and md.tcmusic or nil
        if not tcm or not tcm.isPlaying then return false end
        if tcm.mediaItem ~= expectedMedia then return false end
        local dd = item:getDeviceData()
        return dd and dd:getIsTurnedOn() and (dd:getPower() > 0)
    end

    if candidateMatches(secondary) then
        return secondary, "secondary-media-fallback"
    end
    if candidateMatches(primary) then
        return primary, "primary-media-fallback"
    end

    local attachedItems = player.getAttachedItems and player:getAttachedItems() or nil
    if attachedItems then
        for i = 0, attachedItems:size() - 1 do
            local attached = attachedItems:get(i)
            local attachedItem = attached and attached:getItem() or nil
            if attachedItem and isBackAttachedItem(player, attachedItem) and candidateMatches(attachedItem) then
                return attachedItem, "back-media-fallback"
            end
        end
    end

    return nil, "no-match"
end

local function playerHasPortableByServerData(player, serverData)
    if not player or not serverData then return false end
    local itemid = serverData["itemid"]
    local expectedMedia = serverData["musicName"]
    if not itemid and not expectedMedia then return false end

    local function matches(item)
        if not item then return false end
        if itemid and item.getID and item:getID() == itemid then
            return true
        end
        if expectedMedia and item.getModData then
            local md = item:getModData()
            local tcm = md and md.tcmusic or nil
            if tcm and tcm.isPlaying and tcm.mediaItem == expectedMedia then
                return true
            end
        end
        return false
    end

    if matches(player:getSecondaryHandItem()) then return true end
    if matches(player:getPrimaryHandItem()) then return true end

    local attachedItems = player.getAttachedItems and player:getAttachedItems() or nil
    if attachedItems then
        for i = 0, attachedItems:size() - 1 do
            local attached = attachedItems:get(i)
            local attachedItem = attached and attached:getItem() or nil
            if matches(attachedItem) then
                return true
            end
        end
    end
    return false
end

local function resolvePlayerByServerData(serverData)
    if not serverData then return nil, "no-server-data" end

    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            if playerHasPortableByServerData(p, serverData) then
                return p, "online-item-match"
            end
        end
    end

    for playerNum = 0, getNumActivePlayers() - 1 do
        local p = getSpecificPlayer(playerNum)
        if playerHasPortableByServerData(p, serverData) then
            return p, "local-item-match"
        end
    end

    return nil, "no-item-match"
end

local function TCMusic_FindWorldPlayerAt(x, y, z)
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
        return nil
    end
    local sq = getSquare(x, y, z)
    if not sq then return nil end
    local objs = sq.getObjects and sq:getObjects() or nil
    if not objs then return nil end
    -- Prefer concrete device objects first.
    --[[ JUKEBOX LIFESTYLES DISABLED
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local md = o and o.getModData and o:getModData() or nil
        local tcm = md and md.tcmusic or nil
        if tcm and tcm.deviceType == "IsoObject" and false
            and o.getDeviceData and o:getDeviceData() then
            return o
        end
    end
    JUKEBOX LIFESTYLES DISABLED --]]
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local md = o and o.getModData and o:getModData() or nil
        local tcm = md and md.tcmusic or nil
        --[[ JUKEBOX LIFESTYLES DISABLED
        if tcm and tcm.deviceType == "IsoObject" and false then
            return o
        end
        JUKEBOX LIFESTYLES DISABLED --]]
        if o and instanceof(o, "IsoWaveSignal") then
            local sp = o:getSprite()
            if sp then
                local name = sp:getName()
                if name and TCMusic.WorldMusicPlayer[name] then
                    return o
                end
            end
        end
    end
    return nil
end

local function isLSJukeboxRadioActiveAtOrNear(x, y, z, radius)
    --[[ JUKEBOX LIFESTYLES DISABLED
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
        return false
    end
    local r = tonumber(radius) or 0
    for dx = -r, r do
        for dy = -r, r do
            local sq = getSquare(x + dx, y + dy, z)
            if sq and sq.getObjects then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local obj = objs:get(i)
                    if obj and obj.getSprite and obj.getModData then
                        local spr = obj:getSprite()
                        local props = spr and spr.getProperties and spr:getProperties() or nil
                        local isLSJukebox = props and props.has and props:has("CustomName") and props:get("CustomName") == "Jukebox"
                        if isLSJukebox then
                            local md = obj:getModData()
                            if md and md.OnOff == "on" and md.OnPlay and md.OnPlay ~= "nothing" then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    JUKEBOX LIFESTYLES DISABLED --]]
    return false
end

local function isPlayerInRange(x, y, radius)
    local p = getPlayer()
    if not p then return false end
    return (p:getX() >= x - radius and p:getX() <= x + radius and
            p:getY() >= y - radius and p:getY() <= y + radius)
end

local function calculateVolumeByDistance(x, y, baseVol, volKey)
    local p = getPlayer()
    if not p then return 0 end

    -- Per-device client volume override. baseVol arrives ALREADY scaled by
    -- the 0.4 loudness factor, so the raw 0..1 override must be rescaled
    -- too - substituting it directly made client volume play 2.5x louder
    -- than the same slider position in shared mode.
    if volKey and TCMusic.getClientVolume then
        local ov = TCMusic.getClientVolume(volKey)
        if ov ~= nil then baseVol = ov * 0.4 end
    end

    local dx = math.abs(p:getX() - x)
    local dy = math.abs(p:getY() - y)
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance <= FADE_RADIUS then
        return baseVol
    elseif distance <= HEAR_RADIUS then
        local fadeRange = HEAR_RADIUS - FADE_RADIUS
        local fadeDistance = distance - FADE_RADIUS
        local fadeRatio = 1 - (fadeDistance / fadeRange)
        return baseVol * fadeRatio
    else
        return 0
    end
end

-- Immediately retune a placed device's LIVE playback (placed boombox, vinyl
-- player, world fallback rows). The actual sound runs on a free world
-- emitter owned by this tick engine, so the volume slider / client-volume
-- checkbox would otherwise only take effect on the next heavy cycle.
function TCMusic.applyClientVolumeToWorldDevice(x, y, z, deviceVol)
    if x == nil then return end
    local volKey = TCMusic.worldVolKey and TCMusic.worldVolKey(x, y, z) or nil
    for _, data in pairs(localWorldEmitterTable) do
        if data.x == x and data.y == y and data.z == z and data.emitter and data.localmusicid then
            if deviceVol ~= nil then
                data.baseVolume = deviceVol * 0.4
            end
            local targetVol = calculateVolumeByDistance(x, y, data.baseVolume or 0.4, volKey)
            TCMusic_EmitterSetVolume(data.emitter, data.localmusicid, targetVol)
            data.volume = targetVol
        end
    end
end

local function getWorldCoordsFromServerEntry(musicId, row)
    local x, y, z = string.match(tostring(musicId), '^#(%-?%d+)[-](%-?%d+)[-](%-?%d+)')
    if x then
        return tonumber(x), tonumber(y), tonumber(z)
    end
    if string.match(tostring(musicId), '^W:') and row then
        local dx = tonumber(row["x"])
        local dy = tonumber(row["y"])
        local dz = tonumber(row["z"])
        if dx and dy and dz then
            return dx, dy, dz
        end
    end
    return nil, nil, nil
end

-- Server boot / soft-lua-reload detection. The server stamps a fresh
-- bootToken into trueMusicData each time it initializes; if the token
-- changes while we're connected (admin ran a live lua reload, or a very
-- fast restart), every audio session we're locally driving died
-- server-side. Flush all local playback so nothing ghosts on.
local lastBootToken = nil

local function flushAllLocalPlayback(reason)
    probe("flushAllLocalPlayback reason=" .. tostring(reason))
    for musicId, musicData in pairs(localPlayerMusicTable) do
        local player = isClient() and getPlayerByMusicIdClient(musicId) or getPlayer()
        if player and player:getEmitter() and musicData["localmusicid"] then
            player:getEmitter():stopSound(musicData["localmusicid"])
        end
        localPlayerMusicTable[musicId] = nil
    end
    for id, data in pairs(localWorldEmitterTable) do
        TCMusic_EmitterStop(data.emitter, data.localmusicid)
        localWorldEmitterTable[id] = nil
        worldTTL[id] = nil
    end
    for id, vecache in pairs(localVehicleMusicTable) do
        if vecache["emitter"] and vecache["localmusicid"] then
            vecache["emitter"]:stopSound(vecache["localmusicid"])
        end
        localVehicleMusicTable[id] = nil
    end
    local playerObj = getPlayer()
    if playerObj then
        local pmd = playerObj:getModData()
        if pmd.tcmusicid and playerObj:getEmitter() then
            playerObj:getEmitter():stopSound(pmd.tcmusicid)
            pmd.tcmusicid = nil
        end
        local ws = TCMusic.WalkmanSession
        if ws and ws.soundId and playerObj:getEmitter() then
            playerObj:getEmitter():stopSound(ws.soundId)
        end
        local bs = TCMusic.BoomboxSession
        if bs and bs.soundId and playerObj:getEmitter() then
            playerObj:getEmitter():stopSound(bs.soundId)
        end
        pmd.tcWalkmanItemId = nil
        pmd.tcWalkmanMedia = nil
    end
    TCMusic.WalkmanSession = nil
    TCMusic.BoomboxSession = nil
    TCMusic.pendingOwnerStart = nil
    for k in pairs(syncPending) do syncPending[k] = nil end
    for k in pairs(syncStarted) do syncStarted[k] = nil end
    for k in pairs(syncGo) do syncGo[k] = nil end
    for k in pairs(farCull) do farCull[k] = nil end
end

local function checkBootToken(musicServerTable)
    local token = musicServerTable and musicServerTable.bootToken or nil
    if not token then return end
    if lastBootToken == nil then
        lastBootToken = token
    elseif lastBootToken ~= token then
        lastBootToken = token
        flushAllLocalPlayback("boot-token-changed")
    end
end

function OnRenderTickClientCheckMusic ()
    tickStart = tickStart + 1
    -- Fast lane (every 10 ticks): fire due synchronized starts with sub-second
    -- precision instead of waiting for the heavy 160-tick cycle.
    local forceCycle = false
    if tickStart % 10 == 0 then
        local nowMs = (getTimestampMs and getTimestampMs()) or 0
        local pendingOwner = TCMusic.pendingOwnerStart
        if pendingOwner and nowMs >= pendingOwner.at then
            runPendingOwnerStart(pendingOwner)
        end
        for _, pend in pairs(syncPending) do
            if nowMs >= pend.at then
                forceCycle = true
                break
            end
        end
    end
    if tickStart % tickControl == 0 or forceCycle then
        tickStart = 0
        -- Cache the debug flag once per tick so the heavy string-concat blocks
        -- below can short-circuit cheaply (Lua evaluates concat args BEFORE the
        -- audioDbg call, so the function's own internal check is too late).
        local AUDIO_DBG = SandboxVars and SandboxVars.PZTrueMusicSandbox
            and SandboxVars.PZTrueMusicSandbox.AudioSilenceDebug or false
        if AUDIO_DBG then audioDbg("[TMDBG][TickFired] isClient=" .. tostring(isClient())) end

        if isClient() then
            ModData.request("trueMusicData")
        end

        local vehCount = 0
        TCMusic_ForEachVehicle(function(vehicle)
            vehCount = vehCount + 1
            local vehicleRadio = vehicle:getPartById("Radio")
            local tcm = vehicleRadio and vehicleRadio:getModData().tcmusic or nil
            if AUDIO_DBG then
                audioDbg("[TMDBG][VehScan] veh=" .. tostring(vehicle:getId())
                    .. " hasRadio=" .. tostring(vehicleRadio ~= nil)
                    .. " hasTcm=" .. tostring(tcm ~= nil)
                    .. " media=" .. tostring(tcm and tcm.mediaItem)
                    .. " isPlaying=" .. tostring(tcm and tcm.isPlaying))
            end
            if AUDIO_DBG and tcm and (tcm.mediaItem or tcm.isPlaying) then
                audioDbg("[TMDBG][VehLoop] veh=" .. tostring(vehicle:getId())
                    .. " sqlId=" .. tostring(vehicle:getSqlId())
                    .. " media=" .. tostring(tcm.mediaItem)
                    .. " isPlaying=" .. tostring(tcm.isPlaying)
                    .. " deviceType=" .. tostring(tcm.deviceType)
                    .. " cached=" .. tostring(localVehicleMusicTable[vehicle:getSqlId()] ~= nil))
            end
            if vehicleRadio and vehicleRadio:getModData().tcmusic then
                if vehicleRadio:getModData().tcmusic.mediaItem and vehicleRadio:getModData().tcmusic.isPlaying then
                    local vehicleId = vehicle:getSqlId()
                    local vehSyncKey = "V:" .. tostring(vehicleId)
                    local vehStartId = vehicleRadio:getModData().tcmusic.startId
                    local vecacheExisting = localVehicleMusicTable[vehicleId]
                    if vecacheExisting and vehStartId and vecacheExisting["startId"] ~= vehStartId then
                        -- New synchronized start while already playing: restart in sync.
                        if vecacheExisting["emitter"] and vecacheExisting["localmusicid"] then
                            vecacheExisting["emitter"]:stopSound(vecacheExisting["localmusicid"])
                        end
                        localVehicleMusicTable[vehicleId] = nil
                        vecacheExisting = nil
                    end
                    if not localVehicleMusicTable[vehicleId] and farCullBlocked(vehSyncKey, vehicle:getX(), vehicle:getY()) then
                        -- Engine culled this far vehicle's sound; wait until closer.
                    elseif not localVehicleMusicTable[vehicleId] and not syncGate(vehSyncKey, vehStartId, 0) then
                        -- Waiting for the shared start moment.
                    elseif not localVehicleMusicTable[vehicleId] then
                        -- Only refresh parts when first attaching audio. Calling
                        -- updateParts() every tick on every playing vehicle is
                        -- a heavy per-frame cost.
                        vehicle:updateParts()
                        local vemitter = TCMusic_GetVehicleEmitter(vehicle)
                        local soundName = TCMusic.getSoundName(vehicleRadio:getModData().tcmusic.mediaItem)
                        local deviceData = vehicleRadio:getDeviceData()
                        audioDbg("[TMDBG][VehTick] START vehId=" .. tostring(vehicleId)
                            .. " media=" .. tostring(vehicleRadio:getModData().tcmusic.mediaItem)
                            .. " sound=" .. tostring(soundName)
                            .. " emitter=" .. tostring(vemitter)
                            .. " emitterHasImpl=" .. tostring(vemitter and vemitter.playSoundImpl ~= nil)
                            .. " emitterHasPlay=" .. tostring(vemitter and vemitter.playSound ~= nil)
                            .. " deviceData=" .. tostring(deviceData)
                            .. " devicePower=" .. tostring(deviceData and deviceData.getIsTurnedOn ~= nil and deviceData:getIsTurnedOn())
                            .. " rawDevVol=" .. tostring(deviceData and deviceData.getDeviceVolume ~= nil and deviceData:getDeviceVolume())
                            .. " vehPos=" .. tostring(vehicle:getX()) .. "," .. tostring(vehicle:getY()) .. "," .. tostring(vehicle:getZ())
                            .. " inThisVeh=" .. tostring(vehicle == getPlayer():getVehicle())
                            .. " windowsOpen=" .. tostring(vehicleRadio:getModData().tcmusic.windowsOpen))
                        local id = nil
                        local pathTaken = "none"
                        if vemitter and soundName then
                            if vemitter.playSoundImpl then
                                id = vemitter:playSoundImpl(soundName, vehicle)
                                pathTaken = "playSoundImpl"
                                if id == 0 then id = nil end
                            end
                            if not id and vemitter.playSound then
                                id = vemitter:playSound(soundName)
                                pathTaken = (pathTaken == "playSoundImpl") and "playSoundImpl->playSound" or "playSound"
                                if id == 0 then id = nil end
                            end
                        end
                        audioDbg("[TMDBG][VehTick] playSound handle=" .. tostring(id) .. " path=" .. pathTaken)
                        if not id then
                            audioDbg("[TMDBG][VehTick] FAIL: no playback handle. Causes: missing emitter, unregistered sound name, or emitter.playSound returned 0.")
                        end
                        local vol = deviceData and deviceData:getDeviceVolume() or 0
                        local rawVol = vol
                        vol = TCMusic.getListenVolume and TCMusic.getListenVolume(vol, "V:" .. tostring(vehicleId)) or vol
                        local vol3d = true

                        if vehicle == getPlayer():getVehicle() then
                            vol = vol * 5
                            vol3d = false
                        else
                            if vehicleRadio:getModData().tcmusic.windowsOpen then
                                vol = vol * 3
                            end
                            vol = vol * vehicleDistanceFade(vehicle)
                        end

                        localVehicleMusicTable[vehicleId] = {
                            obj = vehicle,
                            emitter = vemitter,
                            localmusicid = id,
                            volume = vol,
                            startId = vehStartId,
                        }

                        -- Actor feedback: our synchronized start just fired.
                        if TMSpeech and id and TMSpeech.pendingCueStartId == vehStartId then
                            TMSpeech.stopHandshakeCue()
                            TMSpeech.pendingCueStartId = nil
                            TMSpeech.announce(getPlayer(), "Playing", TMSpeech.mediaLabel(vehicleRadio:getModData().tcmusic.mediaItem))
                        end

                        if vemitter and id then
                            local finalVol = vol / 5
                            vemitter:setVolume(id, finalVol)
                            if vemitter.set3D then vemitter:set3D(id, vol3d) end
                            audioDbg("[TMDBG][VehTick] applied setVolume=" .. tostring(finalVol) .. " (rawDev=" .. tostring(rawVol) .. " scaled=" .. tostring(vol) .. ") set3D=" .. tostring(vol3d) .. " isPlayingPostStart=" .. tostring(vemitter.isPlaying and vemitter:isPlaying(id)))
                            if finalVol <= 0 then
                                audioDbg("[TMDBG][VehTick] WARN: final volume <= 0; sound is started but inaudible. Check device volume slider on the radio UI.")
                            end
                        elseif id and not vemitter then
                            audioDbg("[TMDBG][VehTick] WARN: have handle but emitter is nil; cannot setVolume/set3D.")
                        end

                    else
                        local vecache = localVehicleMusicTable[vehicleId]
                        local vehicleEmitter = vecache["emitter"]
                        local locId = vecache["localmusicid"]
                        -- Keep emitter position synced as vehicle moves
                        if vehicleEmitter and vehicleEmitter.setPos then
                            local vobj = vecache["obj"]
                            vehicleEmitter:setPos(vobj:getX(), vobj:getY(), vobj:getZ())
                        end
                        local stillPlaying = vehicleEmitter and locId and vehicleEmitter:isPlaying(locId) or false
                        if vehicleEmitter and locId and stillPlaying then

                            local vol = vehicleRadio:getDeviceData():getDeviceVolume()
                            local rawVol = vol
                            vol = TCMusic.getListenVolume and TCMusic.getListenVolume(vol, "V:" .. tostring(vehicleId)) or vol

                            if vehicle == getPlayer():getVehicle() then
                                vol = vol * 5
                                if vehicleEmitter.set3D then vehicleEmitter:set3D(locId, false) end
                            else
                                if vehicleRadio:getModData().tcmusic.windowsOpen then
                                    vol = vol * 3
                                end
                                vol = vol * vehicleDistanceFade(vehicle)
                                if vehicleEmitter.set3D then vehicleEmitter:set3D(locId, true) end
                            end

                            if vecache["volume"] ~= vol then
                                vehicleEmitter:setVolume(locId, vol / 5)
                                audioDbg("[TMDBG][VehTick] ACTIVE vehId=" .. tostring(vehicleId) .. " volume changed " .. tostring(vecache["volume"]) .. " -> " .. tostring(vol) .. " (rawDev=" .. tostring(rawVol) .. " applied=" .. tostring(vol/5) .. ")")
                                vecache["volume"] = vol
                            end

                            if TMMood then TMMood.reportAt(vehicle:getX(), vehicle:getY(), vol / 5) end

                        else
                            local vobj = vecache["obj"]
                            local vDist = distToLocalPlayer(vobj:getX(), vobj:getY())
                            if vDist > FAR_TRUST_DIST then
                                -- Far: the engine culled our local sound, the radio
                                -- did NOT stop. Suspend locally and re-attach when
                                -- we come closer; never push a stop to the server.
                                audioDbg("[TMDBG][VehTick] ACTIVE vehId=" .. tostring(vehicleId) .. " sound culled by distance (" .. tostring(vDist) .. "); suspending locally")
                                farCull["V:" .. tostring(vehicleId)] = vDist
                                localVehicleMusicTable[vehicleId] = nil
                            else
                                audioDbg("[TMDBG][VehTick] ACTIVE vehId=" .. tostring(vehicleId) .. " sound stopped externally (emitter=" .. tostring(vehicleEmitter) .. " locId=" .. tostring(locId) .. " isPlaying=" .. tostring(stillPlaying) .. "); requesting server stop")
                                sendClientCommand(getPlayer(), 'truemusic', 'setMediaItemToVehiclePart', {
                                    vehicle = vecache["obj"]:getId(),
                                    mediaItem = vecache["obj"]:getPartById("Radio"):getModData().tcmusic.mediaItem,
                                    isPlaying = false,
                                    -- Token of the session we observed ending; the server
                                    -- rejects this stop if a newer session has started.
                                    startId = vecache["startId"],
                                })
                                localVehicleMusicTable[vehicleId] = nil
                            end
                        end
                    end

                else
                    local vehicleId = vehicle:getSqlId()
                    if localVehicleMusicTable[vehicleId] then
                        local vecache = localVehicleMusicTable[vehicleId]
                        audioDbg("[TMDBG][VehTick] STOP vehId=" .. tostring(vehicleId) .. " (server says not playing) emitter=" .. tostring(vecache["emitter"]) .. " locId=" .. tostring(vecache["localmusicid"]))
                        if vecache["emitter"] and vecache["localmusicid"] then
                            vecache["emitter"]:stopSound(vecache["localmusicid"])
                        end
                        localVehicleMusicTable[vehicleId] = nil
                    end
                end
            end
        end)
        if AUDIO_DBG then
            audioDbg("[TMDBG][TickSummary] vehiclesScanned=" .. tostring(vehCount) .. " activeCacheSize=" .. tostring((function() local n=0 for _ in pairs(localVehicleMusicTable) do n=n+1 end return n end)()))
        end

        for musicId, musicVehicleData in pairs(localVehicleMusicTable) do
            if not musicVehicleData["obj"] then
                audioDbg("[TMDBG][VehSweep] drop sqlId=" .. tostring(musicId) .. " reason=no-obj")
                localVehicleMusicTable[musicId] = nil
            else
                local radioPart = musicVehicleData["obj"]:getPartById("Radio")
                local emitter = musicVehicleData["emitter"]
                local locId = musicVehicleData["localmusicid"]
                if radioPart and radioPart:getModData().tcmusic and radioPart:getModData().tcmusic.mediaItem then
                    if not emitter or not locId or not emitter:isPlaying(locId) then
                        audioDbg("[TMDBG][VehSweep] drop sqlId=" .. tostring(musicId) .. " reason=not-playing emitter=" .. tostring(emitter) .. " locId=" .. tostring(locId) .. " isPlaying=" .. tostring(emitter and locId and emitter:isPlaying(locId)))
                        if emitter and locId then emitter:stopSound(locId) end
                        localVehicleMusicTable[musicId] = nil
                    end
                else
                    audioDbg("[TMDBG][VehSweep] drop sqlId=" .. tostring(musicId) .. " reason=no-mediaItem-on-radio")
                    if emitter and locId then emitter:stopSound(locId) end
                    localVehicleMusicTable[musicId] = nil
                end
            end
        end

        local musicServerTable = ModData.getOrCreate("trueMusicData")
        checkBootToken(musicServerTable)
        local canonicalByItemId = {}
        local canonicalByCoord = {}
        if musicServerTable and musicServerTable["now_play"] then
            canonicalByItemId, canonicalByCoord = buildCanonicalWorldIndex(musicServerTable["now_play"])
        end

        if musicServerTable and musicServerTable["now_play"] then
            for id, row in pairs(musicServerTable["now_play"]) do
                local wx, wy, wz = getWorldCoordsFromServerEntry(id, row)
                if wx ~= nil then
                    worldTTL[id] = WORLD_TTL_MAX
                end
            end
        end

        if musicServerTable and musicServerTable["now_play"] then
            for musicId, musicServerData in pairs(musicServerTable["now_play"]) do
                local x, y, z = getWorldCoordsFromServerEntry(musicId, musicServerData)

                if musicId == "Vehicle" then

                elseif x ~= nil then
                    local okWorld, worldErr = pcall(function()
                        if string.match(tostring(musicId), '^#') then
                            local rowRid = musicServerData and (musicServerData["itemid"] or musicServerData["radioItemID"]) or nil
                            if rowRid == nil or tostring(rowRid) == "" then
                                probe("skip world listener musicId=" .. tostring(musicId) .. " reason=legacy-missing-radioItemID")
                                return
                            end
                        end

                        if string.match(tostring(musicId), '^#') then
                            local rowRid = musicServerData and (musicServerData["itemid"] or musicServerData["radioItemID"]) or nil
                            local canonicalId = nil
                            if rowRid ~= nil and tostring(rowRid) ~= "" then
                                canonicalId = canonicalByItemId[tostring(rowRid)]
                            end
                            if not canonicalId then
                                canonicalId = canonicalByCoord[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
                            end

                            if canonicalId and canonicalId ~= musicId then
                                local existingLegacy = localWorldEmitterTable[musicId]
                                if existingLegacy then
                                    TCMusic_EmitterStop(existingLegacy.emitter, existingLegacy.localmusicid)
                                    localWorldEmitterTable[musicId] = nil
                                end
                                worldTTL[musicId] = nil
                                probe("skip world listener musicId=" .. tostring(musicId) .. " reason=canonical-present canonical=" .. tostring(canonicalId))
                                return
                            end
                        end

                        stopSiblingWorldEmittersByRadioItemId(musicId, musicServerData, musicServerTable["now_play"])

                        -- Do not drive fallback while LS radio is active here.
                        if isLSJukeboxRadioActiveAtOrNear(x, y, z, 2) then
                            local existing = localWorldEmitterTable[musicId]
                            if existing then
                                TCMusic_EmitterStop(existing.emitter, existing.localmusicid)
                                localWorldEmitterTable[musicId] = nil
                                worldTTL[musicId] = nil
                                probe("stop world listener musicId=" .. tostring(musicId) .. " reason=ls-radio-active")
                            end
                            return
                        end

                        local boomboxObj = TCMusic_FindWorldPlayerAt(x, y, z)
                        local useWorldFallback = false

                        if boomboxObj then
                            if not (boomboxObj.getDeviceData and boomboxObj:getDeviceData()) then
                                probe("world listener fallback: resolved object has no deviceData musicId=" .. tostring(musicId))
                                boomboxObj = nil
                            end
                        end

                        if boomboxObj then
                            local md = boomboxObj:getModData()
                            local tcm = md and md.tcmusic
                            local mediaName = tcm and TCMusic.getSoundName(tcm.mediaItem)
                            local isPlaying = tcm and tcm.isPlaying

                            if mediaName and isPlaying then
                                local data = localWorldEmitterTable[musicId]
                                local rowStartId = musicServerData["startId"]
                                if data and rowStartId and data.startId ~= rowStartId then
                                    -- New synchronized start on this device: restart in sync.
                                    TCMusic_EmitterStop(data.emitter, data.localmusicid)
                                    localWorldEmitterTable[musicId] = nil
                                    data = nil
                                end

                                local dd = boomboxObj:getDeviceData()
                                if dd and dd.getEmitter and dd:getEmitter() then
                                    dd:getEmitter():stopAll()
                                end

                                if not data and (farCullBlocked(musicId, x, y) or not syncGate(musicId, rowStartId, musicServerData["timestamp"])) then
                                    -- Suspended after an engine cull, or waiting for
                                    -- the shared start moment.
                                elseif not data then
                                    local emitter = TCMusic_GetWorldEmitter(x, y, z)
                                    local localId = TCMusic_EmitterPlay(emitter, mediaName, boomboxObj)

                                    if localId then
                                        -- Row volume first: it's transmitted on every
                                        -- SetVolume; the local deviceData copy can be
                                        -- stale on remote clients.
                                        local baseVol = ((musicServerData["volume"]) or (dd and dd.getDeviceVolume and dd:getDeviceVolume()) or 1) * 0.4
                                        local startVol = calculateVolumeByDistance(x, y, baseVol, TCMusic.worldVolKey and TCMusic.worldVolKey(x, y, z))

                                        TCMusic_EmitterSetVolume(emitter, localId, startVol)
                                        if emitter and emitter.set3D then
                                            emitter:set3D(localId, true)
                                        end

                                        localWorldEmitterTable[musicId] = {
                                            obj = boomboxObj,
                                            emitter = emitter,
                                            localmusicid = localId,
                                            baseVolume = baseVol,
                                            volume = startVol,
                                            radioItemID = musicServerData["itemid"] or nil,
                                            x = x, y = y, z = z,
                                            startTime = musicServerData["startTime"],
                                            startId = rowStartId
                                        }
                                        probe("start world listener musicId=" .. tostring(musicId) .. " mode=object media=" .. tostring(tcm.mediaItem))
                                        if TMSpeech then
                                            -- Local-only: every client's tick engine runs this itself.
                                            TMSpeech.sayAt(x + 0.5, y + 0.5, z, TMSpeech.text("Playing", TMSpeech.mediaLabel(tcm.mediaItem)))
                                            if TMSpeech.pendingCueStartId == rowStartId then
                                                TMSpeech.stopHandshakeCue()
                                                TMSpeech.pendingCueStartId = nil
                                            end
                                        end
                                    end
                                else
                                    if not TCMusic_EmitterIsPlaying(data.emitter, data.localmusicid) then
                                        local ddist = distToLocalPlayer(x, y)
                                        if ddist > FAR_TRUST_DIST then
                                            -- Engine culled our local sound: drop the dead
                                            -- handle and suspend until we come closer, so
                                            -- approaching players re-attach instead of
                                            -- standing next to a silent "playing" device.
                                            localWorldEmitterTable[musicId] = nil
                                            farCull[musicId] = ddist
                                            probe("world listener culled far musicId=" .. tostring(musicId) .. " dist=" .. tostring(ddist))
                                            return
                                        end
                                    end
                                    if data.emitter and data.emitter.setPos then
                                        data.emitter:setPos(x, y, z)
                                    end

                                    local baseVol = ((musicServerData["volume"]) or (dd and dd.getDeviceVolume and dd:getDeviceVolume()) or 1) * 0.4
                                    data.baseVolume = baseVol

                                    local targetVol = calculateVolumeByDistance(x, y, data.baseVolume, TCMusic.worldVolKey and TCMusic.worldVolKey(x, y, z))
                                    if math.abs(data.volume - targetVol) > 0.01 then
                                        TCMusic_EmitterSetVolume(data.emitter, data.localmusicid, targetVol)
                                        data.volume = targetVol
                                    end
                                    if TMMood then TMMood.report(targetVol) end
                                end
                            else
                                -- Allow fallback only for active jukebox rows.
                                useWorldFallback = musicServerData and musicServerData["musicName"] ~= nil and musicServerData["isPlaying"] == true
                                if not useWorldFallback and localWorldEmitterTable[musicId] then
                                    local data = localWorldEmitterTable[musicId]
                                    TCMusic_EmitterStop(data.emitter, data.localmusicid)
                                    localWorldEmitterTable[musicId] = nil
                                    worldTTL[musicId] = nil
                                    probe("stop world listener musicId=" .. tostring(musicId) .. " reason=device-not-playing")
                                end
                            end
                        else
                            useWorldFallback = musicServerData and musicServerData["musicName"] ~= nil and musicServerData["isPlaying"] == true
                        end

                        if useWorldFallback then
                            local data = localWorldEmitterTable[musicId]
                            local rowStartId = musicServerData["startId"]
                            if data and rowStartId and data.startId ~= rowStartId then
                                TCMusic_EmitterStop(data.emitter, data.localmusicid)
                                localWorldEmitterTable[musicId] = nil
                                data = nil
                            end
                            local mediaName = TCMusic.getSoundName(musicServerData["musicName"])
                            if not data and (farCullBlocked(musicId, x, y) or not syncGate(musicId, rowStartId, musicServerData["timestamp"])) then
                                -- Suspended after an engine cull, or waiting for
                                -- the shared start moment.
                            elseif not data then
                                local emitter = TCMusic_GetWorldEmitter(x, y, z)
                                local localId = TCMusic_EmitterPlay(emitter, mediaName)
                                if localId then
                                    local baseVol = (musicServerData["volume"] or 1) * 0.4
                                    local startVol = calculateVolumeByDistance(x, y, baseVol, TCMusic.worldVolKey and TCMusic.worldVolKey(x, y, z))
                                    TCMusic_EmitterSetVolume(emitter, localId, startVol)
                                    if emitter and emitter.set3D then
                                        emitter:set3D(localId, true)
                                    end
                                    localWorldEmitterTable[musicId] = {
                                        obj = nil,
                                        emitter = emitter,
                                        localmusicid = localId,
                                        baseVolume = baseVol,
                                        volume = startVol,
                                        radioItemID = musicServerData["itemid"] or nil,
                                        x = x, y = y, z = z,
                                        startTime = musicServerData["startTime"],
                                        startId = rowStartId
                                    }
                                    probe("start world listener musicId=" .. tostring(musicId) .. " mode=fallback media=" .. tostring(musicServerData["musicName"]))
                                    if TMSpeech then
                                        -- Local-only: every client's tick engine runs this itself.
                                        TMSpeech.sayAt(x + 0.5, y + 0.5, z, TMSpeech.text("Playing", TMSpeech.mediaLabel(musicServerData["musicName"])))
                                        if TMSpeech.pendingCueStartId == rowStartId then
                                            TMSpeech.stopHandshakeCue()
                                            TMSpeech.pendingCueStartId = nil
                                        end
                                    end
                                end
                            else
                                if not TCMusic_EmitterIsPlaying(data.emitter, data.localmusicid) then
                                    local ddist = distToLocalPlayer(x, y)
                                    if ddist > FAR_TRUST_DIST then
                                        localWorldEmitterTable[musicId] = nil
                                        farCull[musicId] = ddist
                                        probe("world fallback culled far musicId=" .. tostring(musicId) .. " dist=" .. tostring(ddist))
                                        return
                                    end
                                end
                                if data.emitter and data.emitter.setPos then
                                    data.emitter:setPos(x, y, z)
                                end
                                data.baseVolume = (musicServerData["volume"] or 1) * 0.4
                                local targetVol = calculateVolumeByDistance(x, y, data.baseVolume, TCMusic.worldVolKey and TCMusic.worldVolKey(x, y, z))
                                if math.abs(data.volume - targetVol) > 0.01 then
                                    TCMusic_EmitterSetVolume(data.emitter, data.localmusicid, targetVol)
                                    data.volume = targetVol
                                end
                                if TMMood then TMMood.report(targetVol) end
                            end
                        end
                    end)
                    if not okWorld then
                        probe("world listener crash musicId=" .. tostring(musicId) .. " err=" .. tostring(worldErr))
                        local stale = localWorldEmitterTable[musicId]
                        if stale then
                            TCMusic_EmitterStop(stale.emitter, stale.localmusicid)
                            localWorldEmitterTable[musicId] = nil
                        end
                    end

                else
                    local player = nil
                    if isClient() then
                        player = getPlayerByMusicIdClient(musicId)
                        if not player then
                            local byItem, byItemReason = resolvePlayerByServerData(musicServerData)
                            if byItem then
                                player = byItem
                                probe("resolved player by item fallback musicId=" .. tostring(musicId) .. " via=" .. tostring(byItemReason))
                            end
                        end
                    else
                        for playerNum = 0, getNumActivePlayers() - 1 do
                            local tempPlayerObj = getSpecificPlayer(playerNum)
                            if tempPlayerObj:getUsername() == musicId then player = tempPlayerObj end
                        end
                    end
                    if not player then
                        probe("skip listener musicId=" .. tostring(musicId) .. " reason=player-not-resolved")
                    end

                    if player and not player:isDead() then
                        local x = player:getX()
                        local y = player:getY()
                        local z = player:getZ()
                        local playerObj = getPlayer()

                        if playerObj then

                            if playerObj == player then
                                local itemid = musicServerData and musicServerData["itemid"] or nil
                                local musicplayer = itemid and playerObj:getInventory():getItemById(itemid) or nil
                                if (not musicplayer) and itemid then
                                    musicplayer = findAttachedItemById(playerObj, itemid)
                                end

                                -- Stop boombox if no longer equipped/attached.
                                if musicplayer and musicplayer.getFullType and musicplayer.getModData then
                                    local fullType = musicplayer:getFullType()
                                    local isBoombox = TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[fullType]
                                    local isWalkman = TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[fullType]
                                    if isBoombox and not isWalkman then
                                        local inPrimary = playerObj:getPrimaryHandItem() == musicplayer
                                        local inSecondary = playerObj:getSecondaryHandItem() == musicplayer
                                        local onBack = isBackAttachedItem(playerObj, musicplayer)
                                        if not inPrimary and not inSecondary and not onBack then
                                            local tmId = playerObj:getModData().tcmusicid
                                            if tmId then
                                                playerObj:getEmitter():stopSound(tmId)
                                                playerObj:getModData().tcmusicid = nil
                                            end
                                            if musicplayer:getModData().tcmusic then
                                                musicplayer:getModData().tcmusic.isPlaying = false
                                            end
                                            ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                                            if isClient() then TCMusic.transmitNowPlay(playerObj) end
                                            musicplayer = nil
                                        end
                                    end
                                end

                                if not musicplayer then
                                    -- Keep now_play on transient owner lookup misses.

                                elseif not (musicplayer:getModData().tcmusic and musicplayer:getModData().tcmusic.mediaItem) or
                                       not musicplayer:getDeviceData() or
                                       (not musicplayer:getDeviceData():getIsTurnedOn() and not isBackAttachedItem(playerObj, musicplayer)) then
                                    -- Keep now_play; owner state can be transient in MP.
                                end

                            else
                                -- Any distance: the sound always runs locally so its
                                -- position stays correct; the engine's 3D attenuation
                                -- (and our koef) makes it inaudible when far away and
                                -- fades it in as you approach - already in sync.

                                local musicData = localPlayerMusicTable[musicId]
                                local rowStartId = musicServerData["startId"]
                                if musicData and rowStartId and musicData["startId"] ~= rowStartId then
                                    -- New synchronized start: restart in sync with everyone.
                                    player:getEmitter():stopSound(musicData["localmusicid"])
                                    localPlayerMusicTable[musicId] = nil
                                    musicData = nil
                                end
                                local musicPlayer, resolveReason = resolveRemotePortableMusicPlayer(player, musicServerData)

                                if (not musicData) and (farCullBlocked(musicId, x, y) or not syncGate(musicId, rowStartId, musicServerData["timestamp"])) then
                                    -- Suspended after an engine cull, or waiting for
                                    -- the shared start moment.
                                elseif not musicData then
                                    if musicPlayer and musicPlayer:getDeviceData() and (musicPlayer:getDeviceData():getPower() > 0) then

                                        local id = player:getEmitter():playSoundImpl(TCMusic.getSoundName(musicServerData["musicName"]), player)

                                        local koef = 0.4
                                        if musicServerData["headphone"] then
                                            koef = 0.02
                                        end
                                        local pKey = musicServerData["itemid"] and ("I:" .. tostring(musicServerData["itemid"])) or nil
                                        local lvol = TCMusic.getListenVolume and TCMusic.getListenVolume(musicServerData["volume"], pKey) or musicServerData["volume"]

                                        localPlayerMusicTable[musicId] = {
                                            localmusicid = id,
                                            volume = lvol * koef,
                                            startId = rowStartId,
                                        }
                                        probe("start local listener musicId=" .. tostring(musicId) .. " itemId=" .. tostring(musicServerData["itemid"]) .. " media=" .. tostring(musicServerData["musicName"]) .. " via=" .. tostring(resolveReason))
                                        player:getEmitter():setVolume(localPlayerMusicTable[musicId]["localmusicid"], lvol * koef)
                                    else
                                        probe("skip start local listener musicId=" .. tostring(musicId) .. " itemId=" .. tostring(musicServerData["itemid"]) .. " reason=" .. tostring(resolveReason))
                                    end

                                else
                                    if TCMusic_EmitterIsPlaying(player:getEmitter(), musicData["localmusicid"]) then
                                        local isBack = (musicPlayer and isBackAttachedItem(player, musicPlayer)) or false
                                        local mediaMatches = (musicPlayer and musicPlayer.getModData and musicPlayer:getModData().tcmusic and musicPlayer:getModData().tcmusic.mediaItem == musicServerData["musicName"]) or false
                                        local idMatches = (musicPlayer and musicPlayer.getID and musicServerData and musicServerData["itemid"] and musicPlayer:getID() == musicServerData["itemid"]) or false
                                        local dd = musicPlayer and musicPlayer.getDeviceData and musicPlayer:getDeviceData() or nil
                                        local portableValid = false
                                        if dd then
                                            if isBack then
                                                -- Back-attach can desync; allow id/media match.
                                                portableValid = (idMatches or mediaMatches)
                                            else
                                                portableValid = dd:getIsTurnedOn() and (dd:getPower() > 0)
                                            end
                                        end
                                        if portableValid then

                                            local koef = 0.4
                                            if musicServerData["headphone"] then
                                                koef = 0.02
                                            end
                                            local pKey = musicServerData["itemid"] and ("I:" .. tostring(musicServerData["itemid"])) or nil
                                            local lvol = TCMusic.getListenVolume and TCMusic.getListenVolume(musicServerData["volume"], pKey) or musicServerData["volume"]

                                            if musicData["volume"] ~= lvol * koef then
                                                player:getEmitter():setVolume(musicData["localmusicid"], lvol * koef)
                                                musicData["volume"] = lvol * koef
                                            end

                                            -- Mood: nearby player's portable is audible (headphones
                                            -- report at koef 0.02 and fall below the audible gate).
                                            if TMMood then TMMood.reportAt(x, y, lvol * koef) end

                                        else
                                            probe("stop local listener musicId=" .. tostring(musicId) .. " reason=validation-failed via=" .. tostring(resolveReason))
                                            player:getEmitter():stopSound(musicData["localmusicid"])
                                            localPlayerMusicTable[musicId] = nil
                                        end

                                    else
                                        local pdist = distToLocalPlayer(x, y)
                                        if pdist > FAR_TRUST_DIST then
                                            -- Engine culled it because they're far; suspend
                                            -- and re-attach when we get closer.
                                            probe("suspend local listener musicId=" .. tostring(musicId) .. " reason=culled-far dist=" .. tostring(pdist))
                                            farCull[musicId] = pdist
                                        else
                                            probe("drop local listener musicId=" .. tostring(musicId) .. " reason=emitter-not-playing")
                                        end
                                        localPlayerMusicTable[musicId] = nil
                                    end
                                end
                            end
                        end

                    else
                        if player and localPlayerMusicTable[musicId] then
                            probe("stop local listener musicId=" .. tostring(musicId) .. " reason=player-not-valid")
                            player:getEmitter():stopSound(localPlayerMusicTable[musicId]["localmusicid"])
                        end
                        localPlayerMusicTable[musicId] = nil
                    end
                end
            end
        end

        local trueMusicData = ModData.getOrCreate("trueMusicData")
        trueMusicData["now_play"] = trueMusicData["now_play"] or {}
        local nowPlay = trueMusicData["now_play"]

        reconcileOwnerPortable(nowPlay)

        for musicId, musicClientData in pairs(localPlayerMusicTable) do
            if not nowPlay[musicId] then
                local player = isClient() and getPlayerByMusicIdClient(musicId) or getPlayer()
                if player then
                    probe("stop local listener musicId=" .. tostring(musicId) .. " reason=missing-now_play")
                    player:getEmitter():stopSound(musicClientData["localmusicid"])
                end
                localPlayerMusicTable[musicId] = nil
            end
        end

        for id, data in pairs(localWorldEmitterTable) do
            local serverKnows = nowPlay[id] ~= nil
            
            if serverKnows then
                worldTTL[id] = WORLD_TTL_MAX
            else
                -- Stop fallback stream when now_play row is gone.
                if data and data.obj == nil then
                    TCMusic_EmitterStop(data.emitter, data.localmusicid)
                    localWorldEmitterTable[id] = nil
                    worldTTL[id] = nil
                else
                    if worldTTL[id] and worldTTL[id] > 0 then
                        worldTTL[id] = worldTTL[id] - 1
                    else
                        TCMusic_EmitterStop(data.emitter, data.localmusicid)
                        localWorldEmitterTable[id] = nil
                        worldTTL[id] = nil
                    end
                end
            end
        end

        -- Prune synchronized-start bookkeeping: pending entries whose row
        -- vanished before firing (playback cancelled during the delay) or
        -- that are long overdue must not keep forcing fast cycles forever.
        local pruneNowMs = (getTimestampMs and getTimestampMs()) or 0
        for id, pend in pairs(syncPending) do
            local isVehicleKey = string.sub(tostring(id), 1, 2) == "V:"
            if (not isVehicleKey and nowPlay[id] == nil) or pruneNowMs > pend.at + 15000 then
                syncPending[id] = nil
            end
        end
        for sid, go in pairs(syncGo) do
            if pruneNowMs > go.at + 15000 then
                syncGo[sid] = nil
            end
        end
        for id in pairs(farCull) do
            local isVehicleKey = string.sub(tostring(id), 1, 2) == "V:"
            if not isVehicleKey and nowPlay[id] == nil then
                farCull[id] = nil
            end
        end
        end
end

function startTrueMusicTick ()
    Events.OnTick.Add(OnRenderTickClientCheckMusic)
end

Events.OnCreatePlayer.Add(startTrueMusicTick)

