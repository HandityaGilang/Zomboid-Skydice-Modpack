require "ISUI/ISUIElement"
require "ISUI/ISToolTipInv"
require "ISUI/ISInventoryPaneContextMenu"

PJCK_ItemSlot = ISUIElement:derive("PJCK_ItemSlot")
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------- --
function PJCK_ItemSlot:initialise()
    ISUIElement.initialise(self)
end

function PJCK_ItemSlot:new(x, y, width, height, item, count, parentPanel)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.padding = parentPanel.padding
    o.buttonHeight = height - width - o.padding / 2
    o.iconSize = math.min(math.max(32, round(width * 0.6/16)*16), width)
    o.parentPanel = parentPanel
    o.item = item
    o.count = count
    o.isPossible = true
    o.isPressed = false
    o.EvoPanel = parentPanel.EvoPanel
    o.tooltip = nil
    
    return o
end

-- ---------------------------------------------------------- --
-- Get/Set Info
-- ---------------------------------------------------------- --

function PJCK_ItemSlot:setItemData(item, count, isPossible, frozenPreview)
    self.item = item
    self.count = count
    self.isPossible = isPossible
    self.frozenPreview = frozenPreview == true
end

function PJCK_ItemSlot:getFoodSatietyInfo(item)

    local ratio = 0
    local isFrozen = instanceof(item, "Food") and item:isFrozen()
    
    if item:IsDrainable() then
        ratio = math.max(0, math.min(1, item:getCurrentUsesFloat()))
    elseif instanceof(item, "Food") then
        local actualWeight = item:getActualWeight()
        local maxWeight = item:getScriptItem():getActualWeight()
        ratio = maxWeight > 0 and actualWeight / maxWeight or 0
    else
        ratio = 1
    end
    
    local r, g, b, a
    if isFrozen then
        r, g, b, a = 0.3, 0.7, 0.9, 0.7
    elseif ratio > 0.7 then
        r, g, b, a = 0.4, 0.8, 0.4, 0.3
    elseif ratio > 0.3 then
        r, g, b, a = 1.0, 0.7, 0.2, 0.5
    else
        r, g, b, a = 0.9, 0.3, 0.3, 0.7
    end
    
    return ratio, r, g, b, a
end

-- ---------------------------------------------------------- --
-- Context Menu
-- ---------------------------------------------------------- --

function PJCK_ItemSlot:onSwitchItem(item)
    self.item = item

    local itemName = item:getName()
    self.EvoPanel.switchItems[itemName] = item
end

function PJCK_ItemSlot:isItemInPlayerInventory(playerObj, item)
    if not playerObj or not item or not item.getContainer then return false end

    local container = item:getContainer()
    if not container then return false end

    if container.isInCharacterInventory then
        local ok, value = pcall(function()
            return container:isInCharacterInventory(playerObj)
        end)
        if ok then return value == true end
    end

    local playerInventory = playerObj:getInventory()
    return container == playerInventory
end

function PJCK_ItemSlot:getContextMenuItems()
    if not self.item then return {} end
    if not self.count or self.count <= 1 then return { self.item } end

    local groupItems = self:getInputGroupItems()
    if groupItems and #groupItems > 0 then
        return groupItems
    end

    return { self.item }
end

function PJCK_ItemSlot:areContextItemsInPlayerInventory(playerObj, items)
    if not items or #items == 0 then return false end

    for _, item in ipairs(items) do
        if not self:isItemInPlayerInventory(playerObj, item) then
            return false
        end
    end

    return true
end

function PJCK_ItemSlot:addProjectCookContextOptions(contextMenu)
    if not contextMenu or not self.item or not self.EvoPanel then return end

    local baseItem = self.EvoPanel:getBaseItem()

    -- Keep Project Cook helpers in addition to the vanilla inventory/loot menu.
    if self.EvoPanel.baseItemPanel and self.EvoPanel.baseItemPanel.baseItemSlot and self.EvoPanel.baseItemPanel.baseItemSlot:isValidBaseItem(self.item) then
        local baseItemOptionText = baseItem and (getTextOrNull("IGUI_PJCK_SwitchBaseItem") or "Switch base item") or (getTextOrNull("IGUI_PJCK_SetAsBaseItem") or "Set as base item")
        local baseItemOption = contextMenu:addOption(baseItemOptionText, self.EvoPanel, self.EvoPanel.setBaseItem, self.item)
        baseItemOption.iconTexture = self.item:getTex()
    end

    if self.count and self.count > 1 and baseItem then
        local switchOption = contextMenu:addOption(getText("IGUI_PJCK_SwitchItem"), nil, nil)
        switchOption.iconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_SwitchContext.png")
        local subMenuSwitch = contextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(switchOption, subMenuSwitch)

        local groupItems = self:getInputGroupItems()
        for _, item in ipairs(groupItems) do
            local ratio = self:getFoodSatietyInfo(item)
            local displayText = item:getName() .. " (" .. math.floor(ratio * 100) .. "%)"
            local option = subMenuSwitch:addOption(displayText, self, self.onSwitchItem, item)
            option.iconTexture = item:getTex()
        end
    end
