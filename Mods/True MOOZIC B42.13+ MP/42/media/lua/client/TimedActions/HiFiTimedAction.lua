require "TimedActions/ISBaseTimedAction"

HiFiTimedAction = ISBaseTimedAction:derive("HiFiTimedAction")

-- Audio-silence debug logs (toggled from sandbox option: PZTrueMoozicDebug page → AudioSilenceDebug)
local function audioDbg(msg)
    if SandboxVars and SandboxVars.PZTrueMusicSandbox and SandboxVars.PZTrueMusicSandbox.AudioSilenceDebug then
        print(msg)
    end
end

-- Vehicle parts draw power from the vehicle battery; DeviceData:getPower() returns 0
-- for vehicle radio slots, so we skip the power check for VehiclePart devices.
local function deviceHasPower(device, deviceData)
    if instanceof(device, "VehiclePart") then return true end
    return deviceData:getPower() > 0
end

-- Modes:
--   AddCassette / RemoveCassette / TogglePlayCassette
--   AddVinyl    / RemoveVinyl    / TogglePlayVinyl
--   AddCD       / RemoveCD       / TogglePlayCD
--   SetVolume   / MuteVolume     / UnMuteVolume
--   AddHeadphones / RemoveHeadphones

function HiFiTimedAction:isValid()
    if self.character and self.device and self.deviceData and self.mode then
        local fn = self["isValid" .. self.mode]
        if fn then return fn(self) end
    end
    return false
end

function HiFiTimedAction:waitToStart() return false end

function HiFiTimedAction:update()
    if self.character and self.deviceData and self.deviceData.isIsoDevice and self.deviceData:isIsoDevice() then
        self.character:faceThisObject(self.deviceData:getParent())
    end
end

function HiFiTimedAction:start() end

function HiFiTimedAction:stop()
    ISBaseTimedAction.stop(self)
end

function HiFiTimedAction:perform()
    if self.character and self.device and self.deviceData and self.mode then
        local fn = self["perform" .. self.mode]
        if fn then fn(self) end
    end
    ISBaseTimedAction.perform(self)
end

--========================================================================
-- CD SLOT (custom CD system using SWTCCDAlbums)
--========================================================================

function HiFiTimedAction:isValidAddCD()
    if not self.secondaryItem then return false end
    local md = self.device:getModData()
    if md.hifiCD and md.hifiCD.cdType then return false end
    return self:isCustomCD(self.secondaryItem)
end

function HiFiTimedAction:performAddCD()
    if not self:isValidAddCD() or not self.secondaryItem then return end
    local item = self.secondaryItem
    local container = item:getContainer()
    if not container then return end
    local md = self.device:getModData()
    if not md.hifiCD then md.hifiCD = {} end
    local itemType = item:getType()
    local cdData = self:getCDData(itemType)
    if cdData then
        md.hifiCD.cdType = itemType
        md.hifiCD.cdDisplayName = cdData.displayName
        md.hifiCD.tracks = cdData.tracks
        md.hifiCD.currentTrack = 1
        md.hifiCD.totalTracks = #cdData.tracks
        md.hifiCD.isPlaying = false
        md.hifiCD.fullItemType = item:getFullType()
        container:DoRemoveItem(item)
        if instanceof(self.device, "IsoObject") and self.device.transmitModData then
            self.device:transmitModData()
        end
    end
end

function HiFiTimedAction:isValidRemoveCD()
    local md = self.device:getModData()
    return md.hifiCD and md.hifiCD.cdType ~= nil
end

function HiFiTimedAction:performRemoveCD()
    if not self:isValidRemoveCD() or not self.character:getInventory() then return end
    local md = self.device:getModData()
    if md.hifiCD.isPlaying then
        md.hifiCD.isPlaying = false
        self:stopCDAudio()
    end
    -- Validate stored fullItemType via ScriptManager; fall back to a
    -- cross-module search by bare item type if the stored value is stale.
    local sm = getScriptManager and getScriptManager() or nil
    local fullType = md.hifiCD.fullItemType
    if fullType and sm and sm.getItem and not sm:getItem(fullType) then
        fullType = nil
    end
    if not fullType then
        fullType = self:getItemFullType(md.hifiCD.cdType)
        if fullType and sm and sm.getItem and not sm:getItem(fullType) then
            fullType = nil
        end
    end
    if fullType then
        local inv = self.character:getInventory()
        if inv and inv.AddItem then
            inv:AddItem(fullType)
        end
    end
    md.hifiCD.cdType = nil
    md.hifiCD.cdDisplayName = nil
    md.hifiCD.tracks = nil
    md.hifiCD.currentTrack = nil
    md.hifiCD.totalTracks = nil
    md.hifiCD.isPlaying = false
    md.hifiCD.fullItemType = nil
    if instanceof(self.device, "IsoObject") and self.device.transmitModData then
        self.device:transmitModData()
    end
