function RecipeCodeOnCreate.DismantleCigarette(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems();
	local result = craftRecipeData:getAllCreatedItems():get(0);

    for i=0, items:size()-1 do
        if items:get(i):getType() == "CigaretteSingle" then
            result:setUsedDelta(0.02);
        elseif items:get(i):getType() == "CigaretteRolled" then
            result:setUsedDelta(0.02);
        elseif items:get(i):getType() == "Cigarillo" then
            result:setUsedDelta(0.06);
        elseif items:get(i):getType() == "Cigar" then
            result:setUsedDelta(0.2);
        elseif items:get(i):getType() == "CigarRolled" then
            result:setUsedDelta(0.2);
        elseif items:get(i):getType() == "CigaretteHemp" then
            result:setUsedDelta(0.02);
        elseif items:get(i):getType() == "CigarHemp" then
            result:setUsedDelta(0.2);
        end
    end
end

function RecipeCodeOnCreate.GrindBuds(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems();
	local result = craftRecipeData:getAllCreatedItems():get(0);

    for i=0, items:size()-1 do
        if items:get(i):getType() == "HempBuds_Cured" then
            result:setUsedDelta(0.2);
        end
    end
end

function RecipeCodeOnCreate.CutPapers(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems();
	local result = craftRecipeData:getAllCreatedItems():get(0);

    for i=0, items:size()-1 do
        if items:get(i):getType() == "PaperSheetPressed" then
            result:setUsedDelta(0.2);
        end
    end
end