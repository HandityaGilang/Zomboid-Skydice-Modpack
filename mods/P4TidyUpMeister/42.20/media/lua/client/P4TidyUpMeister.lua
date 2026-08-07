require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISEquipWeaponAction"
require "TimedActions/ISUnequipAction"
require "TimedActions/ISWearClothing"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISTransferAction"
require "TimedActions/P4RestoreAction"
require "TimedActions/P4RestoreFloorAction"

local P4TidyUpMeister = {}

P4TidyUpMeister.sessions = setmetatable({}, { __mode = "k" })
P4TidyUpMeister.restoring = setmetatable({}, { __mode = "k" })
P4TidyUpMeister.restoreFloor = setmetatable({}, { __mode = "k" })
P4TidyUpMeister.nextSessionId = 1
P4TidyUpMeister.evolvedRecipes = {}

local MAX_ACTION_TRACE = 40
local MAX_VERBOSE_ACTION_LOGS = 12
local MAX_VERBOSE_TRANSFER_LOGS = 8
local DEBUG_OUTPUT_OFF = 1
local DEBUG_OUTPUT_LOG = 2
local DEBUG_OUTPUT_HALO = 3

-- *****************************************************************************
-- * Options
-- *****************************************************************************

P4TidyUpMeister.options = {
	UseContextMenu = nil,
	ForceReequip = nil,
	RestoreDismantleOutputs = nil,
	DebugOutput = nil,
}

P4TidyUpMeister.initOption = function()
	local options = PZAPI.ModOptions:create("P4TidyUpMeister", "Tidy Up Meister")
	P4TidyUpMeister.options.UseContextMenu = options:addTickBox("UseContextMenu", getText("UI_P4TidyUpMeister_Options_UseContextMenu_Name"), true, getText("UI_P4TidyUpMeister_Options_UseContextMenu_Tooltip"))
	P4TidyUpMeister.options.ForceReequip = options:addTickBox("ForceReequip", getText("UI_P4TidyUpMeister_Options_ForceReequip_Name"), false, getText("UI_P4TidyUpMeister_Options_ForceReequip_Tooltip"))
	P4TidyUpMeister.options.RestoreDismantleOutputs = options:addTickBox("RestoreDismantleOutputs", getText("UI_P4TidyUpMeister_Options_RestoreDismantleOutputs_Name"), false, getText("UI_P4TidyUpMeister_Options_RestoreDismantleOutputs_Tooltip"))
	P4TidyUpMeister.options.DebugOutput = options:addComboBox("DebugOutput", getText("UI_P4TidyUpMeister_Options_DebugOutput_Name"), getText("UI_P4TidyUpMeister_Options_DebugOutput_Tooltip"))
	P4TidyUpMeister.options.DebugOutput:addItem(getText("UI_P4TidyUpMeister_Options_DebugOutput_ListItem1"), true)
	P4TidyUpMeister.options.DebugOutput:addItem(getText("UI_P4TidyUpMeister_Options_DebugOutput_ListItem2"), false)
	P4TidyUpMeister.options.DebugOutput:addItem(getText("UI_P4TidyUpMeister_Options_DebugOutput_ListItem3"), false)
end
P4TidyUpMeister.initOption()

P4TidyUpMeister.optionEnabled = function(optionName)
	local option = P4TidyUpMeister.options[optionName]
	return option and option.value
end

-- *****************************************************************************
-- * Debug functions
-- *****************************************************************************

P4TidyUpMeister.playerLabel = function(player)
	if not player then
		return "P?"
	end
	return "P" .. tostring(player:getPlayerNum())
end

P4TidyUpMeister.itemLabel = function(item)
	if not item then
		return "nil"
	end
	if not instanceof(item, "InventoryItem") then
		return tostring(item)
	end
	local container = item:getContainer()
	local containerType = container and container:getType() or "none"
	return string.format("%s#%s@%s", tostring(item:getFullType()), tostring(item:getID()), tostring(containerType))
end

P4TidyUpMeister.debugLog = function(player, session, message)
	local option = P4TidyUpMeister.options.DebugOutput
	if not option or (option.selected or DEBUG_OUTPUT_OFF) < DEBUG_OUTPUT_LOG then
		return
	end
	local sessionId = session and session.id or "-"
	print(string.format("[P4TidyUpMeister][%s][S%s] %s", P4TidyUpMeister.playerLabel(player), tostring(sessionId), tostring(message)))
end

P4TidyUpMeister.debugHalo = function(player, message)
	local option = P4TidyUpMeister.options.DebugOutput
	if not option or (option.selected or DEBUG_OUTPUT_OFF) < DEBUG_OUTPUT_HALO or not player or not player:isLocalPlayer() then
		return
	end
	HaloTextHelper.addText(player, "[P4] " .. message)
end

-- *****************************************************************************
-- * Action policies
-- *****************************************************************************

local PREPARATION_TYPES = {
	ISAddAnimalInTrailer = true,
	ISAttachItemHotbar = true,
	ISClothingExtraAction = true,
	ISDetachItemHotbar = true,
	ISDropWorldItemAction = true,
	ISEquipHeavyItem = true,
	ISEquipWeaponAction = true,
	ISExtendedPlacementAction = true,
	ISFluidTransferAction = true,
	ISGrabCorpseAction = true,
	ISGrabCorpseItem = true,
	ISHutchGrabAnimal = true,
	ISHutchGrabCorpseAction = true,
	ISPickupAnimal = true,
	ISPutAnimalInHutch = true,
	ISRemoveAnimalFromTrailer = true,
	ISTakeGenerator = true,
	ISTransferWaterAction = true,
	ISUnequipAction = true,
	ISWearClothing = true,
}

