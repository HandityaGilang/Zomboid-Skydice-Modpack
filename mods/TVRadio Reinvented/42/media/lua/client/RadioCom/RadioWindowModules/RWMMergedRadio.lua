-- **thank you** turbotutone

require "RadioCom/RadioWindowModules/RWMPanel"

RWMMergedRadio = RWMPanel:derive("RWMMergedRadio");

local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

function RWMMergedRadio:initialise()
    ISPanel.initialise(self)
end

function RWMMergedRadio:createChildren()

	local function makeButton(bt)
		bt:initialise()
		bt.backgroundColor.a = 0
		bt.backgroundColorMouseOver = {r=0.15, g=0.15, b=0.15, a=0.5}
		bt.borderColor.a = 0
		bt.textColor = {r=0, g=0, b=0, a=0.7};
		bt.font = self.font
		--bt:setSound("activate", nil)
		self:addChild(bt)
	end

	self.channelUp = ISButton:new(158, 171, 20, 20,">", self, RWMMergedRadio.doTuneInButton);
	makeButton(self.channelUp)
	
	self.channelDown = ISButton:new(64, 171, 20, 20,"<",self, RWMMergedRadio.doTuneInButton);
	makeButton(self.channelDown)	

	self.tuneWheel = ISButton:new(206, 158, 22, 52,"",self, nil);
	makeButton(self.tuneWheel)
	self.tuneWheel.backgroundColorMouseOver.a = 0
	self.tuneWheel.onMouseMove = self.turning

	self.batteryLid = ISButton:new(157, 140, 77, 19,"",self, RWMMergedRadio.contextMenuBattery);
	makeButton(self.batteryLid)	
	
	self.headphonesPort = ISButton:new(0, 128, 16, 29,"",self, RWMMergedRadio.showHeadphonesContext);
	makeButton(self.headphonesPort)
	self.headphonesPort.backgroundColorMouseOver.a = 0
	
	self.slotCD = ISButton:new(101, 26, 124, 58, "", self, RWMMergedRadio.addMedia);
	makeButton(self.slotCD)
	self.slotCD.backgroundColor.a = 0.2
	self.slotCD.backgroundColorMouseOver.a = 0

	self.playMediaButton = ISButton:new(191, 0, 29, 13,"",self, RWMMergedRadio.togglePlayMedia);
	makeButton(self.playMediaButton)

	self.addPreset = ISButton:new(6, 168, 20, 20,"",self, RWMMergedRadio.doAddPreset);
	makeButton(self.addPreset)
	self.addPreset.textColor.a = 0.7
	self.addPreset.backgroundColorMouseOver.a = 0
	self.addPreset:setTooltip(getText("IGUI_RadioAddPreset"))
	
	self.deletePreset = ISButton:new(6, 191, 20, 20,"",self, RWMMergedRadio.doDeletePreset);
	makeButton(self.deletePreset)
	self.deletePreset.textColor.a = 0.7
	self.deletePreset.backgroundColorMouseOver.a = 0
	self.deletePreset:setTooltip(getText("IGUI_RadioRemovePreset"))
	
	self.volumeBar = ISVolumeBar:new(125, 86, 75, 38, RWMMergedRadio.onVolumeChange, self);
    self.volumeBar:initialise();
	self.volumeBar.elBorderColor.a = 0
	self.volumeBar.elBorderHighlightColor.a = 0
	self.volumeBar.elBackgroundColor.a = 0
	self.volumeBar.elHighlightColor.a = 0
	self.volumeBar.elHoverColor.a = 0
	self.volumeBar.greyCol.a = 0
	self.volumeBar.mouseEnabled = true
	self.volumeBar.timer = 0
	self.volumeBar:setVisible(true)
	self.volumeBar.getVolumeFromXPosition = self.getVolumeFromXPosition
    self:addChild(self.volumeBar);
end

function RWMMergedRadio:toggleOnOff()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff",self.player, self.device ));
    end
end

-- volume
function RWMMergedRadio:volUpOrDown(button)

	if button == "volDown" then
		self.volumeBar:setVolumeJoypad(false)
	elseif button == "volUp" then
		self.volumeBar:setVolumeJoypad(true)
	end
end

function RWMMergedRadio:onVolumeChange( _newVol )

    self.volume = _newVol/self.volumeBar:getVolumeSteps();

    if self.deviceData then
        if self:doWalkTo() then
			if not self.deviceData:getIsTurnedOn() then
				if _newVol ~= 1 then			
					ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff",self.player, self.device ));
				end
			elseif self.volume == 0.1 then
				ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff",self.player, self.device ));
				self.deviceData:setDeviceVolume(0.1)
			end
			ISTimedActionQueue.add(ISRadioAction:new("SetVolume",self.player, self.device, self.volume ));
        end
    end
end

