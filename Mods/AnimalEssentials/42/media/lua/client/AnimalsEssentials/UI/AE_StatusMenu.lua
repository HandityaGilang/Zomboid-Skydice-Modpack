
local AE_StatusMenu = {}

local AE_DataService = nil
local AE_EnhancedLookups = nil
local AE_EventRegistry = require("AnimalsEssentials/Config/AE_EventRegistry")

local statusWindow = nil
local selectedAnimal = nil
local eventSubscriptions = {}
local uiUpdateQueue = {}

function AE_StatusMenu.initializeDependencies()
    local success, result = pcall(function()
        return require("AnimalsEssentials/DataServices/AE_DataService")
    end)
    if success and result then
        AE_DataService = result
    end
    
    local success2, result2 = pcall(function()
        return require("AnimalsEssentials/Core/AE_EnhancedLookups")
    end)
    if success2 and result2 then
        AE_EnhancedLookups = result2
    end
    
end

function AE_StatusMenu.updateAnimalDisplay(animal)
    if not animal then
        return false
    end
    
    if not statusWindow or not statusWindow:isVisible() then
        return false
    end
    
    if not AE_DataService then
        AE_StatusMenu.displayErrorMessage("Data service unavailable")
        return false
    end
    
    sendServerCommand("AE_UIService", "dataRequest", {
        requestType = "animalStatus",
        animalID = animal:getAnimalID(),
        uiComponent = "StatusMenu",
        responseHandler = function(responseData)
            if responseData.success and responseData.animalData then
                AE_StatusMenu.displayAnimalStats(responseData.animalData)
            else
                AE_StatusMenu.displayErrorMessage("Unable to retrieve animal data")
            end
        end
    })
    
    return true
end

