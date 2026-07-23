local Options = require("BII/Options")
local Utils = require("BII/Utils")

local function cookingLevel()
    local player = getPlayer and getPlayer() or nil
    if not player then return 10 end
    if SandboxVars and SandboxVars.BetterItemInfo and SandboxVars.BetterItemInfo.FoodLevelRequirement == false then
        return 10
    end
    return Utils.call(player, "getPerkLevel", Perks and Perks.Cooking) or 0
end

local function addNutritionRows(rows, properties, level)
    if not properties then return end
    local hunger = Utils.call(properties, "getHungerChange")
    if type(hunger) == "number" and hunger < 0 then
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Hunger", "Hunger"), Utils.formatNumber(hunger * 100, 0), Utils.GOOD_R, Utils.GOOD_G, Utils.GOOD_B))
    end

    local calories = Utils.call(properties, "getCalories")
    if type(calories) ~= "number" or calories <= 0 then return end

    local player = getPlayer and getPlayer() or nil
    local hasNutritionist = player and (
        Utils.call(player, "hasTrait", CharacterTrait and CharacterTrait.NUTRITIONIST) == true
        or Utils.call(player, "hasTrait", CharacterTrait and CharacterTrait.NUTRITIONIST2) == true
    )

    if hasNutritionist then
        Utils.addRow(rows, Utils.note(Utils.text("Tooltip_food_Nutrition", "Nutrition")))
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Calories", "Calories"), Utils.formatNumber(calories, 1)))
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Carbs", "Carbs"), Utils.formatNumber(Utils.call(properties, "getCarbohydrates") or 0, 1)))
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Prots", "Proteins"), Utils.formatNumber(Utils.call(properties, "getProteins") or 0, 1)))
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_food_Fat", "Fat"), Utils.formatNumber(Utils.call(properties, "getLipids") or 0, 1)))
        return
    end

    if level < 4 then return end

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

local function getFluidKind(container)
    if not container or not Fluid then return nil end
    local known = {
        { key = "Petrol", label = "Petrol" },
        { key = "Water", label = "Water" },
        { key = "TaintedWater", label = "Tainted water" },
        { key = "Bleach", label = "Bleach" },
        { key = "CleaningLiquid", label = "Cleaning liquid" },
    }

    for _, fluid in ipairs(known) do
        if Fluid[fluid.key] and Utils.call(container, "contains", Fluid[fluid.key]) == true then
            return fluid.label
        end
    end
    return nil
end

local function getRows(item)
    local container = Utils.call(item, "getFluidContainer")
    if not container then return nil end

    local rows = {}
    local amount = Utils.call(container, "getAmount")
    local capacity = Utils.call(container, "getCapacity")
    local freeCapacity = Utils.call(container, "getFreeCapacity")

    if type(amount) == "number" and type(capacity) == "number" and capacity > 0 then
        local value = Utils.formatNumber(amount, 2) .. " / " .. Utils.formatNumber(capacity, 2) .. " L"
        local kind = getFluidKind(container)
        if kind then value = value .. " (" .. kind .. ")" end
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_Fluid", "Fluid"), value))
    elseif type(amount) == "number" and amount > 0 then
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_Fluid", "Fluid"), Utils.formatNumber(amount, 2) .. " L"))
    end

    if type(freeCapacity) == "number" and freeCapacity > 0 then
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_FreeCapacity", "Free Capacity"), Utils.formatNumber(freeCapacity, 2) .. " L"))
    end

    addNutritionRows(rows, Utils.call(container, "getProperties"), cookingLevel())

    if getSandboxOptions and Fluid and Fluid.TaintedWater and Utils.call(container, "contains", Fluid.TaintedWater) == true then
        local ok, showTainted = pcall(function()
            local option = getSandboxOptions():getOptionByName("EnableTaintedWaterText")
            return option and option:getValue()
        end)
        if ok and showTainted then
            Utils.addRow(rows, Utils.note(Utils.text("Tooltip_item_TaintedWater", "Tainted Water"), 1.0, 0.5, 0.5))
        end
    end

    return rows
end

return Utils.newProvider(Options.shouldShowLiquidInfo, 31, getRows)
