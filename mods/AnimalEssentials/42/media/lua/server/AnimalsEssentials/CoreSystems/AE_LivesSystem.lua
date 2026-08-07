local AE_LivesSystem = {}

-- ============================================================================
-- FRAMEWORK INTEGRATION - CAT-ONLY FILTERING
-- ============================================================================

local Config = nil
local ConfigLoadAttempted = false
local AnimalRegistry = nil
local AE_DataConfig = nil
local FALLBACK_RESPAWN_DELAY = 300

local function loadFrameworkDependencies()
    if not ConfigLoadAttempted then
        ConfigLoadAttempted = true
        local success, config = pcall(require, "AnimalsEssentials/ForModders/AE_MasterConfig")
        if success and config then
            Config = config
        end
    end
    
    if not AnimalRegistry then
        local success, result = pcall(function()
            return require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
        end)
        if success and result then
            AnimalRegistry = result
        end
    end
    
    if not AE_DataConfig then
        local success, result = pcall(function()
            return require("AnimalsEssentials/Config/AE_DataConfig")
        end)
        if success and result then
            AE_DataConfig = result
        end
    end
    
    return Config
end

local function getModDataKey()
    loadFrameworkDependencies()
    if AE_DataConfig and AE_DataConfig.ModDataKeys then
        return AE_DataConfig.ModDataKeys.RemainingLives
    end
    return "AE_DATA_RemainingLives"
end

local function getRespawnDelayTicks()
    local config = loadFrameworkDependencies()
    if config and config.Lives and config.Lives.RespawnDelayTicks then
        return config.Lives.RespawnDelayTicks
    end
    return FALLBACK_RESPAWN_DELAY
end

local function isSystemEnabled()
    local config = loadFrameworkDependencies()
    if config and config.IsSystemEnabled then
        return config.IsSystemEnabled("LivesSystem")
    end
    return true
end

local function getLivesConfig(animalCategory)
    local config = loadFrameworkDependencies()
    if config and config.GetLivesConfig then
        return config.GetLivesConfig(animalCategory)
    end
    return nil
end

local function getRegisteredCategories()
    local config = loadFrameworkDependencies()
    if config and config.GetRegisteredCategories then
        return config.GetRegisteredCategories()
    end
    return {}
end

local function getStableIDKey()
    loadFrameworkDependencies()
    if AE_DataConfig and AE_DataConfig.ModDataKeys then
        return AE_DataConfig.ModDataKeys.StableID
    end
    return "AE_DATA_StableID"
end

local function getGlobalTamingDataKey()
    loadFrameworkDependencies()
    if AE_DataConfig and AE_DataConfig.GlobalModDataKeys then
        return AE_DataConfig.GlobalModDataKeys.TamingData
    end
    return "AE_DATA_TamingData"
end

local function getGlobalLivesDataKey()
    loadFrameworkDependencies()
    if AE_DataConfig and AE_DataConfig.GlobalModDataKeys then
        return AE_DataConfig.GlobalModDataKeys.LivesData
    end
    return "AE_DATA_LivesData"
end

local function getHasBagKey()
    loadFrameworkDependencies()
    if AE_DataConfig and AE_DataConfig.ModDataKeys then
        return AE_DataConfig.ModDataKeys.HasBag
    end
    return "AE_CORE_HasBag"
end

local function getMaxTamedSlots()
    local config = loadFrameworkDependencies()
    if config and config.Taming and config.Taming.MaxTamedSlots then
        return config.Taming.MaxTamedSlots
    end
    return 10
end

-- ============================================================================
-- PICKUPDETECTOR PATTERN: DIRECT ANIMAL ACCESS (No AnimalRegistry Dependencies)
-- ============================================================================

local function getAnimalID(animal)
    if not animal then return nil end
    
    local animalID = tostring(animal:getOnlineID())
    if animalID == "0" then
        animalID = "temp_" .. tostring(animal:hashCode())
    end
    
    return animalID
end

local function getAnimalModData(animal)
    if not animal then return nil end
    
    local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")
    return AE_DataService.getAllModData(animal)
end

