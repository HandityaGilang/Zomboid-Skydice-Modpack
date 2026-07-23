BasementBuilder = BasementBuilder or {}

require "BasementBuilder/BasementBuilder_Templates"

BasementBuilder.MOD_DATA_KEY = "BasementBuilderData"
BasementBuilder.MODULE = "BasementBuilder"
BasementBuilder.START_WIDTH = BasementBuilder.getStarterTemplate().width
BasementBuilder.START_HEIGHT = BasementBuilder.getStarterTemplate().height
BasementBuilder.START_LOG_COST = #BasementBuilder.getStarterTemplate().cells
BasementBuilder.START_NAIL_COST = BasementBuilder.START_LOG_COST * 2
BasementBuilder.EXPAND_LOG_COST = 1
BasementBuilder.EXPAND_NAIL_COST = 2
BasementBuilder.DEFAULT_FLOOR = BasementBuilder.getStarterTemplate().palette.floor
BasementBuilder.STAIR_S = { "carpentry_02_96", "carpentry_02_97", "carpentry_02_98" }
BasementBuilder.STAIR_W = { "carpentry_02_88", "carpentry_02_89", "carpentry_02_90" }
BasementBuilder.PILLAR_S = "carpentry_02_95"
BasementBuilder.PILLAR_W = "carpentry_02_94"
BasementBuilder.WALL_W = BasementBuilder.getStarterTemplate().palette.wallWest
BasementBuilder.WALL_N = BasementBuilder.getStarterTemplate().palette.wallNorth
BasementBuilder.ROOF_MARKER = "carpentry_02_58"
BasementBuilder.ENTRY_SPRITE = "carpentry_02_57"
BasementBuilder.EXIT_SPRITE = "fixtures_bathroom_02_36"
BasementBuilder.SUPPORT_RING_RADIUS = 0
BasementBuilder.CLEARANCE_RADIUS = 3

BasementBuilder.FAILURE_TEXT_KEYS = {
    ["No square"] = "Tooltip_BB_NoSquare",
    ["Surface only"] = "Tooltip_BB_SurfaceOnly",
    ["Basement exists"] = "Tooltip_BB_BasementExists",
    ["Out of bounds"] = "Tooltip_BB_OutOfBounds",
    ["Overlap"] = "Tooltip_BB_Overlap",
    ["Not in basement"] = "Tooltip_BB_NotInBasement",
    ["Wrong level"] = "Tooltip_BB_WrongLevel",
    ["Adjacent only"] = "Tooltip_BB_AdjacentOnly",
    ["Already dug"] = "Tooltip_BB_AlreadyDug",
}

function BasementBuilder.getFailureText(reason)
    local key = BasementBuilder.FAILURE_TEXT_KEYS[tostring(reason or "")]
    if key then
        return getText(key)
    end
    return tostring(reason or getText("Tooltip_BB_CantDigHere"))
end

function BasementBuilder.getSaveData()
    local data = ModData.getOrCreate(BasementBuilder.MOD_DATA_KEY)
    data.nextId = data.nextId or 1
    data.basements = data.basements or {}
    return data
end

function BasementBuilder.transmitSaveData()
    if isServer() then
        ModData.transmit(BasementBuilder.MOD_DATA_KEY)
    end
end

function BasementBuilder.key(x, y)
    return tostring(x) .. ":" .. tostring(y)
end

function BasementBuilder.parseKey(key)
    local x, y = string.match(key, "^(%-?%d+):(%-?%d+)$")
    return tonumber(x), tonumber(y)
end

function BasementBuilder.getBasement(id)
    local data = BasementBuilder.getSaveData()
    return data.basements[tostring(id)]
end

function BasementBuilder.getTemplateBounds(template, anchorX, anchorY)
    local minX = nil
    local maxX = nil
    local minY = nil
    local maxY = nil

    for _, cell in ipairs(template.cells) do
        local worldX = anchorX + cell.x
        local worldY = anchorY + cell.y
        minX = minX and math.min(minX, worldX) or worldX
        maxX = maxX and math.max(maxX, worldX) or worldX
        minY = minY and math.min(minY, worldY) or worldY
        maxY = maxY and math.max(maxY, worldY) or worldY
    end

    return minX, maxX, minY, maxY
end

function BasementBuilder.iterTemplateCells(template, anchorX, anchorY, callback)
    for _, cell in ipairs(template.cells) do
        callback(anchorX + cell.x, anchorY + cell.y, cell)
    end
end

function BasementBuilder.ensureBasementShape(basement)
    basement.cells = basement.cells or {}
    basement.walls = basement.walls or {}
    basement.origin = basement.origin or {}
    basement.stairs = basement.stairs or {}
    basement.palette = basement.palette or {}
    basement.binmapName = basement.binmapName or nil
    basement.version = basement.version or 1
    return basement
end

function BasementBuilder.getBasementTemplate(basement)
    if not basement then
        return BasementBuilder.getStarterTemplate()
    end
    return BasementBuilder.getTemplateById(basement.templateId) or BasementBuilder.getStarterTemplate()
end

function BasementBuilder.getBasementPalette(basement)
    local template = BasementBuilder.getBasementTemplate(basement)
    local palette = {
        floor = basement and basement.palette and basement.palette.floor or nil,
        wallWest = basement and basement.palette and basement.palette.wallWest or nil,
        wallNorth = basement and basement.palette and basement.palette.wallNorth or nil,
        corner = basement and basement.palette and basement.palette.corner or nil,
    }
    palette.floor = palette.floor or (template.palette and template.palette.floor) or BasementBuilder.DEFAULT_FLOOR
    palette.wallWest = palette.wallWest or (template.palette and template.palette.wallWest) or BasementBuilder.WALL_W
    palette.wallNorth = palette.wallNorth or (template.palette and template.palette.wallNorth) or BasementBuilder.WALL_N
    palette.corner = palette.corner or (template.palette and template.palette.corner) or "TileWalls_51"
    return palette
end

