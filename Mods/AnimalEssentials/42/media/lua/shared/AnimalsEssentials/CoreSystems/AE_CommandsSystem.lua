-- AE_CommandsSystem.lua
-- PHASE 1A: Core CommandsSystem Module with Defensive Architecture
-- Implements animal command processing with server authority and event-driven patterns

local AE_CommandsSystem = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

-- ============================================================================
-- ENVIRONMENT-AWARE UNIFIED AUTHORITY PATTERN
-- ============================================================================
-- Server-side system that needs singleplayer access compatibility

local function executeWithEnvironmentAwareness(operation, serverLogic, clientLogic, singleplayerLogic)
    if AE_EnvironmentDetector.isSinglePlayer() then
        return (singleplayerLogic and singleplayerLogic()) or serverLogic()
    else
        if not isClient() then
            -- Multiplayer server authority
            return serverLogic()
        else
            -- Multiplayer client behavior  
            return clientLogic and clientLogic() or nil
        end
    end
end

-- Command behavior constants
AE_CommandsSystem.FOLLOW_MIN_DISTANCE = 2.0
AE_CommandsSystem.FOLLOW_MAX_DISTANCE = 8.0
AE_CommandsSystem.PATHFIND_TIMEOUT = 30          -- seconds
AE_CommandsSystem.FOLLOW_COOLDOWN = 5            -- seconds  
AE_CommandsSystem.FOLLOW_MIN_INTERVAL = 1        -- seconds
AE_CommandsSystem.FOLLOW_MAX_INTERVAL = 3        -- seconds
AE_CommandsSystem.STAY_MIN_DURATION = 10         -- seconds
AE_CommandsSystem.STAY_MAX_DURATION = 30         -- seconds
AE_CommandsSystem.GOTO_MIN_DELAY = 0.5           -- seconds
AE_CommandsSystem.GOTO_MAX_DELAY = 2             -- seconds
AE_CommandsSystem.STAY_HUNGER_BREAK = 0.3        -- 30%
AE_CommandsSystem.STAY_THIRST_BREAK = 0.3        -- 30%
AE_CommandsSystem.GOTO_COOLDOWN = 3              -- seconds

-- ============================================================================
-- DEFENSIVE DEPENDENCY LOADING
-- ============================================================================

-- Core dependencies with defensive loading
local Config = nil
local AnimalRegistry = nil
local TamingSystem = nil
local FriendlinessSystem = nil

-- Load Config with defensive pattern
local function loadConfig()
    if Config then return Config end
    
    local success, result = pcall(function()
        return require("AnimalsEssentials/ForModders/AE_MasterConfig")
    end)
    
    if success and result then
        Config = result
        return Config
    else
        print("[AE_CommandsSystem] WARNING: Could not load AE_MasterConfig - using defaults")
        return nil
    end
end

-- Load AnimalRegistry with defensive pattern
local function loadAnimalRegistry()
    if AnimalRegistry then return AnimalRegistry end
    
    local success, result = pcall(function()
        return require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
    end)
    
    if success and result then
        AnimalRegistry = result
        return AnimalRegistry
    else
        print("[AE_CommandsSystem] ERROR: Could not load AE_AnimalRegistry - command system disabled")
        return nil
    end
end

-- Load TamingSystem with defensive pattern
local function loadTamingSystem()
    if TamingSystem then return TamingSystem end
    
    local success, result = pcall(function()
        return require("AnimalsEssentials/Taming/AE_TamingSystem")
    end)
    
    if success and result then
        TamingSystem = result
        return TamingSystem
    else
        print("[AE_CommandsSystem] WARNING: Could not load AE_TamingSystem - using fallback patterns")
        return nil
    end
end

-- Load FriendlinessSystem with defensive pattern
local function loadFriendlinessSystem()
    if FriendlinessSystem then return FriendlinessSystem end
    
    local success, result = pcall(function()
        return require("AnimalsEssentials/CoreSystems/AE_FriendlinessSystem")
    end)
    
    if success and result then
        FriendlinessSystem = result
        return FriendlinessSystem
    else
        print("[AE_CommandsSystem] WARNING: Could not load AE_FriendlinessSystem - using fallback patterns")
        return nil
    end
end

-- Defensive PlayerID manager (replaces missing AE_PlayerIDManager)
local function getPlayerID(player)
    if not player then return nil end
    
    -- Use established AEAPI patterns for player identification
    local success, playerID = pcall(function()
        return player:getOnlineID() or player:getID() or player:getUsername()
    end)
    
    return success and playerID or nil
end

-- ============================================================================
-- CORE DATA STRUCTURES
-- ============================================================================

AE_CommandsSystem.activeAnimals = {}
AE_CommandsSystem.goToCooldowns = {}
AE_CommandsSystem.followCooldowns = {}

-- Player cache for performance optimization
AE_CommandsSystem.playerCache = {
    lastX = nil,
    lastY = nil,
    lastZ = nil,
    lastUpdateTime = 0,
    velocityX = 0,
    velocityY = 0,
    lastChecksum = nil,
    UPDATE_THRESHOLD = 0.1,
    CACHE_DURATION = 100
}

