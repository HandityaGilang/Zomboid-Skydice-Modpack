require "TCMusicDefenitions"

local DEBUG = false
local function dlog(msg)
    if DEBUG then
        print(msg)
    end
end
local PROBE = false
local function probe(msg)
    if PROBE then
        print("[TMDBG][PickupSync] " .. tostring(msg))
    end
end

local pendingStartDevice = {
    sent = false,
    lastCharId = nil,
    countdown = 0,
}

local function getClientCharacterId(player)
    if not player then return nil end
    local desc = player.getDescriptor and player:getDescriptor() or nil
    if desc and desc.getID then
        return desc:getID()
    end
    if player.getID then
        return player:getID()
    end
    return nil
end

local function requestStartDeviceWhenReady()
    if not isClient() or not sendClientCommand then return end
    local player = getPlayer()
    if not player or player:isDead() then return end

    local charId = getClientCharacterId(player)
    if pendingStartDevice.lastCharId ~= charId then
        pendingStartDevice.lastCharId = charId
        pendingStartDevice.sent = false
        pendingStartDevice.countdown = 120
    end

    if pendingStartDevice.sent then return end
    if not charId then return end

    if pendingStartDevice.countdown > 0 then
        pendingStartDevice.countdown = pendingStartDevice.countdown - 1
        return
    end

    dlog("[TCStartWithDevice] client sending RequestStartDevice (charId=" .. tostring(charId) .. ")")
    sendClientCommand("truemusic", "RequestStartDevice", {})
    pendingStartDevice.sent = true
end

Events.OnPlayerUpdate.Add(requestStartDeviceWhenReady)
require "TCMusicContainerFilter"
require "TCBoomboxEquipFix"

if not TCMusic.worldEmitters then TCMusic.worldEmitters = {} end

function TCMusic.makeWorldMusicId(x, y, z, radioItemID)
    if radioItemID ~= nil and tostring(radioItemID) ~= "" then
        return "W:" .. tostring(radioItemID)
    end
    if x ~= nil and y ~= nil and z ~= nil then
        return "#" .. tostring(x) .. "-" .. tostring(y) .. "-" .. tostring(z)
    end
    return nil
end

function TCMusic.getWorldMusicIdForDevice(device)
    if not device then return nil end
    local md = device.getModData and device:getModData() or nil
    local rid = md and md.RadioItemID or nil
    local x = device.getX and device:getX() or nil
    local y = device.getY and device:getY() or nil
    local z = device.getZ and device:getZ() or nil
    return TCMusic.makeWorldMusicId(x, y, z, rid)
end

function TCMusic.clearLegacyWorldNowPlay(nowPlay, x, y, z, radioItemID, keepMusicId)
    if not nowPlay then return end
    local keep = keepMusicId and tostring(keepMusicId) or nil
    local legacy = (x ~= nil and y ~= nil and z ~= nil) and ("#" .. tostring(x) .. "-" .. tostring(y) .. "-" .. tostring(z)) or nil
    if legacy and legacy ~= keep then
        nowPlay[legacy] = nil
    end
    if radioItemID ~= nil then
        local rid = tostring(radioItemID)
        for k, row in pairs(nowPlay) do
            if k ~= keep and string.sub(tostring(k), 1, 1) == "#" then
                local rowId = row and row.itemid and tostring(row.itemid) or nil
                if rowId == rid then
                    nowPlay[k] = nil
                end
            end
        end
    end
end

function TCMusic.getSoundName(mediaItem)
    if not mediaItem then return nil end
    local dotPos = string.find(mediaItem, "%.")
    if dotPos then
        return string.sub(mediaItem, dotPos + 1)
    end
    return mediaItem
end

