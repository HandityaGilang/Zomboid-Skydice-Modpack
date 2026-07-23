-- PHASE 2: Enhanced Animal Lookup Functions with Persistent Identity Support
-- Provides enhanced animal finding capabilities that work with restored animals

local AE_EnhancedLookups = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
local AE_DataService = nil
local AE_TamingSystem = nil

-- PHASE 3: Performance optimization caches
local playerAnimalCache = {}
local cacheExpiry = {}
local CACHE_DURATION_MS = 5000  -- 5 second cache
local lastCleanupTime = 0
local CLEANUP_INTERVAL_MS = 30000  -- 30 second cleanup

function AE_EnhancedLookups.initializeDependencies()
    local success, result = pcall(function()
        return require("AnimalsEssentials/DataServices/AE_DataService")
    end)
    if success and result then
        AE_DataService = result
    end
    
    local success2, result2 = pcall(function()
        return require("AnimalsEssentials/Taming/AE_TamingSystem")
    end)
    if success2 and result2 then
        AE_TamingSystem = result2
    end
end

-- PHASE 2: Enhanced lookup that works with restored animals
function AE_EnhancedLookups.getTamedAnimalByStableID(stableID)
    if not stableID then return nil end
    
    if AE_EnvironmentDetector.isMultiplayer() and isClient() then
        print("[ENHANCED LOOKUPS] MP Mode: Using world search for " .. stableID)
    end
    
    -- Try persistent mapping first (handles restored animals)
    if AE_TamingSystem and AE_TamingSystem.findAnimalByPersistentID then
        local animal = AE_TamingSystem.findAnimalByPersistentID(stableID)
        if animal then
            return animal
        end
    end
    
    -- Fallback to world search if not in persistent mapping
    local player = getPlayer()
    if not player then return nil end
    
    local cell = getCell()
    if not cell then return nil end
    
    local objectList = cell:getObjectList()
    if not objectList then return nil end
    
    for i = 0, objectList:size() - 1 do
        local obj = objectList:get(i)
        if obj and obj:isAnimal() then
            local objStableID = AE_DataService and AE_DataService.getStableID(obj)
            if objStableID == stableID and AE_DataService.isTamed(obj) then
                -- Create mapping if found via fallback search
                if AE_TamingSystem and AE_TamingSystem.createPersistentMapping then
                    AE_TamingSystem.createPersistentMapping(obj)
                end
                return obj
            end
        end
    end
    
    return nil
end