-- Event-driven processing statistics
AE_CommandsSystem.ProcessingStats = {
    commandsProcessed = 0,
    lastProcessTime = 0,
    totalProcessingTime = 0
}

-- Global time-based command scheduling (MP-compatible)
AE_CommandsSystem.CommandSchedule = {
    nextGlobalUpdate = 0,
    updateInterval = 2.0, -- seconds - conservative interval for MP compatibility
    activePlayerCommands = {}, -- playerID -> {lastUpdateTime, needsProcessing}
    activePlayerAnimals = {}, -- PPPP-AAAA optimization: playerID -> {animalIDs}
    initialized = false,
    -- MP scalability protection
    maxPlayersPerCycle = 15, -- Rate limit: process max 15 players per cycle
    maxAnimalsPerPlayer = 6, -- Rate limit: process max 6 animals per player
    processingStats = {
        lastCycleTime = 0,
        playersProcessed = 0,
        animalsProcessed = 0,
        cyclesThrottled = 0
    }
}

-- Command priority enumeration for BehaviorManager integration
AE_CommandsSystem.CommandPriority = {
    WANDERLUST = 1,           -- Automatic wandering
    RETURN_HOME_PASSIVE = 2,  -- Automatic return home
    GOTO = 3,                 -- Manual go-to command
    FOLLOW = 4,               -- Manual follow command
    RETURN_HOME_MANUAL = 5    -- Manual return home command
}

-- ============================================================================
-- DEFENSIVE VALIDATION FUNCTIONS
-- ============================================================================

-- VALIDATION: Check if player can access/modify animal data  
function AE_CommandsSystem.validateAnimalAccess(player, animal)
    if not player or not animal then return false end
    
    local registry = loadAnimalRegistry()
    if not registry then return false end
    
    local animalModData = registry.GetAnimalModData and registry.GetAnimalModData(animal)
    if not animalModData then return false end
    
    -- Use TamingSystem if available for ownership validation
    local tamingSystem = loadTamingSystem()
    if tamingSystem and tamingSystem.IsOwner then
        local success, isOwner = pcall(function()
            return tamingSystem.IsOwner(animal, player)
        end)
        if success then
            return isOwner
        end
    end
    
    -- Fallback to ModData ownership check using established patterns
    local ownerID = animalModData.AE_OwnerPlayerID
    if ownerID then
        local playerID = getPlayerID(player)
        return ownerID == playerID
    end
    
    -- Default to allow access if no ownership system available
    return true
end

-- Get animal data with defensive pattern
local function getAnimalData(animalID)
    if not animalID then return nil end
    
    return AE_CommandsSystem.activeAnimals[animalID]
end

-- Safe animal data initialization
local function initializeAnimalData(animalID, animal)
    if not animalID or not animal then return nil end
    
    if not AE_CommandsSystem.activeAnimals[animalID] then
        AE_CommandsSystem.activeAnimals[animalID] = {
            currentCommand = nil,
            commandStartTime = 0,
            lastPosition = { x = 0, y = 0, z = 0 },
            followData = { active = false, targetPlayer = nil },
            stayData = { active = false, location = nil },
            goToData = { active = false, target = nil },
            cooldowns = {},
            lastUpdate = 0
        }
    end
    
    return AE_CommandsSystem.activeAnimals[animalID]
end

-- ============================================================================
-- CORE COMMAND FUNCTIONS (REQUIRED BY BEHAVIORMANAGER)
-- ============================================================================

--- Check if animal has an active manual command (overrides passive behaviors)
--- @param animalID - the animal's stable ID (AE_AnimalID format)
--- @return boolean - true if manual command is active
function AE_CommandsSystem.HasManualCommand(animalID)
    if not animalID then return false end
    
    local animalData = getAnimalData(animalID)
    if not animalData or not animalData.currentCommand then
        return false
    end
    
    local cmd = animalData.currentCommand
    return cmd == "follow" or cmd == "goto" or cmd == "returnhome_manual"
end

--- Check if a specific command is active
--- @param animalID - the animal's ID
--- @param commandType - the command type to check
--- @return boolean - true if the specific command is active
function AE_CommandsSystem.IsCommandActive(animalID, commandType)
    if not animalID or not commandType then return false end
    
    local animalData = getAnimalData(animalID)
    if not animalData then return false end
    
    return animalData.currentCommand == commandType
end

--- Get current command for animal
--- @param animalID - the animal's ID
--- @return string|nil - current command type or nil
function AE_CommandsSystem.GetCurrentCommand(animalID)
    if not animalID then return nil end
    
    local animalData = getAnimalData(animalID)
    if not animalData then return nil end
    
    return animalData.currentCommand
end

-- ============================================================================
-- COMMAND EXECUTION FUNCTIONS (REQUIRED BY UI SYSTEMS)
-- ============================================================================

