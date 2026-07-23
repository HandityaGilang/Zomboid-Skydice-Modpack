require "ISUI/ISPanel"
local PSC_Tags = ProjectSummerCar_Tags

Project_Dashboard_HotReload = "media/lua/client/Project_Dashboard_Data.lua" -- Reload this file when selecting a dash in debug mode. Change this to your own file if you want to hot reload dash settings. 
VehicleDashboardReplacer = ISPanel:derive("VehicleDashboardReplacer")



local keyOptions = PZAPI.ModOptions:create("ProjectSummerCar",getText("IGUI_PSC_ModOptionsName"))
keyOptions:addDescription(getText("IGUI_PSC_ModOptionHeader"))
keyOptions:addTickBox("DashChangeContext", getText("IGUI_PSC_DashChangeContext"), true, getText("IGUI_PSC_DashChangeContext_Tooltip") )
local dashSaveComboOption = keyOptions:addComboBox("DashChangeSaved",getText("IGUI_PSC_DashChangeSave"))
dashSaveComboOption:addItem(getText("IGUI_PSC_Player"),true)
dashSaveComboOption:addItem(getText("IGUI_PSC_VehicleType"),false)
dashSaveComboOption:addItem(getText("IGUI_PSC_Vehicle"),false)




function GetPartCondition(enginePart,partname)
	local curPart = enginePart:getItemContainer():getFirstTag(partname)
	if curPart then
		return curPart:getCondition()
	end
	return 0
end



function ISVehicleMenu.ChangeDash(playerObj, vehicle)
	local isPaused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
	if isPaused then return end
	local dashboardreplacer = getPlayerVehicleDashboardReplacer(playerObj:getPlayerNum())
	
	
	dashboardreplacer.dashBoardSelect = dashboardreplacer.dashBoardSelect + 1
	if dashboardreplacer.dashBoardSelect > #Project_Dashboard.Dashes then  
		dashboardreplacer.dashBoardSelect = 0 
	end
	local modData = playerObj:getModData();
	modData.ProjectDashboardSelectedDashByType = modData.ProjectDashboardSelectedDashByType or {1,2,3}
	if dashSaveComboOption:getValue() == 1 then
		modData.ProjectDashboardSelectedDash = dashboardreplacer.dashBoardSelect; -- Save selected dash for next load. 
	elseif dashSaveComboOption:getValue() == 2 then
		modData.ProjectDashboardSelectedDashByType[vehicle:getScript():getMechanicType()] = dashboardreplacer.dashBoardSelect; -- Save selected dash for next load. 
	else
		vehicle:getModData().ProjectDashboardSelectedDash = dashboardreplacer.dashBoardSelect;
	end

	
	getPlayerVehicleDashboardReplacer(playerObj:getPlayerNum()):setVehicle(vehicle)
	getPlayerVehicleDashboard(playerObj:getPlayerNum()):setVehicle(vehicle)
end


oldShowRadialMenu = ISVehicleMenu.showRadialMenu
function ISVehicleMenu.showRadialMenu(playerObj)
	oldShowRadialMenu(playerObj);
	local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
	local vehicle = playerObj:getVehicle()
	if vehicle == nil then return end; -- Not inside vehicle. 
	if vehicle:getDriver() ~= playerObj then return end; -- Not driver. 
	--print("value is ",keyOptions:getOption("DashChangeContext"):getValue())
	if keyOptions:getOption("DashChangeContext"):getValue() == true then
		menu:addSlice(getText("IGUI_Dashboard_ChangeDash"), getTexture("media/textures/dashboard/changedash.png"), ISVehicleMenu.ChangeDash, playerObj, vehicle )
	end
end

function VehicleDashboardReplacer:onClickKeysAdvanced()
	self.ignitionTex.mouseDown = false;
	-- This shuts down the engine if held till engine starts properly. 
	self.ignitionTex.mouseDownTime = self.ignitionTex.mouseDownTime or getTimestampMs()
	
	if getGameSpeed() == 0 then return; end
	if getGameSpeed() > 1 then setGameSpeed(1); end
	if not self.vehicle then return end
			if getTimestampMs() - self.ignitionTex.mouseDownTime > 200 then
				return
			end
	-- This could be done better...
	if self.vehicle:isEngineRunning() then
		ISVehicleMenu.onShutOff(self.character)
	elseif not self.vehicle:isEngineStarted() then
		--print("Keyclick at " ,  getTimestampMs(), " timestamp ", self.ignitionTex.mouseDownTime);
		if self.vehicle:isKeysInIgnition() then
--			if getTimestampMs() - self.ignitionTex.mouseDownTime < 200 then
				-- Only remove keys if it was a quick press. 
				self.vehicle:setKeysInIgnition(false);
			--end
		else
			self.vehicle:setKeysInIgnition(true);
		end
	end
end

local oldResolutionChange = ISPlayerDataObject.onResolutionChange
function ISPlayerDataObject:onResolutionChange(oldw, oldh, neww, newh)
    if self.vehicleDashboardReplacer then
        self.vehicleDashboardReplacer:onResolutionChange()
    end
return oldResolutionChange(self,oldw, oldh, neww, newh)
end

local oldCreateInventoryInterface = ISPlayerDataObject.createInventoryInterface
function ISPlayerDataObject:createInventoryInterface()
	local playerObj = getSpecificPlayer(self.id);
    self.vehicleDashboardReplacer = VehicleDashboardReplacer:new(self.id, playerObj)
    self.vehicleDashboardReplacer:initialise()
    self.vehicleDashboardReplacer:instantiate()
	if playerObj:getVehicle() then
		if playerObj:getVehicle():getDriver() == playerObj then
			self.vehicleDashboardReplacer:setVehicle(playerObj:getVehicle())
		end
	end
	
	
