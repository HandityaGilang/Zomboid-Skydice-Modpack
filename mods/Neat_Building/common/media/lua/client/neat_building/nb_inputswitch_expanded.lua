require "ISUI/ISPanel"

-- NB_InputSwitch_Expanded.lua
-- Expanded list of InventoryItems for a group (ScriptItem).
-- Clicking a row notifies the parent picker to toggle selection for that InventoryItem.

NB_InputSwitch_Expanded = ISPanel:derive("NB_InputSwitch_Expanded")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Expanded:initialise()
    ISPanel.initialise(self)
    self:calculateAndSetHeight()
    self:prepareExpandedItemsData()
end

function NB_InputSwitch_Expanded:new(x, y, width, inventoryItems, parentPanel, itemIndex)
    -- Height is calculated based on item count (NC style).
    local o = ISPanel:new(x, y, width, 10)
    setmetatable(o, self)
    self.__index = self

    o.keepOnScreen = false -- Parent scroll view handles clipping.

    o.parentPanel = parentPanel
    o.itemIndex = itemIndex
    o.inventoryItems = inventoryItems or {}

    -- Layout (match NC proportions)
    o.padding = math.max(2, math.floor(FONT_HGT_SMALL * 0.4))
    o.rowH = math.max(20, math.floor(FONT_HGT_SMALL * 1.2))
    o.iconSize = math.max(16, math.min(o.rowH - math.floor(o.padding * 0.5), math.floor(FONT_HGT_SMALL * 1.0)))

    o.expandedItemsData = {}

    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Internal helpers
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Expanded:calculateAndSetHeight()
    -- NC behavior: no extra vertical padding, the rows define the height.
    local totalHeight = #self.inventoryItems * self.rowH
    self:setHeight(totalHeight)
end

function NB_InputSwitch_Expanded:prepareExpandedItemsData()
    -- Rebuild clickable row rects based on current item states from the parent panel.
    self.expandedItemsData = {}

    local st = self.parentPanel and self.parentPanel.itemStates and self.parentPanel.itemStates[self.itemIndex] or nil
    local stateMap = (st and st.expandedItemStates) or {}

    for i, item in ipairs(self.inventoryItems) do
        local itemY = (i - 1) * self.rowH
        table.insert(self.expandedItemsData, {
            item = item,
            x = self.padding,
            y = itemY,
            width = self.width - self.padding * 2,
            height = self.rowH,
            status = stateMap[item] or "normal",
        })
    end
end

function NB_InputSwitch_Expanded:prerender()
    -- Keep row states updated every frame (selection can change while the panel is open).
    self:prepareExpandedItemsData()
end

-- ----------------------------------------------------------------------------------------------------- --
-- render
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Expanded:render()
    if #self.inventoryItems == 0 then return end

    -- Background panel (NC style)
    self:drawRect(self.padding, 0, self.width - self.padding * 2, self.height, 0.8, 0.15, 0.15, 0.15)

    for _, itemData in ipairs(self.expandedItemsData) do
        local item = itemData.item
        local x = itemData.x
        local y = itemData.y
        local w = itemData.width
        local h = itemData.height

        -- Background color by status (match NC semantics).
        if itemData.status == "selected" then
            -- Selected by current input (green).
            self:drawRect(x, y, w, h, 0.50, 0.20, 0.60, 0.20)
        elseif itemData.status == "usedByOther" then
            -- Used by another input (yellow).
            self:drawRect(x, y, w, h, 0.40, 0.80, 0.80, 0.20)
        else
            -- Normal/unselected (grey).
            self:drawRect(x, y, w, h, 0.30, 0.40, 0.40, 0.40)
        end

        if item then
            -- Icon.
            local iconX = x + self.padding / 2
            local iconY = y + (h - self.iconSize) / 2
            local iconAlpha = (itemData.status == "usedByOther") and 0.7 or 1.0
            ISInventoryItem.renderItemIcon(self, item, iconX, iconY, iconAlpha, self.iconSize, self.iconSize)

            -- Name.
            local nameX = iconX + self.iconSize + self.padding
            local nameY = y + (h - FONT_HGT_SMALL) / 2
            local name = item.getDisplayName and item:getDisplayName() or (item.getFullType and item:getFullType() or "Item")
            local alpha = (itemData.status == "usedByOther") and 0.7 or 1.0
            self:drawText(name, nameX, nameY, 1, 1, 1, alpha, UIFont.Small)
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- mouse
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Expanded:onMouseDown(x, y)
    getSoundManager():playUISound("UIActivateButton")

    for _, itemData in ipairs(self.expandedItemsData) do
        if x >= itemData.x and x <= itemData.x + itemData.width and
           y >= itemData.y and y <= itemData.y + itemData.height then
            if itemData.item and self.parentPanel and self.parentPanel.onItemSelected then
                self.parentPanel:onItemSelected(itemData.item)
            end
            return true
        end
    end

    return true
end

return NB_InputSwitch_Expanded
