VVR = VVR or {}
VVR.Data = {}
VVR.Data.Tab = {}

function VVR.Data.Add(scriptName, vehicleName, skinIndexes, chance, sortType, needRecalcChances)
	if not VVR.Data.Tab[scriptName] then return end
	if not ScriptManager.instance:getVehicle(vehicleName) then return end
	local vehicleData = { vehicleName = vehicleName, skinIndexes = skinIndexes, chance = chance, sortType = sortType, }
	table.insert(VVR.Data.Tab[scriptName], vehicleData)
	if needRecalcChances then
		VVR.Data.RecalcChances()
	end
end

function VVR.Data.Remove(scriptName, vehicleName, needRecalcChances)
	if not VVR.Data.Tab[scriptName] then return end
	if not ScriptManager.instance:getVehicle(vehicleName) then return end
	for num = #VVR.Data.Tab[scriptName], 1, -1 do
		if VVR.Data.Tab[scriptName][num].vehicleName == vehicleName then
			table.remove(VVR.Data.Tab[scriptName], num)
		end
	end
	if needRecalcChances then
		VVR.Data.RecalcChances()
	end
end

function VVR.Data.Empty(scriptName)
	if not VVR.Data.Tab[scriptName] then return end
	VVR.Data.Tab[scriptName] = {}
end

function VVR.Data.Find(vehicleName)
	local Data = {}
	for scriptName, baseVehicleData in pairs(VVR.Data.Tab) do
		for _, vehicleData in ipairs(baseVehicleData) do
			if vehicleData.vehicleName == vehicleName then
				table.insert(Data, scriptName)
			end
		end
	end
	return Data
end

local function sort(baseVehicleData)
	local sumChances = {}
	for _, vehicleData in ipairs(baseVehicleData) do
		if vehicleData.chance and vehicleData.sortType then
			if not sumChances[vehicleData.sortType] then sumChances[vehicleData.sortType] = 0 end
			sumChances[vehicleData.sortType] = sumChances[vehicleData.sortType]+vehicleData.chance
		end
	end
	table.sort(baseVehicleData, function(a, b)
		if sumChances[a.sortType] ~= sumChances[b.sortType] then
			return sumChances[a.sortType] > sumChances[b.sortType]
		end
		return a.sortType < b.sortType
	end)
end
	
function VVR.Data.RecalcChances()
	for _, baseVehicleData in pairs(VVR.Data.Tab) do
		local sumChances = 0
		for _, vehicleData in ipairs(baseVehicleData) do
			if vehicleData.chance then
				if type(vehicleData.chance) ~= "number" then error("Chance of "..vehicleData.vehicleName.." is not number") end
				sumChances = sumChances+vehicleData.chance
			end
		end
		for _, vehicleData in ipairs(baseVehicleData) do
			if vehicleData.chance then
				local chance = round((vehicleData.chance*100)/sumChances, 2)
				if vehicleData.chance ~= chance then vehicleData.chance = chance end
			end
		end
		sort(baseVehicleData)
	end
end

VVR.Data.Tab["Base.CarNormal"] = {}
VVR.Data.Tab["Base.SmallCar"] = VVR.Data.Tab["Base.CarNormal"]
VVR.Data.Tab["Base.SmallCar02"] = VVR.Data.Tab["Base.CarNormal"]
VVR.Data.Tab["Base.ModernCar"] = {}
VVR.Data.Tab["Base.ModernCar02"] = VVR.Data.Tab["Base.ModernCar"]
VVR.Data.Tab["Base.CarTaxi"] = {}
VVR.Data.Tab["Base.CarTaxi2"] = VVR.Data.Tab["Base.CarTaxi"]
VVR.Data.Tab["Base.PickUpTruck"] = {}
VVR.Data.Tab["Base.PickUpTruck_Camo"] = VVR.Data.Tab["Base.PickUpTruck"]
VVR.Data.Tab["Base.PickUpVan"] = {}
VVR.Data.Tab["Base.PickUpVan_Camo"] = VVR.Data.Tab["Base.PickUpVan"]
VVR.Data.Tab["Base.CarStationWagon"] = {}
VVR.Data.Tab["Base.CarStationWagon2"] = VVR.Data.Tab["Base.CarStationWagon"]
VVR.Data.Tab["Base.VanSeats"] = {}
VVR.Data.Tab["Base.Van"] = {}
VVR.Data.Tab["Base.StepVan"] = VVR.Data.Tab["Base.Van"]
VVR.Data.Tab["Base.SUV"] = {}
VVR.Data.Tab["Base.OffRoad"] = {}
VVR.Data.Tab["Base.CarLuxury"] = {}
VVR.Data.Tab["Base.SportsCar"] = {}
VVR.Data.Tab["Base.PickUpTruckLightsFire"] = {}
VVR.Data.Tab["Base.PickUpVanLightsFire"] = VVR.Data.Tab["Base.PickUpTruckLightsFire"]
VVR.Data.Tab["Base.CarLights"] = {}
VVR.Data.Tab["Base.PickUpTruckLights"] = {}
VVR.Data.Tab["Base.PickUpVanLights"] = VVR.Data.Tab["Base.PickUpTruckLights"]
VVR.Data.Tab["Base.VanAmbulance"] = {}
VVR.Data.Tab["Base.VanUtility"] = {}
VVR.Data.Tab["Base.Trailer"] = {}
VVR.Data.Tab["Base.TrailerCover"] = {}
VVR.Data.Tab["Base.TrailerAdvert"] = VVR.Data.Tab["Base.TrailerCover"]
VVR.Data.Tab["Base.PickUpVanLightsPolice"] = {}
VVR.Data.Tab["Base.CarLightsPolice"] = {}

--------------------------------------------------------
-------------------- Prof vehicles ---------------------
--------------------------------------------------------