return oldCreateInventoryInterface(self)
end

function getPlayerVehicleDashboardReplacer(id)
    local data = getPlayerData(id)
    return data and data.vehicleDashboardReplacer
end

function VehicleDashboardReplacer:new(playerNum, chr)
	playerReplacementDashes = playerReplacementDashes or {}
	if playerReplacementDashes[playerNum] then
		--print("Old dash detected. turning off");
		playerReplacementDashes[playerNum]:setVehicle(nil); -- disable old dash. This occurs when gamepad takes over from keyboard. 
	end
	
	local o = ISPanel:new(0, 0, 200, 200)
	setmetatable(o, self)
	self.__index = self
	
	local modData = getSpecificPlayer(playerNum):getModData();
	o.dashBoardSelect = modData.ProjectDashboardSelectedDash or 1;
	o.playerNum = playerNum
	o.character = chr;
	o.flickingTimer = 0;
	o.currentLoadedDashboard = 0;	
	playerReplacementDashes[playerNum] = o; -- Used to turn off dash when gamepad takes over. 
	return o
end

function VehicleDashboardReplacer:AddImage(x, y, texture, onclick)
	local image = ISImage:new(x,y, texture:getWidthOrig(),texture:getHeightOrig(), texture);
	image:initialise();
	image:instantiate();
	image.onclick = onclick;
	image.target = self;
	self:addChild(image);
	return image
end

function VehicleDashboardReplacer:UpdateImage(image, x, y, texture, onclick)
	if texture == nil then
		print("Texture not found!");
	end
	
	if image == nil then 
		image = ISImage:new(x,y, texture:getWidthOrig(),texture:getHeightOrig(), texture);
		image:initialise();
		image:instantiate();
		image.target = self;
	else
		image:setX(x);
		image:setY(y);
		image.texture = texture;
		image:setWidth(texture:getWidthOrig());
		image:setHeight(texture:getHeightOrig());		
		self:removeChild(image); -- To maintain child order with all other elements, must remove and readd.
	end
	self:addChild(image); 
	image.onclick = onclick;
	return image
end

function VehicleDashboardReplacer:UpdateGauge(gauge, gaugeData)
	if gauge ~= nil then 
		self:removeChild(gauge); -- just remove old gauge, simpler then trying to update it with all these variables.
	end
	
	gauge = ISVehicleGauge:new(gaugeData.x, gaugeData.y, safeGetTexture(gaugeData.filename), gaugeData.needleX, gaugeData.needleY, gaugeData.needleStart, gaugeData.needleEnd)
	gauge:initialise()
	gauge:instantiate()
	self:addChild(gauge)
	gauge:setNeedleWidth(gaugeData.needleLength)
	return gauge
end

function safeGetTexture(filename)
assert(filename ~= nil,"Critical Error Project Dashboard - Nil filename");
local texture = getTexture(filename)
assert(texture ~= nil, "Critical Error Project Dashboard - Unable to open " .. filename);
return texture;
end


