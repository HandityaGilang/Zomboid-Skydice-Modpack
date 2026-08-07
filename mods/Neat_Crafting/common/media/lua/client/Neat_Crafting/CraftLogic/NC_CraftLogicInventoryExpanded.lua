require "ISUI/ISPanel"

NC_CraftLogicInventoryExpanded = ISPanel:derive("NC_CraftLogicInventoryExpanded")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryExpanded:initialise()
    ISPanel.initialise(self)
    self:calculateAndSetHeight()
    self:prepareItemData()
end

function NC_CraftLogicInventoryExpanded:new(x, y, width, inventoryItems, parentPanel, itemIndex)
    local o = ISPanel:new(x, y, width, 10)
    setmetatable(o, self)
    self.__index = self

    o.keepOnScreen = false  -- Important!
    o.parentPanel = parentPanel
    o.itemIndex = itemIndex
    o.inventoryItems = inventoryItems or {}
    o.padding = math.floor(FONT_HGT_SMALL * 0.4)
    o.itemHeight = math.floor(FONT_HGT_SMALL * 1.5)
    o.iconSize = math.floor(FONT_HGT_SMALL * 1.2)

    o.itemData = {}
    o.tooltipItem = nil
    o.hoveredItemData = nil
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- calculate
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryExpanded:calculateAndSetHeight()
    local totalHeight = #self.inventoryItems * self.itemHeight
    self:setHeight(totalHeight)
end

function NC_CraftLogicInventoryExpanded:prepareItemData()
    self.itemData = {}
    
    local currentRecipe = self.parentPanel.logic:getRecipe()
    
    for i, item in ipairs(self.inventoryItems) do
        local itemY = (i - 1) * self.itemHeight
        
        local isCurrentRecipeItem = false
        if currentRecipe and item then
            isCurrentRecipeItem = false
        end
        
        table.insert(self.itemData, {
            item = item,
            x = self.padding,
            y = itemY,
            width = self.width - self.padding * 2,
            height = self.itemHeight,
            isHovered = false,
            isSelected = isCurrentRecipeItem
        })
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Function
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryExpanded:updateHoverStates(x, y)
    self.hoveredItemData = nil
    
    for i, itemData in ipairs(self.itemData) do
        itemData.isHovered = (x >= itemData.x and x <= itemData.x + itemData.width and
                             y >= itemData.y and y <= itemData.y + itemData.height)
        
        if itemData.isHovered then
            self.hoveredItemData = itemData
        end
    end
end

function NC_CraftLogicInventoryExpanded:onMouseMove()
    local mouseX = self:getMouseX()
    local mouseY = self:getMouseY()
    self:updateHoverStates(mouseX, mouseY)

    if self.hoveredItemData and self.hoveredItemData.item then
        if not self.tooltipItem then
            self:createTooltip(self.hoveredItemData.item)
        else
            self.tooltipItem:setItem(self.hoveredItemData.item)
        end
    else
        self:removeTooltip()
    end
    
    return true
end

function NC_CraftLogicInventoryExpanded:onMouseDown(x, y)
    self:removeTooltip()
    getSoundManager():playUISound("UIActivateButton")
    
    for i, itemData in ipairs(self.itemData) do
        if x >= itemData.x and x <= itemData.x + itemData.width and
           y >= itemData.y and y <= itemData.y + itemData.height then
            
            local item = itemData.item
            self.parentPanel:onItemSelected(item, self.itemIndex)
            return true
        end
    end
    return true
end

function NC_CraftLogicInventoryExpanded:onMouseMoveOutside()
    for _, itemData in ipairs(self.itemData) do
        itemData.isHovered = false
    end
    self.hoveredItemData = nil
    self:removeTooltip()
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryExpanded:createTooltip(item)
    if self.tooltipItem or not item then return end
    
    self.tooltipItem = ISToolTipInv:new(item)
    self.tooltipItem:addToUIManager()
    self.tooltipItem.owner = self
    self.tooltipItem:setItem(item)
    self.tooltipItem:setCharacter(self.parentPanel.player)
    self.tooltipItem:setVisible(true)
    self.tooltipItem:setAlwaysOnTop(true)
end

function NC_CraftLogicInventoryExpanded:removeTooltip()
    if self.tooltipItem then
        self.tooltipItem:setVisible(false)
        self.tooltipItem:removeFromUIManager()
        self.tooltipItem = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryExpanded:updateInventoryItems(inventoryItems)
    self.inventoryItems = inventoryItems or {}
    self:calculateAndSetHeight()
    self:prepareItemData()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicInventoryExpanded:prerender()
    if #self.inventoryItems == 0 then return end

    self:drawRect(self.padding,0,self.width - self.padding * 2,self.height,NCConfig.innerBackgroundAlpha, 0.15, 0.15, 0.15)
end

function NC_CraftLogicInventoryExpanded:render()
    if #self.inventoryItems == 0 then
        return
    end

    for i, itemData in ipairs(self.itemData) do
        local item = itemData.item
        local x = itemData.x
        local y = itemData.y
        local width = itemData.width
        local height = itemData.height

        if itemData.isSelected then
            self:drawRect(x, y, width, height, 0.6, 0.2, 0.6, 0.2)
        elseif itemData.isHovered then
            self:drawRect(x, y, width, height, 0.4, 0.4, 0.4, 0.4)
        end
        
        -- icon
        if item then
            local iconX = x + self.padding / 2
            local iconY = y + (height - self.iconSize) / 2
            
            ISInventoryItem.renderItemIcon(self, item, iconX, iconY, 1.0, self.iconSize, self.iconSize)
        end
        
        if item then
            -- name
            local itemName = item:getDisplayName() or item:getName()
            local textX = x + self.iconSize + self.padding
            local textY = y + (height - FONT_HGT_SMALL) / 2
            local maxTextWidth = width - self.iconSize - self.padding * 3
            
            local displayName = NeatTool.truncateText(itemName, maxTextWidth, UIFont.Small, "...")
            local r, g, b = 0.9, 0.9, 0.9

            if itemData.isSelected then
                r, g, b = 0.2, 1.0, 0.2
            end
            
            self:drawText(displayName, textX, textY, r, g, b, 1.0, UIFont.Small)
            
            -- count
            if item:getCount() and item:getCount() > 1 then
                local countText = tostring(item:getCount())
                local countWidth = getTextManager():MeasureStringX(UIFont.Small, countText)
                local countX = x + width - countWidth - self.padding
                
                self:drawText(countText, countX, textY, 0.7, 0.7, 0.7, 1.0, UIFont.Small)
            end
        end
    end
end

return NC_CraftLogicInventoryExpanded