
local SOTOSbvars = SandboxVars.SOTO;

function SOLvlTrait(player, perk, perkLevel, addBuffer)

	SOAddTraitsByLvl(player, perk, perkLevel);
	
 end
 
Events.LevelPerk.Add(SOLvlTrait);

function SOaddExpBoost(player, perk, boostLevel)

    local currentXPBoost = player:getXp():getPerkBoost(perk);
    local newBoost = currentXPBoost + boostLevel;
    if newBoost > 3 then
        player:getXp():setPerkBoost(perk, 3);
		else
        player:getXp():setPerkBoost(perk, newBoost);
    end
	
end

function SOAddTraitsByLvl(player, perk, perkLevel)

--	if not player:getXp():getPerkBoost(perk) >= 3 then

	-- STRENGTH	
	if perk == Perks.Strength then
		-- lose Slack if Strength and Fitness lvl 8+ 	
		if perkLevel >= 8 and player:getPerkLevel(Perks.Fitness) >= 8 and player:HasTrait("Slack") then
			player:getTraits():remove("Slack");	
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slack"), false, HaloTextHelper.getColorGreen());		
		end		
	end	
	
	-- FITNESS
	if perk == Perks.Fitness then
		-- lose Slack if Strength and Fitness lvl 8+ 	
		if perkLevel >= 8 and player:getPerkLevel(Perks.Strength) >= 8 and player:HasTrait("Slack") then
			player:getTraits():remove("Slack");	
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slack"), false, HaloTextHelper.getColorGreen());		
		end	
	end	
	
	-- MOVEMENT ---
	
	-- SNEAK
	if perk == Perks.Sneak then
		-- add Sneaky if Sneak lvl 4+ and no Conspicuous
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 4 and not player:HasTrait("Conspicuous") and not player:HasTrait("Sneaky") then
			player:getTraits():add("Sneaky");
			SOaddExpBoost(player, Perks.Sneak, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_sneaky"), true, HaloTextHelper.getColorGreen());
		end
		-- add Sneaky if Sneak lvl 5 and Conspicuous
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 5 and player:HasTrait("Conspicuous") and not player:HasTrait("Sneaky") then
			player:getTraits():add("Sneaky");
			SOaddExpBoost(player, Perks.Sneak, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_sneaky"), true, HaloTextHelper.getColorGreen());
		end
		-- add Inconspicuous if Sneak lvl 6 and not Conspicuous
		if SOTOSbvars.InconspicuousEarnable == true and perkLevel == 6 and not player:HasTrait("Conspicuous") and not player:HasTrait("Inconspicuous") then
			player:getTraits():add("Inconspicuous");
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Inconspicuous"), true, HaloTextHelper.getColorGreen());
		end
		-- lose Conspicuous if Sneak lvl 6	
		if SOTOSbvars.ConspicuousRemovable == true and perkLevel == 6 and player:HasTrait("Conspicuous") then
			player:getTraits():remove("Conspicuous");	
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Conspicuous"), false, HaloTextHelper.getColorGreen());	
		end
	end
	
	-- LIGHTFOOT	
	if perk == Perks.Lightfoot then
		-- add Lightfooted if Lightfoot lvl 4+ and no Clumsy
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 4 and not player:HasTrait("Lightfooted") and not player:HasTrait("Clumsy") then
			player:getTraits():add("Lightfooted");
			SOaddExpBoost(player, Perks.Lightfoot, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lightfooted"), true, HaloTextHelper.getColorGreen());
		end
		-- add Lightfooted if Lightfoot lvl 5+ and Clumsy
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 5 and not player:HasTrait("Lightfooted") and player:HasTrait("Clumsy") then
			player:getTraits():add("Lightfooted");
			SOaddExpBoost(player, Perks.Lightfoot, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lightfooted"), true, HaloTextHelper.getColorGreen());
		end		
		-- add Graceful if Lightfoot lvl 6 and not Clumsy
		if SOTOSbvars.GracefulEarnable == true and perkLevel == 6 and not player:HasTrait("Clumsy") and not player:HasTrait("Graceful") then
			player:getTraits():add("Graceful");
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graceful"), true, HaloTextHelper.getColorGreen());
		end			
		-- lose Clumsy if Lightfoot lvl 6
		if SOTOSbvars.ClumsyRemovable == true and perkLevel == 6 and player:HasTrait("Clumsy") then
			player:getTraits():remove("Clumsy");	
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_clumsy"), false, HaloTextHelper.getColorGreen());		

		end
	end	
	
	-- SPRINTING
	if perk == Perks.Sprinting then
		-- add Jogger if Sprinting lvl 5+
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 5 and not player:HasTrait("Jogger") then
			player:getTraits():add("Jogger");
			SOaddExpBoost(player, Perks.Sprinting, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Jogger"), true, HaloTextHelper.getColorGreen());
		end
	end

	-- NIMBLE	
	if perk == Perks.Nimble then
		-- add Agile if Nimble lvl 5+
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 5 and not player:HasTrait("Nimble") then
			player:getTraits():add("Nimble");
			SOaddExpBoost(player, Perks.Nimble, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_nimble"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- SURVIVALIST TRAITS

	-- FORAGING
	if perk == Perks.PlantScavenging then
		-- add Forager if Foraging lvl 6+
		if SOTOSbvars.SurvTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Forager") then
			player:getTraits():add("Forager");
			SOaddExpBoost(player, Perks.PlantScavenging, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_forager"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- FISHING
	if perk == Perks.Fishing then
		-- add Angler if Fishing lvl 6+
		if SOTOSbvars.SurvTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Fishing") then
			player:getTraits():add("Fishing");
			SOaddExpBoost(player, Perks.Fishing, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Fishing"), true, HaloTextHelper.getColorGreen());
		end
	end			

	-- TRAPPING
	if perk == Perks.Trapping then
		-- add Trapper if Trapping lvl 6+
		if SOTOSbvars.SurvTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Trapper") then
			player:getTraits():add("Trapper");
			SOaddExpBoost(player, Perks.Trapping, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_trapper"), true, HaloTextHelper.getColorGreen());
		end
	end

	-- TRACKING
	if perk == Perks.Tracking then
		-- add Tracker if Tracking lvl 6+
		if SOTOSbvars.SurvTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Tracker") then
			player:getTraits():add("Tracker");
			SOaddExpBoost(player, Perks.Tracking, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_tracker"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- CFRAFTING ---
	-- FIRST AID	
	if perk == Perks.Doctor then
		-- add First Aid if First Aid lvl 6+	
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("FirstAid") then
			player:getTraits():add("FirstAid");
			SOaddExpBoost(player, Perks.Doctor, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FirstAid"), true, HaloTextHelper.getColorGreen());
		end
	end		

	-- COOKING
	if perk == Perks.Cooking then
		-- add Culinary if Cooking lvl 6+	
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Culinary") then
			player:getTraits():add("Culinary");
			SOaddExpBoost(player, Perks.Cooking, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_culinary"), true, HaloTextHelper.getColorGreen());
		end
	end	
	
	-- FARMING	
	if perk == Perks.Farming then
		-- Gardener
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Gardener") then
			player:getTraits():add("Gardener");
			SOaddExpBoost(player, Perks.Farming, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gardener"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- CARPENTRY
	if perk == Perks.Woodwork then
		-- add Woodworker if Carpentry lvl 6+
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Woodworker") then
			player:getTraits():add("Woodworker");
			SOaddExpBoost(player, Perks.Woodwork, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_woodworker"), true, HaloTextHelper.getColorGreen());
		end
	end		

	-- ELECTRICITY
	if perk == Perks.Electricity then
		-- Add ElectricTech
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("ElectricTech") then
			player:getTraits():add("ElectricTech");
			SOaddExpBoost(player, Perks.Electricity, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_electrictech"), true, HaloTextHelper.getColorGreen());
		end
	end			
		
	-- MECHANICS
	if perk == Perks.Mechanics then
		-- add Mechanics trait if Mechanis 6+
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("AutoMechanic") then
			player:getTraits():add("AutoMechanic");
			SOaddExpBoost(player, Perks.Mechanics, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_automechanic"), true, HaloTextHelper.getColorGreen());
		end
		
	end		

	-- METALLWEILD
	if perk == Perks.MetalWelding then
	-- Add MetalWelder
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("MetalWelder") then
			player:getTraits():add("MetalWelder");
			SOaddExpBoost(player, Perks.MetalWelding, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_metalwelder"), true, HaloTextHelper.getColorGreen());
		end
	end			
	
	-- TAILORING
	if perk == Perks.Tailoring then
		-- Add Tailor
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Tailor") then
			player:getTraits():add("Tailor");
			SOaddExpBoost(player, Perks.Tailoring, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen());
		end
	end		

	-- CARVING
	if perk == Perks.Carving then
		-- Add Whittler
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Whittler") then
			player:getTraits():add("Whittler");
			SOaddExpBoost(player, Perks.Carving, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Whittler"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- MASONRY
	if perk == Perks.Masonry then
		-- Add Masonry
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Masonry") then
			player:getTraits():add("Masonry");
			SOaddExpBoost(player, Perks.Masonry, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_masonry"), true, HaloTextHelper.getColorGreen());
		end
	end			
	
	-- POTTERY
	if perk == Perks.Pottery then
		-- Add Potter
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Potter") then
			player:getTraits():add("Potter");
			SOaddExpBoost(player, Perks.Pottery, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_potter"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- GLASSMAKING
	if perk == Perks.Glassmaking then
		-- Add Masonry
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("GlassBlower") then
			player:getTraits():add("GlassBlower");
			SOaddExpBoost(player, Perks.Glassmaking, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_glassblower"), true, HaloTextHelper.getColorGreen());
		end
	end	
	
	-- BLACKSMITH
	if perk == Perks.Blacksmith then
		-- Add Blacksmith
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Blacksmith") then
			player:getTraits():add("Blacksmith");
			SOaddExpBoost(player, Perks.Blacksmith, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Blacksmith"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- FLINTKNAPPING
	if perk == Perks.FlintKnapping then
		-- Add KnappingBasics
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("KnappingBasics") then
			player:getTraits():add("KnappingBasics");
			SOaddExpBoost(player, Perks.FlintKnapping, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_knappingbasics"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- HUSBANDRY
	if perk == Perks.Husbandry then
		-- Add AnimalFriend
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("AnimalFriend") then
			player:getTraits():add("AnimalFriend");
			SOaddExpBoost(player, Perks.Husbandry, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_animalfriend"), true, HaloTextHelper.getColorGreen());
		end
	end		

	-- BUTCHERING
	if perk == Perks.Butchering then
		-- Add Slaughterer
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Slaughterer") then
			player:getTraits():add("Slaughterer");
			SOaddExpBoost(player, Perks.Butchering, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slaughterer"), true, HaloTextHelper.getColorGreen());
		end
	end

	-- Melting
--	if perk == Perks.Melting then
		-- Add Smelter
--		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Smelter") then
--			player:getTraits():add("Smelter");
--			SOaddExpBoost(player, Perks.Melting, 1);
--			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_smelter"), true, HaloTextHelper.getColorGreen());
--		end
--	end		
	
	-- COMBAT TRAITS	
	
	-- MAINTENANCE
	if perk == Perks.Maintenance then
		-- Add Durability if maintenance 6+
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Durab") then
			player:getTraits():add("Durab");
			SOaddExpBoost(player, Perks.Maintenance, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_durab"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- SMALL BLADE
	if perk == Perks.SmallBlade then
		-- add Stabber if Short Blade 6+		
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Stabber") then
			player:getTraits():add("Stabber");
			SOaddExpBoost(player, Perks.SmallBlade, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_stabber"), true, HaloTextHelper.getColorGreen());
		end
	end			
	
	-- SMALL BLUNT
	if perk == Perks.SmallBlunt then
		-- add Smasher if Short Blunt 6+	
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Smasher") then
			player:getTraits():add("Smasher");
			SOaddExpBoost(player, Perks.SmallBlunt, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_smasher"), true, HaloTextHelper.getColorGreen());
		end
	end				
	
	-- AXE
	if perk == Perks.Axe then
		-- add Cutter if Axe 6+	
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Cutter") then
			player:getTraits():add("Cutter");
			SOaddExpBoost(player, Perks.Axe, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_cutter"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- SPEAR
	if perk == Perks.Spear then
		-- add Spearman if Spears 6+	
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Spearman") then
			player:getTraits():add("Spearman");
			SOaddExpBoost(player, Perks.Spear, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_spearman"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- LONG BLADE
	if perk == Perks.LongBlade then
		-- add Swordsman if Long Blade 6+	
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("Swordsman") then
			player:getTraits():add("Swordsman");
			SOaddExpBoost(player, Perks.LongBlade, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_swordsman"), true, HaloTextHelper.getColorGreen());
		end
	end			

	-- BLUNT
	if perk == Perks.Blunt then
		-- add BaseballPlayer if Long Blunt 6+
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:HasTrait("BaseballPlayer") then
			player:getTraits():add("BaseballPlayer");
			SOaddExpBoost(player, Perks.Blunt, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PlaysBaseball"), true, HaloTextHelper.getColorGreen());
		end
	end

	-- FIREARM TRAITS
	
	-- AIMING
	if perk == Perks.Aiming then

		-- add Sharpshooter if Aiming lvl 6+ 
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 6 and not player:HasTrait("ShortSighted") and not player:HasTrait("EagleEyed") and player:HasTrait("Shooter") and not player:HasTrait("ExpShooter")then
			player:getTraits():add("ExpShooter");
			player:getTraits():remove("Shooter");				
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_expshooter"), true, HaloTextHelper.getColorGreen());
		end
		-- add Sharpshooter if Aiming lvl 5+ if EagleEyed
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 5 and not player:HasTrait("ShortSighted") and player:HasTrait("EagleEyed") and player:HasTrait("Shooter") and not player:HasTrait("ExpShooter")then
			player:getTraits():add("ExpShooter");
			player:getTraits():remove("Shooter");		
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_expshooter"), true, HaloTextHelper.getColorGreen());
		end		
		-- add Sharpshooter if Aiming lvl 7+ if ShortSighted	
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 7 and player:HasTrait("ShortSighted") and not player:HasTrait("EagleEyed") and player:HasTrait("Shooter") and not player:HasTrait("ExpShooter")then
			player:getTraits():add("ExpShooter");
			player:getTraits():remove("Shooter");				
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_expshooter"), true, HaloTextHelper.getColorGreen());
		end
		
		-- add Shooter if Aiming lvl 6+ 
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 6 and not player:HasTrait("ShortSighted") and not player:HasTrait("EagleEyed") and not player:HasTrait("Shooter") and not player:HasTrait("ExpShooter")then
			player:getTraits():add("Shooter");
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_shooter"), true, HaloTextHelper.getColorGreen());
		end
		-- add Shooter if Aiming lvl 5+ if EagleEyed
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 5 and not player:HasTrait("ShortSighted") and player:HasTrait("EagleEyed") and not player:HasTrait("Shooter") and not player:HasTrait("ExpShooter")then
			player:getTraits():add("Shooter");
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_shooter"), true, HaloTextHelper.getColorGreen());
		end
		-- add Shooter if Aiming lvl 7+ if ShortSighted	
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 7 and player:HasTrait("ShortSighted") and not player:HasTrait("EagleEyed") and not player:HasTrait("Shooter") and not player:HasTrait("ExpShooter")then
			player:getTraits():add("Shooter");
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_shooter"), true, HaloTextHelper.getColorGreen());
		end
	end	
end
