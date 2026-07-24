-- TM_Speaker: right-click context for base speaker tiles
-- Lets the player connect a nearby music device (Vinyl Player or HiFi Stereo)
-- so the speaker acts as a synced emitter

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

local SPEAKER_SPRITES = {
    -- Wood Speaker Cabinet (S / N / E / W)
    ["recreational_01_76"] = true,
    ["recreational_01_77"] = true,
    ["recreational_01_78"] = true,
    ["recreational_01_79"] = true,
    -- Black Speaker Cabinet (S / N / W / E)
    ["recreational_01_80"] = true,
    ["recreational_01_81"] = true,
    ["recreational_01_82"] = true,
    ["recreational_01_83"] = true,
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
-- Reverse: device type tag for modData
local MASTER_DEVICE_TYPES = {
    ["Tsarcraft.TCVinylplayer"]                   = "vinyl",
    ["Tsarcraft.TM_HiFiStereo"]                     = "hifi",
}

-- Check if a sprite name belongs to a speaker
local function isSpeakerSprite(sname)
    if not sname then return false end
    if SPEAKER_SPRITES[sname] then return true end
    local short = string.match(sname, "[^.]+$")
    if short and SPEAKER_SPRITES[short] then return true end
    return false
end

-- Check if a sprite name belongs to a vinyl player
local function isVinylSprite(sname)
    if not sname then return false end
    if VINYL_SPRITES[sname] then return true end
    local short = string.match(sname, "[^.]+$")
    if short and VINYL_SPRITES[short] then return true end
    return false
end

-- Get the sprite name of any IsoObject
local function getSpriteName(obj)
    if not obj then return nil end
    if obj.getSprite then
        local spr = obj:getSprite()
        if spr and spr.getName then return spr:getName() end
    end
    if obj.getName then return obj:getName() end
    return nil
end

-- Check if an object is a known master device (vinyl player or HiFi)
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

-- Find ALL master devices (vinyl players + HiFi stereos) within radius
-- Returns a list of { obj, name, sq, type }
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
                -- Tile objects
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
                -- World inventory objects (dropped items)
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
-- Forward declarations
------------------------------------------------------------------
local getHifiSongData

------------------------------------------------------------------
-- Speaker emitter sync system
------------------------------------------------------------------
local speakerEmitters = {}
table.insert(TMSpeakerGlobal.emitterTables, speakerEmitters)

local function speakerSyncStart(speakerObj)
    local sq = speakerObj:getSquare()
    if not sq then return end
    local key = sq:getX() .. "-" .. sq:getY() .. "-" .. sq:getZ()
    speakerEmitters[key] = {
        obj = speakerObj,
        emitter = nil,
        localmusicid = nil,
        lastMedia = nil,
        nilTicks = 0,
    }

    -- If the master device is already mid-song, mark this speaker to wait
    -- until the next track begins so it doesn't play out of sync.
    local md = speakerObj:getModData()
    local tms = md and md.tmspeaker
    if tms and tms.connected then
        local vx = tms.masterX or tms.vinylX
        local vy = tms.masterY or tms.vinylY
        local vz = tms.masterZ or tms.vinylZ
        if vx and vy and vz and getHifiSongData then
            local sdata = speakerEmitters[key]
            if tms.masterType == "hifi" then
                local hifiSong = getHifiSongData(vx, vy, vz)
                if hifiSong then
                    sdata.waitingForSync = true
                    sdata.waitingSyncSong = hifiSong.soundName
                end
            else
                local vinylMusicId = "#" .. vx .. "-" .. vy .. "-" .. vz
                local trueMusicData = ModData.getOrCreate("trueMusicData")
                local nowPlay = trueMusicData and trueMusicData["now_play"]
                local vinylData = nowPlay and nowPlay[vinylMusicId]
                if vinylData and vinylData["startTime"] then
                    sdata.waitingForSync = vinylData["startTime"]
                end
            end
        end
    end
end

local function speakerSyncStop(speakerObj)
    local sq = speakerObj:getSquare()
    if not sq then return end
    local key = sq:getX() .. "-" .. sq:getY() .. "-" .. sq:getZ()
    local data = speakerEmitters[key]
    if data and data.emitter and data.localmusicid then
        if data.emitter.stopSound then
            data.emitter:stopSound(data.localmusicid)
        elseif data.emitter.stopAll then
            data.emitter:stopAll()
        end
    end
    speakerEmitters[key] = nil
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
        isTileSpeaker = true,
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
        speakerSprite = getSpriteName(speakerObj),
        isTileSpeaker = true,
    })
