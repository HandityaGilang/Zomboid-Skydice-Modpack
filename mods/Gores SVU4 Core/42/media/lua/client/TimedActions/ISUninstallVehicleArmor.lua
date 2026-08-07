--========================================================
-- UNINSTALL VEHICLE ARMOR  (B42.19)
-- Client / TimedActions
--
-- Removes an armour panel and returns fixed flat materials
-- defined in VehicleArmorConfig.UninstallReturn.
-- WeldingRods are never returned (consumed in the weld).
--========================================================

require "TimedActions/ISBaseTimedAction"
require "VehicleArmor_Config"
require "VehicleArmor/VehicleArmor_Visuals"
require "VehicleArmor_ConsumeHelpers"
require "VehicleArmor_ActionHelpers"

ISUninstallVehicleArmor = ISBaseTimedAction:derive("ISUninstallVehicleArmor")

local function GAA_IsMPClient()
    return isClient and isClient()
end


local function GAA_QueueMPVisualRefresh(vehicle, partId)
    -- In multiplayer the timed action does not modify gArmor locally; the
    -- server applies/transmits it. Queue a longer local visual retry so the
    -- client can apply VV visuals as soon as the authoritative modData arrives,
    -- without requiring the player to enter the vehicle.
    if vehicle and VehicleArmorVisuals and VehicleArmorVisuals.QueueApply then
        VehicleArmorVisuals.QueueApply(vehicle, partId, 3, 20)
    end
end

local function GAA_AddVehicleCommandArgs(args, vehicle)
    args = args or {}

    -- Do not send the BaseVehicle Java object through MP commands.
    -- B42 multiplayer command args must be serialisable primitives/tables.
    -- Sending args.vehicle causes: sendClientCommand: can't save key,value=vehicle
    if vehicle then
        if vehicle.getId then
            local ok, value = pcall(function() return vehicle:getId() end)
            if ok and value ~= nil then args.vehicleId = tonumber(value) or tostring(value) end
        end
        if vehicle.getOnlineID then
            local ok, value = pcall(function() return vehicle:getOnlineID() end)
            if ok and value ~= nil then args.vehicleOnlineId = tonumber(value) or tostring(value) end
        end
        if vehicle.getX then
            local ok, value = pcall(function() return vehicle:getX() end)
            if ok and value ~= nil then args.vehicleX = tonumber(value) end
        end
        if vehicle.getY then
            local ok, value = pcall(function() return vehicle:getY() end)
            if ok and value ~= nil then args.vehicleY = tonumber(value) end
        end
        if vehicle.getZ then
            local ok, value = pcall(function() return vehicle:getZ() end)
            if ok and value ~= nil then args.vehicleZ = tonumber(value) end
        end
    end

    return args
end

local function GAA_SendArmorCommand(command, vehicle, args)
    args = GAA_AddVehicleCommandArgs(args, vehicle)

    if isClient and isClient() and sendClientCommand then
        sendClientCommand("GoresSVU4Core", command, args)
        return true
    end

    return false
end


local function GAA_GetArmorActionOwner(character)
    if character and character.getUsername then
        local ok, username = pcall(function()
            return character:getUsername()
        end)
        if ok and username then
            return tostring(username)
        end
    end

    return "local"
end

local function GAA_GetArmorLock(vehicle, partId)
    if not vehicle or not partId then return nil end
    local vdata = vehicle:getModData()
    return vdata and vdata.gArmorLocks and vdata.gArmorLocks[partId]
end

local function GAA_IsArmorPartLockedByOther(vehicle, partId, character)
    local lock = GAA_GetArmorLock(vehicle, partId)
    if not lock then return false end

    return lock.owner ~= GAA_GetArmorActionOwner(character)
end

local function GAA_SendBeginArmorAction(character, vehicle, partId, action)
    local owner = GAA_GetArmorActionOwner(character)

    -- Optimistic local lock for immediate same-client validity.
    local vdata = vehicle and vehicle:getModData()
    if vdata then
        vdata.gArmorLocks = vdata.gArmorLocks or {}
        vdata.gArmorLocks[partId] = {
            owner  = owner,
            action = action or "unknown",
        }
    end

    GAA_SendArmorCommand("BeginArmorAction", vehicle, {
        partId = partId,
        action = action or "unknown",
    })
end

