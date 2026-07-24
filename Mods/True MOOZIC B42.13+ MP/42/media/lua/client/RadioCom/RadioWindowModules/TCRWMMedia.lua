require "RadioCom/RadioWindowModules/RWMPanel"
require "TCMusicClientFunctions"

TCRWMMedia = RWMPanel:derive("TCRWMMedia");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

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

local function isGroundWalkman(device)
    if not device or not instanceof(device, "IsoWaveSignal") then return false end
    local md = device.getModData and device:getModData() or nil
    if md and md.tcmusic and md.tcmusic.isWalkman then
        return true
    end
    if md and md.RadioItemID and device.getSquare then
        local square = device:getSquare()
        if square and square.getWorldObjects then
            local link = tostring(md.RadioItemID)
            local worldObjects = square:getWorldObjects()
            for i = 0, worldObjects:size() - 1 do
                local worldObj = worldObjects:get(i)
                if instanceof(worldObj, "IsoWorldInventoryObject") then
                    local item = worldObj:getItem()
                    if item and item.getID then
                        local itemId = tostring(item:getID())
                        if itemId == link or (itemId .. "tm") == link then
                            local ft = item.getFullType and item:getFullType() or nil
                            return ft and TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[ft] or false
                        end
                    end
                end
            end
        end
    end
    return false
end

