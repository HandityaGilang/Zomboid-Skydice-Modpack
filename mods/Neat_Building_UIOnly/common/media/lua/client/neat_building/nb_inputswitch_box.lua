require "ISUI/ISPanel"

-- NB_InputSwitch_Box.lua
-- Group header box (ScriptItem). Shows icon/name + status line, and toggles expansion.

NB_InputSwitch_Box = ISPanel:derive("NB_InputSwitch_Box")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function NB_InputSwitch_Box:new(x, y, width, height, player, itemInfo, parentPanel, itemIndex)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.itemInfo = itemInfo
    o.parentPanel = parentPanel
    o.itemIndex = itemIndex

    o.padding = math.max(2, math.floor(FONT_HGT_SMALL * 0.2))
    local maxIcon = math.max(16, math.min(height - o.padding * 2, math.floor(FONT_HGT_SMALL * 1.0)))
    o.iconSize = math.floor(maxIcon / 4) * 4

    -- Textures (Neat Building theme)
    o.bgIconSide = getTexture("media/ui/Neat_Building/Button/SlotBG_IconSide.png")
    o.bgLeft = getTexture("media/ui/Neat_Building/Button/SlotBG_LEFT.png")
    o.border = getTexture("media/ui/Neat_Building/Button/SlotBoarder.png")

    return o
end

function NB_InputSwitch_Box:initialise()
    ISPanel.initialise(self)
end

function NB_InputSwitch_Box:render()
    local itemInfo = self.itemInfo
    if not itemInfo or not itemInfo.scriptItem then return end

    -- Background (NC-style ninepatch, scale-safe)
    local absX, absY = self:getAbsoluteX(), self:getAbsoluteY()
    local color = self:isMouseOver() and 0.2 or 0.15
    local bgAlpha = 0.8

    if NinePatchTexture and NinePatchTexture.getSharedTexture then
        local sloticon = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Button/SlotBG_IconSide.png")
        local slotleft = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Button/SlotBG_LEFT.png")
        if sloticon and slotleft then
            sloticon:render(absX, absY, self.height, self.height, color, color, color, bgAlpha)
            slotleft:render(absX + self.height, absY, self.width - self.height, self.height, color, color, color, bgAlpha)
        end

        local slotborder = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Button/SlotBoarder.png")
        if slotborder then
            slotborder:render(absX, absY, self.width, self.height, color, color, color, bgAlpha)
        end
    else
        -- Fallback: plain scaled textures (older UI env)
        if self.bgIconSide then
            self:drawTextureScaled(self.bgIconSide, 0, 0, self.height, self.height, 1, 1, 1, 1)
        end
        if self.bgLeft then
            self:drawTextureScaled(self.bgLeft, self.height, 0, self.width - self.height, self.height, 1, 1, 1, 1)
        end
        if self.border then
            self:drawTextureScaled(self.border, 0, 0, self.width, self.height, 1, 1, 1, 1)
        end
    end

    local alpha = itemInfo.inInventory and 1.0 or 0.5

    -- Icon (ScriptItem texture).
    local scriptItem = itemInfo.scriptItem
    local tex = scriptItem.getNormalTexture and scriptItem:getNormalTexture() or nil
    if tex then
        local iconX = (self.height - self.iconSize) / 2
        local iconY = (self.height - self.iconSize) / 2
        self:drawTextureScaled(tex, iconX, iconY, self.iconSize, self.iconSize, alpha, 1, 1, 1)
    end

    -- Name text.
    local textX = self.height + self.padding
    local maxTextWidth = self.width - textX - self.padding

    local displayName = scriptItem.getDisplayName and scriptItem:getDisplayName() or scriptItem:getFullName()
    local name = NeatTool and NeatTool.truncateText
        and NeatTool.truncateText(displayName, maxTextWidth, UIFont.Small, "...")
        or displayName

    self:drawText(name, textX, self.padding, 1, 1, 1, alpha, UIFont.Small)

    -- Status line.
    local st = self.parentPanel.itemStates[self.itemIndex]
    local statusText = st and st.statusText or getText("UI_NB_InputStatusPossible")
    local statusY = self.padding + FONT_HGT_SMALL + math.max(1, math.floor(self.padding * 0.5))

    local r, g, b = 0.4, 0.4, 0.4
    if statusText == getText("UI_NB_InputStatusAvailable") then
        r, g, b = 0.2, 0.6, 1.0
    elseif statusText == getText("UI_NB_InputStatusUsedByOther") then
        r, g, b = 1.0, 1.0, 0.2
    elseif statusText == getText("UI_NB_InputStatusSelected") then
        r, g, b = 0.2, 1.0, 0.2
    end

    local status = NeatTool and NeatTool.truncateText
        and NeatTool.truncateText(statusText, maxTextWidth, UIFont.Small, "...")
        or statusText

    self:drawTextZoomed(status, textX, statusY, 0.8, r, g, b, alpha, UIFont.Small)

    -- Count (top-right) for inventory groups.
    if itemInfo.inInventory and itemInfo.Count and itemInfo.Count > 0 then
        local countText = tostring(itemInfo.Count)
        local tw = getTextManager():MeasureStringX(UIFont.Small, countText)
        self:drawText(countText, self.width - tw - self.padding, self.padding, 1, 1, 1, alpha, UIFont.Small)
    end
end

function NB_InputSwitch_Box:onMouseDown(x, y)
    getSoundManager():playUISound("UIActivateButton")

    -- Only toggle expansion for groups that have inventory items.
    if self.itemInfo and self.itemInfo.inInventory and self.itemInfo.AvailableItems and #self.itemInfo.AvailableItems > 0 then
        self.parentPanel:toggleItemExpanded(self.itemIndex)
    end
    return true
end

return NB_InputSwitch_Box
