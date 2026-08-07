require "P4PickingMeisterQueue"

local OPTION_TYPE_SELECTABLE = "P4PickingMeister_SelectableOption"

P4PickingMeister = {}

-- Common
P4PickingMeister.player = nil
P4PickingMeister.foodQueue = P4PickingMeisterQueue:new()
P4PickingMeister.Tooltip_AlreadyInProgress = getText("UI_P4PickingMeister_Tooltip_AlreadyInProgress")

-- Grab Menu
P4PickingMeister.Menu_GrabContents = getText("ContextMenu_P4PickingMeister_GrabContents")
P4PickingMeister.Menu_GrabOne = getText("ContextMenu_P4PickingMeister_GrabOne")
P4PickingMeister.Menu_GrabHalf = getText("ContextMenu_P4PickingMeister_GrabHalf")
P4PickingMeister.Menu_GrabAll = getText("ContextMenu_P4PickingMeister_GrabAll")
P4PickingMeister.Menu_GrabAllSelected = getText("ContextMenu_P4PickingMeister_GrabAllSelected")
P4PickingMeister.Menu_Vanilla_Grab = getText("ContextMenu_Grab")
P4PickingMeister.Menu_Vanilla_GrabAll = getText("ContextMenu_Grab_all")
P4PickingMeister.Menu_Vanilla_Favorite = getText("IGUI_CraftUI_Favorite")
P4PickingMeister.Menu_Vanilla_Unfavorite = getText("ContextMenu_Unfavorite")
P4PickingMeister.Tooltip_Empty = getText("UI_P4PickingMeister_Tooltip_Empty")
P4PickingMeister.Tooltip_NotSelected = getText("UI_P4PickingMeister_Tooltip_NotSelected")
P4PickingMeister.Tooltip_NotSelectedJoypad = getText("UI_P4PickingMeister_Tooltip_NotSelectedJoypad")

-- Unpack Menu
P4PickingMeister.Menu_UnpackOne = getText("ContextMenu_P4PickingMeister_UnpackOne")
P4PickingMeister.Menu_UnpackHalf = getText("ContextMenu_P4PickingMeister_UnpackHalf")
P4PickingMeister.Menu_UnpackAll = getText("ContextMenu_P4PickingMeister_UnpackAll")
P4PickingMeister.Menu_Vanilla_Unpack = getText("ContextMenu_Unpack")

-- Food Menu
P4PickingMeister.Menu_OpenCannedFoodAndEat = getText("ContextMenu_P4PickingMeister_OpenCannedFoodAndEat")
P4PickingMeister.Menu_OpenRingpullCannedFoodAndEat = getText("ContextMenu_P4PickingMeister_OpenRingpullCannedFoodAndEat")
P4PickingMeister.Menu_OpenCannedFoodWithBladeAndEat = getText("ContextMenu_P4PickingMeister_OpenCannedFoodWithBladeAndEat")
P4PickingMeister.Menu_OpenBottleOfBeerAndDrink = getText("ContextMenu_P4PickingMeister_OpenBottleOfBeerAndDrink")
P4PickingMeister.Menu_OpenBottleOfChampagneAndDrink = getText("ContextMenu_P4PickingMeister_OpenBottleOfChampagneAndDrink")
P4PickingMeister.Menu_OpenBottleOfWineAndDrink = getText("ContextMenu_P4PickingMeister_OpenBottleOfWineAndDrink")
P4PickingMeister.Menu_OpenCanOfBeverageAndDrink = getText("ContextMenu_P4PickingMeister_OpenCanOfBeverageAndDrink")
P4PickingMeister.Menu_TakeCigaretteAndSmoke = getText("ContextMenu_P4PickingMeister_TakeCigaretteAndSmoke")
P4PickingMeister.Menu_Vanilla_EatAll = getText("ContextMenu_Eat_All")
P4PickingMeister.Menu_Vanilla_EatHalf = getText("ContextMenu_Eat_Half")
P4PickingMeister.Menu_Vanilla_EatQuarter = getText("ContextMenu_Eat_Quarter")
P4PickingMeister.Menu_Vanilla_TakeACigarette = getText("Recipe_TakeACigarette")
P4PickingMeister.Tooltip_CantDrinkMore = getText("UI_P4PickingMeister_Tooltip_CantDrinkMore")
P4PickingMeister.Tooltip_Vanilla_CantEatMore = getText("Tooltip_CantEatMore")

