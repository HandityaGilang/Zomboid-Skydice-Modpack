local M = {}

local WIRE_MASKS = {
    [1] = { kind = "segments", width = 19, segments = {
        { 254.0000, 57.0000, 162.0000, 63.5000 },
        { 162.0000, 63.5000, 115.5000, 87.5000 },
        { 115.5000, 87.5000, 70.5000, 143.0000 },
        { 70.5000, 143.0000, 29.5000, 266.0000 },
        { 29.5000, 266.0000, 24.5000, 394.0000 },
    } },
    [2] = { kind = "segments", width = 19, segments = {
        { 255.5000, 81.0000, 151.5000, 104.5000 },
        { 151.5000, 104.5000, 109.5000, 142.0000 },
        { 109.5000, 142.0000, 40.0000, 283.0000 },
        { 40.0000, 283.0000, 24.5000, 394.0000 },
    } },
    [3] = { kind = "segments", width = 19, segments = {
        { 255.0000, 30.5000, 174.5000, 57.0000 },
        { 174.5000, 57.0000, 136.0000, 116.0000 },
        { 136.0000, 116.0000, 55.5000, 166.5000 },
        { 55.5000, 166.5000, 18.5000, 279.5000 },
        { 18.5000, 279.5000, 25.5000, 396.0000 },
    } },
    [4] = { kind = "segments", width = 19, segments = {
        { 253.5000, 68.5000, 145.5000, 64.0000 },
        { 145.5000, 64.0000, 81.0000, 85.5000 },
        { 81.0000, 85.5000, 46.5000, 156.5000 },
        { 46.5000, 156.5000, 60.0000, 248.5000 },
        { 60.0000, 248.5000, 30.0000, 346.5000 },
        { 30.0000, 346.5000, 24.5000, 394.0000 },
    } },
}

local CUT_MASKS = {
    [1] = { kind = "segments", width = 19, segments = {
        { 41.0000, 229.5000, 26.0000, 305.5000 },
        { 26.0000, 305.5000, 24.5000, 394.0000 },
    } },
    [2] = { kind = "segments", width = 19, segments = {
        { 70.5000, 217.5000, 40.0000, 283.0000 },
        { 40.0000, 283.0000, 24.5000, 394.0000 },
    } },
    [3] = { kind = "segments", width = 19, segments = {
        { 41.5000, 203.5000, 18.0000, 288.0000 },
        { 18.0000, 288.0000, 25.5000, 396.0000 },
    } },
    [4] = { kind = "segments", width = 19, segments = {
        { 52.5000, 188.5000, 58.5000, 260.5000 },
        { 58.5000, 260.5000, 28.0000, 353.0000 },
        { 28.0000, 353.0000, 24.5000, 394.0000 },
    } },
}

local TAIL_MASKS = {
    [1] = { kind = "segments", width = 19, segments = {
        { 254.0000, 57.0000, 162.0000, 63.5000 },
        { 162.0000, 63.5000, 115.5000, 87.5000 },
        { 115.5000, 87.5000, 69.0781, 148.8370 },
    } },
    [2] = { kind = "segments", width = 19, segments = {
        { 255.5000, 81.0000, 144.4810, 106.3820 },
        { 144.4810, 106.3820, 97.4113, 164.0660 },
    } },
    [3] = { kind = "segments", width = 19, segments = {
        { 255.0000, 30.5000, 174.5000, 57.0000 },
        { 174.5000, 57.0000, 138.2040, 113.3040 },
        { 138.2040, 113.3040, 100.3640, 138.2240 },
    } },
    [4] = { kind = "segments", width = 19, segments = {
        { 253.5000, 68.5003, 173.9210, 62.5439 },
        { 173.9210, 62.5439, 99.1633, 75.0031 },
        { 99.1633, 75.0031, 65.9378, 110.9970 },
    } },
}

local MERGED3_MASK = {
    kind = "segments",
    width = 36,
    segments = {
        { 23.5000, 394.5000, 39.5000, 212.0000 },
    },
}

local MERGED2_MASK = {
    kind = "segments",
    width = 36,
    segments = {
        { 25.0000, 395.5000, 45.5000, 211.5000 },
    },
}

local function pointInPolygon(px, py, poly)
    local inside = false
    local j = #poly
    for i = 1, #poly do
        local xi, yi = poly[i][1], poly[i][2]
        local xj, yj = poly[j][1], poly[j][2]
        local intersects = ((yi > py) ~= (yj > py)) and (px < (xj - xi) * (py - yi) / ((yj - yi) + 0.0) + xi)
        if intersects then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function pointNearSegment(px, py, x1, y1, x2, y2, radius)
    local dx = x2 - x1
    local dy = y2 - y1
    local len2 = (dx * dx) + (dy * dy)
    local t = 0
    if len2 > 0 then
        t = ((px - x1) * dx + (py - y1) * dy) / len2
    end
    if t < 0 then
        t = 0
    elseif t > 1 then
        t = 1
    end
    local cx = x1 + (t * dx)
    local cy = y1 + (t * dy)
    local ddx = px - cx
    local ddy = py - cy
    return (ddx * ddx + ddy * ddy) <= (radius * radius)
end

local function containsMask(mask, px, py)
    if mask.kind == "segments" then
        local radius = (mask.width or 0) * 0.5
        for _, seg in ipairs(mask.segments) do
            if pointNearSegment(px, py, seg[1], seg[2], seg[3], seg[4], radius) then
                return true
            end
        end
        return false
    end
    if mask.kind == "polygons" then
        for _, poly in ipairs(mask.polys) do
            if pointInPolygon(px, py, poly) then
                return true
            end
        end
        return false
    end
    return false
end

function M.contains(texId, px, py, isCut)
    local mask = (isCut and CUT_MASKS[texId]) or WIRE_MASKS[texId]
    return containsMask(mask, px, py)
end

function M.containsTail(texId, px, py)
    local mask = TAIL_MASKS[texId]
    return containsMask(mask, px, py)
end

function M.containsMerged3(px, py)
    return containsMask(MERGED3_MASK, px, py)
end

function M.containsMerged2(px, py)
    return containsMask(MERGED2_MASK, px, py)
end

return M