end

-- Pick up speaker (server derives item type from sprite, no client trust)
local function pickUpSpeaker(player, obj)
    if not obj or not obj.getSquare then return end
    speakerSyncStop(obj)
    local sq = obj:getSquare()
    local sname = getSpriteName(obj)
    if not sname then return end
    sendClientCommand(player, 'tmspeaker', 'pickupSpeaker', {
        x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        nameSprite = sname,
    })
end

------------------------------------------------------------------
-- Tick: mirror music at each connected speaker position
-- Checks both True MOOZIC trueMusicData AND HiFi SWTCEmitters
------------------------------------------------------------------
local function stopSpeakerEmitter(data)
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
    data.lastStartTime = nil
end

local function createSpeakerEmitter(data, speakerObj, mediaName, vol)
    if not getWorld() or not getWorld().getFreeEmitter then
        data.createFailed = true
        return
    end
    local spSq = speakerObj:getSquare()
    if not spSq then
        data.createFailed = true
        return
    end
    local spx = spSq:getX()
    local spy = spSq:getY()
    local spz = spSq:getZ()
    local emitter = getWorld():getFreeEmitter(spx, spy, spz)
    if not emitter then
        data.createFailed = true
        return
    end
    if emitter.setPos then emitter:setPos(spx, spy, spz) end

    local localId = nil
    if emitter.playSoundImpl then
        localId = emitter:playSoundImpl(mediaName, IsoObject.new())
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
        data.volume = vol
        data.createFailed = nil
    else
        data.createFailed = true
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

------------------------------------------------------------------------
-- Distance-based volume fade (matches HiFi / boombox behaviour)
------------------------------------------------------------------------
local SPEAKER_HEAR_RADIUS = 100   -- silent beyond
local SPEAKER_FADE_RADIUS = 80    -- full volume within

local function calculateSpeakerVolByDistance(speakerObj, baseVol)
    local p = getPlayer()
    if not p then return 0 end
    local dx = p:getX() - speakerObj:getX()
    local dy = p:getY() - speakerObj:getY()
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance <= SPEAKER_FADE_RADIUS then
        return baseVol
    elseif distance <= SPEAKER_HEAR_RADIUS then
        local fadeRange   = SPEAKER_HEAR_RADIUS - SPEAKER_FADE_RADIUS
        local fadeDistance = distance - SPEAKER_FADE_RADIUS
        return baseVol * (1 - fadeDistance / fadeRange)
    end
    return 0
end
------------------------------------------------------------------------

local function readHifiSlots(md)
    if not md then return nil end
    if md.hifiCD and md.hifiCD.isPlaying and md.hifiCD.tracks then
        local idx = md.hifiCD.currentTrack or 1
        local track = md.hifiCD.tracks[idx]
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
local HIFI_SONG_DBG = 0
local function isTMSpeakerDebugEnabled()
    return SandboxVars and SandboxVars.PZTrueMusicSandbox and SandboxVars.PZTrueMusicSandbox.TMSpeakerDebug == true
end

