--========================================================
-- REPAIR VEHICLE ARMOR  (B42.19)
-- Client / TimedActions
--
-- Restores an existing armour panel's health to 100.
-- Material cost scales with missing HP.
-- No WeldingRods required — patching, not fabricating.
--========================================================

require "TimedActions/ISBaseTimedAction"
require "VehicleArmor_Config"
require "VehicleArmor_ConsumeHelpers"
require "VehicleArmor_ActionHelpers"

ISRepairVehicleArmor = ISBaseTimedAction:derive("ISRepairVehicleArmor")

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
-- HELPERS
----------------------------------------------------------
-- Returns the repair recipe scaled by missing HP.
-- Every listed material costs at least 1 unit if the panel
-- is damaged at all.
local function getScaledRepairRecipe(partId, grade, missingHP)
    local base = VehicleArmorConfig.getRepairRecipe(partId, grade)
    if not base then return nil end

    local ratio  = missingHP / 100
    local scaled = {}

    for mat, req in pairs(base) do
        scaled[mat] = math.max(1, math.ceil(math.floor(req) * ratio))
    end

    return scaled
end

local function getRepairRecipeForArmor(partId, armor)
    if not armor then return nil end

    local missingHP = 100 - (armor.health or 0)
    return getScaledRepairRecipe(
        partId,
        armor.grade,
        missingHP
    )
end

----------------------------------------------------------
-- VALIDITY
----------------------------------------------------------
function ISRepairVehicleArmor:isValid()
    if not self.character then return false end
    if not self.vehicle then return false end

    -- SVU4 Phase 1e position check: cannot work while seated or away from the vehicle.
    if VehicleArmor_CanStartOrContinueAction and not VehicleArmor_CanStartOrContinueAction(self.character, self.vehicle, self.partId) then return false end

    local vdata = self.vehicle:getModData()
    if not vdata.gArmor or not vdata.gArmor[self.partId] then return false end

    local armor = vdata.gArmor[self.partId]
    if (armor.health or 100) >= 100 then return false end

    if GAA_IsArmorPartLockedByOther(self.vehicle, self.partId, self.character) then return false end

    local inv = self.character:getInventory()
    if not inv then return false end

    if not VehicleArmorHelpers.hasRequiredToolsForCharacter(self.character) then return false end

    local recipe = getRepairRecipeForArmor(self.partId, armor)
    if not recipe then return false end
    if not VehicleArmorHelpers.hasRecipeForCharacter(self.character, recipe) then return false end

    local needed = VehicleArmorConfig.FuelUse.Repair[armor.grade] or 1
    local totalFuel = VehicleArmorHelpers.getTotalTorchFuel and VehicleArmorHelpers.getTotalTorchFuel(self.character) or 0
    if totalFuel < needed then return false end

    return true
end

----------------------------------------------------------
-- START
----------------------------------------------------------
function ISRepairVehicleArmor:start()
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
        self:setOverrideHandModels(torch, nil)
    end

    --------------------------------------------------
    -- Vehicle work is noisy: attract nearby zombies
    --------------------------------------------------
    VehicleArmor_MakeWorldSound(
        self.character,
        self.vehicle,
        VehicleArmor_GetSoundRadius("Repair", grade),
        VehicleArmor_GetSoundVolume("Repair")
    )

    if grade ~= "Scrap" then
        VehicleArmor_StartWeldingSound(self)
    end
    GAA_SendBeginArmorAction(self.character, self.vehicle, self.partId, "Repair")
end

----------------------------------------------------------
-- STOP / CANCEL
----------------------------------------------------------
function ISRepairVehicleArmor:stop()
    VehicleArmor_StopWeldingSound(self)
    GAA_SendClearArmorAction(self.character, self.vehicle, self.partId)
    ISBaseTimedAction.stop(self)
end

