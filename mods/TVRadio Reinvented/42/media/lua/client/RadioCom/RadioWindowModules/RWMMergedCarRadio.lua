-- **thank you** turbotutone

require "RadioCom/RadioWindowModules/RWMPanel"

RWMMergedCarRadio = RWMPanel:derive("RWMMergedCarRadio");

local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

function RWMMergedCarRadio:initialise()
    ISPanel.initialise(self)
end

function RWMMergedCarRadio:createChildren()

	local function makeButton(bt)
		bt:initialise()
		bt.backgroundColor.a = 0
		bt.backgroundColorMouseOver.a = 0
		bt.borderColor.a = 0
		bt.textColor = {r=0, g=0, b=0, a=0.7};
		--bt:setSound("activate", nil)
		self:addChild(bt)
	end

	self.toggleOnOffButton = ISButton:new(0, 0, 31, 12,"",self, RWMMergedCarRadio.toggleOnOff);
	makeButton(self.toggleOnOffButton)
	self.toggleOnOffButton.backgroundColorMouseOver = {r=0.15, g=0.15, b=0.15, a=0.5}

	self.channelUp = ISButton:new(18, 21, 19, 18,"", self, RWMMergedCarRadio.doTuneInButton);
	makeButton(self.channelUp)
	
	self.channelDown = ISButton:new(18, 56, 19, 17,"",self, RWMMergedCarRadio.doTuneInButton);
	makeButton(self.channelDown)	

	self.volDown = ISButton:new(2, 39, 18, 17,"", self, RWMMergedCarRadio.volUpOrDown);
	makeButton(self.volDown)
	
	self.volUp = ISButton:new(35, 39, 19, 17,"", self, RWMMergedCarRadio.volUpOrDown);
	makeButton(self.volUp)

	self.tuneWheel = ISButton:new(230, 16, 60, 60,"",self, nil);
	makeButton(self.tuneWheel)
	self.tuneWheel.backgroundColorMouseOver.a = 0
	self.tuneWheel.onMouseMove = self.turning

	self.slotCD = ISButton:new(38, 0, 219, 13, "", self, RWMMergedCarRadio.addMedia);
	makeButton(self.slotCD)
	self.slotCD.backgroundColor.a = 0.2
	self.slotCD.backgroundColorMouseOver.a = 0

	self.playMediaButton = ISButton:new(262, 0, 31, 13,"",self, RWMMergedCarRadio.togglePlayMedia);
	makeButton(self.playMediaButton)
	self.playMediaButton.backgroundColorMouseOver = {r=0.15, g=0.15, b=0.15, a=0.5}

	self.addPreset = ISButton:new(113, 15, 42, 12,"",self, RWMMergedCarRadio.doAddPreset);
	makeButton(self.addPreset)
	self.addPreset.textColor.a = 0.7
	self.addPreset.backgroundColorMouseOver.a = 0
	
	self.deletePreset = ISButton:new(155, 15, 42, 12,"",self, RWMMergedCarRadio.doDeletePreset);
	makeButton(self.deletePreset)
	self.deletePreset.textColor.a = 0.7
	self.deletePreset.backgroundColorMouseOver.a = 0
	
	self.volumeBar = ISVolumeBar:new(126, 48, 100, 14, RWMMergedCarRadio.onVolumeChange, self);
    self.volumeBar:initialise();
	self.volumeBar.elBorderColor.a = 0
	self.volumeBar.elBorderHighlightColor.a = 0
	self.volumeBar.elBackgroundColor.a = 0 --{r = 0.74, g = 0.19, b = 0.17, a = 1}
	self.volumeBar.elHighlightColor.a = 0
	self.volumeBar.elHoverColor.a = 0
	self.volumeBar.greyCol.a = 0
	self.volumeBar.mouseEnabled = false
	self.volumeBar:setVisible(true)
	self.volumeBar.getVolumeFromXPosition = self.getVolumeFromXPosition
    self:addChild(self.volumeBar);
end

function RWMMergedCarRadio:toggleOnOff()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff",self.player, self.device ));
    end
end

-- volume
function RWMMergedCarRadio:volUpOrDown(button)

	if self.deviceData:getIsTurnedOn() then
		if button == self.volDown then
			self.volumeBar:setVolumeJoypad(false)
		elseif button == self.volUp then
			self.volumeBar:setVolumeJoypad(true)
		end
	end
