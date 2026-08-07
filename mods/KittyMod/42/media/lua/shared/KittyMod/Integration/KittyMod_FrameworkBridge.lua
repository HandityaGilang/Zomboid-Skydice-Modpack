local KittyMod_FrameworkBridge = {}

local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
local KittyMod_Core = require("KittyMod/Core/KittyMod_Core")
local KittyMod_SafeAPI = require("KittyMod/Core/KittyMod_SafeAPI")
local AE_EventRegistry = nil
pcall(function()
    AE_EventRegistry = require("AnimalsEssentials/Config/AE_EventRegistry")
end)

local frameworkAvailable = false
local frameworkComponents = {}
local frameworkServices = {}
local integrationState = {
    registered = false,
    syncEnabled = false,
    enhancementsActive = false
}
local enhancedFeatures = {
    uiIntegration = false,
    dataSync = false,
    commandIntegration = false,
    statusIntegration = false,
    behaviorEnhancement = false,
    crossModInteraction = false
}

function KittyMod_FrameworkBridge.initialize()
    KittyMod_FrameworkBridge.detectFrameworkComponents()
    
    if frameworkAvailable then
        KittyMod_FrameworkBridge.enableFrameworkIntegration()
    else
        KittyMod_FrameworkBridge.enableStandaloneMode()
    end
    
    KittyMod_FrameworkBridge.setupEventHandlers()
    KittyMod_FrameworkBridge.initializeServices()
end

function KittyMod_FrameworkBridge.detectFrameworkComponents()
    frameworkAvailable = false
    frameworkComponents = {}
    frameworkServices = {}
    
    local componentChecks = {
        {"AE_FrameworkData", "AnimalsEssentials/DataServices/AE_DataService"},
        {"AE_FrameworkCore", "AnimalsEssentials/CoreSystems/AE_BehaviorManager"},
        {"AE_StatusMenu", "AnimalsEssentials/UI/AE_StatusMenu"},
        {"AE_Commands", "AnimalsEssentials/UI/AE_CommandsUI"}
    }
    
    for _, check in ipairs(componentChecks) do
        local componentName, requirePath = check[1], check[2]
        local success, component = pcall(function()
            return require(requirePath)
        end)
        
        if success and component then
            frameworkComponents[componentName] = component
            if component.getServiceInterface then
                frameworkServices[componentName] = component.getServiceInterface()
            end
        end
    end
    
    if frameworkComponents.AE_FrameworkData or frameworkComponents.AE_FrameworkCore then
        frameworkAvailable = true
    end
    
    return frameworkAvailable
end

function KittyMod_FrameworkBridge.enableFrameworkIntegration()
    if not frameworkAvailable then return false end
    
    KittyMod_FrameworkBridge.registerWithFramework()
    KittyMod_FrameworkBridge.enableEnhancedFeatures()
    
    return true
end

function KittyMod_FrameworkBridge.enableStandaloneMode()
    for feature, _ in pairs(enhancedFeatures) do
        enhancedFeatures[feature] = false
    end
    
    integrationState.registered = false
    integrationState.syncEnabled = false
    integrationState.enhancementsActive = false
    
    return true
end

function KittyMod_FrameworkBridge.initializeServices()
    if not frameworkAvailable then return end
    
    KittyMod_FrameworkBridge.establishServiceConnections()
    KittyMod_FrameworkBridge.validateIntegrationCapabilities()
    KittyMod_FrameworkBridge.enableCompatibilityLayer()
end

function KittyMod_FrameworkBridge.establishServiceConnections()
    if frameworkAvailable then
        integrationState.registered = true
    end
end

function KittyMod_FrameworkBridge.validateIntegrationCapabilities()
    local requiredCapabilities = {
        "event_coordination",
        "data_synchronization", 
        "behavior_enhancement",
        "ui_integration"
    }
    
    for _, capability in ipairs(requiredCapabilities) do
        if frameworkServices.AE_FrameworkCore and 
           frameworkServices.AE_FrameworkCore.hasCapability and
           frameworkServices.AE_FrameworkCore.hasCapability(capability) then
            integrationState.enhancementsActive = true
        end
    end
