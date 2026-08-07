-- CleanUI_CSRLootFilterCompat.lua
-- Compatibility guard for Common Sense Reborn's inventory/loot filter controls.
-- CSR creates its own search/filter header and extra bulk buttons on
-- ISInventoryPage / ISLootWindowContainerControls. CleanUI already owns those
-- areas, so this patch hides CSR's overlapping controls while keeping CSR's
-- virtual Nearby Loot container available. It gates high-frequency wrappers
-- behind the relevant CSR feature flags to avoid idle polling cost.

CleanUI_CSRLootFilterCompat = CleanUI_CSRLootFilterCompat or {}
local Compat = CleanUI_CSRLootFilterCompat

Compat.enabled = true
Compat.wrappers = Compat.wrappers or {}
Compat.lastInstallTick = Compat.lastInstallTick or 0
Compat.installStartTick = Compat.installStartTick or 0
Compat.onTickRemoved = Compat.onTickRemoved or false
Compat.onTickMaxDuration = Compat.onTickMaxDuration or 30000
Compat.onTickInterval = Compat.onTickInterval or 1000

local ON_TICK_MAX_DURATION = 30000
local ON_TICK_INTERVAL = 1000

local function safeCall(fn)
    if not fn then return nil end
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

local function activatedModsContain(modId)
    if not modId or not getActivatedMods then return false end
    local mods = getActivatedMods()
    return mods and mods.contains and mods:contains(modId) or false
end

local function tryRequireCSRFeatureFlags()
    if CSR_FeatureFlags then return end
    if not activatedModsContain("CommonSenseReborn") then return end
    if not require then return end
    safeCall(function() require "CSR_FeatureFlags" end)
end

local function callCSRFlag(flagName, defaultValue)
    tryRequireCSRFeatureFlags()
    if CSR_FeatureFlags and type(CSR_FeatureFlags[flagName]) == "function" then
        local value = safeCall(function() return CSR_FeatureFlags[flagName]() end)
        if type(value) == "boolean" then return value end
    end
    return defaultValue
end

function Compat.isCSRActive()
    return activatedModsContain("CommonSenseReborn") or CSR_FeatureFlags ~= nil or CSR_LootFilter ~= nil
end

function Compat.isLootFilterRelevant()
    if not Compat.isCSRActive() then return false end
    return callCSRFlag("isLootFilterEnabled", true) == true
end

function Compat.isLootBagRelevant()
    if not Compat.isCSRActive() then return false end
    return callCSRFlag("isLootBagEnabled", true) == true
end

local onTick

local function removeOnTick()
    if Compat.onTickRemoved then return end
    if Events and Events.OnTick and onTick then
        safeCall(function() Events.OnTick.Remove(onTick) end)
    end
    Compat.onTickRemoved = true
end

local function getUiDim(ui, getterName, fieldName)
    if not ui then return 0 end
    if getterName and type(ui[getterName]) == "function" then
        local value = safeCall(function() return ui[getterName](ui) end)
        if type(value) == "number" then return value end
    end
    local value = ui[fieldName]
    if type(value) == "number" then return value end
    return 0
end

local function isCSRLootBag(container)
    if not container or type(container.getType) ~= "function" then return false end
    local containerType = safeCall(function() return container:getType() end)
    return containerType == "csrLootBag"
end

local function hasCSRControls(page)
    return page and (page.csrSearchEntry ~= nil or page.csrFilterBtn ~= nil)
end

local function isCleanUILayoutPage(page)
    return page
        and page.inventoryPane ~= nil
        and page.containerButtonPanel ~= nil
        and page.containerButtonPanelWidth ~= nil
        and type(page.titleBarHeight) == "function"
end

