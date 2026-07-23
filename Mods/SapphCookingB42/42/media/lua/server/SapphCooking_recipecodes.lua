
--sapph: hi! b42 got released, so most of the stuff here is going to be gone or tweaked!

--     item:setWorldStaticModel("")
--     item:setStaticModel("")

require "recipecode"

--MRE opening spawns.
--You can get two varieties of items.
--OPTION 1 MRE
function recipe_MREopen1(craftRecipeData, character)
    character:getInventory():AddItem("Base.SugarPacket");
    character:getInventory():AddItem("Base.Teabag");
    character:getInventory():AddItem("Base.Matches");
    character:getInventory():AddItem("Base.Crackers");
    character:getInventory():AddItem("Base.Gum");
    character:getInventory():AddItem("SapphCooking.SaltPacket");
    character:getInventory():AddItem("SapphCooking.Mouth_Toothpick");
    character:getInventory():AddItem("SapphCooking.Drinkmix_Lemon");
    character:getInventory():AddItem("SapphCooking.PlasticSpork");
    character:getInventory():AddItem("SapphCooking.Mustard_Sachet");
    character:getInventory():AddItem("SapphCooking.PeanutButter_Sachet");
    character:getInventory():AddItem("SapphCooking.Tomato_Sachet");
    character:getInventory():AddItem("SapphCooking.HotsaucePacket");
    character:getInventory():AddItem("SapphCooking.MRE_FlamelessRationHeater");
end
--OPTION 2 MRE
function recipe_MREopen2(craftRecipeData, character)
    character:getInventory():AddItem("Base.SugarPacket");
    character:getInventory():AddItem("SapphCooking.CoffeePacket");
    character:getInventory():AddItem("Base.Matches");
    character:getInventory():AddItem("Base.GrahamCrackers");
    character:getInventory():AddItem("Base.Gum");
    character:getInventory():AddItem("Base.MintCandy");
    character:getInventory():AddItem("SapphCooking.SaltPacket");
    character:getInventory():AddItem("SapphCooking.Mouth_Toothpick");
    character:getInventory():AddItem("SapphCooking.Drinkmix_Orange");
    character:getInventory():AddItem("SapphCooking.PlasticSpork");
    character:getInventory():AddItem("SapphCooking.Mustard_Sachet");
    character:getInventory():AddItem("SapphCooking.PeanutButter_Sachet");
    character:getInventory():AddItem("SapphCooking.Tomato_Sachet");
    character:getInventory():AddItem("SapphCooking.HotsaucePacket");
    character:getInventory():AddItem("SapphCooking.MRE_FlamelessRationHeater");
end

	
--Tag Recipes
--for recipes with bacon and eggs pans
 function Recipe.GetItemTypes.SapphCookingBaconEggsPan(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("BaconEggsPan"));
 end
 
