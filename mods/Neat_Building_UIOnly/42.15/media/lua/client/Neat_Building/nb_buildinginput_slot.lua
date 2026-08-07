require "ISUI/ISUIElement"

NB_BuildingInput_Slot = ISUIElement:derive("NB_BuildingInput_Slot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)


-- ----------------------------------------------------------------------------------------------------- --
-- Input picker support (integrated from XP_NB InputPicker patch)
-- ----------------------------------------------------------------------------------------------------- --

local function NB_getKey(inputScript)
    -- Prefer stable keys (name/id) for selection maps
    local key = nil
    if inputScript and inputScript.getName then
        local ok, name = pcall(inputScript.getName, inputScript)
        if ok and name then key = "name:" .. tostring(name) end
    end
    if (not key) and inputScript and inputScript.getID then
        local ok, id = pcall(inputScript.getID, inputScript)
        if ok and id then key = "id:" .. tostring(id) end
    end
    if not key then key = "ud:" .. tostring(inputScript) end
    return key
end

local function NB_safeGetSelectedFullType(logic, inputScript)
    -- Read the preferred fullType for this InputScript from the global selection map.
    if not logic or not inputScript then return nil end

    local getMap = rawget(_G, "NB_getInputSelectionMap")
    if not getMap then return nil end

    local map = getMap(logic)
    if not map then return nil end

    local key = NB_getKey(inputScript)
    return map[key]
end



-- ----------------------------------------------------------------------------------------------------- --
-- Quantity display fix for per-item amounts (integrated from XP_NB Quantity patch)
-- ----------------------------------------------------------------------------------------------------- --

local function _safeMethodCall(obj, methodName, ...)
    -- Safely call a method on a userdata/table if it exists.
    -- Returns nil on missing method or on error.
    if obj == nil then return nil end
    local m = obj[methodName]
    if m == nil then return nil end
    local ok, res = pcall(m, obj, ...)
    if ok then return res end
    return nil
end

local function _getDisplayFullType(slot)
    if not slot or slot.DisplayItem == nil then return nil end
    local di = slot.DisplayItem

    -- Some code paths may assign a full type string directly.
    if type(di) == "string" then
        if di ~= "" then return di end
        return nil
    end

    -- InventoryItem usually supports getFullType().
    local ft = _safeMethodCall(di, "getFullType")
    if ft and ft ~= "" then return ft end

    -- ScriptItem / Item scripts usually support getFullName().
    ft = _safeMethodCall(di, "getFullName")
    if ft and ft ~= "" then return ft end

    return nil
end

local function _round2(v)
    -- Round to 2 decimals without relying on global helpers.
    return math.floor((v * 100) + 0.5) / 100
end

local function _roundNice(v)
    if type(v) ~= "number" then return tostring(v) end
    -- Display integers without decimals, otherwise keep 2 decimals.
    if math.abs(v - math.floor(v + 0.5)) < 0.0001 then
        return tostring(math.floor(v + 0.5))
    end
    return tostring(_round2(v))
end

local function _getRequiredAmountForDisplay(slot)
    if not slot or slot.inputScript == nil then return nil end
    local input = slot.inputScript
    local ft = _getDisplayFullType(slot)

    -- Fluid containers already use getAmount() (liters) in vanilla NB logic.
    if slot.itemType == "fluidContainer" then
        local amt = _safeMethodCall(input, "getAmount")
        return amt, nil, "fluid"
    end

    -- Uses/Drainable: use float amount per item-type if available.
    if slot.itemType == "usesPartial" then
        local amt = nil
        if ft then
            amt = _safeMethodCall(input, "getAmount", ft)
        end
        if amt == nil then
            amt = _safeMethodCall(input, "getAmount")
        end

        local maxAmt = nil
        if _safeMethodCall(input, "isVariableAmount") then
            if ft then
                maxAmt = _safeMethodCall(input, "getMaxAmount", ft)
            end
            if maxAmt == nil then
                maxAmt = _safeMethodCall(input, "getMaxAmount")
            end
        end

        return amt, maxAmt, "uses"
    end

    -- Normal item count: use int amount per item-type if available.
    local amt = nil
    if ft then
        amt = _safeMethodCall(input, "getIntAmount", ft)
    end
    if amt == nil then
        amt = _safeMethodCall(input, "getIntAmount")
    end

    local maxAmt = nil
    if _safeMethodCall(input, "isVariableAmount") then
        if ft then
            maxAmt = _safeMethodCall(input, "getIntMaxAmount", ft)
        end
        if maxAmt == nil then
            maxAmt = _safeMethodCall(input, "getIntMaxAmount")
        end
    end

    return amt, maxAmt, "count"
end
-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInput_Slot:initialise()
    ISUIElement.initialise(self)
    self:updateInputInfo()
end

function NB_BuildingInput_Slot:new(x, y, width, height, player, inputScript, parentpanel)
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
    o.itemType = "normal" -- normal, fluidContainer, usesPartial
    o.consumeScript = nil
    o.tooltip = nil

    o.usePartIconTexture = getTexture("media/ui/Neat_Building/ICON/Icon_UsePart.png")
    o.fluidIconTexture = getTexture("media/textures/Item_Waterdrop_Grey.png")
    o.returnIconTexture = getTexture("media/ui/Neat_Building/ICON/Icon_CraftReturn.png")
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Input Info
-- ----------------------------------------------------------------------------------------------------- --

function NB_BuildingInput_Slot:updateInputInfo()
    if not self.inputScript or not self.logic then return end

    self.bestItemScript = self:getInputItem()
    self.DisplayItem = self.bestItemScript or self:getScriptItem()

    self:updateItemType()
end

function NB_BuildingInput_Slot:getInputItem()
    -- Prefer the selected fullType (if present) for display, but keep vanilla fallback.
    if not self.logic or not self.inputScript then return nil end

    local satisfiedItems = self.logic:getSatisfiedInputItems(self.inputScript)
    local item = (satisfiedItems and satisfiedItems:size() > 0) and satisfiedItems:get(0) or nil

    local selected = NB_safeGetSelectedFullType(self.logic, self.inputScript)
    if not selected or not satisfiedItems or not satisfiedItems.size or satisfiedItems:size() <= 0 then
        return item
    end

    -- Find a matching inventory item and use it for display
    for i = 0, satisfiedItems:size() - 1 do
        local it = satisfiedItems:get(i)
        if it then
            local fullType = it.getFullType and it:getFullType() or (it.getFullName and it:getFullName() or nil)
            if fullType == selected then
                return it
            end
        end
    end

    return item
end


function NB_BuildingInput_Slot:getScriptItem()
    -- If the user has a preferred fullType selected, reflect it in the slot icon/name.
    local selected = NB_safeGetSelectedFullType(self.logic, self.inputScript)
    if selected then
        local scriptItem = getItem(selected)
        if scriptItem then return scriptItem end
    end

    local possibleItems = self.inputScript:getPossibleInputItems()
    return possibleItems and possibleItems:size() > 0 and possibleItems:get(0) or nil
end


function NB_BuildingInput_Slot:updateItemType()
        -- Reset per-update state first so it can't "stick" across item selections.
        local prevType = self.itemType
        local prevDisplay = self._XP_NB_lastDisplayItem
        self.itemType = nil
        self.consumeScript = nil

        -- Call NB's original logic (it will set fluidContainer/usesPartial when applicable).
        if _oldUpdateItemType then
            _oldUpdateItemType(self)
        end

        -- Rebuild cached tooltip when either the display item or type changed.
        self._XP_NB_lastDisplayItem = self.DisplayItem
        if prevDisplay ~= self.DisplayItem or prevType ~= self.itemType then
            self.tooltip = nil
        end
    end

function NB_BuildingInput_Slot:createTooltip()
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
        -- Use per-item required amount (Build 42.13+: InputScript.amount can be normalized).
        local required = _getRequiredAmountForDisplay(self)
        local consumeAmount = required and math.ceil(required) or self.inputScript:getIntAmount()
        description = getText("IGUI_CraftingWindow_WillBeConsume", tostring(consumeAmount))
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

-- ----------------------------------------------------------------------------------------------------- --
-- Get Info
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInput_Slot:getQuantityText()
    if self.DisplayItem == nil or self.inputScript == nil then return nil end

    local amount, maxAmount, kind = _getRequiredAmountForDisplay(self)
    if amount == nil then
        -- Fallback to original behavior.
        return _oldGetQuantityText and _oldGetQuantityText(self) or nil
    end

    if kind == "fluid" then
        return tostring(amount) .. "L"
    end

    if maxAmount and maxAmount > amount then
        return _roundNice(amount) .. "-" .. _roundNice(maxAmount)
    end

    return _roundNice(amount)
end

function NB_BuildingInput_Slot:getDisplayName()
    if not self.DisplayItem then
        return "Unknown"
    end
    
    if self.itemType == "fluidContainer" and self.inputScript:hasConsumeFromItem() then
        local containerName = self.DisplayItem:getDisplayName()
        local consumeScript = self.inputScript:getConsumeFromItemScript()
        local inputFluids = consumeScript:getPossibleInputFluids()
        
        if inputFluids and inputFluids:size() > 0 then
            local fluidName = inputFluids:get(0):getDisplayName()
            return fluidName .." (" .. containerName .. ")"
        end
    end
    
    return self.DisplayItem:getDisplayName()
end

function NB_BuildingInput_Slot:isInputSatisfied()
    if not self.logic or not self.inputScript then return false end

    return self.logic:isInputSatisfied(self.inputScript)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInput_Slot:createTooltip()
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
        local consumeAmount = self.inputScript:getIntAmount()
        description = getText("IGUI_CraftingWindow_WillBeConsume", tostring(consumeAmount))
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

function NB_BuildingInput_Slot:removeTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Interactive
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInput_Slot:onMouseMove(dx, dy)
    if self:isMouseOver() and not self.tooltip then
        self:createTooltip()
    end
    return true
end

function NB_BuildingInput_Slot:onMouseDown(dx, dy)
    -- Keep original behavior (tooltip removal, etc.)
    self:removeTooltip()

    -- Open the picker via the owning BuildingInfoPanel
    local infoPanel = self.parentpanel and self.parentpanel.BuildingInfoPanel
    if infoPanel and infoPanel.NB_togglePickerForSlot then
        infoPanel:NB_togglePickerForSlot(self)
    end

    return true
end

function NB_BuildingInput_Slot:onMouseMoveOutside(dx, dy)
    self:removeTooltip()
    return true
end


-- ----------------------------------------------------------------------------------------------------- --
-- Main Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInput_Slot:prerender()
    local r,g,b = 0.15, 0.15, 0.15
    if self:isMouseOver() then
        r,g,b = 0.2, 0.2, 0.2
    end
    
    local sloticon = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Button/SlotBG_IconSide.png")
    local slotleft = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Button/SlotBG_LEFT.png")
    if sloticon and slotleft then
        sloticon:render(self:getAbsoluteX(), self:getAbsoluteY(), self.height, self.height, r, g, b, 1)
        slotleft:render(self:getAbsoluteX()+self.height, self:getAbsoluteY(), self.width - self.height, self.height, r, g, b, 1)
    end

    r,g,b = 0.2, 0.2, 0.2

    local slotboarder = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Button/SlotBoarder.png")
    if slotboarder then
        slotboarder:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, r, g, b, 1)
    end
