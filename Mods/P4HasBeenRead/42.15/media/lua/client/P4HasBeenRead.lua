local P4HasBeenRead = {}

P4HasBeenRead.doNotAutoMark = false

P4HasBeenRead.textureBookNR = getTexture("media/ui/P4HasBeenRead_Book_NR.png")
P4HasBeenRead.textureBookNC = getTexture("media/ui/P4HasBeenRead_Book_NC.png")
P4HasBeenRead.textureBookAR = getTexture("media/ui/P4HasBeenRead_Book_AR.png")
P4HasBeenRead.textureBookSMM = getTexture("media/ui/P4HasBeenRead_Book_SM_Marked.png")
P4HasBeenRead.textureBookSMU = getTexture("media/ui/P4HasBeenRead_Book_SM_Unmarked.png")
P4HasBeenRead.textureBookCT = getTexture("media/ui/P4HasBeenRead_Book_CT.png")

P4HasBeenRead.notReadTexture = nil
P4HasBeenRead.notCompletedTexture = nil
P4HasBeenRead.alreadyReadTexture = nil
P4HasBeenRead.markedTexture = nil
P4HasBeenRead.unmarkedTexture = nil
P4HasBeenRead.currentTargetTexture = nil
P4HasBeenRead.hasVisibleTextures = false
P4HasBeenRead.hasStatusTextures = false

P4HasBeenRead.Messages_ToDoAutoMark = getText("UI_P4HasBeenRead_Messages_ToDoAutoMark")
P4HasBeenRead.Messages_ToDoNotAutoMark = getText("UI_P4HasBeenRead_Messages_ToDoNotAutoMark")
P4HasBeenRead.ContextMenu_ToDoAutoMark = getText("ContextMenu_P4HasBeenRead_ToDoAutoMark")
P4HasBeenRead.ContextMenu_ToDoNotAutoMark = getText("ContextMenu_P4HasBeenRead_ToDoNotAutoMark")

P4HasBeenRead.effectiveCodes = {"CRP","COO","FRM","DOC","ELC","MTL","MEC","TAI","FIS","TRA","FOR","HUS","FKN","BLA","POT","RCP","BAA","BUA","SBU","LBA","SBA","SPE","AIM","REL","SPR","LFT","NIM","SNE"}
P4HasBeenRead.effectiveMedias = {}

P4HasBeenRead.modData = {}
P4HasBeenRead.useMarking = false
P4HasBeenRead.targetOptions = {}

P4HasBeenRead.player = nil

-- *****************************************************************************
-- * Options
-- *****************************************************************************

P4HasBeenRead.options = {
	EnableTargets = nil,
	ShowMarks = nil,
	ShowCT = nil,
	ShowSM = nil,
	AutoMark = nil,
}

