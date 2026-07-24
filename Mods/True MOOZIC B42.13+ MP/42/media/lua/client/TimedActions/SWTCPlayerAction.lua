
require "TimedActions/ISBaseTimedAction"

SWTCPlayerAction = ISBaseTimedAction:derive("SWTCPlayerAction")

local function playPlayerEmitterSound(playerObj, soundName)
    if not playerObj or not soundName or not playerObj.getEmitter then return nil end
    local emitter = playerObj:getEmitter()
    if not emitter then return nil end
    if emitter.playSoundImpl then
        return emitter:playSoundImpl(soundName, playerObj)
    end
    if emitter.playSound then
        return emitter:playSound(soundName)
    end
    return nil
end

function SWTCPlayerAction:isValid()
    if self.character and self.device and self.deviceData and self.mode then
        if self["isValid"..self.mode] then
            return self["isValid"..self.mode](self)
        end
    end
    return false
end

function SWTCPlayerAction:waitToStart()
    return false
end

function SWTCPlayerAction:update()
    if self.character and self.deviceData and self.deviceData.isIsoDevice and self.deviceData:isIsoDevice() then
        self.character:faceThisObject(self.deviceData:getParent())
    end
end

function SWTCPlayerAction:start()
end

function SWTCPlayerAction:stop()
    ISBaseTimedAction.stop(self)
end

function SWTCPlayerAction:perform()
    if self.character and self.device and self.deviceData and self.mode then
        if self["perform"..self.mode] then
            self["perform"..self.mode](self)
        end
    end
    ISBaseTimedAction.perform(self)
end

function SWTCPlayerAction:isValidTogglePlayMedia()
    local modData = self.device:getModData()
    return self.deviceData:getIsTurnedOn() and self.deviceData:getPower() > 0 and modData.customMusic and modData.customMusic.cdType ~= nil
end

function SWTCPlayerAction:performTogglePlayMedia()
    if not self:isValidTogglePlayMedia() then
        return
    end
    
    local modData = self.device:getModData()
    if not modData.customMusic then
        modData.customMusic = {}
    end
    
    local isCurrentlyPlaying = modData.customMusic.isPlaying == true
    
    if isCurrentlyPlaying then
        modData.customMusic.isPlaying = false
        
        if self.character:getModData().customMusicId then
            self.character:getEmitter():stopSound(self.character:getModData().customMusicId)
            self.character:getModData().customMusicId = nil
        end
        
        local originalVolume = self.character:getModData().originalMusicVolume
        if originalVolume then
            getCore():setOptionMusicVolume(originalVolume)
            self.character:getModData().originalMusicVolume = nil
        end
    else
        if self.deviceData:getHeadphoneType() < 0 then
            return
        end
        
        modData.customMusic.isPlaying = true
        
        self:stopCurrentDeviceAudio()
        
        local originalVolume = getCore():getOptionMusicVolume()
        self.character:getModData().originalMusicVolume = originalVolume
        getCore():setOptionMusicVolume(0)
        
        local soundName = modData.customMusic.soundName
        if soundName then
            if not self:playCurrentDeviceAudio(soundName) then
                modData.customMusic.isPlaying = false
            end
        else
            modData.customMusic.isPlaying = false
        end
    end
end

function SWTCPlayerAction:isValidAddMedia()
    if not self.secondaryItem then
        return false
    end
    
    local modData = self.device:getModData()
    local hasCD = modData.customMusic and modData.customMusic.cdType ~= nil
    if hasCD then
        return false
    end
    
    return self:isCustomCD(self.secondaryItem)
end

function SWTCPlayerAction:performAddMedia()
    if not self:isValidAddMedia() or not self.secondaryItem then
        return
    end
    
    local inventoryItem = self.secondaryItem
    local container = inventoryItem:getContainer()
    
    if not container then
        return
    end
    
    local modData = self.device:getModData()
    if not modData.customMusic then
        modData.customMusic = {}
    end
    
    local itemType = inventoryItem:getType()
    local cdData = self:getCDData(itemType)
    
    if cdData then
        modData.customMusic.cdType = itemType
        modData.customMusic.cdDisplayName = cdData.displayName
        modData.customMusic.soundName = cdData.soundName
        modData.customMusic.isPlaying = false
            -- store the full item type so eject can restore the exact custom CD item
              modData.customMusic.fullItemType = inventoryItem:getFullType()
    else
        return
    end
    
    if inventoryItem:isInPlayerInventory() then
        container:DoRemoveItem(inventoryItem)
    else
        if container:getType() == "floor" and inventoryItem:getWorldItem() and inventoryItem:getWorldItem():getSquare() then
            inventoryItem:getWorldItem():getSquare():transmitRemoveItemFromSquare(inventoryItem:getWorldItem())
            inventoryItem:getWorldItem():getSquare():getWorldObjects():remove(inventoryItem:getWorldItem())
            inventoryItem:getWorldItem():getSquare():getChunk():recalcHashCodeObjects()
            inventoryItem:getWorldItem():getSquare():getObjects():remove(inventoryItem:getWorldItem())
            inventoryItem:setWorldItem(nil)
        end
        container:removeItemOnServer(inventoryItem)
        container:DoRemoveItem(inventoryItem)
    end
