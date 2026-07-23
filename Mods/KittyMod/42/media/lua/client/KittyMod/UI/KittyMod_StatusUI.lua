--[[
local KittyMod_StatusUI = {}
local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
local KittyMod_SafeAPI = require("KittyMod/Core/KittyMod_SafeAPI")
local statusWindow = nil
local selectedCat = nil
local frameworkIntegration = {
    available = false,
    uiEventCoordinator = nil,
    contextMenuIntegration = nil,
    dataService = nil
}

local enhancedUIFeatures = {
    realTimeUpdates = false,
    frameworkContextMenu = false,
    crossModDataSync = false,
    enhancedStatusDisplay = false
}

function KittyMod_StatusUI.initialize()
    Events.OnCreatePlayer.Add(KittyMod_StatusUI.onCreatePlayer)
    Events.OnKeyPressed.Add(KittyMod_StatusUI.onKeyPressed)
    KittyMod_StatusUI.initializeFrameworkIntegration()
    KittyMod_StatusUI.registerWithFramework()
end

function KittyMod_StatusUI.initializeFrameworkIntegration()
    local coordinatorSuccess, coordinator = pcall(function()
        return require("AnimalsEssentials/UI/AE_UIEventCoordinator")
    end)
    if coordinatorSuccess and coordinator then
        frameworkIntegration.uiEventCoordinator = coordinator
        enhancedUIFeatures.realTimeUpdates = true
        enhancedUIFeatures.crossModDataSync = true
    end

    local contextSuccess, contextMenu = pcall(function()
        return require("AnimalsEssentials/UI/AE_ContextMenuIntegration")
    end)
    if contextSuccess and contextMenu then
        frameworkIntegration.contextMenuIntegration = contextMenu
        enhancedUIFeatures.frameworkContextMenu = true
    end

    
    local dataSuccess, dataService = pcall(function()
        return require("AnimalsEssentials/DataServices/AE_DataService")
    end)
    if dataSuccess and dataService then
        frameworkIntegration.dataService = dataService
        enhancedUIFeatures.enhancedStatusDisplay = true
    end
    
    frameworkIntegration.available = frameworkIntegration.uiEventCoordinator ~= nil
end

function KittyMod_StatusUI.registerWithFramework()
    if not frameworkIntegration.uiEventCoordinator then return false end
    
    sendServerCommand("AE_UIFramework", "componentRegistration", {
        componentName = "KittyMod_StatusUI",
        modSource = "KittyMod",
        capabilities = {
            "catStatusDisplay",
            "independentOperation", 
            "frameworkIntegration",
            "realTimeUpdates"
        },
        eventHandlers = {
            "catStatusUpdate",
            "frameworkDataSync",
            "crossModCommunication"
        },
        dependencies = {
            required = {},
            optional = {"AE_DataService", "AE_ContextMenuIntegration"}
        }
    })
    if enhancedUIFeatures.crossModDataSync and Events.OnAE_CrossMod_UIRequest then
        Events.OnAE_CrossMod_UIRequest.Add(function(eventData)
            if eventData.targetMod == "KittyMod" then
                KittyMod_StatusUI.handleFrameworkUIRequest(eventData)
            end
        end)
    end
    
    return true
end

function KittyMod_StatusUI.registerFrameworkDirect()
    if not frameworkIntegration.uiEventCoordinator then return false end

    local registrationData = {
        componentName = "KittyMod_StatusUI",
        modSource = "KittyMod",
        capabilities = {
            "catStatusDisplay",
            "independentOperation", 
            "frameworkIntegration",
            "realTimeUpdates"
        },
        eventHandlers = {
            "catStatusUpdate",
            "frameworkDataSync",
            "crossModCommunication"
        },
        dependencies = {
            required = {},
            optional = {"AE_DataService", "AE_ContextMenuIntegration"}
        }
    }
    
    -- Attempt direct registration through coordinator
    if frameworkIntegration.uiEventCoordinator.registerUIComponent then
        return frameworkIntegration.uiEventCoordinator.registerUIComponent(registrationData)
    end
    
    print("[KittyMod] Framework registration: No suitable method available")
    return false
end

function KittyMod_StatusUI.handleFrameworkUIRequest(requestData)
    if not requestData or not requestData.requestType then return false end
    
    local requestType = requestData.requestType
    
    if requestType == "showCatStatus" and requestData.animal then
        if KittyMod_ModData.isCat(requestData.animal) then
            selectedCat = requestData.animal
            KittyMod_StatusUI.showEnhancedStatusWindow()
            return true
        end
    elseif requestType == "updateCatDisplay" and requestData.catID then
        if selectedCat and selectedCat:getAnimalId() == requestData.catID then
            KittyMod_StatusUI.updateStatusDisplay()
            return true
        end
    elseif requestType == "contextMenuIntegration" then
        return KittyMod_StatusUI.provideCatContextOptions(requestData)
    end
    
    return false
end

function KittyMod_StatusUI.onCreatePlayer(playerIndex, player)
    if playerIndex == 0 then
        KittyMod_StatusUI.createStatusWindow()
    end
end

function KittyMod_StatusUI.onKeyPressed(key)
    if key == Keyboard.KEY_C then
        KittyMod_StatusUI.toggleStatusWindow()
    end
end

function KittyMod_StatusUI.createStatusWindow()
    if statusWindow then return end
    local windowHeight = frameworkIntegration.available and 380 or 300
    
    statusWindow = ISPanel:new(100, 100, 400, windowHeight)
    statusWindow:setAnchorLeft(false)
    statusWindow:setAnchorRight(true)
    statusWindow:setAnchorTop(true)
    statusWindow:setAnchorBottom(false)
    statusWindow:addToUIManager()
    statusWindow:setVisible(false)
    statusWindow.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    statusWindow.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    local titleText = frameworkIntegration.available and "Cat Status (Enhanced)" or "Cat Status"
    statusWindow.titleLabel = ISLabel:new(10, 10, 20, titleText, 1, 1, 1, 1, UIFont.Medium, true)
    statusWindow:addChild(statusWindow.titleLabel)
    statusWindow.nameLabel = ISLabel:new(10, 40, 20, "No cat selected", 1, 1, 1, 1, UIFont.Small, true)
    statusWindow:addChild(statusWindow.nameLabel)
    statusWindow.breedLabel = ISLabel:new(10, 60, 20, "", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    statusWindow:addChild(statusWindow.breedLabel)
    statusWindow.tamenessLabel = ISLabel:new(10, 90, 20, "", 0.7, 1, 0.7, 1, UIFont.Small, true)
    statusWindow:addChild(statusWindow.tamenessLabel)
    statusWindow.personalityLabel = ISLabel:new(10, 110, 20, "", 1, 0.8, 0.6, 1, UIFont.Small, true)
    statusWindow:addChild(statusWindow.personalityLabel)
    statusWindow.moodLabel = ISLabel:new(10, 130, 20, "", 0.8, 0.8, 1, 1, UIFont.Small, true)
    statusWindow:addChild(statusWindow.moodLabel)
    statusWindow.energyLabel = ISLabel:new(10, 150, 20, "", 1, 1, 0.8, 1, UIFont.Small, true)
    statusWindow:addChild(statusWindow.energyLabel)
    statusWindow.huntingLabel = ISLabel:new(10, 170, 20, "", 0.8, 1, 0.8, 1, UIFont.Small, true)
    statusWindow:addChild(statusWindow.huntingLabel)
    statusWindow.affectionLabel = ISLabel:new(10, 190, 20, "", 1, 0.8, 0.8, 1, UIFont.Small, true)
    statusWindow:addChild(statusWindow.affectionLabel)
    if frameworkIntegration.available then
        statusWindow.frameworkDataLabel = ISLabel:new(10, 210, 20, "", 0.9, 0.9, 0.7, 1, UIFont.Small, true)
        statusWindow:addChild(statusWindow.frameworkDataLabel)
        statusWindow.frameworkIndicator = ISLabel:new(10, 230, 20, "Enhanced by AE Framework", 0.7, 0.9, 0.7, 1, UIFont.Small, true)
        statusWindow:addChild(statusWindow.frameworkIndicator)
        if enhancedUIFeatures.crossModDataSync then
            statusWindow.frameworkCommandsButton = ISButton:new(100, 320, 120, 25, "Framework Commands", statusWindow, function()
                KittyMod_StatusUI.showFrameworkCommands()
            end)
            statusWindow:addChild(statusWindow.frameworkCommandsButton)
        end
    end
    
    local buttonY = frameworkIntegration.available and 320 or 250
    
    statusWindow.refreshButton = ISButton:new(10, buttonY, 80, 25, "Refresh", statusWindow, KittyMod_StatusUI.refreshStatus)
    statusWindow:addChild(statusWindow.refreshButton)
    
    statusWindow.closeButton = ISButton:new(300, buttonY, 80, 25, "Close", statusWindow, KittyMod_StatusUI.hideStatusWindow)
    statusWindow:addChild(statusWindow.closeButton)
end

function KittyMod_StatusUI.toggleStatusWindow()
    if not statusWindow then
        KittyMod_StatusUI.createStatusWindow()
    end
    if statusWindow:isVisible() then
        KittyMod_StatusUI.hideStatusWindow()
    else
        KittyMod_StatusUI.showStatusWindow()
    end
end

function KittyMod_StatusUI.showStatusWindow()
    if not statusWindow then return end
    
    local player = getPlayer()
    if not player then return end
    
    local nearestCat = KittyMod_StatusUI.findNearestCat(player)
    if nearestCat then
        selectedCat = nearestCat
        if frameworkIntegration.available and enhancedUIFeatures.enhancedStatusDisplay then
            KittyMod_StatusUI.showEnhancedStatusWindow()
        else
            KittyMod_StatusUI.updateStatusDisplay()
            statusWindow:setVisible(true)
        end
    end
end

function KittyMod_StatusUI.showEnhancedStatusWindow()
    if not selectedCat then return false end
    if enhancedUIFeatures.realTimeUpdates then
        KittyMod_StatusUI.subscribeToFrameworkUpdates()
    end
    if frameworkIntegration.dataService then
        sendServerCommand("AE_UIService", "dataRequest", {
            requestType = "enhancedCatStatus",
            animalID = selectedCat:getAnimalId(),
            uiComponent = "KittyMod_StatusUI",
            responseHandler = function(responseData)
                if responseData.success then
                    KittyMod_StatusUI.displayEnhancedCatData(responseData.catData)
                else
                    KittyMod_StatusUI.updateStatusDisplay()
                end
            end
        })
    else
        KittyMod_StatusUI.updateStatusDisplay()
    end
    statusWindow:setVisible(true)
    return true
end

function KittyMod_StatusUI.subscribeToFrameworkUpdates()
    if not selectedCat or not frameworkIntegration.available then return end
    local catID = selectedCat:getAnimalId()
    Events.OnAE_AnimalDataChanged.Add(function(eventData)
        if eventData.animalID == catID and statusWindow and statusWindow:isVisible() then
            KittyMod_StatusUI.handleFrameworkDataUpdate(eventData)
        end
    end)
end

function KittyMod_StatusUI.handleFrameworkDataUpdate(eventData)
    if not eventData or not eventData.changedData then return end
    for dataKey, newValue in pairs(eventData.changedData) do
        if dataKey == "CatTameness" then
            KittyMod_StatusUI.updateTamenessDisplay(newValue)
        elseif dataKey == "CatMood" then
            KittyMod_StatusUI.updateMoodDisplay(newValue)
        elseif dataKey == "CatAffection" then
            KittyMod_StatusUI.updateAffectionDisplay(newValue)
        elseif dataKey == "CatEnergy" then
            KittyMod_StatusUI.updateEnergyDisplay(newValue)
        end
    end
end


function KittyMod_StatusUI.displayEnhancedCatData(catData)
    if not statusWindow or not catData then return end
    local catName = catData.name or KittyMod_ModData.getCatData(selectedCat, "CatNickname") or "Unknown Cat"
    local breed = catData.breed or KittyMod_ModData.getCatData(selectedCat, "CatBreed") or "Unknown"
    local personality = catData.personality or KittyMod_ModData.getCatData(selectedCat, "CatPersonality") or "Unknown"
    local tameness = catData.tameness or KittyMod_ModData.getCatData(selectedCat, "CatTameness") or 0
    local isTamed = catData.isTamed or KittyMod_ModData.getCatData(selectedCat, "CatIsTamed") or false
    local mood = catData.mood or KittyMod_ModData.getCatData(selectedCat, "CatMood") or "content"
    local energy = catData.energy or KittyMod_ModData.getCatData(selectedCat, "CatEnergy") or 100
    local huntingSkill = catData.huntingSkill or KittyMod_ModData.getCatData(selectedCat, "CatHuntingSkill") or 50
    local affection = catData.affection or KittyMod_ModData.getCatData(selectedCat, "CatAffection") or 0
    local health = catData.health or 100
    local hunger = catData.hunger or 0
    local thirst = catData.thirst or 0
    
    statusWindow.nameLabel:setName(catName .. (isTamed and (" (Tamed)") or " (Wild)"))
    statusWindow.breedLabel:setName("Breed: " .. breed)
    statusWindow.tamenessLabel:setName("Tameness: " .. math.floor(tameness) .. "%")
    statusWindow.personalityLabel:setName("Personality: " .. personality:gsub("^%l", string.upper))
    statusWindow.moodLabel:setName("Mood: " .. mood:gsub("^%l", string.upper))
    statusWindow.energyLabel:setName("Energy: " .. math.floor(energy) .. "%")
    statusWindow.huntingLabel:setName("Hunting Skill: " .. math.floor(huntingSkill) .. "%")
    
    if frameworkIntegration.dataService then
        if isTamed then
            statusWindow.affectionLabel:setName("Affection: " .. math.floor(affection) .. "%")
        else
            statusWindow.affectionLabel:setName("Affection: Unknown")
        end
        
        KittyMod_StatusUI.updateFrameworkSpecificElements(health, hunger, thirst)
    end
end

function KittyMod_StatusUI.updateFrameworkSpecificElements(health, hunger, thirst)
    if statusWindow.frameworkDataLabel then
        local frameworkText = string.format("Health: %d%% | Hunger: %d%% | Thirst: %d%%", 
            math.floor(health), math.floor(hunger), math.floor(thirst))
        statusWindow.frameworkDataLabel:setName(frameworkText)
    end
end

function KittyMod_StatusUI.updateTamenessDisplay(newValue)
    if statusWindow and statusWindow.tamenessLabel then
        statusWindow.tamenessLabel:setName("Tameness: " .. math.floor(newValue) .. "%")
    end
end

function KittyMod_StatusUI.updateMoodDisplay(newValue)
    if statusWindow and statusWindow.moodLabel then
        statusWindow.moodLabel:setName("Mood: " .. newValue:gsub("^%l", string.upper))
    end
end

function KittyMod_StatusUI.updateAffectionDisplay(newValue)
    if statusWindow and statusWindow.affectionLabel then
        local isTamed = KittyMod_ModData.getCatData(selectedCat, "CatIsTamed") or false
        if isTamed then
            statusWindow.affectionLabel:setName("Affection: " .. math.floor(newValue) .. "%")
        end
    end
end

function KittyMod_StatusUI.updateEnergyDisplay(newValue)
    if statusWindow and statusWindow.energyLabel then
        statusWindow.energyLabel:setName("Energy: " .. math.floor(newValue) .. "%")
    end
end

function KittyMod_StatusUI.hideStatusWindow()
    if statusWindow then
        statusWindow:setVisible(false)
        selectedCat = nil
    end
end

function KittyMod_StatusUI.findNearestCat(player)
    if not player then return nil end
    
    local nearbyAnimals = KittyMod_SafeAPI.getAnimalsInRange(player, 8)
    if not nearbyAnimals then return nil end
    
    local nearestCat = nil
    local nearestDistance = 999
    
    for i = 0, nearbyAnimals:size() - 1 do
        local animal = nearbyAnimals:get(i)
        if KittyMod_ModData.isCat(animal) then
            local distance = IsoUtils.DistanceTo(player:getX(), player:getY(), animal:getX(), animal:getY())
            if distance < nearestDistance then
                nearestDistance = distance
                nearestCat = animal
            end
        end
    end
    
    return nearestCat
end

function KittyMod_StatusUI.updateStatusDisplay()
    if not statusWindow or not selectedCat then return end
    
    local catName = KittyMod_ModData.getCatData(selectedCat, "CatNickname") or "Unknown Cat"
    local breed = KittyMod_ModData.getCatData(selectedCat, "CatBreed") or "Unknown"
    local personality = KittyMod_ModData.getCatData(selectedCat, "CatPersonality") or "Unknown"
    local tameness = KittyMod_ModData.getCatData(selectedCat, "CatTameness") or 0
    local isTamed = KittyMod_ModData.getCatData(selectedCat, "CatIsTamed") or false
    local mood = KittyMod_ModData.getCatData(selectedCat, "CatMood") or "content"
    local energy = KittyMod_ModData.getCatData(selectedCat, "CatEnergy") or 100
    local huntingSkill = KittyMod_ModData.getCatData(selectedCat, "CatHuntingSkill") or 50
    local affection = KittyMod_ModData.getCatData(selectedCat, "CatAffection") or 0
    
    statusWindow.nameLabel:setName(catName .. (isTamed and " (Tamed)" or " (Wild)"))
    statusWindow.breedLabel:setName("Breed: " .. breed)
    statusWindow.tamenessLabel:setName("Tameness: " .. math.floor(tameness) .. "%")
    statusWindow.personalityLabel:setName("Personality: " .. personality:gsub("^%l", string.upper))
    statusWindow.moodLabel:setName("Mood: " .. mood:gsub("^%l", string.upper))
    statusWindow.energyLabel:setName("Energy: " .. math.floor(energy) .. "%")
    statusWindow.huntingLabel:setName("Hunting Skill: " .. math.floor(huntingSkill) .. "%")
    
    if isTamed then
        statusWindow.affectionLabel:setName("Affection: " .. math.floor(affection) .. "%")
    else
        statusWindow.affectionLabel:setName("Affection: Unknown")
    end
end

function KittyMod_StatusUI.refreshStatus()
    if selectedCat then
        KittyMod_StatusUI.updateStatusDisplay()
    else
        local player = getPlayer()
        if player then
            selectedCat = KittyMod_StatusUI.findNearestCat(player)
            if selectedCat then
                KittyMod_StatusUI.updateStatusDisplay()
            else
                player:Say("No cats nearby")
            end
        end
    end
end

function KittyMod_StatusUI.getCatStatusText(cat)
    if not cat or not KittyMod_ModData.isCat(cat) then return "Not a cat" end
    
    local catName = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat"
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "unknown"
    local mood = KittyMod_ModData.getCatData(cat, "CatMood") or "content"
    local isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false
    
    return catName .. " - " .. personality:gsub("^%l", string.upper) .. " (" .. mood .. ")" .. (isTamed and " [Tamed]" or " [Wild]")
end

function KittyMod_StatusUI.provideCatContextOptions(requestData)
    if not requestData or not requestData.animal or not KittyMod_ModData.isCat(requestData.animal) then
        return false
    end
    
    local cat = requestData.animal
    local player = requestData.player or getPlayer()
    local contextOptions = {}
    
    table.insert(contextOptions, {
        text = "View Cat Status (KittyMod)",
        icon = "cat_status_icon",
        action = function()
            selectedCat = cat
            KittyMod_StatusUI.showStatusWindow()
        end,
        condition = function() return true end
    })
    
    if frameworkIntegration.available then
        local isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false
        
        if isTamed then
            table.insert(contextOptions, {
                text = "Enhanced Cat Commands",
                icon = "cat_commands_icon",
                action = function()
                    KittyMod_StatusUI.showFrameworkCommands(cat)
                end,
                condition = function() return enhancedUIFeatures.crossModDataSync end
            })
        end
        
        table.insert(contextOptions, {
            text = "Sync with Framework",
            icon = "sync_icon",
            action = function()
                KittyMod_StatusUI.syncCatDataWithFramework(cat)
            end,
            condition = function() return enhancedUIFeatures.crossModDataSync end
        })
    end
    
    if requestData.responseHandler then
        requestData.responseHandler({
            success = true,
            contextOptions = contextOptions,
            modName = "KittyMod"
        })
    end
    
    return true
end

function KittyMod_StatusUI.showFrameworkCommands(cat)
    if not cat or not frameworkIntegration.available then return false end
    
    local catID = cat:getAnimalId()
    
    sendServerCommand("AE_CrossModService", "integrationRequest", {
        sourceMod = "KittyMod",
        targetMod = "AE_FrameworkCore", 
        requestType = "showCommandInterface",
        animal = cat,
        animalID = catID,
        animalType = "cat",
        specialization = "KittyMod"
    })
    
    return true
end

function KittyMod_StatusUI.syncCatDataWithFramework(cat)
    if not cat or not frameworkIntegration.available then return false end
    

    local catData = {
        animalID = cat:getAnimalId(),
        catName = KittyMod_ModData.getCatData(cat, "CatNickname"),
        breed = KittyMod_ModData.getCatData(cat, "CatBreed"),
        personality = KittyMod_ModData.getCatData(cat, "CatPersonality"),
        tameness = KittyMod_ModData.getCatData(cat, "CatTameness"),
        isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed"),
        mood = KittyMod_ModData.getCatData(cat, "CatMood"),
        energy = KittyMod_ModData.getCatData(cat, "CatEnergy"),
        huntingSkill = KittyMod_ModData.getCatData(cat, "CatHuntingSkill"),
        affection = KittyMod_ModData.getCatData(cat, "CatAffection")
    }
    
    sendServerCommand("AE_CrossModService", "integrationRequest", {
        sourceMod = "KittyMod",
        requestType = "dataSync",
        animal = cat,
        catData = catData,
        syncType = "catToFramework",
        responseHandler = function(responseData)
            if responseData.success then
                if selectedCat == cat then
                    KittyMod_StatusUI.updateStatusDisplay()
                end
            end
        end
    })
    
    return true
end

function KittyMod_StatusUI.getFrameworkIntegrationStatus()
    return {
        available = frameworkIntegration.available,
        features = enhancedUIFeatures,
        components = {
            uiEventCoordinator = frameworkIntegration.uiEventCoordinator ~= nil,
            contextMenuIntegration = frameworkIntegration.contextMenuIntegration ~= nil,
            dataService = frameworkIntegration.dataService ~= nil
        }
    }
end

local uiPerformanceOptimization = {
    updateThrottling = {},
    lastUpdateTimes = {},
    pendingUpdates = {},
    cacheEnabled = true
}

function KittyMod_StatusUI.throttledUpdateStatusDisplay(delay)
    delay = delay or 100
    local currentTime = getTimestamp()
    local lastUpdate = uiPerformanceOptimization.lastUpdateTimes.statusDisplay or 0
    
    if currentTime - lastUpdate >= delay then
        KittyMod_StatusUI.updateStatusDisplay()
        uiPerformanceOptimization.lastUpdateTimes.statusDisplay = currentTime
        

        uiPerformanceOptimization.pendingUpdates.statusDisplay = nil
    else

        if not uiPerformanceOptimization.pendingUpdates.statusDisplay then
            uiPerformanceOptimization.pendingUpdates.statusDisplay = true
            
            local function delayedUpdateHandler()
                local checkTime = getTimestamp()
                if checkTime >= lastUpdate + delay then
                    KittyMod_StatusUI.updateStatusDisplay()
                    uiPerformanceOptimization.lastUpdateTimes.statusDisplay = checkTime
                    uiPerformanceOptimization.pendingUpdates.statusDisplay = nil
                    Events.OnTick.Remove(delayedUpdateHandler)
                end
            end
            
            Events.OnTick.Add(delayedUpdateHandler)
        end
    end
end

function KittyMod_StatusUI.validateStandaloneOperation()
    local validationResults = {
        catDetection = false,
        dataAccess = false,
        uiDisplay = false,
        keyboardInput = false,
        independence = false
    }
    

    local player = getPlayer()
    if player then
        local nearbyAnimals = KittyMod_SafeAPI.getAnimalsInRange(player, 8)
        if nearbyAnimals then
            validationResults.catDetection = true
        end
    end
    

    if KittyMod_ModData and KittyMod_ModData.isCat then
        validationResults.dataAccess = true
    end

    if not statusWindow then
        KittyMod_StatusUI.createStatusWindow()
    end
    if statusWindow then
        validationResults.uiDisplay = true
    end
    
    validationResults.keyboardInput = Events.OnKeyPressed ~= nil
    
    validationResults.independence = not frameworkIntegration.available or true
    
    return validationResults
end

function KittyMod_StatusUI.getPerformanceMetrics()
    return {
        frameworkAvailable = frameworkIntegration.available,
        enhancedFeaturesActive = enhancedUIFeatures,
        updateThrottling = uiPerformanceOptimization.updateThrottling,
        lastUpdateTimes = uiPerformanceOptimization.lastUpdateTimes,
        pendingUpdates = uiPerformanceOptimization.pendingUpdates,
        standalone = {
            validation = KittyMod_StatusUI.validateStandaloneOperation(),
            keyboardShortcut = "C",
            independence = "Complete"
        }
    }
end


local catDataCache = {}
local CACHE_DURATION = 2000

function KittyMod_StatusUI.getCachedCatData(cat, dataKey)
    if not cat or not dataKey then return nil end
    
    local catID = cat:getAnimalId()
    local cacheKey = catID .. "_" .. dataKey
    local currentTime = getTimestamp()
    
    if catDataCache[cacheKey] and 
       (currentTime - catDataCache[cacheKey].timestamp) < CACHE_DURATION then
        return catDataCache[cacheKey].value
    end
    
    local value = KittyMod_ModData.getCatData(cat, dataKey)
    
    catDataCache[cacheKey] = {
        value = value,
        timestamp = currentTime
    }
    
    return value
end

function KittyMod_StatusUI.updateStatusDisplayOptimized()
    if not statusWindow or not selectedCat then return end
    local catName = KittyMod_StatusUI.getCachedCatData(selectedCat, "CatNickname") or "Unknown Cat"
    local breed = KittyMod_StatusUI.getCachedCatData(selectedCat, "CatBreed") or "Unknown"
    local personality = KittyMod_StatusUI.getCachedCatData(selectedCat, "CatPersonality") or "Unknown"
    local tameness = KittyMod_StatusUI.getCachedCatData(selectedCat, "CatTameness") or 0
    local isTamed = KittyMod_StatusUI.getCachedCatData(selectedCat, "CatIsTamed") or false
    local mood = KittyMod_StatusUI.getCachedCatData(selectedCat, "CatMood") or "content"
    local energy = KittyMod_StatusUI.getCachedCatData(selectedCat, "CatEnergy") or 100
    local huntingSkill = KittyMod_StatusUI.getCachedCatData(selectedCat, "CatHuntingSkill") or 50
    local affection = KittyMod_StatusUI.getCachedCatData(selectedCat, "CatAffection") or 0
    local updates = {
        {statusWindow.nameLabel, catName .. (isTamed and " (Tamed)" or " (Wild)")},
        {statusWindow.breedLabel, "Breed: " .. breed},
        {statusWindow.tamenessLabel, "Tameness: " .. math.floor(tameness) .. "%"},
        {statusWindow.personalityLabel, "Personality: " .. personality:gsub("^%l", string.upper)},
        {statusWindow.moodLabel, "Mood: " .. mood:gsub("^%l", string.upper)},
        {statusWindow.energyLabel, "Energy: " .. math.floor(energy) .. "%"},
        {statusWindow.huntingLabel, "Hunting Skill: " .. math.floor(huntingSkill) .. "%"}
    }
    
    for _, update in ipairs(updates) do
        local label, text = update[1], update[2]
        if label then
            label:setName(text)
        end
    end
    if isTamed then
        statusWindow.affectionLabel:setName("Affection: " .. math.floor(affection) .. "%")
    else
        statusWindow.affectionLabel:setName("Affection: Unknown")
    end
end

function KittyMod_StatusUI.clearPerformanceCaches()
    catDataCache = {}
    uiPerformanceOptimization.updateThrottling = {}
    uiPerformanceOptimization.lastUpdateTimes = {}
    uiPerformanceOptimization.pendingUpdates = {}
end

function KittyMod_StatusUI.cleanup()
    if frameworkIntegration.available then
        sendServerCommand("AE_UIFramework", "componentRegistration", {
            componentName = "KittyMod_StatusUI",
            modSource = "KittyMod"
        })
    end
    
    selectedCat = nil
    if statusWindow then
        statusWindow:setVisible(false)
        statusWindow = nil
    end
    
    KittyMod_StatusUI.clearPerformanceCaches()
    frameworkIntegration = {
        available = false,
        uiEventCoordinator = nil,
        contextMenuIntegration = nil,
        dataService = nil
    }
    
    enhancedUIFeatures = {
        realTimeUpdates = false,
        frameworkContextMenu = false,
        crossModDataSync = false,
        enhancedStatusDisplay = false
    }
end

Events.OnGameStart.Add(KittyMod_StatusUI.initialize)
Events.OnGameBoot.Add(KittyMod_StatusUI.cleanup)

return KittyMod_StatusUI
--]]