local TABAS_WetSystem = {}

local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_Utils = require("TABAS_Utils")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")

local MIN_SET_INTERVAL_MS = 1200

TABAS_WetSystem.cacheData = {}  -- playerNum -> { lastWetSetMs = number }

local function getCache(playerNum)
    local cache = TABAS_WetSystem.cacheData[playerNum]
    if not cache then
        cache = { lastWetSetMs = 0 }
        TABAS_WetSystem.cacheData[playerNum] = cache
    end
    return cache
end

local function nomalWetnessToZero(character, cache)
    local nowMs = getTimestampMs()
    if nowMs - (cache.lastWetSetMs or 0) < MIN_SET_INTERVAL_MS then
        return false
    end

    local stats = character:getStats()
    if not stats then return false end

    local curWet = stats:get(CharacterStat.WETNESS) or 0
    if curWet < 0.1 then
        return false
    end

    cache.lastWetSetMs = nowMs
    TABAS_Utils.decreaseCharacterWetness(character, curWet)
    return true
end

local function clearWetTimers(md)
    if md.tabas_WetEndH == nil and md.tabas_WetGraceEndH == nil then
        return false
    end

    md.tabas_WetEndH = nil
    md.tabas_WetGraceEndH = nil
    return true
end

function TABAS_WetSystem.bathingWetUpdate(character)
    if not character then return end
    local playerNum = character:getPlayerNum()
    if playerNum == nil then return end

    local md = character:getModData()
    if not md then return end

    if TABAS_BathingUtils.hasBathingElapsed(md, TABAS_BathingUtils.getBathingWetDelaySec()) then
        nomalWetnessToZero(character, getCache(playerNum))
        return
    end

    local wetEndH = md.tabas_WetEndH or 0
    local nowH = TABAS_GameTimes.getWorldAgeHours()
    -- expired
    if wetEndH > 0 and wetEndH <= nowH then
        TABAS_Utils.increaseCharacterWetness(character, 45)
        if clearWetTimers(md) then
            character:transmitModData()
        end
        return
    end
    -- unset
    if not wetEndH or wetEndH <= 0 then
        if clearWetTimers(md) then
            character:transmitModData()
        end
        return
    end

    local stats = character:getStats()
    local curWet = (stats and stats:get(CharacterStat.WETNESS)) or 0
    if curWet >= 20 then
        if clearWetTimers(md) then
            character:transmitModData()
        end
    end
end

function TABAS_WetSystem.clearCache(character)
    local playerNum = character:getPlayerNum()
    if playerNum == nil then return end
    TABAS_WetSystem.cacheData[playerNum] = nil
end

Events.OnPlayerUpdate.Add(TABAS_WetSystem.bathingWetUpdate)
Events.OnPlayerDeath.Add(TABAS_WetSystem.clearCache)
