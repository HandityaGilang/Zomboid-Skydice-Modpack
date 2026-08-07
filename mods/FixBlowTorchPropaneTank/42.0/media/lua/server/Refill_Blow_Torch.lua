Recipe = Recipe or {}
Recipe.OnCreate = Recipe.OnCreate or {}

-- Fill entirely the blowtorch with the remaining propane
function Recipe.OnCreate.RefillBlowTorch(craftRecipeData, character)
	local result = craftRecipeData:getAllCreatedItems():get(0);
    local previousBT = craftRecipeData:getAllConsumedItems():get(0);
    local propaneTank = craftRecipeData:getAllKeepInputItems():get(0);
	
    result:setCurrentUsesFloat(previousBT:getCurrentUsesFloat());

	if propaneTank:getCurrentUsesFloat() >= 0.0625 then
        result:setCurrentUsesFloat(1);
		propaneTank:setCurrentUses(propaneTank:getCurrentUses() - (propaneTank:getMaxUses() / 16 - 1));
        propaneTank:Use();
	else
        result:setCurrentUsesFloat(propaneTank:getCurrentUsesFloat() / 0.0625);
		propaneTank:setCurrentUses(1);
        propaneTank:Use();
	end
	sendItemStats(result)
	sendItemStats(propaneTank)
	
 end