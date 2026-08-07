local Config = require "config/IH_Config"
local Actions = require "gameplay/IH_Actions"
local SandboxSettings = require "config/IH_SandboxSettings"

local SPARK = Config.SPARK

local M = {}

local function buildSparkArgs()
    return {
        dmgMin = SPARK.HAND_DAMAGE_MIN or 6,
        dmgMax = SPARK.HAND_DAMAGE_MAX or 10,
        panicDelta = SPARK.PANIC_DELTA or 20,
        discomfortDelta = SPARK.DISCOMFORT_DELTA or 30,
    }
end

function M.apply(state)
    if not state:hasBatteryCharge() then
        return false
    end

    if isClient() then
        local player = state.playerObj
        local vehicle = player and player:getVehicle() or nil
        sendClientCommand("IH", "SparkApply", {
            vehicleId = vehicle and vehicle:getId() or nil,
        })
        return true
    end

    local args = buildSparkArgs()
    local player = state.playerObj
    local vehicle = player and player:getVehicle() or nil
    Actions.drainBattery(vehicle, SPARK.BATTERY_DRAIN or 3, true)

    Actions.applySparkDamage(player, args)
    Actions.IH_AddAlarmRisk(vehicle, SandboxSettings.ALARM.ADD_SPARK, player)
    return true
end

return M
