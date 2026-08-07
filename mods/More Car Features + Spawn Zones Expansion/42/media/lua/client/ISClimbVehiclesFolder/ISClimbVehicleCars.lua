if getActivatedMods():contains("ClimbableVehicles") then return end

local function initClimbVehicles()
if SandboxVars.GamestaVehicleZones.climbVehicles ~= true then return end

local WayMoreCarsOptions = PZAPI.ModOptions:getOptions("WayMoreCarsOptionsID")

local climbUpCars = WayMoreCarsOptions:getOption("UpCarsID")
local dropDownCars = WayMoreCarsOptions:getOption("DownCarsID")

local climbUpHatches = WayMoreCarsOptions:getOption("UpHatchesID")
local dropDownHatches = WayMoreCarsOptions:getOption("DownHatchesID")
local fallSidesHatchesConditional = WayMoreCarsOptions:getOption("SidesHatchesConditionalID")
local fallSidesHatches = WayMoreCarsOptions:getOption("SidesHatchesID")

local vehicleroof
local vehiclesize
local lengthFrontShift
local lengthBackShift
local widthShift
local heightShift
local extraTall
local playerangle
local playerangleOriginal
local playerpos
local playerpospre
local carpospre
local solidRoofCheck

--Vanilla
	--Normal
	ChevalierCeriseWagon = {
		["Base.CarStationWagon"] = true,
		["Base.CarStationWagon2"] = true,
	}
	ChevalierNyala = {
		["Base.CarLightsBulletinSheriff"] = true,
		["Base.CarNormal"] = true,
		["Base.CarLightsLouisvilleCounty"] = true,
		["Base.CarLightsMuldraughPolice"] = true,
		["Base.CarLightsPolice"] = true,
		["Base.CarLightsRanger"] = true,
		["Base.CarLightsKST"] = true,
		["Base.CarTaxi"] = true,
		["Base.CarTaxi2"] = true,
	}
	ChevalierPrimani = {
		["Base.ModernCar02"] = true,
	}
	DashElite = {
		["Base.ModernCar"] = true,
		["Base.ModernCarLightsCityLouisvillePD"] = true,
		["Base.ModerModernCarLightsMeadeSheriffnCar02"] = true,
		["Base.ModernCarLightsWestPoint"] = true,
	}
	MastersonHorizon = {
		["Base.SmallCar02"] = true,
	}
	--Short
	ChevalierCossette = {
		["Base.SportsCar"] = true,
	}
	ChevalierDart = {
		["Base.SmallCar"] = true,
	}
	MerciaLangFourK = {
		["Base.CarLuxury"] = true,
	}
	RaceCar = {
		["Base.RaceCar34"] = true,
		["Base.RaceCar58"] = true,
		["Base.RaceCar12"] = true,
	}
	--Tall
	ChevalierD6 = {
		["Base.PickUpTruckLightsAirport"] = true,
		["Base.PickUpTruckLightsAirportSecurity"] = true,
		["Base.PickUpTruck"] = true,
		["Base.PickUpTruck_Camo"] = true,
		["Base.PickUpTruckLightsFire"] = true,
		["Base.PickUpTruckLightsFossoil"] = true,
		["Base.PickUpTruckJPLandscaping"] = true,
		["Base.PickUpTruckMccoy"] = true,
		["Base.PickUpTruckLightsRanger"] = true,
	}
	DashBulldriver = {
		["Base.PickUpVanBrickingIt"] = true,
		["Base.PickUpVanBuilder"] = true,
		["Base.PickUpVanCallowayLandscaping"] = true,
		["Base.PickUpVanLightsCarpenter"] = true,
		["Base.PickUpVan"] = true,
		["Base.PickUpVan_Camo"] = true,
		["Base.PickUpVanLightsFire"] = true,
		["Base.PickUpVanLightsFossoil"] = true,
		["Base.PickUpVanHeltonMetalWorking"] = true,
		["Base.PickUpVanLightsKentuckyLumber"] = true,
		["Base.PickUpVanKimbleKonstruction"] = true,
		["Base.PickUpVanLightsLouisvilleCounty"] = true,
		["Base.PickUpVanMarchRidgeConstruction"] = true,
		["Base.PickUpVanMccoy"] = true,
		["Base.PickUpVanMetalworker"] = true,
		["Base.PickUpVanLightsPolice"] = true,
		["Base.PickUpVanLightsRanger"] = true,
		["Base.PickUpVanLightsStatePolice"] = true,
		["Base.PickUpVanYingsWood"] = true,
		["Base.PickUpVanWeldingbyCamille"] = true,
	}
	DashRancher = {
		["Base.OffRoad"] = true,
	}
	FranklinAllTerrain = {
		["Base.SUV"] = true,
	}
	FranklinValuline = {
		["Base.VanBeckmans"] = true,
		["Base.VanBrewsterHarbin"] = true,
		["Base.Van_BugWipers"] = true,
		["Base.VanBuilder"] = true,
		["Base.VanCarpenter"] = true,
		["Base.VanCoastToCoast"] = true,
		["Base.VanDeerValley"] = true,
		["Base.VanFossoil"] = true,
		["Base.Van"] = true,
		["Base.VanGreenes"] = true,
		["Base.VanOvoFarm"] = true,
		["Base.Van_Blacksmith"] = true,
		["Base.Van_Charlemange_Beer"] = true,
		["Base.Van_CraftSupplies"] = true,
		["Base.Van_Glass"] = true,
		["Base.Van_HeritageTailors"] = true,
		["Base.Van_Leather"] = true,
		["Base.Van_Locksmith"] = true,
		["Base.Van_Masonry"] = true,
		["Base.Van_Perfick_Potato"] = true,
		["Base.VanGardenGods"] = true,
		["Base.VanGardener"] = true,
		["Base.VanJohnMcCoy"] = true,
		["Base.VanJonesFabrication"] = true,
		["Base.VanKerrHomes"] = true,
		["Base.VanKnobCreekGas"] = true,
		["Base.Van_KnoxDisti"] = true,
		["Base.VanKnoxCom"] = true,
		["Base.VanKorshunovs"] = true,
		["Base.Van_LectroMax"] = true,
		["Base.VanLouisvilleLandscaping"] = true,
		["Base.VanMail"] = true,
		["Base.Van_MassGenFac"] = true,
		["Base.VanMccoy"] = true,
		["Base.VanMechanic"] = true,
		["Base.VanMeltingPointMetal"] = true,
		["Base.VanMetalheads"] = true,
		["Base.VanMetalworker"] = true,
		["Base.VanMicheles"] = true,
		["Base.VanMobileMechanics"] = true,
		["Base.VanMooreMechanics"] = true,
		["Base.VanOldMill"] = true,
		["Base.VanPennSHam"] = true,
		["Base.VanPlattAuto"] = true,
		["Base.VanPluggedInElectrics"] = true,
		["Base.VanRiversideFabrication"] = true,
		["Base.VanRosewoodworking"] = true,
		["Base.VanSchwabSheetMetal"] = true,
		["Base.VanSpiffo"] = true,
		["Base.Van_Transit"] = true,
		["Base.VanTreyBaines"] = true,
		["Base.VanUncloggers"] = true,
		["Base.VanUtility"] = true,
		["Base.Van_VoltMojo"] = true,
		["Base.VanWPCarpentry"] = true,
		--6 Seater Vans
		["Base.VanSeatsAirportShuttle"] = true,
		["Base.VanSeats_Creature"] = true,
		["Base.VanSeats"] = true,
		["Base.VanSeats_Mural"] = true,
		["Base.VanSeats_Trippy"] = true,
		["Base.VanSeats_Prison"] = true,
		["Base.VanSeats_Space"] = true,
		["Base.VanSeats_LadyDelighter"] = true,
		["Base.VanSeats_Valkyrie"] = true,
		--Radio Vans
		["Base.VanRadio"] = true,
		["Base.VanRadio_3N"] = true,
		--Ambulance Van
		["Base.VanAmbulance"] = true,
	}
	--Extra Tall
	ChevalierStepVan = {
		["Base.StepVanAirportCatering"] = true,
		["Base.StepVan_Cereal"] = true,
		["Base.StepVan"] = true,
		["Base.StepVan_Blacksmith"] = true,
		["Base.StepVan_Butchers"] = true,
		["Base.StepVan_Florist"] = true,
		["Base.StepVan_Glass"] = true,
		["Base.StepVan_Masonry"] = true,
		["Base.StepVan_MobileLibrary"] = true,
		["Base.StepVan_Propane"] = true,
		["Base.StepVan_SmartKut"] = true,
		["Base.StepVan_Citr8"] = true,
		["Base.StepVan_CompleteRepairShop"] = true,
		["Base.StepVan_Genuine_Beer"] = true,
		["Base.StepVan_HuangsLaundry"] = true,
		["Base.StepVan_Jorgensen"] = true,
		["Base.StepVan_Heralds"] = true,
		["Base.StepVan_LouisvilleMotorShop"] = true,
		["Base.StepVan_LouisvilleSWAT"] = true,
		["Base.StepVanMail"] = true,
		["Base.StepVan_MarineBites"] = true,
		["Base.StepVan_Mechanic"] = true,
		["Base.StepVan_Plonkies"] = true,
		["Base.StepVan_RandisPlants"] = true,
		["Base.StepVan_Scarlet"] = true,
		["Base.StepVan_SouthEasternHosp"] = true,
		["Base.StepVan_SouthEasternPaint"] = true,
		["Base.StepVan_USL"] = true,
	}

