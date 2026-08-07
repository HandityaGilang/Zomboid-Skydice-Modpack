require "ISUI/ISPanel"

PJCK_CraftActionPanel = ISPanel:derive("PJCK_CraftActionPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftActionPanel:initialise()
    ISPanel.initialise(self)
end

function PJCK_CraftActionPanel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic

    o.contentBgTextures = {
        topLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LT2.png"),
        top = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_T2.png"),
        topRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RT2.png"),
        left = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_M.png"),
        right = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_R.png"),
        bottomLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LB.png"),
        bottom = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_B.png"),
        bottomRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RB.png")
    }

    o.UIElementBGTextures = {
        left = getTexture("media/ui/Project_Cook/Button/Button_BG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Button/Button_BG_M.png"),
        right = getTexture("media/ui/Project_Cook/Button/Button_BG_R.png")
    }

    o.ProgressBGTextures = {
        left = getTexture("media/ui/Project_Cook/Button/ProgressBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Button/ProgressBG_M.png"),
        right = getTexture("media/ui/Project_Cook/Button/ProgressBG_R.png")
    }

    o.ProgressBarTextures = {
        left = getTexture("media/ui/Project_Cook/Button/ProgressBar_L.png"),
        middle = getTexture("media/ui/Project_Cook/Button/ProgressBar_M.png"),
        right = getTexture("media/ui/Project_Cook/Button/ProgressBar_R.png")
    }
    
    -- 制作按钮相关
    o.craftButton = nil
    o.buttonSize = math.floor(FONT_HGT_SMALL * 3)

    o.minusButton = nil
    o.plusButton = nil
    o.maxButton = nil
    o.quantityInput = nil
    o.controlButtonSize = math.floor(FONT_HGT_SMALL*1.2)
    o.maxButtonWidth = o.controlButtonSize * (3/2)
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- 创建子元素
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftActionPanel:createChildren()
    local Padding = FONT_HGT_SMALL / 2
    local buttonX = (self.width - self.buttonSize) / 2

    self.craftButton = PJCK_SquareButton.createCraftButton(buttonX, Padding, self.buttonSize, self, self.onCraftButtonClick)
    self.craftButton:initialise()
    self:addChild(self.craftButton)

    -- 创建底部数量控制区域
    self:createQuantityControls()
end

function PJCK_CraftActionPanel:createQuantityControls()
    local bottomPadding = math.floor(FONT_HGT_SMALL / 6)
    local endPadding = math.floor(FONT_HGT_SMALL / 8)
    local controlY = self.height - bottomPadding - self.controlButtonSize
    
    -- 计算输入框宽度
    local textWidth = getTextManager():MeasureStringX(UIFont.Small, "9999")
    local inputPadding = FONT_HGT_SMALL / 4
    local inputWidth = textWidth + inputPadding * 2
    
    -- 计算可用于间距的空间
    local totalElementsWidth = self.controlButtonSize + inputWidth + self.controlButtonSize + self.maxButtonWidth
    local availableForSpacing = self.width - endPadding * 2 - totalElementsWidth
    local spacing = math.ceil(availableForSpacing / 3)

    -- 创建减号按钮
    local currentX = endPadding
    self.minusButton = PJCK_SquareButton.createMinusButton(
        currentX, 
        controlY, 
        self.controlButtonSize, 
        self, 
        self.onMinusButtonClick
    )
    self.minusButton:initialise()
    self:addChild(self.minusButton)

    -- 创建输入框
    currentX = currentX + self.controlButtonSize + spacing
    self.quantityInput = ISTextEntryBox:new("1", currentX, controlY, inputWidth, 0)
    self.quantityInput:initialise()
    self.quantityInput:instantiate()
    self.quantityInput:setOnlyNumbers(true)
    self.quantityInput.onLostFocus = function() 
        self:onQuantityInputChanged() 
    end
    self.quantityInput.prerender = function(quantityInput)
        PJCK_UIHelper.drawThreeSlice(
            quantityInput,
            -spacing/2, 0, quantityInput.width+spacing, quantityInput.height,
            self.UIElementBGTextures.left,
            self.UIElementBGTextures.middle,
            self.UIElementBGTextures.right,
            0.8, 0.4, 0.4, 0.4
        )
    end
    self:addChild(self.quantityInput)

    -- 创建加号按钮
    currentX = currentX + inputWidth + spacing
    self.plusButton = PJCK_SquareButton.createPlusButton(
        currentX, 
        controlY, 
        self.controlButtonSize, 
        self, 
        self.onPlusButtonClick
    )
    self.plusButton:initialise()
    self:addChild(self.plusButton)

    -- 创建最大数量按钮
    currentX = currentX + self.controlButtonSize + spacing
    self.maxButton = self:createMaxButton(
        currentX,
        controlY,
        self.maxButtonWidth,
        self.controlButtonSize
    )
    self.maxButton:initialise()
    self:addChild(self.maxButton)
end

-- 创建最大数量按钮
function PJCK_CraftActionPanel:createMaxButton(x, y, width, height)
    local button = ISButton:new(x, y, width, height, "", self, self.onMaxButtonClick)
    
    -- 加载贴图
    button.maxButtonTexture = getTexture("media/ui/Project_Cook/Button/MaxCraft_Button.png")
    button.maxButtonIcon = getTexture("media/ui/Project_Cook/ICON/Icon_MaxCraft.png")
    button.prerender = function(btn)
        local alpha = 0.8
        local brightness = 0.4
        
        if btn.pressed then
            brightness = 0.3
        elseif btn:isMouseOver() then
            brightness = 0.6
        end

        btn:drawTextureScaledAspect(btn.maxButtonTexture, 0, 0, btn.width, btn.height, alpha, brightness, brightness, brightness)
        btn:drawTextureScaledAspect(btn.maxButtonIcon, 0, 0, btn.width, btn.height, 1, 0.9, 0.9, 0.9)
    end
    
    return button
end

-- ----------------------------------------------------------------------------------------------------- --
-- 开始制作
-- ----------------------------------------------------------------------------------------------------- --

function PJCK_CraftActionPanel:onCraftButtonClick()
    if self.logic:isCraftActionInProgress() then return end
    
    if not self.logic:cachedCanPerformCurrentRecipe() then return end

    local craftQuantity = tonumber(self.quantityInput:getText()) or 1
    local maxCount = self.logic:getPossibleCraftCount(true)
    craftQuantity = math.max(1, math.min(maxCount, craftQuantity))

    self:startHandcraft(false, craftQuantity)
end

-- 开始制作
function PJCK_CraftActionPanel:startHandcraft(force, craftTimes)
    if (not self.logic) or self.logic:isCraftActionInProgress() then
        return
    end

    craftTimes = craftTimes or 1
    self.craftTimes = craftTimes
    self.returnToContainer = {}

    local actions = ISEntityUI.HandcraftStartMultiple(self.player, self.logic, force, craftTimes, false)
    if not actions then 
        self.craftTimes = nil
        return 
    end

    for k, action in ipairs(actions) do
        if action then
            action:setOnStart(self.onHandcraftActionStart, self)
            action:setOnComplete(self.onHandcraftActionComplete, self)
            action:setOnCancel(self.onHandcraftActionCancelled, self)
            ISTimedActionQueue.add(action)
        end
    end
end

-- 制作动作开始回调
function PJCK_CraftActionPanel:onHandcraftActionStart(action)
    self.logic:startCraftAction(action)
end

-- 制作动作完成回调
function PJCK_CraftActionPanel:onHandcraftActionComplete()
    -- 先更新剩余制作次数
    if self.craftTimes then
        self.craftTimes = self.craftTimes - 1

        self.HandCraftPanel:updateContainers()
        self.logic:autoPopulateInputs()
        self.logic:sortRecipeList()

        -- 更新文本框显示剩余次数
        if self.craftTimes > 0 then
            self.quantityInput:setText(tostring(self.craftTimes))
            self.currentCraftQuantity = self.craftTimes
        end
        
        -- 只有在所有制作都完成后才停止制作状态
        if self.craftTimes <= 0 then
            self.craftTimes = nil
            self.logic:stopCraftAction()
            
            -- 制作完成后，重置为1
            self.quantityInput:setText("1")
            self.currentCraftQuantity = 1
            
            -- 处理物品归还
            if self.returnToContainer and #self.returnToContainer > 0 then
                ISCraftingUI.ReturnItemsToOriginalContainer(self.player, self.returnToContainer)
            end
        end
    else
        -- 如果没有批量制作计数，直接停止（单次制作）
        self.logic:stopCraftAction()
        self.quantityInput:setText("1")
        self.currentCraftQuantity = 1
    end
end

-- 制作动作取消回调
function PJCK_CraftActionPanel:onHandcraftActionCancelled()
    self.logic:stopCraftAction()
    self.craftTimes = nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- 事件处理
-- ----------------------------------------------------------------------------------------------------- --

function PJCK_CraftActionPanel:onMinusButtonClick()
    if self.logic:isCraftActionInProgress() then return end
    
    local currentValue = tonumber(self.quantityInput:getText()) or 1
    local newValue = math.max(1, currentValue - 1)
    self.quantityInput:setText(tostring(newValue))
    self.currentCraftQuantity = newValue
end

function PJCK_CraftActionPanel:onPlusButtonClick()
    if self.logic:isCraftActionInProgress() then return end

    local currentValue = tonumber(self.quantityInput:getText()) or 1
    local maxCount = self.logic:getPossibleCraftCount(true)
    local newValue = math.min(maxCount, currentValue + 1)
    self.quantityInput:setText(tostring(newValue))
    self.currentCraftQuantity = newValue
end

function PJCK_CraftActionPanel:onQuantityInputChanged()
    if self.logic:isCraftActionInProgress() then return end

    local inputText = self.quantityInput:getText()
    local value = tonumber(inputText) or 1
    local maxCount = self.logic:getPossibleCraftCount(true)
    
    -- 限制范围
    if value < 1 then
        value = 1
    elseif value > maxCount then
        value = maxCount
    end
    
    self.quantityInput:setText(tostring(value))
    self.currentCraftQuantity = value
end

function PJCK_CraftActionPanel:onMaxButtonClick()
    if self.logic:isCraftActionInProgress() then return end

    local maxCount = self.logic:getPossibleCraftCount(true)
    self.quantityInput:setText(tostring(maxCount))
    self.currentCraftQuantity = maxCount
end

-- ----------------------------------------------------------------------------------------------------- --
-- 状态更新方法
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftActionPanel:updateCraftAction()
    if not self.craftButton then return end

    local canCraft = false
    local maxCount = 1
    local isCrafting = self.logic:isCraftActionInProgress()
    
    local recipe = self.logic:getRecipe()
    if recipe then
        canCraft = self.logic:canPerformCurrentRecipe()
        maxCount = self.logic:getPossibleCraftCount(true)
    end

    if isCrafting then
        self.craftButton:setVisible(false)
    else
        self.craftButton:setVisible(true)
        self.craftButton:setCraftState(canCraft and "can" or "cannot")
    end
    self.maxCraftQuantity = maxCount
    
    -- 确保当前数量不超过最大数量
    if not isCrafting and self.quantityInput then
        local currentValue = tonumber(self.quantityInput:getText()) or 1
        if currentValue > maxCount then
            local newValue = math.max(1, maxCount)
            self.quantityInput:setText(tostring(newValue))
            self.currentCraftQuantity = newValue
        end
    end
end

function PJCK_CraftActionPanel:getCraftProgress()
    if not self.logic:isCraftActionInProgress() then
        return 0
    end
    
    local action = self.logic:getCraftActionTable()
    if action then
        return action:getJobDelta()
    end
    
    return 0
end

function PJCK_CraftActionPanel:getRemainingTime()
    if not self.logic:isCraftActionInProgress() then
        return 0
    end
    
    local action = self.logic:getCraftActionTable()
    if action then
        local progress = action:getJobDelta()
        local totalTicks = action:getDuration()
        local remainingTicks = totalTicks * (1 - progress)
        
        -- 转换为真实秒数
        local gameSpeed = getGameSpeed()
        local remainingTime = (remainingTicks / 60) / gameSpeed
        
        return remainingTime
    end
    
    return 0
end------------------------------------------------------------------------------------------------- --
-- 更新函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftActionPanel:update()
    ISPanel.update(self)
end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftActionPanel:prerender()
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        0,
        self.width,
        self.height,
        self.contentBgTextures,
        1.0, 0.1, 0.1, 0.1
    )
