--========================================================
-- Gore's SVU4 Vanilla Vehicles - Auto Tune Radio Aerial Visual
--
-- PickUpArmor.fbx contains a dedicated "Radio Aerial" mesh. This bridge
-- attaches that mesh to the proven SVU3 body-anchor refresh path and toggles
-- it when the Core AutoTuneMilitaryRadio upgrade is installed/removed.
--========================================================

GSVU4VanillaCars = GSVU4VanillaCars or {}
GSVU4VV = GSVU4VV or {}
GSVU4VV.AutoTuneRadioAerial = GSVU4VV.AutoTuneRadioAerial or {}

local PREFIX = "[Gore's SVU4 Vanilla Vehicles AutoTuneRadioAerial] "

local PICKUP_SPEC = {
    anchorIds = {
        "GSVU4_SVU3_PickUpVan_BodyAnchor", -- actual SVU3 pickup/pickup-van body anchor
        "GSVU4_SVU3_PickUp_BodyAnchor",    -- legacy compatibility fallback
    },
    model = "GSVU4_AutoTuneRadioAerialFallback_PickUp",
}

local directPickups = {
    PickUpTruck = true,
    PickUpTruckBrickingIt = true,
    PickUpTruckBuilder = true,
    PickUpTruckCallowayLandscaping = true,
    PickUpTruckHeltonMetalWorking = true,
    PickUpTruckJOLandscaping = true,
    PickUpTruckJPLandscaping = true,
    PickUpTruckKimbleKonstruction = true,
    PickUpTruckLights = true,
    PickUpTruckLightsAirport = true,
    PickUpTruckLightsAirportSecurity = true,
    PickUpTruckLightsCarpenter = true,
    PickUpTruckLightsFire = true,
    PickUpTruckLightsFossoil = true,
    PickUpTruckLightsKentuckyLumber = true,
    PickUpTruckLightsPolice = true,
    PickUpTruckLightsRanger = true,
    PickUpTruckLightsStatePolice = true,
    PickUpTruckMarchRidgeConstruction = true,
    PickUpTruckMccoy = true,
    PickUpTruckMetalworker = true,
    PickUpTruckTransit = true,
    PickUpTruckWeldingbyCamille = true,
    PickUpTruckYingsWood = true,
    PickUpTruck_Camo = true,
    PickUpVan = true,
    PickUpVanBrickingIt = true,
    PickUpVanBuilder = true,
    PickUpVanCallowayLandscaping = true,
    PickUpVanHeltonMetalWorking = true,
    PickUpVanKimbleKonstruction = true,
    PickUpVanLights = true,
    PickUpVanLightsCarpenter = true,
    PickUpVanLightsFire = true,
    PickUpVanLightsFossoil = true,
    PickUpVanLightsKentuckyLumber = true,
    PickUpVanLightsLouisvilleCounty = true,
    PickUpVanLightsPolice = true,
    PickUpVanLightsRanger = true,
    PickUpVanLightsStatePolice = true,
    PickUpVanLights_LouisvilleCounty = true,
    PickUpVanLouisvilleCounty = true,
    PickUpVanMarchRidgeConstruction = true,
    PickUpVanMccoy = true,
    PickUpVanMetalworker = true,
    PickUpVanTransit = true,
    PickUpVanWeldingbyCamille = true,
    PickUpVanYingsWood = true,
    PickUpVan_Camo = true,
    PickUpVan_LightsLouisvilleCounty = true,
    PickUpVan_LouisvilleCounty = true,
}

local function getVehicleScriptName(vehicle)
    if not vehicle then return nil end
    local script = nil
    if vehicle.getScript then
        local ok, value = pcall(function() return vehicle:getScript() end)
        if ok then script = value end
    end
    if script and script.getName then
        local ok, value = pcall(function() return script:getName() end)
        if ok and value then return tostring(value) end
    end
    if script and script.getFullName then
        local ok, value = pcall(function() return script:getFullName() end)
        if ok and value then return tostring(value):gsub("^[^%.]+%.", "") end
    end
    if vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value then return tostring(value):gsub("^[^%.]+%.", "") end
    end
    return nil
end

local function isPickupFamily(vehicle)
    local scriptName = getVehicleScriptName(vehicle)
    if not scriptName then return false end
    if directPickups[scriptName] then return true end
    local lower = string.lower(scriptName)
    return string.find(lower, "pickup", 1, true) ~= nil
