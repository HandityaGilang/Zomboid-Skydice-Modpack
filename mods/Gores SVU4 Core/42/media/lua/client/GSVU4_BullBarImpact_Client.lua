--========================================================
-- Gore's SVU4 Core - Offensive Bullbar Client Detector
-- Finds likely local-driver frontal contacts and sends candidates to the server.
-- The server independently validates every impact before changing game state.
--========================================================

require "GoresSVU4Core/GSVU4_BullBarImpact"

local Impact = GSVU4 and GSVU4.BullBarImpact
if not Impact then return end

local lastScan = 0
local recentZombie = {}
local recentVehicle = {}

local function isMultiplayerClient()
    return isClient and isClient()
end

local function getDriver(vehicle)
    if vehicle and vehicle.getDriver then
        local ok, driver = pcall(function() return vehicle:getDriver() end)
        if ok then return driver end
    end
    return getPlayer and getPlayer() or nil
end

local function killZombieLocal(attacker, zombie)
    if not zombie or not zombie.Kill then return false end
    local driver = getDriver(attacker)
    local ok = pcall(function() zombie:Kill(driver, false) end)
    if not ok then ok = pcall(function() zombie:Kill(driver) end) end
    return ok
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

local function damageVehiclePartLocal(vehicle, part, amount)
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
    if vehicle.transmitPartCondition then
        pcall(function() vehicle:transmitPartCondition(part) end)
    end
    return math.max(0, before - after)
end

local function applyVehicleBonusLocal(attacker, target, cfg)
    if not attacker or not target or target == attacker or isTowingPair(attacker, target) then return end
    if isDamageExemptVehicle(target) then return end

    local relativeSpeed = Impact.relativeImpactSpeedKph(attacker, target)
    local startSpeed = tonumber(cfg.vehicleBonusStartKph) or 24.1402
    if relativeSpeed < startSpeed then return end

    local fullSpeed = tonumber(cfg.zombieKillSpeedKph) or startSpeed
    local scale = Impact.clamp((relativeSpeed - startSpeed) / math.max(1, fullSpeed - startSpeed), 0, 1)
    local estimatedVanillaImpact = Impact.clamp(relativeSpeed / 4, 4, 25)
    local massFactor = math.sqrt(Impact.getMass(attacker) / math.max(1, Impact.getMass(target)))
    massFactor = Impact.clamp(massFactor, 0.65, 1.50)
    local bonus = estimatedVanillaImpact * (tonumber(cfg.vehicleBonusMax) or 0) * scale * massFactor
    if bonus < 1 then return end

    local side = targetImpactSide(target, attacker)
    local part = findDamagePart(target, side)
    local dealt = part and damageVehiclePartLocal(target, part, bonus) or 0
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

local function getObjectKey(obj, fallbackPrefix)
    if not obj then return fallbackPrefix .. ":nil" end
    if obj.getOnlineID then
        local ok, value = pcall(function() return obj:getOnlineID() end)
        if ok and Impact.isValidOnlineId(value) then return fallbackPrefix .. ":online:" .. tostring(value) end
    end
    if obj.getId then
        local ok, value = pcall(function() return obj:getId() end)
        if ok and value ~= nil then return fallbackPrefix .. ":id:" .. tostring(value) end
    end
    local x = obj.getX and obj:getX() or 0
    local y = obj.getY and obj:getY() or 0
    return fallbackPrefix .. ":xy:" .. tostring(math.floor(x)) .. ":" .. tostring(math.floor(y))
end

local function isLiveZombie(obj)
    if not obj or not obj.isZombie then return false end
    local okZombie, zombie = pcall(function() return obj:isZombie() end)
    if not okZombie or zombie ~= true then return false end
    if obj.isDead then
        local okDead, dead = pcall(function() return obj:isDead() end)
        if okDead and dead == true then return false end
    end
    return true
end

local function looksLikeVehicle(obj)
    return obj ~= nil and obj.getModData ~= nil and obj.getPartById ~= nil and obj.getCurrentSpeedKmHour ~= nil
end

local function sendZombieCandidate(attacker, zombie, cfg, now)
    local key = getObjectKey(zombie, "zombie")
    if now - (recentZombie[key] or 0) < (Impact.ZombieRequestCooldownMs or 1400) then return end
    if not Impact.isWithinBullbarWidth(attacker, zombie, cfg.zombieWidthScale) then return end

    local collided, hitVars, collisionSource = Impact.isCharacterCollision(attacker, zombie)
    if not collided then return end

    local hitFromFront = hitVars and Impact.getHitVar(hitVars, "isVehicleHitFromFront") or nil
    if hitFromFront == false then return end
    if not hitVars and not Impact.isPointInFront(attacker, zombie:getX(), zombie:getY(), 0.5, cfg.zombieWidthScale) then return end

    local args = Impact.addVehicleArgs({}, attacker, "vehicle")
    args.speedKph = Impact.getSpeedKph(attacker)
    args.rawSpeedKph = Impact.getRawSpeedKph(attacker)
    args.wasMovingForward = Impact.isMovingForward(attacker)
    local onlineId = zombie.getOnlineID and zombie:getOnlineID() or nil
    args.zombieOnlineId = Impact.isValidOnlineId(onlineId) and onlineId or nil
    local objectId = zombie.getId and zombie:getId() or nil
    args.zombieObjectId = objectId ~= nil and objectId or nil
    args.zombieX = zombie:getX()
    args.zombieY = zombie:getY()
    args.zombieZ = zombie:getZ()
    args.impactVehicleX = attacker:getX()
    args.impactVehicleY = attacker:getY()
    args.impactVehicleZ = attacker:getZ()
    local fx, fy = Impact.getForward2D(attacker)
    args.impactForwardX = fx
    args.impactForwardY = fy
    args.hitFromFront = hitFromFront ~= false
    args.hitSpeed = hitVars and tonumber(Impact.getHitVar(hitVars, "hitSpeed")) or nil
    args.vehicleDamage = hitVars and tonumber(Impact.getHitVar(hitVars, "vehicleDamage")) or nil
    args.collisionSource = collisionSource
    args.clientStamp = now
    recentZombie[key] = now
    if isMultiplayerClient() then
        if sendClientCommand then
            sendClientCommand(Impact.Module, Impact.ZombieCommand, args)
        end
    else
        killZombieLocal(attacker, zombie)
    end
