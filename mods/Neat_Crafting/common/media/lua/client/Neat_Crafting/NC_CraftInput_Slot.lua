require "ISUI/ISUIElement"

NC_CraftInput_Slot = ISUIElement:derive("NC_CraftInput_Slot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- Constructor and initialization
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftInput_Slot:initialise()
    ISUIElement.initialise(self)
    self:updateInputInfo()
end

function NC_CraftInput_Slot:new(x, y, width, height, player, inputScript, parentpanel)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.player = player
    o.inputScript = inputScript
    o.parentpanel = parentpanel
    o.logic = parentpanel.logic

    o.iconSize = math.floor((height * 0.6) / 8 ) * 8
    o.iconAreaWidth = height
    o.padding = math.floor(height * 0.1)
    
    o.DisplayItem = nil
    o.actualInventoryItem = nil
    o.itemType = "normal" -- normal, fluidContainer, usesPartial
    o.consumeScript = nil
    o.tooltip = nil

    o.usePartIconTexture = getTexture("media/ui/Neat_Crafting/ICON/Icon_UsePart.png")
    o.fluidIconTexture = getTexture("media/textures/Item_Waterdrop_Grey.png")
    o.returnIconTexture = getTexture("media/ui/Neat_Crafting/ICON/Icon_CraftReturn.png")
    
    return o
end


-- ----------------------------------------------------------------------------------------------------- --
-- Get item info
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftInput_Slot:updateInputInfo()
    if not self.inputScript or not self.logic then return end
    
    -- Manual > Assigned > Available > Script
    self.actualInventoryItem = self:getBestInventoryItem()
    self.DisplayItem = self.actualInventoryItem and self.actualInventoryItem:getScriptItem() or self:getScriptItem()
    
    -- Set type
    self:updateItemType()
end

-- Get best inventory item
function NC_CraftInput_Slot:getBestInventoryItem()
    local manualItem = self.logic:getRecipeData():getFirstManualInputFor(self.inputScript)
    if manualItem then return manualItem end

    local satisfiedItems = self.logic:getSatisfiedInputInventoryItems(self.inputScript)
    if satisfiedItems and satisfiedItems:size() > 0 then return satisfiedItems:get(0) end

    local inputItemNodes = self.logic:getInputItemNodesForInput(self.inputScript)
    if inputItemNodes and inputItemNodes:size() > 0 then
        local nodeItems = inputItemNodes:get(0):getItems()
        if nodeItems and nodeItems:size() > 0 then return nodeItems:get(0) end
    end
    
    return nil
end

-- Get script item
function NC_CraftInput_Slot:getScriptItem()
    local possibleItems = self.inputScript:getPossibleInputItems()
    return possibleItems and possibleItems:size() > 0 and possibleItems:get(0) or nil
end

-- Update item type
function NC_CraftInput_Slot:updateItemType()
    if self.inputScript:hasConsumeFromItem() then
        local consumeScript = self.inputScript:getConsumeFromItemScript()
        if consumeScript:getResourceType() == ResourceType.Fluid then
            self.itemType = "fluidContainer"
            self.consumeScript = consumeScript
            return
        end
    end
    
    if self.DisplayItem and self.inputScript:isUsesPartialItem(self.DisplayItem) then
        self.itemType = "usesPartial"
    end
end


-- ----------------------------------------------------------------------------------------------------- --
-- Helper methods
-- ----------------------------------------------------------------------------------------------------- --

-- ------------------------------------------------------------------------------
-- Helpers (vanilla-like amount handling)
-- ------------------------------------------------------------------------------

local function _ncIsNearlyInt(n)
    -- This mirrors vanilla-style formatting where integers are displayed without decimals.
    if type(n) ~= "number" then return false end
    return math.abs(n - math.floor(n + 0.0001)) < 0.0001
end

local function _ncFormatNumber(n)
    -- Formats counts/uses in a compact way for the slot UI.
    if n == nil then return "0" end
    if type(n) ~= "number" then return tostring(n) end
    if _ncIsNearlyInt(n) then
        return tostring(math.floor(n + 0.0001))
    end
    return string.format("%.2f", n)
end

function NC_CraftInput_Slot:_getRequiredAmountInfo()
    -- Returns (amount, maxAmount) using fullType-specific overrides when available.
    -- In Build 42, some inputs (especially partial-use/drainables) store real requirements in getAmount(fullType)/getMaxAmount(fullType).
    if not self.inputScript then
        return 0, 0
    end

    local fullType = (self.DisplayItem and self.DisplayItem.getFullName) and self.DisplayItem:getFullName() or nil

    local amount = (self.inputScript.getIntAmount and self.inputScript:getIntAmount()) or 0
    local maxAmount = amount

    if self.inputScript.getIntMaxAmount then
        maxAmount = self.inputScript:getIntMaxAmount() or maxAmount
    end

    if fullType and self.inputScript.getAmount then
        local specific = self.inputScript:getAmount(fullType) or 0
        if specific > 0 then
            amount = specific
        end
    end

    if fullType and self.inputScript.getMaxAmount then
        local specificMax = self.inputScript:getMaxAmount(fullType) or 0
        if specificMax > 0 then
            maxAmount = specificMax
        end
    end

    if maxAmount <= 0 then
        maxAmount = amount
    end

    return amount or 0, maxAmount or 0
end

function NC_CraftInput_Slot:_getConsumeAmountText()
    -- Returns a string used in tooltips: either "N" or "N - M" for variable amounts.
    local amount, maxAmount = self:_getRequiredAmountInfo()
    if self.inputScript and self.inputScript.isVariableAmount and self.inputScript:isVariableAmount() and maxAmount > amount then
        return tostring(amount) .. " - " .. tostring(maxAmount)
    end
    return tostring(amount)
end
function NC_CraftInput_Slot:getQuantityText()
    if not self.DisplayItem or not self.inputScript then
        return nil
    end

    if self.itemType == "fluidContainer" then
        -- Fluid containers: show current/required fluid amount.
        local amount = self.consumeScript:getAmount()
        local satisfiedAmount = self.logic:getInputUses(self.consumeScript)
        return string.format("%.1f / %.1fL", satisfiedAmount, amount)
    end

    -- Items (normal + usesPartial): vanilla-like required/max amount handling.
    local satisfiedAmount = self.logic:getInputCount(self.inputScript)
    local amount, maxAmount = self:_getRequiredAmountInfo()

    local denom = (maxAmount and maxAmount > 0) and maxAmount or amount
    if denom and denom > 0 then
        return _ncFormatNumber(satisfiedAmount) .. " / " .. _ncFormatNumber(denom)
    end

    -- If the script doesn't provide a usable required amount, only show a value when we have something meaningful.
    if satisfiedAmount and satisfiedAmount > 0 then
        return _ncFormatNumber(satisfiedAmount)
    end

    return nil
end

function NC_CraftInput_Slot:getDisplayName()
    if not self.DisplayItem then
        return ""
    end
    
    if self.itemType == "fluidContainer" then
        -- fluidContainer Name:fluid(Container)
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
        return self.DisplayItem:getDisplayName()
    end
end

function NC_CraftInput_Slot:isInputSatisfied()
    if not self.inputScript then
        return false
    end
    
    local satisfied = self.logic:isInputSatisfied(self.inputScript)

    if self.itemType == "fluidContainer" and self.consumeScript then
        satisfied = satisfied and self.logic:isInputSatisfied(self.consumeScript)
    end
    
    return satisfied
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftInput_Slot:createTooltip()
    if self.tooltip then return end
    
    local displayName = self:getDisplayName() 
    self.tooltip = ISToolTip:new()
    self.tooltip:initialise()
    self.tooltip:instantiate()
    self.tooltip:setOwner(self)
    self.tooltip:setName(displayName)

    -- WillBeKept,WillBeConsume,WillBeDestroyed
    local description = ""
    if self.inputScript and self.inputScript:isKeep() then
        description = getText("IGUI_CraftingWindow_WillBeKept")
    elseif self.itemType == "usesPartial" then
        -- usesPartial: use fullType-aware amounts (and support variable ranges) so tooltips match vanilla behavior.
        local consumeAmountText = self:_getConsumeAmountText()
        description = getText("IGUI_CraftingWindow_WillBeConsume", consumeAmountText)
    else
        description = getText("IGUI_CraftingWindow_WillBeDestroyed")
    end
    
    -- [Check if update] Inputitem detail(copy from ISWidgetIngredients)
    if self.inputScript then
        if self.inputScript:isSharpenable() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsSharpenable")
        end
        if self.inputScript:mayDegrade() and self.inputScript:isKeep() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_MayDegrade")
        end
        if self.inputScript:mayDegradeLight() and self.inputScript:isKeep() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_MayDegradeLight")
        end
        if self.inputScript:mayDegradeVeryLight() and self.inputScript:isKeep() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_MayDegradeLight")
        end
        if self.inputScript:sharpnessCheck() and self.inputScript:isKeep() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_SharpnessCheck")
        end
        if self.inputScript:mayDegradeHeavy() and self.inputScript:isKeep() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_MayDegradeHeavy")
        end
        if self.inputScript:isNotDull() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsNotDull")
        end
        if self.inputScript:isWorn() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsWorn")
        end
        if self.inputScript:isNotWorn() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsNotWorn")
        end
        if self.inputScript:isFull() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsFull")
        end
        if self.inputScript:isEmpty() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsEmpty")
        end
        if self.inputScript:notFull() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_NotFull")
        end
        if self.inputScript:notEmpty() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_NotEmpty")
        end
        if self.inputScript:isDamaged() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsDamaged")
        end
        if self.inputScript:isUndamaged() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsUndamaged")
        end
        if self.inputScript:allowFrozenItem() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_AllowFrozenItem")
        end
        if self.inputScript:allowRottenItem() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_AllowRottenItem")
        end
        if self.inputScript:allowDestroyedItem() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_AllowDestroyedItem")
        end
        if self.inputScript:isEmptyContainer() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsEmptyContainer")
        end
        if self.inputScript:isWholeFoodItem() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsWholeFoodItem")
        end
        if self.inputScript:isUncookedFoodItem() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsUncookedFoodItem")
        end
        if self.inputScript:isCookedFoodItem() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsCookedFoodItem")
        end
        if self.inputScript:isHeadPart() then
            description = description .. " <BR> " .. getText("IGUI_CraftingWindow_IsHeadPart")
        end
    end
    
    self.tooltip:setDescription(description)  
    self.tooltip:addToUIManager()
    self.tooltip:setVisible(true)
end

function NC_CraftInput_Slot:removeTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Interactive
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftInput_Slot:onMouseMove(dx, dy)
    if self:isMouseOver() and not self.tooltip then
        self:createTooltip()
    end
    return true
end

function NC_CraftInput_Slot:onMouseMoveOutside(dx, dy)
    self:removeTooltip()
    return true
end

function NC_CraftInput_Slot:onMouseDown(x, y)
    self:removeTooltip()
    getSoundManager():playUISound("UIActivateButton")

    -- Input and output pickers are mutually exclusive.
    local handCraftPanel = self.parentpanel and self.parentpanel.HandCraftPanel
    if handCraftPanel and handCraftPanel.closeOutputSwitchPanel then
        handCraftPanel:closeOutputSwitchPanel()
    end

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

function NC_CraftInput_Slot:onMouseUp(x, y)
    return true
end

function NC_CraftInput_Slot:onRightMouseUp(x, y)
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Main Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftInput_Slot:prerender()
    local r,g,b = 0.15, 0.15, 0.15
    if self:isMouseOver() then
        r,g,b = 0.2, 0.2, 0.2
    end
    
    local sloticon = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_IconSide.png")
    local slotleft = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_LEFT.png")
    if sloticon and slotleft then
        sloticon:render(self:getAbsoluteX(), self:getAbsoluteY(), self.height, self.height, r, g, b, 0.8)
        slotleft:render(self:getAbsoluteX()+self.height, self:getAbsoluteY(), self.width - self.height, self.height, r, g, b, 0.8)
    end

    if self.logic:getManualSelectInputScriptFilter() == self.inputScript then
        r,g,b = 0.5, 0.5, 0.5
    else
        r,g,b = 0.2, 0.2, 0.2
    end

    local slotboarder = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBoarder.png")
    if slotboarder then
        slotboarder:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, r, g, b, 1)
    end
