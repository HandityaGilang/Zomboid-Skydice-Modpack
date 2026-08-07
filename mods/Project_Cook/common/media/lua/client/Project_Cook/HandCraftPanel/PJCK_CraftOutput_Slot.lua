require "ISUI/ISUIElement"

PJCK_CraftOutput_Slot = ISUIElement:derive("PJCK_CraftOutput_Slot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Slot:initialise()
    ISUIElement.initialise(self)

    self:updateOutputInfo()
end

function PJCK_CraftOutput_Slot:new(x, y, size, player, outputScript, parentpanel)
    local o = ISUIElement:new(x, y, size, size)
    setmetatable(o, self)
    self.__index = self
    
    o.size = size
    o.iconSize = size*0.6
    o.player = player
    o.outputScript = outputScript
    o.parentpanel = parentpanel
    o.logic = parentpanel.logic
    o.tooltip = nil

    o.outputAmount = 1
    if outputScript:getResourceType() == ResourceType.Item then
        o.outputAmount = outputScript:getIntAmount()
    elseif outputScript:getResourceType() == ResourceType.Fluid then
        o.outputAmount = outputScript:getAmount()
    end
    
    o.slotTextures = {
        background = getTexture("media/ui/Project_Cook/Slot/Background.png"),
        backgroundHover = getTexture("media/ui/Project_Cook/Slot/Hover.png"),
        border = getTexture("media/ui/Project_Cook/Slot/Boarder.png"),
    }
    
    return o
end
-------------------------------------------------------------------------------------------------- --
-- 更新输出物品信息
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Slot:updateOutputInfo()
    if not self.outputScript then return end

    self.actualOutputItem = nil
    self.itemIcon = nil

    if self.outputScript:getResourceType() == ResourceType.Item then
        if self.logic and self.logic:isManualSelectInputs() then
            local outputMapper = self.outputScript:getOutputMapper()
            if outputMapper then
                local actualOutputItem = outputMapper:getOutputItem(self.logic:getRecipeData(), true)
                if actualOutputItem and actualOutputItem:getNormalTexture() then
                    self.itemIcon = actualOutputItem:getNormalTexture()
                    self.actualOutputItem = actualOutputItem
                end
            end
        end

        if not self.itemIcon then
            local outputObjects = self.outputScript:getPossibleResultItems()
            if outputObjects and outputObjects:size() > 0 then
                local item = outputObjects:get(0)
                self.itemIcon = item:getNormalTexture()
                self.actualOutputItem = item
            end
        end
    elseif self.outputScript:getResourceType() == ResourceType.Fluid then
        self.itemIcon = getTexture("media/textures/Item_Waterdrop_Grey.png")
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 交互处理
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Slot:onMouseMove(dx, dy)
    if self:isMouseOver() and not self.tooltip then
        self:createTooltip()
    end
    return true
end

function PJCK_CraftOutput_Slot:onMouseMoveOutside(dx, dy)
    self:removeTooltip()
    return true
end

function PJCK_CraftOutput_Slot:onMouseDown(x, y)
    self:removeTooltip()
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip功能
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Slot:createTooltip()
    if self.tooltip then return end
    
    local displayName = self.actualOutputItem:getDisplayName()
    
    self.tooltip = ISToolTip:new()
    self.tooltip:initialise()
    self.tooltip:instantiate()
    self.tooltip:setOwner(self)
    self.tooltip:setName(displayName)
    self.tooltip:addToUIManager()
    self.tooltip:setVisible(true)
end

function PJCK_CraftOutput_Slot:removeTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end
-- ---

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Slot:prerender()
    -- 绘制背景
    self:drawTextureScaled(self.slotTextures.background, 0, 0, self.width, self.height, 0.8, 0.4, 0.4, 0.4)
    
    -- 绘制边框
    self:drawTextureScaled(self.slotTextures.border, 0, 0, self.width, self.height, 0.8, 0.4, 0.4, 0.4)
    
    -- 悬浮效果
    if self:isMouseOver() then
        self:drawTextureScaled(self.slotTextures.backgroundHover, 0, 0, self.width, self.height, 0.5, 0.5, 0.5, 0.5)
    end
end

function PJCK_CraftOutput_Slot:render()

    local iconX = (self.width - self.iconSize) / 2
    local iconY = (self.height - self.iconSize) / 2
    self:drawTextureScaledAspect(self.itemIcon, iconX, iconY, self.iconSize, self.iconSize, 1, 1, 1, 1)

    -- 显示数量文本
    if self.outputAmount > 1 then
        local textSize = self.size/4
        local textWidth = PJCK_UIHelper.measureTextWidth(tostring(self.outputAmount), textSize, true)
        
        local textX = self.width - textWidth - self.size/16
        local textY = self.height - textSize - self.size/16

        PJCK_UIHelper.renderText(self, tostring(self.outputAmount), textX, textY, textSize, 1.0, 1, 1, 1, true)
    end
end

return PJCK_CraftOutput_Slot