--- Start a goto command for an animal
--- @param animal - the animal object
--- @param animalID - the animal's ID
--- @param targetX - target X coordinate
--- @param targetY - target Y coordinate
--- @param targetZ - target Z coordinate
--- @param player - the player issuing the command
--- @return boolean, string|nil - success status and error message
function AE_CommandsSystem.startGoTo(animal, animalID, targetX, targetY, targetZ, player)
    if not animal or not animalID or not targetX or not targetY or not targetZ then 
        return false, "Invalid parameters for goto command"
    end
    
    if not player or not AE_CommandsSystem.validateAnimalAccess(player, animal) then
        return false, "Player not authorized to command this animal"
    end
    
    -- Check cooldown
    local currentTime = getTimestamp()
    local lastGoTo = AE_CommandsSystem.goToCooldowns[animalID] or 0
    if currentTime - lastGoTo < AE_CommandsSystem.GOTO_COOLDOWN * 1000 then
        return false, "Goto command on cooldown"
    end
    
    -- Initialize animal data and set goto command
    local animalData = initializeAnimalData(animalID, animal)
    if not animalData then
        return false, "Failed to initialize animal command data"
    end
    
    animalData.currentCommand = "goto"
    animalData.commandStartTime = currentTime
    animalData.goToData = {
        active = true,
        target = { x = targetX, y = targetY, z = targetZ },
        player = player
    }
    
    AE_CommandsSystem.goToCooldowns[animalID] = currentTime
    
    return true, nil
end

--- Follow command for an animal
--- @param animal - the animal object
--- @param player - the player to follow
--- @return boolean - success status
function AE_CommandsSystem.FollowCommand(animal, player)
    if not animal or not player then return false end
    
    if not AE_CommandsSystem.validateAnimalAccess(player, animal) then
        print("[AE_CommandsSystem] WARNING: Player access denied for follow command")
        return false
    end
    
    local registry = loadAnimalRegistry()
    if not registry then return false end
    
    local animalModData = registry.GetAnimalModData and registry.GetAnimalModData(animal)
    if not animalModData then return false end
    
    local animalID = animalModData.AE_AnimalID
    if not animalID then return false end
    
    -- Initialize animal data and set follow command
    local animalData = initializeAnimalData(animalID, animal)
    if not animalData then return false end
    
    animalData.currentCommand = "follow"
    animalData.commandStartTime = getTimestamp()
    animalData.followData = {
        active = true,
        targetPlayer = player
    }
    
    return true
end

--- Stay command for an animal
--- @param animal - the animal object
--- @param player - the player issuing the command
--- @return boolean - success status
function AE_CommandsSystem.StayCommand(animal, player)
    if not animal or not player then return false end
    
    if not AE_CommandsSystem.validateAnimalAccess(player, animal) then
        print("[AE_CommandsSystem] WARNING: Player access denied for stay command")
        return false
    end
    
    local registry = loadAnimalRegistry()
    if not registry then return false end
    
    local animalModData = registry.GetAnimalModData and registry.GetAnimalModData(animal)
    if not animalModData then return false end
    
    local animalID = animalModData.AE_AnimalID
    if not animalID then return false end
    
    -- Initialize animal data and set stay command
    local animalData = initializeAnimalData(animalID, animal)
    if not animalData then return false end
    
    animalData.currentCommand = "stay"
    animalData.commandStartTime = getTimestamp()
    animalData.stayData = {
        active = true,
        location = { x = animal:getX(), y = animal:getY(), z = animal:getZ() }
    }
    
    return true
end

--- Stop all commands for an animal
--- @param animalID - the animal's ID
function AE_CommandsSystem.StopAllCommands(animalID)
    if not animalID then return end
    
    local animalData = getAnimalData(animalID)
    if not animalData then return end
    
    animalData.currentCommand = nil
    animalData.commandStartTime = 0
    animalData.followData.active = false
    animalData.stayData.active = false
    animalData.goToData.active = false
end

-- ============================================================================
-- INITIALIZATION AND CLEANUP
-- ============================================================================

-- Initialize CommandsSystem
function AE_CommandsSystem.Initialize()
    if AE_CommandsSystem.CommandSchedule.initialized then return true end
    
    -- Load core dependencies
    if not loadAnimalRegistry() then
        print("[AE_CommandsSystem] ERROR: AnimalRegistry required for operation")
        return false
    end
    
    -- Optional dependencies (loaded but not required)
    loadConfig()
    loadTamingSystem()
    loadFriendlinessSystem()
    
    AE_CommandsSystem.CommandSchedule.initialized = true
    print("[AE_CommandsSystem] Initialized successfully with defensive patterns")
    return true
end

-- Cleanup function
function AE_CommandsSystem.Cleanup()
    AE_CommandsSystem.activeAnimals = {}
    AE_CommandsSystem.goToCooldowns = {}
    AE_CommandsSystem.followCooldowns = {}
    AE_CommandsSystem.CommandSchedule.initialized = false
end

-- ============================================================================
-- MODULE EXPORT AND GLOBAL REGISTRATION
-- ============================================================================

-- Initialize on load if dependencies are available
local initSuccess = pcall(AE_CommandsSystem.Initialize)
if not initSuccess then
    print("[AE_CommandsSystem] WARNING: Initialization failed - module available but not fully functional")
end

-- Global registration for cross-mod access
_G.AE_CommandsSystem = AE_CommandsSystem

return AE_CommandsSystem