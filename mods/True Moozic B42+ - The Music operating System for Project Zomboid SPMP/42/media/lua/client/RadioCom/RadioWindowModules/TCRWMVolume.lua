require "RadioCom/RadioWindowModules/RWMPanel"

TCRWMVolume = RWMPanel:derive("TCRWMVolume");

local function getHeadphoneType(device, deviceData)
    local hpType = deviceData and deviceData.getHeadphoneType and deviceData:getHeadphoneType() or -1
    if hpType >= 0 then return hpType end
    local md = device and device.getModData and device:getModData() or nil
    if md then
        if md.tm_hasHeadphones ~= nil then
            if md.tm_hasHeadphones then
                if md.tcmusic and md.tcmusic.headphoneType ~= nil then
                    return md.tcmusic.headphoneType
                end
                if md.tm_headphoneType ~= nil then
                    return md.tm_headphoneType
                end
                return 0
            else
                return -1
            end
        end
        if md.tcmusic and md.tcmusic.headphoneType ~= nil then
            return md.tcmusic.headphoneType
        end
    end
    return hpType
end

local function queueAction(self, mode, item)
    if not self or not self.player or not self.device then return false end
    if not self.device.getDeviceData or not self.device:getDeviceData() then return false end
    local action = ISTCBoomboxAction:new(mode, self.player, self.device, item)
    if not action or (action.isValid and not action:isValid()) then return false end
    ISTimedActionQueue.add(action)
    return true
end

function TCRWMVolume:initialise()
    ISPanel.initialise(self)
end

function TCRWMVolume:createChildren()
    self:setHeight(self.innerHeight+self.marginTop+self.marginBottom);

    self.speakerButton = ISSpeakerButton:new (self.marginLeft+2, self.marginTop+2, 20, 20, TCRWMVolume.onSpeakerButton, self);
    self.speakerButton:initialise();
    self:addChild(self.speakerButton);

    local xoffset = self.marginLeft + self.marginRight + 10 + self.textureSize;
    local remWidth = self:getWidth() - xoffset - 10;

    self.volumeBar = ISVolumeBar:new(xoffset, self.marginTop, remWidth, self.innerHeight, TCRWMVolume.onVolumeChange, self);
    self.volumeBar:initialise();
    self:addChild(self.volumeBar);

    self.itemDropBox = ISItemDropBox:new (0, self.marginTop, self.innerHeight, self.innerHeight, false, self, TCRWMVolume.addHeadphone, TCRWMVolume.removeHeadphone, TCRWMVolume.verifyItem, nil );
    self.itemDropBox:initialise();
    self.itemDropBox:setBackDropTex( getTexture("Item_Headphones"), 0.4, 1,1,1 );
    self.itemDropBox:setDoBackDropTex( true );
    self.itemDropBox:setToolTip( true, getText("IGUI_RadioDragHeadphones") );

    local tickY = self.marginTop + self.innerHeight + 4;
    if isClient() then
        self.clientVolBox = ISTickBox:new(xoffset, tickY, 18, 18, "", self, TCRWMVolume.onClientVolumeToggle);
        self.clientVolBox:initialise();
        self.clientVolBox:addOption(getText("IGUI_TCClientVolume"));
        self.clientVolBox.tooltip = getText("IGUI_TCClientVolume_Tooltip");
        self.clientVolBox.selected[1] = false;
        self:addChild(self.clientVolBox);
        self:setHeight(tickY + 18 + self.marginBottom);
    end

    self.hasEnabledHeadphones = false;
end

function TCRWMVolume:clientVolKey()
    return TCMusic.getClientVolumeKeyFor and TCMusic.getClientVolumeKeyFor(self.device, self.deviceType) or nil
end

-- Live playback session for THIS device (walkman/boombox owner). The session
-- carries the echo-proof volume; DeviceData can be rolled back by the server.
function TCRWMVolume:deviceSession()
    if not (self.device and self.device.getID) then return nil end
    local id = self.device:getID()
    local ws = TCMusic.WalkmanSession
    if ws and ws.itemId == id then return ws end
    local bs = TCMusic.BoomboxSession
    if bs and bs.itemId == id then return bs end
    return nil
end

-- After a local-volume change, retune whatever is audibly playing right now.
function TCRWMVolume:applyLocalVolumeNow(key)
    if TCMusic.applyClientVolumeToOwnDevice then
        TCMusic.applyClientVolumeToOwnDevice(self.player or getPlayer(), self.deviceData, key)
    end
    -- Placed device (boombox / vinyl player on the ground): the sound runs
    -- on a tick-engine world emitter - retune it immediately.
    if self.deviceType == "IsoObject" and self.device and self.device.getX
        and TCMusic.applyClientVolumeToWorldDevice then
        TCMusic.applyClientVolumeToWorldDevice(self.device:getX(), self.device:getY(), self.device:getZ(), nil)
    end
