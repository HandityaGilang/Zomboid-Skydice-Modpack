require "ISUI/ISPanel"

NC_RecipeList_Panel = ISPanel:derive("NC_RecipeList_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------- --

function NC_RecipeList_Panel:initialise()
    ISPanel.initialise(self)
end

function NC_RecipeList_Panel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    o.allRecipes = {}

    o.padding = HandCraftPanel.padding
    o.itemHeight = HandCraftPanel.recipeListItemHeight
    o.scrollViewSpacing = NCConfig.scrollViewSpacing

    o.gridItemSize = math.floor(FONT_HGT_SMALL * 2.5)
    o.gridColumnCount = 4
    o.gridPadding = o.padding
    o.filteredRecipes = {}
    
    return o
end
-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --

function NC_RecipeList_Panel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    local minWidth = NCConfig.recipeListWidth
    local minHeight = self.scrollViewSpacing * 2 + self.itemHeight * 3
    
    width = math.max(width, minWidth)
    height = math.max(height, minHeight)
    
    local currentStyle = self.logic:getSelectedRecipeStyle() or "list"
    
    if currentStyle == "list" then
        self.currentScrollView:setX(self.padding/2)
        self.currentScrollView:setY(self.scrollViewSpacing)
        self.currentScrollView:setWidth(width - self.padding/2)
        self.currentScrollView:setHeight(height - self.scrollViewSpacing * 2)
        local itemWidth = width - self.HandCraftPanel.scrollBarWidth - self.padding/2
        self.currentScrollView:setConfig(self.itemHeight, math.floor(self.padding/2))

        if self.currentScrollView.itemPool then
            for _, item in ipairs(self.currentScrollView.itemPool) do
                if item and item.setWidth then
                    item:setWidth(itemWidth)
                end
            end
        end
    else
        self.currentScrollView:setX(self.padding)
        self.currentScrollView:setY(self.scrollViewSpacing)
        self.currentScrollView:setWidth(width - self.padding)
        self.currentScrollView:setHeight(height - self.scrollViewSpacing * 2)
        local availableWidth = width - self.HandCraftPanel.scrollBarWidth - self.padding*2
        self:calculateGridLayout(availableWidth)
        self.currentScrollView:setConfig(self.gridItemSize, self.gridItemSize, self.gridColumnCount)
        self.currentScrollView:setSpacing(self.gridPadding, self.padding)
    end

    self:setWidth(width)
    self:setHeight(height)
    self:updateRecipeList(self.filteredRecipes)
end

function NC_RecipeList_Panel:calculateGridLayout(availableWidth)
    local maxColumns = math.max(1, math.floor((availableWidth + self.padding) / (self.gridItemSize + self.padding)))

    local usedWidth = maxColumns * self.gridItemSize + (maxColumns + 1) * self.padding
    local remainingWidth = availableWidth - usedWidth
    
    self.gridColumnCount = maxColumns
    if maxColumns > 1 and remainingWidth > 0 then
        self.gridPadding = self.padding + (remainingWidth / (maxColumns - 1))
    else
        self.gridPadding = self.padding
    end
end

-- ---------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------- --

function NC_RecipeList_Panel:createChildren()
    if self.currentScrollView then
        self:removeChild(self.currentScrollView)
        self.currentScrollView = nil
    end

    local ListStyle = self.logic:getSelectedRecipeStyle() or "list"
    if ListStyle == "grid" then
        self:createGridScrollView()
    else
        self:createListScrollView()
    end

    self:calculateLayout()
end

function NC_RecipeList_Panel:createListScrollView()
    self.currentScrollView = NIVirtualScrollView:new(0, 0, 10, 10)
    self.currentScrollView:initialise()
    local itemWidth = self.width - self.HandCraftPanel.scrollBarWidth - self.padding
    self.currentScrollView:setConfig(self.itemHeight, math.floor(self.padding/2))
    self:addChild(self.currentScrollView)

    self.currentScrollView:setOnCreateItem(function()
        return NC_RecipeList_Box:new(0, 0, itemWidth, self.itemHeight, nil, self)
    end)
    
    self.currentScrollView:setOnUpdateItem(function(itemObject, entry)
        itemObject:setEntry(entry)
    end)
end

function NC_RecipeList_Panel:createGridScrollView()
    self.currentScrollView = NIGridVirtualScrollView:new(0, 0, 10, 10)
    self.currentScrollView:initialise()
    self.currentScrollView:setConfig(self.gridItemSize, self.gridItemSize, self.gridColumnCount)
    self.currentScrollView:setSpacing(self.gridPadding, self.gridPadding)
    self:addChild(self.currentScrollView)
    self.currentScrollView:setOnCreateItem(function()
        return NC_RecipeList_Grid:new(0, 0, self.gridItemSize, nil, self)
    end)
    
    self.currentScrollView:setOnUpdateItem(function(itemObject, entry)
        itemObject:setEntry(entry)
    end)
end

function NC_RecipeList_Panel:isRecipeCraftableForGroup(recipe)
    if not recipe then
        return false
    end

    if self.player and self.player.isBuildCheat and self.player:isBuildCheat() then
        return true
    end

    if self.logic and self.logic.getCachedRecipeInfo then
        local cachedRecipeInfo = self.logic:getCachedRecipeInfo(recipe)
        if cachedRecipeInfo then
            if not cachedRecipeInfo:isValid() then
                return false
            end
            if not cachedRecipeInfo:isCanPerform() then
                return false
            end
        end
    end

    return true
end

function NC_RecipeList_Panel:toggleGroupNode(groupNode)
    if not groupNode or not groupNode.getChildren then
        return
    end

    local childNodes = groupNode:getChildren()
    local craftableChildCount = 0
    local totalChildCount = childNodes:size()

    for i = 0, totalChildCount - 1 do
        local childNode = childNodes:get(i)
        if childNode:getType() == CraftRecipeListNode.CraftRecipeListNodeType.RECIPE then
            if self:isRecipeCraftableForGroup(childNode:getRecipe()) then
                craftableChildCount = craftableChildCount + 1
            end
        end
    end

    -- Match the vanilla toggle behavior for partial/open/closed recipe groups.
    if craftableChildCount == 0 or craftableChildCount == totalChildCount then
        local newExpandedState = (groupNode:getExpandedState() == CraftRecipeListNodeExpandedState.OPEN)
            and CraftRecipeListNodeExpandedState.CLOSED
            or CraftRecipeListNodeExpandedState.OPEN
        groupNode:setExpandedState(newExpandedState)
    else
        groupNode:toggleExpandedState()
    end

    self.HandCraftPanel:updateRecipeDisplay()
end
-- ---------------------------------------------------------- --
-- Update RecipeList
-- ---------------------------------------------------------- --

function NC_RecipeList_Panel:updateRecipeList(filteredRecipes)
    self.filteredRecipes = filteredRecipes or {}

    if self.currentScrollView then
        self.currentScrollView:setDataSource(self.filteredRecipes, true)
    end
end

-- ---------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------- --

function NC_RecipeList_Panel:prerender()
    local contentBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/ContentPanel_BG.png")
    if contentBG then
        contentBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, NCConfig.recipeListBackgroundAlpha)
    end
end

return NC_RecipeList_Panel