function TCMusic.stopWorldMusic(x, y, z, radioItemID)
    local coordId = (x ~= nil and y ~= nil and z ~= nil) and ("#" .. x .. "-" .. y .. "-" .. z) or nil
    local canonicalId = (radioItemID ~= nil and tostring(radioItemID) ~= "") and ("W:" .. tostring(radioItemID)) or nil
    local rid = (radioItemID ~= nil and tostring(radioItemID) ~= "") and tostring(radioItemID) or nil
    for musicId, data in pairs(TCMusic.worldEmitters) do
        local sameCoordKey = coordId and tostring(musicId) == coordId
        local sameCanonicalKey = canonicalId and tostring(musicId) == canonicalId
        local sameDataCoord = data and x ~= nil and y ~= nil and z ~= nil and data.x == x and data.y == y and data.z == z
        local dataRid = data and (data.radioItemID or data.itemid) or nil
        local sameDataRid = rid and dataRid and tostring(dataRid) == rid
        if sameCoordKey or sameCanonicalKey or sameDataCoord or sameDataRid then
            if data and data.emitter then
                if data.emitter.stopSound and data.localmusicid then
                    data.emitter:stopSound(data.localmusicid)
                elseif data.emitter.stopAll then
                    data.emitter:stopAll()
                end
            end
            probe("destroy local world emitter musicId=" .. tostring(musicId) .. " reason=pickup-sweep coord=" .. tostring(coordId) .. " canonical=" .. tostring(canonicalId) .. " rid=" .. tostring(rid))
            TCMusic.worldEmitters[musicId] = nil
        end
    end
end

-- Pickup continuity: when a placed device is grabbed, remember its state so we
-- can keep the tape and auto-equip a boombox to the primary hand.
-- Playback intentionally does NOT auto-resume on pickup.
TCMusic.pendingPickup = TCMusic.pendingPickup or {}
local pendingPickupCount = 0

local function copyTcmusic(t)
    if not t then return nil end
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

local function registerPendingPickup(item, resumeData, tcmusicSnapshot)
    if not item or not item.getID then return end
    if not TCMusic.pendingPickup[item:getID()] then
        pendingPickupCount = pendingPickupCount + 1
    end
    TCMusic.pendingPickup[item:getID()] = {
        resume = resumeData, -- nil, or { mediaItem, volume } (informational only)
        tcmusic = tcmusicSnapshot, -- copied device modData, re-applied to the arrived item (MP-safe)
        ticks = 900,
        synced = false,
        equipQueued = false,
    }
end

