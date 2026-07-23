
local SOTOSbvars = SandboxVars.SOTO;

function SOTraitsByTimeAndZombieKilled()
	
	local player = getPlayer();
	local playersurvivedhours = player:getHoursSurvived();
	local killedzombies = player:getZombieKills();

	if player:getModData().SOCowardlyRemoved == nil then
	player:getModData().SOCowardlyRemoved = 0;
	end

	if player:getModData().SOBraveRecieved == nil then
	player:getModData().SOBraveRecieved = 0;
	end

	if player:getModData().SODesensitizedRecieved == nil then
	player:getModData().SODesensitizedRecieved = 0;
	end		

	if player:getModData().SOBraveBonus == nil then
	player:getModData().SOBraveBonus = 0;
	end		
	if player:getModData().SOCowardlyPenalty == nil then
	player:getModData().SOCowardlyPenalty = 0;
	end		

	-- Remove Cowardly Trait by time and kills
	if player:HasTrait("Cowardly") and not player:HasTrait("Brave") and not player:HasTrait("Desensitized") and not player:isAsleep() then

	hourscowardtonormalmin = SOTOSbvars.LoseCowardlyHoursMIN;
	hourscowardtonormalmax = SOTOSbvars.LoseCowardlyHoursMAX;
	hourscowardtonormaldiff = hourscowardtonormalmax - hourscowardtonormalmin;

	hourscowardtonormal = hourscowardtonormalmin + ZombRand(hourscowardtonormaldiff); -- 7-14 days

	killedzombiestonormalmin = SOTOSbvars.LoseCowardlyZombMIN;
	killedzombiestonormalmax = SOTOSbvars.LoseCowardlyZombMAX;
	killedzombiestonormaldiff = killedzombiestonormalmax - killedzombiestonormalmin
	
	killedzombiestonormal = killedzombiestonormalmin + ZombRand(killedzombiestonormaldiff); -- default 1000-2000	

	if playersurvivedhours >= hourscowardtonormal then
	if killedzombies >= killedzombiestonormal then
		if player:getModData().SOCowardlyRemoved == 0 then 
		player:getModData().SOCowardlyRemoved = 1;
		player:getTraits():remove("Cowardly");
		getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_cowardly"), false, HaloTextHelper.getColorGreen());
		end		
	end
	end
--	print("hourscowardtonormal = " .. hourscowardtonormal);
--	print("killedzombiestonormal = " .. killedzombiestonormal);
	end

	-- Adding Brave Trait by time and kills 
	if not player:HasTrait("Cowardly") and not player:HasTrait("Brave") and not player:HasTrait("Desensitized") and not player:isAsleep() then

	hoursnormaltobravemin = SOTOSbvars.EarnBraveHoursMIN;
	hoursnormaltobravemax = SOTOSbvars.EarnBraveHoursMAX;
	hoursnormaltobravediff = hoursnormaltobravemax - hoursnormaltobravemin;

	killedzombiestobravemin = SOTOSbvars.EarnBraveZombMIN;
	killedzombiestobravemax = SOTOSbvars.EarnBraveZombMAX;
	killedzombiestobravediff = killedzombiestobravemax - killedzombiestobravemin;

	if player:getModData().SOCowardlyPenalty == 1 then
	hoursnormaltobrave = (hoursnormaltobravemin * 1.2) + ZombRand((hoursnormaltobravediff * 1.2)); -- 21-35 days
	killedzombiestobrave = (killedzombiestobravemin * 1.2) + ZombRand((killedzombiestobravediff * 1.2)); -- 3000-4500
	else
	hoursnormaltobrave = hoursnormaltobravemin + ZombRand(hoursnormaltobravediff); -- 14-28 days
	killedzombiestobrave = killedzombiestobravemin + ZombRand(killedzombiestobravediff); -- 2500-3500
	end
	
	if playersurvivedhours >= hoursnormaltobrave then
	if killedzombies >= killedzombiestobrave then
		if player:getModData().SOBraveRecieved == 0 then 
		player:getTraits():add("Brave");
		player:getModData().SOBraveRecieved = 1;		
		getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_brave"), true, HaloTextHelper.getColorGreen());
		end
	end
	end
