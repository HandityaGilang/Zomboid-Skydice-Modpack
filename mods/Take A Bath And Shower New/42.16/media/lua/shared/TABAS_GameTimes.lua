local TABAS_GameTimes = {}

TABAS_GameTimes.GameTime = nil
TABAS_GameTimes.Calendar = nil
TABAS_GameTimes.Calender = nil

function TABAS_GameTimes.getGameTime()
    local gameTime = TABAS_GameTimes.GameTime or getGameTime() or GameTime.getInstance()
    TABAS_GameTimes.GameTime = gameTime
    if gameTime and not TABAS_GameTimes.Calendar then
        TABAS_GameTimes.Calendar = gameTime:getCalender()
        TABAS_GameTimes.Calender = TABAS_GameTimes.Calendar
    end
    return gameTime
end

function TABAS_GameTimes.getCalendar()
    local gameTime = TABAS_GameTimes.getGameTime()
    if gameTime and not TABAS_GameTimes.Calendar then
        TABAS_GameTimes.Calendar = gameTime:getCalender()
        TABAS_GameTimes.Calender = TABAS_GameTimes.Calendar
    end
    return TABAS_GameTimes.Calendar
end

TABAS_GameTimes.getCalender = TABAS_GameTimes.getCalendar

function TABAS_GameTimes.getWorldAgeHours()
    local gameTime = TABAS_GameTimes.getGameTime()
    return gameTime and gameTime:getWorldAgeHours() or 0
end

function TABAS_GameTimes.getWorldAgeMs()
    return TABAS_GameTimes.getWorldAgeHours() * 3600 * 1000
end

function TABAS_GameTimes.getMultiplier()
    local gameTime = TABAS_GameTimes.getGameTime()
    return gameTime and gameTime:getMultiplier() or 1
end

function TABAS_GameTimes.getMinutesPerDay()
    local gameTime = TABAS_GameTimes.getGameTime()
    return gameTime and gameTime:getMinutesPerDay() or 0
end

function TABAS_GameTimes.getRealworldSecondsSinceLastUpdate()
    local gameTime = TABAS_GameTimes.getGameTime()
    return gameTime and gameTime:getRealworldSecondsSinceLastUpdate() or 0
end

Events.OnGameTimeLoaded.Add(function()
    TABAS_GameTimes.GameTime = GameTime.getInstance()
    TABAS_GameTimes.Calendar = TABAS_GameTimes.GameTime and TABAS_GameTimes.GameTime:getCalender() or nil
    TABAS_GameTimes.Calender = TABAS_GameTimes.Calendar
end)

return TABAS_GameTimes
