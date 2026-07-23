local dcsRandom = newrandom()

DCS_ObjectPlace = DCS_ObjectPlace or {}
local P = DCS_ObjectPlace

P.MAX_R = 30

P.PLACE_MAX_DOOR_DEPTH = 1
local ROOM_SMALL_SIDE = 2
local ROOM_SMALL_MIN_TILES = 4
local RANDOMIZE_MIN_CANDIDATES = 3
local TOP_N = 5

local OUTSIDE_PENALTY = 5000
local FRONT_PENALTY = 50
local CRAMP_PENALTY = 12
local DOOR_NEAR_PENALTY = 8
local CLUTTER_PENALTY = 3
local FRONT_ROW_PENALTY = 12

local WALL_TO_FACING = { N = "south", W = "east", E = "west", S = "north" }
local WALL_PRIORITY = { "W", "N", "E", "S" }
local FACING_RANK = { east = 0, south = 1, west = 2, north = 3 }
local DEFAULT_FACING_ORDER = { "east", "south", "west", "north" }
local FACING_DIR = { east = IsoDirections.E, south = IsoDirections.S,
                      north = IsoDirections.N, west = IsoDirections.W }
local FACING_TO_SIDE = { south = "S", north = "N", east = "E", west = "W" }
local BACK_SKIP = { south = {ax = "y", v = -1}, north = {ax = "y", v = 1},
                    east = {ax = "x", v = -1}, west = {ax = "x", v = 1} }

local function adj(sq, dir)
    if not sq then return nil end
    return sq:getAdjacentSquare(dir)
end

local function flag(sq, f)
    if not sq then return false end
    return sq:has(f) or false
end

local isRoofedPorch

local function isOutsideSq(sq)
    if not sq then return true end
    if sq:isOutside() then return true end
    if isRoofedPorch and isRoofedPorch(sq) then return true end
    return false
end

local function sqFree(sq)
    if not sq then return false end
    return sq:isFree(false) or false
end

local function reachable(sq, n)
    if not (sq and n) then return false end
    return sq:canReachTo(n) or false
end

local function spriteFlag(o, f)
    if not o then return false end
    local props = o:getProperties()
    return (props and props:has(f)) or false
end

local function spriteHasProp(o, name)
    if not o then return false end
    local props = o:getProperties()
    return (props and props:has(name)) or false
end

