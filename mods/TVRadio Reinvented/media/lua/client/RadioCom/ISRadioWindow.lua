-- **thank you** turbotutone

require "ISUI/ISCollapsableWindow"

ISRadioWindow = ISCollapsableWindow:derive("ISRadioWindow");
ISRadioWindow.instances = {};
ISRadioWindow.instancesIso = {};

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6
local UI_BORDER_SPACING = 10

function ISRadioWindow.activate( _player, _deviceObject )
    local playerNum = _player:getPlayerNum();

    local radioWindow, instances;
    _player:setVariable("ExerciseStarted", false);
    _player:setVariable("ExerciseEnded", true);
    local _isIso = not instanceof(_deviceObject, "Radio")
    if _isIso then
        instances = ISRadioWindow.instancesIso;
    else
        instances = ISRadioWindow.instances;
    end

    if instances[ playerNum ] then
        radioWindow = instances[ playerNum ];
        --radioWindow:initialise();
    else
        radioWindow = ISRadioWindow:new (100, 100, 300, 500, _player);
		radioWindow.drawFrame = false
        radioWindow:initialise();
        radioWindow:instantiate();
        ISLayoutManager.enableLog = true;
        if playerNum == 0 then
            ISLayoutManager.RegisterWindow('radiotelevision'..(_isIso and "Iso" or ""), ISCollapsableWindow, radioWindow);
        end
        ISLayoutManager.enableLog = false;
        instances[ playerNum ] = radioWindow;
    end

    --radioWindow.isJoypadWindow = JoypadState.players[playerNum+1] and true or false;

    radioWindow:readFromObject( _player, _deviceObject );

    radioWindow:addToUIManager();
    radioWindow:setVisible(true);
	radioWindow.collapseButton:setVisible(false)
	radioWindow.closeButton:setVisible(false)

    --radioWindow:setJoypadPrompt();
    if JoypadState.players[playerNum+1] then
        if getFocusForPlayer(playerNum) then getFocusForPlayer(playerNum):setVisible(false); end
        if getPlayerInventory(playerNum) then getPlayerInventory(playerNum):close(); end
        if getPlayerLoot(playerNum) then getPlayerLoot(playerNum):close(); end
        --setJoypadFocus(playerNum, nil);
        setJoypadFocus(playerNum, radioWindow);
    end
    return radioWindow;
end

function ISRadioWindow.isActive( _player, _deviceObject )
    local playerNum = _player:getPlayerNum();

    local radioWindow, instances;
    _player:setVariable("ExerciseStarted", false);
    _player:setVariable("ExerciseEnded", true);
    local _isIso = not instanceof(_deviceObject, "Radio")
    if _isIso then
        instances = ISRadioWindow.instancesIso;
    else
        instances = ISRadioWindow.instances;
    end

    if instances[ playerNum ] then
        radioWindow = instances[ playerNum ];
        radioWindow:readFromObject( _player, _deviceObject );
        return radioWindow:isVisible()
    end

    return false
end

function ISRadioWindow.closeIfActive( _player, _deviceObject )
    local playerNum = _player:getPlayerNum();

    local radioWindow, instances;
    _player:setVariable("ExerciseStarted", false);
    _player:setVariable("ExerciseEnded", true);
    local _isIso = not instanceof(_deviceObject, "Radio")
    if _isIso then
        instances = ISRadioWindow.instancesIso;
    else
        instances = ISRadioWindow.instances;
    end

    if instances[ playerNum ] then
        radioWindow = instances[ playerNum ];
        radioWindow:readFromObject( _player, _deviceObject );
        radioWindow:close()
    end
end

function ISRadioWindow:initialise()
    ISCollapsableWindow.initialise(self);
end

function ISRadioWindow:close()
	ISCollapsableWindow.close(self)
	if JoypadState.players[self.playerNum+1] then
		setJoypadFocus(self.playerNum, nil)
	end
end

