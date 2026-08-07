-- Fuel piping for Waterpipes B42.
--
-- Waterpipes already tags a pump built next to a gas station with
-- pump.source == "Petrol" (WPIso.SyncPump), but nothing ever consumes that -
-- there's no generator hook, and its one barrel-sync path always adds real
-- Water fluid regardless of medium. Its actual traversal (traversePipes) is
-- a local in WPServer.lua so it can't be overridden, so this runs its own
-- parallel traversal over the same shared pipe graph (WPModData.Pipes) to
-- carry fuel instead, without touching the base mod's water/barrel state.
require "WPUtils"
require "PFA_GMD"
require "PFA_PipeMatrix"

local GEN_FUEL_MAX = 100.0

local pipeTraversed = {}
local pipeTraversedValve = {}
local pipeTraversedValveDepth = 0

local function hasClosedValve(sx, sy, sz, sdir, wgmd)
    local x, y, z, dir = sx, sy, sz, sdir
    local continue = true

    while continue do
        local traverseId = WPUtils.Coords2Id(x, y, z)

        if pipeTraversedValve[traverseId] ~= nil then return pipeTraversedValve[traverseId] end

        local pump = wgmd.Pumps[traverseId]
        if pump then
            pipeTraversedValve[traverseId] = true
            return true
        end

        local pipe = wgmd.Pipes[traverseId]
        if not pipe then
            pipeTraversedValve[traverseId] = false
            return false
        end

        local valve = wgmd.Valves[traverseId]
        if valve and valve.c then
            pipeTraversedValve[traverseId] = true
            return true
        end

        if pipeTraversedValveDepth > 10 then return true end

        local vectors = PFAGetVectors(pipe.s, dir)
        if #vectors > 1 then
            local allClosed = true
            for _, vector in ipairs(vectors) do
                local nx, ny, nz, ndir = x + vector.x, y + vector.y, z + vector.z, vector.d
                pipeTraversedValveDepth = pipeTraversedValveDepth + 1
                if not hasClosedValve(nx, ny, nz, ndir, wgmd) then
                    allClosed = false
                end
                pipeTraversedValveDepth = pipeTraversedValveDepth - 1
            end
            pipeTraversedValve[traverseId] = allClosed
            return allClosed
        end

        if #vectors == 0 then return false end

        local vector = vectors[1]
        x, y, z, dir = x + vector.x, y + vector.y, z + vector.z, vector.d
    end
end

local function eliminateClosedValveVectors(x, y, z, vectors, wgmd)
    local out = {}
    for _, vector in ipairs(vectors) do
        local nx, ny, nz, ndir = x + vector.x, y + vector.y, z + vector.z, vector.d
        if not hasClosedValve(nx, ny, nz, ndir, wgmd) then
            table.insert(out, vector)
        end
    end
    return out
end

local function iterObjectsOnSquare(square, fn)
    if not square then return end
    local objs = square:getObjects()
    for i = 0, objs:size() - 1 do fn(objs:get(i)) end
    local sobjs = square:getSpecialObjects()
    for i = 0, sobjs:size() - 1 do fn(sobjs:get(i)) end
end

local function getGeneratorOnSquare(square)
    local found = nil
    iterObjectsOnSquare(square, function(obj)
        if not found and obj and instanceof(obj, "IsoGenerator") then found = obj end
    end)
    return found
end

-- Waterpipes' own pump.source only ever gets set to "Petrol" next to a gas
-- station sprite (WPIso.SyncPump) - barrels are never a recognized source
-- there. This lets a pump adjacent to one of OUR virtual fuel barrels (filled
-- via the manual "Fill Barrel with Fuel" action) draw from it as a finite
-- source instead, same as the original B41 addon did. Prefers a barrel that
-- actually has fuel; falls back to an empty one so a pump stays "attached".
local function findAdjacentFuelBarrel(px, py, pz, pgmd)
    local coords = {
        {px - 1, py, pz},
        {px + 1, py, pz},
        {px, py - 1, pz},
        {px, py + 1, pz},
    }
    local fallback = nil
    for _, c in ipairs(coords) do
        local id = WPUtils.Coords2Id(c[1], c[2], c[3])
        local barrel = pgmd.FuelBarrels[id]
        if barrel and barrel.amount and barrel.amount > 0 then
            return barrel
        elseif barrel and not fallback then
            fallback = barrel
        end
    end
    return fallback
end

local function getGeneratorsAdjacentTo(x, y, z)
    local cell = getCell()
    local squares = {
        cell:getGridSquare(x, y, z),
        cell:getGridSquare(x - 1, y, z),
        cell:getGridSquare(x + 1, y, z),
        cell:getGridSquare(x, y - 1, z),
        cell:getGridSquare(x, y + 1, z),
    }
    local out = {}
    for _, sq in ipairs(squares) do
        local g = getGeneratorOnSquare(sq)
        if g then table.insert(out, g) end
    end
    return out