end

function NC_CraftInput_Slot:render()
    local iconX = math.floor((self.iconAreaWidth - self.iconSize) / 2)
    local iconY = math.floor((self.height - self.iconSize) / 2)

    self:renderIcon(iconX, iconY)
    self:renderTextInfo()
    self:renderQuantityText()
    self:renderStatusIcons()
end

-- RenderIcon
function NC_CraftInput_Slot:renderIcon(iconX, iconY)
    if not self.DisplayItem then return end
    
    local alpha = self:isInputSatisfied() and 1.0 or 0.5
    alpha = self.itemType == "fluidContainer" and alpha * 0.5 or alpha
    -- FIXME:if item is fluidContainer,if use renderItemIcon ,the alpha must be 1.0
    if self.actualInventoryItem then
        ISInventoryItem.renderItemIcon(self, self.actualInventoryItem, iconX, iconY, alpha, self.iconSize, self.iconSize)
    else
        local itemIcon = self.DisplayItem:getNormalTexture()
        self:drawTextureScaledAspect(itemIcon, iconX, iconY, self.iconSize, self.iconSize, alpha, 1.0, 1.0, 1.0)
    end

    if self.itemType == "fluidContainer" then
        self:renderFluidOverlay(iconX, iconY)
    end
end

-- FluidOverlay
function NC_CraftInput_Slot:renderFluidOverlay(iconX, iconY)
    local alpha = self:isInputSatisfied() and 1.0 or 0.5
    local fluidColor = {r=1, g=1, b=1}
    local inputFluids = self.logic:getSatisfiedInputFluids(self.consumeScript)
    if inputFluids:size() == 0 then
        inputFluids = self.consumeScript:getPossibleInputFluids()
    end
    if inputFluids and inputFluids:size() > 0 then
        local c = inputFluids:get(0):getColor()
        fluidColor.r, fluidColor.g, fluidColor.b = c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat()
    end
    
    self:drawTextureScaledAspect(self.fluidIconTexture, iconX, iconY, self.iconSize, self.iconSize, 
        alpha, fluidColor.r, fluidColor.g, fluidColor.b)
