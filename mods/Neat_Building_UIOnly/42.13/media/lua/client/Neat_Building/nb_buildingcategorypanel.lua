require "ISUI/ISPanel"

NB_BuildingCategoryPanel = ISPanel:derive("NB_BuildingCategoryPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- Resolve category names through mod translations first, then vanilla translations.
-- This keeps categoryValue stable for filtering while making the visible label translatable.
local NB_CATEGORY_TRANSLATION_KEYS = {
    [""] = { "UI_CraftCat_ALL", "UI_All" },
    ["*"] = { "UI_CraftCat_Favourites", "IGUI_CraftCategory_Favorite", "IGUI_CraftUI_Favorite" },
    Debug = { "UI_CraftCat_Debug", "UI_CraftCat_Dubug" },
    Blacksmithing = { "UI_CraftCat_Blacksmithing", "IGUI_perks_Blacksmith" },
    Knapping = { "UI_CraftCat_Knapping", "IGUI_perks_FlintKnapping" },
    Metalworking = { "UI_CraftCat_Metalworking", "IGUI_perks_MetalWelding" },
    Animals = { "UI_CraftCat_Animals", "IGUI_perks_Husbandry" },
    Medical = { "UI_CraftCat_Medical", "IGUI_CraftCategory_Health", "IGUI_perks_Doctor" },
    Survival = { "UI_CraftCat_Survival", "IGUI_CraftCategory_Survivalist", "IGUI_perks_Survivalist" },
    ["Wall Coverings"] = { "UI_CraftCat_WallCoverings", "ContextMenu_WallCoverings" },
}

function NB_getCategoryDisplayName(categoryValue)
    if categoryValue == nil then
        return ""
    end

    local keys = NB_CATEGORY_TRANSLATION_KEYS[categoryValue]
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
function NB_BuildingCategoryPanel:initialise()
    ISPanel.initialise(self)
end

function NB_BuildingCategoryPanel:new(x, y, width, height, BuildingPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.BuildingPanel = BuildingPanel
    o.player = BuildingPanel.player
    o.logic = BuildingPanel.logic

    o.padding = BuildingPanel.padding
    o.itemHeight = math.floor(FONT_HGT_MEDIUM * 1.5)
    o.scrollBarWidth = BuildingPanel.scrollBarWidth
    o.iconSize = math.floor(o.itemHeight * 0.8)
    o.categories = {}
    o.selectedCategory = ""
    o.fixedheight = o.itemHeight * 2

    o.minimumWidth = o.itemHeight + o.padding * 2 + o.scrollBarWidth
    o.minimumHeight = o.itemHeight * 13
    
    
    return o
end

function NB_BuildingCategoryPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.minimumWidth)
    local height = math.max(_preferredHeight or 0, self.minimumHeight)

    if self.scrollView then
        self.scrollView:setWidth(width)
        self.scrollView:setHeight(height - self.fixedheight)
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingCategoryPanel:createChildren()

    -- All Buildings item
    self.allItem = NB_BuildingCategorySlot:new(self.padding, 0, self.itemHeight, self.itemHeight, NB_getCategoryDisplayName(""), "", true, self)
    self.allItem:initialise()
    self:addChild(self.allItem)
    
    -- Favourites item
    self.favItem = NB_BuildingCategorySlot:new(self.padding, self.itemHeight, self.itemHeight, self.itemHeight, NB_getCategoryDisplayName("*"), "*", false, self)
    self.favItem:initialise()
    self:addChild(self.favItem)

    -- Scroll view for categories
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
function NB_BuildingCategoryPanel:populateCategoryList()
    for i = 1, #self.categories do
        self.scrollView:removeScrollChild(self.categories[i])
    end
    self.categories = {}
    
    local categories = self.logic:getCategoryList()
    
    if categories then  
        local categoriesWithIcon = {}
        local categoriesWithoutIcon = {}
        
        -- Separate categories by whether they have icons
        for i = 0, categories:size() - 1 do
            local categoryValue = categories:get(i)
            
            -- debug cate
            local isDebugCategory = string.lower(categoryValue):find("debug") ~= nil
            local shouldShow = not isDebugCategory or getDebug()
            
            if shouldShow then
                local iconPath = "media/ui/CategoryIcon/" .. categoryValue .. ".png"
                local hasIcon = getTexture(iconPath) ~= nil
                
                if hasIcon then
                    table.insert(categoriesWithIcon, categoryValue)
                else
                    table.insert(categoriesWithoutIcon, categoryValue)
                end
            end
        end
        
        -- Add categories with icons first (vanilla categories)
        for _, categoryValue in ipairs(categoriesWithIcon) do
            local displayName = NB_getCategoryDisplayName(categoryValue)
            local isSelected = (categoryValue == self.selectedCategory)
            self:addCategoryItem(displayName, categoryValue, isSelected)
        end
        
        -- Add modded categories without icons
        for _, categoryValue in ipairs(categoriesWithoutIcon) do
            local displayName = NB_getCategoryDisplayName(categoryValue)
            local isSelected = (categoryValue == self.selectedCategory)
            self:addCategoryItem(displayName, categoryValue, isSelected)
        end
    end

    -- Set scroll height
    local totalHeight = #self.categories * self.itemHeight
    self.scrollView:setScrollHeight(math.max(totalHeight, self.scrollView:getHeight()))
end

-- Add category item
function NB_BuildingCategoryPanel:addCategoryItem(displayName, categoryValue, isSelected)
    local itemY = #self.categories * self.itemHeight
    
    local categoryItem = NB_BuildingCategorySlot:new(
        self.padding, itemY, self.itemHeight, self.itemHeight,
        displayName, categoryValue, isSelected, self
    )
    categoryItem:initialise()
    
    self.scrollView:addScrollChild(categoryItem)
    table.insert(self.categories, categoryItem)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Handle
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingCategoryPanel:onMouseMove()
    local maxTextWidth = self:calculateMaxTextWidth()
    local newWidth = self.minimumWidth + maxTextWidth + self.padding

    self.allItem:setShowText(true)
    self.allItem:setWidth(newWidth - self.scrollBarWidth)
    
    self.favItem:setShowText(true)
    self.favItem:setWidth(newWidth - self.scrollBarWidth)
    
    for i = 1, #self.categories do
        self.categories[i]:setShowText(true)
        self.categories[i]:setWidth(newWidth - self.scrollBarWidth)
    end
    
    self:calculateLayout(newWidth, self.height)
    return true
end

function NB_BuildingCategoryPanel:onMouseMoveOutside()
    self.allItem:setShowText(false)
    self.allItem:setWidth(self.itemHeight)
    
    self.favItem:setShowText(false)
    self.favItem:setWidth(self.itemHeight)
    
    for i = 1, #self.categories do
        self.categories[i]:setShowText(false)
        self.categories[i]:setWidth(self.itemHeight)
    end
    
    self:calculateLayout(self.minimumWidth, self.height)
    return true
end

function NB_BuildingCategoryPanel:calculateMaxTextWidth()
    local maxWidth = 0
    
    local allText = NB_getCategoryDisplayName("")
    local favText = NB_getCategoryDisplayName("*")
    
    maxWidth = math.max(maxWidth, getTextManager():MeasureStringX(UIFont.Small, allText))
    maxWidth = math.max(maxWidth, getTextManager():MeasureStringX(UIFont.Small, favText))
    
    local categories = self.logic:getCategoryList()
    if categories then
        for i = 0, categories:size() - 1 do
            local displayName = NB_getCategoryDisplayName(categories:get(i))
            local textWidth = getTextManager():MeasureStringX(UIFont.Small, displayName)
            maxWidth = math.max(maxWidth, textWidth)
        end
    end
    
    return maxWidth
end
-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingCategoryPanel:update()
    ISPanel.update(self)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Event Handlers
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingCategoryPanel:onCategoryChanged(categoryValue)
    self.selectedCategory = categoryValue

    self.allItem.isSelected = (categoryValue == "")
    self.favItem.isSelected = (categoryValue == "*")

    for i = 1, #self.categories do
        local item = self.categories[i]
        item.isSelected = (item.categoryValue == categoryValue)
    end

    self.BuildingPanel:onCategoryChanged(categoryValue)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingCategoryPanel:prerender()
    -- Draw panel background
    local alpha = self.BuildingPanel.isCollapse and 1.0 or 0.8
    local panelBG = self.BuildingPanel.isCollapse and NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Panel/CategoryBG_Collapse.png") or NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Panel/CategoryBG_Normal.png")
    if panelBG then
        panelBG:render(self:getAbsoluteX(), self:getAbsoluteY() + self.fixedheight, self.width - self.scrollBarWidth, self.height - self.fixedheight, 0.15, 0.15, 0.15, alpha)
    end

    -- Draw pinned items background
    local pinBG = self.BuildingPanel.isCollapse and NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Panel/CategoryBG_Pin_Collapse.png") or NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Panel/CategoryBG_Pin_Normal.png")
    if pinBG then
        pinBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width - self.scrollBarWidth, self.fixedheight, 0.13, 0.13, 0.13, alpha)
    end

end

return NB_BuildingCategoryPanel