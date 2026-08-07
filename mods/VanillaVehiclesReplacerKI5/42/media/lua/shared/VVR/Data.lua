local __utils = require("YAPZLib/Utils")
local __isVanilla = require("YAPZLib/VehicleUtils").isVanilla

local Data = {}
Data.Tab = {}

local replaceTableIfEmpty = function(tab1, tab2)
	if __utils.tableIsEmpty(tab1) then
		return __utils.copyTable(tab2)
	end
	
	return tab1
end

Data.Add = function(scriptName, region, vehicleName, skinIndices, chance, sortType, typeChance, needRecalcChances)
	if not __isVanilla(scriptName) then
		return
	else
		if not Data.Tab[scriptName] then Data.Tab[scriptName] = {} end
	end
	
	if not Data.Tab[scriptName][region] then Data.Tab[scriptName][region] = {} end
	if not ScriptManager.instance:getVehicle(vehicleName) then return end
	local vehicleData = { vehicleName = vehicleName, skinIndices = skinIndices, chance = chance, sortType = sortType, typeChance = typeChance }
	table.insert(Data.Tab[scriptName][region], vehicleData)
	if needRecalcChances then
		Data.RecalcChances()
	end
end

Data.Remove = function(scriptName, region, vehicleName, needRecalcChances)
	if not Data.Tab[scriptName] then return end
	if not Data.Tab[scriptName][region] then return end
	if not ScriptManager.instance:getVehicle(vehicleName) then return end
	for num = #Data.Tab[scriptName][region], 1, -1 do
		if Data.Tab[scriptName][region][num].vehicleName == vehicleName then
			table.remove(Data.Tab[scriptName][region], num)
		end
	end
	if needRecalcChances then
		Data.RecalcChances()
	end
end

Data.Empty = function(scriptName)
	if not Data.Tab[scriptName] then return end
	Data.Tab[scriptName] = {}
end

Data.EmptyRegion = function(scriptName, region)
	if not Data.Tab[scriptName] then return end
	if not Data.Tab[scriptName][region] then return end
	Data.Tab[scriptName][region] = {}
end

Data.Find = function(vehicleName)
	if not ScriptManager.instance:getVehicle(vehicleName) then return end
	local data = {}
	
	for scriptName, baseVehicleData in pairs(Data.Tab) do
		for region, regionVehicleData in pairs(baseVehicleData) do	
			for _, vehicleData in ipairs(regionVehicleData) do
				if vehicleData.vehicleName == vehicleName then
					data[scriptName] = data[scriptName] or {}
					table.insert(data[scriptName], region)
				end
			end
		end
	end
	
	return data
end

local sort = function(regionVehicleData)
	local sumChances = {}
	for _, vehicleData in ipairs(regionVehicleData) do
		if vehicleData.chance and vehicleData.sortType then
			if not sumChances[vehicleData.sortType] then sumChances[vehicleData.sortType] = 0 end
			sumChances[vehicleData.sortType] = sumChances[vehicleData.sortType] + vehicleData.chance
		end
	end
	table.sort(regionVehicleData, function(a, b)
		if sumChances[a.sortType] ~= sumChances[b.sortType] then
			return sumChances[a.sortType] > sumChances[b.sortType]
		end
		return a.sortType < b.sortType
	end)
end

local recalcSpecialChances = function()
	for _, baseVehicleData in pairs(Data.Tab) do
		for region, regionVehicleData in pairs(baseVehicleData) do
			local regionChances = {}
			local sumChances = {}	
			for _, vehicleData in ipairs(regionVehicleData) do
				if vehicleData.chance and vehicleData.sortType and vehicleData.typeChance then
					for ptype in vehicleData.sortType:gmatch("_.+$") do
						ptype = ptype:gsub("^_", "")
						if not regionChances[region] then regionChances[region] = {} end
						if not regionChances[region][ptype] then regionChances[region][ptype] = vehicleData.typeChance end
						if not sumChances[ptype] then sumChances[ptype] = 0 end
						sumChances[ptype] = sumChances[ptype] + vehicleData.chance
					end
				end
			end
			for _, vehicleData in ipairs(regionVehicleData) do
				if vehicleData.chance and vehicleData.sortType and vehicleData.typeChance then
					for ptype in vehicleData.sortType:gmatch("_.+$") do
						ptype = ptype:gsub("^_", "")
						local chance = round((vehicleData.chance * regionChances[region][ptype]) / sumChances[ptype], 2)
						if vehicleData.chance ~= chance then vehicleData.chance = chance end
					end
				end
			end
		end
	end
end
	
Data.RecalcChances = function()
	recalcSpecialChances()
	for _, baseVehicleData in pairs(Data.Tab) do
		for _, regionVehicleData in pairs(baseVehicleData) do
			local sumChances = 0
			for _, vehicleData in ipairs(regionVehicleData) do
				if vehicleData.chance then
					sumChances = sumChances + vehicleData.chance
				end
			end
			for _, vehicleData in ipairs(regionVehicleData) do
				if vehicleData.chance then
					local chance = round((vehicleData.chance * 100) / sumChances, 2)
					if vehicleData.chance ~= chance then vehicleData.chance = chance end
				end
			end
			sort(regionVehicleData)
		end
	end
end

Data.Tab["Base.CarNormal"] = {}
Data.Tab["Base.SmallCar"] = Data.Tab["Base.CarNormal"]
Data.Tab["Base.SmallCar02"] = Data.Tab["Base.CarNormal"]
Data.Tab["Base.ModernCar"] = {}
Data.Tab["Base.ModernCar02"] = Data.Tab["Base.ModernCar"]
Data.Tab["Base.CarTaxi"] = {}
Data.Tab["Base.CarTaxi2"] = Data.Tab["Base.CarTaxi"]
Data.Tab["Base.PickUpTruck"] = {}
Data.Tab["Base.PickUpTruck_Camo"] = Data.Tab["Base.PickUpTruck"]
Data.Tab["Base.PickUpVan"] = {}
Data.Tab["Base.PickUpVan_Camo"] = Data.Tab["Base.PickUpVan"]
Data.Tab["Base.CarStationWagon"] = {}
Data.Tab["Base.CarStationWagon2"] = Data.Tab["Base.CarStationWagon"]
Data.Tab["Base.VanSeats"] = {}
Data.Tab["Base.Van"] = {}
Data.Tab["Base.StepVan"] = Data.Tab["Base.Van"]
Data.Tab["Base.SUV"] = {}
Data.Tab["Base.OffRoad"] = {}
Data.Tab["Base.CarLuxury"] = {}
Data.Tab["Base.SportsCar"] = {}
Data.Tab["Base.RaceCar12"] = {}
Data.Tab["Base.RaceCar34"] = Data.Tab["Base.RaceCar12"]
Data.Tab["Base.RaceCar58"] = Data.Tab["Base.RaceCar12"]
Data.Tab["Base.PickUpTruckLightsFire"] = {}
Data.Tab["Base.PickUpVanLightsFire"] = Data.Tab["Base.PickUpTruckLightsFire"]
Data.Tab["Base.CarLightsRanger"] = {}
Data.Tab["Base.PickUpTruckLightsRanger"] = {}
Data.Tab["Base.PickUpVanLightsRanger"] = Data.Tab["Base.PickUpTruckLightsRanger"]
Data.Tab["Base.VanAmbulance"] = {}
Data.Tab["Base.VanUtility"] = {}
Data.Tab["Base.Trailer"] = {}
Data.Tab["Base.TrailerCover"] = {}
Data.Tab["Base.TrailerAdvert"] = Data.Tab["Base.TrailerCover"]
Data.Tab["Base.Trailer_Livestock"] = {}
Data.Tab["Base.Trailer_Horsebox"] = Data.Tab["Base.Trailer_Livestock"]

--------------------------------------------------------
------------------- Police vehicles --------------------
--------------------------------------------------------

local activeMods = getActivatedMods()

Data.Tab["Base.PickUpVanLightsPolice"] = {}
Data.Tab["Base.CarLightsPolice"] = {}

Data.Add("Base.StepVan_LouisvilleSWAT", "General", "Base.67commandoPolice", nil, 7, "67commando")
Data.Add("Base.StepVan_LouisvilleSWAT", "General", "Base.85chevyStepVanSWAT", nil, 60, "85chevyStepVan")
Data.Add("Base.StepVan_LouisvilleSWAT", "General", "Base.87fordF700swat", nil, 45, "87fordF700")
Data.Add("Base.StepVan_LouisvilleSWAT", "General", "Base.90fordF350SWAT", nil, 33, "90fordF350")

Data.Add("Base.PickUpTruckLightsAirportSecurity", "General", "Base.85chevyImpalaSedanAirport", 1, 25, "85chevyImpala")
Data.Add("Base.CarLightsKST", "General", "Base.85chevyImpalaSedanKSP", nil, 100, "85chevyImpala")
Data.Add("Base.CarLightsLouisvilleCounty", "General", "Base.85chevyImpalaSedanLCPD", nil, 100, "85chevyImpala")
Data.Add("Base.ModernCarLightsCityLouisvillePD", "General", "Base.85chevyImpalaSedanCLPD", nil, 100, "85chevyImpala")
Data.Add("Base.ModernCarLightsMeadeSheriff", "General", "Base.85chevyImpalaSedanMCS", nil, 100, "85chevyImpala")
Data.Add("Base.CarLightsMuldraughPolice", "General", "Base.85chevyImpalaSedanMPD", nil, 100, "85chevyImpala")
Data.Add("Base.ModernCarLightsWestPoint", "General", "Base.85chevyImpalaSedanWPPD", nil, 100, "85chevyImpala")
Data.Add("Base.CarLightsBulletinSheriff", "General", "Base.85chevyImpalaSedanBCS", nil, 100, "85chevyImpala")

Data.Add("Base.VanSeats_Prison", "General", "Base.87fordB700prison", nil, 50, "87fordB700")

Data.Add("Base.PickUpTruckLightsAirportSecurity", "General", "Base.93chevySuburbanAirportSec", nil, 50, "93chevySuburban")
Data.Add("Base.PickUpVanLightsStatePolice", "General", "Base.93chevySuburbanksp", nil, 100, "93chevySuburban")
Data.Add("Base.PickUpVanLightsLouisvilleCounty", "General", "Base.93chevySuburbanPoliceLCPD", nil, 100, "93chevySuburban")

--------------------------------------------------------
-------------------- Prof vehicles ---------------------
--------------------------------------------------------

Data.Tab["Base.VanMccoy"] = {}
Data.Tab["Base.PickUpTruckMccoy"] = Data.Tab["Base.VanMccoy"]
Data.Tab["Base.PickUpVanMccoy"] = Data.Tab["Base.VanMccoy"]
Data.Tab["Base.VanSpiffo"] = {}
Data.Tab["Base.VanFossoil"] = {}
Data.Tab["Base.PickUpTruckLightsFossoil"] = Data.Tab["Base.VanFossoil"]
Data.Tab["Base.PickUpVanLightsFossoil"] = Data.Tab["Base.VanFossoil"]
Data.Tab["Base.VanSeats_Mural"] = {}
Data.Tab["Base.VanBuilder"] = {}
Data.Tab["Base.VanCarpenter"] = {}
Data.Tab["Base.VanGardener"] = {}
Data.Tab["Base.VanMechanic"] = {}
Data.Tab["Base.VanMetalworker"] = {}
Data.Tab["Base.PickUpTruckLightsAirport"] = {}