P4HasBeenRead.initOption = function()
	local options = PZAPI.ModOptions:create("P4HasBeenRead", "Has Been Read")
	P4HasBeenRead.options.EnableTargets = options:addMultipleTickBox("EnableTargets", getText("UI_P4HasBeenRead_Options_EnableTargets_Name"), getText("UI_P4HasBeenRead_Options_EnableTargets_Tooltip"))
	P4HasBeenRead.options.EnableTargets:addTickBox(getText("UI_P4HasBeenRead_Options_EnableTargets_Skills"), true)
	P4HasBeenRead.options.EnableTargets:addTickBox(getText("UI_P4HasBeenRead_Options_EnableTargets_Recipes"), true)
	P4HasBeenRead.options.EnableTargets:addTickBox(getText("UI_P4HasBeenRead_Options_EnableTargets_Map"), true)
	P4HasBeenRead.options.EnableTargets:addTickBox(getText("UI_P4HasBeenRead_Options_EnableTargets_Flier"), true)
	P4HasBeenRead.options.EnableTargets:addTickBox(getText("UI_P4HasBeenRead_Options_EnableTargets_Brochure"), true)
	P4HasBeenRead.options.EnableTargets:addTickBox(getText("UI_P4HasBeenRead_Options_EnableTargets_Titled"), true)
	P4HasBeenRead.options.EnableTargets:addTickBox(getText("UI_P4HasBeenRead_Options_EnableTargets_CD"), true)
	P4HasBeenRead.options.EnableTargets:addTickBox(getText("UI_P4HasBeenRead_Options_EnableTargets_VHS"), true)
	P4HasBeenRead.options.EnableTargets:addTickBox(getText("UI_P4HasBeenRead_Options_EnableTargets_HVHS"), true)
	P4HasBeenRead.options.ShowMarks = options:addMultipleTickBox("ShowMarks", getText("UI_P4HasBeenRead_Options_ShowMarks_Name"), getText("UI_P4HasBeenRead_Options_ShowMarks_Tooltip"))
	P4HasBeenRead.options.ShowMarks:addTickBox(getText("UI_P4HasBeenRead_Options_ShowMarks_NR"), true)
	P4HasBeenRead.options.ShowMarks:addTickBox(getText("UI_P4HasBeenRead_Options_ShowMarks_NC"), true)
	P4HasBeenRead.options.ShowMarks:addTickBox(getText("UI_P4HasBeenRead_Options_ShowMarks_AR"), false)
	P4HasBeenRead.options.ShowCT = options:addTickBox("ShowCT", getText("UI_P4HasBeenRead_Options_ShowCT_Name"), true, getText("UI_P4HasBeenRead_Options_ShowCT_Tooltip"))
	P4HasBeenRead.options.ShowSM = options:addMultipleTickBox("ShowSM", getText("UI_P4HasBeenRead_Options_ShowSM_Name"), getText("UI_P4HasBeenRead_Options_ShowSM_Tooltip"))
	P4HasBeenRead.options.ShowSM:addTickBox(getText("UI_P4HasBeenRead_Options_ShowSM_Marked"), true)
	P4HasBeenRead.options.ShowSM:addTickBox(getText("UI_P4HasBeenRead_Options_ShowSM_Unmarked"), false)
	P4HasBeenRead.options.AutoMark = options:addTickBox("AutoMark", getText("UI_P4HasBeenRead_Options_AutoMark_Name"), false, getText("UI_P4HasBeenRead_Options_AutoMark_Tooltip"))
end
P4HasBeenRead.initOption()

-- *****************************************************************************
-- * ModData functions
-- *****************************************************************************

P4HasBeenRead.initModOptions = function()
	local modData = P4HasBeenRead.player:getModData()
	if not modData.P4HasBeenRead then
		modData.P4HasBeenRead = {}
		modData.P4HasBeenRead.doNotAutoMark = false
	end
	if not modData.P4HasBeenRead.readMap then
		modData.P4HasBeenRead.readMap = {}
	end
	if not modData.P4HasBeenRead.markedMap then
		modData.P4HasBeenRead.markedMap = {}
	end
	P4HasBeenRead.modData = modData.P4HasBeenRead
	P4HasBeenRead.doNotAutoMark = modData.P4HasBeenRead.doNotAutoMark
	P4HasBeenRead.player:transmitModData()
end

P4HasBeenRead.read = function(type)
	P4HasBeenRead.modData.readMap[type] = true
	P4HasBeenRead.player:transmitModData()
end

P4HasBeenRead.marked = function(type, noTransmit)
	P4HasBeenRead.modData.markedMap[type] = true
	if not noTransmit then
		P4HasBeenRead.player:transmitModData()
	end
end

P4HasBeenRead.markedAll = function(types)
	for i,v in ipairs(types) do
		P4HasBeenRead.marked(v, true)
	end
	P4HasBeenRead.player:transmitModData()
end

P4HasBeenRead.unmarked = function(type, noTransmit)
	P4HasBeenRead.modData.markedMap[type] = nil
	if not noTransmit then
		P4HasBeenRead.player:transmitModData()
	end
end

P4HasBeenRead.unmarkedAll = function(types)
	for i,v in ipairs(types) do
		P4HasBeenRead.unmarked(v, true)
	end
	P4HasBeenRead.player:transmitModData()
end

