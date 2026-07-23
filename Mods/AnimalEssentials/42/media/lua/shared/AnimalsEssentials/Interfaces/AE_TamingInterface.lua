require "AnimalsEssentials/DataServices/AE_DataService"
require "AnimalsEssentials/Foundation/AE_OperationGuards"

local function loadTamingSystemSafely()
    local success, tamingSystem = pcall(function()
        return require("AnimalsEssentials/Taming/AE_TamingSystem")
    end)
    return success and tamingSystem or nil
end

AE_TamingInterface = {}

-- Interface layer for taming operations to eliminate circular dependencies
-- Provides shared taming functionality without requiring direct TamingSystem dependency

function AE_TamingInterface.makeAnimalTamed(animal)
    if not AE_DataService.isAnimalValid(animal) then
        return false
    end
    
    -- Get animal ID for operation guard and state tracking
    local animalID = animal:getID()
    
    -- Load taming system safely for interface bypass coordination
    local tamingSystem = loadTamingSystemSafely()
    local originalState = nil
    
    -- Set interface bypass flag to prevent validation interference
    if tamingSystem and tamingSystem.animalsTamingInProgress then
        originalState = tamingSystem.animalsTamingInProgress[animalID]
        tamingSystem.animalsTamingInProgress[animalID] = "INTERFACE_TAMING"
    end
    
    -- Use combined recursion guard and atomic operation protection
    local success, result = AE_OperationGuards.withOperationGuard(animalID, "makingTamed", function()
        return AE_OperationGuards.withAtomicOperation(animalID, "taming", function()
            AE_DataService.setTamed(animal, true)
            AE_DataService.setTameness(animal, 100.0)
            
            if not AE_DataService.getStableID(animal) then
                local animalName = AE_DataService.getAnimalName(animal)
                if not animalName or animalName == "" then
                    local animalType = AnimalRegistry.GetAnimalType(animal)
                    animalName = animalType and animalType:gsub("^%l", string.upper) or "Animal"
                end
                local stableID = AE_TamingInterface.generateAnimalID(animalName)
                if stableID then
                    AE_DataService.setStableID(animal, stableID)
                end
            end
            
            if AE_DataService.getSlotAssigned(animal) == nil then
                AE_DataService.setSlotAssigned(animal, false)
            end
            
            if not AE_DataService.getAnimalName(animal) then
                local animalType = AnimalRegistry.GetAnimalType(animal)
                local animalName = animalType and animalType:gsub("^%l", string.upper) or "Animal"
                AE_DataService.setAnimalName(animal, animalName)
            end
            
            return true
        end)
    end)
    
    -- Restore original taming state after interface operation
    if tamingSystem and tamingSystem.animalsTamingInProgress then
        tamingSystem.animalsTamingInProgress[animalID] = originalState
    end
    
    if not success then
        return false
    end
    
    return result
end

function AE_TamingInterface.generateAnimalID(animalName)
    if not animalName or animalName == "" then
        animalName = "Animal"
    end
    
    local cleanName = animalName:gsub("[^%w]", ""):upper()
    if cleanName == "" then
        cleanName = "ANIMAL"
    end
    
    local prefix = cleanName:sub(1, 4)
    while #prefix < 4 do
        prefix = prefix .. "X"
    end
    
    local counter = 1
    local attempts = 0
    local maxAttempts = 1000
    
    while attempts < maxAttempts do
        local animalID = prefix .. string.format("%04d", counter)
        
        local foundDuplicate = false
        local allAnimals = getCell():getObjectList()
        for i = 0, allAnimals:size() - 1 do
            local obj = allAnimals:get(i)
            if obj:isAnimal() then
                local existingID = AE_DataService.getStableID(obj)
                if existingID == animalID then
                    foundDuplicate = true
                    break
                end
            end
        end
        
        if not foundDuplicate then
            return animalID
        end
        
        counter = counter + 1
        attempts = attempts + 1
    end
    
    return nil
end

function AE_TamingInterface.validateTamingEligibility(animal)
    if not AE_DataService.isAnimalValid(animal) then
        return false
    end
    
    if AE_DataService.isTamed(animal) then
        return false
    end
    
    return true
end

function AE_TamingInterface.getTamingStateSnapshot(animal)
    if not AE_DataService.isAnimalValid(animal) then
        return nil
    end
    
    return {
        isTamed = AE_DataService.isTamed(animal),
        tameness = AE_DataService.getTameness(animal),
        owner = AE_DataService.getOwner(animal),
        stableID = AE_DataService.getStableID(animal),
        animalName = AE_DataService.getAnimalName(animal),
        slotAssigned = AE_DataService.getSlotAssigned(animal)
    }
end

function AE_TamingInterface.restoreTamingStateFromSnapshot(animal, snapshot)
    if not AE_DataService.isAnimalValid(animal) or not snapshot then
        return false
    end
    
    local restored = false
    
    if snapshot.isTamed ~= nil then
        if AE_DataService.setTamed(animal, snapshot.isTamed) then
            restored = true
        end
    end
    
    if snapshot.tameness then
        if AE_DataService.setTameness(animal, snapshot.tameness) then
            restored = true
        end
    end
    
    if snapshot.owner then
        if AE_DataService.setOwner(animal, snapshot.owner) then
            restored = true
        end
    end
    
    if snapshot.stableID then
        if AE_DataService.setStableID(animal, snapshot.stableID) then
            restored = true
        end
    end
    
    if snapshot.animalName then
        if AE_DataService.setAnimalName(animal, snapshot.animalName) then
            restored = true
        end
    end
    
    if snapshot.slotAssigned ~= nil then
        if AE_DataService.setSlotAssigned(animal, snapshot.slotAssigned) then
            restored = true
        end
    end
    
    return restored
end

_G.AE_TamingInterface = AE_TamingInterface

return AE_TamingInterface