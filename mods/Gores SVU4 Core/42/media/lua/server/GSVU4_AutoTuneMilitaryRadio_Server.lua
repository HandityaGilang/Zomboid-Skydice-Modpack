--========================================================
-- Gore's SVU4 Core - Auto Tune Military Radio Server
--========================================================

if isClient and isClient() then return end

require "GoresSVU4Core/GSVU4_AutoTuneMilitaryRadio"

local Radio = GSVU4.AutoTuneMilitaryRadio

local function safeNum(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback or 0 end
    return n
end

local function valueMatches(a, b)
    if a == nil or b == nil then return false end
    if tostring(a) == tostring(b) then return true end
    local na, nb = tonumber(a), tonumber(b)
    return na ~= nil and nb ~= nil and na == nb
end

local function coordsMatch(vehicle, args)
    if not vehicle or not args or args.vehicleX == nil or args.vehicleY == nil then return false end
    if not vehicle.getX or not vehicle.getY then return false end
    local okX, vx = pcall(function() return vehicle:getX() end)
    local okY, vy = pcall(function() return vehicle:getY() end)
    if not okX or not okY then return false end
    return math.abs(safeNum(vx, 0) - safeNum(args.vehicleX, 0)) <= 3
       and math.abs(safeNum(vy, 0) - safeNum(args.vehicleY, 0)) <= 3
end

local function vehicleMatches(vehicle, args)
    if not vehicle or not args then return false end
    if args.vehicleOnlineId ~= nil and vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and valueMatches(value, args.vehicleOnlineId) then return true end
    end
    if args.vehicleId ~= nil and vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and valueMatches(value, args.vehicleId) then return true end
    end
    return coordsMatch(vehicle, args)
end

local function iterateVehicles(callback)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getVehicles then return end
    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if not ok or not vehicles then return end
    if vehicles.size and vehicles.get then
        for i = 0, vehicles:size() - 1 do
            local okV, vehicle = pcall(function() return vehicles:get(i) end)
            if okV and vehicle then callback(vehicle) end
        end
    elseif type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do callback(vehicle) end
    end
end

local function getVehicleFromArgs(args)
    local found = nil
    iterateVehicles(function(vehicle)
        if not found and vehicleMatches(vehicle, args) then found = vehicle end
    end)
    return found
end

local function isEngineRunning(vehicle)
    if not vehicle or not vehicle.isEngineRunning then return false end
    local ok, running = pcall(function() return vehicle:isEngineRunning() end)
    return ok and running == true
end

local function onClientCommand(module, command, player, args)
    if module ~= "GoresSVU4Core" then return end
    if command ~= "AutoTuneMilitaryRadio" and command ~= "AutoTuneMilitaryRadioProgramPreset" then return end

    local vehicle = getVehicleFromArgs(args)
    if not vehicle then return end
    if not Radio.hasUpgrade(vehicle) then return end

    if command == "AutoTuneMilitaryRadioProgramPreset" then
        local ok, result = Radio.programEmergencyPreset(vehicle)
        if ok then

        else

        end
        return
    end

    if command == "AutoTuneMilitaryRadio" then
        if not isEngineRunning(vehicle) then return end
        local ok, result = Radio.autoTuneVehicleRadio(vehicle)
        if ok then

        else

        end
    end
end

Events.OnClientCommand.Add(onClientCommand)
