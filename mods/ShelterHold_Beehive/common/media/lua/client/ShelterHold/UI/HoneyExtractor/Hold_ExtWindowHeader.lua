require "ISUI/ISPanel"

Hold_ExtWindowHeader = ISPanel:derive("Hold_ExtWindowHeader")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtWindowHeader:initialise()
    ISPanel.initialise(self)
end

function Hold_ExtWindowHeader:new(x, y, width, height, parentWindow)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.parentWindow = parentWindow
    o.padding = parentWindow.padding
    o.iconSize = math.floor(FONT_HGT_MEDIUM * 3)
    o.buttonSize = math.floor(FONT_HGT_MEDIUM)

    o.minimumWidth = o.iconSize + getTextManager():MeasureStringX(UIFont.Medium, parentWindow:getWindowTitle()) + o.buttonSize + o.padding * 3
    o.minimumHeight = FONT_HGT_MEDIUM * 1.5
    
    return o
end

function Hold_ExtWindowHeader:calculateLayout(_preferredWidth, _preferredHeight)
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

function Hold_ExtWindowHeader:createChildren()
    self.closeButton = NI_SquareButton:new(0, 0, self.buttonSize, getTexture("media/ui/NeatUI/Icon/Icon_False.png"), self, self.onCloseButtonClick)
    self.closeButton:initialise()
    self.closeButton:setActive(true)
    self.closeButton:setActiveColor(0.8, 0.2, 0.2)
    self:addChild(self.closeButton)
end

function Hold_ExtWindowHeader:onCloseButtonClick()
    if self.parentWindow and self.parentWindow.close then
        self.parentWindow:close()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- MouseFunction
-- ----------------------------------------------------------------------------------------------------- --

function Hold_ExtWindowHeader:onMouseDown()
    self.moving = true
    self:setCapture(true)
    return true
end

function Hold_ExtWindowHeader:onMouseMove(dx, dy)
    if self.moving and self.parentWindow then
        self.parentWindow:setX(self.parentWindow.x + dx)
        self.parentWindow:setY(self.parentWindow.y + dy)
        return true
    end
    return false
end

function Hold_ExtWindowHeader:onMouseMoveOutside(dx, dy)
    if self.moving and self.parentWindow then
        self.parentWindow:setX(self.parentWindow.x + dx)
        self.parentWindow:setY(self.parentWindow.y + dy)
        return true
    end
    return false
end

function Hold_ExtWindowHeader:onMouseUp()
    if self.moving then
        self.moving = false
        self:setCapture(false)
        return true
    end
    return false
end

function Hold_ExtWindowHeader:onMouseUpOutside()
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

function Hold_ExtWindowHeader:prerender()
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/MainTitle_BG.png")
    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.08, 0.08, 0.08, 1)
    end
    self:drawRect(0, self.height - 1, self.width, 2, 1, 0, 0, 0)

    -- Icon
    local sprite = self.parentWindow.entity:getSpriteName()
    local icon = nil
    if sprite == ("Hold_HoneyExtractor_0" or "Hold_HoneyExtractor_1") then
        icon = getTexture("media/ui/ShelterHold/Icon/Icon_exctor_0.png")
    end
    local iconY = (self.height - self.iconSize) - self.padding / 2
    if icon then
        self:drawTextureScaled(icon, self.padding, iconY, self.iconSize, self.iconSize, 1, 1, 1, 1)
    end
    
    -- TitleText
    local titleX = self.padding + (self.iconSize + self.padding)
    local titleY = (self.height - FONT_HGT_MEDIUM) / 2
    local title = self.parentWindow:getWindowTitle()
    self:drawText(title, titleX, titleY, 1, 1, 1, 1, UIFont.Medium)
end

function Hold_ExtWindowHeader:render()
end