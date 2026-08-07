-- FirefighterUniform_ContextMenu
-- written by Jusblazm
local function onFillInventoryObjectContextMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)

    for _, v in ipairs(items) do
        local item = v.items and v.items[1] or v
        if not item then return end

        if item:getFullType() == "Base.Emergency_Axe_HeavySwing" then
            context:addOption(getText("ContextMenu_EmergencyAxeQuickSwing"), item, function()
                ISTimedActionQueue.add(FirefighterUniform_SwapAxeTypeAction:new(player, item))
            end)

        elseif item:getFullType() == "Base.Emergency_Axe_QuickSwing" then
            context:addOption(getText("ContextMenu_EmergencyAxeHeavySwing"), item, function()
                ISTimedActionQueue.add(FirefighterUniform_SwapAxeTypeAction:new(player, item))
            end)
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)