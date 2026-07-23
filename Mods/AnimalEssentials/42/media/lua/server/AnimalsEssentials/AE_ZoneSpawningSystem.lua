local AE_ZoneSpawningSystem = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
local AE_ZoneDefinitions = require("AnimalsEssentials/AE_ZoneDefinitions")

local activeZones = {}

-- PHASE 1: Weight-based spawn token system
local spawnWeightSystem = {
    currentWeights = 0,
    maxWeights = 5,
    timerActive = true,
    lastWeightGeneration = 0,
    nextWeightGenerationTime = 0,
    minGenerationInterval = 0.25,
    maxGenerationInterval = 8
}

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
function AE_ZoneSpawningSystem.calculateZoneBoundaries(corner1, corner2)
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

-- Random position generation within zone boundaries
function AE_ZoneSpawningSystem.getRandomPositionInZone(zoneBounds)
    local x = ZombRand(zoneBounds.minX, zoneBounds.maxX + 1)
    local y = ZombRand(zoneBounds.minY, zoneBounds.maxY + 1)
    return x, y, zoneBounds.z
end

-- Weighted variant selection (exact same system as client)
function AE_ZoneSpawningSystem.selectWeightedVariant()
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

-- Animal spawning with proper breed handling
function AE_ZoneSpawningSystem.spawnAnimalInZone(variant, x, y, z)
    if not AnimalDefinitions then
        print("[AE_ZoneSpawning] SERVER: ERROR: AnimalDefinitions is nil")
        return nil
    end
    
    local animalDef = AnimalDefinitions.getDef(variant)
    if not animalDef then
        print("[AE_ZoneSpawning] SERVER: ERROR: Could not get animal definition for " .. tostring(variant))
        return nil
    end
    
    -- Defensive method existence check for getBreeds
    if not animalDef.getBreeds then
        print("[AE_ZoneSpawning] SERVER: ERROR: getBreeds method not available for " .. tostring(variant))
        return nil
    end
    
    local breeds = animalDef:getBreeds()
    if not breeds then
        print("[AE_ZoneSpawning] SERVER: ERROR: getBreeds returned nil for " .. tostring(variant))
        return nil
    end
    
    -- Defensive method existence check for size
    if not breeds.size then
        print("[AE_ZoneSpawning] SERVER: ERROR: breeds size method not available")
        return nil
    end
    
    if breeds:size() == 0 then
        print("[AE_ZoneSpawning] SERVER: ERROR: No breeds available for " .. tostring(variant))
        return nil
    end
    
    local breedObj = nil
    
    -- System-specific breed selection
    if variant == "babysmokeykitten" or variant == "smokeyboi" or variant == "smokeygirly" then
        -- Smokey system - use "midnight" breed
        -- Defensive method existence check for getBreedByName
        if not animalDef.getBreedByName then
            print("[AE_ZoneSpawning] SERVER: ERROR: getBreedByName method not available")
            -- Defensive method existence check for get
            if not breeds.get then
                print("[AE_ZoneSpawning] SERVER: ERROR: breeds get method not available")
                return nil
            end
            breedObj = breeds:get(0)
        else
            breedObj = animalDef:getBreedByName("midnight")
            if not breedObj then
                print("[AE_ZoneSpawning] SERVER: WARNING: midnight breed not found for " .. tostring(variant) .. ", using first available")
                -- Defensive method existence check for get
                if not breeds.get then
                    print("[AE_ZoneSpawning] SERVER: ERROR: breeds get method not available")
                    return nil
                end
                breedObj = breeds:get(0)
            else
                print("[AE_ZoneSpawning] SERVER: Using midnight breed for " .. tostring(variant))
            end
        end
    else
        -- Standard and manx systems - use first available breed
        -- Defensive method existence check for get
        if not breeds.get then
            print("[AE_ZoneSpawning] SERVER: ERROR: breeds get method not available")
            return nil
        end
        breedObj = breeds:get(0)
        print("[AE_ZoneSpawning] SERVER: Using first available breed for " .. tostring(variant))
    end
    
    if not breedObj then
        print("[AE_ZoneSpawning] SERVER: ERROR: No breed object available for " .. tostring(variant))
        return nil
    end
    
    
    -- Create animal at specified coordinates
    local cell = getCell()
    if not cell then
        print("[AE_ZoneSpawning] SERVER: ERROR: Could not get cell")
        return nil
    end
    
    local animal = addAnimal(cell, x, y, z, variant, breedObj)
    if animal then
        print("[AE_ZoneSpawning] SERVER: Successfully spawned " .. tostring(variant) .. " at (" .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) .. ")")
        
        if animal.addToWorld then
            animal:addToWorld()
        end
        
        return animal
    else
        print("[AE_ZoneSpawning] SERVER: ERROR: addAnimal failed for " .. tostring(variant))
        return nil
    end