P4PickingMeister.OpenRecipe = {
	-- [1] Open and Eat
	["OpenCannedFood"] = {1, P4PickingMeister.Menu_OpenCannedFoodAndEat},
	["OpenCannedFood2"] = {1, P4PickingMeister.Menu_OpenRingpullCannedFoodAndEat},
	["OpenCannedFoodWithKnifeOrSharpStoneFlake"] = {1, P4PickingMeister.Menu_OpenCannedFoodWithBladeAndEat},
	-- [2] Open and Drink
	["OpenBottleOfBeer"] = {2, P4PickingMeister.Menu_OpenBottleOfBeerAndDrink},
	["OpenBottleOfChampagne"] = {2, P4PickingMeister.Menu_OpenBottleOfChampagneAndDrink},
	["OpenBottleOfWine"] = {2, P4PickingMeister.Menu_OpenBottleOfWineAndDrink},
	["OpenCanOfBeverage"] = {2, P4PickingMeister.Menu_OpenCanOfBeverageAndDrink},
	-- [3] Take and Smoke
	["TakeACigarette"] = {3, P4PickingMeister.Menu_TakeCigaretteAndSmoke},
}

-- Firearm Menu
P4PickingMeister.Menu_RetrieveAllAmmo = getText("ContextMenu_P4PickingMeister_RetrieveAllAmmo")
P4PickingMeister.Menu_Vanilla_EjectMagazine = getText("ContextMenu_EjectMagazine")
P4PickingMeister.Menu_Vanilla_Unjam = getText("ContextMenu_Unjam", "")
P4PickingMeister.Menu_Vanilla_Rack = getText("ContextMenu_Rack", "")
P4PickingMeister.Menu_Vanilla_UnloadRounds = getText("ContextMenu_UnloadRounds", "")

-- *****************************************************************************
-- * Options
-- *****************************************************************************

P4PickingMeister.options = {
	ShowIcon = nil,
	ShowInactiveMenu = nil,
}

P4PickingMeister.initOption = function()
	local options = PZAPI.ModOptions:create("P4PickingMeister", "Picking Meister")
	P4PickingMeister.options.ShowIcon = options:addTickBox("ShowIcon", getText("UI_P4PickingMeister_Options_ShowIcon_Name"), true, getText("UI_P4PickingMeister_Options_ShowIcon_Tooltip"))
	P4PickingMeister.options.ShowInactiveMenu = options:addTickBox("ShowInactiveMenu", getText("UI_P4PickingMeister_Options_ShowInactiveMenu_Name"), true, getText("UI_P4PickingMeister_Options_ShowInactiveMenu_Tooltip"))
end
P4PickingMeister.initOption()

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

P4PickingMeister.OnCreatePlayer = function(index, player)
	P4PickingMeister.player = player
end
Events.OnCreatePlayer.Add(P4PickingMeister.OnCreatePlayer)

-- *****************************************************************************
-- * P4PickingMeister Grab functions
-- *****************************************************************************

