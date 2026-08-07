require "MF_ISMoodle"

local TABAS_Moodles = {}

local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")

local function tryRegisterMFMoodles()
    if not MF or type(MF.createMoodle) ~= "function" then return false end
    MF.createMoodle("Wet_Bathing")
    MF.createMoodle("CoolingBody")
    MF.createMoodle("WarmingBody")
    MF.createMoodle("FeelingGaze")
    MF.createMoodle("BodyGrime")
    return true
end
Events.OnGameBoot.Add(tryRegisterMFMoodles)

local function remainingSec(endH)
    if not endH or endH <= 0 then return 0 end
    local sec = (endH - TABAS_GameTimes.getWorldAgeHours()) * 3600
    if sec <= 0 then return 0 end
    return sec
end

local function setIfChanged(moodle, value)
    if not moodle then return end
    local cur = moodle:getValue()
    if cur ~= value then
        moodle:setValue(value)
    end
end

function TABAS_Moodles.update(character)
    if not MF or not character then return end

    local md = character:getModData()
    if not md or not md.Moodles or not md.Moodles.Wet_Bathing then return end

    local playerNum = character:getPlayerNum()
    if playerNum == nil then return end

    local wetMoodle = MF.getMoodle("Wet_Bathing", playerNum)
    local cooling = MF.getMoodle("CoolingBody", playerNum)
    local warming = MF.getMoodle("WarmingBody", playerNum)
    local feelingGaze = MF.getMoodle("FeelingGaze", playerNum)
    local moodleGrime = MF.getMoodle("BodyGrime", playerNum)

    -- Wet_Bathing
    if wetMoodle ~= nil then
        local bathingActive = TABAS_BathingUtils.hasBathingElapsed(md, TABAS_BathingUtils.getBathingWetDelaySec())

        if bathingActive then
            setIfChanged(wetMoodle, 1.0)
        else
            local wetSec = remainingSec(md.tabas_WetEndH)
            local afterGraceSec = remainingSec(md.tabas_WetGraceEndH)
            if afterGraceSec > 0 then
                setIfChanged(wetMoodle, 1.0)
            elseif wetSec > 0 then
                local value = (wetSec <= 240) and 0.6 or 0.7
                setIfChanged(wetMoodle, value)
            else
                setIfChanged(wetMoodle, 0.5)
            end
        end
    end

    if not md.tabas_IsBathing then
        if cooling ~= nil and cooling:getValue() > 0.5 then cooling:setValue(0.5) end
        if warming ~= nil and warming:getValue() > 0.5 then warming:setValue(0.5) end
        if feelingGaze ~= nil and feelingGaze:getValue() < 0.5 then feelingGaze:setValue(0.5) end
    end

    -- Body Grime 
    local enableGrime = SandboxVars.TakeABathAndShower.EnableBodyGrime
        and SandboxVars.TakeABathAndShower.EnableBodyGrimeMoodle

    local bodyGrime = md.tabas_BodyGrime

    if enableGrime then
        if moodleGrime ~= nil and bodyGrime then
            if bodyGrime >= 90 then
                moodleGrime:setValue(0.1)
            elseif bodyGrime >= 75 then
                moodleGrime:setValue(0.2)
            elseif bodyGrime >= 60 then
                moodleGrime:setValue(0.3)
            elseif bodyGrime >= 45 then
                moodleGrime:setValue(0.3)
            elseif moodleGrime:getValue() ~= 0.5 then
                moodleGrime:setValue(0.5)
            end
        end
    elseif moodleGrime ~= nil and moodleGrime:getValue() ~= 0.5 then
        moodleGrime:setValue(0.5)
    end
end

-- local function TABASMoodlesUpdate()
--     for i = 0, getNumActivePlayers() - 1 do
--         local character = getSpecificPlayer(i)
--         if character then
--             TABAS_Moodles.update(character)
--         end
--     end
-- end

Events.OnPlayerUpdate.Add(TABAS_Moodles.update)

return TABAS_Moodles
