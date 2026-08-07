--========================================================
-- Gore's SVU4 Core - Upgrade Server Commands
--========================================================

require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "GoresSVU4Core/GSVU4_AutoTuneMilitaryRadio"

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

local function iterateVehicles(collection, callback)
    if not collection or not callback then return false end
    if type(collection) == "table" then
        for _, vehicle in pairs(collection) do if callback(vehicle) then return true end end
        return false
    end
    if collection.size and collection.get then
        local okSize, count = pcall(function() return collection:size() end)
        if okSize and count then
            for i = 0, count - 1 do
                local okGet, vehicle = pcall(function() return collection:get(i) end)
                if okGet and callback(vehicle) then return true end
            end
        end
    end
    return false
end

local function getVehicleFromArgs(args)
    if not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getVehicles then return nil end
    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if not ok or not vehicles then return nil end
    local found = nil
    iterateVehicles(vehicles, function(vehicle)
        if vehicleMatches(vehicle, args) then found = vehicle; return true end
        return false
    end)
    return found
end


local function applyExternalUpgradeVisual(vehicle, upgradeId, grade)
    if not vehicle or not upgradeId then return end
    if GSVU4Core and GSVU4Core.ApplyExternalUpgradeVisualPacks then
        pcall(function() GSVU4Core.ApplyExternalUpgradeVisualPacks(vehicle, upgradeId, grade) end)
    elseif GSVU4Core and GSVU4Core.ApplyExternalVisualPacks then
        pcall(function() GSVU4Core.ApplyExternalVisualPacks(vehicle, nil) end)
    end
    if GSVU4Core
    and GSVU4Core.QueueUnifiedVehicleVisualRefresh then
        pcall(function()
            GSVU4Core.QueueUnifiedVehicleVisualRefresh(
                vehicle,
                "upgrade:" .. tostring(upgradeId)
            )
        end)
    elseif VehicleArmorVisuals
    and VehicleArmorVisuals.QueueApply then
        pcall(function()
            VehicleArmorVisuals.QueueApply(vehicle, nil, 4, 15)
        end)
    end
end

local function applyUpgradeState(args)
    local vehicle = getVehicleFromArgs(args)
    if not vehicle then return end

    local upgradeId = args and args.upgradeId
    local grade = args and args.grade
    if not upgradeId or not grade then return end

    local data = vehicle:getModData()
    data.gUpgrades = data.gUpgrades or {}

    if tostring(grade) == "Removed" then
        data.gUpgrades[upgradeId] = nil

        if upgradeId == "RoofRack"
        and data.gExternalStorage then
            data.gExternalStorage.RoofRack = nil
        end
    else
        local cfg =
            GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
        if not cfg then return end

        local current = data.gUpgrades[upgradeId] or {}
        current.grade = grade
        current.capacity = tonumber(args.capacity) or cfg.capacity or current.capacity or 0
        current.weight = tonumber(args.weight) or cfg.weight or current.weight or 0
        current.health = tonumber(args.health) or current.health or cfg.health or 100
        if args.filterCapacity ~= nil then current.filterCapacity = tonumber(args.filterCapacity) end
        if args.filterMaxCapacity ~= nil then current.filterMaxCapacity = tonumber(args.filterMaxCapacity) end
        if type(args.filterMedia) == "table" then current.filterMedia = args.filterMedia end
        if args.filterMediaVersion ~= nil then current.filterMediaVersion = args.filterMediaVersion end
        data.gUpgrades[upgradeId] = current

        GSVU4UpgradesConfig.ensureExternalStorageData(vehicle)

        if upgradeId == "RoofRack" then
            data.gExternalStorage.RoofRack =
                data.gExternalStorage.RoofRack
                or { items = {}, used = 0 }

            data.gExternalStorage.RoofRack.capacity =
                tonumber(args.capacity)
                or cfg.capacity
                or 0
        end
    end

    -- The local gUpgrades table is now authoritative for this acknowledgement.
    -- Release the one visual writer immediately instead of waiting for a second
    -- server command. The later server-ready message simply restarts the same
    -- finite retry sequence after native part packets have settled.
    if GSVU4Core
    and GSVU4Core.ReleaseVehicleVisualState then
        GSVU4Core.ReleaseVehicleVisualState(
            vehicle,
            "upgrade-ack:" .. tostring(upgradeId)
        )
    elseif GSVU4Core
    and GSVU4Core.MarkVehicleVisualStatePending then
        GSVU4Core.MarkVehicleVisualStatePending(
            vehicle,
            "upgrade-ack:" .. tostring(upgradeId)
        )
    end

    if GSVU4Core then
        GSVU4Core.UIState = GSVU4Core.UIState or {}
        GSVU4Core.UIState.InventoryDirtyStamp =
            (GSVU4Core.UIState.InventoryDirtyStamp or 0) + 1
    end

    if upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
        if tostring(grade) == "Removed" then
            if GSVU4FilteredAirIntake.clearRuntimeStatus then
                GSVU4FilteredAirIntake.clearRuntimeStatus(vehicle)
            end
        elseif GSVU4FilteredAirIntake.refreshProtectionRuntime then
            local player = getPlayer and getPlayer() or nil
            pcall(function() GSVU4FilteredAirIntake.refreshProtectionRuntime(player, vehicle) end)
        end
    end
end

local function getLocalPlayerSafe()
    if not getPlayer then return nil end
    local ok, player = pcall(getPlayer)
    if ok then return player end
    return nil
end

local function onServerCommand(module, command, args)
    if module ~= "GoresSVU4Core" then return end
    if command == "UpgradeActionApplied" then
        if GSVU4 and GSVU4.MPInventoryMirror and GSVU4.MPInventoryMirror.consumeForUpgradeAction then
            pcall(function() GSVU4.MPInventoryMirror.consumeForUpgradeAction(args) end)
        end
        applyUpgradeState(args)
    elseif command == "UpgradeActionRejected" then
        local player = getLocalPlayerSafe()
        if player and player.Say then player:Say(args and args.message or "Upgrade action rejected.") end
    end
end

Events.OnServerCommand.Add(onServerCommand)