function VehicleDashboardReplacer:loadDash()
	if self.currentLoadedDashboard == self.dashBoardSelect then
		return 
	end

	self.currentLoadedDashboard = self.dashBoardSelect;
	if self.dash then -- have ever loaded a dash before
		for key,switch in pairs(self.dash.switches) do
			self:removeChild(switch.image)
			self:removeChild(switch.iconImage)
			self:removeChild(switch.ledBGImage)
			self:removeChild(switch.ledImage)
		end
	end
	
	self.dash = Project_Dashboard.Dashes[self.dashBoardSelect];
	local backgroundtex = safeGetTexture(self.dash.background);
	self.backgroundImage = self:UpdateImage(self.backgroundImage, 0,0, backgroundtex);
	self:setWidth(backgroundtex:getWidth());
	self:setHeight(backgroundtex:getHeight());

	self.engineGauge = self:UpdateGauge(self.engineGauge,self.dash.rpmGauge)
	self.speedGauge = self:UpdateGauge(self.speedGauge,self.dash.speedGauge)

	
	self.fuelGauge = self:UpdateGauge(self.fuelGauge,self.dash.fuelGauge)
	self.fuelGaugeIcon = self:UpdateImage(self.fuelGaugeIcon, 0, 0, safeGetTexture(self.dash.batteryGauge.icon.filename)); -- Position gets set later in setVehicle
	
	self.tempGauge = self:UpdateGauge(self.tempGauge,self.dash.tempGauge)
	self.tempGaugeIcon = self:UpdateImage(self.tempGaugeIcon, self.dash.tempGauge.x + self.dash.tempGauge.icon.offsetX, self.dash.tempGauge.y + self.dash.tempGauge.icon.offsetY, safeGetTexture(self.dash.tempGauge.icon.filename));
	
	self.batteryGauge = self:UpdateGauge(self.batteryGauge,self.dash.batteryGauge)
	self.batteryTex = self:UpdateImage(self.batteryTex, self.dash.batteryGauge.x + self.dash.batteryGauge.icon.offsetX, self.dash.batteryGauge.y + self.dash.batteryGauge.icon.offsetY, safeGetTexture(self.dash.batteryGauge.icon.filename));
	
	--if self.gearIndicator then
	--	self:removeChild(self.gearIndicator)
	--end
	--self.gearIndicator = ISLabel:new(self.dash.gearIndicator.x, self.dash.gearIndicator.y, 24, "S", 1,1,1,0.85, UIFont.Medium);
	--self.gearIndicator:initialise();
	--self.gearIndicator:instantiate();
	--self:addChild(self.gearIndicator);
	--self.gearIndicator.tooltip = getText("Tooltip_Dashboard_Shift")
	
	
	self.engineTex = self:UpdateImage(self.engineTex, self.dash.engineIcon.x,self.dash.engineIcon.y,safeGetTexture(self.dash.engineIcon.filename),VehicleDashboardReplacer.onClickEngine);
	--self.engineTex.mouseovertext = getText("Tooltip_Dashboard_Engine")
	self.oilLightImage = self:UpdateImage(self.oilLightImage, self.dash.oilIcon.x,self.dash.oilIcon.y, safeGetTexture(self.dash.oilIcon.filename));
	
	self.speedregulatorTex = self:UpdateImage(self.speedregulatorTex, self.dash.cruiseControlIndicator.x + self.dash.cruiseControlIndicator.icon.offsetX, self.dash.cruiseControlIndicator.y + self.dash.cruiseControlIndicator.icon.offsetY, safeGetTexture(self.dash.cruiseControlIndicator.icon.filename));
	self.speedregulatorTex.mouseovertext = getText("Tooltip_Dashboard_SpeedRegulator", Keyboard.getKeyName(Keyboard.KEY_LSHIFT), Keyboard.getKeyName(getCore():getKey("Forward")), Keyboard.getKeyName(getCore():getKey("Backward")))
	

	self.ignitionBG = self:UpdateImage(self.ignitionBG, self.dash.ignition.x,self.dash.ignition.y, safeGetTexture(self.dash.ignition.filename));

	-- Modify ignition switch to be able to detect long press. 
	self.ignitionTex = self:UpdateImage(self.ignitionTex, 0,0, safeGetTexture(self.dash.ignition.emptyIcon.filename), VehicleDashboardReplacer.onClickKeysAdvanced); -- Gets position set later. 
	self.ignitionTex.onMouseDown = ISPanel.mouseDownBonus
	self.ignitionTex.target = self;
	

	
	--self.doorTex.mouseovertext = getText("Tooltip_Dashboard_LockedDoors")
	--self.lightsTex.mouseovertext = getText("Tooltip_Dashboard_Headlights")
	--self.radioTex.mouseovertext = getText("Tooltip_Dashboard_Radio")
	--self.heaterTex.mouseovertext = getText("Tooltip_Dashboard_Heater")
	
	self.dash.switches.radio.onClick = self.dash.switches.radio.onClick or VehicleDashboardReplacer.onClickRadio
	self.dash.switches.heater.onClick = self.dash.switches.heater.onClick or VehicleDashboardReplacer.onClickHeater
	self.dash.switches.locks.onClick = self.dash.switches.locks.onClick or VehicleDashboardReplacer.onClickDoors
	self.dash.switches.trunk.onClick = self.dash.switches.trunk.onClick or VehicleDashboardReplacer.onClickTrunk
	self.dash.switches.headlights.onClick = self.dash.switches.headlights.onClick or VehicleDashboardReplacer.onClickHeadlights
	
	for key,switch in pairs(self.dash.switches) do
 		switch.state = false
		switch.ledState = false
		switch.buttonTextures = {}
		switch.buttonTextures[1] = safeGetTexture(switch.buttonTextureNames[1]);
		switch.buttonTextures[2] = safeGetTexture(switch.buttonTextureNames[2]);
		switch.image = self:AddImage(switch.x,switch.y,switch.buttonTextures[1],switch.onClick);

		switch.iconTexture = safeGetTexture(switch.icon)
		local iconX = switch.x + switch.buttonTextures[1]:getWidthOrig() / 2 - switch.iconTexture:getWidthOrig() / 2
		switch.iconImage = self:AddImage(iconX+switch.iconOffset.x,switch.y+switch.iconOffset.y,switch.iconTexture);
				
		switch.ledBGTexture = safeGetTexture(switch.ledBG)
		local ledBGX = switch.x + switch.buttonTextures[1]:getWidthOrig() / 2 - switch.ledBGTexture:getWidthOrig() / 2
		switch.ledBGImage = self:AddImage(ledBGX+switch.ledBGOffset.x,switch.y+switch.ledBGOffset.y, switch.ledBGTexture);
		
		switch.ledTexture = safeGetTexture(switch.led)
		local ledX = switch.x + switch.buttonTextures[1]:getWidthOrig() / 2 - switch.ledTexture:getWidthOrig() / 2
		switch.ledImage = self:AddImage(ledX+switch.ledOffset.x,switch.y+switch.ledOffset.y, switch.ledTexture);
	end
	self:onResolutionChange()
end


function VehicleDashboardReplacer:createChildren()
	self:loadDash(); -- Shouldn't really be needed here if our loading code didn't use the background size.
	self:onResolutionChange()
end

function VehicleDashboardReplacer.damageFlick(character)
	local dash = nil;
	if instanceof(character, 'IsoPlayer') and character:isLocalPlayer() then
		local vehicle = character:getVehicle()
		dash = getPlayerVehicleDashboardReplacer(character:getPlayerNum())
	end
	if dash then
		dash.flickAlpha = 0;
		dash.flickAlphaUp = true;
		dash.flickingTimer = 100;
	end
end

function VehicleDashboardReplacer:getAlphaFlick(default)
	if self.flickingTimer > 0 then
		self.flickingTimer = self.flickingTimer - 1;
		
		if self.flickAlphaUp then
			self.flickAlpha = self.flickAlpha + 0.2;
			if self.flickAlpha >= 1 then
				self.flickAlpha = 0.8;
				self.flickAlphaUp = false;
			end
		else
			self.flickAlpha = self.flickAlpha - 0.2;
			if self.flickAlpha <= 0 then
				self.flickAlpha = 0.2;
				self.flickAlphaUp = true;
			end
		end
		
		return self.flickAlpha;
	else
		return default;
	end
