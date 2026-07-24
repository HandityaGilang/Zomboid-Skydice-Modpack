require "TimedActions/ISBaseTimedAction"
require "TCMusicClientFunctions"
pcall(function() require "RadioCom/ISTCBoomboxWindow" end)

local DEBUG = false
local function log(msg)
	if DEBUG then
		print(msg)
	end
end
local PROBE = false
local function probe(msg)
	if PROBE then
		print("[TMDBG][ActionShared] " .. tostring(msg))
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

ISTCBoomboxAction = ISBaseTimedAction:derive("ISTCBoomboxAction")

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
		log("ISTCBoomboxAction: Unknown media type, skipping remove")
		return nil
	end
	return instanceItem(fullType)
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
	if not hpItem then return end
	deviceData:addHeadphones(hpItem)
	if md then md.tm_hasHeadphones = true end
	probe("rehydrate headphones inventory walkman item=" .. tostring(fullType) .. " hpType=" .. tostring(deviceData:getHeadphoneType()) .. " hpItem=" .. tostring(hpFullType))
end

local function findLinkedWorldItem(device)
	if not device or not device.getModData then return nil end
	local md = device:getModData()
	if not md or not md.RadioItemID then return nil end
	local square = device.getSquare and device:getSquare() or nil
	if not square or not square.getWorldObjects then return nil end
	local link = tostring(md.RadioItemID)
	local worldObjects = square:getWorldObjects()
	for i = 0, worldObjects:size() - 1 do
		local worldObj = worldObjects:get(i)
		if instanceof(worldObj, "IsoWorldInventoryObject") then
			local item = worldObj:getItem()
			if item and item.getID then
				local itemId = tostring(item:getID())
				if itemId == link or (itemId .. "tm") == link then
					return item
				end
			end
		end
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

local function shouldTransmitDeviceModData(device)
	if not device or not device.getModData then return false end
	local md = device:getModData()
	local tcmusic = md and md.tcmusic or nil
	-- Only world radios should use object moddata packets.
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

function ISTCBoomboxAction:actionWhenPlaying()
	if self.device:getModData().tcmusic.isPlaying then
		local musicId = nil
		if not (self.device:getModData().tcmusic.deviceType == "VehiclePart") then
			if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
				musicId = getPortableMusicId(self.character)
			else
				musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
				volume = self.deviceData:getDeviceVolume(),
				headphone = self.deviceData:getHeadphoneType() >= 0,
				timestamp = "update",
				musicName = self.device:getModData().tcmusic.mediaItem,
			}
			if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
				ModData.getOrCreate("trueMusicData")["now_play"][musicId]["itemid"] = self.device:getID()
			end
			if isClient() then ModData.transmit("trueMusicData") end
		end
	end
end
function ISTCBoomboxAction:isValid()
	if self.character and self.device and self.deviceData and self.mode then
		if self["isValid"..self.mode] then
			return self["isValid"..self.mode](self)
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
		if self["perform"..self.mode] then
			self["perform"..self.mode](self)
		end
	end
	ISBaseTimedAction.perform(self)
end
function ISTCBoomboxAction:stop()
	ISBaseTimedAction.stop(self)
end
function ISTCBoomboxAction:complete()
	if self.character and self.device and self.deviceData and self.mode then
		if self["complete"..self.mode] then
			self["complete"..self.mode](self)
		end
	end
end
function ISTCBoomboxAction:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	if self.mode == "SetVolume" then
		return 0
	end
	if self.mode == "ToggleOnOff" or self.mode == "TogglePlayMedia" then
		return 0
	end
	return 50
end

-- ToggleOnOff
function ISTCBoomboxAction:isValidToggleOnOff()
	return self.deviceData:getIsBatteryPowered() and self.deviceData:getPower() > 0 or self.deviceData:canBePoweredHere();
end
function ISTCBoomboxAction:performToggleOnOff()
	if self:isValidToggleOnOff() then
		return true
	end
end
function ISTCBoomboxAction:completeToggleOnOff()
	if self:isValidToggleOnOff() then
		if self.device:getModData().tcmusic and (self.device:getModData().tcmusic.deviceType == "VehiclePart") then
			sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = self.device:getModData().tcmusic.mediaItem, isPlaying = false })
		end
		if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
			if self.device:getModData().tcmusic.isPlaying then
				self.device:getModData().tcmusic.isPlaying = false
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
			end
		end
		self.deviceData:setIsTurnedOn( not self.deviceData:getIsTurnedOn() );
	end
	return true
end

-- RemoveBattery
function ISTCBoomboxAction:isValidRemoveBattery()
	return self.deviceData and self.deviceData:getIsBatteryPowered() and self.deviceData:getHasBattery();
end
function ISTCBoomboxAction:performRemoveBattery()
	return true
end
function ISTCBoomboxAction:completeRemoveBattery()
	if not self.deviceData then
		return true
	end
	if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		if self.device:getModData().tcmusic.isPlaying then
			self.device:getModData().tcmusic.isPlaying = false
			self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	end
	if self:isValidRemoveBattery() and self.character:getInventory() then
		self.deviceData:getBattery(self.character:getInventory());
	end
	if self.deviceData:getHasBattery() then
		self.deviceData:setIsTurnedOn(false);
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
	return true
end

-- AddBattery
function ISTCBoomboxAction:isValidAddBattery()
	return self.deviceData and self.deviceData:getIsBatteryPowered() and self.deviceData:getHasBattery() == false;
end
function ISTCBoomboxAction:performAddBattery()
	if self:isValidAddBattery() and self.secondaryItem then
		return true
	end
end
function ISTCBoomboxAction:completeAddBattery()
	if not self.deviceData then
		return true
	end
	if self:isValidAddBattery() and self.secondaryItem then
		self.deviceData:addBattery(self.secondaryItem);
		self.device:sync()
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
	return true
end

-- SetVolume
function ISTCBoomboxAction:isValidSetVolume()
	if not self.secondaryItem or type(self.secondaryItem) ~= "number" or self.secondaryItem < 0 or self.secondaryItem > 1 then
		return false;
	end
	return self.deviceData:getIsTurnedOn() and self.deviceData:getPower() > 0;
end
function ISTCBoomboxAction:performSetVolume()
	if self:isValidSetVolume() then
		return true
	end