function BasementBuilder.resolvePaletteOverride(styleId, palette)
    local resolved = {}
    local style = BasementBuilder.getWallStylePreset and BasementBuilder.getWallStylePreset(styleId) or nil
    if style and style.palette then
        resolved.floor = style.palette.floor
        resolved.wallWest = style.palette.wallWest
        resolved.wallNorth = style.palette.wallNorth
        resolved.corner = style.palette.corner
        resolved.styleId = style.id
    end

    if palette then
        resolved.floor = palette.floor or resolved.floor
        resolved.wallWest = palette.wallWest or resolved.wallWest
        resolved.wallNorth = palette.wallNorth or resolved.wallNorth
        resolved.corner = palette.corner or resolved.corner
        resolved.styleId = palette.styleId or resolved.styleId
    end

    return resolved
end

function BasementBuilder.allocateBasementId()
    local data = BasementBuilder.getSaveData()
    local id = data.nextId
    data.nextId = id + 1
    return tostring(id)
end

function BasementBuilder.setCell(basement, x, y, value)
    basement.cells[BasementBuilder.key(x, y)] = value and true or nil
end

function BasementBuilder.hasCell(basement, x, y)
    return basement.cells[BasementBuilder.key(x, y)] == true
end

function BasementBuilder.setWallRecord(basement, x, y, dir, value)
    local key = BasementBuilder.key(x, y)
    basement.walls[key] = basement.walls[key] or {}
    basement.walls[key][dir] = value and true or nil
end

function BasementBuilder.getWallRecord(basement, x, y, dir)
    local key = BasementBuilder.key(x, y)
    return basement.walls[key] and basement.walls[key][dir] == true
end

function BasementBuilder.squareExists(x, y, z)
    return getWorld():isValidSquare(x, y, z)
end

function BasementBuilder.getOrCreateSquare(x, y, z)
    local cell = getCell()
    local square = cell:getOrCreateGridSquare(x, y, z)
    square:EnsureSurroundNotNull()
    return square
end

function BasementBuilder.isSquareChunkLoaded(square)
    return square and square.getChunk and square:getChunk() ~= nil
end

function BasementBuilder.itemHasTag(item, tag)
    if not item or not tag then
        return false
    end

    local ok, result = pcall(function()
        return item:hasTag(tag)
    end)
    if ok and result then
        return true
    end

    local okScript, scriptItem = pcall(function()
        return item:getScriptItem()
    end)
    if okScript and scriptItem and scriptItem.getTags then
        local okTags, tags = pcall(function()
            return scriptItem:getTags()
        end)
        if okTags and tags and tags.contains and tags:contains(tag) then
            return true
        end
    end

    return false
end

function BasementBuilder.isUsableDigTool(item)
    return item
        and not item:isBroken()
        and ItemTag
        and (
            BasementBuilder.itemHasTag(item, ItemTag.DIG_PLOW)
            or BasementBuilder.itemHasTag(item, ItemTag.TAKE_DIRT)
        )
end

function BasementBuilder.getDigTool(playerObj)
    if not playerObj then
        return nil
    end

    local items = playerObj:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if BasementBuilder.isUsableDigTool(item) then
            return item
        end
    end

    local allItems = playerObj:getInventory():getAllEvalRecurse(function(item)
        return BasementBuilder.isUsableDigTool(item)
    end)
    if allItems and allItems:size() > 0 then
        return allItems:get(0)
    end

    return nil
end

function BasementBuilder.removeUndergroundBlocks(square)
    if not square or square:getZ() >= 0 then
        return false
    end

    local removed = false
    while true do
        local before = square:getObjects():size()
        square:removeUnderground()
        if square:getObjects():size() == before then
            break
        end
        removed = true
    end

    return removed
end

function BasementBuilder.isManagedBasementObject(obj)
    if not obj then
        return false
    end

    local props = obj.getProperties and obj:getProperties() or nil
    if props and props:has(IsoFlagType.solidfloor) then
        return true
    end

    if obj.hasModData and obj:hasModData() then
        local tag = obj:getModData().BBTag
        if tag == "wall" or tag == "wall_corner" or tag == "stairs" or tag == "entry" or tag == "exit" or tag == "decor" then
            return true
        end
    end

    if instanceof(obj, "IsoThumpable") and obj.getName and obj:getName() == "Basement Stairs" then
        return true
    end

    return false
end

function BasementBuilder.clearBasementFill(square)
    if not square or square:getZ() >= 0 then
        return false
    end

    local removed = BasementBuilder.removeUndergroundBlocks(square)
    for i = square:getObjects():size() - 1, 0, -1 do
        local obj = square:getObjects():get(i)
        if obj and not BasementBuilder.isManagedBasementObject(obj) then
            if square.transmitRemoveItemFromSquare then
                square:transmitRemoveItemFromSquare(obj)
            end
            obj:removeFromWorld()
            obj:removeFromSquare()
            removed = true
        end
    end

    return removed
end

function BasementBuilder.clearSquare(square)
    if not square then return end
    for i = square:getObjects():size() - 1, 0, -1 do
        local obj = square:getObjects():get(i)
        if obj then
            obj:removeFromWorld()
            obj:removeFromSquare()
        end
    end
    square:getSpecialObjects():clear()
end

function BasementBuilder.clearNonFloorObjects(square)
    if not square then
        return
    end

    for i = square:getObjects():size() - 1, 0, -1 do
        local obj = square:getObjects():get(i)
        if obj then
            local props = obj:getProperties()
            local isFloor = props and props:has(IsoFlagType.solidfloor)
            if not isFloor then
                if square.transmitRemoveItemFromSquare then
                    square:transmitRemoveItemFromSquare(obj)
                end
                obj:removeFromWorld()
                obj:removeFromSquare()
            end
        end
    end
end

function BasementBuilder.removeSquareFloor(square)
    if not square then
        return false
    end

    local removed = false
    for i = square:getObjects():size() - 1, 0, -1 do
        local obj = square:getObjects():get(i)
        if obj then
            local props = obj:getProperties()
            if props and props:has(IsoFlagType.solidfloor) then
                if square.transmitRemoveItemFromSquare then
                    square:transmitRemoveItemFromSquare(obj)
                end
                obj:removeFromWorld()
                obj:removeFromSquare()
                removed = true
            end
        end
    end

    return removed
