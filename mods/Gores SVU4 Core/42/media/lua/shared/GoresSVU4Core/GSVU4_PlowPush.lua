--========================================================
-- Gore's SVU4 Core - Defensive Plow shared helpers
-- Lateral crowd displacement only. No scripted health damage.
--========================================================

require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "GoresSVU4Core/GSVU4_BullBarImpact"

GSVU4 = GSVU4 or {}
GSVU4.PlowPush = GSVU4.PlowPush or {}
local Plow = GSVU4.PlowPush
local Geometry = GSVU4.BullBarImpact

Plow.Module = "GoresSVU4Core"
Plow.PushCommand = "PlowPushZombie"
Plow.ResultCommand = "PlowPushResult"
Plow.ScanIntervalMs = 50

local function safeCall(obj, methodName, ...)
    if not obj or not obj[methodName] then return nil end
    local args = { ... }
    local ok, result = pcall(function() return obj[methodName](obj, unpack(args)) end)
    if ok then return result end
    return nil
end

function Plow.clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function Plow.nowMs()
    if getTimestampMs then
        local ok, value = pcall(function() return getTimestampMs() end)
        if ok and value then return tonumber(value) or 0 end
    end
    return (os.time() or 0) * 1000
end

function Plow.getInstalled(vehicle)
    if not vehicle or not vehicle.getModData then return nil, nil end
    local md = safeCall(vehicle, "getModData")
    local upgrade = md and md.gUpgrades and md.gUpgrades.Plow or nil
    if type(upgrade) ~= "table" or not upgrade.grade then return nil, nil end
    local cfg = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig
        and GSVU4UpgradesConfig.getGradeConfig("Plow", upgrade.grade) or nil
    if not cfg then return nil, nil end
    upgrade.health = tonumber(upgrade.health) or tonumber(cfg.health) or 100
    upgrade.maxHealth = tonumber(upgrade.maxHealth) or tonumber(cfg.health) or 100
    upgrade.wearRemainder = tonumber(upgrade.wearRemainder) or 0
    return upgrade, cfg
end

function Plow.getFunctional(vehicle)
    local upgrade, cfg = Plow.getInstalled(vehicle)
    if not upgrade or (tonumber(upgrade.health) or 0) <= 0 then return nil, nil end
    return upgrade, cfg
end

function Plow.getSpeedKph(vehicle)
    local value = safeCall(vehicle, "getCurrentSpeedKmHour")
    return math.abs(tonumber(value) or 0)
end

function Plow.isMovingForward(vehicle)
    if Geometry and Geometry.isMovingForward then return Geometry.isMovingForward(vehicle) end
    local gear = safeCall(vehicle, "getTransmissionNumber")
    if tonumber(gear) and tonumber(gear) < 0 then return false end
    return Plow.getSpeedKph(vehicle) > 1
end

function Plow.getScriptMass(vehicle)
    local script = safeCall(vehicle, "getScript")
    local mass = script and safeCall(script, "getMass") or nil
    if not tonumber(mass) or tonumber(mass) <= 0 then
        mass = safeCall(vehicle, "getInitialMass")
    end
    if not tonumber(mass) or tonumber(mass) <= 0 then
        mass = safeCall(vehicle, "getMass")
    end
    return math.max(500, tonumber(mass) or 1200)
end

function Plow.getPower(vehicle, cfg, speedOverride)
    local speed = math.abs(tonumber(speedOverride) or Plow.getSpeedKph(vehicle))
    local minSpeed = tonumber(cfg and cfg.minPushKph) or 10
    local fullSpeed = math.max(minSpeed + 1, tonumber(cfg and cfg.fullPushKph) or 45)
    local speedFactor = Plow.clamp((speed - minSpeed) / (fullSpeed - minSpeed), 0, 1)
    local massFactor = Plow.clamp(math.sqrt(Plow.getScriptMass(vehicle) / 1200), 0.70, 1.65)
    local fixtureFactor = tonumber(cfg and cfg.pushMultiplier) or 1.0
    return massFactor * speedFactor * fixtureFactor, massFactor, speedFactor