end

function RWMMergedCarRadio:onVolumeChange( _newVol )

    self.volume = _newVol/self.volumeBar:getVolumeSteps();

    if self.deviceData then
        if self:doWalkTo() then
			if self.deviceData:getIsTurnedOn() then
				ISTimedActionQueue.add(ISRadioAction:new("SetVolume", self.player, self.device, self.volume ));
			end
        end
    end
end

-- fixed to not glitch to max volume when dragging
function RWMMergedCarRadio:getVolumeFromXPosition( _x )

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

-- presets
function RWMMergedCarRadio:doTuneInButton(button)

	if self.player and self.device and #self.presetsList.frequency > 1 then

		local list = self.presetsList.frequency
		local f = self.tuneWheel.frequency.done
		local fNew

		if button == self.channelUp then
			for _, v in ipairs(list) do
				if v > f then fNew = v break end
			end
		else
			for _, v in ipairs(list) do
				if v < f then fNew = v end
			end
		end

		if fNew == nil then
			if f >= list[#list] then fNew = list[1] else fNew = list[#list] end
		end

		if self:doWalkTo() then
			self.tuneWheel.frequency.done = fNew
			self.tuneWheel.frequency.add = fNew
			self.deviceData:setChannel(self.tuneWheel.frequency.done)
		end
	end
end

function RWMMergedCarRadio:doAddPreset()

	local p = self.presetsList

	if #p.frequency < self.deviceData:getDevicePresets():getMaxPresets() then
	
		local newName

		for i=1, 10 do
			if self.userPreset[i] ~= self.usedNames[i] then
				newName = "Channel " .. self.userPreset[i]
				self.usedNames[i] = self.userPreset[i]
				break
			end
		end

		if p.frequency[p.selected] ~= self.tuneWheel.frequency.done then
			table.insert(p.name, newName)
			table.insert(p.frequency, self.tuneWheel.frequency.done)
			self.presets:add(PresetEntry.new(newName, self.tuneWheel.frequency.done))
		end

		if self.deviceData then
			self.deviceData:transmitPresets()
		end
	end
end

function RWMMergedCarRadio:doDeletePreset()

	local p = self.presetsList

	if p.frequency[p.selected] == self.tuneWheel.frequency.done then

		for i=1, 10 do
			if p.name[p.selected] == "Channel " .. self.userPreset[i] then
				self.usedNames[i] = nil
				break
			end
		end

		local toDelete

		for i = 0, self.presets:size()-1 do
			local pSet = self.presets:get(i)
			local pFq = pSet:getFrequency()

			if pFq == p.frequency[p.selected] then
				toDelete = pSet
			end
		end
		print(p.name[p.selected])

		table.remove(p.name, p.selected)
		table.remove(p.frequency, p.selected)
		self.presets:remove(toDelete);
	end

	if self.deviceData then
		self.deviceData:transmitPresets();
	end
end

-- CD
function RWMMergedCarRadio:addMedia()

	local inv = self.player:getInventory()
	local medias = {}
	
	local list = inv:FindAll("Base.Disc_Retail")
	for i=0,list:size()-1 do
		table.insert(medias, list:get(i));
	end

    local playerNum = self.player:getPlayerNum()

    local context = ISContextMenu.get(playerNum, self.slotCD:getAbsoluteX(), self.slotCD:getAbsoluteY())
	if self.deviceData:hasMedia() then
		context:addOption(getText("IGUI_media_removeMedia"), self, self.removeMedia, nil)
	end

if #medias>0 then
    for _,item in ipairs(medias) do
        context:addOption(item:getDisplayName(), self, self.addMediaAux, item)
    end
end

    context.mouseOver = 1
    if JoypadState.players[playerNum+1] then
        context.origin = JoypadState.players[playerNum+1].focus
        setJoypadFocus(playerNum, context)
    end
end

function RWMMergedCarRadio:addMediaAux(item)
    if self:doWalkTo() then
        --ISTimedActionQueue.add(ISRadioAction:new("AddMedia",self.player, self.device, item ))
		ISTimedActionQueue.add(ISDeviceMediaAction:new(self.player, false, item, ISDeviceBatteryAction:getDeviceDataParameter(self.player, self.device, self.deviceType) ));
    end
end

function RWMMergedCarRadio:removeMedia()
    if self:doWalkTo() then
        --ISTimedActionQueue.add(ISRadioAction:new("RemoveMedia",self.player, self.device ))
		ISTimedActionQueue.add(ISDeviceMediaAction:new(self.player, true, nil, ISDeviceBatteryAction:getDeviceDataParameter(self.player, self.device, self.deviceType) ));
    end
end

function RWMMergedCarRadio:togglePlayMedia()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("TogglePlayMedia",self.player, self.device ))
    end
