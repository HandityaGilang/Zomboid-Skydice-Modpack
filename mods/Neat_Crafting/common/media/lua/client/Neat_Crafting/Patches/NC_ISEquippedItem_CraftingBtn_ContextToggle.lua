-- NC_ISEquippedItem_CraftingBtn_ContextToggle.lua
-- Adds a right-click context-menu entry on the vanilla crafting sidebar button (ISEquippedItem.craftingBtn)
-- to toggle Neat Crafting UI on/off via PZAPI ModOptions.
--
-- Debugging notes:
--  * This file includes optional debug prints.
--  * Avoid using ':' in the printed strings because some log viewers truncate messages containing ':'
--
-- Behavior:
--  * Left-click behavior is untouched (still opens/closes the crafting window as vanilla).
--  * Right-click opens an ISContextMenu at the mouse cursor.
--  * The menu entry shows a checkmark when enabled.
--  * Toggling applies immediately by calling the same callbacks used by the ModOptions tickbox.

------------------------------------------------------------
-- Configuration
------------------------------------------------------------

local MOD_ID = "Neat_Crafting_Beta"
local OPT_ID = "useNeatCraftingUI"

-- Debug can be controlled by defining a global before this file loads:
--   NC_DEBUG_CRAFTBTN_CTX = true
-- If not defined, defaults to false (quiet by default).
local DEBUG = false
if rawget(_G, "NC_DEBUG_CRAFTBTN_CTX") ~= nil then
    DEBUG = _G.NC_DEBUG_CRAFTBTN_CTX == true
end

local function nc_dbg(msg)
    -- Print a debug line when DEBUG is enabled.
    if not DEBUG then return end
    -- Avoid ':' in the message string.
    print("[NC] " .. tostring(msg))
end

nc_dbg("CraftBtn context toggle file loaded")

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function nc_to_bool(v)
    -- Convert ModOptions values to boolean.
    -- Accept true/false, "true"/"false", 1/0, "1"/"0".
    return v == true or v == 1 or v == "1" or v == "true"
end

local function nc_get_option()
    -- Fetch the ModOptions option object; return nil if ModOptions isn't available.
    if not (PZAPI and PZAPI.ModOptions) then
        nc_dbg("ModOptions missing PZAPI")
        return nil
    end
    local opts = PZAPI.ModOptions:getOptions(MOD_ID)
    if not opts then
        nc_dbg("ModOptions missing options object")
        return nil
    end
    local opt = opts:getOption(OPT_ID)
    if not opt then
        nc_dbg("ModOptions missing option object")
        return nil
    end
    return opt
end

local function nc_is_enabled()
    -- Prefer the helper provided by NC_ModOptions.lua if it exists.
    if type(NC_isNeatCraftingUIEnabled) == "function" then
        return NC_isNeatCraftingUIEnabled() == true
    end

    local opt = nc_get_option()
    if not opt or type(opt.getValue) ~= "function" then
        return true -- default ON
    end

    local ok, v = pcall(function() return opt:getValue() end)
    if not ok then
        nc_dbg("Option getValue failed")
        return true
    end
    return nc_to_bool(v)
end

local function nc_call_toggle_callbacks(enabled)
    -- NC_ModOptions.lua keeps callbacks in the global NC_UI_TOGGLE_CALLBACKS table.
    if NC_UI_TOGGLE_CALLBACKS and type(NC_UI_TOGGLE_CALLBACKS) == "table" then
        nc_dbg("Calling toggle callbacks")
        for i, cb in ipairs(NC_UI_TOGGLE_CALLBACKS) do
            if type(cb) == "function" then
                local ok = pcall(function() cb(enabled) end)
                if not ok then
                    nc_dbg("Callback failed index " .. tostring(i))
                end
            end
        end
    else
        nc_dbg("No toggle callbacks table")
    end
end

local function nc_set_enabled(enabled)
    -- Set the ModOptions value and apply the change immediately.
    local opt = nc_get_option()

    -- Ensure ModOptions.ini is loaded at least once.
    if PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.load) == "function" then
        pcall(function() PZAPI.ModOptions:load() end)
    end

    if opt and type(opt.setValue) == "function" then
        nc_dbg("Setting option value")
        pcall(function() opt:setValue(enabled) end)
    else
        nc_dbg("Cannot set option value")
    end

    -- Persist immediately when possible.
    if PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.save) == "function" then
        pcall(function() PZAPI.ModOptions:save() end)
    end

    -- Apply in-game without opening the Options screen.
    nc_call_toggle_callbacks(enabled)
