-- **thank you** turbotutone

require "RadioCom/RadioWindowModules/RWMPanel"

RWMMergedCDPlayer = RWMPanel:derive("RWMMergedCDPlayer");

local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

function RWMMergedCDPlayer:initialise()
    ISPanel.initialise(self)
end

function RWMMergedCDPlayer:createChildren()

	local function makeButton(bt)
		bt:initialise()
		bt.backgroundColor.a = 0
		bt.backgroundColorMouseOver.a = 0
		bt.borderColor.a = 0
		bt.textColor = {r=0, g=0, b=0, a=0.7};
		--bt:setSound("activate", nil)
		self:addChild(bt)
	end

	self.toggleOnOffButton = ISButton:new(73, 95, 33, 21,"", self, RWMMergedCDPlayer.toggleOnOff);
	makeButton(self.toggleOnOffButton)
	
	self.volDown = ISButton:new(122, 95, 33, 21,"", self, RWMMergedCDPlayer.volUpOrDown);
	makeButton(self.volDown)
	
	self.volUp = ISButton:new(154, 69, 33, 21,"", self, RWMMergedCDPlayer.volUpOrDown);
	makeButton(self.volUp)

	self.batteryLid = ISButton:new(88, 130, 52, 13,"",self, RWMMergedCDPlayer.contextMenuBattery);
	makeButton(self.batteryLid)	
	
	self.headphonesPort = ISButton:new(220, 19, 12, 19,"",self, RWMMergedCDPlayer.showHeadphonesContext);
	makeButton(self.headphonesPort)
	self.headphonesPort.backgroundColorMouseOver.a = 0
	
	self.slotCD = ISButton:new(0, 0, 13, 55, "", self, RWMMergedCDPlayer.addMedia);
	makeButton(self.slotCD)

	self.playMediaButton = ISButton:new(41, 69, 33, 21,"",self, RWMMergedCDPlayer.togglePlayMedia);
	makeButton(self.playMediaButton)
	
	self.volumeBar = ISVolumeBar:new(0, 146, 80, 20, RWMMergedCDPlayer.onVolumeChange, self);
    self.volumeBar:initialise();
	self.volumeBar.elBorderColor.a = 0
	self.volumeBar.elBorderHighlightColor.a = 0
	self.volumeBar.elBackgroundColor.a = 0
	self.volumeBar.elHighlightColor.a = 0
	self.volumeBar.elHoverColor.a = 0
	self.volumeBar.greyCol.a = 0
	self.volumeBar.mouseEnabled = false
	self.volumeBar.timer = 0
	self.volumeBar:setVisible(true)
	self.volumeBar.getVolumeFromXPosition = self.getVolumeFromXPosition
    self:addChild(self.volumeBar);
end

function RWMMergedCDPlayer:toggleOnOff()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff",self.player, self.device ));
    end
end

function RWMMergedCDPlayer:volUpOrDown(button)

	if self.deviceData:getIsTurnedOn() then
		if button == self.volDown then
			self.volumeBar:setVolumeJoypad(false)
		elseif button == self.volUp then
			self.volumeBar:setVolumeJoypad(true)
		end
	end
end

function RWMMergedCDPlayer:onVolumeChange( _newVol )

    self.volume = _newVol/self.volumeBar:getVolumeSteps();

    if self.deviceData then
        if self:doWalkTo() then
			ISTimedActionQueue.add(ISRadioAction:new("SetVolume",self.player, self.device, self.volume ));
        end
    end
end

-- fixed to not glitch to max volume when dragging
--[[
function RWMMergedCDPlayer:getVolumeFromXPosition( _x )

	local step = 1

	if _x <=0 then
	elseif _x >= self.width then
		step = self.volumeSteps
	else
		local cellwidth = (self.width / self.volumeSteps)
		step = math.ceil(_x/cellwidth)
	end
	
	return step
end
]]--

-- CD
function RWMMergedCDPlayer:addMedia()

    local playerNum = self.player:getPlayerNum()

    local context = ISContextMenu.get(playerNum, self.slotCD:getAbsoluteX(), self.slotCD:getAbsoluteY())
	if self.deviceData:hasMedia() then
		context:addOption(getText("IGUI_media_removeMedia"), self, self.removeMedia, nil)
	else
		local inv = self.player:getInventory()
		local medias = {}
	
		local list = inv:FindAll("Base.Disc_Retail")
		for i=0,list:size()-1 do
			table.insert(medias, list:get(i));
		end

		if #medias>0 then
			for _,item in ipairs(medias) do
				context:addOption(item:getDisplayName(), self, self.addMediaAux, item)
			end
			context.mouseOver = 1
			if JoypadState.players[playerNum+1] then
				context.origin = JoypadState.players[playerNum+1].focus
				setJoypadFocus(playerNum, context)
			end
		end
	end
end

