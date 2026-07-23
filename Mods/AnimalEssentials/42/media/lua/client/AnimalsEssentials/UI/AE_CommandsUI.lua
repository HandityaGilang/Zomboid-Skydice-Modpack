
require "ISUI/ISPanel"

local AE_CommandsUI = {}

local AE_DataService = nil
local AE_CommandsSystem = nil
local AE_EnhancedLookups = nil

  
function AE_CommandsUI.initializeDependencies()
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

AE_CommandsUI.isOpen = false
AE_CommandsUI.commandsWindow = nil
AE_CommandsUI.player = nil
AE_CommandsUI.animal = nil
AE_CommandsUI.animalID = nil
AE_CommandsUI.onBackCallback = nil

AE_CommandsUI.activeCommands = {}
AE_CommandsUI.commandProgress = {}
AE_CommandsUI.eventSubscriptions = {}
AE_CommandsUI.feedbackLabels = {}

AE_CommandsUI.isSelectingTile = false
AE_CommandsUI.tileSelectionAnimal = nil
AE_CommandsUI.selectionMode = nil
AE_CommandsUI.tileHighlightPanel = nil

function AE_CommandsUI.validateUIState()
    if not AE_DataService then
        return false, "data_service_unavailable"
    end
    
    if not AE_CommandsUI.animal then
        return false, "no_animal_selected"
    end
    
    local validationResult = false
    local validationReason = "unknown"
    
    sendServerCommand("AE_UIService", "dataRequest", {
        requestType = "animalCommand",
        animalID = AE_CommandsUI.animal:getAnimalID(),
        playerID = AE_CommandsUI.player and AE_CommandsUI.player:getUsername(),
        uiComponent = "CommandsUI",
        responseHandler = function(responseData)
            validationResult = responseData.success or false
            validationReason = responseData.reason or "validation_failed"
        end
    })
    
    return validationResult, validationReason
end

function AE_CommandsUI.subscribeToCommandEvents(animalID)
    if not animalID then return end
    
    AE_CommandsUI.unsubscribeFromCommandEvents()
    
    local AE_EventRegistry = nil
    local success, result = pcall(function()
        return require("AnimalsEssentials/Config/AE_EventRegistry")
    end)
    if success and result then
        AE_EventRegistry = result
        
        AE_CommandsUI.eventSubscriptions.commandStart = AE_EventRegistry.subscribeEvent("OnAE_CommandStarted", function(eventData)
            if eventData.animalID == animalID then
                AE_CommandsUI.handleCommandStarted(eventData)
            end
        end)
        
        AE_CommandsUI.eventSubscriptions.commandProgress = AE_EventRegistry.subscribeEvent("OnAE_CommandProgress", function(eventData)
            if eventData.animalID == animalID then
                AE_CommandsUI.handleCommandProgress(eventData)
            end
        end)
        
        AE_CommandsUI.eventSubscriptions.commandCompleted = AE_EventRegistry.subscribeEvent("OnAE_CommandCompleted", function(eventData)
            if eventData.animalID == animalID then
                AE_CommandsUI.handleCommandCompleted(eventData)
            end
        end)
        
        AE_CommandsUI.eventSubscriptions.commandFailed = AE_EventRegistry.subscribeEvent("OnAE_CommandFailed", function(eventData)
            if eventData.animalID == animalID then
                AE_CommandsUI.handleCommandFailed(eventData)
            end
        end)
    else
        print("[AE_CommandsUI] B42 Mode: Custom events not supported - command status will not auto-update")
    end
end

function AE_CommandsUI.handleCommandStarted(eventData)
    if not AE_CommandsUI.commandsWindow or not AE_CommandsUI.commandsWindow:isVisible() then
        return
    end
    
    local commandType = eventData.commandType
    AE_CommandsUI.activeCommands[commandType] = {
        startTime = getTimestamp(),
        duration = eventData.estimatedDuration or 5000,
        status = "in_progress"
    }
    
    AE_CommandsUI.updateCommandFeedback(commandType, "Started: " .. (eventData.commandName or commandType))
    AE_CommandsUI.disableCommandButton(commandType, true)
end

function AE_CommandsUI.handleCommandProgress(eventData)
    if not AE_CommandsUI.commandsWindow or not AE_CommandsUI.commandsWindow:isVisible() then
        return
    end
    
    local commandType = eventData.commandType
    local progress = eventData.progress or 0
    
    if AE_CommandsUI.activeCommands[commandType] then
        AE_CommandsUI.activeCommands[commandType].progress = progress
        AE_CommandsUI.updateCommandProgress(commandType, progress)
    end
end

function AE_CommandsUI.handleCommandCompleted(eventData)
    if not AE_CommandsUI.commandsWindow or not AE_CommandsUI.commandsWindow:isVisible() then
        return
    end
    
    local commandType = eventData.commandType
    AE_CommandsUI.activeCommands[commandType] = nil
    
    AE_CommandsUI.updateCommandFeedback(commandType, "Completed: " .. (eventData.result or "Success"))
    AE_CommandsUI.disableCommandButton(commandType, false)
    
    Events.OnTick.Add(function()
        local clearTime = getTimestamp() + 3000
        if getTimestamp() >= clearTime then
            AE_CommandsUI.clearCommandFeedback(commandType)
            Events.OnTick.Remove(AE_CommandsUI.clearFeedbackTimer)
        end
    end)
end

function AE_CommandsUI.handleCommandFailed(eventData)
    if not AE_CommandsUI.commandsWindow or not AE_CommandsUI.commandsWindow:isVisible() then
        return
    end
    
    local commandType = eventData.commandType
    AE_CommandsUI.activeCommands[commandType] = nil
    
    AE_CommandsUI.updateCommandFeedback(commandType, "Failed: " .. (eventData.error or "Unknown error"))
    AE_CommandsUI.disableCommandButton(commandType, false)
    
    Events.OnTick.Add(function()
        local clearTime = getTimestamp() + 5000
        if getTimestamp() >= clearTime then
            AE_CommandsUI.clearCommandFeedback(commandType)
            Events.OnTick.Remove(AE_CommandsUI.clearErrorFeedbackTimer)
        end
    end)
end

