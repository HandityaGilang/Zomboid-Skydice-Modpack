-- NB_ISEquippedItem_BuildBtn_ContextToggle.lua
-- Adds a right-click context-menu entry on the vanilla building sidebar button (ISEquippedItem.buildBtn)
-- to toggle Neat Building UI on/off via PZAPI ModOptions.
--
-- Behavior:
--  * Left-click behavior is untouched (still opens/closes the building window as vanilla).
--  * Right-click opens an ISContextMenu at the mouse cursor.
--  * The menu entry shows a checkmark when enabled.
--  * Toggling applies immediately by calling the same callbacks used by the ModOptions tickbox.

------------------------------------------------------------
-- Configuration
------------------------------------------------------------

local MOD_ID = "Neat_Building"
local OPT_ID = "NB_useNeatBuildingUI"

-- Optional debug (disabled by default).
-- Enable by defining a global before this file loads:
--   NB_DEBUG_BUILDBTN_CTX = true
local DEBUG = false
if rawget(_G, "NB_DEBUG_BUILDBTN_CTX") ~= nil then
    DEBUG = _G.NB_DEBUG_BUILDBTN_CTX == true
end

local function nb_dbg(msg)
    -- Print a debug line when DEBUG is enabled.
    if not DEBUG then return end
    -- Avoid ':' in the message string.
    print("[NB] " .. tostring(msg))
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function nb_to_bool(v)
    -- Convert ModOptions values to boolean.
    -- Accept true/false, "true"/"false", 1/0, "1"/"0".
    return v == true or v == 1 or v == "1" or v == "true"
end

local function nb_get_option()
    -- Fetch the ModOptions option object; return nil if ModOptions isn't available.
    if not (PZAPI and PZAPI.ModOptions) then
        nb_dbg("ModOptions missing PZAPI")
        return nil
    end
    local opts = PZAPI.ModOptions:getOptions(MOD_ID)
    if not opts then
        nb_dbg("ModOptions missing options object")
        return nil
    end
    local opt = opts:getOption(OPT_ID)
    if not opt then
        nb_dbg("ModOptions missing option object")
        return nil
    end
    return opt
end

local function nb_is_enabled()
    -- Prefer the helper provided by NB_ModOptions.lua if it exists.
    if type(NB_isNeatBuildingUIEnabled) == "function" then
        return NB_isNeatBuildingUIEnabled() == true
    end

    local opt = nb_get_option()
    if not opt or type(opt.getValue) ~= "function" then
        return true -- default ON
    end

    local ok, v = pcall(function() return opt:getValue() end)
    if not ok then
        nb_dbg("Option getValue failed")
        return true
    end
    return nb_to_bool(v)
end

local function nb_call_toggle_callbacks(enabled)
    -- NB_ModOptions.lua keeps callbacks in the global NB_UI_TOGGLE_CALLBACKS table.
    if NB_UI_TOGGLE_CALLBACKS and type(NB_UI_TOGGLE_CALLBACKS) == "table" then
        for _, cb in ipairs(NB_UI_TOGGLE_CALLBACKS) do
            if type(cb) == "function" then
                pcall(function() cb(enabled) end)
            end
        end
    end
end

local function nb_set_enabled(enabled)
    -- Set the ModOptions value and apply the change immediately.
    local opt = nb_get_option()

    -- Ensure ModOptions.ini is loaded at least once.
    if PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.load) == "function" then
        pcall(function() PZAPI.ModOptions:load() end)
    end

    if opt and type(opt.setValue) == "function" then
        pcall(function() opt:setValue(enabled) end)
    end

    -- Persist immediately when possible.
    if PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.save) == "function" then
        pcall(function() PZAPI.ModOptions:save() end)
    end

    -- Apply in-game without opening the Options screen.
    nb_call_toggle_callbacks(enabled)
end

------------------------------------------------------------
-- Context menu
------------------------------------------------------------