if SandboxVars.VVR.Professional then

	VVR.Data.Tab["Base.VanMcCoy"] = {}

	VVR.Data.Tab["Base.PickUpTruckMccoy"] = VVR.Data.Tab["Base.VanMcCoy"]
	VVR.Data.Tab["Base.PickUpVanMccoy"] = VVR.Data.Tab["Base.VanMcCoy"]

	VVR.Data.Tab["Base.VanSpiffo"] = {}

	VVR.Data.Tab["Base.VanFossoil"] = {}

	VVR.Data.Tab["Base.PickUpTruckLightsFossoil"] = VVR.Data.Tab["Base.VanFossoil"]
	VVR.Data.Tab["Base.PickUpVanLightsFossoil"] = VVR.Data.Tab["Base.VanFossoil"]

	if getActivatedMods():contains("76chevyKseries") then
		VVR.Data.Add("Base.VanFossoil", "Base.76chevyK20utility", { 1 }, 25, "76chevyUtility")
		VVR.Data.Add("Base.VanFossoil", "Base.76chevyK30CCutility", { 1 }, 20, "76chevyUtility")
		VVR.Data.Add("Base.VanMcCoy", "Base.76chevyK20utility", { 2 }, 25, "76chevyUtility")
		VVR.Data.Add("Base.VanMcCoy", "Base.76chevyK30CCutility", { 2 }, 20, "76chevyUtility")
	end
	
	if getActivatedMods():contains("85chevyStepVanexpanded") then
		VVR.Data.Tab["Base.StepVanMail"] = { { vehicleName = "Base.85chevyStepVanPostal" } }
		VVR.Data.Tab["Base.StepVan_Scarlet"] = { { vehicleName = "Base.85chevyStepVanScarletOak" } }
		VVR.Data.Tab["Base.StepVan_Heralds"] = { { vehicleName = "Base.85chevyStepVanHerald" } }
	else
		VVR.Data.Tab["Base.StepVanMail"] = VVR.Data.Tab["Base.Van"]
		VVR.Data.Tab["Base.StepVan_Scarlet"] = VVR.Data.Tab["Base.Van"]
		VVR.Data.Tab["Base.StepVan_Heralds"] = VVR.Data.Tab["Base.Van"]
	end

	if getActivatedMods():contains("86fordE150") then
		VVR.Data.Add("Base.VanSpiffo", "Base.86fordE150slideSpiffo", nil, 75, "86fordE150")
		VVR.Data.Add("Base.VanMcCoy", "Base.86fordE150mccoy", nil, 35, "86fordE150")
	end
	
	if getActivatedMods():contains("86fordE150expanded") then
		VVR.Data.Add("Base.VanFossoil", "Base.86fordE150fossoil", nil, 60, "86fordE150")

		VVR.Data.Tab["Base.VanSpecial"] = { { vehicleName = "Base.86fordE150postal" } }
		VVR.Data.Tab["Base.VanRadio"] = { { vehicleName = "Base.86fordE150LBMWradio" } }
		VVR.Data.Tab["Base.Van_MassGenFac"] = { { vehicleName = "Base.86fordE150massGenfac" } }
		VVR.Data.Tab["Base.Van_Transit"] = { { vehicleName = "Base.86fordE150kyTransit" } }
		VVR.Data.Tab["Base.Van_LectroMax"] = { { vehicleName = "Base.86fordE150lectromax" } }
		VVR.Data.Tab["Base.Van_KnoxDisti"] = { { vehicleName = "Base.86fordE150knoxDistilery" } }
	else
		VVR.Data.Tab["Base.VanSpecial"] = VVR.Data.Tab["Base.Van"]
		VVR.Data.Tab["Base.VanRadio"] = VVR.Data.Tab["Base.Van"]
		VVR.Data.Tab["Base.Van_MassGenFac"] = VVR.Data.Tab["Base.Van"]
		VVR.Data.Tab["Base.Van_Transit"] = VVR.Data.Tab["Base.Van"]
		VVR.Data.Tab["Base.Van_LectroMax"] = VVR.Data.Tab["Base.Van"]
		VVR.Data.Tab["Base.Van_KnoxDisti"] = VVR.Data.Tab["Base.Van"]
	end
	
	if getActivatedMods():contains("87fordB700") then
		VVR.Data.Add("Base.VanSpiffo", "Base.87fordF700box", { 3 }, 25, "87fordB700")
	end

	if getActivatedMods():contains("93chevySuburban") then
		VVR.Data.Add("Base.VanFossoil", "Base.93chevySilveradoSClongFossoil", nil, 40, "93chevySilverado")
		VVR.Data.Add("Base.VanMcCoy", "Base.93chevySilveradoXClongMcCoy", nil, 40, "93chevySilverado")
	end

	if not VVR.Data.Tab["Base.VanSpiffo"] then
		VVR.Data.Tab["Base.VanSpiffo"] = VVR.Data.Tab["Base.Van"]
	end
	if not VVR.Data.Tab["Base.VanFossoil"] then
		VVR.Data.Tab["Base.VanFossoil"] = VVR.Data.Tab["Base.Van"]
	end
	if not VVR.Data.Tab["Base.VanMcCoy"] then
		VVR.Data.Tab["Base.VanMcCoy"] = VVR.Data.Tab["Base.Van"]
	end
	
--------------------------------------------------------
--------------- Temporary remplacements ----------------
--------------------------------------------------------

	VVR.Data.Tab["Base.VanRadio_3N"] = VVR.Data.Tab["Base.VanRadio"]

end

--------------------------------------------------------
------------------ Optional vehicles -------------------
--------------------------------------------------------

if getActivatedMods():contains("49powerWagon") then
	VVR.Data.Add("Base.PickUpTruck", "Base.49powerWagon", nil, 5, "49powerWagon")
	
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.49powerWagonPD", nil, 2, "49powerWagon")
end

if getActivatedMods():contains("59meteor") then
	VVR.Data.Add("Base.CarStationWagon", "Base.59meteor", nil, 5, "59meteor")
	VVR.Data.Add("Base.VanAmbulance", "Base.59ambulance", nil, 3, "59meteor")
end

