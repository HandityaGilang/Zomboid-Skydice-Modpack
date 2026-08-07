-- Gore's SVU4 Core - ExtraFuelStorage and RoofRack persistent state
-- Reapplies auxiliary-tank cargo capacity on vehicle creation/load and periodically while occupied.
-- Also syncs the GSVU4RoofRack part slot item on the same cadence.

local GSVU4_EFS_lastApply = {}

local GSVU4_GRADE_ITEM = {
    Basic    = "Base.GSVU4RoofRackBasic",
    Standard = "Base.GSVU4RoofRackStandard",
    Military = "Base.GSVU4RoofRackMilitary",
}

local function GSVU4_ApplyExtraFuelStorageToVehicle(vehicle)
    if not vehicle or not vehicle.getModData then return end
    local vdata = vehicle:getModData()
    if vdata and vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage then
        if GSVU4UpgradesConfig and GSVU4UpgradesConfig.applyExtraFuelStorage then
            GSVU4UpgradesConfig.applyExtraFuelStorage(vehicle)
        end
    end
end

local function GSVU4_ForEachLoadedVehicle(callback)
    if not callback or not getCell then return end
    local cell = getCell()
    if not cell or not cell.getVehicles then return end

    local okVehicles, vehicles = pcall(function() return cell:getVehicles() end)
    if not okVehicles or not vehicles then return end

    if type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do callback(vehicle) end
        return
    end

    if vehicles.size and vehicles.get then
        local okSize, count = pcall(function() return vehicles:size() end)
        if okSize and count then
            for i = 0, count - 1 do
                local okGet, vehicle = pcall(function() return vehicles:get(i) end)
                if okGet and vehicle then callback(vehicle) end
            end
        end
        return
    end

    if vehicles.getCount and vehicles.get then
        local okCount, count = pcall(function() return vehicles:getCount() end)
        if okCount and count then
            for i = 0, count - 1 do
                local okGet, vehicle = pcall(function() return vehicles:get(i) end)
                if okGet and vehicle then callback(vehicle) end
            end
        end
    end
end

local function GSVU4_ApplyExtraFuelStorageForPlayer(player)
    if not player or not player.getVehicle then return end
    local vehicle = player:getVehicle()
    if not vehicle then return end

    local vid = tostring(vehicle)
    local now = getTimestampMs and getTimestampMs() or 0

    -- Only reapply every 5 seconds to avoid performance impact
    if GSVU4_EFS_lastApply[vid] and now - GSVU4_EFS_lastApply[vid] < 5000 then return end
    GSVU4_EFS_lastApply[vid] = now

    local vdata = vehicle:getModData()

    -- Reapply ExtraFuelStorage
    GSVU4_ApplyExtraFuelStorageToVehicle(vehicle)

    -- Sync GSVU4RoofRack part slot item so the container survives data syncs
    if vehicle.getPartById then
        local okP, part = pcall(function() return vehicle:getPartById("GSVU4RoofRack") end)
        if okP and part then
            local rack = vdata and vdata.gUpgrades and vdata.gUpgrades.RoofRack
            local current     = part:getInventoryItem()
            local currentType = current and current.getFullType and current:getFullType() or nil

            if rack and rack.grade then
                local wantedType = GSVU4_GRADE_ITEM[rack.grade] or GSVU4_GRADE_ITEM.Basic
                if currentType ~= wantedType and instanceItem then
                    local ok, item = pcall(function() return instanceItem(wantedType) end)
                    if ok and item then
                        pcall(function()
                            part:setInventoryItem(item)
                            vehicle:transmitPartItem(part)
                        end)
                    end
                end
            else
                if currentType then
                    pcall(function()
                        part:setInventoryItem(nil)
                        vehicle:transmitPartItem(part)
                    end)
                end
            end
        end
    end
end

-- Hook for all players (client-side)
Events.OnPlayerUpdate.Add(function(player)
    GSVU4_ApplyExtraFuelStorageForPlayer(player)
end)

-- Also apply when getting into a vehicle
Events.OnEnterVehicle.Add(function(player)
    -- Reset timer so it applies immediately on entry
    if player and player.getVehicle then
        local vehicle = player:getVehicle()
        if vehicle then GSVU4_EFS_lastApply[tostring(vehicle)] = nil end
    end
    GSVU4_ApplyExtraFuelStorageForPlayer(player)
end)

-- Apply as vehicles are instantiated or loaded, including parked vehicles that
-- no player has entered during this session.
if Events and Events.OnVehicleCreated then
    Events.OnVehicleCreated.Add(function(vehicle)
        GSVU4_ApplyExtraFuelStorageToVehicle(vehicle)
    end)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        GSVU4_ForEachLoadedVehicle(GSVU4_ApplyExtraFuelStorageToVehicle)
    end)
end
