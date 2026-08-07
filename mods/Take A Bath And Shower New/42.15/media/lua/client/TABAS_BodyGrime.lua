local TABAS_BodyGrime = {}

local TABAS_Utils = require("TABAS_Utils")

local FIRST_PHASE = 60
local SECOND_PHASE = 75
local THIRD_PHASE = 90

function TABAS_BodyGrime.updateBodyGrime(character)
    local bloodThreshold = SandboxVars.TakeABathAndShower.BloodToGrimeThreshold
    local dirtThreshold = SandboxVars.TakeABathAndShower.DirtToGrimeThreshold
    local grimeIncBase = SandboxVars.TakeABathAndShower.BodyGrimeIncreasedBase -- default 0.8
    local bdMultiplier = SandboxVars.TakeABathAndShower.BloodAndDirtMultiplier
    local enabledDiscomf = SandboxVars.TakeABathAndShower.GrimeDiscomfort

    local md = character:getModData()
    local grime = md.tabas_BodyGrime or 0
    local blood, dirt = TABAS_Utils.getBodyBloodAndDirt(character)
    if blood < bloodThreshold then
        blood = 0
    else
        blood = blood * 0.01 * bdMultiplier
    end
    if dirt < dirtThreshold then
        dirt = 0
    else
        dirt = dirt * 0.01 * bdMultiplier
    end
    local Increased =  grimeIncBase + blood + dirt
    local nowGrime = math.min(grime + Increased, 100)

    md.tabas_BodyGrime = round(nowGrime, 2)
    character:transmitModData()

    if enabledDiscomf then
        if grime >= THIRD_PHASE then
            TABAS_Utils.addFakeWornItem(character, "TABAS.BodyGrime3", "BodyGrime")
        elseif grime >= SECOND_PHASE then
            TABAS_Utils.addFakeWornItem(character, "TABAS.BodyGrime2", "BodyGrime")
        elseif grime >= FIRST_PHASE then
            TABAS_Utils.addFakeWornItem(character, "TABAS.BodyGrime1", "BodyGrime")
        else
            TABAS_Utils.removeFakeWornItem(character, "BodyGrime")
        end
    end

    if TABAS_Utils.DEBUG_ENABLE then
        TABAS_Utils.debugPrint("Grime Update", string.format("cur=%d, Inc=%f (base=%.2f, blood=%.2f, dirt=%.2f)", md.tabas_BodyGrime, Increased, grimeIncBase, blood, dirt))
        TABAS_Utils.debugPrint("Current Grime", tostring(md.tabas_BodyGrime))
    end

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
    playerObj:getModData().tabas_BodyGrime = value
    TABAS_BodyGrime.updateBodyGrime(playerObj)
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
    local md = playerObj:getModData()
    if not md or md.tabas_BodyGrime then return end

    md.tabas_BodyGrime = ZombRand(0, 30)
    playerObj:transmitModData()
end

local function onClearGrime()
    if SandboxVars.TakeABathAndShower.EnableBodyGrime then return end

    for i=0, getNumActivePlayers()-1 do
        local character = getSpecificPlayer(i)
        if character and character:getModData() then
            character:getModData().tabas_BodyGrime = 0
            character:transmitModData()
            TABAS_Utils.removeFakeWornItem(character, "BodyGrime")
        end
    end
end

Events.EveryHours.Add(everyHoursUpdate)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnGameStart.Add(onClearGrime)
Events.OnFillWorldObjectContextMenu.Add(TABAS_BodyGrime.createDebugMenu)

return TABAS_BodyGrime