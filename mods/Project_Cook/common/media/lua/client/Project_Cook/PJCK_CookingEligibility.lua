-- Shared cooking eligibility helpers for Project Cook.
-- These helpers keep non-cooking "Food" items, such as cigarettes, out of the cooking browser.
PJCK_CookingEligibility = PJCK_CookingEligibility or {}

local function PJCK_safeCall(fn)
    local ok, result = pcall(fn)
    if ok then
        return result
    end
    return nil
end

local function PJCK_getScriptItem(item)
    -- Prefer the live item script object, then fall back to ScriptManager by full type.
    if not item then return nil end

    if item.getScriptItem then
        local scriptItem = PJCK_safeCall(function() return item:getScriptItem() end)
        if scriptItem then return scriptItem end
    end

    if item.getFullType then
        local fullType = item:getFullType()
        if fullType then
            return ScriptManager.instance:FindItem(fullType)
        end
    end

    return nil
end

function PJCK_CookingEligibility.hasEvolvedRecipeData(item)
    -- Items usable as cooking ingredients have EvolvedRecipe entries in their script item.
    local scriptItem = PJCK_getScriptItem(item)
    if not scriptItem or not scriptItem.getEvolvedRecipe then return false end

    local evolvedRecipes = PJCK_safeCall(function() return scriptItem:getEvolvedRecipe() end)
    if not evolvedRecipes then return false end

    if evolvedRecipes.size then
        return evolvedRecipes:size() > 0
    end

    return false
end

function PJCK_CookingEligibility.isSmokableFood(item)
    -- In B42 cigarettes, cigars and filled pipes are technically Food, but they are nicotine/smoking items.
    -- Keep this broad so vanilla tobacco items and similar modded smoking items are not shown as cooking ingredients.
    if not item then return false end

    if item.hasTag and ItemTag and ItemTag.SMOKABLE then
        local hasSmokableTag = PJCK_safeCall(function() return item:hasTag(ItemTag.SMOKABLE) end)
        if hasSmokableTag then return true end
    end

    if item.getEatType then
        local eatType = item:getEatType()
        if eatType then
            local lowerEatType = string.lower(tostring(eatType))
            if string.find(lowerEatType, "cigarette") or lowerEatType == "pipe" then
                return true
            end
        end
    end

    if item.getFullType then
        local fullType = item:getFullType()
        if fullType then
            local lowerFullType = string.lower(fullType)
            if string.find(lowerFullType, "cigarette")
                    or string.find(lowerFullType, "cigar")
                    or string.find(lowerFullType, "tobacco")
                    or string.find(lowerFullType, "smokingpipe")
                    or string.find(lowerFullType, "canpipe") then
                return true
            end
        end
    end

    return false
end

function PJCK_CookingEligibility.isTechnicalNonCookingFood(item)
    -- Wrapper kept separate from isSmokableFood so more technical-food exclusions can be added later.
    return PJCK_CookingEligibility.isSmokableFood(item)
end

function PJCK_CookingEligibility.isLooseCookingFood(item, player)
    -- This is used only for the no-base-item browser and the right-click entry point.
    -- Actual recipe ingredient lists still come from vanilla recipe:getItemsCanBeUse().
    if not item or not instanceof(item, "Food") then return false end
    if item.isNoRecipes and player and item:isNoRecipes(player) then return false end
    if PJCK_CookingEligibility.isTechnicalNonCookingFood(item) then return false end

    return PJCK_CookingEligibility.hasEvolvedRecipeData(item)
end

function PJCK_CookingEligibility.hasBaseEvolvedRecipes(item, player, containers)
    -- Check whether the item can act as a base item for at least one evolved recipe.
    if not item or not player then return false end
    if item.isNoRecipes and item:isNoRecipes(player) then return false end

    local recipeList = RecipeManager.getEvolvedRecipe(item, player, containers or ISInventoryPaneContextMenu.getContainers(player), false)
    return recipeList and recipeList:size() > 0
end

function PJCK_CookingEligibility.shouldShowContextOption(item, player, containers)
    -- Show Project Cook for valid base items or actual evolved-recipe food ingredients only.
    return PJCK_CookingEligibility.hasBaseEvolvedRecipes(item, player, containers)
        or PJCK_CookingEligibility.isLooseCookingFood(item, player)
end

return PJCK_CookingEligibility