end

-- Wheel
function RWMMergedCarRadio:turning(dx, dy)
--  replaces self.tuneWheel.onMouseMove

	if self.pressed == true then

		local xx = self:getMouseX()
		local yy = self:getMouseY()
		local half = self.width / 2
		local dir = 1

		if xx > half then
			if yy > half then dir = -1 end
		else
			if yy > half then dir = -1 end
		end

		self.frequency.add = self.frequency.add + dx * 25 * dir
		local f = self.frequency

		if f.add > f.max then f.add = f.min end
		if f.add < f.min then f.add = f.max end

		if f.add / 100 / string.format("%.i", f.add / 100)  == 1 then
			self.frequency.done = f.add
		end
	end
	self.mouseOver = self:isMouseOver();
end










-- READ FROM OBJECT
function RWMMergedCarRadio:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
	RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType );

-- wheel
	self.tuneWheel.frequency = {max, min, done, add}
	local f = self.tuneWheel.frequency
	f.max = self.deviceData:getMaxChannelRange()
	f.min = self.deviceData:getMinChannelRange()
	f.done = self.deviceData:getChannel()
	f.add = self.tuneWheel.frequency.done

-- cache presets
	self.presets = self.deviceData:getDevicePresets():getPresets()
	local presetsTemp = self.presets
	local notSorted = {}
	self.presetsList = {name = {}, frequency = {}, preset = {}, selected = 1}

	for i = 0, presetsTemp:size()-1 do
		local p = presetsTemp:get(i)
		notSorted[p:getFrequency()] = p:getName()
		table.insert(self.presetsList.frequency, i+1, p:getFrequency())
    end

	table.sort(self.presetsList.frequency)

	for k, v in ipairs(self.presetsList.frequency) do
		self.presetsList.name[k] = notSorted[v]
	end

-- check CD
	self.canMedia = self.deviceData:getDeviceName() == getItemNameFromFullType("Base.RadioRed")
	self.slotCD:setVisible(self.canMedia)
	self.playMediaButton:setVisible(self.canMedia)

-- set volume
	self.volume = self.deviceData:getDeviceVolume()
    self.volumeBar.volume = math.floor(self.volume*self.volumeBar:getVolumeSteps())
	self.volumeBar.hoverVolume = self.volumeBar.volume
    return RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType )
end

-- UPDATE
function RWMMergedCarRadio:update()
    ISPanel.update(self);

	if self.deviceData then
-- check wheel
		if self.tuneWheel.pressed then
			self.deviceData:setChannel(self.tuneWheel.frequency.done)
		end

-- check channel
		for k, v in ipairs(self.presetsList.frequency) do
			if self.tuneWheel.frequency.done == v then
				self.presetsList.selected = k
				break
			end
		end
	--local devVol = self.deviceData:getDeviceVolume()+0.05;
    --self.volumeBar:setVolume(math.floor(devVol*self.volumeBar:getVolumeSteps()));
    end
end

function RWMMergedCarRadio:prerender()
    ISPanel.prerender(self);
end

-- RENDER
function RWMMergedCarRadio:render()

	if self.canMedia then
		self:drawTexture(self.carCD, 37, -3, 1, 1, 1, 1)
	end

	if self.deviceData and self.deviceData:getIsTurnedOn()then
-- volume
		local volX = self.volumeBar.hoverVolume * 9
		self:drawRect(134, 48, volX, 10, 1, 0.74, 0.19, 0.17)
		self:drawTexture(self.carVolume, 134, 48, 90, 10, 1, 1, 1, 1)

-- frequency
		local currentFrequency = string.format("%.1f", self.tuneWheel.frequency.done / 1000)
		self:drawText(currentFrequency .. " MHz", 72, 44, 0.74, 0.19, 0.17, 1, self.font);

