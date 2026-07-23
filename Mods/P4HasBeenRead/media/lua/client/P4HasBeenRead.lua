local P4HasBeenRead = {}

P4HasBeenRead.doNotAutoMark = false

P4HasBeenRead.textureBookNR = getTexture("media/ui/P4HasBeenRead_Book_NR.png")
P4HasBeenRead.textureBookNC = getTexture("media/ui/P4HasBeenRead_Book_NC.png")
P4HasBeenRead.textureBookAR = getTexture("media/ui/P4HasBeenRead_Book_AR.png")
P4HasBeenRead.textureBookSM = getTexture("media/ui/P4HasBeenRead_Book_SM.png")
P4HasBeenRead.textureBookCT = getTexture("media/ui/P4HasBeenRead_Book_CT.png")

P4HasBeenRead.notReadTexture = P4HasBeenRead.textureBookNR
P4HasBeenRead.notCompletedTexture = P4HasBeenRead.textureBookNC
P4HasBeenRead.alreadyReadTexture = nil
P4HasBeenRead.selfMarkingTexture = P4HasBeenRead.textureBookSM
P4HasBeenRead.currentTargetTexture = P4HasBeenRead.textureBookCT

P4HasBeenRead.Messages_ToDoAutoMark = getText("UI_P4HasBeenRead_Messages_ToDoAutoMark")
P4HasBeenRead.Messages_ToDoNotAutoMark = getText("UI_P4HasBeenRead_Messages_ToDoNotAutoMark")
P4HasBeenRead.ContextMenu_ToDoAutoMark = getText("ContextMenu_P4HasBeenRead_ToDoAutoMark")
P4HasBeenRead.ContextMenu_ToDoNotAutoMark = getText("ContextMenu_P4HasBeenRead_ToDoNotAutoMark")

P4HasBeenRead.recordedMediaResult = {}

P4HasBeenRead.status = nil
P4HasBeenRead.marking = nil
P4HasBeenRead.current = nil

-- *****************************************************************************
-- * Options
-- *****************************************************************************

P4HasBeenRead.options = {
	showNR = true,
	showNC = true,
	showAR = false,
	showNCasNR = false,
	showSM = true,
	showCT = true,
	enableMap = true,
	enableCD = true,
	enableVHS = true,
	enableHVHS = true,
	autoMark = false,
	reverseMarkDisplay = false,
}

SetModOptions = function(options)
	P4HasBeenRead.options = options
end

-- *****************************************************************************
-- * ModData functions
-- *****************************************************************************

P4HasBeenRead.getReadMap = function()
	local modData = ModData.getOrCreate("P4HasBeenRead")
	if not modData.readMap then
		modData.readMap = {}
	end
	return modData.readMap
end

P4HasBeenRead.getMarkedMap = function()
	local modData = getPlayer():getModData()
	if not modData.P4HasBeenRead then
		modData.P4HasBeenRead = {}
		modData.P4HasBeenRead.markedMap = {}
	end
	return modData.P4HasBeenRead.markedMap
end

P4HasBeenRead.marked = function(type)
	local markedMap = P4HasBeenRead.getMarkedMap()
	markedMap[type] = ""
end

P4HasBeenRead.markedAll = function(types)
	for i,v in ipairs(types) do
		P4HasBeenRead.marked(v)
	end
end

P4HasBeenRead.unmarked = function(type)
	local markedMap = P4HasBeenRead.getMarkedMap()
	markedMap[type] = nil
end

P4HasBeenRead.unmarkedAll = function(types)
	for i,v in ipairs(types) do
		P4HasBeenRead.unmarked(v)
	end
end

P4HasBeenRead.setDoNotAutoMark = function()
	local modData = getPlayer():getModData()
	if not modData.P4HasBeenRead then
		modData.P4HasBeenRead = {}
		modData.P4HasBeenRead.doNotAutoMark = false
	end
	P4HasBeenRead.doNotAutoMark = modData.P4HasBeenRead.doNotAutoMark
end

P4HasBeenRead.toggleDoNotAutoMark = function()
	local modData = getPlayer():getModData()
	modData.P4HasBeenRead.doNotAutoMark = not modData.P4HasBeenRead.doNotAutoMark
	P4HasBeenRead.doNotAutoMark = modData.P4HasBeenRead.doNotAutoMark
	if P4HasBeenRead.doNotAutoMark then
		P4HasBeenRead.showInfo(P4HasBeenRead.Messages_ToDoNotAutoMark)
	else
		P4HasBeenRead.showInfo(P4HasBeenRead.Messages_ToDoAutoMark)
	end
