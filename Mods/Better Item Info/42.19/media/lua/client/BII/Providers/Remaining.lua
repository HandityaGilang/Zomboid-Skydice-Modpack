local Options = require("BII/Options")
local Utils = require("BII/Utils")

local function getRows(item)
    if not Utils.isInstance(item, "DrainableComboItem") then return nil end

    local fullType = Utils.call(item, "getFullType")
    local value
    if fullType == "Base.Battery"
        or (ItemTag and (Utils.hasTag(item, ItemTag.FLASHLIGHT) or Utils.hasTag(item, ItemTag.USES_BATTERY)))
    then
        value = tostring(math.ceil((Utils.call(item, "getCurrentUsesFloat") or 0) * 100)) .. "%"
    else
        value = tostring(Utils.call(item, "getCurrentUses") or 0)
    end

    return {
        Utils.row(Utils.text("Tooltip_BII_UsesLeft", "Uses Left"), value)
    }
end

return Utils.newProvider(Options.shouldShowRemainingInfo, 38, getRows)
