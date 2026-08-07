--========================================================
-- Gore's SVU4 Core - Install Vehicle Upgrade Timed Action
--========================================================

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "GoresSVU4Core/GSVU4_FilteredAirIntake"
require "GoresSVU4Core/GSVU4_EngineScoop"
require "GoresSVU4Core/GSVU4_AutoTuneMilitaryRadio"
require "VehicleArmor_ConsumeHelpers"
require "VehicleArmor_ActionHelpers"

ISInstallVehicleUpgrade = ISBaseTimedAction:derive("ISInstallVehicleUpgrade")

local function isMPClient()
    return isClient and isClient()
end

local function addVehicleCommandArgs(args, vehicle)
    args = args or {}
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

local function sendUpgradeCommand(command, vehicle, args)
    args = addVehicleCommandArgs(args or {}, vehicle)
    if sendClientCommand then
        sendClientCommand("GoresSVU4Core", command, args)
        return true
    end
    return false
end

local function getPerkLevel(character, perk)
    if not character or not perk or not character.getPerkLevel then return 0 end
    local ok, value = pcall(function() return character:getPerkLevel(perk) end)
    if ok and value then return tonumber(value) or 0 end
    return 0
end

local function getItemFullTypeSafe(item)
    if not item then return "" end
    if item.getFullType then
        local ok, value = pcall(function() return item:getFullType() end)
        if ok and value then return tostring(value) end
    end
    if item.getModule and item.getType then
        local ok, module, typ = pcall(function() return item:getModule(), item:getType() end)
        if ok and module and typ then return tostring(module) .. "." .. tostring(typ) end
    end
    return ""
end

local function isScrewdriverItem(item)
    if not item then return false end
    local t  = item.getType and tostring(item:getType()) or ""
    local ft = getItemFullTypeSafe(item)
    local lowT = string.lower(t)
    local lowFt = string.lower(ft)
    return lowT == "screwdriver"
        or lowFt == "base.screwdriver"
        or string.find(lowT, "screwdriver", 1, true) ~= nil
        or string.find(lowFt, "screwdriver", 1, true) ~= nil
end

local function isHammerItemLocal(item)
    if VehicleArmorHelpers and VehicleArmorHelpers.isHammerItem and VehicleArmorHelpers.isHammerItem(item) then return true end
    local t  = item and item.getType and tostring(item:getType()) or ""
    local ft = getItemFullTypeSafe(item)
    return t == "Hammer" or t == "BallPeenHammer" or ft == "Base.Hammer" or ft == "Base.BallPeenHammer"
        or string.find(t, "Hammer") ~= nil or string.find(ft, "Hammer") ~= nil
end

local function scanInventoryRecursive(inv, callback, seen)
    if not inv or not callback then return end
    seen = seen or {}
    if seen[inv] then return end
    seen[inv] = true
    local items = inv.getItems and inv:getItems() or nil
    if not items then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            callback(item)
            if item.getInventory then
                local ok, childInv = pcall(function() return item:getInventory() end)
                if ok and childInv then scanInventoryRecursive(childInv, callback, seen) end
            end
        end
    end
end

local function forEachAccessibleUpgradeItem(character, callback)
    if not character or not callback then return end
    if character.getInventory then
        local ok, inv = pcall(function() return character:getInventory() end)
        if ok and inv then scanInventoryRecursive(inv, callback) end
    end
    if character.getSquare then
        local okSq, square = pcall(function() return character:getSquare() end)
        if okSq and square and square.getObjects then
            local objects = square:getObjects()
            if objects then
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if obj and obj.getContainer then
                        local okC, container = pcall(function() return obj:getContainer() end)
                        if okC and container then scanInventoryRecursive(container, callback) end
                    end
                end
            end
        end
    end
end

