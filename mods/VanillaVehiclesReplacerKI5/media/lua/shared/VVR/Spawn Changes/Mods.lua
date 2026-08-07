require "VVR/Utils"

if not VehicleZoneDistribution then return end

VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}

VehicleZoneDistribution.farm = VehicleZoneDistribution.farm or {}
VehicleZoneDistribution.farm.vehicles = VehicleZoneDistribution.farm.vehicles or {}

VehicleZoneDistribution.trades = VehicleZoneDistribution.trades or {}
VehicleZoneDistribution.trades.vehicles = VehicleZoneDistribution.trades.vehicles or {}

if getActivatedMods():contains("STowTruck_B42") then
	require "TowTruckZoneDef"
	
	VVR.Utils.NilSpawnZones("Base.Chevalier_Rhino_TowTruck")
end

if SandboxVars.VVR.Professional then
	if getActivatedMods():contains("86fordE150expanded") then
		require "86fordE150expandedSpawnList"
		
		VVR.Utils.NilSpawnZones("Base.86fordE150postal")
		VVR.Utils.NilSpawnZones("Base.86fordE150LBMWradio")
		VVR.Utils.NilSpawnZones("Base.86fordE150fossoil")
		VVR.Utils.NilSpawnZones("Base.86fordE150massGenfac")
		VVR.Utils.NilSpawnZones("Base.86fordE150kyTransit")
		VVR.Utils.NilSpawnZones("Base.86fordE150lectromax")
		VVR.Utils.NilSpawnZones("Base.86fordE150knoxDistilery")
	end
end

if getActivatedMods():contains("49powerWagon") then
	require "49powerWagonSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.49powerWagon")
	VVR.Utils.NilSpawnZones("Base.49powerWagonPA")
	VVR.Utils.NilSpawnZones("Base.49powerWagonPD")
	
	
	VehicleZoneDistribution.farm.vehicles["Base.49powerWagon"] = {index = -1, spawnChance = 15}
	VehicleZoneDistribution.military.vehicles["Base.49powerWagonMP"] = {index = -1, spawnChance = 5}
end

if getActivatedMods():contains("59meteor") then
	require "59meteorSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.59meteor")
	VVR.Utils.NilSpawnZones("Base.59ambulance")
end

if getActivatedMods():contains("63beetle") then
	require "63beetleSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.63beetle")
	VVR.Utils.NilSpawnZones("Base.63beetleHP")
	VVR.Utils.NilSpawnZones("Base.63beetleBuggy")
end

if getActivatedMods():contains("63Type2Van") then
	require "63Type2Van_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.63Type2Van")
	VVR.Utils.NilSpawnZones("Base.63Type2VanHippie")
	VVR.Utils.NilSpawnZones("Base.63Type2VanApocalypse")
	
	VehicleZoneDistribution.military.vehicles["Base.63Type2VanMilitary"] = {index = -1, spawnChance = 3}
end

if getActivatedMods():contains("65banshee") then
	require "65banshee_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.65banshee400")
	VVR.Utils.NilSpawnZones("Base.65bansheeSprint")
	VVR.Utils.NilSpawnZones("Base.65bansheeXP")
end

if getActivatedMods():contains("66pontiacLeMans") then
	require "66pontiacLeMans_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.66pontiacLeMans")
	VVR.Utils.NilSpawnZones("Base.66pontiacLeMansConv")
	VVR.Utils.NilSpawnZones("Base.66pontiacGTO")
	VVR.Utils.NilSpawnZones("Base.66pontiacGTOconv")
end
	
if getActivatedMods():contains("67commando") then	
	require "67commandoSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.67commandoPolice")
	
	VehicleZoneDistribution.junkyard.vehicles["Base.67commandoBurnt"] = {index = -1, spawnChance = 1}
	VehicleZoneDistribution.trafficjams.vehicles["Base.67commandoBurnt"] = {index = -1, spawnChance = 1}
	VehicleZoneDistribution.military.vehicles["Base.67commandoBurnt"] = {index = -1, spawnChance = 5}
end

if getActivatedMods():contains("67gt500") then
	require "67gt500SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.67gt500")
	VVR.Utils.NilSpawnZones("Base.67gt500e")
