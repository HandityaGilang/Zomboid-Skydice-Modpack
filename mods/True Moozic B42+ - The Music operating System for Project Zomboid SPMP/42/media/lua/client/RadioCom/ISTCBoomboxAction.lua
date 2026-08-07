require "TimedActions/ISBaseTimedAction"
require "TCMusicClientFunctions"

ISTCBoomboxAction = ISBaseTimedAction:derive("ISTCBoomboxAction")

local DEBUG = false
local function dlog(msg)
    if DEBUG then
        print(msg)
    end
end
local PROBE = false
local function probe(msg)
    if PROBE then
        print("[TMDBG][ActionClient] " .. tostring(msg))
    end
end

-- Audio-silence debug logs (toggled from sandbox option: PZTrueMoozicDebug page → AudioSilenceDebug)
local function audioDbg(msg)
    if SandboxVars and SandboxVars.PZTrueMusicSandbox and SandboxVars.PZTrueMusicSandbox.AudioSilenceDebug then
        print(msg)
    end
end

local function playCharacterEmitterSound(character, soundName)
    if not character or not soundName or not character.getEmitter then return nil end
    local emitter = character:getEmitter()
    if not emitter then return nil end
    if emitter.playSoundImpl then
        return emitter:playSoundImpl(soundName, character)
    end
    if emitter.playSound then
        return emitter:playSound(soundName)
    end
    return nil
end