function AE_CommandsUI.unsubscribeFromCommandEvents()
    local AE_EventRegistry = nil
    local success, result = pcall(function()
        return require("AnimalsEssentials/Config/AE_EventRegistry")
    end)
    if success and result then
        AE_EventRegistry = result
        print("[AE_CommandsUI] B42 Mode: Event subscriptions cleared (logging only)")
    end
    AE_CommandsUI.eventSubscriptions = {}
end

function AE_CommandsUI.screenToWorld(screenX, screenY, worldZ, playerNum)
    local pNum = playerNum or 0
    local zLevel = worldZ or 0
    
    local success1, worldX, worldY = pcall(function()
        return screenToIsoX(pNum, screenX, screenY, zLevel), 
               screenToIsoY(pNum, screenX, screenY, zLevel)
    end)
    
    if success1 and worldX and worldY and type(worldX) == "number" and type(worldY) == "number" then
        return worldX, worldY
    end
    
    local success2, altX, altY = pcall(function()
        local player = getSpecificPlayer(pNum)
        if not player then error("No player") end
        
        local px, py = player:getX(), player:getY()
        local relativeX = screenX - (getCore():getScreenWidth() / 2)
        local relativeY = screenY - (getCore():getScreenHeight() / 2)
        
        local isoX = px + (relativeX * 0.025) + (relativeY * 0.025) 
        local isoY = py + (relativeY * 0.025) - (relativeX * 0.025)
        
        return isoX, isoY
    end)
    
    if success2 and altX and altY and type(altX) == "number" and type(altY) == "number" then
        return altX, altY
    end
    
    local success3, fallbackX, fallbackY = pcall(function()
        return ISCoordConversion.ToWorld(screenX, screenY, zLevel)
    end)
    
    if success3 and fallbackX and fallbackY and type(fallbackX) == "number" and type(fallbackY) == "number" then
        return fallbackX, fallbackY
    end
    
    local player = getSpecificPlayer(pNum)
    if player then
        return player:getX(), player:getY()
    end
    
    return 0, 0
end

ISTileHighlight = ISPanel:derive("ISTileHighlight")

function ISTileHighlight:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.moveWithMouse = false
    o.consumeMouseEvents = false
    o:setWantKeyEvents(false)
    return o
end

function ISTileHighlight:onMouseDown(x, y)
    return false
end

function ISTileHighlight:onMouseUp(x, y)
    return false
end

function ISTileHighlight:onRightMouseDown(x, y)
    return false
end

function ISTileHighlight:onRightMouseUp(x, y)
    return false
end

function ISTileHighlight:render()
    ISPanel.render(self)
    if not AE_CommandsUI.cachedHoverTile then
        return
    end
    local tile = AE_CommandsUI.cachedHoverTile
    local tileX = tile.x
    local tileY = tile.y  
    local tileZ = tile.z
    local player = getPlayer()
    if not player then return end
    local playerNum = player:getPlayerNum()
    local angularStep = 0.1163552834662886
    local northingOffsetCorrection = 1.0471975511965977
    local centerX = tileX + 0.5
    local centerY = tileY + 0.5
    local radius = 0.5
    for angularIter = 0, 6.283185307179586, angularStep do
        local worldX1 = centerX + radius * math.cos(angularIter - northingOffsetCorrection)
        local worldY1 = centerY + radius * math.sin(angularIter - northingOffsetCorrection)
        local worldX2 = centerX + radius * math.cos(angularIter - northingOffsetCorrection + angularStep)  
        local worldY2 = centerY + radius * math.sin(angularIter - northingOffsetCorrection + angularStep)
        local screenX1 = isoToScreenX(playerNum, worldX1, worldY1, tileZ)
        local screenY1 = isoToScreenY(playerNum, worldX1, worldY1, tileZ)  
        local screenX2 = isoToScreenX(playerNum, worldX2, worldY2, tileZ)
        local screenY2 = isoToScreenY(playerNum, worldX2, worldY2, tileZ)
        local lineAlpha, lineRed, lineGreen, lineBlue
        if AE_CommandsUI.selectionMode == "doghouse_placement" then
            lineAlpha, lineRed, lineGreen, lineBlue = 0.8, 0.6, 0.2, 1.0
        else
            lineAlpha, lineRed, lineGreen, lineBlue = 0.8, 0.2, 1.0, 0.2
        end
        local dx = screenX2 - screenX1
        local dy = screenY2 - screenY1
        local length = math.sqrt(dx * dx + dy * dy)
        if length > 0.5 then
            local steps = math.max(1, math.floor(length / 2))
            for step = 0, steps do
                local t = step / steps
                local x = screenX1 + (dx * t)
                local y = screenY1 + (dy * t)
                self:drawRect(x - 1, y - 1, 2, 2, lineAlpha, lineRed, lineGreen, lineBlue)
            end
        end
    end
end

