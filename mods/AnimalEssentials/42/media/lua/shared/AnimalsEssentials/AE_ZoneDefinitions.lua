local AE_ZoneDefinitions = {}

-- Predefined spawn zones with exact coordinates (SHARED - available to client and server)
AE_ZoneDefinitions.spawnZones = {
    -- Animal Care Center zones
    {id = "ACC_1", minX = 3200, minY = 12088, maxX = 3288, maxY = 12243, enabled = true},
    {id = "ACC_2", minX = 3133, minY = 12005, maxX = 3288, maxY = 12083, enabled = true},
    {id = "ACC_3", minX = 3003, minY = 12048, maxX = 3079, maxY = 12196, enabled = true},
    {id = "ACC_4", minX = 3098, minY = 12087, maxX = 3195, maxY = 12157, enabled = true},
    {id = "ACC_5", minX = 3084, minY = 12032, maxX = 3130, maxY = 12060, enabled = true},
    
    -- Pony Roam-O zones
    {id = "PRO_1", minX = 8572, minY = 8498, maxX = 8594, maxY = 8528, enabled = true},
    {id = "PRO_2", minX = 8537, minY = 8514, maxX = 8545, maxY = 8526, enabled = true},
    
    -- Horse Place zones
    {id = "HP_1", minX = 5552, minY = 6425, maxX = 5612, maxY = 6494, enabled = true},
    {id = "HP_2", minX = 5628, minY = 6511, maxX = 5660, maxY = 6540, enabled = true},
    {id = "HP_3", minX = 5551, minY = 6585, maxX = 5623, maxY = 6592, enabled = true}
}

-- Zone categories for management
AE_ZoneDefinitions.zoneCategories = {
    animalCare = {"ACC_1", "ACC_2", "ACC_3", "ACC_4", "ACC_5"},
    ponyRoam = {"PRO_1", "PRO_2"},
    horsePlace = {"HP_1", "HP_2", "HP_3"}
}

-- Spawn configuration settings
AE_ZoneDefinitions.spawnSettings = {
    failureRate = 0.35,  -- 35% spawn failure chance
    minAnimals = 1,
    maxAnimals = 2,
    minSpawnInterval = 4,  -- hours
    maxSpawnInterval = 12, -- hours
    checkInterval = 0.167  -- 10 minutes in hours
}

-- Zone boundary checking utility (shared function)
function AE_ZoneDefinitions.isPlayerInZone(playerX, playerY, zone)
    return playerX >= zone.minX and playerX <= zone.maxX and
           playerY >= zone.minY and playerY <= zone.maxY
end

-- Fast distance approximation for spatial filtering (Manhattan distance)
function AE_ZoneDefinitions.getApproxDistanceToZone(playerX, playerY, zone)
    local centerX = (zone.minX + zone.maxX) / 2
    local centerY = (zone.minY + zone.maxY) / 2
    return math.abs(playerX - centerX) + math.abs(playerY - centerY)
end

-- Get zone by ID utility
function AE_ZoneDefinitions.getZoneById(zoneId)
    for _, zone in ipairs(AE_ZoneDefinitions.spawnZones) do
        if zone.id == zoneId then
            return zone
        end
    end
    return nil
end

-- Get enabled zones utility
function AE_ZoneDefinitions.getEnabledZones()
    local enabledZones = {}
    for _, zone in ipairs(AE_ZoneDefinitions.spawnZones) do
        if zone.enabled then
            table.insert(enabledZones, zone)
        end
    end
    return enabledZones
end

return AE_ZoneDefinitions