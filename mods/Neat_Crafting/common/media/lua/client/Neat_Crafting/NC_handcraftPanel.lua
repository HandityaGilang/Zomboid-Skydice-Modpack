--[[ --------------------------------------------------- --
TODO List:
1.make it can be resized (resize width:recipelist;resize height:recipelist and inputpanel)  done,but still need some performance things to do
3.NCCONFIG better to make it used in XUI
-- --------------------------------------------------- --]]

NC_HandCraftPanel = ISTableLayout:derive("NC_HandCraftPanel")

local function NC_PlayerHasSquare(_player)
    return _player and _player.getSquare and _player:getSquare() ~= nil
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)


-- Build a short, stable description for recipe-related diagnostics.
-- Keep this conservative: only call CraftRecipe methods after the object looks like a CraftRecipe.
local NC_loggedBadRecipeKeys = {}
local NC_reportedSetRecipesFailures = {}

local function NC_IsCraftRecipeObject(recipe)
    if recipe == nil then
        return false, "nil recipe"
    end

    if instanceof then
        local ok, result = pcall(instanceof, recipe, "CraftRecipe")
        if ok then
            if result then
                return true, nil
            end
            return false, "not a CraftRecipe"
        end
    end

    -- Fallback for cases where instanceof is unavailable but the Java object still has a useful class string.
    local text = tostring(recipe)
    if text and string.find(text, "CraftRecipe", 1, true) then
        return true, nil
    end

    return false, "not a CraftRecipe"
end

local function NC_SafeRecipeField(recipe, label, getter)
    if recipe == nil or getter == nil then
        return label .. "=<nil>"
    end

    local ok, value = pcall(getter, recipe)
    if ok and value ~= nil then
        return label .. "=" .. tostring(value)
    end

    return label .. "=<unavailable>"
end

local function NC_GetRecipeDiagnostic(recipe)
    local isRecipe = NC_IsCraftRecipeObject(recipe)
    if not isRecipe then
        return "object=" .. tostring(recipe)
    end

    local parts = {
        "object=" .. tostring(recipe),
        NC_SafeRecipeField(recipe, "name", function(r) return r:getName() end),
        NC_SafeRecipeField(recipe, "fullType", function(r) return r:getScriptObjectFullType() end),
        NC_SafeRecipeField(recipe, "translation", function(r) return r:getTranslationName() end),
        NC_SafeRecipeField(recipe, "category", function(r) return r:getCategory() end),
        NC_SafeRecipeField(recipe, "module", function(r) return r:getModuleName() end),
    }

    return table.concat(parts, "; ")
end

local function NC_LogBadRecipe(source, index, recipe, reason)
    local key = tostring(source) .. ":" .. tostring(index) .. ":" .. tostring(recipe) .. ":" .. tostring(reason)
    if NC_loggedBadRecipeKeys[key] then
        return
    end

    NC_loggedBadRecipeKeys[key] = true
    print("[Neat Crafting] Skipping invalid recipe entry from " .. tostring(source) .. " at index " .. tostring(index) .. ": " .. tostring(reason) .. ". " .. NC_GetRecipeDiagnostic(recipe))
end

local function NC_LogSetRecipesFailure(source, recipeList, errorMessage)
    local key = tostring(source) .. ":" .. tostring(errorMessage)
    if NC_reportedSetRecipesFailures[key] then
        return
    end

    NC_reportedSetRecipesFailures[key] = true
    print("[Neat Crafting] ERROR: HandcraftLogic:setRecipes failed for source " .. tostring(source) .. ": " .. tostring(errorMessage))

    if not recipeList then
        print("[Neat Crafting] setRecipes diagnostic: recipe list is nil.")
        return
    end

    local okSize, size = pcall(function() return recipeList:size() end)
    if not okSize or type(size) ~= "number" then
        print("[Neat Crafting] setRecipes diagnostic: recipe list is not a Java List. object=" .. tostring(recipeList))
        return
    end

    print("[Neat Crafting] setRecipes diagnostic: inspected " .. tostring(size) .. " recipe entries. The first entries are listed below.")
    local maxEntries = math.min(size, 20)
    for i = 0, maxEntries - 1 do
        local okGet, recipe = pcall(function() return recipeList:get(i) end)
        if okGet then
            print("[Neat Crafting]   [" .. tostring(i) .. "] " .. NC_GetRecipeDiagnostic(recipe))
        else
            print("[Neat Crafting]   [" .. tostring(i) .. "] <failed to read entry>: " .. tostring(recipe))
        end
    end
