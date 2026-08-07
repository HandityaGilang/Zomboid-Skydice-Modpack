require "ISUI/ISPanel"

PJCK_InputSwitch_Box = ISPanel:derive("PJCK_InputSwitch_Box")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Box:initialise()
    ISPanel.initialise(self)
end

function PJCK_InputSwitch_Box:new(x, y, width, height, itemInfo, parentPanel, itemIndex)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.itemInfo = itemInfo
    o.parentPanel = parentPanel
    o.itemIndex = itemIndex
    o.padding = math.floor(FONT_HGT_SMALL * 0.2)
    o.iconSize = math.floor(height * 0.6)
    o.iconAreaSize = height

    o.BackgroundTextures = {
        left = getTexture("media/ui/Project_Cook/HandCraft/InputBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/HandCraft/InputBG_M.png"),
        right = getTexture("media/ui/Project_Cook/HandCraft/InputBG_R.png")
    }

    o.BoarderTextures = {
        left = getTexture("media/ui/Project_Cook/HandCraft/InputBoarder_L.png"),
        middle = getTexture("media/ui/Project_Cook/HandCraft/InputBoarder_M.png"),
        right = getTexture("media/ui/Project_Cook/HandCraft/InputBoarder_R.png")
    }
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- 鼠标事件
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Box:onMouseMove()
    if self:isMouseOver() and not self.itemInfo.inInventory and not self.tooltip then
        self:createTooltip()
    end
    return true
end

function PJCK_InputSwitch_Box:onMouseMoveOutside()
    self:removeTooltip()
    return true
end

function PJCK_InputSwitch_Box:onMouseDown()
    self:removeTooltip()
    
    -- 原有的点击逻辑
    if self.itemInfo.inInventory and self.itemInfo.AvailableItems then
        self.parentPanel:toggleItemExpanded(self.itemIndex)
    end
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip功能
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Box:createTooltip()
    if self.tooltip or not self.itemInfo or not self.itemInfo.scriptItem then return end
    
    local displayName = self.itemInfo.scriptItem:getDisplayName()
    
    self.tooltip = ISToolTip:new()
    self.tooltip:initialise()
    self.tooltip:instantiate()
    self.tooltip:setOwner(self)
    self.tooltip:setName(displayName)
    self.tooltip:addToUIManager()
    self.tooltip:setVisible(true)
end

function PJCK_InputSwitch_Box:removeTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Box:prerender()
    -- 绘制背景
    local bgAlpha = self.itemInfo.inInventory and 1.0 or 0.5
    local color = self:isMouseOver() and 0.2 or 0.15

    PJCK_UIHelper.drawThreeSlice(
        self,
        0, 0, self.width, self.height,
        self.BackgroundTextures.left,
        self.BackgroundTextures.middle,
        self.BackgroundTextures.right,
        bgAlpha, color, color, color
    )
    
    -- 绘制边框
    local r, g, b = 0.2, 0.2, 0.2
    if self.parentPanel:isItemExpanded(self.itemIndex) then
        r,g,b = 0.6, 0.6, 0.6
        bgAlpha = 1.0
    end
    
    PJCK_UIHelper.drawThreeSlice(
        self,
        0, 0, self.width, self.height,
        self.BoarderTextures.left,
        self.BoarderTextures.middle,
        self.BoarderTextures.right,
        bgAlpha, r, g, b
    )
end

function PJCK_InputSwitch_Box:render()
    local itemInfo = self.itemInfo
    local item = itemInfo.scriptItem
    
    -- 绘制物品图标
    local iconAreaX = 0
    local iconAreaY = 0
    local iconAreaSize = self.iconAreaSize
    
    local itemIcon = item:getNormalTexture()
    local iconAlpha = itemInfo.inInventory and 1.0 or 0.5
    
    local IconX = iconAreaX + (iconAreaSize - self.iconSize) / 2
    local IconY = iconAreaY + (iconAreaSize - self.iconSize) / 2
    
    self:drawTextureScaledAspect(itemIcon, IconX, IconY, self.iconSize, self.iconSize, iconAlpha, 1, 1, 1)
    
    -- 计算文本区域
    local textX = self.iconAreaSize + self.padding
    local maxTextWidth = self.width - textX - self.padding
    local totalTextHeight = FONT_HGT_SMALL + FONT_HGT_SMALL * 0.8
    local availableSpace = self.height - totalTextHeight
    local spacing = availableSpace / 3

    -- 绘制物品名称
    local itemName = item:getDisplayName()
    local displayName = PJCK_UIHelper.truncateText(itemName, maxTextWidth, UIFont.Small, "...")
    local TextAlpha = itemInfo.inInventory and 1.0 or 0.5

    self:drawText(displayName, textX, spacing, 1, 1, 1, TextAlpha, UIFont.Small)

    -- 绘制状态信息
    local itemState = self.parentPanel.itemStates[self.itemIndex]
    local statusText = itemState.statusText
    local displayStatus = PJCK_UIHelper.truncateText(statusText, maxTextWidth, UIFont.Small, "...")
    local statusY = spacing + FONT_HGT_SMALL + spacing

    -- 根据状态设置颜色
    local r, g, b = 0.4, 0.4, 0.4
    if statusText == getText("IGUI_CraftUI_AvailableItems") then
        r, g, b = 0.2, 0.6, 1.0
    elseif statusText == getText("IGUI_CraftUI_AlreadyAssigned") then
        r, g, b = 1.0, 1.0, 0.2
    elseif statusText == getText("IGUI_PJCK_InputItemSelected") then
        r, g, b = 0.2, 1.0, 0.2
    end

    self:drawTextZoomed(displayStatus, textX, statusY, 0.8, r, g, b, TextAlpha, UIFont.Small)
    
    -- 在图标区域右下角显示数量
    if itemInfo.inInventory and itemInfo.Count > 0 then
        local countText = tostring(itemInfo.Count)
        local textSize = self.iconAreaSize / 4
        local textWidth = PJCK_UIHelper.measureTextWidth(countText, textSize, true)
        
        local countX = self.iconAreaSize - textWidth - self.iconAreaSize / 16
        local countY = self.iconAreaSize - textSize - self.iconAreaSize / 16

        PJCK_UIHelper.renderText(self, countText, countX, countY, textSize, 1, 1, 1, 1, true)
    end
end


return PJCK_InputSwitch_Box