local function isValidAnimal(animal)
    if not animal then return false end
    
    loadFrameworkDependencies()
    if AnimalRegistry and AnimalRegistry.IsFrameworkAnimal then
        return AnimalRegistry.IsFrameworkAnimal(animal)
    end
    
    return false
end

local function extractEssentialSpawnData(character)
    local animalType = character:getAnimalType()
    if not animalType then return nil end
    
    local deathSquare = character:getSquare() or character:getCurrentSquare()
    local x, y, z
    if deathSquare then
        x, y, z = deathSquare:getX(), deathSquare:getY(), deathSquare:getZ()
    else
        x, y, z = character:getX(), character:getY(), character:getZ()
    end
    
    return {
        animalType = animalType,
        x = x, y = y, z = z,
        originalCharacter = character
    }
end

-- ============================================================================
-- ENVIRONMENT-AWARE UNIFIED AUTHORITY PATTERN
-- ============================================================================

local function executeWithEnvironmentAwareness(operation, serverLogic, clientLogic, singleplayerLogic)
    -- SERVER file: Always execute server logic since this file only runs on server
    return serverLogic()
end

local function transmitModDataSafely(animal, context)
    if not animal then return end
    
    -- SERVER file: Always transmit since this file only runs on server
    animal:transmitModData()
end

local function transmitGlobalModDataSafely(key, context)
    if not key then return end
    
    -- SERVER file: Always transmit since this file only runs on server
    ModData.transmit(key)
end

local SandboxSettings = nil
local function getSandboxSettings()
    if not SandboxSettings then
        local success, result = pcall(function()
            return require("AnimalsEssentials/Config/AE_SandboxSettings")
        end)
        if success and result then
            SandboxSettings = result
        else
            SandboxSettings = {
                GetMaxLives = function() return 9999 end,
                GetHealthMultiplier = function() return 1.0 end
            }
        end
    end
    if not SandboxSettings then
        SandboxSettings = {
            GetMaxLives = function() return 9999 end,
            GetHealthMultiplier = function() return 1.0 end
        }
    end
    return SandboxSettings
end
local TamingSystem = nil
local tamingSuccess, tamingResult = pcall(function()
    return require("AnimalsEssentials/Taming/AE_TamingSystem")
end)
if tamingSuccess and tamingResult then
    TamingSystem = tamingResult
end
local EquipmentSystem = nil
local equipSuccess, equipResult = pcall(function()
    return require("AnimalsEssentials/CoreSystems/InventoryStuffs/AE_EquipmentSystem")
end)
local InventorySystem = nil
local invSuccess, invResult = pcall(function()
    return require("AnimalsEssentials/CoreSystems/InventoryStuffs/AE_InventorySystem")
end)
if invSuccess and invResult then
    InventorySystem = invResult
else
end

local pendingRespawns = {}
local tickHandlerActive = false

AE_LivesSystem.MODDATA_KEY = "AE_DATA_RemainingLives"
function AE_LivesSystem.getMaxLives(animal)
    local sandboxSettings = getSandboxSettings()
    if not sandboxSettings then
        return 9999
    end
    if not sandboxSettings.GetMaxLives then
        return 9999
    end
    local sandboxMaxLives = sandboxSettings.GetMaxLives()
    if sandboxMaxLives and sandboxMaxLives ~= 9 then
        return sandboxMaxLives
    end
    if animal then
        local animalCategory = animal:getAnimalType()
        if animalCategory then
            local livesConfig = getLivesConfig(animalCategory)
            if livesConfig and livesConfig.MaxLives then
                return livesConfig.MaxLives
            end
        end
    end
    local categories = getRegisteredCategories()
    if #categories > 0 then
        local fallbackConfig = getLivesConfig(categories[1])
        if fallbackConfig and fallbackConfig.MaxLives then
            return fallbackConfig.MaxLives
        end
    end
    return 9999
