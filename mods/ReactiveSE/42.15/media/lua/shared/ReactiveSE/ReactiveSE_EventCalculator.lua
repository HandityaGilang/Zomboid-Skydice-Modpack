--//////////////////////////////////////////////////--
--    Reactive Sound Events - Event Calculator
--    Event priority calculation system
--//////////////////////////////////////////////////--

local Constants                  = require "ReactiveSE/ReactiveSE_Constants"
local Utils                      = require "ReactiveSE/ReactiveSE_Utils"

local ReactiveSE_EventCalculator = {}

--//////////////////////////////////////////////////--
--          Priority Calculation                  --
--//////////////////////////////////////////////////--

---Gets base priorities
---@param config table
---@return table
local function getBasePriorities(config)
    local priorities = {}

    for eventType, configKey in pairs(Constants.EventConfigMap) do
        local isEnabled = config.events and config.events[eventType]
        priorities[eventType] = isEnabled and
            Constants.ENABLED_EVENT_PRIORITY or
            Constants.DISABLED_EVENT_PRIORITY
    end

    return priorities
end

---Applies time of day modifiers
---@param priorities table
---@param timeOfDay string
local function applyTimeModifiers(priorities, timeOfDay)
    local modifiers = Constants.TimeModifiers[timeOfDay]
    if not modifiers then return end

    for eventType, modifier in pairs(modifiers) do
        if priorities[eventType] then
            priorities[eventType] = priorities[eventType] + modifier
            -- Ensure it doesn't drop below minimum
            priorities[eventType] = Utils.Max(Constants.DISABLED_EVENT_PRIORITY, priorities[eventType])
        end
    end
end

---Applies world age modifiers
---@param priorities table
---@param worldAge integer
local function applyWorldAgeModifiers(priorities, worldAge)
    -- Find appropriate age range
    local applicableRange = nil

    for _, ageRange in pairs(Constants.WorldAgeModifiers) do
        if worldAge <= ageRange.threshold then
            if not applicableRange or ageRange.threshold < applicableRange.threshold then
                applicableRange = ageRange
            end
        end
    end

    if not applicableRange then return end

    -- Apply range modifiers
    for eventType, modifier in pairs(applicableRange.modifiers) do
        if priorities[eventType] then
            priorities[eventType] = priorities[eventType] + modifier
            priorities[eventType] = Utils.Max(Constants.DISABLED_EVENT_PRIORITY, priorities[eventType])
        end
    end
end

---Applies climate modifiers
---@param priorities table
---@param climate string
local function applyClimateModifiers(priorities, climate)
    local modifiers = Constants.ClimateModifiers[climate]
    if not modifiers then return end

    for eventType, modifier in pairs(modifiers) do
        if priorities[eventType] then
            priorities[eventType] = priorities[eventType] + modifier
            priorities[eventType] = Utils.Max(Constants.DISABLED_EVENT_PRIORITY, priorities[eventType])
        end
    end
end

---Applies location modifiers
---@param priorities table
---@param inCity boolean
local function applyLocationModifiers(priorities, inCity)
    local modifiers = inCity and Constants.LocationModifiers.City or Constants.LocationModifiers.Rural

    for eventType, modifier in pairs(modifiers) do
        if priorities[eventType] then
            priorities[eventType] = priorities[eventType] + modifier
            priorities[eventType] = Utils.Max(Constants.DISABLED_EVENT_PRIORITY, priorities[eventType])
        end
    end
end

---Applies player style modifiers
---@param priorities table
---@param playerStyle table
local function applyPlayerStyleModifiers(priorities, playerStyle)
    if not playerStyle.isEnabled then return end

    if playerStyle.isPassive then
        local modifiers = Constants.PlayerStyleModifiers.Passive
        for eventType, modifier in pairs(modifiers) do
            if priorities[eventType] then
                priorities[eventType] = priorities[eventType] + modifier
            end
        end
    end

    if playerStyle.isAggressive then
        local modifiers = Constants.PlayerStyleModifiers.Aggressive
        for eventType, modifier in pairs(modifiers) do
            if priorities[eventType] then
                priorities[eventType] = priorities[eventType] + modifier
                priorities[eventType] = Utils.Max(Constants.DISABLED_EVENT_PRIORITY, priorities[eventType])
            end
        end
    end
end