Data.Add("Base.VanMechanic", "General", "Base.76chevyC30CCwrecker", 2, 10, "76chevyWrecker_MobileMechanics", 10)
Data.Add("Base.VanMechanic", "Louisville", "Base.76chevyC30CCwrecker", 2, 10,"76chevyWrecker_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "Muldraugh", "Base.76chevyC30CCwrecker", 2, 10, "76chevyWrecker_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "Riverside", "Base.76chevyC30CCwrecker", 2, 10, "76chevyWrecker_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "Rosewood", "Base.76chevyC30CCwrecker", 2, 10, "76chevyWrecker_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "WestPoint", "Base.76chevyC30CCwrecker", 2, 10, "76chevyWrecker_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "MarchRidge", "Base.76chevyC30CCwrecker", 2, 15, "76chevyWrecker_MobileMechanics", 75)
Data.Add("Base.VanMechanic", "LAA", "Base.76chevyC30CCwrecker", 2, 25, "76chevyWrecker_MobileMechanics", 100)
Data.Add("Base.VanMechanic", "General", "Base.76chevyC30CCwrecker", 0, 4, "76chevyWrecker_Als", 10)
Data.Add("Base.VanMechanic", "MarchRidge", "Base.76chevyC30CCwrecker", 0, 4, "76chevyWrecker_Als", 25)
Data.Add("Base.VanMechanic", "General", "Base.76chevyK30CCwrecker", 0, 4, "76chevyWrecker_Als", 10)
Data.Add("Base.VanMechanic", "MarchRidge", "Base.76chevyK30CCwrecker", 0, 4, "76chevyWrecker_Als", 25)
Data.Add("Base.VanMechanic", "General", "Base.76chevyC30CCwrecker", 1, 4, "76chevyWrecker_Brewster", 10)
Data.Add("Base.VanMechanic", "Riverside", "Base.76chevyC30CCwrecker", 1, 6, "76chevyWrecker_Brewster", 75)
Data.Add("Base.VanMechanic", "General", "Base.76chevyC30SCwrecker", 0, 6, "76chevyWrecker_Als", 10)
Data.Add("Base.VanMechanic", "MarchRidge", "Base.76chevyC30SCwrecker", 0, 6, "76chevyWrecker_Als", 25)
Data.Add("Base.VanMechanic", "General", "Base.76chevyK30SCwrecker", 0, 6, "76chevyWrecker_Als", 10)
Data.Add("Base.VanMechanic", "MarchRidge", "Base.76chevyK30SCwrecker", 0, 6, "76chevyWrecker_Als", 25)
Data.Add("Base.VanMechanic", "General", "Base.76chevyC30SCwrecker", 1, 4, "76chevyWrecker_Brewster", 10)
Data.Add("Base.VanMechanic", "Riverside", "Base.76chevyC30SCwrecker", 1, 9, "76chevyWrecker_Brewster", 75)
Data.Add("Base.VanFossoil", "General", "Base.76chevyK20utility", 1, 25, "76chevyUtility")
Data.Add("Base.VanFossoil", "General", "Base.76chevyK30CCutility", 1, 20, "76chevyUtility")
Data.Add("Base.VanMccoy", "General", "Base.76chevyK20utility", 2, 25, "76chevyUtility")
Data.Add("Base.VanMccoy", "General", "Base.76chevyK30CCutility", 2, 20, "76chevyUtility")

Data.Add("Base.VanCarpenter", "Louisville", "Base.85chevyStepVanJorgensen", nil, 100, "85chevyStepVan_Jorgensen", 75)
Data.Add("Base.VanCarpenter", "LAA", "Base.85chevyStepVanJorgensen", nil, 100, "85chevyStepVan_Jorgensen", 75)
Data.Add("Base.VanGardener", "WestPoint", "Base.85chevyStepVanRandys", nil, 100, "85chevyStepVan_Randys", 100)
Data.Add("Base.VanMechanic", "General", "Base.85chevyStepVanLvMotorshop", nil, 100, "85chevyStepVan_LvMotorshop", 10)
Data.Add("Base.VanMechanic", "Louisville", "Base.85chevyStepVanLvMotorshop", nil, 100, "85chevyStepVan_LvMotorshop", 75)
Data.Add("Base.VanMechanic", "General", "Base.85chevyStepVanTheCompleteRepair", nil, 100, "85chevyStepVan_CompleteRepair", 10)
Data.Add("Base.VanMechanic", "Rosewood", "Base.85chevyStepVanTheCompleteRepair", nil, 100, "85chevyStepVan_CompleteRepair", 40)

Data.Add("Base.StepVanAirportCatering", "General", "Base.85chevyStepVanLvAirportCatering", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVanMail", "General", "Base.85chevyStepVanPostal", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Blacksmith", "General", "Base.85chevyStepVanBlacksmith", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Butchers", "General", "Base.85chevyStepVanButchers", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Cereal", "General", "Base.85chevyStepVanSunBallz", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Citr8", "General", "Base.85chevyStepVanCitrusWave", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_CompleteRepairShop", "General", "Base.85chevyStepVanTheCompleteRepair", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Florist", "General", "Base.85chevyStepVanFlorist", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Genuine_Beer", "General", "Base.85chevyStepVanGenuine", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Glass", "General", "Base.85chevyStepVanTimelessGlass", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Heralds", "General", "Base.85chevyStepVanHerald", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_HuangsLaundry", "General", "Base.85chevyStepVanMrHuangsLaundry", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Jorgensen", "General", "Base.85chevyStepVanJorgensen", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_LouisvilleMotorShop", "General", "Base.85chevyStepVanLvMotorshop", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_MarineBites", "General", "Base.85chevyStepVanMarineBites", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Masonry", "General", "Base.85chevyStepVanMasonry", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_MobileLibrary", "General", "Base.85chevyStepVanLibrary", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_MobileLibrary", "Louisville", "Base.85chevyStepVan", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_MobileLibrary", "LAA", "Base.85chevyStepVan", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Plonkies", "General", "Base.85chevyStepVanDelirosPlonkies", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Propane", "General", "Base.85chevyStepVanPropane", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_RandisPlants", "General", "Base.85chevyStepVanRandys", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Scarlet", "General", "Base.85chevyStepVanScarletOak", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_SmartKut", "General", "Base.85chevyStepVanSmartCut", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_SouthEasternHosp", "General", "Base.85chevyStepVanSeHospitality", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_SouthEasternHosp", "LAA", "Base.85chevyStepVanLvAirportCatering", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_SouthEasternPaint", "General", "Base.85chevyStepVanSePaintingServices", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_USL", "General", "Base.85chevyStepVanUsLogistics", nil, 100, "85chevyStepVan")
Data.Add("Base.StepVan_Zippee", "General", "Base.85chevyStepVanZippeeMarket", nil, 100, "85chevyStepVan")

Data.Add("Base.VanSpiffo", "General", "Base.86fordE150slideSpiffo", nil, 75, "86fordE150")
Data.Add("Base.VanMccoy", "General", "Base.86fordE150mccoy", nil, 35, "86fordE150")

Data.Add("Base.VanBuilder", "General", "Base.86fordE150kerrHomes", nil, 100, "86fordE150_kerrHomes", 10)
Data.Add("Base.VanBuilder", "Louisville", "Base.86fordE150kerrHomes", nil, 100, "86fordE150_kerrHomes", 75)
Data.Add("Base.VanBuilder", "General", "Base.86fordE150ccconstruction", nil, 100, "86fordE150_CoastToCoast", 10)
Data.Add("Base.VanBuilder", "Louisville", "Base.86fordE150ccconstruction", nil, 100, "86fordE150_CoastToCoast", 25)
Data.Add("Base.VanBuilder", "MarchRidge", "Base.86fordE150ccconstruction", nil, 100, "86fordE150_CoastToCoast", 25)
Data.Add("Base.VanBuilder", "Muldraugh", "Base.86fordE150ccconstruction", nil, 100, "86fordE150_CoastToCoast", 25)
Data.Add("Base.VanBuilder", "Riverside", "Base.86fordE150ccconstruction", nil, 100, "86fordE150_CoastToCoast", 25)
Data.Add("Base.VanBuilder", "WestPoint", "Base.86fordE150ccconstruction", nil, 100, "86fordE150_CoastToCoast", 25)
Data.Add("Base.VanBuilder", "LAA", "Base.86fordE150ccconstruction", nil, 100, "86fordE150_CoastToCoast", 100)
Data.Add("Base.VanBuilder", "General", "Base.86fordE150beckmansBuilding", nil, 100, "86fordE150_Beckmans", 10)
Data.Add("Base.VanBuilder", "WestPoint", "Base.86fordE150beckmansBuilding", nil, 100, "86fordE150_Beckmans", 40)
Data.Add("Base.VanBuilder", "WestPoint", "Base.86fordE150pennSham", nil, 100, "86fordE150_PennSHam", 35)

Data.Add("Base.VanCarpenter", "Muldraugh", "Base.86fordE150McCoyWoodworking", nil, 100, "86fordE150_McCoyWoodworking", 40)
Data.Add("Base.VanCarpenter", "Muldraugh", "Base.86fordE150michelesWoodshop", nil, 100, "86fordE150_Micheles", 35)
Data.Add("Base.VanCarpenter", "General", "Base.86fordE150rosewoodWorking", nil, 100, "86fordE150_RosewoodWorking", 10)
Data.Add("Base.VanCarpenter", "Rosewood", "Base.86fordE150rosewoodWorking", nil, 100, "86fordE150_RosewoodWorking", 75)
Data.Add("Base.VanCarpenter", "WestPoint", "Base.86fordE150wpCarpentry", nil, 100, "86fordE150_WPCarpentry", 75)

Data.Add("Base.VanGardener", "General", "Base.86fordE150lvLandscaping", nil, 100, "86fordE150_LvLandscaping", 10)
Data.Add("Base.VanGardener", "Louisville", "Base.86fordE150lvLandscaping", nil, 100, "86fordE150_LvLandscaping", 100)
Data.Add("Base.VanGardener", "General", "Base.86fordE150treyBaines", nil, 100, "86fordE150_TreyBaines", 10)
Data.Add("Base.VanGardener", "MarchRidge", "Base.86fordE150lvLandscaping", nil, 100, "86fordE150_TreyBaines", 100)
Data.Add("Base.VanGardener", "Riverside", "Base.86fordE150theGardenGods", nil, 100, "86fordE150_GardenGods", 50)

Data.Add("Base.VanMechanic", "General", "Base.86fordE150mobileMechanics", nil, 100, "86fordE150_MobileMechanics", 10)
Data.Add("Base.VanMechanic", "Louisville", "Base.86fordE150mobileMechanics", nil, 100, "86fordE150_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "Muldraugh", "Base.86fordE150mobileMechanics", nil, 100, "86fordE150_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "Riverside", "Base.86fordE150mobileMechanics", nil, 100, "86fordE150_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "Rosewood", "Base.86fordE150mobileMechanics", nil, 100, "86fordE150_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "WestPoint", "Base.86fordE150mobileMechanics", nil, 100, "86fordE150_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "MarchRidge", "Base.86fordE150mobileMechanics", nil, 100, "86fordE150_MobileMechanics", 75)
Data.Add("Base.VanMechanic", "LAA", "Base.86fordE150mobileMechanics", nil, 100, "86fordE150_MobileMechanics", 100)
Data.Add("Base.VanMechanic", "Muldraugh", "Base.86fordE150korshunovs", nil, 100, "86fordE150_Korshunovs", 75)
Data.Add("Base.VanMechanic", "General", "Base.86fordE150brewster", nil, 100, "86fordE150_Brewster", 10)
Data.Add("Base.VanMechanic", "Riverside", "Base.86fordE150brewster", nil, 100, "86fordE150_Brewster", 75)
Data.Add("Base.VanMechanic", "General", "Base.86fordE150plattAutoRepair", nil, 100, "86fordE150_PlattAutoRepair", 10)
Data.Add("Base.VanMechanic", "Rosewood", "Base.86fordE150plattAutoRepair", nil, 100, "86fordE150_PlattAutoRepair", 35)
Data.Add("Base.VanMechanic", "General", "Base.86fordE150mooresMechanics", nil, 100, "86fordE150_MooresMechanics", 10)
Data.Add("Base.VanMechanic", "WestPoint", "Base.86fordE150mooresMechanics", nil, 100, "86fordE150_MooresMechanics", 75)

Data.Add("Base.VanMetalworker", "Louisville", "Base.86fordE150metalheads", nil, 100, "86fordE150_Metalheads", 75)

Data.Add("Base.VanMetalworker", "General", "Base.86fordE150meltingPointMetal", nil, 100, "86fordE150_MeltingPointMetal", 10)
Data.Add("Base.VanMetalworker", "Louisville", "Base.86fordE150meltingPointMetal", nil, 100, "86fordE150_MeltingPointMetal", 25)
Data.Add("Base.VanMetalworker", "MarchRidge", "Base.86fordE150meltingPointMetal", nil, 100, "86fordE150_MeltingPointMetal", 25)
Data.Add("Base.VanMetalworker", "Muldraugh", "Base.86fordE150meltingPointMetal", nil, 100, "86fordE150_MeltingPointMetal", 25)
Data.Add("Base.VanMetalworker", "Riverside", "Base.86fordE150meltingPointMetal", nil, 100, "86fordE150_MeltingPointMetal", 25)
Data.Add("Base.VanMetalworker", "Rosewood", "Base.86fordE150meltingPointMetal", nil, 100, "86fordE150_MeltingPointMetal", 25)
Data.Add("Base.VanMetalworker", "LAA", "Base.86fordE150meltingPointMetal", nil, 100, "86fordE150_MeltingPointMetal", 100)
Data.Add("Base.VanMetalworker", "General", "Base.86fordE150jones", nil, 100, "86fordE150_Jones", 10)
Data.Add("Base.VanMetalworker", "MarchRidge", "Base.86fordE150jones", nil, 100, "86fordE150_Jones", 35)
Data.Add("Base.VanMetalworker", "General", "Base.86fordE150riversideFab", nil, 100, "86fordE150_RiversideFab", 10)
Data.Add("Base.VanMetalworker", "Riverside", "Base.86fordE150riversideFab", nil, 100, "86fordE150_RiversideFab", 75)
Data.Add("Base.VanMetalworker", "General", "Base.86fordE150schwab", nil, 100, "86fordE150_Schwab", 10)
Data.Add("Base.VanMetalworker", "Rosewood", "Base.86fordE150schwab", nil, 100, "86fordE150_Schwab", 75)

Data.Add("Base.VanSeats_Mural", "General", "Base.86fordE150creatureCruiser", nil, 10, "86fordE150")
Data.Add("Base.VanSeats_Mural", "MarchRidge", "Base.86fordE150creatureCruiser", nil, 100, "86fordE150")
Data.Add("Base.VanSeats_Mural", "General", "Base.86fordE150theLadyDelighter", nil, 10, "86fordE150")
Data.Add("Base.VanSeats_Mural", "Muldraugh", "Base.86fordE150theLadyDelighter", nil, 100, "86fordE150")
Data.Add("Base.VanSeats_Mural", "General", "Base.86fordE150quantumVessel", nil, 10, "86fordE150")
Data.Add("Base.VanSeats_Mural", "Riverside", "Base.86fordE150quantumVessel", nil, 100, "86fordE150")
Data.Add("Base.VanSeats_Mural", "General", "Base.86fordE150mesmerWagon", nil, 10, "86fordE150")
Data.Add("Base.VanSeats_Mural", "Rosewood", "Base.86fordE150mesmerWagon", nil, 100, "86fordE150")
Data.Add("Base.VanSeats_Mural", "General", "Base.86fordE150valkyriesSpear", nil, 10, "86fordE150")
Data.Add("Base.VanSeats_Mural", "WestPoint", "Base.86fordE150valkyriesSpear", nil, 100, "86fordE150")

Data.Add("Base.VanFossoil", "General", "Base.86fordE150fossoil", nil, 15, "86fordE150")

Data.Add("Base.VanKerrHomes", "General", "Base.86fordE150kerrHomes", nil, 100, "86fordE150")
Data.Add("Base.VanCoastToCoast", "General", "Base.86fordE150ccconstruction", nil, 100, "86fordE150")
Data.Add("Base.VanBeckmans", "General", "Base.86fordE150beckmansBuilding", nil, 100, "86fordE150")
Data.Add("Base.VanPennSHam", "General", "Base.86fordE150pennSham", nil, 100, "86fordE150")
Data.Add("Base.VanJohnMcCoy", "General", "Base.86fordE150McCoyWoodworking", nil, 100, "86fordE150")
Data.Add("Base.VanMicheles", "General", "Base.86fordE150michelesWoodshop", nil, 100, "86fordE150")
Data.Add("Base.VanRosewoodworking", "General", "Base.86fordE150rosewoodWorking", nil, 100, "86fordE150")
Data.Add("Base.VanWPCarpentry", "General", "Base.86fordE150wpCarpentry", nil, 100, "86fordE150")
Data.Add("Base.VanLouisvilleLandscaping", "General", "Base.86fordE150lvLandscaping", nil, 100, "86fordE150")
Data.Add("Base.VanTreyBaines", "General", "Base.86fordE150treyBaines", nil, 100, "86fordE150")
Data.Add("Base.VanGardenGods", "General", "Base.86fordE150theGardenGods", nil, 100, "86fordE150")
Data.Add("Base.VanMobileMechanics", "General", "Base.86fordE150mobileMechanics", nil, 100, "86fordE150")
Data.Add("Base.VanKorshunovs", "General", "Base.86fordE150korshunovs", nil, 100, "86fordE150")
Data.Add("Base.VanBrewsterHarbin", "General", "Base.86fordE150brewster", nil, 100, "86fordE150")
Data.Add("Base.VanPlattAuto", "General", "Base.86fordE150plattAutoRepair", nil, 100, "86fordE150")
Data.Add("Base.VanMooreMechanics", "General", "Base.86fordE150mooresMechanics", nil, 100, "86fordE150")
Data.Add("Base.VanMetalheads", "General", "Base.86fordE150metalheads", nil, 100, "86fordE150")
Data.Add("Base.VanMeltingPointMetal", "General", "Base.86fordE150meltingPointMetal", nil, 100, "86fordE150")
Data.Add("Base.VanMeltingPointMetal", "LAA", "Base.86fordE150meltingPointMetal", nil, 100, "86fordE150")
Data.Add("Base.VanJonesFabrication", "General", "Base.86fordE150jones", nil, 100, "86fordE150")
Data.Add("Base.VanRiversideFabrication", "General", "Base.86fordE150riversideFab", nil, 100, "86fordE150")
Data.Add("Base.VanSchwabSheetMetal", "General", "Base.86fordE150schwab", nil, 100, "86fordE150")
Data.Add("Base.VanSeats_Creature", "General", "Base.86fordE150creatureCruiser", nil, 100, "86fordE150")
Data.Add("Base.VanSeats_LadyDelighter", "General", "Base.86fordE150theLadyDelighter", nil, 100, "86fordE150")
Data.Add("Base.VanSeats_Space", "General", "Base.86fordE150quantumVessel", nil, 100, "86fordE150")
Data.Add("Base.VanSeats_Trippy", "General", "Base.86fordE150mesmerWagon", nil, 100, "86fordE150")
Data.Add("Base.VanSeats_Valkyrie", "General", "Base.86fordE150valkyriesSpear", nil, 100, "86fordE150")
Data.Add("Base.VanSeatsAirportShuttle", "General", "Base.86fordE150LVairportShuttle", nil, 100, "86fordE150")
Data.Add("Base.VanMail", "General", "Base.86fordE150postal", nil, 100, "86fordE150")
Data.Add("Base.VanRadio", "General", "Base.86fordE150LBMWradio", nil, 100, "86fordE150")
Data.Add("Base.Van_MassGenFac", "General", "Base.86fordE150massGenfac", nil, 100, "86fordE150")
Data.Add("Base.Van_Transit", "General", "Base.86fordE150kyTransit", nil, 100, "86fordE150")
Data.Add("Base.Van_LectroMax", "General", "Base.86fordE150lectromax", nil, 100, "86fordE150")
Data.Add("Base.Van_KnoxDisti", "General", "Base.86fordE150knoxDistilery", nil, 100, "86fordE150")
Data.Add("Base.VanDeerValley", "General", "Base.86fordE150deerValley", nil, 100, "86fordE150")
Data.Add("Base.VanKnobCreekGas", "General", "Base.86fordE150knobCreek", nil, 100, "86fordE150")
Data.Add("Base.VanKnoxCom", "General", "Base.86fordE150knoxTelecom", nil, 100, "86fordE150")
Data.Add("Base.VanOldMill", "General", "Base.86fordE150oldMillWaterCompany", nil, 100, "86fordE150")
Data.Add("Base.Van_Locksmith", "General", "Base.86fordE150locksmith", nil, 100, "86fordE150")
Data.Add("Base.VanPluggedInElectrics", "General", "Base.86fordE150pluggedInElectrics", nil, 100, "86fordE150")
Data.Add("Base.Van_VoltMojo", "General", "Base.86fordE150voltMojo", nil, 100, "86fordE150")
Data.Add("Base.VanGreenes", "General", "Base.86fordE150greenes", nil, 100, "86fordE150")
Data.Add("Base.VanOvoFarm", "General", "Base.86fordE150oVoFarms", nil, 100, "86fordE150")
Data.Add("Base.VanUncloggers", "General", "Base.86fordE150uncloggers", nil, 100, "86fordE150")
Data.Add("Base.Van_Blacksmith", "General", "Base.86fordE150blacksmith", nil, 100, "86fordE150")
Data.Add("Base.Van_BugWipers", "General", "Base.86fordE150bugWipers", nil, 100, "86fordE150")
Data.Add("Base.Van_CraftSupplies", "General", "Base.86fordE150brushAndClay", nil, 100, "86fordE150")
Data.Add("Base.Van_Glass", "General", "Base.86fordE150zenith", nil, 100, "86fordE150")
Data.Add("Base.Van_Leather", "General", "Base.86fordE150leatherwork", nil, 100, "86fordE150")
Data.Add("Base.Van_Masonry", "General", "Base.86fordE150stoneworksMasonry", nil, 100, "86fordE150")
Data.Add("Base.Van_Charlemange_Beer", "General", "Base.86fordE150tasteTheBrew", nil, 100, "86fordE150")
Data.Add("Base.Van_HeritageTailors", "General", "Base.86fordE150heritageTailors", nil, 100, "86fordE150")
Data.Add("Base.Van_Perfick_Potato", "General", "Base.86fordE150perfick", nil, 100, "86fordE150")

Data.Add("Base.VanSpiffo", "General", "Base.87fordF700box", 3, 25, "87fordB700")

Data.Add("Base.VanFossoil", "General", "Base.93chevySilveradoSClongFossoil", nil, 40, "93chevySilverado")
Data.Add("Base.VanMccoy", "General", "Base.93chevySilveradoXClongMcCoy", nil, 40, "93chevySilverado")

Data.Add("Base.VanBuilder", "WestPoint", "Base.93chevySilveradoPennSham", nil, 45, "93chevySilverado_PennSHam", 35)

Data.Add("Base.VanCarpenter", "Muldraugh", "Base.93chevySilveradoMcCoyWoodworking", nil, 45, "93chevySilverado_McCoyWoodworking", 40)
Data.Add("Base.VanCarpenter", "WestPoint", "Base.93chevySilveradoWpCarpentry", nil, 45, "93chevySilverado_WpCarpentry", 75)

Data.Add("Base.VanGardener", "General", "Base.93chevySilveradoK3500lvLandscaping", nil, 45, "93chevySilverado_LvLandscaping", 10)
Data.Add("Base.VanGardener", "Louisville", "Base.93chevySilveradoK3500lvLandscaping", nil, 45, "93chevySilverado_LvLandscaping", 100)

Data.Add("Base.VanMechanic", "General", "Base.93chevySilveradoK3500mechanic", 0, 5, "93chevySilverado_Brewster", 10)
Data.Add("Base.VanMechanic", "Riverside", "Base.93chevySilveradoK3500mechanic", 0, 7, "93chevySilverado_Brewster", 75)
Data.Add("Base.VanMechanic", "General", "Base.93chevySilveradoK3500mechanic", 1, 5, "93chevySilverado_MobileMechanics", 10)
Data.Add("Base.VanMechanic", "Louisville", "Base.93chevySilveradoK3500mechanic", 1, 5, "93chevySilverado_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "Muldraugh", "Base.93chevySilveradoK3500mechanic", 1, 5, "93chevySilverado_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "Riverside", "Base.93chevySilveradoK3500mechanic", 1, 5, "93chevySilverado_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "Rosewood", "Base.93chevySilveradoK3500mechanic", 1, 5, "93chevySilverado_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "WestPoint", "Base.93chevySilveradoK3500mechanic", 1, 5, "93chevySilverado_MobileMechanics", 25)
Data.Add("Base.VanMechanic", "MarchRidge", "Base.93chevySilveradoK3500mechanic", 1, 5, "93chevySilverado_MobileMechanics", 75)
Data.Add("Base.VanMechanic", "LAA", "Base.93chevySilveradoK3500mechanic", 1, 10, "93chevySilverado_MobileMechanics", 100)
Data.Add("Base.VanMechanic", "General", "Base.93chevySilveradoK3500mechanic", 2, 5, "93chevySilverado_MooresMechanics", 10)
Data.Add("Base.VanMechanic", "WestPoint", "Base.93chevySilveradoK3500mechanic", 2, 7, "93chevySilverado_MooresMechanics", 75)

Data.Add("Base.Base.VanMetalworker", "General", "Base.93chevySilveradoRiversideFab", nil, 35, "93chevySilverado", 10)
Data.Add("Base.Base.VanMetalworker", "Riverside", "Base.93chevySilveradoRiversideFab", nil, 35, "93chevySilverado", 75)

Data.Add("Base.PickUpTruckLightsAirport", "General", "Base.85chevyImpalaSedanAirport", 0, 20, "85chevyImpala")
Data.Add("Base.PickUpTruckLightsAirport", "General", "Base.93chevySilveradoAirport", 0, 80, "93chevySilverado")

Data.Tab["Base.PickUpVanBuilder"] = Data.Tab["Base.VanBuilder"]
Data.Tab["Base.PickUpVanLightsCarpenter"] = Data.Tab["Base.VanCarpenter"]
Data.Tab["Base.PickUpVanMetalworker"] = Data.Tab["Base.VanMetalworker"]
Data.Tab["Base.StepVan_Mechanic"] = Data.Tab["Base.VanMechanic"]

--------------------------------------------------------
--------------- Temporary remplacements ----------------
--------------------------------------------------------

Data.Tab["Base.VanRadio_3N"] = Data.Tab["Base.VanRadio"]

Data.Tab["Base.PickUpTruckJPLandscaping"] = Data.Tab["Base.VanLouisvilleLandscaping"]
Data.Tab["Base.PickUpVanBrickingIt"] = Data.Tab["Base.VanCoastToCoast"]
Data.Tab["Base.PickUpVanCallowayLandscaping"] = Data.Tab["Base.VanLouisvilleLandscaping"]
Data.Tab["Base.PickUpVanHeltonMetalWorking"] = Data.Tab["Base.VanMeltingPointMetal"]
Data.Tab["Base.PickUpVanKimbleKonstruction"] = Data.Tab["Base.VanCoastToCoast"]
Data.Tab["Base.PickUpVanLightsKentuckyLumber"] = Data.Tab["Base.VanRosewoodworking"]
Data.Tab["Base.PickUpVanMarchRidgeConstruction"] = Data.Tab["Base.VanCoastToCoast"]
Data.Tab["Base.PickUpVanWeldingbyCamille"] = Data.Tab["Base.VanMeltingPointMetal"]
Data.Tab["Base.PickUpVanYingsWood"] = Data.Tab["Base.VanRosewoodworking"]

--------------------------------------------------------
---------------- Fill tables if empty ------------------
--------------------------------------------------------

local replaceTabs = {
	["Base.CarLightsKST"] = "Base.CarLightsPolice",
	["Base.CarLightsLouisvilleCounty"] = "Base.CarLightsPolice",
	["Base.ModernCarLightsCityLouisvillePD"] = "Base.CarLightsPolice",
	["Base.ModernCarLightsMeadeSheriff"] = "Base.CarLightsPolice",
	["Base.CarLightsMuldraughPolice"] = "Base.CarLightsPolice",
	["Base.ModernCarLightsWestPoint"] = "Base.CarLightsPolice",
	["Base.CarLightsBulletinSheriff"] = "Base.CarLightsPolice",
	["Base.StepVan_LouisvilleSWAT"] = "Base.PickUpVanLightsPolice",
	["Base.VanSeats_Prison"] = "Base.PickUpVanLightsPolice",
	["Base.PickUpVanLightsStatePolice"] = "Base.PickUpVanLightsPolice",
	["Base.PickUpVanLightsLouisvilleCounty"] = "Base.PickUpVanLightsPolice",
	["Base.PickUpTruckLightsAirportSecurity"] = "Base.PickUpVanLightsPolice",
	["Base.StepVanAirportCatering"] = "Base.Van",
	["Base.StepVanMail"] = "Base.Van",
	["Base.StepVan_Blacksmith"] = "Base.Van",
	["Base.StepVan_Butchers"] = "Base.Van",
	["Base.StepVan_Cereal"] = "Base.Van",
	["Base.StepVan_Citr8"] = "Base.Van",
	["Base.StepVan_CompleteRepairShop"] = "Base.Van",
	["Base.StepVan_Florist"] = "Base.Van",
	["Base.StepVan_Genuine_Beer"] = "Base.Van",
	["Base.StepVan_Glass"] = "Base.Van",
	["Base.StepVan_Heralds"] = "Base.Van",
	["Base.StepVan_HuangsLaundry"] = "Base.Van",
	["Base.StepVan_Jorgensen"] = "Base.Van",
	["Base.StepVan_LouisvilleMotorShop"] = "Base.Van",
	["Base.StepVan_MarineBites"] = "Base.Van",
	["Base.StepVan_Masonry"] = "Base.Van",
	["Base.StepVan_Mechanic"] = "Base.Van",
	["Base.StepVan_MobileLibrary"] = "Base.Van",
	["Base.StepVan_Plonkies"] = "Base.Van",
	["Base.StepVan_Propane"] = "Base.Van",
	["Base.StepVan_RandisPlants"] = "Base.Van",
	["Base.StepVan_Scarlet"] = "Base.Van",
	["Base.StepVan_SmartKut"] = "Base.Van",
	["Base.StepVan_SouthEasternHosp"] = "Base.Van",
	["Base.StepVan_SouthEasternPaint"] = "Base.Van",
	["Base.StepVan_USL"] = "Base.Van",
	["Base.StepVan_Zippee"] = "Base.Van",
	["Base.VanBuilder"] = "Base.Van",
	["Base.VanCarpenter"] = "Base.Van",
	["Base.VanGardener"] = "Base.Van",
	["Base.VanMechanic"] = "Base.Van",
	["Base.VanMetalworker"] = "Base.Van",
	["Base.VanSeats_Mural"] = "Base.Van",
	["Base.VanKerrHomes"] = "Base.Van",
	["Base.VanCoastToCoast"] = "Base.Van",
	["Base.VanBeckmans"] = "Base.Van",
	["Base.VanPennSHam"] = "Base.Van",
	["Base.VanJohnMcCoy"] = "Base.Van",
	["Base.VanMicheles"] = "Base.Van",
	["Base.VanRosewoodworking"] = "Base.Van",
	["Base.VanWPCarpentry"] = "Base.Van",
	["Base.VanLouisvilleLandscaping"] = "Base.Van",
	["Base.VanTreyBaines"] = "Base.Van",
	["Base.VanGardenGods"] = "Base.Van",
	["Base.VanMobileMechanics"] = "Base.Van",
	["Base.VanKorshunovs"] = "Base.Van",
	["Base.VanBrewsterHarbin"] = "Base.Van",
	["Base.VanPlattAuto"] = "Base.Van",
	["Base.VanMooreMechanics"] = "Base.Van",
	["Base.VanMetalheads"] = "Base.Van",
	["Base.VanMeltingPointMetal"] = "Base.Van",
	["Base.VanRiversideFabrication"] = "Base.Van",
	["Base.VanSchwabSheetMetal"] = "Base.Van",
	["Base.VanSeats_Creature"] = "Base.Van",
	["Base.VanSeats_LadyDelighter"] = "Base.Van",
	["Base.VanSeats_Space"] = "Base.Van",
	["Base.VanSeats_Trippy"] = "Base.Van",
	["Base.VanSeats_Valkyrie"] = "Base.Van",
	["Base.VanSeatsAirportShuttle"] = "Base.Van",
	["Base.VanMail"] = "Base.Van",
	["Base.VanRadio"] = "Base.Van",
	["Base.Van_MassGenFac"] = "Base.Van",
	["Base.Van_Transit"] = "Base.Van",
	["Base.Van_LectroMax"] = "Base.Van",
	["Base.Van_KnoxDisti"] = "Base.Van",
	["Base.VanDeerValley"] = "Base.Van",
	["Base.VanKnobCreekGas"] = "Base.Van",
	["Base.VanKnoxCom"] = "Base.Van",
	["Base.VanOldMill"] = "Base.Van",
	["Base.Van_Locksmith"] = "Base.Van",
	["Base.VanPluggedInElectrics"] = "Base.Van",
	["Base.Van_VoltMojo"] = "Base.Van",
	["Base.VanGreenes"] = "Base.Van",
	["Base.VanOvoFarm"] = "Base.Van",
	["Base.VanUncloggers"] = "Base.Van",
	["Base.Van_Blacksmith"] = "Base.Van",
	["Base.Van_BugWipers"] = "Base.Van",
	["Base.Van_CraftSupplies"] = "Base.Van",
	["Base.Van_Glass"] = "Base.Van",
	["Base.Van_Leather"] = "Base.Van",
	["Base.Van_Masonry"] = "Base.Van",
	["Base.Van_Charlemange_Beer"] = "Base.Van",
	["Base.Van_HeritageTailors"] = "Base.Van",
	["Base.Van_Perfick_Potato"] = "Base.Van",
	["Base.VanSpiffo"] = "Base.Van",
	["Base.VanFossoil"] = "Base.Van",
	["Base.VanMccoy"] = "Base.Van",
	["Base.PickUpTruckLightsAirport"] = "Base.PickUpTruck",
}

for tab1, tab2 in pairs(replaceTabs) do
	Data.Tab[tab1] = replaceTableIfEmpty(Data.Tab[tab1], Data.Tab[tab2])
end

--------------------------------------------------------
------------------ Optional vehicles -------------------
--------------------------------------------------------

local activeMods = getActivatedMods()

Data.Add("Base.PickUpTruck", "General", "Base.49powerWagon", nil, 5, "49powerWagon")

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.49powerWagonPD", nil, 1, "49powerWagon_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.49powerWagonPD", nil, 1, "49powerWagon_police", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.49powerWagonPD", nil, 1, "49powerWagon_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.49powerWagonPD", nil, 2, "49powerWagon_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.49powerWagonPD", nil, 3, "49powerWagon_police", 15)

Data.Add("Base.CarStationWagon", "General", "Base.59meteor", nil, 5, "59meteor")
Data.Add("Base.VanAmbulance", "General", "Base.59ambulance", nil, 3, "59meteor")

Data.Add("Base.CarNormal", "General", "Base.63beetle", nil, 3, "63beetle")
Data.Add("Base.CarLuxury", "General", "Base.63beetleHP", nil, 2, "63beetle")
Data.Add("Base.OffRoad", "General", "Base.63beetleBuggy", nil, 4, "63beetle")

Data.Add("Base.VanSeats", "General", "Base.63Type2Van", nil, 10, "63Type2Van")

Data.Add("Base.SportsCar", "General", "Base.65banshee400", nil, 1, "65banshee")
Data.Add("Base.SportsCar", "General", "Base.65bansheeSprint", nil, 1, "65banshee")
Data.Add("Base.SportsCar", "General", "Base.65bansheeXP", nil, 1, "65banshee")

Data.Add("Base.CarLuxury", "General", "Base.66pontiacGTO", nil, 3, "66pontiacLeMans")
Data.Add("Base.CarLuxury", "General", "Base.66pontiacGTOconv", nil, 2, "66pontiacLeMans")
Data.Add("Base.CarLuxury", "General", "Base.66pontiacLeMans", nil, 3, "66pontiacLeMans")
Data.Add("Base.CarLuxury", "General", "Base.66pontiacLeMansConv", nil, 2, "66pontiacLeMans")

Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.67commandoPolice", nil, 20, "67commando_swat", 2)
Data.Add("Base.PickUpTruckLightsRanger", "General", "Base.67commando", 3, 7, "67commando")

Data.Add("Base.SportsCar", "General", "Base.67gt500", nil, 4, "67gt500")
Data.Add("Base.SportsCar", "General", "Base.67gt500e", nil, 3, "67gt500")

Data.Add("Base.CarLuxury", "General", "Base.68firebird350", nil, 6, "68firebird")
Data.Add("Base.CarLuxury", "General", "Base.68firebird400", nil, 4, "68firebird")
Data.Add("Base.SportsCar", "General", "Base.68firebirdRamAir", nil, 4, "68firebird")
Data.Add("Base.SportsCar", "General", "Base.68firebirdRamAirCustom", nil, 3, "68firebird")
Data.Add("Base.RaceCar12", "General", "Base.68firebirdRamAirCustom", nil, 3, "68firebird")

Data.Add("Base.SportsCar", "General", "Base.69camaroRS", nil, 4, "69camaro")
Data.Add("Base.SportsCar", "General", "Base.69camaroSS", nil, 4, "69camaro")

Data.Add("Base.CarLuxury", "General", "Base.69chargerRT", nil, 4, "69charger")
Data.Add("Base.CarLuxury", "General", "Base.69charger500", nil, 4, "69charger")
Data.Add("Base.OffRoad", "General", "Base.69chargerDemon", nil, 3, "69charger")
Data.Add("Base.SportsCar", "General", "Base.69chargerDaytona", nil, 8, "69charger")
Data.Add("Base.RaceCar12", "General", "Base.69chargerDaytona", nil, 10, "69charger")

Data.Add("Base.SportsCar", "General", "Base.69fordMustangBoss302", nil, 4, "69fordMustang")
Data.Add("Base.SportsCar", "General", "Base.69fordMustangBoss429", nil, 4, "69fordMustang")
Data.Add("Base.SportsCar", "General", "Base.69fordMustangMach1", nil, 4, "69fordMustang")

Data.Add("Base.CarNormal", "General", "Base.69mini", nil, 3, "69mini")

if activeMods:contains("69mini_ItalianJob") then
	Data.Add("Base.CarNormal", "General", "Base.69miniIJ", nil, 1, "69miniIJ")
end

if activeMods:contains("69mini_PitbullSpecial") then
	Data.Add("Base.SportsCar", "General", "Base.69miniPS", nil, 2, "69mini")
	Data.Add("Base.CarNormal", "General", "Base.69miniPS", nil, 1, "69mini")
end

Data.Add("Base.CarLuxury", "General", "Base.70chevelleSedan", nil, 12, "70chevelle")
Data.Add("Base.CarLuxury", "General", "Base.70chevelleCoupe", nil, 7, "70chevelle")
Data.Add("Base.SportsCar", "General", "Base.70chevelleCoupeSS", nil, 4, "70chevelle")
Data.Add("Base.SportsCar", "General", "Base.70chevelleCoupeSSL6", nil, 4, "70chevelle")
Data.Add("Base.CarStationWagon", "General", "Base.70chevelleWagon", nil, 10, "70chevelle")
Data.Add("Base.CarStationWagon", "General", "Base.70chevelleWagonSS", nil, 3, "70chevelle")
Data.Add("Base.PickUpTruck", "General", "Base.70elCamino", nil, 9, "70elCamino")
Data.Add("Base.PickUpTruck", "General", "Base.70elCaminoSS", nil, 3, "70elCamino")

Data.Add("Base.CarLuxury", "General", "Base.70dodgeBG", nil, 2, "70dodge")
Data.Add("Base.CarLuxury", "General", "Base.70dodgeOP", nil, 2, "70dodge")
Data.Add("Base.CarLuxury", "General", "Base.70dodgeRT", nil, 2, "70dodge")
Data.Add("Base.CarLuxury", "General", "Base.70dodgeTA", nil, 2, "70dodge")

Data.Add("Base.CarLightsPolice", "General", "Base.70dodgePD", nil, 7, "70dodge_police", 20)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.70dodgePD", nil, 5, "70dodge_police", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.70dodgePD", nil, 5, "70dodge_police", 20)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.70dodgePD", nil, 4, "70dodge_police", 20)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.70dodgePD", nil, 2, "70dodge_police", 15)