local function GAA_SendClearArmorAction(character, vehicle, partId)
    local owner = GAA_GetArmorActionOwner(character)

    local vdata = vehicle and vehicle:getModData()
    if vdata and vdata.gArmorLocks then
        local lock = vdata.gArmorLocks[partId]
        if lock and lock.owner == owner then
            vdata.gArmorLocks[partId] = nil
        end
    end

    GAA_SendArmorCommand("ClearArmorAction", vehicle, {
        partId = partId,
    })
end

local function GAA_ClearLocalArmorAction(character, vehicle, partId)
    local owner = GAA_GetArmorActionOwner(character)

    local vdata = vehicle and vehicle:getModData()
    if vdata and vdata.gArmorLocks then
        local lock = vdata.gArmorLocks[partId]
        if lock and lock.owner == owner then
            vdata.gArmorLocks[partId] = nil
        end
    end
end


----------------------------------------------------------
-- VALIDITY
----------------------------------------------------------
function ISUninstallVehicleArmor:isValid()
    if not self.character then return false end
    if not self.vehicle then return false end

    -- SVU4 Phase 1e position check: cannot work while seated or away from the vehicle.
    if VehicleArmor_CanStartOrContinueAction and not VehicleArmor_CanStartOrContinueAction(self.character, self.vehicle, self.partId) then return false end

    local vdata = self.vehicle:getModData()
    if not vdata.gArmor or not vdata.gArmor[self.partId] then return false end

    if GAA_IsArmorPartLockedByOther(self.vehicle, self.partId, self.character) then return false end

    local inv = self.character:getInventory()
    if not inv then return false end

    -- Uninstall currently needs torch fuel only. Hammer/mask
    -- requirements are intentionally left unchanged from the
    -- previous gameplay behaviour.
    local grade  = vdata.gArmor[self.partId].grade
    local needed = VehicleArmorConfig.FuelUse.Uninstall[grade] or 1
    local availableFuel = 0
    if VehicleArmorHelpers.getTotalTorchFuel then
        availableFuel = VehicleArmorHelpers.getTotalTorchFuel(self.character)
    else
        local torch  = VehicleArmorHelpers.findTorch(self.character)
        availableFuel = torch and VehicleArmorHelpers.getTorchFuel(torch) or 0
    end
    if availableFuel < needed then return false end

    return true
end

----------------------------------------------------------
-- START
----------------------------------------------------------
function ISUninstallVehicleArmor:start()
    local grade = "Scrap"
    if self.vehicle then
        local vdata = self.vehicle:getModData()
        local armor = vdata.gArmor and vdata.gArmor[self.partId]
        if armor and armor.grade then
            grade = armor.grade
        end
    end

    if grade == "Scrap" then
        self:setActionAnim("Loot")
        self:setOverrideHandModels(nil, nil)
    else
        self:setActionAnim("BlowTorch")
        local torch = VehicleArmorHelpers.findTorch(self.character)
        if torch then
            pcall(function()
                self:setOverrideHandModels(torch, nil)
            end)
        end
    end

    --------------------------------------------------
    -- Vehicle work is noisy: attract nearby zombies
    --------------------------------------------------
    VehicleArmor_MakeWorldSound(
        self.character,
        self.vehicle,
        VehicleArmor_GetSoundRadius("Uninstall", grade),
        VehicleArmor_GetSoundVolume("Uninstall")
    )

    if grade ~= "Scrap" then
        VehicleArmor_StartWeldingSound(self)
    end
    GAA_SendBeginArmorAction(self.character, self.vehicle, self.partId, "Uninstall")

end

----------------------------------------------------------
-- STOP / CANCEL
----------------------------------------------------------
function ISUninstallVehicleArmor:stop()
    VehicleArmor_StopWeldingSound(self)
    GAA_SendClearArmorAction(self.character, self.vehicle, self.partId)
    ISBaseTimedAction.stop(self)
end