local function hasUpgradeTools(character, upgradeId, grade)
    local hasMask = false
    local hasHammer = false
    local hasScrewdriver = false
    local hasTorch = false

    if not character or not VehicleArmorHelpers then return false end

    local upgDef = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getUpgrade and GSVU4UpgradesConfig.getUpgrade(upgradeId) or nil
    local cfg = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig and GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade) or nil
    local req = (cfg and cfg.tools) or (upgDef and upgDef.tools) or { weldingMask = true, blowTorch = true, hammer = true, screwdriver = true }

    local totalFuel = VehicleArmorHelpers.getTotalTorchFuel and VehicleArmorHelpers.getTotalTorchFuel(character) or 0
    hasTorch = totalFuel > 0

    forEachAccessibleUpgradeItem(character, function(item)
        local ft = getItemFullTypeSafe(item)
        local t  = item.getType and tostring(item:getType()) or ""
        if t == "WeldingMask" or ft == "Base.WeldingMask" then hasMask = true end
        if isHammerItemLocal(item) then hasHammer = true end
        if isScrewdriverItem(item) then hasScrewdriver = true end
    end)

    if req.weldingMask and not hasMask then return false end
    if req.blowTorch and not hasTorch then return false end
    if req.hammer and not hasHammer then return false end
    if req.screwdriver and not hasScrewdriver then return false end
    return true
end

local function hasSkills(character, config)
    if not config or not config.skills then return true end
    local mwNeed = tonumber(config.skills.MetalWelding) or 0
    local meNeed = tonumber(config.skills.Mechanics) or 0
    local elNeed = tonumber(config.skills.Electricity) or 0
    local mw = Perks and Perks.MetalWelding and getPerkLevel(character, Perks.MetalWelding) or 0
    local me = Perks and Perks.Mechanics and getPerkLevel(character, Perks.Mechanics) or 0
    local el = Perks and Perks.Electricity and getPerkLevel(character, Perks.Electricity) or 0
    return mw >= mwNeed and me >= meNeed and el >= elNeed
end


local function applyExternalUpgradeVisual(vehicle, upgradeId, grade)
    if not vehicle or not upgradeId then return end
    if GSVU4Core and GSVU4Core.ApplyExternalUpgradeVisualPacks then
        pcall(function() GSVU4Core.ApplyExternalUpgradeVisualPacks(vehicle, upgradeId, grade) end)
    elseif GSVU4Core and GSVU4Core.ApplyExternalVisualPacks then
        pcall(function() GSVU4Core.ApplyExternalVisualPacks(vehicle, nil) end)
    end
    if GSVU4Core and GSVU4Core.QueueUpgradeVisualState then
        pcall(function() GSVU4Core.QueueUpgradeVisualState(vehicle, upgradeId, 3, 15) end)
    elseif VehicleArmorVisuals and VehicleArmorVisuals.QueueApply then
        pcall(function() VehicleArmorVisuals.QueueApply(vehicle, nil, 3, 15) end)
    end

    if GSVU4Core and GSVU4Core.ReassertInstalledArmorAfterUpgrade then
        pcall(function()
            GSVU4Core.ReassertInstalledArmorAfterUpgrade(vehicle, 4, 12)
        end)
    elseif VehicleArmorVisuals and VehicleArmorVisuals.ForceInstalled then
        pcall(function() VehicleArmorVisuals.ForceInstalled(vehicle) end)
    end
end

