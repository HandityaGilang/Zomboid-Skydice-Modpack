--========================================================
-- Gore's SVU4 Core - Auto Tune Military Radio Client
-- Triggers tuning only when a player is in a vehicle with the engine running.
--========================================================

require "GoresSVU4Core/GSVU4_AutoTuneMilitaryRadio"

GSVU4 = GSVU4 or {}
GSVU4.AutoTuneMilitaryRadioClient = GSVU4.AutoTuneMilitaryRadioClient or { Tick = 0, LastRequest = {} }

local Client = GSVU4.AutoTuneMilitaryRadioClient
local Radio = GSVU4.AutoTuneMilitaryRadio

local function getVehicleKey(vehicle)
    if not vehicle then return nil end
    if vehicle.getOnlineID then
        local ok, v = pcall(function() return vehicle:getOnlineID() end)
        if ok and v and tonumber(v) and tonumber(v) >= 0 then return "online_" .. tostring(v) end
    end
    if vehicle.getId then
        local ok, v = pcall(function() return vehicle:getId() end)
        if ok and v then return "id_" .. tostring(v) end
    end
    if vehicle.getX and vehicle.getY then
        local ok, x, y = pcall(function() return vehicle:getX(), vehicle:getY() end)
        if ok then return "xy_" .. tostring(math.floor(x or 0)) .. "_" .. tostring(math.floor(y or 0)) end
    end
    return tostring(vehicle)
end

local function addVehicleArgs(args, vehicle)
    args = args or {}
    if vehicle then
        if vehicle.getId then local ok, v = pcall(function() return vehicle:getId() end); if ok then args.vehicleId = v end end
        if vehicle.getOnlineID then local ok, v = pcall(function() return vehicle:getOnlineID() end); if ok then args.vehicleOnlineId = v end end
        if vehicle.getX then local ok, v = pcall(function() return vehicle:getX() end); if ok then args.vehicleX = v end end
        if vehicle.getY then local ok, v = pcall(function() return vehicle:getY() end); if ok then args.vehicleY = v end end
        if vehicle.getZ then local ok, v = pcall(function() return vehicle:getZ() end); if ok then args.vehicleZ = v end end
    end
    return args
end

local function isEngineRunning(vehicle)
    if not vehicle or not vehicle.isEngineRunning then return false end
    local ok, running = pcall(function() return vehicle:isEngineRunning() end)
    return ok and running == true
end

local function maybeTune(playerObj)
    if not playerObj or not playerObj.getVehicle then return end
    local vehicle = playerObj:getVehicle()
    if not vehicle or not Radio.hasUpgrade(vehicle) then return end

    local vdata = vehicle:getModData()
    local vehicleKey = getVehicleKey(vehicle)

    local freq = Radio.getAEBSFrequency()
    if not freq then return end

    local presetKey = vehicleKey .. "_preset_" .. tostring(freq)
    local engineRunning = isEngineRunning(vehicle)

    -- The preset should appear even before the engine starts. Tuning the active
    -- channel is still engine-gated to match the intended behaviour.
    local presetAlready = vdata and vdata.gAutoTuneMilitaryRadioPresetProgrammed == true and tonumber(vdata.gAutoTuneMilitaryRadioFrequency) == tonumber(freq)
    if not presetAlready and not Client.LastRequest[presetKey] then
        Client.LastRequest[presetKey] = true
        local okPreset, presetResult = pcall(function() return Radio.programEmergencyPreset(vehicle) end)

        if isClient and isClient() and sendClientCommand then
            sendClientCommand("GoresSVU4Core", "AutoTuneMilitaryRadioProgramPreset", addVehicleArgs({ frequency = freq }, vehicle))
        end

    end

    if not engineRunning then return end

    local tuneKey = vehicleKey .. "_tune_" .. tostring(freq)
    local tunedAlready = vdata and vdata.gAutoTuneMilitaryRadioLastTuneOk == true and tonumber(vdata.gAutoTuneMilitaryRadioFrequency) == tonumber(freq)
    if tunedAlready and Client.LastRequest[tuneKey] then return end

    Client.LastRequest[tuneKey] = true

    -- Local immediate tune for SP/listen-server responsiveness; server command keeps MP authoritative.
    local okLocal, localResult = pcall(function() return Radio.autoTuneVehicleRadio(vehicle) end)

    if isClient and isClient() and sendClientCommand then
        sendClientCommand("GoresSVU4Core", "AutoTuneMilitaryRadio", addVehicleArgs({ frequency = freq }, vehicle))
    end

end

local function onPlayerUpdate(playerObj)
    Client.Tick = (Client.Tick or 0) + 1
    if (Client.Tick % 30) ~= 0 then return end
    maybeTune(playerObj)
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
