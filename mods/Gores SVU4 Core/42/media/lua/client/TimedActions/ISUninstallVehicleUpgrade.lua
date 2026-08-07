--========================================================
-- UNINSTALL VEHICLE UPGRADE  (B42.19)
-- Client / TimedActions
--
-- Adds a real timed action before the authoritative upgrade
-- uninstall command is sent. Tyre chains retain their own
-- dedicated timed-action implementation.
--========================================================

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "GoresSVU4Core/GSVU4_EngineScoop"
require "GoresSVU4Core/GSVU4_FilteredAirIntake"
require "VehicleArmor_ActionHelpers"
require "VehicleArmor_ConsumeHelpers"
pcall(require, "VehicleArmor/VehicleArmor_Visuals")

ISUninstallVehicleUpgrade = ISBaseTimedAction:derive("ISUninstallVehicleUpgrade")
GSVU4Core = GSVU4Core or {}

local function isMPClient()
    return isClient and isClient()
end

local function addVehicleArgs(args, vehicle)
    args = args or {}
    if not vehicle then return args end

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

    return args
end

local function getInstalledUpgrade(vehicle, upgradeId)
    if GSVU4UpgradesConfig and GSVU4UpgradesConfig.getInstalledUpgrade then
        return GSVU4UpgradesConfig.getInstalledUpgrade(vehicle, upgradeId)
    end
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    return md and md.gUpgrades and md.gUpgrades[upgradeId] or nil
end

local function getGradeConfig(upgradeId, grade)
    if GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig then
        return GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
    end
    return nil
end

local function getUpgradeDefinition(upgradeId)
    if GSVU4UpgradesConfig and GSVU4UpgradesConfig.getUpgrade then
        return GSVU4UpgradesConfig.getUpgrade(upgradeId)
    end
    return nil
end

local function usesWelding(upgradeId, grade)
    local cfg = getGradeConfig(upgradeId, grade) or {}
    local def = getUpgradeDefinition(upgradeId) or {}
    local tools = cfg.tools or def.tools or {}
    return (tonumber(cfg.fuelUse) or 0) > 0
        or tools.blowTorch == true
        or tools.weldingMask == true
end

local function giveLocalReturns(character, cfg, health)
    if not character or not cfg then return end
    local inv = character.getInventory and character:getInventory() or nil
    if not inv then return end

    health = tonumber(health) or 0
    local maxHealth = tonumber(cfg.health) or 100
    local healthPercent = maxHealth > 0 and (health / maxHealth) * 100 or 0
    if healthPercent < 50 then
        inv:AddItem("Base.ScrapMetal")
        inv:AddItem("Base.ScrapMetal")
        return
    end

    local recipe = cfg.recipe or {}
    local function giveMany(fullType, count)
        count = math.floor(tonumber(count) or 0)
        for _ = 1, count do inv:AddItem(fullType) end
    end

    giveMany("Base.ScrapMetal", math.floor((recipe.scrap or 0) * 0.5))
    giveMany("Base.SheetMetal", math.floor((recipe.sheets or 0) * 0.5))
    giveMany("Base.MetalBar", math.floor((recipe.bars or 0) * 0.5))
    giveMany("Base.Screws", math.floor((recipe.screws or 0) * 0.5))
    giveMany("Base.Wire", math.floor((recipe.wire or 0) * 0.5))
    giveMany("Base.ElectricWire", math.floor((recipe.electricWire or 0) * 0.5))
    giveMany("Base.LightBulb", math.floor((recipe.bulbs or 0) * 0.5))
    giveMany("Base.GSVU4AutoTuneMilitaryRadio", math.floor((recipe.autoTuneMilitaryRadio or 0) * 1.0))
end