function AE_CommandsUI.open(player, animal, animalID, animalSlot, onBackCallback)
    if not TamingSystem then
        if player and player.Say then
            player:Say("Error: Animal system not loaded")
        end
        return
    end
    if not CommandsSystem then
        if player and player.Say then
            player:Say("Error: Commands system not loaded")
        end
        return
    end
    
    if AE_CommandsUI.isOpen then
        AE_CommandsUI.close()
    end
    
    AE_CommandsUI.player = player
    AE_CommandsUI.animal = animal
    AE_CommandsUI.animalID = animalID
    AE_CommandsUI.animalSlot = animalSlot
    AE_CommandsUI.onBackCallback = onBackCallback
    
    local isValid, reason = AE_CommandsUI.validateUIState()
    if not isValid then
        if player and player.Say then
            if reason == "not_tamed" then
                player:Say("Animal must be tamed to receive commands")
            elseif reason == "invalid_animal" then
                player:Say("Invalid animal selected")
            elseif reason == "no_stable_id" then
                player:Say("Animal not properly registered")
            else
                player:Say("Cannot open commands for this animal")
            end
        end
        return
    end
    
    local windowWidth = 400
    local windowHeight = 350
    local core = getCore()
    local x = (core:getScreenWidth() - windowWidth) / 2
    local y = (core:getScreenHeight() - windowHeight) / 2
    AE_CommandsUI.commandsWindow = ISPanel:new(x, y, windowWidth, windowHeight)
    AE_CommandsUI.commandsWindow:initialise()
    AE_CommandsUI.commandsWindow:instantiate()
    AE_CommandsUI.commandsWindow.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    AE_CommandsUI.commandsWindow.backgroundColor = {r=0, g=0, b=0, a=0.8}
    AE_CommandsUI.commandsWindow.moveWithMouse = true
    
    local animalName = TamingSystem.GetName(animal) or "Animal"
    local titleText = "Commands: " .. animalName
    local textManager = getTextManager()
    local titleWidth = textManager:MeasureStringX(UIFont.Medium, titleText)
    local titleX = (windowWidth - titleWidth) / 2
    local titleLabel = ISLabel:new(titleX, 10, 20, titleText, 1, 1, 1, 1, UIFont.Medium, true)
    titleLabel:initialise()
    titleLabel:instantiate()
    AE_CommandsUI.commandsWindow:addChild(titleLabel)
    
    local closeButton = ISButton:new(windowWidth - 25, 5, 20, 20, "X", nil, AE_CommandsUI.close)
    closeButton:initialise()
    closeButton:instantiate()
    closeButton.borderColor = {r=1, g=1, b=1, a=0.3}
    AE_CommandsUI.commandsWindow:addChild(closeButton)
    
    local backButton = ISButton:new(10, 5, 60, 20, "< Back", nil, AE_CommandsUI.onBack)
    backButton:initialise()
    backButton:instantiate()
    backButton.borderColor = {r=1, g=1, b=1, a=0.3}
    AE_CommandsUI.commandsWindow:addChild(backButton)
    
    local buttonWidth = 324
    local buttonHeight = 45
    local buttonSpacing = 10
    local startY = 50
    
    local followButton = ISButton:new(20, startY, buttonWidth, buttonHeight, "Follow", nil, function()
        AE_CommandsUI.onFollowCommand()
    end)
    followButton:initialise()
    followButton:instantiate()
    followButton.borderColor = {r=1, g=0.6, b=0.2, a=1}
    followButton.backgroundColor = {r=0.5, g=0.3, b=0.1, a=0.8}
    followButton.font = UIFont.Large
    AE_CommandsUI.commandsWindow:addChild(followButton)
    
    local stayButton = ISButton:new(20, startY + buttonHeight + buttonSpacing, buttonWidth, buttonHeight, "Stay", nil, function()
        AE_CommandsUI.onStayCommand()
    end)
    stayButton:initialise()
    stayButton:instantiate()
    stayButton.borderColor = {r=0.2, g=0.6, b=1, a=1}
    stayButton.backgroundColor = {r=0.1, g=0.3, b=0.5, a=0.8}
    stayButton.font = UIFont.Large
    AE_CommandsUI.commandsWindow:addChild(stayButton)
    
    local gotoButtonY = startY + (buttonHeight + buttonSpacing) * 2
    local cooldown = CommandsSystem.getGoToCooldown(animalID)
    local gotoText = "Go-To"
    if cooldown > 0 then
        gotoText = "Go-To (Cooldown: " .. math.ceil(cooldown) .. "s)"
    end

    local gotoButton = ISButton:new(20, gotoButtonY, buttonWidth, buttonHeight, gotoText, nil, function()
        AE_CommandsUI.onGoToCommand()
    end)
    gotoButton:initialise()
    gotoButton:instantiate()
    gotoButton.borderColor = {r=0.2, g=1, b=0.2, a=1}
    gotoButton.backgroundColor = {r=0.1, g=0.4, b=0.1, a=0.8}
    gotoButton.font = UIFont.Large
    if cooldown > 0 then
        gotoButton:setEnable(false)
    end
    AE_CommandsUI.commandsWindow:addChild(gotoButton)
    
    local forageButtonY = startY + (buttonHeight + buttonSpacing) * 3
    local forageText = "Forage/Hunt"
    local forageEnabled = true
    local forageBorderColor = {r=0.8, g=0.4, b=0.1, a=1}
    local forageBackgroundColor = {r=0.4, g=0.2, b=0.05, a=0.8}
    local forageCooldown = CommandsSystem.getForagingCooldown(animalID)
    if forageCooldown > 0 then
        forageText = "Forage/Hunt (Cooldown: " .. math.ceil(forageCooldown) .. "h)"
        forageEnabled = false
        forageBorderColor = {r=0.6, g=0.6, b=0.6, a=1}
        forageBackgroundColor = {r=0.3, g=0.3, b=0.3, a=0.8}
    elseif CommandsSystem.isForaging(animalID) then
        local forageState = CommandsSystem.getForagingState(animalID)
        if forageState == "wandering" then
            forageText = "Foraging (Wandering)"
        elseif forageState == "hunting_prey" then
            forageText = "Foraging (Hunting)"
        elseif forageState == "returning_home" then
            forageText = "Foraging (Returning)"
        elseif forageState == "awaiting_player" then
            forageText = "Foraging (Complete!)"
        else
            forageText = "Foraging (Active)"
        end
        forageEnabled = false
        forageBorderColor = {r=0.6, g=0.6, b=0.6, a=1}
        forageBackgroundColor = {r=0.3, g=0.3, b=0.3, a=0.8}
    end
    local forageButton = ISButton:new(20, forageButtonY, buttonWidth, buttonHeight, forageText, nil, function()
        AE_CommandsUI.onForageCommand()
    end)
    forageButton:initialise()
    forageButton:instantiate()
    forageButton.borderColor = forageBorderColor
    forageButton.backgroundColor = forageBackgroundColor
    forageButton.font = UIFont.Large
    forageButton:setEnable(forageEnabled)
    AE_CommandsUI.commandsWindow:addChild(forageButton)
    
    local homeButton = ISButton:new(20, startY + (buttonHeight + buttonSpacing) * 4, buttonWidth, buttonHeight, "Home", nil, function()
        AE_CommandsUI.onHomeCommand()
    end)
    homeButton:initialise()
    homeButton:instantiate()
    homeButton.borderColor = {r=0.6, g=0.2, b=1, a=1}     -- Purple border
    homeButton.backgroundColor = {r=0.3, g=0.1, b=0.5, a=0.8}  -- Purple background
    homeButton.font = UIFont.Large
    AE_CommandsUI.commandsWindow:addChild(homeButton)
    
    AE_CommandsUI.commandsWindow.onMouseDownOutside = function(self, x, y)
        local mouseX = self:getMouseX()
        local mouseY = self:getMouseY()
        if mouseX < 0 or mouseX > self.width or mouseY < 0 or mouseY > self.height then
            AE_CommandsUI.close()
            return true
        end
        return false
    end
    AE_CommandsUI.commandsWindow.onRightMouseDownOutside = function(self, x, y)
        AE_CommandsUI.close()
        return true
    end
    AE_CommandsUI.commandsWindow:addToUIManager()
    AE_CommandsUI.commandsWindow:setVisible(true)
    AE_CommandsUI.isOpen = true
