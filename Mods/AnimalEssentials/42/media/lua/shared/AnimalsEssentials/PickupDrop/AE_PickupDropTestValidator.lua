AE_PickupDropTestValidator = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

function AE_PickupDropTestValidator.validateDetectionSystem()
    local testResults = {
        detectorLoaded = false,
        dataServiceConnected = false,
        eventsRegistered = false,
        trackingActive = false,
        errors = {}
    }
    
    if not AE_PickupDropDetector then
        table.insert(testResults.errors, "AE_PickupDropDetector not loaded")
        return testResults
    end
    testResults.detectorLoaded = true
    
    if not AE_DataService then
        table.insert(testResults.errors, "AE_DataService not available")
        return testResults
    end
    testResults.dataServiceConnected = true
    
    if AE_PickupDropDetector.initialized then
        testResults.eventsRegistered = true
    else
        table.insert(testResults.errors, "AE_PickupDropDetector not initialized")
    end
    
    local trackingCount = 0
    if AE_PickupDropDetector.TrackedAnimals then
        for _ in pairs(AE_PickupDropDetector.TrackedAnimals) do
            trackingCount = trackingCount + 1
        end
    end
    testResults.trackingActive = trackingCount > 0
    testResults.trackedCount = trackingCount
    
    local preservationCount = 0
    if AE_PickupDropDetector.PendingPreservation then
        for _ in pairs(AE_PickupDropDetector.PendingPreservation) do
            preservationCount = preservationCount + 1
        end
    end
    testResults.pendingPreservations = preservationCount
    
    
    return testResults
end

function AE_PickupDropTestValidator.simulatePickupDrop(animal)
    if not animal or not instanceof(animal, "IsoAnimal") then
        return {success = false, error = "Invalid animal provided"}
    end
    
    local testResult = {
        success = false,
        originalData = {},
        preservedData = {},
        restoredData = {},
        correlationID = nil,
        testSteps = {},
        tamingSystemCompatible = false,
        errorHandlerActive = false
    }
    
    table.insert(testResult.testSteps, "Starting pickup/drop simulation")
    
    local success, result = pcall(function()
        testResult.originalData.tameness = AE_DataService.getTameness and AE_DataService.getTameness(animal) or 0
        testResult.originalData.isTamed = AE_DataService.isTamed and AE_DataService.isTamed(animal) or false
        testResult.originalData.ownerID = AE_DataService.getOwner and AE_DataService.getOwner(animal)
        
        table.insert(testResult.testSteps, "Extracted original data")
        
        local preservationData = AE_PickupDropDetector.extractModData(animal)
        if preservationData then
            testResult.preservedData = preservationData
            testResult.correlationID = "test_" .. getTimestampMs()
            preservationData.correlationID = testResult.correlationID
            preservationData.pickupTime = getTimestampMs()
            preservationData.playerID = 0
            
            AE_PickupDropDetector.PendingPreservation[testResult.correlationID] = preservationData
            
            table.insert(testResult.testSteps, "Created preservation data")
            
            local restoreSuccess, errorMsg = pcall(function()
                return AE_PickupDropDetector.restoreModData(animal, preservationData)
            end)
            
            if restoreSuccess then
                testResult.tamingSystemCompatible = true
                table.insert(testResult.testSteps, "Taming system compatible")
                
                local validationSuccess = true
                if AE_PickupDropErrorHandler then
                    testResult.errorHandlerActive = true
                    AE_PickupDropErrorHandler.preventTamingSystemConflicts(animal)
                    validationSuccess = AE_PickupDropErrorHandler.validateRestoredAnimal(animal, preservationData)
                    table.insert(testResult.testSteps, "Error handler validation: " .. tostring(validationSuccess))
                end
                
                if validationSuccess then
                    testResult.restoredData.tameness = AE_DataService.getTameness and AE_DataService.getTameness(animal) or 0
                    testResult.restoredData.isTamed = AE_DataService.isTamed and AE_DataService.isTamed(animal) or false
                    testResult.restoredData.ownerID = AE_DataService.getOwner and AE_DataService.getOwner(animal)
                    testResult.success = true
                    
                    table.insert(testResult.testSteps, "Full restoration successful")
                else
                    testResult.error = "Validation failed after restoration"
                    table.insert(testResult.testSteps, "Validation failed")
                end
            else
                table.insert(testResult.testSteps, "Taming system error: " .. tostring(errorMsg))
                
                if AE_PickupDropErrorHandler then
                    testResult.errorHandlerActive = true
                    local errorHandlerSuccess = AE_PickupDropErrorHandler.handleTamingSystemError(animal, preservationData, tostring(errorMsg))
                    if errorHandlerSuccess then
                        testResult.success = true
                        table.insert(testResult.testSteps, "Error handler resolved issue")
                    else
                        testResult.error = "Error handler could not resolve: " .. tostring(errorMsg)
                        table.insert(testResult.testSteps, "Error handler failed")
                    end
                else
                    testResult.error = "Restoration failed: " .. tostring(errorMsg)
                    table.insert(testResult.testSteps, "No error handler available")
                end
            end
        else
            testResult.error = "ModData extraction failed - no relevant data found"
            table.insert(testResult.testSteps, "Extraction failed - no data")
        end
        
        return true
    end)
    
    if not success then
        testResult.error = "Test execution failed: " .. tostring(result)
        table.insert(testResult.testSteps, "Test execution error")
    end
    
    return testResult
end

function AE_PickupDropTestValidator.reportStatus()
    local validation = AE_PickupDropTestValidator.validateDetectionSystem()

    if AE_EnvironmentDetector.isSinglePlayer() then
        AE_PickupDropTestValidator.displayValidationResults(validation)
    else
        if not isClient() then
            sendServerCommand("AE_PickupDropTest", "ValidationReport", validation)
        else
            AE_PickupDropTestValidator.displayValidationResults(validation)
        end
    end
end

function AE_PickupDropTestValidator.displayValidationResults(results)
    local message = "AE_PickupDropDetector Validation:\n"
    message = message .. "Detector Loaded: " .. tostring(results.detectorLoaded) .. "\n"
    message = message .. "DataService Connected: " .. tostring(results.dataServiceConnected) .. "\n"
    message = message .. "Events Registered: " .. tostring(results.eventsRegistered) .. "\n"
    message = message .. "Tracking Active: " .. tostring(results.trackingActive) .. "\n"
    message = message .. "Tracked Animals: " .. (results.trackedCount or 0) .. "\n"
    message = message .. "Pending Preservations: " .. (results.pendingPreservations or 0) .. "\n"
    
    if #results.errors > 0 then
        message = message .. "\nErrors:\n"
        for _, error in ipairs(results.errors) do
            message = message .. "- " .. error .. "\n"
        end
    end
    
end

Events.OnGameStart.Add(function()
    Events.OnTick.Add(function()
        Events.OnTick.Remove(AE_PickupDropTestValidator.reportStatus)
        AE_PickupDropTestValidator.reportStatus()
    end)
end)

return AE_PickupDropTestValidator