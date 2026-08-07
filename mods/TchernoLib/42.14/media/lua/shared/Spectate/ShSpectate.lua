Spectate = Spectate or {}
Spectate.Verbose = false
Spectate.ModId = 'Spectate'
Spectate.CmdSpectate = 'Spectate'
Spectate.MDKey = 'Spectate'


function Spectate.getIsoPlayerKey(isoPlayer)
    if isoPlayer then
        return isoPlayer:getUsername()
    end
    return nil
end

function Spectate.isSpectatorOther(isoPlayer)
    local playerKey  = Spectate.getIsoPlayerKey(isoPlayer)
    if not playerKey then return false end
    local md = ModData.get(Spectate.MDKey)
    if not md then return false end
    return md[playerKey] or false
end
