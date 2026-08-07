local KittyMod_Core = {}
local CatRegistry = {}
local isInitialized = false

local CatDefinitions = {
    breeds = {
        "Domestic Shorthair", "Domestic Longhair", "Siamese", "Persian", 
        "Maine Coon", "British Shorthair", "Russian Blue", "Ragdoll",
        "Manx", "Scottish Fold", "Bengal", "Abyssinian"
    },
    genetics = {
        furLength = {"short", "medium", "long"},
        patterns = {"solid", "tabby", "calico", "tortoiseshell", "bicolor", "pointed"},
        colors = {"black", "white", "gray", "orange", "brown", "cream", "silver"},
        eyeColors = {"green", "blue", "amber", "hazel", "odd-eyed"}
    },
    personalities = {
        "playful", "lazy", "curious", "shy", "aggressive", 
        "friendly", "independent", "clingy", "hunter", "sleepy"
    }
}

function KittyMod_Core.initialize()
    if isInitialized then return true end
    KittyMod_Core.initializeCats()
    Events.OnCreateLivingCharacter.Add(KittyMod_Core.onAnimalCreated)
    Events.OnGameStart.Add(KittyMod_Core.onGameStart)
    isInitialized = true
    return true
end

function KittyMod_Core.initializeCats()
    for _, breed in ipairs(CatDefinitions.breeds) do
        CatRegistry[breed] = {
            breed = breed,
            tamingDifficulty = KittyMod_Core.getCatTamingDifficulty(breed),
            specialTraits = KittyMod_Core.getCatTraits(breed),
            baseStats = KittyMod_Core.getCatBaseStats(breed)
        }
    end
    if KittyMod_Core.isFrameworkAvailable() then
        KittyMod_Core.registerWithFramework()
    else
    end
    
    return true
end

function KittyMod_Core.onAnimalCreated(animal)
    if not animal or not animal:isAnimal() then return end
    local animalType = animal:getAnimalType()
    if animalType == "cat" then
        local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
        local breed = KittyMod_Core.selectRandomBreed()
        KittyMod_ModData.initializeCatData(animal, breed)
    end
end

function KittyMod_Core.isFrameworkAvailable()
    local success, framework = pcall(function()
        return require("AnimalsEssentials/AE_FrameworkBridge")
    end)
    if success and framework and framework.isAvailable then
        return framework.isAvailable()
    end
    return false
end

function KittyMod_Core.registerWithFramework()
    if not KittyMod_Core.isFrameworkAvailable() then return false end
    
    sendServerCommand("AE_UIFramework", "componentRegistration", {
        registrationType = "animalMod",
        modName = "KittyMod",
        version = "1.0",
        animalTypes = {"cat"},
        modDataPrefix = "KITTY_",
        definitions = CatDefinitions,
        registry = CatRegistry,
        behaviorHandlers = {
            onTamingComplete = "KittyMod_Behaviors.onCatTamed",
            onInteraction = "KittyMod_Behaviors.onPlayerCatInteraction",
            onDeath = "KittyMod_Behaviors.onCatDeath"
        },
        uiHandlers = {
            statusDisplay = "KittyMod_UI.getCatStatusInfo",
            contextMenu = "KittyMod_UI.addCatContextMenuOptions"
        }
    })
    return true
end

function KittyMod_Core.selectRandomBreed()
    return CatDefinitions.breeds[ZombRand(1, #CatDefinitions.breeds + 1)]
end

function KittyMod_Core.getCatTamingDifficulty(breed)
    local difficultyMap = {
        ["Domestic Shorthair"] = "easy",
        ["Domestic Longhair"] = "easy", 
        ["Siamese"] = "medium",
        ["Manx"] = "medium",
    }
    
    return difficultyMap[breed] or "medium"
end

function KittyMod_Core.getCatTraits(breed)
    local traitMap = {
        ["Domestic Shorthair"] = {"adaptable", "friendly"},
        ["Domestic Longhair"] = {"calm", "gentle"},
        ["Siamese"] = {"vocal", "intelligent", "social"},
        ["Persian"] = {"quiet", "gentle", "docile"},
        ["Maine Coon"] = {"large", "gentle_giant", "dog_like"},
        ["British Shorthair"] = {"independent", "calm"},
        ["Russian Blue"] = {"shy", "loyal", "intelligent"},
        ["Ragdoll"] = {"docile", "relaxed", "affectionate"},
        ["Manx"] = {"playful", "dog_like", "intelligent"},
        ["Scottish Fold"] = {"sweet", "calm", "owl_like"},
        ["Bengal"] = {"active", "wild", "intelligent"},
        ["Abyssinian"] = {"active", "curious", "playful"}
    }
    return traitMap[breed] or {"friendly"}
end

function KittyMod_Core.getCatBaseStats(breed)
    local statsMap = {
        ["Domestic Shorthair"] = {health = 100, agility = 80, intelligence = 70},
        ["Domestic Longhair"] = {health = 95, agility = 75, intelligence = 70},
        ["Siamese"] = {health = 90, agility = 85, intelligence = 90},
        ["Persian"] = {health = 85, agility = 60, intelligence = 75},
        ["Maine Coon"] = {health = 120, agility = 70, intelligence = 80},
        ["British Shorthair"] = {health = 110, agility = 65, intelligence = 75},
        ["Russian Blue"] = {health = 95, agility = 85, intelligence = 85},
        ["Ragdoll"] = {health = 105, agility = 60, intelligence = 70},
        ["Manx"] = {health = 100, agility = 90, intelligence = 85},
        ["Scottish Fold"] = {health = 90, agility = 70, intelligence = 80},
        ["Bengal"] = {health = 95, agility = 95, intelligence = 90},
        ["Abyssinian"] = {health = 90, agility = 90, intelligence = 85}
    }
    return statsMap[breed] or {health = 100, agility = 75, intelligence = 75}
end

function KittyMod_Core.getCatRegistry()
    return CatRegistry
end

function KittyMod_Core.getCatDefinitions()
    return CatDefinitions
end

function KittyMod_Core.isInitialized()
    return isInitialized
end

Events.OnGameStart.Add(KittyMod_Core.initialize)

return KittyMod_Core