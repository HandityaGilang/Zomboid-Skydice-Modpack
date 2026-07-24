require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISItemDropBox"
require "RadioCom/HiFiLcdBar"
require "TimedActions/HiFiTimedAction"

HiFiCDPanel = ISPanel:derive("HiFiCDPanel")

local function playPanelEmitterSound(playerObj, soundName)
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

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6
local UI_BORDER_SPACING = 10

function HiFiCDPanel:initialise()
    ISPanel.initialise(self)
end

function HiFiCDPanel:createChildren()
    local y = UI_BORDER_SPACING + 1
    local charW = getCore():getOptionFontSizeReal() >= 4 and 21 or 14
    local lcdCharWidth = math.floor((self:getWidth() - UI_BORDER_SPACING * 2 - 2) / charW)
    local lcdw = lcdCharWidth * charW
    local x = ((self:getWidth() / 2) - (lcdw / 2)) - 2

    self.lcd = HiFiLcdBar:new(x, y, lcdCharWidth)
    self.lcd:initialise()
    self.lcd.ledColor = {r=0.172, g=0.686, b=0.764, a=1.0}
    self.lcd.ledTextColor = {r=0.039, g=0.180, b=0.2, a=1.0}
    self:addChild(self.lcd)

    y = self.lcd:getY() + self.lcd:getHeight() + UI_BORDER_SPACING

    local unitWidth = math.floor(lcdw / 5)

    self.itemDropBox = ISItemDropBox:new(x, y, BUTTON_HGT, BUTTON_HGT, false, self,
        HiFiCDPanel.onAddCD, HiFiCDPanel.onRemoveCD, HiFiCDPanel.verifyCDItem, nil)
    self.itemDropBox:initialise()
    self.itemDropBox:setBackDropTex(getTexture("Item_Disc"), 0.4, 1, 1, 1)
    self.itemDropBox:setDoBackDropTex(true)
    self.itemDropBox:setToolTip(true, "Drag a CD here")
    self:addChild(self.itemDropBox)

    local bw = math.floor(unitWidth * 0.8)
    self.prevBtn = ISButton:new(x + unitWidth + (unitWidth - bw)/2, y, bw, BUTTON_HGT, "<<", self, HiFiCDPanel.onPrevTrack)
    self.prevBtn:initialise()
    self.prevBtn.backgroundColor = {r=0,g=0,b=0,a=0}
    self.prevBtn.backgroundColorMouseOver = {r=1,g=1,b=1,a=0.2}
    self.prevBtn.borderColor = {r=0,g=0,b=0,a=0}
    self:addChild(self.prevBtn)

    self.playBtn = ISButton:new(x + unitWidth*2 + (unitWidth - bw)/2, y, bw, BUTTON_HGT, getText("ContextMenu_Turn_On"), self, HiFiCDPanel.onTogglePlay)
    self.playBtn:initialise()
    self.playBtn.backgroundColor = {r=0,g=0,b=0,a=0}
    self.playBtn.backgroundColorMouseOver = {r=1,g=1,b=1,a=0.2}
    self.playBtn.borderColor = {r=0,g=0,b=0,a=0}
    self:addChild(self.playBtn)

    self.nextBtn = ISButton:new(x + unitWidth*3 + (unitWidth - bw)/2, y, bw, BUTTON_HGT, ">>", self, HiFiCDPanel.onNextTrack)
    self.nextBtn:initialise()
    self.nextBtn.backgroundColor = {r=0,g=0,b=0,a=0}
    self.nextBtn.backgroundColorMouseOver = {r=1,g=1,b=1,a=0.2}
    self.nextBtn.borderColor = {r=0,g=0,b=0,a=0}
    self:addChild(self.nextBtn)

    y = self.playBtn:getY() + self.playBtn:getHeight() + UI_BORDER_SPACING + 1
    self:setHeight(y)
end

function HiFiCDPanel:onAddCD(_items)
    if not _items or #_items == 0 then return end
    if not self.player or not self.device then return end
    ISTimedActionQueue.add(HiFiTimedAction:new("AddCD", self.player, self.device, _items[1]))
end

function HiFiCDPanel:onRemoveCD()
    if not self.player or not self.device then return end
    ISTimedActionQueue.add(HiFiTimedAction:new("RemoveCD", self.player, self.device))
end

