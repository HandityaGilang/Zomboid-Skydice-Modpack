local TABAS_ModOptions = {
    modID = "TakeABathAndShower",
    name = "Take A Bath And Shower",
    options = {
        RemoveAllTfc = nil,
        DisplayBathtubMenu = nil,
        DisplaysAvailableShower = nil,
        DisplayTubWaterDirtyLevel = nil,
        DisplayTubSpacialTooltip = nil,
        DisplayImproveOption = nil,
        EnabledShowerSteamAnim = nil,
        WashOffMakeup = nil,
        AfterBathingDrySelf = nil,
        AutoTakeBathMode = nil,
        DontMindWatchedBy = nil,
        AutoClothesChange = nil,
        WearingActionTime = nil,
        NotTakeoff_Watches = nil,
        NotTakeOff_Accessories = nil,
        NotTakeOff_Glasses = nil,
        NotTakeOff_Belts = nil,
    }
}

local comboBox_DisplayBathtubMenu = {
    getText("UI_TABAS_DisplayBathtubMenu_UC"),
    getText("UI_TABAS_DisplayBathtubMenu_U"),
    getText("UI_TABAS_DisplayBathtubMenu_C")
}

local comboBox_WearingActionTime = {
    getText("UI_TABAS_WearingActionTime_Fast"),
    getText("UI_TABAS_WearingActionTime_Ones"),
    getText("UI_TABAS_WearingActionTime_Vanilla")
}

local function comboBoxAddItem(comboBox, list)
    comboBox:addItem(list[1], true)
    for i=2, #list do
        comboBox:addItem(list[i], false)
    end
end

local function removeAllTfcObject()
    if not isIngameState() then return end
    if not (isDebugEnabled() or (isClient() and (isAdmin() or getAccessLevel() == "moderator"))) then return end
    sendClientCommand(getSpecificPlayer(0), 'tabas_tfc', 'clearAllTfc', {})
end


function TABAS_ModOptions:createOptions()
    local options = PZAPI.ModOptions:create(self.modID, self.name)
    self.options.RemoveAllTfc = options:addButton(
        "RemoveAllTfc",
        getText("UI_TABAS_RemoveAllTfc"),
        getText("UI_TABAS_RemoveAllTfc_tooltip"),
        removeAllTfcObject, nil
    )
    self.options.DisplayBathtubMenu = options:addComboBox(
        "DisplayBathtubMenu",
        getText("UI_TABAS_DisplayBathtubMenu"),
        getText("UI_TABAS_DisplayBathtubMenu_tooltip")
    )
    comboBoxAddItem(self.options.DisplayBathtubMenu, comboBox_DisplayBathtubMenu)

    self.options.DisplaysAvailableShower = options:addTickBox(
        "DisplaysAvailableShower",
        getText("UI_TABAS_DisplaysAvailableShower"),
        true,
        getText("UI_TABAS_DisplaysAvailableShower_tooltip")
    )

    self.options.DisplayTubWaterDirtyLevel = options:addTickBox(
        "DisplayTubWaterDirtyLevel",
        getText("UI_TABAS_DisplayTubWaterDirtyLevel"),
        false,
        getText("UI_TABAS_DisplayTubWaterDirtyLevel_tooltip")
    )

    self.options.DisplayTubSpacialTooltip = options:addTickBox(
        "DisplayTubSpacialTooltip",
        getText("UI_TABAS_DisplayTubSpacialTooltip"),
        true,
        getText("UI_TABAS_DisplayTubSpacialTooltip_tooltip")
    )

    self.options.DisplayImproveOption = options:addTickBox(
        "DisplayImproveOption",
        getText("UI_TABAS_DisplayImproveOption"),
        true,
        getText("UI_TABAS_DisplayImproveOption_tooltip")
    )

    self.options.EnabledShowerSteamAnim = options:addTickBox(
        "EnabledShowerSteamAnim",
        getText("UI_TABAS_EnabledShowerSteamAnim"),
        true,
        getText("UI_TABAS_EnabledShowerSteamAnim_tooltip")
    )
    
    self.options.WashOffMakeup = options:addTickBox(
        "WashOffMakeup",
        getText("UI_TABAS_WashOffMakeup"),
        true,
        getText("UI_TABAS_WashOffMakeup_tooltip")
    )

    self.options.AfterBathingDrySelf = options:addTickBox(
        "AfterBathingDrySelf",
        getText("UI_TABAS_AfterBathingDrySelf"),
        true,
        getText("UI_TABAS_AfterBathingDrySelf_tooltip")
    )

    self.options.AutoTakeBathMode = options:addTickBox(
        "AutoTakeBathMode",
        getText("UI_TABAS_AutoTakeBathMode"),
        true,
        getText("UI_TABAS_AutoTakeBathMode_tooltip")
    )

    self.options.DontMindWatchedBy = options:addTextEntry(
        "DontMindWatchedBy",
        getText("UI_TABAS_DontMindWatchedBy"),
        getText("username"),
        getText("UI_TABAS_DontMindWatchedBy_tooltip")
    )

    options:addDescription(" ")

    self.options.AutoClothesChange = options:addTickBox(
        "AutoClothesChange",
        getText("UI_TABAS_AutoClothesChange"),
        true,
        getText("UI_TABAS_AutoClothesChange_tooltip")
    )
    
    self.options.WearingActionTime = options:addComboBox(
        "WearingActionTime",
        getText("UI_TABAS_WearingActionTime"),
        getText("UI_TABAS_WearingActionTime_tooltip")
    )
    comboBoxAddItem(self.options.WearingActionTime, comboBox_WearingActionTime)

    self.options.NotTakeoff_Watches = options:addTickBox(
        "NotTakeoff_Watches",
        getText("UI_TABAS_NotTakeoff_Watches"),
        false,
        getText("UI_TABAS_NotTakeoff_Watches_tooltip")
    )

    self.options.NotTakeOff_Accessories = options:addTickBox(
        "NotTakeOff_Accessories",
        getText("UI_TABAS_NotTakeOff_Accessories"),
        false,
        getText("UI_TABAS_NotTakeOff_Accessories_tooltip")
    )

    self.options.NotTakeOff_Glasses = options:addTickBox(
        "NotTakeOff_Glasses",
        getText("UI_TABAS_NotTakeOff_Glasses"),
        false,
        getText("UI_TABAS_NotTakeOff_Glasses_tooltip")
    )

    self.options.NotTakeOff_Belts = options:addTickBox(
        "NotTakeOff_Belts",
        getText("UI_TABAS_NotTakeOff_Belts"),
        false,
        getText("UI_TABAS_NotTakeOff_Belts_tooltip")
    )
end

Events.OnGameBoot.Add(function() TABAS_ModOptions:createOptions() end)

return TABAS_ModOptions.options