end

function SWTCPlayerAction:isValidRemoveMedia()
    local modData = self.device:getModData()
    return (modData.customMusic and modData.customMusic.cdType ~= nil) or (modData.originalCD and modData.originalCD.cdType ~= nil)
end

function SWTCPlayerAction:performRemoveMedia()
    if not self:isValidRemoveMedia() or not self.character:getInventory() then
        return
    end
    
    local modData = self.device:getModData()
    
    if modData.originalCD and modData.originalCD.cdType then
        self:removeOriginalCD()
        return
    end
    
    local cdType = modData.customMusic.cdType
    
    if modData.customMusic.isPlaying then
        modData.customMusic.isPlaying = false
        
        self:stopCurrentDeviceAudio()
        
        local originalVolume = self.character:getModData().originalMusicVolume
        if originalVolume then
            getCore():setOptionMusicVolume(originalVolume)
            self.character:getModData().originalMusicVolume = nil
        end
    end
    
    local sm = getScriptManager and getScriptManager() or nil
    local storedFT = modData.customMusic and modData.customMusic.fullItemType or nil

    local itemFullType = storedFT
    if itemFullType and sm and sm.getItem and not sm:getItem(itemFullType) then
        itemFullType = nil
    end
    if not itemFullType then
        itemFullType = self:getItemFullType(cdType)
    end

    if itemFullType then
        local inventory = self.targetContainer or self.character:getInventory()
        if inventory and inventory.AddItem then
            inventory:AddItem(itemFullType)
        end
    end
    
    modData.customMusic.cdType = nil
    modData.customMusic.cdDisplayName = nil
    modData.customMusic.soundName = nil
    modData.customMusic.isPlaying = false
end

function SWTCPlayerAction:removeOriginalCD()
    if not self.character:getInventory() then
        return
    end
    
    local modData = self.device:getModData()
    
    if self.deviceData and self.deviceData.removeMediaItem then
        self.deviceData:removeMediaItem(self.character:getInventory())
    end
    
    modData.originalCD = nil
end

function SWTCPlayerAction:isValidSetVolume()
    if (not self.secondaryItem) or type(self.secondaryItem) ~= "number" then 
        return false 
    end
    return self.deviceData:getIsTurnedOn() and self.deviceData:getPower() > 0
end

function SWTCPlayerAction:performSetVolume()
    if not self:isValidSetVolume() then
        return
    end
    
    self.deviceData:setDeviceVolume(self.secondaryItem)
    
    local modData = self.device:getModData()
    if modData.customMusic and modData.customMusic.isPlaying then
        local deviceId = self:getDeviceId()
        if deviceId and self.character:getModData().customMusicIds and self.character:getModData().customMusicIds[deviceId] then
            local actualVolume = self.deviceData:getDeviceVolume() * 0.4
            self.character:getEmitter():setVolume(self.character:getModData().customMusicIds[deviceId], actualVolume)
        end
    end
end

function SWTCPlayerAction:isValidMuteVolume()
    return self.deviceData:getIsTurnedOn() and self.deviceData:getPower() > 0 and self.deviceData:getDeviceVolume() > 0
end

function SWTCPlayerAction:performMuteVolume()
    if not self:isValidMuteVolume() then
        return
    end
    
    if self.character then
        self.character:playSound("TelevisionMute")
    end
    
    self.deviceData:setDeviceVolume(0)
    
    local modData = self.device:getModData()
    if modData.customMusic and modData.customMusic.isPlaying then
        local deviceId = self:getDeviceId()
        if deviceId and self.character:getModData().customMusicIds and self.character:getModData().customMusicIds[deviceId] then
            self.character:getEmitter():setVolume(self.character:getModData().customMusicIds[deviceId], 0)
        end
    end
end

function SWTCPlayerAction:isValidUnMuteVolume()
    if (not self.secondaryItem) or type(self.secondaryItem) ~= "number" then 
        return false 
    end
    return self.deviceData:getIsTurnedOn() and self.deviceData:getPower() > 0 and self.deviceData:getDeviceVolume() <= 0
end

function SWTCPlayerAction:performUnMuteVolume()
    if not self:isValidUnMuteVolume() then
        return
    end
    
    if self.character then
        self.character:playSound("TelevisionUnMute")
    end
    
    self.deviceData:setDeviceVolume(self.secondaryItem)
    
    local modData = self.device:getModData()
    if modData.customMusic and modData.customMusic.isPlaying then
        local deviceId = self:getDeviceId()
        if deviceId and self.character:getModData().customMusicIds and self.character:getModData().customMusicIds[deviceId] then
            local actualVolume = self.deviceData:getDeviceVolume() * 0.4
            self.character:getEmitter():setVolume(self.character:getModData().customMusicIds[deviceId], actualVolume)
        end
    end