end

function PJCK_ItemSlot:showItemContextMenu()
    self:hideTooltip()
    if not self.item or not self.EvoPanel or not self.EvoPanel.player then return end

    local player = self.EvoPanel.player
    local playerNum = player:getPlayerNum()
    local playerObj = getSpecificPlayer(playerNum) or player
    local contextX = self:getAbsoluteX() + self.width
    local contextY = self:getAbsoluteY()
    local contextItems = self:getContextMenuItems()
    local isInPlayerInventory = self:areContextItemsInPlayerInventory(playerObj, contextItems)
    local contextMenu = nil

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
        contextMenu = ISInventoryPaneContextMenu.createMenu(playerNum, isInPlayerInventory, contextItems, contextX, contextY, self)
    else
        contextMenu = ISContextMenu.get(playerNum, contextX, contextY)
    end

    self:addProjectCookContextOptions(contextMenu)
end

-- ---------------------------------------------------------- --
-- Button Function
-- ---------------------------------------------------------- --

function PJCK_ItemSlot:onAddButton()
    if not self.parentPanel:canAddItem(self.item) then return end
    
    local maxAvailable = self.parentPanel:getMaxAvailableCount(self.item)
    local currentSelected = self.parentPanel:getSelectedCount(self.item)
    
    if currentSelected < maxAvailable then
        self.EvoPanel:addPreCookItems(self.item)
        getSoundManager():playUISound("UIActivateButton")
    end
end

function PJCK_ItemSlot:onMinusButton()
    local currentSelected = self.parentPanel:getSelectedCount(self.item)
    if currentSelected <= 0 then return end

    self.EvoPanel:removePreCookItems(self.item, 1)
    getSoundManager():playUISound("UIActivateButton")
end

-- ---------------------------------------------------------- --
-- Mouse Function
-- ---------------------------------------------------------- --
function PJCK_ItemSlot:getButtonAtPosition(x, y)
    if self.isPossible or self.frozenPreview then return nil end
    if y < self.width + self.padding / 2 or y > self.height or x < 0 or x >self.width then return nil end
    
    local currentSelected = self.parentPanel:getSelectedCount(self.item)
    if currentSelected > 0 then
        local buttonWidth = self.width / 2
        if x <= buttonWidth then
            return "add"
        elseif x >= buttonWidth then
            return "minus"
        end
    else
        return "add"
    end
    return nil
end

function PJCK_ItemSlot:onMouseDown(x, y)
    local button = self:getButtonAtPosition(x, y)
    if button then
        self.pressedButton = button
        return true
    end
    self.isPressed = true
    return false
end

function PJCK_ItemSlot:onMouseUp(x, y)
    if self.pressedButton then
        local button = self:getButtonAtPosition(x, y)
        if button == self.pressedButton then
            if button == "add" then
                self:onAddButton()
            elseif button == "minus" then
                self:onMinusButton()
            end
        end
        self.pressedButton = nil
        return true
    end
    self.isPressed = false
    return false
end

function PJCK_ItemSlot:onMouseMove()
    local contextMenu = getPlayerContextMenu(self.EvoPanel.player:getPlayerNum())
    if contextMenu and contextMenu:isAnyVisible() then
        self:hideTooltip()
        return true
    end

    if self:getMouseY() < self.width then
        self:showTooltip()
    else
        self:hideTooltip()
    end
    return true
end

function PJCK_ItemSlot:onMouseMoveOutside()
    self:hideTooltip()
    return true
end

function PJCK_ItemSlot:onMouseDoubleClick()
    if self.isPossible or self.frozenPreview then return false end
    if self:getMouseY() >= self.width then return false end
    
    local recipe = self.EvoPanel:getRecipe()
    local baseItem = self.EvoPanel:getBaseItem()
    local usable = self.EvoPanel:isUsableForRecipe(self.item, recipe)
    if recipe and baseItem and usable and self.parentPanel:canAddItem(self.item) then
        -- add to preCookItems
        self.EvoPanel:addPreCookItems(self.item)
        -- add Ingredients
        self.EvoPanel:addIngredients({self.item}, recipe, baseItem)
        return true
    end
    return false
