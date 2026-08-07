
require "RadioCom/RadioWindowModules/RWMPanel"
-- ISVolumeBar / ISItemDropBox are vanilla globals by mod load time; require paths fail in B42 (WARN spam).
require "RadioCom/ISUIRadio/ISSpeakerButton"
require "TimedActions/SWTCPlayerAction"

SWTCRWMVolume = RWMPanel:derive("SWTCRWMVolume");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6
local UI_BORDER_SPACING = 10

function SWTCRWMVolume:initialise()
    ISPanel.initialise(self)
end

function SWTCRWMVolume:createChildren()
    RWMPanel.createChildren(self);
    
    self.speakerButton = ISSpeakerButton:new (UI_BORDER_SPACING+1, UI_BORDER_SPACING+1, BUTTON_HGT, BUTTON_HGT, SWTCRWMVolume.onSpeakerButton, self);
    self.speakerButton:initialise();
    self:addChild(self.speakerButton);

    self.volumeBar = ISVolumeBar:new(self.speakerButton:getRight()+UI_BORDER_SPACING, UI_BORDER_SPACING+1, self.width-(self.speakerButton:getRight()+UI_BORDER_SPACING*3)-BUTTON_HGT, BUTTON_HGT, SWTCRWMVolume.onVolumeChange, self);
    self.volumeBar:initialise();
    self.volumeBar:setVolumeSteps(10);
    self:addChild(self.volumeBar);

    self.itemDropBox = ISItemDropBox:new(self.volumeBar:getRight()+UI_BORDER_SPACING, UI_BORDER_SPACING+1, BUTTON_HGT, BUTTON_HGT, false, self, SWTCRWMVolume.addHeadphone, SWTCRWMVolume.removeHeadphone, SWTCRWMVolume.verifyItem, nil );
    self.itemDropBox:initialise();
    self.itemDropBox:setBackDropTex( getTexture("Item_Headphones"), 0.4, 1,1,1 );
    self.itemDropBox:setDoBackDropTex( true );
    self.itemDropBox:setToolTip( true, getText("IGUI_RadioDragHeadphones") );
    
    self.hasEnabledHeadphones = false;

    if isClient() then
        self.clientVolBox = ISTickBox:new(self.volumeBar:getX(), self.itemDropBox:getBottom()+4, 18, 18, "", self, SWTCRWMVolume.onClientVolumeToggle);
        self.clientVolBox:initialise();
        self.clientVolBox:addOption(getText("IGUI_TCClientVolume"));
        self.clientVolBox.tooltip = getText("IGUI_TCClientVolume_Tooltip");
        self.clientVolBox.selected[1] = false;
        self:addChild(self.clientVolBox);
        self:setHeight(self.clientVolBox:getBottom()+UI_BORDER_SPACING);
    else
        self:setHeight(self.itemDropBox:getBottom()+UI_BORDER_SPACING);
    end
end

function SWTCRWMVolume:clientVolKey()
    return TCMusic.getClientVolumeKeyFor and TCMusic.getClientVolumeKeyFor(self.device, self.deviceType) or nil
end

function SWTCRWMVolume:onClientVolumeToggle(index, selected)
    local key = self:clientVolKey()
    if not key then return end
    if selected then
        TCMusic.setClientVolume(key, (self.deviceData and self.deviceData:getDeviceVolume()) or 1.0)
    else
        TCMusic.setClientVolume(key, nil)
    end
    if TCMusic.applyClientVolumeToOwnDevice then
        TCMusic.applyClientVolumeToOwnDevice(self.player or getPlayer(), self.deviceData, key)
    end
end

function SWTCRWMVolume:addHeadphone( _items )
    if _items and #_items > 0 then
        if self:doWalkTo() then
            ISTimedActionQueue.add(SWTCPlayerAction:new("AddHeadphones", self.player, self.device, _items[1]));
        end
    end
end

function SWTCRWMVolume:removeHeadphone()
    if self:doWalkTo() then
        ISTimedActionQueue.add(SWTCPlayerAction:new("RemoveHeadphones", self.player, self.device));
    end