if getActivatedMods():contains("63beetle") then
	VVR.Data.Add("Base.CarNormal", "Base.63beetle", nil, 3, "63beetle")
	VVR.Data.Add("Base.CarLuxury", "Base.63beetleHP", nil, 2, "63beetle")
	VVR.Data.Add("Base.OffRoad", "Base.63beetleBuggy", nil, 7, "63beetle")
end

if getActivatedMods():contains("63Type2Van") then
	VVR.Data.Add("Base.VanSeats", "Base.63Type2Van", nil, 10, "63Type2Van")
end

if getActivatedMods():contains("65banshee") then
	VVR.Data.Add("Base.SportsCar", "Base.65banshee400", nil, 1, "65banshee")
	VVR.Data.Add("Base.SportsCar", "Base.65bansheeSprint", nil, 1, "65banshee")
	VVR.Data.Add("Base.SportsCar", "Base.65bansheeXP", nil, 1, "65banshee")
end

if getActivatedMods():contains("66pontiacLeMans") then
	VVR.Data.Add("Base.CarLuxury", "Base.66pontiacGTO", nil, 3, "66pontiacLeMans")
	VVR.Data.Add("Base.CarLuxury", "Base.66pontiacGTOconv", nil, 2, "66pontiacLeMans")
	VVR.Data.Add("Base.CarLuxury", "Base.66pontiacLeMans", nil, 3, "66pontiacLeMans")
	VVR.Data.Add("Base.CarLuxury", "Base.66pontiacLeMansConv", nil, 2, "66pontiacLeMans")
end

if getActivatedMods():contains("67commando") then
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.67commandoPolice", nil, 1, "67commando")
end

if getActivatedMods():contains("67gt500") then
	VVR.Data.Add("Base.SportsCar", "Base.67gt500", nil, 4, "67gt500")
	VVR.Data.Add("Base.SportsCar", "Base.67gt500e", nil, 3, "67gt500")
end

if getActivatedMods():contains("68firebird") then
	VVR.Data.Add("Base.CarLuxury", "Base.68firebird350", nil, 6, "68firebird")
	VVR.Data.Add("Base.CarLuxury", "Base.68firebird400", nil, 4, "68firebird")
	VVR.Data.Add("Base.SportsCar", "Base.68firebirdRamAir", nil, 4, "68firebird")
	VVR.Data.Add("Base.SportsCar", "Base.68firebirdRamAirCustom", nil, 3, "68firebird")
end

if getActivatedMods():contains("69camaro") then
	VVR.Data.Add("Base.SportsCar", "Base.69camaroRS", nil, 4, "69camaro")
	VVR.Data.Add("Base.SportsCar", "Base.69camaroSS", nil, 4, "69camaro")
end

if getActivatedMods():contains("69charger") then
	VVR.Data.Add("Base.CarLuxury", "Base.69chargerRT", nil, 4, "69charger")
	VVR.Data.Add("Base.CarLuxury", "Base.69charger500", nil, 4, "69charger")
	VVR.Data.Add("Base.SportsCar", "Base.69chargerDaytona", nil, 10, "69charger")
end

if getActivatedMods():contains("69mini") then
	VVR.Data.Add("Base.CarNormal", "Base.69mini", nil, 3, "69mini")
end

if getActivatedMods():contains("69mini_ItalianJob") then
	VVR.Data.Add("Base.CarNormal", "Base.69miniIJ", nil, 1, "69miniIJ")
end

if getActivatedMods():contains("69mini_PitbullSpecial") then
	VVR.Data.Add("Base.SportsCar", "Base.69miniPS", nil, 2, "69mini")
end

if getActivatedMods():contains("70dodge") then
	VVR.Data.Add("Base.CarLuxury", "Base.70dodgeBG", nil, 2, "70dodge")
	VVR.Data.Add("Base.CarLuxury", "Base.70dodgeOP", nil, 2, "70dodge")
	VVR.Data.Add("Base.CarLuxury", "Base.70dodgeRT", nil, 2, "70dodge")
	VVR.Data.Add("Base.CarLuxury", "Base.70dodgeTA", nil, 2, "70dodge")
	
	VVR.Data.Add("Base.CarLightsPolice", "Base.70dodgePD", nil, 7, "70dodge")
end

if getActivatedMods():contains("70barracuda") then
	VVR.Data.Add("Base.CarLuxury", "Base.70barracuda", nil, 3, "70barracuda")
	VVR.Data.Add("Base.CarLuxury", "Base.70barracudaAAR", nil, 3, "70barracuda")
	VVR.Data.Add("Base.CarLuxury", "Base.70cuda", nil, 3, "70barracuda")
end

if getActivatedMods():contains("70roadRunner") then
	VVR.Data.Add("Base.CarLuxury", "Base.70roadRunner", nil, 12, "70roadRunner")
end

if getActivatedMods():contains("73fordFalcon") then
	VVR.Data.Add("Base.CarLuxury", "Base.73fordFalconXBGT", nil, 3, "73fordFalcon")
	VVR.Data.Add("Base.CarLuxury", "Base.73fordFalconXBGTlhd", nil, 6, "73fordFalcon")
end

if getActivatedMods():contains("75grandPrix") then
	VVR.Data.Add("Base.CarLuxury", "Base.75grandPrixHurst", nil, 3, "75grandPrix")
	VVR.Data.Add("Base.CarLuxury", "Base.75grandPrixLJ", nil, 3, "75grandPrix")
	VVR.Data.Add("Base.CarLuxury", "Base.75grandPrixSJ", nil, 3, "75grandPrix")
end

if getActivatedMods():contains("76chevyKseries") then
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.76chevyK10fd", nil, 13, "76chevy")
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.76chevyK20fd", nil, 17, "76chevy")
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.76chevyK30CCfd", nil, 20, "76chevy")
	
	VVR.Data.Add("Base.PickUpTruck", "Base.76chevyK10", nil, 7, "76chevy")
	VVR.Data.Add("Base.PickUpTruck", "Base.76chevyK20", nil, 8, "76chevy")
	VVR.Data.Add("Base.PickUpTruck", "Base.76chevyK20BigRed", nil, 1, "76chevy")
	VVR.Data.Add("Base.PickUpTruck", "Base.76chevyK30CC", nil, 6, "76chevy")
	VVR.Data.Add("Base.PickUpTruck", "Base.76chevyK30SCdually", nil, 2, "76chevy")
	VVR.Data.Add("Base.PickUpTruck", "Base.76chevyK30CCdually", nil, 1, "76chevy")
