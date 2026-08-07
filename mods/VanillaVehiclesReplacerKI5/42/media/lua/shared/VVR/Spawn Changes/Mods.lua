local VZDUtils = require("YAPZLib/VehicleZoneDistribution")

if not VehicleZoneDistribution then return end

VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}

local professionalVehicles = {
	["Base.85chevyStepVanPostal"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanUsLogistics"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanHerald"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanScarletOak"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanGenuine"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanButchers"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanLibrary"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanFlorist"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanTimelessGlass"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanPropane"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanLvMotorshop"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanMasonry"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanJorgensen"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanSePaintingServices"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanBlacksmith"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanMrHuangsLaundry"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanRandys"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanMarineBites"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanDelirosPlonkies"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanSmartCut"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanSunBallz"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanTheCompleteRepair"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanLvAirportCatering"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanCitrusWave"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanZippeeMarket"] = "85chevyStepVanExpanded_SpawnList",
	["Base.85chevyStepVanSeHospitality"] = "85chevyStepVanExpanded_SpawnList",
	
	["Base.86fordE150LVairportShuttle"] = "86fordE150expandedSpawnList",
	["Base.86fordE150postal"] = "86fordE150expandedSpawnList",
	["Base.86fordE150LBMWradio"] = "86fordE150expandedSpawnList",
	["Base.86fordE150fossoil"] = "86fordE150expandedSpawnList",
	["Base.86fordE150massGenfac"] = "86fordE150expandedSpawnList",
	["Base.86fordE150kyTransit"] = "86fordE150expandedSpawnList",
	["Base.86fordE150lectromax"] = "86fordE150expandedSpawnList",
	["Base.86fordE150knoxDistilery"] = "86fordE150expandedSpawnList",
	["Base.86fordE150ccconstruction"] = "86fordE150expandedSpawnList",
	["Base.86fordE150beckmansBuilding"] = "86fordE150expandedSpawnList",
	["Base.86fordE150kerrHomes"] = "86fordE150expandedSpawnList",
	["Base.86fordE150rosewoodWorking"] = "86fordE150expandedSpawnList",
	["Base.86fordE150lvLandscaping"] = "86fordE150expandedSpawnList",
	["Base.86fordE150treyBaines"] = "86fordE150expandedSpawnList",
	["Base.86fordE150mobileMechanics"] = "86fordE150expandedSpawnList",
	["Base.86fordE150brewster"] = "86fordE150expandedSpawnList",
	["Base.86fordE150mooresMechanics"] = "86fordE150expandedSpawnList",
	["Base.86fordE150plattAutoRepair"] = "86fordE150expandedSpawnList",
	["Base.86fordE150meltingPointMetal"] = "86fordE150expandedSpawnList",
	["Base.86fordE150jones"] = "86fordE150expandedSpawnList",
	["Base.86fordE150riversideFab"] = "86fordE150expandedSpawnList",
	["Base.86fordE150schwab"] = "86fordE150expandedSpawnList",
	["Base.86fordE150deerValley"] = "86fordE150expandedSpawnList",
	["Base.86fordE150knobCreek"] = "86fordE150expandedSpawnList",
	["Base.86fordE150knoxTelecom"] = "86fordE150expandedSpawnList",
	["Base.86fordE150oldMillWaterCompany"] = "86fordE150expandedSpawnList",
	["Base.86fordE150locksmith"] = "86fordE150expandedSpawnList",
	["Base.86fordE150pluggedInElectrics"] = "86fordE150expandedSpawnList",
	["Base.86fordE150voltMojo"] = "86fordE150expandedSpawnList",
	["Base.86fordE150blacksmith"] = "86fordE150expandedSpawnList",
	["Base.86fordE150zenith"] = "86fordE150expandedSpawnList",
	["Base.86fordE150greenes"] = "86fordE150expandedSpawnList",
	["Base.86fordE150oVoFarms"] = "86fordE150expandedSpawnList",
	["Base.86fordE150perfick"] = "86fordE150expandedSpawnList",
	["Base.86fordE150heritageTailors"] = "86fordE150expandedSpawnList",
	["Base.86fordE150tasteTheBrew"] = "86fordE150expandedSpawnList",
	["Base.86fordE150stoneworksMasonry"] = "86fordE150expandedSpawnList",
	["Base.86fordE150leatherwork"] = "86fordE150expandedSpawnList",
	["Base.86fordE150uncloggers"] = "86fordE150expandedSpawnList",
	["Base.86fordE150bugWipers"] = "86fordE150expandedSpawnList",
	["Base.86fordE150brushAndClay"] = "86fordE150expandedSpawnList",
	
	["Base.93chevySilveradoVoltMojo"] = "93chevySuburbanExpanded_SpawnList",
	["Base.93chevySilveradoStoneworksMasonry"] = "93chevySuburbanExpanded_SpawnList",
	["Base.93chevySilveradoUncloggers"] = "93chevySuburbanExpanded_SpawnList",
}