function TCMusic.OnObjectAboutToBeRemovedAux(object)
    if instanceof(object, "IsoWorldInventoryObject") then
        local _item = object:getItem()
        if _item and instanceof(_item, "Radio") then
            probe("OnObjectAboutToBeRemoved isoWorldItem radio id=" .. tostring(_item.getID and _item:getID()))
        end
        if _item and instanceof(_item, "Radio") and TCMusic.WorldMusicPlayer[_item:getFullType()] then
            local square = object:getSquare()
            if not square then return end
            local sqrObjects = square:getObjects()
            local sqrObjSize = sqrObjects:size()
            local _obj = nil
            local _spriteFallback = nil
            local wantedSprite = TCMusic.WorldMusicPlayer[_item:getFullType()]
            
            for i = 0, sqrObjSize - 1 do
                local tObj = sqrObjects:get(i)
                if instanceof(tObj, "IsoRadio") then
                    local radioItemID = tObj:getModData().RadioItemID
                    local itemId = tostring(_item:getID())
                    if radioItemID ~= nil then
                        radioItemID = tostring(radioItemID)
                    end
                    if radioItemID == itemId or radioItemID == (itemId .. "tm") then
                        _obj = tObj
                        break
                    end
                    -- MP: the server reassigns the item's ID after placement, so the
                    -- RadioItemID stamped client-side at place-time goes stale. Keep a
                    -- sprite-matched candidate to adopt when no ID match exists.
                    if (not _spriteFallback) and wantedSprite and tObj.getSprite and tObj:getSprite()
                        and tObj:getSprite():getName() == wantedSprite then
                        _spriteFallback = tObj
                    end
                end
            end
            if not _obj and _spriteFallback then
                _obj = _spriteFallback
                _obj:getModData().RadioItemID = _item:getID()
                probe("pickup adopt-by-sprite: restamped RadioItemID=" .. tostring(_item:getID()))
            end
            
            local itemModData = _item:getModData() or {}
            if _obj then
                local objModData = _obj:getModData()

                -- Capture playing state before the transitional stop so playback can resume on the holder.
                local resumeData = nil
                if objModData.tcmusic and objModData.tcmusic.isPlaying and objModData.tcmusic.mediaItem then
                    local objDD = _obj:getDeviceData()
                    resumeData = {
                        mediaItem = objModData.tcmusic.mediaItem,
                        volume = objDD and objDD:getDeviceVolume() or nil,
                    }
                end
                
                -- MERGE the IsoRadio's copy over the item's own instead of replacing
                -- it: on a client whose IsoRadio modData never synced, a wholesale
                -- replace clobbers the item's real mediaItem with nothing (tape eaten).
                local mergedTcm = {}
                if itemModData.tcmusic then
                    for k, v in pairs(itemModData.tcmusic) do mergedTcm[k] = v end
                end
                if objModData.tcmusic then
                    for k, v in pairs(objModData.tcmusic) do
                        if v ~= nil then mergedTcm[k] = v end
                    end
                    if not objModData.tcmusic.mediaItem and itemModData.tcmusic and itemModData.tcmusic.mediaItem then
                        mergedTcm.mediaItem = itemModData.tcmusic.mediaItem
                    end
                end
                itemModData.tcmusic = mergedTcm
                
                itemModData.tcmusic.isPlaying = false
                itemModData.tcmusic.deviceType = "InventoryItem"
                -- Carry HiFi deck contents (CD/cassette/vinyl) onto the picked-up
                -- item too, or the loaded media is eaten on pickup.
                if TCMusic and TCMusic.copyHiFiSlots then
                    TCMusic.copyHiFiSlots(objModData, itemModData, true)
                end
                
                local deviceData = _obj:getDeviceData()
                if deviceData then
                    _item:setDeviceData(deviceData)
                end
                _item:getDeviceData():setIsTurnedOn(false)

                local x = _obj:getX()
                local y = _obj:getY()
                local z = _obj:getZ()
                local radioItemID = _item.getID and _item:getID() or nil
                local musicId = TCMusic.makeWorldMusicId(x, y, z, radioItemID)
                local tmData = ModData.getOrCreate("trueMusicData")
                tmData["now_play"] = tmData["now_play"] or {}
                tmData["now_play"][musicId] = nil
                TCMusic.clearLegacyWorldNowPlay(tmData["now_play"], x, y, z, radioItemID, musicId)
                -- World-row removal is synced via the setWorldDevicePlayback command below;
                -- raw client ModData.transmit clobbers other players' rows, so don't.
                if TCMusic and TCMusic.stopWorldMusic then
                    TCMusic.stopWorldMusic(x, y, z, radioItemID)
                end
                if isClient() then
                    local args = {
                        x = x, y = y, z = z,
                        musicId = musicId,
                        isPlaying = false,
                        media = itemModData and itemModData.tcmusic and itemModData.tcmusic.mediaItem or nil,
                        radioItemID = radioItemID,
                        volume = (deviceData and deviceData.getDeviceVolume) and deviceData:getDeviceVolume() or nil,
                    }
                    probe("force-stop world playback on pickup musicId=" .. tostring(musicId) .. " radioItemID=" .. tostring(args.radioItemID) .. " mode=object-or-fallback")
                    sendClientCommand("truemusic", "setWorldDevicePlayback", args)
                end
                
                sendClientCommand('truemusic', 'deleteWO', { 
                    x = _obj:getX(), 
                    y = _obj:getY(), 
                    z = _obj:getZ(),
                    nameSprite = TCMusic.WorldMusicPlayer[_item:getFullType()],
                })
                registerPendingPickup(_item, resumeData, copyTcmusic(itemModData.tcmusic))
            else
                -- Stop fallback stream by world-item square.
                itemModData.tcmusic = itemModData.tcmusic or {}
                itemModData.tcmusic.isPlaying = false
                itemModData.tcmusic.deviceType = "InventoryItem"
                local x = square:getX()
                local y = square:getY()
                local z = square:getZ()
                local radioItemID = _item.getID and _item:getID() or nil
                local musicId = TCMusic.makeWorldMusicId(x, y, z, radioItemID)
                local tmData = ModData.getOrCreate("trueMusicData")
                tmData["now_play"] = tmData["now_play"] or {}
                -- Capture playing state from the world row before clearing it.
                local row = tmData["now_play"][musicId] or tmData["now_play"]["#" .. tostring(x) .. "-" .. tostring(y) .. "-" .. tostring(z)]
                local resumeData = nil
                if row and row.musicName then
                    resumeData = { mediaItem = row.musicName, volume = row.volume }
                    if not itemModData.tcmusic.mediaItem then
                        itemModData.tcmusic.mediaItem = row.musicName
                    end
                end
                tmData["now_play"][musicId] = nil
                TCMusic.clearLegacyWorldNowPlay(tmData["now_play"], x, y, z, radioItemID, musicId)
                -- World-row removal is synced via the setWorldDevicePlayback command below;
                -- raw client ModData.transmit clobbers other players' rows, so don't.
                if TCMusic and TCMusic.stopWorldMusic then
                    TCMusic.stopWorldMusic(x, y, z, radioItemID)
                end
                if isClient() then
                    local args = {
                        x = x, y = y, z = z,
                        musicId = musicId,
                        isPlaying = false,
                        media = itemModData and itemModData.tcmusic and itemModData.tcmusic.mediaItem or nil,
                        radioItemID = radioItemID,
                    }
                    probe("force-stop world playback on pickup musicId=" .. tostring(musicId) .. " radioItemID=" .. tostring(args.radioItemID) .. " mode=object-or-fallback")
                    sendClientCommand("truemusic", "setWorldDevicePlayback", args)
                end
                registerPendingPickup(_item, resumeData, copyTcmusic(itemModData.tcmusic))
            end
        end
    end
