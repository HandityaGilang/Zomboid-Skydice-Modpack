local DRAGONSLAYER_TYPE = "Dragonslayer.Dragonslayer"
local ANIMATION_FLAG = "DragonslayerWeapon"

local function isHoldingDragonslayer(player)
    local primaryItem = player:getPrimaryHandItem()
    return primaryItem ~= nil and primaryItem:getFullType() == DRAGONSLAYER_TYPE
end

local function updateAnimationFlag(player)
    if player == nil then
        return
    end

    local shouldEnable = isHoldingDragonslayer(player)
    if player:getVariableBoolean(ANIMATION_FLAG) == shouldEnable then
        return
    end

    if shouldEnable then
        player:setVariable(ANIMATION_FLAG, true)
    else
        player:clearVariable(ANIMATION_FLAG)
    end
end

Events.OnPlayerUpdate.Add(updateAnimationFlag)