end

function AE_ZoneSpawningSystem.addPlayerToActiveZone(zoneID, playerID, zoneData, cachedCoords)
    local currentTime = getGameTime():getWorldAgeHours()

    if not activeZones[zoneID] then
        activeZones[zoneID] = {
            zoneData = zoneData,
            players = {},
            activeSince = currentTime,
            firstEntrySpawnExecuted = false
        }
        print("[AE_ZoneSpawning] Zone " .. zoneID .. " activated")
    end

    if not activeZones[zoneID].players[playerID] then
        local minMinutes = 10
        local maxMinutes = 30
        local randomMinutes = minMinutes + ZombRand(maxMinutes - minMinutes + 1)
        local hoursToAdd = randomMinutes / 60

        activeZones[zoneID].players[playerID] = {
            entryTime = currentTime,
            cachedCoordinates = cachedCoords or {x = 0, y = 0, z = 0},
            lastCoordinateUpdate = currentTime,
            nextRefreshTime = currentTime + hoursToAdd
        }

        print("[AE_ZoneSpawning] Player " .. playerID .. " entered zone " .. zoneID)
        print("[AE_ZoneSpawning] Cached coordinates: (" ..
              tostring(activeZones[zoneID].players[playerID].cachedCoordinates.x) .. ", " ..
              tostring(activeZones[zoneID].players[playerID].cachedCoordinates.y) .. ", " ..
              tostring(activeZones[zoneID].players[playerID].cachedCoordinates.z) .. ")")
        print("[AE_ZoneSpawning] Next coordinate refresh in " .. string.format("%.2f", hoursToAdd * 60) .. " minutes")
    end
end

function AE_ZoneSpawningSystem.removePlayerFromActiveZone(zoneID, playerID)
    if not activeZones[zoneID] then
        return
    end

    if activeZones[zoneID].players[playerID] then
        activeZones[zoneID].players[playerID] = nil
        activeZones[zoneID].lastUpdate = getTimestamp()
        print("[AE_ZoneSpawning] Player " .. playerID .. " left zone " .. zoneID)

        local playerCount = 0
        for _ in pairs(activeZones[zoneID].players) do
            playerCount = playerCount + 1
        end

        if playerCount == 0 then
            activeZones[zoneID] = nil
            print("[AE_ZoneSpawning] Zone " .. zoneID .. " deactivated (no players)")
        end
    end
end

function AE_ZoneSpawningSystem.getActiveZones()
    local zones = {}
    for zoneID, data in pairs(activeZones) do
        if data.zoneData.enabled then
            table.insert(zones, data.zoneData)
        end
    end
    return zones
end

function AE_ZoneSpawningSystem.getAllPlayersInZones()
    local playerCount = 0
    for zoneID, data in pairs(activeZones) do
        for _ in pairs(data.players) do
            playerCount = playerCount + 1
        end
    end
    return playerCount
end




-- PHASE 3: Coordinate caching and refresh system

function AE_ZoneSpawningSystem.refreshZoneCoordinates(zoneID, playerID, player)
    if not activeZones[zoneID] or not activeZones[zoneID].players[playerID] then
        return false
    end

    local currentTime = getGameTime():getWorldAgeHours()
    local playerData = activeZones[zoneID].players[playerID]

    local newCoords = {
        x = player:getX(),
        y = player:getY(),
        z = player:getZ()
    }

    playerData.cachedCoordinates = newCoords
    playerData.lastCoordinateUpdate = currentTime

    local minMinutes = 10
    local maxMinutes = 30
    local randomMinutes = minMinutes + ZombRand(maxMinutes - minMinutes + 1)
    local hoursToAdd = randomMinutes / 60

    playerData.nextRefreshTime = currentTime + hoursToAdd

    print("[AE_ZoneSpawning] Refreshed coordinates for player " .. playerID .. " in zone " .. zoneID)
    print("[AE_ZoneSpawning] New coordinates: (" ..
          tostring(newCoords.x) .. ", " ..
          tostring(newCoords.y) .. ", " ..
          tostring(newCoords.z) .. ")")
    print("[AE_ZoneSpawning] Next refresh in " .. string.format("%.2f", hoursToAdd * 60) .. " minutes")

    return true
end