function HiFiCDPanel:verifyCDItem(_item)
    if not _item or not SWTCCDAlbums then return false end
    return SWTCCDAlbums[_item:getType()] ~= nil
end

function HiFiCDPanel:onTogglePlay()
    if not self.player or not self.device then return end
    ISTimedActionQueue.add(HiFiTimedAction:new("TogglePlayCD", self.player, self.device))
end

function HiFiCDPanel:onPrevTrack()
    local md = self.device and self.device:getModData() or nil
    if not md or not md.hifiCD or not md.hifiCD.tracks then return end
    local wasPlaying = md.hifiCD.isPlaying
    if wasPlaying then self:stopAudio() end
    md.hifiCD.currentTrack = md.hifiCD.currentTrack - 1
    if md.hifiCD.currentTrack < 1 then md.hifiCD.currentTrack = md.hifiCD.totalTracks end
    if wasPlaying then
        self:playAudio()
        self:resetVehicleAudioState()
    end
    if self.deviceType == "IsoObject" and self.device and self.device.transmitModData then
        self.device:transmitModData()
    end
end

function HiFiCDPanel:onNextTrack()
    local md = self.device and self.device:getModData() or nil
    if not md or not md.hifiCD or not md.hifiCD.tracks then return end
    local wasPlaying = md.hifiCD.isPlaying
    if wasPlaying then self:stopAudio() end
    md.hifiCD.currentTrack = md.hifiCD.currentTrack + 1
    if md.hifiCD.currentTrack > md.hifiCD.totalTracks then md.hifiCD.currentTrack = 1 end
    if wasPlaying then
        self:playAudio()
        self:resetVehicleAudioState()
    end
    if self.deviceType == "IsoObject" and self.device and self.device.transmitModData then
        self.device:transmitModData()
    end
end

-- When tracks change on a vehicle device, tell the tick handler to restart audio
function HiFiCDPanel:resetVehicleAudioState()
    if self.deviceType ~= "VehiclePart" or not HiFiVehicleAudio then return end
    local v = self.device:getVehicle()
    if not v then return end
    local vid = v:getId()
    local state = HiFiVehicleAudio.vehicles[vid]
    if state then
        if state.cdSound and state.cdEmitter then
            state.cdEmitter:stopSound(state.cdSound)
        end
        state.cdSound = nil
        state.cdEmitter = nil
    end
end

function HiFiCDPanel:getDeviceId()
    if not self.device then return nil end
    if instanceof(self.device, "IsoObject") then
        return "hifi_world_" .. self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ() .. "_cd"
    end
    if instanceof(self.device, "VehiclePart") then
        local v = self.device:getVehicle()
        if v then return "hifi_vehicle_" .. v:getId() .. "_cd" end
    end
    return "hifi_cd"
end

function HiFiCDPanel:stopAudio()
    if self.deviceType == "VehiclePart" then return end
    if self.deviceType == "IsoObject" then
        self:resetWorldAudioState()
        return
    end
    local did = self:getDeviceId()
    local pmd = self.player:getModData()
    if did and pmd.customMusicIds and pmd.customMusicIds[did] then
        self.player:getEmitter():stopSound(pmd.customMusicIds[did])
        pmd.customMusicIds[did] = nil
    end
end

function HiFiCDPanel:resetWorldAudioState()
    if not HiFiWorldAudio or not instanceof(self.device, "IsoObject") then return end
    local key = self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
    local state = HiFiWorldAudio.objects[key]
    if state then
        if state.cdSound and state.cdEmitter then
            state.cdEmitter:stopSound(state.cdSound)
        end
        state.cdSound   = nil
        state.cdEmitter  = nil
    end
end

function HiFiCDPanel:playAudio()
    if self.deviceType == "VehiclePart" then return true end
    if self.deviceType == "IsoObject" then return true end  -- world tick handler manages
    local md = self.device:getModData()
    if not md.hifiCD or not md.hifiCD.tracks then return false end
    local track = md.hifiCD.tracks[md.hifiCD.currentTrack]
    if not track or not track.soundName then return false end
    local did = self:getDeviceId()
    local pmd = self.player:getModData()
    if not pmd.customMusicIds then pmd.customMusicIds = {} end
    if pmd.customMusicIds[did] then
        self.player:getEmitter():stopSound(pmd.customMusicIds[did])
    end
    pmd.customMusicIds[did] = playPanelEmitterSound(self.player, track.soundName)
    if pmd.customMusicIds[did] then
        local vol = self.deviceData:getDeviceVolume() * 0.4
        self.player:getEmitter():setVolume(pmd.customMusicIds[did], vol)
        return true
    end
    return false
