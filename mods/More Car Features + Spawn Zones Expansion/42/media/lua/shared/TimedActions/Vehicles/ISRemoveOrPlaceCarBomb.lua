ISRemoveOrPlaceCarBomb = ISBaseTimedAction:derive("ISRemoveOrPlaceCarBomb")

function ISRemoveOrPlaceCarBomb:isValid()
	if not SandboxVars.GamestaVehicleZones.interactBombVehicle then return false end

	if not self.vehicle or (self.started and self.vehicle ~= self.character:getNearVehicle()) then		--vehicle must be the one in front of the player, obviously
		return false
	elseif not self.vehicle:isStopped() then		--vehicle cannot be moving
		return false
	end

	if not self.vehicle:getModData().CarBombSlots then
		self.vehicle:getModData().CarBombSlots = {}
	end
	local bombData = self.vehicle:getModData().CarBombSlots[self.plantType] or {}

	local part = self.vehicle:getPartById(self.plantType)
	if part and part:getDoor() and part:getInventoryItem() and not part:getDoor():isOpen() then
		return false
	elseif self.plantType == "Ignition" and part ~= self.vehicle:getPassengerDoor(0) then
		part = self.vehicle:getPassengerDoor(0)
		if part and part:getDoor() and part:getInventoryItem() and not part:getDoor():isOpen() then
			return false
		end
	end

	if self.bomb then
		if self.plantType == "Ignition" and (self.vehicle:isStarting() or self.vehicle:isEngineRunning() or self.vehicle:isEngineStarted()) then		--cannot plant bomb for ignition start if vehicle already on or starting
			return false
		end

		if bombData[1] then		--bomb planted by someone else
			if isClient() then
				if self.finalTick then
					return false
				end
				self.finalTick = true
			else
				return false
			end
		end

		if string.contains(self.bomb:getScriptItem():getFullName(), "Sensor") and (self.character:getPerkLevel(Perks.Electricity) < 4 or self.character:getPerkLevel(Perks.Mechanics) < 3) then
			return false
		end

		return true

	else
		if not bombData[1] then		--bomb triggered or removed
			if isClient() then
				if self.finalTick then
					return false
				end
				self.finalTick = true
			else
				return false
			end
		end

		if string.contains(bombData[1], "Sensor") and (self.character:getPerkLevel(Perks.Electricity) < 5 or self.character:getPerkLevel(Perks.Mechanics) < 2) then
			return false
		end

		return true

	end
end

function ISRemoveOrPlaceCarBomb:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISRemoveOrPlaceCarBomb:serverStart()
	self.vehicle:getModData().CarBombSlots = self.vehicle:getModData().CarBombSlots or {}
end

function ISRemoveOrPlaceCarBomb:start()
	if self.bomb then
		if isClient() then
			self.bomb = self.character:getInventory():getItemById(self.bomb:getID())
		end
		self.bomb:setJobType(getText("ContextMenu_TrapPlace", self.bomb:getName()))
		self.bomb:setJobDelta(0.0)
	end

	self:setOverrideHandModels(nil, nil)
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Low")

	self.started = true
end

function ISRemoveOrPlaceCarBomb:update()
	if self.bomb then
		self.bomb:setJobDelta(self:getJobDelta())
	end

	self.character:setMetabolicTarget(Metabolics.UsingTools)
end

function ISRemoveOrPlaceCarBomb:stop()
	if self.bomb then
		self.bomb:setJobDelta(0.0)
	end

	ISBaseTimedAction.stop(self)
end

function ISRemoveOrPlaceCarBomb:perform()
	if self.bomb then
		self.bomb:setJobDelta(0.0)

		HaloTextHelper.addGoodText(self.character, getText("Bomb Has Been Planted"))
	else
		HaloTextHelper.addGoodText(self.character, getText("Bomb Has Been Removed"))
	end

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISRemoveOrPlaceCarBomb:complete()
	if not SandboxVars.GamestaVehicleZones.interactBombVehicle then return false end

	local bombData = self.vehicle:getModData().CarBombSlots[self.plantType]
	if self.bomb then
		if bombData and bombData[1] then
			return false
		else
			if isClient() and not self.character:getInventory():containsID(self.bomb:getID()) then
				return false
			elseif not self.character:getInventory():contains(self.bomb) then
				return false
			end
		end

		self.character:removeFromHands(self.bomb)
		self.character:getInventory():Remove(self.bomb)
		sendRemoveItemFromContainer(self.character:getInventory(), self.bomb)

		self.vehicle:getModData().CarBombSlots[self.plantType] = {self.bomb:getScriptItem():getFullName(), self.character:getOnlineID(), nil}
	else
		if not bombData or not bombData[1] then
			return false
		end

		local removedBomb = instanceItem(bombData[1])
		self.character:getInventory():AddItem(removedBomb)
		sendAddItemToContainer(self.character:getInventory(), removedBomb)

		self.vehicle:getModData().CarBombSlots[self.plantType] = nil
	end

	if isServer() then
	--	self.vehicle:transmitModData()
		local args = { vehicleId = self.vehicle:getId(), CarBombSlotsMD = self.vehicle:getModData().CarBombSlots[self.plantType], PT = self.plantType }
		sendServerCommand("MoreCarFeatures", "CarBombTransmitModData", args)
	end

--	local trap = IsoTrap.new(self.character, self.bomb, self.square:getCell(), self.square)
--	trap:place()
--	buildUtil.setHaveConstruction(self.square, true)
	return true
end

function ISRemoveOrPlaceCarBomb:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return (1000 - (20 * self.character:getPerkLevel(Perks.Electricity)) + (10 * self.character:getPerkLevel(Perks.Mechanics)) )
end

function ISRemoveOrPlaceCarBomb:new(character, vehicle, bomb, plantType)
	local o = ISBaseTimedAction.new(self, character)
	o.vehicle = vehicle
	o.bomb = bomb
	o.plantType = plantType
	o.maxTime = o:getDuration()
	return o
end
