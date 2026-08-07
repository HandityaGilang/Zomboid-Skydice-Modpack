-- **thank you** turbotutone

require "RadioCom/RadioWindowModules/RWMPanel"

RWMMergedTV = RWMPanel:derive("RWMMergedTV");

local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
--local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function RWMMergedTV:initialise()
    ISPanel.initialise(self)
end

function RWMMergedTV:createChildren()

	local function makeButton(bt)
		bt:initialise()
		bt.backgroundColor.a = 0
		bt.backgroundColorMouseOver = {r=0.15, g=0.15, b=0.15, a=0.5}
		bt.borderColor.a = 0
		--bt:setSound("activate", nil)
		self:addChild(bt)
	end

	self.volDown = ISButton:new(21, 133, 20, 20,"", self, RWMMergedTV.volUpOrDown);
	makeButton(self.volDown)
	
	self.volUp = ISButton:new(49, 133, 20, 20,"", self, RWMMergedTV.volUpOrDown);
	makeButton(self.volUp)

	self.channelUp = ISButton:new(77, 133, 20, 20,"", self, RWMMergedTV.doTuneInButton);
	makeButton(self.channelUp)
	
	self.channelDown = ISButton:new(105, 133, 20, 20,"", self, RWMMergedTV.doTuneInButton);
	makeButton(self.channelDown)

    self.toggleOnOffButton = ISButton:new(133, 133, 20, 20,"", self, RWMMergedTV.toggleOnOff);
	makeButton(self.toggleOnOffButton)

	self.slotVHS = ISButton:new(25, 173, 134, 24, "", self, RWMMergedTV.addMedia);
	makeButton(self.slotVHS)

	self.playMediaButton = ISButton:new(168, 175, 20, 20,"", self, RWMMergedTV.togglePlayMedia);
	makeButton(self.playMediaButton)

	
	self.volumeBar = ISVolumeBar:new(32, 100, 90, 28, RWMVolume.onVolumeChange, self);
    self.volumeBar:initialise();

	self.volumeBar.elBorderColor.a = 0;
	self.volumeBar.elBorderHighlightColor.a = 0;
	self.volumeBar.elHighlightColor.g = 0.7
	self.volumeBar.elHoverColor.g = 0.5
	self.volumeBar.elBackgroundColor = {r=0.5, g=0.5, b=0.5, a=0.7};

	self.volumeBar.mouseEnabled = false
	self.volumeBar.timer = 0
	self.volumeBar:setVisible(true)
    self:addChild(self.volumeBar);
end

--	turn on / off
function RWMMergedTV:toggleOnOff()

-- 	this is so players with a remote equipped can interact with televisions
	if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff",self.player, self.device ));
    end
end

-- volume +-
function RWMMergedTV:volUpOrDown(button)

	self.volumeBar:setVisible(self.deviceData:getIsTurnedOn())
	
	if button == self.volDown then
		self.volumeBar:setVolumeJoypad(false)
	elseif button == self.volUp then
		self.volumeBar:setVolumeJoypad(true)
	end

	self.volumeBar.timer = 1500
end

-- channel +-
function RWMMergedTV:doTuneInButton(button)
    
	if self.player and self.device then

		if button == self.channelUp then
			if self.channelSelected == self.channelMax then
				self.channelSelected = 0
			else
			self.channelSelected = self.channelSelected + 1
			end
		elseif button == self.channelDown then
			if self.channelSelected == 0 then
				self.channelSelected = self.channelMax
			else
			self.channelSelected = self.channelSelected - 1
			end
		end


		if self:doWalkTo() then
			local p = self.channels:get(self.channelSelected);
			ISTimedActionQueue.add(ISRadioAction:new("SetChannel",self.player, self.device, p:getFrequency() ));
		end
		
		self.nameTimer = 1500
	end
	
end

-- VHS
function RWMMergedTV:addMedia()

    local playerNum = self.player:getPlayerNum()
    local context = ISContextMenu.get(playerNum, self.slotVHS:getAbsoluteX(), self.slotVHS:getAbsoluteY())
	if self.deviceData:hasMedia() then
		context:addOption(getText("IGUI_media_removeMedia"), self, self.removeMedia, nil)
	else
		local inv = self.player:getInventory();
		local medias = {};
		local list = inv:FindAll("Base.VHS_Retail");
		for i=0,list:size()-1 do
			table.insert(medias, list:get(i));
		end

		local list = inv:FindAll("Base.VHS_Home");
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

