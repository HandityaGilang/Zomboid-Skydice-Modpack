WPIso = WPIso or {}

-- PUMPS
local pumpSprites = {}
pumpSprites.ns = "waterpipes_01_24"
pumpSprites.we = "waterpipes_01_25"

WPIso.pumpSprites = pumpSprites

-- PIPES
local pipeSprites = {}

-- curves
pipeSprites.ne = "waterpipes_01_10"
pipeSprites.se = "waterpipes_01_8"
pipeSprites.sw = "waterpipes_01_11"
pipeSprites.nw = "waterpipes_01_9"

-- t-shapes
pipeSprites.nsw = "waterpipes_01_5"
pipeSprites.swe = "waterpipes_01_4"
pipeSprites.nse = "waterpipes_01_6"
pipeSprites.nwe = "waterpipes_01_3"

-- straight
pipeSprites.ns = "waterpipes_01_0"
pipeSprites.we = "waterpipes_01_1"

-- downs
pipeSprites.nd = "waterpipes_01_16"
pipeSprites.wd = "waterpipes_01_18"
pipeSprites.ed = "waterpipes_01_19"
pipeSprites.sd = "waterpipes_01_17"

-- cross
pipeSprites.nswe = "waterpipes_01_2"

-- upwards
pipeSprites.eu = "waterpipes_01_15"
pipeSprites.su = "waterpipes_01_13"
pipeSprites.nu = "waterpipes_01_12"
pipeSprites.wu = "waterpipes_01_14"

--[[
-- PIPES
local pipeSprites = {}

-- curves
pipeSprites.ne = "industry_02_24"
pipeSprites.se = "industry_02_25"
pipeSprites.sw = "industry_02_26"
pipeSprites.nw = "industry_02_27"

-- t-shapes
pipeSprites.nsw = "industry_02_28"
pipeSprites.swe = "industry_02_29"
pipeSprites.nse = "industry_02_30"
pipeSprites.nwe = "industry_02_31"

-- straight
pipeSprites.ns = "industry_02_32"
pipeSprites.we = "industry_02_33"

-- downs
pipeSprites.nd = "industry_02_35"
pipeSprites.wd = "industry_02_36"
pipeSprites.ed = "industry_02_37"
pipeSprites.sd = "industry_02_38"

-- cross
pipeSprites.nswe = "industry_02_39"

-- upwards
pipeSprites.eu = "industry_02_76"
pipeSprites.su = "industry_02_77"
pipeSprites.nu = "industry_02_78"
pipeSprites.wu = "industry_02_79"

]]

WPIso.pipeSprites = pipeSprites


-- VALVES
local valveSprites = {}
valveSprites.ns = "waterpipes_01_20"
valveSprites.we = "waterpipes_01_21"
WPIso.valveSprites = valveSprites

-- FLOWMETERS
local flowmeterSprites = {}
flowmeterSprites.ns = "waterpipes_01_22"
flowmeterSprites.we = "waterpipes_01_23"
WPIso.flowmeterSprites = flowmeterSprites

-- RECEIVERS
local barrelSprites = {}
table.insert(barrelSprites, "carpentry_02_120")
table.insert(barrelSprites, "carpentry_02_121")
table.insert(barrelSprites, "carpentry_02_122")
table.insert(barrelSprites, "carpentry_02_123")
table.insert(barrelSprites, "carpentry_02_124")
table.insert(barrelSprites, "carpentry_02_125")
table.insert(barrelSprites, "carpentry_02_126")
table.insert(barrelSprites, "carpentry_02_127")

for i=0, 11 do
    table.insert(barrelSprites, "fixtures_bathroom_01_" .. i)
end

table.insert(barrelSprites, "fixtures_bathroom_01_25")
table.insert(barrelSprites, "fixtures_bathroom_01_26")
table.insert(barrelSprites, "fixtures_bathroom_01_32")
table.insert(barrelSprites, "fixtures_bathroom_01_33")
table.insert(barrelSprites, "fixtures_bathroom_01_52")
table.insert(barrelSprites, "fixtures_bathroom_01_54")
table.insert(barrelSprites, "fixtures_bathroom_01_55")
table.insert(barrelSprites, "fixtures_bathroom_02_4")
table.insert(barrelSprites, "fixtures_bathroom_02_5")
table.insert(barrelSprites, "fixtures_bathroom_02_14")
table.insert(barrelSprites, "fixtures_bathroom_02_15")

for i=0, 35 do
    table.insert(barrelSprites, "fixtures_sinks_01_" .. i)
