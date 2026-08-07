require "ISUI/ISPanel"

NB_CellRecipeList = ISPanel:derive("NB_CellRecipeList")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_CellRecipeList:initialise()
    ISPanel.initialise(self)
end

function NB_CellRecipeList:new(x, y, width, height, BuildingPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o:noBackground()
    o.BuildingPanel = BuildingPanel
    o.player = BuildingPanel.player
    o.logic = BuildingPanel.logic
    o.padding = BuildingPanel.padding
    o.filterBarHeight = BuildingPanel.filterbarHeight
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --
function NB_CellRecipeList:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or 0
    local height = _preferredHeight or 0

    if self.filterBar then
        self.filterBar:setX(0)
        self.filterBar:setY(0)
        self.filterBar:setWidth(width)
        self.filterBar:setHeight(self.filterBarHeight)
        self.filterBar:calculateLayout(width, self.filterBarHeight)
    end

    if self.recipeListPanel then
        local listY = self.padding + self.filterBarHeight
        local listHeight = height - listY - self.padding
        
        self.recipeListPanel:setX(0)
        self.recipeListPanel:setY(listY)
        self.recipeListPanel:calculateLayout(width, listHeight)
    end


    width = math.max(width, math.max(self.recipeListPanel:getWidth(),self.filterBar:getWidth()))
    height = math.max(height, self.filterBar:getHeight() + self.recipeListPanel:getHeight() + self.padding*2)

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NB_CellRecipeList:createChildren()
    -- FilterBar
    self.filterBar = NB_FilterBar:new(0, 0, 10, 10, self.BuildingPanel)
    self.filterBar:initialise()
    self:addChild(self.filterBar)

    -- RecipeListPanel
    self.recipeListPanel = NB_BuildingRecipeList_Panel:new(0, 0, 10, 10, self.BuildingPanel)
    self.recipeListPanel:initialise()
    self:addChild(self.recipeListPanel)
end

return NB_CellRecipeList