end

------------------------------------------------------------
-- Context menu
------------------------------------------------------------

local function nc_toggle_from_menu()
    -- Toggle when clicking the context-menu entry.
    local before = nc_is_enabled()
    local after = not before
    nc_dbg("Menu toggle clicked")
    nc_dbg("Toggle before " .. tostring(before) .. " after " .. tostring(after))
    nc_set_enabled(after)
end

local function nc_show_context_menu(panel)
    -- Build and show the context menu at the mouse cursor.
    nc_dbg("Show context menu called")

    if not panel then
        nc_dbg("Panel missing")
        return true
    end

    local playerObj = panel.chr
    if not playerObj then
        nc_dbg("Panel chr missing")
        return true
    end

    if not (ISContextMenu and ISContextMenu.get) then
        nc_dbg("ISContextMenu missing")
        return true
    end

    local playerNum = playerObj:getPlayerNum()
    local x = getMouseX()
    local y = getMouseY()

    nc_dbg("Mouse x " .. tostring(x) .. " y " .. tostring(y) .. " player " .. tostring(playerNum))

    local context = ISContextMenu.get(playerNum, x, y)
    if not context then
        nc_dbg("Context menu get returned nil")
        return true
    end

    local enabled = nc_is_enabled()
    local label = getText("IGUI_NC_ModOptions_UseNeatCraftingUI")
    local option = context:addOption(label, nil, nc_toggle_from_menu)

    nc_dbg("Context option added enabled " .. tostring(enabled))

    if context.setOptionChecked then
        context:setOptionChecked(option, enabled)
    else
        nc_dbg("Context menu has no setOptionChecked")
    end

    return true
end

------------------------------------------------------------
-- Hooking the crafting button
------------------------------------------------------------

local function nc_attach_right_click_handlers(target, panel, label)
    -- Attach Neat Crafting's RMB context menu to one UI element without depending on mod load order.
    if not target or not panel then
        return false
    end

    if target._NC_RightClickHooked and target._NC_RightClickPanel == panel then
        return true
    end

    -- Preserve any existing RMB callbacks so another mod can still observe the event.
    local previousRightMouseDown = target.onRightMouseDown
    local previousRightMouseUp = target.onRightMouseUp
    local previousRightMouseUpOutside = target.onRightMouseUpOutside

    target._NC_RightClickHooked = true
    target._NC_RightClickPanel = panel

    nc_dbg("Attaching right click handlers to " .. tostring(label))

    target.onRightMouseDown = function(_self, _x, _y)
        -- Let an earlier handler run first, then consume the event for the context menu.
        if previousRightMouseDown then
            pcall(function() previousRightMouseDown(_self, _x, _y) end)
        end
        nc_dbg(tostring(label) .. " right down")
        return true
    end

    target.onRightMouseUp = function(_self, _x, _y)
        -- Let an earlier handler run first, then open the Neat Crafting toggle menu.
        if previousRightMouseUp then
            pcall(function() previousRightMouseUp(_self, _x, _y) end)
        end
        nc_dbg(tostring(label) .. " right up")
        return nc_show_context_menu(panel)
    end

    target.onRightMouseUpOutside = function(_self, _x, _y)
        -- Preserve the previous outside callback when present, but do not consume outside clicks here.
        if previousRightMouseUpOutside then
            pcall(function() previousRightMouseUpOutside(_self, _x, _y) end)
        end
        nc_dbg(tostring(label) .. " right up outside")
        return false
    end

    return true
end

local function nc_attach_to_crafting_btn(panel)
    -- Attach right-click handlers to the vanilla crafting button and any overlay currently owned by it.
    if not panel then
        return false, false
    end

    local btnHooked = false
    local popupHooked = false

    if panel.craftingBtn then
        btnHooked = nc_attach_right_click_handlers(panel.craftingBtn, panel, "craftingBtn")
    else
        nc_dbg("Attach skipped craftingBtn missing")
    end

    -- Project Cook adds craftingPopup later, during prerender, so this function is called repeatedly.
    if panel.craftingPopup then
        popupHooked = nc_attach_right_click_handlers(panel.craftingPopup, panel, "craftingPopup")
    end

    return btnHooked, popupHooked