end

for i=0, 7 do
    table.insert(barrelSprites, "appliances_laundry_01_" .. i)
end

WPIso.barrelSprites = barrelSprites

local waterSprinklersSprites = {}
table.insert(waterSprinklersSprites, "waterpipes_01_7")
WPIso.waterSprinklersSprites = waterSprinklersSprites

-- TAINTED WATER SOURCES
local waterSprites = {}
table.insert(waterSprites, "blends_natural_02_0")
table.insert(waterSprites, "blends_natural_02_5")
table.insert(waterSprites, "blends_natural_02_6")
table.insert(waterSprites, "blends_natural_02_7")
table.insert(waterSprites, "industry_02_191") -- hack for w1a
WPIso.waterSprites = waterSprites

-- FRESH WATER SOURCES
local freshWaterSprites = {}
table.insert(freshWaterSprites, "camping_01_16") -- well
table.insert(freshWaterSprites, "morebuild_01_0") -- well morebuild
WPIso.freshWaterSprites = freshWaterSprites

-- FUEL SOURCES
local fuelStationSprites = {}
table.insert(fuelStationSprites, "location_shop_gas2go_01_12")
table.insert(fuelStationSprites, "location_shop_gas2go_01_13")
table.insert(fuelStationSprites, "location_shop_gas2go_01_14")
table.insert(fuelStationSprites, "location_shop_gas2go_01_15")
table.insert(fuelStationSprites, "location_shop_fossoil_01_12")
table.insert(fuelStationSprites, "location_shop_fossoil_01_13")
table.insert(fuelStationSprites, "location_shop_fossoil_01_14")
table.insert(fuelStationSprites, "location_shop_fossoil_01_15")
WPIso.fuelStationSprites = fuelStationSprites

-- pumps

WPIso.IsPump = function(object)
    local sprite = object:getSprite()
    if sprite then
        local lookupSprites = WPIso.pumpSprites
        local spriteName = sprite:getName()
        for _, lookupSprite in pairs(lookupSprites) do
            if spriteName == lookupSprite then
                return true
            end
        end
    end
    return false
end

WPIso.GetPump = function(square)
    local objects = square:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        if WPIso.IsPump(object) then
            return object
        end
    end
end

WPIso.SyncPump = function(pump)
    local cell = getCell()
    local sx, sy, sz = pump.x, pump.y, pump.z
    local square = cell:getGridSquare(sx, sy, sz)

    if square then
        -- sync status
        local isoPump = WPIso.GetPump(square)
        if isoPump then
            if square:haveElectricity() then
                if isoPump:isActivated() ~= pump.active then
                    isoPump:setActivated(pump.active)
                end
            else
                pump.active = false
                isoPump:setActivated(false)
            end
        end

        -- sync sound
        if not isServer() then
            if pump.active then
                WPSound.AddToObject(isoPump, "WPWaterPumpLoop", 0.5)
            else
                WPSound.RemoveFromObject(isoPump)
            end
        end
    end

    -- sync water source
    local waterSprites = WPIso.waterSprites
    local freshWaterSprites = WPIso.freshWaterSprites
    local fuelStationSprites = WPIso.fuelStationSprites

    local testSquares = {}
    table.insert(testSquares, {x=sx-1, y=sy, z=sz})
    table.insert(testSquares, {x=sx+1, y=sy, z=sz})
    table.insert(testSquares, {x=sx, y=sy-1, z=sz})
    table.insert(testSquares, {x=sx, y=sy+1, z=sz})

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
                            pump.source = "Water"
                            return
                        end
                    end
                    for _, spriteTest in pairs(waterSprites) do
                        if spriteName == spriteTest then
                            pump.source =  "TaintedWater"
                            return
                        end
                    end
                    for _, spriteTest in pairs(fuelStationSprites) do
                        if spriteName == spriteTest then
                            pump.source =  "Petrol"
                            return
                        end
                    end
                end
            end
        end
    end
end

-- pipes

WPIso.IsPipe = function(object)
    local sprite = object:getSprite()
    if sprite then
        local lookupSprites = WPIso.pipeSprites
        local spriteName = sprite:getName()
        for _, lookupSprite in pairs(lookupSprites) do
            if spriteName == lookupSprite then
                return true
            end
        end
    end
    return false
end

WPIso.GetPipe = function(square)
    local objects = square:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        if WPIso.IsPipe(object) then
            return object
        end
    end
end