end

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

SetTextures = function()
	if ModOptions and ModOptions.getInstance then
		P4HasBeenRead.notReadTexture = nil
		if P4HasBeenRead.options.showNR then
			P4HasBeenRead.notReadTexture = P4HasBeenRead.textureBookNR
		end
		P4HasBeenRead.notCompletedTexture = nil
		if P4HasBeenRead.options.showNC then
			if P4HasBeenRead.options.showNCasNR then
				P4HasBeenRead.notCompletedTexture = P4HasBeenRead.textureBookNR
			else
				P4HasBeenRead.notCompletedTexture = P4HasBeenRead.textureBookNC
			end
		end
		P4HasBeenRead.alreadyReadTexture = nil
		if P4HasBeenRead.options.showAR then
			P4HasBeenRead.alreadyReadTexture = P4HasBeenRead.textureBookAR
		end
		P4HasBeenRead.selfMarkingTexture = nil
		if P4HasBeenRead.options.showSM then
			P4HasBeenRead.selfMarkingTexture = P4HasBeenRead.textureBookSM
		end
		P4HasBeenRead.currentTargetTexture = nil
		if P4HasBeenRead.options.showCT then
			P4HasBeenRead.currentTargetTexture = P4HasBeenRead.textureBookCT
		end
	end
end
Events.OnGameStart.Add(SetTextures)

P4HasBeenRead.OnCreatePlayer = function(playerIndex, player)
	-- Conversion markedList to markedMap
	local modData = getPlayer():getModData()
	if modData.P4HasBeenRead and modData.P4HasBeenRead.markedList then
		modData.P4HasBeenRead.markedMap = {}
		for i,v in ipairs(modData.P4HasBeenRead.markedList) do
			modData.P4HasBeenRead.markedMap[v] = ""
		end
		modData.P4HasBeenRead.markedList = nil
	end
end
Events.OnCreatePlayer.Add(P4HasBeenRead.OnCreatePlayer)

P4HasBeenRead.OnFillInventoryObjectContextMenu = function(player, contextMenu, items)
	if P4HasBeenRead.options.showSM then
		local markedMap = P4HasBeenRead.getMarkedMap()
		if #items == 1 then
			local item = nil
			if not instanceof(items[1], "InventoryItem") then
				item = items[1].items[1]
			else
				item = items[1]
			end
			local type = item:getFullType()
			local category = item:getCategory()
			if category == "Literature" then
				if P4HasBeenRead.isTargetLiterature(item) then
					if markedMap[type] then
						local menuText = "UI_P4HasBeenRead_Unmarked_Book"
						if P4HasBeenRead.options.reverseMarkDisplay then
							menuText = "UI_P4HasBeenRead_Marked_Book"
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
					else
						local menuText = "UI_P4HasBeenRead_Marked_Book"
						if P4HasBeenRead.options.reverseMarkDisplay then
							menuText = "UI_P4HasBeenRead_Unmarked_Book"
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
					end
				end
			elseif instanceof(item, "MapItem") then
				type = item:getMapID()
				if type then
					if markedMap[type] then
						local menuText = "UI_P4HasBeenRead_Unmarked_Map"
						if P4HasBeenRead.options.reverseMarkDisplay then
							menuText = "UI_P4HasBeenRead_Marked_Map"
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
					else
						local menuText = "UI_P4HasBeenRead_Marked_Map"
						if P4HasBeenRead.options.reverseMarkDisplay then
							menuText = "UI_P4HasBeenRead_Unmarked_Map"
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
					end
				end
			elseif type == "Base.Disc_Retail" then
				type = "Base.RM-" .. item:getMediaData():getIndex()
				if markedMap[type] then
					local menuText = "UI_P4HasBeenRead_Unmarked_CD"
					if P4HasBeenRead.options.reverseMarkDisplay then
						menuText = "UI_P4HasBeenRead_Marked_CD"
					end
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
				else
					local menuText = "UI_P4HasBeenRead_Marked_CD"
					if P4HasBeenRead.options.reverseMarkDisplay then
						menuText = "UI_P4HasBeenRead_Unmarked_CD"
					end
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
				end
			elseif type == "Base.VHS_Retail" or type == "Base.VHS_Home" then
				type = "Base.RM-" .. item:getMediaData():getIndex()
				if markedMap[type] then
					local menuText = "UI_P4HasBeenRead_Unmarked_VHS"
					if P4HasBeenRead.options.reverseMarkDisplay then
						menuText = "UI_P4HasBeenRead_Marked_VHS"
					end
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
				else
					local menuText = "UI_P4HasBeenRead_Marked_VHS"
					if P4HasBeenRead.options.reverseMarkDisplay then
						menuText = "UI_P4HasBeenRead_Unmarked_VHS"
					end
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
				end
			end
		else
			local types = {}
			for i,v in ipairs(items) do
				local item = nil
				if not instanceof(v, "InventoryItem") then
					item = v.items[1]
				else
					item = v
				end
				local type = item:getFullType()
				local category = item:getCategory()
				if category == "Literature" then
					if P4HasBeenRead.isTargetLiterature(item) then
						table.insert(types, type)
					end
				elseif instanceof(item, "MapItem") then
					type = item:getMapID()
					if type then
						table.insert(types, type)
					end
				elseif type == "Base.Disc_Retail" then
					type = "Base.RM-" .. item:getMediaData():getIndex()
					table.insert(types, type)
				elseif type == "Base.VHS_Retail" or type == "Base.VHS_Home" then
					type = "Base.RM-" .. item:getMediaData():getIndex()
					table.insert(types, type)
				end
			end
			if #types > 0 then
				if P4HasBeenRead.options.reverseMarkDisplay then
					contextMenu:addOption(getText("UI_P4HasBeenRead_Marked_ALL"), types, P4HasBeenRead.unmarkedAll)
					contextMenu:addOption(getText("UI_P4HasBeenRead_Unmarked_ALL"), types, P4HasBeenRead.markedAll)
				else
					contextMenu:addOption(getText("UI_P4HasBeenRead_Marked_ALL"), types, P4HasBeenRead.markedAll)
					contextMenu:addOption(getText("UI_P4HasBeenRead_Unmarked_ALL"), types, P4HasBeenRead.unmarkedAll)
				end
			end
		end
	end