end

function VehicleDashboardReplacer:getSelectedDashboard(vehicle)
	--print("VehicleDashboardReplacer ", vehicle);
	if vehicle == nil then
		return 0
	end
	
	local modData = getSpecificPlayer(self.playerNum):getModData();
	modData.ProjectDashboardSelectedDashByType = modData.ProjectDashboardSelectedDashByType or {1,2,3}
	local selectedDash;
	if dashSaveComboOption:getValue() == 1 then
		selectedDash = modData.ProjectDashboardSelectedDash; 
	elseif dashSaveComboOption:getValue() == 2 then
		selectedDash = modData.ProjectDashboardSelectedDashByType[vehicle:getScript():getMechanicType()]; 
	else
		selectedDash = vehicle:getModData().ProjectDashboardSelectedDash;
	end
	--print("VehicleDashboardReplacer result", selectedDash);
	if selectedDash == nil then
		selectedDash = 0;
	end
	
	return selectedDash
end

function VehicleDashboardReplacer:setVehicle(vehicle)
	
	self.dashBoardSelect = self:getSelectedDashboard(vehicle);
	if self.dashBoardSelect == 0 then
		vehicle = nil -- Disable this dashboard.
	end 

	self.vehicle = vehicle
	if not vehicle then
		self:removeFromUIManager()
		return
	end
	
	-- Can't use globals here because when player switches to gamepad, global is no longer valid for the new dashboard instance. 
	
	
	if self.currentLoadedDashboard ~= self.dashBoardSelect then
		if getDebug() then
			reloadLuaFile(Project_Dashboard_HotReload);
		end
		self:loadDash()
	end

	--print("Texture ".. self.dash.rpmGauge.redline4500);
	--print("Texture loaded", safeGetTexture(self.dash.rpmGauge.redline4500));
	--print("Self dash was ", self.dash);
	if vehicle:getScript():getEngineRPMType() == "firebird" then
		if self.dash.rpmGauge.redline6000 then
			self.engineGauge:setTexture(safeGetTexture(self.dash.rpmGauge.redline6000))
		end
	else
		if self.dash.rpmGauge.redline4500 then
			self.engineGauge:setTexture(safeGetTexture(self.dash.rpmGauge.redline4500))
		end
	end

	
	
	-- This should be moved elsewhere, likely...
	local part = vehicle:getPartById("GasTank")
	if part and part:isContainer() and part:getContainerContentType() then
		self.gasTank = part
		if self.vehicle:isEngineRunning() then
			self.fuelValue = self.gasTank:getContainerContentAmount() / self.gasTank:getContainerCapacity()
		else
			self.fuelValue = 0.0
		end
		self.fuelGauge:setVisible(true)

        local gasArea = part:getArea()
		self.fuelGaugeIcon.texture = safeGetTexture(self.dash.fuelGauge.icon.filename)
		self.fuelGaugeIcon:setX(self.dash.fuelGauge.x + self.dash.fuelGauge.icon.offsetX)
		self.fuelGaugeIcon:setY(self.dash.fuelGauge.y + self.dash.fuelGauge.icon.offsetY)
        if gasArea then
            if vehicle:leftSideFuel() then
				self.fuelGaugeIcon.texture = safeGetTexture(self.dash.fuelGauge.iconLeft.filename)
				self.fuelGaugeIcon:setX(self.dash.fuelGauge.x + self.dash.fuelGauge.iconLeft.offsetX)
				self.fuelGaugeIcon:setY(self.dash.fuelGauge.y + self.dash.fuelGauge.iconLeft.offsetY)
            elseif vehicle:rightSideFuel() then
				self.fuelGaugeIcon.texture = safeGetTexture(self.dash.fuelGauge.iconRight.filename)
				self.fuelGaugeIcon:setX(self.dash.fuelGauge.x + self.dash.fuelGauge.iconRight.offsetX)
				self.fuelGaugeIcon:setY(self.dash.fuelGauge.y + self.dash.fuelGauge.iconRight.offsetY)
            end
        end
	else
		self.gasTank = nil
		self.fuelGauge:setVisible(false)
	end
	self:setVisible(true)
	self:addToUIManager()
	self:onResolutionChange()
	if not ISUIHandler.allUIVisible then
		self:removeFromUIManager()
	end
end

