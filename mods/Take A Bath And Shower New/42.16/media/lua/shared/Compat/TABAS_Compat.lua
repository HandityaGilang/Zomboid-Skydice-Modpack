TABAS_Compat = TABAS_Compat or {}

TABAS_Compat.loaded = false

local loadedMods = {
    BTO = "BathTowelsOverhaul",
    WP = "Waterpipes",
    LifeStyle = "LifestyleHobbies",
    RasBodyMod = "rasBodyMod",
    FurryMod = "FurryMod",
    Starlit = "StarlitLibrary",
    TABAS_TG = "TakeABathAndShowerTG",
    RealisticTemperature = "RC_RealisticColdMod",
    MelosTiles = "melos_tiles_for_miles_pack",
}

function TABAS_Compat.checkLoadedMods()
    local activeMods = getActivatedMods()
    for key, modDir in pairs(loadedMods) do
        TABAS_Compat[key] = activeMods:contains(modDir)
    end
end

function TABAS_Compat.applyRealisticTemperatureBathingTemperature()
    return false
end

local function applyCompatPatches()
    if not TABAS_Compat.loaded then
        TABAS_Compat.loaded = true
        TABAS_Compat.checkLoadedMods()
    end

    local patches = require("Compat/TABAS_WashYourSelf")
    if patches and patches.apply then
        patches.apply()
    end

    patches = require("Compat/TABAS_FluidTransferAction")
    if patches and patches.apply then
        patches.apply()
    end

    if TABAS_Compat.RasBodyMod then
        patches = require("Compat/TABAS_RasBodyMod")
        if patches and patches.apply then
            patches.apply()
        end
    end

    if TABAS_Compat.WP then
        patches = require("Compat/TABAS_WaterPipes")
        if patches and patches.apply then
            patches.apply()
        end
    end

    if TABAS_Compat.LifeStyle then
        patches = require("Compat/TABAS_LifeStyle")
        if patches and patches.apply then
            patches.apply()
        end
    end

    if TABAS_Compat.FurryMod then
        patches = require("Compat/TABAS_FurryMod")
        if patches and patches.apply then
            patches.apply()
        end
    end

    if TABAS_Compat.RealisticTemperature then
        patches = require("Compat/TABAS_RealisticTemperature")
        if patches and patches.apply then
            patches.apply()
        end
    end

    if TABAS_Compat.MelosTiles then
        patches = require("Compat/TABAS_MelosTiles")
        if patches and patches.apply then
            patches.apply()
        end
    end

    local plumbingPatch = require("TABAS_PlumbingPatch")
    if plumbingPatch and plumbingPatch.apply then
        plumbingPatch.apply()
    end
end

Events.OnGameStart.Add(applyCompatPatches)
Events.OnServerStarted.Add(applyCompatPatches)