local function applyUpgradeLocal(vehicle, upgradeId, grade, character)
    local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
    if not vehicle or not cfg then return false end
    local vdata = vehicle:getModData()
    vdata.gUpgrades = vdata.gUpgrades or {}
    local previousUpgrade = vdata.gUpgrades[upgradeId]
    local newUpgrade = {
        grade = grade,
        capacity = cfg.capacity or 0,
        weight = cfg.weight or 0,
        health = cfg.health or 100,
        maxHealth = cfg.health or 100,
        wearRemainder = 0,
    }
    if upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
        GSVU4FilteredAirIntake.initialiseUpgradeState(newUpgrade, cfg, previousUpgrade)
    end
    vdata.gUpgrades[upgradeId] = newUpgrade
    if upgradeId == "EngineScoop" and GSVU4EngineScoop and GSVU4EngineScoop.resetRuntime then
        GSVU4EngineScoop.resetRuntime(vehicle, previousUpgrade == nil)
    end
    GSVU4UpgradesConfig.ensureExternalStorageData(vehicle)
    if upgradeId == "RoofRack" then
        vdata.gExternalStorage.RoofRack = vdata.gExternalStorage.RoofRack or {
            capacity = cfg.capacity or 0,
            used = 0,
            items = {},
        }
        vdata.gExternalStorage.RoofRack.capacity = cfg.capacity or 0
    end
    if upgradeId == "BullBar" and GSVU4_ApplyBullBarVisual then
        GSVU4_ApplyBullBarVisual(vehicle)
    end
    if upgradeId == "AutoTuneMilitaryRadio" and GSVU4 and GSVU4.AutoTuneMilitaryRadio then
        pcall(function() GSVU4.AutoTuneMilitaryRadio.replaceVehicleRadioItem(vehicle, character) end)
        pcall(function() GSVU4.AutoTuneMilitaryRadio.programEmergencyPreset(vehicle) end)
        if GSVU4_ApplyAutoTuneRadioAerialVisual then
            pcall(function() GSVU4_ApplyAutoTuneRadioAerialVisual(vehicle, true) end)
        end
        if vehicle and vehicle.isEngineRunning then
            local okRun, running = pcall(function() return vehicle:isEngineRunning() end)
            if okRun and running == true then
                pcall(function() GSVU4.AutoTuneMilitaryRadio.autoTuneVehicleRadio(vehicle) end)
            end
        end
    end
    if (GSVU4UpgradesConfig.isRoofLightUpgradeId and GSVU4UpgradesConfig.isRoofLightUpgradeId(upgradeId)) and GSVU4_ApplyRoofLightsVisual then
        GSVU4_ApplyRoofLightsVisual(vehicle)
    end
    applyExternalUpgradeVisual(vehicle, upgradeId, grade)
    if vehicle.transmitModData then vehicle:transmitModData() end
    if VehicleArmor_UpdateMass then VehicleArmor_UpdateMass(vehicle) end
    return true
end


-- Return the vehicle part used to choose the pathing/work area for an upgrade.
-- These positions deliberately match the physical location of the upgrade.
function GSVU4Core.GetUpgradeWorkPart(upgradeId)
    local map = {
        RoofRack = "DoorFrontLeft",
        RoofLights = "EngineDoor",
        RoofLightsLeft = "DoorFrontLeft",
        RoofLightsRight = "DoorFrontRight",
        RoofLightsRear = "TrunkDoor",
        ExtraFuelStorage = "TrunkDoor",
        BullBar = "EngineDoor",
        Plow = "EngineDoor",
        EngineScoop = "EngineDoor",
        FilteredAirIntake = "EngineDoor",
        AutoTuneMilitaryRadio = "DoorFrontLeft",
        JerryCanSlots = "TrunkDoor",
    }
    return map[tostring(upgradeId or "")] or "EngineDoor"
end

function GSVU4Core.QueueUpgradeInstallTimedAction(character, vehicle, upgradeId, grade, time)
    if not character or not vehicle or not upgradeId or not grade then return false end

    local action = ISInstallVehicleUpgrade:new(
        character,
        vehicle,
        upgradeId,
        grade,
        tonumber(time) or 200
    )

    if VehicleArmor_QueueVehicleArmorAction then
        VehicleArmor_QueueVehicleArmorAction(
            character,
            vehicle,
            GSVU4Core.GetUpgradeWorkPart(upgradeId),
            action
        )
    elseif ISTimedActionQueue then
        ISTimedActionQueue.add(action)
    else
        return false
    end

    return true
end

