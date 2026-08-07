--========================================================
-- Gore's SVU4 Core - Offensive Bullbar Server Resolver
-- Server-authoritative zombie guarantees, vehicle bonus damage and front-condition integrity wear.
--========================================================

if isClient and isClient() then return end

require "GoresSVU4Core/GSVU4_BullBarImpact"

local Impact = GSVU4 and GSVU4.BullBarImpact
if not Impact then return end

local collisionCooldown = {}
local frontDamageLast = {}

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
    if player.getVehicle and player:getVehicle() ~= vehicle then return false end
    if vehicle.getDriver then
        local ok, driver = pcall(function() return vehicle:getDriver() end)
        if ok and driver ~= player then return false end
    end
    return true
end

local function getAttacker(player, args)
    if not player or not player.getVehicle then return nil end
    local vehicle = player:getVehicle()
    if vehicle and Impact.vehicleMatchesArgs(vehicle, args, "vehicle") and isDriver(player, vehicle) then
        return vehicle
    end
    return nil
end

local function nearbySquareObjects(x, y, z, radius, callback)
    if not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return nil end
    x, y, z = math.floor(tonumber(x) or 0), math.floor(tonumber(y) or 0), math.floor(tonumber(z) or 0)
    for dx = -radius, radius do
        for dy = -radius, radius do
            local square = cell:getGridSquare(x + dx, y + dy, z)
            if square and square.getMovingObjects then
                local moving = square:getMovingObjects()
                for i = 0, listSize(moving) - 1 do
                    local obj = listGet(moving, i)
                    if callback(obj) then return obj end
                end
            end
        end
    end
    return nil
end

local function findZombie(args)
    if not args then return nil end
    local wanted = tonumber(args.zombieOnlineId)
    local wantedObjectId = args.zombieObjectId ~= nil and tostring(args.zombieObjectId) or nil
    local useOnlineId = Impact.isValidOnlineId(wanted)
    local best, bestDistance = nil, math.huge
    nearbySquareObjects(args.zombieX, args.zombieY, args.zombieZ, 3, function(obj)
        if not obj or not obj.isZombie then return false end
        local okZombie, zombie = pcall(function() return obj:isZombie() end)
        if not okZombie or zombie ~= true then return false end
        if useOnlineId and obj.getOnlineID then
            local okId, onlineId = pcall(function() return obj:getOnlineID() end)
            if okId and tonumber(onlineId) == wanted then best = obj return true end
            return false
        end
        if wantedObjectId and obj.getId then
            local okId, objectId = pcall(function() return obj:getId() end)
            if okId and tostring(objectId) == wantedObjectId then best = obj return true end
        end
        local dx = (tonumber(obj:getX()) or 0) - (tonumber(args.zombieX) or 0)
        local dy = (tonumber(obj:getY()) or 0) - (tonumber(args.zombieY) or 0)
        local distance = dx * dx + dy * dy
        if distance < bestDistance and distance <= 4.0 then
            best, bestDistance = obj, distance
        end
        return false
    end)
    return best
end

local function findTargetVehicle(args, attacker)
    if not args then return nil end
    local target = nearbySquareObjects(args.targetX, args.targetY, args.targetZ, 4, function(obj)
        return obj ~= attacker and obj and obj.getModData and obj.getPartById
            and Impact.vehicleMatchesArgs(obj, args, "target")
    end)
    if target then return target end

    if getCell then
        local cell = getCell()
        if cell and cell.getVehicles then
            local ok, vehicles = pcall(function() return cell:getVehicles() end)
            if ok and vehicles then
                for i = 0, listSize(vehicles) - 1 do
                    local vehicle = listGet(vehicles, i)
                    if vehicle ~= attacker and Impact.vehicleMatchesArgs(vehicle, args, "target") then return vehicle end
                end
            end
        end
    end
    return nil
end

local function cooldownKey(attacker, targetType, targetKey)
    return Impact.getVehicleKey(attacker) .. ":" .. targetType .. ":" .. tostring(targetKey)
end

local function claimCooldown(key, durationMs)
    local now = Impact.nowMs()
    local previous = tonumber(collisionCooldown[key]) or 0
    if now - previous < durationMs then return false end
    collisionCooldown[key] = now
    return true
end

