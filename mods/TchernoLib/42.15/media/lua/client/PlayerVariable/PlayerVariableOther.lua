
--update variables for non local player instances
require 'PlayerVariable/PlayerVariableShared'
PlaVar.remoteSyncCallback = nil

---subscribe to MD
function PlaVar.initGMD()
    ModData.request(PlaVar.MDKey);
end

--- merge subscribed global mod data + set all variables
function PlaVar.OnReceiveGlobalModData(_module, _packet)
    if _module == PlaVar.MDKey then
        if _packet then
            if PlaVar.Verbose then print("Client receives Global mod data update "..tab2str(_module)..' '..tab2str(_packet)) end
            ModData.add(_module, _packet)
            PlaVar.updateOnlinePlayers()--synchro asap for all players
            if PlaVar.remoteSyncCallback == nil and _packet then--there is no such thing as Events.OnOtherPlayerDetected anymore, pull sync instead
                PlaVar.remoteSyncCallback = PlaVar.periodicRemoteSync
                Events.OnTick.Add(PlaVar.periodicRemoteSync)
            end
        else
            if PlaVar.Verbose then print("Client receives Global mod data synchro "..tab2str(_module)..' '..tab2str(_packet)) end
        end
    end
end

--
PlaVar.remoteSyncTicks = 0
function PlaVar.periodicRemoteSync()
    PlaVar.remoteSyncTicks = PlaVar.remoteSyncTicks + 1
    if PlaVar.remoteSyncTicks < PlaVar.SyncPeriod*3 then return end
    PlaVar.remoteSyncTicks = 0
    PlaVar.updateOnlinePlayers()
end


---called on database change
function PlaVar.updateOnlinePlayers()
    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers then
        for i=0, onlinePlayers:size()-1 do
            --Tch: onlinePlayers:get(i) should always work from what I understand. but it does not. so we protect.
            local ok, isoPlayer = pcall(onlinePlayers.get, onlinePlayers, i)
            if not ok then break end
            if isoPlayer and not isoPlayer:isLocalPlayer() then
                PlaVar.updateOtherPlayer(isoPlayer)
            end
        end
    end
end

---this synchro is called both on database change and on player list change
function PlaVar.updateOtherPlayer(isoPlayer)
    if isoPlayer and not isoPlayer:isLocalPlayer() then
        local md = PlaVar.getMD(isoPlayer)
        if md then
            for variable,value in pairs(md) do
                isoPlayer:setVariable(variable,value)
                PlaVar.setPlayerFlag(isoPlayer, variable, value)--propagate flags
                if PlaVar.Verbose then print("PlaVar.updateOtherPlayer update md "..p2str(isoPlayer)..' '..tab2str(variable)..' '..tab2str(value)) end
            end
        else
            if PlaVar.Verbose then print("PlaVar.updateOtherPlayer WARNING md "..tab2str(md)) end
        end
    else
        if PlaVar.Verbose then print("PlaVar.updateOtherPlayer ERROR "..p2str(isoPlayer)) end
    end
end


--- install callbacks
--register the database update callback
Events.OnInitGlobalModData.Add(PlaVar.initGMD)
--set on database update
Events.OnReceiveGlobalModData.Add(PlaVar.OnReceiveGlobalModData)
if isClient() then
--set on other players detection
Events.OnOtherPlayerDetected.Add(PlaVar.updateOtherPlayer)
end
