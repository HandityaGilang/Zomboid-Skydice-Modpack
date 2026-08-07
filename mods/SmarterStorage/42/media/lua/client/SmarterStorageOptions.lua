require "SmarterStorage"

local options = {
	vanillaTooltips_enabled = false,
	renamedTooltips_enabled = true,
}

if ModOptions and ModOptions.getInstance then
	local settings = ModOptions:getInstance(options, "SmarterStorage", "Smarter Storage")

	local optVanilla = settings:getData("vanillaTooltips_enabled")
	optVanilla.name = "UI_SmarterStorage_Options_Vanilla_Name"
	optVanilla.tooltip = "UI_SmarterStorage_Options_Vanilla_Tooltip"

	local optRenamedTooltips = settings:getData("renamedTooltips_enabled")
	optRenamedTooltips.name = "UI_SmarterStorage_Options_RenamedTooltips_Name"
	optRenamedTooltips.tooltip = "UI_SmarterStorage_Options_RenamedTooltips_Tooltip"

	SetModOptions(options)
end