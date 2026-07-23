local isClient = isClient();
local function calculateMultiplier()
	local player = getPlayer();
	local profession = player:getDescriptor():getCharacterProfession();
	local multiplier = 0.25
	
	if SandboxVars.BecomeDesensitized.ConsiderTraits then
		--Good Traits
		if player:hasTrait(CharacterTrait.BRAVE) then
			multiplier = multiplier + 0.05 --0.30
		end
		
		if player:hasTrait(CharacterTrait.HUNTER) then
			multiplier = multiplier + 0.025 --0.325
		end

		--Bad Traits
		if player:hasTrait(CharacterTrait.COWARDLY) then --0.20
			multiplier = multiplier - 0.05
		end
	
		if player:hasTrait(CharacterTrait.AGORAPHOBIC) then  --0.0175
			multiplier = multiplier - 0.025
		end
	
		if player:hasTrait(CharacterTrait.CLAUSTROPHOBIC) then --0.15
			multiplier = multiplier - 0.025
		end
	
		if player:hasTrait(CharacterTrait.HEMOPHOBIC) then --0.125
			multiplier = multiplier - 0.025
		end

		if player:hasTrait(CharacterTrait.PACIFIST) then --0.075
			multiplier = multiplier - 0.05
		end
	end
	
	if SandboxVars.BecomeDesensitized.ConsiderOccupations then 
		if profession == CharacterProfession.POLICE_OFFICER then
			multiplier = multiplier + 0.05
		elseif profession == CharacterProfession.FIRE_OFFICER then
			multiplier = multiplier + 0.025
		elseif profession == CharacterProfession.PARK_RANGER then
			multiplier = multiplier + 0.01
		elseif profession == CharacterProfession.SECURITY_GUARD then
			multiplier = multiplier + 0.01
		elseif profession == CharacterProfession.DOCTOR then
			multiplier = multiplier + 0.05
		elseif profession == CharacterProfession.NURSE then
			multiplier = multiplier + 0.05
		end
	end

	return multiplier
end

local function updateTraits(player, traits, hasTrait)
	if hasTrait then
	--[[
		if player:hasTrait(CharacterTrait.BRAVE) then
			traits:remove(CharacterTrait.BRAVE); 
		end

		if player:hasTrait(CharacterTrait.COWARDLY) then
			traits:remove(CharacterTrait.COWARDLY); 
		end

		if player:hasTrait(CharacterTrait.AGORAPHOBIC) then
			traits:remove(CharacterTrait.AGORAPHOBIC); 
		end

		if player:hasTrait(CharacterTrait.CLAUSTROPHOBIC) then
			traits:remove(CharacterTrait.CLAUSTROPHOBIC); 
		end

		if player:hasTrait(CharacterTrait.HEMOPHOBIC) then
			traits:remove(CharacterTrait.HEMOPHOBIC); 
		end

		if player:hasTrait(CharacterTrait.ADRENALINE_JUNKIE) then
			traits:remove(CharacterTrait.ADRENALINE_JUNKIE); 
		end
	]]
		local traitsArray = {
		CharacterTrait.BRAVE,
		CharacterTrait.COWARDLY,
		CharacterTrait.AGORAPHOBIC,
		CharacterTrait.CLAUSTROPHOBIC,
		CharacterTrait.HEMOPHOBIC,
		CharacterTrait.ADRENALINE_JUNKIE
		}
		if not isClient then
			for _,value in ipairs(traitsArray) do
				if player:hasTrait(value) then
					traits:remove(value);
				end
			end
		end
		if isClient then
			local args = {onlineID = player:getOnlineID()}
			sendClientCommand("updateModule", "updateCommand", args)
		end
	end
end


local function checkTraits()
	local player = getPlayer();
	local playerData = player:getModData();
	local traits = player:getCharacterTraits();
	local hasDesensitized = player:hasTrait(CharacterTrait.DESENSITIZED);

	updateTraits(player, traits, hasDesensitized);
end

local function becomeDesensitized()
	local player = getPlayer();
	local traits = player:getCharacterTraits();
	local hasDesensitized = player:hasTrait(CharacterTrait.DESENSITIZED);

	if hasDesensitized == false then
		if not isClient then
			traits:add(CharacterTrait.DESENSITIZED);
		end
		if isClient then
			local args = {onlineID = player:getOnlineID()}
			sendClientCommand("becomeDesensitizedModule", "becomeDesensitizedCommand", args)
		end
		hasDesensitized = true;
	end

	updateTraits(player, traits, hasDesensitized);
end

--run every day
local function checkDesensitized()
	local player = getPlayer();

	if player:hasTrait(CharacterTrait.DESENSITIZED) then
		-- do nothing for now 
		-- might do checks for lower zombie killing count over a number of weeks
		-- if player has a low zombie killing count, lose desensitized
	else 
		local playerData = player:getModData();
		local selectedMinZKills = SandboxVars.BecomeDesensitized.MinimumZombieKills;
		local selectedMaxZKills = SandboxVars.BecomeDesensitized.MaximumZombieKills;
		local zombieKills = player:getZombieKills();
		local zombiesKilledDifference = zombieKills;
		
		-- if over MaximumZombieKills zombie kills, automatically become Desensitized
		if zombiesKilledDifference >= selectedMaxZKills then
			becomeDesensitized();
			return;
		--elseif killed more than MinimumZombieKills new zombies
		elseif zombiesKilledDifference > selectedMinZKills then
			local multiplier = calculateMultiplier()
			local probability = zombiesKilledDifference / selectedMaxZKills;
			local probabilityTreshold = 100 * probability * multiplier;
			
			local randomNumber = ZombRand(1, 100);

			if randomNumber < probabilityTreshold then
				becomeDesensitized();
				return;
			end
		else
			return;
		end
	end
end

Events.EveryDays.Add(checkDesensitized);
Events.EveryDays.Add(checkTraits);