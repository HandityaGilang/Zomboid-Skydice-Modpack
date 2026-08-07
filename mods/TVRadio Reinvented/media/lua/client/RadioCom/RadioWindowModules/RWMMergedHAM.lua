-- **thank you** turbotutone

require "RadioCom/RadioWindowModules/RWMPanel"

RWMMergedHAM = RWMPanel:derive("RWMMergedHAM");

local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)
--local SHIFT_Y = math.max(getTextManager():MeasureStringY(UIFont.Large, prompt) , 32)

function RWMMergedHAM:initialise()
    ISPanel.initialise(self)
end

function RWMMergedHAM:createChildren()

	local function makeButton(bt)
		bt:initialise()
		bt.backgroundColor.a = 0
		bt.backgroundColorMouseOver = {r=0.15, g=0.15, b=0.15, a=0.5}
		bt.borderColor.a = 0
		bt.textColor = {r=0, g=0, b=0, a=0.7};
		--bt:setSound("activate", nil)
		self:addChild(bt)
	end

	self.muteButton = ISButton:new(213, 167, 16, 15,"", self, RWMMergedHAM.onMuteButton);
	makeButton(self.muteButton)

	self.plusTen = ISButton:new(123, 82, 15, 15,"", self, RWMMergedHAM.addTenOrHundred);
	makeButton(self.plusTen)

	self.plusHundred = ISButton:new(147, 82, 15, 15,"", self, RWMMergedHAM.addTenOrHundred);
	makeButton(self.plusHundred)

	self.toggleOnOffButton = ISButton:new(238, 4, 27, 15,"", self, RWMMergedHAM.toggleOnOff);
	makeButton(self.toggleOnOffButton)

	self.channelUp = ISButton:new(95, 73, 15, 15,"", self, RWMMergedHAM.doTuneInButton);
	makeButton(self.channelUp)
	
	self.channelDown = ISButton:new(1, 74, 15, 15,"",self, RWMMergedHAM.doTuneInButton);
	makeButton(self.channelDown)	

	self.tuneWheel = ISButton:new(24, 77, 64, 64,"",self, nil);
	makeButton(self.tuneWheel)
	self.tuneWheel.backgroundColorMouseOver.a = 0
	self.tuneWheel.onMouseMove = self.turning

	self.batteryLid = ISButton:new(120, 0, 46, 18,"",self, RWMMergedHAM.contextMenuBattery);
	makeButton(self.batteryLid)	
	
	self.headphonesPort = ISButton:new(240, 108, 22, 26,"",self, RWMMergedHAM.showHeadphonesContext);
	makeButton(self.headphonesPort)
	self.headphonesPort.backgroundColorMouseOver.a = 0
	
	self.slotCD = ISButton:new(101, 26, 124, 58, "", self, RWMMergedHAM.addMedia);
	makeButton(self.slotCD)
	self.slotCD.backgroundColor.a = 0.2
	self.slotCD.backgroundColorMouseOver.a = 0

	self.playMediaButton = ISButton:new(191, 0, 29, 13,"",self, RWMMergedHAM.togglePlayMedia);
	makeButton(self.playMediaButton)

	self.addPreset = ISButton:new(130, 118, 27, 15,"",self, RWMMergedHAM.doAddPreset);
	makeButton(self.addPreset)
	--self.addPreset:setTooltip(getText("IGUI_RadioAddPreset"))
	
	self.deletePreset = ISButton:new(130, 154, 27, 15,"",self, RWMMergedHAM.doDeletePreset);
	makeButton(self.deletePreset)
	--self.deletePreset:setTooltip(getText("IGUI_RadioRemovePreset"))
	
	self.volumeBar = ISVolumeBar:new(22, 161, 75, 21, RWMMergedHAM.onVolumeChange, self);
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

function RWMMergedHAM:onMuteButton()
    if self.deviceData and self.player and self.device then
        if self:doWalkTo() then
            ISTimedActionQueue.add(ISRadioAction:new("MuteMicrophone",self.player, self.device, not self.deviceData:getMicIsMuted() ));
        end
    end
end

