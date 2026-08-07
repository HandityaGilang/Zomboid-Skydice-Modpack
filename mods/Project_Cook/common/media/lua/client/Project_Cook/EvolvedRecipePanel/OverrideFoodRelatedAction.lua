require "TimedActions/ISAddItemInRecipe"

local original_ISAddItemInRecipeComplete = nil
if not original_ISAddItemInRecipeComplete then
    original_ISAddItemInRecipeComplete = ISAddItemInRecipe.complete
end

local PJCK_DEBUG_LOGS = false
local function PJCK_dbg(...)
    if not PJCK_DEBUG_LOGS then return end
    local parts = {"[ProjectCook]"}
    for i = 1, select('#', ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    print(table.concat(parts, " "))
end


local PJCK_GENERATED_RECIPE_NAME_LIMIT = 3

local function PJCK_setGeneratedRecipeName(baseItem, generatedName)
    -- B42.17 vanilla may call setName(getText(name)) after name was already translated.
    -- When the second getText() returns nil, Java receives setName() with no argument.
    if baseItem and generatedName and generatedName ~= "" then
        baseItem:setName(tostring(generatedName))
    end
end

local function PJCK_getRecipeDisplayName(recipe)
    -- Keep vanilla translated evolved-recipe names when available, but keep a safe fallback.
    if not recipe then return "" end

    local untranslatedName = nil
    if recipe.getUntranslatedName then
        untranslatedName = recipe:getUntranslatedName()
    end

    if untranslatedName and untranslatedName ~= "" then
        local key = "ContextMenu_EvolvedRecipe_" .. tostring(untranslatedName)
        local translated = getText(key)
        if translated and translated ~= "" and translated ~= key then
            return tostring(translated)
        end
        return tostring(untranslatedName)
    end

    if recipe.getName then
        local name = recipe:getName()
        if name and name ~= "" then
            return tostring(name)
        end
    end

    return ""
end

local function PJCK_formatRecipeName(prefixName, recipeName)
    -- Format generated food names through the vanilla two-argument key.
    -- This avoids ContextMenu_EvolvedRecipe_RecipeNameNew, whose B42.17 translations may require four arguments.
    local prefix = prefixName and tostring(prefixName) or ""
    local recipeDisplayName = recipeName and tostring(recipeName) or ""

    if prefix ~= "" and recipeDisplayName ~= "" then
        local ok, translated = pcall(getText, "ContextMenu_EvolvedRecipe_RecipeName", prefix, recipeDisplayName)
        if ok and translated and translated ~= "" then
            return tostring(translated)
        end
        return prefix .. " " .. recipeDisplayName
    end

    if recipeDisplayName ~= "" then
        return recipeDisplayName
    end

    return prefix
end

-- Generate the evolved recipe name using the vanilla B42 logic, but avoid translating the
-- already-generated display name a second time before InventoryItem:setName().
ISAddItemInRecipe.checkName = function(baseItem, recipe)
    local max_total = PJCK_GENERATED_RECIPE_NAME_LIMIT
    local max_base = max_total
    local foodTypeList = {}
    local finalName = ""
    local spicesName = ""
    local name = ""
    local count = 0

    if not baseItem or not recipe then
        return
    end

    if not baseItem:getExtraItems() and not baseItem:getSpices() then
        return
    end

    if instanceof(baseItem, "Food") and not baseItem:isCustomName() then -- Do not rename custom or unique recipes.
        if baseItem:getExtraItems() then
            for i = 0, baseItem:getExtraItems():size() - 1 do
                for _, v in pairs(foodTypeList) do
                    if v ~= "" then count = count + 1 end
                end

                local food = baseItem:getExtraItems():get(i)
                local foodName = getItemEvolvedRecipeName(food) or getItemDisplayName(food)
                if isItemFood(food) then
                    if getItemFoodType(food) == "NoExplicit" or not getItemFoodType(food) then
                        -- NoExplicit appears only if there is no other ingredient inside the recipe.
                        if count == 0 then
                            foodTypeList["NoExplicit"] = getItemDisplayName(food)
                        end
                    else
                        foodTypeList["NoExplicit"] = ""
                        local foodTypeName = getText("ContextMenu_FoodType_" .. getItemFoodType(food))
                        if not foodTypeList[foodTypeName] then
                            -- First use the food name; if there are several different foods of this type, use the food type.
                            foodTypeList[foodTypeName] = foodName
                        elseif foodTypeList[foodTypeName] ~= getItemDisplayName(food) then
                            foodTypeList[foodTypeName] = foodTypeName
                        end
                    end
                end
            end
        end

        count = 0
        for _, v in pairs(foodTypeList) do
            if v ~= "" then count = count + 1 end
        end

        if count > max_base then
            count = 0
            name = PJCK_getRecipeDisplayName(recipe)
            PJCK_setGeneratedRecipeName(baseItem, name)
        else
            local index = 0
            for _, v in pairs(foodTypeList) do
                if v ~= "" and not ((v == "Fruit" or v == "Fruits") and baseItem:getType() == "FruitSalad") then
                    -- Keep the vanilla fruit-salad naming exception.
                    if finalName ~= "" then
                        if index == count then
                            finalName = finalName .. " " .. getText("ContextMenu_EvolvedRecipe_and") .. " "
                        else
                            finalName = finalName .. getText("ContextMenu_EvolvedRecipe_comma") .. " "
                        end
                    end
                    finalName = finalName .. v
                end
                index = index + 1
            end

            name = PJCK_formatRecipeName(finalName, PJCK_getRecipeDisplayName(recipe))
            PJCK_setGeneratedRecipeName(baseItem, name)
        end
    end

    if count > max_total then
        -- If there is already the maximum amount of food elements, do not spend time on spices.
        if not isServer() then
            ISInventoryPage.dirtyUI()
        end
        return
    end

    local previousCount = count
    if baseItem:getSpices() then
        count = 0
        foodTypeList = {}
        for i = 0, baseItem:getSpices():size() - 1 do
            for _, v in pairs(foodTypeList) do
                if v ~= "" then count = count + 1 end
            end

            local food = baseItem:getSpices():get(i)
            local foodName = getItemEvolvedRecipeName(food) or getItemDisplayName(food)
            if isItemFood(food) and not hasItemTag(food, ItemTag.MINOR_INGREDIENT) then
                if getItemFoodType(food) == "NoExplicit" or not getItemFoodType(food) then
                    if count == 0 then
                        foodTypeList["NoExplicit"] = getItemDisplayName(food)
                    end
                else
                    foodTypeList["NoExplicit"] = ""
                    local foodTypeName = getText("ContextMenu_FoodType_" .. getItemFoodType(food))
                    if not foodTypeList[foodTypeName] then
                        foodTypeList[foodTypeName] = foodName
                    elseif foodTypeList[foodTypeName] ~= getItemDisplayName(food) then
                        foodTypeList[foodTypeName] = foodTypeName
                    end
                end
            end
        end

        count = 0
        for _, v in pairs(foodTypeList) do
            if v ~= "" then count = count + 1 end
        end

        if (count + previousCount) <= max_base then
            local index = 0
            for _, v in pairs(foodTypeList) do
                if v ~= "" and not ((v == "Fruit" or v == "Fruits") and baseItem:getType() == "FruitSalad") then
                    -- Keep the vanilla fruit-salad naming exception.
                    if spicesName ~= "" then
                        if index == count then
                            spicesName = spicesName .. " " .. getText("ContextMenu_EvolvedRecipe_and") .. " "
                        else
                            spicesName = spicesName .. getText("ContextMenu_EvolvedRecipe_comma") .. " "
                        end
                    end
                    spicesName = spicesName .. v
                end
                index = index + 1
            end

            if spicesName:len() > 0 and baseItem:getExtraItems() and baseItem:getExtraItems():size() > 0 then
                -- Build a stable name without using RecipeNameNew, because some B42.17 locales contain a %4$s placeholder.
                local baseRecipeName = PJCK_formatRecipeName(finalName, PJCK_getRecipeDisplayName(recipe))
                name = PJCK_formatRecipeName(spicesName, baseRecipeName)
                PJCK_setGeneratedRecipeName(baseItem, name)
            elseif spicesName:len() > 0 then
                name = PJCK_formatRecipeName(spicesName, PJCK_getRecipeDisplayName(recipe))
                PJCK_setGeneratedRecipeName(baseItem, name)
            end
        end
    end

    if not isServer() then
        ISInventoryPage.dirtyUI()
    end
end

local function PJCK_snapshotInventoryIds(inventory)
    local ids = {}
    if not inventory or not inventory.getItems then return ids end
    local items = inventory:getItems()
    if not items then return ids end
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getID then
            ids[it:getID()] = true
        end
    end
    return ids
end

local function PJCK_findReplacementBaseItem(character, beforeIds, expectedFullType, oldBaseId, oldBaseFullType, usedItemFullType, recipe)
    local inventory = character and character.getInventory and character:getInventory() or nil
    if not inventory then return nil end

    local items = inventory:getItems()
    if not items then return nil end

    if oldBaseId and inventory.getItemById then
        local sameIdItem = inventory:getItemById(oldBaseId)
        if sameIdItem then
            if not expectedFullType or (sameIdItem.getFullType and sameIdItem:getFullType() == expectedFullType) then
                PJCK_dbg("findReplacementBaseItem matched sameIdItem", sameIdItem:getFullType(), sameIdItem:getID())
                return sameIdItem
            end
        end
    end

    if expectedFullType then
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it and it.getFullType and it:getFullType() == expectedFullType then
                PJCK_dbg("findReplacementBaseItem matched expected type in inventory", expectedFullType, it:getID())
                return it
            end
        end
    end

    local newItems = {}
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and it.getID and not beforeIds[it:getID()] then
            table.insert(newItems, it)
        end
    end

    if #newItems == 0 then
        PJCK_dbg("findReplacementBaseItem found no newItems")
        return nil
    end

    if expectedFullType then
        for _, it in ipairs(newItems) do
            if it.getFullType and it:getFullType() == expectedFullType then
                return it
            end
        end
    end

    local containers = ISInventoryPaneContextMenu.getContainers(character)

    local function looksLikeUsableBaseItem(it)
        if not it then return false end
        local recipes = RecipeManager.getEvolvedRecipe(it, character, containers, false)
        return recipes and recipes:size() > 0
    end

    for _, it in ipairs(newItems) do
        if looksLikeUsableBaseItem(it) and (not usedItemFullType or it:getFullType() ~= usedItemFullType) then
            return it
        end
    end

    for _, it in ipairs(newItems) do
        if it.getFullType and oldBaseFullType and it:getFullType() ~= oldBaseFullType and (not usedItemFullType or it:getFullType() ~= usedItemFullType) then
            return it
        end
    end

    return newItems[1]
end


local function PJCK_scheduleBaseItemRefreshRetry(playerNum, character, replacementInfo)
    if not Events or not Events.OnTick then return end

    PJCK_dbg("schedule retry", "player", playerNum, "expected", replacementInfo and replacementInfo.expectedFullType, "oldId", replacementInfo and replacementInfo.oldBaseId)

    local ticksLeft = 180
    local function retry()
        ticksLeft = ticksLeft - 1

        local playerData = PJCK_CookingUI and PJCK_CookingUI.players and PJCK_CookingUI.players[playerNum] or nil
        local panel = playerData and playerData.windows and playerData.windows["CookingWindow"] and playerData.windows["CookingWindow"].instance or nil
        if not panel or not panel.EvoPanel or not character then
            Events.OnTick.Remove(retry)
            return
        end

        local updatedBaseItem = PJCK_findReplacementBaseItem(
            character,
            replacementInfo.beforeIds,
            replacementInfo.expectedFullType,
            replacementInfo.oldBaseId,
            replacementInfo.oldBaseFullType,
            replacementInfo.usedItemFullType,
            nil
        )

        if updatedBaseItem then
            PJCK_dbg("retry matched replacement", updatedBaseItem:getFullType(), updatedBaseItem:getID())
            panel.EvoPanel:refreshBaseItemAfterRecipeAction(updatedBaseItem, nil)
            Events.OnTick.Remove(retry)
            return
        end

        if ticksLeft <= 0 then
            PJCK_dbg("retry expired", replacementInfo and replacementInfo.expectedFullType, replacementInfo and replacementInfo.oldBaseId)
            Events.OnTick.Remove(retry)
        end
    end

    Events.OnTick.Add(retry)
end

function ISAddItemInRecipe:complete()
    local character = self.character
    local inventory = character and character.getInventory and character:getInventory() or nil
    local beforeIds = PJCK_snapshotInventoryIds(inventory)
    local oldBaseId = self.baseItem and self.baseItem.getID and self.baseItem:getID() or nil
    local oldBaseFullType = self.baseItem and self.baseItem.getFullType and self.baseItem:getFullType() or nil
    local usedItemFullType = self.usedItem and self.usedItem.getFullType and self.usedItem:getFullType() or nil

    PJCK_dbg("ISAddItemInRecipe.complete START")
    PJCK_dbg("Add source base", oldBaseFullType, oldBaseId, "used", usedItemFullType)
    local result = original_ISAddItemInRecipeComplete(self)

    if PJCK_CookingUI and PJCK_CookingUI.players then
        for playerNum, playerData in pairs(PJCK_CookingUI.players) do
            local panel = playerData.windows and playerData.windows["CookingWindow"] and playerData.windows["CookingWindow"].instance
            if panel and panel.EvoPanel and character and character:getPlayerNum() == playerNum then
                local updatedBaseItem = nil
                local expectedFullType = self.baseItem and self.baseItem.getFullType and self.baseItem:getFullType() or nil

                if self.baseItem and inventory and inventory:getItemById(self.baseItem:getID()) then
                    updatedBaseItem = inventory:getItemById(self.baseItem:getID())
                elseif self.baseItem and self.baseItem.getContainer and self.baseItem:getContainer() == inventory then
                    updatedBaseItem = self.baseItem
                else
                    updatedBaseItem = PJCK_findReplacementBaseItem(character, beforeIds, expectedFullType, oldBaseId, oldBaseFullType, usedItemFullType, self.recipe)
                end

                PJCK_dbg("Add expectedFullType", expectedFullType)
                local replacementInfo = {
                    beforeIds = beforeIds,
                    oldBaseId = oldBaseId,
                    oldBaseFullType = oldBaseFullType,
                    expectedFullType = expectedFullType,
                    usedItemFullType = usedItemFullType,
                }

                if panel.EvoPanel.refreshBaseItemAfterRecipeAction then
                    PJCK_dbg("Add updatedBaseItem immediate", updatedBaseItem and updatedBaseItem:getFullType() or "nil", updatedBaseItem and updatedBaseItem:getID() or "nil")
                    panel.EvoPanel:refreshBaseItemAfterRecipeAction(updatedBaseItem, replacementInfo)
                    if not updatedBaseItem then
                        PJCK_scheduleBaseItemRefreshRetry(playerNum, character, replacementInfo)
                    end
                else
                    panel.EvoPanel:setBaseItem(updatedBaseItem)
                end
            end
        end
    end

    return result
end


local function PJCK_getDirectDumpReplacementFullType(item)
    if not item or not item.getFullType then return nil end

    local scriptItem = ScriptManager.instance:FindItem(item:getFullType())
    if not scriptItem then return nil end

    if scriptItem:getReplaceOnUse() then
        return moduleDotType(scriptItem:getModuleName(), scriptItem:getReplaceOnUse())
    end

    if scriptItem:isItemType(ItemType.Drainable) and scriptItem:getReplaceOnDeplete() then
        return moduleDotType(scriptItem:getModuleName(), scriptItem:getReplaceOnDeplete())
    end

    return nil
end
local original_DumpContentsActionComplete = nil
if not original_DumpContentsActionComplete then
    original_DumpContentsActionComplete = ISDumpContentsAction.complete
end

function ISDumpContentsAction:complete()
    local character = self.character
    local inventory = character and character.getInventory and character:getInventory() or nil
    local beforeIds = PJCK_snapshotInventoryIds(inventory)
    local oldBaseId = self.item and self.item.getID and self.item:getID() or nil
    local oldBaseFullType = self.item and self.item.getFullType and self.item:getFullType() or nil
    local expectedFullType = PJCK_getDirectDumpReplacementFullType(self.item)

    PJCK_dbg("ISDumpContentsAction.complete START")
    PJCK_dbg("Dump source", oldBaseFullType, oldBaseId, "expected", expectedFullType)
    local result = original_DumpContentsActionComplete(self)

    if PJCK_CookingUI and PJCK_CookingUI.players and character then
        local playerNum = character:getPlayerNum()
        local panel = PJCK_CookingUI.players[playerNum] and PJCK_CookingUI.players[playerNum].windows and PJCK_CookingUI.players[playerNum].windows["CookingWindow"] and PJCK_CookingUI.players[playerNum].windows["CookingWindow"].instance

        if panel and panel.EvoPanel then
            local baseItem = panel.EvoPanel:getBaseItem()

            if baseItem and self.item and baseItem:getID() == self.item:getID() then
                local updatedBaseItem = nil

                if inventory and self.item and self.item.getID then
                    local sameIdItem = inventory:getItemById(self.item:getID())
                    if sameIdItem then
                        if not expectedFullType or (sameIdItem.getFullType and sameIdItem:getFullType() == expectedFullType) then
                            updatedBaseItem = sameIdItem
                        end
                    end
                end

                if not updatedBaseItem and expectedFullType and inventory then
                    updatedBaseItem = PJCK_findReplacementBaseItem(character, beforeIds, expectedFullType, oldBaseId, oldBaseFullType, nil, nil)
                end

                local replacementInfo = {
                    beforeIds = beforeIds,
                    oldBaseId = oldBaseId,
                    oldBaseFullType = oldBaseFullType,
                    expectedFullType = expectedFullType,
                }

                PJCK_dbg("Dump updatedBaseItem immediate", updatedBaseItem and updatedBaseItem:getFullType() or "nil", updatedBaseItem and updatedBaseItem:getID() or "nil")
                if updatedBaseItem then
                    if panel.EvoPanel.refreshBaseItemAfterRecipeAction then
                        panel.EvoPanel:refreshBaseItemAfterRecipeAction(updatedBaseItem, replacementInfo)
                    else
                        panel.EvoPanel:setBaseItem(updatedBaseItem)
                    end
                else
                    if panel.EvoPanel.refreshBaseItemAfterRecipeAction then
                        panel.EvoPanel:refreshBaseItemAfterRecipeAction(nil, replacementInfo)
                    else
                        panel.EvoPanel:setBaseItem(nil)
                    end
                    PJCK_scheduleBaseItemRefreshRetry(playerNum, character, replacementInfo)
                end
            end
        end
    end

    return result
end