function RWMMergedTV:addMediaAux(item)
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("AddMedia",self.player, self.device, item ));
    end
end

function RWMMergedTV:removeMedia()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("RemoveMedia",self.player, self.device ));
    end
end

function RWMMergedTV:togglePlayMedia()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("TogglePlayMedia",self.player, self.device ));
    end
end


function RWMMergedTV:chooseVideo()

	local function changeVideo(name)
		self.video = getTexture("media/videos/" .. name)
	end

	if self.deviceData then
		if self.deviceData:isPlayingMedia() then
			local media = self.deviceData:getMediaData()
			if media == nil then return end
			local title = media:getTitleEN()

			if title == "Exposure Survival" then changeVideo("TV_203_S.png") return
			elseif title == "Woodcraft" then changeVideo("TV_203_W.png") return
			elseif title == "The Cook Show" then changeVideo("TV_203_C.png") return
			elseif title == "Carzone" then changeVideo("VHS_CarZone.png") return
			end
			changeVideo("VHS_Noise.png")
		else
			if getGameTime():getWorldAgeHours() < 185 then
				local ch = self.deviceData:getChannel()
				if self.deviceData:isReceivingSignal() then
					if ch == 200 then changeVideo("TV_200.png") return
					elseif ch == 201 then changeVideo("TV_201.png") return
					elseif ch == 203 then
						local hour = getGameTime():getHour()
						if hour >= 18 then changeVideo("TV_203_S.png") return end
						if hour >= 12 then changeVideo("TV_203_W.png") return end
						if hour >= 6 then changeVideo("TV_203_C.png") return end
					elseif ch == 204 then changeVideo("TV_204.png") return
					elseif ch == 205 then changeVideo("TV_205.png") return
					end
				else
					changeVideo("TV_Ad.png") return
				end
			else
				changeVideo("TV_Static.png") return
			end
		end
	end
end

function RWMMergedTV:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
	RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType );
    self.volume = self.deviceData:getDeviceVolume();
	self.channels = self.deviceData:getDevicePresets():getPresets();
	
	self.channelMax = self.channels:size()-1
	
	for i = 0, self.channels:size()-1 do
		local p = self.channels:get(i);
		if p:getFrequency() == self.deviceData:getChannel() then
			self.channelSelected = i
		end
    end
	

	self.canMedia = self.deviceData:getDeviceName() ~= getItemNameFromFullType("Radio.TvAntique")
	self.slotVHS:setVisible(self.canMedia)
	self.playMediaButton:setVisible(self.canMedia)
	
    self.volumeBar:setVolume(math.floor(self.volume*self.volumeBar:getVolumeSteps()));
	--[[if _deviceData:getIsBatteryPowered() then
        return false;
    end]]--
    return RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType );
end

function RWMMergedTV:update()
    ISPanel.update(self);

	if self.deviceData then
        self.volumeBar:setEnableControls(self.deviceData:getIsTurnedOn());
        local devVol = self.deviceData:getDeviceVolume()+0.05; --hack for decimal/float precision thingy
        self.volumeBar:setVolume(math.floor(devVol*self.volumeBar:getVolumeSteps()));
		
		if self.deviceData:getIsTurnedOn() then
			self:chooseVideo()
		end
    end

	if self.volumeBar.timer > 0 then
        self.volumeBar.timer = self.volumeBar.timer - UIManager.getMillisSinceLastUpdate();
    else
		self.volumeBar:setVisible(false)
    end

	if self.nameTimer > 0 then
		self.nameTimer = self.nameTimer - UIManager.getMillisSinceLastUpdate();
	end
end

function RWMMergedTV:prerender()

	if self.deviceData and self.deviceData:getIsTurnedOn() then
		self:drawTexture(self.video, 7, 6, 160, 120, 1, 1, 1, 1);
	end

    ISPanel.prerender(self);
