--========================================================
-- WELD VEHICLE ARMOR  (B42.19)
-- Client / TimedActions
--
-- Installs a new armour panel onto a vehicle part.
-- Requires: BlowTorch fuel, WeldingMask, Hammer, and
-- grade-appropriate materials.
--========================================================

require "TimedActions/ISBaseTimedAction"
require "VehicleArmor_Config"
require "VehicleArmor/VehicleArmor_Visuals"
require "VehicleArmor_ConsumeHelpers"
require "VehicleArmor_ActionHelpers"

ISWeldVehicleArmor = ISBaseTimedAction:derive("ISWeldVehicleArmor")

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
function ISWeldVehicleArmor:_failValid(reason)
    self._lastInvalidReason = tostring(reason or "unknown")
    return false
end

function ISWeldVehicleArmor:isValid()
    if not self.character then return self:_failValid("missing character") end
    if not self.vehicle then return self:_failValid("missing vehicle") end
    if not self.partId then return self:_failValid("missing partId") end
    if not self.grade then return self:_failValid("missing grade") end
    if not self.vehicle:getPartById(self.partId) then return self:_failValid("vehicle part not found") end

    -- SVU4 Phase 1e position check: cannot work while seated or away from the vehicle.
    if VehicleArmor_CanStartOrContinueAction and not VehicleArmor_CanStartOrContinueAction(self.character, self.vehicle, self.partId) then
        return self:_failValid("position/vehicle access check failed")
    end

    local vdata = self.vehicle:getModData()
    if vdata.gArmor and vdata.gArmor[self.partId] then return self:_failValid("armor already installed") end

    if GAA_IsArmorPartLockedByOther(self.vehicle, self.partId, self.character) then return self:_failValid("part locked by other action") end

    local inv = self.character:getInventory()
    if not inv then return self:_failValid("missing inventory") end

    if not VehicleArmorHelpers.hasRequiredToolsForCharacter(self.character, self.grade) then return self:_failValid("missing required tools") end

    local recipe = VehicleArmorConfig.getInstallRecipe(self.partId, self.grade)
    if not recipe then return self:_failValid("missing install recipe") end
    if not VehicleArmorHelpers.hasRecipeForCharacter(self.character, recipe) then return self:_failValid("missing required materials") end

    local needed = VehicleArmorConfig.getInstallFuelUse and VehicleArmorConfig.getInstallFuelUse(self.partId, self.grade) or (VehicleArmorConfig.FuelUse.Install[self.grade] or 0)
    local totalFuel = VehicleArmorHelpers.getTotalTorchFuel and VehicleArmorHelpers.getTotalTorchFuel(self.character) or 0
    if needed > 0 and totalFuel <= 0 then return self:_failValid("missing blowtorch") end
    if needed > 0 and totalFuel < needed then return self:_failValid("not enough blowtorch fuel: total=" .. tostring(totalFuel) .. " needed=" .. tostring(needed)) end

    if VehicleArmorHelpers and VehicleArmorHelpers.hasSkillRequirements then
        if not VehicleArmorHelpers.hasSkillRequirements(self.character, self.grade) then
            return self:_failValid("missing skill requirements")
        end
    end

    return true
end

----------------------------------------------------------
-- START
----------------------------------------------------------
function ISWeldVehicleArmor:start()
    local grade = self.grade or "Scrap"

    if grade == "Scrap" then
        self:setActionAnim("Loot")
        self:setOverrideHandModels(nil, nil)
    else
        self:setActionAnim("BlowTorch")
        local torch = VehicleArmorHelpers.findTorch(self.character)
        self:setOverrideHandModels(torch, nil)
    end

    --------------------------------------------------
    -- Metalwork is noisy: attract nearby zombies
    --------------------------------------------------
    VehicleArmor_MakeWorldSound(
        self.character,
        self.vehicle,
        VehicleArmor_GetSoundRadius("Install", grade),
        VehicleArmor_GetSoundVolume("Install")
    )

    if grade ~= "Scrap" then
        VehicleArmor_StartWeldingSound(self)
    end
    GAA_SendBeginArmorAction(self.character, self.vehicle, self.partId, "Install")
