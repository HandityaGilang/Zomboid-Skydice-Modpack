--***********************************************************
--**                LEMMY/ROBERT JOHNSON                   **
--***********************************************************

require "ISUI/ISToolTip"
require "ISUI/ISInventoryPaneContextMenu"

-- Keep legacy behavior: this version overrides doDrinkFluidMenu.
ISInventoryPaneContextMenu.doDrinkFluidMenu = function(playerObj, fluidContainer, context)
    -- Build the base "Drink" option.
    local cmd = fluidContainer:getCustomMenuOption() or getText("ContextMenu_Drink")
    local eatOption = context:addOption(cmd, fluidContainer, nil)

    -- Respect vanilla restrictions (sealed items, overeating moodle, etc.).
    if not fluidContainer:getFluidContainer():canPlayerEmpty() then
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        eatOption.notAvailable = true
        tooltip.description = getText("Tooltip_item_sealed")
        eatOption.toolTip = tooltip
    elseif playerObj:getMoodles():getMoodleLevel(MoodleType.FoodEaten) >= 3 then
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        eatOption.notAvailable = true
        tooltip.description = getText("Tooltip_CantEatMore")
        eatOption.toolTip = tooltip
    elseif fluidContainer:getFluidContainer():getCapacity() > 3.0 then
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        eatOption.notAvailable = true
        tooltip.description = getText("Tooltip_CantDrinkFrom")
        eatOption.toolTip = tooltip
    else
        -- Create the submenu with drink fractions.
        local subMenuEat = context:getNew(context)
        context:addSubMenu(eatOption, subMenuEat)

        local capacity = fluidContainer:getFluidContainer():getCapacity()
        local amount = fluidContainer:getFluidContainer():getAmount()
        local baseThirst = amount / capacity

        -- DRINK SMART: Add "0% Thirst" (legacy logic).
        local amountThirst = math.abs(fluidContainer:getFluidContainer():getProperties():getThirstChange())
        local thirst = playerObj:getStats():getThirst()

        if amountThirst > 0 then
            local ratioForThirst = thirst / amountThirst
            if ratioForThirst <= 1 then
                subMenuEat:addOption(("0 % " .. getText("Tooltip_food_Thirst")), fluidContainer, ISInventoryPaneContextMenu.onDrinkFluid, ratioForThirst, playerObj)
            else
                local opt = subMenuEat:addOption(("0 % " .. getText("Tooltip_food_Thirst")), fluidContainer, nil)
                local tooltip = ISInventoryPaneContextMenu.addToolTip()
                opt.notAvailable = true
                tooltip.description = getText("Tooltip_Not_enough_drink")
                opt.toolTip = tooltip
            end
        end

        -- Vanilla options.
        subMenuEat:addOption(getText("ContextMenu_Eat_All"), fluidContainer, ISInventoryPaneContextMenu.onDrinkFluid, 1, playerObj)
        if baseThirst >= 0.5 then
            subMenuEat:addOption(getText("ContextMenu_Eat_Half"), fluidContainer, ISInventoryPaneContextMenu.onDrinkFluid, 0.5, playerObj)
        end
        if baseThirst >= 0.25 then
            subMenuEat:addOption(getText("ContextMenu_Eat_Quarter"), fluidContainer, ISInventoryPaneContextMenu.onDrinkFluid, 0.25, playerObj)
        end
    end
end