local function dispatchClientCommand(character, module, command, args)
    if PROBE then
        local out = {}
        if args then
            for k, v in pairs(args) do
                out[#out + 1] = tostring(k) .. "=" .. tostring(v)
            end
            table.sort(out)
        end
        probe("sendClientCommand module=" .. tostring(module) .. " command=" .. tostring(command) .. " args={" .. table.concat(out, ", ") .. "}")
    end
    return sendClientCommand(character, module, command, args)
end

local function ensureInventoryWalkmanHeadphones(device, deviceData)
    if not device or not deviceData or not device.getModData or not device.getFullType then return end
    local fullType = device:getFullType()
    if not (TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[fullType]) then return end
    if not (deviceData.getHeadphoneType and deviceData.addHeadphones) then return end
    if deviceData:getHeadphoneType() >= 0 then return end

    local md = device:getModData()
    local tcm = md and md.tcmusic or nil
    local hpType = tcm and tcm.headphoneType or md.tm_headphoneType
    if hpType == nil or hpType < 0 then return end

    local hpFullType = (tcm and tcm.headphoneItemFullType) or "Base.Headphones"
    if hpFullType ~= "Base.Headphones" and hpFullType ~= "Base.Earbuds" then
        hpFullType = "Base.Headphones"
    end

    local hpItem = instanceItem and instanceItem(hpFullType) or nil
    if not hpItem then
        probe("rehydrate headphones skipped itemCreate failed fullType=" .. tostring(hpFullType))
        return
    end
    deviceData:addHeadphones(hpItem)
    if md then
        md.tm_hasHeadphones = true
    end
    probe("rehydrate headphones inventory walkman item=" .. tostring(fullType) .. " hpType=" .. tostring(deviceData:getHeadphoneType()) .. " hpItem=" .. tostring(hpFullType))
end

local function getWorldArgs(device, deviceData)
    if not device then return nil end
    local md = device.getModData and device:getModData() or nil
    local radioItemID = md and md.RadioItemID or nil
    if (radioItemID == nil or tostring(radioItemID) == "") and md and md.tcmusic and md.tcmusic.radioItemID then
        radioItemID = md.tcmusic.radioItemID
    end
    if (radioItemID == nil or tostring(radioItemID) == "") then
        local square = device.getSquare and device:getSquare() or nil
        local worldObjects = square and square.getWorldObjects and square:getWorldObjects() or nil
        if worldObjects and md and md.tcmusic and md.tcmusic.mediaItem then
            for i = 0, worldObjects:size() - 1 do
                local wobj = worldObjects:get(i)
                local item = wobj and wobj.getItem and wobj:getItem() or nil
                if item and item.getID and item.getFullType and TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[item:getFullType()] then
                    radioItemID = item:getID()
                    md.RadioItemID = radioItemID
                    md.tcmusic.radioItemID = radioItemID
                    break
                end
            end
        end
    end
    
    if (radioItemID == nil or tostring(radioItemID) == "") then
        local x = device.getX and device:getX() or nil
        local y = device.getY and device:getY() or nil
        local z = device.getZ and device:getZ() or nil
        if x ~= nil and y ~= nil and z ~= nil then
            radioItemID = "C:" .. tostring(x) .. "-" .. tostring(y) .. "-" .. tostring(z)
            if md then
                md.RadioItemID = radioItemID
                md.tcmusic = md.tcmusic or {}
                md.tcmusic.radioItemID = radioItemID
            end
        end
    end
    local media = md and md.tcmusic and md.tcmusic.mediaItem or nil
    local x = device.getX and device:getX() or nil
    local y = device.getY and device:getY() or nil
    local z = device.getZ and device:getZ() or nil
    local volume = (deviceData and deviceData.getDeviceVolume) and deviceData:getDeviceVolume() or nil
    local musicId = TCMusic and TCMusic.makeWorldMusicId and TCMusic.makeWorldMusicId(x, y, z, radioItemID) or ((x and y and z) and ("#" .. tostring(x) .. "-" .. tostring(y) .. "-" .. tostring(z)) or nil)
    return {
        x = x, y = y, z = z,
        radioItemID = radioItemID,
        isJukebox = false,
        media = media,
        volume = volume,
        musicId = musicId,
    }
end

local function getWorldMusicIdForDevice(device)
    if TCMusic and TCMusic.getWorldMusicIdForDevice then
        return TCMusic.getWorldMusicIdForDevice(device)
    end
    if not device then return nil end
    local md = device.getModData and device:getModData() or nil
    local rid = md and md.RadioItemID or nil
    local x = device.getX and device:getX() or nil
    local y = device.getY and device:getY() or nil
    local z = device.getZ and device:getZ() or nil
    if rid ~= nil and tostring(rid) ~= "" then
        return "W:" .. tostring(rid)
    end
    if x ~= nil and y ~= nil and z ~= nil then
        return "W:C:" .. tostring(x) .. "-" .. tostring(y) .. "-" .. tostring(z)
    end
    return (x and y and z) and ("#" .. tostring(x) .. "-" .. tostring(y) .. "-" .. tostring(z)) or nil
end

local function getPortableMusicId(character)
    if not character then return nil end
    if character.getOnlineID then
        local id = tonumber(character:getOnlineID())
        if id and id > 0 then
            return id
        end
    end
    if character.getUsername then
        return character:getUsername()
    end
    return nil
end

local function hasHeadphones(device, deviceData)
    local md = device and device.getModData and device:getModData() or nil
    if md then
        if md.tm_hasHeadphones ~= nil then
            return md.tm_hasHeadphones
        end
        if md.tcmusic and md.tcmusic.headphoneType ~= nil then
            return md.tcmusic.headphoneType >= 0
        end
    end
    return deviceData and deviceData.getHeadphoneType and deviceData:getHeadphoneType() >= 0
end

local function resolveMediaFullType(mediaItem)
    if not mediaItem then return nil end
    if string.find(mediaItem, "%.") then
        return mediaItem
    end
    local fallback = "Tsarcraft." .. mediaItem
    if getScriptManager():FindItem(fallback) then
        return fallback
    end
    return nil
end

local function createMediaItem(mediaItem)
    local fullType = resolveMediaFullType(mediaItem)
    if not fullType then
        dlog("ISTCBoomboxAction: Unknown media type, skipping remove")
        return nil
    end
    return instanceItem(fullType)
end

local function findLinkedWorldItem(device)
    if not device or not device.getModData then return nil end
    local md = device:getModData()
    if not md then return nil end
    local square = device.getSquare and device:getSquare() or nil
    if not square or not square.getWorldObjects then return nil end
    local link = md.RadioItemID and tostring(md.RadioItemID) or nil
    local wantedSprite = device.getSprite and device:getSprite() and device:getSprite():getName() or nil
    local worldObjects = square:getWorldObjects()
    local fallback = nil
    for i = 0, worldObjects:size() - 1 do
        local worldObj = worldObjects:get(i)
        if instanceof(worldObj, "IsoWorldInventoryObject") then
            local item = worldObj:getItem()
            if item and item.getID then
                local itemId = tostring(item:getID())
                if link and (itemId == link or (itemId .. "tm") == link) then
                    return item
                end
                -- MP: the server reassigns item IDs, so the stamped link goes
                -- stale - fall back to the co-located device item whose
                -- fullType maps to this device's sprite.
                if (not fallback) and item.getFullType and TCMusic and TCMusic.WorldMusicPlayer
                    and TCMusic.WorldMusicPlayer[item:getFullType()]
                    and (wantedSprite == nil or TCMusic.WorldMusicPlayer[item:getFullType()] == wantedSprite) then
                    fallback = item
                end
            end
        end
    end
    if fallback then
        md.RadioItemID = fallback:getID()
        if md.tcmusic then md.tcmusic.radioItemID = md.RadioItemID end
        return fallback
    end
    return nil
end

local function findLifestyleJukeboxHost(device)
    
    return nil
end

local function isLifestyleJukeboxPoweredOn(device)
    
    return true
end

local function stopLifestyleJukeboxTrack(device)
    
end

local function stopSiblingJukeboxProxyPlayback(device)
    
end

local function stopAllJukeboxProxyPlayback(device)
    
end

local function shouldTransmitDeviceModData(device)
    if not device or not device.getModData then return false end
    local md = device:getModData()
    local tcmusic = md and md.tcmusic or nil
    if tcmusic and tcmusic.deviceType then
        return tcmusic.deviceType == "IsoObject"
    end
    return instanceof(device, "IsoWaveSignal")
end

local function getJukeboxMusicPlayer(device)
    
    return nil
end

local function getMusicPlayerForActionDevice(device)
    if not device or not device.getModData then return nil end
    local tcm = device:getModData().tcmusic or nil
    if not tcm then return nil end

    if tcm.deviceType == "InventoryItem" then
        return TCMusic.ItemMusicPlayer[device:getFullType()] or TCMusic.WalkmanPlayer[device:getFullType()]
    elseif tcm.deviceType == "IsoObject" then
        local jukeboxMusicPlayer = getJukeboxMusicPlayer(device)
        if jukeboxMusicPlayer then
            return jukeboxMusicPlayer
        end
        local sprite = device.getSprite and device:getSprite() or nil
        local spriteName = sprite and sprite.getName and sprite:getName() or nil
        return spriteName and TCMusic.WorldMusicPlayer[spriteName] or nil
    elseif tcm.deviceType == "VehiclePart" then
        local invItem = device.getInventoryItem and device:getInventoryItem() or nil
        return invItem and TCMusic.VehicleMusicPlayer[invItem:getFullType()] or nil
    end

    return nil
end

local function syncJukeboxModeMedia(device)
    
end

local function applyJukeboxModeMedia(device)
    
end

local function primeJukeboxModeMediaForNextPlay(device)
    
    return false
end

local function transmitDeviceModDataIfNeeded(device)
    if device and device.transmitModData and shouldTransmitDeviceModData(device) then
        device:transmitModData()
    end
end

local function stopCharacterMusic(character)
    if not character then return end
    -- Any stop cancels a not-yet-fired synchronized start.
    TCMusic.pendingOwnerStart = nil
    local md = character.getModData and character:getModData() or nil
    local tmId = md and md.tcmusicid or nil
    if tmId then
        character:getEmitter():stopSound(tmId)
    end
    if md then
        md.tcmusicid = nil
        md.tcWalkmanItemId = nil
        md.tcWalkmanMedia = nil
    end
    -- Walkman session (local-only playback, state lives OUTSIDE the item so
    -- server item echoes can't roll it back): stop + clear.
    local ws = TCMusic.WalkmanSession
    if ws and ws.soundId then
        character:getEmitter():stopSound(ws.soundId)
    end
    TCMusic.WalkmanSession = nil
    -- Boombox session (same Tal-style principle: play state lives OUTSIDE
    -- the item; other players hear us via the shared now_play row).
    local bs = TCMusic.BoomboxSession
    if bs and bs.soundId then
        character:getEmitter():stopSound(bs.soundId)
    end
    TCMusic.BoomboxSession = nil
end

-- Push the portable device's modData (tcmusic.isPlaying / mediaItem) to the
-- server after every client-side playback state change. Without this the
-- server keeps a STALE copy of the item; any later ItemStats echo from the
-- server then overwrites the client's state (play/stop button flipping back
-- by itself) and other clients can never match the device by media. Only
-- top-level (main inventory / equipped / attached) items are synced: an item
-- nested inside a bag makes remote clients NPE on the ItemStats ContainerID
-- ("containingItem is null").
local function syncPortableDevice(device)
    if not isClient() then return end
    if not device or not device.syncItemFields or not device.getModData then return end
    local tcm = device:getModData().tcmusic
    if tcm and tcm.deviceType and tcm.deviceType ~= "InventoryItem" then return end
    local cont = device.getContainer and device:getContainer() or nil
    if cont and cont.getContainingItem and cont:getContainingItem() ~= nil then return end
    device:syncItemFields()
end

-- Overhead status text (vanilla TV/radio style). Placed devices get the
-- text above the DEVICE, everything else above the acting player.
-- Uses semantic keys (IGUI_TMS_*): shown locally in the actor's language
-- and relayed via the server so nearby players see it in THEIRS.
local function speechSay(self, key, arg)
    if not TMSpeech then return end
    local tcm = self.device and self.device.getModData and self.device:getModData().tcmusic or nil
    if tcm and tcm.deviceType == "IsoObject" and self.device.getX then
        TMSpeech.announceDevice(self.device, key, arg)
    else
        TMSpeech.announce(self.character, key, arg)
    end
end

local function speechStop(self)
    if not TMSpeech then return end
    local tcm = self.device and self.device.getModData and self.device:getModData().tcmusic or nil
    local onDevice = tcm and tcm.deviceType == "IsoObject" and self.device.getX
    if isClient() then
        if onDevice then
            TMSpeech.announceDevice(self.device, "StopSend")
            TMSpeech.announceDeviceLater(self.device, "StopDone", nil, 900)
        else
            TMSpeech.announce(self.character, "StopSend")
            TMSpeech.announceLater(self.character, "StopDone", nil, 900)
        end
    else
        speechSay(self, "Stopped")
    end
end

-- MP synchronized start announced: cue sound + status line on the actor.
local function speechHandshake(self, sid)
    if not TMSpeech or not isClient() then return end
    -- Handshake disabled (sandbox default): no cue, no "waiting" text -
    -- the "Playing" announce fires when the sound starts moments later.
    if not (TCMusic.syncHandshakeEnabled and TCMusic.syncHandshakeEnabled()) then return end
    local tcm = self.device and self.device.getModData and self.device:getModData().tcmusic or nil
    if tcm and tcm.deviceType == "IsoObject" and self.device.getX then
        TMSpeech.announceDevice(self.device, "Handshake")
    else
        TMSpeech.announce(self.character, "Handshake")
    end
    TMSpeech.startHandshakeCue(self.character)
    TMSpeech.pendingCueStartId = sid
end

function ISTCBoomboxAction:actionWhenPlaying()
    local tcm = self.device:getModData().tcmusic
    if tcm.deviceType == "VehiclePart" then return end
    if tcm.deviceType == "InventoryItem" then
        -- Walkman plays local-only: never (re)publish a shared row.
        if TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[self.device:getFullType()] then
            return
        end
        -- Boombox: the client-local session IS the play state (item modData
        -- is never written for play/stop). Republish the shared row from it
        -- so volume/headphone changes reach other players.
        local bs = TCMusic.BoomboxSession
        if not (bs and bs.itemId == self.device:getID()) then return end
        local musicId = getPortableMusicId(self.character)
        ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
            volume = bs.volume or self.deviceData:getDeviceVolume(),
            headphone = self.deviceData:getHeadphoneType() >= 0,
            timestamp = "update",
            musicName = bs.media,
            startId = bs.startId,
            itemid = self.device:getID(),
        }
        if isClient() then TCMusic.transmitNowPlay(self.character) end
        return
    end
    if tcm.isPlaying then
        local musicId = getWorldMusicIdForDevice(self.device)
        ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
            volume = self.deviceData:getDeviceVolume(),
            headphone = self.deviceData:getHeadphoneType() >= 0,
            timestamp = "update",
            musicName = tcm.mediaItem,
            startId = tcm.startId,
        }
        if isClient() then TCMusic.transmitNowPlay(self.character) end
    end
