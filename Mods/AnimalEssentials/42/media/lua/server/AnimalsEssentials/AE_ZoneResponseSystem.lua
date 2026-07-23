-- SERVER-SIDE Zone Response System for immediate position monitoring
-- Following USER AUTHORITY: Server response system separate from shared definitions

local AE_ZoneResponseSystem = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

-- Load zone definitions from shared module
local AE_ZoneDefinitions = require("AnimalsEssentials/AE_ZoneDefinitions")

-- Load zone spawning core module  
local AE_ZoneSpawningCore = require("AnimalsEssentials/AE_ZoneSpawningCore")

local function getZoneSpawningCore()
    return AE_ZoneSpawningCore
end

-- Player position tracking state
local playerZoneState = {} -- Track which zones each player was in

-- PHASE 1: Simple cache system (USER AUTHORITY - 10 minute satiation)
local zoneMovementCache = {} -- {zoneId: {timestamp, isActive}}
local lastPlayerPositions = {} -- {playerId: {x, y}}

-- System initialization (SERVER AUTHORITY - following user corrections)
function AE_ZoneResponseSystem.initializeZoneSystem()
    print("[AE_ZoneResponse_DEBUG] Initializing zone system - SYSTEM INITIALIZATION ENTRY POINT")
    
    local success, result = pcall(function()
        local modData = ModData.getOrCreate("AE_ZoneSpawning_LastSeen")
        
        if not modData.zones then
            print("[AE_ZoneResponse_DEBUG] Creating zones table for first time")
            modData.zones = {}
        else
            print("[AE_ZoneResponse_DEBUG] Zones table exists, zone count: " .. tostring(table.getn and table.getn(modData.zones) or 0))
        end
        
        -- Ensure all zones exist in ModData (for existing saves)
        local zoneCount = 0
        for _, zone in ipairs(AE_ZoneDefinitions.spawnZones) do
            if zone.enabled then
                if not modData.zones[zone.id] then
                    print("[AE_ZoneResponse_DEBUG] Creating zone data for: " .. zone.id)
                    modData.zones[zone.id] = {
                        lastVisited = 0,
                        lastSpawnTime = 0,
                        pendingNewGameSpawn = false,  -- Legacy flag (unused in zone isolation)
                        newGameSpawnExecuted = false  -- Zone isolation: false allows first-time spawn per zone
                    }
                else
                    print("[AE_ZoneResponse_DEBUG] Zone data exists for: " .. zone.id)
                end
                zoneCount = zoneCount + 1
            end
        end
        
        modData.systemInitialized = true
        modData.lastSystemCheck = getGameTime():getWorldAgeHours()
        
        print("[AE_ZoneResponse_DEBUG] Saving zone system initialization data")
        -- SERVER file: Always save since this file only runs on server
        ModData.add("AE_ZoneSpawning_LastSeen", modData)
        
        -- SERVER file: Always transmit since this file only runs on server
        print("[AE_ZoneResponse_DEBUG] Server environment - transmitting ModData")
        return true
    end)
    
    if not success then
        print("[AE_ZoneResponse_DEBUG] ERROR: Zone system initialization failed: " .. tostring(result))
    else
        print("[AE_ZoneResponse_DEBUG] Zone system initialization SUCCESS")
    end
end

-- Emergency fallback player enumeration (preserved for safety)
local function getPlayersDefensively()
    local players = {}

    if AE_EnvironmentDetector.isSinglePlayer() then
        local player = getSpecificPlayer(0)
        if player then
            return {player}
        end
        return {}
    end
    
    -- Emergency iteration method (0-15) as fallback
    for i = 0, 15 do
        local success, player = pcall(function()
            return getSpecificPlayer(i)
        end)
        
        if success and player then
            table.insert(players, player)
        end
    end
    
    return players
end


-- TRUE OPTIMIZATION: Movement-based monitoring with purpose-built APIs and layered fallback
function AE_ZoneResponseSystem.checkMovementBasedZones()
    local success, result = pcall(function()
        if not getGameTime then
            return false
        end
        
        local currentTime = getGameTime():getWorldAgeHours()
        
        -- Emergency fallback player enumeration (defensive pattern)
        local players = getPlayersDefensively()
        if #players == 0 then
            return false
        end
        
        local successCount = 0
        for _, player in ipairs(players) do
            local playerSuccess = pcall(function()
                AE_ZoneResponseSystem.processPlayerMovement(player, currentTime)
            end)
            
            if playerSuccess then
                successCount = successCount + 1
            end
        end
        
        return successCount > 0
    end)
    
    if not success then
        print("[AE_ZoneResponse_DEBUG] ERROR: Movement-based zone check failed: " .. tostring(result))
        Events.OnTick.Add(AE_ZoneResponseSystem.attemptRecovery)
    end
