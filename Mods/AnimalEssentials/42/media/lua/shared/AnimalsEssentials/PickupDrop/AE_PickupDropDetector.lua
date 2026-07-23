AE_PickupDropDetector = {}

local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")
local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
local AE_PickupDropErrorHandler = require("AnimalsEssentials/PickupDrop/AE_PickupDropErrorHandler")
local AE_PickupDropEdgeCaseHandler = require("AnimalsEssentials/PickupDrop/AE_PickupDropEdgeCaseHandler")
local AE_PickupDropPerformanceMonitor = require("AnimalsEssentials/PickupDrop/AE_PickupDropPerformanceMonitor")
local AE_InstanceRestoration = require("AnimalsEssentials/CoreSystems/AE_InstanceRestoration")

AE_PickupDropDetector.PendingPreservation = {}

AE_PickupDropDetector.TrackedAnimals = {}

AE_PickupDropDetector.ScheduledChecks = {}

AE_PickupDropDetector.Config = {
    preservationTimeoutMs = 120000,
    cleanupTimeoutMs = 240000,
    minimumMatchScore = 60,
    trackingUpdateInterval = 2000
}

function AE_PickupDropDetector.initialize()
    if AE_PickupDropDetector.initialized then 
        print("[AE_PickupDropDetector] Already initialized")
        return true  -- Already initialized successfully
    end
    
    -- PHASE 2 PICKUP FIX: Comprehensive dependency validation with detailed logging
    print("[AE_PickupDropDetector] Starting initialization...")
    
    if not AE_DataService then
        print("[AE_PickupDropDetector] ERROR: AE_DataService not available")
        return false
    end
    print("[AE_PickupDropDetector] OK: AE_DataService available")
    
    if not Events.OnCreateLivingCharacter then
        print("[AE_PickupDropDetector] ERROR: OnCreateLivingCharacter event not available")
        return false
    end
    print("[AE_PickupDropDetector] OK: OnCreateLivingCharacter event available")
    
    if not Events.OnPlayerUpdate then
        print("[AE_PickupDropDetector] ERROR: OnPlayerUpdate event not available")
        return false
    end
    print("[AE_PickupDropDetector] OK: OnPlayerUpdate event available")
    
    -- PHASE 2 PICKUP FIX: Safe event registration with validation
    print("[AE_PickupDropDetector] Registering event handlers...")
    local success = pcall(function()
        Events.OnCreateLivingCharacter.Add(AE_PickupDropDetector.onAnimalCreate)
        Events.OnPlayerUpdate.Add(AE_PickupDropDetector.trackAnimalStates)
    end)
    
    if not success then
        print("[AE_PickupDropDetector] ERROR: Failed to register event handlers")
        return false
    end
    
    AE_PickupDropDetector.initialized = true
    print("[AE_PickupDropDetector] Successfully initialized and registered event handlers")
    return true
end