end

function BasementBuilder.getWallObjectIndex(square)
    if not square then
        return -1
    end

    for i = square:getObjects():size(), 1, -1 do
        local obj = square:getObjects():get(i - 1)
        local props = obj and obj:getProperties() or nil
        if props and props:has(IsoFlagType.solidfloor) then
            return i
        end
    end

    return -1
end

function BasementBuilder.ensureFloor(square, sprite)
    if not square then return end
    if not BasementBuilder.isSquareChunkLoaded(square) then
        return
    end
    BasementBuilder.removeUndergroundBlocks(square)
    local floor = square:getFloor()
    if floor and floor:getSprite() and floor:getSprite():getName() == sprite then
        return
    end
    square:addFloor(sprite)
end

function BasementBuilder.ensureSurfaceEntryFloor(basement)
    if not basement or not basement.origin then return end

    local template = BasementBuilder.getBasementTemplate(basement)
    local floorSprite = BasementBuilder.ENTRY_SPRITE
    if template.markers and template.markers.surfaceFloor then
        floorSprite = template.markers.surfaceFloor
    end

    local entryX = basement.stairs and basement.stairs.x or basement.origin.x
    local entryY = basement.stairs and basement.stairs.y or basement.origin.y
    local topSquare = BasementBuilder.getOrCreateSquare(entryX, entryY, 0)
    if not (basement.stairs and basement.stairs.surfaceHole) then
        BasementBuilder.ensureFloor(topSquare, floorSprite)
    end
    topSquare:RecalcAllWithNeighbours(true)
end

function BasementBuilder.clearSurfaceStairwell(basement)
    if not basement or not basement.stairs then
        return
    end

    local north = basement.stairs.north ~= false
    for level = 0, 2 do
        local x = basement.stairs.x
        local y = basement.stairs.y
        if north then
            y = y - level
        else
            x = x - level
        end

        if BasementBuilder.squareExists(x, y, 0) then
            local square = BasementBuilder.getOrCreateSquare(x, y, 0)
            BasementBuilder.clearNonFloorObjects(square)
            BasementBuilder.removeSquareFloor(square)
            square:RecalcAllWithNeighbours(true)
        end
    end
end

function BasementBuilder.getBasementBoundsFromCells(basement)
    local minX = nil
    local maxX = nil
    local minY = nil
    local maxY = nil

    for key, _ in pairs(basement.cells or {}) do
        local x, y = BasementBuilder.parseKey(key)
        if x and y then
            minX = minX and math.min(minX, x) or x
            maxX = maxX and math.max(maxX, x) or x
            minY = minY and math.min(minY, y) or y
            maxY = maxY and math.max(maxY, y) or y
        end
    end

    return minX, maxX, minY, maxY
end

function BasementBuilder.iterBasementArea(basement, padding, callback)
    if not basement or not callback then
        return
    end

    local radius = math.max(0, padding or 0)
    local visited = {}

    for key, _ in pairs(basement.cells or {}) do
        local baseX, baseY = BasementBuilder.parseKey(key)
        if baseX and baseY then
            for offsetX = -radius, radius do
                for offsetY = -radius, radius do
                    local x = baseX + offsetX
                    local y = baseY + offsetY
                    local visitKey = BasementBuilder.key(x, y)
                    if not visited[visitKey] then
                        visited[visitKey] = true
                        callback(x, y, BasementBuilder.hasCell(basement, x, y))
                    end
                end
            end
        end
    end
end

function BasementBuilder.clearBasementPerimeter(basement, padding)
    if not basement then
        return
    end

    BasementBuilder.iterBasementArea(basement, padding or BasementBuilder.CLEARANCE_RADIUS, function(x, y, isCell)
        if BasementBuilder.squareExists(x, y, basement.z) then
            local square = BasementBuilder.getOrCreateSquare(x, y, basement.z)
            local changed = false
            if isCell then
                changed = BasementBuilder.removeUndergroundBlocks(square)
            else
                changed = BasementBuilder.clearBasementFill(square)
            end
            if changed then
                square:RecalcAllWithNeighbours(true)
            end
        end
    end)
end

function BasementBuilder.isWithinBasementPerimeter(basement, x, y, padding)
    if not basement then
        return false
    end

    local minX, maxX, minY, maxY = BasementBuilder.getBasementBoundsFromCells(basement)
    if not minX then
        return false
    end

    local radius = math.max(0, padding or BasementBuilder.CLEARANCE_RADIUS or 0)
    return x >= (minX - radius)
        and x <= (maxX + radius)
        and y >= (minY - radius)
        and y <= (maxY + radius)
end

function BasementBuilder.refreshLoadedPerimeter(basement, padding)
    if not basement then
        return
    end

    BasementBuilder.iterBasementArea(basement, padding or BasementBuilder.CLEARANCE_RADIUS, function(x, y, isCell)
        local square = getCell():getGridSquare(x, y, basement.z)
        if BasementBuilder.isSquareChunkLoaded(square) then
            local changed = false
            if isCell then
                changed = BasementBuilder.removeUndergroundBlocks(square)
            else
                changed = BasementBuilder.clearBasementFill(square)
            end
            if changed then
                square:RecalcAllWithNeighbours(true)
            end
        end
    end)
end

function BasementBuilder.clearExteriorCornerSquares(basement)
    if not basement then
        return
    end

    local minX, maxX, minY, maxY = BasementBuilder.getBasementBoundsFromCells(basement)
    if not minX then
        return
    end

    local corners = {
        { x = minX - 1, y = minY - 1 },
        { x = minX - 1, y = maxY + 1 },
        { x = maxX + 1, y = minY - 1 },
        { x = maxX + 1, y = maxY + 1 },
    }

    for _, corner in ipairs(corners) do
        local loaded = false
        local changed = false
        if BasementBuilder.squareExists(corner.x, corner.y, basement.z) then
            local square = BasementBuilder.getOrCreateSquare(corner.x, corner.y, basement.z)
            loaded = BasementBuilder.isSquareChunkLoaded(square)
            if loaded then
                changed = BasementBuilder.clearBasementFill(square)
                if changed then
                    square:RecalcAllWithNeighbours(true)
                end
            end
        end
        print("[BasementBuilder][CornerFix] source=" .. tostring(isClient() and "client" or "server") .. " basement=" .. tostring(basement.id) .. " corner=" .. tostring(corner.x) .. "," .. tostring(corner.y) .. "," .. tostring(basement.z) .. " loaded=" .. tostring(loaded) .. " changed=" .. tostring(changed))
    end