P4HasBeenRead.toggleDoNotAutoMark = function()
	P4HasBeenRead.doNotAutoMark = not P4HasBeenRead.doNotAutoMark
	P4HasBeenRead.modData.doNotAutoMark = P4HasBeenRead.doNotAutoMark
	P4HasBeenRead.player:transmitModData()
	if P4HasBeenRead.doNotAutoMark then
		P4HasBeenRead.showInfo(P4HasBeenRead.Messages_ToDoNotAutoMark)
	else
		P4HasBeenRead.showInfo(P4HasBeenRead.Messages_ToDoAutoMark)
	end
end

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

P4HasBeenRead.OnLoad = function()
	P4HasBeenRead.loadFunctions()
end
Events.OnLoad.Add(P4HasBeenRead.OnLoad)

P4HasBeenRead.OnCreatePlayer = function(playerIndex, player)
	P4HasBeenRead.player = player
	P4HasBeenRead.initModOptions()
end
Events.OnCreatePlayer.Add(P4HasBeenRead.OnCreatePlayer)

P4HasBeenRead.OnInitRecordedMedia = function(_rc)
	for id, media in pairs(RecMedia) do
		local isEffective = false
		for _, line in ipairs(media.lines) do
			if line.codes ~= "BOR-1" then -- Hack for performance
				for _, code in ipairs(P4HasBeenRead.effectiveCodes) do
					if string.find(line.codes, code) then
						isEffective = true
						break
					end
				end
			end
			if isEffective then
				break
			end
		end
		if isEffective then
			P4HasBeenRead.effectiveMedias[id] = true
		end
	end
end
Events.OnInitRecordedMedia.Add(P4HasBeenRead.OnInitRecordedMedia)

P4HasBeenRead.initTextures = function()
	P4HasBeenRead.notReadTexture = nil
	if P4HasBeenRead.options.ShowMarks:getValue(1) then
		P4HasBeenRead.notReadTexture = P4HasBeenRead.textureBookNR
	end
	P4HasBeenRead.notCompletedTexture = nil
	if P4HasBeenRead.options.ShowMarks:getValue(2) then
		P4HasBeenRead.notCompletedTexture = P4HasBeenRead.textureBookNC
	end
	P4HasBeenRead.alreadyReadTexture = nil
	if P4HasBeenRead.options.ShowMarks:getValue(3) then
		P4HasBeenRead.alreadyReadTexture = P4HasBeenRead.textureBookAR
	end
	P4HasBeenRead.currentTargetTexture = nil
	if P4HasBeenRead.options.ShowCT.value then
		P4HasBeenRead.currentTargetTexture = P4HasBeenRead.textureBookCT
	end
	P4HasBeenRead.markedTexture = nil
	if P4HasBeenRead.options.ShowSM:getValue(1) then
		P4HasBeenRead.markedTexture = P4HasBeenRead.textureBookSMM
	end
	P4HasBeenRead.unmarkedTexture = nil
	if P4HasBeenRead.options.ShowSM:getValue(2) then
		P4HasBeenRead.unmarkedTexture = P4HasBeenRead.textureBookSMU
	end
	P4HasBeenRead.useMarking = P4HasBeenRead.options.ShowSM:getValue(1) or P4HasBeenRead.options.ShowSM:getValue(2)
	P4HasBeenRead.hasStatusTextures = P4HasBeenRead.notReadTexture ~= nil or P4HasBeenRead.notCompletedTexture ~= nil or P4HasBeenRead.alreadyReadTexture ~= nil
	P4HasBeenRead.hasVisibleTextures = P4HasBeenRead.hasStatusTextures or P4HasBeenRead.currentTargetTexture ~= nil or P4HasBeenRead.markedTexture ~= nil or P4HasBeenRead.unmarkedTexture ~= nil
	for i = 1, 9 do
		P4HasBeenRead.targetOptions[i] = P4HasBeenRead.options.EnableTargets:getValue(i)
	end
end
Events.OnGameStart.Add(P4HasBeenRead.initTextures)