function RWMMergedHAM:addTenOrHundred(button)

	if self.deviceData:getIsTurnedOn() then
		f = self.tuneWheel.frequency

		if button == self.plusHundred then
			newF = f.done + 100000
		else
			newF = f.done + 10000
		end

		if newF > f.max then
			newF = newF - f.max + f.min
		end

		self.deviceData:setChannel(newF)
		f.done = newF
		f.add = newF
	end
end

function RWMMergedHAM:toggleOnOff()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff", self.player, self.device ));
    end
end

-- volume
function RWMMergedHAM:volUpOrDown(button)

	if button == "volDown" then
		self.volumeBar:setVolumeJoypad(false)
	elseif button == "volUp" then
		self.volumeBar:setVolumeJoypad(true)
	end
end

function RWMMergedHAM:onVolumeChange( _newVol )

    self.volume = _newVol/self.volumeBar:getVolumeSteps();

    if self.deviceData then
        if self:doWalkTo() then
			ISTimedActionQueue.add(ISRadioAction:new("SetVolume",self.player, self.device, self.volume ));
        end
    end
end

-- fixed to not glitch to max volume when dragging
function RWMMergedHAM:getVolumeFromXPosition( _x )

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
function RWMMergedHAM:doTuneInButton(button)

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

function RWMMergedHAM:doAddPreset()
	
	
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

function RWMMergedHAM:doDeletePreset()

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
function RWMMergedHAM:addMedia()

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

function RWMMergedHAM:addMediaAux(item)
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("AddMedia",self.player, self.device, item ))
    end
end

function RWMMergedHAM:removeMedia()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("RemoveMedia",self.player, self.device ))
    end
end

function RWMMergedHAM:togglePlayMedia()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("TogglePlayMedia",self.player, self.device ))
    end
end

-- Battery

function RWMMergedHAM:contextMenuBattery()

	local playerNum = self.player:getPlayerNum()
    local context = ISContextMenu.get(playerNum, self.batteryLid:getAbsoluteX(), self.batteryLid:getAbsoluteY())
	if self.deviceData:getHasBattery() then
		local currentPower = string.format("%.i", self.deviceData:getPower() * 100)
		print(currentPower)
		context:addOption(getText("ContextMenu_Remove_Battery").. " " .. currentPower  .. "%", self, self.removeBattery, nil)
	else
		local inventory = self.player:getInventory()
		local batteries = inventory:FindAll("Base.Battery")
		if batteries:size() ~= 0 then
			context:addOption(getText("ContextMenu_AddBattery"), self, self.addBattery, nil)
		end
	end
end

function RWMMergedHAM:addBattery()

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

function RWMMergedHAM:removeBattery()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("RemoveBattery",self.player, self.device ));
    end
end

-- Headphones
function RWMMergedHAM:showHeadphonesContext()
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

function RWMMergedHAM:addHeadphone()

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
    --local pbuff = 0;

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

function RWMMergedHAM:removeHeadphone()
    if self:doWalkTo() then
        ISTimedActionQueue.add(ISRadioAction:new("RemoveHeadphones",self.player, self.device ));
    end
end


-- Wheel
function RWMMergedHAM:turning(dx, dy)
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
function RWMMergedHAM:readFromObject( _player, _deviceObject, _deviceData, _deviceType )
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
	if self.deviceData:getDeviceName() ~= getItemNameFromFullType("Radio.RadioRed") then
		self.slotCD:setVisible(false)
		self.playMediaButton:setVisible(false)
	else
		self.slotCD:setVisible(true)
		self.playMediaButton:setVisible(true)	
	end


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
function RWMMergedHAM:update()
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

function RWMMergedHAM:prerender()
    ISPanel.prerender(self);
end

-- RENDER
function RWMMergedHAM:render()

if self.deviceData then

-- volume slider
	local sliderX = 0

	if not self.volumeBar.dragInside then
		sliderX = self.volume * 70 + 15
	else
		sliderX = self.volumeBar.hoverVolume * 7 + 15
	end

	self:drawTexture(self.volumeSlider, sliderX, 159, 11, 19, 1, 1, 1, 1)


	if self.deviceData:getIsTurnedOn() then

	self.channelUp:setVisible(true)
	self.channelDown:setVisible(true)

	if self.deviceData:getMicIsMuted() then
		self:drawText("x", 156, 35, 0,0,0,0.5, self.font);
	end

