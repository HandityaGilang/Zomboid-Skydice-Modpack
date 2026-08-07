require "ISUI/ISUIElement"

PJCK_VirtualScrollView = ISUIElement:derive("PJCK_VirtualScrollView")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------- --
-- 构造函数
-- ----------------------------------------- --
function PJCK_VirtualScrollView:new(x, y, w, h)
    local o = ISUIElement:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    o.x = x
    o.y = y
    o.width = w
    o.height = h
    
    o:setAnchorLeft(true)
    o:setAnchorRight(true)
    o:setAnchorTop(true)
    o:setAnchorBottom(true)

    -- 核心配置
    o.dataSource = {}           -- 数据源
    o.itemHeight = 50           -- 每个项目的高度
    o.padding = 5               -- 内边距
    
    -- 对象池
    o.itemPool = {}             -- 项目对象池
    o.poolSize = 0             -- 池大小
    o.autoPoolSize = true      -- 是否自动计算池大小
    o.poolSizeBuffer = 1.5     -- 池大小缓冲倍数
    o.visibleStartIndex = 1     -- 可见开始索引
    o.visibleEndIndex = 1       -- 可见结束索引
    
    -- 滚动相关
    o.scrollOffset = 0          -- 当前滚动偏移
    o.totalHeight = 0           -- 总内容高度
    o.maxScrollOffset = 0       -- 最大滚动偏移
    
    -- 平滑滚动
    o.smoothScrollY = nil               -- scroll (当前平滑滚动位置)
    o.smoothScrollTargetY = nil         -- smooth scroll to target(目标滚动位置)
    
    -- 回调函数
    o.onCreateItem = nil        -- Create UIElement（创建项目回调）: function(index) return itemObject end
    o.onUpdateItem = nil        -- Update when index change(更新项目回调): function(itemObject, data) end
    
    return o
end

-- ----------------------------------------- --
-- 初始化
-- ----------------------------------------- --
function PJCK_VirtualScrollView:createChildren()
    self:addScrollBar()
    self:initializePool()
end

function PJCK_VirtualScrollView:addScrollBar()
    self.vscroll = PJCK_SimpleScrollBar:new(self, true)
    self.vscroll:initialise()
    self:addChild(self.vscroll)
end

-- ----------------------------------------- --
-- 配置函数
-- ----------------------------------------- --
function PJCK_VirtualScrollView:setDataSource(dataSource, forceRefresh)
    self.dataSource = dataSource or {}
    self:updateScrollMetrics()
    
    -- 如果强制刷新，重置可见范围强制更新
    if forceRefresh then
        self.visibleStartIndex = -1
        self.visibleEndIndex = -1
    end
    
    self:refreshItems()
end

function PJCK_VirtualScrollView:getDataCount()
    return #self.dataSource
end

function PJCK_VirtualScrollView:setConfig(itemHeight, padding)
    self.itemHeight = itemHeight
    self.padding = padding

    if self.autoPoolSize then
        self.poolSize = self:calculateAutoPoolSize()
        self:initializePool()
    end

    self:updateScrollMetrics()
    self:refreshItems()
end

function PJCK_VirtualScrollView:setOnCreateItem(callback)
    self.onCreateItem = callback
    self:initializePool()
end

function PJCK_VirtualScrollView:setOnUpdateItem(callback)
    self.onUpdateItem = callback
end

-- ----------------------------------------- --
-- 对象池管理
-- ----------------------------------------- --
function PJCK_VirtualScrollView:setPoolSize(size)
    if size and size > 0 then
        self.poolSize = size
        self.autoPoolSize = false
    else
        self.autoPoolSize = true
        self.poolSize = self:calculateAutoPoolSize()
    end
    self:initializePool()
end

-- 设置池大小缓冲倍数
function PJCK_VirtualScrollView:setPoolSizeBuffer(buffer)
    self.poolSizeBuffer = buffer or 1.5
    if self.autoPoolSize then
        self.poolSize = self:calculateAutoPoolSize()
        self:initializePool()
    end
end

