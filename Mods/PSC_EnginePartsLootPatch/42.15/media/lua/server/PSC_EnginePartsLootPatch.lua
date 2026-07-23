-- Project Summer Car Engine Parts Loot Patch
-- Adds Project Summer Car engine parts/fluids to world loot distributions.
-- v3: base spawn weights reduced by 60%, global multiplier default is 1.0, duplicate-safe insertion.
-- Server-side distribution patch. Load after Project Summer Car.

if isClient() then return end

require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"
require "Items/Distributions"

PSC_EngineLootPatch = PSC_EngineLootPatch or {}
PSC_EngineLootPatch.applied = PSC_EngineLootPatch.applied or false

local PSC_ITEMS = {
    { name = "Base.AirConditioner1_1", key = "AirConditioner1_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.AirConditioner1_2", key = "AirConditioner1_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.AirConditioner1_3", key = "AirConditioner1_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Alternator1_1", key = "Alternator1_1", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Alternator1_2", key = "Alternator1_2", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Alternator1_3", key = "Alternator1_3", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.BottleATF", key = "BottleATF", gas = 1.80, garage = 2.20, special = 1.80 },
    { name = "Base.BottleAntifreeze1", key = "BottleAntifreeze1", gas = 1.80, garage = 2.20, special = 1.80 },
    { name = "Base.BottleAntifreeze2", key = "BottleAntifreeze2", gas = 1.80, garage = 2.20, special = 1.80 },
    { name = "Base.BottleMotorOil", key = "BottleMotorOil", gas = 1.80, garage = 2.20, special = 1.80 },
    { name = "Base.BottleMotorOilCan", key = "BottleMotorOilCan", gas = 1.80, garage = 2.20, special = 1.80 },
    { name = "Base.BrakeBooster1_1", key = "BrakeBooster1_1", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.BrakeBooster1_2", key = "BrakeBooster1_2", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.BrakeBooster1_3", key = "BrakeBooster1_3", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Crankshaft1_1", key = "Crankshaft1_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Crankshaft1_2", key = "Crankshaft1_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Crankshaft1_3", key = "Crankshaft1_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Crankshaft2_1", key = "Crankshaft2_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Crankshaft2_2", key = "Crankshaft2_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Crankshaft2_3", key = "Crankshaft2_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Crankshaft3_1", key = "Crankshaft3_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Crankshaft3_2", key = "Crankshaft3_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Crankshaft3_3", key = "Crankshaft3_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.CylinderHead1_1", key = "CylinderHead1_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.CylinderHead1_2", key = "CylinderHead1_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.CylinderHead1_3", key = "CylinderHead1_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.CylinderHead2_1", key = "CylinderHead2_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.CylinderHead2_2", key = "CylinderHead2_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.CylinderHead2_3", key = "CylinderHead2_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.CylinderHead3_1", key = "CylinderHead3_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.CylinderHead3_2", key = "CylinderHead3_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.CylinderHead3_3", key = "CylinderHead3_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.FanBelt1_1", key = "FanBelt1_1", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.FanBelt1_2", key = "FanBelt1_2", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.FanBelt1_3", key = "FanBelt1_3", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Flywheel1_1", key = "Flywheel1_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Flywheel1_2", key = "Flywheel1_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Flywheel1_3", key = "Flywheel1_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Flywheel2_1", key = "Flywheel2_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Flywheel2_2", key = "Flywheel2_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Flywheel2_3", key = "Flywheel2_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Flywheel3_1", key = "Flywheel3_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Flywheel3_2", key = "Flywheel3_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Flywheel3_3", key = "Flywheel3_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.HeadGasket1_1", key = "HeadGasket1_1", gas = 0.80, garage = 1.40, special = 1.40 },
    { name = "Base.HeadGasket1_2", key = "HeadGasket1_2", gas = 0.80, garage = 1.40, special = 1.40 },
    { name = "Base.HeadGasket1_3", key = "HeadGasket1_3", gas = 0.80, garage = 1.40, special = 1.40 },
    { name = "Base.HeaterCore1_1", key = "HeaterCore1_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.HeaterCore1_2", key = "HeaterCore1_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.HeaterCore1_3", key = "HeaterCore1_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.OilFilter1_1", key = "OilFilter1_1", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.OilFilter1_2", key = "OilFilter1_2", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.OilFilter1_3", key = "OilFilter1_3", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.OilPan1_1", key = "OilPan1_1", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.OilPan1_2", key = "OilPan1_2", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.OilPan1_3", key = "OilPan1_3", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Pistons1_1", key = "Pistons1_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Pistons1_2", key = "Pistons1_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Pistons1_3", key = "Pistons1_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Pistons2_1", key = "Pistons2_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Pistons2_2", key = "Pistons2_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Pistons2_3", key = "Pistons2_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Pistons3_1", key = "Pistons3_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Pistons3_2", key = "Pistons3_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Pistons3_3", key = "Pistons3_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.PowerSteeringPump1_1", key = "PowerSteeringPump1_1", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.PowerSteeringPump1_2", key = "PowerSteeringPump1_2", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.PowerSteeringPump1_3", key = "PowerSteeringPump1_3", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Radiator1_1", key = "Radiator1_1", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Radiator1_2", key = "Radiator1_2", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Radiator1_3", key = "Radiator1_3", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Radiator2_1", key = "Radiator2_1", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Radiator2_2", key = "Radiator2_2", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Radiator2_3", key = "Radiator2_3", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Radiator3_1", key = "Radiator3_1", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Radiator3_2", key = "Radiator3_2", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Radiator3_3", key = "Radiator3_3", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Sparkplug1_1", key = "Sparkplug1_1", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Sparkplug1_2", key = "Sparkplug1_2", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Sparkplug1_3", key = "Sparkplug1_3", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Sparkplug2_1", key = "Sparkplug2_1", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Sparkplug2_2", key = "Sparkplug2_2", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Sparkplug2_3", key = "Sparkplug2_3", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Sparkplug3_1", key = "Sparkplug3_1", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Sparkplug3_2", key = "Sparkplug3_2", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Sparkplug3_3", key = "Sparkplug3_3", gas = 1.20, garage = 1.80, special = 1.60 },
    { name = "Base.Starter1_1", key = "Starter1_1", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Starter1_2", key = "Starter1_2", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.Starter1_3", key = "Starter1_3", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.ToolKit", key = "ToolKit", gas = 0.10, garage = 0.24, special = 0.32 },
    { name = "Base.TorqueConverter1_1", key = "TorqueConverter1_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.TorqueConverter1_2", key = "TorqueConverter1_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.TorqueConverter1_3", key = "TorqueConverter1_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.TorqueConverter2_1", key = "TorqueConverter2_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.TorqueConverter2_2", key = "TorqueConverter2_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.TorqueConverter2_3", key = "TorqueConverter2_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.TorqueConverter3_1", key = "TorqueConverter3_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.TorqueConverter3_2", key = "TorqueConverter3_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.TorqueConverter3_3", key = "TorqueConverter3_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission1_1", key = "Transmission1_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission1_2", key = "Transmission1_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission1_3", key = "Transmission1_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission2_1", key = "Transmission2_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission2_2", key = "Transmission2_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission2_3", key = "Transmission2_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission3_1", key = "Transmission3_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission3_2", key = "Transmission3_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission3_3", key = "Transmission3_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission4_1", key = "Transmission4_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission4_2", key = "Transmission4_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission4_3", key = "Transmission4_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission5_1", key = "Transmission5_1", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission5_2", key = "Transmission5_2", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.Transmission5_3", key = "Transmission5_3", gas = 0.00, garage = 0.48, special = 0.84 },
    { name = "Base.WaterPump1_1", key = "WaterPump1_1", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.WaterPump1_2", key = "WaterPump1_2", gas = 0.00, garage = 0.88, special = 0.96 },
    { name = "Base.WaterPump1_3", key = "WaterPump1_3", gas = 0.00, garage = 0.88, special = 0.96 },
}

-- v4: remove all *_4 Project Summer Car engine parts from world loot.
-- These parts appear in the admin item list, but they are intentionally not injected into loot.

local PSC_REMOVED_NO4_ITEMS = {
    "Base.AirConditioner1_4",
    "Base.Alternator1_4",
    "Base.BrakeBooster1_4",
    "Base.Crankshaft1_4",
    "Base.Crankshaft2_4",
    "Base.Crankshaft3_4",
    "Base.CylinderHead1_4",
    "Base.CylinderHead2_4",
    "Base.CylinderHead3_4",
    "Base.FanBelt1_4",
    "Base.Flywheel1_4",
    "Base.Flywheel2_4",
    "Base.Flywheel3_4",
    "Base.HeadGasket1_4",
    "Base.HeaterCore1_4",
    "Base.OilFilter1_4",
    "Base.OilPan1_4",
    "Base.Pistons1_4",
    "Base.Pistons2_4",
    "Base.Pistons3_4",
    "Base.PowerSteeringPump1_4",
    "Base.Radiator1_4",
    "Base.Radiator2_4",
    "Base.Radiator3_4",
    "Base.Sparkplug1_4",
    "Base.Sparkplug2_4",
    "Base.Sparkplug3_4",
    "Base.Starter1_4",
    "Base.TorqueConverter1_4",
    "Base.TorqueConverter2_4",
    "Base.TorqueConverter3_4",
    "Base.Transmission1_4",
    "Base.Transmission2_4",
    "Base.Transmission3_4",
    "Base.Transmission4_4",
    "Base.Transmission5_4",
    "Base.WaterPump1_4",

}

local GAS_LISTS = { "GasStorageMechanics", "GasStorageCombo", "GasStorageTools", "GasStoreShelf", "GasStoreCounter" }
local GARAGE_LISTS = { "GarageMechanics", "MechanicShelfTools", "MechanicShelfMisc", "ToolCabinetMechanics", "CrateMechanics", "CrateMetalwork", "ToolStoreTools", "CarSupplyTools", "MechanicShelfOutfit" }
local SPECIAL_LISTS = { "MechanicSpecial", "ToolStoreMechanics", "MechanicShelfTools", "GarageMechanics", "CrateMechanics" }

local function sandbox()
    return SandboxVars and SandboxVars.PSCSpawnPatch or {}
end

local function num(value, default)
    if value == nil then return default end
    value = tonumber(value)
    if value == nil then return default end
    return value
end

local function removeExistingItem(items, fullType)
    if not items or not fullType then return end
    for i = #items - 1, 1, -2 do
        if items[i] == fullType then
            table.remove(items, i + 1)
            table.remove(items, i)
        end
    end
end

local function addItem(items, fullType, weight)
    if not items or not fullType then return end
    removeExistingItem(items, fullType)
    if not weight or weight <= 0 then return end
    table.insert(items, fullType)
    table.insert(items, weight)
end


local function removeNo4ItemsFromProcedural(listName)
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    local dist = ProceduralDistributions.list[listName]
    if not dist or not dist.items then return end
    removeNo4ItemsFromProcedural(listName)
    for _, fullType in ipairs(PSC_REMOVED_NO4_ITEMS) do
        removeExistingItem(dist.items, fullType)
    end
end

local function addItemsToProcedural(listName, context, contextMultiplier)
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    local dist = ProceduralDistributions.list[listName]
    if not dist or not dist.items then return end

    local sv = sandbox()
    local global = num(sv.GlobalMultiplier, 1.0)
    contextMultiplier = num(contextMultiplier, 1.0)

    for _, item in ipairs(PSC_ITEMS) do
        local baseWeight = num(item[context], 0)
        if baseWeight > 0 then
            local itemMultiplier = num(sv[item.key], 1.0)
            local finalWeight = baseWeight * global * contextMultiplier * itemMultiplier
            addItem(dist.items, item.name, finalWeight)
        end
    end
end

local function applyPSCWorldLoot()
    if PSC_EngineLootPatch.applied then return end
    PSC_EngineLootPatch.applied = true

    local sv = sandbox()
    if sv.EnablePatch == false then
        print("PSC Engine Parts Loot Patch v4: disabled by sandbox.")
        return
    end

    local gasMult = num(sv.GasStationMultiplier, 1.0)
    local mechMult = num(sv.MechanicMultiplier, 1.0)
    local specialMult = num(sv.SpecialPartsMultiplier, 1.0)

    for _, listName in ipairs(GAS_LISTS) do
        addItemsToProcedural(listName, "gas", gasMult)
    end

    for _, listName in ipairs(GARAGE_LISTS) do
        addItemsToProcedural(listName, "garage", mechMult)
    end

    for _, listName in ipairs(SPECIAL_LISTS) do
        addItemsToProcedural(listName, "special", mechMult * specialMult)
    end

    print("PSC Engine Parts Loot Patch v4: Project Summer Car parts added with sandbox multipliers. *_4 non-installable parts excluded from world loot.")
end

applyPSCWorldLoot()