function AE_PickupDropDetector.onAnimalCreate(character)
    if not character or not instanceof(character, "IsoAnimal") then return end
    
    local animal = character
    
    AE_PickupDropPerformanceMonitor.recordDetectionEvent(animal, "create")
    
    local restorationTriggered = AE_InstanceRestoration.detectInstanceChange(animal)
    
    local potentialRestoration = AE_PickupDropDetector.findMatchingPreservation(animal)
    
    
    if potentialRestoration and not restorationTriggered then
        local startTime = getTimestampMs()
        local restoreSuccess = false
        local errorMsg = nil
        
        AE_PickupDropPerformanceMonitor.recordPreservationAttempt(animal, potentialRestoration.correlationID)
        
        local success, result = pcall(function()
            return AE_PickupDropDetector.restoreModData(animal, potentialRestoration)
        end)
        
        if success then
            restoreSuccess = result
        else
            errorMsg = tostring(result)
            AE_PickupDropPerformanceMonitor.recordError("restoration_failed", errorMsg)
            restoreSuccess = AE_PickupDropErrorHandler.handleTamingSystemError(animal, potentialRestoration, errorMsg)
        end
        
        if restoreSuccess then
            AE_PickupDropDetector.PendingPreservation[potentialRestoration.correlationID] = nil
            
            AE_PickupDropErrorHandler.preventTamingSystemConflicts(animal)
            
            local validationSuccess = AE_PickupDropErrorHandler.validateRestoredAnimal(animal, potentialRestoration)
            if validationSuccess then
                local endTime = getTimestampMs()
                local restorationTime = endTime - startTime
                
                AE_PickupDropPerformanceMonitor.recordPreservationSuccess(animal, potentialRestoration.correlationID, restorationTime)
                AE_PickupDropPerformanceMonitor.recordCorrelationTime(potentialRestoration.correlationID, potentialRestoration.pickupTime, endTime)
                
                AE_PickupDropDetector.triggerUIUpdate(animal, potentialRestoration)
                
                if not AE_EnvironmentDetector.isMultiplayer() then
                    animal:transmitModData()
                else
                    if not isClient() then
                        animal:transmitModData()
                        
                        local notification = {
                            action = "animalDataRestored",
                            animalID = potentialRestoration.stableID or animal:getOnlineID(),
                            playerID = potentialRestoration.playerID,
                            timestamp = getTimestampMs()
                        }
                        sendServerCommand("AE_PickupDropNotification", "AnimalRestored", notification)
                    end
                end
            else
                AE_PickupDropPerformanceMonitor.recordError("validation_failed", "Restored animal failed validation")
            end
        else
            AE_PickupDropPerformanceMonitor.recordError("preservation_failed", errorMsg or "Unknown restoration error")
        end
        
    else
    end
    
    AE_PickupDropDetector.trackAnimal(animal)
end

function AE_PickupDropDetector.trackAnimal(animal)
    if not animal then return end
    
    local animalID = tostring(animal:getOnlineID())
    if animalID == "0" then
        animalID = "temp_" .. tostring(animal:hashCode())
    end
    
    AE_PickupDropDetector.TrackedAnimals[animalID] = {
        animal = animal,
        lastSquare = animal:getCurrentSquare(),
        lastHeldBy = animal.heldBy,
        isInWorld = animal:isExistInTheWorld()
    }
end

function AE_PickupDropDetector.trackAnimalStates(player)
    if AE_EnvironmentDetector.isSinglePlayer() then
        if not player or player:getPlayerNum() ~= 0 then return end
    else
        if isClient() then
            return
        end
    end
    
    for animalID, trackData in pairs(AE_PickupDropDetector.TrackedAnimals) do
        if trackData.animal and not trackData.animal:isDead() then
            AE_PickupDropDetector.checkStateChange(animalID, trackData)
        else
            AE_PickupDropDetector.TrackedAnimals[animalID] = nil
        end
    end
    
    AE_PickupDropDetector.processScheduledChecks()
end

function AE_PickupDropDetector.checkStateChange(animalID, trackData)
    local animal = trackData.animal
    local currentSquare = animal:getCurrentSquare()
    local currentHeldBy = animal.heldBy
    local currentInWorld = animal:isExistInTheWorld()
    
    local wasInWorld = trackData.isInWorld
    local hadHeldBy = trackData.lastHeldBy ~= nil
    local hasHeldBy = currentHeldBy ~= nil
    
    if not hadHeldBy and hasHeldBy then
        AE_PickupDropDetector.onAnimalPickup(animal, currentHeldBy)
    elseif hadHeldBy and not hasHeldBy then
        AE_PickupDropDetector.onAnimalDrop(animal, trackData.lastHeldBy)
    end
    
    trackData.lastSquare = currentSquare
    trackData.lastHeldBy = currentHeldBy
    trackData.isInWorld = currentInWorld
end