function PJCK_VirtualScrollView:calculateAutoPoolSize()
    if self.itemHeight <= 0 or self.height <= 0 then
        return 10
    end

    local visibleItemCount = math.ceil(self.height / self.itemHeight)

    local poolSize = math.ceil(visibleItemCount * self.poolSizeBuffer)
    print("Calculated pool size:", poolSize)

    local minPoolSize = 3
    local maxPoolSize = 50
    
    return math.max(minPoolSize, math.min(maxPoolSize, poolSize))
end

function PJCK_VirtualScrollView:initializePool()
    for _, item in ipairs(self.itemPool) do
        if item and item.removeFromUIManager then
            self:removeChild(item)
        end
    end
    
    self.itemPool = {}
    
    if not self.onCreateItem then return end
    
    if self.autoPoolSize and self.poolSize == 0 then
        self.poolSize = self:calculateAutoPoolSize()
    end

    for i = 1, self.poolSize do
        local item = self.onCreateItem(i)
        if item then
            item:initialise()
            item:setVisible(false)
            self:addChild(item)
            table.insert(self.itemPool, item)
        end
    end
    
    self:refreshItems()
end

-- ----------------------------------------- --
-- 滚动计算
-- ----------------------------------------- --
function PJCK_VirtualScrollView:updateScrollMetrics()
    local dataCount = self:getDataCount()

    self.totalHeight = dataCount * self.itemHeight + self.padding * 2
    if dataCount == 0 then
        self.maxScrollOffset = 0
    else
        local lastItemBottom = self.padding + dataCount * self.itemHeight
        self.maxScrollOffset = math.max(0, lastItemBottom - self.height)
    end
    
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScrollOffset))
end

function PJCK_VirtualScrollView:calculateVisibleRange()
    if self:getDataCount() == 0 then
        return 1, 0
    end
    
    local startY = self.scrollOffset
    local endY = startY + self.height
    
    local startIndex = math.max(1, math.ceil(startY / self.itemHeight))
    local endIndex = math.min(self:getDataCount(), math.floor(endY / self.itemHeight) + 1)
    
    local bufferSize = 1
    startIndex = math.max(1, startIndex - bufferSize)
    endIndex = math.min(self:getDataCount(), endIndex + bufferSize)
    --print("startIndex: "..startIndex.." endIndex: ".. endIndex)
    
    return startIndex, endIndex
end

-- ----------------------------------------- --
-- 项目更新
-- ----------------------------------------- --
function PJCK_VirtualScrollView:refreshItems()
    if not self.onUpdateItem or #self.itemPool == 0 then
        return
    end
    
    local startIndex, endIndex = self:calculateVisibleRange()
    local needReassignData = startIndex ~= self.visibleStartIndex or endIndex ~= self.visibleEndIndex
    
    self.visibleStartIndex = startIndex
    self.visibleEndIndex = endIndex
    
    if needReassignData then
        for _, item in ipairs(self.itemPool) do
            item:setVisible(false)
        end
    end
    
    local poolIndex = 1
    for dataIndex = startIndex, endIndex do
        if poolIndex > #self.itemPool then
            break
        end
        
        if dataIndex <= self:getDataCount() then
            local item = self.itemPool[poolIndex]
            local data = self.dataSource[dataIndex]
            
            if needReassignData then
                self.onUpdateItem(item, data)
                item:setVisible(true)
            end
            
            local itemY = self.padding + (dataIndex - 1) * self.itemHeight - self.scrollOffset
            item:setY(itemY)
            
            poolIndex = poolIndex + 1
        end
    end
end

