local KittyMod_IntegrationValidator = {}

local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
local KittyMod_Core = require("KittyMod/Core/KittyMod_Core")
local KittyMod_SafeAPI = require("KittyMod/Core/KittyMod_SafeAPI")

local validationResults = {}
local testRunning = false
local validationCompleted = false

function KittyMod_IntegrationValidator.initialize()
    Events.OnGameStart.Add(function()
        Events.OnTick.Add(function()
            Events.OnTick.Remove(KittyMod_IntegrationValidator.conditionalValidation)
            KittyMod_IntegrationValidator.conditionalValidation()
        end)
    end)
end

function KittyMod_IntegrationValidator.conditionalValidation()
    if validationCompleted then return end
    validationCompleted = true
    
    local KittyMod_FrameworkBridge = require("KittyMod/Integration/KittyMod_FrameworkBridge")
    
    if KittyMod_FrameworkBridge.isFrameworkAvailable() then
        KittyMod_IntegrationValidator.runValidationTests()
    end
end

function KittyMod_IntegrationValidator.runValidationTests()
    if testRunning then return end
    testRunning = true
    
    validationResults = {
        standaloneOperation = false,
        frameworkDetection = false,
        dataSynchronization = false,
        eventCommunication = false,
        gracefulDegradation = false,
        uiIntegration = false,
        commandIntegration = false
    }
    
    KittyMod_IntegrationValidator.testStandaloneOperation()
    KittyMod_IntegrationValidator.testFrameworkDetection()
    KittyMod_IntegrationValidator.testDataSynchronization()
    KittyMod_IntegrationValidator.testEventCommunication()
    KittyMod_IntegrationValidator.testGracefulDegradation()
    KittyMod_IntegrationValidator.testUIIntegration()
    KittyMod_IntegrationValidator.testCommandIntegration()
    
    KittyMod_IntegrationValidator.reportValidationResults()
    testRunning = false
end

function KittyMod_IntegrationValidator.testStandaloneOperation()
    local success = true
    
    if not KittyMod_Core then
        success = false
    end
    
    if not KittyMod_ModData then
        success = false
    end
    
    local testData = KittyMod_Core.getCatDefinitions()
    if not testData or not testData.breeds then
        success = false
    end
    
    local testRegistry = KittyMod_Core.getCatRegistry()
    if not testRegistry or type(testRegistry) ~= "table" then
        success = false
    end
    
    validationResults.standaloneOperation = success
    if success then
    end
end

function KittyMod_IntegrationValidator.testFrameworkDetection()
    local success = true
    
    local bridgeSuccess, bridge = pcall(function()
        return require("KittyMod/Integration/KittyMod_FrameworkBridge")
    end)
    
    if not bridgeSuccess or not bridge then
        success = false
    else
        local detection = bridge.detectFrameworkComponents
        if not detection or type(detection) ~= "function" then
            success = false
        else
            local frameworkStatus = bridge.isFrameworkAvailable()
            
            local components = bridge.getFrameworkComponents()
            if components then
                for name, component in pairs(components) do
                end
            end
        end
    end
    
    validationResults.frameworkDetection = success
    if success then
    end
end

function KittyMod_IntegrationValidator.testDataSynchronization()
    local success = true
    
    local bridgeSuccess, bridge = pcall(function()
        return require("KittyMod/Integration/KittyMod_FrameworkBridge")
    end)
    
    if bridgeSuccess and bridge then
        local syncFunction = bridge.handleFrameworkDataSync
        if not syncFunction or type(syncFunction) ~= "function" then
            success = false
        end
        
        local dataRequestFunction = bridge.handleFrameworkDataRequest
        if not dataRequestFunction or type(dataRequestFunction) ~= "function" then
            success = false
        end
    else
    end
    
    validationResults.dataSynchronization = success
    if success then
    end
end