Data.Add("Base.CarNormal", "General", "Base.70fordEscortSedan", nil, 18, "70fordEscort")
Data.Add("Base.CarNormal", "General", "Base.70fordEscortCoupe", nil, 10, "70fordEscort")
Data.Add("Base.CarStationWagon", "General", "Base.70fordEscortWagon", nil, 20, "70fordEscort")
Data.Add("Base.SportsCar", "General", "Base.70fordEscortRS", nil, 10, "70fordEscort")
Data.Add("Base.RaceCar12", "General", "Base.70fordEscortRS", 4, 10, "70fordEscort")

Data.Add("Base.CarLuxury", "General", "Base.70barracuda", nil, 3, "70barracuda")
Data.Add("Base.CarLuxury", "General", "Base.70barracudaAAR", nil, 3, "70barracuda")
Data.Add("Base.CarLuxury", "General", "Base.70cuda", nil, 3, "70barracuda")

Data.Add("Base.CarLuxury", "General", "Base.70roadRunner", nil, 12, "70roadRunner")

Data.Add("Base.CarLuxury", "General", "Base.73fordFalconXBGT", nil, 3, "73fordFalcon")
Data.Add("Base.CarLuxury", "General", "Base.73fordFalconXBGTlhd", nil, 6, "73fordFalcon")

