require "ISUI/ISScrollBar"

-- ----------------------------------------- --
-- 自定义滚动条类定义
-- ----------------------------------------- --
PJCK_SimpleScrollBar = ISScrollBar:derive("PJCK_SimpleScrollBar")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------- --
-- 初始化与构造函数
-- ----------------------------------------- --
function PJCK_SimpleScrollBar:instantiate()
    self.javaObject = UIElement.new(self);
    
    if self.vertical then
        self.anchorLeft = false;
        self.anchorRight = true;
        self.anchorBottom = true;
        self.x = self.parent.width - self.width;
        self.y = 0;
        self.width = self.width;
        self.height = self.parent.height;
    else
        self.anchorTop = false
        self.anchorRight = true
        self.anchorBottom = true
        self.x = 0
        self.y = self.parent.height - self.height
        self.width = self.parent.width - (self.parent.vscroll and (self.parent.vscroll.width or 13) or 0)
        self.height = self.height
    end

    self.javaObject:setX(self.x);
    self.javaObject:setY(self.y);
    self.javaObject:setHeight(self.height);
    self.javaObject:setWidth(self.width);
    self.javaObject:setAnchorLeft(self.anchorLeft);
    self.javaObject:setAnchorRight(self.anchorRight);
    self.javaObject:setAnchorTop(self.anchorTop);
    self.javaObject:setAnchorBottom(self.anchorBottom);
    self.javaObject:setScrollWithParent(false);
end

function PJCK_SimpleScrollBar:new(parent, vertical)
    local o = {}
    o = ISScrollBar:new(parent, vertical)
    setmetatable(o, self)
    self.__index = self
    
    -- 设置样式
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0.0}

    o.uptex = nil
    o.downtex = nil
    o.toptex = nil
    o.midtex = nil
    o.bottex = nil
    
    -- 垂直模式贴图与宽度
    if vertical then
        o.width = FONT_HGT_SMALL*0.6
        o.thumbNormalTextures = {
            top = getTexture("media/ui/Project_Cook/ScrollBar/ScrollBar_V_T.png"),
            middle = getTexture("media/ui/Project_Cook/ScrollBar/ScrollBar_V_M.png"),
            bottom = getTexture("media/ui/Project_Cook/ScrollBar/ScrollBar_V_B.png")
        }
    else
    -- 水平模式贴图与宽度
        o.height = FONT_HGT_SMALL*0.6
        o.thumbHorizontalTextures = {
            left = getTexture("media/ui/Project_Cook/ScrollBar/ScrollBar_H_L.png"),
            middle = getTexture("media/ui/Project_Cook/ScrollBar/ScrollBar_H_M.png"),
            right = getTexture("media/ui/Project_Cook/ScrollBar/ScrollBar_H_R.png")
        }
    end
    
    return o
end

