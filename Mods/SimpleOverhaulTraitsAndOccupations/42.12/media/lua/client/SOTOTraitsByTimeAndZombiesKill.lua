
local SOTOSbvars = SandboxVars.SOTO;

function SOTOtraitsByTimeAndZombiesKilled()
	
	local player = getPlayer();
	local playerHoursSurvived = player:getHoursSurvived();
	local playerZombiesKilled = player:getZombieKills();

	if player:getModData().CowardlyRemoved == nil then
	player:getModData().CowardlyRemoved = 0;
	end	
	if player:getModData().BraveRecieved == nil then
	player:getModData().BraveRecieved = 0;
	end
	if player:getModData().DesensitizedRecieved == nil then
	player:getModData().DesensitizedRecieved = 0;
	end		

	if player:getModData().BraveBonus == nil then
	player:getModData().BraveBonus = 0;
	end		
	if player:getModData().CowardlyPenalty == nil then
	player:getModData().CowardlyPenalty = 0;
	end

	-- Remove Cowardly Trait by time and kills
	if player:HasTrait("Cowardly") and not player:HasTrait("Brave") and not player:HasTrait("Desensitized") and not player:isAsleep() then
		-- Cowardly Hours Data
		local CowardlyHoursToRemoveMin = SOTOSbvars.CowardlyHoursToRemoveMin;
		local CowardlyHoursToRemoveMax = SOTOSbvars.CowardlyHoursToRemoveMax;
		local CowardlyHoursToRemoveDiff = CowardlyHoursToRemoveMax - CowardlyHoursToRemoveMin;
		local CowardlyHoursToRemove = CowardlyHoursToRemoveMin + ZombRand(CowardlyHoursToRemoveDiff); -- 7-14 days
		-- Cowardly ZombiesKilled Data
		local CowardlyZombiesKilledToRemoveMin = SOTOSbvars.CowardlyZombiesKilledToRemoveMin;
		local CowardlyZombiesKilledToRemoveMax = SOTOSbvars.CowardlyZombiesKilledToRemoveMax;
		local CowardlyZombiesKilledToRemoveDiff = CowardlyZombiesKilledToRemoveMax - CowardlyZombiesKilledToRemoveMin;
		local CowardlyZombiesKilledToRemove = CowardlyZombiesKilledToRemoveMin + ZombRand(CowardlyZombiesKilledToRemoveDiff); -- default 1000-2000	

		if playerHoursSurvived >= CowardlyHoursToRemove then
			if playerZombiesKilled >= CowardlyZombiesKilledToRemove then
				if SOTOSbvars.CowardlyRemovable == true then
					if player:getModData().CowardlyRemoved == 0 then 
						player:getModData().CowardlyRemoved = 1;
						player:getTraits():remove("Cowardly");
						getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_cowardly"), false, HaloTextHelper.getColorGreen());
					end		
				end
			end
		end
	-- print("CowardlyHoursToRemove = " .. CowardlyHoursToRemove);
	-- print("CowardlyZombiesKilledToRemove = " .. CowardlyZombiesKilledToRemove);
	end

	-- Adding Brave Trait by time and kills 
	if not player:HasTrait("Cowardly") and not player:HasTrait("Brave") and not player:HasTrait("Desensitized") and not player:isAsleep() then
		-- Brave Hours Data
		local BraveHoursToEarnMin = SOTOSbvars.BraveHoursToEarnMin;
		local BraveHoursToEarnMax = SOTOSbvars.BraveHoursToEarnMax;
		local BraveHoursToEarnDiff = BraveHoursToEarnMax - BraveHoursToEarnMin;
		local BraveHoursToEarn = BraveHoursToEarnMin + ZombRand(BraveHoursToEarnDiff);
		-- Brave ZombiesKilled Data
		local BraveZombiesKilledToEarnMin = SOTOSbvars.BraveZombiesKilledToEarnMin;
		local BraveZombiesKilledToEarnMax = SOTOSbvars.BraveZombiesKilledToEarnMax;
		local BraveZombiesKilledToEarnDiff = BraveZombiesKilledToEarnMax - BraveZombiesKilledToEarnMin;
		local BraveZombiesKilledToEarn = BraveZombiesKilledToEarnMin + ZombRand(BraveZombiesKilledToEarnDiff);

		if player:getModData().CowardlyPenalty == 1 then
		BraveHoursToEarn = (BraveHoursToEarnMin * 1.2) + ZombRand((BraveHoursToEarnDiff * 1.2)); -- 21-35 days
		BraveZombiesKilledToEarn = (BraveZombiesKilledToEarnMin * 1.2) + ZombRand((BraveZombiesKilledToEarnDiff * 1.2)); -- 3000-4500
		else
		BraveHoursToEarn = BraveHoursToEarnMin + ZombRand(BraveHoursToEarnDiff); -- 14-28 days
		BraveZombiesKilledToEarn = BraveZombiesKilledToEarnMin + ZombRand(BraveZombiesKilledToEarnDiff); -- 2500-3500
		end
		
		if playerHoursSurvived >= BraveHoursToEarn then
			if playerZombiesKilled >= BraveZombiesKilledToEarn then
				if SOTOSbvars.BraveEarnable == true then
					if player:getModData().BraveRecieved == 0 then 
						player:getTraits():add("Brave");
						player:getModData().BraveRecieved = 1;		
						getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_brave"), true, HaloTextHelper.getColorGreen());
					end
				end
			end
		end
	-- print("BraveHoursToEarn = " .. BraveHoursToEarn);
	-- print("BraveZombiesKilledToEarn = " .. BraveZombiesKilledToEarn);	
	end	

	-- Adding Desensitized Trait by time and kills 
	if player:HasTrait("Brave") and not player:HasTrait("Desensitized") and not player:isAsleep() then
		-- Desensitized Hours Data
		local DesensitizedHoursToEarnMin = SOTOSbvars.DesensitizedHoursToEarnMin;
		local DesensitizedHoursToEarnMax = SOTOSbvars.DesensitizedHoursToEarnMax;
		local DesensitizedHoursToEarnDiff = DesensitizedHoursToEarnMax - DesensitizedHoursToEarnMin;
		local DesensitizedHoursToEarn = DesensitizedHoursToEarnMin + ZombRand(DesensitizedHoursToEarnDiff);
		-- Desensitized ZombiesKilled Data
		local DesensitizedZombiesKilledToEarnMin = SOTOSbvars.DesensitizedZombiesKilledToEarnMin;
		local DesensitizedZombiesKilledToEarnMax = SOTOSbvars.DesensitizedZombiesKilledToEarnMax;
		local DesensitizedZombiesKilledToEarnDiff = DesensitizedZombiesKilledToEarnMax - DesensitizedZombiesKilledToEarnMin;
		local DesensitizedZombiesKilledToEarn = DesensitizedHoursToEarnMin + ZombRand(DesensitizedZombiesKilledToEarnDiff);
		
		if player:getModData().CowardlyPenalty == 1 then	
		DesensitizedHoursToEarn = (DesensitizedHoursToEarnMin * 1.2) + ZombRand((DesensitizedHoursToEarnDiff * 1.2)); -- 49-77 days
		DesensitizedZombiesKilledToEarn = (DesensitizedZombiesKilledToEarnMin * 1.2) + ZombRand((DesensitizedZombiesKilledToEarnDiff * 1.2)); -- 6000-9000
		elseif player:getModData().BraveBonus == 1 then
		DesensitizedHoursToEarn = (DesensitizedHoursToEarnMin * 0.8) + ZombRand((DesensitizedHoursToEarnDiff * 0.8)); -- 35-63 days
		DesensitizedZombiesKilledToEarn = (DesensitizedZombiesKilledToEarnMin * 0.8) + ZombRand((DesensitizedZombiesKilledToEarnDiff * 0.8)); -- 5000-8000
		else
		DesensitizedHoursToEarn = DesensitizedHoursToEarnMin + ZombRand(DesensitizedHoursToEarnDiff); -- 42-70 days
		DesensitizedZombiesKilledToEarn = DesensitizedZombiesKilledToEarnMin + ZombRand(DesensitizedZombiesKilledToEarnDiff); -- 5500-8500	
		end	

		if playerHoursSurvived >= DesensitizedHoursToEarn then
			if playerZombiesKilled >= DesensitizedZombiesKilledToEarn then
				if SOTOSbvars.DesensitizedEarnable == true then
					if player:HasTrait("FearoftheDark") then
						player:getTraits():remove("FearoftheDark")
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_fearofthedark"), false, HaloTextHelper.getColorGreen());			
					end	
					if player:HasTrait("Hemophobic") then
						player:getTraits():remove("Hemophobic")
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hemophobic"), false, HaloTextHelper.getColorGreen());			
					end			
					if player:getModData().DesensitizedRecieved == 0 then 
						player:getModData().DesensitizedRecieved = 1;	
						player:getTraits():remove("Brave")
						player:getTraits():add("Desensitized"); 
						getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Desensitized"), true, HaloTextHelper.getColorGreen());
					end	
				end
			end
		end
	-- print("DesensitizedHoursToEarn = " .. DesensitizedHoursToEarn);
	-- print("DesensitizedZombiesKilledToEarn = " .. DesensitizedZombiesKilledToEarn);			
	end	

	-- Removing Pafist
	if player:HasTrait("Pacifist") and not player:isAsleep() then
		-- Pacifist Hours Data
		local PacifistHoursToRemoveMin = SOTOSbvars.PacifistHoursToRemoveMin;
		local PacifistHoursToRemoveMax = SOTOSbvars.PacifistHoursToRemoveMax;
		local PacifistHoursToRemoveDiff = PacifistHoursToRemoveMax - PacifistHoursToRemoveMin;
		local PacifistHoursToRemove = PacifistHoursToRemoveMin + ZombRand(PacifistHoursToRemoveDiff); -- 28-42 days
		-- Pacifist ZombiesKilled Data
		local PacifistZombiesKilledToRemoveMin = SOTOSbvars.PacifistZombiesKilledToRemoveMin;
		local PacifistZombiesKilledToRemoveMax = SOTOSbvars.PacifistZombiesKilledToRemoveMax;
		local PacifistZombiesKilledToRemoveDiff = PacifistZombiesKilledToRemoveMax - PacifistZombiesKilledToRemoveMin;
		local PacifistZombiesKilledToRemove = PacifistHoursToRemoveMin + ZombRand(PacifistZombiesKilledToRemoveDiff);	-- 1500-2500
		
		if playerHoursSurvived >= PacifistHoursToRemove then
			if playerZombiesKilled >= PacifistZombiesKilledToRemove then
				if SOTOSbvars.PacifistRemovable == true then
					if player:getPerkLevel(Perks.Axe) >= SOTOSbvars.PacifistSkillLvlToRemove
					or player:getPerkLevel(Perks.SmallBlunt) >= SOTOSbvars.PacifistSkillLvlToRemove
					or player:getPerkLevel(Perks.Blunt) >= SOTOSbvars.PacifistSkillLvlToRemove
					or player:getPerkLevel(Perks.SmallBlade) >= SOTOSbvars.PacifistSkillLvlToRemove
					or player:getPerkLevel(Perks.LongBlade) >= SOTOSbvars.PacifistSkillLvlToRemove
					or player:getPerkLevel(Perks.Spear) >= SOTOSbvars.PacifistSkillLvlToRemove
					or player:getPerkLevel(Perks.Aiming) >= SOTOSbvars.PacifistSkillLvlToRemove
					then
						player:getTraits():remove("Pacifist")			
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pacifist"), false, HaloTextHelper.getColorGreen());
					end
					end
				end
			end
	-- print("PacifistHoursToRemove:" .. PacifistHoursToRemove);
	-- print("PacifistZombiesKilledToRemove:" .. PacifistZombiesKilledToRemove);		
	-- print("BraveBonus: " .. player:getModData().BraveBonus);	
	-- print("CowardlyPenalty: " .. player:getModData().CowardlyPenalty);		
	end
	
end

Events.EveryHours.Add(SOTOtraitsByTimeAndZombiesKilled);



	