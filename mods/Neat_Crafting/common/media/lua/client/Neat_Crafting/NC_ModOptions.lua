-- NC_ModOptions.lua
-- Project Zomboid (B42) - Options panel for Neat Crafting UI

-----------------------------------------
-- Constants
-----------------------------------------
local MOD_ID    = "Neat_Crafting_Beta"  -- Unique ID for this ModOptions section
local MOD_TITLE = "Neat Crafting"  -- Section title shown in the options menu

-----------------------------------------
-- Internal state + callback registry
-----------------------------------------
NC_UI_TOGGLE_CALLBACKS = NC_UI_TOGGLE_CALLBACKS or {}

-- Internal flag: ensure we load ModOptions.ini at least once so saved values apply in-game.
NC_MODOPTIONS_LOADED = NC_MODOPTIONS_LOADED or false

local function _nc_to_bool(v)
    -- Accept true/false, "true"/"false", 1/0, "1"/"0"
    return v == true or v == 1 or v == "1" or v == "true"
end

function NC_isNeatCraftingUIEnabled()
    -- Default = enabled.
    -- Important: ModOptions.ini is only loaded by vanilla when opening the Options screen.
    -- We load it once ourselves so the saved value applies immediately at game start.
    if not NC_MODOPTIONS_LOADED and PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.load) == "function" then
        pcall(function() PZAPI.ModOptions:load() end)
        NC_MODOPTIONS_LOADED = true
    end

    local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions(MOD_ID)
    local o = opts and opts:getOption("useNeatCraftingUI")
    if not o then return true end
    return _nc_to_bool(o:getValue())
end

function NC_RegisterUiToggleCallback(cb)
    -- Register a callback that receives (enabled:boolean)
    if type(cb) ~= "function" then return end
    table.insert(NC_UI_TOGGLE_CALLBACKS, cb)
    -- Apply immediately using current option value
    pcall(function() cb(NC_isNeatCraftingUIEnabled()) end)
end

local function _nc_call_toggle_callbacks(enabled)
    for _,cb in ipairs(NC_UI_TOGGLE_CALLBACKS) do
        pcall(function() cb(enabled) end)
    end
end

-----------------------------------------
-- Register options into the main menu
-----------------------------------------
local function NC_ModOptions()
    if not (PZAPI and PZAPI.ModOptions) then return end

    local options = PZAPI.ModOptions:create(MOD_ID, MOD_TITLE)

    -- Enable Neat Crafting UI (tickbox)
    options:addTickBox(
        "useNeatCraftingUI",
        "IGUI_NC_ModOptions_UseNeatCraftingUI",
        true,
        "IGUI_NC_ModOptions_UseNeatCraftingUI_Tooltip"
    )

    -- Load saved values now so the toggle works without opening the Options screen.
    if type(PZAPI.ModOptions.load) == "function" then
        pcall(function() PZAPI.ModOptions:load() end)
        NC_MODOPTIONS_LOADED = true
    end

    -- Apply changes live when the user toggles the option in the Options menu
    local opt = options:getOption("useNeatCraftingUI")
    if opt then
        -- Called immediately when the user changes the value in the Options menu.
        opt.onChange = function(self, selected)
            _nc_call_toggle_callbacks(_nc_to_bool(selected))
        end

        -- Called when pressing Apply in the Options menu.
        opt.onChangeApply = function(self, selected)
            _nc_call_toggle_callbacks(_nc_to_bool(selected))
        end
    end

    -- Apply current state once options exist (covers early-loaded patches that registered callbacks before OnGameBoot).
    _nc_call_toggle_callbacks(NC_isNeatCraftingUIEnabled())
end

-- Register options at game boot
Events.OnGameBoot.Add(NC_ModOptions)
