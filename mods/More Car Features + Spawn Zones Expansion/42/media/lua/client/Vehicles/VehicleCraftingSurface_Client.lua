vehicleCraftSurf = vehicleCraftSurf or {}

local CraftRecipeManagerGetUniqueRecipeItems = CraftRecipeManager.getUniqueRecipeItems
function CraftRecipeManager.getUniqueRecipeItems(itemsCraft, playerObj, containerList)
	local returnTestRecipes = CraftRecipeManagerGetUniqueRecipeItems(itemsCraft, playerObj, containerList)

	local recipeNames = itemsCraft:getScriptItem():getUsedInRecipes(playerObj)
	for i=0, recipeNames:size()-1 do
		local recipeName = recipeNames:get(i)
		local logic = HandcraftLogic.new(playerObj, nil, nil)
		logic:setContainers(containerList)
		if instanceof(logic, "BaseCraftingLogic") then
			local craftRecipe = getScriptManager():getCraftRecipe(recipeName)
			logic:setRecipeFromContextClick(craftRecipe, itemsCraft)
			local cachedRecipeInfo = logic:getCachedRecipeInfo(craftRecipe)
			if cachedRecipeInfo and cachedRecipeInfo:isValid() and not cachedRecipeInfo:isCanPerform() 
				and vehicleCraftSurf.canPerformCurrentRecipeREMAKE(logic, playerObj) 
				and craftRecipe:isAnySurfaceCraft() 
				and not logic:isCharacterInRangeOfWorkbench()
				and (vehicleCraftSurf.isCharacterInRangeVehicleHood(playerObj) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(playerObj))
			then
				returnTestRecipes:add(craftRecipe)
			end
		end
	end
	
	return returnTestRecipes
end

local ISInventoryPaneContextMenuOnNewCraft = ISInventoryPaneContextMenu.OnNewCraft
function ISInventoryPaneContextMenu.OnNewCraft(selectedItem, recipe, player, all, eatPercentage)
	local playerObj = getSpecificPlayer(player)
	local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
	local logic = HandcraftLogic.new(playerObj, nil, nil)
	logic:setIsoObject(logic:findCraftSurface(playerObj, 2))
	logic:setContainers(containers)
	logic:setRecipeFromContextClick(recipe, selectedItem)

	if logic:canPerformCurrentRecipe() then
		ISInventoryPaneContextMenuOnNewCraft(selectedItem, recipe, player, all, eatPercentage)
		
	elseif recipe:isAnySurfaceCraft() 
		and vehicleCraftSurf.canPerformCurrentRecipeREMAKE(logic, playerObj) 
		and not logic:isCharacterInRangeOfWorkbench() 
		and (vehicleCraftSurf.isCharacterInRangeVehicleHood(playerObj) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(playerObj))
	then
		local items = logic:getRecipeData():getAllInputItems()
		local itemsToReturn = logic:getRecipeData():getAllPutBackInputItems()

		if logic:isUsingRecipeAtHandBenefit() then
			local recipeAtHandItem = logic:getUsingRecipeAtHandItem()
			if recipeAtHandItem then
				items:add(recipeAtHandItem)
				itemsToReturn:add(recipeAtHandItem)
			end
		end

		local returnToContainer = {}
		if not recipe:isCanBeDoneFromFloor() then
			local itemsWereMoved = false
			for i=1,items:size() do
				local item = items:get(i-1)
				if item:getContainer() ~= playerObj:getInventory() then
					ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
					if itemsToReturn:contains(item) then
						table.insert(returnToContainer, item)
					end
					itemsWereMoved = true
				end
			end
			if itemsWereMoved then
				logic:setRecipeFromContextClick(recipe, selectedItem)
			end
		end

		local action = ISEntityUI.HandcraftStart(playerObj, logic, false, true, eatPercentage)
		if action then
			if not all then
				action:setOnComplete(ISInventoryPaneContextMenu.OnNewCraftComplete, logic)
			end
			logic:startCraftAction(action)
		end

		ISCraftingUI.ReturnItemsToOriginalContainer(playerObj, returnToContainer)
	end
end