-- ----------------------------------------- --
-- 渲染函数
-- ----------------------------------------- --
function PJCK_SimpleScrollBar:render()
    local mx = self:getMouseX()
    local my = self:getMouseY()
    local mouseOver = self.scrolling or (self:isMouseOver() and self:isPointOverThumb(mx, my))
    
    -- 垂直滚动条
    if self.vertical then
        local sh = self.parent:getScrollHeight()
        
        if(sh > self:getHeight()) then
            local del = self:getHeight() / sh
            local boxheight = del * self:getHeight()
            boxheight = math.ceil(boxheight)
            boxheight = math.max(boxheight, 20)
            
            local dif = (self:getHeight() - boxheight) * self.pos
            dif = math.ceil(dif)
            
            self.barx = 0
            self.bary = dif
            self.barwidth = self.width
            self.barheight = boxheight
            
            -- 绘制垂直滑块
            if self.thumbNormalTextures and self.thumbNormalTextures.top then
                local brightness = mouseOver and 1.0 or 0.8
                self:drawVerticalThumb(
                    self.barx, self.bary,
                    self.barwidth, self.barheight,
                    self.thumbNormalTextures.top,
                    self.thumbNormalTextures.middle,
                    self.thumbNormalTextures.bottom,
                    0.8, brightness, brightness, brightness
                )
            end
        else
            self.barx = 0
            self.bary = 0
            self.barwidth = 0
            self.barheight = 0
        end
    else
        -- 水平滚动条
        local sw = self.parent:getScrollWidth()
        
        if(sw > self:getWidth()) then
            local del = self:getWidth() / sw
            local boxwidth = del * self:getWidth()
            boxwidth = math.ceil(boxwidth)
            boxwidth = math.max(boxwidth, 20)
            
            local dif = (self:getWidth() - boxwidth) * self.pos
            dif = math.ceil(dif)
            
            self.barx = dif
            self.bary = 0
            self.barwidth = boxwidth
            self.barheight = self.height
            
            -- 绘制水平滑块
            if self.thumbHorizontalTextures and self.thumbHorizontalTextures.left then
                local brightness = mouseOver and 1.0 or 0.8
                self:drawHorizontalThumb(
                    self.barx, self.bary,
                    self.barwidth, self.barheight,
                    self.thumbHorizontalTextures.left,
                    self.thumbHorizontalTextures.middle,
                    self.thumbHorizontalTextures.right,
                    0.8, brightness, brightness, brightness
                )
            end
        else
            self.barx = 0
            self.bary = 0
            self.barwidth = 0
            self.barheight = 0
        end
    end
end

-- ----------------------------------------- --
-- 垂直滑块绘制函数
-- ----------------------------------------- --
function PJCK_SimpleScrollBar:drawVerticalThumb(x, y, width, height, topTexture, middleTexture, bottomTexture, alpha, r, g, b)
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    -- 获取上下贴图的原始尺寸
    local topOriginalWidth = topTexture:getWidth()
    local topOriginalHeight = topTexture:getHeight()
    local bottomOriginalWidth = bottomTexture:getWidth()
    local bottomOriginalHeight = bottomTexture:getHeight()
    
    -- 计算等比缩放后的上下高度
    local widthRatio = width / topOriginalWidth
    local topActualHeight = math.floor(topOriginalHeight * widthRatio)
    
    widthRatio = width / bottomOriginalWidth
    local bottomActualHeight = math.floor(bottomOriginalHeight * widthRatio)
    
    local minHeight = topActualHeight + bottomActualHeight
    
    -- 如果总高度不够绘制上下两端，按比例缩放上下端
    if height <= minHeight then
        local topRatio = topActualHeight / minHeight
        topActualHeight = math.floor(height * topRatio)
        bottomActualHeight = height - topActualHeight

        self:drawTextureScaled(topTexture, x, y, width, topActualHeight, alpha, r, g, b)
        if bottomActualHeight > 0 then
            self:drawTextureScaled(bottomTexture, x, y + topActualHeight, width, bottomActualHeight, alpha, r, g, b)
        end
    else
        local middleHeight = height - topActualHeight - bottomActualHeight

        self:drawTextureScaled(topTexture, x, y, width, topActualHeight, alpha, r, g, b)
        if middleHeight > 0 and middleTexture then
            self:drawTextureScaled(middleTexture, x, y + topActualHeight, width, middleHeight, alpha, r, g, b)
        end
        self:drawTextureScaled(bottomTexture, x, y + topActualHeight + middleHeight, width, bottomActualHeight, alpha, r, g, b)
    end
end