end
function ISTCBoomboxAction:completeSetVolume()
	self.deviceData:setDeviceVolume(self.secondaryItem)
	local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"] or nil
	if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local tcmusicid = self.character:getModData().tcmusicid
		if tcmusicid then
			self.character:getEmitter():setVolume(tcmusicid, self.deviceData:getDeviceVolume() * 0.4)
		end
		local musicId = getPortableMusicId(self.character)
		if nowPlay and musicId and nowPlay[musicId] then
			nowPlay[musicId]["volume"] = self.deviceData:getDeviceVolume()
			nowPlay[musicId]["timestamp"] = "update"
		end
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		-- Громкость контролирует файл TCTickCheckMusic.lua
	else
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():setVolumeAll(self.deviceData:getDeviceVolume() * 0.4)
		end
		local musicId = "#" .. self.device:getX() .. "-" .. self.device:getY() .. "-" .. self.device:getZ()
		if nowPlay and musicId and nowPlay[musicId] then
			nowPlay[musicId]["volume"] = self.deviceData:getDeviceVolume()
			nowPlay[musicId]["timestamp"] = "update"
		end
	end
	if isClient() and nowPlay then
		ModData.transmit("trueMusicData")
	end
	self:actionWhenPlaying()
	return true
end

-- RemoveHeadphones
function ISTCBoomboxAction:isValidRemoveHeadphones()
	ensureInventoryWalkmanHeadphones(self.device, self.deviceData)
	return self.deviceData and self.deviceData:getHeadphoneType() >= 0;
end
function ISTCBoomboxAction:performRemoveHeadphones()
	ensureInventoryWalkmanHeadphones(self.device, self.deviceData)
	if self:isValidRemoveHeadphones() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveHeadphones()
	if not self.deviceData then
		return true
	end
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
		if self.device:getModData().tcmusic.isPlaying then
			self.device:getModData().tcmusic.isPlaying = false
			self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	end
	self:actionWhenPlaying()
	self.device:sync()
	return true
end

-- AddHeadphones
function ISTCBoomboxAction:isValidAddHeadphones()
	ensureInventoryWalkmanHeadphones(self.device, self.deviceData)
	return self.deviceData and self.deviceData:getHeadphoneType() < 0;
end
function ISTCBoomboxAction:performAddHeadphones()
	if self:isValidAddHeadphones() and self.secondaryItem then
		return true
	end
end
function ISTCBoomboxAction:completeAddHeadphones()
	if not self.deviceData then
		return true
	end
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
	return true
end

-- TogglePlayMedia
function ISTCBoomboxAction:isValidTogglePlayMedia()
	local tcm = self.device and self.device.getModData and self.device:getModData().tcmusic or nil
	if not tcm or not tcm.mediaItem then return false end
	if tcm.isPlaying then return true end
	if not self.deviceData:getIsTurnedOn() then return false end
	if tcm.deviceType == "InventoryItem" and TCMusic.WalkmanPlayer[self.device:getFullType()] and (not hasHeadphones(self.device, self.deviceData)) then
		return false
	end
	if tcm.deviceType == "IsoObject" and false and (not isLifestyleJukeboxPoweredOn(self.device)) then
		return false
	end
	if not tcm.needSpeaker or tcm.connectTo then
		return true
	end
	return false
end
function ISTCBoomboxAction:performTogglePlayMedia()
	if self:isValidTogglePlayMedia() then
		return true
	end
end
function ISTCBoomboxAction:completeTogglePlayMedia()
	if isClient() then
		-- ModData.request("trueMusicData")
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getModData().tcmusic.isPlaying then
			self.device:getVehicle():getEmitter():stopAll()
			sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = self.device:getModData().tcmusic.mediaItem, isPlaying = false })
		elseif self.device:getVehicle():getEmitter() then
			getSoundManager():StopMusic()
			self.deviceData:setChannelRaw(100)
			sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = self.device:getModData().tcmusic.mediaItem, isPlaying = true })
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			self.device:getModData().tcmusic.isPlaying = false
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			probe("toggle OFF inv musicId=" .. tostring(musicId) .. " itemId=" .. tostring(self.device:getID()))
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		else
			getSoundManager():StopMusic()
			self.device:getModData().tcmusic.isPlaying = true
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
			end
			local soundName = TCMusic and TCMusic.getSoundName and TCMusic.getSoundName(self.device:getModData().tcmusic.mediaItem) or self.device:getModData().tcmusic.mediaItem
			self.character:getModData().tcmusicid = playCharacterEmitterSound(self.character, soundName)
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():setVolume(self.character:getModData().tcmusicid, self.deviceData:getDeviceVolume() * 0.4)
			end
			probe("toggle ON inv musicId=" .. tostring(musicId) .. " itemId=" .. tostring(self.device:getID()) .. " media=" .. tostring(self.device:getModData().tcmusic.mediaItem))
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
				volume = self.deviceData:getDeviceVolume(),
				headphone = self.deviceData:getHeadphoneType() >= 0,
				timestamp = "update",
				musicName = self.device:getModData().tcmusic.mediaItem,
			}
			if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
				ModData.getOrCreate("trueMusicData")["now_play"][musicId]["itemid"] = self.device:getID()
			end
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		if self.device:getModData().tcmusic.isPlaying then
			self.device:getModData().tcmusic.isPlaying = false
			local emitter = self.deviceData:getEmitter()
			if emitter then
				self.deviceData:getEmitter():stopAll()
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
			primeJukeboxModeMediaForNextPlay(self.device)
		else
			getSoundManager():StopMusic()
			self.device:getModData().tcmusic.isPlaying = true
			
			local emitter = self.deviceData:getEmitter()
			if emitter then
				self.deviceData:getEmitter():stopAll()
				self.deviceData:setNoTransmit(false)
				self.deviceData:playSound(self.device:getModData().tcmusic.mediaItem, self.deviceData:getDeviceVolume() * 0.4, false)
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = {
				volume = self.deviceData:getDeviceVolume(),
				headphone = self.deviceData:getHeadphoneType() >= 0,
				timestamp = "update",
				musicName = self.device:getModData().tcmusic.mediaItem,
				musicDeviceID = self.deviceData:getEmitter(),
			}
			if self.device:getModData().tcmusic.deviceType == "InventoryItem" then
				ModData.getOrCreate("trueMusicData")["now_play"][musicId]["itemid"] = self.device:getID()
			end
		end
		transmitDeviceModDataIfNeeded(self.device)
	end
	if isClient() then
		ModData.transmit("trueMusicData") 
	end
	return true
end

-- AddMedia
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
		return true
	end