P4HasBeenRead.OnFillInventoryObjectContextMenu = function(player, contextMenu, items)
	if P4HasBeenRead.useMarking then
		local markedMap = P4HasBeenRead.modData.markedMap
		if #items == 1 then
			local item = nil
			if not instanceof(items[1], "InventoryItem") then
				item = items[1].items[1]
			else
				item = items[1]
			end
			local type = P4HasBeenRead.getFullType(item)
			local category = item:getCategory()
			if category == "Literature" then
				if P4HasBeenRead.isTargetLiterature(item) then
					if markedMap[type] then
						local menuText = "UI_P4HasBeenRead_Unmarked_Book"
						if item:getFullType() == "Base.Flier" then
							menuText = "UI_P4HasBeenRead_Unmarked_Flier"
						elseif item:getFullType() == "Base.Brochure" then
							menuText = "UI_P4HasBeenRead_Unmarked_Brochure"
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
					else
						local menuText = "UI_P4HasBeenRead_Marked_Book"
						if item:getFullType() == "Base.Flier" then
							menuText = "UI_P4HasBeenRead_Marked_Flier"
						elseif item:getFullType() == "Base.Brochure" then
							menuText = "UI_P4HasBeenRead_Marked_Brochure"
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
					end
				end
			elseif instanceof(item, "MapItem") then
				type = item:getMapID()
				if type then
					if markedMap[type] then
						local menuText = "UI_P4HasBeenRead_Unmarked_Map"
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
					else
						local menuText = "UI_P4HasBeenRead_Marked_Map"
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
					end
				end
			elseif type == "Base.Disc_Retail" then
				type = "Base.RM-" .. item:getMediaData():getIndex()
				if markedMap[type] then
					local menuText = "UI_P4HasBeenRead_Unmarked_CD"
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
				else
					local menuText = "UI_P4HasBeenRead_Marked_CD"
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
				end
			elseif type == "Base.VHS_Retail" or type == "Base.VHS_Home" then
				type = "Base.RM-" .. item:getMediaData():getIndex()
				if markedMap[type] then
					local menuText = "UI_P4HasBeenRead_Unmarked_VHS"
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
				else
					local menuText = "UI_P4HasBeenRead_Marked_VHS"
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
				local type = P4HasBeenRead.getFullType(item)
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
				contextMenu:addOption(getText("UI_P4HasBeenRead_Marked_ALL"), types, P4HasBeenRead.markedAll)
				contextMenu:addOption(getText("UI_P4HasBeenRead_Unmarked_ALL"), types, P4HasBeenRead.unmarkedAll)
			end
		end
	end
end
Events.OnFillInventoryObjectContextMenu.Add(P4HasBeenRead.OnFillInventoryObjectContextMenu)

P4HasBeenRead.OnFillWorldObjectContextMenu = function(player, context, worldObjects, test)
	if P4HasBeenRead.useMarking and P4HasBeenRead.options.AutoMark.value then
		if P4HasBeenRead.doNotAutoMark then
			context:addOption(P4HasBeenRead.ContextMenu_ToDoAutoMark, nil, P4HasBeenRead.toggleDoNotAutoMark)
		else
			context:addOption(P4HasBeenRead.ContextMenu_ToDoNotAutoMark, nil, P4HasBeenRead.toggleDoNotAutoMark)
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(P4HasBeenRead.OnFillWorldObjectContextMenu)

-- *****************************************************************************
-- * Overwrite functions
-- *****************************************************************************

P4HasBeenRead.MainOptions_apply = MainOptions.apply
function MainOptions:apply(closeAfter)
	P4HasBeenRead.MainOptions_apply(self, closeAfter)
	P4HasBeenRead.initTextures()
end

P4HasBeenRead.ISInventoryPaneContextMenu_onCheckMap = ISInventoryPaneContextMenu.onCheckMap
function ISInventoryPaneContextMenu.onCheckMap(map, player)
	P4HasBeenRead.ISInventoryPaneContextMenu_onCheckMap(map, player)
	local mapId = map:getMapID()
	if mapId then
		P4HasBeenRead.read(mapId)
	end
end

P4HasBeenRead.ISReadABook_perform = ISReadABook.perform
function ISReadABook:perform()
	P4HasBeenRead.ISReadABook_perform(self)
	if P4HasBeenRead.isTargetLiterature(self.item) then
		local modData = self.item:getModData()
		if modData.literatureTitle then
			P4HasBeenRead.read(modData.literatureTitle)
		elseif modData.printMedia then
			P4HasBeenRead.read(modData.printMedia)
		end
	end
