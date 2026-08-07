TaillightModZomboid = TaillightModZomboid or {}
-- ---------------------------------------------------------------------
function TaillightModZomboid.restoreDefaultTaillight()
    print("Restoring default brightness...")
    TaillightModZomboid.optBrightnessRed:setValue(0.35)
end

function TaillightModZomboid.restoreDefaultReverse()
    print("Restoring default brightness...")
    TaillightModZomboid.optBrightnessReverse:setValue(0.4)
end
-- ---------------------------------------------------------------------

function TaillightModZomboid.loadModMenuConfig()
    local id = "Taillights and Stoplights"
    local options = PZAPI.ModOptions:create(id, getText("UI_TaillightModZomboid_modName"))
    
    TaillightModZomboid.optReverseLights = options:addTickBox("0", getText("UI_TaillightModZomboid_optReverseLights"), false)
    TaillightModZomboid.optAlwaysVisible = options:addTickBox("6", getText("UI_TaillightModZomboid_optAlwaysVisible"), false, getText("UI_TaillightModZomboid_optAlwaysVisible_tooltip"))
    TaillightModZomboid.optSep1 = options:addSeparator()
    TaillightModZomboid.optBrightnessRed = options:addSlider("2",  getText("UI_TaillightModZomboid_optBrightnessRed"), 0.2, 0.55, 0.01, 0.35, getText("UI_TaillightModZomboid_optBrightnessRed_tooltip"))
    TaillightModZomboid.optDefaultBrightness1 = options:addButton("3", getText("UI_TaillightModZomboid_optDefaultBrightness1"),nil, TaillightModZomboid.restoreDefaultTaillight)
    TaillightModZomboid.optBrightnessReverse = options:addSlider("4",  getText("UI_TaillightModZomboid_optBrightnessReverse"), 0.22, 1, 0.01, 0.4, getText("UI_TaillightModZomboid_optBrightnessReverse_tooltip"))
    TaillightModZomboid.optDefaultBrightness2 = options:addButton("5", getText("UI_TaillightModZomboid_optDefaultBrightness2"), nil, TaillightModZomboid.restoreDefaultReverse)
end

TaillightModZomboid.loadModMenuConfig()

-----------------------------------------------------------------------

function TaillightModZomboid.getOptReverseLights()
    return TaillightModZomboid.optReverseLights:getValue()
end
function TaillightModZomboid.getOptAlwaysVisible()
    return TaillightModZomboid.optAlwaysVisible:getValue()
end
function TaillightModZomboid.getOptBRed()
    return (TaillightModZomboid.optBrightnessRed:getValue() - 0.35)
end
function TaillightModZomboid.getOptBReverse()
    return (TaillightModZomboid.optBrightnessReverse:getValue() - 0.4)
end
