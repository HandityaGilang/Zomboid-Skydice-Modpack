local AE_ZoneSpawningCore = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

local AE_MPPlayerUtils = nil
local function loadMPPlayerUtils()
    if not AE_MPPlayerUtils then
        local success, result = pcall(function()
            return require("AnimalsEssentials/AE_MPPlayerUtils")
        end)
        
        if success and result then
            AE_MPPlayerUtils = result
            print("[AE_ZoneSpawning] AE_MPPlayerUtils loaded successfully for optimization")
        else
            print("[AE_ZoneSpawning] WARNING: AE_MPPlayerUtils not available - using legacy player selection")
        end
    end
    return AE_MPPlayerUtils
end

-- Comprehensive optimization configuration system (BEHAVIORAL DIRECTIVE: Defensive patterns)
local PLAYER_SELECTION_CONFIG = {
    -- Phase 1 optimizations (safe, minimal risk)
    cacheMaxPlayers = true,                  -- Cache player detection results
    usePlayerCaching = false,                -- Phase 2: Daily player count caching (disabled by default)
    
    -- Caching parameters  
    cacheIntervalHours = 24,                 -- Daily refresh for player count cache
    emergencyRefreshThreshold = 0,           -- Refresh cache if no players detected
    maxPlayersCacheRefreshMinutes = 60,      -- Refresh maxPlayers cache hourly
    
    -- Debugging and monitoring
    debugPlayerSelection = false,            -- Detailed selection logging
    debugCaching = false,                    -- Cache operation logging
    enablePerformanceMonitoring = true,     -- Track optimization impact
    
    -- Emergency controls (BEHAVIORAL DIRECTIVE: Rollback capability)
    emergencyDisableOptimizations = false,   -- Master kill switch
    fallbackToOptimizedOnError = true,      -- Auto-fallback to optimized methods
    
    -- Validation settings
    validateCacheIntegrity = true,           -- Validate cached data before use
    maxEmergencyRefreshPerHour = 6           -- Rate limiting for emergency polls
}

-- Cache data structures (BEHAVIORAL DIRECTIVE: Defensive, dormant by default)
local maxPlayersCache = {
    value = nil,
    lastRefresh = 0,
    refreshIntervalMs = 3600000  -- 1 hour in milliseconds
}

local playerCountCache = {
    lastPollTime = 0,                    -- Last poll in world age hours
    cacheValidHours = 24,                -- Cache lifetime  
    maxPlayers = 0,                      -- Server slot count
    currentPlayerCount = 0,              -- Active players detected
    playerSlots = {},                    -- Occupied slot tracking
    emergencyMode = false,               -- Fallback when cache invalid
    pollInProgress = false,              -- Prevent concurrent polling
    lastEmergencyPoll = 0                -- Rate limiting for emergency polls
}

-- Performance monitoring (BEHAVIORAL DIRECTIVE: Quality integrity)
local performanceMetrics = {
    legacyCallCount = 0,
    cachedCallCount = 0,
    emergencyPollCount = 0,
    dailyPollCount = 0,
    cacheHitRate = 0,
    lastPerformanceReport = 0
}

-- System state variables (dormant by default)
local nextSpawnTime = nil
local systemActive = false

-- Pending zone spawns system (following LivesSystem pattern)
local pendingZoneSpawns = {}
local SPAWN_DELAY_TICKS = 300  -- ~5 seconds at 60 FPS (like LivesSystem delay)
local tickHandlerActive = false

-- Timed spawning data structure
local timedSpawnData = {
    coordinatesPending = nil,
    spawnScheduled = false,
    delayStartTime = 0,
    targetSpawnTime = 0
}

-- Timer state for defensive non-polling approach
local timedSpawnTimer = {
    lastTriggerTime = 0,
    nextTriggerTime = 0,
    systemActive = false
}

local timerExecuting = false

-- Predefined spawn zones with exact coordinates from user specifications
local spawnZones = {
    -- Animal Care Center zones
    {id = "ACC_1", corner1 = {x = 3288, y = 12243}, corner2 = {x = 3200, y = 12088}, enabled = true},
    {id = "ACC_2", corner1 = {x = 3288, y = 12005}, corner2 = {x = 3133, y = 12083}, enabled = true},
    {id = "ACC_3", corner1 = {x = 3003, y = 12196}, corner2 = {x = 3079, y = 12048}, enabled = true},
    {id = "ACC_4", corner1 = {x = 3195, y = 12157}, corner2 = {x = 3098, y = 12087}, enabled = true},
    {id = "ACC_5", corner1 = {x = 3130, y = 12060}, corner2 = {x = 3084, y = 12032}, enabled = true},
    
    -- Pony Roam-O zones
    {id = "PRO_1", corner1 = {x = 8594, y = 8528}, corner2 = {x = 8572, y = 8498}, enabled = true},
    {id = "PRO_2", corner1 = {x = 8537, y = 8514}, corner2 = {x = 8545, y = 8526}, enabled = true},
    
    -- Horse Place zones
    {id = "HP_1", corner1 = {x = 5612, y = 6494}, corner2 = {x = 5552, y = 6425}, enabled = true},
    {id = "HP_2", corner1 = {x = 5660, y = 6540}, corner2 = {x = 5628, y = 6511}, enabled = true},
    {id = "HP_3", corner1 = {x = 5623, y = 6592}, corner2 = {x = 5551, y = 6585}, enabled = true}
}

-- Zone boundary calculation from corner coordinates
function AE_ZoneSpawningCore.calculateZoneBoundaries(corner1, corner2)
    local minX = math.min(corner1.x, corner2.x)
    local maxX = math.max(corner1.x, corner2.x)
    local minY = math.min(corner1.y, corner2.y)
    local maxY = math.max(corner1.y, corner2.y)
    return {
        minX = minX,
        maxX = maxX,
        minY = minY,
        maxY = maxY,
        z = 0  -- Ground level default
    }