function KittyMod_IntegrationValidator.testEventCommunication()
    local success = true
    
    local testEventFired = false
    
    local testHandler = function(data)
        if data and data.source == "KittyMod_ValidationTest" then
            testEventFired = true
        end
    end
    
    if Events.OnAE_TestEvent then
        Events.OnAE_TestEvent.Add(testHandler)
        
        
        Events.OnAE_TestEvent.Remove(testHandler)
    end
    
    local bridgeSuccess, bridge = pcall(function()
        return require("KittyMod/Integration/KittyMod_FrameworkBridge")
    end)
    
    if not bridgeSuccess or not bridge then
    else
        local eventHandlers = {
            "onFrameworkDataRequest",
            "onFrameworkCommandRequest", 
            "onFrameworkStatusRequest",
            "onFrameworkSyncRequest"
        }
        
        for _, handler in ipairs(eventHandlers) do
            if not bridge[handler] or type(bridge[handler]) ~= "function" then
                success = false
            end
        end
    end
    
    validationResults.eventCommunication = success
    if success then
    end
end

function KittyMod_IntegrationValidator.testGracefulDegradation()
    local success = true
    
    local testCat = nil
    local player = getPlayer()
    if player then
        local nearbyAnimals = KittyMod_SafeAPI.getAnimalsInRange(player, 50)
        if nearbyAnimals then
            for i = 0, nearbyAnimals:size() - 1 do
                local animal = nearbyAnimals:get(i)
                if KittyMod_ModData.isCat(animal) then
                    testCat = animal
                    break
                end
            end
        end
    end
    
    if testCat then
        local beforeSync = KittyMod_ModData.getCatData(testCat, "CatTameness") or 0
        
        KittyMod_ModData.syncWithFramework(testCat, "CatTameness", beforeSync)
        
        local afterSync = KittyMod_ModData.getCatData(testCat, "CatTameness") or 0
        
        if beforeSync ~= afterSync then
            success = false
        end
    else
    end
    
    local behaviorSuccess, behaviors = pcall(function()
        return require("KittyMod/Behaviors/KittyMod_Behaviors")
    end)
    
    if not behaviorSuccess or not behaviors then
        success = false
    end
    
    validationResults.gracefulDegradation = success
    if success then
    end
end

function KittyMod_IntegrationValidator.testUIIntegration()
    local success = true
    
    local uiBridgeSuccess, uiBridge = pcall(function()
        return require("KittyMod/Integration/KittyMod_UIBridge")
    end)
    
    if uiBridgeSuccess and uiBridge then
        local frameworkUIStatus = uiBridge.isFrameworkUIAvailable()
        
        local enhancements = uiBridge.getUIEnhancements()
        if enhancements then
            for feature, enabled in pairs(enhancements) do
            end
        end
    else
        success = false
    end
    
    local statusUISuccess, statusUI = pcall(function()
        return require("KittyMod/UI/KittyMod_StatusUI")
    end)
    
    if not statusUISuccess or not statusUI then
        success = false
    end
    
    validationResults.uiIntegration = success
    if success then
    end
end

function KittyMod_IntegrationValidator.testCommandIntegration()
    local success = true
    
    local commandsSuccess, commands = pcall(function()
        return require("KittyMod/Behaviors/KittyMod_Commands")
    end)
    
    if not commandsSuccess or not commands then
        success = false
    else
        local testFunctions = {
            "executeCommand",
            "showCatCommandMenu",
            "calculateObedienceChance"
        }
        
        for _, funcName in ipairs(testFunctions) do
            if not commands[funcName] or type(commands[funcName]) ~= "function" then
                success = false
            end
        end
    end
end

function KittyMod_IntegrationValidator.reportValidationResults()
    local totalTests = 0
    local passedTests = 0
    
    for testName, result in pairs(validationResults) do
        totalTests = totalTests + 1
        if result then
            passedTests = passedTests + 1
        end
    end
    
end

function KittyMod_IntegrationValidator.getValidationResults()
    return validationResults
end

function KittyMod_IntegrationValidator.isValidationComplete()
    return not testRunning and next(validationResults) ~= nil
end

function KittyMod_IntegrationValidator.forceValidation()
    testRunning = false
    KittyMod_IntegrationValidator.runValidationTests()
end

Events.OnGameStart.Add(KittyMod_IntegrationValidator.initialize)

return KittyMod_IntegrationValidator