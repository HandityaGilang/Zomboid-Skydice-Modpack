local HGTS = require("HGTS_Core")

local function HGTS_ServerApply()
    HGTS.applyForCurrentWeather()
end

Events.OnGameStart.Add(HGTS_ServerApply)
Events.OnLoad.Add(HGTS_ServerApply)

if Events.OnWeatherPeriodStart then
    Events.OnWeatherPeriodStart.Add(HGTS_ServerApply)
end