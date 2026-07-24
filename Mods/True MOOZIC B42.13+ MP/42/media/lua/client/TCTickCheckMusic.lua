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
local WORLD_TTL_MAX = 300
local worldTTL = {}

local tickControl = 160
local tickStart = 0

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

local function calculateVolumeByDistance(x, y, baseVol)
    local p = getPlayer()
    if not p then return 0 end
    
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

function OnRenderTickClientCheckMusic ()
    tickStart = tickStart + 1
    if tickStart % tickControl == 0 then
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
                    if not localVehicleMusicTable[vehicleId] then
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
                        local vol3d = true

                        if vehicle == getPlayer():getVehicle() then
                            vol = vol * 5
                            vol3d = false
                        elseif vehicleRadio:getModData().tcmusic.windowsOpen then
                            vol = vol * 3
                        end

                        localVehicleMusicTable[vehicleId] = {
                            obj = vehicle,
                            emitter = vemitter,
                            localmusicid = id,
                            volume = vol,
                        }

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

                            if vehicle == getPlayer():getVehicle() then
                                vol = vol * 5
                                if vehicleEmitter.set3D then vehicleEmitter:set3D(locId, false) end
                            else
                                if vehicleRadio:getModData().tcmusic.windowsOpen then
                                    vol = vol * 3
                                end
                                if vehicleEmitter.set3D then vehicleEmitter:set3D(locId, true) end
                            end

                            if vecache["volume"] ~= vol then
                                vehicleEmitter:setVolume(locId, vol / 5)
                                audioDbg("[TMDBG][VehTick] ACTIVE vehId=" .. tostring(vehicleId) .. " volume changed " .. tostring(vecache["volume"]) .. " -> " .. tostring(vol) .. " (rawDev=" .. tostring(rawVol) .. " applied=" .. tostring(vol/5) .. ")")
                                vecache["volume"] = vol
                            end

                        else
                            audioDbg("[TMDBG][VehTick] ACTIVE vehId=" .. tostring(vehicleId) .. " sound stopped externally (emitter=" .. tostring(vehicleEmitter) .. " locId=" .. tostring(locId) .. " isPlaying=" .. tostring(stillPlaying) .. "); requesting server stop")
                            sendClientCommand(getPlayer(), 'truemusic', 'setMediaItemToVehiclePart', {
                                vehicle = vecache["obj"]:getId(),
                                mediaItem = vecache["obj"]:getPartById("Radio"):getModData().tcmusic.mediaItem,
                                isPlaying = false
                            })
                            localVehicleMusicTable[vehicleId] = nil
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

                                local dd = boomboxObj:getDeviceData()
                                if dd and dd.getEmitter and dd:getEmitter() then
                                    dd:getEmitter():stopAll()
                                end

                                if not data then
                                    local emitter = TCMusic_GetWorldEmitter(x, y, z)
                                    local localId = TCMusic_EmitterPlay(emitter, mediaName, boomboxObj)

                                    if localId then
                                        local baseVol = ((dd and dd.getDeviceVolume and dd:getDeviceVolume()) or (musicServerData["volume"] or 1)) * 0.4
                                        local startVol = calculateVolumeByDistance(x, y, baseVol)

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
                                            startTime = musicServerData["startTime"]
                                        }
                                        probe("start world listener musicId=" .. tostring(musicId) .. " mode=object media=" .. tostring(tcm.mediaItem))
                                    end
                                else
                                    if data.emitter and data.emitter.setPos then
                                        data.emitter:setPos(x, y, z)
                                    end

                                    local baseVol = ((dd and dd.getDeviceVolume and dd:getDeviceVolume()) or (musicServerData["volume"] or 1)) * 0.4
                                    data.baseVolume = baseVol

                                    local targetVol = calculateVolumeByDistance(x, y, data.baseVolume)
                                    if math.abs(data.volume - targetVol) > 0.01 then
                                        TCMusic_EmitterSetVolume(data.emitter, data.localmusicid, targetVol)
                                        data.volume = targetVol
                                    end
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
                            local mediaName = TCMusic.getSoundName(musicServerData["musicName"])
                            if not data then
                                local emitter = TCMusic_GetWorldEmitter(x, y, z)
                                local localId = TCMusic_EmitterPlay(emitter, mediaName)
                                if localId then
                                    local baseVol = (musicServerData["volume"] or 1) * 0.4
                                    local startVol = calculateVolumeByDistance(x, y, baseVol)
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
                                        startTime = musicServerData["startTime"]
                                    }
                                    probe("start world listener musicId=" .. tostring(musicId) .. " mode=fallback media=" .. tostring(musicServerData["musicName"]))
                                end
                            else
                                if data.emitter and data.emitter.setPos then
                                    data.emitter:setPos(x, y, z)
                                end
                                data.baseVolume = (musicServerData["volume"] or 1) * 0.4
                                local targetVol = calculateVolumeByDistance(x, y, data.baseVolume)
                                if math.abs(data.volume - targetVol) > 0.01 then
                                    TCMusic_EmitterSetVolume(data.emitter, data.localmusicid, targetVol)
                                    data.volume = targetVol
                                end
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
                                            if isClient() then ModData.transmit("trueMusicData") end
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

                            elseif ((playerObj:getX() >= x - 60 and playerObj:getX() <= x + 60 and
                                     playerObj:getY() >= y - 60 and playerObj:getY() <= y + 60)) then

                                local musicData = localPlayerMusicTable[musicId]
                                local musicPlayer, resolveReason = resolveRemotePortableMusicPlayer(player, musicServerData)

                                if not musicData then
                                    if musicPlayer and musicPlayer:getDeviceData() and (musicPlayer:getDeviceData():getPower() > 0) then

                                        local id = player:getEmitter():playSoundImpl(TCMusic.getSoundName(musicServerData["musicName"]), player)

                                        local koef = 0.4
                                        if musicServerData["headphone"] then
                                            koef = 0.02
                                        end

                                        localPlayerMusicTable[musicId] = {
                                            localmusicid = id,
                                            volume = musicServerData["volume"] * koef,
                                        }
                                        probe("start local listener musicId=" .. tostring(musicId) .. " itemId=" .. tostring(musicServerData["itemid"]) .. " media=" .. tostring(musicServerData["musicName"]) .. " via=" .. tostring(resolveReason))
                                        player:getEmitter():setVolume(localPlayerMusicTable[musicId]["localmusicid"], musicServerData["volume"] * koef)
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

                                            if musicData["volume"] ~= musicServerData["volume"] * koef then
                                                player:getEmitter():setVolume(musicData["localmusicid"], musicServerData["volume"] * koef)
                                                musicData["volume"] = musicServerData["volume"] * koef
                                            end

                                        else
                                            probe("stop local listener musicId=" .. tostring(musicId) .. " reason=validation-failed via=" .. tostring(resolveReason))
                                            player:getEmitter():stopSound(musicData["localmusicid"])
                                            localPlayerMusicTable[musicId] = nil
                                        end

                                    else
                                        probe("drop local listener musicId=" .. tostring(musicId) .. " reason=emitter-not-playing")
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
        local nowPlay = trueMusicData["now_play"] or {}
        
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
        end
end

function startTrueMusicTick ()
    Events.OnTick.Add(OnRenderTickClientCheckMusic)
end

Events.OnCreatePlayer.Add(startTrueMusicTick)

