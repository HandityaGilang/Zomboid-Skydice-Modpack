--//////////////////////////////////////////////////--
--    REACTIVE SOUND EVENTS - Event Generator
--    Generates and validates sound event data
--//////////////////////////////////////////////////--

local isSP = not isServer() and not isClient()
if not isServer() and not isSP then return end

local Constants                 = require "ReactiveSE/ReactiveSE_Constants"
local Utils                     = require "ReactiveSE/ReactiveSE_Utils"
local Config                    = require "ReactiveSE/ReactiveSE_Config"
local SoundLibrary              = require "ReactiveSE/ReactiveSE_SoundLibrary"
local EventCalculator           = require "ReactiveSE/ReactiveSE_EventCalculator"

local ReactiveSE_EventGenerator = {}

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

---Calculates sound distance using weighted distribution
---@param config table
---@return number
local function calculateSoundDistance(config)
    local minRange   = config.minRange
    local maxRange   = config.maxRange
    local totalRange = maxRange - minRange

    local roll       = ZombRandFloat(0, 100)
    local distance   = minRange

    local dist       = Constants.DistanceDistribution
    local defaults   = Constants.Defaults

    if roll < dist.CLOSE_CHANCE then
        local closeRange = Utils.Floor(totalRange * dist.CLOSE_RATIO)
        distance = minRange + ZombRand(closeRange)
    elseif roll < (dist.CLOSE_CHANCE + dist.MEDIUM_CHANCE) then
        local midStart = Utils.Floor(totalRange * dist.MEDIUM_START)
        local midEnd   = Utils.Floor(totalRange * dist.MEDIUM_END)
        distance       = minRange + midStart + ZombRand(midEnd - midStart)
    else
        local farStart = Utils.Floor(totalRange * dist.FAR_START)
        distance = minRange + farStart + ZombRand(totalRange - farStart)
    end

    return Utils.Min(distance, defaults.MAX_DISTANCE_CAP)
end

