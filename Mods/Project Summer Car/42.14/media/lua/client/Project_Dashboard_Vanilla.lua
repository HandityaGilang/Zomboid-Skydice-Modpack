local PSC_Tags = ProjectSummerCar_Tags


function ISInventoryPage:onLoseJoypadFocus(joypadData)
    ISPanel.onLoseJoypadFocus(self, joypadData)

    self.inventoryPane.doController = false;
    local inv = getPlayerInventory(self.player);
	if not inv then
        return;
    end
    local loot = getPlayerLoot(self.player);
    if inv.joyfocus or loot.joyfocus then
      --  self.inventoryPane.doController = false;
        return;
    end

    if getFocusForPlayer(self.player) == nil then
        inv:setVisible(false);
        loot:setVisible(false);
        local playerObj = getSpecificPlayer(self.player)
        playerObj:setBannedAttacking(false)
        if playerObj:getVehicle() and playerObj:getVehicle():isDriver(playerObj) then
			local dashboardreplacer = getPlayerVehicleDashboardReplacer(self.player)
			if dashboardreplacer.dashBoardSelect == 0 then
				getPlayerVehicleDashboard(self.player):addToUIManager()
			else
				dashboardreplacer:addToUIManager();
			end
        end
      --  self.inventoryPane.doController = false;
    end

end

function ISInventoryPage:onGainJoypadFocus(joypadData)
    ISPanel.onGainJoypadFocus(self, joypadData)

    local inv = getPlayerInventory(self.player);
    local loot = getPlayerLoot(self.player);
    inv:setVisible(true);
    loot:setVisible(true);
			local dashboardreplacer = getPlayerVehicleDashboardReplacer(self.player)
			if dashboardreplacer.dashBoardSelect == 0 then
				getPlayerVehicleDashboard(self.player):removeFromUIManager()
			else
				dashboardreplacer:removeFromUIManager();
			end
    self.inventoryPane.doController = true;
end


local oldSetVehicle = ISVehicleDashboard.setVehicle
function ISVehicleDashboard:setVehicle(vehicle)
	local dashboardSelect = getPlayerVehicleDashboardReplacer(self.playerNum):getSelectedDashboard(vehicle)
	if dashboardSelect == 0 then
		oldSetVehicle(self,vehicle)
	else
		oldSetVehicle(self,nil)
	end
end

function ISPanel:mouseDownBonus(x, y)
	self.mouseDownTime = getTimestampMs();
	self.mouseDown = true;
	ISPanel:onMouseDown(x, y)
end

function ISVehicleDashboard:onClickKeysAdvanced()
	self.ignitionTex.mouseDown = false;

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
		if self.vehicle:isKeysInIgnition() then
			self.vehicle:setKeysInIgnition(false);
		else
			self.vehicle:setKeysInIgnition(true);
		end
	end
end


