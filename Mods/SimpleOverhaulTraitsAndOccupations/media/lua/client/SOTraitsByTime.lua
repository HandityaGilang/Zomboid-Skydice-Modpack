
local SOTOSbvars = SandboxVars.SOTO;

-- REMOVE SUNDAYDRIVER
function SOsundaydriverremove()

	local player = getPlayer();
	
	if player:HasTrait("SundayDriver") then

	if player:HasTrait("FastLearner") then minutestoremovesr = 2520 + ZombRand(840);
	elseif player:HasTrait("SlowLearner") then minutestoremovesr = 4680 + ZombRand(1560);
	else minutestoremovesr = 3600 + ZombRand(1200);
	end

	if player:getModData().SOminutesWhileDriving == nil then
		player:getModData().SOminutesWhileDriving = 0;		
	end
		
	if player:isDriving() == true and not player:isAsleep() then
		local vehicle = player:getVehicle();	
		if vehicle:getCurrentSpeedKmHour() >= 10 then		
		player:getModData().SOminutesWhileDriving = player:getModData().SOminutesWhileDriving + 1;
--		print("wroom");		
		end
	end
	if player:getModData().SOminutesWhileDriving >= minutestoremovesr then
		player:getTraits():remove("SundayDriver");
		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SundayDriver"), false, HaloTextHelper.getColorGreen());
		getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
		player:getModData().SOminutesWhileDriving = 0;		
	end
	if player:getModData().SOminutesWhileDriving > 4800 then
	player:getModData().SOminutesWhileDriving = 4800;
		elseif player:getModData().SOminutesWhileDriving < 0 then
		player:getModData().SOminutesWhileDriving = 0;
		end	
--		print("minutestoremovesr =" .. minutestoremovesr);		
--		print("player:getModData().SOminutesWhileDriving =" .. player:getModData().SOminutesWhileDriving);	
	end
end

-- REMOVE SMOKER TRAIT
function SOquitsmoker()

 local player = getPlayer();
	
	if player:HasTrait("Smoker") then
	local HoursSinceLastSmoke = player:getTimeSinceLastSmoke();		
	local hoursmokertonormal = 672 + ZombRand(96); -- 28-32 days
		if player:getModData().SOhoursSinceLastSmoke == nil then
			player:getModData().SOhoursSinceLastSmoke = 0;
		end		
		if HoursSinceLastSmoke >= 10 then
			player:getModData().SOhoursSinceLastSmoke = player:getModData().SOhoursSinceLastSmoke + 1;
			else
				player:getModData().SOhoursSinceLastSmoke = player:getModData().SOhoursSinceLastSmoke - 3;
		end
		if player:getModData().SOhoursSinceLastSmoke > 768 then
			player:getModData().SOhoursSinceLastSmoke = 768;	
			elseif player:getModData().SOhoursSinceLastSmoke < 0 then
				player:getModData().SOhoursSinceLastSmoke = 0;
		end

		if player:getModData().SOhoursSinceLastSmoke >= hoursmokertonormal and player:HasTrait("Smoker") then
			player:setTimeSinceLastSmoke(0);
			player:getStats():setStressFromCigarettes(0);
			player:getTraits():remove("Smoker");
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Smoker"), false, HaloTextHelper.getColorGreen());
			getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);	
		end	
--	print("hourscowardtonormal = " .. hoursmokertonormal);
--	print("getTimeSinceLastSmoke = " .. player:getTimeSinceLastSmoke());	
--	print("SOhoursSinceLastSmoke = " .. player:getModData().SOhoursSinceLastSmoke);		
	end
end

function SOtransferitems(player)
	local player = getPlayer();
	local TAtoloseAllThumbs = 37500;
--	local TAtoloseDisorganized = 110000;
	local WAtoloseDisorganized = 37500;	

	if player:getModData().SOtransferamountAT == nil then
	player:getModData().SOtransferamountAT = 0;
	end	
--[[
	if player:getModData().SOtransferamountDO == nil then
 player:getModData().SOtransferamountDO = 0;
 end	]]	
	if player:getModData().SOweightamountDO == nil then
	player:getModData().SOweightamountDO = 0;
	end			
	
	if player:HasTrait("AllThumbs") and player:getModData().SOtransferamountAT >= TAtoloseAllThumbs then
		player:getTraits():remove("AllThumbs");
		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen());
		getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);			
	end
--[[	
	if player:HasTrait("Disorganized") and player:getModData().SOtransferamountDO >= TAtoloseDisorganized then
 player:getTraits():remove("Disorganized");
 HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Disorganized"), false, HaloTextHelper.getColorGreen());
		getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);		
	end]]
	
	if player:HasTrait("Disorganized") and player:getModData().SOweightamountDO >= WAtoloseDisorganized then
		player:getTraits():remove("Disorganized");
		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Disorganized"), false, HaloTextHelper.getColorGreen());
		getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);		
	end	
	
--	print("SOtransferamountAT = " .. player:getModData().SOtransferamountAT);
--	print("SOtransferamountDO = " .. player:getModData().SOtransferamountDO);	
--	print("SOweightamountDO = " .. player:getModData().SOweightamountDO);	
end

Events.EveryOneMinute.Add(SOtransferitems);
Events.EveryOneMinute.Add(SOsundaydriverremove);
Events.EveryHours.Add(SOquitsmoker);

-- TEST FUNCTION
--[[function SOearnoutdoorsman()	
	local player = getPlayer();
 local climateManager = getClimateManager();

	if player:getModData().SOOutdoorsmanEarn == nil then
 player:getModData().SOOutdoorsmanEarn = 0;
 end	

	if not player:HasTrait("Outdoorsman") then 	

		local currRainIntensity = climateManager:getRainIntensity();
		local rainmultiplier = currRainIntensity * 3;
		local timetogetoutdorsman = 8640 -- 6 is one hour / 144 is one day

		if player:isOutside() and player:getVehicle() == nil then
		print("currRainIntensity: " .. currRainIntensity);		
		print("rainmultiplier: " .. rainmultiplier);			
		print("player:getModData().SOOutdoorsmanEarn: " .. player:getModData().SOOutdoorsmanEarn);		

		player:getModData().SOOutdoorsmanEarn = player:getModData().SOOutdoorsmanEarn + (rainmultiplier + 1);

		print("player:getModData().SOOutdoorsmanEarn: " .. player:getModData().SOOutdoorsmanEarn);		
		end
		
		if player:getModData().SOOutdoorsmanEarn >= timetogetoutdorsman then
		player:getTraits():add("Outdoorsman");
		getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_outdoorsman"), true, HaloTextHelper.getColorGreen());
		end
	end
	
end]]

