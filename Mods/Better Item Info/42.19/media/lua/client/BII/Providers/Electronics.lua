local Options = require("BII/Options")
local Utils = require("BII/Utils")

local function getRows(item)
    if not ItemTag then return nil end
    local displayCategory = Utils.call(item, "getDisplayCategory")
    local displayName = Utils.call(item, "getDisplayName") or ""
    local electronic = Utils.hasTag(item, ItemTag.MISC_ELECTRONIC)
        or Utils.hasTag(item, ItemTag.DIGITAL)
        or (displayCategory == "Electronics" and (
            Utils.hasTag(item, ItemTag.TV_REMOTE)
            or Utils.hasTag(item, ItemTag.CAMERA)
            or displayName == "Power Bar"
            or displayName == "Home Alarm"
            or displayName == "Speaker"
        ))
        or (displayCategory == "Communications" and not string.find(displayName, "Makeshift", 1, true))

    if not electronic then return nil end
    return { Utils.note(Utils.text("Tooltip_BII_Electronic", "Electronic"), 1.0, 1.0, 0.5) }
end

return Utils.newProvider(Options.shouldShowElectronicsInfo, 36, getRows)