---Searches a valid position around the player using angular sweep
---@param player IsoPlayer
---@param distance number
---@param attempts number
---@param blockedZones table
---@param checkBuildings boolean|nil
---@return number|nil, number|nil, string|nil
local function findValidPositionAroundPlayer(player, distance, attempts, blockedZones, checkBuildings)
    if not player then return nil, nil, nil end

    local playerX     = player:getX()
    local playerY     = player:getY()
    local step        = (2 * math.pi) / attempts
    local angleOffset = Utils.RandomAngle()
    local metaGrid    = getWorld():getMetaGrid()

    for i = 1, attempts do
        local angle = angleOffset + (step * i)
        local x, y  = Utils.CalculateSoundPosition(playerX, playerY, distance, angle)
        local zone  = Utils.GetZoneTypeAt(x, y)
        Utils.LogInfo("[EventGenerator] Checking position (" ..
            tostring(x) .. ", " .. tostring(y) .. ")" .. (not zone and " (no zone)" or " (" .. tostring(zone) .. ")"))

        local isValid = true
        if zone and blockedZones[zone] then isValid = false end

        if isValid and checkBuildings then
            if metaGrid:getBuildingAt(x, y) or metaGrid:getRoomAt(x, y, 0) then
                isValid = false
                Utils.LogInfo("[EventGenerator] Position blocked by building/room")
            end
        end

        if isValid then
            Utils.LogInfo("[EventGenerator] Found valid position at (" .. tostring(x) .. ", " .. tostring(y) .. ")")
            return x, y, zone
        end
    end

    Utils.LogInfo("[EventGenerator] No valid position found within sound range")
    return nil, nil, nil
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Generates complete event data
---@param player IsoPlayer
---@param eventType string
---@param fallbackType string|nil Optional fallback event type for zone restrictions
---@return table|nil
function ReactiveSE_EventGenerator.Generate(player, eventType, fallbackType)
    if not player or not eventType then
        Utils.LogWarning("[EventGenerator] Invalid input parameters")
        return nil
    end

    local config           = Config.Get()
    local modData          = ReactiveSE_Initialize.GetModData()
    local eventTypes       = Constants.EventTypes
    local urbanZones       = Constants.UrbanZones
    local blockedZones     = Constants.BlockedZones

    -- Get sound clip
    local clip, newHistory = SoundLibrary.GetClip(eventType, modData.lastClips)
    modData.lastClips      = newHistory

    local distance         = calculateSoundDistance(config)
    local angle            = Utils.RandomAngle()
    local x, y             = Utils.CalculateSoundPosition(
        player:getX(),
        player:getY(),
        distance,
        angle
    )

    local zoneType         = Utils.GetZoneTypeAt(x, y)

    if zoneType and blockedZones[zoneType] then
        local distancesToTry = {
            distance,
            Utils.Floor((config.minRange + config.maxRange) / 2),
            config.maxRange
        }

        local found = false

        for i = 1, #distancesToTry do
            local newX, newY, newZone = findValidPositionAroundPlayer(
                player,
                distancesToTry[i],
                16,
                blockedZones,
                false -- Default behavior for generic blocked zone retry
            )

            if newX and newY then
                x, y     = newX, newY
                zoneType = newZone
                found    = true
                break
            end
        end

        if not found then
            Utils.LogWarning("[EventGenerator] No valid position found within sound range")
            -- TODO: Implement fallback position selection or re-try event later
        end
    end

    if eventType == eventTypes.VEHICLE_CRASH then
        local isUrban = zoneType and urbanZones[zoneType]
        local metaGrid = getWorld():getMetaGrid()
        local isBuilding = metaGrid:getBuildingAt(x, y) or metaGrid:getRoomAt(x, y, 0)

        if not isUrban or isBuilding then
            if not isUrban then
                Utils.LogInfo(
                    "[EventGenerator] VehicleCrash not in urban zone, searching alternative position")
            end
            if isBuilding then
                Utils.LogInfo(
                    "[EventGenerator] VehicleCrash inside building, searching alternative position")
            end

            local distancesToTry = {
                distance,
                Utils.Floor((config.minRange + config.maxRange) / 2),
                config.maxRange
            }

            local foundUrban = false

            for i = 1, #distancesToTry do
                local newX, newY, newZone = findValidPositionAroundPlayer(
                    player,
                    distancesToTry[i],
                    16,
                    {},  -- no blocked zones, we only care about urban/building
                    true -- CHECK BUILDINGS
                )

                if newX and newY and newZone and urbanZones[newZone] then
                    x, y       = newX, newY
                    zoneType   = newZone
                    foundUrban = true
                    Utils.LogInfo("[EventGenerator] VehicleCrash re-located to urban/valid zone at (" ..
                        tostring(x) .. ", " .. tostring(y) .. ")")
                    break
                end
            end

            if not foundUrban then
                local newEventType = fallbackType or eventTypes.GUNSHOT
                Utils.LogInfo("[EventGenerator] No urban position found for VehicleCrash, switching to " .. newEventType)
                eventType = newEventType
                clip, newHistory = SoundLibrary.GetClip(eventType, modData.lastClips)
                modData.lastClips = newHistory
            end
        end
    end

    local eventData       = {
        x           = x,
        y           = y,
        radius      = distance,
        clip        = clip,
        eventType   = eventType,
        timestamp   = os.time(),
        worldAge    = Utils.GetWorldAge(),
        generatedBy = "server"
    }

    -- Update ModData
    modData.lastEventType = eventType
    modData.totalEvents   = modData.totalEvents + 1
    modData.lastEventTime = getGameTime():getWorldAgeHours()

    -- Trigger Scene Registration (Decoupled)
    triggerEvent("OnReactiveSoundEvent", eventData)

    return eventData
end

---Generates a normal event
---@param player IsoPlayer
---@return table|nil
function ReactiveSE_EventGenerator.GenerateNormalEvent(player)
    if not player then return nil end

    local config              = Config.Get()
    local modData             = ReactiveSE_Initialize.GetModData()

    -- Calculate priorities
    local priority            = EventCalculator.CalculatePriorities(player, config, modData)

    -- Select primary and fallback event types
    local eventType, fallback = EventCalculator.SelectEventType(priority, modData.lastEventType)

    return ReactiveSE_EventGenerator.Generate(player, eventType, fallback)
end

---Generates a weather event
---@param player IsoPlayer
---@return table|nil
function ReactiveSE_EventGenerator.GenerateWeatherEvent(player)
    if not player then return nil end
    return ReactiveSE_EventGenerator.Generate(player, Constants.EventTypes.WEATHER)
end

---Validates event data integrity
---@param eventData table
---@return boolean, string|nil
function ReactiveSE_EventGenerator.ValidateEventData(eventData)
    if not eventData then return false, "eventData is nil" end

    local requiredFields = { "x", "y", "radius", "clip", "eventType" }

    for i = 1, #requiredFields do
        if eventData[requiredFields[i]] == nil then
            return false, "Missing required field: " .. requiredFields[i]
        end
    end

    return true, nil
end

return ReactiveSE_EventGenerator
