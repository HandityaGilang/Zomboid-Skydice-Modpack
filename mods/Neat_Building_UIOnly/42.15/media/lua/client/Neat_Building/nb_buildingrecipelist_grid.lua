require "ISUI/ISUIElement"

NB_BuildingRecipeList_Grid = ISUIElement:derive("NB_BuildingRecipeList_Grid")

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Grid:initialise()
    ISUIElement.initialise(self)
end

function NB_BuildingRecipeList_Grid:new(x, y, size, recipe, parentPanel)
    local o = ISUIElement:new(x, y, size, size)
    setmetatable(o, self)
    self.__index = self
    
    o:setOnMouseDoubleClick(o, NB_BuildingRecipeList_Grid.onDoubleClick)
    o.recipe = recipe
    o.parentPanel = parentPanel
    o.player = parentPanel.player
    o.logic = parentPanel.BuildingPanel.logic
    o.canBuild = false
    o.iconSize = math.floor((size*0.8) / 16) * 16
    o.padding = math.floor(size * 0.1)

    o.slotTextures = {
        background = getTexture("media/ui/Neat_Building/Button/SquareSLTBackground.png"),
        border = getTexture("media/ui/Neat_Building/Button/SquareSLTBoarder.png"),
    }

    o.favouriteIcon = getTexture("media/ui/Neat_Building/ICON/FavouriteYes.png")
    o.layerIcon = getTexture("media/ui/Neat_Building/ICON/Icon_Layer.png")
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Base Function
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Grid:setRecipe(recipe, canBuild)
    self.recipe = recipe
    self.canBuild = canBuild
end

function NB_BuildingRecipeList_Grid:onMouseDown()
    if not self.recipe then return true end
    getSoundManager():playUISound("UIActivateButton")
    self.logic:setRecipe(self.recipe)
    return true
end

function NB_BuildingRecipeList_Grid:onDoubleClick()
    if not self.recipe then return end
    
    local buildingPanel = self.parentPanel.BuildingPanel
    if not buildingPanel then return end
    
    if buildingPanel.logic:getRecipe() ~= self.recipe then
        buildingPanel.logic:setRecipe(self.recipe)
    end

    buildingPanel:startBuild()
end


-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Grid:prerender()
    local bgAlpha = self.canBuild and 1.0 or 0.5
    local color = self:isMouseOver() and 0.5 or 0.3
    self:drawTextureScaled(self.slotTextures.background, 0, 0, self.width, self.height, bgAlpha * 0.4, color, color, color)

    local r, g, b = 0.2, 0.2, 0.2
    if self.canBuild then
        r, g, b = 0.4, 0.4, 0.4
    end
    if self.logic:getRecipe() == self.recipe then
        r, g, b = 0.8, 0.5, 0.2
    end
    
    self:drawTextureScaled(self.slotTextures.border, 0, 0, self.width, self.height, 0.8, r, g, b)
end

function NB_BuildingRecipeList_Grid:render()
    if not self.recipe then return end
    
    -- Draw Recipe Icon
    local recipeIcon = self.recipe:getIconTexture()
    if recipeIcon then
        local iconAlpha = self.canBuild and 1.0 or 0.5
        local iconX = (self.width - self.iconSize) / 2
        local iconY = (self.height - self.iconSize) / 2
        
        self:drawTextureScaledAspect(recipeIcon, iconX, iconY, self.iconSize, self.iconSize, iconAlpha, 1, 1, 1)
    end

    -- Draw layer icon for multi-level recipes
    if BuildingRecipeGroups.hasMultipleLevels(self.recipe:getName()) then
        local layerIconSize = math.floor(self.width / 4)
        local layerIconX = self.padding
        local layerIconY = self.padding
        self:drawTextureScaledAspect(self.layerIcon, layerIconX, layerIconY, layerIconSize, layerIconSize, 1, 0.8, 0.8, 0.8)
    end

    -- Draw favourite icon
    local favString = BuildLogic.getFavouriteModDataString(self.recipe)
    if self.player:getModData()[favString] then
        local favIconSize = math.floor(self.width / 4)
        local favIconX = self.padding
        local favIconY = self.width - favIconSize - self.padding
        self:drawTextureScaledAspect(self.favouriteIcon, favIconX, favIconY, favIconSize, favIconSize, 1, 0.8, 0.2, 0.2)
    end
end

return NB_BuildingRecipeList_Grid