function AE_ZoneSpawningSystem.checkCoordinateRefresh()
    local currentTime = getGameTime():getWorldAgeHours()
    local refreshCount = 0

    for zoneID, zoneData in pairs(activeZones) do
        for playerID, playerData in pairs(zoneData.players) do
            if currentTime >= playerData.nextRefreshTime then
                local player = nil

                if AE_EnvironmentDetector.isSinglePlayer() then
                    player = getSpecificPlayer(0)
                else
                    if not isClient() then
                        local onlinePlayers = getOnlinePlayers()
                        if onlinePlayers then
                            for i = 0, onlinePlayers:size() - 1 do
                                local p = onlinePlayers:get(i)
                                if p and tostring(p:getOnlineID()) == playerID then
                                    player = p
                                    break
                                end
                            end
                        end
                    end
                end

                if player then
                    AE_ZoneSpawningSystem.refreshZoneCoordinates(zoneID, playerID, player)
                    refreshCount = refreshCount + 1
                else
                    print("[AE_ZoneSpawning] WARNING: Could not find player " .. playerID .. " for coordinate refresh")
                end
            end
        end
    end

    if refreshCount > 0 then
        print("[AE_ZoneSpawning] Coordinate refresh cycle complete - " .. refreshCount .. " players updated")
    end
end

-- PHASE 1: Weight system functions

function AE_ZoneSpawningSystem.generateSpawnWeights()
    local currentTime = getGameTime():getWorldAgeHours()

    local minHours = spawnWeightSystem.minGenerationInterval
    local maxHours = spawnWeightSystem.maxGenerationInterval
    local range = maxHours - minHours
    local hoursToAdd = minHours + (ZombRand(math.floor(range * 100)) / 100)

    spawnWeightSystem.nextWeightGenerationTime = currentTime + hoursToAdd

    local weightsToAdd = 1 + ZombRand(3)

    local oldWeights = spawnWeightSystem.currentWeights
    spawnWeightSystem.currentWeights = math.min(
        spawnWeightSystem.currentWeights + weightsToAdd,
        spawnWeightSystem.maxWeights
    )

    local actualAdded = spawnWeightSystem.currentWeights - oldWeights

    print("[AE_WeightSystem] Generated " .. actualAdded .. " weights (" ..
          oldWeights .. " -> " .. spawnWeightSystem.currentWeights .. ")")
    print("[AE_WeightSystem] Next generation in " .. string.format("%.2f", hoursToAdd) .. " hours")

    if spawnWeightSystem.currentWeights >= spawnWeightSystem.maxWeights then
        spawnWeightSystem.timerActive = false
        print("[AE_WeightSystem] Max weights reached (5), timer dormant")
    end

    spawnWeightSystem.lastWeightGeneration = currentTime

    AE_ZoneSpawningSystem.saveWeightSystemState()
end

function AE_ZoneSpawningSystem.consumeSpawnWeight()
    if spawnWeightSystem.currentWeights > 0 then
        spawnWeightSystem.currentWeights = spawnWeightSystem.currentWeights - 1

        print("[AE_WeightSystem] Weight consumed (" ..
              (spawnWeightSystem.currentWeights + 1) .. " -> " ..
              spawnWeightSystem.currentWeights .. ")")

        if not spawnWeightSystem.timerActive then
            spawnWeightSystem.timerActive = true
            AE_ZoneSpawningSystem.scheduleNextWeightGeneration()
            print("[AE_WeightSystem] Timer reactivated")
        end

        AE_ZoneSpawningSystem.saveWeightSystemState()
        return true
    else
        print("[AE_WeightSystem] No weights available")
        return false
    end
end

function AE_ZoneSpawningSystem.refundSpawnWeight()
    if spawnWeightSystem.currentWeights < spawnWeightSystem.maxWeights then
        spawnWeightSystem.currentWeights = spawnWeightSystem.currentWeights + 1

        print("[AE_WeightSystem] Weight refunded (" ..
              (spawnWeightSystem.currentWeights - 1) .. " -> " ..
              spawnWeightSystem.currentWeights .. ")")

        AE_ZoneSpawningSystem.saveWeightSystemState()
    end
end

function AE_ZoneSpawningSystem.scheduleNextWeightGeneration()
    local currentTime = getGameTime():getWorldAgeHours()
    local minHours = spawnWeightSystem.minGenerationInterval
    local maxHours = spawnWeightSystem.maxGenerationInterval
    local range = maxHours - minHours
    local hoursToAdd = minHours + (ZombRand(math.floor(range * 100)) / 100)

    spawnWeightSystem.nextWeightGenerationTime = currentTime + hoursToAdd

    print("[AE_WeightSystem] Next weight generation scheduled in " ..
          string.format("%.2f", hoursToAdd) .. " hours")

    AE_ZoneSpawningSystem.saveWeightSystemState()