VZDUtils.clearSpawnZones(professionalVehicles, true)

VZDUtils.addToSpawnZone("Base.93chevySuburbanAirportSec", "airportservice", nil, 15)
VZDUtils.addToSpawnZone("Base.93chevySilveradoAirport", "airportservice", nil, 20)
VZDUtils.addToSpawnZone("Base.93chevySuburbanPrison", "prison", nil, 50)

local vehicles = {
	["Base.Chevalier_Rhino_TowTruck"] = "TowTruckZoneDef",

	["Base.49powerWagon"] = "49powerWagonSpawnList",
	["Base.49powerWagonPA"] = "49powerWagonSpawnList",
	["Base.49powerWagonPD"] = "49powerWagonSpawnList",

	["Base.59meteor"] = "59meteorSpawnList",
	["Base.59ambulance"] = "59meteorSpawnList",

	["Base.63beetle"] = "63beetleSpawnList",
	["Base.63beetleHP"] = "63beetleSpawnList",
	["Base.63beetleBuggy"] = "63beetleSpawnList",

	["Base.63Type2Van"] = "63Type2Van_SpawnList",
	["Base.63Type2VanHippie"] = "63Type2Van_SpawnList",
	["Base.63Type2VanApocalypse"] = "63Type2Van_SpawnList",

	["Base.65banshee400"] = "65banshee_SpawnList",
	["Base.65bansheeSprint"] = "65banshee_SpawnList",
	["Base.65bansheeXP"] = "65banshee_SpawnList",

	["Base.66pontiacLeMans"] = "66pontiacLeMans_SpawnList",
	["Base.66pontiacLeMansConv"] = "66pontiacLeMans_SpawnList",
	["Base.66pontiacGTO"] = "66pontiacLeMans_SpawnList",
	["Base.66pontiacGTOconv"] = "66pontiacLeMans_SpawnList",

	["Base.67commandoPolice"] = "67commandoSpawnList",

	["Base.67gt500"] = "67gt500SpawnList",
	["Base.67gt500e"] = "67gt500SpawnList",

	["Base.68firebird350"] = "68firebird_SpawnList",
	["Base.68firebird400"] = "68firebird_SpawnList",
	["Base.68firebirdRamAir"] = "68firebird_SpawnList",
	["Base.68firebirdRamAirCustom"] = "68firebird_SpawnList",

	["Base.69camaroRS"] = "69camaroSpawnList",
	["Base.69camaroSS"] = "69camaroSpawnList",

	["Base.69chargerRT"] = "69charger_SpawnList",
	["Base.69charger500"] = "69charger_SpawnList",
	["Base.69chargerDaytona"] = "69charger_SpawnList",
	["Base.69chargerDemon"] = "69charger_SpawnList",
	
	["Base.69fordMustangEV6"] = "69fordMustang_SpawnList",
	["Base.69fordMustangTBC"] = "69fordMustang_SpawnList",
	["Base.69fordMustangUBC"] = "69fordMustang_SpawnList",
	["Base.69fordMustangBoss302"] = "69fordMustang_SpawnList",
	["Base.69fordMustangBoss429"] = "69fordMustang_SpawnList",
	["Base.69fordMustangMach1"] = "69fordMustang_SpawnList",

	["Base.69mini"] = "69mini_SpawnList",
	["Base.69miniIJ"] = "69mini_SpawnList",
	
	["Base.70chevelleSedan"] = "70chevelle_SpawnList",
	["Base.70chevelleCoupe"] = "70chevelle_SpawnList",
	["Base.70chevelleCoupeSS"] = "70chevelle_SpawnList",
	["Base.70chevelleCoupeSSL6"] = "70chevelle_SpawnList",
	["Base.70chevelleWagon"] = "70chevelle_SpawnList",
	["Base.70chevelleWagonSS"] = "70chevelle_SpawnList",
	["Base.70elCamino"] = "70chevelle_SpawnList",
	["Base.70elCaminoSS"] = "70chevelle_SpawnList",

	["Base.70dodgeBG"] = "70dodgeSpawnList",
	["Base.70dodgeOP"] = "70dodgeSpawnList",
	["Base.70dodgePD"] = "70dodgeSpawnList",
	["Base.70dodgeRT"] = "70dodgeSpawnList",
	["Base.70dodgeTA"] = "70dodgeSpawnList",

	["Base.70fordEscortCoupe"] = "70fordEscort_SpawnList",
	["Base.70fordEscortRS"] = "70fordEscort_SpawnList",
	["Base.70fordEscortSedan"] = "70fordEscort_SpawnList",
	["Base.70fordEscortWagon"] = "70fordEscort_SpawnList",

	["Base.70barracuda"] = "70barracudaSpawnList",
	["Base.70cuda"] = "70barracudaSpawnList",
	["Base.70barracudaAAR"] = "70barracudaSpawnList",

	["Base.70roadRunner"] = "70roadRunner_SpawnList",

	["Base.73fordFalconXBGT"] = "73fordFalconXBGT_SpawnList",
	["Base.73fordFalconXBGTlhd"] = "73fordFalconXBGTlhd_SpawnList",
	
	["Base.73nissanGTR"] = "73nissanGTR_SpawnList",
	["Base.73nissanGTRlhd"] = "73nissanGTR_SpawnList",

	["Base.75grandPrixHurst"] = "75grandPrix_SpawnList",
	["Base.75grandPrixLJ"] = "75grandPrix_SpawnList",
	["Base.75grandPrixSJ"] = "75grandPrix_SpawnList",

	["Base.76chevyK10"] = "76chevyKseries_SpawnList",
	["Base.76chevyK20"] = "76chevyKseries_SpawnList",
	["Base.76chevyK20BigRed"] = "76chevyKseries_SpawnList",
	["Base.76chevyK30SCdually"] = "76chevyKseries_SpawnList",
	["Base.76chevyK30SCduallyS"] = "76chevyKseries_SpawnList",
	["Base.76chevyK30CC"] = "76chevyKseries_SpawnList",
	["Base.76chevyK20utility"] = "76chevyKseries_SpawnList",
	["Base.76chevyK30CCutility"] = "76chevyKseries_SpawnList",
	["Base.76chevyK10fd"] = "76chevyKseries_SpawnList",
	["Base.76chevyK20fd"] = "76chevyKseries_SpawnList",
	["Base.76chevyK30CCfd"] = "76chevyKseries_SpawnList",
	["Base.76chevySuburban"] = "76chevyKseries_SpawnList",
	["Base.76chevySuburban2"] = "76chevyKseries_SpawnList",

	["Base.76chryslerNewYorker"] = "76chryslerNewYorker_SpawnList",
	["Base.76chryslerNewYorkerTPB"] = "76chryslerNewYorker_SpawnList",
	
	["Base.77firebird"] = "77firebird_SpawnList",
	["Base.77firebirdES"] = "77firebird_SpawnList",
	["Base.77firebirdFR"] = "77firebird_SpawnList",
	["Base.77firebirdTA"] = "77firebird_SpawnList",

	["Base.79camaro"] = "79camaro_SpawnList",
	["Base.79camaroRS"] = "79camaro_SpawnList",
	["Base.79camaroZ28"] = "79camaro_SpawnList",
	["Base.79camaroGhost"] = "79camaro_SpawnList",

	["Base.81deloreanDMC12"] = "81deloreanDMC12_SpawnList",

	["Base.82jeepJ10"] = "82jeepJ10SpawnList",
	["Base.82jeepJ10pd"] = "82jeepJ10SpawnList",
	["Base.82jeepJ10ranger"] = "82jeepJ10SpawnList",

	["Base.82firebird"] = "82firebird_SpawnList",
	["Base.82firebirdSE"] = "82firebird_SpawnList",
	["Base.82firebirdTA"] = "82firebird_SpawnList",

	["Base.82porsche911turbo"] = "82porsche911SpawnList",
	["Base.82porsche911rwb"] = "82porsche911SpawnList",
	["Base.82porsche911sc"] = "82porsche911SpawnList",
	["Base.82porsche911targa"] = "82porsche911SpawnList",

	["Base.84buickElectraSedan"] = "84buickElectra_SpawnList",
	["Base.84buickElectraCoupe"] = "84buickElectra_SpawnList",

	["Base.84cadillacDeVilleSedan"] = "84cadillacDeVille_SpawnList",
	["Base.84cadillacDeVilleCoupe"] = "84cadillacDeVille_SpawnList",

	["Base.84jeepXJ2"] = "84jeepXJ_SpawnList",
	["Base.84jeepXJ4"] = "84jeepXJ_SpawnList",
	["Base.84jeepXJksp"] = "84jeepXJ_SpawnList",
	["Base.84jeepXJpd"] = "84jeepXJ_SpawnList",
	["Base.84jeepXJranger"] = "84jeepXJ_SpawnList",

	["Base.84mercLWB4"] = "84mercSpawnList",
	["Base.84mercLWB2"] = "84mercSpawnList",
	["Base.84mercSWB"] = "84mercSpawnList",

	["Base.84oldsmobile98Sedan"] = "84oldsmobile98_SpawnList",
	["Base.84oldsmobile98Coupe"] = "84oldsmobile98_SpawnList",

	["Base.85buickLeSabreSedan"] = "85buickLeSabre_SpawnList",
	["Base.85buickLeSabreCoupe"] = "85buickLeSabre_SpawnList",
	["Base.85buickLeSabreWagon"] = "85buickLeSabre_SpawnList",
	["Base.85buickLeSabreWagon2"] = "85buickLeSabre_SpawnList",

	["Base.85chevyCapriceSedan"] = "85chevyCaprice_SpawnList",
	["Base.85chevyCapriceCoupe"] = "85chevyCaprice_SpawnList",
	["Base.85chevyCapriceWagon"] = "85chevyCaprice_SpawnList",
	["Base.85chevyCapriceWagon2"] = "85chevyCaprice_SpawnList",
	["Base.85chevyImpalaSedanPD"] = "85chevyCaprice_SpawnList",
	["Base.85chevyImpalaSedanPDu"] = "85chevyCaprice_SpawnList",
	["Base.85chevyImpalaSedanKSP"] = "85chevyCaprice_SpawnList",
	["Base.85chevyImpalaSedanTaxi"] = "85chevyCaprice_SpawnList",
	["Base.85chevyImpalaSedanFD"] = "85chevyCaprice_SpawnList",
	["Base.85chevyImpalaSedanRanger"] = "85chevyCaprice_SpawnList",
	["Base.85chevyImpalaSedanAirport"] = "85chevyCaprice_SpawnList",

	["Base.85chevyStepVan"] = "85chevyStepVan_SpawnList",
	["Base.85chevyStepVanSWAT"] = "85chevyStepVan_SpawnList",

	["Base.85oldsmobileDelta88Sedan"] = "85oldsmobileDelta88_SpawnList",
	["Base.85oldsmobileDelta88Coupe"] = "85oldsmobileDelta88_SpawnList",
	["Base.85oldsmobileDelta88Wagon"] = "85oldsmobileDelta88_SpawnList",
	["Base.85oldsmobileDelta88Wagon2"] = "85oldsmobileDelta88_SpawnList",

	["Base.85pontiacParisienneSedan"] = "85pontiacParisienne_SpawnList",
	["Base.85pontiacParisienneWagon"] = "85pontiacParisienne_SpawnList",
	["Base.85pontiacParisienneWagon2"] = "85pontiacParisienne_SpawnList",

	["Base.86chevyK5blazer"] = "86chevyCUCV_SpawnList",
	["Base.86chevyK5pd"] = "86chevyCUCV_SpawnList",
	["Base.86chevyK5ksp"] = "86chevyCUCV_SpawnList",

	["Base.86fordE150"] = "86fordE150SpawnList",
	["Base.86fordE150slide"] = "86fordE150SpawnList",
	["Base.86fordE150long"] = "86fordE150SpawnList",
	["Base.86fordE150longW"] = "86fordE150SpawnList",
	["Base.86fordE150slideSpiffo"] = "86fordE150SpawnList",
	["Base.86fordE150mccoy"] = "86fordE150SpawnList",
	["Base.86fordE150ksp"] = "86fordE150SpawnList",
	["Base.86fordE150so"] = "86fordE150SpawnList",

	["Base.86oshkoshKYFD"] = "86oshkoshP19AspawnList",

	["Base.87buickRegalGNX"] = "87buickRegal_SpawnList",
	["Base.87buickRegalTurboT"] = "87buickRegal_SpawnList",
	["Base.87buickRegalTurboTfbi"] = "87buickRegal_SpawnList",

	["Base.87chevySuburban"] = "87chevySuburban_SpawnList",
	["Base.87chevySuburbanOP"] = "87chevySuburban_SpawnList",

	["Base.87fordF700box"] = "87fordB700_spawnList",
	["Base.87fordB700prison"] = "87fordB700_spawnList",
	["Base.87fordF700swat"] = "87fordB700_spawnList",
	["Base.87fordF700bank"] = "87fordB700_spawnList",
	["Base.87fordB700school"] = "87fordB700_spawnList",

	["Base.87toyotaMR2"] = "87toyotaMR2_SpawnList",
	["Base.87toyotaMR2c"] = "87toyotaMR2_SpawnList",

	["Base.88chevyS10"] = "88chevyS10SpawnList",

	["Base.88toyotaHiluxSC"] = "88toyotaHilux_SpawnList",
	["Base.88toyotaHiluxXC"] = "88toyotaHilux_SpawnList",
	["Base.88toyotaHiluxXCS"] = "88toyotaHilux_SpawnList",

	["Base.89fordBronco"] = "89fordBroncoSpawnList",
	["Base.89fordBroncoPD"] = "89fordBroncoSpawnList",
	["Base.89fordBroncoRanger"] = "89fordBroncoSpawnList",

	["Base.89dodgeCaravan"] = "89dodgeCaravanSpawnList",
	["Base.89dodgeCaravanLE"] = "89dodgeCaravanSpawnList",
	["Base.89dodgeCaravanNomad"] = "89dodgeCaravanSpawnList",

	["Base.89trooper"] = "89trooper_SpawnList",
	["Base.89trooperRS"] = "89trooper_SpawnList",
	["Base.89trooperOP"] = "89trooper_SpawnList",

	["Base.89defender90"] = "89defender_SpawnList",
	["Base.89defender90utility"] = "89defender_SpawnList",
	["Base.89defender110"] = "89defender_SpawnList",
	["Base.89defender110utility"] = "89defender_SpawnList",
	["Base.89defender130"] = "89defender_SpawnList",

	["Base.89volvo244sedan"] = "89volvo200_SpawnList",
	["Base.89volvo245wagon"] = "89volvo200_SpawnList",
	["Base.89volvo242turbo"] = "89volvo200_SpawnList",

	["Base.90bmwE30sedan2"] = "90bmwE30_SpawnList",
	["Base.90bmwE30sedan4"] = "90bmwE30_SpawnList",
	["Base.90bmwE30touring"] = "90bmwE30_SpawnList",
	["Base.90bmwE30cabrio"] = "90bmwE30_SpawnList",
	["Base.90bmwE30m3"] = "90bmwE30_SpawnList",

	["Base.90fordF350ambulance"] = "90fordF350ambulance_SpawnList",
	["Base.90fordF350SWAT"] = "90fordF350ambulance_SpawnList",

	["Base.90pierceArrow"] = "90pierceArrowspawnList",

	["Base.91fordLTD"] = "91fordLTD_SpawnList",
	["Base.91fordLTDwagon"] = "91fordLTD_SpawnList",
	["Base.91fordLTDunmarked"] = "91fordLTD_SpawnList",
	["Base.91fordLTDtaxi"] = "91fordLTD_SpawnList",
	["Base.91fordLTDksp"] = "91fordLTD_SpawnList",
	["Base.91fordLTDksp2"] = "91fordLTD_SpawnList",
	["Base.91fordLTDpd"] = "91fordLTD_SpawnList",
	["Base.91fordLTDranger"] = "91fordLTD_SpawnList",

	["Base.91fordRangerSC"] = "91fordRanger_SpawnList",
	["Base.91fordRangerSClong"] = "91fordRanger_SpawnList",
	["Base.91fordRangerXC"] = "91fordRanger_SpawnList",
	["Base.91fordRangerXClong"] = "91fordRanger_SpawnList",
	["Base.91fordRangerPD"] = "91fordRanger_SpawnList",
	["Base.91fordRangerRanger"] = "91fordRanger_SpawnList",

	["Base.91geoMetro"] = "91geoMetro_SpawnList",
	
	["Base.91lexusLS400"] = "91lexusLS400_SpawnList",

	["Base.91nissan240sx"] = "91nissan240sx_SpawnList",
	["Base.91nissan240sx2"] = "91nissan240sx_SpawnList",

	["Base.91range"] = "91range_SpawnList",
	["Base.91range2"] = "91range_SpawnList",

	["Base.92fordCV"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPIunmarked"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPItaxi"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPI"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPIpdu"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPI2ksp"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPI2kspst"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPI2"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPI2sup"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPI2so"] = "92fordCVPI_SpawnList",
	["Base.92fordCVPIfd"] = "92fordCVPI_SpawnList",

	["Base.92jeepYJs"] = "92jeepYJ_SpawnList",
	["Base.92jeepYJse"] = "92jeepYJ_SpawnList",
	["Base.92jeepYJranger"] = "92jeepYJ_SpawnList",

	["Base.92jeepYJjp"] = "92jeepYJJP18_SpawnList",

	["Base.92nissanGTR"] = "92nissanGTRSpawnList",
	["Base.92nissanGTRlhd"] = "92nissanGTRSpawnList",

	["Base.93chevySuburban"] = "93chevySuburban_SpawnList",
	["Base.93chevySuburbanDually"] = "93chevySuburban_SpawnList",
	["Base.93chevySuburbanfbi"] = "93chevySuburban_SpawnList",
	["Base.93chevySuburbanfd"] = "93chevySuburban_SpawnList",
	["Base.93chevySuburbanpd"] = "93chevySuburban_SpawnList",
	["Base.93chevySuburbanksp"] = "93chevySuburban_SpawnList",
	["Base.93chevySuburbanpdu"] = "93chevySuburban_SpawnList",

	["Base.93chevySilveradoCC"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoCClong"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoCCdually"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoSC"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoSClong"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoSCdually"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoXC"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoXClong"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoXCdually"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoK3500wrecker"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoK3500flatbed"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoCClongfd"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoXClongRanger"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoSClongFossoil"] = "93chevySilverado_SpawnList",
	["Base.93chevySilveradoXClongMcCoy"] = "93chevySilverado_SpawnList",

	["Base.93fordElgin"] = "93fordElgin_SpawnList",

	["Base.93fordF150"] = "93fordF350_SpawnList",
	["Base.93fordF150S"] = "93fordF350_SpawnList",
	["Base.93fordF250"] = "93fordF350_SpawnList",
	["Base.93fordF350"] = "93fordF350_SpawnList",
	["Base.93fordF350dually"] = "93fordF350_SpawnList",
	["Base.93fordF350utilityDpw"] = "93fordF350_SpawnList",
	["Base.93fordF350utilityFd"] = "93fordF350_SpawnList",
	["Base.93fordF350fd"] = "93fordF350_SpawnList",
	["Base.93fordF350pd"] = "93fordF350_SpawnList",
	["Base.93fordF350so"] = "93fordF350_SpawnList",
	["Base.93fordF350utility"] = "93fordF350_SpawnList",

	["Base.93mustangSSP"] = "93mustangSSP_SpawnList",
	["Base.93mustangGT"] = "93mustangSSP_SpawnList",
	["Base.93mustangSVTcobraR"] = "93mustangSSP_SpawnList",
	["Base.93mustangSSPpd"] = "93mustangSSP_SpawnList",
	["Base.93mustangSSPpd2"] = "93mustangSSP_SpawnList",
	["Base.93mustangSSPksp"] = "93mustangSSP_SpawnList",
	["Base.93mustangSSPksp2"] = "93mustangSSP_SpawnList",
	["Base.93mustangSSPunmarked"] = "93mustangSSP_SpawnList",
	["Base.93mustangSSPkspCol"] = "93mustangSSP_SpawnList",

	["Base.93fordTaurus"] = "93fordTaurus_SpawnList",
	["Base.93fordTaurusSHO"] = "93fordTaurus_SpawnList",
	["Base.93fordTaurusWagon"] = "93fordTaurus_SpawnList",

	["Base.93townCar"] = "93townCar_SpawnList",
	["Base.93townCarLimo"] = "93townCar_SpawnList",

	["Base.95impreza"] = "95impreza_SpawnList",
	["Base.95imprezalhd"] = "95impreza_SpawnList",

	["Base.96lancerEVO"] = "96lancerEVO_SpawnList",
	["Base.96lancerEVOlhd"] = "96lancerEVO_SpawnList",

	["Base.98stagea260RS"] = "98stagea_SpawnList",
	["Base.98stagea260RSlhd"] = "98stagea_SpawnList",

	["Base.99fordCVPI"] = "99fordCVPI_SpawnList",
	["Base.99fordCVPIunmarked"] = "99fordCVPI_SpawnList",

	["Base.04vwTouran"] = "04vwTouran_SpawnList",

	["Base.isoContainer2"] = "isoContainers_SpawnList",
	["Base.isoContainer3tanker"] = "isoContainers_SpawnList",
}

VZDUtils.clearSpawnZones(vehicles, true)

VZDUtils.addToSpawnZone("Base.49powerWagon", "farm", nil, 15)
VZDUtils.addToSpawnZone("Base.49powerWagonPA", "business", nil, 1)
VZDUtils.addToSpawnZone("Base.49powerWagonMP", "military", nil, 5)

VZDUtils.addToSpawnZone("Base.63Type2VanHippie", "business", nil, 1)
VZDUtils.addToSpawnZone("Base.63Type2VanApocalypse", "business", nil, 1)
VZDUtils.addToSpawnZone("Base.63Type2VanMilitary", "military", nil, 3)

VZDUtils.addToSpawnZone("Base.67commandoBurnt", "junkyard", nil, 1)
VZDUtils.addToSpawnZone("Base.67commandoBurnt", "trafficjams", nil, 1)
VZDUtils.addToSpawnZone("Base.67commandoBurnt", "military", nil, 5)

VZDUtils.addToSpawnZone("Base.69fordMustangEV6", "business", nil, 0.33)
VZDUtils.addToSpawnZone("Base.69fordMustangTBC", "business", nil, 0.33)
VZDUtils.addToSpawnZone("Base.69fordMustangUBC", "business", nil, 0.33)

VZDUtils.addToSpawnZone("Base.80manKat1", "business", nil, 3)
VZDUtils.addToSpawnZone("Base.80manKat1", "parkingstall", nil, 2)
VZDUtils.addToSpawnZone("Base.80manKat1", "junkyard", nil, 2)
VZDUtils.addToSpawnZone("Base.80manKat1", "trafficjams", nil, 2)
VZDUtils.addToSpawnZone("Base.80manKat1", "transit", nil, 10)
VZDUtils.addToSpawnZone("Base.80manKat1", "delivery", nil, 20)

VZDUtils.addToSpawnZone("Base.84mercLWB4M", "military", nil, 10)

VZDUtils.addToSpawnZone("Base.85chevyImpalaSedanPrison", "prison", nil, 50)
VZDUtils.addToSpawnZone("Base.85chevyImpalaSedanAirport", "airportservice", nil, 20)
VZDUtils.addToSpawnZone("Base.85chevyImpalaSedanTaxi", "airportshuttle", nil, 10)

VZDUtils.addToSpawnZone("Base.87fordF700bank", "business", nil, 4)
VZDUtils.addToSpawnZone("Base.87fordF700box", "business", nil, 4)
VZDUtils.addToSpawnZone("Base.87fordF700box", "parkingstall", nil, 3)
VZDUtils.addToSpawnZone("Base.87fordF700box", "junkyard", nil, 3)
VZDUtils.addToSpawnZone("Base.87fordF700box", "trafficjams", nil, 3)
VZDUtils.addToSpawnZone("Base.87fordF700box", "transit", nil, 15)
VZDUtils.addToSpawnZone("Base.87fordF700box", "delivery", nil, 30)
VZDUtils.addToSpawnZone("Base.87fordB700school", "junkyard", nil, 3)
VZDUtils.addToSpawnZone("Base.87fordB700school", "trafficjams", nil, 3)
VZDUtils.addToSpawnZone("Base.87fordB700military", "military", nil, 4)

VZDUtils.addToSpawnZone("Base.89defenderWolf", "military", nil, 15)

VZDUtils.addToSpawnZone("Base.92amgeneralM998Burnt", "junkyard", nil, 15, "92amgeneralM998SpawnList")
VZDUtils.addToSpawnZone("Base.92amgeneralM998Burnt", "trafficjams", nil, 15)

VZDUtils.addToSpawnZone("Base.93townCarLimo", "parkingstall", nil, 0.5)
VZDUtils.addToSpawnZone("Base.93townCarLimo", "good", nil, 1)
VZDUtils.addToSpawnZone("Base.93townCarLimo", "trafficjams", nil, 0.5)

VZDUtils.addToSpawnZone("Base.isoContainer3tanker", "fossoil", 2, 25)
VZDUtils.addToSpawnZone("Base.isoContainer3tanker", "airportservice", nil, 15)
VZDUtils.addToSpawnZone("Base.isoContainer3tanker", "farm", nil, 5)
VZDUtils.addToSpawnZone("Base.isoContainer3tanker", "military", nil, 15)

VZDUtils.addToSpawnZone("Base.isoContainer2", "mccoy", 4, 30)
VZDUtils.addToSpawnZone("Base.isoContainer2", "lectromax", nil, 10)
VZDUtils.addToSpawnZone("Base.isoContainer2", "massgenfac", nil, 10)
VZDUtils.addToSpawnZone("Base.isoContainer2", "transit", nil, 10)
VZDUtils.addToSpawnZone("Base.isoContainer2", "military", nil, 15)

VZDUtils.addToSpawnZone("Base.isoContainer5", "junkyard", nil, 10)
VZDUtils.addToSpawnZone("Base.isoContainer5", "farm", nil, 7)

VZDUtils.removeFromSpawnZone({ ["Base.TrailerKI5livestock"] = "KI5trailers_SpawnList" }, "parkingstall")

VZDUtils.addToSpawnZone("Base.TrailerKI5utilityLarge", "transit", nil, 4)
VZDUtils.addToSpawnZone("Base.TrailerKI5utilityMedium", "transit", nil, 7)
VZDUtils.addToSpawnZone("Base.TrailerKI5utilitySmall", "transit", nil, 10)

VZDUtils.addToSpawnZone("Base.TrailerKI5cargoLarge", "transit", nil, 1)
VZDUtils.addToSpawnZone("Base.TrailerKI5cargoMedium", "transit", nil, 2)
VZDUtils.addToSpawnZone("Base.TrailerKI5cargoSmall", "transit", nil, 3)

local function setSkins(vehicleName, zoneName, skins)
	if not VehicleZoneDistribution[zoneName] or not VehicleZoneDistribution[zoneName].vehicles then return end
	if VehicleZoneDistribution[zoneName].vehicles[vehicleName] then
		VehicleZoneDistribution[zoneName].vehicles[vehicleName].skins = skins
	end
end

setSkins("Base.67commando", "military", { 0, 1, 2, 4, 5, 6 })
setSkins("Base.78amgeneralM50A3", "military", { 0, 1, 2, 3, 4, 5, 6 })
setSkins("Base.78amgeneralM62", "military", { 0, 1, 2, 3, 4, 5, 6 })
setSkins("Base.80manKat1", "military", { 1, 2, 4 })
setSkins("Base.80manKat1", "business", { 0, 2, 3 })
setSkins("Base.80manKat1", "parkingstall", { 0, 2, 3 })
setSkins("Base.80manKat1", "junkyard", { 0, 2, 3 })
setSkins("Base.80manKat1", "trafficjams", { 0, 2, 3 })
setSkins("Base.80manKat1", "transit", { 0, 2, 3 })
setSkins("Base.80manKat1", "delivery", { 0, 2, 3 })
setSkins("Base.86chevyM1010", "military", { 0, 1, 2, 3 })
setSkins("Base.isoContainer2", "military", { 0, 1, 2, 3, 5 })
setSkins("Base.isoContainer2", "lectromax", { 0, 3, 5 })
setSkins("Base.isoContainer2", "massgenfac", { 0, 3, 5 })
setSkins("Base.isoContainer2", "transit", { 0, 3, 5 })
setSkins("Base.isoContainer3tanker", "military", { 0, 1, 3, 4, 5 })
setSkins("Base.isoContainer3tanker", "airportservice", { 0, 4, 5 })
setSkins("Base.isoContainer3tanker", "farm", { 0, 4, 5, 6 })