end


function RWMMergedTV:render()

	if self.deviceData then
		if self.deviceData:hasMedia() then
			self:drawTexture(self.imageVHS, 27, 173, 129, 24, 1, 1, 1, 1)
		end
		
		if self.deviceData:getIsTurnedOn() then
			if self.nameTimer > 0 then
				local ch = self.channels:get(self.channelSelected)
				self:drawText(ch:getName(), 10, 10, 0.4, 1 ,0.4 , 0.9, self.font);
			end
		end
	end

    ISPanel.render(self);
end

function RWMMergedTV:clear()
    RWMPanel.clear(self);
end


function RWMMergedTV:onBumperContext()

	local playerNum = self.player:getPlayerNum()
	local inventory = self.player:getInventory()
    local context = ISContextMenu.get(playerNum, self.slotVHS:getAbsoluteX(), self.slotVHS:getAbsoluteY())
	
	if self.deviceData:hasMedia() then
		context:addOption(getText("IGUI_media_removeMedia"), self, self.removeMedia, nil)
	else
		local medias = {};
		local list = inventory:FindAll("Base.VHS_Retail");
		for i=0,list:size()-1 do
			table.insert(medias, list:get(i));
		end

		local list = inventory:FindAll("Base.VHS_Home");
		for i=0,list:size()-1 do
			table.insert(medias, list:get(i));
		end
		
		if #medias>0 then
			for _,item in ipairs(medias) do
				context:addOption(item:getDisplayName(), self, self.addMediaAux, item)
			end
		end	
	end

	if context.numOptions < 2 then return end
	
	context.origin = self.parent
	context.mouseOver = 1
	setJoypadFocus(playerNum, context)
end

function RWMMergedTV:onJoypadDown(button)

    if button == Joypad.AButton then
		self:toggleOnOff()
	elseif button == Joypad.BButton then
		return
    elseif button == Joypad.YButton then
		self:doTuneInButton(self.channelUp)
    elseif button == Joypad.XButton and self.canMedia then
		self:togglePlayMedia()
    elseif button == Joypad.LBumper then
		return
    elseif button == Joypad.RBumper then
		self:onBumperContext()
    end
end

function RWMMergedTV:onJoypadDirUp()

	return
end

function RWMMergedTV:onJoypadDirDown()

	return
end

function RWMMergedTV:onJoypadDirLeft()

	self:volUpOrDown(self.volDown)
end

function RWMMergedTV:onJoypadDirRight()

	self:volUpOrDown(self.volUp)
end


function RWMMergedTV:DPadPrompt()

	local prompt = getText("IGUI_RadioVolume")
	local offset = (50 - FONT_HGT_LARGE) / 2

	self:drawTexture(Joypad.Texture.DPad, 0, self.height + 29, 1, 1, 1, 1)
	self:drawText(prompt, 42, self.height + 20 + offset, 1, 1, 1, 1, UIFont.Large)
end

function RWMMergedTV:getAPrompt()

	if self.deviceData:getIsTurnedOn() then
        return getText("ContextMenu_Turn_Off")
    else
        return getText("ContextMenu_Turn_On")
    end
end

function RWMMergedTV:getBPrompt()
    return nil;
end

function RWMMergedTV:getXPrompt()

	if self.canMedia then
		if self.deviceData:isPlayingMedia() then
			return getText("IGUI_media_stop")
		else
			return getText("IGUI_media_play")
		end
	end
end

function RWMMergedTV:getYPrompt()

	return getText("IGUI_RadioSelectChannel")
end

function RWMMergedTV:getLBPrompt()

	return nil;
end

function RWMMergedTV:getRBPrompt()
	
	return getText("IGUI_DeviceOptions")
end


function RWMMergedTV:new (x, y, width, height)
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

	o.canMedia = false
	o.video = getTexture("media/ui/TV_and_Radio/TV_Static.png")
	o.imageVHS = getTexture("media/ui/TV_and_Radio/VHS.png")
	o.noSignal = getTexture("media/ui/TV_and_Radio/noSignal.png")
	o.font = UIFont.Code
	o.nameTimer = 0
    return o
end

