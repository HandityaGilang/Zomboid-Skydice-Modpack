require "ISUI/ISPanel"

PJCK_RecipeInfoPanel = ISPanel:derive("PJCK_RecipeInfoPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_RecipeInfoPanel:initialise()
    ISPanel.initialise(self)
end

function PJCK_RecipeInfoPanel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    
    -- 布局设置
    o.padding = FONT_HGT_SMALL * 0.2
    o.iconSize = height *0.6
    o.iconAreaWidth = height
    
    -- 状态图标纹理
    o.skillIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Book.png")
    o.lightIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Light.png")
    o.surfaceIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Surface.png")
    o.walkIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Walking.png")
    
    -- RequireIcons 相关
    o.requireIcons = {}
    o.requireIconsCreated = false
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- 创建子元素
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_RecipeInfoPanel:createChildren()
    -- 创建固定的三个图标位置
    self:createRequireIcons()
end

function PJCK_RecipeInfoPanel:createRequireIcons()
    if self.requireIconsCreated then
        return
    end
    
    local statusIconSize = (self.height - (self.padding*4 ))/3
    local iconSpacing = self.padding
    local rightMargin = self.padding
    local iconX = self.width - rightMargin - statusIconSize
    
    -- 创建三个固定位置的图标
    for i = 1, 3 do
        local iconY = self.padding + (i - 1) * (statusIconSize + iconSpacing)
        
        local icon = ISImage:new(iconX, iconY, statusIconSize, statusIconSize, self.lightIconTexture)
        icon.autoScale = true
        icon:initialise()
        icon:instantiate()
        icon:setVisible(false)
        icon:setColor(1.0, 1.0, 1.0)
        icon.mouseovertext = ""
        
        self:addChild(icon)
        self.requireIcons[i] = icon
    end
    
    self.requireIconsCreated = true
end

-- ----------------------------------------------------------------------------------------------------- --
-- 更新图标状态
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_RecipeInfoPanel:updateRequireIcons(recipe)
    if not self.requireIconsCreated then
        self:createRequireIcons()
    end
    
    -- 先隐藏所有图标
    for i = 1, 3 do
        self.requireIcons[i]:setVisible(false)
    end
    
    if not recipe then return end

    local iconsToShow = {}
    
    -- 光线要求图标
    if not recipe:canBeDoneInDark() then
        local tooDark = self.player:tooDarkToRead()
        table.insert(iconsToShow, {
            texture = self.lightIconTexture,
            color = tooDark and {r=1.0, g=0.2, b=0.2} or {r=1.0, g=1.0, b=1.0},
            tooltip = getText("IGUI_CraftingWindow_RequiresLight")
        })
    end

    -- 学习要求图标
    if recipe:needToBeLearn() then
        local learned = self.player:isRecipeKnown(recipe, true)
        table.insert(iconsToShow, {
            texture = self.skillIconTexture,
            color = learned and {r=1.0, g=1.0, b=1.0} or {r=1.0, g=0.2, b=0.2},
            tooltip = learned and getText("IGUI_CraftingWindow_RecipeKnown") or getText("IGUI_CraftingWindow_RequiresLearning")
        })
    end
    
    -- 表面要求图标
    if not recipe:isInHandCraftCraft() then
        local inRangeOfWorkbench = self.logic:isCharacterInRangeOfWorkbench()
        table.insert(iconsToShow, {
            texture = self.surfaceIconTexture,
            color = inRangeOfWorkbench and {r=1.0, g=1.0, b=1.0} or {r=1.0, g=0.2, b=0.2},
            tooltip = inRangeOfWorkbench and "Work surface available" or getText("IGUI_CraftingWindow_RequiresSurface")
        })
    end

    -- 行走制作图标
    if recipe:isCanWalk() and not self.player:hasAwkwardHands() then
        table.insert(iconsToShow, {
            texture = self.walkIconTexture,
            color = {r=1.0, g=1.0, b=1.0},
            tooltip = getText("IGUI_CraftingWindow_CanWalk")
        })
    end
    
    -- 更新图标
    for i = 1, math.min(#iconsToShow, 3) do
        local iconData = iconsToShow[i]
        local icon = self.requireIcons[i]
        icon.texture = iconData.texture
        icon:setColor(iconData.color.r, iconData.color.g, iconData.color.b)
        icon.mouseovertext = iconData.tooltip
        icon:setVisible(true)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 更新
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_RecipeInfoPanel:onRecipeChanged()
    local recipe = self.logic:getRecipe()
    self:updateRequireIcons(recipe)
end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_RecipeInfoPanel:prerender()
    -- 绘制背景
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        0,
        self.width,
        self.height,
        self.HandCraftPanel.contentBgTextures2,
        1.0, 0.1, 0.1, 0.1
    )

    self:drawRect(self.iconAreaWidth, self.padding * 2, 1, self.height - self.padding * 4, 0.3, 0.5, 0.5, 0.5)
end

function PJCK_RecipeInfoPanel:render()
    local recipe = self.logic:getRecipe()
    if recipe then
        self:RenderRecipeIcon(recipe)
        self:RenderRecipeName(recipe)
        self:RenderRecipeTooltip(recipe)
    end
end

-- 绘制图标
function PJCK_RecipeInfoPanel:RenderRecipeIcon(recipe)
    local iconX = (self.iconAreaWidth - self.iconSize) / 2
    local iconY = (self.height - self.iconSize) / 2

    self:drawTextureScaledAspect(recipe:getIconTexture(), iconX, iconY, self.iconSize, self.iconSize, 1.0, 1.0, 1.0, 1.0)
end

-- 绘制配方名称
function PJCK_RecipeInfoPanel:RenderRecipeName(recipe)
    local nameX = self.iconAreaWidth + self.padding * 2
    local statusIconArea = (FONT_HGT_SMALL * 0.6) + self.padding * 2
    local maxWidth = self.width - nameX - statusIconArea
    local displayName = PJCK_UIHelper.truncateText(recipe:getTranslationName(), maxWidth, UIFont.Medium, "...")

    self:drawText(displayName, nameX, self.padding, 1.0, 1.0, 1.0, 1.0, UIFont.Medium)
end

-- 绘制配方提示
function PJCK_RecipeInfoPanel:RenderRecipeTooltip(recipe)
    if recipe:getTooltip() then
        local nameX = self.iconAreaWidth + self.padding * 2
        local statusIconArea = (FONT_HGT_SMALL * 0.6) + self.padding * 2
        local maxWidth = self.width - nameX - statusIconArea
        local recipetext = getText(recipe:getTooltip())
        local tooltipY = self.padding + FONT_HGT_MEDIUM
        local displayTooltip = PJCK_UIHelper.truncateText(recipetext, maxWidth, UIFont.Small, "...")
        self:drawText(displayTooltip, nameX, tooltipY, 0.8, 0.8, 0.8, 1.0, UIFont.Small)
    end
end

return PJCK_RecipeInfoPanel