end

function KittyMod_FrameworkBridge.enableCompatibilityLayer()
    if not integrationState.enhancementsActive then return end
    
    sendServerCommand("AE_UIFramework", "componentRegistration", {
        modName = "KittyMod",
        dataNamespace = "KITTY_",
        fallbackHandlers = {
            onFrameworkUnavailable = KittyMod_FrameworkBridge.handleFrameworkLoss,
            onServiceFailure = KittyMod_FrameworkBridge.handleServiceFailure,
            onDataConflict = KittyMod_FrameworkBridge.handleDataConflict
        }
    })
end

function KittyMod_FrameworkBridge.registerWithFramework()
    if not frameworkAvailable then return false end
    
    sendServerCommand("AE_UIFramework", "componentRegistration", {
        modName = "KittyMod",
        version = "1.0",
        animalTypes = {"cat"},
        modDataPrefix = "KITTY_",
        definitions = KittyMod_Core.getCatDefinitions(),
        registry = KittyMod_Core.getCatRegistry(),
        integrationLevel = "enhanced",
        capabilities = {
            behaviorEnhancement = true,
            crossModInteraction = true,
            dataSelectionSync = true,
            uiIntegration = true,
            commandExpansion = true
        },
        behaviorHandlers = {
            onTamingComplete = function(cat, player)
                return KittyMod_FrameworkBridge.handleFrameworkTaming(cat, player)
            end,
            onInteraction = function(cat, player, interactionType)
                return KittyMod_FrameworkBridge.handleFrameworkInteraction(cat, player, interactionType)
            end,
            onDeath = function(cat, killer)
                return KittyMod_FrameworkBridge.handleFrameworkDeath(cat, killer)
            end,
            onBehaviorTrigger = function(cat, behaviorType, context)
                return KittyMod_FrameworkBridge.handleEnhancedBehavior(cat, behaviorType, context)
            end
        },
        uiHandlers = {
            statusDisplay = function(cat)
                return KittyMod_FrameworkBridge.getFrameworkStatusInfo(cat)
            end,
            contextMenu = function(cat, player, context)
                return KittyMod_FrameworkBridge.addFrameworkContextOptions(cat, player, context)
            end,
            enhancedStatusDisplay = function(cat, displayType)
                return KittyMod_FrameworkBridge.getEnhancedStatusInfo(cat, displayType)
            end
        },
        dataHandlers = {
            onDataRequest = function(cat, dataTypes)
                return KittyMod_FrameworkBridge.handleFrameworkDataRequest(cat, dataTypes)
            end,
            onDataSync = function(cat, key, value)
                return KittyMod_FrameworkBridge.handleFrameworkDataSync(cat, key, value)
            end,
            onCrossModDataRequest = function(cat, requestingMod, dataScope)
                return KittyMod_FrameworkBridge.handleCrossModDataRequest(cat, requestingMod, dataScope)
            end
        },
        commandHandlers = {
            onCommandRequest = function(cat, player, command, parameters)
                return KittyMod_FrameworkBridge.handleEnhancedCommand(cat, player, command, parameters)
            end,
            getAvailableCommands = function(cat, player)
                return KittyMod_FrameworkBridge.getEnhancedCommandList(cat, player)
            end
        }
    })
    
    integrationState.registered = true
    return true
end

function KittyMod_FrameworkBridge.enableEnhancedFeatures()
    if frameworkComponents.AE_StatusMenu then
        enhancedFeatures.statusIntegration = true
    end
    
    if frameworkComponents.AE_Commands then
        enhancedFeatures.commandIntegration = true
    end
    
    if frameworkComponents.AE_FrameworkData then
        enhancedFeatures.dataSync = true
        integrationState.syncEnabled = true
    end
    
    if frameworkComponents.AE_FrameworkCore then
        enhancedFeatures.uiIntegration = true
        enhancedFeatures.behaviorEnhancement = true
    end
    
    -- Cross-mod interaction available through existing AE_CoreCommunication
    if frameworkAvailable then
        enhancedFeatures.crossModInteraction = true
    end
    
    if integrationState.registered and integrationState.syncEnabled then
        KittyMod_FrameworkBridge.initializeEnhancedIntegration()
    end