local function transmitBullbar(vehicle, player, upgrade, oldHealth, wear, kind)
    if vehicle and vehicle.transmitModData then vehicle:transmitModData() end
    local newHealth = tonumber(upgrade and upgrade.health) or 0
    if sendServerCommand and player then
        local args = Impact.addVehicleArgs({}, vehicle, "vehicle")
        args.destroyed = oldHealth > 0 and newHealth <= 0
        args.health = newHealth
        args.oldHealth = oldHealth
        args.wear = wear
        args.kind = kind
        sendServerCommand(player, Impact.Module, Impact.ResultCommand, args)
    end
end

local function applyBullbarWear(vehicle, player, upgrade, amount, kind)
    local oldHealth = tonumber(upgrade.health) or 100
    amount = math.max(0, math.floor((tonumber(amount) or 0) + 0.5))
    if amount <= 0 then return oldHealth end
    upgrade.health = math.max(0, oldHealth - amount)
    transmitBullbar(vehicle, player, upgrade, oldHealth, amount, kind)
    return upgrade.health
end

local GAA_AllowedFrontDamageParts = {
    EngineDoor = true,
    Hood = true,
    HeadlightLeft = true,
    HeadlightRight = true,
    Engine = true,
    FrontEndDurability = true,
}

local function handleFrontDamage(player, args)
    local attacker = getAttacker(player, args)
    if not attacker then return end
    local upgrade, cfg = Impact.getFunctional(attacker)
    if not upgrade or not cfg then return end

    local sourcePartId = tostring(args and args.sourcePartId or "")
    if not GAA_AllowedFrontDamageParts[sourcePartId] then return end
    if sourcePartId ~= "FrontEndDurability" and not attacker:getPartById(sourcePartId) then return end

    local rawDamage = Impact.clamp(tonumber(args and args.damageTaken) or 0, 0, 100)
    local previousCondition = tonumber(args and args.previousCondition)
    local currentCondition = tonumber(args and args.currentCondition)
    if previousCondition and currentCondition then
        local snapshotDamage = Impact.clamp(previousCondition - currentCondition, 0, 100)
        if snapshotDamage <= 0 then return end
        rawDamage = math.min(rawDamage, snapshotDamage + 0.01)
    end
    if rawDamage <= 0 then return end

    -- Reject duplicate/out-of-order reports while allowing distinct condition
    -- drops on consecutive update ticks during dense horde impacts.
    local vehicleKey = Impact.getVehicleKey(attacker)
    local stamp = tonumber(args and args.clientStamp) or 0
    local sequence = tonumber(args and args.sequence) or 0
    local previous = frontDamageLast[vehicleKey]
    if previous then
        if stamp < previous.stamp then return end
        if stamp == previous.stamp and sequence <= previous.sequence then return end
    end
    frontDamageLast[vehicleKey] = {
        stamp = stamp,
        sequence = sequence,
        serverStamp = Impact.nowMs(),
    }

    local multiplier = math.max(0, tonumber(cfg.frontWearPerDamage) or 0.3)
    local minimum = math.max(1, math.floor(tonumber(cfg.frontWearMin) or 1))
    local maximum = math.max(minimum, math.floor(tonumber(cfg.frontWearMax) or 100))
    local wear = math.ceil(rawDamage * multiplier)
    wear = math.max(minimum, math.min(maximum, wear))

    applyBullbarWear(attacker, player, upgrade, wear, "front-impact")
end

local function zombieIsAlive(zombie)
    if not zombie then return false end
    if zombie.isDead then
        local ok, dead = pcall(function() return zombie:isDead() end)
        if ok and dead == true then return false end
    end
    if zombie.getHealth then
        local ok, health = pcall(function() return zombie:getHealth() end)
        if ok and tonumber(health) and tonumber(health) <= 0 then return false end
    end
    return true
end

local function killZombie(zombie, player)
    if not zombie or not zombie.Kill then return false end
    local ok = pcall(function() zombie:Kill(player, false) end)
    if not ok then ok = pcall(function() zombie:Kill(player) end) end
    return ok
end