Data.Add("Base.SportsCar", "General", "Base.73nissanGTR", nil, 3, "73nissanGTR")
Data.Add("Base.SportsCar", "General", "Base.73nissanGTRlhd", nil, 6, "73nissanGTR")

Data.Add("Base.CarLuxury", "General", "Base.75grandPrixHurst", nil, 3, "75grandPrix")
Data.Add("Base.CarLuxury", "General", "Base.75grandPrixLJ", nil, 3, "75grandPrix")
Data.Add("Base.CarLuxury", "General", "Base.75grandPrixSJ", nil, 3, "75grandPrix")

Data.Add("Base.PickUpTruckLightsFire", "General", "Base.76chevyK10fd", nil, 13, "76chevy")
Data.Add("Base.PickUpTruckLightsFire", "General", "Base.76chevyK20fd", nil, 17, "76chevy")
Data.Add("Base.PickUpTruckLightsFire", "General", "Base.76chevyK30CCfd", nil, 20, "76chevy")

Data.Add("Base.PickUpTruck", "General", "Base.76chevyK10", nil, 7, "76chevy")
Data.Add("Base.PickUpTruck", "General", "Base.76chevyK20", nil, 8, "76chevy")
Data.Add("Base.PickUpTruck", "General", "Base.76chevyK20BigRed", nil, 1, "76chevy")
Data.Add("Base.PickUpTruck", "General", "Base.76chevyK30CC", nil, 6, "76chevy")
Data.Add("Base.PickUpTruck", "General", "Base.76chevyK30SCdually", nil, 2, "76chevy")
Data.Add("Base.PickUpTruck", "General", "Base.76chevyK30CCduallyS", nil, 1, "76chevy")
Data.Add("Base.PickUpTruck", "General", "Base.76chevyK30CCdually", nil, 2, "76chevy")
Data.Add("Base.OffRoad", "General", "Base.76chevyK30CCduallyS", nil, 8, "76chevy")
Data.Add("Base.SUV", "General", "Base.76chevySuburban", nil, 14, "76chevy")
Data.Add("Base.SUV", "General", "Base.76chevySuburban2", nil, 14, "76chevy")

Data.Add("Base.VanUtility", "General", "Base.76chevyC30SCwrecker", { 2, 3, 4, 5, 6 }, 3, "76chevyWrecker")
Data.Add("Base.VanUtility", "General", "Base.76chevyC30CCwrecker", { 3, 4, 5, 6, 7 }, 2, "76chevyWrecker")
Data.Add("Base.VanUtility", "General", "Base.76chevyK30SCwrecker", { 1, 2, 3, 4, 5 }, 3, "76chevyWrecker")
Data.Add("Base.VanUtility", "General", "Base.76chevyK30CCwrecker", { 1, 2, 3, 4, 5 }, 2, "76chevyWrecker")
Data.Add("Base.VanUtility", "General", "Base.76chevyK20utility", { 0, 3, 4 }, 15, "76chevyUtility")
Data.Add("Base.VanUtility", "General", "Base.76chevyK30CCutility", { 0, 3, 4 }, 10, "76chevyUtility")

Data.Add("Base.CarLuxury", "General", "Base.76chryslerNewYorker", nil, 8, "76chryslerNewYorker")
Data.Add("Base.CarLuxury", "General", "Base.76chryslerNewYorkerTPB", nil, 2, "76chryslerNewYorker")

Data.Add("Base.CarLuxury", "General", "Base.77firebird", nil, 10, "77firebird")
Data.Add("Base.SportsCar", "General", "Base.77firebirdES", nil, 3, "77firebird")
Data.Add("Base.SportsCar", "General", "Base.77firebirdFR", nil, 3, "77firebird")
Data.Add("Base.SportsCar", "General", "Base.77firebirdTA", nil, 3, "77firebird")
Data.Add("Base.RaceCar12", "General", "Base.77firebirdTA", { 1, 2, 3, 4, 5, 6, 7, 8 }, 3, "77firebird")

if activeMods:contains("78amgeneralM50A3") then
	Data.Add("Base.PickUpTruckLightsFire", "General", "Base.78amgeneralM50A3", 7, 30, "78amgeneralMXX")
end

if activeMods:contains("78amgeneralM62") then
	Data.Add("Base.PickUpTruckLightsFire", "General", "Base.78amgeneralM62", 7, 10, "78amgeneralMXX")
end

Data.Add("Base.SportsCar", "General", "Base.78lamboCountachLP400", nil, 8, "78lamboCountach")
Data.Add("Base.SportsCar", "General", "Base.78lamboCountachLP400S", nil, 5, "78lamboCountach")
Data.Add("Base.SportsCar", "General", "Base.78lamboCountachLP400Scb", nil, 2, "78lamboCountach")

Data.Add("Base.SportsCar", "General", "Base.79camaro", nil, 6, "79camaro")
Data.Add("Base.SportsCar", "General", "Base.79camaroRS", nil, 6, "79camaro")
Data.Add("Base.SportsCar", "General", "Base.79camaroZ28", nil, 4, "79camaro")
Data.Add("Base.SportsCar", "General", "Base.79camaroGhost", nil, 2, "79camaro")
Data.Add("Base.RaceCar12", "General", "Base.79camaroGhost", nil, 7, "79camaro")

Data.Add("Base.SportsCar", "General", "Base.81deloreanDMC12", nil, 10, "81delorean")

Data.Add("Base.PickUpTruck", "General", "Base.82jeepJ10", nil, 20, "82jeepJ10")
Data.Add("Base.PickUpTruckLightsRanger", "General", "Base.82jeepJ10ranger", nil, 30, "82jeepJ10")

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.82jeepJ10pd", nil, 10, "82jeepJ10_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.82jeepJ10pd", nil, 8, "82jeepJ10_police", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.82jeepJ10pd", nil, 10, "82jeepJ10_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.82jeepJ10pd", nil, 10, "82jeepJ10_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.82jeepJ10pd", nil, 7, "82jeepJ10_police", 15)