local function hasGarageDoorOnSide(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    if not objs then return false end
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and spriteHasProp(o, "GarageDoor") then return true end
    end
    return false
end

local function hasGarageDoorAnySide(sq)
    if not sq then return false end
    if hasGarageDoorOnSide(sq) then return true end
    local s = adj(sq, IsoDirections.S)
    if s and hasGarageDoorOnSide(s) then return true end
    local e = adj(sq, IsoDirections.E)
    if e and hasGarageDoorOnSide(e) then return true end
    return false
end

local function garageDoorIn8Surround(sq)
    if not sq then return false end
    local cell = getCell and getCell() or nil
    if not cell then return false end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local n = cell:getGridSquare(x + dx, y + dy, z)
                if n and hasGarageDoorOnSide(n) then return true end
            end
        end
    end
    return false
end

local function garageDoorInFrontArea(sq, facing)
    if not sq then return false end
    local cell = getCell and getCell() or nil
    if not cell then return false end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local sideDx, sideDy = 0, 0
    local frontDx, frontDy = 0, 0
    if facing == "south" then
        sideDx, sideDy = 1, 0
        frontDx, frontDy = 0, 1
    elseif facing == "north" then
        sideDx, sideDy = 1, 0
        frontDx, frontDy = 0, -1
    elseif facing == "east" then
        sideDx, sideDy = 0, 1
        frontDx, frontDy = 1, 0
    elseif facing == "west" then
        sideDx, sideDy = 0, 1
        frontDx, frontDy = -1, 0
    end
    local s1 = cell:getGridSquare(x + sideDx, y + sideDy, z)
    local s2 = cell:getGridSquare(x - sideDx, y - sideDy, z)
    if s1 and hasGarageDoorOnSide(s1) then return true end
    if s2 and hasGarageDoorOnSide(s2) then return true end
    local f1 = cell:getGridSquare(x + frontDx, y + frontDy, z)
    local f2 = cell:getGridSquare(x + frontDx + sideDx, y + frontDy + sideDy, z)
    local f3 = cell:getGridSquare(x + frontDx - sideDx, y + frontDy - sideDy, z)
    if f1 and hasGarageDoorOnSide(f1) then return true end
    if f2 and hasGarageDoorOnSide(f2) then return true end
    if f3 and hasGarageDoorOnSide(f3) then return true end
    return false
end

local function isRealWallN(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    if not objs then return false end
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and spriteFlag(o, IsoFlagType.WallN)
           and not spriteHasProp(o, "GarageDoor")
           and not spriteFlag(o, IsoFlagType.DoorWallN)
           and not spriteFlag(o, IsoFlagType.WindowN) then
            return true
        end
    end
    return false
end
local function isRealWallW(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    if not objs then return false end
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and spriteFlag(o, IsoFlagType.WallW)
           and not spriteHasProp(o, "GarageDoor")
           and not spriteFlag(o, IsoFlagType.DoorWallW)
           and not spriteFlag(o, IsoFlagType.WindowW) then
            return true
        end
    end
    return false
end

local function hasDoorAnySide(sq)
    if not sq then return false end
    if flag(sq, IsoFlagType.DoorWallN) or flag(sq, IsoFlagType.DoorWallW) then return true end
    local s = adj(sq, IsoDirections.S)
    if s and flag(s, IsoFlagType.DoorWallN) then return true end
    local e = adj(sq, IsoDirections.E)
    if e and flag(e, IsoFlagType.DoorWallW) then return true end
    if hasGarageDoorAnySide(sq) then return true end
    return false
end

local function hasWindowAnySide(sq)
    if not sq then return false end
    if flag(sq, IsoFlagType.WindowN) or flag(sq, IsoFlagType.WindowW) then return true end
    local s = adj(sq, IsoDirections.S)
    if s and flag(s, IsoFlagType.WindowN) then return true end
    local e = adj(sq, IsoDirections.E)
    if e and flag(e, IsoFlagType.WindowW) then return true end
    return false
end

local function hasDCSObject(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    if not objs then return false end
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o then
            local md = o:getModData()
            if md and md.IsDCSObject then return true end
        end
    end
    return false
end

local function isStructuralWall(o)
    return spriteFlag(o, IsoFlagType.WallN)
        or spriteFlag(o, IsoFlagType.WallW)
        or spriteFlag(o, IsoFlagType.WallNW)
end

local function isWallAttachment(o)
    if spriteFlag(o, IsoFlagType.WallOverlay) then return true end
    if spriteFlag(o, IsoFlagType.attachedN) or spriteFlag(o, IsoFlagType.attachedS)
       or spriteFlag(o, IsoFlagType.attachedE) or spriteFlag(o, IsoFlagType.attachedW) then
        return true
    end
    return false
end

local function isFlatDecoration(o)
    return isWallAttachment(o) and spriteFlag(o, IsoFlagType.WallOverlay)
end

local function isEdgeObject(o)
    return spriteFlag(o, IsoFlagType.WindowN) or spriteFlag(o, IsoFlagType.WindowW)
        or spriteFlag(o, IsoFlagType.DoorWallN) or spriteFlag(o, IsoFlagType.DoorWallW)
        or spriteHasProp(o, "GarageDoor")
end

local function tileHasObstruction(sq)
    if not sq then return false end
    local floor = sq:getFloor()
    local objs = sq:getObjects()
    if not objs then return false end
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and o ~= floor
           and not isStructuralWall(o)
           and not isFlatDecoration(o)
           and not isEdgeObject(o) then
            return true
        end
    end
    return false
end
P.tileHasObstruction = tileHasObstruction

local function tileHasStairs(sq)
    if not sq then return false end
    return sq:HasStairs() and true or false
end

function P.nearStairs(sq)
    if not sq then return false end
    return tileHasStairs(sq)
        or tileHasStairs(adj(sq, IsoDirections.N))
        or tileHasStairs(adj(sq, IsoDirections.S))
        or tileHasStairs(adj(sq, IsoDirections.E))
        or tileHasStairs(adj(sq, IsoDirections.W))
end

local function isWindowN(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    if not objs then return false end
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and spriteFlag(o, IsoFlagType.WindowN) then return true end
    end
    return false
end
local function isWindowW(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    if not objs then return false end
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and spriteFlag(o, IsoFlagType.WindowW) then return true end
    end
    return false
end
local function isFenceN(sq) return (sq and flag(sq, IsoFlagType.HoppableN)) or false end
local function isFenceW(sq) return (sq and flag(sq, IsoFlagType.HoppableW)) or false end

local function backableN(sq, includeWindows, includeFences)
    return isRealWallN(sq)
        or (includeWindows and isWindowN(sq))
        or (includeFences and isFenceN(sq))
        or false
end
local function backableW(sq, includeWindows, includeFences)
    return isRealWallW(sq)
        or (includeWindows and isWindowW(sq))
        or (includeFences and isFenceW(sq))
        or false
end

function P.scanWalls(sq, includeWindows, includeFences)
    local w = { N = false, S = false, E = false, W = false }
    if not sq then return w end
    w.N = backableN(sq, includeWindows, includeFences)
    w.W = backableW(sq, includeWindows, includeFences)
    w.S = backableN(adj(sq, IsoDirections.S), includeWindows, includeFences)
    w.E = backableW(adj(sq, IsoDirections.E), includeWindows, includeFences)
    return w
end

local function sideBlocked(sq, walls, sideName, dir)
    if walls[sideName] then return true end
    local n = adj(sq, dir)
    if not n then return true end
    return not sqFree(n)
end

function P.isPlaceable(sq)
    if not sqFree(sq) then return false end
    if hasDCSObject(sq) then return false end
    if tileHasObstruction(sq) then return false end
    if P.nearStairs(sq) then return false end
    return true
end

local function tileIsClutter(t)
    if not t then return false end
    if sqFree(t) then return false end
    local w = P.scanWalls(t)
    if w.N or w.S or w.E or w.W then return false end
    return true
end

P.CLEAR_RADIUS = 5
function P.surroundClear(sq, radius)
    if not sq then return false end
    local cell = getCell and getCell() or nil
    if not cell then return false end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    for dx = -radius, radius do
        for dy = -radius, radius do
            if not (dx == 0 and dy == 0) then
                if tileIsClutter(cell:getGridSquare(x + dx, y + dy, z)) then
                    return false
                end
            end
        end
    end
    return true
end

function P.isGoodTile(sq, allowWindows)
    if not P.isPlaceable(sq) then return false end
    if hasDoorAnySide(sq) then return false end
    if not allowWindows and hasWindowAnySide(sq) then return false end
    local walls = P.scanWalls(sq)
    local bN = sideBlocked(sq, walls, "N", IsoDirections.N)
    local bS = sideBlocked(sq, walls, "S", IsoDirections.S)
    local bE = sideBlocked(sq, walls, "E", IsoDirections.E)
    local bW = sideBlocked(sq, walls, "W", IsoDirections.W)
    if (bN and bS) or (bE and bW) then return false end
    if reachable(sq, adj(sq, IsoDirections.N))
       or reachable(sq, adj(sq, IsoDirections.S))
       or reachable(sq, adj(sq, IsoDirections.E))
       or reachable(sq, adj(sq, IsoDirections.W)) then
        return true
    end
    return false
end

function P.opennessScore(sq)
    if not sq then return -1 end
    local cell = getCell and getCell() or nil
    if not cell then return -1 end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local score = 0
    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                if sqFree(cell:getGridSquare(x + dx, y + dy, z)) then
                    score = score + 1
                end
            end
        end
    end
    return score
end

function P.isFullyOpen(sq)
    if not P.isGoodTile(sq) then return false end
    local w = P.scanWalls(sq)
    if w.N or w.S or w.E or w.W then return false end
    if garageDoorIn8Surround(sq) then return false end
    local cell = getCell and getCell() or nil
    if not cell then return false end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local n = cell:getGridSquare(x + dx, y + dy, z)
                if not sqFree(n) then return false end
                if tileHasObstruction(n) then return false end
            end
        end
    end
    return true
end

local function tileEdgeHasAttachment(tile, wantNorth)
    if not tile then return false end
    local objs = tile:getObjects()
    if not objs then return false end
    local edgeFlag = wantNorth and IsoFlagType.attachedN or IsoFlagType.attachedW
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and (spriteFlag(o, edgeFlag) or spriteFlag(o, IsoFlagType.WallOverlay)) then
            return true
        end
    end
    return false
end

local function sideDecorated(sq, side)
    if not sq then return false end
    if side == "N" then return tileEdgeHasAttachment(sq, true) end
    if side == "W" then return tileEdgeHasAttachment(sq, false) end
    if side == "S" then return tileEdgeHasAttachment(adj(sq, IsoDirections.S), true) end
    if side == "E" then return tileEdgeHasAttachment(adj(sq, IsoDirections.E), false) end
    return false
end

local function usableWall(cfg, walls, sq, side)
    if not (walls[side] and cfg and cfg[WALL_TO_FACING[side]]) then return false end
    if not cfg.allowDecoratedWalls and sideDecorated(sq, side) then return false end
    return true
end

function P.resolveSprite(cfg, walls, sq)
    if not cfg then return nil end
    local frontEdge = sq and P.scanWalls(sq, true, true) or nil
    local function frontClear(facing)
        if not frontEdge then return true end
        local fside = FACING_TO_SIDE[facing]
        return not (fside and frontEdge[fside])
    end
    if walls then
        for _, side in ipairs(WALL_PRIORITY) do
            if usableWall(cfg, walls, sq, side) and frontClear(WALL_TO_FACING[side]) then
                return cfg[WALL_TO_FACING[side]], WALL_TO_FACING[side]
            end
        end
        for _, side in ipairs(WALL_PRIORITY) do
            if usableWall(cfg, walls, sq, side) then
                return cfg[WALL_TO_FACING[side]], WALL_TO_FACING[side]
            end
        end
    end
    if frontEdge then
        for _, facing in ipairs(DEFAULT_FACING_ORDER) do
            if cfg[facing] and frontClear(facing) then return cfg[facing], facing end
        end
    end
    local d = cfg.default or "south"
    return cfg[d] or cfg.south or cfg.west or cfg.north or cfg.east, d
end

local function hasBackableWall(cfg, walls, sq)
    if not (cfg and walls) then return false end
    for _, side in ipairs(WALL_PRIORITY) do
        if usableWall(cfg, walls, sq, side) then return true end
    end
    return false
end

local function forRing(cell, cx, cy, cz, r, fn)
    if r == 0 then
        local sq = cell:getGridSquare(cx, cy, cz)
        if sq and fn(sq) then return sq end
        return nil
    end
    for dx = -r, r do
        for dy = -r, r do
            if math.max(math.abs(dx), math.abs(dy)) == r then
                local sq = cell:getGridSquare(cx + dx, cy + dy, cz)
                if sq and fn(sq) then return sq end
            end
        end
    end
    return nil
end

local SEAL_CAP = 160

local SIDE_DIRS = { N = IsoDirections.N, S = IsoDirections.S,
                    E = IsoDirections.E, W = IsoDirections.W }

local function tileSideKind(t, orient)
    if not t then return "unknown" end
    local dF, wF, lF
    if orient == "N" then
        dF, wF, lF = IsoFlagType.DoorWallN, IsoFlagType.WindowN, IsoFlagType.WallN
    else
        dF, wF, lF = IsoFlagType.DoorWallW, IsoFlagType.WindowW, IsoFlagType.WallW
    end
    if flag(t, dF) then return "door" end
    if flag(t, wF) then return "window" end
    if flag(t, lF) then return "wall" end
    local hasDoor, hasWin, hasWall, hasGarageDoor = false, false, false, false
    local objs = t:getObjects()
    if objs then
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if o then
                if spriteFlag(o, dF) then hasDoor = true end
                if spriteFlag(o, wF) then hasWin = true end
                if spriteFlag(o, lF) or spriteFlag(o, IsoFlagType.WallNW) then hasWall = true end
                if spriteHasProp(o, "GarageDoor") then hasGarageDoor = true end
            end
        end
    end
    if hasDoor or hasGarageDoor then return "door" end
    if hasWin then return "window" end
    if hasWall then return "wall" end
    return "open"
end

local function edgeKind(sq, side)
    if side == "N" then return tileSideKind(sq, "N")
    elseif side == "W" then return tileSideKind(sq, "W")
    elseif side == "S" then return tileSideKind(adj(sq, IsoDirections.S), "N")
    else return tileSideKind(adj(sq, IsoDirections.E), "W")
    end
end

isRoofedPorch = function(sq)
    if not sq then return false end
    if sq.haveRoof == false then return false end
    for side, dir in pairs(SIDE_DIRS) do
        if edgeKind(sq, side) == "open" then
            local n = adj(sq, dir)
            if n and n:isOutside() then return true end
        end
    end
    return false
end

P._sealGen = 0
local sealMemo = {}
local sealMemoGen = -1

function P.regionSealed(sq)
    if not sq then return false end
    if P._sealGen ~= sealMemoGen then sealMemo = {}; sealMemoGen = P._sealGen end
    if isOutsideSq(sq) then return false end
    local cell = getCell and getCell() or nil
    if not cell then return false end
    local z = sq:getZ()
    local startKey = sq:getX() .. "," .. sq:getY() .. "," .. z
    local m = sealMemo[startKey]
    if m ~= nil then return m end

    local visited = {}
    local visitedList = {}
    local stack = { sq }
    local accessible = false
    local count = 0
    while #stack > 0 do
        local cur = table.remove(stack)
        local ck = cur:getX() .. "," .. cur:getY()
        if not visited[ck] then
            visited[ck] = true
            visitedList[#visitedList + 1] = cur
            count = count + 1
            if count > SEAL_CAP or isOutsideSq(cur) then accessible = true; break end
            for side, dir in pairs(SIDE_DIRS) do
                local k = edgeKind(cur, side)
                if k == "door" or k == "window" or k == "unknown" then
                    accessible = true
                elseif k == "open" then
                    local n = adj(cur, dir)
                    if n then
                        if not visited[n:getX() .. "," .. n:getY()] then stack[#stack + 1] = n end
                    else
                        accessible = true
                    end
                end
            end
            if accessible then break end
        end
    end

    local sealed = not accessible
    for _, t in ipairs(visitedList) do
        sealMemo[t:getX() .. "," .. t:getY() .. "," .. z] = sealed
    end
    return sealed
end

local function roomBlocked(sq)
    return P.regionSealed(sq)
end

local REACH_CAP = 600
P.REACH_MAX_DOOR_DEPTH = 2
function P.reachDiag(sq, maxDepth)
    if not sq then return { size = 0 } end
    maxDepth = maxDepth or P.REACH_MAX_DOOR_DEPTH or 2
    local z = sq:getZ()
    local visited = {}
    local size, doors = 0, 0
    local touchedOutside, capped = false, false
    local minX, minY, maxX, maxY
    local DEPTH_KEY = { [0] = "green", [1] = "yellow", [2] = "red", [3] = "magenta" }
    local cols = {
        green = { x = {}, y = {} },
        yellow = { x = {}, y = {} },
        red = { x = {}, y = {} },
        magenta = { x = {}, y = {} },
        out = { x = {}, y = {} },
    }
    local depthCount = { green = 0, yellow = 0, red = 0, magenta = 0 }
    local function bbox(cx, cy)
        if not minX or cx < minX then minX = cx end
        if not maxX or cx > maxX then maxX = cx end
        if not minY or cy < minY then minY = cy end
        if not maxY or cy > maxY then maxY = cy end
    end
    local function keyOf(s) return s:getX() .. "," .. s:getY() end

    local frontier = { sq }
    local depth = 0
    while #frontier > 0 and depth <= maxDepth and not capped do
        local nextFrontier = {}
        local roomStack = {}
        for _, f in ipairs(frontier) do
            if not visited[keyOf(f)] then roomStack[#roomStack + 1] = f end
        end
        while #roomStack > 0 do
            local cur = table.remove(roomStack)
            local ck = keyOf(cur)
            if not visited[ck] then
                visited[ck] = true
                size = size + 1
                local cx, cy = cur:getX(), cur:getY()
                bbox(cx, cy)
                if size > REACH_CAP then capped = true; break end
                if isOutsideSq(cur) then
                    touchedOutside = true
                    cols.out.x[#cols.out.x + 1] = cx; cols.out.y[#cols.out.y + 1] = cy
                else
                    local key = DEPTH_KEY[depth < 3 and depth or 3]
                    cols[key].x[#cols[key].x + 1] = cx
                    cols[key].y[#cols[key].y + 1] = cy
                    depthCount[key] = depthCount[key] + 1
                    for side, dir in pairs(SIDE_DIRS) do
                        local k = edgeKind(cur, side)
                        if k == "open" then
                            local n = adj(cur, dir)
                            if n and not visited[keyOf(n)] then roomStack[#roomStack + 1] = n end
                        elseif k == "door" then
                            doors = doors + 1
                            local n = adj(cur, dir)
                            if n and not visited[keyOf(n)] then nextFrontier[#nextFrontier + 1] = n end
                        end
                    end
                end
            end
        end
        frontier = nextFrontier
        depth = depth + 1
    end

    return { size = size, doors = doors, touchedOutside = touchedOutside,
             capped = capped, maxDepth = maxDepth,
             minX = minX, minY = minY, maxX = maxX, maxY = maxY, z = z,
             d0 = depthCount.green, d1 = depthCount.yellow,
             d2 = depthCount.red, d3 = depthCount.magenta,
             cols = cols }
end

function P.reachRooms(sq, maxDepth)
    if not sq or isOutsideSq(sq) then return { rooms = {}, greenIndex = 0 } end
    maxDepth = maxDepth or P.PLACE_MAX_DOOR_DEPTH or 1
    local function keyOf(s) return s:getX() .. "," .. s:getY() end
    local rooms = {}
    local visited = {}
    local total = 0
    local frontier = { sq }
    local depth = 0
    while #frontier > 0 and depth <= maxDepth and total < REACH_CAP do
        local nextFrontier = {}
        for _, entryTile in ipairs(frontier) do
            if not visited[keyOf(entryTile)] then
                local room = { depth = depth, tiles = {} }
                local roomStack = { entryTile }
                while #roomStack > 0 do
                    local cur = table.remove(roomStack)
                    local ck = keyOf(cur)
                    if not visited[ck] then
                        visited[ck] = true
                        total = total + 1
                        if not isOutsideSq(cur) then
                            local cx, cy = cur:getX(), cur:getY()
                            room.tiles[#room.tiles + 1] = cur
                            if not room.minX or cx < room.minX then room.minX = cx end
                            if not room.maxX or cx > room.maxX then room.maxX = cx end
                            if not room.minY or cy < room.minY then room.minY = cy end
                            if not room.maxY or cy > room.maxY then room.maxY = cy end
                            for side, dir in pairs(SIDE_DIRS) do
                                local k = edgeKind(cur, side)
                                if k == "open" then
                                    local n = adj(cur, dir)
                                    if n and not visited[keyOf(n)] then roomStack[#roomStack + 1] = n end
                                elseif k == "door" then
                                    local n = adj(cur, dir)
                                    if n and not visited[keyOf(n)] then nextFrontier[#nextFrontier + 1] = n end
                                end
                            end
                        end
                        if total >= REACH_CAP then break end
                    end
                end
                if #room.tiles > 0 then rooms[#rooms + 1] = room end
            end
        end
        frontier = nextFrontier
        depth = depth + 1
    end
    return { rooms = rooms, greenIndex = (#rooms > 0) and 1 or 0 }
end

function P.sealDiag(sq)
    if not sq then return { sealed = false, reason = "nil-sq", count = 0 } end
    if isOutsideSq(sq) then
        return { sealed = false, reason = "start-outside", count = 0 }
    end
    local startEdges = "N=" .. edgeKind(sq, "N") .. " S=" .. edgeKind(sq, "S")
        .. " E=" .. edgeKind(sq, "E") .. " W=" .. edgeKind(sq, "W")
    local visited = {}
    local stack = { sq }
    local count = 0
    local reason, atX, atY
    while #stack > 0 do
        local cur = table.remove(stack)
        local ck = cur:getX() .. "," .. cur:getY()
        if not visited[ck] then
            visited[ck] = true
            count = count + 1
            if count > SEAL_CAP then reason = "exceeded-cap"; break end
            if isOutsideSq(cur) then
                reason = "reached-outside"; atX = cur:getX(); atY = cur:getY(); break
            end
            for side, dir in pairs(SIDE_DIRS) do
                local k = edgeKind(cur, side)
                if k == "door" or k == "window" or k == "unknown" then
                    reason = k .. "-edge-" .. side; atX = cur:getX(); atY = cur:getY(); break
                elseif k == "open" then
                    local n = adj(cur, dir)
                    if n then
                        if not visited[n:getX() .. "," .. n:getY()] then stack[#stack + 1] = n end
                    else
                        reason = "open-unloaded-" .. side; atX = cur:getX(); atY = cur:getY(); break
                    end
                end
            end
            if reason then break end
        end
    end
    return { sealed = (reason == nil), reason = reason or "fully-bounded",
             count = count, atX = atX, atY = atY, edges = startEdges }
end

local function anyDoorInSurround(sq)
    if not sq then return false end
    local cell = getCell and getCell() or nil
    if not cell then return false end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                if hasDoorAnySide(cell:getGridSquare(x + dx, y + dy, z)) then
                    return true
                end
            end
        end
    end
    return false
end

local function crampedNeighbours(sq, facing)
    if not sq then return 0 end
    local cell = getCell and getCell() or nil
    if not cell then return 0 end
    local skip = BACK_SKIP[facing]
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local n = 0
    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local skipIt = skip and ((skip.ax == "x" and dx == skip.v)
                                      or (skip.ax == "y" and dy == skip.v))
                if not skipIt and tileHasObstruction(cell:getGridSquare(x + dx, y + dy, z)) then
                    n = n + 1
                end
            end
        end
    end
    return n
end

local function chebyshev(a, b)
    return math.max(math.abs(a:getX() - b:getX()), math.abs(a:getY() - b:getY()))
end

local function randIndex(n)
    if n <= 1 then return 1 end
    return dcsRandom:random(1, n)
end

local function roomIsSmall(room)
    if not room or not room.minX then return true end
    local w = (room.maxX - room.minX) + 1
    local h = (room.maxY - room.minY) + 1
    if w <= ROOM_SMALL_SIDE or h <= ROOM_SMALL_SIDE then return true end
    if #room.tiles < ROOM_SMALL_MIN_TILES then return true end
    return false
end

local function frontOffsets(facing)
    if facing == "south" then return 0, 1, 1, 0 end
    if facing == "north" then return 0, -1, 1, 0 end
    if facing == "east"  then return 1, 0, 0, 1 end
    if facing == "west"  then return -1, 0, 0, 1 end
    return 0, 0, 0, 0
end

local function frontRowClearCount(sq, facing)
    local cell = getCell and getCell() or nil
    if not (sq and cell) then return 3 end
    local fdx, fdy, sdx, sdy = frontOffsets(facing)
    if fdx == 0 and fdy == 0 then return 3 end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local n = 0
    local f1 = cell:getGridSquare(x + fdx, y + fdy, z)
    local f2 = cell:getGridSquare(x + fdx + sdx, y + fdy + sdy, z)
    local f3 = cell:getGridSquare(x + fdx - sdx, y + fdy - sdy, z)
    if f1 and sqFree(f1) then n = n + 1 end
    if f2 and sqFree(f2) then n = n + 1 end
    if f3 and sqFree(f3) then n = n + 1 end
    return n
end

local function scoreWallCandidate(cfg, sq, prox, allowWindows, allowFences, preferInside, requireClear)
    local walls = P.scanWalls(sq, allowWindows, allowFences)
    if not hasBackableWall(cfg, walls, sq) then return nil end
    local _, facing = P.resolveSprite(cfg, walls, sq)
    if not facing then return nil end
    local rank = FACING_RANK[facing] or 3
    local dir = FACING_DIR[facing]
    local fside = FACING_TO_SIDE[facing]
    if garageDoorInFrontArea(sq, facing) then return nil end
    local frontEdge = P.scanWalls(sq, true, true)
    local frontWall = fside and frontEdge[fside] and true or false
    local frontOccupied = dir and not sqFree(adj(sq, dir)) and true or false
    local frontBlocked = (frontWall or frontOccupied) and FRONT_PENALTY or 0
    local place = (preferInside and isOutsideSq(sq)) and OUTSIDE_PENALTY or 0
    local doorNear = anyDoorInSurround(sq) and DOOR_NEAR_PENALTY or 0
    local crampedCount = crampedNeighbours(sq, facing)
    if requireClear and crampedCount > 0 then return nil end
    local cramped = (crampedCount > 0) and CRAMP_PENALTY or 0
    local clutter = (not P.surroundClear(sq, P.CLEAR_RADIUS)) and CLUTTER_PENALTY or 0
    local frontJam = (3 - frontRowClearCount(sq, facing)) * FRONT_ROW_PENALTY
    return rank * 2 + frontBlocked + frontJam + prox + place + doorNear + cramped + clutter, facing
end

local function collectRoomCandidates(out, room, cfg, mode, target, maxR, allowWindows, allowFences, preferInside, requireClear)
    if mode == "open" then
        local before = #out
        for _, sq in ipairs(room.tiles) do
            local d = chebyshev(sq, target)
            if d <= maxR and P.isFullyOpen(sq) then
                out[#out + 1] = { sq = sq, score = d }
            end
        end
        if #out > before then return end
    end
    for _, sq in ipairs(room.tiles) do
        local d = chebyshev(sq, target)
        if d <= maxR and P.isGoodTile(sq, allowWindows) then
            local s = scoreWallCandidate(cfg, sq, d, allowWindows, allowFences, preferInside, requireClear)
            if s then out[#out + 1] = { sq = sq, score = s } end
        end
    end
end

local function pickWithinReach(target, cfg, mode, maxR, allowWindows, allowFences, preferInside)
    local rr = P.reachRooms(target, P.PLACE_MAX_DOOR_DEPTH)
    if not rr or #rr.rooms == 0 then return nil end
    local green = rr.rooms[rr.greenIndex]
    local chosen = green
    if roomIsSmall(green) then
        local biggest = nil
        for _, room in ipairs(rr.rooms) do
            if room.depth >= 1 and (not biggest or #room.tiles > #biggest.tiles) then
                biggest = room
            end
        end
        if biggest and #biggest.tiles > #green.tiles then chosen = biggest end
    end
    local function gather(aw, af, requireClear)
        local cands = {}
        collectRoomCandidates(cands, chosen, cfg, mode, target, maxR, aw, af, preferInside, requireClear)
        if #cands == 0 then
            for _, room in ipairs(rr.rooms) do
                if room ~= chosen then
                    collectRoomCandidates(cands, room, cfg, mode, target, maxR, aw, af, preferInside, requireClear)
                end
            end
        end
        return cands
    end

    local cands = gather(allowWindows, allowFences, true)
    if #cands == 0 and not (allowWindows and allowFences) then
        cands = gather(true, true, true)
    end
    if #cands == 0 then
        cands = gather(true, true, false)
    end
    if #cands == 0 then return nil end
    table.sort(cands, function(a, b) return a.score < b.score end)
    if #cands >= RANDOMIZE_MIN_CANDIDATES then
        local topN = (#cands < TOP_N) and #cands or TOP_N
        return cands[randIndex(topN)].sq
    end
    return cands[1].sq
end

local function pickPlacementTile(cell, target, cfg)
    if not (cell and target) then return target end
    local cx, cy, cz = target:getX(), target:getY(), target:getZ()
    local mode = (cfg and cfg.mode) or "wall"
    local maxR = (cfg and cfg.searchRadius) or P.MAX_R
    local allowWindows = cfg and cfg.allowWindows
    local allowFences = cfg and cfg.allowFences
    local requireOutside = cfg and cfg.requireOutside
    local preferInside = (cfg and cfg.preferInside) and not requireOutside
    P._sealGen = (P._sealGen or 0) + 1

    if preferInside and not requireOutside and not isOutsideSq(target) then
        local chosen = pickWithinReach(target, cfg, mode, maxR, allowWindows, allowFences, preferInside)
        if chosen then return chosen end
    end

    if mode == "open" then
        local openR = (cfg and cfg.openRadius) or 4
        if openR > maxR then openR = maxR end
        for r = 0, openR do
            local found = forRing(cell, cx, cy, cz, r, function(sq)
                if requireOutside then
                    if not isOutsideSq(sq) then return false end
                elseif preferInside and isOutsideSq(sq) then
                    return false
                end
                if roomBlocked(sq) then return false end
                return P.isFullyOpen(sq)
            end)
            if found then return found end
        end
    end

    local best, bestScore = nil, nil
    local fallbackGood = nil
    local insideFallback = nil
    for r = 0, maxR do
        forRing(cell, cx, cy, cz, r, function(sq)
            if P.isGoodTile(sq, allowWindows) and not roomBlocked(sq) then
                if requireOutside and not isOutsideSq(sq) then return false end
                if not fallbackGood then fallbackGood = sq end
                if not insideFallback and not isOutsideSq(sq) then insideFallback = sq end
                local score = scoreWallCandidate(cfg, sq, r, allowWindows, allowFences, preferInside)
                if score and ((not bestScore) or score < bestScore) then
                    bestScore, best = score, sq
                end
            end
            return false
        end)
        if best and bestScore == 0 then break end
    end
    if best and not (preferInside and isOutsideSq(best)) then return best end
    if insideFallback then return insideFallback end
    if best then return best end

    if fallbackGood then return fallbackGood end
    return target
end

function P.findPlacementTile(cell, target, cfg)
    local tile = pickPlacementTile(cell, target, cfg)
    if DCS_Config and DCS_Config.DEBUG and target then
        local function tag(sq)
            if not sq then return "nil" end
            return sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ()
                .. " out=" .. tostring(isOutsideSq(sq))
                .. " sealed=" .. tostring(P.regionSealed(sq))
        end
        DCS_dprint("[DCS_PLACE] mode=" .. tostring(cfg and cfg.mode)
            .. " target=[" .. tag(target) .. "]"
            .. " -> tile=[" .. tag(tile) .. "]")
    end
    return tile
end

return DCS_ObjectPlace