----------------------------------------------------------
-- PERFORM
----------------------------------------------------------
function ISUninstallVehicleArmor:perform()
    VehicleArmor_StopWeldingSound(self)
    if not self:isValid() then
        if self.character then
            self.character:Say("Missing required tools or materials.")
        end
        ISBaseTimedAction.perform(self)
        return
    end

    --------------------------------------------------
    -- Multiplayer authoritative path
    --
    -- The client only requests the completed uninstall. The server
    -- consumes fuel, removes armor modData, creates real server-owned
    -- refund items, awards XP, refreshes mass, and transmits state.
    --------------------------------------------------
    if GAA_IsMPClient() then
        local vdataMP = self.vehicle:getModData()
        local armorMP = vdataMP and vdataMP.gArmor and vdataMP.gArmor[self.partId]
        local gradeMP = armorMP and armorMP.grade or nil

        local sent = GAA_SendArmorCommand("UninstallArmor", self.vehicle, {
            partId = self.partId,
            grade  = gradeMP,
        })

        -- Clear only the optimistic local lock. Server lock is cleared
        -- by the authoritative server uninstall path.
        GAA_ClearLocalArmorAction(self.character, self.vehicle, self.partId)

        if sent then
            GAA_QueueMPVisualRefresh(self.vehicle, self.partId)
        end

        if self.character then
            self.character:Say(sent and "Armor removal requested." or "Unable to contact server.")
        end

        ISBaseTimedAction.perform(self)
        return
    end

    local inv   = self.character:getInventory()
    local vdata = self.vehicle:getModData()
    if not inv then
        ISBaseTimedAction.perform(self)
        return
    end
    local armor = vdata.gArmor[self.partId]
    local grade = armor.grade

    --------------------------------------------------
    -- Single-player blowtorch fuel drain + salvage return.
    --------------------------------------------------
    local use = VehicleArmorConfig.FuelUse.Uninstall[grade] or 1
    if VehicleArmorHelpers.consumeTorchFuelFromCharacter then
        VehicleArmorHelpers.consumeTorchFuelFromCharacter(self.character, use)
    else
        local torch = VehicleArmorHelpers.findTorch(self.character)
        if torch then VehicleArmorHelpers.consumeTorchFuel(torch, use) end
    end

    local returns = VehicleArmorConfig.getUninstallReturn(self.partId, grade)

    --------------------------------------------------
    -- MP refund safety:
    -- In multiplayer, refunded items must be created by
    -- the server. Creating them here produces client-only
    -- ghost items that appear in the main inventory but
    -- cannot be moved to another container.
    --
    -- Single-player still refunds locally because there is
    -- no server command path to create the returned items.
    --------------------------------------------------
    if returns and not GAA_IsMPClient() then
        for mat, qty in pairs(returns) do
            for _ = 1, qty do
                if     mat == "scrap"  then inv:AddItem("Base.ScrapMetal")
                elseif mat == "sheets" then inv:AddItem("Base.SheetMetal")
                elseif mat == "bars"   then inv:AddItem("Base.MetalBar")
                elseif mat == "screws" then inv:AddItem("Base.Screws")
                elseif mat == "wire"   then inv:AddItem("Base.Wire")
                end
            end
        end
    end

    --------------------------------------------------
    -- Apply locally and transmit the vehicle modData.
    -- Then notify the server with serializable args only.
    --------------------------------------------------
    vdata.gArmor[self.partId] = nil

    -- Do not clear gArmorGasLeak here. If GasTank armour was
    -- destroyed, the tank has already been punctured.
    self.vehicle:transmitModData()

    local sent = GAA_SendArmorCommand("UninstallArmor", self.vehicle, {
        partId = self.partId,
        grade  = grade,
        clientApplied = true,  -- tells server not to give returns twice
    })

    --------------------------------------------------
    -- XP reward
    --------------------------------------------------
    VehicleArmor_AddMetalWeldingXP(
        self.character,
        VehicleArmor_GetArmorUninstallXP(grade)
    )

    VehicleArmor_AddMechanicsXP(
        self.character,
        VehicleArmor_GetArmorUninstallMechanicsXP(grade)
    )

    if VehicleArmorVisuals then
        if VehicleArmorVisuals.ApplyToPart then
            VehicleArmorVisuals.ApplyToPart(self.vehicle, self.partId)
        end
        if VehicleArmorVisuals.QueueApply then
            VehicleArmorVisuals.QueueApply(self.vehicle, self.partId)
        end
        if VehicleArmorVisuals.ForceInstalled then
            VehicleArmorVisuals.ForceInstalled(self.vehicle)
        end
    end

    if VehicleArmor_UpdateMass then
        VehicleArmor_UpdateMass(self.vehicle)
    end

    GAA_SendClearArmorAction(self.character, self.vehicle, self.partId)

    self.character:Say("Armor removed. Salvage recovered.")
    ISBaseTimedAction.perform(self)
end

----------------------------------------------------------
-- NEW
----------------------------------------------------------
function ISUninstallVehicleArmor:new(character, vehicle, partId, time)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index  = self
    o.vehicle     = vehicle
    o.partId      = partId
    o.stopOnWalk  = true
    o.stopOnRun   = true
    o.maxTime     = time or 200
    return o
end
