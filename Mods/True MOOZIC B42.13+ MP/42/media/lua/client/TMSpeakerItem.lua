-- TMSpeakerItem: right-click context for Base.Speaker dropped in the world
-- Handles IsoWorldInventoryObject speakers (not tile-based speaker cabinets)

-- Shared global so both tile and item speaker files can count total speakers per device
TMSpeakerGlobal = TMSpeakerGlobal or { emitterTables = {} }

local function countSpeakersForDevice(vx, vy, vz)
    local count = 0
    for _, tbl in ipairs(TMSpeakerGlobal.emitterTables) do
        for _, data in pairs(tbl) do
            local obj = data.obj
            if obj and obj.getModData then
                local md = obj:getModData()
                local tms = md and md.tmspeaker
                if tms and tms.connected then
                    local mx = tms.masterX or tms.vinylX
                    local my = tms.masterY or tms.vinylY
                    local mz = tms.masterZ or tms.vinylZ
                    if mx == vx and my == vy and mz == vz then
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

local SPEAKER_ITEM_TYPES = {
    ["Base.Speaker"] = true,
}

local VINYL_SPRITES = {
    ["tsarcraft_music_01_63"] = true,
    ["tsarcraft_music_01_36"] = true,
}

-- Known master device fullTypes and their display names
local MASTER_DEVICE_NAMES = {
    ["Tsarcraft.TCVinylplayer"]                   = "IGUI_TMSpeaker_DeviceVinyl",
    ["Tsarcraft.TM_HiFiStereo"]                     = "IGUI_TMSpeaker_DeviceHifi",
}
local MASTER_DEVICE_TYPES = {
    ["Tsarcraft.TCVinylplayer"]                   = "vinyl",
    ["Tsarcraft.TM_HiFiStereo"]                     = "hifi",
}

local function isVinylSprite(sname)
    if not sname then return false end
    if VINYL_SPRITES[sname] then return true end
    local short = string.match(sname, "[^.]+$")
    if short and VINYL_SPRITES[short] then return true end
    return false
end

local function getSpriteName(obj)
    if not obj then return nil end
    if obj.getSprite then
        local spr = obj:getSprite()
        if spr and spr.getName then return spr:getName() end
    end
    if obj.getName then return obj:getName() end
    return nil
end

-- Check if an IsoWorldInventoryObject is a speaker item
local function isSpeakerWorldItem(obj)
    if not obj then return false end
    if not instanceof(obj, "IsoWorldInventoryObject") then return false end
    local item = obj:getItem()
    if item and item.getFullType then
        return SPEAKER_ITEM_TYPES[item:getFullType()] == true
    end
    return false
end

