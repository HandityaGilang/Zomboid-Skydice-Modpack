AE_PickupDropErrorHandler = {}

AE_PickupDropErrorHandler.ErrorCounts = {}
AE_PickupDropErrorHandler.PreservationFailures = {}

function AE_PickupDropErrorHandler.handleTamingSystemError(animal, preservationData, errorMsg)
    if not animal or not preservationData then return false end
    
    local animalID = preservationData.stableID or tostring(animal:getOnlineID())
    local errorKey = "taming_" .. animalID
    
    AE_PickupDropErrorHandler.ErrorCounts[errorKey] = (AE_PickupDropErrorHandler.ErrorCounts[errorKey] or 0) + 1
    
    if string.find(errorMsg, "GetMaxTamedAnimals") or string.find(errorMsg, "AE_SandboxSettings") then
        return AE_PickupDropErrorHandler.applySandboxFix(animal, preservationData)
    end
    
    return false
end

function AE_PickupDropErrorHandler.applySandboxFix(animal, preservationData)
    if not animal or not preservationData then return false end
    
    local success, result = pcall(function()
        if preservationData.isTamed and preservationData.ownerID then
            local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")
            AE_DataService.setTamed(animal, true)
            AE_DataService.setOwner(animal, preservationData.ownerID)
            AE_DataService.setTameness(animal, preservationData.tameness or 100)
            
            if preservationData.animalName then
                AE_DataService.setAnimalName(animal, preservationData.animalName)
            end
            
            if preservationData.stableID then
                AE_DataService.setStableID(animal, preservationData.stableID)
            end
            
            return true
        end
        return false
    end)
    
    return success and result
end

function AE_PickupDropErrorHandler.validateRestoredAnimal(animal, preservationData)
    if not animal or not preservationData then return false end
    
    local validationErrors = {}
    
    local success, result = pcall(function()
        if preservationData.isTamed then
            if not AE_DataService or not AE_DataService.isTamed then
                table.insert(validationErrors, "AE_DataService not available")
                return false
            end
            
            local currentTamed = AE_DataService.isTamed(animal)
            if not currentTamed then
                table.insert(validationErrors, "Tamed status not restored")
            end
            
            if preservationData.ownerID then
                local currentOwner = AE_DataService.getOwner and AE_DataService.getOwner(animal)
                if currentOwner ~= preservationData.ownerID then
                    table.insert(validationErrors, "Owner ID not restored")
                end
            end
            
            if preservationData.tameness and preservationData.tameness > 0 then
                local currentTameness = AE_DataService.getTameness and AE_DataService.getTameness(animal)
                if not currentTameness or currentTameness == 0 then
                    table.insert(validationErrors, "Tameness not restored")
                end
            end
        end
        
        return #validationErrors == 0
    end)
    
    if not success or not result then
        local animalID = preservationData.stableID or tostring(animal:getOnlineID())
        AE_PickupDropErrorHandler.PreservationFailures[animalID] = {
            errors = validationErrors,
            preservationData = preservationData,
            timestamp = getTimestampMs()
        }
        return false
    end
    
    return true
end

function AE_PickupDropErrorHandler.preventTamingSystemConflicts(animal)
    if not animal then return end
    
    local success, result = pcall(function()
        local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")
        local isTamed = AE_DataService.isTamed(animal)
        if isTamed then
            local tameness = AE_DataService.getTameness(animal)
            if not tameness or tameness == 0 then
                AE_DataService.setTameness(animal, 100)
            end
            
            local ownerID = AE_DataService.getOwner(animal)
            if not ownerID or ownerID == "" then
                local nearbyPlayers = animal:getCurrentSquare():getWorldObjects()
                for i = 0, nearbyPlayers:size() - 1 do
                    local obj = nearbyPlayers:get(i)
                    if instanceof(obj, "IsoPlayer") then
                        AE_DataService.setOwner(animal, obj:getOnlineID())
                        break
                    end
                end
            end
        end
    end)
end

function AE_PickupDropErrorHandler.getErrorReport()
    local report = {
        totalErrors = 0,
        errorBreakdown = {},
        failureDetails = {},
        timestamp = getTimestampMs()
    }
    
    for errorKey, count in pairs(AE_PickupDropErrorHandler.ErrorCounts) do
        report.totalErrors = report.totalErrors + count
        report.errorBreakdown[errorKey] = count
    end
    
    for animalID, failure in pairs(AE_PickupDropErrorHandler.PreservationFailures) do
        report.failureDetails[animalID] = failure
    end
    
    return report
end

function AE_PickupDropErrorHandler.cleanupOldErrors()
    local currentTime = getTimestampMs()
    local cleanupKeys = {}
    
    for animalID, failure in pairs(AE_PickupDropErrorHandler.PreservationFailures) do
        if currentTime - failure.timestamp > 300000 then
            table.insert(cleanupKeys, animalID)
        end
    end
    
    for _, key in ipairs(cleanupKeys) do
        AE_PickupDropErrorHandler.PreservationFailures[key] = nil
    end
end

Events.OnTick.Add(function()
    Events.OnTick.Remove(AE_PickupDropErrorHandler.cleanupOldErrors)
    AE_PickupDropErrorHandler.cleanupOldErrors()
end)

return AE_PickupDropErrorHandler