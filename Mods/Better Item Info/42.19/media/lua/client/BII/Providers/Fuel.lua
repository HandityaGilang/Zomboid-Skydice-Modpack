require "Camping/CCampfireSystem"

local Options = require("BII/Options")
local Utils = require("BII/Utils")

local function getRows(item)
    if not ItemTag or not Utils.hasTag(item, ItemTag.IS_FIRE_FUEL) then return nil end
    local displayCategory = Utils.call(item, "getDisplayCategory")
    if displayCategory == "Bag" or displayCategory == "Container" then return nil end

    local category = Utils.call(item, "getCategory")
    local itemType = Utils.call(item, "getType")
    local value = (campingLightFireCategory and campingLightFireCategory[category])
        or (campingFuelCategory and campingFuelCategory[category])
        or (campingLightFireType and campingLightFireType[itemType])
        or (campingFuelType and campingFuelType[itemType])

    local burnRatio = 2 / 3
    local fireFuelRatio = Utils.call(item, "getFireFuelRatio") or 0
    if fireFuelRatio > 0 then
        burnRatio = fireFuelRatio
    elseif Utils.call(item, "IsClothing") == true
        or Utils.call(item, "IsInventoryContainer") == true
        or Utils.call(item, "IsLiterature") == true
        or Utils.call(item, "IsMap") == true
    then
        burnRatio = 0.25
    end

    local weight = Utils.call(item, "getActualWeight") or 0
    local fuelMinutes = weight * burnRatio * 60
    if type(value) == "number" then
        fuelMinutes = math.min(value, weight * burnRatio) * 60
    end

    return {
        Utils.row(Utils.text("Tooltip_BII_FireFuel", "Fire Fuel"), Utils.timeString(fuelMinutes))
    }
end

return Utils.newProvider(Options.shouldShowFuelInfo, 35, getRows)