end

if getActivatedMods():contains("77firebird") then
	VVR.Data.Add("Base.CarLuxury", "Base.77firebird", nil, 10, "77firebird")
	VVR.Data.Add("Base.SportsCar", "Base.77firebirdES", nil, 3, "77firebird")
	VVR.Data.Add("Base.SportsCar", "Base.77firebirdFR", nil, 3, "77firebird")
	VVR.Data.Add("Base.SportsCar", "Base.77firebirdTA", nil, 3, "77firebird")
end

if getActivatedMods():contains("81deloreanDMC12") then
	VVR.Data.Add("Base.SportsCar", "Base.81deloreanDMC12", nil, 10, "81delorean")
end

if getActivatedMods():contains("82jeepJ10") then
	VVR.Data.Add("Base.PickUpTruck", "Base.82jeepJ10", nil, 20, "82jeepJ10")
	VVR.Data.Add("Base.PickUpTruckLights", "Base.82jeepJ10ranger", nil, 30, "82jeepJ10")

	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.82jeepJ10pd", nil, 15, "82jeepJ10")
end

if getActivatedMods():contains("82firebird") then
	VVR.Data.Add("Base.CarLuxury", "Base.82firebird", nil, 8, "82firebird")
	VVR.Data.Add("Base.CarLuxury", "Base.82firebirdTA", nil, 7, "82firebird")
end

if getActivatedMods():contains("82firebirdKITT") then
	VVR.Data.Add("Base.SportsCar", "Base.82firebirdKITT", nil, 1, "82firebird")
	VVR.Data.Add("Base.SportsCar", "Base.82firebirdKARR", nil, 1, "82firebird")
end

if getActivatedMods():contains("82porsche911") then
	VVR.Data.Add("Base.SportsCar", "Base.82porsche911rwb", nil, 18, "82porsche911")
	VVR.Data.Add("Base.SportsCar", "Base.82porsche911turbo", nil, 17, "82porsche911")
end

if getActivatedMods():contains("84buickElectra") then
	VVR.Data.Add("Base.CarLuxury", "Base.84buickElectraSedan", nil, 14, "84buickElectra")
	VVR.Data.Add("Base.CarLuxury", "Base.84buickElectraCoupe", nil, 9, "84buickElectra")
end

if getActivatedMods():contains("84cadillacDeVille") then
	VVR.Data.Add("Base.CarLuxury", "Base.84cadillacDeVilleSedan", nil, 14, "84cadillacDeVille")
	VVR.Data.Add("Base.CarLuxury", "Base.84cadillacDeVilleCoupe", nil, 9, "84cadillacDeVille")
end

if getActivatedMods():contains("84jeepXJ") then
	VVR.Data.Add("Base.SUV", "Base.84jeepXJ2", nil, 10, "84jeepXJ")
	VVR.Data.Add("Base.SUV", "Base.84jeepXJ4", nil, 15, "84jeepXJ")
	VVR.Data.Add("Base.OffRoad", "Base.84jeepXJ2", nil, 13, "84jeepXJ")
	VVR.Data.Add("Base.OffRoad", "Base.84jeepXJ4", nil, 12, "84jeepXJ")
	VVR.Data.Add("Base.PickUpTruckLights", "Base.84jeepXJranger", nil, 45, "84jeepXJ")
	
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.84jeepXJpd", nil, 12, "84jeepXJ")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.84jeepXJksp", nil, 23, "84jeepXJ")
end

if getActivatedMods():contains("84merc") then
	VVR.Data.Add("Base.OffRoad", "Base.84mercLWB2", nil, 13, "84merc")
	VVR.Data.Add("Base.OffRoad", "Base.84mercLWB4", nil, 12, "84merc")
	VVR.Data.Add("Base.OffRoad", "Base.84mercSWB", nil, 20, "84merc")
end

if getActivatedMods():contains("84oldsmobile98") then
	VVR.Data.Add("Base.CarLuxury", "Base.84oldsmobile98Sedan", nil, 14, "84oldsmobile98")
	VVR.Data.Add("Base.CarLuxury", "Base.84oldsmobile98Coupe", nil, 9, "84oldsmobile98")
end

if getActivatedMods():contains("85buickLeSabre") then
	VVR.Data.Add("Base.CarNormal", "Base.85buickLeSabreSedan", nil, 22, "85buickLeSabre")
	VVR.Data.Add("Base.CarNormal", "Base.85buickLeSabreCoupe", nil, 13, "85buickLeSabre")
	VVR.Data.Add("Base.CarStationWagon", "Base.85buickLeSabreWagon", nil, 15, "85buickLeSabre")
	VVR.Data.Add("Base.CarStationWagon", "Base.85buickLeSabreWagon2", nil, 15, "85buickLeSabre")
end

if getActivatedMods():contains("85chevyCaprice") then
	VVR.Data.Add("Base.CarNormal", "Base.85chevyCapriceSedan", nil, 22, "85chevyCaprice")
	VVR.Data.Add("Base.CarNormal", "Base.85chevyCapriceCoupe", nil, 12, "85chevyCaprice")
	VVR.Data.Add("Base.CarStationWagon", "Base.85chevyCapriceWagon", nil, 15, "85chevyCaprice")
	VVR.Data.Add("Base.CarStationWagon", "Base.85chevyCapriceWagon2", nil, 15, "85chevyCaprice")
	VVR.Data.Add("Base.CarTaxi", "Base.85chevyImpalaSedanTaxi", nil, 40, "85chevyImpala")
	VVR.Data.Add("Base.CarLights", "Base.85chevyImpalaSedanRanger", nil, 50, "85chevyImpala")
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.85chevyImpalaSedanFD", nil, 8, "85chevyImpala")
	
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanCLPD", nil, 2, "85chevyImpala")
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanLCPD", nil, 5, "85chevyImpala")
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanMCS", nil, 8, "85chevyImpala")
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanMPD", nil, 3, "85chevyImpala")
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanWPPD", nil, 2, "85chevyImpala")
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanPrison", nil, 3, "85chevyImpala")
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanBCS", nil, 1, "85chevyImpala")
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanPD", nil, 12, "85chevyImpala")
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanKSP", nil, 23, "85chevyImpala")
	VVR.Data.Add("Base.CarLightsPolice", "Base.85chevyImpalaSedanPDu", nil, 1, "85chevyImpala")