WPIso.BuildPipe = function(square)

    local cell = getCell()

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
                local testX = coords["x"]
                local testY = coords["y"]
                local testZ = coords["z"] + z
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
                    object:transmitUpdatedSpriteToServer()
                    WPVirtual.PipeAdd(sx, sy, sz, spriteKey)
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
                    if isClient() then
                        sledgeDestroy(object)
                    else
                        object:getSquare():transmitRemoveItemFromSquare(object)
                    end
                    -- WPVirtual.PipeRemove(sx, sy, sz + 1)
                    break
                end
            end

            local extrapipe = IsoObject.new(extraSquare:getCell(), extraSquare, getSprite(extraSprite))
            extraSquare:AddSpecialObject(extrapipe)
            extrapipe:transmitCompleteItemToClients()
            WPVirtual.PipeAdd(sx, sy, sz + 1, extraSpriteKey)
        end
    end

    local sx, sy, sz = square:getX(), square:getY(), square:getZ()

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
            WPVirtual.BarrelAdd(coords.x, coords.y, coords.z, wmax * 100)
        end

        local isoBuilding = WPIso.GetBuilding(testSquare)
        if isoBuilding then
            WPIso.ConnectBuilding(testSquare, isoBuilding)
        end
    end
end

-- valves

WPIso.IsValve = function(object)
    local sprite = object:getSprite()
    if sprite then
        local lookupSprites = WPIso.valveSprites
        local spriteName = sprite:getName()
        for _, lookupSprite in pairs(lookupSprites) do
            if spriteName == lookupSprite then
                return true
            end
        end
    end
    return false
end

WPIso.GetValve = function(square)
    local objects = square:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        if WPIso.IsValve(object) then
            return object
        end
    end
end

-- flowmeters

WPIso.IsFlowmeter = function(object)
    local sprite = object:getSprite()
    if sprite then
        local lookupSprites = WPIso.flowmeterSprites
        local spriteName = sprite:getName()
        for _, lookupSprite in pairs(lookupSprites) do
            if spriteName == lookupSprite then
                return true
            end
        end
    end
    return false
end

WPIso.GetFlowmeter = function(square)
    local objects = square:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        if WPIso.IsFlowmeter(object) then
            return object
        end
    end
end

-- barrels

WPIso.IsBarrel = function(object)
    local sprite = object:getSprite()
    if sprite then
        local lookupSprites = WPIso.barrelSprites
        local spriteName = sprite:getName()
        for _, lookupSprite in pairs(lookupSprites) do
            if spriteName == lookupSprite then
                return true
            end
        end
    end
    return false
end

WPIso.GetBarrel = function(square)
    local objects = square:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        if WPIso.IsBarrel(object) then
            return object
        end
    end
end

WPIso.GetWaterStatus = function(object)
    local w, wmax = 0, 20
    local sprite = object:getSprite()
    local container = object:getFluidContainer()
    local md = object:getModData()
    md.canBeWaterPiped = nil -- this disables vanilla plumbing which allows drink/fill menu
    local props = sprite:getProperties()
    if sprite then
        if md.waterMaxAmount and md.waterAmount then -- this is when water shutoff happened for sinks
            w = md.waterAmount
            wmax = md.waterMaxAmount
            
            local test = object:hasFluid()
        elseif props:has("waterAmount") and props:has("waterMaxAmount") then -- this is when wter shutoff NOT happened for sinks
            w = props:get("waterAmount")
            wmax = props:get("waterMaxAmount")
        elseif instanceof(object, "IsoCombinationWasherDryer") or instanceof(object, "IsoClothingWasher") then
            wmax = 40
            w = object:getFluidAmount()
        elseif container then -- real barrels
            wmax = object:getFluidCapacity()
            w = object:getFluidAmount()
        end
    end
    object:transmitModData()
    object:sync()
    return w, wmax
end