end
function ISTCBoomboxAction:completeAddMedia()
	local inventoryItem = self.secondaryItem
	local container = self.secondaryItem:getContainer()
		if container then
			if self.device:getModData().tcmusic.deviceType == "IsoObject" then
				self.device:getModData().tcmusic.mediaItem = inventoryItem:getType();
				syncJukeboxModeMedia(self.device)
				transmitDeviceModDataIfNeeded(self.device)
				local linkedItem = findLinkedWorldItem(self.device)
				if linkedItem then
					local linkedMd = linkedItem:getModData()
					linkedMd.tcmusic = linkedMd.tcmusic or {}
					linkedMd.tcmusic.mediaItem = inventoryItem:getType()
				end
			elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
			local mediaItemName = inventoryItem:getType()
			sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = mediaItemName, isPlaying = false })
		else
			self.device:getModData().tcmusic.mediaItem = inventoryItem:getType();
		end
		if (container:getType() == "floor" and inventoryItem:getWorldItem() and inventoryItem:getWorldItem():getSquare()) then
			inventoryItem:getWorldItem():getSquare():transmitRemoveItemFromSquare(inventoryItem:getWorldItem());
			inventoryItem:getWorldItem():getSquare():getWorldObjects():remove(inventoryItem:getWorldItem());
			inventoryItem:getWorldItem():getSquare():getObjects():remove(inventoryItem:getWorldItem());
			inventoryItem:setWorldItem(nil);
			inventoryItem:removeFromWorld()
		end
		if not inventoryItem:isInPlayerInventory() then
			container:removeItemOnServer(inventoryItem)
			sendRemoveItemFromContainer(container, inventoryItem)
		end
		if container == self.character:getInventory() then
			self.character:removeFromHands(inventoryItem)
			self.character:getInventory():Remove(inventoryItem)
			sendRemoveItemFromContainer(self.character:getInventory(), inventoryItem)
		else
			container:Remove(inventoryItem)
			sendRemoveItemFromContainer(container, inventoryItem)
		end
	end
	return true
end

