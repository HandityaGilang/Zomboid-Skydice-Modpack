BuildRecipeCode = BuildRecipeCode or {}

BuildRecipeCode.waterPump = {}
BuildRecipeCode.waterPump.OnCreate = function(data)
    return true
end

BuildRecipeCode.waterPump.OnIsValid = function(data)
    local square = data.square
    local cell = square:getCell()
    local sx, sy, sz = square:getX(), square:getY(), square:getZ()
    local testSquares = {}
    table.insert(testSquares, {x=sx-1, y=sy, z=sz})
    table.insert(testSquares, {x=sx+1, y=sy, z=sz})
    table.insert(testSquares, {x=sx, y=sy-1, z=sz})
    table.insert(testSquares, {x=sx, y=sy+1, z=sz})

    local pumpSprites = WPIso.pumpSprites
    for _, coords in ipairs(testSquares) do
        local testSquare = cell:getGridSquare(coords.x, coords.y, coords.z)
        if testSquare then
            local objects = testSquare:getObjects()
            for i=0, objects:size()-1 do
                local object = objects:get(i)
                local sprite = object:getSprite()
                if sprite then
                    local spriteName = sprite:getName()
                    for _, spriteTest in pairs(pumpSprites) do
                        if spriteName == spriteTest then
                            return false
                        end
                    end
                end
            end
        end
    end

    local waterSprites = WPIso.waterSprites
    local freshWaterSprites = WPIso.freshWaterSprites
    local fuelStationSprites = WPIso.fuelStationSprites
    for _, coords in ipairs(testSquares) do
        local testSquare = cell:getGridSquare(coords.x, coords.y, coords.z)
        if testSquare then
            local objects = testSquare:getObjects()
            for i=0, objects:size()-1 do
                local object = objects:get(i)
                local sprite = object:getSprite()
                if sprite then
                    local spriteName = sprite:getName()
                    
                    for _, spriteTest in pairs(freshWaterSprites) do
                        if spriteName == spriteTest then
                            return true
                        end
                    end
                    for _, spriteTest in pairs(waterSprites) do
                        if spriteName == spriteTest then
                            return true
                        end
                    end
                    for _, spriteTest in pairs(fuelStationSprites) do
                        if spriteName == spriteTest then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end


BuildRecipeCode.waterPipe = {}
BuildRecipeCode.waterPipe.OnCreate = function(data)
    return true
end

BuildRecipeCode.waterPipe.OnIsValid = function(data)
    local square = data.square

    if not square:isFree(false) then
        return false
    end

    local isoPipe = WPIso.GetPipe(square)
    if isoPipe then
        return false
    end
    return true
end


BuildRecipeCode.waterValve = {}
-- Server-authoritative registration: OnCreate runs on the server (via ISBuildIsoEntity) with
-- the object already placed. Registering here works in MP, unlike the old client-side
-- checkForAddition path which never detected overlay objects on a remote client.
BuildRecipeCode.waterValve.OnCreate = function(params)
    local thumpable = params.thumpable
    local sq = thumpable and thumpable:getSquare()
    if not sq then return true end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()

    -- match the valve sprite to the underlying pipe orientation (as the old code did)
    local isoPipe = WPIso.GetPipe(sq)
    if isoPipe then
        local ps = isoPipe:getSprite():getName()
        local vs
        if ps == WPIso.pipeSprites.ns then vs = WPIso.valveSprites.ns
        elseif ps == WPIso.pipeSprites.we then vs = WPIso.valveSprites.we end
        local spr = vs and getSprite(vs)
        if spr then
            thumpable:setSprite(spr)
            thumpable:transmitUpdatedSpriteToClients()
        end
    end

    local gmd = GetWPModData()
    gmd.Valves[WPUtils.Coords2Id(x, y, z)] = { x = x, y = y, z = z, c = false }
    TransmitWPModData()
    return true
end

BuildRecipeCode.waterValve.OnIsValid = function(data)
    local square = data.square

    local isoValve = WPIso.GetValve(square)
    if isoValve then
        return false
    end

    local isoFlowmeter = WPIso.GetFlowmeter(square)
    if isoFlowmeter then
        return false
    end

    local isoPipe = WPIso.GetPipe(square)
    if isoPipe then
        local sp = isoPipe:getSprite():getName()
        if sp == WPIso.pipeSprites.ns or sp == WPIso.pipeSprites.we then
            return true
        end
    end
    return false
end

BuildRecipeCode.waterFlowmeter = {}
BuildRecipeCode.waterFlowmeter.OnCreate = function(params)
    local thumpable = params.thumpable
    local sq = thumpable and thumpable:getSquare()
    if not sq then return true end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()

    local isoPipe = WPIso.GetPipe(sq)
    if isoPipe then
        local ps = isoPipe:getSprite():getName()
        local fs
        if ps == WPIso.pipeSprites.ns then fs = WPIso.flowmeterSprites.ns
        elseif ps == WPIso.pipeSprites.we then fs = WPIso.flowmeterSprites.we end
        local spr = fs and getSprite(fs)
        if spr then
            thumpable:setSprite(spr)
            thumpable:transmitUpdatedSpriteToClients()
        end
    end

    local gmd = GetWPModData()
    gmd.Flowmeters[WPUtils.Coords2Id(x, y, z)] = { x = x, y = y, z = z, f = 0 }
    TransmitWPModData()
    return true
end

BuildRecipeCode.waterFlowmeter.OnIsValid = function(data)
    local square = data.square

    local isoValve = WPIso.GetValve(square)
    if isoValve then
        return false
    end

    local isoFlowmeter = WPIso.GetFlowmeter(square)
    if isoFlowmeter then
        return false
    end

    local isoPipe = WPIso.GetPipe(square)
    if isoPipe then
        local sp = isoPipe:getSprite():getName()
        if sp == WPIso.pipeSprites.ns or sp == WPIso.pipeSprites.we then
            return true
        end
    end
    return false
end


BuildRecipeCode.waterSprinkler = {}
BuildRecipeCode.waterSprinkler.OnCreate = function(params)
    local thumpable = params.thumpable
    local sq = thumpable and thumpable:getSquare()
    if not sq then return true end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()

    local gmd = GetWPModData()
    gmd.Sprinklers[WPUtils.Coords2Id(x, y, z)] = { x = x, y = y, z = z, w = 0, wmax = 200 }
    TransmitWPModData()
    return true
end

BuildRecipeCode.waterSprinkler.OnIsValid = function(data)
    local square = data.square

    local isoPipe = WPIso.GetPipe(square)
    if isoPipe then
        return true
    end
    return false
end