local function applyLocalRemoval(vehicle, upgradeId, current)
    if not vehicle or not upgradeId or not current then return false, "Upgrade unavailable." end
    local md = vehicle:getModData()
    md.gUpgrades = md.gUpgrades or {}

    local cfg = getGradeConfig(upgradeId, current.grade)

    -- Restore the original cargo capacity before removing the auxiliary tank
    -- or granting salvage. A failed restore leaves the upgrade installed.
    if upgradeId == "ExtraFuelStorage"
    and GSVU4UpgradesConfig
    and GSVU4UpgradesConfig.removeExtraFuelStorage then
        local okCall, restored, reason = pcall(function()
            return GSVU4UpgradesConfig.removeExtraFuelStorage(vehicle)
        end)
        if not okCall or restored ~= true then
            return false, reason or "Unable to restore the original cargo capacity."
        end
    else
        md.gUpgrades[upgradeId] = nil
    end
    if upgradeId == "EngineScoop" then
        md.gEngineScoopRuntime = nil
    end

    local player = getPlayer and getPlayer() or nil
    giveLocalReturns(player, cfg, current.health or 100)
    if upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
        GSVU4FilteredAirIntake.returnInstalledFilterMedia(player, current)
        if GSVU4FilteredAirIntake.clearRuntimeStatus then
            GSVU4FilteredAirIntake.clearRuntimeStatus(vehicle)
        end
    end

    if upgradeId == "RoofRack" and GSVU4_DrainRoofRackContainer then
        pcall(function() GSVU4_DrainRoofRackContainer(vehicle, getPlayer and getPlayer() or nil) end)
    end

    if md.gExternalStorage and upgradeId == "RoofRack" then
        md.gExternalStorage.RoofRack = nil
    end

    if vehicle.transmitModData then pcall(function() vehicle:transmitModData() end) end
    if VehicleArmor_UpdateMass then pcall(function() VehicleArmor_UpdateMass(vehicle) end) end

    if GSVU4Core and GSVU4Core.ApplyUpgradeVisualState then
        pcall(function() GSVU4Core.ApplyUpgradeVisualState(vehicle, upgradeId) end)
    elseif GSVU4Core and GSVU4Core.ApplyExternalUpgradeVisualPacks then
        pcall(function() GSVU4Core.ApplyExternalUpgradeVisualPacks(vehicle, upgradeId, "Removed") end)
    end

    if GSVU4Core and GSVU4Core.QueueUpgradeVisualState then
        pcall(function() GSVU4Core.QueueUpgradeVisualState(vehicle, upgradeId, 3, 15) end)
    end

    return true, nil
end

function ISUninstallVehicleUpgrade:isValid()
    if not self.character or not self.vehicle or not self.upgradeId then return false end

    if VehicleArmor_CanStartOrContinueAction
    and not VehicleArmor_CanStartOrContinueAction(self.character, self.vehicle, nil) then
        return false
    end

    return getInstalledUpgrade(self.vehicle, self.upgradeId) ~= nil
end

function ISUninstallVehicleUpgrade:update()
    if self.character and self.vehicle then
        if self.character.faceThisObject then
            pcall(function() self.character:faceThisObject(self.vehicle) end)
        elseif self.character.faceLocation and self.vehicle.getX and self.vehicle.getY then
            pcall(function() self.character:faceLocation(self.vehicle:getX(), self.vehicle:getY()) end)
        end
    end
end

function ISUninstallVehicleUpgrade:start()
    if self.useWelding then
        self:setActionAnim("BlowTorch")
        if VehicleArmorHelpers and VehicleArmorHelpers.findTorch then
            local torch = VehicleArmorHelpers.findTorch(self.character)
            if torch then pcall(function() self:setOverrideHandModels(torch, nil) end) end
        end
        if VehicleArmor_StartWeldingSound then VehicleArmor_StartWeldingSound(self) end
        if VehicleArmor_MakeWorldSound then
            VehicleArmor_MakeWorldSound(
                self.character,
                self.vehicle,
                VehicleArmor_GetSoundRadius and VehicleArmor_GetSoundRadius("Uninstall", "Standard") or 20,
                VehicleArmor_GetSoundVolume and VehicleArmor_GetSoundVolume("Uninstall") or 10
            )
        end
    else
        self:setActionAnim("Loot")
    end