Data.Add("Base.CarLuxury", "General", "Base.82firebird", nil, 8, "82firebird")
Data.Add("Base.SportsCar", "General", "Base.82firebirdTA", nil, 4, "82firebird")
Data.Add("Base.SportsCar", "General", "Base.82firebirdSE", nil, 4, "82firebird")
Data.Add("Base.RaceCar12", "General", "Base.82firebirdTA", 8, 7, "82firebird")

Data.Add("Base.SportsCar", "General", "Base.82firebirdKITT", nil, 1, "82firebird")
Data.Add("Base.SportsCar", "General", "Base.82firebirdKARR", nil, 1, "82firebird")

Data.Add("Base.SportsCar", "General", "Base.82porsche911rwb", nil, 9, "82porsche911")
Data.Add("Base.SportsCar", "General", "Base.82porsche911turbo", nil, 9, "82porsche911")
Data.Add("Base.SportsCar", "General", "Base.82porsche911sc", nil, 9, "82porsche911")
Data.Add("Base.SportsCar", "General", "Base.82porsche911targa", nil, 8, "82porsche911")
Data.Add("Base.RaceCar12", "General", "Base.82porsche911rwb", 1, 10, "82porsche911")
Data.Add("Base.RaceCar12", "General", "Base.82porsche911turbo", { 12, 13, 14 }, 15, "82porsche911")

Data.Add("Base.CarLuxury", "General", "Base.84buickElectraSedan", nil, 14, "84buickElectra")
Data.Add("Base.CarLuxury", "General", "Base.84buickElectraCoupe", nil, 9, "84buickElectra")

Data.Add("Base.CarLuxury", "General", "Base.84cadillacDeVilleSedan", nil, 14, "84cadillacDeVille")
Data.Add("Base.CarLuxury", "General", "Base.84cadillacDeVilleCoupe", nil, 9, "84cadillacDeVille")

Data.Add("Base.SportsCar", "General", "Base.84corvetteC4", nil, 17, "84corvetteC4")
Data.Add("Base.SportsCar", "General", "Base.93corvetteC4", nil, 17, "93corvetteC4")
Data.Add("Base.ModernCar", "General", "Base.93corvetteC4", nil, 22, "93corvetteC4")

Data.Add("Base.SUV", "General", "Base.84jeepXJ2", nil, 10, "84jeepXJ")
Data.Add("Base.SUV", "General", "Base.84jeepXJ4", nil, 15, "84jeepXJ")
Data.Add("Base.OffRoad", "General", "Base.84jeepXJ2", nil, 13, "84jeepXJ")
Data.Add("Base.OffRoad", "General", "Base.84jeepXJ4", nil, 12, "84jeepXJ")
Data.Add("Base.PickUpTruckLightsRanger", "General", "Base.84jeepXJranger", nil, 45, "84jeepXJ")

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.84jeepXJpd", { 0, 1 }, 35, "84jeepXJ_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.84jeepXJpd", { 0, 1 }, 20, "84jeepXJ_police", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.84jeepXJpd", { 0, 1 }, 35, "84jeepXJ_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.84jeepXJpd", { 0, 1 }, 35, "84jeepXJ_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.84jeepXJpd", { 0, 1 }, 23, "84jeepXJ_police", 15)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.84jeepXJpd", { 2, 3 }, 45, "84jeepXJ_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.84jeepXJpd", { 2, 3 }, 23, "84jeepXJ_sheriff", 15)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.84jeepXJpd", { 2, 3 }, 13, "84jeepXJ_sheriff", 7)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.84jeepXJpd", { 2, 3 }, 20, "84jeepXJ_sheriff", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.84jeepXJpd", { 2, 3 }, 45, "84jeepXJ_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.84jeepXJpd", { 2, 3 }, 15, "84jeepXJ_sheriff", 8)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.84jeepXJksp", { 0 }, 50, "84jeepXJ_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.84jeepXJksp", { 0 }, 33, "84jeepXJ_ksp", 25)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.84jeepXJksp", { 0 }, 30, "84jeepXJ_ksp", 21)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.84jeepXJksp", { 0 }, 40, "84jeepXJ_ksp", 30)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.84jeepXJksp", { 0 }, 35, "84jeepXJ_ksp", 28)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.84jeepXJksp", { 0 }, 30, "84jeepXJ_ksp", 23)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.84jeepXJksp", { 0 }, 60, "84jeepXJ_ksp", 50)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.84jeepXJksp", { 0 }, 50, "84jeepXJ_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.84jeepXJksp", { 0 }, 30, "84jeepXJ_ksp", 20)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.84jeepXJksp", { 0 }, 30, "84jeepXJ_ksp", 22)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.84jeepXJksp", { 1 }, 10, "84jeepXJ_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.84jeepXJksp", { 1 }, 6, "84jeepXJ_ksp", 25)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.84jeepXJksp", { 1 }, 6, "84jeepXJ_ksp", 21)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.84jeepXJksp", { 1 }, 8, "84jeepXJ_ksp", 30)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.84jeepXJksp", { 1 }, 8, "84jeepXJ_ksp", 28)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.84jeepXJksp", { 1 }, 6, "84jeepXJ_ksp", 23)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.84jeepXJksp", { 1 }, 12, "84jeepXJ_ksp", 50)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.84jeepXJksp", { 1 }, 10, "84jeepXJ_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.84jeepXJksp", { 1 }, 6, "84jeepXJ_ksp", 20)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.84jeepXJksp", { 1 }, 6, "84jeepXJ_ksp", 22)

Data.Add("Base.OffRoad", "General", "Base.84mercLWB2", nil, 13, "84merc")
Data.Add("Base.OffRoad", "General", "Base.84mercLWB4", nil, 12, "84merc")
Data.Add("Base.OffRoad", "General", "Base.84mercSWB", nil, 20, "84merc")

Data.Add("Base.CarLuxury", "General", "Base.84oldsmobile98Sedan", nil, 14, "84oldsmobile98")
Data.Add("Base.CarLuxury", "General", "Base.84oldsmobile98Coupe", nil, 9, "84oldsmobile98")

Data.Add("Base.CarNormal", "General", "Base.85buickLeSabreSedan", nil, 22, "85buickLeSabre")
Data.Add("Base.CarNormal", "General", "Base.85buickLeSabreCoupe", nil, 13, "85buickLeSabre")
Data.Add("Base.CarStationWagon", "General", "Base.85buickLeSabreWagon", nil, 15, "85buickLeSabre")
Data.Add("Base.CarStationWagon", "General", "Base.85buickLeSabreWagon2", nil, 15, "85buickLeSabre")

Data.Add("Base.CarNormal", "General", "Base.85chevyCapriceSedan", nil, 22, "85chevyCaprice")
Data.Add("Base.CarNormal", "General", "Base.85chevyCapriceCoupe", nil, 13, "85chevyCaprice")
Data.Add("Base.CarStationWagon", "General", "Base.85chevyCapriceWagon", nil, 15, "85chevyCaprice")
Data.Add("Base.CarStationWagon", "General", "Base.85chevyCapriceWagon2", nil, 15, "85chevyCaprice")
Data.Add("Base.CarTaxi", "General", "Base.85chevyImpalaSedanTaxi", nil, 40, "85chevyImpala")
Data.Add("Base.CarLightsRanger", "General", "Base.85chevyImpalaSedanRanger", nil, 50, "85chevyImpala")
Data.Add("Base.PickUpTruckLightsFire", "General", "Base.85chevyImpalaSedanFD", nil, 8, "85chevyImpala")

Data.Add("Base.CarLightsPolice", "Louisville", "Base.85chevyImpalaSedanCLPD", nil, 75, "85chevyImpala_CLPD", 49)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.85chevyImpalaSedanLCPD", nil, 75, "85chevyImpala_LCPD", 19)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.85chevyImpalaSedanLCPD", nil, 75, "85chevyImpala_LCPD", 60)
Data.Add("Base.CarLightsPolice", "LAA", "Base.85chevyImpalaSedanAirport", 1, 75, "85chevyImpala_airportSecurity", 28)
Data.Add("Base.CarLightsPolice", "LAA", "Base.85chevyImpalaSedanLCPD", nil, 75, "85chevyImpala_LCPD", 42)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.85chevyImpalaSedanMCS", nil, 75, "85chevyImpala_MCS", 20)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.85chevyImpalaSedanMPD", nil, 75, "85chevyImpala_MPD", 49)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.85chevyImpalaSedanWPPD", nil, 75, "85chevyImpala_WPPD", 65)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.85chevyImpalaSedanMCS", nil, 75, "85chevyImpala_MCS", 50)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.85chevyImpalaSedanPrison", nil, 75, "85chevyImpala_prison", 10)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.85chevyImpalaSedanMCS", nil, 75, "85chevyImpala_MCS", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.85chevyImpalaSedanBCS", nil, 75, "85chevyImpala_BCS", 65)
Data.Add("Base.CarLightsPolice", "General", "Base.85chevyImpalaSedanMCS", nil, 75, "85chevyImpala_MCS", 10)

Data.Add("Base.CarLightsPolice", "General", "Base.85chevyImpalaSedanPD", nil, 50, "85chevyImpala_police", 20)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.85chevyImpalaSedanPD", nil, 35, "85chevyImpala_police", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.85chevyImpalaSedanPD", nil, 40, "85chevyImpala_police", 20)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.85chevyImpalaSedanPD", nil, 40, "85chevyImpala_police", 20)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.85chevyImpalaSedanPD", nil, 30, "85chevyImpala_police", 15)

Data.Add("Base.CarLightsPolice", "General", "Base.85chevyImpalaSedanKSP", nil, 50, "85chevyImpala_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.85chevyImpalaSedanKSP", nil, 33, "85chevyImpala_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.85chevyImpalaSedanKSP", nil, 30, "85chevyImpala_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.85chevyImpalaSedanKSP", nil, 40, "85chevyImpala_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.85chevyImpalaSedanKSP", nil, 35, "85chevyImpala_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.85chevyImpalaSedanKSP", nil, 30, "85chevyImpala_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.85chevyImpalaSedanKSP", nil, 60, "85chevyImpala_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.85chevyImpalaSedanKSP", nil, 50, "85chevyImpala_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.85chevyImpalaSedanKSP", nil, 30, "85chevyImpala_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.85chevyImpalaSedanKSP", nil, 30, "85chevyImpala_ksp", 22)

Data.Add("Base.CarLightsPolice", "Louisville", "Base.85chevyImpalaSedanPDu", nil, 25, "85chevyImpala_undercover", 2)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.85chevyImpalaSedanPDu", nil, 25, "85chevyImpala_undercover", 1)

Data.Add("Base.Van", "General", "Base.85chevyStepVan", nil, 40, "85chevyStepVan")
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.85chevyStepVanSWAT", nil, 2, "85chevyStepVan_swat")

Data.Add("Base.CarNormal", "General", "Base.85oldsmobileDelta88Sedan", nil, 22, "85oldsmobileDelta88")
Data.Add("Base.CarNormal", "General", "Base.85oldsmobileDelta88Coupe", nil, 13, "85oldsmobileDelta88")
Data.Add("Base.CarStationWagon", "General", "Base.85oldsmobileDelta88Wagon", nil, 15, "85oldsmobileDelta88")
Data.Add("Base.CarStationWagon", "General", "Base.85oldsmobileDelta88Wagon2", nil, 15, "85oldsmobileDelta88")

Data.Add("Base.CarNormal", "General", "Base.85pontiacParisienneSedan", nil, 35, "85pontiacParisienne")
Data.Add("Base.CarStationWagon", "General", "Base.85pontiacParisienneWagon", nil, 15, "85pontiacParisienne")
Data.Add("Base.CarStationWagon", "General", "Base.85pontiacParisienneWagon2", nil, 15, "85pontiacParisienne")

Data.Add("Base.SUV", "General", "Base.86chevyK5blazer", nil, 20, "86chevyK5")
Data.Add("Base.PickUpVan", "General", "Base.86chevyK5blazer", nil, 30, "86chevyK5")
Data.Add("Base.OffRoad", "General", "Base.86chevyK5blazer", nil, 15, "86chevyK5")
Data.Add("Base.VanAmbulance", "General", "Base.86chevyM1010", 4, 25, "86chevyCUCV")

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.86chevyK5pd", { 0, 1 }, 35, "86chevyK5_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.86chevyK5pd", { 0, 1 }, 20, "86chevyK5_police", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.86chevyK5pd", { 0, 1 }, 35, "86chevyK5_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.86chevyK5pd", { 0, 1 }, 35, "86chevyK5_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.86chevyK5pd", { 0, 1 }, 23, "86chevyK5_police", 15)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.86chevyK5pd", 2, 40, "86chevyK5_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.86chevyK5pd", 2, 22, "86chevyK5_sheriff", 15)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.86chevyK5pd", 2, 13, "86chevyK5_sheriff", 7)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.86chevyK5pd", 2, 20, "86chevyK5_sheriff", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.86chevyK5pd", 2, 40, "86chevyK5_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.86chevyK5pd", 2, 15, "86chevyK5_sheriff", 8)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.86chevyK5ksp", { 0 }, 50, "86chevyK5_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.86chevyK5ksp", { 0 }, 33, "86chevyK5_ksp", 25)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.86chevyK5ksp", { 0 }, 30, "86chevyK5_ksp", 21)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.86chevyK5ksp", { 0 }, 40, "86chevyK5_ksp", 30)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.86chevyK5ksp", { 0 }, 35, "86chevyK5_ksp", 28)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.86chevyK5ksp", { 0 }, 30, "86chevyK5_ksp", 23)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.86chevyK5ksp", { 0 }, 60, "86chevyK5_ksp", 50)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.86chevyK5ksp", { 0 }, 50, "86chevyK5_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.86chevyK5ksp", { 0 }, 30, "86chevyK5_ksp", 20)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.86chevyK5ksp", { 0 }, 30, "86chevyK5_ksp", 22)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.86chevyK5ksp", { 1 }, 10, "86chevyK5_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.86chevyK5ksp", { 1 }, 6, "86chevyK5_ksp", 25)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.86chevyK5ksp", { 1 }, 6, "86chevyK5_ksp", 21)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.86chevyK5ksp", { 1 }, 8, "86chevyK5_ksp", 30)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.86chevyK5ksp", { 1 }, 8, "86chevyK5_ksp", 28)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.86chevyK5ksp", { 1 }, 6, "86chevyK5_ksp", 23)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.86chevyK5ksp", { 1 }, 12, "86chevyK5_ksp", 50)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.86chevyK5ksp", { 1 }, 10, "86chevyK5_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.86chevyK5ksp", { 1 }, 6, "86chevyK5_ksp", 20)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.86chevyK5ksp", { 1 }, 6, "86chevyK5_ksp", 22)

