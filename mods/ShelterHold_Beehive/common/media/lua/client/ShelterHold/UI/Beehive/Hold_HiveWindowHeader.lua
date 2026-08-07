require "ISUI/ISPanel"

Hold_HiveWindowHeader = ISPanel:derive("Hold_HiveWindowHeader")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveWindowHeader:initialise()
    ISPanel.initialise(self)
end

function Hold_HiveWindowHeader:new(x, y, width, height, parentWindow)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.parentWindow = parentWindow
    o.padding = parentWindow.padding
    o.iconSize = math.floor(FONT_HGT_MEDIUM * 3 / 2) * 2
    o.buttonSize = math.floor(FONT_HGT_MEDIUM)

    o.minimumWidth = o.iconSize + getTextManager():MeasureStringX(UIFont.Medium, parentWindow:getWindowTitle()) + o.buttonSize + o.padding * 4
    o.minimumHeight = FONT_HGT_MEDIUM * 1.5
    
    return o
end

function Hold_HiveWindowHeader:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.minimumWidth)
    local height = math.max(_preferredHeight or 0, self.minimumHeight)

    if self.closeButton then
        self.closeButton:setX(width - self.buttonSize - self.padding)
        self.closeButton:setY((height - self.buttonSize) / 2)
    end
    
    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveWindowHeader:createChildren()
    self.closeButton = NI_SquareButton:new(0, 0, self.buttonSize, getTexture("media/ui/NeatUI/Icon/Icon_False.png"), self, self.onCloseButtonClick)
    self.closeButton:initialise()
    self.closeButton:setActive(true)
    self.closeButton:setActiveColor(0.8, 0.2, 0.2)
    self:addChild(self.closeButton)
end

function Hold_HiveWindowHeader:onCloseButtonClick()
    if self.parentWindow and self.parentWindow.close then
        self.parentWindow:close()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- MouseFunction
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveWindowHeader:onMouseDown()
    self.moving = true
    self:setCapture(true)
    return true
end

function Hold_HiveWindowHeader:onMouseMove(dx, dy)
    if self.moving and self.parentWindow then
        self.parentWindow:setX(self.parentWindow.x + dx)
        self.parentWindow:setY(self.parentWindow.y + dy)
        return true
    end
    return false
end

function Hold_HiveWindowHeader:onMouseMoveOutside(dx, dy)
    if self.moving and self.parentWindow then
        self.parentWindow:setX(self.parentWindow.x + dx)
        self.parentWindow:setY(self.parentWindow.y + dy)
        return true
    end
    return false
end

function Hold_HiveWindowHeader:onMouseUp()
    if self.moving then
        self.moving = false
        self:setCapture(false)
        return true
    end
    return false
end

function Hold_HiveWindowHeader:onMouseUpOutside()
    if self.moving then
        self.moving = false
        self:setCapture(false)
        return true
    end
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveWindowHeader:prerender()
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/MainTitle_BG.png")
    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.08, 0.08, 0.08, 1)
    end
    self:drawRect(0, self.height - 1, self.width, 2, 1, 0, 0, 0)

    -- Icon
    local sprite = self.parentWindow.entity:getSpriteName()
    local icon = nil
    if sprite == "Hold_Beehive_1" then
        icon = getTexture("media/ui/ShelterHold/Icon/Icon_Beehive_1.png")
    elseif sprite == "Hold_Beehive_0" then
        icon = getTexture("media/ui/ShelterHold/Icon/Icon_Beehive_0.png")
    end
    local iconY = (self.height - self.iconSize) - self.padding / 2
    if icon then
        self:drawTextureScaled(icon, self.padding, iconY, self.iconSize, self.iconSize, 1, 1, 1, 1)
    end
    
    -- TitleText
    local titleX = self.padding + (icon and (self.iconSize + self.padding) or 0)
    local titleY = (self.height - FONT_HGT_MEDIUM) / 2
    local title = self.parentWindow:getWindowTitle()
    if title then
        self:drawText(title, titleX, titleY, 1, 1, 1, 1, UIFont.Medium)
    end
end