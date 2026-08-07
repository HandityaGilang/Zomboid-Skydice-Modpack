--========================================================
-- Gore's SVU4 Core - Upgrade Config
--========================================================

GSVU4UpgradesConfig = GSVU4UpgradesConfig or {}

GSVU4UpgradesConfig.TabOrder = {
    "Armor",
    "Upgrades",
    "ExternalStorage",
}

GSVU4UpgradesConfig.RoofRackGrades = {
    "Basic",
    "Standard",
    "Military",
}

GSVU4UpgradesConfig.RoofRackRank = {
    Basic = 1,
    Standard = 2,
    Military = 3,
}

GSVU4UpgradesConfig.Upgrades = {
    RoofRack = {
        id = "RoofRack",
        label = "Roof Rack",
        description = "External storage frame mounted above the vehicle, separate from the normal trunk.",
        tools = {
            weldingMask = true,
            blowTorch = true,
            hammer = true,
            screwdriver = true,
        },
        toolLabels = {
            "Welding Mask",
            "Blowtorch",
            "Hammer",
            "Screwdriver",
        },
        grades = {
            Basic = {
                label = "Basic Roof Rack",
                capacity = 35,
                weight = 18,
                time = 180,
                fuelUse = 0,
                tools = { hammer = true, screwdriver = true },
                toolLabels = { "Hammer", "Screwdriver" },
                recipe = { bars = 1, scrap = 2, screws = 4 },
                skills = { MetalWelding = 0, Mechanics = 1 },
                xp = { MetalWelding = 0, Mechanics = 2 },
            },
            Standard = {
                label = "Standard Roof Rack",
                capacity = 55,
                weight = 30,
                time = 260,
                fuelUse = 2,
                recipe = { bars = 2, sheets = 1, screws = 8, wire = 1 },
                skills = { MetalWelding = 3, Mechanics = 2 },
                xp = { MetalWelding = 10, Mechanics = 4 },
            },
            Military = {
                label = "Military Roof Rack",
                capacity = 80,
                weight = 45,
                time = 380,
                fuelUse = 3,
                recipe = { bars = 4, sheets = 2, screws = 12, wire = 2, rods = 0.2 },
                skills = { MetalWelding = 5, Mechanics = 4 },
                xp = { MetalWelding = 18, Mechanics = 7 },
            },
        },
    },

    ExtraFuelStorage = {
        id = "ExtraFuelStorage",
        label = "Auxiliary Fuel Tank",
        description = "Mounts an auxiliary fuel tank to the vehicle, increasing total fuel capacity. Reduces the vehicle's primary cargo compartment capacity as a trade-off.",
        tools = {
            weldingMask  = true,
            blowTorch    = true,
            hammer       = true,
            screwdriver  = true,
        },
        toolLabels = {
            "Welding Mask",
            "Blowtorch",
            "Hammer",
            "Screwdriver",
        },
        grades = {
            Basic = {
                label       = "Basic Auxiliary Tank",
                fuelBonus   = 20,    -- extra litres added to fuel tank
                trunkPenalty = 10,   -- kg of trunk capacity removed
                weight      = 6,
                time        = 120,
                fuelUse     = 0,
                tools       = { hammer = true, screwdriver = true },
                toolLabels  = { "Hammer", "Screwdriver" },
                recipe      = { bars = 1, sheets = 1, screws = 4 },
                skills      = { MetalWelding = 0, Mechanics = 1 },
                xp          = { MetalWelding = 0, Mechanics = 2 },
            },
            Standard = {
                label       = "Standard Auxiliary Tank",
                fuelBonus   = 40,
                trunkPenalty = 20,
                weight      = 12,
                time        = 200,
                fuelUse     = 2,
                recipe      = { bars = 2, sheets = 2, screws = 6, wire = 1 },
                skills      = { MetalWelding = 2, Mechanics = 2 },
                xp          = { MetalWelding = 8, Mechanics = 4 },
            },
            Military = {
                label       = "Military Auxiliary Tank",
                fuelBonus   = 60,
                trunkPenalty = 30,
                weight      = 18,
                time        = 320,
                fuelUse     = 3,
                recipe      = { bars = 4, sheets = 4, screws = 10, wire = 2, rods = 0.2 },
                skills      = { MetalWelding = 4, Mechanics = 3 },
                xp          = { MetalWelding = 15, Mechanics = 7 },
            },
        },
    },
}

GSVU4UpgradesConfig.ExtraFuelStorageGrades = { "Basic", "Standard", "Military" }

-- Apply ExtraFuelStorage effects to a vehicle (fuel bonus + cargo-capacity penalty).
-- Called after install and on each game load via Events.OnPlayerUpdate.
function GSVU4UpgradesConfig.getEffectiveFuelCapacity(vehicle)
    -- Returns {base, bonus, effective, reserve} or nil if no upgrade installed
    if not vehicle or not vehicle.getModData then return nil end
    local vdata = vehicle:getModData()
    local upgrade = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
    if not upgrade then return nil end
    local cfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", upgrade.grade)
    local bonus = cfg and (tonumber(cfg.fuelBonus) or 0) or 0
    local base = tonumber(vdata.GSVU4_origFuelCap) or 0
    local effective = tonumber(vdata.GSVU4_effectiveFuelCap) or (base + bonus)
    local reserve = tonumber(vdata.GSVU4_fuelReserve) or 0
    if base == 0 then return nil end
    return { base = base, bonus = bonus, effective = effective, reserve = reserve }
end

-- Cargo-part IDs supported by the auxiliary tank. Internal public function names
-- retain "Trunk" for compatibility with existing Core patches and saved modData.
local GSVU4_CARGO_PART_IDS = { "TrunkBag", "TruckBed", "Trunk", "TrunkBag2", "TrunkBag3", "Fridge" }
local GSVU4_TRUNK_PART_IDS = GSVU4_CARGO_PART_IDS

-- Some modded vehicles expose a generic/hidden trunk alongside their actual
-- player-facing cargo compartment. These overrides prevent the capacity penalty
-- being applied to the wrong container. Both qualified and unqualified script
-- names are accepted because getScriptName() varies between vehicle frameworks.
local GSVU4_PRIMARY_CARGO_PART_OVERRIDES = {
    ["Base.pzkStepVanMilk"] = "Fridge",
    ["pzkStepVanMilk"] = "Fridge",
}

