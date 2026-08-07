if isClient() then return end

local TABAS_BathingBenefitHandler = {}

TABAS_BathingBenefitHandler.instances = TABAS_BathingBenefitHandler.instances or {}
TABAS_BathingBenefitHandler.onMinuteFunc = TABAS_BathingBenefitHandler.onMinuteFunc

local TABAS_BathingBenefitDriver = require("Bathing/TABAS_BathingBenefitDriver")
local TABAS_Utils = require("TABAS_Utils")

local function hasActiveDrivers()
    for _, _ in pairs(TABAS_BathingBenefitHandler.instances) do
        return true
    end
    return false
end

local function everyOneMinute()
    local drivers = {}
    for _, driver in pairs(TABAS_BathingBenefitHandler.instances) do
        drivers[#drivers + 1] = driver
    end

    for i=1, #drivers do
        local driver = drivers[i]
        if driver and driver:update() == false then
            TABAS_BathingBenefitHandler.instances[driver.playerKey] = nil
        end
    end

    TABAS_BathingBenefitHandler.removeEventHooks()
end

function TABAS_BathingBenefitHandler.start(player, mode, x, y, z)
    if not player then return nil end

    local playerKey = TABAS_Utils.getPlayerKey(player)
    local oldDriver = TABAS_BathingBenefitHandler.instances[playerKey]
    if oldDriver then
        oldDriver:destroy()
    end

    local driver = TABAS_BathingBenefitDriver:new(player, mode, x, y, z)
    if not driver then return nil end

    TABAS_BathingBenefitHandler.instances[playerKey] = driver
    TABAS_BathingBenefitHandler.eventHooks()
    return driver
end

function TABAS_BathingBenefitHandler.stop(player)
    if not player then return end

    local playerKey = TABAS_Utils.getPlayerKey(player)
    local driver = TABAS_BathingBenefitHandler.instances[playerKey]
    if driver then
        driver:destroy()
        TABAS_BathingBenefitHandler.instances[playerKey] = nil
    end

    TABAS_BathingBenefitHandler.removeEventHooks()
end

function TABAS_BathingBenefitHandler.eventHooks()
    if TABAS_BathingBenefitHandler.onMinuteFunc then return end

    TABAS_BathingBenefitHandler.onMinuteFunc = everyOneMinute
    Events.EveryOneMinute.Add(TABAS_BathingBenefitHandler.onMinuteFunc)
end

function TABAS_BathingBenefitHandler.removeEventHooks()
    if not TABAS_BathingBenefitHandler.onMinuteFunc or hasActiveDrivers() then return end

    Events.EveryOneMinute.Remove(TABAS_BathingBenefitHandler.onMinuteFunc)
    TABAS_BathingBenefitHandler.onMinuteFunc = nil
end

return TABAS_BathingBenefitHandler