end

-- PHASE 1: Simple movement detection with caching (FOCUSED FIX)
function AE_ZoneResponseSystem.processPlayerMovement(player, currentTime)
    local playerId = tostring(player:getOnlineID())
    local playerX, playerY = player:getX(), player:getY()
    
    -- Simple movement check (5 unit threshold)
    local lastPos = lastPlayerPositions[playerId]
    local hasMovedSignificantly = false
    
    if not lastPos then
        hasMovedSignificantly = true
        lastPlayerPositions[playerId] = {x = playerX, y = playerY}
    else
        local distance = math.sqrt((playerX - lastPos.x)^2 + (playerY - lastPos.y)^2)
        if distance >= 5 then
            hasMovedSignificantly = true
            lastPlayerPositions[playerId] = {x = playerX, y = playerY}
        end
    end
    
    if not hasMovedSignificantly then
        return -- Skip processing if no significant movement
    end
    
    print("[AE_ZoneResponse_DEBUG] Movement detected for player " .. playerId .. " at (" .. tostring(playerX) .. ", " .. tostring(playerY) .. ")")
    
    -- Check zones (simple cache check)
    for _, zone in ipairs(AE_ZoneDefinitions.spawnZones) do
        if zone.enabled then
            -- Simple cache check (10 minute satiation)
            local cache = zoneMovementCache[zone.id]
            if cache and cache.isActive and (currentTime - cache.timestamp) < 0.167 then
                -- Cache still active, skip this zone
            else
                if AE_ZoneDefinitions.isPlayerInZone(playerX, playerY, zone) then
                print("[AE_ZoneResponse_DEBUG] Player " .. playerId .. " ENTERED zone: " .. zone.id)
                
                -- Create cache entry
                zoneMovementCache[zone.id] = {
                    timestamp = currentTime,
                    isActive = true,
                    playerPos = {x = playerX, y = playerY}
                }
                
                AE_ZoneResponseSystem.onPlayerEnterZone(player, zone, currentTime)
                end
            end
        end
    end
end