end

function PJCK_ItemSlot:onRightMouseDown(x, y)
    if self.isPossible then return false end
    if not (self:getMouseY() >= self.width) then
        self:hideTooltip()
        self:showItemContextMenu()
        return true
    end
    return false
end

function PJCK_ItemSlot:showTooltip()
    if self.tooltip or not self.item then return end
    
    if self.isPossible and not self.frozenPreview then
        self.tooltip = ISToolTip:new()
        self.tooltip:initialise()
        self.tooltip:setOwner(self)
        self.tooltip:setName(self.item:getDisplayName())
        self.tooltip:setVisible(true)
        self.tooltip:setAlwaysOnTop(true)
        self.tooltip:addToUIManager()
    else
        self.tooltip = ISToolTipInv:new(self.item)
        self.tooltip:initialise()
        self.tooltip:setOwner(self)
        self.tooltip:setCharacter(self.EvoPanel.player)
        self.tooltip:setItem(self.item)
        self.tooltip.followMouse = true
        self.tooltip:setVisible(true)
        self.tooltip:addToUIManager()
    end
end

function PJCK_ItemSlot:hideTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

function PJCK_ItemSlot:getInputGroupItems()
    local groupItems = {}
    if not self.item or not self.EvoPanel or not self.EvoPanel.player then
        return groupItems
    end

    local containers = ISInventoryPaneContextMenu.getContainers(self.EvoPanel.player)
    local allItems = ArrayList.new()
    if containers and CraftRecipeManager and CraftRecipeManager.getAllItemsFromContainers then
        CraftRecipeManager.getAllItemsFromContainers(containers, allItems)
    end

    if allItems then
        local itemName = self.item:getName()
        for i = 0, allItems:size() - 1 do
            local item = allItems:get(i)
            if item and item:getName() == itemName then
                table.insert(groupItems, item)
            end
        end
    end

    return groupItems
end

function PJCK_ItemSlot:getFrozenStackState()
    if not self.item or not instanceof(self.item, "Food") then
        return false, false
    end

    local groupItems = self:getInputGroupItems()
    local total = 0
    local frozen = 0

    for _, item in ipairs(groupItems) do
        if item and instanceof(item, "Food") then
            total = total + 1
            if item:isFrozen() then
                frozen = frozen + 1
            end
        end
    end

    if total == 0 then
        return self.item:isFrozen(), self.item:isFrozen()
    end

    return frozen > 0, frozen == total
end

function PJCK_ItemSlot:shouldShowCookableIcon()
    if not self.item or not self.item.isFood or not self.item:isFood() then
        return false
    end

    if self.item:isBurnt() then
        return false
    end

    if self.item:isbDangerousUncooked() and not self.item:isCooked() then
        return true
    end

    if self.item:isIsCookable() and not self.item:isCooked() then
        return true
    end

    return false
end

function PJCK_ItemSlot:shouldShowBurntIcon()
    return self.item and self.item.isFood and self.item:isFood() and self.item:isBurnt()
end

-- ---------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------- --

