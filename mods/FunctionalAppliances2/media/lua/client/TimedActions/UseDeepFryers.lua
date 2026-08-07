require "TimedActions/ISBaseTimedAction"

UseDeepFryers = ISBaseTimedAction:derive("UseDeepFryers")

function UseDeepFryers:isValid()
	return true
end

local function theEnd(player, machine, foodChoice)
	local player = getPlayer()
	local xp = player:getXp()
	local perkBoost = xp:getPerkBoost(Perks.Cooking)
	local multiplier = xp:getMultiplier(Perks.Cooking)
	local baseXP = 1

	local inv = player:getInventory()

	if foodChoice == "French Fries" then
		if inv:FindAndReturn("SapphCooking.CutPeeledPotato") then
			inv:Remove("CutPeeledPotato")
			inv:AddItem("Base.Fries")
		elseif inv:FindAndReturn("FunctionalAppliances.FAPotatoWedges") then
			inv:Remove("FAPotatoWedges")
			inv:AddItem("Base.Fries")
		end
	elseif foodChoice == "Potato Skins" then
		if inv:FindAndReturn("SapphCooking.PotatoPeel") then
			inv:Remove("PotatoPeel")
			inv:AddItem("FunctionalAppliances.FAFriedPotatoSkins")
		elseif inv:FindAndReturn("FunctionalAppliances.FAPotatoSkins") then
			inv:Remove("FAPotatoSkins")
			inv:AddItem("FunctionalAppliances.FAFriedPotatoSkins")
		end
	elseif foodChoice == "Onion Rings" then
		if inv:FindAndReturn("Base.FriedOnionRingsCraft") then
			inv:Remove("FriedOnionRingsCraft")
			inv:AddItem("Base.FriedOnionRings")
		end
	elseif foodChoice == "Blooming Onion" then
		if inv:FindAndReturn("FunctionalAppliances.FABatteredBloomingOnion") then
			inv:Remove("FABatteredBloomingOnion")
			inv:AddItem("FunctionalAppliances.FAFriedBloomingOnion")
		end
	elseif foodChoice == "Tortillas" then
		if inv:FindAndReturn("SapphCooking.CutTortilla") then
			inv:Remove("CutTortilla")
			inv:AddItem("SapphCooking.SapphTortillaChips")
		end
	elseif foodChoice == "Shrimp" then
		if inv:FindAndReturn("Base.ShrimpFriedCraft") then
			inv:Remove("ShrimpFriedCraft")
			inv:AddItem("Base.ShrimpFried")
		end
	elseif foodChoice == "Fish Fillet" then
		if inv:FindAndReturn("SapphCooking.FishFilletinBatter") then
			inv:Remove("FishFilletinBatter")
			inv:AddItem("SapphCooking.SapphFishFried")
		end
	elseif foodChoice == "Corndog" then
		if inv:FindAndReturn("SapphCooking.SausageinBatter") then
			inv:Remove("SausageinBatter")
			inv:AddItem("SapphCooking.SapphCorndog")
		end
	elseif foodChoice == "Fried Chicken" then
		if inv:FindAndReturn("FunctionalAppliances.FABatteredChicken") then			
			inv:Remove("FABatteredChicken")
			inv:AddItem("Base.ChickenFried")
		end
	elseif foodChoice == "Chicken Fillet" then	
		if inv:FindAndReturn("FunctionalAppliances.FABatteredChickenFillet") then			
			inv:Remove("FABatteredChickenFillet")
			inv:AddItem("FunctionalAppliances.FAFriedChickenFillet")
		end
	elseif foodChoice == "Chicken Tenders" then
		if inv:FindAndReturn("SapphCooking.SlicedChickenBatter") then			
			inv:Remove("SlicedChickenBatter")
			inv:AddItem("FunctionalAppliances.FAFriedChickenTenders")
		end
	elseif foodChoice == "Chicken Nuggets" then	
		if inv:FindAndReturn("SapphCooking.SmallBirdMeatinBatter") then			
			inv:Remove("SmallBirdMeatinBatter")
			inv:AddItem("Base.ChickenNuggets")
		end
	elseif foodChoice == "Doughboy" then			
		if inv:FindAndReturn("Base.BreadDough") then
			inv:Remove("BreadDough")
			inv:AddItem("FunctionalAppliances.FAFriedDoughboy")
		elseif inv:FindAndReturn("Base.Dough") then
			inv:Remove("Dough")
			inv:AddItem("FunctionalAppliances.FAFriedDoughboy")
		elseif inv:FindAndReturn("SapphCooking.SmallDough") then
			inv:Remove("SmallDough")
			inv:AddItem("FunctionalAppliances.FAFriedDoughboy")
		elseif inv:FindAndReturn("SapphCooking.PastryDough") then
			inv:Remove("PastryDough")
			inv:AddItem("FunctionalAppliances.FAFriedDoughboy")
		end
	elseif foodChoice == "Doughnut" then				
		if inv:FindAndReturn("SapphCooking.DoughnutShapedDough") then
			inv:Remove("DoughnutShapedDough")
			inv:AddItem("Base.DoughnutPlain")
		elseif inv:FindAndReturn("Base.Dough") then
			inv:Remove("Dough")
			inv:AddItem("Base.DoughnutPlain")
		elseif inv:FindAndReturn("SapphCooking.SmallDough") then
			inv:Remove("SmallDough")
			inv:AddItem("Base.DoughnutPlain")
		elseif inv:FindAndReturn("SapphCooking.PastryDough") then
			inv:Remove("PastryDough")
			inv:AddItem("Base.DoughnutPlain")
		end
	elseif foodChoice == "Churros" then				
		if inv:FindAndReturn("SapphCooking.PastryDough") then
			inv:Remove("PastryDough")
			inv:AddItem("SapphCooking.ChurrosPlain")
		elseif inv:FindAndReturn("Base.Dough") then
			inv:Remove("Dough")
			inv:AddItem("SapphCooking.ChurrosPlain")
		elseif inv:FindAndReturn("SapphCooking.SmallDough") then
			inv:Remove("SmallDough")
			inv:AddItem("SapphCooking.ChurrosPlain")
		end
	elseif foodChoice == "Cheese Sticks" then
		if inv:FindAndReturn("FunctionalAppliances.FABatteredCheese") then		
			inv:Remove("FABatteredCheese")
			inv:AddItem("FunctionalAppliances.FAFriedCheeseSticks")
		end
	end
	
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
	
	xp:AddXP(Perks.Cooking, baseXP)
end

function UseDeepFryers:waitToStart()
	self.character:faceThisObject(self.machine)
	return self.character:shouldBeTurning()
end

function UseDeepFryers:update()

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

function UseDeepFryers:start()
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Mid")
	self:setOverrideHandModels(nil, nil)
end

function UseDeepFryers:stop()

	if self.gameSound and
		self.gameSound ~= 0 and
		self.character:getEmitter():isPlaying(self.gameSound) then
		self.character:getEmitter():stopSound(self.gameSound)
	end

	local soundRadius = 15
	local volume = 6

	ISBaseTimedAction.stop(self)
end

function UseDeepFryers:perform()

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

	theEnd(self.character, self.machine, self.foodChoice)

	ISBaseTimedAction.perform(self)
end

function UseDeepFryers:new(character, machine, sound, food)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.machine = machine
	o.foodChoice = food
	o.soundFile = sound
	o.stopOnWalk = true
	o.stopOnRun = true
	o.gameSound = 0
	o.maxTime = 440
	return o
end