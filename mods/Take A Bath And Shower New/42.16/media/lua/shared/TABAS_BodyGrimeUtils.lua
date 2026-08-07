local TABAS_BodyGrimeUtils = {}

local TABAS_Utils = require("TABAS_Utils")

local FIRST_PHASE = 60
local SECOND_PHASE = 75
local THIRD_PHASE = 90

local function clampBodyGrime(value)
    return math.max(0, math.min(round(value or 0, 2), 100))
end

function TABAS_BodyGrimeUtils.syncAppearance(character)
    if not character then return 0 end

    local md = character:getModData()
    local grime = (md and md.tabas_BodyGrime) or 0

    if not SandboxVars.TakeABathAndShower.GrimeDiscomfort then
        TABAS_Utils.removeFakeWornItem(character, "BodyGrime")
        return grime
    end

    if grime >= THIRD_PHASE then
        TABAS_Utils.addFakeWornItem(character, "TABAS.BodyGrime3", "BodyGrime")
    elseif grime >= SECOND_PHASE then
        TABAS_Utils.addFakeWornItem(character, "TABAS.BodyGrime2", "BodyGrime")
    elseif grime >= FIRST_PHASE then
        TABAS_Utils.addFakeWornItem(character, "TABAS.BodyGrime1", "BodyGrime")
    else
        TABAS_Utils.removeFakeWornItem(character, "BodyGrime")
    end

    return grime
end

function TABAS_BodyGrimeUtils.setBodyGrime(character, value)
    if not character then return nil end
    if isClient() and not isServer() then
        sendClientCommand("tabas_player", "setBodyGrime", { value = value })
        return nil
    end

    local md = character:getModData()
    if not md then return nil end

    local newValue = clampBodyGrime(value)
    md.tabas_BodyGrime = newValue
    if (isServer() or not isMultiplayer()) then
        character:transmitModData()
    end
    TABAS_BodyGrimeUtils.syncAppearance(character)
    return newValue
end

function TABAS_BodyGrimeUtils.ensureBodyGrime(character)
    if not character then return nil, false end

    local md = character:getModData()
    if not md then return nil, false end

    if md.tabas_BodyGrime ~= nil then
        TABAS_BodyGrimeUtils.syncAppearance(character)
        return md.tabas_BodyGrime, true
    end

    if isClient() and not isServer() then
        sendClientCommand("tabas_player", "ensureBodyGrime", {})
        return nil, false
    end

    local value = ZombRand(0, 30)
    TABAS_BodyGrimeUtils.setBodyGrime(character, value)
    return value, true
end

function TABAS_BodyGrimeUtils.clearBodyGrime(character)
    return TABAS_BodyGrimeUtils.setBodyGrime(character, 0)
end

function TABAS_BodyGrimeUtils.removeBodyGrime(character, amount)
    if not character then return 0 end
    if isClient() and not isServer() then
        sendClientCommand("tabas_player", "removeBodyGrime", { amount = amount })
        return 0
    end

    local md = character:getModData()
    local grime = (md and md.tabas_BodyGrime) or 0
    if grime < 10 or amount == nil or amount <= 0 then
        return 0
    end

    local newValue = math.max(0, grime - amount)
    TABAS_BodyGrimeUtils.setBodyGrime(character, newValue)
    return grime - newValue
end

function TABAS_BodyGrimeUtils.updateBodyGrime(character)
    if not character then return nil end
    if isClient() and not isServer() then
        sendClientCommand("tabas_player", "updateBodyGrime", {})
        return nil
    end

    local bloodThreshold = SandboxVars.TakeABathAndShower.BloodToGrimeThreshold
    local dirtThreshold = SandboxVars.TakeABathAndShower.DirtToGrimeThreshold
    local grimeIncBase = SandboxVars.TakeABathAndShower.BodyGrimeIncreasedBase
    local bdMultiplier = SandboxVars.TakeABathAndShower.BloodAndDirtMultiplier

    local md = character:getModData()
    if not md then return nil end

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

    local increased = grimeIncBase + blood + dirt
    local value = math.min(grime + increased, 100)
    local currentGrime = TABAS_BodyGrimeUtils.setBodyGrime(character, value)

    if TABAS_Utils.DEBUG_ENABLE then
        TABAS_Utils.debugPrint("Grime Update", string.format(
                "cur=%.2f, Inc=%.2f (base=%.2f, blood=%.2f, dirt=%.2f)",
                currentGrime, increased, grimeIncBase, blood, dirt)
            )
    end

    return currentGrime
end

return TABAS_BodyGrimeUtils