local GSVU4_CARGO_PART_LABELS = {
    TrunkBag = "Trunk",
    TruckBed = "Truck Bed",
    Trunk = "Trunk",
    TrunkBag2 = "Trunk",
    TrunkBag3 = "Trunk",
    Fridge = "Fridge",
}

local function GSVU4_GetVehicleScriptName(vehicle)
    if not vehicle then return nil end
    if vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value and tostring(value) ~= "" then return tostring(value) end
    end
    if vehicle.getScript then
        local okScript, script = pcall(function() return vehicle:getScript() end)
        if okScript and script and script.getFullName then
            local okName, value = pcall(function() return script:getFullName() end)
            if okName and value and tostring(value) ~= "" then return tostring(value) end
        end
    end
    return nil
end

local function GSVU4_GetPrimaryCargoOverride(vehicle)
    local scriptName = GSVU4_GetVehicleScriptName(vehicle)
    if not scriptName then return nil end
    return GSVU4_PRIMARY_CARGO_PART_OVERRIDES[scriptName]
        or GSVU4_PRIMARY_CARGO_PART_OVERRIDES[scriptName:gsub("^Base%.", "")]
end

local function GSVU4_GetCargoPartLabel(partId)
    return GSVU4_CARGO_PART_LABELS[tostring(partId or "")]
        or tostring(partId or "Cargo Compartment")
end

local function GSVU4_GetPartContainer(part)
    if not part then return nil end

    if part.getItemContainer then
        local ok, container = pcall(function() return part:getItemContainer() end)
        if ok and container then return container end
    end

    if part.getContainer then
        local ok, container = pcall(function() return part:getContainer() end)
        if ok and container then return container end
    end

    return nil
end

local function GSVU4_ReadTrunkCapacity(part, container)
    if part and part.getContainerCapacity then
        local ok, capacity = pcall(function() return part:getContainerCapacity() end)
        capacity = ok and tonumber(capacity) or nil
        if capacity and capacity > 0 then return capacity end
    end

    if container and container.getMaxCapacity then
        local ok, capacity = pcall(function() return container:getMaxCapacity() end)
        capacity = ok and tonumber(capacity) or nil
        if capacity and capacity > 0 then return capacity end
    end

    if container and container.getCapacity then
        local ok, capacity = pcall(function() return container:getCapacity() end)
        capacity = ok and tonumber(capacity) or nil
        if capacity and capacity > 0 then return capacity end
    end

    return nil
end

local function GSVU4_FindTrunkInfo(vehicle, preferredPartId, preferStoredPart)
    if not vehicle or not vehicle.getPartById then return nil end

    local function inspect(partId)
        if not partId then return nil end
        local okPart, part = pcall(function() return vehicle:getPartById(partId) end)
        if not okPart or not part then return nil end

        local container = GSVU4_GetPartContainer(part)
        if not container then return nil end

        return {
            partId = partId,
            part = part,
            container = container,
            capacity = GSVU4_ReadTrunkCapacity(part, container),
        }
    end

    local overridePartId = GSVU4_GetPrimaryCargoOverride(vehicle)

    -- Normal selection prefers a vehicle-specific primary cargo override. Exact
    -- restoration paths can request the previously stored part first instead.
    if preferStoredPart then
        local preferred = inspect(preferredPartId)
        if preferred then
            preferred.label = GSVU4_GetCargoPartLabel(preferred.partId)
            return preferred
        end
        local override = inspect(overridePartId)
        if override then
            override.label = GSVU4_GetCargoPartLabel(override.partId)
            return override
        end
    else
        local override = inspect(overridePartId)
        if override then
            override.label = GSVU4_GetCargoPartLabel(override.partId)
            return override
        end
        local preferred = inspect(preferredPartId)
        if preferred then
            preferred.label = GSVU4_GetCargoPartLabel(preferred.partId)
            return preferred
        end
    end

    for _, partId in ipairs(GSVU4_TRUNK_PART_IDS) do
        if partId ~= preferredPartId and partId ~= overridePartId then
            local info = inspect(partId)
            if info then
                info.label = GSVU4_GetCargoPartLabel(info.partId)
                return info
            end
        end
    end

    return nil
end

local function GSVU4_GetContainerItemCount(container)
    if not container then return nil end

    if container.isEmpty then
        local ok, empty = pcall(function() return container:isEmpty() end)
        if ok and empty == true then return 0 end
    end

    if container.getItems then
        local okItems, items = pcall(function() return container:getItems() end)
        if okItems and items and items.size then
            local okSize, size = pcall(function() return items:size() end)
            if okSize and tonumber(size) then return math.max(0, math.floor(tonumber(size))) end
        end
    end

    return nil
end

local function GSVU4_CanSetTrunkCapacity(info)
    if not info or not info.part or not info.container then return false end
    if info.part.setContainerCapacity then return true end
    if info.container.setMaxCapacity then return true end
    if info.container.setCapacity then return true end
    return false
end

local function GSVU4_SetTrunkCapacity(vehicle, info, targetCapacity)
    if not info then return false, nil end
    targetCapacity = math.max(0, math.floor((tonumber(targetCapacity) or 0) + 0.5))

    local function readBack()
        return GSVU4_ReadTrunkCapacity(info.part, info.container)
    end

    local function matchesTarget(value)
        value = tonumber(value)
        return value and math.abs(value - targetCapacity) < 0.01
    end

    if info.part and info.part.setContainerCapacity then
        pcall(function() info.part:setContainerCapacity(targetCapacity) end)
        local actual = readBack()
        if matchesTarget(actual) then
            if vehicle and vehicle.transmitPartModData then
                pcall(function() vehicle:transmitPartModData(info.part) end)
            end
            return true, actual
        end
    end

    if info.container and info.container.setMaxCapacity then
        pcall(function() info.container:setMaxCapacity(targetCapacity) end)
        local actual = readBack()
        if matchesTarget(actual) then
            if vehicle and vehicle.transmitPartModData then
                pcall(function() vehicle:transmitPartModData(info.part) end)
            end
            return true, actual
        end
    end

    if info.container and info.container.setCapacity then
        pcall(function() info.container:setCapacity(targetCapacity) end)
        local actual = readBack()
        if matchesTarget(actual) then
            if vehicle and vehicle.transmitPartModData then
                pcall(function() vehicle:transmitPartModData(info.part) end)
            end
            return true, actual
        end
    end

    return false, readBack()
