local AE_SummoningSystem = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

function AE_SummoningSystem.findOptimalSpawnPosition(player, x, y, z, radius)
    return x, y, z
end

local function selectWeightedCatVariant()
    local catVariants = {
        "babykitten", "tom", "queen",
        "babykittenmanx", "tommanx", "queenmanx",
        "babysmokeykitten", "smokeyboi", "smokeygirly"
    }
    
    local randomIndex = ZombRand(#catVariants) + 1
    return catVariants[randomIndex]
end

local function getBreedObjectForVariant(animalVariant, animalDef)
    if not animalDef then
        return nil
    end

    if animalVariant == "babysmokeykitten" or animalVariant == "smokeyboi" or animalVariant == "smokeygirly" then
        if animalDef.getBreedByName then
            local breedObj = animalDef:getBreedByName("midnight")
            if breedObj then
                return breedObj
            end
        end
    end

    local breeds = animalDef:getBreeds()
    if breeds and breeds.size and breeds:size() > 0 then
        if breeds.get then
            return breeds:get(0)
        end
    end

    return nil
end

local function performGuaranteedSpawnWithPostSetup(player, x, y, z, radius)
    if AE_EnvironmentDetector.isMultiplayer() and isClient() then
        return { animal = nil }
    end

    local spawnX, spawnY, spawnZ = AE_SummoningSystem.findOptimalSpawnPosition(player, x, y, z, radius)

    local animalVariant = selectWeightedCatVariant()

    if not AnimalDefinitions then
        return { animal = nil }
    end

    local animalDef = AnimalDefinitions.getDef(animalVariant)
    if not animalDef then
        return { animal = nil }
    end

    local breedObj = getBreedObjectForVariant(animalVariant, animalDef)
    if not breedObj then
        return { animal = nil }
    end

    local cell = player:getCell()
    if not cell then
        return { animal = nil }
    end

    local animal = addAnimal(cell, spawnX, spawnY, spawnZ, animalVariant, breedObj)
    if not animal then
        return { animal = nil }
    end

    if animal.addToWorld then
        animal:addToWorld()
    end
    if animal.setHealth then
        animal:setHealth(100)
    end

    local breedName = "unknown"
    if breedObj and breedObj.getName then
        breedName = breedObj:getName()
    end

    return { animal = animal, animalType = animalVariant, breed = breedName }
end


local function ultimateFallbackSpawnWithPostSetup(player, x, y, z)
    if AE_EnvironmentDetector.isMultiplayer() and isClient() then
        return nil
    end
    
    local fallbackVariants = {"tom", "queen", "babykitten"}
    
    for _, animalVariant in ipairs(fallbackVariants) do
        local animalDef = AnimalDefinitions.getDef(animalVariant)
        if animalDef then
            local breeds = animalDef:getBreeds()
            if breeds and breeds:size() > 0 then
                local breed = breeds:get(0)
                local cell = player:getCell()
                if cell then
                    local animal = addAnimal(cell, x, y, z, animalVariant, breed)
                    if animal then
                        if animal.addToWorld then
                            animal:addToWorld()
                        end
                        if animal.setHealth then
                            animal:setHealth(100)
                        end
                        return animal
                    end
                end
            end
        end
    end
    
    return nil
end

function AE_SummoningSystem.summonRandomCat(player, x, y, z, radius)
    if AE_EnvironmentDetector.isMultiplayer() and isClient() then
        return false
    end
    
    if not player then
        return false
    end
    
    local spawnResult = performGuaranteedSpawnWithPostSetup(player, x, y, z, radius)

    if spawnResult and spawnResult.animal then
        return true
    end
    
    local fallbackAnimal = ultimateFallbackSpawnWithPostSetup(player, x, y, z)

    if fallbackAnimal then
        return true
    end
    
    return false
end


return AE_SummoningSystem