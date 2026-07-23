local Options = require("BII/Options")
local Utils = require("BII/Utils")

local refrigerationEffectivenessMultiplier = { 0.4, 0.3, 0.2, 0.1, 0.03, 0 }
local foodSpoilageMultiplier = { 1.7, 1.4, 1.0, 0.7, 0.4 }

local function spoilModifier(item)
    local mod = 1
    local fridgeFactor = SandboxVars and SandboxVars.FridgeFactor or 3
    local foodRotSpeed = SandboxVars and SandboxVars.FoodRotSpeed or 3

    if Utils.call(item, "isFrozen") == true then
        mod = mod * 0.02
        if refrigerationEffectivenessMultiplier[fridgeFactor] == 0 then
            mod = 0
        end
    elseif (Utils.call(item, "getHeat") or 1) < 1 then
        mod = mod * (refrigerationEffectivenessMultiplier[fridgeFactor] or 1)
    end

    return mod * (foodSpoilageMultiplier[foodRotSpeed] or 1)
end

local function cookingLevel(item)
    local player = getPlayer and getPlayer() or nil
    if not player then return 10 end
    if SandboxVars and SandboxVars.BetterItemInfo and SandboxVars.BetterItemInfo.FoodLevelRequirement == false then
        return 10
    end
    return Utils.call(player, "getPerkLevel", Perks and Perks.Cooking) or 0
end

local function isGoodFrozen(item)
    local tags = Utils.call(item, "getTags")
    return tostring(tags) == "[GoodFrozen]"
end

local function addNutritionRows(rows, item, level)
    local player = getPlayer and getPlayer() or nil
    local calories = Utils.call(item, "getCalories")
    if type(calories) ~= "number" or calories <= 0 then return end

    local hasNutritionist = player and (
        Utils.call(player, "hasTrait", CharacterTrait and CharacterTrait.NUTRITIONIST) == true
        or Utils.call(player, "hasTrait", CharacterTrait and CharacterTrait.NUTRITIONIST2) == true
    )

    if hasNutritionist then
        Utils.addRow(rows, Utils.note(Utils.text("Tooltip_food_Nutrition", "Nutrition")))
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Calories", "Calories"), Utils.formatNumber(calories, 1)))
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Carbs", "Carbs"), Utils.formatNumber(Utils.call(item, "getCarbohydrates") or 0, 1)))
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Prots", "Proteins"), Utils.formatNumber(Utils.call(item, "getProteins") or 0, 1)))
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Fat", "Fat"), Utils.formatNumber(Utils.call(item, "getLipids") or 0, 1)))
        return
    end

    if Utils.call(item, "isPackaged") == true or level < 4 then return end

    local value
    if level >= 6 then
        value = Utils.formatNumber(calories, 0)
    elseif level >= 5 or calories < 100 then
        value = "~" .. Utils.formatNumber(calories, -1)
    else
        value = "~" .. Utils.formatNumber(calories, -2)
    end
    Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Calories", "Calories"), value))
end

local function getRows(item)
    if not Utils.isInstance(item, "Food") then return nil end

    local rows = {}
    local level = cookingLevel(item)
    addNutritionRows(rows, item, level)

    local offAge = Utils.call(item, "getOffAge")
    local offAgeMax = Utils.call(item, "getOffAgeMax")
    local age = Utils.call(item, "getAge")
    local packaged = Utils.call(item, "isPackaged") == true

    if type(offAge) == "number" and type(offAgeMax) == "number" and type(age) == "number" and offAge < 10000 then
        local modifier = spoilModifier(item)
        if age <= offAge and (level >= 2 or packaged) and not isGoodFrozen(item) then
            local value = Utils.text("Tooltip_never", "Never")
            if modifier ~= 0 then
                local days = (offAge - age) / modifier
                value = (level >= 4 or packaged) and Utils.formatNumber(days, 1) or tostring(math.floor(days))
            end
            Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_StaleDays", "Days Until Stale"), value))
        end

        if age <= offAgeMax and (level >= 1 or packaged) then
            local label = isGoodFrozen(item) and Utils.text("Tooltip_BII_MeltedDays", "Days Until Melted")
                or Utils.text("Tooltip_BII_RottenDays", "Days Until Rotten")
            local value = Utils.text("Tooltip_never", "Never")
            if modifier ~= 0 then
                local days = (offAgeMax - age) / modifier
                value = (level >= 3 or isGoodFrozen(item) or packaged) and Utils.formatNumber(days, 1) or tostring(math.floor(days))
            end
            Utils.addRow(rows, Utils.row(label, value))
        end
    end

    if Utils.call(item, "isSpice") == true then
        Utils.addRow(rows, Utils.note(Utils.text("Tooltip_BII_Seasoning", "Seasoning")))
    end

    return rows
end

return Utils.newProvider(Options.shouldShowFoodInfo, 30, getRows)
