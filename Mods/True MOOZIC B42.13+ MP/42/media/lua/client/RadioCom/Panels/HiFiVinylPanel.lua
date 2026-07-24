require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISItemDropBox"
require "RadioCom/HiFiLcdBar"
require "TimedActions/HiFiTimedAction"
require "TCMusicDefenitions"

HiFiVinylPanel = ISPanel:derive("HiFiVinylPanel")

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

function HiFiVinylPanel:initialise()
    ISPanel.initialise(self)
end

function HiFiVinylPanel:createChildren()
    local y = UI_BORDER_SPACING + 1
    local charW = getCore():getOptionFontSizeReal() >= 4 and 21 or 14
    local lcdCharWidth = math.floor((self:getWidth() - UI_BORDER_SPACING * 2 - 2) / charW)
    local lcdw = lcdCharWidth * charW
    local x = ((self:getWidth() / 2) - (lcdw / 2)) - 2

    self.lcd = HiFiLcdBar:new(x, y, lcdCharWidth)
    self.lcd:initialise()
    self.lcd.ledColor = {r=0.8, g=0.6, b=0.2, a=1.0}
    self.lcd.ledTextColor = {r=0.2, g=0.15, b=0.05, a=1.0}
    self:addChild(self.lcd)

    y = self.lcd:getY() + self.lcd:getHeight() + UI_BORDER_SPACING

    local unitWidth = math.floor(lcdw / 3)

    self.itemDropBox = ISItemDropBox:new(x, y, BUTTON_HGT, BUTTON_HGT, false, self,
        HiFiVinylPanel.onAddVinyl, HiFiVinylPanel.onRemoveVinyl,
        HiFiVinylPanel.verifyVinylItem, nil)
    self.itemDropBox:initialise()
    local vinylTex = getTexture("media/textures/UI/TCVinylrecord.png") or getTexture("Item_Disc")
    self.itemDropBox:setBackDropTex(vinylTex, 0.4, 1, 1, 1)
    self.itemDropBox:setDoBackDropTex(true)
    self.itemDropBox:setToolTip(true, "Drag a Vinyl here")
    self:addChild(self.itemDropBox)

    local bw = math.floor(unitWidth * 0.8)
    self.playBtn = ISButton:new(x + unitWidth + (unitWidth - bw)/2, y, bw, BUTTON_HGT,
        getText("ContextMenu_Turn_On"), self, HiFiVinylPanel.onTogglePlay)
    self.playBtn:initialise()
    self.playBtn.backgroundColor = {r=0,g=0,b=0,a=0}
    self.playBtn.backgroundColorMouseOver = {r=1,g=1,b=1,a=0.2}
    self.playBtn.borderColor = {r=0,g=0,b=0,a=0}
    self:addChild(self.playBtn)

    y = self.playBtn:getY() + self.playBtn:getHeight() + UI_BORDER_SPACING + 1
    self:setHeight(y)
end

function HiFiVinylPanel:onAddVinyl(_items)
    if not _items or #_items == 0 then return end
    if not self.player or not self.device then return end
    ISTimedActionQueue.add(HiFiTimedAction:new("AddVinyl", self.player, self.device, _items[1]))
end

function HiFiVinylPanel:onRemoveVinyl()
    if not self.player or not self.device then return end
    ISTimedActionQueue.add(HiFiTimedAction:new("RemoveVinyl", self.player, self.device))
end

