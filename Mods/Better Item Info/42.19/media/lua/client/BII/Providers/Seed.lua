local Options = require("BII/Options")
local Utils = require("BII/Utils")

local months = {
    [1] = Utils.text("Farming_Month_1", "January"),
    [2] = Utils.text("Farming_Month_2", "February"),
    [3] = Utils.text("Farming_Month_3", "March"),
    [4] = Utils.text("Farming_Month_4", "April"),
    [5] = Utils.text("Farming_Month_5", "May"),
    [6] = Utils.text("Farming_Month_6", "June"),
    [7] = Utils.text("Farming_Month_7", "July"),
    [8] = Utils.text("Farming_Month_8", "August"),
    [9] = Utils.text("Farming_Month_9", "September"),
    [10] = Utils.text("Farming_Month_10", "October"),
    [11] = Utils.text("Farming_Month_11", "November"),
    [12] = Utils.text("Farming_Month_12", "December"),
}

local function getPlant(seed)
    if not farming_vegetableconf or not farming_vegetableconf.props then return nil end
    for _, plant in pairs(farming_vegetableconf.props) do
        if plant.seedName == seed then return plant end
        if type(plant.seedTypes) == "table" then
            for _, seedType in ipairs(plant.seedTypes) do
                if seedType == seed then return plant end
            end
        end
    end
    return nil
end

local function packetSeedType(item)
    local itemType = Utils.call(item, "getType") or ""
    if not string.find(itemType, "BagSeed", 1, true) then return nil end
    local fullType = Utils.call(item, "getFullType") or ""
    fullType = string.gsub(fullType, "Bag", "")
    fullType = string.gsub(fullType, "_Empty", "")
    fullType = string.gsub(fullType, "2", "")
    return fullType
end

local function getRows(item)
    local plant = nil
    if ItemTag and Utils.hasTag(item, ItemTag.IS_SEED) then
        plant = getPlant(Utils.call(item, "getFullType"))
    end
    plant = plant or getPlant(packetSeedType(item))
    if not plant then return nil end

    local rows = {}
    local player = getPlayer and getPlayer() or nil
    local seasonKnown = plant.seasonRecipe and player and Utils.call(player, "isRecipeActuallyKnown", plant.seasonRecipe) == true
    local seasons = Utils.text("IGUI_ItemCat_Unknown", "Unknown")

    if seasonKnown then
        local parts = {}
        local valueParts = {}
        local bestMonths = {}
        local riskMonths = {}
        for _, monthNum in ipairs(plant.bestMonth or {}) do bestMonths[monthNum] = true end
        for _, monthNum in ipairs(plant.riskMonth or {}) do riskMonths[monthNum] = true end
        for _, monthNum in ipairs(plant.sowMonth or {}) do
            local month = months[monthNum] or tostring(monthNum)
            local separator = #parts > 0 and ", " or ""
            table.insert(parts, month)
            if separator ~= "" then table.insert(valueParts, { text = separator }) end
            local part = { text = month }
            if bestMonths[monthNum] then
                part.r, part.g, part.b = Utils.GOOD_R, Utils.GOOD_G, Utils.GOOD_B
            elseif riskMonths[monthNum] then
                part.r, part.g, part.b = 1.0, 0.45, 0.45
            end
            table.insert(valueParts, part)
        end
        seasons = table.concat(parts, ", ")
        local row = Utils.row(Utils.text("Tooltip_BII_GrowingSeasons", "Planting Season"), seasons)
        row.valueParts = valueParts
        Utils.addRow(rows, row)
    else
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_GrowingSeasons", "Planting Season"), seasons))
    end

    if seasonKnown then
        local farmingSpeed = SandboxVars and SandboxVars.FarmingSpeedNew or 1
        local days = math.floor(((plant.timeToGrow or 0) * (plant.harvestLevel or 1)) / 24 / farmingSpeed)
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_GrowthTime", "Average Growth Time"), tostring(days) .. " " .. Utils.text("IGUI_Gametime_days", "days")))
    end

    return rows
end

return Utils.newProvider(Options.shouldShowSeedInfo, 33, getRows)