local PREPARATION_CRAFT_RECIPES = {
	ExtinguishCandle = true,
	ExtinguishHurricaneLantern = true,
	LightCandle = true,
	LightHurricaneLantern = true,
}

local TRANSFER_TYPES = {
	ISInventoryTransferAction = true,
}

local INFRASTRUCTURE_TYPES = {
	ISCloseVehicleDoor = true,
	ISEnterVehicle = true,
	ISExitVehicle = true,
	ISOpenCloseCurtain = true,
	ISOpenCloseDoor = true,
	ISOpenCloseWindow = true,
	ISOpenVehicleDoor = true,
	ISPathFindAction = true,
	ISQueueActionsAction = true,
	ISSwitchVehicleSeat = true,
	ISToggleHutchDoor = true,
	ISWaitWhileGettingUp = true,
	ISWalkToTimedAction = true,
}

local INTERNAL_TYPES = {
	P4RestoreAction = true,
	P4RestoreFloorAction = true,
}

local ACTION_EXCEPTIONS = {
	ISBBQLightFromKindle = { queueRestoreOnCancel = true, restoreHands = true },
	ISFireplaceLightFromKindle = { queueRestoreOnCancel = true, restoreHands = true },
	ISFitnessAction = { queueRestoreOnCancel = true, restoreHands = true, restoreWorn = true },
	ISInstallVehiclePart = { restoreHands = true },
	ISLightFromKindle = { queueRestoreOnCancel = true, restoreHands = true },
	ISUninstallVehiclePart = { restoreHands = true },
}

P4TidyUpMeister.registerActionPolicy = function(actionType, policy)
	if not actionType or type(policy) ~= "table" then
		return false
	end
	ACTION_EXCEPTIONS[actionType] = policy
	P4TidyUpMeister.debugLog(nil, nil, "registered action policy " .. tostring(actionType))
	return true
end

-- Public compatibility API. General Timed Actions do not need to register here;
-- this is only for actions that need exceptional cancellation, ignore, or restore behavior.
_G.P4TidyUpMeister = {
	registerActionPolicy = P4TidyUpMeister.registerActionPolicy,
}

-- *****************************************************************************
-- * Session observation functions
-- *****************************************************************************

P4TidyUpMeister.getGridInfo = function(player, item, srcContainer)
	if not getActivatedMods():contains("INVENTORY_TETRIS") then
		return nil
	end
	if not ItemContainerGrid or not ItemContainerGrid.FindInstance then
		return nil
	end
	local srcContainerGrid = ItemContainerGrid.FindInstance(srcContainer, player:getPlayerNum())
	if not srcContainerGrid then
		return nil
	end
	for _,grid in ipairs(srcContainerGrid.grids) do
		for _,stack in ipairs(grid.persistentData.stacks) do
			if stack.itemIDs[item:getID()] then
				return {
					gridIndex = grid.gridIndex,
					x = stack.x,
					y = stack.y,
					isRotated = stack.isRotated,
				}
			end
		end
	end
	return nil
end

P4TidyUpMeister.rememberFloorItem = function(session, item)
	local worldItem = item:getWorldItem()
	if not worldItem then
		return
	end
	local floorInfo = {
		square = worldItem:getSquare(),
		offX = worldItem:getOffX(),
		offY = worldItem:getOffY(),
		offZ = worldItem:getOffZ(),
		rotationX = item:getWorldXRotation(),
		rotationY = item:getWorldYRotation(),
		rotationZ = item:getWorldZRotation(),
	}
	local fullType = item:getFullType()
	session.floorItems[fullType] = floorInfo
	local replaceItem = item:getReplaceOnUseFullType()
	if replaceItem then
		session.floorItems[replaceItem] = floorInfo
	end
	if instanceof(item, "DrainableComboItem") then
		replaceItem = item:getReplaceOnDepleteFullType()
		if replaceItem then
			session.floorItems[replaceItem] = floorInfo
		end
	end
	P4TidyUpMeister.debugLog(session.character, session, "floor source " .. P4TidyUpMeister.itemLabel(item) .. " square=" .. tostring(floorInfo.square))
end

P4TidyUpMeister.rememberTransfer = function(session, action)
	local item = action.item
	local srcContainer = action.srcContainer or (item and item:getContainer())
	if not item or not srcContainer or srcContainer:getType() == "none" then
		return
	end
	if not session.transferredItems[item] then
		session.transferredItems[item] = {
			action = action,
			container = srcContainer,
			gridInfo = P4TidyUpMeister.getGridInfo(session.character, item, srcContainer),
			hasFollowingOperation = false,
		}
		session.transferCount = session.transferCount + 1
		if session.transferCount <= MAX_VERBOSE_TRANSFER_LOGS then
			P4TidyUpMeister.debugLog(session.character, session, "remember transfer " .. P4TidyUpMeister.itemLabel(item) .. " -> " .. tostring(action.destContainer and action.destContainer:getType()))
		elseif session.transferCount == MAX_VERBOSE_TRANSFER_LOGS + 1 then
			P4TidyUpMeister.debugLog(session.character, session, "further transfer details suppressed; totals remain in the session summary")
		end
	end
	if srcContainer:getType() == "floor" then
		P4TidyUpMeister.rememberFloorItem(session, item)
		if session.armed then
			P4TidyUpMeister.restoreFloor[session.character] = session.floorItems
		end
	end
end