function HiFiVinylPanel:verifyVinylItem(_item)
    if not _item then return false end
    local itemType = _item:getType()
    -- Accept items whose GlobalMusic mapping points to the vinyl music player
    if GlobalMusic and GlobalMusic[itemType] then
        local mapped = GlobalMusic[itemType]
        return mapped == (TCMusic and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayer"])
            or mapped == "tsarcraft_music_01_63"
    end
    return false
end

function HiFiVinylPanel:onTogglePlay()
    if not self.player or not self.device then return end
    ISTimedActionQueue.add(HiFiTimedAction:new("TogglePlayVinyl", self.player, self.device))
end

function HiFiVinylPanel:getDeviceId()
    if not self.device then return nil end
    if instanceof(self.device, "IsoObject") then
        return "hifi_world_" .. self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ() .. "_vinyl"
    end
    return "hifi_vinyl"
end

function HiFiVinylPanel:stopAudio()
    if self.deviceType == "IsoObject" then
        if HiFiWorldAudio and instanceof(self.device, "IsoObject") then
            local key = self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
            local state = HiFiWorldAudio.objects[key]
            if state then
                if state.vinylSound and state.vinylEmitter then
                    state.vinylEmitter:stopSound(state.vinylSound)
                end
                state.vinylSound   = nil
                state.vinylEmitter  = nil
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

function HiFiVinylPanel:playAudio()
    if self.deviceType == "IsoObject" then return true end  -- world tick handler manages
    local md = self.device:getModData()
    if not md.hifiVinyl or not md.hifiVinyl.mediaItem then return false end
    local soundName = TCMusic.getSoundName and TCMusic.getSoundName(md.hifiVinyl.mediaItem) or md.hifiVinyl.mediaItem
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

function HiFiVinylPanel:getMediaDisplayName()
    local md = self.device:getModData()
    if md.hifiVinyl and md.hifiVinyl.mediaItem then
        local item = instanceItem(md.hifiVinyl.mediaItem)
        if item then return item:getDisplayName() end
        return md.hifiVinyl.mediaItem
    end
    return nil
end

function HiFiVinylPanel:update()
    ISPanel.update(self)
    if not self.player or not self.device or not self.deviceData then return end
    local md = self.device:getModData()
    local isOn = self.deviceData:getIsTurnedOn()
    local hasVinyl = md.hifiVinyl and md.hifiVinyl.mediaItem ~= nil
    local canUse = hasVinyl and isOn

    self.lcd:toggleOn(isOn)
    self.playBtn:setEnable(canUse)

    if hasVinyl then
        local vinylTex = getTexture("media/textures/UI/TCVinylrecord.png") or getTexture("Item_Disc")
        self.itemDropBox:setStoredItemFake(vinylTex)
        if md.hifiVinyl.isPlaying then
            self.playBtn:setTitle("Stop")
            if self.deviceType ~= "IsoObject" then
                local did = self:getDeviceId()
                local pmd = self.player:getModData()
                if did and pmd.customMusicIds and pmd.customMusicIds[did] then
                    if not self.player:getEmitter():isPlaying(pmd.customMusicIds[did]) then
                        md.hifiVinyl.isPlaying = false
                        pmd.customMusicIds[did] = nil
                    end
                elseif md.hifiVinyl.isPlaying then
                    self:playAudio()
                end
            end
            local name = self:getMediaDisplayName() or "Vinyl"
            self.lcd:setText(name .. " ***")
            self.lcd:setDoScroll(true)
        else
            self.playBtn:setTitle("Play")
            self.lcd:setText("Vinyl Ready")
            self.lcd:setDoScroll(false)
        end
    else
        self.itemDropBox:setStoredItemFake(nil)
        self.playBtn:setTitle("Play")
        self.lcd:setText("No Vinyl")
        self.lcd:setDoScroll(false)
    end

    if not isOn and md.hifiVinyl and md.hifiVinyl.isPlaying then
        md.hifiVinyl.isPlaying = false
        self:stopAudio()
        if self.deviceType == "IsoObject" and self.device.transmitModData then
            self.device:transmitModData()
        end
    end
end

function HiFiVinylPanel:clear()
    self.player = nil
    self.device = nil
    self.deviceData = nil
end

function HiFiVinylPanel:readFromObject(_player, _device, _deviceData, _deviceType)
    self.player = _player
    self.device = _device
    self.deviceData = _deviceData
    self.deviceType = _deviceType
    if self.player then self.itemDropBox.mouseEnabled = true end
    return true
end

function HiFiVinylPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height or 0)
    setmetatable(o, self)
    self.__index = self
    o.background = true
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    return o
end
