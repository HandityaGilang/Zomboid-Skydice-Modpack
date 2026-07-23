require "TimedAction/ISFitnessAction"

local oldISFitnessAction_exeLooped = ISFitnessAction.exeLooped

function ISFitnessAction:exeLooped()
	local player = self.character;
	local currcalories = player:getNutrition():getCalories()
	local weight = player:getNutrition():getWeight()	

	local calexe = 0.015 -- 1.0 per minute
	local calburp = 0.025 -- 1.0 per minute
	local calmod = 0.30 -- 1.0 per minute
	
	if self.exercise == "squats" then
		if player:hasTrait(SOTO.CharacterTrait.HIGH_SWEATY) then	
			SOAddThirst(player, 10,  0.005);			
			SOAddWetness(player, 25, ZombRand(7));
		end

		if player:hasTrait(SOTO.CharacterTrait.SLOW_METABOLISM) and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:hasTrait(SOTO.CharacterTrait.FAST_METABOLISM) and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		
	
	elseif self.exercise == "burpees" then
		if player:hasTrait(SOTO.CharacterTrait.HIGH_SWEATY) then		
			SOAddThirst(player, 10,  0.005);		
			SOAddWetness(player, 25, ZombRand(9));
		end	
		if player:hasTrait(SOTO.CharacterTrait.SLOW_METABOLISM) and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calburp * calmod))
		end
		if player:hasTrait(SOTO.CharacterTrait.FAST_METABOLISM) and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calburp * calmod))
		end		
		
	elseif self.exercise == "pushups" then	
		if player:hasTrait(SOTO.CharacterTrait.HIGH_SWEATY) then		
			SOAddThirst(player, 10,  0.005);		
			SOAddWetness(player, 25, ZombRand(7));
		end	

		if player:hasTrait(SOTO.CharacterTrait.SLOW_METABOLISM) and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:hasTrait(SOTO.CharacterTrait.FAST_METABOLISM) and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		

	elseif self.exercise == "situp" then
		if player:hasTrait(SOTO.CharacterTrait.HIGH_SWEATY) then		
	--		player:Say("sweat train");	
			SOAddThirst(player, 10,  0.005);		
			SOAddWetness(player, 25, ZombRand(7));
		end	
		
		if player:hasTrait(SOTO.CharacterTrait.SLOW_METABOLISM) and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:hasTrait(SOTO.CharacterTrait.FAST_METABOLISM) and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		

	elseif self.exercise == "barbellcurl" then
		if player:hasTrait(SOTO.CharacterTrait.HIGH_SWEATY) then		
	--		player:Say("sweat train");	
			SOAddThirst(player, 10,  0.005);		
			SOAddWetness(player, 25, ZombRand(7));
		end	
		
		if player:hasTrait(SOTO.CharacterTrait.SLOW_METABOLISM) and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:hasTrait(SOTO.CharacterTrait.FAST_METABOLISM) and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		

	elseif self.exercise == "dumbbellpress" then
		if player:hasTrait(SOTO.CharacterTrait.HIGH_SWEATY) then		
	--		player:Say("sweat train");	
			SOAddThirst(player, 7,  0.005);			
			SOAddWetness(player, 20, ZombRand(7));
		end		
		
		if player:hasTrait(SOTO.CharacterTrait.SLOW_METABOLISM) and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:hasTrait(SOTO.CharacterTrait.FAST_METABOLISM) and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		
	
	elseif self.exercise == "bicepscurl" then	
		if player:hasTrait(SOTO.CharacterTrait.HIGH_SWEATY) then		
	--		player:Say("sweat train");	
			SOAddThirst(player, 7,  0.005);		
			SOAddWetness(player, 20, ZombRand(7));
		end	

		if player:hasTrait(SOTO.CharacterTrait.SLOW_METABOLISM) and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:hasTrait(SOTO.CharacterTrait.FAST_METABOLISM) and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		

	end
	
oldISFitnessAction_exeLooped(self)

end