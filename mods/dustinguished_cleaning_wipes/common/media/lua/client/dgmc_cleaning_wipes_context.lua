require("ISUI/ISToolTip")
local bodyAction = require("actions/dgmc_cleaning_wipes_clean_body_action")
local itemAction = require("actions/dgmc_cleaning_wipes_clean_item_action")
local logger = require("dgmc_cleaning_wipes_logging")

local menuText = getText("ContextMenu_DGMC_Cleaning_Wipes")
local noopText = getText("ContextMenu_DGMC_Cleaning_Wipes_No_Op")
local yourselfText = getText("ContextMenu_Yourself")
local clothingText = getText("ContextMenu_WashAllClothing")
local containerText = getText("ContextMenu_WashAllContainer")
local weaponText = getText("ContextMenu_WashAllWeapon")

local SBV = SandboxVars.DGMC_Cleaning_Wipes

---@param lhs InventoryItem
---@param rhs InventoryItem
---@return boolean
local function wipeComparison(lhs, rhs)
	return lhs:getCurrentUses() < rhs:getCurrentUses()
end

---@param items ContextMenuItemStack[] | InventoryItem[]
---@return InventoryItem[]
local function findWipes(items)
	---@type InventoryItem[]
	local result = {}

	for i = 1, #items do
		local item = items[i]

		if instanceof(item, "InventoryItem") then
			---@cast item InventoryItem
			if item:hasTag(DGMC_CleaningWipes_G.tag) == true then
				table.insert(result, item)
			end
		else
			---@cast item ContextMenuItemStack
			if item.items ~= nil then
				for j = 2, #item.items do
					local subItem = item.items[j]
					if subItem:hasTag(DGMC_CleaningWipes_G.tag) == true then
						table.insert(result, subItem)
					end
				end
			end
		end
	end

	return result
end

---@param player IsoPlayer
---@return number
local function calcPlayerDirtiness(player)
	local result = 0.0

	local visual = player:getHumanVisual()
	local maxIndex = BloodBodyPartType.MAX:index()
	for i = 1, maxIndex do
		local part = BloodBodyPartType.FromIndex(i - 1)
		result = result + visual:getBlood(part) + visual:getDirt(part)
	end

	logger.debug("calcPlayerDirtiness", "%f", result)
	return result
end

