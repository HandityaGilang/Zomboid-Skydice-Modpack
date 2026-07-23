-- CleanUI_InventoryUIModeSwitcher.lua
-- Stores both the CleanUI and vanilla inventory classes, then swaps the active
-- globals when the ModOption changes.

local function CleanUI_uiSwitcherDebug(message)
    -- Set _G.CLEANUI_UI_SWITCHER_DEBUG = true before load to enable debug prints.
    if rawget(_G, "CLEANUI_UI_SWITCHER_DEBUG") ~= true then
        return
    end
    print("[CleanUI] " .. tostring(message))
end

local function CleanUI_storeEnhancedClasses()
    -- Cache the currently loaded CleanUI overrides before we swap anything.
    if not _G.CleanUI_Clean_ISInventoryPage and ISInventoryPage then
        _G.CleanUI_Clean_ISInventoryPage = ISInventoryPage
    end
    if not _G.CleanUI_Clean_ISInventoryPane and ISInventoryPane then
        _G.CleanUI_Clean_ISInventoryPane = ISInventoryPane
    end
    if not _G.CleanUI_Clean_ISInventoryWindowContainerControls and ISInventoryWindowContainerControls then
        _G.CleanUI_Clean_ISInventoryWindowContainerControls = ISInventoryWindowContainerControls
    end
    if not _G.CleanUI_Clean_ISLootWindowContainerControls and ISLootWindowContainerControls then
        _G.CleanUI_Clean_ISLootWindowContainerControls = ISLootWindowContainerControls
    end

    return _G.CleanUI_Clean_ISInventoryPage ~= nil
        and _G.CleanUI_Clean_ISInventoryPane ~= nil
        and _G.CleanUI_Clean_ISInventoryWindowContainerControls ~= nil
        and _G.CleanUI_Clean_ISLootWindowContainerControls ~= nil
end

local function CleanUI_loadVanillaClasses()
    -- Load the namespaced vanilla copies for this build branch once.
    if _G.CleanUI_Vanilla_ISInventoryPage
        and _G.CleanUI_Vanilla_ISInventoryPane
        and _G.CleanUI_Vanilla_ISInventoryWindowContainerControls
        and _G.CleanUI_Vanilla_ISLootWindowContainerControls then
        return true
    end

    require "CleanUI/Vanilla/CleanUI_Vanilla_ISInventoryPane"
    require "CleanUI/Vanilla/CleanUI_Vanilla_ISInventoryWindowContainerControls"
    require "CleanUI/Vanilla/CleanUI_Vanilla_ISLootWindowContainerControls"
    require "CleanUI/Vanilla/CleanUI_Vanilla_ISInventoryPage"

    return _G.CleanUI_Vanilla_ISInventoryPage ~= nil
        and _G.CleanUI_Vanilla_ISInventoryPane ~= nil
        and _G.CleanUI_Vanilla_ISInventoryWindowContainerControls ~= nil
        and _G.CleanUI_Vanilla_ISLootWindowContainerControls ~= nil
end


local function CleanUI_playerUsesController(playerNum)
    -- Preserve vanilla controller behavior: inventory and loot panels start hidden
    -- and should only be opened when controller focus explicitly asks for them.
    local playerObj = getSpecificPlayer(playerNum)
    if playerObj and playerObj.getJoypadBind and playerObj:getJoypadBind() ~= -1 then
        return true
    end
    if type(getJoypadData) == "function" and getJoypadData(playerNum) ~= nil then
        return true
    end
    if JoypadState and JoypadState.players and JoypadState.players[playerNum + 1] ~= nil then
        return true
    end
    return false
end

local function CleanUI_getDesiredInventoryPageClass(enabled)
    -- Resolve the class table that should back new inventory / loot windows.
    if enabled then
        return _G.CleanUI_Clean_ISInventoryPage
    end
    return _G.CleanUI_Vanilla_ISInventoryPage
end