-- Check if an object is a known master device
local function isMasterDevice(obj)
    if not obj then return false end
    local sname = getSpriteName(obj)
    if isVinylSprite(sname) then return true end
    if instanceof(obj, "IsoWorldInventoryObject") then
        local it = obj:getItem()
        if it and it.getFullType then
            return MASTER_DEVICE_NAMES[it:getFullType()] ~= nil
        end
    end
    -- Placed radio devices (IsoWaveSignal) with HiFi modData
    if instanceof(obj, "IsoWaveSignal") and obj.getModData then
        local md = obj:getModData()
        if md and md.hifiDeviceType and MASTER_DEVICE_NAMES[md.hifiDeviceType] then
            return true
        end
        -- Fallback: check for a HiFi WorldInventoryObject on the same square
        if obj.getSquare then
            local sq = obj:getSquare()
            if sq then
                local wobjs = sq:getWorldObjects()
                if wobjs then
                    for i = 0, wobjs:size() - 1 do
                        local w = wobjs:get(i)
                        if instanceof(w, "IsoWorldInventoryObject") then
                            local it = w:getItem()
                            if it and it.getFullType and MASTER_DEVICE_NAMES[it:getFullType()] then
                                md.hifiDeviceType = it:getFullType()
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Find ALL master devices within radius
local function findAllMasterDevices(speakerObj, radius)
    if not radius then radius = 10 end
    if not speakerObj or not speakerObj.getSquare then return {} end
    local sq = speakerObj:getSquare()
    if not sq then return {} end
    local sz = sq:getZ()
    local sx = sq:getX()
    local sy = sq:getY()
    local found = {}
    local seen = {}
    for dy = -radius, radius do
        for dx = -radius, radius do
            local sq2 = getCell():getGridSquare(sx + dx, sy + dy, sz)
            if sq2 then
                local objects = sq2:getObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local o = objects:get(i)
                        local sname = getSpriteName(o)
                        if isVinylSprite(sname) then
                            local key = sq2:getX() .. "_" .. sq2:getY() .. "_" .. sq2:getZ() .. "_vinyl"
                            if not seen[key] then
                                seen[key] = true
                                table.insert(found, {
                                    obj  = o,
                                    name = getText("IGUI_TMSpeaker_DeviceVinyl") or "Vinyl Player",
                                    sq   = sq2,
                                    type = "vinyl",
                                })
                            end
                        end
                    end
                end
                local wobjs = sq2:getWorldObjects()
                if wobjs then
                    for i = 0, wobjs:size() - 1 do
                        local w = wobjs:get(i)
                        if instanceof(w, "IsoWorldInventoryObject") then
                            local it = w:getItem()
                            if it and it.getFullType then
                                local ft = it:getFullType()
                                if MASTER_DEVICE_NAMES[ft] then
                                    local dtype = MASTER_DEVICE_TYPES[ft] or "unknown"
                                    local key = sq2:getX() .. "_" .. sq2:getY() .. "_" .. sq2:getZ() .. "_" .. dtype
                                    if not seen[key] then
                                        seen[key] = true
                                        local nameKey = MASTER_DEVICE_NAMES[ft]
                                        table.insert(found, {
                                            obj  = w,
                                            name = getText(nameKey) or nameKey,
                                            sq   = sq2,
                                            type = dtype,
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return found
end

------------------------------------------------------------------
-- Speaker emitter sync system
------------------------------------------------------------------
local itemSpeakerEmitters = {}
table.insert(TMSpeakerGlobal.emitterTables, itemSpeakerEmitters)

local function speakerSyncStart(speakerObj)
    local sq = speakerObj:getSquare()
    if not sq then return end
    local key = "item-" .. sq:getX() .. "-" .. sq:getY() .. "-" .. sq:getZ()
    itemSpeakerEmitters[key] = {
        obj = speakerObj,
        emitter = nil,
        localmusicid = nil,
        lastMedia = nil,
        nilTicks = 0,
    }
end

local function speakerSyncStop(speakerObj)
    local sq = speakerObj:getSquare()
    if not sq then return end
    local key = "item-" .. sq:getX() .. "-" .. sq:getY() .. "-" .. sq:getZ()
    local data = itemSpeakerEmitters[key]
    if data and data.emitter and data.localmusicid then
        if data.emitter.stopSound then
            data.emitter:stopSound(data.localmusicid)
        elseif data.emitter.stopAll then
            data.emitter:stopAll()
        end
    end
    itemSpeakerEmitters[key] = nil
end

------------------------------------------------------------------
-- Speaker Wire helpers
------------------------------------------------------------------
local WIRE_ITEM_TYPE  = "Tsarcraft.WireBundle"
local WIRE_MAX_FT     = 200
local WIRE_FT_PER_TILE = 5

local function getWireRemaining(wireItem)
    if not wireItem then return 0 end
    local md = wireItem:getModData()
    if md.tmWireFt == nil then md.tmWireFt = WIRE_MAX_FT end
    return md.tmWireFt
end

local function getAllWireSorted(player)
    local inv = player:getInventory()
    if not inv then return {} end
    local items = inv:getItemsFromFullType(WIRE_ITEM_TYPE)
    if not items or items:size() == 0 then return {} end
    local list = {}
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local ft = getWireRemaining(it)
        table.insert(list, { item = it, ft = ft })
    end
    table.sort(list, function(a, b) return a.ft < b.ft end)
    return list
end

local function getTotalWire(player)
    local sorted = getAllWireSorted(player)
    local total = 0
    for _, entry in ipairs(sorted) do
        total = total + entry.ft
    end
    return total, sorted
end

local function findBestWire(player)
    local sorted = getAllWireSorted(player)
    if #sorted == 0 then return nil, 0 end
    local best = sorted[#sorted]
    return best.item, best.ft
end

local function tileDistance(sq1, sq2)
    if not sq1 or not sq2 then return 999 end
    local dx = math.abs(sq1:getX() - sq2:getX())
    local dy = math.abs(sq1:getY() - sq2:getY())
    return math.max(dx, dy)
end

local function nameWireBundle(wireItem, ft)
    if ft <= 0 then
        wireItem:setName((getText("IGUI_TMSpeaker_WireName") or "Speaker Wire Bundle") .. " (" .. (getText("IGUI_TMSpeaker_Empty") or "empty") .. ")")
    else
        wireItem:setName((getText("IGUI_TMSpeaker_WireName") or "Speaker Wire Bundle") .. " (" .. tostring(ft) .. "ft)")
    end
end

local function consumeWire(player, ftNeeded)
    local sorted = getAllWireSorted(player)
    local remaining = ftNeeded
    local inv = player:getInventory()
    for _, entry in ipairs(sorted) do
        if remaining <= 0 then break end
        local take = math.min(entry.ft, remaining)
        local newFt = entry.ft - take
        local wireMd = entry.item:getModData()
        wireMd.tmWireFt = newFt
        remaining = remaining - take
        if newFt <= 0 then
            inv:Remove(entry.item)
        else
            nameWireBundle(entry.item, newFt)
        end
    end
    return remaining <= 0
end

local function createWireBundle(player, ft)
    local inv = player:getInventory()
    if not inv then return nil end
    local newItem = instanceItem(WIRE_ITEM_TYPE)
    if not newItem then return nil end
    local md = newItem:getModData()
    md.tmWireFt = ft
    nameWireBundle(newItem, ft)
    inv:AddItem(newItem)
    return newItem
end

local function recoverWire(player, ftToRecover)
    if ftToRecover <= 0 or not player then return end
    local remaining = ftToRecover
    local wireItem, wireFt = findBestWire(player)
    if wireItem then
        local cur = wireFt
        local space = WIRE_MAX_FT - cur
        if space > 0 then
            local add = math.min(remaining, space)
            local wireMd = wireItem:getModData()
            wireMd.tmWireFt = cur + add
            nameWireBundle(wireItem, cur + add)
            remaining = remaining - add
        end
    end
    while remaining > 0 do
        local add = math.min(remaining, WIRE_MAX_FT)
        createWireBundle(player, add)
        remaining = remaining - add
    end
end

-- Connect speaker to a specific master device (server-authoritative)
local function connectToDevice(player, speakerObj, deviceEntry)
    if not speakerObj or not deviceEntry then return end
    local deviceObj = deviceEntry.obj
    local viSq = deviceObj:getSquare()
    if not viSq then return end
    local spSq = speakerObj:getSquare()
    if not spSq then return end
    sendClientCommand(player, 'tmspeaker', 'connectSpeaker', {
        speakerX = spSq:getX(),
        speakerY = spSq:getY(),
        speakerZ = spSq:getZ(),
        speakerSprite = getSpriteName(speakerObj),
        deviceX = viSq:getX(),
        deviceY = viSq:getY(),
        deviceZ = viSq:getZ(),
        deviceType = deviceEntry.type,
        deviceName = deviceEntry.name,
        isTileSpeaker = false,
    })
end

-- Disconnect speaker (server-authoritative)
local function disconnectDevice(player, speakerObj)
    if not speakerObj then return end
    local spSq = speakerObj:getSquare()
    if not spSq then return end
    speakerSyncStop(speakerObj)
    sendClientCommand(player, 'tmspeaker', 'disconnectSpeaker', {
        speakerX = spSq:getX(),
        speakerY = spSq:getY(),
        speakerZ = spSq:getZ(),
        isTileSpeaker = false,
    })
end

------------------------------------------------------------------
-- Tick: mirror music at each connected item speaker
-- Checks both True MOOZIC trueMusicData AND HiFi SWTCEmitters
------------------------------------------------------------------
local function stopItemEmitter(data)
    if data.emitter and data.localmusicid then
        if data.emitter.stopSound then
            data.emitter:stopSound(data.localmusicid)
        elseif data.emitter.stopAll then
            data.emitter:stopAll()
        end
    end
    data.emitter = nil
    data.localmusicid = nil
    data.lastMedia = nil
end

local function createItemEmitter(data, spx, spy, spz, mediaName, vol)
    if not getWorld() or not getWorld().getFreeEmitter then
        return
    end
    local emitter = getWorld():getFreeEmitter(spx, spy, spz)
    if not emitter then
        return
    end
    if emitter.setPos then emitter:setPos(spx, spy, spz) end

    local localId = nil
    if emitter.playSoundImpl then
        localId = emitter:playSoundImpl(mediaName, IsoObject.new())
    elseif emitter.playSound then
        localId = emitter:playSound(mediaName)
    end

    if localId then
        if emitter.setVolume then
            emitter:setVolume(localId, vol)
        end
        if emitter.set3D then
            emitter:set3D(localId, true)
        end
        data.emitter = emitter
        data.localmusicid = localId
    end
end

-- Check if a master device still exists at the given position
local function masterExistsAt(vx, vy, vz)
    local sq = getCell():getGridSquare(vx, vy, vz)
    if not sq then return false end
    local objects = sq:getObjects()
    if objects then
        for i = 0, objects:size() - 1 do
            local o = objects:get(i)
            if isMasterDevice(o) then return true end
        end
    end
    local wobjs = sq:getWorldObjects()
    if wobjs then
        for i = 0, wobjs:size() - 1 do
            local w = wobjs:get(i)
            if isMasterDevice(w) then return true end
        end
    end
    return false
end

-- HiFi device types whose modData we can read directly
local HIFI_DEVICE_TYPES = {
    ["Tsarcraft.TM_HiFiStereo"] = true,
}

local function readHifiSlots(md)
    if not md then return nil end
    if md.hifiCD and md.hifiCD.isPlaying and md.hifiCD.tracks and md.hifiCD.currentTrack then
        local track = md.hifiCD.tracks[md.hifiCD.currentTrack]
        if track and track.soundName then
            return { soundName = track.soundName, baseVol = 0.4 }
        end
    end
    if md.hifiTape and md.hifiTape.isPlaying and md.hifiTape.mediaItem then
        local sn = TCMusic and TCMusic.getSoundName and TCMusic.getSoundName(md.hifiTape.mediaItem)
        if sn then return { soundName = sn, baseVol = 0.4 } end
    end
    if md.hifiVinyl and md.hifiVinyl.isPlaying and md.hifiVinyl.mediaItem then
        local sn = TCMusic and TCMusic.getSoundName and TCMusic.getSoundName(md.hifiVinyl.mediaItem)
        if sn then return { soundName = sn, baseVol = 0.4 } end
    end
    return nil
end

-- Read playing state directly from HiFi device modData
local function getHifiSongData(vx, vy, vz)
    local sq = getCell():getGridSquare(vx, vy, vz)
    if not sq then return nil end
    local wobjs = sq:getWorldObjects()
    if wobjs then
        for i = 0, wobjs:size() - 1 do
            local w = wobjs:get(i)
            if instanceof(w, "IsoWorldInventoryObject") then
                local it = w:getItem()
                if it and it.getFullType and HIFI_DEVICE_TYPES[it:getFullType()] then
                    return readHifiSlots(w:getModData()) or readHifiSlots(it:getModData())
                end
            end
        end
    end
    local objects = sq:getObjects()
    if objects then
        for i = 0, objects:size() - 1 do
            local o = objects:get(i)
            if instanceof(o, "IsoRadio") or instanceof(o, "IsoWaveSignal") then
                local result = readHifiSlots(o:getModData())
                if result then return result end
            end
        end
    end
    return nil
end

local function onTickItemSpeakerSync()
    for key, data in pairs(itemSpeakerEmitters) do
        local speakerObj = data.obj
        if not speakerObj or not speakerObj.getSquare then
            itemSpeakerEmitters[key] = nil
        else
            local spMd = speakerObj:getModData()
            local tms = spMd and spMd.tmspeaker
            if not tms or not tms.connected then
                stopItemEmitter(data)
                itemSpeakerEmitters[key] = nil
            else
                local vx = tms.masterX or tms.vinylX
                local vy = tms.masterY or tms.vinylY
                local vz = tms.masterZ or tms.vinylZ
                if vx and vy and vz then
                    if not masterExistsAt(vx, vy, vz) then
                        -- Stop local emitter; server handles wire recovery
                        stopItemEmitter(data)
                        itemSpeakerEmitters[key] = nil
                        local player = getSpecificPlayer(0)
                        if player then
                            local autoSq = speakerObj:getSquare()
                            if autoSq then
                                sendClientCommand(player, 'tmspeaker', 'autoDisconnectSpeaker', {
                                    speakerX = autoSq:getX(),
                                    speakerY = autoSq:getY(),
                                    speakerZ = autoSq:getZ(),
                                    isTileSpeaker = false,
                                })
                            end
                        end
                    else
                        -- Source 1: HiFi modData (check FIRST — HiFi uses player emitters,
                        -- not world emitters, so the vinylEmitterReady gate would block it)
                        local hifiSong = getHifiSongData(vx, vy, vz)

                        -- Source 2: True MOOZIC trueMusicData (only if no HiFi data)
                        local mediaName = nil
                        local vinylData = nil
                        local vinylMusicId = nil
                        if not hifiSong then
                            vinylMusicId = "#" .. vx .. "-" .. vy .. "-" .. vz
                            local trueMusicData = ModData.getOrCreate("trueMusicData")
                            local nowPlay = trueMusicData and trueMusicData["now_play"]
                            vinylData = nowPlay and nowPlay[vinylMusicId]
                            mediaName = vinylData and vinylData["musicName"] or nil
                        end

                        if hifiSong then
                            -- HiFi path (no vinylEmitterReady gate)
                            data.nilTicks = 0
                            local soundName = hifiSong.soundName

                            if data.waitingForSync then
                                if soundName ~= data.waitingSyncSong then
                                    data.waitingForSync = nil
                                    data.waitingSyncSong = nil
                                end
                            end

                            if not data.waitingForSync then
                                local speakerCount = countSpeakersForDevice(vx, vy, vz)
                                local volMultiplier = math.min(0.4 + (speakerCount - 1) * 0.15, 1.0)
                                local vol = (hifiSong.baseVol or 0.4) * volMultiplier

                                local spSq = speakerObj:getSquare()
                                local spx = spSq:getX()
                                local spy = spSq:getY()
                                local spz = spSq:getZ()

                                local needsCreate = false
                                if not data.emitter then
                                    needsCreate = true
                                elseif soundName ~= data.lastMedia then
                                    needsCreate = true
                                end

                                if needsCreate then
                                    if data.emitter then stopItemEmitter(data) end
                                    createItemEmitter(data, spx, spy, spz, soundName, vol)
                                    data.lastMedia = soundName
                                else
                                    if data.emitter and data.localmusicid then
                                        if data.emitter.setVolume then
                                            data.emitter:setVolume(data.localmusicid, vol)
                                        end
                                    end
                                end
                            end

                        elseif mediaName then
                            -- True MOOZIC path
                            data.nilTicks = 0

                            if TCMusic and TCMusic.getSoundName then
                                mediaName = TCMusic.getSoundName(mediaName) or mediaName
                            end

                            local speakerCount = countSpeakersForDevice(vx, vy, vz)
                            local volMultiplier = math.min(0.4 + (speakerCount - 1) * 0.15, 1.0)
                            local vol = (vinylData["volume"] or 1) * volMultiplier
                            local startTime = vinylData["startTime"]

                            local vinylEmitterReady = TCMusic and TCMusic.worldEmitters and TCMusic.worldEmitters[vinylMusicId]

                            if data.waitingForSync then
                                if startTime and startTime ~= data.waitingForSync then
                                    data.waitingForSync = nil
                                    data.waitingSyncSong = nil
                                end
                            end

                            if data.waitingForSync then
                                -- Still waiting
                            elseif not vinylEmitterReady then
                                -- Not loaded yet
                            else
                                local spSq = speakerObj:getSquare()
                                local spx = spSq:getX()
                                local spy = spSq:getY()
                                local spz = spSq:getZ()

                                local needsCreate = false
                                if not data.emitter then
                                    needsCreate = true
                                elseif mediaName ~= data.lastMedia then
                                    needsCreate = true
                                elseif startTime and data.lastStartTime and startTime < data.lastStartTime then
                                    needsCreate = true
                                end

                                if needsCreate then
                                    if data.emitter then stopItemEmitter(data) end
                                    createItemEmitter(data, spx, spy, spz, mediaName, vol)
                                    data.lastMedia = mediaName
                                    data.lastStartTime = startTime
                                else
                                    if data.emitter and data.localmusicid then
                                        if data.emitter.setVolume then
                                            data.emitter:setVolume(data.localmusicid, vol)
                                        end
                                    end
                                    if startTime then
                                        data.lastStartTime = startTime
                                    end
                                end
                            end

                        else
                            -- No music from either source
                            data.nilTicks = (data.nilTicks or 0) + 1
                            if data.nilTicks > 60 then
                                if data.emitter or data.localmusicid then
                                    stopItemEmitter(data)
                                end
                                data.waitingForSync = nil
                                data.waitingSyncSong = nil
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnTick.Add(onTickItemSpeakerSync)

------------------------------------------------------------------
-- Handle server commands (all clients)
------------------------------------------------------------------
local function startItemSpeakerFromBroadcast(args)
    local sq = getCell():getGridSquare(args.speakerX, args.speakerY, args.speakerZ)
    if not sq then return end
    local wobjs = sq:getWorldObjects()
    if not wobjs then return end
    for i = 0, wobjs:size() - 1 do
        local o = wobjs:get(i)
        if isSpeakerWorldItem(o) then
            local md = o:getModData()
            if md and md.tmspeaker and md.tmspeaker.connected then
                local key = "item-" .. sq:getX() .. "-" .. sq:getY() .. "-" .. sq:getZ()
                if not itemSpeakerEmitters[key] then
                    speakerSyncStart(o)
                end
                -- Detect mid-song state (client-local audio)
                local sdata = itemSpeakerEmitters[key]
                if sdata then
                    local vx = md.tmspeaker.masterX or md.tmspeaker.vinylX
                    local vy = md.tmspeaker.masterY or md.tmspeaker.vinylY
                    local vz = md.tmspeaker.masterZ or md.tmspeaker.vinylZ
                    if vx and vy and vz then
                        local midSong = false
                        if md.tmspeaker.masterType == "hifi" then
                            -- HiFi: check HiFi modData directly (skip trueMusicData)
                            local hifiSong = getHifiSongData(vx, vy, vz)
                            if hifiSong then midSong = true end
                        else
                            -- Vinyl: check trueMusicData
                            local vinylMusicId = "#" .. vx .. "-" .. vy .. "-" .. vz
                            local trueMusicData = ModData.getOrCreate("trueMusicData")
                            local nowPlay = trueMusicData and trueMusicData["now_play"]
                            local vinylData = nowPlay and nowPlay[vinylMusicId]
                            if vinylData and vinylData["startTime"] then
                                midSong = vinylData["startTime"]
                            end
                        end
                        if midSong then
                            sdata.waitingForSync = midSong
                            if midSong == true then
                                local hs = getHifiSongData(vx, vy, vz)
                                if hs then sdata.waitingSyncSong = hs.soundName end
                            end
                        end
                    end
                end
            end
            break
        end
    end
end

local function onItemServerCommand(module, command, args)
    if module ~= 'tmspeaker' then return end
    if command == 'speakerConnected' then
        if not args.isTileSpeaker then
            startItemSpeakerFromBroadcast(args)
        end
    elseif command == 'speakerDisconnected' then
        if not args.isTileSpeaker then
            local key = "item-" .. args.speakerX .. "-" .. args.speakerY .. "-" .. args.speakerZ
            local data = itemSpeakerEmitters[key]
            if data then
                stopItemEmitter(data)
                itemSpeakerEmitters[key] = nil
            end
        end
    elseif command == 'connectResult' then
        if not args.isTileSpeaker then
            local player = getSpecificPlayer(0)
            if player and player.Say then
                if args.success then
                    local msg = getText("IGUI_TMSpeaker_ConnectedMsg") or "Connected to %1 (%2ft wire)"
                    msg = msg:gsub("%%1", args.deviceName or "device"):gsub("%%2", tostring(args.ftUsed or 0))
                    player:Say(msg)
                else
                    player:Say(args.msg or (getText("IGUI_TMSpeaker_ConnectFailed") or "Connection failed"))
                end
            end
        end
    elseif command == 'disconnectResult' then
        if not args.isTileSpeaker then
            local player = getSpecificPlayer(0)
            if player and player.Say then
                if args.success then
                    local wr = args.wireRecovered or 0
                    if wr > 0 then
                        local msg = getText("IGUI_TMSpeaker_DisconnectedWire") or "Disconnected (%1ft wire recovered)"
                        msg = msg:gsub("%%1", tostring(wr))
                        player:Say(msg)
                    else
                        player:Say(getText("IGUI_TMSpeaker_DisconnectedMsg") or "Disconnected speaker")
                    end
                end
            end
        end
    end
end

Events.OnServerCommand.Add(onItemServerCommand)

------------------------------------------------------------------
-- Restore connections on game load
------------------------------------------------------------------
local function onGameStartItems()
    for playerIdx = 0, 3 do
        local player = getSpecificPlayer(playerIdx)
        if player then
            local sq = player:getSquare()
            if sq then
                local radius = 50
                local px = sq:getX()
                local py = sq:getY()
                local pz = sq:getZ()
                for dy = -radius, radius do
                    for dx = -radius, radius do
                        local sq2 = getCell():getGridSquare(px + dx, py + dy, pz)
                        if sq2 then
                            local wobjs = sq2:getWorldObjects()
                            if wobjs then
                                for i = 0, wobjs:size() - 1 do
                                    local o = wobjs:get(i)
                                    if isSpeakerWorldItem(o) then
                                        local md = o:getModData()
                                        if md and md.tmspeaker and md.tmspeaker.connected then
                                            speakerSyncStart(o)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnGameStart.Add(onGameStartItems)

------------------------------------------------------------------
-- Re-register item speakers when chunks load
------------------------------------------------------------------
local function onLoadGridsquareItems(sq)
    if not sq then return end
    local wobjs = sq:getWorldObjects()
    if not wobjs then return end
    for i = 0, wobjs:size() - 1 do
        local o = wobjs:get(i)
        if isSpeakerWorldItem(o) then
            local md = o:getModData()
            if md and md.tmspeaker and md.tmspeaker.connected then
                local key = "item-" .. sq:getX() .. "-" .. sq:getY() .. "-" .. sq:getZ()
                if not itemSpeakerEmitters[key] then
                    speakerSyncStart(o)
                end
            end
        end
    end
end

Events.LoadGridsquare.Add(onLoadGridsquareItems)

------------------------------------------------------------------
-- Context menu
------------------------------------------------------------------
local function onFillMenuItems(playerNum, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    if not worldobjects or #worldobjects == 0 then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local doneSquare = {}
    local squares = {}
    for _, obj in ipairs(worldobjects) do
        if obj and obj.getSquare then
            local sq = obj:getSquare()
            if sq and not doneSquare[sq] then
                doneSquare[sq] = true
                table.insert(squares, sq)
            end
        end
    end

    for _, sq in ipairs(squares) do
        local wobjs = sq:getWorldObjects()
        if wobjs then
            for i = 0, wobjs:size() - 1 do
                local obj = wobjs:get(i)
                if isSpeakerWorldItem(obj) then
                    local md = obj:getModData()
                    local connected = md and md.tmspeaker and md.tmspeaker.connected

                    if connected then
                        local devName = (md.tmspeaker.masterName) or "device"
                        local disconnLabel = (getText("ContextMenu_Disconnect_Device") or "Disconnect") .. " (" .. devName .. ")"
                        context:addOption(disconnLabel, player, disconnectDevice, obj)
                    else
                        local devices = findAllMasterDevices(obj, 10)
                        local connectLabel = getText("ContextMenu_Connect_Device") or "Connect"

                        if #devices == 0 then
                            local opt = context:addOption(connectLabel, player, function() end)
                            opt.notAvailable = true
                        elseif #devices == 1 then
                            local dev = devices[1]
                            local sSq = obj:getSquare()
                            local vSq = dev.sq
                            local dist = tileDistance(sSq, vSq)
                            local ftNeeded = dist * WIRE_FT_PER_TILE
                            local totalFt = getTotalWire(player)
                            local label = connectLabel .. " " .. dev.name
                            local canConnect = true
                            if totalFt < ftNeeded then
                                label = label .. " [" .. tostring(ftNeeded) .. "ft needed, have " .. tostring(totalFt) .. "ft]"
                                canConnect = false
                            else
                                label = label .. " (" .. tostring(ftNeeded) .. "ft)"
                            end
                            local opt = context:addOption(label, player, connectToDevice, obj, dev)
                            if not canConnect then
                                opt.notAvailable = true
                            end
                        else
                            -- Multiple devices: sub-menu selector
                            local subMenu = ISContextMenu:getNew(context)
                            local parentOpt = context:addOption(connectLabel)
                            context:addSubMenu(parentOpt, subMenu)
                            local anyAvailable = false
                            for _, dev in ipairs(devices) do
                                local sSq = obj:getSquare()
                                local vSq = dev.sq
                                local dist = tileDistance(sSq, vSq)
                                local ftNeeded = dist * WIRE_FT_PER_TILE
                                local totalFt = getTotalWire(player)
                                local label = dev.name
                                local canConnect = true
                                if totalFt < ftNeeded then
                                    label = label .. " [" .. tostring(ftNeeded) .. "ft needed, have " .. tostring(totalFt) .. "ft]"
                                    canConnect = false
                                else
                                    label = label .. " (" .. tostring(ftNeeded) .. "ft)"
                                end
                                local opt = subMenu:addOption(label, player, connectToDevice, obj, dev)
                                if not canConnect then
                                    opt.notAvailable = true
                                else
                                    anyAvailable = true
                                end
                            end
                            if not anyAvailable then
                                parentOpt.notAvailable = true
                            end
                        end
                    end
                    return
                end
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillMenuItems)