end
Events.OnFillInventoryObjectContextMenu.Add(P4HasBeenRead.OnFillInventoryObjectContextMenu)

P4HasBeenRead.OnFillWorldObjectContextMenu = function(player, context, worldObjects, test)
	if P4HasBeenRead.options.showSM and P4HasBeenRead.options.autoMark then
		if P4HasBeenRead.doNotAutoMark then
			context:addOption(P4HasBeenRead.ContextMenu_ToDoAutoMark, nil, P4HasBeenRead.toggleDoNotAutoMark)
		else
			context:addOption(P4HasBeenRead.ContextMenu_ToDoNotAutoMark, nil, P4HasBeenRead.toggleDoNotAutoMark)
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(P4HasBeenRead.OnFillWorldObjectContextMenu)

-- For Inventory Tetris
if ItemGridUI then
	P4HasBeenRead.ItemGridUI_renderGridItem = ItemGridUI._renderGridItem
	function ItemGridUI._renderGridItem(drawingContext, playerObj, item, stack, x, y, rotate, alphaMult, force1x1, isBuried)
		P4HasBeenRead.ItemGridUI_renderGridItem(drawingContext, playerObj, item, stack, x, y, rotate, alphaMult, force1x1, isBuried)
		P4HasBeenRead.SetTextures(playerObj, item)
		if P4HasBeenRead.status or P4HasBeenRead.marking or P4HasBeenRead.current then
			local options = require "InventoryTetris/Settings"
			local h = nil
			if force1x1 then
				h = 1
			else
				_, h = TetrisItemData.getItemSize(item, rotate)
			end
			local yoff = options.CELL_SIZE * h
			if P4HasBeenRead.status then
				drawingContext:drawTexture(P4HasBeenRead.status, x+2, y+yoff-19, alphaMult, 1, 1, 1)
			end
			if P4HasBeenRead.marking then
				drawingContext:drawTexture(P4HasBeenRead.marking, x+12, y+yoff-13, alphaMult, 1, 1, 1)
			end
			if P4HasBeenRead.current then
				drawingContext:drawTexture(P4HasBeenRead.current, x+1, y+yoff-31, alphaMult, 1, 1, 1)
			end
		end
	end
end

-- *****************************************************************************
-- * Overwrite functions
-- *****************************************************************************

P4HasBeenRead.ISInventoryPaneContextMenu_onCheckMap = ISInventoryPaneContextMenu.onCheckMap
function ISInventoryPaneContextMenu.onCheckMap(map, player)
	P4HasBeenRead.ISInventoryPaneContextMenu_onCheckMap(map, player)
	local mapId = map:getMapID()
	if mapId then
		local readMap = P4HasBeenRead.getReadMap()
		readMap[mapId] = ""
	end
