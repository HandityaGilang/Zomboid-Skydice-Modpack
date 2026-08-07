require "TimedActions/ISBaseTimedAction"

UseSodaFountain = ISBaseTimedAction:derive("UseSodaFountain")

function UseSodaFountain:isValid()
	return true
end

function UseSodaFountain:waitToStart()
	self.character:faceThisObject(self.machine)
	return self.character:shouldBeTurning()
end

function UseSodaFountain:update()
	local isPlaying = self.gameSound
		and self.gameSound ~= 0
		and self.character:getEmitter():isPlaying(self.gameSound)

	if not isPlaying then
		local soundRadius = 13
		local volume = 6

		self.gameSound = self.character:getEmitter():playSound(self.soundFile)
		
		addSound(self.character,
				 self.character:getX(),
				 self.character:getY(),
				 self.character:getZ(),
				 soundRadius,
				 volume)
	end
	
	self.character:faceThisObject(self.machine)
end

function UseSodaFountain:start()
	self:setActionAnim("fill_container_tap")
	self.character:SetVariable("LootPosition", "Mid")
	self:setOverrideHandModels(nil, nil)
end

function UseSodaFountain:stop()
	if self.gameSound and
		self.gameSound ~= 0 and
		self.character:getEmitter():isPlaying(self.gameSound) then
		self.character:getEmitter():stopSound(self.gameSound)
	end

	local soundRadius = 15
	local volume = 6

	ISBaseTimedAction.stop(self)
end

function UseSodaFountain:perform()
	if self.gameSound and
		self.gameSound ~= 0 and
		self.character:getEmitter():isPlaying(self.gameSound) then
		self.character:getEmitter():stopSound(self.gameSound)
	end

	local soundRadius = 13
	local volume = 6
		
	addSound(self.character,
			 self.character:getX(),
			 self.character:getY(),
			 self.character:getZ(),
			 soundRadius,
			 volume)

	local capacity = self.container:getFluidContainer():getCapacity()

	if self.syrup:getType() == "FAEmptySodaSyrupBox" then
		while self.tank:getCurrentUsesFloat()/self.tank:getUseDelta() > 0 and (self.machine:getFluidAmount() > 0 or self.jug:getFluidContainer():getAmount() > 0) and capacity > 0 do
			if self.machine:getFluidAmount() > 0 then
				self.machine:useFluid(1)
			else
				self.jug:getFluidContainer():removeFluid(1)
			end

			local newTankWeightAmount = 5 + (math.floor(self.tank:getCurrentUsesFloat()/self.tank:getUseDelta()) - 1) * 0.05
			self.tank:setCustomWeight(true)
			self.tank:setActualWeight(newTankWeightAmount)
			self.tank:Use()
			capacity = capacity - 1

			self.container:getFluidContainer():addFluid("CarbonatedWater", 1)
		end
	else
		while self.syrup:getCurrentUsesFloat()/self.syrup:getUseDelta() > 0 and self.tank:getCurrentUsesFloat()/self.tank:getUseDelta() > 0 and (self.machine:getFluidAmount() > 0 or self.jug:getFluidContainer():getAmount() > 0) and capacity > 0 do
			if self.syrup:getType() ~= "FAEmptySodaSyrupBox" then
				local newWeightAmount = 1 + (math.floor(self.syrup:getCurrentUsesFloat()/self.syrup:getUseDelta()) - 1) * 0.1875
				self.syrup:setCustomWeight(true)
				self.syrup:setActualWeight(newWeightAmount)
				self.syrup:Use()
			end

			if self.machine:getFluidAmount() > 0 then
				self.machine:useFluid(1)
			else
				self.jug:getFluidContainer():removeFluid(1)
			end

			local newTankWeightAmount = 5 + (math.floor(self.tank:getCurrentUsesFloat()/self.tank:getUseDelta()) - 1) * 0.05
			self.tank:setCustomWeight(true)
			self.tank:setActualWeight(newTankWeightAmount)
			self.tank:Use()
			capacity = capacity - 1

			if self.syrup:getType() == "FAMixedBerriesSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("FAMixedBerries", 1)
			elseif self.syrup:getType() == "FAOrangeSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("SodaPop", 1)
			elseif self.syrup:getType() == "FALemonLimeSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("FALemonLime", 1)
			elseif self.syrup:getType() == "FARootBeerSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("FARootBeer", 1)
			elseif self.syrup:getType() == "FAKYColaSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("FAKYCola", 1)
			elseif self.syrup:getType() == "FAColaSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("Cola", 1)
			elseif self.syrup:getType() == "FADietColaSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("ColaDiet", 1)
			elseif self.syrup:getType() == "FAGingerAleSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("GingerAle", 1)
			elseif self.syrup:getType() == "FABlueberrySodaSyrupBox" then
				self.container:getFluidContainer():addFluid("SodaBlueberry", 1)
			elseif self.syrup:getType() == "FABubblegumSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("SodaBubblegum", 1)
			elseif self.syrup:getType() == "FALimeSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("SodaLime", 1)
			elseif self.syrup:getType() == "FAGrapeSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("SodaGrape", 1)
			elseif self.syrup:getType() == "FAPineappleSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("SodaPineapple", 1)
			elseif self.syrup:getType() == "FAStrawberrySodaSyrupBox" then
				self.container:getFluidContainer():addFluid("SodaStrewberry", 1)
			elseif self.syrup:getType() == "FADrPeppaSodaSyrupBox" then
				self.container:getFluidContainer():addFluid("FADrPeppa", 1)
			else
				self.container:getFluidContainer():addFluid("CarbonatedWater", 1)
			end
		end
	end

	if self.tank and self.tank.getContainer and self.tank:getContainer() ~= nil then
		self.tank:getContainer():requestSync()
	end

	ISBaseTimedAction.perform(self)
end

function UseSodaFountain:new(character, machine, sound, container, syrup, tank, jug)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.machine = machine
	o.soundFile = sound
	o.container = container
	o.syrup = syrup
	o.tank = tank
	o.jug = jug
	o.stopOnWalk = true
	o.stopOnRun = true
	o.gameSound = 0
	o.maxTime = 170
	return o
end