end

function HiFiTimedAction:isValidTogglePlayCD()
    local md = self.device:getModData()
    return self.deviceData:getIsTurnedOn() and deviceHasPower(self.device, self.deviceData)
        and md.hifiCD and md.hifiCD.cdType ~= nil
end

function HiFiTimedAction:performTogglePlayCD()
    local valid = self:isValidTogglePlayCD()
    local md = self.device:getModData()
    local isVeh = instanceof(self.device, "VehiclePart")
    audioDbg("[HIFIDBG][TogglePlayCD] valid=" .. tostring(valid) .. " isVehiclePart=" .. tostring(isVeh) .. " on=" .. tostring(self.deviceData:getIsTurnedOn()) .. " power=" .. tostring(self.deviceData:getPower()) .. " cdType=" .. tostring(md.hifiCD and md.hifiCD.cdType) .. " wasPlaying=" .. tostring(md.hifiCD and md.hifiCD.isPlaying))
    if not valid then return end
    if md.hifiCD.isPlaying then
        md.hifiCD.isPlaying = false
        self:stopCDAudio()
    else
        md.hifiCD.isPlaying = true
    end
    audioDbg("[HIFIDBG][TogglePlayCD] set isPlaying=" .. tostring(md.hifiCD.isPlaying))
    if instanceof(self.device, "IsoObject") and self.device.transmitModData then
        self.device:transmitModData()
    elseif isVeh then
        local v = self.device:getVehicle()
        if v and v.transmitPartModData then
            v:transmitPartModData(self.device)
            audioDbg("[HIFIDBG][TogglePlayCD] transmitPartModData vehId=" .. tostring(v:getId()))
        end
    end
end

--========================================================================
-- CASSETTE SLOT (TrueMusic tape system)
--========================================================================

function HiFiTimedAction:isValidAddCassette()
    if not self.secondaryItem then return false end
    local md = self.device:getModData()
    md.hifiTape = md.hifiTape or {}
    if md.hifiTape.mediaItem then return false end
    local itemType = self.secondaryItem:getType()
    return GlobalMusic and GlobalMusic[itemType] ~= nil
end

function HiFiTimedAction:performAddCassette()
    if not self:isValidAddCassette() or not self.secondaryItem then return end
    local item = self.secondaryItem
    local container = item:getContainer()
    if not container then return end
    local md = self.device:getModData()
    md.hifiTape = md.hifiTape or {}
    md.hifiTape.mediaItem = item:getFullType()
    md.hifiTape.isPlaying = false
    container:DoRemoveItem(item)
    if instanceof(self.device, "IsoObject") and self.device.transmitModData then
        self.device:transmitModData()
    end
end

function HiFiTimedAction:isValidRemoveCassette()
    local md = self.device:getModData()
    return md.hifiTape and md.hifiTape.mediaItem ~= nil
end

function HiFiTimedAction:performRemoveCassette()
    if not self:isValidRemoveCassette() or not self.character:getInventory() then return end
    local md = self.device:getModData()
    if md.hifiTape.isPlaying then
        md.hifiTape.isPlaying = false
        self:stopTapeAudio()
    end
    local mediaItem = md.hifiTape.mediaItem
    if mediaItem then
        local inv = self.character:getInventory()
        if inv and inv.AddItem then
            inv:AddItem(mediaItem)
        end
    end
    md.hifiTape.mediaItem = nil
    md.hifiTape.isPlaying = false
    if instanceof(self.device, "IsoObject") and self.device.transmitModData then
        self.device:transmitModData()
    end
end

function HiFiTimedAction:isValidTogglePlayCassette()
    local md = self.device:getModData()
    return self.deviceData:getIsTurnedOn() and deviceHasPower(self.device, self.deviceData)
        and md.hifiTape and md.hifiTape.mediaItem ~= nil
end

function HiFiTimedAction:performTogglePlayCassette()
    local valid = self:isValidTogglePlayCassette()
    local md = self.device:getModData()
    local isVeh = instanceof(self.device, "VehiclePart")
    audioDbg("[HIFIDBG][TogglePlayTape] valid=" .. tostring(valid) .. " isVehiclePart=" .. tostring(isVeh) .. " on=" .. tostring(self.deviceData:getIsTurnedOn()) .. " power=" .. tostring(self.deviceData:getPower()) .. " tape=" .. tostring(md.hifiTape and md.hifiTape.mediaItem) .. " wasPlaying=" .. tostring(md.hifiTape and md.hifiTape.isPlaying))
    if not valid then return end
    if md.hifiTape.isPlaying then
        md.hifiTape.isPlaying = false
        self:stopTapeAudio()
    else
        md.hifiTape.isPlaying = true
    end
    audioDbg("[HIFIDBG][TogglePlayTape] set isPlaying=" .. tostring(md.hifiTape.isPlaying))
    if instanceof(self.device, "IsoObject") and self.device.transmitModData then
        self.device:transmitModData()
    elseif isVeh then
        local v = self.device:getVehicle()
        if v and v.transmitPartModData then
            v:transmitPartModData(self.device)
            audioDbg("[HIFIDBG][TogglePlayTape] transmitPartModData vehId=" .. tostring(v:getId()))
        end
    end