end

local function NC_SanitizeRecipeList(recipes, source)
    local safeRecipes = ArrayList.new()

    if recipes == nil then
        print("[Neat Crafting] Recipe source " .. tostring(source) .. " returned nil; using an empty recipe list.")
        return safeRecipes
    end

    local okSize, size = pcall(function() return recipes:size() end)
    if not okSize or type(size) ~= "number" then
        print("[Neat Crafting] Recipe source " .. tostring(source) .. " did not return a Java List; using an empty recipe list. object=" .. tostring(recipes))
        return safeRecipes
    end

    for i = 0, size - 1 do
        local okGet, recipe = pcall(function() return recipes:get(i) end)
        if okGet then
            local isRecipe, reason = NC_IsCraftRecipeObject(recipe)
            if isRecipe then
                safeRecipes:add(recipe)
            else
                NC_LogBadRecipe(source, i, recipe, reason)
            end
        else
            NC_LogBadRecipe(source, i, nil, "failed to read recipe entry: " .. tostring(recipe))
        end
    end

    if safeRecipes:size() ~= size then
        print("[Neat Crafting] Sanitized recipe source " .. tostring(source) .. ": kept " .. tostring(safeRecipes:size()) .. " / " .. tostring(size) .. " entries.")
    end

    return safeRecipes
end

local function NC_SetLogicRecipesSafely(panel, recipes, source)
    if not panel or not panel.logic then
        print("[Neat Crafting] ERROR: HandcraftLogic is not available while setting recipes from " .. tostring(source) .. ".")
        return false
    end

    local safeRecipes = NC_SanitizeRecipeList(recipes or ArrayList.new(), source)
    local ok, err = pcall(function()
        panel.logic:setRecipes(safeRecipes)
    end)

    if ok then
        return true, safeRecipes
    end

    NC_LogSetRecipesFailure(source, safeRecipes, err)

    -- Leave the panel usable instead of letting a bad recipe source break the whole window.
    local fallbackOk, fallbackErr = pcall(function()
        panel.logic:setRecipes(ArrayList.new())
    end)
    if not fallbackOk then
        print("[Neat Crafting] ERROR: Failed to apply empty fallback recipe list: " .. tostring(fallbackErr))
    end

    return false, safeRecipes
end


