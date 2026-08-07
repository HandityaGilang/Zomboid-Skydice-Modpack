require "ISUI/ISUIElement"

NB_BuildingRecipeList_Box = ISUIElement:derive("NB_BuildingRecipeList_Box")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Box:initialise()
    ISUIElement.initialise(self)
end

function NB_BuildingRecipeList_Box:new(x, y, width, height, recipe, parentPanel)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o:setOnMouseDoubleClick(o, NB_BuildingRecipeList_Box.onDoubleClick)
    o.recipe = recipe
    o.parentPanel = parentPanel
    o.player = parentPanel.player
    o.logic = parentPanel.BuildingPanel.logic
    o.canBuild = false

    o.iconSize = math.floor((height*0.8) / 16) * 16
    o.padding = parentPanel.padding / 2
    o.iconAreaSize = height

    o.skillTexts = {}
    o.statusIconSize = parentPanel.statusIconSize

    o.skillIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Book_16.png")
    o.lightIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Light_16.png")
    o.favouriteIcon = getTexture("media/ui/Neat_Building/ICON/FavouriteYes.png")
    o.layerIcon = getTexture("media/ui/Neat_Building/ICON/Icon_Layer.png")

    return o
end
-- ----------------------------------------------------------------------------------------------------- --
-- Update Building Info
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Box:setRecipe(recipe, canBuild)
    self.recipe = recipe
    self.canBuild = canBuild
    
    self:updateSkillTexts()
end


function NB_BuildingRecipeList_Box:updateSkillTexts()
    self.skillTexts = {}

    if not self.recipe or self.recipe:getRequiredSkillCount() == 0 then return end

    local maxTextWidth = self.width - self.iconAreaSize - self.padding * 2 - (self.statusIconSize + self.padding)

    for i = 0, self.recipe:getRequiredSkillCount() - 1 do
        local requiredSkill = self.recipe:getRequiredSkill(i)
        local skillText = "LV"..tostring(requiredSkill:getLevel()) .." ".. tostring(requiredSkill:getPerk():getName())
        local truncatedSkillText = NeatTool.truncateText(skillText, maxTextWidth, UIFont.Small, "...")

        local isMet = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player)
        
        table.insert(self.skillTexts, {
            text = truncatedSkillText,
            isMet = isMet
        })
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse function
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Box:onDoubleClick()
    if not self.recipe then return end

    local buildingPanel = self.parentPanel.BuildingPanel
    if not buildingPanel then return end
    
    if buildingPanel.logic:getRecipe() ~= self.recipe then
        buildingPanel.logic:setRecipe(self.recipe)
    end

    buildingPanel:startBuild()
end

function NB_BuildingRecipeList_Box:onMouseDown()
    if not self.recipe then return true end
    getSoundManager():playUISound("UIActivateButton")
    self.logic:setRecipe(self.recipe)
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Box:prerender()
    local bgAlpha = self.canBuild and 1.0 or 0.5
    local r,g,b = 0.15, 0.15, 0.15
    if self:isMouseOver() then
        r,g,b = 0.2, 0.2, 0.2
    end
    
    local sloticon = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Button/SlotBG_IconSide.png")
    if sloticon then
        sloticon:render(self:getAbsoluteX(), self:getAbsoluteY(), self.height, self.height, r, g, b, bgAlpha)
    end
    local slotleft = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Button/SlotBG_LEFT.png")
    if slotleft then
        slotleft:render(self:getAbsoluteX()+self.height, self:getAbsoluteY(), self.width - self.height, self.height, r, g, b, bgAlpha)
    end

    if self.logic and self.logic:getRecipe() == self.recipe then
        r,g,b = 0.8, 0.5, 0.2
        bgAlpha = 1.0
    else
        r,g,b = 0.2, 0.2, 0.2
    end

    local slotboarder = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Button/SlotBoarder.png")
    if slotboarder then
        slotboarder:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, r, g, b, bgAlpha)
    end

    self:renderRecipeInfo()
end

function NB_BuildingRecipeList_Box:renderRecipeInfo()
    if not self.recipe then return end

    local iconAreaX = 0
    local iconAreaY = 0
    local iconAreaSize = self.iconAreaSize
    
