require "ISUI/ISPanel"

NC_CraftLogicInventoryPanel = ISPanel:derive("NC_CraftLogicInventoryPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryPanel:initialise()
    ISPanel.initialise(self)
end

function NC_CraftLogicInventoryPanel:new(x, y, width, height, player, logic)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.player = player
    o.logic = logic
    o.entity = logic:getEntity()
    o.craftLogicComponent = logic:getCraftLogic()

    o.boxPadding = math.floor(FONT_HGT_SMALL * 0.2)
    o.panelPadding = o.boxPadding * 2
    o.BoxWidth = math.floor(width - o.boxPadding * 2 - FONT_HGT_SMALL * 0.6)
    o.BoxHeight = math.floor(FONT_HGT_SMALL * 2.5)
    o.BoxSpacing = math.floor(FONT_HGT_SMALL * 0.3)

    o.minimumWidth = 200
    o.minimumHeight = 100

    o.inventoryItems = {}
    o.itemStates = {}
    o.expandedStates = {}
    o.savedScrollY = 0
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(self.minimumWidth, _preferredWidth or 0)
    local height = math.max(self.minimumHeight, _preferredHeight or 0)

    self.BoxWidth = math.floor(width - self.boxPadding * 2 - FONT_HGT_SMALL * 0.6)
    
    if self.ScrollView then
        local contentHeight = height - self.panelPadding * 2
        local contentWidth = width - self.panelPadding

        self.ScrollView:setX(self.panelPadding)
        self.ScrollView:setY(self.panelPadding)
        self.ScrollView:setWidth(contentWidth)
        self.ScrollView:setHeight(contentHeight)
        self.ScrollView:setScrollSensitivity(self.BoxHeight + self.BoxSpacing)
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryPanel:createChildren()

    local contentHeight = self.height - self.panelPadding * 2
    local contentWidth = self.width - self.panelPadding

    self.ScrollView = NIScrollView:new(self.panelPadding, self.panelPadding, contentWidth, contentHeight)
    self.ScrollView:initialise()
    self.ScrollView:setScrollDirection("vertical")
    self.ScrollView:setScrollSensitivity(self.BoxHeight + self.BoxSpacing)
    self:addChild(self.ScrollView)

    self:loadItems()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Recipe Data
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryPanel:loadItems()
    
    self.inventoryItems = {}
    self.savedScrollY = 0

    self:collectAllInputItems()

    self:populate()
end

function NC_CraftLogicInventoryPanel:collectAllInputItems()
    local recipeList = self.logic:getRecipeList()

    if not recipeList or recipeList:size() == 0 then return end

    local itemToRecipesMap = {}
    for i = 0, recipeList:size() - 1 do
        local recipe = recipeList:get(i)
        local inputs = recipe:getInputs()
        
        for j = 0, inputs:size() - 1 do
            local input = inputs:get(j)
            local possibleItems = input:getPossibleInputItems()
            
            for k = 0, possibleItems:size() - 1 do
                local scriptItem = possibleItems:get(k)
                local itemType = scriptItem:getFullName()
                
                if not itemToRecipesMap[itemType] then
                    itemToRecipesMap[itemType] = {
                        scriptItem = scriptItem,
                        recipes = {},
                        inputScript = input
                    }
                end
                
                local alreadyAdded = false
                for _, existingRecipe in ipairs(itemToRecipesMap[itemType].recipes) do
                    if existingRecipe == recipe then
                        alreadyAdded = true
                        break
                    end
                end
                
                if not alreadyAdded then
                    table.insert(itemToRecipesMap[itemType].recipes, recipe)
                end
            end
        end
    end

    local playerInventory = self.player:getInventory()

    local itemList = {}
    for itemType, itemData in pairs(itemToRecipesMap) do
        local inventoryCount = playerInventory:getCountTypeRecurse(itemType)
        local inInventory = inventoryCount > 0
        
        local finalItemData = {
            scriptItem = itemData.scriptItem,
            recipes = itemData.recipes,
            inputScript = itemData.inputScript,
            inventoryCount = inventoryCount,
            inInventory = inInventory,
            totalCount = inventoryCount,
            expanded = false
        }
        
        table.insert(itemList, finalItemData)
    end
    self.inventoryItems = itemList
end

-- ----------------------------------------------------------------------------------------------------- --
-- UI Expanded
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryPanel:isItemExpanded(itemIndex)
    return self.expandedStates[itemIndex] or false
end

function NC_CraftLogicInventoryPanel:toggleItemExpanded(itemIndex)
    if self.ScrollView and self.ScrollView.getYScroll then
        self.savedScrollY = self.ScrollView:getYScroll()
    end
    
    local wasExpanded = self:isItemExpanded(itemIndex)
    self.expandedStates[itemIndex] = not wasExpanded
    
    self:populate()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Select
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryPanel:onItemSelected(itemData, itemIndex)
    if itemData.recipes and #itemData.recipes > 0 then
        local firstRecipe = itemData.recipes[1]
        self:selectRecipe(firstRecipe)
    end

    if itemData.inInventory then
        self:toggleItemExpanded(itemIndex)
    end
end

function NC_CraftLogicInventoryPanel:onRecipeSelected(recipe)
    self:selectRecipe(recipe)
end

function NC_CraftLogicInventoryPanel:selectRecipe(recipe)
    if not recipe then return end
    
    self.logic:setRecipe(recipe)

    self:populate()
end

-- ----------------------------------------------------------------------------------------------------- --
-- populate
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryPanel:populate()
    self:clearAllScrollChildren()
    
    local currentY = 0
    local visibleIndex = 0

    for i, itemData in ipairs(self.inventoryItems) do
        visibleIndex = visibleIndex + 1
        
        if visibleIndex > 1 then
            currentY = currentY + self.BoxSpacing
        end

        local itemBox = NC_CraftLogicInventoryBox:new(0, currentY, self.BoxWidth, self.BoxHeight, itemData, self, i)
        itemBox:initialise()
        self.ScrollView:addScrollChild(itemBox)
        currentY = currentY + self.BoxHeight

        local isExpanded = self:isItemExpanded(i)

        if isExpanded and itemData.inInventory then
            local expandedPanel = NC_CraftLogicInventoryExpanded:new(0, currentY, self.BoxWidth, itemData.recipes, self, i)
            expandedPanel:initialise()
            self.ScrollView:addScrollChild(expandedPanel)
            
            local expandedHeight = expandedPanel:getHeight()
            currentY = currentY + expandedHeight
        end
    end

    local totalHeight = currentY + self.boxPadding
    self.ScrollView:setScrollHeight(totalHeight)

    
    local maxScrollY = math.max(0, totalHeight - self.ScrollView:getHeight())
    local newScrollY = math.min(self.savedScrollY, maxScrollY)
    self.ScrollView:setYScroll(newScrollY)

end

function NC_CraftLogicInventoryPanel:clearAllScrollChildren()
    if not self.ScrollView then return end
    
    for i = #self.ScrollView.scrollChildren, 1, -1 do
        local child = self.ScrollView.scrollChildren[i]
        self.ScrollView:removeScrollChild(child)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryPanel:updateContainers(containers)

    self:loadItems()
end

function NC_CraftLogicInventoryPanel:onRecipeChanged()
    self:populate()
end

function NC_CraftLogicInventoryPanel:onUpdateRecipeList()
    self:loadItems()
end

function NC_CraftLogicInventoryPanel:onContainersChanged()
    self:loadItems()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryPanel:prerender()
    local panelbackground = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/InnerPanel_BG.png")
    if panelbackground then
        panelbackground:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, NCConfig.innerBackgroundAlpha)
    end
end

return NC_CraftLogicInventoryPanel