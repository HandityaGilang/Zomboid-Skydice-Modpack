require "ISUI/ISPanel"

PJCK_InventoryPanel = ISPanel:derive("PJCK_InventoryPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_InventoryPanel:initialise()
    ISPanel.initialise(self)
end

function PJCK_InventoryPanel:new(x, y, width, height, CookerPanel)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.CookerPanel = CookerPanel
    o.player = CookerPanel.player
    o.selectedContainer = nil
    o.selectedAllContainers = false
    o.lastContainerSize = 0
    o.hoverHighlightedObject = nil
    o.selectedHighlightedObject = nil
    
    -- 容器按钮区域
    o.containersButtonSize = math.floor(FONT_HGT_SMALL*2)
    o.ContainerButtonPadding = math.floor(FONT_HGT_SMALL*0.2)
    o.baseContainerButtonHeight = o.containersButtonSize + o.ContainerButtonPadding*2
    o.containerButtonHeight = o.baseContainerButtonHeight
    
    -- 食物区域
    o.slotSize = math.floor(FONT_HGT_SMALL * 2.5)
    o.slotSpacing = math.floor(o.slotSize / 4)
    o.verticalSpacing = math.floor(o.slotSize/1.5)
    local availableWidth = width - o.slotSpacing * 2
    o.itemsPerRow = math.floor(availableWidth / (o.slotSize + o.slotSpacing))
    o.itemsPerRow = math.max(1, o.itemsPerRow)
    
    -- 容器按钮数组
    o.containerButtons = {}
    
    -- 食物槽位数组
    o.foodSlots = {}
    o.allFoodItems = {}
    
    return o
end

-- ---------------------------------------------------------- --
-- 创建子元素
-- ---------------------------------------------------------- --

function PJCK_InventoryPanel:createChildren()
    local titleHeight = FONT_HGT_MEDIUM * 1.2
    local padding = FONT_HGT_SMALL * 0.4
    
    -- 创建标题栏
    self.titleBar = ISPanel:new(0, 0, self.width, titleHeight)
    self.titleBar:initialise()
    self.titleBar.backgroundColor.a = 0
    self.titleBar.borderColor.a = 0
    self:addChild(self.titleBar)
    self.titleHeight = titleHeight
    
    -- 标题文本
    local titleTextY = (titleHeight - FONT_HGT_SMALL) / 2
    local inventoryLabel = ISLabel:new(padding, titleTextY, FONT_HGT_SMALL, 
                                     getText("IGUI_ItemCat_Food"), 1, 1, 1, 1, UIFont.Small, true)
    inventoryLabel:initialise()
    self.titleBar:addChild(inventoryLabel)
    
    self:createContainerArea()
    self:createFoodArea()
    
    -- 初始更新容器按钮和食物列表
    self:updateContainerButtons()
    self:updateFoodList()
    self:selectDefaultContainer()
end

-- 创建容器按钮区域
function PJCK_InventoryPanel:createContainerArea()
    
    self.containerScrollView = PJCK_ScrollView:new(0, self.titleHeight, self.width, self.baseContainerButtonHeight)
    self.containerScrollView:initialise()
    self.containerScrollView:setScrollDirection("horizontal")
    self.containerScrollView:setScrollSensitivity(self.containersButtonSize + self.ContainerButtonPadding)
    self:addChild(self.containerScrollView)
    self.containerScrollView:setWantKeyEvents(true)
    self.containerButtons = {}
end

-- 创建容器按钮
function PJCK_InventoryPanel:createContainerButtons(containerInfo)
    local currentX = self.ContainerButtonPadding

    -- Global container button: shows food from every available container.
    local allContainersTexture = getTexture("media/ui/Project_Cook/ICON/Icon_AllContainers.png") or getTexture("media/ui/Project_Cook/ICON/Icon_ShowAll.png")
    local allContainersText = getTextOrNull("IGUI_PJCK_AllContainers") or "All Containers"
    local allContainersButton = PJCK_ContainerButton:new(
        currentX,
        self.ContainerButtonPadding,
        self.containersButtonSize,
        self.containersButtonSize,
        nil,
        allContainersText,
        allContainersTexture,
        self,
        true
    )
    allContainersButton:initialise()
    self.containerScrollView:addScrollChild(allContainersButton)
    table.insert(self.containerButtons, allContainersButton)
    currentX = currentX + self.containersButtonSize + self.ContainerButtonPadding
    
    for _, info in ipairs(containerInfo) do
        -- 创建容器按钮
        local containerButton = PJCK_ContainerButton:new(
            currentX,
            self.ContainerButtonPadding,
            self.containersButtonSize,
            self.containersButtonSize,
            info.container,
            info.displayName,
            info.texture,
            self,
            false
        )
        containerButton:initialise()
        
        self.containerScrollView:addScrollChild(containerButton)
        table.insert(self.containerButtons, containerButton)
        
        currentX = currentX + self.containersButtonSize + self.ContainerButtonPadding
    end
    
    -- 设置滚动区域大小
    local totalWidth = currentX + self.ContainerButtonPadding
    self.containerScrollView:setScrollWidth(math.max(totalWidth, self.containerScrollView:getWidth()))
    self.containerScrollView:setScrollHeight(self.containerButtonHeight)
end

-- 创建食物区域
function PJCK_InventoryPanel:createFoodArea()
    local padding = FONT_HGT_SMALL / 8
    local foodAreaY = self.titleHeight + self.containerButtonHeight + padding
    local foodAreaHeight = self.height - foodAreaY - padding
    
    self.scrollView = PJCK_ScrollView:new(0, foodAreaY, self.width, foodAreaHeight)
    self.scrollView:initialise()
    self.scrollView:setScrollDirection("vertical")
    self.scrollView:setScrollSensitivity(self.slotSize + self.slotSpacing)
    self:addChild(self.scrollView)
    self.scrollView:setWantKeyEvents(true)
    self.foodAreaY = foodAreaY
end

-- 创建食物槽位
function PJCK_InventoryPanel:createFoodSlots()
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

        currentX = currentX + self.slotSize + self.slotSpacing
        maxRowHeight = math.max(maxRowHeight, self.slotSize)
        itemsInCurrentRow = itemsInCurrentRow + 1
    end

    local totalWidth = self.itemsPerRow * (self.slotSize + self.slotSpacing) + self.slotSpacing
    local totalHeight = currentY + maxRowHeight + self.slotSpacing
    
    self.scrollView:setScrollWidth(totalWidth)
    self.scrollView:setScrollHeight(math.max(totalHeight, self.scrollView:getHeight()))
end

-- 重新布局子组件
function PJCK_InventoryPanel:relayoutChildren()
    -- 更新容器按钮区域高度
    self.containerScrollView:setHeight(self.containerButtonHeight)
    
    -- 更新食物区域高度
    local padding = FONT_HGT_SMALL / 8
    local foodAreaY = self.titleHeight + self.containerButtonHeight + padding
    local foodAreaHeight = self.height - foodAreaY - padding

    self.scrollView:setY(foodAreaY)
    self.scrollView:setHeight(foodAreaHeight)

    self.foodAreaY = foodAreaY
end

-- ---------------------------------------------------------- --
-- 容器按钮区域方法
-- ---------------------------------------------------------- --

-- 获取容器信息
function PJCK_InventoryPanel:getContainerInfo()
    local containers = self.CookerPanel.MainPanel:getContainers()
    local containerInfo = {}
    
    if not containers then return containerInfo end
    
    -- 获取当前选中的烹饪器容器
    local selectedCooker = self.CookerPanel.selectedCooker
    
    for i = 0, containers:size() - 1 do
        local container = containers:get(i)
        
        -- 跳过当前选中的烹饪器容器
        if selectedCooker and container == selectedCooker then
            -- 跳过这个容器
        else
            local displayName = ""
            local containerTexture = nil
            local containerType = container:getType()
            
            -- 玩家背包特殊处理
            if container == self.player:getInventory() then
                displayName = getText("IGUI_InventoryTooltip")
                containerTexture = getTexture("media/ui/Icon_InventoryBasic.png")
            else
                if container:getVehiclePart() then
                    displayName = getText("IGUI_VehiclePart" .. containerType)
                else
                    displayName = getTextOrNull("IGUI_ContainerTitle_" .. containerType) or containerType
                end
                
                -- 获取图标
                local containingItem = container:getContainingItem()
                if containingItem then
                    displayName = containingItem:getName()
                    containerTexture = containingItem:getTex()
                else
                    if ContainerButtonIcons and ContainerButtonIcons[containerType] then
                        containerTexture = ContainerButtonIcons[containerType]
                    else
                        containerTexture = getTexture("media/ui/Container_Shelf.png")
                    end
                end
            end
            
            table.insert(containerInfo, {
                container = container,
                displayName = displayName,
                texture = containerTexture
            })
        end
    end
    
    return containerInfo
end

-- 检查是否需要滚动条
function PJCK_InventoryPanel:needsScrollBar(containerInfo)
    if not containerInfo or #containerInfo == 0 then
        return false
    end
    
    local buttonSpacing = self.ContainerButtonPadding
    local buttonSize = self.containersButtonSize
    local totalButtons = #containerInfo + 1 -- plus the global/all-containers button
    local totalButtonWidth = totalButtons * buttonSize + (totalButtons + 1) * buttonSpacing

    return totalButtonWidth > self.width
end

-- 更新容器按钮区域高度
function PJCK_InventoryPanel:updateContainerAreaHeight(needsScrollBar)
    local newHeight = self.baseContainerButtonHeight
    if needsScrollBar then
        newHeight = newHeight + FONT_HGT_SMALL*0.6
    end

    if self.containerButtonHeight ~= newHeight then
        self.containerButtonHeight = newHeight
        self:relayoutChildren()
    end
end

function PJCK_InventoryPanel:getPlayerNum()
    return self.player and self.player.getPlayerNum and self.player:getPlayerNum() or 0
end

function PJCK_InventoryPanel:getContainerParent(container)
    if not container then return nil end
    if container.getParent and container:getParent() then return container:getParent() end

    local item = container.getContainingItem and container:getContainingItem() or nil
    if item and item.getWorldItem and item:getWorldItem() then
        return item:getWorldItem()
    end

    return nil
end

function PJCK_InventoryPanel:isHighlightableContainerObject(object)
    if not object then return false end
    if instanceof(object, "IsoPlayer") and not instanceof(object, "IsoDeadBody") then
        return false
    end
    return true
end

function PJCK_InventoryPanel:clearObjectHighlight(object)
    if not object then return end

    local playerNum = self:getPlayerNum()
    pcall(function() object:setHighlighted(playerNum, false, false) end)
    pcall(function() object:setOutlineHighlight(playerNum, false) end)
    pcall(function() object:setOutlineHlAttached(playerNum, false) end)
end

function PJCK_InventoryPanel:applySelectedObjectHighlight(object)
    if not self:isHighlightableContainerObject(object) then return end

    local playerNum = self:getPlayerNum()
    pcall(function() object:setHighlighted(playerNum, true, false) end)
    pcall(function() object:setHighlightColor(playerNum, getCore():getObjectHighlitedColor()) end)

    if getCore():getOptionDoContainerOutline() then
        pcall(function() object:setOutlineHighlight(playerNum, true) end)
        pcall(function() object:setOutlineHlAttached(playerNum, true) end)
        pcall(function()
            local color = getCore():getObjectHighlitedColor()
            object:setOutlineHighlightCol(playerNum, color:getR(), color:getG(), color:getB(), 1)
        end)
    end
end

function PJCK_InventoryPanel:applyHoverObjectOutline(object)
    if not self:isHighlightableContainerObject(object) then return end
    if not getCore():getOptionDoContainerOutline() then return end

    local playerNum = self:getPlayerNum()
    pcall(function() object:setOutlineHighlight(playerNum, true) end)
    pcall(function() object:setOutlineHlAttached(playerNum, true) end)
    pcall(function()
        local color = getCore():getWorldItemHighlightColor()
        object:setOutlineHighlightCol(playerNum, color:getR(), color:getG(), color:getB(), 1)
    end)
end

function PJCK_InventoryPanel:applyHoverContainerHighlight(container)
    local object = self:getContainerParent(container)
    if not self:isHighlightableContainerObject(object) then return end

    if self.hoverHighlightedObject and self.hoverHighlightedObject ~= object then
        self:clearHoverContainerHighlight()
    end

    self.hoverHighlightedObject = object
    self:applyHoverObjectOutline(object)
end

function PJCK_InventoryPanel:clearHoverContainerHighlight(container)
    local object = container and self:getContainerParent(container) or self.hoverHighlightedObject
    if not object then return end
    if self.hoverHighlightedObject and object ~= self.hoverHighlightedObject then return end

    if object == self.selectedHighlightedObject then
        -- If the hovered object is also the selected container, removing the
        -- hover outline must restore the selected-container highlight instead
        -- of clearing the colored selection.
        self:applySelectedObjectHighlight(object)
    else
        self:clearObjectHighlight(object)
    end

    if self.hoverHighlightedObject == object then
        self.hoverHighlightedObject = nil
    end
end

function PJCK_InventoryPanel:clearSelectedContainerHighlight()
    if self.selectedHighlightedObject then
        if self.selectedHighlightedObject == self.hoverHighlightedObject then
            self:applyHoverObjectOutline(self.selectedHighlightedObject)
        else
            self:clearObjectHighlight(self.selectedHighlightedObject)
        end
        self.selectedHighlightedObject = nil
    end
end

function PJCK_InventoryPanel:updateSelectedContainerHighlight()
    self:clearSelectedContainerHighlight()

    if self.selectedAllContainers or not self.selectedContainer then
        return
    end

    local object = self:getContainerParent(self.selectedContainer)
    if not self:isHighlightableContainerObject(object) then return end

    self.selectedHighlightedObject = object
    self:applySelectedObjectHighlight(object)

    if self.hoverHighlightedObject == object then
        self:applyHoverObjectOutline(object)
    end
end

-- 更新容器按钮
function PJCK_InventoryPanel:updateContainerButtons()
    self:clearHoverContainerHighlight()
    self:clearSelectedContainerHighlight()

    -- 清除现有按钮
    for _, button in ipairs(self.containerButtons) do
        self.containerScrollView:removeChild(button)
    end
    self.containerButtons = {}
    
    -- 检查是否需要滚动条并更新区域高度
    local containerInfo = self:getContainerInfo()
    local needsScrollBar = self:needsScrollBar(containerInfo)
    self:updateContainerAreaHeight(needsScrollBar)
    
    self:createContainerButtons(containerInfo)
end

-- 选择默认容器
function PJCK_InventoryPanel:selectDefaultContainer()
    if #self.containerButtons > 0 then
        local playerInventoryButton = nil
        for _, button in ipairs(self.containerButtons) do
            if not button:isAllContainersButton() and button:getContainer() == self.player:getInventory() then
                playerInventoryButton = button
                break
            end
        end

        local defaultButton = playerInventoryButton or self.containerButtons[1]
        if defaultButton then
            self:onContainerButtonClick(defaultButton)
        end
    end
end

function PJCK_InventoryPanel:isAllContainersSelected()
    return self.selectedAllContainers == true
end

function PJCK_InventoryPanel:getAvailableSourceContainers()
    local containers = self.CookerPanel.MainPanel:getContainers()
    local result = {}
    if not containers then return result end

    local selectedCooker = self.CookerPanel.selectedCooker
    for i = 0, containers:size() - 1 do
        local container = containers:get(i)
        if container and container ~= selectedCooker then
            table.insert(result, container)
        end
    end

    return result
end

function PJCK_InventoryPanel:getSelectedContainersSizeSignature()
    local total = 0
    local containers = self:getAvailableSourceContainers()
    for _, container in ipairs(containers) do
        if container and container.getItems then
            local items = container:getItems()
            total = total + (items and items:size() or 0)
        end
    end
    return total
end

-- 容器按钮点击
function PJCK_InventoryPanel:onContainerButtonClick(clickedButton)
    -- 更新按钮选中状态
    for _, button in ipairs(self.containerButtons) do
        button:setSelected(false)
    end
    clickedButton:setSelected(true)
    
    -- 设置选中的容器
    self.selectedAllContainers = clickedButton:isAllContainersButton()
    self.selectedContainer = self.selectedAllContainers and nil or clickedButton:getContainer()
    self:updateSelectedContainerHighlight()
    
    -- 重置容器监控状态
    if self.selectedAllContainers then
        self.lastContainerSize = self:getSelectedContainersSizeSignature()
    else
        self.lastContainerSize = self.selectedContainer and self.selectedContainer:getItems():size() or 0
    end

    -- 更新食物列表
    self:updateFoodList()
end


-- ---------------------------------------------------------- --
-- 数据获取与处理
-- ---------------------------------------------------------- --

-- 获取所有食物物品
function PJCK_InventoryPanel:getAllFoodItems()
    local foodItems = {}
    local sourceContainers = {}

    if self.selectedAllContainers then
        sourceContainers = self:getAvailableSourceContainers()
    elseif self.selectedContainer then
        sourceContainers = { self.selectedContainer }
    else
        return foodItems
    end

    local itemsByName = {}

    for _, sourceContainer in ipairs(sourceContainers) do
        local containerItems = sourceContainer and sourceContainer:getItems()
        if containerItems then
            for i = 0, containerItems:size() - 1 do
                local item = containerItems:get(i)
                if self:isFoodItem(item) then
                    local itemName = item:getName()
                    if not itemsByName[itemName] then
                        itemsByName[itemName] = {
                            item = item,
                            count = 1
                        }
                    else
                        itemsByName[itemName].count = itemsByName[itemName].count + 1

                        if self:getItemQuality(item) > self:getItemQuality(itemsByName[itemName].item) then
                            itemsByName[itemName].item = item
                        end
                    end
                end
            end
        end
    end

    -- 转换为数组并排序
    for _, itemGroup in pairs(itemsByName) do
        table.insert(foodItems, itemGroup)
    end

    table.sort(foodItems, function(a, b)
        return a.item:getName() < b.item:getName()
    end)

    return foodItems
end

-- 判断是否为食物物品
function PJCK_InventoryPanel:isFoodItem(item)
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
function PJCK_InventoryPanel:getItemQuality(item)
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

-- ---------------------------------------------------------- --
-- 数据更新
-- ---------------------------------------------------------- --

-- 更新食物列表
function PJCK_InventoryPanel:updateFoodList()
    -- 清除现有槽位
    for _, slot in ipairs(self.foodSlots) do
        self.scrollView:removeChild(slot)
    end
    self.foodSlots = {}
    
    -- 获取新的食物列表
    self.allFoodItems = self:getAllFoodItems()
    
    -- 更新数量显示
    local totalCount = 0
    for _, itemGroup in ipairs(self.allFoodItems) do
        totalCount = totalCount + itemGroup.count
    end
    
    -- 创建新的食物槽位
    self:createFoodSlots()
end

-- 检测容器容量变化
function PJCK_InventoryPanel:checkContainerChanges()
    if self.selectedAllContainers then
        local currentSize = self:getSelectedContainersSizeSignature()
        if currentSize ~= self.lastContainerSize then
            self.lastContainerSize = currentSize
            return true
        end
        return false
    end

    if not self.selectedContainer then
        if self.lastContainerSize ~= 0 then
            self.lastContainerSize = 0
            return true -- 容器从有变成无，需要更新
        end
        return false
    end
    
    local currentSize = self.selectedContainer:getItems():size()
    
    if currentSize ~= self.lastContainerSize then
        self.lastContainerSize = currentSize
        return true -- 容器内容发生变化
    end
    
    return false
end

function PJCK_InventoryPanel:update()
    ISPanel.update(self)
    
    -- 检查容器变化并更新数据
    if self:checkContainerChanges() then
        -- 容器内容发生变化，更新食物列表
        self:updateFoodList()
    end
end


-- ---------------------------------------------------------- --
-- 渲染函数
-- ---------------------------------------------------------- --

function PJCK_InventoryPanel:prerender()
    -- 绘制食物区域背景
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        self.titleHeight + self.containerButtonHeight,
        self.width,
        self.height - self.titleHeight-self.containerButtonHeight,
        self.CookerPanel.contentBgTextures,
        1.0, 0.1, 0.1, 0.1
    )
    
    -- 绘制容器按钮区域背景
    PJCK_UIHelper.drawThreeSlice(
        self,
        0,
        self.titleHeight, 
        self.width, 
        self.containerButtonHeight,
        self.CookerPanel.contentBgTextures.topLeft,
        self.CookerPanel.contentBgTextures.top,
        self.CookerPanel.contentBgTextures.topRight,
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

return PJCK_InventoryPanel