-- Safely query craft recipes without assuming the Java bridge will always accept the input type.
-- This also gives us a pure-Lua fallback when a mod or call path passes an unexpected query value.
local function NC_SafeQueryRecipes(recipeQuery)
    local normalizedQuery = nil

    if type(recipeQuery) == "string" then
        normalizedQuery = recipeQuery
    elseif recipeQuery ~= nil then
        -- Ignore unexpected non-string query values and let the caller fall back to defaults.
        print("[Neat Crafting] Ignoring non-string recipe query: " .. tostring(recipeQuery))
        return nil
    else
        return nil
    end

    if normalizedQuery == "" then
        return nil
    end

    -- Prefer the vanilla query path when it works.
    if CraftRecipeManager and CraftRecipeManager.queryRecipes then
        local ok, result = pcall(CraftRecipeManager.queryRecipes, normalizedQuery)
        if ok and result then
            return result
        end

        print("[Neat Crafting] CraftRecipeManager.queryRecipes failed for query '" .. tostring(normalizedQuery) .. "'. Falling back to Lua tag filtering.")
    end

    if not (ScriptManager and ScriptManager.instance and ScriptManager.instance.getAllCraftRecipes) then
        return nil
    end

    local allRecipes = ScriptManager.instance:getAllCraftRecipes()
    if not allRecipes then
        return nil
    end

    if normalizedQuery == "*" then
        return allRecipes
    end

    local whitelist = {}
    local blacklist = {}

    local function NC_AddQueryTokens(targetTable, querySegment)
        if not querySegment or querySegment == "" then
            return
        end

        for token in string.gmatch(querySegment, "[^;]+") do
            local normalizedToken = tostring(token):gsub("^%s+", ""):gsub("%s+$", "")
            if normalizedToken ~= "" then
                targetTable[string.lower(normalizedToken)] = true
            end
        end
    end

    -- Match vanilla TaggedObjectManager semantics: ';' is OR within each section and '-' starts the blacklist section.
    local dashIndex = string.find(normalizedQuery, "-", 1, true)
    if dashIndex then
        local whitelistSegment = dashIndex > 1 and string.sub(normalizedQuery, 1, dashIndex - 1) or nil
        local blacklistSegment = string.sub(normalizedQuery, dashIndex + 1)
        NC_AddQueryTokens(whitelist, whitelistSegment)
        NC_AddQueryTokens(blacklist, blacklistSegment)
    else
        NC_AddQueryTokens(whitelist, normalizedQuery)
    end

    local filteredRecipes = ArrayList.new()
    for i = 0, allRecipes:size() - 1 do
        local recipe = allRecipes:get(i)
        if recipe then
            local hasWhitelistMatch = (next(whitelist) == nil)
            local hasBlacklistMatch = false
            local tags = recipe.getTags and recipe:getTags() or nil

            if tags then
                for tagIndex = 0, tags:size() - 1 do
                    local tagValue = tags:get(tagIndex)
                    if tagValue then
                        local loweredTagValue = string.lower(tostring(tagValue))
                        if whitelist[loweredTagValue] then
                            hasWhitelistMatch = true
                        end
                        if blacklist[loweredTagValue] then
                            hasBlacklistMatch = true
                            break
                        end
                    end
                end
            end

            if hasWhitelistMatch and not hasBlacklistMatch then
                filteredRecipes:add(recipe)
            end
        end
    end

    return filteredRecipes
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_HandCraftPanel:initialise()
    ISTableLayout.initialise(self)
end

function NC_HandCraftPanel:new(x, y, width, height, MainPanel,player,craftBench,isoObject,recipeQuery)
    local o = ISTableLayout:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    --MainData
    o.MainPanel = MainPanel
    o.player = player
    o.craftBench = craftBench
    o.isoObject = isoObject
    o.recipeQuery = recipeQuery
    --MainConfig
    o.padding = NCConfig.padding
    o.scrollBarWidth = NCConfig.scrollBarWidth
    o.titleHeight = NCConfig.titleHeight
    o.scrollViewSpacing = NCConfig.scrollViewSpacing

    --categoryList
    o.categoryListWidth = NCConfig.categoryListWidth

    --recipeListPanel
    o.recipeListWidth = NCConfig.recipeListWidth
    o.recipeListItemHeight = NCConfig.recipeListItemHeight

    --inputPanel
    o.inputSlotHeight = NCConfig.inputSlotHeight
    o.inputPanelWidth = NCConfig.inputPanelWidth

    --recipeInfo
    o.recipeInfoMinHeight = NCConfig.recipeInfoMinHeight

    --outputPanel
    o.outputMinHeight = NCConfig.craftOutputMinHeight

    o.logic = HandcraftLogic.new(o.player, o.craftBench, o.isoObject)
    o.logic:setManualSelectInputs(true)
    o.logic:addEventListener("onUpdateRecipeList", o.onLogicUpdateRecipeList, o)
    o.logic:addEventListener("onRecipeChanged", o.onLogicRecipeChanged, o)
    o.logic:addEventListener("onInputsChanged", o.onLogicInputsChanged, o)
    o.logic:addEventListener("onShowManualSelectChanged", o.onShowManualSelectChanged, o)
    o.logic:addEventListener("onRebuildInputItemNodes", o.onRebuildInputItemNodes, o)
    o.logic:addEventListener("onStartCraft", o.onStartCraft, o)
    o.logic:addEventListener("onStopCraft", o.onStopCraft, o)
    o.lastPlayerMovingState = nil
    o._categoryString = ""
    o._filterString = ""
    o.selectedOutputScript = nil
    
    -- Controls a vanilla-like \"Show All Recipes\" behavior (override recipe source list)
    o.seeAllRecipe = false

    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --
function NC_HandCraftPanel:calculateLayout(_preferredWidth, _preferredHeight)
    ISTableLayout.calculateLayout(self, _preferredWidth, _preferredHeight)

    if self.InputSwitchPanel and self.InputSwitchPanel:isReallyVisible() then
        local inputSwitchWidth = self.InputSwitchPanel:getWidth()
        local inputSwitchHeight = self:getHeight()
        self.InputSwitchPanel:calculateLayout(inputSwitchWidth, inputSwitchHeight)
    end

    if self.OutputSwitchPanel and self.OutputSwitchPanel:isReallyVisible() then
        local outputSwitchWidth = self.OutputSwitchPanel:getWidth()
        local outputSwitchHeight = self:getHeight()
        self.OutputSwitchPanel:calculateLayout(outputSwitchWidth, outputSwitchHeight)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_HandCraftPanel:createChildren()
    self:updateContainers()
    self:setLogicRecipes()
    self:addRowFill(nil)

    self.categoryColumn = self:addColumn(nil)
    self.categoryColumn.minimumWidth = self.categoryListWidth

    self.recipeListColumn = self:addColumnFill(nil)
    self.recipeListColumn.minimumWidth = self.recipeListWidth

    local spacingColumn1 = self:addColumn(nil)
    spacingColumn1.minimumWidth = self.padding

    self.baseCraftColumn = self:addColumn(nil)
    self.baseCraftColumn.minimumWidth = self.inputPanelWidth

    local spacingColumn2 = self:addColumn(nil)
    spacingColumn2.minimumWidth = self.padding
    
    self:createCategoryPanel()
    self:createCellRecipeList()
    self:createCellBaseCraft()

    self.filterBar = self.cellRecipeList.filterBar
    self.recipeListPanel = self.cellRecipeList.recipeListPanel
    self.craftInputPanel = self.cellBaseCraft.craftInputPanel
    self.recipeInfoPanel = self.cellBaseCraft.recipeInfoPanel
    self.craftoutputPanel = self.cellBaseCraft.craftResultPanel.craftoutputPanel
    self.craftActionPanel = self.cellBaseCraft.craftResultPanel.craftActionPanel
    
    self:performInitialUpdate()
end

function NC_HandCraftPanel:createCategoryPanel()
    self.categoryPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_CategoryList_Panel, 0, 0, 10, 10, self)
    self.categoryPanel:initialise()
    self:setElement(self.categoryColumn:index(), 0, self.categoryPanel)
end

function NC_HandCraftPanel:createCellRecipeList()
    self.cellRecipeList = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_CellRecipeList, 0, 0, 10, 10, self)
    self.cellRecipeList:initialise()
    self:setElement(self.recipeListColumn:index(), 0, self.cellRecipeList)
end

function NC_HandCraftPanel:createCellBaseCraft()
    self.cellBaseCraft = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_CellBaseCraft, 0, 0, 10, 10, self)
    self.cellBaseCraft:initialise()
    self:setElement(self.baseCraftColumn:index(), 0, self.cellBaseCraft)
end

-- make sure everything initialise
function NC_HandCraftPanel:performInitialUpdate()
    local currentRecipe = self.logic:getRecipe()
    -- force choose Recipe again
    if currentRecipe then
        self:onLogicRecipeChanged()
    end

    if self.recipeListPanel then
        self:updateRecipeDisplay()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Logic Event listener
-- ----------------------------------------------------------------------------------------------------- --
function NC_HandCraftPanel:onCategoryChanged(categoryValue)
    self._categoryString = categoryValue

    self:filterRecipeList()

    self:onLogicRecipeChanged()
end


-- [Warning]logic:filterRecipeList will trigger logic:sortRecipeList() twice
-- first for base filter ,second for remove rightclickonly
function NC_HandCraftPanel:filterRecipeList()
    local filterString = self._filterString or ""
    if self.recipeListPanel and self.recipeListPanel._filterMode and filterString ~= "" then
        filterString = filterString .. "-@-" .. self.recipeListPanel._filterMode
    end
    self.logic:filterRecipeList(filterString, self._categoryString)