-- fixed to not glitch to max volume when dragging
function RWMMergedRadio:getVolumeFromXPosition( _x )

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
function RWMMergedRadio:doTuneInButton(button)

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
			--ISTimedActionQueue.add( ISRadioAction:new( "SetChannel",self.player, self.device, fNew ))
		end
	end
end

function RWMMergedRadio:doAddPreset()
	
	
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
	else
		--
	end
end

function RWMMergedRadio:doDeletePreset()

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
function RWMMergedRadio:addMedia()

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

function RWMMergedRadio:addMediaAux(item)
    if self:doWalkTo() then
        --ISTimedActionQueue.add(ISRadioAction:new("AddMedia",self.player, self.device, item ))
		ISTimedActionQueue.add(ISDeviceMediaAction:new(self.player, false, item, ISDeviceBatteryAction:getDeviceDataParameter(self.player, self.device, self.deviceType) ));
    end
end

function RWMMergedRadio:removeMedia()
    if self:doWalkTo() then
        --ISTimedActionQueue.add(ISRadioAction:new("RemoveMedia",self.player, self.device ))
		ISTimedActionQueue.add(ISDeviceMediaAction:new(self.player, true, nil, ISDeviceBatteryAction:getDeviceDataParameter(self.player, self.device, self.deviceType) ));
    end
end

function RWMMergedRadio:togglePlayMedia()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("TogglePlayMedia",self.player, self.device ))
    end
end

-- Battery

function RWMMergedRadio:contextMenuBattery()

	local playerNum = self.player:getPlayerNum()
    local context = ISContextMenu.get(playerNum, self.batteryLid:getAbsoluteX(), self.batteryLid:getAbsoluteY())
	if self.deviceData:getHasBattery() then
		local currentPower = string.format("%.i", self.deviceData:getPower() * 100)
		if currentPower == "" then currentPower = 0 end
		context:addOption(getText("ContextMenu_Remove_Battery").. " " .. currentPower  .. "%", self, self.removeBattery, nil)
	else
		local inventory = self.player:getInventory()
		local batteries = inventory:FindAll("Base.Battery")
		if batteries:size() ~= 0 then
			context:addOption(getText("ContextMenu_AddBattery"), self, self.addBattery, nil)
		end
	end
end

function RWMMergedRadio:addBattery()

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
			if i:getCurrentUsesFloat() > pbuff then
				item = i;
				pbuff = i:getCurrentUsesFloat()
			end
		end

		if item then
			if self:doWalkTo() then
				--ISTimedActionQueue.add(ISRadioAction:new("AddBattery",self.player, self.device, item ))
				ISTimedActionQueue.add(ISDeviceBatteryAction:new(self.player, false, item, ISDeviceBatteryAction:getDeviceDataParameter(self.player, self.device, self.deviceType) ));
				if self.volume ~= 0.1 then
					ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff",self.player, self.device ));
				end
			end
		end
end

function RWMMergedRadio:removeBattery()
    if self:doWalkTo() then
        --ISTimedActionQueue.add(ISRadioAction:new("RemoveBattery",self.player, self.device ));
		ISTimedActionQueue.add(ISDeviceBatteryAction:new(self.player, true, nil, ISDeviceBatteryAction:getDeviceDataParameter(self.player, self.device, self.deviceType) ));
    end
end

-- Headphones
function RWMMergedRadio:showHeadphonesContext()
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

function RWMMergedRadio:addHeadphone()

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

function RWMMergedRadio:removeHeadphone()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("RemoveHeadphones",self.player, self.device ));
    end
end


-- Wheel
function RWMMergedRadio:turning(dx, dy)
--  replaces self.tuneWheel.onMouseMove
	if self.pressed == true then
		
		self.frequency.add = self.frequency.add - dy * 25
		print(self.frequency.add)
		print(self.frequency.done)
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
function RWMMergedRadio:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
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

-- check CD and change text color
	
	self.canMedia = self.deviceData:getDeviceName() == getItemNameFromFullType("Base.RadioRed")
	self.slotCD:setVisible(self.canMedia)
	self.playMediaButton:setVisible(self.canMedia)

-- set volume
	if not self.deviceData:getIsTurnedOn() then
		self.deviceData:setDeviceVolume(0.1)
	end
		

	self.volume = self.deviceData:getDeviceVolume()
	print(self.volume)
    self.volumeBar.volume = math.floor(self.volume*self.volumeBar:getVolumeSteps())
	self.volumeBar.hoverVolume = self.volumeBar.volume
    return RWMPanel.readFromObject(self, _player, _deviceObject, _deviceData, _deviceType )
end

-- UPDATE
function RWMMergedRadio:update()
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

function RWMMergedRadio:prerender()
    ISPanel.prerender(self);
end

-- RENDER
function RWMMergedRadio:render()

if self.deviceData then