end

function TCMusic.AdvancedSoundOptions()
    SystemDisabler.setEnableAdvancedSoundOptions(true)
end

-- Processes pending pickups: re-applies the copied device modData (tape, battery,
-- headphones) onto the item that actually arrives in the inventory. In MP the
-- arriving item is a fresh server copy, so modData written to the old world-item
-- instance is lost — without this restore the tape gets eaten. Then the state is
-- pushed to the server via syncItemFields and boomboxes are equipped into the
-- primary hand. Playback does NOT auto-resume.
local function processPendingPickup()
    if pendingPickupCount <= 0 then return end
    local player = getPlayer()
    if not player or player:isDead() then return end

    for itemId, entry in pairs(TCMusic.pendingPickup) do
        entry.ticks = entry.ticks - 1
        if entry.ticks <= 0 then
            TCMusic.pendingPickup[itemId] = nil
            pendingPickupCount = pendingPickupCount - 1
        else
            local item = player:getInventory():getItemById(itemId)
            if item then
                if not entry.synced then
                    local md = item:getModData()
                    md.tcmusic = md.tcmusic or {}
                    if entry.tcmusic then
                        for k, v in pairs(entry.tcmusic) do
                            md.tcmusic[k] = v
                        end
                    end
                    md.tcmusic.deviceType = "InventoryItem"
                    md.tcmusic.isPlaying = false
                    -- Push the restored modData (mediaItem etc.) to the server so the tape isn't eaten.
                    if TCMusic.safeSyncItem then TCMusic.safeSyncItem(item) elseif isClient() then item:syncItemFields() end
                    entry.synced = true
                    probe("pickup-restore itemId=" .. tostring(itemId) .. " media=" .. tostring(md.tcmusic.mediaItem))
                end

                local fullType = item:getFullType()
                local isBoombox = TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[fullType]
                if not isBoombox then
                    -- Only boomboxes auto-equip; other devices just keep their tape.
                    TCMusic.pendingPickup[itemId] = nil
                    pendingPickupCount = pendingPickupCount - 1
                elseif player:getPrimaryHandItem() == item then
                    TCMusic.pendingPickup[itemId] = nil
                    pendingPickupCount = pendingPickupCount - 1
                elseif not entry.equipQueued then
                    entry.equipQueued = true
                    ISTimedActionQueue.add(ISEquipWeaponAction:new(player, item, 25, true, false))
                end
            end
        end
    end
end

Events.OnTick.Add(processPendingPickup)

function TCMusic.OnObjectAboutToBeRemoved(object)
    TCMusic.OnObjectAboutToBeRemovedAux(object)
end

Events.OnObjectAboutToBeRemoved.Add(TCMusic.OnObjectAboutToBeRemoved)
Events.OnGameBoot.Add(TCMusic.AdvancedSoundOptions)