--Modded KI5 (in order of release date/mod ID)
	RangeRoverClassic_91 = {
		["Base.91range"] = true,
		["Base.91range2"] = true,
	}
	AMGeneralM998_92 = {
		["Base.92amgeneralM998"] = true,
	}
	CadilacMilerMeteor_59 = {
		["Base.59meteor"] = true,
		["Base.59ambulance"] = true,
		["Base.ECTO1"] = true,
	}
	MercedesBenzW460long_84 = {
		["Base.84mercLWB2"] = true,
		["Base.84mercLWB4"] = true,
		["Base.84mercLWB4M"] = true,
	}
	MercedesBenzW460short_84 = {
		["Base.84mercSWB"] = true,
	}
	NissanSkylineGTRR32_92 = {
		["Base.92nissanGTR"] = true,
		["Base.92nissanGTRlhd"] = true,
	}
	FordEconolineE150long_86 = {
		["Base.86fordE150long"] = true,
		["Base.86fordE150LVairportShuttle"] = true,
		["Base.86fordE150deerValley"] = true,
		["Base.86fordE150rosewoodWorking"] = true,
		["Base.86fordE150wpCarpentry"] = true,
		["Base.86fordE150jones"] = true,
		["Base.86fordE150kerrHomes"] = true,
		["Base.86fordE150perfick"] = true,
		["Base.86fordE150heritageTailors"] = true,
	}
	FordEconolineE150short_86 = {
		["Base.86fordE150"] = true,
		["Base.86fordE150dnd"] = true,
		["Base.86fordE150slide"] = true,
		["Base.86fordE150mm"] = true,
		["Base.86fordE150pd"] = true,
		["Base.86fordE150med"] = true,
		["Base.86fordE150ksp"] = true,
		["Base.86fordE150so"] = true,
		["Base.86fordE150mccoy"] = true,
		["Base.86fordE150LBMWradio"] = true,
		["Base.86fordE150leatherwork"] = true,
		["Base.86fordE150brewster"] = true,
		["Base.86fordE150fossoil"] = true,
		["Base.86fordE150locksmith"] = true,
		["Base.86fordE150knobCreek"] = true,
		["Base.86fordE150knoxDistilery"] = true,
		["Base.86fordE150korshunovs"] = true,
		["Base.86fordE150lvLandscaping"] = true,
		["Base.86fordE150metalheads"] = true,
		["Base.86fordE150michelesWoodshop"] = true,
		["Base.86fordE150mobileMechanics"] = true,
		["Base.86fordE150oldMillWaterCompany"] = true,
		["Base.86fordE150blacksmith"] = true,
		["Base.86fordE150pluggedInElectrics"] = true,
		["Base.86fordE150postal"] = true,
		["Base.86fordE150riversideFab"] = true,
		["Base.86fordE150schwab"] = true,
		["Base.86fordE150stoneworksMasonry"] = true,
		["Base.86fordE150tasteTheBrew"] = true,
		["Base.86fordE150voltMojo"] = true,
		["Base.86fordE150beckmansBuilding"] = true,
		["Base.86fordE150brushAndClay"] = true,
		["Base.86fordE150bugWipers"] = true,
		["Base.86fordE150ccconstruction"] = true,
		["Base.86fordE150greenes"] = true,
		["Base.86fordE150knoxTelecom"] = true,
		["Base.86fordE150kyTransit"] = true,
		["Base.86fordE150lectromax"] = true,
		["Base.86fordE150massGenfac"] = true,
		["Base.86fordE150McCoyWoodworking"] = true,
		["Base.86fordE150meltingPointMetal"] = true,
		["Base.86fordE150mooresMechanics"] = true,
		["Base.86fordE150oVoFarms"] = true,
		["Base.86fordE150pennSham"] = true,
		["Base.86fordE150plattAutoRepair"] = true,
		["Base.86fordE150theGardenGods"] = true,
		["Base.86fordE150treyBaines"] = true,
		["Base.86fordE150uncloggers"] = true,
		["Base.86fordE150zenith"] = true,
		["Base.86fordE150creatureCruiser"] = true,
		["Base.86fordE150theLadyDelighter"] = true,
		["Base.86fordE150quantumVessel"] = true,
		["Base.86fordE150valkyriesSpear"] = true,
		["Base.86fordE150mesmerWagon"] = true,
	}
	DodgeChallenger_70 = {
		["Base.70dodgeBG"] = true,
		["Base.70dodgeOP"] = true,
		["Base.70dodgePD"] = true,
		["Base.70dodgeRT"] = true,
		["Base.70dodgeTA"] = true,
	}
	JeepJ10_82 = {
		["Base.82jeepJ10"] = true,
		["Base.82jeepJ10t"] = true,
		["Base.82jeepJ10pd"] = true,
		["Base.82jeepJ10ranger"] = true,
	}
	ChevroletS10_88 = {
		["Base.88chevyS10"] = true,
	}
	FordBronco_89 = {
		["Base.89fordBronco"] = true,
		["Base.89fordBroncoPD"] = true,
		["Base.89fordBroncoRanger"] = true,
	}
	PlymouthBarracuda_70 = {
		["Base.70barracuda"] = true,
		["Base.70cuda"] = true,
		["Base.70barracudaAAR"] = true,
	}
	LincolnTownCar_93 = {
		["Base.93townCar"] = true,
	}
	Limo_93 = {
		["Base.93townCarLimo"] = true,
	}
	IsuzaTrooper_89 = {
		["Base.89trooper"] = true,
		["Base.89trooperRS"] = true,
		["Base.89trooperOP"] = true,
	}
	MiniMk2_69 = {
		["Base.69mini"] = true,
		["Base.69miniUnionJack"] = true,
		["Base.69miniIJ"] = true,
		["Base.69miniMrB"] = true,
		["Base.69miniPS"] = true,
	}
	FordCrownVictoria_92 = {
		["Base.92fordCVPI"] = true,
		["Base.92fordCVPIunmarked"] = true,
		["Base.92fordCVPI2"] = true,
		["Base.92fordCVPI2ksp"] = true,
		["Base.92fordCVPItaxi"] = true,
		["Base.92fordCVPI2sup"] = true,
		["Base.92fordCVPI2so"] = true,
		["Base.92fordCV"] = true,
		["Base.92fordCVPI2kspst"] = true,
		["Base.92fordCVPIpdu"] = true,
		["Base.92fordCVPIfd"] = true,
	}
	ChevroletCamero_69 = {
		["Base.69camaroSS"] = true,
		["Base.69camaroRS"] = true,
	}
	FordMustangSSP_93 = {
		["Base.93mustangSSP"] = true,
		["Base.93mustangSSPpd"] = true,
		["Base.93mustangSSPksp"] = true,
		["Base.93mustangSSPunmarked"] = true,
		["Base.93mustangSSPkspCol"] = true,
	}
	Volkswagon1300Beetle_63 = {
		["Base.63beetle"] = true,
		["Base.63beetleBuggy"] = true,
		["Base.63beetleHP"] = true,
	}
	GeoMetro_91 = {
		["Base.91geoMetro"] = true,
	}
	ShelbyGT500yEleanor_67 = {
		["Base.67gt500"] = true,
		["Base.67gt500e"] = true,
	}
	DodgeCaravan_89 = {
		["Base.89dodgeCaravan"] = true,
		["Base.89dodgeCaravanLE"] = true,
		["Base.89dodgeCaravanNomad"] = true,
	}
	VolkswagenType2Van_63 = {
		["Base.63Type2Van"] = true,
		["Base.63Type2VanMilitary"] = true,
		["Base.63Type2VanHippie"] = true,
		["Base.63Type2VanApocalypse"] = true,
	}
	ToyotaMR2_87 = {
		["Base.87toyotaMR2"] = true,
		["Base.87toyotaMR2c"] = true,
	}
	FordFSeriesF150_93 = {
		["Base.93fordF150"] = true,
	}
	FordFSeriesF250_93 = {
		["Base.93fordF250"] = true,
	}
	FordFSeriesF350_93 = {
		["Base.93fordF350"] = true,
		["Base.93fordF350dually"] = true,
		["Base.93fordF350pd"] = true,
		["Base.93fordF350fd"] = true,
		["Base.93fordF350so"] = true,
		["Base.93fordF350utility"] = true,
		["Base.93fordF350utilityDpw"] = true,
		["Base.93fordF350utilityFd"] = true,
	}
	FordTaurus_93 = {
		["Base.93fordTaurus"] = true,
		["Base.93fordTaurusSHO"] = true,
	}
	FordTaurusWagon_93 = {
		["Base.93fordTaurusWagon"] = true,
	}
	BMW3Series_90 = {
		["Base.90bmwE30cabrio"] = true,
		["Base.90bmwE30m3"] = true,
		["Base.90bmwE30sedan2"] = true,
		["Base.90bmwE30sedan4"] = true,
	}
	BMW3Seriestouring_90 = {
		["Base.90bmwE30touring"] = true,
	}
	ChevroletSuburbanySilveradosingle_93 = {
		["Base.93chevySilveradoK3500flatbed"] = true,
		["Base.93chevySilveradoK3500lvLandscaping"] = true,
		["Base.93chevySilveradoK3500mechanic"] = true,
		["Base.93chevySilveradoK3500wrecker"] = true,
		["Base.93chevySilveradoSCdually"] = true,
		["Base.93chevySilveradoSClong"] = true,
		["Base.93chevySilveradoSClongFossoil"] = true,
		["Base.93chevySilveradoStoneworksMasonry"] = true,
	}
	ChevroletSuburbanySilveradosingle2_93 = {
		["Base.93chevySilveradoAirport"] = true,
		["Base.93chevySilveradoSC"] = true,
	}
	ChevroletSuburbanySilveradosingleplus_93 = {
		["Base.93chevySilveradoMcCoyWoodworking"] = true,
		["Base.93chevySilveradoRiversideFab"] = true,
		["Base.93chevySilveradoVoltMojo"] = true,
		["Base.93chevySilveradoWpCarpentry"] = true,
		["Base.93chevySilveradoXC"] = true,
		["Base.93chevySilveradoXCdually"] = true,
		["Base.93chevySilveradoXClong"] = true,
		["Base.93chevySilveradoXClongMcCoy"] = true,
		["Base.93chevySilveradoXClongRanger"] = true,
	}
	ChevroletSuburbanySilveradodual_93 = {
		["Base.93chevySilveradoCC"] = true,
		["Base.93chevySilveradoCCdually"] = true,
		["Base.93chevySilveradoCClong"] = true,
		["Base.93chevySilveradoCClongfd"] = true,
		["Base.93chevySilveradoPennSham"] = true,
		["Base.93chevySilveradoPoliceBCS"] = true,
		["Base.93chevySilveradoPoliceMCS"] = true,
		["Base.93chevySilveradoUncloggers"] = true,
	}
	ChevroletSuburbanySilveradosuburban_93 = {
		["Base.93chevySuburban"] = true,
		["Base.93chevySuburbanAirportSec"] = true,
		["Base.93chevySuburbanDually"] = true,
		["Base.93chevySuburbanPoliceBCS"] = true,
		["Base.93chevySuburbanPoliceCLPD"] = true,
		["Base.93chevySuburbanPoliceLCPD"] = true,
		["Base.93chevySuburbanPoliceMCS"] = true,
		["Base.93chevySuburbanPoliceMPD"] = true,
		["Base.93chevySuburbanPoliceWPPD"] = true,
		["Base.93chevySuburbanPrison"] = true,
		["Base.93chevySuburbanfbi"] = true,
		["Base.93chevySuburbanfd"] = true,
		["Base.93chevySuburbanksp"] = true,
		["Base.93chevySuburbanpd"] = true,
		["Base.93chevySuburbanpdu"] = true,
	}
	ChevroletKSeriesshort_76 = {
		["Base.76chevyK10"] = true,
		["Base.76chevyK20"] = true,
		["Base.76chevyK20BigRed"] = true,
		["Base.76chevyK20utility"] = true,
		["Base.76chevyK10spirit"] = true,
		["Base.76chevyK10fd"] = true,
		["Base.76chevyK20fd"] = true,
		["Base.76chevyC30SCwrecker"] = true,
	}
	ChevroletKSerieslong_76 = {
		["Base.76chevyK30CC"] = true,
		["Base.76chevyK30CCdually"] = true,
		["Base.76chevyK30CCutility"] = true,
		["Base.76chevyK30SCdually"] = true,
		["Base.76chevyK30CCfd"] = true,
		["Base.76chevyC30CCwrecker"] = true,
	}
	ChevroletSuburban_87 = {
		["Base.87chevySuburban"] = true,
		["Base.87chevySuburbanCUCV"] = true,
		["Base.87chevySuburbanOP"] = true,
	}
	PontiacGrandPrix_75 = {
		["Base.75grandPrixSJ"] = true,
		["Base.75grandPrixLJ"] = true,
		["Base.75grandPrixHurst"] = true,
	}
	BuickRegal_87 = {
		["Base.87buickRegalTurboT"] = true,
		["Base.87buickRegalTurboTfbi"] = true,
		["Base.87buickRegalGNX"] = true,
	}
	DeLoreanDMC12_81 = {
		["Base.81deloreanDMC12"] = true,
		["Base.81deloreanDMC12BTTF"] = true,
	}
	PontiacFirebird_68 = {
		["Base.68firebird350"] = true,
		["Base.68firebird400"] = true,
		["Base.68firebirdRamAir"] = true,
		["Base.68firebirdRamAirCustom"] = true,
	}
	Volvo200Series_89 = {
		["Base.89volvo242turbo"] = true,
		["Base.89volvo244sedan"] = true,
	}
	Volvo200Serieswagon_89 = {
		["Base.89volvo245wagon"] = true,
	}
	PontiacFirebird_82 = {
		["Base.82firebird"] = true,
		["Base.82firebirdSE"] = true,
		["Base.82firebirdTA"] = true,
		["Base.82firebirdKITT"] = true,
		["Base.82firebirdKARR"] = true,
	}
	PontiacFirebird_77 = {
		["Base.77firebird"] = true,
		["Base.77firebirdES"] = true,
		["Base.77firebirdFR"] = true,
		["Base.77firebirdTA"] = true,
	}
	FordLTDCrownVictoriayCountrySquire_91 = {
		["Base.91fordLTD"] = true,
		["Base.91fordLTDksp"] = true,
		["Base.91fordLTDksp2"] = true,
		["Base.91fordLTDpd"] = true,
		["Base.91fordLTDranger"] = true,
		["Base.91fordLTDtaxi"] = true,
		["Base.91fordLTDunmarked"] = true,
		["Base.91fordLTDwagon"] = true,
	}
	Porche911_82 = {
		["Base.82porsche911turbo"] = true,
		["Base.82porsche911rwb"] = true,
	}
	JeepXJCherokee_84 = {
		["Base.84jeepXJ2"] = true,
		["Base.84jeepXJ4"] = true,
		["Base.84jeepXJksp"] = true,
		["Base.84jeepXJpd"] = true,
		["Base.84jeepXJranger"] = true,
	}
	ChevroletCapriceyImpalashort_85 = {
		["Base.85chevyCapriceSedan"] = true,
		["Base.85chevyCapriceCoupe"] = true,
		["Base.85chevyImpalaSedanAirport"] = true,
		["Base.85chevyImpalaSedanBCS"] = true,
		["Base.85chevyImpalaSedanCLPD"] = true,
		["Base.85chevyImpalaSedanFD"] = true,
		["Base.85chevyImpalaSedanKSP"] = true,
		["Base.85chevyImpalaSedanLCPD"] = true,
		["Base.85chevyImpalaSedanMCS"] = true,
		["Base.85chevyImpalaSedanMPD"] = true,
		["Base.85chevyImpalaSedanPD"] = true,
		["Base.85chevyImpalaSedanPDu"] = true,
		["Base.85chevyImpalaSedanPrison"] = true,
		["Base.85chevyImpalaSedanRanger"] = true,
		["Base.85chevyImpalaSedanTaxi"] = true,
		["Base.85chevyImpalaSedanWPPD"] = true,
	}
	ChevroletCapriceyImpalalong_85 = {
		["Base.85chevyCapriceWagon"] = true,
		["Base.85chevyCapriceWagon2"] = true,
	}
	PontiacParisienneshort_85 = {
		["Base.85pontiacParisienneSedan"] = true,
	}
	PontiacParisiennelong_85 = {
		["Base.85pontiacParisienneWagon"] = true,
		["Base.85pontiacParisienneWagon2"] = true,
	}
	BuickLeSabreshort_85 = {
		["Base.85buickLeSabreSedan"] = true,
		["Base.85buickLeSabreCoupe"] = true,
	}
	BuickLeSabrelong_85 = {
		["Base.85buickLeSabreWagon"] = true,
		["Base.85buickLeSabreWagon2"] = true,
	}
	OldsmobileDelta88short_85 = {
		["Base.85oldsmobileDelta88Sedan"] = true,
		["Base.85oldsmobileDelta88Coupe"] = true,
	}
	OldsmobileDelta88long_85 = {
		["Base.85oldsmobileDelta88Wagon"] = true,
		["Base.85oldsmobileDelta88Wagon2"] = true,
	}
	ChevroletCUCVextended_86 = {
		["Base.86chevyK5blazer"] = true,
		["Base.86chevyK5ksp"] = true,
		["Base.86chevyK5pd"] = true,
		["Base.86chevyM1009"] = true,
		["Base.86chevyM1009mp"] = true,
	}
	ChevroletCUCVsingle_86 = {
		["Base.86chevyM1008"] = true,
		["Base.86chevyM1010"] = true,
		["Base.86chevyM1028"] = true,
		["Base.86chevyM1031"] = true,
	}
	ToyotaHiluxsingle_88 = {
		["Base.88toyotaHiluxSC"] = true,
	}
	ToyotaHiluxsingleplus_88 = {
		["Base.88toyotaHiluxXC"] = true,
	}
	ToyotaHiluxextended_88 = {
		["Base.88toyotaHiluxXCS"] = true,
	}
	PontiacLeMansyGTO_66 = {
		["Base.66pontiacLeMans"] = true,
		["Base.66pontiacGTO"] = true,
	}
	FordFalcon_73 = {
		["Base.73fordFalconXBGT"] = true,
		["Base.73fordFalconXBGTlhd"] = true,
		["Base.73fordFalconPS"] = true,
		["Base.73fordFalconPSlhd"] = true,
	}
	Nissan240SX_91 = {
		["Base.91nissan240sx"] = true,
		["Base.91nissan240sx2"] = true,
	}
	FordRangersingle_91 = {
		["Base.91fordRangerSC"] = true,
		["Base.91fordRangerSClong"] = true,
	}
	FordRangersingleplus_91 = {
		["Base.91fordRangerPD"] = true,
		["Base.91fordRangerXC"] = true,
		["Base.91fordRangerXClong"] = true,
	}
	PontiacBanshee_65 = {
		["Base.65bansheeSprint"] = true,
		["Base.65banshee400"] = true,
		["Base.65bansheeXP"] = true,
	}
	LandRoverDefender90s_89 = {
		["Base.89defender90"] = true,
		["Base.89defender90utility"] = true,
	}
	LandRoverDefender110s_89 = {
		["Base.89defender110"] = true,
		["Base.89defender110utility"] = true,
	}
	LandRoverDefender130s_89 = {
		["Base.89defender130"] = true,
	}
	CadillacDeVille_84 = {
		["Base.84cadillacDeVilleSedan"] = true,
		["Base.84cadillacDeVilleCoupe"] = true,
	}
	BuickElectra_84 = {
		["Base.84buickElectraSedan"] = true,
		["Base.84buickElectraCoupe"] = true,
	}
	Oldsmobile98Regency_84 = {
		["Base.84oldsmobile98Sedan"] = true,
		["Base.84oldsmobile98Coupe"] = true,
	}
	ChevyStepVan_85 = {
		["Base.85chevyStepVan"] = true,
		["Base.85chevyStepVanButchers"] = true,
		["Base.85chevyStepVanLibrary"] = true,
		["Base.85chevyStepVanPropane"] = true,
		["Base.85chevyStepVanFlorist"] = true,
		["Base.85chevyStepVanMasonry"] = true,
		["Base.85chevyStepVanBlacksmith"] = true,
		["Base.85chevyStepVanSeHospitality"] = true,
		["Base.85chevyStepVanDelirosPlonkies"] = true,
		["Base.85chevyStepVanTheCompleteRepair"] = true,
		["Base.85chevyStepVanSePaintingServices"] = true,
		["Base.85chevyStepVanLvAirportCatering"] = true,
		["Base.85chevyStepVanPostal"] = true,
		["Base.85chevyStepVanUsLogistics"] = true,
		["Base.85chevyStepVanMarineBites"] = true,
		["Base.85chevyStepVanRandys"] = true,
		["Base.85chevyStepVanLvMotorshop"] = true,
		["Base.85chevyStepVanGenuine"] = true,
		["Base.85chevyStepVanHerald"] = true,
		["Base.85chevyStepVanScarletOak"] = true,
		["Base.85chevyStepVanJorgensen"] = true,
		["Base.85chevyStepVanSmartCut"] = true,
		["Base.85chevyStepVanTimelessGlass"] = true,
		["Base.85chevyStepVanZippeeMarket"] = true,
		["Base.85chevyStepVanCitrusWave"] = true,
		["Base.85chevyStepVanMrHuangsLaundry"] = true,
		["Base.85chevyStepVanSunBallz"] = true,
	}
	DodgeCharger_69 = {
		["Base.69chargerRT"] = true,
		["Base.69charger500"] = true,
		["Base.69chargerDaytona"] = true,
	}
	PlymouthRoadRunner_70 = {
		["Base.70roadRunner"] = true,
	}
	--Extra Tall/Other (KI5)
	commando_67 = {
		["Base.67commando"] = true,
		["Base.67commandoT50"] = true,
		["Base.67commandoPolice"] = true,
	}
	oshkoshP19A_86 = {
		["Base.86oshkoshUSMC"] = true,
		["Base.86oshkoshKYFD"] = true,
		["Base.86oshkoshFRTR55"] = true,
		["Base.86oshkoshP19ABurnt"] = true,
	}
	amgeneralM35A2_78 = {
		["Base.78amgeneralM35A2"] = true,
		["Base.78amgeneralM62"] = true,
	}
	amgeneralM35A2tanker_78 = {
		["Base.78amgeneralM49A2C"] = true,
		["Base.78amgeneralM50A3"] = true,
	}
	amgeneralM923_83 = {
		["Base.83amgeneralM923"] = true,
	}
	pierceArrow_90 = {
		["Base.90pierceArrow"] = true,
	}
	fordF350ambulance_90 = {
		["Base.90fordF350ambulance"] = true,
		["Base.90fordF350SWAT"] = true,
	}
	fordB700bankswat_87 = {
		["Base.87fordF700swat"] = true,
		["Base.87fordF700bank"] = true,
	}
	fordElgin_93 = {
		["Base.93fordElgin"] = true,
		["Base.93fordElginSpec"] = true,
	}
	manKat1_80 = {
		["Base.80manKat1"] = true,
	}