---Filters and sorts events by priority
---@param priorities table
---@return table
local function filterAndSort(priorities)
    -- Filter only valid events (priority > threshold)
    local validEvents = {}
    for eventType, priority in pairs(priorities) do
        if priority > Constants.MIN_VALID_PRIORITY then
            validEvents[eventType] = priority
        end
    end

    -- If no valid events, find the highest priority one
    if Utils.IsTableEmpty(validEvents) then
        local maxPriority = 0
        local maxEvent = nil

        for eventType, priority in pairs(priorities) do
            if priority > maxPriority then
                maxPriority = priority
                maxEvent = eventType
            end
        end

        if maxEvent then
            return { maxEvent }
        end

        -- Absolute fallback
        return { Constants.EventTypes.ZOMBIE }
    end

    -- Sort by descending priority
    local sortedEvents = {}
    for eventType, _ in pairs(validEvents) do
        table.insert(sortedEvents, eventType)
    end

    table.sort(sortedEvents, function(a, b)
        return validEvents[a] > validEvents[b]
    end)

    return sortedEvents
end

--//////////////////////////////////////////////////--
--          Player Style Calculation              --
--//////////////////////////////////////////////////--

---Calculates player game style
---@param config table
---@param modData table
---@return table
local function calculatePlayerStyle(config, modData)
    local playerStyle = {
        isEnabled = config.playerStyle,
        isAggressive = false,
        isPassive = false
    }

    if not playerStyle.isEnabled then
        return playerStyle
    end

    local worldAge = Utils.GetWorldAge()
    if worldAge <= 0 then worldAge = 1 end

    local kCount = modData.kCount or 0
    local tNoKills = modData.tNoKills or 0

    local aggRatio = Utils.Floor(kCount / worldAge)
    playerStyle.isAggressive = aggRatio >= config.aggKills
    playerStyle.isPassive = tNoKills > config.pasDays

    return playerStyle
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Calculates event priorities based on context
---@param player IsoPlayer
---@param config table
---@param modData table
---@return table Array of types sorted by priority
function ReactiveSE_EventCalculator.CalculatePriorities(player, config, modData)
    if not player then
        Utils.LogWarning("[EventCalculator] No player provided to CalculatePriorities")
        return { Constants.EventTypes.ZOMBIE }
    end

    -- Get game context
    local timeOfDay = Utils.GetTimeOfDay()
    local worldAge = Utils.GetWorldAge()
    local climate = Utils.GetWeather()
    local inCity = Utils.IsPlayerInCity(player)
    local playerStyle = calculatePlayerStyle(config, modData)

    -- Calculate base priorities
    local priorities = getBasePriorities(config)

    -- Apply all modifiers
    applyTimeModifiers(priorities, timeOfDay)
    applyWorldAgeModifiers(priorities, worldAge)
    applyClimateModifiers(priorities, climate)
    applyLocationModifiers(priorities, inCity)
    applyPlayerStyleModifiers(priorities, playerStyle)

    -- Filter and sort
    local sortedEvents = filterAndSort(priorities)

    return sortedEvents
end

---Selects an event type from the priority list
---@param priorityList table
---@param lastEventType string
---@return string primary Primary event type
---@return string secondary Secondary fallback event type
function ReactiveSE_EventCalculator.SelectEventType(priorityList, lastEventType)
    if not priorityList or #priorityList == 0 then
        return Constants.EventTypes.GUNSHOT, Constants.EventTypes.GUNSHOT
    end

    -- Filter the last used event
    local availableEvents = {}
    for i = 1, #priorityList do
        local eventType = priorityList[i]
        if eventType ~= lastEventType then
            table.insert(availableEvents, eventType)
        end
    end

    -- If no other events available, use what is there
    if #availableEvents == 0 then
        availableEvents = priorityList
    end

    -- Weighted selection system
    local roll = ZombRand(100)
    local primary, secondary

    if roll < Constants.EventSelection.FAVORITE_CHANCE and availableEvents[1] then
        primary = availableEvents[1]
        secondary = availableEvents[2] or availableEvents[1]
    elseif roll < (Constants.EventSelection.FAVORITE_CHANCE + Constants.EventSelection.SECOND_CHANCE) and availableEvents[2] then
        primary = availableEvents[2]
        secondary = availableEvents[1] or availableEvents[2]
    else
        local index = ZombRand(1, #availableEvents + 1)
        primary = availableEvents[index] or availableEvents[1]
        -- Secondary is the next one in the list, or first if at end
        secondary = availableEvents[index + 1] or availableEvents[1]
    end

    return primary, secondary
end

return ReactiveSE_EventCalculator