end

if getActivatedMods():contains("85chevyStepVan") then
	VVR.Data.Add("Base.Van", "Base.85chevyStepVan", nil, 40, "85chevyStepVan")
end

if getActivatedMods():contains("85oldsmobileDelta88") then
	VVR.Data.Add("Base.CarNormal", "Base.85oldsmobileDelta88Sedan", nil, 22, "85oldsmobileDelta88")
	VVR.Data.Add("Base.CarNormal", "Base.85oldsmobileDelta88Coupe", nil, 13, "85oldsmobileDelta88")
	VVR.Data.Add("Base.CarStationWagon", "Base.85oldsmobileDelta88Wagon", nil, 15, "85oldsmobileDelta88")
	VVR.Data.Add("Base.CarStationWagon", "Base.85oldsmobileDelta88Wagon2", nil, 15, "85oldsmobileDelta88")
end


if getActivatedMods():contains("85pontiacParisienne") then
	VVR.Data.Add("Base.CarNormal", "Base.85pontiacParisienneSedan", nil, 35, "85pontiacParisienne")
	VVR.Data.Add("Base.CarStationWagon", "Base.85pontiacParisienneWagon", nil, 15, "85pontiacParisienne")
	VVR.Data.Add("Base.CarStationWagon", "Base.85pontiacParisienneWagon2", nil, 15, "85pontiacParisienne")
end


if getActivatedMods():contains("86chevyCUCV") then
	VVR.Data.Add("Base.SUV", "Base.86chevyK5blazer", nil, 20, "86chevyK5")
	VVR.Data.Add("Base.PickUpVan", "Base.86chevyK5blazer", nil, 30, "86chevyK5")
	VVR.Data.Add("Base.OffRoad", "Base.86chevyK5blazer", nil, 15, "86chevyK5")
	
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.86chevyK5pd", nil, 12, "86chevyK5")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.86chevyK5ksp", nil, 23, "86chevyK5")
end

if getActivatedMods():contains("86fordE150") then
	VVR.Data.Add("Base.Van", "Base.86fordE150", nil, 35, "86fordE150")
	VVR.Data.Add("Base.Van", "Base.86fordE150long", nil, 12, "86fordE150")
	VVR.Data.Add("Base.Van", "Base.86fordE150slide", nil, 13, "86fordE150")
	VVR.Data.Add("Base.VanSeats", "Base.86fordE150longW", nil, 35, "86fordE150")
	VVR.Data.Add("Base.VanAmbulance", "Base.86fordE150med", nil, 7, "86fordE150")
	
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.86fordE150so", nil, 12, "86fordE150")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.86fordE150ksp", nil, 23, "86fordE150")
end

if getActivatedMods():contains("86oshkoshP19A") then
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.86oshkoshKYFD", nil, 35, "86oshkosh")
end

if getActivatedMods():contains("87buickRegal") then
	VVR.Data.Add("Base.CarLuxury", "Base.87buickRegalGNX", nil, 25, "87buickRegal")
	VVR.Data.Add("Base.SportsCar", "Base.87buickRegalTurboT", nil, 15, "87buickRegal")
	
	VVR.Data.Add("Base.CarLightsPolice", "Base.87buickRegalTurboTfbi", nil, 1, "87buickRegal")
end

if getActivatedMods():contains("87chevySuburban") then
	VVR.Data.Add("Base.SUV", "Base.87chevySuburban", nil, 30, "87chevySuburban")
	VVR.Data.Add("Base.SUV", "Base.87chevySuburbanOP", nil, 5, "87chevySuburban")
	VVR.Data.Add("Base.OffRoad", "Base.87chevySuburbanOP", nil, 10, "87chevySuburban")
end

if getActivatedMods():contains("87fordB700") then
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.87fordF700swat", nil, 2, "87fordF700")
end

if getActivatedMods():contains("87toyotaMR2") then
	VVR.Data.Add("Base.SportsCar", "Base.87toyotaMR2", nil, 16, "87toyotaMR2")
	VVR.Data.Add("Base.SportsCar", "Base.87toyotaMR2c", nil, 14, "87toyotaMR2")
end

if getActivatedMods():contains("88chevyS10") then
	VVR.Data.Add("Base.PickUpTruck", "Base.88chevyS10", nil, 25, "88chevyS10")
end

if getActivatedMods():contains("88toyotaHilux") then
	VVR.Data.Add("Base.PickUpTruck", "Base.88toyotaHiluxSC", nil, 15, "88toyotaHilux")
	VVR.Data.Add("Base.PickUpTruck", "Base.88toyotaHiluxXC", nil, 10, "88toyotaHilux")
	VVR.Data.Add("Base.PickUpVan", "Base.88toyotaHiluxSC", nil, 9, "88toyotaHilux")
	VVR.Data.Add("Base.PickUpVan", "Base.88toyotaHiluxXC", nil, 5, "88toyotaHilux")
	VVR.Data.Add("Base.PickUpVan", "Base.88toyotaHiluxXCS", nil, 1, "88toyotaHilux")
end

if getActivatedMods():contains("89fordBronco") then
	VVR.Data.Add("Base.PickUpVan", "Base.89fordBronco", nil, 45, "89fordBronco")
	VVR.Data.Add("Base.PickUpTruckLights", "Base.89fordBroncoRanger", nil, 35, "89fordBronco")
	
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.89fordBroncoPD", nil, 20, "89fordBronco")
end

