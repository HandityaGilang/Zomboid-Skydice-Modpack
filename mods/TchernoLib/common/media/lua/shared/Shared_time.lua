
luatime = luatime or {}

--allows to compare world hour data with real-time seconds (for most of anmation like feelings that must be paused)
function luatime.getRealtimeSeconds2WorldHours(sbTime)
    --local realTime2simulatedTime = 1440.0/getGameTime():getMinutesPerDay()
    --local second2hours = 1/3600
    local realTimeS2simTimeH = 0.4/getGameTime():getMinutesPerDay()--==realTime2simulatedTime*second2hours
    return sbTime*realTimeS2simTimeH
end
--allows to compare world hour data with real-time seconds (for most of anmation like feelings that must be paused)
function luatime.getWorldHours2RealtimeSeconds(worldHours)
    local simTimeH2realTimeS = getGameTime():getMinutesPerDay()/0.4
    return worldHours*simTimeH2realTimeS
end
