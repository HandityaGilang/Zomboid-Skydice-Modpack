require "ISUI/ISUIElement"

PJCK_ScrollView = ISUIElement:derive("PJCK_ScrollView");
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------- --
-- 构造函数
-- ----------------------------------------- --
function PJCK_ScrollView:new(x, y, w, h)
    local o = {};
    o = ISUIElement:new(x, y, w, h);
    setmetatable(o, self);
    self.__index = self;

    o.x = x;
    o.y = y;
    o.width = w;
    o.height = h;
    
    o:setAnchorLeft(true);
    o:setAnchorRight(true);
    o:setAnchorTop(true);
    o:setAnchorBottom(true);
    o.keepOnScreen = false

    o.scrollChildren = {};
    o.lastX = 0;
    o.lastY = 0;

    o.scrollSensitivity = 32;
    o.scrollDirection = "vertical";

    o.smoothScrollX = nil               -- 当前平滑滚动X位置
    o.smoothScrollY = nil               -- 当前平滑滚动Y位置  
    o.smoothScrollTargetX = nil         -- 目标滚动X位置
    o.smoothScrollTargetY = nil         -- 目标滚动Y位置

    return o;
end

-- ----------------------------------------- --
-- 初始化函数
-- ----------------------------------------- --
function PJCK_ScrollView:createChildren()
    self:addCustomScrollBars();
end

function PJCK_ScrollView:addCustomScrollBars()
    -- 根据滚动方向创建对应的滚动条
    if self.scrollDirection == "vertical" then
        -- 创建垂直滚动条
        self.vscroll = PJCK_SimpleScrollBar:new(self, true);
        self.vscroll:initialise();
        self:addChild(self.vscroll);
    elseif self.scrollDirection == "horizontal" then
        -- 创建水平滚动条
        self.hscroll = PJCK_SimpleScrollBar:new(self, false);
        self.hscroll:initialise();
        self:addChild(self.hscroll);
    end
end

-- ----------------------------------------- --
-- 子元素管理函数
-- ----------------------------------------- --
function PJCK_ScrollView:addScrollChild(child)
    self:addChild(child);
    table.insert(self.scrollChildren, child);

    local x = self:getXScroll()
    local y = self:getYScroll()
    child:setX(child:getX() + x)
    child:setY(child:getY() + y)

    self:sendScrollbarsToFront()
end

function PJCK_ScrollView:removeScrollChild(child)
    self:removeChild(child);
    for i, v in ipairs(self.scrollChildren) do
        if v == child then
            table.remove(self.scrollChildren, i);
            return
        end
    end
end

function PJCK_ScrollView:sendScrollbarsToFront()
    if self.hscroll then
        self.hscroll:bringToTop();
    end

    if self.vscroll then
        self.vscroll:bringToTop();
    end
end

-- ----------------------------------------- --
-- 渲染函数
-- ----------------------------------------- --
function PJCK_ScrollView:prerender()
    self:updateSmoothScrolling()
    self:setStencilRect(0, 0, self.width, self.height);
    self:updateScrollbars();
    self:updateScroll();
end

function PJCK_ScrollView:render()
    self:clearStencilRect();
end

-- ----------------------------------------- --
-- 鼠标事件处理
-- ----------------------------------------- --
function PJCK_ScrollView:onMouseWheel(del)
    if self.scrollDirection == "horizontal" then
        -- 水平滚动
        local currentScroll = (self.smoothScrollTargetX and self.smoothScrollTargetX) or self:getXScroll()
        local targetScroll = currentScroll - (del * self.scrollSensitivity)
        
        -- 边界限制
        local scrollWidth = self:getScrollWidth()
        local maxScroll = math.min(0, self.width - scrollWidth)
        targetScroll = math.max(maxScroll, math.min(0, targetScroll))
        
        self.smoothScrollTargetX = targetScroll
        if not self.smoothScrollX then
            self.smoothScrollX = self:getXScroll()
        end
    else
        -- 垂直滚动
        local currentScroll = (self.smoothScrollTargetY and self.smoothScrollTargetY) or self:getYScroll()
        local targetScroll = currentScroll - (del * self.scrollSensitivity)
        
        -- 边界限制
        local scrollHeight = self:getScrollHeight()
        local maxScroll = math.min(0, self.height - scrollHeight)
        targetScroll = math.max(maxScroll, math.min(0, targetScroll))
        
        self.smoothScrollTargetY = targetScroll
        if not self.smoothScrollY then
            self.smoothScrollY = self:getYScroll()
        end
    end
    return true
