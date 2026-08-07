require "ISUI/ISCollapsableWindow"
require "RadioCom/ISRadioWindow"
require "TCMusicClientFunctions"

ISTCBoomboxWindow = ISCollapsableWindow:derive("ISTCBoomboxWindow");
ISTCBoomboxWindow.instances = {};
ISTCBoomboxWindow.instancesIso = {};

local TM_JUKE_DEBUG = false
local function dlog(msg)
    if TM_JUKE_DEBUG then
        print("[TMJukeDbg][Window] " .. tostring(msg))
    end
end
local isJukeboxDevice

function ISTCBoomboxWindow.activate( _player, _deviceObject )
    local playerNum = _player:getPlayerNum();
    
    local radioWindow, instances;
    _player:setVariable("ExerciseStarted", false);
    _player:setVariable("ExerciseEnded", true);
    local _isIso = not instanceof(_deviceObject, "Radio")
    if _isIso then
        instances = ISTCBoomboxWindow.instancesIso;
    else
        instances = ISTCBoomboxWindow.instances;
    end

    if instances[ playerNum ] then
        radioWindow = instances[ playerNum ];
    else
        radioWindow = ISTCBoomboxWindow:new (100, 100, 300, 500, _player);
        radioWindow:initialise();
        radioWindow:instantiate();
        if playerNum == 0 then
            ISLayoutManager.RegisterWindow('radiotelevision'..(_isIso and "Iso" or ""), ISCollapsableWindow, radioWindow);
        end
        instances[ playerNum ] = radioWindow;
    end

    dlog("activate start obj=" .. tostring(_deviceObject) .. " classRadio=" .. tostring(instanceof(_deviceObject, "Radio")) .. " classIsoWave=" .. tostring(instanceof(_deviceObject, "IsoWaveSignal")))
    radioWindow:readFromObject( _player, _deviceObject );
    dlog("after read type=" .. tostring(radioWindow.deviceType) .. " hasData=" .. tostring(radioWindow.deviceData ~= nil))
    if isJukeboxDevice(_deviceObject) then
        local sw = getCore() and getCore():getScreenWidth() or 1920
        local sh = getCore() and getCore():getScreenHeight() or 1080
        radioWindow:setX(math.max(0, math.floor((sw - radioWindow:getWidth()) / 2)))
        radioWindow:setY(math.max(0, math.floor((sh - radioWindow:getHeight()) / 3)))
    end
    radioWindow:addToUIManager();
    radioWindow:setVisible(true);
    if radioWindow.bringToTop then
        radioWindow:bringToTop()
    end
    dlog("after show visible=" .. tostring(radioWindow:getIsVisible()))

    if JoypadState.players[playerNum+1] then
        if getFocusForPlayer(playerNum) then getFocusForPlayer(playerNum):setVisible(false); end
        if getPlayerInventory(playerNum) then getPlayerInventory(playerNum):setVisible(false); end
        if getPlayerLoot(playerNum) then getPlayerLoot(playerNum):setVisible(false); end
        setJoypadFocus(playerNum, radioWindow);
    end
    return radioWindow;
end

function ISTCBoomboxWindow:initialise()
    ISCollapsableWindow.initialise(self);
end

function ISTCBoomboxWindow:addModule( _modulePanel, _moduleName, _enable )
    local module = {};
    module.enabled = _enable;
    module.element = RWMElement:new (0, 0, self.width, 0, _modulePanel, _moduleName, self);
    table.insert(self.modules, module);
    self:addChild(module.element);
end

function ISTCBoomboxWindow:createChildren()
    ISCollapsableWindow.createChildren(self);
    local th = self:titleBarHeight();

    self:addModule(TCRWMPower:new (0, 0, self.width, 0), getText("IGUI_RadioPower"), true);
    self:addModule(TCRWMGridPower:new (0, 0, self.width, 0), getText("IGUI_RadioPower"), true);
    self:addModule(TCRWMVolume:new (0, 0, self.width, 0), getText("IGUI_RadioVolume"), true);
    self:addModule(TCRWMMedia:new (0, 0, self.width, 0 ), getText("IGUI_RadioMedia"), true);

end

local dist = 4;
local function isAttachedToBack(player, item)
    if not player or not item then return false end
    local attachedItems = player.getAttachedItems and player:getAttachedItems() or nil
    if not attachedItems then return false end
    for i = 0, attachedItems:size() - 1 do
        local attached = attachedItems:get(i)
        local attachedItem = attached and attached:getItem() or nil
        if attachedItem == item then
            local loc = attached.getLocation and attached:getLocation() or nil
            if loc == "Big Weapon On Back" or loc == "Big Weapon On Back with Bag" or loc == "Back" then
                return true
            end
        end
    end
    return false