end

function GSVU4UpgradesConfig.getTrunkInfo(vehicle)
    local preferredPartId = nil
    if vehicle and vehicle.getModData then
        local vdata = vehicle:getModData()
        preferredPartId = vdata and vdata.GSVU4_trunkPartId or nil
    end
    return GSVU4_FindTrunkInfo(vehicle, preferredPartId, false)
end

function GSVU4UpgradesConfig.getCargoInfo(vehicle)
    return GSVU4UpgradesConfig.getTrunkInfo(vehicle)
end

function GSVU4UpgradesConfig.getCargoPartLabel(vehicle)
    local info = GSVU4UpgradesConfig.getTrunkInfo(vehicle)
    return info and info.label or "Cargo Compartment"
end

function GSVU4UpgradesConfig.getTrunkCapacity(vehicle)
    local info = GSVU4UpgradesConfig.getTrunkInfo(vehicle)
    return info and info.capacity or nil
end

function GSVU4UpgradesConfig.getTrunkItemCount(vehicle)
    local info = GSVU4UpgradesConfig.getTrunkInfo(vehicle)
    if not info then return nil end
    return GSVU4_GetContainerItemCount(info.container)
end

function GSVU4UpgradesConfig.isTrunkCompletelyEmpty(vehicle)
    local info = GSVU4UpgradesConfig.getTrunkInfo(vehicle)
    if not info then
        return false, "No supported cargo compartment was found on this vehicle."
    end

    local count = GSVU4_GetContainerItemCount(info.container)
    if count == nil then
        return false, string.format(
            "Unable to verify that the %s is completely empty.",
            tostring(info.label or "target cargo compartment"))
    end
    if count > 0 then
        local itemWord = count == 1 and "item" or "items"
        return false, string.format(
            "The %s must be completely empty before installing an auxiliary fuel tank (%d %s stored).",
            tostring(info.label or "target cargo compartment"),
            count,
            itemWord)
    end

    return true, nil
end

function GSVU4UpgradesConfig.canAffordTrunkPenalty(vehicle, upgradeId, grade)
    -- Installation and grade changes require a supported, completely empty cargo compartment.
    local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
    if not cfg then return false, "Invalid auxiliary fuel tank grade." end

    local penalty = tonumber(cfg.trunkPenalty) or 0
    local info = GSVU4UpgradesConfig.getTrunkInfo(vehicle)
    if not info then
        return false, "No supported cargo compartment was found on this vehicle."
    end
    if not info.capacity then
        return false, string.format(
            "Unable to read the %s capacity.",
            tostring(info.label or "target cargo compartment"))
    end
    if not GSVU4_CanSetTrunkCapacity(info) then
        return false, string.format(
            "The %s capacity cannot be adjusted safely.",
            tostring(info.label or "target cargo compartment"))
    end

    local empty, emptyReason = GSVU4UpgradesConfig.isTrunkCompletelyEmpty(vehicle)
    if not empty then return false, emptyReason end

    local vdata = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local storedPartId = vdata and vdata.GSVU4_trunkPartId or nil
    local originalCapacity = nil
    if storedPartId == info.partId then
        originalCapacity = vdata and tonumber(vdata.GSVU4_origTrunkCap) or nil
    end
    originalCapacity = originalCapacity or tonumber(info.capacity)

    -- Keep at least 10 units of usable cargo capacity after fitting the tank.
    local minRequired = penalty + 10
    if originalCapacity < minRequired then
        return false, string.format(
            "%s is too small. Need %d original capacity (have %d).",
            tostring(info.label or "Cargo compartment"),
            minRequired,
            math.floor(originalCapacity))
    end

    return true, nil
end

function GSVU4UpgradesConfig.applyExtraFuelStorage(vehicle)
    if not vehicle or not vehicle.getModData then return false, "Vehicle unavailable." end
    local vdata = vehicle:getModData()
    local upgrade = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
    if not upgrade or not upgrade.grade then return false, "No auxiliary fuel tank is installed." end

    local cfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", upgrade.grade)
    if not cfg then return false, "Invalid auxiliary fuel tank configuration." end

    local fuelBonus = tonumber(cfg.fuelBonus) or 0
    local trunkPenalty = tonumber(cfg.trunkPenalty) or 0

    -- Apply the cargo penalty first. The exact part and original capacity are
    -- stored so grade changes and uninstall always operate on the same compartment.
    -- Vehicle-specific overrides are checked before a legacy stored part so
    -- older saves can migrate from a hidden trunk to the visible Fridge compartment.
    local storedPartId = vdata.GSVU4_trunkPartId
    local info = GSVU4_FindTrunkInfo(vehicle, storedPartId, false)
    if not info or not info.capacity then
        return false, "No supported cargo compartment was found."
    end

    if storedPartId and storedPartId ~= info.partId and vdata.GSVU4_origTrunkCap then
        local oldInfo = GSVU4_FindTrunkInfo(vehicle, storedPartId, true)
        if not oldInfo or oldInfo.partId ~= storedPartId then
            return false, "The previously adjusted cargo compartment could not be found for migration."
        end
        local restored, actual = GSVU4_SetTrunkCapacity(
            vehicle, oldInfo, tonumber(vdata.GSVU4_origTrunkCap))
        if not restored then
            return false, string.format(
                "Unable to restore the previous %s capacity during migration (current value: %s).",
                tostring(oldInfo.label or "cargo compartment"),
                tostring(actual or "unknown"))
        end
        vdata.GSVU4_origTrunkCap = nil
        vdata.GSVU4_targetTrunkCap = nil
        vdata.GSVU4_trunkPenaltyApplied = nil
    end

    local originalCapacity = tonumber(vdata.GSVU4_origTrunkCap) or tonumber(info.capacity)
    local targetCapacity = math.max(10, originalCapacity - trunkPenalty)
    local applied, actualCapacity = GSVU4_SetTrunkCapacity(vehicle, info, targetCapacity)
    if not applied then
        return false, string.format(
            "Unable to set %s capacity to %d (current value: %s).",
            tostring(info.label or "cargo compartment"),
            targetCapacity,
            tostring(actualCapacity or "unknown"))
    end

    vdata.GSVU4_origTrunkCap = originalCapacity
    vdata.GSVU4_trunkPartId = info.partId
    vdata.GSVU4_targetTrunkCap = targetCapacity
    vdata.GSVU4_trunkPenaltyApplied = trunkPenalty

    -- The main tank remains vanilla-sized. The auxiliary capacity is tracked
    -- as a separate reserve and displayed by the SVU4 UI.
    local gasPart = vehicle.getPartById and vehicle:getPartById("GasTank")
    if gasPart then
        local baseCap = nil
        if gasPart.getContainerCapacity then
            local ok, value = pcall(function() return gasPart:getContainerCapacity() end)
            if ok then baseCap = tonumber(value) end
        end

        if baseCap and baseCap > 0 then
            if not vdata.GSVU4_origFuelCap then
                vdata.GSVU4_origFuelCap = baseCap
            end
            vdata.GSVU4_effectiveFuelCap = (vdata.GSVU4_origFuelCap or baseCap) + fuelBonus
            if vdata.GSVU4_fuelReserve == nil then
                vdata.GSVU4_fuelReserve = 0
            end
        end
    end

    return true, nil
