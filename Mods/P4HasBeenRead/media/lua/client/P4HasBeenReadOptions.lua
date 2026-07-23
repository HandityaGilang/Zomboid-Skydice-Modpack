require "P4HasBeenRead"

local options = {
	showNR = true,
	showNC = true,
	showAR = false,
	showNCasNR = false,
	showSM = true,
	showCT = true,
	enableMap = true,
	enableCD = true,
	enableVHS = true,
	enableHVHS = true,
	autoMark = false,
	reverseMarkDisplay = false,
}

if ModOptions and ModOptions.getInstance then
	local settings = ModOptions:getInstance(options, "P4HasBeenRead", "Has Been Read")

	local optShowNR = settings:getData("showNR")
	optShowNR.name = "UI_P4HasBeenRead_Options_ShowNR_Name"
	optShowNR.tooltip = "UI_P4HasBeenRead_Options_ShowNR_Tooltip"

	local optShowNC = settings:getData("showNC")
	optShowNC.name = "UI_P4HasBeenRead_Options_ShowNC_Name"
	optShowNC.tooltip = "UI_P4HasBeenRead_Options_ShowNC_Tooltip"

	local optShowAR = settings:getData("showAR")
	optShowAR.name = "UI_P4HasBeenRead_Options_ShowAR_Name"
	optShowAR.tooltip = "UI_P4HasBeenRead_Options_ShowAR_Tooltip"

	local optShowNCasNR = settings:getData("showNCasNR")
	optShowNCasNR.name = "UI_P4HasBeenRead_Options_ShowNCasNR_Name"
	optShowNCasNR.tooltip = "UI_P4HasBeenRead_Options_ShowNCasNR_Tooltip"

	local optShowSM = settings:getData("showSM")
	optShowSM.name = "UI_P4HasBeenRead_Options_ShowSM_Name"
	optShowSM.tooltip = "UI_P4HasBeenRead_Options_ShowSM_Tooltip"

	local optShowCT = settings:getData("showCT")
	optShowCT.name = "UI_P4HasBeenRead_Options_ShowCT_Name"
	optShowCT.tooltip = "UI_P4HasBeenRead_Options_ShowCT_Tooltip"

	local optEnableMap = settings:getData("enableMap")
	optEnableMap.name = "UI_P4HasBeenRead_Options_EnableMap_Name"
	optEnableMap.tooltip = "UI_P4HasBeenRead_Options_EnableMap_Tooltip"

	local optEnableCD = settings:getData("enableCD")
	optEnableCD.name = "UI_P4HasBeenRead_Options_EnableCD_Name"
	optEnableCD.tooltip = "UI_P4HasBeenRead_Options_EnableCD_Tooltip"

	local optEnableVHS = settings:getData("enableVHS")
	optEnableVHS.name = "UI_P4HasBeenRead_Options_EnableVHS_Name"
	optEnableVHS.tooltip = "UI_P4HasBeenRead_Options_EnableVHS_Tooltip"

	local optEnableHVHS = settings:getData("enableHVHS")
	optEnableHVHS.name = "UI_P4HasBeenRead_Options_EnableHVHS_Name"
	optEnableHVHS.tooltip = "UI_P4HasBeenRead_Options_EnableHVHS_Tooltip"

	local optAutoMark = settings:getData("autoMark")
	optAutoMark.name = "UI_P4HasBeenRead_Options_AutoMark_Name"
	optAutoMark.tooltip = "UI_P4HasBeenRead_Options_AutoMark_Tooltip"

	local optReverseMarkDisplay = settings:getData("reverseMarkDisplay")
	optReverseMarkDisplay.name = "UI_P4HasBeenRead_Options_ReverseMarkDisplay_Name"
	optReverseMarkDisplay.tooltip = "UI_P4HasBeenRead_Options_ReverseMarkDisplay_Tooltip"

	SetModOptions(options)

	function settings:OnApplyInGame()
		SetTextures()
	end
end