end

function NC_HandCraftPanel:setLogicRecipes()
    local recipes = nil
    local recipeSource = "default handcraft query"

    if type(self.recipeQuery) == "string" and self.recipeQuery ~= "" then
        recipeSource = "recipeQuery=" .. tostring(self.recipeQuery)
        recipes = NC_SafeQueryRecipes(self.recipeQuery)
    elseif self.recipeQuery ~= nil then
        -- Recover from unexpected query payloads by using the default handcraft query.
        print("[Neat Crafting] Invalid recipeQuery payload detected, using default handcraft query instead. payload=" .. tostring(self.recipeQuery))
        recipes = NC_SafeQueryRecipes("InHandCraft;AnySurfaceCraft")
    elseif self.craftBench then
        recipeSource = "craftBench:getRecipes()"
        recipes = self.craftBench:getRecipes()
    else
        recipes = NC_SafeQueryRecipes("InHandCraft;AnySurfaceCraft")
    end

    -- Always provide a sanitized Java list to HandcraftLogic, even if the query failed.
    -- Keep the applied source list so Neat Crafting can recover when vanilla logic returns
    -- an empty category-filtered list for workstation/bench recipes.
    local _, appliedRecipes = NC_SetLogicRecipesSafely(self, recipes, recipeSource)
    self._ncSourceRecipeList = appliedRecipes

    -- When enabled, replace the context-based recipes with the full craft recipe list (vanilla behavior).
    if self.seeAllRecipe then
        if ScriptManager and ScriptManager.instance and ScriptManager.instance.getAllCraftRecipes then
            -- Vanilla source of truth for "all recipes".
            _, appliedRecipes = NC_SetLogicRecipesSafely(self, ScriptManager.instance:getAllCraftRecipes(), "ScriptManager:getAllCraftRecipes()")
        else
            _, appliedRecipes = NC_SetLogicRecipesSafely(self, NC_SafeQueryRecipes("*"), "recipeQuery=*")
        end
        self._ncSourceRecipeList = appliedRecipes
    end
end




-- Enable/disable vanilla-like "Show All Recipes" behavior
function NC_HandCraftPanel:setSeeAllRecipe(enabled)
    -- Normalize to boolean
    self.seeAllRecipe = (enabled == true)

    -- Update containers so can-make checks/tooltips remain consistent
    if self.updateContainers then
        self:updateContainers()
    end

    -- Rebuild recipe source list (bench/query vs all)
    if self.setLogicRecipes then
        self:setLogicRecipes()
    end

    -- Refresh category list (NC does not always auto-repopulate like vanilla)
    if self.categoryPanel and self.categoryPanel.populateCategoryList then
        self.categoryPanel:populateCategoryList()
    end

    -- Re-apply current filters and redraw recipe list
    if self.filterRecipeList then
        self:filterRecipeList()
    end
    if self.updateRecipeDisplay then
        self:updateRecipeDisplay()
    end

    -- Keep the FilterBar toggle state in sync if it exists
    if self.filterBar and self.filterBar.showAllRecipesButton then
        self.filterBar.showAllRecipesButton:setActive(self.seeAllRecipe)
    end
end


function NC_HandCraftPanel:onLogicUpdateRecipeList()
    self:updateRecipeDisplay()
end

-- Trigger function: setRecipe()
function NC_HandCraftPanel:onLogicRecipeChanged()
    -- Close any input/output picker when the selected recipe changes.
    self.logic:setShowManualSelectInputs(false)
    self.logic:setManualSelectInputScriptFilter(nil)
    self:closeOutputSwitchPanel()
    
    self:updateContainers()

    if self.craftInputPanel then
        self.craftInputPanel:onRecipeChanged()
    end
    
    if self.craftoutputPanel then
        self.craftoutputPanel:onRecipeChanged()
    end
    
    if self.recipeInfoPanel then
        self.recipeInfoPanel:onRecipeChanged()
    end

    if self.craftActionPanel then
        self.craftActionPanel:onRecipeChanged()
    end
end

