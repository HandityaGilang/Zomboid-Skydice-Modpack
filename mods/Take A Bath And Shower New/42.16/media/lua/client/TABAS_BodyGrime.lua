local TABAS_BodyGrime = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_BodyGrimeUtils = require("TABAS_BodyGrimeUtils")
local TABAS_Moodles = require("TABAS_Moodles")

function TABAS_BodyGrime.updateBodyGrime(character)
    return TABAS_BodyGrimeUtils.updateBodyGrime(character)
end

function TABAS_BodyGrime.createDebugMenu(player, context, worldObjects, test)
    if not TABAS_Utils.DEBUG_ENABLE then return end
    if test and ISWorldObjectContextMenu.Test then return true end
    local mainMenu = context:addOption("Dev: Body Grime Info")
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainMenu, subMenu)
    TABAS_BodyGrime.GrimeInfoMenu(player, subMenu)
end

function TABAS_BodyGrime.GrimeInfoMenu(player, context)
    local playerObj = getSpecificPlayer(player)
    local grime = playerObj:getModData().tabas_BodyGrime or 0
    local currentGrime = round(grime, 4)
    -- Displays current Body Grime
    context:addOption("Current Grime: " .. tostring(currentGrime))
    -- Body Grime to value
    context:addOption("Body Grime + 20", playerObj, TABAS_BodyGrime.forceValue, grime + 20)
    context:addOption("Body Grime to 0", playerObj, TABAS_BodyGrime.forceValue, 0)
    context:addOption("Body Grime to 50", playerObj, TABAS_BodyGrime.forceValue, 50)
    context:addOption("Body Grime to 100", playerObj, TABAS_BodyGrime.forceValue, 100)
end

function TABAS_BodyGrime.forceValue(playerObj, value)
    TABAS_BodyGrimeUtils.setBodyGrime(playerObj, value)
end

local function everyHoursUpdate()
    if not SandboxVars.TakeABathAndShower.EnableBodyGrime then return end
    for i=0, getNumActivePlayers()-1 do
        local character = getSpecificPlayer(i)
        if character then
            TABAS_BodyGrime.updateBodyGrime(character)
        end
    end
end

local function onCreatePlayer(playerNum, player)
    if not SandboxVars.TakeABathAndShower.EnableBodyGrime then return end
    local playerObj = getSpecificPlayer(playerNum)
    TABAS_BodyGrimeUtils.ensureBodyGrime(playerObj)
end

local function onClearGrime()
    if SandboxVars.TakeABathAndShower.EnableBodyGrime then return end

    for i=0, getNumActivePlayers()-1 do
        local character = getSpecificPlayer(i)
        if character then
            TABAS_BodyGrimeUtils.clearBodyGrime(character)
        end
    end
end

function TABAS_BodyGrime.moodleUpdate(player)
    local playerNum = player:getPlayerNum()
    local moodleName = "BodyGrime"

    if not SandboxVars.TakeABathAndShower.EnableBodyGrime or not SandboxVars.TakeABathAndShower.EnableBodyGrimeMoodle then
        TABAS_Moodles.setMFMoodleValue(moodleName, playerNum, 0.5)
        return
    end

    local bodyGrime = player:getModData().tabas_BodyGrime

    if bodyGrime then
        local targetValue = 0.5
        if bodyGrime >= 90 then
            targetValue = 0.1
        elseif bodyGrime >= 75 then
            targetValue = 0.2
        elseif bodyGrime >= 60 then
            targetValue = 0.3
        elseif bodyGrime >= 45 then
            targetValue = 0.3
        end
        TABAS_Moodles.setMFMoodleValue(moodleName, playerNum, targetValue)
    end
end

Events.EveryHours.Add(everyHoursUpdate)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnGameStart.Add(onClearGrime)
Events.OnFillWorldObjectContextMenu.Add(TABAS_BodyGrime.createDebugMenu)
Events.OnPlayerUpdate.Add(TABAS_BodyGrime.moodleUpdate)

return TABAS_BodyGrime