end

function TCRWMVolume:onClientVolumeToggle(index, selected)
    local key = self:clientVolKey()
    if not key then return end
    if selected then
        local ses = self:deviceSession()
        TCMusic.setClientVolume(key, (ses and ses.volume) or (self.deviceData and self.deviceData:getDeviceVolume()) or 1.0)
    else
        TCMusic.setClientVolume(key, nil)
    end
    self:applyLocalVolumeNow(key)
end

function TCRWMVolume:toggleHeaphoneSupport(enable)
    if self.hasEnabledHeadphones ~= enable then
        if not enable then
            self.volumeBar:setWidth(self.volumeBar:getWidth() + self.itemDropBox:getWidth() + 10);
            self:removeChild(self.itemDropBox);
        else
            local x = self.volumeBar:getX() + (self.volumeBar:getWidth()-self.itemDropBox:getWidth());
            self.itemDropBox:setX(x);
            self.volumeBar:setWidth(self.volumeBar:getWidth() - (self.itemDropBox:getWidth() + 10));
            self:addChild(self.itemDropBox);
        end
    end
    self.hasEnabledHeadphones = enable;
end

function TCRWMVolume:addHeadphone( _items )
    local item;
    local pbuff = 0;

    for _,i in ipairs(_items) do
        item = i;
        break;
    end

    if item then
        if self:doWalkTo() then
            queueAction(self, "AddHeadphones", item)
        end
    end
end

function TCRWMVolume:removeHeadphone()
    if self:doWalkTo() then
        queueAction(self, "RemoveHeadphones")
    end
end

function TCRWMVolume:verifyItem(_item)
    if _item:getFullType() == "Base.Headphones" or _item:getFullType() == "Base.Earbuds" then
        return true;
    end
end

function TCRWMVolume:round(num, idp)
    local mult = 10^(idp or 0);
    return math.floor(num * mult + 0.5) / mult;
end

function TCRWMVolume:onVolumeChange( _newVol )
    self.volume = _newVol / self.volumeBar:getVolumeSteps();
    local cvKey = self:clientVolKey()
    if cvKey and TCMusic.isClientVolumeActive and TCMusic.isClientVolumeActive(cvKey) then
        -- Local mode for THIS device: the slider adjusts this client's
        -- listening volume only; the shared device volume is untouched.
        TCMusic.setClientVolume(cvKey, self.volume)
        self:applyLocalVolumeNow(cvKey)
        return
    end
    if self.deviceData then
        -- Compare against the SESSION volume when one is live: DeviceData
        -- can be rolled back by a server item echo, and matching against
        -- the stale value would wrongly swallow the change.
        local ses = self:deviceSession()
        local current = (ses and ses.volume) or self.deviceData:getDeviceVolume()
        if math.abs(self.volume - current) < 0.001 then
            return
        end
        if self:doWalkTo() then
            queueAction(self, "SetVolume", self.volume)
        end
    end
end

function TCRWMVolume:onSpeakerButton( _ismute )
    self.isMute = _ismute;
    if self.isMute == true then
        if self.deviceData then
            if self:doWalkTo() then
                queueAction(self, "SetVolume", 0)
            end
        end
        self.volumeBar:setEnableControls(false);
    else
        if self.deviceData then
            if self:doWalkTo() then
                local volumeToSet = self.volume ~= 0 and self.volume or 0.1
                queueAction(self, "SetVolume", volumeToSet)
            end
        end
        self.volumeBar:setEnableControls(true);
    end
end

function TCRWMVolume:clear()
    RWMPanel.clear(self);
end

function TCRWMVolume:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
    RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType );
    self.volume = self.deviceData:getDeviceVolume();
    self.volumeBar:setVolume(math.floor(self.volume*self.volumeBar:getVolumeSteps()));
    local md = _deviceObject and _deviceObject.getModData and _deviceObject:getModData() or nil
    local isJukebox = false -- JUKEBOX LIFESTYLES DISABLED: was `md and md.tcmusic and md.tcmusic.isJukebox`
    if (not isJukebox) and self.deviceData:getIsPortable() and self.deviceData:getIsTelevision()==false then
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