local ISEntityUIHandcraftStart = ISEntityUI.HandcraftStart
function ISEntityUI.HandcraftStart(_player, _handcraftLogic, force, addToQueue, eatPercentage)
	local action = ISEntityUIHandcraftStart(_player, _handcraftLogic, force, addToQueue, eatPercentage)

	if not action then
		if not _player or not _handcraftLogic then return end

		if _player ~= _handcraftLogic:getPlayer() then return end

		if not _handcraftLogic:canPerformCurrentRecipe() and not force then
			if _handcraftLogic:getRecipe():isAnySurfaceCraft() 
				and vehicleCraftSurf.canPerformCurrentRecipeREMAKE(_handcraftLogic, _player) 
				and not _handcraftLogic:isCharacterInRangeOfWorkbench() 
				and (vehicleCraftSurf.isCharacterInRangeVehicleHood(_player) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(_player))
			then
				action = ISHandcraftAction.FromLogic(_handcraftLogic, eatPercentage)
				action.force = force
				if addToQueue then
					ISTimedActionQueue.add(action)
				end
			else
				log(DebugType.CraftLogic, "Aborting ISEntityUI.HandcraftStart, conditions for 'vehicle hood/trunk' crafting not met.")
			end
		end

	end

	return action
end

function ISHandcraftWindow:createChildren()
    ISCollapsableWindow.createChildren(self);

    self.windowHeader = ISXuiSkin.build(self.xuiSkin, nil, ISHandcraftWindowHeader, 0, 0, 10, 10, self.player);
    if self.isoObject then
		local header = getText("IGUI_CraftingWindow_Header");
		local props = self.isoObject:getProperties();
		local surface = (props and props:has("IsMoveAble") and props:has("CustomName") and props:get("CustomName")) or getText("IGUI_CraftingWindow_Surface"); --self.isoObject:getProperties():has("IsMoveAble") and
        self.windowHeader.titleStr = header .. surface;
	elseif vehicleCraftSurf.isCharacterInRangeVehicleHood(self.player) then
		local header = getText("IGUI_CraftingWindow_Header");
		local vehicle = getText("GameSound_Category_Vehicle");
		local hood = getText("IGUI_VehiclePartEngineDoor");
		self.windowHeader.titleStr = header .. vehicle .. " " .. hood;
	elseif vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(self.player) then
		local header = getText("IGUI_CraftingWindow_Header");
		local orText = getText("IGUI_CraftingWindow_Or");
		local trailer = getText("IGUI_VehiclePartTrailerTrunk");
		local trunk = getText("IGUI_ContainerTitle_TruckBedOpen");
		self.windowHeader.titleStr = header .. trailer .. " " .. orText .. " " .. trunk;
	end
    self.windowHeader:initialise();
    self.windowHeader:instantiate();
    self:addChild(self.windowHeader);

    -- lock button
    local th = self:titleBarHeight()
    local buttonHeight = th-2
    local x = self.width - ((buttonHeight - 1) * 2) - 1;
    self.lockButton = ISButton:new(x, 0, buttonHeight, buttonHeight, "", self, ISHandcraftWindow.toggleLock);
    self.lockButton.anchorRight = false;
    self.lockButton.anchorLeft = false;
    self.lockButton:initialise();
    self.lockButton.borderColor.a = 0.0;
    self.lockButton.backgroundColor.a = 0;
    self.lockButton.backgroundColorMouseOver.a = 0;
    if self.locked then
        self.lockButton:setImage(self.lockedButtonTexture);
    else
        self.lockButton:setImage(self.unlockedButtonTexture);
    end
    self.lockButton:setUIName(getText("Lock"));
    self:addChild(self.lockButton);
    self.lockButton:setVisible(true);
    
    self.handCraftPanel = ISXuiSkin.build(self.xuiSkin, nil, ISHandCraftPanel, 0, 0, 10, 10, self.player, nil, self.isoObject);
    if self.queryOverride then
        self.handCraftPanel.recipeQuery = self.queryOverride;
    else
        self.handCraftPanel.recipeQuery = "InHandCraft;AnySurfaceCraft";
    end
    self.handCraftPanel:initialise();
    self.handCraftPanel:instantiate();
    self:addChild(self.handCraftPanel);

    if self.pinButton then
        self.pinButton:setAnchorRight(false);
    end
    if self.collapseButton then
        self.collapseButton:setAnchorRight(false);
    end

    -- due to onResize -> calculateLayout anchors causing issues we set custom resize function to widgets.
    self.resizeWidget.resizeFunction = ISHandcraftWindow.calculateLayout;
    self.resizeWidget2.resizeFunction = ISHandcraftWindow.calculateLayout;

    self:xuiRecalculateLayout();