-- PHASE 3: Handle player entering a zone with weight-based spawning
function AE_ZoneResponseSystem.onPlayerEnterZone(player, zone, currentTime)
    print("[AE_ZoneResponse_DEBUG] Processing zone entry for player in zone: " .. zone.id)

    local success, result = pcall(function()
        AE_ZoneResponseSystem.updateZoneLastSeen(zone.id, currentTime)

        local modData = ModData.getOrCreate("AE_ZoneSpawning_LastSeen")
        local zoneData = modData.zones[zone.id]

        if not zoneData then
            print("[AE_ZoneResponse_DEBUG] WARNING: No zone data found for " .. zone.id)
            return false
        end

        local playerID = tostring(player:getOnlineID())
        local playerCoords = {
            x = player:getX(),
            y = player:getY(),
            z = player:getZ()
        }

        local ZoneSpawningSystem = _G.AE_ZoneSpawningSystem

        if not zoneData.newGameSpawnExecuted then
            print("[AE_ZoneResponse_DEBUG] FIRST ENTRY to zone " .. zone.id .. " - immediate spawn (NO weight check)")

            local spawnCoords = {
                x = playerCoords.x,
                y = playerCoords.y,
                z = playerCoords.z,
                zoneId = zone.id,
                playerID = playerID,
                entryTime = currentTime,
                tickCount = 0
            }

            local spawningCore = getZoneSpawningCore()
            if spawningCore and spawningCore.addToPendingZoneSpawns then
                spawningCore.addToPendingZoneSpawns(spawnCoords)
                print("[AE_ZoneResponse_DEBUG] First entry spawn added to pending spawns")
            else
                print("[AE_ZoneResponse_DEBUG] ERROR: AE_ZoneSpawningCore not available")
                return false
            end

            zoneData.newGameSpawnExecuted = true
            modData.zones[zone.id] = zoneData
            ModData.add("AE_ZoneSpawning_LastSeen", modData)

            if ZoneSpawningSystem and ZoneSpawningSystem.addPlayerToActiveZone then
                ZoneSpawningSystem.addPlayerToActiveZone(zone.id, playerID, zone, playerCoords)
            end

            print("[AE_ZoneResponse_DEBUG] First entry spawn executed for zone: " .. zone.id)
            return true
        else
            print("[AE_ZoneResponse_DEBUG] Subsequent entry to zone " .. zone.id .. " - checking weight system")

            if ZoneSpawningSystem and ZoneSpawningSystem.addPlayerToActiveZone then
                ZoneSpawningSystem.addPlayerToActiveZone(zone.id, playerID, zone, playerCoords)
            end

            if ZoneSpawningSystem and ZoneSpawningSystem.consumeSpawnWeight then
                local weightConsumed = ZoneSpawningSystem.consumeSpawnWeight()

                if not weightConsumed then
                    print("[AE_ZoneResponse_DEBUG] No weights available, skipping spawn")
                    return false
                end

                print("[AE_ZoneResponse_DEBUG] Weight consumed, checking spawn conditions")

                local timeSinceSpawn = currentTime - (zoneData.lastSpawnTime or 0)
                local minSpawnInterval = AE_ZoneDefinitions.spawnSettings.minSpawnInterval

                print("[AE_ZoneResponse_DEBUG] Time since last spawn: " .. string.format("%.2f", timeSinceSpawn) .. " hours (min: " .. tostring(minSpawnInterval) .. ")")

                if timeSinceSpawn < minSpawnInterval then
                    print("[AE_ZoneResponse_DEBUG] Spawn interval not met, refunding weight")
                    if ZoneSpawningSystem.refundSpawnWeight then
                        ZoneSpawningSystem.refundSpawnWeight()
                    end
                    return false
                end

                local spawnRoll = ZombRand(100)
                local failureRate = AE_ZoneDefinitions.spawnSettings.failureRate * 100

                print("[AE_ZoneResponse_DEBUG] Spawn roll: " .. tostring(spawnRoll) .. " (need >= " .. tostring(failureRate) .. ")")

                if spawnRoll < failureRate then
                    print("[AE_ZoneResponse_DEBUG] Spawn failed (35% failure), refunding weight")
                    if ZoneSpawningSystem.refundSpawnWeight then
                        ZoneSpawningSystem.refundSpawnWeight()
                    end
                    return false
                end

                print("[AE_ZoneResponse_DEBUG] Spawn conditions met, executing spawn")

                local spawnCoords = {
                    x = playerCoords.x,
                    y = playerCoords.y,
                    z = playerCoords.z,
                    zoneId = zone.id,
                    playerID = playerID,
                    entryTime = currentTime,
                    tickCount = 0
                }

                local spawningCore = getZoneSpawningCore()
                if spawningCore and spawningCore.addToPendingZoneSpawns then
                    spawningCore.addToPendingZoneSpawns(spawnCoords)

                    zoneData.lastSpawnTime = currentTime
                    modData.zones[zone.id] = zoneData
                    ModData.add("AE_ZoneSpawning_LastSeen", modData)

                    print("[AE_ZoneResponse_DEBUG] Weight-based spawn executed for zone: " .. zone.id)
                    return true
                else
                    print("[AE_ZoneResponse_DEBUG] ERROR: AE_ZoneSpawningCore not available, refunding weight")
                    if ZoneSpawningSystem.refundSpawnWeight then
                        ZoneSpawningSystem.refundSpawnWeight()
                    end
                    return false
                end
            else
                print("[AE_ZoneResponse_DEBUG] WARNING: Weight system not available")
                return false
            end
        end
    end)

    if not success then
        print("[AE_ZoneResponse_DEBUG] ERROR: Zone entry processing failed for " .. zone.id .. ": " .. tostring(result))
    else
        print("[AE_ZoneResponse_DEBUG] Zone entry processing completed for " .. zone.id)
    end
end

-- Update zone last seen time
function AE_ZoneResponseSystem.updateZoneLastSeen(zoneId, currentTime)
    local success, result = pcall(function()
        local modData = ModData.getOrCreate("AE_ZoneSpawning_LastSeen")
        if modData.zones[zoneId] then
            modData.zones[zoneId].lastVisited = currentTime or getGameTime():getWorldAgeHours()
            -- SERVER file: Always save since this file only runs on server
            ModData.add("AE_ZoneSpawning_LastSeen", modData)
            print("[AE_ZoneResponse_DEBUG] Updated lastVisited for zone " .. zoneId .. " to: " .. tostring(currentTime))
            return true
        else
            print("[AE_ZoneResponse_DEBUG] WARNING: Cannot update lastVisited - zone " .. zoneId .. " not found")
            return false
        end
    end)
    
    if not success then
        print("[AE_ZoneResponse_DEBUG] ERROR: Failed to update zone last seen: " .. tostring(result))
    end
