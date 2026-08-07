PP = PP or {}

PP.MODULE = "PlayablePool"
PP.CMD_JOIN = "Join"
PP.CMD_WATCH = "Watch"
PP.CMD_LEAVE = "Leave"
PP.CMD_SHOOT = "Shoot"
PP.CMD_AIM = "Aim"
PP.CMD_SET_SHOT_CALL = "SetShotCall"
PP.CMD_SET_MODE = "SetMode"
PP.CMD_PLACE_CUE = "PlaceCue"
PP.CMD_RESET = "Reset"
PP.CMD_ADD_AI = "AddAI"
PP.CMD_REMOVE_AI = "RemoveAI"
PP.CMD_DEBUG_ADD_BOT = "DebugAddBot"
PP.CMD_DEBUG_MY_TURN = "DebugMyTurn"
PP.CMD_STATE = "State"
PP.CMD_MESSAGE = "Message"

local TABLE_W = 900
local TABLE_H = 380
local TABLE_SPRITE_W = 1774
local TABLE_SPRITE_H = 887
local VISUAL_BALL_R = 13
local PHYSICS_BALL_R = VISUAL_BALL_R * 1.20
local POCKET_R = 32
local BOTTOM_CENTER_POCKET_R = 27
local POCKET_MOUTH_R = POCKET_R + PHYSICS_BALL_R * 0.95

PP.PHASE_CHOOSING_MODE = "choosing_mode"
PP.PHASE_WAITING_FOR_PLAYERS = "waiting_for_players"
PP.PHASE_READY = "ready"
PP.PHASE_AIMING = "aiming"
PP.PHASE_SHOT_COMMITTED = "shot_committed"
PP.PHASE_SIMULATING = "simulating"
PP.PHASE_RESOLVING = "resolving"
PP.PHASE_TURN_READY = "turn_ready"
PP.PHASE_GAME_OVER = "game_over"

PP.TABLE_GEOMETRY = {
    tableW = TABLE_W,
    tableH = TABLE_H,
    spriteW = TABLE_SPRITE_W,
    spriteH = TABLE_SPRITE_H,
    visualBallRadius = VISUAL_BALL_R,
    physicsBallRadius = PHYSICS_BALL_R,
    playfield = {
        insetX = 0.043,
        insetTop = 0.085,
        insetBottom = 0.059,
    },
    ballSpriteTextureSize = 96,
    ballSpriteVisibleSize = 86,
    pocketCaptureRadius = POCKET_R,
    pocketGravityRadius = POCKET_R + PHYSICS_BALL_R * 0.78,
    pocketMouthRadius = POCKET_MOUTH_R,
    collisionEdge = {
        -- Sprite-space visual contact edge. This is the rail surface the
        -- outside of the ball touches; runtime collision insets it by ball radius.
        { id = "edge_1", x = 933.453, y = 40.803 },
        { id = "edge_2", x = 880.718, y = 3.141 },
        { id = "edge_2", x = 846.168, y = 23.243 },
        { id = "edge_2", x = 837.373, y = 61.562 },
        { id = "edge_2", x = 655.827, y = 62.819 },
        { id = "edge_3", x = 125.637, y = 64.075 },
        { id = "edge_4", x = 118.099, y = 60.306 },
        { id = "edge_4", x = 97.369, y = 43.973 },
        { id = "edge_4", x = 93.6, y = 30.153 },
        { id = "edge_4", x = 81.664, y = 5.654 },
        { id = "edge_4", x = 56.537, y = 5.025 },
        { id = "edge_4", x = 19.474, y = 15.076 },
        { id = "edge_3", x = 6.91, y = 75.382 },
        { id = "edge_3", x = 41.46, y = 88.574 },
        { id = "edge_2", x = 53.396, y = 145.739 },
        { id = "edge_3", x = 60.306, y = 778.324 },
        { id = "edge_3", x = 32.666, y = 799.054 },
        { id = "edge_3", x = 10.051, y = 821.04 },
        { id = "edge_3", x = 6.282, y = 848.052 },
        { id = "edge_3", x = 30.781, y = 873.18 },
        { id = "edge_3", x = 73.498, y = 875.693 },
        { id = "edge_3", x = 91.087, y = 861.873 },
        { id = "edge_2", x = 118.099, y = 821.669 },
        { id = "edge_2", x = 836.117, y = 822.297 },
        { id = "edge_2", x = 839.886, y = 837.373 },
        { id = "edge_2", x = 843.027, y = 848.052 },
        { id = "edge_2", x = 849.309, y = 863.129 },
        { id = "edge_2", x = 866.898, y = 874.436 },
        { id = "edge_2", x = 921.526, y = 868.168 },
        { id = "edge_2", x = 932.825, y = 842.43 },
        { id = "edge_2", x = 937.847, y = 820.459 },
        { id = "edge_2", x = 1507.021, y = 822.925 },
        { id = "edge_3", x = 1656.612, y = 822.343 },
        { id = "edge_3", x = 1671.678, y = 837.408 },
        { id = "edge_3", x = 1702.437, y = 872.562 },
        { id = "edge_3", x = 1756.411, y = 872.552 },
        { id = "edge_3", x = 1765.839, y = 836.153 },
        { id = "edge_38", x = 1757.039, y = 806.592 },
        { id = "edge_2", x = 1728.803, y = 791.583 },
        { id = "edge_2", x = 1709.97, y = 779.656 },
        { id = "edge_2", x = 1709.343, y = 106.716 },
        { id = "edge_2", x = 1733.824, y = 90.395 },
        { id = "edge_2", x = 1773.372, y = 90.395 },
        { id = "edge_2", x = 1772.117, y = 5.022 },
        { id = "edge_2", x = 1676.072, y = 3.139 },
        { id = "edge_2", x = 1673.561, y = 44.57 },
        { id = "edge_2", x = 1657.24, y = 64.657 },
        { id = "edge_2", x = 935.336, y = 62.146 },
    },
    pockets = {
        { id = "top_left", x = -15.002, y = -17.994, spriteX = 49.254, spriteY = 39.441, mouthRadius = 46.82, commitRadius = 46.352 },
        { id = "top_middle", x = 450.375, y = -20.809, spriteX = 887.676, spriteY = 33.816, mouthRadius = 46.82, commitRadius = 46.352 },
        { id = "top_right", x = 911.309, y = -15.726, spriteX = 1718.091, spriteY = 43.973, mouthRadius = 46.82, commitRadius = 46.352 },
        { id = "bottom_left", x = -16.539, y = 382.298, spriteX = 46.486, spriteY = 839.258, mouthRadius = 46.82, commitRadius = 46.352 },
        { id = "bottom_middle", x = 452.441, y = 388.9, spriteX = 891.397, spriteY = 852.45, captureRadius = 27, gravityRadius = 37.296, mouthRadius = 41.82, commitRadius = 40.728 },
        { id = "bottom_right", x = 914.447, y = 383.241, spriteX = 1723.745, spriteY = 841.142, mouthRadius = 46.82, commitRadius = 46.352 },
    },
    rackLayouts = {
        nine_ball = {
            { id = 1, col = 0, row = 0 },
            { id = 2, col = 1, row = -0.5 },
            { id = 3, col = 1, row = 0.5 },
            { id = 4, col = 2, row = -1 },
            { id = 9, col = 2, row = 0 },
            { id = 5, col = 2, row = 1 },
            { id = 6, col = 3, row = -0.5 },
            { id = 7, col = 3, row = 0.5 },
            { id = 8, col = 4, row = 0 },
        },
        eight_ball = {
            { id = 1, col = 0, row = 0 },
            { id = 9, col = 1, row = -0.5 },
            { id = 2, col = 1, row = 0.5 },
            { id = 10, col = 2, row = -1 },
            { id = 8, col = 2, row = 0 },
            { id = 3, col = 2, row = 1 },
            { id = 11, col = 3, row = -1.5 },
            { id = 4, col = 3, row = -0.5 },
            { id = 12, col = 3, row = 0.5 },
            { id = 5, col = 3, row = 1.5 },
            { id = 13, col = 4, row = -2 },
            { id = 6, col = 4, row = -1 },
            { id = 14, col = 4, row = 0 },
            { id = 7, col = 4, row = 1 },
            { id = 15, col = 4, row = 2 },
        },
    },
}

