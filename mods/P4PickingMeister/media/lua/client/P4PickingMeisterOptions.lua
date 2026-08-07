require "P4PickingMeister"

local options = {
	ShowIcon = true,
	ShowInactiveMenu = true,
}

if ModOptions and ModOptions.getInstance then
	local settings = ModOptions:getInstance(options, "P4PickingMeister", "Picking Meister")

	local optShowIcon = settings:getData("ShowIcon")
	optShowIcon.name = "UI_P4PickingMeister_Options_ShowIcon_Name"
	optShowIcon.tooltip = "UI_P4PickingMeister_Options_ShowIcon_Tooltip"

	local optShowInactiveMenu = settings:getData("ShowInactiveMenu")
	optShowInactiveMenu.name = "UI_P4PickingMeister_Options_ShowInactiveMenu_Name"
	optShowInactiveMenu.tooltip = "UI_P4PickingMeister_Options_ShowInactiveMenu_Tooltip"

	SetModOptions(options)
end
