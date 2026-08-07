
PlaVar = PlaVar or {}
PlaVar.Verbose = false
PlaVar.ModId = 'Variables'
PlaVar.MDKey = PlaVar.ModId--no need to distinguish for now
PlaVar.SyncKey = 'Sync'
PlaVar.SyncPeriod = 10


function PlaVar.getIsoPlayerKey(isoPlayer)
    if isoPlayer and isoPlayer.getUsername then
        return isoPlayer:getUsername()
    else
        print('PlaVar shared getIsoPlayerKey: ERROR '..tab2str(isoPlayer))
    end
    return nil
end

--parses Global Mod Data to retrieve the variable value associated to the isoPlayer
function PlaVar.is(isoPlayer,variable)
    if not variable then return false end
    local struct = PlaVar.getMD(isoPlayer)
    if not struct then return false end
    return struct[variable] or false
end

--parses Global Mod Data to retrieve all variables associated to the isoPlayer
function PlaVar.getMD(isoPlayer)
    local md = ModData.get(PlaVar.MDKey)
    if not md then return nil end
    local playerKey  = PlaVar.getIsoPlayerKey(isoPlayer)
    if not playerKey then return nil end
    return md[playerKey]
end

if isClient() then
    LuaEventManager.AddEvent('OnOtherPlayerDetected')
end