end
function AE_LivesSystem.getLives(animal)
    if not isValidAnimal(animal) then
        return nil
    end
    local modData = getAnimalModData(animal)
    if not modData then
        return nil
    end
    local animalID = modData[getStableIDKey()]
    if animalID and animalID ~= "" and animalID ~= "unnamed" then
        local lives = AE_LivesSystem.getLivesByID(animalID)
        modData[AE_LivesSystem.MODDATA_KEY] = lives
        animal:transmitModData()
        return lives
    end
    if modData[AE_LivesSystem.MODDATA_KEY] == nil then
        modData[AE_LivesSystem.MODDATA_KEY] = AE_LivesSystem.getMaxLives(animal)
        animal:transmitModData()
    end
    return modData[AE_LivesSystem.MODDATA_KEY]
end
function AE_LivesSystem.setLives(animal, lives)
    if not isValidAnimal(animal) then
        return false
    end
    if type(lives) ~= "number" then
        return false
    end
    local modData = getAnimalModData(animal)
    if not modData then
        return false
    end
    local maxLives = AE_LivesSystem.getMaxLives(animal)
    local clampedLives = math.max(0, math.min(maxLives, lives))
    modData[AE_LivesSystem.MODDATA_KEY] = clampedLives
    animal:transmitModData()
    local animalID = modData[getStableIDKey()]
    if animalID and animalID ~= "" and animalID ~= "unnamed" then
        AE_LivesSystem.setLivesByID(animalID, clampedLives)
    end
    return true
end
function AE_LivesSystem.consumeLifeByID(animalID)
    local currentLives = AE_LivesSystem.getLivesByID(animalID)
    if not currentLives then return nil end
    local newLives = math.max(0, currentLives - 1)
    local success = AE_LivesSystem.setLivesByID(animalID, newLives)
    if not success then return nil end
    if newLives <= 0 then
        local cacheSuccess, CacheSystem = pcall(function()
            return require("AnimalsEssentials/CoreSystems/AE_AnimalCacheSystem")
        end)
        if cacheSuccess and CacheSystem then
            local globalTamingData = ModData.get(getGlobalTamingDataKey())
            if globalTamingData and globalTamingData.players then
                for playerNum, playerData in pairs(globalTamingData.players) do
                    for _, slotAnimalID in pairs(playerData) do
                        if slotAnimalID == animalID then
                            local player = getSpecificPlayer(playerNum)
                            if player then
                                CacheSystem.CleanupDeadAnimal(player, animalID)
                            end
                            break
                        end
                    end
                end
            end
        end
    end
    return newLives
end
function AE_LivesSystem.getLivesByID(animalID)
    if not animalID or animalID == "" or animalID == "unnamed" then
        return nil
    end
    local globalData = ModData.getOrCreate(getGlobalLivesDataKey())
    if not globalData.lives then
        globalData.lives = {}
    end
    if globalData.lives[animalID] == nil then
        globalData.lives[animalID] = AE_LivesSystem.getMaxLives(nil)
        ModData.transmit(getGlobalLivesDataKey())
    end
    return globalData.lives[animalID]
end
function AE_LivesSystem.setLivesByID(animalID, lives)
    if not animalID or animalID == "" or animalID == "unnamed" then
        return false
    end
    if type(lives) ~= "number" then
        return false
    end
    local globalData = ModData.getOrCreate(getGlobalLivesDataKey())
    if not globalData.lives then
        globalData.lives = {}
    end
    local maxLives = AE_LivesSystem.getMaxLives(nil)
    local clampedLives = math.max(0, math.min(maxLives, lives))
    globalData.lives[animalID] = clampedLives
    ModData.transmit(getGlobalLivesDataKey())
    return true
end
local function onCharacterDeath(character)
    if not isSystemEnabled() then return end
    if not character then return end

    local success, isAnimal = pcall(function()
        return character:isAnimal()
    end)
    if not success or not isAnimal then
        return
    end

    if not isValidAnimal(character) then return end
    
    local spawnData = extractEssentialSpawnData(character)
    if not spawnData then return end
    
    table.insert(pendingRespawns, {
        animalType = spawnData.animalType,
        x = spawnData.x,
        y = spawnData.y,
        z = spawnData.z,
        originalCharacter = spawnData.originalCharacter,
        tickCount = 0,
        dataRestored = false
    })
    
    if character.removeFromWorld then
        character:removeFromWorld()
    end
    if character.removeFromSquare then
        character:removeFromSquare()
    end