function VehicleDashboardReplacer:prerender()

	-- Should really be done somewhere else. 
	if self.ignitionTex.mouseDown == true then 
		if getTimestampMs() - self.ignitionTex.mouseDownTime > 200 then
			ISVehicleMenu.onStartEngine(self.character)
			--print("Starting Engine!")
		end
	end

	if not self.vehicle or not ISUIHandler.allUIVisible then return end
	local alpha = self:getAlphaFlick(0.65);
	local greyBg = {r=0.5, g=0.5, b=0.5, a=alpha};
	local goodColor = { r = getCore():getGoodHighlitedColor():getR(), g = getCore():getGoodHighlitedColor():getG(), b = getCore():getGoodHighlitedColor():getB(), a = alpha }
	local badColor = { r = getCore():getBadHighlitedColor():getR(), g = getCore():getBadHighlitedColor():getG(), b = getCore():getBadHighlitedColor():getB(), a = alpha }
	
	self.fuelGaugeIcon.backgroundColor = {r=0.4, g=0.4, b=0.4, a=1}
	if self.gasTank then
		local current = 0.0
		if self.vehicle:isEngineRunning() or self.vehicle:isKeysInIgnition() or self.vehicle:isStarting() then
			current = self.gasTank:getContainerContentAmount() / self.gasTank:getContainerCapacity()
		end
		
		if self.fuelValue < current then
			self.fuelValue = math.min(self.fuelValue + 0.015 * (30 / getPerformance():getUIRenderFPS()), current)
		elseif self.fuelValue > current then
			self.fuelValue = math.max(self.fuelValue - 0.05 * (30 / getPerformance():getUIRenderFPS()), current)
		end
		self.fuelGauge:setValue(self.fuelValue)
		

		if self.vehicle:isEngineRunning() or self.vehicle:isKeysInIgnition() or self.vehicle:isStarting() then
			if current < 0.15 then
				self.fuelGaugeIcon.backgroundColor = {r=1.0, g=0.0, b=0.0, a=1}
			elseif current < 0.3 then
				self.fuelGaugeIcon.backgroundColor = {r=1.0, g=0.6, b=0.0, a=1}
			end
		end
		
		
		local engineSpeedValue = 0;
		local speedValue = 0;
		if self.vehicle:isEngineRunning() then
			if self.vehicle:getScript():getEngineRPMType() == "firebird" then
				engineSpeedValue = math.max(0,math.min(1,(self.vehicle:getEngineSpeed())/(7000)));
			else -- Todo: detect if we actually had loaded a proper lower RPM tacho? Base off the tacho loaded?
				engineSpeedValue = math.max(0,math.min(1,(self.vehicle:getEngineSpeed())/(6000)));
			end
			
			speedValue = math.max(0,math.min(1,math.abs(self.vehicle:getCurrentSpeedKmHour())/120));
		end
		self.engineGauge:setValue(engineSpeedValue)
		-- RJ: Fake the speedometer a tad
		self.speedGauge:setValue(speedValue * BaseVehicle.getFakeSpeedModifier())
		--self.speedGauge:setValue(ZombRand(2));
		--self.engineGauge:setValue(ZombRand(2));
		
	end
	
	-- Temp gauge update code.
	local engineVehiclePart = self.vehicle:getPartById("Engine") -- Because weird unimog RV trailer thing without an engine... 
	local engineModData = engineVehiclePart and engineVehiclePart:getModData(); 
	if engineModData and engineModData.temperature and engineModData.temperatureRadiator then
		local temp = math.min(engineModData.temperature / (75 * 4),0.25) -- Scale 0~75 to 0~0.25
		temp = temp + math.min(math.max((engineModData.temperature - 75) / 100.0,0),0.75) -- Scale 75~150 to 0~0.75, added to the previous 0.25 for 0.25~1.00
		
		
		self.tempVal = self.tempVal or 0;
		self.tempVal = (self.tempVal * 0.99) + temp * 0.01 -- Smooth it out.
		self.tempGauge:setValue(self.tempVal)
		self.tempGaugeIcon.backgroundColor = {r=0.4, g=0.4,b=0.4, a=1};
		if engineModData.temperature > 140 then
			self.tempGaugeIcon.backgroundColor = {r=1.0, g=0.0,b=0.0, a=1};
		elseif engineModData.temperature > 125 then
			self.tempGaugeIcon.backgroundColor = {r=1.0, g=0.6,b=0.0, a=1};
		end
		
		self.tempGaugeIcon.mouseovertext = "Engine Temp: " .. math.floor(engineModData.temperature) .. "c <LINE>Radiator Temp: " .. math.floor(engineModData.temperatureRadiator).."c";
	end
	
	
	
	self.engineTex.backgroundColor = {r=0.4, g=0.4,b=0.4, a=1};
	local engine = self.vehicle:getPartById("Engine");
	if self.vehicle:isEngineRunning() or self.vehicle:isKeysInIgnition() or self.vehicle:isStarting() then
        local cond = engine:getCondition()
        local color = ColorInfo.new(0.4, 0.4, 0.4, 1)
		local cautionColor = ColorInfo.new(1, 0.6, 0.0, 1)
		if cond < 70 then
			getCore():getBadHighlitedColor():interp(cautionColor, cond/70, color);
		end
		self.engineTex.backgroundColor = {r=color:getR(), g=color:getG(), b=color:getB(), a=alpha};
		self.engineTex.mouseovertext = "Engine: " .. tostring(engine:getCondition()).."%"
		--self.gearIndicator.name = self.vehicle:getTransmissionNumberLetter();
	end
	
	--if not self.vehicle:isEngineRunning() then
	--	self.gearIndicator.name = "P";
	--end
	
	
	local oilLevel = 0;
	local oilPan = engine and engine:getItemContainer():getFirstTag(PSC_Tags.EngineOilPan)
	local sv = SandboxVars.ProjectSummerCar	
	
	if oilPan then
		if sv.SmartOilIndicator then
			oilLevel = oilPan:getFluidContainer():getSpecificFluidAmount(Fluid.Get("MotorOil")) / oilPan:getFluidContainer():getCapacity()	
			self.oilLightImage.mouseovertext = "Oil Quality: " .. math.floor((oilLevel * 100)+0.5)  .. "% <LINE> Oil Level: " .. math.floor((oilPan:getFluidContainer():getFilledRatio()*100)+0.5) .. "%"
		else
			oilLevel = oilPan:getFluidContainer():getFilledRatio();
		end
	else
		if sv.SmartOilIndicator then
			self.oilLightImage.mouseovertext = "Oil Pan Missing!"
		end
	end	
	
	
	local oilColor = {r=0.4, g=0.4, b=0.4, a=1}
	if sv.SmartOilIndicator and oilLevel < 0.5 then
		oilColor = {r=1.0, g=0.6, b=0.0, a=1}
	end
	
	self.oilLightImage.backgroundColor = oilLevel > 0.3 and oilColor or badColor; -- grey
	

	-- Battery indicator logic
	self.batteryGauge:setValue(0)
	if self.vehicle:isEngineRunning() or self.vehicle:isKeysInIgnition() or self.vehicle:isStarting() then
        local charge = self.vehicle:getBatteryCharge()
		local fanBelt = GetPartCondition(engine,PSC_Tags.EngineFanBelt) * 0.01;
		local alternator = GetPartCondition(engine,PSC_Tags.EngineAlternator) * 0.01;
		local batteryWarningLight = charge < 0.3;
		local batteryGaugeValue = charge * 0.5;
		local chargeSpeed = 0;
		if self.vehicle:isEngineRunning() then
			--local charge = self.vehicle:getBatteryCharge();
			--local chargeSpeed = (1.2 - charge) * 0.002; -- 20%-120% speed modifier * 2x = Faster charging at lower battery, slower at higher battery than vanilla
			chargeSpeed = alternator * math.min(1,fanBelt*3); -- Fanbelt over 33% = fine
			batteryWarningLight = chargeSpeed < 0.3
			batteryGaugeValue = (charge + chargeSpeed) * 0.5
		end
		if self.vehicle:isStarting() then -- Make it dip when starting.
			batteryGaugeValue = math.max(0,batteryGaugeValue-0.07);
		end
		
		self.batteryTex.backgroundColor = batteryWarningLight and badColor or {r=0.4, g=0.4, b=0.4, a=1}
		self.chargeValue = self.chargeValue or 0
		if self.chargeValue < batteryGaugeValue then
			self.chargeValue = math.min(self.chargeValue + 0.010 * (30 / getPerformance():getUIRenderFPS()), batteryGaugeValue)
		elseif self.chargeValue > batteryGaugeValue then
			self.chargeValue = math.max(self.chargeValue - 0.015 * (30 / getPerformance():getUIRenderFPS()), batteryGaugeValue)
		end
		self.batteryTex.mouseovertext = "Battery Charge: " .. math.floor(charge*1000)/10 .. "% <LINE>Charging Rate: ".. math.floor(chargeSpeed*1000)/10 .."%";
		self.batteryGauge:setValue(self.chargeValue); 
	else
		self.batteryTex.mouseovertext = ""; 
		self.batteryTex.backgroundColor = {r=0.4, g=0.4, b=0.4, a=1}
	end
	
	local keyState = self.dash.ignition.emptyIcon;
	
	if self.vehicle:isKeysInIgnition() then
		if self.vehicle:isStarting() then
			keyState = self.dash.ignition.keyStartIcon
			
		elseif self.vehicle:isEngineRunning() then
			keyState = self.dash.ignition.keyRunIcon;
		else
			keyState = self.dash.ignition.keyOffIcon;
		end
	else
		if self.vehicle:isHotwired() then
			if self.vehicle:isEngineRunning() or self.vehicle:isStarting() then
				keyState = self.dash.ignition.hotwireOnIcon;
			else
				keyState = self.dash.ignition.hotwireOffIcon;
			end
		end
	end
	self.ignitionTex.texture = safeGetTexture(keyState.filename); 
	self.ignitionTex:setX(self.dash.ignition.x + keyState.offsetX)
	self.ignitionTex:setY(self.dash.ignition.y + keyState.offsetY)
	
	if (self.vehicle:isKeysInIgnition()) then
		if not self.wasKeyInIgnition then
			self.wasKeyInIgnition = true
			if self.character then
				self.character:playSound("VehicleInsertIgnitionKey")
			end
		end
	else
		if self.wasKeyInIgnition then
			self.wasKeyInIgnition = false
			if self.character then
				self.character:playSound("VehicleRemoveIgnitionKey")
			end
		end
	end


	if self.vehicle:getHeadlightsOn() and not self.vehicle:getHeadlightCanEmmitLight() then
		self.dash.switches.headlights.ledImage.backgroundColor = badColor
	elseif self.vehicle:getHeadlightsOn() then
		self.dash.switches.headlights.ledImage.backgroundColor = goodColor
	end
	self.dash.switches.headlights.state = self.vehicle:getHeadlightsOn();
	self.dash.switches.headlights.ledState = self.dash.switches.headlights.state;
	
	
	
	
	self.dash.switches.locks.ledState = true;
	self.dash.switches.locks.state = false;
	if self.vehicle:areAllDoorsLocked() then
		self.dash.switches.locks.ledImage.backgroundColor = badColor
		self.dash.switches.locks.state = true;
	elseif self.vehicle:isAnyDoorLocked() then
		self.dash.switches.locks.ledImage.backgroundColor = {r=1, g=1, b=0, a=alpha};
	else
		self.dash.switches.locks.ledState = false;
	end

	local heater = self.vehicle:getPartById("Heater");
	heater = heater and heater:getModData().active
	self.dash.switches.heater.state = heater == true
	self.dash.switches.heater.ledState = heater == true
	self.dash.switches.heater.ledImage.backgroundColor = goodColor
	
	
	if self.vehicle:isRegulator() then
		self.speedregulatorTex.backgroundColor = goodColor
