-- Gore's SVU4 Core - Filtered Air Intake client protection

require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "GoresSVU4Core/GSVU4_FilteredAirIntake"

local M = GSVU4FilteredAirIntake
if not M then return end

local PlayerState = setmetatable({}, { __mode = "k" })
local RuntimeByVehicle = setmetatable({}, { __mode = "k" })
local RuntimeByVehicleKey = {}

local function safeCall(fn, default)
    local ok, value = pcall(fn)
    if ok then return value end
    return default
end

local MethodCache = setmetatable({}, { __mode = "k" })

local function getMethod(object, methodName)
    if not object then return nil end
    local cache = MethodCache[object]
    if not cache then
        cache = {}
        MethodCache[object] = cache
    end
    if cache[methodName] ~= nil then
        return cache[methodName] or nil
    end

    local ok, method = pcall(function() return object[methodName] end)
    if not ok or type(method) ~= "function" then
        cache[methodName] = false
        return nil
    end
    cache[methodName] = method
    return method
end

local function callMethod(object, methodName, default, ...)
    local method = getMethod(object, methodName)
    if not method then return default end
    local args = { ... }
    local ok, value = pcall(function() return method(object, unpack(args)) end)
    if ok then return value end
    return default
end

local function nowMs()
    if getTimestampMs then
        local value = safeCall(function() return getTimestampMs() end, nil)
        if value ~= nil then return tonumber(value) or 0 end
    end
    return os.time() * 1000
end

local function worldAgeHours()
    if getGameTime then
        local gameTime = safeCall(function() return getGameTime() end, nil)
        if gameTime then
            local value = safeCall(function() return gameTime:getWorldAgeHours() end, nil)
            if value ~= nil then return tonumber(value) or 0 end
        end
    end
    return 0
end

local function resolvePlayer(player)
    if player and getMethod(player, "getVehicle") then return player end
    if getPlayer then return safeCall(function() return getPlayer() end, nil) end
    return nil
end

local function getVehicle(player)
    return callMethod(player, "getVehicle", nil)
end

local function vehicleKey(vehicle)
    if not vehicle then return nil end
    local onlineId = tonumber(callMethod(vehicle, "getOnlineID", nil))
    if onlineId and onlineId >= 0 then return "online:" .. tostring(math.floor(onlineId)) end

    local id = callMethod(vehicle, "getId", nil)
    if id ~= nil then return "id:" .. tostring(id) end
    return tostring(vehicle)
end

local function storeRuntime(vehicle, runtime)
    if not vehicle or not runtime then return end
    RuntimeByVehicle[vehicle] = runtime
    local key = vehicleKey(vehicle)
    if key then RuntimeByVehicleKey[key] = runtime end
end

function M.clearRuntimeStatus(vehicle)
    if not vehicle then return end
    RuntimeByVehicle[vehicle] = nil
    local key = vehicleKey(vehicle)
    if key then RuntimeByVehicleKey[key] = nil end
end

function M.getRuntimeStatus(vehicle)
    if not vehicle then return nil end
    local installed = M.getInstalled(vehicle)
    if not installed then
        M.clearRuntimeStatus(vehicle)
        return nil
    end

    local runtime = RuntimeByVehicle[vehicle]
    if not runtime then
        local key = vehicleKey(vehicle)
        runtime = key and RuntimeByVehicleKey[key] or nil
    end

    if runtime and runtime.upgradeRef ~= installed then
        M.clearRuntimeStatus(vehicle)
        return nil
    end
    return runtime
end

local FliesSoundClass = nil
local FliesSoundResolveAttempted = false

local function getFliesSoundInstance()
    local direct = rawget(_G, "FliesSound")
    if direct and direct.instance then return direct.instance end

    if not FliesSoundResolveAttempted then
        FliesSoundResolveAttempted = true
        local bridge = rawget(_G, "luajava")
        if bridge and bridge.bindClass then
            FliesSoundClass = safeCall(function() return bridge.bindClass("zombie.FliesSound") end, nil)
        end
    end

    return FliesSoundClass and FliesSoundClass.instance or nil
end

local function getEngineCorpseCount(player)
    local instance = getFliesSoundInstance()
    if not instance then return nil end
    local value = tonumber(safeCall(function() return instance:getCorpseCount(player) end, nil))
    if value == nil then return nil end
    return math.max(0, math.floor(value + 0.5))
end

