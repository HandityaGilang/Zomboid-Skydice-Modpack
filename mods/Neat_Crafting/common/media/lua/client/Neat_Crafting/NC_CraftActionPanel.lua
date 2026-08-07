require "ISUI/ISPanel"

NC_CraftActionPanel = ISPanel:derive("NC_CraftActionPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function NC_StopCraftActionCompat(logic, stopAll)
    if not logic or not logic.stopCraftAction then
        return
    end

    -- Build 42.20 added HandcraftLogic:stopCraftAction(stopAll).
    -- Older B42 builds only accept stopCraftAction(), so try the new signature
    -- only when we need to force-stop a cancelled batch and fall back safely.
    if stopAll == true then
        local ok = pcall(function()
            logic:stopCraftAction(true)
        end)
        if ok then
            return
        end
    end

    pcall(function()
        logic:stopCraftAction()
    end)
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftActionPanel:initialise()
    ISPanel.initialise(self)
end

function NC_CraftActionPanel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    o.padding = HandCraftPanel.padding
    o.allowBatchCraft = true

    o.PlusIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_Plus.png")
    o.MinusIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_Minus.png")
    o.TimeIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_Clock.png")

    o.UIElementBGTextures = {
        left = getTexture("media/ui/NeatUI/Button/Button_FULL_L.png"),
        middle = getTexture("media/ui/NeatUI/Button/Button_FULL_M.png"),
        right = getTexture("media/ui/NeatUI/Button/Button_FULL_R.png")
    }

    o.ProgressBGTextures = {
        left = getTexture("media/ui/Neat_Crafting/Progress/Background_L.png"),
        middle = getTexture("media/ui/Neat_Crafting/Progress/Background_M.png"),
        right = getTexture("media/ui/Neat_Crafting/Progress/Background_R.png")
    }

    o.ProgressBarTextures = {
        left = getTexture("media/ui/Neat_Crafting/Progress/Progress_L.png"),
        middle = getTexture("media/ui/Neat_Crafting/Progress/Progress_M.png"),
        right = getTexture("media/ui/Neat_Crafting/Progress/Progress_R.png")
    }
    
    o.CraftButtonTextures = {
        canCraft = getTexture("media/ui/Neat_Crafting/Button/CanCraft.png"),
        canCraftPressed = getTexture("media/ui/Neat_Crafting/Button/CanCraft_Pressed.png"),
        cannotCraft = getTexture("media/ui/Neat_Crafting/Button/CannotCraft.png"),
        cannotCraftPressed = getTexture("media/ui/Neat_Crafting/Button/CannotCraft_Pressed.png")
    }

    o.controlButtonSize = math.floor(HandCraftPanel.titleHeight * 0.8)
    o.maxButtonWidth = o.controlButtonSize * (3/2)
    o.craftbuttonSize = math.floor((height - HandCraftPanel.titleHeight - o.padding*2) * 0.8)
    
    return o
end

function NC_CraftActionPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    self.craftbuttonSize = math.floor((height - self.HandCraftPanel.titleHeight - self.padding) * 0.8)

    self:relayoutCraftButton()

    self:relayoutQuantityControls()

    self:setWidth(width)
    self:setHeight(height)
end

function NC_CraftActionPanel:relayoutCraftButton()
    if self.craftButton then
        local buttonX = (self.width - self.craftbuttonSize) / 2

        local buttonY
        if self.allowBatchCraft then
            buttonY = self.padding
        else
            buttonY = (self.height - self.craftbuttonSize) / 2
        end
        
        self.craftButton:setX(buttonX)
        self.craftButton:setY(buttonY)
        self.craftButton:setWidth(self.craftbuttonSize)
        self.craftButton:setHeight(self.craftbuttonSize)
    end
end

function NC_CraftActionPanel:relayoutQuantityControls()
    if not self.minusButton or not self.quantityInput or not self.plusButton or not self.maxButton then
        return
    end
    
    local bottomPadding = math.floor(FONT_HGT_SMALL / 6)
    local endPadding = math.floor(FONT_HGT_SMALL / 8)
    local controlY = self.height - bottomPadding - self.controlButtonSize

    local textWidth = getTextManager():MeasureStringX(UIFont.Small, "9999")
    local inputPadding = FONT_HGT_SMALL / 4
    local inputWidth = textWidth + inputPadding * 2

    local totalElementsWidth = self.controlButtonSize + inputWidth + self.controlButtonSize + self.maxButtonWidth
    local availableForSpacing = self.width - endPadding * 2 - totalElementsWidth
    local spacing = math.max(math.ceil(availableForSpacing / 3), 2)
    
    local currentX = endPadding
    self.minusButton:setX(currentX)
    self.minusButton:setY(controlY)
    self.minusButton:setWidth(self.controlButtonSize)
    self.minusButton:setHeight(self.controlButtonSize)
    
    currentX = currentX + self.controlButtonSize + spacing
    self.quantityInput:setX(currentX)
    self.quantityInput:setY(controlY)
    self.quantityInput:setWidth(inputWidth)
    self.quantityInput:setHeight(self.controlButtonSize)
    
    currentX = currentX + inputWidth + spacing
    self.plusButton:setX(currentX)
    self.plusButton:setY(controlY)
    self.plusButton:setWidth(self.controlButtonSize)
    self.plusButton:setHeight(self.controlButtonSize)
    
    currentX = currentX + self.controlButtonSize + spacing
    self.maxButton:setX(currentX)
    self.maxButton:setY(controlY)
    self.maxButton:setWidth(self.maxButtonWidth)
    self.maxButton:setHeight(self.controlButtonSize)
end


-- ----------------------------------------------------------------------------------------------------- --
-- Create child elements
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftActionPanel:createChildren()
    self.craftButton = self:createCraftButton(0, 0, 10)
    self.craftButton:initialise()
    self:addChild(self.craftButton)
    self:createQuantityControls()
end

function NC_CraftActionPanel:createCraftButton(x, y, size)
    local button = ISButton:new(x, y, size, size, "", self, self.onCraftButtonClick)
    button.craftState = "cannot"
    button.prerender = function(btn)
        local texture
        if btn.craftState == "can" then
            if btn.pressed then
                texture = self.CraftButtonTextures.canCraftPressed
            else
                texture = self.CraftButtonTextures.canCraft
            end
        else
            if btn.pressed then
                texture = self.CraftButtonTextures.cannotCraftPressed
            else
                texture = self.CraftButtonTextures.cannotCraft
            end
        end
        
        if texture then
            btn:drawTextureScaledAspect(texture, 0, 0, btn.width, btn.height, 1.0, 1.0, 1.0, 1.0)
        end
    end

    button.setCraftState = function(btn, state)
        btn.craftState = state
    end
    
    return button
end

function NC_CraftActionPanel:createQuantityControls()
    self.minusButton = NC_SquareButton:new(0, 0, 10, self.MinusIcon,self, self.onMinusButtonClick)
    self.minusButton:initialise()
    self:addChild(self.minusButton)

    -- Number Text Input
    self.quantityInput = ISTextEntryBox:new("1", 0, 0, 10, 10)
    self.quantityInput:initialise()
    self.quantityInput:instantiate()
    self.quantityInput:setOnlyNumbers(true)
    self.quantityInput.onLostFocus = function() self:onQuantityInputChanged() end
    self.quantityInput.prerender = function(quantityInput)
        NeatTool.ThreePatch.drawHorizontal(
            quantityInput,
            -self.padding/2, 0, quantityInput.width+self.padding, quantityInput.height,
            self.UIElementBGTextures.left,
            self.UIElementBGTextures.middle,
            self.UIElementBGTextures.right,
            1, 0.4, 0.4, 0.4
        )
    end
    self:addChild(self.quantityInput)

    -- PlusButton
    self.plusButton = NC_SquareButton:new(0, 0, 10, self.PlusIcon, self, self.onPlusButtonClick)
    self.plusButton:initialise()
    self:addChild(self.plusButton)

    -- Max Button
    self.maxButton = self:createMaxButton(0, 0, self.maxButtonWidth, self.controlButtonSize)
    self.maxButton:initialise()
    self:addChild(self.maxButton)
end

-- Create MaxButton
function NC_CraftActionPanel:createMaxButton(x, y, width, height)
    local button = ISButton:new(x, y, width, height, "", self, self.onMaxButtonClick)
    button.maxButtonTexture = getTexture("media/ui/Neat_Crafting/Button/MaxCraft_Button.png")
    button.maxButtonIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_MaxCraft.png")
    button.prerender = function(btn)
        local alpha = 0.8
        local brightness = (btn.pressed and 0.3) or (btn:isMouseOver() and 0.6) or 0.4
        btn:drawTextureScaledAspect(btn.maxButtonTexture, 0, 0, btn.width, btn.height, alpha, brightness, brightness, brightness)
        btn:drawTextureScaledAspect(btn.maxButtonIcon, 0, 0, btn.width, btn.height, 1, 0.9, 0.9, 0.9)
    end
    
    return button
end
-- ----------------------------------------------------------------------------------------------------- --
-- Start crafting
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftActionPanel:onCraftButtonClick()
    if self.logic:isCraftActionInProgress() then return end
    
    if not self.logic:cachedCanPerformCurrentRecipe() then return end

    local craftQuantity = 1
    if self.allowBatchCraft then
        craftQuantity = tonumber(self.quantityInput:getText()) or 1
        local maxCount = self.logic:getPossibleCraftCount(true)
        craftQuantity = math.max(1, math.min(maxCount, craftQuantity))
    end
    
    self:startHandcraft(false, craftQuantity)
end

-- Start crafting
function NC_CraftActionPanel:startHandcraft(force, craftTimes)
    if (not self.logic) or self.logic:isCraftActionInProgress() then
        return
    end

    craftTimes = craftTimes or 1
    self.craftTimes = craftTimes
    self.returnToContainer = {}
    self.queuedCraftActions = {}

    local actions = ISEntityUI.HandcraftStartMultiple(self.player, self.logic, force, craftTimes, false)
    if not actions then 
        self.craftTimes = nil
        return 
    end

    for k, action in ipairs(actions) do
        if action then
            -- Track each queued craft action so the UI can follow the real active timed action.
            self.queuedCraftActions[action] = true

            action:setOnStart(self.onHandcraftActionStart, self)
            action:setOnComplete(self.onHandcraftActionComplete, self)
            action:setOnCancel(self.onHandcraftActionCancelled, self)
            ISTimedActionQueue.add(action)
        end
    end
end

-- Craft action start callback
function NC_CraftActionPanel:onHandcraftActionStart(action)
    self.logic:startCraftAction(action)

    -- Keep the craft button hidden for every action inside a batch so the progress bar stays visible.
    if self.craftButton and self.craftButton.setVisible then
        self.craftButton:setVisible(false)
    end
end

-- Refresh crafting data once after the batch ends/cancels, instead of once per crafted item.
function NC_CraftActionPanel:isBatchCraftQueued()
    return self.craftTimes ~= nil and self.craftTimes > 0
end

function NC_CraftActionPanel:getQueuedCraftAction()
    local timedActionQueue = ISTimedActionQueue.getTimedActionQueue(self.player)
    if not timedActionQueue or not timedActionQueue.queue then
        return nil
    end

    local currentAction = timedActionQueue.queue[1]
    if currentAction and self.queuedCraftActions and self.queuedCraftActions[currentAction] then
        return currentAction
    end

    return nil
end

function NC_CraftActionPanel:getDisplayCraftAction()
    -- Prefer the actual front-of-queue action so the progress bar survives the gap between chained batch crafts.
    local queuedCraftAction = self:getQueuedCraftAction()
    if queuedCraftAction then
        return queuedCraftAction
    end

    if self.logic and self.logic.isCraftActionInProgress and self.logic:isCraftActionInProgress() then
        return self.logic:getCraftActionTable()
    end

    return nil
end

function NC_CraftActionPanel:refreshAfterCraftBatch()
    -- Re-scan nearby containers only once so the next craft state uses the latest inventory snapshot.
    if self.HandCraftPanel and self.HandCraftPanel.updateContainers then
        self.HandCraftPanel:updateContainers()
    end

    -- Rebuild the currently selected recipe inputs once after the batch completes.
    if self.logic and self.logic.autoPopulateInputs then
        self.logic:autoPopulateInputs()
    end

    -- Re-sort and refresh the recipe list once, matching vanilla's deferred refresh behavior.
    if self.logic and self.logic.sortRecipeList then
        self.logic:sortRecipeList()
    end

    -- Update the recipe details panel once after the deferred refresh.
    if self.HandCraftPanel and self.HandCraftPanel.recipeInfoPanel and self.HandCraftPanel.recipeInfoPanel.onRecipeChanged then
        self.HandCraftPanel.recipeInfoPanel:onRecipeChanged()
    end
end

-- Craft action complete callback
function NC_CraftActionPanel:onHandcraftActionComplete()
    -- In Multiplayer, HandcraftLogic.stopCraftAction() is ref-counted (numCraftActionInProgress).
    -- Call stopCraftAction() ONCE per completed action to balance onHandcraftActionStart().
    NC_StopCraftActionCompat(self.logic, false)

    if self.craftTimes then
        self.craftTimes = self.craftTimes - 1

        -- Keep the remaining quantity in sync without triggering a full container/input refresh per item.
        if self.craftTimes > 0 then
            if self.quantityInput and self.quantityInput.setText then
                self.quantityInput:setText(tostring(self.craftTimes))
            end
            self.currentCraftQuantity = self.craftTimes
            return
        end

        -- Batch finished: restore the default quantity and do one deferred refresh.
        self.craftTimes = nil
        if self.quantityInput and self.quantityInput.setText then
            self.quantityInput:setText("1")
        end
        self.currentCraftQuantity = 1

        self.queuedCraftActions = nil
        self:refreshAfterCraftBatch()

        -- Return items to original containers only once after the batch is fully done.
        if self.returnToContainer and #self.returnToContainer > 0 then
            ISCraftingUI.ReturnItemsToOriginalContainer(self.player, self.returnToContainer)
        end
        return
    end

    -- Single craft fallback: keep the UI state consistent and refresh once.
    if self.quantityInput and self.quantityInput.setText then
        self.quantityInput:setText("1")
    end
    self.currentCraftQuantity = 1
    self.queuedCraftActions = nil
    self:refreshAfterCraftBatch()
end

-- Craft action cancel callback
function NC_CraftActionPanel:onHandcraftActionCancelled()
    NC_StopCraftActionCompat(self.logic, true)
    self.craftTimes = nil

    if self.quantityInput and self.quantityInput.setText then
        self.quantityInput:setText("1")
    end
    self.currentCraftQuantity = 1
    self.queuedCraftActions = nil

    -- Apply the same deferred refresh path when the queued batch is interrupted.
    self:refreshAfterCraftBatch()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Event handling
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftActionPanel:onMinusButtonClick()
    if self.logic:isCraftActionInProgress() then return end
    
    local currentValue = tonumber(self.quantityInput:getText()) or 1
    local newValue = math.max(1, currentValue - 1)
    self.quantityInput:setText(tostring(newValue))
    self.currentCraftQuantity = newValue
end

function NC_CraftActionPanel:onPlusButtonClick()
    if self.logic:isCraftActionInProgress() then return end

    local currentValue = tonumber(self.quantityInput:getText()) or 1
    local maxCount = self.logic:getPossibleCraftCount(true)
    local newValue = math.min(maxCount, currentValue + 1)
    self.quantityInput:setText(tostring(newValue))
    self.currentCraftQuantity = newValue
end

function NC_CraftActionPanel:onQuantityInputChanged()
    if self.logic:isCraftActionInProgress() then return end

    local inputText = self.quantityInput:getText()
    local value = tonumber(inputText) or 1
    local maxCount = self.logic:getPossibleCraftCount(true)

    if value < 1 then
        value = 1
    elseif value > maxCount then
        value = maxCount
    end
    
    self.quantityInput:setText(tostring(value))
    self.currentCraftQuantity = value
end

function NC_CraftActionPanel:onMaxButtonClick()
    if self.logic:isCraftActionInProgress() then return end

    local maxCount = self.logic:getPossibleCraftCount(false)
    self.quantityInput:setText(tostring(maxCount))
    self.currentCraftQuantity = maxCount
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update status
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftActionPanel:updateCraftAction()
    if not self.craftButton then return end

    local canCraft = false
    local maxCount = 1
    local displayAction = self:getDisplayCraftAction()
    local isCrafting = displayAction ~= nil
    local isBatchQueued = self:isBatchCraftQueued()
    
    local recipe = self.logic:getRecipe()
    if recipe then
        canCraft = self.logic:canPerformCurrentRecipe()
        maxCount = self.logic:getPossibleCraftCount(true)
    end

    if isCrafting or isBatchQueued then
        self.craftButton:setVisible(false)
    else
        self.craftButton:setVisible(true)
        self.craftButton:setCraftState(canCraft and "can" or "cannot")
    end
    self.maxCraftQuantity = maxCount
    
    if not isCrafting and self.quantityInput then
        local currentValue = tonumber(self.quantityInput:getText()) or 1
        if currentValue > maxCount then
            local newValue = math.max(1, maxCount)
            self.quantityInput:setText(tostring(newValue))
            self.currentCraftQuantity = newValue
        end
    end
end

function NC_CraftActionPanel:getCraftProgress()
    local action = self:getDisplayCraftAction()
    if action then
        return action:getJobDelta()
    end

    return 0
end

function NC_CraftActionPanel:getRemainingTime()
    local action = self:getDisplayCraftAction()
    if action then
        local progress = action:getJobDelta()
        local totalTicks = action:getDuration()
        local remainingTicks = totalTicks * (1 - progress)

        local gameSpeed = getGameSpeed()
        if gameSpeed <= 0 then
            gameSpeed = 1
        end
        local remainingTime = (remainingTicks / 60) / gameSpeed

        return remainingTime
    end

    return 0
end

function NC_CraftActionPanel:onRecipeChanged()
    local recipe = self.logic:getRecipe()
    self.allowBatchCraft = recipe:isAllowBatchCraft()
    if self.minusButton then self.minusButton:setVisible(self.allowBatchCraft) end
    if self.quantityInput then self.quantityInput:setVisible(self.allowBatchCraft) end
    if self.plusButton then self.plusButton:setVisible(self.allowBatchCraft) end
    if self.maxButton then self.maxButton:setVisible(self.allowBatchCraft) end
    if self.craftButton then
        local buttonY = self.allowBatchCraft and self.padding or ((self.height - self.craftbuttonSize) / 2)
        self.craftButton:setY(buttonY)
    end
end
-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftActionPanel:prerender()
    local panelBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/InnerPanel_BG.png")
    if panelBG then
        panelBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, NCConfig.actionBackgroundAlpha)
    end
