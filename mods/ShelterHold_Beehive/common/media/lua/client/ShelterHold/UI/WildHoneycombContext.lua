require "TimedActions/ISBaseTimedAction"

local function onWildHoneyComb(player, item)

    ISInventoryPaneContextMenu.transferIfNeeded(player, item)

    ISTimedActionQueue.add(Hold_DisassembleCombAction:new(player, item))
end

local function onFillInventoryObjectContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    for i, item in ipairs(items) do
        local itemTarget = item

        if item.items then
            itemTarget = item.items[1]
        end
        
        if itemTarget and itemTarget:getFullType() == "Hold.WildHoneyComb" then
            local option = context:addOption(getText("IGUI_Hold_Beehive_DisassembleComb"), player, onWildHoneyComb, itemTarget)
            option.iconTexture = getTexture("media/textures/item_WildHoneyComb.png")

            local tooltip = ISToolTip:new()
            tooltip:initialise()
            tooltip:setVisible(false)
            tooltip.description = getText("Tooltip_Beehive_DisassembleComb")
            option.toolTip = tooltip
            break
        end
    end
end

Events.OnPreFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)