end

-- fuel amount is tracked in generator-percent-equivalent units, so 1 unit
-- delivered == 1% of a generator's tank, and barrels/cans (0-100 / 0-1) line up 1:1
local function fillGeneratorsAroundPipe(x, y, z, available)
    if available <= 0 then return 0 end
    local gens = getGeneratorsAdjacentTo(x, y, z)
    if #gens == 0 then return 0 end

    print("[PFA] found " .. #gens .. " generator(s) adjacent to pipe at " .. x .. "," .. y .. "," .. z .. " (available=" .. available .. ")")

    local used = 0
    for _, gen in ipairs(gens) do
        if available <= 0 then break end

        local cur = gen:getFuel() or 0
        if cur < 0 then cur = 0 end

        local missing = GEN_FUEL_MAX - cur
        if missing > 0 then
            local add = math.min(available, missing)
            gen:setFuel(math.min(GEN_FUEL_MAX, cur + add))
            gen:transmitModData()
            used = used + add
            available = available - add
            print("[PFA] generator fuel " .. cur .. " -> " .. gen:getFuel() .. " (added " .. add .. ")")
        end
    end
    return used
end

local function traverseFuel(sx, sy, sz, sdir, amount, wgmd, pgmd)
    local x, y, z, dir = sx, sy, sz, sdir
    local continue = true
    local used = 0

    while continue do
        local traverseId = WPUtils.Coords2Id(x, y, z)
        if pipeTraversed[traverseId] then return used end

        local pipe = wgmd.Pipes[traverseId]
        if not pipe then return used end

        pipeTraversed[traverseId] = true

        -- mark this pipe square as fuel-carrying this pass, so the manual
        -- "Fill Barrel with Fuel" action knows fuel is actually reaching it
        pgmd.FuelPipes[traverseId] = amount

        local genUsed = fillGeneratorsAroundPipe(x, y, z, amount)
        amount = amount - genUsed
        used = used + genUsed

        local valve = wgmd.Valves[traverseId]
        if valve and valve.c then return used end

        local vectors = PFAGetVectors(pipe.s, dir)
        if not vectors or #vectors == 0 then return used end

        if #vectors == 1 then
            local vector = vectors[1]
            x, y, z, dir = x + vector.x, y + vector.y, z + vector.z, vector.d
        else
            vectors = eliminateClosedValveVectors(x, y, z, vectors, wgmd)
            if #vectors == 0 then return used end

            local parts = WPUtils.SplitIntToParts(amount, #vectors)
            for k, vector in ipairs(vectors) do
                local part = parts[k]
                if part and part > 0 then
                    local nx, ny, nz, ndir = x + vector.x, y + vector.y, z + vector.z, vector.d
                    used = used + traverseFuel(nx, ny, nz, ndir, part, wgmd, pgmd)
                end
            end
            continue = false
        end
    end

    return used
end

local function moveFuel()
    if isClient() then return end

    local pumpMaxFuel = SandboxVars.Plumbing.FuelPumpMaxFuel
    if not pumpMaxFuel then pumpMaxFuel = 40 end

    local wgmd = GetWPModData()
    local pgmd = GetPFAModData()
    if not wgmd or not pgmd then return end

    pgmd.FuelPipes = {}

    for _, pump in pairs(wgmd.Pumps) do
        local barrelSource = nil
        if pump.source ~= "Petrol" then
            barrelSource = findAdjacentFuelBarrel(pump.x, pump.y, pump.z, pgmd)
        end

        if pump.active and (pump.source == "Petrol" or barrelSource) then
            pipeTraversed = {}
            pipeTraversedValve = {}

            local efficiency = pump.efficiency or 0
            local amount = pumpMaxFuel * efficiency / 100

            if barrelSource then
                amount = math.min(amount, barrelSource.amount)
            end

            print("[PFA] fuel pump active at " .. pump.x .. "," .. pump.y .. "," .. pump.z ..
                " source=" .. (barrelSource and "barrel" or "Petrol") .. " efficiency=" .. tostring(pump.efficiency) .. " amount=" .. amount)

            if amount > 0 then
                local vectors = {
                    {x = 1, y = 0, z = 0, d = "w"},
                    {x = -1, y = 0, z = 0, d = "e"},
                    {x = 0, y = 1, z = 0, d = "n"},
                    {x = 0, y = -1, z = 0, d = "s"},
                }
                local delivered = 0
                for _, vector in ipairs(vectors) do
                    delivered = delivered + traverseFuel(pump.x + vector.x, pump.y + vector.y, pump.z + vector.z, vector.d, amount, wgmd, pgmd)
                end

                if barrelSource and delivered > 0 then
                    barrelSource.amount = barrelSource.amount - delivered
                    if barrelSource.amount < 0 then barrelSource.amount = 0 end
                end
            end
        end
    end

    TransmitPFAModData()
end

Events.EveryOneMinute.Add(moveFuel)
