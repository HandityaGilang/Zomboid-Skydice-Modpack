require "Vehicles/VehicleDistributions"

-- B42: guard against missing vehicle distribution tables
local function safeVehicleInsert(tblName, item, chance)
    if VehicleDistributions and VehicleDistributions[tblName] and VehicleDistributions[tblName].items then
        table.insert(VehicleDistributions[tblName].items, item)
        table.insert(VehicleDistributions[tblName].items, chance)
    end
end

safeVehicleInsert("PostalTruckBed", "RGM.BookTinkering1", 6)
safeVehicleInsert("PostalTruckBed", "RGM.BookTinkering2", 4)
safeVehicleInsert("PostalTruckBed", "RGM.BookTinkering3", 2)
safeVehicleInsert("PostalTruckBed", "RGM.BookTinkering4", 1)
safeVehicleInsert("PostalTruckBed", "RGM.BookTinkering5", 0.5)
safeVehicleInsert("PostalTruckBed", "RGM.TinkeringMag",   0.5)

-- Alias kept for backward compat; only set if the source exists
if VehicleDistributions and VehicleDistributions.PostalTruckBed then
    if VehicleDistributions.Postal then
        VehicleDistributions.Postal.TruckBed = VehicleDistributions.PostalTruckBed
    end
end
