--Made by SportXAI
--Create time : 2022/12/20  20:10
--Rewrite time : 2023/8/12 19:00
--local defaultRifleSpeed = 1.34
--local defaultPistolSpeed = 1.24
--local _defaultShoveSpeed = 0.80

local function GunStockAttack_ReturnWeaponType(item)
    if item == nil then return end

        if item:IsWeapon() and item:isRanged() then
            if not item:isTwoHandWeapon() then
                return "P" --pistol
            else 
                return "R" --rifle
            end
        end

    return "N"
end

local function Buttstroke_HitZombie(zombie, player)
    if not instanceof (player, "IsoPlayer") then return end
    if player:getVariableBoolean("Bob_BayonetAttack") then return end

    local playerStats = player:getStats()
    local enduranceLost = getSandboxOptions():getOptionByName("ButtstrokeOption.EnduranceLost"):getValue()
    local conditionLost = getSandboxOptions():getOptionByName("ButtstrokeOption.WeaponConditionLost"):getValue()
    local stockDamage = getSandboxOptions():getOptionByName("ButtstrokeOption.Damage"):getValue()
    local weapon = player:getPrimaryHandItem()

    --is weapon on hand
    if weapon == nil then return end
    --not stamp on zombie
    if player:getVariableBoolean("StompAnim") then return end

    if player:isDoShove() and player:isAiming() and player:getVariableBoolean("bShoveAiming") then
        if GunStockAttack_ReturnWeaponType(weapon) == "N" then return end
        triggerEvent("OnWeaponHitCharacter", player, zombie, weapon, (stockDamage / 100) * playerStats:getEndurance())
        zombie:setHealth(zombie:getHealth() - (stockDamage / 100) * playerStats:getEndurance())

        --weapon condition lose
        local fLossChance = (weapon:getConditionLowerChance()) + math.floor(math.floor(player:getPerkLevel(Perks.Maintenance) + (player:getPerkLevel(Perks.Aiming) / 2 )) / 2)
        if ZombRand(fLossChance) == 0 then
            weapon:setCondition(weapon:getCondition() - conditionLost)
        end

        --player endurance lose
        playerStats:setEndurance(playerStats:getEndurance() - enduranceLost)

        --[[Hit type
        if GunStockAttack_ReturnWeaponType(weapon) == "R" then  
            zombie:setVariable("Buttstroke_HitByRifle", true)
        else
            zombie:setVariable("Buttstroke_HitByPistol", true)
        end--]]

        --set variable to play hit sound
        if not player:getEmitter():isPlaying("Buttstroke_Hit") then
            local sound = player:getEmitter():playSound("Buttstroke_Hit")
            player:getEmitter():setVolume(sound, 1.5)
        end

        --add blood
        if zombie:getHealth() <= 0.6 then
            zombie:addBlood(BloodBodyPartType.Head, false, false ,false)
        end

        if zombie:getHealth() <= 0.4 then
            zombie:addBlood(6)
        end
    end
end

Events.OnHitZombie.Add(Buttstroke_HitZombie)