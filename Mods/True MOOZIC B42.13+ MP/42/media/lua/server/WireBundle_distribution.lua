-- WireBundle_distribution.lua
-- Adds Tsarcraft.WireBundle (Speaker Wire) to loot tables

require "Items/ProceduralDistributions"
require "Vehicles/VehicleDistributions"

local WIRE = "Tsarcraft.WireBundle"

------------------------------------------------------------------
-- Helper: safely add to a procedural distribution list
------------------------------------------------------------------
local function addToProc(listName, weight)
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    local list = ProceduralDistributions.list[listName]
    if not list or not list.items then return end
    table.insert(list.items, WIRE)
    table.insert(list.items, weight)
end

------------------------------------------------------------------
-- Helper: safely add to a vehicle distribution
------------------------------------------------------------------
local function addToVehicle(distName, weight)
    if not VehicleDistributions then return end
    local dist = VehicleDistributions[distName]
    if not dist or not dist.items then return end
    table.insert(dist.items, WIRE)
    table.insert(dist.items, weight)
end

------------------------------------------------------------------
-- Electronics / Music stores  (best chance)
------------------------------------------------------------------
addToProc("ElectronicStoreMusic",      4)
addToProc("ElectronicStoreMisc",       2)
addToProc("ElectronicStoreAppliances", 1)
addToProc("MusicStoreOthers",          4)
addToProc("MusicStoreCDs",             1)

------------------------------------------------------------------
-- Hardware / Tool stores
------------------------------------------------------------------
addToProc("ToolStoreMisc",        3)
addToProc("ToolStoreAccessories", 2)
addToProc("ToolStoreTools",       1)

------------------------------------------------------------------
-- Gas stations
------------------------------------------------------------------
addToProc("GasStorageCombo",    1)
addToProc("GasStoreSpecial",   1)

------------------------------------------------------------------
-- Mall / Department / Gigamart
------------------------------------------------------------------
addToProc("GigamartHouseElectronics", 2)
addToProc("GigamartTools",           1)
addToProc("CrateElectronics",        2)

------------------------------------------------------------------
-- Mechanic shelves (wiring is plausible here)
------------------------------------------------------------------
addToProc("MechanicShelfElectric", 3)
addToProc("MechanicShelfMisc",    1)
addToProc("GarageMechanics",      1)
addToProc("StoreShelfMechanics",  1)

------------------------------------------------------------------
-- General shelves where boomboxes / radios appear
------------------------------------------------------------------
addToProc("LivingRoomShelf",  0.5)

------------------------------------------------------------------
-- Maintenance / mechanic vehicles
------------------------------------------------------------------
addToVehicle("VanMechanic",            2)
addToVehicle("VanMobileMechanics",     2)
addToVehicle("VanMooreMechanics",      2)
addToVehicle("VanPluggedInElectrics",  3)
addToVehicle("VanUtility",            1)
addToVehicle("VanBuilder",            1)
addToVehicle("VanCarpenter",          1)
