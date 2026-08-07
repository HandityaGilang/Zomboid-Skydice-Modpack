require "ISUI/ISUIElement"

PJCK_RecipeList_Box = ISUIElement:derive("PJCK_RecipeList_Box")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

--[[ local function getFieldValue(object, fieldName)
    if not object then return nil end
    
    for i = 0, getNumClassFields(object) - 1 do
        local field = getClassField(object, i)
        local currentFieldName = string.match(tostring(field), "([^%.]+)$")
        
        if currentFieldName == fieldName then
            return getClassFieldVal(object, field)
        end
    end
    
    return nil
end]]

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Box:initialise()
    ISUIElement.initialise(self)
    
end

function PJCK_RecipeList_Box:new(x, y, width, recipe, parentPanel)
    local Height = FONT_HGT_SMALL * 3
    local o = ISUIElement:new(x, y, width, Height)
    setmetatable(o, self)
    self.__index = self
    
    o.recipe = recipe
    o.parentPanel = parentPanel
    o.player = parentPanel.player
    o.logic = parentPanel.HandCraftPanel.logic
    o.canMakeRecipe = true
    
    -- 样式设置
    o.iconSize = FONT_HGT_SMALL * 2
    o.padding = FONT_HGT_SMALL * 0.2
    o.iconAreaSize = Height
    
    -- 标签相关变量
    o.nameLabel = nil
    o.skillTexts = {}
    -- o.xpTexts = {}
    o.maxTextWidth = 0
    
    -- 加载贴图
    o.BackgroundTextures = {
        left = getTexture("media/ui/Project_Cook/HandCraft/InputBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/HandCraft/InputBG_M.png"),
        right = getTexture("media/ui/Project_Cook/HandCraft/InputBG_R.png")
    }

    o.BoarderTextures = {
        left = getTexture("media/ui/Project_Cook/HandCraft/InputBoarder_L.png"),
        middle = getTexture("media/ui/Project_Cook/HandCraft/InputBoarder_M.png"),
        right = getTexture("media/ui/Project_Cook/HandCraft/InputBoarder_R.png")
    }
    
    -- 状态图标
    o.skillIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Book_16.png")
    o.lightIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Light_16.png")
    o.surfaceIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Surface_16.png")
    o.walkIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Walking_16.png")
    
    return o
end

-- ---------------------------------------------------------- --
-- 创建子元素
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Box:createChildren()
    local statusIconSize = FONT_HGT_SMALL * 0.6
    local rightMargin = self.padding
    local textX = self.iconAreaSize + self.padding*2
    local textY = self.padding
    self.maxTextWidth = self.width - textX - (statusIconSize + rightMargin + self.padding)
    local defaultText = ""
    
    self.nameLabel = ISLabel:new(textX, textY, FONT_HGT_SMALL, defaultText, 1.0, 1.0, 1.0, 1.0, UIFont.Small, true)
    self.nameLabel:initialise()
    self:addChild(self.nameLabel)
end


-- ---------------------------------------------------------- --
-- 设置可制作状态
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Box:updateLabelsAlpha()
    local alpha = self.canMakeRecipe and 1.0 or 0.5

    if self.nameLabel then
        self.nameLabel.a = alpha
    end
end

-- ---------------------------------------------------------- --
-- 设置新的配方
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Box:setRecipe(recipe, canMake)
    self.recipe = recipe
    self.canMakeRecipe = canMake
    self:updateLabelsAlpha()
    
    -- 计算文本宽度
    local statusIconSize = FONT_HGT_SMALL * 0.6
    local rightMargin = self.padding
    local textX = self.iconAreaSize + self.padding
    self.maxTextWidth = self.width - textX - (statusIconSize + rightMargin + self.padding)
    
    -- 设置配方名称
    local recipeName = ""
    if self.recipe then
        recipeName = self.recipe:getTranslationName()
        recipeName = PJCK_UIHelper.truncateText(recipeName, self.maxTextWidth, UIFont.Small, "...")
    end
    self.nameLabel:setName(recipeName)
    
    -- 更新技能文本内容
    self:updateSkillTexts()
    -- sself:updateXPTexts()
    
    -- 更新透明度
    self:updateLabelsAlpha()
