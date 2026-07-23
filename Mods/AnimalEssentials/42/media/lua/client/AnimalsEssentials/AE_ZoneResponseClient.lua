local AE_ZoneDefinitions = require("AnimalsEssentials/AE_ZoneDefinitions")

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

-- SP direct access to zone response system (deferred loading for SP environment)
local AE_ZoneResponseSystem = nil
local function getZoneResponseSystem()
    if not AE_ZoneResponseSystem and AE_EnvironmentDetector.isSinglePlayer() then
        local success, result = pcall(function()
            return require("AnimalsEssentials/AE_ZoneResponseSystem")
        end)
        if success and result then
            AE_ZoneResponseSystem = result
        end
    end
    return AE_ZoneResponseSystem
end

local AE_ZoneResponseClient = {}

-- Movement tracking state
local lastPlayerPosition = nil
local lastZoneCheck = 0

-- PHASE 2: Track which zones player is currently in
local playerActiveZones = {}

-- Movement threshold (tiles) - only send commands on significant movement
local MOVEMENT_THRESHOLD = 5
-- Zone check cooldown (seconds) - prevent spam
local ZONE_CHECK_COOLDOWN = 3
-- Zone check interval (seconds) - reduce OnPlayerUpdate frequency
local ZONE_CHECK_INTERVAL = 1.5
-- Maximum distance for zone proximity filtering (tiles)
local MAX_ZONE_PROXIMITY = 100

-- PHASE 2: Entry-only zone detection with exit tracking
local function checkPlayerZones(player)
    if not player or player:isDead() then
        return
    end

    local currentTime = getGameTime():getWorldAgeHours()
    local playerX, playerY = player:getX(), player:getY()

    -- Check movement threshold
    local hasMovedSignificantly = false

    if not lastPlayerPosition then
        hasMovedSignificantly = true
        lastPlayerPosition = {x = playerX, y = playerY}
    else
        local distance = math.sqrt((playerX - lastPlayerPosition.x)^2 + (playerY - lastPlayerPosition.y)^2)
        if distance >= MOVEMENT_THRESHOLD then
            hasMovedSignificantly = true
            lastPlayerPosition = {x = playerX, y = playerY}
        end
    end

    -- Skip if no significant movement or cooldown active
    if not hasMovedSignificantly then
        return
    end

    if currentTime - lastZoneCheck < (ZONE_CHECK_COOLDOWN / 3600) then
        return
    end

    lastZoneCheck = currentTime

    -- Track current zones player is in
    local currentZones = {}

    -- Check all zones for entry/exit
    for _, zone in ipairs(AE_ZoneDefinitions.spawnZones) do
        if zone.enabled then
            local distanceToZone = AE_ZoneDefinitions.getApproxDistanceToZone(playerX, playerY, zone)
            if distanceToZone <= MAX_ZONE_PROXIMITY then
                if AE_ZoneDefinitions.isPlayerInZone(playerX, playerY, zone) then
                    currentZones[zone.id] = true

                    -- Check if this is a NEW entry
                    if not playerActiveZones[zone.id] then
                        print("[AE_ZoneClient_DEBUG] Player entered zone: " .. zone.id)

                        playerActiveZones[zone.id] = true

                        if AE_EnvironmentDetector.isMultiplayer() then
                            sendClientCommand("AE_ZoneSystem", "playerZoneEntry", {
                                x = playerX,
                                y = playerY,
                                z = player:getZ(),
                                zoneId = zone.id,
                                entryTime = currentTime
                            })
                        else
                            local zoneSystem = getZoneResponseSystem()
                            if zoneSystem and zoneSystem.processDirectZoneEntry then
                                zoneSystem.processDirectZoneEntry(player, zone, currentTime)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Check for zone exits
    for zoneId, wasInZone in pairs(playerActiveZones) do
        if wasInZone and not currentZones[zoneId] then
            print("[AE_ZoneClient_DEBUG] Player exited zone: " .. zoneId)

            playerActiveZones[zoneId] = nil

            if AE_EnvironmentDetector.isMultiplayer() then
                sendClientCommand("AE_ZoneSystem", "playerZoneExit", {
                    zoneId = zoneId,
                    exitTime = currentTime
                })
            else
                local zoneSystem = getZoneResponseSystem()
                if zoneSystem and zoneSystem.processDirectZoneExit then
                    zoneSystem.processDirectZoneExit(player, zoneId, currentTime)
                end
            end
        end
    end
end

-- Event-driven client movement monitoring (following AnimalCollectors defensive pattern)
local function onPlayerUpdate()
    local player = getSpecificPlayer(0)
    if player then
        local success, result = pcall(function()
            checkPlayerZones(player)
        end)
        
        if not success then
            print("[AE_ZoneClient_DEBUG] Error in zone check: " .. tostring(result))
        end
    end
end

-- System initialization
local function initialize()
    print("[AE_ZoneClient_DEBUG] Initializing client-side zone movement detection")

    -- Reset state
    lastPlayerPosition = nil
    lastZoneCheck = 0
    playerActiveZones = {}

    print("[AE_ZoneClient_DEBUG] Zone movement detection initialized with entry/exit tracking")
end

-- Coordinator-triggered zone check for hybrid approach
function AE_ZoneResponseClient.performZoneCheck(player)
    if not player then
        player = getSpecificPlayer(0)
    end
    
    if not player then
        return false
    end
    
    local success, result = pcall(function()
        checkPlayerZones(player)
        return true
    end)
    
    if not success then
        print("[AE_ZoneClient_DEBUG] Error in coordinator-triggered zone check: " .. tostring(result))
        return false
    end
    
    return result
end

-- Timer-based zone checking function
local function timerBasedZoneCheck()
    local player = getSpecificPlayer(0)
    if player then
        local success, result = pcall(function()
            checkPlayerZones(player)
        end)
        if not success then
            print("[AE_ZoneClient_DEBUG] Error in timer-based zone check: " .. tostring(result))
        end
    end
end

-- Cleanup function
local function shutdown()
    print("[AE_ZoneClient_DEBUG] Shutting down client-side zone detection")

    if Events and Events.EveryTenMinutes then
        Events.EveryTenMinutes.Remove(timerBasedZoneCheck)
    end

    if Events and Events.OnPlayerUpdate then
        Events.OnPlayerUpdate.Remove(onPlayerUpdate)
    end

    lastPlayerPosition = nil
    lastZoneCheck = 0
    playerActiveZones = {}
end

-- Event registrations (CLIENT-SIDE - following reference patterns)
print("[AE_ZoneClient_DEBUG] Registering client zone detection events")

if Events then
    if Events.OnGameStart then
        Events.OnGameStart.Add(initialize)
    end
    
    if Events.OnGameEnd then
        Events.OnGameEnd.Add(shutdown)
    end
    
    if Events.OnDisconnect then
        Events.OnDisconnect.Add(shutdown)
    end
else
    print("[AE_ZoneClient_DEBUG] ERROR: Events table not available")
end

print("[AE_ZoneClient_DEBUG] Client zone detection system loaded")

return AE_ZoneResponseClient