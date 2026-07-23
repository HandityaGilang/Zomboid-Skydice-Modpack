-- CleanUI_ISEquippedItem_InventoryBtn_ContextToggle.lua
-- Adds a right-click context-menu entry to ISEquippedItem.invBtn so players can
-- switch between the CleanUI and vanilla inventory / loot windows at runtime.

local function CleanUI_showInventoryModeContextMenu(panel)
    -- Build and show the context menu at the mouse cursor.
    if not panel or not panel.chr then
        return true
    end

    if not (ISContextMenu and ISContextMenu.get) then
        return true
    end

    local playerNum = panel.chr:getPlayerNum()
    local context = ISContextMenu.get(playerNum, getMouseX(), getMouseY())
    if not context then
        return true
    end

    local enabled = true
    if type(CleanUI_isCleanInventoryUIEnabled) == "function" then
        enabled = CleanUI_isCleanInventoryUIEnabled() == true
    end

    local option = context:addOption(getText("UI_CleanUI_UseCleanUIInventory"), nil, function()
        if type(CleanUI_setCleanInventoryUIEnabled) == "function" then
            CleanUI_setCleanInventoryUIEnabled(not enabled)
        end
    end)

    if context.setOptionChecked then
        context:setOptionChecked(option, enabled)
    end

    return true
end

local function CleanUI_attachInventoryButtonContext(panel)
    -- Attach right-click handlers to the inventory sidebar button of one panel instance.
    if not panel then
        return
    end

    local button = panel.invBtn
    if not button or button._CleanUI_InventoryModeCtxHooked then
        return
    end

    button._CleanUI_InventoryModeCtxHooked = true

    button.onRightMouseDown = function(_self, _x, _y)
        return true
    end

    button.onRightMouseUp = function(_self, _x, _y)
        return CleanUI_showInventoryModeContextMenu(panel)
    end

    button.onRightMouseUpOutside = function(_self, _x, _y)
        return false
    end
end

local function CleanUI_patchISEquippedItemInitialise()
    -- Wrap initialise so future instances always receive the right-click hook.
    if not ISEquippedItem or ISEquippedItem._CleanUI_InventoryModeInitWrapped then
        return
    end

    ISEquippedItem._CleanUI_InventoryModeInitWrapped = true
    local originalInitialise = ISEquippedItem.initialise

    function ISEquippedItem:initialise(...)
        if originalInitialise then
            originalInitialise(self, ...)
        end
        CleanUI_attachInventoryButtonContext(self)
    end
end

local function CleanUI_tryHookExistingEquippedPanel()
    -- Attach the hook to an already-created equipped panel when possible.
    if ISEquippedItem and ISEquippedItem.instance then
        CleanUI_attachInventoryButtonContext(ISEquippedItem.instance)
    end
end

local function CleanUI_bootstrapInventoryButtonContextToggle()
    -- Retry until ISEquippedItem exists, to survive different load orders.
    if _G.CleanUI_InventoryModeCtxBootstrapRunning then
        return
    end
    _G.CleanUI_InventoryModeCtxBootstrapRunning = true

    local function tickFn()
        if not ISEquippedItem then
            return
        end

        CleanUI_patchISEquippedItemInitialise()
        CleanUI_tryHookExistingEquippedPanel()

        local instance = ISEquippedItem.instance
        if instance and instance.invBtn and instance.invBtn._CleanUI_InventoryModeCtxHooked then
            Events.OnTick.Remove(tickFn)
            _G.CleanUI_InventoryModeCtxBootstrapRunning = false
        end
    end

    Events.OnTick.Add(tickFn)
end

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(CleanUI_bootstrapInventoryButtonContextToggle)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(CleanUI_bootstrapInventoryButtonContextToggle)
end

if Events and Events.OnTick then
    CleanUI_bootstrapInventoryButtonContextToggle()
end
