require "ISUI/ISPanel"

Hold_ExtProductCell = ISPanel:derive("Hold_ExtProductCell")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtProductCell:initialise()
    ISPanel.initialise(self)
end

function Hold_ExtProductCell:new(x, y, width, height, extPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o:noBackground()
    o.extPanel = extPanel
    o.player = extPanel.player
    o.entity = extPanel.entity
    o.padding = extPanel.padding
    
    return o
end

function Hold_ExtProductCell:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.width)
    local height = math.max(_preferredHeight or 0, self.height)

    if self.fluidContainerPanel and self.infoPanel then

        self.fluidContainerPanel:setX(self.padding)
        self.fluidContainerPanel:setY(self.padding)
        self.fluidContainerPanel:calculateLayout(0, 0)

        self.infoPanel:setX(self.fluidContainerPanel:getWidth() + self.padding)
        self.infoPanel:setY(self.padding)
        self.infoPanel:calculateLayout(0, self.fluidContainerPanel:getHeight())

        height = math.max(height, self.fluidContainerPanel:getHeight() + self.padding * 2, self.infoPanel:getHeight())
        width = math.max(width, self.fluidContainerPanel:getWidth() + self.padding*3 + self.infoPanel:getWidth())
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtProductCell:createChildren()

    self.fluidContainerPanel = Hold_ExtFluidContainerPanel:new(0, 0, 10, 10, self.extPanel)
    self.fluidContainerPanel:initialise()
    self:addChild(self.fluidContainerPanel)

    self.infoPanel = Hold_ExtInfoPanel:new(0, 0, 10, 10, self.extPanel)
    self.infoPanel:initialise()
    self:addChild(self.infoPanel)
end

function Hold_ExtProductCell:prerender()
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerPanel_BG.png")
    if bg then
        bg:render(self:getAbsoluteX() + self.padding, self:getAbsoluteY(), self.width - self.padding * 2, self.height, 0.1, 0.1, 0.1, 1)
    end
end

return Hold_ExtProductCell