local VehicleCarsTables = {
--Vanilla
	--Normal
	ChevalierCeriseWagon,
	ChevalierNyala,
	ChevalierPrimani,
	DashElite,
	MastersonHorizon,
	--Short
	ChevalierCossette,
	ChevalierDart,
	MerciaLangFourK,
	RaceCar,
	--Tall
	ChevalierD6,
	DashBulldriver,
	DashRancher,
	FranklinAllTerrain,
	FranklinValuline,
	--Extra Tall
	ChevalierStepVan,

--Modded KI5 (in order of release date/mod ID)
	RangeRoverClassic_91,
	AMGeneralM998_92,
	CadilacMilerMeteor_59,
	MercedesBenzW460long_84,
	MercedesBenzW460short_84,
	NissanSkylineGTRR32_92,
	FordEconolineE150long_86,
	FordEconolineE150short_86,
	DodgeChallenger_70,
	JeepJ10_82,
	ChevroletS10_88,
	FordBronco_89,
	PlymouthBarracuda_70,
	LincolnTownCar_93,
	Limo_93,
	IsuzaTrooper_89,
	MiniMk2_69,
	FordCrownVictoria_92,
	ChevroletCamero_69,
	FordMustangSSP_93,
	Volkswagon1300Beetle_63,
	GeoMetro_91,
	ShelbyGT500yEleanor_67,
	DodgeCaravan_89,
	VolkswagenType2Van_63,
	ToyotaMR2_87,
	FordFSeriesF150_93,
	FordFSeriesF250_93,
	FordFSeriesF350_93,
	FordTaurus_93,
	FordTaurusWagon_93,
	BMW3Series_90,
	BMW3Seriestouring_90,
	ChevroletSuburbanySilveradosingle_93,
	ChevroletSuburbanySilveradosingle2_93,
	ChevroletSuburbanySilveradosingleplus_93,
	ChevroletSuburbanySilveradodual_93,
	ChevroletSuburbanySilveradosuburban_93,
	ChevroletKSeriesshort_76,
	ChevroletKSerieslong_76,
	ChevroletSuburban_87,
	PontiacGrandPrix_75,
	BuickRegal_87,
	DeLoreanDMC12_81,
	PontiacFirebird_68,
	Volvo200Series_89,
	Volvo200Serieswagon_89,
	PontiacFirebird_82,
	PontiacFirebird_77,
	FordLTDCrownVictoriayCountrySquire_91,
	Porche911_82,
	JeepXJCherokee_84,
	ChevroletCapriceyImpalashort_85,
	ChevroletCapriceyImpalalong_85,
	PontiacParisienneshort_85,
	PontiacParisiennelong_85,
	BuickLeSabreshort_85,
	BuickLeSabrelong_85,
	OldsmobileDelta88short_85,
	OldsmobileDelta88long_85,
	ChevroletCUCVextended_86,
	ChevroletCUCVsingle_86,
	ToyotaHiluxsingle_88,
	ToyotaHiluxsingleplus_88,
	ToyotaHiluxextended_88,
	PontiacLeMansyGTO_66,
	FordFalcon_73,
	Nissan240SX_91,
	FordRangersingle_91,
	FordRangersingleplus_91,
	PontiacBanshee_65,
	LandRoverDefender90s_89,
	LandRoverDefender110s_89,
	LandRoverDefender130s_89,
	CadillacDeVille_84,
	BuickElectra_84,
	Oldsmobile98Regency_84,
	ChevyStepVan_85,
	DodgeCharger_69,
	PlymouthRoadRunner_70,
	--Extra Tall/Other (KI5)
	commando_67,
	oshkoshP19A_86,
	amgeneralM35A2_78,
	amgeneralM35A2tanker_78,
	amgeneralM923_83,
	pierceArrow_90,
	fordF350ambulance_90,
	fordB700bankswat_87,
	fordElgin_93,
	manKat1_80,
}

