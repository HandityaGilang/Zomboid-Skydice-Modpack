require "TimedActions/ISBaseTimedAction"

UsePopcornMachine = ISBaseTimedAction:derive("UsePopcornMachine")

function UsePopcornMachine:isValid()
	return true
end

function UsePopcornMachine:waitToStart()
	self.character:faceThisObject(self.machine)
	return self.character:shouldBeTurning()
end

function UsePopcornMachine:update()
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

function UsePopcornMachine:start()
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Mid")
	self:setOverrideHandModels(nil, nil)

	if self.lightSource == nil then
		self.lightSource = IsoLightSource.new(self.machine:getX(), self.machine:getY(), self.machine:getZ(), 0.1, 0.1, 0, 1)
		self.machine:getCell():addLamppost(self.lightSource)
	end
end

function UsePopcornMachine:stop()
	if self.gameSound and
		self.gameSound ~= 0 and
		self.character:getEmitter():isPlaying(self.gameSound) then
		self.character:getEmitter():stopSound(self.gameSound)
	end

	local soundRadius = 15
	local volume = 6
	
    	if self.lightSource ~= nil then
        	self.machine:getCell():removeLamppost(self.lightSource)	
        	self.lightSource = nil
    	end

	ISBaseTimedAction.stop(self)
end

function UsePopcornMachine:perform()
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

    	if self.lightSource ~= nil then
        	self.machine:getCell():removeLamppost(self.lightSource)	
        	self.lightSource = nil
    	end

	ISBaseTimedAction.perform(self)
end

function UsePopcornMachine:complete()
	local inv = self.character:getInventory()
	local instantPopcorn = inv:FindAndReturn("Base.Popcorn")

	if instantPopcorn then
		inv:Remove(instantPopcorn)
		sendRemoveItemFromContainer(inv, instantPopcorn)

		local addItem1 = instanceItem("FunctionalAppliances.FATheaterPopcorn")
		self.machine:getContainer():AddItem(addItem1)
		sendAddItemToContainer(self.machine:getContainer(), addItem1)

		local addItem2 = instanceItem("FunctionalAppliances.FATheaterPopcorn")
		self.machine:getContainer():AddItem(addItem2)
		sendAddItemToContainer(self.machine:getContainer(), addItem2)

		local addItem3 = instanceItem("FunctionalAppliances.FATheaterPopcorn")
		self.machine:getContainer():AddItem(addItem3)
		sendAddItemToContainer(self.machine:getContainer(), addItem3)
	end
	self.machine:sync()

	local xp = self.character:getXp()
	local perkBoost = xp:getPerkBoost(Perks.Cooking)
	local multiplier = xp:getMultiplier(Perks.Cooking)
	local baseXP = 1

	if perkBoost == 1 then
		baseXP = baseXP * 1.75
	elseif perkBoost == 2 then
		baseXP = baseXP * 2
	elseif perkBoost == 3 then
		baseXP = baseXP * 2.25
	end

	if multiplier ~= 0 then
		baseXP = baseXP * multiplier
	end
	
	addXp(self.character, Perks.Cooking, baseXP)

	return true
end

function UsePopcornMachine:new(character, machine, soundFile)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.machine = machine
	o.soundFile = soundFile
	o.stopOnWalk = true
	o.stopOnRun = true
	o.gameSound = 0
	o.maxTime = 250
	o.lightSource = nil
	return o
end