end

function AE_CommandsUI.close()
    if AE_CommandsUI.commandsWindow then
        AE_CommandsUI.commandsWindow:setVisible(false)
        AE_CommandsUI.commandsWindow:removeFromUIManager()
        AE_CommandsUI.commandsWindow = nil
    end
    AE_CommandsUI.isOpen = false
    AE_CommandsUI.player = nil
    AE_CommandsUI.animal = nil
    AE_CommandsUI.animalID = nil
    AE_CommandsUI.animalSlot = nil
    AE_CommandsUI.onBackCallback = nil
end

function AE_CommandsUI.onBack()
    AE_CommandsUI.close()
    if AE_CommandsUI.onBackCallback then
        AE_CommandsUI.onBackCallback()
    end
end

function AE_CommandsUI.onFollowCommand()
    if not AE_CommandsUI.animal or not AE_CommandsUI.animalID then return end
    
    local isValid, reason = AE_CommandsUI.validateUIState()
    if not isValid then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say("Cannot execute command: " .. (reason or "unknown error"))
        end
        AE_CommandsUI.close()
        return
    end
    
    local usedPspspsps, failureMessage = CommandsSystem.startFollow(AE_CommandsUI.animal, AE_CommandsUI.animalID, AE_CommandsUI.player)
    if failureMessage then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say(failureMessage)
        end
    elseif usedPspspsps ~= false then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            if usedPspspsps then
                AE_CommandsUI.player:Say("Pspspsps!")
            else
                local animalName = TamingSystem.GetName(AE_CommandsUI.animal) or "Animal"
                AE_CommandsUI.player:Say("Follow me, " .. animalName .. "!")
            end
        end
    end
    AE_CommandsUI.close()
end

function AE_CommandsUI.onStayCommand()
    if not AE_CommandsUI.animal or not AE_CommandsUI.animalID then return end
    
    local isValid, reason = AE_CommandsUI.validateUIState()
    if not isValid then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say("Cannot execute command: " .. (reason or "unknown error"))
        end
        AE_CommandsUI.close()
        return
    end
    
    local success, failureMessage = CommandsSystem.startStay(AE_CommandsUI.animal, AE_CommandsUI.animalID, AE_CommandsUI.player)
    if failureMessage then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say(failureMessage)
        end
    elseif success then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            local animalName = TamingSystem.GetName(AE_CommandsUI.animal) or "Animal"
            AE_CommandsUI.player:Say("Stay, " .. animalName .. "!")
        end
    end
    AE_CommandsUI.close()
end

function AE_CommandsUI.onGoToCommand()
    if not AE_CommandsUI.animal or not AE_CommandsUI.animalID then
        return
    end
    
    local isValid, reason = AE_CommandsUI.validateUIState()
    if not isValid then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say("Cannot execute command: " .. (reason or "unknown error"))
        end
        return
    end
    
    local cooldown = CommandsSystem.getGoToCooldown(AE_CommandsUI.animalID)
    if cooldown > 0 then
        return
    end
    local animalID = AE_CommandsUI.animalID
    local animal = AE_CommandsUI.animal
    AE_CommandsUI.tileSelectionAnimal = animal
    AE_CommandsUI.tileSelectionAnimalID = animalID
    AE_CommandsUI.isSelectingTile = true
    AE_CommandsUI.selectionMode = "goto"
    if not AE_CommandsUI.tileHighlightPanel then
        local screenWidth = getCore():getScreenWidth()
        local screenHeight = getCore():getScreenHeight()
        AE_CommandsUI.tileHighlightPanel = ISTileHighlight:new(0, 0, screenWidth, screenHeight)
        AE_CommandsUI.tileHighlightPanel:initialise()
        AE_CommandsUI.tileHighlightPanel:instantiate()
        AE_CommandsUI.tileHighlightPanel:addToUIManager()
        AE_CommandsUI.tileHighlightPanel:setAlwaysOnTop(true)
    end
    AE_CommandsUI.close()
end

function AE_CommandsUI.onForageCommand()
    if not AE_CommandsUI.animal or not AE_CommandsUI.animalID then return end
    
    local isValid, reason = AE_CommandsUI.validateUIState()
    if not isValid then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say("Cannot execute command: " .. (reason or "unknown error"))
        end
        AE_CommandsUI.close()
        return
    end
    
    local success, failureMessage = CommandsSystem.startForage(AE_CommandsUI.animal, AE_CommandsUI.animalID, AE_CommandsUI.player)
    if failureMessage then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say(failureMessage)
        end
    elseif success then
        if AE_CommandsUI.player and AE_CommandsUI.player.Say then
            local animalName = TamingSystem.GetName(AE_CommandsUI.animal) or "Animal"
            AE_CommandsUI.player:Say(animalName .. " is going foraging!")
        end
    end

    AE_CommandsUI.close()
end

