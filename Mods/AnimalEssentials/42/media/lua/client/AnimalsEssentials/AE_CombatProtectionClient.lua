local AE_CombatProtectionClient = {}

-- Client-side combat protection handler for universal cat protection
-- Detects damage events and sends server commands for damage mitigation

local function onWeaponHitCharacter(attacker, victim, weapon, damage)
    -- Only process if attacker is a player and victim is an animal
    if not attacker or not victim then return end
    if not instanceof(attacker, "IsoPlayer") then return end
    if not instanceof(victim, "IsoAnimal") then return end
    
    -- Load required modules
    local AnimalRegistry = require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
    local Config = require("AnimalsEssentials/ForModders/AE_MasterConfig")
    
    -- Check if combat protection is enabled
    if not Config.IsSystemEnabled("CombatProtection") then return end
    
    -- Check if victim is a framework animal
    if not AnimalRegistry.IsFrameworkAnimal(victim) then return end
    
    -- Check if victim is a cat (covers all three types: kttr, kttrmanx, smokeykttr)
    local animalCategory = AnimalRegistry.GetAnimalType(victim)
    if animalCategory ~= "cat" then return end
    
    -- Get protection configuration
    local protectionConfig = Config.GetCombatProtectionConfig("cat")
    if not protectionConfig or not protectionConfig.CompleteInvulnerability then return end
    
    -- Check starvation exception if enabled
    if protectionConfig.AllowStarvationDeath then
        local stats = victim:getStats()
        if stats then
            local hunger = stats:getHunger()
            local thirst = stats:getThirst()
            if hunger >= 100 or thirst >= 100 then
                return -- Allow death from starvation/dehydration
            end
        end
    end
    
    -- Send server command for damage mitigation
    sendServerCommand("AE_Protection", "mitigateDamage", {
        animalID = victim:getID(),
        damage = damage
    })
end

function AE_CombatProtectionClient.Initialize()
    -- Register for weapon hit events
    if Events and Events.OnWeaponHitCharacter then
        Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
        print("[AE_CombatProtectionClient] Combat protection initialized")
    else
        print("[AE_CombatProtectionClient] WARNING: OnWeaponHitCharacter event not available")
    end
end

-- Initialize when game starts
Events.OnGameStart.Add(AE_CombatProtectionClient.Initialize)

return AE_CombatProtectionClient