function Recipe.GetItemTypes.SapphCookingFalafel(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingFalafel"));
    scriptItems:addAll(getScriptManager():getItemsTag("Peas"));
    scriptItems:addAll(getScriptManager():getItemsTag("Beans"));
 end

 function Recipe.GetItemTypes.SapphCookingMushroom(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("Mushroom"));
    scriptItems:addAll(getScriptManager():getItemsTag("Mushrooms"));
 end

 function Recipe.GetItemTypes.SapphCookingBread(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingBread"));
    scriptItems:addAll(getScriptManager():getItemsTag("Bread"));
 end

 function Recipe.GetItemTypes.SapphCookingKnifes(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingKnife"));
    scriptItems:addAll(getScriptManager():getItemsTag("SharpKnife"));
    scriptItems:addAll(getScriptManager():getItemsTag("DullKnife"));
 end

 function Recipe.GetItemTypes.SapphCookingTomatoSauce(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingKetchup"));
    scriptItems:addAll(getScriptManager():getItemsTag("Ketchup"));
    scriptItems:addAll(getScriptManager():getItemsTag("TomatoKetchup"));
 end

 function Recipe.GetItemTypes.SapphCookingMincedMeat(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingMincedMeat"));
    scriptItems:addAll(getScriptManager():getItemsTag("MincedMeat"));
 end

 function Recipe.GetItemTypes.SapphCookingBroth(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingBroth"));
    scriptItems:addAll(getScriptManager():getItemsTag("Broth"));
 end

 function Recipe.GetItemTypes.SapphCookingMinceMeat(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingMinceMeat"));
    scriptItems:addAll(getScriptManager():getItemsTag("MinceMeat"));
 end

 function Recipe.GetItemTypes.SapphCookingThermos(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingThermos"));
    scriptItems:addAll(getScriptManager():getItemsTag("Thermos"));
 end

function Recipe.GetItemTypes.SapphCookingRice(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingRice"));
	scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingRiceBowl"));
	scriptItems:addAll(getScriptManager():getItemsTag("CookedRice"));
end

function Recipe.GetItemTypes.SapphCookingCarrots(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("Carrots"));
	scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingCarrot"));
    scriptItems:addAll(getScriptManager():getItemsTag("CannedCarrots"));
	scriptItems:addAll(getScriptManager():getItemsTag("Carrot"));
end

function Recipe.GetItemTypes.SapphCookingPotatoes(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("Potatoes"));
	scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingPotato"));
    scriptItems:addAll(getScriptManager():getItemsTag("CannedPotatoes"));
	scriptItems:addAll(getScriptManager():getItemsTag("Potato"));
end

function Recipe.GetItemTypes.SapphCookingSoysauce(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingSoysauce"));
	scriptItems:addAll(getScriptManager():getItemsTag("Soysauce"));
end

function Recipe.GetItemTypes.SapphCookingCitrus(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingCitrus"));
	scriptItems:addAll(getScriptManager():getItemsTag("Citrus"));
end

	function Recipe.GetItemTypes.SapphCookingRiceBowl(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingRiceBowl"));
	scriptItems:addAll(getScriptManager():getItemsTag("RiceBowl"));
end

function Recipe.GetItemTypes.SapphCookingEgg(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingEgg"));
	scriptItems:addAll(getScriptManager():getItemsTag("Egg"));
end

function Recipe.GetItemTypes.SapphCookingCheese(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingCheese"));
	scriptItems:addAll(getScriptManager():getItemsTag("Cheese"));
	scriptItems:addAll(getScriptManager():getItemsTag("Cheeses"));
end

function Recipe.GetItemTypes.SapphCookingMilk(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingMilk"));
	scriptItems:addAll(getScriptManager():getItemsTag("Milk"));
end

function Recipe.GetItemTypes.SapphCookingSausages(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingSausages"));
	scriptItems:addAll(getScriptManager():getItemsTag("Sausages"));
	scriptItems:addAll(getScriptManager():getItemsTag("Sausage"));
end

function Recipe.GetItemTypes.SapphCookingChicken(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingChicken"));
	scriptItems:addAll(getScriptManager():getItemsTag("Chicken"));
end

function Recipe.GetItemTypes.SapphCookingFriedChickenRecipe(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingFriedChicken"));
	scriptItems:addAll(getScriptManager():getItemsTag("FriedChickenRecipe"));
end

function Recipe.GetItemTypes.SapphCookingSugar(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingSugar"));
	scriptItems:addAll(getScriptManager():getItemsTag("Sugar"));
end

function Recipe.GetItemTypes.SapphCookingBerry(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingBerry"));
	scriptItems:addAll(getScriptManager():getItemsTag("Berries"));
    scriptItems:addAll(getScriptManager():getItemsTag("Berry"));
end


function Recipe.GetItemTypes.SapphCookingPepper(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingPepper"));
	scriptItems:addAll(getScriptManager():getItemsTag("Pepper"));
end

function Recipe.GetItemTypes.SapphCookingSalt(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingSalt"));
	scriptItems:addAll(getScriptManager():getItemsTag("Salt"));
end

function Recipe.GetItemTypes.SapphCookingPasta(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingPasta"));
	scriptItems:addAll(getScriptManager():getItemsTag("Pasta"));
end

function Recipe.GetItemTypes.SapphCookingSyrup(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingSyrup"));
	scriptItems:addAll(getScriptManager():getItemsTag("Syrup"));
    scriptItems:addAll(getScriptManager():getItemsTag("Syrups"));
end

function Recipe.GetItemTypes.SapphCookingBeets(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("Beet"));
	scriptItems:addAll(getScriptManager():getItemsTag("Beets"));
end

function Recipe.GetItemTypes.SapphCookingSliced(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingSlicedVegetables"));
	scriptItems:addAll(getScriptManager():getItemsTag("SlicedVegetables"));
end

function Recipe.GetItemTypes.SapphCookingCoffeeCup(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("CoffeeCup"));
end

function Recipe.GetItemTypes.SapphCookingMeltedChocolate(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("MeltedChocolate"));
	scriptItems:addAll(getScriptManager():getItemsTag("SapphCookingMeltedChocolate"));
end

function Recipe.GetItemTypes.SapphCookingIcing(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("Icing"));
end

function Recipe.GetItemTypes.SapphCookingChocolate(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("Chocolate"));
end

function Recipe.GetItemTypes.SapphCookingCakes(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("isCake"));
end

function Recipe.GetItemTypes.SapphCookingPastryCream(scriptItems)
    scriptItems:addAll(getScriptManager():getItemsTag("PastryCream"));
    scriptItems:addAll(getScriptManager():getItemsTag("Custard"));
end


function Recipe.OnCreate.SapphAutoCook(craftRecipeData, character) -- auto cooks foods, and reduces boredom/stress.
    --sums all of the consumed items into the result.
    --then sets the result to cooked, and hot.
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
    local body = character:getBodyDamage(); 
    local stats = character:getStats();    
    local currentUnhappiness = body:getUnhappynessLevel(); 
    local currentBoredom = body:getBoredomLevel();  
    local currentStress = stats:getStress();
    body:setBoredomLevel(currentBoredom - 4); 
    body:setUnhappynessLevel(currentUnhappiness - 4); 
    stats:setStress(currentStress - .1);
end


--sapph: still need to learn the new fluid system, should be better to wait until it is actually out

--[[
    --for i=0,items:size() - 1 do
    --    local item = items:get(i)
    --    if item:getType() == "EmptyThermos" then
    --        local result = character:getInventory():AddItem("SapphCooking.EmptyThermos")
    --        result:getFluidContainer():addFluid("BrewedCoffee", 1.0)
    --    end
    --   if item:getType() == "Mug_Metal" then
    --        local result = character:getInventory():AddItem("SapphCooking.Mug_Metal")
    --        result:getFluidContainer():addFluid("BrewedCoffee", 0.2)
    --    end
    --end  
    --]]

function Recipe.OnCreate.SapphBrewCoffee(craftRecipeData, character) 
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
    local body = character:getBodyDamage(); 
    local stats = character:getStats();    
    local currentUnhappiness = body:getUnhappynessLevel(); 
    local currentBoredom = body:getBoredomLevel();  
    local currentStress = stats:getStress();
    body:setBoredomLevel(currentBoredom - 4); 
    body:setUnhappynessLevel(currentUnhappiness - 4); 
    stats:setStress(currentStress - .1);
    HaloTextHelper.addTextWithArrow(character, getText("IGUI_HaloNote_Stress"), false, HaloTextHelper.getColorGreen());

end


function Recipe.OnTest.HotCoffeeFluidContainer(item)
    if instanceof(item, "InventoryItem") and item:hasComponent(ComponentType.FluidContainer) and not item:getFluidContainer():isEmpty() then
        return item:getItemHeat() > 1.6;
    end
	return true;
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

function LightCandle_OnCreate(craftRecipeData, character)
	local items = craftRecipeData:getAllConsumedItems();
	local result = craftRecipeData:getAllCreatedItems():get(0);
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if item:getType() == "HalfCandle" then
            result:setUsedDelta(item:getCurrentUsesFloat());
            result:setCondition(item:getCondition());
            result:setFavorite(item:isFavorite());
            if character:getPrimaryHandItem() == character:getSecondaryHandItem() then
                character:setPrimaryHandItem(nil)
            end
            character:setSecondaryHandItem(result);
            result:setActivated(true); --ensure the candle emits light upon creation
        end
    end
end

function ExtinguishCandle_OnCreate(craftRecipeData, character)
	local items = craftRecipeData:getAllConsumedItems();
	local result = craftRecipeData:getAllCreatedItems():get(0);
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if item:getType() == "HalfCandleLit" then
            result:setUsedDelta(item:getCurrentUsesFloat());
            result:setCondition(item:getCondition());
            result:setFavorite(item:isFavorite());
        end
    end
end


function Recipe.OnCreate.FryingCooking(craftRecipeData, character)
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
local body = character:getBodyDamage(); 
local stats = character:getStats();    
local currentUnhappiness = body:getUnhappynessLevel(); 
local currentBoredom = body:getBoredomLevel();  
local currentStress = stats:getStress();
body:setBoredomLevel(currentBoredom - 4); 
body:setUnhappynessLevel(currentUnhappiness - 4); 
stats:setStress(currentStress - .1);
HaloTextHelper.addTextWithArrow(character, getText("IGUI_HaloNote_Stress"), false, HaloTextHelper.getColorGreen());
end


function Recipe.OnCreate.FryingCookingTwoResult(craftRecipeData, character)
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
    local body = character:getBodyDamage(); 
    local stats = character:getStats();    
    local currentUnhappiness = body:getUnhappynessLevel(); 
    local currentBoredom = body:getBoredomLevel();  
    local currentStress = stats:getStress();
    body:setBoredomLevel(currentBoredom - 4); 
    body:setUnhappynessLevel(currentUnhappiness - 4); 
    stats:setStress(currentStress - .1);
    HaloTextHelper.addTextWithArrow(character, getText("IGUI_HaloNote_Stress"), false, HaloTextHelper.getColorGreen());
end


function Recipe.OnCreate.SapphMake2Result(craftRecipeData, character)
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
function Recipe.OnCreate.SapphDivideIntoFive(craftRecipeData, character)
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
function Recipe.OnCreate.SapphDivideIntoSix(craftRecipeData, character)
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
function Recipe.OnCreate.SapphDivideEight(craftRecipeData, character)
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
function Recipe.OnCreate.SapphDivideFour(craftRecipeData, character)
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
function Recipe.OnCreate.SapphDivideThreeCooked(craftRecipeData, character)
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
function Recipe.OnCreate.SapphDivideFourCooked(craftRecipeData, character)
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
function Recipe.OnCreate.SapphDivideThree(craftRecipeData, character)
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

function Recipe.OnCreate.SapphCottonCandy(craftRecipeData, character)

    Results={ "SapphCooking.CottonCandy_White", 
"SapphCooking.CottonCandy_Pink", 
"SapphCooking.CottonCandy_Blue",
"SapphCooking.CottonCandy_Purple",
"SapphCooking.CottonCandy_Green",
"SapphCooking.CottonCandy_Red",
"SapphCooking.CottonCandy_Yellow",
"SapphCooking.CottonCandy_Orange", }
    local inv = character:getInventory();
	inv:AddItem(Results[ZombRand(1, #Results+1)], 1)
end

--cakes~
function Recipe.OnCreate.SapphCakeAddCandle(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if item:getType() == "CakeRaw" or item:getType() == "CakeRaw_Chocolate" or item:getType() == "CakeRaw_BlackForestCake" or item:getType() == "CakeRaw_Carrot" or item:getType() == "CakeRaw_Strawberry" or item:getType() == "CakeRaw_RedVelvet" or item:getType() == "CakeRaw_Birthday" or item:getType() == "CakePrep_Chocolate" or item:getType() == "CakePrep_Carrot" or item:getType() == "CakePrep_Strawberry" or item:getType() == "CakePrep_BlackForest" or item:getType() == "CakePrep_Birthday" or item:getType() == "CakePrep_RedVelvet" then
            for j=0,results:size() - 1 do
				local result = results:get(j)
                result:setBaseHunger(item:getBaseHunger());
                result:setHungChange(item:getHungChange());
                result:setThirstChange(item:getThirstChangeUnmodified());
                result:setBoredomChange(item:getBoredomChangeUnmodified());
                result:setUnhappyChange(item:getUnhappyChangeUnmodified());
                result:setCarbohydrates(item:getCarbohydrates());
                result:setLipids(item:getLipids());
                result:setProteins(item:getProteins());
                result:setCalories(item:getCalories());
                result:setWeight(item:getWeight());
                result:setCooked(item:isCooked());
                if character:getPrimaryHandItem() == character:getSecondaryHandItem() then
                    character:setPrimaryHandItem(nil)
                end
                character:setSecondaryHandItem(result);
            end
        end
    end
end

function Recipe.OnCreate.SapphCakeRemoveCandle(craftRecipeData, character)
    local results = craftRecipeData:getAllCreatedItems();
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if item:getType() == "Cake_Candle" or item:getType() == "CakeChocolate_Candle" or item:getType() == "CakeBlackForest_Candle" or item:getType() == "CakeCarrot_Candle" or item:getType() == "CakeStrawberry_Candle" or item:getType() == "CakeRedVelvet_Candle" or item:getType() == "CakeBirthday_Candle" then 
            for j=0,results:size() - 1 do
				local result = results:get(j)
                result:setBaseHunger(item:getBaseHunger());result:setBaseHunger(item:getBaseHunger());
                result:setHungChange(item:getHungChange());
                result:setThirstChange(item:getThirstChangeUnmodified());
                result:setBoredomChange(item:getBoredomChangeUnmodified());
                result:setUnhappyChange(item:getUnhappyChangeUnmodified());
                result:setCarbohydrates(item:getCarbohydrates());
                result:setLipids(item:getLipids());
                result:setProteins(item:getProteins());
                result:setCalories(item:getCalories());
                result:setWeight(item:getWeight());
                result:setCooked(true);
            end
        end
    end
    --adds a half used candle, so you can't farm wishes~
    local inv = character:getInventory();
	inv:AddItem("SapphCooking.HalfCandle");
    --get the boredom/status of the player.
    --makes the player happy when cooking c:
    local body = character:getBodyDamage(); 
    local stats = character:getStats();    
    local currentUnhappiness = body:getUnhappynessLevel(); 
    local currentBoredom = body:getBoredomLevel();  
    local currentStress = stats:getStress();
    body:setBoredomLevel(currentBoredom - 30); 
    body:setUnhappynessLevel(currentUnhappiness - 30); 
    stats:setStress(currentStress - 10);
    HaloTextHelper.addTextWithArrow(character, getText("IGUI_HaloNote_Stress"), false, HaloTextHelper.getColorGreen());
end

function Recipe.OnCreate.SapphBirthdayCake(items, result, player)
    for i=0,items:size() - 1 do
        local item = items:get(i)
	    if item:getTags():contains("isCake") then 
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
function Recipe.OnCreate.SapphDeleteFluidComponent(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems();
    for i=0,items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "InventoryItem") and item:hasComponent(ComponentType.FluidContainer) then
            character:getInventory():Remove(item)
        end
    end
end

-- sapph: for prep recipes, it checks for every food item values in the recipe, then adds it on the result.
function Recipe.OnCreate.SapphCreatePrep(craftRecipeData, character)
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



function Recipe.OnCreate.SapphCreatePrepThree(craftRecipeData, character)
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
    --checks if its cold
function Recipe.OnTest.SapphCheckCold(item)
	if instanceof(item, "InventoryItem") and item:hasComponent(ComponentType.FluidContainer) then
		return item:getItemHeat() < 0.5;
	end
	return true;
end


function Recipe.OnCreate.PopscicleCreate(craftRecipeData, character)

    Colors={ "SapphCooking.Popsicle_White", 
    "SapphCooking.Popsicle_Pink", 
    "SapphCooking.Popsicle_Blue",
    "SapphCooking.Popsicle_Purple",
    "SapphCooking.Popsicle_Green",
    "SapphCooking.Popsicle_Red",
    "SapphCooking.Popsicle_Orange",
    "SapphCooking.Popsicle_Yellow", }

    local inv = character:getInventory();
	inv:AddItem(Colors[ZombRand(1, #Colors+1)], 1)
end
