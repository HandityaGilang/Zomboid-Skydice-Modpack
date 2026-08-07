require "RadioCom/RadioWindowModules/RWMPanel"

TCRWMGridPower = RWMPanel:derive("TCRWMGridPower");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function TCRWMGridPower:initialise()
    ISPanel.initialise(self)
end

function TCRWMGridPower:createChildren()
    self:setHeight(32);

    local xoff = 0;

    self.led = ISLedLight:new (10, (self.height-10)/2, 10, 10);
    self.led:initialise();
    self.led:setLedColor( 1, 0, 1, 0 );
    self.led:setLedColorOff( 1, 0, 0.3, 0 );
    self:addChild(self.led);

    xoff = self.led:getX() + self.led:getWidth();

    local buttonW = getTextManager():MeasureStringX(UIFont.Small, getText("ContextMenu_Turn_Off"))+10;
    self.toggleOnOffButton = ISButton:new(xoff+10, 4, buttonW,self.height-8,getText("ContextMenu_Turn_On"),self, TCRWMGridPower.toggleOnOff);
    self.toggleOnOffButton:initialise();
    self.toggleOnOffButton.backgroundColor = {r=0, g=0, b=0, a=0.0};
    self.toggleOnOffButton.backgroundColorMouseOver = {r=1.0, g=1.0, b=1.0, a=0.1};
    self.toggleOnOffButton.borderColor = {r=1.0, g=1.0, b=1.0, a=0.3};
    self:addChild(self.toggleOnOffButton);
end

function TCRWMGridPower:toggleOnOff()
    if self:doWalkTo() then
        if self.device and self.device.getSquare and self.device:getSquare() == nil then
            return
        end
        ISTimedActionQueue.add(ISTCBoomboxAction:new("ToggleOnOff", self.player, self.device));
    end
end

function TCRWMGridPower:clear()
    RWMPanel.clear(self);
end

function TCRWMGridPower:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
    --[[ JUKEBOX LIFESTYLES DISABLED
    local md = _deviceObject and _deviceObject.getModData and _deviceObject:getModData() or nil
    if md and md.tcmusic and false then
        return false;
    end
    JUKEBOX LIFESTYLES DISABLED --]]
    if _deviceData:getIsBatteryPowered() then
        return false;
    end
    return RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType );
end

function TCRWMGridPower:update()
    ISPanel.update(self);

    if self.player and self.device and self.deviceData then
        local isOn = self.deviceData:getIsTurnedOn();
        self.led:setLedIsOn(isOn);

        if isOn then
            self.toggleOnOffButton:setTitle(getText("ContextMenu_Turn_Off"));
        else
            self.toggleOnOffButton:setTitle(getText("ContextMenu_Turn_On"));
        end
    end
end

function TCRWMGridPower:prerender()
    ISPanel.prerender(self);
end


function TCRWMGridPower:render()
    ISPanel.render(self);
    if self.deviceData then
        local x = self.toggleOnOffButton:getX()+self.toggleOnOffButton:getWidth()+5
        local y = (self.height - FONT_HGT_SMALL) / 2
        local hasWorldSquare = true
        if self.device and self.device.getSquare then
            hasWorldSquare = self.device:getSquare() ~= nil
        end
        if hasWorldSquare and self.deviceData:canBePoweredHere() then
            self:drawText(getText("IGUI_RadioPowerNearby"), x, y, 0,1,0,1, UIFont.Small);
        else
            self:drawText(getText("IGUI_RadioRequiresPowerNearby"), x, y, 1,0,0,1, UIFont.Small);
        end
    end
end

function TCRWMGridPower:onJoypadDown(button)
    if button == Joypad.AButton then
        self:toggleOnOff()
    end
end

function TCRWMGridPower:getAPrompt()
    if self.deviceData:getIsTurnedOn() then
        return getText("ContextMenu_Turn_Off");
    else
        return getText("ContextMenu_Turn_On");
    end
end
function TCRWMGridPower:getBPrompt()
    return nil;
end
function TCRWMGridPower:getXPrompt()
    return nil;
end
function TCRWMGridPower:getYPrompt()
    return nil;
end


function TCRWMGridPower:new (x, y, width, height)
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
    return o
end