end

----------------------------------------------------------
-- STOP / CANCEL
----------------------------------------------------------
function ISWeldVehicleArmor:stop()
    VehicleArmor_StopWeldingSound(self)
    GAA_SendClearArmorAction(self.character, self.vehicle, self.partId)
    ISBaseTimedAction.stop(self)
end

----------------------------------------------------------
-- PERFORM
----------------------------------------------------------
function ISWeldVehicleArmor:perform()
    VehicleArmor_StopWeldingSound(self)

    if not self:isValid() then
        if self.character then
            self.character:Say("Missing required materials.")
        end
        ISBaseTimedAction.perform(self)
        return
    end

    --------------------------------------------------
    -- Multiplayer authoritative path
    --
    -- In MP the client timed action only requests the
    -- completed armor operation. The server owns the final
    -- material/fuel consumption, vehicle modData update, XP,
    -- mass refresh, and confirmation. This avoids inventory
    -- and vehicle-state desync when a server command is delayed
    -- or a vehicle lookup fails.
    --------------------------------------------------
    if GAA_IsMPClient() then
        local sent = GAA_SendArmorCommand("InstallArmor", self.vehicle, {
            partId = self.partId,
            grade  = self.grade,
        })

        -- Clear only the optimistic local lock. Do not send a server
        -- clear here; the server keeps its action lock until it
        -- accepts or rejects the authoritative command.
        GAA_ClearLocalArmorAction(self.character, self.vehicle, self.partId)

        if sent then
            GAA_QueueMPVisualRefresh(self.vehicle, self.partId)
        end

        if self.character then
            self.character:Say(sent and "Armor install requested." or "Unable to contact server.")
        end

        ISBaseTimedAction.perform(self)
        return
    end

    local inv   = self.character:getInventory()
    local vdata = self.vehicle:getModData()

    --------------------------------------------------
    -- Single-player local path
    --------------------------------------------------
    local use = VehicleArmorConfig.getInstallFuelUse and VehicleArmorConfig.getInstallFuelUse(self.partId, self.grade) or (VehicleArmorConfig.FuelUse.Install[self.grade] or 0)
    if use > 0 then
        if VehicleArmorHelpers.consumeTorchFuelFromCharacter then
            VehicleArmorHelpers.consumeTorchFuelFromCharacter(self.character, use)
        else
            local torch = VehicleArmorHelpers.findTorch(self.character)
            if torch then VehicleArmorHelpers.consumeTorchFuel(torch, use) end
        end
    end

    local recipe = VehicleArmorConfig.getInstallRecipe(self.partId, self.grade)
    VehicleArmorHelpers.consumeRecipeForCharacter(self.character, recipe)

    --------------------------------------------------
    -- Apply locally and transmit the vehicle modData.
    -- Then notify the server with serializable args only.
    --------------------------------------------------
    vdata.gArmor = vdata.gArmor or {}
    vdata.gArmor[self.partId] = {
        grade  = self.grade,
        health = 100,
    }
    self.vehicle:transmitModData()

    local sent = GAA_SendArmorCommand("InstallArmor", self.vehicle, {
        partId = self.partId,
        grade  = self.grade,
        clientApplied = true,  -- tells server not to consume materials again
    })

    --------------------------------------------------
    -- Award MetalWelding and Mechanics XP
    --------------------------------------------------
    VehicleArmor_AddMetalWeldingXP(
        self.character,
        VehicleArmor_GetArmorInstallXP(self.grade)
    )

    VehicleArmor_AddMechanicsXP(
        self.character,
        VehicleArmor_GetArmorInstallMechanicsXP(self.grade)
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

    self.character:Say("Armor installed.")
    ISBaseTimedAction.perform(self)
end

----------------------------------------------------------
-- NEW
----------------------------------------------------------
function ISWeldVehicleArmor:new(character, vehicle, partId, grade, time)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index  = self
    o.vehicle     = vehicle
    o.partId      = partId
    o.grade       = grade
    o.stopOnWalk  = true
    o.stopOnRun   = true
    o.maxTime     = time or VehicleArmorConfig.Time[grade] or 250
    return o
end
