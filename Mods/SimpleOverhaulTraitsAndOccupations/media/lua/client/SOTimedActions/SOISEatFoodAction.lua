require "TimedActions/ISEatFoodAction"

local oldISEatFoodAction_perform = ISEatFoodAction.perform
function ISEatFoodAction:perform(...)

    oldISEatFoodAction_perform(self, ...)

	-- Alcohol 
	if self.character:HasTrait("SOAlcoholic") then
		if self.character:getModData().SOtenminutesSinceLastDrink == nil then
			self.character:getModData().SOtenminutesSinceLastDrink = 0;
		end		
		if self.character:getModData().SOAlcoholBottlesDrinked == nil then
			self.character:getModData().SOAlcoholBottlesDrinked = 0; 
		end	
	
		local AbstinenceMult = 1
		if self.character:getModData().SOtenminutesSinceLastDrink >= 1008 then
			AbstinenceMult = 3
		end
		if self.character:getSleepingPillsTaken() == 0 and self.item:isAlcoholic() then
			-- print("ALCOHOL")
			self.character:getModData().SOAlcoholBottlesDrinked = self.character:getModData().SOAlcoholBottlesDrinked + (60 * self:getJobDelta()) -- 60 mins
			self.character:getModData().SOtenminutesSinceLastDrink = self.character:getModData().SOtenminutesSinceLastDrink - ((432 * AbstinenceMult) * self:getJobDelta())	
			if self.character:getModData().SOtenminutesSinceLastDrink <= 0 then
				self.character:getModData().SOtenminutesSinceLastDrink = 0
			end
			if self.character:getModData().SOAlcoholBottlesDrinked >= 240 then 
				self.character:setSleepingTabletEffect(self.character:getModData().SOAlcoholBottlesDrinked * 4) 
				else
				self.character:setSleepingTabletEffect(0)
			end
		end	
	end
	
	if not self.character:HasTrait("SOAlcoholic") and self.item:isAlcoholic() then
		self.character:getModData().SOtenminutesToObtainAlcoholic = self.character:getModData().SOtenminutesToObtainAlcoholic + (200 * self:getJobDelta())	
	end	
	
end

local oldISEatFoodAction_stop = ISEatFoodAction.stop
function ISEatFoodAction:stop(...)
	
    oldISEatFoodAction_stop(self, ...)

	if self.character:HasTrait("SOAlcoholic") then
		if self.character:getModData().SOtenminutesSinceLastDrink == nil then
			self.character:getModData().SOtenminutesSinceLastDrink = 0;
		end	
		if self.character:getModData().SOAlcoholBottlesDrinked == nil then
			self.character:getModData().SOAlcoholBottlesDrinked = 0; 
		end	
			
		local AbstinenceMult = 1
		if self.character:getModData().SOtenminutesSinceLastDrink >= 1008 then
			AbstinenceMult = 3
		end
		if self.character:getSleepingPillsTaken() == 0 and self.item:isAlcoholic() then
			-- print("ALCOHOL")
			self.character:getModData().SOAlcoholBottlesDrinked = self.character:getModData().SOAlcoholBottlesDrinked + (60 * self:getJobDelta()) -- 60 mins
			self.character:getModData().SOtenminutesSinceLastDrink = self.character:getModData().SOtenminutesSinceLastDrink - ((432 * AbstinenceMult) * self:getJobDelta())	
			if self.character:getModData().SOtenminutesSinceLastDrink <= 0 then
				self.character:getModData().SOtenminutesSinceLastDrink = 0
			end
			if self.character:getModData().SOAlcoholBottlesDrinked >= 240 then 
				self.character:setSleepingTabletEffect(self.character:getModData().SOAlcoholBottlesDrinked * 4) 
				else
				self.character:setSleepingTabletEffect(0)
			end
		end	
	end
	
	if not self.character:HasTrait("SOAlcoholic") and self.item:isAlcoholic() then
		self.character:getModData().SOtenminutesToObtainAlcoholic = self.character:getModData().SOtenminutesToObtainAlcoholic + (200 * self:getJobDelta())	
	end

end