function AE_CommandsUI.startDoghousePlacement(animal, animalID, playerRef)
    if not animal or not animalID then
        return
    end
    
    -- CONVERTED: Validate doghouse placement eligibility
    local dataServiceSuccess, dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil and AE_DataService.isAnimalValid ~= nil
    end)
    
    if dataServiceSuccess and dataServiceAvailable then
        local validSuccess, validResult = pcall(function()
            return AE_DataService.isAnimalValid(animal)
        end)
        if not (validSuccess and validResult) then
            if playerRef and playerRef.Say then
                playerRef:Say("Invalid animal for doghouse placement")
            end
            return
        end
        
        local tameSuccess, tameResult = pcall(function()
            return AE_DataService.isTamed(animal)
        end)
        if not (tameSuccess and tameResult) then
            if playerRef and playerRef.Say then
                playerRef:Say("Only tamed animals can have doghouses")
            end
            return
        end
    end
    
    AE_CommandsUI.tileSelectionAnimal = animal
    AE_CommandsUI.tileSelectionAnimalID = animalID
    AE_CommandsUI.player = playerRef
    AE_CommandsUI.isSelectingTile = true
    AE_CommandsUI.selectionMode = "doghouse_placement"
    if not AE_CommandsUI.tileHighlightPanel then
        local screenWidth = getCore():getScreenWidth()
        local screenHeight = getCore():getScreenHeight()
        AE_CommandsUI.tileHighlightPanel = ISTileHighlight:new(0, 0, screenWidth, screenHeight)
        AE_CommandsUI.tileHighlightPanel:initialise()
        AE_CommandsUI.tileHighlightPanel:instantiate()
        AE_CommandsUI.tileHighlightPanel:addToUIManager()
        AE_CommandsUI.tileHighlightPanel:setAlwaysOnTop(true)
    end
    if playerRef and playerRef.Say then
        playerRef:Say("Click where you want to place the doghouse")
    end
end

function AE_CommandsUI.cancelTileSelection()
    AE_CommandsUI.isSelectingTile = false
    AE_CommandsUI.tileSelectionAnimal = nil
    AE_CommandsUI.tileSelectionAnimalID = nil
    AE_CommandsUI.selectionMode = nil
    if AE_CommandsUI.tileHighlightPanel then
        AE_CommandsUI.tileHighlightPanel:setVisible(false)
        AE_CommandsUI.tileHighlightPanel:removeFromUIManager()
        AE_CommandsUI.tileHighlightPanel = nil
    end
    AE_CommandsUI.cachedHoverTile = nil
    AE_CommandsUI.pendingHoverTile = nil
    AE_CommandsUI.hoverTickCounter = 0
end

function AE_CommandsUI.updateHoveredTile()
    if not AE_CommandsUI.isSelectingTile then
        AE_CommandsUI.cachedHoverTile = nil
        AE_CommandsUI.pendingHoverTile = nil
        AE_CommandsUI.hoverTickCounter = 0
        return
    end
    local player = getPlayer()
    if not player then
        AE_CommandsUI.cachedHoverTile = nil
        AE_CommandsUI.pendingHoverTile = nil
        AE_CommandsUI.hoverTickCounter = 0
        return
    end
    local mouseX = getMouseX()
    local mouseY = getMouseY()
    
    -- Proper screen-to-world coordinate conversion accounting for zoom and camera
    local playerNum = player:getPlayerNum()
    local worldX, worldY = AE_CommandsUI.screenToWorld(mouseX, mouseY, player:getZ(), playerNum)
    
    local worldZ = player:getZ()
    local tileX = round(worldX)
    local tileY = round(worldY)
    local tileZ = worldZ
    local cell = player:getCell()
    local square = cell:getGridSquare(tileX, tileY, tileZ)
    if not square then
        AE_CommandsUI.pendingHoverTile = nil
        AE_CommandsUI.hoverTickCounter = 0
        return
    end
    local playerSquare = player:getSquare()
    if not playerSquare then
        AE_CommandsUI.pendingHoverTile = nil
        AE_CommandsUI.hoverTickCounter = 0
        return
    end
    local playerX = playerSquare:getX()
    local playerY = playerSquare:getY()
    local dx = tileX - playerX
    local dy = tileY - playerY
    local distance = math.sqrt(dx * dx + dy * dy)
    if AE_CommandsUI.pendingHoverTile and
       AE_CommandsUI.pendingHoverTile.x == tileX and
       AE_CommandsUI.pendingHoverTile.y == tileY and
       AE_CommandsUI.pendingHoverTile.z == tileZ then
        AE_CommandsUI.hoverTickCounter = AE_CommandsUI.hoverTickCounter + 1
        if AE_CommandsUI.hoverTickCounter >= AE_CommandsUI.HOVER_DELAY_TICKS then
            local playerNum = player:getPlayerNum()
            local worldX = tileX + 0.5
            local worldY = tileY + 0.5
            AE_CommandsUI.cachedHoverTile = {
                x = tileX,
                y = tileY,
                z = tileZ,
                distance = distance,
                square = square
            }
        end
    else
        AE_CommandsUI.pendingHoverTile = {
            x = tileX,
            y = tileY,
            z = tileZ,
            distance = distance,
            square = square
        }
        AE_CommandsUI.hoverTickCounter = 0
    end
end

function AE_CommandsUI.drawTileSelectionFeedback()
    if not AE_CommandsUI.isSelectingTile then
        return
    end
    local modeText = "Go-To Mode"
    if AE_CommandsUI.selectionMode == "doghouse_placement" then
        modeText = "Doghouse Placement"
    end
    if AE_CommandsUI.cachedHoverTile then
        local tile = AE_CommandsUI.cachedHoverTile
        local textMgr = getTextManager()
        local x = 10
        local y = 100
        if AE_CommandsUI.selectionMode == "doghouse_placement" then
            textMgr:DrawString(UIFont.Small, x, y, modeText, 0.6, 0.2, 1.0, 1.0)  -- Purple for doghouse
        else
            textMgr:DrawString(UIFont.Small, x, y, modeText, 0.2, 1.0, 0.2, 1.0)  -- Green for goto
        end
        textMgr:DrawString(UIFont.Small, x, y + 15, "Target: (" .. tile.x .. ", " .. tile.y .. ")", 1, 1, 1, 1)
        textMgr:DrawString(UIFont.Small, x, y + 30, "Distance: " .. string.format("%.1f", tile.distance) .. " tiles", 1, 1, 1, 1)
        textMgr:DrawString(UIFont.Small, x, y + 45, "Left-Click: Select | Right-Click: Cancel", 0.7, 0.7, 0.7, 1)
    else
        local textMgr = getTextManager()
        if AE_CommandsUI.selectionMode == "doghouse_placement" then
            textMgr:DrawString(UIFont.Small, 10, 100, modeText .. " (hover over world)", 0.6, 0.2, 1.0, 1.0)
        else
            textMgr:DrawString(UIFont.Small, 10, 100, modeText .. " (hover over world)", 0.2, 1.0, 0.2, 1.0)
        end
        textMgr:DrawString(UIFont.Small, 10, 115, "Right-Click: Cancel", 0.7, 0.7, 0.7, 1)
    end
