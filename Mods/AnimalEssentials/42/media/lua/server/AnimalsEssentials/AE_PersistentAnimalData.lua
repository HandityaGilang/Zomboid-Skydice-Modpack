local AE_PersistentAnimalData = {}
local ANIMAL_REGISTRY_KEY = "AE_AnimalRegistry"

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

function AE_PersistentAnimalData.initialize()
    
    local registry = ModData.getOrCreate(ANIMAL_REGISTRY_KEY)
    if not registry.animals then
        registry.animals = {}
        print("[AE_PersistentAnimalData] Initialized server-side animal registry")
    end
    
    if not registry.playerAnimals then
        registry.playerAnimals = {}
        print("[AE_PersistentAnimalData] Initialized player-animal ownership tracking")
    end
    
    return true
end
function AE_PersistentAnimalData.setData(animalId, key, value, ownerID)
    
    if not animalId or not key then
        print("[AE_PersistentAnimalData] ERROR: Missing animalId or key")
        return false
    end
    
    local registry = ModData.getOrCreate(ANIMAL_REGISTRY_KEY)
    
    if not registry.animals[animalId] then
        registry.animals[animalId] = {}
        print("[AE_PersistentAnimalData] Created new animal entry for ID: " .. tostring(animalId))
    end
    
    registry.animals[animalId][key] = value
    
    if ownerID then
        registry.animals[animalId].ownerID = ownerID
        
        if not registry.playerAnimals[ownerID] then
            registry.playerAnimals[ownerID] = {}
        end
        registry.playerAnimals[ownerID][animalId] = true
    end
    
    ModData.add(ANIMAL_REGISTRY_KEY, registry)
    
    return true
end
function AE_PersistentAnimalData.getData(animalId, key)
    if not animalId or not key then
        print("[AE_PersistentAnimalData] ERROR: Missing animalId or key for getData")
        return nil
    end
    
    local registry = ModData.getOrCreate(ANIMAL_REGISTRY_KEY)
    
    if not registry.animals or not registry.animals[animalId] then
        return nil
    end
    
    return registry.animals[animalId][key]
end
function AE_PersistentAnimalData.getAllData(animalId)
    if not animalId then
        print("[AE_PersistentAnimalData] ERROR: Missing animalId for getAllData")
        return nil
    end
    
    local registry = ModData.getOrCreate(ANIMAL_REGISTRY_KEY)
    
    if not registry.animals or not registry.animals[animalId] then
        return {}
    end
    
    return registry.animals[animalId]
end
function AE_PersistentAnimalData.getPlayerAnimals(playerID)
    if not playerID then
        print("[AE_PersistentAnimalData] ERROR: Missing playerID")
        return {}
    end
    
    local registry = ModData.getOrCreate(ANIMAL_REGISTRY_KEY)
    
    if not registry.playerAnimals or not registry.playerAnimals[playerID] then
        return {}
    end
    
    local animals = {}
    for animalId, _ in pairs(registry.playerAnimals[playerID]) do
        if registry.animals[animalId] then
            animals[animalId] = registry.animals[animalId]
        end
    end
    
    return animals
end
function AE_PersistentAnimalData.removeAnimal(animalId)
    
    if not animalId then
        print("[AE_PersistentAnimalData] ERROR: Missing animalId for removeAnimal")
        return false
    end
    
    local registry = ModData.getOrCreate(ANIMAL_REGISTRY_KEY)
    
    if registry.animals and registry.animals[animalId] then
        local ownerID = registry.animals[animalId].ownerID
        if ownerID and registry.playerAnimals[ownerID] then
            registry.playerAnimals[ownerID][animalId] = nil
        end
        
        registry.animals[animalId] = nil
        
        ModData.add(ANIMAL_REGISTRY_KEY, registry)
        
        print("[AE_PersistentAnimalData] Removed animal data for ID: " .. tostring(animalId))
        return true
    end
    
    return false
end
function AE_PersistentAnimalData.exists(animalId)
    if not animalId then
        return false
    end
    
    local registry = ModData.getOrCreate(ANIMAL_REGISTRY_KEY)
    return registry.animals and registry.animals[animalId] ~= nil
end
function AE_PersistentAnimalData.getStats()
    local registry = ModData.getOrCreate(ANIMAL_REGISTRY_KEY)
    
    local animalCount = 0
    if registry.animals then
        for _ in pairs(registry.animals) do
            animalCount = animalCount + 1
        end
    end
    
    local playerCount = 0
    if registry.playerAnimals then
        for _ in pairs(registry.playerAnimals) do
            playerCount = playerCount + 1
        end
    end
    
    return {
        totalAnimals = animalCount,
        playersWithAnimals = playerCount,
        registryInitialized = registry.animals ~= nil
    }
end
function AE_PersistentAnimalData.isAvailable()
    return true
end
Events.OnServerStarted.Add(function()
    if AE_EnvironmentDetector.isMultiplayer() then
        AE_PersistentAnimalData.initialize()
        local stats = AE_PersistentAnimalData.getStats()
        print("[AE_PersistentAnimalData] MP Server initialized - " .. stats.totalAnimals .. " animals registered")
    end
end)

Events.OnGameStart.Add(function()
    if AE_EnvironmentDetector.isSinglePlayer() then
        AE_PersistentAnimalData.initialize()
        local stats = AE_PersistentAnimalData.getStats()
        print("[AE_PersistentAnimalData] SP initialized - " .. stats.totalAnimals .. " animals registered")
    end
end)

return AE_PersistentAnimalData