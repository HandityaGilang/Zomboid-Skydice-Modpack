local TABAS_ContextMenuVanillaFluid = {}

local function predicateFillTarget(item)
    if not item then return false end
    local itemFluidContainer = item:getFluidContainer()
    return itemFluidContainer ~= nil and not itemFluidContainer:isFull() and itemFluidContainer:canAddFluid(Fluid.Water)
end

local function predicateWashableClothing(item)
    return item and not item:isHidden() and (item:hasBlood() or item:hasDirt()) and not item:hasTag(ItemTag.BREAK_WHEN_WET)
end

local function predicateWashableContainer(item)
    return item and not item:isHidden() and (item:hasBlood() or item:hasDirt())
end

local function predicateWashableWeapon(item)
    return item and item:hasBlood()
end

local function predicateWashableBandage(item)
    return item and item:hasTag(ItemTag.CAN_BE_WASHED) and item:getJobDelta() == 0
end

local function collectInventoryItems(playerObj, predicate)
    local items = {}
    local javaList = playerObj:getInventory():getAllEvalRecurse(predicate)
    if not javaList then return items end

    for i = 0, javaList:size() - 1 do
        items[#items + 1] = javaList:get(i)
    end

    return items
end

local function compareRequiredSoap(itemA, itemB)
    return ISWashClothing.GetRequiredSoap(itemA) < ISWashClothing.GetRequiredSoap(itemB)
end

local function appendItems(target, source)
    for i = 1, #source do
        target[#target + 1] = source[i]
    end
end

local function collectCategoryItems(playerObj, category, predicate)
    local items = {}
    local javaList = playerObj:getInventory():getItemsFromCategory(category)
    if not javaList then return items end

    for i = 0, javaList:size() - 1 do
        local item = javaList:get(i)
        if not predicate or predicate(item) then
            items[#items + 1] = item
        end
    end

    return items
end

local function collectTaggedItems(playerObj, tag, predicate)
    local items = {}
    local javaList = playerObj:getInventory():getAllTag(tag)
    if not javaList then return items end

    for i = 0, javaList:size() - 1 do
        local item = javaList:get(i)
        if not predicate or predicate(item) then
            items[#items + 1] = item
        end
    end

    return items
end

local function groupItemsByName(items)
    table.sort(items, function(a, b)
        return not string.sort(a:getName(), b:getName())
    end)

    local groupedItems = {}
    local itemGroup = {}
    local previousItem = nil

    for _, item in ipairs(items) do
        if previousItem and item:getName() ~= previousItem:getName() then
            groupedItems[#groupedItems + 1] = itemGroup
            itemGroup = {}
        end
        itemGroup[#itemGroup + 1] = item
        previousItem = item
    end

    if #itemGroup > 0 then
        groupedItems[#groupedItems + 1] = itemGroup
    end

    return groupedItems
end

local function formatWaterAmount(amount, capacity)
    if capacity >= 9999 then
        return getText("Tooltip_WaterUnlimited")
    end
    return string.format("%sL / %sL", luautils.round(amount, 2), luautils.round(capacity, 2))
end

local function createWaterSourceTooltip(bathingObj)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local source = nil

    if instanceof(bathingObj, "IsoWorldInventoryObject") then
        source = bathingObj:getItem():getName()
    else
        source = tostring(ISWorldObjectContextMenu.getMoveableDisplayName(bathingObj))
        if source == "nil" then
            source = getText("ContextMenu_NaturalWaterSource")
        end
    end

    if bathingObj:isTaintedWater() and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() then
        tooltip.description = "<RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater")
    end

    tooltip.maxLineWidth = 512
    if tooltip.description == "" then
        return nil
    end
    return tooltip
end

local function applyFillOptionWaterSourceTooltip(option, bathingObj)
    if not option then return end
    option.toolTip = createWaterSourceTooltip(bathingObj)
end

local function applySingleFillTooltip(option, item, bathingObj)
    if not option or not item then return end
    local waterSourceTooltip = createWaterSourceTooltip(bathingObj)
    if waterSourceTooltip then
        if instanceof(item, "DrainableComboItem") then
            waterSourceTooltip.description = string.format("%s <LINE> %s: %d/10",
                waterSourceTooltip.description,
                getText("ContextMenu_ItemWaterCapacity"),
                math.floor(item:getCurrentUsesFloat() * 10.0))
        end
        option.toolTip = waterSourceTooltip
        return
    end
    option.toolTip = ISWorldObjectContextMenu.addToolTipInv(item)
end

local function applyFillTargetTexture(option, item)
    if not option or not item then return end
    option.itemForTexture = item
end

function TABAS_ContextMenuVanillaFluid.doDrinkMenu(player, bathingObj, context, playerObj, worldObjects)
    local option = context:addOption(getText("ContextMenu_Drink"), worldObjects, ISWorldObjectContextMenu.onDrink, bathingObj, player)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local thirst = playerObj:getStats():get(CharacterStat.THIRST)
    local waterAmount = bathingObj:getFluidAmount()
    local waterCapacity = bathingObj:getFluidCapacity()
    local thirstDelta = math.min(waterAmount * 10, thirst * 100)
    local waterLabel = bathingObj:getFluidUiName() or getText("ContextMenu_WaterName")
    local tx = getTextManager():MeasureStringX(tooltip.font, waterLabel .. ":") + 20

    tooltip.description = string.format("%s: <SETX:%d> %s", waterLabel, tx, formatWaterAmount(waterAmount, waterCapacity))
    -- tooltip.description = tooltip.description .. "<LINE>" .. string.format("%s: <SETX:%d> -%d / %d", getText("Tooltip_food_Thirst"), tx, thirstDelta, thirst * 100)

    if bathingObj:isTaintedWater() and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() then
        tooltip.description = tooltip.description .. " <BR> <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater")
    end
    option.toolTip = tooltip
end

function TABAS_ContextMenuVanillaFluid.doFillMenu(player, bathingObj, context, playerObj, worldObjects)
    local containers = collectInventoryItems(playerObj, predicateFillTarget)
    local validContainers = {}

    for i = 1, #containers do
        local item = containers[i]
        local itemFluidContainer = item and item:getFluidContainer()
        if itemFluidContainer and bathingObj:canTransferFluidTo(itemFluidContainer) then
            validContainers[#validContainers + 1] = item
        end
    end

    containers = validContainers
    if #containers == 0 then return end

    if #containers == 1 then
        local option = context:addOption(getText("ContextMenu_Fill"), worldObjects, ISWorldObjectContextMenu.onTakeWater, bathingObj, nil, containers[1], player)
        applyFillTargetTexture(option, containers[1])
        applySingleFillTooltip(option, containers[1], bathingObj)
        return
    end

    local fillOption = context:addOption(getText("ContextMenu_Fill"))
    local fillSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(fillOption, fillSubMenu)
    local fillAllOption = fillSubMenu:addOption(getText("ContextMenu_FillAll"), worldObjects, ISWorldObjectContextMenu.onTakeWater, bathingObj, containers, nil, player)
    applyFillOptionWaterSourceTooltip(fillAllOption, bathingObj)

    local groupedContainers = groupItemsByName(containers)
    for _, containerGroup in ipairs(groupedContainers) do
        local item = containerGroup[1]
        if #containerGroup > 1 then
            local groupOption = fillSubMenu:addOption(item:getName() .. " (" .. #containerGroup .. ")", worldObjects, nil)
            applyFillTargetTexture(groupOption, item)

            local groupSubMenu = ISContextMenu:getNew(fillSubMenu)
            fillSubMenu:addSubMenu(groupOption, groupSubMenu)

            local fillOneOption = groupSubMenu:addOption(getText("ContextMenu_FillOne"), worldObjects, ISWorldObjectContextMenu.onTakeWater, bathingObj, nil, item, player)
            applyFillTargetTexture(fillOneOption, item)
            applyFillOptionWaterSourceTooltip(fillOneOption, bathingObj)

            local fillAllOption = groupSubMenu:addOption(getText("ContextMenu_FillAll"), worldObjects, ISWorldObjectContextMenu.onTakeWater, bathingObj, containerGroup, nil, player)
            applyFillTargetTexture(fillAllOption, item)
            applyFillOptionWaterSourceTooltip(fillAllOption, bathingObj)
        else
            local option = fillSubMenu:addOption(item:getName(), worldObjects, ISWorldObjectContextMenu.onTakeWater, bathingObj, nil, item, player)
            applyFillTargetTexture(option, item)
            applySingleFillTooltip(option, item, bathingObj)
        end
    end
end

local function createWashGroupTooltip(soapRemaining, waterRemaining, items)
    local soapRequired, waterRequired = ISWorldObjectContextMenu.calculateSoapAndWaterRequired(items)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local description = tooltip.description or ""

    if soapRemaining < soapRequired then
        description = description .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
    else
        description = string.format("%s%s: %.2f / %.0f <LINE> ", description, getText("IGUI_Washing_Soap"), math.min(soapRemaining, soapRequired), soapRequired)
    end

    description = string.format("%s%s: %.2f / %.0f", description, getText("ContextMenu_WaterName"), math.min(waterRemaining, waterRequired), waterRequired)

    tooltip.description = description
    return tooltip, waterRequired
end

local function createWashItemTooltip(item, soapRemaining, waterRemaining)
    local soapRequired = ISWashClothing.GetRequiredSoap(item)
    local waterRequired = ISWashClothing.GetRequiredWater(item)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local description = tooltip.description or ""

    if soapRemaining < soapRequired then
        description = description .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
    else
        description = string.format("%s%s: %.0f / %.0f <LINE> ", description, getText("IGUI_Washing_Soap"), math.min(soapRemaining, soapRequired), soapRequired)
    end

    description = string.format("%s%s: %.2f / %.0f", description, getText("ContextMenu_WaterName"), math.min(waterRemaining, waterRequired), waterRequired)

    if (instanceof(item, "Clothing") or instanceof(item, "InventoryContainer") or item:IsWeapon()) and item:getBloodLevel() > 0 then
        description = string.format("%s <LINE> %s: %.0f / 100", description, getText("Tooltip_clothing_bloody"), math.ceil(item:getBloodLevelAdjustedHigh()))
    end

    if instanceof(item, "Clothing") and item:getDirtiness() > 0 then
        description = string.format("%s <LINE> %s: %.0f / 100", description, getText("Tooltip_clothing_dirty"), math.ceil(item:getDirtiness()))
    end

    tooltip.description = description
    return tooltip, waterRequired
end

local function addWashGroupOption(menu, label, items, soapList, playerObj, bathingObj, soapRemaining, waterRemaining)
    if #items == 0 then return end

    local option = menu:addOption(label, playerObj, ISWorldObjectContextMenu.onWashClothing, bathingObj, soapList, items, nil)
    local tooltip, waterRequired = createWashGroupTooltip(soapRemaining, waterRemaining, items)
    option.toolTip = tooltip
    if waterRemaining < waterRequired then
        option.notAvailable = true
    end
end

local function addWashItemOption(menu, item, soapList, playerObj, bathingObj, soapRemaining, waterRemaining)
    local option = menu:addOption(getText("ContextMenu_WashClothing", item:getDisplayName()), playerObj, ISWorldObjectContextMenu.onWashClothing, bathingObj, soapList, nil, item)
    local tooltip, waterRequired = createWashItemTooltip(item, soapRemaining, waterRemaining)
    option.toolTip = tooltip
    option.itemForTexture = item
    if waterRemaining < waterRequired then
        option.notAvailable = true
    end
end

local function createWashYourselfTooltip(playerObj, soapRemaining, soapRequired, waterRemaining, waterRequired)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local description = tooltip.description or ""

    if soapRemaining < soapRequired then
        description = string.format("%s%s <LINE> ", description, getText("IGUI_Washing_WithoutSoap"))
    else
        description = string.format("%s%s: %.2f / %.2f <LINE> ", description, getText("IGUI_Washing_Soap"), math.min(soapRemaining, soapRequired), soapRequired)
    end

    description = string.format("%s%s: %.2f / %.2f", description, getText("ContextMenu_WaterName"), math.min(waterRemaining, waterRequired), waterRequired)

    local visual = playerObj:getHumanVisual()
    local bodyBlood = 0
    local bodyDirt = 0
    local maxIndex = BloodBodyPartType.MAX:index()

    for i = 0, maxIndex - 1 do
        local part = BloodBodyPartType.FromIndex(i)
        bodyBlood = bodyBlood + visual:getBlood(part)
        bodyDirt = bodyDirt + visual:getDirt(part)
    end

    if bodyBlood > 0 then
        description = string.format("%s <LINE> %s: %.0f / 100", description, getText("Tooltip_clothing_bloody"), math.ceil(bodyBlood / maxIndex * 100.0))
    end

    if bodyDirt > 0 then
        description = string.format("%s <LINE> %s: %.0f / 100", description, getText("Tooltip_clothing_dirty"), math.ceil(bodyDirt / maxIndex * 100.0))
    end

    tooltip.description = description
    return tooltip
end

local function addWashYourselfOption(menu, playerObj, bathingObj, waterRemaining)
    local soapList = playerObj:getInventory():getSoapList(nil, false)
    local soapRemaining = ISWashYourself.GetSoapRemaining(soapList)
    local soapRequired = ISWashYourself.GetRequiredSoap(playerObj)
    local waterRequired = ISWashYourself.GetRequiredWater(playerObj)
    local option = menu:addGetUpOption(getText("ContextMenu_Yourself"), playerObj, ISWorldObjectContextMenu.onWashYourself, bathingObj, soapList)
    option.toolTip = createWashYourselfTooltip(playerObj, soapRemaining, soapRequired, waterRemaining, waterRequired)
    if waterRemaining < 1 then
        option.notAvailable = true
    end
end

function TABAS_ContextMenuVanillaFluid.doWashMenu(player, bathingObj, context, playerObj)
    local canWashSelf = ISWashYourself.GetRequiredWater(playerObj) > 0
    local soapList = playerObj:getInventory():getSoapList(nil, true)
    local soapRemaining = ISWashClothing.GetSoapRemaining(soapList)
    local waterRemaining = bathingObj:getFluidAmount()
    local clothingItems = collectCategoryItems(playerObj, "Clothing", predicateWashableClothing)
    local containerItems = collectCategoryItems(playerObj, "Container", predicateWashableContainer)
    local weaponItems = collectCategoryItems(playerObj, "Weapon", predicateWashableWeapon)
    local bandageItems = collectTaggedItems(playerObj, ItemTag.CAN_BE_WASHED, predicateWashableBandage)
    local washItems = {}

    table.sort(clothingItems, compareRequiredSoap)
    table.sort(containerItems, compareRequiredSoap)
    table.sort(weaponItems, compareRequiredSoap)
    table.sort(bandageItems, compareRequiredSoap)
    appendItems(washItems, clothingItems)
    appendItems(washItems, bandageItems)
    appendItems(washItems, weaponItems)
    appendItems(washItems, containerItems)
    table.sort(washItems, compareRequiredSoap)

    if not canWashSelf and #clothingItems == 0 and #containerItems == 0 and #weaponItems == 0 and #bandageItems == 0 then
        ISWorldObjectContextMenu.doRecipeUsingWaterMenu(bathingObj, player, context)
        return
    end

    local washOption = context:addOption(getText("ContextMenu_Wash"))
    local washSubMenu = ISContextMenu:getNew(context)
    context:addSubMenu(washOption, washSubMenu)

    if canWashSelf then
        addWashYourselfOption(washSubMenu, playerObj, bathingObj, waterRemaining)
    end

    addWashGroupOption(washSubMenu, getText("ContextMenu_WashAllClothing"), clothingItems, soapList, playerObj, bathingObj, soapRemaining, waterRemaining)
    addWashGroupOption(washSubMenu, getText("ContextMenu_WashAllContainer"), containerItems, soapList, playerObj, bathingObj, soapRemaining, waterRemaining)
    addWashGroupOption(washSubMenu, getText("ContextMenu_WashAllWeapon"), weaponItems, soapList, playerObj, bathingObj, soapRemaining, waterRemaining)
    addWashGroupOption(washSubMenu, getText("ContextMenu_WashAllBandage"), bandageItems, soapList, playerObj, bathingObj, soapRemaining, waterRemaining)

    for i = 1, #washItems do
        addWashItemOption(washSubMenu, washItems[i], soapList, playerObj, bathingObj, soapRemaining, waterRemaining)
    end

    ISWorldObjectContextMenu.doRecipeUsingWaterMenu(bathingObj, player, washSubMenu)
end

function TABAS_ContextMenuVanillaFluid.doEmptyMenu(player, fluidContainer, context)
    if fluidContainer and fluidContainer:canPlayerEmpty() and not fluidContainer:isEmpty() then
        context:addOption(getText("Fluid_Empty"), player, ISWorldObjectContextMenu.onFluidEmpty, fluidContainer)
    end
end

return TABAS_ContextMenuVanillaFluid
