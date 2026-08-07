local TABAS_ReEquipItemsMenu = {}


local TABAS_OutfitManagement = require("TABAS_OutfitManagement")

local MAX_SEARCH_DISTANCE = 8
local COLOR_GRAY = "<RGB:0.6,0.6,0.6>"
local COLOR_YELLOW = "<RGB:1,1,0.5>"
local COLOR_GREEN = "<RGB:0.5,1,0.5>"

local function setTextColor(playerObj, playerInv, itemId)
    local item = playerInv:getItemById(itemId)
    if not item then
        return COLOR_YELLOW
    elseif not playerObj:isEquipped(item) then
        return COLOR_GREEN
    end
    return COLOR_GRAY
end

local function setTextColorAttached(playerObj, playerInv, itemId)
    local item = playerInv:getItemById(itemId)
    if not item then
        return COLOR_YELLOW
    elseif not playerObj:isAttachedItem(item) then
        return COLOR_GREEN
    end
    return COLOR_GRAY
end


local function createItemListText(playerObj, data)
    if not data then return "" end

    local lines = {}
    local playerInv = playerObj:getInventory()
    if data.clothes then
        for _, entry in ipairs(data.clothes) do
            local color = setTextColor(playerObj, playerInv, entry.itemId)
            lines[#lines + 1] = " - " .. color .. entry.displayName
        end
    end
    if data.handItems then
        for _, entry in ipairs(data.handItems) do
            local color = setTextColor(playerObj, playerInv, entry.itemId)
            lines[#lines + 1] = " - " .. color .. entry.displayName
        end
    end
    if data.attachedItems then
        for _, entry in ipairs(data.attachedItems) do
            local color = setTextColorAttached(playerObj, playerInv, entry.itemId)
            lines[#lines + 1] = " * " .. color .. entry.displayName
        end
    end
    if #lines == 0 then return "" end

    return " <LINE> <LINE> " .. getText("ContextMenu_TABAS_ReEquipItems_DebugItems") .. " <LINE> " .. table.concat(lines, " <LINE> ")
end

function TABAS_ReEquipItemsMenu.createMenu(player, context, worldObjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local md = playerObj:getModData()
    if not md or md.tabas_IsBathing then return end

    local outfitData = TABAS_OutfitManagement.getOutfitData(playerObj)
    if not outfitData then return end

    local mainOption = context:addOption(getText("ContextMenu_TABAS_ReEquipItems"), playerObj, TABAS_ReEquipItemsMenu.onReEquipItemsFromMenu)
    mainOption.iconTexture = getTexture("media/ui/Icons/tabas_reequip_action.png")
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local text = createItemListText(playerObj, outfitData)
    tooltip.description = getText("ContextMenu_TABAS_ReEquipItems_tooltip") .. text
    mainOption.toolTip = tooltip

    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainOption, subMenu)

    local discardOption = subMenu:addOption(getText("ContextMenu_TABAS_ReEquipItems_Discard"), playerObj, TABAS_ReEquipItemsMenu.onDiscardOutfitData)
    discardOption.iconTexture = getTexture("media/ui/Icons/tabas_reequip_discard.png")
    local discardTooltip = ISWorldObjectContextMenu.addToolTip()
    discardTooltip.description = getText("ContextMenu_TABAS_ReEquipItems_Discard_tooltip")
    discardOption.toolTip = discardTooltip
end

function TABAS_ReEquipItemsMenu.onReEquipItemsFromMenu(playerObj)
    TABAS_OutfitManagement.onReEquipActionQueue(playerObj, true)
end

function TABAS_ReEquipItemsMenu.onDiscardOutfitData(playerObj)
    TABAS_OutfitManagement.discardOutfitData(playerObj)
end

Events.OnFillWorldObjectContextMenu.Add(TABAS_ReEquipItemsMenu.createMenu)

return TABAS_ReEquipItemsMenu
