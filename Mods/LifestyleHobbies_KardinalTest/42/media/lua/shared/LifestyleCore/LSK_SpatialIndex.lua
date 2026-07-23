LSKSpatialIndex = LSKSpatialIndex or {}

local Index = LSKSpatialIndex

Index.CHUNK_SIZE = 10
Index.MAX_ENTRIES = 2048
Index.MAX_PER_CHUNK = 96
Index._chunks = Index._chunks or {}
Index._entries = Index._entries or {}
Index._entryOrder = Index._entryOrder or {}
Index._count = Index._count or 0
Index._serial = Index._serial or 0
Index._pruneCursor = Index._pruneCursor or 1
Index._legacyList = Index._legacyList or nil
Index._metrics = Index._metrics or {
    registered = 0,
    removed = 0,
    pruned = 0,
    evicted = 0,
    queries = 0,
}

local NAME_CATEGORIES = {
    ["Jukebox"] = { "jukebox" },
    ["Disco Ball"] = { "disco" },
    ["Disco Floor"] = { "disco" },
    ["Hygienator"] = { "hygiene" },
    ["Sculpture Ice"] = { "art" },
    ["Sculpture Lamp"] = { "art" },
    ["GF Clock"] = { "invention" },
    ["StationWork"] = { "invention" },
    ["FoodSynthesizer"] = { "invention" },
    ["DrinkingBuddy"] = { "invention" },
}

local function chunkCoordinate(value)
    return math.floor(value / Index.CHUNK_SIZE)
end

local function chunkKey(x, y, z)
    return tostring(chunkCoordinate(x)) .. ":" .. tostring(chunkCoordinate(y)) .. ":" .. tostring(z)
end

local function getProperty(object, property)
    local sprite = object and object.getSprite and object:getSprite()
    local properties = sprite and sprite:getProperties()
    if properties and properties:has(property) then
        return properties:get(property)
    end
    return nil
end

local function isValid(object)
    if not object or not object.getSquare then
        return false
    end
    local ok, square = pcall(object.getSquare, object)
    return ok and square ~= nil
end

local function removeFromLegacyList(object)
    local list = Index._legacyList
    if not list then
        return
    end
    for index = #list, 1, -1 do
        if list[index] == object then
            table.remove(list, index)
        end
    end
end

local function addToLegacyList(object)
    local list = Index._legacyList
    if not list then
        return
    end
    for index = 1, #list do
        if list[index] == object then
            return
        end
    end
    table.insert(list, object)
end

local function removeEntry(entry, wasPruned, wasEvicted)
    if not entry or not Index._entries[entry.object] then
        return false
    end
    local bucket = Index._chunks[entry.chunk]
    if bucket then
        bucket.items[entry.object] = nil
        bucket.count = math.max(0, bucket.count - 1)
        if bucket.count == 0 then
            Index._chunks[entry.chunk] = nil
        end
    end
    Index._entries[entry.object] = nil
    for index = #Index._entryOrder, 1, -1 do
        if Index._entryOrder[index] == entry.object then
            table.remove(Index._entryOrder, index)
            if Index._pruneCursor > index then
                Index._pruneCursor = Index._pruneCursor - 1
            end
            break
        end
    end
    Index._count = math.max(0, Index._count - 1)
    removeFromLegacyList(entry.object)
    Index._metrics.removed = Index._metrics.removed + 1
    if wasPruned then
        Index._metrics.pruned = Index._metrics.pruned + 1
    end
    if wasEvicted then
        Index._metrics.evicted = Index._metrics.evicted + 1
    end
    return true
end

local function evictOldest(bucket)
    local oldest = nil
    if bucket then
        for _, entry in pairs(bucket.items) do
            if not oldest or entry.serial < oldest.serial then
                oldest = entry
            end
        end
    else
        local object = Index._entryOrder[1]
        oldest = object and Index._entries[object]
    end
    if oldest then
        removeEntry(oldest, false, true)
    end
end

function Index.classify(object)
    local customName = getProperty(object, "CustomName")
    local groupName = getProperty(object, "GroupName")
    local name = customName or groupName
    local mapped = name and NAME_CATEGORIES[name]
    if not mapped then
        return nil, customName, groupName
    end
    local categories = { interactive = true }
    for index = 1, #mapped do
        categories[mapped[index]] = true
    end
    return categories, customName, groupName
end

function Index.configureLegacyList(list)
    Index._legacyList = list
    if list then
        for object, _ in pairs(Index._entries) do
            addToLegacyList(object)
        end
    end
end

