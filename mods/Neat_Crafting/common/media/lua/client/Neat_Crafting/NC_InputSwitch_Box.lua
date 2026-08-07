require "ISUI/ISPanel"

NC_InputSwitch_Box = ISPanel:derive("NC_InputSwitch_Box")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function ncText(key, fallback)
    local text = getText(key)
    if not text or text == key then
        return fallback
    end
    return text
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Box:initialise()
    ISPanel.initialise(self)
end

function NC_InputSwitch_Box:new(x, y, width, height, itemInfo, parentPanel, itemIndex)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.itemInfo = itemInfo
    o.parentPanel = parentPanel
    o.itemIndex = itemIndex
    o.padding = math.floor(FONT_HGT_SMALL * 0.2)
    o.iconSize = math.floor(height * 0.6)
    o.searchIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_SearchItem.png")
    o.fluidIcon = getTexture("media/textures/Item_Waterdrop_Grey.png")
    
    return o
end

function NC_InputSwitch_Box:createChildren()
    if not self.itemInfo or self.itemInfo.isHeader or self.itemInfo.itemType == "fluid" or not self.itemInfo.scriptItem then
        return
    end

    local totalTextHeight = FONT_HGT_SMALL + FONT_HGT_SMALL * 0.8
    local availableSpace = self.height - totalTextHeight
    local spacing = availableSpace / 3
    local nameBottomY = spacing + FONT_HGT_SMALL
    local availableHeight = self.height - self.padding - nameBottomY
    self.searchButtonSize = math.floor(availableHeight)
    local buttonX = self.width - self.searchButtonSize - self.padding
    local buttonY = self.height - self.searchButtonSize - self.padding
    self.searchButton = ISButton:new(buttonX, buttonY, self.searchButtonSize, self.searchButtonSize, "", self, self.onSearchButtonClick)
    self.searchButton.borderColor.a = 0
    self.searchButton.backgroundColor.a = 0
    self.searchButton.backgroundColorMouseOver.a = 0
    self.searchButton:initialise()
    self:addChild(self.searchButton)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Function
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Box:onMouseMove()
    if not self.itemInfo or self.itemInfo.isHeader then
        return true
    end

    if self:isMouseOver() and not self.itemInfo.inInventory and not self.tooltip then
        self:createTooltip()
    end
    return true
end

function NC_InputSwitch_Box:onMouseMoveOutside()
    self:removeTooltip()
    return true
end

function NC_InputSwitch_Box:onMouseDown()
    if not self.itemInfo or self.itemInfo.isHeader then
        return true
    end

    getSoundManager():playUISound("UIActivateButton")
    self:removeTooltip()

    if self.itemInfo.inInventory and self.itemInfo.AvailableItems and #self.itemInfo.AvailableItems > 0 then
        self.parentPanel:toggleItemExpanded(self.itemIndex)
    end
    return true
end

function NC_InputSwitch_Box:onSearchButtonClick()
    if not self.itemInfo or self.itemInfo.isHeader or self.itemInfo.itemType == "fluid" or not self.itemInfo.scriptItem then return end
    
    local itemName = self.itemInfo.scriptItem:getDisplayName()
    local handCraftPanel = self.parentPanel.HandCraftPanel
    if handCraftPanel then
        local searchComponent = nil
        
        if handCraftPanel.MainPanel then
            if handCraftPanel.MainPanel.header and handCraftPanel.MainPanel.header.searchComponent then
                searchComponent = handCraftPanel.MainPanel.header.searchComponent
            elseif handCraftPanel.MainPanel.parent and handCraftPanel.MainPanel.parent.header then
                searchComponent = handCraftPanel.MainPanel.parent.header.searchComponent
            end
        end

        if searchComponent then
            searchComponent:setSearchMode("OutputName")
            searchComponent:setSearchText(itemName)
            searchComponent:performSearch()
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Box:createTooltip()
    if self.tooltip or not self.itemInfo then return end

    local displayName = nil
    if self.itemInfo.itemType == "fluid" then
        displayName = self.itemInfo.displayName
    elseif self.itemInfo.scriptItem then
        displayName = self.itemInfo.scriptItem:getDisplayName()
    end
    if not displayName then return end
    
    self.tooltip = ISToolTip:new()
    self.tooltip:initialise()
    self.tooltip:instantiate()
    self.tooltip:setOwner(self)
    self.tooltip:setName(displayName)
    self.tooltip:addToUIManager()
    self.tooltip:setVisible(true)
end

function NC_InputSwitch_Box:removeTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render helpers
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Box:renderHeader()
    local text = self.itemInfo.displayName or ""
    local maxTextWidth = self.width - self.padding * 2
    local displayName = NeatTool.truncateText(text, maxTextWidth, UIFont.Small, "...")
    local textY = math.floor((self.height - FONT_HGT_SMALL) / 2)
    self:drawText(displayName, self.padding * 2, textY, 0.7, 0.85, 1.0, 1.0, UIFont.Small)
end