end

function BasementBuilder.recalcLoadedPerimeter(basement, padding)
    if not basement then
        return
    end

    BasementBuilder.iterBasementArea(basement, padding or BasementBuilder.CLEARANCE_RADIUS, function(x, y)
        local square = getCell():getGridSquare(x, y, basement.z)
        if BasementBuilder.isSquareChunkLoaded(square) then
            square:RecalcAllWithNeighbours(true)
        end
    end)
end

function BasementBuilder.isWithinBasementSupportRing(basement, x, y)
    if not basement then
        return false
    end

    local minX, maxX, minY, maxY = BasementBuilder.getBasementBoundsFromCells(basement)
    if not minX then
        return false
    end

    local radius = BasementBuilder.SUPPORT_RING_RADIUS or 0
    return x >= (minX - radius) and x <= (maxX + radius) and y >= (minY - radius) and y <= (maxY + radius)
end

function BasementBuilder.refreshChunkExtents()
    local cell = getCell()
    if not cell or not cell.getChunkMap then
        return
    end

    for playerIndex = 0, 3 do
        local ok, chunkMap = pcall(function()
            return cell:getChunkMap(playerIndex)
        end)
        if ok and chunkMap and chunkMap.calculateZExtentsForChunkMap then
            pcall(function()
                chunkMap:calculateZExtentsForChunkMap()
            end)
        end
    end
end

function BasementBuilder.ensureBasementLight(basement)
    return
end

function BasementBuilder.postProcessBasement(basement)
    if not basement then return end

    local minX, maxX, minY, maxY = BasementBuilder.getBasementBoundsFromCells(basement)
    if not minX then return end

    local palette = BasementBuilder.getBasementPalette(basement)
    local z = basement.z

    BasementBuilder.clearBasementPerimeter(basement, BasementBuilder.CLEARANCE_RADIUS)

    for x = minX, maxX do
        for y = minY, maxY do
            local square = getCell():getGridSquare(x, y, z)
            if square then
                local changed = BasementBuilder.removeUndergroundBlocks(square)
                if BasementBuilder.hasCell(basement, x, y) then
                    BasementBuilder.ensureFloor(square, palette.floor)
                    changed = true
                end
                if changed then
                    square:RecalcAllWithNeighbours(true)
                end
            end
        end
    end

    BasementBuilder.ensureSurfaceEntryFloor(basement)

    local landing = basement.stairs and basement.stairs.landing or nil
    if landing then
        local landingSquare = BasementBuilder.getOrCreateSquare(landing.x, landing.y, z)
        BasementBuilder.removeUndergroundBlocks(landingSquare)
        BasementBuilder.ensureFloor(landingSquare, palette.floor)
        landingSquare:RecalcAllWithNeighbours(true)
    end

    BasementBuilder.refreshChunkExtents()
    BasementBuilder.ensureBasementLight(basement)
end

function BasementBuilder.findTaggedObject(square, tag)
    if not square then return nil end
    for i = 0, square:getObjects():size() - 1 do
        local obj = square:getObjects():get(i)
        if obj and obj:hasModData() and obj:getModData().BBTag == tag then
            return obj
        end
    end
    return nil
end

function BasementBuilder.createMarker(square, sprite, tag, basementId)
    if not BasementBuilder.isSquareChunkLoaded(square) then
        return nil
    end
    local obj = IsoObject.new(getCell(), square, sprite)
    obj:getModData().BBTag = tag
    obj:getModData().BBBasementId = basementId
    square:AddSpecialObject(obj)
    obj:transmitCompleteItemToClients()
    obj:transmitModData()
    square:RecalcAllWithNeighbours(true)
    return obj
end

function BasementBuilder.removeTaggedObjects(square, tags)
    if not square then return end
    local lookup = {}
    for _, tag in ipairs(tags) do
        lookup[tag] = true
    end
    for i = square:getObjects():size() - 1, 0, -1 do
        local obj = square:getObjects():get(i)
        if obj and obj:hasModData() then
            local tag = obj:getModData().BBTag
            if lookup[tag] then
                obj:removeFromWorld()
                obj:removeFromSquare()
            end
        end
    end
end

function BasementBuilder.removeManagedSurfaceStairs(basement)
    if not basement or not basement.stairs then return end
    local north = basement.stairs.north ~= false
    for level = 0, 2 do
        local x = basement.stairs.x
        local y = basement.stairs.y
        if north then
            y = y - level
        else
            x = x - level
        end
        local square = getCell():getGridSquare(x, y, 0)
        if BasementBuilder.isSquareChunkLoaded(square) then
            for i = square:getObjects():size() - 1, 0, -1 do
                local obj = square:getObjects():get(i)
                if obj and instanceof(obj, "IsoThumpable") and obj:getName() == "Basement Stairs" then
                    obj:removeFromWorld()
                    obj:removeFromSquare()
                end
            end
            square:RecalcAllWithNeighbours(true)
        end
    end
end

function BasementBuilder.removeManagedBasementStairs(basement)
    if not basement or not basement.stairs then
        return
    end

    local north = basement.stairs.north ~= false
    for level = 0, 2 do
        local x = basement.stairs.x
        local y = basement.stairs.y
        if north then
            y = y - level
        else
            x = x - level
        end

        local square = getCell():getGridSquare(x, y, basement.z)
        if BasementBuilder.isSquareChunkLoaded(square) then
            for i = square:getObjects():size() - 1, 0, -1 do
                local obj = square:getObjects():get(i)
                if obj and instanceof(obj, "IsoThumpable") and obj:getName() == "Basement Stairs" then
                    obj:removeFromWorld()
                    obj:removeFromSquare()
                end
            end
            square:RecalcAllWithNeighbours(true)
        end
    end