-- RemoveMedia
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
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMedia()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		self.character:getInventory():AddItem(itemTape)
		sendAddItemToContainer(self.character:getInventory(), itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = getPortableMusicId(self.character)
		probe("completeRemoveMedia inv clear now_play musicId=" .. tostring(musicId) .. " itemId=" .. tostring(self.device:getID()))
		if self.device:getModData().tcmusic.isPlaying and self.character:getModData().tcmusicid then
			self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
			self.character:getModData().tcmusicid = nil
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	else
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
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
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	return true
end

function ISTCBoomboxAction:new(mode, character, device, secondaryItem)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.mode = mode
	o.character = character
	o.device = device
	o.secondaryItem = secondaryItem
	o.deviceData = device and device:getDeviceData()
	o.stopOnWalk = false
	o.stopOnRun = true
	o.stopOnAim = true
	o.maxTime = o:getDuration()
	return o
end

-- a FannyFront
function ISTCBoomboxAction:isValidRemoveMediaToFannyF()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToFannyF()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToFannyF()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		if not inventory then
			local packFront = self.character:getWornItem(ItemBodyLocation.FANNY_PACK_BACK)
			if packFront and packFront:getItemContainer() then
				inventory = packFront:getItemContainer()
			end
		end
		if not inventory then
			inventory = self.character:getInventory()
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a guantera o FannyFront
function ISTCBoomboxAction:isValidRemoveMediaToGloveFannyF()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToGloveFannyF()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToGloveFannyF()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		local vehicle = self.character:getVehicle()
		if vehicle then
			local seat = vehicle:getSeat(self.character)
			if seat <= 1 then
				local glove = vehicle:getPartById("GloveBox")
				if glove then
					local glovePack = glove:getItemContainer()
					if glovePack then
						inventory = glovePack
					end
				end
			end
		end
		if not inventory then
			local packFront = self.character:getWornItem(ItemBodyLocation.FANNY_PACK_BACK)
			if packFront and packFront:getItemContainer() then
				inventory = packFront:getItemContainer()
			end
		end
		if not inventory then
			inventory = self.character:getInventory()
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a FannyBack
function ISTCBoomboxAction:isValidRemoveMediaToFannyB()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToFannyB()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToFannyB()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		if not inventory then
			local packBack = self.character:getWornItem(ItemBodyLocation.FANNY_PACK_FRONT)
			if packBack and packBack:getItemContainer() then
				inventory = packBack:getItemContainer()
			end
		end
		if not inventory then
			inventory = self.character:getInventory()
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a guantera o FannyBack
function ISTCBoomboxAction:isValidRemoveMediaToGloveFannyB()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToGloveFannyB()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToGloveFannyB()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		local vehicle = self.character:getVehicle()
		if vehicle then
			local seat = vehicle:getSeat(self.character)
			if seat <= 1 then
				local glove = vehicle:getPartById("GloveBox")
				if glove then
					local glovePack = glove:getItemContainer()
					if glovePack then
						inventory = glovePack
					end
				end
			end
		else
			if not inventory then
				local packBack = self.character:getWornItem(ItemBodyLocation.FANNY_PACK_FRONT)
				if packBack and packBack:getItemContainer() then
					inventory = packBack:getItemContainer()
				end
			end
			if not inventory then
				inventory = self.character:getInventory()
			end
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a Weebing
function ISTCBoomboxAction:isValidRemoveMediaToWeebing()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToWeebing()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToWeebing()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		if not inventory then
			local containerWeebing = self.character:getWornItem(ItemBodyLocation.WEBBING)
			if containerWeebing and containerWeebing:getItemContainer() then
				inventory = containerWeebing:getItemContainer()
			end
		end
		if not inventory then
			inventory = self.character:getInventory()
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a guantera o Weebing
function ISTCBoomboxAction:isValidRemoveMediaToGloveWeebing()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToGloveWeebing()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToGloveWeebing()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		local vehicle = self.character:getVehicle()
		if vehicle then
			local seat = vehicle:getSeat(self.character)
			if seat <= 1 then
				local glove = vehicle:getPartById("GloveBox")
				if glove then
					local glovePack = glove:getItemContainer()
					if glovePack then
						inventory = glovePack
					end
				end
			end
		end
		if not inventory then
			local containerWeebing = self.character:getWornItem(ItemBodyLocation.WEBBING)
			if containerWeebing and containerWeebing:getItemContainer() then
				inventory = containerWeebing:getItemContainer()
			end
		end
		if not inventory then
			inventory = self.character:getInventory()
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a Satchel
function ISTCBoomboxAction:isValidRemoveMediaToSatchel()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToSatchel()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToSatchel()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		if not inventory then
			local containerSatchel = self.character:getWornItem(ItemBodyLocation.SATCHEL) or self.character:getClothingItem_Satchel()
			if containerSatchel and containerSatchel:getItemContainer() then
				inventory = containerSatchel:getItemContainer()
			end
		end
		if not inventory then
			inventory = self.character:getInventory()
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a guantera o Satchel
function ISTCBoomboxAction:isValidRemoveMediaToGloveSatchel()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToGloveSatchel()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToGloveSatchel()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		local vehicle = self.character:getVehicle()
		if vehicle then
			local seat = vehicle:getSeat(self.character)
			if seat <= 1 then
				local glove = vehicle:getPartById("GloveBox")
				if glove then
					local glovePack = glove:getItemContainer()
					if glovePack then
						inventory = glovePack
					end
				end
			end
		end
		if not inventory then
			local containerSatchel = self.character:getWornItem(ItemBodyLocation.SATCHEL) or self.character:getClothingItem_Satchel()
			if containerSatchel and containerSatchel:getItemContainer() then
				inventory = containerSatchel:getItemContainer()
			end
		end
		if not inventory then
			inventory = self.character:getInventory()
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a mochila
function ISTCBoomboxAction:isValidRemoveMediaToBack()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToBack()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToBack()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		if not inventory then
			local containerBack = self.character:getClothingItem_Back() -- or self.character:getWornItem(ItemBodyLocation.BACK)
			if containerBack then
				inventory = containerBack:getItemContainer()
			end
		end
		if not inventory then
			inventory = self.character:getInventory()
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a guantera o mochila
function ISTCBoomboxAction:isValidRemoveMediaToGloveBack()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToGloveBack()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToGloveBack()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory
		local vehicle = self.character:getVehicle()
		if vehicle then
			local seat = vehicle:getSeat(self.character)
			if seat <= 1 then
				local glove = vehicle:getPartById("GloveBox")
				if glove then
					local glovePack = glove:getItemContainer()
					if glovePack then
						inventory = glovePack
					end
				end
			end
		end
		if not inventory then
			local backPack = self.character:getClothingItem_Back()
			if backPack and backPack:getItemContainer() then
				inventory = backPack:getItemContainer()
			end
		end
		if not inventory then
			inventory = self.character:getInventory()
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- a guantera
function ISTCBoomboxAction:isValidRemoveMediaToGlove()
	if self.device:getModData().tcmusic.mediaItem then
		return true
	else
		return false
	end
end
function ISTCBoomboxAction:performRemoveMediaToGlove()
	if self:isValidRemoveMedia() and self.character:getInventory() then
		return true
	end
end
function ISTCBoomboxAction:completeRemoveMediaToGlove()
	local itemTape = createMediaItem(self.device:getModData().tcmusic.mediaItem)
	if itemTape then
		local inventory = self.character:getInventory()
		local vehicle = self.character:getVehicle()
		if vehicle then
			local seat = vehicle:getSeat(self.character)
			if seat <= 1 then
				local glove = vehicle:getPartById("GloveBox")
				if glove then
					local glovePack = glove:getItemContainer()
					if glovePack then
						inventory = glovePack
					end
				end
			end
		end
		inventory:AddItem(itemTape)
		sendAddItemToContainer(inventory, itemTape)
	end
	if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		if self.device:getVehicle() and self.device:getVehicle():getEmitter() then
			self.device:getVehicle():getEmitter():stopAll()
		end
	elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
		local musicId = nil
		musicId = getPortableMusicId(self.character)
		if self.device:getModData().tcmusic.isPlaying then
			if self.character:getModData().tcmusicid then
				self.character:getEmitter():stopSound(self.character:getModData().tcmusicid)
				self.character:getModData().tcmusicid = nil
			end
			ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
		end
	else
		local musicId = nil
		musicId = "#" .. self.device:getX() .. "°" .. self.device:getY() .. "°" .. self.device:getZ()
		local emitter = self.deviceData:getEmitter()
		if emitter then
			self.deviceData:getEmitter():stopAll()
		end
		ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
	end
	self.device:getModData().tcmusic.mediaItem = nil
	syncJukeboxModeMedia(self.device)
	self.device:getModData().tcmusic.isPlaying = false
	if self.device:getModData().tcmusic.deviceType == "IsoObject" then
		transmitDeviceModDataIfNeeded(self.device)
	elseif self.device:getModData().tcmusic.deviceType == "VehiclePart" then
		sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = "nil", isPlaying = false })
	end
	if isClient() then
		ModData.transmit("trueMusicData")
	end
	return true
end

-- obtener valores del menu opciones
local function getModPZTMOptValue(optId)
	-- Add safety check for PZAPI and ModOptions
	if not PZAPI or not PZAPI.ModOptions then
		return nil
	end
	
	local modOption = PZAPI.ModOptions:getOptions("pztmModOpt")
	if not modOption then
		return nil
	end
	
	local option = modOption:getOption(optId)
	if not option then
		return nil
	end
	
	return option:getValue()
end

-- obtener dispositivos
local function getVehicleRadio(player)
	local player = player
	if not player then
		return nil
	end
	local automovil = player:getVehicle()
	if not automovil then
		return nil
	end
	local seat = automovil:getSeat(player)
	if seat > 1 then
		return nil
	end
	local radio = automovil:getPartById("Radio")
	if radio then
		local deviceModData = radio:getModData()
		if deviceModData then
			local deviceTCMusic = deviceModData.tcmusic
			if not deviceTCMusic then
				deviceModData.tcmusic = {}
				deviceModData.tcmusic.deviceType = "VehiclePart"
				deviceModData.tcmusic.isPlaying = false
				deviceModData.tcmusic.mediaItem = nil
				automovil:updateParts()
			end
		end
		return radio
	end
	return nil
