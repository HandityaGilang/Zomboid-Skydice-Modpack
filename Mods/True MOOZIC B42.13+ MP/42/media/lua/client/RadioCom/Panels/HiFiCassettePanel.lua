require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISItemDropBox"
require "RadioCom/HiFiLcdBar"
require "TimedActions/HiFiTimedAction"
require "TCMusicDefenitions"

HiFiCassettePanel = ISPanel:derive("HiFiCassettePanel")

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

function HiFiCassettePanel:initialise()
    ISPanel.initialise(self)
end

function HiFiCassettePanel:createChildren()
    local y = UI_BORDER_SPACING + 1
    local charW = getCore():getOptionFontSizeReal() >= 4 and 21 or 14
    local lcdCharWidth = math.floor((self:getWidth() - UI_BORDER_SPACING * 2 - 2) / charW)
    local lcdw = lcdCharWidth * charW
    local x = ((self:getWidth() / 2) - (lcdw / 2)) - 2

    self.lcd = HiFiLcdBar:new(x, y, lcdCharWidth)
    self.lcd:initialise()
    self.lcd.ledColor = {r=0.2, g=0.8, b=0.2, a=1.0}
    self.lcd.ledTextColor = {r=0.05, g=0.2, b=0.05, a=1.0}
    self:addChild(self.lcd)

    y = self.lcd:getY() + self.lcd:getHeight() + UI_BORDER_SPACING

    local unitWidth = math.floor(lcdw / 3)

    self.itemDropBox = ISItemDropBox:new(x, y, BUTTON_HGT, BUTTON_HGT, false, self,
        HiFiCassettePanel.onAddCassette, HiFiCassettePanel.onRemoveCassette,
        HiFiCassettePanel.verifyCassetteItem, nil)
    self.itemDropBox:initialise()
    local tapeTex = getTexture("media/textures/UI/TCTape.png") or getTexture("Item_Battery")
    self.itemDropBox:setBackDropTex(tapeTex, 0.4, 1, 1, 1)
    self.itemDropBox:setDoBackDropTex(true)
    self.itemDropBox:setToolTip(true, "Drag a Cassette here")
    self:addChild(self.itemDropBox)

    local bw = math.floor(unitWidth * 0.8)
    self.playBtn = ISButton:new(x + unitWidth + (unitWidth - bw)/2, y, bw, BUTTON_HGT,
        getText("ContextMenu_Turn_On"), self, HiFiCassettePanel.onTogglePlay)
    self.playBtn:initialise()
    self.playBtn.backgroundColor = {r=0,g=0,b=0,a=0}
    self.playBtn.backgroundColorMouseOver = {r=1,g=1,b=1,a=0.2}
    self.playBtn.borderColor = {r=0,g=0,b=0,a=0}
    self:addChild(self.playBtn)

    y = self.playBtn:getY() + self.playBtn:getHeight() + UI_BORDER_SPACING + 1
    self:setHeight(y)
end

function HiFiCassettePanel:onAddCassette(_items)
    if not _items or #_items == 0 then return end
    if not self.player or not self.device then return end
    ISTimedActionQueue.add(HiFiTimedAction:new("AddCassette", self.player, self.device, _items[1]))
end

function HiFiCassettePanel:onRemoveCassette()
    if not self.player or not self.device then return end
    ISTimedActionQueue.add(HiFiTimedAction:new("RemoveCassette", self.player, self.device))
end

function HiFiCassettePanel:verifyCassetteItem(_item)
    if not _item then return false end
    local itemType = _item:getType()
    -- Accept items whose GlobalMusic mapping points to the cassette music player
    if GlobalMusic and GlobalMusic[itemType] then
        local mapped = GlobalMusic[itemType]
        return mapped == (TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer["Tsarcraft.TCBoombox"])
            or mapped == "tsarcraft_music_01_62"
    end
    return false
end

function HiFiCassettePanel:onTogglePlay()
    if not self.player or not self.device then return end
    ISTimedActionQueue.add(HiFiTimedAction:new("TogglePlayCassette", self.player, self.device))
end

function HiFiCassettePanel:getDeviceId()
    if not self.device then return nil end
    if instanceof(self.device, "IsoObject") then
        return "hifi_world_" .. self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ() .. "_tape"
    end
    if instanceof(self.device, "VehiclePart") then
        local v = self.device:getVehicle()
        if v then return "hifi_vehicle_" .. v:getId() .. "_tape" end
    end
    return "hifi_tape"
end

