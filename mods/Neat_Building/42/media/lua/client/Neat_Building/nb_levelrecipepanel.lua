require "ISUI/ISPanel"

NB_LevelRecipePanel = ISPanel:derive("NB_LevelRecipePanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)


-- ----------------------------------------------------------------------------------------------------- --
-- Recipe-known strict check (integrated from XP_NB RecipeKnownIcon patch)
-- ----------------------------------------------------------------------------------------------------- --

local function NB_safeCall(fn)
    -- Protected call helper to avoid UI crashes from signature differences.
    local ok, res = pcall(fn)
    if ok then return res end
    return nil
end

local function NB_isRecipeActuallyKnown(player, recipe)
    -- Prefer strict API if available, fall back to legacy checks.
    if not player or not recipe then return false end

    if player.isRecipeActuallyKnown then
        local v = NB_safeCall(function() return player:isRecipeActuallyKnown(recipe) end)
        if v ~= nil then return v end
    end

    if player.isRecipeKnown then
        -- Some builds expose a strict flag signature.
        local vStrict = NB_safeCall(function() return player:isRecipeKnown(recipe, true) end)
        if vStrict ~= nil then return vStrict end

        -- Legacy signature.
        local vLegacy = NB_safeCall(function() return player:isRecipeKnown(recipe) end)
        if vLegacy ~= nil then return vLegacy end
    end

    return false
end
-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_LevelRecipePanel:initialise()
    ISPanel.initialise(self)
end

function NB_LevelRecipePanel:new(x, y, width, height, BuildingInfoPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.BuildingInfoPanel = BuildingInfoPanel
    o.logic = BuildingInfoPanel.logic
    o.player = BuildingInfoPanel.player
    o.padding = BuildingInfoPanel.padding
    
    o.recipeIconSize = math.floor(FONT_HGT_SMALL * 4/16)*16
    o.smallIconSize = math.floor(o.recipeIconSize * 0.7 /8) *8

    o.iconAreaHeight = o.recipeIconSize + o.padding * 2
    o.nameAreaHeight = FONT_HGT_MEDIUM + o.padding

    o.currentRecipe = nil
    o.recipeGroup = nil
    o.groupRecipes = {}
    o.currentRecipeIndex = 1

    o.BuildingRecipeGroups = BuildingRecipeGroups

    o.requireIcons = {}
    o.requireIconSize = FONT_HGT_SMALL
    o.skillIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Book.png")
    o.lightIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Light.png")

    o.favoriteIconSize = math.floor(o.recipeIconSize * 0.3)
    o.isFavorite = false

    o.DotTexture = {
        on = getTexture("media/ui/Neat_Building/ICON/Icon_DotUnselect.png"),
        off = getTexture("media/ui/Neat_Building/ICON/Icon_DotSelect.png")
    }
    
    return o
end

function NB_LevelRecipePanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.minimumWidth)
    local height = math.max(_preferredHeight or 0, self.minimumHeight)
    
    self:setWidth(width)
    self:setHeight(height)
    
    self:updateIconLayout()
    self:relayoutRequireIcons()
end

function NB_LevelRecipePanel:updateIconLayout()
    local centerX = self.width / 2
    local iconAreaCenterY = self.iconAreaHeight / 2

    if self.currentIcon then
        self.currentIcon:setX(centerX - self.recipeIconSize / 2)
        self.currentIcon:setY(iconAreaCenterY - self.recipeIconSize / 2)
    end

    if self.prevIcon then
        local prevX = centerX - self.recipeIconSize / 2 - self.padding - self.smallIconSize
        local prevY = iconAreaCenterY - self.smallIconSize / 2
        self.prevIcon:setX(prevX)
        self.prevIcon:setY(prevY)
    end

    if self.nextIcon then
        local nextX = centerX + self.recipeIconSize / 2 + self.padding
        local nextY = iconAreaCenterY - self.smallIconSize / 2
        self.nextIcon:setX(nextX)
        self.nextIcon:setY(nextY)
    end

    if self.favouriteButton then
        local favoriteX = (centerX - self.recipeIconSize / 2)
        local favoriteY = (iconAreaCenterY + self.recipeIconSize / 2 - self.favoriteIconSize)
        self.favouriteButton:setX(favoriteX)
        self.favouriteButton:setY(favoriteY)
    end
end

function NB_LevelRecipePanel:relayoutRequireIcons()
    local iconSpacing = self.padding / 2
    local rightMargin = self.padding
    
    for i = 1, 4 do
        if self.requireIcons[i] then
            local iconX = self.width - rightMargin - self.requireIconSize
            local iconY = self.padding + (i - 1) * (self.requireIconSize + iconSpacing)
            
            self.requireIcons[i]:setX(iconX)
            self.requireIcons[i]:setY(iconY)
            self.requireIcons[i]:setWidth(self.requireIconSize)
            self.requireIcons[i]:setHeight(self.requireIconSize)
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NB_LevelRecipePanel:createChildren()
    self.currentIcon = ISImage:new(0, 0, self.recipeIconSize, self.recipeIconSize, nil)
    self.currentIcon:initialise()
    self.currentIcon.autoScale = true
    self:addChild(self.currentIcon)
    
    self.prevIcon = ISButton:new(0, 0, self.smallIconSize, self.smallIconSize, "", self, self.switchToPreviousRecipe)
    self.prevIcon:initialise()
    self.prevIcon.displayBackground = false
    self.prevIcon:setVisible(false)
    self:addChild(self.prevIcon)
    
    self.nextIcon = ISButton:new(0, 0, self.smallIconSize, self.smallIconSize, "", self, self.switchToNextRecipe)
    self.nextIcon:initialise()
    self.nextIcon.displayBackground = false
    self.nextIcon:setVisible(false)
    self:addChild(self.nextIcon)

    self.favouriteButton = ISButton:new(0, 0, self.favoriteIconSize, self.favoriteIconSize, "", self, self.onFavoriteClick)
    self.favouriteButton:initialise()
    self.favouriteButton.displayBackground = false
    self:addChild(self.favouriteButton)

    for i = 1, 2 do
        local icon = ISImage:new(0, 0, 10, 10, self.lightIconTexture)
        icon.autoScale = true
        icon:initialise()
        icon:setVisible(false)
        self:addChild(icon)
        self.requireIcons[i] = icon
    end
end

function NB_LevelRecipePanel:updateRequireIcons()
    for i = 1, 2 do
        self.requireIcons[i]:setVisible(false)
    end
    
    if not self.logic:getRecipe() then return end
    local recipe = self.logic:getRecipe()

    local iconsToShow = {}
    
    -- Light Need
    if not recipe:canBeDoneInDark() then
        local tooDark = self.player:tooDarkToRead()
        table.insert(iconsToShow, {
            texture = self.lightIconTexture,
            color = tooDark and {r=1.0, g=0.2, b=0.2} or {r=1.0, g=1.0, b=1.0},
            tooltip = getText("IGUI_CraftingWindow_RequiresLight")
        })
    end
	
	-- Recipe learning requirement (FIXED).
	if recipe.needToBeLearn and recipe:needToBeLearn() then
		local hasRecipe = NB_isRecipeActuallyKnown(self.player, recipe)

		-- Prefer vanilla tooltip key for "not learned" on newer builds.
		local notLearnedTxt = getText("IGUI_CraftingWindow_RequiresLearning")
		if notLearnedTxt == "IGUI_CraftingWindow_RequiresLearning" then
			notLearnedTxt = getText("IGUI_CraftingWindow_RequiresRecipe")
		end

		table.insert(iconsToShow, {
			texture = self.skillIconTexture,
			color = hasRecipe and {r=1.0, g=1.0, b=1.0} or {r=1.0, g=0.2, b=0.2},
			tooltip = hasRecipe and getText("IGUI_CraftingWindow_RecipeKnown") or notLearnedTxt
		})
	end
	
    for i = 1, math.min(#iconsToShow, 2) do
        local iconData = iconsToShow[i]
        local icon = self.requireIcons[i]
        icon.texture = iconData.texture
        icon:setColor(iconData.color.r, iconData.color.g, iconData.color.b)
        icon:setMouseOverText(iconData.tooltip)
        icon:setVisible(true)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NB_LevelRecipePanel:onRecipeChanged()
    self.currentRecipe = self.logic:getRecipe()
    
    if not self.currentRecipe then
        self.recipeGroup = nil
        self.groupRecipes = {}
        self.currentRecipeIndex = 1
        self:updateDisplay()
        return
    end

    local recipeName = self.currentRecipe:getName()
    
    self.recipeGroup = self.BuildingRecipeGroups.getRecipeGroup(recipeName)
    
    if self.recipeGroup then
        local groupRecipeNames = self.BuildingRecipeGroups.getGroupRecipes(self.recipeGroup)
        self.groupRecipes = {}

        for i, name in ipairs(groupRecipeNames) do
            local recipe = self:findRecipeByName(name)
            if recipe then
                table.insert(self.groupRecipes, recipe)
                if recipe == self.currentRecipe then
                    self.currentRecipeIndex = i
                end
            end
        end
    else
        self.groupRecipes = {}
        self.currentRecipeIndex = 1
    end
    
    self:updateDisplay()
    self:updateRequireIcons()
    self:updateFavouriteButton()
end

function NB_LevelRecipePanel:updateDisplay()
    if self.currentIcon then
        local iconTexture = self.currentRecipe and self.currentRecipe:getIconTexture() or nil
        self.currentIcon.texture = iconTexture
    end

    local prevRecipe = self:getPreviousRecipe()
    if self.prevIcon then
        if prevRecipe then
            local prevTexture = prevRecipe:getIconTexture()
            self.prevIcon.prerender = function(button)
                if prevTexture then
                    local alpha = button:isMouseOver() and 1.0 or 0.7
                    button:drawTextureScaledAspect(prevTexture, 0, 0, button.width, button.height, alpha, 1, 1, 1)
                end
            end
            self.prevIcon:setVisible(true)
        else
            self.prevIcon:setVisible(false)
        end
    end

    local nextRecipe = self:getNextRecipe()
    if self.nextIcon then
        if nextRecipe then
            local nextTexture = nextRecipe:getIconTexture()
            self.nextIcon.prerender = function(button)
                if nextTexture then
                    local alpha = button:isMouseOver() and 1.0 or 0.7
                    button:drawTextureScaledAspect(nextTexture, 0, 0, button.width, button.height, alpha, 1, 1, 1)
                end
            end
            self.nextIcon:setVisible(true)
        else
            self.nextIcon:setVisible(false)
        end
    end
    
    self:updateIconLayout()
end

function NB_LevelRecipePanel:findRecipeByName(recipeName)
    local allRecipes = self.logic:getAllBuildableRecipes()
    if not allRecipes then return nil end
    
    for i = 0, allRecipes:size() - 1 do
        local recipe = allRecipes:get(i)
        if recipe:getName() == recipeName then
            return recipe
        end
    end
    return nil
end

function NB_LevelRecipePanel:onFavoriteClick()
    if not self.currentRecipe then return end
    local favString = BaseCraftingLogic.getFavouriteModDataString(self.logic:getRecipe())
    local currentFav = self.player:getModData()[favString] or false
    self.player:getModData()[favString] = not currentFav

    self:updateFavouriteButton()
	-- Sync player modData to the server in multiplayer (if the API exists)
	if self.player and self.player.transmitModData then
		self.player:transmitModData()
	end

end

function NB_LevelRecipePanel:updateFavouriteButton()
    if not self.favouriteButton then return end
    
    local isFavourite = false
    local recipe = self.logic:getRecipe()
    if recipe then
        local favString = BaseCraftingLogic.getFavouriteModDataString(recipe)
        isFavourite = self.player:getModData()[favString] or false
    end
    
    if isFavourite then
        self.favouriteButton.image = getTexture("media/ui/Neat_Crafting/ICON/FavouriteYes.png")
        self.favouriteButton.textureColor = { r = 0.8,g = 0.2,b = 0.2,a=1}
    else
        self.favouriteButton.image = getTexture("media/ui/Neat_Crafting/ICON/FavouriteNo.png")
        self.favouriteButton.textureColor = { r=1, g=1, b=1, a=1 }
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Switch recipe
-- ----------------------------------------------------------------------------------------------------- --
function NB_LevelRecipePanel:getPreviousRecipe()
    if #self.groupRecipes <= 1 then return nil end
    
    local prevIndex = self.currentRecipeIndex - 1
    if prevIndex < 1 then prevIndex = #self.groupRecipes end
    
    return self.groupRecipes[prevIndex]
end

function NB_LevelRecipePanel:getNextRecipe()
    if #self.groupRecipes <= 1 then return nil end
    
    local nextIndex = self.currentRecipeIndex + 1
    if nextIndex > #self.groupRecipes then nextIndex = 1 end
    
    return self.groupRecipes[nextIndex]
end

function NB_LevelRecipePanel:switchToPreviousRecipe()
    local prevRecipe = self:getPreviousRecipe()
    if prevRecipe then
        self.logic:setRecipe(prevRecipe)
    end
end

function NB_LevelRecipePanel:switchToNextRecipe()
    local nextRecipe = self:getNextRecipe()
    if nextRecipe then
        self.logic:setRecipe(nextRecipe)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_LevelRecipePanel:render()

    if #self.groupRecipes > 1 then
        local indicatorY = self.currentIcon:getBottom() + self.padding
        
        local dotSize = self.padding
        local dotPadding = self.padding / 2
        local totalWidth = (#self.groupRecipes - 1) * dotPadding + #self.groupRecipes * dotSize
        local startX = (self.width - totalWidth) / 2
        
        for i = 1, #self.groupRecipes do
            local isSelected = (i == self.currentRecipeIndex)
            local texture = isSelected and self.DotTexture.off or self.DotTexture.on

            self:drawTextureScaled(texture, startX, indicatorY, dotSize, dotSize, 1.0, 1, 1, 1)
            startX = startX + dotSize + dotPadding
        end
    end

    if self.currentRecipe then
        local recipeName = self.currentRecipe:getTranslationName()
        local maxTextWidth = self.width - self.padding*2
        local displayName = NeatTool.truncateText(recipeName, maxTextWidth, UIFont.Medium, "...")
        local nameWidth = getTextManager():MeasureStringX(UIFont.Medium, displayName)
        local nameX = (self.width - nameWidth) / 2
        local nameY = self.currentIcon:getBottom() + self.padding*2
        
        self:drawText(displayName, nameX, nameY, 0.9, 0.9, 0.9, 1, UIFont.Medium)
    end
end

return NB_LevelRecipePanel