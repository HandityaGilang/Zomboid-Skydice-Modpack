--========================================================
-- Gore's SVU4 Vanilla Vehicles - Unified visual refresh manager
-- Ensures hidden armour/upgrade visuals stay hidden from the first
-- client-side spawn/load pass, and installed upgrades appear without
-- waiting for later interaction ticks.
--========================================================

GSVU4VV = GSVU4VV or {}

local VR = {}
local refreshQueue = {}
local seenNearby = {}
local tickCounter = 0
local nearbyCounter = 0

local function getShortVehicleName(vehicle)
    if not vehicle then return nil end
    if vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value then return tostring(value):gsub("^Base%.", "") end
    end
    if vehicle.getScript then
        local okScript, script = pcall(function() return vehicle:getScript() end)
        if okScript and script then
            if script.getFullName then
                local ok, value = pcall(function() return script:getFullName() end)
                if ok and value then return tostring(value):gsub("^Base%.", "") end
            end
            if script.getName then
                local ok, value = pcall(function() return script:getName() end)
                if ok and value then return tostring(value):gsub("^Base%.", "") end
            end
        end
    end
    return nil
end

local function eachModel(spec, callback)
    if type(spec) == "table" then
        for _, modelName in pairs(spec) do eachModel(modelName, callback) end
    elseif spec then
        callback(tostring(spec))
    end
end

local function hideSportsCarSpawnDefaults(vehicle)
    if getShortVehicleName(vehicle) ~= "SportsCar" then return end

    local family = GSVU4VV
        and GSVU4VV.FamilyByVehicle
        and (GSVU4VV.FamilyByVehicle.SportsCar
            or GSVU4VV.FamilyByVehicle["Base.SportsCar"])
        or nil
    local hood = family and family.GroupByName and family.GroupByName.Hood or nil
    local engineDoor = vehicle.getPartById and vehicle:getPartById("EngineDoor") or nil
    if engineDoor and engineDoor.setModelVisible and hood then
        eachModel(hood.hideModels or hood.models, function(modelName)
            pcall(function() engineDoor:setModelVisible(modelName, false) end)
            pcall(function() engineDoor:setModelVisible(modelName .. "_Scoop", false) end)
        end)
    end

    local chainsInstalled = GSVU4_TyreChains
        and GSVU4_TyreChains.isInstalled
        and GSVU4_TyreChains.isInstalled(vehicle)
    if not chainsInstalled and vehicle.getPartById then
        local anchor = vehicle:getPartById("GSVU4_SVU3_SportsCar_BodyAnchor")
        if anchor and anchor.setModelVisible then
            pcall(function() anchor:setModelVisible("GSVU4_SVU3_SportsCar_TireChains_Left", false) end)
            pcall(function() anchor:setModelVisible("GSVU4_SVU3_SportsCar_TireChains_Right", false) end)
        end
    end
end

local function getVehicleKey(vehicle)
    if not vehicle then return nil end
    if vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and value ~= nil and tonumber(value) and tonumber(value) >= 0 then return "online:" .. tostring(value) end
    end
    if vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and value ~= nil then return "id:" .. tostring(value) end
    end
    local x, y, z = 0, 0, 0
    if vehicle.getX then local ok, value = pcall(function() return vehicle:getX() end); if ok then x = math.floor(tonumber(value) or 0) end end
    if vehicle.getY then local ok, value = pcall(function() return vehicle:getY() end); if ok then y = math.floor(tonumber(value) or 0) end end
    if vehicle.getZ then local ok, value = pcall(function() return vehicle:getZ() end); if ok then z = math.floor(tonumber(value) or 0) end end
    return "pos:" .. tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return false, nil end
    local ok, result = pcall(fn, ...)
    return ok, result
end

