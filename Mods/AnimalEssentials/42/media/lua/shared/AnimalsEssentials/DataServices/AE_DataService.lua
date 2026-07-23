require "AnimalsEssentials/Config/AE_DataConfig"
require "AnimalsEssentials/Communication/AE_NamespaceManager"
require "AnimalsEssentials/Foundation/AE_OperationGuards"

AE_DataService = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

local function getPersistentStorage()
    if AE_EnvironmentDetector.isSinglePlayer() then
        return require("AnimalsEssentials/AE_PersistentAnimalData")
    else
        if not isClient() then
            return require("AnimalsEssentials/AE_PersistentAnimalData")
        end
    end
    return nil
end

function AE_DataService.getTameness(animal)
    if not animal then return 0 end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            local tameness = storage.getData(animalId, "tameness")
            return tameness or 0
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Tameness
    local namespace = "AE_DATA"
    local tameness = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    return tameness or 0
end

function AE_DataService.setTameness(animal, value)
    if not animal or not value then return false end
    
    local clampedValue = math.max(0, math.min(100, value))
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "tameness", clampedValue)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Tameness
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, clampedValue, namespace, "AE_FrameworkData")
end

function AE_DataService.isTamed(animal)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            local isTamed = storage.getData(animalId, "isTamed")
            return isTamed == true
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.IsTamed
    local namespace = "AE_DATA"
    local isTamed = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    return isTamed == true
end

function AE_DataService.setTamed(animal, isTamed)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "isTamed", isTamed)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.IsTamed
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, isTamed, namespace, "AE_FrameworkData")
end

function AE_DataService.getOwner(animal)
    if not animal then return nil end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.getData(animalId, "ownerID")
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Owner
    local namespace = "AE_DATA"
    return AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
end

function AE_DataService.setOwner(animal, ownerID)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "ownerID", ownerID, ownerID)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Owner
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, ownerID, namespace, "AE_FrameworkData")
end

function AE_DataService.getAnimalName(animal)
    if not animal then return nil end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.getData(animalId, "animalName")
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.AnimalName
    local namespace = "AE_DATA"
    return AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
end

function AE_DataService.setAnimalName(animal, name)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "animalName", name)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.AnimalName
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, name, namespace, "AE_FrameworkData")
end

function AE_DataService.getStableID(animal)
    if not animal then return nil end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.getData(animalId, "stableID")
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.StableID
    local namespace = "AE_DATA"
    return AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
end

function AE_DataService.setStableID(animal, stableID)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "stableID", stableID)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.StableID
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, stableID, namespace, "AE_FrameworkData")
end

function AE_DataService.getSlotAssigned(animal)
    if not animal then return nil end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.getData(animalId, "slotAssigned")
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.SlotAssigned
    local namespace = "AE_DATA"
    return AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
end

function AE_DataService.setSlotAssigned(animal, slotAssigned)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "slotAssigned", slotAssigned)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.SlotAssigned
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, slotAssigned, namespace, "AE_FrameworkData")
end

function AE_DataService.getCurrentCommand(animal)
    if not animal then return nil end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.getData(animalId, "currentCommand")
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.CurrentCommand
    local namespace = "AE_CORE"
    return AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
end

function AE_DataService.setCurrentCommand(animal, command)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "currentCommand", command)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.CurrentCommand
    local namespace = "AE_CORE"
    return AE_NamespaceManager.setModData(animal, key, command, namespace, "AE_FrameworkData")
end

function AE_DataService.getBehaviorState(animal)
    if not animal then return nil end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.getData(animalId, "behaviorState")
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.BehaviorState
    local namespace = "AE_CORE"
    return AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
end

function AE_DataService.setBehaviorState(animal, state)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "behaviorState", state)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.BehaviorState
    local namespace = "AE_CORE"
    return AE_NamespaceManager.setModData(animal, key, state, namespace, "AE_FrameworkData")
end

function AE_DataService.getLastPosition(animal)
    if not animal then return nil end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.getData(animalId, "lastPosition")
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.LastPosition
    local namespace = "AE_CORE"
    return AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
end

function AE_DataService.setLastPosition(animal, position)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "lastPosition", position)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.LastPosition
    local namespace = "AE_CORE"
    return AE_NamespaceManager.setModData(animal, key, position, namespace, "AE_FrameworkData")
end

function AE_DataService.getHunger(animal)
    if not animal then return 0 end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            local hunger = storage.getData(animalId, "hunger")
            return hunger or 0
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Hunger
    local namespace = "AE_DATA"
    local hunger = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    return hunger or 0
end