end

function ISHandcraftWindow:prerender()
    self:stayOnSplitScreen();

    if self.dirtyLayout then
        local oldX = self:getX();
        local oldWidth = self:getWidth();
        if self.calculateLayout then self:calculateLayout(self.xuiPreferredResizeWidth, self.xuiPreferredResizeHeight); end
        self.dirtyLayout = false;

        if self.xuiResizeAnchorRight then
            self:setX(oldX - (self:getWidth()-oldWidth))
            self.xuiResizeAnchorRight = false;
        end
    end

    if self.isoObject then
        if self.isoObjectInProximity then
            local header = getText("IGUI_CraftingWindow_Header");
            local props = self.isoObject:getProperties();
            local surface = (props and props:has("IsMoveAble") and props:has("CustomName") and props:get("CustomName")) or getText("IGUI_CraftingWindow_Surface"); --self.isoObject:getProperties():has("IsMoveAble") and
            self.windowHeader.title.name = header .. surface;
        else
            self.windowHeader.title.name = getText("IGUI_CraftingWindow_Title");
        end
	elseif vehicleCraftSurf.isCharacterInRangeVehicleHood(self.player) then
		local header = getText("IGUI_CraftingWindow_Header");
		local vehicle = getText("GameSound_Category_Vehicle");
		local hood = getText("IGUI_VehiclePartEngineDoor");
		self.windowHeader.title.name = header .. vehicle .. " " .. hood;
	elseif vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(self.player) then
		local header = getText("IGUI_CraftingWindow_Header");
		local orText = getText("IGUI_CraftingWindow_Or");
		local trailer = getText("IGUI_VehiclePartTrailerTrunk");
		local trunk = getText("IGUI_ContainerTitle_TruckBedOpen");
		self.windowHeader.title.name = header .. trailer .. " " .. orText .. " " .. trunk;
    else
        self.windowHeader.title.name = getText("IGUI_CraftingWindow_Title");
    end

    ISCollapsableWindow.prerender(self);
end

local ISRecipeScrollingListBoxIsCraftable = ISRecipeScrollingListBox.isCraftable
function ISRecipeScrollingListBox:isCraftable(_craftRecipe)
	local scrollListHighlight = ISRecipeScrollingListBoxIsCraftable(self, _craftRecipe)

	if not scrollListHighlight then
		local cachedRecipeInfo = self.logic:getCachedRecipeInfo(_craftRecipe)
		local newLogic = HandcraftLogic.new(self.player, nil, nil)
		newLogic:setContainers(ISInventoryPaneContextMenu.getContainers(self.player))
		newLogic:setRecipe(_craftRecipe)
		if cachedRecipeInfo and cachedRecipeInfo:isValid() and not cachedRecipeInfo:isCanPerform() 
			and vehicleCraftSurf.canPerformCurrentRecipeREMAKE(newLogic, self.player) 
			and _craftRecipe:isAnySurfaceCraft() 
			and not newLogic:isCharacterInRangeOfWorkbench() 
			and (vehicleCraftSurf.isCharacterInRangeVehicleHood(self.player) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(self.player))
		then
			cachedRecipeInfo:overrideCanPerform(true)
			return true
		else
			return false
		end
	end

	return scrollListHighlight
end

local ISEntityUIHandcraftStartMultiple = ISEntityUI.HandcraftStartMultiple
function ISEntityUI.HandcraftStartMultiple( _player, _handcraftLogic, force, qty, addToQueue)
	local actions = ISEntityUIHandcraftStartMultiple( _player, _handcraftLogic, force, qty, addToQueue)

	local tableEmpty = true
	if not actions then return nil end
	for k,action in ipairs(actions) do
		tableEmpty = false
		break
	end

	if tableEmpty 
		and vehicleCraftSurf.canPerformCurrentRecipeREMAKE(_handcraftLogic, _player) 
		and _handcraftLogic:getRecipe():isAnySurfaceCraft() 
		and not _handcraftLogic:isCharacterInRangeOfWorkbench() 
		and (vehicleCraftSurf.isCharacterInRangeVehicleHood(_player) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(_player))
	then
		for i = 0, qty-1 do
			local action = ISHandcraftAction.FromLogicMultiple(_handcraftLogic);
			action.force = force
			if addToQueue then
				ISTimedActionQueue.add(action);
			end
			table.insert(actions, action);
		end
	end
		
	return actions;