end

if getActivatedMods():contains("68firebird") then
	require "68firebird_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.68firebird350")
	VVR.Utils.NilSpawnZones("Base.68firebird400")
	VVR.Utils.NilSpawnZones("Base.68firebirdRamAir")
	VVR.Utils.NilSpawnZones("Base.68firebirdRamAirCustom")
end

if getActivatedMods():contains("69camaro") then
	require "69camaroSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.69camaroRS")
	VVR.Utils.NilSpawnZones("Base.69camaroSS")
end

if getActivatedMods():contains("69charger") then
	require "69charger_SpawnList"

	VVR.Utils.NilSpawnZones("Base.69chargerRT", true)
	VVR.Utils.NilSpawnZones("Base.69charger500", true)
	VVR.Utils.NilSpawnZones("Base.69chargerDaytona", true)
end

if getActivatedMods():contains("69charger") then
	require "69charger_SpawnList"

	VVR.Utils.NilSpawnZones("Base.69chargerRT", true)
	VVR.Utils.NilSpawnZones("Base.69charger500", true)
	VVR.Utils.NilSpawnZones("Base.69chargerDaytona", true)
end

if getActivatedMods():contains("69mini") then
	require "69mini_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.69mini")
	if getActivatedMods():contains("69mini_ItalianJob") then
		VVR.Utils.NilSpawnZones("Base.69miniIJ")
	end
end

if getActivatedMods():contains("70dodge") then
	require "70dodgeSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.70dodgeBG")
	VVR.Utils.NilSpawnZones("Base.70dodgeOP")
	VVR.Utils.NilSpawnZones("Base.70dodgePD")
	VVR.Utils.NilSpawnZones("Base.70dodgeRT")
	VVR.Utils.NilSpawnZones("Base.70dodgeTA")
end
	
if getActivatedMods():contains("70barracuda") then
	require "70barracudaSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.70barracuda")
	VVR.Utils.NilSpawnZones("Base.70cuda")
	VVR.Utils.NilSpawnZones("Base.70barracudaAAR")
end

if getActivatedMods():contains("70roadRunner") then
	require "70roadRunner_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.70roadRunner", true)
end

if getActivatedMods():contains("73fordFalcon") then
	require "73fordFalconXBGT_SpawnList"
	require "73fordFalconXBGTlhd_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.73fordFalconXBGT")
	VVR.Utils.NilSpawnZones("Base.73fordFalconXBGTlhd")
end

if getActivatedMods():contains("75grandPrix") then
	require "75grandPrix_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.75grandPrixHurst")
	VVR.Utils.NilSpawnZones("Base.75grandPrixLJ")
	VVR.Utils.NilSpawnZones("Base.75grandPrixSJ")
end

if getActivatedMods():contains("76chevyKseries") then
	require "76chevyKseries_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.76chevyK10")
	VVR.Utils.NilSpawnZones("Base.76chevyK20")
	VVR.Utils.NilSpawnZones("Base.76chevyK20BigRed")
	VVR.Utils.NilSpawnZones("Base.76chevyK30SCdually")
	VVR.Utils.NilSpawnZones("Base.76chevyK30CC")
	VVR.Utils.NilSpawnZones("Base.76chevyK20utility")
	VVR.Utils.NilSpawnZones("Base.76chevyK30CCutility")
	VVR.Utils.NilSpawnZones("Base.76chevyK10fd")
	VVR.Utils.NilSpawnZones("Base.76chevyK20fd")
	VVR.Utils.NilSpawnZones("Base.76chevyK30CCfd")
end

if getActivatedMods():contains("77firebird") then
	require "77firebird_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.77firebird")
	VVR.Utils.NilSpawnZones("Base.77firebirdES")
	VVR.Utils.NilSpawnZones("Base.77firebirdFR")
	VVR.Utils.NilSpawnZones("Base.77firebirdTA")
end

if getActivatedMods():contains("81deloreanDMC12") then
	require "81deloreanDMC12_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.81deloreanDMC12")
end

if getActivatedMods():contains("82jeepJ10") then
	require "82jeepJ10SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.82jeepJ10")
	VVR.Utils.NilSpawnZones("Base.82jeepJ10pd")
	VVR.Utils.NilSpawnZones("Base.82jeepJ10ranger")