getHifiSongData = function(vx, vy, vz)
    local sq = getCell():getGridSquare(vx, vy, vz)
    HIFI_SONG_DBG = HIFI_SONG_DBG + 1
    local doLog = isTMSpeakerDebugEnabled() and (HIFI_SONG_DBG % 200 == 0)
    if not sq then
        if doLog then print("[TMSpeaker] getHifiSongData: NO SQUARE at " .. vx .. "," .. vy .. "," .. vz) end
        return nil
    end
    local wobjs = sq:getWorldObjects()
    if wobjs and doLog then print("[TMSpeaker] getHifiSongData: " .. wobjs:size() .. " world objs at " .. vx .. "," .. vy .. "," .. vz) end
    if wobjs then
        for i = 0, wobjs:size() - 1 do
            local w = wobjs:get(i)
            if instanceof(w, "IsoWorldInventoryObject") then
                local it = w:getItem()
                if it and it.getFullType then
                    if doLog then print("[TMSpeaker]   worldObj fullType=" .. tostring(it:getFullType()) .. " match=" .. tostring(HIFI_DEVICE_TYPES[it:getFullType()] or false)) end
                    if HIFI_DEVICE_TYPES[it:getFullType()] then
                        local r = readHifiSlots(w:getModData()) or readHifiSlots(it:getModData())
                        if doLog then print("[TMSpeaker]   readHifiSlots from worldObj -> " .. tostring(r ~= nil)) end
                        -- Only return if we actually found playing data;
                        -- otherwise fall through to check the IsoWaveSignal tile object
                        if r then return r end
                    end
                end
            end
        end
    end
    local objects = sq:getObjects()
    if doLog then print("[TMSpeaker] getHifiSongData: " .. (objects and objects:size() or 0) .. " tile objs at " .. vx .. "," .. vy .. "," .. vz) end
    if objects then
        for i = 0, objects:size() - 1 do
            local o = objects:get(i)
            local isWave = instanceof(o, "IsoWaveSignal")
            local isRadio = instanceof(o, "IsoRadio")
            if doLog then
                local sname = getSpriteName(o) or "?"
                print("[TMSpeaker]   tileObj[" .. i .. "] sprite=" .. sname .. " isWave=" .. tostring(isWave) .. " isRadio=" .. tostring(isRadio))
            end
            if isRadio or isWave then
                local md = o:getModData()
                if doLog then
                    print("[TMSpeaker]   modData keys: hifiCD=" .. tostring(md.hifiCD ~= nil) .. " hifiTape=" .. tostring(md.hifiTape ~= nil) .. " hifiVinyl=" .. tostring(md.hifiVinyl ~= nil) .. " hifiDeviceType=" .. tostring(md.hifiDeviceType))
                    if md.hifiCD then
                        print("[TMSpeaker]   hifiCD.isPlaying=" .. tostring(md.hifiCD.isPlaying) .. " tracks=" .. tostring(md.hifiCD.tracks ~= nil) .. " currentTrack=" .. tostring(md.hifiCD.currentTrack))
                    end
                    if md.hifiTape then
                        print("[TMSpeaker]   hifiTape.isPlaying=" .. tostring(md.hifiTape.isPlaying) .. " mediaItem=" .. tostring(md.hifiTape.mediaItem))
                    end
                    if md.hifiVinyl then
                        print("[TMSpeaker]   hifiVinyl.isPlaying=" .. tostring(md.hifiVinyl.isPlaying) .. " mediaItem=" .. tostring(md.hifiVinyl.mediaItem))
                    end
                end
                local result = readHifiSlots(md)
                if result then return result end
            end
        end
    end
    return nil
end