local function getJukeboxMusicPlayer(device)
    --[[ JUKEBOX LIFESTYLES DISABLED
    local md = device and device.getModData and device:getModData() or nil
    local tcm = md and md.tcmusic or nil
    if not tcm or not false then return nil end
    local mode = (tcm.jukeboxMode == "vinyl") and "vinyl" or "cassette"
    if mode == "vinyl" then
        return (TCMusic and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayer"]) or "tsarcraft_music_01_63"
    end
    return (TCMusic and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer["Tsarcraft.TCBoombox"]) or "tsarcraft_music_01_62"
    JUKEBOX LIFESTYLES DISABLED --]]
    return nil
end

local function getMusicPlayerForDevice(self)
    if not self or not self.device or not self.device.getModData then return nil end
    local tcm = self.device:getModData().tcmusic or nil
    if not tcm then return nil end

    if tcm.deviceType == "InventoryItem" then
        return TCMusic.ItemMusicPlayer[self.device:getFullType()] or TCMusic.WalkmanPlayer[self.device:getFullType()]
    elseif tcm.deviceType == "IsoObject" then
        local jukeboxMusicPlayer = getJukeboxMusicPlayer(self.device)
        if jukeboxMusicPlayer then
            return jukeboxMusicPlayer
        end
        local sprite = self.device.getSprite and self.device:getSprite() or nil
        local spriteName = sprite and sprite.getName and sprite:getName() or nil
        return spriteName and TCMusic.WorldMusicPlayer[spriteName] or nil
    elseif tcm.deviceType == "VehiclePart" then
        local invItem = self.device.getInventoryItem and self.device:getInventoryItem() or nil
        return invItem and TCMusic.VehicleMusicPlayer[invItem:getFullType()] or nil
    end

    return nil
end

local function getWorldMusicIdSafe(device)
    if not device then return nil end
    local md = device.getModData and device:getModData() or nil
    local tcm = md and md.tcmusic or nil
    local rid = md and md.RadioItemID or (tcm and tcm.radioItemID) or nil
    local hx = tcm and tonumber(tcm.hostX) or nil
    local hy = tcm and tonumber(tcm.hostY) or nil
    local hz = tcm and tonumber(tcm.hostZ) or nil

    if TCMusic and TCMusic.makeWorldMusicId then
        if rid ~= nil and tostring(rid) ~= "" then
            return TCMusic.makeWorldMusicId(hx or nil, hy or nil, hz or nil, rid)
        end
    end

    if hx and hy and hz then
        --[[ JUKEBOX LIFESTYLES DISABLED
        if tcm and false then
            return "W:J:" .. tostring(hx) .. "-" .. tostring(hy) .. "-" .. tostring(hz)
        end
        JUKEBOX LIFESTYLES DISABLED --]]
        return "W:C:" .. tostring(hx) .. "-" .. tostring(hy) .. "-" .. tostring(hz)
    end
    local sq = device.getSquare and device:getSquare() or nil
    if sq and sq.getX and sq.getY and sq.getZ then
        --[[ JUKEBOX LIFESTYLES DISABLED
        if tcm and false then
            return "W:J:" .. tostring(sq:getX()) .. "-" .. tostring(sq:getY()) .. "-" .. tostring(sq:getZ())
        end
        JUKEBOX LIFESTYLES DISABLED --]]
        return "W:C:" .. tostring(sq:getX()) .. "-" .. tostring(sq:getY()) .. "-" .. tostring(sq:getZ())
    end
    return nil
end

local function queueAction(self, mode, item)
    if not self or not self.player or not self.device then return false end
    if not self.device.getDeviceData or not self.device:getDeviceData() then return false end
    local action = ISTCBoomboxAction:new(mode, self.player, self.device, item)
    if not action or (action.isValid and not action:isValid()) then return false end
    ISTimedActionQueue.add(action)
    return true
end

function TCRWMMedia:initialise()
    ISPanel.initialise(self)
end

function TCRWMMedia:createChildren()

    local y = 4;
    local ww = math.floor((self:getWidth()-20)/ISLcdBar.charW);
    local charWidth = ww;
    local lcdw = ww*ISLcdBar.charW;
    local x = ((self:getWidth()/2)-(lcdw/2))-2;

    self.lcd = ISLcdBar:new(x,y,charWidth);
    self.lcd:initialise();
    self.lcd:setTextMode(false);
    self:addChild(self.lcd);

    y = self.lcd:getY() + self.lcd:getHeight() + 5;

    x = (self:getWidth()/2)-(24/2);
    self.itemDropBox = ISItemDropBox:new (x, y, 24, 24, false, self, TCRWMMedia.addMedia, TCRWMMedia.removeMedia, TCRWMMedia.verifyItem, nil );
    self.itemDropBox:initialise();
    self.itemDropBox:setBackDropTex( getTexture("Item_Battery"), 0.4, 1,1,1 );
    self.itemDropBox:setDoBackDropTex( true );
    self.itemDropBox:setToolTip( true, getText("IGUI_RadioDragBattery") );
    self:addChild(self.itemDropBox);

    y = self.itemDropBox:getY() + self.itemDropBox:getHeight() + 5;

    local btnHgt = FONT_HGT_SMALL + 1 * 2

    self.toggleOnOffButton = ISButton:new(10, y, self:getWidth()-20, btnHgt, getText("ContextMenu_Turn_On"),self, TCRWMMedia.togglePlayMedia);
    self.toggleOnOffButton:initialise();
    self.toggleOnOffButton.backgroundColor = {r=0, g=0, b=0, a=0.0};
    self.toggleOnOffButton.backgroundColorMouseOver = {r=1.0, g=1.0, b=1.0, a=0.1};
    self.toggleOnOffButton.borderColor = {r=1.0, g=1.0, b=1.0, a=0.3};
    self:addChild(self.toggleOnOffButton);

    y = self.toggleOnOffButton:getY() + self.toggleOnOffButton:getHeight() + 10;

    self:setHeight(y);
end

function TCRWMMedia:connectSpeaker (_item, dx, dy)
    local square = _item:getSquare()
    if square == nil then return end
    for y=square:getY() - dy, square:getY() + dy do
        for x=square:getX() - dx, square:getX() + dx do
            local square2 = getCell():getGridSquare(x, y, square:getZ())
            if square2 ~= nil then
                for i=1,square2:getObjects():size() do
                    local object = square2:getObjects():get(i-1)
                    if instanceof( object, "IsoWorldInventoryObject") then
                        if object:getItem():getType() == "Speaker" then
                            if object:getModData().tcmusic and object:getModData().tcmusic.connectTo then
                                
                            else
                                object:getModData().tcmusic = {}
                                object:getModData().tcmusic.connectTo = _item
                                _item:getModData().tcmusic.connectTo = object
                                object:transmitModData()
                                return true
                            end
                        end    
                    end
                end
            end
        end
    end
    return false
end


function TCRWMMedia:togglePlayMedia()
    local md = self.device and self.device.getModData and self.device:getModData() or nil
    local tcm = md and md.tcmusic or nil
    if not tcm then return end

    if self.deviceType == "IsoObject" and isGroundWalkman(self.device) then
        if self.player then
            self.player:Say(getText("IGUI_TC_cant_play_on_ground"))
        end
        return
    end
    if self:doWalkTo() then
        if not tcm.needSpeaker or tcm.connectTo then
            queueAction(self, "TogglePlayMedia")
        else
            if TCRWMMedia.connectSpeaker(self.player, self.device, 1, 1) then
                
            else
                self.player:Say(getText("IGUI_PlayerText_TC_need_speaker"))
            end
        end
    end
end

function TCRWMMedia:removeMedia()
    if self:doWalkTo() then
        queueAction(self, "RemoveMedia")
    end
end

function TCRWMMedia:addMedia( _items )
    if self.player:getJoypadBind() == -1 then
        self:addMediaAux(_items[1])
        return
     end
    local playerNum = self.player:getPlayerNum()
    local context = ISContextMenu.get(playerNum, self:getAbsoluteX(), self:getAbsoluteY())
    for _,item in ipairs(_items) do
        context:addOption(item:getDisplayName(), self, self.addMediaAux, item)
    end
    context.mouseOver = 1
    if JoypadState.players[playerNum+1] then
        context.origin = JoypadState.players[playerNum+1].focus
        setJoypadFocus(playerNum, context)
    end
end

function TCRWMMedia:addMediaAux(item)
    if self:doWalkTo() then
        if item then
            queueAction(self, "AddMedia", item)
        end
    end
end

function TCRWMMedia:verifyItem( _item )
    if not _item or not _item.getType then return false end
    if GlobalMusic[_item:getType()] then
        if self.deviceType == "InventoryItem" then
            if TCMusic.ItemMusicPlayer[self.device:getFullType()] == GlobalMusic[_item:getType()] or 
                    TCMusic.WalkmanPlayer[self.device:getFullType()] == GlobalMusic[_item:getType()] then
                return true;
            end
        elseif self.deviceType == "IsoObject" then
            if isGroundWalkman(self.device) then
                return false;
            end
            local musicPlayer = getMusicPlayerForDevice(self)
            if musicPlayer and musicPlayer == GlobalMusic[_item:getType()] then
                return true;
            end
        elseif self.deviceType == "VehiclePart" then
            if self.device:getInventoryItem() and TCMusic.VehicleMusicPlayer[self.device:getInventoryItem():getFullType()] == GlobalMusic[_item:getType()] then
                return true;
            end
        end
    end
end

function TCRWMMedia:clear()
    RWMPanel.clear(self);
end

function TCRWMMedia:updateToolTip( device )
        device = device or self.device
        local deviceData = device:getDeviceData()
        local tooltip = self:getMediaName(device)
        if deviceData:getMediaType() == 0 then
            self.itemDropBox:setToolTip( true, tooltip or getText("IGUI_media_dragCassette") );
        elseif deviceData:getMediaType()==1 then
            self.itemDropBox:setToolTip( true, tooltip or getText("IGUI_media_dragVinyl") );
        end
end


function TCRWMMedia:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
    if _deviceData:getMediaType() < 0 then
        if _deviceType == "VehiclePart" then
            _deviceData:setMediaType(0)
        else
            return false;
        end
    end
    self.mediaIndex = -9999;
    if _deviceData:getMediaType()==1 then
        self.itemDropBox:setBackDropTex( self.cdTex, 0.4, 1,1,1 );
        self.lcd.ledColor = self.lcdBlue.back;
        self.lcd.ledTextColor = self.lcdBlue.text;
    end
    if _deviceData:getMediaType()==0 then
        self.itemDropBox:setBackDropTex( self.tapeTex, 0.4, 1,1,1 );
        self.lcd.ledColor = self.lcdGreen.back;
        self.lcd.ledTextColor = self.lcdGreen.text;
    end
    self:updateToolTip(_deviceObject)
    if _deviceType == "IsoObject" then
        self.lastWorldMusicId = getWorldMusicIdSafe(_deviceObject)
    end

    local read =  RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType );

    if self.player then
        self.itemDropBox.mouseEnabled = true;
        if JoypadState.players[self.player:getPlayerNum()+1] then
            self.itemDropBox.mouseEnabled = false;
        end
    end

    return read;