local function CleanUI_applyInventoryMode(enabled)
    -- Swap the global classes used by the inventory / loot windows.
    if not CleanUI_storeEnhancedClasses() then
        return false
    end
    if not CleanUI_loadVanillaClasses() then
        return false
    end

    if enabled then
        ISInventoryPage = _G.CleanUI_Clean_ISInventoryPage
        ISInventoryPane = _G.CleanUI_Clean_ISInventoryPane
        ISInventoryWindowContainerControls = _G.CleanUI_Clean_ISInventoryWindowContainerControls
        ISLootWindowContainerControls = _G.CleanUI_Clean_ISLootWindowContainerControls
        CleanUI_uiSwitcherDebug("Applied enhanced inventory UI classes")
    else
        ISInventoryPage = _G.CleanUI_Vanilla_ISInventoryPage
        ISInventoryPane = _G.CleanUI_Vanilla_ISInventoryPane
        ISInventoryWindowContainerControls = _G.CleanUI_Vanilla_ISInventoryWindowContainerControls
        ISLootWindowContainerControls = _G.CleanUI_Vanilla_ISLootWindowContainerControls
        CleanUI_uiSwitcherDebug("Applied vanilla inventory UI classes")
    end

    return true
end

local function CleanUI_captureInventoryWindowState(page, playerNum)
    -- Capture the minimum runtime state needed to recreate one page.
    if not page then
        return nil
    end

    local visible = true
    if page.getIsVisible then
        visible = page:getIsVisible()
    elseif page.isVisible then
        visible = page:isVisible()
    end

    local state = {
        x = page:getX(),
        y = page:getY(),
        width = page:getWidth(),
        height = page:getHeight(),
        inventory = page.inventory,
        onCharacter = page.onCharacter == true,
        zoom = page.zoom,
        visible = visible,
        pin = page.pin == true,
        isCollapsed = page.isCollapsed == true,
        maxDrawHeight = page.maxDrawHeight,
        player = playerNum,
        info = page.info,
        controller = page.getController and page:getController() or nil,
    }

    return state
end

local function CleanUI_removeInventoryWindow(page)
    -- Cleanly remove one inventory window before rebuilding it.
    if not page then
        return
    end

    pcall(function()
        page:setVisible(false)
    end)

    pcall(function()
        page:removeFromUIManager()
    end)
end

local function CleanUI_restoreCollapsedState(page, state)
    -- Reapply pin / collapsed state after a page is recreated.
    if not page or not state then
        return
    end

    if state.pin ~= nil and page.pin ~= state.pin and page.setPinned then
        page:setPinned()
    end

    if state.isCollapsed ~= nil and page.isCollapsed ~= state.isCollapsed and page.collapse then
        page:collapse()
    end

    if state.maxDrawHeight and page.setMaxDrawHeight and page.isCollapsed == true then
        page:setMaxDrawHeight(state.maxDrawHeight)
    end
end

local function CleanUI_restoreVanillaResizeWidgets(page)
    -- When switching back to the vanilla inventory UI, make sure the vanilla
    -- resize widgets are visible and on top. CleanUI pages can hide their
    -- compact resize widget when locked, but vanilla pages should always keep
    -- the normal resize handles available.
    if not page then
        return
    end

    if page.resizeWidget then
        page.resizeWidget.target = page
        page.resizeWidget.resizing = false
        if page.resizeWidget.setCapture then page.resizeWidget:setCapture(false) end
        if page.resizeWidget.setVisible then page.resizeWidget:setVisible(true) end
        if page.resizeWidget.bringToTop then page.resizeWidget:bringToTop() end
    end

    if page.resizeWidget2 then
        page.resizeWidget2.target = page
        page.resizeWidget2.resizing = false
        if page.resizeWidget2.setCapture then page.resizeWidget2:setCapture(false) end
        if page.resizeWidget2.setVisible then page.resizeWidget2:setVisible(true) end
        if page.resizeWidget2.bringToTop then page.resizeWidget2:bringToTop() end
    end
end

local function CleanUI_buildInventoryWindow(state)
    -- Recreate one inventory / loot window using the currently active class.
    if not state then
        return nil
    end

    local page = ISInventoryPage:new(state.x, state.y, state.width, state.height, state.inventory, state.onCharacter, state.zoom)
    page.player = state.player
    page:initialise()
    page:setUIName((state.onCharacter and "inventory" or "loot") .. tostring(state.player))
    page:addToUIManager()

    if state.controller ~= nil and page.setController then
        page:setController(state.controller)
    end

    if page.setInfo then
        page:setInfo(state.info or (state.onCharacter and getText("UI_InventoryInfo") or getText("UI_LootInfo")))
    end

    if page.setX then page:setX(state.x) end
    if page.setY then page:setY(state.y) end
    if page.setWidth then page:setWidth(state.width) end
    if page.setHeight then page:setHeight(state.height) end

    CleanUI_restoreCollapsedState(page, state)

    if state.visible ~= nil then
        page:setVisible(state.visible)
    end

    return page