function ISRadioWindow:addModule( _modulePanel, _moduleName, _enable, _width, _height, x, y)
    if not _width or not _height then
		return
	end
	
	local module = {};
    module.enabled = _enable;
    --module.panel = _modulePanel;
    --module.name = _moduleName;
    module.element = RWMElementRI:new (x, y, _width, _height, _modulePanel, _moduleName, self);
	module.element:setVisible(false)
    table.insert(self.modules, module);
    self:addChild(module.element);
end

function ISRadioWindow:createChildren()
    ISCollapsableWindow.createChildren(self);
    local th = self:titleBarHeight();



    --self:addModule(RWMSignal:new (0, 0, self.width, 0 ), "Signal", false);
    --self:addModule(RWMGeneral:new (0, 0, self.width, 0), getText("IGUI_RadioGeneral"), true);
    --self:addModule(RWMPower:new (0, 0, self.width, 0), getText("IGUI_RadioPower"), true);
    --self:addModule(RWMGridPower:new (0, 0, 22, 22), "", true, 22, 22);

    self:addModule(RWMMergedTV:new (0, 0, 189, 196), "", true, 189, 196, 54, 40);
	self:addModule(RWMMergedCarRadio:new (0, 0, 293, 78), "", true, 293, 78, 35, 30);
    self:addModule(RWMMergedRadio:new (0, 0, 227, 214), "", true, 227, 214, 20, 152);
    self:addModule(RWMMergedCDPlayer:new (0, 0, 232, 144), "", true, 232, 144, 14, 100);
    self:addModule(RWMMergedWalkieTalkie:new (0, 0, 75, 246), "", true, 75, 246, 26, 118);
	self:addModule(RWMMergedHAM:new (0, 0, 265, 190), "", true, 265, 190, 43, 30);

    --self:addModule(RWMSignal:new (0, 0, self.width, 0), getText("IGUI_RadioSignal"), true);
    --self:addModule(RWMVolume:new (0, 0, 100, 20), "", true, 100, 20);
    --self:addModule(RWMMicrophone:new (0, 0, self.width, 0), getText("IGUI_RadioMicrophone"), true);
    --self:addModule(RWMMedia:new (0, 0, self.width, 0 ), getText("IGUI_RadioMedia"), true);
    --self:addModule(RWMChannel:new (0, 0, self.width, 0 ), getText("IGUI_RadioChannel"), true);
    --self:addModule(RWMChannelTV:new (0, 0, self.width, 0 ), getText("IGUI_RadioChannel"), true);
	
end

local dist = 5;
function ISRadioWindow:update()
    ISCollapsableWindow.update(self);

    if self:getIsVisible() then

        if self.deviceData and self.deviceType == "VehiclePart" then
            local part = self.deviceData:getParent()
            if part and part:getItemType() and not part:getItemType():isEmpty() and not part:getInventoryItem() then
                self:close()
                return
            end
        end

        if self.deviceType and self.device and self.player and self.deviceData then		
            if self.deviceType=="InventoryItem" then -- incase of inventory item check if player has it in a hand
                if self.player:getPrimaryHandItem() == self.device or self.player:getSecondaryHandItem() == self.device  or self.player:getClothingItem_Back() == self.device then
                    return;
                end
            elseif self.deviceType == "IsoObject" or self.deviceType == "VehiclePart" then -- incase of isoobject check distance.
                if self.device:getSquare() and self.player:getX() > self.device:getX()-dist and self.player:getX() < self.device:getX()+dist and self.player:getY() > self.device:getY()-dist and self.player:getY() < self.device:getY()+dist then
                    return;
                end
            end
        end

    end

    if self.deviceData and self.deviceType=="InventoryItem" then        -- conveniently turn off radio when unequiped to prevent accidental loss of power.
        self.deviceData:setIsTurnedOn(false);
    end

    -- otherwise remove
    self:close();
    --self:clear();
    --self:removeFromUIManager();
end

