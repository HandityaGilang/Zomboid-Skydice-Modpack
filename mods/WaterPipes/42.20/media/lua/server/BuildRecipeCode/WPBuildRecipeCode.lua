BuildRecipeCode = BuildRecipeCode or {}

BuildRecipeCode.waterPump = {}
BuildRecipeCode.waterPump.OnCreate = function(data)
    local thumpable = data.thumpable
    local sprite = getSprite(thumpable:getSprite():getName())
    local cell = getCell()
    local square = thumpable:getSquare()
    local sx, sy, sz = square:getX(), square:getY(), square:getZ()
    local object = IsoClothingDryer.new(cell, square, sprite)
    local gmd = GetWPModData()

    object:setActivated(false)
    object:setMovedThumpable(true)
    object:createContainersFromSpriteProperties()
    square:AddSpecialObject(object)

	if thumpable:getSquare() ~= nil then
		thumpable:removeFromWorld()
		thumpable:removeFromSquare()
		thumpable:setSquare(nil)
	end

    gmd.Pumps[WPUtils.Coords2Id(sx, sy, sz)] = { x = sx, y = sy, z = sz, efficiency = 100, filter = 0, active = false, burn = false }
    TransmitWPModData()
	return { replaceObject = true, object = object }
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

    local thumpable = data.thumpable
    local square = thumpable:getSquare()
    local cell = square:getCell()
    local sx, sy, sz = square:getX(), square:getY(), square:getZ()
    local gmd = GetWPModData()

    local function determinePipeSprites(neighbours, neighboursUp)

        local spriteKey = "nswe"
        local extraSpriteKey = nil

        if neighbours[1] and neighbours[2] and neighbours[3] and neighbours[4] then
            spriteKey = "nswe"
        elseif neighbours[1] and neighbours[3] and neighbours[4] then
            spriteKey = "nsw"
        elseif neighbours[1] and neighbours[2] and neighbours[4] then
            spriteKey = "swe"
        elseif neighbours[2] and neighbours[3] and neighbours[4] then
            spriteKey = "nse"
        elseif neighbours[1] and neighbours[2] and neighbours[3] then
            spriteKey = "nwe"
        elseif neighbours[3] and neighbours[4] then
            spriteKey = "ns"
        elseif neighbours[1] and neighbours[2] then
            spriteKey = "we"
        elseif neighbours[2] and neighbours[3] then
            spriteKey = "ne"
        elseif neighbours[2] and neighbours[4] then
            spriteKey = "se"
        elseif neighbours[1] and neighbours[4] then
            spriteKey = "sw"
        elseif neighbours[1] and neighbours[3] then
            spriteKey = "nw"
        elseif neighbours[1] and neighboursUp[2] then 
            spriteKey = "wu"
            extraSpriteKey = "ed"
        elseif neighbours[1] and not neighboursUp[2] then 
            spriteKey = "we"
        elseif neighbours[2] and neighboursUp[1] then
            spriteKey = "eu"
            extraSpriteKey = "wd"
        elseif neighbours[2] and not neighboursUp[1] then
            spriteKey = "we"
        elseif neighbours[3] and neighboursUp[4] then
            spriteKey = "nu"
            extraSpriteKey = "sd"
        elseif neighbours[3] and not neighboursUp[4] then
            spriteKey = "ns"
        elseif neighbours[4] and neighboursUp[3] then
            spriteKey = "su"
            extraSpriteKey = "nd"
        elseif neighbours[4] and not neighboursUp[3] then
            spriteKey = "ns"
        end

        return spriteKey, extraSpriteKey
    end

    local function fixNeighboringPipeSprite (square)
        local sx = square:getX()
        local sy = square:getY()
        local sz = square:getZ()

        local testSquares = {}
        table.insert(testSquares, {x=sx-1, y=sy, z=sz})
        table.insert(testSquares, {x=sx+1, y=sy, z=sz})
        table.insert(testSquares, {x=sx, y=sy-1, z=sz})
        table.insert(testSquares, {x=sx, y=sy+1, z=sz})

        local neighbours = {false, false, false, false}
        local neighboursUp = {false, false, false, false}
        for z=0, 1 do
            for k, coords in ipairs(testSquares) do
                local testX = coords.x
                local testY = coords.y
                local testZ = coords.z + z
                local testSquare = cell:getGridSquare(testX, testY, testZ)
                if testSquare then
                    local isoPipe = WPIso.GetPipe(testSquare)
                    local isoBarrel = WPIso.GetBarrel(testSquare)
                    if isoPipe or isoBarrel then
                        if z == 0 then
                            neighbours[k] = true
                        else
                            neighboursUp[k] = true
                        end
                    end
                end
            end
        end

        local spriteKey, extraSpriteKey = determinePipeSprites(neighbours, neighboursUp)
        local sprite, extraSprite = WPIso.pipeSprites[spriteKey], WPIso.pipeSprites[extraSpriteKey]

        if sprite then
            local objects = square:getObjects()
            for i=0, objects:size()-1 do
                local object = objects:get(i)
                if WPIso.IsPipe(object) then
                    object:setSpriteFromName(sprite)
                    object:transmitUpdatedSpriteToClients()
                    gmd.Pipes[WPUtils.Coords2Id(sx, sy, sz)] = { x = sx, y = sy, z = sz, s=spriteKey }
                    break
                end
            end
        end

        if extraSprite then
            local extraSquare = cell:getGridSquare(sx, sy, sz + 1)
            local objects = extraSquare:getObjects()
            for i=0, objects:size()-1 do
                local object = objects:get(i)
                if WPIso.IsPipe(object) then
                    object:getSquare():transmitRemoveItemFromSquare(object)
                    break
                end
            end

            local extrapipe = IsoObject.new(cell, extraSquare, getSprite(extraSprite))
            extraSquare:AddSpecialObject(extrapipe)
            extrapipe:transmitCompleteItemToClients()
            gmd.Pipes[WPUtils.Coords2Id(sx, sy, sz)] = { x = sx, y = sy, z = sz, s=extraSpriteKey }
        end
    end

    local function connectBuilding(square, building)
        local sx, sy, sz = square:getX(), square:getY(), square:getZ()

        local cell = square:getCell()
        local def = building:getDef()
        local bid = def:getIDString()
        local bx1, bx2 =  def:getX(), def:getX2()
        local by1, by2 = def:getY(), def:getY2()
        local bz1 = def:getMinLevel()
        local bz2 = def:getMaxLevel()

        for z = bz1, bz2 do
            for y = by1, by2 do
                for x = bx1, bx2 do
                    local sq = cell:getGridSquare(x, y, z)
                    if sq and not sq:isOutside() then
                        local isoBarrel = WPIso.GetBarrel(sq)
                        if isoBarrel then
                            local w, wmax = WPIso.GetWaterStatus(isoBarrel)
                            gmd.Barrels[WPUtils.Coords2Id(x, y, z)] = { x = x, y = y, z = z, w=0, wmax=wmax * 100, bid=bid }
                        end
                    end
                end
            end
        end
        gmd.Buildings[WPUtils.Coords2Id(sx, sy, sz)] = { x = sx, y = sy, z = sz, bid=bid }
    end

    local testSquares = {}
    table.insert(testSquares, {x=sx-1, y=sy, z=sz})
    table.insert(testSquares, {x=sx+1, y=sy, z=sz})
    table.insert(testSquares, {x=sx, y=sy-1, z=sz})
    table.insert(testSquares, {x=sx, y=sy+1, z=sz})
    table.insert(testSquares, {x=sx, y=sy, z=sz})

    for _, coords in ipairs(testSquares) do
        local testSquare = cell:getGridSquare(coords.x, coords.y, coords.z)
        local isoPipe = WPIso.GetPipe(testSquare)
        if isoPipe then
            fixNeighboringPipeSprite(testSquare)
        end

        local isoBarrel = WPIso.GetBarrel(testSquare)
        if isoBarrel then
            local w, wmax = WPIso.GetWaterStatus(isoBarrel)
            gmd.Barrels[WPUtils.Coords2Id(coords.x, coords.y, coords.z)] = { x = coords.x, y = coords.y, z = coords.z, w=0, wmax=wmax * 100 }
        end

        local isoBuilding = WPIso.GetBuilding(testSquare)
        if isoBuilding then
            connectBuilding(testSquare, isoBuilding)
        end
    end
        
    TransmitWPModData()

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
        if ps == WPIso.pipeSprites.ns then 
            fs = WPIso.flowmeterSprites.ns
        elseif ps == WPIso.pipeSprites.we then 
            fs = WPIso.flowmeterSprites.we
        end
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