end
local function getWalkman(player)
	local player = player
	if not player then
		return nil
	end
	local playerInventory = player:getInventory()
	local primary = player:getPrimaryHandItem()
	if primary and (TCMusic.WalkmanPlayer[primary:getFullType()] or TCMusic.ItemMusicPlayer[primary:getFullType()]) then
		local deviceModData = primary:getModData()
		if deviceModData then
			local deviceTCMusic = deviceModData.tcmusic
			if not deviceTCMusic then
				deviceModData.tcmusic = {}
				deviceModData.tcmusic.deviceType = "InventoryItem"
				deviceModData.tcmusic.isPlaying = false
				deviceModData.tcmusic.mediaItem = nil
				deviceModData.tcmusicid = nil
				ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
				if isClient() then ModData.transmit("trueMusicData") end
			end
		end
		return primary
	end
	local secondary = player:getSecondaryHandItem()
	if secondary and (TCMusic.WalkmanPlayer[secondary:getFullType()] or TCMusic.ItemMusicPlayer[secondary:getFullType()]) then
		local deviceModData = secondary:getModData()
		if deviceModData then
			local deviceTCMusic = deviceModData.tcmusic
			if not deviceTCMusic then
				deviceModData.tcmusic = {}
				deviceModData.tcmusic.deviceType = "InventoryItem"
				deviceModData.tcmusic.isPlaying = false
				deviceModData.tcmusic.mediaItem = nil
				deviceModData.tcmusicid = nil
				ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
				if isClient() then ModData.transmit("trueMusicData") end
			end
		end
		return secondary
	end
	local attachedItems = player:getAttachedItems()
	if attachedItems then
		for i = 0, attachedItems:size() - 1 do
			local attached = attachedItems:get(i)
			local item = attached and attached:getItem()
			if item then
				local loc = attached:getLocation()
				if (loc == "TCWalkman Belt Left" or loc == "TCWalkman Belt Right"
					or loc == "Webbing Right Walkie" or loc == "Webbing Left Walkie"
					or loc == "Webbing Right" or loc == "Webbing Left"
					or loc == "Big Weapon On Back" or loc == "Big Weapon On Back with Bag" or loc == "Back")
					and (TCMusic.WalkmanPlayer[item:getFullType()] or TCMusic.ItemMusicPlayer[item:getFullType()]) then
					local deviceModData = item:getModData()
					if deviceModData then
						local deviceTCMusic = deviceModData.tcmusic
						if not deviceTCMusic then
							deviceModData.tcmusic = {}
							deviceModData.tcmusic.deviceType = "InventoryItem"
							deviceModData.tcmusic.isPlaying = false
							deviceModData.tcmusic.mediaItem = nil
							deviceModData.tcmusicid = nil
							ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
							if isClient() then ModData.transmit("trueMusicData") end
						end
					end
					return item
				end
			end
		end
	end
	for i = 0, playerInventory:getItems():size() - 1 do
		local item = playerInventory:getItems():get(i)
		if item and TCMusic.WalkmanPlayer[item:getFullType()] then
			local deviceModData = item:getModData()
			if deviceModData then
				local deviceTCMusic = deviceModData.tcmusic
				if not deviceTCMusic then
					deviceModData.tcmusic = {}
					deviceModData.tcmusic.deviceType = "InventoryItem"
					deviceModData.tcmusic.isPlaying = false
					deviceModData.tcmusic.mediaItem = nil
					deviceModData.tcmusicid = nil
					ModData.getOrCreate("trueMusicData")["now_play"][musicId] = nil
					if isClient() then ModData.transmit("trueMusicData") end
				end
			end
			return item
		end
	end
	return nil
end

local function resolvePlayerDevice(player)
	local portable = getWalkman(player)
	if portable then
		return portable, false
	end
	local vehicleDevice = player and player:getVehicle() and getVehicleRadio(player) or nil
	return vehicleDevice, vehicleDevice ~= nil
end

local function adjustDeviceVolume(player, device, delta)
	if not device or not device.getDeviceData then return end
	local deviceData = device:getDeviceData()
	if not deviceData then return end
	if deviceData:getIsBatteryPowered() then
		if (deviceData.getHasBattery and not deviceData:getHasBattery()) or (deviceData.getPower and deviceData:getPower() <= 0) then
			player:Say(getText("IGUI_No_Battery"))
			return
		end
	end
	if not deviceData:getIsTurnedOn() then
		return
	end
	local current = deviceData:getDeviceVolume()
	local target = current + delta
	if target < 0 then target = 0 end
	if target > 1 then target = 1 end
	ISTimedActionQueue.add(ISTCBoomboxAction:new("SetVolume", player, device, target))
end

local function handlePlayStop(player)
	local playerDevice = nil
	playerDevice = (resolvePlayerDevice(player))
	if not playerDevice then
		player:Say(getText("IGUI_No_Device"))
		return
	end
	local deviceData = playerDevice.getDeviceData and playerDevice:getDeviceData() or nil
	if deviceData and deviceData:getIsBatteryPowered() then
		if (deviceData.getHasBattery and not deviceData:getHasBattery()) or (deviceData.getPower and deviceData:getPower() <= 0) then
			player:Say(getText("IGUI_No_Battery"))
			return
		end
	end
	local deviceModData = playerDevice:getModData()
	if not deviceModData then
		player:Say(getText("IGUI_No_ValidDevice"))
		return
	end
	local deviceTCMusic = deviceModData.tcmusic
	if not deviceTCMusic then
		deviceModData.tcmusic = {}
		deviceTCMusic = deviceModData.tcmusic
	end
	local deviceMediaItem = deviceTCMusic.mediaItem
	if not deviceMediaItem then
		player:Say(getText("IGUI_No_Cassette"))
		return
	end
	if deviceTCMusic.deviceType == "InventoryItem"
		and TCMusic.WalkmanPlayer[playerDevice:getFullType()]
		and (not hasHeadphones(playerDevice, deviceData)) then
		player:Say(getText("IGUI_No_Audifonos"))
		return
	end
	local isOn = deviceData and deviceData:getIsTurnedOn() or false
	local isPlaying = deviceTCMusic.isPlaying == true
	if isPlaying then
		ISTimedActionQueue.add(ISTCBoomboxAction:new("TogglePlayMedia", player, playerDevice))
		if isOn then
			ISTimedActionQueue.add(ISTCBoomboxAction:new("ToggleOnOff", player, playerDevice))
		end
	else
		if not isOn then
			ISTimedActionQueue.add(ISTCBoomboxAction:new("ToggleOnOff", player, playerDevice))
		end
		ISTimedActionQueue.add(ISTCBoomboxAction:new("TogglePlayMedia", player, playerDevice))
	end
end

