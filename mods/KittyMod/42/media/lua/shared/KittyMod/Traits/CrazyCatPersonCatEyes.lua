--[[
local function initCrazyCatPersonCatEyesTrait()
    TraitFactory.addTrait(
        "CrazyCatPersonCatEyes",
        getText("UI_trait_NightVision"),
        0,
        getText("UI_trait_NightVisionDesc"),
        false,
        true
    )
end

Events.OnGameBoot.Add(initCrazyCatPersonCatEyesTrait)
--]]