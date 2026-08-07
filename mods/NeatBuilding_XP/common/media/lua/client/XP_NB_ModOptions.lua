-- XP_NB_ModOptions.lua
-- Project Zomboid (B42) – Options panel for the “XP_NB” addon
-- All comments are in English as requested.

-----------------------------------------
-- Constants
-----------------------------------------
local MOD_ID    = "Neat_Building_AddonXP"   -- keep this equal to your modOptionsID
local MOD_TITLE = "Neat Building - Addon XP Display"  -- keep name in translations for easier identification

-----------------------------------------
-- Register the options into the main menu
-----------------------------------------
local function XP_NB_ModOptions()
    -- NOTE: pass the *i18n key* as section name; MainOptions.lua will call getText on it.
    local options = PZAPI.ModOptions:create(MOD_ID, MOD_TITLE)

    -- Show XP lines (tickbox)
    -- SIGNATURE (B42): addTickBox(id, nameKey, valueBoolean, tooltipKey)
    options:addTickBox(
        "XP_NB_xpShow",
        "UI_XP_NB_xpShow",
        true,
        "UI_XP_NB_xpShow_tooltip"
    )

    -- XP lines format (combobox)
    -- SIGNATURE: addComboBox(id, nameKey, tooltipKey)
    local xpFormat = options:addComboBox(
        "XP_NB_xpFormat",
        "UI_XP_NB_xpFormat",
        "UI_XP_NB_xpFormat_tooltip"
    )
    -- IMPORTANT: pass i18n KEYS; the wrapper calls getText(name) internally.
    xpFormat:addItem("UI_XP_NB_xpFormat_BasicXP",    false)
    xpFormat:addItem("UI_XP_NB_xpFormat_FinalXP",    false)
    xpFormat:addItem("UI_XP_NB_xpFormat_Multiplier", true)  -- default
    xpFormat:addItem("UI_XP_NB_xpFormat_Breakdown",  false)

    -- Show “Mod:” line (tickbox)
    local opt_showMod = options:addTickBox(
        "XP_NB_showRecipeMod",
        "UI_XP_NB_showRecipeMod",
        true,
        "UI_XP_NB_showRecipeMod_tooltip"
    )

    -- Extra-lines text scale (for XP and “Mod:” lines)
    local textScale = options:addComboBox(
        "XP_NB_textScale",
        "UI_XP_NB_textScale",
        "UI_XP_NB_textScale_tooltip"
    )
    -- These are literal labels; B42.20.1 requires escaped percent signs because ModOptions calls getText(name).
    textScale:addItem("70%%",  false)
    textScale:addItem("80%%",  true)   -- default (matches scale 0.8)
    textScale:addItem("90%%",  false)
    textScale:addItem("100%%", false)
    textScale:addItem("110%%", false)
    textScale:addItem("120%%", false)

    ----------------------------------------------------------------
    -- Ask list boxes to recompute row heights when some options change
    ----------------------------------------------------------------
	local function invalidateHeights()
		if not XP_NB_allLists then return end
		for list,_ in pairs(XP_NB_allLists) do
			list.XP_NB_heightsDirty = true
			list._xpnb_dirty = true
		end
	end

    local function attachOnChange(opt, cb)
        -- Different builds expose different APIs; keep it defensive.
        if opt and type(opt.onValueChanged) == "function" then
            opt:onValueChanged(function() cb() end)
        elseif opt and type(opt.setOnValueChanged) == "function" then
            opt:setOnValueChanged(cb)
        elseif opt and type(opt.setCallback) == "function" then
            opt:setCallback(cb)
        end
    end

    attachOnChange(opt_showMod, invalidateHeights)
    attachOnChange(textScale,   invalidateHeights)
    attachOnChange(xpFormat,    invalidateHeights)
end

-- Register options at game boot
Events.OnGameBoot.Add(XP_NB_ModOptions)

-----------------------------------------
-- Getters used by the rest of the addon
-- (Keep them tiny; they’re called in hot paths.)
-----------------------------------------
local function _xpnb_to_bool(v)
    -- Accept true/false, "true"/"false", 1/0, "1"/"0"
    return v == true or v == 1 or v == "1" or v == "true"
end

function XP_NB_getxpShow()
    local opts = PZAPI.ModOptions:getOptions(MOD_ID)
    local o = opts and opts:getOption("XP_NB_xpShow")
    if not o then return true end          -- default if option missing
    return _xpnb_to_bool(o:getValue())
end

-- Returns "1".."4" across both old numeric values and newer string-key values.
function XP_NB_getxpFormat()
    local opts = PZAPI.ModOptions:getOptions(MOD_ID)
    local o = opts and opts:getOption("XP_NB_xpFormat")
    local v = o and o:getValue() or nil
    if v == nil then return "3" end
    v = tostring(v)
    local map = {
        ["1"] = "1",
        ["2"] = "2",
        ["3"] = "3",
        ["4"] = "4",
        ["UI_XP_NB_xpFormat_BasicXP"] = "1",
        ["UI_XP_NB_xpFormat_FinalXP"] = "2",
        ["UI_XP_NB_xpFormat_Multiplier"] = "3",
        ["UI_XP_NB_xpFormat_Breakdown"] = "4",
    }
    return map[v] or "3"
end

function XP_NB_getShowRecipeMod()
    local opts = PZAPI.ModOptions:getOptions(MOD_ID)
    local o = opts and opts:getOption("XP_NB_showRecipeMod")
    if not o then return true end
    return _xpnb_to_bool(o:getValue())
end

-- Returns numeric zoom factor for extra lines (0.7..1.2), default 0.8
function XP_NB_getTextScale()
    local opts = PZAPI.ModOptions:getOptions(MOD_ID)
    local o = opts and opts:getOption("XP_NB_textScale")
    local idx = (o and tonumber(o:getValue())) or 2
    local map = {0.7, 0.8, 0.9, 1.0, 1.1, 1.2}
    return map[idx] or 0.8
end