end

function BasementBuilder.ensureBasementAccessStairs(basement)
    if not basement or not basement.stairs then
        return
    end

    BasementBuilder.removeManagedSurfaceStairs(basement)
    BasementBuilder.removeManagedBasementStairs(basement)
    BasementBuilder.clearSurfaceStairwell(basement)

    local baseSquare = BasementBuilder.getOrCreateSquare(basement.stairs.x, basement.stairs.y, basement.z)
    if not BasementBuilder.isSquareChunkLoaded(baseSquare) then
        return
    end
    BasementBuilder.removeUndergroundBlocks(baseSquare)
    BasementBuilder.addStairsAt(baseSquare, basement.stairs.north ~= false)
end

function BasementBuilder.ensureEntryMarkers(basement)
    local template = BasementBuilder.getBasementTemplate(basement)
    BasementBuilder.ensureBasementAccessStairs(basement)
    BasementBuilder.ensureSurfaceEntryFloor(basement)

    local entryX = basement.stairs and basement.stairs.x or basement.origin.x
    local entryY = basement.stairs and basement.stairs.y or basement.origin.y
    local topSquare = BasementBuilder.getOrCreateSquare(entryX, entryY, 0)
    BasementBuilder.removeTaggedObjects(topSquare, { "entry" })
    local entrySprite = template.markers and template.markers.surfaceEntry or nil
    if entrySprite then
        BasementBuilder.createMarker(topSquare, entrySprite, "entry", basement.id)
    end

    local landing = basement.stairs and basement.stairs.landing or nil
    local exitX = landing and landing.x or basement.origin.x
    local exitY = landing and landing.y or basement.origin.y
    local exitSquare = BasementBuilder.getOrCreateSquare(exitX, exitY, basement.z)
    BasementBuilder.removeTaggedObjects(exitSquare, { "exit" })
    BasementBuilder.ensureFloor(exitSquare, BasementBuilder.getBasementPalette(basement).floor)
    BasementBuilder.createMarker(exitSquare, BasementBuilder.EXIT_SPRITE, "exit", basement.id)
end

function BasementBuilder.applyDecorList(basement, decorList)
    if not decorList then return end
    for _, decor in ipairs(decorList) do
        local square = BasementBuilder.getOrCreateSquare(basement.origin.x + decor.x, basement.origin.y + decor.y, basement.z)
        if decor.tag then
            BasementBuilder.removeTaggedObjects(square, { decor.tag })
        end
        BasementBuilder.createMarker(square, decor.sprite, decor.tag or "decor", basement.id)
    end
end

function BasementBuilder.createWall(square, north, basement)
    if not BasementBuilder.isSquareChunkLoaded(square) then
        return nil
    end
    local palette = BasementBuilder.getBasementPalette(basement)
    local sprite = north and palette.wallNorth or palette.wallWest
    local wall = IsoThumpable.new(getCell(), square, sprite, north, {})
    wall:getModData().BBTag = "wall"
    wall:getModData().BBDirection = north and "N" or "W"
    wall:getModData().BBBasementId = basement and basement.id or nil
    wall:setCanPassThrough(false)
    wall:setCanBarricade(false)
    wall:setIsDoor(false)
    wall:setIsDoorFrame(false)
    wall:setIsDismantable(false)
    wall:setCanBePlastered(false)
    wall:setIsThumpable(true)
    wall:setBlockAllTheSquare(false)
    wall:setCrossSpeed(1.0)
    wall:setName("Basement Concrete Wall")
    wall:setMaxHealth(1200)
    wall:setHealth(1200)
    wall:setBreakSound("BreakObject")
    square:AddSpecialObject(wall, BasementBuilder.getWallObjectIndex(square))
    if isServer() then
        wall:transmitCompleteItemToClients()
        wall:transmitModData()
    end
    return wall
end

function BasementBuilder.createCorner(square, basement)
    if not BasementBuilder.isSquareChunkLoaded(square) then
        return nil
    end
    local palette = BasementBuilder.getBasementPalette(basement)
    local corner = IsoThumpable.new(getCell(), square, palette.corner, false, {})
    corner:getModData().BBTag = "wall_corner"
    corner:getModData().BBBasementId = basement and basement.id or nil
    corner:setCorner(true)
    corner:setCanPassThrough(false)
    corner:setCanBarricade(false)
    corner:setIsDoor(false)
    corner:setIsDoorFrame(false)
    corner:setIsDismantable(false)
    corner:setCanBePlastered(false)
    corner:setIsThumpable(true)
    corner:setBlockAllTheSquare(false)
    corner:setCrossSpeed(1.0)
    corner:setName("Basement Wall Corner")
    corner:setMaxHealth(1200)
    corner:setHealth(1200)
    corner:setBreakSound("BreakObject")
    square:AddSpecialObject(corner, BasementBuilder.getWallObjectIndex(square))
    if isServer() then
        corner:transmitCompleteItemToClients()
        corner:transmitModData()
    end
    return corner
end

function BasementBuilder.removeWall(square, north)
    if not square then return end
    for i = square:getObjects():size() - 1, 0, -1 do
        local obj = square:getObjects():get(i)
        if obj and obj:hasModData() and obj:getModData().BBTag == "wall" and obj:getSprite() then
            local dir = obj:getModData().BBDirection
            local matchesDir = (north and dir == "N") or ((not north) and dir == "W")
            if matchesDir then
                obj:removeFromWorld()
                obj:removeFromSquare()
            end
        end
    end
end

function BasementBuilder.removeCorner(square)
    if not square then
        return false
    end
    local removed = false
    for i = square:getObjects():size() - 1, 0, -1 do
        local obj = square:getObjects():get(i)
        if obj and obj:hasModData() and obj:getModData().BBTag == "wall_corner" then
            obj:removeFromWorld()
            obj:removeFromSquare()
            removed = true
        end
    end
    return removed
end