function RWMMergedCDPlayer:addMediaAux(item)
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("AddMedia",self.player, self.device, item ))
    end
end

function RWMMergedCDPlayer:removeMedia()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("RemoveMedia",self.player, self.device ))
    end
end

function RWMMergedCDPlayer:togglePlayMedia()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("TogglePlayMedia",self.player, self.device ))
    end
end

-- Battery
function RWMMergedCDPlayer:contextMenuBattery()

	local playerNum = self.player:getPlayerNum()
    local context = ISContextMenu.get(playerNum, self.batteryLid:getAbsoluteX(), self.batteryLid:getAbsoluteY())
	if self.deviceData:getHasBattery() then
		local currentPower = string.format("%.i", self.deviceData:getPower() * 100)
		context:addOption(getText("ContextMenu_Remove_Battery").. " " .. currentPower  .. "%", self, self.removeBattery, nil)
	else
		local inventory = self.player:getInventory()
		local batteries = inventory:FindAll("Base.Battery")
		if batteries:size() ~= 0 then
			context:addOption(getText("ContextMenu_AddBattery"), self, self.addBattery, nil)
		end
	end
end

function RWMMergedCDPlayer:addBattery()

		local inventory = self.player:getInventory()
		local list = inventory:FindAll("Base.Battery")
		local batTable = {}
		if list and list:size()>0 then
			
			for i=0,list:size()-1 do
				table.insert(batTable, list:get(i))
			end
		end

		local item;
		local pbuff = 0;

		for _,i in ipairs(batTable) do
			if i:getDelta() > pbuff then
				item = i;
				pbuff = i:getDelta()
			end
		end

		if item then
			if self:doWalkTo() then
				ISTimedActionQueue.add(ISRadioAction:new("AddBattery",self.player, self.device, item ))
				if self.volume ~= 0.1 then
					ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff",self.player, self.device ));
				end
			end
		end
end

function RWMMergedCDPlayer:removeBattery()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("RemoveBattery",self.player, self.device ));
    end
end

-- Headphones
function RWMMergedCDPlayer:showHeadphonesContext()
	local playerNum = self.player:getPlayerNum()
    local context = ISContextMenu.get(playerNum, self.headphonesPort:getAbsoluteX() + self.headphonesPort.width / 2, self.headphonesPort:getAbsoluteY() + self.headphonesPort.height * 0.8)
	if self.deviceData:getHeadphoneType() >= 0 then
		context:addOption(getText("IGUI_RadioRemoveHeadphones"), self, self.removeHeadphone, nil)
	else
		local inventory = self.player:getInventory()
		local headphones = inventory:FindAll("Base.Headphones")
		local earbuds = inventory:FindAll("Base.Earbuds")
		if headphones:size() + earbuds:size() ~= 0 then
			context:addOption(getText("IGUI_RadioAddHeadphones"), self, self.addHeadphone, nil)
		end
	end
end

function RWMMergedCDPlayer:addHeadphone()

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
   
	local item;
    local pbuff = 0;

    for _,i in ipairs(tab) do
            item = i;
        break;
    end

    if item then
        if self:doWalkTo() then
            ISTimedActionQueue.add(ISRadioAction:new("AddHeadphones",self.player, self.device, item ));
        end
    end
end

function RWMMergedCDPlayer:removeHeadphone()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("RemoveHeadphones",self.player, self.device ));
    end
end










-- READ FROM OBJECT
function RWMMergedCDPlayer:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
	RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType );

-- set volume
	if not self.deviceData:getIsTurnedOn() then
		self.deviceData:setDeviceVolume(0.1)
	end
		

	self.volume = self.deviceData:getDeviceVolume()
    self.volumeBar.volume = math.floor(self.volume*self.volumeBar:getVolumeSteps())
	self.volumeBar.hoverVolume = self.volumeBar.volume
    return RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType )
end

-- UPDATE
function RWMMergedCDPlayer:update()
    ISPanel.update(self);

	if self.deviceData then
		
	--local devVol = self.deviceData:getDeviceVolume()+0.05;
    --self.volumeBar:setVolume(math.floor(devVol*self.volumeBar:getVolumeSteps()));
    end
end

function RWMMergedCDPlayer:prerender()
    ISPanel.prerender(self);
end

-- RENDER
function RWMMergedCDPlayer:render()

	if self.deviceData then

		if self.deviceData:getIsTurnedOn() then

			local currentPower = string.format("%.i", self.deviceData:getPower() * 100)

			self:drawText(currentPower, 46, 16, 0,0,0,0.5, self.font);
			
			
			local volX = self.volumeBar.hoverVolume * 4
			self:drawRect(28, 32, volX, 9, 0.5, 0, 0, 0)

			self:drawTexture(self.playerVolume, 28, 32, 41, 9, 1, 1, 1, 1)
			
			if self.deviceData:hasMedia() then
				self:drawTexture(self.playerMediaIcon, 28, 18, 15, 15, 1, 1, 1, 1)
			end
		end
		
	end
    ISPanel.render(self);