local VehicleCars = {}
for _, tableGroup in ipairs(VehicleCarsTables) do
	for k,v in pairs(tableGroup) do
		VehicleCars[k] = true
	end
end

commando_67hatch = {
	["Base.67commando"] = true, --0, 1, 2, 3, 4, 5 
	["Base.67commandoT50"] = true, --0, 1, 2, 3, 4, 5
	["Base.67commandoPolice"] = true, --0, 1, 2, 3, 4, 5
}

oshkoshP19A_86hatch = {
	["Base.86oshkoshUSMC"] = true, --3
	["Base.86oshkoshKYFD"] = true, --3
	["Base.86oshkoshFRTR55"] = true, --3
}

RangeRoverClassic_91sunroof = {
	["Base.91range"] = true, --0, 1
	["Base.91range2"] = true, --0, 1
}

Limo_93sunroof = {
	["Base.93townCarLimo"] = true, --5
}

MercedesBenzW460long_84hatch = {
	["Base.84mercLWB4M"] = true, --2, 3
}

ToyotaMR2_87sunroof = {
	["Base.87toyotaMR2"] = true, --0, 1
}

Nissan240SX_91sunroof = {
	["Base.91nissan240sx2"] = true, --0, 1
}

local VehicleHybridsTables = {
	commando_67hatch,
	oshkoshP19A_86hatch,
	RangeRoverClassic_91sunroof,
	Limo_93sunroof,
	MercedesBenzW460long_84hatch,
	ToyotaMR2_87sunroof,
	Nissan240SX_91sunroof,
}