end

-- ---------------------------------------------------------- --
-- 更新技能文本内容
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Box:updateSkillTexts()
    -- 清除现有技能文本
    self.skillTexts = {}
    
    -- 如果没有配方或没有技能需求
    if not self.recipe or self.recipe:getRequiredSkillCount() == 0 then
        return
    end
    
    -- 如果有技能需求，生成技能需求文本
    for i = 0, self.recipe:getRequiredSkillCount() - 1 do
        local requiredSkill = self.recipe:getRequiredSkill(i)
        local skillText = "- ".." LV"..tostring(requiredSkill:getLevel()) .." ".. tostring(requiredSkill:getPerk():getName())
        local truncatedSkillText = PJCK_UIHelper.truncateText(skillText, self.maxTextWidth, UIFont.Small, "...")
        
        -- 检查玩家是否满足这个技能要求
        local isMet = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player)
        
        table.insert(self.skillTexts, {
            text = truncatedSkillText,
            isMet = isMet
        })
    end
end

function PJCK_RecipeList_Box:updateXPTexts()
    self.xpTexts = {}
    
    if not self.recipe or self.recipe:getXPAwardCount() == 0 then
        return
    end
    
    for i = 0, self.recipe:getXPAwardCount() - 1 do
        local xpAward = self.recipe:getXPAward(i)
        if xpAward then
            local amount = getFieldValue(xpAward, "amount") or 0
            local perk = getFieldValue(xpAward, "perk")
            local skillName = perk and perk:getName() or "Unknown"
            
            local xpText = "+ " .. tostring(amount) .. " XP " .. tostring(skillName)
            local truncatedXPText = PJCK_UIHelper.truncateText(xpText, self.maxTextWidth, UIFont.Small, "...")
            
            table.insert(self.xpTexts, {
                text = truncatedXPText,
                amount = amount,
                skill = skillName
            })
        end
    end
end

-- ---------------------------------------------------------- --
-- 玩家技能检查
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Box:canPlayerMake()
    if not self.recipe or not self.player then return false end
    
    -- 检查技能要求
    if self.recipe:getRequiredSkillCount() > 0 then
        for i = 0, self.recipe:getRequiredSkillCount() - 1 do
            local requiredSkill = self.recipe:getRequiredSkill(i)
            if not CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player) then
                return false
            end
        end
    end
    
    -- 检查是否需要学习
    if self.recipe:needToBeLearn() then
        if not self.player:isRecipeKnown(self.recipe, true) then
            return false
        end
    end
    
    return true
end

-- ---------------------------------------------------------- --
-- 更新
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Box:update()
    ISUIElement.update(self)
end

-- ---------------------------------------------------------- --
-- 鼠标交互
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Box:onMouseMove()
    return true
end

function PJCK_RecipeList_Box:onMouseMoveOutside()
    return true
end

function PJCK_RecipeList_Box:onMouseDown()
    if not self.recipe then return true end
    
    local handCraftPanel = self.parentPanel.HandCraftPanel
    handCraftPanel.logic:setRecipe(self.recipe)
    return true
end

function PJCK_RecipeList_Box:onMouseUp()
    return true
end

-- ---------------------------------------------------------- --
-- 渲染函数
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Box:prerender()
    local bgAlpha = self.canMakeRecipe and 1.0 or 0.5
    local r,g,b = 0.15, 0.15, 0.15
    if self:isMouseOver() then
        r,g,b = 0.2, 0.2, 0.2
    end
    PJCK_UIHelper.drawThreeSlice(
        self,
        0, 0, self.width, self.height,
        self.BackgroundTextures.left,
        self.BackgroundTextures.middle,
        self.BackgroundTextures.right,
        bgAlpha, r, g, b
    )

    local handCraftPanel = self.parentPanel and self.parentPanel.HandCraftPanel
    if handCraftPanel.logic:getRecipe() == self.recipe then
        r,g,b = 0.8, 0.5, 0.2
        bgAlpha = 1.0
    else
        r,g,b = 0.2, 0.2, 0.2
    end
        PJCK_UIHelper.drawThreeSlice(
            self,
            0, 0, self.width, self.height,
            self.BoarderTextures.left,
            self.BoarderTextures.middle,
            self.BoarderTextures.right,
            bgAlpha, r, g, b
        )
