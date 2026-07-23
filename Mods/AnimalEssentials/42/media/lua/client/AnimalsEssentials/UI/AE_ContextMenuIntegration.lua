-- SESSION 6A3: Advanced Context Menu Integration System
-- Dynamic framework-aware context menu with real-time adaptation

local AE_ContextMenuIntegration = {}

-- Dependencies
local AE_DataService = nil
local AE_StatusMenu = nil
local AE_CommandsUI = nil

-- Context menu state management
local contextMenuCache = {}
local frameworkAvailability = {
    dataService = false,
    commandsUI = false,
    statusMenu = false
}

-- Initialize dependencies with framework detection
function AE_ContextMenuIntegration.initialize()
    AE_ContextMenuIntegration.detectFrameworkComponents()
    AE_ContextMenuIntegration.setupEventHandlers()
end

-- Detect available framework components
function AE_ContextMenuIntegration.detectFrameworkComponents()
    local dataSuccess, dataService = pcall(function()
        return require("AnimalsEssentials/DataServices/AE_DataService")
    end)
    if dataSuccess and dataService then
        AE_DataService = dataService
        frameworkAvailability.dataService = true
    end
    
    local statusSuccess, statusMenu = pcall(function()
        return require("AnimalsEssentials/UI/AE_StatusMenu")
    end)
    if statusSuccess and statusMenu then
        AE_StatusMenu = statusMenu
        frameworkAvailability.statusMenu = true
    end
    
    local commandsSuccess, commandsUI = pcall(function()
        return require("AnimalsEssentials/UI/AE_CommandsUI")
    end)
    if commandsSuccess and commandsUI then
        AE_CommandsUI = commandsUI
        frameworkAvailability.commandsUI = true
    end
end

-- Setup event handlers for dynamic context menu updates
function AE_ContextMenuIntegration.setupEventHandlers()
    -- B42-compatible event handling via AE_EventRegistry
    local AE_EventRegistry = nil
    local success, result = pcall(function()
        return require("AnimalsEssentials/Config/AE_EventRegistry")
    end)
    if success and result then
        AE_EventRegistry = result
        
        -- Listen for animal state changes to update context menus
        AE_EventRegistry.subscribeEvent("OnAE_AnimalStateChanged", function(eventData)
            AE_ContextMenuIntegration.invalidateContextMenuCache(eventData.animalID)
        end)
        
        -- Listen for framework component availability changes
        AE_EventRegistry.subscribeEvent("OnAE_FrameworkComponentAvailable", function(eventData)
            frameworkAvailability[eventData.component] = true
            AE_ContextMenuIntegration.refreshAllContextMenus()
        end)
        
        AE_EventRegistry.subscribeEvent("OnAE_FrameworkComponentUnavailable", function(eventData)
            frameworkAvailability[eventData.component] = false
            AE_ContextMenuIntegration.refreshAllContextMenus()
        end)
    else
        -- Fallback for B42 - custom events not supported
        print("[AE_ContextMenuIntegration] B42 Mode: Custom events not supported - using direct function calls")
    end
end

-- Main context menu integration function
function AE_ContextMenuIntegration.addAnimalContextOptions(player, animal, context)
    if not player or not animal or not context then
        return false
    end
    
    -- Check if this is a framework-managed animal
    if not AE_ContextMenuIntegration.isFrameworkAnimal(animal) then
        return false
    end
    
    -- Defensive method existence check for getAnimalId
    if not animal.getAnimalID then
        print("[AE_ContextMenuIntegration] ERROR: getAnimalID method not available for animal")
        return false
    end
    local animalID = animal:getAnimalID()
    local cacheKey = animalID .. "_" .. player:getUsername()
    
    -- Check cache for performance optimization
    if contextMenuCache[cacheKey] and contextMenuCache[cacheKey].timestamp > (getTimestamp() - 5000) then
        AE_ContextMenuIntegration.applyContextMenuOptions(context, contextMenuCache[cacheKey].options)
        return true
    end
    
    -- Generate context menu options based on animal state and framework availability
    local contextOptions = AE_ContextMenuIntegration.generateContextOptions(player, animal)
    
    -- Cache the options for performance
    contextMenuCache[cacheKey] = {
        options = contextOptions,
        timestamp = getTimestamp()
    }
    
    -- Apply the options to the context menu
    AE_ContextMenuIntegration.applyContextMenuOptions(context, contextOptions)
    
    return true
end