function VR.ApplyAllVehicleVisuals(vehicle, force)
    if not vehicle then return false end
    local applied = false

    hideSportsCarSpawnDefaults(vehicle)

    -- After load order settles, ApplyVehicle is wrapped below so a single call
    -- reasserts the full Vanilla Cars visual stack. Keep a small fallback path
    -- in case another file calls this helper before the wrapper attaches.
    if GSVU4VV and GSVU4VV.VisualPart and GSVU4VV.VisualPart.ApplyVehicle then
        local ok, result = safeCall(GSVU4VV.VisualPart.ApplyVehicle, vehicle)
        applied = (ok and result == true) or applied
        if GSVU4VV.VisualPart.GSVU4VV_AllVisualsWrapped then
            return applied
        end
    end

    if GSVU4VV and GSVU4VV.ApplyRoofLightsUpgradeVisual then safeCall(GSVU4VV.ApplyRoofLightsUpgradeVisual, vehicle); applied = true end
    if GSVU4VV and GSVU4VV.ApplyRoofRackUpgradeVisual then safeCall(GSVU4VV.ApplyRoofRackUpgradeVisual, vehicle); applied = true end
    if GSVU4_ApplyBullBarVisual then safeCall(GSVU4_ApplyBullBarVisual, vehicle, true); applied = true end
    if GSVU4_ApplyAutoTuneRadioAerialVisual then safeCall(GSVU4_ApplyAutoTuneRadioAerialVisual, vehicle, true); applied = true end
    if GSVU4Core and GSVU4Core.ApplyExternalVisualPacks then safeCall(GSVU4Core.ApplyExternalVisualPacks, vehicle, nil); applied = true end
    if GSVU4_TyreChains and GSVU4_TyreChains.applyVisuals then safeCall(GSVU4_TyreChains.applyVisuals, vehicle, true); applied = true end
    if GSVU4VV and GSVU4VV.ApplyEngineScoopVisual then safeCall(GSVU4VV.ApplyEngineScoopVisual, vehicle, true); applied = true end
    return applied
end

if GSVU4VV and GSVU4VV.VisualPart and not GSVU4VV.VisualPart.GSVU4VV_AllVisualsWrapped then
    local originalApplyVehicle = GSVU4VV.VisualPart.ApplyVehicle
    function GSVU4VV.VisualPart.ApplyVehicle(vehicle)
        local applied = false
        if originalApplyVehicle then
            local ok, result = pcall(originalApplyVehicle, vehicle)
            applied = (ok and result == true) or applied
        end
        if vehicle then
            if GSVU4VV and GSVU4VV.ApplyRoofLightsUpgradeVisual then pcall(GSVU4VV.ApplyRoofLightsUpgradeVisual, vehicle) end
            if GSVU4VV and GSVU4VV.ApplyRoofRackUpgradeVisual then pcall(GSVU4VV.ApplyRoofRackUpgradeVisual, vehicle) end
            if GSVU4_ApplyBullBarVisual then pcall(GSVU4_ApplyBullBarVisual, vehicle, true) end
            if GSVU4_ApplyAutoTuneRadioAerialVisual then pcall(GSVU4_ApplyAutoTuneRadioAerialVisual, vehicle, true) end
            if GSVU4Core and GSVU4Core.ApplyExternalVisualPacks then pcall(GSVU4Core.ApplyExternalVisualPacks, vehicle, nil) end
            if GSVU4_TyreChains and GSVU4_TyreChains.applyVisuals then pcall(GSVU4_TyreChains.applyVisuals, vehicle, true) end
            applied = true
        end
        return applied
    end
    GSVU4VV.VisualPart.GSVU4VV_AllVisualsWrapped = true
end

function VR.QueueVehicle(vehicle, frames)
    if not vehicle then return end
    local key = getVehicleKey(vehicle)
    if not key then return end
    refreshQueue[key] = {
        vehicle = vehicle,
        frames = tonumber(frames) or 240,
    }
    VR.ApplyAllVehicleVisuals(vehicle, true)
end

local function processQueue()
    for key, row in pairs(refreshQueue) do
        if not row or not row.vehicle or (row.frames or 0) <= 0 then
            refreshQueue[key] = nil
        else
            row.frames = row.frames - 15
            VR.ApplyAllVehicleVisuals(row.vehicle, true)
        end
    end
end

