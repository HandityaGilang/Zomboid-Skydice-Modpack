-- ItemConditionSettings.lua
-- Mod Options integration for Item Condition Overlay
-- Version: 1.2.0
--
-- PZAPI.ModOptions ships with the base game in Build 42
-- (media/lua/client/PZAPI/ModOptions.lua) and persists values to ModOptions.ini,
-- so nothing extra is required for settings to survive a restart.

local AMMO_MODES = { "off", "simple", "advanced" }
local AMMO_FONT_MODES = { "auto", "small", "medium", "large" }

-- Hotbar scale slider is in percent, converted to a multiplier
local HOTBAR_SCALE_MIN = 75
local HOTBAR_SCALE_MAX = 250
local HOTBAR_SCALE_STEP = 5
local HOTBAR_SCALE_DEFAULT = 100

local function readOptions(options)
    local S = ItemConditionOverlay and ItemConditionOverlay.Settings
    if not S then
        return
    end

    local ammoMode = options:getOption("ammoCounterMode")
    if ammoMode then
        S.ammoCounterMode = AMMO_MODES[ammoMode:getValue()] or "advanced"
    end

    local fontMode = options:getOption("ammoFontMode")
    if fontMode then
        S.ammoFontMode = AMMO_FONT_MODES[fontMode:getValue()] or "auto"
    end

    local inInventory = options:getOption("showInInventory")
    if inInventory then
        S.showInInventory = inInventory:getValue() and true or false
    end

    local tooltips = options:getOption("showHotbarTooltips")
    if tooltips then
        S.showHotbarTooltips = tooltips:getValue() and true or false
    end

    local fluids = options:getOption("showFluidLevel")
    if fluids then
        S.showFluidLevel = fluids:getValue() and true or false
    end

    local fluidColor = options:getOption("fluidUseOwnColor")
    if fluidColor then
        S.fluidUseOwnColor = fluidColor:getValue() and true or false
    end

    local fillWhenFull = options:getOption("alwaysShowFillBars")
    if fillWhenFull then
        S.alwaysShowFillBars = fillWhenFull:getValue() and true or false
    end

    local scale = options:getOption("hotbarScale")
    if scale then
        local pct = tonumber(scale:getValue()) or HOTBAR_SCALE_DEFAULT
        S.hotbarScale = pct / 100
    end
end

if PZAPI and PZAPI.ModOptions then
    local options = PZAPI.ModOptions:create("ItemConditionOverlay", "Item Condition Overlay")

    ----------------------------------------------------------------------------
    options:addTitle("Hotbar")

    -- Requested repeatedly by players on 1440p, 4K, ultrawide and TV setups.
    -- Vanilla hardcodes 60px hotbar slots that never scale with resolution.
    options:addSlider("hotbarScale", "Hotbar size (%)",
        HOTBAR_SCALE_MIN, HOTBAR_SCALE_MAX, HOTBAR_SCALE_STEP, HOTBAR_SCALE_DEFAULT,
        "Scales the hotbar slots. 100% is vanilla size. Useful on high resolution displays where the vanilla hotbar is very small.")

    local ammoMode = options:addComboBox("ammoCounterMode", "Ammo counter display",
        "How to show remaining ammo on firearms in the hotbar.")
    ammoMode:addItem("Off")
    ammoMode:addItem("Simple (16/16)")
    ammoMode:addItem("Advanced (15+1/15)", true)  -- Default selected

    local ammoFont = options:addComboBox("ammoFontMode", "Ammo counter text size",
        "Auto keeps the normal size, grows with the hotbar size slider, and shortens the text if it will not fit. Use a fixed size if you prefer.")
    ammoFont:addItem("Auto (fit to slot)", true)  -- Default selected
    ammoFont:addItem("Small")
    ammoFont:addItem("Medium")
    ammoFont:addItem("Large")

    options:addTickBox("showHotbarTooltips", "Show hotbar item tooltips", true,
        "Turn off to stop the hotbar tooltip appearing on mouseover, which can overlap other tooltips.")

    ----------------------------------------------------------------------------
    options:addSeparator()
    options:addTitle("Inventory")

    options:addTickBox("showInInventory", "Show condition bars in inventory", true,
        "Turn off for hotbar-only condition bars. Also useful if another inventory mod draws its own bars.")

    options:addTickBox("alwaysShowFillBars", "Keep bars on refillable items when full", true,
        "Canteens, flashlights, filters and anything else with a fill level keep their bar in the inventory even when full, so full is distinguishable from empty at a glance. Turn off to hide them when full, the way ordinary tools behave.")

    ----------------------------------------------------------------------------
    options:addSeparator()
    options:addTitle("Fluids")

    options:addTickBox("showFluidLevel", "Show fill level on water containers", true,
        "Shows how full canteens, water bottles and buckets are. These use a different system to normal items, so they never showed a bar before.")

    options:addTickBox("fluidUseOwnColor", "Colour fluid bars by fluid type", true,
        "Paints the bar in the fluid's own colour, so water, petrol, bleach and tea are distinguishable at a glance. Turn off to use the usual green to red fill gradient instead.")

    ----------------------------------------------------------------------------
    -- Apply settings when the Apply button is clicked
    function options:apply()
        readOptions(self)
    end

    -- Load saved settings on game start
    Events.OnGameStart.Add(function()
        local saved = PZAPI.ModOptions.Dict["ItemConditionOverlay"]
        if saved then
            saved:apply()
        end
    end)
end
