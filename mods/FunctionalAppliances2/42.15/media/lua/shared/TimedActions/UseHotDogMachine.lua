require "TimedActions/ISBaseTimedAction"

UseHotDogMachine = ISBaseTimedAction:derive("UseHotDogMachine")

function UseHotDogMachine:isValid()
	return true
end

function UseHotDogMachine:waitToStart()
	self.character:faceThisObject(self.machine)
	return self.character:shouldBeTurning()
end

function UseHotDogMachine:update()
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

function UseHotDogMachine:start()
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Mid")
	self:setOverrideHandModels(nil, nil)

	if self.lightSource == nil then
		self.lightSource = IsoLightSource.new(self.machine:getX(), self.machine:getY(), self.machine:getZ(), 0.1, 0, 0, 1)
		self.machine:getCell():addLamppost(self.lightSource)
	end
end

function UseHotDogMachine:stop()
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

function UseHotDogMachine:perform()
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

function UseHotDogMachine:complete()
	local inv = self.character:getInventory()
	local HotdogBun = inv:FindAndReturn("Base.BunsHotdog_single")
	local BreadSlices = inv:FindAndReturn("Base.BreadSlices")
	local Sausage = inv:FindAndReturn("Base.Sausage")
	local Wiener = inv:FindAndReturn("Base.Hotdog_single")

	if self.foodType == "Hotdog" then
		if Sausage then
			inv:Remove(Sausage)
			sendRemoveItemFromContainer(inv, Sausage)
		elseif Wiener then
			inv:Remove(Wiener)
			sendRemoveItemFromContainer(inv, Wiener)
		end
		if HotdogBun then
			inv:Remove(HotdogBun)
			sendRemoveItemFromContainer(inv, HotdogBun)
		elseif BreadSlices then
			inv:Remove(BreadSlices)
			sendRemoveItemFromContainer(inv, BreadSlices)
		end
		local Hotdog = instanceItem("Base.Hotdog")
		inv:AddItem(Hotdog)
		sendAddItemToContainer(inv, Hotdog)
	else
		local playerItems = inv:getItems()
		for i=0, playerItems:size()-1 do
        		local item = playerItems:get(i)
			local itemType = nil

			if item and item:getFullType() then
				itemType = item:getFullType()
			end

			if self.foodType == "Sausage" and itemType == "Base.Sausage" and not item:isCooked() then
				inv:Remove(item)
				sendRemoveItemFromContainer(inv, item)
				local addItem1 = instanceItem("Base.Sausage")
				self.machine:getContainer():AddItem(addItem1)
				sendAddItemToContainer(self.machine:getContainer(), addItem1)
				addItem1:setCooked(true)
				sendItemStats(addItem1)
				break
			elseif self.foodType == "Wiener" and itemType == "Base.Hotdog_single" and not item:isCooked() then
				inv:Remove(item)
				sendRemoveItemFromContainer(inv, item)
				local addItem1 = instanceItem("Base.Hotdog_single")
				self.machine:getContainer():AddItem(addItem1)
				sendAddItemToContainer(self.machine:getContainer(), addItem1)
				addItem1:setCooked(true)
				sendItemStats(addItem1)
				break
			end
		end
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

function UseHotDogMachine:new(character, machine, soundFile, foodType)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.machine = machine
	o.soundFile = soundFile
	o.foodType = foodType
	o.stopOnWalk = true
	o.stopOnRun = true
	o.gameSound = 0
	o.maxTime = 240
	o.lightSource = nil
	return o
end