-- Check if animal is managed by the framework
function AE_ContextMenuIntegration.isFrameworkAnimal(animal)
    if not animal then return false end
    
    if AE_DataService and frameworkAvailability.dataService then
        -- Use data service to check if animal is framework-managed
        local isManaged = false
        sendServerCommand("AE_UIService", "dataRequest", {
            requestType = "isFrameworkAnimal",
            animalID = animal.getAnimalID and animal:getAnimalID() or "unknown",
            responseHandler = function(responseData)
                isManaged = responseData.success and responseData.isFrameworkAnimal
            end
        })
        return isManaged
    else
        -- Fallback: check for framework ModData keys
        -- Defensive method existence check for getModData
        if not animal.getModData then
            print("[AE_ContextMenuIntegration] WARNING: getModData method not available for animal")
            return false
        end
        local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")
        local stableID = AE_DataService.getStableID(animal)
        local animalName = AE_DataService.getAnimalName(animal)
        local tameness = AE_DataService.getTameness(animal)
        return stableID or animalName or tameness ~= nil
    end
end

-- Generate dynamic context menu options based on animal state
function AE_ContextMenuIntegration.generateContextOptions(player, animal)
    local options = {}
    -- Defensive method existence check for getAnimalId
    if not animal.getAnimalID then
        print("[AE_ContextMenuIntegration] ERROR: getAnimalID method not available for animal")
        return false
    end
    local animalID = animal:getAnimalID()
    
    -- Get animal state information
    local animalState = AE_ContextMenuIntegration.getAnimalState(player, animal)
    
    -- Add status menu option if available
    if frameworkAvailability.statusMenu and animalState.isTamed then
        table.insert(options, {
            text = "View Status",
            icon = "status_icon",
            action = function()
                sendServerCommand("AE_UIService", "componentUpdate", {
                    component = "StatusMenu",
                    updateType = "showAnimalStatus",
                    animal = animal
                })
            end,
            condition = function() return animalState.canViewStatus end
        })
    end
    
    -- Add commands option if animal is tamed and commands available
    if frameworkAvailability.commandsUI and animalState.isTamed and animalState.isOwner then
        table.insert(options, {
            text = "Give Commands",
            icon = "command_icon",
            action = function()
                sendServerCommand("AE_UIService", "componentUpdate", {
                    component = "CommandsUI",
                    updateType = "showAnimalCommands",
                    animal = animal,
                    player = player,
                    animalID = animalID
                })
            end,
            condition = function() return animalState.canGiveCommands end
        })
    end
    
    -- Add care options based on framework availability
    if frameworkAvailability.dataService then
        if animalState.needsCare then
            table.insert(options, {
                text = "Care for Animal",
                icon = "care_icon",
                action = function()
                    AE_ContextMenuIntegration.showCareOptions(player, animal)
                end,
                condition = function() return animalState.canCare end
            })
        end
        
        -- Add feeding option
        if animalState.needsFeeding then
            table.insert(options, {
                text = "Feed Animal",
                icon = "feed_icon",
                action = function()
                    AE_ContextMenuIntegration.feedAnimal(player, animal)
                end,
                condition = function() return animalState.canFeed end
            })
        end
    end
    
    -- Add taming option for wild animals
    if not animalState.isTamed and animalState.canTame then
        table.insert(options, {
            text = "Attempt to Tame",
            icon = "tame_icon",
            action = function()
                AE_ContextMenuIntegration.attemptTaming(player, animal)
            end,
            condition = function() return animalState.canTame end
        })
    end
    
    -- Add equipment options for tamed animals
    if animalState.isTamed and animalState.isOwner and frameworkAvailability.dataService then
        table.insert(options, {
            text = "Manage Equipment",
            icon = "equipment_icon",
            action = function()
                AE_ContextMenuIntegration.showEquipmentOptions(player, animal)
            end,
            condition = function() return animalState.canManageEquipment end
        })
    end
    
    return options
end

