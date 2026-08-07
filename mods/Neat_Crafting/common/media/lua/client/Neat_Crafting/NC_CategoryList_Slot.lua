require "ISUI/ISPanel"

NC_CategoryList_Slot = ISUIElement:derive("NC_CategoryList_Slot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryList_Slot:initialise()
    ISUIElement.initialise(self)
end

function NC_CategoryList_Slot:new(x, y, width, height, displayName, categoryValue, isSelected, parentPanel)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.displayName = displayName
    o.categoryValue = categoryValue
    o.isSelected = isSelected
    o.parentPanel = parentPanel
    o.padding = parentPanel.padding
    o.iconSize = parentPanel.iconSize
    
    o.categoryIcon = o:getCategoryIcon(displayName,categoryValue)
    o.DeflautBG = getTexture("media/ui/CategoryIcon/Deflaut.png")
    
    return o
end

function NC_CategoryList_Slot:getCategoryIcon(_displayName, categoryValue)
    local IconFile = categoryValue

    -- Use the internal category value for icon lookup so translated labels do not affect icons.
    if categoryValue == "" then
        IconFile = "ALL"
    elseif categoryValue == "*" then
        IconFile = "Favourites"
    end

    local iconPath = "media/ui/CategoryIcon/" .. IconFile .. ".png"

    return getTexture(iconPath)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse function
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryList_Slot:onMouseDown()
    if not self.isSelected then
        getSoundManager():playUISound("UIActivateButton")
        self.parentPanel:onCategoryChanged(self.categoryValue)
    end
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryList_Slot:prerender()
end

function NC_CategoryList_Slot:render()
    -- Draw Icon
    local IconSize = self:isMouseOver() and (self.iconSize * 1.2) or self.iconSize
    local iconX = (self.height - IconSize) / 2
    local iconY = (self.height - IconSize) / 2
    local a,r,g,b = 0.8,0.8,0.8,0.8
    if self.isSelected then
        a,r,g,b = 1,0.8,0.6,0.2
    end
    
    if self.categoryIcon then
        self:drawTextureScaledAspect(
            self.categoryIcon, 
            iconX, iconY, 
            IconSize, IconSize, 
            a, r, g, b
        )
    else
        -- if no Icon,we draw firstChar
        local firstChar = ""
        if self.displayName and #self.displayName > 0 then
            firstChar = string.sub(self.displayName, 1, 1)
        end

        local centerX = iconX + IconSize / 2
        local centerY = iconY + IconSize / 2
        self:drawTextureScaled(self.DeflautBG,iconX, iconY,IconSize, IconSize,a, r, g, b)
        if firstChar ~= "" then
            local textWidth = getTextManager():MeasureStringX(UIFont.Medium, firstChar)
            local textX = centerX - textWidth / 2
            local textY = centerY - FONT_HGT_MEDIUM / 2
            self:drawText(firstChar, textX, textY, r, g, b, a, UIFont.Medium)
        end
    end
end

return NC_CategoryList_Slot