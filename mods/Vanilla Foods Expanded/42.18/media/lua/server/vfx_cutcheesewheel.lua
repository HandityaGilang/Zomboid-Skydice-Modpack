function VFX_CutCheeseWheel(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();

    local unhappyChange = 0;
    local boredomChange = 0;
    local stressChange  = 0;

    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
            unhappyChange = unhappyChange + item:getUnhappyChangeUnmodified() / 5;
            boredomChange = boredomChange + item:getBoredomChangeUnmodified() / 5;
            stressChange  = stressChange  + item:getStressChange() / 5;
        end
    end

    for j=0,results:size() - 1 do
        local result = results:get(j)
        if instanceof(result, "Food") then
            result:setUnhappyChange(unhappyChange);
            result:setBoredomChange(boredomChange);
            result:setStressChange(stressChange)
        end
    end

end