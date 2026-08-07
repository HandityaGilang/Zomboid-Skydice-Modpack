require "TimedActions/ISBaseTimedAction"

local _Food = nil;
local _Character = nil;
local _Percent = nil;
local _hoursCount = 2;

function OnEat_SurvivalTabs(food, character, percent)
	
	--print("Firing ReTriggerFunction");
    _Food = food;
    _Character = character;
    _Percent = percent;
	
	--local thisID = _Food.getID();
	local curWeight = _Food:getWeight();
	
	--print("Item's current weight");
	--print(curWeight);
	
	curWeight = curWeight - .01;
	
	food:setWeight(curWeight);
	food:setActualWeight(curWeight);
	food:setCustomWeight(true);
		
	--print(food:getWeight());
	--print("Uses Left");
	--print(math.floor(curWeight * 100));
	
	if(math.floor(curWeight * 100) <= 0) then
		--print("Delete Used up Item");
		local usedItem = food:getContainer():getParent()
		food:getContainer():Remove(food)
	end
end