function BasementBuilder.refreshCornerAt(basement, x, y)
    local square = BasementBuilder.getOrCreateSquare(x, y, basement.z)
    if not BasementBuilder.isSquareChunkLoaded(square) then
        return
    end

    if BasementBuilder.removeCorner(square) then
        square:RecalcAllWithNeighbours(true)
    end
end

function BasementBuilder.checkAndCreateCornerForWall(basement, x, y, north)
    return
end

function BasementBuilder.refreshTile(basement, x, y)
    if not BasementBuilder.hasCell(basement, x, y) then
        return
    end

    local z = basement.z
    local square = BasementBuilder.getOrCreateSquare(x, y, z)
    if not BasementBuilder.isSquareChunkLoaded(square) then
        return
    end
    local palette = BasementBuilder.getBasementPalette(basement)
    BasementBuilder.ensureFloor(square, palette.floor)

    local northOpen = BasementBuilder.hasCell(basement, x, y - 1)
    local westOpen = BasementBuilder.hasCell(basement, x - 1, y)
    local southOpen = BasementBuilder.hasCell(basement, x, y + 1)
    local eastOpen = BasementBuilder.hasCell(basement, x + 1, y)

    BasementBuilder.removeWall(square, true)
    BasementBuilder.removeWall(square, false)

    if not northOpen then
        BasementBuilder.createWall(square, true, basement)
        BasementBuilder.setWallRecord(basement, x, y, "N", true)
        BasementBuilder.checkAndCreateCornerForWall(basement, x, y, true)
    else
        BasementBuilder.setWallRecord(basement, x, y, "N", false)
    end

    if not westOpen then
        BasementBuilder.createWall(square, false, basement)
        BasementBuilder.setWallRecord(basement, x, y, "W", true)
        BasementBuilder.checkAndCreateCornerForWall(basement, x, y, false)
    else
        BasementBuilder.setWallRecord(basement, x, y, "W", false)
    end

    local eastSq = BasementBuilder.getOrCreateSquare(x + 1, y, z)
    if not BasementBuilder.isSquareChunkLoaded(eastSq) then
        return
    end
    if not eastOpen then
        BasementBuilder.clearBasementFill(eastSq)
    end
    BasementBuilder.removeWall(eastSq, false)
    if not eastOpen then
        BasementBuilder.createWall(eastSq, false, basement)
        BasementBuilder.setWallRecord(basement, x + 1, y, "W", true)
        BasementBuilder.checkAndCreateCornerForWall(basement, x + 1, y, false)
    else
        BasementBuilder.setWallRecord(basement, x + 1, y, "W", false)
    end

    local southSq = BasementBuilder.getOrCreateSquare(x, y + 1, z)
    if not BasementBuilder.isSquareChunkLoaded(southSq) then
        return
    end
    if not southOpen then
        BasementBuilder.clearBasementFill(southSq)
    end
    BasementBuilder.removeWall(southSq, true)
    if not southOpen then
        BasementBuilder.createWall(southSq, true, basement)
        BasementBuilder.setWallRecord(basement, x, y + 1, "N", true)
        BasementBuilder.checkAndCreateCornerForWall(basement, x, y + 1, true)
    else
        BasementBuilder.setWallRecord(basement, x, y + 1, "N", false)
    end

    local southEastSq = BasementBuilder.getOrCreateSquare(x + 1, y + 1, z)
    if BasementBuilder.isSquareChunkLoaded(southEastSq) and (not eastOpen or not southOpen or not BasementBuilder.hasCell(basement, x + 1, y + 1)) then
        BasementBuilder.clearBasementFill(southEastSq)
        southEastSq:RecalcAllWithNeighbours(true)
    end

    square:RecalcAllWithNeighbours(true)
    eastSq:RecalcAllWithNeighbours(true)
    southSq:RecalcAllWithNeighbours(true)

    BasementBuilder.refreshCornerAt(basement, x, y)
    BasementBuilder.refreshCornerAt(basement, x + 1, y)
    BasementBuilder.refreshCornerAt(basement, x, y + 1)
    BasementBuilder.refreshCornerAt(basement, x + 1, y + 1)
end

function BasementBuilder.refreshNeighbors(basement, x, y)
    BasementBuilder.refreshTile(basement, x, y)
    if BasementBuilder.hasCell(basement, x, y - 1) then BasementBuilder.refreshTile(basement, x, y - 1) end
    if BasementBuilder.hasCell(basement, x - 1, y) then BasementBuilder.refreshTile(basement, x - 1, y) end
    if BasementBuilder.hasCell(basement, x + 1, y) then BasementBuilder.refreshTile(basement, x + 1, y) end
    if BasementBuilder.hasCell(basement, x, y + 1) then BasementBuilder.refreshTile(basement, x, y + 1) end
end

function BasementBuilder.refreshLoadedBasement(basement)
    if not basement then
        return
    end

    BasementBuilder.ensureBasementShape(basement)
    BasementBuilder.clearExteriorCornerSquares(basement)
    BasementBuilder.refreshLoadedPerimeter(basement, BasementBuilder.CLEARANCE_RADIUS)

    for key, _ in pairs(basement.cells or {}) do
        local x, y = BasementBuilder.parseKey(key)
        if x and y then
            local square = getCell():getGridSquare(x, y, basement.z)
            if BasementBuilder.isSquareChunkLoaded(square) then
                BasementBuilder.refreshTile(basement, x, y)
            end
        end
    end

    local landing = basement.stairs and basement.stairs.landing or nil
    if landing then
        local landingSquare = getCell():getGridSquare(landing.x, landing.y, basement.z)
        if BasementBuilder.isSquareChunkLoaded(landingSquare) then
            BasementBuilder.ensureFloor(landingSquare, BasementBuilder.getBasementPalette(basement).floor)
            landingSquare:RecalcAllWithNeighbours(true)
        end
    end
end

function BasementBuilder.refreshLoadedBasements()
    local data = BasementBuilder.getSaveData()
    for _, basement in pairs(data.basements) do
        BasementBuilder.refreshLoadedBasement(basement)
    end
    BasementBuilder.refreshChunkExtents()
end