if getActivatedMods():contains("89dodgeCaravan") then
	VVR.Data.Add("Base.VanSeats", "Base.89dodgeCaravan", nil, 25, "89dodgeCaravan")
	VVR.Data.Add("Base.VanSeats", "Base.89dodgeCaravanLE", nil, 20, "89dodgeCaravan")
	VVR.Data.Add("Base.VanSeats", "Base.89dodgeCaravanNomad", nil, 5, "89dodgeCaravan")
	VVR.Data.Add("Base.OffRoad", "Base.89dodgeCaravanNomad", nil, 4, "89dodgeCaravan")
end

if getActivatedMods():contains("89trooper") then
	VVR.Data.Add("Base.OffRoad", "Base.89trooper", nil, 12, "89trooper")
	VVR.Data.Add("Base.OffRoad", "Base.89trooperOP", nil, 20, "89trooper")
	VVR.Data.Add("Base.OffRoad", "Base.89trooperRS", nil, 13, "89trooper")
end

if getActivatedMods():contains("89defender") then
	VVR.Data.Add("Base.SUV", "Base.89defender110", nil, 21, "89defender")
	VVR.Data.Add("Base.SUV", "Base.89defender110utility", nil, 4, "89defender")
	VVR.Data.Add("Base.OffRoad", "Base.89defender90", nil, 24, "89defender")
	VVR.Data.Add("Base.OffRoad", "Base.89defender90utility", nil, 6, "89defender")
	VVR.Data.Add("Base.PickUpVan", "Base.89defender130", nil, 7, "89defender")
	VVR.Data.Add("Base.PickUpTruck", "Base.89defender130", nil, 10, "89defender")
end

if getActivatedMods():contains("89volvo200") then
	VVR.Data.Add("Base.CarNormal", "Base.89volvo244sedan", nil, 35, "89volvo200")
	VVR.Data.Add("Base.CarStationWagon", "Base.89volvo245wagon", nil, 25, "89volvo200")
	VVR.Data.Add("Base.CarLuxury", "Base.89volvo242turbo", nil, 9, "89volvo200")
end

if getActivatedMods():contains("90bmwE30") then
	VVR.Data.Add("Base.CarNormal", "Base.90bmwE30sedan2", nil, 8, "90bmwE30")
	VVR.Data.Add("Base.CarNormal", "Base.90bmwE30sedan4", nil, 12, "90bmwE30")
	VVR.Data.Add("Base.ModernCar", "Base.90bmwE30sedan2", nil, 15, "90bmwE30")
	VVR.Data.Add("Base.ModernCar", "Base.90bmwE30sedan4", nil, 15, "90bmwE30")
	VVR.Data.Add("Base.CarStationWagon", "Base.90bmwE30touring", nil, 13, "90bmwE30")
	VVR.Data.Add("Base.CarLuxury", "Base.90bmwE30cabrio", nil, 27, "90bmwE30")
	VVR.Data.Add("Base.SportsCar", "Base.90bmwE30m3", nil, 31, "90bmwE30")
end

if getActivatedMods():contains("90fordF350ambulance") then
	VVR.Data.Add("Base.VanAmbulance", "Base.90fordF350ambulance", nil, 75, "90fordF350")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.90fordF350SWAT", nil, 2, "90fordF350")
end

if getActivatedMods():contains("90pierceArrow") then
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.90pierceArrow", nil, 50, "90pierceArrow")
end

if getActivatedMods():contains("91fordLTD") then
	VVR.Data.Add("Base.CarNormal", "Base.91fordLTD", nil, 30, "91fordLTD")
	VVR.Data.Add("Base.ModernCar", "Base.91fordLTD", nil, 25, "91fordLTD")
	VVR.Data.Add("Base.CarStationWagon", "Base.91fordLTDwagon", nil, 25, "91fordLTD")
	VVR.Data.Add("Base.CarTaxi", "Base.91fordLTDtaxi", nil, 30, "91fordLTD")
	VVR.Data.Add("Base.CarLights", "Base.91fordLTDranger", nil, 50, "91fordLTD")
	
	VVR.Data.Add("Base.CarLightsPolice", "Base.91fordLTDpd", nil, 18, "91fordLTD")
	VVR.Data.Add("Base.CarLightsPolice", "Base.91fordLTDksp", nil, 16, "91fordLTD")
	VVR.Data.Add("Base.CarLightsPolice", "Base.91fordLTDksp2", nil, 16, "91fordLTD")
	VVR.Data.Add("Base.CarLightsPolice", "Base.91fordLTDunmarked", nil, 1, "91fordLTD")
end

if getActivatedMods():contains("91geoMetro") then
	VVR.Data.Add("Base.CarNormal", "Base.91geoMetro", nil, 45, "91geoMetro")
end

if getActivatedMods():contains("91fordRanger") then
	VVR.Data.Add("Base.PickUpTruck", "Base.91fordRangerSC", nil, 10, "91fordRanger")
	VVR.Data.Add("Base.PickUpTruck", "Base.91fordRangerSClong", nil, 7, "91fordRanger")
	VVR.Data.Add("Base.PickUpTruck", "Base.91fordRangerXC", nil, 8, "91fordRanger")
	VVR.Data.Add("Base.PickUpTruck", "Base.91fordRangerXClong", nil, 5, "91fordRanger")
	VVR.Data.Add("Base.PickUpVan", "Base.91fordRangerSC", nil, 7, "91fordRanger")
	VVR.Data.Add("Base.PickUpVan", "Base.91fordRangerSClong", nil, 5, "91fordRanger")
	VVR.Data.Add("Base.PickUpVan", "Base.91fordRangerXC", nil, 5, "91fordRanger")
	VVR.Data.Add("Base.PickUpVan", "Base.91fordRangerXClong", nil, 3, "91fordRanger")
	VVR.Data.Add("Base.PickUpTruckLights", "Base.91fordRangerRanger", nil, 35, "91fordRanger")
	
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.91fordRangerPD", { 0, 1 }, 20, "91fordRanger")
end