local function isDeadBody(obj)
    if not obj then return false end
    if instanceof then
        local value = safeCall(function() return instanceof(obj, "IsoDeadBody") end, false)
        if value == true then return true end
    end
    local objectName = safeCall(function() return obj:getObjectName() end, nil)
    if objectName then
        local low = string.lower(tostring(objectName))
        if low:find("deadbody", 1, true) or low:find("dead body", 1, true) or low:find("corpse", 1, true) then
            return true
        end
    end
    return tostring(obj):find("IsoDeadBody", 1, true) ~= nil
end

local function addBody(out, seen, obj, stopAt)
    if not obj or seen[obj] or not isDeadBody(obj) then return false end
    seen[obj] = true
    out.count = out.count + 1
    return out.count >= stopAt
end

local function countBodyList(list, out, seen, stopAt)
    if not list then return false end
    local size = tonumber(safeCall(function() return list:size() end, nil))
    if not size then return false end
    for i = 0, size - 1 do
        local obj = safeCall(function() return list:get(i) end, nil)
        if obj and addBody(out, seen, obj, stopAt) then return true end
    end
    return false
end

local function countBodiesOnSquare(square, stopAt)
    local out, seen = { count = 0 }, {}
    if not square then return 0 end

    local deadBodies = safeCall(function() return square:getDeadBodys() end, nil)
    if countBodyList(deadBodies, out, seen, stopAt) then return out.count end

    local deadBody = safeCall(function() return square:getDeadBody() end, nil)
    if addBody(out, seen, deadBody, stopAt) then return out.count end

    local staticObjects = safeCall(function() return square:getStaticMovingObjects() end, nil)
    if countBodyList(staticObjects, out, seen, stopAt) then return out.count end

    local objects = safeCall(function() return square:getObjects() end, nil)
    countBodyList(objects, out, seen, stopAt)
    return out.count
end

local function hasCorpseExposure(player, threshold)
    threshold = math.max(1, math.floor(tonumber(threshold) or 1))

    local engineCount = getEngineCorpseCount(player)
    if engineCount ~= nil and engineCount >= threshold then
        return true
    end

    local square = safeCall(function() return player:getSquare() end, nil)
    local cell = getCell and safeCall(function() return getCell() end, nil) or nil
    if not square or not cell then return false end

    local sx = tonumber(safeCall(function() return square:getX() end, nil))
    local sy = tonumber(safeCall(function() return square:getY() end, nil))
    local sz = tonumber(safeCall(function() return square:getZ() end, nil))
    if sx == nil or sy == nil or sz == nil then return false end

    local radius = 13
    local total = 0
    for dx = -radius, radius do
        for dy = -radius, radius do
            local sq = safeCall(function() return cell:getGridSquare(sx + dx, sy + dy, sz) end, nil)
            if sq then
                total = total + countBodiesOnSquare(sq, threshold - total)
                if total >= threshold then return true end
            end
        end
    end
    return false
end

local function getHealthChannels(player)
    local body = callMethod(player, "getBodyDamage", nil)
    local foodSickness = tonumber(callMethod(body, "getFoodSicknessLevel", nil))

    local stats = callMethod(player, "getStats", nil)
    local statsSickness = tonumber(callMethod(stats, "getSickness", nil))

    return body, foodSickness, stats, statsSickness
end

local function setFoodSickness(body, value)
    if value == nil then return false end
    return callMethod(body, "setFoodSicknessLevel", false, value) ~= false
end

local function setStatsSickness(stats, value)
    if value == nil then return false end
    return callMethod(stats, "setSickness", false, value) ~= false
end

local function addVehicleArgs(vehicle, args)
    args = args or {}
    args.vehicleId = callMethod(vehicle, "getId", nil)
    args.vehicleOnlineId = callMethod(vehicle, "getOnlineID", nil)
    args.vehicleX = callMethod(vehicle, "getX", nil)
    args.vehicleY = callMethod(vehicle, "getY", nil)
    args.vehicleZ = callMethod(vehicle, "getZ", nil)
    return args
end

local function drainCapacity(vehicle, amount)
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    local upgrade = M.getInstalled(vehicle)
    if not upgrade then return end
    local current = tonumber(upgrade.filterCapacity) or M.getGradeCapacity(upgrade.grade)
    local updated = math.max(0, current - amount)
    if updated == current then return end

    upgrade.filterCapacity = updated
    if isClient and isClient() and sendClientCommand then
        sendClientCommand("GoresSVU4Core", "DrainFilteredAirIntake", addVehicleArgs(vehicle, { amount = amount }))
    elseif vehicle then
        callMethod(vehicle, "transmitModData", nil)
    end
