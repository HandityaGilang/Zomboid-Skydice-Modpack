-- CONVERTED: AE_NamingUI.lua
-- SESSION 3D: Enhanced with AE_DataService validation and integration

local AE_TamingSystem = require("AnimalsEssentials/Taming/AE_TamingSystem")
local AnimalRegistry = require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")

local AE_NamingUI = {}

-- CONVERTED: Enhanced context menu creation with AE_DataService validation
local function createAnimalMenu(player, context, worldobjects)
    if not player or not context then return end
    
    for _, obj in ipairs(worldobjects) do
        if instanceof(obj, "IsoAnimal") then
            local animal = obj
            
            -- CONVERTED: Enhanced animal validation using AE_DataService
            local dataServiceAvailable = false
            local isValidAnimal = false
            
            local success, result = pcall(function()
                return AE_DataService ~= nil and AE_DataService.isAnimalValid ~= nil
            end)
            
            if success and result then
                dataServiceAvailable = true
                local validationSuccess, validationResult = pcall(function()
                    return AE_DataService.isAnimalValid(animal)
                end)
                isValidAnimal = validationSuccess and validationResult
                
                if isValidAnimal then
                    local tameSuccess, tameResult = pcall(function()
                        return AE_DataService.isTamed(animal)
                    end)
                    if not (tameSuccess and tameResult) then
                        isValidAnimal = false
                    end
                end
            else
                local registrySuccess, registryResult = pcall(function()
                    return AnimalRegistry and AnimalRegistry.IsFrameworkAnimal and AnimalRegistry.IsFrameworkAnimal(animal)
                end)
                isValidAnimal = registrySuccess and registryResult
            end
            
            if isValidAnimal then
                local owner = AE_TamingSystem.GetOwner(animal)
                if owner and owner == player then
                    local animalName = AE_TamingSystem.GetName(animal)
                    if animalName and animalName ~= "" then
                        local animalType = AnimalRegistry.GetAnimalType(animal) or "Animal"
                        local displayType = animalType:sub(1,1):upper() .. animalType:sub(2)
                        local mainOption = context:addOption(displayType .. ": " .. animalName, nil, nil)
                        local subMenu = context:getNew(context)
                        context:addSubMenu(mainOption, subMenu)
                        
                        -- CONVERTED: Enhanced rename option with validation
                        subMenu:addOption("Rename", animal, function(target)
                            -- Additional validation before opening naming UI
                            if dataServiceAvailable then
                                local validSuccess, validResult = pcall(function()
                                    return AE_DataService.isAnimalValid(target)
                                end)
                                if not (validSuccess and validResult) then
                                    if player and player.Say then
                                        player:Say("Cannot rename - invalid animal")
                                    end
                                    return
                                end
                                
                                local tameSuccess, tameResult = pcall(function()
                                    return AE_DataService.isTamed(target)
                                end)
                                if not (tameSuccess and tameResult) then
                                    if player and player.Say then
                                        player:Say("Can only rename tamed animals")
                                    end
                                    return
                                end
                                
                                local idSuccess, animalID = pcall(function()
                                    return AE_DataService.getStableID(target)
                                end)
                                if not (idSuccess and animalID and animalID ~= "") then
                                    if player and player.Say then
                                        player:Say("Animal not properly registered")
                                    end
                                    return
                                end
                            end
                            
                            AE_TamingSystem.ShowAnimalNamingUI(target, player, true)
                        end)
                        
                        -- CONVERTED: Additional context options with data service integration
                        if dataServiceAvailable then
                            local friendlinessSuccess, friendliness = pcall(function()
                                local key = AE_DataConfig.ModDataKeys.Friendliness
                                local namespace = "AE_DATA"
                                return AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
                            end)
                            friendliness = (friendlinessSuccess and friendliness) or 0
                            
                            local tamenessSuccess, tameness = pcall(function()
                                return AE_DataService.getTameness(animal)
                            end)
                            tameness = (tamenessSuccess and tameness) or 0
                            
                            subMenu:addOption("View Stats", animal, function(target)
                                if player and player.Say then
                                    local stats = string.format("Tameness: %.1f%%, Friendliness: %.1f", 
                                                               tameness, friendliness)
                                    player:Say(stats)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end

-- CONVERTED: Enhanced context menu validation
function AE_NamingUI.validateContextAccess(player, animal)
    if not player or not animal then
        return false, "missing_parameters"
    end
    
    local dataServiceSuccess, dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil and AE_DataService.isAnimalValid ~= nil
    end)
    
    if dataServiceSuccess and dataServiceAvailable then
        local validSuccess, validResult = pcall(function()
            return AE_DataService.isAnimalValid(animal)
        end)
        if not (validSuccess and validResult) then
            return false, "invalid_animal"
        end
        
        local tameSuccess, tameResult = pcall(function()
            return AE_DataService.isTamed(animal)
        end)
        if not (tameSuccess and tameResult) then
            return false, "not_tamed"
        end
        
        local idSuccess, animalID = pcall(function()
            return AE_DataService.getStableID(animal)
        end)
        if not (idSuccess and animalID and animalID ~= "") then
            return false, "no_stable_id"
        end
    end
    
    local registrySuccess, registryResult = pcall(function()
        return AnimalRegistry and AnimalRegistry.IsFrameworkAnimal and AnimalRegistry.IsFrameworkAnimal(animal)
    end)
    if not (registrySuccess and registryResult) then
        return false, "not_framework_animal"
    end
    
    local owner = AE_TamingSystem.GetOwner(animal)
    if not owner or owner ~= player then
        return false, "not_owner"
    end
    
    return true, "valid"
end

-- CONVERTED: Enhanced initialization with data service integration
local function init()
    Events.OnFillWorldObjectContextMenu.Add(createAnimalMenu)
    
    -- CONVERTED: Fire initialization event for other systems
    local success, result = pcall(function()
        return AE_DataService ~= nil and AE_EventRegistry ~= nil and AE_EventRegistry.safeFireEvent ~= nil
    end)
    
    if success and result then
        local eventSuccess, eventResult = pcall(function()
            AE_EventRegistry.safeFireEvent("OnAE_NamingUIInitialized", {
                timestamp = GameTime.getServerTimeMills(),
                dataServiceIntegration = true
            })
        end)
        if not eventSuccess then
            print("[AE_NamingUI] Failed to fire initialization event: " .. tostring(eventResult))
        end
    end
end

Events.OnGameStart.Add(init)

return AE_NamingUI