--	print("hoursnormaltobrave = " .. hoursnormaltobrave);
--	print("killedzombiestobrave = " .. killedzombiestobrave);	
	end	

	-- Adding Desensitized Trait by time and kills 
	if player:HasTrait("Brave") and not player:HasTrait("Desensitized") and not player:isAsleep() then

	hoursbravetodesenmin = SOTOSbvars.EarnDesensitizedHoursMIN;
	hoursbravetodesenmax = SOTOSbvars.EarnDesensitizedHoursMAX;
	hoursbravetodesendiff = hoursbravetodesenmax - hoursbravetodesenmin;

	killedzombiestodesenmin = SOTOSbvars.EarnDesensitizedZombMIN;
	killedzombiestodesenmax = SOTOSbvars.EarnDesensitizedZombMAX;
	killedzombiestodesendiff = killedzombiestodesenmax - killedzombiestodesenmin;

	if player:getModData().SOCowardlyPenalty == 1 then	
	hoursbravetodesen = (hoursbravetodesenmin * 1.2) + ZombRand((hoursbravetodesendiff * 1.2)); -- 49-77 days
	killedzombiestodesen = (killedzombiestodesenmin * 1.2) + ZombRand((killedzombiestodesendiff * 1.2)); -- 6000-9000
	elseif player:getModData().SOBraveBonus == 1 then
	hoursbravetodesen = (hoursbravetodesenmin * 0.8) + ZombRand((hoursbravetodesendiff * 0.8)); -- 35-63 days
	killedzombiestodesen = (killedzombiestodesenmin * 0.8) + ZombRand((killedzombiestodesendiff * 0.8)); -- 5000-8000
	else
	hoursbravetodesen = hoursbravetodesenmin + ZombRand(hoursbravetodesendiff); -- 42-70 days
	killedzombiestodesen = killedzombiestodesenmin + ZombRand(killedzombiestodesendiff); -- 5500-8500	
	end	

	if playersurvivedhours >= hoursbravetodesen then
	if killedzombies >= killedzombiestodesen then
		if player:HasTrait("FearoftheDark") then
 			player:getTraits():remove("FearoftheDark")
 			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_fearofthedark"), false, HaloTextHelper.getColorGreen());			
 		end	
 		if player:HasTrait("Hemophobic") then
 			player:getTraits():remove("Hemophobic")
 			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hemophobic"), false, HaloTextHelper.getColorGreen());			
  		end			

		if player:getModData().SODesensitizedRecieved == 0 then 
		player:getModData().SODesensitizedRecieved = 1;	
		player:getTraits():remove("Brave")
		player:getTraits():add("Desensitized"); 
		getSoundManager():PlaySound("GainExperienceLevel", false, 0):setVolume(0.50);
		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Desensitized"), true, HaloTextHelper.getColorGreen());
		end	
	end
	end
--	print("hoursbravetodesen = " .. hoursbravetodesen);
--	print("killedzombiestodesen = " .. killedzombiestodesen);			
	end	

	-- Removing Pafist
	if player:HasTrait("Pacifist") and not player:isAsleep() then

--[[	if player:getModData().SOCowardlyPenalty == 1 then		
	hourspacif = 672 + ZombRand(336); -- 28-42 days
	killedzombiespacif = 2000 + ZombRand(1200); --2000-3200
	elseif player:getModData().SOBraveBonus == 1 then	
	hourspacif = 336 + ZombRand(336); -- 14-28 days
	killedzombiespacif = 1000 + ZombRand(1200); --1000-2200
	else	
	hourspacif = 504 + ZombRand(336); -- 21-35 days
	killedzombiespacif = 1500 + ZombRand(1200); --1500-2700
	end]]

	hourspacifmin = SOTOSbvars.LosePacifistHoursMIN;
	hourspacifmax = SOTOSbvars.LosePacifistHoursMAX;
	hourspacifdiff = hourspacifmax - hourspacifmin;
	
	killedzombiespacifmin = SOTOSbvars.LosePacifistZombMIN;
	killedzombiespacifmax = SOTOSbvars.LosePacifistZombMAX;
	killedzombiespacifdiff = killedzombiespacifmax - killedzombiespacifmin	
	
	hourspacif = hourspacifmin + ZombRand(hourspacifdiff); -- 28-42 days
	killedzombiespacif = killedzombiespacifmin + ZombRand(killedzombiespacifdiff);	-- 1500-2500

	if playersurvivedhours >= hourspacif then
	if killedzombies >= killedzombiespacif then
	
		if player:getPerkLevel(Perks.Axe) >= SOTOSbvars.LosePacifistSkillLvl
		or player:getPerkLevel(Perks.SmallBlunt) >= SOTOSbvars.LosePacifistSkillLvl
		or player:getPerkLevel(Perks.Blunt) >= SOTOSbvars.LosePacifistSkillLvl
		or player:getPerkLevel(Perks.SmallBlade) >= SOTOSbvars.LosePacifistSkillLvl
		or player:getPerkLevel(Perks.LongBlade) >= SOTOSbvars.LosePacifistSkillLvl
		or player:getPerkLevel(Perks.Spear) >= SOTOSbvars.LosePacifistSkillLvl
		or player:getPerkLevel(Perks.Aiming) >= SOTOSbvars.LosePacifistSkillLvl
		then
			player:getTraits():remove("Pacifist")			
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pacifist"), false, HaloTextHelper.getColorGreen());
		end
		end
		
	end
--	print("hourspacif:" .. hourspacif);
--	print("killedzombiespacif:" .. killedzombiespacif);			
	end
--	print("SOBraveBonus: " .. player:getModData().SOBraveBonus);	
--	print("SOCowardlyPenalty: " .. player:getModData().SOCowardlyPenalty);		
end

Events.EveryHours.Add(SOTraitsByTimeAndZombieKilled);



	