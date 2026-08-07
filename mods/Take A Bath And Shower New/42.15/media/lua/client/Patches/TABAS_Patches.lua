local TABAS_Patches = {}

local PATCH_MODULES = {
    "Patches/TABAS_DestoryCursor",
    "Patches/TABAS_OnFluidMenu",
    "Patches/TABAS_DrinkMenu",
    "Patches/TABAS_EscCancel",
    "Patches/TABAS_ISBuildAction",
    "Patches/TABAS_ISPlace3DItemCursor",
    "Patches/TABAS_RadialMenuPatch",
    "Patches/TABAS_TimedActionQueue",
}

function TABAS_Patches.apply()
    if TABAS_Patches._applied then return end
    TABAS_Patches._applied = true

    for i = 1, #PATCH_MODULES do
        local patch = require(PATCH_MODULES[i])
        if patch and patch.apply then
            patch.apply()
        end
    end
end

Events.OnGameStart.Add(TABAS_Patches.apply)

return TABAS_Patches
