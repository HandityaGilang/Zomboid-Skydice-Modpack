function Recipe.OnCreate.LWGiveSnack(items, result, player)
	
	local snackChance = ZombRand(1,3);			
	if snackChance == 1 then			
		player:getInventory():AddItem("LWBetterElectronics_Items.Otternoses");
	elseif snackChance == 2 then
		player:getInventory():AddItem("LWBetterElectronics_Items.YeenBeans");
	end
end	

function Recipe.OnCreate.LWSortElectricalScraps(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
	if ElecChance <= 50 then			
		player:getInventory():AddItem("Radio.ElectricWire");
	elseif ElecChance <= 60 then
		player:getInventory():AddItem("Base.Lightbulb");
	elseif ElecChance <= 70 then
		player:getInventory():AddItem("Radio.RadioReceiver");
    elseif ElecChance <= 80 then
		player:getInventory():AddItem("Radio.RadioTransmitter");		
    elseif ElecChance <= 90 then
		player:getInventory():AddItem("Base.Amplifier");			
    elseif ElecChance <= 100 then
		player:getInventory():AddItem("Base.Aluminum");				
	end
end	

function Recipe.OnCreate.LWDismantleRadio(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			player:getInventory():AddItem("Radio.ElectricWire");
		end
		if ElecChance <= 10 then
			player:getInventory():AddItem("Base.Lightbulb");
		end
		if ElecChance <= 10 then
			player:getInventory():AddItem("Radio.RadioReceiver");
		end
		if ElecChance >= 10 then
			player:getInventory():AddItem("Base.ElectronicsScrap");		
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.Amplifier");	
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.Aluminum");			
		end

end	

function Recipe.OnCreate.LWDismantleNoiseMakerV1(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			player:getInventory():AddItem("Radio.ElectricWire");
		end
		if ElecChance >= 10 then
			player:getInventory():AddItem("Base.Speaker");
		end
		if ElecChance >= 10 then
			player:getInventory():AddItem("Base.ElectronicsScrap");		
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.ElectronicsScrap");	
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.WristWatch_Right_DigitalRed");			
		end

end	

function Recipe.OnCreate.LWDismantleNoiseMakerV2(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			player:getInventory():AddItem("Radio.ElectricWire");
		end
		if ElecChance >= 10 then
			player:getInventory():AddItem("Base.Speaker");
		end
		if ElecChance >= 10 then
			player:getInventory():AddItem("Base.ElectronicsScrap");		
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.Speaker");	
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.WristWatch_Right_DigitalRed");			
		end

end	

function Recipe.OnCreate.LWDismantleNoiseMakerV3(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			player:getInventory():AddItem("Radio.ElectricWire");
		end
		if ElecChance >= 10 then
			player:getInventory():AddItem("Base.Speaker");
		end
		if ElecChance >= 10 then
			player:getInventory():AddItem("Base.HomeAlarm");		
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.Speaker");	
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.WristWatch_Right_DigitalRed");			
		end

end	

function Recipe.OnCreate.LWDismantleRemote(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 80 then			
			player:getInventory():AddItem("Radio.ElectricWire");
		end
		if ElecChance >= 10 then
			player:getInventory():AddItem("Base.Speaker");
		end
		if ElecChance >= 10 then
			player:getInventory():AddItem("Base.HomeAlarm");		
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.Speaker");	
		end
		if ElecChance >= 80 then
			player:getInventory():AddItem("Base.WristWatch_Right_DigitalRed");			
		end

end	

function Recipe.OnCreate.LWGiveMotionSensor(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			player:getInventory():AddItem("Base.MotionSensor");
		end

		if ElecChance >= 91 then
			player:getInventory():AddItem("Radio.ElectronicsScrap");			
		end

end	

function Recipe.OnCreate.LWGiveTimer(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			player:getInventory():AddItem("Base.TimerCrafted");
		end

		if ElecChance >= 91 then
			player:getInventory():AddItem("Radio.ElectronicsScrap");			
		end

end	

function Recipe.OnCreate.LWGiveAmplifier(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			player:getInventory():AddItem("Base.Amplifier");
		end

		if ElecChance >= 91 then
			player:getInventory():AddItem("Radio.ElectronicsScrap");			
		end

end	

function Recipe.OnCreate.LWGiveCraftedTrigger(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			player:getInventory():AddItem("Base.TriggerCrafted");
		end

		if ElecChance >= 91 then
			player:getInventory():AddItem("Radio.ElectronicsScrap");			
		end

end	

function Recipe.OnCreate.LWGiveRemoteReceiver(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			player:getInventory():AddItem("Radio.RadioReceiver");
		end

		if ElecChance >= 91 then
			player:getInventory():AddItem("Radio.ElectronicsScrap");			
		end

end	

function Recipe.OnCreate.LWDismantleRemote(items, result, player)
	
	local ElecChance = ZombRand(1,100);			
		if ElecChance <= 90 then			
			player:getInventory():AddItem("Base.Remote");
		end

		if ElecChance >= 91 then
			player:getInventory():AddItem("Base.ElectronicsScrap");			
		end

end	


function Recipe.OnCreate.RepairCarBattery(items, result, player, selectedItem)
	    
	local condition = player:getPerkLevel(Perks.Electricity) * 8
		
    result:setCondition(condition)
    
end

function Recipe.OnCreate.RebuildCarBattery(items, result, player, selectedItem)
	    
	local condition = player:getPerkLevel(Perks.Electricity) * 10
		
    result:setCondition(condition)
    
end

function Recipe.OnGiveXP.RepairCarBatteryXP(recipe, ingredients, result, player)
    player:getXp():AddXP(Perks.Electricity, player:getPerkLevel(Perks.Electricity)*3);
end