end

function GSVU4UpgradesConfig.removeExtraFuelStorage(vehicle)
    if not vehicle or not vehicle.getModData then return false, "Vehicle unavailable." end
    local vdata = vehicle:getModData()

    local originalCapacity = tonumber(vdata.GSVU4_origTrunkCap)
    if originalCapacity then
        local info = GSVU4_FindTrunkInfo(vehicle, vdata.GSVU4_trunkPartId, true)
        if not info then
            return false, "The original cargo compartment could not be found."
        end

        local restored, actualCapacity = GSVU4_SetTrunkCapacity(vehicle, info, originalCapacity)
        if not restored then
            return false, string.format(
                "Unable to restore %s capacity to %d (current value: %s).",
                tostring(info.label or "cargo compartment"),
                originalCapacity,
                tostring(actualCapacity or "unknown"))
        end
    end

    vdata.GSVU4_origFuelCap = nil
    vdata.GSVU4_effectiveFuelCap = nil
    vdata.GSVU4_fuelReserve = nil
    vdata.GSVU4_origTrunkCap = nil
    vdata.GSVU4_trunkPartId = nil
    vdata.GSVU4_targetTrunkCap = nil
    vdata.GSVU4_trunkPenaltyApplied = nil

    if vdata.gUpgrades then vdata.gUpgrades.ExtraFuelStorage = nil end
    return true, nil
end

function GSVU4UpgradesConfig.ensureExternalStorageData(vehicle)
    if not vehicle or not vehicle.getModData then return end
    local vdata = vehicle:getModData()
    vdata.gExternalStorage = vdata.gExternalStorage or {}
end

function GSVU4UpgradesConfig.getUpgrade(upgradeId)
    return upgradeId and GSVU4UpgradesConfig.Upgrades and GSVU4UpgradesConfig.Upgrades[upgradeId] or nil
end

function GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
    local upgrade = GSVU4UpgradesConfig.getUpgrade(upgradeId)
    return upgrade and upgrade.grades and upgrade.grades[grade] or nil
end

function GSVU4UpgradesConfig.getInstalledUpgrade(vehicle, upgradeId)
    if not vehicle or not vehicle.getModData then return nil end
    local vdata = vehicle:getModData()
    return vdata and vdata.gUpgrades and vdata.gUpgrades[upgradeId] or nil
end

function GSVU4UpgradesConfig.getUpgradeToolLabels(upgradeId)
    local upgrade = GSVU4UpgradesConfig.getUpgrade(upgradeId)
    return upgrade and upgrade.toolLabels or {}
end

function GSVU4UpgradesConfig.getUpgradeTools(upgradeId)
    local upgrade = GSVU4UpgradesConfig.getUpgrade(upgradeId)
    return upgrade and upgrade.tools or {}
end

function GSVU4UpgradesConfig.canUpgradeRoofRack(currentGrade, targetGrade)
    local rank = GSVU4UpgradesConfig.RoofRackRank
    local cur  = rank and rank[currentGrade] or 0
    local tgt  = rank and rank[targetGrade]  or 0
    return tgt > cur
end

-- Generic upgrade rank check used by isValid for any upgrade
function GSVU4UpgradesConfig.canUpgrade(upgradeId, currentGrade, targetGrade)
    local r = { Basic=1, Standard=2, Military=3 }
    return (r[targetGrade] or 0) > (r[currentGrade] or 0)
end

function GSVU4UpgradesConfig.canUpgradeExtraFuelStorage(currentGrade, targetGrade)
    local r = { Basic=1, Standard=2, Military=3 }
    return (r[targetGrade] or 0) > (r[currentGrade] or 0)
end

GSVU4UpgradesConfig.RecipeLabels = {
    scrap     = "Scrap Metal",
    sheets    = "Metal Sheets",
    bars      = "Metal Bars",
    screws    = "Screws",
    wire      = "Wire",
    electricWire = "Electrical Wire",
    bulbs     = "Light Bulbs",
    rods      = "Welding Rods",
}
GSVU4UpgradesConfig.RecipeOrder = { "sheets", "bars", "screws", "electricWire", "wire", "bulbs", "rods", "scrap" }


-- GSVU4 roof lighting upgrade registration guard
-- Kept here so the upgrade exists before the UI list is built.
GSVU4UpgradesConfig.RoofLightsGrades = GSVU4UpgradesConfig.RoofLightsGrades or { "Basic" }
if not GSVU4UpgradesConfig.Upgrades.RoofLights then
    GSVU4UpgradesConfig.Upgrades.RoofLights = {
        id = "RoofLights",
        label = "Roof Lighting System",
        description = "External roof-mounted lighting hardware. Visual models are supplied by optional vehicle packs.",
        tools = { hammer = true, screwdriver = true },
        toolLabels = { "Hammer", "Screwdriver" },
        grades = {
            Basic = {
                label = "Roof Lighting System",
                lightBonus = 1,
                weight = 5,
                time = 220,
                fuelUse = 0,
                recipe = { sheets = 1, bars = 2, screws = 6, electricWire = 2, wire = 1, bulbs = 2 },
                skills = { Mechanics = 3, Electricity = 4 },
                xp = { Mechanics = 4, Electricity = 5 },
            },
        },
    }