end

isJukeboxDevice = function(device)
    --[[ JUKEBOX LIFESTYLES DISABLED
    if not device or not device.getModData then return false end
    local md = device:getModData()
    return md and md.tcmusic and false == true
    JUKEBOX LIFESTYLES DISABLED --]]
    return false
end

local function getLinkedWorldRadioItem(device)
    if not device or not device.getModData or not device.getSquare then return nil end
    local md = device:getModData()
    if not md or not md.RadioItemID then return nil end
    local square = device:getSquare()
    if not square or not square.getWorldObjects then return nil end
    local link = tostring(md.RadioItemID)
    local worldObjects = square:getWorldObjects()
    for i = 0, worldObjects:size() - 1 do
        local worldObj = worldObjects:get(i)
        if instanceof(worldObj, "IsoWorldInventoryObject") then
            local item = worldObj:getItem()
            if item and item.getID then
                local itemId = tostring(item:getID())
                if itemId == link or (itemId .. "tm") == link then
                    return item
                end
            end
        end
    end
    return nil
end

function ISTCBoomboxWindow.closeIfActive(_player, _deviceObject)
    if not _player then return end
    local playerNum = _player:getPlayerNum()
    local _isIso = not instanceof(_deviceObject, "Radio")
    local instances = _isIso and ISTCBoomboxWindow.instancesIso or ISTCBoomboxWindow.instances
    local radioWindow = instances and instances[playerNum] or nil
    if not radioWindow then return end
    if radioWindow.device ~= _deviceObject then
        return
    end
    radioWindow:close()
end
function ISTCBoomboxWindow:update()
    ISCollapsableWindow.update(self);
    if self:getIsVisible() then
        --[[ JUKEBOX LIFESTYLES DISABLED
        if self.deviceType == "IsoObject" and isJukeboxDevice(self.device) then
            return;
        end
        JUKEBOX LIFESTYLES DISABLED --]]
        if self.deviceData and self.deviceType == "VehiclePart" then
            local part = self.deviceData:getParent()
            if part and part:getItemType() and not part:getItemType():isEmpty() and not part:getInventoryItem() then
                self:close()
                return
            end
        end

        if self.deviceType and self.device and self.character and self.deviceData then
            if self.deviceType=="InventoryItem" then -- incase of inventory item check if player has it in a hand
                if self.character:getPrimaryHandItem() == self.device or 
                    self.character:getSecondaryHandItem() == self.device or 
                    isAttachedToBack(self.character, self.device) or
                    (TCMusic.WalkmanPlayer[self.device:getFullType()] and self.device:getContainer() == self.character:getInventory()) then
                    return;
                end
            elseif self.deviceType == "IsoObject" or self.deviceType == "VehiclePart" then -- incase of isoobject check distance.
                if self.device:getSquare() and self.character:getX() > self.device:getX()-dist and self.character:getX() < self.device:getX()+dist and self.character:getY() > self.device:getY()-dist and self.character:getY() < self.device:getY()+dist then
                    return;
                end
            end
        end
    end

    if self.deviceData and self.deviceType=="InventoryItem" and
        ( self.character:getSecondaryHandItem() ~= self.device and self.character:getPrimaryHandItem() ~= self.device
            and not isAttachedToBack(self.character, self.device)) then        
        self.device:getModData().tcmusic.isPlaying = false;
        self.deviceData:setIsTurnedOn(false);
    end

    dlog("auto-close type=" .. tostring(self.deviceType) .. " hasCharacter=" .. tostring(self.character ~= nil) .. " hasDevice=" .. tostring(self.device ~= nil))
    self:close();
end

function ISTCBoomboxWindow:prerender()
    self:stayOnSplitScreen();
    ISCollapsableWindow.prerender(self);
    local cnt = 0;
    local ymod = self:titleBarHeight()+1;
    for i=1,#self.modules do
        if self.modules[i].enabled then
            self.modules[i].element:setY(ymod);
            ymod = ymod + self.modules[i].element:getHeight()+1;
        else
            self.modules[i].element:setVisible(false);
        end
    end
    self:setHeight(ymod);
end

function ISTCBoomboxWindow:stayOnSplitScreen()
    ISUIElement.stayOnSplitScreen(self, self.characterNum)
end


function ISTCBoomboxWindow:render()
    ISCollapsableWindow.render(self);
end

function ISTCBoomboxWindow:onLoseJoypadFocus(joypadData)
    self.drawJoypadFocus = false;
end

function ISTCBoomboxWindow:onGainJoypadFocus(joypadData)
    self.drawJoypadFocus = true;
end