function ISRadioWindow:prerender()
    self:stayOnSplitScreen();
    ISCollapsableWindow.prerender(self);
    local cnt = 0;
    --[[local ymod = self:titleBarHeight()+1;
    for i=1,#self.modules do
        if self.modules[i].enabled then
            self.modules[i].element:setY(ymod);
            ymod = ymod + self.modules[i].element:getHeight()+1;
        else
            self.modules[i].element:setVisible(false);
        end
    end]]--
    --self:setHeight(ymod);
	--print(self:titleBarHeight())
	--self:setHeight(self:titleBarHeight() + 282 + 1)
	--self:setHeight(self:titleBarHeight() + 397 + 1)
    --ISCollapsableWindow.prerender(self);
    --self:stayOnSplitScreen();
    --self:setJoypadPrompt();


	local nameD = self.title

	local function drawBG(img, x , y)
		if JoypadState.players[self.playerNum+1] then
			local prompt = getText("IGUI_RadioVolume") .. " / " .. getText("IGUI_RadioFrequency")
			local shiftX = getTextManager():MeasureStringX(UIFont.Large, prompt) + 100
			self:setWidth(math.max(x,shiftX)) 
			self:setHeight(self:titleBarHeight() + y + 32)
		else
			self:setWidth(x + 1)
			self:setHeight(self:titleBarHeight() + y + 1)
		end
		self:drawTexture(img, 0 , 0, x, y, 1, 1, 1, 1)
	end
	
	if self.deviceData then
	
		local function checkName(name)
			return nameD == getItemNameFromFullType(name)
		end

		if checkName("Radio.TvBlack") then drawBG(self.valutechTV, 282 , 282) return
		elseif checkName("Radio.TvWideScreen") then drawBG(self.premiumTV, 282 , 282) return
		elseif checkName("Radio.TvAntique") then drawBG(self.antiqueTV, 282 , 282) return
		elseif (instanceof(self.device, "VehiclePart") and "VehiclePart") then drawBG(self.carRadio, 365 , 140) return
		elseif checkName("Radio.RadioRed") then drawBG(self.premiumRadio, 270 , 386) return
		elseif checkName("Radio.RadioBlack") or checkName("Radio.RadioMakeShift") then drawBG(self.valutechRadio, 270 , 386) return
		elseif checkName("Base.CDplayer") then drawBG(self.playerCD, 257 , 257) return
		else
			local addName
			for i = 1, 6 do
				if i == 6 then addName = "MakeShift" else addName = i end
				if checkName("Radio.WalkieTalkie" .. addName) then drawBG(self.walkieTalkie, 123 , 384) return end
				if checkName("Radio.HamRadio" .. addName) then drawBG(self.RadioHAM, 352 , 251) return end
			end
		end
	
	end
end

function ISRadioWindow:stayOnSplitScreen()
    ISUIElement.stayOnSplitScreen(self, self.playerNum)
end

function ISRadioWindow:onMouseDownOutside(x, y)
	if x < 0 or y < 0 or x > self.width or y > self.height then
		self:close()
	end
end

function ISRadioWindow:render()
    --self:setJoypadPrompt();
	self:DPadPrompt()
    ISCollapsableWindow.render(self);
end

function ISRadioWindow:onLoseJoypadFocus(joypadData)
    self.drawJoypadFocus = false;
end

function ISRadioWindow:onGainJoypadFocus(joypadData)
    self.drawJoypadFocus = false;
	--self:focusNext();
end

function ISRadioWindow:close()
    ISCollapsableWindow.close(self);
    if JoypadState.players[self.playerNum+1] then
        if getFocusForPlayer(self.playerNum)==self or (self.subFocus and getFocusForPlayer(self.playerNum)==self.subFocus) then
            setJoypadFocus(self.playerNum, nil);
        end
    end
    self:removeFromUIManager();
    self:clear();
    self.subFocus = nil;
end

