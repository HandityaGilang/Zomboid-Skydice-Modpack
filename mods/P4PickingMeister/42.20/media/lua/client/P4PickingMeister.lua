local OPTION_TYPE_SELECTABLE = "P4PickingMeister_SelectableOption"

P4PickingMeister = {}

-- Common
P4PickingMeister.player = nil

-- Grab Menu
P4PickingMeister.Menu_GrabContents = getText("ContextMenu_P4PickingMeister_GrabContents")
P4PickingMeister.Menu_GrabOne = getText("ContextMenu_P4PickingMeister_GrabOne")
P4PickingMeister.Menu_GrabHalf = getText("ContextMenu_P4PickingMeister_GrabHalf")
P4PickingMeister.Menu_GrabAll = getText("ContextMenu_P4PickingMeister_GrabAll")
P4PickingMeister.Menu_GrabAllSelected = getText("ContextMenu_P4PickingMeister_GrabAllSelected")
P4PickingMeister.Menu_Vanilla_Place = getText("ContextMenu_PlaceItemOnGround")
P4PickingMeister.Menu_Vanilla_More = getText("ContextMenu_More")
P4PickingMeister.Tooltip_Empty = getText("UI_P4PickingMeister_Tooltip_Empty")
P4PickingMeister.Tooltip_NotSelected = getText("UI_P4PickingMeister_Tooltip_NotSelected")
P4PickingMeister.Tooltip_NotSelectedJoypad = getText("UI_P4PickingMeister_Tooltip_NotSelectedJoypad")

-- Unpack Menu
P4PickingMeister.Menu_UnpackContents = getText("ContextMenu_P4PickingMeister_UnpackContents")
P4PickingMeister.Menu_UnpackOne = getText("ContextMenu_P4PickingMeister_UnpackOne")
P4PickingMeister.Menu_UnpackHalf = getText("ContextMenu_P4PickingMeister_UnpackHalf")
P4PickingMeister.Menu_UnpackAll = getText("ContextMenu_P4PickingMeister_UnpackAll")
P4PickingMeister.Menu_UnpackAllSelected = getText("ContextMenu_P4PickingMeister_UnpackAllSelected")
P4PickingMeister.Menu_Vanilla_Unpack = getText("ContextMenu_Unpack")

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
	local destContainer = getPlayerInventory(player).inventory
	local targets = {}
	local blockedTargets = {}
	local allTargets = {}
	local contentCount = 0
	for _,v in ipairs(items) do
		if instanceof(v, "InventoryItem") then
			if instanceof(v, "InventoryContainer") then
				parent = v:getContainer()
				contentCount = contentCount + P4PickingMeister.collectTargets(v, destContainer, targets, blockedTargets, allTargets)
			end
		else
			for i,v in ipairs(v.items) do
				if i > 1 and instanceof(v, "InventoryContainer") then
					parent = v:getContainer()
					contentCount = contentCount + P4PickingMeister.collectTargets(v, destContainer, targets, blockedTargets, allTargets)
				end
			end
		end
	end
	if not parent then
		return
	end

	local isInCharacterInventory = parent:isInCharacterInventory(getSpecificPlayer(player))
	local menuContents = isInCharacterInventory and P4PickingMeister.Menu_UnpackContents or P4PickingMeister.Menu_GrabContents
	local menuOne = isInCharacterInventory and P4PickingMeister.Menu_UnpackOne or P4PickingMeister.Menu_GrabOne
	local menuHalf = isInCharacterInventory and P4PickingMeister.Menu_UnpackHalf or P4PickingMeister.Menu_GrabHalf
	local menuAll = isInCharacterInventory and P4PickingMeister.Menu_UnpackAll or P4PickingMeister.Menu_GrabAll
	local menuAllSelected = isInCharacterInventory and P4PickingMeister.Menu_UnpackAllSelected or P4PickingMeister.Menu_GrabAllSelected

	local insertPosition = P4PickingMeister.Menu_Vanilla_Place
	if not context:getOptionFromName(insertPosition) then
		insertPosition = P4PickingMeister.Menu_Vanilla_More
	end
	if not context:getOptionFromName(insertPosition) then
		return
	end

	if contentCount > 0 then
		local option = context:insertOptionBefore(insertPosition, menuContents, targets, nil)
		local subMenu = ISContextMenu:getNew(context)
		context:addSubMenu(option, subMenu)
		P4PickingMeister.addTargetOptions(subMenu, targets, blockedTargets, allTargets, parent, player, menuOne, menuHalf, menuAll, menuAllSelected)
	elseif P4PickingMeister.options.ShowInactiveMenu.value then
		local option = context:insertOptionBefore(insertPosition, menuContents, nil, nil)
		option.notAvailable = true
		option.toolTip = ISInventoryPaneContextMenu.addToolTip()
		option.toolTip.description = P4PickingMeister.Tooltip_Empty
	end
