local KittyMod_UIBridge = {}

local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
local KittyMod_SafeAPI = require("KittyMod/Core/KittyMod_SafeAPI")

local frameworkUIAvailable = false
local uiEnhancements = {}

function KittyMod_UIBridge.initialize()
    KittyMod_UIBridge.detectFrameworkUI()
    if frameworkUIAvailable then
        KittyMod_UIBridge.enableUIIntegration()
    end
    KittyMod_UIBridge.setupUIEventHandlers()
end

function KittyMod_UIBridge.detectFrameworkUI()
    frameworkUIAvailable = false
    local uiComponents = {
        "AnimalsEssentials/UI/AE_StatusMenu",
        "AnimalsEssentials/UI/AE_CommandsUI", 
        "AnimalsEssentials/UI/AE_CareUI"
    }
    for _, componentPath in ipairs(uiComponents) do
        local success, component = pcall(function()
            return require(componentPath)
        end)
        if success and component then
            frameworkUIAvailable = true
        end
    end
    return frameworkUIAvailable
end

function KittyMod_UIBridge.enableUIIntegration()
    if not frameworkUIAvailable then return false end
    uiEnhancements.contextMenuIntegration = true
    uiEnhancements.statusMenuIntegration = true
    uiEnhancements.commandUIIntegration = true
    return true
end

function KittyMod_UIBridge.setupUIEventHandlers()
    if not Events then
        return
    end
    
    if Events.OnFillInventoryObjectContextMenu then
        Events.OnFillInventoryObjectContextMenu.Add(KittyMod_UIBridge.onContextMenu)
    end
    
    if frameworkUIAvailable then
        if Events.OnAE_UIRequest then
            Events.OnAE_UIRequest.Add(KittyMod_UIBridge.onFrameworkUIRequest)
        end
        if Events.OnAE_StatusUIUpdate then
            Events.OnAE_StatusUIUpdate.Add(KittyMod_UIBridge.onFrameworkStatusUpdate)
        end
    end
end

function KittyMod_UIBridge.onContextMenu(player, context, objects)
    if not player or not context or not objects then return end
    for _, object in ipairs(objects) do
        if object and instanceof(object, "IsoAnimal") then
            local cat = object
            if KittyMod_ModData.isCat(cat) then
                KittyMod_UIBridge.addCatContextOptions(cat, player, context)
            end
        end
    end
end

function KittyMod_UIBridge.addCatContextOptions(cat, player, context)
    if not cat or not player or not context then return end
    local isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false
    local owner = KittyMod_ModData.getCatData(cat, "CatOwner") or ""
    local catName = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat"
    if isTamed and owner == player:getUsername() then
        context:addOptionOnTop("Examine " .. catName, cat, function()
            KittyMod_UIBridge.showCatStatus(cat, player)
        end)
        context:addOptionOnTop("Give Command to " .. catName, cat, function()
            KittyMod_UIBridge.showCatCommands(cat, player)
        end)
        if frameworkUIAvailable then
            context:addOptionOnTop("Open Framework Status", cat, function()
                KittyMod_UIBridge.openFrameworkStatus(cat, player)
            end)
        end
    else
        local tameness = KittyMod_ModData.getCatData(cat, "CatTameness") or 0
        context:addOptionOnTop("Approach Cat (" .. math.floor(tameness) .. "% trust)", cat, function()
            KittyMod_UIBridge.approachCat(cat, player)
        end)
    end
end

function KittyMod_UIBridge.showCatStatus(cat, player)
    if not cat or not player then return end
    local KittyMod_StatusUI = require("KittyMod/UI/KittyMod_StatusUI")
    KittyMod_StatusUI.showStatusWindow()
end

function KittyMod_UIBridge.showCatCommands(cat, player)
    if not cat or not player then return end
    local KittyMod_Commands = require("KittyMod/Behaviors/KittyMod_Commands")
    KittyMod_Commands.showCatCommandMenu(player)
end

