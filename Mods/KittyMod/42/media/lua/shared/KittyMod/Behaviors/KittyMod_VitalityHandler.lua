local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")

local KittyVitalityHandler = {}
local DEFAULT_BOOSTED_HEALTH = 10000.0
local processedCats = {}

local function getHealthMultiplier()
    local sandboxOptions = SandboxOptions.getInstance()
    if sandboxOptions then
        return sandboxOptions:getDoubleLootRespawn()
    end
    return 1.0
end

function KittyVitalityHandler.applyVitalityToHealth(cat)
    if not cat then return end
    if cat:isDead() then return end
    if not KittyMod_ModData.isCat(cat) then return end
    
    local catID = tostring(cat:getOnlineID())
    if processedCats[catID] then return end
    
    local success, genome = pcall(function() return cat:getGenome() end)
    if success and genome then
        local geneSuccess, vitalityGene = pcall(function() return genome:getGene("vitality") end)
        if geneSuccess and vitalityGene then
            local valueSuccess, vitalityValue = pcall(function() return vitalityGene:getValue() end)
            if valueSuccess and vitalityValue and vitalityValue > 0 then
                local breed = KittyMod_ModData.getCatData(cat, "CatBreed")
                local baseHealthMultiplier = KittyVitalityHandler.getBreedHealthMultiplier(breed)
                
                local baseHealth = 100.0 * vitalityValue * baseHealthMultiplier
                local healthMultiplier = getHealthMultiplier()
                local newMaxHealth = baseHealth * healthMultiplier
                
                cat:setHealth(newMaxHealth)
                processedCats[catID] = true
                return
            end
        end
    end
    
    local breed = KittyMod_ModData.getCatData(cat, "CatBreed")
    local breedHealthMultiplier = KittyVitalityHandler.getBreedHealthMultiplier(breed)
    
    local healthMultiplier = getHealthMultiplier()
    local finalHealth = DEFAULT_BOOSTED_HEALTH * healthMultiplier * breedHealthMultiplier
    
    cat:setHealth(finalHealth)
    processedCats[catID] = true
end

function KittyVitalityHandler.getBreedHealthMultiplier(breed)
    local healthMultipliers = {
        ["Maine Coon"] = 1.2,
        ["Persian"] = 0.9,
        ["British Shorthair"] = 1.1,
        ["Ragdoll"] = 1.05,
        ["Siamese"] = 0.95,
        ["Bengal"] = 1.0,
        ["Russian Blue"] = 1.0,
        ["Scottish Fold"] = 0.9,
        ["Abyssinian"] = 0.95,
        ["Manx"] = 1.0,
        ["Domestic Shorthair"] = 1.0,
        ["Domestic Longhair"] = 1.0
    }
    
    return healthMultipliers[breed] or 1.0
end

function KittyVitalityHandler.onZombieUpdate(zombie)
    if not zombie then return end
    if not instanceof(zombie, "IsoAnimal") then return end
    KittyVitalityHandler.applyVitalityToHealth(zombie)
end

function KittyVitalityHandler.Initialize()
    if Events.OnZombieUpdate then
        Events.OnZombieUpdate.Add(KittyVitalityHandler.onZombieUpdate)
    end
end

Events.OnGameStart.Add(KittyVitalityHandler.Initialize)

return KittyVitalityHandler