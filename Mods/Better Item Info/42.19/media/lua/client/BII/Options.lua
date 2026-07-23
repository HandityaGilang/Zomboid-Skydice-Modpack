local Options = {}

local defaults = {
    ShowFoodInfo = true,
    ShowLiquidInfo = true,
    ShowWeaponInfo = true,
    ShowSeedInfo = true,
    ShowMetalInfo = true,
    ShowFuelInfo = true,
    ShowElectronicsInfo = true,
    ShowBookInfo = true,
    ShowRemainingInfo = true,
}

local function text(key, fallback)
    if getTextOrNull then
        return getTextOrNull(key) or fallback
    end
    return fallback
end

local function addTickBox(options, key, fallback, tooltipFallback)
    Options[key] = options:addTickBox(
        key,
        text("UI_BII_" .. key, fallback),
        defaults[key] == true,
        text("UI_BII_" .. key .. "_tooltip", tooltipFallback)
    )
end

if PZAPI and PZAPI.ModOptions then
    local modOptions = PZAPI.ModOptions:create("EURY_ITEMINFO", text("UI_BII_Options", "Better Item Info"))

    addTickBox(modOptions, "ShowFoodInfo", "Show Food Info", "Show spoilage and nutrition details for food.")
    addTickBox(modOptions, "ShowLiquidInfo", "Show Liquid Info", "Show nutrition details for liquids.")
    addTickBox(modOptions, "ShowWeaponInfo", "Show Weapon Info", "Show weapon stats based on character skills.")
    addTickBox(modOptions, "ShowSeedInfo", "Show Seed Info", "Show growing seasons and growth time for seeds.")
    addTickBox(modOptions, "ShowMetalInfo", "Show Metal Info", "Show smelting and scrapping metal information.")
    addTickBox(modOptions, "ShowFuelInfo", "Show Fire Fuel Info", "Show how long burnable items fuel a fire.")
    addTickBox(modOptions, "ShowElectronicsInfo", "Show Electronics Info", "Show items dismantled for electrical XP.")
    addTickBox(modOptions, "ShowBookInfo", "Show Book Info", "Show remaining read time for skill books.")
    addTickBox(modOptions, "ShowRemainingInfo", "Show Remaining Uses", "Show numeric remaining uses for drainable items.")
end

local function getValue(key)
    local option = Options[key]
    if option and option.getValue then
        return option:getValue() == true
    end
    return defaults[key] == true
end

function Options.shouldShowFoodInfo() return getValue("ShowFoodInfo") end
function Options.shouldShowLiquidInfo() return getValue("ShowLiquidInfo") end
function Options.shouldShowWeaponInfo() return getValue("ShowWeaponInfo") end
function Options.shouldShowSeedInfo() return getValue("ShowSeedInfo") end
function Options.shouldShowMetalInfo() return getValue("ShowMetalInfo") end
function Options.shouldShowFuelInfo() return getValue("ShowFuelInfo") end
function Options.shouldShowElectronicsInfo() return getValue("ShowElectronicsInfo") end
function Options.shouldShowBookInfo() return getValue("ShowBookInfo") end
function Options.shouldShowRemainingInfo() return getValue("ShowRemainingInfo") end

return Options