-- obtener cassette desde
local function getCassetteFromPlayer(player)
	local player = player
	if not player then
		return nil
	end
	local TCFoundCassettes = {}
	local cassette = nil
	local playerInventory = player:getInventory()
	if playerInventory then
		local cassettesEncontrados = 0
		for i = 0, playerInventory:getItems():size() - 1 do
			local item = playerInventory:getItems():get(i)
			if item and item:getType() and string.find(item:getType(), "Cassette") then
				if not TCFoundCassettes[item] and GlobalMusic[item:getType()] then
					cassettesEncontrados = cassettesEncontrados + 1
					TCFoundCassettes[cassettesEncontrados] = item
				end
			end
		end
		if #TCFoundCassettes >= 1 then
			local cassetteRandom = ZombRand(1, #TCFoundCassettes)
			if TCFoundCassettes[cassetteRandom] then
				cassette = TCFoundCassettes[cassetteRandom]
				return cassette
			end
		end
	end
	return nil
end
local function getCassetteFromFannyFront(player)
	local player = player
	local cassette = nil
	if not player then
		return nil
	end
	local TCFoundCassettes = {}
	local container = player:getInventory()
	local containerPackFront = player:getWornItem(ItemBodyLocation.FANNY_PACK_BACK)
	if containerPackFront then
		local containerInventory = containerPackFront:getItemContainer()
		local cassettesEncontrados = 0
		for i = 0, containerInventory:getItems():size() - 1 do
			local item = containerInventory:getItems():get(i)
			if item and item:getType() and string.find(item:getType(), "Cassette") then
				if not TCFoundCassettes[item] and GlobalMusic[item:getType()] then
					cassettesEncontrados = cassettesEncontrados + 1
					TCFoundCassettes[cassettesEncontrados] = item
				end
			end
		end
		if #TCFoundCassettes >= 1 then
			local cassetteRandom = ZombRand(1, #TCFoundCassettes)
			if TCFoundCassettes[cassetteRandom] then
				cassette = TCFoundCassettes[cassetteRandom]
				containerInventory:Remove(cassette)
				sendRemoveItemFromContainer(containerInventory, cassette);
				container:AddItem(cassette)
				sendAddItemToContainer(inventory, cassette)				
				return cassette
			end
		end
	end
	return nil
end
local function getCassetteFromFannyBack(player)
	local player = player
	local cassette = nil
	if not player then
		return nil
	end
	local TCFoundCassettes = {}
	local container = player:getInventory()
	local containerPackBack = player:getWornItem(ItemBodyLocation.FANNY_PACK_FRONT)
	if containerPackBack then
		local containerInventory = containerPackBack:getItemContainer()
		local cassettesEncontrados = 0
		for i = 0, containerInventory:getItems():size() - 1 do
			local item = containerInventory:getItems():get(i)
			if item and item:getType() and string.find(item:getType(), "Cassette") then
				-- containerInventory:Remove(item)
				-- container:AddItem(item)
				-- return item
				if not TCFoundCassettes[item] and GlobalMusic[item:getType()] then
					cassettesEncontrados = cassettesEncontrados + 1
					TCFoundCassettes[cassettesEncontrados] = item
				end
			end
		end
		if #TCFoundCassettes >= 1 then
			local cassetteRandom = ZombRand(1, #TCFoundCassettes)
			if TCFoundCassettes[cassetteRandom] then
				cassette = TCFoundCassettes[cassetteRandom]
				containerInventory:Remove(cassette)
				sendRemoveItemFromContainer(containerInventory, cassette)
				container:AddItem(cassette)
				sendAddItemToContainer(container, cassette)				
				return cassette
			end
		end
	end
	return nil
end
local function getCassetteFromWeebing(player)
	local player = player
	local cassette = nil
	if not player then
		return nil
	end
	local TCFoundCassettes = {}
	local container = player:getInventory()
	local containerWeebing = player:getWornItem(ItemBodyLocation.WEBBING)
	if containerWeebing then
		local containerInventory = containerWeebing:getItemContainer()
		local cassettesEncontrados = 0
		for i = 0, containerInventory:getItems():size() - 1 do
			local item = containerInventory:getItems():get(i)
			if item and item:getType() and string.find(item:getType(), "Cassette") then
				-- containerInventory:Remove(item)
				-- container:AddItem(item)
				-- return item
				if not TCFoundCassettes[item] and GlobalMusic[item:getType()] then
					cassettesEncontrados = cassettesEncontrados + 1
					TCFoundCassettes[cassettesEncontrados] = item
				end
			end
		end
		if #TCFoundCassettes >= 1 then
			local cassetteRandom = ZombRand(1, #TCFoundCassettes)
			if TCFoundCassettes[cassetteRandom] then
				cassette = TCFoundCassettes[cassetteRandom]
				containerInventory:Remove(cassette)
				sendRemoveItemFromContainer(containerInventory, cassette)
				container:AddItem(cassette)
				sendAddItemToContainer(container, cassette)				
				return cassette
			end
		end
	end
	return nil
end
local function getCassetteFromSatchel(player)
	local player = player
	local cassette = nil
	if not player then
		return nil
	end
	local TCFoundCassettes = {}
	local container = player:getInventory()
	local containerSatchel = player:getWornItem(ItemBodyLocation.SATCHEL) or player:getClothingItem_Satchel()
	if containerSatchel then
		local containerInventory = containerSatchel:getItemContainer()
		local cassettesEncontrados = 0
		for i = 0, containerInventory:getItems():size() - 1 do
			local item = containerInventory:getItems():get(i)
			if item and item:getType() and string.find(item:getType(), "Cassette") then
				-- containerInventory:Remove(item)
				-- container:AddItem(item)
				-- return item
				if not TCFoundCassettes[item] and GlobalMusic[item:getType()] then
					cassettesEncontrados = cassettesEncontrados + 1
					TCFoundCassettes[cassettesEncontrados] = item
				end
			end
		end
		if #TCFoundCassettes >= 1 then
			local cassetteRandom = ZombRand(1, #TCFoundCassettes)
			if TCFoundCassettes[cassetteRandom] then
				cassette = TCFoundCassettes[cassetteRandom]
				containerInventory:Remove(cassette)
				sendRemoveItemFromContainer(containerInventory, cassette)
				container:AddItem(cassette)
				sendAddItemToContainer(container, cassette)				
				return cassette
			end
		end
	end
	return nil
end
local function getCassetteFromPackBack(player)
	local player = player
	local cassette = nil
	if not player then
		return nil
	end
	local TCFoundCassettes = {}
	local container = player:getInventory()
	local containerBack = player:getClothingItem_Back() -- or player:getWornItem(ItemBodyLocation.BACK)
	if containerBack then
		local containerInventory = containerBack:getItemContainer()
		local cassettesEncontrados = 0
		for i = 0, containerInventory:getItems():size() - 1 do
			local item = containerInventory:getItems():get(i)
			if item and item:getType() and string.find(item:getType(), "Cassette") then
				if not TCFoundCassettes[item] and GlobalMusic[item:getType()] then
					cassettesEncontrados = cassettesEncontrados + 1
					TCFoundCassettes[cassettesEncontrados] = item
				end
			end
		end
		if #TCFoundCassettes >= 1 then
			local cassetteRandom = ZombRand(1, #TCFoundCassettes)
			if TCFoundCassettes[cassetteRandom] then
				cassette = TCFoundCassettes[cassetteRandom]
				containerInventory:Remove(cassette)
				sendRemoveItemFromContainer(containerInventory, cassette)
				container:AddItem(cassette)
				sendAddItemToContainer(container, cassette)				
				return cassette
			end
		end
	end
	return nil
end
local function getCassetteFromGlove(player)
	local player = player
	if not player then
		return nil
	end
	local TCFoundCassettes = {}
	local cassette = nil
	local container = player:getInventory()
	local vehicle = player:getVehicle()
	if not vehicle then
		return nil
	end
	local glove = vehicle:getPartById("GloveBox")
	if glove then
		local containerInventory = glove:getItemContainer()
		if containerInventory then
			local cassettesEncontrados = 0
			for i = 0, containerInventory:getItems():size() - 1 do
				local item = containerInventory:getItems():get(i)
				if item and item:getType() and string.find(item:getType(), "Cassette") then
					if not TCFoundCassettes[item] and GlobalMusic[item:getType()] then
						cassettesEncontrados = cassettesEncontrados + 1
						TCFoundCassettes[cassettesEncontrados] = item
					end
				end
			end
			if #TCFoundCassettes >= 1 then
				local cassetteRandom = ZombRand(1, #TCFoundCassettes)
				if TCFoundCassettes[cassetteRandom] then
					containerInventory:Remove(cassette)
					cassette = TCFoundCassettes[cassetteRandom]
					container:AddItem(cassette)
					sendAddItemToContainer(container, cassette)	
					return cassette
				end
			end
		end
	end
	return nil
end

-- ver tecla oprimida
local function onPZTMKeyPressed(key)
	player = getSpecificPlayer(0)
	if not player or player:isDead() then
		return
	end
	if UIManager.getSpeedControls() and (UIManager.getSpeedControls():getCurrentGameSpeed() == 0) then
		return
	end
	if JoypadState.players[1] then
		return
	end
	if player:isAttacking() then
		return
	end
	local queue = ISTimedActionQueue.queues[player]
	if queue and #queue.queue > 0 then
		return
	end
	-- seguridad superada, ahora a revisar los botones
	local playKey = getCore():getKey("TrueMoozic_PlayStop")
	local onOffKey = getCore():getKey("TrueMoozic_OnOff")
	local volUpKey = getCore():getKey("TrueMoozic_VolUp")
	local volDownKey = getCore():getKey("TrueMoozic_VolDown")
	local deviceOptionsKey = getCore():getKey("TrueMoozic_DeviceOptions")

	if playKey == key then -- ToggleOnOff + TogglePlayMedia
		handlePlayStop(player)
	elseif getModPZTMOptValue("2") == key then -- RemoveMedia
		local playerDevice = nil
		local isVehicleDevice = false
		local sendWhere = getModPZTMOptValue("6b")
		local actionChosedWithVehicle = "RemoveMedia"
		local actionChosed = "RemoveMedia"
		if sendWhere == 1 then
			if getModPZTMOptValue("5") then
				actionChosedWithVehicle = "RemoveMediaToGloveFannyF"
			end
			actionChosed = "RemoveMediaToFannyF"
		elseif sendWhere == 2 then
			if getModPZTMOptValue("5") then
				actionChosedWithVehicle = "RemoveMediaToGloveFannyB"
			end
			actionChosed = "RemoveMediaToFannyB"
		elseif sendWhere == 3 then
			if getModPZTMOptValue("5") then
				actionChosedWithVehicle = "RemoveMediaToGloveWeebing"
			end
			actionChosed = "RemoveMediaToWeebing"
		elseif sendWhere == 4 then
			if getModPZTMOptValue("5") then
				actionChosedWithVehicle = "RemoveMediaToGloveSatchel"
			end
			actionChosed = "RemoveMediaToSatchel"
		elseif sendWhere == 5 then
			if getModPZTMOptValue("5") then
				actionChosedWithVehicle = "RemoveMediaToGloveBack"
			end
			actionChosed = "RemoveMediaToBack"
		end
		playerDevice, isVehicleDevice = resolvePlayerDevice(player)
		if isVehicleDevice then
			if not playerDevice then
				player:Say(getText("IGUI_No_Device"))
				return
			end
			local deviceModData = playerDevice:getModData()
			if not deviceModData then
				player:Say(getText("IGUI_No_ValidDevice"))
				return
			end
			local deviceTCMusic = deviceModData.tcmusic
			if not deviceTCMusic then
				deviceModData.tcmusic = {}
			end
			local deviceMediaItem = playerDevice:getModData().tcmusic.mediaItem
			if not deviceMediaItem then
				player:Say(getText("IGUI_No_Cassette"))
				return
			end
			if getModPZTMOptValue("5") and getModPZTMOptValue("6") then
				ISTimedActionQueue.add(ISTCBoomboxAction:new(actionChosedWithVehicle, player, playerDevice))
			elseif getModPZTMOptValue("5") and not getModPZTMOptValue("6") then
				ISTimedActionQueue.add(ISTCBoomboxAction:new("RemoveMediaToGlove", player, playerDevice))
			elseif not getModPZTMOptValue("5") and getModPZTMOptValue("6") then
				ISTimedActionQueue.add(ISTCBoomboxAction:new(actionChosed, player, playerDevice))
			elseif not getModPZTMOptValue("5") and not getModPZTMOptValue("6") then
				ISTimedActionQueue.add(ISTCBoomboxAction:new("RemoveMedia", player, playerDevice))
			end
		else
			playerDevice = playerDevice or getWalkman(player)
			if not playerDevice then
				player:Say(getText("IGUI_No_Device"))
				return
			end
			local deviceModData = playerDevice:getModData()
			if not deviceModData then
				player:Say(getText("IGUI_No_ValidDevice"))
				return
			end
			local deviceTCMusic = deviceModData.tcmusic
			if not deviceTCMusic then
				deviceModData.tcmusic = {}
			end
			local deviceMediaItem = playerDevice:getModData().tcmusic.mediaItem
			if not deviceMediaItem then
				player:Say(getText("IGUI_No_Cassette"))
				return
			end
			if getModPZTMOptValue("6") then
				ISTimedActionQueue.add(ISTCBoomboxAction:new(actionChosed, player, playerDevice))
			else
				ISTimedActionQueue.add(ISTCBoomboxAction:new("RemoveMedia", player, playerDevice))
			end
		end
	elseif onOffKey == key then  -- ToggleOnOff
		local playerDevice = nil
		playerDevice = (resolvePlayerDevice(player))
		if not playerDevice then
			player:Say(getText("IGUI_No_Device"))
			return
		end
		local deviceData = playerDevice.getDeviceData and playerDevice:getDeviceData() or nil
		if deviceData and deviceData:getIsBatteryPowered() then
			if (deviceData.getHasBattery and not deviceData:getHasBattery()) or (deviceData.getPower and deviceData:getPower() <= 0) then
				player:Say(getText("IGUI_No_Battery"))
				return
			end
		end
		local deviceModData = playerDevice:getModData()
		if not deviceModData then
			player:Say(getText("IGUI_No_ValidDevice"))
			return
		end
		local deviceTCMusic = deviceModData.tcmusic
		if not deviceTCMusic then
			deviceModData.tcmusic = {}
		end
		ISTimedActionQueue.add(ISTCBoomboxAction:new("ToggleOnOff", player, playerDevice))
	elseif volUpKey == key then  -- Volume Up
		local playerDevice = nil
		playerDevice = (resolvePlayerDevice(player))
		if not playerDevice then
			player:Say(getText("IGUI_No_Device"))
			return
		end
		adjustDeviceVolume(player, playerDevice, 0.1)
	elseif volDownKey == key then  -- Volume Down
		local playerDevice = nil
		playerDevice = (resolvePlayerDevice(player))
		if not playerDevice then
			player:Say(getText("IGUI_No_Device"))
			return
		end
		adjustDeviceVolume(player, playerDevice, -0.1)
	elseif deviceOptionsKey == key then -- Device Options
		local playerDevice = nil
		playerDevice = (resolvePlayerDevice(player))
		if not playerDevice then
			player:Say(getText("IGUI_No_Device"))
			return
		end
		local md = playerDevice and playerDevice.getModData and playerDevice:getModData() or nil
		local tcm = md and md.tcmusic or nil
		local isWorldTMDevice = tcm and (tcm.deviceType == "IsoObject")
		if ISTCBoomboxWindow and (isWorldTMDevice or (playerDevice.getFullType and (TCMusic.ItemMusicPlayer[playerDevice:getFullType()] or TCMusic.WalkmanPlayer[playerDevice:getFullType()]))) then
			ISTCBoomboxWindow.activate(player, playerDevice)
			return
		end
		if ISRadioWindow and ISRadioWindow.activate then
			ISRadioWindow.activate(player, playerDevice, true)
		end
	elseif getModPZTMOptValue("4") == key then -- Add
		local playerDevice = nil
		local isVehicleDevice = false
		local cassetteNew = nil
		local cassetteOld = nil
		local playerModPZTMOpt5Value = getModPZTMOptValue("5")
		local playerModPZTMOpt6Value = getModPZTMOptValue("6")
		playerDevice, isVehicleDevice = resolvePlayerDevice(player)
		if isVehicleDevice then
			if not playerDevice then
				player:Say(getText("IGUI_No_Device"))
				return
			end
			local deviceModData = playerDevice:getModData() -- establecemos si tiene cassette
			if not deviceModData then
				player:Say(getText("IGUI_No_ValidDevice"))
				return
			end
			local deviceTCMusic = deviceModData.tcmusic
			if not deviceTCMusic then
				deviceModData.tcmusic = {}			
			end
			cassetteOld = playerDevice:getModData().tcmusic.mediaItem	
			if cassetteOld then
				player:Say(getText("IGUI_Cassette_Yet"))
				return
			end
			if not cassetteNew and playerModPZTMOpt5Value then
				cassetteNew = getCassetteFromGlove(player)
			end
		else
			playerDevice = playerDevice or getWalkman(player)
			if not playerDevice then
				player:Say(getText("IGUI_No_Device"))
				return
			end
			local deviceModData = playerDevice:getModData() -- establecemos si tiene cassette
			if not deviceModData then
				player:Say(getText("IGUI_No_ValidDevice"))
				return
			end
			local deviceTCMusic = deviceModData.tcmusic
			if not deviceTCMusic then
				deviceModData.tcmusic = {}			
			end
			cassetteOld = playerDevice:getModData().tcmusic.mediaItem	
			if cassetteOld then
				player:Say(getText("IGUI_Cassette_Yet"))
				return
			end
		end
		if not cassetteNew then
			cassetteNew = getCassetteFromPlayer(player)
		end
		if not cassetteNew and playerModPZTMOpt6Value then
			local takeFrom = getModPZTMOptValue("6a")
			if takeFrom == 1 then
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyFront(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyBack(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromWeebing(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromSatchel(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromPackBack(player)
				end
			elseif takeFrom == 2 then
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyBack(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyFront(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromWeebing(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromSatchel(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromPackBack(player)
				end
			elseif takeFrom == 3 then
				if not cassetteNew then
					cassetteNew = getCassetteFromWeebing(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyFront(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyBack(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromSatchel(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromPackBack(player)
				end
			elseif takeFrom == 4 then
				if not cassetteNew then
					cassetteNew = getCassetteFromSatchel(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyFront(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyBack(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromWeebing(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromPackBack(player)
				end
			elseif takeFrom == 5 then
				if not cassetteNew then
					cassetteNew = getCassetteFromPackBack(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyFront(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromFannyBack(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromWeebing(player)
				end
				if not cassetteNew then
					cassetteNew = getCassetteFromSatchel(player)
				end
			end
		end
		if not cassetteNew then
			player:Say(getText("IGUI_No_Find_Cassette"))
			return
		end
		ISTimedActionQueue.add(ISTCBoomboxAction:new("AddMedia", player, playerDevice, cassetteNew))
	end
end

-- verificar y activar si se eligio agregar la supervisión de teclas
local function onPZTMGameStart()
	Events.OnKeyPressed.Add(onPZTMKeyPressed)
end

-- agregar el verificador de teclas al iniciar
Events.OnGameStart.Add(onPZTMGameStart)