end

function NB_BuildingInput_Slot:render()
    local iconX = math.floor((self.iconAreaWidth - self.iconSize) / 2)
    local iconY = math.floor((self.height - self.iconSize) / 2)

    self:renderIcon(iconX, iconY)
    self:renderTextInfo()
    self:renderQuantityText()
    self:renderStatusIcons()
end

-- RenderIcon
function NB_BuildingInput_Slot:renderIcon(iconX, iconY)
    if not self.DisplayItem then return end
    
    local alpha = self:isInputSatisfied() and 1.0 or 0.5
    alpha = self.itemType == "fluidContainer" and alpha * 0.5 or alpha
    
    local itemIcon = self.DisplayItem:getNormalTexture()
    self:drawTextureScaledAspect(itemIcon, iconX, iconY, self.iconSize, self.iconSize, alpha, 1.0, 1.0, 1.0)

    if self.itemType == "fluidContainer" then
        self:renderFluidOverlay(iconX, iconY)
    end
end

-- FluidOverlay
function NB_BuildingInput_Slot:renderFluidOverlay(iconX, iconY)
    local alpha = self:isInputSatisfied() and 1.0 or 0.5
    local fluidColor = {r=1, g=1, b=1}
    
    if self.consumeScript then
        local inputFluids = self.consumeScript:getPossibleInputFluids()
        if inputFluids and inputFluids:size() > 0 then
            local c = inputFluids:get(0):getColor()
            fluidColor.r, fluidColor.g, fluidColor.b = c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat()
        end
    end
    
    if self.fluidIconTexture then
        self:drawTextureScaledAspect(self.fluidIconTexture, iconX, iconY, self.iconSize, self.iconSize, 
            alpha, fluidColor.r, fluidColor.g, fluidColor.b)
    end
