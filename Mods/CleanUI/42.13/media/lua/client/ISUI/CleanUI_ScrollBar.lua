require "ISUI/ISScrollBar"

CleanUI = CleanUI or {}
CleanUI.ScrollBar = ISScrollBar:derive("CleanUI_ScrollBar")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------------------------------------------------------------------- --
-- Instantiate
-- ----------------------------------------------------------------------------------------------------- --
function CleanUI.ScrollBar:instantiate()
    self.javaObject = UIElement.new(self)

    local padding = FONT_HGT_SMALL * 0.4
    self.anchorLeft = false
    self.anchorRight = true
    self.anchorTop = true
    self.anchorBottom = true
    self.x = self.parent.width - self.width
    self.y = padding
    self.height = self.parent.height

    self.javaObject:setX(self.x)
    self.javaObject:setY(self.y)
    self.javaObject:setHeight(self.height)
    self.javaObject:setWidth(self.width)
    self.javaObject:setAnchorLeft(self.anchorLeft)
    self.javaObject:setAnchorRight(self.anchorRight)
    self.javaObject:setAnchorTop(self.anchorTop)
    self.javaObject:setAnchorBottom(self.anchorBottom)
    self.javaObject:setScrollWithParent(false)
end

function CleanUI.ScrollBar:new(parent)
    local o = ISScrollBar:new(parent, true)
    setmetatable(o, self)
    self.__index = self

    o.anchorLeft = true
	o.anchorRight = false
	o.anchorTop = true
	o.anchorBottom = false

    o.alpha = 1.0
    o.width = math.floor(FONT_HGT_SMALL * 0.6)
    o.thumbTexture = NinePatchTexture.getSharedTexture("media/ui/CleanUI/ScrollBar/ScrollBar_V.png")
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function CleanUI.ScrollBar:render()
    local mx = self:getMouseX()
    local my = self:getMouseY()
    local mouseOver = self.scrolling or (self:isMouseOver() and self:isPointOverThumb(mx, my))
    
    local sh = self.parent:getScrollHeight()
    
    if sh > self:getHeight() then
        local del = self:getHeight() / sh
        local boxHeight = del * self:getHeight()
        boxHeight = math.ceil(boxHeight)
        boxHeight = math.max(boxHeight, 20)
        
        local dif = (self:getHeight() - boxHeight) * self.pos
        dif = math.ceil(dif)
        
        self.barwidth = self.width * 0.6
        self.barheight = boxHeight
        self.barx = (self.width - self.barwidth) / 2
        self.bary = dif

        local brightness = mouseOver and 0.8 or 0.6

        -- Resolve the texture lazily because some inventory panes can be created
        -- before the shared texture is available in B42.17. If it is still missing,
        -- draw a plain fallback scrollbar instead of throwing every render frame.
        local thumbTexture = self.thumbTexture
        if not thumbTexture then
            thumbTexture = NinePatchTexture.getSharedTexture("media/ui/CleanUI/ScrollBar/ScrollBar_V.png")
            self.thumbTexture = thumbTexture
        end

        if thumbTexture then
            thumbTexture:render(self:getAbsoluteX() + self.barx, self:getAbsoluteY(), self.barwidth, self.height, 0.1, 0.1, 0.1, 0.5)
            thumbTexture:render(self:getAbsoluteX() + self.barx, self:getAbsoluteY() + self.bary, self.barwidth, self.barheight, brightness, brightness, brightness, 0.9 * self.alpha)
        else
            self:drawRect(self.barx, 0, self.barwidth, self.height, 0.5, 0.1, 0.1, 0.1)
            self:drawRect(self.barx, self.bary, self.barwidth, self.barheight, 0.9 * self.alpha, brightness, brightness, brightness)
        end
    else
        self.barx = 0
        self.bary = 0
        self.barwidth = 0
        self.barheight = 0
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Click-to-Jump
-- ----------------------------------------------------------------------------------------------------- --
function CleanUI.ScrollBar:hitTest(x, y)
    if not self:isPointOver(self:getAbsoluteX() + x, self:getAbsoluteY() + y) then
        return nil
    end

    if self:isPointOverThumb(x, y) then
        return "thumb"
    end

    if not self.barx or (self.barwidth == 0) then
        return nil
    end

    if y < self.bary then
        return "trackUp"
    end
    return "trackDown"
end

function CleanUI.ScrollBar:onClickTrackUp(y)
    self:jumpToClickPosition(y)
end

function CleanUI.ScrollBar:onClickTrackDown(y)
    self:jumpToClickPosition(y)
end

function CleanUI.ScrollBar:jumpToClickPosition(y)
    local scrollHeight = self.parent:getScrollHeight()
    local parentHeight = self.parent:getHeight()
    if scrollHeight <= parentHeight then return end
    
    local relativePos = math.max(0, math.min(1, y / self:getHeight()))
    self.pos = relativePos
    self.parent:setYScroll(-relativePos * (scrollHeight - parentHeight))
end

return CleanUI.ScrollBar