-- Add the new sandbox behavior for legacy too: allow water drink menu below 10% thirst.
if not ISInventoryPaneContextMenu.__DrinkSmartLowThirstWrapped then
    ISInventoryPaneContextMenu.__DrinkSmartLowThirstWrapped = true

    local vanillaCreateMenu = ISInventoryPaneContextMenu.createMenu

    local DRINKSMART_DEBUG = false
    local function DrinkSmart_Log(...)
        if not DRINKSMART_DEBUG then return end
        local parts = {...}
        for i = 1, #parts do parts[i] = tostring(parts[i]) end
        print("[DrinkSmart] " .. table.concat(parts, " "))
    end

    -- Helper: detect a water source in the clicked items.
    local function DrinkSmart_FindWaterContainer(items)
        for _, v in ipairs(items or {}) do
            local testItem = v
            if testItem and not instanceof(testItem, "InventoryItem") and type(testItem) == "table" and testItem.items then
                testItem = testItem.items[1]
            end
            if testItem and testItem.isWaterSource and testItem:isWaterSource() then
                return testItem
            end
            if testItem and testItem.getWorldItem then
                local worldItem = testItem:getWorldItem()
                if worldItem and worldItem.getFluidContainer and worldItem:getFluidContainer() and worldItem:getFluidContainer():isWaterSource() then
                    return worldItem
                end
            end
        end
        return nil
    end


    -- Helper: find a top-level Drink/Open and Drink option for a specific target.
    local function DrinkSmart_FindTopDrinkOption(context, fluidContainer, startIndex)
        if not context or not context.options then return nil, nil end
        local first = startIndex or 1
        for i = first, #context.options do
            local opt = context.options[i]
            if opt and opt.target == fluidContainer and opt.subOption ~= nil then
                local name = opt.name
                if name == getText("ContextMenu_Drink") or name == getText("ContextMenu_OpenAndDrink") or fluidContainer:getCustomMenuOption() == name then
                    return opt, i
                end
            end
        end
        return nil, nil
    end

    -- Helper: move an existing top-level option before another option while preserving submenus.
    local function DrinkSmart_MoveOptionBefore(context, optionToMove, anchorOption)
        if not context or not context.options or not optionToMove or not anchorOption or optionToMove == anchorOption then return false end
        local fromIndex, toIndex = nil, nil
        for i, opt in ipairs(context.options) do
            if opt == optionToMove then fromIndex = i end
            if opt == anchorOption then toIndex = i end
            if fromIndex and toIndex then break end
        end
        if not fromIndex or not toIndex or fromIndex == toIndex then return false end
        if fromIndex < toIndex then
            -- Already before anchor; keep current order.
            return false
        end
        local moved = table.remove(context.options, fromIndex)
        table.insert(context.options, toIndex, moved)
        for i, opt in ipairs(context.options) do
            opt.id = i
        end
        if context.calcHeight then context:calcHeight() end
        if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
        return true
    end

    -- Helper: move an existing top-level option after another option while preserving submenus.
    local function DrinkSmart_MoveOptionAfter(context, optionToMove, anchorOption)
        if not context or not context.options or not optionToMove or not anchorOption or optionToMove == anchorOption then return false end
        local fromIndex, toIndex = nil, nil
        for i, opt in ipairs(context.options) do
            if opt == optionToMove then fromIndex = i end
            if opt == anchorOption then toIndex = i end
            if fromIndex and toIndex then break end
        end
        if not fromIndex or not toIndex or fromIndex == toIndex then return false end
        if fromIndex == toIndex + 1 then
            return false
        end
        local moved = table.remove(context.options, fromIndex)
        if fromIndex < toIndex then toIndex = toIndex - 1 end
        table.insert(context.options, toIndex + 1, moved)
        for i, opt in ipairs(context.options) do opt.id = i end
        if context.calcHeight then context:calcHeight() end
        if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
        return true
    end

    -- Helper: choose a "before" anchor when we inject Drink after vanilla has already built the menu.
    -- Priority after the equip-slot fallback (handled separately):
    --   1) recipe/craft-related options (e.g. "Clean Bandage" or a "Craft" submenu)
    --   2) the top-level "Fluid" submenu (B42.14+)
    --   3) older vanilla anchors usually placed after Drink
    local function DrinkSmart_FindVanillaDrinkAnchorBefore(context, injectedOption)
        if not context or not context.options then return nil end

        -- 1) Recipe/craft options inserted by the dynamic crafting context menu.
        --    This catches direct recipe entries (e.g. Clean Bandage) and the "Craft" submenu.
        for _, opt in ipairs(context.options) do
            if opt ~= injectedOption and opt then
                if opt.onSelect == ISInventoryPaneContextMenu.OnNewCraft then
                    return opt
                end
                if opt.subOption and opt.subOption.options then
                    for _, subOpt in ipairs(opt.subOption.options) do
                        if subOpt and subOpt.onSelect == ISInventoryPaneContextMenu.OnNewCraft then
                            return opt
                        end
                    end
                end
            end
        end

        -- 2) B42.14+ top-level Fluid submenu.
        local fluidMenuName = getText("ContextMenu_Fluid")
        for _, opt in ipairs(context.options) do
            if opt ~= injectedOption and opt and opt.name == fluidMenuName then
                return opt
            end
        end

        -- 3) Older/common vanilla anchors that usually appear after Drink.
        local anchorNames = {
            getText("ContextMenu_Pour_into"),
            getText("ContextMenu_Pour_on_Ground"),
            getText("ContextMenu_OpenAndEat"),
            getText("ContextMenu_Eat"),
            getText("ContextMenu_Take_pills"),
            getText("ContextMenu_Drop"),
            getText("ContextMenu_Move_To"),
            getText("ContextMenu_Unpack"),
            getText("IGUI_invpage_Transfer_all"),
            getText("IGUI_invpage_Loot_all"),
        }
        for _, wantedName in ipairs(anchorNames) do
            for _, opt in ipairs(context.options) do
                if opt ~= injectedOption and opt and opt.name == wantedName then
                    return opt
                end
            end
        end
        -- Fallback: place before top-level food consume entries even with custom labels (e.g. Smoke), if detectable.
        for _, opt in ipairs(context.options) do
            if opt ~= injectedOption and opt and opt.onSelect == ISInventoryPaneContextMenu.onEatItems then
                return opt
            end
        end
        return nil
    end

    -- Helper: if no later anchor exists, place Drink after the last equip-related option (close to vanilla slot).
    local function DrinkSmart_FindVanillaDrinkAnchorAfter(context, injectedOption)
        if not context or not context.options then return nil end
        local anchorNames = {
            getText("ContextMenu_Equip_Two_Hands"),
            getText("ContextMenu_Equip_Primary"),
            getText("ContextMenu_Equip_Secondary"),
        }
        local lastMatch = nil
        for _, opt in ipairs(context.options) do
            if opt ~= injectedOption and opt then
                for _, wantedName in ipairs(anchorNames) do
                    if opt.name == wantedName then
                        lastMatch = opt
                    end
                end
            end
        end
        return lastMatch
    end

    ISInventoryPaneContextMenu.createMenu = function(player, isInPlayerInventory, items, x, y, origin)
        DrinkSmart_Log("[Legacy] createMenu start", "player=", player, "items=", items and #items or "nil")

        local context = nil
        if vanillaCreateMenu then
            context = vanillaCreateMenu(player, isInPlayerInventory, items, x, y, origin)
        end
        if not context then
            DrinkSmart_Log("[Legacy] createMenu vanilla returned nil")
            return context
        end

        local ok, err = pcall(function()
            if not SandboxVars or not SandboxVars.DrinkSmart or not SandboxVars.DrinkSmart.AllowWaterDrinkLowThirst then
                return
            end

            local playerObj = getSpecificPlayer(player)
            if not playerObj then return end

            local thirst = playerObj:getStats():getThirst()
            if thirst == nil or thirst > 0.1 then return end

            local drinkText = getText("ContextMenu_Drink")
            for _, opt in ipairs(context.options or {}) do
                if opt and opt.name == drinkText then
                    return
                end
            end

            local waterContainer = DrinkSmart_FindWaterContainer(items)
            if not waterContainer then
                DrinkSmart_Log("[Legacy] low-thirst path: no water container")
                return
            end

            DrinkSmart_Log("[Legacy] low-thirst path: injecting drink menu")
            local beforeCount = #context.options
            ISInventoryPaneContextMenu.doDrinkFluidMenu(playerObj, waterContainer, context)

            -- Reposition the injected top-level Drink option near vanilla's usual slot.
            local injectedOption = nil
            local injectedIndex = nil
            injectedOption, injectedIndex = DrinkSmart_FindTopDrinkOption(context, waterContainer, beforeCount + 1)
            if not injectedOption then
                injectedOption, injectedIndex = DrinkSmart_FindTopDrinkOption(context, waterContainer, 1)
            end
            if injectedOption then
                -- Priority: after Equip (closest to vanilla) -> before recipe/craft/Fluid -> fallback anchors.
                local afterAnchor = DrinkSmart_FindVanillaDrinkAnchorAfter(context, injectedOption)
                if afterAnchor and DrinkSmart_MoveOptionAfter(context, injectedOption, afterAnchor) then
                    DrinkSmart_Log("[Legacy] low-thirst path: moved drink option after", afterAnchor.name or "?")
                else
                    local beforeAnchor = DrinkSmart_FindVanillaDrinkAnchorBefore(context, injectedOption)
                    if beforeAnchor and DrinkSmart_MoveOptionBefore(context, injectedOption, beforeAnchor) then
                        DrinkSmart_Log("[Legacy] low-thirst path: moved drink option before", beforeAnchor.name or "?")
                    else
                        DrinkSmart_Log("[Legacy] low-thirst path: no anchor/move needed")
                    end
                end
            else
                DrinkSmart_Log("[Legacy] low-thirst path: injected option not found for reposition")
            end
        end)

        if not ok then
            print("[DrinkSmart] [Legacy] createMenu wrapper error: " .. tostring(err))
        end

        return context
    end
end