function HiFiCassettePanel:stopAudio()
    if self.deviceType == "VehiclePart" then return end
    if self.deviceType == "IsoObject" then
        if HiFiWorldAudio and instanceof(self.device, "IsoObject") then
            local key = self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
            local state = HiFiWorldAudio.objects[key]
            if state then
                if state.tapeSound and state.tapeEmitter then
                    state.tapeEmitter:stopSound(state.tapeSound)
                end
                state.tapeSound   = nil
                state.tapeEmitter  = nil
            end
        end
        return
    end
    local did = self:getDeviceId()
    local pmd = self.player:getModData()
    if did and pmd.customMusicIds and pmd.customMusicIds[did] then
        self.player:getEmitter():stopSound(pmd.customMusicIds[did])
        pmd.customMusicIds[did] = nil
    end
end

function HiFiCassettePanel:playAudio()
    if self.deviceType == "VehiclePart" then return true end
    if self.deviceType == "IsoObject" then return true end  -- world tick handler manages
    local md = self.device:getModData()
    if not md.hifiTape or not md.hifiTape.mediaItem then return false end
    local soundName = TCMusic.getSoundName and TCMusic.getSoundName(md.hifiTape.mediaItem) or md.hifiTape.mediaItem
    if not soundName then return false end
    local did = self:getDeviceId()
    local pmd = self.player:getModData()
    if not pmd.customMusicIds then pmd.customMusicIds = {} end
    if pmd.customMusicIds[did] then
        self.player:getEmitter():stopSound(pmd.customMusicIds[did])
    end
    pmd.customMusicIds[did] = playPanelEmitterSound(self.player, soundName)
    if pmd.customMusicIds[did] then
        local vol = self.deviceData:getDeviceVolume() * 0.4
        self.player:getEmitter():setVolume(pmd.customMusicIds[did], vol)
        return true
    end
    return false
end

function HiFiCassettePanel:getMediaDisplayName()
    local md = self.device:getModData()
    if md.hifiTape and md.hifiTape.mediaItem then
        local item = instanceItem(md.hifiTape.mediaItem)
        if item then return item:getDisplayName() end
        return md.hifiTape.mediaItem
    end
    return nil
end

function HiFiCassettePanel:update()
    ISPanel.update(self)
    if not self.player or not self.device or not self.deviceData then return end
    local md = self.device:getModData()
    local isOn = self.deviceData:getIsTurnedOn()
    local hasTape = md.hifiTape and md.hifiTape.mediaItem ~= nil
    local canUse = hasTape and isOn

    self.lcd:toggleOn(isOn)
    self.playBtn:setEnable(canUse)

    if hasTape then
        local tapeTex = getTexture("media/textures/UI/TCTape.png") or getTexture("Item_Battery")
        self.itemDropBox:setStoredItemFake(tapeTex)
        if md.hifiTape.isPlaying then
            self.playBtn:setTitle("Stop")
            -- For non-vehicle/non-world devices, manage audio in the panel
            if self.deviceType ~= "VehiclePart" and self.deviceType ~= "IsoObject" then
                local did = self:getDeviceId()
                local pmd = self.player:getModData()
                if did and pmd.customMusicIds and pmd.customMusicIds[did] then
                    if not self.player:getEmitter():isPlaying(pmd.customMusicIds[did]) then
                        md.hifiTape.isPlaying = false
                        pmd.customMusicIds[did] = nil
                    end
                elseif md.hifiTape.isPlaying then
                    self:playAudio()
                end
            end
            -- Vehicle audio is handled by HiFiVehicleTick
            local name = self:getMediaDisplayName() or "Cassette"
            self.lcd:setText(name .. " ***")
            self.lcd:setDoScroll(true)
        else
            self.playBtn:setTitle("Play")
            self.lcd:setText("Cassette Ready")
            self.lcd:setDoScroll(false)
        end
    else
        self.itemDropBox:setStoredItemFake(nil)
        self.playBtn:setTitle("Play")
        self.lcd:setText("No Cassette")
        self.lcd:setDoScroll(false)
    end

    if not isOn and md.hifiTape and md.hifiTape.isPlaying then
        md.hifiTape.isPlaying = false
        self:stopAudio()
        if self.deviceType == "IsoObject" and self.device.transmitModData then
            self.device:transmitModData()
        end
    end
end

function HiFiCassettePanel:clear()
    self.player = nil
    self.device = nil
    self.deviceData = nil
end

function HiFiCassettePanel:readFromObject(_player, _device, _deviceData, _deviceType)
    self.player = _player
    self.device = _device
    self.deviceData = _deviceData
    self.deviceType = _deviceType
    if self.player then self.itemDropBox.mouseEnabled = true end
    return true
end

function HiFiCassettePanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height or 0)
    setmetatable(o, self)
    self.__index = self
    o.background = true
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    return o
end
