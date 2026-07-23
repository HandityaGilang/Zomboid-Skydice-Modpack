DCS_Objects = DCS_Objects or {}

local FALLBACK_SPRITES = {
    visit = "vegetation_ornamental_01_48",
    quest = "location_business_bank_01_69",
    trader = "appliances_com_01_52",
}

local function utcDay() return os.date("!%Y%m%d") end

local function coordKey(x, y, z)
    return math.floor(x) .. "," .. math.floor(y) .. "," .. math.floor(z or 0)
end

local function objectCfg(t)
    local cfgs = DCS_Challenges and DCS_Challenges.ObjectSprites
    return cfgs and cfgs[t] or nil
end

local function spriteFor(entry)
    if entry.sprite then return entry.sprite end
    local cfg = objectCfg(entry.type)
    if cfg then
        local d = cfg.default or "south"
        local s = cfg[d] or cfg.south or cfg.west or cfg.north or cfg.east
        if s then return s end
    end
    local def = DCS_Challenges and DCS_Challenges.DefaultSprites
    if def and def[entry.type] then return def[entry.type] end
    return FALLBACK_SPRITES[entry.type] or FALLBACK_SPRITES.visit
end

local function scanNear(cell, x, y, z, radius, pred)
    if not cell then return nil end
    for dx = -radius, radius do
        for dy = -radius, radius do
            local sq = cell:getGridSquare(x + dx, y + dy, z)
            if sq then
                local objs = sq:getObjects()
                if objs then
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if o then
                            local md = o:getModData()
                            if md and md.IsDCSObject and pred(md, o, sq) then
                                return o, sq
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function removeObject(square, obj)
    square:transmitRemoveItemFromSquare(obj)
    obj:removeFromSquare()
end

local function placeObjectResolved(cell, target, entry, anchorKey)
    local cfg = objectCfg(entry.type)

    local placeCfg = cfg
    if entry.outside then
        placeCfg = {}
        if cfg then for k, v in pairs(cfg) do placeCfg[k] = v end end
        placeCfg.requireOutside = true
    end

    local tile = target
    local placeMode
    if entry.outside then
        tile = target
        placeMode = "EXACT(outside=true)"
    elseif DCS_ObjectPlace and DCS_ObjectPlace.findPlacementTile then
        tile = DCS_ObjectPlace.findPlacementTile(cell, target, placeCfg) or target
        placeMode = "SEARCH"
    else
        placeMode = "FALLBACK(no ObjectPlace)"
    end
    DCS_dprint("[DCS_OBJ] placeObjectResolved chId=" .. tostring(entry.challengeId)
        .. " anchor=" .. tostring(anchorKey)
        .. " mode=" .. placeMode
        .. " -> tile=" .. coordKey(tile:getX(), tile:getY(), tile:getZ())
        .. (coordKey(tile:getX(), tile:getY(), tile:getZ()) == anchorKey and " (anchor)" or " (OFFSET)"))

    local sprite = entry.sprite
    if not sprite and entry.outside and cfg then
        sprite = cfg.south or cfg.west or cfg.north or cfg.east
        DCS_dprint("[DCS_OBJ] orient chId=" .. tostring(entry.challengeId)
            .. " type=" .. tostring(entry.type)
            .. " facing=south(hardcoded, outside=true) sprite=" .. tostring(sprite)
            .. " tile=" .. coordKey(tile:getX(), tile:getY(), tile:getZ()))
    end
    if not sprite and cfg and DCS_ObjectPlace and DCS_ObjectPlace.resolveSprite then
        local walls = DCS_ObjectPlace.scanWalls(tile, cfg.allowWindows, cfg.allowFences)
        local facing
        sprite, facing = DCS_ObjectPlace.resolveSprite(cfg, walls, tile)
        DCS_dprint("[DCS_OBJ] orient chId=" .. tostring(entry.challengeId)
            .. " type=" .. tostring(entry.type)
            .. " walls{N=" .. tostring(walls and walls.N) .. " S=" .. tostring(walls and walls.S)
            .. " E=" .. tostring(walls and walls.E) .. " W=" .. tostring(walls and walls.W) .. "}"
            .. " facing=" .. tostring(facing) .. " sprite=" .. tostring(sprite)
            .. " tile=" .. coordKey(tile:getX(), tile:getY(), tile:getZ()))
    end
    sprite = sprite or spriteFor(entry)

    local obj = IsoObject.new(cell, tile, sprite)
    obj:setName("DCS")
    obj:setOutlineOnMouseover(true)
    local md = obj:getModData()
    md.IsDCSObject = true
    md.DCSChallengeId = entry.challengeId
    md.DCSObjectType = entry.type
    md.DCSObjectSide = entry.side
    md.DCSObjectName = entry.name
    md.DCSAnchorKey = anchorKey
    md.DCSPlacedAt = coordKey(tile:getX(), tile:getY(), tile:getZ())
    tile:transmitAddObjectToSquare(obj, -1)
