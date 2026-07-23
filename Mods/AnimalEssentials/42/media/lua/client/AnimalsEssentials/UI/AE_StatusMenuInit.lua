-- CONVERTED: AE_StatusMenuInit.lua
-- SESSION 3D: Enhanced with AE_DataService integration and validation

local AE_StatusMenu = require("AnimalsEssentials/UI/AE_StatusMenu")

-- CONVERTED: Enhanced initialization with data service verification
local function onGameStart()
    local function delayedInit()
        local player = getSpecificPlayer(0)
        if player then
            -- CONVERTED: Verify AE_DataService availability before initializing
            local dataServiceAvailable = pcall(function()
                return AE_DataService ~= nil and AE_DataService.isAnimalValid
            end)
            
            if dataServiceAvailable then
                -- Enhanced initialization with data service integration
                local initSuccess = pcall(function()
                    if AE_StatusMenu and AE_StatusMenu.initialize then
                        AE_StatusMenu.initialize()
                        return true
                    end
                    return false
                end)
                
                if not initSuccess then
                    print("[AE_StatusMenuInit] Failed to initialize AE_StatusMenu")
                end
                
                -- CONVERTED: Fire initialization event for coordination
                if AE_EventRegistry then
                    AE_EventRegistry.safeFireEvent("OnAE_StatusMenuInitialized", {
                        timestamp = GameTime.getServerTimeMills(),
                        dataServiceIntegration = true,
                        playerID = player:getOnlineID()
                    })
                end
            else
                -- Fallback initialization without data service
                AE_StatusMenu.Initialize()
                
                -- Log fallback mode for debugging
                if isDebugEnabled() then
                    print("[AE_StatusMenuInit] Initialized in fallback mode - AE_DataService not available")
                end
            end
        end
    end
    
    local initialized = false
    local function tryInit()
        if not initialized then
            initialized = true
            Events.OnTick.Remove(tryInit)
            delayedInit()
        end
    end
    Events.OnTick.Add(tryInit)
end

-- CONVERTED: Enhanced status menu validation
function AE_StatusMenuInit_ValidateInitialization()
    local dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil
    end)
    
    local statusMenuAvailable = pcall(function()
        return AE_StatusMenu ~= nil and AE_StatusMenu.Initialize ~= nil
    end)
    
    return {
        dataService = dataServiceAvailable,
        statusMenu = statusMenuAvailable,
        timestamp = GameTime.getServerTimeMills(),
        playerCount = getNumActivePlayers()
    }
end

-- CONVERTED: Enhanced reinitialization for data service updates
function AE_StatusMenuInit_Reinitialize()
    local player = getPlayer()
    if player then
        local validationResult = AE_StatusMenuInit_ValidateInitialization()
        
        if validationResult.dataService and validationResult.statusMenu then
            -- Reinitialize with full data service integration
            AE_StatusMenu.Initialize()
            
            if AE_EventRegistry then
                AE_EventRegistry.safeFireEvent("OnAE_StatusMenuReinitialized", {
                    timestamp = GameTime.getServerTimeMills(),
                    dataServiceIntegration = true,
                    reason = "manual_reinit"
                })
            end
            
            return true
        else
            return false, "validation_failed"
        end
    else
        return false, "no_player"
    end
end

Events.OnGameStart.Add(onGameStart)

-- CONVERTED: Export validation functions for external use
return {
    validate = AE_StatusMenuInit_ValidateInitialization,
    reinitialize = AE_StatusMenuInit_Reinitialize
}