end

function PJCK_ScrollView:updateSmoothScrolling()
    local frameRateFrac = UIManager.getMillisSinceLastRender() / 33.3
    
    -- 垂直平滑滚动
    if self.smoothScrollTargetY then
        if not self.smoothScrollY then 
            self.smoothScrollY = self:getYScroll()
        end
        
        local dy = self.smoothScrollTargetY - self.smoothScrollY
        local moveAmount = dy * math.min(0.5, 0.25 * frameRateFrac)
        
        if frameRateFrac > 1 then
            moveAmount = dy * math.min(1.0, math.min(0.5, 0.25 * frameRateFrac) * frameRateFrac)
        end
        
        local targetY = self.smoothScrollY + moveAmount
        
        if math.abs(targetY - self.smoothScrollY) > 0.1 then
            self:setYScroll(targetY)
            self.smoothScrollY = targetY
        else
            self:setYScroll(self.smoothScrollTargetY)
            self.smoothScrollTargetY = nil
            self.smoothScrollY = nil
        end
    end
    
    -- 水平平滑滚动
    if self.smoothScrollTargetX then
        if not self.smoothScrollX then 
            self.smoothScrollX = self:getXScroll()
        end
        
        local dx = self.smoothScrollTargetX - self.smoothScrollX
        local moveAmount = dx * math.min(0.5, 0.25 * frameRateFrac)
        
        if frameRateFrac > 1 then
            moveAmount = dx * math.min(1.0, math.min(0.5, 0.25 * frameRateFrac) * frameRateFrac)
        end
        
        local targetX = self.smoothScrollX + moveAmount
        
        if math.abs(targetX - self.smoothScrollX) > 0.1 then
            self:setXScroll(targetX)
            self.smoothScrollX = targetX
        else
            self:setXScroll(self.smoothScrollTargetX)
            self.smoothScrollTargetX = nil
            self.smoothScrollX = nil
        end
    end
end

-- ----------------------------------------- --
-- 滚动灵敏度设置方法
-- ----------------------------------------- --
function PJCK_ScrollView:setScrollSensitivity(sensitivity)
    if sensitivity and sensitivity > 0 then
        self.scrollSensitivity = sensitivity;
    end
end

function PJCK_ScrollView:getScrollSensitivity()
    return self.scrollSensitivity;
end

-- ----------------------------------------- --
-- 滚动方向与滚动条控制
-- ----------------------------------------- --
function PJCK_ScrollView:setScrollDirection(direction)
    if direction == "horizontal" or direction == "vertical" then
        local oldDirection = self.scrollDirection
        self.scrollDirection = direction;
        
        if oldDirection ~= direction and (self.vscroll or self.hscroll) then
            self:recreateScrollBars()
        end
    end
end

function PJCK_ScrollView:recreateScrollBars()
    -- 移除现有滚动条
    if self.vscroll then
        self:removeChild(self.vscroll)
        self.vscroll = nil
    end
    if self.hscroll then
        self:removeChild(self.hscroll)
        self.hscroll = nil
    end
    
    -- 重新创建滚动条
    self:addCustomScrollBars()
end