-- 		self.speedregulatorTex.backgroundColor = {r=0, g=1, b=0, a=alpha};
	else
		self.speedregulatorTex.backgroundColor = greyBg;
	end
	
	--self.trunkTex.mouseovertext = getText("Tooltip_Dashboard_TrunkLocked")
	--self.trunkTex.mouseovertext = getText("Tooltip_Dashboard_TrunkUnlocked")

	
	self.dash.switches.trunk.state = self.vehicle:isTrunkLocked()
	self.dash.switches.trunk.ledState = self.vehicle:isTrunkLocked()
	self.dash.switches.trunk.ledImage.backgroundColor = badColor;
	
	self.dash.switches.radio.state = false;
	local radio = self.vehicle:getPartById("Radio")
	if radio and radio:getInventoryItem() then
		self.dash.switches.radio.state = radio and radio:getDeviceData()  and radio:getDeviceData():getIsTurnedOn() and (self.vehicle:isKeysInIgnition() or self.vehicle:isHotwired()) and (self.vehicle:getBatteryCharge() > 0)
		 --self.dash.switches.radio.state = ISRadioWindow.isActive(self.character, radio) -- Don't use. causes add preset/etc to not work. 
	end
	
	self.dash.switches.radio.ledState = false;
    if self.vehicle:getPartById("Radio") and self.vehicle:getPartById("Radio"):getDeviceData()  and self.vehicle:getPartById("Radio"):getDeviceData():getIsTurnedOn() then
		self.dash.switches.radio.ledState = true;
    end
	self.dash.switches.radio.ledImage.backgroundColor = goodColor
		
	for key,switch in pairs(self.dash.switches) do
		switch.image.texture = switch.state and switch.buttonTextures[2] or switch.buttonTextures[1]
		switch.ledImage:setVisible(switch.ledState)
	end
