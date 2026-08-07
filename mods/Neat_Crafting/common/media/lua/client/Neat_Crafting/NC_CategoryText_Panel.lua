require "ISUI/ISPanel"

NC_CategoryText_Panel = ISPanel:derive("NC_CategoryText_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryText_Panel:initialise()
    ISPanel.initialise(self)
    self:updateCategoryList()
end

function NC_CategoryText_Panel:new(x, y, width, height, categoryPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o:noBackground()
    o.keepOnScreen = false
    o.categoryPanel = categoryPanel
    o.padding = categoryPanel.padding
    o.itemHeight = categoryPanel.itemHeight
    o.iconSize = categoryPanel.iconSize
    o.fixedheight = categoryPanel.fixedheight
    o.categories = {}
    o.fixedCategories = {}

    o.textBG = {
        left = getTexture("media/ui/Neat_Crafting/Panel/CategoryText_L.png"),
        middle = getTexture("media/ui/Neat_Crafting/Panel/CategoryText_M.png"),
        right = getTexture("media/ui/Neat_Crafting/Panel/CategoryText_R.png")
    }
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- update Category List
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryText_Panel:updateCategoryList()
    self.categories = {}
    self.fixedCategories = {}

    table.insert(self.fixedCategories, {
        displayName = NC_getCategoryDisplayName and NC_getCategoryDisplayName("") or (getTextOrNull("UI_CraftCat_ALL") or "ALL"),
    })
    table.insert(self.fixedCategories, {
        displayName = NC_getCategoryDisplayName and NC_getCategoryDisplayName("*") or (getTextOrNull("UI_CraftCat_Favourites") or "Favourites"),
    })

    if self.categoryPanel.categories then
        for i = 1, #self.categoryPanel.categories do
            local categorySlot = self.categoryPanel.categories[i]
            table.insert(self.categories, {
                displayName = categorySlot.displayName,
            })
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryText_Panel:prerender()
    if self.categoryPanel and not self.categoryPanel:isReallyVisible() then
        self:removeFromUIManager()
		self:setVisible(false)
		return
	end
end

function NC_CategoryText_Panel:render()
    -- Render fixedCategories
    if self.fixedCategories then
        for i, category in ipairs(self.fixedCategories) do
            local itemY = (i-1) * self.itemHeight
            self:renderCategoryItem(category, itemY)
        end
    end
    
    -- Render Others
    local scrollY = self.categoryPanel.scrollView:getYScroll()
    self:setStencilRect(0, self.fixedheight, self.width, self.height - self.fixedheight)
    local baseY = self.fixedheight + scrollY
    for i, category in ipairs(self.categories) do
        local itemY = baseY + (i-1) * self.itemHeight
        local textY = itemY + (self.itemHeight - FONT_HGT_SMALL) / 2
        if textY >= self.fixedheight - self.itemHeight and textY <= self.height then
        self:renderCategoryItem(category, itemY)
        end
    end
    self:clearStencilRect()
end

function NC_CategoryText_Panel:renderCategoryItem(category, itemY)
    local textY = itemY + (self.itemHeight - FONT_HGT_SMALL) / 2
    local textWidth = getTextManager():MeasureStringX(UIFont.Small, category.displayName)
    local textX = self.width - textWidth - self.padding
    local bgWidth = textWidth + self.padding * 3
    local bgX = self.width - bgWidth
    local bgY = itemY + (self.itemHeight - self.iconSize) / 2
    if self.textBG.left and self.textBG.middle and self.textBG.right then
        NeatTool.ThreePatch.drawHorizontal(
            self,
            bgX, bgY,
            bgWidth, self.iconSize,
            self.textBG.left,
            self.textBG.middle,
            self.textBG.right,
            0.8, 0.1, 0.1, 0.1
        )
    end

    self:drawText(category.displayName, textX, textY, 1, 1, 1, 1, UIFont.Small)
end

return NC_CategoryText_Panel