function Index.register(object, categories)
    if not isValid(object) then
        return false
    end
    categories = categories or Index.classify(object)
    if not categories then
        if Index._entries[object] then
            Index.unregister(object)
        end
        return false
    end

    local x = object:getX()
    local y = object:getY()
    local z = object:getZ()
    local key = chunkKey(x, y, z)
    local existing = Index._entries[object]
    if existing then
        if existing.chunk ~= key then
            removeEntry(existing, false, false)
        else
            existing.categories = categories
            existing.x = x
            existing.y = y
            existing.z = z
            addToLegacyList(object)
            return true
        end
    end

    local bucket = Index._chunks[key]
    if not bucket then
        bucket = { items = {}, count = 0 }
        Index._chunks[key] = bucket
    end
    if bucket.count >= Index.MAX_PER_CHUNK then
        evictOldest(bucket)
    end
    if Index._count >= Index.MAX_ENTRIES then
        evictOldest(nil)
    end

    Index._serial = Index._serial + 1
    local entry = {
        object = object,
        categories = categories,
        x = x,
        y = y,
        z = z,
        chunk = key,
        serial = Index._serial,
    }
    bucket.items[object] = entry
    bucket.count = bucket.count + 1
    Index._entries[object] = entry
    table.insert(Index._entryOrder, object)
    Index._count = Index._count + 1
    Index._metrics.registered = Index._metrics.registered + 1
    addToLegacyList(object)
    return true
end

function Index.unregister(object)
    return removeEntry(Index._entries[object], false, false)
end

function Index.prune(maxChecks)
    local checked = 0
    local removed = 0
    maxChecks = maxChecks or Index.MAX_ENTRIES
    while checked < maxChecks and #Index._entryOrder > 0 do
        if Index._pruneCursor > #Index._entryOrder then
            Index._pruneCursor = 1
        end
        local object = Index._entryOrder[Index._pruneCursor]
        local entry = Index._entries[object]
        checked = checked + 1
        if entry and not isValid(entry.object) then
            if removeEntry(entry, true, false) then
                removed = removed + 1
            end
        else
            Index._pruneCursor = Index._pruneCursor + 1
        end
    end
    return removed
end

function Index.queryNearby(category, x, y, z, radius, result)
    result = result or {}
    radius = radius or 10
    local minChunkX = chunkCoordinate(x - radius)
    local maxChunkX = chunkCoordinate(x + radius)
    local minChunkY = chunkCoordinate(y - radius)
    local maxChunkY = chunkCoordinate(y + radius)
    local radiusSquared = radius * radius
    Index._metrics.queries = Index._metrics.queries + 1

    for chunkX = minChunkX, maxChunkX do
        for chunkY = minChunkY, maxChunkY do
            local key = tostring(chunkX) .. ":" .. tostring(chunkY) .. ":" .. tostring(z)
            local bucket = Index._chunks[key]
            if bucket then
                for _, entry in pairs(bucket.items) do
                    if (not category or entry.categories[category]) and isValid(entry.object) then
                        local deltaX = entry.x - x
                        local deltaY = entry.y - y
                        if deltaX * deltaX + deltaY * deltaY <= radiusSquared then
                            table.insert(result, entry.object)
                        end
                    end
                end
            end
        end
    end
    return result
end

function Index.queryNearbyPlayer(category, player, radius, result)
    if not player then
        return result or {}
    end
    return Index.queryNearby(category, player:getX(), player:getY(), player:getZ(), radius, result)
end

function Index.getNearbyRecipients(x, y, z, radius, predicate, result)
    result = result or {}
    radius = radius or 10
    local radiusSquared = radius * radius
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers()
    if onlinePlayers and onlinePlayers:size() > 0 then
        for index = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(index)
            if player and not player:isDead() and player:getZ() == z then
                local deltaX = player:getX() - x
                local deltaY = player:getY() - y
                if deltaX * deltaX + deltaY * deltaY <= radiusSquared and
                (not predicate or predicate(player)) then
                    table.insert(result, player)
                end
            end
        end
    else
        local player = getPlayer and getPlayer()
        if player and not player:isDead() and player:getZ() == z then
            local deltaX = player:getX() - x
            local deltaY = player:getY() - y
            if deltaX * deltaX + deltaY * deltaY <= radiusSquared and
            (not predicate or predicate(player)) then
                table.insert(result, player)
            end
        end
    end
    return result
end

function Index.getNearbyRecipientsForObject(object, radius, predicate, result)
    if not object or not isValid(object) then
        return result or {}
    end
    return Index.getNearbyRecipients(
        object:getX(),
        object:getY(),
        object:getZ(),
        radius,
        predicate,
        result
    )
end

function Index.getMetrics()
    local result = {
        entries = Index._count,
        chunks = 0,
    }
    for _ in pairs(Index._chunks) do
        result.chunks = result.chunks + 1
    end
    for key, value in pairs(Index._metrics) do
        result[key] = value
    end
    return result
end

return Index