function PJCK_ScrollView:updateScrollbars()
    local sw = self:getScrollWidth() or 1
    local sh = self:getScrollHeight() or 1

    local margin = FONT_HGT_SMALL*0.2
    
    -- 根据滚动方向更新对应的滚动条
    if self.scrollDirection == "vertical" then
        -- 仅垂直滚动
        if self.vscroll then
            local needVScroll = sh > self.height
            self.vscroll:setHeight(self.height - margin * 2)
            self.vscroll:setX(self.width - self.vscroll.width)
            self.vscroll:setY(margin)
            self.vscroll:setVisible(needVScroll)
        end
        
    elseif self.scrollDirection == "horizontal" then
        -- 仅水平滚动
        if self.hscroll then
            local needHScroll = sw > self.width
            self.hscroll:setWidth(self.width - margin * 2)
            self.hscroll:setX(margin)
            self.hscroll:setY(self.height - self.hscroll.height)
            self.hscroll:setVisible(needHScroll)
        end
    end
end

-- ----------------------------------------- --
-- 滚动逻辑
-- ----------------------------------------- --
function PJCK_ScrollView:updateScroll()
    local xScroll = self:getXScroll()
    local yScroll = self:getYScroll()

    local scrollAreaWidth = self:getScrollWidth()
    local scrollAreaHeight = self:getScrollHeight()

    if self.scrollDirection == "horizontal" then
        -- 水平滚动
        if scrollAreaWidth > self.width then
            if xScroll > 0 then xScroll = 0 end
            if xScroll < -(scrollAreaWidth - self.width) then
                xScroll = -(scrollAreaWidth - self.width)
            end
            self:setXScroll(xScroll)
        else
            self:setXScroll(0)
        end
        self:setYScroll(0)
        
    else
        -- 垂直滚动
        if scrollAreaHeight > self.height then
            if yScroll > 0 then yScroll = 0 end
            local maxNegativeScroll = -(scrollAreaHeight - self.height)
            if yScroll < maxNegativeScroll then
                yScroll = maxNegativeScroll
            end
            self:setYScroll(yScroll)
        else
            self:setYScroll(0)
        end
        self:setXScroll(0)
    end

    -- 更新子元素位置
    local deltaX = self:getXScroll() - self.lastX
    local deltaY = self:getYScroll() - self.lastY
    for _, child in pairs(self.scrollChildren) do
        child:setX(child:getX() + deltaX)
        child:setY(child:getY() + deltaY)
    end

    self.lastX = self:getXScroll()
    self.lastY = self:getYScroll()
    
    -- 根据滚动方向更新滚动条位置
    if self.scrollDirection == "vertical" then
        if self.vscroll then
            if scrollAreaHeight <= self.height then
                self.vscroll.pos = 0
            else
                self.vscroll.pos = (-self:getYScroll()) / (scrollAreaHeight - self.height)
            end
        end
    elseif self.scrollDirection == "horizontal" then
        if self.hscroll then
            if scrollAreaWidth <= self.width then
                self.hscroll.pos = 0
            else
                self.hscroll.pos = (-self:getXScroll()) / (scrollAreaWidth - self.width)
            end
        end
    end
end

-- ----------------------------------------- --
-- 滚动辅助函数
-- ----------------------------------------- --
function PJCK_ScrollView:resetScroll()
    self.smoothScrollX = nil
    self.smoothScrollY = nil
    self.smoothScrollTargetX = nil
    self.smoothScrollTargetY = nil

    self:setXScroll(0);
    self:setYScroll(0);
    self:updateScroll();
end
-- ----------------------------------------- --
-- 滚动区域尺寸计算
-- ----------------------------------------- --
function PJCK_ScrollView:getScrollWidth()
    if self.scrollwidth then
        return self.scrollwidth
    end
    
    local width = 0
    for _, child in pairs(self.scrollChildren) do
        width = math.max(width, child:getX() + child:getWidth())
    end
    return width
end

function PJCK_ScrollView:getScrollHeight()
    if self.scrollheight then
        return self.scrollheight
    end
    
    local height = 0
    for _, child in pairs(self.scrollChildren) do
        height = math.max(height, child:getY() + child:getHeight())
    end
    return height
end

function PJCK_ScrollView:setScrollWidth(width)
    self.scrollwidth = width
end

function PJCK_ScrollView:setScrollHeight(height)
    self.scrollheight = height
end

return PJCK_ScrollView