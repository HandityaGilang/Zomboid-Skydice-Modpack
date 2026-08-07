require "ISUI/ISUIElement"

PJCK_ValueAdjustmentSlot = ISUIElement:derive("PJCK_ValueAdjustmentSlot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_ValueAdjustmentSlot:initialise()
    ISUIElement.initialise(self)
end

function PJCK_ValueAdjustmentSlot:new(x, y, width, height, title, value, minValue, maxValue, step, parentPanel, onValueChange, formatFunction)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.title = title
    o.value = value
    o.minValue = minValue
    o.maxValue = maxValue
    o.step = step
    o.parentPanel = parentPanel
    o.onValueChange = onValueChange
    o.formatFunction = formatFunction
    
    o.titleHeight = FONT_HGT_SMALL * 1.2
    o.ButtonSize = FONT_HGT_MEDIUM
    o.valueAreaWidth = width - o.ButtonSize * 2 - FONT_HGT_SMALL / 2
    
    o.BackgroundTextures = {
        left = getTexture("media/ui/Project_Cook/Button/Cooker_BG_Left.png"),
        middle = getTexture("media/ui/Project_Cook/Button/Cooker_BG_Middle.png"),
        right = getTexture("media/ui/Project_Cook/Button/Cooker_BG_Right.png")
    }
    
    return o
end

-- ---------------------------------------------------------- --
-- 创建子元素
-- ---------------------------------------------------------- --

function PJCK_ValueAdjustmentSlot:createChildren()
    local Padding = FONT_HGT_SMALL / 4
    local contentHeight = self.height - self.titleHeight
    
    -- 计算按钮在内容区域的垂直居中位置
    local buttonY = self.titleHeight + (contentHeight - self.ButtonSize) / 2
    
    -- 减号按钮
    self.minusButton = PJCK_SquareButton.createMinusButton(Padding, buttonY, self.ButtonSize, self, self.onMinusClick)
    self.minusButton:initialise()
    self:addChild(self.minusButton)
    
    -- 加号按钮
    local plusX = self.width - self.ButtonSize - Padding
    self.plusButton = PJCK_SquareButton.createPlusButton(plusX, buttonY, self.ButtonSize, self, self.onPlusClick)
    self.plusButton:initialise()
    self:addChild(self.plusButton)
end

-- ---------------------------------------------------------- --
-- 数值操作
-- ---------------------------------------------------------- --

function PJCK_ValueAdjustmentSlot:setValue(newValue)
    local oldValue = self.value
    self.value = math.max(self.minValue, math.min(self.maxValue, newValue))
    
    if self.value ~= oldValue and self.onValueChange then
        self.onValueChange(self, self.value)
    end
end

function PJCK_ValueAdjustmentSlot:getValue()
    return self.value
end

function PJCK_ValueAdjustmentSlot:onMinusClick()
    self:setValue(self.value - self.step)
end

function PJCK_ValueAdjustmentSlot:onPlusClick()
    self:setValue(self.value + self.step)
end

-- ---------------------------------------------------------- --
-- 渲染函数
-- ---------------------------------------------------------- --

function PJCK_ValueAdjustmentSlot:prerender()
    -- 绘制标题（X轴居中）
    local contentHeight = self.height - self.titleHeight
    local titleTextWidth = getTextManager():MeasureStringX(UIFont.Small, self.title)
    local titleX = (self.width - titleTextWidth) / 2
    local titleY = (self.titleHeight - FONT_HGT_SMALL) / 2
    self:drawText(self.title, titleX, titleY, 0.9, 0.9, 0.9, 1.0, UIFont.Small)
    
    -- 绘制区域背景
    PJCK_UIHelper.drawThreeSlice(
        self,
        0, self.titleHeight, self.width, contentHeight,
        self.BackgroundTextures.left,
        self.BackgroundTextures.middle,
        self.BackgroundTextures.right,
        0.8, 0.5, 0.5, 0.5
    )
end

function PJCK_ValueAdjustmentSlot:render()
    -- 绘制数值（在内容区域垂直居中）
    local contentHeight = self.height - self.titleHeight
    local valueStr = self.formatFunction and self.formatFunction(self.value) or tostring(self.value)
    local textWidth = getTextManager():MeasureStringX(UIFont.Medium, valueStr)
    local valueX = self.ButtonSize + (self.valueAreaWidth - textWidth) / 2
    local valueY = self.titleHeight + (contentHeight - FONT_HGT_MEDIUM) / 2
    
    self:drawText(valueStr, valueX, valueY, 1, 1, 1, 1.0, UIFont.Medium)
end

return PJCK_ValueAdjustmentSlot