end

function PJCK_CraftActionPanel:render()
    if self.logic:isCraftActionInProgress() then
        self:drawCraftProgressBar()
    end
end

-- 绘制进度条
function PJCK_CraftActionPanel:drawCraftProgressBar()
    -- 计算进度条位置
    local progressX = self.craftButton:getX()
    local progressY = self.craftButton:getY()
    local progressWidth = math.floor(self.width * 0.8)
    local progressHeight = math.floor(FONT_HGT_SMALL * 1.2)

    progressX = (self.width - progressWidth) / 2
    progressY = self.craftButton:getY() + (self.craftButton:getHeight() - progressHeight) / 2
    
    -- 绘制进度条背景
    PJCK_UIHelper.drawThreeSlice(
        self,
        progressX, progressY, progressWidth, progressHeight,
        self.ProgressBGTextures.left,
        self.ProgressBGTextures.middle,
        self.ProgressBGTextures.right,
        0.8, 0.4, 0.4, 0.4
    )
    
    -- 绘制进度条
    local progress = self:getCraftProgress()
    if progress > 0 then
        local fillWidth = math.floor(progressWidth * progress)
        
        self:setStencilRect(progressX, progressY, fillWidth, progressHeight)
        
        PJCK_UIHelper.drawThreeSlice(
            self,
            progressX, progressY, progressWidth, progressHeight,
            self.ProgressBarTextures.left,
            self.ProgressBarTextures.middle,
            self.ProgressBarTextures.right,
            1.0, 0.2, 0.8, 0.4
        )
        
        self:clearStencilRect()
    end
    
    -- 绘制剩余时间
    local remainingTime = self:getRemainingTime()
    if remainingTime > 0 then
        local timeText = string.format("%.1f", remainingTime).."s"
        local font = UIFont.Small
        local textWidth = getTextManager():MeasureStringX(font, timeText)
        local textHeight = getTextManager():MeasureStringY(font, timeText)

        local textX = progressX + progressWidth - textWidth - FONT_HGT_SMALL/8
        local textY = progressY - textHeight - FONT_HGT_SMALL/16
        
        -- 绘制文本
        self:drawText(timeText, textX, textY, 1, 1, 1, 1, font)
    end
end

return PJCK_CraftActionPanel