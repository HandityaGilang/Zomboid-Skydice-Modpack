LSKScheduler = LSKScheduler or {}

local Scheduler = LSKScheduler

Scheduler.LANES = Scheduler.LANES or {
    FAST = "5hz",
    NORMAL = "1hz",
    SLOW = "0.1hz",
    GAME_MINUTE = "gameMinute",
}

Scheduler._lanes = Scheduler._lanes or {
    ["5hz"] = { interval = 200, budget = 3, tasks = {}, order = {}, cursor = 1, lastRun = 0, gameDelta = 0 },
    ["1hz"] = { interval = 1000, budget = 5, tasks = {}, order = {}, cursor = 1, lastRun = 0, gameDelta = 0 },
    ["0.1hz"] = { interval = 10000, budget = 8, tasks = {}, order = {}, cursor = 1, lastRun = 0, gameDelta = 0 },
    gameMinute = { interval = false, budget = 8, tasks = {}, order = {}, cursor = 1, lastRun = 0, gameDelta = 0 },
}

Scheduler._metrics = Scheduler._metrics or {
    ticks = 0,
    runs = 0,
    errors = 0,
    skipped = 0,
    deferred = 0,
    lastTickMs = 0,
    maxTickMs = 0,
}

local function getPlayerForTask(task)
    if task.playerIndex ~= nil and getSpecificPlayer then
        return getSpecificPlayer(task.playerIndex)
    end
    if getPlayer then
        return getPlayer()
    end
    return nil
end

local function canRun(task, player)
    if LifestyleSecure and LifestyleSecure.Features
        and LifestyleSecure.Features.IsModActive
        and not LifestyleSecure.Features.IsModActive() then
        return false
    end
    if task.requirePlayer ~= false and not player then
        return false
    end
    if player then
        if task.allowDead ~= true and player.isDead and player:isDead() then
            return false
        end
        if task.allowAsleep ~= true and player.isAsleep and player:isAsleep() then
            return false
        end
    end
    if task.guard and not task.guard(player, task) then
        return false
    end
    return true
end

local function removeFromOrder(lane, id)
    for index = #lane.order, 1, -1 do
        if lane.order[index] == id then
            table.remove(lane.order, index)
            if lane.cursor > index then
                lane.cursor = lane.cursor - 1
            end
        end
    end
    if lane.cursor < 1 or lane.cursor > #lane.order then
        lane.cursor = 1
    end
end

function Scheduler.remove(id)
    if not id then
        return false
    end
    for _, lane in pairs(Scheduler._lanes) do
        if lane.tasks[id] then
            lane.tasks[id] = nil
            removeFromOrder(lane, id)
            return true
        end
    end
    return false
end

function Scheduler.register(id, laneName, callback, options)
    if not id or type(callback) ~= "function" then
        return false
    end
    laneName = laneName or Scheduler.LANES.NORMAL
    local lane = Scheduler._lanes[laneName]
    if not lane then
        return false
    end

    Scheduler.remove(id)
    options = options or {}
    local task = {
        id = id,
        callback = callback,
        playerIndex = options.playerIndex,
        requirePlayer = options.requirePlayer,
        allowDead = options.allowDead,
        allowAsleep = options.allowAsleep,
        guard = options.guard,
        enabled = options.enabled ~= false,
        runs = 0,
        errors = 0,
        skipped = 0,
        lastDurationMs = 0,
        maxDurationMs = 0,
    }
    lane.tasks[id] = task
    table.insert(lane.order, id)
    return task
end

function Scheduler.setEnabled(id, enabled)
    for _, lane in pairs(Scheduler._lanes) do
        local task = lane.tasks[id]
        if task then
            task.enabled = enabled == true
            return true
        end
    end
    return false
end

