require "ISUI/ISPanel"

NC_InputSwitch_Panel = ISPanel:derive("NC_InputSwitch_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function ncText(key, fallback)
    local text = getText(key)
    if not text or text == key then
        return fallback
    end
    return text
end

local function ncListSize(list)
    return list and list:size() or 0
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update Position and follow Handcraftpanel
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:updatePosition()
    if not self.HandCraftPanel then return end
    local ScreenPadding = FONT_HGT_SMALL * 0.2
    local newX = self.HandCraftPanel:getAbsoluteX() + self.HandCraftPanel:getWidth() + ScreenPadding
    local newY = self.HandCraftPanel:getAbsoluteY()

    local screenWidth = getCore():getScreenWidth()
    
    if newX + self.width > screenWidth then
        newX = self.HandCraftPanel:getAbsoluteX() - self.width - ScreenPadding
    end
    
    self:setX(newX)
    self:setY(newY)
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:initialise()
    ISPanel.initialise(self)
    self:updatePosition()
end

function NC_InputSwitch_Panel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.logic = HandCraftPanel.logic
    o.player = HandCraftPanel.player
    o.currentInputScript = nil

    o.boxPadding = math.floor(FONT_HGT_SMALL * 0.2)
    o.panelPadding = o.boxPadding * 2
    o.BoxWidth = math.floor(width - o.boxPadding * 2 - FONT_HGT_SMALL * 0.6)
    o.BoxHeight = math.floor(FONT_HGT_SMALL * 2.5)
    o.SectionHeight = math.max(FONT_HGT_SMALL + o.boxPadding * 2, math.floor(o.BoxHeight * 0.55))
    o.BoxSpacing = math.floor(FONT_HGT_SMALL * 0.3)

    o.expandedStates = {}
    o.InputscriptItems = {}
    o.savedScrollY = 0
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth
    local height = _preferredHeight

    self.BoxWidth = math.floor(width - self.boxPadding * 2 - FONT_HGT_SMALL * 0.6)
    self.SectionHeight = math.max(FONT_HGT_SMALL + self.boxPadding * 2, math.floor(self.BoxHeight * 0.55))
    if self.contentScrollView then
        local contentHeight = height - self.panelPadding * 2
        local contentWidth = width - self.panelPadding

        self.contentScrollView:setX(self.panelPadding)
        self.contentScrollView:setY(self.panelPadding)
        self.contentScrollView:setWidth(contentWidth)
        self.contentScrollView:setHeight(contentHeight)
        self.contentScrollView:setScrollSensitivity(self.BoxHeight + self.BoxSpacing)
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:createChildren()
    local contentHeight = self.height - self.panelPadding*2
    local contentWidth = self.width - self.panelPadding

    self.contentScrollView = NIScrollView:new(
        self.panelPadding, 
        self.panelPadding, 
        contentWidth, 
        contentHeight
    )
    self.contentScrollView:initialise()
    self.contentScrollView:setScrollDirection("vertical")
    self.contentScrollView:setScrollSensitivity(self.BoxHeight + self.BoxSpacing)
    self:addChild(self.contentScrollView)

    self:loadInputscriptItems()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Fluid helpers
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:getFluidConsumeScript(inputScript)
    if not inputScript or not inputScript.hasConsumeFromItem or not inputScript:hasConsumeFromItem() then
        return nil
    end

    local consumeScript = inputScript:getConsumeFromItemScript()
    if consumeScript and consumeScript.getResourceType and consumeScript:getResourceType() == ResourceType.Fluid then
        return consumeScript
    end

    return nil
end

function NC_InputSwitch_Panel:getFluidKey(fluid)
    if not fluid then return nil end
    if fluid.getFluidTypeString then
        return fluid:getFluidTypeString()
    end
    if fluid.getDisplayName then
        return fluid:getDisplayName()
    end
    return tostring(fluid)
end

function NC_InputSwitch_Panel:getFluidDisplayName(fluid)
    if not fluid then return "" end
    if fluid.getDisplayName then
        return fluid:getDisplayName()
    end
    return tostring(fluid)
end

function NC_InputSwitch_Panel:getFluidColor(fluid)
    if not fluid or not fluid.getColor then
        return 1, 1, 1
    end

    local color = fluid:getColor()
    if not color then
        return 1, 1, 1
    end

    return color:getRedFloat(), color:getGreenFloat(), color:getBlueFloat()
end

function NC_InputSwitch_Panel:isFluidAllowed(consumeScript, fluid)
    if not consumeScript or not fluid then return false end
    if consumeScript.containsFluid then
        return consumeScript:containsFluid(fluid)
    end
    return true
end

function NC_InputSwitch_Panel:addSectionHeader(text)
    table.insert(self.InputscriptItems, {
        itemType = "section",
        displayName = text or "",
        isHeader = true
    })
end

function NC_InputSwitch_Panel:addFluidRows(inputScript, consumeScript)
    if not consumeScript or not consumeScript.getPossibleInputFluids then return end

    local rowsByKey = {}
    local orderedRows = {}

    local function getOrCreateRow(fluid)
        local key = self:getFluidKey(fluid)
        if not key then return nil end

        local row = rowsByKey[key]
        if not row then
            row = {
                itemType = "fluid",
                fluid = fluid,
                displayName = self:getFluidDisplayName(fluid),
                AvailableItems = {},
                Count = 0,
                inInventory = false,
                isSelectedFluid = false
            }
            rowsByKey[key] = row
            table.insert(orderedRows, row)
        end
        return row
    end

    local possibleFluids = consumeScript:getPossibleInputFluids()
    for i = 0, ncListSize(possibleFluids) - 1 do
        getOrCreateRow(possibleFluids:get(i))
    end

    -- Current / satisfied fluids are taken from the applied container items.
    if self.logic.getSatisfiedInputFluids then
        local satisfiedFluids = self.logic:getSatisfiedInputFluids(consumeScript)
        for i = 0, ncListSize(satisfiedFluids) - 1 do
            local fluid = satisfiedFluids:get(i)
            local row = getOrCreateRow(fluid)
            if row then
                row.isSelectedFluid = true
                row.inInventory = true
            end
        end
    end

    -- Available fluids are inferred from the fluid containers that the current input can use.
    local inputItemNodes = self.logic:getInputItemNodesForInput(inputScript)
    for i = 0, ncListSize(inputItemNodes) - 1 do
        local node = inputItemNodes:get(i)
        local nodeItems = node and node:getItems()
        for j = 0, ncListSize(nodeItems) - 1 do
            local invItem = nodeItems:get(j)
            local fluidContainer = invItem and invItem.getFluidContainer and invItem:getFluidContainer() or nil
            local primaryFluid = fluidContainer and fluidContainer.getPrimaryFluid and fluidContainer:getPrimaryFluid() or nil
            if primaryFluid and self:isFluidAllowed(consumeScript, primaryFluid) then
                local row = getOrCreateRow(primaryFluid)
                if row then
                    row.inInventory = true
                    table.insert(row.AvailableItems, invItem)
                    row.Count = #row.AvailableItems
                end
            end
        end
    end

    if #orderedRows == 0 then return end

    table.sort(orderedRows, function(a, b)
        local aRank = a.isSelectedFluid and 0 or (a.inInventory and 1 or 2)
        local bRank = b.isSelectedFluid and 0 or (b.inInventory and 1 or 2)
        if aRank ~= bRank then return aRank < bRank end
        return tostring(a.displayName) < tostring(b.displayName)
    end)

    self:addSectionHeader(ncText("IGUI_NC_Liquids", "Liquids"))
    for _, row in ipairs(orderedRows) do
        table.insert(self.InputscriptItems, row)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Load InputScript
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:loadInputscriptItems()
    self.InputscriptItems = {}
    self.savedScrollY = 0
    
    local currentInputScript = self.logic:getManualSelectInputScriptFilter()
    if not currentInputScript then return end

    if self.currentInputScript ~= currentInputScript then
        self.expandedStates = {}
        self.currentInputScript = currentInputScript
    end

    local consumeScript = self:getFluidConsumeScript(currentInputScript)
    if consumeScript then
        self:addFluidRows(currentInputScript, consumeScript)
    end

    local existingItemTypes = {}
    local itemRows = {}
    local isContainerInput = consumeScript ~= nil
    
    self:addAvailableItems(currentInputScript, existingItemTypes, itemRows, isContainerInput)
    self:addPossibleItems(currentInputScript, existingItemTypes, itemRows, isContainerInput)

    if #itemRows > 0 then
        if isContainerInput then
            local headerText = ncText("IGUI_NC_Containers", "Containers")
            if currentInputScript.isAcceptsAnyItem and currentInputScript:isAcceptsAnyItem() then
                headerText = ncText("IGUI_NC_AnyContainer", "Any container")
            end
            self:addSectionHeader(headerText)
        end

        for _, inputInfo in ipairs(itemRows) do
            table.insert(self.InputscriptItems, inputInfo)
        end
    end

    self:calculateItemStates()
    self:populate()
end

-- Add Available first
function NC_InputSwitch_Panel:addAvailableItems(inputScript, existingItemTypes, targetRows, isContainerInput)
    targetRows = targetRows or self.InputscriptItems
    local inputItemNodes = self.logic:getInputItemNodesForInput(inputScript)
    
    for i = 0, ncListSize(inputItemNodes) - 1 do
        local node = inputItemNodes:get(i)
        local scriptItem = node:getScriptItem()
        local nodeItems = node:getItems()

        local AvailableItems = {}
        for j = 0, ncListSize(nodeItems) - 1 do
            table.insert(AvailableItems, nodeItems:get(j))
        end

        local InputInfo = {
            itemType = "item",
            scriptItem = scriptItem,
            AvailableItems = AvailableItems,
            Count = ncListSize(nodeItems),
            inInventory = true,
            isContainerInput = isContainerInput
        }
        
        table.insert(targetRows, InputInfo)
        existingItemTypes[scriptItem:getFullName()] = true
    end
end

-- Add Possible
function NC_InputSwitch_Panel:addPossibleItems(inputScript, existingItemTypes, targetRows, isContainerInput)
    targetRows = targetRows or self.InputscriptItems
    local allPossibleItems = inputScript:getPossibleInputItems()
    
    for i = 0, ncListSize(allPossibleItems) - 1 do
        local scriptItem = allPossibleItems:get(i)
        local itemType = scriptItem:getFullName()

        if not existingItemTypes[itemType] then
            local InputInfo = {
                itemType = "item",
                scriptItem = scriptItem,
                inInventory = false,
                isContainerInput = isContainerInput
            }
            
            table.insert(targetRows, InputInfo)
            existingItemTypes[itemType] = true
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Status
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:isItemExpanded(itemIndex)
    return self.expandedStates[itemIndex] or false
end

function NC_InputSwitch_Panel:toggleItemExpanded(itemIndex)

    self.savedScrollY = self.contentScrollView:getYScroll()
    
    local wasExpanded = self:isItemExpanded(itemIndex)
    self.expandedStates[itemIndex] = not wasExpanded

    self:populate()
end

function NC_InputSwitch_Panel:calculateItemStates()
    self.itemStates = {}
    
    local currentInputScript = self.logic:getManualSelectInputScriptFilter()
    if not currentInputScript then return end
    
    local inputFilterData = self.logic:getRecipeData():getDataForInputScript(currentInputScript)
    if not inputFilterData then return end
    
    local satisfiedItems = self.logic:getSatisfiedInputInventoryItems(currentInputScript)
    
    for i, InputInfo in ipairs(self.InputscriptItems) do
        local itemState = {
            hasSelectedItems = false,
            statusText = getText("IGUI_CraftUI_PossibleItems"),
            expandedItemStates = {}
        }

        if InputInfo.isHeader then
            itemState.statusText = ""
        elseif InputInfo.itemType == "fluid" then
            itemState.statusText = ncText("IGUI_NC_PossibleLiquids", "Possible liquids")

            local hasSelectedByCurrentInput = false
            local hasSelectedByOtherInput = false

            if InputInfo.AvailableItems then
                for _, item in ipairs(InputInfo.AvailableItems) do
                    if self.logic:getRecipeData():containsInputItem(item) then
                        local isAssignedToThisInput = self.logic:getRecipeData():containsInputItem(inputFilterData, item)
                        if isAssignedToThisInput then
                            hasSelectedByCurrentInput = true
                        else
                            hasSelectedByOtherInput = true
                        end
                        InputInfo.inInventory = true
                    end

                    local expandedItemStatus = "normal"
                    if self.logic:getRecipeData():containsInputItem(item) then
                        local isAssignedToThisInput = self.logic:getRecipeData():containsInputItem(inputFilterData, item)
                        expandedItemStatus = isAssignedToThisInput and "selected" or "usedByOther"
                    end
                    itemState.expandedItemStates[item] = expandedItemStatus
                end
            end

            if hasSelectedByCurrentInput or InputInfo.isSelectedFluid then
                itemState.hasSelectedItems = true
                itemState.statusText = ncText("IGUI_NC_SelectedLiquid", "Selected liquid")
            elseif hasSelectedByOtherInput then
                itemState.statusText = getText("IGUI_CraftUI_AlreadyAssigned")
            elseif InputInfo.inInventory then
                itemState.statusText = ncText("IGUI_NC_AvailableLiquids", "Available liquids")
            end
        elseif InputInfo.inInventory and InputInfo.AvailableItems then
            -- is items selected 
            for j = 0, ncListSize(satisfiedItems) - 1 do
                local selectedItem = satisfiedItems:get(j)
                for _, availableItem in ipairs(InputInfo.AvailableItems) do
                    if selectedItem == availableItem then
                        itemState.hasSelectedItems = true
                        break
                    end
                end
                if itemState.hasSelectedItems then break end
            end
            
            -- get status text
            local hasSelectedByCurrentInput = false
            local hasSelectedByOtherInput = false
            
            for _, item in ipairs(InputInfo.AvailableItems) do
                if self.logic:getRecipeData():containsInputItem(item) then
                    local isAssignedToThisInput = self.logic:getRecipeData():containsInputItem(inputFilterData, item)
                    if isAssignedToThisInput then
                        hasSelectedByCurrentInput = true
                    else
                        hasSelectedByOtherInput = true
                    end
                end
                
                -- get every item status
                local expandedItemStatus = "normal"
                if self.logic:getRecipeData():containsInputItem(item) then
                    local isAssignedToThisInput = self.logic:getRecipeData():containsInputItem(inputFilterData, item)
                    expandedItemStatus = isAssignedToThisInput and "selected" or "usedByOther"
                end
                
                itemState.expandedItemStates[item] = expandedItemStatus
            end

            if hasSelectedByCurrentInput then
                itemState.statusText = getText("IGUI_NC_InputItemSelected")
            elseif hasSelectedByOtherInput then
                itemState.statusText = getText("IGUI_CraftUI_AlreadyAssigned")
            elseif InputInfo.isContainerInput then
                itemState.statusText = ncText("IGUI_NC_AvailableContainers", "Available containers")
            else
                itemState.statusText = getText("IGUI_CraftUI_AvailableItems")
            end
        elseif InputInfo.isContainerInput then
            itemState.statusText = ncText("IGUI_NC_PossibleContainers", "Possible containers")
        end
        
        self.itemStates[i] = itemState
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Select
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:onItemSelected(selectedItem)
    self.savedScrollY = self.contentScrollView:getYScroll()
    
    local currentInputScript = self.logic:getManualSelectInputScriptFilter()
    local inputFilterData = self.logic:getRecipeData():getDataForInputScript(currentInputScript)
    if not inputFilterData then return end

    if self.logic:getRecipeData():containsInputItem(selectedItem) then
        local isAssignedToThisInput = self.logic:getRecipeData():containsInputItem(inputFilterData, selectedItem)
        
        if isAssignedToThisInput then
            -- If Selected ,Remove it
            self.logic:removeInputItem(selectedItem)
        else
            -- If Selected by other ,remove it then select it
            self.logic:removeInputItem(selectedItem)
            self.logic:offerInputItem(selectedItem)
        end
    else
        self.logic:offerInputItem(selectedItem)
    end

    self:calculateItemStates()
    self:populate()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Build or rebuild list
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:populate()
    self:clearAllScrollChildren()
    
    local currentY = 0

    for i, InputInfo in ipairs(self.InputscriptItems) do
        if i > 1 then
            currentY = currentY + self.BoxSpacing
        end

        local rowHeight = InputInfo.isHeader and self.SectionHeight or self.BoxHeight
        
        local InputBox = NC_InputSwitch_Box:new(
            0, currentY, self.BoxWidth, rowHeight, 
            InputInfo, self, i
        )
        InputBox:initialise()
        self.contentScrollView:addScrollChild(InputBox)
        currentY = currentY + rowHeight
        
        if self:isItemExpanded(i) and InputInfo.AvailableItems and #InputInfo.AvailableItems > 0 then
            local expandedPanel = NC_InputSwitch_Expanded:new(0, currentY, self.BoxWidth, InputInfo.AvailableItems, self, i)
            expandedPanel:initialise()
            self.contentScrollView:addScrollChild(expandedPanel)
            
            local expandedHeight = expandedPanel:getHeight()
            currentY = currentY + expandedHeight
        end
    end

    local totalHeight = currentY + self.boxPadding
    self.contentScrollView:setScrollHeight(totalHeight)
    
    local maxScrollY = math.max(0, totalHeight - self.contentScrollView:getHeight())
    local newScrollY = math.min(self.savedScrollY, maxScrollY)
    self.contentScrollView:setYScroll(newScrollY)
end

function NC_InputSwitch_Panel:clearAllScrollChildren()
    if not self.contentScrollView then return end
    
    for i = #self.contentScrollView.scrollChildren, 1, -1 do
        local child = self.contentScrollView.scrollChildren[i]
        self.contentScrollView:removeScrollChild(child)
    end
end

-- let the box invisible when we dont need
function NC_InputSwitch_Panel:updateBoxVisibility()
    if not self.contentScrollView then return end
    
    local viewportTop = -self.contentScrollView:getYScroll()
    local viewportBottom = viewportTop + self.contentScrollView:getHeight()
    local buffer = self.BoxHeight*3
    
    for _, child in ipairs(self.contentScrollView.scrollChildren) do
        if child.itemInfo then
            local boxTop = child:getY() - self.contentScrollView:getYScroll()
            local boxBottom = boxTop + child:getHeight()
            local isVisible = not (boxBottom < viewportTop - buffer or boxTop > viewportBottom + buffer)
            child:setVisible(isVisible)
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Base function
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:onManualSelectChanged(manualSelectInputs)
    if not manualSelectInputs then
        self:Close()
    else
        self:loadInputscriptItems()
    end
end

function NC_InputSwitch_Panel:onShowManualSelectChanged(shouldShow)
    if not shouldShow then
        self:Close()
    end
end

function NC_InputSwitch_Panel:onInputsChanged()
    self:calculateItemStates()
    self:populate()
end

function NC_InputSwitch_Panel:Close()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Panel:prerender()
    if self.HandCraftPanel and not self.HandCraftPanel:isReallyVisible() then
        self:Close()
		return
	end

    local panelbackground = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/MainPanelBG_RoundTop.png")
    if panelbackground then
        panelbackground:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, NCConfig.slotPopupBackgroundAlpha)
    end
end

function NC_InputSwitch_Panel:render()
    self:updatePosition()

    self:updateBoxVisibility()
end

return NC_InputSwitch_Panel
