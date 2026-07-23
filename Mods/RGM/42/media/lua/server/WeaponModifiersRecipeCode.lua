
-- B42: Recipe global table may not be pre-defined by the engine
Recipe = Recipe or {}
Recipe.OnCreate = Recipe.OnCreate or {}

RGMManager = RGMManager or {}
if RGMManager.RecipeCodeLoaded then return end
RGMManager.RecipeCodeLoaded = true

local function getItemList(items)
    -- B42 compatibility: items may be CraftRecipeData or plain ArrayList
    if items and type(items.getAllUsedItems) == "function" then
        return items:getAllUsedItems()
    end
    return items
end

function Recipe.OnCreate.UpgradeSpear(items, result, player)
    local itemList = getItemList(items)
    local conditionMax = 0;
    for i=0,itemList:size() - 1 do
        local item = itemList:get(i)
        if item and item:getModData().modifier then
            if item:getType() == "SpearCrafted" then
                conditionMax = item:getCondition()
                if item:getModData().modifier then
                    result:getModData().spearModifier = item:getModData().modifier
                end
            elseif instanceof(item, "HandWeapon") then
                conditionMax = conditionMax - ((item:getConditionMax() - item:getCondition())/2)
                if item:getModData().modifier then
                    result:getModData().bladeModifier = item:getModData().modifier
                end
            end
        end
    end

    if conditionMax > result:getConditionMax() then
        conditionMax = result:getConditionMax();
    end
    if conditionMax < 2 then
        conditionMax = 2;
    end

    result:setCondition(conditionMax);

    local finalMod = result:getModData().bladeModifier or result:getModData().spearModifier
    if finalMod then
        result:getModData().modifier = finalMod
        result:getModData().modifierChecked = true
        pcall(function() RGMManager.applyModifierStatsToItem(result, finalMod) end)
        if type(result.transmitModData) == "function" then result:transmitModData() end
        RGMManager.notifyPlayerModifierAssigned(player, result, finalMod)
    end
end

function Recipe.OnCreate.DismantleSpear(items, result, player)
    local itemList = getItemList(items)

    -- B42: no selectedItem param — find the spear in item list
    local selectedItem = nil
    for i=0,itemList:size()-1 do
        local it = itemList:get(i)
        if it and instanceof(it, "HandWeapon") then
            selectedItem = it
            break
        end
    end
    if not selectedItem then return end

    local conditionMax = selectedItem:getCondition();
    if conditionMax > selectedItem:getConditionMax() then
        conditionMax = selectedItem:getConditionMax();
    end
    if conditionMax < 2 then
        conditionMax = 2;
    end
    local spear = player:getInventory():AddItem("Base.SpearCrafted");
    if spear then
        spear:setCondition(conditionMax)
        local spearMod = selectedItem:getModData().spearModifier or selectedItem:getModData().modifier
        if spearMod then
            spear:getModData().modifier = spearMod
            spear:getModData().modifierChecked = true
            pcall(function() RGMManager.applyModifierStatsToItem(spear, spearMod) end)
            if type(spear.transmitModData) == "function" then spear:transmitModData() end
            RGMManager.notifyPlayerModifierAssigned(player, spear, spearMod)
        end
    end
    local bladeMod = selectedItem:getModData().bladeModifier or selectedItem:getModData().modifier
    if bladeMod then
        result:getModData().modifier = bladeMod
        result:getModData().modifierChecked = true
        pcall(function() RGMManager.applyModifierStatsToItem(result, bladeMod) end)
        if type(result.transmitModData) == "function" then result:transmitModData() end
        RGMManager.notifyPlayerModifierAssigned(player, result, bladeMod)
    end
end

function Recipe.OnCreate.OpenUmbrella(items, result, player)
    local itemList = getItemList(items)
    local umbrella = nil
    for i=0,itemList:size()-1 do
        local it = itemList:get(i)
        if it and (it:getType() == "Umbrella" or it:getType() == "UmbrellaOpen") then
            umbrella = it
            break
        end
    end
    if not umbrella then return end

    result:setCondition(umbrella:getCondition())
    local umbMod = umbrella:getModData().modifier
    if umbMod then
        result:getModData().modifier = umbMod
        result:getModData().modifierChecked = true
        pcall(function() RGMManager.applyModifierStatsToItem(result, umbMod) end)
        if type(result.transmitModData) == "function" then result:transmitModData() end
        RGMManager.notifyPlayerModifierAssigned(player, result, umbMod)
    end
    -- B42: hand equip handled by engine automatically after OnCreate
    if player then
        local ph = player:getPrimaryHandItem()
        local sh = player:getSecondaryHandItem()
        if sh == umbrella or ph == umbrella then
            if not player:getPrimaryHandItem() or player:getPrimaryHandItem() == umbrella then
                player:setPrimaryHandItem(result)
            else
                player:setSecondaryHandItem(result)
            end
        end
    end
end

function Recipe.OnCreate.CloseUmbrella(items, result, player)
    local itemList = getItemList(items)
    local umbrella = nil
    for i=0,itemList:size()-1 do
        local it = itemList:get(i)
        if it and (it:getType() == "Umbrella" or it:getType() == "UmbrellaOpen") then
            umbrella = it
            break
        end
    end
    if not umbrella then return end

    result:setCondition(umbrella:getCondition())
    local umbMod2 = umbrella:getModData().modifier
    if umbMod2 then
        result:getModData().modifier = umbMod2
        result:getModData().modifierChecked = true
        pcall(function() RGMManager.applyModifierStatsToItem(result, umbMod2) end)
        if type(result.transmitModData) == "function" then result:transmitModData() end
        RGMManager.notifyPlayerModifierAssigned(player, result, umbMod2)
    end
    if player then
        if not player:getPrimaryHandItem() then
            player:setPrimaryHandItem(result)
        end
        player:setSecondaryHandItem(result)
    end
end