if getActivatedMods():contains("91nissan240sx") then
	VVR.Data.Add("Base.SportsCar", "Base.91nissan240sx", nil, 18, "91nissan240sx")
	VVR.Data.Add("Base.SportsCar", "Base.91nissan240sx2", nil, 17, "91nissan240sx")
end

if getActivatedMods():contains("91range") then
	VVR.Data.Add("Base.SUV", "Base.91range", nil, 16, "91range")
	VVR.Data.Add("Base.SUV", "Base.91range2", nil, 11, "91range")
	VVR.Data.Add("Base.OffRoad", "Base.91range", nil, 13, "91range")
	VVR.Data.Add("Base.OffRoad", "Base.91range2", nil, 12, "91range")
end

if getActivatedMods():contains("92fordCVPI") then
	VVR.Data.Add("Base.CarNormal", "Base.92fordCV", nil, 30, "92fordCV")
	VVR.Data.Add("Base.ModernCar", "Base.92fordCV", nil, 25, "92fordCV")
	VVR.Data.Add("Base.CarTaxi", "Base.92fordCVPItaxi", nil, 25, "92fordCV")
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.92fordCVPIfd", nil, 8, "92fordCV")
	
	VVR.Data.Add("Base.CarLightsPolice", "Base.92fordCVPI", nil, 10, "92fordCVPI")
	VVR.Data.Add("Base.CarLightsPolice", "Base.92fordCVPI2", nil, 10, "92fordCVPI")
	VVR.Data.Add("Base.CarLightsPolice", "Base.92fordCVPI2ksp", nil, 15, "92fordCVPI")
	VVR.Data.Add("Base.CarLightsPolice", "Base.92fordCVPI2kspst", nil, 10, "92fordCVPI")
	VVR.Data.Add("Base.CarLightsPolice", "Base.92fordCVPI2so", nil, 9, "92fordCVPI")
	VVR.Data.Add("Base.CarLightsPolice", "Base.92fordCVPI2sup", nil, 6, "92fordCVPI")
	VVR.Data.Add("Base.CarLightsPolice", "Base.92fordCVPIunmarked", nil, 1, "92fordCVPI")
	VVR.Data.Add("Base.CarLightsPolice", "Base.92fordCVPIpdu", nil, 1, "92fordCVPI")
end

if getActivatedMods():contains("92jeepYJ") then
	VVR.Data.Add("Base.OffRoad", "Base.92jeepYJs", nil, 20, "92jeepYJ")
	VVR.Data.Add("Base.OffRoad", "Base.92jeepYJse", nil, 17, "92jeepYJ")
	VVR.Data.Add("Base.PickUpTruckLights", "Base.92jeepYJranger", nil, 20, "92jeepYJ")
end

if getActivatedMods():contains("92jeepYJJP18") then
	VVR.Data.Add("Base.OffRoad", "Base.92jeepYJjp", nil, 3, "92jeepYJ")
end

if getActivatedMods():contains("92nissanGTR") then
	VVR.Data.Add("Base.SportsCar", "Base.92nissanGTR", nil, 12, "92nissanGTR")
	VVR.Data.Add("Base.SportsCar", "Base.92nissanGTRlhd", nil, 23, "92nissanGTR")
end

if getActivatedMods():contains("93chevySuburban") then
	VVR.Data.Add("Base.SUV", "Base.93chevySuburban", nil, 26, "93chevySuburban")
	VVR.Data.Add("Base.SUV", "Base.93chevySuburbanDually", nil, 9, "93chevySuburban")
	
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.93chevySuburbanfd", nil, 20, "93chevySuburban")
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.93chevySilveradoCClongfd", nil, 15, "93chevySilverado")
	VVR.Data.Add("Base.PickUpTruckLights", "Base.93chevySilveradoXClongRanger", nil, 27, "93chevySilverado")
	
	VVR.Data.Add("Base.PickUpTruck", "Base.93chevySilveradoSC", nil, 8, "93chevySilverado")
	VVR.Data.Add("Base.PickUpTruck", "Base.93chevySilveradoSClong", nil, 3, "93chevySilverado")
	VVR.Data.Add("Base.PickUpTruck", "Base.93chevySilveradoSCdually", nil, 3, "93chevySilverado")
	VVR.Data.Add("Base.PickUpTruck", "Base.93chevySilveradoXC", nil, 6, "93chevySilverado")
	VVR.Data.Add("Base.PickUpTruck", "Base.93chevySilveradoXClong", nil, 2, "93chevySilverado")
	VVR.Data.Add("Base.PickUpTruck", "Base.93chevySilveradoXCdually", nil, 2, "93chevySilverado")
	VVR.Data.Add("Base.PickUpTruck", "Base.93chevySilveradoCC", nil, 4, "93chevySilverado")
	VVR.Data.Add("Base.PickUpTruck", "Base.93chevySilveradoCClong", nil, 1, "93chevySilverado")
	VVR.Data.Add("Base.PickUpTruck", "Base.93chevySilveradoCCdually", nil, 1, "93chevySilverado")
	
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanpd", nil, 12, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanksp", nil, 23, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanfbi", nil, 1, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanpdu", nil, 1, "93chevySuburban")
end

if getActivatedMods():contains("93chevySuburbanExpanded") then
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanPoliceCLPD", nil, 2, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanPoliceLCPD", nil, 5, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySilveradoPoliceMCS", nil, 4, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanPoliceMCS", nil, 4, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanPoliceMPD", nil, 3, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanPoliceWPPD", nil, 2, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanPrison", nil, 3, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySilveradoPoliceBCS", nil, 0.5, "93chevySuburban")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93chevySuburbanPoliceBCS", nil, 0.5, "93chevySuburban")
end

