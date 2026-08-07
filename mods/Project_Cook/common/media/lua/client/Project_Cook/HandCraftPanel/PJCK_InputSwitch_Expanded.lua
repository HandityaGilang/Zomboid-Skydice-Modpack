require "ISUI/ISPanel"

PJCK_InputSwitch_Expanded = ISPanel:derive("PJCK_InputSwitch_Expanded")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Expanded:initialise()
    ISPanel.initialise(self)
    self:calculateAndSetHeight()
    self:prepareExpandedItemsData()
end

function PJCK_InputSwitch_Expanded:new(x, y, width, inventoryItems, parentPanel, itemIndex)
    local o = ISPanel:new(x, y, width, 10)
    setmetatable(o, self)
    self.__index = self

    o.keepOnScreen = false
    o.parentPanel = parentPanel
    o.itemIndex = itemIndex
    o.inventoryItems = inventoryItems or {}
    o.padding = math.floor(FONT_HGT_SMALL * 0.4)
    o.itemHeight = math.floor(FONT_HGT_SMALL * 1.2)
    o.iconSize = math.floor(FONT_HGT_SMALL)

    o.expandedItemsData = {}

    o.tooltipItem = nil
    o.hoveredItemData = nil

    o.contentBgTextures = {
        topLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LT.png"),
        top = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_T.png"),
        topRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RT.png"),
        left = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_M.png"),
        right = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_R.png"),
        bottomLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LB.png"),
        bottom = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_B.png"),
        bottomRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RB.png")
    }
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- 高度计算和数据准备
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Expanded:calculateAndSetHeight()
    
    local totalHeight = #self.inventoryItems * self.itemHeight
    self:setHeight(totalHeight)
end

function PJCK_InputSwitch_Expanded:prepareExpandedItemsData()
    self.expandedItemsData = {}
    
    local itemState = self.parentPanel.itemStates[self.itemIndex]
    if not itemState then return end
    
    if not itemState.expandedItemStates then
        itemState.expandedItemStates = {}
    end

    for i, invItem in ipairs(self.inventoryItems) do
        if invItem then
            local itemY = (i - 1) * (self.itemHeight)
            
            local itemStatus = itemState.expandedItemStates[invItem]
            
            table.insert(self.expandedItemsData, {
                item = invItem,
                x = self.padding,
                y = itemY,
                width = self.width - self.padding * 2,
                height = self.itemHeight,
                isHovered = false,
                status = itemStatus
            })
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 鼠标事件处理
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Expanded:updateHoverStates(x, y)
    self.hoveredItemData = nil
    
    for i, itemData in ipairs(self.expandedItemsData) do
        itemData.isHovered = (x >= itemData.x and x <= itemData.x + itemData.width and
                             y >= itemData.y and y <= itemData.y + itemData.height)
        
        if itemData.isHovered then
            self.hoveredItemData = itemData
        end
    end
end

function PJCK_InputSwitch_Expanded:onMouseMove()
    local mouseX = self:getMouseX()
    local mouseY = self:getMouseY()
    self:updateHoverStates(mouseX, mouseY)
    
    -- 处理tooltip
    if self.hoveredItemData and self.hoveredItemData.item then
        if not self.tooltipItem then
            self:createTooltip(self.hoveredItemData.item)
        else
            self.tooltipItem:setItem(self.hoveredItemData.item)
        end
    else
        if self.tooltipItem then
            self.tooltipItem:setVisible(false)
        end
    end
    
    return true
end

function PJCK_InputSwitch_Expanded:onMouseDown(x, y)
    self:removeTooltip()

    for i, itemData in ipairs(self.expandedItemsData) do
        if x >= itemData.x and x <= itemData.x + itemData.width and
           y >= itemData.y and y <= itemData.y + itemData.height then
            
            local item = itemData.item
            self.parentPanel:onItemSelected(item, self.itemIndex)
            return true
        end
    end
    return true
end

function PJCK_InputSwitch_Expanded:onMouseMoveOutside()
    for _, itemData in ipairs(self.expandedItemsData) do
        itemData.isHovered = false
    end
    self.hoveredItemData = nil

    self:removeTooltip()
    
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip功能
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Expanded:createTooltip(item)
    if self.tooltipItem or not item then return end
    
    self.tooltipItem = ISToolTipInv:new(item)
    self.tooltipItem:addToUIManager()
    self.tooltipItem.owner = self
    self.tooltipItem:setItem(item)
    self.tooltipItem:setCharacter(self.parentPanel.player)
    self.tooltipItem:setVisible(true)
    self.tooltipItem:setAlwaysOnTop(true)
end

function PJCK_InputSwitch_Expanded:removeTooltip()
    if self.tooltipItem then
        self.tooltipItem:setVisible(false)
        self.tooltipItem:removeFromUIManager()
        self.tooltipItem = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 更新方法
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Expanded:updateInventoryItems(inventoryItems)
    self.inventoryItems = inventoryItems or {}
    self:calculateAndSetHeight()
    self:prepareExpandedItemsData()
end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Expanded:prerender()
    if #self.inventoryItems == 0 then
        return
    end
    
    self:drawRect(
        self.padding,
        0,
        self.width - self.padding * 2,
        self.height,
        0.8, 0.15, 0.15, 0.15
    )
end

function PJCK_InputSwitch_Expanded:render()
    if #self.inventoryItems == 0 then
        return
    end
    
    -- 绘制每个展开的库存物品
    for i, itemData in ipairs(self.expandedItemsData) do
        local item = itemData.item
        local x = itemData.x
        local y = itemData.y
        local width = itemData.width
        local height = itemData.height
        
        -- 根据状态绘制背景
        if itemData.status == "selected" then
            -- 被当前输入选择（绿色）
            self:drawRect(x, y, width, height, 0.5, 0.2, 0.6, 0.2)
        elseif itemData.status == "usedByOther" then
            -- 被其他输入使用（黄色）
            self:drawRect(x, y, width, height, 0.5, 0.6, 0.6, 0.2)
        elseif itemData.isHovered then
            -- 悬浮时高亮
            self:drawRect(x, y, width, height, 0.3, 0.4, 0.4, 0.4)
        end
        
        -- 绘制物品图标
        if item then
            local iconX = x + self.padding / 2
            local iconY = y + (height - self.iconSize) / 2
            local iconAlpha = (itemData.status == "usedByOther") and 0.7 or 1.0
            
            ISInventoryItem.renderItemIcon(self, item, iconX, iconY, iconAlpha, self.iconSize, self.iconSize)
        end
        
        -- 绘制物品名称
        if item then
            local itemName = item:getDisplayName() or item:getName()
            local textX = x + self.iconSize + self.padding
            local textY = y + (height - FONT_HGT_SMALL) / 2
            local maxTextWidth = width - self.iconSize - self.padding * 2
            
            local displayName = PJCK_UIHelper.truncateText(itemName, maxTextWidth, UIFont.Small, "...")
            local textAlpha = (itemData.status == "usedByOther") and 0.7 or 1.0
            local r, g, b = 0.9, 0.9, 0.9
            
            self:drawText(displayName, textX, textY, r, g, b, textAlpha, UIFont.Small)
        end
    end
end

return PJCK_InputSwitch_Expanded