function PJCK_ItemSlot:prerender()
    local recipe = self.EvoPanel:getRecipe()

    -- Background
    local isMouseOver = self:isMouseOver() and self:getMouseY() <= self.width
    local color = isMouseOver and 0.3 or 0.2
    local bgAlpha = self.isPossible and 0.6 or 0.8
    self:drawTextureScaled(self.parentPanel.slotTex.bg, 0, 0, self.width, self.width, bgAlpha, color, color, color)
    
    -- Border
    local usable = true
    if self.item and recipe then
        usable = self.EvoPanel:isUsableForRecipe(self.item, recipe)
    end
    local borderR = usable and 0.4 or 0.8
    if self.isPossible then 
        borderR = 0.4
    end
    local borderAlpha = self.isPossible and 0.8 or 1
    self:drawTextureScaled(self.parentPanel.slotTex.border, 0, 0, self.width, self.width, borderAlpha, borderR, 0.4, 0.4)
    
    -- Button Background
    if self.item and self.count > 0 and recipe and not self.frozenPreview then
        NeatTool.ThreePatch.drawHorizontal(self, 0, self.width + self.padding / 2, self.width, self.buttonHeight,self.parentPanel.bottomTex.L, self.parentPanel.bottomTex.M, self.parentPanel.bottomTex.R,1.0, 0.2, 0.2, 0.2)
        self:renderButtonIcons()
    end
    
    -- Satiety
    if not self.isPossible then
        local ratio, r, g, b, a = self:getFoodSatietyInfo(self.item)
        if ratio > 0 then
            local percentage = math.max(0, math.min(1, ratio))
            self.javaObject:DrawTexturePercentageBottomUp(self.parentPanel.slotTex.bg, percentage, 0, 0, self.width, self.width, r, g, b, a)
        end
    end
    
    -- Icon
    if self.item then
        local alpha = self.isPossible and 0.5 or 1
        local iconX = (self.width - self.iconSize) / 2
        local iconY = (self.width - self.iconSize) / 2
        ISInventoryItem.renderItemIcon(self, self.item, iconX, iconY, alpha, self.iconSize, self.iconSize)
    end
    
    -- Count
    if not self.isPossible then
        local countStr = tostring(self.count)
        local textSize = self.width / 4
        local textWidth = NeatTool.measureTextWidth(countStr, textSize, true)
        local margin = self.width / 12

        NeatTool.renderText(self, countStr, self.width - textWidth - margin, self.width - textSize - margin,textSize, 1.0, 1, 1, 1, true)
    end
    
    -- Fresh Icon
    if instanceof(self.item, "Food") and not self.item:isFresh() and not self.isPossible then
        local freshIconSize = self.width / 4
        local margin = self.width / 16
        local r, g, b = self.item:isRotten() and 1 or 1, self.item:isRotten() and 0.4 or 0.75, 0.4
        self:drawTextureScaled(self.parentPanel.freshIcon, margin, margin, freshIconSize, freshIconSize, 0.9, r, g, b)
    end

    -- Cookable / raw-danger icon, or burnt-state icon.
    if not self.isPossible then
        local iconSize = self.width / 4
        local margin = self.width / 16
        if self:shouldShowBurntIcon() and self.parentPanel.burntIcon then
            self:drawTextureScaled(self.parentPanel.burntIcon, self.width - iconSize - margin, margin, iconSize, iconSize, 0.95, 1, 1, 1)
        elseif self:shouldShowCookableIcon() and self.parentPanel.cookableIcon then
            self:drawTextureScaled(self.parentPanel.cookableIcon, self.width - iconSize - margin, margin, iconSize, iconSize, 0.95, 1, 1, 1)
        end
    end

    -- Frozen icon. Partially frozen stacks use a lower alpha.
    local anyFrozen, allFrozen = self:getFrozenStackState()
    if (not self.isPossible or self.frozenPreview) and anyFrozen and self.parentPanel.frozenIcon then
        local iconSize = self.width / 4
        local margin = self.width / 16
        local alpha = allFrozen and 1.0 or 0.45
        self:drawTextureScaled(self.parentPanel.frozenIcon, margin, self.width - iconSize - margin, iconSize, iconSize, alpha, 1, 1, 1)
    end
end

function PJCK_ItemSlot:renderButtonIcons()
    local currentSelected = self.parentPanel:getSelectedCount(self.item)
    local buttonY = self.width + self.padding / 2
    local iconSize = self.buttonHeight * 0.7
    local iconY = (self.buttonHeight - iconSize) / 2

    local hoveredButton = self:getButtonAtPosition(self:getMouseX(), self:getMouseY())
    
    if currentSelected > 0 then
        local buttonWidth = self.width / 2
        
        -- Add button
        local addAlpha = (hoveredButton == "add") and 1 or 0.6
        local addColor = (currentSelected > 0) and {r = 1.0, g = 0.7, b = 0.0} or {r = 0.8, g = 0.8, b = 0.8}
        local addIconX = (buttonWidth - iconSize) / 2
        self:drawTextureScaled(self.parentPanel.plusIcon, addIconX, buttonY + iconY, iconSize, iconSize, addAlpha, addColor.r, addColor.g, addColor.b)
        
        -- Minus button
        local minusAlpha = (hoveredButton == "minus") and 1 or 0.6
        local minusIconX = buttonWidth + (buttonWidth - iconSize) / 2
        self:drawTextureScaled(self.parentPanel.minusIcon, minusIconX + 1, buttonY + iconY, iconSize, iconSize, minusAlpha, addColor.r, addColor.g, addColor.b)
    else
        -- Single add button
        local addAlpha = (hoveredButton == "add") and 1 or 0.6
        local addIconX = (self.width - iconSize) / 2
        self:drawTextureScaled(self.parentPanel.plusIcon, addIconX, buttonY + iconY, iconSize, iconSize, addAlpha, 0.8, 0.8, 0.8)
    end
end

return PJCK_ItemSlot