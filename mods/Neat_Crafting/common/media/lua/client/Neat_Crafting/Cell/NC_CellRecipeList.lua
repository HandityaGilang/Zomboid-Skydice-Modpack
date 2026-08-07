require "ISUI/ISPanel"

NC_CellRecipeList = ISPanel:derive("NC_CellRecipeList")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------------------------------------------------------------------- --
-- instantiate
-- ----------------------------------------------------------------------------------------------------- --
function NC_CellRecipeList:initialise()
    ISPanel.initialise(self)
end

function NC_CellRecipeList:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    o.padding = HandCraftPanel.padding

    o.filterBarHeight = HandCraftPanel.titleHeight
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_CellRecipeList:createChildren()

    self.filterBar = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_FilterBar, 0, 0, 10, 10, self.HandCraftPanel)
    self.filterBar:initialise()
    self:addChild(self.filterBar)

    self.recipeListPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_RecipeList_Panel, 0, 0, 10, 10, self.HandCraftPanel)
    self.recipeListPanel:initialise()
    self:addChild(self.recipeListPanel)
end

-- ----------------------------------------------------------------------------------------------------- --
-- calculateLayout
-- ----------------------------------------------------------------------------------------------------- --
function NC_CellRecipeList:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height
    
    self:layoutChildren(width, height)

    self:setWidth(width)
    self:setHeight(height)
end

function NC_CellRecipeList:layoutChildren(width, height)
    if self.filterBar then
        local filterY = self.padding
        
        self.filterBar:setX(0)
        self.filterBar:setY(filterY)
        self.filterBar:setWidth(width)
        self.filterBar:setHeight(self.filterBarHeight)
        self.filterBar:calculateLayout(width, self.filterBarHeight)
    end

    if self.recipeListPanel then
        local listY = self.padding + self.filterBarHeight
        local listHeight = height - listY - self.padding
        
        self.recipeListPanel:setX(0)
        self.recipeListPanel:setY(listY)
        self.recipeListPanel:setWidth(width)
        self.recipeListPanel:setHeight(listHeight)
        self.recipeListPanel:calculateLayout(width, listHeight)
    end
end

return NC_CellRecipeList