end

if getActivatedMods():contains("82firebird") then
	require "82firebird_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.82firebird")
	VVR.Utils.NilSpawnZones("Base.82firebirdSE")
	VVR.Utils.NilSpawnZones("Base.82firebirdTA")
end

if getActivatedMods():contains("82porsche911") then
	require "82porsche911SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.82porsche911turbo")
	VVR.Utils.NilSpawnZones("Base.82porsche911rwb")
end

if getActivatedMods():contains("84buickElectra") then
	require "84buickElectra_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.84buickElectraSedan")
	VVR.Utils.NilSpawnZones("Base.84buickElectraCoupe")
end

if getActivatedMods():contains("84cadillacDeVille") then
	require "84cadillacDeVille_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.84cadillacDeVilleSedan")
	VVR.Utils.NilSpawnZones("Base.84cadillacDeVilleCoupe")
end

if getActivatedMods():contains("84jeepXJ") then
	require "84jeepXJ_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.84jeepXJ2")
	VVR.Utils.NilSpawnZones("Base.84jeepXJ4")
	VVR.Utils.NilSpawnZones("Base.84jeepXJksp")
	VVR.Utils.NilSpawnZones("Base.84jeepXJpd")
	VVR.Utils.NilSpawnZones("Base.84jeepXJranger")
end

if getActivatedMods():contains("84merc") then
	require "84mercSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.84mercLWB4")
	VVR.Utils.NilSpawnZones("Base.84mercLWB2")
	VVR.Utils.NilSpawnZones("Base.84mercSWB")
	
	VehicleZoneDistribution.military.vehicles["Base.84mercLWB4M"] = {index = -1, spawnChance = 10}
end

if getActivatedMods():contains("84oldsmobile98") then
	require "84oldsmobile98_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.84oldsmobile98Sedan")
	VVR.Utils.NilSpawnZones("Base.84oldsmobile98Coupe")
end

if getActivatedMods():contains("85buickLeSabre") then
	require "85buickLeSabre_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.85buickLeSabreSedan")
	VVR.Utils.NilSpawnZones("Base.85buickLeSabreCoupe")
	VVR.Utils.NilSpawnZones("Base.85buickLeSabreWagon")
	VVR.Utils.NilSpawnZones("Base.85buickLeSabreWagon2")
end

if getActivatedMods():contains("85chevyCaprice") then
	require "85chevyCaprice_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.85chevyCapriceSedan")
	VVR.Utils.NilSpawnZones("Base.85chevyCapriceCoupe")
	VVR.Utils.NilSpawnZones("Base.85chevyCapriceWagon")
	VVR.Utils.NilSpawnZones("Base.85chevyCapriceWagon2")
	VVR.Utils.NilSpawnZones("Base.85chevyImpalaSedanPD")
	VVR.Utils.NilSpawnZones("Base.85chevyImpalaSedanPDu")
	VVR.Utils.NilSpawnZones("Base.85chevyImpalaSedanKSP")
	VVR.Utils.NilSpawnZones("Base.85chevyImpalaSedanTaxi")
	VVR.Utils.NilSpawnZones("Base.85chevyImpalaSedanFD")
	VVR.Utils.NilSpawnZones("Base.85chevyImpalaSedanRanger")
	VVR.Utils.NilSpawnZones("Base.85chevyImpalaSedanAirport")
end

if getActivatedMods():contains("85chevyStepVan") then
	require "85chevyStepVan_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.85chevyStepVan")
end

if getActivatedMods():contains("85chevyStepVanexpanded") then
	require "85chevyStepVanExpanded_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanPostal")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanUsLogistics")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanHerald")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanScarletOak")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanGenuine")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanButchers")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanLibrary")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanFlorist")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanTimelessGlass")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanPropane")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanLvMotorshop")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanMasonry")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanJorgensen")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanSePaintingServices")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanBlacksmith")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanMrHuangsLaundry")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanRandys")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanMarineBites")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanDelirosPlonkies")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanSmartCut")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanSunBallz")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanTheCompleteRepair")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanLvAirportCatering")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanCitrusWave")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanZippeeMarket")
	VVR.Utils.NilSpawnZones("Base.85chevyStepVanSeHospitality")
