local TABAS_DrySelfMenu = {}

local TABAS_Utils = require("TABAS_Utils")

local function toInventoryItems(items)
    local actualItems = {}
    for i = 1, #items do
        local item = items[i]
        if not instanceof(item, "InventoryItem") then
            item = item.items and item.items[1] or nil
        end
        if instanceof(item, "InventoryItem") then
            actualItems[#actualItems + 1] = item
        end
    end
    return actualItems
end

TABAS_DrySelfMenu.createMenu = function(player, context, items)
    if #items < 1 then return end

    local playerObj = getSpecificPlayer(player)
    if not TABAS_DrySelf.hasBathingWet(playerObj) then return end

    local actualItems = toInventoryItems(items)
    local towel = TABAS_Utils.getPreferredBathTowel(actualItems, true)
    if not towel then
        towel = TABAS_Utils.getPreferredBathTowel(actualItems, false)
    end
    if not towel then return end
    if context:getOptionFromName(getText("ContextMenu_Dry_myself")) then
        context:removeOptionByName(getText("ContextMenu_Dry_myself"))
    end

    local option = context:insertOptionAfter(getText("ContextMenu_PlaceItemOnGround"), getText("ContextMenu_Dry_myself"), towel, TABAS_DrySelfMenu.doDrySelf, player)
    local icon = towel:getIcon()
    option.iconTexture = icon
    if not TABAS_Utils.isAvailableBathTowel(towel) then
        option.notAvailable = true
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        tooltip.description = getText("IGUI_BathTowelsOverhaul_TowelTooWet")
        option.toolTip = tooltip
    end
end

TABAS_DrySelfMenu.onDryMyself = function(towels, player)
    local actualItems = ISInventoryPane.getActualItems(towels)
    local towel = TABAS_Utils.getPreferredBathTowel(actualItems, true)
    if towel then
        TABAS_DrySelfMenu.doDrySelf(towel, player)
    end
end

TABAS_DrySelfMenu.doDrySelf = function(towel, player)
    if not TABAS_Utils.isAvailableBathTowel(towel) then return end
    local playerObj = getSpecificPlayer(player)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, towel)

    ISTimedActionQueue.add(TABAS_DrySelf:new(playerObj, towel, true))
end

Events.OnFillInventoryObjectContextMenu.Add(TABAS_DrySelfMenu.createMenu)

return TABAS_DrySelfMenu
