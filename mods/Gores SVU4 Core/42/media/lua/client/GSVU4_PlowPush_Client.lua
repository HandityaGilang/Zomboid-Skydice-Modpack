--========================================================
-- Gore's SVU4 Core - Defensive Plow client controller
-- Detects zombies in the blade sweep and applies/sends lateral displacement.
--========================================================

require "GoresSVU4Core/GSVU4_PlowPush"

local Plow = GSVU4 and GSVU4.PlowPush
if not Plow then return end

local recentZombie = {}
local lastScan = 0

local function isMPClient()
    return isClient and isClient() == true
end

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

local function objectKey(zombie)
    if zombie and zombie.getOnlineID then
        local ok, value = pcall(function() return zombie:getOnlineID() end)
        if ok and tonumber(value) and tonumber(value) >= 0 then return "online:" .. tostring(value) end
    end
    if zombie and zombie.getId then
        local ok, value = pcall(function() return zombie:getId() end)
        if ok and value ~= nil then return "id:" .. tostring(value) end
    end
    return tostring(zombie)
end

local function addZombieArgs(args, zombie)
    local onlineId = zombie.getOnlineID and zombie:getOnlineID() or nil
    args.zombieOnlineId = tonumber(onlineId) and tonumber(onlineId) >= 0 and onlineId or nil
    args.zombieObjectId = zombie.getId and zombie:getId() or nil
    args.zombieX = zombie:getX()
    args.zombieY = zombie:getY()
    args.zombieZ = zombie:getZ()
    return args
end

local function processZombie(vehicle, zombie, upgrade, cfg, now)
    if not Plow.isZombieAlive(zombie) then return end
    local key = objectKey(zombie)
    local cooldown = tonumber(cfg.pushCooldownMs) or 700
    if now - (tonumber(recentZombie[key]) or 0) < cooldown then return end
    local sweep = Plow.getSweepPosition(vehicle, zombie:getX(), zombie:getY(), cfg.widthScale)
    if not sweep then return end
    local power = Plow.getPower(vehicle, cfg)
    if power <= 0.05 then return end
    recentZombie[key] = now

    if isMPClient() then
        if not sendClientCommand then return end
        local args = Plow.addVehicleArgs({}, vehicle)
        addZombieArgs(args, zombie)
        args.speedKph = Plow.getSpeedKph(vehicle)
        args.impactVehicleX = vehicle:getX()
        args.impactVehicleY = vehicle:getY()
        args.impactVehicleZ = vehicle:getZ()
        local fx, fy = Plow.getForward2D(vehicle)
        args.impactForwardX = fx
        args.impactForwardY = fy
        args.side = sweep.side
        args.clientStamp = now
        sendClientCommand(Plow.Module, Plow.PushCommand, args)
    else
        local moved, strong = Plow.applyDisplacement(vehicle, zombie, cfg, nil, sweep.side)
        if moved then
            Plow.applyWear(vehicle, upgrade, cfg, strong)
        end
    end
end

local function scanZombies(vehicle, upgrade, cfg, now)
    if not getCell then return end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return end
    local cx = math.floor(vehicle:getX())
    local cy = math.floor(vehicle:getY())
    local cz = math.floor(vehicle:getZ())
    local seen = {}
    for dx = -3, 3 do
        for dy = -3, 3 do
            local square = cell:getGridSquare(cx + dx, cy + dy, cz)
            if square and square.getMovingObjects then
                local moving = square:getMovingObjects()
                for index = 0, listSize(moving) - 1 do
                    local zombie = listGet(moving, index)
                    if zombie and not seen[zombie] and Plow.isZombieAlive(zombie) then
                        seen[zombie] = true
                        processZombie(vehicle, zombie, upgrade, cfg, now)
                    end
                end
            end
        end
    end
end

local function prune(now)
    for key, stamp in pairs(recentZombie) do
        if now - (tonumber(stamp) or 0) > 5000 then recentZombie[key] = nil end
    end
end

local function onPlayerUpdate(player)
    if not player or not player.isLocalPlayer or not player:isLocalPlayer() then return end
    local vehicle = player.getVehicle and player:getVehicle() or nil
    if not vehicle then return end
    if vehicle.getDriver then
        local ok, driver = pcall(function() return vehicle:getDriver() end)
        if ok and driver ~= player then return end
    end
    local upgrade, cfg = Plow.getFunctional(vehicle)
    if not upgrade or not cfg then return end
    if not Plow.isMovingForward(vehicle) then return end
    if Plow.getSpeedKph(vehicle) < (tonumber(cfg.minPushKph) or 10) then return end

    local now = Plow.nowMs()
    if now - lastScan < (Plow.ScanIntervalMs or 50) then return end
    lastScan = now
    scanZombies(vehicle, upgrade, cfg, now)
    if now % 5000 < 100 then prune(now) end
end

local function onServerCommand(module, command, args)
    if module ~= Plow.Module or command ~= Plow.ResultCommand or not args then return end
    local player = getPlayer and getPlayer() or nil
    local vehicle = player and player.getVehicle and player:getVehicle() or nil
    if not vehicle or not Plow.vehicleMatchesArgs(vehicle, args) then return end
    local upgrade = Plow.getInstalled(vehicle)
    if upgrade and args.health ~= nil then
        upgrade.health = tonumber(args.health) or upgrade.health
        upgrade.wearRemainder = tonumber(args.wearRemainder) or upgrade.wearRemainder
    end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
if Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