end

-- Render ItemName
function NB_BuildingInput_Slot:renderTextInfo()
    if not self.DisplayItem then return end
    
    local textStartX = self.iconAreaWidth + self.padding
    local textAreaWidth = self.width - textStartX - self.padding
    local textScale = 0.8

    local itemName = self:getDisplayName()
    local adjustedTextAreaWidth = textAreaWidth / textScale
    local truncatedName = itemName
    if NeatTool and NeatTool.truncateText then
        truncatedName = NeatTool.truncateText(itemName, adjustedTextAreaWidth, UIFont.Small, "...")
    end
    
    local textAlpha = self:isInputSatisfied() and 1.0 or 0.5
    self:drawTextZoomed(truncatedName, textStartX, self.padding, textScale, 1, 1, 1, textAlpha, UIFont.Small)
end

-- Render Count
function NB_BuildingInput_Slot:renderQuantityText()
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
function NB_BuildingInput_Slot:renderStatusIcons()
    local iconSize = math.floor(FONT_HGT_MEDIUM*0.8)
    local textStartX = self.iconAreaWidth + self.padding
    local iconY = math.floor(self.height - FONT_HGT_MEDIUM)
    local iconSpacing = math.floor(FONT_HGT_SMALL * 0.3)
    
    -- Iskeep Icon
    if self.inputScript and self.inputScript:isKeep() and self.returnIconTexture then
        self:drawTextureScaledAspect(self.returnIconTexture, textStartX, iconY, iconSize, iconSize, 0.8, 1.0, 1.0, 1.0)
        textStartX = textStartX + iconSize + iconSpacing
    end
    
    -- UsesPartial Icon
    if self.itemType == "usesPartial" and self.usePartIconTexture then
        self:drawTextureScaledAspect(self.usePartIconTexture, textStartX, iconY, iconSize, iconSize, 0.8, 1.0, 1.0, 1.0)
    end
end

return NB_BuildingInput_Slot