end

if getActivatedMods():contains("85oldsmobileDelta88") then
	require "85oldsmobileDelta88_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.85oldsmobileDelta88Sedan")
	VVR.Utils.NilSpawnZones("Base.85oldsmobileDelta88Coupe")
	VVR.Utils.NilSpawnZones("Base.85oldsmobileDelta88Wagon")
	VVR.Utils.NilSpawnZones("Base.85oldsmobileDelta88Wagon2")
end

if getActivatedMods():contains("85pontiacParisienne") then
	require "85pontiacParisienne_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.85pontiacParisienneSedan")
	VVR.Utils.NilSpawnZones("Base.85pontiacParisienneWagon")
	VVR.Utils.NilSpawnZones("Base.85pontiacParisienneWagon2")
end

if getActivatedMods():contains("86chevyCUCV") then
	require "86chevyCUCV_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.86chevyK5blazer")
	VVR.Utils.NilSpawnZones("Base.86chevyK5pd")
	VVR.Utils.NilSpawnZones("Base.86chevyK5ksp")
end

if getActivatedMods():contains("86fordE150") then
	require "86fordE150SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.86fordE150")
	VVR.Utils.NilSpawnZones("Base.86fordE150slide")
	VVR.Utils.NilSpawnZones("Base.86fordE150long")
	VVR.Utils.NilSpawnZones("Base.86fordE150longW")
	VVR.Utils.NilSpawnZones("Base.86fordE150slideSpiffo")
	VVR.Utils.NilSpawnZones("Base.86fordE150ksp")
	VVR.Utils.NilSpawnZones("Base.86fordE150so")
end

if getActivatedMods():contains("86oshkoshP19A") then
	require "86oshkoshP19AspawnList"
	
	VVR.Utils.NilSpawnZones("Base.86oshkoshKYFD")
end

if getActivatedMods():contains("87buickRegal") then
	require "87buickRegal_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.87buickRegalGNX")
	VVR.Utils.NilSpawnZones("Base.87buickRegalTurboT")
	VVR.Utils.NilSpawnZones("Base.87buickRegalTurboTfbi")
end

if getActivatedMods():contains("87chevySuburban") then
	require "87chevySuburban_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.87chevySuburban")
	VVR.Utils.NilSpawnZones("Base.87chevySuburbanOP")
end

if getActivatedMods():contains("87fordB700") then
	require "87fordB700_spawnList"
	
	VVR.Utils.NilSpawnZones("Base.87fordB700prison")
	VVR.Utils.NilSpawnZones("Base.87fordF700swat")
	VVR.Utils.NilSpawnZones("Base.87fordB700school")
	
	VehicleZoneDistribution.junkyard.vehicles["Base.87fordB700school"] = { index = -1, spawnChance = 3 }
	VehicleZoneDistribution.trafficjams.vehicles["Base.87fordB700school"] = { index = -1, spawnChance = 3 }
	VehicleZoneDistribution.trades.vehicles["Base.87fordF700box"] = { index = -1, spawnChance = 20 }
	VehicleZoneDistribution.military.vehicles["Base.87fordB700military"] = { index = -1, spawnChance = 3 }
end

if getActivatedMods():contains("87toyotaMR2") then
	require "87toyotaMR2_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.87toyotaMR2")
	VVR.Utils.NilSpawnZones("Base.87toyotaMR2c")
end

if getActivatedMods():contains("88chevyS10") then
	require "88chevyS10SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.88chevyS10")
end

if getActivatedMods():contains("88toyotaHilux") then
	require "88toyotaHilux_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.88toyotaHiluxSC")
	VVR.Utils.NilSpawnZones("Base.88toyotaHiluxXC")
	VVR.Utils.NilSpawnZones("Base.88toyotaHiluxXCS")
end

if getActivatedMods():contains("89fordBronco") then
	require "89fordBroncoSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.89fordBronco")
	VVR.Utils.NilSpawnZones("Base.89fordBroncoPD")
	VVR.Utils.NilSpawnZones("Base.89fordBroncoRanger")
end