end

function ISUninstallVehicleUpgrade:stop()
    if self.useWelding and VehicleArmor_StopWeldingSound then
        VehicleArmor_StopWeldingSound(self)
    end
    ISBaseTimedAction.stop(self)
end

function ISUninstallVehicleUpgrade:perform()
    if self.useWelding and VehicleArmor_StopWeldingSound then
        VehicleArmor_StopWeldingSound(self)
    end

    if not self:isValid() then
        if self.character and self.character.Say then
            self.character:Say("Upgrade removal cancelled.")
        end
        ISBaseTimedAction.perform(self)
        return
    end

    local current = getInstalledUpgrade(self.vehicle, self.upgradeId)
    if not current then
        ISBaseTimedAction.perform(self)
        return
    end

    if isMPClient() and sendClientCommand then
        sendClientCommand(
            "GoresSVU4Core",
            "UninstallUpgrade",
            addVehicleArgs({ upgradeId = self.upgradeId }, self.vehicle)
        )

        if GSVU4Core
        and GSVU4Core.ReleaseVehicleVisualState then
            GSVU4Core.ReleaseVehicleVisualState(
                self.vehicle,
                "local-uninstall-request:" .. tostring(self.upgradeId)
            )
        end

        if self.character and self.character.Say then
            self.character:Say("Upgrade removal requested.")
        end
    else
        local removed, reason = applyLocalRemoval(self.vehicle, self.upgradeId, current)
        if self.character and self.character.Say then
            self.character:Say(removed and "Upgrade removed." or (reason or "Upgrade removal failed."))
        end
    end

    ISBaseTimedAction.perform(self)
end

function ISUninstallVehicleUpgrade:new(character, vehicle, upgradeId, grade, time)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self

    o.character = character
    o.vehicle = vehicle
    o.upgradeId = upgradeId
    o.grade = grade
    o.useWelding = usesWelding(upgradeId, grade)
    o.maxTime = tonumber(time) or 200
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = false

    return o
end

local function getUpgradeWorkPart(upgradeId)
    if GSVU4Core and GSVU4Core.GetUpgradeWorkPart then
        return GSVU4Core.GetUpgradeWorkPart(upgradeId)
    end

    if upgradeId == "RoofRack"
    or upgradeId == "RoofLightsLeft"
    or upgradeId == "AutoTuneMilitaryRadio" then
        return "DoorFrontLeft"
    end
    if upgradeId == "RoofLightsRight" then
        return "DoorFrontRight"
    end
    if upgradeId == "ExtraFuelStorage"
    or upgradeId == "JerryCanSlots"
    or upgradeId == "RoofLightsRear" then
        return "TrunkDoor"
    end
    return "EngineDoor"
end

function GSVU4Core.GetUpgradeUninstallTime(upgradeId, grade)
    local cfg = getGradeConfig(upgradeId, grade) or {}
    return tonumber(cfg.uninstallTime) or tonumber(cfg.time) or 200
end

function GSVU4Core.QueueUpgradeUninstallTimedAction(character, vehicle, upgradeId)
    if not character or not vehicle or not upgradeId then return false end

    local current = getInstalledUpgrade(vehicle, upgradeId)
    if not current or not current.grade then return false end

    local action = ISUninstallVehicleUpgrade:new(
        character,
        vehicle,
        upgradeId,
        current.grade,
        GSVU4Core.GetUpgradeUninstallTime(upgradeId, current.grade)
    )

    if VehicleArmor_QueueVehicleArmorAction then
        VehicleArmor_QueueVehicleArmorAction(
            character,
            vehicle,
            getUpgradeWorkPart(upgradeId),
            action
        )
    elseif ISTimedActionQueue then
        ISTimedActionQueue.add(action)
    else
        return false
    end

    return true
end