end

function PJCK_RecipeList_Box:render()

    local iconAreaX = 0
    local iconAreaY = 0
    local iconAreaSize = self.iconAreaSize
    
------ 绘制配方图标   ----------------------------------------------------------------------------------
    if self.recipe then
        local recipeIcon = self.recipe:getIconTexture()
        if recipeIcon then
            local Alpha = self.canMakeRecipe and 1.0 or 0.5     

            local IconX = iconAreaX + (iconAreaSize - self.iconSize) / 2
            local IconY = iconAreaY + (iconAreaSize - self.iconSize) / 2
            
            self:drawTextureScaledAspect(recipeIcon, IconX, IconY, self.iconSize, self.iconSize, Alpha, 1, 1, 1)
        end
        
---------- 绘制技能文本  --------------------------------------------------------------------------------
        if #self.skillTexts > 0 then
            local textX = self.iconAreaSize + self.padding*2
            local textY = self.padding + FONT_HGT_SMALL
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            local zoomScale = 0.8
            
            for i = 1, #self.skillTexts do
                local skillData = self.skillTexts[i]
                local r, g, b = skillData.isMet and 0.2 or 1.0, skillData.isMet and 0.8 or 0.2, 0.2
                
                self:drawTextZoomed(skillData.text, textX, textY, zoomScale, r, g, b, alpha, UIFont.Small)
                textY = textY + FONT_HGT_SMALL * zoomScale
            end
        end

        --[[ 绘制经验值奖励
        if #self.xpTexts > 0 then
            local textX = self.iconAreaSize + self.padding*2
            local textY = self.padding + FONT_HGT_SMALL
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            local zoomScale = 0.8

            if #self.skillTexts > 0 then
                textY = textY + (#self.skillTexts * FONT_HGT_SMALL * zoomScale)
            end
            
            for i = 1, #self.xpTexts do
                local xpData = self.xpTexts[i]
                local r, g, b = 0.2, 1.0, 0.2
                
                self:drawTextZoomed(xpData.text, textX, textY, zoomScale, r, g, b, alpha, UIFont.Small)
                textY = textY + FONT_HGT_SMALL * zoomScale
            end
        end
        ]]
        
---------- 绘制状态图标  --------------------------------------------------------------------------------
        local statusIconSize = FONT_HGT_SMALL*0.6
        local rightMargin = self.padding
        local iconsToShow = {}

        -- 光线需求图标
        if not self.recipe:canBeDoneInDark() then
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            table.insert(iconsToShow, {texture = self.lightIconTexture, alpha = alpha})
        end

        -- 需要配方图标
        if self.recipe:needToBeLearn() then
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            table.insert(iconsToShow, {texture = self.skillIconTexture, alpha = alpha})
        end

        -- 表面需求图标
        if not self.recipe:isInHandCraftCraft() then
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            table.insert(iconsToShow, {texture = self.surfaceIconTexture, alpha = alpha})
        end

        -- 行走制作图标
        if self.recipe:isCanWalk() and not self.player:hasAwkwardHands() then
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            table.insert(iconsToShow, {texture = self.walkIconTexture, alpha = alpha})
        end

        local iconX = self.width - rightMargin - statusIconSize
        local availableHeight = self.height - self.padding * 2
        local totalIconsHeight = 3 * statusIconSize
        local iconSpacing = (availableHeight - totalIconsHeight) / 2

        for i = 1, #iconsToShow do
            local icon = iconsToShow[i]
            local iconY = self.padding + (i - 1) * (statusIconSize + iconSpacing)
            self:drawTextureScaled(icon.texture, iconX, iconY, statusIconSize, statusIconSize, icon.alpha, 1, 1, 1)
        end
    end
end

return PJCK_RecipeList_Box