
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
		if perkLevel >= 8 and player:getPerkLevel(Perks.Fitness) >= 8 and player:hasTrait(SOTO.CharacterTrait.SLACK) then
			player:getCharacterTraits():remove(SOTO.CharacterTrait.SLACK);	
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slack"), false, HaloTextHelper.getColorGreen());		
		end		
	end	
	
	-- FITNESS
	if perk == Perks.Fitness then
		-- lose Slack if Strength and Fitness lvl 8+ 	
		if perkLevel >= 8 and player:getPerkLevel(Perks.Strength) >= 8 and player:hasTrait(SOTO.CharacterTrait.SLACK) then
			player:getCharacterTraits():remove(SOTO.CharacterTrait.SLACK);	
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slack"), false, HaloTextHelper.getColorGreen());		
		end	
	end	
	
	-- MOVEMENT ---
	
	-- SNEAK
	if perk == Perks.Sneak then
		-- add Sneaky if Sneak lvl 4+ and no Conspicuous
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 4 and not player:hasTrait(CharacterTrait.CONSPICUOUS) and not player:hasTrait(SOTO.CharacterTrait.SNEAKY) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.SNEAKY);
			SOaddExpBoost(player, Perks.Sneak, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_sneaky"), true, HaloTextHelper.getColorGreen());
		end
		-- add Sneaky if Sneak lvl 5 and Conspicuous
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 5 and player:hasTrait(CharacterTrait.CONSPICUOUS) and not player:hasTrait(SOTO.CharacterTrait.SNEAKY) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.SNEAKY);
			SOaddExpBoost(player, Perks.Sneak, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_sneaky"), true, HaloTextHelper.getColorGreen());
		end
		-- add Inconspicuous if Sneak lvl 6 and not Conspicuous
		if SOTOSbvars.InconspicuousEarnable == true and perkLevel == 6 and not player:hasTrait(CharacterTrait.CONSPICUOUS) and not player:hasTrait(CharacterTrait.INCONSPICUOUS) then
			player:getCharacterTraits():add(CharacterTrait.INCONSPICUOUS);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Inconspicuous"), true, HaloTextHelper.getColorGreen());
		end
		-- lose Conspicuous if Sneak lvl 6	
		if SOTOSbvars.ConspicuousRemovable == true and perkLevel == 6 and player:hasTrait(CharacterTrait.CONSPICUOUS) then
			player:getCharacterTraits():remove(CharacterTrait.CONSPICUOUS);	
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Conspicuous"), false, HaloTextHelper.getColorGreen());	
		end
	end
	
	-- LIGHTFOOT	
	if perk == Perks.Lightfoot then
		-- add Lightfooted if Lightfoot lvl 4+ and no Clumsy
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 4 and not player:hasTrait(SOTO.CharacterTrait.LIGHTFOOTED) and not player:hasTrait(CharacterTrait.CLUMSY) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.LIGHTFOOTED);
			SOaddExpBoost(player, Perks.Lightfoot, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lightfooted"), true, HaloTextHelper.getColorGreen());
		end
		-- add Lightfooted if Lightfoot lvl 5+ and Clumsy
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 5 and not player:hasTrait(SOTO.CharacterTrait.LIGHTFOOTED) and player:hasTrait(CharacterTrait.CLUMSY) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.LIGHTFOOTED);
			SOaddExpBoost(player, Perks.Lightfoot, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lightfooted"), true, HaloTextHelper.getColorGreen());
		end		
		-- add Graceful if Lightfoot lvl 6 and not Clumsy
		if SOTOSbvars.GracefulEarnable == true and perkLevel == 6 and not player:hasTrait(CharacterTrait.CLUMSY) and not player:hasTrait(CharacterTrait.GRACEFUL) then
			player:getCharacterTraits():add(CharacterTrait.GRACEFUL);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graceful"), true, HaloTextHelper.getColorGreen());
		end			
		-- lose Clumsy if Lightfoot lvl 6
		if SOTOSbvars.ClumsyRemovable == true and perkLevel == 6 and player:hasTrait(CharacterTrait.CLUMSY) then
			player:getCharacterTraits():remove(CharacterTrait.CLUMSY);	
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_clumsy"), false, HaloTextHelper.getColorGreen());		

		end
	end	
	
	-- SPRINTING
	if perk == Perks.Sprinting then
		-- add Jogger if Sprinting lvl 5+
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 5 and not player:hasTrait(CharacterTrait.JOGGER) then
			player:getCharacterTraits():add(CharacterTrait.JOGGER);
			SOaddExpBoost(player, Perks.Sprinting, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Jogger"), true, HaloTextHelper.getColorGreen());
		end
	end

	-- NIMBLE	
	if perk == Perks.Nimble then
		-- add Agile if Nimble lvl 5+
		if SOTOSbvars.AgilityTraitsObtainable == true and perkLevel >= 5 and not player:hasTrait(SOTO.CharacterTrait.AGILE) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.AGILE);
			SOaddExpBoost(player, Perks.Nimble, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_agile"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- SURVIVALIST TRAITS

	-- FORAGING
	if perk == Perks.PlantScavenging then
		-- add Forager if Foraging lvl 6+
		if SOTOSbvars.SurvTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.FORAGER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.FORAGER);
			SOaddExpBoost(player, Perks.PlantScavenging, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_forager"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- FISHING
	if perk == Perks.Fishing then
		-- add Angler if Fishing lvl 6+
		if SOTOSbvars.SurvTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(CharacterTrait.FISHING) then
			player:getCharacterTraits():add(CharacterTrait.FISHING);
			SOaddExpBoost(player, Perks.Fishing, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Fishing"), true, HaloTextHelper.getColorGreen());
		end
	end			

	-- TRAPPING
	if perk == Perks.Trapping then
		-- add Trapper if Trapping lvl 6+
		if SOTOSbvars.SurvTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.TRAPPER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.TRAPPER);
			SOaddExpBoost(player, Perks.Trapping, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_trapper"), true, HaloTextHelper.getColorGreen());
		end
	end

	-- TRACKING
	if perk == Perks.Tracking then
		-- add Tracker if Tracking lvl 6+
		if SOTOSbvars.SurvTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.TRACKER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.TRACKER);
			SOaddExpBoost(player, Perks.Tracking, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_tracker"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- CFRAFTING ---
	-- FIRST AID	
	if perk == Perks.Doctor then
		-- add First Aid if First Aid lvl 6+	
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(CharacterTrait.FIRST_AID) then
			player:getCharacterTraits():add(CharacterTrait.FIRST_AID);
			SOaddExpBoost(player, Perks.Doctor, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FIRST_AID"), true, HaloTextHelper.getColorGreen());
		end
	end		

	-- COOKING
	if perk == Perks.Cooking then
		-- add Culinary if Cooking lvl 6+	
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.CULINARY) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.CULINARY);
			SOaddExpBoost(player, Perks.Cooking, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_culinary"), true, HaloTextHelper.getColorGreen());
		end
	end	
	
	-- FARMING	
	if perk == Perks.Farming then
		-- Gardener
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(CharacterTrait.GARDENER) then
			player:getCharacterTraits():add(CharacterTrait.GARDENER);
			SOaddExpBoost(player, Perks.Farming, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gardener"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- CARPENTRY
	if perk == Perks.Woodwork then
		-- add Woodworker if Carpentry lvl 6+
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.WOODWORKER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.WOODWORKER);
			SOaddExpBoost(player, Perks.Woodwork, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_woodworker"), true, HaloTextHelper.getColorGreen());
		end
	end		

	-- ELECTRICITY
	if perk == Perks.Electricity then
		-- Add ElectricTech
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.ELECTRICALMECHANIC) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.ELECTRICALMECHANIC);
			SOaddExpBoost(player, Perks.Electricity, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_electricalmechanic"), true, HaloTextHelper.getColorGreen());
		end
	end			
		
	-- MECHANICS
	if perk == Perks.Mechanics then
		-- add Mechanics trait if Mechanis 6+
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.AUTOMECHANIC) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.AUTOMECHANIC);
			SOaddExpBoost(player, Perks.Mechanics, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_automechanic"), true, HaloTextHelper.getColorGreen());
		end
		
	end		

	-- METALLWEILD
	if perk == Perks.MetalWelding then
	-- Add MetalWelder
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.METAL_WELDER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.METAL_WELDER);
			SOaddExpBoost(player, Perks.MetalWelding, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_metalwelder"), true, HaloTextHelper.getColorGreen());
		end
	end			
	
	-- TAILORING
	if perk == Perks.Tailoring then
		-- Add Tailor
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(CharacterTrait.TAILOR) then
			player:getCharacterTraits():add(CharacterTrait.TAILOR);
			SOaddExpBoost(player, Perks.Tailoring, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen());
		end
	end		

	-- CARVING
	if perk == Perks.Carving then
		-- Add Whittler
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(CharacterTrait.WHITTLER) then
			player:getCharacterTraits():add(CharacterTrait.WHITTLER);
			SOaddExpBoost(player, Perks.Carving, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Whittler"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- MASONRY
	if perk == Perks.Masonry then
		-- Add Masonry
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.MASONRY) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.MASONRY);
			SOaddExpBoost(player, Perks.Masonry, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_masonry"), true, HaloTextHelper.getColorGreen());
		end
	end			
	
	-- POTTERY
	if perk == Perks.Pottery then
		-- Add Potter
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.POTTER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.POTTER);
			SOaddExpBoost(player, Perks.Pottery, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_potter"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- GLASSMAKING
	if perk == Perks.Glassmaking then
		-- Add Masonry
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.GLASSBLOWER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.GLASSBLOWER);
			SOaddExpBoost(player, Perks.Glassmaking, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_glassblower"), true, HaloTextHelper.getColorGreen());
		end
	end	
	
	-- BLACKSMITH
	if perk == Perks.Blacksmith then
		-- Add Blacksmith
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(CharacterTrait.BLACKSMITH) then
			player:getCharacterTraits():add(CharacterTrait.BLACKSMITH);
			SOaddExpBoost(player, Perks.Blacksmith, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Blacksmith"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- FLINTKNAPPING
	if perk == Perks.FlintKnapping then
		-- Add KnappingBasics
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.KNAPPING_BASICS) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.KNAPPING_BASICS);
			SOaddExpBoost(player, Perks.FlintKnapping, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_knappingbasics"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- HUSBANDRY
	if perk == Perks.Husbandry then
		-- Add AnimalFriend
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.ANIMAL_FRIEND) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.ANIMAL_FRIEND);
			SOaddExpBoost(player, Perks.Husbandry, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_animalfriend"), true, HaloTextHelper.getColorGreen());
		end
	end		

	-- BUTCHERING
	if perk == Perks.Butchering then
		-- Add Slaughterer
		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.SLAUGHTERER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.SLAUGHTERER);
			SOaddExpBoost(player, Perks.Butchering, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slaughterer"), true, HaloTextHelper.getColorGreen());
		end
	end

	-- Melting
--	if perk == Perks.Melting then
		-- Add Smelter
--		if SOTOSbvars.CraftTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait("Smelter") then
--			player:getCharacterTraits():add("Smelter");
--			SOaddExpBoost(player, Perks.Melting, 1);
--			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_smelter"), true, HaloTextHelper.getColorGreen());
--		end
--	end		
	
	-- COMBAT TRAITS	
	
	-- MAINTENANCE
	if perk == Perks.Maintenance then
		-- Add DURABILITY if maintenance 6+
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.DURABILITY) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.DURABILITY);
			SOaddExpBoost(player, Perks.Maintenance, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_durability"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- SMALL BLADE
	if perk == Perks.SmallBlade then
		-- add Stabber if Short Blade 6+		
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.KNIFER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.KNIFER);
			SOaddExpBoost(player, Perks.SmallBlade, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_knifer"), true, HaloTextHelper.getColorGreen());
		end
	end			
	
	-- SMALL BLUNT
	if perk == Perks.SmallBlunt then
		-- add Smasher if Short Blunt 6+	
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.BLUDGEONER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.BLUDGEONER);
			SOaddExpBoost(player, Perks.SmallBlunt, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_bludgeoner"), true, HaloTextHelper.getColorGreen());
		end
	end				
	
	-- AXE
	if perk == Perks.Axe then
		-- add Cutter if Axe 6+	
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.CUTTER) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.CUTTER);
			SOaddExpBoost(player, Perks.Axe, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_cutter"), true, HaloTextHelper.getColorGreen());
		end
	end	

	-- SPEAR
	if perk == Perks.Spear then
		-- add Spearman if Spears 6+	
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.SPEARMAN) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.SPEARMAN);
			SOaddExpBoost(player, Perks.Spear, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_spearman"), true, HaloTextHelper.getColorGreen());
		end
	end		
	
	-- LONG BLADE
	if perk == Perks.LongBlade then
		-- add Swordsman if Long Blade 6+	
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(SOTO.CharacterTrait.SWORDSMAN) then
			player:getCharacterTraits():add(SOTO.CharacterTrait.SWORDSMAN);
			SOaddExpBoost(player, Perks.LongBlade, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_swordsman"), true, HaloTextHelper.getColorGreen());
		end
	end			

	-- BLUNT
	if perk == Perks.Blunt then
		-- add BASEBALL_PLAYER if Long Blunt 6+
		if SOTOSbvars.CombatTraitsObtainable == true and perkLevel >= 6 and not player:hasTrait(CharacterTrait.BASEBALL_PLAYER) then
			player:getCharacterTraits():add(CharacterTrait.BASEBALL_PLAYER);
			SOaddExpBoost(player, Perks.Blunt, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PlaysBaseball"), true, HaloTextHelper.getColorGreen());
		end
	end

	-- FIREARM TRAITS
	
	-- AIMING
	if perk == Perks.Aiming then

		-- add Sharpshooter if Aiming lvl 6+ 
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 6 and not player:hasTrait(CharacterTrait.SHORT_SIGHTED) and not player:hasTrait(CharacterTrait.EAGLE_EYED) and player:hasTrait(SOTO.CharacterTrait.SHOOTER) and not player:hasTrait(SOTO.CharacterTrait.EXP_SHOOTER)then
			player:getCharacterTraits():add(SOTO.CharacterTrait.EXP_SHOOTER);
			player:getCharacterTraits():remove(SOTO.CharacterTrait.SHOOTER);				
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_expshooter"), true, HaloTextHelper.getColorGreen());
		end
		-- add Sharpshooter if Aiming lvl 5+ if EagleEyed
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 5 and not player:hasTrait(CharacterTrait.SHORT_SIGHTED) and player:hasTrait(CharacterTrait.EAGLE_EYED) and player:hasTrait(SOTO.CharacterTrait.SHOOTER) and not player:hasTrait(SOTO.CharacterTrait.EXP_SHOOTER)then
			player:getCharacterTraits():add(SOTO.CharacterTrait.EXP_SHOOTER);
			player:getCharacterTraits():remove(SOTO.CharacterTrait.SHOOTER);		
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_expshooter"), true, HaloTextHelper.getColorGreen());
		end		
		-- add Sharpshooter if Aiming lvl 7+ if ShortSighted	
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 7 and player:hasTrait(CharacterTrait.SHORT_SIGHTED) and not player:hasTrait(CharacterTrait.EAGLE_EYED) and player:hasTrait(SOTO.CharacterTrait.SHOOTER) and not player:hasTrait(SOTO.CharacterTrait.EXP_SHOOTER)then
			player:getCharacterTraits():add(SOTO.CharacterTrait.EXP_SHOOTER);
			player:getCharacterTraits():remove(SOTO.CharacterTrait.SHOOTER);				
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_expshooter"), true, HaloTextHelper.getColorGreen());
		end
		
		-- add Shooter if Aiming lvl 6+ 
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 6 and not player:hasTrait(CharacterTrait.SHORT_SIGHTED) and not player:hasTrait(CharacterTrait.EAGLE_EYED) and not player:hasTrait(SOTO.CharacterTrait.SHOOTER) and not player:hasTrait(SOTO.CharacterTrait.EXP_SHOOTER)then
			player:getCharacterTraits():add(SOTO.CharacterTrait.SHOOTER);
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_shooter"), true, HaloTextHelper.getColorGreen());
		end
		-- add Shooter if Aiming lvl 5+ if EagleEyed
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 5 and not player:hasTrait(CharacterTrait.SHORT_SIGHTED) and player:hasTrait(CharacterTrait.EAGLE_EYED) and not player:hasTrait(SOTO.CharacterTrait.SHOOTER) and not player:hasTrait(SOTO.CharacterTrait.EXP_SHOOTER)then
			player:getCharacterTraits():add(SOTO.CharacterTrait.SHOOTER);
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_shooter"), true, HaloTextHelper.getColorGreen());
		end
		-- add Shooter if Aiming lvl 7+ if ShortSighted	
		if SOTOSbvars.FirearmTraitsObtainable == true and perkLevel == 7 and player:hasTrait(CharacterTrait.SHORT_SIGHTED) and not player:hasTrait(CharacterTrait.EAGLE_EYED) and not player:hasTrait(SOTO.CharacterTrait.SHOOTER) and not player:hasTrait(SOTO.CharacterTrait.EXP_SHOOTER)then
			player:getCharacterTraits():add(SOTO.CharacterTrait.SHOOTER);
			SOaddExpBoost(player, Perks.Aiming, 1);
			SOaddExpBoost(player, Perks.Reloading, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_shooter"), true, HaloTextHelper.getColorGreen());
		end
	end	
end