if getActivatedMods():contains("89dodgeCaravan") then
	require "89dodgeCaravanSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.89dodgeCaravan")
	VVR.Utils.NilSpawnZones("Base.89dodgeCaravanLE")
	VVR.Utils.NilSpawnZones("Base.89dodgeCaravanNomad")
	
	VehicleZoneDistribution.farm.vehicles["Base.89dodgeCaravanNomad"] = {index = -1, spawnChance = 10}
end

if getActivatedMods():contains("89trooper") then
	require "89trooper_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.89trooper")
	VVR.Utils.NilSpawnZones("Base.89trooperRS")
	VVR.Utils.NilSpawnZones("Base.89trooperOP")
end

if getActivatedMods():contains("89defender") then
	require "89defender_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.89defender90")
	VVR.Utils.NilSpawnZones("Base.89defender90utility")
	VVR.Utils.NilSpawnZones("Base.89defender110")
	VVR.Utils.NilSpawnZones("Base.89defender110utility")
	VVR.Utils.NilSpawnZones("Base.89defender130")
	
	VehicleZoneDistribution.military.vehicles["Base.89defenderWolf"] = {index = -1, spawnChance = 15}
end
	
if getActivatedMods():contains("89volvo200") then
	require "89volvo200_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.89volvo244sedan")
	VVR.Utils.NilSpawnZones("Base.89volvo245wagon")
	VVR.Utils.NilSpawnZones("Base.89volvo242turbo")
end

if getActivatedMods():contains("90bmwE30") then
	require "90bmwE30_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.90bmwE30sedan2")
	VVR.Utils.NilSpawnZones("Base.90bmwE30sedan4")
	VVR.Utils.NilSpawnZones("Base.90bmwE30touring")
	VVR.Utils.NilSpawnZones("Base.90bmwE30cabrio")
	VVR.Utils.NilSpawnZones("Base.90bmwE30m3")
end

if getActivatedMods():contains("90fordF350ambulance") then
	require "90fordF350ambulance_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.90fordF350ambulance")
	VVR.Utils.NilSpawnZones("Base.90fordF350SWAT")
end

if getActivatedMods():contains("90pierceArrow") then
	require "90pierceArrowspawnList"
	
	VVR.Utils.NilSpawnZones("Base.90pierceArrow")
end

if getActivatedMods():contains("91fordLTD") then
	require "91fordLTD_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.91fordLTD")
	VVR.Utils.NilSpawnZones("Base.91fordLTDwagon")
	VVR.Utils.NilSpawnZones("Base.91fordLTDunmarked")
	VVR.Utils.NilSpawnZones("Base.91fordLTDtaxi")
	VVR.Utils.NilSpawnZones("Base.91fordLTDksp")
	VVR.Utils.NilSpawnZones("Base.91fordLTDksp2")
	VVR.Utils.NilSpawnZones("Base.91fordLTDpd")
	VVR.Utils.NilSpawnZones("Base.91fordLTDranger")
end

if getActivatedMods():contains("91fordRanger") then
	require "91fordRanger_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.91fordRangerSC")
	VVR.Utils.NilSpawnZones("Base.91fordRangerSClong")
	VVR.Utils.NilSpawnZones("Base.91fordRangerXC")
	VVR.Utils.NilSpawnZones("Base.91fordRangerXClong")
	VVR.Utils.NilSpawnZones("Base.91fordRangerPD")
	VVR.Utils.NilSpawnZones("Base.91fordRangerRanger")
end

if getActivatedMods():contains("91geoMetro") then
	require "91geoMetro_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.91geoMetro")
end

if getActivatedMods():contains("91nissan240sx") then
	require "91nissan240sx_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.91nissan240sx")
	VVR.Utils.NilSpawnZones("Base.91nissan240sx2")
end

if getActivatedMods():contains("91range") then
	require "91range_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.91range")
	VVR.Utils.NilSpawnZones("Base.91range2")
end

if getActivatedMods():contains("92amgeneralM998") then
	require "92amgeneralM998SpawnList"
	
	VehicleZoneDistribution.junkyard.vehicles["Base.92amgeneralM998Burnt"] = {index = -1, spawnChance = 1}
	VehicleZoneDistribution.trafficjams.vehicles["Base.92amgeneralM998Burnt"] = {index = -1, spawnChance = 1}