end
local function getGuaranteedBreed(animalDef)
    if not animalDef then return nil end
    
    local breed = animalDef:getBreedByName("shorthair")
    if not breed then
        local breeds = animalDef:getBreeds()
        if breeds and breeds:size() > 0 then
            breed = breeds:get(0)
        end
    end
    return breed
end

local function attemptDataRestoration(newAnimal, originalCharacter)
    if not originalCharacter then return end
    
    local originalModData = getAnimalModData(originalCharacter)
    if originalModData then
        local newModData = getAnimalModData(newAnimal)
        if newModData then
            for key, value in pairs(originalModData) do
                newModData[key] = value
            end
            pcall(function() newAnimal:transmitModData() end)
        end
    end
end

local function ensureMinimumViableData(newAnimal)
    local modData = getAnimalModData(newAnimal)
    if not modData then return end
    
    local stableIDKey = getStableIDKey()
    if not modData[stableIDKey] or modData[stableIDKey] == "" then
        modData[stableIDKey] = "RESPAWN_" .. tostring(newAnimal:hashCode())
    end
    
    local livesKey = getModDataKey()
    if not modData[livesKey] then
        modData[livesKey] = AE_LivesSystem.getMaxLives(newAnimal)
    end
    
    pcall(function() newAnimal:transmitModData() end)
end

local function performSpawnWithRestoration(respawnData)
    local animalDef = AnimalDefinitions.getDef(respawnData.animalType)
    if not animalDef then return false end
    
    local breed = getGuaranteedBreed(animalDef)
    if not breed then return false end
    
    local cell = getCell()
    if not cell then return false end
    
    local newAnimal = addAnimal(cell, respawnData.x, respawnData.y, respawnData.z, respawnData.animalType, breed)
    if not newAnimal then return false end
    
    attemptDataRestoration(newAnimal, respawnData.originalCharacter)
    ensureMinimumViableData(newAnimal)
    
    if newAnimal.addToWorld then
        newAnimal:addToWorld()
    end
    if newAnimal.setHealth then
        newAnimal:setHealth(100)
    end
    
    return true
end

local function onTick()
    if #pendingRespawns == 0 then return end
    for i = #pendingRespawns, 1, -1 do
        local respawnData = pendingRespawns[i]
        respawnData.tickCount = respawnData.tickCount + 1
        if respawnData.tickCount >= getRespawnDelayTicks() then
            if performSpawnWithRestoration(respawnData) then
                table.remove(pendingRespawns, i)
            else
                table.remove(pendingRespawns, i)
            end
        end
    end
end
local function onCorpseCreated(corpse)
    if not isSystemEnabled() then return end
    if not corpse then return end

    local success, isAnimal = pcall(function()
        return corpse:isAnimal()
    end)
    if not success or not isAnimal then
        return
    end

    if not isValidAnimal(corpse) then return end
    
    local characterID = nil
    local modData = getAnimalModData(corpse)
    if modData then
        characterID = modData[getStableIDKey()]
    end
    
    if not characterID then
        characterID = "TEMP_" .. tostring(corpse:hashCode())
    end
    
    for _, respawnData in ipairs(pendingRespawns) do
        local respawnID = nil
        if respawnData.originalCharacter then
            local originalModData = getAnimalModData(respawnData.originalCharacter)
            if originalModData then
                respawnID = originalModData[getStableIDKey()]
            end
            if not respawnID then
                respawnID = "TEMP_" .. tostring(respawnData.originalCharacter:hashCode())
            end
        end
        
        if respawnID == characterID then
            if corpse.removeFromWorld then
                corpse:removeFromWorld()
            end
            if corpse.removeFromSquare then
                corpse:removeFromSquare()
            end
            return
        end
    end
end
local function initialize()
    if not isSystemEnabled() then
        return
    end
    Events.OnCharacterDeath.Add(onCharacterDeath)
    Events.OnTick.Add(onTick)
    if Events.OnCreateLivingCharacter then
        Events.OnCreateLivingCharacter.Add(function(character)
            if character and character:isDead() then
                onCorpseCreated(character)
            end
        end)
    end
end
Events.OnGameStart.Add(initialize)
return AE_LivesSystem