local oldDashboardpreender = ISVehicleDashboard.prerender
function ISVehicleDashboard:prerender()
oldDashboardpreender(self)

	if not self.vehicle or not ISUIHandler.allUIVisible then return end
	
	local engine = self.vehicle:getPartById("Engine");
	local engineContainer = engine and engine:getItemContainer()
	local oilLevel = 0;
	local oilPan = engineContainer and engineContainer:getFirstTag(PSC_Tags.EngineOilPan)
	
	if oilPan then
		oilLevel = oilPan:getFluidContainer():getFilledRatio();
	end
	
	local waterLevel = 0;
	local radiator = engineContainer and engineContainer:getFirstTag(PSC_Tags.EngineRadiator)
	if radiator then
		waterLevel = radiator:getFluidContainer():getFilledRatio();
	end	
	
	local engineData = engine and engine:getModData()
	local engineTemp = engineData and engineData.temperature;
	if engineTemp == nil then
		engineTemp = 22
	end
	-- Todo: Add temp mouseover to temp gauge? Just place a fake transparent image over it?
	--self.tempGaugeTex.mouseovertext = "Temperature: " .. engineData.temperature .. "C" 

	if engine then
		self.engineTex.mouseovertext = "Engine: ".. engine:getCondition() .. "% <LINE> Oil: " .. string.format("%.2f", oilLevel*100) .. "% <LINE> Temp: " .. string.format("%.0f", engineTemp) .. "C <LINE> Coolant: " .. string.format("%.2f", waterLevel*100) .. "% "
	else
		self.engineTex.mouseovertext = "Engine not found."
	end

	local battery = self.vehicle:getPartById("Battery");
	if battery then
		batteryItem = battery:getInventoryItem();
		if batteryItem then
			self.batteryTex.mouseovertext = "Battery: " .. batteryItem:getCondition() .. "% <LINE> Charge: " .. string.format("%.2f", batteryItem:getCurrentUsesFloat()*100) .. "%"
		end
	end


	
	
	-- Should really be done somewhere else. 
	if self.ignitionTex.mouseDown == true then 
		if getTimestampMs() - self.ignitionTex.mouseDownTime > 200 then
			ISVehicleMenu.onStartEngine(self.character)
			--print("Starting Engine!")
		end
	end
	
	if self.vehicle:isHotwired() then
		self.ignitionTex.texture = self.iconIgnitionHotwired;
	else
		if self.vehicle:isKeysInIgnition() then
			if self.vehicle:isStarting() then
				self.ignitionTex.texture = self.iconIgnitionKey -- Key to vertical
			elseif self.vehicle:isEngineRunning() then
				self.ignitionTex.texture = self.iconIgnitionStarting -- Key to 45
			else
				self.ignitionTex.texture = self.iconIgnitionStarted -- Key to horzontal
			end
		else
			self.ignitionTex.texture = self.iconIgnition; -- No key
		end
	end
end

local oldDashboardCreateChildren = ISVehicleDashboard.createChildren;
function ISVehicleDashboard:createChildren()
	oldDashboardCreateChildren(self)
	-- Modify ignition switch to be able to detect long press. 
	self.ignitionTex.onMouseDown = ISPanel.mouseDownBonus
	self.ignitionTex.onclick = ISVehicleDashboard.onClickKeysAdvanced;
	
	self.iconIgnitionStarting = getTexture("media/textures/ignition_key_starting.png");

	self.tempGaugeTex = getTexture("media/textures/TempGauge.png");
	local x = 50
	local y = self.backgroundTex:getHeight() - self.tempGaugeTex:getHeight() - 70
	self.tempGauge = ISVehicleGauge:new(x, y, self.tempGaugeTex, 20, 30, 45, -45)
	self.tempGauge:initialise()
	self.tempGauge:instantiate()
	self.tempGauge:setNeedleWidth(20)
	self:addChild(self.tempGauge)	
end


oldDashboardRender = ISVehicleDashboard.render
function ISVehicleDashboard:render()
return oldDashboardRender(self)
end

oldDashboardPrerender = ISVehicleDashboard.prerender
function ISVehicleDashboard:prerender()
		
	if self.vehicle then
	local engineVehiclePart = self.vehicle:getPartById("Engine");
	
	local engineModData = engineVehiclePart and engineVehiclePart:getModData()
		if engineModData and engineModData.temperature then
			local temp = math.min(engineModData.temperature / (75 * 4),0.25) -- Scale 0~75 to 0~0.25
			temp = temp + math.min(math.max((engineModData.temperature - 75) / 100.0,0),0.75) -- Scale 75~150 to 0~0.75, added to the previous 0.25 for 0.25~1.00
	
			--print("temp ".. engineModData.temperature .. " after " .. temp)
			self.tempVal = self.tempVal or 0;
			self.tempVal = (self.tempVal * 0.99) + temp * 0.01 -- Smooth it out.
			
			--self.tempVal = self.tempVal + 0.01 -- Debug test for setting up gauge. 
			--if self.tempVal > 1 then
			--	self.tempVal = 0
			--end
			
			self.tempGauge:setValue(self.tempVal)
		end
	end
	return oldDashboardPrerender(self)
end