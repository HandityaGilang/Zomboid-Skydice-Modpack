require "ISUI/ISPanel"
require "ISUI/ISVolumeBar"
require "ISUI/ISItemDropBox"
require "RadioCom/ISUIRadio/ISSpeakerButton"
require "TimedActions/HiFiTimedAction"

HiFiVolumePanel = ISPanel:derive("HiFiVolumePanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6
local UI_BORDER_SPACING = 10

function HiFiVolumePanel:initialise()
    ISPanel.initialise(self)
end

function HiFiVolumePanel:createChildren()
    self.speakerButton = ISSpeakerButton:new(UI_BORDER_SPACING+1, UI_BORDER_SPACING+1, BUTTON_HGT, BUTTON_HGT, HiFiVolumePanel.onSpeakerButton, self)
    self.speakerButton:initialise()
    self:addChild(self.speakerButton)

    self.volumeBar = ISVolumeBar:new(self.speakerButton:getRight()+UI_BORDER_SPACING, UI_BORDER_SPACING+1,
        self.width-(self.speakerButton:getRight()+UI_BORDER_SPACING*3)-BUTTON_HGT, BUTTON_HGT,
        HiFiVolumePanel.onVolumeChange, self)
    self.volumeBar:initialise()
    self.volumeBar:setVolumeSteps(10)
    self:addChild(self.volumeBar)

    self.itemDropBox = ISItemDropBox:new(self.volumeBar:getRight()+UI_BORDER_SPACING, UI_BORDER_SPACING+1,
        BUTTON_HGT, BUTTON_HGT, false, self,
        HiFiVolumePanel.addHeadphone, HiFiVolumePanel.removeHeadphone, HiFiVolumePanel.verifyHeadphone, nil)
    self.itemDropBox:initialise()
    self.itemDropBox:setBackDropTex(getTexture("Item_Headphones"), 0.4, 1, 1, 1)
    self.itemDropBox:setDoBackDropTex(true)
    self.itemDropBox:setToolTip(true, getText("IGUI_RadioDragHeadphones"))
    self:addChild(self.itemDropBox)

    self:setHeight(self.itemDropBox:getBottom() + UI_BORDER_SPACING)
end

function HiFiVolumePanel:addHeadphone(_items)
    if _items and #_items > 0 and self.player and self.device then
        ISTimedActionQueue.add(HiFiTimedAction:new("AddHeadphones", self.player, self.device, _items[1]))
    end
end

function HiFiVolumePanel:removeHeadphone()
    if self.player and self.device then
        ISTimedActionQueue.add(HiFiTimedAction:new("RemoveHeadphones", self.player, self.device))
    end
end

function HiFiVolumePanel:verifyHeadphone(_item)
    return _item:getFullType() == "Base.Headphones" or _item:getFullType() == "Base.Earbuds"
end

function HiFiVolumePanel:onVolumeChange(_newVol)
    self.volume = _newVol / self.volumeBar:getVolumeSteps()
    if self.deviceData and self.player and self.device then
        ISTimedActionQueue.add(HiFiTimedAction:new("SetVolume", self.player, self.device, self.volume))
    end
end

function HiFiVolumePanel:onSpeakerButton(_ismute)
    self.isMute = _ismute
    if self.isMute then
        if self.player and self.device then
            ISTimedActionQueue.add(HiFiTimedAction:new("SetVolume", self.player, self.device, 0))
        end
        self.volumeBar:setEnableControls(false)
    else
        if self.player and self.device then
            local vol = self.volume ~= 0 and self.volume or 0.1
            ISTimedActionQueue.add(HiFiTimedAction:new("SetVolume", self.player, self.device, vol))
        end
        self.volumeBar:setEnableControls(true)
    end
end

function HiFiVolumePanel:clear()
    self.player = nil
    self.device = nil
    self.deviceData = nil
end

function HiFiVolumePanel:readFromObject(_player, _device, _deviceData, _deviceType)
    self.player = _player
    self.device = _device
    self.deviceData = _deviceData
    self.deviceType = _deviceType
    self.volume = self.deviceData:getDeviceVolume()
    self.volumeBar:setVolume(math.floor(self.volume * self.volumeBar:getVolumeSteps()))
    if self.player then
        self.itemDropBox.mouseEnabled = true
    end
    return true
end

function HiFiVolumePanel:update()
    ISPanel.update(self)
    if self.deviceData then
        self.speakerButton:setEnableControls(self.deviceData:getIsTurnedOn())
        self.speakerButton.isMute = self.deviceData:getDeviceVolume() <= 0
        self.volumeBar:setEnableControls(self.deviceData:getIsTurnedOn() and not self.speakerButton.isMute)
        local devVol = self.deviceData:getDeviceVolume() + 0.05
        self.volumeBar:setVolume(math.floor(devVol * self.volumeBar:getVolumeSteps()))

        if self.deviceData:getHeadphoneType() >= 0 then
            if self.deviceData:getHeadphoneType() == 0 then
                self.itemDropBox:setStoredItemFake(getTexture("Item_Headphones"))
            elseif self.deviceData:getHeadphoneType() == 1 then
                self.itemDropBox:setStoredItemFake(getTexture("Item_Earbuds"))
            end
        else
            self.itemDropBox:setStoredItemFake(nil)
        end
    end
end

function HiFiVolumePanel:prerender()
    ISPanel.prerender(self)
end

function HiFiVolumePanel:render()
    ISPanel.render(self)
end

function HiFiVolumePanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height or 0)
    setmetatable(o, self)
    self.__index = self
    o.background = true
    o.backgroundColor = {r=0,g=0,b=0,a=0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.volume = 0.5
    o.isMute = false
    return o
end