Data.Add("Base.Van", "General", "Base.86fordE150", nil, 35, "86fordE150")
Data.Add("Base.Van", "General", "Base.86fordE150long", nil, 12, "86fordE150")
Data.Add("Base.Van", "General", "Base.86fordE150slide", nil, 13, "86fordE150")
Data.Add("Base.VanSeats", "General", "Base.86fordE150longW", nil, 35, "86fordE150")
Data.Add("Base.VanAmbulance", "General", "Base.86fordE150med", nil, 7, "86fordE150")

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.86fordE150so", nil, 30, "86fordE150_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.86fordE150so", nil, 15, "86fordE150_sheriff", 15)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.86fordE150so", nil, 7, "86fordE150_sheriff", 7)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.86fordE150so", nil, 12, "86fordE150_sheriff", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.86fordE150so", nil, 30, "86fordE150_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.86fordE150so", nil, 8, "86fordE150_sheriff", 8)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.86fordE150ksp", nil, 40, "86fordE150_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.86fordE150ksp", nil, 25, "86fordE150_ksp", 25)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.86fordE150ksp", nil, 21, "86fordE150_ksp", 21)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.86fordE150ksp", nil, 30, "86fordE150_ksp", 30)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.86fordE150ksp", nil, 28, "86fordE150_ksp", 28)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.86fordE150ksp", nil, 23, "86fordE150_ksp", 23)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.86fordE150ksp", nil, 50, "86fordE150_ksp", 50)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.86fordE150ksp", nil, 40, "86fordE150_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.86fordE150ksp", nil, 20, "86fordE150_ksp", 20)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.86fordE150ksp", nil, 22, "86fordE150_ksp", 22)

Data.Add("Base.PickUpTruckLightsFire", "General", "Base.86oshkoshKYFD", nil, 25, "86oshkosh")

Data.Add("Base.CarLuxury", "General", "Base.87buickRegalGNX", nil, 25, "87buickRegal")
Data.Add("Base.SportsCar", "General", "Base.87buickRegalTurboT", nil, 15, "87buickRegal")

Data.Add("Base.CarLightsPolice", "Louisville", "Base.87buickRegalTurboTfbi", nil, 2, "87buickRegal_undercover")
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.87buickRegalTurboTfbi", nil, 1, "87buickRegal_undercover")

Data.Add("Base.SUV", "General", "Base.87chevySuburban", nil, 30, "87chevySuburban")
Data.Add("Base.SUV", "General", "Base.87chevySuburbanOP", nil, 5, "87chevySuburban")
Data.Add("Base.OffRoad", "General", "Base.87chevySuburbanOP", nil, 10, "87chevySuburban")

Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.87fordF700swat", nil, 2, "87fordF700_swat")

Data.Add("Base.SportsCar", "General", "Base.87toyotaMR2", nil, 16, "87toyotaMR2")
Data.Add("Base.SportsCar", "General", "Base.87toyotaMR2c", nil, 14, "87toyotaMR2")

Data.Add("Base.PickUpTruck", "General", "Base.88chevyS10", nil, 25, "88chevyS10")

Data.Add("Base.PickUpTruck", "General", "Base.88toyotaHiluxSC", nil, 15, "88toyotaHilux")
Data.Add("Base.PickUpTruck", "General", "Base.88toyotaHiluxXC", nil, 10, "88toyotaHilux")
Data.Add("Base.PickUpVan", "General", "Base.88toyotaHiluxSC", nil, 9, "88toyotaHilux")
Data.Add("Base.PickUpVan", "General", "Base.88toyotaHiluxXC", nil, 5, "88toyotaHilux")
Data.Add("Base.PickUpVan", "General", "Base.88toyotaHiluxXCS", nil, 1, "88toyotaHilux")
Data.Add("Base.OffRoad", "General", "Base.88toyotaHiluxXCS", nil, 7, "88toyotaHilux")

Data.Add("Base.PickUpVan", "General", "Base.89fordBronco", nil, 45, "89fordBronco")
Data.Add("Base.PickUpTruckLightsRanger", "General", "Base.89fordBroncoRanger", nil, 35, "89fordBronco")

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.89fordBroncoPD", 0, 35, "89fordBronco_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.89fordBroncoPD", 0, 20, "89fordBronco_police", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.89fordBroncoPD", 0, 35, "89fordBronco_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.89fordBroncoPD", 0, 35, "89fordBronco_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.89fordBroncoPD", 0, 23, "89fordBronco_police", 15)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.89fordBroncoPD", 1, 40, "89fordBronco_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.89fordBroncoPD", 1, 22, "89fordBronco_sheriff", 15)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.89fordBroncoPD", 1, 13, "89fordBronco_sheriff", 7)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.89fordBroncoPD", 1, 20, "89fordBronco_sheriff", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.89fordBroncoPD", 1, 40, "89fordBronco_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.89fordBroncoPD", 1, 15, "89fordBronco_sheriff", 8)

Data.Add("Base.VanSeats", "General", "Base.89dodgeCaravan", nil, 25, "89dodgeCaravan")
Data.Add("Base.VanSeats", "General", "Base.89dodgeCaravanLE", nil, 20, "89dodgeCaravan")
Data.Add("Base.VanSeats", "General", "Base.89dodgeCaravanNomad", nil, 5, "89dodgeCaravan")
Data.Add("Base.OffRoad", "General", "Base.89dodgeCaravanNomad", nil, 4, "89dodgeCaravan")

Data.Add("Base.OffRoad", "General", "Base.89trooper", nil, 12, "89trooper")
Data.Add("Base.OffRoad", "General", "Base.89trooperOP", nil, 20, "89trooper")
Data.Add("Base.OffRoad", "General", "Base.89trooperRS", nil, 13, "89trooper")

Data.Add("Base.SUV", "General", "Base.89defer110", nil, 21, "89defer")
Data.Add("Base.SUV", "General", "Base.89defer110utility", nil, 4, "89defer")
Data.Add("Base.OffRoad", "General", "Base.89defer90", nil, 24, "89defer")
Data.Add("Base.OffRoad", "General", "Base.89defer90utility", nil, 6, "89defer")
Data.Add("Base.PickUpVan", "General", "Base.89defer130", nil, 7, "89defer")
Data.Add("Base.PickUpTruck", "General", "Base.89defer130", nil, 10, "89defer")

Data.Add("Base.CarNormal", "General", "Base.89volvo244sedan", nil, 30, "89volvo200")
Data.Add("Base.CarNormal", "General", "Base.89volvo242turbo", nil, 5, "89volvo200")
Data.Add("Base.CarStationWagon", "General", "Base.89volvo245wagon", nil, 25, "89volvo200")
Data.Add("Base.CarLuxury", "General", "Base.89volvo242turbo", nil, 5, "89volvo200")

Data.Add("Base.CarNormal", "General", "Base.90bmwE30sedan2", nil, 8, "90bmwE30")
Data.Add("Base.CarNormal", "General", "Base.90bmwE30sedan4", nil, 12, "90bmwE30")
Data.Add("Base.ModernCar", "General", "Base.90bmwE30sedan2", nil, 15, "90bmwE30")
Data.Add("Base.ModernCar", "General", "Base.90bmwE30sedan4", nil, 15, "90bmwE30")
Data.Add("Base.CarStationWagon", "General", "Base.90bmwE30touring", nil, 13, "90bmwE30")
Data.Add("Base.CarLuxury", "General", "Base.90bmwE30cabrio", nil, 27, "90bmwE30")
Data.Add("Base.SportsCar", "General", "Base.90bmwE30m3", nil, 31, "90bmwE30")
Data.Add("Base.RaceCar12", "General", "Base.90bmwE30m3", { 5, 6 }, 25, "90bmwE30")

Data.Add("Base.VanAmbulance", "General", "Base.90fordF350ambulance", nil, 75, "90fordF350")
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.90fordF350SWAT", nil, 30, "90fordF350_swat")

Data.Add("Base.PickUpTruckLightsFire", "General", "Base.90pierceArrow", nil, 50, "90pierceArrow")

Data.Add("Base.CarNormal", "General", "Base.91fordLTD", nil, 30, "91fordLTD")
Data.Add("Base.ModernCar", "General", "Base.91fordLTD", nil, 25, "91fordLTD")
Data.Add("Base.CarStationWagon", "General", "Base.91fordLTDwagon", nil, 25, "91fordLTD")
Data.Add("Base.CarTaxi", "General", "Base.91fordLTDtaxi", nil, 30, "91fordLTD")
Data.Add("Base.CarLightsRanger", "General", "Base.91fordLTDranger", nil, 50, "91fordLTD")

Data.Add("Base.CarLightsPolice", "General", "Base.91fordLTDpd", { 0, 1 }, 35, "91fordLTD_police", 20)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.91fordLTDpd", { 0, 1 }, 20, "91fordLTD_police", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.91fordLTDpd", { 0, 1 }, 35, "91fordLTD_police", 20)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.91fordLTDpd", { 0, 1 }, 35, "91fordLTD_police", 20)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.91fordLTDpd", { 0, 1 }, 23, "91fordLTD_police", 15)

Data.Add("Base.CarLightsPolice", "General", "Base.91fordLTDpd", { 2, 3, 4 }, 40, "91fordLTD_sheriff", 30)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.91fordLTDpd", { 2, 3, 4 }, 22, "91fordLTD_sheriff", 15)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.91fordLTDpd", { 2, 3, 4 }, 13, "91fordLTD_sheriff", 7)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.91fordLTDpd", { 2, 3, 4 }, 20, "91fordLTD_sheriff", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.91fordLTDpd", { 2, 3, 4 }, 40, "91fordLTD_sheriff", 30)
Data.Add("Base.CarLightsPolice", "LAA", "Base.91fordLTDpd", { 2, 3, 4 }, 15, "91fordLTD_sheriff", 8)

Data.Add("Base.CarLightsPolice", "General", "Base.91fordLTDksp", { 2, 3, 4 }, 30, "91fordLTD_sheriff", 30)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.91fordLTDksp", { 2, 3, 4 }, 15, "91fordLTD_sheriff", 15)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.91fordLTDksp", { 2, 3, 4 }, 7, "91fordLTD_sheriff", 7)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.91fordLTDksp", { 2, 3, 4 }, 12, "91fordLTD_sheriff", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.91fordLTDksp", { 2, 3, 4 }, 30, "91fordLTD_sheriff", 30)
Data.Add("Base.CarLightsPolice", "LAA", "Base.91fordLTDksp", { 2, 3, 4 }, 8, "91fordLTD_sheriff", 8)

Data.Add("Base.CarLightsPolice", "General", "Base.91fordLTDksp", 0, 50, "91fordLTD_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.91fordLTDksp", 0, 33, "91fordLTD_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.91fordLTDksp", 0, 30, "91fordLTD_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.91fordLTDksp", 0, 40, "91fordLTD_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.91fordLTDksp", 0, 35, "91fordLTD_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.91fordLTDksp", 0, 30, "91fordLTD_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.91fordLTDksp", 0, 60, "91fordLTD_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.91fordLTDksp", 0, 50, "91fordLTD_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.91fordLTDksp", 0, 30, "91fordLTD_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.91fordLTDksp", 0, 30, "91fordLTD_ksp", 22)

Data.Add("Base.CarLightsPolice", "General", "Base.91fordLTDksp2", nil, 40, "91fordLTD_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.91fordLTDksp2", nil, 25, "91fordLTD_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.91fordLTDksp2", nil, 21, "91fordLTD_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.91fordLTDksp2", nil, 30, "91fordLTD_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.91fordLTDksp2", nil, 28, "91fordLTD_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.91fordLTDksp2", nil, 23, "91fordLTD_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.91fordLTDksp2", nil, 50, "91fordLTD_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.91fordLTDksp2", nil, 40, "91fordLTD_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.91fordLTDksp2", nil, 20, "91fordLTD_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.91fordLTDksp2", nil, 22, "91fordLTD_ksp", 22)

Data.Add("Base.CarLightsPolice", "Louisville", "Base.91fordLTDunmarked", nil, 33, "91fordLTD_undercover", 2)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.91fordLTDunmarked", nil, 33, "91fordLTD_undercover", 1)

Data.Add("Base.CarNormal", "General", "Base.91geoMetro", nil, 45, "91geoMetro")

Data.Add("Base.CarLuxury", "General", "Base.91lexusLS400", nil, 25, "91lexusLS400")
Data.Add("Base.ModernCar", "General", "Base.91lexusLS400", nil, 30, "91lexusLS400")

Data.Add("Base.PickUpTruck", "General", "Base.91fordRangerSC", nil, 10, "91fordRanger")
Data.Add("Base.PickUpTruck", "General", "Base.91fordRangerSClong", nil, 7, "91fordRanger")
Data.Add("Base.PickUpTruck", "General", "Base.91fordRangerXC", nil, 8, "91fordRanger")
Data.Add("Base.PickUpTruck", "General", "Base.91fordRangerXClong", nil, 5, "91fordRanger")
Data.Add("Base.PickUpVan", "General", "Base.91fordRangerSC", nil, 7, "91fordRanger")
Data.Add("Base.PickUpVan", "General", "Base.91fordRangerSClong", nil, 5, "91fordRanger")
Data.Add("Base.PickUpVan", "General", "Base.91fordRangerXC", nil, 5, "91fordRanger")
Data.Add("Base.PickUpVan", "General", "Base.91fordRangerXClong", nil, 3, "91fordRanger")
Data.Add("Base.PickUpTruckLightsRanger", "General", "Base.91fordRangerRanger", nil, 35, "91fordRanger")

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.91fordRangerPD", { 0, 1 }, 30, "91fordRanger_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.91fordRangerPD", { 0, 1 }, 20, "91fordRanger_police", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.91fordRangerPD", { 0, 1 }, 30, "91fordRanger_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.91fordRangerPD", { 0, 1 }, 30, "91fordRanger_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.91fordRangerPD", { 0, 1 }, 25, "91fordRanger_police", 15)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.91fordRangerPD", 2, 35, "91fordRanger_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.91fordRangerPD", 2, 20, "91fordRanger_sheriff", 15)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.91fordRangerPD", 2, 12, "91fordRanger_sheriff", 7)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.91fordRangerPD", 2, 15, "91fordRanger_sheriff", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.91fordRangerPD", 2, 35, "91fordRanger_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.91fordRangerPD", 2, 15, "91fordRanger_sheriff", 8)

Data.Add("Base.SportsCar", "General", "Base.91nissan240sx", nil, 18, "91nissan240sx")
Data.Add("Base.SportsCar", "General", "Base.91nissan240sx2", nil, 17, "91nissan240sx")

Data.Add("Base.SUV", "General", "Base.91range", nil, 16, "91range")
Data.Add("Base.SUV", "General", "Base.91range2", nil, 11, "91range")
Data.Add("Base.OffRoad", "General", "Base.91range", nil, 13, "91range")
Data.Add("Base.OffRoad", "General", "Base.91range2", nil, 12, "91range")

