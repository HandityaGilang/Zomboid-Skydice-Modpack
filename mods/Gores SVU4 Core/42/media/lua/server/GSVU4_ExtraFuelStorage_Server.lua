--========================================================
-- Gore's SVU4 Core - Extra Fuel Storage Server Logic
-- Manages the auxiliary fuel reserve that tops up the main tank.
--
-- How it works:
--   On install: vdata.GSVU4_fuelReserve is filled to cfg.fuelBonus litres.
--   Every INTERVAL ticks (while player is driving):
--     If main tank < script capacity AND reserve > 0:
--       Transfer up to TRANSFER_RATE litres from reserve into main.
--       transmitPartModData so clients see the updated fuel level.
--   Net effect: mechanics screen shows near-full tank until reserve empties.
--========================================================

local GSVU4_EFS_INTERVAL      = 30   -- ticks between checks (same as gas leak)
local GSVU4_EFS_TRANSFER_RATE = 0.5  -- max litres transferred per interval
local GSVU4_EFS_Timers        = {}

local function GSVU4_GetVehicleKey(vehicle)
    if not vehicle then return nil end
    local uid = "0"
    if vehicle.getUniqueId then uid = tostring(vehicle:getUniqueId())
    elseif vehicle.getId    then uid = tostring(vehicle:getId()) end
    return "gsvu4efs_"
        .. math.floor(vehicle:getX()) .. "_"
        .. math.floor(vehicle:getY()) .. "_"
        .. uid
end

local function GSVU4_IsDriver(character, vehicle)
    if not character or not vehicle then return false end
    if character.isDriver then
        local ok, r = pcall(function() return character:isDriver() end)
        if ok and r ~= nil then return r == true end
    end
    if vehicle.getDriver then
        local ok, d = pcall(function() return vehicle:getDriver() end)
        if ok and d then return d == character end
    end
    return false
end

local function GSVU4_ProcessFuelReserve(vehicle)
    if not vehicle then return end

    local vdata = vehicle:getModData()
    if not vdata then return end

    -- Only process if ExtraFuelStorage is installed with a reserve
    local upgrade = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
    if not upgrade then return end

    local reserve = tonumber(vdata.GSVU4_fuelReserve) or 0
    if reserve < 0.001 then return end

    local gasPart = vehicle.getPartById and vehicle:getPartById("GasTank")
    if not gasPart then return end
    if not gasPart.getContainerContentAmount then return end
    if not gasPart.getContainerCapacity then return end

    local current = tonumber(gasPart:getContainerContentAmount()) or 0
    local cap     = tonumber(gasPart:getContainerCapacity()) or 0
    if cap <= 0 then return end

    local space = cap - current
    if space < 0.001 then return end  -- main tank already full

    -- Transfer from reserve into main tank
    local transfer = math.min(reserve, space, GSVU4_EFS_TRANSFER_RATE)
    if transfer < 0.001 then return end

    local newMain    = math.min(cap, current + transfer)
    local newReserve = math.max(0, reserve - transfer)

    if gasPart.setContainerContentAmount then
        gasPart:setContainerContentAmount(newMain)
    end

    vdata.GSVU4_fuelReserve = newReserve

    -- Sync to clients
    if vehicle.transmitPartModData then
        vehicle:transmitPartModData(gasPart)
    end
    vehicle:transmitModData()
end

local function GSVU4_OnPlayerUpdateEFS(character)
    if not character then return end
    local vehicle = character.getVehicle and character:getVehicle()
    if not vehicle then return end
    if not GSVU4_IsDriver(character, vehicle) then return end

    local key = GSVU4_GetVehicleKey(vehicle)
    if not key then return end

    GSVU4_EFS_Timers[key] = (GSVU4_EFS_Timers[key] or 0) + 1
    if GSVU4_EFS_Timers[key] < GSVU4_EFS_INTERVAL then return end
    GSVU4_EFS_Timers[key] = 0

    GSVU4_ProcessFuelReserve(vehicle)
end

Events.OnPlayerUpdate.Add(GSVU4_OnPlayerUpdateEFS)

-- Run immediately when entering a vehicle (reset timer for instant response)
local function GSVU4_OnEnterVehicleEFS(character)
    if not character then return end
    local vehicle = character.getVehicle and character:getVehicle()
    if vehicle then
        local key = GSVU4_GetVehicleKey(vehicle)
        if key then GSVU4_EFS_Timers[key] = GSVU4_EFS_INTERVAL end  -- trigger on next update
    end
end

Events.OnEnterVehicle.Add(GSVU4_OnEnterVehicleEFS)

-- Expose a function so the config can fill the reserve on install/uninstall
function GSVU4_SetFuelReserve(vehicle, amount)
    if not vehicle or not vehicle.getModData then return end
    local vdata = vehicle:getModData()
    vdata.GSVU4_fuelReserve = math.max(0, tonumber(amount) or 0)
    vehicle:transmitModData()
end

-- Handle client commands for EFS
local function GSVU4_OnClientCommandEFS(module, command, player, args)
    if module ~= "GoresSVU4Core" then return end

    -- Give the player an empty version of a fluid container they just used
    if command == "GiveEmptyContainer" then
        if not player or not args or not args.fullType then return end
        local fullType = tostring(args.fullType)
        -- Validate: only allow known fluid container types (security check)
        local typeLower = fullType:lower()
        local isFluidContainer = typeLower:find("can")
            or typeLower:find("bottle")
            or typeLower:find("canteen")
            or typeLower:find("flask")
            or typeLower:find("jug")
            or typeLower:find("petrol")
            or typeLower:find("jerry")
            or typeLower:find("water")
        if not isFluidContainer then
            return
        end
        local inv = player:getInventory()
        if inv then
            -- AddItem creates a new item - get it back so we can empty its FluidContainer
            local newItem = nil
            local ok, err = pcall(function()
                newItem = inv:AddItem(fullType)
            end)
            if not (ok and newItem) then
                -- AddItem may not return the item on all versions - find it by checking
                -- the last added item
                local ok2, err2 = pcall(function() inv:AddItem(fullType) end)
                ok = ok2
                err = err2
            end

            if newItem then
                -- Drain the FluidContainer using ISFluidEmptyAction
                -- This goes through the game engine properly and syncs to clients
                local fc = nil
                if newItem.getFluidContainer then
                    local okFC, f = pcall(function() return newItem:getFluidContainer() end)
                    if okFC and f then fc = f end
                end
                if fc and ISFluidEmptyAction then
                    local action = ISFluidEmptyAction:new(player, fc)
                    if action then
                        ISTimedActionQueue.add(action)
                    end
                else
                end
            else
            end
        end
        return
    end

    if command ~= "SeedEFSReserve" then return end
    if not player or not args then return end

    -- Find the vehicle near the specified coords
    local px = tonumber(args.vehicleX)
    local py = tonumber(args.vehicleY)
    if not px or not py then return end

    -- Get vehicle from player's current vehicle (safest approach in B42)
    local vehicle = player.getVehicle and player:getVehicle()
    if not vehicle then return end

    -- Verify coords roughly match
    if math.abs(vehicle:getX() - px) > 5 or math.abs(vehicle:getY() - py) > 5 then return end

    local vdata = vehicle:getModData()
    local upgrade = vdata and vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
    if not upgrade then return end

    if GSVU4UpgradesConfig and GSVU4UpgradesConfig.applyExtraFuelStorage then
        GSVU4UpgradesConfig.applyExtraFuelStorage(vehicle)
        vehicle:transmitModData()
    end
end

Events.OnClientCommand.Add(GSVU4_OnClientCommandEFS)