end

P4HasBeenRead.ISInventoryTransferAction_perform = ISInventoryTransferAction.perform
function ISInventoryTransferAction:perform()
	-- Auto mark if needed
	if P4HasBeenRead.useMarking and P4HasBeenRead.options.AutoMark.value and not P4HasBeenRead.doNotAutoMark then
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
			local type = P4HasBeenRead.getFullType(self.item)
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
-- * For Compatible functions
-- *****************************************************************************

P4HasBeenRead.loadFunctions = function()
	-- Inventory Tetris
	if TetrisEvents then
		P4HasBeenRead.InventoryTetris = {}
		P4HasBeenRead.InventoryTetris.options = require "InventoryTetris/Settings"

		function P4HasBeenRead.InventoryTetris.call(eventData, drawingContext, renderInstructions, instructionCount, playerObj)
			if not P4HasBeenRead.hasVisibleTextures then
				return
			end
			local readMap = P4HasBeenRead.modData.readMap
			local markedMap = P4HasBeenRead.modData.markedMap
			local recordedMedia = getZomboidRadio():getRecordedMedia()
			local recordedMediaResult = {}
			for i = 1, instructionCount do
				local instruction = renderInstructions[i]
				local hidden = instruction[9]
				if not hidden then
					local item = instruction[2]
					local x = instruction[3]
					local y = instruction[4]
					local h = instruction[6]
					local status, marking, current = P4HasBeenRead.setTextures(playerObj, item, readMap, markedMap, recordedMedia, recordedMediaResult)
					if status or marking or current then
						local yoff = P4HasBeenRead.InventoryTetris.options.CELL_SIZE * h
						local alphaMult = instruction[7]
						if status then
							drawingContext.javaObject:DrawTexture(status, x+2, y+yoff-19, alphaMult)
						end
						if marking then
							drawingContext.javaObject:DrawTexture(marking, x+12, y+yoff-13, alphaMult)
						end
						if current then
							drawingContext.javaObject:DrawTexture(current, x+1, y+yoff-31, alphaMult)
						end
					end
				end
			end
		end
		TetrisEvents.OnPostRenderGrid:add(P4HasBeenRead.InventoryTetris)
	end
end

-- *****************************************************************************
-- * Main functions
-- *****************************************************************************