end

function KittyMod_FrameworkBridge.initializeEnhancedIntegration()
    if enhancedFeatures.dataSync then
        KittyMod_FrameworkBridge.enableSelectiveDataSync()
    end
    
    if enhancedFeatures.behaviorEnhancement then
        KittyMod_FrameworkBridge.enableBehaviorEnhancements()
    end
    
    if enhancedFeatures.crossModInteraction then
        KittyMod_FrameworkBridge.enableCrossModCapabilities()
    end
end

function KittyMod_FrameworkBridge.enableSelectiveDataSync()
    local syncKeys = {"CatTameness", "CatIsTamed", "CatOwner", "CatNickname"}
    
    sendServerCommand("AE_CrossModService", "syncComplete", {
        modName = "KittyMod",
        namespace = "KITTY_",
        syncKeys = syncKeys,
        syncDirection = "bidirectional",
        conflictResolution = "mod_authoritative"
    })
end

function KittyMod_FrameworkBridge.enableBehaviorEnhancements()
    sendServerCommand("AE_UIFramework", "componentRegistration", {
        modName = "KittyMod",
        animalType = "cat",
        enhancementTypes = {
            "personality_interaction",
            "cross_animal_socialization",
            "enhanced_command_processing",
            "environmental_adaptation"
        }
    })
end

function KittyMod_FrameworkBridge.enableCrossModCapabilities()
    sendServerCommand("AE_CrossModService", "integrationRequest", {
        modName = "KittyMod",
        capabilities = {
            animalInteraction = true,
            dataSharing = true,
            behaviorCoordination = true,
            uiIntegration = true
        }
    })
end

function KittyMod_FrameworkBridge.setupEventHandlers()
    -- B42 custom event registration via AE_EventRegistry
    if AE_EventRegistry then
        AE_EventRegistry.subscribeEvent("OnAE_DataRequest", KittyMod_FrameworkBridge.onFrameworkDataRequest)
        AE_EventRegistry.subscribeEvent("OnAE_CommandRequest", KittyMod_FrameworkBridge.onFrameworkCommandRequest)
        AE_EventRegistry.subscribeEvent("OnAE_StatusRequest", KittyMod_FrameworkBridge.onFrameworkStatusRequest)
        AE_EventRegistry.subscribeEvent("OnAE_SyncRequest", KittyMod_FrameworkBridge.onFrameworkSyncRequest)
    else
        print("[KittyMod] FrameworkBridge: AE_EventRegistry not available - using standalone mode")
    end
end

function KittyMod_FrameworkBridge.onFrameworkDataRequest(requestData)
    if not requestData or requestData.animalType ~= "cat" then return end
    
    local cat = KittyMod_SafeAPI.safeGetAnimalByID(requestData.animalID)
    if not cat or not KittyMod_ModData.isCat(cat) then return end
    
    local responseData = KittyMod_FrameworkBridge.handleFrameworkDataRequest(cat, requestData.dataTypes)
    
    sendServerCommand("AE_UIService", "dataRequest", {
        requestId = requestData.requestId,
        animalID = requestData.animalID,
        success = responseData ~= nil,
        data = responseData
    })
end

function KittyMod_FrameworkBridge.onFrameworkCommandRequest(commandData)
    if not commandData or commandData.animalType ~= "cat" then return end
    
    local cat = KittyMod_SafeAPI.safeGetAnimalByID(commandData.animalID)
    if not cat or not KittyMod_ModData.isCat(cat) then return end
    
    local KittyMod_Commands = require("KittyMod/Behaviors/KittyMod_Commands")
    local success = KittyMod_Commands.executeCommand(commandData.player, commandData.command)
    
    sendServerCommand("AE_UIService", "componentUpdate", {
        requestId = commandData.requestId,
        animalID = commandData.animalID,
        success = success,
        command = commandData.command
    })
