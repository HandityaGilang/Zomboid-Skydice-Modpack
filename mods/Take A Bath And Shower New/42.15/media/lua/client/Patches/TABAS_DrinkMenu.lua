require "ISUI/ISWorldObjectContextMenu"

-- For Do Drink Menu with Bath Salt in Tub Fluid Container
local TABAS_DrinkMenu = {}

function TABAS_DrinkMenu.apply()
    if TABAS_DrinkMenu._applied then return end
    TABAS_DrinkMenu._applied = true

    local old_doDrinkWaterMenu = ISWorldObjectContextMenu.doDrinkWaterMenu
    local doDrinkWaterMenu = function(object, player, context)
        old_doDrinkWaterMenu(object, player, context)
        if not object:getModData() or not object:getModData().bathSalt then return end

        local option = context:getOptionFromName(getText("ContextMenu_Drink"))
        if not option then return end

        local tooltip = option.toolTip
        if getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() then
            tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater")
            option.toolTip = tooltip
        end
    end
    ISWorldObjectContextMenu.doDrinkWaterMenu = doDrinkWaterMenu
end

return TABAS_DrinkMenu
