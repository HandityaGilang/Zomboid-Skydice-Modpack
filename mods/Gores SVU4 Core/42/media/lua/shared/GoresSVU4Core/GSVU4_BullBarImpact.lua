--========================================================
-- Gore's SVU4 Core - Offensive Bullbar Impact Helpers
-- Shared client/server geometry and configuration helpers.
--========================================================

require "GoresSVU4Core/GSVU4_Upgrades_Config"

GSVU4 = GSVU4 or {}
GSVU4.BullBarImpact = GSVU4.BullBarImpact or {}
local Impact = GSVU4.BullBarImpact

Impact.Module = "GoresSVU4Core"
Impact.ZombieCommand = "BullBarZombieImpact"
Impact.VehicleCommand = "BullBarVehicleImpact"
Impact.FrontDamageCommand = "BullBarFrontDamage"
Impact.ResultCommand = "BullBarImpactResult"
Impact.ClientScanIntervalMs = 25
Impact.ZombieRequestCooldownMs = 1400
Impact.VehicleRequestCooldownMs = 1200

function Impact.clamp(value, minValue, maxValue)
    value = tonumber(value) or 0
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function Impact.nowMs()
    if getTimestampMs then
        local ok, value = pcall(function() return getTimestampMs() end)
        if ok and value then return tonumber(value) or 0 end
    end
    return (os.time() or 0) * 1000
end

local function safeCall(obj, methodName, ...)
    if not obj or not obj[methodName] then return nil end
    local args = { ... }
    local ok, result = pcall(function()
        return obj[methodName](obj, unpack(args))
    end)
    if ok then return result end
    return nil
end

function Impact.getInstalled(vehicle)
    if not vehicle or not vehicle.getModData then return nil, nil end
    local vdata = safeCall(vehicle, "getModData")
    local upgrade = vdata and vdata.gUpgrades and vdata.gUpgrades.BullBar or nil
    if type(upgrade) ~= "table" or not upgrade.grade then return nil, nil end
    upgrade.health = tonumber(upgrade.health) or 100
    local cfg = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig
        and GSVU4UpgradesConfig.getGradeConfig("BullBar", upgrade.grade) or nil
    if not cfg then return nil, nil end
    return upgrade, cfg
end

function Impact.getFunctional(vehicle)
    local upgrade, cfg = Impact.getInstalled(vehicle)
    if not upgrade or (tonumber(upgrade.health) or 0) <= 0 then return nil, nil end
    return upgrade, cfg
end

function Impact.getRawSpeedKph(vehicle)
    local value = safeCall(vehicle, "getCurrentSpeedKmHour")
    return tonumber(value) or 0
end

function Impact.getSpeedKph(vehicle)
    return math.abs(Impact.getRawSpeedKph(vehicle))
end

function Impact.isMovingForward(vehicle)
    if not vehicle then return false end
    local transmission = safeCall(vehicle, "getTransmissionNumber")
    if tonumber(transmission) and tonumber(transmission) < 0 then return false end
    local rawSpeed = Impact.getRawSpeedKph(vehicle)
    if rawSpeed < -1 then return false end
    return math.abs(rawSpeed) > 1
end

function Impact.isValidOnlineId(value)
    value = tonumber(value)
    return value ~= nil and value >= 0
end

function Impact.getVehicleKey(vehicle)
    if not vehicle then return "vehicle:nil" end
    local onlineId = safeCall(vehicle, "getOnlineID")
    if Impact.isValidOnlineId(onlineId) then return "online:" .. tostring(onlineId) end
    local id = safeCall(vehicle, "getId")
    if id ~= nil then return "id:" .. tostring(id) end
    return "xy:" .. tostring(math.floor(tonumber(safeCall(vehicle, "getX")) or 0))
        .. ":" .. tostring(math.floor(tonumber(safeCall(vehicle, "getY")) or 0))
end

function Impact.addVehicleArgs(args, vehicle, prefix)
    args = args or {}
    prefix = prefix or "vehicle"
    if not vehicle then return args end
    local onlineId = safeCall(vehicle, "getOnlineID")
    local id = safeCall(vehicle, "getId")
    local x = safeCall(vehicle, "getX")
    local y = safeCall(vehicle, "getY")
    local z = safeCall(vehicle, "getZ")
    args[prefix .. "OnlineId"] = onlineId
    args[prefix .. "Id"] = id
    args[prefix .. "X"] = x
    args[prefix .. "Y"] = y
    args[prefix .. "Z"] = z
    return args
end

local function valuesMatch(a, b)
    if a == nil or b == nil then return false end
    if tostring(a) == tostring(b) then return true end
    local na, nb = tonumber(a), tonumber(b)
    return na ~= nil and nb ~= nil and na == nb
