require "ISUI/ISPanel"

NC_CraftLogicInventoryBox = ISPanel:derive("NC_CraftLogicInventoryBox")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryBox:initialise()
    ISPanel.initialise(self)
end

function NC_CraftLogicInventoryBox:new(x, y, width, height, itemData, parentPanel, itemIndex)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.itemData = itemData
    o.parentPanel = parentPanel
    o.itemIndex = itemIndex
    o.padding = math.floor(FONT_HGT_SMALL * 0.2)
    o.iconSize = math.floor(height * 0.6)
    
    return o
end

function NC_CraftLogicInventoryBox:createChildren()
    local totalTextHeight = FONT_HGT_SMALL + FONT_HGT_SMALL * 0.8
    local availableSpace = self.height - totalTextHeight
    local spacing = availableSpace / 3
    local nameBottomY = spacing + FONT_HGT_SMALL
    local availableHeight = self.height - self.padding - nameBottomY
    
    self.actionButtonSize = math.floor(availableHeight)
    local buttonX = self.width - self.actionButtonSize - self.padding
    local buttonY = self.height - self.actionButtonSize - self.padding
    
    if #self.itemData.recipes > 1 then
        self.actionButton = ISButton:new(buttonX, buttonY, self.actionButtonSize, self.actionButtonSize, "", self, self.onExpandButtonClick)
    else
        self.actionButton = ISButton:new(buttonX, buttonY, self.actionButtonSize, self.actionButtonSize, "", self, self.onSelectButtonClick)
    end
    
    self.actionButton.borderColor.a = 0
    self.actionButton.backgroundColor.a = 0
    self.actionButton.backgroundColorMouseOver.a = 0
    self.actionButton:initialise()
    self:addChild(self.actionButton)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Function
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryBox:onMouseMove()
    return true
end

function NC_CraftLogicInventoryBox:onMouseMoveOutside()
    return true
end

function NC_CraftLogicInventoryBox:onMouseDown()
    getSoundManager():playUISound("UIActivateButton")

    self.parentPanel:onItemSelected(self.itemData, self.itemIndex)
    return true
end

function NC_CraftLogicInventoryBox:onExpandButtonClick()
    if #self.itemData.recipes > 1 then
        self.parentPanel:toggleItemExpanded(self.itemIndex)
    end
end

function NC_CraftLogicInventoryBox:onSelectButtonClick()
    if #self.itemData.recipes == 1 and self.itemData.inInventory then
        local recipe = self.itemData.recipes[1]
        self.parentPanel:onRecipeSelected(recipe)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryBox:prerender()
    -- Background
    local bgAlpha = self.itemData.inInventory and 1.0 or 0.5
    local color = self:isMouseOver() and 0.2 or 0.15

    local sloticon = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_IconSide.png")
    sloticon:render(self:getAbsoluteX(), self:getAbsoluteY(), self.height, self.height, color, color, color, 0.8)
    local slotleft = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_LEFT.png")
    slotleft:render(self:getAbsoluteX()+self.height, self:getAbsoluteY(), self.width - self.height, self.height, color, color, color, bgAlpha)

    local itemState = self.parentPanel.itemStates[self.itemIndex]
    if itemState and itemState.isCurrentRecipeItem then
        color = 0.2
        bgAlpha = 1.0
    elseif self.parentPanel:isItemExpanded(self.itemIndex) then
        color = 0.6
        bgAlpha = 1.0
    else
        color = 0.2
        bgAlpha = 0.8
    end
    
    local slotboarder = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBoarder.png")
    if slotboarder then
        slotboarder:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, color, color, color, bgAlpha)
    end
end

function NC_CraftLogicInventoryBox:render()
    local itemData = self.itemData
    local item = itemData.scriptItem
    
    -- Draw Item Icon
    local itemIcon = item:getNormalTexture()
    local iconAlpha = itemData.inInventory and 1.0 or 0.5
    
    local IconX = (self.height - self.iconSize) / 2
    local IconY = (self.height - self.iconSize) / 2
    
    self:drawTextureScaledAspect(itemIcon, IconX, IconY, self.iconSize, self.iconSize, iconAlpha, 1, 1, 1)
    
    -- Draw Item Name
    local textX = self.height + self.padding
    local maxTextWidth = self.width - textX - self.padding - self.actionButtonSize
    local totalTextHeight = FONT_HGT_SMALL + FONT_HGT_SMALL * 0.8
    local availableSpace = self.height - totalTextHeight
    local spacing = availableSpace / 3

    local itemName = item:getDisplayName()
    local displayName = NeatTool.truncateText(itemName, maxTextWidth, UIFont.Small, "...")
    local TextAlpha = itemData.inInventory and 1.0 or 0.5

    self:drawText(displayName, textX, spacing, 1, 1, 1, TextAlpha, UIFont.Small)

    -- Draw Status Text
    local currentRecipe = self.parentPanel.logic:getRecipe()
    local statusText = getText("IGUI_CraftUI_PossibleItems")
    local r, g, b = 0.4, 0.4, 0.4

    local isCurrentRecipeItem = false
    if currentRecipe and itemData.recipes then
        for _, recipe in ipairs(itemData.recipes) do
            if recipe == currentRecipe then
                isCurrentRecipeItem = true
                break
            end
        end
    end

    if isCurrentRecipeItem then
        statusText = getText("IGUI_NC_InputItemSelected")
        r, g, b = 0.2, 1.0, 0.2
    elseif itemData.inInventory then
        statusText = getText("IGUI_CraftUI_AvailableItems")
        r, g, b = 0.2, 0.6, 1.0
    else
        statusText = getText("IGUI_CraftUI_PossibleItems")
        r, g, b = 0.4, 0.4, 0.4
    end

    local displayStatus = NeatTool.truncateText(statusText, maxTextWidth, UIFont.Small, "...")
    local statusY = spacing + FONT_HGT_SMALL + spacing

    self:drawTextZoomed(displayStatus, textX, statusY, 0.8, r, g, b, TextAlpha, UIFont.Small)
    
    -- Count Text
    if itemData.inInventory and itemData.totalCount > 0 then
        local countText = tostring(itemData.totalCount)
        local textSize = self.height / 4
        local textWidth = NeatTool.measureTextWidth(countText, textSize, true)
        
        local countX = self.height - textWidth - self.height / 16
        local countY = self.height - textSize - self.height / 16

        NeatTool.renderText(self, countText, countX, countY, textSize, 1, 1, 1, 1, true)
    end
end

return NC_CraftLogicInventoryBox