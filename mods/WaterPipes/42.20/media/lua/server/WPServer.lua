
-- the matrix defines the vectors where the water can go next
-- based on a shape of the pipe, and the direction from where the water is coming from
local matrix = {
    ["ne"] = {
        ["n"] = {{x=1, y=0, z=0}},
        ["e"] = {{x=0, y=-1, z=0}},
    },
    ["se"] = {
        ["s"] = {{x=1, y=0, z=0}},
        ["e"] = {{x=0, y=1, z=0}},
    },
    ["sw"] = {
        ["s"] = {{x=-1, y=0, z=0}},
        ["w"] = {{x=0, y=1, z=0}},
    },
    ["nw"] = {
        ["n"] = {{x=-1, y=0, z=0}},
        ["w"] = {{x=0, y=-1, z=0}},
    },
    ["ns"] = {
        ["n"] = {{x=0, y=1, z=0}},
        ["s"] = {{x=0, y=-1, z=0}},
    },
    ["we"] = {
        ["w"] = {{x=1, y=0, z=0}},
        ["e"] = {{x=-1, y=0, z=0}},
    },
    ["nd"] = {
        ["n"] = {{x=0, y=0, z=-1}},
        ["d"] = {{x=0, y=-1, z=0}},
    },
    ["sd"] = {
        ["s"] = {{x=0, y=0, z=-1}},
        ["d"] = {{x=0, y=1, z=0}},
    },
    ["wd"] = {
        ["w"] = {{x=0, y=0, z=-1}},
        ["d"] = {{x=-1, y=0, z=0}},
    },
    ["ed"] = {
        ["e"] = {{x=0, y=0, z=-1}},
        ["d"] = {{x=1, y=0, z=0}},
    },
    ["nu"] = {
        ["n"] = {{x=0, y=0, z=1}},
        ["u"] = {{x=0, y=-1, z=0}},
    },
    ["su"] = {
        ["s"] = {{x=0, y=0, z=1}},
        ["u"] = {{x=0, y=1, z=0}},
    },
    ["wu"] = {
        ["w"] = {{x=0, y=0, z=1}},
        ["u"] = {{x=-1, y=0, z=0}},
    },
    ["eu"] = {
        ["e"] = {{x=0, y=0, z=1}},
        ["u"] = {{x=1, y=0, z=0}},
    },
    ["nsw"] = {
        ["n"] = {{x=-1, y=0, z=0}, {x=0, y=1, z=0}},
        ["s"] = {{x=-1, y=0, z=0}, {x=0, y=-1, z=0}},
        ["w"] = {{x=0, y=-1, z=0}, {x=0, y=1, z=0}},
    },
    ["swe"] = {
        ["s"] = {{x=-1, y=0, z=0}, {x=1, y=0, z=0}},
        ["w"] = {{x=1, y=0, z=0}, {x=0, y=1, z=0}},
        ["e"] = {{x=-1, y=0, z=0}, {x=0, y=1, z=0}},
    },
    ["nse"] = {
        ["n"] = {{x=1, y=0, z=0}, {x=0, y=1, z=0}},
        ["s"] = {{x=1, y=0, z=0}, {x=0, y=-1, z=0}},
        ["e"] = {{x=0, y=-1, z=0}, {x=0, y=1, z=0}},
    },
    ["nwe"] = {
        ["n"] = {{x=-1, y=0, z=0}, {x=1, y=0, z=0}},
        ["w"] = {{x=1, y=0, z=0}, {x=0, y=-1, z=0}},
        ["e"] = {{x=-1, y=0, z=0}, {x=0, y=-1, z=0}},
    },
    ["nswe"] = {
        ["n"] = {{x=-1, y=0, z=0}, {x=1, y=0, z=0}, {x=0, y=1, z=0}},
        ["s"] = {{x=-1, y=0, z=0}, {x=1, y=0, z=0}, {x=0, y=-1, z=0}},
        ["w"] = {{x=0, y=-1, z=0}, {x=0, y=1, z=0}, {x=1, y=0, z=0}},
        ["e"] = {{x=0, y=-1, z=0}, {x=0, y=1, z=0}, {x=-1, y=0, z=0}},
    },
}

local pipeTraversed = {}
local pipeTraversedValve = {}
local pipeTraversedValveDepth = 0

