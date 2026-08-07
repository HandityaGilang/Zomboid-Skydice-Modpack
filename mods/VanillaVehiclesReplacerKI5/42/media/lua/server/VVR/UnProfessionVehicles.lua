if getActivatedMods():contains("\\85chevyCaprice") then
	require "Vehicles/85chevyCaprice_ProfessionVehicles"
	
	ProfessionVehicles["85chevyImpalaSedanPD"] = {}
end

if getActivatedMods():contains("\\85chevyStepVanexpanded") then
	require "Vehicles/85chevyStepVanexpanded_ProfessionVehicles"
end

if getActivatedMods():contains("\\86fordE150expanded") then
	require "Vehicles/86fordE150expanded_ProfessionVehicles"
end

if getActivatedMods():contains("\\93chevySuburbanExpanded") then
	require "Vehicles/93chevySuburbanExpanded_ProfessionVehicles"
	
	ProfessionVehicles["93chevySuburbanpd"] = {}
end

ProfessionVehicles.RaceCarBurnt = {}
ProfessionVehicles.PickUpVanLightsPolice = {}
ProfessionVehicles.CarLightsPolice = {}

ProfessionVehicles.UniqueVehicles = {}
ProfessionVehicles.VanSeats_Mural = {}
ProfessionVehicles.VanBuilder = {}
ProfessionVehicles.VanCarpenter = {}
ProfessionVehicles.VanGardener = {}
ProfessionVehicles.VanMechanic = {}
ProfessionVehicles.VanMetalworker = {}
ProfessionVehicles.PickUpVanBuilder = {}
ProfessionVehicles.PickUpVanLightsCarpenter = {}
ProfessionVehicles.PickUpVanMetalworker = {}
ProfessionVehicles.StepVan_Mechanic = {}