end

function SWTCRWMVolume:verifyItem(_item)
    if _item:getFullType() == "Base.Headphones" or _item:getFullType() == "Base.Earbuds" then
        return true;
    end
end

function SWTCRWMVolume:round(num, idp)
    local mult = 10^(idp or 0);
    return math.floor(num * mult + 0.5) / mult;
end

function SWTCRWMVolume:onVolumeChange( _newVol )
    self.volume = _newVol/self.volumeBar:getVolumeSteps();
    local cvKey = self:clientVolKey()
    if cvKey and TCMusic.isClientVolumeActive and TCMusic.isClientVolumeActive(cvKey) then
        -- Local mode for THIS device only.
        TCMusic.setClientVolume(cvKey, self.volume)
        if TCMusic.applyClientVolumeToOwnDevice then
            TCMusic.applyClientVolumeToOwnDevice(self.player or getPlayer(), self.deviceData, cvKey)
        end
        return
    end
    if self.deviceData then
        if self:doWalkTo() then
            ISTimedActionQueue.add(SWTCPlayerAction:new("SetVolume", self.player, self.device, self.volume));
        end
    end
end

function SWTCRWMVolume:onSpeakerButton( _ismute )
    self.isMute = _ismute;
    if self.isMute == true then
        if self.deviceData then
            if self:doWalkTo() then
                ISTimedActionQueue.add(SWTCPlayerAction:new("SetVolume", self.player, self.device, 0));
            end
        end
        self.volumeBar:setEnableControls(false);
    else
        if self.deviceData then
            if self:doWalkTo() then
                ISTimedActionQueue.add(SWTCPlayerAction:new("SetVolume", self.player, self.device, self.volume~=0 and self.volume or 0.1));
            end
        end
        self.volumeBar:setEnableControls(true);
    end
end

function SWTCRWMVolume:clear()
    RWMPanel.clear(self);
end

function SWTCRWMVolume:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
    RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType );
    self.volume = self.deviceData:getDeviceVolume();
    self.volumeBar:setVolume(math.floor(self.volume*self.volumeBar:getVolumeSteps()));
    if self.deviceData:getIsPortable() and self.deviceData:getIsTelevision()==false then
        self:toggleHeaphoneSupport(true);
    else
        self:toggleHeaphoneSupport(false);
    end

    if self.player then
        self.itemDropBox.mouseEnabled = true;
        self.volumeBar.mouseEnabled = true;
        if JoypadState.players[self.player:getPlayerNum()+1] then
            self.itemDropBox.mouseEnabled = false;
            self.volumeBar.mouseEnabled = false;
        end
    end

    return true;
end

function SWTCRWMVolume:update()
    ISPanel.update(self);

    local cvKey = self:clientVolKey()
    local cvActive = cvKey and TCMusic.isClientVolumeActive and TCMusic.isClientVolumeActive(cvKey) or false
    if self.clientVolBox then
        self.clientVolBox.selected[1] = cvActive
    end
    if cvActive then
        -- Local mode: the slider shows/controls this device's local volume.
        self.speakerButton:setEnableControls(true);
        self.volumeBar:setEnableControls(true);
        self.volumeBar:setVolume(math.floor(((TCMusic.getClientVolume(cvKey) or 1.0) + 0.05) * self.volumeBar:getVolumeSteps()));
        if self.deviceData then
            if self.deviceData:getHeadphoneType() >= 0 then
                if self.deviceData:getHeadphoneType() == 0 then
                    self.itemDropBox:setStoredItemFake( self.headphonesTex );
                elseif self.deviceData:getHeadphoneType() == 1 then
                    self.itemDropBox:setStoredItemFake( self.earbudsTex );
                end
            else
                self.itemDropBox:setStoredItemFake( nil );
            end
        end
        return
    end

    if self.deviceData then
        self.speakerButton:setEnableControls(self.deviceData:getIsTurnedOn());
        self.speakerButton.isMute = self.deviceData:getDeviceVolume()<=0;
        self.volumeBar:setEnableControls(self.deviceData:getIsTurnedOn() and not self.speakerButton.isMute);
        local devVol = self.deviceData:getDeviceVolume()+0.05;
        self.volumeBar:setVolume(math.floor(devVol*self.volumeBar:getVolumeSteps()));

        if self.deviceData:getHeadphoneType() >= 0 then
            if self.deviceData:getHeadphoneType() == 0 then
                self.itemDropBox:setStoredItemFake( self.headphonesTex );
            elseif self.deviceData:getHeadphoneType() == 1 then
                self.itemDropBox:setStoredItemFake( self.earbudsTex );
            end
        else
            self.itemDropBox:setStoredItemFake( nil );
        end
    end