local function handleZombieImpact(player, args)
    local attacker = getAttacker(player, args)
    if not attacker then return end
    local upgrade, cfg = Impact.getFunctional(attacker)
    if not upgrade or not cfg then return end

    local serverSpeed = Impact.getSpeedKph(attacker)
    local clientSpeed = Impact.clamp(tonumber(args and args.speedKph) or 0, 0, 220)
    local impactSpeed = math.max(serverSpeed, clientSpeed)
    if args and args.wasMovingForward == false then return end
    if impactSpeed < (tonumber(cfg.zombieKillSpeedKph) or 9999) then return end

    local snapshotX, snapshotY = tonumber(args and args.impactVehicleX), tonumber(args and args.impactVehicleY)
    local currentX, currentY = tonumber(attacker:getX()), tonumber(attacker:getY())
    if not snapshotX or not snapshotY or not currentX or not currentY then return end
    local moveDx, moveDy = currentX - snapshotX, currentY - snapshotY
    if moveDx * moveDx + moveDy * moveDy > 144 then return end

    local impactZ = tonumber(args and args.impactVehicleZ) or tonumber(attacker:getZ()) or 0
    local zombieZ = tonumber(args and args.zombieZ)
    if not zombieZ or math.abs(zombieZ - impactZ) > 1 then return end
    if args and args.hitFromFront == false then return end
    if not Impact.isPointInFrontSnapshot(attacker, snapshotX, snapshotY, args.impactForwardX, args.impactForwardY, args.zombieX, args.zombieY, 0.5, cfg.zombieWidthScale) then
        return
    end

    local targetKey
    if Impact.isValidOnlineId(args and args.zombieOnlineId) then
        targetKey = "online:" .. tostring(args.zombieOnlineId)
    elseif args and args.zombieObjectId ~= nil then
        targetKey = "object:" .. tostring(args.zombieObjectId)
    else
        local qx = math.floor((tonumber(args and args.zombieX) or 0) * 4 + 0.5)
        local qy = math.floor((tonumber(args and args.zombieY) or 0) * 4 + 0.5)
        targetKey = "xy:" .. tostring(qx) .. ":" .. tostring(qy)
    end
    local key = cooldownKey(attacker, "zombie", targetKey)
    if not claimCooldown(key, tonumber(cfg.impactCooldownMs) or 1200) then return end

    -- Integrity wear is handled separately by the front-part condition-loss
    -- observer. This route only applies the guaranteed offensive zombie result.
    local zombie = findZombie(args)
    if zombie and zombieIsAlive(zombie) then killZombie(zombie, player) end
end

local function safeString(obj, methodName)
    local value = Impact.safeCall(obj, methodName)
    return value ~= nil and tostring(value) or ""
end

local function isDamageExemptVehicle(vehicle)
    if not vehicle then return true end
    local names = table.concat({
        safeString(vehicle, "getScriptName"),
        safeString(vehicle, "getName"),
        safeString(vehicle, "getObjectName"),
        safeString(vehicle, "getVehicleType"),
    }, " "):lower()
    local script = Impact.safeCall(vehicle, "getScript")
    if script then
        names = names .. " " .. safeString(script, "getName"):lower()
        names = names .. " " .. safeString(script, "getFullName"):lower()
    end
    if names:find("wreck") or names:find("burnt") or names:find("burned")
    or names:find("smashed") or names:find("destroyed") then return true end

    for _, methodName in ipairs({ "isBurnt", "isBurned", "isDestroyed", "isSmashed" }) do
        local result = Impact.safeCall(vehicle, methodName)
        if result == true then return true end
    end

    local engine = vehicle.getPartById and vehicle:getPartById("Engine") or nil
    if not engine then return true end
    local condition = engine.getCondition and engine:getCondition() or 0
    return (tonumber(condition) or 0) <= 0
end

local function isTowingPair(a, b)
    if not a or not b then return false end
    local aTowedBy = Impact.safeCall(a, "getVehicleTowedBy")
    local aTowing = Impact.safeCall(a, "getVehicleTowing")
    local bTowedBy = Impact.safeCall(b, "getVehicleTowedBy")
    local bTowing = Impact.safeCall(b, "getVehicleTowing")
    return aTowedBy == b or aTowing == b or bTowedBy == a or bTowing == a
end

local function targetImpactSide(target, attacker)
    local fx, fy = Impact.getForward2D(target)
    if not fx or not fy then return "front" end
    local dx = attacker:getX() - target:getX()
    local dy = attacker:getY() - target:getY()
    local forward = dx * fx + dy * fy
    local lateral = dx * (-fy) + dy * fx
    if math.abs(forward) >= math.abs(lateral) then
        return forward >= 0 and "front" or "rear"
    end
    return lateral >= 0 and "left" or "right"
