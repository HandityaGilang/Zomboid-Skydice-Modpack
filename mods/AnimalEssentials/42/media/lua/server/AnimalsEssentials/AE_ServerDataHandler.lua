AE_ServerDataHandler = {}

-- Server-side data validation and authority implementation
-- Ensures data integrity and proper authorization for ModData operations

-- Server-side data validation rules
local validationRules = {
    tameness = {
        type = "number",
        min = 0,
        max = 100,
        required = false
    },
    hunger = {
        type = "number", 
        min = 0,
        max = 100,
        required = false
    },
    thirst = {
        type = "number",
        min = 0, 
        max = 100,
        required = false
    },
    health = {
        type = "number",
        min = 0,
        max = 100, 
        required = false
    },
    isTamed = {
        type = "boolean",
        required = false
    },
    ownerID = {
        type = "string",
        maxLength = 64,
        required = false
    },
    breed = {
        type = "string",
        maxLength = 32,
        required = false
    }
}

-- Command table structure for organized routing
local Commands = {}

-- CRITICAL: Animal ID resolution function for server command handlers
function AE_ServerDataHandler.getAnimalByID(animalID)
    if not animalID then
        print("[AE_ServerDataHandler] ERROR: No animalID provided for getAnimalByID")
        return nil
    end
    
    -- Use established AnimalRegistry pattern for animal resolution
    local success, AnimalRegistry = pcall(function()
        return require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
    end)
    
    if not success or not AnimalRegistry then
        print("[AE_ServerDataHandler] ERROR: AnimalRegistry not available for animal resolution")
        return nil
    end
    
    -- Try to get animal by ID using AnimalRegistry
    if AnimalRegistry.GetAnimalByID then
        local animal = AnimalRegistry.GetAnimalByID(animalID)
        if animal then
            return animal
        end
    end
    
    -- Fallback: Search through all animals in the cell for matching ID
    local cell = getCell()
    if not cell then
        print("[AE_ServerDataHandler] ERROR: No cell available for animal search")
        return nil
    end
    
    for i = 0, cell:getObjectList():size() - 1 do
        local obj = cell:getObjectList():get(i)
        local success, isValidAnimal = pcall(function()
            -- Multi-layer defensive validation
            if not obj then return false end
            if not AE_DataService then return false end
            if not AE_DataService.isAnimalValid then return false end
            
            return AE_DataService.isAnimalValid(obj)
        end)
        
        if success and isValidAnimal then
            local objModData = AnimalRegistry.GetAnimalModData and AnimalRegistry.GetAnimalModData(obj)
            if objModData and objModData.AE_AnimalID == animalID then
                return obj
            end
            
            -- Fallback to StableID for backward compatibility
            local stableID = objModData and objModData.AE_StableID
            if stableID == animalID then
                return obj
            end
        end
    end
    
    print("[AE_ServerDataHandler] WARNING: Animal not found with ID: " .. tostring(animalID))
    return nil
end

-- Data service commands (existing functionality)
Commands.AE_DataService = {
    setTameness = function(player, args)
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if animal and args.data then
            local success = AE_DataService.setTameness(animal, args.data.tameness)
            return success, success and "Tameness updated" or "Tameness update failed"
        end
        return false, "Invalid parameters"
    end,
    
    setHunger = function(player, args)
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if animal and args.data then
            local success = AE_DataService.setHunger(animal, args.data.hunger)
            return success, success and "Hunger updated" or "Hunger update failed"
        end
        return false, "Invalid parameters"
    end,
    
    setThirst = function(player, args)
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if animal and args.data then
            local success = AE_DataService.setThirst(animal, args.data.thirst)
            return success, success and "Thirst updated" or "Thirst update failed"
        end
        return false, "Invalid parameters"
    end,
    
    setHealth = function(player, args)
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if animal and args.data then
            local success = AE_DataService.setHealth(animal, args.data.health)
            return success, success and "Health updated" or "Health update failed"
        end
        return false, "Invalid parameters"
    end,
    
    setTamed = function(player, args)
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if animal and args.data then
            local success = AE_DataService.setTamed(animal, args.data.isTamed)
            if success and args.data.isTamed then
                AE_DataService.setOwner(animal, player:getUsername())
            end
            return success, success and "Tamed status updated" or "Tamed status update failed"
        end
        return false, "Invalid parameters"
    end,
    
    setOwner = function(player, args)
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if animal and args.data then
            local success = AE_DataService.setOwner(animal, args.data.ownerID)
            return success, success and "Owner updated" or "Owner update failed"
        end
        return false, "Invalid parameters"
    end,
    
    setBreed = function(player, args)
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if animal and args.data then
            local success = AE_DataService.setBreed(animal, args.data.breed)
            return success, success and "Breed updated" or "Breed update failed"
        end
        return false, "Invalid parameters"
    end,
    
    updateStatus = function(player, args)
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if animal then
            local success = AE_UnifiedStateTracker.updateStatus(animal)
            return success, success and "Status tracking updated" or "Status update failed"
        end
        return false, "Invalid parameters"
    end
}