end

-- PHASE 1: Simple coordinate generation (NEW FORMAT - no overengineering)
function AE_ZoneSpawningCore.getRandomPositionInZone(zone)
    local x = ZombRand(zone.minX, zone.maxX + 1)
    local y = ZombRand(zone.minY, zone.maxY + 1)
    return x, y, 0
end

-- Weighted variant selection (exact same system as client)
function AE_ZoneSpawningCore.selectWeightedVariant()
    local catSpawnOptions = {
        -- Common variants (63.5% total)
        {variant = "babykitten", weight = 31.75},        -- Common baby
        {variant = "babykittenmanx", weight = 31.75},    -- Common baby manx
        
        -- Uncommon variants (32% total - garf/siamese + manx adults)  
        {variant = "tom", weight = 8},                   -- Uncommon male
        {variant = "queen", weight = 8},                 -- Uncommon female
        {variant = "tommanx", weight = 8},               -- Uncommon male manx
        {variant = "queenmanx", weight = 8},             -- Uncommon female manx
        
        -- Rare variants (1.5% each - 4.5% total)
        {variant = "babysmokeykitten", weight = 1.5},    -- Rare baby smokey
        {variant = "smokeyboi", weight = 1.5},           -- Rare male smokey  
        {variant = "smokeygirly", weight = 1.5}          -- Rare female smokey
    }
    
    -- Calculate total weight
    local totalWeight = 0
    for _, entry in ipairs(catSpawnOptions) do
        totalWeight = totalWeight + entry.weight
    end
    
    -- Random selection within total weight (use integer math for precision)
    local randomValue = ZombRand(totalWeight * 100) / 100
    
    -- Find selected variant
    local currentWeight = 0
    for _, entry in ipairs(catSpawnOptions) do
        currentWeight = currentWeight + entry.weight
        if randomValue <= currentWeight then
            return entry.variant
        end
    end
    
    -- Fallback (should never reach here)
    return "babykitten"
end

-- Pending spawns management (following LivesSystem pattern)
function AE_ZoneSpawningCore.addToPendingZoneSpawns(spawnData)
    print("[AE_ZoneSpawning_DEBUG] Adding to pending spawns: zone " .. spawnData.zoneId .. 
          " at player coords (" .. spawnData.x .. ", " .. spawnData.y .. ", " .. spawnData.z .. ")")
    table.insert(pendingZoneSpawns, spawnData)
    
    -- Activate tick handler if not already active (defensive activation)
    if not tickHandlerActive then
        AE_ZoneSpawningCore.activateTickHandler()
    end
end

-- Tick-based processing (like LivesSystem onTick)
function AE_ZoneSpawningCore.onTick()
    if #pendingZoneSpawns == 0 then 
        return 
    end
    
    for i = #pendingZoneSpawns, 1, -1 do
        local spawnData = pendingZoneSpawns[i]
        spawnData.tickCount = spawnData.tickCount + 1
        
        if spawnData.tickCount >= SPAWN_DELAY_TICKS then
            print("[AE_ZoneSpawning_DEBUG] Delay reached for zone " .. spawnData.zoneId .. 
                  ", executing spawn at player coordinates")
            
            if AE_ZoneSpawningCore.executeDirectSpawnAtCoordinates(spawnData) then
                table.remove(pendingZoneSpawns, i)
                print("[AE_ZoneSpawning_DEBUG] Spawn completed and removed from pending list")
            else
                table.remove(pendingZoneSpawns, i)
                print("[AE_ZoneSpawning_DEBUG] Spawn failed and removed from pending list")
            end
        end
    end
    
    -- Deactivate tick handler when no more pending spawns (defensive deactivation)
    if #pendingZoneSpawns == 0 and tickHandlerActive then
        AE_ZoneSpawningCore.deactivateTickHandler()
    end
end

-- Tick handler management (defensive pattern)
function AE_ZoneSpawningCore.activateTickHandler()
    if not Events or not Events.OnTick then
        print("[AE_ZoneSpawning_DEBUG] WARNING: OnTick event not available")
        return
    end
    
    if not tickHandlerActive then
        Events.OnTick.Add(AE_ZoneSpawningCore.onTick)
        tickHandlerActive = true
        print("[AE_ZoneSpawning_DEBUG] Tick handler activated for pending spawns")
    end
end

function AE_ZoneSpawningCore.deactivateTickHandler()
    if Events and Events.OnTick and tickHandlerActive then
        Events.OnTick.Remove(AE_ZoneSpawningCore.onTick)
        tickHandlerActive = false
        print("[AE_ZoneSpawning_DEBUG] Tick handler deactivated (no pending spawns)")
    end
end

-- Direct spawning at player coordinates (following SummoningItem + LivesSystem pattern)
function AE_ZoneSpawningCore.executeDirectSpawnAtCoordinates(spawnData)
    local AE_RouterIntegrationUtils = require("AnimalsEssentials/Core/AE_RouterIntegrationUtils")
    
    local player = getSpecificPlayer(0)
    if not player then
        return 0
    end
    
    local animalCount = 1 + ZombRand(2)
    local successfulSpawns = 0
    
    for i = 1, animalCount do
        if AE_RouterIntegrationUtils.routedSpawnCat(player, spawnData.x, spawnData.y, spawnData.z, 3) then
            successfulSpawns = successfulSpawns + 1
        end
    end
    
    return successfulSpawns > 0
end

