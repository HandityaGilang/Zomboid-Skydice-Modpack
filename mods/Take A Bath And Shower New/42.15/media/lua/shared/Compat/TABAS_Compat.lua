TABAS_Compat = TABAS_Compat or {}

TABAS_Compat.loaded = false

local loadedMods = {
    BTO = "BathTowelsOverhaul",
    MF = "MoodleFramework",
    WP = "Waterpipes",
    LifeStyle = "LifestyleHobbies",
    RasBodyMod = "rasBodyMod",
    FurryMod = "FurryMod",
    -- Starlit = "StarlitLibrary",
    TABAS_TG = "TakeABathAndShowerTG",
}

local function applyCompatPatches()
    if not TABAS_Compat.loaded then
        TABAS_Compat.loaded = true

        local activeMods = getActivatedMods()
        for key, modDir in pairs(loadedMods) do
            TABAS_Compat[key] = activeMods:contains(modDir)
        end
    end

    local patches = require("Compat/TABAS_WashYourSelf")
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
end

Events.OnGameStart.Add(applyCompatPatches)
Events.OnServerStarted.Add(applyCompatPatches)


function TABAS_Compat.confirmMF(name, playerNum)
    if isServer() then
        return TABAS_Compat.MF
    else
        if TABAS_Compat.MF then
            local moodle = MF.getMoodle(name, playerNum)
            if moodle ~= nil and type(moodle.getValue) == "function" then
                return moodle
            end
        end
    end
    return nil
end
