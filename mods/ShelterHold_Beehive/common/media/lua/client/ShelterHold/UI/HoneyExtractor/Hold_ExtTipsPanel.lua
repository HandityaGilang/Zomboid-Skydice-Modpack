require "ISUI/ISPanel"

Hold_ExtTipsPanel = ISPanel:derive("Hold_ExtTipsPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtTipsPanel:initialise()
    ISPanel.initialise(self)
end

function Hold_ExtTipsPanel:new(x, y, width, height, extPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.extPanel = extPanel
    o.player = extPanel.player
    
    o.padding = extPanel.padding
    o.iconSize = math.floor(FONT_HGT_SMALL * 2 / 2) * 2

    local line1Width = getTextManager():MeasureStringX(UIFont.Small,getText("Tooltip_HoneyExtractor_WouldDamaged"))
    local line2Width = getTextManager():MeasureStringX(UIFont.Small,getText("Tooltip_HoneyExtractor_ExtractDetail"))
    o.minimumWidth = o.padding * 5 + o.iconSize + math.max(line1Width, line2Width)
    o.minimumHeight = o.padding * 2 + FONT_HGT_SMALL * 2

    o.tipsIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Tips.png")
    
    return o
end

function Hold_ExtTipsPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    width = math.max(width, self.minimumWidth)
    height = math.max(height, self.minimumHeight)

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update and Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtTipsPanel:update()
    ISPanel.update(self)
end

function Hold_ExtTipsPanel:prerender()
    -- background
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerPanel_BG.png")
    if bg then
        bg:render(self:getAbsoluteX() + self.padding, self:getAbsoluteY(), self.width - self.padding * 2, self.height, 0.1, 0.1, 0.1, 1)
    end

    --Icon
    local currentX = self.padding * 2
    self:drawTextureScaled(self.tipsIcon, currentX, self.padding, self.iconSize, self.iconSize, 1, 1, 1, 1)
    currentX = currentX + self.iconSize + self.padding
    
    -- text
    local currentY = self.padding
    local titleText = getText("Tooltip_HoneyExtractor_WouldDamaged")
    local detailText = getText("Tooltip_HoneyExtractor_ExtractDetail")
    self:drawText(titleText, currentX, currentY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    currentY = currentY + FONT_HGT_SMALL
    self:drawText(detailText, currentX, currentY, 0.8, 0.8, 0.8, 1, UIFont.Small)
end

return Hold_ExtTipsPanel