end
--========================================================
-- GSVU4_UPGRADE_LIGHTING_SYSTEM_EXTENSION
-- Adds installable roof light options used by optional visual packs.
--========================================================

GSVU4UpgradesConfig.RoofLightsGrades = { "Basic" }
GSVU4UpgradesConfig.RoofLightOptionIds = {
    "RoofLights",
    "RoofLightsLeft",
    "RoofLightsRight",
    "RoofLightsRear",
}
GSVU4UpgradesConfig.RoofLightOptionLabels = {
    RoofLights = "Roof Lighting System",
    RoofLightsLeft = "Left Side Roof Light",
    RoofLightsRight = "Right Side Roof Light",
    RoofLightsRear = "Rear Roof Light",
}

function GSVU4UpgradesConfig.isRoofLightUpgradeId(upgradeId)
    return upgradeId == "RoofLights" or upgradeId == "RoofLightsLeft" or upgradeId == "RoofLightsRight" or upgradeId == "RoofLightsRear"
end

local GSVU4_ROOFLIGHT_RECIPE = {
    sheets = 1,
    bars = 2,
    screws = 6,
    electricWire = 2,
    wire = 1,
    bulbs = 2,
}

local function gsvu4CopyRecipe(src)
    local out = {}
    for k, v in pairs(src or {}) do out[k] = v end
    return out
end

local function gsvu4RegisterRoofLightUpgrade(upgradeId, label, description, requiresUpgrade)
    GSVU4UpgradesConfig.Upgrades[upgradeId] = {
        id = upgradeId,
        label = label,
        description = description,
        requiresUpgrade = requiresUpgrade,
        requiresUpgradeLabel = requiresUpgrade == "RoofLights" and "Roof Lighting System" or nil,
        tools = {
            hammer = true,
            screwdriver = true,
        },
        toolLabels = {
            "Hammer",
            "Screwdriver",
        },
        grades = {
            Basic = {
                label = label,
                lightBonus = 1,
                weight = 3,
                time = 180,
                fuelUse = 0,
                recipe = gsvu4CopyRecipe(GSVU4_ROOFLIGHT_RECIPE),
                skills = { Mechanics = 3, Electricity = 4 },
                xp = { Mechanics = 4, Electricity = 5 },
            },
        },
    }
end

gsvu4RegisterRoofLightUpgrade(
    "RoofLights",
    "Roof Lighting System",
    "Forward-facing roof-mounted auxiliary lighting hardware. Required before side or rear roof lights can be fitted."
)

gsvu4RegisterRoofLightUpgrade(
    "RoofLightsLeft",
    "Left Side Roof Light",
    "Left-facing roof-mounted side light. Requires the front Roof Lighting System first.",
    "RoofLights"
)

gsvu4RegisterRoofLightUpgrade(
    "RoofLightsRight",
    "Right Side Roof Light",
    "Right-facing roof-mounted side light. Requires the front Roof Lighting System first.",
    "RoofLights"
)

gsvu4RegisterRoofLightUpgrade(
    "RoofLightsRear",
    "Rear Roof Light",
    "Rear-facing roof-mounted work light with extended beam range. Requires the front Roof Lighting System first.",
    "RoofLights"
)

function GSVU4UpgradesConfig.isUpgradePrerequisiteMet(vehicle, upgradeId)
    local upg = GSVU4UpgradesConfig.Upgrades and GSVU4UpgradesConfig.Upgrades[upgradeId] or nil
    local required = upg and upg.requiresUpgrade or nil
    if not required then return true end
    local current = GSVU4UpgradesConfig.getInstalledUpgrade and GSVU4UpgradesConfig.getInstalledUpgrade(vehicle, required) or nil
    return current ~= nil and current.grade ~= nil
end

function GSVU4UpgradesConfig.getUpgradePrerequisiteLabel(upgradeId)
    local upg = GSVU4UpgradesConfig.Upgrades and GSVU4UpgradesConfig.Upgrades[upgradeId] or nil
    return upg and (upg.requiresUpgradeLabel or upg.requiresUpgrade) or nil
end

function GSVU4UpgradesConfig.canUpgradeRoofLights(currentGrade, targetGrade)
    return false
end

local GSVU4_oldCanUpgrade = GSVU4UpgradesConfig.canUpgrade
function GSVU4UpgradesConfig.canUpgrade(upgradeId, currentGrade, targetGrade)
    if GSVU4UpgradesConfig.isRoofLightUpgradeId and GSVU4UpgradesConfig.isRoofLightUpgradeId(upgradeId) then return false end
    if GSVU4_oldCanUpgrade then return GSVU4_oldCanUpgrade(upgradeId, currentGrade, targetGrade) end
    return false
end


--========================================================
-- GSVU4_BULLBAR_UPGRADE_EXTENSION
-- Offensive bull / push bars for frontal ramming.
-- Bullbars do not reduce damage received by the vehicle.
--========================================================

GSVU4UpgradesConfig.BullBarGrades = { "Basic", "Standard", "Military" }
GSVU4UpgradesConfig.BullBarRank = { Basic = 1, Standard = 2, Military = 3 }