-- UI service commands using B42-compatible sendClientCommand pattern
Commands.AE_UIService = {
    dataRequest = function(player, args)
        local success = false
        local animalData = {}
        local errorMessage = "Unknown error"
        
        if args.requestType == "animalStatus" and args.animalID then
            local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
            if animal and AE_DataService then
                -- Retrieve animal data via unified AE_DataService backend
                animalData = {
                    name = AE_DataService.getAnimalName(animal) or "Unknown",
                    owner = AE_DataService.getOwner(animal) or "None",
                    tameness = AE_DataService.getTameness(animal) or 0,
                    health = AE_DataService.getHealth(animal) or 0,
                    hunger = AE_DataService.getHunger(animal) or 0,
                    thirst = AE_DataService.getThirst(animal) or 0,
                    isTamed = AE_DataService.isTamed(animal) or false,
                    stableID = AE_DataService.getStableID(animal) or "None"
                }
                success = true
            else
                errorMessage = animal and "AE_DataService unavailable" or "Animal not found"
            end
        else
            errorMessage = "Invalid request parameters"
        end
        
        sendClientCommand(player, "AE_UIService", "dataResponse", {
            success = success,
            requestType = args.requestType,
            animalData = success and animalData or nil,
            errorMessage = success and nil or errorMessage
        })
        
        return success, success and "Data retrieved successfully" or errorMessage
    end,
    
    componentUpdate = function(player, args)
        local success = false
        local message = "Unknown update type"
        
        if args.updateType == "attemptTaming" and args.animalID then
            print("[TAMING DEBUG] Server received taming attempt for animalID: " .. tostring(args.animalID))
            local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
            if animal then
                print("[TAMING DEBUG] Animal found on server, calling FeedAnimal")
                local AE_TamingSystem = require("AnimalsEssentials/Taming/AE_TamingSystem")
                success = AE_TamingSystem.FeedAnimal(animal, player)
                message = success and "Taming attempt processed" or "Taming attempt failed"
                print("[TAMING DEBUG] FeedAnimal result: " .. tostring(success) .. " - " .. message)
            else
                print("[TAMING DEBUG] ERROR: Animal not found on server")
                message = "Animal not found"
            end
        elseif args.updateType == "feedAnimal" and args.animalID then
            local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
            if animal then
                local AE_TamingSystem = require("AnimalsEssentials/Taming/AE_TamingSystem")
                success = AE_TamingSystem.FeedAnimal(animal, player)
                message = success and "Animal fed successfully" or "Feeding failed"
            else
                message = "Animal not found"
            end
        else
            success = true
            message = "Component update processed"
        end
        
        sendClientCommand(player, "AE_UIService", "updateResult", {
            success = success,
            component = args.component,
            updateType = args.updateType,
            message = message
        })
        return success, message
    end,
    
    broadcastUpdate = function(player, args)
        sendClientCommand(player, "AE_UIService", "broadcastResult", {
            success = true,
            updateType = args.updateType
        })
        return true, "Broadcast update processed"
    end
}

-- Service registry commands (for service discovery)
Commands.AE_ServiceRegistry = {
    serviceAvailable = function(player, args)
        sendClientCommand(player, "AE_ServiceRegistry", "serviceRegistered", {
            success = true,
            service = args.service,
            version = args.version
        })
        return true, "Service availability registered"
    end,
    
    serviceRequest = function(player, args)
        sendClientCommand(player, "AE_ServiceRegistry", "serviceResponse", {
            success = true,
            service = args.service,
            available = true
        })
        return true, "Service request processed"
    end
}