function ISTCBoomboxWindow:close()
    ISCollapsableWindow.close(self);
    if JoypadState.players[self.characterNum+1] then
        if getFocusForPlayer(self.characterNum)==self or (self.subFocus) then
            setJoypadFocus(self.characterNum, nil);
        end
    end
    self:removeFromUIManager();
    self:clear();
    self.subFocus = nil;
end

function ISTCBoomboxWindow:clear()
    self.drawJoypadFocus = false;
    self.character = nil;
    self.device = nil;
    self.deviceData = nil;
    self.deviceType = nil;
    self.hotKeyPanels = {};
    for i=1,#self.modules do
        self.modules[i].enabled = false;
        self.modules[i].element:clear();
    end
end

function ISTCBoomboxWindow:readFromObject( _player, _deviceObject )
    self:clear();
    self.character = _player;
    self.device = _deviceObject;
    if self.device then
        -- Some world devices (e.g. Lifestyle jukebox wrappers) are plain IsoObject
        -- with deviceData but not IsoWaveSignal. Treat them as IsoObject.
        local isGenericIsoWithDeviceData = (not instanceof(self.device, "IsoWaveSignal"))
            and (not instanceof(self.device, "VehiclePart"))
            and self.device.getDeviceData
            and self.device.getSquare
        self.deviceType = (instanceof(self.device, "Radio") and "InventoryItem") or
            (instanceof(self.device, "IsoWaveSignal") and "IsoObject") or
            (isGenericIsoWithDeviceData and "IsoObject") or
            (instanceof(self.device, "VehiclePart") and "VehiclePart");
        dlog("classified type=" .. tostring(self.deviceType) .. " genericIso=" .. tostring(isGenericIsoWithDeviceData))
        if self.deviceType then
            self.deviceData = _deviceObject:getDeviceData();
            self.title = self.deviceData:getDeviceName(); -- JUKEBOX LIFESTYLES DISABLED: was `(isJukeboxDevice(self.device) and "Jukebox") or self.deviceData:getDeviceName()`
            if self.deviceType == "IsoObject" then
                if not self.device:getModData().tcmusic then
                    self.device:getModData().tcmusic = {}
                end
                self.device:getModData().tcmusic.deviceType = self.deviceType
                local linkedItem = getLinkedWorldRadioItem(self.device)
                if linkedItem and linkedItem.getDisplayName then
                    self.title = linkedItem:getDisplayName()
                end
                if self.deviceData and self.deviceData.getMediaType and self.deviceData.setMediaType then
                    local mt = self.deviceData:getMediaType()
                    if mt == nil or mt < 0 then
                        if linkedItem and linkedItem.getDeviceData and linkedItem:getDeviceData() and linkedItem:getDeviceData().getMediaType then
                            local lmt = linkedItem:getDeviceData():getMediaType()
                            if lmt ~= nil and lmt >= 0 then
                                self.deviceData:setMediaType(lmt)
                            end
                        end
                        mt = self.deviceData:getMediaType()
                        if mt == nil or mt < 0 then
                            local fullType = linkedItem and linkedItem.getFullType and linkedItem:getFullType() or nil
                            if fullType and fullType:lower():find("vinyl") then
                                self.deviceData:setMediaType(1)
                            else
                                self.deviceData:setMediaType(0)
                            end
                        end
                    end
                end
                if not isClient() and self.deviceData:getMediaType() == 1 then
                end
                if self.device.transmitModData then
                    self.device:transmitModData()
                end
            elseif self.deviceType == "InventoryItem" then
                if not self.device:getModData().tcmusic then
                    self.device:getModData().tcmusic = {}
                end
                self.device:getModData().tcmusic.deviceType = self.deviceType
            else
                local mediaItemName = false
                local isPlaying = false
                if self.device:getModData().tcmusic then
                    mediaItemName = self.device:getModData().tcmusic.mediaItem
                    isPlaying = self.device:getModData().tcmusic.isPlaying
                end
                sendClientCommand(self.character, 'truemusic', 'setMediaItemToVehiclePart', { vehicle = self.device:getVehicle():getId(), mediaItem = mediaItemName, isPlaying = isPlaying })
            end
        end
    end

    if (not self.character) or (not self.device) or (not self.deviceData) or (not self.deviceType) then
        dlog("read invalid character/device/data/type; clearing")
        self:clear();
        return;
    end

    for i=1,#self.modules do
        self.modules[i].enabled = self.modules[i].element:readFromObject(self.character, self.device, self.deviceData, self.deviceType);
        self.modules[i].element:setVisible(self.modules[i].enabled);
        if self.modules[i].enabled then
            if self.modules[i].element.titleText==getText("IGUI_RadioPower") then -- or self.modules[i].element.titleText=="GridPower" then
                self.hotKeyPanels.power = self.modules[i].element.subpanel;
            elseif self.modules[i].element.titleText==getText("IGUI_RadioVolume") then
                self.hotKeyPanels.volume = self.modules[i].element.subpanel;
            elseif self.modules[i].element.titleText==getText("IGUI_RadioMicrophone") then
                self.hotKeyPanels.microphone = self.modules[i].element.subpanel;
            end
        end
    end