----------------------------------------------------------
-- PERFORM
----------------------------------------------------------
function ISRepairVehicleArmor:perform()
    VehicleArmor_StopWeldingSound(self)

    if not self:isValid() then
        if self.character then
            self.character:Say("Missing repair materials.")
        end
        ISBaseTimedAction.perform(self)
        return
    end

    --------------------------------------------------
    -- Multiplayer authoritative path
    --
    -- The client only requests the completed repair. The server
    -- validates current armor health, consumes materials/fuel,
    -- repairs the panel, clears gas-tank leak state if applicable,
    -- awards XP, and transmits the vehicle modData.
    --------------------------------------------------
    if GAA_IsMPClient() then
        local sent = GAA_SendArmorCommand("RepairArmor", self.vehicle, {
            partId = self.partId,
        })

        -- Clear only the optimistic local lock. Server lock is cleared
        -- by the authoritative server repair path.
        GAA_ClearLocalArmorAction(self.character, self.vehicle, self.partId)

        if sent then
            GAA_QueueMPVisualRefresh(self.vehicle, self.partId)
        end

        if self.character then
            self.character:Say(sent and "Armor repair requested." or "Unable to contact server.")
        end

        ISBaseTimedAction.perform(self)
        return
    end

    local inv       = self.character:getInventory()
    local vdata     = self.vehicle:getModData()
    local armor     = vdata.gArmor[self.partId]
    local grade     = armor.grade
    local missingHP = math.max(0, 100 - (armor.health or 0))

    --------------------------------------------------
    -- Single-player repair material consumption.
    --------------------------------------------------
    local use = VehicleArmorConfig.FuelUse.Repair[grade] or 1
    if VehicleArmorHelpers.consumeTorchFuelFromCharacter then
        VehicleArmorHelpers.consumeTorchFuelFromCharacter(self.character, use)
    else
        local torch = VehicleArmorHelpers.findTorch(self.character)
        if torch then VehicleArmorHelpers.consumeTorchFuel(torch, use) end
    end

    local recipe = getRepairRecipeForArmor(self.partId, armor)
    VehicleArmorHelpers.consumeRecipeForCharacter(self.character, recipe)

    --------------------------------------------------
    -- Apply locally and transmit the vehicle modData.
    -- Then notify the server with serializable args only.
    --------------------------------------------------
    armor.health = 100

    if self.partId == "GasTank" and vdata.gArmorGasLeak then
        vdata.gArmorGasLeak = nil
    end

    self.vehicle:transmitModData()

    local sent = GAA_SendArmorCommand("RepairArmor", self.vehicle, {
        partId = self.partId,
        clientApplied = true,  -- tells server not to consume materials again
    })

    --------------------------------------------------
    -- XP reward
    --------------------------------------------------
    VehicleArmor_AddMetalWeldingXP(
        self.character,
        VehicleArmor_GetArmorRepairXP(grade, missingHP)
    )

    VehicleArmor_AddMechanicsXP(
        self.character,
        VehicleArmor_GetArmorRepairMechanicsXP(grade, missingHP)
    )

    GAA_SendClearArmorAction(self.character, self.vehicle, self.partId)

    self.character:Say("Armor repaired.")
    ISBaseTimedAction.perform(self)
end

----------------------------------------------------------
-- NEW
----------------------------------------------------------
function ISRepairVehicleArmor:new(character, vehicle, partId, time)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index  = self
    o.vehicle     = vehicle
    o.partId      = partId
    o.stopOnWalk  = true
    o.stopOnRun   = true

    if time then
        o.maxTime = time
    else
        local vdata = vehicle:getModData()
        local armor = vdata.gArmor and vdata.gArmor[partId]
        if armor then
            local grade     = armor.grade or "Scrap"
            local baseTime  = VehicleArmorConfig.Time[grade] or 250
            local missingHP = 100 - (armor.health or 0)
            o.maxTime = math.max(50, math.floor(baseTime * (missingHP / 100)))
        else
            o.maxTime = 150
        end
    end

    return o
end
