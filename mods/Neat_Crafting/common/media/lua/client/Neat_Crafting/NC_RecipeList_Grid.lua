require "ISUI/ISUIElement"

NC_RecipeList_Grid = ISUIElement:derive("NC_RecipeList_Grid")

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeList_Grid:initialise()
    ISUIElement.initialise(self)
end

function NC_RecipeList_Grid:new(x, y, size, recipe, parentPanel)
    local o = ISUIElement:new(x, y, size, size)
    setmetatable(o, self)
    self.__index = self
    
    o.recipe = recipe
    o.parentPanel = parentPanel
    o.player = parentPanel.player
    o.logic = parentPanel.HandCraftPanel.logic
    o.canMakeRecipe = true
    o.entryType = "recipe"
    o.node = nil
    o.iconSize = math.floor((size*0.8) / 16) * 16

    o.slotTextures = {
        background = getTexture("media/ui/Neat_Crafting/Button/SquareSLTBackground.png"),
        border = getTexture("media/ui/Neat_Crafting/Button/SquareSLTBoarder.png"),
    }
    o.groupOpenTexture = getTexture("media/ui/Icon_RecipeGroup_Open_48x48.png")
    o.groupPartialTexture = getTexture("media/ui/Icon_RecipeGroup_Partial_48x48.png")
    o.groupClosedTexture = getTexture("media/ui/Icon_RecipeGroup_Closed_48x48.png")
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Base Function
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeList_Grid:setEntry(entry, canMake)
    if entry and type(entry) == "table" and entry.entryType then
        local entryCanMake = entry.canMake
        self.entryType = entry.entryType
        self.node = entry.node
        self.canMakeRecipe = entryCanMake ~= false
        if entry.entryType == "group" then
            self.recipe = nil
            return
        end
        entry = entry.recipe
        if type(canMake) ~= "boolean" then
            canMake = entryCanMake
        end
    end

    self.entryType = "recipe"
    self.node = nil
    self.recipe = entry
    self.canMakeRecipe = canMake
end

function NC_RecipeList_Grid:setRecipe(recipe, canMake)
    self:setEntry({ entryType = "recipe", recipe = recipe, canMake = canMake })
end

function NC_RecipeList_Grid:onMouseDown()
    getSoundManager():playUISound("UIActivateButton")

    if self.entryType == "group" then
        self.parentPanel:toggleGroupNode(self.node)
        return true
    end

    if not self.recipe then return true end
    local handCraftPanel = self.parentPanel.HandCraftPanel
    handCraftPanel.logic:setRecipe(self.recipe)
    return true
end
-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeList_Grid:prerender()
    local color = self:isMouseOver() and 0.5 or 0.3
    self:drawTextureScaled(self.slotTextures.background, 0, 0, self.width, self.height, 0.4, color, color, color)

    local r, g, b = 0.2, 0.2, 0.2
    if self.canMakeRecipe then
        r, g, b = 0.4, 0.4, 0.4
    end
    if self.entryType == "recipe" and self.logic:getRecipe() == self.recipe then
        r, g, b = 0.8, 0.5, 0.2
    end
    
    self:drawTextureScaled(self.slotTextures.border, 0, 0, self.width, self.height, 0.8, r, g, b)
end

function NC_RecipeList_Grid:render()
    if self.entryType == "group" and self.node then
        local groupIcon = self.node:getIconTexture()
        if groupIcon then
            local iconAlpha = self.canMakeRecipe and 1.0 or 0.6
            local iconX = (self.width - self.iconSize) / 2
            local iconY = (self.height - self.iconSize) / 2
            self:drawTextureScaledAspect(groupIcon, iconX, iconY, self.iconSize, self.iconSize, iconAlpha, 1, 1, 1)
        end

        local groupStateTexture = self.groupClosedTexture
        if self.node:getExpandedState() == CraftRecipeListNodeExpandedState.OPEN then
            groupStateTexture = self.groupOpenTexture
        elseif self.node:getExpandedState() == CraftRecipeListNodeExpandedState.PARTIAL then
            groupStateTexture = self.groupPartialTexture
        end

        if groupStateTexture then
            local arrowSize = math.floor(self.width * 0.35)
            local arrowX = self.padding or 4
            local arrowY = self.height - arrowSize - 4
            self:drawTextureScaledAspect(groupStateTexture, arrowX, arrowY, arrowSize, arrowSize, 1, 1, 1, 1)
        end
        return
    end

    if self.recipe then
        local recipeIcon = self.recipe:getIconTexture()
        if recipeIcon then
            local iconAlpha = self.canMakeRecipe and 1.0 or 0.5
            local iconX = (self.width - self.iconSize) / 2
            local iconY = (self.height - self.iconSize) / 2
            
            self:drawTextureScaledAspect(recipeIcon, iconX, iconY, self.iconSize, self.iconSize, iconAlpha, 1, 1, 1)
        end
    end
end

return NC_RecipeList_Grid