function ISRadioWindow:clear()
    self.drawJoypadFocus = false;
    self.player = nil;
    self.device = nil;
    self.deviceData = nil;
    self.deviceType = nil;
    self.hotKeyPanels = {};
    for i=1,#self.modules do
        self.modules[i].enabled = false;
        self.modules[i].element:clear();
    end
end

-- read from item/object and set modules
function ISRadioWindow:readFromObject( _player, _deviceObject )
    self:clear();
    self.player = _player;
    self.device = _deviceObject;

    if self.device then
        self.deviceType = (instanceof(self.device, "Radio") and "InventoryItem") or
            (instanceof(self.device, "IsoWaveSignal") and "IsoObject") or
            (instanceof(self.device, "VehiclePart") and "VehiclePart");
        if self.deviceType then
            self.deviceData = _deviceObject:getDeviceData();
            self.title = self.deviceData:getDeviceName();
        end
    end

    if (not self.player) or (not self.device) or (not self.deviceData) or (not self.deviceType) then
        self:clear();
        return;
    end

	local nameD = self.title
	
	local function enableModule(n)
		self.modules[n].enabled = true
		self.modules[n].element:setVisible(true)
		self.modules[n].element:readFromObject(self.player, self.device, self.deviceData, self.deviceType)
		self.hotKeyPanels = self.modules[n].element.subpanel
		for i=1,#self.modules do
			if i ~= n then
				self.modules[i].enabled = false
				self.modules[i].element:setVisible(false)
				self.modules[i].element:clear()
			end
		end
	end

	local function checkName(name)
		return nameD == getItemNameFromFullType(name)
	end

	if self.player and self.device and self.deviceData then
		if checkName("Radio.TvBlack") or checkName("Radio.TvWideScreen") or checkName("Radio.TvAntique") then enableModule(1) return
		elseif (instanceof(self.device, "VehiclePart") and "VehiclePart") then enableModule(2) return
		elseif checkName("Radio.RadioRed") or checkName("Radio.RadioBlack") or checkName("Radio.RadioMakeShift") then enableModule(3) return
		elseif checkName("Base.CDplayer") then enableModule(4) return
		else
			local addName
			for i = 1, 6 do
				if i == 6 then addName = "MakeShift" else addName = i end
				if checkName("Radio.WalkieTalkie" .. addName) then enableModule(5) return end
				if checkName("Radio.HamRadio" .. addName) then enableModule(6) return end
			end
		end
	end
end

--local interval = 20;
function ISRadioWindow:onJoypadDirUp()
    self.hotKeyPanels:onJoypadDirUp()
end

function ISRadioWindow:onJoypadDirDown()
    self.hotKeyPanels:onJoypadDirDown()
end

function ISRadioWindow:onJoypadDirLeft()
    self.hotKeyPanels:onJoypadDirLeft()
end

function ISRadioWindow:onJoypadDirRight()
    self.hotKeyPanels:onJoypadDirRight()
end

function ISRadioWindow:onJoypadDown(button)
    if button == Joypad.AButton then
		self.hotKeyPanels:onJoypadDown(button)
    elseif button == Joypad.BButton then
        self:close();
    elseif button == Joypad.YButton then
        self.hotKeyPanels:onJoypadDown(button)
    elseif button == Joypad.XButton then
        self.hotKeyPanels:onJoypadDown(button)
    elseif button == Joypad.LBumper then
        self.hotKeyPanels:onJoypadDown(button)
    elseif button == Joypad.RBumper then
		self.hotKeyPanels.parent = self
        self.hotKeyPanels:onJoypadDown(button)
    end
end

function ISRadioWindow:getAPrompt()

    return self.hotKeyPanels:getAPrompt()
end

function ISRadioWindow:getBPrompt()

    return getText("IGUI_RadioClose");
end

function ISRadioWindow:getXPrompt()
   return self.hotKeyPanels:getXPrompt()
end

function ISRadioWindow:getYPrompt()

	return self.hotKeyPanels:getYPrompt()
end