P4HasBeenRead.setTextures = function(player, item, readMap, markedMap, recordedMedia, recordedMediaResult)
	local statusTexture = nil
	local selfMarkingTexture = nil
	local currentTargetTexture = nil
	if item:getCategory() == "Literature" then
		if P4HasBeenRead.isTargetLiterature(item) then
			local type = P4HasBeenRead.getFullType(item)
			local fullType = item:getFullType()
			local skillBook = SkillBook[item:getSkillTrained()]
			if skillBook then
				if P4HasBeenRead.targetOptions[1] and (P4HasBeenRead.hasStatusTextures or P4HasBeenRead.currentTargetTexture) then
					local perkLevel = player:getPerkLevel(skillBook.perk)
					local minLevel = item:getLvlSkillTrained()
					local maxLevel = item:getMaxLevelTrained()
					if (minLevel <= perkLevel + 1) and (perkLevel + 1 <= maxLevel) then
						currentTargetTexture = P4HasBeenRead.currentTargetTexture
					end
					if P4HasBeenRead.hasStatusTextures then
						local readPages = player:getAlreadyReadPages(fullType)
						if readPages >= item:getNumberOfPages() then
							statusTexture = P4HasBeenRead.alreadyReadTexture
						elseif perkLevel >= maxLevel then
							statusTexture = P4HasBeenRead.alreadyReadTexture
						elseif readPages > 0 then
							statusTexture = P4HasBeenRead.notCompletedTexture
						else
							statusTexture = P4HasBeenRead.notReadTexture
						end
					end
				end
			else
				local learnedRecipes = item:getLearnedRecipes()
				if learnedRecipes and not learnedRecipes:isEmpty() then
					if P4HasBeenRead.targetOptions[2] and P4HasBeenRead.hasStatusTextures then
						if player:getKnownRecipes():containsAll(learnedRecipes) then
							statusTexture = P4HasBeenRead.alreadyReadTexture
						else
							statusTexture = P4HasBeenRead.notReadTexture
						end
					end
				elseif fullType == "Base.Flier" then
					if P4HasBeenRead.targetOptions[4] and P4HasBeenRead.hasStatusTextures then
						if readMap[type] then
							statusTexture = P4HasBeenRead.alreadyReadTexture
						else
							statusTexture = P4HasBeenRead.notReadTexture
						end
					end
				elseif fullType == "Base.Brochure" then
					if P4HasBeenRead.targetOptions[5] and P4HasBeenRead.hasStatusTextures then
						if readMap[type] then
							statusTexture = P4HasBeenRead.alreadyReadTexture
						else
							statusTexture = P4HasBeenRead.notReadTexture
						end
					end
				elseif P4HasBeenRead.targetOptions[6] and P4HasBeenRead.hasStatusTextures then
					if readMap[type] then
						statusTexture = P4HasBeenRead.alreadyReadTexture
					else
						statusTexture = P4HasBeenRead.notReadTexture
					end
				end
			end
			if markedMap[type] then
				selfMarkingTexture = P4HasBeenRead.markedTexture
			else
				selfMarkingTexture = P4HasBeenRead.unmarkedTexture
			end
		end
	elseif instanceof(item, "MapItem") then
		local mapId = item:getMapID()
		if mapId then
			if P4HasBeenRead.targetOptions[3] and P4HasBeenRead.hasStatusTextures then
				if readMap[mapId] then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
			end
			if markedMap[mapId] then
				selfMarkingTexture = P4HasBeenRead.markedTexture
			else
				selfMarkingTexture = P4HasBeenRead.unmarkedTexture
			end
		end
	elseif recordedMedia then
		local mediaData = item:getMediaData()
		if mediaData then
			local isTarget = false
			local index = mediaData:getIndex()
			local category = mediaData:getCategory()
			if P4HasBeenRead.targetOptions[7] and category == "CDs" then
				isTarget = true
			elseif P4HasBeenRead.targetOptions[8] and category == "Retail-VHS" then
				isTarget = true
			elseif P4HasBeenRead.targetOptions[9] and category == "Home-VHS" then
				isTarget = true
			end
			if isTarget then
				if P4HasBeenRead.currentTargetTexture and P4HasBeenRead.effectiveMedias[mediaData:getId()] then
					currentTargetTexture = P4HasBeenRead.currentTargetTexture
				end
				if P4HasBeenRead.hasStatusTextures then
					local cachedTexture = recordedMediaResult[index]
					if cachedTexture ~= nil then
						statusTexture = cachedTexture or nil
					else
						if recordedMedia:hasListenedToAll(player, mediaData) then
							statusTexture = P4HasBeenRead.alreadyReadTexture
						else
							statusTexture = P4HasBeenRead.notReadTexture
						end
						recordedMediaResult[index] = statusTexture or false
					end
				end
			end
			if markedMap["Base.RM-" .. index] then
				selfMarkingTexture = P4HasBeenRead.markedTexture
			else
				selfMarkingTexture = P4HasBeenRead.unmarkedTexture
			end
		end
	end
	return statusTexture, selfMarkingTexture, currentTargetTexture
end

