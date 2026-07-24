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
                end
            end
            
            local itemModData = _item:getModData() or {}
            if _obj then
                local objModData = _obj:getModData()
                
                if objModData.tcmusic then
                    itemModData.tcmusic = objModData.tcmusic
                else
                    itemModData.tcmusic = {}
                end
                
                itemModData.tcmusic.isPlaying = false
                itemModData.tcmusic.deviceType = "InventoryItem"
                
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
                if isClient() then
                    ModData.transmit("trueMusicData")
                end
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
                tmData["now_play"][musicId] = nil
                TCMusic.clearLegacyWorldNowPlay(tmData["now_play"], x, y, z, radioItemID, musicId)
                if isClient() then
                    ModData.transmit("trueMusicData")
                end
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
            end
        end
    end
end

function TCMusic.AdvancedSoundOptions()
    SystemDisabler.setEnableAdvancedSoundOptions(true)
end

function TCMusic.OnObjectAboutToBeRemoved(object)
    TCMusic.OnObjectAboutToBeRemovedAux(object)
end

Events.OnObjectAboutToBeRemoved.Add(TCMusic.OnObjectAboutToBeRemoved)
Events.OnGameBoot.Add(TCMusic.AdvancedSoundOptions)
