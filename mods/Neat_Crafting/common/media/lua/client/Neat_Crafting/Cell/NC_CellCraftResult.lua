require "ISUI/ISPanel"

NC_CellCraftResult = ISPanel:derive("NC_CellCraftResult")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------------------------------------------------------------------- --
-- instantiate
-- ----------------------------------------------------------------------------------------------------- --
function NC_CellCraftResult:initialise()
    ISPanel.initialise(self)
end

function NC_CellCraftResult:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    o.padding = HandCraftPanel.padding
    o.actionPanelWidth = math.floor(NCConfig.inputPanelWidth * 2 / 5)
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_CellCraftResult:createChildren()

    self.craftoutputPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_CraftOutput_Panel, 0, 0, 10, 10, self.HandCraftPanel)
    self.craftoutputPanel:initialise()
    self:addChild(self.craftoutputPanel)

    self.craftActionPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_CraftActionPanel, 0, 0, 10, 10, self.HandCraftPanel)
    self.craftActionPanel:initialise()
    self:addChild(self.craftActionPanel)
end

-- ----------------------------------------------------------------------------------------------------- --
-- calculateLayout
-- ----------------------------------------------------------------------------------------------------- --
function NC_CellCraftResult:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    self:layoutChildren(width, height)

    self:setWidth(width)
    self:setHeight(height)
end

function NC_CellCraftResult:layoutChildren(width, height)
    local outputPanelWidth = width - self.actionPanelWidth - self.padding

    if self.craftoutputPanel then
        self.craftoutputPanel:setX(0)
        self.craftoutputPanel:setY(0)
        self.craftoutputPanel:setWidth(outputPanelWidth)
        self.craftoutputPanel:setHeight(height)
        self.craftoutputPanel:calculateLayout(outputPanelWidth, height)
    end
    
    if self.craftActionPanel then
        local actionX = outputPanelWidth + self.padding
        
        self.craftActionPanel:setX(actionX)
        self.craftActionPanel:setY(0)
        self.craftActionPanel:setWidth(self.actionPanelWidth)
        self.craftActionPanel:setHeight(height)
        self.craftActionPanel:calculateLayout(self.actionPanelWidth, height)
    end
end

return NC_CellCraftResult