end

function KittyMod_FrameworkBridge.onFrameworkStatusRequest(statusData)
    if not statusData or statusData.animalType ~= "cat" then return end
    
    local cat = KittyMod_SafeAPI.safeGetAnimalByID(statusData.animalID)
    if not cat or not KittyMod_ModData.isCat(cat) then return end
    
    local statusInfo = KittyMod_FrameworkBridge.getFrameworkStatusInfo(cat)
    
    sendServerCommand("AE_UIService", "componentUpdate", {
        requestId = statusData.requestId,
        animalID = statusData.animalID,
        success = statusInfo ~= nil,
        statusInfo = statusInfo
    })
end

function KittyMod_FrameworkBridge.onFrameworkSyncRequest(syncData)
    if not syncData or syncData.animalType ~= "cat" then return end
    
    local cat = KittyMod_SafeAPI.safeGetAnimalByID(syncData.animalID)
    if not cat or not KittyMod_ModData.isCat(cat) then return end
    
    local success = KittyMod_FrameworkBridge.handleFrameworkDataSync(cat, syncData.dataKey, syncData.value)
    
    sendServerCommand("AE_CrossModService", "syncComplete", {
        requestId = syncData.requestId,
        animalID = syncData.animalID,
        success = success,
        dataKey = syncData.dataKey
    })
end

function KittyMod_FrameworkBridge.handleFrameworkTaming(cat, player)
    if not cat or not player then return false end
    
    local catName = KittyMod_ModData.getCatData(cat, "CatNickname")
    local tameness = KittyMod_ModData.getCatData(cat, "CatTameness") or 0
    
    return {
        success = true,
        catName = catName,
        tameness = tameness,
        message = "Framework integrated taming completed for " .. (catName or "cat")
    }
end

function KittyMod_FrameworkBridge.handleFrameworkInteraction(cat, player, interactionType)
    if not cat or not player then return false end
    
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality")
    local mood = KittyMod_ModData.getCatData(cat, "CatMood")
    local affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 0
    
    return {
        success = true,
        personality = personality,
        mood = mood,
        affection = affection,
        interactionType = interactionType
    }
end

function KittyMod_FrameworkBridge.handleFrameworkDeath(cat, killer)
    if not cat then return false end
    
    local catName = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat"
    local owner = KittyMod_ModData.getCatData(cat, "CatOwner")
    
    return {
        success = true,
        catName = catName,
        owner = owner,
        message = catName .. " has died"
    }
end

function KittyMod_FrameworkBridge.getFrameworkStatusInfo(cat)
    if not cat or not KittyMod_ModData.isCat(cat) then return nil end
    
    return {
        name = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat",
        breed = KittyMod_ModData.getCatData(cat, "CatBreed") or "Unknown",
        personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "unknown",
        tameness = KittyMod_ModData.getCatData(cat, "CatTameness") or 0,
        isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false,
        mood = KittyMod_ModData.getCatData(cat, "CatMood") or "content",
        energy = KittyMod_ModData.getCatData(cat, "CatEnergy") or 100,
        affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 0,
        huntingSkill = KittyMod_ModData.getCatData(cat, "CatHuntingSkill") or 50,
        owner = KittyMod_ModData.getCatData(cat, "CatOwner") or ""
    }
end

function KittyMod_FrameworkBridge.addFrameworkContextOptions(cat, player, context)
    if not cat or not player or not context then return false end
    if not KittyMod_ModData.isCat(cat) then return false end
    
    local isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false
    local owner = KittyMod_ModData.getCatData(cat, "CatOwner") or ""
    
    if isTamed and owner == player:getUsername() then
        context:addOption("Cat Status", cat, function()
            local KittyMod_StatusUI = require("KittyMod/UI/KittyMod_StatusUI")
            KittyMod_StatusUI.showStatusWindow()
        end)
        
        context:addOption("Give Command", cat, function()
            local KittyMod_Commands = require("KittyMod/Behaviors/KittyMod_Commands")
            KittyMod_Commands.showCatCommandMenu(player)
        end)
    end
    
    return true