end

-- Initialize event-driven monitoring system (following AnimalCollectors pattern)
function AE_ZoneResponseSystem.startEventDrivenMonitoring()
    print("[AE_ZoneResponse_DEBUG] Starting event-driven zone monitoring")
    
    -- Clear state
    playerZoneState = {}
    zoneMovementCache = {}
    lastPlayerPositions = {}
    
    -- Event-driven: No timer registration needed - client sends commands when zones entered
    print("[AE_ZoneResponse_DEBUG] Event-driven monitoring ready - waiting for client zone entry commands")
end

-- Main system initialization function
function AE_ZoneResponseSystem.initialize()
    print("[AE_ZoneResponse_DEBUG] AE_ZoneResponseSystem initialization called")
    
    -- Initialize zone system
    AE_ZoneResponseSystem.initializeZoneSystem()
    
    -- Start event-driven monitoring (following AnimalCollectors pattern)
    AE_ZoneResponseSystem.startEventDrivenMonitoring()
    
    print("[AE_ZoneResponse_DEBUG] Zone response system fully initialized")
end

-- Recovery mechanism for network restoration
function AE_ZoneResponseSystem.attemptRecovery()
    Events.OnTick.Remove(AE_ZoneResponseSystem.attemptRecovery)

    -- SERVER file: Always ready since this file only runs on server
    local mpReady = AE_EnvironmentDetector.isMultiplayer()
    if mpReady then
        print("[AE_ZoneResponse_DEBUG] Network recovered - clearing corrupted state")
        playerZoneState = {}
        lastPlayerPositions = {}
        return
    end
    
    print("[AE_ZoneResponse_DEBUG] Network still unstable - will retry later")
end

-- System cleanup
function AE_ZoneResponseSystem.shutdown()
    print("[AE_ZoneResponse_DEBUG] Shutting down zone response system")
    
    -- Event-driven system: Remove command handler
    if Events.OnClientCommand then
        Events.OnClientCommand.Remove(onClientCommand)
    end
    if Events.OnTick then
        Events.OnTick.Remove(AE_ZoneResponseSystem.attemptRecovery)
    end
    
    playerZoneState = {}
    zoneMovementCache = {}
    lastPlayerPositions = {}
end

-- Client command handler following AnimalCollectors pattern
local function onClientCommand(module, command, player, args)
    if module == "AE_ZoneSystem" then
        if command == "playerZoneEntry" then
            -- Defensive validation of command data
            if not player or not args or not args.zoneId then
                print("[AE_ZoneResponse_DEBUG] Invalid zone entry command received")
                return
            end

            -- Additional validation
            if not args.x or not args.y or not args.entryTime then
                print("[AE_ZoneResponse_DEBUG] Incomplete zone entry data")
                return
            end

            print("[AE_ZoneResponse_DEBUG] Received zone entry command - Player: " .. tostring(player:getOnlineID()) .. ", Zone: " .. args.zoneId)

            -- Find the zone definition
            local targetZone = nil
            for _, zone in ipairs(AE_ZoneDefinitions.spawnZones) do
                if zone.id == args.zoneId and zone.enabled then
                    targetZone = zone
                    break
                end
            end

            if not targetZone then
                print("[AE_ZoneResponse_DEBUG] Zone not found or disabled: " .. args.zoneId)
                return
            end

            -- Process zone entry using existing logic
            local success, result = pcall(function()
                AE_ZoneResponseSystem.onPlayerEnterZone(player, targetZone, args.entryTime)
            end)

            if not success then
                print("[AE_ZoneResponse_DEBUG] Error processing zone entry: " .. tostring(result))
            end

        elseif command == "playerZoneExit" then
            -- PHASE 2: Handle zone exit command
            if not player or not args or not args.zoneId then
                print("[AE_ZoneResponse_DEBUG] Invalid zone exit command received")
                return
            end

            if not args.exitTime then
                print("[AE_ZoneResponse_DEBUG] Incomplete zone exit data")
                return
            end

            print("[AE_ZoneResponse_DEBUG] Received zone exit command - Player: " .. tostring(player:getOnlineID()) .. ", Zone: " .. args.zoneId)

            -- Process zone exit
            local success, result = pcall(function()
                AE_ZoneResponseSystem.onPlayerExitZone(player, args.zoneId, args.exitTime)
            end)

            if not success then
                print("[AE_ZoneResponse_DEBUG] Error processing zone exit: " .. tostring(result))
            end
        end
    end