function ISInstallVehicleUpgrade:isValid()
    if not self.character or not self.vehicle then return false end
    -- Block on KI5 vehicles
    if GSVU4_KI5FullBlock and GSVU4_KI5FullBlock.IsKI5Vehicle and GSVU4_KI5FullBlock.IsKI5Vehicle(self.vehicle) == true then
        if self.character.Say then self.character:Say("Upgrades not supported on KI5 vehicles.") end
        return false
    end
    if VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character) then return false end
    if VehicleArmor_IsCharacterNearVehicle and not VehicleArmor_IsCharacterNearVehicle(self.character, self.vehicle, 5.5) then return false end

    local cfg = GSVU4UpgradesConfig.getGradeConfig(self.upgradeId, self.grade)
    if not cfg then return false end

    if self.upgradeId == "EngineScoop" and GSVU4EngineScoop and GSVU4EngineScoop.canInstallOnVehicle then
        local vehicleOk, vehicleReason = GSVU4EngineScoop.canInstallOnVehicle(self.vehicle)
        if not vehicleOk then
            if self.character and self.character.Say then self.character:Say(vehicleReason) end
            return false
        end
    end

    if GSVU4UpgradesConfig.canInstallFrontFixture then
        local fixtureOk, fixtureReason = GSVU4UpgradesConfig.canInstallFrontFixture(self.vehicle, self.upgradeId)
        if not fixtureOk then
            if self.character and self.character.Say then self.character:Say(fixtureReason) end
            return false
        end
    end

    if GSVU4UpgradesConfig.isUpgradePrerequisiteMet and not GSVU4UpgradesConfig.isUpgradePrerequisiteMet(self.vehicle, self.upgradeId) then
        if self.character and self.character.Say then
            local label = GSVU4UpgradesConfig.getUpgradePrerequisiteLabel and GSVU4UpgradesConfig.getUpgradePrerequisiteLabel(self.upgradeId) or "required upgrade"
            self.character:Say(tostring(label) .. " must be installed first.")
        end
        return false
    end

    if not hasSkills(self.character, cfg) then return false end

    local current = GSVU4UpgradesConfig.getInstalledUpgrade(self.vehicle, self.upgradeId)
    if current then
        -- Use upgrade-specific progression check; fall back to generic rank comparison
        local canUpgrade = false
        local gradeRank = { Basic=1, Standard=2, Military=3 }
        if GSVU4UpgradesConfig.canUpgrade then
            canUpgrade = GSVU4UpgradesConfig.canUpgrade(self.upgradeId, current.grade, self.grade)
        elseif GSVU4UpgradesConfig.canUpgradeRoofRack and self.upgradeId == "RoofRack" then
            canUpgrade = GSVU4UpgradesConfig.canUpgradeRoofRack(current.grade, self.grade)
        else
            canUpgrade = (gradeRank[self.grade] or 0) > (gradeRank[current.grade] or 0)
        end
        if not canUpgrade then return false end
    end

    -- For ExtraFuelStorage: validate the primary cargo compartment and capacity penalty
    if self.upgradeId == "ExtraFuelStorage" and GSVU4UpgradesConfig.canAffordTrunkPenalty then
        local ok, reason = GSVU4UpgradesConfig.canAffordTrunkPenalty(
            self.vehicle, self.upgradeId, self.grade)
        if not ok then
            if self.character and self.character.Say then
                self.character:Say(reason or "Cargo compartment is too small for this upgrade.")
            end
            return false
        end
    end

    if self.upgradeId == "FilteredAirIntake" and not current and GSVU4FilteredAirIntake then
        local filterNeed = tonumber(cfg.filterCapacityMax) or tonumber(cfg.capacity) or 0
        if GSVU4FilteredAirIntake.getAvailableFilterCapacity(self.character) < filterNeed then
            if self.character and self.character.Say then
                self.character:Say("Not enough filter media. Factory filters provide 50; crafted or recharged filters provide 25.")
            end
            return false
        end
        local selection = GSVU4FilteredAirIntake.selectFilterItems(self.character, filterNeed)
        if not selection then return false end
    end

    if VehicleArmorHelpers then
        if not hasUpgradeTools(self.character, self.upgradeId, self.grade) then return false end
        -- Strip jerrycans from recipe - handled separately
        local recipeNoJerry = {}
        for k, v in pairs(cfg.recipe or {}) do if k ~= "jerrycans" then recipeNoJerry[k] = v end end
        if VehicleArmorHelpers.hasRecipeForCharacter and not VehicleArmorHelpers.hasRecipeForCharacter(self.character, recipeNoJerry) then return false end
        -- Jerry can count check
        local jerryNeed = tonumber((cfg.recipe or {}).jerrycans) or 0
        if jerryNeed > 0 then
            local jcount = 0
            local inv = self.character and self.character.getInventory and self.character:getInventory()
            if inv and inv.getItems then
                local items = inv:getItems()
                for i = 0, (items and items:size() or 0) - 1 do
                    local item = items:get(i)
                    if item and item.getFullType then
                        local ok, ft = pcall(function() return item:getFullType() end)
                        if ok and ft and (tostring(ft):lower():find("petrolcan") or tostring(ft):lower():find("jerrycan")) then jcount = jcount + 1 end
                    end
                end
            end
            if jcount < jerryNeed then return false end
        end
        if VehicleArmorHelpers.getTotalTorchFuel and VehicleArmorHelpers.getTotalTorchFuel(self.character) < (cfg.fuelUse or 1) then return false end
    end

    return true