end

--========================================================================
-- VINYL SLOT (TrueMusic vinyl system)
--========================================================================

function HiFiTimedAction:isValidAddVinyl()
    if not self.secondaryItem then return false end
    local md = self.device:getModData()
    md.hifiVinyl = md.hifiVinyl or {}
    if md.hifiVinyl.mediaItem then return false end
    local itemType = self.secondaryItem:getType()
    return GlobalMusic and GlobalMusic[itemType] ~= nil
end

function HiFiTimedAction:performAddVinyl()
    if not self:isValidAddVinyl() or not self.secondaryItem then return end
    local item = self.secondaryItem
    local container = item:getContainer()
    if not container then return end
    local md = self.device:getModData()
    md.hifiVinyl = md.hifiVinyl or {}
    md.hifiVinyl.mediaItem = item:getFullType()
    md.hifiVinyl.isPlaying = false
    container:DoRemoveItem(item)
    if instanceof(self.device, "IsoObject") and self.device.transmitModData then
        self.device:transmitModData()
    end
end

function HiFiTimedAction:isValidRemoveVinyl()
    local md = self.device:getModData()
    return md.hifiVinyl and md.hifiVinyl.mediaItem ~= nil
end

function HiFiTimedAction:performRemoveVinyl()
    if not self:isValidRemoveVinyl() or not self.character:getInventory() then return end
    local md = self.device:getModData()
    if md.hifiVinyl.isPlaying then
        md.hifiVinyl.isPlaying = false
        self:stopVinylAudio()
    end
    local mediaItem = md.hifiVinyl.mediaItem
    if mediaItem then
        local inv = self.character:getInventory()
        if inv and inv.AddItem then
            inv:AddItem(mediaItem)
        end
    end
    md.hifiVinyl.mediaItem = nil
    md.hifiVinyl.isPlaying = false
    if instanceof(self.device, "IsoObject") and self.device.transmitModData then
        self.device:transmitModData()
    end
end

function HiFiTimedAction:isValidTogglePlayVinyl()
    local md = self.device:getModData()
    return self.deviceData:getIsTurnedOn() and deviceHasPower(self.device, self.deviceData)
        and md.hifiVinyl and md.hifiVinyl.mediaItem ~= nil
end

function HiFiTimedAction:performTogglePlayVinyl()
    if not self:isValidTogglePlayVinyl() then return end
    local md = self.device:getModData()
    if md.hifiVinyl.isPlaying then
        md.hifiVinyl.isPlaying = false
        self:stopVinylAudio()
    else
        md.hifiVinyl.isPlaying = true
    end
    if instanceof(self.device, "IsoObject") and self.device.transmitModData then
        self.device:transmitModData()
    elseif instanceof(self.device, "VehiclePart") then
        local v = self.device:getVehicle()
        if v and v.transmitPartModData then v:transmitPartModData(self.device) end
    end
end

--========================================================================
-- VOLUME / HEADPHONES
--========================================================================

function HiFiTimedAction:isValidSetVolume()
    if not self.secondaryItem or type(self.secondaryItem) ~= "number" then return false end
    return self.deviceData:getIsTurnedOn() and deviceHasPower(self.device, self.deviceData)
end

function HiFiTimedAction:performSetVolume()
    if not self:isValidSetVolume() then return end
    self.deviceData:setDeviceVolume(self.secondaryItem)
end

function HiFiTimedAction:isValidAddHeadphones()
    return self.deviceData:getHeadphoneType() < 0
end

function HiFiTimedAction:performAddHeadphones()
    if not self:isValidAddHeadphones() or not self.secondaryItem then return end
    self.deviceData:addHeadphones(self.secondaryItem)
end

function HiFiTimedAction:isValidRemoveHeadphones()
    return self.deviceData:getHeadphoneType() >= 0
end

function HiFiTimedAction:performRemoveHeadphones()
    if not self:isValidRemoveHeadphones() then return end
    if self.character:getInventory() then
        self.deviceData:getHeadphones(self.character:getInventory())
    end
end

--========================================================================
-- CD HELPERS
--========================================================================

function HiFiTimedAction:isCustomCD(item)
    if not item then return false end
    if not SWTCCDAlbums then return false end
    local itemType = item:getType()
    return SWTCCDAlbums[itemType] ~= nil