end

local function nc_patch_isequippeditem_methods()
    -- Wrap ISEquippedItem only after game start. Re-wrap if another mod replaces the method later.
    if not ISEquippedItem then
        return false
    end

    if ISEquippedItem._NC_CraftBtnCtxInitWrapper ~= ISEquippedItem.initialise then
        local oldInitialise = ISEquippedItem.initialise

        nc_dbg("Wrapping ISEquippedItem initialise")

        local initWrapper = function(self, ...)
            -- Call the previous initialise first so vanilla and other mods can create their widgets.
            if oldInitialise then
                oldInitialise(self, ...)
            end

            -- Hook the crafting button after it is created.
            nc_attach_to_crafting_btn(self)
        end

        ISEquippedItem.initialise = initWrapper
        ISEquippedItem._NC_CraftBtnCtxInitWrapper = initWrapper
    end

    if ISEquippedItem._NC_CraftBtnCtxPrerenderWrapper ~= ISEquippedItem.prerender then
        local oldPrerender = ISEquippedItem.prerender

        nc_dbg("Wrapping ISEquippedItem prerender")

        local prerenderWrapper = function(self, ...)
            -- Call the previous prerender first so Project Cook can create/update craftingPopup.
            if oldPrerender then
                oldPrerender(self, ...)
            end

            -- Re-check every frame because Project Cook's overlay can appear after initialise.
            nc_attach_to_crafting_btn(self)
        end

        ISEquippedItem.prerender = prerenderWrapper
        ISEquippedItem._NC_CraftBtnCtxPrerenderWrapper = prerenderWrapper
    end

    return true
end

local function nc_try_hook_existing_instance()
    -- Fallback hook in case the current sidebar instance already exists.
    if not ISEquippedItem then return false, false end

    if ISEquippedItem.instance and type(ISEquippedItem.instance) == "table" then
        return nc_attach_to_crafting_btn(ISEquippedItem.instance)
    end

    return false, false
end

------------------------------------------------------------
-- Bootstrap
------------------------------------------------------------

local function nc_bootstrap()
    -- Start after OnGameStart to avoid touching ISEquippedItem during early Linux MP UI boot.
    if _G.NC_CraftBtnCtxBootstrapRunning then
        return
    end
    if not (Events and Events.OnTick) then
        nc_dbg("OnTick missing cannot bootstrap")
        return
    end

    _G.NC_CraftBtnCtxBootstrapRunning = true

    nc_dbg("Bootstrap start")

    local warnedMissing = false
    local stableTicks = 0
    local STABLE_TICKS_BEFORE_STOP = 120

    local function tickFn()
        if not ISEquippedItem then
            if not warnedMissing then
                warnedMissing = true
                nc_dbg("Tick waiting for ISEquippedItem")
            end
            return
        end

        -- Ensure initialise and prerender remain wrapped even if another mod patches after us.
        nc_patch_isequippeditem_methods()

        -- Also hook an already-created panel instance, if any.
        local btnHooked = false
        local popupHooked = false
        btnHooked, popupHooked = nc_try_hook_existing_instance()

        -- Keep ticking briefly after success so delayed overlays such as Project Cook's craftingPopup are caught.
        local inst = ISEquippedItem.instance
        local popupOk = (not inst) or (not inst.craftingPopup) or popupHooked
        if btnHooked and popupOk then
            stableTicks = stableTicks + 1
        else
            stableTicks = 0
        end

        if stableTicks >= STABLE_TICKS_BEFORE_STOP then
            nc_dbg("Tick done crafting hooks stable")
            Events.OnTick.Remove(tickFn)
            _G.NC_CraftBtnCtxBootstrapRunning = false
        end
    end

    Events.OnTick.Add(tickFn)
end

-- Delay the bootstrap until game start. This avoids the early UI initialisation issue seen on Linux MP clients.
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        nc_dbg("OnGameStart event")
        nc_bootstrap()
    end)
elseif Events and Events.OnTick then
    -- Fallback only for environments without OnGameStart.
    nc_dbg("OnGameStart missing bootstrap now")
    nc_bootstrap()
end