function ISRadioWindow:getLBPrompt()

	return self.hotKeyPanels:getLBPrompt()
end

function ISRadioWindow:getRBPrompt()

	return self.hotKeyPanels:getRBPrompt()
end

function ISRadioWindow:DPadPrompt()

	if JoypadState.players[self.playerNum+1] then
		self.hotKeyPanels:DPadPrompt()
	end
end

function ISRadioWindow:unfocusSelf()
    setJoypadFocus(self.playerNum, nil);
end

function ISRadioWindow:focusSelf()
    self.subFocus = nil;
    setJoypadFocus(self.playerNum, self);
end

function ISRadioWindow:isValidPrompt()
    return (self.player and self.device and self.deviceData)
end

function ISRadioWindow:focusNext(_up)
    --print("focus next ")
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

--hocus pocus set subfocus
function ISRadioWindow:setSubFocus( _newFocus )
    --print("subfocus "..tostring(_newFocus))
    if not _newFocus or not _newFocus.element then
        self:focusSelf();
    else
        self.subFocus = _newFocus;
        _newFocus.element:setFocus(self.playerNum, self);
    end
end

function ISRadioWindow:new (x, y, width, height, player)
    local o = {}
    --o.data = {}
    o = ISCollapsableWindow:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.player = player;
    o.playerNum = player:getPlayerNum();
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0};
    o.backgroundColor = {r=0, g=0, b=0, a=0};
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
    --o.viewList = {}
    o.resizable = false;
    o.drawFrame = true;

	o.valutechTV = getTexture("media/ui/TV_and_Radio/valutechTV.png")
	o.premiumTV = getTexture("media/ui/TV_and_Radio/premiumTV.png")
	o.antiqueTV = getTexture("media/ui/TV_and_Radio/antiqueTV.png")
	
	o.premiumRadio = getTexture("media/ui/TV_and_Radio/premiumRadio.png")
	o.valutechRadio = getTexture("media/ui/TV_and_Radio/valutechRadio.png")

	o.carRadio = getTexture("media/ui/TV_and_Radio/carRadio.png")
	o.playerCD = getTexture("media/ui/TV_and_Radio/playerCD.png")
	o.walkieTalkie = getTexture("media/ui/TV_and_Radio/walkieTalkie.png")
	o.RadioHAM = getTexture("media/ui/TV_and_Radio/RadioHAM.png")
	o.cacheName = nil

    o.device = nil;     -- item or object linked to panel
    o.deviceData = nil; -- deviceData
    o.modules = {};     -- table of modules to use
    o.overrideBPrompt = true;
    o.subFocus = nil;
    o.hotKeyPanels = {};
    o.isJoypadWindow = false;
    return o
end

function ISRadioWindow.onEquip( _player, _item)
    if _player == getPlayer() and instanceof(_item, "Radio") then
        ISRadioWindow.activate( _player, _item );
    end
end

Events.OnEquipPrimary.Add(ISRadioWindow.onEquip);
Events.OnEquipSecondary.Add(ISRadioWindow.onEquip);

--[[
local cnt = 0;
local tab = "    ";
function ISRadioWindow:updatetest()
    ISCollapsableWindow.update(self);

    cnt = cnt+1;
    if cnt > 60 then
        cnt = 0;
        if ISMouseDrag.dragging and #ISMouseDrag.dragging > 0 then
            print("MOUSE #######################################");
            for i,v in pairs(ISMouseDrag) do
                print(i,v);
            end
            print("MOUSE #######################################");
            for i3,v3 in ipairs(ISMouseDrag.dragging) do
                print(tab,i3,v3);
                if type( v3 ) == "table" then
                    for i4,v4 in pairs(v3) do
                        print(tab,tab,i4,v4);
                        if type( v4 ) == "table" then
                            for i5,v5 in pairs(v4) do
                                print(tab,tab,tab,i5,v5);
                            end
                        end
                    end
                end
            end
        end
    end
end
--]]