end

-- The context menu (shared file) also queues RemoveMediaToFannyF/Glove/Back/
-- Satchel/Weebing... variants. This client class doesn't define them, so they
-- silently did NOTHING client-side. Route them all to the plain RemoveMedia
-- handlers here: locally the work is identical (stop audio, clear state); the
-- SERVER complete* variant still places the tape into the right bag in MP.
local function resolveModeHandler(self, prefix)
    local fn = self[prefix .. self.mode]
    if not fn and type(self.mode) == "string" and string.find(self.mode, "^RemoveMediaTo") then
        fn = self[prefix .. "RemoveMedia"]
    end
    return fn
end

function ISTCBoomboxAction:isValid()
    if self.character and self.device and self.deviceData and self.mode then
        local fn = resolveModeHandler(self, "isValid")
        if fn then
            return fn(self)
        end
    end
end

function ISTCBoomboxAction:update()
    if self.character and self.deviceData and self.deviceData:isIsoDevice() then
        self.character:faceThisObject(self.deviceData:getParent())
    end
end

function ISTCBoomboxAction:perform()
    if self.character and self.device and self.deviceData and self.mode then
        local fn = resolveModeHandler(self, "perform")
        if fn then
            fn(self)
        end
    end
    ISBaseTimedAction.perform(self)
end
function ISTCBoomboxAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISTCBoomboxAction:isValidToggleOnOff()
    return self.deviceData:getIsBatteryPowered() and self.deviceData:getPower() > 0 or self.deviceData:canBePoweredHere();
end

