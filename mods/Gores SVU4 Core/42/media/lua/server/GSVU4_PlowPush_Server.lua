--========================================================
-- Gore's SVU4 Core - Defensive Plow server resolver
-- Server-authoritative lateral zombie displacement and plow wear.
--========================================================

if isClient and isClient() then return end
require "GoresSVU4Core/GSVU4_PlowPush"

local Plow = GSVU4 and GSVU4.PlowPush
if not Plow then return end
local cooldowns = {}

local function listSize(list)
    if not list then return 0 end
    if type(list) == "table" then return #list end
    if list.size then
        local ok, count = pcall(function() return list:size() end)
        if ok then return tonumber(count) or 0 end
    end
    return 0
end

local function listGet(list, index)
    if not list then return nil end
    if type(list) == "table" then return list[index + 1] end
    if list.get then
        local ok, value = pcall(function() return list:get(index) end)
        if ok then return value end
    end
    return nil
end

local function isDriver(player, vehicle)
    if not player or not vehicle then return false end
    if not player.getVehicle or player:getVehicle() ~= vehicle then return false end
    if vehicle.getDriver then
        local ok, driver = pcall(function() return vehicle:getDriver() end)
        if ok and driver ~= player then return false end
    end
    return true
end

local function findVehicle(player, args)
    local vehicle = player and player.getVehicle and player:getVehicle() or nil
    if vehicle and Plow.vehicleMatchesArgs(vehicle, args) and isDriver(player, vehicle) then return vehicle end
    return nil
end

local function findZombie(args)
    if not args or not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return nil end
    local wantedOnline = tonumber(args.zombieOnlineId)
    local wantedObject = args.zombieObjectId ~= nil and tostring(args.zombieObjectId) or nil
    local best, bestDistance = nil, math.huge
    local cx, cy, cz = math.floor(tonumber(args.zombieX) or 0), math.floor(tonumber(args.zombieY) or 0), math.floor(tonumber(args.zombieZ) or 0)
    for dx = -3, 3 do
        for dy = -3, 3 do
            local square = cell:getGridSquare(cx + dx, cy + dy, cz)
            if square and square.getMovingObjects then
                local moving = square:getMovingObjects()
                for index = 0, listSize(moving) - 1 do
                    local zombie = listGet(moving, index)
                    if Plow.isZombieAlive(zombie) then
                        if wantedOnline and wantedOnline >= 0 and zombie.getOnlineID then
                            local ok, value = pcall(function() return zombie:getOnlineID() end)
                            if ok and tonumber(value) == wantedOnline then return zombie end
                        end
                        if wantedObject and zombie.getId then
                            local ok, value = pcall(function() return zombie:getId() end)
                            if ok and tostring(value) == wantedObject then return zombie end
                        end
                        local zx, zy = tonumber(zombie:getX()) or 0, tonumber(zombie:getY()) or 0
                        local ddx, ddy = zx - (tonumber(args.zombieX) or 0), zy - (tonumber(args.zombieY) or 0)
                        local distance = ddx * ddx + ddy * ddy
                        if distance < bestDistance and distance <= 4 then
                            best, bestDistance = zombie, distance
                        end
                    end
                end
            end
        end
    end
    return best
end

local function zombieKey(zombie, args)
    if zombie and zombie.getOnlineID then
        local ok, value = pcall(function() return zombie:getOnlineID() end)
        if ok and tonumber(value) and tonumber(value) >= 0 then return "online:" .. tostring(value) end
    end
    if zombie and zombie.getId then
        local ok, value = pcall(function() return zombie:getId() end)
        if ok and value ~= nil then return "id:" .. tostring(value) end
    end
    return "xy:" .. tostring(args.zombieX) .. ":" .. tostring(args.zombieY)
end

local function sendResult(player, vehicle, upgrade)
    if not player or not sendServerCommand then return end
    local args = Plow.addVehicleArgs({}, vehicle)
    args.health = tonumber(upgrade.health) or 0
    args.wearRemainder = tonumber(upgrade.wearRemainder) or 0
    sendServerCommand(player, Plow.Module, Plow.ResultCommand, args)
end

local function handlePush(player, args)
    local vehicle = findVehicle(player, args)
    if not vehicle then return end
    local upgrade, cfg = Plow.getFunctional(vehicle)
    if not upgrade or not cfg then return end
    local speed = math.abs(tonumber(args and args.speedKph) or 0)
    if speed < (tonumber(cfg.minPushKph) or 10) then return end
    if args and args.impactVehicleX and vehicle.getX then
        local dx = (tonumber(vehicle:getX()) or 0) - (tonumber(args.impactVehicleX) or 0)
        local dy = (tonumber(vehicle:getY()) or 0) - (tonumber(args.impactVehicleY) or 0)
        if dx * dx + dy * dy > 100 then return end
    end
    local zombie = findZombie(args)
    if not zombie then return end
    local sweep = Plow.getSweepPosition(
        vehicle,
        zombie:getX(), zombie:getY(), cfg.widthScale,
        args.impactVehicleX, args.impactVehicleY,
        args.impactForwardX, args.impactForwardY
    )
    if not sweep then return end
    local key = tostring(vehicle) .. ":" .. zombieKey(zombie, args)
    local now = Plow.nowMs()
    local cooldown = tonumber(cfg.pushCooldownMs) or 700
    if now - (tonumber(cooldowns[key]) or 0) < cooldown then return end
    cooldowns[key] = now

    local moved, strong, power = Plow.applyDisplacement(vehicle, zombie, cfg, speed, sweep.side)
    if not moved then return end
    Plow.applyWear(vehicle, upgrade, cfg, strong)
    sendResult(player, vehicle, upgrade)
end

local function onClientCommand(module, command, player, args)
    if module == Plow.Module and command == Plow.PushCommand then handlePush(player, args) end
end

Events.OnClientCommand.Add(onClientCommand)
