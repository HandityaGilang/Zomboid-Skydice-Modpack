-- XP_NC_ModOptions.lua
-- Registers mod options and notifies the recipe list to recompute heights
-- when options that affect layout/height change (text scale, “Mod:” visibility).

local MOD_ID  = "Neat_Crafting_AddonXP"
local modName = "Neat Crafting - Addon XP Display" -- keep name in translations for easier identification

-------------------------------------------------------------
-- Internal: best-effort invalidation of recipe list heights
-- Called when options that affect layout change.
-------------------------------------------------------------
local function XP_NC_tryInvalidateHeights()
    -- Preferred: let the XP_NC UI module handle it (defined in XP_NC_RecipeList_Box.lua)
    if type(_G.XP_NC_invalidateHeights) == "function" then
        -- Call user's function safely
        local ok, err = pcall(_G.XP_NC_invalidateHeights)
        if not ok then print("[XP_NC] invalidateHeights error ->", err) end
        return
    end

    -- Fallback: try to find a visible list and mark it dirty.
    -- We do this defensively; if anything is missing we just return.
    local ui = getPlayerContext and getPlayerContext()
    if ui and ui.currentRecipeListView then
        local list = ui.currentRecipeListView
        list.XP_NC_heightsDirty = true
        if list.updateScrollMetrics then
            pcall(function() list:updateScrollMetrics() end)
        end
        if list.refreshItems and not list.XP_NC_inRefresh then
            pcall(function() list:refreshItems() end)
        end
    end
end

-- Helper: attach a value-changed callback to a PZAPI option object (defensively)
local function attachOnChange(optionObj, cb)
    if not optionObj or type(cb) ~= "function" then return end
    -- Try common callback shapes defensively
    if type(optionObj.setOnValueChanged) == "function" then
        optionObj:setOnValueChanged(cb)
        return
    end
    if type(optionObj.onValueChanged) == "function" then
        optionObj:onValueChanged(cb)
        return
    end
    -- Some PZAPI builds expose 'setCallback'
    if type(optionObj.setCallback) == "function" then
        optionObj:setCallback(cb)
        return
    end
    -- Last resort: wrap getter polling once user closes the options (no-op if not available)
end

-------------------------------------------------------------
-- Registers the mod options into the in-game options menu
-------------------------------------------------------------
local function XP_NC_ModOptions()
    local options = PZAPI.ModOptions:create(MOD_ID, modName)

    -- Show XP lines
    local opt_xpShow = options:addTickBox("XP_NC_xpShow", getText("UI_XP_NC_xpShow"), true, getText("UI_XP_NC_xpShow_tooltip"))

    -- XP lines format
    local xpFormat = options:addComboBox("XP_NC_xpFormat", getText("UI_XP_NC_xpFormat"), getText("UI_XP_NC_xpFormat_tooltip"))
    xpFormat:addItem(getText("UI_XP_NC_xpFormat_BasicXP"),     false)
    xpFormat:addItem(getText("UI_XP_NC_xpFormat_FinalXP"),     false)
    xpFormat:addItem(getText("UI_XP_NC_xpFormat_Multiplier"),  true)
    xpFormat:addItem(getText("UI_XP_NC_xpFormat_Breakdown"),   false)

    -- Show “Mod:” line
    local opt_showMod = options:addTickBox("XP_NC_showRecipeMod", getText("UI_XP_NC_showRecipeMod"), true, getText("UI_XP_NC_showRecipeMod_tooltip"))

    -- Extra-lines text scale (for XP/“Mod:” lines)
    local textScale = options:addComboBox(
        "XP_NC_textScale",
        getText("UI_XP_NC_textScale"),
        getText("UI_XP_NC_textScale_tooltip")
    )
    textScale:addItem("70%%",  false)
    textScale:addItem("80%%",  true)   -- DEFAULT (matches 0.8 of the NC mod)
    textScale:addItem("90%%",  false)
    textScale:addItem("100%%", false)
    textScale:addItem("110%%", false)
    textScale:addItem("120%%", false)

    ----------------------------------------------------------------
    -- Side effects: when these options change, request height recompute
    -- * XP_NC_showRecipeMod affects whether “Mod:” line is drawn
    -- * XP_NC_textScale affects line height / LUT / desired height
    -- * XP_NC_xpShow also changes line count potentially (optional to hook)
    ----------------------------------------------------------------
    attachOnChange(opt_showMod, XP_NC_tryInvalidateHeights)
    attachOnChange(textScale,  XP_NC_tryInvalidateHeights)
    attachOnChange(opt_xpShow, XP_NC_tryInvalidateHeights)
end

-- Register options on game boot
Events.OnGameBoot.Add(XP_NC_ModOptions)

-------------------------------------------------------------
-- Getter functions for mod options
-------------------------------------------------------------

function XP_NC_getxpShow()
    if rawget(_G, "XP_NC_DISABLE_XP_MOD_LINES") == true then return false end
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local opt = options:getOption("XP_NC_xpShow")
        if opt then
            return opt:getValue() == true
        end
    end
    return true
end

function XP_NC_getxpFormat()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local opt = options:getOption("XP_NC_xpFormat")
        if opt then
            return tostring(opt:getValue())
        end
    end
    return "3" -- Default index as string
end

-- Returns whether to display the recipe's origin mod line in the UI
function XP_NC_getShowRecipeMod()
    if rawget(_G, "XP_NC_DISABLE_XP_MOD_LINES") == true then return false end
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local opt = options:getOption("XP_NC_showRecipeMod")
        if opt then return opt:getValue() == true end
    end
    return true -- default enabled
end

-- Returns scale for extra text lines (XP and "Mod:")
function XP_NC_getTextScale()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    local idx = 2 -- 80% default
    if options then
        local opt = options:getOption("XP_NC_textScale")
        if opt then idx = tonumber(opt:getValue()) or 2 end
    end
    local map = {0.7, 0.8, 0.9, 1.0, 1.1, 1.2}
    return map[idx] or 0.8
end
