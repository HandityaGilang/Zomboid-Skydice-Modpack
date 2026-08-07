ISRepairFuelPump = ISBaseTimedAction:derive("ISRepairFuelPump")

function ISRepairFuelPump:isValid()
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		return false
	end

	self.fuelStation:getModData().FuelPumpsInUseOrBroken = self.fuelStation:getModData().FuelPumpsInUseOrBroken or {}
	local pumps = self.fuelStation:getModData().FuelPumpsInUseOrBroken
	for i = #pumps, 1, -1 do
		if pumps[i][1] == self.dir then
			if not pumps[i][2] then
				return false
			end
			break
		end
	end

	if self.started then
		local glue, hose
		for _, item in ipairs(self.reqItems) do
			local itemName = item:getScriptItem():getFullName()
			if itemName == "Base.Woodglue" then
				if item:getUses() ~= 5 then
					return false
				end
				glue = true
			elseif itemName == "Base.RubberHose" then
				hose = true
			else
				return false
			end

			if isClient() and not self.character:getInventory():containsID(item:getID()) then
				return false
			elseif not self.character:getInventory():contains(item) then
				return false
			end
		end

		if not (glue and hose) then
			return false
		end
	end

	return self.character:getPerkLevel(Perks.Maintenance) >= 1 and self.character:getCurrentSquare() == self.standSquare
end

function ISRepairFuelPump:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function ISRepairFuelPump:start()
	self.reqItems = {self.woodglue, self.rubberhose}
	self.started = true

	self:setOverrideHandModels(nil, nil)
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Low")
end

function ISRepairFuelPump:update()
	self.character:faceLocation(self.square:getX(), self.square:getY())

	for _, item in ipairs(self.reqItems) do
		item:setJobDelta(self:getJobDelta())
	end

	self.character:setMetabolicTarget(Metabolics.UsingTools)
end

function ISRepairFuelPump:stop()
	for _, item in ipairs(self.reqItems) do
		item:setJobDelta(0.0)
	end

	ISBaseTimedAction.stop(self)
end

function ISRepairFuelPump:perform()
	for _, item in ipairs(self.reqItems) do
		item:setJobDelta(0.0)
	end

	ISBaseTimedAction.perform(self)
end

function ISRepairFuelPump:complete()
	local reqItems = {self.woodglue, self.rubberhose}
	for _, item in ipairs(reqItems) do
		self.character:removeFromHands(item)
		self.character:getInventory():Remove(item)
		sendRemoveItemFromContainer(self.character:getInventory(), item)
	end

	addXp(self.character, Perks.Maintenance, 10)

	self.fuelStation:getModData().FuelPumpsInUseOrBroken = self.fuelStation:getModData().FuelPumpsInUseOrBroken or {}
	local pumps = self.fuelStation:getModData().FuelPumpsInUseOrBroken
	for i = #pumps, 1, -1 do
		if pumps[i][1] == self.dir then
			table.remove(self.fuelStation:getModData().FuelPumpsInUseOrBroken, i)
			self.fuelStation:transmitModData()
			break
		end
	end

	return true
end

function ISRepairFuelPump:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return (500 - (30 * self.character:getPerkLevel(Perks.Maintenance)) )
end

function ISRepairFuelPump:new(character, fuelStation, standSquare, dir, woodglue, rubberhose)
	local o = ISBaseTimedAction.new(self, character)
	o.standSquare = standSquare
	o.fuelStation = fuelStation
	o.square = fuelStation:getSquare()
	o.dir = dir
	o.woodglue = woodglue
	o.rubberhose = rubberhose
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = o:getDuration()
	return o
end