Data.Add("Base.CarNormal", "General", "Base.92fordCV", nil, 30, "92fordCV")
Data.Add("Base.ModernCar", "General", "Base.92fordCV", nil, 25, "92fordCV")
Data.Add("Base.CarTaxi", "General", "Base.92fordCVPItaxi", nil, 25, "92fordCV")
Data.Add("Base.PickUpTruckLightsFire", "General", "Base.92fordCVPIfd", nil, 8, "92fordCV")

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI", { 1, 2 }, 35, "92fordCVPI_police", 20)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.92fordCVPI", { 1, 2 }, 20, "92fordCVPI_police", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI", { 1, 2 }, 35, "92fordCVPI_police", 20)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.92fordCVPI", { 1, 2 }, 35, "92fordCVPI_police", 20)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.92fordCVPI", { 1, 2 }, 22, "92fordCVPI_police", 15)

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI", { 3, 4 }, 40, "92fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.92fordCVPI", { 3, 4 }, 22, "92fordCVPI_sheriff", 15)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPI", { 3, 4 }, 12, "92fordCVPI_sheriff", 7)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.92fordCVPI", { 3, 4 }, 20, "92fordCVPI_sheriff", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI", { 3, 4 }, 40, "92fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "LAA", "Base.92fordCVPI", { 3, 4, }, 15, "92fordCVPI_sheriff", 8)

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI", 0, 50, "92fordCVPI_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.92fordCVPI", 0, 33, "92fordCVPI_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPI", 0, 30, "92fordCVPI_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.92fordCVPI", 0, 40, "92fordCVPI_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.92fordCVPI", 0, 35, "92fordCVPI_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.92fordCVPI", 0, 30, "92fordCVPI_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI", 0, 60, "92fordCVPI_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.92fordCVPI", 0, 50, "92fordCVPI_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.92fordCVPI", 0, 30, "92fordCVPI_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.92fordCVPI", 0, 30, "92fordCVPI_ksp", 22)

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI2", { 1, 2 }, 20, "92fordCVPI_police", 20)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.92fordCVPI2", { 1, 2 }, 12, "92fordCVPI_police", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI2", { 1, 2 }, 20, "92fordCVPI_police", 20)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.92fordCVPI2", { 1, 2 }, 20, "92fordCVPI_police", 20)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.92fordCVPI2", { 1, 2 }, 15, "92fordCVPI_police", 15)

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI2", { 3, 4 }, 30, "92fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.92fordCVPI2", { 3, 4 }, 15, "92fordCVPI_sheriff", 15)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPI2", { 3, 4 }, 7, "92fordCVPI_sheriff", 7)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.92fordCVPI2", { 3, 4 }, 12, "92fordCVPI_sheriff", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI2", { 3, 4 }, 30, "92fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "LAA", "Base.92fordCVPI2", { 3, 4 }, 8, "92fordCVPI_sheriff", 8)

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI2", 0, 40, "92fordCVPI_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.92fordCVPI2", 0, 25, "92fordCVPI_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPI2", 0, 21, "92fordCVPI_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.92fordCVPI2", 0, 30, "92fordCVPI_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.92fordCVPI2", 0, 28, "92fordCVPI_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.92fordCVPI2", 0, 23, "92fordCVPI_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI2", 0, 50, "92fordCVPI_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.92fordCVPI2", 0, 40, "92fordCVPI_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.92fordCVPI2", 0, 20, "92fordCVPI_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.92fordCVPI2", 0, 22, "92fordCVPI_ksp", 22)

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI2ksp", nil, 40, "92fordCVPI_ksp")
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.92fordCVPI2ksp", nil, 25, "92fordCVPI_ksp")
Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPI2ksp", nil, 21, "92fordCVPI_ksp")
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.92fordCVPI2ksp", nil, 30, "92fordCVPI_ksp")
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.92fordCVPI2ksp", nil, 28, "92fordCVPI_ksp")
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.92fordCVPI2ksp", nil, 23, "92fordCVPI_ksp")
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI2ksp", nil, 50, "92fordCVPI_ksp")
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.92fordCVPI2ksp", nil, 40, "92fordCVPI_ksp")
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.92fordCVPI2ksp", nil, 20, "92fordCVPI_ksp")
Data.Add("Base.CarLightsPolice", "LAA", "Base.92fordCVPI2ksp", nil, 22, "92fordCVPI_ksp")

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI2kspst", nil, 40, "92fordCVPI_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.92fordCVPI2kspst", nil, 25, "92fordCVPI_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPI2kspst", nil, 21, "92fordCVPI_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.92fordCVPI2kspst", nil, 30, "92fordCVPI_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.92fordCVPI2kspst", nil, 28, "92fordCVPI_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.92fordCVPI2kspst", nil, 23, "92fordCVPI_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI2kspst", nil, 50, "92fordCVPI_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.92fordCVPI2kspst", nil, 40, "92fordCVPI_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.92fordCVPI2kspst", nil, 20, "92fordCVPI_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.92fordCVPI2kspst", nil, 22, "92fordCVPI_ksp", 22)

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI2so", nil, 30, "92fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.92fordCVPI2so", nil, 15, "92fordCVPI_sheriff", 15)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPI2so", nil, 7, "92fordCVPI_sheriff", 7)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.92fordCVPI2so", nil, 12, "92fordCVPI_sheriff", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI2so", nil, 30, "92fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "LAA", "Base.92fordCVPI2so", nil, 8, "92fordCVPI_sheriff", 8)

Data.Add("Base.CarLightsPolice", "General", "Base.92fordCVPI2sup", nil, 30, "92fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.92fordCVPI2sup", nil, 15, "92fordCVPI_sheriff", 15)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPI2sup", nil, 7, "92fordCVPI_sheriff", 7)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.92fordCVPI2sup", nil, 12, "92fordCVPI_sheriff", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.92fordCVPI2sup", nil, 30, "92fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "LAA", "Base.92fordCVPI2sup", nil, 8, "92fordCVPI_sheriff", 8)

Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPIunmarked", nil, 25, "92fordCVPI_undercover", 2)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.92fordCVPIunmarked", nil, 25, "92fordCVPI_undercover", 1)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.92fordCVPIpdu", nil, 30, "92fordCVPI_undercover", 2)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.92fordCVPIpdu", nil, 30, "92fordCVPI_undercover", 1)

Data.Add("Base.OffRoad", "General", "Base.92jeepYJs", nil, 20, "92jeepYJ")
Data.Add("Base.OffRoad", "General", "Base.92jeepYJse", nil, 17, "92jeepYJ")
Data.Add("Base.PickUpTruckLightsRanger", "General", "Base.92jeepYJranger", nil, 20, "92jeepYJ")

if activeMods:contains("92jeepYJJP18") then
	Data.Add("Base.OffRoad", "General", "Base.92jeepYJjp", nil, 3, "92jeepYJ")
end

Data.Add("Base.SportsCar", "General", "Base.92nissanGTR", nil, 12, "92nissanGTR")
Data.Add("Base.SportsCar", "General", "Base.92nissanGTRlhd", nil, 23, "92nissanGTR")

Data.Add("Base.SUV", "General", "Base.93chevySuburban", nil, 26, "93chevySuburban")
Data.Add("Base.SUV", "General", "Base.93chevySuburbanDually", nil, 9, "93chevySuburban")

Data.Add("Base.PickUpTruckLightsFire", "General", "Base.93chevySuburbanfd", nil, 20, "93chevySuburban")
Data.Add("Base.PickUpTruckLightsFire", "General", "Base.93chevySilveradoCClongfd", nil, 15, "93chevySilverado")
Data.Add("Base.PickUpTruckLightsRanger", "General", "Base.93chevySilveradoXClongRanger", nil, 27, "93chevySilverado")

Data.Add("Base.PickUpTruck", "General", "Base.93chevySilveradoSC", nil, 8, "93chevySilverado")
Data.Add("Base.PickUpTruck", "General", "Base.93chevySilveradoSClong", nil, 3, "93chevySilverado")
Data.Add("Base.PickUpTruck", "General", "Base.93chevySilveradoSCdually", nil, 3, "93chevySilverado")
Data.Add("Base.PickUpTruck", "General", "Base.93chevySilveradoXC", nil, 6, "93chevySilverado")
Data.Add("Base.PickUpTruck", "General", "Base.93chevySilveradoXClong", nil, 2, "93chevySilverado")
Data.Add("Base.PickUpTruck", "General", "Base.93chevySilveradoXCdually", nil, 2, "93chevySilverado")
Data.Add("Base.PickUpTruck", "General", "Base.93chevySilveradoCC", nil, 4, "93chevySilverado")
Data.Add("Base.PickUpTruck", "General", "Base.93chevySilveradoCClong", nil, 1, "93chevySilverado")
Data.Add("Base.PickUpTruck", "General", "Base.93chevySilveradoCCdually", nil, 1, "93chevySilverado")

Data.Add("Base.VanUtility", "General", "Base.93chevySilveradoK3500wrecker", { 3, 4, 5, 6 }, 5, "93chevySilverado")
Data.Add("Base.VanUtility", "General", "Base.93chevySilveradoK3500flatbed", { 3, 4, 5, 6 }, 10, "93chevySilverado")

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.93chevySuburbanpd", { 0, 1 }, 20, "93chevySuburban_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.93chevySuburbanpd", { 0, 1 }, 12, "93chevySuburban_police", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.93chevySuburbanpd", { 0, 1 }, 20, "93chevySuburban_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.93chevySuburbanpd", { 0, 1 }, 20, "93chevySuburban_police", 20)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.93chevySuburbanpd", { 0, 1 }, 7, "93chevySuburban_police", 7)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.93chevySuburbanpd", { 2, 3, 4 }, 30, "93chevySuburban_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.93chevySuburbanpd", { 2, 3, 4 }, 15, "93chevySuburban_sheriff", 15)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93chevySuburbanpd", { 2, 3, 4 }, 7, "93chevySuburban_sheriff", 7)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.93chevySuburbanpd", { 2, 3, 4 }, 12, "93chevySuburban_sheriff", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.93chevySuburbanpd", { 2, 3, 4 }, 30, "93chevySuburban_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.93chevySuburbanpd", { 2, 3, 4 }, 8, "93chevySuburban_sheriff", 8)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.93chevySuburbanksp", { 0, 1 }, 40, "93chevySuburban_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.93chevySuburbanksp", { 0, 1 }, 25, "93chevySuburban_ksp", 25)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93chevySuburbanksp", { 0, 1 }, 21, "93chevySuburban_ksp", 21)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.93chevySuburbanksp", { 0, 1 }, 30, "93chevySuburban_ksp", 30)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.93chevySuburbanksp", { 0, 1 }, 28, "93chevySuburban_ksp", 28)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.93chevySuburbanksp", { 0, 1 }, 23, "93chevySuburban_ksp", 23)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.93chevySuburbanksp", { 0, 1 }, 50, "93chevySuburban_ksp", 50)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.93chevySuburbanksp", { 0, 1 }, 40, "93chevySuburban_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.93chevySuburbanksp", { 0, 1 }, 20, "93chevySuburban_ksp", 20)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.93chevySuburbanksp", { 0, 1 }, 22, "93chevySuburban_ksp", 22)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.93chevySuburbanksp", { 2 }, 8, "93chevySuburban_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.93chevySuburbanksp", { 2 }, 6, "93chevySuburban_ksp", 25)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93chevySuburbanksp", { 2 }, 4, "93chevySuburban_ksp", 21)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.93chevySuburbanksp", { 2 }, 6, "93chevySuburban_ksp", 30)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.93chevySuburbanksp", { 2 }, 6, "93chevySuburban_ksp", 28)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.93chevySuburbanksp", { 2 }, 4, "93chevySuburban_ksp", 23)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.93chevySuburbanksp", { 2 }, 10, "93chevySuburban_ksp", 50)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.93chevySuburbanksp", { 2 }, 8, "93chevySuburban_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.93chevySuburbanksp", { 2 }, 4, "93chevySuburban_ksp", 20)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.93chevySuburbanksp", { 2 }, 4, "93chevySuburban_ksp", 22)

Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93chevySuburbanfbi", nil, 10, "93chevySuburban_undercover", 2)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.93chevySuburbanfbi", nil, 10, "93chevySuburban_undercover", 1)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93chevySuburbanpdu", nil, 15, "93chevySuburban_undercover", 2)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.93chevySuburbanpdu", nil, 15, "93chevySuburban_undercover", 1)

Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93chevySuburbanPoliceCLPD", nil, 50, "93chevySuburban_CLPD", 49)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93chevySuburbanPoliceLCPD", nil, 20, "93chevySuburban_LCPD", 19)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.93chevySuburbanPoliceLCPD", nil, 60, "93chevySuburban_LCPD", 60)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.93chevySuburbanAirportSec", nil, 30, "93chevySuburban_airportSecurity", 28)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.93chevySuburbanPoliceLCPD", nil, 40, "93chevySuburban_LCPD", 42)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.93chevySilveradoPoliceMCS", nil, 12, "93chevySilverado_MCS", 20)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.93chevySuburbanPoliceMCS", nil, 20, "93chevySuburban_MCS", 20)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.93chevySuburbanPoliceMPD", nil, 50, "93chevySuburban_MPD", 49)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.93chevySuburbanPoliceWPPD", nil, 65, "93chevySuburban_WPPD", 65)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.93chevySilveradoPoliceMCS", nil, 35, "93chevySilverado_MCS", 50)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.93chevySuburbanPoliceMCS", nil, 50, "93chevySuburban_MCS", 50)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.93chevySuburbanPrison", nil, 10, "93chevySuburban_prison", 10)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.93chevySilveradoPoliceMCS", nil, 30, "93chevySilverado_MCS", 40)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.93chevySuburbanPoliceMCS", nil, 40, "93chevySuburban_MCS", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.93chevySilveradoPoliceBCS", nil, 45, "93chevySilverado_BCS", 65)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.93chevySuburbanPoliceBCS", nil, 65, "93chevySuburban_BCS", 65)
Data.Add("Base.PickUpVanLightsPolice", "General", "Base.93chevySuburbanPoliceMCS", nil, 10, "93chevySuburban_MCS", 10)
Data.Add("Base.PickUpVanLightsPolice", "General", "Base.93chevySilveradoPoliceMCS", nil, 5, "93chevySilverado_MCS", 10)

Data.Add("Base.VanUtility", "General", "Base.93fordElgin", nil, 3, "93fordElgin")
Data.Add("Base.VanUtility", "General", "Base.93fordElginSpec", nil, 2, "93fordElgin")