local VehicleHybrids = {}
for _, tableGroup in ipairs(VehicleHybridsTables) do
	for k,v in pairs(tableGroup) do
		VehicleHybrids[k] = true
	end
end

local function getSpecificV(vehicle)
	local fullVName = vehicle:getScript():getFullName()
--Vanilla
	--Normal
	if ChevalierCeriseWagon[fullVName] then
		return {0.4, 1}, 0.2, 2.1, 0.1
	elseif ChevalierNyala[fullVName] then
		return {0.4, 0.5}, 0.3, 1.8, 0.1
	elseif ChevalierPrimani[fullVName] then
		return {0.4, 0.5}, 0.5, 1.6, 0.1
	elseif DashElite[fullVName] then
		return {0.4, 0.6}, 0.3, 1.4, 0.1
	elseif MastersonHorizon[fullVName] then
		return {0.4, 0.5}, 0.2, 1.9, 0.05
	--Short
	elseif ChevalierCossette[fullVName] then
		return {0.3, 0.3}, 0.01, 2.5, 0.4
	elseif ChevalierDart[fullVName] then
		return {0.3, 0.4}, 0.01, 2.5, 0.2
	elseif MerciaLangFourK[fullVName] then
		return {0.4, 0.5}, 0.01, 1.5, 0.1
	elseif RaceCar[fullVName] then
		return {0.3, 0.3}, 0.01, 1.9, 0.45
	--Tall
	elseif ChevalierD6[fullVName] then
		return {0.4, 0.2}, 2.1, 0.3, -0.15
	elseif DashBulldriver[fullVName] then
		return {0.3, 1.3}, 0.3, 1.3, -0.05
	elseif DashRancher[fullVName] then
		return {0.4, 0.8}, 0.2, 1.5, -0.1
	elseif FranklinAllTerrain[fullVName] then
		return {0.5, 0.9}, 0.4, 1.5, -0.1
	elseif FranklinValuline[fullVName] then
		return {0.5, 1.5}, 0.6, 1.1, -0.25
	--Extra Tall
	elseif ChevalierStepVan[fullVName] then
		return {0.7, 1.7}, 0.7, 1.1, -0.55--, 0.25

--Modded KI5 (in order of release date/mod ID)
	elseif RangeRoverClassic_91[fullVName] then
		return {0.5, 1.0}, 0.01, 1.6, -0.2
	elseif AMGeneralM998_92[fullVName] then
		return {0.8, 1.1}, 0.5, 1.2, -0.3
	elseif CadilacMilerMeteor_59[fullVName] then
		return {0.5, 1.5}, 0.4, 1.3, 0.0
	elseif MercedesBenzW460long_84[fullVName] then
		return {0.5, 1.1}, 0.3, 1.5, -0.5
	elseif MercedesBenzW460short_84[fullVName] then
		return {0.5, 1.0}, 0.3, 1.3, -0.4
	elseif NissanSkylineGTRR32_92[fullVName] then
		return {0.3, 0.4}, 0.2, 1.7, 0.3
	elseif FordEconolineE150long_86[fullVName] then
		return {0.6, 2.1}, 0.4, 1.0, -0.25
	elseif FordEconolineE150short_86[fullVName] then
		return {0.6, 1.8}, 0.4, 1.0, -0.25
	elseif DodgeChallenger_70[fullVName] then
		return {0.4, 0.5}, 0.1, 1.5, 0.2
	elseif JeepJ10_82[fullVName] then
		return {0.5, 0.2}, 1.7, 0.3, -0.25
	elseif ChevroletS10_88[fullVName] then
		return {0.4, 0.2}, 1.3, 0.7, -0.1
	elseif FordBronco_89[fullVName] then
		return {0.5, 1.0}, 0.3, 1.5, -0.3
	elseif PlymouthBarracuda_70[fullVName] then
		return {0.4, 0.5}, 0.2, 1.6, 0.3
	elseif LincolnTownCar_93[fullVName] then
		return {0.4, 0.8}, 0.2, 1.5, 0.0
	elseif Limo_93[fullVName] then
		return {0.4, 1.4}, 0.5, 1.3, 0.0
	elseif IsuzaTrooper_89[fullVName] then
		return {0.5, 1.1}, 0.4, 1.3, -0.3
	elseif MiniMk2_69[fullVName] then
		return {0.3, 0.6}, 0.4, 1.4, 0.25
	elseif FordCrownVictoria_92[fullVName] then
		return {0.4, 0.6}, 0.3, 1.5, 0.05
	elseif ChevroletCamero_69[fullVName] then
		return {0.4, 0.6}, 0.2, 1.4, 0.3
	elseif FordMustangSSP_93[fullVName] then
		return {0.4, 0.4}, 0.1, 1.9, 0.2
	elseif Volkswagon1300Beetle_63[fullVName] then
		return {0.3, 0.4}, 0.5, 1.5, 0.25
	elseif GeoMetro_91[fullVName] then
		return {0.3, 0.4}, 0.2, 1.9, 0.25
	elseif ShelbyGT500yEleanor_67[fullVName] then
		return {0.4, 0.4}, 0.1, 1.7, 0.15
	elseif DodgeCaravan_89[fullVName] then
		return {0.5, 1.0}, 0.4, 1.5, -0.25
	elseif VolkswagenType2Van_63[fullVName] then
		return {0.4, 1.4}, 0.8, 1.1, -0.3
	elseif ToyotaMR2_87[fullVName] then
		return {0.3, 0.3}, 0.4, 1.2, 0.3
	elseif FordFSeriesF150_93[fullVName] then
		return {0.5, 0.3}, 0.6, 1.0, -0.4
	elseif FordFSeriesF250_93[fullVName] then
		return {0.5, 0.3}, 1.0, 0.5, -0.4
	elseif FordFSeriesF350_93[fullVName] then
		return {0.5, 0.6}, 1.5, 0.4, -0.4
	elseif FordTaurus_93[fullVName] then
		return {0.5, 0.6}, 0.4, 1.3, 0.1
	elseif FordTaurusWagon_93[fullVName] then
		return {0.5, 0.9}, 0.2, 1.8, 0.1
	elseif BMW3Series_90[fullVName] then
		return {0.3, 0.5}, 0.4, 1.6, 0.2
	elseif BMW3Seriestouring_90[fullVName] then
		return {0.3, 0.9}, 0.2, 1.4, 0.2
	elseif ChevroletSuburbanySilveradosingle_93[fullVName] then
		return {0.4, 0.2}, 2.5, 0.01, -0.3
	elseif ChevroletSuburbanySilveradosingle2_93[fullVName] then
		return {0.4, 0.2}, 1.8, 0.4, -0.35
	elseif ChevroletSuburbanySilveradosingleplus_93[fullVName] then
		return {0.4, 0.4}, 1.9, 0.3, -0.35
	elseif ChevroletSuburbanySilveradodual_93[fullVName] then
		return {0.4, 0.6}, 1.5, 0.4, -0.35
	elseif ChevroletSuburbanySilveradosuburban_93[fullVName] then
		return {0.4, 1.4}, 0.4, 1.3, -0.35
	elseif ChevroletKSeriesshort_76[fullVName] then
		return {0.4, 0.3}, 1.6, 0.01, -0.3
	elseif ChevroletKSerieslong_76[fullVName] then
		return {0.4, 0.7}, 1.3, 0.5, -0.3
	elseif ChevroletSuburban_87[fullVName] then
		return {0.4, 1.4}, 0.4, 1.3, -0.35
	elseif PontiacGrandPrix_75[fullVName] then
		return {0.4, 0.5}, 0.3, 1.6, 0.15
	elseif BuickRegal_87[fullVName] then
		return {0.5, 0.6}, 0.3, 1.3, 0.15
	elseif DeLoreanDMC12_81[fullVName] then
		return {0.3, 0.3}, 0.01, 2.5, 0.35
	elseif PontiacFirebird_68[fullVName] then
		return {0.4, 0.5}, 0.1, 1.6, 0.2
	elseif Volvo200Series_89[fullVName] then
		return {0.4, 0.6}, 0.4, 1.3, 0.05
	elseif Volvo200Serieswagon_89[fullVName] then
		return {0.4, 1.1}, 0.2, 1.6, 0.05
	elseif PontiacFirebird_82[fullVName] then
		return {0.4, 0.5}, 0.01, 1.5, 0.3
	elseif PontiacFirebird_77[fullVName] then
		return {0.4, 0.5}, 0.01, 1.8, 0.3
	elseif FordLTDCrownVictoriayCountrySquire_91[fullVName] then
		return {0.4, 0.7}, 0.3, 1.2, 0.1
	elseif Porche911_82[fullVName] then
		return {0.3, 0.3}, 0.01, 1.6, 0.35
	elseif JeepXJCherokee_84[fullVName] then
		return {0.5, 1.0}, 0.1, 1.6, -0.1
	elseif ChevroletCapriceyImpalashort_85[fullVName] then
		return {0.5, 0.7}, 0.3, 1.1, 0.1
	elseif ChevroletCapriceyImpalalong_85[fullVName] then
		return {0.5, 1.2}, 0.2, 1.6, 0.1
	elseif PontiacParisienneshort_85[fullVName] then
		return {0.5, 0.7}, 0.3, 1.1, 0.1
	elseif PontiacParisiennelong_85[fullVName] then
		return {0.5, 1.2}, 0.2, 1.6, 0.1
	elseif BuickLeSabreshort_85[fullVName] then
		return {0.5, 0.7}, 0.3, 1.1, 0.1
	elseif BuickLeSabrelong_85[fullVName] then
		return {0.5, 1.2}, 0.2, 1.6, 0.1
	elseif OldsmobileDelta88short_85[fullVName] then
		return {0.5, 0.7}, 0.3, 1.1, 0.1
	elseif OldsmobileDelta88long_85[fullVName] then
		return {0.5, 1.2}, 0.2, 1.6, 0.1
	elseif ChevroletCUCVextended_86[fullVName] then
		return {0.5, 1.0}, 0.2, 1.6, -0.3
	elseif ChevroletCUCVsingle_86[fullVName] then
		return {0.5, 0.3}, 1.6, 0.1, -0.3
	elseif ToyotaHiluxsingle_88[fullVName] then
		return {0.4, 0.2}, 1.1, 0.9, -0.15
	elseif ToyotaHiluxsingleplus_88[fullVName] then
		return {0.4, 0.4}, 1.3, 0.6, -0.15
	elseif ToyotaHiluxextended_88[fullVName] then
		return {0.4, 1.4}, 0.4, 1.3, -0.15
	elseif PontiacLeMansyGTO_66[fullVName] then
		return {0.4, 0.5}, 0.5, 1.4, 0.15
	elseif FordFalcon_73[fullVName] then
		return {0.4, 0.5}, 0.2, 1.4, 0.2
	elseif Nissan240SX_91[fullVName] then
		return {0.3, 0.2}, 0.1, 3.0, 0.3
	elseif FordRangersingle_91[fullVName] then
		return {0.4, 0.2}, 1.5, 0.5, -0.2
	elseif FordRangersingleplus_91[fullVName] then
		return {0.4, 0.4}, 1.2, 0.5, -0.2
	elseif PontiacBanshee_65[fullVName] then
		return {0.3, -0.3}, 3.0, -0.9, 0.35
	elseif LandRoverDefender90s_89[fullVName] then
		return {0.4, 1.1}, 0.2, 1.4, -0.5
	elseif LandRoverDefender110s_89[fullVName] then
		return {0.4, 1.4}, 0.3, 1.3, -0.5
	elseif LandRoverDefender130s_89[fullVName] then
		return {0.4, 0.6}, 1.0, 0.9, -0.45
	elseif CadillacDeVille_84[fullVName] then
		return {0.4, 0.8}, 0.2, 1.3, 0.1
	elseif BuickElectra_84[fullVName] then
		return {0.4, 0.8}, 0.2, 1.3, 0.1
	elseif Oldsmobile98Regency_84[fullVName] then
		return {0.4, 0.8}, 0.2, 1.3, 0.1
	elseif ChevyStepVan_85[fullVName] then
		return {0.8, 2.1}, 0.5, 1.2, -1.0
	elseif DodgeCharger_69[fullVName] then
		return {0.4, 0.5}, 0.1, 1.7, 0.2
	elseif PlymouthRoadRunner_70[fullVName] then
		return {0.4, 0.5}, 0.1, 1.7, 0.2
	--Extra Tall/Other (KI5)
	elseif commando_67[fullVName] then
		return {0.6, 1.8}, 0.8, 1.2, -0.55--, 0.25
	elseif oshkoshP19A_86[fullVName] then
		return {0.5, 3.3}, 1.0, 0.9, -1.0--, 0.1
	elseif amgeneralM35A2_78[fullVName] then
		return {0.5, 0.3}, 2.5, 0.01, -1.0--, 0.15
	elseif amgeneralM35A2tanker_78[fullVName] then
		return {0.5, 1.6}, 0.3, 2.0, -0.8--, 0.15
	elseif amgeneralM923_83[fullVName] then
		return {0.7, 0.4}, 3.8, -2.0, -1.3--, 0.0
	elseif pierceArrow_90[fullVName] then
		return {0.6, 3.1}, 1.1, 0.9, -1.20--, 0.05
	elseif fordF350ambulance_90[fullVName] then
		return {0.9, 1.8}, 0.1, 1.5, -1.1--, 0.1
	elseif fordB700bankswat_87[fullVName] then
		return {0.8, 2.1}, 0.4, 1.2, -1.05--, 0.1
	elseif fordElgin_93[fullVName] then
		return {0.7, 2.1}, 0.9, 1.0, -1.2--, 0.05
	elseif manKat1_80[fullVName] then
		return {0.6, 1.0}, 3.0, -1.0, -1.25--, 0.0
	end