function ISTCBoomboxAction:performToggleOnOff()
    if self:isValidToggleOnOff() then
        if self.device:getModData().tcmusic and (self.device:getModData().tcmusic.deviceType == "VehiclePart") then
            dispatchClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = self.device:getModData().tcmusic.mediaItem, isPlaying = false })
        end
        if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
            -- Walkman session: power off kills the local playback.
            local ws = TCMusic.WalkmanSession
            if ws and ws.itemId == self.device:getID() then
                stopCharacterMusic(self.character)
            end
            -- Boombox session: power off kills playback + the shared row.
            local bs = TCMusic.BoomboxSession
            if bs and bs.itemId == self.device:getID() then
                stopCharacterMusic(self.character)
                local musicId = getPortableMusicId(self.character)
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                if isClient() then TCMusic.transmitNowPlay(self.character) end
            end
            if self.device:getModData().tcmusic.isPlaying then
                self.device:getModData().tcmusic.isPlaying = false
                stopCharacterMusic(self.character)
                local musicId = getPortableMusicId(self.character)
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                if isClient() then TCMusic.transmitNowPlay(self.character) end
                syncPortableDevice(self.device)
            end
        elseif self.device:getModData().tcmusic.deviceType == "IsoObject" then
            if self.device:getModData().tcmusic.isPlaying then
                self.device:getModData().tcmusic.isPlaying = false
                
                local emitter = self.deviceData:getEmitter()
                if emitter then emitter:stopAll() end
                if TCMusic.stopWorldMusic then
                    TCMusic.stopWorldMusic(self.device:getX(), self.device:getY(), self.device:getZ())
                end
                local musicId = getWorldMusicIdForDevice(self.device)
                local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"]
                nowPlay[musicId] = nil
                if TCMusic and TCMusic.clearLegacyWorldNowPlay then
                    nowPlay = ModData.getOrCreate("trueMusicData")["now_play"]
                    local md = self.device:getModData()
                    TCMusic.clearLegacyWorldNowPlay(nowPlay, self.device:getX(), self.device:getY(), self.device:getZ(), md and md.RadioItemID, musicId)
                end
                if isClient() then
                    local wa = getWorldArgs(self.device, self.deviceData)
                    if wa then
                        wa.isPlaying = false
                        dispatchClientCommand(self.character, "truemusic", "setWorldDevicePlayback", wa)
                    end
                end
                if isClient() then TCMusic.transmitNowPlay(self.character) end
                transmitDeviceModDataIfNeeded(self.device)
            end
        end
        self.deviceData:setIsTurnedOn( not self.deviceData:getIsTurnedOn() );
        -- Placed device: the power flip previously lived ONLY on this client
        -- and evaporated on chunk reload. Persist it on the device, the
        -- linked floor item, and the server.
        if self.device:getModData().tcmusic.deviceType == "IsoObject" then
            local md = self.device:getModData()
            md.tcmusic.turnedOn = self.deviceData:getIsTurnedOn()
            local linkedItem = findLinkedWorldItem(self.device)
            if linkedItem then
                local lmd = linkedItem:getModData()
                lmd.tcmusic = lmd.tcmusic or {}
                lmd.tcmusic.turnedOn = md.tcmusic.turnedOn
                if not md.tcmusic.turnedOn then lmd.tcmusic.isPlaying = false end
            end
            transmitDeviceModDataIfNeeded(self.device)
            if isClient() then
                local wa = getWorldArgs(self.device, self.deviceData)
                if wa then
                    wa.turnedOn = md.tcmusic.turnedOn
                    dispatchClientCommand(self.character, "truemusic", "setWorldDevicePower", wa)
                end
            end
        end
        speechSay(self, self.deviceData:getIsTurnedOn() and "PowerOn" or "PowerOff")
    end
end

function ISTCBoomboxAction:isValidRemoveBattery()
    return self.deviceData and self.deviceData:getIsBatteryPowered() and self.deviceData:getHasBattery();
end

function ISTCBoomboxAction:performRemoveBattery()
    if not self.deviceData then
        return
    end
    if self.deviceData:getHasBattery() then
        self.deviceData:setIsTurnedOn(false);
    end
    if self:isValidRemoveBattery() and self.character:getInventory() then
        self.deviceData:getBattery(self.character:getInventory());
    end
    if self.device and self.device.getModData and self.deviceData then
        local md = self.device:getModData()
        md.tcmusic = md.tcmusic or {}
        md.tcmusic.batteryHas = false
        if self.deviceData.getPower then
            md.tcmusic.batteryPower = self.deviceData:getPower()
        end
        if self.device.transmitModData then
            transmitDeviceModDataIfNeeded(self.device)
        end
    end
    if self.deviceData and self.deviceData.setHasBattery then
        self.deviceData:setHasBattery(false)
    end
    if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
        -- Walkman session: no battery, no music.
        local ws = TCMusic.WalkmanSession
        if ws and ws.itemId == self.device:getID() then
            stopCharacterMusic(self.character)
        end
        -- Boombox session: no battery, no music (and retire the shared row).
        local bs = TCMusic.BoomboxSession
        if bs and bs.itemId == self.device:getID() then
            stopCharacterMusic(self.character)
            local musicId = getPortableMusicId(self.character)
            ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
            if isClient() then TCMusic.transmitNowPlay(self.character) end
        end
        if self.device:getModData().tcmusic.isPlaying then
            self.device:getModData().tcmusic.isPlaying = false
            stopCharacterMusic(self.character)
            local musicId = getPortableMusicId(self.character)
            ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
            if isClient() then TCMusic.transmitNowPlay(self.character) end
            syncPortableDevice(self.device)
        end
    elseif self.device:getModData().tcmusic.deviceType == "IsoObject" then
        if self.device:getModData().tcmusic.isPlaying then
            self.device:getModData().tcmusic.isPlaying = false
            local emitter = self.deviceData:getEmitter()
            if emitter then emitter:stopAll() end
            if TCMusic.stopWorldMusic then
                TCMusic.stopWorldMusic(self.device:getX(), self.device:getY(), self.device:getZ())
            end
            local musicId = getWorldMusicIdForDevice(self.device)
            local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"]
            nowPlay[musicId] = nil
            if TCMusic and TCMusic.clearLegacyWorldNowPlay then
                local md = self.device:getModData()
                TCMusic.clearLegacyWorldNowPlay(nowPlay, self.device:getX(), self.device:getY(), self.device:getZ(), md and md.RadioItemID, musicId)
            end
            if isClient() then
                local wa = getWorldArgs(self.device, self.deviceData)
                if wa then
                    wa.isPlaying = false
                    dispatchClientCommand(self.character, "truemusic", "setWorldDevicePlayback", wa)
                end
            end
            if isClient() then TCMusic.transmitNowPlay(self.character) end
            transmitDeviceModDataIfNeeded(self.device)
        end
    end
end

function ISTCBoomboxAction:isValidAddBattery()
    return self.deviceData and self.deviceData:getIsBatteryPowered() and self.deviceData:getHasBattery() == false;
end

function ISTCBoomboxAction:performAddBattery()
    if not self.deviceData then
        return
    end
    if self:isValidAddBattery() and self.secondaryItem then
        self.deviceData:addBattery(self.secondaryItem);
        if self.device and self.device.getModData and self.deviceData then
            local md = self.device:getModData()
            md.tcmusic = md.tcmusic or {}
            md.tcmusic.batteryHas = true
            if self.deviceData.getPower then
                md.tcmusic.batteryPower = self.deviceData:getPower()
            end
            if self.device.transmitModData then
                transmitDeviceModDataIfNeeded(self.device)
            end
        end
    end
end

function ISTCBoomboxAction:isValidSetVolume()
    if not self.secondaryItem or type(self.secondaryItem) ~= "number" or self.secondaryItem < 0 or self.secondaryItem > 1 then
        return false;
    end
    return self.deviceData:getIsTurnedOn() and self.deviceData:getPower() > 0;