end

function ISInstallVehicleUpgrade:start()
    -- Play the blowtorch welding animation, same as armor install
    self:setActionAnim("BlowTorch")

    -- Hold the blowtorch in the primary hand during the animation
    if VehicleArmorHelpers and VehicleArmorHelpers.findTorch then
        local torch = VehicleArmorHelpers.findTorch(self.character)
        if torch then self:setOverrideHandModels(torch, nil) end
    end

    VehicleArmor_StartWeldingSound(self)
    VehicleArmor_MakeWorldSound(self.character, self.vehicle, VehicleArmor_GetSoundRadius("Install", "Standard"), VehicleArmor_GetSoundVolume("Install"))
end

function ISInstallVehicleUpgrade:stop()
    VehicleArmor_StopWeldingSound(self)
    ISBaseTimedAction.stop(self)
end

local function addElectricityXP(character, amount)
    if not character or not amount or amount <= 0 then return end
    if VehicleArmor_AddXP and Perks and Perks.Electricity then
        VehicleArmor_AddXP(character, Perks.Electricity, amount)
    end
end

function ISInstallVehicleUpgrade:perform()
    VehicleArmor_StopWeldingSound(self)

    if not self:isValid() then
        if self.character then self.character:Say("Missing upgrade tools, materials, skills, or blowtorch fuel.") end
        ISBaseTimedAction.perform(self)
        return
    end

    if isMPClient() then
        local sent = sendUpgradeCommand("InstallUpgrade", self.vehicle, {
            upgradeId = self.upgradeId,
            grade = self.grade,
        })

        -- We already hold the exact live vehicle object here. Start the single
        -- visual writer immediately so installed armor cannot be left waiting
        -- for a later vehicle-ID lookup or OnEnterVehicle fallback.
        if sent
        and GSVU4Core
        and GSVU4Core.ReleaseVehicleVisualState then
            GSVU4Core.ReleaseVehicleVisualState(
                self.vehicle,
                "local-install-request:" .. tostring(self.upgradeId)
            )
        end

        if self.character then
            self.character:Say(
                sent
                and "Upgrade install requested."
                or "Unable to contact server."
            )
        end
        ISBaseTimedAction.perform(self)
        return
    end

    local cfg = GSVU4UpgradesConfig.getGradeConfig(self.upgradeId, self.grade)
    local extraFuelPreApplied = false
    local currentUpgrade = GSVU4UpgradesConfig.getInstalledUpgrade(self.vehicle, self.upgradeId)
    local installedFilterMedia = nil

    if self.upgradeId == "ExtraFuelStorage" then
        local vdata = self.vehicle:getModData()
        local previous = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage or nil

        applyUpgradeLocal(self.vehicle, self.upgradeId, self.grade, self.character)
        local applied, reason = GSVU4UpgradesConfig.applyExtraFuelStorage(self.vehicle)
        if not applied then
            vdata.gUpgrades = vdata.gUpgrades or {}
            vdata.gUpgrades.ExtraFuelStorage = previous
            if previous then
                pcall(function() GSVU4UpgradesConfig.applyExtraFuelStorage(self.vehicle) end)
            else
                pcall(function() GSVU4UpgradesConfig.removeExtraFuelStorage(self.vehicle) end)
            end
            if self.character and self.character.Say then
                self.character:Say(reason or "Unable to apply the cargo-capacity penalty.")
            end
            ISBaseTimedAction.perform(self)
            return
        end
        extraFuelPreApplied = true
    end

    if self.upgradeId == "FilteredAirIntake" and not currentUpgrade and GSVU4FilteredAirIntake then
        local filterNeed = tonumber(cfg.filterCapacityMax) or tonumber(cfg.capacity) or 0
        local consumedOk, added, consumed, filterReason, media = GSVU4FilteredAirIntake.consumeFilterCapacity(self.character, filterNeed)
        if not consumedOk then
            if self.character and self.character.Say then self.character:Say(filterReason or "Not enough filter media.") end
            ISBaseTimedAction.perform(self)
            return
        end
        installedFilterMedia = media
    end

    if VehicleArmorHelpers then
        if VehicleArmorHelpers.consumeTorchFuelFromCharacter then
            VehicleArmorHelpers.consumeTorchFuelFromCharacter(self.character, cfg.fuelUse or 1)
        end
        if VehicleArmorHelpers.consumeRecipeForCharacter then
            local recipeNoJerry = {}
            for k, v in pairs(cfg.recipe or {}) do if k ~= "jerrycans" then recipeNoJerry[k] = v end end
            VehicleArmorHelpers.consumeRecipeForCharacter(self.character, recipeNoJerry)
        end
    end
    -- Consume empty jerry cans
    local jerryNeed = tonumber((cfg.recipe or {}).jerrycans) or 0
    if jerryNeed > 0 then
        local consumed, inv = 0, self.character and self.character.getInventory and self.character:getInventory()
        if inv and inv.getItems and inv.Remove then
            local toRemove = {}
            local items = inv:getItems()
            for i = 0, (items and items:size() or 0) - 1 do
                if consumed >= jerryNeed then break end
                local item = items:get(i)
                if item and item.getFullType then
                    local ok, ft = pcall(function() return item:getFullType() end)
                    if ok and ft and (tostring(ft):lower():find("petrolcan") or tostring(ft):lower():find("jerrycan")) then
                        table.insert(toRemove, item); consumed = consumed + 1
                    end
                end
            end
            for _, item in ipairs(toRemove) do pcall(function() inv:Remove(item) end) end
        end
    end
    if not extraFuelPreApplied then
        applyUpgradeLocal(self.vehicle, self.upgradeId, self.grade, self.character)
        if installedFilterMedia and GSVU4FilteredAirIntake then
            local installed = GSVU4FilteredAirIntake.getInstalled(self.vehicle)
            GSVU4FilteredAirIntake.setInstalledFilterMedia(installed, installedFilterMedia)
            if self.vehicle and self.vehicle.transmitModData then self.vehicle:transmitModData() end
        end
    elseif self.vehicle and self.vehicle.transmitModData then
        self.vehicle:transmitModData()
    end

    if self.upgradeId == "FilteredAirIntake"
    and GSVU4FilteredAirIntake
    and GSVU4FilteredAirIntake.clearRuntimeStatus
    then
        GSVU4FilteredAirIntake.clearRuntimeStatus(self.vehicle)
    end

    -- On MP client, send a command to server to seed the reserve
    -- (server-side event then handles the actual transfer loop)
    if self.upgradeId == "ExtraFuelStorage" and isClient and isClient() then
        if sendClientCommand then
            sendClientCommand("GoresSVU4Core", "SeedEFSReserve", {
                vehicleX = math.floor(self.vehicle:getX()),
                vehicleY = math.floor(self.vehicle:getY()),
            })
        end
    end

    if cfg.xp then
        VehicleArmor_AddMetalWeldingXP(self.character, cfg.xp.MetalWelding or 0)
        VehicleArmor_AddMechanicsXP(self.character, cfg.xp.Mechanics or 0)
        addElectricityXP(self.character, cfg.xp.Electricity or 0)
    end

    if self.character then self.character:Say((cfg.label or "Upgrade") .. " installed.") end
    ISBaseTimedAction.perform(self)
end

function ISInstallVehicleUpgrade:new(character, vehicle, upgradeId, grade, time)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.vehicle = vehicle
    o.upgradeId = upgradeId
    o.grade = grade
    o.maxTime = time or 200
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = false
    return o
end