function AE_PickupDropDetector.onAnimalPickup(animal, player)
    AE_PickupDropPerformanceMonitor.recordDetectionEvent(animal, "pickup")
    
    if not AE_PickupDropEdgeCaseHandler.handleRapidPickupDrop(animal, player) then
        AE_PickupDropPerformanceMonitor.recordError("throttled", "Pickup blocked by throttling")
        return
    end
    
    local preservationData = AE_PickupDropDetector.extractModData(animal)
    if not preservationData then 
        AE_PickupDropPerformanceMonitor.recordError("extraction_failed", "No ModData to preserve")
        return 
    end
    
    local correlationID = AE_PickupDropDetector.generateCorrelationID(animal, player)
    preservationData.correlationID = correlationID
    preservationData.pickupTime = getTimestampMs()
    preservationData.playerID = player:getOnlineID()
    
    if not AE_PickupDropEdgeCaseHandler.handleDuplicatePreservation(animal, preservationData) then
        AE_PickupDropPerformanceMonitor.recordError("duplicate_prevented", "Duplicate preservation blocked")
        return
    end
    
    AE_PickupDropDetector.PendingPreservation[correlationID] = preservationData
    
    AE_PickupDropDetector.cleanupExpiredPreservations()
end

function AE_PickupDropDetector.onAnimalDrop(animal, player)
    if not player then return end
end

function AE_PickupDropDetector.extractModData(animal)
    if not animal then return nil end
    
    local preservationData = {}
    
    local success, result = pcall(function()
        preservationData.tameness = AE_DataService.getTameness and AE_DataService.getTameness(animal) or 0
        preservationData.isTamed = AE_DataService.isTamed and AE_DataService.isTamed(animal) or false
        preservationData.ownerID = AE_DataService.getOwner and AE_DataService.getOwner(animal)
        preservationData.currentCommand = AE_DataService.getCurrentCommand and AE_DataService.getCurrentCommand(animal)
        preservationData.animalType = animal:getAnimalType() or "unknown"
        preservationData.animalName = AE_DataService.getAnimalName and AE_DataService.getAnimalName(animal)
        preservationData.stableID = AE_DataService.getStableID and AE_DataService.getStableID(animal)
        preservationData.hunger = AE_DataService.getHunger and AE_DataService.getHunger(animal)
        preservationData.thirst = AE_DataService.getThirst and AE_DataService.getThirst(animal)
        preservationData.friendliness = AE_DataService.getFriendliness and AE_DataService.getFriendliness(animal)
        preservationData.remainingLives = AE_DataService.getRemainingLives and AE_DataService.getRemainingLives(animal)
        preservationData.lastPosition = {
            x = animal:getX(),
            y = animal:getY(),
            z = animal:getZ()
        }
        
        if preservationData.ownerID then
            AE_PickupDropPerformanceMonitor.recordTimedActionEvent("owner_captured", {
                animalID = animal:getOnlineID(),
                ownerID = preservationData.ownerID,
                isTamed = preservationData.isTamed
            })
        else
            AE_PickupDropPerformanceMonitor.recordTimedActionEvent("no_owner_captured", {
                animalID = animal:getOnlineID(),
                isTamed = preservationData.isTamed
            })
        end
        
        return true
    end)
    
    if not success then
        return nil
    end
    return preservationData
end