end

function ISTCBoomboxAction:performSetVolume()
    if self:isValidSetVolume() then
        self.deviceData:setDeviceVolume(self.secondaryItem)
        local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"] or nil
        if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
            local newVol = self.deviceData:getDeviceVolume()
            -- Session volume (Tal-style): the session carries the LIVE volume
            -- so a server item echo reverting DeviceData can't snap it back.
            local ws = TCMusic.WalkmanSession
            if ws and ws.itemId == self.device:getID() then
                ws.volume = newVol
                if ws.soundId then
                    -- Master/device volume IS the walkman volume (no
                    -- client-volume layer - only the wearer hears it).
                    self.character:getEmitter():setVolume(ws.soundId, newVol * 0.4)
                end
            end
            local bs = TCMusic.BoomboxSession
            if bs and bs.itemId == self.device:getID() then
                bs.volume = newVol
                if bs.soundId then
                    local cvKey = "I:" .. tostring(self.device:getID())
                    local vol = TCMusic.getListenVolume and TCMusic.getListenVolume(newVol, cvKey) or newVol
                    self.character:getEmitter():setVolume(bs.soundId, vol * 0.4)
                end
            end
            -- Legacy sound handle (older builds without sessions).
            local tcmusicid = self.character:getModData().tcmusicid
            if tcmusicid and not (bs and bs.soundId == tcmusicid) and not (ws and ws.soundId == tcmusicid) then
                local vol = newVol
                if not (TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[self.device:getFullType()]) then
                    local cvKey = "I:" .. tostring(self.device:getID())
                    vol = TCMusic.getListenVolume and TCMusic.getListenVolume(vol, cvKey) or vol
                end
                self.character:getEmitter():setVolume(tcmusicid, vol * 0.4)
            end
            local musicId = getPortableMusicId(self.character)
            if nowPlay and musicId and nowPlay[musicId] then
                nowPlay[musicId]["volume"] = newVol
                nowPlay[musicId]["timestamp"] = "update"
            end
            -- Persist the new device volume on the server's copy of the item;
            -- without this the next ItemStats echo restores the OLD volume
            -- (slider snapping back by itself). Play state stays out of the
            -- item, so this sync can't disturb the session.
            syncPortableDevice(self.device)
        elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
        else
            local emitter = self.deviceData:getEmitter()
            if emitter then
                local cvKey = TCMusic.worldVolKey and TCMusic.worldVolKey(self.device:getX(), self.device:getY(), self.device:getZ()) or nil
                self.deviceData:getEmitter():setVolumeAll((TCMusic.getListenVolume and TCMusic.getListenVolume(self.deviceData:getDeviceVolume(), cvKey) or self.deviceData:getDeviceVolume()) * 0.4)
            end
            -- The actual playback usually runs on a FREE world emitter owned
            -- by the tick engine (placed boombox / vinyl player): retune it
            -- right now instead of waiting for the next heavy tick cycle.
            if TCMusic.applyClientVolumeToWorldDevice then
                TCMusic.applyClientVolumeToWorldDevice(self.device:getX(), self.device:getY(), self.device:getZ(), self.deviceData:getDeviceVolume())
            end
            -- Persist volume on the device + linked floor item.
            local dmd = self.device:getModData()
            dmd.tcmusic = dmd.tcmusic or {}
            dmd.tcmusic.volume = self.deviceData:getDeviceVolume()
            local linkedItem = findLinkedWorldItem(self.device)
            if linkedItem then
                local lmd = linkedItem:getModData()
                lmd.tcmusic = lmd.tcmusic or {}
                lmd.tcmusic.volume = dmd.tcmusic.volume
            end
            if isClient() then
                local wa = getWorldArgs(self.device, self.deviceData)
                if wa then
                    dispatchClientCommand(self.character, "truemusic", "setWorldDeviceVolume", wa)
                end
            end
            local musicId = getWorldMusicIdForDevice(self.device)
            if nowPlay and musicId and nowPlay[musicId] then
                nowPlay[musicId]["volume"] = self.deviceData:getDeviceVolume()
                nowPlay[musicId]["timestamp"] = "update"
            end
        end
        if isClient() and nowPlay then
            TCMusic.transmitNowPlay(self.character)
        end
        self:actionWhenPlaying()
    end
end

function ISTCBoomboxAction:isValidRemoveHeadphones()
    ensureInventoryWalkmanHeadphones(self.device, self.deviceData)
    return self.deviceData and self.deviceData:getHeadphoneType() >= 0;
end

function ISTCBoomboxAction:performRemoveHeadphones()
    if not self.deviceData then
        return
    end
    ensureInventoryWalkmanHeadphones(self.device, self.deviceData)
    if self:isValidRemoveHeadphones() and self.character:getInventory() then
        self.deviceData:getHeadphones(self.character:getInventory());
        if self.device and self.device.getModData and self.deviceData and self.deviceData.getHeadphoneType then
            local md = self.device:getModData()
            md.tcmusic = md.tcmusic or {}
            md.tcmusic.headphoneType = -1
            md.tcmusic.headphoneItemFullType = nil
            md.tm_headphoneType = -1
            md.tm_hasHeadphones = false
            if self.device.transmitModData then
                transmitDeviceModDataIfNeeded(self.device)
            end
        end
        if self.device:getModData().tcmusic.deviceType == "InventoryItem" and self.device:getFullType() and TCMusic.WalkmanPlayer[self.device:getFullType()] then
            -- Walkman session: no headphones, no music.
            local ws = TCMusic.WalkmanSession
            if ws and ws.itemId == self.device:getID() then
                stopCharacterMusic(self.character)
            end
            if self.device:getModData().tcmusic.isPlaying then
                self.device:getModData().tcmusic.isPlaying = false
                stopCharacterMusic(self.character)
                local musicId = getPortableMusicId(self.character)
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                if isClient() then TCMusic.transmitNowPlay(self.character) end
            end
            syncPortableDevice(self.device)
        end
        self:actionWhenPlaying()
    end
end

function ISTCBoomboxAction:isValidAddHeadphones()
    ensureInventoryWalkmanHeadphones(self.device, self.deviceData)
    return self.deviceData and self.deviceData:getHeadphoneType() < 0;
end