function Scheduler.getMetrics()
    local result = {}
    for key, value in pairs(Scheduler._metrics) do
        result[key] = value
    end
    result.lanes = {}
    for laneName, lane in pairs(Scheduler._lanes) do
        local laneMetrics = {
            taskCount = #lane.order,
            budget = lane.budget,
            tasks = {},
        }
        for _, id in ipairs(lane.order) do
            local task = lane.tasks[id]
            if task then
                laneMetrics.tasks[id] = {
                    runs = task.runs,
                    errors = task.errors,
                    skipped = task.skipped,
                    lastDurationMs = task.lastDurationMs,
                    maxDurationMs = task.maxDurationMs,
                    enabled = task.enabled,
                }
            end
        end
        result.lanes[laneName] = laneMetrics
    end
    return result
end

local function runLane(laneName, lane, now, elapsedMs)
    local count = #lane.order
    if count == 0 then
        lane.gameDelta = 0
        return
    end

    local started = getTimestampMs()
    local visited = 0
    local gameDelta = lane.gameDelta
    lane.gameDelta = 0

    while visited < count and getTimestampMs() - started < lane.budget do
        if lane.cursor > #lane.order then
            lane.cursor = 1
        end
        local id = lane.order[lane.cursor]
        lane.cursor = lane.cursor + 1
        visited = visited + 1

        local task = lane.tasks[id]
        if task and task.enabled then
            local player = getPlayerForTask(task)
            local guardOk, runnable = pcall(canRun, task, player)
            if guardOk and runnable then
                local taskStart = getTimestampMs()
                local ok, errorMessage = pcall(task.callback, {
                    lane = laneName,
                    nowMs = now,
                    elapsedMs = elapsedMs,
                    deltaGameSeconds = gameDelta,
                    player = player,
                })
                local duration = getTimestampMs() - taskStart
                task.lastDurationMs = duration
                task.maxDurationMs = math.max(task.maxDurationMs, duration)
                task.runs = task.runs + 1
                Scheduler._metrics.runs = Scheduler._metrics.runs + 1
                if not ok then
                    task.errors = task.errors + 1
                    Scheduler._metrics.errors = Scheduler._metrics.errors + 1
                    print("LSKScheduler task error [" .. tostring(id) .. "]: " .. tostring(errorMessage))
                end
            else
                task.skipped = task.skipped + 1
                Scheduler._metrics.skipped = Scheduler._metrics.skipped + 1
                if not guardOk then
                    task.errors = task.errors + 1
                    Scheduler._metrics.errors = Scheduler._metrics.errors + 1
                end
            end
        end
    end

    if visited < count then
        Scheduler._metrics.deferred = Scheduler._metrics.deferred + count - visited
    end
end

local function getGameMinuteStamp()
    local gameTime = getGameTime and getGameTime()
    if not gameTime then
        return nil
    end
    if gameTime.getWorldAgeHours then
        return math.floor(gameTime:getWorldAgeHours() * 60)
    end
    return nil
end

local function dispatch()
    local tickStart = getTimestampMs()
    local now = tickStart
    local gameTime = getGameTime and getGameTime()
    local gameDelta = gameTime and gameTime:getGameWorldSecondsSinceLastUpdate() or 0
    Scheduler._metrics.ticks = Scheduler._metrics.ticks + 1

    for laneName, lane in pairs(Scheduler._lanes) do
        lane.gameDelta = lane.gameDelta + gameDelta
        local due = false
        local elapsedMs = 0
        if lane.interval then
            if lane.lastRun == 0 or now - lane.lastRun >= lane.interval then
                elapsedMs = lane.lastRun == 0 and lane.interval or now - lane.lastRun
                due = true
            end
        else
            local minuteStamp = getGameMinuteStamp()
            if minuteStamp and minuteStamp ~= lane.lastMinute then
                lane.lastMinute = minuteStamp
                elapsedMs = lane.lastRun == 0 and 0 or now - lane.lastRun
                due = true
            end
        end
        if due then
            lane.lastRun = now
            runLane(laneName, lane, now, elapsedMs)
        end
    end

    local duration = getTimestampMs() - tickStart
    Scheduler._metrics.lastTickMs = duration
    Scheduler._metrics.maxTickMs = math.max(Scheduler._metrics.maxTickMs, duration)
end

if not Scheduler._eventInstalled then
    Events.OnTick.Add(dispatch)
    Scheduler._eventInstalled = true
end

return Scheduler
