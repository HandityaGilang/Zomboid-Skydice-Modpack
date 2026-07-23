local AE_SandboxSettings = {}

AE_SandboxSettings.OPTION_KEYS = {
    FRIENDLINESS_MODE = "AE_FriendlinessMode",
    SURVIVAL_MODE = "AE_SurvivalMode",
}

AE_SandboxSettings.DEFAULTS = {
    FRIENDLINESS_MODE = 2,
    SURVIVAL_MODE = 2,
}

AE_SandboxSettings.FRIENDLINESS_MODES = {
    [1] = {
        name = "Lovebug",
        commandSuccessMultiplier = 1.65,
        friendlinessGainMultiplier = 8.0,
        maxTamedAnimals = 6,
        tamingGainMultiplier = 1.0,
        scratchOnFailEnabled = false,
    },
    [2] = {
        name = "Timid",
        commandSuccessMultiplier = 1.0,
        friendlinessGainMultiplier = 1.0,
        maxTamedAnimals = 3,
        tamingGainMultiplier = 1.0,
        scratchOnFailEnabled = false,
    },
    [3] = {
        name = "Asshole",
        commandSuccessMultiplier = 1.0,
        friendlinessGainMultiplier = 0.65,
        maxTamedAnimals = 3,
        tamingGainMultiplier = 0.5,
        scratchOnFailEnabled = true,
    },
}

AE_SandboxSettings.SURVIVAL_MODES = {
    [1] = {
        name = "Godlike",
        maxLives = 99999,
        combatProtectionEnabled = true,
        completeInvulnerability = true,
        healthMultiplier = 90.01,
    },
    [2] = {
        name = "NineLives",
        maxLives = 9,
        combatProtectionEnabled = true,
        completeInvulnerability = true,
        healthMultiplier = 1.0,
    },
    [3] = {
        name = "Realistic",
        maxLives = 1,
        combatProtectionEnabled = false,
        completeInvulnerability = false,
        healthMultiplier = 1.0,
    },
}

function AE_SandboxSettings.GetFriendlinessMode()
    if SandboxVars and SandboxVars.AnimalsEssentials then
        return SandboxVars.AnimalsEssentials.FriendlinessMode or AE_SandboxSettings.DEFAULTS.FRIENDLINESS_MODE
    end
    return AE_SandboxSettings.DEFAULTS.FRIENDLINESS_MODE
end

function AE_SandboxSettings.GetFriendlinessConfig()
    local mode = AE_SandboxSettings.GetFriendlinessMode()
    return AE_SandboxSettings.FRIENDLINESS_MODES[mode] or AE_SandboxSettings.FRIENDLINESS_MODES[2]
end

function AE_SandboxSettings.GetSurvivalMode()
    if SandboxVars and SandboxVars.AnimalsEssentials then
        return SandboxVars.AnimalsEssentials.SurvivalMode or AE_SandboxSettings.DEFAULTS.SURVIVAL_MODE
    end
    return AE_SandboxSettings.DEFAULTS.SURVIVAL_MODE
end

function AE_SandboxSettings.GetSurvivalConfig()
    local mode = AE_SandboxSettings.GetSurvivalMode()
    return AE_SandboxSettings.SURVIVAL_MODES[mode] or AE_SandboxSettings.SURVIVAL_MODES[2]
end

function AE_SandboxSettings.GetCommandSuccessMultiplier()
    return AE_SandboxSettings.GetFriendlinessConfig().commandSuccessMultiplier
end

function AE_SandboxSettings.GetFriendlinessGainMultiplier()
    return AE_SandboxSettings.GetFriendlinessConfig().friendlinessGainMultiplier
end

function AE_SandboxSettings.GetMaxTamedAnimals()
    return AE_SandboxSettings.GetFriendlinessConfig().maxTamedAnimals
end

function AE_SandboxSettings.GetTamingGainMultiplier()
    return AE_SandboxSettings.GetFriendlinessConfig().tamingGainMultiplier
end

function AE_SandboxSettings.IsScratchOnFailEnabled()
    return AE_SandboxSettings.GetFriendlinessConfig().scratchOnFailEnabled
end

function AE_SandboxSettings.GetMaxLives()
    return AE_SandboxSettings.GetSurvivalConfig().maxLives
end

function AE_SandboxSettings.IsCombatProtectionEnabled()
    return AE_SandboxSettings.GetSurvivalConfig().combatProtectionEnabled
end

function AE_SandboxSettings.IsCompleteInvulnerabilityEnabled()
    return AE_SandboxSettings.GetSurvivalConfig().completeInvulnerability
end

function AE_SandboxSettings.GetHealthMultiplier()
    return AE_SandboxSettings.GetSurvivalConfig().healthMultiplier
end

function AE_SandboxSettings.ApplyCatScratch(player)
    if not player or player:isDead() then return false end

    if not AE_SandboxSettings.IsScratchOnFailEnabled() then
        return false
    end

    if ZombRand(100) >= 30 then
        return false
    end
    
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return false end

    local scratchLocations = {
        BodyPart.Hand_L,
        BodyPart.Hand_R,
        BodyPart.ForeArm_L,
        BodyPart.ForeArm_R,
    }
    
    local location = scratchLocations[ZombRand(#scratchLocations) + 1]
    local bodyPart = bodyDamage:getBodyPart(location)
    
    if bodyPart then
        local damage = 1 + ZombRand(3)
        bodyPart:AddDamage(damage)
        bodyPart:AddCut(damage, true, true, true)

        local locationName = ""
        if location == BodyPart.Hand_L then
            locationName = "left hand"
        elseif location == BodyPart.Hand_R then
            locationName = "right hand"
        elseif location == BodyPart.ForeArm_L then
            locationName = "left forearm"
        elseif location == BodyPart.ForeArm_R then
            locationName = "right forearm"
        end
        
        player:Say("Ouch! The cat scratched my " .. locationName .. "!")
        
        return true
    end
    
    return false
end

function AE_SandboxSettings.PrintCurrentSettings()
    local config = AE_SandboxSettings.GetFriendlinessConfig()
end

function AE_SandboxSettings.Initialize()
    AE_SandboxSettings.PrintCurrentSettings()
end

return AE_SandboxSettings