function TCRWMVolume:update()
    ISPanel.update(self);

    -- Walkman = headphones-only local playback: nobody else hears it, so
    -- there is no shared volume to diverge from. The master slider IS the
    -- volume - hide the client-volume layer and drop any stored override.
    local isWalkman = self.device and self.device.getFullType
        and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[self.device:getFullType()] or false
    local cvKey = self:clientVolKey()
    local cvActive = cvKey and TCMusic.isClientVolumeActive and TCMusic.isClientVolumeActive(cvKey) or false
    if isWalkman then
        if cvActive and cvKey and TCMusic.setClientVolume then
            TCMusic.setClientVolume(cvKey, nil)
        end
        cvActive = false
    end
    if self.clientVolBox then
        self.clientVolBox.selected[1] = cvActive
        self.clientVolBox:setVisible(not isWalkman)
    end
    if cvActive then
        -- Local mode: the slider shows/controls this device's local volume.
        self.speakerButton:setEnableControls(true);
        self.volumeBar:setEnableControls(true);
        self.volumeBar:setVolume(math.floor(((TCMusic.getClientVolume(cvKey) or 1.0) + 0.05) * self.volumeBar:getVolumeSteps()));
        if self.deviceData then
            local hpType = getHeadphoneType(self.device, self.deviceData)
            if hpType >= 0 then
                if hpType == 0 then
                    self.itemDropBox:setStoredItemFake( self.headphonesTex );
                elseif hpType == 1 then
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
        -- Session volume wins over DeviceData: the server item echo can roll
        -- DeviceData back, which made the slider visibly snap to the OLD
        -- volume seconds after moving it. The session value is echo-proof.
        local ses = self:deviceSession()
        local shownVol = (ses and ses.volume) or self.deviceData:getDeviceVolume()
        if ses then
            self.speakerButton.isMute = shownVol <= 0
            self.volumeBar:setEnableControls(not self.speakerButton.isMute)
        end
        local devVol = shownVol+0.05; --hack for decimal/float precision thingy
        self.volumeBar:setVolume(math.floor(devVol*self.volumeBar:getVolumeSteps()));

        local hpType = getHeadphoneType(self.device, self.deviceData)
        if hpType >= 0 then
            if hpType == 0 then
                self.itemDropBox:setStoredItemFake( self.headphonesTex );
            elseif hpType == 1 then
                self.itemDropBox:setStoredItemFake( self.earbudsTex );
            end
        else
            self.itemDropBox:setStoredItemFake( nil );
        end
    end
end

function TCRWMVolume:prerender()
    ISPanel.prerender(self);
end

function TCRWMVolume:render()
    ISPanel.render(self);
end

function TCRWMVolume:onJoypadDown(button)
    if button == Joypad.AButton then
        self.volumeBar:setVolumeJoypad(true)
    elseif button == Joypad.BButton then
        self.volumeBar:setVolumeJoypad(false)
    elseif button == Joypad.XButton then
        if getHeadphoneType(self.device, self.deviceData) >= 0 then
            self:removeHeadphone();
        else
            local tab = {}
            local inventory = self.player:getInventory()
            
            local headphonesList = inventory:FindAll("Base.Headphones")
            if headphonesList then
                local headphonesSize = headphonesList:size()
                for i = 0, headphonesSize - 1 do
                    table.insert(tab, headphonesList:get(i))
                end
            end
            
            local earbudsList = inventory:FindAll("Base.Earbuds")
            if earbudsList then
                local earbudsSize = earbudsList:size()
                for i = 0, earbudsSize - 1 do
                    table.insert(tab, earbudsList:get(i))
                end
            end
            
            self:addHeadphone(tab)
        end
    elseif button == Joypad.YButton then
        self:onSpeakerButton(not self.speakerButton.isMute)
    end
end

function TCRWMVolume:getAPrompt()
    return getText("IGUI_RadioVolUp");
end
function TCRWMVolume:getBPrompt()
    return getText("IGUI_RadioVolDown");
end
function TCRWMVolume:getXPrompt()
    if getHeadphoneType(self.device, self.deviceData) >= 0 then
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
function TCRWMVolume:getYPrompt()
    if self.speakerButton.isMute then
        return getText("IGUI_RadioUnmuteSpeaker");
    else
        return getText("IGUI_RadioMuteSpeaker");
    end
end

function TCRWMVolume:new (x, y, width, height)
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
    o.fontheight = getTextManager():MeasureStringY(UIFont.Small, "AbdfghijklpqtyZ")+2;
    o.textureSize = 16;
    o.isMute = false;
    o.volume = 6;
    o.marginLeft = 4;
    o.marginRight = 4;
    o.marginTop = 4;
    o.marginBottom = 4;
    o.innerHeight = 24;
    o.headphonesTex = getTexture("Item_Headphones");
    o.earbudsTex = getTexture("Item_Earbuds");
    return o
end