end

local function getab(table1,table2)
	local a,b
	local c = table1[1]-table2[1]
	if c ~= 0 then
		a = (table1[2]-table2[2])/c
		b = table1[2]-a*table1[1]
		return a,b
	else 
		return false,false
	end
end

local function findFirstAvailableSeat(vehicle, seatIndices)
	for _, idx in ipairs(seatIndices) do
		local part = vehicle:getPartForSeatContainer(idx)
		if part and part:getInventoryItem() ~= nil then
			return idx
		end
	end
	return nil
end

local function localisSolidRoof()
	local cell = getCell()
	if not vehicleroof then return end

	local z0 = 0
	local baseX = math.floor(vehicleroof:getX())
	local baseY = math.floor(vehicleroof:getY())

	local maxsize = math.max(vehiclesize[1], vehiclesize[2])
	local rx = math.ceil(maxsize)+1
	local ry = rx

	solidRoofCheck = false
	for dx = -rx, rx do
		for dy = -ry, ry do
			local sx = baseX + dx
			local sy = baseY + dy
			local sq0 = cell:getGridSquare(sx, sy, z0)
			if sq0 then
				if sq0:getVehicleContainer() == vehicleroof then
					local sq1 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift-1, 1)
					if sq1:isSolidFloor() then solidRoofCheck = true return end
					local sq2 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift+1, 1)
					if sq2:isSolidFloor() then solidRoofCheck = true return end
					local sq3 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift+1, 1)
					if sq3:isSolidFloor() then solidRoofCheck = true return end
					local sq4 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift-1, 1)
					if sq4:isSolidFloor() then solidRoofCheck = true return end
				end
			end
		end
	end
end

local function solidifyRoof()
	local cell = getCell()
	if not vehicleroof then return end

	local z0 = 0
	local baseX = math.floor(vehicleroof:getX())
	local baseY = math.floor(vehicleroof:getY())

	local maxsize = math.max(vehiclesize[1], vehiclesize[2])
	local rx = math.ceil(maxsize)+1
	local ry = rx

	for dx = -rx, rx do
		for dy = -ry, ry do
			local sx = baseX + dx
			local sy = baseY + dy
			local sq0 = cell:getGridSquare(sx, sy, z0)
			if sq0 then
				if sq0:getVehicleContainer() == vehicleroof then -- ~= nil or == vehicleroof
					local sq1 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift-1, 1)
					if sq1 then sq1:setSolidFloor(true) end
					local sq2 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift+1, 1)
					if sq2 then sq2:setSolidFloor(true) end
					local sq3 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift+1, 1)
					if sq3 then sq3:setSolidFloor(true) end
					local sq4 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift-1, 1)
					if sq4 then sq4:setSolidFloor(true) end
				end
--			else (backup)
--				local objects = sq0:getLuaMovingObjectList()
--				for i, obj in ipairs(objects) do
--					print(vehicleroof)
--					print(obj)
--					if obj == vehicleroof then
--						print("yes")
--						local sq5 = cell:getOrCreateGridSquare(sx+heightShift, sy+heightShift, z)
--						if sq5 then sq5:setSolidFloor(true) end
--					else
--						print("no")
--					end
--				end
			end
		end
	end
end

local function unsolidifyRoof()
	local cell = getCell()
	if not vehicleroof then return end

	local z0 = 0
	local baseX = math.floor(vehicleroof:getX())
	local baseY = math.floor(vehicleroof:getY())

	local maxsize = math.max(vehiclesize[1], vehiclesize[2])
	local rx = math.ceil(maxsize)+1
	local ry = rx

	for dx = -rx, rx do
		for dy = -ry, ry do
			local sx = baseX + dx
			local sy = baseY + dy
			local sq0 = cell:getGridSquare(sx, sy, z0)
			if sq0 then
				if sq0:getVehicleContainer() == vehicleroof then
					local sq1 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift-1, 1)
					if sq1 then sq1:setSolidFloor(false) end
					local sq2 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift+1, 1)
					if sq2 then sq2:setSolidFloor(false) end
					local sq3 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift+1, 1)
					if sq3 then sq3:setSolidFloor(false) end
					local sq4 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift-1, 1)
					if sq4 then sq4:setSolidFloor(false) end
				end
			end
		end
	end
end

