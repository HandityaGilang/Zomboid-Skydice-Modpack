
--ensures the communication is possible with the server using sendClientCommand
require 'PlayerVariable/PlayerVariableShared'

PlaVar.lastRequestTime = nil
PlaVar.sync = {}
PlaVar.isSync = {}
PlaVar.callbackSynchro = {}

function isCmdReady()
    return PlaVar.computeAndGetSync(0)
end

function PlaVar.computeAndGetSync(playerNum)
    if PlaVar.isSync[playerNum] then return true end
    local isoPlayer = getSpecificPlayer(playerNum)
    local syncValue = PlaVar.sync[playerNum]

    if syncValue ~= nil then
        local isSync = PlaVar.is(isoPlayer,PlaVar.SyncKey)
        if isSync == syncValue then
            PlaVar.isSync[playerNum] = true
            PlaVar.callAtResync(playerNum)
            return true
        end
    else
        syncValue = getTimestampMs()
        PlaVar.sync[playerNum] = syncValue
    end
    
    local ts = getTimestampMs()
    if not PlaVar.lastRequestTime or ts - PlaVar.lastRequestTime > PlaVar.SyncPeriod then
        local args = {}
        args[PlaVar.SyncKey] = syncValue
        sendClientCommand(isoPlayer, PlaVar.ModId, PlaVar.SyncKey, args)
        PlaVar.lastRequestTime = ts
    end
    return false
end

function PlaVar.setDesync(playerNum)
    PlaVar.isSync[playerNum] = false;
    PlaVar.sync[playerNum] = nil
end

Events.OnCreatePlayer.Add(function(playerNum, player) PlaVar.setDesync(playerNum) end)


--register (only for next resync)
function PlaVar.onResync(playerNum,func)
    if not PlaVar.callbackSynchro[playerNum] then
        PlaVar.callbackSynchro[playerNum] = {}
    end
    table.insert(PlaVar.callbackSynchro[playerNum], func)
end
--callback stimulation
function PlaVar.callAtResync(playerNum)
    local list = PlaVar.callbackSynchro[playerNum]
    if list then
        for it,func in pairs(list) do
            func(playerNum)
        end
    else
    end
    PlaVar.callbackSynchro[playerNum] = {}--reset
end
