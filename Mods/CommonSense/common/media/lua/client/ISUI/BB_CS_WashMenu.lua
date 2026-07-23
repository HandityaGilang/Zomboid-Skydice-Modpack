-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

local compatify = false
local compatifyIDs = { "WashFix" }

local function tryReturnClothes(character, item, container)
    local currentContainer = item and item:getContainer()
    if not container or not currentContainer then return end

    if container ~= currentContainer then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(character, item, currentContainer, container))
    end
end

---@param playerObj IsoPlayer
---@param sink IsoObject
---@param soapList InventoryItem[]
---@param washListItems InventoryItem[]
---@param singleClothing InventoryItem?
---@param noSoap boolean
local function onWashClothingProper(playerObj, sink, soapList, washListItems, singleClothing, noSoap, context)
	context:closeAll()
    luautils.walkAdjObject(playerObj, sink, true, false)
    for _, item in ipairs(washListItems) do
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, item)
    end
	ISWorldObjectContextMenu.onWashClothing(playerObj, sink, soapList, washListItems, singleClothing, noSoap)
end

---@param washList washList
---@param soapRemaining number
---@param waterRemaining number
---@return ISToolTip
local function defineTooltip(washList, soapRemaining, waterRemaining)
    local tooltip = ISWorldObjectContextMenu.addToolTip();
    local requiredSoap = washList.requiredSoap
    local requiredWater = washList.requiredWater

    if (soapRemaining < requiredSoap) then
        tooltip.description = getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
    else
        tooltip.description = getText("IGUI_Washing_Soap") .. ": " .. tostring(math.min(soapRemaining, requiredSoap)) .. " / " .. tostring(requiredSoap) .. " <LINE> "
    end

    tooltip.description = tooltip.description .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.min(waterRemaining, requiredWater)) .. " / " .. tostring(requiredWater)
    return tooltip
end

---@param playerObj IsoPlayer
---@param playerInv ItemContainer
---@return customData
local function defineWashList(playerObj, playerInv)

    local data = {} --[[@class customData]]
    data.equippedWashList = {requiredSoap = 0.0, requiredWater = 0.0, items = {}} --[[@class washList]]
    data.unequippedWashList = {requiredSoap = 0.0, requiredWater = 0.0, items = {}} --[[@as washList]]
    data.washEquipment = false

	local clothingInventory = playerInv:getItemsFromCategory("Clothing")
    local containers = playerInv:getItemsFromCategory("Container")
    clothingInventory:addAll(containers)
    --local containerInventory = ArrayList.new()
    for i=0, containers:size()-1 do
        local container = containers:get(i) --[[@as InventoryContainer]]
        local items = container:getInventory():getItemsFromCategory("Clothing")
        clothingInventory:addAll(items)
    end

	for i=0, clothingInventory:size() - 1 do
		local item = clothingInventory:get(i)
        
		if not item:isHidden() and (item:hasBlood() or item:hasDirt()) then
			data.washEquipment = true

            if playerObj:isEquipped(item) then
                data.equippedWashList.requiredSoap = data.equippedWashList.requiredSoap + ISWashClothing.GetRequiredSoap(item)
                data.equippedWashList.requiredWater = data.equippedWashList.requiredWater + ISWashClothing.GetRequiredWater(item)
                table.insert(data.equippedWashList.items, item)
            else
                data.unequippedWashList.requiredSoap = data.unequippedWashList.requiredSoap + ISWashClothing.GetRequiredSoap(item)
                data.unequippedWashList.requiredWater = data.unequippedWashList.requiredWater + ISWashClothing.GetRequiredWater(item)
                table.insert(data.unequippedWashList.items, item)
            end
		end
	end

    return data
end