local SPEAKER_TICK_DBG_INTERVAL = 0
local function onTickSpeakerSync()
    SPEAKER_TICK_DBG_INTERVAL = SPEAKER_TICK_DBG_INTERVAL + 1
    local doLog = isTMSpeakerDebugEnabled() and (SPEAKER_TICK_DBG_INTERVAL % 200 == 0)
    if doLog then
        local count = 0
        for _ in pairs(speakerEmitters) do count = count + 1 end
        print("[TMSpeaker] onTickSpeakerSync: tracking " .. count .. " speaker(s)")
    end
    for key, data in pairs(speakerEmitters) do
        local speakerObj = data.obj
        if not speakerObj or not speakerObj.getSquare then
            if doLog then print("[TMSpeaker]   " .. key .. " -> obj missing or no getSquare, removing") end
            speakerEmitters[key] = nil
        else
            local spMd = speakerObj:getModData()
            local tms = spMd and spMd.tmspeaker
            if not tms or not tms.connected then
                if doLog then print("[TMSpeaker]   " .. key .. " -> not connected, removing") end
                stopSpeakerEmitter(data)
                speakerEmitters[key] = nil
            else
                local vx = tms.masterX or tms.vinylX
                local vy = tms.masterY or tms.vinylY
                local vz = tms.masterZ or tms.vinylZ
                if doLog then print("[TMSpeaker]   " .. key .. " -> master=" .. tostring(vx) .. "," .. tostring(vy) .. "," .. tostring(vz) .. " type=" .. tostring(tms.masterType)) end
                if vx and vy and vz then
                    if not masterExistsAt(vx, vy, vz) then
                        if doLog then print("[TMSpeaker]   " .. key .. " -> master NOT found at pos, auto-disconnect") end
                        -- Stop local emitter; server handles wire recovery
                        stopSpeakerEmitter(data)
                        speakerEmitters[key] = nil
                        local player = getSpecificPlayer(0)
                        if player then
                            local autoSq = speakerObj:getSquare()
                            if autoSq then
                                sendClientCommand(player, 'tmspeaker', 'autoDisconnectSpeaker', {
                                    speakerX = autoSq:getX(),
                                    speakerY = autoSq:getY(),
                                    speakerZ = autoSq:getZ(),
                                    speakerSprite = getSpriteName(speakerObj),
                                    isTileSpeaker = true,
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

                        if doLog then print("[TMSpeaker]   " .. key .. " -> hifiSong=" .. tostring(hifiSong ~= nil) .. " vinylMedia=" .. tostring(mediaName) .. " emitter=" .. tostring(data.emitter ~= nil) .. " musicid=" .. tostring(data.localmusicid)) end

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
                                local baseVol = (hifiSong.baseVol or 0.4) * volMultiplier
                                local vol = calculateSpeakerVolByDistance(speakerObj, baseVol)

                                local needsCreate = false
                                if not data.emitter and not data.createFailed then
                                    needsCreate = true
                                elseif soundName ~= data.lastMedia then
                                    data.createFailed = nil
                                    needsCreate = true
                                end

                                if needsCreate then
                                    if data.emitter then stopSpeakerEmitter(data) end
                                    createSpeakerEmitter(data, speakerObj, soundName, vol)
                                    data.lastMedia = soundName
                                else
                                    -- Update volume by distance (only if changed)
                                    if data.emitter and data.localmusicid then
                                        if math.abs((data.volume or 0) - vol) > 0.01 then
                                            if data.emitter.setVolume then
                                                data.emitter:setVolume(data.localmusicid, vol)
                                            end
                                            data.volume = vol
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
                            local baseVol = (vinylData["volume"] or 1) * volMultiplier
                            local vol = calculateSpeakerVolByDistance(speakerObj, baseVol)
                            local startTime = vinylData["startTime"]

                            local vinylEmitterReady = TCMusic and TCMusic.worldEmitters and TCMusic.worldEmitters[vinylMusicId]

                            if data.waitingForSync then
                                if startTime and startTime ~= data.waitingForSync then
                                    data.waitingForSync = nil
                                    data.waitingSyncSong = nil
                                end
                            end

                            if data.waitingForSync then
                                -- Still waiting for next track
                            elseif not vinylEmitterReady then
                                -- Emitter not loaded yet
                            else
                                local needsCreate = false
                                if not data.emitter and not data.createFailed then
                                    needsCreate = true
                                elseif mediaName ~= data.lastMedia then
                                    data.createFailed = nil
                                    needsCreate = true
                                elseif startTime and data.lastStartTime and startTime < data.lastStartTime then
                                    data.createFailed = nil
                                    needsCreate = true
                                end

                                if needsCreate then
                                    if data.emitter then stopSpeakerEmitter(data) end
                                    createSpeakerEmitter(data, speakerObj, mediaName, vol)
                                    data.lastMedia = mediaName
                                    data.lastStartTime = startTime
                                else
                                    -- Update volume by distance (only if changed)
                                    if data.emitter and data.localmusicid then
                                        if math.abs((data.volume or 0) - vol) > 0.01 then
                                            if data.emitter.setVolume then
                                                data.emitter:setVolume(data.localmusicid, vol)
                                            end
                                            data.volume = vol
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
                                    stopSpeakerEmitter(data)
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

Events.OnTick.Add(onTickSpeakerSync)

------------------------------------------------------------------
-- Handle server commands (all clients)
------------------------------------------------------------------
local function startTileSpeakerFromBroadcast(args)
    local sq = getCell():getGridSquare(args.speakerX, args.speakerY, args.speakerZ)
    if not sq then return end
    local objects = sq:getObjects()
    if not objects then return end
    for i = 0, objects:size() - 1 do
        local o = objects:get(i)
        if isSpeakerSprite(getSpriteName(o)) then
            local md = o:getModData()
            if md and md.tmspeaker and md.tmspeaker.connected then
                local key = sq:getX() .. "-" .. sq:getY() .. "-" .. sq:getZ()
                if not speakerEmitters[key] then
                    speakerSyncStart(o)
                end
            end
            break
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= 'tmspeaker' then return end
    if command == 'speakerConnected' then
        if args.isTileSpeaker then
            startTileSpeakerFromBroadcast(args)
        end
    elseif command == 'speakerDisconnected' then
        if args.isTileSpeaker then
            local key = args.speakerX .. "-" .. args.speakerY .. "-" .. args.speakerZ
            local data = speakerEmitters[key]
            if data then
                stopSpeakerEmitter(data)
                speakerEmitters[key] = nil
            end
        end
    elseif command == 'connectResult' then
        if args.isTileSpeaker then
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
        if args.isTileSpeaker then
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

Events.OnServerCommand.Add(onServerCommand)

------------------------------------------------------------------
-- Restore speaker connections on game load
------------------------------------------------------------------
local function onGameStart()
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
                            local objects = sq2:getObjects()
                            if objects then
                                for i = 0, objects:size() - 1 do
                                    local o = objects:get(i)
                                    local sname = getSpriteName(o)
                                    if isSpeakerSprite(sname) then
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

Events.OnGameStart.Add(onGameStart)

------------------------------------------------------------------
-- Re-register speakers when chunks load
------------------------------------------------------------------
local function onLoadGridsquare(sq)
    if not sq then return end
    local objects = sq:getObjects()
    if not objects then return end
    for i = 0, objects:size() - 1 do
        local o = objects:get(i)
        local sname = getSpriteName(o)
        if isSpeakerSprite(sname) then
            local md = o:getModData()
            if md and md.tmspeaker and md.tmspeaker.connected then
                local key = sq:getX() .. "-" .. sq:getY() .. "-" .. sq:getZ()
                if not speakerEmitters[key] then
                    speakerSyncStart(o)
                end
            end
        end
    end
end

Events.LoadGridsquare.Add(onLoadGridsquare)

------------------------------------------------------------------
-- Context menu
------------------------------------------------------------------
local function onFillMenu(playerNum, context, worldobjects, test)
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
        local objects = sq:getObjects()
        if objects then
            for i = 0, objects:size() - 1 do
                local obj = objects:get(i)
                if obj then
                    local sname = getSpriteName(obj)
                    if isSpeakerSprite(sname) then
                        local md = obj:getModData()
                        local connected = md and md.tmspeaker and md.tmspeaker.connected

                        if connected then
                            local devName = (md.tmspeaker.masterName) or "device"
                            local disconnLabel = (getText("ContextMenu_Disconnect_Device") or "Disconnect") .. " (" .. devName .. ")"
                            context:addOption(disconnLabel, player, disconnectDevice, obj)
                        else
                            local devices = findAllMasterDevices(obj, 30)
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
                        context:addOption(getText("ContextMenu_PickUp_Speaker") or "Pick up speaker", player, pickUpSpeaker, obj)
                        return
                    end
                end
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillMenu)
