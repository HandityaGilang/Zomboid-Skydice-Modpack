--//////////////////////////////////////////////////--
--    Reactive Sound Events - Resurrection Manager
--    Handles reanimation of scene corpses
--    when player approaches.
--//////////////////////////////////////////////////--

if isClient() and not isServer() then return end

local Constants = require "ReactiveSE/ReactiveSE_Constants"
local Utils = require "ReactiveSE/ReactiveSE_Utils"

local ReactiveSE_ResurrectionManager = {}

--//////////////////////////////////////////////////--
--          Internal Functions                    --
--//////////////////////////////////////////////////--

---Finds a dead body at the given coordinates
---@param x number
---@param y number
---@param z number
---@return IsoDeadBody|nil
local function findCorpseAt(x, y, z)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return nil end

    local deadBodies = sq:getDeadBodys()
    if deadBodies and deadBodies:size() > 0 then
        local body = deadBodies:get(0)
        return body --[[@as IsoDeadBody]]
    end

    return nil
end

---Triggers reanimation on a corpse
---@param corpse IsoDeadBody
local function reanimateCorpse(corpse)
    if not corpse then return end

    -- Use the native PZ reanimation API
    -- setReanimateTime to current world time triggers immediate reanimation
    local currentTime = getGameTime():getWorldAgeHours()
    corpse:setReanimateTime(currentTime)

    Utils.LogInfo("[ResurrectionManager] Corpse reanimated!")
end

---Processes resurrection logic for a single corpse
---@param corpseData table { x, y, z, triggered, triggeredMinute }
---@param players table Array of IsoPlayer
---@return boolean shouldRemove True if corpse should be removed from tracking
local function processOneCorpse(corpseData, players)
    if not corpseData then return true end
    if not players or #players == 0 then return false end

    local activationDist = Constants.Defaults.SCREAM_ACTIVATION_DISTANCE or 5

    -- Check player proximity
    for i = 1, #players do
        local player = players[i]
        local dist = Utils.GetDistance(player:getX(), player:getY(), corpseData.x, corpseData.y)

        if dist <= activationDist then
            if not corpseData.triggered then
                -- First time player is close - start the timer
                corpseData.triggered = true
                corpseData.triggeredMinute = 0
                Utils.LogInfo("[ResurrectionManager] Player entered range. Starting resurrection timer.")
            else
                -- Already triggered, increment minute counter
                corpseData.triggeredMinute = (corpseData.triggeredMinute or 0) + 1

                -- Check if delay has passed (3-6 minutes, randomized on first trigger)
                if not corpseData.delayMinutes then
                    local minDelay = Constants.Defaults.SCREAM_REANIMATE_DELAY_MIN or 3
                    local maxDelay = Constants.Defaults.SCREAM_REANIMATE_DELAY_MAX or 6
                    corpseData.delayMinutes = ZombRand(minDelay, maxDelay + 1)
                    Utils.LogInfo("[ResurrectionManager] Resurrection delay set to " ..
                        corpseData.delayMinutes .. " minutes")
                end

                if corpseData.triggeredMinute >= corpseData.delayMinutes then
                    -- Time to reanimate!
                    local corpse = findCorpseAt(corpseData.x, corpseData.y, corpseData.z)
                    if corpse then
                        reanimateCorpse(corpse)
                    else
                        Utils.LogWarning("[ResurrectionManager] Could not find corpse at location")
                    end
                    return true -- Remove from tracking
                end
            end
            break -- Only need to check one player being close
        end
    end

    return false
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Filters corpse list based on resurrection chance
---@param corpseDataList table Array of corpse data
---@param isScream boolean If true, all corpses resurrect (100%)
---@return table Filtered list of corpses that will be tracked for resurrection
function ReactiveSE_ResurrectionManager.FilterForResurrection(corpseDataList, isScream)
    if not corpseDataList or #corpseDataList == 0 then
        return {}
    end

    -- Scream scenes: 100% resurrection chance
    if isScream then
        return corpseDataList
    end

    -- Other scenes: flat 25% chance per corpse
    local chance = Constants.Defaults.RESURRECTION_CHANCE or 25
    local filtered = {}

    for i = 1, #corpseDataList do
        if ZombRand(100) < chance then
            table.insert(filtered, corpseDataList[i])
            Utils.LogInfo("[ResurrectionManager] Corpse (" .. i .. ") selected for resurrection (25% roll)")
        end
    end

    return filtered
end

---Processes multiple corpses for resurrection
---@param corpseDataList table Array of { x, y, z, triggered, triggeredMinute }
---@param players table Array of IsoPlayer
---@return table remaining Corpses that should continue being tracked
function ReactiveSE_ResurrectionManager.Process(corpseDataList, players)
    if not corpseDataList or #corpseDataList == 0 then
        return {}
    end

    local remaining = {}
    for i = 1, #corpseDataList do
        local shouldRemove = processOneCorpse(corpseDataList[i], players)
        if not shouldRemove then
            table.insert(remaining, corpseDataList[i])
        end
    end
    return remaining
end

return ReactiveSE_ResurrectionManager