-- ----------------------------------------- --
-- 水平滑块绘制函数
-- ----------------------------------------- --
function PJCK_SimpleScrollBar:drawHorizontalThumb(x, y, width, height, leftTexture, middleTexture, rightTexture, alpha, r, g, b)
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    -- 获取左右贴图的原始尺寸
    local leftOriginalWidth = leftTexture:getWidth()
    local leftOriginalHeight = leftTexture:getHeight()
    local rightOriginalWidth = rightTexture:getWidth()
    local rightOriginalHeight = rightTexture:getHeight()
    
    -- 计算等比缩放后的左右宽度
    local heightRatio = height / leftOriginalHeight
    local leftActualWidth = math.floor(leftOriginalWidth * heightRatio)
    
    heightRatio = height / rightOriginalHeight
    local rightActualWidth = math.floor(rightOriginalWidth * heightRatio)
    
    local minWidth = leftActualWidth + rightActualWidth
    
    -- 如果总宽度不够绘制左右两端，按比例缩放左右端
    if width <= minWidth then
        local leftRatio = leftActualWidth / minWidth
        leftActualWidth = math.floor(width * leftRatio)
        rightActualWidth = width - leftActualWidth

        self:drawTextureScaled(leftTexture, x, y, leftActualWidth, height, alpha, r, g, b)
        if rightActualWidth > 0 then
            self:drawTextureScaled(rightTexture, x + leftActualWidth, y, rightActualWidth, height, alpha, r, g, b)
        end
    else
        local middleWidth = width - leftActualWidth - rightActualWidth

        self:drawTextureScaled(leftTexture, x, y, leftActualWidth, height, alpha, r, g, b)
        if middleWidth > 0 and middleTexture then
            self:drawTextureScaled(middleTexture, x + leftActualWidth, y, middleWidth, height, alpha, r, g, b)
        end
        self:drawTextureScaled(rightTexture, x + leftActualWidth + middleWidth, y, rightActualWidth, height, alpha, r, g, b)
    end
end
-- ----------------------------------------- --
-- 轨道点击处理
-- ----------------------------------------- --
function PJCK_SimpleScrollBar:hitTest(x, y)
    if not self:isPointOver(self:getAbsoluteX() + x, self:getAbsoluteY() + y) then
        return nil
    end
    
    -- 检测是否点击滑块
    if self:isPointOverThumb(x, y) then
        return "thumb"
    end
    
    -- 滑块不存在或宽度为0时不进行进一步检测
    if not self.barx or (self.barwidth == 0) then
        return nil
    end
    
    -- 垂直滚动条轨道检测
    if self.vertical then
        if y < self.bary then
            return "trackUp"
        end
        return "trackDown"
    else
        -- 水平滚动条轨道检测
        if x < self.barx then
            return "trackLeft"
        end
        return "trackRight"
    end
end

function PJCK_SimpleScrollBar:onClickTrackUp(y)
    self:jumpToClickPosition(nil, y)
end

function PJCK_SimpleScrollBar:onClickTrackDown(y)
    self:jumpToClickPosition(nil, y)
end

function PJCK_SimpleScrollBar:onClickTrackLeft(x)
    self:jumpToClickPosition(x, nil)
end

function PJCK_SimpleScrollBar:onClickTrackRight(x)
    self:jumpToClickPosition(x, nil)
end

-- 跳转滚动条
function PJCK_SimpleScrollBar:jumpToClickPosition(x, y)
    if self.vertical and y then
        -- 垂直滚动条
        local scrollHeight = self.parent:getScrollHeight()
        local parentHeight = self.parent:getHeight()
        if scrollHeight <= parentHeight then return end
        
        local relativePos = math.max(0, math.min(1, y / self:getHeight()))
        self.pos = relativePos
        self.parent:setYScroll(-relativePos * (scrollHeight - parentHeight))
        
    elseif not self.vertical and x then
        -- 水平滚动条
        local scrollWidth = self.parent:getScrollWidth()
        local parentWidth = self.parent:getWidth()
        if scrollWidth <= parentWidth then return end
        
        local relativePos = math.max(0, math.min(1, x / self:getWidth()))
        self.pos = relativePos
        self.parent:setXScroll(-relativePos * (scrollWidth - parentWidth))
    end
end

return PJCK_SimpleScrollBar