-- MP scalability: ModData.transmit() serializes and sends the ENTIRE water network
-- (every pump/pipe/valve/flowmeter/barrel/sprinkler) to all clients. Doing this every
-- game-minute unconditionally floods a server. We only need to sync while water is
-- actually moving; when the whole network is idle nothing changes. Transmit while any
-- pump is active, plus one final tick after it stops (to sync flowmeter->0 / sprinkler off).
local wpWasActiveLastTick = false

-- determine traverse vetors base on pipe shpe and input direction
local function getVectors (shape, dir)
    local vectors = {}
    if matrix[shape] then
        if matrix[shape][dir] then
            vectors = matrix[shape][dir]
        end
    end

    for k, vector in pairs(vectors) do
        local d
        if vector.x == 1 then d = "w" end
        if vector.x == -1 then d = "e" end
        if vector.y == 1 then d = "n" end
        if vector.y == -1 then d = "s" end
        if vector.z == 1 then d = "d" end
        if vector.z == -1 then d = "u" end
        vectors[k]["d"] = d
    end
    return vectors
end

-- traverses pipe to next node to see if the pipline has a closed valve
local function hasClosedValve(sx, sy, sz, sdir)
    local gmd = GetWPModData()

    local x = sx
    local y = sy
    local z = sz
    local dir = sdir

    local continue = true

    while (continue) do
        local traverseId = WPUtils.Coords2Id(x, y, z)

        -- probably a loop pipe case
        if pipeTraversedValve[traverseId] ~= nil then return pipeTraversedValve[traverseId] end

        -- we've found a pump so direction is opposite
        local pump = gmd.Pumps[traverseId]
        if pump then 
            pipeTraversedValve[traverseId] = true
            return true 
        end

        -- end of pipline case, water pours out of pipe
        local pipe = gmd.Pipes[traverseId]
        if not pipe then
            pipeTraversedValve[traverseId] = false
            return false
        end

        -- print ("(PIPE) TRAVERSE:" .. traverseId .. " A:" .. amount)
        
        -- we've found a closed valve
        local valve = gmd.Valves[traverseId]
        if valve and valve.c then
            pipeTraversedValve[traverseId] = true
            return true
        end

        -- end of pipeline, next pipline has separate check
        if pipeTraversedValveDepth > 10 then
            return true
        end

        local vectors = getVectors(pipe.s, dir)
        if #vectors > 1 then 
            local allClosed = true
            for k, vector in pairs(vectors) do
                local nx = x + vector.x
                local ny = y + vector.y
                local nz = z + vector.z
                local ndir = vector.d
                pipeTraversedValveDepth = pipeTraversedValveDepth + 1
                if not hasClosedValve(nx, ny, nz, ndir) then
                    -- print ("--- PIPE X:" .. nx .. " Y:" .. ny .. " D:" .. ndir .. " IS OPEN")
                    allClosed = false
                else
                    -- print ("--- PIPE X:" .. nx .. " Y:" .. ny .. " D:" .. ndir .. " HAS CLOSED VALVE")
                end
                pipeTraversedValveDepth = pipeTraversedValveDepth - 1
            end
            if allClosed then 
                -- print ("--- CONCLUSION ALLCLOSED")
                pipeTraversedValve[traverseId] = true
                return true 
            else
                -- print ("--- CONCLUSION NOT ALLCLOSED")
                pipeTraversedValve[traverseId] = false
                return false
            end
        end 

        -- this should not happen, but ...
        if #vectors == 0 then return false end 

        local vector = vectors[1]
        x = x + vector.x
        y = y + vector.y
        z = z + vector.z
        dir = vector.d
    end
end

-- eliminates vectors for pipliones that have closed valves somethere in the line
local function eliminateVectorsWithClosedValves(x, y, z, vectors)
    local newVectors = {}

    for k, vector in pairs(vectors) do
        local nx = x + vector.x
        local ny = y + vector.y
        local nz = z + vector.z
        local ndir = vector.d
        if not hasClosedValve(nx, ny, nz, ndir) then
            table.insert(newVectors, vector)
            -- print ("PIPE X:" .. nx .. " Y:" .. ny .. " D:" .. ndir .. " IS OPEN")
        else
            -- print ("PIPE X:" .. nx .. " Y:" .. ny .. " D:" .. ndir .. " HAS CLOSED VALVE")
        end
    end
    return newVectors