end

P4HasBeenRead.ISInventoryTransferAction_perform = ISInventoryTransferAction.perform
function ISInventoryTransferAction:perform()
	-- Auto mark if needed
	if P4HasBeenRead.options.showSM and P4HasBeenRead.options.autoMark and not P4HasBeenRead.doNotAutoMark then
		local inventory = self.character:getInventory()
		local needsMark = false
		if inventory == self.destContainer then
			needsMark = true
		else
			local containingItem = self.destContainer:getContainingItem()
			if containingItem and inventory:containsRecursive(containingItem) then
				needsMark = true
			end
		end
		if needsMark then
			local type = self.item:getFullType()
			local category = self.item:getCategory()
			local isMarkable = false
			if category == "Literature" then
				if P4HasBeenRead.isTargetLiterature(self.item) then
					isMarkable = true
				end
			elseif instanceof(self.item, "MapItem") then
				type = self.item:getMapID()
				if type then
					isMarkable = true
				end
			elseif type == "Base.Disc_Retail" or type == "Base.VHS_Retail" or type == "Base.VHS_Home" then
				type = "Base.RM-" .. self.item:getMediaData():getIndex()
				isMarkable = true
			end
			if isMarkable then
				P4HasBeenRead.marked(type)
			end
		end
	end
	-- Original function call
	P4HasBeenRead.ISInventoryTransferAction_perform(self)
end

-- *****************************************************************************
-- * Main functions
-- *****************************************************************************

P4HasBeenRead.SetTextures = function(player, item)
	local type = item:getFullType()

	local recordedMedia = getZomboidRadio():getRecordedMedia()
	local readMap = P4HasBeenRead.getReadMap()
	local markedMap = P4HasBeenRead.getMarkedMap()

	local statusTexture = nil
	local selfMarkingTexture = nil
	local currentTargetTexture = nil
	if item:getCategory() == "Literature" then
		if P4HasBeenRead.isTargetLiterature(item) then
			local skillBook = SkillBook[item:getSkillTrained()]
			if skillBook then
				local perkLevel = player:getPerkLevel(skillBook.perk)
				local minLevel = item:getLvlSkillTrained()
				local maxLevel = item:getMaxLevelTrained()
				if (minLevel <= perkLevel + 1) and (perkLevel + 1 <= maxLevel) then
					currentTargetTexture = P4HasBeenRead.currentTargetTexture
				end
				local readPages = player:getAlreadyReadPages(item:getFullType())
				if readPages >= item:getNumberOfPages() then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				elseif perkLevel >= maxLevel then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				elseif readPages > 0 then
					statusTexture = P4HasBeenRead.notCompletedTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
			elseif item:getTeachedRecipes() and not item:getTeachedRecipes():isEmpty() then
				if player:getKnownRecipes():containsAll(item:getTeachedRecipes()) then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
			end
			if P4HasBeenRead.options.showSM then
				if markedMap[type] then
					if not P4HasBeenRead.options.reverseMarkDisplay then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				else
					if P4HasBeenRead.options.reverseMarkDisplay then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				end
			end
		end
	elseif instanceof(item, "MapItem") then
		if P4HasBeenRead.options.enableMap then
			local mapId = item:getMapID()
			if mapId then
				if readMap[mapId] then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
				if P4HasBeenRead.options.showSM then
					if markedMap[mapId] then
						if not P4HasBeenRead.options.reverseMarkDisplay then
							selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
						end
					else
						if P4HasBeenRead.options.reverseMarkDisplay then
							selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
						end
					end
				end
			end
		end
	elseif recordedMedia then
		local mediaData = item:getMediaData()
		if mediaData then
			local isTarget = false
			local index = mediaData:getIndex()
			local category = mediaData:getCategory()
			if P4HasBeenRead.options.enableCD and category == "CDs" then
				isTarget = true
			elseif P4HasBeenRead.options.enableVHS and category == "Retail-VHS" then
				isTarget = true
			elseif P4HasBeenRead.options.enableHVHS and category == "Home-VHS" then
				isTarget = true
			end
			if isTarget then
				statusTexture = P4HasBeenRead.recordedMediaResult[index]
				if statusTexture then
					if statusTexture == "mynil" then
						statusTexture = nil
					end
				else
					if recordedMedia:hasListenedToAll(player, mediaData) then
						statusTexture = P4HasBeenRead.alreadyReadTexture
					else
						statusTexture = P4HasBeenRead.notReadTexture
					end
					if statusTexture then
						P4HasBeenRead.recordedMediaResult[index] = statusTexture
					else
						P4HasBeenRead.recordedMediaResult[index] = "mynil"
					end
				end
			end
			if P4HasBeenRead.options.showSM then
				if markedMap["Base.RM-" .. index] then
					if not P4HasBeenRead.options.reverseMarkDisplay then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				else
					if P4HasBeenRead.options.reverseMarkDisplay then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				end
			end
		end
	end
	P4HasBeenRead.status = statusTexture
	P4HasBeenRead.marking = selfMarkingTexture
	P4HasBeenRead.current = currentTargetTexture