GSVU4UpgradesConfig.Upgrades.BullBar = {
    id = "BullBar",
    label = "Bull / Push Bar",
    description = "Front-mounted ramming upgrade. It improves frontal impacts against zombies and usable vehicles, but provides no defensive protection to the vehicle.",
    tools = {
        weldingMask = true,
        blowTorch = true,
        hammer = true,
        screwdriver = true,
    },
    toolLabels = {
        "Welding Mask",
        "Blowtorch",
        "Hammer",
        "Screwdriver",
    },
    grades = {
        Basic = {
            label = "Basic Bull / Push Bar",
            weight = 12,
            time = 180,
            health = 100,
            zombieKillSpeedMph = 60,
            zombieKillSpeedKph = 96.5606,
            zombieWidthScale = 1.00,
            frontWearPerDamage = 0.75,
            frontWearMin = 1,
            frontWearMax = 23,
            vehicleBonusStartMph = 15,
            vehicleBonusStartKph = 24.1402,
            vehicleBonusMax = 0.25,
            impactCooldownMs = 1200,
            fuelUse = 1,
            recipe = { bars = 2, sheets = 1, screws = 6 },
            skills = { MetalWelding = 2, Mechanics = 2 },
            xp = { MetalWelding = 6, Mechanics = 4 },
        },
        Standard = {
            label = "Standard Bull / Push Bar",
            weight = 20,
            time = 260,
            health = 100,
            zombieKillSpeedMph = 50,
            zombieKillSpeedKph = 80.4672,
            zombieWidthScale = 1.10,
            frontWearPerDamage = 0.45,
            frontWearMin = 1,
            frontWearMax = 15,
            vehicleBonusStartMph = 15,
            vehicleBonusStartKph = 24.1402,
            vehicleBonusMax = 0.50,
            impactCooldownMs = 1200,
            fuelUse = 2,
            recipe = { bars = 4, sheets = 2, screws = 10 },
            skills = { MetalWelding = 4, Mechanics = 3 },
            xp = { MetalWelding = 12, Mechanics = 7 },
        },
        Military = {
            label = "Military Bull / Push Bar",
            weight = 32,
            time = 380,
            health = 100,
            zombieKillSpeedMph = 40,
            zombieKillSpeedKph = 64.3738,
            zombieWidthScale = 1.35,
            frontWearPerDamage = 0.30,
            frontWearMin = 1,
            frontWearMax = 11,
            vehicleBonusStartMph = 15,
            vehicleBonusStartKph = 24.1402,
            vehicleBonusMax = 0.75,
            impactCooldownMs = 1200,
            fuelUse = 3,
            recipe = { bars = 6, sheets = 3, screws = 14, rods = 0.2 },
            skills = { MetalWelding = 6, Mechanics = 5 },
            xp = { MetalWelding = 20, Mechanics = 12 },
        },
    },
}

function GSVU4UpgradesConfig.isBullBarUpgradeId(upgradeId)
    return upgradeId == "BullBar"
end

function GSVU4UpgradesConfig.canUpgradeBullBar(currentGrade, targetGrade)
    local r = GSVU4UpgradesConfig.BullBarRank or { Basic=1, Standard=2, Military=3 }
    return (r[targetGrade] or 0) > (r[currentGrade] or 0)
end

local GSVU4_oldCanUpgradeBullBarWrap = GSVU4UpgradesConfig.canUpgrade
function GSVU4UpgradesConfig.canUpgrade(upgradeId, currentGrade, targetGrade)
    if upgradeId == "BullBar" then return GSVU4UpgradesConfig.canUpgradeBullBar(currentGrade, targetGrade) end
    if GSVU4_oldCanUpgradeBullBarWrap then return GSVU4_oldCanUpgradeBullBarWrap(upgradeId, currentGrade, targetGrade) end
    return false
end


--========================================================
-- GSVU4_AUTO_TUNE_MILITARY_RADIO_UPGRADE_EXTENSION
-- Single-grade add-on radio module. Installing it replaces the vehicle
-- Radio part item with Base.GSVU4AutoTuneMilitaryRadio, then programs
-- the device when installed and auto-tunes while the engine is running.
--========================================================

GSVU4UpgradesConfig.AutoTuneMilitaryRadioGrades = { "Military" }

GSVU4UpgradesConfig.Upgrades.AutoTuneMilitaryRadio = {
    id = "AutoTuneMilitaryRadio",
    label = "Auto Tune Military Radio",
    description = "Military vehicle radio module. Automatically tunes the vehicle radio to the current save's Emergency Broadcast channel when the driver enters with the engine running or starts the engine.",
    tools = {
        screwdriver = true,
    },
    toolLabels = {
        "Screwdriver",
    },
    grades = {
        Military = {
            label = "Auto Tune Military Radio",
            weight = 2,
            time = 160,
            health = 100,
            fuelUse = 0,
            tools = { screwdriver = true },
            toolLabels = { "Screwdriver" },
            radioRange = 1000000,
            recipe = { autoTuneMilitaryRadio = 1, screws = 6, electricWire = 2, wire = 2 },
            skills = { Mechanics = 2, Electricity = 4 },
            xp = { Mechanics = 4, Electricity = 8 },
        },
    },
}

function GSVU4UpgradesConfig.isAutoTuneMilitaryRadioUpgradeId(upgradeId)
    return upgradeId == "AutoTuneMilitaryRadio"
end

local GSVU4_oldCanUpgradeAutoTuneRadioWrap = GSVU4UpgradesConfig.canUpgrade
function GSVU4UpgradesConfig.canUpgrade(upgradeId, currentGrade, targetGrade)
    if upgradeId == "AutoTuneMilitaryRadio" then return false end
    if GSVU4_oldCanUpgradeAutoTuneRadioWrap then return GSVU4_oldCanUpgradeAutoTuneRadioWrap(upgradeId, currentGrade, targetGrade) end
    return false
end

--========================================================
-- GSVU4_TYRE_CHAINS_UPGRADE_UI_BRIDGE
-- Registers tyre chains as a single-stage item in the SVU4 Upgrades UI.
-- The actual install/remove/repair authority remains in the tyre-chain
-- client/server timed-action files.
--========================================================
pcall(require, "GoresSVU4TyreChains/GSVU4_TyreChains_Config")

GSVU4UpgradesConfig.TyreChainsGrades = { "Standard" }

GSVU4UpgradesConfig.Upgrades.TyreChains = {
    id = "TyreChains",
    label = "Tyre Chains",
    description = "Wheel-mounted chains for safer winter driving. Helps in snow but wears and makes noise on dry roads.",
    tools = {
        tyreChains = true,
    },
    toolLabels = {
        "Lug Wrench",
        "Wrench or Ratchet Wrench",
    },
    grades = {
        Standard = {
            label = "Tyre Chains",
            weight = 8,
            time = 240,
            health = 100,
            fuelUse = 0,
            recipe = { heavyChain = 4, wire = 4, screws = 16, ductTape = 1 },
            skills = { MetalWelding = 0, Mechanics = 5, Electricity = 0 },
            xp = { Mechanics = 4 },
        },
    },
}

function GSVU4UpgradesConfig.isTyreChainsUpgradeId(upgradeId)
    return upgradeId == "TyreChains"
