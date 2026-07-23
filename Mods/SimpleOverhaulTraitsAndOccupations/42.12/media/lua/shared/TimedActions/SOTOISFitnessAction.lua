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
		if player:HasTrait("SoreLegs")then
			SOAddPain(player, 7, "UpperLeg_L", ZombRand(5)+1);	
			SOAddPain(player, 7, "UpperLeg_R", ZombRand(5)+1);	
			SOAddPain(player, 20, "LowerLeg_L", ZombRand(5)+1);	
			SOAddPain(player, 20, "LowerLeg_R", ZombRand(5)+1);
		end	
		if player:HasTrait("HighSweaty") then	
			SOAddThirst(player, 10,  0.005);			
			SOAddWetness(player, 25, ZombRand(7));
		end
		
		if player:HasTrait("Endomorph") and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:HasTrait("Ectomorph") and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		
		if player:HasTrait("AccMetabolism") then -- Losing weight faster when weight over 70
			if weight >= 82 then -- loses weight faster when over 82+ weight
				player:getNutrition():setCalories(currcalories - (calexe * calmod))
			end
			if weight <= 78 then -- gains weight faster when below 78- weight
				player:getNutrition():setCalories(currcalories + (calexe * calmod))
			end
		end		
		
	elseif self.exercise == "burpees" then
		if player:HasTrait("SoreLegs")then
			SOAddPain(player, 7, "UpperLeg_L", ZombRand(5)+2);	
			SOAddPain(player, 7, "UpperLeg_R", ZombRand(5)+2);	
			SOAddPain(player, 20, "LowerLeg_L", ZombRand(5)+2);	
			SOAddPain(player, 20, "LowerLeg_R", ZombRand(5)+2);
			SOAddPain(player, 20, "Foot_L", ZombRand(4)+2);	
			SOAddPain(player, 20, "Foot_R", ZombRand(4)+2);		
		end
		if player:HasTrait("HighSweaty") then		
			SOAddThirst(player, 10,  0.005);		
			SOAddWetness(player, 25, ZombRand(9));
		end	
		if player:HasTrait("Endomorph") and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calburp * calmod))
		end
		if player:HasTrait("Ectomorph") and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calburp * calmod))
		end		
		if player:HasTrait("AccMetabolism") then -- Losing weight faster when weight over 70
			if weight >= 82 then -- loses weight faster when over 82+ weight
				player:getNutrition():setCalories(currcalories - (calburp * calmod))
			end
			if weight <= 78 then -- gains weight faster when below 78- weight
				player:getNutrition():setCalories(currcalories + (calburp * calmod))
			end
		end	
		
	elseif self.exercise == "pushups" then	
		if player:HasTrait("HighSweaty") then		
			SOAddThirst(player, 10,  0.005);		
			SOAddWetness(player, 25, ZombRand(7));
		end	

		if player:HasTrait("Endomorph") and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:HasTrait("Ectomorph") and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		
		if player:HasTrait("AccMetabolism") then -- Losing weight faster when weight over 70
			if weight >= 82 then -- loses weight faster when over 82+ weight
				player:getNutrition():setCalories(currcalories - (calexe * calmod))
			end
			if weight <= 78 then -- gains weight faster when below 78- weight
				player:getNutrition():setCalories(currcalories + (calexe * calmod))
			end
		end			

	elseif self.exercise == "situp" then
		if player:HasTrait("HighSweaty") then		
	--		player:Say("sweat train");	
			SOAddThirst(player, 10,  0.005);		
			SOAddWetness(player, 25, ZombRand(7));
		end	
		
		if player:HasTrait("Endomorph") and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:HasTrait("Ectomorph") and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		
		if player:HasTrait("AccMetabolism") then -- Losing weight faster when weight over 70
			if weight >= 82 then -- loses weight faster when over 82+ weight
				player:getNutrition():setCalories(currcalories - (calexe * calmod))
			end
			if weight <= 78 then -- gains weight faster when below 78- weight
				player:getNutrition():setCalories(currcalories + (calexe * calmod))
			end
		end			

	elseif self.exercise == "barbellcurl" then
		if player:HasTrait("HighSweaty") then		
	--		player:Say("sweat train");	
			SOAddThirst(player, 10,  0.005);		
			SOAddWetness(player, 25, ZombRand(7));
		end	
		
		if player:HasTrait("Endomorph") and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:HasTrait("Ectomorph") and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		
		if player:HasTrait("AccMetabolism") then -- Losing weight faster when weight over 70
			if weight >= 82 then -- loses weight faster when over 82+ weight
				player:getNutrition():setCalories(currcalories - (calexe * calmod))
			end
			if weight <= 78 then -- gains weight faster when below 78- weight
				player:getNutrition():setCalories(currcalories + (calexe * calmod))
			end
		end			

	elseif self.exercise == "dumbbellpress" then
		if player:HasTrait("HighSweaty") then		
	--		player:Say("sweat train");	
			SOAddThirst(player, 7,  0.005);			
			SOAddWetness(player, 20, ZombRand(7));
		end		
		
		if player:HasTrait("Endomorph") and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:HasTrait("Ectomorph") and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		
		if player:HasTrait("AccMetabolism") then -- Losing weight faster when weight over 70
			if weight >= 82 then -- loses weight faster when over 82+ weight
				player:getNutrition():setCalories(currcalories - (calexe * calmod))
			end
			if weight <= 78 then -- gains weight faster when below 78- weight
				player:getNutrition():setCalories(currcalories + (calexe * calmod))
			end
		end			
	
	elseif self.exercise == "bicepscurl" then	
		if player:HasTrait("HighSweaty") then		
	--		player:Say("sweat train");	
			SOAddThirst(player, 7,  0.005);		
			SOAddWetness(player, 20, ZombRand(7));
		end	

		if player:HasTrait("Endomorph") and weight <= 90 then -- Gain weight faster when below 90 weight
			player:getNutrition():setCalories(currcalories + (calexe * calmod))
		end
		if player:HasTrait("Ectomorph") and weight >= 70 then -- Losing weight faster when weight over 70
			player:getNutrition():setCalories(currcalories - (calexe * calmod))
		end		
		if player:HasTrait("AccMetabolism") then -- Losing weight faster when weight over 70
			if weight >= 82 then -- loses weight faster when over 82+ weight
				player:getNutrition():setCalories(currcalories - (calexe * calmod))
			end
			if weight <= 78 then -- gains weight faster when below 78- weight
				player:getNutrition():setCalories(currcalories + (calexe * calmod))
			end
		end			

	end
	
oldISFitnessAction_exeLooped(self)

end