function BasementBuilder.addStairsAt(topSquare, north)
    if not BasementBuilder.isSquareChunkLoaded(topSquare) then
        return false
    end
    local stairs = north and BasementBuilder.STAIR_S or BasementBuilder.STAIR_W
    local pillar = north and BasementBuilder.PILLAR_S or BasementBuilder.PILLAR_W
    for level = 0, 2 do
        local x = topSquare:getX()
        local y = topSquare:getY()
        if north then
            y = y - level
        else
            x = x - level
        end
        local sq = BasementBuilder.getOrCreateSquare(x, y, topSquare:getZ())
        if not BasementBuilder.isSquareChunkLoaded(sq) then
            return false
        end
        local thumpable = sq:AddStairs(north, level, stairs[level + 1], pillar, {})
        if not thumpable then
            return false
        end
        thumpable:setCanBarricade(false)
        thumpable:setIsDismantable(true)
        thumpable:setIsStairs(true)
        thumpable:setName("Basement Stairs")
        thumpable:setMaxHealth(300)
        thumpable:setHealth(300)
        thumpable:getModData().BBTag = "stairs"
        if isServer() then
            thumpable:transmitCompleteItemToClients()
            thumpable:transmitModData()
        end
        sq:RecalcAllWithNeighbours(true)
    end
    return true
end

function BasementBuilder.findBasementBySurfaceSquare(square)
    if not square then return nil end
    local data = BasementBuilder.getSaveData()
    local sx = square:getX()
    local sy = square:getY()
    for _, basement in pairs(data.basements) do
        BasementBuilder.ensureBasementShape(basement)
        local entryX = basement.stairs and basement.stairs.x or (basement.origin and basement.origin.x)
        local entryY = basement.stairs and basement.stairs.y or (basement.origin and basement.origin.y)
        if entryX == sx and entryY == sy then
            return basement
        end
    end
    return nil
end

function BasementBuilder.findBasementByCell(x, y, z)
    if z >= 0 then return nil end
    local data = BasementBuilder.getSaveData()
    for _, basement in pairs(data.basements) do
        BasementBuilder.ensureBasementShape(basement)
        if basement.z == z and BasementBuilder.hasCell(basement, x, y) then
            return basement
        end
    end
    return nil
end

function BasementBuilder.getBasementBySquare(square)
    if not square then
        return nil
    end
    return BasementBuilder.findBasementByCell(square:getX(), square:getY(), square:getZ())
end

function BasementBuilder.isBasementSquare(square)
    return BasementBuilder.getBasementBySquare(square) ~= nil
end

function BasementBuilder.isPlayerInBasement(playerObj)
    local square = playerObj and playerObj:getCurrentSquare() or nil
    return BasementBuilder.isBasementSquare(square)
end

function BasementBuilder.isSquareTreatedAsInterior(square)
    if not square then
        return false
    end
    if BasementBuilder.isBasementSquare(square) then
        return true
    end
    return not square:isOutside()
end

function BasementBuilder.findBasementByDugCell(x, y, z)
    if z >= 0 then return nil end
    local data = BasementBuilder.getSaveData()
    for _, basement in pairs(data.basements) do
        BasementBuilder.ensureBasementShape(basement)
        if basement.z == z and BasementBuilder.hasCell(basement, x, y) then
            return basement
        end
    end
    return nil
end

function BasementBuilder.canStartBasement(square)
    if square and (not square.getX or not square.getY or not square.getZ) and square.getSquare then
        square = square:getSquare()
    end

    if not square then
        return false, "No square"
    end
    if not square.getX or not square.getY or not square.getZ then
        return false, "No square"
    end
    if square:getZ() ~= 0 then
        return false, "Surface only"
    end
    if BasementBuilder.findBasementBySurfaceSquare(square) then
        return false, "Basement exists"
    end
    local template = BasementBuilder.getStarterTemplate()
    BasementBuilder.iterTemplateCells(template, square:getX(), square:getY(), function(bx, by)
        if not BasementBuilder.squareExists(bx, by, -1) then
            error("Out of bounds")
        end
        if BasementBuilder.findBasementByDugCell(bx, by, -1) then
            error("Overlap")
        end
    end)
    return true
end

function BasementBuilder._safeCanStartBasement(square)
    local ok, valid, reason = pcall(BasementBuilder.canStartBasement, square)
    if ok then
        return valid, reason
    end
    return false, valid
end

function BasementBuilder.createStarterDefinition(square, styleId, paletteOverride)
    local template = BasementBuilder.getStarterTemplate()
    local paletteOverrideResolved = BasementBuilder.resolvePaletteOverride(styleId, paletteOverride)
    local id = BasementBuilder.allocateBasementId()
    local basement = BasementBuilder.ensureBasementShape({
        id = id,
        z = -1,
        origin = { x = square:getX(), y = square:getY(), z = square:getZ() },
        templateId = template.id,
        stairs = {
            x = square:getX() + template.stairs.x,
            y = square:getY() + template.stairs.y,
            north = template.stairs.north,
            surfaceHole = true,
            landing = template.stairs.landing and {
                x = square:getX() + template.stairs.landing.x,
                y = square:getY() + template.stairs.landing.y,
            } or nil,
        },
        palette = {
            floor = paletteOverrideResolved.floor or template.palette.floor,
            wallWest = paletteOverrideResolved.wallWest or template.palette.wallWest,
            wallNorth = paletteOverrideResolved.wallNorth or template.palette.wallNorth,
            corner = paletteOverrideResolved.corner or template.palette.corner,
            styleId = paletteOverrideResolved.styleId or styleId,
        },
        binmapName = template.binmapName,
    })

    BasementBuilder.iterTemplateCells(template, square:getX(), square:getY(), function(x, y)
        BasementBuilder.setCell(basement, x, y, true)
    end)

    local data = BasementBuilder.getSaveData()
    data.basements[id] = basement
    return basement
end