end

function Impact.vehicleMatchesArgs(vehicle, args, prefix)
    if not vehicle or not args then return false end
    prefix = prefix or "vehicle"
    local onlineArg = args[prefix .. "OnlineId"]
    local idArg = args[prefix .. "Id"]
    if onlineArg ~= nil and valuesMatch(safeCall(vehicle, "getOnlineID"), onlineArg) then return true end
    if idArg ~= nil and valuesMatch(safeCall(vehicle, "getId"), idArg) then return true end
    local ax, ay = tonumber(args[prefix .. "X"]), tonumber(args[prefix .. "Y"])
    local vx, vy = tonumber(safeCall(vehicle, "getX")), tonumber(safeCall(vehicle, "getY"))
    if ax and ay and vx and vy and math.abs(vx - ax) <= 2 and math.abs(vy - ay) <= 2 then
        return true
    end
    return false
end

function Impact.newVector3f()
    if Vector3f and Vector3f.new then
        local ok, value = pcall(function() return Vector3f.new() end)
        if ok then return value end
    end
    return nil
end

local function component(vector, name)
    if not vector then return nil end
    local okField, field = pcall(function() return vector[name] end)
    if okField and type(field) == "number" then return field end
    local okMethod, value = pcall(function() return vector[name](vector) end)
    if okMethod then return tonumber(value) end
    local getter = "get" .. string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
    local okGetter, getterValue = pcall(function() return vector[getter](vector) end)
    if okGetter then return tonumber(getterValue) end
    return nil
end

function Impact.getForward2D(vehicle)
    local out = Impact.newVector3f()
    if out and vehicle and vehicle.getForwardVector then
        local ok, vector = pcall(function() return vehicle:getForwardVector(out) end)
        if ok then
            vector = vector or out
            local x = component(vector, "x")
            local y = component(vector, "z")
            if x and y then
                local length = math.sqrt(x * x + y * y)
                if length > 0.001 then return x / length, y / length end
            end
        end
    end

    local dir = safeCall(vehicle, "getDir")
    local name = tostring(dir or ""):lower()
    name = name:gsub("isodirections%.", "")
    local diagonal = 0.70710678
    if name == "ne" or name:find("northeast") then return diagonal, -diagonal end
    if name == "nw" or name:find("northwest") then return -diagonal, -diagonal end
    if name == "se" or name:find("southeast") then return diagonal, diagonal end
    if name == "sw" or name:find("southwest") then return -diagonal, diagonal end
    if name:find("north") or name == "n" then return 0, -1 end
    if name:find("south") or name == "s" then return 0, 1 end
    if name:find("west") or name == "w" then return -1, 0 end
    if name:find("east") or name == "e" then return 1, 0 end
    return nil, nil
end

function Impact.getVehicleDimensions(vehicle)
    local width, length = 2.0, 4.5
    local script = safeCall(vehicle, "getScript")
    local extents = script and safeCall(script, "getExtents") or nil
    if extents then
        width = math.max(1.2, math.abs(component(extents, "x") or width))
        length = math.max(2.0, math.abs(component(extents, "z") or length))
    end
    return width, length
end

function Impact.isPointInFront(vehicle, targetX, targetY, targetRadius, widthScale)
    if not vehicle then return false end
    local vx, vy = tonumber(safeCall(vehicle, "getX")), tonumber(safeCall(vehicle, "getY"))
    targetX, targetY = tonumber(targetX), tonumber(targetY)
    if not vx or not vy or not targetX or not targetY then return false end
    local fx, fy = Impact.getForward2D(vehicle)
    if not fx or not fy then return false end
    local dx, dy = targetX - vx, targetY - vy
    local forward = dx * fx + dy * fy
    local lateral = math.abs(dx * (-fy) + dy * fx)
    local width, length = Impact.getVehicleDimensions(vehicle)
    targetRadius = tonumber(targetRadius) or 0.6
    widthScale = Impact.clamp(tonumber(widthScale) or 1.0, 0.5, 2.0)
    local lateralLimit = (width * 0.55 + targetRadius + 0.8) * widthScale
    return forward >= math.max(0.15, length * 0.10)
       and forward <= (length * 0.65 + targetRadius + 1.2)
       and lateral <= lateralLimit
end