-- Direct animal spawning (following SummoningItem pattern exactly)
function AE_ZoneSpawningCore.spawnAnimalDirectly(variant, x, y, z)
    local success, result = pcall(function()
        if not AnimalDefinitions then
            print("[AE_ZoneSpawning] ERROR: AnimalDefinitions not available")
            return false
        end
        
        local animalDef = AnimalDefinitions.getDef(variant)
        if not animalDef then
            print("[AE_ZoneSpawning] ERROR: Could not get definition for " .. tostring(variant))
            return false
        end
        
        local breeds = animalDef:getBreeds()
        if not breeds or breeds:size() == 0 then
            print("[AE_ZoneSpawning] ERROR: No breeds available for " .. tostring(variant))
            return false
        end
        
        -- Breed selection logic (following SummoningItem pattern exactly)
        local breedObj = nil
        if variant == "babysmokeykitten" or variant == "smokeyboi" or variant == "smokeygirly" then
            if animalDef.getBreedByName then
                breedObj = animalDef:getBreedByName("midnight")
            end
            if not breedObj then
                breedObj = breeds:get(0)
            end
            print("[AE_ZoneSpawning] Using midnight breed for " .. tostring(variant))
        else
            breedObj = breeds:get(0)
            print("[AE_ZoneSpawning] Using first available breed for " .. tostring(variant))
        end
        
        if not breedObj then
            print("[AE_ZoneSpawning] ERROR: No breed object available for " .. tostring(variant))
            return false
        end
        
        local cell = getCell()
        if not cell then
            print("[AE_ZoneSpawning] ERROR: Could not get cell")
            return false
        end
        
        -- Direct spawning call (following both working patterns)
        local animal = addAnimal(cell, x, y, z, variant, breedObj)
        if not animal then
            print("[AE_ZoneSpawning] ERROR: addAnimal failed for " .. tostring(variant))
            return false
        end
        
        -- Add to world (following SummoningItem pattern)
        if animal.addToWorld then
            animal:addToWorld()
        end
        
        print("[AE_ZoneSpawning] SUCCESS: " .. variant .. " spawned at (" .. x .. ", " .. y .. ", " .. z .. ")")
        return true
    end)
    
    if not success then
        print("[AE_ZoneSpawning] ERROR: Spawn execution failed: " .. tostring(result))
        return false
    end
    
    return result
end

-- Environment-aware player selection for timed spawning (BEHAVIORAL DIRECTIVE: User authority preserved)
function AE_ZoneSpawningCore.selectPlayerForTimedSpawn()
    -- Emergency disable check (BEHAVIORAL DIRECTIVE: Rollback capability)
    if PLAYER_SELECTION_CONFIG.emergencyDisableOptimizations then
        if PLAYER_SELECTION_CONFIG.debugPlayerSelection then
            print("[AE_ZoneSpawning] Emergency optimizations disabled - using basic optimized method")
        end
        return AE_ZoneSpawningCore.selectPlayerForTimedSpawnWithOptimizations()
    end
    
    -- Route to appropriate implementation based on configuration
    if PLAYER_SELECTION_CONFIG.usePlayerCaching then
        return AE_ZoneSpawningCore.selectPlayerForTimedSpawnCached()
    else
        return AE_ZoneSpawningCore.selectPlayerForTimedSpawnWithOptimizations()
    end
end

-- Phase 2A: Daily player count polling system (BEHAVIORAL DIRECTIVE: User authority preserved)
function AE_ZoneSpawningCore.performDailyPlayerPoll()
    local currentTime = getGameTime():getWorldAgeHours()
    
    -- Prevent concurrent polling (BEHAVIORAL DIRECTIVE: Defensive patterns)
    if playerCountCache.pollInProgress then
        if PLAYER_SELECTION_CONFIG.debugCaching then
            print("[AE_ZoneSpawning] Daily poll already in progress, skipping")
        end
        return false
    end
    
    playerCountCache.pollInProgress = true
    
    local success, result = pcall(function()
        if PLAYER_SELECTION_CONFIG.debugCaching then
            print("[AE_ZoneSpawning] Starting daily player count poll")
        end
        
        -- Cache server configuration (using Phase 1 optimization)
        playerCountCache.maxPlayers = AE_ZoneSpawningCore.getCachedMaxPlayers()
        playerCountCache.currentPlayerCount = 0
        playerCountCache.playerSlots = {}
        
        -- Poll all server slots ONCE per day (USER AUTHORITY: Preserve original logic)
        for i = 0, playerCountCache.maxPlayers - 1 do
            local player = getSpecificPlayer(i)
            if player then
                playerCountCache.currentPlayerCount = playerCountCache.currentPlayerCount + 1
                playerCountCache.playerSlots[i] = {
                    player = player,
                    lastSeen = currentTime,
                    playerID = tostring(player:getOnlineID()),
                    coordinates = {
                        x = player:getX(),
                        y = player:getY(),
                        z = player:getZ()
                    }
                }
            end
        end
        
        playerCountCache.lastPollTime = currentTime
        playerCountCache.cacheValidHours = PLAYER_SELECTION_CONFIG.cacheIntervalHours
        playerCountCache.emergencyMode = false
        
        if PLAYER_SELECTION_CONFIG.debugCaching then
            print("[AE_ZoneSpawning] Daily poll complete: " .. playerCountCache.currentPlayerCount .. 
                  " players found in " .. playerCountCache.maxPlayers .. " server slots")
        end
        
        return true
    end)
    
    playerCountCache.pollInProgress = false
    
    if not success then
        print("[AE_ZoneSpawning] ERROR: Daily player poll failed: " .. tostring(result))
        playerCountCache.emergencyMode = true
        return false
    end
    
    return result
end

-- Phase 2A: Check if daily poll is due
function AE_ZoneSpawningCore.isDailyPollDue()
    local currentTime = getGameTime():getWorldAgeHours()
    return (currentTime - playerCountCache.lastPollTime) >= playerCountCache.cacheValidHours
