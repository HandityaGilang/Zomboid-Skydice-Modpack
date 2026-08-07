require "ISUI/ISPanel"

Hold_HiveRequiredCell = ISPanel:derive("Hold_HiveRequiredCell")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveRequiredCell:initialise()
    ISPanel.initialise(self)
end

function Hold_HiveRequiredCell:new(x, y, width, height, hivePanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.hivePanel = hivePanel
    o.parentWindow = hivePanel.parentWindow
    o.player = hivePanel.player
    o.padding = hivePanel.padding

    return o
end

function Hold_HiveRequiredCell:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.width)
    local height = math.max(_preferredHeight or 0, self.height)

    if self.beesPanel then
        self.beesPanel:setX(self.padding)
        self.beesPanel:setY(0)
        self.beesPanel:calculateLayout(0, height)
    end

    if self.envInfoPanel then
        self.envInfoPanel:setX(self.padding * 2 + self.beesPanel:getWidth())
        self.envInfoPanel:setY(0)
        self.envInfoPanel:calculateLayout(0, height)
    end

    if self.beesPanel and self.envInfoPanel then
        width = math.max(width, self.padding * 3 + self.beesPanel:getWidth() + self.envInfoPanel:getWidth())
        height = math.max(height, self.beesPanel:getHeight(), self.envInfoPanel:getHeight())
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveRequiredCell:createChildren()
    -- BeesPanel
    self.beesPanel = Hold_HiveBeesPanel:new(0, 0, 10, 10, self.hivePanel)
    self.beesPanel:initialise()
    self:addChild(self.beesPanel)
    
    -- EntityInfoPanel
    self.envInfoPanel = Hold_HiveEnvInfoPanel:new(0, 0, 10, 10, self.hivePanel)
    self.envInfoPanel:initialise()
    self:addChild(self.envInfoPanel)
end