------ Draw RecipeIcon   ----------------------------------------------------------------------------------
    local recipeIcon = self.recipe:getIconTexture()
    if recipeIcon then
        local Alpha = self.canBuild and 1.0 or 0.5
        local IconX = iconAreaX + (iconAreaSize - self.iconSize) / 2
        local IconY = iconAreaY + (iconAreaSize - self.iconSize) / 2
        
        self:drawTextureScaledAspect(recipeIcon, IconX, IconY, self.iconSize, self.iconSize, Alpha, 1, 1, 1)
    end

    -- Draw layer icon for multi-level recipes
    if self.recipe and BuildingRecipeGroups.hasMultipleLevels(self.recipe:getName()) then
        local layerIconSize = math.floor(self.height / 4)
        local layerIconX = iconAreaX + self.padding
        local layerIconY = iconAreaY + self.padding

        self:drawTextureScaledAspect(self.layerIcon, layerIconX, layerIconY, layerIconSize, layerIconSize, 1, 0.8, 0.8, 0.8)
    end

    -- Draw favouriteIcon
    local favString = BuildLogic.getFavouriteModDataString(self.recipe)
    if self.player:getModData()[favString] then
        local favIconSize = math.floor(self.height / 5)
        local favIconX = iconAreaX + self.padding
        local favIconY = iconAreaY + iconAreaSize - favIconSize - self.padding
        
        self:drawTextureScaledAspect(self.favouriteIcon, favIconX, favIconY, favIconSize, favIconSize, 1, 0.8, 0.2, 0.2)
    end

------ Draw Text   ----------------------------------------------------------------------------------
    local textX = self.iconAreaSize + self.padding
    local textY = self.padding
    local maxTextWidth = self.width - textX - (self.statusIconSize + self.padding * 2)
    
    local recipeName = self.recipe:getTranslationName()
    local displayName = NeatTool.truncateText(recipeName, maxTextWidth, UIFont.Small, "...")
    local nameAlpha = self.canBuild and 1.0 or 0.5
    
    self:drawText(displayName, textX, textY, 1, 1, 1, nameAlpha, UIFont.Small)
    
    -- Skill Need
    if #self.skillTexts > 0 then
        local skillTextY = textY + FONT_HGT_SMALL
        local alpha = self.canBuild and 1.0 or 0.5
        local zoomScale = 0.8
        
        for i = 1, math.min(#self.skillTexts, 2) do
            local skillData = self.skillTexts[i]
            local r, g, b = skillData.isMet and 0.2 or 1.0, skillData.isMet and 0.8 or 0.2, 0.2
            
            self:drawTextZoomed(skillData.text, textX, skillTextY, zoomScale, r, g, b, alpha, UIFont.Small)
            skillTextY = skillTextY + FONT_HGT_SMALL * zoomScale
        end
    end
    
------ Draw Require Icon   ----------------------------------------------------------------------------------
    local rightMargin = self.padding
    local iconsToShow = {}

    if not self.recipe:canBeDoneInDark() then
        local alpha = self.canBuild and 1.0 or 0.5
        table.insert(iconsToShow, {texture = self.lightIconTexture, alpha = alpha})
    end

    if self.recipe:needToBeLearn() then
        local alpha = self.canBuild and 1.0 or 0.5
        table.insert(iconsToShow, {texture = self.skillIconTexture, alpha = alpha})
    end

    local iconX = self.width - rightMargin - self.statusIconSize
    local availableHeight = self.height - self.padding * 2
    local totalIconsHeight = math.min(#iconsToShow, 3) * self.statusIconSize
    local iconSpacing = math.max(0, (availableHeight - totalIconsHeight) / math.max(1, math.min(#iconsToShow, 3) - 1))

    for i = 1, math.min(#iconsToShow, 3) do
        local icon = iconsToShow[i]
        local iconY = self.padding + (i - 1) * (self.statusIconSize + iconSpacing)
        self:drawTextureScaled(icon.texture, iconX, iconY, self.statusIconSize, self.statusIconSize, icon.alpha, 1, 1, 1)
    end
end

return NB_BuildingRecipeList_Box