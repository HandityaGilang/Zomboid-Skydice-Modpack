require "TimedActions/ISBaseTimedAction"

UseDeepFryers = ISBaseTimedAction:derive("UseDeepFryers")

function UseDeepFryers:isValid()
	return true
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

	ISBaseTimedAction.perform(self)
end

function UseDeepFryers:complete()
	local inv = self.character:getInventory()
	local CutPeeledPotato = inv:FindAndReturn("SapphCooking.CutPeeledPotato")
	local FAPotatoWedges = inv:FindAndReturn("FunctionalAppliances.FAPotatoWedges") 
	local PotatoPeel = inv:FindAndReturn("SapphCooking.PotatoPeel") 
	local FAPotatoSkins = inv:FindAndReturn("FunctionalAppliances.FAPotatoSkins") 
	local FriedOnionRingsCraft = inv:FindAndReturn("Base.FriedOnionRingsCraft") 
	local FABatteredBloomingOnion = inv:FindAndReturn("FunctionalAppliances.FABatteredBloomingOnion") 
	local CutTortilla = inv:FindAndReturn("SapphCooking.CutTortilla") 
	local ShrimpFriedCraft = inv:FindAndReturn("Base.ShrimpFriedCraft") 
	local FishFilletinBatter = inv:FindAndReturn("SapphCooking.FishFilletinBatter") 
	local SausageinBatter = inv:FindAndReturn("SapphCooking.SausageinBatter") 
	local FABatteredChicken = inv:FindAndReturn("FunctionalAppliances.FABatteredChicken") 
	local FABatteredChickenFillet = inv:FindAndReturn("FunctionalAppliances.FABatteredChickenFillet") 
	local SlicedChickenBatter = inv:FindAndReturn("SapphCooking.SlicedChickenBatter") 
	local SmallBirdMeatinBatter = inv:FindAndReturn("SapphCooking.SmallBirdMeatinBatter") 
	local BreadDough = inv:FindAndReturn("Base.BreadDough") 
	local Dough = inv:FindAndReturn("Base.Dough") 
	local SmallDough = inv:FindAndReturn("SapphCooking.SmallDough") 
	local PastryDough = inv:FindAndReturn("SapphCooking.PastryDough") 
	local DoughnutShapedDough = inv:FindAndReturn("SapphCooking.DoughnutShapedDough") 
	local FABatteredCheese = inv:FindAndReturn("FunctionalAppliances.FABatteredCheese") 

	if foodChoice == "French Fries" then
		if CutPeeledPotato then
			inv:Remove(CutPeeledPotato)
			sendRemoveItemFromContainer(inv, CutPeeledPotato)
			local addItem1 = instanceItem("Base.Fries")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif FAPotatoWedges then
			inv:Remove(FAPotatoWedges)
			sendRemoveItemFromContainer(inv, FAPotatoWedges)
			local addItem1 = instanceItem("Base.Fries")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Potato Skins" then
		if PotatoPeel then
			inv:Remove(PotatoPeel)
			sendRemoveItemFromContainer(inv, PotatoPeel)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedPotatoSkins")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif FAPotatoSkins then
			inv:Remove(FAPotatoSkins)
			sendRemoveItemFromContainer(inv, FAPotatoSkins)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedPotatoSkins")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Onion Rings" then
		if FriedOnionRingsCraft then
			inv:Remove(FriedOnionRingsCraft)
			sendRemoveItemFromContainer(inv, FriedOnionRingsCraft)
			local addItem1 = instanceItem("Base.FriedOnionRings")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Blooming Onion" then
		if FABatteredBloomingOnion then
			inv:Remove(FABatteredBloomingOnion)
			sendRemoveItemFromContainer(inv, FABatteredBloomingOnion)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedBloomingOnion")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Tortillas" then
		if CutTortilla then
			inv:Remove(CutTortilla)
			sendRemoveItemFromContainer(inv, CutTortilla)
			local addItem1 = instanceItem("SapphCooking.SapphTortillaChips")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Shrimp" then
		if ShrimpFriedCraft then
			inv:Remove(ShrimpFriedCraft)
			sendRemoveItemFromContainer(inv, ShrimpFriedCraft)
			local addItem1 = instanceItem("Base.ShrimpFried")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Fish Fillet" then
		if FishFilletinBatter then
			inv:Remove(FishFilletinBatter)
			sendRemoveItemFromContainer(inv, FishFilletinBatter)
			local addItem1 = instanceItem("SapphCooking.SapphFishFried")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Corndog" then
		if SausageinBatter then
			inv:Remove(SausageinBatter)
			sendRemoveItemFromContainer(inv, SausageinBatter)
			local addItem1 = instanceItem("SapphCooking.SapphCorndog")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Fried Chicken" then
		if FABatteredChicken then	
			inv:Remove(FABatteredChicken)
			sendRemoveItemFromContainer(inv, FABatteredChicken)
			local addItem1 = instanceItem("Base.ChickenFried")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Chicken Fillet" then	
		if FABatteredChickenFillet then	
			inv:Remove(FABatteredChickenFillet)
			sendRemoveItemFromContainer(inv, FABatteredChickenFillet)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedChickenFillet")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Chicken Tenders" then
		if SlicedChickenBatter then
			inv:Remove(SlicedChickenBatter)
			sendRemoveItemFromContainer(inv, SlicedChickenBatter)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedChickenTenders")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Chicken Nuggets" then	
		if SmallBirdMeatinBatter then	
			inv:Remove(SmallBirdMeatinBatter)
			sendRemoveItemFromContainer(inv, SmallBirdMeatinBatter)
			local addItem1 = instanceItem("Base.ChickenNuggets")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Doughboy" then			
		if BreadDough then
			inv:Remove(BreadDough)
			sendRemoveItemFromContainer(inv, BreadDough)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedDoughboy")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif Dough then
			inv:Remove(Dough)
			sendRemoveItemFromContainer(inv, Dough)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedDoughboy")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif SmallDough then
			inv:Remove(SmallDough)
			sendRemoveItemFromContainer(inv, SmallDough)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedDoughboy")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif PastryDough then
			inv:Remove(PastryDough)
			sendRemoveItemFromContainer(inv, PastryDough)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedDoughboy")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Doughnut" then				
		if DoughnutShapedDough then
			inv:Remove(DoughnutShapedDough)
			sendRemoveItemFromContainer(inv, DoughnutShapedDough)
			local addItem1 = instanceItem("Base.DoughnutPlain")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif Dough then
			inv:Remove(Dough)
			sendRemoveItemFromContainer(inv, Dough)
			local addItem1 = instanceItem("Base.DoughnutPlain")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif SmallDough then
			inv:Remove(SmallDough)
			sendRemoveItemFromContainer(inv, SmallDough)
			local addItem1 = instanceItem("Base.DoughnutPlain")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif PastryDough then
			inv:Remove(PastryDough)
			sendRemoveItemFromContainer(inv, PastryDough)
			local addItem1 = instanceItem("Base.DoughnutPlain")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Churros" then				
		if PastryDough then
			inv:Remove(PastryDough)
			sendRemoveItemFromContainer(inv, PastryDough)
			local addItem1 = instanceItem("SapphCooking.ChurrosPlain")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif Dough then
			inv:Remove(Dough)
			sendRemoveItemFromContainer(inv, Dough)
			local addItem1 = instanceItem("SapphCooking.ChurrosPlain")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		elseif SmallDough then
			inv:Remove(SmallDough)
			sendRemoveItemFromContainer(inv, SmallDough)
			local addItem1 = instanceItem("SapphCooking.ChurrosPlain")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	elseif foodChoice == "Cheese Sticks" then
		if FABatteredCheese then
			inv:Remove(FABatteredCheese)
			sendRemoveItemFromContainer(inv, FABatteredCheese)
			local addItem1 = instanceItem("FunctionalAppliances.FAFriedCheeseSticks")
			inv:AddItem(addItem1)
			sendAddItemToContainer(inv, addItem1)
		end
	end

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

function UseDeepFryers:new(character, machine, soundFile, foodChoice)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.machine = machine
	o.foodChoice = foodChoice
	o.soundFile = soundFile
	o.stopOnWalk = true
	o.stopOnRun = true
	o.gameSound = 0
	o.maxTime = 440
	return o
end