---@param playerIndex integer
---@param context ISContextMenu
---@param worldObjects IsoObject[]
---@param test boolean
local function doWashClothingMenu(playerIndex, context, worldObjects, test)

    if not SandboxVars.CommonSense.WashOnly or compatify then return end

    local sink = nil --[[@as IsoObject?]]
    for _, worldObj in ipairs(worldObjects) do
        local square = worldObj:getSquare()
        local objs = square and square:getObjects()
        for i=0, objs:size()-1 do
            local obj = objs:get(i)
            if obj:hasWater() then
                sink = obj
                break
            end
        end
        if sink then break end
    end
    if not sink then return end

    local playerObj = getSpecificPlayer(playerIndex)
	if sink:getSquare():getBuilding() ~= playerObj:getBuilding() then return end
    local playerInv = playerObj:getInventory()
    local customData = defineWashList(playerObj, playerInv)
    local washEquipment = customData.washEquipment
	local equippedWashList = customData.equippedWashList
	local unequippedWashList = customData.unequippedWashList
	local soapList = ArrayList.new() --[[@as ArrayList<InventoryItem>]]--[[@diagnostic disable-line: missing-parameter]]

	if not washEquipment then return end

    -- Soap list limited to players inventory
	local barList = playerInv:getItemsFromType("Soap2", true)
    local bottleList = playerInv:getItemsFromType("CleaningLiquid2", true)
    soapList:addAll(barList)
    soapList:addAll(bottleList)

	table.sort(equippedWashList.items, ISWorldObjectContextMenu.compareClothingBlood)
	table.sort(unequippedWashList.items, ISWorldObjectContextMenu.compareClothingBlood)

    local soapRemaining = ISWashClothing.GetSoapRemaining(soapList) --[[@diagnostic disable-line: param-type-mismatch]]
    local waterRemaining = sink:getFluidAmount()

    local mainSubMenu = nil --[[@as ISContextMenu?]]
    local option = nil --[[@as umbrella.ISContextMenu.Option?]]
    local submenuIndex = 1

    -- This way allows us to add our option after the last submenu
    while option == nil do
        mainSubMenu = context:getSubMenu(submenuIndex)
        if mainSubMenu == nil then break end
        option = mainSubMenu:getOptionFromName(getText("ContextMenu_WashAllBandage"))
        or mainSubMenu:getOptionFromName(getText("ContextMenu_WashAllWeapon"))
        or mainSubMenu:getOptionFromName(getText("ContextMenu_WashAllContainer"))
        or mainSubMenu:getOptionFromName(getText("ContextMenu_WashAllClothing"))
        or mainSubMenu:getOptionFromName(getText("ContextMenu_Yourself"))
        submenuIndex = submenuIndex + 1
    end

    if mainSubMenu ~= nil and option ~= nil then
        local onlyOption = mainSubMenu:insertOptionAfter(option.name, getText("ContextMenu_CS_Only")) --[[@as umbrella.ISContextMenu.Option]]
        local onlySubMenu = ISContextMenu:getNew(context)
        context:addSubMenu(onlyOption, onlySubMenu)

        if #equippedWashList.items > 0 then
            local noSoap = (soapRemaining < equippedWashList.requiredSoap)
            local opt = onlySubMenu:addOption(getText("ContextMenu_CS_WashEquippedOnly"), playerObj, onWashClothingProper, sink, soapList, equippedWashList.items, nil,  noSoap, context)
            opt.toolTip = defineTooltip(equippedWashList, soapRemaining, waterRemaining)
            if waterRemaining < equippedWashList.requiredWater then
                opt.notAvailable = true
            end
        end

        if #unequippedWashList.items > 0 then
            local noSoap = (soapRemaining < unequippedWashList.requiredSoap)
            local opt = onlySubMenu:addOption(getText("ContextMenu_CS_WashUnequippedOnly"), playerObj, onWashClothingProper, sink, soapList, unequippedWashList.items, nil,  noSoap, context)
            opt.toolTip = defineTooltip(unequippedWashList, soapRemaining, waterRemaining)
            if waterRemaining < unequippedWashList.requiredWater then
                opt.notAvailable = true
            end
        end
    end
end

Events.OnInitGlobalModData.Add(function()
    compatify = BB_CS_Utils.needToCompatify(compatifyIDs)
end)
Events.OnFillWorldObjectContextMenu.Add(doWashClothingMenu)