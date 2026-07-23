local Options = require("BII/Options")
local Utils = require("BII/Utils")

local smeltableTags = {
    { "SMELTABLE_IRON_SMALL", "Tooltip_BII_SmallIron", "Small Iron" },
    { "SMELTABLE_IRON_MEDIUM", "Tooltip_BII_MediumIron", "Medium Iron" },
    { "SMELTABLE_IRON_MEDIUM_PLUS", "Tooltip_BII_MediumPlusIron", "Medium Plus Iron" },
    { "SMELTABLE_IRON_LARGE", "Tooltip_BII_LargeIron", "Large Iron" },
    { "SMELTABLE_STEEL_SMALL", "Tooltip_BII_SmallSteel", "Small Steel" },
    { "SMELTABLE_STEEL_MEDIUM", "Tooltip_BII_MediumSteel", "Medium Steel" },
    { "SMELTABLE_STEEL_MEDIUM_PLUS", "Tooltip_BII_MediumPlusSteel", "Medium Plus Steel" },
    { "SMELTABLE_STEEL_LARGE", "Tooltip_BII_LargeSteel", "Large Steel" },
}

local scrapTags = {
    { "TINY_GOLD_SCRAP", "Tooltip_BII_TinyGold", "Tiny Gold" },
    { "SMALLEST_GOLD_SCRAP", "Tooltip_BII_SmallestGold", "Smallest Gold" },
    { "SMALLER_GOLD_SCRAP", "Tooltip_BII_SmallerGold", "Smaller Gold" },
    { "SMALL_GOLD_SCRAP", "Tooltip_BII_SmallGold", "Small Gold" },
    { "GOLD_SCRAP", "Tooltip_BII_Gold", "Gold" },
    { "TINY_SILVER_SCRAP", "Tooltip_BII_TinySilver", "Tiny Silver" },
    { "SMALLEST_SILVER_SCRAP", "Tooltip_BII_SmallestSilver", "Smallest Silver" },
    { "SMALLER_SILVER_SCRAP", "Tooltip_BII_SmallerSilver", "Smaller Silver" },
    { "SMALL_SILVER_SCRAP", "Tooltip_BII_SmallSilver", "Small Silver" },
    { "SILVER_SCRAP", "Tooltip_BII_Silver", "Silver" },
    { "SCRAP_LARGE_COPPER", "Tooltip_BII_LargeCopper", "Large Copper" },
    { "SCRAP_SMALL_COPPER", "Tooltip_BII_MediumCopper", "Medium Copper" },
    { "SCRAP_ALUMINIUM_LARGE", "Tooltip_BII_LargeAluminium", "Large Aluminium" },
}

local function addFirstMatching(rows, item, tags, labelKey, fallback)
    if not ItemTag then return end
    for _, tag in ipairs(tags) do
        local enum = ItemTag[tag[1]]
        if enum and Utils.hasTag(item, enum) then
            Utils.addRow(rows, Utils.row(Utils.text(labelKey, fallback), Utils.text(tag[2], tag[3])))
            return
        end
    end
end

local function getRows(item)
    local rows = {}
    addFirstMatching(rows, item, smeltableTags, "Tooltip_BII_Smeltable", "Smeltable")
    addFirstMatching(rows, item, scrapTags, "Tooltip_BII_Scrappable", "Scrappable")
    return rows
end

return Utils.newProvider(Options.shouldShowMetalInfo, 34, getRows)