local function ifOnRoof(player)
	local vx = vehicleroof:getX()
	local vy = vehicleroof:getY()
	local vz = vehicleroof:getZ()
	
	if not (vehicleroof and playerangle and playerpos) then
		carpospre = nil
		playerpospre = nil
		unsolidifyRoof()
		player:setX(player:getX()-heightShift)
		player:setY(player:getY()-heightShift)
		if extraTall then player:setZ(player:getZ()-extraTall) else player:setZ(player:getZ()-0.5) end
		player:getModData().isonVehicleCars = { false, nil, nil, nil, nil, nil, nil, nil, nil }
		Events.OnPlayerUpdate.Remove(ifOnRoof)
		return
	end
	
	local fullVName = vehicleroof:getScript():getFullName()
	if VehicleHybrids[fullVName] then
		if isKeyPressed(dropDownHatches:getValue()) then
			local seatCandidates = nil
			if commando_67hatch[fullVName] then seatCandidates = {0,1,2,3,4,5}
			elseif oshkoshP19A_86hatch[fullVName] then seatCandidates = {3}
			elseif RangeRoverClassic_91sunroof[fullVName] then seatCandidates = {0,1}
			elseif Limo_93sunroof[fullVName] then seatCandidates = {5}
			elseif MercedesBenzW460long_84hatch[fullVName] then seatCandidates = {2,3}
			elseif ToyotaMR2_87sunroof[fullVName] then seatCandidates = {0,1}
			elseif Nissan240SX_91sunroof[fullVName] then seatCandidates = {0,1}
			end
			if not vehicleroof:isAnyDoorLocked() then
				if seatCandidates then
					local seatNumber = findFirstAvailableSeat(vehicleroof, seatCandidates)
					if seatNumber then
						carpospre = nil
						playerpospre = nil
						unsolidifyRoof()
						player:getModData().isonHatch = { false, nil, nil, nil, nil, nil, nil, nil, nil }
						vehicleroof:enter(seatNumber, player)
						vehicleroof:setCharacterPosition(player, seatNumber, "inside")
						vehicleroof:transmitCharacterPosition(seatNumber, "inside")
						vehicleroof:playPassengerAnim(seatNumber, "idle")
						Events.OnPlayerUpdate.Remove(ifOnRoof)
						
						triggerEvent("OnEnterVehicle", player)
						triggerEvent("OnSwitchVehicleSeat", player)
						return
					end
				end
			end
		elseif (isKeyDown(fallSidesHatchesConditional:getValue()) and isKeyPressed(fallSidesHatches:getValue())) or (fallSidesHatchesConditional:getValue() == 0 and isKeyPressed(fallSidesHatches:getValue())) then
			carpospre = nil
			playerpospre = nil
			unsolidifyRoof()
			player:setX(player:getX()-heightShift)
			player:setY(player:getY()-heightShift)
			if extraTall then player:setZ(player:getZ()-extraTall) else player:setZ(player:getZ()-0.5) end
			player:getModData().isonVehicleCars = { false, nil, nil, nil, nil, nil, nil, nil, nil }
			
			Events.OnPlayerUpdate.Remove(ifOnRoof)
			return
		end
	elseif isKeyPressed(dropDownCars:getValue()) then
		carpospre = nil
		playerpospre = nil
		unsolidifyRoof()
		player:setX(player:getX()-heightShift)
		player:setY(player:getY()-heightShift)
		if extraTall then player:setZ(player:getZ()-extraTall) else player:setZ(player:getZ()-0.5) end
		player:getModData().isonVehicleCars = { false, nil, nil, nil, nil, nil, nil, nil, nil }
		
		Events.OnPlayerUpdate.Remove(ifOnRoof)
		return
	end

	playerpos = {player:getX()-heightShift,player:getY()-heightShift,1}

	local vx1 = vx + vehiclesize[2]*lengthBackShift*math.cos(playerangle) + vehiclesize[1]*math.cos(playerangle+math.pi/2)
	local vy1 = vy + vehiclesize[2]*lengthBackShift*math.sin(playerangle) + vehiclesize[1]*math.sin(playerangle+math.pi/2)

	local vx2 = vx + vehiclesize[2]*lengthFrontShift*math.cos(playerangle+math.pi) + vehiclesize[1]*math.cos(playerangle+math.pi/2)
	local vy2 = vy + vehiclesize[2]*lengthFrontShift*math.sin(playerangle+math.pi) + vehiclesize[1]*math.sin(playerangle+math.pi/2)

	local vx3 = vx + vehiclesize[2]*lengthFrontShift*math.cos(playerangle+math.pi) + vehiclesize[1]*math.cos(playerangle-math.pi/2)
	local vy3 = vy + vehiclesize[2]*lengthFrontShift*math.sin(playerangle+math.pi) + vehiclesize[1]*math.sin(playerangle-math.pi/2)

	local vx4 = vx + vehiclesize[2]*lengthBackShift*math.cos(playerangle) + vehiclesize[1]*math.cos(playerangle-math.pi/2)
	local vy4 = vy + vehiclesize[2]*lengthBackShift*math.sin(playerangle) + vehiclesize[1]*math.sin(playerangle-math.pi/2)

	local pos1 = {vx1,vy1}
	local pos2 = {vx2,vy2}
	local pos3 = {vx3,vy3}
	local pos4 = {vx4,vy4}

	local postable = {pos1,pos2,pos3,pos4}

	local maxy = {0,0}
	local maxx = {0,0}
	local miny = {0,99999}
	local minx = {99999,0}

	for i=1,#postable do
		if postable[i][2] >= maxy[2] then
			maxy = {postable[i][1],postable[i][2]}
		end

		if postable[i][1] >= maxx[1] then
			maxx = {postable[i][1],postable[i][2]}
		end

		if postable[i][2] <= miny[2] then
			miny = {postable[i][1],postable[i][2]}
		end

		if postable[i][1] <= minx[1] then
			minx = {postable[i][1],postable[i][2]}
		end
	end

	local a1,b1 = getab(maxy,minx)
	local a2,b2 = getab(maxy,maxx)
	local a3,b3 = getab(maxx,miny)
	local a4,b4 = getab(minx,miny)

	local ismove = false

	if not a1 or not b1 then
		if playerpos[2] <= maxy[2] and playerpos[2] <= miny[2] and playerpos[1] <= maxx[1] and playerpos[1] >= minx[1] then
			ismove = true
		else
			ismove = false
		end
	else
		if playerpos[2]<=playerpos[1]*a1+b1 and playerpos[2] <= playerpos[1]*a2+b2 and playerpos[2] >= playerpos[1]*a3+b3 and playerpos[2] >= playerpos[1]*a4+b4 then
			ismove = true 
		else
			ismove = false
		end
	end
	
	solidifyRoof()

	if ismove then
		playerpospre = {player:getX(),player:getY()}
		if carpospre then
			if carpospre[1] ~= vx or carpospre[2] ~= vy then
				player:setX(player:getX()+vx-carpospre[1])
				player:setY(player:getY()+vy-carpospre[2])
			end
		end
	else
		if isClient() and carpospre and (carpospre[1] ~= vx or carpospre[2] ~= vy) then
			player:setX(vx+heightShift)
			player:setY(vy+heightShift)
		else
			if playerpospre ~= nil then
				player:setX(playerpospre[1])
				player:setY(playerpospre[2])
			else
				local scanStep = 0.1
				local found = false
				local foundX, foundY

				local xMin = math.min(minx[1], maxx[1], miny[1], maxy[1])
				local xMax = math.max(minx[1], maxx[1], miny[1], maxy[1])
				local yMin = math.min(minx[2], maxx[2], miny[2], maxy[2])
				local yMax = math.max(minx[2], maxx[2], miny[2], maxy[2])

				local y = yMin
				while y <= yMax and not found do
					local x = xMin
					while x <= xMax and not found do
						local testPosX = x
						local testPosY = y

						local isNowMove = false
						if not a1 or not b1 then
							if testPosY <= maxy[2] and testPosY <= miny[2] and testPosX <= maxx[1] and testPosX >= minx[1] then
								isNowMove = true
							end
						else
							if testPosY <= testPosX * a1 + b1 and
							testPosY <= testPosX * a2 + b2 and
							testPosY >= testPosX * a3 + b3 and
							testPosY >= testPosX * a4 + b4 then
								isNowMove = true
							end
						end

						if isNowMove then
							player:setX(testPosX + heightShift)
							player:setY(testPosY + heightShift)
							playerpospre = { player:getX(), player:getY() }
							found = true
							foundX, foundY = playerpospre[1], playerpospre[2]
							break
						end
						x = x + scanStep
					end
					y = y + scanStep
				end
				if not found then
					player:setX(vx + heightShift)
					player:setY(vy + heightShift)
				end
			end

		end
	end
	if player:getZ() <= 0.9 then
		player:setZ(1.1)
	end
	carpospre = {vx,vy,vz}
end