end

local function isDriverOwner(vehicle, player)
    local isDriverValue = callMethod(vehicle, "isDriver", nil, player)
    if isDriverValue == nil then return true end
    return isDriverValue == true
end

local function resetPlayerState(state, foodSickness, statsSickness, age)
    state.vehicle = nil
    state.upgradeRef = nil
    state.previousFoodSickness = foodSickness
    state.previousStatsSickness = statsSickness
    state.lastScanWorldAge = age
    state.drainRemainder = 0
    state.nextScan = 0
end

local function evaluateProtectionRuntime(player, vehicle)
    local status = M.getStatus(vehicle)
    local exposed = false
    if status and status.active then
        exposed = hasCorpseExposure(player, M.CORPSE_THRESHOLD or 5)
    end

    local runtime = {
        active = status and status.active == true and exposed,
        exposed = exposed == true,
        capacity = status and tonumber(status.capacity) or 0,
        checkedAt = nowMs(),
        upgradeRef = M.getInstalled(vehicle),
    }
    storeRuntime(vehicle, runtime)
    return runtime, status
end

function M.refreshProtectionRuntime(player, vehicle)
    player = resolvePlayer(player)
    if not player then return nil end
    vehicle = vehicle or getVehicle(player)
    if not vehicle then return nil end
    if getVehicle(player) ~= vehicle then
        M.clearRuntimeStatus(vehicle)
        return nil
    end

    local state = PlayerState[player] or {}
    PlayerState[player] = state
    local age = worldAgeHours()
    local installed = M.getInstalled(vehicle)

    if state.vehicle ~= vehicle or state.upgradeRef ~= installed then
        state.vehicle = vehicle
        state.upgradeRef = installed
        state.previousFoodSickness = nil
        state.previousStatsSickness = nil
    end

    state.lastScanWorldAge = age
    state.drainRemainder = 0
    state.nextScan = nowMs() + 1000
    M.clearRuntimeStatus(vehicle)

    local runtime = evaluateProtectionRuntime(player, vehicle)
    return runtime
end

local function updatePlayer(eventPlayer)
    local player = resolvePlayer(eventPlayer)
    if not player then return end

    local state = PlayerState[player] or {}
    PlayerState[player] = state

    local now = nowMs()
    local age = worldAgeHours()
    local vehicle = getVehicle(player)

    if not vehicle then
        resetPlayerState(state, nil, nil, age)
        return
    end

    local body, foodSickness, stats, statsSickness = getHealthChannels(player)
    local installed = M.getInstalled(vehicle)

    if state.vehicle ~= vehicle or state.upgradeRef ~= installed then
        state.vehicle = vehicle
        state.upgradeRef = installed
        state.previousFoodSickness = foodSickness
        state.previousStatsSickness = statsSickness
        state.lastScanWorldAge = age
        state.drainRemainder = 0
        state.nextScan = 0
        M.clearRuntimeStatus(vehicle)
    end

    if not state.nextScan or now >= state.nextScan then
        state.nextScan = now + 1000

        local runtime = evaluateProtectionRuntime(player, vehicle)

        local elapsedMinutes = 0
        if state.lastScanWorldAge then elapsedMinutes = math.max(0, (age - state.lastScanWorldAge) * 60) end
        state.lastScanWorldAge = age

        if runtime.active and isDriverOwner(vehicle, player) then
            state.drainRemainder = (tonumber(state.drainRemainder) or 0) + elapsedMinutes
            local whole = math.floor(state.drainRemainder)
            if whole > 0 then
                local sent = math.min(whole, 5)
                state.drainRemainder = state.drainRemainder - sent
                drainCapacity(vehicle, sent)
            end
        else
            state.drainRemainder = 0
        end
    end

    local runtime = M.getRuntimeStatus(vehicle)
    if runtime and runtime.active then
        local previousFood = tonumber(state.previousFoodSickness)
        if foodSickness ~= nil and previousFood ~= nil and foodSickness > previousFood + 0.0001 then
            if setFoodSickness(body, previousFood) then foodSickness = previousFood end
        end

        local previousStats = tonumber(state.previousStatsSickness)
        if statsSickness ~= nil and previousStats ~= nil and statsSickness > previousStats + 0.0001 then
            if setStatsSickness(stats, previousStats) then statsSickness = previousStats end
        end
    end

    state.previousFoodSickness = foodSickness
    state.previousStatsSickness = statsSickness
end

Events.OnPlayerUpdate.Add(updatePlayer)
