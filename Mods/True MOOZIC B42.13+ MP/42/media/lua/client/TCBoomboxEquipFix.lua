require "TCMusicDefenitions"

local function hasBoomboxEquipped(player)
    if not player then return false end
    local primary = player:getPrimaryHandItem()
    if primary and TCMusic.ItemMusicPlayer[primary:getFullType()] then
        return true
    end
    local secondary = player:getSecondaryHandItem()
    if secondary and TCMusic.ItemMusicPlayer[secondary:getFullType()] then
        return true
    end
    return false
end

local function onEquipBoomboxFix(player, item)
    if player ~= getPlayer() then return end
    if hasBoomboxEquipped(player) then
        player:resetModelNextFrame()
    end
end

Events.OnEquipPrimary.Add(onEquipBoomboxFix)
Events.OnEquipSecondary.Add(onEquipBoomboxFix)