end

local GSVU4_oldCanUpgradeTyreChainsWrap = GSVU4UpgradesConfig.canUpgrade
function GSVU4UpgradesConfig.canUpgrade(upgradeId, currentGrade, targetGrade)
    if upgradeId == "TyreChains" then return false end
    if GSVU4_oldCanUpgradeTyreChainsWrap then return GSVU4_oldCanUpgradeTyreChainsWrap(upgradeId, currentGrade, targetGrade) end
    return false
end


--========================================================
-- GSVU4_PLOW_DEFENCE_UPGRADE_EXTENSION
-- Defensive front fixture. Pushes zombies laterally without scripted damage.
-- Mutually exclusive with every Bull / Push Bar grade.
--========================================================

GSVU4UpgradesConfig.PlowGrades = { "Standard", "Reinforced" }

GSVU4UpgradesConfig.Upgrades.Plow = {
    id = "Plow",
    label = "Defensive Plow",
    description = "Front-mounted crowd-control blade. It pushes zombies sideways instead of increasing collision damage. Heavier vehicles generate stronger displacement.",
    tools = {
        weldingMask = true,
        blowTorch = true,
        hammer = true,
        screwdriver = true,
    },
    toolLabels = {
        "Welding Mask",
        "Blowtorch",
        "Hammer",
        "Screwdriver",
    },
    grades = {
        Standard = {
            label = "Standard Toothed Plow",
            weight = 38,
            time = 320,
            uninstallTime = 260,
            health = 100,
            minPushKph = 10,
            fullPushKph = 45,
            pushMultiplier = 1.00,
            widthScale = 1.00,
            normalWear = 0.50,
            strongWear = 1.00,
            knockdownThreshold = 0.95,
            pushCooldownMs = 700,
            fuelUse = 2,
            recipe = { bars = 5, sheets = 3, screws = 12 },
            skills = { MetalWelding = 4, Mechanics = 4 },
            xp = { MetalWelding = 14, Mechanics = 8 },
        },
        Reinforced = {
            label = "Reinforced Heavy Plow",
            weight = 55,
            time = 440,
            uninstallTime = 340,
            health = 150,
            minPushKph = 10,
            fullPushKph = 45,
            pushMultiplier = 1.15,
            widthScale = 1.05,
            normalWear = 0.50,
            strongWear = 1.00,
            knockdownThreshold = 0.90,
            pushCooldownMs = 650,
            fuelUse = 3,
            recipe = { bars = 8, sheets = 4, screws = 16, rods = 0.2 },
            skills = { MetalWelding = 6, Mechanics = 5 },
            xp = { MetalWelding = 22, Mechanics = 13 },
        },
    },
}

function GSVU4UpgradesConfig.isPlowUpgradeId(upgradeId)
    return tostring(upgradeId or "") == "Plow"
end

function GSVU4UpgradesConfig.isFrontFixtureUpgradeId(upgradeId)
    upgradeId = tostring(upgradeId or "")
    return upgradeId == "BullBar" or upgradeId == "Plow"
end

function GSVU4UpgradesConfig.getInstalledFrontFixture(vehicle, exceptUpgradeId)
    if not vehicle or not vehicle.getModData then return nil, nil end
    local ok, md = pcall(function() return vehicle:getModData() end)
    local upgrades = ok and md and md.gUpgrades or nil
    if not upgrades then return nil, nil end
    for _, upgradeId in ipairs({ "BullBar", "Plow" }) do
        if tostring(upgradeId) ~= tostring(exceptUpgradeId or "") then
            local fixture = upgrades[upgradeId]
            if type(fixture) == "table" and fixture.grade then
                return upgradeId, fixture
            end
        end
    end
    return nil, nil
end

function GSVU4UpgradesConfig.canInstallFrontFixture(vehicle, targetUpgradeId)
    if not GSVU4UpgradesConfig.isFrontFixtureUpgradeId(targetUpgradeId) then
        return true, nil
    end
    local installedId = GSVU4UpgradesConfig.getInstalledFrontFixture(vehicle, targetUpgradeId)
    if installedId then
        return false, "Another front fixture is already installed. Uninstall it before fitting this one."
    end
    return true, nil
end

local GSVU4_oldCanUpgradePlowWrap = GSVU4UpgradesConfig.canUpgrade
function GSVU4UpgradesConfig.canUpgrade(upgradeId, currentGrade, targetGrade)
    -- Plow variants are physical alternatives. Remove the existing blade before
    -- fitting the other version so materials and integrity are never overwritten.
    if tostring(upgradeId or "") == "Plow" then return false end
    if GSVU4_oldCanUpgradePlowWrap then
        return GSVU4_oldCanUpgradePlowWrap(upgradeId, currentGrade, targetGrade)
    end
    return false
end

--========================================================
-- Filtered Air Intake
-- Full corpse-fume protection while the engine is running and every cabin
-- opening is present, intact and closed. Grades change filter endurance only.
--========================================================
GSVU4UpgradesConfig.FilteredAirIntakeGrades = { "Basic", "Standard", "Military" }
GSVU4UpgradesConfig.Upgrades.FilteredAirIntake = {
    id = "FilteredAirIntake",
    label = "Filtered Air Intake",
    description = "Raised filtered cabin-air intake. Fully protects occupants from corpse fumes only while the engine is running and the cabin is completely sealed.",
    tools = { weldingMask = true, blowTorch = true, screwdriver = true },
    toolLabels = { "Welding Mask", "Blowtorch", "Screwdriver" },
    grades = {
        Basic = {
            label = "Basic Filtered Air Intake",
            filterCapacityMax = 50,
            capacity = 50,
            weight = 5,
            health = 100,
            time = 180,
            fuelUse = 1,
            recipe = { bars = 1, sheets = 1, screws = 6, electricWire = 2, wire = 1 },
            skills = { MetalWelding = 2, Mechanics = 2, Electricity = 2 },
            xp = { MetalWelding = 7, Mechanics = 3, Electricity = 3 },
        },
        Standard = {
            label = "Standard Filtered Air Intake",
            filterCapacityMax = 75,
            capacity = 75,
            weight = 8,
            health = 125,
            time = 260,
            fuelUse = 2,
            recipe = { bars = 2, sheets = 2, screws = 8, electricWire = 3, wire = 2 },
            skills = { MetalWelding = 3, Mechanics = 3, Electricity = 4 },
            xp = { MetalWelding = 11, Mechanics = 5, Electricity = 6 },
        },
        Military = {
            label = "Military Filtered Air Intake",
            filterCapacityMax = 100,
            capacity = 100,
            weight = 12,
            health = 150,
            time = 360,
            fuelUse = 3,
            recipe = { bars = 3, sheets = 3, screws = 12, electricWire = 4, wire = 2, rods = 0.2 },
            skills = { MetalWelding = 5, Mechanics = 4, Electricity = 6 },
            xp = { MetalWelding = 17, Mechanics = 7, Electricity = 10 },
        },
    },
}