end

local function CleanUI_pageMatchesMode(page, enabled)
    -- Check whether an existing page already uses the desired class table.
    if not page then
        return true
    end

    local desired = CleanUI_getDesiredInventoryPageClass(enabled)
    local meta = getmetatable(page)
    return meta == desired
end

local function CleanUI_refreshPlayerInventoryWindows(playerNum)
    -- Rebuild the two main inventory windows for a player using the active mode.
    local playerObj = getSpecificPlayer(playerNum)
    local pdata = getPlayerData(playerNum)
    if not playerObj or not pdata then
        return
    end

    local playerState = CleanUI_captureInventoryWindowState(pdata.playerInventory, playerNum)
    local lootState = CleanUI_captureInventoryWindowState(pdata.lootInventory, playerNum)

    if not playerState then
        local zoom = 1.34
        playerState = {
            x = 0,
            y = 0,
            width = 260,
            height = 120,
            inventory = playerObj:getInventory(),
            onCharacter = true,
            zoom = zoom,
            visible = true,
            pin = false,
            isCollapsed = false,
            player = playerNum,
            info = getText("UI_InventoryInfo"),
            controller = playerObj:getJoypadBind(),
        }
    else
        playerState.inventory = playerObj:getInventory()
    end

    if not lootState then
        lootState = {
            x = playerState.x + playerState.width + 2,
            y = playerState.y,
            width = 260,
            height = 120,
            inventory = nil,
            onCharacter = false,
            zoom = playerState.zoom,
            visible = playerState.visible,
            pin = false,
            isCollapsed = false,
            player = playerNum,
            info = getText("UI_LootInfo"),
            controller = playerObj:getJoypadBind(),
        }
    end

    -- Rebuilds triggered from the Mod Options screen can capture the pages as
    -- hidden. With mouse/keyboard, keep the old recovery behavior so the player
    -- does not lose access after applying the toggle. With controller, preserve
    -- vanilla startup/focus behavior and do not force the panels open.
    if not CleanUI_playerUsesController(playerNum) then
        playerState.visible = true
        lootState.visible = true
    end

    CleanUI_removeInventoryWindow(pdata.playerInventory)
    CleanUI_removeInventoryWindow(pdata.lootInventory)

    pdata.playerInventory = CleanUI_buildInventoryWindow(playerState)
    pdata.lootInventory = CleanUI_buildInventoryWindow(lootState)

    if type(CleanUI_isCleanInventoryUIEnabled) == "function" and not CleanUI_isCleanInventoryUIEnabled() then
        CleanUI_restoreVanillaResizeWidgets(pdata.playerInventory)
        CleanUI_restoreVanillaResizeWidgets(pdata.lootInventory)
    end

    if pdata.playerInventory and pdata.lootInventory then
        UIManager.setPlayerInventory(playerNum, pdata.playerInventory.javaObject, pdata.lootInventory.javaObject)
        if pdata.playerInventory.refreshBackpacks then pdata.playerInventory:refreshBackpacks() end
        if pdata.lootInventory.refreshBackpacks then pdata.lootInventory:refreshBackpacks() end
    end

    -- The sidebar inventory button keeps direct references to the active
    -- inventory and loot windows. Rebind them after recreating the pages so
    -- right-click / left-click actions keep working after a live UI mode swap.
    local equipped = ISEquippedItem and ISEquippedItem.instance
    if equipped and equipped.chr and equipped.chr:getPlayerNum() == playerNum then
        equipped.inventory = pdata.playerInventory
        equipped.loot = pdata.lootInventory
    end
end

local function CleanUI_refreshAllInventoryWindows(enabled)
    -- Rebuild only when the current pages do not match the active mode.
    for playerNum = 0, getNumActivePlayers() - 1 do
        local pdata = getPlayerData(playerNum)
        if pdata then
            local needsRefresh = not CleanUI_pageMatchesMode(pdata.playerInventory, enabled)
                or not CleanUI_pageMatchesMode(pdata.lootInventory, enabled)
            if needsRefresh then
                CleanUI_refreshPlayerInventoryWindows(playerNum)
            end
        end
    end