Data.Add("Base.PickUpTruck", "General", "Base.93fordF150", nil, 9, "93fordF350")
Data.Add("Base.PickUpTruck", "General", "Base.93fordF150S", nil, 1, "93fordF350")
Data.Add("Base.PickUpTruck", "General", "Base.93fordF250", nil, 12, "93fordF350")
Data.Add("Base.PickUpTruck", "General", "Base.93fordF350", nil, 6, "93fordF350")
Data.Add("Base.PickUpTruck", "General", "Base.93fordF350dually", nil, 3, "93fordF350")
Data.Add("Base.PickUpTruckLightsFire", "General", "Base.93fordF350fd", nil, 12, "93fordF350")
Data.Add("Base.PickUpTruckLightsFire", "General", "Base.93fordF350utilityFd", nil, 12, "93fordF350")
Data.Add("Base.VanUtility", "General", "Base.93fordF350utility", nil, 13, "93fordF350")
Data.Add("Base.VanUtility", "General", "Base.93fordF350utilityDpw", nil, 12, "93fordF350")
Data.Add("Base.OffRoad", "General", "Base.93fordF150S", nil, 10, "93fordF350")

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.93fordF350so", nil, 20, "93fordF350_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.93fordF350so", nil, 10, "93fordF350_sheriff", 15)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93fordF350so", nil, 5, "93fordF350_sheriff", 7)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.93fordF350so", nil, 8, "93fordF350_sheriff", 12)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.93fordF350so", nil, 20, "93fordF350_sheriff", 30)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.93fordF350so", nil, 5, "93fordF350_sheriff", 8)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.93fordF350pd", { 0, 1 }, 30, "93fordF350_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.93fordF350pd", { 0, 1 }, 18, "93fordF350_ksp", 25)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93fordF350pd", { 0, 1 }, 15, "93fordF350_ksp", 21)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.93fordF350pd", { 0, 1 }, 20, "93fordF350_ksp", 30)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.93fordF350pd", { 0, 1 }, 20, "93fordF350_ksp", 28)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.93fordF350pd", { 0, 1 }, 15, "93fordF350_ksp", 23)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.93fordF350pd", { 0, 1 }, 40, "93fordF350_ksp", 50)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.93fordF350pd", { 0, 1 }, 30, "93fordF350_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.93fordF350pd", { 0, 1 }, 15, "93fordF350_ksp", 20)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.93fordF350pd", { 0, 1 }, 15, "93fordF350_ksp", 22)

Data.Add("Base.PickUpVanLightsPolice", "General", "Base.93fordF350pd", { 2 }, 6, "93fordF350_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "Jefferson", "Base.93fordF350pd", { 2 }, 4, "93fordF350_ksp", 25)
Data.Add("Base.PickUpVanLightsPolice", "Louisville", "Base.93fordF350pd", { 2 }, 4, "93fordF350_ksp", 21)
Data.Add("Base.PickUpVanLightsPolice", "Muldraugh", "Base.93fordF350pd", { 2 }, 4, "93fordF350_ksp", 30)
Data.Add("Base.PickUpVanLightsPolice", "Rosewood", "Base.93fordF350pd", { 2 }, 4, "93fordF350_ksp", 28)
Data.Add("Base.PickUpVanLightsPolice", "WestPoint", "Base.93fordF350pd", { 2 }, 4, "93fordF350_ksp", 23)
Data.Add("Base.PickUpVanLightsPolice", "Riverside", "Base.93fordF350pd", { 2 }, 4, "93fordF350_ksp", 50)
Data.Add("Base.PickUpVanLightsPolice", "MarchRidge", "Base.93fordF350pd", { 2 }, 6, "93fordF350_ksp", 40)
Data.Add("Base.PickUpVanLightsPolice", "ValleyStation", "Base.93fordF350pd", { 2 }, 4, "93fordF350_ksp", 20)
Data.Add("Base.PickUpVanLightsPolice", "LAA", "Base.93fordF350pd", { 2 }, 4, "93fordF350_ksp", 22)

Data.Add("Base.CarLuxury", "General", "Base.93mustangSSP", nil, 10, "93mustangSSP")
Data.Add("Base.CarLuxury", "General", "Base.93mustangGT", nil, 8, "93mustangSSP")
Data.Add("Base.CarLuxury", "General", "Base.93mustangSVTcobraR", nil, 7, "93mustangSSP")
Data.Add("Base.ModernCar", "General", "Base.93mustangSSP", nil, 12, "93mustangSSP")
Data.Add("Base.ModernCar", "General", "Base.93mustangGT", nil, 9, "93mustangSSP")
Data.Add("Base.ModernCar", "General", "Base.93mustangSVTcobraR", nil, 9, "93mustangSSP")

Data.Add("Base.CarLightsPolice", "General", "Base.93mustangSSPpd", nil, 20, "93mustangSSP_police", 20)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.93mustangSSPpd", nil, 12, "93mustangSSP_police", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.93mustangSSPpd", nil, 20, "93mustangSSP_police", 20)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.93mustangSSPpd", nil, 20, "93mustangSSP_police", 20)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.93mustangSSPpd", nil, 15, "93mustangSSP_police", 15)

Data.Add("Base.CarLightsPolice", "General", "Base.93mustangSSPpd2", nil, 20, "93mustangSSP_police", 20)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.93mustangSSPpd2", nil, 12, "93mustangSSP_police", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.93mustangSSPpd2", nil, 20, "93mustangSSP_police", 20)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.93mustangSSPpd2", nil, 20, "93mustangSSP_police", 20)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.93mustangSSPpd2", nil, 15, "93mustangSSP_police", 15)

Data.Add("Base.CarLightsPolice", "General", "Base.93mustangSSPksp", nil, 40, "93mustangSSP_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.93mustangSSPksp", nil, 25, "93mustangSSP_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.93mustangSSPksp", nil, 21, "93mustangSSP_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.93mustangSSPksp", nil, 30, "93mustangSSP_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.93mustangSSPksp", nil, 28, "93mustangSSP_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.93mustangSSPksp", nil, 23, "93mustangSSP_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.93mustangSSPksp", nil, 50, "93mustangSSP_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.93mustangSSPksp", nil, 40, "93mustangSSP_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.93mustangSSPksp", nil, 20, "93mustangSSP_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.93mustangSSPksp", nil, 22, "93mustangSSP_ksp", 22)

Data.Add("Base.CarLightsPolice", "General", "Base.93mustangSSPksp2", nil, 40, "93mustangSSP_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.93mustangSSPksp2", nil, 25, "93mustangSSP_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.93mustangSSPksp2", nil, 21, "93mustangSSP_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.93mustangSSPksp2", nil, 30, "93mustangSSP_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.93mustangSSPksp2", nil, 28, "93mustangSSP_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.93mustangSSPksp2", nil, 23, "93mustangSSP_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.93mustangSSPksp2", nil, 50, "93mustangSSP_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.93mustangSSPksp2", nil, 40, "93mustangSSP_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.93mustangSSPksp2", nil, 20, "93mustangSSP_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.93mustangSSPksp2", nil, 22, "93mustangSSP_ksp", 22)

Data.Add("Base.CarLightsPolice", "General", "Base.93mustangSSPkspCol", nil, 40, "93mustangSSP_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.93mustangSSPkspCol", nil, 25, "93mustangSSP_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.93mustangSSPkspCol", nil, 21, "93mustangSSP_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.93mustangSSPkspCol", nil, 30, "93mustangSSP_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.93mustangSSPkspCol", nil, 28, "93mustangSSP_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.93mustangSSPkspCol", nil, 23, "93mustangSSP_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.93mustangSSPkspCol", nil, 50, "93mustangSSP_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.93mustangSSPkspCol", nil, 40, "93mustangSSP_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.93mustangSSPkspCol", nil, 20, "93mustangSSP_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.93mustangSSPkspCol", nil, 22, "93mustangSSP_ksp", 22)

Data.Add("Base.CarLightsPolice", "Louisville", "Base.93mustangSSPunmarked", nil, 10, "93mustangSSP_undercover", 2)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.93mustangSSPunmarked", nil, 10, "93mustangSSP_undercover", 1)

Data.Add("Base.CarLuxury", "General", "Base.93fordTaurusSHO", nil, 15, "93fordTaurus")
Data.Add("Base.CarNormal", "General", "Base.93fordTaurusSHO", nil, 8, "93fordTaurus")
Data.Add("Base.ModernCar", "General", "Base.93fordTaurusSHO", nil, 25, "93fordTaurus")
Data.Add("Base.CarNormal", "General", "Base.93fordTaurus", nil, 27, "93fordTaurus")
Data.Add("Base.ModernCar", "General", "Base.93fordTaurus", nil, 5, "93fordTaurus")
Data.Add("Base.CarStationWagon", "General", "Base.93fordTaurusWagon", nil, 25, "93fordTaurus")

Data.Add("Base.CarLuxury", "General", "Base.93townCar", nil, 25, "93townCar")
Data.Add("Base.ModernCar", "General", "Base.93townCar", nil, 30, "93townCar")

Data.Add("Base.ModernCar", "General", "Base.95impreza", nil, 12, "95impreza")
Data.Add("Base.ModernCar", "General", "Base.95imprezalhd", nil, 23, "95impreza")
Data.Add("Base.SportsCar", "General", "Base.95impreza", nil, 12, "95impreza")
Data.Add("Base.SportsCar", "General", "Base.95imprezalhd", nil, 23, "95impreza")
Data.Add("Base.RaceCar12", "General", "Base.95impreza", 6, 5, "95impreza")
Data.Add("Base.RaceCar12", "General", "Base.95imprezalhd", 6, 15, "95impreza")

Data.Add("Base.ModernCar", "General", "Base.96lancerEVO", nil, 12, "96lancerEVO")
Data.Add("Base.ModernCar", "General", "Base.96lancerEVOlhd", nil, 23, "96lancerEVO")
Data.Add("Base.SportsCar", "General", "Base.96lancerEVO", nil, 12, "96lancerEVO")
Data.Add("Base.SportsCar", "General", "Base.96lancerEVOlhd", nil, 23, "96lancerEVO")
Data.Add("Base.RaceCar12", "General", "Base.96lancerEVO", 6, 5, "96lancerEVO")
Data.Add("Base.RaceCar12", "General", "Base.96lancerEVOlhd", 6, 15, "96lancerEVO")

Data.Add("Base.ModernCar", "General", "Base.96saturnSL2", nil, 30, "96saturnSL2")
Data.Add("Base.CarNormal", "General", "Base.96saturnSL2", nil, 28, "96saturnSL2")

Data.Add("Base.CarStationWagon", "General", "Base.98stagea260RS", nil, 7, "98stagea")
Data.Add("Base.CarStationWagon", "General", "Base.98stagea260RSlhd", nil, 18, "98stagea")
Data.Add("Base.ModernCar", "General", "Base.98stagea260RS", nil, 10, "98stagea")
Data.Add("Base.ModernCar", "General", "Base.98stagea260RSlhd", nil, 20, "98stagea")

Data.Add("Base.CarLightsPolice", "General", "Base.99fordCVPI", { 1, 2 }, 20, "99fordCVPI_police", 20)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.99fordCVPI", { 1, 2 }, 12, "99fordCVPI_police", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.99fordCVPI", { 1, 2 }, 20, "99fordCVPI_police", 20)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.99fordCVPI", { 1, 2 }, 20, "99fordCVPI_police", 20)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.99fordCVPI", { 1, 2 }, 15, "99fordCVPI_police", 15)

Data.Add("Base.CarLightsPolice", "General", "Base.99fordCVPI", 3, 30, "99fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.99fordCVPI", 3, 15, "99fordCVPI_sheriff", 15)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.99fordCVPI", 3, 7, "99fordCVPI_sheriff", 7)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.99fordCVPI", 3, 12, "99fordCVPI_sheriff", 12)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.99fordCVPI", 3, 30, "99fordCVPI_sheriff", 30)
Data.Add("Base.CarLightsPolice", "LAA", "Base.99fordCVPI", 3, 8, "99fordCVPI_sheriff", 8)

Data.Add("Base.CarLightsPolice", "General", "Base.99fordCVPI", 0, 40, "99fordCVPI_ksp", 40)
Data.Add("Base.CarLightsPolice", "Jefferson", "Base.99fordCVPI", 0, 25, "99fordCVPI_ksp", 25)
Data.Add("Base.CarLightsPolice", "Louisville", "Base.99fordCVPI", 0, 21, "99fordCVPI_ksp", 21)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.99fordCVPI", 0, 30, "99fordCVPI_ksp", 30)
Data.Add("Base.CarLightsPolice", "Rosewood", "Base.99fordCVPI", 0, 28, "99fordCVPI_ksp", 28)
Data.Add("Base.CarLightsPolice", "WestPoint", "Base.99fordCVPI", 0, 23, "99fordCVPI_ksp", 23)
Data.Add("Base.CarLightsPolice", "Riverside", "Base.99fordCVPI", 0, 50, "99fordCVPI_ksp", 50)
Data.Add("Base.CarLightsPolice", "MarchRidge", "Base.99fordCVPI", 0, 40, "99fordCVPI_ksp", 40)
Data.Add("Base.CarLightsPolice", "ValleyStation", "Base.99fordCVPI", 0, 20, "99fordCVPI_ksp", 20)
Data.Add("Base.CarLightsPolice", "LAA", "Base.99fordCVPI", 0, 22, "99fordCVPI_ksp", 22)

Data.Add("Base.CarLightsPolice", "Louisville", "Base.99fordCVPIunmarked", nil, 20, "99fordCVPI_undercover", 2)
Data.Add("Base.CarLightsPolice", "Muldraugh", "Base.99fordCVPIunmarked", nil, 20, "99fordCVPI_undercover", 1)

Data.Add("Base.CarNormal", "General", "Base.04vwTouran", nil, 30, "04vwTouran")
Data.Add("Base.ModernCar", "General", "Base.04vwTouran", nil, 30, "04vwTouran")

Data.Add("Base.Trailer", "General", "Base.TrailerKI5utilitySmall", nil, 60, "KI5trailer")
Data.Add("Base.Trailer", "General", "Base.TrailerKI5utilityMedium", nil, 30, "KI5trailer")
Data.Add("Base.Trailer", "General", "Base.TrailerKI5utilityLarge", nil, 10, "KI5trailer")

Data.Add("Base.TrailerCover", "General", "Base.TrailerKI5cargoSmall", nil, 52, "KI5trailer")
Data.Add("Base.TrailerCover", "General", "Base.TrailerKI5cargoMedium", nil, 28, "KI5trailer")
Data.Add("Base.TrailerCover", "General", "Base.TrailerKI5cargoLarge", nil, 8, "KI5trailer")

Data.Add("Base.Trailer_Livestock", "General", "Base.TrailerKI5livestock", nil, 100, "KI5trailer")

Data.Add("Base.TrailerCover", "General", "Base.Trailer87Scamp13", nil, 5, "KI5trailerCamp")
Data.Add("Base.TrailerCover", "General", "Base.Trailer61Bambi16", nil, 3, "KI5trailerCamp")
Data.Add("Base.TrailerCover", "General", "Base.Trailer87Scamp16", nil, 3, "KI5trailerCamp")
Data.Add("Base.TrailerCover", "General", "Base.Trailer54FlyingCloud22", nil, 1, "KI5trailerCamp")

Data.RecalcChances()

return Data