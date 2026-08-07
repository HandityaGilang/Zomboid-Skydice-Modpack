
local PUMP_POS = {
    ["location_shop_fossoil_01_12"] = 0,
    ["location_shop_fossoil_01_13"] = 1,
    ["location_shop_fossoil_01_14"] = 2,
    ["location_shop_fossoil_01_15"] = 3,
    ["location_shop_gas2go_01_12"]  = 0,
    ["location_shop_gas2go_01_13"]  = 1,
    ["location_shop_gas2go_01_14"]  = 2,
    ["location_shop_gas2go_01_15"]  = 3,
}

local STATE_NONE, STATE_GREEN, STATE_RED = 0, 1, 2

local DIAG = false
local DIAG_STATE_NAMES = {[STATE_NONE] = "NONE", [STATE_GREEN] = "GREEN", [STATE_RED] = "RED"}

local NIGHT_THRESHOLD = 0.5

local function overlaySpriteName(pos, state, night)
    local colorIdx = (state == STATE_GREEN) and 0 or 1
    local idx = colorIdx * 4 + pos
    if night then idx = idx + 8 end
    return "gas_pump_indicator_01_" .. idx
end

local PAIR_BLOCK = {
    ["3:2:1:0"]  = 0,
    ["2:3:-1:0"] = 1,
    ["2:3:1:0"]  = 2,
    ["3:2:-1:0"] = 3,
    ["0:1:0:1"]  = 4,
    ["1:0:0:-1"] = 5,
    ["1:0:0:1"]  = 6,
    ["0:1:0:-1"] = 7,
}

local function pairSpriteName(block, ownState, nbrState, night)
    local cc = ((ownState == STATE_RED) and 2 or 0) + ((nbrState == STATE_RED) and 1 or 0)
    local idx = 16 + block * 8 + cc * 2 + (night and 1 or 0)
    return "gas_pump_indicator_01_" .. idx
end

local function pumpAmount(pump)
    if isClient() then
        if SandboxVars.FuelStationGasInfinite then return 1000 end
        local amount = pump:getModData().fuelAmount
        if type(amount) ~= "number" then return nil end
        return amount
    end
    local amount = pump:getPipedFuelAmount()
    if amount < 0 then return nil end
    return amount
end

local function pumpState(square, pump)
    local hasPower = square:haveElectricity() or pump:hasGridPower()
    if not hasPower then return STATE_NONE end
    local anyPositive, anyZero = false, false
    local objs = square:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local sp = o:getSprite()
        if sp and PUMP_POS[sp:getName()] then
            local amount = pumpAmount(o)
            if amount then
                if amount > 0 then anyPositive = true else anyZero = true end
            end
        end
    end
    if anyPositive then return STATE_GREEN end
    if anyZero then return STATE_RED end
    return STATE_NONE
end


local spriteCache = {}
local function modSprite(name, unlit)
    local spr = spriteCache[name]
    if spr == nil then
        spr = IsoSpriteManager.instance:getSprite(name)
        if unlit then
            spr:getProperties():set(IsoFlagType.unlit)
        end
        spriteCache[name] = spr
    end
    return spr
end

local BLOCKER_NAME = "gas_pump_indicator_blocker"
local blockerSpr = nil
local blockerSupported = nil

local diagPlugLast = {}
local function diagPlug(obj, outcome)
    if not DIAG then return end
    pcall(function()
        local sq = obj:getSquare()
        local k = sq and (sq:getX() .. "," .. sq:getY()) or "?"
        local name = obj:getSprite() and obj:getSprite():getName() or "?"
        k = k .. ":" .. tostring(name)
        if diagPlugLast[k] ~= outcome then
            diagPlugLast[k] = outcome
            print("[GasPumpIndicator] DIAG plug " .. k .. " -> " .. outcome)
        end
    end)
end

local function ensurePlugged(obj)
    if blockerSupported == false then return end
    local ov = obj:getOnOverlay()
    if ov ~= nil then
        local ours = false
        pcall(function() ours = (blockerSpr ~= nil and ov:getParentSprite() == blockerSpr) end)
        if ours then
            diagPlug(obj, "ours-already")
            return
        end
        if not pcall(function() obj:clearOnOverlay() end) then
            diagPlug(obj, "evict-FAILED")
            return
        end
        diagPlug(obj, "evicted-foreign")
    else
        diagPlug(obj, "slot-was-empty")
    end
    local ok = pcall(function()
        if blockerSpr == nil then
            blockerSpr = IsoSpriteManager.instance:getSprite(BLOCKER_NAME)
        end
        obj:setOnOverlay(IsoSpriteInstance.get(blockerSpr))
    end)
    if not ok then
        blockerSupported = false
        print("[GasPumpIndicator] on-overlay plug unavailable (vanilla night patch may show)")
        return
    end
    blockerSupported = true
end

local function invalidateChunk(obj)
    pcall(function() obj:invalidateRenderChunkLevel(1024) end)
end