-- UI framework commands (for component management)
Commands.AE_UIFramework = {
    componentAvailable = function(player, args)
        sendClientCommand(player, "AE_UIFramework", "componentRegistered", {
            success = true,
            component = args.component,
            capabilities = args.capabilities
        })
        return true, "Component availability registered"
    end,
    
    componentRegistration = function(player, args)
        sendClientCommand(player, "AE_UIFramework", "registrationResult", {
            success = true,
            component = args.component
        })
        return true, "Component registration processed"
    end
}

-- Cross-mod service commands (for cross-mod communication)
Commands.AE_CrossModService = {
    statusUpdate = function(player, args)
        sendClientCommand(player, "AE_CrossModService", "statusResult", {
            success = true,
            modName = args.modName,
            status = args.status
        })
        return true, "Cross-mod status updated"
    end,
    
    integrationRequest = function(player, args)
        sendClientCommand(player, "AE_CrossModService", "integrationResponse", {
            success = true,
            modName = args.modName,
            integration = args.integration
        })
        return true, "Integration request processed"
    end,
    
    syncComplete = function(player, args)
        sendClientCommand(player, "AE_CrossModService", "syncResult", {
            success = true,
            syncType = args.syncType
        })
        return true, "Cross-mod sync completed"
    end
}

-- PHASE 2A: CommandsSystem server command handlers
Commands.AE_CommandsSystem = {
    followCommand = function(player, args)
        if not args.animalID then
            return false, "Animal ID required for follow command"
        end
        
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if not animal then
            return false, "Animal not found with ID: " .. tostring(args.animalID)
        end
        
        -- Load CommandsSystem module
        local success, CommandsSystem = pcall(function()
            return require("AnimalsEssentials/CoreSystems/AE_CommandsSystem")
        end)
        
        if not success or not CommandsSystem then
            return false, "CommandsSystem not available"
        end
        
        -- Validate player authorization
        if not CommandsSystem.validateAnimalAccess(player, animal) then
            return false, "Player not authorized to command this animal"
        end
        
        -- Execute follow command
        local commandSuccess = CommandsSystem.FollowCommand(animal, player)
        if commandSuccess then
            return true, "Follow command executed successfully"
        else
            return false, "Follow command failed"
        end
    end,
    
    stayCommand = function(player, args)
        if not args.animalID then
            return false, "Animal ID required for stay command"
        end
        
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if not animal then
            return false, "Animal not found with ID: " .. tostring(args.animalID)
        end
        
        -- Load CommandsSystem module
        local success, CommandsSystem = pcall(function()
            return require("AnimalsEssentials/CoreSystems/AE_CommandsSystem")
        end)
        
        if not success or not CommandsSystem then
            return false, "CommandsSystem not available"
        end
        
        -- Validate player authorization
        if not CommandsSystem.validateAnimalAccess(player, animal) then
            return false, "Player not authorized to command this animal"
        end
        
        -- Execute stay command
        local commandSuccess = CommandsSystem.StayCommand(animal, player)
        if commandSuccess then
            return true, "Stay command executed successfully"
        else
            return false, "Stay command failed"
        end
    end,
    
    goToCommand = function(player, args)
        if not args.animalID or not args.targetX or not args.targetY or not args.targetZ then
            return false, "Animal ID and target coordinates required for goto command"
        end
        
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if not animal then
            return false, "Animal not found with ID: " .. tostring(args.animalID)
        end
        
        -- Load CommandsSystem module
        local success, CommandsSystem = pcall(function()
            return require("AnimalsEssentials/CoreSystems/AE_CommandsSystem")
        end)
        
        if not success or not CommandsSystem then
            return false, "CommandsSystem not available"
        end
        
        -- Validate player authorization
        if not CommandsSystem.validateAnimalAccess(player, animal) then
            return false, "Player not authorized to command this animal"
        end
        
        -- Execute goto command
        local commandSuccess, errorMsg = CommandsSystem.startGoTo(
            animal, args.animalID, args.targetX, args.targetY, args.targetZ, player
        )
        
        if commandSuccess then
            return true, "Goto command executed successfully"
        else
            return false, errorMsg or "Goto command failed"
        end
    end,
    
    stopCommands = function(player, args)
        if not args.animalID then
            return false, "Animal ID required for stop command"
        end
        
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if not animal then
            return false, "Animal not found with ID: " .. tostring(args.animalID)
        end
        
        -- Load CommandsSystem module
        local success, CommandsSystem = pcall(function()
            return require("AnimalsEssentials/CoreSystems/AE_CommandsSystem")
        end)
        
        if not success or not CommandsSystem then
            return false, "CommandsSystem not available"
        end
        
        -- Validate player authorization
        if not CommandsSystem.validateAnimalAccess(player, animal) then
            return false, "Player not authorized to command this animal"
        end
        
        -- Execute stop commands
        CommandsSystem.StopAllCommands(args.animalID)
        return true, "All commands stopped successfully"
    end,
    
    queryStatus = function(player, args)
        if not args.animalID then
            return false, "Animal ID required for status query"
        end
        
        -- Load CommandsSystem module
        local success, CommandsSystem = pcall(function()
            return require("AnimalsEssentials/CoreSystems/AE_CommandsSystem")
        end)
        
        if not success or not CommandsSystem then
            return false, "CommandsSystem not available"
        end
        
        local hasManualCommand = CommandsSystem.HasManualCommand(args.animalID)
        local currentCommand = CommandsSystem.GetCurrentCommand(args.animalID)
        
        -- Send status back to client
        sendClientCommand(player, "AE_CommandsSystem", "statusResult", {
            animalID = args.animalID,
            hasManualCommand = hasManualCommand,
            currentCommand = currentCommand,
            timestamp = getTimestamp()
        })
        
        return true, "Status query completed"
    end
}

