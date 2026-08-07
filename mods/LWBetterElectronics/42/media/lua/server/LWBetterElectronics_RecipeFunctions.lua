function RecipeCodeOnCreate.LWGiveSnack(craftRecipeData, character)	
	local snackChance = ZombRand(1,3);			
	if snackChance == 1 then			
		character:getInventory():AddItem("LWBetterElectronics.Otternoses");
	elseif snackChance == 2 then
		character:getInventory():AddItem("LWBetterElectronics.YeenBeans");
	end
end	

function RecipeCodeOnCreate.SortElectricalScraps(craftRecipeData, character)
	local ElecChance = ZombRand(1,100);			
	if ElecChance <= 50 then			
		character:getInventory():AddItem("Base.ElectricWire");
	elseif ElecChance <= 60 then
		character:getInventory():AddItem("Base.Lightbulb");
	elseif ElecChance <= 70 then
		character:getInventory():AddItem("Base.RadioReceiver");
    elseif ElecChance <= 80 then
		character:getInventory():AddItem("Base.RadioTransmitter");		
    elseif ElecChance <= 90 then
		character:getInventory():AddItem("Base.Amplifier");			
    elseif ElecChance <= 100 then
		character:getInventory():AddItem("Base.Aluminum");				
	end
end	

function RecipeCodeOnCreate.LWDismantleRadio(craftRecipeData, character)
		local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			character:getInventory():AddItem("Base.ElectricWire");
		end
		if ElecChance <= 10 then
			character:getInventory():AddItem("Base.Lightbulb");
		end
		if ElecChance <= 10 then
			character:getInventory():AddItem("Base.RadioReceiver");
		end
		if ElecChance >= 10 then
			character:getInventory():AddItem("Base.ElectronicsScrap");		
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.Amplifier");	
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.Aluminum");			
		end

end	

function RecipeCodeOnCreate.LWDismantleNoiseMakerV1(craftRecipeData, character)
		local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			character:getInventory():AddItem("Base.ElectricWire");
		end
		if ElecChance >= 10 then
			character:getInventory():AddItem("Base.Speaker");
		end
		if ElecChance >= 10 then
			character:getInventory():AddItem("Base.ElectronicsScrap");		
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.ElectronicsScrap");	
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.WristWatch_Right_DigitalRed");			
		end

end	

function RecipeCodeOnCreate.LWDismantleNoiseMakerV2(craftRecipeData, character)
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			character:getInventory():AddItem("Base.ElectricWire");
		end
		if ElecChance >= 10 then
			character:getInventory():AddItem("Base.Speaker");
		end
		if ElecChance >= 10 then
			character:getInventory():AddItem("Base.ElectronicsScrap");		
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.Speaker");	
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.WristWatch_Right_DigitalRed");			
		end

end	

function RecipeCodeOnCreate.LWDismantleNoiseMakerV3(craftRecipeData, character)
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			character:getInventory():AddItem("Base.ElectricWire");
		end
		if ElecChance >= 10 then
			character:getInventory():AddItem("Base.Speaker");
		end
		if ElecChance >= 10 then
			character:getInventory():AddItem("Base.HomeAlarm");		
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.Speaker");	
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.WristWatch_Right_DigitalRed");			
		end

end	

function RecipeCodeOnCreate.LWDismantleRemote(craftRecipeData, character)
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			character:getInventory():AddItem("Base.ElectricWire");
		end
		if ElecChance >= 10 then
			character:getInventory():AddItem("Base.Speaker");
		end
		if ElecChance >= 10 then
			character:getInventory():AddItem("Base.HomeAlarm");		
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.Speaker");	
		end
		if ElecChance >= 80 then
			character:getInventory():AddItem("Base.WristWatch_Right_DigitalRed");			
		end

end	

function RecipeCodeOnCreate.LWGiveMotionSensor(craftRecipeData, character)
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			character:getInventory():AddItem("Base.MotionSensor");
		end

		if ElecChance >= 91 then
			character:getInventory():AddItem("Base.ElectronicsScrap");			
		end

end	

function RecipeCodeOnCreate.LWGiveTimer(craftRecipeData, character)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			character:getInventory():AddItem("Base.TimerCrafted");
		end

		if ElecChance >= 91 then
			character:getInventory():AddItem("Base.ElectronicsScrap");			
		end

end	

function RecipeCodeOnCreate.LWGiveAmplifier(craftRecipeData, character)
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			character:getInventory():AddItem("Base.Amplifier");
		end

		if ElecChance >= 91 then
			character:getInventory():AddItem("Base.ElectronicsScrap");			
		end

end	

function RecipeCodeOnCreate.LWGiveCraftedTrigger(craftRecipeData, character)

	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			character:getInventory():AddItem("Base.TriggerCrafted");
		end

		if ElecChance >= 91 then
			character:getInventory():AddItem("Base.ElectronicsScrap");			
		end

end	

function RecipeCodeOnCreate.LWGiveRemoteReceiver(craftRecipeData, character)

	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			character:getInventory():AddItem("Base.RadioReceiver");
		end

		if ElecChance >= 91 then
			character:getInventory():AddItem("Base.ElectronicsScrap");			
		end

end	

function RecipeCodeOnCreate.LWDismantleRemote(craftRecipeData, character)

	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			character:getInventory():AddItem("Base.Remote");
		end

		if ElecChance >= 91 then
			character:getInventory():AddItem("Base.ElectronicsScrap");			
		end

end	


function RecipeCodeOnCreate.RepairCarBattery(craftRecipeData, character)

	local condition = character:getPerkLevel(Perks.Electricity) * 8
		
    result:setCondition(condition)
    
end

function RecipeCodeOnCreate.RebuildCarBattery(craftRecipeData, character)

	local condition = character:getPerkLevel(Perks.Electricity) * 10
		
    result:setCondition(condition)
    
end