end

function NC_CraftActionPanel:render()
    if self:getDisplayCraftAction() then
        self:drawCraftProgressBar()
    end
end

function NC_CraftActionPanel:drawCraftProgressBar()
    local progressX = self.craftButton:getX()
    local progressY = self.craftButton:getY()
    local progressWidth = math.floor(self.width * 0.8)
    local progressHeight = math.floor(FONT_HGT_SMALL * 1.2)

    progressX = (self.width - progressWidth) / 2
    progressY = self.craftButton:getY() + (self.craftButton:getHeight() - progressHeight) / 2
    
    -- Draw Background
    NeatTool.ThreePatch.drawHorizontal(
        self,
        progressX, progressY, progressWidth, progressHeight,
        self.ProgressBGTextures.left,
        self.ProgressBGTextures.middle,
        self.ProgressBGTextures.right,
        0.8, 0.4, 0.4, 0.4
    )
    
    -- Draw Progress
    local progress = self:getCraftProgress()
    if progress > 0 then
        local fillWidth = math.floor(progressWidth * progress)
        
        self:setStencilRect(progressX, progressY, fillWidth, progressHeight)
        NeatTool.ThreePatch.drawHorizontal(
            self,
            progressX, progressY, progressWidth, progressHeight,
            self.ProgressBarTextures.left,
            self.ProgressBarTextures.middle,
            self.ProgressBarTextures.right,
            1.0, 0.2, 0.8, 0.4
        )
        
        self:clearStencilRect()
    end
    
    -- Draw Remining Time
    local remainingTime = self:getRemainingTime()
    if remainingTime > 0 then
        local timeText = string.format("%.1f", remainingTime).."s"
        local font = UIFont.Small
        local textWidth = getTextManager():MeasureStringX(font, timeText)
        local textHeight = getTextManager():MeasureStringY(font, timeText)

        local textX = progressX + progressWidth - textWidth - FONT_HGT_SMALL/8
        local textY = progressY - textHeight - FONT_HGT_SMALL/16

        self:drawText(timeText, textX, textY, 1, 1, 1, 1, font)
    end
end

return NC_CraftActionPanel