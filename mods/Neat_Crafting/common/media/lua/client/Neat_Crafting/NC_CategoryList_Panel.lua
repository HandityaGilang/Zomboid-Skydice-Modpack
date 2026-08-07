--[[ --------------------------------------------------- --
TODO List:
Hope i can separate MOD Cate and vanilla Cate
-- --------------------------------------------------- --]]
require "ISUI/ISPanel"

NC_CategoryList_Panel = ISPanel:derive("NC_CategoryList_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- Resolve category names through mod translations first, then vanilla translations.
-- This keeps categoryValue stable for filtering while making the visible label translatable.
local NC_CATEGORY_TRANSLATION_KEYS = {
    [""] = { "UI_CraftCat_ALL", "UI_All" },
    ["*"] = { "UI_CraftCat_Favourites", "IGUI_CraftCategory_Favorite", "IGUI_CraftUI_Favorite" },
    ["Wall Coverings"] = { "UI_CraftCat_WallCoverings", "ContextMenu_WallCoverings" },
    Animals = { "UI_CraftCat_Animals", "IGUI_perks_Husbandry" },
    Blacksmithing = { "UI_CraftCat_Blacksmithing", "IGUI_perks_Blacksmith" },
    Knapping = { "UI_CraftCat_Knapping", "IGUI_perks_FlintKnapping" },
    Medical = { "UI_CraftCat_Medical", "IGUI_CraftCategory_Health", "IGUI_perks_Doctor" },
    Metalworking = { "UI_CraftCat_Metalworking", "IGUI_perks_MetalWelding" },
    Survival = { "UI_CraftCat_Survival", "IGUI_CraftCategory_Survivalist", "IGUI_perks_Survivalist" },
}

function NC_getCategoryDisplayName(categoryValue)
    if categoryValue == nil then
        return ""
    end

    local keys = NC_CATEGORY_TRANSLATION_KEYS[categoryValue]
    if keys then
        for _, key in ipairs(keys) do
            local text = getTextOrNull(key)
            if text then
                return text
            end
        end
    end

    local text = getTextOrNull("UI_CraftCat_" .. categoryValue)
        or getTextOrNull("IGUI_CraftCategory_" .. categoryValue)
        or getTextOrNull("IGUI_perks_" .. categoryValue)
        or getTextOrNull("ContextMenu_" .. categoryValue)

    return text or categoryValue
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryList_Panel:initialise()
    ISPanel.initialise(self)
end

function NC_CategoryList_Panel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic

    o.padding = HandCraftPanel.padding
    o.titleHeight = HandCraftPanel.titleHeight
    o.itemHeight = math.floor(FONT_HGT_MEDIUM * 1.5)
    o.scrollBarWidth = FONT_HGT_SMALL * 0.6
    o.iconSize = math.floor(o.itemHeight*0.8)
    o.fixedheight = o.itemHeight * 2
    o.categories = {}
    o.selectedCategory = ""
    
    return o
end

function NC_CategoryList_Panel:calculateLayout(preferredWidth, _preferredHeight)
    local width = preferredWidth
    local height = _preferredHeight or self.height

    self.scrollView:setWidth(width)
    self.scrollView:setHeight(height - self.fixedheight)

    self:setWidth(width)
    self:setHeight(height)
end
-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryList_Panel:createChildren()
    self.allItem = NC_CategoryList_Slot:new(self.padding, 0, self.itemHeight, self.itemHeight, NC_getCategoryDisplayName(""), "", true, self)
    self.allItem:initialise()
    self:addChild(self.allItem)
    
    self.favItem = NC_CategoryList_Slot:new(self.padding, self.itemHeight, self.itemHeight, self.itemHeight, NC_getCategoryDisplayName("*"), "*", false, self)
    self.favItem:initialise()
    self:addChild(self.favItem)

    self.scrollView = NIScrollView:new(0, self.fixedheight, self.width, self.height - self.fixedheight)
    self.scrollView:setAutoHideScrollbar(true)
    self.scrollView:initialise()
    self.scrollView:setScrollDirection("vertical")
    self.scrollView:setScrollSensitivity(self.itemHeight)
    self:addChild(self.scrollView)

    self:populateCategoryList()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Build CategoryList
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryList_Panel:populateCategoryList()

    for i = 1, #self.categories do
        self.scrollView:removeScrollChild(self.categories[i])
    end
    self.categories = {}
    
    local categories = self.logic:getCategoryList()
    if categories then  
        local categoriesWithIcon = {}
        local categoriesWithoutIcon = {}
        
        for i = 0, categories:size() - 1 do
            local categoryValue = categories:get(i)
            local iconPath = "media/ui/CategoryIcon/" .. categoryValue .. ".png"
            local hasIcon = getTexture(iconPath) ~= nil
            
            if hasIcon then
                table.insert(categoriesWithIcon, categoryValue)
            else
                table.insert(categoriesWithoutIcon, categoryValue)
            end
        end
        
        -- get vanilla first (need a category:isvanilla())
        for _, categoryValue in ipairs(categoriesWithIcon) do
            local displayName = NC_getCategoryDisplayName(categoryValue)
            local isSelected = (categoryValue == self.selectedCategory)
            self:addCategoryItem(displayName, categoryValue, isSelected)
        end
        
        -- get mod category
        for _, categoryValue in ipairs(categoriesWithoutIcon) do
            local displayName = NC_getCategoryDisplayName(categoryValue)
            local isSelected = (categoryValue == self.selectedCategory)
            self:addCategoryItem(displayName, categoryValue, isSelected)
        end
    end

    local totalHeight = #self.categories * (self.itemHeight)
    self.scrollView:setScrollHeight(math.max(totalHeight, self.scrollView:getHeight()))
end

-- add category
function NC_CategoryList_Panel:addCategoryItem(displayName, categoryValue, isSelected)
    local itemY = #self.categories * (self.itemHeight)
    
    local categoryItem = NC_CategoryList_Slot:new(
        self.padding, itemY, self.itemHeight, self.itemHeight,
        displayName, categoryValue, isSelected, self
    )
    categoryItem:initialise()
    
    self.scrollView:addScrollChild(categoryItem)
    table.insert(self.categories, categoryItem)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse over show text
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryList_Panel:calculateTextPanelSizeAndPosition()
    local maxTextWidth = 0
    local allDisplayName = NC_getCategoryDisplayName("")
    local favDisplayName = NC_getCategoryDisplayName("*")
    
    local allTextWidth = getTextManager():MeasureStringX(UIFont.Small, allDisplayName)
    local favTextWidth = getTextManager():MeasureStringX(UIFont.Small, favDisplayName)
    
    if allTextWidth > maxTextWidth then
        maxTextWidth = allTextWidth
    end
    if favTextWidth > maxTextWidth then
        maxTextWidth = favTextWidth
    end

    local categories = self.logic:getCategoryList()
    if categories then  
        for i = 0, categories:size() - 1 do
            local displayName = NC_getCategoryDisplayName(categories:get(i))
            local textWidth = getTextManager():MeasureStringX(UIFont.Small, displayName)
            if textWidth > maxTextWidth then
                maxTextWidth = textWidth
            end
        end
    end

    local panelWidth = math.floor(maxTextWidth + self.padding * 4)
    local panelHeight = self.height
    local panelX = self:getAbsoluteX() - panelWidth
    local panelY = self:getAbsoluteY()
    
    return panelX, panelY, panelWidth, panelHeight
end

-- show
function NC_CategoryList_Panel:showCategoryTextPanel()
    if not self.categoryTextPanel then
        local panelX, panelY, panelWidth, panelHeight = self:calculateTextPanelSizeAndPosition()
        self.categoryTextPanel = NC_CategoryText_Panel:new(panelX, panelY, panelWidth, panelHeight, self)
        self.categoryTextPanel:initialise()
        self.categoryTextPanel:addToUIManager()
        self.categoryTextPanel:setVisible(true)
    end
end

-- hide
function NC_CategoryList_Panel:hideCategoryTextPanel()
    if self.categoryTextPanel then
        self.categoryTextPanel:setVisible(false)
        self.categoryTextPanel:removeFromUIManager()
        self.categoryTextPanel = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse function
-- ----------------------------------------------------------------------------------------------------- --

function NC_CategoryList_Panel:update()
end

function NC_CategoryList_Panel:onMouseMove()
    self:showCategoryTextPanel()
    return true
end

function NC_CategoryList_Panel:onMouseMoveOutside()
    self:hideCategoryTextPanel()
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryList_Panel:onCategoryChanged(categoryValue)
    self.selectedCategory = categoryValue

    self.allItem.isSelected = (categoryValue == "")
    self.favItem.isSelected = (categoryValue == "*")

    for i = 1, #self.categories do
        local item = self.categories[i]
        item.isSelected = (item.categoryValue == categoryValue)
    end
    
    self.HandCraftPanel:onCategoryChanged(categoryValue)
end
-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CategoryList_Panel:prerender()

    local panelbackground = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/CategoryBG_RightAngle.png")
    local pinbackground = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/CategoryBG_Pin.png")
    if panelbackground and pinbackground then
        panelbackground:render(self:getAbsoluteX(), self:getAbsoluteY() + self.fixedheight - 1, self.width - self.scrollBarWidth, self.height-self.fixedheight+1, 0.15, 0.15, 0.15, NCConfig.recipeListBackgroundAlpha)
        pinbackground:render(self:getAbsoluteX(), self:getAbsoluteY() + 1, self.width - self.scrollBarWidth, self.fixedheight - 1, 0.13, 0.13, 0.13, NCConfig.categoryPinnedAlpha)
    end
end

function NC_CategoryList_Panel:render()
end

return NC_CategoryList_Panel