-- volume slider
	local sliderX = 0

	if not self.volumeBar.dragInside then
		sliderX = 119 + self.volume * 70
	else
		sliderX = 119 + self.volumeBar.hoverVolume * 7
	end

	self:drawTexture(self.volumeSlider, sliderX, 89, 11, 19, 1, 1, 1, 1)


	if self.deviceData:getIsTurnedOn() then

	self.channelUp:setVisible(true)
	self.channelDown:setVisible(true)

-- frequency
	local currentFrequency = string.format("%.1f", self.tuneWheel.frequency.done / 1000)

	self:drawText(currentFrequency .. " MHz", 94, 171, 0,0,0,0.7, self.font);

-- channel name
		if self.tuneWheel.frequency.done == self.presetsList.frequency[self.presetsList.selected] then
			local channelName = self.presetsList.name[self.presetsList.selected]
			if channelName == "Automated Emergency Broadcast System" then channelName = "Automated Broadcast" end
			
			local offsetX = (self.width - 43 - getTextManager():MeasureStringX(self.font, channelName)) / 2

			self:drawText(channelName, 28+offsetX, 187, 0,0,0,0.7, self.font);
		end

-- power indicator
		if self.turnOnDelay < 900 then
			self.turnOnDelay = self.turnOnDelay + UIManager.getMillisSinceLastRender()
		else
		end

		if self.turnOnDelay > 900 then self.turnOnDelay = 900 end

		self:drawTextureScaled(self.powerIndicator, 76, 104, 139, 91, self.turnOnDelay / 900, 1, 1, 1)
		
	else
		self.turnOnDelay = 0
		self.channelUp:setVisible(false)
		self.channelDown:setVisible(false)
	end
	
-- CD
	if self.deviceData:hasMedia() then
		self:drawTexture(self.imageCD, 100, 27, 124, 59, 1, 1, 1, 1)
	end
end
    ISPanel.render(self);
end

function RWMMergedRadio:clear()
    RWMPanel.clear(self);
end


function RWMMergedRadio:onBumperContext()

	local playerNum = self.player:getPlayerNum()
	local inventory = self.player:getInventory()
    local context = ISContextMenu.get(playerNum, self.batteryLid:getAbsoluteX(), self.batteryLid:getAbsoluteY())
	
	if self.deviceData:getHasBattery() then
		local currentPower = string.format("%.i", self.deviceData:getPower() * 100)
		if currentPower == "" then currentPower = 0 end
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

function RWMMergedRadio:onJoypadDown(button)

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

function RWMMergedRadio:onJoypadDirUp()

	local f = self.tuneWheel.frequency
	
	f.done = f.done + 200
	
	if f.done > f.max then f.done = f.min end
	f.add = f.done
	self.deviceData:setChannel(f.done)
end

function RWMMergedRadio:onJoypadDirDown()

    local f = self.tuneWheel.frequency

    f.done = f.done - 200
	
	if f.done < f.min then f.done = f.max end
	f.add = f.done
	self.deviceData:setChannel(f.done)
end

function RWMMergedRadio:onJoypadDirLeft()

	self:volUpOrDown("volDown")
end

function RWMMergedRadio:onJoypadDirRight()

	self:volUpOrDown("volUp")
end


function RWMMergedRadio:DPadPrompt()

	local prompt = getText("IGUI_RadioVolume") .. " / " .. getText("IGUI_RadioFrequency")
	local offset = (50 - FONT_HGT_LARGE) / 2

	self:drawTexture(Joypad.Texture.DPad, 0, self.height + 29, 1, 1, 1, 1)
	self:drawText(prompt, 42, self.height + 20 + offset, 1, 1, 1, 1, UIFont.Large)
end

function RWMMergedRadio:getAPrompt()

	if self.deviceData:getIsTurnedOn() then
        return getText("ContextMenu_Turn_Off")
    else
        return getText("ContextMenu_Turn_On")
    end
end

function RWMMergedRadio:getBPrompt()
    return nil;
end

function RWMMergedRadio:getXPrompt()

	if self.canMedia then
		if self.deviceData:isPlayingMedia() then
			return getText("IGUI_media_stop")
		else
			return getText("IGUI_media_play")
		end
	end
end

function RWMMergedRadio:getYPrompt()

	return getText("IGUI_RadioSelectChannel")
end

function RWMMergedRadio:getLBPrompt()

	if self.tuneWheel.frequency.done == self.presetsList.frequency[self.presetsList.selected] then
		return getText("IGUI_RadioRemovePreset")
	else
		return getText("IGUI_RadioAddPreset")		
	end
end

function RWMMergedRadio:getRBPrompt()
	
	return getText("IGUI_DeviceOptions")
end

function RWMMergedRadio:new (x, y, width, height)
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
	o.imageCD = getTexture("media/ui/TV_and_Radio/CD.png")
	o.volumeSlider = getTexture("media/ui/TV_and_Radio/volumeSlider.png")
	o.powerIndicator = getTexture("media/ui/TV_and_Radio/powerIndicator.png")
	o.turnOnDelay = 0
	o.font = UIFont.Code
    return o
end