end

local function ensureSquare(cell, square, entry)
    if not square then return end
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local anchorKey = coordKey(x, y, z)
    local R = (DCS_ObjectPlace and DCS_ObjectPlace.MAX_R) or 0

    local function anchoredHere(md, o, sq)
        if md.DCSAnchorKey == anchorKey then return true end
        if md.DCSAnchorKey == nil and sq:getX() == x and sq:getY() == y then return true end
        return false
    end

    if entry then
        local existing, exSq = scanNear(cell, x, y, z, R, function(md)
            return md.DCSAnchorKey == anchorKey and md.DCSChallengeId == entry.challengeId
        end)
        if existing then
            DCS_dprint("[DCS_OBJ] ensureSquare KEEP chId=" .. tostring(entry.challengeId)
                .. " anchor=" .. anchorKey .. " foundAt="
                .. coordKey(exSq:getX(), exSq:getY(), exSq:getZ()))
            return
        end
        local stale, staleSq = scanNear(cell, x, y, z, R, anchoredHere)
        if stale and staleSq then
            DCS_dprint("[DCS_OBJ] ensureSquare STALE-REMOVE chId=" .. tostring(entry.challengeId)
                .. " anchor=" .. anchorKey .. " removedAnchor=" .. tostring(stale:getModData().DCSAnchorKey)
                .. " removedChId=" .. tostring(stale:getModData().DCSChallengeId)
                .. " at=" .. coordKey(staleSq:getX(), staleSq:getY(), staleSq:getZ()))
            removeObject(staleSq, stale)
        end
        DCS_dprint("[DCS_OBJ] ensureSquare PLACE chId=" .. tostring(entry.challengeId)
            .. " anchor=" .. anchorKey)
        placeObjectResolved(cell, square, entry, anchorKey)
    else
        local existing, esq = scanNear(cell, x, y, z, R, anchoredHere)
        if existing and esq then
            DCS_dprint("[DCS_OBJ] ensureSquare NO-ENTRY-REMOVE anchor=" .. anchorKey
                .. " at=" .. coordKey(esq:getX(), esq:getY(), esq:getZ()))
            removeObject(esq, existing)
        end
    end
end

local placePending = {}
local placePendingCount = 0
local placeFrame = 0
local PLACE_DELAY_FRAMES = 30

local function enqueuePlace(square, entry)
    if not (square and entry) then return end
    local key = coordKey(square:getX(), square:getY(), square:getZ())
    if not placePending[key] then placePendingCount = placePendingCount + 1 end
    placePending[key] = { x = square:getX(), y = square:getY(), z = square:getZ(), frame = placeFrame }
end

local function onTickPlace()
    if not DCS_Env.runsServerLogic() then return end
    if not (DCS_Config and DCS_Config.USE_OBJECTS) then return end
    placeFrame = placeFrame + 1
    if placePendingCount == 0 then return end
    local cell = getCell and getCell() or nil
    if not cell then return end
    local gmd = ModData.getOrCreate("DCS_ObjectData")
    local reg = gmd.objects or {}
    for key, item in pairs(placePending) do
        local sq = cell:getGridSquare(item.x, item.y, item.z)
        local entry = reg[key]
        if not sq or not entry then
            placePending[key] = nil; placePendingCount = placePendingCount - 1
        elseif (placeFrame - item.frame) >= PLACE_DELAY_FRAMES then
            ensureSquare(cell, sq, entry)
            placePending[key] = nil; placePendingCount = placePendingCount - 1
        end
    end
end
Events.OnTick.Add(onTickPlace)

local function onLoadGridsquare(square)
    if not (DCS_Config and DCS_Config.USE_OBJECTS) then return end
    if not DCS_Env.runsServerLogic() then return end
    if not square then return end
    local gmd = ModData.getOrCreate("DCS_ObjectData")
    local reg = gmd.objects
    if not reg then return end
    local key = coordKey(square:getX(), square:getY(), square:getZ())
    local entry = reg[key]
    local cell = getCell and getCell() or nil
    if entry then
        enqueuePlace(square, entry)
    elseif gmd.staleKeys and gmd.staleKeys[key] then
        ensureSquare(cell, square, nil)
        gmd.staleKeys[key] = nil
    end
end
Events.LoadGridsquare.Add(onLoadGridsquare)

