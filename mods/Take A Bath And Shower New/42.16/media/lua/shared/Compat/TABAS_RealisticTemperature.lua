local TABAS_RealisticTemperature = {}

require "Compat/TABAS_Compat"
local TABAS_BathingBenefits = require("Bathing/TABAS_BathingBenefits")
local TABAS_GameTimes = require("TABAS_GameTimes")

TABAS_RealisticTemperature.originalShouldForceImmediateChilly = nil
TABAS_RealisticTemperature.originalUpdatePlayerBodyTemperature = nil
TABAS_RealisticTemperature.patchedShouldForceImmediateChilly = false
TABAS_RealisticTemperature.patchedBodyTemperatureUpdate = false

local BATHING_WARMTH_PROXIMITY_RATE = 0.35
local BATHING_WARMTH_PROXIMITY_TTL_HOURS = 2.0 / 60.0

local function isBathing(player)
    local md = player and player:getModData()
    if md and md.tabas_IsBathing == true then return true end

    if player:getVariableBoolean("TABAS_TakeBath") and player:getVariableBoolean("TABAS_BathStarted") then
        return true
    end
    if player:getVariableBoolean("TABAS_ShowerStarted") and not player:getVariableBoolean("TABAS_ShowerEnded") then
        return true
    end
    return false
end

local function getBodyTempRecord(player)
    local md = player and player:getModData()
    if not md then return nil end

    md.RC_TempSimBodyTemp = md.RC_TempSimBodyTemp or {}
    return md.RC_TempSimBodyTemp
end

local function getVehicleId(vehicle)
    if not vehicle then return nil end
    return vehicle:getId()
end

local function setBathingWarmthProximity(player, rec)
    local square = player and player.getSquare and player:getSquare()
    if not (square and square.getX and square.getY and square.getZ) then return end

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    local vehicle = player:getVehicle()
    local indoor = square:isInARoom() == true
    local bucketTiles = 1

    if not indoor then
        if vehicle then
            bucketTiles = tonumber(RC_TempSim and RC_TempSim.BODY_TEMP_PROXIMITY_VEHICLE_BUCKET_TILES) or 8
        else
            bucketTiles = tonumber(RC_TempSim and RC_TempSim.BODY_TEMP_PROXIMITY_BUCKET_TILES) or 4
        end
    end

    if bucketTiles > 1 then
        x = math.floor(x / bucketTiles)
        y = math.floor(y / bucketTiles)
    end

    rec._bodyTempProximityCache = {
        x = x,
        y = y,
        z = z,
        inVehicle = vehicle ~= nil,
        vehicleId = getVehicleId(vehicle),
        value = BATHING_WARMTH_PROXIMITY_RATE,
        expiresAtHours = TABAS_GameTimes.getWorldAgeHours() + BATHING_WARMTH_PROXIMITY_TTL_HOURS,
    }
end

local function applyPersistentTemperature(player, temperature)
    if RC_TempSim and RC_TempSim.ThermalAuthorityClient and RC_TempSim.ThermalAuthorityClient.applyPersistentOutcome then
        return RC_TempSim.ThermalAuthorityClient.applyPersistentOutcome(player, { temperature = temperature }, "tabas_bathing")
    end

    local stats = player and player:getStats()
    if stats then
        stats:set(CharacterStat.TEMPERATURE, temperature)
        return true
    end
    return false
end

local function suspendRealisticTemperatureBodyUpdate(player)
    local rec = getBodyTempRecord(player)
    if not rec then return false end

    local nowHours = TABAS_GameTimes.getWorldAgeHours()
    rec._pendingUpdateMinutes = 0
    rec._lastBodyTempUpdateHours = nowHours
    rec._lastBodyTempStableCheckHours = nowHours
    rec._vehicleBodyTempJob = nil
    rec._lastForcedChilly = nil
    setBathingWarmthProximity(player, rec)
    return true
end

local function patchImmediateChillyUpvalue()
    if TABAS_RealisticTemperature.patchedShouldForceImmediateChilly then return true end
    if not (debug and debug.getupvalue and debug.setupvalue) then return false end
    if not (RC_TempSim and type(RC_TempSim._runBodyTemperatureSimulation) == "function") then return false end

    local runner = RC_TempSim._runBodyTemperatureSimulation
    local index = 1
    while true do
        local name, value = debug.getupvalue(runner, index)
        if not name then break end

        if name == "shouldForceImmediateChilly" and type(value) == "function" then
            TABAS_RealisticTemperature.originalShouldForceImmediateChilly = value
            local original = value
            debug.setupvalue(runner, index, function(player, airC, coolingMult, thermalSummary, movementHeat, warmthProx)
                if isBathing(player) then
                    return false
                end
                return original(player, airC, coolingMult, thermalSummary, movementHeat, warmthProx)
            end)
            TABAS_RealisticTemperature.patchedShouldForceImmediateChilly = true
            return true
        end

        index = index + 1
    end

    return false
end

local function patchBodyTemperatureUpdate()
    if TABAS_RealisticTemperature.patchedBodyTemperatureUpdate then return true end
    if not (RC_TempSim and type(RC_TempSim.updatePlayerBodyTemperature) == "function") then return false end

    local original = RC_TempSim.updatePlayerBodyTemperature
    TABAS_RealisticTemperature.originalUpdatePlayerBodyTemperature = original
    RC_TempSim.updatePlayerBodyTemperature = function(player)
        if isBathing(player) then
            suspendRealisticTemperatureBodyUpdate(player)
            return
        end
        return original(player)
    end
    TABAS_RealisticTemperature.patchedBodyTemperatureUpdate = true
    return true
end

local function applyPatches()
    patchImmediateChillyUpvalue()
    patchBodyTemperatureUpdate()
end

function TABAS_RealisticTemperature.applyBathingTemperature(player, waterTemp, minutes, ambientTemp)
    if isServer() and not isClient() then return false end
    applyPatches()

    local rec = getBodyTempRecord(player)
    if not rec then return false end

    rec._lastForcedChilly = nil
    setBathingWarmthProximity(player, rec)

    local stats = player and player:getStats()
    local current = tonumber(rec.core)
    if not current and stats then
        current = stats:get(CharacterStat.TEMPERATURE)
    end
    if not current then return false end

    local target = TABAS_BathingBenefits.getTemperatureTarget(waterTemp, ambientTemp)
    local nextTemp, delta = TABAS_BathingBenefits.stepTemperatureTowards(current, target, minutes)
    if delta == 0 then
        return true
    end

    rec.core = nextTemp
    rec._bodyTempDirty = true
    rec._lastBodyTempStatsApplied = nil

    applyPersistentTemperature(player, nextTemp)
    return true
end

function TABAS_RealisticTemperature.apply()
    applyPatches()
    TABAS_Compat.applyRealisticTemperatureBathingTemperature = function(player, waterTemp, minutes, ambientTemp)
        return TABAS_RealisticTemperature.applyBathingTemperature(player, waterTemp, minutes, ambientTemp)
    end
end

return TABAS_RealisticTemperature