function NC_InputSwitch_Box:renderFluidIcon(iconX, iconY, iconAlpha)
    local r, g, b = 1, 1, 1
    if self.itemInfo.fluid and self.parentPanel and self.parentPanel.getFluidColor then
        r, g, b = self.parentPanel:getFluidColor(self.itemInfo.fluid)
    end

    if self.fluidIcon then
        self:drawTextureScaledAspect(self.fluidIcon, iconX, iconY, self.iconSize, self.iconSize, iconAlpha, r, g, b)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_InputSwitch_Box:prerender()
    if self.itemInfo and self.itemInfo.isHeader then
        self:drawRect(0, 0, self.width, self.height, 0.35, 0.08, 0.08, 0.08)
        return
    end

    -- Keep the slot body opaque for readability on bright backgrounds.
    -- Availability is still communicated by dimming the item icon/text in render().
    local bgAlpha = 1.0
    local color = self:isMouseOver() and 0.2 or 0.15

    local sloticon = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_IconSide.png")
    local slotleft = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_LEFT.png")
    if sloticon and slotleft then
        sloticon:render(self:getAbsoluteX(), self:getAbsoluteY(), self.height, self.height, color, color, color, 0.8)
        slotleft:render(self:getAbsoluteX()+self.height, self:getAbsoluteY(), self.width - self.height, self.height, color, color, color, bgAlpha)
    end
    
    -- Boarder
    if self.parentPanel:isItemExpanded(self.itemIndex) then
        color = 0.6
        bgAlpha = 1.0
    else
        color = 0.2
    end
    
    local slotboarder = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBoarder.png")
    if slotboarder then
        slotboarder:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, color, color, color, bgAlpha)
    end
end

function NC_InputSwitch_Box:render()
    local itemInfo = self.itemInfo
    if not itemInfo then return end

    if itemInfo.isHeader then
        self:renderHeader()
        return
    end
    
    -- Draw Item / Fluid Icon
    local iconAlpha = itemInfo.inInventory and 1.0 or 0.5
    local IconX = (self.height - self.iconSize) / 2
    local IconY = (self.height - self.iconSize) / 2

    if itemInfo.itemType == "fluid" then
        self:renderFluidIcon(IconX, IconY, iconAlpha)
    elseif itemInfo.scriptItem then
        local itemIcon = itemInfo.scriptItem:getNormalTexture()
        self:drawTextureScaledAspect(itemIcon, IconX, IconY, self.iconSize, self.iconSize, iconAlpha, 1, 1, 1)
    end
    
    -- Draw Item / Fluid Name
    local textX = self.height + self.padding
    local maxTextWidth = self.width - textX - self.padding
    local totalTextHeight = FONT_HGT_SMALL + FONT_HGT_SMALL * 0.8
    local availableSpace = self.height - totalTextHeight
    local spacing = availableSpace / 3

    local itemName = itemInfo.displayName
    if not itemName and itemInfo.scriptItem then
        itemName = itemInfo.scriptItem:getDisplayName()
    end
    itemName = itemName or ""
    local displayName = NeatTool.truncateText(itemName, maxTextWidth, UIFont.Small, "...")
    local TextAlpha = itemInfo.inInventory and 1.0 or 0.5

    self:drawText(displayName, textX, spacing, 1, 1, 1, TextAlpha, UIFont.Small)

    -- Draw Status Text
    local itemState = self.parentPanel.itemStates[self.itemIndex]
    local statusText = itemState and itemState.statusText or getText("IGUI_CraftUI_PossibleItems")
    local displayStatus = NeatTool.truncateText(statusText, maxTextWidth, UIFont.Small, "...")
    local statusY = spacing + FONT_HGT_SMALL + spacing

    local r, g, b = 0.4, 0.4, 0.4
    if statusText == getText("IGUI_CraftUI_AvailableItems") or statusText == ncText("IGUI_NC_AvailableContainers", "Available containers") or statusText == ncText("IGUI_NC_AvailableLiquids", "Available liquids") then
        r, g, b = 0.2, 0.6, 1.0
    elseif statusText == getText("IGUI_CraftUI_AlreadyAssigned") then
        r, g, b = 1.0, 1.0, 0.2
    elseif statusText == getText("IGUI_NC_InputItemSelected") or statusText == ncText("IGUI_NC_SelectedLiquid", "Selected liquid") then
        r, g, b = 0.2, 1.0, 0.2
    end

    self:drawTextZoomed(displayStatus, textX, statusY, 0.8, r, g, b, TextAlpha, UIFont.Small)
    
    -- Count Text
    if itemInfo.inInventory and itemInfo.Count and itemInfo.Count > 0 then
        local countText = tostring(itemInfo.Count)
        local textSize = self.height / 4
        local textWidth = NeatTool.measureTextWidth(countText, textSize, true)
        
        local countX = self.height - textWidth - self.height / 16
        local countY = self.height - textSize - self.height / 16

        NeatTool.renderText(self, countText, countX, countY, textSize, 1, 1, 1, 1, true)
    end

    if self.searchIcon and self.searchButton then
        local buttonX = self.width - self.searchButtonSize - self.padding
        local buttonY = self.height - self.searchButtonSize - self.padding
        local alpha = 0.8
        
        if self.searchButton:isMouseOver() then
            alpha = 1.0
        end
        
        self:drawTextureScaled(self.searchIcon, buttonX, buttonY, self.searchButtonSize, self.searchButtonSize, alpha, 0.8, 0.8, 0.8)
    end
end


return NC_InputSwitch_Box