PP.TABLE_W = PP.TABLE_GEOMETRY.tableW
PP.TABLE_H = PP.TABLE_GEOMETRY.tableH
PP.BALL_R = PP.TABLE_GEOMETRY.visualBallRadius
PP.BALL_PHYSICS_R = PP.TABLE_GEOMETRY.physicsBallRadius
PP.CUE_SPOT_X = PP.TABLE_W * 0.25
PP.RACK_SPOT_X = PP.TABLE_W * 0.67
PP.POCKET_R = PP.TABLE_GEOMETRY.pocketCaptureRadius
PP.BALL_SPRITE_TEXTURE_SIZE = PP.TABLE_GEOMETRY.ballSpriteTextureSize
PP.BALL_SPRITE_VISIBLE_SIZE = PP.TABLE_GEOMETRY.ballSpriteVisibleSize
PP.MAX_POWER = 850
PP.SHOT_POWER_MULTIPLIER = 1.25
PP.MAX_PLAY_DISTANCE = 8
PP.SHOT_MAX_DISTANCE = 2.75
PP.ANIMATION_TICKS_PER_FRAME = 9
PP.ANIMATION_FRAME_MS = 35
PP.MOOD_RELIEF_SCALE = 0.4025
PP.ABANDONED_SESSION_MINUTES = 20
PP.GAME_MODE = "9-ball lite"
PP.DEFAULT_MODE_ID = "eight_ball"
PP.WIN_BALL_ID = 9
PP.EVENT_LIMIT = 8

PP.POCKET_LABELS = {
    top_left = "top left",
    top_middle = "top middle",
    top_right = "top right",
    bottom_left = "bottom left",
    bottom_middle = "bottom middle",
    bottom_right = "bottom right",
}

PP.POCKET_ORDER = {
    "top_left",
    "top_middle",
    "top_right",
    "bottom_left",
    "bottom_middle",
    "bottom_right",
}

PP.GAME_MODES = {
    {
        id = "eight_ball",
        name = "8-Ball",
        shortName = "8-Ball",
        icon = "mode_8ball.png",
        description = "Solids and stripes. Clear your group, then sink the 8.",
    },
    {
        id = "nine_ball",
        name = "9-Ball",
        shortName = "9-Ball",
        icon = "mode_9ball.png",
        description = "Hit the lowest ball first. Legally sink the 9 to win.",
    },
}

PP.GAME_MODE_BY_ID = {}
for i = 1, #PP.GAME_MODES do
    PP.GAME_MODE_BY_ID[PP.GAME_MODES[i].id] = PP.GAME_MODES[i]
end

PP.AI_DIFFICULTY_ORDER = { "easy", "medium", "hard" }
PP.AI_DIFFICULTIES = {
    easy = {
        id = "easy",
        name = "Easy",
        playerName = "Easy Bot",
        skillLevel = 2,
        aimError = math.rad(7.5),
        powerError = 0.18,
        planNoise = 0.30,
        thinkingMs = 900,
        aimStepMs = 340,
        aimSteps = 4,
        shootDelayMs = 520,
        xpScale = 0.65,
    },
    medium = {
        id = "medium",
        name = "Medium",
        playerName = "Medium Bot",
        skillLevel = 5,
        aimError = math.rad(3.25),
        powerError = 0.09,
        planNoise = 0.14,
        thinkingMs = 1100,
        aimStepMs = 320,
        aimSteps = 5,
        shootDelayMs = 520,
        xpScale = 1.00,
    },
    hard = {
        id = "hard",
        name = "Hard",
        playerName = "Hard Bot",
        skillLevel = 8,
        aimError = math.rad(1.15),
        powerError = 0.04,
        planNoise = 0.04,
        thinkingMs = 1250,
        aimStepMs = 300,
        aimSteps = 6,
        shootDelayMs = 460,
        xpScale = 1.30,
    },
}

PP.DEFAULT_CONFIG = {
    BoredomReliefPerTurn = 18,
    MaxPlayDistance = 8,
    AllowAdminSoloPractice = true,
    AllowSpectators = true,
    EnableBetaMinigames = false,
    AbandonedSessionMinutes = 20,
    StressReliefPerTurn = 0,
    UnhappinessReliefPerTurn = 0,
}

PP.BALL_COLORS = {
    cue = { r = 0.92, g = 0.88, b = 0.72 },
    [1] = { r = 0.95, g = 0.82, b = 0.16 },
    [2] = { r = 0.14, g = 0.38, b = 0.90 },
    [3] = { r = 0.85, g = 0.15, b = 0.10 },
    [4] = { r = 0.48, g = 0.22, b = 0.74 },
    [5] = { r = 0.96, g = 0.50, b = 0.12 },
    [6] = { r = 0.12, g = 0.62, b = 0.20 },
    [7] = { r = 0.58, g = 0.16, b = 0.08 },
    [8] = { r = 0.04, g = 0.04, b = 0.04 },
}

function PP.atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    if x > 0 then
        return math.atan(y / x)
    end
    if x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    end
    if x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    end
    if x == 0 and y > 0 then
        return math.pi / 2
    end
    if x == 0 and y < 0 then
        return -math.pi / 2
    end
    return 0
end

function PP.ballPhysicsRadius()
    return (PP.TABLE_GEOMETRY and PP.TABLE_GEOMETRY.physicsBallRadius) or PP.BALL_PHYSICS_R or PP.BALL_R
end

function PP.ballVisualRadius()
    return (PP.TABLE_GEOMETRY and PP.TABLE_GEOMETRY.visualBallRadius) or PP.BALL_R
end

function PP.getTableGeometry()
    return PP.TABLE_GEOMETRY
end

function PP.getRailBounds()
    local boundary = PP.getPlayableBoundary and PP.getPlayableBoundary() or nil
    if boundary and #boundary > 0 then
        local left = boundary[1].x
        local right = boundary[1].x
        local top = boundary[1].y
        local bottom = boundary[1].y
        for i = 2, #boundary do
            local p = boundary[i]
            left = math.min(left, p.x)
            right = math.max(right, p.x)
            top = math.min(top, p.y)
            bottom = math.max(bottom, p.y)
        end
        return { left = left, top = top, right = right, bottom = bottom }
    end
    return {
        left = PP.ballPhysicsRadius(),
        top = PP.ballPhysicsRadius(),
        right = PP.TABLE_W - PP.ballPhysicsRadius(),
        bottom = PP.TABLE_H - PP.ballPhysicsRadius(),
    }
end

function PP.getPocketCenters()
    local geometry = PP.getTableGeometry()
    return geometry and geometry.pockets or {}
end

function PP.getPocketCaptureRadius(pocket)
    if pocket and pocket.captureRadius then
        return pocket.captureRadius
    end
    local geometry = PP.getTableGeometry()
    return geometry and geometry.pocketCaptureRadius or PP.POCKET_R
end

function PP.getPocketGravityRadius(pocket)
    if pocket and pocket.gravityRadius then
        return pocket.gravityRadius
    end
    local geometry = PP.getTableGeometry()
    return geometry and geometry.pocketGravityRadius or (PP.POCKET_R + PP.ballPhysicsRadius() * 0.78)
end

function PP.getPocketMouthRadius()
    local geometry = PP.getTableGeometry()
    return geometry and geometry.pocketMouthRadius or (PP.POCKET_R + PP.ballPhysicsRadius() * 0.95)
end

function PP.getPlayfieldMap()
    local geometry = PP.getTableGeometry()
    return geometry and geometry.playfield or { insetX = 0.043, insetTop = 0.085, insetBottom = 0.059 }
end

local function geometrySpriteRect()
    local geometry = PP.getTableGeometry() or {}
    local map = PP.getPlayfieldMap()
    local spriteW = geometry.spriteW or TABLE_SPRITE_W
    local spriteH = geometry.spriteH or TABLE_SPRITE_H
    local x = spriteW * (map.insetX or 0)
    local y = spriteH * (map.insetTop or 0)
    local w = spriteW * (1 - (map.insetX or 0) * 2)
    local h = spriteH * (1 - (map.insetTop or 0) - (map.insetBottom or 0))
    return x, y, w, h
end

function PP.tableToSprite(x, y)
    local sx, sy, sw, sh = geometrySpriteRect()
    return sx + (tonumber(x) or 0) / PP.TABLE_W * sw, sy + (tonumber(y) or 0) / PP.TABLE_H * sh