-- frequency
	local currentFrequency = string.format("%.1f", self.tuneWheel.frequency.done / 1000)

	self:drawText(currentFrequency, 123, 49, 0,0,0,0.6, self.font);

-- channel name		
		if self.tuneWheel.frequency.done == self.presetsList.frequency[self.presetsList.selected] then	
			self:drawText("CH " .. self.presetsList.selected, 123, 37, 0,0,0,0.6, self.font);
		end

-- power indicator
		if self.turnOnDelay < 900 then
			self.turnOnDelay = self.turnOnDelay + UIManager.getMillisSinceLastRender()
		else
		end

		if self.turnOnDelay > 900 then self.turnOnDelay = 900 end

		self:drawTextureScaled(self.powerIndicator, 19, -25, 139, 91, self.turnOnDelay / 900, 1, 1, 1)
		
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

function RWMMergedHAM:clear()
    RWMPanel.clear(self);
end


function RWMMergedHAM:onBumperContext()

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

	if self.deviceData:getMicIsMuted() then
		context:addOption(getText("IGUI_RadioUnmuteMic"), self, self.onMuteButton, item)
	else
		context:addOption(getText("IGUI_RadioMuteMic"), self, self.onMuteButton, item)
	end
	
	if context.numOptions < 2 then return end
	
	context.origin = self.parent
	context.mouseOver = 1
	setJoypadFocus(playerNum, context)
end

function RWMMergedHAM:onJoypadDown(button)

    if button == Joypad.AButton then
		self:toggleOnOff()
	elseif button == Joypad.BButton then
		return
    elseif button == Joypad.YButton then
		self:doTuneInButton(self.channelUp)
    elseif button == Joypad.XButton then
		return
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

function RWMMergedHAM:onJoypadDirUp()

	local f = self.tuneWheel.frequency
	
	f.done = f.done + 200
	
	if f.done > f.max then f.done = f.min end
	f.add = f.done
	self.deviceData:setChannel(f.done)
end

function RWMMergedHAM:onJoypadDirDown()

    local f = self.tuneWheel.frequency

    f.done = f.done - 200
	
	if f.done < f.min then f.done = f.max end
	f.add = f.done
	self.deviceData:setChannel(f.done)
end

function RWMMergedHAM:onJoypadDirLeft()

	self:volUpOrDown("volDown")
end

function RWMMergedHAM:onJoypadDirRight()

	self:volUpOrDown("volUp")
end


function RWMMergedHAM:DPadPrompt()

	local prompt = getText("IGUI_RadioVolume") .. " / " .. getText("IGUI_RadioFrequency")
	local offset = (50 - FONT_HGT_LARGE) / 2

	self:drawTexture(Joypad.Texture.DPad, 0, self.height + 29, 1, 1, 1, 1)
	self:drawText(prompt, 42, self.height + 20 + offset, 1, 1, 1, 1, UIFont.Large)
end

function RWMMergedHAM:getAPrompt()

	if self.deviceData:getIsTurnedOn() then
        return getText("ContextMenu_Turn_Off")
    else
        return getText("ContextMenu_Turn_On")
    end
end

function RWMMergedHAM:getBPrompt()
    return nil;
end

function RWMMergedHAM:getXPrompt()
	return nil;
end

function RWMMergedHAM:getYPrompt()

	return getText("IGUI_RadioSelectChannel")
end

function RWMMergedHAM:getLBPrompt()

	if self.tuneWheel.frequency.done == self.presetsList.frequency[self.presetsList.selected] then
		return getText("IGUI_RadioRemovePreset")
	else
		return getText("IGUI_RadioAddPreset")		
	end
end

function RWMMergedHAM:getRBPrompt()
	
	return getText("IGUI_DeviceOptions")
end

function RWMMergedHAM:new (x, y, width, height)
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