end

local candidatesBySide = {
    front = { "EngineDoor", "Hood", "Windshield", "HeadlightLeft", "HeadlightRight" },
    rear = { "TrunkDoor", "TruckBed", "RearWindshield", "HeadlightRearLeft", "HeadlightRearRight" },
    left = { "DoorFrontLeft", "WindowFrontLeft", "DoorRearLeft", "WindowRearLeft" },
    right = { "DoorFrontRight", "WindowFrontRight", "DoorRearRight", "WindowRearRight" },
}

local function findDamagePart(vehicle, side)
    local candidates = candidatesBySide[side] or candidatesBySide.front
    local fallback = nil
    for _, partId in ipairs(candidates) do
        local part = vehicle:getPartById(partId)
        if part and part.getCondition then
            fallback = fallback or part
            if (tonumber(part:getCondition()) or 0) > 0 then return part end
        end
    end
    return fallback
end

local function damageVehiclePart(vehicle, part, amount)
    if not vehicle or not part then return 0 end
    amount = math.max(1, math.floor((tonumber(amount) or 0) + 0.5))
    local before = tonumber(part:getCondition()) or 0
    if before <= 0 then return 0 end
    if part.damage then
        pcall(function() part:damage(amount) end)
    elseif part.setCondition then
        pcall(function() part:setCondition(math.max(0, before - amount)) end)
    end
    local after = tonumber(part:getCondition()) or math.max(0, before - amount)
    if vehicle.transmitPartCondition then pcall(function() vehicle:transmitPartCondition(part) end) end
    return math.max(0, before - after)
end

local function handleVehicleImpact(player, args)
    local attacker = getAttacker(player, args)
    if not attacker or not Impact.isMovingForward(attacker) then return end
    local upgrade, cfg = Impact.getFunctional(attacker)
    if not upgrade or not cfg then return end

    local target = findTargetVehicle(args, attacker)
    if not target or target == attacker or isTowingPair(attacker, target) then return end
    if math.abs((tonumber(target:getZ()) or 0) - (tonumber(attacker:getZ()) or 0)) > 1 then return end
    if not Impact.isPointInFront(attacker, target:getX(), target:getY(), 1.2) then return end
    if not Impact.isVehicleCollision(attacker, target) then return end

    local relativeSpeed = Impact.relativeImpactSpeedKph(attacker, target)
    local startSpeed = tonumber(cfg.vehicleBonusStartKph) or 24.1402
    if relativeSpeed < startSpeed then return end

    local key = cooldownKey(attacker, "vehicle", Impact.getVehicleKey(target))
    if not claimCooldown(key, tonumber(cfg.impactCooldownMs) or 1200) then return end

    local fullSpeed = tonumber(cfg.zombieKillSpeedKph) or startSpeed
    local scale = Impact.clamp((relativeSpeed - startSpeed) / math.max(1, fullSpeed - startSpeed), 0, 1)

    -- Bullbar wear is based on the attacker's actual front-part condition loss.
    -- This also covers collisions with exempt wrecks without double-charging
    -- successful vehicle-impact requests here.
    if isDamageExemptVehicle(target) then return end

    local estimatedVanillaImpact = Impact.clamp(relativeSpeed / 4, 4, 25)
    local massFactor = math.sqrt(Impact.getMass(attacker) / math.max(1, Impact.getMass(target)))
    massFactor = Impact.clamp(massFactor, 0.65, 1.50)
    local bonus = estimatedVanillaImpact * (tonumber(cfg.vehicleBonusMax) or 0) * scale * massFactor
    if bonus < 1 then return end

    local side = targetImpactSide(target, attacker)
    local part = findDamagePart(target, side)
    if part then damageVehiclePart(target, part, bonus) end
end

local function onClientCommand(module, command, player, args)
    if module ~= Impact.Module then return end
    if command == Impact.FrontDamageCommand then
        handleFrontDamage(player, args)
    elseif command == Impact.ZombieCommand then
        handleZombieImpact(player, args)
    elseif command == Impact.VehicleCommand then
        handleVehicleImpact(player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)