WPIso.SyncBarrel = function(barrel)
    local cell = getCell()
    local square = cell:getGridSquare(barrel.x, barrel.y, barrel.z)
    local isoBarrel
    if square then
        local objects = square:getObjects()
        for i=0, objects:size()-1 do
            local object = objects:get(i)
            if WPIso.IsBarrel(object) then
                isoBarrel = object
                break
            end
        end
    end

    if isoBarrel then
        -- Rain barrels are authoritative via SRainBarrelSystem; update through that
        -- to avoid stateToIsoObject overwriting our addFluid on the next system tick.
        local rbSys = SRainBarrelSystem and SRainBarrelSystem.instance
        local rbLuaObj = rbSys and rbSys:getLuaObjectAt(barrel.x, barrel.y, barrel.z)
        if rbLuaObj then
            local available = barrel.w / 100
            if available > 0 then
                local rbWater = rbLuaObj.waterAmount or 0
                local rbMax   = rbLuaObj.waterMax   or 0
                local needed  = rbMax - rbWater
                if needed > 0 then
                    local add = math.min(available, needed)
                    rbLuaObj.waterAmount = rbWater + add
                    barrel.w = barrel.w - (add * 100)
                    rbLuaObj:saveData()
                end
            end
            return
        end

        local w, wmax = WPIso.GetWaterStatus(isoBarrel)
        local needed = wmax - w
        if needed > 0 then
            local available = barrel.w / 100
            if available > 0 then
                local add
                if available < needed then
                    add = available
                else
                    add = needed
                end

                local container = isoBarrel:getFluidContainer()
                if container or instanceof(isoBarrel, "IsoCombinationWasherDryer") or instanceof(isoBarrel, "IsoClothingWasher") then
                    local fluidType = FluidType.Water
                    isoBarrel:addFluid(fluidType, add)
                    barrel.w = barrel.w - (add * 100)

                    local md = isoBarrel:getModData()
                    if not md.waterAmount then md.waterAmount = 0 end
                    if not md.waterMaxAmount then 
                        local capacity = isoBarrel:getFluidCapacity()
                        if capacity then
                            if capacity < 40 then
                                capacity = 40
                            end
                            md.waterMaxAmount = capacity
                        else
                            md.waterMaxAmount = 40 
                        end
                    end

                    md.waterAmount = md.waterAmount + add
                    if md.waterAmount > md.waterMaxAmount then md.waterAmount = md.waterMaxAmount end
                    isoBarrel:transmitModData()
                    isoBarrel:sync()
                    -- print ("SYNC TO WASHING MACHINE: " .. add)
                else
                    local md = isoBarrel:getModData()
                    if md.waterMaxAmount and md.waterAmount then
                        local fluidType = FluidType[barrel.m]
                        isoBarrel:addFluid(fluidType, add)

                        md.waterAmount = md.waterAmount + add
                        -- print ("SYNC TO SINK: " .. add)
                        barrel.w = barrel.w - (add * 100)
                        isoBarrel:transmitModData()
                        isoBarrel:sync()
                    end
                end
                
            end
        end

        local props = isoBarrel:getSprite():getProperties()
        if barrel.w > 0 and barrel.m == "TaintedWater" then
            props:set(IsoFlagType.taintedWater)
        else
            props:unset(IsoFlagType.taintedWater)
        end
    end
end

-- sprinklers

WPIso.IsSprinkler = function(object)
    local sprite = object:getSprite()
    if sprite then
        local lookupSprites = WPIso.waterSprinklersSprites
        local spriteName = sprite:getName()
        for _, lookupSprite in pairs(lookupSprites) do
            if spriteName == lookupSprite then
                return true
            end
        end
    end
    return false
end

WPIso.GetSprinkler = function(square)
    local objects = square:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        if WPIso.IsSprinkler(object) then
            return object
        end
    end
end

-- buildings

WPIso.GetBuilding = function(square)
    return square:getBuilding()
end

WPIso.ConnectBuilding = function(square, building)
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
                        WPVirtual.BarrelAdd(x, y, z, wmax * 100, bid)
                    end
                end
            end
        end
    end

    WPVirtual.BuildingAdd(sx, sy, sz, bid)
end

-- medium

WPIso.IsWater = function(object)
    local sprite = object:getSprite()
    if sprite then
        local lookupSprites = WPIso.waterSprites
        local spriteName = sprite:getName()
        for _, lookupSprite in pairs(lookupSprites) do
            if spriteName == lookupSprite then
                return true
            end
        end
    end
    return false
end

WPIso.IsFreshWater = function(object)
    local sprite = object:getSprite()
    if sprite then
        local lookupSprites = WPIso.freshWaterSprites
        local spriteName = sprite:getName()
        for _, lookupSprite in pairs(lookupSprites) do
            if spriteName == lookupSprite then
                return true
            end
        end
    end
    return false
end

WPIso.IsFuelStation = function(object)
    local sprite = object:getSprite()
    if sprite then
        local lookupSprites = WPIso.fuelStationSprites
        local spriteName = sprite:getName()
        for _, lookupSprite in pairs(lookupSprites) do
            if spriteName == lookupSprite then
                return true
            end
        end
    end
    return false
end




