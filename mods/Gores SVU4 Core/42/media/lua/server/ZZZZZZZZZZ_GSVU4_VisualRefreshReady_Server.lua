--========================================================
-- GORE'S SVU4 CORE - SERVER VISUAL REFRESH READY QUEUE
--
-- Native vehicle-part packets are queued first.
-- Cosmetic clients are released a few server ticks later.
--========================================================

GSVU4_ServerPendingVisualReady =
    GSVU4_ServerPendingVisualReady or {}

local DELAY_TICKS = 8
local tickRegistered = false

local function vehicleKey(vehicle)
    if not vehicle then return nil end

    if vehicle.getOnlineID then
        local ok, value = pcall(function()
            return vehicle:getOnlineID()
        end)
        if ok and value ~= nil then
            return "online:" .. tostring(value)
        end
    end

    if vehicle.getId then
        local ok, value = pcall(function()
            return vehicle:getId()
        end)
        if ok and value ~= nil then
            return "id:" .. tostring(value)
        end
    end

    return tostring(vehicle)
end

local function addVehicleArgs(args, vehicle)
    args = args or {}

    if vehicle then
        if vehicle.getId then
            local ok, value = pcall(function()
                return vehicle:getId()
            end)
            if ok and value ~= nil then
                args.vehicleId = value
            end
        end

        if vehicle.getOnlineID then
            local ok, value = pcall(function()
                return vehicle:getOnlineID()
            end)
            if ok and value ~= nil then
                args.vehicleOnlineId = value
            end
        end

        if vehicle.getX then
            local ok, value = pcall(function()
                return vehicle:getX()
            end)
            if ok then args.vehicleX = value end
        end

        if vehicle.getY then
            local ok, value = pcall(function()
                return vehicle:getY()
            end)
            if ok then args.vehicleY = value end
        end

        if vehicle.getZ then
            local ok, value = pcall(function()
                return vehicle:getZ()
            end)
            if ok then args.vehicleZ = value end
        end
    end

    return args
end

local function broadcast(fallbackPlayer, args)
    if not sendServerCommand then return end

    local sent = false

    if getOnlinePlayers then
        local okPlayers, players = pcall(getOnlinePlayers)

        if okPlayers
        and players
        and players.size
        and players.get then
            local okSize, count = pcall(function()
                return players:size()
            end)

            if okSize and count then
                for index = 0, count - 1 do
                    local okPlayer, player = pcall(function()
                        return players:get(index)
                    end)

                    if okPlayer and player then
                        pcall(function()
                            sendServerCommand(
                                player,
                                "GoresSVU4Core",
                                "VehicleVisualRefreshReady",
                                args
                            )
                        end)
                        sent = true
                    end
                end
            end
        end
    end

    if not sent and fallbackPlayer then
        sendServerCommand(
            fallbackPlayer,
            "GoresSVU4Core",
            "VehicleVisualRefreshReady",
            args
        )
    end
end

local function hasPending()
    for _, _ in pairs(GSVU4_ServerPendingVisualReady) do
        return true
    end
    return false
end

local function unregisterTick()
    if not tickRegistered then return end

    if Events and Events.OnTick and Events.OnTick.Remove then
        pcall(function()
            Events.OnTick.Remove(
                GSVU4_ServerProcessVisualRefreshReady
            )
        end)
    end

    tickRegistered = false
end

local function registerTick()
    if tickRegistered then return end

    if Events and Events.OnTick then
        Events.OnTick.Add(
            GSVU4_ServerProcessVisualRefreshReady
        )
        tickRegistered = true
    end
end

function GSVU4_ServerQueueVisualRefreshReady(
    player,
    vehicle,
    reason
)
    local key = vehicleKey(vehicle)
    if not key then return false end

    GSVU4_ServerPendingVisualReady[key] = {
        player = player,
        vehicle = vehicle,
        reason = tostring(reason or "action"),
        ticks = 0,
    }

    registerTick()
    return true
end

function GSVU4_ServerProcessVisualRefreshReady()
    for key, entry in pairs(GSVU4_ServerPendingVisualReady) do
        if not entry or not entry.vehicle then
            GSVU4_ServerPendingVisualReady[key] = nil
        else
            entry.ticks = (entry.ticks or 0) + 1

            if entry.ticks >= DELAY_TICKS then
                local args = addVehicleArgs({
                    reason = entry.reason,
                }, entry.vehicle)

                broadcast(entry.player, args)
                GSVU4_ServerPendingVisualReady[key] = nil
            end
        end
    end

    if not hasPending() then
        unregisterTick()
    end
end