-- channel name
		if self.tuneWheel.frequency.done == self.presetsList.frequency[self.presetsList.selected] then
			local channelName = self.presetsList.name[self.presetsList.selected]
			if channelName == "Automated Emergency Broadcast System" then channelName = "Automated Broadcast" end
			self:drawText(channelName, 71, 31, 0.74, 0.19, 0.17, 1, self.font);
		end
	end
    ISPanel.render(self);
end

function RWMMergedCarRadio:clear()
    RWMPanel.clear(self);
end


function RWMMergedCarRadio:onBumperContext()

	local playerNum = self.player:getPlayerNum()
	local inventory = self.player:getInventory()
    local context = ISContextMenu.get(playerNum, self.toggleOnOffButton:getAbsoluteX(), self.toggleOnOffButton:getAbsoluteY())
	
	if self.canMedia then
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
	end
	
	if context.numOptions < 2 then return end
	
	context.origin = self.parent
	context.mouseOver = 1
	setJoypadFocus(playerNum, context)
end

function RWMMergedCarRadio:onJoypadDown(button)

    if button == Joypad.AButton then
		self:toggleOnOff()
	elseif button == Joypad.BButton then
		return
    elseif button == Joypad.YButton then
		self:doTuneInButton(self.channelUp)
    elseif button == Joypad.XButton and self.canMedia then
		self:togglePlayMedia()
    elseif button == Joypad.LBumper then

		if self.tuneWheel.frequency.done == self.presetsList.frequency[self.presetsList.selected] then
			self:doDeletePreset()
		else
			self:doAddPreset()
		end
		
    elseif button == Joypad.RBumper then
		self:onBumperContext()
    end
end

function RWMMergedCarRadio:onJoypadDirUp()

	local f = self.tuneWheel.frequency
	
	f.done = f.done + 200
	
	if f.done > f.max then f.done = f.min end
	f.add = f.done
	self.deviceData:setChannel(f.done)
end

function RWMMergedCarRadio:onJoypadDirDown()

    local f = self.tuneWheel.frequency

    f.done = f.done - 200
	
	if f.done < f.min then f.done = f.max end
	f.add = f.done
	self.deviceData:setChannel(f.done)
end

function RWMMergedCarRadio:onJoypadDirLeft()

	self:volUpOrDown(self.volDown)
end

function RWMMergedCarRadio:onJoypadDirRight()

	self:volUpOrDown(self.volUp)
end


function RWMMergedCarRadio:DPadPrompt()

	local prompt = getText("IGUI_RadioVolume") .. " / " .. getText("IGUI_RadioFrequency")
	local offset = (50 - FONT_HGT_LARGE) / 2

	self:drawTexture(Joypad.Texture.DPad, 0, self.height + 29, 1, 1, 1, 1)
	self:drawText(prompt, 42, self.height + 20 + offset, 1, 1, 1, 1, UIFont.Large)
end

function RWMMergedCarRadio:getAPrompt()

	if self.deviceData:getIsTurnedOn() then
        return getText("ContextMenu_Turn_Off")
    else
        return getText("ContextMenu_Turn_On")
    end
end

function RWMMergedCarRadio:getBPrompt()
    return nil;
end

function RWMMergedCarRadio:getXPrompt()
	if self.canMedia then
		if self.deviceData:isPlayingMedia() then
			return getText("IGUI_media_stop")
		else
			return getText("IGUI_media_play")
		end
	end
end

function RWMMergedCarRadio:getYPrompt()

	return getText("IGUI_RadioSelectChannel")
end

function RWMMergedCarRadio:getLBPrompt()

	if self.tuneWheel.frequency.done == self.presetsList.frequency[self.presetsList.selected] then
		return getText("IGUI_RadioRemovePreset")
	else
		return getText("IGUI_RadioAddPreset")		
	end
end

function RWMMergedCarRadio:getRBPrompt()
	
	return getText("IGUI_DeviceOptions")
end


function RWMMergedCarRadio:new (x, y, width, height)
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
	o.presetsList = {}
	o.userPreset = {"Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliett"}
	o.usedNames = {}
	o.carCD = getTexture("media/ui/TV_and_Radio/carCD.png")
	o.volumeSlider = getTexture("media/ui/TV_and_Radio/volumeSlider.png")
	o.powerIndicator = getTexture("media/ui/TV_and_Radio/powerIndicator.png")
	o.carVolume = getTexture("media/ui/TV_and_Radio/carVolume.png")
	o.turnOnDelay = 0
	o.font = UIFont.Code
    return o
end

