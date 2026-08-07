--========================================================
-- GORE'S SVU4 CORE - MP SINGLE-WRITER VISUAL SYNC
--
-- Server owns gameplay/native part state.
-- Client owns cosmetic model visibility.
-- One controller reapplies upgrades first and armor last.
--========================================================

require "VehicleArmor/VehicleArmor_Visuals"
require "GoresSVU4Core/GSVU4_Upgrades_Config"

GSVU4Core = GSVU4Core or {}
GSVU4Core.PendingVehicleVisualSync =
    GSVU4Core.PendingVehicleVisualSync or {}

local RETRY_TICKS = { 2, 10, 30, 90, 180, 300, 600 }
local READY_FALLBACK_TICKS = 60
local tickRegistered = false

local ALL_UPGRADE_IDS = {
    "EngineScoop",
    "FilteredAirIntake",
    "RoofRack",
    "ExtraFuelStorage",
    "JerryCanSlots",
    "BullBar",
    "Plow",
    "AutoTuneMilitaryRadio",
    "TyreChains",
    "RoofLights",
    "RoofLightsLeft",
    "RoofLightsRight",
    "RoofLightsRear",
}

local function valueMatches(a, b)
    if a == nil or b == nil then return false end
    if tostring(a) == tostring(b) then return true end
    local na, nb = tonumber(a), tonumber(b)
    return na ~= nil and nb ~= nil and na == nb
end

local function coordsMatch(vehicle, args)
    if not vehicle or not args then return false end
    if args.vehicleX == nil or args.vehicleY == nil then return false end
    if not vehicle.getX or not vehicle.getY then return false end

    local okX, x = pcall(function() return vehicle:getX() end)
    local okY, y = pcall(function() return vehicle:getY() end)
    if not okX or not okY then return false end

    return math.abs((tonumber(x) or 0) - (tonumber(args.vehicleX) or 0)) <= 2
       and math.abs((tonumber(y) or 0) - (tonumber(args.vehicleY) or 0)) <= 2
end

local function vehicleMatches(vehicle, args)
    if not vehicle or not args then return false end

    if args.vehicleOnlineId ~= nil and vehicle.getOnlineID then
        local ok, value = pcall(function()
            return vehicle:getOnlineID()
        end)
        if ok and valueMatches(value, args.vehicleOnlineId) then
            return true
        end
    end

    if args.vehicleId ~= nil and vehicle.getId then
        local ok, value = pcall(function()
            return vehicle:getId()
        end)
        if ok and valueMatches(value, args.vehicleId) then
            return true
        end
    end

    return coordsMatch(vehicle, args)
end

local function getVehicleFromArgs(args)
    if not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getVehicles then return nil end

    local okVehicles, vehicles = pcall(function()
        return cell:getVehicles()
    end)
    if not okVehicles or not vehicles then return nil end

    local found = nil
    local function inspect(vehicle)
        if vehicleMatches(vehicle, args) then
            found = vehicle
            return true
        end
        return false
    end

    if type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do
            if inspect(vehicle) then break end
        end
    elseif vehicles.size and vehicles.get then
        local okSize, count = pcall(function()
            return vehicles:size()
        end)
        if okSize and count then
            for index = 0, count - 1 do
                local okVehicle, vehicle = pcall(function()
                    return vehicles:get(index)
                end)
                if okVehicle and inspect(vehicle) then break end
            end
        end
    end

    return found
end

local function vehicleKey(vehicle)
    if not vehicle then return nil end

    if vehicle.getOnlineID then
        local ok, value = pcall(function()
            return vehicle:getOnlineID()
        end)
        if ok and value ~= nil and tonumber(value)
        and tonumber(value) >= 0 then
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

local function applyNativeVisualsOnly(vehicle)
    if not vehicle then return end

    if GSVU4_ApplyAutoTuneRadioAerialVisual then
        pcall(function()
            GSVU4_ApplyAutoTuneRadioAerialVisual(vehicle, true)
        end)
    end

    if GSVU4
    and GSVU4.RoofRack
    and GSVU4.RoofRack.SyncVisualOnly then
        pcall(function()
            GSVU4.RoofRack.SyncVisualOnly(vehicle)
        end)

        if GSVU4.RoofRack.RefreshInventoryPages then
            pcall(function()
                GSVU4.RoofRack.RefreshInventoryPages()
            end)
        end
    end

    if GSVU4
    and GSVU4.RoofLights
    and GSVU4.RoofLights.syncVisualOnly then
        pcall(function()
            GSVU4.RoofLights.syncVisualOnly(vehicle)
        end)
    elseif GSVU4_ApplyRoofLightsVisual then
        pcall(function()
            GSVU4_ApplyRoofLightsVisual(vehicle)
        end)
    end

    if GSVU4_TyreChains
    and GSVU4_TyreChains.requestVisualRefresh then
        pcall(function()
            GSVU4_TyreChains.requestVisualRefresh(vehicle, 30)
        end)
    end
end

local function applyExternalVisuals(vehicle)
    if not vehicle then return end

    local data = vehicle.getModData and vehicle:getModData() or nil
    local upgrades = data and data.gUpgrades or nil

    if GSVU4Core.ApplyExternalUpgradeVisualPacks then
        for _, upgradeId in ipairs(ALL_UPGRADE_IDS) do
            local entry = upgrades and upgrades[upgradeId] or nil
            local grade = entry and entry.grade or "Removed"

            pcall(function()
                GSVU4Core.ApplyExternalUpgradeVisualPacks(
                    vehicle,
                    upgradeId,
                    grade
                )
            end)
        end
    end

    -- One full visual-pack pass. This restores body-anchor based vehicles and
    -- every armor/upgrade alias registered by Vanilla Cars or PZK Cars.
    if GSVU4Core.ApplyExternalVisualPacks then
        pcall(function()
            GSVU4Core.ApplyExternalVisualPacks(vehicle, nil)
        end)
    end
