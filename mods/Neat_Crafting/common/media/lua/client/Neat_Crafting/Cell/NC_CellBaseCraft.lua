require "ISUI/ISPanel"

NC_CellBaseCraft = ISPanel:derive("NC_CellBaseCraft")

-- ----------------------------------------------------------------------------------------------------- --
-- instantiate
-- ----------------------------------------------------------------------------------------------------- --

function NC_CellBaseCraft:initialise()
    ISPanel.initialise(self)
end

function NC_CellBaseCraft:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    o.padding = HandCraftPanel.padding
    o.recipeInfoMinHeight = NCConfig.recipeInfoMinHeight
    o.craftResultMinHeight = NCConfig.craftOutputMinHeight
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --

function NC_CellBaseCraft:createChildren()

    self.craftInputPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_CraftInput_Panel, 0, 0, 10, 10, self.HandCraftPanel)
    self.craftInputPanel:initialise()
    self:addChild(self.craftInputPanel)

    self.recipeInfoPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_RecipeInfoPanel, 0, 0, 10, 10, self.HandCraftPanel)
    self.recipeInfoPanel:initialise()
    self:addChild(self.recipeInfoPanel)

    self.craftResultPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_CellCraftResult, 0, 0, 10, 10, self.HandCraftPanel)
    self.craftResultPanel:initialise()
    self:addChild(self.craftResultPanel)
end

-- ----------------------------------------------------------------------------------------------------- --
-- calculateLayout
-- ----------------------------------------------------------------------------------------------------- --
function NC_CellBaseCraft:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height
    
    self:layoutChildren(width, height)

    self:setWidth(width)
    self:setHeight(height)
end

function NC_CellBaseCraft:layoutChildren(width, height)
    local currentY = self.padding

    local remainingHeight = height - self.padding * 4
    local inputPanelHeight = remainingHeight - self.recipeInfoMinHeight - self.craftResultMinHeight

    if self.craftInputPanel then
        self.craftInputPanel:setX(0)
        self.craftInputPanel:setY(currentY)
        self.craftInputPanel:setWidth(width)
        self.craftInputPanel:setHeight(inputPanelHeight)
        self.craftInputPanel:calculateLayout(width, inputPanelHeight)
    end

    currentY = currentY + inputPanelHeight + self.padding

    if self.recipeInfoPanel then
        self.recipeInfoPanel:setX(0)
        self.recipeInfoPanel:setY(currentY)
        self.recipeInfoPanel:setWidth(width)
        self.recipeInfoPanel:setHeight(self.recipeInfoMinHeight)
        self.recipeInfoPanel:calculateLayout(width, self.recipeInfoMinHeight)
    end

    currentY = currentY + self.recipeInfoMinHeight + self.padding

    if self.craftResultPanel then
        self.craftResultPanel:setX(0)
        self.craftResultPanel:setY(currentY)
        self.craftResultPanel:setWidth(width)
        self.craftResultPanel:setHeight(self.craftResultMinHeight)
        self.craftResultPanel:calculateLayout(width, self.craftResultMinHeight)
    end
end

return NC_CellBaseCraft