function DCS_Objects.rebuildForDay(challenges, seed)
    if not DCS_Env.runsServerLogic() then return end
    local gmd = ModData.getOrCreate("DCS_ObjectData")
    local oldReg = gmd.objects or {}

    local reg = {}
    for _, ch in ipairs(challenges or {}) do
        if ch and not ch._phase2 then
            if ch.type == "visitLocation" and ch.x and ch.y then
                reg[coordKey(ch.x, ch.y, 0)] = {
                    challengeId = ch.id, type = "visit",
                    sprite = ch.objectSprite, name = "Barney the Gnome",
                    outside = ch.outside,
                }
            elseif ch.type == "questDeliver" and ch.destX and ch.destY then
                reg[coordKey(ch.destX, ch.destY, 0)] = {
                    challengeId = ch.id, type = "quest",
                    sprite = ch.objectSprite, name = "Safe",
                    outside = ch.outside,
                }
            end
        end
    end
    if DCS_Challenges and DCS_Challenges.pickDailyTraders and DCS_Challenges.buildTraderLocationPools then
        local pools = DCS_Challenges.buildTraderLocationPools(seed)
        if pools and pools.east and pools.west then
            reg[coordKey(pools.east.x, pools.east.y, pools.east.z or 0)] = {
                challengeId = "trader_east", type = "trader", side = "east",
                name = pools.east.name,
                outside = pools.east.outside,
            }
            reg[coordKey(pools.west.x, pools.west.y, pools.west.z or 0)] = {
                challengeId = "trader_west", type = "trader", side = "west",
                name = pools.west.name,
                outside = pools.west.outside,
            }
            local ngmd = ModData.getOrCreate("DCS_NPCData")
            ngmd.traderDay = os.date("!%Y%m%d")
            ngmd.traderLocations = {
                east = { x = math.floor(pools.east.x), y = math.floor(pools.east.y), z = math.floor(pools.east.z or 0), name = pools.east.name },
                west = { x = math.floor(pools.west.x), y = math.floor(pools.west.y), z = math.floor(pools.west.z or 0), name = pools.west.name },
            }
            if DCS_NPC and DCS_NPC.setTraderLocations then
                DCS_NPC.setTraderLocations(ngmd.traderLocations)
            end
        end
    end

    local staleKeys = gmd.staleKeys or {}
    for key in pairs(oldReg) do
        if not reg[key] then staleKeys[key] = true end
    end
    for key in pairs(reg) do staleKeys[key] = nil end

    gmd.objects = reg
    gmd.staleKeys = staleKeys
    gmd.day = utcDay()

    local cell = getCell and getCell() or nil
    if cell then
        for key, entry in pairs(reg) do
            local x, y, z = key:match("^(-?%d+),(-?%d+),(-?%d+)$")
            if x then
                local sq = cell:getGridSquare(tonumber(x), tonumber(y), tonumber(z))
                if sq then enqueuePlace(sq, entry) end
            end
        end
        for key in pairs(staleKeys) do
            local x, y, z = key:match("^(-?%d+),(-?%d+),(-?%d+)$")
            if x then
                local sq = cell:getGridSquare(tonumber(x), tonumber(y), tonumber(z))
                if sq then ensureSquare(cell, sq, nil); staleKeys[key] = nil end
            end
        end
    end

    local n = 0; for _ in pairs(reg) do n = n + 1 end
    DCS_dprint("[DCS_OBJ] rebuildForDay: " .. n .. " object location(s) registered for day " .. gmd.day)
end

function DCS_Objects.forceRePlaceAll()
    if not DCS_Env.runsServerLogic() then return 0 end
    local cell = getCell and getCell() or nil
    if not cell then return 0 end
    local gmd = ModData.getOrCreate("DCS_ObjectData")
    local reg = gmd.objects or {}
    local R = (DCS_ObjectPlace and DCS_ObjectPlace.MAX_R) or 0
    local n = 0
    for key, entry in pairs(reg) do
        local x, y, z = key:match("^(-?%d+),(-?%d+),(-?%d+)$")
        if x then
            local xi, yi, zi = tonumber(x), tonumber(y), tonumber(z)
            local sq = cell:getGridSquare(xi, yi, zi)
            if sq then
                local existing, exSq = scanNear(cell, xi, yi, zi, R, function(md)
                    return md.DCSAnchorKey == key
                end)
                if existing then
                    removeObject(exSq, existing)
                    DCS_dprint("[DCS_OBJ] forceRePlaceAll: removed existing anchor=" .. key)
                end
                ensureSquare(cell, sq, entry)
                n = n + 1
            end
        end
    end
    DCS_dprint("[DCS_OBJ] forceRePlaceAll: re-placed " .. n .. " object(s)")
    return n
end

function DCS_Objects.getObjectData()
    local gmd = ModData.getOrCreate("DCS_ObjectData")
    local result = {}
    for key, entry in pairs(gmd.objects or {}) do
        local x, y, z = key:match("^(-?%d+),(-?%d+),(-?%d+)$")
        result[#result + 1] = {
            challengeId = entry.challengeId, type = entry.type, side = entry.side,
            name = entry.name, x = tonumber(x), y = tonumber(y), z = tonumber(z),
        }
    end
    return result
end

return DCS_Objects
