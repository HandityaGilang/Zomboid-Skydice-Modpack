
require 'Movement/WalkSpeedTuningHook'

WalkSpeedTuning = WalkSpeedTuning or {}
WalkSpeedTuning.Verbose = false


if not WalkSpeedTuning.args then--allows single file reload without overriding the configuration. Got me once for some lost hours
    WalkSpeedTuning.args = WalkSpeedTuning.args or {}
    --diverses
    WalkSpeedTuning.args.noSaturateSpeed = false
    WalkSpeedTuning.args.noTemperatureEffect = false
    WalkSpeedTuning.args.noTreeSlowdown = false
    WalkSpeedTuning.args.noEnduranceSlowdown = false
    WalkSpeedTuning.args.noHeavyLoadSlowdown = false

    --injury related
    WalkSpeedTuning.args.inhibitLimping = false
    WalkSpeedTuning.args.noInjurySlowdown = false
    WalkSpeedTuning.args.noBandageSpeedup = false
    WalkSpeedTuning.args.noUpperLeftLegPainSlowdown = false

    --runSpeedModifier related 
    WalkSpeedTuning.args.restrictRunSpeedModifierByItemType = {'InventoryContainer'}--bags only like vanilla
    WalkSpeedTuning.args.runSpeedModifierWalkGain = 0.5F--applied to runSpeedModifier (from equipment, including barefoot malus), that is added to walk speed
    WalkSpeedTuning.args.runSpeedModifierRunGain  = 1.F--applied to runSpeedModifier (from equipment, including barefoot malus), that is multiplied to run speed

    --strafe related
    WalkSpeedTuning.args.noNimbleCapOnStrafeSpeed = false
    WalkSpeedTuning.args.maxSpeedForStrafeSpeed = 1.5F--level 6. to uncap level 10, set it to 1.9F
    WalkSpeedTuning.args.noSpeedCapOnStrafeSpeed = false
    WalkSpeedTuning.args.maxSpeedForStrafeSpeed = 1.0F--only negative impact is taken into account
    WalkSpeedTuning.args.noSaturateStrafeSpeed = false
    WalkSpeedTuning.args.maxStrafeSpeed = 0.6F
    --WalkSpeedTuning.args.noHeavyBreath = false -- needs the right hook for idle
end

WalkSpeedTuning.posX = nil
WalkSpeedTuning.posY = nil
WalkSpeedTuning.refTime = nil
function WalkSpeedTuning.update(isoPlayer)
    if not isoPlayer then isoPlayer = getPlayer() end
    if isoPlayer then
        local beforeInju = 0;
        local beforeWalk = 0;
        if WalkSpeedTuning.Verbose then
            beforeInju = isoPlayer:getVariableFloat("WalkInjury", 0.0F)
            beforeWalk = isoPlayer:getVariableFloat("WalkSpeed" , 0.0F)
        
            local newX = isoPlayer:getX()
            local newY = isoPlayer:getY()
            local newTime = getGameTime():getWorldAgeHours()
            if WalkSpeedTuning.posX and WalkSpeedTuning.posY then
                local deltaTime = luatime.getWorldHours2RealtimeSeconds(newTime - WalkSpeedTuning.refTime)
                if deltaTime > 0 then
                    local deltaX = newX-WalkSpeedTuning.posX
                    local deltaY = newY-WalkSpeedTuning.posY
                    local speedX = deltaX/deltaTime
                    local speedY = deltaY/deltaTime
                    local speed = math.sqrt(speedX*speedX+speedY*speedY)
                    print ('WalkSpeedTuning '..deltaX..', '..deltaY..' for '..deltaTime..' makes '..speed)
                end
            end
            WalkSpeedTuning.posX = newX
            WalkSpeedTuning.posY = newY
            WalkSpeedTuning.refTime = newTime
        end
        
        isoPlayer:setVariable('WalkSpeed',RE.calculateWalkSpeed(isoPlayer,WalkSpeedTuning.args));--includes WalkInjury
        
        if WalkSpeedTuning.Verbose then print ('WalkInjury '..beforeInju..' => '..isoPlayer:getVariableFloat("WalkInjury", 0.0F)) end
        if WalkSpeedTuning.Verbose then print ('WalkSpeed ' ..beforeWalk..' => '..isoPlayer:getVariableFloat("WalkSpeed" , 0.0F)) end
    end
end
