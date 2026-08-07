require "ISUI/ISPanel"

NB_FilterBar = ISPanel:derive("NB_FilterBar")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)


-- ============================================================
-- Extra filter helpers (built-in)
-- These filters are part of Neat Building. XP_NB can optionally add more buttons
-- (XP-only / Mod-only) that reuse the same internal filter flags.
-- ============================================================

local function NB_getTextureAny(paths)
    -- Try multiple texture paths and return the first valid texture
    for i = 1, #paths do
        local tex = getTexture(paths[i])
        if tex then return tex end
    end
    return nil
end

local function NB_hasRequiredSkills(playerObj, recipe)
    -- Mirrors vanilla required-skill validation (fail-open if API changes)
    if not playerObj or not recipe then return true end
    if not recipe.getRequiredSkillCount or not recipe.getRequiredSkill then return true end

    local count = 0
    local okCount, result = pcall(function() return recipe:getRequiredSkillCount() end)
    if okCount and result then count = result end
    if count <= 0 then return true end

    for i = 0, count - 1 do
        local req = recipe:getRequiredSkill(i)
        if req and req.getPerk and req.getLevel and playerObj.getPerkLevel then
            local perk = req:getPerk()
            local lvl  = req:getLevel()
            if perk and lvl and playerObj:getPerkLevel(perk) < lvl then
                return false
            end
        end
    end
    return true
end

local function NB_isKnownRecipe(playerObj, recipe)
    -- If recipe doesn't need learning -> treat as known.
    -- If it needs learning -> use IsoGameCharacter.isRecipeKnown(recipe, true)
    if not recipe then return true end
    if not recipe.needToBeLearn then return true end

    local okNeed, need = pcall(function() return recipe:needToBeLearn() end)
    if not okNeed or not need then return true end

    if not playerObj or not playerObj.isRecipeKnown then
        return true
    end

    local okKnown, known = pcall(function() return playerObj:isRecipeKnown(recipe, true) end)
    if okKnown then return known == true end
    return true
end

local function NB_canPerformNow(playerObj, logicObj, recipe)
    -- Matches NB recipe validation behaviour: (info:isValid() and info:isCanPerform()) or cheat
    if not recipe or not logicObj then return false end

    local cheat = (playerObj and playerObj.isBuildCheat and playerObj:isBuildCheat()) == true
    if cheat then return true end

    if not logicObj.getCachedRecipeInfo then
        -- Fail-open if upstream API changes
        return true
    end

    local okInfo, info = pcall(function() return logicObj:getCachedRecipeInfo(recipe) end)
    if not okInfo or not info then return false end

    if info.isValid and info.isCanPerform then
        return (info:isValid() and info:isCanPerform()) == true
    end

    return true
end

-- --- Click handlers ---------------------------------------------------------

function NB_FilterBar:onXP_NB_CanMakeFilterClick()
    -- Toggle "can make now" filter
    self._XP_NB_filterCanMake = not (self._XP_NB_filterCanMake == true)
    if self.canMakeBtn then
        self.canMakeBtn:setActive(self._XP_NB_filterCanMake == true)
    end
    if self.BuildingPanel and self.BuildingPanel.onFilterChanged then
        self.BuildingPanel:onFilterChanged()
    end
end

function NB_FilterBar:onXP_NB_SkillFilterClick()
    -- Toggle "meets skill requirements" filter
    self._XP_NB_filterSkill = not (self._XP_NB_filterSkill == true)
    if self.skillBtn then
        self.skillBtn:setActive(self._XP_NB_filterSkill == true)
    end
    if self.BuildingPanel and self.BuildingPanel.onFilterChanged then
        self.BuildingPanel:onFilterChanged()
    end
end

function NB_FilterBar:onXP_NB_KnownFilterClick()
    -- Toggle "known recipes only" filter
    self._XP_NB_filterKnown = not (self._XP_NB_filterKnown == true)
    if self.knownBtn then
        self.knownBtn:setActive(self._XP_NB_filterKnown == true)
    end
    if self.BuildingPanel and self.BuildingPanel.onFilterChanged then
        self.BuildingPanel:onFilterChanged()
    end