-- Get comprehensive animal state for context menu decisions
function AE_ContextMenuIntegration.getAnimalState(player, animal)
    local state = {
        isTamed = false,
        isOwner = false,
        needsCare = false,
        needsFeeding = false,
        canTame = false,
        canViewStatus = false,
        canGiveCommands = false,
        canCare = false,
        canFeed = false,
        canManageEquipment = false
    }
    
    if AE_DataService and frameworkAvailability.dataService then
        -- Request comprehensive animal state via data service
        sendServerCommand("AE_UIService", "dataRequest", {
            requestType = "animalState",
            animalID = animal.getAnimalID and animal:getAnimalID() or "unknown",
            playerID = player:getUsername(),
            responseHandler = function(responseData)
                if responseData.success and responseData.animalState then
                    for key, value in pairs(responseData.animalState) do
                        state[key] = value
                    end
                end
            end
        })
    else
        -- Fallback: basic state detection from ModData
        -- Defensive method existence check for getModData
        if not animal.getModData then
            print("[AE_ContextMenuIntegration] WARNING: getModData method not available for animal")
            return state
        end
        local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")
        local tameness = AE_DataService.getTameness(animal)
        local owner = AE_DataService.getOwner(animal)
        state.isTamed = tameness and tameness >= 80
        state.isOwner = owner == player:getUsername()
        state.canViewStatus = true
        state.canTame = not state.isTamed
        state.canFeed = true
    end
    
    return state
end

-- Apply generated options to the actual context menu
function AE_ContextMenuIntegration.applyContextMenuOptions(context, options)
    if not context or not options then return end
    
    local hasFrameworkOptions = false
    
    for _, option in ipairs(options) do
        -- Check if option condition is met
        if not option.condition or option.condition() then
            context:addOption(option.text, option.target or nil, option.action)
            hasFrameworkOptions = true
        end
    end
    
    -- Add separator if we added framework options
    if hasFrameworkOptions and #options > 0 then
        context:addOption("", nil, nil) -- Separator
    end
end

-- Context menu action handlers
function AE_ContextMenuIntegration.showCareOptions(player, animal)
    sendServerCommand("AE_UIService", "componentUpdate", {
        component = "CareOptions",
        updateType = "showCareOptions",
        player = player,
        animal = animal,
        animalID = animal.getAnimalID and animal:getAnimalID() or "unknown"
    })
end

function AE_ContextMenuIntegration.feedAnimal(player, animal)
    sendServerCommand("AE_UIService", "componentUpdate", {
        component = "AnimalCommands",
        updateType = "feedAnimal",
        player = player,
        animal = animal,
        animalID = animal.getAnimalID and animal:getAnimalID() or "unknown"
    })
end

function AE_ContextMenuIntegration.attemptTaming(player, animal)
    sendServerCommand("AE_UIService", "componentUpdate", {
        component = "AnimalCommands",
        updateType = "attemptTaming",
        player = player,
        animal = animal,
        animalID = animal.getAnimalID and animal:getAnimalID() or "unknown"
    })
end

function AE_ContextMenuIntegration.showEquipmentOptions(player, animal)
    sendServerCommand("AE_UIService", "componentUpdate", {
        component = "EquipmentOptions",
        updateType = "showEquipmentOptions",
        player = player,
        animal = animal,
        animalID = animal.getAnimalID and animal:getAnimalID() or "unknown"
    })
end

-- Cache management functions
function AE_ContextMenuIntegration.invalidateContextMenuCache(animalID)
    if not animalID then return end
    
    for cacheKey, _ in pairs(contextMenuCache) do
        if cacheKey:find(animalID) then
            contextMenuCache[cacheKey] = nil
        end
    end
end

function AE_ContextMenuIntegration.refreshAllContextMenus()
    contextMenuCache = {}
end

function AE_ContextMenuIntegration.clearExpiredCache()
    local currentTime = getTimestamp()
    for cacheKey, cacheData in pairs(contextMenuCache) do
        if currentTime - cacheData.timestamp > 30000 then -- 30 seconds
            contextMenuCache[cacheKey] = nil
        end
    end
end

-- Framework availability checking
function AE_ContextMenuIntegration.getFrameworkAvailability()
    return frameworkAvailability
end

function AE_ContextMenuIntegration.updateFrameworkAvailability(component, available)
    if frameworkAvailability[component] ~= nil then
        frameworkAvailability[component] = available
        local AE_EventRegistry = nil
        local success, result = pcall(function()
            return require("AnimalsEssentials/Config/AE_EventRegistry")
        end)
        if success and result then
            AE_EventRegistry = result
            if available then
                AE_EventRegistry.safeFireEvent("OnAE_FrameworkComponentAvailable", {component = component})
            else
                AE_EventRegistry.safeFireEvent("OnAE_FrameworkComponentUnavailable", {component = component})
            end
        end
    end
end

-- Initialize on game start
Events.OnGameStart.Add(AE_ContextMenuIntegration.initialize)

-- PHASE 2 CONSOLIDATION: Timer moved to AE_DataCleanupCoordinator
-- Events.EveryTenMinutes.Add(AE_ContextMenuIntegration.clearExpiredCache) -- Disabled - handled by coordinator

return AE_ContextMenuIntegration