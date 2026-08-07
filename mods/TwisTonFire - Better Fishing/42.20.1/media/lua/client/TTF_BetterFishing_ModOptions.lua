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

    -- Build 42.20.1 resolves ModOptions labels and tooltips through getText().
    -- Pass translation keys here instead of already translated strings.
    local options = PZAPI.ModOptions:create(
        OPTIONS_ID,
        "UI_options_TTF_BetterFishing"
    )

    options:addTitle("UI_options_TTF_BetterFishing_StatusUI_Title")

    config.disableStatusUI = options:addTickBox(
        "disableStatusUI",
        "UI_options_TTF_BetterFishing_disableStatusUI",
        false,
        "UI_options_TTF_BetterFishing_disableStatusUI_tooltip"
    )

    config.statusUIScale = options:addComboBox(
        "statusUIScale",
        "UI_options_TTF_BetterFishing_statusUIScale",
        "UI_options_TTF_BetterFishing_statusUIScale_tooltip"
    )

    for _, value in ipairs(SCALE_VALUES) do
        config.statusUIScale:addItem(
            "UI_options_TTF_BetterFishing_statusUIScale_" .. tostring(value),
            value == 100
        )
    end
end

createOptions()
