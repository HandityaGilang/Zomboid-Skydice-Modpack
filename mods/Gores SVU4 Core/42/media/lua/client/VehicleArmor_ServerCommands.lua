--========================================================
-- VEHICLE ARMOR SERVER COMMANDS
-- Client-side feedback/refresh for server-authoritative MP actions.
--========================================================

local function GAA_GetLocalPlayerSafe()
    if getPlayer then
        local ok, player = pcall(getPlayer)
        if ok then return player end
    end

    return nil
end

local function GAA_CommandValueMatches(a, b)
    if a == nil or b == nil then return false end
    if tostring(a) == tostring(b) then return true end
    local na = tonumber(a)
    local nb = tonumber(b)
    return na ~= nil and nb ~= nil and na == nb
end

local function GAA_CoordsMatch(vehicle, args)
    if not vehicle or not args or args.vehicleX == nil or args.vehicleY == nil then return false end
    if not vehicle.getX or not vehicle.getY then return false end

    local okX, vx = pcall(function() return vehicle:getX() end)
    local okY, vy = pcall(function() return vehicle:getY() end)
    if not okX or not okY or vx == nil or vy == nil then return false end

    if math.abs(tonumber(vx) - tonumber(args.vehicleX)) > 2 then return false end
    if math.abs(tonumber(vy) - tonumber(args.vehicleY)) > 2 then return false end

    if args.vehicleZ ~= nil and vehicle.getZ then
        local okZ, vz = pcall(function() return vehicle:getZ() end)
        if okZ and vz ~= nil and math.abs(tonumber(vz) - tonumber(args.vehicleZ)) > 1 then
            return false
        end
    end

    return true
end

local function GAA_VehicleMatchesArgs(vehicle, args)
    if not vehicle or not args then return false end

    if args.vehicleOnlineId ~= nil and vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and GAA_CommandValueMatches(value, args.vehicleOnlineId) then return true end
    end

    if args.vehicleId ~= nil and vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and GAA_CommandValueMatches(value, args.vehicleId) then return true end
    end

    return GAA_CoordsMatch(vehicle, args)
end

local function GAA_IterateVehicles(collection, callback)
    if not collection or not callback then return false end

    -- B42 MP commonly returns Java/userdata collections from cell:getVehicles().
    -- ipairs() only works on Lua tables and can throw "Expected a table".
    if type(collection) == "table" then
        for _, vehicle in pairs(collection) do
            if callback(vehicle) then return true end
        end
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
        return false
    end

    if collection.getCount and collection.get then
        local okCount, count = pcall(function() return collection:getCount() end)
        if okCount and count then
            for i = 0, count - 1 do
                local okGet, vehicle = pcall(function() return collection:get(i) end)
                if okGet and callback(vehicle) then return true end
            end
        end
        return false
    end

    return false
end

local function GAA_GetVehicleFromServerArgs(args)
    if not args or not getCell then return nil end

    local cell = getCell()
    if not cell or not cell.getVehicles then return nil end

    local okVehicles, vehicles = pcall(function()
        return cell:getVehicles()
    end)

    if not okVehicles or not vehicles then return nil end

    local found = nil

    GAA_IterateVehicles(vehicles, function(vehicle)
        if GAA_VehicleMatchesArgs(vehicle, args) then
            found = vehicle
            return true
        end
        return false
    end)

    return found
end

local function GAA_MarkArmorInventoryUIRefreshNeeded()
    if GSVU4Core then
        GSVU4Core.UIState = GSVU4Core.UIState or {}
        GSVU4Core.UIState.InventoryDirty = true
        GSVU4Core.UIState.InventoryDirtyStamp = (GSVU4Core.UIState.InventoryDirtyStamp or 0) + 1
    end
end

local function GAA_ApplyArmorActionApplied(args)
    local vehicle = GAA_GetVehicleFromServerArgs(args)
    if not vehicle then return end

    local partId = args and args.partId
    if not partId then return end

    local vdata = vehicle:getModData()
    vdata.gArmor = vdata.gArmor or {}

    if args.action == "InstallArmor" or args.action == "RepairArmor" then
        vdata.gArmor[partId] = {
            grade = args.grade,
            health = tonumber(args.health) or 100,
        }
    elseif args.action == "UninstallArmor" then
        vdata.gArmor[partId] = nil
    end

    -- Reconcile the complete vehicle immediately from the acknowledged state.
    -- The later server-ready command restarts the same finite sequence.
    if GSVU4Core
    and GSVU4Core.ReleaseVehicleVisualState then
        GSVU4Core.ReleaseVehicleVisualState(
            vehicle,
            "armor-ack:" .. tostring(partId)
        )
    elseif GSVU4Core
    and GSVU4Core.MarkVehicleVisualStatePending then
        GSVU4Core.MarkVehicleVisualStatePending(
            vehicle,
            "armor-ack:" .. tostring(partId)
        )
    end
end

local function GAA_OnServerCommand(module, command, args)
    if module ~= "GoresSVU4Core" then return end

    if command == "ArmorActionRejected" then
        GAA_MarkArmorInventoryUIRefreshNeeded()
        local message = args and args.message or "Armor action rejected by server."
        local lower = tostring(message):lower()

        -- Final client-side guard for old/delayed server builds or mod-order
        -- edge cases: never surface the misleading vehicle-not-found message
        -- from this mod. It can be a false positive after the timed action has
        -- already completed locally/authoritatively.
        if lower == "vehicle not found" or lower == "vehicle not found." then
            return
        end

        local player = GAA_GetLocalPlayerSafe()

        if player and player.Say then
            player:Say(message)
        end
    elseif command == "ArmorActionApplied" then
        GAA_MarkArmorInventoryUIRefreshNeeded()
        if GSVU4 and GSVU4.MPInventoryMirror and GSVU4.MPInventoryMirror.consumeForArmorAction then
            pcall(function() GSVU4.MPInventoryMirror.consumeForArmorAction(args) end)
        end
        GAA_ApplyArmorActionApplied(args)
    end
end

Events.OnServerCommand.Add(GAA_OnServerCommand)
