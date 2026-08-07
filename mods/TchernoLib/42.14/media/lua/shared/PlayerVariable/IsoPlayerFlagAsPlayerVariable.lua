
require 'PlayerVariable/PlayerVariableShared'
PlaVar.flagMap = {}
PlaVar.ZombiesDontAttack = 'zombiesDontAttack'
PlaVar.Invisible = 'm_invisible'
PlaVar.AvoidDamage = 'm_avoidDamage'
PlaVar.GodMode = 'm_godMod'

function PlaVar.addFlag(variable,getFunc,setFunc)
    
    PlaVar.flagMap[variable] = {get=getFunc, set=setFunc}
end

function PlaVar.isPlayerFlag(variable)
    return PlaVar.getPlayerFlagAssociation(variable) ~= nil
end

function PlaVar.getPlayerFlagAssociation(variable)
    if variable then
        return PlaVar.flagMap[variable]
    else
        print('PlaVar.getPlayerFlagAssociation ERROR '..tab2str(variable))
    end
end

function PlaVar.setPlayerFlagFromAssociation(isoPlayer, flagAssoc, value)
    if not flagAssoc then print('PlaVar.setPlayerFlagFromAssociation ERROR missing flagAssoc'); return end
    if not isoPlayer then print('PlaVar.setPlayerFlagFromAssociation ERROR missing isoPlayer'); return end
    --print ('PlaVar.setPlayerFlagFromAssociation '..tab2str(flagAssoc))
    flagAssoc.set(isoPlayer, value)
end

function PlaVar.setPlayerFlag(isoPlayer, variable, value)
    local flagAssoc = PlaVar.getPlayerFlagAssociation(variable)
    if flagAssoc then
        --print ('PlaVar.setPlayerFlag '..p2str(isoPlayer)..' '..tab2str(variable)..' '..tab2str(value)..' '..tab2str(flagAssoc))
        PlaVar.setPlayerFlagFromAssociation(isoPlayer, flagAssoc, value)
    end
end

--I cannot store directly Java functions. I do not know why.
function PlaVar.isZombiesDontAttack(isoPlayer)
    return isoPlayer:isZombiesDontAttack()
end
function PlaVar.setZombiesDontAttack(isoPlayer,value)
    isoPlayer:setZombiesDontAttack(value)
end
function PlaVar.isInvisible(isoPlayer)
    return isoPlayer:isInvisible()
end
function PlaVar.setInvisible(isoPlayer,value)
    isoPlayer:setInvisible(value)
end
function PlaVar.avoidDamage(isoPlayer)
    return isoPlayer:avoidDamage()
end
function PlaVar.setAvoidDamage(isoPlayer,value)
    isoPlayer:setAvoidDamage(value)
end
function PlaVar.isGodMod(isoPlayer)
    return isoPlayer:isGodMod()
end
function PlaVar.setGodMod(isoPlayer,value)
    isoPlayer:setGodMod(value)
end


PlaVar.addFlag(PlaVar.ZombiesDontAttack,PlaVar.isZombiesDontAttack,PlaVar.setZombiesDontAttack)
PlaVar.addFlag(PlaVar.Invisible,PlaVar.isInvisible,PlaVar.setInvisible)
PlaVar.addFlag(PlaVar.AvoidDamage,PlaVar.avoidDamage,PlaVar.setAvoidDamage)
--PlaVar.addFlag(PlaVar.GodMode,PlaVar.isGodMod,PlaVar.setGodMod)
