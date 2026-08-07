--//////////////////////////////////////////////////--
--    Reactive Sound Events - Utilities
--    Shared helper functions
--//////////////////////////////////////////////////--

local Constants = require "ReactiveSE/ReactiveSE_Constants"

local ReactiveSE_Utils = {}

--//////////////////////////////////////////////////--
--          Math & Clamping Functions             --
--//////////////////////////////////////////////////--

---Limits a value within a range
---@param val number
---@param min number
---@param max number
---@return number
function ReactiveSE_Utils.Clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

---Floors a number
---@param val number
---@return number
function ReactiveSE_Utils.Floor(val)
    return val - val % 1
end

---Absolute value
---@param val number
---@return number
function ReactiveSE_Utils.Abs(val)
    return val < 0 and -val or val
end

---Power
---@param val number
---@param exp number
---@return number
function ReactiveSE_Utils.Pow(val, exp)
    return val ^ exp
end

---Maximum between two values
---@param a number
---@param b number
---@return number
function ReactiveSE_Utils.Max(a, b)
    return a > b and a or b
end

---Minimum between two values
---@param a number
---@param b number
---@return number
function ReactiveSE_Utils.Min(a, b)
    return a < b and a or b
end

---Rounds a number to N decimals
---@param num number
---@param decimals integer
---@return number
function ReactiveSE_Utils.Round(num, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return ReactiveSE_Utils.Floor(num * mult + 0.5) / mult
end

---Linearly interpolates between two values
---@param a number
---@param b number
---@param t number Factor (0-1)
---@return number
function ReactiveSE_Utils.Lerp(a, b, t)
    t = ReactiveSE_Utils.Clamp(t, 0, 1)
    return a + (b - a) * t
end

--//////////////////////////////////////////////////--
--          Probability Functions                 --
--//////////////////////////////////////////////////--

---Calculates if an event with a certain probability should occur
---@param prob integer Probability (0-100)
---@return boolean
function ReactiveSE_Utils.RollProbability(prob)
    if prob <= 0 then return false end
    if prob >= 100 then return true end
    return ZombRand(101) < prob
end

---Generates a random float between min and max
---@param min number
---@param max number
---@return number
function ReactiveSE_Utils.RandomFloat(min, max)
    return min + ZombRandFloat(0, 1) * (max - min)
end

---Generates a random angle in radians
---@return number
function ReactiveSE_Utils.RandomAngle()
    return ReactiveSE_Utils.RandomFloat(-3.14159265, 3.14159265)
end

--//////////////////////////////////////////////////--
--          Distance & Position Functions         --
--//////////////////////////////////////////////////--

---Calculates the distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function ReactiveSE_Utils.GetDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

---Calculates sound position using distance and angle
---@param playerX number
---@param playerY number
---@param distance number
---@param angle number Angle in radians
---@return number x, number y
function ReactiveSE_Utils.CalculateSoundPosition(playerX, playerY, distance, angle)
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    local x = ReactiveSE_Utils.Floor(playerX + distance * cos)
    local y = ReactiveSE_Utils.Floor(playerY + distance * sin)
    return x, y
end

---Finds a valid spawn square near coordinates
---@param x number Center X
---@param y number Center Y
---@param z number Z level
---@param radius number Search radius
---@param attempts number|nil Max attempts (default: 3)
---@return IsoGridSquare|nil sq, number actualX, number actualY
function ReactiveSE_Utils.FindSpawnSquare(x, y, z, radius, attempts)
    attempts = attempts or 3
    for _ = 1, attempts do
        local ox = ZombRand(-radius, radius + 1)
        local oy = ZombRand(-radius, radius + 1)
        local sq = getCell():getGridSquare(x + ox, y + oy, z)
        if sq and sq:isFree(false) then
            return sq, x + ox, y + oy
        end
    end
    return nil, x, y
end

--//////////////////////////////////////////////////--
--          Time Functions                        --
--//////////////////////////////////////////////////--

---Gets world age in days
---@return integer
function ReactiveSE_Utils.GetWorldAge()
    local worldAge = getGameTime():getWorldAgeHours()
    return ReactiveSE_Utils.Floor(worldAge / 24)
end

---Gets current hour of day (0-23)
---@return number
function ReactiveSE_Utils.GetCurrentHour()
    return getGameTime():getTimeOfDay()
end

---Gets current month (0-11)
---@return integer
function ReactiveSE_Utils.GetCurrentMonth()
    return getGameTime():getMonth()
end

---Determines if it is day or night
---@return string "Day" or "Night"
function ReactiveSE_Utils.GetTimeOfDay()
    local month = ReactiveSE_Utils.GetCurrentMonth()
    local hour = ReactiveSE_Utils.GetCurrentHour()

    -- Find current season
    for _, season in pairs(Constants.DayNightSchedule) do
        for i = 1, #season.months do
            local m = season.months[i]
            if m == month then
                local isNight = hour >= season.nightStart or hour < season.nightEnd
                return isNight and "Night" or "Day"
            end
        end
    end

    -- Fallback (should not happen)
    return (hour >= 22 or hour < 6) and "Night" or "Day"
end

--//////////////////////////////////////////////////--
--          Weather Functions                     --
--//////////////////////////////////////////////////--

---Gets current weather state
---@return string "normal" or "extreme"
function ReactiveSE_Utils.GetWeather()
    local climateManager = getClimateManager()
    if not climateManager then return "normal" end

    local rainIntensity = climateManager:getRainIntensity()
    local weatherPeriod = climateManager:getWeatherPeriod()

    if not weatherPeriod then return "normal" end

    local currentStage = weatherPeriod:getCurrentStageID()

    -- Check if extreme weather
    if Constants.ExtremeWeatherIDs[currentStage] or rainIntensity >= Constants.EXTREME_RAIN_THRESHOLD then
        return "extreme"
    end

    return "normal"
end

---Checks if current weather is a rain storm
---@return boolean
function ReactiveSE_Utils.IsRainStorm()
    local climateManager = getClimateManager()
    if not climateManager then return false end

    local rainIntensity = climateManager:getRainIntensity()
    local weatherPeriod = climateManager:getWeatherPeriod()

    if not weatherPeriod then return false end

    local currentStage = weatherPeriod:getCurrentStageID()

    -- Only trigger for rain-based storms (not blizzards)
    if Constants.RainStormIDs[currentStage] then
        return true
    end

    -- Also check rain intensity threshold (excludes snow which has no rain intensity)
    if rainIntensity >= Constants.EXTREME_RAIN_THRESHOLD then
        return true
    end

    return false
end

--//////////////////////////////////////////////////--
--          Player & Location Functions           --
--//////////////////////////////////////////////////--

---Gets the zone type at a specific coordinate (handles unloaded chunks)
---@param x number
---@param y number
---@return string|nil
function ReactiveSE_Utils.GetZoneTypeAt(x, y)
    local cell = getCell()
    if cell then
        local sq = cell:getGridSquare(x, y, 0)
        if sq then
            local zone = sq:getZoneType()
            if zone then return zone end
        end
    end

    -- Fallback to MetaGrid (works for unloaded chunks)
    local metaGrid = getWorld():getMetaGrid()
    if metaGrid then
        local zone = metaGrid:getZoneAt(x, y, 0)
        if zone then
            return zone:getType()
        end
    end

    return nil
end

---Determines if player is in urban zone
---@param player IsoPlayer
---@return boolean
function ReactiveSE_Utils.IsPlayerInCity(player)
    if not player then return false end

    local x = player:getX()
    local y = player:getY()
    local z = player:getZ()
    local cell = player:getCell()

    if not cell then return false end

    local gridSquare = cell:getGridSquare(x, y, z)
    if not gridSquare then return false end

    local zoneType = gridSquare:getZoneType()

    return Constants.UrbanZones[zoneType] or false
end

--//////////////////////////////////////////////////--
--          Multiplayer Functions                 --
--//////////////////////////////////////////////////--

---Gets all active players
---@return table Array of IsoPlayer
function ReactiveSE_Utils.GetAllPlayers()
    local players = {}
    local numPlayers = getNumActivePlayers()

    for i = 0, numPlayers - 1 do
        local player = getSpecificPlayer(i)
        if player then
            table.insert(players, player)
        end
    end

    return players
end

---Gets a reference player for event generation
---@return IsoPlayer|nil
function ReactiveSE_Utils.GetReferencePlayer()
    local modData = ReactiveSE_Initialize.GetModData()
    if not modData then
        return nil
    end

    -- Pure Singleplayer
    if not isServer() and not isClient() then
        return getSpecificPlayer(0)
    end

    -- Multiplayer / Host / Dedicated Server
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers or onlinePlayers:size() == 0 then
        return nil
    end

    local playerCount = onlinePlayers:size()

    -- If there is only one player, use it
    if playerCount == 1 then
        local player = onlinePlayers:get(0)
        modData.lastReferencePlayerId = player:getOnlineID()
        return player
    end

    -- Choose a random one different from the previous one
    local lastId = modData.lastReferencePlayerId
    local candidate
    local attempts = 0

    repeat
        candidate = onlinePlayers:get(ZombRand(playerCount))
        attempts = attempts + 1
    until not lastId
        or candidate:getOnlineID() ~= lastId
        or attempts > 5

    modData.lastReferencePlayerId = candidate:getOnlineID()
    return candidate
end

--//////////////////////////////////////////////////--
--          Item Functions                        --
--//////////////////////////////////////////////////--

---Safely adds an item to a container and syncs in multiplayer
---@param container ItemContainer
---@param itemType string
---@return InventoryItem|nil
function ReactiveSE_Utils.SafeAddItem(container, itemType)
    if not container or not itemType then return nil end
    local item = container:AddItem(itemType)
    if item and isServer() then
        sendAddItemToContainer(container, item)
    end
    return item
end

--//////////////////////////////////////////////////--
--          Table Functions                       --
--//////////////////////////////////////////////////--

---Shallow copy of a table
---@param tbl table
---@return table
function ReactiveSE_Utils.ShallowCopy(tbl)
    if type(tbl) ~= "table" then return tbl end

    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

---Counts the number of elements in a table
---@param tbl table
---@return integer
function ReactiveSE_Utils.TableCount(tbl)
    if type(tbl) ~= "table" then return 0 end

    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

---Checks if a table is empty
---@param tbl table
---@return boolean
function ReactiveSE_Utils.IsTableEmpty(tbl)
    if type(tbl) ~= "table" then
        return true
    end

    for _ in pairs(tbl) do
        return false
    end

    return true
end

--//////////////////////////////////////////////////--
--          Validation Functions                  --
--//////////////////////////////////////////////////--

---Validates that a number is within a range
---@param value number
---@param min number
---@param max number
---@param default number
---@return number
function ReactiveSE_Utils.ValidateRange(value, min, max, default)
    if type(value) ~= "number" then return default end
    if value < min or value > max then return default end
    return value
end

---Validates that a table has all required keys
---@param tbl table
---@param requiredKeys table
---@return boolean
function ReactiveSE_Utils.ValidateTable(tbl, requiredKeys)
    if type(tbl) ~= "table" then return false end

    for i = 1, #requiredKeys do
        local key = requiredKeys[i]
        if tbl[key] == nil then return false end
    end

    return true
end

--//////////////////////////////////////////////////--
--          Logging Functions                     --
--//////////////////////////////////////////////////--

---Prints a log with mod prefix
---@param message string
---@param level string "INFO", "WARN", "ERROR"
function ReactiveSE_Utils.Log(message, level)
    level = level or "INFO"

    -- INFO only if debug is active
    if level == "INFO" then
        local Config = require "ReactiveSE/ReactiveSE_Config"
        if not Config.IsDebug() then
            return
        end
    end

    local prefix = "[" .. Constants.MOD_NAME .. " " .. level .. "]: "
    print(prefix .. tostring(message))
end

---Info log
---@param message string
function ReactiveSE_Utils.LogInfo(message)
    ReactiveSE_Utils.Log(message, "INFO")
end

---Warning log
---@param message string
function ReactiveSE_Utils.LogWarning(message)
    ReactiveSE_Utils.Log(message, "WARN")
end

---Error log
---@param message string
function ReactiveSE_Utils.LogError(message)
    ReactiveSE_Utils.Log(message, "ERROR")
end

--//////////////////////////////////////////////////--
--          Event Execution                       --
--//////////////////////////////////////////////////--

---Executes a full event (sound + reactions)
---@param eventData table
function ReactiveSE_Utils.ExecuteEvent(eventData)
    if not eventData then return end

    -- Try to get local player
    -- getPlayer() returns local player on client/SP/Host
    -- Returns nil on dedicated server
    local player = getPlayer()

    if not player then
        -- If no local player, do nothing (dedicated server or error)
        return
    end

    -- 1. Play sound
    local SoundPlayer = require "ReactiveSE/ReactiveSE_SoundPlayer"
    if SoundPlayer then
        SoundPlayer.PlaySound(eventData)
    end

    -- 2. Apply reactions
    local PlayerReacts = require "ReactiveSE/ReactiveSE_PlayerReactions"
    if PlayerReacts then
        PlayerReacts.Apply(player, eventData)
    end
end

return ReactiveSE_Utils
