ISInsertOrRemoveFuelPump = ISBaseTimedAction:derive("ISInsertOrRemoveFuelPump")

function ISInsertOrRemoveFuelPump:isValid()
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		return false
	end

	if not isClient() then
		local vehicleMD = self.vehicle:getModData().statusFuelPumpNozzle or {}
		if vehicleMD[5] or (vehicleMD[1] and self.insert) or (not vehicleMD[1] and not self.insert) then
			return false
		end
	end

	return self.vehicle:isStopped() and self.vehicle:isInArea(self.part:getArea(), self.character)
end

function ISInsertOrRemoveFuelPump:waitToStart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISInsertOrRemoveFuelPump:update()

end

function ISInsertOrRemoveFuelPump:start()
	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)

	if self.insert then
		self.vehicle:getEmitter():playSound("DoorOpen")
	end
end

function ISInsertOrRemoveFuelPump:stop()

	ISBaseTimedAction.stop(self)
end

function ISInsertOrRemoveFuelPump:perform()
	if not self.insert then
		self.vehicle:getEmitter():playSound("DoorOpen")
	end

	ISBaseTimedAction.perform(self)
end

function ISInsertOrRemoveFuelPump:complete()
	local vehicleMD = self.vehicle:getModData().statusFuelPumpNozzle or {}
	if isServer() then
		if vehicleMD[5] or (vehicleMD[1] and self.insert) or (not vehicleMD[1] and not self.insert) then
			return false
		end
	end

	if self.fuelStation then
		self.fuelStation:getModData().FuelPumpsInUseOrBroken = self.fuelStation:getModData().FuelPumpsInUseOrBroken or {}
		local pumps = self.fuelStation:getModData().FuelPumpsInUseOrBroken

		local pumpSide
		local square = self.fuelStation:getSquare()
		if self.insert then
			local centerArea = self.vehicle:getAreaCenter(self.part:getArea())
			local dir = self.fuelStation:getFacing()
			if dir == IsoDirections.E then
				if centerArea:getX() < square:getX()+0.5 then
					pumpSide = "W"
				else
					pumpSide = "E"
				end
			elseif dir == IsoDirections.S then
				if centerArea:getY() < square:getY()+0.5 then
					pumpSide = "N"
				else
					pumpSide = "S"
				end
			end

			table.insert(self.fuelStation:getModData().FuelPumpsInUseOrBroken, {pumpSide, false})
		else
			pumpSide = vehicleMD[3]

			if not vehicleMD[2] then
				for i = #pumps, 1, -1 do
					if pumps[i][1] == vehicleMD[3] then
						table.remove(self.fuelStation:getModData().FuelPumpsInUseOrBroken, i)
						break
					end
				end
			end
		end
		self.fuelStation:transmitModData()

		self.vehicle:getModData().statusFuelPumpNozzle = { self.insert, false, pumpSide, {math.floor(square:getX()), math.floor(square:getY())}, false }

		if self.insert then
			MoreCarFeatures.attachedFuelPump(self.vehicle:getId(), self.fuelStation)
		end
	else
		self.vehicle:getModData().statusFuelPumpNozzle = { false, false, vehicleMD[3], vehicleMD[4], false }
	end
	self.vehicle:transmitModData()

	return true
end

function ISInsertOrRemoveFuelPump:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	elseif self.character:hasTrait(CharacterTrait.DEXTROUS) then
		return 15
	elseif self.character:hasTrait(CharacterTrait.ALL_THUMBS) or self.character:isWearingAwkwardGloves() then
		return 60
	end
	return 30
end

function ISInsertOrRemoveFuelPump:new(character, part, fuelStation, insert)
	local o = ISBaseTimedAction.new(self, character)
	o.part = part
	o.vehicle = part:getVehicle()
	o.fuelStation = fuelStation
	o.insert = insert
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = o:getDuration()
	return o
end