end

function VehicleDashboardReplacer:checkEngineFull()
	for i=0,self.vehicle:getPartCount() do
		local part = self.vehicle:getPartByIndex(i);
		if part and part:getLuaFunction("checkEngine") and not VehicleUtils.callLua(part:getLuaFunction("checkEngine"), self.vehicle, part) then
			return false;
		end
	end
	return true;
end
		
function VehicleDashboardReplacer:render()
	if not self.vehicle then return end

	local currentGear = self.vehicle:getTransmissionNumberLetter();
	if not self.vehicle:isEngineRunning() then
		currentGear = "P";
	end
	
	-- Consider switching to use drawTextZoomed based on selected font size to rescale things properly. 
	-- local zoom = 0.8
	local curFontSize = getCore():getOptionFontSizeReal() -- Should be cached at start of game, since it can't actually be changed midgame but the option can. 
	local fontSizeSmall = {16,19,26,33,38}
	local fontSizeMed = {23,29,33,40,45}
	
	local zoom = 1;
	if self.dash.gearIndicator.font == UIFont.Small then
		zoom = 19 / fontSizeSmall[curFontSize];
	else
		zoom = 29 / fontSizeMed[curFontSize];
	end
	
	self:drawTextZoomed(currentGear, self.dash.gearIndicator.x, self.dash.gearIndicator.y, zoom, 0, 1, 0, 0.8, self.dash.gearIndicator.font)
	--self:drawText(currentGear, self.dash.gearIndicator.x, self.dash.gearIndicator.y, 0, 1, 0, 0.8, self.dash.gearIndicator.font);


	if self.dash.cruiseControlIndicator.font == UIFont.Small then
		zoom = 19 / fontSizeSmall[curFontSize];
	else
		zoom = 29 / fontSizeMed[curFontSize];
	end
	if self.vehicle:isRegulator() then
		self:drawTextZoomed(tostring(self.vehicle:getRegulatorSpeed()), self.dash.cruiseControlIndicator.x, self.dash.cruiseControlIndicator.y, zoom, 0, 1, 0, 0.8, self.dash.cruiseControlIndicator.font);
	else
		self:drawTextZoomed(tostring(self.vehicle:getRegulatorSpeed()), self.dash.cruiseControlIndicator.x, self.dash.cruiseControlIndicator.y, zoom, 1, 1, 1, 0.3, self.dash.cruiseControlIndicator.font);
	end
end

function VehicleDashboardReplacer:onResolutionChange()

	local screenLeft = getPlayerScreenLeft(self.playerNum)
	local screenTop = getPlayerScreenTop(self.playerNum)
	local screenWidth = getPlayerScreenWidth(self.playerNum)
	local screenHeight = getPlayerScreenHeight(self.playerNum)

	if self.backgroundImage == nil then
		return;
	end
	
	--print("Current background size ",self.backgroundImage:getWidth(), " ", self.backgroundImage:getHeight())
	self:setHeight(self.backgroundImage:getHeight());
	self:setWidth(self.backgroundImage:getWidth());
	
	self:setX(screenLeft + (screenWidth - self.backgroundImage:getWidth()) / 2);
	self:setY(screenTop + screenHeight - self.height);

	if self.backgroundImage then
		self.backgroundImage:setX(0)
		self.backgroundImage:setY(0)
	end
end

function VehicleDashboardReplacer:onClickEngine()
	if getGameSpeed() == 0 then return; end
	if getGameSpeed() > 1 then setGameSpeed(1); end
	if not self.vehicle then return end
	if self.vehicle:isEngineRunning() then
		ISVehicleMenu.onShutOff(self.character)
	else
		ISVehicleMenu.onStartEngine(self.character)
	end
end

function VehicleDashboardReplacer:onClickHeadlights()
	if getGameSpeed() == 0 then return; end
	if getGameSpeed() > 1 then setGameSpeed(1); end
	ISVehicleMenu.onToggleHeadlights(self.character);
end