-- ----------------------------------------- --
-- 滚动控制
-- ----------------------------------------- --
-- 平滑滚动实现
function PJCK_VirtualScrollView:updateSmoothScrolling()
    if not self.smoothScrollTargetY then return end
    
    if not self.smoothScrollY then 
        self.smoothScrollY = -self.scrollOffset
    end
    
    local dy = self.smoothScrollTargetY - self.smoothScrollY
    local maxYScroll = self.maxScrollOffset
    
    local frameRateFrac = UIManager.getMillisSinceLastRender() / 33.3
    local itemHeightFrac = 160 / self.itemHeight
    local moveAmount = dy * math.min(0.5, 0.25 * frameRateFrac * itemHeightFrac)
    
    if frameRateFrac > 1 then
        moveAmount = dy * math.min(1.0, math.min(0.5, 0.25 * frameRateFrac * itemHeightFrac) * frameRateFrac)
    end
    
    local targetY = self.smoothScrollY + moveAmount
    if targetY > 0 then targetY = 0 end
    if targetY < -maxYScroll then targetY = -maxYScroll end
    
    if math.abs(targetY - self.smoothScrollY) > 0.1 then
        self:setScrollOffsetDirect(-targetY)
        self.smoothScrollY = targetY
    else
        self:setScrollOffsetDirect(-self.smoothScrollTargetY)
        self.smoothScrollTargetY = nil
        self.smoothScrollY = nil
    end
end


-- 设置滚动方向
function PJCK_VirtualScrollView:setScrollOffsetDirect(offset)
    local oldOffset = self.scrollOffset
    self.scrollOffset = math.max(0, math.min(offset, self.maxScrollOffset))
    
    if oldOffset ~= self.scrollOffset then
        self:refreshItems()
        self:updateScrollBar()
    end
end

-- 更新滚动条
function PJCK_VirtualScrollView:updateScrollBar()
    if not self.vscroll then return end
    local margin = FONT_HGT_SMALL*0.2

    self.vscroll:setHeight(self.height - margin * 2)
    self.vscroll:setX(self.width - self.vscroll.width)
    self.vscroll:setY(margin)
    
    if self.maxScrollOffset <= 0 then
        self.vscroll.pos = 0
        self.vscroll:setVisible(false)
    else
        self.vscroll.pos = self.scrollOffset / self.maxScrollOffset
        self.vscroll:setVisible(true)
    end
end

-- ----------------------------------------- --
-- 鼠标滚轮
-- ----------------------------------------- --
function PJCK_VirtualScrollView:onMouseWheel(del)
    local maxScroll = self.maxScrollOffset
    
    -- 基于目标位置计算，连续滚动
    local baseScroll = (self.smoothScrollTargetY and -self.smoothScrollTargetY) or self.scrollOffset
    local currentItemIndex = baseScroll / self.itemHeight
    
    local targetItemIndex
    if del < 0 then
        targetItemIndex = math.floor(currentItemIndex)
        if math.abs(currentItemIndex - targetItemIndex) < 0.01 then
            targetItemIndex = targetItemIndex - 1
        end
    else
        targetItemIndex = math.ceil(currentItemIndex)
        if math.abs(currentItemIndex - targetItemIndex) < 0.01 then
            targetItemIndex = targetItemIndex + 1
        end
    end

    targetItemIndex = math.max(0, targetItemIndex)
    local targetScroll = math.min(targetItemIndex * self.itemHeight, maxScroll)
    
    self.smoothScrollTargetY = -targetScroll
    if not self.smoothScrollY then
        self.smoothScrollY = -self.scrollOffset
    end
    return true
end

-- ----------------------------------------- --
-- 渲染
-- ----------------------------------------- --
function PJCK_VirtualScrollView:prerender()
    self:setStencilRect(0, 0, self.width, self.height)
    self:updateSmoothScrolling()
    self:updateScrollBar()
end

function PJCK_VirtualScrollView:render()
    self:clearStencilRect()
end

function PJCK_VirtualScrollView:update()
    ISUIElement.update(self)
end

-- ----------------------------------------- --
-- ScrollBar接口
-- ----------------------------------------- --
function PJCK_VirtualScrollView:getScrollHeight()
    return self.totalHeight
end

function PJCK_VirtualScrollView:getYScroll()
    return -self.scrollOffset
end

function PJCK_VirtualScrollView:setYScroll(yScroll)
    self.smoothScrollTargetY = nil
    self.smoothScrollY = nil
    self:setScrollOffsetDirect(-yScroll)
end

return PJCK_VirtualScrollView