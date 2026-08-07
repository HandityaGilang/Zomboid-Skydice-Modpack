-- TwisTonFire — Better Fishing Mod Options

TTF_BetterFishingOptions = TTF_BetterFishingOptions or {}

local OPTIONS_ID = "TwisTonFireBetterFishing"

local config = {
    disableStatusUI = nil,
    statusUIScale = nil,
}

local SCALE_VALUES = {
    50,
    75,
    100,
    125,
    150,
    175,
    200,
}

local function getTextSafe(key, fallback)
    if getTextOrNull then
        local text = getTextOrNull(key)
        if text and text ~= key then
            return text
        end
    end

    return fallback
end

function TTF_BetterFishingOptions.isStatusUIDisabled()
    if config.disableStatusUI and config.disableStatusUI.getValue then
        return config.disableStatusUI:getValue() == true
    end

    return false
end

function TTF_BetterFishingOptions.getUIScalePercent()
    if config.statusUIScale and config.statusUIScale.getValue then
        local index = tonumber(config.statusUIScale:getValue()) or 3
        return SCALE_VALUES[index] or 100
    end

    return 100
end

local function createOptions()
    if not PZAPI or not PZAPI.ModOptions then
        return
    end

    local options = PZAPI.ModOptions:create(
        OPTIONS_ID,
        getTextSafe("UI_options_TTF_BetterFishing", "TwisTonFire - Better Fishing")
    )

    options:addTitle(getTextSafe("UI_options_TTF_BetterFishing_StatusUI_Title", "Fishing Status UI"))

    config.disableStatusUI = options:addTickBox(
        "disableStatusUI",
        getTextSafe("UI_options_TTF_BetterFishing_disableStatusUI", "Disable Fishing Status UI"),
        false,
        getTextSafe("UI_options_TTF_BetterFishing_disableStatusUI_tooltip", "Disables the icon-only fishing status UI when a fishing rod is equipped.")
    )

    config.statusUIScale = options:addComboBox(
        "statusUIScale",
        getTextSafe("UI_options_TTF_BetterFishing_statusUIScale", "Fishing Status UI Scale"),
        getTextSafe("UI_options_TTF_BetterFishing_statusUIScale_tooltip", "Changes the size of the fishing status UI.")
    )

    for _, value in ipairs(SCALE_VALUES) do
        config.statusUIScale:addItem(tostring(value) .. "%", value == 100)
    end
end

createOptions()