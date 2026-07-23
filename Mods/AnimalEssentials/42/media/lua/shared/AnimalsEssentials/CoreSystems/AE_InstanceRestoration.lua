local AE_InstanceRestoration = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

local AE_PersistentAnimalData = nil
local AE_DataService = nil
local AnimalRegistry = nil

local pendingRestorations = {}
local restorationAttempts = {}
local MAX_RESTORATION_ATTEMPTS = 3
local RESTORATION_DELAY_TICKS = 30

local function loadDependencies()
    if not AE_PersistentAnimalData then
        local success, result = pcall(function()
            return require("AnimalsEssentials/AE_PersistentAnimalData")
        end)
        if success and result then
            AE_PersistentAnimalData = result
        end
    end
    
    if not AE_DataService then
        local success, result = pcall(function()
            return require("AnimalsEssentials/DataServices/AE_DataService")
        end)
        if success and result then
            AE_DataService = result
        end
    end
    
    if not AnimalRegistry then
        local success, result = pcall(function()
            return require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
        end)
        if success and result then
            AnimalRegistry = result
        end
    end
end

function AE_InstanceRestoration.detectInstanceChange(animal)
    if not animal or not animal:isAnimal() then return false end
    
    loadDependencies()
    if not AE_DataService or not AE_PersistentAnimalData then return false end
    
    local success, animalId = pcall(function() return animal:getAnimalID() end)
    if not success or not animalId then return false end
    
    local persistentData = AE_PersistentAnimalData.getData(animalId, "tameness")
    if not persistentData then return false end
    
    local currentTameness = AE_DataService.getTameness(animal)
    local isNewInstance = (currentTameness == nil or currentTameness == 0) and persistentData > 0
    
    if isNewInstance then
        table.insert(pendingRestorations, {
            animal = animal,
            animalId = animalId,
            tickCount = 0,
            timestamp = getTimestampMs()
        })
        return true
    end
    
    return false
end

function AE_InstanceRestoration.restoreAnimalData(animal, animalId)
    if not animal or not animalId then return false end
    
    loadDependencies()
    if not AE_DataService or not AE_PersistentAnimalData then return false end
    
    local allData = AE_PersistentAnimalData.getAllData(animalId)
    if not allData then return false end
    
    local restored = false
    
    if allData.tameness then
        AE_DataService.setTameness(animal, allData.tameness)
        restored = true
    end
    
    if allData.isTamed then
        AE_DataService.setTamed(animal, allData.isTamed)
        restored = true
    end
    
    if allData.ownerID then
        AE_DataService.setOwner(animal, allData.ownerID)
        restored = true
    end
    
    if allData.animalName then
        AE_DataService.setAnimalName(animal, allData.animalName)
        restored = true
    end
    
    if allData.stableID then
        AE_DataService.setStableID(animal, allData.stableID)
        restored = true
    end
    
    if allData.customHunger then
        AE_DataService.setCustomHunger(animal, allData.customHunger)
        restored = true
    end
    
    if allData.customThirst then
        AE_DataService.setCustomThirst(animal, allData.customThirst)
        restored = true
    end
    
    if restored then
        if AE_EnvironmentDetector.isSinglePlayer() then
            animal:transmitModData()
        else
            if not isClient() then
                animal:transmitModData()
            end
        end
    end
    
    return restored
end

function AE_InstanceRestoration.processRestorations()
    if #pendingRestorations == 0 then return end
    
    for i = #pendingRestorations, 1, -1 do
        local restoration = pendingRestorations[i]
        restoration.tickCount = restoration.tickCount + 1
        
        if restoration.tickCount >= RESTORATION_DELAY_TICKS then
            local animal = restoration.animal
            local animalId = restoration.animalId
            
            if animal and not animal:isDead() then
                local attempts = restorationAttempts[animalId] or 0
                
                if attempts < MAX_RESTORATION_ATTEMPTS then
                    local success = AE_InstanceRestoration.restoreAnimalData(animal, animalId)
                    
                    if success then
                        print("[AE_InstanceRestoration] Restored data for animal: " .. animalId)
                        
                        if AnimalRegistry and AnimalRegistry.IsFrameworkAnimal then
                            if AnimalRegistry.IsFrameworkAnimal(animal) then
                                local TamingSystem = nil
                                local success, result = pcall(function()
                                    return require("AnimalsEssentials/Taming/AE_TamingSystem")
                                end)
                                if success and result then
                                    TamingSystem = result
                                    if TamingSystem.recognizeRestoredAnimal then
                                        TamingSystem.recognizeRestoredAnimal(animal)
                                    end
                                end
                            end
                        end
                        
                        restorationAttempts[animalId] = nil
                    else
                        restorationAttempts[animalId] = attempts + 1
                        print("[AE_InstanceRestoration] Restoration attempt " .. (attempts + 1) .. " failed for: " .. animalId)
                    end
                else
                    print("[AE_InstanceRestoration] Max restoration attempts reached for: " .. animalId)
                    restorationAttempts[animalId] = nil
                end
            end
            
            table.remove(pendingRestorations, i)
        end
    end
end

function AE_InstanceRestoration.cleanupStaleAttempts()
    local currentTime = getTimestampMs()
    local staleKeys = {}
    
    for animalId, _ in pairs(restorationAttempts) do
        local found = false
        for _, restoration in ipairs(pendingRestorations) do
            if restoration.animalId == animalId then
                if currentTime - restoration.timestamp > 60000 then
                    table.insert(staleKeys, animalId)
                end
                found = true
                break
            end
        end
        
        if not found then
            table.insert(staleKeys, animalId)
        end
    end
    
    for _, animalId in ipairs(staleKeys) do
        restorationAttempts[animalId] = nil
    end
end

Events.OnCreateLivingCharacter.Add(function(character)
    if character and character:isAnimal() then
        local success = pcall(function()
            AE_InstanceRestoration.detectInstanceChange(character)
        end)
        if not success then
            print("[AE_InstanceRestoration] Error detecting instance change")
        end
    end
end)

local tickCounter = 0
Events.OnTick.Add(function()
    tickCounter = tickCounter + 1
    
    if tickCounter % 10 == 0 then
        AE_InstanceRestoration.processRestorations()
    end
    
    if tickCounter % 1800 == 0 then
        AE_InstanceRestoration.cleanupStaleAttempts()
    end
end)

function AE_InstanceRestoration.getStats()
    return {
        pendingRestorations = #pendingRestorations,
        activeAttempts = 0,
        timestamp = getTimestampMs()
    }
end

return AE_InstanceRestoration