end

local function CleanUI_tryRegisterInventoryModeCallback()
    -- Register the live runtime switch only once.
    if _G.CleanUI_InventoryUIModeSwitcherRegistered then
        return true
    end

    if type(CleanUI_RegisterInventoryUiToggleCallback) ~= "function"
        or type(CleanUI_isCleanInventoryUIEnabled) ~= "function" then
        return false
    end

    _G.CleanUI_InventoryUIModeSwitcherRegistered = true

    CleanUI_RegisterInventoryUiToggleCallback(function(enabled)
        if not CleanUI_applyInventoryMode(enabled == true) then
            return
        end

        CleanUI_refreshAllInventoryWindows(enabled == true)
        _G.CleanUI_LastInventoryUIMode = enabled == true
    end)

    return true
end



local function CleanUI_installInitialVisibilityRecovery()
    -- Some saves can reopen with both inventory windows hidden even though
    -- CleanUI was active and the player left them visible. Recover once after
    -- the UI is ready, but only when both pages are hidden.
    if _G.CleanUI_InitialInventoryVisibilityRecoveryInstalled then
        return
    end
    _G.CleanUI_InitialInventoryVisibilityRecoveryInstalled = true

    local ticksRemaining = 20
    local function tickFn()
        ticksRemaining = ticksRemaining - 1
        if ticksRemaining < 0 then
            Events.OnTick.Remove(tickFn)
            return
        end

        if type(CleanUI_isCleanInventoryUIEnabled) ~= "function" or not CleanUI_isCleanInventoryUIEnabled() then
            Events.OnTick.Remove(tickFn)
            return
        end

        for playerNum = 0, getNumActivePlayers() - 1 do
            local pdata = getPlayerData(playerNum)
            if pdata and pdata.playerInventory and pdata.lootInventory then
                -- Do not auto-open panels for controller users. Vanilla keeps
                -- inventory/loot closed on load until controller focus opens them.
                if not CleanUI_playerUsesController(playerNum) then
                    local playerVisible = pdata.playerInventory.getIsVisible and pdata.playerInventory:getIsVisible() or pdata.playerInventory.visible == true
                    local lootVisible = pdata.lootInventory.getIsVisible and pdata.lootInventory:getIsVisible() or pdata.lootInventory.visible == true
                    if not playerVisible and not lootVisible then
                        pcall(function() pdata.playerInventory:setVisible(true) end)
                        pcall(function() pdata.lootInventory:setVisible(true) end)
                        local equipped = ISEquippedItem and ISEquippedItem.instance
                        if equipped and equipped.chr and equipped.chr:getPlayerNum() == playerNum then
                            equipped.inventory = pdata.playerInventory
                            equipped.loot = pdata.lootInventory
                        end
                    end
                end
            end
        end

        Events.OnTick.Remove(tickFn)
    end

    Events.OnTick.Add(tickFn)
end


local function CleanUI_bootstrapInventoryModeSwitcher()
    -- Wait until the classes and ModOptions helpers exist, then install the switcher.
    if _G.CleanUI_InventoryUIModeSwitcherBootstrapRunning then
        return
    end
    _G.CleanUI_InventoryUIModeSwitcherBootstrapRunning = true

    local function tickFn()
        local classesReady = ISInventoryPage and ISInventoryPane and ISInventoryWindowContainerControls and ISLootWindowContainerControls
        if not classesReady then
            return
        end

        if not CleanUI_storeEnhancedClasses() then
            return
        end

        if not CleanUI_loadVanillaClasses() then
            return
        end

        if not CleanUI_tryRegisterInventoryModeCallback() then
            return
        end

        Events.OnTick.Remove(tickFn)
        _G.CleanUI_InventoryUIModeSwitcherBootstrapRunning = false
    end

    Events.OnTick.Add(tickFn)
end

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(CleanUI_bootstrapInventoryModeSwitcher)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(CleanUI_bootstrapInventoryModeSwitcher)
    Events.OnGameStart.Add(CleanUI_installInitialVisibilityRecovery)
end

if Events and Events.OnTick then
    CleanUI_bootstrapInventoryModeSwitcher()
end