end

function RWMMergedCDPlayer:clear()
    RWMPanel.clear(self);
end



function RWMMergedCDPlayer:onBumperContext()

	local playerNum = self.player:getPlayerNum()
	local inventory = self.player:getInventory()
    local context = ISContextMenu.get(playerNum, self.batteryLid:getAbsoluteX(), self.batteryLid:getAbsoluteY())
	
	if self.deviceData:getHasBattery() then
		local currentPower = string.format("%.i", self.deviceData:getPower() * 100)
		context:addOption(getText("ContextMenu_Remove_Battery").. " " .. currentPower  .. "%", self, self.removeBattery, nil)
	else
		local batteries = inventory:FindAll("Base.Battery")
		if batteries:size() ~= 0 then
			context:addOption(getText("ContextMenu_AddBattery"), self, self.addBattery, nil)
		end
	end

	if self.deviceData:getHeadphoneType() >= 0 then
		context:addOption(getText("IGUI_RadioRemoveHeadphones"), self, self.removeHeadphone, nil)
	else
		local headphones = inventory:FindAll("Base.Headphones")
		local earbuds = inventory:FindAll("Base.Earbuds")
		if headphones:size() + earbuds:size() ~= 0 then
			context:addOption(getText("IGUI_RadioAddHeadphones"), self, self.addHeadphone, nil)
		end
	end
	
	if self.deviceData:hasMedia() then
		context:addOption(getText("IGUI_media_removeMedia"), self, self.removeMedia, nil)
	else
		local medias = {}
		
		local list = inventory:FindAll("Base.Disc_Retail")
		for i=0,list:size()-1 do
			table.insert(medias, list:get(i));
		end

		if #medias>0 then
			for _,item in ipairs(medias) do
				context:addOption("+" .. item:getDisplayName(), self, self.addMediaAux, item)
			end
		end
	end
	
	if context.numOptions < 2 then return end
	
	context.origin = self.parent
	context.mouseOver = 1
	setJoypadFocus(playerNum, context)
end

function RWMMergedCDPlayer:onJoypadDown(button)

    if button == Joypad.AButton then
		self:toggleOnOff()
	elseif button == Joypad.BButton then
		return
    elseif button == Joypad.YButton then
		return
    elseif button == Joypad.XButton then
		self:togglePlayMedia()
    elseif button == Joypad.LBumper then
		return
    elseif button == Joypad.RBumper then
		self:onBumperContext()
    end
end

function RWMMergedCDPlayer:onJoypadDirUp()

	return nil;
end

function RWMMergedCDPlayer:onJoypadDirDown()

    return nil;
end

function RWMMergedCDPlayer:onJoypadDirLeft()

	self:volUpOrDown(self.volDown)
end

function RWMMergedCDPlayer:onJoypadDirRight()

	self:volUpOrDown(self.volUp)
end


function RWMMergedCDPlayer:DPadPrompt()

	local prompt = getText("IGUI_RadioVolume")
	local offset = (50 - FONT_HGT_LARGE) / 2

	self:drawTexture(Joypad.Texture.DPad, 0, self.height + 29, 1, 1, 1, 1)
	self:drawText(prompt, 42, self.height + 20 + offset, 1, 1, 1, 1, UIFont.Large)
end

function RWMMergedCDPlayer:getAPrompt()

	if self.deviceData:getIsTurnedOn() then
        return getText("ContextMenu_Turn_Off")
    else
        return getText("ContextMenu_Turn_On")
    end
end

function RWMMergedCDPlayer:getBPrompt()
    return nil;
end

function RWMMergedCDPlayer:getXPrompt()

	if self.deviceData:isPlayingMedia() then
		return getText("IGUI_media_stop")
	else
		return getText("IGUI_media_play")
	end
end

function RWMMergedCDPlayer:getYPrompt()

	return nil;
end

function RWMMergedCDPlayer:getLBPrompt()

	return nil;
end

function RWMMergedCDPlayer:getRBPrompt()
	
	return getText("IGUI_DeviceOptions")
end


function RWMMergedCDPlayer:new (x, y, width, height)
    local o = RWMPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.x = x;
    o.y = y;
    o.background = true;
    o.backgroundColor.a = 0
    o.borderColor.a = 0
    o.width = width;
    o.height = height;
    o.anchorLeft = true;
    o.anchorRight = false;
    o.anchorTop = true;
    o.anchorBottom = false;

	o.playerMediaIcon = getTexture("media/ui/TV_and_Radio/playerMediaIcon.png")
	o.playerVolume = getTexture("media/ui/TV_and_Radio/playerVolume.png")
	o.font = UIFont.Code
    return o
end