end

function KittyMod_FrameworkBridge.handleFrameworkDataRequest(cat, dataTypes)
    if not cat or not KittyMod_ModData.isCat(cat) then return nil end
    
    local data = {}
    
    if not dataTypes or #dataTypes == 0 then
        return KittyMod_ModData.getAllCatData(cat)
    end
    
    for _, dataType in ipairs(dataTypes) do
        data[dataType] = KittyMod_ModData.getCatData(cat, "Cat" .. dataType:gsub("^%l", string.upper))
    end
    
    return data
end

function KittyMod_FrameworkBridge.handleFrameworkDataSync(cat, key, value)
    if not cat or not key then return false end
    if not KittyMod_ModData.isCat(cat) then return false end
    
    local kittyKey = "Cat" .. key:gsub("^%l", string.upper)
    return KittyMod_ModData.setCatData(cat, kittyKey, value)
end

function KittyMod_FrameworkBridge.isFrameworkAvailable()
    return frameworkAvailable
end

function KittyMod_FrameworkBridge.isFeatureEnabled(feature)
    return enhancedFeatures[feature] or false
end

function KittyMod_FrameworkBridge.getFrameworkComponents()
    return frameworkComponents
end

function KittyMod_FrameworkBridge.getEnhancedFeatures()
    return enhancedFeatures
end

function KittyMod_FrameworkBridge.getIntegrationState()
    return integrationState
end

function KittyMod_FrameworkBridge.handleEnhancedBehavior(cat, behaviorType, context)
    if not cat or not KittyMod_ModData.isCat(cat) then return nil end
    if not enhancedFeatures.behaviorEnhancement then return nil end
    
    local KittyMod_Behaviors = require("KittyMod/Behaviors/KittyMod_Behaviors")
    
    if behaviorType == "personality_interaction" then
        return KittyMod_Behaviors.getPersonalityInteractionData(cat, context)
    elseif behaviorType == "cross_animal_socialization" then
        return KittyMod_Behaviors.handleCrossAnimalInteraction(cat, context.targetAnimal)
    elseif behaviorType == "environmental_adaptation" then
        return KittyMod_Behaviors.adaptToEnvironment(cat, context.environment)
    end
    
    return nil
end

function KittyMod_FrameworkBridge.getEnhancedStatusInfo(cat, displayType)
    if not cat or not KittyMod_ModData.isCat(cat) then return nil end
    if not enhancedFeatures.statusIntegration then 
        return KittyMod_FrameworkBridge.getFrameworkStatusInfo(cat)
    end
    
    local baseInfo = KittyMod_FrameworkBridge.getFrameworkStatusInfo(cat)
    
    if displayType == "detailed" then
        baseInfo.furPattern = KittyMod_ModData.getCatData(cat, "CatFurPattern") or "unknown"
        baseInfo.furColor = KittyMod_ModData.getCatData(cat, "CatFurColor") or "unknown"
        baseInfo.playfulness = KittyMod_ModData.getCatData(cat, "CatPlayfulness") or 50
        baseInfo.loyalty = KittyMod_ModData.getCatData(cat, "CatLoyalty") or 0
        baseInfo.lastFed = KittyMod_ModData.getCatData(cat, "CatLastFed") or 0
        baseInfo.sleepLocation = KittyMod_ModData.getCatData(cat, "CatSleepLocation") or "unknown"
    elseif displayType == "compact" then
        return {
            name = baseInfo.name,
            breed = baseInfo.breed,
            tameness = baseInfo.tameness,
            mood = baseInfo.mood,
            isTamed = baseInfo.isTamed
        }
    end
    
    return baseInfo
end