P4TidyUpMeister.updateTransferOperationEvidence = function(session, queue)
	if not queue or session.operationCount == 0 then
		return
	end
	local actionIndices = {}
	for index,action in ipairs(queue.queue) do
		actionIndices[action] = index
	end
	for item,containerInfo in pairs(session.transferredItems) do
		if not containerInfo.hasFollowingOperation then
			local transferIndex = actionIndices[containerInfo.action]
			if transferIndex then
				for operationAction in pairs(session.operationActions) do
					local operationIndex = actionIndices[operationAction]
					if operationIndex and operationIndex > transferIndex then
						containerInfo.hasFollowingOperation = true
						P4TidyUpMeister.debugLog(session.character, session, "link transfer "
							.. P4TidyUpMeister.itemLabel(item) .. " -> operation "
							.. P4TidyUpMeister.actionTypeOf(operationAction))
						break
					end
				end
			end
		end
	end
end

P4TidyUpMeister.captureSession = function(player)
	local session = {
		id = P4TidyUpMeister.nextSessionId,
		character = player,
		primaryItem = player:getPrimaryHandItem(),
		secondaryItem = player:getSecondaryHandItem(),
		primaryActivated = false,
		secondaryActivated = false,
		inventoryItems = {},
		wornItems = {},
		transferredItems = {},
		floorItems = {},
		craftRecipes = {},
		operationActions = {},
		operationCount = 0,
		actions = {},
		actionCounts = {},
		actionTotal = 0,
		transferCount = 0,
		sawPreparation = false,
		sawTransfer = false,
		sawOperation = false,
		armed = false,
		restoreHands = false,
		restoreWorn = false,
		cancelled = false,
		restoreOnCancel = true,
		idleTicks = 0,
	}
	P4TidyUpMeister.nextSessionId = P4TidyUpMeister.nextSessionId + 1
	if session.primaryItem and session.primaryItem:canBeActivated() then
		session.primaryActivated = session.primaryItem:isActivated()
	end
	if session.secondaryItem and session.secondaryItem:canBeActivated() then
		session.secondaryActivated = session.secondaryItem:isActivated()
	end
	local inventoryItems = player:getInventory():getItems()
	for i=0, inventoryItems:size()-1 do
		session.inventoryItems[inventoryItems:get(i)] = true
	end
	local wornItems = player:getWornItems()
	local wornLabels = {}
	for i=0, wornItems:size()-1 do
		local wornItem = wornItems:get(i)
		session.wornItems[wornItem:getLocation()] = wornItem:getItem()
		table.insert(wornLabels, tostring(wornItem:getLocation()) .. "=" .. P4TidyUpMeister.itemLabel(wornItem:getItem()))
	end
	P4TidyUpMeister.debugLog(player, session, "capture primary=" .. P4TidyUpMeister.itemLabel(session.primaryItem) .. " secondary=" .. P4TidyUpMeister.itemLabel(session.secondaryItem))
	P4TidyUpMeister.debugLog(player, session, "capture worn=[" .. table.concat(wornLabels, ", ") .. "] inventoryCount=" .. tostring(inventoryItems:size()))
	P4TidyUpMeister.debugHalo(player, "watch #" .. tostring(session.id))
	return session
end

P4TidyUpMeister.actionTypeOf = function(action)
	return action and (action.Type or action.type) or "UnknownAction"
end

P4TidyUpMeister.armSession = function(session, reason)
	if session.armed then
		return
	end
	session.armed = true
	session.armReason = reason
	P4TidyUpMeister.restoreFloor[session.character] = session.floorItems
	P4TidyUpMeister.debugLog(session.character, session, "ARM reason=" .. tostring(reason))
	P4TidyUpMeister.debugHalo(session.character, "armed #" .. tostring(session.id))
end

P4TidyUpMeister.observeAction = function(session, action, source, queue)
	local actionType = P4TidyUpMeister.actionTypeOf(action)
	session.actionTotal = session.actionTotal + 1
	session.actionCounts[actionType] = (session.actionCounts[actionType] or 0) + 1
	if #session.actions < MAX_ACTION_TRACE then
		table.insert(session.actions, actionType)
	end
	if session.actionTotal <= MAX_VERBOSE_ACTION_LOGS then
		P4TidyUpMeister.debugLog(session.character, session, string.format("add[%s] type=%s item=%s", tostring(source), tostring(actionType), P4TidyUpMeister.itemLabel(action.item)))
	elseif session.actionTotal == MAX_VERBOSE_ACTION_LOGS + 1 then
		P4TidyUpMeister.debugLog(session.character, session, "further per-action logs suppressed; trace and counts remain in the session summary")
	end

	if INTERNAL_TYPES[actionType] then
		return
	end
	if TRANSFER_TYPES[actionType] then
		session.sawTransfer = true
		P4TidyUpMeister.rememberTransfer(session, action)
		if source == "addAfter" then
			P4TidyUpMeister.updateTransferOperationEvidence(session, queue)
		end
		return
	end
	if PREPARATION_TYPES[actionType] then
		session.sawPreparation = true
		return
	end
	if actionType == "ISHandcraftAction" and action.craftRecipe then
		local recipeName = tostring(action.craftRecipe:getName())
		if PREPARATION_CRAFT_RECIPES[recipeName] then
			session.sawPreparation = true
			P4TidyUpMeister.debugLog(session.character, session, "preparation craft recipe=" .. recipeName)
			return
		end
	end
	if INFRASTRUCTURE_TYPES[actionType] then
		return
	end

	session.sawOperation = true
	if actionType == "ISHandcraftAction" and action.craftRecipe then
		session.craftRecipes[action.craftRecipe] = true
	end
	if actionType == "ISMoveablesAction" and action.mode == "scrap" then
		session.sawDismantle = true
		session.restoreHands = true
		session.restoreWorn = true
	elseif actionType == "ISHandcraftAction" and action.craftRecipe then
		local recipeName = string.lower(tostring(action.craftRecipe:getName()))
		if string.find(recipeName, "dismantle", 1, true) or string.find(recipeName, "disassemble", 1, true) then
			session.sawDismantle = true
			session.restoreHands = true
			session.restoreWorn = true
			P4TidyUpMeister.debugLog(session.character, session, "dismantle recipe=" .. tostring(action.craftRecipe:getName()))
		end
	end
	local policy = ACTION_EXCEPTIONS[actionType]
	if policy and policy.ignore then
		P4TidyUpMeister.debugLog(session.character, session, "ignored by action policy: " .. actionType)
		return
	end
	if policy and policy.restoreOnCancel == false then
		session.restoreOnCancel = false
	end
	if policy and policy.queueRestoreOnCancel then
		session.queueRestoreOnCancel = true
	end
	if policy and policy.restoreHands then
		session.restoreHands = true
	end
	if policy and policy.restoreWorn then
		session.restoreWorn = true
	end
	if not session.operationActions[action] then
		session.operationActions[action] = true
		session.operationCount = session.operationCount + 1
	end
	P4TidyUpMeister.updateTransferOperationEvidence(session, queue)
	P4TidyUpMeister.armSession(session, "operation:" .. actionType)