-- PHASE 3: Performance optimized cleanup
function AE_EnhancedLookups.cleanupCache()
    local currentTime = getTimestampMs()
    
    -- Only run cleanup periodically
    if currentTime - lastCleanupTime < CLEANUP_INTERVAL_MS then
        return
    end
    
    local expiredKeys = {}
    for playerID, expiry in pairs(cacheExpiry) do
        if currentTime > expiry then
            table.insert(expiredKeys, playerID)
        end
    end
    
    for _, playerID in ipairs(expiredKeys) do
        playerAnimalCache[playerID] = nil
        cacheExpiry[playerID] = nil
    end
    
    lastCleanupTime = currentTime
    
    if #expiredKeys > 0 then
        print("[ENHANCED LOOKUPS] Cleaned " .. #expiredKeys .. " expired cache entries")
    end
end

-- PHASE 2: Get all tamed animals for a player (includes restored animals)
function AE_EnhancedLookups.getAllTamedAnimalsForPlayer(player)
    if not player then return {} end
    
    local playerID = player:getOnlineID()
    local currentTime = getTimestampMs()
    
    -- PHASE 3: Check cache first for performance
    if playerAnimalCache[playerID] and cacheExpiry[playerID] and currentTime < cacheExpiry[playerID] then
        return playerAnimalCache[playerID]
    end
    
    -- PHASE 3: Periodic cache cleanup
    AE_EnhancedLookups.cleanupCache()
    
    local animals = {}
    
    -- Collect from persistent mappings (includes restored animals)
    if AE_TamingSystem and AE_TamingSystem.persistentAnimalMapping then
        for stableID, animal in pairs(AE_TamingSystem.persistentAnimalMapping) do
            if animal and animal:isExistInTheWorld() and not animal:isDead() then
                local owner = AE_DataService and AE_DataService.getOwner(animal)
                if owner == playerID then
                    table.insert(animals, {
                        animal = animal,
                        stableID = stableID,
                        source = "persistent_mapping"
                    })
                end
            end
        end
    end
    
    -- Collect additional animals from world that might not be in mapping yet
    local cell = getCell()
    if cell then
        local objectList = cell:getObjectList()
        if objectList then
            for i = 0, objectList:size() - 1 do
                local obj = objectList:get(i)
                if obj and obj:isAnimal() and AE_DataService then
                    local isTamed = AE_DataService.isTamed(obj)
                    local owner = AE_DataService.getOwner(obj)
                    local stableID = AE_DataService.getStableID(obj)
                    
                    if isTamed and owner == playerID and stableID then
                        -- Check if already in results from persistent mapping
                        local alreadyIncluded = false
                        for _, existing in ipairs(animals) do
                            if existing.stableID == stableID then
                                alreadyIncluded = true
                                break
                            end
                        end
                        
                        if not alreadyIncluded then
                            table.insert(animals, {
                                animal = obj,
                                stableID = stableID,
                                source = "world_search"
                            })
                            
                            -- Create mapping for newly found animal
                            if AE_TamingSystem and AE_TamingSystem.createPersistentMapping then
                                AE_TamingSystem.createPersistentMapping(obj)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- PHASE 3: Cache results for performance
    playerAnimalCache[playerID] = animals
    cacheExpiry[playerID] = currentTime + CACHE_DURATION_MS
    
    return animals
end

-- PHASE 2: Enhanced animal targeting for commands
function AE_EnhancedLookups.findTargetAnimalForCommand(stableID, player)
    if not stableID or not player then return nil end
    
    local animal = AE_EnhancedLookups.getTamedAnimalByStableID(stableID)

    if animal and animal:isExistInTheWorld() and not animal:isDead() then
        -- Verify ownership
        local owner = AE_DataService and AE_DataService.getOwner(animal)
        if owner == player:getOnlineID() then
            return animal
        end
    end
    
    return nil
end

-- PHASE 2: Get animal by multiple ID types (supports both instance and persistent IDs)
function AE_EnhancedLookups.getAnimalByAnyID(animalID)
    if not animalID then return nil end
    
    -- Try as StableID first
    local animal = AE_EnhancedLookups.getTamedAnimalByStableID(animalID)
    if animal then return animal end
    
    -- Try as instance ID through cache
    if AE_TamingSystem and AE_TamingSystem.animalCache then
        animal = AE_TamingSystem.animalCache[animalID]
        if animal and animal:isExistInTheWorld() and not animal:isDead() then
            return animal
        end
    end
    
    -- Fallback to world search by instance ID
    local cell = getCell()
    if cell then
        local objectList = cell:getObjectList()
        if objectList then
            for i = 0, objectList:size() - 1 do
                local obj = objectList:get(i)
                if obj and obj:isAnimal() and obj:getID() == animalID then
                    return obj
                end
            end
        end
    end
    
    return nil
end

-- PHASE 3: Cache invalidation for updated animals
function AE_EnhancedLookups.invalidatePlayerCache(playerID)
    if playerID then
        playerAnimalCache[playerID] = nil
        cacheExpiry[playerID] = nil
    else
        -- Clear all caches if no specific player
        playerAnimalCache = {}
        cacheExpiry = {}
    end
end

-- PHASE 2: Initialize enhanced lookups
function AE_EnhancedLookups.initialize()
    AE_EnhancedLookups.initializeDependencies()
    
    -- Subscribe to instance update events
    if Events and Events.OnTamedAnimalInstanceUpdated then
        Events.OnTamedAnimalInstanceUpdated.Add(function(stableID, newAnimal)
            -- Update any cached references when instances change
            print("[ENHANCED LOOKUPS] Updated animal instance mapping: " .. stableID)
            
            -- PHASE 3: Invalidate caches when animals are restored
            if newAnimal and AE_DataService then
                local owner = AE_DataService.getOwner(newAnimal)
                if owner then
                    AE_EnhancedLookups.invalidatePlayerCache(owner)
                end
            end
        end)
    end
end

-- Initialize on module load
AE_EnhancedLookups.initialize()

-- Global access
_G.AE_EnhancedLookups = AE_EnhancedLookups

return AE_EnhancedLookups