
--sapph: hello! b42 mp got released, so most of the stuff here is going to be gone or tweaked!
-- had to remove all the recipe codes, as i was getting lots of errors in b42.13.

--sapph (from 12/22/25) - been trying to fix some issues, but end of the year and holliday shenannigans are making things difficult,
-- so i decided to just remove temporarely all the errors in the code (the new character stats functions), that way i can fix them later 
local SapphCookingRegistries = require("SapphCookingRegistries")

function SapphAutoCook(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    local hungerSum = 0;
    local hungerChangeSum = 0;
    local thirstSum = 0;
    local unhappySum = 0.3; --adds a bit of happiness
    local carbsSum = 0;
    local lipidsSum = 0;
    local proteinsSum = 0;
    local caloriesSum = 0;
    local weightSum = 0;
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
            hungerSum = hungerSum + item:getBaseHunger();
            hungerChangeSum = hungerChangeSum + item:getHungChange();
            thirstSum = thirstSum;
            unhappySum = unhappySum + item:getUnhappyChangeUnmodified();
            carbsSum = carbsSum + item:getCarbohydrates();
            lipidsSum = lipidsSum + item:getLipids();
            proteinsSum = proteinsSum + item:getProteins();
            caloriesSum = caloriesSum + item:getCalories();
            weightSum = weightSum + item:getWeight();
        end
    end
    for j=0,results:size() - 1 do
        local result = results:get(j)
            if instanceof(result, "Food") then
                result:setBaseHunger(hungerSum);
                result:setHungChange(hungerChangeSum);
                result:setThirstChange(thirstSum);
                result:setUnhappyChange(unhappySum);
                result:setCarbohydrates(carbsSum);
                result:setLipids(lipidsSum);
                result:setProteins(proteinsSum);
                result:setCalories(caloriesSum);
                result:setCooked(true);
                result:setHeat(2.5);
                result:setAge(0);
            end
        end  
    --get the boredom/status of the player.
    --makes the player happy when cooking c:
    --[[
    local player = getPlayer();
    local stats = player:getStats();    
    local currentUnhappiness = stats:get(CharacterStat.UNHAPPINESS); 
    local currentBoredom = stats:get(CharacterStat.BOREDOM);  
    local currentStress = stats:get(CharacterStat.STRESS);
    player:set(CharacterStat.UNHAPPINESS, currentUnhappiness - 4); 
    player:set(CharacterStat.BOREDOM, currentBoredom - 4); 
    player:set(CharacterStat.STRESS, currentStress - .1);
    --]]
end


function SapphBrewCoffee(craftRecipeData, character) 
    local result = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0, items:size()-1 do
        if items:get(i):getType() == "ClothFilter" then
        character:getInventory():AddItem("SapphCooking.DirtyClothFilter");
        end
        if items:get(i):getType() == "CheeseCloth" then
        character:getInventory():AddItem("Base.CheeseCloth");
        end
    end
    --get the boredom/status of the player.
    --makes the player happy when cooking c:
    --[[
    local player = getPlayer();
    local stats = player:getStats();    
    local currentUnhappiness = stats:get(CharacterStat.UNHAPPINESS); 
    local currentBoredom = stats:get(CharacterStat.BOREDOM);  
    local currentStress = stats:get(CharacterStat.STRESS);
    player:set(CharacterStat.UNHAPPINESS, currentUnhappiness - 4); 
    player:set(CharacterStat.BOREDOM, currentBoredom - 4); 
    player:set(CharacterStat.STRESS, currentStress - .1);
    HaloTextHelper.addTextWithArrow(character, getText("IGUI_HaloNote_Stress"), false, HaloTextHelper.getColorGreen());
    ]]--  
end

-- Adding Candles on cakes.
--  sapph(from 2023-ish): So... wasn't sure why i added this.
-- someone a few months ago said they had their birthday on zomboid,
-- so i guess this was made with that in mind, some way of adding candles on a cakes
-- birthdays should be fun, so hopefully this can help with that.
-- heh, only time will tell.

--sapph(from june/2024): guess, i'm doing back on this idea again :3
--this code is here, cause i don't want the player to be able to 
--re-use candles on cakes (since they'll give the player a stress/happiness boost).

--sapph(from december/2025): oh - most of that code became vanilla flags/functions - so hooray~ 

function FryingCooking(craftRecipeData, character)
--sums all of the consumed items into the result.
--then sets the result to cooked, and hot.
--but since we're cooking with oil - this oncreate adds some more calories on the result item.
local results = craftRecipeData:getAllCreatedItems();
local items = craftRecipeData:getAllConsumedItems();
local hungerSum = 0;
local hungerChangeSum = 0;
local thirstSum = 0;
local unhappySum = 0;
local carbsSum = 0;
local lipidsSum = 0;
local proteinsSum = 0;
local caloriesSum = 0;
local weightSum = 0;
for i=0,items:size() - 1 do
    local item = items:get(i)
    if instanceof(item, "Food") then
        hungerSum = hungerSum + item:getBaseHunger();
        hungerChangeSum = hungerChangeSum + item:getHungChange();
        thirstSum = thirstSum;
        unhappySum = unhappySum + item:getUnhappyChangeUnmodified();
        carbsSum = carbsSum + item:getCarbohydrates();
        lipidsSum = lipidsSum + item:getLipids();
        proteinsSum = proteinsSum + item:getProteins();
        caloriesSum = caloriesSum + item:getCalories();
        weightSum = weightSum + item:getWeight()
        if item:getType() == "farming.Potato" then --gives the player a potato peel
        character:getInventory():AddItem("SapphCooking.PotatoPeel")
        end
    end
end
for j=0,results:size() - 1 do
    local result = results:get(j)
        if instanceof(result, "Food") then
            result:setBaseHunger(hungerSum);
            result:setHungChange(hungerChangeSum);
            result:setThirstChange(thirstSum);
            result:setUnhappyChange(unhappySum);
            result:setCarbohydrates(carbsSum);
            result:setLipids(lipidsSum);
            result:setProteins(proteinsSum);
            result:setCalories(caloriesSum + 200);
            result:setCooked(true);
            result:setHeat(2.5);
            result:setAge(0);
        end
    end  
--get the boredom/status of the player.
--makes the player happy when cooking c:
    --[[
    local player = getPlayer();
    local stats = player:getStats();    
    local currentUnhappiness = stats:get(CharacterStat.UNHAPPINESS); 
    local currentBoredom = stats:get(CharacterStat.BOREDOM);  
    local currentStress = stats:get(CharacterStat.STRESS);
    player:set(CharacterStat.UNHAPPINESS, currentUnhappiness - 4); 
    player:set(CharacterStat.BOREDOM, currentBoredom - 4); 
    player:set(CharacterStat.STRESS, currentStress - .1);
    HaloTextHelper.addTextWithArrow(character, getText("IGUI_HaloNote_Stress"), false, HaloTextHelper.getColorGreen());
    ]]--  

end


function FryingCookingTwoResult(craftRecipeData, character)
    --sums all of the consumed items into the result.
    --then sets the result to cooked, and hot.
    --but since we're cooking with oil - this oncreate adds some more calories on the result item.
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    local hungerSum = 0;
    local hungerChangeSum = 0;
    local thirstSum = 0;
    local unhappySum = 0.3; --adds a bit of happiness
    local carbsSum = 0;
    local lipidsSum = 0;
    local proteinsSum = 0;
    local caloriesSum = 0;
    local weightSum = 0;
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
            hungerSum = hungerSum + item:getBaseHunger();
            hungerChangeSum = hungerChangeSum + item:getHungChange();
            thirstSum = thirstSum;
            unhappySum = unhappySum + item:getUnhappyChangeUnmodified();
            carbsSum = carbsSum + item:getCarbohydrates();
            lipidsSum = lipidsSum + item:getLipids();
            proteinsSum = proteinsSum + item:getProteins();
            caloriesSum = caloriesSum + item:getCalories();
            weightSum = weightSum + item:getWeight()
            if item:getType() == "farming.Potato" then --gives the player a potato peel
            character:getInventory():AddItem("SapphCooking.PotatoPeel")
            end
        end
    end
    for j=0,results:size() - 1 do
        local result = results:get(j)
            if instanceof(result, "Food") then
                result:setBaseHunger(hungerSum / 2);
                result:setHungChange(hungerChangeSum / 2);
                result:setThirstChange(thirstSum / 2);
                result:setUnhappyChange(unhappySum / 2);
                result:setCarbohydrates(carbsSum / 2);
                result:setLipids(lipidsSum / 2);
                result:setProteins(proteinsSum / 2);
                result:setCalories((caloriesSum + 200) / 2);
                result:setCustomWeight(true);
                result:setActualWeight(weightSum / 2);
                result:setWeight(weightSum / 2);
                result:setCooked(true);
                result:setHeat(2.5);
                result:setAge(0);
            end
        end  
    --get the boredom/status of the player.
    --makes the player happy when cooking c:
    --[[
    local player = getPlayer();
    local stats = player:getStats();    
    local currentUnhappiness = stats:get(CharacterStat.UNHAPPINESS); 
    local currentBoredom = stats:get(CharacterStat.BOREDOM);  
    local currentStress = stats:get(CharacterStat.STRESS);
    player:set(CharacterStat.UNHAPPINESS, currentUnhappiness - 4); 
    player:set(CharacterStat.BOREDOM, currentBoredom - 4); 
    player:set(CharacterStat.STRESS, currentStress - .1);
    HaloTextHelper.addTextWithArrow(character, getText("IGUI_HaloNote_Stress"), false, HaloTextHelper.getColorGreen());
    ]]--  
    
end


function SapphMake2Result(craftRecipeData, character)
	local items = craftRecipeData:getAllConsumedItems();
	local results = craftRecipeData:getAllCreatedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
            for j=0,results:size() - 1 do
                local result = results:get(j)
                if instanceof(result, "Food") then
                    result:setBaseHunger(item:getBaseHunger() / 2);
                    result:setHungChange(item:getBaseHunger() / 2);
                    result:setThirstChange(item:getThirstChangeUnmodified() / 2);
                    result:setBoredomChange(item:getBoredomChangeUnmodified() / 2);
                    result:setUnhappyChange(item:getUnhappyChangeUnmodified() / 2);
                    result:setCarbohydrates(item:getCarbohydrates() / 2);
                    result:setLipids(item:getLipids() / 2);
                    result:setProteins(item:getProteins() / 2);
                    result:setCalories(item:getCalories() / 2);
                    result:setCooked(item:isCooked())
                    result:setBurnt(item:isBurnt())
                    result:setCustomWeight(true);
                    result:setActualWeight(item:getWeight() / 2);
                    result:setWeight(item:getWeight() / 2);
                end
            end
        end
    end
    
end




--Divides into five
function SapphDivideIntoFive(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        for j=0,results:size() - 1 do
            local result = results:get(j)
            if instanceof(result, "Food") then
                result:setBaseHunger(item:getBaseHunger() / 5);
                result:setHungChange(item:getHungChange() / 5);
                result:setThirstChange(item:getThirstChangeUnmodified() / 5)
                result:setBoredomChange(item:getBoredomChangeUnmodified() / 5)
                result:setUnhappyChange(item:getUnhappyChangeUnmodified() / 5)
                result:setCalories(item:getCalories() / 5)
                result:setCarbohydrates(item:getCarbohydrates() / 5)
                result:setLipids(item:getLipids() / 5)
                result:setProteins(item:getProteins() / 5)
                result:setCustomWeight(true);
                result:setActualWeight(item:getWeight() / 5);
                result:setWeight(item:getWeight() / 5);
                result:setCooked(item:isCooked())
                result:setBurnt(item:isBurnt())
            end
        end
    end
    
end

--Divides into Six
function SapphDivideIntoSix(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        for j=0,results:size() - 1 do
            local result = results:get(j)
            if instanceof(result, "Food") then
            result:setBaseHunger(item:getBaseHunger() / 6);
            result:setHungChange(item:getHungChange() / 6);
            result:setThirstChange(item:getThirstChangeUnmodified() / 6)
            result:setBoredomChange(item:getBoredomChangeUnmodified() / 6)
            result:setUnhappyChange(item:getUnhappyChangeUnmodified() / 6)
            result:setCalories(item:getCalories() / 6)
            result:setCarbohydrates(item:getCarbohydrates() / 6)
            result:setLipids(item:getLipids() / 6)
            result:setProteins(item:getProteins() / 6)
            result:setCooked(item:isCooked())
            result:setBurnt(item:isBurnt())
            end
        end
    end
    
end

--Divides into eight, this is only a placeholder for a few recipes
function SapphDivideEight(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
			condition = item:getCondition()
			for j=0,results:size() - 1 do
				local result = results:get(j)
				if instanceof(result, "Food") then
					result:setBaseHunger(item:getBaseHunger() / 8);
                    result:setHungChange(item:getHungChange() / 8);
                    result:setThirstChange(item:getThirstChangeUnmodified() / 8)
                    result:setBoredomChange(item:getBoredomChangeUnmodified() / 8)
                    result:setUnhappyChange(item:getUnhappyChangeUnmodified() / 8)
                    result:setCalories(item:getCalories() / 8)
                    result:setCarbohydrates(item:getCarbohydrates() / 8)
                    result:setLipids(item:getLipids() / 8)
                    result:setProteins(item:getProteins() / 8)
                end
            end
        end
    end
    
end

--Divides into four, this is only a placeholder for the protein/powdered milk!
function SapphDivideFour(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
			condition = item:getCondition()
			for j=0,results:size() - 1 do
				local result = results:get(j)
				if instanceof(result, "Food") then
					result:setBaseHunger(item:getBaseHunger() / 4);
                    result:setHungChange(item:getHungChange() / 4);
                    result:setThirstChange(item:getThirstChangeUnmodified() / 4)
                    result:setBoredomChange(item:getBoredomChangeUnmodified() / 4)
                    result:setUnhappyChange(item:getUnhappyChangeUnmodified() / 4)
                    result:setCalories(item:getCalories() / 4)
                    result:setCarbohydrates(item:getCarbohydrates() / 4)
                    result:setLipids(item:getLipids() / 4)
                    result:setProteins(item:getProteins() / 4)
                end
            end
        end
    end
    
end

--divides into 3, but cooked!
function SapphDivideThreeCooked(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
			condition = item:getCondition()
			for j=0,results:size() - 1 do
				local result = results:get(j)
				if instanceof(result, "Food") then
					result:setBaseHunger(item:getBaseHunger() / 3);
                    result:setHungChange(item:getHungChange() / 3);
                    result:setThirstChange(item:getThirstChangeUnmodified() / 3)
                    result:setBoredomChange(item:getBoredomChangeUnmodified() / 3)
                    result:setUnhappyChange(item:getUnhappyChangeUnmodified() / 3)
                    result:setCalories(item:getCalories() / 3)
                    result:setCarbohydrates(item:getCarbohydrates() / 3)
                    result:setLipids(item:getLipids() / 3)
                    result:setProteins(item:getProteins() / 3)
                    result:setCooked(true)
                end
            end
        end
    end
    
end

--divides into 4, but cooked!
function SapphDivideFourCooked(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
			condition = item:getCondition()
			for j=0,results:size() - 1 do
				local result = results:get(j)
				if instanceof(result, "Food") then
					result:setBaseHunger(item:getBaseHunger() / 4);
                    result:setHungChange(item:getHungChange() / 4);
                    result:setThirstChange(item:getThirstChangeUnmodified() / 4)
                    result:setBoredomChange(item:getBoredomChangeUnmodified() / 4)
                    result:setUnhappyChange(item:getUnhappyChangeUnmodified() / 4)
                    result:setCalories(item:getCalories() / 4)
                    result:setCarbohydrates(item:getCarbohydrates() / 4)
                    result:setLipids(item:getLipids() / 4)
                    result:setProteins(item:getProteins() / 4)
                    result:setCooked(true)
                end
            end
        end
    end
    
end

--divides into 3
function SapphDivideThree(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
			condition = item:getCondition()
			for j=0,results:size() - 1 do
				local result = results:get(j)
				if instanceof(result, "Food") then
					result:setBaseHunger(item:getBaseHunger() / 3);
                    result:setHungChange(item:getHungChange() / 3);
                    result:setThirstChange(item:getThirstChangeUnmodified() / 3)
                    result:setBoredomChange(item:getBoredomChangeUnmodified() / 3)
                    result:setUnhappyChange(item:getUnhappyChangeUnmodified() / 3)
                    result:setCalories(item:getCalories() / 3)
                    result:setCarbohydrates(item:getCarbohydrates() / 3)
                    result:setLipids(item:getLipids() / 3)
                    result:setProteins(item:getProteins() / 3)
                end
            end
        end
    end
    
end
--]]
function SapphCottonCandy(craftRecipeData, character)

    Results={ "SapphCooking.CottonCandy_White", 
"SapphCooking.CottonCandy_Pink", 
"SapphCooking.CottonCandy_Blue",
"SapphCooking.CottonCandy_Purple",
"SapphCooking.CottonCandy_Green",
"SapphCooking.CottonCandy_Red",
"SapphCooking.CottonCandy_Yellow",
"SapphCooking.CottonCandy_Orange", }
    local result = (Results[ZombRand(1, #Results+1)]);
	character:getInventory():AddItem(result)
    sendAddItemToContainer(character:getInventory(), result)
end


--cakes~
function SapphCakeAddCandle(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    local hungerSum = 0;
    local hungerChangeSum = 0;
    local thirstSum = 0;
    local unhappySum = 0.3; --adds a bit of happiness
    local carbsSum = 0;
    local lipidsSum = 0;
    local proteinsSum = 0;
    local caloriesSum = 0;
    local weightSum = 0;
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "Food") then
            hungerSum = hungerSum + item:getBaseHunger();
            hungerChangeSum = hungerChangeSum + item:getHungChange();
            thirstSum = thirstSum;
            unhappySum = unhappySum + item:getUnhappyChangeUnmodified();
            carbsSum = carbsSum + item:getCarbohydrates();
            lipidsSum = lipidsSum + item:getLipids();
            proteinsSum = proteinsSum + item:getProteins();
            caloriesSum = caloriesSum + item:getCalories();
            weightSum = weightSum + item:getWeight();
        end

        for j=0,results:size() - 1 do
        local result = results:get(j)
            if instanceof(result, "Food") then
                result:setBaseHunger(hungerSum);
                result:setHungChange(hungerChangeSum);
                result:setThirstChange(thirstSum);
                result:setUnhappyChange(unhappySum);
                result:setCarbohydrates(carbsSum);
                result:setLipids(lipidsSum);
                result:setProteins(proteinsSum);
                result:setCalories(caloriesSum);
                result:setCooked(true);
                if character:getPrimaryHandItem() == character:getSecondaryHandItem() then
                    character:setPrimaryHandItem(nil)
                end
                character:setSecondaryHandItem(result);
            end
        end
    end
end

function SapphCakeRemoveCandle(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();

    local candle = instanceItem("SapphCooking.HalfCandle")
    character:getInventory():AddItem(candle)
    sendAddItemToContainer(character:getInventory(), candle)

    --makes the player happy
    local player = getPlayer();
    local stats = player:getStats();   
    --sets unhappiness/boredom/stress to 0!
    stats:set(CharacterStat.UNHAPPINESS, 0);
    stats:set(CharacterStat.BOREDOM, 0);
    stats:set(CharacterStat.STRESS, 0);
    HaloTextHelper.addTextWithArrow(character, getText("IGUI_HaloNote_Stress"), false, HaloTextHelper.getColorGreen());
    
    --[[
    local currentUnhappiness = stats:get(CharacterStat.UNHAPPINESS); 
    local currentBoredom = stats:get(CharacterStat.BOREDOM);  
    local currentStress = stats:get(CharacterStat.STRESS);
    
    player:set(CharacterStat.BOREDOM, currentBoredom - 4); 
    player:set(CharacterStat.STRESS, currentStress - .1);
    ]]--  
end

function SapphBirthdayCake(items, result, player)
    for i=0,items:size() - 1 do
        local item = items:get(i)
	    if instanceof(result, "Food") then
            result:setBaseHunger(item:getBaseHunger());
            result:setHungChange(item:getHungChange());
            result:setThirstChange(item:getThirstChangeUnmodified());
            result:setBoredomChange(item:getBoredomChangeUnmodified());
            result:setUnhappyChange(item:getUnhappyChangeUnmodified());
            result:setCarbohydrates(item:getCarbohydrates());
            result:setLipids(item:getLipids());
            result:setProteins(item:getProteins());
            result:setCalories(item:getCalories() + 30);
            result:setWeight(item:getWeight());
            result:setCooked(true);
        end
    end
    
end

--sapph: this deletes fluid containers manually -for some reason they arent being consumed by "mode:destroy"
function SapphDeleteFluidComponent(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "InventoryItem") and item:hasComponent(ComponentType.FluidContainer) then
            character:getInventory():Remove(item)
        end
    end
end

-- sapph: for prep recipes, it checks for every food item values in the recipe, then adds it on the result.
function SapphCreatePrep(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    local hungerSum = 0;
    local hungerChangeSum = 0;
    local thirstSum = 0;
    local unhappySum = 0.3; --adds a bit of happiness
    local carbsSum = 0;
    local lipidsSum = 0;
    local proteinsSum = 0;
    local caloriesSum = 70; --adds calories, so recipes are more worth!
    local weightSum = 0;
    for i=0,items:size() - 1 do
        local item = items:get(i)
        --deletes fluid containers manually - cause they are not yet being consumed by "mode:destroy"
        --sapph(01/28): this was supposed to be fixed - but i guess it's not, so it's going back in!
        if item:hasComponent(ComponentType.FluidContainer) then
            character:getInventory():Remove(item)
        end
        if instanceof(item, "Food") then
            hungerSum = hungerSum + item:getBaseHunger();
            hungerChangeSum = hungerChangeSum + item:getHungChange();
            thirstSum = thirstSum;
            -- quick fix to unhappyness on recipes!
            if item:getType() == "Butter" or item:getType() == "Pasta" or item:getType() == "MacandcheesePowder" then
                unhappySum = unhappySum - item:getUnhappyChangeUnmodified();
            end
            unhappySum = unhappySum + item:getUnhappyChangeUnmodified();
            carbsSum = carbsSum + item:getCarbohydrates();
            lipidsSum = lipidsSum + item:getLipids();
            proteinsSum = proteinsSum + item:getProteins();
            caloriesSum = caloriesSum + item:getCalories();
            weightSum = weightSum + item:getWeight();
            
        end
    end
    for j=0,results:size() - 1 do
        local result = results:get(j)
            if instanceof(result, "Food") then
            result:setBaseHunger(hungerSum);
            result:setHungChange(hungerChangeSum);
            result:setThirstChange(thirstSum);
            result:setUnhappyChange(unhappySum);
            result:setCarbohydrates(carbsSum);
            result:setLipids(lipidsSum);
            result:setProteins(proteinsSum);
            result:setCalories(caloriesSum);
            result:setAge(0);
        end
    end
    
end

--For cooked prep

function SapphCreatePrepCooked(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    local hungerSum = 0;
    local hungerChangeSum = 0;
    local thirstSum = 0;
    local unhappySum = 0.3; --adds a bit of happiness
    local carbsSum = 0;
    local lipidsSum = 0;
    local proteinsSum = 0;
    local caloriesSum = 70; --adds calories, so recipes are more worth!
    local weightSum = 0;
    for i=0,items:size() - 1 do
        local item = items:get(i)
        --deletes fluid containers manually - cause they are not yet being consumed by "mode:destroy"
        --sapph(01/28): this was supposed to be fixed - but i guess it's not, so it's going back in!
        if item:hasComponent(ComponentType.FluidContainer) then
            character:getInventory():Remove(item)
        end
        if instanceof(item, "Food") then
            hungerSum = hungerSum + item:getBaseHunger();
            hungerChangeSum = hungerChangeSum + item:getHungChange();
            thirstSum = thirstSum;
            -- quick fix to unhappyness on recipes!
            if item:getType() == "Butter" or item:getType() == "Pasta" or item:getType() == "MacandcheesePowder" then
                unhappySum = unhappySum - item:getUnhappyChangeUnmodified();
            end
            unhappySum = unhappySum + item:getUnhappyChangeUnmodified();
            carbsSum = carbsSum + item:getCarbohydrates();
            lipidsSum = lipidsSum + item:getLipids();
            proteinsSum = proteinsSum + item:getProteins();
            caloriesSum = caloriesSum + item:getCalories();
            weightSum = weightSum + item:getWeight();
            
        end
    end
    for j=0,results:size() - 1 do
        local result = results:get(j)
            if instanceof(result, "Food") then
            result:setBaseHunger(hungerSum);
            result:setHungChange(hungerChangeSum);
            result:setThirstChange(thirstSum);
            result:setUnhappyChange(unhappySum);
            result:setCarbohydrates(carbsSum);
            result:setLipids(lipidsSum);
            result:setProteins(proteinsSum);
            result:setCalories(caloriesSum);
            result:setCooked(true);
            result:setHeat(2.5);
            result:setAge(0);
        end
    end
    
end



function SapphCreatePrepThree(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    local hungerSum = 0;
    local hungerChangeSum = 0;
    local thirstSum = 0;
    local unhappySum = 0.3; --adds a bit of happiness
    local carbsSum = 0;
    local lipidsSum = 0;
    local proteinsSum = 0;
    local caloriesSum = 55; --adds calories, so recipes are more worth!
    local weightSum = 0;
    for i=0,items:size() - 1 do
        local item = items:get(i)
        --deletes fluid containers manually - cause they are not yet being consumed by "mode:destroy"
        if instanceof(item, "InventoryItem") and item:hasComponent(ComponentType.FluidContainer) then
            character:getInventory():Remove(item)
        end
        if instanceof(item, "Food") then
            hungerSum = hungerSum + item:getBaseHunger();
            hungerChangeSum = hungerChangeSum + item:getHungChange();
            thirstSum = thirstSum;
            unhappySum = unhappySum + item:getUnhappyChangeUnmodified();
            carbsSum = carbsSum + item:getCarbohydrates();
            lipidsSum = lipidsSum + item:getLipids();
            proteinsSum = proteinsSum + item:getProteins();
            caloriesSum = caloriesSum + item:getCalories();
            weightSum = weightSum + item:getWeight();
        end
    end
    for j=0,results:size() - 1 do
        local result = results:get(j)
            if instanceof(result, "Food") then
            result:setBaseHunger(hungerSum / 3);
            result:setHungChange(hungerChangeSum / 3);
            result:setThirstChange(thirstSum / 3);
            result:setUnhappyChange(unhappySum / 3);
            result:setCarbohydrates(carbsSum / 3);
            result:setLipids(lipidsSum / 3);
            result:setProteins(proteinsSum / 3);
            result:setCalories(caloriesSum / 3);
            result:setCustomWeight(true);
            result:setActualWeight(weightSum / 3);
            result:setWeight(weightSum / 3);
            result:setAge(0);
        end
    end
    
end


--this checks if the power is on.
local function CheckPoweredSquare(square)
	return (SandboxVars.AllowExteriorGenerator and square:haveElectricity() or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier))
end

function HotCoffeeFluidContainer(item)
    if instanceof(item, "InventoryItem") and item:hasComponent(ComponentType.FluidContainer) and not item:getFluidContainer():isEmpty() then
        return item:getItemHeat() > 1.4;
    end
	return true;
end

function IsHotPan(item)
    if item and instanceof(item, "InventoryItem") and item:hasComponent(ComponentType.FluidContainer) then
        if item.getItemHeat ~= nil then
            local temp = item:getItemHeat()
            --print("Item: " .. tostring(item:getType()) .. " Temperature: " .. tostring(temp))
            return temp > 1.1
        end
    end
	return true; -- non - fluid containers can return true.
end

    --sapph: this code checks for the temperature of water!
    --this is used for ice cubes! 
function SapphCheckCold(item)
	if item and instanceof(item, "InventoryItem") and item:hasComponent(ComponentType.FluidContainer) and not item:getFluidContainer():isEmpty() then
        if item.getItemHeat ~= nil then
            local temp = item:getItemHeat()
            return temp < 0.6
        end
    end
	return false;
end

--sapph: this code is used to convert custom bottles into vanilla bottles, making them empty after the oncreate is called.
function SapphOnCleanBottle(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    for j=0,results:size() - 1 do
        local result = results:get(j)
        if result:hasComponent(ComponentType.FluidContainer) then
            result:getFluidContainer():removeFluid()
        end
    end
end