P4PickingMeister.OnFillInventoryObjectContextMenu_Grab = function(player, context, items)
	local parent = nil
	local targets = {}
	local allTargets = {}
	for _,v in ipairs(items) do
		if instanceof(v, "InventoryItem") then
			if instanceof(v, "InventoryContainer") then
				parent = v:getContainer()
				P4PickingMeister.checkTarget(v, targets, allTargets)
			end
		else
			for i,v in ipairs(v.items) do
				if i > 1 and instanceof(v, "InventoryContainer") then
					parent = v:getContainer()
					P4PickingMeister.checkTarget(v, targets, allTargets)
				end
			end
		end
	end
	if not parent then
		return
	end

	local insertPosition = nil
	for i,v in ipairs(context.options) do
		if v.name == P4PickingMeister.Menu_Vanilla_Favorite then
			insertPosition = v.name
			break
		elseif v.name == P4PickingMeister.Menu_Vanilla_Unfavorite then
			insertPosition = v.name
			break
		end
	end
	for i,v in ipairs(context.options) do
		if v.name == P4PickingMeister.Menu_Vanilla_Grab then
			insertPosition = v.name
			break
		elseif v.name == P4PickingMeister.Menu_Vanilla_GrabAll then
			insertPosition = v.name
			break
		end
	end

	if insertPosition then
		if #allTargets > 0 then
			local option = context:insertOptionAfter(insertPosition, P4PickingMeister.Menu_GrabContents, targets, nil)
			local subMenu = ISContextMenu:getNew(context)
			context:addSubMenu(option, subMenu)
			local sortedTargets = {}
			for name,target in pairs(targets) do
				table.insert(sortedTargets, {name, target})
			end
			for i = #sortedTargets, 1, -1 do
				local name = sortedTargets[i][1]
				local target = sortedTargets[i][2]
				if #target > 1 then
					local subOption = subMenu:addOption(name .. " (" .. #target .. ")", target, P4PickingMeister.onGrabItems, parent, player, OPTION_TYPE_SELECTABLE)
					if P4PickingMeister.options.ShowIcon.value then
						subOption.iconTexture = target[1]:getTexture()
					end
					local subSubMenu = ISContextMenu:getNew(subMenu)
					subMenu:addSubMenu(subOption, subSubMenu)
					subSubMenu:addOption(P4PickingMeister.Menu_GrabOne, target[1], P4PickingMeister.onGrabOneItem, parent, player)
					subSubMenu:addOption(P4PickingMeister.Menu_GrabHalf, target, P4PickingMeister.onGrabHalfItems, parent, player)
					subSubMenu:addOption(P4PickingMeister.Menu_GrabAll, target, P4PickingMeister.onGrabItems, parent, player)
				else
					local subOption = subMenu:addOption(name, target, P4PickingMeister.onGrabItems, parent, player, OPTION_TYPE_SELECTABLE)
					if P4PickingMeister.options.ShowIcon.value then
						subOption.iconTexture = target[1]:getTexture()
					end
				end
			end
			if #sortedTargets > 1 then
				subMenu:addOption(P4PickingMeister.Menu_GrabAll, allTargets, P4PickingMeister.onGrabItems, parent, player)
			end
			if (subMenu:getOptionFromName(P4PickingMeister.Menu_GrabAll)) then
				local selectOption = subMenu:insertOptionBefore(P4PickingMeister.Menu_GrabAll, P4PickingMeister.Menu_GrabAllSelected, {}, P4PickingMeister.onGrabItems, parent, player)
				selectOption.notAvailable = true
				selectOption.toolTip = ISInventoryPaneContextMenu.addToolTip()
				selectOption.toolTip.description = P4PickingMeister.getNotSelectedTooltip(player)
			end
		else
			if P4PickingMeister.options.ShowInactiveMenu.value then
				local option = context:insertOptionAfter(insertPosition, P4PickingMeister.Menu_GrabContents, nil, nil)
				option.notAvailable = true
				option.toolTip = ISInventoryPaneContextMenu.addToolTip()
				option.toolTip.description = P4PickingMeister.Tooltip_Empty
			end
		end
	end
end
Events.OnFillInventoryObjectContextMenu.Add(P4PickingMeister.OnFillInventoryObjectContextMenu_Grab)

P4PickingMeister.checkTarget = function(container, targets, allTargets)
	local items = container:getItemContainer():getItems()
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		local name = item:getName()
		if targets[name] == nil then
			targets[name] = {item}
		else
			table.insert(targets[name], item)
		end
		table.insert(allTargets, item)
	end
end

P4PickingMeister.onGrabItems = function(items, parent, player, optionType)
	local playerObj = getSpecificPlayer(player)
	local playerInv = getPlayerInventory(player).inventory
	if parent ~= playerInv then
		if not luautils.walkToContainer(parent, player) then
			return
		end
	end
	for _,item in ipairs(items) do
		P4PickingMeister.addTransferAction(playerObj, item, item:getContainer(), playerInv)
	end
end

P4PickingMeister.onGrabOneItem = function(item, parent, player)
	local playerObj = getSpecificPlayer(player)
	local playerInv = getPlayerInventory(player).inventory
	if parent ~= playerInv then
		if not luautils.walkToContainer(parent, player) then
			return
		end
	end
	P4PickingMeister.addTransferAction(playerObj, item, item:getContainer(), playerInv)
end

P4PickingMeister.onGrabHalfItems = function(items, parent, player)
	local playerObj = getSpecificPlayer(player)
	local playerInv = getPlayerInventory(player).inventory
	if parent ~= playerInv then
		if not luautils.walkToContainer(parent, player) then
			return
		end
	end
	for i = 1, math.floor(#items / 2) do
		local item = items[i]
		P4PickingMeister.addTransferAction(playerObj, item, item:getContainer(), playerInv)
	end
end

P4PickingMeister.addTransferAction = function(playerObj, item, srcContainer, destContainer)
	local itemId = item:getID()
	local srcItem = srcContainer:getContainingItem()
	local srcId = srcItem:getID()
	local srcParent = srcItem:getContainer()
	ISTimedActionQueue.add(P4PickingAction:new(playerObj, itemId, srcId, srcParent, destContainer))
end

P4PickingMeister.ISContextMenu_onJoypadDirRight = ISContextMenu.onJoypadDirRight
function ISContextMenu:onJoypadDirRight()
	local option = self.options[self.mouseOver]
	if option and option.subOption ~= nil and option.param3 == OPTION_TYPE_SELECTABLE then
		self:checkHighlightedOption(nil)
		self:hideToolTip()
		local subMenu = self:getSubMenu(option.subOption)
		if self:isOptionSingleMenu() then
			subMenu.mouseOver = 1 + subMenu:getDefaultOptionCount()
			self:displaySubMenu(subMenu, option)
			return
		end
		subMenu.forceVisible = true
		subMenu.mouseOver = 1
		setJoypadFocus(self.player, subMenu)
		subMenu:ensureVisible()
	end
	P4PickingMeister.ISContextMenu_onJoypadDirRight(self)
end

P4PickingMeister.ISContextMenu_onRightMouseUp = ISContextMenu.onRightMouseUp
function ISContextMenu:onRightMouseUp(...)
	P4PickingMeister.toggleCheckMark(self)
	P4PickingMeister.ISContextMenu_onRightMouseUp(self, ...)
end

P4PickingMeister.ISContextMenu_onJoypadDown = ISContextMenu.onJoypadDown
function ISContextMenu:onJoypadDown(button)
	if button == Joypad.YButton then
		P4PickingMeister.toggleCheckMark(self)
	end
	P4PickingMeister.ISContextMenu_onJoypadDown(self, button)
end

P4PickingMeister.toggleCheckMark = function(context)
	local option = context.options[context.mouseOver]
	if option and option.param3 == OPTION_TYPE_SELECTABLE then
		local selectOption = context:getOptionFromName(P4PickingMeister.Menu_GrabAllSelected)
		if (selectOption) then
			-- Toggle selected
			option.checkMark = not option.checkMark
			-- Update Grab All Selected menu
			local targets = {}
			for _,option in ipairs(context.options) do
				if option.checkMark then
					for _,target in ipairs(option.target) do
						table.insert(targets, target)
					end
				end
			end
			if #targets > 0 then
				selectOption.target = targets
				selectOption.notAvailable = false
				selectOption.toolTip = nil
			else
				selectOption.target = {}
				selectOption.notAvailable = true
				selectOption.toolTip = ISInventoryPaneContextMenu.addToolTip()
				selectOption.toolTip.description = P4PickingMeister.getNotSelectedTooltip(context.player)
			end
			return
		end
	end
end

P4PickingMeister.getNotSelectedTooltip = function(playerNum)
	local tooltip = P4PickingMeister.Tooltip_NotSelected
	local joypadData = JoypadState.players[playerNum + 1]
	if joypadData and joypadData.isActive then
		tooltip = P4PickingMeister.Tooltip_NotSelectedJoypad
	end
	return tooltip
end

-- *****************************************************************************
-- * P4PickingMeister Unpack functions
-- *****************************************************************************

P4PickingMeister.OnFillInventoryObjectContextMenu_Unpack = function(player, context, items)
	if #items == 1 and context:getOptionFromName(P4PickingMeister.Menu_Vanilla_Unpack) then
		local item = items[1]
		if not instanceof(item, "InventoryItem") then
			if #item.items > 2 then
				local inventory = getSpecificPlayer(player):getInventory()
				-- Add UnpackOne Menu
				local oneItems = {item.items[2]}
				context:insertOptionBefore(P4PickingMeister.Menu_Vanilla_Unpack, P4PickingMeister.Menu_UnpackOne, oneItems, ISInventoryPaneContextMenu.onMoveItemsTo, inventory, player)
				-- Add UnpackHalf Menu
				local halfItems = {}
				for i = 2, math.floor((#item.items - 1) / 2) + 1 do
					table.insert(halfItems, item.items[i])
				end
				context:insertOptionBefore(P4PickingMeister.Menu_Vanilla_Unpack, P4PickingMeister.Menu_UnpackHalf, halfItems, ISInventoryPaneContextMenu.onMoveItemsTo, inventory, player)
				-- Add UnpackAll Menu
				local allItems = ISInventoryPane.getActualItems(item.items)
				context:insertOptionBefore(P4PickingMeister.Menu_Vanilla_Unpack, P4PickingMeister.Menu_UnpackAll, allItems, ISInventoryPaneContextMenu.onMoveItemsTo, inventory, player)
				-- Remove Vanilla Unpack
				context:removeOptionByName(P4PickingMeister.Menu_Vanilla_Unpack)
			end
		end
	end
end
Events.OnFillInventoryObjectContextMenu.Add(P4PickingMeister.OnFillInventoryObjectContextMenu_Unpack)

-- *****************************************************************************
-- * P4PickingMeister Food functions
-- *****************************************************************************

P4PickingMeister.OnFillInventoryObjectContextMenu_Food = function(player, context, items)
	for i,v in ipairs(context.options) do
		if instanceof(v.param1, "CraftRecipe") then
			local item = v.target
			local func = v.onSelect
			local recipe = v.param1
			local player = v.param2
			local all = v.param3
			local menu = P4PickingMeister.OpenRecipe[recipe:getName()]
			if menu then
				local playerObj = getSpecificPlayer(player)
				if menu[1] == 1 then
					local option = context:insertOptionAfter(v.name, menu[2], item, nil)
					option.iconTexture = v.iconTexture
					if playerObj:getMoodles():getMoodleLevel(MoodleType.FOOD_EATEN) >= 3 then
						option.notAvailable = true
						option.toolTip = ISInventoryPaneContextMenu.addToolTip()
						option.toolTip.description = P4PickingMeister.Tooltip_Vanilla_CantEatMore
					elseif P4PickingMeister.foodQueue:isNotEmpty() then
						option.notAvailable = true
						option.toolTip = ISInventoryPaneContextMenu.addToolTip()
						option.toolTip.description = P4PickingMeister.Tooltip_AlreadyInProgress
					else
						local subMenu = ISContextMenu:getNew(context)
						context:addSubMenu(option, subMenu)
						subMenu:addOption(P4PickingMeister.Menu_Vanilla_EatAll, item, P4PickingMeister.onOpenAndEat, func, recipe, player, all, 1)
						subMenu:addOption(P4PickingMeister.Menu_Vanilla_EatHalf, item, P4PickingMeister.onOpenAndEat, func, recipe, player, all, 0.5)
						subMenu:addOption(P4PickingMeister.Menu_Vanilla_EatQuarter, item, P4PickingMeister.onOpenAndEat, func, recipe, player, all, 0.25)
					end
				elseif menu[1] == 2 then
					local option = context:insertOptionAfter(v.name, menu[2], item, nil)
					option.iconTexture = v.iconTexture
					if playerObj:getMoodles():getMoodleLevel(MoodleType.FOOD_EATEN) >= 3 then
						option.notAvailable = true
						option.toolTip = ISInventoryPaneContextMenu.addToolTip()
						option.toolTip.description = P4PickingMeister.Tooltip_CantDrinkMore
					elseif P4PickingMeister.foodQueue:isNotEmpty() then
						option.notAvailable = true
						option.toolTip = ISInventoryPaneContextMenu.addToolTip()
						option.toolTip.description = P4PickingMeister.Tooltip_AlreadyInProgress
					else
						local subMenu = ISContextMenu:getNew(context)
						context:addSubMenu(option, subMenu)
						subMenu:addOption(P4PickingMeister.Menu_Vanilla_EatAll, item, P4PickingMeister.onOpenAndDrink, func, recipe, player, all, 1)
						subMenu:addOption(P4PickingMeister.Menu_Vanilla_EatHalf, item, P4PickingMeister.onOpenAndDrink, func, recipe, player, all, 0.5)
						subMenu:addOption(P4PickingMeister.Menu_Vanilla_EatQuarter, item, P4PickingMeister.onOpenAndDrink, func, recipe, player, all, 0.25)
					end
				elseif menu[1] == 3 then
					local option = context:insertOptionAfter(v.name, P4PickingMeister.Menu_TakeCigaretteAndSmoke, item, P4PickingMeister.onTakeAndSmoke, player)
					option.iconTexture = v.iconTexture
					-- Check the fire source from Vanilla(ISInventoryPaneContextMenu.doEatOption).
					local found = false
					local required = ""
					if playerObj:getVehicle() and playerObj:getVehicle():canLightSmoke(playerObj) then
						found = true
					else
						found = ISInventoryPaneContextMenu.hasOpenFlame(playerObj)
					end
					if not found then
						local list = item:getRequireInHandOrInventory()
						for i = 0, list:size() - 1 do
							local fullType = moduleDotType(item:getModule(), list:get(i))
							if playerObj:getInventory():getFirstTypeEvalRecurse(fullType, P4PickingMeister.predicateNotEmpty) then
								found = true
								break
							end
							required = required .. getItemNameFromFullType(fullType)
							if i < list:size() - 1 then
								required = required .. "/"
							end
						end
					end
					if not found then
						option.notAvailable = true
						option.toolTip = ISInventoryPaneContextMenu.addToolTip()
						option.toolTip.description = getText("ContextMenu_Require", required)
					end
				end
			end
		end
	end
end
Events.OnFillInventoryObjectContextMenu.Add(P4PickingMeister.OnFillInventoryObjectContextMenu_Food)

P4PickingMeister.onOpenAndEat = function(item, func, recipe, player, all, percent)
	-- Add a Walk Check to the vanilla menu as there is no check.
	-- If the vanilla side is fixed, this check will no longer be necessary.
	local playerInv = getPlayerInventory(player).inventory
	local parent = item:getContainer()
	if parent ~= playerInv then
		if not luautils.walkToContainer(parent, player) then
			return
		end
	end
	local playerObj = getSpecificPlayer(player)
	P4PickingMeister.foodQueue:enqueue(percent)
	func(item, recipe, player, all)
end

P4PickingMeister.onOpenAndDrink = function(item, func, recipe, player, all, percent)
	-- Add a Walk Check to the vanilla menu as there is no check.
	-- If the vanilla side is fixed, this check will no longer be necessary.
	local playerInv = getPlayerInventory(player).inventory
	local parent = item:getContainer()
	if parent ~= playerInv then
		if not luautils.walkToContainer(parent, player) then
			return
		end
	end
	local playerObj = getSpecificPlayer(player)
	func(item, recipe, player, all)
	ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
	local mask = ISInventoryPaneContextMenu.getEatingMask(playerObj, true)
	ISTimedActionQueue.add(ISDrinkFluidAction:new(playerObj, item:getWorldItem() or item, percent))
	if mask then ISTimedActionQueue.add(ISWearClothing:new(playerObj, mask, 50)) end
end

P4PickingMeister.onTakeAndSmoke = function(item, player)
	-- Add a Walk Check to the vanilla menu as there is no check.
	-- If the vanilla side is fixed, this check will no longer be necessary.
	local playerInv = getPlayerInventory(player).inventory
	local parent = item:getContainer()
	if parent ~= playerInv then
		if not luautils.walkToContainer(parent, player) then
			return
		end
	end
	ISInventoryPaneContextMenu.takePill(item, player)
end

P4PickingMeister.predicateNotEmpty = function(item)
	return item:getCurrentUsesFloat() > 0
end

P4PickingMeister.Actions_addOrDropItem = Actions.addOrDropItem
function Actions.addOrDropItem(playerObj, item)
	P4PickingMeister.Actions_addOrDropItem(playerObj, item)
	if P4PickingMeister.foodQueue:isNotEmpty() then
		local percent = P4PickingMeister.foodQueue:dequeue()
		ISInventoryPaneContextMenu.eatItem(item, percent, playerObj:getPlayerNum())
	end
end

P4PickingMeister.ISHandcraftAction_stop = ISHandcraftAction.stop
function ISHandcraftAction:stop()
	P4PickingMeister.ISHandcraftAction_stop(self)
	P4PickingMeister.foodQueue:clear()
end

-- *****************************************************************************
-- * P4PickingMeister Firearm functions
-- *****************************************************************************

P4PickingMeister.ISInventoryPaneContextMenu_doReloadMenuForWeapon = ISInventoryPaneContextMenu.doReloadMenuForWeapon
function ISInventoryPaneContextMenu.doReloadMenuForWeapon(playerObj, weapon, context)
	P4PickingMeister.ISInventoryPaneContextMenu_doReloadMenuForWeapon(playerObj, weapon, context)
	local insertPosition = nil
	local hasMagazine = false
	local needsRack = false
	local tooltips = {}
	for i,v in ipairs(context.options) do
		if string.find(v.name, P4PickingMeister.Menu_Vanilla_EjectMagazine) then
			insertPosition = v.name
			hasMagazine = true
			table.insert(tooltips, v.name)
		elseif string.find(v.name, P4PickingMeister.Menu_Vanilla_Unjam) then
			insertPosition = v.name
			needsRack = true
			table.insert(tooltips, v.name)
		elseif string.find(v.name, P4PickingMeister.Menu_Vanilla_Rack) then
			insertPosition = v.name
			needsRack = true
			table.insert(tooltips, v.name)
		elseif string.find(v.name, P4PickingMeister.Menu_Vanilla_UnloadRounds) then
			insertPosition = v.name
			table.insert(tooltips, v.name)
		end
	end
	if insertPosition then
		local option = context:insertOptionAfter(insertPosition, P4PickingMeister.Menu_RetrieveAllAmmo, weapon, P4PickingMeister.onRetrieveAllAmmo, playerObj, hasMagazine, needsRack)
		option.toolTip = ISInventoryPaneContextMenu.addToolTip()
		option.toolTip.description = table.concat(tooltips, "\n")
	end
end

P4PickingMeister.onRetrieveAllAmmo = function(weapon, playerObj, hasMagazine, needsRack)
	local player = playerObj:getPlayerNum()
	-- Add a Walk Check to the vanilla menu as there is no check.
	-- If the vanilla side is fixed, this check will no longer be necessary.
	local playerInv = getPlayerInventory(player).inventory
	local parent = weapon:getContainer()
	if parent ~= playerInv then
		if not luautils.walkToContainer(parent, player) then
			return
		end
	end
	ISInventoryPaneContextMenu.equipWeapon(weapon, true, false, player)
	if hasMagazine then
		ISTimedActionQueue.add(ISEjectMagazine:new(playerObj, weapon))
	else
		ISTimedActionQueue.add(ISUnloadBulletsFromFirearm:new(playerObj, weapon))
	end
	if needsRack then
		ISTimedActionQueue.add(ISRackFirearm:new(playerObj, weapon))
	end
end
