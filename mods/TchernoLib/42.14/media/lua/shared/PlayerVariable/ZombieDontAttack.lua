require 'PlayerVariable/PlayerVariableShared'
local uselessZs = {}
PlaVar.reacZs = false

-- Tried and DOES NOT WORK as an alternative: forcing max discretion (setSneaking(true) +
-- setPerkLevelDebug(Perks.Sneak, 10)) only reduces normal spot chance by up to 52% - not
-- enough, and has no effect at all on the forced spottedLast/bonusSpotTime reacquisition.
function PlaVar.onZombieUpdateDontAttack(isoZombie)
    if not isoZombie:getTarget() then return end
    local isoPlayer = isoZombie:getTarget()

    --unfortunately a zombie is the target of other zombies when a pipe bomb explodes.
    --let's check isoPlayer type with the existence of isLocalPlayer method
    if isoPlayer and isoPlayer.isLocalPlayer and PlaVar.is(isoPlayer,PlaVar.ZombiesDontAttack) then
        local newTarget = PlaVar.getZombieTarget(isoZombie)
        isoZombie:setTarget(newTarget)--replace target

        if newTarget == nil and SandboxVars.TchernoLib.UselessZombies then--no target for now, we need to set useless because internal memory would trigger
            isoZombie:setUseless(true)
            table.insert(uselessZs,isoZombie)
            if not PlaVar.reacZs then
                PlaVar.reacZs = true
                Events.OnTick.Add(PlaVar.reactivateUselessZombies)
            end
        end
    end
end

if Events.OnZombieUpdate then
Events.OnZombieUpdate.Add(PlaVar.onZombieUpdateDontAttack)
end

function PlaVar.reactivateUselessZombies()
    for iterZ = 1, #uselessZs do
        isoZombie = uselessZs[iterZ]
        if isoZombie:isUseless() then
            isoZombie:setUseless(false)
            isoZombie:setTarget(PlaVar.getZombieTarget(isoZombie))
        end
    end
    uselessZs = {}
    if PlaVar.reacZs then
        PlaVar.reacZs = false
        Events.OnTick.Remove(PlaVar.reactivateUselessZombies)
    end
end

--this has no effect because TestZombieSpotPlayer is called from java
-----protects against re-spot + remove closeestZombie distance info
--require 'Override/OverrideJavaPublicMethod'
--Override.patchClassMetaMethod(zombie.characters.IsoPlayer.class,"TestZombieSpotPlayer",function(TestZombieSpotPlayer)
--    return function(...)
--        local args = {...}
--        local isoGameCharacter = args[1]
--        if not PlaVar.is(isoGameCharacter, InfPla.Variable) then
--            TestZombieSpotPlayer(...)
--        end
--    end
--end)

function PlaVar.getZombieTarget(isoZombie)
    local zombieSquare = isoZombie:getSquare()
    if not zombieSquare then return nil end
    
    local playerList = getOnlinePlayers()
    if not playerList then return nil end
    
    
    local listSize = playerList:size();
    local x = isoZombie:getX();
    local y = isoZombie:getY();
    local z = isoZombie:getZ();
    
    local target = nil
    local targetDistance = 20.0F
    
    for objIter = 0, listSize-1 do
        --Tch: onlinePlayers:get(i) should always work from what I understand. but it does not. so we protect.
        local ok, isoPlayer = pcall(playerList.get, playerList, objIter)
        if not ok then break end
        if isoPlayer and isoPlayer:getSquare() and not isoPlayer:isGhostMode() and not PlaVar.is(isoPlayer,PlaVar.ZombiesDontAttack) then
            local playerX = isoPlayer:getX();
            local playerY = isoPlayer:getY();
            local playerZ = isoPlayer:getZ();
            local distance = IsoUtils.DistanceTo(playerX, playerY, x, y);
            if distance < targetDistance and zombieSquare:isCouldSee(isoPlayer:getPlayerNum()) then
                targetDistance = distance
                target = isoPlayer
            end
            --print ('Visible Player Detected ' ..p2str(isoPlayer))
        elseif isoPlayer and isoPlayer.getPlayerNum then
            --print ('Hidden Player Detected ' )
        end
    end
    return target
end

