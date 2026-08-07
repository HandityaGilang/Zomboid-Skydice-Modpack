function MakeDynamicPlates(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems()
    local results = craftRecipeData:getAllCreatedItems()

    local plateCount = 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getFullType() == "Base.Plate" or item:getFullType() == "Base.ClayPlate" then
            plateCount = plateCount + 1
        end
    end

    plateCount = math.max(plateCount, 1)

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
            for j = 0, results:size() - 1 do
                local result = results:get(j)
                if instanceof(result, "Food") then


                    --B42.20 added some new thing so i will use them now 
                    result:copyFoodFromSplit(item, plateCount)

                    --Pretty sure those are forgotten from the above
                    result:setRottenTime(item:getRottenTime())
                    result:setBadCold(item:isBadCold())
                    
                    --This would give too much free cooking XP i think. You should not get ~10xp for every food you place in a plate.
                    --result:setChef(item:getChef())

                    --i should Add the herbal thing too maybe ? but i dont think you can add them to pan via a evolved recipe anyway.


                    --Dev made a typo ? maybe will need to be fixed later
                    result:setbDangerousUncooked(item:isbDangerousUncooked())

                    --that should overwrite copyCookedBurntFrom called by copyFoodFromSplit. copyCookedBurntFrom use the plate default value to make the math (bad)
                    --It also for some reason do not get saved (why idk?) when saving the game. food.save() for some reason do not save those 2 value. 
                    --So idk how most vanilla food manage to work without those 2 value saved. all 4 pan use default value i think (60/120) so i will simply add them to the plate too ig.
                    --This is a shit fix but i dont think i can make it better, i could save it inside a moddata inside the item but that sucks too.
                    result:setMinutesToCook(item:getMinutesToCook())
                    result:setMinutesToBurn(item:getMinutesToBurn())
                    --This is technically useless as it would set the same default as all plate AND get reverted to the plate default at game load.

                    result:setCookingTime(item:getCookingTime())
                    result:setCooked(item:isCooked())
                    result:setBurnt(item:isBurnt())
                    result:setHeat(item:getHeat())
                    
                    -- result:setAge(item:getAge())
                    -- result:setRottenTime(item:getRottenTime())
                    -- result:setMinutesToCook(item:getMinutesToCook())
                    -- result:setMinutesToBurn(item:getMinutesToBurn())
                    -- result:setCooked(item:isCooked())
                    -- result:setBurnt(item:isBurnt())
                    -- result:setBaseHunger(item:getBaseHunger() / plateCount)
                    -- result:setHungChange(item:getHungChange() / plateCount)
                    -- result:setThirstChange(item:getThirstChangeUnmodified() / plateCount)

                    --copyFoodFromSplit already do it but i want to keep the "buff" that the plate add so i overwrite it.
                    result:setBoredomChange((item:getBoredomChangeUnmodified() / plateCount) - 5)
                    result:setUnhappyChange((item:getUnhappyChangeUnmodified() / plateCount) - 8)


                    -- result:setCarbohydrates(item:getCarbohydrates() / plateCount)
                    -- result:setLipids(item:getLipids() / plateCount)
                    -- result:setProteins(item:getProteins() / plateCount)
                    -- result:setCalories(item:getCalories() / plateCount)
                    -- result:setTainted(item:isTainted())
                    

                    --Adding extra item fuckup the weight of the plate as 60% of each extra item weight are added to each plate

                    -- if item:haveExtraItems() then
                    --     for k = 0, item:getExtraItems():size() - 1 do
                    --         local extraItem = item:getExtraItems():get(k)
                    --         result:addExtraItem(extraItem)
                    --     end
                    -- end

                    if item:getFullType() == "Base.ClayPlate" then
                        result:setName("Ceramic Plate of " .. item:getDisplayName())
                    else
                        result:setName("Plate of " .. item:getDisplayName())
                    end
                    result:setCustomName(true)
                    
                    --Idk if that still needed for MP but it dont cause dup anyway so i will keep it
                    result:syncItemFields()
                    sendAddItemToContainer(character:getInventory(), result)
                end
            end
        end
    end
end