local function hideControl(control)
    if not control then return end

    -- Clear stale CSR search text so a hidden search field cannot keep filtering.
    if type(control.getInternalText) == "function" and type(control.setText) == "function" then
        local text = safeCall(function() return control:getInternalText() end)
        if text and text ~= "" then
            safeCall(function() control:setText("") end)
        end
    elseif type(control.getText) == "function" and type(control.setText) == "function" then
        local text = safeCall(function() return control:getText() end)
        if text and text ~= "" then
            safeCall(function() control:setText("") end)
        end
    end

    -- Hide and move off-screen. CSR may set the controls visible again during
    -- update(), so CleanUI repeats this in wrapped update/prerender paths.
    if type(control.setVisible) == "function" then safeCall(function() control:setVisible(false) end) end
    if type(control.setX) == "function" then safeCall(function() control:setX(-10000) end) end
    if type(control.setY) == "function" then safeCall(function() control:setY(-10000) end) end
    if type(control.setWidth) == "function" then safeCall(function() control:setWidth(1) end) end
    if type(control.setHeight) == "function" then safeCall(function() control:setHeight(1) end) end
end

local function removeControlFromList(list, control)
    if not list or not control then return end
    for i = #list, 1, -1 do
        if list[i] == control then
            table.remove(list, i)
        end
    end
end

local function addUniqueControl(list, seen, control)
    if control and not seen[control] then
        seen[control] = true
        table.insert(list, control)
    end
end

local function getControlTitle(control)
    if not control then return nil end
    if type(control.getTitle) == "function" then
        local title = safeCall(function() return control:getTitle() end)
        if type(title) == "string" then return title end
    end
    if type(control.title) == "string" then return control.title end
    return nil
end

local function titleLooksLikeCSRLootBagButton(control)
    local title = getControlTitle(control)
    if not title or title == "" then return false end
    local lower = string.lower(title)
    return lower == string.lower((getText and getText("IGUI_invpage_Loot_all")) or "Loot All")
        or lower == "loot all"
        or lower == "take all"
        or lower == string.lower((getTextOrNull and getTextOrNull("ContextMenu_MoveToFloor")) or "Move To Floor")
        or lower == "move to floor"
        or string.find(lower, "unwanted last", 1, true) ~= nil
end

local function removeCSRControl(parent, control)
    if not parent or not control then return end

    -- Hide first so any remaining duplicate child reference cannot render text.
    hideControl(control)

    -- Clear the title on CSR-only buttons. This is defensive against duplicate
    -- child references left by repeated addChild() calls in CSR's arrange().
    if type(control.setTitle) == "function" then
        safeCall(function() control:setTitle("") end)
    elseif type(control.title) == "string" then
        control.title = ""
    end

    -- removeChild() should detach the UI element, but repeated third-party
    -- addChild() calls can leave duplicate Lua-side references. Remove all of
    -- them from the known child/control arrays as well.
    if type(parent.removeChild) == "function" then
        safeCall(function() parent:removeChild(control) end)
        safeCall(function() parent:removeChild(control) end)
    end
    removeControlFromList(parent.controls, control)
    removeControlFromList(parent.children, control)
    removeControlFromList(parent.childrenInOrder, control)
end

local function shrinkControlsToVisibleChildren(controlsUI)
    if not controlsUI or not controlsUI.controls then return end
    local bottom = 0
    for _, control in ipairs(controlsUI.controls) do
        if control and control._csrLootBag ~= true then
            local visible = true
            if type(control.getIsVisible) == "function" then
                local value = safeCall(function() return control:getIsVisible() end)
                if type(value) == "boolean" then visible = value end
            elseif type(control.isVisible) == "function" then
                local value = safeCall(function() return control:isVisible() end)
                if type(value) == "boolean" then visible = value end
            elseif type(control.visible) == "boolean" then
                visible = control.visible
            end
            if visible then
                local y = getUiDim(control, "getY", "y")
                local h = getUiDim(control, "getHeight", "height")
                bottom = math.max(bottom, y + h + 1)
            end
        end
    end
    if bottom > 0 and type(controlsUI.setHeight) == "function" then
        controlsUI:setHeight(bottom)
    end
end

