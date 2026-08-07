local HGTS = require("HGTS_Core")
require("HGTS_StormMood_SP")

local function HGTS_ClientApply()
    HGTS.applyForCurrentWeather()
end

HGTS._lastDay = HGTS._lastDay or -1

local function HGTS_ApplyOncePerDay()
    local gt = getGameTime()
    if not gt then return end
    local d = gt:getDay()
    if d ~= HGTS._lastDay then
        HGTS._lastDay = d
        HGTS.applyForCurrentWeather()
    end
end

Events.EveryHours.Add(HGTS_ApplyOncePerDay)
Events.OnGameStart.Add(HGTS_ClientApply)
Events.OnLoad.Add(HGTS_ClientApply)