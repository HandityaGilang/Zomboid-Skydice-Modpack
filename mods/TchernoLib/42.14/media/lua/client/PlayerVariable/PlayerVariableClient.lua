
require 'PlayerVariable/PlayerVariableShared'
PlaVar.tempMemory = {}

--
function PlaVar.set(isoPlayer, variable, value, forceNetworkUpdate)
    if not isoPlayer then
        print('PlaVar.set ERROR: trying to set nil player.')
        return
    end
    if not isoPlayer:isLocal() then
        print('PlaVar.set ERROR: trying to set non local player.')
        return
    end
    if not isCmdReady() then
        print('PlaVar.set ERROR: no valid connexion yet, message wont be sent.')
        return
    end
    if not variable then
        print('PlaVar.set ERROR: variable unset.')
        return
    end

    local previousValue = nil
    if not forceNetworkUpdate then
        previousValue = PlaVar.getLocal(isoPlayer,variable)--I use string because it works for bool float and string but this is not optimised !
    end
    
    --set locally
    PlaVar.setLocal(isoPlayer,variable,value)

    if not forceNetworkUpdate then
        if previousValue then
            if value ~= previousValue then
                if PlaVar.Verbose then print('PlaVar.set update network: '..p2str(isoPlayer)..'.'..variable..' from '..tab2str(previousValue)..' to '..tab2str(value)..'.') end
                forceNetworkUpdate = true--modified
            end
        else
            if PlaVar.Verbose then print('PlaVar.set create network: '..p2str(isoPlayer)..'.'..variable..' with '..tab2str(value)..'.') end
            forceNetworkUpdate = true--not yet set, set it
        end
    end
    
    if forceNetworkUpdate then
        --set on network
        local args = {}
        args[variable] = value or false
        sendClientCommand(isoPlayer, PlaVar.ModId, variable, args)
        if PlaVar.Verbose then print('PlaVar.sent: '..p2str(isoPlayer)..' '..PlaVar.ModId..' '..variable..' '..tab2str(args)) end
    end
end

--this records the last updated value to compensate for java anim struct not being exposed
function PlaVar.setLocal(isoPlayer, variable, value)
    isoPlayer:setVariable(variable, value)
    PlaVar.setPlayerFlag(isoPlayer, variable, value)--propagate flags
    local key = PlaVar.getIsoPlayerKey(isoPlayer)
    local pmem = PlaVar.tempMemory[key]
    if not pmem then PlaVar.tempMemory[key] = {}; pmem = PlaVar.tempMemory[key] end
    pmem[variable] = value
end

function PlaVar.getLocal(isoPlayer,variable)
    local key = PlaVar.getIsoPlayerKey(isoPlayer)
    local pmem = PlaVar.tempMemory[key]
    if pmem then return pmem[variable] end
    return nil
end


