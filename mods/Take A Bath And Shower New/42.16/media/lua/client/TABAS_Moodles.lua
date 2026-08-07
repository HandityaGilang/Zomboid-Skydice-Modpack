local TABAS_Moodles = {}

local function hasMoodleFramework()
    return MF ~= nil and MF.createMoodle ~= nil and MF.getMoodle ~= nil
end

local function hasMFMoodleData(moodle, name)
    if not moodle or not moodle.char or not moodle.char.getModData then return false end

    local modData = moodle.char:getModData()
    if type(modData) ~= "table" then return false end
    if type(modData.Moodles) ~= "table" then return false end
    if type(modData.Moodles[name]) ~= "table" then return false end

    return true
end

local function isMoodleFrameworkActive()
    local activeMods = getActivatedMods()
    return activeMods ~= nil and activeMods:contains("MoodleFramework")
end

function TABAS_Moodles.getMFMoodle(name, playerNum)
    if not hasMoodleFramework() then return nil end

    local moodle = MF.getMoodle(name, playerNum)
    if moodle == nil then return nil end
    if moodle.getValue == nil or moodle.setValue == nil then return nil end
    if not hasMFMoodleData(moodle, name) then
        if not TABAS_Moodles._mfDataErrorPrinted then
            print("TABAS: Moodle Framework data is unavailable; TABAS moodle update skipped.")
            TABAS_Moodles._mfDataErrorPrinted = true
        end
        return nil
    end
    return moodle
end

function TABAS_Moodles.setMFMoodleValue(name, playerNum, value)
    local moodle = TABAS_Moodles.getMFMoodle(name, playerNum)
    if not moodle then return false end

    moodle:setValue(value)
    return true
end

local function tryRegisterMFMoodles()
    if TABAS_Moodles._registered then return true end

    if not isMoodleFrameworkActive() then return false end

    require "MF_ISMoodle"
    if not hasMoodleFramework() then return false end

    MF.createMoodle("Wet_Bathing")
    MF.createMoodle("CoolingBody")
    MF.createMoodle("WarmingBody")
    MF.createMoodle("FeelingGaze")
    MF.createMoodle("BodyGrime")
    TABAS_Moodles._registered = true
    return true
end

-- MF registers moodles by hooking OnCreatePlayer, so this needs to happen before GameStart.
Events.OnGameBoot.Add(tryRegisterMFMoodles)

return TABAS_Moodles
