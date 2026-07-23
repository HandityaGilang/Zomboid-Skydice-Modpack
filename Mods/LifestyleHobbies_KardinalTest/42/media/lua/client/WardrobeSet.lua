
require "WardrobeFunctions"
require "LifestyleCore/LSK_SystemsClient"

LSWardrobeContextMenu = LSWardrobeContextMenu or {}

local function isValidTarget(player, item)
    return player:isEquippedClothing(item) and not item:isHidden() and item:getType() ~= "NeuralHat"
end

function LSWardrobeContextMenu.setClothes(player, option)    
    local wornItems = player:getWornItems()
    local playerData = player:getModData()
    playerData[option..'Clothes'] = {}
    for n=1,31 do
        local val = n-1
        playerData[option..'Clothes'..tostring(val)] = false
    end
    local wornNum
    for i=1,wornItems:size() do
        local val = i-1
        local wornItem = wornItems:get(val)
        local item = wornItem:getItem()
        if isValidTarget(player, item) then
            local itemFullType = item:getFullType()
            playerData[option..'Clothes'..tostring(val)] = itemFullType
            table.insert(playerData[option..'Clothes'], itemFullType)
            wornNum = val
            if val == 30 then break; end
        end
    end

    if not wornNum then return; end
    getSoundManager():playUISound("UI_Button_SELECT")
    player:Say(option.." set total:  " .. tostring(wornNum))

    if isClient() and LifestyleSecure.ClientSystems then
        LifestyleSecure.ClientSystems.saveComfortPreset(player, option, playerData[option..'Clothes'])
    end

end
