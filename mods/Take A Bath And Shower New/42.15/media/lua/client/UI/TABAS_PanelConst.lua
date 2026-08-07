local TABAS_PanelConst = {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

TABAS_PanelConst.SCALE = {
    HGT_SMALL = FONT_HGT_SMALL,
    HGT_MEDIUM = FONT_HGT_MEDIUM,
    HGT_BUTTON = FONT_HGT_SMALL + 6,
    BETWEEN_SPACING = FONT_HGT_SMALL * 0.6,
    BORDER_SPACING = FONT_HGT_SMALL * 0.45,
}

TABAS_PanelConst.COLOR = {
    backgroundColor = {r=0, g=0, b=0, a=0.5},
    backgroundColorDark = {r=0, g=0, b=0, a=0.8},
    blankColor = {r=0, g=0, b=0, a=0},
    borderColor = {r=0.6, g=0.6, b=0.6, a=1},
    borderOuterColor = {r=0.4, g=0.4, b=0.4, a=1},
    buttonBackgroundColor = {r=0.4, g=0.4, b=0.4, a=0.4},
    buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5},
    labelColor = {r=0.8, g=0.8, b=0.5,a=1},
    textColor = {r=1, g=1, b=1, a=1},
    variableColor={r=0.9, g=0.55, b=0.1, a=1}
}

TABAS_PanelConst.TEXTURE = {
    -- background
    bg_button = getTexture("media/ui/Backgrounds/tabas_buttonBG.png"),
    bg_label = getTexture("media/ui/Backgrounds/tabas_labelGB.png"),
    bg_frame = getTexture("media/ui/Backgrounds/tabas_statusFrame.png"),
    bg_title = getTexture("media/ui/Panel_TitleBar.png"),
    bg_status = getTexture("media/ui/Panel_StatusBar.png"),
    -- general
    trueIcon = getTexture("media/ui/Icons/tabas_trueIcon.png"),
    falseIcon = getTexture("media/ui/Icons/tabas_falseIcon.png"),
    infinityIcon = getTexture("media/ui/Icons/tabas_infinityIcon.png"),
    cautionIcon = getTexture("media/ui/Icons/tabas_caution.png"),
    configIcon = getTexture("media/ui/Icons/tabas_configIcon.png"),
    plusIcon = getTexture("media/ui/Entity/BTN_Plus_Icon_48x48.png"),
	minusIcon = getTexture("media/ui/Entity/BTN_Minus_Icon_48x48.png"),
    swapIcon = getTexture("media/ui/Entity/BTN_Swap_Icon_48x48.png"),
    resetIcon = getTexture("media/ui/Icons/tabas_resetIcon.png"),

    infoButton_small = getTexture("media/ui/Panel_info_button.png"),
    infoButton = getTexture("media/ui/inventoryPanes/Button_Info.png"),
    pinButton = getTexture("media/ui/inventoryPanes/Button_Pin.png"),
    closeButton = getTexture("media/ui/inventoryPanes/Button_Close.png"),
    -- bath salt
    bathSaltAdd = getTexture("media/ui/Icons/tabas_addBathSalt.png"),
    bathSaltItem = getTexture("media/textures/item_BathSalt.png"),
    -- entry panel
    makeoff = getTexture("media/ui/Icons/tabas_makeoff.png"),
	towel = getTexture("media/ui/Icons/tabas_bathtowel.png"),
	autoCC = getTexture("media/ui/Icons/tabas_autoCC.png"),
	autoDry = getTexture("media/ui/Icons/tabas_tubReheat.png"),
	bathingTime = getTexture("media/ui/Icons/tabas_bathingTime.png"),
    -- shower
    showerHot = getTexture("media/ui/Icons/tabas_shower_hot.png"),
    showerCold = getTexture("media/ui/Icons/tabas_shower_cold.png"),
    -- bath
    waterIcon = getTexture("media/ui/Icons/tabas_water.png"),
    pipedIcon = getTexture("media/ui/Icons/tabas_piped.png"),
    powerdIcon = getTexture("media/ui/Icons/tabas_electricaly.png"),
    faucetIcon = getTexture("media/ui/Icons/tabas_bathFaucet.png"),
    tub_fillIcon = getTexture("media/ui/Icons/tabas_filltub.png"),
    tub_stopIcon = getTexture("media/ui/Icons/tabas_stopIcon.png"),
    tub_emptyIcon = getTexture("media/ui/Icons/tabas_tubStopperOut.png"),
    tub_removeIcon = getTexture("media/ui/Icons/tabas_tubStopperOut.png"),
    tub_putIcon = getTexture("media/ui/Icons/tabas_tubStopperIn.png"),
    tub_capacity = getTexture("media/ui/Icons/tabas_tubCapacity.png"),
    tub_amount = getTexture("media/ui/Icons/tabas_tubAmount.png"),
    tub_lastUpdate = getTexture("media/ui/Icons/tabas_lastUpdate.png"),
    tub_dirtyLevel = getTexture("media/ui/Icons/tabas_dirtyLevel.png"),
    tub_waterTemp = getTexture("media/ui/Icons/tabas_waterTemperature.png"),
    tub_setTemp = getTexture("media/ui/Icons/tabas_temperatureSetting.png"),
    bath_actionmenu = getTexture("media/ui/Icons/tabas_bath_actionmenu.png"),
}

return TABAS_PanelConst