end

function NB_FilterBar:onXP_NB_MinSizeClick()
    -- Resize the main BuildingPanel to its minimum allowed size.
    if self.BuildingPanel and self.BuildingPanel.calculateLayout then
        self.BuildingPanel:calculateLayout(1, 1)
    end
end
-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_FilterBar:initialise()
    ISPanel.initialise(self)
end

function NB_FilterBar:new(x, y, width, height, BuildingPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.BuildingPanel = BuildingPanel
    o.player = BuildingPanel.player
    o.logic = BuildingPanel.logic
    o.padding = BuildingPanel.padding
    o.buttonsize = math.floor(FONT_HGT_SMALL * 1.2)
    o.scrollBarWidth = BuildingPanel.scrollBarWidth
    o.dragging = false
    
    -- Layout icons
    o.GridStyleIcon = getTexture("media/ui/Neat_Building/ICON/Icon_CraftGridStyle.png")
    o.ListStyleIcon = getTexture("media/ui/Neat_Building/ICON/Icon_CraftListStyle.png")
    
    -- Search functionality
    o.searchText = ""
    o.searchMode = "RecipeName"
    o.clearIcon = getTexture("media/ui/Neat_Building/ICON/Icon_Close.png")
    o.UIElementBGTextures = {
        left = getTexture("media/ui/NeatUI/Button/Button_FULL_L.png"),
        middle = getTexture("media/ui/NeatUI/Button/Button_FULL_M.png"),
        right = getTexture("media/ui/NeatUI/Button/Button_FULL_R.png")
    }

    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --
function NB_FilterBar:calculateLayout(_preferredWidth, _preferredHeight)
    local width  = math.max(_preferredWidth or 0, 0)
    local height = math.max(_preferredHeight or 0, 0)

    -- Two-row geometry (row 1: search + min-size + close, row 2: sort + filters + layout toggle)
    local rowH  = self.buttonsize
    local row1Y = self.padding
    local row2Y = row1Y + rowH + self.padding

    -- Ensure we have enough height (fail-safe)
    local minHeight = rowH * 2 + self.padding * 3
    height = math.max(height, minHeight)

    -- ---------------------------------------------------------
    -- Minimum width (compute first so right-aligned buttons are stable)
    -- ---------------------------------------------------------
    local row2LeftCount = 0
    if self.sortButton then row2LeftCount = row2LeftCount + 1 end
    if self.canMakeBtn then row2LeftCount = row2LeftCount + 1 end
    if self.skillBtn   then row2LeftCount = row2LeftCount + 1 end
    if self.knownBtn   then row2LeftCount = row2LeftCount + 1 end
    if self.xpBtn      then row2LeftCount = row2LeftCount + 1 end
    if self.modBtn     then row2LeftCount = row2LeftCount + 1 end

    local hasLayoutBtn = self.layoutToggleButton ~= nil

    local minW_row2Left = 0
    if row2LeftCount > 0 then
        minW_row2Left = row2LeftCount * rowH + (row2LeftCount - 1) * self.padding
    end

    -- Row2 has an extra right-aligned layout toggle button.
    local minW_row2 = minW_row2Left
    if hasLayoutBtn then
        if minW_row2 > 0 then minW_row2 = minW_row2 + self.padding end
        minW_row2 = minW_row2 + rowH
    end

    -- Row1 has: search icon + min search width + min-size button + close button
    local minW_row1 = (rowH * 3) + (self.padding * 4) + (rowH * 4)

    local minW = math.max(minW_row1, minW_row2)
    width = math.max(width, minW)

    -- ---------------------------------------------------------
    -- Row 1: search + min-size + close
    -- ---------------------------------------------------------
    local closeX = width - rowH

    if self.closeButton then
        self.closeButton:setX(closeX)
        self.closeButton:setY(row1Y)
        self.closeButton:setWidth(rowH)
        self.closeButton:setHeight(rowH)
    end

    -- Min-size button sits to the left of close button on row 1
    local minSizeX = closeX - rowH - self.padding
    if self.minSizeBtn then
        self.minSizeBtn:setX(minSizeX)
        self.minSizeBtn:setY(row1Y)
        self.minSizeBtn:setWidth(rowH)
        self.minSizeBtn:setHeight(rowH)
    end

    -- Row 1 left: search icon + search box (+ clear button inside)
    local x1 = 0

    if self.searchModeButton then
        self.searchModeButton:setX(x1)
        self.searchModeButton:setY(row1Y)
        self.searchModeButton:setWidth(rowH)
        self.searchModeButton:setHeight(rowH)
        x1 = x1 + rowH + self.padding
    end

    if self.searchBox then
        -- Fill up to (min-size button - padding) if present, otherwise (close button - padding)
        local rightLimit = (self.minSizeBtn and (minSizeX - self.padding)) or (closeX - self.padding)
        local searchW = rightLimit - x1
        local minSearchW = rowH * 4
        if searchW < minSearchW then searchW = minSearchW end

        self.searchBox:setX(x1)
        self.searchBox:setY(row1Y)
        self.searchBox:setWidth(searchW)
        self.searchBox:setHeight(rowH)

        if self.clearButton then
            local clearX = x1 + searchW - rowH - math.floor(self.padding / 2)
            self.clearButton:setX(clearX)
            self.clearButton:setY(row1Y)
            self.clearButton:setWidth(rowH)
            self.clearButton:setHeight(rowH)
        end
    end

    -- ---------------------------------------------------------
    -- Row 2: sort + filters (left) + layout toggle (right)
    -- ---------------------------------------------------------
    local x2 = 0

    if self.sortButton then
        self.sortButton:setX(x2)
        self.sortButton:setY(row2Y)
        self.sortButton:setWidth(rowH)
        self.sortButton:setHeight(rowH)
        x2 = x2 + rowH + self.padding
    end

    if self.canMakeBtn then
        self.canMakeBtn:setX(x2)
        self.canMakeBtn:setY(row2Y)
        self.canMakeBtn:setWidth(rowH)
        self.canMakeBtn:setHeight(rowH)
        x2 = x2 + rowH + self.padding
    end

    if self.skillBtn then
        self.skillBtn:setX(x2)
        self.skillBtn:setY(row2Y)
        self.skillBtn:setWidth(rowH)
        self.skillBtn:setHeight(rowH)
        x2 = x2 + rowH + self.padding
    end

    if self.knownBtn then
        self.knownBtn:setX(x2)
        self.knownBtn:setY(row2Y)
        self.knownBtn:setWidth(rowH)
        self.knownBtn:setHeight(rowH)
        x2 = x2 + rowH + self.padding
    end

    if self.xpBtn then
        self.xpBtn:setX(x2)
        self.xpBtn:setY(row2Y)
        self.xpBtn:setWidth(rowH)
        self.xpBtn:setHeight(rowH)
        x2 = x2 + rowH + self.padding
    end

    if self.modBtn then
        self.modBtn:setX(x2)
        self.modBtn:setY(row2Y)
        self.modBtn:setWidth(rowH)
        self.modBtn:setHeight(rowH)
        x2 = x2 + rowH + self.padding
    end

    if self.layoutToggleButton then
        -- Right aligned on row 2 (like Neat Crafting)
        local layout2X = width - rowH
        self.layoutToggleButton:setX(layout2X)
        self.layoutToggleButton:setY(row2Y)
        self.layoutToggleButton:setWidth(rowH)
        self.layoutToggleButton:setHeight(rowH)
    end

    self:setWidth(width)
    self:setHeight(height)
end


-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NB_FilterBar:createChildren()
    -- Sort Button
    self.sortButton = NI_SquareButton:new(0, 0, 10, getTexture("media/ui/Neat_Building/ICON/Icon_CraftSort.png"), self, self.onSortButtonClick)
    self.sortButton:initialise()
    self:addChild(self.sortButton)

    -- Search Mode Button
    local searchIcon = getTexture("media/ui/Neat_Building/ICON/Icon_SearchItem.png")
    self.searchModeButton = NI_SquareButton:new(0, 0, 10, searchIcon, self, self.onSearchModeButtonClick)
    self.searchModeButton:initialise()
    self:addChild(self.searchModeButton)

    -- Search Text Entry Box
    self.searchBox = ISTextEntryBox:new("", 0, 0, 10, 10)
    self.searchBox:initialise()
    self.searchBox.font = UIFont.Small
    self.searchBox.onTextChange = function()
        self:onSearchTextChanged()
    end
    self.searchBox.backgroundColor.a = 0
    self.searchBox.borderColor.a = 0
    self.searchBox.prerender = function(searchBox)
        NeatTool.ThreePatch.drawHorizontal(
            searchBox,
            -self.padding/2, 0, 
            searchBox.width + self.padding, searchBox.height,
            self.UIElementBGTextures.left,
            self.UIElementBGTextures.middle,
            self.UIElementBGTextures.right,
            1, 0.4, 0.4, 0.4
        )
    end
    self:addChild(self.searchBox)

    -- Clear Button
    self.clearButton = ISButton:new(0, 0, 10, 10, "", self, self.onClearButtonClick)
    self.clearButton:initialise()
    self.clearButton.borderColor.a = 0
    self.clearButton.backgroundColor.a = 0
    self.clearButton.backgroundColorMouseOver.a = 0
    self.clearButton:setVisible(false)
    
    self.clearButton.prerender = function(button)
        if button:isVisible() then
            local alpha = button:isMouseOver() and 1.0 or 0.7
            button:drawTextureScaled(
                self.clearIcon,
                0, 0,
                button.width, button.height,
                alpha, 0.8, 0.8, 0.8
            )
        end
    end
    self:addChild(self.clearButton)

    -- Layout Toggle Button
    self.layoutToggleButton = NI_SquareButton:new(0, 0, 10, self.ListStyleIcon, self, self.onLayoutToggleButtonClick)
    self.layoutToggleButton:initialise()
    self:addChild(self.layoutToggleButton)

    -- ---------------------------------------------------------
    -- Extra filter buttons (built-in)
    -- ---------------------------------------------------------
    if not self._NB_extraFiltersAdded then
        self._NB_extraFiltersAdded = true

        -- Initialize states (persist per instance)
        self._XP_NB_filterCanMake = self._XP_NB_filterCanMake == true
        self._XP_NB_filterSkill   = self._XP_NB_filterSkill   == true
        self._XP_NB_filterKnown   = self._XP_NB_filterKnown   == true
        -- XP_NB may toggle these flags if its extra buttons are enabled
        self._XP_NB_filterXP      = self._XP_NB_filterXP      == true
        self._XP_NB_filterMod     = self._XP_NB_filterMod     == true

        -- Load icons (prefer Neat_Building; allow fallback paths)
        local canMakeIcon = NB_getTextureAny({
            "media/ui/Neat_Building/ICON/Icon_Canmake.png",
            "media/ui/Neat_Building/Icon/Icon_Canmake.png",
            "media/ui/Neat_Crafting/ICON/Icon_Canmake.png",
            "media/ui/Neat_Crafting/Icon/Icon_Canmake.png",
        })

        local skillIcon = NB_getTextureAny({
            "media/ui/Neat_Building/ICON/Icon_CraftLV.png",
            "media/ui/Neat_Building/Icon/Icon_CraftLV.png",
            "media/ui/Neat_Crafting/ICON/Icon_CraftLV.png",
            "media/ui/Neat_Crafting/Icon/Icon_CraftLV.png",
        })

        local knownIcon = NB_getTextureAny({
            "media/ui/Neat_Building/ICON/Icon_RecipeKnow.png",
            "media/ui/Neat_Building/Icon/Icon_RecipeKnow.png",
            "media/ui/Neat_Crafting/ICON/Icon_RecipeKnow.png",
            "media/ui/Neat_Crafting/Icon/Icon_RecipeKnow.png",
        })

        local minSizeIcon = NB_getTextureAny({
            "media/ui/Neat_Building/ICON/Icon_MinSize.png",
            "media/ui/Neat_Building/Icon/Icon_MinSize.png",
        })

        -- Create CanMake button
        self.canMakeBtn = NI_SquareButton:new(0, 0, 10, canMakeIcon, self, self.onXP_NB_CanMakeFilterClick)
        self.canMakeBtn:initialise()
        self.canMakeBtn:setActiveColor(0.2, 0.6, 0.2)
        self.canMakeBtn:setActive(self._XP_NB_filterCanMake == true)
        self.canMakeBtn:setTooltip(getText("UI_NB_filterOnlyCanBuild"))
        self:addChild(self.canMakeBtn)

        -- Create Skill button
        self.skillBtn = NI_SquareButton:new(0, 0, 10, skillIcon, self, self.onXP_NB_SkillFilterClick)
        self.skillBtn:initialise()
        self.skillBtn:setActiveColor(0.2, 0.6, 0.2)
        self.skillBtn:setActive(self._XP_NB_filterSkill == true)
        self.skillBtn:setTooltip(getText("UI_NB_filterOnlyMetSkillReq"))
        self:addChild(self.skillBtn)

        -- Create Known button
        self.knownBtn = NI_SquareButton:new(0, 0, 10, knownIcon, self, self.onXP_NB_KnownFilterClick)
        self.knownBtn:initialise()
        self.knownBtn:setActiveColor(0.2, 0.6, 0.2)
        self.knownBtn:setActive(self._XP_NB_filterKnown == true)
        self.knownBtn:setTooltip(getText("UI_NB_filterOnlyKnownRecipes"))
        self:addChild(self.knownBtn)

        -- Create "Minimum size" button (row 1, right of search box, left of close button)
        self.minSizeBtn = NI_SquareButton:new(0, 0, 10, minSizeIcon, self, self.onXP_NB_MinSizeClick)
        self.minSizeBtn:initialise()
        local tip = getTextOrNull("UI_NB_setPanelMinSize") or "Set panel to minimum size"
        self.minSizeBtn:setTooltip(tip)
        self:addChild(self.minSizeBtn)
    end

    -- Close Button
    self.closeButton = NI_SquareButton:new(0, 0, 10, self.clearIcon, self, self.onCloseButtonClick)
    self.closeButton:initialise()
    self.closeButton:setActive(true)
    self.closeButton:setActiveColor(0.8, 0.2, 0.2)
    self:addChild(self.closeButton)

    self:updateSortMode()
    self:updateLayoutButton()
    self:updateSearchModeButton()
    self:updateClearButtonVisibility()

    if self.calculateLayout then
        self:calculateLayout(self.width, self.height)
    end
end

function NB_FilterBar:onCloseButtonClick()
    if self.BuildingPanel and self.BuildingPanel.close then
        self.BuildingPanel:close()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Sort Button Functions
-- ----------------------------------------------------------------------------------------------------- --
function NB_FilterBar:onSortButtonClick()
    local context = ISContextMenu.get(0, self.sortButton:getAbsoluteX(), self.sortButton:getAbsoluteY() + self.sortButton:getHeight())
    local option1 = context:addOption(getText("IGUI_SortType_RecipeName") or "Recipe Name", self, self.updateSortMode, "RecipeName")
    option1.iconTexture = getTexture("media/ui/Neat_Building/ICON/Grey.png")
    
    local option2 = context:addOption(getText("IGUI_SortType_LastUsed") or "Last Used", self, self.updateSortMode, "LastUsed")
    option2.iconTexture = getTexture("media/ui/Neat_Building/ICON/Blue.png")
    
    local option3 = context:addOption(getText("IGUI_SortType_MostUsed") or "Most Used", self, self.updateSortMode, "MostUsed")
    option3.iconTexture = getTexture("media/ui/Neat_Building/ICON/Orange.png")
end

function NB_FilterBar:updateSortMode(sortmode)
    if not self.sortButton then return end
    if not sortmode then 
        sortmode = self.logic:getRecipeSortMode() and self.logic:getRecipeSortMode() or "RecipeName"
    end

    self.logic:setRecipeSortMode(sortmode)

    if sortmode == "RecipeName" then
        self.sortButton:setActiveColor(0.2, 0.2, 0.2)
        self.sortButton:setActive(false)
    elseif sortmode == "LastUsed" then
        self.sortButton:setActiveColor(0.2, 0.4, 0.8)
        self.sortButton:setActive(true)
    elseif sortmode == "MostUsed" then
        self.sortButton:setActiveColor(0.8, 0.5, 0.2)
        self.sortButton:setActive(true)
    end

    if self.logic.sortRecipeList then
        self.logic:sortRecipeList()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Layout Toggle Functions
-- ----------------------------------------------------------------------------------------------------- --
function NB_FilterBar:onLayoutToggleButtonClick()
    local currentStyle = self.logic:getSelectedRecipeStyle()
    local newStyle = (currentStyle == "grid") and "list" or "grid"
    
    if self.logic.setSelectedRecipeStyle then
        self.logic:setSelectedRecipeStyle(newStyle)
    end
    self:updateLayoutButton()

    if self.BuildingPanel.recipeListPanel then
        local isGridLayout = (newStyle == "grid")
        self.BuildingPanel.recipeListPanel:setLayoutMode(isGridLayout)
    end
end

function NB_FilterBar:updateLayoutButton()
    if not self.layoutToggleButton then return end

    local currentStyle = self.logic:getSelectedRecipeStyle()

    if currentStyle == "grid" then
        self.layoutToggleButton:setIcon(self.GridStyleIcon)
    else
        self.layoutToggleButton:setIcon(self.ListStyleIcon)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Search Functions
-- ----------------------------------------------------------------------------------------------------- --
function NB_FilterBar:onSearchTextChanged()
    self.searchText = self.searchBox:getInternalText()
    self:updateClearButtonVisibility()
    self:performSearch()
end

function NB_FilterBar:performSearch()
    local searchString = self.searchText or ""

    if self.searchMode and self.searchMode ~= "RecipeName" and searchString ~= "" then
        searchString = searchString .. "-@-" .. self.searchMode
    end

    self.BuildingPanel:onSearchTextChanged(searchString)
end

function NB_FilterBar:onSearchModeButtonClick()
    local context = ISContextMenu.get(
        0, 
        self.searchModeButton:getAbsoluteX(), 
        self.searchModeButton:getAbsoluteY() + self.searchModeButton:getHeight()
    )
    
    local option1 = context:addOption(getText("IGUI_FilterType_RecipeName") or "Recipe Name", self, self.setSearchMode, "RecipeName")
    option1.iconTexture = getTexture("media/ui/Neat_Building/ICON/Grey.png")
    
    local option2 = context:addOption(getText("IGUI_FilterType_InputName") or "Input Name", self, self.setSearchMode, "InputName")
    option2.iconTexture = getTexture("media/ui/Neat_Building/ICON/Blue.png")
end

function NB_FilterBar:setSearchMode(mode)
    self.searchMode = mode
    self:updateSearchModeButton()

    if self.searchText and self.searchText ~= "" then
        self:performSearch()
    end
end

function NB_FilterBar:onClearButtonClick()
    self:clearSearch()
    self:updateClearButtonVisibility()
end

function NB_FilterBar:updateClearButtonVisibility()
    if self.clearButton then
        local hasText = self.searchText and self.searchText ~= ""
        self.clearButton:setVisible(hasText)
    end
end

function NB_FilterBar:updateSearchModeButton()
    if not self.searchModeButton then return end

    if self.searchMode == "RecipeName" then
        self.searchModeButton:setActiveColor(0.2, 0.2, 0.2)
        self.searchModeButton:setActive(false)
    elseif self.searchMode == "InputName" then
        self.searchModeButton:setActiveColor(0.2, 0.4, 0.8)
        self.searchModeButton:setActive(true)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Search Utility Functions
-- ----------------------------------------------------------------------------------------------------- --
function NB_FilterBar:getSearchText()
    return self.searchText
end

function NB_FilterBar:getSearchMode()
    return self.searchMode
end

function NB_FilterBar:setSearchText(text)
    if self.searchBox then
        self.searchBox:setText(text or "")
        self.searchText = text or ""
        self:updateClearButtonVisibility()
    end
end

function NB_FilterBar:clearSearch()
    self:setSearchText("")
    self:performSearch()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Filter Manager
-- ----------------------------------------------------------------------------------------------------- --
function NB_FilterBar:getFilteredRecipes()
    -- Return recipes as a plain Lua array for the UI.
    -- B42.13+ changed logic:getRecipeList() to sometimes return a container with getAllRecipes().
    -- This version supports:
    --   * Java lists (size/get)
    --   * Lua tables (ipairs)
    local result = {}

    local logic = self and self.logic
    if not logic then return result end

    local recipeList = (logic.getRecipeList and logic:getRecipeList()) or nil
    if not recipeList then return result end

    local allRecipes = (recipeList.getAllRecipes and recipeList:getAllRecipes()) or recipeList
    if not allRecipes then return result end

    -- Lua table path
    if type(allRecipes) == "table" then
        for _, r in ipairs(allRecipes) do
            if r then result[#result + 1] = r end
        end
        return result
    end

    -- Java list path
    if allRecipes.size and allRecipes.get then
        for i = 0, allRecipes:size() - 1 do
            local r = allRecipes:get(i)
            if r then result[#result + 1] = r end
        end
    end

    local list = result

    local any =
        self._XP_NB_filterCanMake == true or
        self._XP_NB_filterSkill   == true or
        self._XP_NB_filterKnown   == true or
        self._XP_NB_filterXP      == true or
        self._XP_NB_filterMod     == true

    if not any then
        return list
    end

    local out = {}

    for i = 1, #list do
        local recipe = list[i]
        local ok = true

        -- CanMake filter
        if ok and self._XP_NB_filterCanMake == true then
            ok = NB_canPerformNow(self.player, self.logic, recipe)
        end

        -- Skill filter
        if ok and self._XP_NB_filterSkill == true then
            ok = NB_hasRequiredSkills(self.player, recipe)
        end

        -- Known filter
        if ok and self._XP_NB_filterKnown == true then
            ok = NB_isKnownRecipe(self.player, recipe)
        end

        -- XP filter (only if the recipe API is available)
        if ok and self._XP_NB_filterXP == true then
            local xpCount = 0
            if recipe and recipe.getXPAwardCount then
                local okXp, v = pcall(function() return recipe:getXPAwardCount() end)
                if okXp and v then xpCount = v end
            end
            if xpCount <= 0 then ok = false end
        end

        -- Mod filter (uses XP_NB_resolveModLabel if present; nil means vanilla)
        if ok and self._XP_NB_filterMod == true then
            local fn = rawget(_G, "XP_NB_resolveModLabel")
            if fn then
                local label = fn(recipe)
                if label == nil or label == "" then
                    ok = false
                end
            end
        end

        if ok then
            out[#out + 1] = recipe
        end
    end

    return out

end

function NB_FilterBar:onMouseDown(x, y)
    self.dragging = true
    self.BuildingPanel:bringToTop()
    return true
end

function NB_FilterBar:onMouseMove(dx, dy)
    if self.dragging then
        self.BuildingPanel:setX(self.BuildingPanel:getX() + dx)
        self.BuildingPanel:setY(self.BuildingPanel:getY() + dy)
    end
    return true
end

function NB_FilterBar:onMouseUp(x, y)
    self.dragging = false
    return true
end

function NB_FilterBar:onMouseMoveOutside(dx, dy)
    if self.dragging then
        self.BuildingPanel:setX(self.BuildingPanel:getX() + dx)
        self.BuildingPanel:setY(self.BuildingPanel:getY() + dy)
    end
    return true
end

function NB_FilterBar:onMouseUpOutside(x, y)
    self.dragging = false
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_FilterBar:prerender()
    local TitleBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Panel/MainTitle_BG.png")
    if TitleBG then
        TitleBG:render(self:getAbsoluteX() - self.scrollBarWidth - 1, self:getAbsoluteY(), self.width + self.scrollBarWidth + self.padding + 1, self.height, 0.1, 0.1, 0.1, 1)
    end
end

return NB_FilterBar