function KittyMod_FrameworkBridge.handleEnhancedCommand(cat, player, command, parameters)
    if not cat or not player or not KittyMod_ModData.isCat(cat) then return false end
    if not enhancedFeatures.commandIntegration then return false end
    
    local KittyMod_Commands = require("KittyMod/Behaviors/KittyMod_Commands")
    
    if command == "enhanced_hunt" then
        return KittyMod_Commands.executeEnhancedHunt(player, cat, parameters)
    elseif command == "social_interaction" then
        return KittyMod_Commands.executeSocialInteraction(player, cat, parameters.targetAnimal)
    elseif command == "environmental_exploration" then
        return KittyMod_Commands.executeEnvironmentalExploration(player, cat, parameters.area)
    else
        return KittyMod_Commands.executeCommand(player, command)
    end
end

function KittyMod_FrameworkBridge.getEnhancedCommandList(cat, player)
    if not cat or not player or not KittyMod_ModData.isCat(cat) then return {} end
    
    local KittyMod_Commands = require("KittyMod/Behaviors/KittyMod_Commands")
    local baseCommands = KittyMod_Commands.getAvailableCommands(cat, player)
    
    if not enhancedFeatures.commandIntegration then return baseCommands end
    
    local enhancedCommands = {
        {command = "enhanced_hunt", label = "Enhanced Hunt", description = "Framework-coordinated hunting with other animals"},
        {command = "social_interaction", label = "Social Interaction", description = "Interact with other framework animals"},
        {command = "environmental_exploration", label = "Environmental Exploration", description = "Explore area with framework guidance"}
    }
    
    for _, enhancedCmd in ipairs(enhancedCommands) do
        table.insert(baseCommands, enhancedCmd)
    end
    
    return baseCommands
end

function KittyMod_FrameworkBridge.handleCrossModDataRequest(cat, requestingMod, dataScope)
    if not cat or not requestingMod or not KittyMod_ModData.isCat(cat) then return nil end
    if not enhancedFeatures.crossModInteraction then return nil end
    
    local allowedData = {}
    
    if dataScope == "basic" then
        allowedData = {
            animalType = "cat",
            isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false,
            tameness = KittyMod_ModData.getCatData(cat, "CatTameness") or 0,
            owner = KittyMod_ModData.getCatData(cat, "CatOwner") or ""
        }
    elseif dataScope == "interaction" then
        allowedData = {
            personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "unknown",
            mood = KittyMod_ModData.getCatData(cat, "CatMood") or "content",
            affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 0,
            socializable = true
        }
    end
    
    return allowedData
end

function KittyMod_FrameworkBridge.handleFrameworkLoss()
    for feature, _ in pairs(enhancedFeatures) do
        enhancedFeatures[feature] = false
    end
    
    integrationState.registered = false
    integrationState.syncEnabled = false
    integrationState.enhancementsActive = false
    frameworkAvailable = false
    
    sendServerCommand("AE_CrossModService", "statusUpdate", {
        modName = "KittyMod",
        status = "frameworkLost",
        timestamp = getTimestamp(),
        reason = "framework_unavailable"
    })
end

function KittyMod_FrameworkBridge.handleServiceFailure(serviceName, error)
    if frameworkServices[serviceName] then
        frameworkServices[serviceName] = nil
    end
    
    if serviceName == "AE_FrameworkData" then
        enhancedFeatures.dataSync = false
        integrationState.syncEnabled = false
    end
    
    sendServerCommand("AE_CrossModService", "statusUpdate", {
        serviceName = serviceName,
        error = error,
        timestamp = getTimestamp()
    })
end

function KittyMod_FrameworkBridge.handleDataConflict(cat, conflictType, kittyData, frameworkData)
    if not cat or not KittyMod_ModData.isCat(cat) then return kittyData end
    
    if conflictType == "tameness_mismatch" then
        local kittyTameness = kittyData or 0
        local frameworkTameness = frameworkData or 0
        
        return math.max(kittyTameness, frameworkTameness)
    elseif conflictType == "owner_mismatch" then
        return kittyData
    end
    
    return kittyData
end

Events.OnGameStart.Add(KittyMod_FrameworkBridge.initialize)

return KittyMod_FrameworkBridge