function AE_PickupDropDetector.restoreModData(animal, preservationData)
    if not animal or not preservationData then 
        return false 
    end
    
    local restoredCount = 0
    
    if preservationData.tameness ~= nil then
        if AE_DataService.setTameness(animal, preservationData.tameness) then
            restoredCount = restoredCount + 1
        end
    end
    
    if preservationData.ownerID then
        if AE_DataService.setOwner(animal, preservationData.ownerID) then
            restoredCount = restoredCount + 1
            
            AE_PickupDropPerformanceMonitor.recordTimedActionEvent("owner_restored", {
                animalID = animal:getOnlineID(),
                ownerID = preservationData.ownerID,
                correlationID = preservationData.correlationID
            })
        else
            AE_PickupDropPerformanceMonitor.recordError("owner_restoration_failed", "Failed to restore animal owner: " .. tostring(preservationData.ownerID))
        end
    else
        AE_PickupDropPerformanceMonitor.recordError("no_owner_data", "No owner data found in preservation data")
    end
    
    if preservationData.isTamed == true then
        local success = AE_PickupDropDetector.restoreCompleteTamingState(animal, preservationData)
        if success then
            restoredCount = restoredCount + 1
            AE_PickupDropPerformanceMonitor.recordTimedActionEvent("complete_taming_restored", {
                animalID = animal:getOnlineID(),
                correlationID = preservationData.correlationID
            })
        else
            AE_PickupDropPerformanceMonitor.recordError("complete_taming_restoration_failed", "Failed to restore complete taming state")
        end
    end
    
    if preservationData.currentCommand then
        if AE_DataService.setCurrentCommand(animal, preservationData.currentCommand) then
            restoredCount = restoredCount + 1
        end
    end
    
    if preservationData.animalName and AE_DataService.setAnimalName then
        if AE_DataService.setAnimalName(animal, preservationData.animalName) then
            restoredCount = restoredCount + 1
        end
    end
    
    if preservationData.stableID and AE_DataService.setStableID then
        if AE_DataService.setStableID(animal, preservationData.stableID) then
            restoredCount = restoredCount + 1
        end
    end
    
    if preservationData.hunger and AE_DataService.setHunger then
        if AE_DataService.setHunger(animal, preservationData.hunger) then
            restoredCount = restoredCount + 1
        end
    end
    
    if preservationData.thirst and AE_DataService.setThirst then
        if AE_DataService.setThirst(animal, preservationData.thirst) then
            restoredCount = restoredCount + 1
        end
    end
    
    if preservationData.friendliness and AE_DataService.setFriendliness then
        if AE_DataService.setFriendliness(animal, preservationData.friendliness) then
            restoredCount = restoredCount + 1
        end
    end
    
    if preservationData.remainingLives and AE_DataService.setRemainingLives then
        if AE_DataService.setRemainingLives(animal, preservationData.remainingLives) then
            restoredCount = restoredCount + 1
        end
    end
    
    if preservationData.lastPosition and AE_DataService.setLastPosition then
        if AE_DataService.setLastPosition(animal, preservationData.lastPosition) then
            restoredCount = restoredCount + 1
        end
    end
    
    
    return restoredCount > 0
end

function AE_PickupDropDetector.findMatchingPreservation(animal)
    local currentTime = getTimestampMs()
    local animalType = animal:getAnimalType() or "unknown"
    local animalSquare = animal:getCurrentSquare()
    local bestMatch = nil
    local bestScore = 0
    
    local preservationCount = 0
    for _ in pairs(AE_PickupDropDetector.PendingPreservation) do
        preservationCount = preservationCount + 1
    end
    
    local optimizedSearch = preservationCount > 20
    local searchLimit = optimizedSearch and 10 or preservationCount
    local searchCount = 0
    
    local candidatesArray = {}
    for correlationID, preservationData in pairs(AE_PickupDropDetector.PendingPreservation) do
        if currentTime - preservationData.pickupTime < AE_PickupDropDetector.Config.preservationTimeoutMs then
            table.insert(candidatesArray, preservationData)
        end
    end
    
    if optimizedSearch then
        table.sort(candidatesArray, function(a, b)
            if a.animalType == animalType and b.animalType ~= animalType then
                return true
            elseif a.animalType ~= animalType and b.animalType == animalType then
                return false
            else
                return a.pickupTime > b.pickupTime
            end
        end)
    end
    
    for _, preservationData in ipairs(candidatesArray) do
        if searchCount >= searchLimit then break end
        searchCount = searchCount + 1
        
        local matchScore = 0
        
        if preservationData.animalType == animalType then
            matchScore = matchScore + 50
        end
        
        if preservationData.ownerID and preservationData.ownerID ~= "" then
            local nearbyPlayers = animalSquare:getWorldObjects()
            for i = 0, nearbyPlayers:size() - 1 do
                local obj = nearbyPlayers:get(i)
                if instanceof(obj, "IsoPlayer") then
                    local playerID = obj:getOnlineID()
                    if playerID == preservationData.playerID then
                        matchScore = matchScore + 30
                        break
                    end
                end
            end
        end
        
        if preservationData.animalName and preservationData.animalName ~= "" then
            matchScore = matchScore + 20
        end
        
        if preservationData.isTamed then
            matchScore = matchScore + 10
        end
        
        local timeDiff = currentTime - preservationData.pickupTime
        local timeScore = math.max(0, 10 - (timeDiff / 1000))
        matchScore = matchScore + timeScore
        
        if matchScore > bestScore and matchScore >= AE_PickupDropDetector.Config.minimumMatchScore then
            bestScore = matchScore
            bestMatch = preservationData
            
            if optimizedSearch and matchScore >= 90 then
                break
            end
        end
    end
    
    local searchDetails = {
        totalCandidates = #candidatesArray,
        searchLimit = searchLimit,
        bestScore = bestScore,
        minimumRequired = AE_PickupDropDetector.Config.minimumMatchScore
    }
    
    
    return bestMatch