-- Commands.AE_AnimalCommand routing for client-server command transmission compatibility
Commands.AE_AnimalCommand = {
    follow = function(player, args)
        return Commands.AE_CommandsSystem.followCommand(player, args)
    end,
    
    stay = function(player, args)
        return Commands.AE_CommandsSystem.stayCommand(player, args)
    end,
    
    goTo = function(player, args)
        return Commands.AE_CommandsSystem.goToCommand(player, args)
    end,
    
    forage = function(player, args)
        -- Bridge forage/hunt command to existing behavior systems
        if not args.animalID then
            return false, "Animal ID required for forage command"
        end
        
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if not animal then
            return false, "Animal not found with ID: " .. tostring(args.animalID)
        end
        
        -- Load CommandsSystem for authorization
        local success, CommandsSystem = pcall(function()
            return require("AnimalsEssentials/CoreSystems/AE_CommandsSystem")
        end)
        
        if not success or not CommandsSystem then
            return false, "CommandsSystem not available"
        end
        
        -- Validate player authorization
        if not CommandsSystem.validateAnimalAccess(player, animal) then
            return false, "Player not authorized to command this animal"
        end
        
        -- Start hunting behavior via BehaviorManager
        local behaviorSuccess, behaviorResult = pcall(function()
            local BehaviorManager = require("AnimalsEssentials/BehaviorSystems/AE_BehaviorManager")
            if BehaviorManager and BehaviorManager.StartHuntingBehavior then
                return BehaviorManager.StartHuntingBehavior(animal, args.animalID)
            else
                return false
            end
        end)
        
        if behaviorSuccess and behaviorResult then
            return true, "Foraging/hunting behavior started successfully"
        else
            return false, "Failed to start foraging/hunting behavior"
        end
    end
}

--- Combat protection commands for damage mitigation
Commands.AE_Protection = {
    mitigateDamage = function(player, args)
        local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
        if not animal then
            return false, "Animal not found"
        end
        
        -- Load required modules
        local AnimalRegistry = require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
        local Config = require("AnimalsEssentials/ForModders/AE_MasterConfig")
        
        -- Verify animal is a framework cat
        local animalCategory = AnimalRegistry.GetAnimalType(animal)
        if animalCategory ~= "cat" then
            return false, "Protection only applies to cats"
        end
        
        -- Check if combat protection is enabled
        if not Config.IsSystemEnabled("CombatProtection") then
            return false, "Combat protection disabled"
        end
        
        -- Get protection configuration
        local protectionConfig = Config.GetCombatProtectionConfig("cat")
        if not protectionConfig or not protectionConfig.CompleteInvulnerability then
            return false, "Complete invulnerability not enabled"
        end
        
        -- Apply damage mitigation by restoring health
        local currentHealth = animal:getHealth()
        local newHealth = currentHealth + args.damage
        animal:setHealth(newHealth)
        
        -- Sync to clients
        animal:transmitModData()
        
        return true, "Damage mitigated"
    end
}