end

function AE_CommandsUI.onMouseDown(x, y)
    if not AE_CommandsUI.isSelectingTile then
        return false
    end
    local player = getPlayer()
    if not player then
        return false
    end
    local clickX = x
    local clickY = y
    if type(clickX) ~= "number" then
        clickX = getMouseX()
    end
    if type(clickY) ~= "number" then
        clickY = getMouseY()
    end
    local worldX, worldY = ISCoordConversion.ToWorld(clickX, clickY, 0)
    local worldZ = player:getZ()
    local tileX = round(worldX)
    local tileY = round(worldY)
    local tileZ = worldZ
    local cell = player:getCell()
    local square = cell:getGridSquare(tileX, tileY, tileZ)
    if not square then
        return false
    end
    local playerSquare = player:getSquare()
    if not playerSquare then
        return false
    end
    local playerX = playerSquare:getX()
    local playerY = playerSquare:getY()
    local dx = tileX - playerX
    local dy = tileY - playerY
    local distance = math.sqrt(dx * dx + dy * dy)
    if not AE_CommandsUI.tileSelectionAnimal or not AE_CommandsUI.tileSelectionAnimalID then
        AE_CommandsUI.cancelTileSelection()
        return false
    end
    if AE_CommandsUI.selectionMode == "doghouse_placement" then
        local HomeLocation = require("AnimalsEssentials/BehaviorSystems/Core/AE_HomeLocation")
        local animalName = TamingSystem.GetName(AE_CommandsUI.tileSelectionAnimal) or "Animal"
        local success, errorMsg = HomeLocation.PlaceDoghouse(
            tileX, tileY, tileZ,
            AE_CommandsUI.tileSelectionAnimalID,
            animalName,
            AE_CommandsUI.tileSelectionAnimal
        )
        if success then
            if player and player.Say then
                player:Say("Home set for " .. animalName .. "!")
            end
        else
            if player and player.Say then
                player:Say(errorMsg or "Cannot place doghouse here")
            end
        end
    elseif AE_CommandsUI.selectionMode == "goto" then
        local success, failureMessage = CommandsSystem.startGoTo(AE_CommandsUI.tileSelectionAnimal, AE_CommandsUI.tileSelectionAnimalID, tileX, tileY, tileZ, player)
        if failureMessage then
            if player and player.Say then
                player:Say(failureMessage)
            end
        elseif success then
            if player and player.Say then
                local animalName = TamingSystem.GetName(AE_CommandsUI.tileSelectionAnimal) or "Animal"
                player:Say("Go there, " .. animalName .. "!")
            end
        end
    end
    AE_CommandsUI.cancelTileSelection()
    return true
end

function AE_CommandsUI.onRightMouseDown(x, y)
    if not AE_CommandsUI.isSelectingTile then return false end
    AE_CommandsUI.cancelTileSelection()
    local player = getPlayer()
    if player and player.Say then
        player:Say("Cancelled")
    end
    return true
end

function AE_CommandsUI.onHomeCommand()
    AE_CommandsUI.openHomeSubmenu()
end

AE_CommandsUI.homeSubmenuWindow = nil

function AE_CommandsUI.openHomeSubmenu()
    if AE_CommandsUI.homeSubmenuWindow then
        AE_CommandsUI.closeHomeSubmenu()
    end
    local windowWidth = 280
    local windowHeight = 200
    local x = (getCore():getScreenWidth() - windowWidth) / 2
    local y = (getCore():getScreenHeight() - windowHeight) / 2
    AE_CommandsUI.homeSubmenuWindow = ISPanel:new(x, y, windowWidth, windowHeight)
    AE_CommandsUI.homeSubmenuWindow:initialise()
    AE_CommandsUI.homeSubmenuWindow:instantiate()
    AE_CommandsUI.homeSubmenuWindow.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    AE_CommandsUI.homeSubmenuWindow.borderColor = {r=0.6, g=0.2, b=1, a=1}  -- Purple border
    local animalName = TamingSystem.GetName(AE_CommandsUI.animal) or "Animal"
    local titleText = "Home: " .. animalName
    local textManager = getTextManager()
    local titleWidth = textManager:MeasureStringX(UIFont.Medium, titleText)
    local titleX = (windowWidth - titleWidth) / 2
    local titleLabel = ISLabel:new(titleX, 10, 20, titleText, 1, 1, 1, 1, UIFont.Medium, true)
    titleLabel:initialise()
    titleLabel:instantiate()
    AE_CommandsUI.homeSubmenuWindow:addChild(titleLabel)

    local closeButton = ISButton:new(windowWidth - 25, 5, 20, 20, "X", nil, AE_CommandsUI.closeHomeSubmenu)
    closeButton:initialise()
    closeButton:instantiate()
    closeButton.borderColor = {r=1, g=1, b=1, a=0.3}
    AE_CommandsUI.homeSubmenuWindow:addChild(closeButton)
    local buttonWidth = 240
    local buttonHeight = 40
    local buttonSpacing = 10
    local startY = 50
    local returnHomeButton = ISButton:new(20, startY, buttonWidth, buttonHeight, "Return Home", nil, function()
        AE_CommandsUI.onReturnHomeCommand()
    end)
    returnHomeButton:initialise()
    returnHomeButton:instantiate()
    returnHomeButton.borderColor = {r=0.2, g=1, b=0.2, a=1}
    returnHomeButton.backgroundColor = {r=0.1, g=0.4, b=0.1, a=0.8}
    returnHomeButton.font = UIFont.Large
    AE_CommandsUI.homeSubmenuWindow:addChild(returnHomeButton)
    local restoreHomeButton = ISButton:new(20, startY + buttonHeight + buttonSpacing, buttonWidth, buttonHeight, "Restore Home", nil, function()
        AE_CommandsUI.onRestoreHomeCommand()
    end)
    restoreHomeButton:initialise()
    restoreHomeButton:instantiate()
    restoreHomeButton.borderColor = {r=1, g=0.5, b=0.2, a=1}
    restoreHomeButton.backgroundColor = {r=0.5, g=0.2, b=0.1, a=0.8}
    restoreHomeButton.font = UIFont.Large
    AE_CommandsUI.homeSubmenuWindow:addChild(restoreHomeButton)
    AE_CommandsUI.homeSubmenuWindow.onMouseDownOutside = function(self, x, y)
        local mouseX = self:getMouseX()
        local mouseY = self:getMouseY()
        if mouseX < 0 or mouseX > self.width or mouseY < 0 or mouseY > self.height then
            AE_CommandsUI.closeHomeSubmenu()
            return true
        end
        return false
    end
    AE_CommandsUI.homeSubmenuWindow.onRightMouseDownOutside = function(self, x, y)
        AE_CommandsUI.closeHomeSubmenu()
        return true
    end
    AE_CommandsUI.homeSubmenuWindow:addToUIManager()
    AE_CommandsUI.homeSubmenuWindow:setVisible(true)