end

function HiFiCDPanel:getCurrentTrackDisplayName()
    local md = self.device:getModData()
    if md.hifiCD and md.hifiCD.tracks and md.hifiCD.currentTrack then
        local idx = md.hifiCD.currentTrack
        local t = md.hifiCD.tracks[idx]
        if t and t.displayName then
            local raw = t.displayName
            if string.match(raw, "^IGUI_") then
                local translated = getTextOrNull(raw)
                if translated then return translated end
                return (getTextOrNull("IGUI_TM_Track") or "Track") .. " " .. tostring(idx)
            end
            return raw
        end
        return (getTextOrNull("IGUI_TM_Track") or "Track") .. " " .. tostring(idx)
    end
    return "Unknown"
end

function HiFiCDPanel:update()
    ISPanel.update(self)
    if not self.player or not self.device or not self.deviceData then return end
    local md = self.device:getModData()
    local isOn = self.deviceData:getIsTurnedOn()
    local hasCD = md.hifiCD and md.hifiCD.cdType ~= nil
    local canUse = hasCD and isOn

    self.lcd:toggleOn(isOn)
    self.playBtn:setEnable(canUse)
    self.prevBtn:setEnable(canUse)
    self.nextBtn:setEnable(canUse)

    if hasCD then
        self.itemDropBox:setStoredItemFake(getTexture("Item_Disc"))
        if md.hifiCD.isPlaying then
            self.playBtn:setTitle("Stop")
            -- For non-vehicle/non-world devices, manage audio in the panel
            if self.deviceType ~= "VehiclePart" and self.deviceType ~= "IsoObject" then
                local did = self:getDeviceId()
                local pmd = self.player:getModData()
                if did and pmd.customMusicIds and pmd.customMusicIds[did] then
                    if not self.player:getEmitter():isPlaying(pmd.customMusicIds[did]) then
                        if md.hifiCD.totalTracks and md.hifiCD.totalTracks > 1 then
                            md.hifiCD.currentTrack = md.hifiCD.currentTrack + 1
                            if md.hifiCD.currentTrack > md.hifiCD.totalTracks then md.hifiCD.currentTrack = 1 end
                            pmd.customMusicIds[did] = nil
                            self:playAudio()
                        else
                            md.hifiCD.isPlaying = false
                            pmd.customMusicIds[did] = nil
                        end
                    end
                elseif md.hifiCD.isPlaying then
                    self:playAudio()
                end
            end
            -- Vehicle audio is handled by HiFiVehicleTick
            local albumName = md.hifiCD.cdDisplayName or "CD"
            if string.match(albumName, "^IGUI_") then
                albumName = getTextOrNull(albumName) or "CD"
            end
            local trackName = self:getCurrentTrackDisplayName()
            self.lcd:setText(albumName .. " [" .. md.hifiCD.currentTrack .. "/" .. md.hifiCD.totalTracks .. "] - " .. trackName)
            self.lcd:setDoScroll(true)
        else
            self.playBtn:setTitle("Play")
            self.lcd:setText("CD Ready")
            self.lcd:setDoScroll(false)
        end
    else
        self.itemDropBox:setStoredItemFake(nil)
        self.playBtn:setTitle("Play")
        self.lcd:setText("No CD")
        self.lcd:setDoScroll(false)
    end

    if not isOn and md.hifiCD and md.hifiCD.isPlaying then
        md.hifiCD.isPlaying = false
        self:stopAudio()
        if self.deviceType == "IsoObject" and self.device.transmitModData then
            self.device:transmitModData()
        end
    end
end

function HiFiCDPanel:clear()
    self.player = nil
    self.device = nil
    self.deviceData = nil
end

function HiFiCDPanel:readFromObject(_player, _device, _deviceData, _deviceType)
    self.player = _player
    self.device = _device
    self.deviceData = _deviceData
    self.deviceType = _deviceType
    if self.player then
        self.itemDropBox.mouseEnabled = true
    end
    return true
end

function HiFiCDPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height or 0)
    setmetatable(o, self)
    self.__index = self
    o.background = true
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    return o
end