local function restoreCleanUIContainerButtonRects(page)
    if not page or not page.containerButtonPanel or not page.backpacks then return end
    if page.draggingButton or page.dragInsertPosition ~= nil then return end

    local buttonSize = tonumber(page.buttonSize) or 0
    if buttonSize <= 0 then return end

    local panelW = tonumber(page.containerButtonPanelWidth) or getUiDim(page.containerButtonPanel, "getWidth", "width") or buttonSize
    if panelW < buttonSize then panelW = buttonSize end

    local padding = tonumber(page.padding) or 0
    local buttonX = math.floor((panelW - buttonSize) / 2)
    local y = padding

    for _, button in ipairs(page.backpacks) do
        if button then
            -- Keep CleanUI's container icons panel-relative. CSR / other UI wrappers
            -- can re-assert absolute or rail-relative positions after Nearby Loot
            -- layout updates, which makes the icons slide under the panel border.
            if type(button.setX) == "function" then button:setX(buttonX) else button.x = buttonX end
            if type(button.setY) == "function" then button:setY(y) else button.y = y end
            if type(button.setWidth) == "function" then button:setWidth(buttonSize) else button.width = buttonSize end
            if type(button.setHeight) == "function" then button:setHeight(buttonSize) else button.height = buttonSize end
            button.anchorLeft = false
            button.anchorRight = true
            button.anchorTop = false
            button.anchorBottom = false
            y = y + buttonSize + padding
        end
    end
end

