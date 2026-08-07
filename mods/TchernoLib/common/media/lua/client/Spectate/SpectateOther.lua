
require 'Spectate/ShSpectate'

local doSpectateCheckForOtherInvis = false
--- merge subscribed global mod data + start the cycling invis synchronisation loop
function Spectate.OnReceiveGlobalModData(_module, _packet)
    if _module == Spectate.MDKey then
        if _packet then
            if Spectate.Verbose then print("Client receives Global mod data update "..ShGO.getTableString(_module or 'nil')..' '..ShGO.getTableString(_packet or 'nil')) end
            ModData.add(_module, _packet)
            if not doSpectateCheckForOtherInvis then
                doSpectateCheckForOtherInvis = true
                Events.OnPlayerUpdate.Add(Spectate.updateOnlinePlayers)
            end
            Spectate.updateOnlinePlayers()
        else
            if Spectate.Verbose then print("Client receives Global mod data synchro "..ShGO.getTableString(_module or 'nil')..' '..ShGO.getTableString(_packet or 'nil')) end
        end
    end
end

---subscribe to MD
function Spectate.initGMD()
    ModData.request(Spectate.MDKey);
end

function Spectate.updateOnlinePlayers()
    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers then
        local allCorrect = true
        for i=0, onlinePlayers:size()-1 do
            local isoPlayer = onlinePlayers:get(i)
            if isoPlayer and not isoPlayer:isLocalPlayer() then
                local isSpectator = Spectate.isSpectatorOther(isoPlayer) or false
                --if Spectate.Verbose then print("Spectate.updateOnlinePlayers yep "..p2str(isoPlayer)..' '..tostring(isSpectator and 'true' or 'false')) end
                local isThisOneChanged = Spectate.assertSpectatorOther(isoPlayer,isSpectator)
                allCorrect = allCorrect and not isThisOneChanged
            else
                --if Spectate.Verbose then print("Spectate.updateOnlinePlayers nop "..p2str(isoPlayer)) end
            end
        end
        if allCorrect then
            --this also required to reactivate on player connection: too complex
            --doSpectateCheckForOtherInvis = false
            --Events.OnPlayerUpdate.Remove(Spectate.updateOnlinePlayers)
        end
    end
end

--- install callbacks
if isClient() then
Events.OnReceiveGlobalModData.Add(Spectate.OnReceiveGlobalModData)
Events.OnInitGlobalModData.Add(Spectate.initGMD)
end

function Spectate.isSpectatorByMe(isoPlayer)
    return isoPlayer and isoPlayer:isInvisible() or false
end

function Spectate.assertSpectatorOther(isoPlayer,isSpectator)
    if not isoPlayer then return false end

    if not isoPlayer:isGodMod() and not Spectate.isSpectatorByMe(isoPlayer) and isSpectator then--only upfront
        if Spectate.Verbose then print("Spectate.assertSpectatorOther set hide="..b2str(isSpectator)..' '..p2str(isoPlayer)..' '..b2str(Spectate.isSpectatorByMe(isoPlayer))) end
        isSpectator = isSpectator or false
        isoPlayer:setInvisible(isSpectator)
        isoPlayer:setZombiesDontAttack(isSpectator)
        Spectate.setInvisible(isoPlayer,isSpectator)
        return true
    end
    return false
end