require "ISUI/ISPanel"

NB_BuildingPanel = ISTableLayout:derive("NB_BuildingPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- Size clamp while dragging/resizing (integrated from XP_NB SizeClamp patch)
-- ----------------------------------------------------------------------------------------------------- --

local function NB_leftMouseDown()
    -- Use whichever mouse-down function exists in this PZ build (safe for 42.12 and 42.13)
    if isMouseButtonDown then
        local ok, res = pcall(isMouseButtonDown, 0)
        if ok then return res == true end
    end
    if Mouse and Mouse.isButtonDown then
        local ok, res = pcall(Mouse.isButtonDown, 0)
        if ok then return res == true end
    end
    return false
end

local function NB_setAbsPosByDelta(panel, targetAbsX, targetAbsY)
    -- Move a panel to the target absolute position by applying a delta to local x/y.
    if not panel or not panel.getAbsoluteX or not panel.getAbsoluteY then return end
    local absX = panel:getAbsoluteX()
    local absY = panel:getAbsoluteY()
    local dx = targetAbsX - absX
    local dy = targetAbsY - absY
    panel:setX((panel.x or 0) + dx)
    panel:setY((panel.y or 0) + dy)
end

local function NB_clampPanelSizeAndPos(panel)
    -- Clamp panel size/position to keep resize handles reachable after resolution changes.
    if not panel or not getCore then return end

    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    if not sw or not sh then return end

    local w = panel.width or (panel.getWidth and panel:getWidth()) or 0
    local h = panel.height or (panel.getHeight and panel:getHeight()) or 0

    -- Only clamp when the panel is larger than the screen.
    local changed = false
    local targetW, targetH = w, h

    if w > sw then
        targetW = math.floor(sw * 0.9)
        changed = true
    end
    if h > sh then
        targetH = math.floor(sh * 0.9)
        changed = true
    end

    if changed then
        -- Prefer calculateLayout() to preserve NB internal layout & min sizes.
        if panel.calculateLayout then
            panel:calculateLayout(targetW, targetH)
        else
            if panel.setWidth then panel:setWidth(targetW) end
            if panel.setHeight then panel:setHeight(targetH) end
        end
    end

    -- Clamp position so the panel stays on-screen.
    if panel.getAbsoluteX and panel.getAbsoluteY then
        local absX = panel:getAbsoluteX()
        local absY = panel:getAbsoluteY()

        local curW = panel.width or (panel.getWidth and panel:getWidth()) or targetW
        local curH = panel.height or (panel.getHeight and panel:getHeight()) or targetH

        local newAbsX = absX
        local newAbsY = absY

        if newAbsX < 0 then newAbsX = 0 end
        if newAbsY < 0 then newAbsY = 0 end
        if (newAbsX + curW) > sw then newAbsX = math.max(0, sw - curW) end
        if (newAbsY + curH) > sh then newAbsY = math.max(0, sh - curH) end

        if newAbsX ~= absX or newAbsY ~= absY then
            NB_setAbsPosByDelta(panel, newAbsX, newAbsY)
        end
    end
end


-- ----------------------------------------------------------------------------------------------------- --
-- Input picker union helpers (integrated from XP_NB InputPicker patch)
-- ----------------------------------------------------------------------------------------------------- --

local function NB_leftMouseDown()
    -- Cross-build check for "left mouse button is down"
    if isMouseButtonDown then
        local ok, res = pcall(isMouseButtonDown, 0)
        if ok then return res == true end
    end
    if Mouse and Mouse.isButtonDown then
        local ok, res = pcall(Mouse.isButtonDown, 0)
        if ok then return res == true end
    end
    return false
end

local function NB_hidePicker()
    -- Hide the singleton and clear union state
    if NB_PICKER_SINGLETON then
        NB_PICKER_SINGLETON:setVisible(false)
    end
    NB_UI_UNION = nil
end

local NB_lastDown = false

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingPanel:initialise()
    ISTableLayout.initialise(self)
end

function NB_BuildingPanel:new(x, y, width, height, player, isoObject, recipeQuery, contextRecipe)
    local o = ISTableLayout:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    -- Main Data
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.isoObject = isoObject
    o.recipeQuery = recipeQuery or "AnySurfaceCraft"
    o.buildEntity = nil
    o.contextRecipe = contextRecipe

    o.tempAdjWidth = 0
    o.tempAdjHeight = 0
    o:setWantKeyEvents(true)

    o.isCollapse = false
    o.pin = true
    
    -- Main Config
    o.padding = math.floor(FONT_HGT_SMALL * 0.4)
    o.scrollBarWidth = FONT_HGT_SMALL * 0.6
    o.scrollViewSpacing = 2
    
    -- Building specific config
    local btn = math.floor(FONT_HGT_SMALL * 1.2)
    o.filterbarHeight = btn * 2 + o.padding * 3
    
    -- Category and filter state
    o._categoryString = ""
    o._filterString = ""

    o.logic = BuildLogic.new(o.player, o.craftBench, o.isoObject)
    o.logic:addEventListener("onUpdateContainers", o.onLogicUpdateContainers, o)
    o.logic:addEventListener("onRecipeChanged", o.onLogicRecipeChanged, o)
    o.logic:addEventListener("onUpdateRecipeList", o.onLogicUpdateRecipeList, o)
    -- o.logic:addEventListener("onShowManualSelectChanged", o.onShowManualSelectChanged, o)
    o.logic:addEventListener("onStopCraft", o.onStopCraft, o)
    o.lastPlayerMovingState = nil
    
    return o
end


-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingPanel:createChildren()
    self:updateContainers()
    self:setLogicRecipes()

    self:addRowFill(nil)

    self.categoryColumn = self:addColumn(nil)
    
    self.recipeListColumn = self:addColumnFill(nil)

    local spacingCloumn = self:addColumn(nil)
    spacingCloumn.minimumWidth = self.padding

    self:createCellRecipeList()
    self:createResizeWidget()
    self:createCategoryPanel()
    self.filterBar = self.cellRecipeList.filterBar
    self.recipeListPanel = self.cellRecipeList.recipeListPanel

    self:performInitialUpdate()
end

function NB_BuildingPanel:createCategoryPanel()
    self.categoryPanel = NB_BuildingCategoryPanel:new(0, 0, 10, 10, self)
    self.categoryPanel:initialise()
    self:setElement(self.categoryColumn:index(), 0, self.categoryPanel)
end

function NB_BuildingPanel:createCellRecipeList()
    self.cellRecipeList = NB_CellRecipeList:new(0, 0, 10, 10, self)
    self.cellRecipeList:initialise()
    self:setElement(self.recipeListColumn:index(), 0, self.cellRecipeList)
end

function NB_BuildingPanel:createResizeWidget()
    local resizeSize = self.padding
    self.resizeWidget = ISResizeWidget:new(self.width - resizeSize-2, self.height - resizeSize-2, resizeSize, resizeSize, self, false)
    self.resizeWidget.anchorRight = true
    self.resizeWidget.anchorBottom = true
    self.resizeWidget:initialise()
    self.resizeWidget:instantiate()
    self.resizeWidget:setAlwaysOnTop(true)
    self.resizeWidget.prerender = function(widget)
        local alpha = widget.mouseOver and 0.8 or 0.6
        widget:drawTextureScaledAspect(getTexture("media/ui/NeatUI/Resize/ResizeIcon.png"), 0, 0, widget.width, widget.height, alpha, 1, 1, 1)
    end
    self.resizeWidget.resizeFunction = function(target, newWidth, newHeight)
        target:calculateLayout(newWidth, newHeight)
    end
    ISPanel.addChild(self, self.resizeWidget)
end

-- make sure everything initialise
function NB_BuildingPanel:performInitialUpdate()
    local currentRecipe = self.logic:getRecipe()
    -- force choose Recipe again
    if currentRecipe then
        self:onLogicRecipeChanged()
    end

    if self.recipeListPanel then
        self:updateRecipeDisplay()
    end

    -- Guard the initial context selection because some mod/plugin paths can supply nil or stale recipes.
    if self.contextRecipe and self.contextRecipe.getName then
        local ok, err = pcall(function() self.logic:setRecipe(self.contextRecipe) end)
        if ok and self.recipeListPanel then
            self.recipeListPanel:scrollToRecipe(self.contextRecipe)
        elseif not ok then
            print("NB_BuildingPanel.performInitialUpdate: failed to apply context recipe - " .. tostring(err))
        end
    end

    self.contextRecipe = nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- Logic Event listener
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingPanel:onCategoryChanged(categoryValue)
    self._categoryString = categoryValue
    self:filterRecipeList()
end

function NB_BuildingPanel:filterRecipeList()
    local filterString = self._filterString or ""
    if self.recipeListPanel and self.recipeListPanel._filterMode and filterString ~= "" then
        filterString = filterString .. "-@-" .. self.recipeListPanel._filterMode
    end
    self.logic:filterRecipeList(filterString, self._categoryString)
end

function NB_BuildingPanel:setLogicRecipes()
    -- Keep the initial recipe source load resilient to Java/Lua bridge errors.
    local okList, list = pcall(function() return self.logic:getAllBuildableRecipes() end)
    if not okList then
        print("NB_BuildingPanel.setLogicRecipes: failed to read buildable recipes - " .. tostring(list))
        return
    end

    if not list then
        return
    end

    local okSet, err = pcall(function() self.logic:setRecipes(list) end)
    if not okSet then
        print("NB_BuildingPanel.setLogicRecipes: failed to set buildable recipes - " .. tostring(err))
    end
end

-- setContainers
function NB_BuildingPanel:onLogicUpdateContainers()
    -- self:updateRecipeDisplay()
end

-- sortRecipeList:filterRecipeList()setRecipes()
function NB_BuildingPanel:onLogicUpdateRecipeList()
    self:updateRecipeDisplay()
end

function NB_BuildingPanel:startBuild()
    self:createBuildIsoEntity()
end

function NB_BuildingPanel:onStopCraft()
    self:updateContainers()
    self.logic:sortRecipeList()
    self.logic:refresh()
    self:updateRecipeDisplay()
    -- recreate build entity for quick sequential building by player  
    self:createBuildIsoEntity()
end

function NB_BuildingPanel:onSearchTextChanged(searchString)
    self._filterString = searchString
    self:filterRecipeList()
end

function NB_BuildingPanel:onFilterChanged()
    self:updateRecipeDisplay()
end


function NB_BuildingPanel:updateRecipeDisplay()
    if not self.filterBar or not self.recipeListPanel then
        return
    end

    local filteredRecipes = self.filterBar:getFilteredRecipes()

    self.recipeListPanel:updateRecipeList(filteredRecipes)
end

-- setRecipe
function NB_BuildingPanel:onLogicRecipeChanged()


if self.logic then
    -- Clear selection state stored by input picker (avoid stale choices between recipes)
    local clearFn = rawget(_G, "NB_clearInputSelectionMap")
    if clearFn then
        clearFn(self.logic)
    end
end
    self:updateContainers()

    self:updateRecipeDisplay()

    local recipe = self.logic:getRecipe()
    if recipe then
        self:showBuildingInfoPanel(recipe)
    else
        self:closeBuildingInfoPanel()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- build Entity
-- ----------------------------------------------------------------------------------------------------- --

-- ----------------------------------------------------------------------------------------------------- --
-- Ceilings B42 compatibility helpers
-- ----------------------------------------------------------------------------------------------------- --

local function NB_tagsContainCeiling(tags)
    if not tags then return false end

    if type(tags) == "string" then
        return string.find(string.lower(tags), "ceiling", 1, true) ~= nil
    end

    if type(tags) == "table" then
        for _, tag in pairs(tags) do
            if type(tag) == "string" and string.lower(tag) == "ceiling" then
                return true
            end
        end
    end

    if tags.contains then
        local ok, result = pcall(function()
            return tags:contains("Ceiling") or tags:contains("ceiling")
        end)
        if ok and result then return true end
    end

    if tags.size and tags.get then
        local ok, count = pcall(function() return tags:size() end)
        if ok and count then
            for i = 0, count - 1 do
                local okTag, tag = pcall(function() return tags:get(i) end)
                if okTag and type(tag) == "string" and string.lower(tag) == "ceiling" then
                    return true
                end
            end
        end
    end

    return false
end

local function NB_isCeilingsB42Recipe(recipe)
    if not recipe then return false end

    local checks = {
        function()
            if recipe.getTags then return recipe:getTags() end
            return nil
        end,
        function()
            return recipe.tags
        end,
    }

    for _, check in ipairs(checks) do
        local ok, tags = pcall(check)
        if ok and NB_tagsContainCeiling(tags) then
            return true
        end
    end

    return false
end

local function NB_getPlayerZ(player)
    if not player or not player.getCurrentSquare then return 0 end
    local square = player:getCurrentSquare()
    if square and square.getZ then
        return square:getZ()
    end
    return 0
end

local function NB_getOrCreateCeilingsB42Square(x, y, z)
    -- Get or create the target z+1 grid square used by Ceilings B42 validation.
    local ceilingSquare = getCell():getGridSquare(x, y, z)
    if ceilingSquare then
        return ceilingSquare
    end

    local okWorld, validSquare = pcall(function()
        return getWorld():isValidSquare(x, y, z)
    end)

    if okWorld and validSquare then
        local okCreate, createdSquare = pcall(function()
            return getCell():createNewGridSquare(x, y, z, true)
        end)
        if okCreate then
            ceilingSquare = createdSquare
        end
    end

    return ceilingSquare
end

local function NB_isCeilingsB42PlacementValid(buildEntity, x, y, baseZ)
    -- Keep the target z synchronized with the hovered floor square.
    if not buildEntity then
        return false, nil, nil
    end

    baseZ = tonumber(baseZ) or buildEntity.originalZ or 0
    local ceilingZ = baseZ + 1
    buildEntity.originalZ = baseZ
    buildEntity.ceilingZ = ceilingZ

    local ceilingSquare = NB_getOrCreateCeilingsB42Square(x, y, ceilingZ)
    if not ceilingSquare then
        return false, nil, ceilingZ
    end

    local okValid, ceilingValid = pcall(function()
        return buildEntity:isValid(ceilingSquare, buildEntity.north)
    end)

    return okValid and ceilingValid == true, ceilingSquare, ceilingZ
end

local function NB_applyCeilingsB42CursorSupport(buildEntity, player, recipe)
    if not buildEntity or not NB_isCeilingsB42Recipe(recipe or buildEntity.craftRecipe) then
        return
    end

    local currentZ = NB_getPlayerZ(player)
    buildEntity.isCeilingBuild = true
    buildEntity.originalZ = currentZ
    buildEntity.ceilingZ = currentZ + 1
    buildEntity.craftRecipe = recipe or buildEntity.craftRecipe

    if not buildEntity._NB_CeilingsB42TryBuildPatched and buildEntity.tryBuild then
        buildEntity._NB_CeilingsB42TryBuildPatched = true
        local originalTryBuild = buildEntity.tryBuild
        buildEntity.tryBuild = function(selfBuild, x, y, z)
            -- Final safety gate: do not start the timed action if the z+1 ceiling target is invalid.
            local baseZ = tonumber(z) or selfBuild.originalZ or NB_getPlayerZ(player)
            local placementValid = NB_isCeilingsB42PlacementValid(selfBuild, x, y, baseZ)
            selfBuild.canBeBuild = placementValid

            if not placementValid then
                selfBuild.build = false
                return nil
            end

            return originalTryBuild(selfBuild, x, y, z)
        end
    end

    if buildEntity._NB_CeilingsB42RenderPatched then
        return
    end
    buildEntity._NB_CeilingsB42RenderPatched = true

    local originalRender = buildEntity.render
    buildEntity.render = function(selfRender, x, y, z, square)
        local baseZ = tonumber(z) or selfRender.originalZ or currentZ
        local ceilingValid, ceilingSquare, ceilingZ = NB_isCeilingsB42PlacementValid(selfRender, x, y, baseZ)
        selfRender.canBeBuild = ceilingValid

        local floorCursor = nil
        if selfRender.getFloorCursorSprite then
            local okCursor, cursor = pcall(function() return selfRender:getFloorCursorSprite() end)
            if okCursor then floorCursor = cursor end
        end

        if not ceilingSquare then
            if floorCursor then
                floorCursor:RenderGhostTileRed(x, y, baseZ)
            end
            return
        end

        -- Draw the real ceiling ghost at z+1.
        originalRender(selfRender, x, y, ceilingZ, ceilingSquare)

        -- Draw a floor-level placement guide and keep it in sync with the real z+1 validation.
        if floorCursor then
            if ceilingValid then
                local color = getCore() and getCore():getGoodHighlitedColor()
                if color then
                    floorCursor:RenderGhostTileColor(x, y, baseZ, color:getR(), color:getG(), color:getB(), 0.8)
                else
                    floorCursor:RenderGhostTileColor(x, y, baseZ, 0.0, 1.0, 0.0, 0.8)
                end
            else
                floorCursor:RenderGhostTileRed(x, y, baseZ)
            end
        end
    end
end


function NB_BuildingPanel.SetDragItem(item, playerNum)
    local windowKey = "BuildWindow"

    -- Context menus and other UI systems may clear the drag item before the BuildWindow
    -- has created its ISEntityUI player/window tables. Guard every level before indexing.
    if not ISEntityUI or not ISEntityUI.players or playerNum == nil then return end

    local playerData = ISEntityUI.players[playerNum]
    if not playerData or not playerData.windows then return end

    local windowData = playerData.windows[windowKey]
    if not windowData or not windowData.instance then return end

    local instance = windowData.instance

    if item then
        instance.pin = false
        instance.isCollapse = true
        if instance.recipeListColumn then
            instance.recipeListColumn:setVisible(false)
        end
        if instance.spacingCloumn then
            instance.spacingCloumn:setVisible(false)
        end
        if instance.resizeWidget then
            instance.resizeWidget:setVisible(false)
        end
        if instance.BuildingInfoPanel then
            instance.BuildingInfoPanel:setVisible(false)
        end
        instance.tempadjWidth = instance:getWidth()
        instance.tempadjHeight = instance:getHeight()
        instance:calculateLayout(instance.categoryListWidth, instance.tempadjHeight)
    else
        instance.pin = true
    end
end

function NB_BuildingPanel:createBuildIsoEntity(dontSetDrag)
    local player = self.player
    local info = self.logic:getSelectedBuildObject()
    local recipe = self.logic:getRecipe()
    
    if info ~= nil and recipe ~= nil then
        if self.buildEntity == nil or self.buildEntity.objectInfo ~= info then
            local containers = ISInventoryPaneContextMenu.getContainers(self.player)
            self.buildEntity = ISBuildIsoEntity:new(player, info, 1, containers, self.logic)
            self.buildEntity.dragNilAfterPlace = false
            self.buildEntity.blockAfterPlace = true
            self.buildEntity.player = player:getPlayerNum()
    
            local inventory = player:getInventory()
            
            local function getTool(toolInfo, inventory)
                if toolInfo then
                    local inputScript = toolInfo
                    local entryItems = inputScript:getPossibleInputItems()
                    
                    for m = 0, entryItems:size() - 1 do
                        local itemType = entryItems:get(m):getFullName()
                        local result = inventory:getAllTypeEvalRecurse(itemType, ISBuildIsoEntity.predicateMaterial)
                        if result:size() > 0 then
                            return result:get(0):getFullType()
                        end
                    end
                end
                return nil
            end
            
            self.buildEntity.equipBothHandItem = getTool(recipe:getToolBoth(), inventory)
            self.buildEntity.firstItem = getTool(recipe:getToolRight(), inventory)
            self.buildEntity.secondItem = getTool(recipe:getToolLeft(), inventory)
        end

        local canBuild = self.logic:canPerformCurrentRecipe() or self.player:isBuildCheat()
        
        if self.logic:isCraftActionInProgress() then
            canBuild = false
        end

        self.buildEntity.blockBuild = not canBuild

        NB_applyCeilingsB42CursorSupport(self.buildEntity, player, recipe)

        if not dontSetDrag then
            getCell():setDrag(self.buildEntity, player:getPlayerNum())
        end
    else
        self.buildEntity = nil
        getCell():setDrag(nil, player:getPlayerNum())
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Key Function
-- ----------------------------------------------------------------------------------------------------- --

function NB_BuildingPanel:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

function NB_BuildingPanel:onKeyRelease(key)
    if self.cellRecipeList:isVisible() and self:isVisible() and key == Keyboard.KEY_ESCAPE then
        self:close()
        return true
    end

    if not self.cellRecipeList:isVisible() and self.categoryPanel:isVisible() and key == Keyboard.KEY_ESCAPE then
        getCell():setDrag(nil, self.player:getPlayerNum())
        return true
    end

    return false
end

function NB_BuildingPanel:onKeyPressed(key)
    if key == Keyboard.KEY_ESCAPE or getCore():isKey("Crafting UI", key) or getCore():isKey("Build UI", key) then
        return true
    end
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingPanel:update()
    ISTableLayout.update(self)

    self:updateCollapseState()

    if self.BuildingInfoPanel then
        local mouseOverInfoPanel = self.BuildingInfoPanel:isMouseOver()
        local mouseOverBuildingPanel = self:isMouseOver()
        
        if (mouseOverInfoPanel or mouseOverBuildingPanel) and not self.isCollapse then
            self.BuildingInfoPanel:setVisible(true)
        else
            self.BuildingInfoPanel:setVisible(false)
        end
    end

    local currentMovingState = self.player:isPlayerMoving()

    if self.lastPlayerMovingState == true and currentMovingState == false then
        self.lastPlayerMovingState = currentMovingState
        self:updateContainers()
        self:updateRecipeDisplay()
    end

    if self.lastPlayerMovingState ~= currentMovingState then
        self.lastPlayerMovingState = currentMovingState
    end
    -- Clamp oversized panel while dragging/resizing after a resolution change
    if NB_leftMouseDown() then
        local sw = getCore():getScreenWidth()
        local sh = getCore():getScreenHeight()
        local w = self.width or 0
        local h = self.height or 0
        if sw and sh and (w > sw or h > sh) then
            NB_clampPanelSizeAndPos(self)
        end
    end
    -- Input picker auto-close logic (click outside + when info panel collapses)
    local union = rawget(_G, "NB_UI_UNION")
    if union and union.picker and union.picker.isVisible and union.picker:isVisible() then
        -- Close picker if NB hides the info panel (leave-union behavior)
        if union.infoPanel and union.infoPanel.isReallyVisible and (not union.infoPanel:isReallyVisible()) then
            NB_hidePicker()
            NB_lastDown = NB_leftMouseDown()
            return
        end

        local down = NB_leftMouseDown()
        if union.ignoreClickCloseUntilMouseUp then
            -- Avoid immediate close on the same click that opened the picker
            if not down then
                union.ignoreClickCloseUntilMouseUp = false
            end
        else
            -- Close on mouse-down edge if click is outside the picker
            if down and (not NB_lastDown) then
                if union.picker.isMouseOver and (not union.picker:isMouseOver()) then
                    NB_hidePicker()
                    NB_lastDown = down
                    return
                end
            end
        end

        NB_lastDown = down
    else
        NB_lastDown = NB_leftMouseDown()
    end

end

function NB_BuildingPanel:updateContainers()
    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    self.logic:setContainers(containers)
end


function NB_BuildingPanel:updateResizeWidgetPosition()
    if self.resizeWidget then
        local resizeSize = self.padding
        local newX = self.width - resizeSize - 2
        local newY = self.height - resizeSize - 2
        self.resizeWidget:setX(newX)
        self.resizeWidget:setY(newY)
    end
end

function NB_BuildingPanel:updateCollapseState()
    local shouldExpand
    
    if self.pin then
        shouldExpand = true
    else
        shouldExpand = self:isMouseOver() or self.BuildingInfoPanel:isMouseOver()
    end

    if shouldExpand and self.isCollapse then
        self.isCollapse = false
        if self.recipeListColumn then
            self.recipeListColumn:setVisible(true)
        end
        if self.spacingCloumn then
            self.spacingCloumn:setVisible(true)
        end
        if self.resizeWidget then
            self.resizeWidget:setVisible(true)
        end
        self:calculateLayout(self.tempadjWidth, self.tempadjHeight)
        
    elseif not shouldExpand and not self.isCollapse then
        self.isCollapse = true
        if self.recipeListColumn then
            self.recipeListColumn:setVisible(false)
        end
        if self.spacingCloumn then
            self.spacingCloumn:setVisible(false)
        end
        if self.resizeWidget then
            self.resizeWidget:setVisible(false)
        end
        self.tempadjWidth = self:getWidth()
        self.tempadjHeight = self:getHeight()
        self:calculateLayout(self.categoryListWidth, self.tempadjHeight)
    end
end
-- ----------------------------------------------------------------------------------------------------- --
-- Panel Manager
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingPanel:close()

    self:closeBuildingInfoPanel()
    ISEntityUI.OnCloseWindow(self)
    getCell():setDrag(nil, self.player:getPlayerNum())
    
    if JoypadState.players[self.playerNum+1] then
        if isJoypadFocusOnElementOrDescendant(self.playerNum, self) then
            setJoypadFocus(self.playerNum, nil)
        end
    end

    if self.isoObject and getCore():getOptionDoContainerOutline() then
        self.isoObject:setOutlineHighlight(false);
        self.isoObject:setOutlineHlAttached(false);
    end
    
    self:removeFromUIManager()
end

function NB_BuildingPanel:showBuildingInfoPanel()
    
    if not (self.BuildingInfoPanel and self.BuildingInfoPanel:isReallyVisible()) then
        self.BuildingInfoPanel = NB_BuildingInfoPanel:new(0, 0, 50, 50, self)
        self.BuildingInfoPanel:initialise()
        self.BuildingInfoPanel:addToUIManager()
        self.BuildingInfoPanel:setVisible(false)
        self.BuildingInfoPanel:onRecipeChanged()
    else
        self.BuildingInfoPanel:onRecipeChanged()
    end
end

function NB_BuildingPanel:closeBuildingInfoPanel()
    if self.BuildingInfoPanel then
        self.BuildingInfoPanel:close()
        self.BuildingInfoPanel = nil
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingPanel:prerender()

    local panelBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Panel/MainPanelBG_RoundTop.png")
    if panelBG and not self.isCollapse then
        panelBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.15, 0.15, 0.15, 1)
    end