local function applyChannels(square, name, night)
    if name then
        pcall(modSprite, name, night)
    end
    local objs = square:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local sp = o:getSprite()
        if sp and PUMP_POS[sp:getName()] then
            pcall(function() o:setOverlaySprite(name, false) end)
            ensurePlugged(o)
        end
    end
    return name
end


local trackedCoords = {}
local function coordKey(x, y, z) return x .. "," .. y .. "," .. z end

local function findPumpAt(cell, x, y, z)
    local sq = cell:getGridSquare(x, y, z)
    if not sq then return nil, nil, nil end
    local objs = sq:getObjects()
    local pump, pumpPos = nil, nil
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local sp = o:getSprite()
        if sp then
            local pos = PUMP_POS[sp:getName()]
            if pos then
                pump, pumpPos = o, pos
            end
        end
    end
    return pump, pumpPos, sq
end

local PAIR_DIRS = { {1, 0}, {-1, 0}, {0, 1}, {0, -1} }
local function findPairNeighbor(cell, x, y, z, ownPos)
    for i = 1, 4 do
        local dx, dy = PAIR_DIRS[i][1], PAIR_DIRS[i][2]
        local pump, pos, sq = findPumpAt(cell, x + dx, y + dy, z)
        if pump then
            local block = PAIR_BLOCK[ownPos .. ":" .. pos .. ":" .. dx .. ":" .. dy]
            if block then
                return block, pump, sq
            end
        end
    end
    return nil
end

local function registerSquare(square)
    if not square then return end
    local objs = square:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        local sp = o:getSprite()
        if sp then
            local pos = PUMP_POS[sp:getName()]
            if pos then
                local k = coordKey(o:getX(), o:getY(), o:getZ())
                if trackedCoords[k] == nil then
                    trackedCoords[k] = {x = o:getX(), y = o:getY(), z = o:getZ(), pos = pos}
                    if DIAG then
                        local parts = {}
                        for j = 0, objs:size() - 1 do
                            local oo = objs:get(j)
                            local ssp = oo:getSprite()
                            parts[#parts + 1] = j .. "=" .. tostring(ssp and ssp:getName() or "?")
                        end
                        print("[GasPumpIndicator] DIAG track " .. k .. " pos=" .. pos
                            .. " objs[" .. table.concat(parts, " | ") .. "]")
                    end
                end
            end
        end
    end
end

local function onLoadGridsquare(square)
    registerSquare(square)
end

local TICK_INTERVAL = 6
local tickCounter = 0

local SCAN_TICK_INTERVAL = 150
local scanCounter = 0
local SCAN_RADIUS = 16

local function boxScanAroundPlayer()
    local player = getPlayer()
    if not player then return end
    local cell = getCell()
    if not cell then return end
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    for dx = -SCAN_RADIUS, SCAN_RADIUS do
        for dy = -SCAN_RADIUS, SCAN_RADIUS do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then registerSquare(sq) end
        end
    end
end

local lightOnStripped = false
local function stripLightOnFlag()
    if lightOnStripped then return end
    lightOnStripped = true
    for name in pairs(PUMP_POS) do
        pcall(function()
            local spr = IsoSpriteManager.instance:getSprite(name)
            if spr then
                spr:getProperties():unset(IsoFlagType.HasLightOnSprite)
            end
        end)
    end
    if DIAG then
        print("[GasPumpIndicator] DIAG stripped HasLightOnSprite from pump sprites")
    end
end

local function onTick()
    stripLightOnFlag()
    tickCounter = tickCounter + 1
    scanCounter = scanCounter + 1

    if scanCounter >= SCAN_TICK_INTERVAL then
        scanCounter = 0
        boxScanAroundPlayer()
    end

    if tickCounter < TICK_INTERVAL then return end
    tickCounter = 0

    local cell = getCell()
    if not cell then return end

    local night = false
    pcall(function() night = getClimateManager():getNightStrength() > NIGHT_THRESHOLD end)

    for k, entry in pairs(trackedCoords) do
        local pump, pos, sq = findPumpAt(cell, entry.x, entry.y, entry.z)
        if pump then
            local state = pumpState(sq, pump)
            local name = nil
            if state ~= STATE_NONE then
                local block, nbrPump, nbrSq = findPairNeighbor(cell, entry.x, entry.y, entry.z, pos or entry.pos)
                if block then
                    local nbrState = pumpState(nbrSq, nbrPump)
                    if nbrState ~= STATE_NONE then
                        name = pairSpriteName(block, state, nbrState, night)
                    end
                end
                if name == nil then
                    name = overlaySpriteName(pos or entry.pos, state, night)
                end
            end
            applyChannels(sq, name, night)
            if name ~= entry.lastName then
                entry.lastName = name
                invalidateChunk(pump)
            end
            if DIAG and state ~= entry.lastState then
                print("[GasPumpIndicator] DIAG change " .. k .. " state="
                    .. (DIAG_STATE_NAMES[state] or tostring(state))
                    .. " overlay=" .. tostring(name) .. " pos=" .. tostring(pos or entry.pos))
            end
            entry.lastState = state
        end
    end
end

Events.LoadGridsquare.Add(onLoadGridsquare)
Events.OnTick.Add(onTick)
