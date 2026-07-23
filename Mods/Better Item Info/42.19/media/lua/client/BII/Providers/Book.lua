local Options = require("BII/Options")
local Utils = require("BII/Utils")

local function getRows(item)
    if Utils.call(item, "getDisplayCategory") ~= "SkillBook" or Utils.call(item, "getCategory") ~= "Literature" then return nil end

    local readTimeMultiplier = 2
    local player = getPlayer and getPlayer() or nil
    if player and Utils.call(player, "hasTrait", CharacterTrait and CharacterTrait.SLOW_READER) == true then
        readTimeMultiplier = readTimeMultiplier * 1.3
    elseif player and Utils.call(player, "hasTrait", CharacterTrait and CharacterTrait.FAST_READER) == true then
        readTimeMultiplier = readTimeMultiplier * 0.7
    end

    local pages = Utils.call(item, "getNumberOfPages") or 0
    local read = Utils.call(item, "getAlreadyReadPages") or 0
    local minutesLeft = Utils.round((pages - read) * readTimeMultiplier, 0)
    if minutesLeft <= 0 then return nil end

    return {
        Utils.row(Utils.text("Tooltip_BII_ReadTimeLeft", "Read Time Left"), Utils.timeString(minutesLeft))
    }
end

return Utils.newProvider(Options.shouldShowBookInfo, 37, getRows)