end

local function scanZombies(attacker, cfg, now)
    if Impact.getSpeedKph(attacker) < (tonumber(cfg.zombieKillSpeedKph) or 9999) then return end
    if not getCell then return end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return end
    local cx, cy, cz = math.floor(attacker:getX()), math.floor(attacker:getY()), math.floor(attacker:getZ())
    local seen = {}
    for dx = -3, 3 do
        for dy = -3, 3 do
            local square = cell:getGridSquare(cx + dx, cy + dy, cz)
            if square and square.getMovingObjects then
                local objects = square:getMovingObjects()
                for i = 0, listSize(objects) - 1 do
                    local obj = listGet(objects, i)
                    if isLiveZombie(obj) and not seen[obj] then
                        seen[obj] = true
                        sendZombieCandidate(attacker, obj, cfg, now)
                    end
                end
            end
        end
    end
end

local function sendVehicleCandidate(attacker, target, cfg, now)
    if not target or target == attacker then return end
    local key = Impact.getVehicleKey(target)
    if now - (recentVehicle[key] or 0) < (Impact.VehicleRequestCooldownMs or 1200) then return end
    if not Impact.isPointInFront(attacker, target:getX(), target:getY(), 1.2) then return end
    if not Impact.isVehicleCollision(attacker, target) then return end

    local args = Impact.addVehicleArgs({}, attacker, "vehicle")
    Impact.addVehicleArgs(args, target, "target")
    args.speedKph = Impact.getSpeedKph(attacker)
    args.relativeSpeedKph = Impact.relativeImpactSpeedKph(attacker, target)
    args.clientStamp = now
    recentVehicle[key] = now
    if isMultiplayerClient() then
        if sendClientCommand then
            sendClientCommand(Impact.Module, Impact.VehicleCommand, args)
        end
    else
        applyVehicleBonusLocal(attacker, target, cfg)
    end
end

local function scanVehicles(attacker, cfg, now)
    if Impact.getSpeedKph(attacker) < (tonumber(cfg.vehicleBonusStartKph) or 24.1402) then return end
    if not getCell then return end
    local cell = getCell()
    if not cell or not cell.getVehicles then return end
    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if not ok or not vehicles then return end
    for i = 0, listSize(vehicles) - 1 do
        local target = listGet(vehicles, i)
        if looksLikeVehicle(target) then sendVehicleCandidate(attacker, target, cfg, now) end
    end
end

local function prune(tableRef, now, maxAge)
    for key, stamp in pairs(tableRef) do
        if now - (tonumber(stamp) or 0) > maxAge then tableRef[key] = nil end
    end
end

local function onPlayerUpdate(player)
    if not player or not player.isLocalPlayer or not player:isLocalPlayer() then return end
    local attacker = player:getVehicle()
    if not attacker then return end
    if attacker.getDriver then
        local ok, driver = pcall(function() return attacker:getDriver() end)
        if ok and driver ~= player then return end
    end

    local upgrade, cfg = Impact.getFunctional(attacker)
    if not upgrade or not cfg then return end
    if not Impact.isMovingForward(attacker) then return end

    local now = Impact.nowMs()
    if now - lastScan < (Impact.ClientScanIntervalMs or 90) then return end
    lastScan = now

    scanZombies(attacker, cfg, now)
    scanVehicles(attacker, cfg, now)

    if now % 5000 < 120 then
        prune(recentZombie, now, 6000)
        prune(recentVehicle, now, 6000)
    end
end

local function onServerCommand(module, command, args)
    if module ~= Impact.Module or command ~= Impact.ResultCommand then return end
    local player = getPlayer and getPlayer() or nil
    local vehicle = player and player.getVehicle and player:getVehicle() or nil
    if vehicle and args and Impact.vehicleMatchesArgs(vehicle, args, "vehicle") then
        local vdata = vehicle:getModData()
        local upgrade = vdata and vdata.gUpgrades and vdata.gUpgrades.BullBar or nil
        if upgrade and args.health ~= nil then upgrade.health = tonumber(args.health) or upgrade.health end
    end
    if args and args.destroyed == true and player and player.Say then player:Say("Bull bar destroyed!") end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnServerCommand.Add(onServerCommand)