function BasementBuilder.buildStarterRoom(basement)
    local template = BasementBuilder.getBasementTemplate(basement)
    BasementBuilder.postProcessBasement(basement)
    for key, _ in pairs(basement.cells) do
        local x, y = BasementBuilder.parseKey(key)
        BasementBuilder.refreshTile(basement, x, y)
    end

    BasementBuilder.applyDecorList(basement, template.decor and template.decor.basement)
    BasementBuilder.ensureEntryMarkers(basement)
    BasementBuilder.clearExteriorCornerSquares(basement)
    BasementBuilder.recalcLoadedPerimeter(basement, BasementBuilder.CLEARANCE_RADIUS)
    BasementBuilder.refreshChunkExtents()
end

function BasementBuilder.startBasement(square, styleId, paletteOverride)
    local valid = BasementBuilder._safeCanStartBasement(square)
    if not valid then
        return nil
    end
    local basement = BasementBuilder.createStarterDefinition(square, styleId, paletteOverride)
    BasementBuilder.buildStarterRoom(basement)
    BasementBuilder.transmitSaveData()
    return basement
end

function BasementBuilder.canExpandFrom(square, targetX, targetY)
    if not square then
        return false, nil, "No square"
    end
    local basement = BasementBuilder.findBasementByCell(square:getX(), square:getY(), square:getZ())
    if not basement then
        return false, nil, "Not in basement"
    end
    if square:getZ() ~= basement.z then
        return false, nil, "Wrong level"
    end
    local dx = math.abs(targetX - square:getX())
    local dy = math.abs(targetY - square:getY())
    if dx + dy ~= 1 then
        return false, nil, "Adjacent only"
    end
    local template = BasementBuilder.getExpandTemplate()
    local overlapReason = nil
    BasementBuilder.iterTemplateCells(template, targetX, targetY, function(x, y)
        if BasementBuilder.hasCell(basement, x, y) then
            overlapReason = "Already dug"
            return
        end
        if not BasementBuilder.squareExists(x, y, basement.z) then
            overlapReason = "Out of bounds"
            return
        end
        if BasementBuilder.findBasementByDugCell(x, y, basement.z) then
            overlapReason = "Overlap"
            return
        end
    end)
    if overlapReason then
        return false, nil, overlapReason
    end
    return true, basement
end

function BasementBuilder._safeCanExpandFrom(square, targetX, targetY)
    local ok, valid, basement, reason = pcall(BasementBuilder.canExpandFrom, square, targetX, targetY)
    if ok then
        return valid, basement, reason
    end
    return false, nil, valid
end

function BasementBuilder.expandBasement(basement, x, y)
    local template = BasementBuilder.getExpandTemplate()
    BasementBuilder.iterTemplateCells(template, x, y, function(cellX, cellY)
        BasementBuilder.setCell(basement, cellX, cellY, true)
    end)
    BasementBuilder.postProcessBasement(basement)
    BasementBuilder.refreshNeighbors(basement, x, y)
    BasementBuilder.clearExteriorCornerSquares(basement)
    BasementBuilder.recalcLoadedPerimeter(basement, BasementBuilder.CLEARANCE_RADIUS)
    BasementBuilder.refreshChunkExtents()
    BasementBuilder.transmitSaveData()
end

function BasementBuilder.rebuildAll()
    local data = BasementBuilder.getSaveData()
    for _, basement in pairs(data.basements) do
        BasementBuilder.ensureBasementShape(basement)
        basement.walls = {}
        BasementBuilder.postProcessBasement(basement)
        for key, _ in pairs(basement.cells) do
            local x, y = BasementBuilder.parseKey(key)
            BasementBuilder.refreshTile(basement, x, y)
        end
        local template = BasementBuilder.getBasementTemplate(basement)
        BasementBuilder.applyDecorList(basement, template.decor and template.decor.basement)
        BasementBuilder.ensureEntryMarkers(basement)
    end
end

function BasementBuilder.onLoadGridSquare(square)
    if not BasementBuilder.isSquareChunkLoaded(square) then
        return
    end

    local data = BasementBuilder.getSaveData()
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()

    for _, basement in pairs(data.basements) do
        BasementBuilder.ensureBasementShape(basement)

        local entryX = basement.stairs and basement.stairs.x or (basement.origin and basement.origin.x)
        local entryY = basement.stairs and basement.stairs.y or (basement.origin and basement.origin.y)
        local landing = basement.stairs and basement.stairs.landing or nil
        local landingX = landing and landing.x or nil
        local landingY = landing and landing.y or nil

        if z == basement.z then
            if BasementBuilder.isWithinBasementPerimeter(basement, x, y, BasementBuilder.CLEARANCE_RADIUS) then
                local changed = false
                if BasementBuilder.hasCell(basement, x, y) then
                    changed = BasementBuilder.removeUndergroundBlocks(square)
                else
                    changed = BasementBuilder.clearBasementFill(square)
                end
                if changed then
                    square:RecalcAllWithNeighbours(true)
                end
            end

            local shouldRefresh = BasementBuilder.hasCell(basement, x, y)
                or BasementBuilder.hasCell(basement, x - 1, y)
                or BasementBuilder.hasCell(basement, x + 1, y)
                or BasementBuilder.hasCell(basement, x, y - 1)
                or BasementBuilder.hasCell(basement, x, y + 1)
            if shouldRefresh then
                if BasementBuilder.hasCell(basement, x, y) then BasementBuilder.refreshTile(basement, x, y) end
                if BasementBuilder.hasCell(basement, x - 1, y) then BasementBuilder.refreshTile(basement, x - 1, y) end
                if BasementBuilder.hasCell(basement, x + 1, y) then BasementBuilder.refreshTile(basement, x + 1, y) end
                if BasementBuilder.hasCell(basement, x, y - 1) then BasementBuilder.refreshTile(basement, x, y - 1) end
                if BasementBuilder.hasCell(basement, x, y + 1) then BasementBuilder.refreshTile(basement, x, y + 1) end
            end
        end

        if (z == 0 and x == entryX and y == entryY) or
            (landingX and landingY and z == basement.z and x == landingX and y == landingY) then
            BasementBuilder.ensureEntryMarkers(basement)
        end
    end
end

Events.LoadGridsquare.Add(BasementBuilder.onLoadGridSquare)