if getActivatedMods():contains("93fordF350") then
	VVR.Data.Add("Base.PickUpTruck", "Base.93fordF150", nil, 9, "93fordF350")
	VVR.Data.Add("Base.PickUpTruck", "Base.93fordF150S", nil, 1, "93fordF350")
	VVR.Data.Add("Base.PickUpTruck", "Base.93fordF250", nil, 12, "93fordF350")
	VVR.Data.Add("Base.PickUpTruck", "Base.93fordF350", nil, 6, "93fordF350")
	VVR.Data.Add("Base.PickUpTruck", "Base.93fordF350dually", nil, 3, "93fordF350")
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.93fordF350fd", nil, 12, "93fordF350")
	VVR.Data.Add("Base.PickUpTruckLightsFire", "Base.93fordF350utilityFd", nil, 12, "93fordF350")
	VVR.Data.Add("Base.VanUtility", "Base.93fordF350utility", nil, 13, "93fordF350")
	VVR.Data.Add("Base.VanUtility", "Base.93fordF350utilityDpw", nil, 12, "93fordF350")
	VVR.Data.Add("Base.OffRoad", "Base.93fordF150S", nil, 10, "93fordF350")
	
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93fordF350so", nil, 10, "93fordF350")
	VVR.Data.Add("Base.PickUpVanLightsPolice", "Base.93fordF350pd", nil, 15, "93fordF350")
end

if getActivatedMods():contains("93mustangSSP") then
	VVR.Data.Add("Base.CarLuxury", "Base.93mustangSSP", nil, 25, "93mustangSSP")
	VVR.Data.Add("Base.ModernCar", "Base.93mustangSSP", nil, 30, "93mustangSSP")
	
	VVR.Data.Add("Base.CarLightsPolice", "Base.93mustangSSPpd", nil, 20, "93mustangSSP")
	VVR.Data.Add("Base.CarLightsPolice", "Base.93mustangSSPksp", nil, 18, "93mustangSSP")
	VVR.Data.Add("Base.CarLightsPolice", "Base.93mustangSSPkspCol", nil, 12, "93mustangSSP")
	VVR.Data.Add("Base.CarLightsPolice", "Base.93mustangSSPunmarked", nil, 1, "93mustangSSP")
end

if getActivatedMods():contains("93fordTaurus") then
	VVR.Data.Add("Base.CarLuxury", "Base.93fordTaurusSHO", nil, 15, "93fordTaurus")
	VVR.Data.Add("Base.CarNormal", "Base.93fordTaurusSHO", nil, 8, "93fordTaurus")
	VVR.Data.Add("Base.ModernCar", "Base.93fordTaurusSHO", nil, 25, "93fordTaurus")
	VVR.Data.Add("Base.CarNormal", "Base.93fordTaurus", nil, 27, "93fordTaurus")
	VVR.Data.Add("Base.ModernCar", "Base.93fordTaurus", nil, 5, "93fordTaurus")
	VVR.Data.Add("Base.CarStationWagon", "Base.93fordTaurusWagon", nil, 25, "93fordTaurus")
end

if getActivatedMods():contains("93townCar") then
	VVR.Data.Add("Base.CarLuxury", "Base.93townCar", nil, 25, "93townCar")
	VVR.Data.Add("Base.ModernCar", "Base.93townCar", nil, 30, "93townCar")
end

if getActivatedMods():contains("95impreza") then
	VVR.Data.Add("Base.ModernCar", "Base.95impreza", nil, 12, "95impreza")
	VVR.Data.Add("Base.ModernCar", "Base.95imprezalhd", nil, 23, "95impreza")
	VVR.Data.Add("Base.SportsCar", "Base.95impreza", nil, 12, "95impreza")
	VVR.Data.Add("Base.SportsCar", "Base.95imprezalhd", nil, 23, "95impreza")
end

if getActivatedMods():contains("96lancerEVO") then
	VVR.Data.Add("Base.ModernCar", "Base.96lancerEVO", nil, 12, "96lancerEVO")
	VVR.Data.Add("Base.ModernCar", "Base.96lancerEVOlhd", nil, 23, "96lancerEVO")
	VVR.Data.Add("Base.SportsCar", "Base.96lancerEVO", nil, 12, "96lancerEVO")
	VVR.Data.Add("Base.SportsCar", "Base.96lancerEVOlhd", nil, 23, "96lancerEVO")
end

if getActivatedMods():contains("98stagea") then
	VVR.Data.Add("Base.CarStationWagon", "Base.98stagea260RS", nil, 7, "98stagea")
	VVR.Data.Add("Base.CarStationWagon", "Base.98stagea260RSlhd", nil, 18, "98stagea")
	VVR.Data.Add("Base.ModernCar", "Base.98stagea260RS", nil, 10, "98stagea")
	VVR.Data.Add("Base.ModernCar", "Base.98stagea260RSlhd", nil, 20, "98stagea")
end

if getActivatedMods():contains("99fordCVPI") then

	VVR.Data.Add("Base.CarLightsPolice", "Base.99fordCVPI", nil, 35, "99fordCVPI")
	VVR.Data.Add("Base.CarLightsPolice", "Base.99fordCVPIunmarked", nil, 1, "99fordCVPI")
end

if getActivatedMods():contains("04vwTouran") then
	VVR.Data.Add("Base.CarNormal", "Base.04vwTouran", nil, 30, "04vwTouran")
	VVR.Data.Add("Base.ModernCar", "Base.04vwTouran", nil, 30, "04vwTouran")
end

if getActivatedMods():contains("KI5trailers") then
	VVR.Data.Add("Base.Trailer", "Base.TrailerKI5utilitySmall", nil, 60, "KI5trailer")
	VVR.Data.Add("Base.Trailer", "Base.TrailerKI5utilityMedium", nil, 30, "KI5trailer")
	VVR.Data.Add("Base.Trailer", "Base.TrailerKI5utilityLarge", nil, 10, "KI5trailer")
	
	VVR.Data.Add("Base.TrailerCover", "Base.TrailerKI5cargoSmall", nil, 60, "KI5trailer")
	VVR.Data.Add("Base.TrailerCover", "Base.TrailerKI5cargoMedium", nil, 30, "KI5trailer")
	VVR.Data.Add("Base.TrailerCover", "Base.TrailerKI5cargoLarge", nil, 10, "KI5trailer")
end

VVR.Data.RecalcChances()