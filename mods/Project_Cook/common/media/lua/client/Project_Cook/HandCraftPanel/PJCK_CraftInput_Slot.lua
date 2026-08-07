require "ISUI/ISUIElement"

PJCK_CraftInput_Slot = ISUIElement:derive("PJCK_CraftInput_Slot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Slot:initialise()
    ISUIElement.initialise(self)
    self:updateInputInfo()
end

function PJCK_CraftInput_Slot:new(x, y, width, height, player, inputScript, parentpanel)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.player = player
    o.inputScript = inputScript
    o.parentpanel = parentpanel
    o.logic = parentpanel.logic
    
    -- 布局相关设置
    o.iconSize = math.floor(height*0.6)
    o.iconAreaWidth = height
    o.padding = math.floor(height * 0.1)
    
    o.DisplayItem = nil
    o.itemType = "normal" -- normal, fluidContainer, usesPartial
    o.consumeScript = nil

    -- Tooltip相关
    o.tooltip = nil

    -- 贴图资源
    o.usePartIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_UsePart.png")
    o.fluidIconTexture = getTexture("media/textures/Item_Waterdrop_Grey.png")
    o.returnIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_CraftReturn.png")

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
-- 获取物品信息
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Slot:updateInputInfo()
    if not self.inputScript or not self.logic then return end

    self.DisplayItem = nil
    self.itemType = "normal"
    self.consumeScript = nil
    
    -- 获取显示物品
    local manualItem = self.logic:getRecipeData():getFirstManualInputFor(self.inputScript)
    if manualItem then
        self.DisplayItem = manualItem:getScriptItem()
    else
        local possibleItems = self.inputScript:getPossibleInputItems()
        if possibleItems and possibleItems:size() > 0 then
            self.DisplayItem = possibleItems:get(0)
        end
    end
    
    -- 三种类型判断
    if self.inputScript:hasConsumeFromItem() then
        local consumeScript = self.inputScript:getConsumeFromItemScript()
        if consumeScript:getResourceType() == ResourceType.Fluid then
            self.itemType = "fluidContainer"
            self.consumeScript = consumeScript
        end
    elseif self.inputScript:isUsesPartialItem(self.DisplayItem) then
        self.itemType = "usesPartial"
    else
        self.itemType = "normal"
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 便捷方法
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Slot:getQuantityText()
    if not self.DisplayItem or not self.inputScript then
        return nil
    end
    
    if self.itemType == "fluidContainer" then
        -- 液体容器：显示液体量
        local amount = self.consumeScript:getAmount()
        local satisfiedAmount = self.logic:getInputUses(self.consumeScript)
        return string.format("%.1f / %.1fL", satisfiedAmount, amount)
        
    elseif self.itemType == "usesPartial" then
        -- 消耗部分物品：显示消耗量/总量
        local requiredAmount = self.inputScript:getIntAmount()
        local manualItem = self.logic:getRecipeData():getFirstManualInputFor(self.inputScript)
        if manualItem then
            local itemMaxUses = manualItem:getCurrentUses()
            return itemMaxUses .. " / " .. requiredAmount
        else
            return "0 / " .. requiredAmount
        end
        
    else
        -- 普通物品：显示数量
        local satisfiedAmount = self.logic:getInputCount(self.inputScript)
        local requiredAmount = self.inputScript:getIntAmount()
        
        -- 检查是否有特定物品的数量要求
        if self.DisplayItem:getFullName() then
            local specificAmount = self.inputScript:getAmount(self.DisplayItem:getFullName())
            if specificAmount > 0 then
                requiredAmount = specificAmount
            end
        end
        
        if requiredAmount > 0 or satisfiedAmount > 0 then
            return satisfiedAmount .. " / " .. requiredAmount
        end
    end
    
    return nil
end

function PJCK_CraftInput_Slot:getDisplayName()
    if not self.DisplayItem then
        return ""
    end
    
    if self.itemType == "fluidContainer" then
        -- 液体容器：显示-液体名(容器名)
        local containerName = self.DisplayItem:getDisplayName()
        local inputFluids = self.logic:getSatisfiedInputFluids(self.consumeScript)
        if inputFluids:size() == 0 then
            inputFluids = self.consumeScript:getPossibleInputFluids()
        end
        
        if inputFluids and inputFluids:size() > 0 then
            local fluidName = inputFluids:get(0):getDisplayName()
            return fluidName .." (" .. containerName .. ")"
        else
            return containerName
        end
    else
        -- 普通物品和消耗部分物品：直接显示物品名
        return self.DisplayItem:getDisplayName()
    end
end

function PJCK_CraftInput_Slot:isInputSatisfied()
    if not self.inputScript then
        return false
    end
    
    local satisfied = self.logic:isInputSatisfied(self.inputScript)
    
    -- 液体容器需要额外检查消耗脚本
    if self.itemType == "fluidContainer" and self.consumeScript then
        satisfied = satisfied and self.logic:isInputSatisfied(self.consumeScript)
    end
    
    return satisfied
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip功能
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Slot:createTooltip()
    if self.tooltip then return end
    
    local displayName = self:getDisplayName() 
    self.tooltip = ISToolTip:new()
    self.tooltip:initialise()
    self.tooltip:instantiate()
    self.tooltip:setOwner(self)
    self.tooltip:setName(displayName)

    local description = ""
    
    if self.inputScript and self.inputScript:isKeep() then
        -- 保留物品
        description = getText("IGUI_CraftingWindow_WillBeKept")
    elseif self.itemType == "usesPartial" then
        -- 消耗部分物品
        local consumeAmount = self.inputScript:getIntAmount()
        description = getText("IGUI_CraftingWindow_WillBeConsume", tostring(consumeAmount))
    else
        -- 普通物品（完全消耗）
        description = getText("IGUI_CraftingWindow_WillBeDestroyed")
    end
    
    self.tooltip:setDescription(description)  
    self.tooltip:addToUIManager()
    self.tooltip:setVisible(true)
end

function PJCK_CraftInput_Slot:removeTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 交互处理
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Slot:onMouseMove(dx, dy)
    if self:isMouseOver() and not self.tooltip then
        self:createTooltip()
    end
    return true
end

function PJCK_CraftInput_Slot:onMouseMoveOutside(dx, dy)
    self:removeTooltip()
    return true
end

function PJCK_CraftInput_Slot:onMouseDown(x, y)
    self:removeTooltip()
    local currentInputScript = self.logic:getManualSelectInputScriptFilter()
    if currentInputScript ~= self.inputScript then
        self.logic:setManualSelectInputScriptFilter(self.inputScript)
        self.logic:setShowManualSelectInputs(true)
    else
        self.logic:setManualSelectInputScriptFilter(nil)
        self.logic:setShowManualSelectInputs(false)
    end
    return true
end

function PJCK_CraftInput_Slot:onMouseUp(x, y)
    return true
end

function PJCK_CraftInput_Slot:onRightMouseUp(x, y)
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- 更新函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Slot:update()
    ISUIElement.update(self)
end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Slot:prerender()
    local r,g,b = 0.15, 0.15, 0.15
    if self:isMouseOver() then
        r,g,b = 0.2, 0.2, 0.2
    end
    PJCK_UIHelper.drawThreeSlice(
        self,
        0, 0, self.width, self.height,
        self.BackgroundTextures.left,
        self.BackgroundTextures.middle,
        self.BackgroundTextures.right,
        0.8, r, g, b
    )

    if self.logic:getManualSelectInputScriptFilter() == self.inputScript then
        r,g,b = 0.5, 0.5, 0.5
    else
        r,g,b = 0.2, 0.2, 0.2
    end
    PJCK_UIHelper.drawThreeSlice(
        self,
        0, 0, self.width, self.height,
        self.BoarderTextures.left,
        self.BoarderTextures.middle,
        self.BoarderTextures.right,
        1, r, g, b
    )
end

function PJCK_CraftInput_Slot:render()
    local iconX = math.floor((self.iconAreaWidth - self.iconSize) / 2)
    local iconY = math.floor((self.height - self.iconSize) / 2)

    self:renderIcon(iconX, iconY)
    self:renderTextInfo()
    self:renderQuantityText()
    self:renderStatusIcons()
end

-- 渲染图标
function PJCK_CraftInput_Slot:renderIcon(iconX, iconY)
    if not self.DisplayItem then
        return
    end
    
    local alpha = self:isInputSatisfied() and 1.0 or 0.5
    local itemIcon = self.DisplayItem:getNormalTexture()
    
    if self.itemType == "fluidContainer" then
        -- 液体容器：先画容器，再画液体图标
        self:drawTextureScaledAspect(itemIcon, iconX, iconY, self.iconSize, self.iconSize, alpha * 0.5, 1.0, 1.0, 1.0)
        
        -- 获取液体颜色
        local fluidColor = {r=1, g=1, b=1}
        local inputFluids = self.logic:getSatisfiedInputFluids(self.consumeScript)
        if inputFluids:size() == 0 then
            inputFluids = self.consumeScript:getPossibleInputFluids()
        end
        if inputFluids and inputFluids:size() > 0 then
            local c = inputFluids:get(0):getColor()
            fluidColor.r = c:getRedFloat()
            fluidColor.g = c:getGreenFloat()
            fluidColor.b = c:getBlueFloat()
        end
        
        self:drawTextureScaledAspect(
            self.fluidIconTexture, 
            iconX, iconY, 
            self.iconSize, self.iconSize, 
            alpha, 
            fluidColor.r, fluidColor.g, fluidColor.b
        )
    else
        self:drawTextureScaledAspect(itemIcon, iconX, iconY, self.iconSize, self.iconSize, alpha, 1.0, 1.0, 1.0)
    end
end

-- 绘制物品名称
function PJCK_CraftInput_Slot:renderTextInfo()
    if not self.DisplayItem then return end
    
    local textStartX = self.iconAreaWidth + self.padding
    local textAreaWidth = self.width - textStartX - self.padding
    local textScale = 0.8

    local itemName = self:getDisplayName()
    local adjustedTextAreaWidth = textAreaWidth / textScale
    local truncatedName = PJCK_UIHelper.truncateText(itemName, adjustedTextAreaWidth, UIFont.Small, "...")
    
    local textAlpha = self:isInputSatisfied() and 1.0 or 0.5
    
    self:drawTextZoomed(truncatedName, textStartX, self.padding, textScale, 1, 1, 1, textAlpha, UIFont.Small)
end

-- 渲染数量文本
function PJCK_CraftInput_Slot:renderQuantityText()
    local quantityText = self:getQuantityText()
    if not quantityText then return end

    local TextWidth = getTextManager():MeasureStringX(UIFont.Medium, quantityText)

    local padding = self.height / 8
    local textX = math.floor(self.width - TextWidth - padding)
    local textY = math.floor(self.height - FONT_HGT_MEDIUM - padding/4)

    local r, g, b = 1, 1, 1
    if self:isInputSatisfied() then
        r, g, b = 0.3, 1, 0.3
    else
        r, g, b = 1, 0.3, 0.3
    end

    self:drawText(quantityText, textX, textY, r, g, b, 1.0, UIFont.Medium)
end

-- 渲染状态图标
function PJCK_CraftInput_Slot:renderStatusIcons()
    local iconSize = math.floor(FONT_HGT_MEDIUM*0.8)
    local textStartX = self.iconAreaWidth + self.padding
    local iconY = math.floor(self.height - FONT_HGT_MEDIUM)
    local iconSpacing = math.floor(FONT_HGT_SMALL * 0.3)
    
    -- 绘制工具图标
    if self.inputScript and self.inputScript:isKeep() then
        self:drawTextureScaledAspect(self.returnIconTexture, textStartX, iconY, iconSize, iconSize, 0.8, 1.0, 1.0, 1.0)
        textStartX = textStartX + iconSize + iconSpacing
    end
    
    -- 绘制消耗部分图标
    if self.itemType == "usesPartial" then
        self:drawTextureScaledAspect(self.usePartIconTexture, textStartX, iconY, iconSize, iconSize, 0.8, 1.0, 1.0, 1.0)
    end
end

return PJCK_CraftInput_Slot