end

function AE_PickupDropDetector.generateCorrelationID(animal, player)
    local animalType = animal:getAnimalType() or "unknown"
    local playerID = player:getOnlineID()
    local timestamp = getTimestampMs()
    
    return animalType .. "_" .. playerID .. "_" .. timestamp
end

function AE_PickupDropDetector.triggerUIUpdate(animal, preservationData)
    if not animal or not preservationData then return end
    
    local animalID = preservationData.stableID or tostring(animal:getOnlineID())
    
    local updateEvent = {
        action = "dataRestored",
        animalID = animalID,
        ownerID = preservationData.ownerID,
        animalName = preservationData.animalName,
        tameness = preservationData.tameness,
        isTamed = preservationData.isTamed,
        timestamp = getTimestampMs()
    }
    
    if AE_UnifiedStateTracker and AE_UnifiedStateTracker.updateTrackedState then
        AE_UnifiedStateTracker.updateTrackedState("status", animalID, {
            tameness = preservationData.tameness,
            isTamed = preservationData.isTamed,
            ownerID = preservationData.ownerID,
            lastRestored = getTimestampMs()
        })
    end
    
    if Events.AE_AnimalDataRestored then
        Events.AE_AnimalDataRestored.Trigger(updateEvent)
    end
    
    local sessionRegistryUpdate = {
        animalID = animalID,
        action = "dataRestored",
        preservedData = {
            tameness = preservationData.tameness,
            isTamed = preservationData.isTamed,
            ownerID = preservationData.ownerID,
            animalName = preservationData.animalName
        },
        timestamp = getTimestampMs()
    }
    
    if not AE_EnvironmentDetector.isMultiplayer() then
        if Events.AE_SessionRegistryUpdate then
            Events.AE_SessionRegistryUpdate.Trigger(sessionRegistryUpdate)
        end
    else
        if not isClient() then
            sendServerCommand("AE_SessionRegistry", "AnimalDataRestored", sessionRegistryUpdate)
        end
    end
end

function AE_PickupDropDetector.preserveAnimalData(animal, preservationData)
    if not animal or not preservationData then return false end
    
    local animalData = AE_PickupDropDetector.captureModData(animal)
    if not animalData then return false end
    
    local enrichedPreservationData = {
        correlationID = preservationData.correlationID,
        originalAnimalID = animal:getOnlineID(),
        playerID = preservationData.playerID,
        playerUsername = preservationData.playerUsername,
        pickupTime = preservationData.pickupTime or getTimestampMs(),
        actionType = preservationData.actionType or "timedaction",
        detectionMethod = preservationData.detectionMethod or "timedaction_scan",
        tameness = animalData.tameness,
        isTamed = animalData.isTamed,
        ownerID = animalData.ownerID,
        currentCommand = animalData.currentCommand,
        animalType = animalData.animalType,
        animalName = animalData.animalName,
        stableID = animalData.stableID,
        hunger = animalData.hunger,
        thirst = animalData.thirst,
        friendliness = animalData.friendliness,
        remainingLives = animalData.remainingLives,
        lastPosition = animalData.lastPosition,
        animalPosition = preservationData.animalPosition
    }
    
    AE_PickupDropDetector.PendingPreservation[preservationData.correlationID] = enrichedPreservationData
    
    AE_PickupDropPerformanceMonitor.recordTimedActionEvent("data_preserved", {
        animalID = animal:getOnlineID(),
        correlationID = preservationData.correlationID,
        playerID = preservationData.playerID
    })
    
    return true
