--//////////////////////////////////////////////////--
--    Reactive Sound Events - Player Stats Tracker
--    Efficient tracking and aggregation of world statistics
--//////////////////////////////////////////////////--

local isSP = not isServer() and not isClient()
if not isServer() and not isSP then return end

local ReactiveSE_PlayerStatsTracker = {}

--//////////////////////////////////////////////////--
--          Kill Tracking                         --
--//////////////////////////////////////////////////--

---Executed when a zombie dies
---@param zombie IsoZombie
local function onZombieDead(zombie)
    if not ReactiveSE_State or not ReactiveSE_State.initialized then return end

    local modData = ReactiveSE_Initialize.GetModData()
    modData.kCount = (modData.kCount or 0) + 1

    -- Flags that kills happened today
    modData._killsToday = true
end

--//////////////////////////////////////////////////--
--          Daily Update                          --
--//////////////////////////////////////////////////--

---Executed once per game world day
local function onEveryDay()
    if not ReactiveSE_State or not ReactiveSE_State.initialized then return end

    local modData = ReactiveSE_Initialize.GetModData()

    if modData._killsToday then
        modData.tNoKills = 0
    else
        modData.tNoKills = (modData.tNoKills or 0) + 1
    end

    -- Reset daily flag
    modData._killsToday = false
end

--//////////////////////////////////////////////////--
--          Events                                --
--//////////////////////////////////////////////////--

Events.OnZombieDead.Add(onZombieDead)
Events.EveryDays.Add(onEveryDay)

return ReactiveSE_PlayerStatsTracker