end

function TCRWMMedia:getMediaName(device)
    device = device or self.device
    if not device or not device:getModData().tcmusic.mediaItem then
        return nil
    end
    local item = instanceItem(device:getModData().tcmusic.mediaItem)
    if not item then
        return nil
    end
    return item:getDisplayName()
end

function TCRWMMedia:getMediaText()
    local text = nil;
    if self.device:getModData().tcmusic.mediaItem then
        text = self:getMediaName()
    end
    if text ~= nil then
        return text.." *** ";
    end
    return self.deviceData:getMediaType()==0 and self.textNoTape or self.textNoCD;
end

function TCRWMMedia:update()
    ISPanel.update(self);
    
    if self.player and self.device and self.deviceData and self.device:getModData().tcmusic then
        if self.deviceType == "IsoObject" then
            local sq = self.device.getSquare and self.device:getSquare() or nil
            if not sq then
                local musicId = self.lastWorldMusicId or getWorldMusicIdSafe(self.device)
                local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"] or nil
                if nowPlay and musicId then
                    nowPlay[musicId] = nil
                end
                if self.deviceData and self.deviceData.getEmitter and self.deviceData:getEmitter() then
                    self.deviceData:getEmitter():stopAll()
                end
                local parent = self.parent
                if parent and parent.close then
                    parent:close()
                elseif parent and parent.setVisible then
                    parent:setVisible(false)
                end
                self.device = nil
                return
            end
            self.lastWorldMusicId = getWorldMusicIdSafe(self.device)
        end

        local isOn = self.deviceData:getIsTurnedOn();

        self.lcd:toggleOn(isOn);

        if (not isOn) and self.device:getModData().tcmusic.mediaItem and self.device:getDeviceData():getEmitter() and self.device:getDeviceData():getEmitter():isPlaying(self.device:getModData().tcmusic.mediaItem) then
            self.deviceData:getEmitter():stopAll()
            ISBaseTimedAction.perform(self)
        end
        
        
        if self.device:getModData().tcmusic.deviceType == "VehiclePart" then
            if self.device:getModData().tcmusic.mediaItem and self.device:getModData().tcmusic.isPlaying then
                self.toggleOnOffButton:setTitle(self.textStop);
            else
                self.toggleOnOffButton:setTitle(self.textPlay);
            end
        elseif self.device:getModData().tcmusic.deviceType == "InventoryItem" then
            if self.device:getModData().tcmusic.mediaItem and 
                    self.player:getModData().tcmusicid and
                    self.player:getEmitter():isPlaying(self.player:getModData().tcmusicid) then
                        self.toggleOnOffButton:setTitle(self.textStop);
            else
                if self.device:getModData().tcmusic.needSpeaker and not self.device:getModData().tcmusic.connectTo then
                    self.toggleOnOffButton:setTitle(self.textSpeaker);
                elseif self.deviceType == "IsoObject" and self.device:getModData().tcmusic.isWalkman then
                    self.toggleOnOffButton:setTitle(getText("IGUI_TC_cant_play_on_ground"))
                elseif self.deviceType == "InventoryItem" and TCMusic.WalkmanPlayer[self.device:getFullType()] and not hasHeadphones(self.device, self.deviceData) then
                    self.toggleOnOffButton:setTitle(getText("IGUI_TC_connect_headphones"))
                else
                    self.toggleOnOffButton:setTitle(self.textPlay);
                end
            end
        else
            local worldPlaying = self.device:getModData().tcmusic.mediaItem and self.device:getModData().tcmusic.isPlaying
            --[[ JUKEBOX LIFESTYLES DISABLED
            if (not worldPlaying) and false then
                local nowPlay = ModData.getOrCreate("trueMusicData")["now_play"] or nil
                local musicId = self.lastWorldMusicId or getWorldMusicIdSafe(self.device)
                worldPlaying = nowPlay and nowPlay[musicId] and nowPlay[musicId].isPlaying == true
                if (not worldPlaying) and self.device and self.device.getX and self.device.getY and self.device.getZ then
                    local legacyMusicId = "#" .. tostring(self.device:getX()) .. "-" .. tostring(self.device:getY()) .. "-" .. tostring(self.device:getZ())
                    worldPlaying = nowPlay and nowPlay[legacyMusicId] and nowPlay[legacyMusicId].isPlaying == true
                end
            end
            JUKEBOX LIFESTYLES DISABLED --]]
            if worldPlaying then
                self.toggleOnOffButton:setTitle(self.textStop);
            else
                if self.device:getModData().tcmusic.needSpeaker and not self.device:getModData().tcmusic.connectTo then
                    self.toggleOnOffButton:setTitle(self.textSpeaker);
                elseif self.deviceType == "IsoObject" and isGroundWalkman(self.device) then
                    self.toggleOnOffButton:setTitle(getText("IGUI_TC_cant_play_on_ground"))
                elseif self.deviceType == "InventoryItem" and TCMusic.WalkmanPlayer[self.device:getFullType()] and not hasHeadphones(self.device, self.deviceData) then
                    self.toggleOnOffButton:setTitle(getText("IGUI_TC_connect_headphones"))
                else
                    self.toggleOnOffButton:setTitle(self.textPlay);
                end
            end
        end
        if self.device:getModData().tcmusic.mediaItem then
            if self.deviceData:getMediaType()==1 then
                self.itemDropBox:setStoredItemFake( self.cdTex );
            end
            if self.deviceData:getMediaType()==0 then
                self.itemDropBox:setStoredItemFake( self.tapeTex );
            end

            if self.device:getModData().tcmusic.mediaItem and (self.device:getModData().tcmusic.isPlaying or (self.device:getModData().tcmusic.deviceType == "VehiclePart" and self.device:getVehicle():getEmitter() and self.device:getVehicle():getEmitter():isPlaying(self.device:getModData().tcmusic.mediaItem))) then
                self.lcd:setText(self:getMediaText());
                self.lcd:setDoScroll(true);
            else
                self.lcd:setText(self.idleText);
                self.lcd:setDoScroll(false);
            end
        else
            self.itemDropBox:setStoredItemFake( nil );
            self.lcd:setText(self.mediaText);
            self.lcd:setDoScroll(false);
        end
        self:updateToolTip(self.device);
    end