end

-- Phase 2B: Emergency contingency handling for zero players (USER AUTHORITY: Preserve functionality)
function AE_ZoneSpawningCore.performEmergencyPlayerPoll()
    local currentTime = getGameTime():getWorldAgeHours()
    
    -- Rate limiting: prevent emergency polling spam (BEHAVIORAL DIRECTIVE: Defensive patterns)
    if playerCountCache.lastEmergencyPoll and (currentTime - playerCountCache.lastEmergencyPoll) < PLAYER_SELECTION_CONFIG.emergencyPollCooldown then
        if PLAYER_SELECTION_CONFIG.debugCaching then
            print("[AE_ZoneSpawning] Emergency poll skipped - cooldown active")
        end
        return false
    end
    
    if PLAYER_SELECTION_CONFIG.debugCaching then
        print("[AE_ZoneSpawning] Performing emergency player poll due to zero cached players")
    end
    
    playerCountCache.lastEmergencyPoll = currentTime
    performanceMetrics.emergencyPollCount = performanceMetrics.emergencyPollCount + 1
    
    local success, result = pcall(function()
        -- Emergency scan using EXACT original logic (USER AUTHORITY: Preserve spawn distribution)
        playerCountCache.maxPlayers = AE_ZoneSpawningCore.getCachedMaxPlayers()
        playerCountCache.currentPlayerCount = 0
        playerCountCache.playerSlots = {}
        
        -- Same server slot iteration as original selectPlayerForTimedSpawn
        for i = 0, playerCountCache.maxPlayers - 1 do
            local player = getSpecificPlayer(i)
            if player then
                playerCountCache.currentPlayerCount = playerCountCache.currentPlayerCount + 1
                playerCountCache.playerSlots[i] = {
                    player = player,
                    lastSeen = currentTime,
                    playerID = tostring(player:getOnlineID()),
                    coordinates = {
                        x = player:getX(),
                        y = player:getY(),
                        z = player:getZ()
                    },
                    emergencyDetected = true -- Flag for monitoring
                }
                
                if PLAYER_SELECTION_CONFIG.debugCaching then
                    print("[AE_ZoneSpawning] Emergency: Found player at slot " .. i)
                end
            end
        end
        
        -- Update emergency state
        if playerCountCache.currentPlayerCount > 0 then
            playerCountCache.emergencyMode = false
            if PLAYER_SELECTION_CONFIG.debugCaching then
                print("[AE_ZoneSpawning] Emergency poll successful - " .. playerCountCache.currentPlayerCount .. " players found")
            end
            return true
        else
            playerCountCache.emergencyMode = true
            if PLAYER_SELECTION_CONFIG.debugCaching then
                print("[AE_ZoneSpawning] Emergency poll confirmed zero players - entering emergency mode")
            end
            return false
        end
    end)
    
    if not success then
        print("[AE_ZoneSpawning] ERROR: Emergency player poll failed: " .. tostring(result))
        playerCountCache.emergencyMode = true
        return false
    end
    
    return result
end

-- Phase 2B: Validate cache before use with emergency fallback (USER AUTHORITY: No breaking logic)
function AE_ZoneSpawningCore.validatePlayerCacheWithEmergency()
    -- Check if cache expired and needs daily refresh
    if AE_ZoneSpawningCore.isDailyPollDue() then
        if PLAYER_SELECTION_CONFIG.debugCaching then
            print("[AE_ZoneSpawning] Cache expired, performing daily poll")
        end
        
        local pollSuccess = AE_ZoneSpawningCore.performDailyPlayerPoll()
        if not pollSuccess then
            if PLAYER_SELECTION_CONFIG.debugCaching then
                print("[AE_ZoneSpawning] Daily poll failed, cache marked as invalid")
            end
            return false
        end
    end
    
    -- Emergency contingency: if cache shows zero players but spawning requested
    if playerCountCache.currentPlayerCount == 0 then
        if PLAYER_SELECTION_CONFIG.debugCaching then
            print("[AE_ZoneSpawning] Zero players in cache, triggering emergency poll")
        end
        
        local emergencySuccess = AE_ZoneSpawningCore.performEmergencyPlayerPoll()
        if not emergencySuccess then
            -- Confirmed zero players after emergency check
            if PLAYER_SELECTION_CONFIG.debugCaching then
                print("[AE_ZoneSpawning] Emergency poll confirmed no players available")
            end
            return false
        end
    end
    
    -- Final validation: cache must have valid player data
    local isValid, reason = AE_ZoneSpawningCore.validatePlayerCountCache()
    if not isValid then
        if PLAYER_SELECTION_CONFIG.debugCaching then
            print("[AE_ZoneSpawning] Cache validation failed: " .. tostring(reason))
        end
        return false
    end
    
    return playerCountCache.currentPlayerCount > 0
end

-- Phase 2A: Cache validation (BEHAVIORAL DIRECTIVE: Quality integrity)
function AE_ZoneSpawningCore.validatePlayerCountCache()
    if not PLAYER_SELECTION_CONFIG.validateCacheIntegrity then
        return true -- Skip validation if disabled
    end
    
    -- Basic cache integrity checks
    if playerCountCache.maxPlayers <= 0 then
        return false, "Invalid maxPlayers in cache"
    end
    
    if playerCountCache.currentPlayerCount < 0 then
        return false, "Invalid currentPlayerCount in cache"
    end
    
    if playerCountCache.currentPlayerCount > playerCountCache.maxPlayers then
        return false, "currentPlayerCount exceeds maxPlayers"
    end
    
    -- Verify cache age
    local currentTime = getGameTime():getWorldAgeHours()
    local cacheAge = currentTime - playerCountCache.lastPollTime
    if cacheAge > (playerCountCache.cacheValidHours * 1.5) then -- 50% tolerance
        return false, "Cache too old: " .. cacheAge .. " hours"
    end
    
    return true, "Cache validation passed"