end

function HiFiTimedAction:getCDData(itemType)
    if not itemType or not SWTCCDAlbums then return nil end
    local albumData = SWTCCDAlbums[itemType]
    if albumData then
        return {
            displayName = albumData.displayName,
            tracks = albumData.tracks,
            totalTracks = albumData.totalTracks,
        }
    end
    return nil
end

function HiFiTimedAction:getItemFullType(itemType)
    if not itemType then return nil end
    -- Prefer ScriptManager (searches every loaded module). SWTCCDAlbums'
    -- fullItemType metadata can point to the wrong module (e.g. the sound
    -- module CD_CustomMusic rather than the real item module TM_CDTEST).
    local sm = getScriptManager and getScriptManager() or nil
    if sm and sm.FindItem then
        local scriptItem = sm:FindItem(itemType)
        if scriptItem then
            if scriptItem.getFullName then return scriptItem:getFullName() end
            if scriptItem.getModuleName and scriptItem.getName then
                return scriptItem:getModuleName() .. "." .. scriptItem:getName()
            end
        end
    end
    if SWTCCDAlbums and SWTCCDAlbums[itemType] and SWTCCDAlbums[itemType].fullItemType then
        local ft = SWTCCDAlbums[itemType].fullItemType
        if sm and sm.getItem and sm:getItem(ft) then return ft end
    end
    local modId = string.match(itemType, "^([^_]+)_")
    if modId then return modId .. "_CustomMusic." .. itemType end
    return "Base." .. itemType
end

function HiFiTimedAction:getDeviceId()
    if not self.device then return nil end
    if instanceof(self.device, "InventoryItem") then
        return "hifi_item_" .. self.device:getID()
    elseif instanceof(self.device, "IsoObject") then
        return "hifi_world_" .. self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
    elseif instanceof(self.device, "VehiclePart") then
        local v = self.device:getVehicle()
        if v then return "hifi_vehicle_" .. v:getId() end
    end
    return "hifi_default_" .. tostring(self.device)
end

--========================================================================
-- AUDIO STOP HELPERS
--========================================================================

function HiFiTimedAction:stopCDAudio()
    if instanceof(self.device, "IsoObject") and HiFiWorldAudio then
        local key = self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
        local state = HiFiWorldAudio.objects[key]
        if state then
            if state.cdSound and state.cdEmitter then
                state.cdEmitter:stopSound(state.cdSound)
            end
            state.cdSound   = nil
            state.cdEmitter  = nil
        end
        return
    end
    local deviceId = self:getDeviceId() .. "_cd"
    if self.character:getModData().customMusicIds and self.character:getModData().customMusicIds[deviceId] then
        self.character:getEmitter():stopSound(self.character:getModData().customMusicIds[deviceId])
        self.character:getModData().customMusicIds[deviceId] = nil
    end
end

function HiFiTimedAction:stopTapeAudio()
    if instanceof(self.device, "IsoObject") and HiFiWorldAudio then
        local key = self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
        local state = HiFiWorldAudio.objects[key]
        if state then
            if state.tapeSound and state.tapeEmitter then
                state.tapeEmitter:stopSound(state.tapeSound)
            end
            state.tapeSound   = nil
            state.tapeEmitter  = nil
        end
        return
    end
    local deviceId = self:getDeviceId() .. "_tape"
    if self.character:getModData().customMusicIds and self.character:getModData().customMusicIds[deviceId] then
        self.character:getEmitter():stopSound(self.character:getModData().customMusicIds[deviceId])
        self.character:getModData().customMusicIds[deviceId] = nil
    end
end

function HiFiTimedAction:stopVinylAudio()
    if instanceof(self.device, "IsoObject") and HiFiWorldAudio then
        local key = self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
        local state = HiFiWorldAudio.objects[key]
        if state then
            if state.vinylSound and state.vinylEmitter then
                state.vinylEmitter:stopSound(state.vinylSound)
            end
            state.vinylSound   = nil
            state.vinylEmitter  = nil
        end
        return
    end
    local deviceId = self:getDeviceId() .. "_vinyl"
    if self.character:getModData().customMusicIds and self.character:getModData().customMusicIds[deviceId] then
        self.character:getEmitter():stopSound(self.character:getModData().customMusicIds[deviceId])
        self.character:getModData().customMusicIds[deviceId] = nil
    end
end

--========================================================================
-- CONSTRUCTOR
--========================================================================

function HiFiTimedAction:new(mode, character, device, secondaryItem)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.mode = mode
    o.character = character
    o.device = device
    o.deviceData = device and device:getDeviceData()
    o.secondaryItem = secondaryItem
    o.stopOnWalk = false
    o.stopOnRun = true
    o.maxTime = 30
    return o
end
