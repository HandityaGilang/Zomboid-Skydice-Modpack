require "Neat_Crafting/NC_ModOptions"

NC_InventorySearch = {}

-- Search recipes by input ingredient
function NC_InventorySearch.searchAsInput(item, playerIndex)
    local player = getSpecificPlayer(playerIndex)
    local itemName = item:getScriptItem():getDisplayName()
    
    NC_InventorySearch.pendingSearch = {
        mode = "InputName", 
        text = itemName
    }
    
    ISEntityUI.OpenHandcraftWindow(player, nil)
end

-- Search recipes by output item
function NC_InventorySearch.searchAsOutput(item, playerIndex)
    local player = getSpecificPlayer(playerIndex)
    local itemName = item:getScriptItem():getDisplayName()
    
    NC_InventorySearch.pendingSearch = {
        mode = "OutputName", 
        text = itemName
    }
    
    ISEntityUI.OpenHandcraftWindow(player, nil)
end

function NC_InventorySearch.onFillInventoryObjectContextMenu(playerIndex, contextMenu, items)
    
    -- If Neat Crafting UI is disabled, do not add context menu entries.
    if not NC_isNeatCraftingUIEnabled() then return end
if not items or #items < 1 then return end

    local baseItem = items[1]
    if not baseItem then
        return
    elseif not instanceof(baseItem, "InventoryItem") then
        baseItem = baseItem.items[1]
    end

    local mainOption = contextMenu:addOption(getText("IGUI_NC_SearchForCraft"), baseItem)
    mainOption.iconTexture = getTexture("media/ui/Neat_Crafting/ICON/CraftingBase.png")

    local subMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(mainOption, subMenu)

    local asInputOption = subMenu:addOption(getText("IGUI_NC_SearchAsInput"), baseItem, NC_InventorySearch.searchAsInput, playerIndex)
    asInputOption.iconTexture = getTexture("media/ui/Neat_Crafting/ICON/Blue.png")
    local asOutputOption = subMenu:addOption(getText("IGUI_NC_SearchAsOutput"), baseItem, NC_InventorySearch.searchAsOutput, playerIndex)
    asOutputOption.iconTexture = getTexture("media/ui/Neat_Crafting/ICON/Orange.png")

end

Events.OnFillInventoryObjectContextMenu.Add(NC_InventorySearch.onFillInventoryObjectContextMenu)