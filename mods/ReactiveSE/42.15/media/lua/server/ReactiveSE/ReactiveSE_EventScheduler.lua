--//////////////////////////////////////////////////--
--    Reactive Sound Events - Event Scheduler
--    Cooldown, probability and timing system
--//////////////////////////////////////////////////--

local isSP = not isServer() and not isClient()
if not isServer() and not isSP then return end

local Utils                     = require "ReactiveSE/ReactiveSE_Utils"
local Constants                 = require "ReactiveSE/ReactiveSE_Constants"
local Config                    = require "ReactiveSE/ReactiveSE_Config"

local ReactiveSE_EventScheduler = {}

--//////////////////////////////////////////////////--
--          Probability Management                --
--//////////////////////////////////////////////////--

---Determines if a regular event should occur
---@return boolean
function ReactiveSE_EventScheduler.ShouldTriggerEvent()
    local modData = ReactiveSE_Initialize.GetModData()
    local config = Config.Get()
    local minCD = config.minCD
    local maxCD = config.maxCD

    -- Check minimum cooldown
    if modData.eventCD < minCD then
        Utils.LogInfo("Event cooldown not reached: " .. modData.eventCD .. "/" .. minCD)
        modData.eventCD = modData.eventCD + Constants.Defaults.TICK_INTERVAL
        return false
    end

    -- Force trigger at maximum cooldown (guaranteed event)
    if modData.eventCD >= maxCD then
        Utils.LogInfo("Event forced at max cooldown: " .. modData.eventCD .. "/" .. maxCD)
        modData.eventCD = 0
        modData.eventChance = modData.baseEventChance
        return true
    end

    -- Probability roll
    local triggered = Utils.RollProbability(modData.eventChance)

    if triggered then
        Utils.LogInfo("Event triggered with chance: " .. modData.eventChance .. "%")
        -- Reset values
        modData.eventChance = modData.baseEventChance
        modData.eventCD = 0
        return true
    else
        -- Increment cooldown timer
        modData.eventCD = modData.eventCD + Constants.Defaults.TICK_INTERVAL

        -- Exponential mode: increment probability (capped at MAX_PROBABILITY_CAP)
        if not config.flatProbability then
            local ticksRemaining = (maxCD - minCD) / Constants.Defaults.TICK_INTERVAL
            local increment = (Constants.Defaults.MAX_PROBABILITY_CAP - modData.baseEventChance) / ticksRemaining
            modData.eventChance = Utils.Min(Constants.Defaults.MAX_PROBABILITY_CAP, modData.eventChance + increment)
            Utils.LogInfo("Exponential mode: chance now " .. modData.eventChance .. "%")
        end
        return false
    end
end

---Determines if a weather event should occur
---@return boolean
function ReactiveSE_EventScheduler.ShouldTriggerWeatherEvent()
    local config = Config.Get()

    -- Check if weather events are enabled
    if not config.events or not config.events.Weather then
        return false
    end

    -- Check if it's a rain storm
    local isRainStorm = Utils.IsRainStorm()
    if not isRainStorm then
        return false
    end

    -- Probability roll
    return Utils.RollProbability(Constants.Defaults.WEATHER_EVENT_CHANCE)
end

--//////////////////////////////////////////////////--
--          Status                                 --
--//////////////////////////////////////////////////--

---Gets scheduler status information
---@return table
function ReactiveSE_EventScheduler.GetStatus()
    local modData = ReactiveSE_Initialize.GetModData()
    local config = Config.Get()

    return {
        currentCD = modData.eventCD,
        minCD = config.minCD,
        maxCD = config.maxCD,
        currentChance = modData.eventChance,
        baseChance = modData.baseEventChance,
        totalEvents = modData.totalEvents,
        lastEventType = modData.lastEventType,
        lastEventTime = modData.lastEventTime
    }
end

return ReactiveSE_EventScheduler