local function nb_toggle_from_menu()
    -- Toggle when clicking the context-menu entry.
    local before = nb_is_enabled()
    local after = not before
    nb_set_enabled(after)
end

local function nb_show_context_menu(panel)
    -- Build and show the context menu at the mouse cursor.
    if not panel then
        return true
    end

    local playerObj = panel.chr
    if not playerObj then
        return true
    end

    if not (ISContextMenu and ISContextMenu.get) then
        return true
    end

    local playerNum = playerObj:getPlayerNum()
    local x = getMouseX()
    local y = getMouseY()

    local context = ISContextMenu.get(playerNum, x, y)
    if not context then
        return true
    end

    local enabled = nb_is_enabled()
    local label = getText("IGUI_NB_ModOptions_UseNeatBuildingUI")
    local option = context:addOption(label, nil, nb_toggle_from_menu)

    if context.setOptionChecked then
        context:setOptionChecked(option, enabled)
    end

    return true
end

------------------------------------------------------------
-- Hooking the building button
------------------------------------------------------------

local function nb_attach_to_build_btn(panel)
    -- Attach right-click handlers to the building button of a specific ISEquippedItem instance.
    if not panel then return end

    local btn = panel.buildBtn
    if not btn then
        return
    end

    if btn._NB_RightClickHooked then
        return
    end
    btn._NB_RightClickHooked = true

    -- Consume right-mouse-down so UIElement will treat it as handled.
    btn.onRightMouseDown = function(_self, _x, _y)
        return true
    end

    -- Open the menu on right-mouse-up.
    btn.onRightMouseUp = function(_self, _x, _y)
        return nb_show_context_menu(panel)
    end
end

local function nb_patch_isequippeditem_initialise()
    -- Wrap ISEquippedItem:initialise so every time the panel is initialized we hook the button.
    if not ISEquippedItem then
        return false
    end

    if ISEquippedItem._NB_BuildBtnCtxInitWrapped then
        return true
    end

    ISEquippedItem._NB_BuildBtnCtxInitWrapped = true

    local oldInitialise = ISEquippedItem.initialise

    function ISEquippedItem:initialise(...)
        -- Call the original initialise first.
        if oldInitialise then
            oldInitialise(self, ...)
        end

        -- Hook the build button after it is created.
        nb_attach_to_build_btn(self)
    end

    return true
end

local function nb_try_hook_existing_instance()
    -- Fallback hook in case another mod overwrites initialise or load order changes.
    if not ISEquippedItem then return end

    if ISEquippedItem.instance and type(ISEquippedItem.instance) == "table" then
        nb_attach_to_build_btn(ISEquippedItem.instance)
    end
end

------------------------------------------------------------
-- Bootstrap
------------------------------------------------------------

local function nb_bootstrap()
    -- Try to patch immediately, and keep retrying until ISEquippedItem exists.
    if _G.NB_BuildBtnCtxBootstrapRunning then
        return
    end
    _G.NB_BuildBtnCtxBootstrapRunning = true

    local function tickFn()
        if not ISEquippedItem then
            return
        end

        -- Ensure initialise is wrapped.
        nb_patch_isequippeditem_initialise()

        -- Also hook an already-created panel instance, if any.
        nb_try_hook_existing_instance()

        -- Once we see the button hooked at least once, we can stop ticking.
        local inst = ISEquippedItem.instance
        if inst and inst.buildBtn and inst.buildBtn._NB_RightClickHooked then
            Events.OnTick.Remove(tickFn)
            _G.NB_BuildBtnCtxBootstrapRunning = false
        end
    end

    Events.OnTick.Add(tickFn)
end

-- Run bootstrap in several phases to survive different load orders.
if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(function()
        nb_bootstrap()
    end)
else
    -- If OnGameBoot isn't available, bootstrap right away.
    if Events and Events.OnTick then
        nb_bootstrap()
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        nb_bootstrap()
    end)
end

-- As a last resort, start once at file load too.
if Events and Events.OnTick then
    nb_bootstrap()
end
