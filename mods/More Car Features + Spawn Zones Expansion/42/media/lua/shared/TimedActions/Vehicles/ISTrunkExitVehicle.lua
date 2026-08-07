ISTrunkExitVehicle = ISBaseTimedAction:derive("ISTrunkExitVehicle")

function ISTrunkExitVehicle:isValid()
	if self.vehicle and self.vehicle:isStopped() and self.vehicle == self.character:getVehicle() then
		local contToNext
		local seat = self.vehicle:getSeat(self.character)
		if MoreCarFeatures.canEnterExitVehicleTrunk[self.fullVName] then
			if self.vehicle:getMaxPassengers() <= 2 or self.vehicle:getPassengerArea(seat):contains("SeatRear") then
				contToNext = true
			end
		elseif MoreCarFeatures.canEnterExitVehicleTrunkKI51[self.fullVName] then
			if seat >= 0 then
				contToNext = true
			end
		elseif MoreCarFeatures.canEnterExitVehicleTrunkKI52[self.fullVName] then
			if seat == 2 or seat == 3 then
				contToNext = true
			end
		elseif MoreCarFeatures.canEnterExitVehicleTrunkKI53[self.fullVName] then
			if seat == 4 or seat == 5 then
				contToNext = true
			end
		end

		if contToNext then
			if ISVehicleMenu.notBlockedPartExit(self.character, self.trunkPart) then
				return true
			else
				HaloTextHelper.addBadText(playerObj, getText("IGUI_PlayerText_DoorBlocked"))
			end
		end
	end
	return false
end

function ISTrunkExitVehicle:start()
	self.action:setBlockMovementEtc(true)

	self.faceAway = MoreCarFeatures.getVehicleDir(self.vehicle) - math.pi
end

function ISTrunkExitVehicle:update()

end

function ISTrunkExitVehicle:stop()
	
	ISBaseTimedAction.stop(self)
end

function ISTrunkExitVehicle:perform()
	local trunkExit = self.vehicle:getAreaCenter(self.trunkPart:getArea())
	self.vehicle:exit(self.character)
	self.character:setX(trunkExit:getX())
	self.character:setY(trunkExit:getY())
	self.character:setZ(self.vehicle:getZ())
	self.character:PlayAnim("Idle")
	self.character:triggerMusicIntensityEvent("VehicleExit")
	triggerEvent("OnExitVehicle", self.character)
	self.vehicle:updateHasExtendOffsetForExitEnd(self.character)

	self.character:setTargetAndCurrentDirection(math.cos(self.faceAway), math.sin(self.faceAway))

	ISBaseTimedAction.perform(self)
end

function ISTrunkExitVehicle:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 30
end

function ISTrunkExitVehicle:new(character, vehicle, doorPart)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.vehicle = vehicle
	o.fullVName = vehicle:getScript():getFullName()
	o.character = character
	o.trunkPart = doorPart
	o.maxTime = o:getDuration()
	return o
end