end

local function getForward(vehicle)
    if Geometry and Geometry.getForward2D then return Geometry.getForward2D(vehicle) end
    return nil, nil
end

local function getDimensions(vehicle)
    if Geometry and Geometry.getVehicleDimensions then return Geometry.getVehicleDimensions(vehicle) end
    return 2.0, 4.5
end

function Plow.getSweepPosition(vehicle, targetX, targetY, widthScale, originX, originY, forwardX, forwardY)
    originX = tonumber(originX) or tonumber(safeCall(vehicle, "getX"))
    originY = tonumber(originY) or tonumber(safeCall(vehicle, "getY"))
    targetX, targetY = tonumber(targetX), tonumber(targetY)
    if not originX or not originY or not targetX or not targetY then return nil end
    if not forwardX or not forwardY then forwardX, forwardY = getForward(vehicle) end
    forwardX, forwardY = tonumber(forwardX), tonumber(forwardY)
    if not forwardX or not forwardY then return nil end
    local length = math.sqrt(forwardX * forwardX + forwardY * forwardY)
    if length < 0.001 then return nil end
    forwardX, forwardY = forwardX / length, forwardY / length

    local dx, dy = targetX - originX, targetY - originY
    local forward = dx * forwardX + dy * forwardY
    local lateralSigned = dx * (-forwardY) + dy * forwardX
    local lateral = math.abs(lateralSigned)
    local width, vehicleLength = getDimensions(vehicle)
    widthScale = Plow.clamp(tonumber(widthScale) or 1.0, 0.75, 1.40)
    local halfWidth = (width * 0.60 + 0.55) * widthScale
    local frontNear = math.max(0.15, vehicleLength * 0.22)
    local frontFar = vehicleLength * 0.66 + 1.10
    if forward < frontNear or forward > frontFar or lateral > halfWidth then return nil end
    local side = lateralSigned < 0 and -1 or 1
    if lateral < 0.08 then side = 1 end
    return {
        forward = forward,
        lateral = lateralSigned,
        side = side,
        halfWidth = halfWidth,
        forwardX = forwardX,
        forwardY = forwardY,
    }
end

function Plow.isZombieAlive(zombie)
    if not zombie or not zombie.isZombie then return false end
    local okZombie, isZombieValue = pcall(function() return zombie:isZombie() end)
    if not okZombie or isZombieValue ~= true then return false end
    if zombie.isDead then
        local okDead, dead = pcall(function() return zombie:isDead() end)
        if okDead and dead == true then return false end
    end
    return true
end

local function squareIsUsable(square)
    if not square then return false end
    if square.isSolid then
        local ok, value = pcall(function() return square:isSolid() end)
        if ok and value == true then return false end
    end
    if square.isSolidTrans then
        local ok, value = pcall(function() return square:isSolidTrans() end)
        if ok and value == true then return false end
    end
    if square.isFree then
        local ok, value = pcall(function() return square:isFree(false) end)
        if ok and value == false then return false end
    end
    return true
end

function Plow.findDestination(zombie, vehicle, side, distance)
    if not zombie or not vehicle or not getCell then return nil, nil end
    local x = tonumber(safeCall(zombie, "getX"))
    local y = tonumber(safeCall(zombie, "getY"))
    local z = math.floor(tonumber(safeCall(zombie, "getZ")) or 0)
    if not x or not y then return nil, nil end
    local fx, fy = getForward(vehicle)
    if not fx or not fy then return nil, nil end
    side = tonumber(side) and tonumber(side) < 0 and -1 or 1
    local lateralX, lateralY = -fy * side, fx * side
    local cell = getCell()
    if not cell or not cell.getGridSquare then return nil, nil end

    local bestX, bestY = nil, nil
    local maxDistance = Plow.clamp(tonumber(distance) or 0.75, 0.35, 2.10)
    local step = 0.20
    local travelled = step
    while travelled <= maxDistance + 0.001 do
        local tx, ty = x + lateralX * travelled, y + lateralY * travelled
        local square = cell:getGridSquare(math.floor(tx), math.floor(ty), z)
        if not squareIsUsable(square) then break end
        bestX, bestY = tx, ty
        travelled = travelled + step
    end
    return bestX, bestY
