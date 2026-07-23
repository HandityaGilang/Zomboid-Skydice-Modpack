function MakeDynamicPlates(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems()
    local results = craftRecipeData:getAllCreatedItems()

    -- Determine the number of plates used
    local plateCount = 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getFullType() == "Base.Plate" or item:getFullType() == "Base.ClayPlate" then
            plateCount = plateCount + 1
        end
    end

    -- Ensure there's at least one plate to avoid division by zero
    plateCount = math.max(plateCount, 1)

    -- Process the results
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
            for j = 0, results:size() - 1 do
                local result = results:get(j)
                if instanceof(result, "Food") then

                    result:setAge(item:getAge())
                    result:setRottenTime(item:getRottenTime())
                    result:setMinutesToCook(item:getMinutesToCook())
                    result:setMinutesToBurn(item:getMinutesToBurn())
                    result:setCooked(item:isCooked())
                    result:setBurnt(item:isBurnt())
                    result:setBaseHunger(item:getBaseHunger() / plateCount)
                    result:setHungChange(item:getHungChange() / plateCount)
                    result:setThirstChange(item:getThirstChangeUnmodified() / plateCount)
                    result:setBoredomChange((item:getBoredomChangeUnmodified() / plateCount) - 5)
                    result:setUnhappyChange((item:getUnhappyChangeUnmodified() / plateCount) - 8)
                    result:setCarbohydrates(item:getCarbohydrates() / plateCount)
                    result:setLipids(item:getLipids() / plateCount)
                    result:setProteins(item:getProteins() / plateCount)
                    result:setCalories(item:getCalories() / plateCount)
                    result:setTainted(item:isTainted())
                    result:setBadCold(item:isBadCold())

                    result:setActualWeight(0.1)

                    if item:haveExtraItems() then
                        for k = 0, item:getExtraItems():size() - 1 do
                            local extraItem = item:getExtraItems():get(k)
                            result:addExtraItem(extraItem)
                        end
                    end

                    -- Adjust the name dynamically
                    if item:getFullType() == "Base.ClayPlate" then
                        result:setName("Ceramic Plate of " .. item:getDisplayName())
                    else
                        result:setName("Plate of " .. item:getDisplayName())
                    end
                    result:setCustomName(true)
                end
            end
        end
    end
end