end

function AE_PickupDropDetector.scheduleDropDetection(animal, player, actionTimestamp)
    if not animal or not player then return end
    
    local scheduledDetection = {
        animalID = animal:getOnlineID(),
        playerID = player:getOnlineID(),
        actionTimestamp = actionTimestamp,
        scheduledTime = getTimestampMs(),
        checkInterval = 2000,
        maxChecks = 15
    }
    
    AE_PickupDropDetector.scheduleDropCheck(scheduledDetection)
end

function AE_PickupDropDetector.scheduleDropCheck(detectionData)
    local currentTime = getTimestampMs()
    
    local delayedCheck = {
        scheduledTime = currentTime + detectionData.checkInterval,
        detectionData = detectionData
    }
    
    if not AE_PickupDropDetector.ScheduledChecks then
        AE_PickupDropDetector.ScheduledChecks = {}
    end
    
    table.insert(AE_PickupDropDetector.ScheduledChecks, delayedCheck)
end

function AE_PickupDropDetector.performDropCheck(detectionData)
    local animal = AE_PickupDropDetector.findAnimalByID(detectionData.animalID)
    
    if animal then
        if not animal.heldBy then
            AE_PickupDropDetector.onAnimalCreate(animal)
        else
            detectionData.maxChecks = detectionData.maxChecks - 1
            if detectionData.maxChecks > 0 then
                AE_PickupDropDetector.scheduleDropCheck(detectionData)
            end
        end
    end
end

function AE_PickupDropDetector.findAnimalByID(animalID)
    if not animalID or animalID == 0 then return nil end
    
    local cell = getWorld():getCell()
    if not cell then return nil end
    
    local zombieList = cell:getZombieList()
    for i = 0, zombieList:size() - 1 do
        local character = zombieList:get(i)
        if character and character:isAnimal() and character:getOnlineID() == animalID then
            return character
        end
    end
    
    return nil
end

function AE_PickupDropDetector.processScheduledChecks()
    if not AE_PickupDropDetector.ScheduledChecks then return end
    
    local currentTime = getTimestampMs()
    local pendingChecks = {}
    
    for _, scheduledCheck in ipairs(AE_PickupDropDetector.ScheduledChecks) do
        if currentTime >= scheduledCheck.scheduledTime then
            AE_PickupDropDetector.performDropCheck(scheduledCheck.detectionData)
        else
            table.insert(pendingChecks, scheduledCheck)
        end
    end
    
    AE_PickupDropDetector.ScheduledChecks = pendingChecks
end

function AE_PickupDropDetector.cleanupExpiredPreservations()
    local currentTime = getTimestampMs()
    local expiredKeys = {}
    
    for correlationID, preservationData in pairs(AE_PickupDropDetector.PendingPreservation) do
        if currentTime - preservationData.pickupTime > 60000 then
            table.insert(expiredKeys, correlationID)
        end
    end
    
    for _, key in ipairs(expiredKeys) do
        AE_PickupDropDetector.PendingPreservation[key] = nil
    end
end