end

function AE_CommandsUI.closeHomeSubmenu()
    if AE_CommandsUI.homeSubmenuWindow then
        AE_CommandsUI.homeSubmenuWindow:setVisible(false)
        AE_CommandsUI.homeSubmenuWindow:removeFromUIManager()
        AE_CommandsUI.homeSubmenuWindow = nil
    end
end

function AE_CommandsUI.onReturnHomeCommand()
    if not AE_CommandsUI.animal or not AE_CommandsUI.player then return end
    local HomeLocation = require("AnimalsEssentials/BehaviorSystems/Core/AE_HomeLocation")
    if not HomeLocation.HasHome(AE_CommandsUI.animal) then
        if AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say("No home location set!")
        end
        AE_CommandsUI.closeHomeSubmenu()
        return
    end
    local success = HomeLocation.StartReturnHome(AE_CommandsUI.animal, true)
    if success then
        local animalName = TamingSystem.GetName(AE_CommandsUI.animal) or "Animal"
        if AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say(animalName .. " will return home soon")
        end
    else
        if AE_CommandsUI.player.Say then
            AE_CommandsUI.player:Say("Can't return home right now")
        end
    end
    AE_CommandsUI.closeHomeSubmenu()
    AE_CommandsUI.close()
end

function AE_CommandsUI.onRestoreHomeCommand()
    if not AE_CommandsUI.animal or not AE_CommandsUI.player or not AE_CommandsUI.animalID then return end
    local HomeLocation = require("AnimalsEssentials/BehaviorSystems/Core/AE_HomeLocation")
    local hasHome = HomeLocation.HasHome(AE_CommandsUI.animal)
    local onCooldown, remainingMinutes = HomeLocation.IsRestoreHomeOnCooldown(AE_CommandsUI.animalID)
    if onCooldown then
        if AE_CommandsUI.player.Say then
            local remainingHours = math.ceil(remainingMinutes / 60)
            AE_CommandsUI.player:Say("Cooldown: " .. remainingHours .. "h remaining")
        end
        AE_CommandsUI.closeHomeSubmenu()
        return
    end
    if hasHome then
        local success, errorMsg = HomeLocation.RestoreHome(AE_CommandsUI.animalID)
        if success then
            if AE_CommandsUI.player.Say then
                AE_CommandsUI.player:Say("Home removed! You can place a new doghouse now.")
            end
        else
            if AE_CommandsUI.player.Say then
                AE_CommandsUI.player:Say(errorMsg or "Can't remove home")
            end
        end
        AE_CommandsUI.closeHomeSubmenu()
    else
        local player = AE_CommandsUI.player
        local animal = AE_CommandsUI.animal
        local animalID = AE_CommandsUI.animalID
        AE_CommandsUI.closeHomeSubmenu()
        AE_CommandsUI.close()
        AE_CommandsUI.startDoghousePlacement(animal, animalID, player)
    end
end

-- UI Feedback Methods for Real-Time Command Response
function AE_CommandsUI.updateCommandFeedback(commandType, feedbackText)
    if not AE_CommandsUI.commandsWindow then return end
    
    local feedbackLabel = AE_CommandsUI.feedbackLabels[commandType]
    if feedbackLabel then
        feedbackLabel:setText(feedbackText or "")
        feedbackLabel:setVisible(true)
    end
end

function AE_CommandsUI.updateCommandProgress(commandType, progress)
    if not AE_CommandsUI.commandsWindow then return end
    
    local progressBar = AE_CommandsUI.commandsWindow:getChild(commandType .. "_ProgressBar")
    if progressBar then
        progressBar:setProgress(progress / 100) -- Convert percentage to 0-1 range
        progressBar:setVisible(true)
    end
end

function AE_CommandsUI.disableCommandButton(commandType, disabled)
    if not AE_CommandsUI.commandsWindow then return end
    
    local commandButton = AE_CommandsUI.commandsWindow:getChild(commandType .. "_Button")
    if commandButton then
        commandButton:setEnable(not disabled)
        if disabled then
            commandButton:setBackgroundColor(0.3, 0.3, 0.3, 0.8)
        else
            commandButton:setBackgroundColor(0.4, 0.4, 0.4, 0.8)
        end
    end
end

function AE_CommandsUI.clearCommandFeedback(commandType)
    if not AE_CommandsUI.commandsWindow then return end
    
    local feedbackLabel = AE_CommandsUI.feedbackLabels[commandType]
    if feedbackLabel then
        feedbackLabel:setText("")
        feedbackLabel:setVisible(false)
    end
    
    local progressBar = AE_CommandsUI.commandsWindow:getChild(commandType .. "_ProgressBar")
    if progressBar then
        progressBar:setVisible(false)
    end
end