local function iterLoadedVehicles(callback)
    if not callback or not getCell then return end
    local cell = getCell()
    if not cell or not cell.getVehicles then return end
    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if not ok or not vehicles then return end

    if vehicles.size and vehicles.get then
        local okSize, size = pcall(function() return vehicles:size() end)
        if okSize and size then
            for i = 0, size - 1 do
                local okVehicle, vehicle = pcall(function() return vehicles:get(i) end)
                if okVehicle and vehicle then callback(vehicle) end
            end
        end
    elseif type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do
            if vehicle then callback(vehicle) end
        end
    end
end

local function getPlayerXY(playerObj)
    if not playerObj then return nil, nil end
    local x, y = nil, nil
    if playerObj.getX then local ok, value = pcall(function() return playerObj:getX() end); if ok then x = tonumber(value) end end
    if playerObj.getY then local ok, value = pcall(function() return playerObj:getY() end); if ok then y = tonumber(value) end end
    return x, y
end

local function getVehicleXY(vehicle)
    if not vehicle then return nil, nil end
    local x, y = nil, nil
    if vehicle.getX then local ok, value = pcall(function() return vehicle:getX() end); if ok then x = tonumber(value) end end
    if vehicle.getY then local ok, value = pcall(function() return vehicle:getY() end); if ok then y = tonumber(value) end end
    return x, y
end

local function isVehicleNearAnyPlayer(vehicle, maxDistSq)
    local vx, vy = getVehicleXY(vehicle)
    if not vx or not vy or not getNumActivePlayers or not getSpecificPlayer then return false end
    for i = 0, getNumActivePlayers() - 1 do
        local playerObj = getSpecificPlayer(i)
        local px, py = getPlayerXY(playerObj)
        if px and py then
            local dx, dy = vx - px, vy - py
            if (dx * dx + dy * dy) <= maxDistSq then return true end
        end
    end
    return false
end

local function refreshNearbyVehicles()
    iterLoadedVehicles(function(vehicle)
        if vehicle and isVehicleNearAnyPlayer(vehicle, 45 * 45) then
            local key = getVehicleKey(vehicle) or tostring(vehicle)
            if not seenNearby[key] then
                seenNearby[key] = true
                VR.QueueVehicle(vehicle, 180)
            end
        end
    end)
end

local function fullSweep(frames)
    iterLoadedVehicles(function(vehicle)
        VR.QueueVehicle(vehicle, frames or 180)
    end)
end

local function onTick()
    tickCounter = tickCounter + 1
    nearbyCounter = nearbyCounter + 1
    if tickCounter >= 15 then
        tickCounter = 0
        processQueue()
    end
    if nearbyCounter >= 30 then
        nearbyCounter = 0
        refreshNearbyVehicles()
    end
end

local function onGameStart()
    if GSVU4VV and GSVU4VV.RegisterEngineScoopVehicles then
        pcall(GSVU4VV.RegisterEngineScoopVehicles)
    end
    fullSweep(180)
end

local function onLoad()
    if GSVU4VV and GSVU4VV.RegisterEngineScoopVehicles then
        pcall(GSVU4VV.RegisterEngineScoopVehicles)
    end
    fullSweep(180)
end

local function onCreatePlayer(playerNum, playerObj)
    fullSweep(180)
end

local function onEnterVehicle(character)
    local vehicle = character and character.getVehicle and character:getVehicle() or nil
    if vehicle then VR.QueueVehicle(vehicle, 180) end
end

local function onVehicleCreated(vehicle)
    if vehicle then
        hideSportsCarSpawnDefaults(vehicle)
        VR.QueueVehicle(vehicle, 240)
    end
end

if Events then
    if Events.OnGameStart then Events.OnGameStart.Add(onGameStart) end
    if Events.OnLoad then Events.OnLoad.Add(onLoad) end
    if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
    if Events.OnEnterVehicle then Events.OnEnterVehicle.Add(onEnterVehicle) end
    if Events.OnVehicleCreated then Events.OnVehicleCreated.Add(onVehicleCreated) end
    if Events.OnTick then Events.OnTick.Add(onTick) end
    if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(onTick) end
end