end

P4TidyUpMeister.shouldObserveCharacter = function(character)
	return character
		and instanceof(character, "IsoPlayer")
		and character:isLocalPlayer()
		and not P4TidyUpMeister.restoring[character]
end

P4TidyUpMeister.prepareQueueAdd = function(action)
	local character = action and action.character
	if not P4TidyUpMeister.shouldObserveCharacter(character) then
		return nil
	end
	local modData = character:getModData()
	if modData.P4TidyUpMeister and modData.P4TidyUpMeister.doNotReequip then
		return nil
	end
	local session = P4TidyUpMeister.sessions[character]
	if not session then
		session = P4TidyUpMeister.captureSession(character)
		P4TidyUpMeister.sessions[character] = session
	end
	local queue = ISTimedActionQueue.getTimedActionQueue(character)
	if session.actionTotal < 3 then
		P4TidyUpMeister.debugLog(character, session, "queue-size-before=" .. tostring(#queue.queue))
	end
	return session
end

P4TidyUpMeister.observeQueuedAction = function(session, action, source, queue)
	if not session then
		return
	end
	if session.pendingCancelReason then
		P4TidyUpMeister.debugLog(action.character, session, "CONTINUE after " .. tostring(session.pendingCancelReason))
		session.pendingCancelReason = nil
	end
	session.idleTicks = 0
	P4TidyUpMeister.observeAction(session, action, source, queue)
end

P4TidyUpMeister.markQueueCancelled = function(queue, reason)
	local character = queue and queue.character
	local session = character and P4TidyUpMeister.sessions[character]
	if not session or P4TidyUpMeister.restoring[character] then
		return
	end
	if #queue.queue == 0 and not queue.current then
		return
	end
	session.pendingCancelReason = reason
	session.cancelAction = queue.current or queue.queue[1]
	session.idleTicks = 0
	P4TidyUpMeister.debugLog(character, session, "CANCEL pending reason=" .. tostring(reason))
end

P4TidyUpMeister.isSuccessfulQueueReset = function(session)
	if not isClient() then
		return false
	end
	local action = session.cancelAction
	if not action or action.Type ~= "ISMoveablesAction" or action.mode ~= "scrap" then
		return false
	end
	local object = action.moveProps and action.moveProps.object
	return object and object:getObjectIndex() == -1
end

-- *****************************************************************************
-- * Restore functions
-- *****************************************************************************

P4TidyUpMeister.findReplacementItems = function(session)
	local addedItems = {}
	local inventoryItems = session.character:getInventory():getItems()
	for i=0, inventoryItems:size()-1 do
		local item = inventoryItems:get(i)
		if not session.inventoryItems[item] then
			table.insert(addedItems, item)
		end
	end
	return addedItems
end

P4TidyUpMeister.destinationIsAvailable = function(player, destContainer)
	if destContainer == player:getInventory() then
		return true
	end
	local playerLoot = getPlayerLoot(player:getPlayerNum())
	if playerLoot and playerLoot.backpacks then
		for _,backpack in ipairs(playerLoot.backpacks) do
			if backpack.inventory == destContainer then
				return true
			end
		end
	end
	local containingItem = destContainer:getContainingItem()
	return containingItem and player:getInventory():containsRecursive(containingItem)
end

P4TidyUpMeister.findReplacement = function(session, item, addedItems, usedItems)
	local replaceItems = {}
	local replaceItemSet = {}
	local function addReplaceItem(replaceItem)
		if replaceItem and not replaceItemSet[replaceItem] then
			replaceItemSet[replaceItem] = true
			table.insert(replaceItems, replaceItem)
		end
	end
	local replaceItem = item:getReplaceOnUse()
	if not replaceItem and instanceof(item, "DrainableComboItem") then
		replaceItem = item:getReplaceOnDeplete()
	end
	if not replaceItem then
		replaceItem = item:getReplaceType("PetrolSource")
	end
	if replaceItem then
		addReplaceItem(replaceItem)
	end
	local sourceScriptItem = item:getScriptItem()
	if sourceScriptItem then
		for craftRecipe in pairs(session.craftRecipes) do
			local outputs = craftRecipe:getOutputs()
			for i=0,outputs:size()-1 do
				local output = outputs:get(i)
				local outputMapper = output:getOutputMapper()
				if outputMapper and output:getIntAmount() <= 1 then
					local resultItems = outputMapper:getResultItems()
					for j=0,resultItems:size()-1 do
						local resultItem = resultItems:get(j)
						local pattern = outputMapper:getPatternForResult(resultItem)
						local matchesSource = false
						for k=0,pattern:size()-1 do
							if pattern:get(k) == sourceScriptItem then
								matchesSource = true
								break
							end
						end
						if matchesSource then
							addReplaceItem(resultItem:getFullName())
							addReplaceItem(resultItem:getReplaceOnUse())
						end
					end
				end
			end
		end
	end
	if #replaceItems == 0 then
		local resultItems = P4TidyUpMeister.evolvedRecipes[item:getFullType()]
		if resultItems then
			for _,resultItem in pairs(resultItems) do
				addReplaceItem(resultItem)
			end
		end
	end
	for _,candidateType in pairs(replaceItems) do
		for _,addedItem in ipairs(addedItems) do
			if not usedItems[addedItem]
				and (candidateType == addedItem:getFullType() or candidateType == addedItem:getType()) then
				return addedItem
			end
		end
	end
	return nil
end

P4TidyUpMeister.queueTransferRestore = function(session, item, containerInfo)
	local player = session.character
	local inventory = player:getInventory()
	local destContainer = containerInfo.container
	local action = ISInventoryTransferAction:new(player, item, inventory, destContainer)
	local gridInfo = containerInfo.gridInfo
	if gridInfo and action.setTetrisTarget then
		action:setTetrisTarget(gridInfo.x, gridInfo.y, gridInfo.gridIndex, gridInfo.isRotated)
	end
	P4TidyUpMeister.debugLog(player, session, "queue transfer restore " .. P4TidyUpMeister.itemLabel(item) .. " -> " .. tostring(destContainer:getType()))
	ISTimedActionQueue.add(action)
	P4TidyUpMeister.queueFloorRestore(session, item)
end

P4TidyUpMeister.queueFloorRestore = function(session, item)
	if not isClient() then
		return
	end
	local floorInfo = session.floorItems[item:getFullType()]
	if not floorInfo or not floorInfo.square then
		return
	end
	P4TidyUpMeister.debugLog(session.character, session, "queue MP floor restore for " .. P4TidyUpMeister.itemLabel(item))
	ISTimedActionQueue.add(P4RestoreFloorAction:new(
		session.character,
		item,
		floorInfo.square:getX(),
		floorInfo.square:getY(),
		floorInfo.square:getZ(),
		floorInfo.offX,
		floorInfo.offY,
		floorInfo.offZ,
		floorInfo.rotationX,
		floorInfo.rotationY,
		floorInfo.rotationZ,
		P4TidyUpMeister.options.DebugOutput.selected >= DEBUG_OUTPUT_LOG
	))
end

P4TidyUpMeister.inheritFloorInfo = function(session, sourceItem, replacement)
	local floorInfo = session.floorItems[sourceItem:getFullType()]
	if floorInfo then
		session.floorItems[replacement:getFullType()] = floorInfo
	end
end

P4TidyUpMeister.queueTransferRestores = function(session, addedItems)
	local player = session.character
	local inventory = player:getInventory()
	local usedItems = {}
	local unresolved = {}

	for item,containerInfo in pairs(session.transferredItems) do
		local destContainer = containerInfo.container
		if not containerInfo.hasFollowingOperation then
			P4TidyUpMeister.debugLog(player, session, "skip transfer without following operation " .. P4TidyUpMeister.itemLabel(item))
		elseif not P4TidyUpMeister.destinationIsAvailable(player, destContainer) then
			P4TidyUpMeister.debugLog(player, session, "skip unavailable destination for " .. P4TidyUpMeister.itemLabel(item))
		elseif item:getContainer() == destContainer then
			P4TidyUpMeister.debugLog(player, session, "already restored " .. P4TidyUpMeister.itemLabel(item))
			P4TidyUpMeister.queueFloorRestore(session, item)
		elseif item:getContainer() == inventory then
			usedItems[item] = true
			P4TidyUpMeister.queueTransferRestore(session, item, containerInfo)
		else
			local replacement = nil
			if not session.sawDismantle then
				if isMultiplayer() then
					local inventoryItems = inventory:getItems()
					for i=0, inventoryItems:size()-1 do
						local inventoryItem = inventoryItems:get(i)
						if not usedItems[inventoryItem]
							and not session.inventoryItems[inventoryItem]
							and inventoryItem:getType() == item:getType() then
							replacement = inventoryItem
							break
						end
					end
				end
				if not replacement then
					replacement = P4TidyUpMeister.findReplacement(session, item, addedItems, usedItems)
				end
			end
			if replacement then
				usedItems[replacement] = true
				P4TidyUpMeister.inheritFloorInfo(session, item, replacement)
				P4TidyUpMeister.queueTransferRestore(session, replacement, containerInfo)
			else
				table.insert(unresolved, { item = item, containerInfo = containerInfo })
			end
		end
	end

	local unassignedAddedItems = {}
	for _,addedItem in ipairs(addedItems) do
		if not usedItems[addedItem] and addedItem:getContainer() == inventory then
			table.insert(unassignedAddedItems, addedItem)
		end
	end
	if session.sawDismantle and P4TidyUpMeister.optionEnabled("RestoreDismantleOutputs")
		and #unresolved > 0 and #unassignedAddedItems > 0 then
		local outputContainer = unresolved[1].containerInfo.container
		local hasSingleDestination = true
		for i=2,#unresolved do
			if unresolved[i].containerInfo.container ~= outputContainer then
				hasSingleDestination = false
				break
			end
		end
		if hasSingleDestination then
			P4TidyUpMeister.debugLog(player, session, "restore dismantle outputs count=" .. tostring(#unassignedAddedItems)
				.. " -> " .. tostring(outputContainer:getType()))
			for _,outputItem in ipairs(unassignedAddedItems) do
				P4TidyUpMeister.queueTransferRestore(session, outputItem, { container = outputContainer })
			end
			return
		end
		P4TidyUpMeister.debugLog(player, session, "skip dismantle outputs because source destinations are ambiguous")
	end
	for _,entry in ipairs(unresolved) do
		P4TidyUpMeister.debugLog(player, session, "no unambiguous replacement found for " .. P4TidyUpMeister.itemLabel(entry.item))
	end
end

P4TidyUpMeister.queueRestore = function(session)
	local player = session.character
	P4TidyUpMeister.sessions[player] = nil
	P4TidyUpMeister.restoring[player] = {
		sessionId = session.id,
		idleTicks = 0,
	}
	P4TidyUpMeister.restoreFloor[player] = session.floorItems
	P4TidyUpMeister.debugLog(player, session, "RESTORE actionTotal=" .. tostring(session.actionTotal)
		.. " trace=[" .. table.concat(session.actions, " -> ") .. "] reason=" .. tostring(session.armReason))
	P4TidyUpMeister.debugHalo(player, "restore #" .. tostring(session.id))

	if session.restoreHands then
		local currentPrimary = player:getPrimaryHandItem()
		local currentSecondary = player:getSecondaryHandItem()
		local wasTwoHanded = session.primaryItem and session.primaryItem == session.secondaryItem
		local isTwoHanded = currentPrimary and currentPrimary == currentSecondary

		if session.primaryItem then
			local needsPrimaryEquip = currentPrimary ~= session.primaryItem
				or (wasTwoHanded and currentSecondary ~= session.primaryItem)
			if needsPrimaryEquip then
				ISTimedActionQueue.add(ISEquipWeaponAction:new(player, session.primaryItem, 50, true, wasTwoHanded))
			end
			if needsPrimaryEquip or (session.primaryItem:canBeActivated()
				and session.primaryItem:isActivated() ~= session.primaryActivated) then
				ISTimedActionQueue.add(P4RestoreAction:new(player, session.primaryItem, session.primaryActivated))
			end
		elseif currentPrimary then
			ISTimedActionQueue.add(ISUnequipAction:new(player, currentPrimary, 50))
		end

		if session.secondaryItem then
			if not wasTwoHanded then
				local needsSecondaryEquip = currentSecondary ~= session.secondaryItem
				if needsSecondaryEquip then
					ISTimedActionQueue.add(ISEquipWeaponAction:new(player, session.secondaryItem, 50, false, false))
				end
				if needsSecondaryEquip or (session.secondaryItem:canBeActivated()
					and session.secondaryItem:isActivated() ~= session.secondaryActivated) then
					ISTimedActionQueue.add(P4RestoreAction:new(player, session.secondaryItem, session.secondaryActivated))
				end
			end
		elseif currentSecondary and not isTwoHanded then
			ISTimedActionQueue.add(ISUnequipAction:new(player, currentSecondary, 50))
		end
	end

	if session.restoreWorn then
		local currentWornItems = {}
		local wornItems = player:getWornItems()
		for i=0, wornItems:size()-1 do
			local wornItem = wornItems:get(i)
			local location = wornItem:getLocation()
			currentWornItems[location] = wornItem:getItem()
			if not session.wornItems[location] then
				ISTimedActionQueue.add(ISUnequipAction:new(player, wornItem:getItem(), 50))
			end
		end
		for location,wornItem in pairs(session.wornItems) do
			if wornItem ~= currentWornItems[location] then
				ISTimedActionQueue.add(ISWearClothing:new(player, wornItem, 50))
			end
		end
	end

	local addedItems = P4TidyUpMeister.findReplacementItems(session)
	P4TidyUpMeister.queueTransferRestores(session, addedItems)
end

P4TidyUpMeister.forceRestoreHands = function(session)
	local player = session.character
	player:setPrimaryHandItem(session.primaryItem)
	player:setSecondaryHandItem(session.secondaryItem)
	P4TidyUpMeister.debugLog(player, session, "force-restored hands after cancellation")
	P4TidyUpMeister.debugHalo(player, "force restore #" .. tostring(session.id))
end

P4TidyUpMeister.finishSession = function(session)
	local player = session.character
	local actionCounts = {}
	for actionType,count in pairs(session.actionCounts) do
		table.insert(actionCounts, actionType .. "=" .. tostring(count))
	end
	table.sort(actionCounts)
	P4TidyUpMeister.debugLog(player, session, "finish armed=" .. tostring(session.armed)
		.. " cancelled=" .. tostring(session.cancelled)
		.. " prep=" .. tostring(session.sawPreparation)
		.. " transfer=" .. tostring(session.sawTransfer)
		.. " operation=" .. tostring(session.sawOperation)
		.. " dismantle=" .. tostring(session.sawDismantle)
		.. " restoreHands=" .. tostring(session.restoreHands)
		.. " restoreWorn=" .. tostring(session.restoreWorn)
		.. " queueRestoreOnCancel=" .. tostring(session.queueRestoreOnCancel)
		.. " actionTotal=" .. tostring(session.actionTotal)
		.. " transferCount=" .. tostring(session.transferCount)
		.. " counts=[" .. table.concat(actionCounts, ", ") .. "]"
		.. " trace=[" .. table.concat(session.actions, " -> ") .. "]")

	if not session.armed then
		P4TidyUpMeister.sessions[player] = nil
		P4TidyUpMeister.debugHalo(player, "skip #" .. tostring(session.id))
		return
	end
	if session.cancelled then
		P4TidyUpMeister.sessions[player] = nil
		if session.queueRestoreOnCancel then
			P4TidyUpMeister.debugLog(player, session, "cancelled action uses normal queue restore")
			P4TidyUpMeister.queueRestore(session)
		elseif session.restoreOnCancel and P4TidyUpMeister.optionEnabled("ForceReequip") then
			P4TidyUpMeister.restoreFloor[player] = nil
			P4TidyUpMeister.forceRestoreHands(session)
		else
			P4TidyUpMeister.restoreFloor[player] = nil
			P4TidyUpMeister.debugLog(player, session, "cancelled session discarded restoreOnCancel=" .. tostring(session.restoreOnCancel))
		end
		return
	end
	P4TidyUpMeister.queueRestore(session)
end

-- *****************************************************************************
-- * ModData functions
-- *****************************************************************************

P4TidyUpMeister.setDoNotReequip = function(player)
	local modData = player:getModData()
	if not modData.P4TidyUpMeister then
		modData.P4TidyUpMeister = {
			doNotReequip = false,
		}
		player:transmitModData()
	end
end

P4TidyUpMeister.toggleDoNotReequip = function(player)
	P4TidyUpMeister.setDoNotReequip(player)
	local modData = player:getModData()
	modData.P4TidyUpMeister.doNotReequip = not modData.P4TidyUpMeister.doNotReequip
	player:transmitModData()
	local textKey = modData.P4TidyUpMeister.doNotReequip
		and "UI_P4TidyUpMeister_Messages_ToDoNotReequip"
		or "UI_P4TidyUpMeister_Messages_ToDoReequip"
	player:Say(getText(textKey), 0.607, 0.717, 1.000, UIFont.Dialogue, 15, "radio")
	P4TidyUpMeister.debugLog(player, nil, "doNotReequip=" .. tostring(modData.P4TidyUpMeister.doNotReequip))
end

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

P4TidyUpMeister.OnPlayerUpdate = function(player)
	if not player or not player:isLocalPlayer() then
		return
	end
	local queue = ISTimedActionQueue.getTimedActionQueue(player)
	local restoring = P4TidyUpMeister.restoring[player]
	if restoring then
		if #queue.queue == 0 and not player:hasTimedActions() then
			restoring.idleTicks = restoring.idleTicks + 1
			if restoring.idleTicks >= 2 then
				P4TidyUpMeister.debugLog(player, nil, "restore queue complete S" .. tostring(restoring.sessionId))
				P4TidyUpMeister.debugHalo(player, "done #" .. tostring(restoring.sessionId))
				P4TidyUpMeister.restoring[player] = nil
				P4TidyUpMeister.restoreFloor[player] = nil
			end
		else
			restoring.idleTicks = 0
		end
		return
	end

	local session = P4TidyUpMeister.sessions[player]
	if not session then
		return
	end
	if session.pendingCancelReason then
		if #queue.queue > 0 or player:hasTimedActions() then
			P4TidyUpMeister.debugLog(player, session, "CONTINUE queued after " .. tostring(session.pendingCancelReason))
			session.pendingCancelReason = nil
			session.cancelAction = nil
		elseif P4TidyUpMeister.isSuccessfulQueueReset(session) then
			P4TidyUpMeister.debugLog(player, session, "RESET treated as completed MP dismantle")
			session.pendingCancelReason = nil
			session.cancelAction = nil
		else
			session.cancelled = true
			session.cancelReason = session.pendingCancelReason
			session.pendingCancelReason = nil
			session.cancelAction = nil
			P4TidyUpMeister.debugLog(player, session, "CANCEL confirmed reason=" .. tostring(session.cancelReason))
			P4TidyUpMeister.debugHalo(player, "cancel #" .. tostring(session.id))
		end
	end
	if #queue.queue == 0 and not player:hasTimedActions() then
		session.idleTicks = session.idleTicks + 1
		if session.idleTicks >= 2 then
			P4TidyUpMeister.finishSession(session)
		end
	else
		session.idleTicks = 0
	end
end
Events.OnPlayerUpdate.Add(P4TidyUpMeister.OnPlayerUpdate)

P4TidyUpMeister.OnCreatePlayer = function(playerIndex, player)
	P4TidyUpMeister.setDoNotReequip(player)
	P4TidyUpMeister.debugLog(player, nil, "debug observer ready")
	P4TidyUpMeister.debugHalo(player, "debug ready")
end
Events.OnCreatePlayer.Add(P4TidyUpMeister.OnCreatePlayer)

P4TidyUpMeister.OnFillWorldObjectContextMenu = function(playerIndex, context, worldObjects, test)
	if not P4TidyUpMeister.optionEnabled("UseContextMenu") then
		return
	end
	local player = getSpecificPlayer(playerIndex)
	if not player then
		return
	end
	P4TidyUpMeister.setDoNotReequip(player)
	local disabled = player:getModData().P4TidyUpMeister.doNotReequip
	local textKey = disabled
		and "ContextMenu_P4TidyUpMeister_ToDoReequip"
		or "ContextMenu_P4TidyUpMeister_ToDoNotReequip"
	context:addOption(getText(textKey), player, P4TidyUpMeister.toggleDoNotReequip)
end
Events.OnFillWorldObjectContextMenu.Add(P4TidyUpMeister.OnFillWorldObjectContextMenu)

P4TidyUpMeister.OnLoad = function()
	table.wipe(P4TidyUpMeister.evolvedRecipes)
	local evolvedRecipes = getEvolvedRecipes()
	for i=0, evolvedRecipes:size()-1 do
		local evolvedRecipe = evolvedRecipes:get(i)
		local baseItem = evolvedRecipe:getBaseItem()
		local resultItem = evolvedRecipe:getFullResultItem()
		local resultItems = P4TidyUpMeister.evolvedRecipes[baseItem]
		if not resultItems then
			resultItems = {}
			P4TidyUpMeister.evolvedRecipes[baseItem] = resultItems
		end
		table.insert(resultItems, resultItem)
	end
	P4TidyUpMeister.debugLog(nil, nil, "loaded; debug observer enabled")
end
Events.OnLoad.Add(P4TidyUpMeister.OnLoad)

-- *****************************************************************************
-- * Timed Action Queue hooks
-- *****************************************************************************

P4TidyUpMeister.ISTimedActionQueue_add = ISTimedActionQueue.add
ISTimedActionQueue.add = function(action)
	local session = P4TidyUpMeister.prepareQueueAdd(action)
	local queue = P4TidyUpMeister.ISTimedActionQueue_add(action)
	if queue then
		P4TidyUpMeister.observeQueuedAction(session, action, "add", queue)
	end
	return queue
end

P4TidyUpMeister.ISTimedActionQueue_addAfter = ISTimedActionQueue.addAfter
ISTimedActionQueue.addAfter = function(previousAction, action)
	local session = P4TidyUpMeister.prepareQueueAdd(action)
	local queue, addedAction = P4TidyUpMeister.ISTimedActionQueue_addAfter(previousAction, action)
	if queue and addedAction then
		P4TidyUpMeister.observeQueuedAction(session, action, "addAfter", queue)
	end
	return queue, addedAction
end

P4TidyUpMeister.ISTimedActionQueue_resetQueue = ISTimedActionQueue.resetQueue
function ISTimedActionQueue:resetQueue()
	P4TidyUpMeister.markQueueCancelled(self, "resetQueue")
	return P4TidyUpMeister.ISTimedActionQueue_resetQueue(self)
end

P4TidyUpMeister.ISTimedActionQueue_clearQueue = ISTimedActionQueue.clearQueue
function ISTimedActionQueue:clearQueue()
	P4TidyUpMeister.markQueueCancelled(self, "clearQueue")
	return P4TidyUpMeister.ISTimedActionQueue_clearQueue(self)
end

-- *****************************************************************************
-- * Floor restoration hooks
-- *****************************************************************************

P4TidyUpMeister.ISInventoryTransferAction_getNotFullFloorSquare = ISInventoryTransferAction.getNotFullFloorSquare
function ISInventoryTransferAction:getNotFullFloorSquare(item)
	local dropSquare = P4TidyUpMeister.ISInventoryTransferAction_getNotFullFloorSquare(self, item)
	local floorItems = P4TidyUpMeister.restoreFloor[self.character]
	local floorInfo = floorItems and floorItems[item:getFullType()]
	if dropSquare and floorInfo and floorInfo.square then
		local diffX = math.abs(floorInfo.square:getX() - dropSquare:getX())
		local diffY = math.abs(floorInfo.square:getY() - dropSquare:getY())
		local diffZ = math.abs(floorInfo.square:getZ() - dropSquare:getZ())
		if diffX <= 1 and diffY <= 1 and diffZ == 0 then
			P4TidyUpMeister.debugLog(self.character, nil, "restore floor square for " .. P4TidyUpMeister.itemLabel(item))
			return floorInfo.square
		end
	end
	return dropSquare
end

P4TidyUpMeister.ISTransferAction_GetDropItemOffset = ISTransferAction.GetDropItemOffset
function ISTransferAction.GetDropItemOffset(character, square, item)
	local floorItems = P4TidyUpMeister.restoreFloor[character]
	local floorInfo = item and floorItems and floorItems[item:getFullType()]
	if floorInfo then
		P4TidyUpMeister.debugLog(character, nil, "restore floor offset for " .. P4TidyUpMeister.itemLabel(item))
		return floorInfo.offX, floorInfo.offY, floorInfo.offZ
	end
	return P4TidyUpMeister.ISTransferAction_GetDropItemOffset(character, square, item)
end

P4TidyUpMeister.ISTransferAction_transferItem = ISTransferAction.transferItem
function ISTransferAction:transferItem(character, item, srcContainer, destContainer, dropSquare)
	local result = P4TidyUpMeister.ISTransferAction_transferItem(self, character, item, srcContainer, destContainer, dropSquare)
	local floorItems = P4TidyUpMeister.restoreFloor[character]
	local floorInfo = result and floorItems and floorItems[result:getFullType()]
	if floorInfo and destContainer:getType() == "floor" then
		result:setWorldXRotation(floorInfo.rotationX)
		result:setWorldYRotation(floorInfo.rotationY)
		result:setWorldZRotation(floorInfo.rotationZ)
		P4TidyUpMeister.debugLog(character, nil, "restore floor rotation for " .. P4TidyUpMeister.itemLabel(result))
	end
	return result
end