local function restoreCleanUILayout(page)
    if not page or not page.controlsUI or not page.inventoryPane or type(page.titleBarHeight) ~= "function" then return end

    safeCall(function()
        local titleBarH = page:titleBarHeight()
        local pageW = getUiDim(page, "getWidth", "width")
        local pageH = getUiDim(page, "getHeight", "height")
        local buttonPanelW = page.containerButtonPanelWidth or 0
        local controlsX = page.isPageLeft and page:isPageLeft() and buttonPanelW or 0
        local controlsW = math.max(1, pageW - buttonPanelW)

        -- CSR LootBag may move the loot controls row to the bottom of the panel
        -- after its own virtual-container buttons are injected. CleanUI owns this
        -- row, so force it back under the title bar before arranging controls.
        if type(page.controlsUI.setX) == "function" then page.controlsUI:setX(controlsX) end
        if type(page.controlsUI.setY) == "function" then page.controlsUI:setY(titleBarH) end
        if type(page.controlsUI.setWidth) == "function" then page.controlsUI:setWidth(controlsW) end

        -- Do not call controlsUI:arrange() here. CSR also wraps arrange() and
        -- injects its Nearby Loot bulk buttons there; calling it from this
        -- cleanup path can re-add the buttons every frame and increase CPU use.
        -- The original arrange/update path has already arranged CleanUI's row.
        shrinkControlsToVisibleChildren(page.controlsUI)

        -- Some CSR wrappers reposition the controls row during update(), so
        -- assert CleanUI geometry after shrinking stale CSR controls.
        if type(page.controlsUI.setX) == "function" then page.controlsUI:setX(controlsX) end
        if type(page.controlsUI.setY) == "function" then page.controlsUI:setY(titleBarH) end
        if type(page.controlsUI.setWidth) == "function" then page.controlsUI:setWidth(controlsW) end

        local controlsH = getUiDim(page.controlsUI, "getHeight", "height")
        local paneX = controlsX
        local paneY = titleBarH + controlsH
        local paneW = controlsW
        local paneH = pageH - paneY
        if paneH < 1 then paneH = 1 end

        -- CleanUI's inventory pane starts below its own filter/controls row.
        if type(page.inventoryPane.setX) == "function" then page.inventoryPane:setX(paneX) end
        if type(page.inventoryPane.setY) == "function" then page.inventoryPane:setY(paneY) end
        if type(page.inventoryPane.setWidth) == "function" then page.inventoryPane:setWidth(paneW) end
        if type(page.inventoryPane.setHeight) == "function" then page.inventoryPane:setHeight(paneH) end

        -- CleanUI's side container-button strip starts directly below the title
        -- bar, not below the search/filter row.
        if page.containerButtonPanel then
            local panelX = page.isPageLeft and page:isPageLeft() and 0 or math.max(0, pageW - buttonPanelW)
            if type(page.containerButtonPanel.setX) == "function" then page.containerButtonPanel:setX(panelX) end
            if type(page.containerButtonPanel.setY) == "function" then page.containerButtonPanel:setY(titleBarH) end
            if type(page.containerButtonPanel.setHeight) == "function" then page.containerButtonPanel:setHeight(math.max(1, pageH - titleBarH)) end
            if page.containerButtonPanelWidth and type(page.containerButtonPanel.setWidth) == "function" then
                page.containerButtonPanel:setWidth(page.containerButtonPanelWidth)
            end
            restoreCleanUIContainerButtonRects(page)
            if page.backpacks and #page.backpacks > 0 and page.backpacks[#page.backpacks].getBottom
                and type(page.containerButtonPanel.setScrollHeight) == "function" then
                page.containerButtonPanel:setScrollHeight(page.backpacks[#page.backpacks]:getBottom() + (page.padding or 0))
            end
        end
    end)
end

function Compat.suppressPage(page)
    if not Compat.enabled or not page or page._cleanUICSRLootFilterSuppressing then return end

    local hasControls = hasCSRControls(page)
    local needsLayoutRestore = Compat.isLootFilterRelevant() and isCleanUILayoutPage(page)

    -- CSR 2026-06-15 can suppress its own controls for CleanUI but still run
    -- layoutLootWindowRail() every update. Restore CleanUI geometry even when
    -- CSR did not create csrSearchEntry/csrFilterBtn, otherwise the loot-panel
    -- container button rail is forced to the wrong side/width.
    if not hasControls and not needsLayoutRestore then return end

    page._cleanUICSRLootFilterSuppressing = true

    -- CSR checks this flag before applying its search text. Category filters and
    -- hide-equipped state are left untouched; this patch only removes the
    -- overlapping CSR header UI and restores CleanUI-owned layout geometry.
    page.csrLootFilterSuppressed = true

    if hasControls then
        hideControl(page.csrSearchEntry)
        hideControl(page.csrFilterBtn)
    end
    restoreCleanUILayout(page)

    page._cleanUICSRLootFilterSuppressing = false
end

function Compat.suppressLootControls(controlsUI)
    if not Compat.enabled or not controlsUI or controlsUI._cleanUICSRLootControlsSuppressing then return end

    local lootWindow = controlsUI.lootWindow
    local container = lootWindow and lootWindow.inventoryPane and lootWindow.inventoryPane.inventory
    if not isCSRLootBag(container) then return end

    controlsUI._cleanUICSRLootControlsSuppressing = true

    -- CSR injects bulk Nearby Loot buttons into the same row CleanUI uses for
    -- its own search/sort/collapse controls. Collect explicit fields, controls
    -- marked by CSR, and title-matched fallback buttons in case CSR changes field
    -- names in a later update.
    local csrButtons = {}
    local seen = {}
    addUniqueControl(csrButtons, seen, controlsUI._csrLootBagTakeAll)
    addUniqueControl(csrButtons, seen, controlsUI._csrLootBagMoveFloor)
    addUniqueControl(csrButtons, seen, controlsUI._csrLootBagUnwantedLast)

    local sources = { controlsUI.controls, controlsUI.children, controlsUI.childrenInOrder }
    for _, source in ipairs(sources) do
        if source then
            for _, control in ipairs(source) do
                if control and (control._csrLootBag == true or titleLooksLikeCSRLootBagButton(control)) then
                    addUniqueControl(csrButtons, seen, control)
                end
            end
        end
    end

    for _, control in ipairs(csrButtons) do
        removeCSRControl(controlsUI, control)
    end
    shrinkControlsToVisibleChildren(controlsUI)

    if controlsUI.controls and #controlsUI.controls > 0 then
        if type(controlsUI.setVisible) == "function" then safeCall(function() controlsUI:setVisible(true) end) end

        -- CSR LootBag places the controls row above the resize widget for its
        -- own virtual-container buttons. After suppressing those buttons, force
        -- CleanUI's row back below the title bar and restore the pane geometry.
        restoreCleanUILayout(lootWindow)

        if type(controlsUI.fixMouseOverButton) == "function" then safeCall(function() controlsUI:fixMouseOverButton() end) end
    end

    controlsUI._cleanUICSRLootControlsSuppressing = false
end

local function suppressKnownPages(pageNeeded, lootControlsNeeded)
    if not Compat.enabled then return end
    if pageNeeded == nil then pageNeeded = Compat.isLootFilterRelevant() end
    if lootControlsNeeded == nil then lootControlsNeeded = Compat.isLootBagRelevant() end
    if not pageNeeded and not lootControlsNeeded then return end
    local players = 1
    if getNumActivePlayers then
        local count = safeCall(function() return getNumActivePlayers() end)
        if type(count) == "number" and count > 0 then players = count end
    end

    for playerNum = 0, players - 1 do
        local invPage = getPlayerInventory and safeCall(function() return getPlayerInventory(playerNum) end) or nil
        local lootPage = getPlayerLoot and safeCall(function() return getPlayerLoot(playerNum) end) or nil
        if pageNeeded then
            Compat.suppressPage(invPage)
            Compat.suppressPage(lootPage)
        end
        if lootControlsNeeded and lootPage and lootPage.controlsUI then
            Compat.suppressLootControls(lootPage.controlsUI)
        end
    end
end

local function wrapPageMethod(methodName)
    if not ISInventoryPage or type(ISInventoryPage[methodName]) ~= "function" then return end
    local key = "ISInventoryPage." .. methodName
    if ISInventoryPage[methodName] == Compat.wrappers[key] then return end

    local original = ISInventoryPage[methodName]
    local wrapper = function(self, ...)
        original(self, ...)
        if Compat.isLootFilterRelevant() or hasCSRControls(self) then
            Compat.suppressPage(self)
        end
    end

    Compat.wrappers[key] = wrapper
    ISInventoryPage[methodName] = wrapper
end

local function wrapLootControlsMethod(methodName)
    if not ISLootWindowContainerControls or type(ISLootWindowContainerControls[methodName]) ~= "function" then return end
    local key = "ISLootWindowContainerControls." .. methodName
    if ISLootWindowContainerControls[methodName] == Compat.wrappers[key] then return end

    local original = ISLootWindowContainerControls[methodName]
    local wrapper = function(self, ...)
        original(self, ...)
        if Compat.isLootBagRelevant() then
            Compat.suppressLootControls(self)
        end
    end

    Compat.wrappers[key] = wrapper
    ISLootWindowContainerControls[methodName] = wrapper
end

function Compat.installWrappers()
    if not Compat.enabled or not Compat.isCSRActive() then return end

    local pageNeeded = Compat.isLootFilterRelevant()
    local lootControlsNeeded = Compat.isLootBagRelevant()
    if not pageNeeded and not lootControlsNeeded then return end

    -- Page update/prerender wrappers are only needed for CSR's inventory filter
    -- controls. If the CSR loot filter feature is disabled, avoid wrapping these
    -- high-frequency methods entirely.
    if pageNeeded and ISInventoryPage then
        wrapPageMethod("createChildren")
        wrapPageMethod("update")
        wrapPageMethod("refreshBackpacks")
        wrapPageMethod("onInventoryContainerSizeChanged")
        wrapPageMethod("prerender")
    end

    -- CSR's Nearby Loot virtual container can still be enabled while the CSR loot
    -- filter feature is disabled. In that case only the loot controls arrange()
    -- wrapper is needed to suppress CSR's overlapping bulk buttons.
    if lootControlsNeeded and ISLootWindowContainerControls then
        wrapLootControlsMethod("arrange")
    end

    suppressKnownPages(pageNeeded, lootControlsNeeded)
end

onTick = function()
    -- Temporary low-frequency load-order safety net. Once CSR is confirmed absent,
    -- disabled for the relevant features, or enough startup time has passed, remove
    -- this OnTick hook so CleanUI does not keep polling forever.
    local now = getTimestampMs and getTimestampMs() or 0
    if Compat.installStartTick == 0 then Compat.installStartTick = now end
    if now - (Compat.lastInstallTick or 0) <= ON_TICK_INTERVAL then return end
    Compat.lastInstallTick = now

    local pageNeeded = Compat.isLootFilterRelevant()
    local lootControlsNeeded = Compat.isLootBagRelevant()
    if not Compat.isCSRActive() or (not pageNeeded and not lootControlsNeeded) then
        removeOnTick()
        return
    end

    Compat.installWrappers()

    if now - (Compat.installStartTick or 0) > ON_TICK_MAX_DURATION then
        removeOnTick()
    end
end

if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(Compat.installWrappers) end
    if Events.OnGameStart then Events.OnGameStart.Add(Compat.installWrappers) end
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(Compat.installWrappers) end
    if Events.OnTick then Events.OnTick.Add(onTick) end
end

return Compat
