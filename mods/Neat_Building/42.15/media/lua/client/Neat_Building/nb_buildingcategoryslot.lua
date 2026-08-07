require "ISUI/ISUIElement"

NB_BuildingCategorySlot = ISUIElement:derive("NB_BuildingCategorySlot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingCategorySlot:initialise()
    ISUIElement.initialise(self)
end

function NB_BuildingCategorySlot:new(x, y, width, height, displayName, categoryValue, isSelected, parentPanel)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.displayName = displayName
    o.categoryValue = categoryValue
    o.isSelected = isSelected
    o.parentPanel = parentPanel
    o.padding = parentPanel.padding
    o.iconSize = parentPanel.iconSize
    o.showText = false
    
    o.categoryIcon = o:getCategoryIcon(displayName, categoryValue)
    o.defaultBG = getTexture("media/ui/CategoryIcon/Deflaut.png")
    
    return o
end

function NB_BuildingCategorySlot:getCategoryIcon(_displayName, categoryValue)
    local iconFile = categoryValue

    -- Use the internal category value for icon lookup so translated labels do not affect icons.
    if categoryValue == "" then
        iconFile = "ALL"
    elseif categoryValue == "*" then
        iconFile = "Favourites"
    end

    local iconPath = "media/ui/CategoryIcon/" .. iconFile .. ".png"
    
    return getTexture(iconPath)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse function
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingCategorySlot:setShowText(show)
    self.showText = show
end

function NB_BuildingCategorySlot:onMouseDown()
    if not self.isSelected then
        getSoundManager():playUISound("UIActivateButton")
        self.parentPanel:onCategoryChanged(self.categoryValue)
    end
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingCategorySlot:prerender()
    -- noBackground
end

function NB_BuildingCategorySlot:render()
    -- Draw Icon
    local iconSize = self:isMouseOver() and (self.iconSize * 1.2) or self.iconSize
    local iconX = (self.height - iconSize) / 2
    local iconY = (self.height - iconSize) / 2
    local a, r, g, b = 0.8, 0.8, 0.8, 0.8
    
    if self.isSelected then
        a, r, g, b = 1, 0.8, 0.6, 0.2
    elseif self:isMouseOver() then
        a, r, g, b = 1, 0.8, 0.8, 0.8
    end
    
    if self.categoryIcon then
        self:drawTextureScaledAspect(self.categoryIcon, iconX, iconY, iconSize, iconSize, a, r, g, b)
    else
        -- If no icon, draw first character of category name
        local firstChar = ""
        if self.displayName and #self.displayName > 0 then
            firstChar = string.sub(self.displayName, 1, 1)
        end

        local centerX = iconX + iconSize / 2
        local centerY = iconY + iconSize / 2

        self:drawTextureScaled(self.defaultBG, iconX, iconY, iconSize, iconSize, a, r, g, b)

        if firstChar ~= "" then
            local textWidth = getTextManager():MeasureStringX(UIFont.Medium, firstChar)
            local textX = centerX - textWidth / 2
            local textY = centerY - FONT_HGT_MEDIUM / 2
            self:drawText(firstChar, textX, textY, r, g, b, a, UIFont.Medium)
        end
    end
    if self.showText then
        local textX = self.height + self.padding
        local textY = (self.height - FONT_HGT_SMALL) / 2
        self:drawText(self.displayName, textX, textY, r, g, b, a, UIFont.Small)
    end
end

return NB_BuildingCategorySlot