end

-- main water traverse func
local function traversePipes(sx, sy, sz, sdir, medium, amount)

    -- getSandboxOptions():set("WaterShut", 1)
    -- getSandboxOptions():set("WaterShutModifier", 0)

    local x = sx
    local y = sy
    local z = sz
    local dir = sdir

    local continue = true

    local gmd = GetWPModData()

    while (continue) do
        local traverseId = WPUtils.Coords2Id(x, y, z)

        -- probably a loop pipe case
        if pipeTraversed[traverseId] then return end

        local pipe = gmd.Pipes[traverseId]
        local barrel = gmd.Barrels[traverseId]
        local building = gmd.Buildings[traverseId]
        if pipe then
            -- print ("(PIPE) TRAVERSE:" .. traverseId .. " A:" .. amount)
            pipeTraversed[traverseId] = true

            -- puts water in the sprinkler, unless every outgoing path is blocked by a
            -- closed valve (handles [sprinkler]→[valve] layouts where users expect the
            -- downstream valve to shut off the sprinkler)
            local sprinkler = gmd.Sprinklers[traverseId]
            if sprinkler then
                local vectors = getVectors(pipe.s, dir)
                local allBlocked = vectors and #vectors > 0
                if allBlocked then
                    for _, v in ipairs(vectors) do
                        local nid = WPUtils.Coords2Id(x + v.x, y + v.y, z + v.z)
                        local nv = gmd.Valves[nid]
                        if not (nv and nv.c) then
                            allBlocked = false
                            break
                        end
                    end
                end
                if not allBlocked then
                    local used = WPVirtual.SprinklerPourIn(x, y, z, amount)
                    amount = amount - used
                    -- print ("(SPRINKLER) TRAVERSE:" .. traverseId .. " A:" .. amount)
                end
            end

            -- update flowmeter if there is one
            local flowmeter = gmd.Flowmeters[traverseId]
            if flowmeter then
                flowmeter.f = flowmeter.f + amount
            end

            -- proceed if valve is not present or is open
            local valve = gmd.Valves[traverseId]
            if not valve or not valve.c then
                local vectors = getVectors(pipe.s, dir)
                if vectors then
                    -- non-recursive traverse
                    if #vectors == 1 then
                        local vector = vectors[1]
                        x = x + vector.x
                        y = y + vector.y
                        z = z + vector.z
                        dir = vector.d

                    -- we are at the node, begin recursive traverse 
                    elseif #vectors > 1 then

                        -- preliminaty scan of the pipline to see if it has a closed valve
                        vectors = eliminateVectorsWithClosedValves(x, y, z, vectors)
                        local amountParts = WPUtils.SplitIntToParts(amount, #vectors)

                        for k, vector in pairs(vectors) do
                            local amountPart = amountParts[k]

                            -- no need to pump if there is no more water
                            if amountPart > 0 then
                                local nx = x + vector.x
                                local ny = y + vector.y
                                local nz = z + vector.z
                                local ndir = vector.d
                                -- print ("RECURSE NODE, NEXT: " .. nx .. "-" .. ny .. "-" .. nz .. "-" .. ndir)

                                traversePipes(nx, ny, nz, ndir, medium, amountPart)
                            else
                                -- print ("NO MORE WATER")
                            end
                        end
                    else
                        continue = false
                    end
                else
                    continue = false
                end
            else
                continue = false
            end
        elseif building then 
            -- will distribute equally water to all faucets in the building
            -- print ("(BUILDING) TRAVERSE:" .. traverseId .. " A:" .. amount)
            pipeTraversed[traverseId] = true
            WPVirtual.BuildingPourIn(x, y, z, building.bid, medium, amount)
        elseif barrel then
            -- will pour in a single watter container
            -- print ("(BARREL) TRAVERSE:" .. traverseId .. " A:" .. amount)
            pipeTraversed[traverseId] = true
            WPVirtual.BarrelPourIn(x, y, z, medium, amount)
        else
            continue = false
        end
    end
end

-- main
local function moveWater()
    if isClient() then return end

    local pumpFilterUsage = SandboxVars.Plumbing.PumpFilterUsage
    if not pumpFilterUsage then pumpFilterUsage = 0.007 end

    local pumpEfficiencyLoss = SandboxVars.Plumbing.PumpEfficiencyLoss
    if not pumpEfficiencyLoss then pumpEfficiencyLoss = 0.0012 end

    local pumpMaxWater = SandboxVars.Plumbing.PumpMaxWater
    if not pumpMaxWater then pumpMaxWater = 12 end

    local gmd = GetWPModData()

    -- pipes pass, reset water and medium
    for _, v in pairs(gmd.Pipes) do
        v.w = 0
        v.m = nil
    end

    -- sprinkler pass, reset virtual water so animation stops when pump is off
    for _, v in pairs(gmd.Sprinklers) do
        v.w = 0
    end

    -- flowmeter rest
    for _, v in pairs(gmd.Flowmeters) do
        v.f = 0
    end

    -- iso sync block start
    for _, barrel in pairs(gmd.Barrels) do
        WPIso.SyncBarrel(barrel)
    end

    for _, pump in pairs(gmd.Pumps) do
        WPIso.SyncPump(pump)
    end
    -- iso sync block end

    -- adjusting pump efficiency, filter degradation, emergency stop
    for _, pump in pairs(gmd.Pumps) do

        -- sanity
        if not pump.active then pump.active = false end
        if not pump.efficiency then pump.efficiency = 100 end
        if not pump.filter then pump.filter = 0 end

        -- if not pump.source then pump.active = false end

        if pump.active then
            -- usage logic
            pump.filter = pump.filter - pumpFilterUsage
            if pump.filter < 0 then pump.filter = 0 end

            pump.efficiency = pump.efficiency - pumpEfficiencyLoss
            if pump.efficiency < 0 then pump.efficiency = 0 end

            -- state logic
            if pump.efficiency == 0 then
                pump.active = false
            elseif pump.efficiency < 20 then
                local nbr = ZombRand(10 + pump.efficiency * 5)
                if nbr == 2 then
                    pump.active = false
                elseif nbr == 1 then
                    pump.burn = true
                end
            end
        end
    end

    -- virtual water moevement
    local wpActiveThisTick = false
    for _, pump in pairs(gmd.Pumps) do

        if pump.active and pump.source then
            wpActiveThisTick = true
            pipeTraversed = {}
            pipeTraversedValve = {}

            local amount = pumpMaxWater * pump.efficiency
            local medium = pump.source

            if pump.filter > 0 and medium == "TaintedWater" then
                medium = "Water"
            end

            local vectors = {
                ["w"] = {x=1, y=0, z=0},
                ["e"] = {x=-1, y=0, z=0},
                ["n"] = {x=0, y=1, z=0},
                ["s"] = {x=0, y=-1, z=0},
            }

            for dir, vector in pairs(vectors) do
                local x, y, z = pump.x + vector.x, pump.y + vector.y, pump.z + vector.z
                traversePipes(x, y, z, dir, medium, amount)
            end
        end
    end

    -- sprinkler watering
    local fs = SFarmingSystem and SFarmingSystem.instance
    for id, sprinkler in pairs(gmd.Sprinklers) do
        if sprinkler.w > 0 then
            if fs then
                local radius = 5
                for dx = -radius, radius do
                    for dy = -radius, radius do
                        if dx * dx + dy * dy <= radius * radius then
                            local plant = fs:getLuaObjectAt(sprinkler.x + dx, sprinkler.y + dy, sprinkler.z)
                            if plant and plant.waterNeeded and plant.waterNeeded > 0 and plant.waterLvl and plant.waterLvl < 100 then
                                plant.waterLvl = plant.waterLvl + 5.0
                                plant.lastWaterHour = fs.hoursElapsed
                                if plant.saveData then plant:saveData() end
                            end
                        end
                    end
                end
            end
            if not sprinkler.gen then sprinkler.gen = 0 end
            sprinkler.gen = sprinkler.gen + 1
        end
    end

    -- Only sync when the network is (or just was) moving water. Idle networks change
    -- nothing, so skipping the transmit avoids flooding the server with full-blob
    -- ModData packets every minute. The trailing tick guarantees clients receive the
    -- "stopped" state (flowmeter->0, sprinkler off) after the last active tick.
    if wpActiveThisTick or wpWasActiveLastTick then
        TransmitWPModData()
    end
    wpWasActiveLastTick = wpActiveThisTick
end

Events.EveryOneMinute.Add(moveWater)