-- Enhanced open function with event-driven command feedback
function AE_CommandsUI.openWithRealTimeFeedback(player, animal, animalID, onBackCallback)
    if not AE_CommandsSystem then
        if player and player.Say then
            player:Say("Error: Commands system not loaded")
        end
        return
    end
    
    if AE_CommandsUI.isOpen then
        AE_CommandsUI.close()
    end
    
    AE_CommandsUI.player = player
    AE_CommandsUI.animal = animal
    AE_CommandsUI.animalID = animalID
    AE_CommandsUI.onBackCallback = onBackCallback
    
    -- Event-driven validation
    local isValid, reason = AE_CommandsUI.validateUIState()
    if not isValid then
        if player and player.Say then
            if reason == "data_service_unavailable" then
                player:Say("Framework data service unavailable")
            elseif reason == "no_animal_selected" then
                player:Say("No animal selected")
            else
                player:Say("Cannot open commands for this animal")
            end
        end
        return
    end
    
    -- Subscribe to real-time command events
    AE_CommandsUI.subscribeToCommandEvents(animalID)
    
    -- Create enhanced commands window with feedback
    AE_CommandsUI.createCommandsWindowWithFeedback()
    
    AE_CommandsUI.isOpen = true
end

-- Enhanced close function with event cleanup
function AE_CommandsUI.closeWithEventCleanup()
    AE_CommandsUI.unsubscribeFromCommandEvents()
    AE_CommandsUI.activeCommands = {}
    AE_CommandsUI.feedbackLabels = {}
    
    if AE_CommandsUI.commandsWindow then
        AE_CommandsUI.commandsWindow:setVisible(false)
        AE_CommandsUI.commandsWindow:removeFromUIManager()
        AE_CommandsUI.commandsWindow = nil
    end
    
    AE_CommandsUI.isOpen = false
end

-- Initialize enhanced commands UI with dependencies
function AE_CommandsUI.initializeEnhanced()
    AE_CommandsUI.initializeDependencies()
    
    -- B42-compatible UI event handlers via AE_EventRegistry
    local AE_EventRegistry = nil
    local success, result = pcall(function()
        return require("AnimalsEssentials/Config/AE_EventRegistry")
    end)
    if success and result then
        AE_EventRegistry = result
        
        -- Set up global command response handlers
        AE_EventRegistry.subscribeEvent("OnAE_UI_CommandResponse", function(responseData)
            if responseData.uiComponent == "CommandsUI" then
                if responseData.responseHandler then
                    responseData.responseHandler(responseData)
                end
            end
        end)
        
        -- Set up UI event handlers
        AE_EventRegistry.subscribeEvent("OnAE_UI_ShowAnimalCommands", function(eventData)
            if eventData.animal and eventData.player then
                AE_CommandsUI.openWithRealTimeFeedback(
                    eventData.player, 
                    eventData.animal, 
                    eventData.animalID,
                    eventData.onBackCallback
                )
            end
        end)
        
        AE_EventRegistry.subscribeEvent("OnAE_UI_HideAnimalCommands", function()
            AE_CommandsUI.closeWithEventCleanup()
        end)
    else
        -- B42 fallback - no UI event handlers
        print("[AE_CommandsUI] B42 Mode: UI events not supported - manual open/close required")
    end
end

if Events and Events.OnMouseMove and Events.OnPostUIDraw and Events.OnMouseDown and Events.OnRightMouseDown then
    Events.OnMouseMove.Add(AE_CommandsUI.updateHoveredTile)
    Events.OnPostUIDraw.Add(AE_CommandsUI.drawTileSelectionFeedback)
    Events.OnMouseDown.Add(AE_CommandsUI.onMouseDown)
    Events.OnRightMouseDown.Add(AE_CommandsUI.onRightMouseDown)
end

-- PHASE 2: Enhanced animal targeting functions that work with restored animals
function AE_CommandsUI.openCommandsForAnimalByStableID(stableID, player, onBackCallback)
    if not stableID or not player then return false end
    
    -- Use enhanced lookups to find animal (supports restored animals)
    if not AE_EnhancedLookups then
        AE_CommandsUI.initializeDependencies()
    end
    
    if AE_EnhancedLookups then
        local animal = AE_EnhancedLookups.findTargetAnimalForCommand(stableID, player)
        if animal then
            return AE_CommandsUI.openWithRealTimeFeedback(player, animal, stableID, onBackCallback)
        else
            if player and player.Say then
                player:Say("Animal with ID " .. stableID .. " not found or not accessible")
            end
            return false
        end
    else
        if player and player.Say then
            player:Say("Enhanced targeting system not available")
        end
        return false
    end
end

-- PHASE 2: Validate current animal is still accessible (for restored animals)
function AE_CommandsUI.validateCurrentAnimal()
    if not AE_CommandsUI.animal or not AE_CommandsUI.animalID then
        return false
    end
    
    -- Check if animal still exists and is valid
    if not AE_CommandsUI.animal:isExistInTheWorld() or AE_CommandsUI.animal:isDead() then
        return false
    end
    
    -- For restored animals, verify it's still in the mapping
    if AE_EnhancedLookups then
        local foundAnimal = AE_EnhancedLookups.getTamedAnimalByStableID(AE_CommandsUI.animalID)
        return foundAnimal ~= nil
    end
    
    return true
end

-- PHASE 2: Refresh animal reference (useful for restored animals)
function AE_CommandsUI.refreshAnimalReference()
    if not AE_CommandsUI.animalID or not AE_CommandsUI.player then
        return false
    end
    
    if AE_EnhancedLookups then
        local refreshedAnimal = AE_EnhancedLookups.findTargetAnimalForCommand(AE_CommandsUI.animalID, AE_CommandsUI.player)
        if refreshedAnimal then
            AE_CommandsUI.animal = refreshedAnimal
            return true
        end
    end
    
    return false
end

-- PHASE 2: Handle animal instance updates (for restored animals)
function AE_CommandsUI.handleAnimalInstanceUpdate(stableID, newAnimal)
    -- If we're currently managing commands for this animal, update the reference
    if AE_CommandsUI.animal and AE_CommandsUI.animalID == stableID then
        AE_CommandsUI.animal = newAnimal
        -- Refresh any UI elements that depend on the animal instance
        print("[COMMANDS UI] Updated animal instance for: " .. stableID)
    end
end

-- Subscribe to animal instance update events
if Events and Events.OnTamedAnimalInstanceUpdated then
    Events.OnTamedAnimalInstanceUpdated.Add(AE_CommandsUI.handleAnimalInstanceUpdate)
end

-- Initialize enhanced commands UI on game start
Events.OnGameStart.Add(AE_CommandsUI.initializeEnhanced)

return AE_CommandsUI