function Impact.isPointInFrontSnapshot(vehicle, originX, originY, forwardX, forwardY, targetX, targetY, targetRadius, widthScale)
    originX, originY = tonumber(originX), tonumber(originY)
    forwardX, forwardY = tonumber(forwardX), tonumber(forwardY)
    targetX, targetY = tonumber(targetX), tonumber(targetY)
    if not originX or not originY or not forwardX or not forwardY or not targetX or not targetY then return false end
    local fLength = math.sqrt(forwardX * forwardX + forwardY * forwardY)
    if fLength < 0.001 then return false end
    forwardX, forwardY = forwardX / fLength, forwardY / fLength
    local dx, dy = targetX - originX, targetY - originY
    local forward = dx * forwardX + dy * forwardY
    local lateral = math.abs(dx * (-forwardY) + dy * forwardX)
    local width, length = Impact.getVehicleDimensions(vehicle)
    targetRadius = tonumber(targetRadius) or 0.6
    widthScale = Impact.clamp(tonumber(widthScale) or 1.0, 0.5, 2.0)
    local lateralLimit = (width * 0.55 + targetRadius + 0.8) * widthScale
    return forward >= math.max(0.05, length * 0.05)
       and forward <= (length * 0.80 + targetRadius + 2.0)
       and lateral <= lateralLimit
end

function Impact.getHitVar(hitVars, name)
    if not hitVars or not name then return nil end
    local ok, value = pcall(function() return hitVars[name] end)
    if ok then return value end
    return nil
end

function Impact.isWithinBullbarWidth(vehicle, character, widthScale)
    if not vehicle or not character then return false end
    local width = Impact.getVehicleDimensions(vehicle)
    widthScale = Impact.clamp(tonumber(widthScale) or 1.0, 0.5, 2.0)
    local lateralLimit = (width * 0.55 + 0.5 + 0.8) * widthScale

    local out = Impact.newVector3f()
    if out and vehicle.getLocalPos then
        local ok, localPos = pcall(function()
            return vehicle:getLocalPos(character:getX(), character:getY(), character:getZ(), out)
        end)
        if ok then
            localPos = localPos or out
            local localX = component(localPos, "x")
            if localX then return math.abs(localX) <= lateralLimit end
        end
    end

    local vx, vy = tonumber(safeCall(vehicle, "getX")), tonumber(safeCall(vehicle, "getY"))
    local tx, ty = tonumber(safeCall(character, "getX")), tonumber(safeCall(character, "getY"))
    local fx, fy = Impact.getForward2D(vehicle)
    if not vx or not vy or not tx or not ty or not fx or not fy then return false end
    local dx, dy = tx - vx, ty - vy
    local lateral = math.abs(dx * (-fy) + dy * fx)
    return lateral <= lateralLimit
end

function Impact.isCharacterCollision(vehicle, character)
    if not vehicle or not character then return false, nil, nil end

    -- B42 exposes the same collision resolver used by vehicle hits.  Unlike the
    -- brief active-collision flags, this returns HitVars for the current contact
    -- and identifies whether the vehicle struck from the front.
    if vehicle.checkCollision then
        local ok, hitVars = pcall(function() return vehicle:checkCollision(character) end)
        if ok and hitVars ~= nil then return true, hitVars, "checkCollision" end
    end

    if vehicle.isCollided then
        local ok, result = pcall(function() return vehicle:isCollided(character) end)
        if ok and result == true then return true, nil, "isCollided" end
    end
    if character.isVehicleCollisionActive then
        local ok, result = pcall(function() return character:isVehicleCollisionActive(vehicle) end)
        if ok and result == true then return true, nil, "collisionActive" end
    end
    return false, nil, nil
end

function Impact.isVehicleCollision(attacker, target)
    if not attacker or not target or attacker == target then return false end
    if attacker.testCollisionWithVehicle then
        local ok, result = pcall(function() return attacker:testCollisionWithVehicle(target) end)
        if ok then return result == true end
    end
    return false
end

function Impact.relativeImpactSpeedKph(attacker, target)
    local a = math.abs(Impact.getSpeedKph(attacker))
    local t = math.abs(Impact.getSpeedKph(target))
    -- Closing speed is deliberately conservative because exact physics velocity
    -- units differ across game contexts. Head-on movement can still add target speed.
    if attacker and target then
        local afx, afy = Impact.getForward2D(attacker)
        local tfx, tfy = Impact.getForward2D(target)
        if afx and afy and tfx and tfy then
            local alignment = afx * tfx + afy * tfy
            if alignment < -0.25 then return a + t end
            if alignment > 0.25 then return math.max(a - t, a * 0.5) end
        end
    end
    return math.max(a, math.abs(a - t))
end

function Impact.getMass(vehicle)
    local mass = tonumber(safeCall(vehicle, "getMass"))
    if mass and mass > 0 then return mass end
    local script = safeCall(vehicle, "getScript")
    mass = script and tonumber(safeCall(script, "getMass")) or nil
    return (mass and mass > 0) and mass or 1000
end

function Impact.safeCall(obj, methodName, ...)
    return safeCall(obj, methodName, ...)
end