function ISTCBoomboxAction:performAddHeadphones()
    if not self.deviceData then
        return
    end
    if self:isValidAddHeadphones() and self.secondaryItem then
        self.deviceData:addHeadphones(self.secondaryItem);
        if self.device and self.device.getModData and self.deviceData and self.deviceData.getHeadphoneType then
            local md = self.device:getModData()
            md.tcmusic = md.tcmusic or {}
            md.tcmusic.headphoneType = self.deviceData:getHeadphoneType()
            md.tcmusic.headphoneItemFullType = self.secondaryItem.getFullType and self.secondaryItem:getFullType() or "Base.Headphones"
            md.tm_headphoneType = md.tcmusic.headphoneType
            md.tm_hasHeadphones = true
            if self.device.transmitModData then
                transmitDeviceModDataIfNeeded(self.device)
            end
        end
        self:actionWhenPlaying()
    end
end

function ISTCBoomboxAction:isValidTogglePlayMedia()
    local tcm = self.device and self.device.getModData and self.device:getModData().tcmusic or nil
    -- An active walkman/boombox session must ALWAYS be stoppable - even if a
    -- server item echo rolled the item's modData back (mediaItem nulled etc.).
    local ws = TCMusic.WalkmanSession
    if ws and self.device and self.device.getID and ws.itemId == self.device:getID() then
        return true
    end
    local bs = TCMusic.BoomboxSession
    if bs and self.device and self.device.getID and bs.itemId == self.device:getID() then
        return true
    end
    if not tcm or not tcm.mediaItem then return false end

    if tcm.isPlaying then
        return true
    end

    if not self.deviceData:getIsTurnedOn() then return false end
    if tcm.deviceType == "InventoryItem" and TCMusic.WalkmanPlayer[self.device:getFullType()] and (not hasHeadphones(self.device, self.deviceData)) then
        return false
    end
    if tcm.deviceType == "IsoObject" and false and (not isLifestyleJukeboxPoweredOn(self.device)) then
        return false
    end
    if (not tcm.needSpeaker) or tcm.connectTo then
        return true
    end
    return false
end

