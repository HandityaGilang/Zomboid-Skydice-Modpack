ISUnHotwireVehicle = ISBaseTimedAction:derive("ISUnHotwireVehicle")

function ISUnHotwireVehicle:isValid()
	local vehicle = self.character:getVehicle()
	return (vehicle ~= nil and vehicle:isDriver(self.character))
end

function ISUnHotwireVehicle:update()
	self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
end

function ISUnHotwireVehicle:start()
	self.sound = self.character:getEmitter():playSound("VehicleHotwireStart")
end

function ISUnHotwireVehicle:stop()
	self:stopSound()
	ISBaseTimedAction.stop(self)
end

function ISUnHotwireVehicle:perform()
	self:stopSound()

	ISBaseTimedAction.perform(self)
end

function ISUnHotwireVehicle:complete()
--	self.character:getVehicle():setHotwired(false)
	self.character:getVehicle():cheatHotwire(false, true)
	return true
end

function ISUnHotwireVehicle:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function ISUnHotwireVehicle:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return (500 - (20 * self.character:getPerkLevel(Perks.Electricity)) + (10 * self.character:getPerkLevel(Perks.Mechanics)) )
end

function ISUnHotwireVehicle:new(character)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = false
	o.stopOnRun = false
	o.maxTime = o:getDuration()
	return o
end

