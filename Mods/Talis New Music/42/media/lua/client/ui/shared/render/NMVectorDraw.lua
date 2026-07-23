NMVectorDraw = NMVectorDraw or {}
local PREPARED_SHAPE_CACHE = PREPARED_SHAPE_CACHE or setmetatable({}, { __mode = "k" })

local function triCross(ax, ay, bx, by, cx, cy)
    return ((bx - ax) * (cy - ay)) - ((by - ay) * (cx - ax))
end

local function toVertexList(points)
    local verts = {}
    for i = 1, #points, 2 do
        verts[#verts + 1] = { x = points[i], y = points[i + 1] }
    end
    if #verts >= 2 then
        local a = verts[1]
        local b = verts[#verts]
        if math.abs(a.x - b.x) < 0.0001 and math.abs(a.y - b.y) < 0.0001 then
            verts[#verts] = nil
        end
    end
    return verts
end

local function polygonArea(verts)
    local area = 0
    local n = #verts
    for i = 1, n do
        local a = verts[i]
        local b = verts[(i % n) + 1]
        area = area + (a.x * b.y) - (b.x * a.y)
    end
    return area * 0.5
end

local function pointInTriangle(px, py, ax, ay, bx, by, cx, cy)
    local b1 = triCross(px, py, ax, ay, bx, by) < 0
    local b2 = triCross(px, py, bx, by, cx, cy) < 0
    local b3 = triCross(px, py, cx, cy, ax, ay) < 0
    return (b1 == b2) and (b2 == b3)
end

local function isConvex(prev, curr, nextV, isCCW)
    local cross = triCross(prev.x, prev.y, curr.x, curr.y, nextV.x, nextV.y)
    if isCCW then
        return cross > 0.0001
    end
    return cross < -0.0001
end

local function anyPointInsideTriangle(indexes, verts, ia, ib, ic)
    local a = verts[ia]
    local b = verts[ib]
    local c = verts[ic]
    for i = 1, #indexes do
        local vi = indexes[i]
        if vi ~= ia and vi ~= ib and vi ~= ic then
            local p = verts[vi]
            if pointInTriangle(p.x, p.y, a.x, a.y, b.x, b.y, c.x, c.y) then
                return true
            end
        end
    end
    return false
end

local function triangulate(points)
    local verts = toVertexList(points)
    local n = #verts
    if n < 3 then return {}, verts end
    if n == 3 then return { { 1, 2, 3 } }, verts end
    local idx = {}
    for i = 1, n do idx[i] = i end
    local tris = {}
    local isCCW = polygonArea(verts) > 0
    local guard = n * n
    while #idx > 3 and guard > 0 do
        guard = guard - 1
        local earFound = false
        for i = 1, #idx do
            local ia = idx[((i - 2 + #idx) % #idx) + 1]
            local ib = idx[i]
            local ic = idx[(i % #idx) + 1]
            if isConvex(verts[ia], verts[ib], verts[ic], isCCW)
                and (not anyPointInsideTriangle(idx, verts, ia, ib, ic)) then
                tris[#tris + 1] = { ia, ib, ic }
                table.remove(idx, i)
                earFound = true
                break
            end
        end
        if not earFound then break end
    end
    if #idx == 3 then
        tris[#tris + 1] = { idx[1], idx[2], idx[3] }
    end
    return tris, verts
end

function NMVectorDraw.hexToColor(hex)
    local h = tostring(hex or ""):gsub("#", "")
    if #h ~= 6 then return { r = 1, g = 1, b = 1, a = 1 } end
    local r = tonumber(string.sub(h, 1, 2), 16) or 255
    local g = tonumber(string.sub(h, 3, 4), 16) or 255
    local b = tonumber(string.sub(h, 5, 6), 16) or 255
    return { r = r / 255, g = g / 255, b = b / 255, a = 1 }
end

function NMVectorDraw.prepareShape(points, viewBox, bounds)
    if not (points and #points >= 6) then return nil end
    local tris, verts = triangulate(points)
    if #tris <= 0 or #verts <= 0 then return nil end

    local vb = tonumber(viewBox) or 23
    local minX, minY = 0, 0
    local spanX, spanY = vb, vb
    if bounds then
        minX = tonumber(bounds.minX) or 0
        minY = tonumber(bounds.minY) or 0
        local maxX = tonumber(bounds.maxX) or vb
        local maxY = tonumber(bounds.maxY) or vb
        spanX = math.max(0.0001, maxX - minX)
        spanY = math.max(0.0001, maxY - minY)
    end

    local prepared = {}
    for i = 1, #tris do
        local t = tris[i]
        local a = verts[t[1]]
        local b = verts[t[2]]
        local c = verts[t[3]]
        prepared[i] = {
            (a.x - minX) / spanX, (a.y - minY) / spanY,
            (b.x - minX) / spanX, (b.y - minY) / spanY,
            (c.x - minX) / spanX, (c.y - minY) / spanY,
        }
    end
    return prepared
end

function NMVectorDraw.drawPreparedShape(ui, prepared, color, left, top, width, height)
    if not (ui and ui.drawPolygon and prepared and color) then return end
    local w = tonumber(width) or 0
    local h = tonumber(height) or w
    if w <= 0 or h <= 0 then return end
    local cr, cg, cb, ca = color.r, color.g, color.b, color.a or 1
    for i = 1, #prepared do
        local tri = prepared[i]
        local ax = left + (tri[1] * w)
        local ay = top + (tri[2] * h)
        local bx = left + (tri[3] * w)
        local by = top + (tri[4] * h)
        local cx = left + (tri[5] * w)
        local cy = top + (tri[6] * h)
        ui:drawPolygon(nil, ax, ay, bx, by, cx, cy, cx, cy, cr, cg, cb, ca)
    end
end

function NMVectorDraw.drawShape(ui, points, color, left, top, width, viewBox, bounds, height)
    if not (ui and ui.drawPolygon and points and #points >= 6 and color) then return end
    local prepared = PREPARED_SHAPE_CACHE[points]
    if prepared == nil then
        prepared = NMVectorDraw.prepareShape(points, viewBox, bounds) or false
        PREPARED_SHAPE_CACHE[points] = prepared
    end
    if prepared == false then
        return
    end
    NMVectorDraw.drawPreparedShape(ui, prepared, color, left, top, width, height)
end