function ISTCBoomboxAction:performTogglePlayMedia()
    if self:isValidTogglePlayMedia() then
        if isClient() then
        end
        if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
            local veh = self.device:getVehicle()
            local tcm = self.device:getModData().tcmusic
            audioDbg("[TMDBG][TCVehToggle] veh=" .. tostring(veh and veh:getId()) .. " mediaItem=" .. tostring(tcm.mediaItem) .. " wasPlaying=" .. tostring(tcm.isPlaying) .. " isClient=" .. tostring(isClient()))
            if veh then
                if tcm.isPlaying then
                    local vemit = veh.getEmitter and veh:getEmitter() or nil
                    if vemit and vemit.stopAll then vemit:stopAll() end
                    audioDbg("[TMDBG][TCVehToggle] sending STOP command")
                    if isClient() then
                        dispatchClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = veh:getId(), mediaItem = tcm.mediaItem, isPlaying = false })
                    else
                        -- Singleplayer: apply directly; server command handler isn't invoked.
                        tcm.isPlaying = false
                        if veh.transmitPartModData then veh:transmitPartModData(self.device) end
                    end
                    speechStop(self)
                else
                    if self.deviceData.setChannelRaw then self.deviceData:setChannelRaw(100) end
                    audioDbg("[TMDBG][TCVehToggle] sending PLAY command")
                    local sid = TCMusic.newStartId(veh:getId())
                    if isClient() then
                        dispatchClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = veh:getId(), mediaItem = tcm.mediaItem, isPlaying = true, startId = sid })
                    else
                        -- Singleplayer: set flag directly so TCTickCheckMusic picks it up.
                        tcm.isPlaying = true
                        tcm.startId = sid
                        if veh.transmitPartModData then veh:transmitPartModData(self.device) end
                    end
                    speechHandshake(self, sid)
                end
            else
                audioDbg("[TMDBG][TCVehToggle] ERROR: no vehicle on device")
            end
        elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
            local musicId = nil
            musicId = getPortableMusicId(self.character)
 
            local isWalkman = TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[self.device:getFullType()]
            if isWalkman then
                -- WALKMAN: play state lives ONLY in the client-local session
                -- (TCMusic.WalkmanSession). The item's modData is NEVER
                -- written for play/stop, so the B42 server ItemStats echo has
                -- nothing to roll back (that echo is what kept flipping the
                -- button to Play and killing Stop/volume a few seconds in).
                local tcm = self.device:getModData().tcmusic
                local ws = TCMusic.WalkmanSession
                local sessionActive = ws and ws.itemId == self.device:getID()
                if sessionActive or tcm.isPlaying then
                    -- STOP: stopCharacterMusic tears down the session (and
                    -- any legacy sound handle) in one place.
                    stopCharacterMusic(self.character)
                    ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                    -- Migration: older builds stamped isPlaying on the item;
                    -- clear it and sync ONCE so the server copy matches.
                    if tcm.isPlaying then
                        tcm.isPlaying = false
                        syncPortableDevice(self.device)
                    end
                    probe("toggle OFF walkman session itemId=" .. tostring(self.device:getID()))
                    speechSay(self, "Stopped")
                else
                    -- PLAY: start the audio right now, remember it in the
                    -- session. Master/device volume applies directly (no
                    -- client-volume layer - only the wearer hears it).
                    getSoundManager():StopMusic()
                    stopCharacterMusic(self.character)
                    local id = self.character:getEmitter():playSoundImpl(TCMusic.getSoundName(tcm.mediaItem), self.character)
                    if id and id ~= 0 then
                        self.character:getEmitter():setVolume(id, self.deviceData:getDeviceVolume() * 0.4)
                        TCMusic.WalkmanSession = {
                            itemId = self.device:getID(),
                            media = tcm.mediaItem,
                            soundId = id,
                            volume = self.deviceData:getDeviceVolume(),
                        }
                    end
                    -- No shared row: nobody else can hear a walkman.
                    ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                    probe("toggle ON walkman session itemId=" .. tostring(self.device:getID()) .. " media=" .. tostring(tcm.mediaItem))
                    if TMSpeech and TMSpeech.announce then
                        TMSpeech.announce(self.character, "Playing", TMSpeech.mediaLabel and TMSpeech.mediaLabel(tcm.mediaItem) or nil)
                    end
                end
            else
                -- BOOMBOX: like the walkman, play state lives ONLY in the
                -- client-local session (TCMusic.BoomboxSession). The item's
                -- modData is NEVER written for play/stop, so the B42 server
                -- ItemStats echo has nothing to roll back. Other players
                -- still hear us through the shared now_play row (ModData,
                -- not item data - echo-immune).
                local tcm = self.device:getModData().tcmusic
                local bs = TCMusic.BoomboxSession
                local sessionActive = bs and bs.itemId == self.device:getID()
                if sessionActive or tcm.isPlaying then
                    -- STOP: stopCharacterMusic tears down the session, the
                    -- sound handle AND any scheduled sync start in one place.
                    stopCharacterMusic(self.character)
                    if TMSpeech and TMSpeech.stopHandshakeCue then TMSpeech.stopHandshakeCue() end
                    ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
                    -- Migration: older builds stamped isPlaying on the item;
                    -- clear it and sync ONCE so the server copy matches.
                    if tcm.isPlaying then
                        tcm.isPlaying = false
                        syncPortableDevice(self.device)
                    end
                    probe("toggle OFF boombox session itemId=" .. tostring(self.device:getID()))
                    speechStop(self)
                else
                    getSoundManager():StopMusic()
                    stopCharacterMusic(self.character)
                    -- Synchronized start: announce first, play later. In MP the
                    -- server's ready-check ('goStart') pulls this forward once
                    -- every client has answered; the delay below is the fallback
                    -- ceiling. SP has no handshake - use a short fixed delay.
                    local sid = TCMusic.newStartId(self.device:getID())
                    TCMusic.BoomboxSession = {
                        itemId = self.device:getID(),
                        media = tcm.mediaItem,
                        startId = sid,
                        soundId = nil, -- filled in when the sync start fires
                        volume = self.deviceData:getDeviceVolume(),
                    }
                    TCMusic.pendingOwnerStart = {
                        at = getTimestampMs() + ((isClient() and TCMusic.syncHandshakeEnabled()) and (TCMusic.SYNC_START_DELAY_MS or 2000) or 250),
                        itemid = self.device:getID(),
                        media = tcm.mediaItem,
                        startId = sid,
                    }
                    probe("toggle ON boombox session itemId=" .. tostring(self.device:getID()) .. " media=" .. tostring(tcm.mediaItem) .. " startId=" .. tostring(sid))
                    speechHandshake(self, sid)
                    ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
                        volume = self.deviceData:getDeviceVolume(),
                        headphone = self.deviceData:getHeadphoneType() >= 0,
                        timestamp = "update",
                        musicName = tcm.mediaItem,
                        startId = sid,
                        itemid = self.device:getID(),
                    }
                end
            end
            -- Portable play/stop never touches the item's modData - nothing
            -- changed, so no item sync (a sync would invite the echo back).
        else
            local musicId = nil
            musicId = getWorldMusicIdForDevice(self.device)
            probe("performTogglePlayMedia world-branch musicId=" .. tostring(musicId))
            local worldPlaying = self.device:getModData().tcmusic.isPlaying
            
            if worldPlaying then
                probe("toggle OFF world musicId=" .. tostring(musicId) .. " media=" .. tostring(self.device:getModData().tcmusic.mediaItem))
                self.device:getModData().tcmusic.isPlaying = false
                self.device:getModData().tcmusic.startTime = nil
                
                
                local emitter = self.deviceData:getEmitter()
                if emitter then
                    emitter:stopAll()
                end
                
                if TCMusic.stopWorldMusic then
                    TCMusic.stopWorldMusic(self.device:getX(), self.device:getY(), self.device:getZ())
                end
                if isClient() then
                    local wa = getWorldArgs(self.device, self.deviceData)
                    if wa then
                        wa.isPlaying = false
                        dispatchClientCommand(self.character, "truemusic", "setWorldDevicePlayback", wa)
                    end
                end
                
                local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"]
                nowPlay[musicId] = nil
                if TCMusic and TCMusic.clearLegacyWorldNowPlay then
                    local md = self.device:getModData()
                    TCMusic.clearLegacyWorldNowPlay(nowPlay, self.device:getX(), self.device:getY(), self.device:getZ(), md and md.RadioItemID, musicId)
                end
                -- Keep the linked floor item's copy coherent locally (device
                -- still on, just not playing) - the rebuild reads from it.
                local linkedItem = findLinkedWorldItem(self.device)
                if linkedItem then
                    local lmd = linkedItem:getModData()
                    lmd.tcmusic = lmd.tcmusic or {}
                    lmd.tcmusic.isPlaying = false
                end
                primeJukeboxModeMediaForNextPlay(self.device)
                speechStop(self)
            else
                probe("toggle ON world musicId=" .. tostring(musicId) .. " media=" .. tostring(self.device:getModData().tcmusic.mediaItem))
                getSoundManager():StopMusic()
                self.device:getModData().tcmusic.isPlaying = true
                local sid = TCMusic.newStartId(self.device:getModData().RadioItemID or musicId)
                self.device:getModData().tcmusic.startId = sid
                
                local emitter = self.deviceData:getEmitter()
                if emitter then
                    emitter:stopAll()
                end
                if isClient() then
                    local wa = getWorldArgs(self.device, self.deviceData)
                    if wa then
                        wa.isPlaying = true
                        wa.startId = sid
                        dispatchClientCommand(self.character, "truemusic", "setWorldDevicePlayback", wa)
                    end
                end
                speechHandshake(self, sid)
                
                -- Stamp the linked floor item locally too: play implies the
                -- device is powered on with this media, and the rebuild path
                -- restores power/cassette from the item's copy.
                local linkedItem = findLinkedWorldItem(self.device)
                if linkedItem then
                    local lmd = linkedItem:getModData()
                    lmd.tcmusic = lmd.tcmusic or {}
                    if not lmd.tcmusic.mediaItem then
                        lmd.tcmusic.mediaItem = self.device:getModData().tcmusic.mediaItem
                    end
                    lmd.tcmusic.isPlaying = true
                    lmd.tcmusic.turnedOn = true
                    lmd.tcmusic.volume = self.deviceData:getDeviceVolume()
                end
                
                ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
                    volume = self.deviceData:getDeviceVolume(),
                    headphone = self.deviceData:getHeadphoneType() >= 0,
                    isPlaying = true,
                    timestamp = "update",
                    musicName = self.device:getModData().tcmusic.mediaItem,
                    x = self.device:getX(),
                    y = self.device:getY(),
                    z = self.device:getZ(),
                    startId = sid,
                }
                local md = self.device:getModData()
                if md and md.RadioItemID then
                    ModData.getOrCreate("trueMusicData")["now_play"][musicId]["itemid"] = md.RadioItemID
                end
            end
            transmitDeviceModDataIfNeeded(self.device)
        end
        if isClient() then TCMusic.transmitNowPlay(self.character) end
    end
end