end

local interval = 20;
function ISTCBoomboxWindow:onJoypadDirUp()
    self:setY(self:getY()-interval);
end

function ISTCBoomboxWindow:onJoypadDirDown()
    self:setY(self:getY()+interval);
end

function ISTCBoomboxWindow:onJoypadDirLeft()
    self:setX(self:getX()-interval);
end

function ISTCBoomboxWindow:onJoypadDirRight()
    self:setX(self:getX()+interval);
end

function ISTCBoomboxWindow:onJoypadDown(button)
    if button == Joypad.AButton and self.hotKeyPanels.power then
        self.hotKeyPanels.power:onJoypadDown(Joypad.AButton);
    elseif button == Joypad.BButton then
        self:close();
    elseif button == Joypad.YButton and self.hotKeyPanels.volume then
        self.hotKeyPanels.volume:onJoypadDown(Joypad.YButton);
    elseif button == Joypad.XButton and self.hotKeyPanels.microphone then
        self.hotKeyPanels.microphone:onJoypadDown(Joypad.AButton);
    elseif button == Joypad.LBumper then
        self:unfocusSelf(false);
    elseif button == Joypad.RBumper then
        self:focusNext();
    end
end

function ISTCBoomboxWindow:getAPrompt()
    if self.hotKeyPanels.power then
        return getText("IGUI_Hotkey")..": "..self.hotKeyPanels.power:getAPrompt();
    end
    return nil;
end
function ISTCBoomboxWindow:getBPrompt()
    return getText("IGUI_RadioClose");
end
function ISTCBoomboxWindow:getXPrompt()
    if self.hotKeyPanels.microphone then
        return getText("IGUI_Hotkey")..": "..self.hotKeyPanels.microphone:getAPrompt();
    end
    return nil;
end
function ISTCBoomboxWindow:getYPrompt()
    if self.hotKeyPanels.volume then
        return getText("IGUI_Hotkey")..": "..self.hotKeyPanels.volume:getYPrompt();
    end
    return nil;
end
function ISTCBoomboxWindow:getLBPrompt()
    return getText("IGUI_RadioReleaseFocus");
end
function ISTCBoomboxWindow:getRBPrompt()
    return getText("IGUI_RadioSelectInner");
end

function ISTCBoomboxWindow:unfocusSelf()
    setJoypadFocus(self.characterNum, nil);
end

function ISTCBoomboxWindow:focusSelf()
    self.subFocus = nil;
    setJoypadFocus(self.characterNum, self);
end

function ISTCBoomboxWindow:isValidPrompt()
    return (self.character and self.device and self.deviceData)
end

function ISTCBoomboxWindow:focusNext(_up)
    local first = nil;
    local last = nil;
    local found = false;
    local nextFocus = nil;
    for i=1,#self.modules do
        if self.modules[i].enabled then
            if not first then first = self.modules[i]; end
            if found and not _up and not nextFocus then
                nextFocus = self.modules[i];
            end
            if self.subFocus and self.subFocus==self.modules[i] then
                found = true;
                if last~=nil and _up then
                    nextFocus = last;
                end
            end
            last = self.modules[i];
        end
    end
    if not nextFocus then
        if _up then
            nextFocus = last;
        else
            nextFocus = first;
        end
    end
    self:setSubFocus(nextFocus)
end

function ISTCBoomboxWindow:setSubFocus( _newFocus )
    if not _newFocus or not _newFocus.element then
        self:focusSelf();
    else
        self.subFocus = _newFocus;
        _newFocus.element:setFocus(self.characterNum, self);
    end
end

function ISTCBoomboxWindow:new (x, y, width, height, player)
    local o = {}
    o = ISCollapsableWindow:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.character = player;
    o.characterNum = player:getPlayerNum();
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};
    o.width = width;
    o.height = height;
    o.anchorLeft = true;
    o.anchorRight = false;
    o.anchorTop = true;
    o.anchorBottom = false;
    o.pin = true;
    o.isCollapsed = false;
    o.collapseCounter = 0;
    o.title = "Radio/Television Window";
    o.resizable = false;
    o.drawFrame = true;

    o.device = nil;
    o.deviceData = nil;
    o.modules = {};
    o.overrideBPrompt = true;
    o.subFocus = nil;
    o.hotKeyPanels = {};
    o.isJoypadWindow = false;
    return o
end