end

-- Render ItemName
function NC_CraftInput_Slot:renderTextInfo()
    if not self.DisplayItem then return end
    
    local textStartX = self.iconAreaWidth + self.padding
    local textAreaWidth = self.width - textStartX - self.padding
    local textScale = 0.8

    local itemName = self:getDisplayName()
    local adjustedTextAreaWidth = textAreaWidth / textScale
    local truncatedName = NeatTool.truncateText(itemName, adjustedTextAreaWidth, UIFont.Small, "...")
    
    local textAlpha = self:isInputSatisfied() and 1.0 or 0.5
    self:drawTextZoomed(truncatedName, textStartX, self.padding, textScale, 1, 1, 1, textAlpha, UIFont.Small)
end

-- Render Count
function NC_CraftInput_Slot:renderQuantityText()
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

-- Render Status Icons
function NC_CraftInput_Slot:renderStatusIcons()
    local iconSize = math.floor(FONT_HGT_MEDIUM*0.8)
    local textStartX = self.iconAreaWidth + self.padding
    local iconY = math.floor(self.height - FONT_HGT_MEDIUM)
    local iconSpacing = math.floor(FONT_HGT_SMALL * 0.3)
    
    -- Iskeep Icon
    if self.inputScript and self.inputScript:isKeep() then
        self:drawTextureScaledAspect(self.returnIconTexture, textStartX, iconY, iconSize, iconSize, 0.8, 1.0, 1.0, 1.0)
        textStartX = textStartX + iconSize + iconSpacing
    end
    
    -- UsesPartial Icon
    if self.itemType == "usesPartial" then
        self:drawTextureScaledAspect(self.usePartIconTexture, textStartX, iconY, iconSize, iconSize, 0.8, 1.0, 1.0, 1.0)
    end
end

return NC_CraftInput_Slot