-- PHASE 2A: CommandsSystem command validation
function AE_ServerDataHandler.validateCommandsSystemCommand(player, command, animalID, data)
    if not player or not command or not animalID then
        print("[AE_ServerDataHandler] ERROR: Invalid CommandsSystem command parameters")
        return false, "Invalid parameters"
    end
    
    -- Validate CommandsSystem command types
    local validCommands = {
        "followCommand",
        "stayCommand",
        "goToCommand",
        "stopCommands",
        "queryStatus"
    }
    
    local isValidCommand = false
    for _, validCommand in ipairs(validCommands) do
        if command == validCommand then
            isValidCommand = true
            break
        end
    end
    
    if not isValidCommand then
        print("[AE_ServerDataHandler] ERROR: Unknown CommandsSystem command " .. command)
        return false, "Unknown CommandsSystem command"
    end
    
    -- Validate player authorization (basic check)
    if not AE_ServerDataHandler.isPlayerAuthorized(player, animalID, command) then
        print("[AE_ServerDataHandler] WARNING: Player " .. player:getUsername() .. " not authorized for CommandsSystem command " .. command)
        return false, "Not authorized"
    end
    
    -- Validate command-specific parameters
    if command == "goToCommand" then
        if not data or not data.targetX or not data.targetY or not data.targetZ then
            return false, "GoTo command requires target coordinates"
        end
    end
    
    return true, "Valid"
end

-- Command validation and authorization (Data service commands)
function AE_ServerDataHandler.validateDataCommand(player, command, animalID, data)
    if not player or not command or not animalID then
        print("[AE_ServerDataHandler] ERROR: Invalid command parameters")
        return false, "Invalid parameters"
    end
    
    -- Validate player authorization
    if not AE_ServerDataHandler.isPlayerAuthorized(player, animalID, command) then
        print("[AE_ServerDataHandler] WARNING: Player " .. player:getUsername() .. " not authorized for command " .. command)
        return false, "Not authorized"
    end
    
    -- Validate command type
    local validCommands = {
        "setTameness",
        "setHunger", 
        "setThirst",
        "setHealth",
        "setTamed",
        "setOwner",
        "setBreed",
        "updateStatus"
    }
    
    local isValidCommand = false
    for _, validCommand in ipairs(validCommands) do
        if command == validCommand then
            isValidCommand = true
            break
        end
    end
    
    if not isValidCommand then
        print("[AE_ServerDataHandler] ERROR: Unknown command " .. command)
        return false, "Unknown command"
    end
    
    -- Validate data structure
    if data then
        local isValid, errorMsg = AE_ServerDataHandler.validateDataStructure(data)
        if not isValid then
            return false, errorMsg
        end
    end
    
    return true, "Valid"
end

-- Player authorization checking
function AE_ServerDataHandler.isPlayerAuthorized(player, animalID, operation)
    if not player then return false end
    
    -- Find the animal
    local animal = AE_ServerDataHandler.getAnimalByID(animalID)
    if not animal then
        print("[AE_ServerDataHandler] WARNING: Animal " .. animalID .. " not found")
        return false
    end
    
    -- Check if player is the owner
    local ownerID = AE_DataService.getOwner(animal)
    if ownerID and ownerID == player:getUsername() then
        return true
    end
    
    -- Check if animal is tamed to this player
    if AE_DataService.isTamed(animal) and ownerID == player:getUsername() then
        return true
    end
    
    -- Check if animal is within interaction distance
    local distance = player:DistTo(animal)
    if distance > 10 then -- 10 tile interaction range
        print("[AE_ServerDataHandler] WARNING: Player too far from animal (" .. distance .. " tiles)")
        return false
    end
    
    -- For untamed animals, allow basic operations
    if not AE_DataService.isTamed(animal) then
        local allowedOps = {"setTameness", "updateStatus"}
        for _, allowedOp in ipairs(allowedOps) do
            if operation == allowedOp then
                return true
            end
        end
    end
    
    return false
end

