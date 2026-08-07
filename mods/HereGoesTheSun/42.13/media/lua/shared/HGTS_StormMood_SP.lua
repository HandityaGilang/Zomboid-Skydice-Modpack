local function IsLocalMode()
    return (isMultiplayer ~= nil) and (isMultiplayer() == false)
end

local function Boot()
    if not IsLocalMode() then return end

    print("[HGTS] StormMood Local runner ENABLED (isMultiplayer=false)")

    local StormMoodCore = require("HGTS_StormMoodCore")

    local function Tick()
        local cm = getClimateManager()
        if not cm then return end
        pcall(function()
            StormMoodCore.TickServer()
        end)
    end

    Events.EveryOneMinute.Add(Tick)
end

Events.OnGameStart.Add(Boot)