end
Events.OnFillInventoryObjectContextMenu.Add(P4PickingMeister.OnFillInventoryObjectContextMenu_Grab)

P4PickingMeister.collectTargets = function(container, destContainer, targets, blockedTargets, allTargets)
	local items = container:getItemContainer():getItems()
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		local name = item:getName()
		if destContainer:isItemAllowed(item) then
			if targets[name] == nil then
				targets[name] = {item}
			else
				table.insert(targets[name], item)
			end
			table.insert(allTargets, item)
		else
			if blockedTargets[name] == nil then
				blockedTargets[name] = {item}
			else
				table.insert(blockedTargets[name], item)
			end
		end
	end
	return items:size()
end

P4PickingMeister.addTargetOptions = function(subMenu, targets, blockedTargets, allTargets, parent, player, menuOne, menuHalf, menuAll, menuAllSelected)
	local sortedTargets = {}
	for name,target in pairs(targets) do
		table.insert(sortedTargets, {name, target, false})
	end
	for name,target in pairs(blockedTargets) do
		table.insert(sortedTargets, {name, target, true})
	end

	local selectableTargetCount = 0
	for i = #sortedTargets, 1, -1 do
		local name = sortedTargets[i][1]
		local target = sortedTargets[i][2]
		local blocked = sortedTargets[i][3]
		if blocked then
			local optionName = #target > 1 and name .. " (" .. #target .. ")" or name
			local option = subMenu:addOption(optionName, nil, nil)
			option.notAvailable = true
			if P4PickingMeister.options.ShowIcon.value then
				option.iconTexture = target[1]:getTexture()
			end
		elseif #target > 1 then
			selectableTargetCount = selectableTargetCount + 1
			local option = subMenu:addOption(name .. " (" .. #target .. ")", target, P4PickingMeister.onGrabItems, parent, player, OPTION_TYPE_SELECTABLE)
			if P4PickingMeister.options.ShowIcon.value then
				option.iconTexture = target[1]:getTexture()
			end
			local itemCountMenu = ISContextMenu:getNew(subMenu)
			subMenu:addSubMenu(option, itemCountMenu)
			itemCountMenu:addOption(menuOne, target[1], P4PickingMeister.onGrabOneItem, parent, player)
			itemCountMenu:addOption(menuHalf, target, P4PickingMeister.onGrabHalfItems, parent, player)
			itemCountMenu:addOption(menuAll, target, P4PickingMeister.onGrabItems, parent, player)
		else
			selectableTargetCount = selectableTargetCount + 1
			local option = subMenu:addOption(name, target, P4PickingMeister.onGrabItems, parent, player, OPTION_TYPE_SELECTABLE)
			if P4PickingMeister.options.ShowIcon.value then
				option.iconTexture = target[1]:getTexture()
			end
		end
	end

	if selectableTargetCount > 1 then
		subMenu:addOption(menuAll, allTargets, P4PickingMeister.onGrabItems, parent, player)
	end
	if subMenu:getOptionFromName(menuAll) then
		local selectOption = subMenu:insertOptionBefore(menuAll, menuAllSelected, {}, P4PickingMeister.onGrabItems, parent, player)
		selectOption.notAvailable = true
		selectOption.toolTip = ISInventoryPaneContextMenu.addToolTip()
		selectOption.toolTip.description = P4PickingMeister.getNotSelectedTooltip(player)
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
	if option and not option.notAvailable and option.param3 == OPTION_TYPE_SELECTABLE then
		local selectOption = context:getOptionFromName(P4PickingMeister.Menu_GrabAllSelected) or context:getOptionFromName(P4PickingMeister.Menu_UnpackAllSelected)
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