end

function SWTCRWMVolume:prerender()
    ISPanel.prerender(self);
end

function SWTCRWMVolume:render()
    ISPanel.render(self);
end

function SWTCRWMVolume:onJoypadDown(button)
    if button == Joypad.AButton then
        self.volumeBar:setVolumeJoypad(true)
    elseif button == Joypad.BButton then
        self.volumeBar:setVolumeJoypad(false)
    elseif button == Joypad.XButton then
        if self.deviceData:getHeadphoneType() >= 0 then
            self:removeHeadphone();
        else
            local tab = {};
            local inventory = self.player:getInventory();
            local list = inventory:FindAll("Base.Headphones");
            if list and list:size()>0 then
                for i=0,list:size()-1 do
                    table.insert(tab, list:get(i));
                end
            end
            list = inventory:FindAll("Base.Earbuds");
            if list and list:size()>0 then
                for i=0,list:size()-1 do
                    table.insert(tab, list:get(i));
                end
            end
            self:addHeadphone( tab );
        end
    elseif button == Joypad.YButton then
        self:onSpeakerButton( not self.speakerButton.isMute );
    end
end

function SWTCRWMVolume:getAPrompt()
    return getText("IGUI_RadioVolUp");
end

function SWTCRWMVolume:getBPrompt()
    return getText("IGUI_RadioVolDown");
end

function SWTCRWMVolume:getXPrompt()
    if self.deviceData:getHeadphoneType() >= 0 then
        return getText("IGUI_RadioRemoveHeadphones");
    else
        local has = false;
        local inventory = self.player:getInventory();
        local list = inventory:FindAll("Base.Headphones");
        if list and list:size()>0 then has = true; end
        if not has then
            list = inventory:FindAll("Base.Earbuds");
            if list and list:size()>0 then has = true; end
        end
        if has then
            return getText("IGUI_RadioAddHeadphones");
        end
    end
    return nil
end

function SWTCRWMVolume:getYPrompt()
    if self.speakerButton.isMute then
        return getText("IGUI_RadioUnmuteSpeaker");
    else
        return getText("IGUI_RadioMuteSpeaker");
    end
end

function SWTCRWMVolume:toggleHeaphoneSupport(enable)
    if self.hasEnabledHeadphones ~= enable then
        if not enable then
            self.volumeBar:setWidth(self.width - BUTTON_HGT - UI_BORDER_SPACING*3 - 2);
            self:removeChild(self.itemDropBox);
        else
            self.volumeBar:setWidth(self.width-(self.speakerButton:getRight()+UI_BORDER_SPACING*3)-BUTTON_HGT);
            self:addChild(self.itemDropBox);
        end
    end
    self.hasEnabledHeadphones = enable;
end

function SWTCRWMVolume:new (x, y, width, height)
    local o = RWMPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.background = true;
    o.backgroundColor = {r=0, g=0, b=0, a=0.0};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.width = width;
    o.height = height;
    o.anchorLeft = true;
    o.anchorRight = false;
    o.anchorTop = true;
    o.anchorBottom = false;
    o.isMute = false;
    o.volume = 6;
    o.headphonesTex = getTexture("Item_Headphones");
    o.earbudsTex = getTexture("Item_Earbuds");
    return o
end 