---@param inventory ItemContainer
---@param category string
---@return InventoryItem[]
local function findDirtyItems(inventory, category)
	local result = {}
	local items = inventory:getItemsFromCategory(category)

	for i = 0, items:size() - 1 do
		local item = items:get(i)

		if item ~= nil and item:isHidden() == false and (item:hasBlood() or item:hasDirt()) then
			table.insert(result, item)
		end
	end

	logger.debug("findDirtyItems", "found %i %s items", #result, category)

	return result
end

---@param player IsoPlayer
---@param wipes InventoryItem[]
---@param usesNeeded integer
local function transferWipes(player, wipes, usesNeeded)
	local count = #wipes

	---@type ArrayList<InventoryItem>
	local result = ArrayList.new(count)

	for i = 1, count do
		local wipe = wipes[i]
		if wipe ~= nil then
			result:add(wipe)

			usesNeeded = usesNeeded - wipe:getCurrentUses()
			if usesNeeded <= 0 then
				break
			end
		end
	end

	logger.debug("transferWipes", "transferring %i uses, from %i of %i wipes, if needed", usesNeeded, result:size(), count)

	ISInventoryPaneContextMenu.transferIfNeeded(player, result)
end

---@param player IsoPlayer
---@param dirtiness number
---@param wipes InventoryItem[]
local function onCleanBody(player, dirtiness, wipes)
	logger.debug("onCleanBody", "dirtiness: %f, wipes: %i", dirtiness, #wipes)
	table.sort(wipes, wipeComparison)

	local wipe = wipes[1]

	ISInventoryPaneContextMenu.transferIfNeeded(player, wipe)

	---@diagnostic disable-next-line
	ISTimedActionQueue.add(bodyAction:new(player, dirtiness, wipe))
end

---@param player IsoPlayer
---@param item InventoryItem
---@param wipes InventoryItem[]
local function onCleanItem(player, item, wipes)
	logger.debug("onCleanItem", "item: %s, wipes: %i", item:getName(), #wipes)
	table.sort(wipes, wipeComparison)

	local wipe = wipes[1]

	ISInventoryPaneContextMenu.transferIfNeeded(player, wipe)

	---@diagnostic disable-next-line
	ISTimedActionQueue.add(itemAction:new(player, item, wipe))
end

---@param wipes InventoryItem[]
---@return integer[]
local function getUses(wipes)
	---@type integer[]
	local result = {}

	for i = 1, #wipes do
		table.insert(result, wipes[i]:getCurrentUses())
	end

	return result
end

---@param player IsoPlayer
---@param items InventoryItem[]
---@param wipes InventoryItem[]
local function onCleanAll(player, items, wipes)
	logger.debug("onCleanAll", "items: %i, wipes: %i", #items,  #wipes)
	table.sort(wipes, wipeComparison)

	local uses = getUses(wipes)
	local numWipes = #wipes
	local wipeIndex = 1

	if numWipes > 1 then
		transferWipes(player, wipes, numWipes)
	else
		ISInventoryPaneContextMenu.transferIfNeeded(player, wipes[1])
	end

	for i = 1, #items do
		if uses[wipeIndex] <= 0 then
			wipeIndex = wipeIndex + 1

			if wipeIndex > numWipes then
				return
			end
		end

		---@diagnostic disable
		ISTimedActionQueue.add(itemAction:new(player, items[i], wipes[wipeIndex]))
		uses[wipeIndex] = uses[wipeIndex] - 1
		---@diagnostic enable
	end
end

---@param menu ISContextMenu
---@param player IsoPlayer
---@param items InventoryItem[]
---@param wipes InventoryItem[]
local function addItemSetToSubMenu(menu, player, items, wipes)
	for i = 1, #items do
		local item = items[i]
		local option = menu:addGetUpOption(item:getDisplayName(), player, onCleanItem, item, wipes)

		if option ~= nil then
			option.iconTexture = item:getIcon()
		end
	end
end

---@param context ISContextMenu
---@param option umbrella.ISContextMenu.Option
---@param playerDirtiness number
---@param clothing InventoryItem[]
---@param containers InventoryItem[]
---@param weapons InventoryItem[]
---@param player IsoPlayer
---@param wipes InventoryItem[]
local function buildSubMenu(context, option, playerDirtiness, clothing, containers, weapons, player, wipes)
	local subMenu = ISContextMenu:getNew(context)
	context:addSubMenu(option, subMenu)

	if playerDirtiness > 0 then
		subMenu:addGetUpOption(yourselfText, player, onCleanBody, playerDirtiness, wipes)
	end

	if #clothing > 0 then
		subMenu:addGetUpOption(clothingText, player, onCleanAll, clothing, wipes)		
	end

	if #containers > 0 then
		subMenu:addGetUpOption(containerText, player, onCleanAll, containers, wipes)
	end

	if #weapons > 0 then
		subMenu:addGetUpOption(weaponText, player, onCleanAll, weapons, wipes)
	end

	addItemSetToSubMenu(subMenu, player, clothing, wipes)
	addItemSetToSubMenu(subMenu, player, containers, wipes)
	addItemSetToSubMenu(subMenu, player, weapons, wipes)
end

---@param option umbrella.ISContextMenu.Option
local function buildNoOpContext(option)
	option.notAvailable = true
	local tooltip = ISToolTip:new()
	tooltip:initialise()
	tooltip.description = noopText
	option.toolTip = tooltip
end

---@param playerNum integer
---@param context ISContextMenu
---@param items ContextMenuItemStack[] | InventoryItem[]
local function onContextEvent(playerNum, context, items)
	if items == nil or #items == 0 then
		return
	end

	local wipes = findWipes(items)
	if #wipes == 0 or wipes[1] == nil then
		logger.debug("onContextEvent", "no wipes found")
		return
	end
	local icon = wipes[1]:getIcon()

	local player = getSpecificPlayer(playerNum)
	if player == nil or player:isDead() == true then
		logger.error("onContextEvent", "no valid player")
		return
	end

	local inventory = player:getInventory()
	if inventory == nil then
		logger.error("onContextEvent", "no player inventory")
		return
	end

	local playerDirtiness = 0.0
	if SBV.Clean_Body == true then
		playerDirtiness = calcPlayerDirtiness(player)
	else
		logger.debug("onContextEvent", "cleaning body is disabled via sandbox setting")
	end

	local clothing
	local containers
	if SBV.Clean_Clothing == true then
		clothing = findDirtyItems(inventory, "Clothing")
		containers = findDirtyItems(inventory, "Container")
	else
		clothing = {}
		containers = {}
		logger.debug("onContextEvent", "cleaning clothing is disabled via sandbox setting")
	end

	local weapons
	if SBV.Clean_Weapons == true then
		weapons = findDirtyItems(inventory, "Weapon")
	else
		weapons = {}
		logger.debug("onContextEvent", "cleaning weapons is disabled via sandbox setting")
	end

	local option = context:addOption(menuText, wipes, nil)
	option.iconTexture = icon

	if playerDirtiness > 0 or #clothing> 0 or #containers > 0 or #weapons > 0 then
		buildSubMenu(context, option, playerDirtiness, clothing, containers, weapons, player, wipes)
	else
		buildNoOpContext(option)
	end
end

Events.OnFillInventoryObjectContextMenu.Add(onContextEvent)