-- Data structure validation
function AE_ServerDataHandler.validateDataStructure(data)
    if type(data) ~= "table" then
        return false, "Data must be a table"
    end
    
    for key, value in pairs(data) do
        local rule = validationRules[key]
        if rule then
            -- Type validation
            if rule.type and type(value) ~= rule.type then
                return false, "Invalid type for " .. key .. " (expected " .. rule.type .. ")"
            end
            
            -- Range validation for numbers
            if rule.type == "number" then
                if rule.min and value < rule.min then
                    return false, key .. " below minimum (" .. rule.min .. ")"
                end
                if rule.max and value > rule.max then
                    return false, key .. " above maximum (" .. rule.max .. ")"
                end
            end
            
            -- Length validation for strings
            if rule.type == "string" and rule.maxLength then
                if string.len(value) > rule.maxLength then
                    return false, key .. " exceeds maximum length (" .. rule.maxLength .. ")"
                end
            end
        end
    end
    
    return true, "Valid"
end

-- Get animal by ID with validation
function AE_ServerDataHandler.getAnimalByID(animalID)
    if not animalID then return nil end
    
    -- Search through all animals in the world
    local cell = getWorld():getCell()
    if not cell then return nil end
    
    for i = 0, cell:getObjectList():size() - 1 do
        local obj = cell:getObjectList():get(i)
        local success, isValidAnimal = pcall(function()
            -- Multi-layer defensive validation
            if not obj then return false end
            if not AE_DataService then return false end
            if not AE_DataService.isAnimalValid then return false end
            
            return AE_DataService.isAnimalValid(obj)
        end)
        
        if success and isValidAnimal then
            if obj:getID() == animalID then
                return obj
            end
        end
    end
    
    return nil
end

-- Server command processing with Commands table routing
function AE_ServerDataHandler.onServerCommand(module, command, player, args)
    print("[TAMING DEBUG] Server received command - module: " .. tostring(module) .. ", command: " .. tostring(command))
    if not player or not command or not args then
        print("[AE_ServerDataHandler] ERROR: Invalid server command")
        return
    end
    
    -- Route command using Commands table
    print("[TAMING DEBUG] Checking Commands[" .. tostring(module) .. "][" .. tostring(command) .. "]")
    if Commands[module] and Commands[module][command] then
        print("[TAMING DEBUG] Command handler found, executing")
        local success, result = Commands[module][command](player, args)
        print("[TAMING DEBUG] Command execution result: " .. tostring(success))
        
        -- Handle data service commands with additional processing
        if module == "AE_DataService" and args.animalID then
            local animal = AE_ServerDataHandler.getAnimalByID(args.animalID)
            if animal and success then
                -- B42.13.1 Server Authority Pattern (per user guidance)
                local transmitSuccess, transmitError = pcall(function()
                    animal:transmitModData()
                end)
                if not transmitSuccess then
                    print("[AE_ServerDataHandler] WARNING: transmitModData failed for animal " .. args.animalID .. ": " .. tostring(transmitError))
                end
                
                -- Fire server-side event
                if AE_EventRegistry then
                    AE_EventRegistry.safeFireEvent("OnAE_StateUpdated", {
                        animalID = args.animalID,
                        command = command,
                        player = player:getUsername(),
                        timestamp = GameTime.getServerTimeMills()
                    })
                end
            end
        end
        
        print("[AE_ServerDataHandler] Command " .. module .. "." .. command .. ": " .. tostring(result))
    else
        print("[TAMING DEBUG] ERROR: Command not found - Commands[" .. tostring(module) .. "][" .. tostring(command) .. "]")
        print("[AE_ServerDataHandler] ERROR: Unknown module/command: " .. tostring(module) .. "." .. tostring(command))
    end
end

-- Data synchronization for new players
function AE_ServerDataHandler.onPlayerConnect(player)
    if not player then return end
    
    print("[AE_ServerDataHandler] Player connected: " .. player:getUsername())
    
    -- Send data service configuration to client
    sendClientCommand(player, "AE_DataService", "configSync", {
        validationRules = validationRules,
        serverTime = GameTime.getServerTimeMills()
    })
end

