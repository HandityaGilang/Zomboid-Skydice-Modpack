require "ISUI/ISPanel"

NC_OutputSwitch_Box = ISPanel:derive("NC_OutputSwitch_Box")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Box:initialise()
    ISPanel.initialise(self)
end

function NC_OutputSwitch_Box:new(x, y, width, height, itemInfo, parentPanel, itemIndex)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.itemInfo = itemInfo
    o.parentPanel = parentPanel
    o.itemIndex = itemIndex
    o.padding = math.floor(FONT_HGT_SMALL * 0.2)
    o.iconSize = math.floor(height * 0.6)
    o.searchIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_SearchItem.png")

    return o
end

function NC_OutputSwitch_Box:createChildren()
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
-- Search helpers
-- ----------------------------------------------------------------------------------------------------- --
local function NC_OutputSwitch_GetSearchComponent(handCraftPanel)
    -- Finds the shared search box regardless of whether Neat Crafting is opened as a handcraft or entity panel.
    if not handCraftPanel or not handCraftPanel.MainPanel then
        return nil
    end

    if handCraftPanel.MainPanel.header and handCraftPanel.MainPanel.header.searchComponent then
        return handCraftPanel.MainPanel.header.searchComponent
    end

    if handCraftPanel.MainPanel.parent and handCraftPanel.MainPanel.parent.header then
        return handCraftPanel.MainPanel.parent.header.searchComponent
    end

    return nil
end

function NC_OutputSwitch_Box:onSearchButtonClick()
    if not self.itemInfo or not self.itemInfo.scriptItem then return end

    local handCraftPanel = self.parentPanel and self.parentPanel.HandCraftPanel
    local searchComponent = NC_OutputSwitch_GetSearchComponent(handCraftPanel)
    if not searchComponent then return end

    -- Output search is the reverse navigation: find recipes that require this output item.
    local itemName = self.itemInfo.scriptItem:getDisplayName()
    searchComponent:setSearchMode("InputName")
    searchComponent:setSearchText(itemName)
    searchComponent:performSearch()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Function
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Box:onMouseMove()
    if self:isMouseOver() and not self.tooltip then
        self:createTooltip()
    end
    return true
end

function NC_OutputSwitch_Box:onMouseMoveOutside()
    self:removeTooltip()
    return true
end

function NC_OutputSwitch_Box:onMouseDown()
    getSoundManager():playUISound("UIActivateButton")
    self:removeTooltip()
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Box:createTooltip()
    if self.tooltip or not self.itemInfo or not self.itemInfo.scriptItem then return end

    self.tooltip = ISToolTip:new()
    self.tooltip:initialise()
    self.tooltip:instantiate()
    self.tooltip:setOwner(self)
    self.tooltip:setName(self.itemInfo.scriptItem:getDisplayName())
    self.tooltip:addToUIManager()
    self.tooltip:setVisible(true)
end

function NC_OutputSwitch_Box:removeTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Box:prerender()
    -- Keep the slot body opaque for readability on bright backgrounds.
    -- Current/possible output state is still communicated by dimming icon/text and status color.
    local bgAlpha = 1.0
    local color = self:isMouseOver() and 0.2 or 0.15

    local sloticon = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_IconSide.png")
    local slotleft = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_LEFT.png")
    if sloticon and slotleft then
        sloticon:render(self:getAbsoluteX(), self:getAbsoluteY(), self.height, self.height, color, color, color, 0.8)
        slotleft:render(self:getAbsoluteX() + self.height, self:getAbsoluteY(), self.width - self.height, self.height, color, color, color, bgAlpha)
    end

    local borderColor = self.itemInfo.isCurrentOutput and 0.6 or 0.2
    local slotboarder = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBoarder.png")
    if slotboarder then
        slotboarder:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, borderColor, borderColor, borderColor, 1)
    end
end

function NC_OutputSwitch_Box:render()
    local itemInfo = self.itemInfo
    local item = itemInfo and itemInfo.scriptItem or nil
    if not item then return end

    -- Draw item icon.
    local itemIcon = item:getNormalTexture()
    local iconAlpha = itemInfo.isCurrentOutput and 1.0 or 0.75
    local iconX = (self.height - self.iconSize) / 2
    local iconY = (self.height - self.iconSize) / 2
    self:drawTextureScaledAspect(itemIcon, iconX, iconY, self.iconSize, self.iconSize, iconAlpha, 1, 1, 1)

    -- Draw item name.
    local textX = self.height + self.padding
    local maxTextWidth = self.width - textX - self.padding
    local totalTextHeight = FONT_HGT_SMALL + FONT_HGT_SMALL * 0.8
    local availableSpace = self.height - totalTextHeight
    local spacing = availableSpace / 3

    local itemName = item:getDisplayName()
    local displayName = NeatTool.truncateText(itemName, maxTextWidth, UIFont.Small, "...")
    self:drawText(displayName, textX, spacing, 1, 1, 1, iconAlpha, UIFont.Small)

    -- Draw status text.
    local statusText = itemInfo.isCurrentOutput and "Current Output" or "Possible Output"
    local displayStatus = NeatTool.truncateText(statusText, maxTextWidth, UIFont.Small, "...")
    local statusY = spacing + FONT_HGT_SMALL + spacing
    local r, g, b = 0.4, 0.4, 0.4
    if itemInfo.isCurrentOutput then
        r, g, b = 0.2, 1.0, 0.2
    end
    self:drawTextZoomed(displayStatus, textX, statusY, 0.8, r, g, b, iconAlpha, UIFont.Small)

    -- Draw output amount when the recipe produces more than one item.
    if itemInfo.amount and itemInfo.amount > 1 then
        local countText = tostring(itemInfo.amount)
        local textSize = self.height / 4
        local textWidth = NeatTool.measureTextWidth(countText, textSize, true)
        local countX = self.height - textWidth - self.height / 16
        local countY = self.height - textSize - self.height / 16
        NeatTool.renderText(self, countText, countX, countY, textSize, 1, 1, 1, 1, true)
    end

    -- Draw search icon in the bottom-right corner.
    if self.searchIcon then
        local buttonX = self.width - self.searchButtonSize - self.padding
        local buttonY = self.height - self.searchButtonSize - self.padding
        local alpha = 0.8
        if self.searchButton and self.searchButton:isMouseOver() then
            alpha = 1.0
        end
        self:drawTextureScaled(self.searchIcon, buttonX, buttonY, self.searchButtonSize, self.searchButtonSize, alpha, 0.8, 0.8, 0.8)
    end
end

return NC_OutputSwitch_Box