end

P4HasBeenRead.ISInventoryPane_renderdetails = ISInventoryPane.renderdetails
function ISInventoryPane:renderdetails(doDragged)
	P4HasBeenRead.ISInventoryPane_renderdetails(self, doDragged)
	P4HasBeenRead.recordedMediaResult = {}

	-- [NOTICE]
	-- The source code below is the basicaly same as the vanilla code in Build 41.50.
	-- Due to changes in the vanilla code, it may not work properly.

	local player = getSpecificPlayer(self.player)
	local y = 0
	local MOUSEX = self:getMouseX()
	local MOUSEY = self:getMouseY()
	local YSCROLL = self:getYScroll()
	local HEIGHT = self:getHeight()
	for k, v in ipairs(self.itemslist) do
		local count = 1
		for k2, v2 in ipairs(v.items) do
			local item = v2
			P4HasBeenRead.SetTextures(player, item)
			if P4HasBeenRead.status or P4HasBeenRead.marking or P4HasBeenRead.current then
				local doIt = true
				local xoff = 0
				local yoff = 0
				local isDragging = false
				if self.dragging ~= nil and self.selected[y+1] ~= nil and self.dragStarted then
					xoff = MOUSEX - self.draggingX
					yoff = MOUSEY - self.draggingY
					if not doDragged then
						doIt = false
					else
						isDragging = true
					end
				else
					if doDragged then
						doIt = false
					end
				end
				local topOfItem = y * self.itemHgt + YSCROLL
				if not isDragging and ((topOfItem + self.itemHgt < 0) or (topOfItem > HEIGHT)) then
					doIt = false
				end
				if doIt == true then
					local tex = item:getTex()
					if tex ~= nil then
						local texWH = math.min(self.itemHgt-2,32)
						if count == 1  then
							if P4HasBeenRead.status then
								self:drawTexture(P4HasBeenRead.status, xoff+5, (y*self.itemHgt)+self.headerHgt+yoff+texWH-16, 1, 1, 1, 1)
							end
							if P4HasBeenRead.marking then
								self:drawTexture(P4HasBeenRead.marking, xoff+15, (y*self.itemHgt)+self.headerHgt+yoff+texWH-10, 1, 1, 1, 1)
							end
							if P4HasBeenRead.current then
								self:drawTexture(P4HasBeenRead.current, xoff+4, (y*self.itemHgt)+self.headerHgt+yoff-3, 1, 1, 1, 1)
							end
						elseif v.count > 2 or (doDragged and count > 1 and self.selected[(y+1) - (count-1)] == nil) then
							if P4HasBeenRead.status then
								self:drawTexture(P4HasBeenRead.status, xoff+21, (y*self.itemHgt)+self.headerHgt+yoff+texWH-16, 0.3, 1, 1, 1)
							end
							if P4HasBeenRead.marking then
								self:drawTexture(P4HasBeenRead.marking, xoff+31, (y*self.itemHgt)+self.headerHgt+yoff+texWH-10, 0.3, 1, 1, 1)
							end
							if P4HasBeenRead.current then
								self:drawTexture(P4HasBeenRead.current, xoff+20, (y*self.itemHgt)+self.headerHgt+yoff-3, 0.3, 1, 1, 1)
							end
						end
					end
				end
			end
			y = y + 1
			if count == 1 and self.collapsed ~= nil and v.name ~= nil and self.collapsed[v.name] then
				break
			end
			if count == 51 then
				break
			end
			count = count + 1
		end
	end
end

P4HasBeenRead.isTargetLiterature = function(item)
	local isTarget = false
	if SkillBook[item:getSkillTrained()] then
		isTarget = true
	elseif item:getTeachedRecipes() and not item:getTeachedRecipes():isEmpty() then
		isTarget = true
	end
	return isTarget
end

P4HasBeenRead.showInfo = function(message)
	getPlayer():Say(message, 0.607, 0.717, 1.000, UIFont.Dialogue, 15, "radio")
end
