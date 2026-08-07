-- NB_ModOptions.lua
-- Project Zomboid (B42) – Options panel for Neat Building UI

-----------------------------------------
-- Constants
-----------------------------------------
local MOD_ID    = "Neat_Building"         -- Unique ID for this ModOptions section
local MOD_TITLE = "Neat Building"  -- Section title shown in the options menu

-----------------------------------------
-- Internal state + callback registry
-----------------------------------------
NB_UI_TOGGLE_CALLBACKS = NB_UI_TOGGLE_CALLBACKS or {}

-- Internal flag: ensure we load ModOptions.ini at least once so saved values apply in-game.
NB_MODOPTIONS_LOADED = NB_MODOPTIONS_LOADED or false


local function _nb_to_bool(v)
    -- Accept true/false, "true"/"false", 1/0, "1"/"0"
    return v == true or v == 1 or v == "1" or v == "true"
end

function NB_isNeatBuildingUIEnabled()
    -- Default = enabled.
    -- Important: ModOptions.ini is only loaded by vanilla when opening the Options screen.
    -- We load it once ourselves so the saved value applies immediately at game start.
    if not NB_MODOPTIONS_LOADED and PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.load) == "function" then
        pcall(function() PZAPI.ModOptions:load() end)
        NB_MODOPTIONS_LOADED = true
    end

    local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions(MOD_ID)
    local o = opts and opts:getOption("NB_useNeatBuildingUI")
    if not o then return true end
    return _nb_to_bool(o:getValue())
end

function NB_RegisterUiToggleCallback(cb)
    -- Register a callback that receives (enabled:boolean)
    if type(cb) ~= "function" then return end
    table.insert(NB_UI_TOGGLE_CALLBACKS, cb)
    -- Apply immediately using current option value
    pcall(function() cb(NB_isNeatBuildingUIEnabled()) end)
end

local function _nb_call_toggle_callbacks(enabled)
    for _,cb in ipairs(NB_UI_TOGGLE_CALLBACKS) do
        pcall(function() cb(enabled) end)
    end
end

-----------------------------------------
-- Register options into the main menu
-----------------------------------------
local function NB_ModOptions()
    if not (PZAPI and PZAPI.ModOptions) then return end

    local options = PZAPI.ModOptions:create(MOD_ID, MOD_TITLE)

    -- Enable Neat Building UI (tickbox)
    options:addTickBox(
        "NB_useNeatBuildingUI",
        "IGUI_NB_ModOptions_UseNeatBuildingUI",
        true,
        "IGUI_NB_ModOptions_UseNeatBuildingUI_Tooltip"
    )

    -- Load saved values now so the toggle works without opening the Options screen.
    if type(PZAPI.ModOptions.load) == "function" then
        pcall(function() PZAPI.ModOptions:load() end)
        NB_MODOPTIONS_LOADED = true
    end

    -- Apply changes live when the user toggles the option in the Options menu
    local opt = options:getOption("NB_useNeatBuildingUI")
    if opt then
        -- Called immediately when the user changes the value in the Options menu.
        opt.onChange = function(self, selected)
            _nb_call_toggle_callbacks(_nb_to_bool(selected))
        end

        -- Called when pressing Apply in the Options menu.
        opt.onChangeApply = function(self, selected)
            _nb_call_toggle_callbacks(_nb_to_bool(selected))
        end
    end

    -- Apply current state once options exist (covers early-loaded patches that registered callbacks before OnGameBoot).
    _nb_call_toggle_callbacks(NB_isNeatBuildingUIEnabled())
end

-- Register options at game boot
Events.OnGameBoot.Add(NB_ModOptions)