end

local function setHitDirection(zombie, x, y, force, strong)
    if Vector2 and Vector2.new and zombie.setHitDir then
        pcall(function() zombie:setHitDir(Vector2.new(x, y)) end)
    end
    if zombie.setHitForce then pcall(function() zombie:setHitForce(force) end) end
    if zombie.setBumpStaggered then pcall(function() zombie:setBumpStaggered(true) end) end
    if zombie.setBumpFall then pcall(function() zombie:setBumpFall(strong == true) end) end
    if strong and zombie.setKnockedDown then pcall(function() zombie:setKnockedDown(true) end) end
    if strong and zombie.setFallOnFront then pcall(function() zombie:setFallOnFront(false) end) end
end

function Plow.applyDisplacement(vehicle, zombie, cfg, speedOverride, sideOverride)
    if not Plow.isZombieAlive(zombie) then return false, false, 0 end
    local position = Plow.getSweepPosition(
        vehicle,
        safeCall(zombie, "getX"),
        safeCall(zombie, "getY"),
        cfg and cfg.widthScale
    )
    if not position then return false, false, 0 end
    local power = Plow.getPower(vehicle, cfg, speedOverride)
    if power <= 0.05 then return false, false, power end
    local side = tonumber(sideOverride) and (tonumber(sideOverride) < 0 and -1 or 1) or position.side
    local distance = Plow.clamp(0.35 + power * 0.85, 0.35, 2.0)
    local targetX, targetY = Plow.findDestination(zombie, vehicle, side, distance)
    if not targetX then
        side = -side
        targetX, targetY = Plow.findDestination(zombie, vehicle, side, distance * 0.85)
    end
    if not targetX then return false, false, power end

    local fx, fy = position.forwardX, position.forwardY
    local pushX, pushY = -fy * side, fx * side
    local strong = power >= (tonumber(cfg and cfg.knockdownThreshold) or 0.95)
    setHitDirection(zombie, pushX, pushY, Plow.clamp(power, 0.25, 1.75), strong)
    pcall(function() zombie:setX(targetX) end)
    pcall(function() zombie:setY(targetY) end)
    if zombie.setLx then pcall(function() zombie:setLx(targetX) end) end
    if zombie.setLy then pcall(function() zombie:setLy(targetY) end) end
    return true, strong, power
end

function Plow.applyWear(vehicle, upgrade, cfg, strong)
    if not vehicle or not upgrade or not cfg then return 0, tonumber(upgrade and upgrade.health) or 0 end
    local wear = strong and (tonumber(cfg.strongWear) or 1.0) or (tonumber(cfg.normalWear) or 0.5)
    local total = (tonumber(upgrade.wearRemainder) or 0) + wear
    local whole = math.floor(total + 0.0001)
    upgrade.wearRemainder = total - whole
    if whole <= 0 then return 0, tonumber(upgrade.health) or 0 end
    local oldHealth = tonumber(upgrade.health) or tonumber(cfg.health) or 100
    upgrade.health = math.max(0, oldHealth - whole)
    upgrade.maxHealth = tonumber(cfg.health) or tonumber(upgrade.maxHealth) or 100
    if vehicle.transmitModData then pcall(function() vehicle:transmitModData() end) end
    return whole, upgrade.health
end

function Plow.addVehicleArgs(args, vehicle)
    args = args or {}
    if Geometry and Geometry.addVehicleArgs then
        return Geometry.addVehicleArgs(args, vehicle, "vehicle")
    end
    return args
end

function Plow.vehicleMatchesArgs(vehicle, args)
    if Geometry and Geometry.vehicleMatchesArgs then
        return Geometry.vehicleMatchesArgs(vehicle, args, "vehicle")
    end
    return false
end

function Plow.getForward2D(vehicle)
    return getForward(vehicle)
end