end

local function hasAutoTuneRadioInstalled(vehicle)
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local up = md and md.gUpgrades and md.gUpgrades.AutoTuneMilitaryRadio
    return type(up) == "table" and up.grade ~= nil
end

local function getPartByIds(vehicle, ids)
    if not vehicle or not vehicle.getPartById or not ids then return nil end
    for _, id in ipairs(ids) do
        local ok, part = pcall(function() return vehicle:getPartById(id) end)
        if ok and part then return part end
    end
    return nil
end

local function setModel(part, modelName, visible)
    if not part or not modelName or not part.setModelVisible then return false end
    local ok = pcall(function() part:setModelVisible(tostring(modelName), visible == true) end)
    return ok == true
end

function GSVU4_ApplyAutoTuneRadioAerialVisual(vehicle, force)
    if not vehicle or not isPickupFamily(vehicle) then return false end

    local part = getPartByIds(vehicle, PICKUP_SPEC.anchorIds)
    if not part then return false end

    local visible = hasAutoTuneRadioInstalled(vehicle)
    setModel(part, PICKUP_SPEC.model, visible)
    -- visual-only local state; no part-model packet transmit
    -- Vanilla damage overlay is refreshed once by Core after visual retries settle.
    return true
end

GSVU4VV.AutoTuneRadioAerial.Pending = GSVU4VV.AutoTuneRadioAerial.Pending or {}

local function vehicleKey(vehicle)
    if not vehicle then return nil end
    if vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and value ~= nil and tonumber(value) and tonumber(value) >= 0 then return "online:" .. tostring(value) end
    end
    if vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and value ~= nil then return "id:" .. tostring(value) end
    end
    return tostring(vehicle)
end

local function queueApply(vehicle, attempts)
    if not vehicle then return end
    GSVU4_ApplyAutoTuneRadioAerialVisual(vehicle, true)
    local key = vehicleKey(vehicle)
    if key then
        GSVU4VV.AutoTuneRadioAerial.Pending[key] = { vehicle = vehicle, attempts = tonumber(attempts) or 12 }
    end
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
    if math.abs((tonumber(vx) or 0) - (tonumber(args.vehicleX) or 0)) > 2 then return false end
    if math.abs((tonumber(vy) or 0) - (tonumber(args.vehicleY) or 0)) > 2 then return false end
    return true
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

local function findVehicleFromArgs(args)
    if not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getVehicles then return nil end
    local okVehicles, vehicles = pcall(function() return cell:getVehicles() end)
    if not okVehicles or not vehicles then return nil end

    if vehicles.size and vehicles.get then
        local okSize, count = pcall(function() return vehicles:size() end)
        if okSize and count then
            for i = 0, count - 1 do
                local okGet, vehicle = pcall(function() return vehicles:get(i) end)
                if okGet and vehicleMatches(vehicle, args) then return vehicle end
            end
        end
    elseif type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do
            if vehicleMatches(vehicle, args) then return vehicle end
        end
    end
    return nil
end

local function onServerCommand(module, command, args)
    if module ~= "GoresSVU4Core" or command ~= "UpgradeActionApplied" then return end
    if not args or args.upgradeId ~= "AutoTuneMilitaryRadio" then return end
    local vehicle = findVehicleFromArgs(args)
    if vehicle then queueApply(vehicle, 16) end
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end

if Events and Events.OnEnterVehicle then
    Events.OnEnterVehicle.Add(function(player)
        local vehicle = player and player.getVehicle and player:getVehicle() or nil
        if vehicle then queueApply(vehicle, 8) end
    end)
end

if Events and Events.OnPlayerUpdate and not GSVU4VV.AutoTuneRadioAerial._pendingHooked then
    GSVU4VV.AutoTuneRadioAerial._pendingHooked = true
    Events.OnPlayerUpdate.Add(function()
        local pending = GSVU4VV.AutoTuneRadioAerial.Pending
        for key, entry in pairs(pending) do
            if not entry or not entry.vehicle or (entry.attempts or 0) <= 0 then
                pending[key] = nil
            else
                GSVU4_ApplyAutoTuneRadioAerialVisual(entry.vehicle, true)
                entry.attempts = (entry.attempts or 0) - 1
            end
        end
    end)
end