end

function AE_ZoneSpawningSystem.checkWeightGenerationTimer()
    if not spawnWeightSystem.timerActive then
        return
    end

    local currentTime = getGameTime():getWorldAgeHours()

    if currentTime >= spawnWeightSystem.nextWeightGenerationTime then
        AE_ZoneSpawningSystem.generateSpawnWeights()
    end
end

function AE_ZoneSpawningSystem.saveWeightSystemState()
    local modData = ModData.getOrCreate("AE_ZoneSpawning_Weights")
    modData.currentWeights = spawnWeightSystem.currentWeights
    modData.timerActive = spawnWeightSystem.timerActive
    modData.lastWeightGeneration = spawnWeightSystem.lastWeightGeneration
    modData.nextWeightGenerationTime = spawnWeightSystem.nextWeightGenerationTime

    if AE_EnvironmentDetector.isSinglePlayer() then
        ModData.add("AE_ZoneSpawning_Weights", modData)
    else
        if not isClient() then
            ModData.add("AE_ZoneSpawning_Weights", modData)
        end
    end
end

function AE_ZoneSpawningSystem.loadWeightSystemState()
    local modData = ModData.getOrCreate("AE_ZoneSpawning_Weights")

    spawnWeightSystem.currentWeights = modData.currentWeights or 0
    spawnWeightSystem.timerActive = modData.timerActive
    if spawnWeightSystem.timerActive == nil then
        spawnWeightSystem.timerActive = true
    end
    spawnWeightSystem.lastWeightGeneration = modData.lastWeightGeneration or 0
    spawnWeightSystem.nextWeightGenerationTime = modData.nextWeightGenerationTime or 0

    print("[AE_WeightSystem] Loaded state - Weights: " .. spawnWeightSystem.currentWeights ..
          ", Timer active: " .. tostring(spawnWeightSystem.timerActive))
end

function AE_ZoneSpawningSystem.initializeWeightSystem()
    print("[AE_WeightSystem] Initializing weight generation system")

    AE_ZoneSpawningSystem.loadWeightSystemState()

    if spawnWeightSystem.nextWeightGenerationTime == 0 then
        AE_ZoneSpawningSystem.scheduleNextWeightGeneration()
        print("[AE_WeightSystem] First-time initialization, timer scheduled")
    else
        print("[AE_WeightSystem] Continuing from saved state")
    end
end


function AE_ZoneSpawningSystem.initializeZoneTracking()
    print("[AE_ZoneSpawning] SERVER: Zone tracking now event-driven (entry/exit commands only)")
end

function AE_ZoneSpawningSystem.Initialize()
    print("[AE_ZoneSpawning] SERVER: Initializing weight-based zone spawning system")

    AE_ZoneSpawningSystem.initializeWeightSystem()
    AE_ZoneSpawningSystem.initializeZoneTracking()

    if Events.EveryHours then
        Events.EveryHours.Add(AE_ZoneSpawningSystem.checkWeightGenerationTimer)
        Events.EveryHours.Add(AE_ZoneSpawningSystem.checkCoordinateRefresh)
        print("[AE_ZoneSpawning] SERVER: Registered EveryHours events for weight generation and coordinate refresh")
    else
        print("[AE_ZoneSpawning] SERVER: WARNING - Events.EveryHours not available")
    end

    print("[AE_ZoneSpawning] SERVER: System initialized - event-driven architecture active")
end


local function onServerCommand(module, command, player, args)
    if module == "AE_ZoneSpawning" and command == "spawnAnimal" then
        if not player or not args then
            return
        end

        if not args.x or not args.y or not args.z then
            return
        end

        local radius = args.radius or 3
        local variant = AE_ZoneSpawningSystem.selectWeightedVariant()

        local zoneBounds = {
            minX = args.x - radius,
            maxX = args.x + radius,
            minY = args.y - radius,
            maxY = args.y + radius,
            z = args.z
        }

        local x, y, z = AE_ZoneSpawningSystem.getRandomPositionInZone(zoneBounds)

        AE_ZoneSpawningSystem.spawnAnimalInZone(variant, x, y, z)
    end
end

if Events and Events.OnClientCommand then
    Events.OnClientCommand.Add(onServerCommand)
end

return AE_ZoneSpawningSystem