-- Periodic data integrity checking
function AE_ServerDataHandler.performDataIntegrityCheck()
    local checkedCount = 0
    local issuesFound = 0
    
    -- Check all animals in the world
    local cell = getWorld():getCell()
    if not cell then return end
    
    for i = 0, cell:getObjectList():size() - 1 do
        local obj = cell:getObjectList():get(i)
        local success, isValidAnimal = pcall(function()
            -- Multi-layer defensive validation
            if not obj then return false end
            if not AE_DataService then return false end
            if not AE_DataService.isAnimalValid then return false end
            
            return AE_DataService.isAnimalValid(obj)
        end)
        
        if success and isValidAnimal then
            checkedCount = checkedCount + 1
            
            local integritySuccess, isValid, issues = pcall(function()
                return AE_ModDataManager.validateModDataIntegrity(obj)
            end)
            
            if integritySuccess and not isValid then
                issuesFound = issuesFound + (issues and #issues or 0)
                local animalIDSuccess, animalID = pcall(function() return obj:getID() end)
                local displayID = animalIDSuccess and animalID or "unknown"
                print("[AE_ServerDataHandler] Data integrity issues for animal " .. displayID .. ":")
                if issues then
                    for _, issue in ipairs(issues) do
                        print("  - " .. issue)
                    end
                end
            end
        end
    end
    
    if checkedCount > 0 then
        print("[AE_ServerDataHandler] Data integrity check complete: " .. checkedCount .. " animals checked, " .. issuesFound .. " issues found")
    end
    
    -- Fire integrity check event
    if AE_EventRegistry then
        AE_EventRegistry.safeFireEvent("OnAE_DataIntegrityCheck", {
            animalsChecked = checkedCount,
            issuesFound = issuesFound,
            timestamp = GameTime.getServerTimeMills()
        })
    end
end

-- Emergency data recovery
function AE_ServerDataHandler.emergencyDataRecovery(animalID)
    local animal = AE_ServerDataHandler.getAnimalByID(animalID)
    if not animal then
        print("[AE_ServerDataHandler] Cannot recover: Animal " .. animalID .. " not found")
        return false
    end
    
    -- Create emergency backup
    local backup = AE_ModDataManager.createModDataBackup(animal)
    if not backup then
        print("[AE_ServerDataHandler] Cannot create backup for animal " .. animalID)
        return false
    end
    
    -- Reset to safe defaults
    local defaultData = {
        tameness = 0,
        hunger = 100,
        thirst = 100,
        health = 100,
        isTamed = false
    }
    
    local success = true
    for key, value in pairs(defaultData) do
        if key == "tameness" then
            success = AE_DataService.setTameness(animal, value) and success
        elseif key == "hunger" then
            success = AE_DataService.setHunger(animal, value) and success
        elseif key == "thirst" then
            success = AE_DataService.setThirst(animal, value) and success
        elseif key == "health" then
            success = AE_DataService.setHealth(animal, value) and success
        elseif key == "isTamed" then
            success = AE_DataService.setTamed(animal, value) and success
        end
    end
    
    if success then
        print("[AE_ServerDataHandler] Emergency recovery successful for animal " .. animalID)
    else
        print("[AE_ServerDataHandler] Emergency recovery failed for animal " .. animalID)
    end
    
    return success
end

-- Initialize server data handler
function AE_ServerDataHandler.initialize()
    -- Register server command handler (always safe)
    Events.OnClientCommand.Add(AE_ServerDataHandler.onServerCommand)
    
    -- Environment-aware event registration
    local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
    
    -- MP-only events with defensive null checks
    if AE_EnvironmentDetector.isMultiplayer() then
        if Events.OnPlayerConnect then
            Events.OnPlayerConnect.Add(AE_ServerDataHandler.onPlayerConnect)
        end
    end
    
    -- SP/MP compatible events with defensive null checks
    if Events.EveryHours then
        Events.EveryHours.Add(AE_ServerDataHandler.performDataIntegrityCheck)
    end
    
    -- Fire initialization event with defensive pattern
    if AE_EventRegistry and AE_EventRegistry.safeFireEvent then
        AE_EventRegistry.safeFireEvent("OnAE_SystemInitialized", {
            module = "AE_ServerDataHandler",
            serverSide = AE_EnvironmentDetector.isMultiplayer(),
            validationRules = AE_ServerDataHandler.getValidationRuleCount(),
            timestamp = GameTime and GameTime.getServerTimeMills and GameTime.getServerTimeMills() or 0
        })
    end
    
    print("[AE_ServerDataHandler] Server-side data handler initialized in " .. 
          (AE_EnvironmentDetector.isSinglePlayer() and "SP" or "MP") .. " mode")
    return true
end

-- Get validation rule count for monitoring
function AE_ServerDataHandler.getValidationRuleCount()
    local count = 0
    for _ in pairs(validationRules) do
        count = count + 1
    end
    return count
end

-- Export for global access
_G.AE_ServerDataHandler = AE_ServerDataHandler