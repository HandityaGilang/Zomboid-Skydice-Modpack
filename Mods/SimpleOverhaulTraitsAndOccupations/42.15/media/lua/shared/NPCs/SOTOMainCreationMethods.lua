SOTOBaseGameCharacterDetails = {}

	----------------------------------------------
	--- SIMPLE OVERHAUL TRAITS AND OCCUPATIONS ---
	----------------------------------------------

SOTOBaseGameCharacterDetails.DoNewCharacterInitializations = function(playernum, character)
	local player = getSpecificPlayer(playernum);

	-- BRAVE BONUS
	if player:hasTrait(CharacterTrait.BRAVE) or player:hasTrait(SOTO.CharacterTrait.BRAVE2) then
		if player:getModData().SOBraveBonus == nil then
		player:getModData().SOBraveBonus = 1;
		end	
	end

	-- COWARDLY PENALTY
	if player:hasTrait(CharacterTrait.COWARDLY) then
		if player:getModData().SOCowardlyPenalty == nil then
		player:getModData().SOCowardlyPenalty = 1;
		end	
	end	

	-- ALCOHOLIC MOD DATA
	if player:hasTrait(SOTO.CharacterTrait.ALCOHOLIC) then	
		if player:getModData().AlcoholicTimeSinceLastDrink == nil then
			player:getModData().AlcoholicTimeSinceLastDrink = 0;
		end	
	end

	if player:hasTrait(SOTO.CharacterTrait.CHRONIC_MIGRAINE) then
		if player:getModData().migraineCooldown == nil then
			player:getModData().migraineCooldown = 0
		end
		if player:getModData().migraineDuration == nil then
			player:getModData().migraineDuration = 0
		end
		local initialDelay = ZombRand(72, 288) -- 12-48 hours
		player:getModData().migraineCooldown = initialDelay
		-- local initialDelayHours = math.floor(initialDelay)
		-- print("The first migraine:" .. initialDelayHours)
	end

	if player:hasTrait(SOTO.CharacterTrait.SLACK) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.SLACK); -- revoming trait since its only affect strength and fitness
	end		
	if player:hasTrait(SOTO.CharacterTrait.TAUT) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.TAUT); -- revoming trait since its only affect strength and fitness
	end	
	
	-- TRAITS SWAP	
	if player:hasTrait(SOTO.CharacterTrait.BRAVE2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.BRAVE2);
		player:getCharacterTraits():add(CharacterTrait.BRAVE);
	end
	if player:hasTrait(SOTO.CharacterTrait.TIRELESS2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.TIRELESS2);
		player:getCharacterTraits():add(SOTO.CharacterTrait.TIRELESS);
	end	
	if player:hasTrait(SOTO.CharacterTrait.DEXTROUS2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.DEXTROUS2);
		player:getCharacterTraits():add(CharacterTrait.DEXTROUS);
	end
	
	if player:hasTrait(SOTO.CharacterTrait.INVENTIVE2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.INVENTIVE2);
		player:getCharacterTraits():add(CharacterTrait.INVENTIVE);
	end		
	if player:hasTrait(SOTO.CharacterTrait.GENERATOR_EXPERT2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.GENERATOR_EXPERT2);
		player:getCharacterTraits():add(SOTO.CharacterTrait.GENERATOR_EXPERT);
	end	
	if player:hasTrait(SOTO.CharacterTrait.HANDY2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.HANDY2);
		player:getCharacterTraits():add(CharacterTrait.HANDY);
	end	
	if player:hasTrait(SOTO.CharacterTrait.STRONG_BACK2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.STRONG_BACK2);
		player:getCharacterTraits():add(SOTO.CharacterTrait.STRONG_BACK);
	end	
	if player:hasTrait(SOTO.CharacterTrait.HERBALIST2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.HERBALIST2);
		player:getCharacterTraits():add(CharacterTrait.HERBALIST);
	end		
	if player:hasTrait(CharacterTrait.COOK2) then
		player:getCharacterTraits():remove(CharacterTrait.COOK2);
		player:getCharacterTraits():add(CharacterTrait.COOK);
	end		
	if player:hasTrait(CharacterTrait.NUTRITIONIST2) then
		player:getCharacterTraits():remove(CharacterTrait.NUTRITIONIST2);
		player:getCharacterTraits():add(CharacterTrait.NUTRITIONIST);
	end	
	if player:hasTrait(CharacterTrait.MECHANICS2) then
		player:getCharacterTraits():remove(CharacterTrait.MECHANICS2);
		player:getCharacterTraits():add(CharacterTrait.MECHANICS);
	end
	if player:hasTrait(SOTO.CharacterTrait.ORGANIZED2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.ORGANIZED2);
		player:getCharacterTraits():add(CharacterTrait.ORGANIZED);
	end
	if player:hasTrait(SOTO.CharacterTrait.GRACEFUL2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.GRACEFUL2);
		player:getCharacterTraits():add(CharacterTrait.GRACEFUL);
	end	
	if player:hasTrait(SOTO.CharacterTrait.INCONSPICUOUS2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.INCONSPICUOUS2);
		player:getCharacterTraits():add(CharacterTrait.INCONSPICUOUS);
	end	
	if player:hasTrait(SOTO.CharacterTrait.PACIFIST2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.PACIFIST2);
		player:getCharacterTraits():add(CharacterTrait.PACIFIST);
	end	
	if player:hasTrait(SOTO.CharacterTrait.SHOOTER2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.SHOOTER2);
		player:getCharacterTraits():add(SOTO.CharacterTrait.SHOOTER);
	end			
	if player:hasTrait(SOTO.CharacterTrait.FAST_READER2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.FAST_READER2);
		player:getCharacterTraits():add(CharacterTrait.FAST_READER);
	end		
	if player:hasTrait(SOTO.CharacterTrait.ADRENALINE_JUNKIE2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.ADRENALINE_JUNKIE2);
		player:getCharacterTraits():add(CharacterTrait.ADRENALINE_JUNKIE);
	end
	if player:hasTrait(SOTO.CharacterTrait.SCOUT2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.SCOUT2);
		player:getCharacterTraits():add(CharacterTrait.SCOUT);
	end	
	if player:hasTrait(SOTO.CharacterTrait.SPEED_DEMON2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.SPEED_DEMON2);
		player:getCharacterTraits():add(CharacterTrait.SPEED_DEMON);
	end		
	if player:hasTrait(SOTO.CharacterTrait.EAGLE_EYED2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.EAGLE_EYED2);
		player:getCharacterTraits():add(CharacterTrait.EAGLE_EYED);
	end	
	if player:hasTrait(SOTO.CharacterTrait.FIRST_AID2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.FIRST_AID2);
		player:getCharacterTraits():add(CharacterTrait.FIRST_AID);
	end
	if player:hasTrait(SOTO.CharacterTrait.GARDENER2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.GARDENER2);
		player:getCharacterTraits():add(CharacterTrait.GARDENER);
	end	
	if player:hasTrait(SOTO.CharacterTrait.ANIMAL_FRIEND2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.ANIMAL_FRIEND2);
		player:getCharacterTraits():add(CharacterTrait.ANIMAL_FRIEND);
	end
	if player:hasTrait(SOTO.CharacterTrait.SLAUGHTERER2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.SLAUGHTERER2);
		player:getCharacterTraits():add(SOTO.CharacterTrait.SLAUGHTERER);
	end
	if player:hasTrait(SOTO.CharacterTrait.HUNTER2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.HUNTER2);
		player:getCharacterTraits():add(CharacterTrait.HUNTER);
	end
	if player:hasTrait(SOTO.CharacterTrait.DESENSITIZED2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.DESENSITIZED2);
		player:getCharacterTraits():add(CharacterTrait.DESENSITIZED);
	end
	if player:hasTrait(SOTO.CharacterTrait.NIGHT_VISION2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.NIGHT_VISION2);
		player:getCharacterTraits():add(CharacterTrait.NIGHT_VISION);
	end
	if player:hasTrait(SOTO.CharacterTrait.GYMNAST2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.GYMNAST2);
		player:getCharacterTraits():add(CharacterTrait.GYMNAST);
	end	
	if player:hasTrait(SOTO.CharacterTrait.OUTDOORSMAN2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.OUTDOORSMAN2);
		player:getCharacterTraits():add(CharacterTrait.OUTDOORSMAN);
	end	
	if player:hasTrait(SOTO.CharacterTrait.KEEN_HEARING2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.KEEN_HEARING2);
		player:getCharacterTraits():add(CharacterTrait.KEEN_HEARING);
	end		
	if player:hasTrait(SOTO.CharacterTrait.CRUELTY2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.CRUELTY2);
		player:getCharacterTraits():add(SOTO.CharacterTrait.CRUELTY);
	end		
	if player:hasTrait(SOTO.CharacterTrait.BREATHING_TECHNIQUE2) then
		player:getCharacterTraits():remove(SOTO.CharacterTrait.BREATHING_TECHNIQUE2);
		player:getCharacterTraits():add(SOTO.CharacterTrait.BREATHING_TECHNIQUE);
	end	
	
end

Events.OnCreatePlayer.Add(SOTOBaseGameCharacterDetails.DoNewCharacterInitializations);


SOTOBaseGameCharacterDetails.WeightFixCharacterInitializations = function(playernum, character)
    local player = getSpecificPlayer(playernum)
    if not player then return end

    local modData = player:getModData()

    if modData.SOTOWeightFixed then
        return
    end

    -- FIX FOR VANILLA WEIGHT START
    if player:hasTrait(CharacterTrait.UNDERWEIGHT) then
        player:getNutrition():setWeight(70)
    elseif player:hasTrait(CharacterTrait.VERY_UNDERWEIGHT) then
        player:getNutrition():setWeight(60)
    elseif player:hasTrait(CharacterTrait.OVERWEIGHT) then
        player:getNutrition():setWeight(95)
    elseif player:hasTrait(CharacterTrait.OBESE) then
        player:getNutrition():setWeight(105)
    else
        player:getNutrition():setWeight(80)
    end

    modData.SOTOWeightFixed = true
end

Events.OnCreatePlayer.Add(SOTOBaseGameCharacterDetails.WeightFixCharacterInitializations)