P4HasBeenRead.ISInventoryPane_renderdetails = ISInventoryPane.renderdetails
function ISInventoryPane:renderdetails(doDragged)
	P4HasBeenRead.ISInventoryPane_renderdetails(self, doDragged)
	if not P4HasBeenRead.hasVisibleTextures then
		return
	end
	if doDragged and (self.dragging == nil or not self.dragStarted) then
		return
	end

	local player = getSpecificPlayer(self.player)
	local readMap = P4HasBeenRead.modData.readMap
	local markedMap = P4HasBeenRead.modData.markedMap
	local recordedMedia = getZomboidRadio():getRecordedMedia()
	local recordedMediaResult = {}
	local y = 0
	local MOUSEX = self:getMouseX()
	local MOUSEY = self:getMouseY()
	local YSCROLL = self:getYScroll()
	local HEIGHT = self:getHeight()
	local texWH = math.min(self.itemHgt-2, 32)
	local texInset = (self.itemHgt-texWH)/2
	for k, v in ipairs(self.itemslist) do
		local count = 1
		for k2, v2 in ipairs(v.items) do
			local item = v2
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
			elseif doDragged then
				doIt = false
			end
			local topOfItem = y * self.itemHgt + YSCROLL
			if not isDragging and ((topOfItem + self.itemHgt < 0) or (topOfItem > HEIGHT)) then
				doIt = false
			end
			if doIt and item:getTex() ~= nil then
				local status, marking, current = P4HasBeenRead.setTextures(player, item, readMap, markedMap, recordedMedia, recordedMediaResult)
				if status or marking or current then
					local iconX = 10+16+xoff
					if count == 1 then
						iconX = self.column2-texWH-texInset+xoff
					end
					local iconY = (y*self.itemHgt)+self.headerHgt+texInset+yoff
					local overlayX = iconX-5
					if not isDragging then
						overlayX = math.max(1, overlayX)
					end
					if isDragging then
						self:suspendStencil()
					end
					if count == 1 then
						if status then
							self:drawTexture(status, overlayX, iconY+texWH-16, 1, 1, 1, 1)
						end
						if marking then
							self:drawTexture(marking, overlayX+10, iconY+texWH-10, 1, 1, 1, 1)
						end
						if current then
							self:drawTexture(current, overlayX-1, iconY-4, 1, 1, 1, 1)
						end
					elseif v.count > 2 or (doDragged and count > 1 and self.selected[(y+1) - (count-1)] == nil) then
						if status then
							self:drawTexture(status, overlayX, iconY+texWH-16, 0.3, 1, 1, 1)
						end
						if marking then
							self:drawTexture(marking, overlayX+10, iconY+texWH-10, 0.3, 1, 1, 1)
						end
						if current then
							self:drawTexture(current, overlayX-1, iconY-4, 0.3, 1, 1, 1)
						end
					end
					if isDragging then
						self:resumeStencil()
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
	local modData = item:getModData()
	if SkillBook[item:getSkillTrained()] then
		isTarget = true
	elseif item:getLearnedRecipes() and not item:getLearnedRecipes():isEmpty() then
		isTarget = true
	elseif item:getFullType() == "Base.Flier" or item:getFullType() == "Base.Brochure" then
		isTarget = true
	elseif modData then
		if modData.literatureTitle then
			isTarget = true
		elseif modData.printMedia then
			isTarget = true
		end
	end
	return isTarget
end

P4HasBeenRead.getFullType = function(item)
	local type = item:getFullType()
	local modData = item:getModData()
	if type == "Base.RecipeClipping" or type == "Base.SewingPattern" or (string.find(type, "Schematic", 1, true) and item:getDisplayCategory() == "RecipeResource") then
		type = P4HasBeenRead.getRecipeResourceFullType(item, type)
	end
	if modData then
		if modData.literatureTitle then
			type = modData.literatureTitle
		elseif modData.printMedia then
			type = modData.printMedia
		end
	end
	return type
end

P4HasBeenRead.getRecipeResourceFullType = function(item, type)
	local recipes = item:getLearnedRecipes()
	if recipes:isEmpty() then
		return type
	elseif recipes:size() == 1 then
		return type .. "|" .. recipes:get(0)
	else
		local temp = {}
		for i = 0, recipes:size() - 1 do
			temp[#temp+1] = recipes:get(i)
		end
		table.sort(temp)

		local last = nil
		local j = 1
		for i = 1, #temp do
			local v = temp[i]
			if v ~= last then
				temp[j] = v
				j = j + 1
				last = v
			end
		end
		for k = j, #temp do
			temp[k] = nil
		end

		return type .. "|" .. table.concat(temp, "|")
	end
end

P4HasBeenRead.showInfo = function(message)
	P4HasBeenRead.player:Say(message, 0.607, 0.717, 1.000, UIFont.Dialogue, 15, "radio")
end
