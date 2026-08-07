--***********************************************************
--**                LEMMY/ROBERT JOHNSON                   **
--***********************************************************

require "ISUI/ISToolTip"
require "ISUI/ISInventoryPaneContextMenu"

-- Cache vanilla functions so we keep future bugfixes/changes made by the game (or other mods loaded before this one).
-- We also guard against double-wrapping in case the file is required more than once.
if not ISInventoryPaneContextMenu.__DrinkSmartWrapped then
    ISInventoryPaneContextMenu.__DrinkSmartWrapped = true

    local vanillaDoDrinkFluidMenu = ISInventoryPaneContextMenu.doDrinkFluidMenu
    local vanillaCreateMenu = ISInventoryPaneContextMenu.createMenu

    -- Temporary debug logging (set to false to reduce spam).
    local DRINKSMART_DEBUG = false
    local function DrinkSmart_Log(...)
        if not DRINKSMART_DEBUG then return end
        local parts = {...}
        for i = 1, #parts do parts[i] = tostring(parts[i]) end
        print("[DrinkSmart] " .. table.concat(parts, " "))
    end

    -- Helper: safe thirst getter across different Build 42 sub-versions.
    local function DrinkSmart_GetThirst(playerObj)
        -- Get the stats object (can be nil in edge cases).
        local stats = playerObj and playerObj.getStats and playerObj:getStats() or nil
        if not stats then return nil end

        -- Prefer the CharacterStat.THIRST getter used by newer builds.
        if CharacterStat and CharacterStat.THIRST and stats.get then
            local ok, value = pcall(function()
                -- Read thirst from the enum-based stats API.
                return stats:get(CharacterStat.THIRST)
            end)
            if ok and value ~= nil then
                return value
            end
        end

        -- Fallback for older stats APIs.
        if stats.getThirst then
            return stats:getThirst()
        end

        return nil
    end

    -- Helper: detect a water source in the clicked items (mirrors vanilla tests.waterContainer logic).
    local function DrinkSmart_FindWaterContainer(items)
        -- Iterate items as vanilla does (items can be InventoryItem or a table with .items).
        for _, v in ipairs(items or {}) do
            local testItem = v
            if testItem and not instanceof(testItem, "InventoryItem") and type(testItem) == "table" and testItem.items then
                testItem = testItem.items[1]
            end
            if testItem and testItem.isWaterSource and testItem:isWaterSource() then
                return testItem
            end

            -- Ground/world-panel items often have a backing IsoWorldInventoryObject.
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
            -- Already immediately after anchor.
            return false
        end
        local moved = table.remove(context.options, fromIndex)
        if fromIndex < toIndex then
            -- After removing from before anchor, the anchor shifts left by one.
            toIndex = toIndex - 1
        end
        table.insert(context.options, toIndex + 1, moved)
        for i, opt in ipairs(context.options) do
            opt.id = i
        end
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
    -- 1) Wrap vanilla doDrinkFluidMenu to inject the "0% Thirst" option into the submenu.
    ISInventoryPaneContextMenu.doDrinkFluidMenu = function(playerObj, fluidContainer, context)
        DrinkSmart_Log("doDrinkFluidMenu start", "player=", playerObj and playerObj:getUsername() or "nil", "fluidContainer=", fluidContainer and (fluidContainer.getDisplayName and fluidContainer:getDisplayName() or tostring(fluidContainer)) or "nil")
        -- First, let vanilla build the menu (this keeps any new vanilla options/logic intact).
        if vanillaDoDrinkFluidMenu then
            vanillaDoDrinkFluidMenu(playerObj, fluidContainer, context)
        end

        -- Defensive checks to avoid nil crashes.
        if not fluidContainer or not fluidContainer.getFluidContainer or not fluidContainer:getFluidContainer() then DrinkSmart_Log("doDrinkFluidMenu abort: invalid fluidContainer") return end
        if not playerObj or not context or not context.options then DrinkSmart_Log("doDrinkFluidMenu abort: invalid player/context") return end

        -- Resolve the real InventoryItem behind IsoWorldInventoryObject (used for textures and opening recipes).
        local realItem = instanceof(fluidContainer, "IsoWorldInventoryObject") and fluidContainer:getItem() or fluidContainer
        if not realItem then DrinkSmart_Log("doDrinkFluidMenu abort: no realItem") return end

        -- Find the submenu created by vanilla for this fluidContainer.
        -- We match by target + itemForTexture to avoid grabbing unrelated "Drink" options.
        local drinkOption = nil
        for _, opt in ipairs(context.options) do
            if opt
                and opt.target == fluidContainer
                and opt.itemForTexture == realItem
                and opt.subOption ~= nil then
                drinkOption = opt
                break
            end
        end
        if not drinkOption or drinkOption.notAvailable or not drinkOption.subOption then DrinkSmart_Log("doDrinkFluidMenu abort: no vanilla drink submenu found") return end

        local subMenu = context:getSubMenu(drinkOption.subOption)
        if not subMenu then DrinkSmart_Log("doDrinkFluidMenu abort: submenu lookup failed") return end

        -- Build the label (auto-localized via the game's vocabulary).
        local smartLabel = "0% " .. getText("Tooltip_food_Thirst")

        -- Avoid duplicates if another mod (or a reload) already added it.
        if subMenu.getOptionFromName and subMenu:getOptionFromName(smartLabel) then DrinkSmart_Log("doDrinkFluidMenu skip: smart option already exists") return end

        -- Compute opening recipe (mirrors vanilla logic, so sealed containers use "Open and Drink").
        local openingRecipe = nil
        local openingRecipeName = realItem:getOpeningRecipe()
        if realItem:isSealed()
            and openingRecipeName
            and getScriptManager():getCraftRecipe(openingRecipeName) then

            openingRecipe = getScriptManager():getCraftRecipe(openingRecipeName)

            -- Check if the player can actually perform the opening recipe.
            local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
            local logic = HandcraftLogic.new(playerObj, nil, nil)
            logic:setContainers(containers)
            logic:setRecipeFromContextClick(openingRecipe, realItem)
            if not logic:canPerformCurrentRecipe() then
                openingRecipe = nil
            end
        end

        -- Only show the option when it makes sense (player is thirsty and the drink reduces thirst).
        local thirst = DrinkSmart_GetThirst(playerObj)
        local thirstChange = fluidContainer:getFluidContainer():getProperties():getThirstChange()

        -- Note: thirstChange is negative when it reduces thirst.
        if not thirst or thirst <= 0 or not thirstChange or thirstChange >= 0 then DrinkSmart_Log("doDrinkFluidMenu skip: thirst/thirstChange condition", "thirst=", thirst, "thirstChange=", thirstChange) return end

        local amountThirst = math.abs(thirstChange)
        if amountThirst <= 0 then DrinkSmart_Log("doDrinkFluidMenu skip: amountThirst <= 0") return end

        -- "needed" is the fraction of the current content required to reach 0 thirst.
        local needed = thirst / amountThirst
        local percent = math.max(0, math.min(1, needed)) -- Clamp to [0..1]

        -- Insert above the vanilla "All" option when possible, otherwise it will be added at the end.
        local insertBefore = getText("ContextMenu_Eat_All")

        if needed <= 1 then
            if subMenu.insertOptionBefore then
                DrinkSmart_Log("doDrinkFluidMenu add smart option", "percent=", percent, "needed=", needed)
                subMenu:insertOptionBefore(
                    insertBefore,
                    smartLabel,
                    fluidContainer,
                    ISInventoryPaneContextMenu.onDrinkFluid,
                    percent,
                    playerObj,
                    openingRecipe,
                    realItem
                )
            else
                -- Fallback: just add the option at the end if insertOptionBefore doesn't exist.
                DrinkSmart_Log("doDrinkFluidMenu add smart option fallback", "percent=", percent, "needed=", needed)
                subMenu:addOption(smartLabel, fluidContainer, ISInventoryPaneContextMenu.onDrinkFluid, percent, playerObj, openingRecipe, realItem)
            end
        else
            DrinkSmart_Log("doDrinkFluidMenu add disabled smart option", "needed=", needed)
            local opt = subMenu.insertOptionBefore
                and subMenu:insertOptionBefore(insertBefore, smartLabel, fluidContainer, nil)
                or subMenu:addOption(smartLabel, fluidContainer, nil)

            local tooltip = ISInventoryPaneContextMenu.addToolTip()
            opt.notAvailable = true
            tooltip.description = getText("Tooltip_Not_enough_drink")
            opt.toolTip = tooltip
        end
    end

    -- 2) Wrap vanilla createMenu to optionally allow water sources to show the Drink menu below 10% thirst.
    ISInventoryPaneContextMenu.createMenu = function(player, isInPlayerInventory, items, x, y, origin)
        DrinkSmart_Log("createMenu start", "player=", player, "items=", items and #items or "nil", "x=", x, "y=", y)

        local context = nil
        if vanillaCreateMenu then
            context = vanillaCreateMenu(player, isInPlayerInventory, items, x, y, origin)
        end

        -- IMPORTANT: preserve vanilla return semantics (many callers expect the returned context object).
        if not context then
            DrinkSmart_Log("createMenu vanilla returned nil")
            return context
        end

        -- Run our extra low-thirst water logic safely so a mod bug never kills the entire context menu.
        local ok, err = pcall(function()
            if not SandboxVars or not SandboxVars.DrinkSmart or not SandboxVars.DrinkSmart.AllowWaterDrinkLowThirst then
                DrinkSmart_Log("createMenu low-thirst option disabled")
                return
            end

            local playerObj = getSpecificPlayer(player)
            if not playerObj then
                DrinkSmart_Log("createMenu abort: no playerObj")
                return
            end

            local thirst = DrinkSmart_GetThirst(playerObj)
            if thirst == nil or thirst > 0.1 then
                -- Outside the low-thirst window; vanilla already handled normal cases.
                return
            end

            DrinkSmart_Log("createMenu low-thirst path", "thirst=", thirst, "numOptions=", context.numOptions)

            -- Avoid duplicates if any "Drink" entry already exists.
            local drinkText = getText("ContextMenu_Drink")
            local openDrinkText = getText("ContextMenu_OpenAndDrink")
            for _, opt in ipairs(context.options or {}) do
                if opt and (opt.name == drinkText or opt.name == openDrinkText) then
                    DrinkSmart_Log("createMenu skip: drink option already exists", "name=", opt.name)
                    return
                end
            end

            local waterContainer = DrinkSmart_FindWaterContainer(items)
            if not waterContainer then
                DrinkSmart_Log("createMenu low-thirst path: no water container found")
                return
            end

            DrinkSmart_Log("createMenu low-thirst path: injecting drink menu")
            local beforeCount = #context.options
            -- Delegate to the (wrapped) drink menu builder.
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
                    DrinkSmart_Log("createMenu low-thirst path: moved drink option after", afterAnchor.name or "?")
                else
                    local beforeAnchor = DrinkSmart_FindVanillaDrinkAnchorBefore(context, injectedOption)
                    if beforeAnchor and DrinkSmart_MoveOptionBefore(context, injectedOption, beforeAnchor) then
                        DrinkSmart_Log("createMenu low-thirst path: moved drink option before", beforeAnchor.name or "?")
                    else
                        DrinkSmart_Log("createMenu low-thirst path: no anchor/move needed")
                    end
                end
            else
                DrinkSmart_Log("createMenu low-thirst path: injected option not found for reposition")
            end
        end)

        if not ok then
            print("[DrinkSmart] createMenu wrapper error: " .. tostring(err))
        end

        return context
    end
end