end

function GSVU4Core.ApplyCompleteVehicleVisualState(vehicle, rebuildDamage)
    if not vehicle then return false end

    -- Rebuild native damage only for the initial authoritative pass. Late
    -- visual retries reassert custom models without repeatedly rebuilding the
    -- blood/damage overlay, which causes visible pulsing.
    if rebuildDamage ~= false and vehicle.doDamageOverlay then
        pcall(function()
            vehicle:doDamageOverlay()
        end)
    end

    -- Stable final order:
    -- damage -> native upgrades -> external packs -> armor.
    applyNativeVisualsOnly(vehicle)
    applyExternalVisuals(vehicle)

    if VehicleArmorVisuals
    and VehicleArmorVisuals.ForceInstalled then
        pcall(function()
            VehicleArmorVisuals.ForceInstalled(vehicle, true)
        end)
    end

    return true
end

local function hasPending()
    for _, _ in pairs(GSVU4Core.PendingVehicleVisualSync) do
        return true
    end
    return false
end

local function unregisterTick()
    if not tickRegistered then return end
    if Events and Events.OnTick and Events.OnTick.Remove then
        pcall(function()
            Events.OnTick.Remove(
                GSVU4Core.ProcessVehicleVisualSync
            )
        end)
    end
    tickRegistered = false
end

local function registerTick()
    if tickRegistered then return end
    if Events and Events.OnTick then
        Events.OnTick.Add(
            GSVU4Core.ProcessVehicleVisualSync
        )
        tickRegistered = true
    end
end

function GSVU4Core.MarkVehicleVisualStatePending(vehicle, reason)
    local key = vehicleKey(vehicle)
    if not key then return false end

    GSVU4Core.PendingVehicleVisualSync[key] = {
        vehicle = vehicle,
        reason = tostring(reason or "action"),
        ready = false,
        age = 0,
        retryIndex = 1,
    }

    registerTick()
    return true
end

function GSVU4Core.ReleaseVehicleVisualState(vehicle, reason)
    local key = vehicleKey(vehicle)
    if not key then return false end

    local entry = GSVU4Core.PendingVehicleVisualSync[key] or {
        vehicle = vehicle,
        reason = tostring(reason or "ready"),
    }

    entry.vehicle = vehicle
    entry.reason = tostring(reason or entry.reason or "ready")
    entry.ready = true
    entry.age = 0
    entry.retryIndex = 1
    GSVU4Core.PendingVehicleVisualSync[key] = entry

    -- Apply immediately, then retain a finite late-packet retry window.
    GSVU4Core.ApplyCompleteVehicleVisualState(vehicle, true)
    registerTick()
    return true
end

function GSVU4Core.ProcessVehicleVisualSync()
    local pending = GSVU4Core.PendingVehicleVisualSync

    if not pending or not hasPending() then
        unregisterTick()
        return
    end

    for key, entry in pairs(pending) do
        if not entry or not entry.vehicle then
            pending[key] = nil
        else
            entry.age = (entry.age or 0) + 1

            -- Safety fallback for old servers or separate TyreChains commands.
            if entry.ready ~= true
            and entry.age >= READY_FALLBACK_TICKS then
                entry.ready = true
                entry.age = 0
                entry.retryIndex = 1
                GSVU4Core.ApplyCompleteVehicleVisualState(entry.vehicle, false)
            elseif entry.ready == true then
                local target = RETRY_TICKS[entry.retryIndex or 1]

                if target and entry.age >= target then
                    GSVU4Core.ApplyCompleteVehicleVisualState(
                        entry.vehicle,
                        false
                    )
                    entry.retryIndex = (entry.retryIndex or 1) + 1
                end

                if not RETRY_TICKS[entry.retryIndex or 1] then
                    pending[key] = nil
                end
            end
        end
    end

    if not hasPending() then
        unregisterTick()
    end
end

local function onVehicleCreated(vehicle)
    if not vehicle then return end
    -- B42.20 may bind dynamically injected vehicle models after the original
    -- game-start sweep. Apply immediately and retain the normal finite retry
    -- sequence so a freshly spawned car does not need an enter/exit refresh.
    GSVU4Core.ReleaseVehicleVisualState(vehicle, "vehicle-created")
end

local function onServerCommand(module, command, args)
    if module ~= "GoresSVU4Core" then return end
    if command ~= "VehicleVisualRefreshReady" then return end

    local vehicle = getVehicleFromArgs(args)
    if not vehicle then return end

    GSVU4Core.ReleaseVehicleVisualState(
        vehicle,
        args and args.reason or "server-ready"
    )
end

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end
if Events and Events.OnVehicleCreated then
    Events.OnVehicleCreated.Add(onVehicleCreated)
end

-- Legacy callers are routed into the same controller rather than creating a
-- second, competing armor-only queue.
if VehicleArmorVisuals then
    VehicleArmorVisuals.QueueApply = function(
        vehicle,
        partId,
        maxAttempts,
        intervalTicks
    )
        return GSVU4Core.ReleaseVehicleVisualState(
            vehicle,
            "legacy:" .. tostring(partId or "vehicle")
        )
    end
end