function VehicleDashboardReplacer:onClickDoors()
	if getGameSpeed() == 0 then return; end
	if getGameSpeed() > 1 then setGameSpeed(1); end
	ISVehiclePartMenu.onLockDoors(self.character, self.vehicle, not self.vehicle:isAnyDoorLocked());
end

function VehicleDashboardReplacer:onClickTrunk()
	if getGameSpeed() == 0 then return; end
	if getGameSpeed() > 1 then setGameSpeed(1); end
	ISVehicleMenu.onToggleTrunkLocked(self.character);
end

function VehicleDashboardReplacer:onClickHeater()
	if getGameSpeed() == 0 then return; end
	if getGameSpeed() > 1 then setGameSpeed(1); end
	if self.vehicle:getHeater() then -- prevents red error if no heater part like in RV's. 
		ISVehicleMenu.onToggleHeater(self.character)
	end
end

function VehicleDashboardReplacer:onClickRadio()
	if getGameSpeed() == 0 then return; end
	if getGameSpeed() > 1 then setGameSpeed(1); end
	local radio = self.vehicle:getPartById("Radio")
	if not radio or not radio:getInventoryItem() or not radio:getDeviceData() then return end
	getSoundManager():playUISound("VehicleRadioButton")
	if radio:getDeviceData():getIsTurnedOn() then
        radio:getDeviceData():setIsTurnedOn(false)
        if ISRadioWindow.isActive(self.character, radio) then
            ISRadioWindow.closeIfActive(self.character, radio)
        end
        return
    end
    if ISRadioWindow.isActive(self.character, radio) then
        ISRadioWindow.closeIfActive(self.character, radio)
	else
        ISVehicleMenu.onSignalDevice(self.character, radio)
    end
end

function VehicleDashboardReplacer.onEnterVehicle(character)
	local vehicle = character:getVehicle()
	if instanceof(character, 'IsoPlayer') and character:isLocalPlayer() and vehicle:isDriver(character) then
		getPlayerVehicleDashboardReplacer(character:getPlayerNum()):setVehicle(vehicle)
	end
end

function VehicleDashboardReplacer.onExitVehicle(character)
	--print("EXITING!");
	if instanceof(character, 'IsoPlayer') and character:isLocalPlayer() then
		local data = getPlayerVehicleDashboardReplacer(character:getPlayerNum())
		if data then data:setVehicle(nil) end
	end
end

function VehicleDashboardReplacer.onSwitchVehicleSeat(character)
	if instanceof(character, 'IsoPlayer') and character:isLocalPlayer() then
		local vehicle = character:getVehicle()
		if vehicle:isDriver(character) then
			getPlayerVehicleDashboardReplacer(character:getPlayerNum()):setVehicle(vehicle)
		else
			getPlayerVehicleDashboardReplacer(character:getPlayerNum()):setVehicle(nil)
		end
	end
end

function VehicleDashboardReplacer.OnGameStart()
	if isServer() then return end
	for i=1,getNumActivePlayers() do
		local playerObj = getSpecificPlayer(i-1)
		if playerObj and not playerObj:isDead() and playerObj:getVehicle() then
			VehicleDashboardReplacer.onEnterVehicle(playerObj)
		end
	end
end


function VehicleDashboardReplacer.getVehicleCondition(vehicle)
	local parts = {}
	for i=1, vehicle:getPartCount() do
		local part = vehicle:getPartByIndex(i-1)
		parts[part] = part:getCondition()
	end
	return parts
end

local function comparePartsDamage(parts1, parts2)
	for part, condition in pairs(parts1) do
		if parts2[part] ~= nil then
			if math.abs(parts2[part] - condition) > 10 then
				return true
			end
		end	
	end
	return false
end

VehicleDashboardReplacer.lastVehicleDamage = nil
VehicleDashboardReplacer.lastVehicleDamageTimer = 0
function VehicleDashboardReplacer.damageChecker()
	local character = getPlayer()
	if character == nil then return end
	if character:getVehicle() == nil then
		-- Gets called constantly? Due to using vehicle == nil to disable a vehicle... 
        VehicleDashboardReplacer.onExitVehicle(character)
    end

	if VehicleDashboardReplacer.lastVehicleDamageTimer <= 0 then	
		local vehicle = character:getVehicle()
		if vehicle ~= nil then
			if VehicleDashboardReplacer.lastVehicleDamage == nil then
				VehicleDashboardReplacer.lastVehicleDamage = VehicleDashboardReplacer.getVehicleCondition(vehicle)
			else
				local condition = VehicleDashboardReplacer.getVehicleCondition(vehicle)
				if comparePartsDamage(VehicleDashboardReplacer.lastVehicleDamage, condition) then
					VehicleDashboardReplacer.damageFlick(character)
				end
				VehicleDashboardReplacer.lastVehicleDamage = condition
			end
		else
			VehicleDashboardReplacer.lastVehicleDamage = nil
		end	
		VehicleDashboardReplacer.lastVehicleDamageTimer = 10
	else
		VehicleDashboardReplacer.lastVehicleDamageTimer = VehicleDashboardReplacer.lastVehicleDamageTimer - 1
	end
end

function VehicleDashboardReplacer.onGameStart()
	-- No longer preloading textures at game start. 
end

Events.OnGameStart.Add(VehicleDashboardReplacer.onGameStart)
Events.OnEnterVehicle.Add(VehicleDashboardReplacer.onEnterVehicle)
Events.OnExitVehicle.Add(VehicleDashboardReplacer.onExitVehicle)
Events.OnSwitchVehicleSeat.Add(VehicleDashboardReplacer.onSwitchVehicleSeat)
Events.OnTick.Add(VehicleDashboardReplacer.damageChecker)