end

if getActivatedMods():contains("92fordCVPI") then
	require "92fordCVPI_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.92fordCV")
	VVR.Utils.NilSpawnZones("Base.92fordCVPIunmarked")
	VVR.Utils.NilSpawnZones("Base.92fordCVPItaxi")
	VVR.Utils.NilSpawnZones("Base.92fordCVPI")
	VVR.Utils.NilSpawnZones("Base.92fordCVPIpdu")
	VVR.Utils.NilSpawnZones("Base.92fordCVPI2ksp")
	VVR.Utils.NilSpawnZones("Base.92fordCVPI2kspst")
	VVR.Utils.NilSpawnZones("Base.92fordCVPI2")
	VVR.Utils.NilSpawnZones("Base.92fordCVPI2sup")
	VVR.Utils.NilSpawnZones("Base.92fordCVPI2so")
	VVR.Utils.NilSpawnZones("Base.92fordCVPIfd")
end

if getActivatedMods():contains("92jeepYJ") then
	require "92jeepYJ_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.92jeepYJs")
	VVR.Utils.NilSpawnZones("Base.92jeepYJse")
	VVR.Utils.NilSpawnZones("Base.92jeepYJranger")
end

if getActivatedMods():contains("92jeepYJJP18") then
	require "92jeepYJJP18_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.92jeepYJjp")
end
	
if getActivatedMods():contains("92nissanGTR") then
	require "92nissanGTRSpawnList"
	
	VVR.Utils.NilSpawnZones("Base.92nissanGTR")
	VVR.Utils.NilSpawnZones("Base.92nissanGTRlhd")
end

if getActivatedMods():contains("93chevySuburban") then
	require "93chevySuburban_SpawnList"
	require "93chevySilverado_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoCC")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoCClong")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoCCdually")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoSC")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoSClong")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoSCdually")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoXC")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoXClong")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoXCdually")
	VVR.Utils.NilSpawnZones("Base.93chevySuburban")
	VVR.Utils.NilSpawnZones("Base.93chevySuburbanDually")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoK3500wrecker")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoK3500flatbed")
	VVR.Utils.NilSpawnZones("Base.93chevySuburbanfbi")
	VVR.Utils.NilSpawnZones("Base.93chevySuburbanfd")
	VVR.Utils.NilSpawnZones("Base.93chevySuburbanpd")
	VVR.Utils.NilSpawnZones("Base.93chevySuburbanksp")
	VVR.Utils.NilSpawnZones("Base.93chevySuburbanpdu")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoCClongfd")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoXClongRanger")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoSClongFossoil")
	VVR.Utils.NilSpawnZones("Base.93chevySilveradoXClongMcCoy")
end

if getActivatedMods():contains("93fordElgin") then
	require "93fordElgin_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.93fordElgin")
end

if getActivatedMods():contains("93fordF350") then
	require "93fordF350_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.93fordF150")
	VVR.Utils.NilSpawnZones("Base.93fordF150S")
	VVR.Utils.NilSpawnZones("Base.93fordF250")
	VVR.Utils.NilSpawnZones("Base.93fordF350")
	VVR.Utils.NilSpawnZones("Base.93fordF350dually")
	VVR.Utils.NilSpawnZones("Base.93fordF350utilityDpw")
	VVR.Utils.NilSpawnZones("Base.93fordF350utilityFd")
	VVR.Utils.NilSpawnZones("Base.93fordF350fd")
	VVR.Utils.NilSpawnZones("Base.93fordF350pd")
	VVR.Utils.NilSpawnZones("Base.93fordF350so")
	VVR.Utils.NilSpawnZones("Base.93fordF350utility")
end

if getActivatedMods():contains("93mustangSSP") then
	require "93mustangSSP_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.93mustangSSP")
	VVR.Utils.NilSpawnZones("Base.93mustangSSPksp")
	VVR.Utils.NilSpawnZones("Base.93mustangSSPunmarked")
	VVR.Utils.NilSpawnZones("Base.93mustangSSPkspCol")
end

