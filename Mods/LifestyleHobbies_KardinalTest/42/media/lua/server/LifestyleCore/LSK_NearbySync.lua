require "LifestyleCore/LSK_Features"

LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.NearbySync = LifestyleSecure.NearbySync or {}

local Nearby = LifestyleSecure.NearbySync

Nearby.DEFAULT_RADIUS = 35
Nearby.MAX_RADIUS = 80

local function finite(value)
    value = tonumber(value)
    return value and value == value and value > -math.huge and value < math.huge and value or nil
end

local function distanceSquared(aX, aY, bX, bY)
    local dx = aX - bX
    local dy = aY - bY
    return dx * dx + dy * dy
end

function Nearby.SendAround(x, y, z, radius, module, command, args, includeSource)
    if LifestyleSecure and LifestyleSecure.Features
        and LifestyleSecure.Features.IsModActive
        and not LifestyleSecure.Features.IsModActive() then
        return 0
    end
    x = finite(x)
    y = finite(y)
    z = finite(z) or 0
    radius = math.min(Nearby.MAX_RADIUS, math.max(1, finite(radius) or Nearby.DEFAULT_RADIUS))
    if not x or not y or not module or not command or not getOnlinePlayers then
        return 0
    end

    local players = getOnlinePlayers()
    if not players then
        return 0
    end

    local radiusSquared = radius * radius
    local sent = 0
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and not player:isDead() then
            local sameLevel = math.abs((player:getZ() or 0) - z) <= 2
            local inRange = distanceSquared(player:getX(), player:getY(), x, y) <= radiusSquared
            if sameLevel and inRange and (includeSource ~= false or player:getX() ~= x or player:getY() ~= y) then
                sendServerCommand(player, module, command, args or {})
                sent = sent + 1
            end
        end
    end
    return sent
end

function Nearby.SendAroundPlayer(source, radius, module, command, args)
    if not source then
        return 0
    end
    return Nearby.SendAround(
        source:getX(),
        source:getY(),
        source:getZ(),
        radius,
        module,
        command,
        args,
        true
    )
end

return Nearby
