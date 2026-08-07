SpawnSelector = SpawnSelector or {}

SpawnSelector.REGION_NAME = "Spawn Selector"
SpawnSelector.STAGING_X = 12425
SpawnSelector.STAGING_Y = 3702
SpawnSelector.STAGING_Z = 0
SpawnSelector.SAFE_RADIUS = 10
SpawnSelector.ARRIVAL_SAFE_RADIUS = 20
SpawnSelector.ARRIVAL_GRACE_MS = 15000
SpawnSelector.MIN_Z = -17
SpawnSelector.MAX_Z = 29
SpawnSelector.LAYER_VALIDATION_MS = 10000
SpawnSelector.RANDOM_BUILDING_MAX_ATTEMPTS = 25
SpawnSelector.RANDOM_BUILDING_SCAN_ATTEMPTS = 200

SpawnSelector.RANDOM_REGIONS = {
    { minX = 11763, minY = 1213, maxX = 12500, maxY = 3503 },
    { minX = 12423, minY = 1202, maxX = 14694, maxY = 7444 },
    { minX = 4975, minY = 5234, maxX = 7467, maxY = 5871 },
    { minX = 9352, minY = 6631, maxX = 14625, maxY = 7469 },
    { minX = 135, minY = 5754, maxX = 7288, maxY = 14746 },
    { minX = 7393, minY = 7516, maxX = 12726, maxY = 14617 },
}

function SpawnSelector.isRandomSpawnAllowed(x, y)
    for _, region in ipairs(SpawnSelector.RANDOM_REGIONS) do
        if x >= region.minX
            and x <= region.maxX
            and y >= region.minY
            and y <= region.maxY then
            return true
        end
    end

    return false
end

function SpawnSelector.rollRandomPosition(bounds)
    local minX = math.max(bounds.minX, 135)
    local minY = math.max(bounds.minY, 1202)
    local maxX = math.min(bounds.maxX, 14694)
    local maxY = math.min(bounds.maxY, 14746)

    if minX > maxX or minY > maxY then
        return nil, nil
    end

    for attempt = 1, 1000 do
        local x = ZombRand(minX, maxX + 1)
        local y = ZombRand(minY, maxY + 1)
        if SpawnSelector.isRandomSpawnAllowed(x, y) then
            return x, y
        end
    end

    return nil, nil
end

function SpawnSelector.rollRandomBuildingTile(bounds)
    local world = getWorld()
    local metaGrid = world and world:getMetaGrid()
    local buildings = metaGrid and metaGrid:getBuildings()
    if not buildings or buildings:size() == 0 then
        return nil, nil
    end

    local minX = math.max(bounds and bounds.minX or 135, 135)
    local minY = math.max(bounds and bounds.minY or 1202, 1202)
    local maxX = math.min(bounds and bounds.maxX or 14694, 14694)
    local maxY = math.min(bounds and bounds.maxY or 14746, 14746)
    if minX > maxX or minY > maxY then
        return nil, nil
    end

    local buildingCount = buildings:size()
    for attempt = 1, SpawnSelector.RANDOM_BUILDING_SCAN_ATTEMPTS do
        local building = buildings:get(ZombRand(buildingCount))
        local rooms = building and building:getRooms()
        local roomCount = rooms and rooms:size() or 0
        if roomCount > 0 then
            local room = rooms:get(ZombRand(roomCount))
            local roomMinX, roomMinY = room:getX(), room:getY()
            local roomMaxX, roomMaxY = room:getX2(), room:getY2()
            local roomZ = room:getZ()
            if roomMaxX > roomMinX
                and roomMaxY > roomMinY
                and roomZ == 0
                and roomMinX >= minX and roomMaxX <= maxX
                and roomMinY >= minY and roomMaxY <= maxY
                and SpawnSelector.isRandomSpawnAllowed(roomMinX, roomMinY) then
                for _ = 1, 20 do
                    local x = ZombRand(roomMinX, roomMaxX + 1)
                    local y = ZombRand(roomMinY, roomMaxY + 1)
                    if room:isInside(x, y, roomZ) then
                        return x, y
                    end
                end
            end
        end
    end

    return nil, nil
end

local function addSpawnSelectorRegion(regions)
    for _, region in ipairs(regions) do
        if region.name == SpawnSelector.REGION_NAME then
            return
        end
    end

    table.insert(regions, 1, {
        name = SpawnSelector.REGION_NAME,
        points = {
            unemployed = {
                {
                    posX = SpawnSelector.STAGING_X,
                    posY = SpawnSelector.STAGING_Y,
                    posZ = SpawnSelector.STAGING_Z,
                },
            },
        },
    })
end

Events.OnSpawnRegionsLoaded.Add(addSpawnSelectorRegion)