function ISTCBoomboxAction:isValidAddMedia()
    applyJukeboxModeMedia(self.device)
    local musicPlayer = getMusicPlayerForActionDevice(self.device)
    if self.secondaryItem then
        local music = self.secondaryItem:getType()
        return (not self.device:getModData().tcmusic.mediaItem) and GlobalMusic[music] and musicPlayer == GlobalMusic[music];
    end
end

function ISTCBoomboxAction:performAddMedia()
    if self:isValidAddMedia() and self.secondaryItem then
        local inventoryItem = self.secondaryItem
        local container = self.secondaryItem:getContainer()
        if container then
            if TMSpeech then
                local label = (inventoryItem.getDisplayName and inventoryItem:getDisplayName()) or "media"
                speechSay(self, "Insert", tostring(label))
            end
            if (container:getType() == "floor" and inventoryItem:getWorldItem() and inventoryItem:getWorldItem():getSquare()) then
                inventoryItem:getWorldItem():getSquare():transmitRemoveItemFromSquare(inventoryItem:getWorldItem());
                inventoryItem:getWorldItem():getSquare():getWorldObjects():remove(inventoryItem:getWorldItem());
                local sq = inventoryItem:getWorldItem():getSquare()
                local ch = sq and sq:getChunk() or nil
                if ch and ch.recalcHashCodeObjects then
                    ch:recalcHashCodeObjects()
                end
                inventoryItem:getWorldItem():getSquare():getObjects():remove(inventoryItem:getWorldItem());
                inventoryItem:setWorldItem(nil);
            end
            if self.device:getModData().tcmusic.deviceType == "IsoObject" then
                probe("performAddMedia world-branch media=" .. tostring(inventoryItem and inventoryItem:getFullType()))
                self.device:getModData().tcmusic.mediaItem = inventoryItem:getFullType();
                syncJukeboxModeMedia(self.device)
                transmitDeviceModDataIfNeeded(self.device)
                if isClient() then
                    local wa = getWorldArgs(self.device, self.deviceData)
                    if wa then
                        wa.isPlaying = false
                        dispatchClientCommand(self.character, "truemusic", "setWorldDeviceMedia", wa)
                    end
                end
                local linkedItem = findLinkedWorldItem(self.device)
                if linkedItem then
                    local linkedMd = linkedItem:getModData()
                    linkedMd.tcmusic = linkedMd.tcmusic or {}
                    linkedMd.tcmusic.mediaItem = inventoryItem:getFullType()
                end
            elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
                local mediaItemName = inventoryItem:getFullType()
                dispatchClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = mediaItemName, isPlaying = false })
            else
                self.device:getModData().tcmusic.mediaItem = inventoryItem:getFullType();
                syncJukeboxModeMedia(self.device)
                syncPortableDevice(self.device)
            end
            if not inventoryItem:isInPlayerInventory() then
                -- B42.20: removeItemOnServer was removed from vanilla and the old call
                -- triggered anti-cheat item-delete packets from the client. Local removal
                -- below plus the TMItemMPSync server command keeps things in sync.
            end
            container:DoRemoveItem(inventoryItem);
        end
    end
end

function ISTCBoomboxAction:isValidRemoveMedia()
    applyJukeboxModeMedia(self.device)
    if self.device:getModData().tcmusic.mediaItem then
        return true
    else
        return false
    end
end

function ISTCBoomboxAction:performRemoveMedia()
    if self:isValidRemoveMedia() and self.character:getInventory() then
        if TMSpeech then
            speechSay(self, "Eject", TMSpeech.mediaLabel(self.device:getModData().tcmusic.mediaItem))
        end
        -- MP: the tape item is created SERVER-side (completeRemoveMedia in the
        -- shared file) and broadcast back. Creating it here too made a client-
        -- only ghost copy the server never knew about (uneqippable, undroppable,
        -- ItemStats packet errors for everyone nearby). SP has no server
        -- complete pass, so create it locally there.
        if not isClient() then
            local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
            if not itemTape then return end
            self.character:getInventory():AddItem(itemTape)
        end
        if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
            if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
                self.device:getVehicle():getEmitter():stopAll()
            end
        else
            local emitter = self.deviceData:getEmitter()
            if emitter then
                self.deviceData:getEmitter():stopAll()
            end
            if TCMusic.stopWorldMusic and self.device:getModData().tcmusic.deviceType == "IsoObject" then
                TCMusic.stopWorldMusic(self.device:getX(), self.device:getY(), self.device:getZ())
            end
        end
        self.device:getModData().tcmusic.mediaItem = nil
        syncJukeboxModeMedia(self.device)
        self.device:getModData().tcmusic.isPlaying = false
        if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
            local musicId = getPortableMusicId(self.character)
            probe("remove media inv clear now_play musicId=" .. tostring(musicId) .. " itemId=" .. tostring(self.device:getID()))
            ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
            stopCharacterMusic(self.character)
            if isClient() then TCMusic.transmitNowPlay(self.character) end
            syncPortableDevice(self.device)
        end
        
        if self.device:getModData().tcmusic.deviceType == "IsoObject" then
            local musicId = getWorldMusicIdForDevice(self.device)
            local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"]
            nowPlay[musicId] = nil
            if TCMusic and TCMusic.clearLegacyWorldNowPlay then
                local md = self.device:getModData()
                TCMusic.clearLegacyWorldNowPlay(nowPlay, self.device:getX(), self.device:getY(), self.device:getZ(), md and md.RadioItemID, musicId)
            end
            if isClient() then
                local wa = getWorldArgs(self.device, self.deviceData)
                if wa then
                    wa.media = nil
                    wa.isPlaying = false
                    dispatchClientCommand(self.character, "truemusic", "setWorldDeviceMedia", wa)
                    dispatchClientCommand(self.character, "truemusic", "setWorldDevicePlayback", wa)
                end
            end
            if isClient() then TCMusic.transmitNowPlay(self.character) end
            transmitDeviceModDataIfNeeded(self.device)
            local linkedItem = findLinkedWorldItem(self.device)
            if linkedItem then
                local linkedMd = linkedItem:getModData()
                if linkedMd.tcmusic then
                    linkedMd.tcmusic.mediaItem = nil
                    linkedMd.tcmusic.isPlaying = false
                end
            end
        elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
            dispatchClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
        end
    end
end

function ISTCBoomboxAction:new(mode, character, device, secondaryItem)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.mode = mode;
    o.character = character;
    o.device = device;
    o.deviceData = device and device:getDeviceData();
    o.secondaryItem = secondaryItem;
    o.stopOnWalk = false;
    o.stopOnRun = true;
    o.maxTime = 30;
    return o;
end







