if isServer() then
    return
end

require "BasementBuilder/BasementBuilder_Core"

BasementBuilder_ClientSync = BasementBuilder_ClientSync or {}

BasementBuilder_ClientSync._syncRetryTicks = BasementBuilder_ClientSync._syncRetryTicks or 0
BasementBuilder_ClientSync._syncRetryActive = BasementBuilder_ClientSync._syncRetryActive or false

local function clearTable(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[deepCopy(k)] = deepCopy(v)
    end
    return copy
end

local function countEntries(t)
    local count = 0
    for _, _ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

function BasementBuilder_ClientSync.refreshGlobalData()
    local data = ModData.getOrCreate(BasementBuilder.MOD_DATA_KEY)
    data.nextId = data.nextId or 1
    data.basements = data.basements or {}
end

function BasementBuilder_ClientSync.applySyncPacket(args)
    local data = ModData.getOrCreate(BasementBuilder.MOD_DATA_KEY)
    clearTable(data)
    data.nextId = args and args.nextId or 1
    data.basements = deepCopy(args and args.basements or {})
    BasementBuilder_ClientSync.stopSyncRetry()
    BasementBuilder.refreshLoadedBasements()
end

function BasementBuilder_ClientSync.requestSync()
    BasementBuilder_ClientSync.refreshGlobalData()
    local playerObj = getSpecificPlayer(0)
    if not playerObj then
        return
    end
    sendClientCommand(playerObj, BasementBuilder.MODULE, "sync", {})
end

function BasementBuilder_ClientSync.beginSyncRetry(ticks)
    BasementBuilder_ClientSync._syncRetryTicks = math.max(BasementBuilder_ClientSync._syncRetryTicks or 0, ticks or 600)
    BasementBuilder_ClientSync._syncRetryActive = true
end

function BasementBuilder_ClientSync.stopSyncRetry()
    BasementBuilder_ClientSync._syncRetryTicks = 0
    BasementBuilder_ClientSync._syncRetryActive = false
end

function BasementBuilder_ClientSync.requestSyncWithRetry()
    BasementBuilder_ClientSync.requestSync()
    BasementBuilder_ClientSync.beginSyncRetry(600)
end

function BasementBuilder_ClientSync.onTick()
    if not BasementBuilder_ClientSync._syncRetryActive then
        return
    end

    local ticksLeft = BasementBuilder_ClientSync._syncRetryTicks or 0
    if ticksLeft <= 0 then
        BasementBuilder_ClientSync.stopSyncRetry()
        return
    end

    BasementBuilder_ClientSync._syncRetryTicks = ticksLeft - 1

    if ticksLeft % 120 ~= 0 then
        return
    end

    local playerObj = getSpecificPlayer(0)
    if not playerObj then
        return
    end

    local data = ModData.getOrCreate(BasementBuilder.MOD_DATA_KEY)
    local hasBasementData = data and data.basements and countEntries(data.basements) > 0
    if hasBasementData then
        BasementBuilder_ClientSync.stopSyncRetry()
        return
    end

    sendClientCommand(playerObj, BasementBuilder.MODULE, "sync", {})
end

function BasementBuilder_ClientSync.onConnected()
    BasementBuilder_ClientSync.requestSyncWithRetry()
end

function BasementBuilder_ClientSync.onServerCommand(module, command, args)
    if module ~= BasementBuilder.MODULE then
        return
    end
    if command == "syncData" then
        BasementBuilder_ClientSync.applySyncPacket(args or {})
        return
    end
end

Events.OnInitGlobalModData.Add(BasementBuilder_ClientSync.refreshGlobalData)
Events.OnConnected.Add(BasementBuilder_ClientSync.onConnected)
Events.OnGameStart.Add(BasementBuilder_ClientSync.requestSyncWithRetry)
Events.OnCreatePlayer.Add(BasementBuilder_ClientSync.requestSyncWithRetry)
Events.OnServerCommand.Add(BasementBuilder_ClientSync.onServerCommand)
Events.OnTick.Add(BasementBuilder_ClientSync.onTick)
