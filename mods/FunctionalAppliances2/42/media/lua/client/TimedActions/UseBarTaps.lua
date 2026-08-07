require "TimedActions/ISBaseTimedAction"

UseBarTaps = ISBaseTimedAction:derive("UseBarTaps")

function UseBarTaps:isValid()
	return true
end

function UseBarTaps:waitToStart()
	self.character:faceThisObject(self.machine)
	return self.character:shouldBeTurning()
end

function UseBarTaps:update()

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

function UseBarTaps:start()
	self:setActionAnim("fill_container_tap")
	self.character:SetVariable("LootPosition", "Mid")
	self:setOverrideHandModels(nil, nil)
end

function UseBarTaps:stop()

	if self.gameSound and
		self.gameSound ~= 0 and
		self.character:getEmitter():isPlaying(self.gameSound) then
		self.character:getEmitter():stopSound(self.gameSound)
	end

	local soundRadius = 15
	local volume = 6

	ISBaseTimedAction.stop(self)
end

function UseBarTaps:perform()

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

	while self.keg:getCurrentUsesFloat()/self.keg:getUseDelta() > 0 and capacity > 0 do
		local newWeightAmount = 2 + (math.floor(self.keg:getCurrentUsesFloat()/self.keg:getUseDelta()) - 1) * 0.375
		self.keg:setCustomWeight(true)
		self.keg:setActualWeight(newWeightAmount)
		self.keg:Use()
		capacity = capacity - 1

		if self.keg:getType() == "FABubKeg" then
			self.container:getFluidContainer():addFluid("FABubBeer", 1)
		elseif self.keg:getType() == "FABubLiteKeg" then
			self.container:getFluidContainer():addFluid("FABubLiteBeer", 1)
		elseif self.keg:getType() == "FASwillerKeg" then
			self.container:getFluidContainer():addFluid("FASwillerBeer", 1)
		elseif self.keg:getType() == "FASwillerLiteKeg" then
			self.container:getFluidContainer():addFluid("FASwillerLiteBeer", 1)
		elseif self.keg:getType() == "FAHomeBrewKeg" then
			self.container:getFluidContainer():addFluid("FAHomeBrewBeer", 1)
		else
			self.container:getFluidContainer():addFluid("Beer", 1)
		end
	end

	if self.keg and self.keg.getContainer and self.keg:getContainer() ~= nil then
		self.keg:getContainer():requestSync()
	end

	ISBaseTimedAction.perform(self)
end

function UseBarTaps:new(character, machine, sound, keg, container)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.machine = machine
	o.soundFile = sound
	o.keg = keg
	o.container = container
	o.stopOnWalk = true
	o.stopOnRun = true
	o.gameSound = 0
	o.maxTime = 170
	return o
end