-- Trigger function: offerInputItem(InventoryItem),removeInputItem(InventoryItem),autoPopulateInputs()
function NC_HandCraftPanel:onLogicInputsChanged()
    if self.craftInputPanel then
        self.craftInputPanel:onInputsChanged()
    end
    
    if self.craftoutputPanel then
        self.craftoutputPanel:onInputsChanged()
    end

    if self.craftActionPanel then
        self.craftActionPanel:updateCraftAction()
    end

    if self.InputSwitchPanel then
        self.InputSwitchPanel:onInputsChanged()
    end

    if self.OutputSwitchPanel then
        self.OutputSwitchPanel:onOutputsChanged()
    end
end

-- Trigger function: Manual
function NC_HandCraftPanel:onShowManualSelectChanged(shouldShow)
    if shouldShow then
        self:closeOutputSwitchPanel()
        self:showInputSwitchPanel()
    else
        self:closeInputSwitchPanel()
    end
end

-- Trigger function: setRecipe(),setContainers(),setManualSelectInputScriptFilter()
function NC_HandCraftPanel:onRebuildInputItemNodes()
    if self.InputSwitchPanel then
        self.InputSwitchPanel:loadInputscriptItems()
    end

    if self.craftActionPanel then
        self.craftActionPanel:updateCraftAction()
    end
end

-- Trigger function: startCraftAction(KahluaTableImpl)
function NC_HandCraftPanel:onStartCraft()
    if self.craftActionPanel then
        self.craftActionPanel:updateCraftAction()
    end
end

-- Trigger function: stopCraftAction()
function NC_HandCraftPanel:onStopCraft()
    if self.craftActionPanel then
        self.craftActionPanel:updateCraftAction()
    end
end

function NC_HandCraftPanel:onSearchTextChanged(searchString)
    self._filterString = searchString
    self:filterRecipeList()
end

function NC_HandCraftPanel:onFilterChanged()
    self:updateRecipeDisplay()
end

function NC_HandCraftPanel:updateRecipeDisplay()
    if not self.filterBar or not self.recipeListPanel then
        return
    end

    local filteredRecipes = self.filterBar:getFilteredRecipes()

    self.recipeListPanel:updateRecipeList(filteredRecipes)
end


-- Test Multiple Search
function NC_HandCraftPanel:filterRecipeListMultiple(recipeNames)
    if not recipeNames or #recipeNames == 0 then return end

    local nameSet = {}
    for _, name in ipairs(recipeNames) do
        if name then
            nameSet[tostring(name):lower()] = true
        end
    end

    local filteredRecipes = {}
    local recipeListObj = (self.logic and self.logic.getRecipeList) and self.logic:getRecipeList() or nil

    -- Build 42 recipe lists may be exposed as CraftRecipeListNodeCollection when
    -- vanilla recipe groups are enabled. Use getAllRecipes() when available so
    -- context-menu filtering works with both grouped and flat recipe lists.
    local allRecipes = recipeListObj
    if recipeListObj and recipeListObj.getAllRecipes then
        allRecipes = recipeListObj:getAllRecipes()
    end

    if allRecipes and allRecipes.size and allRecipes.get then
        for i = 0, allRecipes:size() - 1 do
            local recipe = allRecipes:get(i)
            if recipe and recipe.getTranslationName then
                local translationName = tostring(recipe:getTranslationName() or ""):lower()
                if nameSet[translationName] then
                    table.insert(filteredRecipes, recipe)
                end
            end
        end
    elseif type(allRecipes) == "table" then
        for _, recipe in ipairs(allRecipes) do
            if recipe and recipe.getTranslationName then
                local translationName = tostring(recipe:getTranslationName() or ""):lower()
                if nameSet[translationName] then
                    table.insert(filteredRecipes, recipe)
                end
            end
        end
    else
        print("[Neat Crafting] WARNING: filterRecipeListMultiple could not read the current recipe list.")
    end

    if self.recipeListPanel then
        self.recipeListPanel:updateRecipeList(filteredRecipes)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- InputSwitch Panel