function AE_StatusMenu.subscribeToDataEvents(animal)
    if not animal then
        return false
    end
    
    AE_StatusMenu.unsubscribeFromDataEvents()
    
    local animalID = animal:getAnimalID()
    
    local AE_EventRegistry = nil
    local success, result = pcall(function()
        return require("AnimalsEssentials/Config/AE_EventRegistry")
    end)
    if success and result then
        AE_EventRegistry = result
        
        if AE_EventRegistry.subscribeEvent then
            eventSubscriptions.dataChanges = AE_EventRegistry.subscribeEvent("OnAE_AnimalDataChanged", function(eventData)
                if eventData.animalID == animalID and statusWindow and statusWindow:isVisible() then
                    AE_StatusMenu.handleRealTimeDataUpdate(eventData)
                end
            end)
            
  
            eventSubscriptions.stateChanges = AE_EventRegistry.subscribeEvent("OnAE_AnimalStateChanged", function(eventData)
                if eventData.animalID == animalID and statusWindow and statusWindow:isVisible() then
                    AE_StatusMenu.handleAnimalStateUpdate(eventData)
                end
            end)
        end
    else
        print("[AE_StatusMenu] B42 Mode: Custom events not supported - using manual update mode")
        
        -- PHASE 3: Status updates now handled by AE_UIHealthCoordinator via defensive architecture
        -- Events.EveryTenMinutes.Add(function() -- Disabled - handled by UI Health Coordinator
        print("[AE_StatusMenu] Status updates now handled by defensive architecture")
    end
    
    return true
end

function AE_StatusMenu.handleRealTimeDataUpdate(eventData)
    if not eventData or not eventData.changedData then
        return
    end
    
    for dataKey, newValue in pairs(eventData.changedData) do
        uiUpdateQueue[dataKey] = newValue
    end
    
    if not AE_StatusMenu.updateScheduled then
        AE_StatusMenu.updateScheduled = true
        
        local timedActionSuccess, timedActionResult = pcall(function()
            if ISTimedActionQueue and ISTimedAction then
                ISTimedActionQueue.add(ISTimedAction:new(nil))
                return true
            end
            return false
        end)
        
        if not (timedActionSuccess and timedActionResult) then
            local function processUpdatesOnTick()
                AE_StatusMenu.processQueuedUpdates()
                AE_StatusMenu.updateScheduled = false
                Events.OnTick.Remove(processUpdatesOnTick)
            end
            Events.OnTick.Add(processUpdatesOnTick)
        else
            Events.OnTick.Add(function()
                AE_StatusMenu.processQueuedUpdates()
                AE_StatusMenu.updateScheduled = false
                Events.OnTick.Remove(AE_StatusMenu.processQueuedUpdates)
            end)
        end
    end
end

function AE_StatusMenu.processQueuedUpdates()
    if not statusWindow or not statusWindow:isVisible() then
        uiUpdateQueue = {}
        return
    end
    
    for dataKey, newValue in pairs(uiUpdateQueue) do
        AE_StatusMenu.updateUIElement(dataKey, newValue)
    end
    
    uiUpdateQueue = {}
end

function AE_StatusMenu.updateUIElement(dataKey, newValue)
    if dataKey == "tameness" then
        AE_StatusMenu.updateTamenessDisplay(newValue)
    elseif dataKey == "hunger" then
        AE_StatusMenu.updateHungerDisplay(newValue)
    elseif dataKey == "thirst" then
        AE_StatusMenu.updateThirstDisplay(newValue)
    elseif dataKey == "owner" then
        AE_StatusMenu.updateOwnerDisplay(newValue)
    elseif dataKey == "health" then
        AE_StatusMenu.updateHealthDisplay(newValue)
    elseif dataKey == "name" then
        AE_StatusMenu.updateNameDisplay(newValue)
    end
end

function AE_StatusMenu.unsubscribeFromDataEvents()
    local AE_EventRegistry = nil
    local success, result = pcall(function()
        return require("AnimalsEssentials/Config/AE_EventRegistry")
    end)
    if success and result then
        AE_EventRegistry = result
        print("[AE_StatusMenu] B42 Mode: Event subscriptions cleared (logging only)")
    end
    eventSubscriptions = {}
end

function AE_StatusMenu.initialize()
    AE_StatusMenu.initializeDependencies()
    
    if AE_EventRegistry and AE_EventRegistry.subscribeEvent then
        AE_EventRegistry.subscribeEvent("OnAE_UI_DataResponse", function(responseData)
            if responseData.uiComponent == "StatusMenu" then
                if responseData.responseHandler then
                    responseData.responseHandler(responseData)
                end
            end
        end)
    end
    
    if AE_EventRegistry and AE_EventRegistry.subscribeEvent then
        AE_EventRegistry.subscribeEvent("OnAE_UI_ShowAnimalStatus", function(eventData)
            if eventData.animal then
                AE_StatusMenu.showAnimalStatus(eventData.animal)
            end
        end)
        
        AE_EventRegistry.subscribeEvent("OnAE_UI_HideAnimalStatus", function()
            AE_StatusMenu.hideAnimalStatus()
        end)
    end
    
    AE_StatusMenu.createStatusWindow()
end

function AE_StatusMenu.createStatusWindow()
    if statusWindow then return end
    
    statusWindow = ISPanel:new(100, 100, 450, 350)
    statusWindow:setAnchorLeft(false)
    statusWindow:setAnchorRight(true)
    statusWindow:setAnchorTop(true)
    statusWindow:setAnchorBottom(false)
    statusWindow:addToUIManager()
    statusWindow:setVisible(false)
    statusWindow.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    statusWindow.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    
    statusWindow:addChild(ISLabel:new(10, 10, 20, "Animal Status", 1, 1, 1, 1, UIFont.Medium, true))
    
    local nameLabel = ISLabel:new(10, 40, 20, "No animal selected", 1, 1, 1, 1, UIFont.Small, true)
    nameLabel:setName("AnimalNameLabel")
    statusWindow:addChild(nameLabel)
    
    local ownerLabel = ISLabel:new(10, 65, 20, "Owner: None", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    ownerLabel:setName("OwnerLabel")
    statusWindow:addChild(ownerLabel)
    
    local tamenessLabel = ISLabel:new(10, 95, 20, "Tameness: 0%", 0.7, 1, 0.7, 1, UIFont.Small, true)
    tamenessLabel:setName("TamenessLabel")
    statusWindow:addChild(tamenessLabel)
    
    local healthLabel = ISLabel:new(10, 125, 20, "Health: 100%", 1, 0.7, 0.7, 1, UIFont.Small, true)
    healthLabel:setName("HealthLabel")
    statusWindow:addChild(healthLabel)
    
    local hungerLabel = ISLabel:new(10, 155, 20, "Hunger: 0%", 1, 0.9, 0.7, 1, UIFont.Small, true)
    hungerLabel:setName("HungerLabel")
    statusWindow:addChild(hungerLabel)
    
    local thirstLabel = ISLabel:new(10, 185, 20, "Thirst: 0%", 0.7, 0.9, 1, 1, UIFont.Small, true)
    thirstLabel:setName("ThirstLabel")
    statusWindow:addChild(thirstLabel)
    
    local errorLabel = ISLabel:new(10, 220, 20, "", 1, 0.5, 0.5, 1, UIFont.Small, true)
    errorLabel:setName("ErrorLabel")
    errorLabel:setVisible(false)
    statusWindow:addChild(errorLabel)
    
    local refreshButton = ISButton:new(10, 280, 80, 25, "Refresh", statusWindow, function()
        if selectedAnimal then
            AE_StatusMenu.updateAnimalDisplay(selectedAnimal)
        end
    end)
    statusWindow:addChild(refreshButton)
    
    local closeButton = ISButton:new(350, 280, 80, 25, "Close", statusWindow, function()
        AE_StatusMenu.hideAnimalStatus()
    end)
    statusWindow:addChild(closeButton)
end

function AE_StatusMenu.showAnimalStatus(animal)
    if not animal then
        return false
    end
    
    selectedAnimal = animal
    
    AE_StatusMenu.subscribeToDataEvents(animal)
    
    AE_StatusMenu.updateAnimalDisplay(animal)
    
    if statusWindow then
        statusWindow:setVisible(true)
    end
    
    return true
end

function AE_StatusMenu.hideAnimalStatus()
    AE_StatusMenu.unsubscribeFromDataEvents()
    
    selectedAnimal = nil
    uiUpdateQueue = {}
    
    if statusWindow then
        statusWindow:setVisible(false)
    end
    
    return true
end

function AE_StatusMenu.showAnimalStatusByStableID(stableID)
    if not stableID then return false end
    
    if not AE_EnhancedLookups then
        AE_StatusMenu.initializeDependencies()
    end
    
    if AE_EnhancedLookups then
        local animal = AE_EnhancedLookups.getTamedAnimalByStableID(stableID)
        if animal then
            return AE_StatusMenu.showAnimalStatus(animal)
        else
            AE_StatusMenu.displayErrorMessage("Animal with ID " .. stableID .. " not found or not accessible")
            return false
        end
    else
        AE_StatusMenu.displayErrorMessage("Enhanced lookup system not available")
        return false
    end
end

function AE_StatusMenu.getAllTamedAnimals()
    if not AE_EnhancedLookups then
        AE_StatusMenu.initializeDependencies()
    end
    
    local player = getPlayer()
    if not player then return {} end
    
    if AE_EnhancedLookups then
        return AE_EnhancedLookups.getAllTamedAnimalsForPlayer(player)
    else
        return {}
    end
end

function AE_StatusMenu.createAnimalSelectionList()
    local tamedAnimals = AE_StatusMenu.getAllTamedAnimals()
    local animalList = {}
    
    for _, animalData in ipairs(tamedAnimals) do
        local animal = animalData.animal
        local stableID = animalData.stableID
        local source = animalData.source
        
        if animal and stableID then
            local animalName = AE_DataService and AE_DataService.getAnimalName(animal) or "Unnamed"
            local displayName = animalName .. " (" .. stableID .. ")"
            
            if source == "persistent_mapping" then
                displayName = displayName .. " [Restored]"
            end
            
            table.insert(animalList, {
                displayName = displayName,
                stableID = stableID,
                animal = animal,
                source = source
            })
        end
    end
    
    return animalList
end

function AE_StatusMenu.updateTamenessDisplay(newValue)
    if not statusWindow then return end
    
    local success, tamenessLabel = pcall(function()
        return statusWindow:getChild("TamenessLabel")
    end)
    
    if success and tamenessLabel then
        local tamenessText = string.format("Tameness: %.1f%%", newValue or 0)
        if newValue and newValue >= 80 then
            tamenessText = tamenessText .. " (Tamed)"
        end
        local setSuccess = pcall(function()
            tamenessLabel:setText(tamenessText)
        end)
        if not setSuccess then
            print("[AE_StatusMenu] Failed to update tameness display")
        end
    end
end

function AE_StatusMenu.updateHungerDisplay(newValue)
    if not statusWindow then return end
    
    local success, hungerLabel = pcall(function()
        return statusWindow:getChild("HungerLabel")
    end)
    
    if success and hungerLabel then
        local setSuccess = pcall(function()
            hungerLabel:setText(string.format("Hunger: %.1f%%", newValue or 0))
        end)
        if not setSuccess then
            print("[AE_StatusMenu] Failed to update hunger display")
        end
    end
end

function AE_StatusMenu.updateThirstDisplay(newValue)
    if not statusWindow then return end
    
    local success, thirstLabel = pcall(function()
        return statusWindow:getChild("ThirstLabel")
    end)
    
    if success and thirstLabel then
        local setSuccess = pcall(function()
            thirstLabel:setText(string.format("Thirst: %.1f%%", newValue or 0))
        end)
        if not setSuccess then
            print("[AE_StatusMenu] Failed to update thirst display")
        end
    end
end

function AE_StatusMenu.updateHealthDisplay(newValue)
    if not statusWindow then return end
    
    local success, healthLabel = pcall(function()
        return statusWindow:getChild("HealthLabel")
    end)
    
    if success and healthLabel then
        local setSuccess = pcall(function()
            healthLabel:setText(string.format("Health: %.1f%%", newValue or 0))
        end)
        if not setSuccess then
            print("[AE_StatusMenu] Failed to update health display")
        end
    end
end

function AE_StatusMenu.updateNameDisplay(newValue)
    if not statusWindow then return end
    
    local success, nameLabel = pcall(function()
        return statusWindow:getChild("AnimalNameLabel")
    end)
    
    if success and nameLabel then
        local setSuccess = pcall(function()
            nameLabel:setText(newValue or "Unknown")
        end)
        if not setSuccess then
            print("[AE_StatusMenu] Failed to update name display")
        end
    end
end

function AE_StatusMenu.updateOwnerDisplay(newValue)
    if not statusWindow then return end
    
    local success, ownerLabel = pcall(function()
        return statusWindow:getChild("OwnerLabel")
    end)
    
    if success and ownerLabel then
        local setSuccess = pcall(function()
            ownerLabel:setText("Owner: " .. (newValue or "None"))
        end)
        if not setSuccess then
            print("[AE_StatusMenu] Failed to update owner display")
        end
    end
end

function AE_StatusMenu.displayErrorMessage(errorMessage)
    if not statusWindow then return end
    
    local success, errorLabel = pcall(function()
        return statusWindow:getChild("ErrorLabel")
    end)
    
    if success and errorLabel then
        local textSuccess = pcall(function()
            errorLabel:setText(errorMessage or "Unknown error")
            errorLabel:setVisible(true)
        end)
        
        if textSuccess then
            local hideTime = nil
            local gameTimeSuccess, gameTimeInstance = pcall(function()
                return GameTime and GameTime.getServerTimeMills and GameTime.getServerTimeMills()
            end)
            
            if gameTimeSuccess and gameTimeInstance then
                hideTime = gameTimeInstance + 5000
            else
                hideTime = 300 -- ~5 seconds at 60 FPS
            end
            
            local function hideErrorOnTick()
                local currentTime
                if gameTimeSuccess then
                    currentTime = GameTime.getServerTimeMills()
                else
                    hideTime = hideTime - 1
                    currentTime = 0
                end
                
                if (gameTimeSuccess and currentTime >= hideTime) or (not gameTimeSuccess and hideTime <= 0) then
                    local hideSuccess = pcall(function()
                        errorLabel:setVisible(false)
                    end)
                    Events.OnTick.Remove(hideErrorOnTick)
                end
            end
            
            Events.OnTick.Add(hideErrorOnTick)
        end
    end
end

function AE_StatusMenu.displayAnimalStats(animalData)
    if not statusWindow or not animalData then return end
    
    AE_StatusMenu.updateNameDisplay(animalData.name)
    AE_StatusMenu.updateOwnerDisplay(animalData.owner)
    AE_StatusMenu.updateTamenessDisplay(animalData.tameness)
    AE_StatusMenu.updateHealthDisplay(animalData.health)
    AE_StatusMenu.updateHungerDisplay(animalData.hunger)
    AE_StatusMenu.updateThirstDisplay(animalData.thirst)
end

function AE_StatusMenu.getPlayerAnimalList(player)
    if not player or not AE_DataService then 
        return {}
    end
    
    local animalList = {}
    
    sendServerCommand("AE_UIService", "dataRequest", {
        requestType = "playerAnimalList",
        playerID = player:getUsername(),
        uiComponent = "StatusMenu",
        responseHandler = function(responseData)
            if responseData.success and responseData.animalList then
                animalList = responseData.animalList
            end
        end
    })
    
    return animalList
end

function AE_StatusMenu.cleanup()
    AE_StatusMenu.unsubscribeFromDataEvents()
    selectedAnimal = nil
    uiUpdateQueue = {}
    
    if statusWindow then
        statusWindow:setVisible(false)
        statusWindow = nil
    end
end

function AE_StatusMenu.handleAnimalInstanceUpdate(stableID, newAnimal)
    if selectedAnimal and AE_DataService then
        local currentStableID = AE_DataService.getStableID(selectedAnimal)
        if currentStableID == stableID then
            selectedAnimal = newAnimal
            AE_StatusMenu.updateAnimalDisplay(newAnimal)
        end
    end
end

if Events and Events.OnTamedAnimalInstanceUpdated then
    Events.OnTamedAnimalInstanceUpdated.Add(AE_StatusMenu.handleAnimalInstanceUpdate)
end

Events.OnGameStart.Add(AE_StatusMenu.initialize)

Events.OnGameBoot.Add(AE_StatusMenu.cleanup)

return AE_StatusMenu