--========================================================
-- Engine Scoop / improvised forced-induction upgrade
-- Optional visual packs register vehicles with matching fitted scoop meshes.
-- Power is offset by increased real fuel use, unavoidable running wear, and
-- accelerated engine damage when an improvised setup is held above its safe
-- speed for too long.
--========================================================
GSVU4UpgradesConfig.EngineScoopGrades = {
    "Small",
    "Medium",
    "SmallRound",
    "Large",
    "LargeRound",
    "Piped",
}

GSVU4UpgradesConfig.Upgrades.EngineScoop = {
    id = "EngineScoop",
    label = "Engine Scoop",
    description = "Improvised hood-fed forced induction. Adds engine force, burns extra fuel, steadily wears the engine, and becomes increasingly dangerous at sustained high speed.",
    tools = { weldingMask = true, blowTorch = true, hammer = true, screwdriver = true },
    toolLabels = { "Welding Mask", "Blowtorch", "Hammer", "Screwdriver" },
    grades = {
        Small = {
            label = "Small Field Intake Scoop",
            engineForceMultiplier = 1.09,
            extraFuelFraction = 0.14,
            wearHoursPerCondition = 12.0,
            stressSpeedMph = 95,
            stressGraceSeconds = 45,
            stressDamageIntervalSeconds = 15,
            weight = 4,
            health = 100,
            time = 220,
            fuelUse = 1,
            recipe = { bars = 1, sheets = 1, screws = 6, wire = 1 },
            skills = { MetalWelding = 2, Mechanics = 3 },
            xp = { MetalWelding = 7, Mechanics = 6 },
        },
        Medium = {
            label = "Medium Tuned Intake Scoop",
            engineForceMultiplier = 1.17,
            extraFuelFraction = 0.22,
            wearHoursPerCondition = 9.0,
            stressSpeedMph = 95,
            stressGraceSeconds = 35,
            stressDamageIntervalSeconds = 13,
            weight = 6,
            health = 110,
            time = 280,
            fuelUse = 2,
            recipe = { bars = 2, sheets = 2, screws = 8, wire = 2 },
            skills = { MetalWelding = 3, Mechanics = 4 },
            xp = { MetalWelding = 10, Mechanics = 8 },
        },
        SmallRound = {
            label = "Small Round Ram Intake",
            engineForceMultiplier = 1.19,
            extraFuelFraction = 0.26,
            wearHoursPerCondition = 8.0,
            stressSpeedMph = 90,
            stressGraceSeconds = 28,
            stressDamageIntervalSeconds = 11,
            weight = 7,
            health = 115,
            time = 310,
            fuelUse = 2,
            recipe = { bars = 2, sheets = 2, screws = 9, wire = 2, rods = 0.1 },
            skills = { MetalWelding = 4, Mechanics = 4 },
            xp = { MetalWelding = 12, Mechanics = 9 },
        },
        Large = {
            label = "Large Performance Scoop",
            engineForceMultiplier = 1.27,
            extraFuelFraction = 0.34,
            wearHoursPerCondition = 6.0,
            stressSpeedMph = 90,
            stressGraceSeconds = 23,
            stressDamageIntervalSeconds = 10,
            weight = 9,
            health = 125,
            time = 360,
            fuelUse = 3,
            recipe = { bars = 3, sheets = 3, screws = 12, wire = 2, rods = 0.1 },
            skills = { MetalWelding = 5, Mechanics = 5 },
            xp = { MetalWelding = 16, Mechanics = 12 },
        },
        LargeRound = {
            label = "Large Round Ram Intake",
            engineForceMultiplier = 1.30,
            extraFuelFraction = 0.38,
            wearHoursPerCondition = 5.0,
            stressSpeedMph = 88,
            stressGraceSeconds = 20,
            stressDamageIntervalSeconds = 9,
            weight = 10,
            health = 135,
            time = 400,
            fuelUse = 3,
            recipe = { bars = 3, sheets = 3, screws = 14, wire = 3, rods = 0.2 },
            skills = { MetalWelding = 5, Mechanics = 6 },
            xp = { MetalWelding = 18, Mechanics = 14 },
        },
        Piped = {
            label = "Piped Hot-Rod Intake",
            engineForceMultiplier = 1.36,
            extraFuelFraction = 0.45,
            wearHoursPerCondition = 3.0,
            stressSpeedMph = 85,
            stressGraceSeconds = 15,
            stressDamageIntervalSeconds = 8,
            weight = 12,
            health = 150,
            time = 460,
            fuelUse = 4,
            recipe = { bars = 4, sheets = 4, screws = 16, wire = 4, rods = 0.3 },
            skills = { MetalWelding = 7, Mechanics = 8 },
            xp = { MetalWelding = 25, Mechanics = 20 },
        },
    },
}

function GSVU4UpgradesConfig.isEngineScoopUpgradeId(upgradeId)
    return tostring(upgradeId or "") == "EngineScoop"
end

-- Scoop shapes are complete physical alternatives, not linear upgrades.
-- Remove the current assembly before fitting another one.
local GSVU4_oldCanUpgradeEngineScoopWrap = GSVU4UpgradesConfig.canUpgrade
function GSVU4UpgradesConfig.canUpgrade(upgradeId, currentGrade, targetGrade)
    if tostring(upgradeId or "") == "EngineScoop" then return false end
    if GSVU4_oldCanUpgradeEngineScoopWrap then
        return GSVU4_oldCanUpgradeEngineScoopWrap(upgradeId, currentGrade, targetGrade)
    end
    return false
end
