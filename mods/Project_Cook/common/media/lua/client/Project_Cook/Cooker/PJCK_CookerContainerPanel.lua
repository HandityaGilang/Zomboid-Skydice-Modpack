require "ISUI/ISPanel"

PJCK_CookerContainerPanel = ISPanel:derive("PJCK_CookerContainerPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_CookerContainerPanel:initialise()
    ISPanel.initialise(self)
end

function PJCK_CookerContainerPanel:new(x, y, width, height, CookerPanel)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.CookerPanel = CookerPanel
    o.player = CookerPanel.player
    o.selectedCooker = nil
    o.lastCookerSize = 0
    
    -- 槽位参数设置
    o.slotSize = math.floor(FONT_HGT_SMALL * 2.5)
    o.slotSpacing = math.floor(o.slotSize / 4)
    o.verticalSpacing = math.floor(o.slotSize/1.5)
    
    -- 计算每行可容纳的物品数量
    local availableWidth = width - o.slotSpacing * 2
    o.itemsPerRow = math.floor(availableWidth / (o.slotSize + o.slotSpacing))
    o.itemsPerRow = math.max(1, o.itemsPerRow)
    
    -- 食物槽位数组
    o.foodSlots = {}
    o.allFoodItems = {}
    
    -- 添加图标和按钮纹理
    o.NoItemIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Search.png")
    o.NoContainerIcon = getTexture("media/ui/Project_Cook/ICON/icon_Query.png")
    
    o.buttonTextures = {
        left = getTexture("media/ui/Project_Cook/Button/Button_BG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Button/Button_BG_M.png"),
        right = getTexture("media/ui/Project_Cook/Button/Button_BG_R.png")
    }
    
    return o
end

-- ---------------------------------------------------------- --
-- 创建子元素
-- ---------------------------------------------------------- --

function PJCK_CookerContainerPanel:createChildren()
    local titleHeight = FONT_HGT_MEDIUM * 1.2
    local padding = FONT_HGT_SMALL * 0.4
    
    -- 创建标题栏
    self.titleBar = ISPanel:new(0, 0, self.width, titleHeight)
    self.titleBar:initialise()
    self.titleBar.backgroundColor.a = 0
    self.titleBar.borderColor.a = 0
    self:addChild(self.titleBar)
    
    -- 标题文本
    local titleTextY = (titleHeight - FONT_HGT_SMALL) / 2
    local containerLabel = ISLabel:new(padding, titleTextY, FONT_HGT_SMALL, 
                                     getText("IGUI_PJCK_CookerContainer"), 1, 1, 1, 1, UIFont.Small, true)
    containerLabel:initialise()
    self.titleBar:addChild(containerLabel)
    self.containerLabel = containerLabel

    self.capacityLabel = ISLabel:new(self.width - padding, titleTextY, FONT_HGT_SMALL, 
                                "", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.capacityLabel:initialise()
    self.titleBar:addChild(self.capacityLabel)
    
    -- 创建滚动视图
    local contentY = titleHeight
    local contentHeight = self.height - contentY
    
    self.scrollView = PJCK_ScrollView:new(0, contentY, self.width, contentHeight)
    self.scrollView:initialise()
    self.scrollView:setScrollDirection("vertical")
    self.scrollView:setScrollSensitivity(self.slotSize + self.slotSpacing)
    self:addChild(self.scrollView)
    self.scrollView:setWantKeyEvents(true)
    self.titleHeight = titleHeight
    self.contentY = contentY
    
    -- 初始更新显示
    self:updateDisplay()
end

-- ---------------------------------------------------------- --
-- 烹饪器相关方法
-- ---------------------------------------------------------- --

function PJCK_CookerContainerPanel:setCooker(cooker)
    self.selectedCooker = cooker

    if cooker then
        local cookerItems = cooker:getItems()
        self.lastCookerSize = cookerItems and cookerItems:size() or 0
    else
        self.lastCookerSize = 0
    end
    
    self:updateDisplay()
    self:updateCapacityDisplay()
end


function PJCK_CookerContainerPanel:getCooker()
    return self.selectedCooker
end

-- ---------------------------------------------------------- --
-- 数据获取与处理
-- ---------------------------------------------------------- --

-- 获取烹饪器内的所有食物物品
function PJCK_CookerContainerPanel:getAllFoodItems()
    local foodItems = {}
    
    if not self.selectedCooker then
        return foodItems
    end
    
    local cookerItems = self.selectedCooker:getItems()
    if not cookerItems then
        return foodItems
    end
    
    -- 按名称分组食物物品
    local itemsByName = {}
    
    for i = 0, cookerItems:size() - 1 do
        local item = cookerItems:get(i)
        if self:isFoodItem(item) then
            local itemName = item:getName()
            if not itemsByName[itemName] then
                itemsByName[itemName] = {
                    item = item,
                    count = 1
                }
            else
                itemsByName[itemName].count = itemsByName[itemName].count + 1
                
                -- 选择状态更好的物品作为代表
                if self:getItemQuality(item) > self:getItemQuality(itemsByName[itemName].item) then
                    itemsByName[itemName].item = item
                end
            end
        end
    end
    
    -- 转换为数组并排序
    for _, itemGroup in pairs(itemsByName) do
        table.insert(foodItems, itemGroup)
    end
    
    -- 按名称排序
    table.sort(foodItems, function(a, b)
        return a.item:getName() < b.item:getName()
    end)
    
    return foodItems
end

-- 判断是否为食物物品
function PJCK_CookerContainerPanel:isFoodItem(item)
    if not item then return false end

    if instanceof(item, "Food") then
        return true
    end

    if item:getFluidContainer() and item:getFluidContainer():getAmount() > 0 then
        return true
    end
    
    return false
end

-- 获取物品品质评分
function PJCK_CookerContainerPanel:getItemQuality(item)
    local quality = 0
    
    if instanceof(item, "Food") then
        -- 新鲜度评分
        if item:isFresh() then
            quality = quality + 100
        elseif not item:isRotten() then
            quality = quality + 50
        end
        
        -- 重量评分
        local actualWeight = item:getActualWeight()
        local maxWeight = item:getScriptItem():getActualWeight()
        if maxWeight > 0 then
            quality = quality + (actualWeight / maxWeight) * 50
        end
    elseif item:IsDrainable() then
        -- 剩余用量评分
        quality = quality + item:getCurrentUsesFloat() * 100
    else
        quality = 100
    end
    
    return quality
end

function PJCK_CookerContainerPanel:getCookerCapacityInfo()
    if not self.selectedCooker then
        return 0, 0
    end
    
    local playerObj = self.player
    local currentWeight = 0
    local maxCapacity = 0
    
    -- 使用与ISInventoryPage相同的方法获取容量
    maxCapacity = self.selectedCooker:getEffectiveCapacity(playerObj)
    
    -- 获取当前重量（使用与ISInventoryPage相同的方法）
    currentWeight = self.selectedCooker:getCapacityWeight()
    
    return currentWeight, maxCapacity
end

-- 更新容量显示
function PJCK_CookerContainerPanel:updateCapacityDisplay()
    if not self.capacityLabel then return end
    
    if not self.selectedCooker then
        self.capacityLabel:setName("")
        return
    end
    
    local currentWeight, maxCapacity = self:getCookerCapacityInfo()
    
    -- 四舍五入到两位小数，与原版保持一致
    local roundedWeight = round(currentWeight, 2)
    local capacityText = roundedWeight .. "/" .. maxCapacity
    
    -- 更新文本和位置
    self.capacityLabel:setName(capacityText)
    local textWidth = getTextManager():MeasureStringX(UIFont.Small, capacityText)
    local padding = FONT_HGT_SMALL * 0.4
    self.capacityLabel:setX(self.width - textWidth - padding)
end
-- ---------------------------------------------------------- --
-- UI更新
-- ---------------------------------------------------------- --

-- 更新显示内容
function PJCK_CookerContainerPanel:updateDisplay()
    -- 更新标题文本
    if self.selectedCooker then
        -- 更新食物列表
        self:updateFoodList()
        self:updateCapacityDisplay()
    else
        -- 清除现有槽位
        self:clearFoodSlots()
        self:updateCapacityDisplay()
    end
end

-- 清除食物槽位
function PJCK_CookerContainerPanel:clearFoodSlots()
    for _, slot in ipairs(self.foodSlots) do
        self.scrollView:removeChild(slot)
    end
    self.foodSlots = {}
end

-- 更新食物列表
function PJCK_CookerContainerPanel:updateFoodList()
    if not self.selectedCooker then
        self:clearFoodSlots()
        return
    end
    
    -- 清除现有槽位
    self:clearFoodSlots()
    
    -- 获取新的食物列表
    self.allFoodItems = self:getAllFoodItems()
    
    if #self.allFoodItems > 0 then
        -- 创建新的食物槽位
        self:createFoodSlots()
    end
    -- 如果没有食物，render函数会显示空容器状态
end

-- 创建食物槽位
function PJCK_CookerContainerPanel:createFoodSlots()
    local currentX = self.slotSpacing
    local currentY = self.slotSpacing
    local maxRowHeight = 0
    local itemsInCurrentRow = 0
    
    for index, itemGroup in ipairs(self.allFoodItems) do
        -- 检查是否需要换行
        if itemsInCurrentRow >= self.itemsPerRow then
            currentX = self.slotSpacing
            currentY = currentY + maxRowHeight + self.verticalSpacing
            itemsInCurrentRow = 0
            maxRowHeight = 0
        end
        
        -- 创建食物槽位
        local foodSlot = PJCK_FoodSlot:new(
            currentX, 
            currentY, 
            self.slotSize, 
            itemGroup.item, 
            itemGroup.count,
            self
        )
        foodSlot:initialise()
        
        self.scrollView:addScrollChild(foodSlot)
        table.insert(self.foodSlots, foodSlot)
        
        -- 更新位置
        currentX = currentX + self.slotSize + self.slotSpacing
        maxRowHeight = math.max(maxRowHeight, self.slotSize)
        itemsInCurrentRow = itemsInCurrentRow + 1
    end
    
    -- 设置滚动区域大小
    local totalWidth = self.itemsPerRow * (self.slotSize + self.slotSpacing) + self.slotSpacing
    local totalHeight = currentY + maxRowHeight + self.slotSpacing
    
    self.scrollView:setScrollWidth(totalWidth)
    self.scrollView:setScrollHeight(math.max(totalHeight, self.scrollView:getHeight()))
end

-- ---------------------------------------------------------- --
-- 数据更新
-- ---------------------------------------------------------- --

function PJCK_CookerContainerPanel:checkCookerChanges()
    if not self.selectedCooker then
        if self.lastCookerSize ~= 0 then
            self.lastCookerSize = 0
            return true -- 烹饪器从有变成无，需要更新
        end
        return false
    end
    
    local cookerItems = self.selectedCooker:getItems()
    if not cookerItems then
        if self.lastCookerSize ~= 0 then
            self.lastCookerSize = 0
            return true
        end
        return false
    end
    
    local currentSize = cookerItems:size()
    
    if currentSize ~= self.lastCookerSize then
        self.lastCookerSize = currentSize
        return true -- 烹饪器内容发生变化
    end
    
    return false
end

function PJCK_CookerContainerPanel:update()
    ISPanel.update(self)
    
    -- 从父面板获取当前选中的烹饪器
    if self.CookerPanel.selectedCooker ~= self.selectedCooker then
        self:setCooker(self.CookerPanel.selectedCooker)
    end
    
    -- 检查烹饪器变化并更新数据
    if self:checkCookerChanges() then
        -- 烹饪器内容发生变化，更新显示
        self:updateDisplay()
        
        -- 如果需要，也可以触发主面板的数据更新
        if self.CookerPanel and self.CookerPanel.MainPanel then
            self.CookerPanel.MainPanel:updateData()
        end
    end
end

-- ---------------------------------------------------------- --
-- 渲染函数
-- ---------------------------------------------------------- --

function PJCK_CookerContainerPanel:prerender()
    -- 绘制主内容区域背景
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        self.titleHeight,
        self.width,
        self.height - self.titleHeight,
        self.CookerPanel.contentBgTextures,
        1.0, 0.1, 0.1, 0.1
    )
    
    -- 绘制标题栏
    PJCK_UIHelper.drawThreeSlice(
        self,
        0,
        0,
        self.width,
        self.titleHeight,
        self.CookerPanel.titleBarTextures.left,
        self.CookerPanel.titleBarTextures.middle,
        self.CookerPanel.titleBarTextures.right,
        1.0, 0.2, 0.2, 0.2
    )
end

function PJCK_CookerContainerPanel:render()
    local availableHeight = math.floor(self.height - self.titleHeight)
    local iconSize = math.floor(self.width * 0.3)
    local textSize = FONT_HGT_MEDIUM
    local totalHeight = iconSize + textSize
    local startY = self.contentY + (availableHeight - totalHeight) / 2

    -- "未选择烹饪器"状态
    if not self.selectedCooker then
        -- 绘制图标
        local iconX = (self.width - iconSize) / 2
        self:drawTextureScaled(self.NoItemIcon, iconX, startY, iconSize, iconSize, 1, 1, 1, 1)
        
        -- 绘制文本
        local text = getText("IGUI_PJCK_NoCookerSelected")
        local textWidth = getTextManager():MeasureStringX(UIFont.Medium, text)
        local textX = (self.width - textWidth) / 2
        local textY = startY + iconSize 

        local bgPadding = FONT_HGT_SMALL / 2
        local bgWidth = textWidth + bgPadding * 2
        local bgHeight = textSize + bgPadding
        local bgX = textX - bgPadding
        local bgY = textY - bgPadding / 2
        
        PJCK_UIHelper.drawThreeSlice(
            self,
            bgX, bgY, bgWidth, bgHeight,
            self.buttonTextures.left,
            self.buttonTextures.middle,
            self.buttonTextures.right,
            1.0, 0.2, 0.2, 0.2
        )

        self:drawText(text, textX, textY, 0.7, 0.7, 0.7, 1.0, UIFont.Medium)
        return
    end
    
    -- "空容器"状态
    if self.selectedCooker and #self.allFoodItems == 0 then
        -- 绘制图标
        local iconX = (self.width - iconSize) / 2
        self:drawTextureScaled(self.NoContainerIcon, iconX, startY, iconSize, iconSize, 1, 1, 1, 1)
        
        -- 绘制文本
        local text = getText("IGUI_PJCK_EmptyContainer")
        local textWidth = getTextManager():MeasureStringX(UIFont.Medium, text)
        local textX = (self.width - textWidth) / 2
        local textY = startY + iconSize 

        local bgPadding = FONT_HGT_SMALL / 2
        local bgWidth = textWidth + bgPadding * 2
        local bgHeight = textSize + bgPadding
        local bgX = textX - bgPadding
        local bgY = textY - bgPadding / 2
        
        PJCK_UIHelper.drawThreeSlice(
            self,
            bgX, bgY, bgWidth, bgHeight,
            self.buttonTextures.left,
            self.buttonTextures.middle,
            self.buttonTextures.right,
            1.0, 0.2, 0.2, 0.2
        )

        self:drawText(text, textX, textY, 0.7, 0.7, 0.7, 1.0, UIFont.Medium)
    end
end

return PJCK_CookerContainerPanel