-- ----------------------------------------------------------------------------------------------------- --
function NC_HandCraftPanel:showInputSwitchPanel()
    if not self.InputSwitchPanel then
        local Width = FONT_HGT_SMALL * 12
        local Height = self:getHeight()

        self.InputSwitchPanel = NC_InputSwitch_Panel:new(0, 0, Width, Height, self)
        self.InputSwitchPanel:initialise()
        self.InputSwitchPanel:addToUIManager()
        self.InputSwitchPanel:setVisible(true)
    end
end

function NC_HandCraftPanel:closeInputSwitchPanel()
    if self.InputSwitchPanel then
        self.InputSwitchPanel:Close()
        self.InputSwitchPanel = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- OutputSwitch Panel
-- ----------------------------------------------------------------------------------------------------- --
function NC_HandCraftPanel:getSelectedOutputScript()
    return self.selectedOutputScript
end

function NC_HandCraftPanel:toggleOutputSwitchPanel(outputScript)
    if not outputScript then return end

    -- Output selection is only for navigation/search; it must not keep an input slot selected.
    if self.logic then
        self.logic:setManualSelectInputScriptFilter(nil)
        self.logic:setShowManualSelectInputs(false)
    end
    self:closeInputSwitchPanel()

    if self.selectedOutputScript == outputScript and self.OutputSwitchPanel then
        self:closeOutputSwitchPanel()
        return
    end

    self.selectedOutputScript = outputScript
    self:showOutputSwitchPanel()
end

function NC_HandCraftPanel:showOutputSwitchPanel()
    if not self.selectedOutputScript then return end

    if not self.OutputSwitchPanel then
        local Width = FONT_HGT_SMALL * 12
        local Height = self:getHeight()

        self.OutputSwitchPanel = NC_OutputSwitch_Panel:new(0, 0, Width, Height, self)
        self.OutputSwitchPanel:initialise()
        self.OutputSwitchPanel:addToUIManager()
        self.OutputSwitchPanel:setVisible(true)
    else
        self.OutputSwitchPanel:loadOutputscriptItems()
    end
end

function NC_HandCraftPanel:closeOutputSwitchPanel()
    if self.OutputSwitchPanel then
        self.OutputSwitchPanel:Close()
        self.OutputSwitchPanel = nil
    end

    self.selectedOutputScript = nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --

function NC_HandCraftPanel:updateContainers()
    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    return self.logic:setContainers(containers)
end

function NC_HandCraftPanel:updateIsoObject()
    local IsoObject = nil
    if NC_PlayerHasSquare(self.player) then
        IsoObject = ISEntityUI.FindCraftSurface(self.player, 1)
    end
    self.logic:setIsoObject(IsoObject)
end

-- FIXME:In More cases, updates are required.
-- 1.turn on the light 2.transfer items 3.weather changed
-- maybe update when containers:size() changed
function NC_HandCraftPanel:needUpdate()
    local currentMovingState = self.player:isPlayerMoving()

    if self.lastPlayerMovingState == true and currentMovingState == false then
        self.lastPlayerMovingState = currentMovingState
        return true
    end

    if self.lastPlayerMovingState ~= currentMovingState then
        self.lastPlayerMovingState = currentMovingState
    end
    
    return false
end


function NC_HandCraftPanel:update()
    ISTableLayout.update(self)

    -- Skip expensive container/recipe refresh work while a craft action is still running.
    if self.logic and self.logic.isCraftActionInProgress and self.logic:isCraftActionInProgress() then
        return
    end

    if self:needUpdate() then
        local newContainers = ISInventoryPaneContextMenu.getContainers(self.player)

        if not self.craftBench then
            local newIsoObject = nil
            if NC_PlayerHasSquare(self.player) then
                newIsoObject = ISEntityUI.FindCraftSurface(self.player, 1)
            end
            self.logic:setIsoObject(newIsoObject)
        end
        
        self.logic:setContainers(newContainers)

        if self.recipeListPanel then
            self.logic:sortRecipeList()
        end
        
        if self.recipeInfoPanel then
            self.recipeInfoPanel:onRecipeChanged()
        end

        if self.craftActionPanel then
            self.craftActionPanel:updateCraftAction()
        end
    end
end

return NC_HandCraftPanel