end

-- Direct zone entry processing for SP environment
function AE_ZoneResponseSystem.processDirectZoneEntry(player, zone, currentTime)
    if not player or not zone then
        print("[AE_ZoneResponse_DEBUG] Invalid parameters for direct zone entry")
        return
    end

    print("[AE_ZoneResponse_DEBUG] Direct zone entry - Player: " .. tostring(player:getOnlineID()) .. ", Zone: " .. zone.id)

    local success, result = pcall(function()
        AE_ZoneResponseSystem.onPlayerEnterZone(player, zone, currentTime)
    end)

    if not success then
        print("[AE_ZoneResponse_DEBUG] Error in direct zone processing: " .. tostring(result))
    end
end

-- PHASE 2: Handle player exiting a zone
function AE_ZoneResponseSystem.onPlayerExitZone(player, zoneId, currentTime)
    print("[AE_ZoneResponse_DEBUG] Processing zone exit - Player: " .. tostring(player:getOnlineID()) .. ", Zone: " .. zoneId)

    local playerID = tostring(player:getOnlineID())

    local ZoneSpawningSystem = _G.AE_ZoneSpawningSystem
    if ZoneSpawningSystem and ZoneSpawningSystem.removePlayerFromActiveZone then
        ZoneSpawningSystem.removePlayerFromActiveZone(zoneId, playerID)
        print("[AE_ZoneResponse_DEBUG] Player removed from active zone: " .. zoneId)
    else
        print("[AE_ZoneResponse_DEBUG] WARNING: AE_ZoneSpawningSystem not available for zone exit")
    end
end

-- Direct zone exit processing for SP environment
function AE_ZoneResponseSystem.processDirectZoneExit(player, zoneId, currentTime)
    if not player or not zoneId then
        print("[AE_ZoneResponse_DEBUG] Invalid parameters for direct zone exit")
        return
    end

    print("[AE_ZoneResponse_DEBUG] Direct zone exit - Player: " .. tostring(player:getOnlineID()) .. ", Zone: " .. zoneId)

    local success, result = pcall(function()
        AE_ZoneResponseSystem.onPlayerExitZone(player, zoneId, currentTime)
    end)

    if not success then
        print("[AE_ZoneResponse_DEBUG] Error in direct zone exit processing: " .. tostring(result))
    end
end

-- Event registrations (SERVER AUTHORITY - following reference patterns)
print("[AE_ZoneResponse_DEBUG] Registering zone response system events")

if Events then
    if Events.OnGameStart then
        print("[AE_ZoneResponse_DEBUG] Registering OnGameStart event")
        Events.OnGameStart.Add(AE_ZoneResponseSystem.initialize)
    else
        print("[AE_ZoneResponse_DEBUG] WARNING: OnGameStart not available")
    end
    
    if Events.OnServerStarted then
        print("[AE_ZoneResponse_DEBUG] Registering OnServerStarted event")
        Events.OnServerStarted.Add(AE_ZoneResponseSystem.initialize)
    else
        print("[AE_ZoneResponse_DEBUG] WARNING: OnServerStarted not available")
    end
    
    if Events.OnGameEnd then
        print("[AE_ZoneResponse_DEBUG] Registering OnGameEnd shutdown")
        Events.OnGameEnd.Add(AE_ZoneResponseSystem.shutdown)
    end
    
    if Events.OnDisconnect then
        print("[AE_ZoneResponse_DEBUG] Registering OnDisconnect shutdown")
        Events.OnDisconnect.Add(AE_ZoneResponseSystem.shutdown)
    end
    
    if Events.OnClientCommand then
        Events.OnClientCommand.Add(onClientCommand)
        if AE_EnvironmentDetector.isMultiplayer() then
            print("[AE_ZoneResponse_DEBUG] Registered OnClientCommand for zone entry (MP)")
        else
            print("[AE_ZoneResponse_DEBUG] Registered OnClientCommand (SP - will not fire)")
        end
    else
        print("[AE_ZoneResponse_DEBUG] WARNING: OnClientCommand not available")
    end
else
    print("[AE_ZoneResponse_DEBUG] ERROR: Events table not available")
end

print("[AE_ZoneResponse_DEBUG] Zone response system events registered")

return AE_ZoneResponseSystem