function AE_DataService.setHunger(animal, value)
    if not animal or not value then return false end
    
    local clampedValue = math.max(0, math.min(100, value))
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "hunger", clampedValue)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Hunger
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, clampedValue, namespace, "AE_FrameworkData")
end

function AE_DataService.getThirst(animal)
    if not animal then return 0 end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            local thirst = storage.getData(animalId, "thirst")
            return thirst or 0
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Thirst
    local namespace = "AE_DATA"
    local thirst = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    return thirst or 0
end

function AE_DataService.setThirst(animal, value)
    if not animal or not value then return false end
    
    local clampedValue = math.max(0, math.min(100, value))
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "thirst", clampedValue)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Thirst
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, clampedValue, namespace, "AE_FrameworkData")
end

function AE_DataService.getHealth(animal)
    if not animal then return 0 end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            local health = storage.getData(animalId, "health")
            return health or 0
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Health
    local namespace = "AE_DATA"
    local health = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    return health or 0
end

function AE_DataService.setHealth(animal, value)
    if not animal or not value then return false end
    
    local clampedValue = math.max(0, math.min(100, value))
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "health", clampedValue)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Health
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, clampedValue, namespace, "AE_FrameworkData")
end

function AE_DataService.getEquipment(animal)
    if not animal then return {} end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            local equipment = storage.getData(animalId, "equipment")
            return equipment or {}
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Equipment
    local namespace = "AE_DATA"
    local equipment = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    return equipment or {}
end

function AE_DataService.setEquipment(animal, equipment)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "equipment", equipment or {})
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Equipment
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, equipment or {}, namespace, "AE_FrameworkData")
end

function AE_DataService.getAttachments(animal)
    if not animal then return {} end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            local attachments = storage.getData(animalId, "attachments")
            return attachments or {}
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Attachments
    local namespace = "AE_CORE"
    local attachments = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    return attachments or {}
end

function AE_DataService.setAttachments(animal, attachments)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "attachments", attachments or {})
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Attachments
    local namespace = "AE_CORE"
    return AE_NamespaceManager.setModData(animal, key, attachments or {}, namespace, "AE_FrameworkData")
end

function AE_DataService.getBreed(animal)
    if not animal then return nil end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.getData(animalId, "breed")
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Breed
    local namespace = "AE_DATA"
    return AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
end

function AE_DataService.setBreed(animal, breed)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "breed", breed)
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Breed
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, breed, namespace, "AE_FrameworkData")
end

function AE_DataService.getGenetics(animal)
    if not animal then return {} end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            local genetics = storage.getData(animalId, "genetics")
            return genetics or {}
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Genetics
    local namespace = "AE_DATA"
    local genetics = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    return genetics or {}
end

function AE_DataService.setGenetics(animal, genetics)
    if not animal then return false end
    
    local storage = getPersistentStorage()
    if storage then
        local animalId = animal:getAnimalID()
        if animalId then
            return storage.setData(animalId, "genetics", genetics or {})
        end
    end
    
    local key = AE_DataConfig.ModDataKeys.Genetics
    local namespace = "AE_DATA"
    return AE_NamespaceManager.setModData(animal, key, genetics or {}, namespace, "AE_FrameworkData")
end

function AE_DataService.isAnimalValid(animal)
    if not animal then return false end

    local success, exists = pcall(function()
        return animal:isExistInTheWorld()
    end)
    if not success or not exists then
        return false
    end

    local success2, isDead = pcall(function()
        return animal:isDead()
    end)
    if not success2 then
        return false
    end
    if isDead then
        return false
    end

    return true
end

function AE_DataService.getAllModData(animal)
    if not animal then return nil end

    return {
        tameness = AE_DataService.getTameness(animal),
        isTamed = AE_DataService.isTamed(animal),
        owner = AE_DataService.getOwner(animal),
        animalName = AE_DataService.getAnimalName(animal),
        stableID = AE_DataService.getStableID(animal),
        slotAssigned = AE_DataService.getSlotAssigned(animal),
        currentCommand = AE_DataService.getCurrentCommand(animal),
        behaviorState = AE_DataService.getBehaviorState(animal),
        lastPosition = AE_DataService.getLastPosition(animal),
        hunger = AE_DataService.getHunger(animal),
        thirst = AE_DataService.getThirst(animal),
        health = AE_DataService.getHealth(animal),
        equipment = AE_DataService.getEquipment(animal),
        attachments = AE_DataService.getAttachments(animal),
        breed = AE_DataService.getBreed(animal),
        genetics = AE_DataService.getGenetics(animal)
    }
end

return AE_DataService