end

-- Phase 1B: Optimized player selection with conservative player detection (BEHAVIORAL DIRECTIVE: Preserve functionality)
function AE_ZoneSpawningCore.selectPlayerForTimedSpawnWithOptimizations()
    local selectedPlayer = nil
    local coordinates = nil
    
    -- Performance tracking
    performanceMetrics.cachedCallCount = performanceMetrics.cachedCallCount + 1
    
    if PLAYER_SELECTION_CONFIG.debugPlayerSelection then
        print("[AE_ZoneSpawning] Using Phase 1 optimized player selection method")
    end

    if AE_EnvironmentDetector.isSinglePlayer() then
        selectedPlayer = getSpecificPlayer(0)
    else
        if not isClient() then
            local players = {}
            local maxPlayers = AE_ZoneSpawningCore.getCachedMaxPlayers()  -- Phase 1B optimization
            
            for i = 0, maxPlayers - 1 do
                local player = getSpecificPlayer(i)
                if player then
                    table.insert(players, player)
                end
            end
            
            if #players > 0 then
                selectedPlayer = players[ZombRand(#players) + 1]
                if PLAYER_SELECTION_CONFIG.debugPlayerSelection then
                    print("[AE_ZoneSpawning] Selected player from " .. #players .. " players (Phase 1 optimized)")
                end
            end
        end
    end
    
    if selectedPlayer then
        local currentSquare = selectedPlayer:getCurrentSquare()
        if currentSquare and not currentSquare:isOutside() then
            if PLAYER_SELECTION_CONFIG.debugPlayerSelection then
                print("[AE_ZoneSpawning] Player not outside, skipping coordinate capture")
            end
            return nil
        end

        coordinates = {
            x = selectedPlayer:getX(),
            y = selectedPlayer:getY(),
            z = selectedPlayer:getZ(),
            playerID = tostring(selectedPlayer:getOnlineID()),
            captureTime = getGameTime():getWorldAgeHours()
        }
    end

    return coordinates
end


-- Phase 2C: Cached player selection with original logic preservation (USER AUTHORITY: Preserve functionality)
function AE_ZoneSpawningCore.selectPlayerForTimedSpawnCached()
    -- Validate cache and handle emergencies before selection
    local cacheValid = AE_ZoneSpawningCore.validatePlayerCacheWithEmergency()
    if not cacheValid then
        if PLAYER_SELECTION_CONFIG.debugPlayerSelection then
            print("[AE_ZoneSpawning] Cache invalid, falling back to optimized method")
        end
        return AE_ZoneSpawningCore.selectPlayerForTimedSpawnWithOptimizations()
    end
    
    local selectedPlayer = nil
    local coordinates = nil
    
    -- Performance tracking
    performanceMetrics.cachedCallCount = performanceMetrics.cachedCallCount + 1
    
    if PLAYER_SELECTION_CONFIG.debugPlayerSelection then
        print("[AE_ZoneSpawning] Using cached player selection method")
    end

    if AE_EnvironmentDetector.isSinglePlayer() then
        selectedPlayer = getSpecificPlayer(0)
    else
        if not isClient() then
            -- Build player array from cache (preserves EXACT original selection logic)
            local availablePlayers = {}
            for slotId, playerData in pairs(playerCountCache.playerSlots) do
                if playerData.player then
                    table.insert(availablePlayers, playerData.player)
                end
            end
            
            if #availablePlayers > 0 then
                -- Same random selection as original implementation
                selectedPlayer = availablePlayers[ZombRand(#availablePlayers) + 1]
                if PLAYER_SELECTION_CONFIG.debugPlayerSelection then
                    print("[AE_ZoneSpawning] Selected cached player from " .. #availablePlayers .. " players")
                end
            else
                if PLAYER_SELECTION_CONFIG.debugPlayerSelection then
                    print("[AE_ZoneSpawning] No cached players available, cache may be stale")
                end
            end
        end
    end
    
    if selectedPlayer then
        local currentSquare = selectedPlayer:getCurrentSquare()
        if currentSquare and not currentSquare:isOutside() then
            if PLAYER_SELECTION_CONFIG.debugPlayerSelection then
                print("[AE_ZoneSpawning] Player not outside (cached), skipping coordinate capture")
            end
            return nil
        end

        coordinates = {
            x = selectedPlayer:getX(),
            y = selectedPlayer:getY(),
            z = selectedPlayer:getZ(),
            playerID = tostring(selectedPlayer:getOnlineID()),
            captureTime = getGameTime():getWorldAgeHours(),
            fromCache = true
        }
    end

    return coordinates
end

-- Phase 2C: Initialize daily player caching via Events.EveryHours monitoring
function AE_ZoneSpawningCore.checkDailyPlayerCaching()
    if not PLAYER_SELECTION_CONFIG.usePlayerCaching or PLAYER_SELECTION_CONFIG.emergencyDisableOptimizations then
        return
    end
    
    -- Check if daily poll is due
    if AE_ZoneSpawningCore.isDailyPollDue() then
        if PLAYER_SELECTION_CONFIG.debugCaching then
            print("[AE_ZoneSpawning] Daily polling window reached, performing player cache refresh")
        end
        
        local pollSuccess = AE_ZoneSpawningCore.performDailyPlayerPoll()
        if not pollSuccess then
            print("[AE_ZoneSpawning] WARNING: Daily player poll failed, cache may be unreliable")
        end
    end
end

-- Phase 1B: Conservative player detection implementation (BEHAVIORAL DIRECTIVE: Defensive patterns)
function AE_ZoneSpawningCore.getCachedMaxPlayers()
    -- Emergency disable check
    if PLAYER_SELECTION_CONFIG.emergencyDisableOptimizations or not PLAYER_SELECTION_CONFIG.cacheMaxPlayers then
        -- Use conservative estimate to avoid expensive calls
        return 32  -- Standard PZ server maximum, safe fallback
    end
    
    local currentTimeMs = getTimestampMs()
    
    -- Check if cache needs refresh
    if not maxPlayersCache.value or 
       (currentTimeMs - maxPlayersCache.lastRefresh) > maxPlayersCache.refreshIntervalMs then
        
        local success, result = pcall(function()
            -- Use conservative detection instead of expensive getMaxPlayers()
            local detectedPlayers = 0
            for i = 0, 31 do  -- Check up to standard PZ maximum
                if getSpecificPlayer(i) then
                    detectedPlayers = i + 8  -- Add buffer for new connections
                end
            end
            return math.max(detectedPlayers, 8)  -- Minimum reasonable server size
        end)
        
        if success then
            maxPlayersCache.value = result
            maxPlayersCache.lastRefresh = currentTimeMs
            
            if PLAYER_SELECTION_CONFIG.debugCaching then
                print("[AE_ZoneSpawning] Player detection cache refreshed: " .. result .. " slots")
            end
        else
            -- Conservative fallback (BEHAVIORAL DIRECTIVE: Graceful degradation)
            if PLAYER_SELECTION_CONFIG.debugCaching then
                print("[AE_ZoneSpawning] Player detection failed, using conservative estimate")
            end
            return 16  -- Conservative fallback
        end
    end
    
    return maxPlayersCache.value
end

-- Cache management functions (BEHAVIORAL DIRECTIVE: Quality integrity)
function AE_ZoneSpawningCore.refreshMaxPlayersCache()
    local success, result = pcall(function()
        -- Use same detection logic as getCachedMaxPlayers
        local detectedPlayers = 0
        for i = 0, 31 do
            if getSpecificPlayer(i) then
                detectedPlayers = i + 8
            end
        end
        return math.max(detectedPlayers, 8)
    end)
    
    if success then
        maxPlayersCache.value = result
        maxPlayersCache.lastRefresh = getTimestampMs()
        return true
    else
        return false
    end
end

function AE_ZoneSpawningCore.clearMaxPlayersCache()
    maxPlayersCache.value = nil
    maxPlayersCache.lastRefresh = 0
    if PLAYER_SELECTION_CONFIG.debugCaching then
        print("[AE_ZoneSpawning] Player detection cache cleared")
    end
end

-- Validation functions for failure contingencies
local function isSpawnLocationValid(x, y, z)
    local cell = getCell()
    if not cell then
        return false, "No cell available"
    end

    local square = cell:getGridSquare(x, y, z)
    if not square then
        return false, "Square not loaded at coordinates"
    end

    if not square:isOutside() then
        return false, "Spawn location is not outside"
    end

    return true, "Valid spawn location"
end

local function validateCoordinates(x, y, z)
    if x < -10000 or x > 10000 or y < -10000 or y > 10000 then
        return false, "Coordinates out of reasonable bounds"
    end
    
    if z < 0 or z > 7 then
        return false, "Invalid Z level"
    end
    
    return true, "Coordinates valid"
end

local function isAnimalSystemReady()
    if not AnimalDefinitions then
        return false, "AnimalDefinitions not loaded"
    end
    
    local testDef = AnimalDefinitions.getDef("babykitten")
    if not testDef then
        return false, "Animal definitions not accessible"
    end
    
    return true, "Animal system ready"
end

local function validateTimedSpawn(coordsData)
    if not coordsData or not coordsData.x or not coordsData.y then
        return false, "Invalid coordinate data"
    end

    local locationValid, locationReason = isSpawnLocationValid(
        coordsData.x, coordsData.y, coordsData.z or 0
    )
    if not locationValid then
        return false, locationReason
    end

    local systemReady, systemReason = isAnimalSystemReady()
    if not systemReady then
        return false, systemReason
    end

    return true, "All validations passed"
end

-- Add coordinates for delayed timed spawn
function AE_ZoneSpawningCore.scheduleTimedSpawn(playerCoords)
    local failureRoll = ZombRand(100)
    if failureRoll < 45 then
        print("[AE_TimedSpawning] Spawn failed due to 45% failure rate (rolled: " .. failureRoll .. ")")
        return false
    end
    
    timedSpawnData.coordinatesPending = playerCoords
    timedSpawnData.spawnScheduled = true
    timedSpawnData.delayStartTime = getGameTime():getWorldAgeHours()
    
    local delayHours = 0.167 + (ZombRand(11) * 0.0167)
    timedSpawnData.targetSpawnTime = timedSpawnData.delayStartTime + delayHours
    
    print("[AE_TimedSpawning] Scheduled spawn at player coords (" .. 
          playerCoords.x .. ", " .. playerCoords.y .. ") in " .. 
          (delayHours * 60) .. " minutes")
    
    return true
end

-- Execute timed spawn when delay reached
function AE_ZoneSpawningCore.executeTimedSpawn()
    if not timedSpawnData.spawnScheduled or not timedSpawnData.coordinatesPending then
        return false
    end
    
    local currentTime = getGameTime():getWorldAgeHours()
    if currentTime >= timedSpawnData.targetSpawnTime then
        local isValid, reason = validateTimedSpawn(timedSpawnData.coordinatesPending)
        if not isValid then
            print("[AE_TimedSpawning] Spawn validation failed: " .. reason)
            timedSpawnData.coordinatesPending = nil
            timedSpawnData.spawnScheduled = false
            return false
        end
        
        local AE_RouterIntegrationUtils = require("AnimalsEssentials/Core/AE_RouterIntegrationUtils")
        
        local player = getSpecificPlayer(0)
        if not player then
            timedSpawnData.coordinatesPending = nil
            timedSpawnData.spawnScheduled = false
            return false
        end
        
        local success = AE_RouterIntegrationUtils.routedSpawnCat(
            player,
            timedSpawnData.coordinatesPending.x, 
            timedSpawnData.coordinatesPending.y, 
            timedSpawnData.coordinatesPending.z,
            3
        )
        
        timedSpawnData.coordinatesPending = nil
        timedSpawnData.spawnScheduled = false
        timedSpawnData.delayStartTime = 0
        
        return success
    end
    
    return false
end

-- Initialize timed spawning system
function AE_ZoneSpawningCore.initializeTimedSpawning()
    local currentTime = getGameTime():getWorldAgeHours()
    
    local intervalHours = 0.5 + (ZombRand(950) * 0.01)
    
    timedSpawnTimer.lastTriggerTime = currentTime
    timedSpawnTimer.nextTriggerTime = currentTime + intervalHours
    timedSpawnTimer.systemActive = true
    
    print("[AE_TimedSpawning] Initialized timer system, next trigger in " .. 
          (intervalHours * 60) .. " minutes")
end

-- Check if timed spawn should trigger
function AE_ZoneSpawningCore.checkTimedSpawnTimer()
    if not timedSpawnTimer.systemActive then
        return
    end
    
    if timerExecuting then
        return
    end
    
    timerExecuting = true
    
    local currentTime = getGameTime():getWorldAgeHours()
    
    if timedSpawnData.spawnScheduled then
        AE_ZoneSpawningCore.executeTimedSpawn()
    end
    
    if currentTime >= timedSpawnTimer.nextTriggerTime then
        print("[AE_TimedSpawning] Timer trigger reached, initiating new spawn cycle")
        
        local playerCoords = AE_ZoneSpawningCore.selectPlayerForTimedSpawn()
        if playerCoords then
            AE_ZoneSpawningCore.scheduleTimedSpawn(playerCoords)
        else
            print("[AE_TimedSpawning] No players found for timed spawn")
        end
        
        local intervalHours = 0.5 + (ZombRand(950) * 0.01)
        timedSpawnTimer.nextTriggerTime = currentTime + intervalHours
        timedSpawnTimer.lastTriggerTime = currentTime
        
        print("[AE_TimedSpawning] Next trigger scheduled in " .. (intervalHours * 60) .. " minutes")
    end
    
    timerExecuting = false
end

function AE_ZoneSpawningCore.initializeTimedSpawningEvents()
    if Events and Events.EveryHours then
        Events.EveryHours.Add(AE_ZoneSpawningCore.checkTimedSpawnTimer)
        print("[AE_TimedSpawning] Registered with EveryHours timer")
    else
        print("[AE_TimedSpawning] WARNING: Events.EveryHours not available")
    end
    
    -- Phase 2C: Register daily player caching monitoring
    if Events and Events.EveryHours then
        Events.EveryHours.Add(AE_ZoneSpawningCore.checkDailyPlayerCaching)
        print("[AE_ZoneSpawning] Registered daily player caching with EveryHours monitoring")
    end
end

-- System initialization (following LivesSystem pattern)
function AE_ZoneSpawningCore.initialize()
    print("[AE_ZoneSpawning] Initializing direct spawning system")
    
    pendingZoneSpawns = {}
    tickHandlerActive = false
    
    AE_ZoneSpawningCore.initializeTimedSpawning()
    AE_ZoneSpawningCore.initializeTimedSpawningEvents()
    
    print("[AE_ZoneSpawning] Direct spawning system initialized successfully")
end

-- Clean shutdown for pending spawns
function AE_ZoneSpawningCore.shutdown()
    print("[AE_ZoneSpawning] Shutting down direct spawning system")
    
    if tickHandlerActive then
        AE_ZoneSpawningCore.deactivateTickHandler()
    end
    
    if Events and Events.EveryTenMinutes then
        Events.EveryTenMinutes.Remove(AE_ZoneSpawningCore.checkTimedSpawnTimer)
    end
    if Events and Events.EveryHours then
        Events.EveryHours.Remove(AE_ZoneSpawningCore.checkTimedSpawnTimer)
        Events.EveryHours.Remove(AE_ZoneSpawningCore.checkDailyPlayerCaching)
    end
    
    pendingZoneSpawns = {}
    timedSpawnData.coordinatesPending = nil
    timedSpawnData.spawnScheduled = false
    timedSpawnTimer.systemActive = false
    
    print("[AE_ZoneSpawning] Direct spawning system shutdown complete")
end

-- Initialize on game start (following both working patterns)
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(AE_ZoneSpawningCore.initialize)
else
    AE_ZoneSpawningCore.initialize()
end

-- Configuration management functions (BEHAVIORAL DIRECTIVE: Quality integrity)
function AE_ZoneSpawningCore.setPlayerSelectionConfig(config)
    for key, value in pairs(config) do
        if PLAYER_SELECTION_CONFIG[key] ~= nil then
            PLAYER_SELECTION_CONFIG[key] = value
            print("[AE_ZoneSpawning] Configuration '" .. key .. "' set to " .. tostring(value))
        end
    end
end

function AE_ZoneSpawningCore.getPlayerSelectionConfig()
    return PLAYER_SELECTION_CONFIG
end

-- Emergency controls (BEHAVIORAL DIRECTIVE: Rollback capability)
function AE_ZoneSpawningCore.emergencyDisableAllOptimizations()
    PLAYER_SELECTION_CONFIG.emergencyDisableOptimizations = true
    PLAYER_SELECTION_CONFIG.usePlayerCaching = false
    PLAYER_SELECTION_CONFIG.cacheMaxPlayers = false
    AE_ZoneSpawningCore.clearMaxPlayersCache()
    print("[AE_ZoneSpawning] EMERGENCY: Advanced optimizations disabled, using basic optimized implementation")
end

function AE_ZoneSpawningCore.enablePhase1Optimizations()
    PLAYER_SELECTION_CONFIG.emergencyDisableOptimizations = false
    PLAYER_SELECTION_CONFIG.cacheMaxPlayers = true
    PLAYER_SELECTION_CONFIG.usePlayerCaching = false  -- Phase 2 not ready yet
    print("[AE_ZoneSpawning] Phase 1 optimizations enabled (conservative player detection)")
    return true
end

-- Phase 2D: Enable Phase 2 optimizations (USER AUTHORITY: Your daily caching solution)
function AE_ZoneSpawningCore.enablePhase2Optimizations()
    PLAYER_SELECTION_CONFIG.emergencyDisableOptimizations = false
    PLAYER_SELECTION_CONFIG.cacheMaxPlayers = true  -- Keep Phase 1 benefits
    PLAYER_SELECTION_CONFIG.usePlayerCaching = true -- Enable daily caching
    
    -- Trigger initial poll if cache is empty
    if playerCountCache.lastPollTime == 0 then
        local currentTime = getGameTime():getWorldAgeHours()
        print("[AE_ZoneSpawning] Phase 2 enabled, performing initial player poll")
        AE_ZoneSpawningCore.performDailyPlayerPoll()
    end
    
    print("[AE_ZoneSpawning] Phase 2 optimizations enabled (daily player caching)")
    print("[AE_ZoneSpawning] Cache interval: " .. PLAYER_SELECTION_CONFIG.cacheIntervalHours .. " hours")
    return true
end

-- Performance and monitoring functions (BEHAVIORAL DIRECTIVE: Quality integrity)
function AE_ZoneSpawningCore.getPlayerSelectionStats()
    local currentTime = getGameTime():getWorldAgeHours()
    local stats = {
        -- Current configuration state
        phase1OptimizationsEnabled = PLAYER_SELECTION_CONFIG.cacheMaxPlayers and not PLAYER_SELECTION_CONFIG.emergencyDisableOptimizations,
        phase2OptimizationsEnabled = PLAYER_SELECTION_CONFIG.usePlayerCaching and not PLAYER_SELECTION_CONFIG.emergencyDisableOptimizations,
        emergencyMode = PLAYER_SELECTION_CONFIG.emergencyDisableOptimizations,
        
        -- Phase 1 Cache status
        maxPlayersCacheValid = maxPlayersCache.value ~= nil,
        maxPlayersCacheValue = maxPlayersCache.value,
        maxPlayersCacheAge = maxPlayersCache.lastRefresh > 0 and (getTimestampMs() - maxPlayersCache.lastRefresh) or 0,
        
        -- Phase 2 Cache status
        playerCacheValid = playerCountCache.lastPollTime > 0 and (currentTime - playerCountCache.lastPollTime) < PLAYER_SELECTION_CONFIG.cacheIntervalHours,
        playerCacheAge = currentTime - playerCountCache.lastPollTime,
        cachedPlayerCount = playerCountCache.currentPlayerCount,
        playerCacheEmergencyMode = playerCountCache.emergencyMode,
        
        -- Performance metrics
        legacyCallCount = performanceMetrics.legacyCallCount,
        cachedCallCount = performanceMetrics.cachedCallCount,
        dailyPollCount = performanceMetrics.dailyPollCount,
        emergencyPollCount = performanceMetrics.emergencyPollCount,
        cacheHitRate = performanceMetrics.cachedCallCount > 0 and (performanceMetrics.cachedCallCount / (performanceMetrics.legacyCallCount + performanceMetrics.cachedCallCount)) or 0
    }
    
    return stats
end

function AE_ZoneSpawningCore.reportPerformanceMetrics()
    local stats = AE_ZoneSpawningCore.getPlayerSelectionStats()
    
    print("[AE_ZoneSpawning] === Performance Report ===")
    print("[AE_ZoneSpawning] Phase 1 Optimizations: " .. tostring(stats.phase1OptimizationsEnabled))
    print("[AE_ZoneSpawning] Phase 2 Optimizations: " .. tostring(stats.phase2OptimizationsEnabled))
    print("[AE_ZoneSpawning] Emergency Mode: " .. tostring(stats.emergencyMode))
    print("[AE_ZoneSpawning] === Call Statistics ===")
    print("[AE_ZoneSpawning] Legacy Calls: " .. stats.legacyCallCount)
    print("[AE_ZoneSpawning] Cached Calls: " .. stats.cachedCallCount)
    print("[AE_ZoneSpawning] Daily Polls: " .. stats.dailyPollCount)
    print("[AE_ZoneSpawning] Emergency Polls: " .. stats.emergencyPollCount)
    print("[AE_ZoneSpawning] Cache Hit Rate: " .. string.format("%.1f%%", stats.cacheHitRate * 100))
    print("[AE_ZoneSpawning] === Cache Status ===")
    print("[AE_ZoneSpawning] MaxPlayers Cache Valid: " .. tostring(stats.maxPlayersCacheValid))
    print("[AE_ZoneSpawning] Player Cache Valid: " .. tostring(stats.playerCacheValid))
    print("[AE_ZoneSpawning] Cached Player Count: " .. stats.cachedPlayerCount)
    
    return stats
end

-- Clean shutdown on game end
if Events and Events.OnGameEnd then
    Events.OnGameEnd.Add(AE_ZoneSpawningCore.shutdown)
end

print("[AE_ZoneSpawning] Player Selection Optimization System loaded - Phase 1 (conservative detection) active")

return AE_ZoneSpawningCore