end

function TCRWMMedia:prerender()
    ISPanel.prerender(self);
end


function TCRWMMedia:render()
    ISPanel.render(self);
end

function TCRWMMedia:onJoypadDown(button)
    if button == Joypad.AButton then
        self:togglePlayMedia()
    elseif button == Joypad.BButton then
        if self.device:getModData().tcmusic.mediaItem then
            self:removeMedia();
        else
            local inv = self.player:getInventory();
            local medias = {};
            
            local musicPlayer = getMusicPlayerForDevice(self)
            for i=0, inv:getItemsFromCategory("Item"):size()-1 do
                local itemInContainer = inv:getItemsFromCategory("Item"):get(i)
                local musicCarrier = GlobalMusic[itemInContainer:getType()]
                if musicCarrier and musicCarrier == musicPlayer then    
                    table.insert(medias, itemInContainer);
                end
            end
            if #medias>0 then
                self:addMedia( medias );
            end
        end
    else
    end
end

function TCRWMMedia:getAPrompt()
    if self.device:getModData().tcmusic.mediaItem and self.device:getDeviceData():getEmitter() and 
       self.device:getDeviceData():getEmitter():isPlaying(self.device:getModData().tcmusic.mediaItem) then
        return self.textStop;
    else
        return self.textPlay;
    end
