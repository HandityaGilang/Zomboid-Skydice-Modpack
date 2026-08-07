ISRefuelFromGasPumpToggle = ISBaseTimedAction:derive("ISRefuelFromGasPumpToggle")

function ISRefuelFromGasPumpToggle:isValid()
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		return false
	end

	if not isClient() then
		local vehicleMD = self.vehicle:getModData().statusFuelPumpNozzle or {}
		if not vehicleMD[1] or vehicleMD[2] or self.toggle == vehicleMD[5] then
			return false
		end
	end

	return self.vehicle:isStopped() and self.vehicle:isInArea(self.part:getArea(), self.character)
end

function ISRefuelFromGasPumpToggle:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISRefuelFromGasPumpToggle:update()

end

function ISRefuelFromGasPumpToggle:start()
	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)
	self.character:reportEvent("EventTakeWater")
end

function ISRefuelFromGasPumpToggle:stop()

	ISBaseTimedAction.stop(self)
end

function ISRefuelFromGasPumpToggle:perform()

	ISBaseTimedAction.perform(self)
end

function ISRefuelFromGasPumpToggle:complete()
	local vehicleMD = self.vehicle:getModData().statusFuelPumpNozzle or {}
	if isServer() then
		if not vehicleMD[1] or vehicleMD[2] or self.toggle == vehicleMD[5] then
			return false
		end
	end

	self.vehicle:getModData().statusFuelPumpNozzle = { true, false, vehicleMD[3], vehicleMD[4], self.toggle }
	self.vehicle:transmitModData()

	return true
end

function ISRefuelFromGasPumpToggle:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 10
end

function ISRefuelFromGasPumpToggle:new(character, part, fuelStation, toggle)
	local o = ISBaseTimedAction.new(self, character)
	o.part = part
	o.vehicle = part:getVehicle()
	o.fuelStation = fuelStation
	o.toggle = toggle
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = o:getDuration()
	return o
end