end

local ISWidgetHandCraftControlPrerender = ISWidgetHandCraftControl.prerender
function ISWidgetHandCraftControl:prerender()
	ISWidgetHandCraftControlPrerender(self)

	if self.logic and not (self.logic:isCraftActionInProgress() and self.logic:getCraftActionTable()) then
		if self.buttonCraft and not self.buttonCraft.enable then
			local recipe = self.logic:getRecipe()
			if recipe and recipe:isAnySurfaceCraft() 
			and vehicleCraftSurf.canPerformCurrentRecipeREMAKE(self.logic, self.player)
			and not self.logic:isCharacterInRangeOfWorkbench() 
			and (vehicleCraftSurf.isCharacterInRangeVehicleHood(self.player) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(self.player))
			then
				self.buttonCraft.enable = true--self.logic:cachedCanPerformCurrentRecipe()		--Unintended results? Button being enabled when it not all needs are met, BUT, it still will not perform the recipe if clicked on.
			end
		end
	end
end

local ISWidgetTitleHeaderUpdateLabels = ISWidgetTitleHeader.updateLabels
function ISWidgetTitleHeader:updateLabels()
	ISWidgetTitleHeaderUpdateLabels(self)

	if self.logic and not self.logic:cachedCanPerformCurrentRecipe() then
		if self.errorLabel.errorText and string.contains(self.errorLabel.errorText, getText("IGUI_CraftingWindow_Error_Workbench")) then
			local errorText = "";
			if not self.logic:areAllInputItemsSatisfied() then
				if errorText ~= "" then errorText = errorText .. ", " end
				errorText = errorText .. getText("IGUI_CraftingWindow_Error_Inputs");
			end
			if not self.isCanWalk and self.player:isPlayerMoving() then
				if errorText ~= "" then errorText = errorText .. ", " end
				errorText = errorText .. getText("IGUI_CraftingWindow_Error_Moving");
			end
			if self.needToBeLearn and not self.player:isRecipeKnown(self.recipe, true) then
				if errorText ~= "" then errorText = errorText .. ", " end
				errorText = errorText .. getText("IGUI_CraftingWindow_Error_NotLearn");
			end
			if not self.canBeDoneInDark and self.player:tooDarkToRead() then
				if errorText ~= "" then errorText = errorText .. ", " end
				errorText = errorText .. getText("IGUI_CraftingWindow_Error_TooDark");
			end
			if self.requiresSurface and not (self.logic:isCharacterInRangeOfWorkbench() or (vehicleCraftSurf.isCharacterInRangeVehicleHood(self.player) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(self.player))) then
				if errorText ~= "" then errorText = errorText .. ", " end
				errorText = errorText .. getText("IGUI_CraftingWindow_Error_Workbench");
			end
			if errorText ~= "" then
				errorText = getText("IGUI_CraftingWindow_Error_NotAvailable") .. errorText;
				self.errorLabel.errorText = errorText;
				self.errorLabel:setVisible(true);
			else
				self.errorLabel:setVisible(false);
			end
		end
	else
		self.errorLabel:setVisible(false);
	end
end

local ISWidgetTitleHeaderUpdatePropertyIcons = ISWidgetTitleHeader.updatePropertyIcons
function ISWidgetTitleHeader:updatePropertyIcons()
	ISWidgetTitleHeaderUpdatePropertyIcons(self)

	if self.showPropertyIcons and self.requiresSurfaceIcon then
		self.requiresSurfaceIcon.backgroundColor = self.logic and not ((vehicleCraftSurf.isCharacterInRangeVehicleHood(self.player) or vehicleCraftSurf.isCharacterInRangeVehicleOpenTrunk(self.player)) or self.logic:isCharacterInRangeOfWorkbench()) and self.colBad or self.colWhite;
	end
end