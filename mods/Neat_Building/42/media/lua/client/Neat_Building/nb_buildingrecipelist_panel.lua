require "ISUI/ISPanel"

NB_BuildingRecipeList_Panel = ISPanel:derive("NB_BuildingRecipeList_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function NB_copyRecipeArray(source)
    -- Normalize recipe collections to a dense 1-based Lua array.
    local out = {}
    if not source then return out end

    if type(source) == "table" then
        for i = 1, #source do
            local recipe = source[i]
            if recipe then
                out[#out + 1] = recipe
            end
        end
        return out
    end

    if source.getAllRecipes then
        local okAll, recipes = pcall(function() return source:getAllRecipes() end)
        if okAll and recipes then
            return NB_copyRecipeArray(recipes)
        end
    end

    if source.size and source.get then
        local okSize, size = pcall(function() return source:size() end)
        if okSize and size then
            for i = 0, size - 1 do
                local okGet, recipe = pcall(function() return source:get(i) end)
                if okGet and recipe then
                    out[#out + 1] = recipe
                end
            end
        end
    end

    return out
end

local function NB_findFirstValidRecipe(recipeList)
    -- Pick the first real recipe entry and skip nil / malformed values.
    if not recipeList then return nil end
    for i = 1, #recipeList do
        local recipe = recipeList[i]
        if recipe and recipe.getName then
            return recipe
        end
    end
    return nil
end

local function NB_hasRecipe(recipeList, targetRecipe)
    if not recipeList or not targetRecipe then return false end
    for i = 1, #recipeList do
        if recipeList[i] == targetRecipe then
            return true
        end
    end
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Panel:initialise()
    ISPanel.initialise(self)
end

function NB_BuildingRecipeList_Panel:new(x, y, width, height, BuildingPanel)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.BuildingPanel = BuildingPanel
    o.player = BuildingPanel.player
    o.logic = BuildingPanel.logic
    o.allRecipes = {}

    o.padding = BuildingPanel.padding
    o.itemHeight = FONT_HGT_SMALL * 3 + o.padding
    o.scrollViewSpacing = BuildingPanel.scrollViewSpacing
    o.statusIconSize = math.floor(FONT_HGT_SMALL * 0.6)
    o.scrollBarWidth = BuildingPanel.scrollBarWidth

    local minItemsCount = 6
    local minTextWidth = getTextManager():MeasureStringX(UIFont.Small, "Commercial Full Glass Black Wall")
    o.minimumHeight = o.itemHeight * minItemsCount + (o.padding/2) * (minItemsCount + 1)
    o.minimumWidth = o.padding + o.itemHeight + minTextWidth + o.statusIconSize + o.scrollBarWidth

    o.gridItemSize = math.floor(FONT_HGT_SMALL * 3)
    o.gridColumnCount = 4
    o.gridPadding = o.padding

    o.filteredRecipes = {}
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Panel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.minimumWidth)
    local height = math.max(_preferredHeight or 0, self.minimumHeight)

    local currentStyle = self.logic:getSelectedRecipeStyle() or "list"

    if not self:ensureScrollViewStyle(currentStyle) then return end

    if currentStyle == "list" then
        self.scrollView:setX(self.padding/2)
        self.scrollView:setY(self.scrollViewSpacing)
        self.scrollView:setWidth(width - self.padding/2)
        self.scrollView:setHeight(height - self.scrollViewSpacing * 2)
        self.scrollView:setConfig(self.itemHeight, math.floor(self.padding / 2))

        local itemWidth = width - self.scrollBarWidth - self.padding/2
        if self.scrollView.itemPool then
            for _, item in ipairs(self.scrollView.itemPool) do
                if item and item.setWidth then
                    item:setWidth(itemWidth)
                end
            end
        end
    else
        self.scrollView:setX(self.padding)
        self.scrollView:setY(self.scrollViewSpacing)
        self.scrollView:setWidth(width - self.padding)
        self.scrollView:setHeight(height - self.scrollViewSpacing * 2)
        
        local availableWidth = width - self.scrollBarWidth - self.padding*2
        self:calculateGridLayout(availableWidth)
        self.scrollView:setConfig(self.gridItemSize, self.gridItemSize, self.gridColumnCount)
        self.scrollView:setSpacing(self.gridPadding, self.padding)
    end

    self:setWidth(width)
    self:setHeight(height)
    self:updateRecipeList(self.filteredRecipes)
end

function NB_BuildingRecipeList_Panel:calculateGridLayout(availableWidth)
    local maxColumns = math.max(1, math.floor((availableWidth + self.padding) / (self.gridItemSize + self.padding)))
    local usedWidth = maxColumns * self.gridItemSize + (maxColumns + 1) * self.padding
    local remainingWidth = availableWidth - usedWidth
    
    self.gridColumnCount = maxColumns
    if maxColumns > 1 and remainingWidth > 0 then
        self.gridPadding = self.padding + (remainingWidth / (maxColumns - 1))
    else
        self.gridPadding = self.padding
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Scroll view style safety
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Panel:ensureScrollViewStyle(currentStyle)
    -- Keep the concrete scroll view class in sync with the selected display style.
    -- A grid scroll view expects setConfig(itemWidth, itemHeight, axisCount), while
    -- the list scroll view expects setConfig(itemHeight, spacing). If they get mixed,
    -- Kahlua can throw "__div not defined" when axisCount becomes nil.
    currentStyle = currentStyle or "list"

    if self.scrollView and self.scrollViewStyle == currentStyle then
        return true
    end

    if self.scrollView then
        self:removeChild(self.scrollView)
        self.scrollView = nil
    end
    self.scrollViewStyle = nil

    if currentStyle == "list" then
        self:createListScrollView()
    else
        self:createGridScrollView()
    end

    return self.scrollView ~= nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Panel:createChildren()
    if self.scrollView then
        self:removeChild(self.scrollView)
        self.scrollView = nil
    end
    self.scrollViewStyle = nil

    local currentStyle = self.logic:getSelectedRecipeStyle() or "list"
    
    if currentStyle == "list" then
        self:createListScrollView()
    else
        self:createGridScrollView()
    end

    self:calculateLayout(self.width,self.height)
end

function NB_BuildingRecipeList_Panel:createListScrollView()
    self.scrollViewStyle = "list"
    self.scrollView = NIVirtualScrollView:new(0, 0, 10, 10)
    self.scrollView:initialise()
    self.scrollView:setConfig(self.itemHeight, math.floor(self.padding / 2))
    self:addChild(self.scrollView)

    self.scrollView:setOnCreateItem(function()
        local itemWidth = self.width - self.BuildingPanel.scrollBarWidth - self.padding
        return NB_BuildingRecipeList_Box:new(0, 0, itemWidth, self.itemHeight, nil, self)
    end)
    
    self.scrollView:setOnUpdateItem(function(itemObject, recipe)
        local canBuild = false
        if recipe and self.logic then
            canBuild = self:canBuildRecipe(recipe)
        end
        itemObject:setRecipe(recipe, canBuild)
    end)
end

function NB_BuildingRecipeList_Panel:createGridScrollView()
    self.scrollViewStyle = "grid"
    self.scrollView = NIGridVirtualScrollView:new(0, 0, 10, 10)
    self.scrollView:initialise()
    self.scrollView:setConfig(self.gridItemSize, self.gridItemSize, self.gridColumnCount)
    self.scrollView:setSpacing(self.gridPadding, self.gridPadding)
    self:addChild(self.scrollView)

    self.scrollView:setOnCreateItem(function()
        return NB_BuildingRecipeList_Grid:new(0, 0, self.gridItemSize, nil, self)
    end)
    
    self.scrollView:setOnUpdateItem(function(itemObject, recipe)
        local canBuild = false
        if recipe and self.logic then
            canBuild = self:canBuildRecipe(recipe)
        end
        itemObject:setRecipe(recipe, canBuild)
    end)
end

function NB_BuildingRecipeList_Panel:setLayoutMode(isGrid)
    local newStyle = isGrid and "grid" or "list"
    self.logic:setSelectedRecipeStyle(newStyle)
    
    self:createChildren()
end


function NB_BuildingRecipeList_Panel:canBuildRecipe(recipe)
    if not recipe or not self.logic then return false end
    
    local info = self.logic:getCachedRecipeInfo(recipe)
    if not info then return false end

    local cheat = self.player:isBuildCheat()
    return (info:isValid() and info:isCanPerform()) or cheat
end
-- ----------------------------------------------------------------------------------------------------- --
-- Update RecipeList
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Panel:updateRecipeList(filteredRecipes)
    -- Always work with a dense Lua array so UI code is not sensitive to bridge changes.
    self.filteredRecipes = NB_copyRecipeArray(filteredRecipes)

    local finalRecipes = self.filteredRecipes

    -- when fav ,show all recipe
    if self.BuildingPanel._categoryString ~= "*" then
        finalRecipes = self:applyOnAddToMenuFilter(self.filteredRecipes)
    else
        finalRecipes = NB_copyRecipeArray(finalRecipes)
    end

    local currentRecipe = self.logic and self.logic.getRecipe and self.logic:getRecipe() or nil
    if currentRecipe and currentRecipe.getName then
        local currentGroup = BuildingRecipeGroups.getRecipeGroup(currentRecipe:getName())

        if currentGroup then
            -- Keep the currently selected level visible when another recipe from the same group is present.
            for i = 1, #finalRecipes do
                local recipe = finalRecipes[i]
                if recipe and recipe.getName then
                    local recipeGroup = BuildingRecipeGroups.getRecipeGroup(recipe:getName())
                    if recipeGroup == currentGroup and recipe ~= currentRecipe then
                        finalRecipes[i] = currentRecipe
                        break
                    end
                end
            end
        end
    end

    if self.scrollView then
        self.scrollView:setDataSource(finalRecipes, true)
    end

    local selectedRecipe = currentRecipe
    if not NB_hasRecipe(finalRecipes, selectedRecipe) then
        selectedRecipe = NB_findFirstValidRecipe(finalRecipes)
    end

    -- Avoid passing nil / malformed values into the Java bridge.
    if selectedRecipe and selectedRecipe ~= currentRecipe and self.logic and self.logic.setRecipe then
        local ok, err = pcall(function() self.logic:setRecipe(selectedRecipe) end)
        if not ok then
            print("NB_BuildingRecipeList_Panel.updateRecipeList: failed to set recipe - " .. tostring(err))
        end
    end

    -- print("Updated recipe list: " .. #finalRecipes)
end

function NB_BuildingRecipeList_Panel:applyOnAddToMenuFilter(recipeList)
    local finalRecipes = {}

    for _, recipe in ipairs(recipeList) do
        local failed = false

        if recipe and recipe.getOnAddToMenu and recipe:getOnAddToMenu() then
            local func = recipe:getOnAddToMenu()
            local params = {
                player = self.player,
                recipe = recipe,
                shouldShowAll = false
            }

            -- Guard modded OnAddToMenu callbacks so one bad recipe does not break the whole panel.
            local ok, result = pcall(function()
                if callLuaBool then
                    return callLuaBool(func, params)
                end
                return true
            end)

            failed = not ok or not result
        end

        if recipe and not failed then
            table.insert(finalRecipes, recipe)
        end
    end

    return finalRecipes
end

function NB_BuildingRecipeList_Panel:scrollToRecipe(targetRecipe)
    if not targetRecipe or not self.scrollView then return end

    local dataSource = self.scrollView.dataSource or {}

    local targetIndex = -1
    for i = 1, #dataSource do
        if dataSource[i] == targetRecipe then
            targetIndex = i
            break
        end
    end

    if targetIndex > 0 then
        local currentStyle = self.logic:getSelectedRecipeStyle() or "list"
        local scrollY = 0
        
        if currentStyle == "grid" then
            local columnCount = self.gridColumnCount or 4
            local rowHeight = self.gridItemSize + self.gridPadding

            local targetRow = math.ceil(targetIndex / columnCount)

            scrollY = (targetRow - 1) * rowHeight
        else
            local itemHeight = self.itemHeight
            local spacing = math.floor(self.padding / 2)

            scrollY = (targetIndex - 1) * (itemHeight + spacing)
        end

        self.scrollView:setYScroll(-scrollY)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingRecipeList_Panel:prerender()
    local contentBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Panel/InnerPanel_BG.png")
    if contentBG then
        contentBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, 1)
    end
end

return NB_BuildingRecipeList_Panel