local function preCheckOnRoof()
	local player = getPlayer()
	if player == nil then return end
	local vehicle = player:getNearVehicle()
	if vehicle == nil or not VehicleCars[vehicle:getScript():getFullName()] then return end
	local seatIndex = findFirstAvailableSeat(vehicle, {0,1,2,3,4,5})
	if not seatIndex then return end

	local vx = vehicle:getX()
	local vy = vehicle:getY()
	local vz = vehicle:getZ()

	local dx = vx - player:getX()
	local dy = vy - player:getY()
	local dist = math.sqrt(dx*dx + dy*dy)
	if dist > 2 then return end

	if player:getModData().isClimbingVehicle then return end
	if isKeyPressed(climbUpCars:getValue()) then
		if vz > 0.5 then return end
		if player:getZ() ~= 0 then return end
		vehicleroof = vehicle
		vehiclesize, lengthBackShift, lengthFrontShift, widthShift, extraTall = getSpecificV(vehicle)
		heightShift = 1.3 + widthShift
		localisSolidRoof()
		if solidRoofCheck == true then return end
		if ISTimedActionQueue.isPlayerDoingAction(player) then ISTimedActionQueue.clear(player) end
		player:getModData().isClimbingVehicle = true
		local pathAction = ISPathFindAction:pathToVehicleAdjacent(player, vehicle)
		pathAction.Type = "ClimbVehicle"
		function pathAction:perform()
			if not player:getModData().isClimbingVehicle then
				ISPathFindAction.stop(self)
				return
			end
			ISPathFindAction.perform(self)
			player:faceThisObject(vehicle)
			local delayTicks = 100
			local delayAction = ISBaseTimedAction:derive("delayAction")
			delayAction.Type = "ClimbVehicle"
			function delayAction:new(character, time)
				local o = ISBaseTimedAction.new(self, character)
				o.maxTime = time or 1
				return o
			end
			function delayAction:isValid() return true end
			function delayAction:waitToStart()
				player:faceThisObject(vehicle)
				return player:shouldBeTurning()
			end
			function delayAction:start()
				player:setVariable("ClimbVehicle", true)
				player:setBlockMovement(true)
			end
			function delayAction:update()
				if not player:getModData().isClimbingVehicle then
					self:stop()
					return
				end
				local tq = ISTimedActionQueue.getTimedActionQueue(player)
				if tq and tq.queue then
					for i, a in ipairs(tq.queue) do
						if a and a.Type and a.Type ~= "ClimbVehicle" then
							self:stop()
							return
						end
					end
				end
			end
			function delayAction:perform()
				if not player:getModData().isClimbingVehicle then
					ISBaseTimedAction.perform(self)
					return
				end
				playerangleOriginal = player:getForwardDirection():getDirection()
				playerpos = {vx,vy,1}
				vehicle:enter(seatIndex, player)
				vehicle:transmitCharacterPosition(seatIndex, "inside")
				vehicle:playPassengerAnim(seatIndex, "idle")
				playerangle = player:getForwardDirection():getDirection()
				vehicle:exit(player)
				player:setTargetAndCurrentDirection(math.cos(playerangleOriginal), math.sin(playerangleOriginal))
				solidifyRoof()
				player:setX(vx+heightShift)
				player:setY(vy+heightShift)
				player:setZ(1.0)
				player:getModData().isonVehicleCars = { true, vx, vy, vz, vehiclesize, lengthBackShift, lengthFrontShift, widthShift, extraTall }
				player:setVariable("ClimbVehicle", false)
				player:setVariable("ClimbVehicleStarted", false)
				player:setVariable("ClimbVehicleStruggled", false)
				player:setBlockMovement(false)
				player:getModData().isClimbingVehicle = false
				Events.OnPlayerUpdate.Add(ifOnRoof)
				ISBaseTimedAction.perform(self)
			end
			function delayAction:stop()
				ISBaseTimedAction.stop(self)
				player:setVariable("ClimbVehicle", false)
				player:setVariable("ClimbVehicleStarted", false)
				player:setVariable("ClimbVehicleStruggled", false)
				player:setBlockMovement(false)
				player:getModData().isClimbingVehicle = false
			end
			ISTimedActionQueue.add(delayAction:new(player, delayTicks))
		end
		function pathAction:stop()
			ISPathFindAction.stop(self)
			player:getModData().isClimbingVehicle = false
		end
		ISTimedActionQueue.add(pathAction)
	end
end

local function preLoadCheckOnRoof(player)
	local vehicle = player:getNearVehicle()
	playerangleOriginal = player:getForwardDirection():getDirection()
	if vehicle == nil or (vehicle:getScript():getFullName() ~= VehicleCars[vehicle:getScript():getFullName()]) then
		local playerangleSpawnTest = (math.pi*.75)
		player:setTargetAndCurrentDirection(math.cos(playerangleSpawnTest), math.sin(playerangleSpawnTest))
		vehicle = player:getNearVehicle()
		if vehicle == nil or (vehicle:getScript():getFullName() ~= VehicleCars[vehicle:getScript():getFullName()]) then
			playerangleSpawnTest = (-math.pi*.75)
			player:setTargetAndCurrentDirection(math.cos(playerangleSpawnTest), math.sin(playerangleSpawnTest))
			vehicle = player:getNearVehicle()
			if vehicle == nil or (vehicle:getScript():getFullName() ~= VehicleCars[vehicle:getScript():getFullName()]) then
				playerangleSpawnTest = (-math.pi*.25)
				player:setTargetAndCurrentDirection(math.cos(playerangleSpawnTest), math.sin(playerangleSpawnTest))
				vehicle = player:getNearVehicle()
				if vehicle == nil or not (vehicle:getScript():getFullName() ~= VehicleCars[vehicle:getScript():getFullName()]) then
					playerangleSpawnTest = (math.pi*.25)
					player:setTargetAndCurrentDirection(math.cos(playerangleSpawnTest), math.sin(playerangleSpawnTest))
					vehicle = player:getNearVehicle()
					if vehicle == nil or not (vehicle:getScript():getFullName() ~= VehicleCars[vehicle:getScript():getFullName()]) then
						carpospre = nil
						playerpospre = nil
						unsolidifyRoof()
						player:getModData().isonVehicleCars = { false, nil, nil, nil, nil, nil, nil, nil, nil }
						player:setTargetAndCurrentDirection(math.cos(playerangleOriginal), math.sin(playerangleOriginal))
						Events.OnPlayerUpdate.Remove(preLoadCheckOnRoof)
						return
					end
				end
			end
		end
	end
	local seatIndex = findFirstAvailableSeat(vehicle, {0,1,2,3,4,5})
	if not seatIndex then
		carpospre = nil
		playerpospre = nil
		unsolidifyRoof()
		player:getModData().isonVehicleCars = { false, nil, nil, nil, nil, nil, nil, nil, nil }
		player:setTargetAndCurrentDirection(math.cos(playerangleOriginal), math.sin(playerangleOriginal))
		Events.OnPlayerUpdate.Remove(preLoadCheckOnRoof)
		return
	end
	vehicleroof = vehicle
	vehiclesize, lengthBackShift, lengthFrontShift, widthShift, extraTall = getSpecificV(vehicle)
	heightShift = 1.3 + widthShift
	localisSolidRoof()
	if solidRoofCheck == true then
		carpospre = nil
		playerpospre = nil
		unsolidifyRoof()
		player:getModData().isonVehicleCars = { false, nil, nil, nil, nil, nil, nil, nil, nil }
		player:setTargetAndCurrentDirection(math.cos(playerangleOriginal), math.sin(playerangleOriginal))
		Events.OnPlayerUpdate.Remove(preLoadCheckOnRoof)
		return
	end

	local vx, vy, vz = player:getModData().isonVehicleCars[2], player:getModData().isonVehicleCars[3], player:getModData().isonVehicleCars[4]

--	local playerposOriginalX, playerposOriginalY = player:getX(), player:getY()
	playerpos = {vx,vy,1}
	vehicle:enter(seatIndex, player)
	vehicle:transmitCharacterPosition(seatIndex, "inside")
	vehicle:playPassengerAnim(seatIndex, "idle")
	playerangle = player:getForwardDirection():getDirection()
	vehicle:exit(player)
	player:setTargetAndCurrentDirection(math.cos(playerangleOriginal), math.sin(playerangleOriginal))
	solidifyRoof()
	player:setX(vx+heightShift)
	player:setY(vy+heightShift)
	player:setZ(1.1)
	player:getModData().isonVehicleCars = { true, vx, vy, vz, vehiclesize, lengthBackShift, lengthFrontShift, widthShift, extraTall }

	Events.OnPlayerUpdate.Add(ifOnRoof)
	Events.OnPlayerUpdate.Remove(preLoadCheckOnRoof)
end

local function checkUpdate(playerIndex, player)
	if player:getModData().isonVehicleCars then
		if player:getModData().isonVehicleCars[1] == true and not getCell():getOrCreateGridSquare(player:getX(), player:getY(), player:getZ()):isSolidFloor() then
			player:setX(player:getX()-(1.3+player:getModData().isonVehicleCars[8]))
			player:setY(player:getY()-(1.3+player:getModData().isonVehicleCars[8]))
			player:setZ(0)
			Events.OnPlayerUpdate.Add(preLoadCheckOnRoof)
		end
	end
	player:getModData().isClimbingVehicle = false
	Events.OnTick.Add(preCheckOnRoof)
end

Events.OnCreatePlayer.Add(checkUpdate)

local function OnEnterVehicleForVC(player)
	triggerEvent("OnSwitchVehicleSeat", player)
	Events.OnTick.Remove(preCheckOnRoof)
end

Events.OnEnterVehicle.Add(OnEnterVehicleForVC)

local function OnExitVehicleForVC(player)
	Events.OnTick.Add(preCheckOnRoof)
end

Events.OnExitVehicle.Add(OnExitVehicleForVC)

end
Events.OnInitGlobalModData.Add(initClimbVehicles)