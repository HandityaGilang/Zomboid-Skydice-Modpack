require "ISUI/ISInventoryPaneContextMenu"

if not CleanUI_DrinkFluidMenuPatch_Applied then
    CleanUI_DrinkFluidMenuPatch_Applied = true

    local CleanUI_doDrinkFluidMenu_Orig = ISInventoryPaneContextMenu.doDrinkFluidMenu

    ISInventoryPaneContextMenu.doDrinkFluidMenu = function(playerObj, fluidContainer, context)
        if not fluidContainer then return end

        local isWorldItem = instanceof(fluidContainer, "IsoWorldInventoryObject")
        local item = isWorldItem and fluidContainer:getItem() or fluidContainer
        if not item then return end
        if not item.getFluidContainer or not item:getFluidContainer() then return end

        -- Normalize to the actual InventoryItem before vanilla checks getJobDelta()/getJobType().
        return CleanUI_doDrinkFluidMenu_Orig(playerObj, item, context)
    end
end