function KittyMod_UIBridge.openFrameworkStatus(cat, player)
    if not frameworkUIAvailable or not cat or not player then return end
    sendServerCommand("AE_UIService", "componentUpdate", {
        component = "StatusMenu",
        updateType = "openStatusMenu",
        animalID = cat:getOnlineID(),
        animalType = "cat",
        playerID = player:getOnlineID()
    })
end

function KittyMod_UIBridge.approachCat(cat, player)
    if not cat or not player then return end
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality")
    local tameness = KittyMod_ModData.getCatData(cat, "CatTameness") or 0
    local KittyMod_Behaviors = require("KittyMod/Behaviors/KittyMod_Behaviors")
    KittyMod_Behaviors.handleDirectCatInteraction(cat, player)
end

function KittyMod_UIBridge.onFrameworkUIRequest(requestData)
    if not requestData or requestData.animalType ~= "cat" then return end
    local cat = KittyMod_SafeAPI.safeGetAnimalByID(requestData.animalID)
    if not cat or not KittyMod_ModData.isCat(cat) then return end
    local responseData = {}
    if requestData.requestType == "statusInfo" then
        responseData = {
            name = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat",
            breed = KittyMod_ModData.getCatData(cat, "CatBreed") or "Unknown",
            personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "unknown",
            tameness = KittyMod_ModData.getCatData(cat, "CatTameness") or 0,
            mood = KittyMod_ModData.getCatData(cat, "CatMood") or "content",
            energy = KittyMod_ModData.getCatData(cat, "CatEnergy") or 100,
            affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 0
        }
    elseif requestData.requestType == "commandInfo" then
        local KittyMod_Commands = require("KittyMod/Behaviors/KittyMod_Commands")
        local currentCommand = KittyMod_Commands.getCurrentCommand(cat)
        responseData = {
            currentCommand = currentCommand and currentCommand.command or "none",
            loyalty = KittyMod_ModData.getCatData(cat, "CatLoyalty") or 0,
            availableCommands = {"come", "stay", "sit", "follow", "hunt", "play"}
        }
    end

    sendServerCommand("AE_UIService", "dataRequest", {
        requestType = "uiResponse",
        requestId = requestData.requestId,
        animalID = requestData.animalID,
        success = true,
        data = responseData
    })
end

function KittyMod_UIBridge.onFrameworkStatusUpdate(updateData)
    if not updateData or updateData.animalType ~= "cat" then return end
    local cat = KittyMod_SafeAPI.safeGetAnimalByID(updateData.animalID)
    if not cat or not KittyMod_ModData.isCat(cat) then return end
    if updateData.updateType == "refresh" then
        local KittyMod_StatusUI = require("KittyMod/UI/KittyMod_StatusUI")
        KittyMod_StatusUI.refreshStatus()
    end
end

function KittyMod_UIBridge.getCatUIInfo(cat)
    if not cat or not KittyMod_ModData.isCat(cat) then return nil end
    return {
        displayName = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat",
        breed = KittyMod_ModData.getCatData(cat, "CatBreed") or "Unknown",
        personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "unknown",
        isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false,
        owner = KittyMod_ModData.getCatData(cat, "CatOwner") or "",
        mood = KittyMod_ModData.getCatData(cat, "CatMood") or "content",
        tameness = KittyMod_ModData.getCatData(cat, "CatTameness") or 0,
        affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 0,
        energy = KittyMod_ModData.getCatData(cat, "CatEnergy") or 100,
        huntingSkill = KittyMod_ModData.getCatData(cat, "CatHuntingSkill") or 50,
        enhancedFeatures = frameworkUIAvailable
    }
end

function KittyMod_UIBridge.isFrameworkUIAvailable()
    return frameworkUIAvailable
end

function KittyMod_UIBridge.getUIEnhancements()
    return uiEnhancements
end

Events.OnGameStart.Add(KittyMod_UIBridge.initialize)

return KittyMod_UIBridge