require "ISUI/ISPanel"
require "Project_Cook/EvolvedRecipePanel/PJCK_BaseItem"
require "Project_Cook/EvolvedRecipePanel/PJCK_CookingInfo"


PJCK_BaseItemColumn = ISPanel:derive("PJCK_BaseItemColumn")

-- ----------------------------------------- --
-- initialise
-- ----------------------------------------- --
function PJCK_BaseItemColumn:initialise()
    ISPanel.initialise(self)
end

function PJCK_BaseItemColumn:new(x, y, width, height, EvoPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.EvoPanel = EvoPanel
    o.player = EvoPanel.player
    o.padding = EvoPanel.padding
    
    return o
end

function PJCK_BaseItemColumn:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.width)
    local height = math.max(_preferredHeight or 0, self.height)
    
    if self.baseItemPanel then
        self.baseItemPanel:setX(0)
        self.baseItemPanel:setY(self.padding)
        self.baseItemPanel:calculateLayout()
    end
    
    if self.cookingInfoPanel then
        local infoY = self.padding + self.baseItemPanel:getHeight() + self.padding
        local panelHeight = height - self.baseItemPanel:getHeight() - self.padding * 3
        self.cookingInfoPanel:setX(0)
        self.cookingInfoPanel:setY(infoY)
        self.cookingInfoPanel:calculateLayout(width, panelHeight)
    end
    
    local width = math.max(self.cookingInfoPanel:getWidth(), self.baseItemPanel:getWidth())
    local height = math.max(height,self.cookingInfoPanel:getHeight()+ self.baseItemPanel:getHeight() + self.padding * 3)

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------- --
-- createChildren
-- ----------------------------------------- --
function PJCK_BaseItemColumn:createChildren()
    -- BaseItem Panel
    self.baseItemPanel = PJCK_BaseItem:new(0, 0, 10, 10, self.EvoPanel)
    self.baseItemPanel:initialise()
    self:addChild(self.baseItemPanel)
    
    -- CookingInfo Panel
    self.cookingInfoPanel = PJCK_CookingInfo:new(0, 0, 10, 10, self.EvoPanel)
    self.cookingInfoPanel:initialise()
    self:addChild(self.cookingInfoPanel)
end

return PJCK_BaseItemColumn