end

function PP.spriteToTable(x, y)
    local sx, sy, sw, sh = geometrySpriteRect()
    return ((tonumber(x) or 0) - sx) / sw * PP.TABLE_W, ((tonumber(y) or 0) - sy) / sh * PP.TABLE_H
end

local function copyPointList(points)
    local result = {}
    for i = 1, #(points or {}) do
        local point = points[i]
        result[i] = { id = point.id, x = point.x, y = point.y }
    end
    return result
end

function PP.getCollisionEdge(space)
    local geometry = PP.getTableGeometry()
    local edge = geometry and geometry.collisionEdge or {}
    if space == "sprite" then
        return copyPointList(edge)
    end
    if geometry and geometry._collisionEdgeTable and geometry._collisionEdgeTableSource == edge then
        return geometry._collisionEdgeTable
    end
    local result = {}
    for i = 1, #edge do
        local x, y = PP.spriteToTable(edge[i].x, edge[i].y)
        result[i] = { id = edge[i].id, x = x, y = y }
    end
    if geometry then
        geometry._collisionEdgeTable = result
        geometry._collisionEdgeTableSource = edge
    end
    return result
end

local function segmentClosestPoint(px, py, ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    local lenSq = dx * dx + dy * dy
    if lenSq <= 0.000001 then
        return ax, ay, 0
    end
    local t = ((px - ax) * dx + (py - ay) * dy) / lenSq
    if t < 0 then
        t = 0
    elseif t > 1 then
        t = 1
    end
    return ax + dx * t, ay + dy * t, t
end

local function segmentLength(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    return math.sqrt(dx * dx + dy * dy)
end

local function visualSegments(space)
    local edge = PP.getCollisionEdge(space)
    local result = {}
    for i = 1, #edge do
        local a = edge[i]
        local b = edge[i % #edge + 1]
        local len = segmentLength(a, b)
        if len > 0.000001 then
            result[#result + 1] = {
                id = (a.id or ("edge_" .. tostring(i))) .. "_to_" .. tostring(b.id or ("edge_" .. tostring(i % #edge + 1))),
                index = i,
                ax = a.x,
                ay = a.y,
                bx = b.x,
                by = b.y,
                length = len,
            }
        end
    end
    return result
end

function PP.getVisualCollisionSegments(space)
    return visualSegments(space or "table")
end

local function pocketMouthBridgeForSegment(seg, pocket)
    if not seg or not pocket then
        return false
    end
    local mouthR = pocket.mouthRadius or PP.getPocketMouthRadius()
    local cx, cy = pocket.x, pocket.y
    local px, py, t = segmentClosestPoint(cx, cy, seg.ax, seg.ay, seg.bx, seg.by)
    local closestDist = math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy))
    if closestDist > mouthR * 0.62 or t <= 0.08 or t >= 0.92 then
        return false
    end
    local axDist = math.sqrt((seg.ax - cx) * (seg.ax - cx) + (seg.ay - cy) * (seg.ay - cy))
    local bxDist = math.sqrt((seg.bx - cx) * (seg.bx - cx) + (seg.by - cy) * (seg.by - cy))
    local endpointDist = math.min(axDist, bxDist)
    if endpointDist <= 0.000001 then
        return false
    end
    if closestDist > endpointDist * 0.93 then
        return false
    end
    return seg.length >= mouthR * 0.35
end

local function segmentCrossesPocketMouth(seg)
    local pockets = PP.getPocketCenters()
    for i = 1, #pockets do
        if pocketMouthBridgeForSegment(seg, pockets[i]) then
            return true, pockets[i]
        end
    end
    return false, nil
end

function PP.getPocketMouthBridgeSegments(space)
    local geometry = PP.getTableGeometry()
    local cacheField = space == "sprite" and "_pocketMouthBridgeSegmentsSprite" or "_pocketMouthBridgeSegmentsTable"
    local edge = geometry and geometry.collisionEdge or nil
    if geometry and geometry[cacheField] and geometry._pocketMouthBridgeSegmentsSource == edge then
        return geometry[cacheField]
    end
    local tableSegments = visualSegments("table")
    local result = {}
    for i = 1, #tableSegments do
        local isBridge, pocket = segmentCrossesPocketMouth(tableSegments[i])
        if isBridge then
            local seg = tableSegments[i]
            if space == "sprite" then
                local ax, ay = PP.tableToSprite(seg.ax, seg.ay)
                local bx, by = PP.tableToSprite(seg.bx, seg.by)
                result[#result + 1] = { id = seg.id, index = seg.index, pocketId = pocket and pocket.id, ax = ax, ay = ay, bx = bx, by = by }
            else
                result[#result + 1] = { id = seg.id, index = seg.index, pocketId = pocket and pocket.id, ax = seg.ax, ay = seg.ay, bx = seg.bx, by = seg.by }
            end
        end
    end
    if geometry then
        geometry[cacheField] = result
        geometry._pocketMouthBridgeSegmentsSource = edge
    end
    return result
end

local function polygonSignedArea(points)
    local area = 0
    for i = 1, #points do
        local a = points[i]
        local b = points[i % #points + 1]
        area = area + (a.x * b.y - b.x * a.y)
    end
    return area * 0.5
end

function PP.polygonSignedArea(points)
    return polygonSignedArea(points or {})
end

function PP.pointInPolygon(x, y, points)
    local inside = false
    local count = #(points or {})
    if count < 3 then
        return false
    end
    local j = count
    for i = 1, count do
        local pi = points[i]
        local pj = points[j]
        if ((pi.y > y) ~= (pj.y > y)) and (x < (pj.x - pi.x) * (y - pi.y) / ((pj.y - pi.y) ~= 0 and (pj.y - pi.y) or 0.000001) + pi.x) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function lineIntersection(a, b)
    local det = a.dx * b.dy - a.dy * b.dx
    if math.abs(det) < 0.000001 then
        return nil
    end
    local ox = b.x - a.x
    local oy = b.y - a.y
    local t = (ox * b.dy - oy * b.dx) / det
    return { x = a.x + a.dx * t, y = a.y + a.dy * t }
end

function PP.offsetPolygon(points, amount)
    points = points or {}
    if #points < 3 then
        return copyPointList(points)
    end
    local area = polygonSignedArea(points)
    local lines = {}
    for i = 1, #points do
        local a = points[i]
        local b = points[i % #points + 1]
        local dx = b.x - a.x
        local dy = b.y - a.y
        local len = math.sqrt(dx * dx + dy * dy)
        if len <= 0.000001 then
            dx, dy, len = 1, 0, 1
        end
        dx = dx / len
        dy = dy / len
        local nx, ny
        if area >= 0 then
            nx, ny = -dy, dx
        else
            nx, ny = dy, -dx
        end
        lines[i] = { x = a.x + nx * amount, y = a.y + ny * amount, dx = dx, dy = dy, nx = nx, ny = ny }
    end
    local result = {}
    for i = 1, #lines do
        local prev = lines[i == 1 and #lines or i - 1]
        local current = lines[i]
        local p = lineIntersection(prev, current)
        if not p then
            p = { x = points[i].x + current.nx * amount, y = points[i].y + current.ny * amount }
        end
        result[i] = { id = points[i].id, x = p.x, y = p.y }
    end
    return result
end

function PP.getPlayableBoundary()
    local geometry = PP.getTableGeometry()
    local cacheKey = tostring(PP.ballPhysicsRadius())
    if geometry and geometry._playableBoundary and geometry._playableBoundaryKey == cacheKey then
        return geometry._playableBoundary
    end
    local boundary = PP.offsetPolygon(PP.getCollisionEdge("table"), PP.ballPhysicsRadius())
    if geometry then
        geometry._playableBoundary = boundary
        geometry._playableBoundaryKey = cacheKey
    end
    return boundary
end

function PP.getCollisionSegments()
    local geometry = PP.getTableGeometry()
    local edgeSource = geometry and geometry.collisionEdge or nil
    local cacheKey = tostring(PP.ballPhysicsRadius())
    if geometry and geometry._collisionSegments and geometry._collisionSegmentsSource == edgeSource and geometry._collisionSegmentsKey == cacheKey then
        return geometry._collisionSegments
    end
    local edge = PP.getCollisionEdge("table")
    local area = polygonSignedArea(edge)
    local amount = PP.ballPhysicsRadius()
    local segments = {}
    local visual = visualSegments("table")
    for i = 1, #visual do
        local seg = visual[i]
        if not segmentCrossesPocketMouth(seg) then
            local a = { x = seg.ax, y = seg.ay }
            local b = { x = seg.bx, y = seg.by }
            local dx = b.x - a.x
            local dy = b.y - a.y
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0.000001 then
                local nx, ny
                if area >= 0 then
                    nx, ny = -dy / len, dx / len
                else
                    nx, ny = dy / len, -dx / len
                end
                segments[#segments + 1] = {
                    id = seg.id or ("edge_" .. tostring(i)),
                    ax = a.x + nx * amount,
                    ay = a.y + ny * amount,
                    bx = b.x + nx * amount,
                    by = b.y + ny * amount,
                    minX = math.min(a.x + nx * amount, b.x + nx * amount),
                    maxX = math.max(a.x + nx * amount, b.x + nx * amount),
                    minY = math.min(a.y + ny * amount, b.y + ny * amount),
                    maxY = math.max(a.y + ny * amount, b.y + ny * amount),
                    visualAx = a.x,
                    visualAy = a.y,
                    visualBx = b.x,
                    visualBy = b.y,
                    nx = nx,
                    ny = ny,
                }
            end
        end
    end
    if geometry then
        geometry._collisionSegments = segments
        geometry._collisionSegmentsSource = edgeSource
        geometry._collisionSegmentsKey = cacheKey
    end
    return segments
end

function PP.getCollisionSegmentsInSprite()
    local geometry = PP.getTableGeometry()
    local edgeSource = geometry and geometry.collisionEdge or nil
    local cacheKey = tostring(PP.ballPhysicsRadius())
    if geometry and geometry._collisionSegmentsSprite and geometry._collisionSegmentsSpriteSource == edgeSource and geometry._collisionSegmentsSpriteKey == cacheKey then
        return geometry._collisionSegmentsSprite
    end
    local tableSegments = PP.getCollisionSegments()
    local result = {}
    for i = 1, #tableSegments do
        local seg = tableSegments[i]
        local ax, ay = PP.tableToSprite(seg.ax, seg.ay)
        local bx, by = PP.tableToSprite(seg.bx, seg.by)
        result[i] = { id = seg.id, ax = ax, ay = ay, bx = bx, by = by, nx = seg.nx, ny = seg.ny }
    end
    if geometry then
        geometry._collisionSegmentsSprite = result
        geometry._collisionSegmentsSpriteSource = edgeSource
        geometry._collisionSegmentsSpriteKey = cacheKey
    end
    return result
end

function PP.getCollisionInteriorBounds()
    local geometry = PP.getTableGeometry()
    local edgeSource = geometry and geometry.collisionEdge or nil
    local cacheKey = tostring(PP.ballPhysicsRadius())
    if geometry and geometry._collisionInteriorBounds and geometry._collisionInteriorBoundsSource == edgeSource and geometry._collisionInteriorBoundsKey == cacheKey then
        return geometry._collisionInteriorBounds
    end
    local segments = PP.getCollisionSegments()
    local left = -math.huge
    local right = math.huge
    local top = -math.huge
    local bottom = math.huge
    for i = 1, #segments do
        local seg = segments[i]
        if (seg.nx or 0) > 0.55 then
            left = math.max(left, seg.maxX or math.max(seg.ax, seg.bx))
        elseif (seg.nx or 0) < -0.55 then
            right = math.min(right, seg.minX or math.min(seg.ax, seg.bx))
        end
        if (seg.ny or 0) > 0.55 then
            top = math.max(top, seg.maxY or math.max(seg.ay, seg.by))
        elseif (seg.ny or 0) < -0.55 then
            bottom = math.min(bottom, seg.minY or math.min(seg.ay, seg.by))
        end
    end
    if left == -math.huge or right == math.huge or top == -math.huge or bottom == math.huge or left >= right or top >= bottom then
        local rails = PP.getRailBounds()
        left = rails.left
        right = rails.right
        top = rails.top
        bottom = rails.bottom
    end
    local bounds = { left = left, right = right, top = top, bottom = bottom }
    if geometry then
        geometry._collisionInteriorBounds = bounds
        geometry._collisionInteriorBoundsSource = edgeSource
        geometry._collisionInteriorBoundsKey = cacheKey
    end
    return bounds
end

function PP.getCollisionSegmentsForEdge(edgePoints)
    local saved = PP.TABLE_GEOMETRY and PP.TABLE_GEOMETRY.collisionEdge
    if not PP.TABLE_GEOMETRY then
        return {}
    end
    PP.TABLE_GEOMETRY.collisionEdge = edgePoints or {}
    PP.TABLE_GEOMETRY._playableBoundary = nil
    PP.TABLE_GEOMETRY._playableBoundaryKey = nil
    PP.TABLE_GEOMETRY._collisionEdgeTable = nil
    PP.TABLE_GEOMETRY._collisionEdgeTableSource = nil
    PP.TABLE_GEOMETRY._collisionSegments = nil
    PP.TABLE_GEOMETRY._collisionSegmentsSource = nil
    PP.TABLE_GEOMETRY._collisionSegmentsSprite = nil
    PP.TABLE_GEOMETRY._collisionSegmentsSpriteSource = nil
    PP.TABLE_GEOMETRY._collisionInteriorBounds = nil
    PP.TABLE_GEOMETRY._collisionInteriorBoundsSource = nil
    PP.TABLE_GEOMETRY._pocketMouthBridgeSegmentsTable = nil
    PP.TABLE_GEOMETRY._pocketMouthBridgeSegmentsSprite = nil
    local segments = PP.getCollisionSegmentsInSprite()
    PP.TABLE_GEOMETRY.collisionEdge = saved
    PP.TABLE_GEOMETRY._playableBoundary = nil
    PP.TABLE_GEOMETRY._playableBoundaryKey = nil
    PP.TABLE_GEOMETRY._collisionEdgeTable = nil
    PP.TABLE_GEOMETRY._collisionEdgeTableSource = nil
    PP.TABLE_GEOMETRY._collisionSegments = nil
    PP.TABLE_GEOMETRY._collisionSegmentsSource = nil
    PP.TABLE_GEOMETRY._collisionSegmentsSprite = nil
    PP.TABLE_GEOMETRY._collisionSegmentsSpriteSource = nil
    PP.TABLE_GEOMETRY._collisionInteriorBounds = nil
    PP.TABLE_GEOMETRY._collisionInteriorBoundsSource = nil
    PP.TABLE_GEOMETRY._pocketMouthBridgeSegmentsTable = nil
    PP.TABLE_GEOMETRY._pocketMouthBridgeSegmentsSprite = nil
    return segments
end

function PP.isInsidePlayableBoundary(x, y)
    return PP.pointInPolygon(tonumber(x) or 0, tonumber(y) or 0, PP.getPlayableBoundary())
end

function PP.getRackLayout(modeId)
    local geometry = PP.getTableGeometry()
    local layouts = geometry and geometry.rackLayouts or {}
    return layouts[modeId or PP.DEFAULT_MODE_ID] or layouts[PP.DEFAULT_MODE_ID] or layouts.eight_ball or {}
end

function PP.getPocketById(pocketId)
    if not pocketId then
        return nil
    end
    local pockets = PP.getPocketCenters()
    for i = 1, #pockets do
        if pockets[i].id == pocketId then
            return pockets[i]
        end
    end
    return nil
end

function PP.pocketLabel(pocketId)
    return PP.POCKET_LABELS[pocketId] or tostring(pocketId or "-")
end

function PP.statusForPhase(phase)
    if phase == PP.PHASE_CHOOSING_MODE then
        return "choosing"
    end
    if phase == PP.PHASE_WAITING_FOR_PLAYERS then
        return "waiting"
    end
    if phase == PP.PHASE_GAME_OVER then
        return "finished"
    end
    return "playing"
end

function PP.phaseForState(state)
    if not state or not state.modeSelected then
        return PP.PHASE_CHOOSING_MODE
    end
    if state.winner then
        return PP.PHASE_GAME_OVER
    end
    if #(state.players or {}) < 2 then
        return PP.PHASE_WAITING_FOR_PLAYERS
    end
    if state.phase == PP.PHASE_AIMING and not state.aim then
        return PP.PHASE_TURN_READY
    end
    return state.phase or PP.PHASE_TURN_READY
end

function PP.setPhase(state, phase)
    if not state then
        return
    end
    state.phase = phase or PP.phaseForState(state)
    state.status = PP.statusForPhase(state.phase)
end

function PP.refreshStatePhase(state)
    if not state then
        return
    end
    if not state.modeSelected then
        PP.setPhase(state, PP.PHASE_CHOOSING_MODE)
    elseif state.winner then
        PP.setPhase(state, PP.PHASE_GAME_OVER)
    elseif #(state.players or {}) < 2 then
        PP.setPhase(state, PP.PHASE_WAITING_FOR_PLAYERS)
    elseif state.phase == PP.PHASE_AIMING and not state.aim then
        PP.setPhase(state, PP.PHASE_TURN_READY)
    elseif not state.phase or state.phase == PP.PHASE_CHOOSING_MODE or state.phase == PP.PHASE_WAITING_FOR_PLAYERS then
        PP.setPhase(state, PP.PHASE_TURN_READY)
    else
        PP.setPhase(state, state.phase)
    end
end

function PP.copyTable(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for k, v in pairs(value) do
        result[k] = PP.copyTable(v, seen)
    end
    return result
end

function PP.getConfigValue(name)
    local defaults = PP.DEFAULT_CONFIG or {}
    local value = defaults[name]
    if SandboxVars and SandboxVars.PlayablePool and SandboxVars.PlayablePool[name] ~= nil then
        value = SandboxVars.PlayablePool[name]
    end
    return value
end

function PP.getConfigNumber(name)
    local value = tonumber(PP.getConfigValue(name))
    if value == nil then
        return tonumber(PP.DEFAULT_CONFIG[name]) or 0
    end
    return value
end

function PP.getConfigBoolean(name)
    local value = PP.getConfigValue(name)
    if value == false or value == "false" or value == 0 or value == "0" then
        return false
    end
    return true
end

function PP.sendClientCommand(playerObj, module, command, args)
    if not sendClientCommand then
        return false
    end
    local ok = pcall(function()
        sendClientCommand(playerObj, module, command, args)
    end)
    if ok then
        return true
    end
    ok = pcall(function()
        sendClientCommand(module, command, args)
    end)
    return ok
end

function PP.addXp(playerObj, perk, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not playerObj or not perk or amount <= 0 or not playerObj.getXp then
        return false
    end
    local xp = playerObj:getXp()
    if not xp or not xp.AddXP then
        return false
    end
    local ok = pcall(function()
        xp:AddXP(perk, amount, false, false, false, false)
    end)
    if ok then
        return true
    end
    ok = pcall(function()
        xp:AddXP(perk, amount)
    end)
    return ok
end

local function applyLegacyStatsValue(owner, getterName, setterName, amount)
    if not owner or not owner[getterName] or not owner[setterName] then
        return false
    end
    local ok, current = pcall(function()
        return owner[getterName](owner)
    end)
    if not ok or current == nil then
        return false
    end
    current = tonumber(current) or 0
    local delta = current > 1 and amount or (amount / 100)
    local nextValue = math.max(0, current - delta)
    ok = pcall(function()
        owner[setterName](owner, nextValue)
    end)
    return ok and nextValue ~= current
end

function PP.applyCharacterStat(playerObj, statName, amount)
    amount = tonumber(amount) or 0
    if not playerObj or amount <= 0 then
        return false
    end

    local stats = playerObj.getStats and playerObj:getStats() or nil
    if CharacterStat and stats and stats.add then
        local stat = nil
        if statName == "BOREDOM" then
            stat = CharacterStat.BOREDOM
        elseif statName == "STRESS" then
            stat = CharacterStat.STRESS
        elseif statName == "UNHAPPINESS" then
            stat = CharacterStat.UNHAPPINESS
        end
        if stat then
            local ok, changed = pcall(function()
                return stats:add(stat, -amount)
            end)
            if ok then
                return changed and true or false
            end
        end
    end

    if statName == "BOREDOM" then
        return applyLegacyStatsValue(stats, "getBoredom", "setBoredom", amount)
    end
    if statName == "STRESS" then
        return applyLegacyStatsValue(stats, "getStress", "setStress", amount)
    end
    if statName == "UNHAPPINESS" then
        local bodyDamage = playerObj.getBodyDamage and playerObj:getBodyDamage() or nil
        return applyLegacyStatsValue(bodyDamage, "getUnhappynessLevel", "setUnhappynessLevel", amount)
            or applyLegacyStatsValue(bodyDamage, "getUnhappinessLevel", "setUnhappinessLevel", amount)
    end
    return false
end

function PP.addEvent(state, text, kind)
    if not state or not text then
        return
    end
    state.events = state.events or {}
    table.insert(state.events, {
        text = tostring(text),
        kind = kind or "info",
        shotNumber = state.shotNumber or 0,
    })
    while #state.events > PP.EVENT_LIMIT do
        table.remove(state.events, 1)
    end
end

function PP.findNameIndex(list, name)
    if not list or not name then
        return nil
    end
    for i = 1, #list do
        if list[i] == name then
            return i
        end
    end
    return nil
end

function PP.removeName(list, name)
    if not list or not name then
        return false
    end
    local removed = false
    for i = #list, 1, -1 do
        if list[i] == name then
            table.remove(list, i)
            removed = true
        end
    end
    return removed
end

function PP.nextRackBreakerName(players, previousBreakerName, requesterName)
    if not players or #players == 0 then
        return nil
    end
    local previousIndex = PP.findNameIndex(players, previousBreakerName)
    if previousIndex then
        local nextIndex = previousIndex + 1
        if nextIndex > #players then
            nextIndex = 1
        end
        return players[nextIndex]
    end
    return players[PP.findNameIndex(players, requesterName) or 1]
end

function PP.applyRackBreaker(state, breakerName, fallbackName)
    if not state or not state.players or #state.players == 0 then
        return nil
    end
    local index = PP.findNameIndex(state.players, breakerName) or PP.findNameIndex(state.players, fallbackName) or 1
    state.currentPlayer = index
    state.breakerName = state.players[index]
    return state.breakerName
end

function PP.getGameMode(modeId)
    return PP.GAME_MODE_BY_ID[modeId or PP.DEFAULT_MODE_ID] or PP.GAME_MODE_BY_ID[PP.DEFAULT_MODE_ID]
end

function PP.getGameModeName(modeId)
    local mode = PP.getGameMode(modeId)
    return mode and mode.name or PP.GAME_MODE
end

function PP.isValidGameMode(modeId)
    return modeId and PP.GAME_MODE_BY_ID[modeId] ~= nil
end

function PP.getAIDifficulty(difficultyId)
    return PP.AI_DIFFICULTIES[difficultyId or "medium"] or PP.AI_DIFFICULTIES.medium
end

function PP.isAIDifficulty(difficultyId)
    return difficultyId and PP.AI_DIFFICULTIES[difficultyId] ~= nil
end

function PP.getAIPlayerName(difficultyId)
    local difficulty = PP.getAIDifficulty(difficultyId)
    return difficulty.playerName or "Pool Bot"
end

function PP.getStateAI(state)
    local ai = state and state.ai
    if not ai or not ai.playerName then
        return nil, nil
    end
    local difficulty = PP.getAIDifficulty(ai.difficulty)
    return ai, difficulty
end

function PP.isStateAIPlayer(state, playerName)
    local ai = state and state.ai
    return ai and playerName and ai.playerName == playerName and PP.findNameIndex(state.players or {}, playerName) ~= nil
end

function PP.initialModeState(modeId)
    local mode = PP.getGameMode(modeId)
    local state = {
        id = mode.id,
        scores = {},
        groups = {},
    }
    return state
end

function PP.isBreakShot(state)
    return state and (tonumber(state.shotNumber) or 0) == 0
end

function PP.isSolidBall(id)
    return type(id) == "number" and id >= 1 and id <= 7
end

function PP.isStripeBall(id)
    return type(id) == "number" and id >= 9 and id <= 15
end

function PP.ballGroupName(id)
    if PP.isSolidBall(id) then
        return "solids"
    end
    if PP.isStripeBall(id) then
        return "stripes"
    end
    return nil
end

function PP.keyForTable(x, y, z)
    return tostring(math.floor(tonumber(x) or 0)) .. ":" .. tostring(math.floor(tonumber(y) or 0)) .. ":" .. tostring(math.floor(tonumber(z) or 0))
end

function PP.getUsername(playerObj)
    if not playerObj then
        return "Unknown"
    end
    if playerObj.getUsername then
        local ok, name = pcall(function()
            return playerObj:getUsername()
        end)
        if ok and name and name ~= "" then
            return name
        end
    end
    if playerObj.getDisplayName then
        local ok, name = pcall(function()
            return playerObj:getDisplayName()
        end)
        if ok and name and name ~= "" then
            return name
        end
    end
    return "Player"
end

function PP.getSpriteName(isoObject)
    if not isoObject or not isoObject.getSprite then
        return nil
    end
    local ok, sprite = pcall(function()
        return isoObject:getSprite()
    end)
    if not ok or not sprite or not sprite.getName then
        return nil
    end
    ok, sprite = pcall(function()
        return sprite:getName()
    end)
    if ok then
        return sprite
    end
    return nil
end

function PP.getObjectProperty(isoObject, name)
    if not isoObject or not isoObject.getProperties then
        return nil
    end
    local ok, props = pcall(function()
        return isoObject:getProperties()
    end)
    if not ok or not props or not props.get then
        return nil
    end
    ok, props = pcall(function()
        return props:get(name)
    end)
    if ok then
        return props
    end
    return nil
end

PP.POOL_TABLE_SPRITES = PP.POOL_TABLE_SPRITES or {
    recreational_01_2 = true,
    recreational_01_3 = true,
    recreational_01_6 = true,
    recreational_01_7 = true,
}

function PP.isPoolTableObject(isoObject)
    local spriteName = PP.getSpriteName(isoObject)
    local customName = PP.getObjectProperty(isoObject, "CustomName")
    local groupName = PP.getObjectProperty(isoObject, "GroupName")
    local combined = tostring(spriteName or "") .. " " .. tostring(customName or "") .. " " .. tostring(groupName or "")
    combined = string.lower(combined)

    if string.find(combined, "pooltable", 1, true) or string.find(combined, "pool table", 1, true) then
        return true
    end
    if string.find(combined, "billiard", 1, true) or string.find(combined, "snooker", 1, true) then
        return true
    end
    if spriteName and PP.POOL_TABLE_SPRITES[string.lower(spriteName)] then
        return true
    end
    return false
end

function PP.findPoolTableFromWorldObjects(worldobjects)
    if not worldobjects then
        return nil
    end
    for i = 1, #worldobjects do
        local object = worldobjects[i]
        if PP.isPoolTableObject(object) then
            return object
        end
        if object and object.getSquare then
            local square = object:getSquare()
            if square and square.getObjects then
                local objects = square:getObjects()
                for j = 0, objects:size() - 1 do
                    local candidate = objects:get(j)
                    if PP.isPoolTableObject(candidate) then
                        return candidate
                    end
                end
            end
        end
    end
    return nil
end

function PP.getTableAnchor(isoObject)
    if not isoObject or not isoObject.getSquare then
        return nil
    end
    local square = isoObject:getSquare()
    if not square then
        return nil
    end

    local z = square:getZ()
    local minX = square:getX()
    local minY = square:getY()
    local cell = getCell()
    if cell then
        for dx = -2, 2 do
            for dy = -2, 2 do
                local scanSquare = cell:getGridSquare(square:getX() + dx, square:getY() + dy, z)
                if scanSquare and scanSquare.getObjects then
                    local objects = scanSquare:getObjects()
                    for i = 0, objects:size() - 1 do
                        if PP.isPoolTableObject(objects:get(i)) then
                            minX = math.min(minX, scanSquare:getX())
                            minY = math.min(minY, scanSquare:getY())
                        end
                    end
                end
            end
        end
    end

    return { x = minX, y = minY, z = z, key = PP.keyForTable(minX, minY, z) }
end

function PP.playerNearTable(playerObj, anchor)
    if not playerObj or not anchor then
        return false
    end
    local dx = playerObj:getX() - anchor.x
    local dy = playerObj:getY() - anchor.y
    local dz = math.abs(playerObj:getZ() - anchor.z)
    return dz < 1 and math.sqrt(dx * dx + dy * dy) <= PP.getConfigNumber("MaxPlayDistance")
end

function PP.playerAtShotDistance(playerObj, anchor)
    if not playerObj or not anchor then
        return false
    end
    local dx = playerObj:getX() - (anchor.x + 1)
    local dy = playerObj:getY() - (anchor.y + 1)
    local dz = math.abs(playerObj:getZ() - anchor.z)
    return dz < 1 and math.sqrt(dx * dx + dy * dy) <= PP.SHOT_MAX_DISTANCE
end

local RNG_MOD = 2147483647
local RNG_MUL = 48271

function PP.hashSeed(value)
    local text = tostring(value or "")
    local hash = 0
    for i = 1, string.len(text) do
        hash = (hash * 31 + string.byte(text, i)) % RNG_MOD
    end
    if hash <= 0 then
        hash = 1
    end
    return hash
end

local function seededNext(seed)
    seed = (tonumber(seed) or 1) % RNG_MOD
    if seed <= 0 then
        seed = 1
    end
    seed = (seed * RNG_MUL) % RNG_MOD
    return seed, seed / RNG_MOD
end

local function seededRange(seed, low, high)
    local value
    seed, value = seededNext(seed)
    return seed, low + (high - low) * value
end

local function seededInt(seed, low, high)
    local value
    seed, value = seededNext(seed)
    return seed, low + math.floor(value * (high - low + 1))
end

local function seededShuffle(values, seed)
    local result = PP.copyTable(values or {})
    for i = #result, 2, -1 do
        local j
        seed, j = seededInt(seed, 1, i)
        result[i], result[j] = result[j], result[i]
    end
    return result, seed
end

local function nowForSeed()
    if getTimestampMs then
        return getTimestampMs()
    end
    return os.time()
end

function PP.createRackSeed(anchor, modeId, rackNumber, breakerName)
    local parts = {
        "rack",
        modeId or PP.DEFAULT_MODE_ID,
        tostring(rackNumber or 1),
        tostring(breakerName or ""),
        anchor and anchor.key or "",
        tostring(nowForSeed()),
    }
    return table.concat(parts, ":")
end

local function rackSlots(modeId)
    local rack = PP.getRackLayout(modeId)
    local slots = {}
    for i = 1, #rack do
        slots[#slots + 1] = { col = rack[i].col, row = rack[i].row }
    end
    return slots
end

local function legalRackIds(modeId, seed)
    modeId = modeId or PP.DEFAULT_MODE_ID
    if modeId == "nine_ball" then
        local shuffled
        shuffled, seed = seededShuffle({ 2, 3, 4, 5, 6, 7, 8 }, seed)
        return { 1, shuffled[1], shuffled[2], shuffled[3], 9, shuffled[4], shuffled[5], shuffled[6], shuffled[7] }, seed
    end

    local cornerSeed
    seed, cornerSeed = seededInt(seed, 1, 2)
    local backLeft = cornerSeed == 1 and 1 or 9
    local backRight = cornerSeed == 1 and 9 or 1
    local remaining = {}
    for id = 1, 15 do
        if id ~= 8 and id ~= backLeft and id ~= backRight then
            remaining[#remaining + 1] = id
        end
    end
    local shuffled
    shuffled, seed = seededShuffle(remaining, seed)
    return {
        shuffled[1],
        shuffled[2],
        shuffled[3],
        shuffled[4],
        8,
        shuffled[5],
        shuffled[6],
        shuffled[7],
        shuffled[8],
        shuffled[9],
        backLeft,
        shuffled[10],
        shuffled[11],
        shuffled[12],
        backRight,
    }, seed
end

local function rackJitter(seed, id, modeId)
    if id == 8 or (modeId == "nine_ball" and (id == 1 or id == 9)) then
        return 0, 0, seed
    end
    local physicsR = PP.ballPhysicsRadius()
    local maxOffset = physicsR * 0.018
    local xOffset, yOffset
    seed, xOffset = seededRange(seed, -maxOffset, maxOffset)
    seed, yOffset = seededRange(seed, -maxOffset, maxOffset)
    return xOffset, yOffset, seed
end

local function ballWouldOverlap(balls, x, y, diameter)
    for i = 1, #balls do
        local ball = balls[i]
        if type(ball.id) == "number" and not ball.pocketed then
            local dx = (ball.x or 0) - x
            local dy = (ball.y or 0) - y
            if dx * dx + dy * dy < diameter * diameter then
                return true
            end
        end
    end
    return false
end

function PP.newRack(modeId, rackSeed)
    modeId = modeId or PP.DEFAULT_MODE_ID
    rackSeed = rackSeed or ("stable:" .. tostring(modeId))
    local balls = {}
    table.insert(balls, { id = "cue", x = PP.CUE_SPOT_X, y = PP.TABLE_H / 2, vx = 0, vy = 0, pocketed = false })
    local startX = PP.RACK_SPOT_X
    local startY = PP.TABLE_H / 2
    local physicsR = PP.ballPhysicsRadius()
    local seed = PP.hashSeed(rackSeed)
    local gapScale
    seed, gapScale = seededRange(seed, 1.006, 1.018)
    local gapX = math.sqrt(3) * physicsR * gapScale
    local gapY = 2 * physicsR * gapScale
    local slots = rackSlots(modeId)
    local ids
    ids, seed = legalRackIds(modeId, seed)
    for i = 1, #slots do
        local xOffset, yOffset
        xOffset, yOffset, seed = rackJitter(seed, ids[i], modeId)
        local baseX = startX + slots[i].col * gapX
        local baseY = startY + slots[i].row * gapY
        local x = baseX + xOffset
        local y = baseY + yOffset
        while ballWouldOverlap(balls, x, y, physicsR * 2.01) do
            xOffset = xOffset * 0.5
            yOffset = yOffset * 0.5
            x = baseX + xOffset
            y = baseY + yOffset
            if math.abs(xOffset) < 0.001 and math.abs(yOffset) < 0.001 then
                x = baseX
                y = baseY
                break
            end
        end
        table.insert(balls, {
            id = ids[i],
            x = x,
            y = y,
            vx = 0,
            vy = 0,
            pocketed = false,
        })
    end
    return balls
end

function PP.refreshRack(state, modeId, rackSeed)
    if not state then
        return nil
    end
    modeId = modeId or state.modeId or PP.DEFAULT_MODE_ID
    rackSeed = rackSeed or PP.createRackSeed(state.anchor, modeId, state.rackNumber, state.breakerName or PP.currentPlayerName(state))
    state.rackSeed = rackSeed
    state.rackEntropy = {
        seed = rackSeed,
        modeId = modeId,
        rackNumber = tonumber(state.rackNumber) or 1,
    }
    state.balls = PP.newRack(modeId, rackSeed)
    return rackSeed
end

function PP.newState(anchor, ownerName, modeId)
    local hasMode = PP.isValidGameMode(modeId)
    local mode = PP.getGameMode(hasMode and modeId or PP.DEFAULT_MODE_ID)
    local phase = hasMode and PP.PHASE_WAITING_FOR_PLAYERS or PP.PHASE_CHOOSING_MODE
    local rackSeed = PP.createRackSeed(anchor, mode.id, 1, ownerName)
    local state = {
        key = anchor.key,
        anchor = PP.copyTable(anchor),
        players = { ownerName },
        spectators = {},
        currentPlayer = 1,
        breakerName = ownerName,
        rackNumber = 1,
        rackSeed = rackSeed,
        rackEntropy = {
            seed = rackSeed,
            modeId = mode.id,
            rackNumber = 1,
        },
        balls = PP.newRack(mode.id, rackSeed),
        phase = phase,
        status = PP.statusForPhase(phase),
        message = ownerName .. " started a pool game.",
        shotNumber = 0,
        winner = nil,
        winReason = nil,
        modeId = mode.id,
        mode = mode.name,
        modeSelected = hasMode,
        modeState = PP.initialModeState(mode.id),
        ballInHand = false,
        ballInHandPlayer = nil,
        events = {},
    }
    PP.addEvent(state, state.message, "join")
    return state
end

function PP.findBall(state, id)
    if not state or not state.balls then
        return nil
    end
    for i = 1, #state.balls do
        if state.balls[i].id == id then
            return state.balls[i]
        end
    end
    return nil
end

function PP.isObjectBall(ball)
    return ball and type(ball.id) == "number"
end

function PP.lowestObjectBall(state)
    local lowest = nil
    if not state or not state.balls then
        return nil
    end
    for i = 1, #state.balls do
        local ball = state.balls[i]
        if PP.isObjectBall(ball) and not ball.pocketed and (not lowest or ball.id < lowest.id) then
            lowest = ball
        end
    end
    return lowest
end

function PP.findLowestBallInGroup(state, groupName)
    local lowest = nil
    if not state or not state.balls then
        return nil
    end
    for i = 1, #state.balls do
        local ball = state.balls[i]
        local matches = groupName == "solids" and PP.isSolidBall(ball.id) or groupName == "stripes" and PP.isStripeBall(ball.id)
        if matches and not ball.pocketed and (not lowest or ball.id < lowest.id) then
            lowest = ball
        end
    end
    return lowest
end

function PP.eightBallGroupCleared(state, groupName)
    return PP.findLowestBallInGroup(state, groupName) == nil
end

function PP.playerEightBallGroup(state, playerName)
    local modeState = state and state.modeState
    return modeState and modeState.groups and playerName and modeState.groups[playerName] or nil
end

function PP.oppositeEightBallGroup(groupName)
    if groupName == "solids" then
        return "stripes"
    end
    if groupName == "stripes" then
        return "solids"
    end
    return nil
end

function PP.onBallForState(state)
    local modeId = state and (state.modeId or PP.DEFAULT_MODE_ID) or PP.DEFAULT_MODE_ID
    if modeId == "eight_ball" then
        local groupName = PP.playerEightBallGroup(state, PP.currentPlayerName(state))
        if not groupName then
            return "open"
        end
        if PP.eightBallGroupCleared(state, groupName) then
            return PP.findBall(state, 8)
        end
        return PP.findLowestBallInGroup(state, groupName)
    end
    return PP.lowestObjectBall(state)
end

function PP.legalTargetBalls(state, playerName)
    local targets = {}
    if not state or not state.balls then
        return targets
    end
    for i = 1, #state.balls do
        local ball = state.balls[i]
        if PP.isObjectBall(ball) and not ball.pocketed and PP.isLegalFirstHit(state, ball.id, playerName) then
            targets[#targets + 1] = ball
        end
    end
    table.sort(targets, function(a, b)
        return (a.id or 99) < (b.id or 99)
    end)
    return targets
end

function PP.eightBallCallRequired(state)
    return state and (state.modeId or PP.DEFAULT_MODE_ID) == "eight_ball" and not PP.isBreakShot(state)
end

local function closestLegalTargetForAim(state, playerName, angle)
    local cue = PP.findBall(state, "cue")
    local targets = PP.legalTargetBalls(state, playerName)
    if not cue or #targets == 0 then
        return targets[1]
    end
    local dirX = math.cos(tonumber(angle) or 0)
    local dirY = math.sin(tonumber(angle) or 0)
    local best = nil
    local bestScore = nil
    for i = 1, #targets do
        local ball = targets[i]
        local dx = (ball.x or 0) - (cue.x or 0)
        local dy = (ball.y or 0) - (cue.y or 0)
        local forward = dx * dirX + dy * dirY
        local lateral = math.abs(dx * dirY - dy * dirX)
        local score = lateral + math.max(0, -forward) * 4 + math.max(0, forward) * 0.01
        if not bestScore or score < bestScore then
            best = ball
            bestScore = score
        end
    end
    return best
end

local function bestPocketForBallAndAim(ball, angle)
    if not ball then
        return nil
    end
    local pockets = PP.getPocketCenters()
    local dirX = math.cos(tonumber(angle) or 0)
    local dirY = math.sin(tonumber(angle) or 0)
    local best = nil
    local bestScore = nil
    for i = 1, #pockets do
        local pocket = pockets[i]
        local dx = (pocket.x or 0) - (ball.x or 0)
        local dy = (pocket.y or 0) - (ball.y or 0)
        local forward = dx * dirX + dy * dirY
        local lateral = math.abs(dx * dirY - dy * dirX)
        local dist = math.sqrt(dx * dx + dy * dy)
        local score = lateral + dist * 0.05 + math.max(0, -forward) * 1.8
        if not bestScore or score < bestScore then
            best = pocket
            bestScore = score
        end
    end
    return best
end

function PP.buildShotCallForAim(state, playerName, angle)
    if not PP.eightBallCallRequired(state) then
        return nil
    end
    local target = closestLegalTargetForAim(state, playerName or PP.currentPlayerName(state), angle)
    local pocket = bestPocketForBallAndAim(target, angle)
    if not target or not pocket then
        return nil
    end
    return {
        ballId = target.id,
        pocketId = pocket.id,
        safety = false,
        automatic = true,
    }
end

function PP.normalizeShotCall(state, playerName, shotCall)
    if not PP.eightBallCallRequired(state) then
        return nil, true, nil
    end
    if type(shotCall) ~= "table" then
        return nil, false, "Call a ball and pocket before shooting."
    end
    if shotCall.safety == true then
        return { safety = true }, true, nil
    end
    local ballId = tonumber(shotCall.ballId)
    local pocketId = shotCall.pocketId and tostring(shotCall.pocketId) or nil
    local ball = ballId and PP.findBall(state, ballId) or nil
    if not ball or ball.pocketed or not PP.isLegalFirstHit(state, ballId, playerName) then
        return nil, false, "Call a legal object ball."
    end
    if not PP.getPocketById(pocketId) then
        return nil, false, "Call a pocket."
    end
    return {
        ballId = ballId,
        pocketId = pocketId,
        safety = false,
        automatic = shotCall.automatic == true,
    }, true, nil
end

function PP.setShotCall(state, playerName, shotCall)
    if not state then
        return false, "No pool rack is active."
    end
    local normalized, ok, reason = PP.normalizeShotCall(state, playerName, shotCall)
    if not ok then
        return false, reason
    end
    state.shotCall = normalized
    return true, nil
end

function PP.clearShotCall(state)
    if state then
        state.shotCall = nil
    end
end

function PP.shotCallLabel(shotCall)
    if not shotCall then
        return "-"
    end
    if shotCall.safety then
        return "safety"
    end
    if shotCall.ballId and shotCall.pocketId then
        return tostring(shotCall.ballId) .. " to " .. PP.pocketLabel(shotCall.pocketId)
    end
    return "-"
end

function PP.isLegalFirstHit(state, ballId, playerName)
    if not state or not ballId or ballId == "cue" then
        return false
    end
    local modeId = state.modeId or PP.DEFAULT_MODE_ID
    if modeId == "eight_ball" then
        local groupName = PP.playerEightBallGroup(state, playerName or PP.currentPlayerName(state))
        if groupName == "solids" then
            if PP.eightBallGroupCleared(state, groupName) then
                return ballId == 8
            end
            return PP.isSolidBall(ballId)
        end
        if groupName == "stripes" then
            if PP.eightBallGroupCleared(state, groupName) then
                return ballId == 8
            end
            return PP.isStripeBall(ballId)
        end
        return PP.isSolidBall(ballId) or PP.isStripeBall(ballId)
    end
    local onBall = PP.onBallForState(state)
    return onBall and onBall.id == ballId
end

function PP.onBallLabel(state)
    if not state or not state.modeSelected then
        return "-"
    end
    if state.modeId == "eight_ball" then
        local groupName = PP.playerEightBallGroup(state, PP.currentPlayerName(state))
        if not groupName then
            return "open"
        end
        if PP.eightBallGroupCleared(state, groupName) then
            return "8"
        end
        return groupName
    end
    local ball = PP.onBallForState(state)
    if ball and ball.id then
        return tostring(ball.id)
    end
    return "-"
end

function PP.respotBall(state, id)
    local ball = PP.findBall(state, id)
    if not ball then
        return
    end
    ball.x = PP.RACK_SPOT_X + PP.ballPhysicsRadius() * 3.5
    ball.y = PP.TABLE_H / 2
    ball.vx = 0
    ball.vy = 0
    ball.pocketed = false
end

function PP.applyGameMode(state, modeId)
    local mode = PP.getGameMode(modeId)
    if not state or not mode then
        return
    end
    state.modeId = mode.id
    state.mode = mode.name
    state.modeSelected = true
    state.modeState = PP.initialModeState(mode.id)
    state.rackNumber = tonumber(state.rackNumber) or 1
    PP.applyRackBreaker(state, state.breakerName, PP.currentPlayerName(state))
    PP.refreshRack(state, mode.id, PP.createRackSeed(state.anchor, mode.id, state.rackNumber, state.breakerName))
    state.shotNumber = 0
    state.winner = nil
    state.winReason = nil
    state.ballInHand = false
    state.ballInHandPlayer = nil
    PP.clearShotCall(state)
    state.aim = nil
    PP.refreshStatePhase(state)
end

function PP.isCuePlacementClear(state, x, y)
    x = tonumber(x)
    y = tonumber(y)
    if not state or not x or not y then
        return false, "Invalid cue placement."
    end
    local physicsR = PP.ballPhysicsRadius()
    if PP.isInsidePlayableBoundary and not PP.isInsidePlayableBoundary(x, y) then
        return false, "Place the cue ball inside the rails."
    end
    local pockets = PP.getPocketCenters()
    for i = 1, #pockets do
        local dx = x - pockets[i].x
        local dy = y - pockets[i].y
        local blockedR = PP.getPocketCaptureRadius(pockets[i]) + physicsR * 0.5
        if dx * dx + dy * dy < blockedR * blockedR then
            return false, "Do not place the cue ball in a pocket."
        end
    end
    for i = 1, #state.balls do
        local ball = state.balls[i]
        if ball.id ~= "cue" and not ball.pocketed then
            local dx = x - ball.x
            local dy = y - ball.y
            if dx * dx + dy * dy < (physicsR * 2.08) * (physicsR * 2.08) then
                return false, "Cue ball is too close to another ball."
            end
        end
    end
    return true, nil
end

function PP.isMoving(state)
    if not state or not state.balls then
        return false
    end
    for i = 1, #state.balls do
        local ball = state.balls[i]
        if not ball.pocketed and ((ball.vx or 0) * (ball.vx or 0) + (ball.vy or 0) * (ball.vy or 0)) > 0.5 then
            return true
        end
    end
    return false
end

function PP.allObjectBallsPocketed(state)
    for i = 1, #state.balls do
        local ball = state.balls[i]
        if PP.isObjectBall(ball) and not ball.pocketed then
            return false
        end
    end
    return true
end

function PP.currentPlayerName(state)
    if not state or not state.players then
        return nil
    end
    return state.players[state.currentPlayer or 1]
end

function PP.isRackResetResolving(state, resolving)
    if resolving then
        return true
    end
    if not state then
        return false
    end
    local phase = PP.phaseForState(state)
    return state.shotInMotion
        or state.animation ~= nil
        or phase == PP.PHASE_SHOT_COMMITTED
        or phase == PP.PHASE_SIMULATING
        or phase == PP.PHASE_RESOLVING
end

function PP.canResetRack(state, playerName, options)
    options = options or {}
    if not state then
        return false, "There is no active pool rack to reset."
    end
    if PP.isRackResetResolving(state, options.resolving) and not options.force then
        return false, "Wait for the shot to finish before resetting."
    end
    if not options.force and not PP.findNameIndex(state.players or {}, playerName) then
        return false, "Join this pool game before resetting the rack."
    end
    return true, nil
end

function PP.advanceTurn(state)
    if not state.players or #state.players < 2 then
        state.currentPlayer = 1
        return
    end
    state.currentPlayer = (state.currentPlayer or 1) + 1
    if state.currentPlayer > #state.players then
        state.currentPlayer = 1
    end
    PP.clearShotCall(state)
end

function PP.setBallInHand(state, playerName)
    state.ballInHand = true
    state.ballInHandPlayer = playerName
    PP.clearShotCall(state)
end

function PP.clearBallInHand(state)
    state.ballInHand = false
    state.ballInHandPlayer = nil
end