end

function TCRWMMedia:getBPrompt()
    if self.device:getModData().tcmusic.mediaItem then
        return getText("IGUI_media_removeMedia");
    else
        local inv = self.player:getInventory();
        local medias = {};
        local musicPlayer = getMusicPlayerForDevice(self)
        for i=0, inv:getItemsFromCategory("Item"):size()-1 do
            local itemInContainer = inv:getItemsFromCategory("Item"):get(i)
            local musicCarrier = GlobalMusic[itemInContainer:getType()]
            if musicCarrier and musicCarrier == musicPlayer then    
                table.insert(medias, itemInContainer);
            end
        end
        if #medias>0 then
            return getText("IGUI_media_addMedia");
        end
    end
    return nil;
end
function TCRWMMedia:getXPrompt()
    return nil;
end
function TCRWMMedia:getYPrompt()
    return nil;
end


function TCRWMMedia:new (x, y, width, height)
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
    o.cdTex = getTexture("media/textures/UI/TCVinylrecord.png");
    o.tapeTex = getTexture("media/textures/UI/TCTape.png");
    o.mediaIndex = -9999;
    o.mediaText = "";
    o.idleText = getText("IGUI_media_idle");
    o.lcdBlue = {
        text = { r=0.039, g=0.180, b=0.2, a=1.0 },
        back = { r=0.172, g=0.686, b=0.764, a=1.0 }
    };
    o.lcdGreen = {
        text = { r=0.180, g=0.2, b=0.039, a=1.0 },
        back = { r=0.686, g=0.764, b=0.172, a=1.0 },
    };
    o.textPlay = getText("IGUI_media_play");
    o.textSpeaker = getText("IGUI_TC_connect_speaker");
    o.textStop = getText("IGUI_media_stop");
    o.textNoCD = getText("IGUI_media_nocd");
    o.textNoTape = getText("IGUI_media_notape");
    return o
end