if getActivatedMods():contains("93fordTaurus") then
	require "93fordTaurus_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.93fordTaurus")
	VVR.Utils.NilSpawnZones("Base.93fordTaurusSHO")
	VVR.Utils.NilSpawnZones("Base.93fordTaurusWagon")
end

if getActivatedMods():contains("93townCar") then
	require "93townCar_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.93townCar")
	VVR.Utils.NilSpawnZones("Base.93townCarLimo")
	
	VehicleZoneDistribution.parkingstall.vehicles["Base.93townCarLimo"] = {index = -1, spawnChance = 0.5}
	VehicleZoneDistribution.good.vehicles["Base.93townCarLimo"] = {index = -1, spawnChance = 1}
	VehicleZoneDistribution.trafficjams.vehicles["Base.93townCarLimo"] = {index = -1, spawnChance = 0.5}
end

if getActivatedMods():contains("95impreza") then
	require "95impreza_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.95impreza")
	VVR.Utils.NilSpawnZones("Base.95imprezalhd")
end

if getActivatedMods():contains("96lancerEVO") then
	require "96lancerEVO_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.96lancerEVO")
	VVR.Utils.NilSpawnZones("Base.96lancerEVOlhd")
end

if getActivatedMods():contains("98stagea") then
	require "98stagea_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.98stagea260RS")
	VVR.Utils.NilSpawnZones("Base.98stagea260RSlhd")
end

if getActivatedMods():contains("99fordCVPI") then
	require "99fordCVPI_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.99fordCVPI")
	VVR.Utils.NilSpawnZones("Base.99fordCVPIunmarked")
end

if getActivatedMods():contains("04vwTouran") then
	require "04vwTouran_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.04vwTouran")
end

if getActivatedMods():contains("isoContainers") then
	require "isoContainers_SpawnList"
	
	VVR.Utils.NilSpawnZones("Base.isoContainer2")
	VVR.Utils.NilSpawnZones("Base.isoContainer3tanker")
	
	VehicleZoneDistribution.mccoy.vehicles["Base.isoContainer2"] = {index = 4, spawnChance = 30}
	VehicleZoneDistribution.fossoil.vehicles["Base.isoContainer3tanker"] = {index = 2, spawnChance = 25}
	VehicleZoneDistribution.lectromax.vehicles["Base.isoContainer2"] = {index = -1, spawnChance = 10}
	VehicleZoneDistribution.massgenfac.vehicles["Base.isoContainer2"] = {index = -1, spawnChance = 10}
	VehicleZoneDistribution.transit.vehicles["Base.isoContainer2"] = {index = -1, spawnChance = 10}
	VehicleZoneDistribution.junkyard.vehicles["Base.isoContainer5"] = {index = -1, spawnChance = 10}
	VehicleZoneDistribution.farm.vehicles["Base.isoContainer5"] = {index = -1, spawnChance = 7}
	VehicleZoneDistribution.farm.vehicles["Base.isoContainer3tanker"] = {index = -1, spawnChance = 5}
	VehicleZoneDistribution.military.vehicles["Base.isoContainer4"] = {index = -1, spawnChance = 15}
	VehicleZoneDistribution.military.vehicles["Base.isoContainer3tanker"] = {index = -1, spawnChance = 15}
end

if getActivatedMods():contains("KI5trailers") then
	require "KI5trailers_SpawnList"
	
	VehicleZoneDistribution.parkingstall.vehicles["Base.TrailerKI5livestock"] = nil
	VehicleZoneDistribution.transit.vehicles["Base.TrailerKI5utilityLarge"] = {index = -1, spawnChance = 4}
	VehicleZoneDistribution.transit.vehicles["Base.TrailerKI5utilityMedium"] = {index = -1, spawnChance = 7}
	VehicleZoneDistribution.transit.vehicles["Base.TrailerKI5utilitySmall"] = {index = -1, spawnChance = 10}
	VehicleZoneDistribution.transit.vehicles["Base.TrailerKI5cargoLarge"] = {index = -1, spawnChance = 1}
	VehicleZoneDistribution.transit.vehicles["Base.TrailerKI5cargoMedium"] = {index = -1, spawnChance = 2}
	VehicleZoneDistribution.transit.vehicles["Base.TrailerKI5cargoSmall"] = {index = -1, spawnChance = 3}
end