function AE_PickupDropDetector.restoreCompleteTamingState(animal, preservationData)
    if not animal or not preservationData then
        return false
    end
    
    -- SUB-SESSION 4: Coordinate with new validation system
    local AE_TamingSystem = nil
    local tamingSystemSuccess, tamingSystemResult = pcall(function()
        return require("AnimalsEssentials/Taming/AE_TamingSystem")
    end)
    
    if tamingSystemSuccess and tamingSystemResult then
        AE_TamingSystem = tamingSystemResult
    end
    
    local success, AE_TamingInterface = pcall(function()
        return require("AnimalsEssentials/Interfaces/AE_TamingInterface")
    end)
    
    if not success or not AE_TamingInterface then
        AE_DataService.setTamed(animal, true)
        return false
    end
    
    -- SUB-SESSION 4: Set restoration bypass flag
    local animalID = animal:getOnlineID()
    local originalState = nil
    if AE_TamingSystem and AE_TamingSystem.animalsTamingInProgress then
        originalState = AE_TamingSystem.animalsTamingInProgress[animalID]
        AE_TamingSystem.animalsTamingInProgress[animalID] = "RESTORING"
        print("[PICKUP RESTORE] Set restoration bypass for: " .. animalID)
    end
    
    -- SUB-SESSION 4: Execute restoration with comprehensive error handling
    local restoreSuccess = false
    local errorReason = nil
    
    success, errorReason = pcall(function()
        restoreSuccess = AE_TamingInterface.makeAnimalTamed(animal)
        if not restoreSuccess then
            error("Interface taming failed")
        end
    end)
    
    -- SUB-SESSION 4: Always clear restoration bypass flag, regardless of outcome
    if AE_TamingSystem and AE_TamingSystem.animalsTamingInProgress then
        AE_TamingSystem.animalsTamingInProgress[animalID] = originalState
        print("[PICKUP RESTORE] Cleared restoration bypass for: " .. animalID)
    end
    
    -- SUB-SESSION 4: Handle restoration failures with graceful fallback
    if not success or not restoreSuccess then
        print("[PICKUP RESTORE] Interface restoration failed for: " .. animalID .. " - " .. tostring(errorReason))
        -- Fallback: Direct taming without interface
        local fallbackSuccess = pcall(function()
            AE_DataService.setTamed(animal, true)
            AE_DataService.setTameness(animal, 100.0)
        end)
        
        if not fallbackSuccess then
            print("[PICKUP RESTORE] CRITICAL: Fallback taming also failed for: " .. animalID)
            return false
        end
        print("[PICKUP RESTORE] Used fallback direct taming for: " .. animalID)
    end
    
    if preservationData.animalName then
        AE_DataService.setAnimalName(animal, preservationData.animalName)
    end
    
    if preservationData.stableID then
        AE_DataService.setStableID(animal, preservationData.stableID)
    end
    
    -- PHASE 1: Trigger persistent identity recognition for restored animal
    if AE_TamingSystem and AE_TamingSystem.recognizeRestoredAnimal then
        local recognized = AE_TamingSystem.recognizeRestoredAnimal(animal)
        if recognized then
            print("[PICKUP RESTORE] Successfully registered new instance with taming system")
        else
            print("[PICKUP RESTORE] WARNING: Failed to register new instance - animal may not be recognized")
        end
    end
    
    print("[PICKUP RESTORE] Successfully restored taming state for: " .. animalID)
    return true
end

-- Pickup restoration: Register tamed animal data using existing patterns
function AE_PickupDropDetector.registerTamedAnimal(animal)
    if not animal then return false end
    
    local stableID = AE_DataService.getStableID(animal)
    if stableID and AE_DataService.isTamed(animal) then
        -- Store animal data snapshot in existing TrackedAnimals table
        local animalSnapshot = AE_DataService.getAnimalDataSnapshot(animal)
        AE_PickupDropDetector.TrackedAnimals[stableID] = animalSnapshot
        return true
    end
    
    return false
end

-- Pickup restoration: Cross-reference animal by stableID using existing patterns
function AE_PickupDropDetector.getTamedAnimalData(stableID)
    if not stableID then return nil end
    return AE_PickupDropDetector.TrackedAnimals[stableID]
end

-- PHASE 2 PICKUP FIX: Status function for debugging
AE_PickupDropDetector.getStatus = function()
    return {
        initialized = AE_PickupDropDetector.initialized or false,
        trackedAnimals = AE_PickupDropDetector.TrackedAnimals or {},
        pendingPreservation = AE_PickupDropDetector.PendingPreservation or {},
        scheduledChecks = AE_PickupDropDetector.ScheduledChecks or {},
        dependencies = {
            dataService = AE_DataService ~= nil,
            onCreateEvent = Events.OnCreateLivingCharacter ~= nil,
            onPlayerUpdateEvent = Events.OnPlayerUpdate ~= nil
        },
        config = AE_PickupDropDetector.Config,
        timestamp = getTimestamp()
    }
end

Events.OnGameStart.Add(AE_PickupDropDetector.initialize)

return AE_PickupDropDetector