end

Events.SetDragItem.Remove(ISBuildPanel.SetDragItem)
Events.SetDragItem.Add(NB_BuildingPanel.SetDragItem)

-- Prioritize selected fullType (if the picker stores a preference) in BuildLogic:getSatisfiedInputItems()
Events.OnGameBoot.Add(function()
    if not BuildLogic or BuildLogic._XP_NB_satisfiedHooked then return end
    BuildLogic._XP_NB_satisfiedHooked = true

    local _oldSatisfied = BuildLogic.getSatisfiedInputItems

    function BuildLogic:getSatisfiedInputItems(inputScript)
        local list = _oldSatisfied and _oldSatisfied(self, inputScript) or nil
        if not list or not inputScript then return list end

        local getMap = rawget(_G, "NB_getInputSelectionMap")
        if not getMap then return list end

        local map = getMap(self)
        if not map then return list end

        -- Key must match the one used by the picker.
        local key = nil
        if inputScript.getName then
            local ok, name = pcall(inputScript.getName, inputScript)
            if ok and name then key = "name:" .. tostring(name) end
        end
        if (not key) and inputScript.getID then
            local ok, id = pcall(inputScript.getID, inputScript)
            if ok and id then key = "id:" .. tostring(id) end
        end
        if not key then key = "ud:" .. tostring(inputScript) end

        local selected = map[key]
        if not selected then return list end

        -- Find a matching inventory item and swap it to index 0
        if list.size and list:size() > 1 then
            for i = 0, list:size() - 1 do
                local it = list:get(i)
                if it then
                    local fullType = it.getFullType and it:getFullType() or (it.getFullName and it:getFullName() or nil)
                    if fullType == selected then
                        if i > 0 and list.set then
                            local first = list:get(0)
                            list:set(0, it)
                            list:set(i, first)
                        end
                        break
                    end
                end
            end
        end

        return list
    end
end)