end

function SWTCPlayerAction:isValidAddHeadphones()
    return self.deviceData:getHeadphoneType() < 0
end

function SWTCPlayerAction:performAddHeadphones()
    if not self:isValidAddHeadphones() or not self.secondaryItem then
        return
    end
    
    self.deviceData:addHeadphones(self.secondaryItem)
end

function SWTCPlayerAction:isValidRemoveHeadphones()
    return self.deviceData:getHeadphoneType() >= 0
end

function SWTCPlayerAction:performRemoveHeadphones()
    if not self:isValidRemoveHeadphones() then
        return
    end
    
    if self.character:getInventory() then
        self.deviceData:getHeadphones(self.character:getInventory())
    end
end

-- Helper Methods
function SWTCPlayerAction:isCustomCD(item)
    if not item then return false end
    
    return item:getModData().CustomMusicCD == true
end


-- Bulletproof: searches every loaded item definition across ALL modules
-- for an item whose bare name == itemType.  Avoids relying on FindItem's
-- exact semantics which vary between PZ builds.
local function scanAllItemsForType(itemType)
    if not itemType then return nil end
    local sm = getScriptManager and getScriptManager() or nil
    if not sm then return nil end
    if sm.getAllItems then
        local ok, list = pcall(function() return sm:getAllItems() end)
        if ok and list and list.size then
            local n = list:size()
            for i = 0, n - 1 do
                local it = list:get(i)
                if it and it.getName and it:getName() == itemType then
                    if it.getFullName then return it:getFullName() end
                    if it.getModuleName then return it:getModuleName() .. "." .. itemType end
                end
            end
        end
    end
    return nil
end

function SWTCPlayerAction:getItemFullType(itemType)
    if not itemType then return nil end

    local found = scanAllItemsForType(itemType)
    if found then return found end

    local sm = getScriptManager and getScriptManager() or nil
    if SWTCCDAlbums and SWTCCDAlbums[itemType] and SWTCCDAlbums[itemType].fullItemType then
        local ft = SWTCCDAlbums[itemType].fullItemType
        if sm and sm.getItem and sm:getItem(ft) then return ft end
    end

    local modId = string.match(itemType, "^([^_]+)_")
    if modId then
        return modId .. "_CustomMusic." .. itemType
    end

    return "Base." .. itemType
end

function SWTCPlayerAction:new(mode, character, device, secondaryItem, targetContainer)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    
    o.mode = mode
    o.character = character
    o.device = device
    o.deviceData = device and device:getDeviceData()
    o.secondaryItem = secondaryItem
    o.targetContainer = targetContainer
    o.stopOnWalk = false
    o.stopOnRun = true
    o.maxTime = 30
    
    return o
end

function SWTCPlayerAction:getDeviceId()
    if not self.device then return nil end
    
    if instanceof(self.device, "InventoryItem") then
        return "item_" .. self.device:getID()
    elseif instanceof(self.device, "IsoObject") then
        return "world_" .. self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
    elseif instanceof(self.device, "VehiclePart") then
        if self.device:getVehicle() then
            return "vehicle_" .. self.device:getVehicle():getId() .. "_" .. self.device:getType()
        else
            return "vehiclepart_" .. self.device:getType()
        end
    else
        return "default_" .. tostring(self.device)
    end
end

function SWTCPlayerAction:stopCurrentDeviceAudio()
    local deviceId = self:getDeviceId()
    if deviceId and self.character:getModData().customMusicIds and self.character:getModData().customMusicIds[deviceId] then
        self.character:getEmitter():stopSound(self.character:getModData().customMusicIds[deviceId])
        self.character:getModData().customMusicIds[deviceId] = nil
    end
end

function SWTCPlayerAction:playCurrentDeviceAudio(soundName)
    if not soundName then return false end
    
    local deviceId = self:getDeviceId()
    if not deviceId then return false end
    
    if not self.character:getModData().customMusicIds then
        self.character:getModData().customMusicIds = {}
    end
    
    if self.character:getModData().customMusicIds[deviceId] then
        self.character:getEmitter():stopSound(self.character:getModData().customMusicIds[deviceId])
    end
    
    self.character:getModData().customMusicIds[deviceId] = playPlayerEmitterSound(self.character, soundName)
    
    if self.character:getModData().customMusicIds[deviceId] then
        local actualVolume = self.deviceData:getDeviceVolume() * 0.4
        self.character:getEmitter():setVolume(self.character:getModData().customMusicIds[deviceId], actualVolume)
        return true
    else
        return false
    end
end 