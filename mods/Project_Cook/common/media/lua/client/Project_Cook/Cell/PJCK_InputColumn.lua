require "ISUI/ISPanel"
require "Project_Cook/EvolvedRecipePanel/PJCK_InputPanel"


PJCK_InputColumn = ISPanel:derive("PJCK_InputColumn")

-- ----------------------------------------- --
-- initialise
-- ----------------------------------------- --
function PJCK_InputColumn:initialise()
    ISPanel.initialise(self)
end

function PJCK_InputColumn:new(x, y, width, height, EvoPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.EvoPanel = EvoPanel
    o.player = EvoPanel.player
    o.padding = EvoPanel.padding
    
    return o
end

function PJCK_InputColumn:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.width)
    local height = math.max(_preferredHeight or 0, self.height)

    local panelHeight = (height - self.padding * 3) / 2
    if self.ingredientsPanel then
        self.ingredientsPanel:setX(0)
        self.ingredientsPanel:setY(self.padding)
        self.ingredientsPanel:calculateLayout(width,panelHeight)
    end
    
    if self.seasoningsPanel then
        local seasoningY = self.padding + self.ingredientsPanel:getHeight() + self.padding
        self.seasoningsPanel:setX(0)
        self.seasoningsPanel:setY(seasoningY)
        self.seasoningsPanel:calculateLayout(width,panelHeight)
    end

    width = math.max(self.ingredientsPanel:getWidth(), self.seasoningsPanel:getWidth())
    height = math.max(height, self.ingredientsPanel:getHeight() + self.seasoningsPanel:getHeight() + self.padding * 3)

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------- --
-- createChildren
-- ----------------------------------------- --
function PJCK_InputColumn:createChildren()
    -- IngredientsPanel
    self.ingredientsPanel = PJCK_InputPanel:new(0, 0, 10, 10, self.EvoPanel, "Ingredient")
    self.ingredientsPanel:initialise()
    self.ingredientsPanel.titleText = getText("IGUI_PJCK_Ingredients")
    self:addChild(self.ingredientsPanel)
    
    -- seasoningsPanel
    self.seasoningsPanel = PJCK_InputPanel:new(0, 0, 10, 10, self.EvoPanel, "Seasoning")
    self.seasoningsPanel:initialise()
    self.seasoningsPanel.titleText = getText("IGUI_PJCK_Seasonings")
    self:addChild(self.seasoningsPanel)
end

return PJCK_InputColumn