NewVZones = NewVZones or {}

function NewVZones.RebalancingAct()
	VehicleZoneDistribution.police.chanceToSpawnNormal = 0
	VehicleZoneDistribution.police.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.prison.chanceToSpawnNormal = 0
	VehicleZoneDistribution.prison.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.fire.chanceToSpawnNormal = 0
	VehicleZoneDistribution.fire.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.ambulance.chanceToSpawnNormal = 0
	VehicleZoneDistribution.ambulance.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.spiffo.chanceToSpawnNormal = 40
	VehicleZoneDistribution.mccoy.chanceToSpawnNormal = 0
	VehicleZoneDistribution.network3.chanceToSpawnNormal = 0
	VehicleZoneDistribution.sport.chanceToSpawnNormal = 0
	VehicleZoneDistribution.sport.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.good.chanceToSpawnNormal = 0
	VehicleZoneDistribution.good.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.medium.chanceToSpawnNormal = 0
	VehicleZoneDistribution.medium.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.bad.chanceToSpawnNormal = 0
	VehicleZoneDistribution.bad.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.postal.chanceToSpawnNormal = 0
	VehicleZoneDistribution.postal.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.ranger.chanceToSpawnNormal = 0
	VehicleZoneDistribution.ranger.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.sport.spawnRate = 10
	VehicleZoneDistribution.good.spawnRate = 12
	VehicleZoneDistribution.medium.spawnRate = 14
	VehicleZoneDistribution.bad.spawnRate = 16
	VehicleZoneDistribution.trailerpark.chanceToSpawnBurnt = 10
	VehicleZoneDistribution.trailerpark.chanceOfOverCar = 0

--	Strange things happen with this zone in particular because of how the race cars spawn (swapped at start of spawn of a burnt variant, default)
--	VehicleZoneDistribution.racecar.vehicles = {}
--	VehicleZoneDistribution.racecar.vehicles["Base.RaceCarBurnt"] = {index = -1, spawnChance = 1}
--	VehicleZoneDistribution.racecar.vehicles["Base.RaceCar12"] = {index = -1, spawnChance = 33}
--	VehicleZoneDistribution.racecar.vehicles["Base.RaceCar34"] = {index = -1, spawnChance = 33}
--	VehicleZoneDistribution.racecar.vehicles["Base.RaceCar58"] = {index = -1, spawnChance = 33}
--	VehicleZoneDistribution.racecar.spawnRate = 100;

	local activatedMods = getActivatedMods()

	if activatedMods:contains("isoContainers") then --2625625421
		VehicleZoneDistribution.parkingstall.vehicles["Base.isoContainer2"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["Base.isoContainer3tanker"] = nil
		VehicleZoneDistribution.postal.vehicles["Base.isoContainer3tanker"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.isoContainer5"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.advertising.vehicles["Base.isoContainer4"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.knoxdisti.vehicles["Base.isoContainer4"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.transit.vehicles["Base.isoContainer4"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.scarlet.vehicles["Base.isoContainer4"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.farm.vehicles["Base.isoContainer5"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.farm.vehicles["Base.isoContainer3tanker"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.farm.vehicles["Base.isoContainer2"] = {index = -1, spawnChance = 10}
	end

--No Vanilla Vehicles
	if not (activatedMods:contains("NoVanillaVehicles") or activatedMods:contains("VVR")) then
		VehicleZoneDistribution.mccoy.vehicles["Base.Trailer"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.mccoy.vehicles["Base.TrailerCover"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.carpenter.vehicles["Base.Trailer"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.carpenter.vehicles["Base.TrailerCover"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.ranger.vehicles["Base.Trailer"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.ranger.vehicles["Base.TrailerCover"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.trailerpark.vehicles["Base.Trailer"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerCover"] = {index = -1, spawnChance = 10}
	end

--W900
	if activatedMods:contains("rSemiTruck") then --3409472393
		VehicleZoneDistribution.parkingstall.vehicles["SemiTruck"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["SemiTruckLite"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["SemiTruckBox"] = nil

		VehicleZoneDistribution.parkingstall.vehicles["SemiTrailerLowBed"] = {index = 1, spawnChance = 0}
		VehicleZoneDistribution.fire.vehicles["SemiTrailerLowBed"] = {index = 1, spawnChance = 0}
		VehicleZoneDistribution.police.vehicles["SemiTrailerLowBed"] = {index = 1, spawnChance = 0}
		VehicleZoneDistribution.junkyard.vehicles["SemiTrailerLowBed"] = {index = 1, spawnChance = 5}
		VehicleZoneDistribution.advertising.vehicles["SemiTrailerLowBed"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.transit.vehicles["SemiTrailerLowBed"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.mccoy.vehicles["SemiTrailerLowBed"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.postal.vehicles["SemiTrailerLowBed"] = nil
		VehicleZoneDistribution.fossoil.vehicles["SemiTrailerLowBed"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.kyheralds.vehicles["SemiTrailerLowBed"] = nil
	end

--U.S. M113 APC
	if activatedMods:contains("U.S.M113_APC_by_Papa_Chad") then --2705655822
		VehicleZoneDistribution.trailerpark.vehicles["Base.M113_APC"] = nil
		VehicleZoneDistribution.fossoil.vehicles["Base.M113_APC"] = nil
		VehicleZoneDistribution.ranger.vehicles["Base.M113_APC"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.police.vehicles["Base.M113_Police"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.medium.vehicles["Base.M113_APC"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["Base.M113_APC"] = nil

		VehicleZoneDistribution.trafficjamw.vehicles["Base.M113_APC"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.M113_Police"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.M113_APC"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.M113_APC"] = nil

		VehicleZoneDistribution.farm.vehicles["Base.M113_APC"] = nil
		VehicleZoneDistribution.farm.vehicles["Base.M113_Police"] = nil

		VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
		VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}
		VehicleZoneDistribution.military.vehicles["Base.M113_APC"] = {index = -1, spawnChance = 10}

		VehicleZoneDistribution.normalburnt.vehicles["Base.M113_APCBurnt"] = nil
		VehicleZoneDistribution.specialburnt.vehicles["Base.M113_APCBurnt"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.M113_APCBurnt"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.M113_APCBurnt"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.M113_APCBurnt"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.M113_APCBurnt"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.M113_APCBurnt"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.M113_APCBurnt"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.M113_APCBurnt"] = nil
	end

--U.S. M548
	if activatedMods:contains("U.S. M548 Cargo Carrier by Papa_Chad") then --3424497614
		VehicleZoneDistribution.trailerpark.vehicles["Base.M548"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.M548"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.M548"] = nil
		VehicleZoneDistribution.ranger.vehicles["Base.M548"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.medium.vehicles["Base.M548"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["Base.M548"] = nil

		VehicleZoneDistribution.trafficjamw.vehicles["Base.M548"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.M548"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.M548"] = nil

		VehicleZoneDistribution.farm.vehicles["Base.M548"] = nil

		VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
		VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}
		VehicleZoneDistribution.military.vehicles["Base.M548"] = {index = -1, spawnChance = 10}

		VehicleZoneDistribution.normalburnt.vehicles["Base.M548Burnt"] = nil
		VehicleZoneDistribution.specialburnt.vehicles["Base.M548Burnt"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.M548Burnt"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.M548Burnt"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.M548Burnt"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.M548Burnt"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.M548Burnt"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.M548Burnt"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.M548Burnt"] = nil
	end

--US M998 Humvee
	if activatedMods:contains("U.S. M998 Humvee by Papa_Chad") then --3554424111
		VehicleZoneDistribution.trailerpark.vehicles["Base.M998_Humvee"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["Base.M998_Humvee"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.M998_Humvee"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.M998_Humvee"] = nil
		VehicleZoneDistribution.medium.vehicles["Base.M998_Humvee"] = nil
		VehicleZoneDistribution.fire.vehicles["Base.M998_Humvee"] = nil
		VehicleZoneDistribution.farm.vehicles["Base.M998_Humvee"] = nil

		VehicleZoneDistribution.ranger.vehicles["Base.M998_Humvee"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.airportshuttle.vehicles["Base.M998_Humvee"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.police.vehicles["Base.M998_Humvee"] = {index = 0, spawnChance = 1}

		VehicleZoneDistribution.trafficjamw.vehicles["Base.M998_Humvee"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.M998_Humvee"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.M998_Humvee"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.M998_Humvee"] = nil
	end

--U.S. M163
	if activatedMods:contains("U.S. M163 VADS by Papa_Chad by Papa_Chad") then --3598575779
		VehicleZoneDistribution.trailerpark.vehicles["Base.M163"] = nil
		VehicleZoneDistribution.fossoil.vehicles["Base.M163"] = nil
		VehicleZoneDistribution.ranger.vehicles["Base.M163"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.police.vehicles["Base.M163"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.medium.vehicles["Base.M163"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["Base.M163"] = nil

		VehicleZoneDistribution.trafficjamw.vehicles["Base.M163"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.M163"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.M163"] = nil

		VehicleZoneDistribution.farm.vehicles["Base.M163"] = nil

		VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
		VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}
		VehicleZoneDistribution.military.vehicles["Base.M163"] = {index = -1, spawnChance = 10}
	end

--Autotsar Motorclub
	if activatedMods:contains("amclub") then --3404737883
		VehicleZoneDistribution.parkingstall.vehicles["Base.AMC_quad"] = nil
		
		VehicleZoneDistribution.trailerpark.vehicles["Base.AMC_quad"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.mccoy.vehicles["Base.AMC_quad"] = nil

		VehicleZoneDistribution.fossoil.vehicles["Base.AMC_quad"] = nil

		VehicleZoneDistribution.postal.vehicles["Base.AMC_bmw_classic"] = nil
		VehicleZoneDistribution.postal.vehicles["Base.AMC_quad"] = nil

		VehicleZoneDistribution.bad.vehicles["Base.AMC_bmw_classic"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.bad.vehicles["Base.AMC_bmw_custom"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.bad.vehicles["Base.AMC_harley"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.bad.vehicles["Base.AMC_quad"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.bad.vehicles["Base.TrailerAMC"] = {index = -1, spawnChance = 3}
	end

--PZK
	if activatedMods:contains("PzkVanillaPlusCarPack") then --3217685049
		VehicleZoneDistribution.prison.vehicles["Base.pzkFranklinTruckBusPrison"] = nil

		VehicleZoneDistribution.fire.vehicles["Base.pzkFireTruckFlatLadder"] = {index = -1, spawnChance = 50}
	end

--KI5
	if activatedMods:contains("91range") then --2409333430
		VehicleZoneDistribution.trailerpark.vehicles["Base.91range"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.91range2"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91range"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91range"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91range"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91range"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91range2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91range2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91range2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91range2"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.91range"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.91range2"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("67commando") then --2478247379
		VehicleZoneDistribution.trailerpark.vehicles["Base.67commando"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.67commandoT50"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.67commandoBurnt"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.67commando"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.67commandoT50"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.67commandoBurnt"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.67commando"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.67commandoT50"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.67commandoBurnt"] = nil

		VehicleZoneDistribution.police.vehicles["Base.67commandoPolice"] = nil

		VehicleZoneDistribution.ranger.vehicles["Base.67commando"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.farm.vehicles["Base.67commando"] = nil
		VehicleZoneDistribution.farm.vehicles["Base.67commandoT50"] = nil
	end


	if activatedMods:contains("86oshkoshP19A") then --2566953935
		VehicleZoneDistribution.trailerpark.vehicles["Base.86oshkoshKYFD"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.86oshkoshP19ABurnt"] = nil

		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerM1082"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerM1095"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.86oshkoshUSMC"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.86oshkoshP19ABurnt"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerM1082"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerM1095"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.86oshkoshUSMC"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.86oshkoshFRTR55"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.86oshkoshKYFD"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.86oshkoshP19ABurnt"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerM1082"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerM1095"] = nil

		VehicleZoneDistribution.police.vehicles["Base.86oshkoshUSMC"] = nil

		VehicleZoneDistribution.fire.vehicles["Base.86oshkoshUSMC"] = nil
	end


	if activatedMods:contains("82oshkoshM911") then --2618213077
		VehicleZoneDistribution.trailerpark.vehicles["Base.82oshkoshM911"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.82oshkoshM911B"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.82oshkoshM911Burnt"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerM127stake"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerM128van"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerM129van"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerM747lowbed"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerM967tanker"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.82oshkoshM911"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.82oshkoshM911B"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.82oshkoshM911Burnt"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerM747lowbed"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.mccoy.vehicles["Base.TrailerM127stake"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.mccoy.vehicles["Base.TrailerM128van"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.mccoy.vehicles["Base.82oshkoshM911B"] = {index = -1, spawnChance = 2}
	
		VehicleZoneDistribution.farm.vehicles["Base.TrailerM128van"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.farm.vehicles["Base.TrailerM129van"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.farm.vehicles["Base.82oshkoshM911"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.farm.vehicles["Base.82oshkoshM911B"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.ranger.vehicles["Base.TrailerM129van"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.ranger.vehicles["Base.82oshkoshM911B"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.fossoil.vehicles["Base.82oshkoshM911"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.fossoil.vehicles["Base.82oshkoshM911B"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.fossoil.vehicles["Base.TrailerM967tanker"] = {index = -1, spawnChance = 10}

		VehicleZoneDistribution.trafficjams.vehicles["Base.82oshkoshM911"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.82oshkoshM911Burnt"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82oshkoshM911Burnt"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82oshkoshM911Burnt"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82oshkoshM911Burnt"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerM127stake"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.TrailerM128van"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerM129van"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.TrailerM747lowbed"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerM967tanker"] = nil
	end


	if activatedMods:contains("92amgeneralM998") then --2642541073
		VehicleZoneDistribution.parkingstall.vehicles["Base.92amgeneralM998"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["Base.TrailerM101A3cargo"] = nil

		VehicleZoneDistribution.trailerpark.vehicles["Base.92amgeneralM998"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerM101A3cargo"] = nil

		VehicleZoneDistribution.bad.vehicles["Base.92amgeneralM998"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.92amgeneralM998"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.92amgeneralM998Burnt"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.92amgeneralM998"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.92amgeneralM998Burnt"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerM101A3cargo"] = nil
	end


	if activatedMods:contains("59meteor") then --2772575623
		VehicleZoneDistribution.bad.vehicles["Base.59meteor"] = nil

		VehicleZoneDistribution.ambulance.vehicles["Base.59ambulance"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.59meteor"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.59meteor"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.59meteor"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.59meteor"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.59meteor"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("78amgeneralM35A2") then --2799152995
		VehicleZoneDistribution.parkingstall.vehicles["Base.78amgeneralM35A2"] = nil

		VehicleZoneDistribution.trailerpark.vehicles["Base.78amgeneralM35A2"] = nil

		VehicleZoneDistribution.bad.vehicles["Base.78amgeneralM35A2"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.78amgeneralM35A2"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.78amgeneralM35A2"] = nil
	end


	if activatedMods:contains("78amgeneralM49A2C") then --2799152995
		VehicleZoneDistribution.parkingstall.vehicles["Base.78amgeneralM49A2C"] = nil

		VehicleZoneDistribution.trailerpark.vehicles["Base.78amgeneralM49A2C"] = nil

		VehicleZoneDistribution.bad.vehicles["Base.78amgeneralM49A2C"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.78amgeneralM49A2C"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.78amgeneralM49A2C"] = nil
	end


	if activatedMods:contains("78amgeneralM50A3") then --2799152995
		VehicleZoneDistribution.parkingstall.vehicles["Base.78amgeneralM50A3"] = nil

		VehicleZoneDistribution.trailerpark.vehicles["Base.78amgeneralM50A3"] = nil

		VehicleZoneDistribution.bad.vehicles["Base.78amgeneralM50A3"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.78amgeneralM50A3"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.78amgeneralM50A3"] = nil
	end


	if activatedMods:contains("78amgeneralM62") then --2799152995
		VehicleZoneDistribution.parkingstall.vehicles["Base.78amgeneralM62"] = nil

		VehicleZoneDistribution.trailerpark.vehicles["Base.78amgeneralM62"] = nil

		VehicleZoneDistribution.bad.vehicles["Base.78amgeneralM62"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.78amgeneralM62"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.78amgeneralM62"] = nil
	end


	if activatedMods:contains("84merc") then --2805630347
		VehicleZoneDistribution.trailerpark.vehicles["Base.84mercLWB2"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.84mercSWB"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84mercLWB2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84mercLWB2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84mercLWB2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84mercLWB2"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84mercLWB4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84mercLWB4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84mercLWB4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84mercLWB4"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84mercLWB4M"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84mercLWB4M"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84mercLWB4M"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84mercLWB4M"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.84mercLWB2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.84mercLWB4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.84mercLWB4M"] = {index = -1, spawnChance = 3}
	end

	if activatedMods:contains("83amgeneralM923") then --2811383142
		VehicleZoneDistribution.parkingstall.vehicles["Base.83amgeneralM923"] = nil

		VehicleZoneDistribution.trailerpark.vehicles["Base.83amgeneralM923"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.83amgeneralM923"] = nil
	end


	if activatedMods:contains("92nissanGTR") then --2846036306
		VehicleZoneDistribution.trailerpark.vehicles["Base.92nissanGTRlhd"] = nil

		VehicleZoneDistribution.bad.vehicles["Base.92nissanGTR"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.92nissanGTRlhd"] = nil

		VehicleZoneDistribution.medium.vehicles["Base.92nissanGTRlhd"] = nil

		VehicleZoneDistribution.good.vehicles["Base.92nissanGTRlhd"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjams.vehicles["Base.92nissanGTR"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.92nissanGTRlhd"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.92nissanGTR"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.92nissanGTR"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.92nissanGTR"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.92nissanGTR"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.92nissanGTR"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("86fordE150") then --2870394916
		VehicleZoneDistribution.trafficjamn.vehicles["Base.86fordE150"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.86fordE150"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.86fordE150"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.86fordE150"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.86fordE150"] = {index = -1, spawnChance = 3}
	
--		if activatedMods:contains("86fordE150dnd") then
--
--		end

--		if activatedMods:contains("86fordE150mm") then
--
--		end

--		if activatedMods:contains("86fordE150pd") then
--
--		end

		if activatedMods:contains("86fordE150expanded") then
			VehicleZoneDistribution.trafficjamn.vehicles["Base.86fordE150slide"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.86fordE150slide"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.86fordE150slide"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.86fordE150slide"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.86fordE150long"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.86fordE150long"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.86fordE150long"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.86fordE150long"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.86fordE150longW"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.86fordE150longW"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.86fordE150longW"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.86fordE150longW"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.86fordE150med"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.86fordE150med"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.86fordE150med"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.86fordE150med"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.86fordE150so"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.86fordE150so"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.86fordE150so"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.86fordE150so"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.junkyard.vehicles["Base.86fordE150slide"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.86fordE150long"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.86fordE150longW"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.86fordE150med"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.86fordE150so"] = {index = -1, spawnChance = 3}
		end

	end


	if activatedMods:contains("70dodge") then --2873290424
		VehicleZoneDistribution.good.vehicles["Base.70dodgeRT"] = nil
		VehicleZoneDistribution.good.vehicles["Base.70dodgeTA"] = nil
		VehicleZoneDistribution.medium.vehicles["Base.70dodgeRT"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.medium.vehicles["Base.70dodgeTA"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.sport.vehicles["Base.70dodgeRT"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.sport.vehicles["Base.70dodgeTA"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.70dodgePD"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.70dodgePD"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70dodgeRT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70dodgeRT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70dodgeRT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70dodgeRT"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70dodgeTA"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70dodgeTA"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70dodgeTA"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70dodgeTA"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.70dodgeRT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.70dodgeTA"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("82jeepJ10") then --2886832257
		VehicleZoneDistribution.good.vehicles["Base.82jeepJ10"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.medium.vehicles["Base.82jeepJ10"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.82jeepJ10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82jeepJ10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82jeepJ10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82jeepJ10"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.82jeepJ10"] = {index = -1, spawnChance = 3}

--		if activatedMods:contains("82jeepJ10t") then
--
--		end

	end


	if activatedMods:contains("88chevyS10") then --2886832936
		VehicleZoneDistribution.trailerpark.vehicles["Base.88chevyS10"] = nil

		VehicleZoneDistribution.good.vehicles["Base.88chevyS10"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.medium.vehicles["Base.88chevyS10"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.88chevyS10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.88chevyS10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.88chevyS10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.88chevyS10"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.88chevyS10"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("89fordBronco") then --2886833398
		VehicleZoneDistribution.trailerpark.vehicles["Base.89fordBronco"] = nil

		VehicleZoneDistribution.good.vehicles["Base.89fordBronco"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.medium.vehicles["Base.89fordBronco"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89fordBronco"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89fordBronco"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89fordBronco"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89fordBronco"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.89fordBronco"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("70barracuda") then --2913633066
		VehicleZoneDistribution.good.vehicles["Base.70barracuda"] = nil
		VehicleZoneDistribution.good.vehicles["Base.70cuda"] = nil
		VehicleZoneDistribution.good.vehicles["Base.70barracudaAAR"] = nil
		VehicleZoneDistribution.medium.vehicles["Base.70barracuda"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.medium.vehicles["Base.70cuda"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.medium.vehicles["Base.70barracudaAAR"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.sport.vehicles["Base.70barracuda"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.sport.vehicles["Base.70cuda"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.sport.vehicles["Base.70barracudaAAR"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70barracuda"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70barracuda"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70barracuda"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70barracuda"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70cuda"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70cuda"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70cuda"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70cuda"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70barracudaAAR"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70barracudaAAR"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70barracudaAAR"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70barracudaAAR"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.70barracuda"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.70cuda"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.70barracudaAAR"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("93townCar") then --2932547723
		VehicleZoneDistribution.good.vehicles["Base.93townCarLimo"] = nil
	
		VehicleZoneDistribution.trafficjamn.vehicles["Base.93townCar"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93townCar"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93townCar"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93townCar"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.93townCar"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("89trooper") then --2932549988
		VehicleZoneDistribution.trailerpark.vehicles["Base.89trooperRS"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.89trooperOP"] = nil

		VehicleZoneDistribution.good.vehicles["Base.89trooper"] = {index = -1, spawnChance = 4}
		VehicleZoneDistribution.good.vehicles["Base.89trooperOP"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89trooper"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89trooper"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89trooper"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89trooper"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89trooperRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89trooperRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89trooperRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89trooperRS"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89trooperOP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89trooperOP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89trooperOP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89trooperOP"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.89trooper"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.89trooperRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.89trooperOP"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("69mini") then --2937786633
		VehicleZoneDistribution.good.vehicles["Base.69mini"] = nil
		VehicleZoneDistribution.good.vehicles["Base.69miniUnionJack"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.69mini"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.69mini"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.69mini"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.69mini"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.69mini"] = {index = -1, spawnChance = 3}

--		if activatedMods:contains("69mini_ItalianJob") then
--
--		end

--		if activatedMods:contains("69mini_MrBean") then
--
--		end

--		if activatedMods:contains("69mini_PitbullSpecial") then
--
--		end

	end


	if activatedMods:contains("90pierceArrow") then --2942793445
		VehicleZoneDistribution.fire.vehicles["Base.90pierceArrow"] = { index = -1, spawnChance = 50 }

		VehicleZoneDistribution.trailerpark.vehicles["Base.90pierceArrow"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.90pierceArrow"] = nil
	end


	if activatedMods:contains("90fordF350ambulance") then --2952802178
		VehicleZoneDistribution.ambulance.vehicles["Base.90fordF350SWAT"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.90fordF350ambulance"] = nil

		VehicleZoneDistribution.fire.vehicles["Base.90fordF350ambulance"] = nil
		VehicleZoneDistribution.fire.vehicles["Base.90fordF350SWAT"] = nil

		VehicleZoneDistribution.prison.vehicles["Base.90fordF350SWAT"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjams.vehicles["Base.90fordF350SWAT"] = nil
	end


	if activatedMods:contains("92fordCVPI") then --2962175696
		VehicleZoneDistribution.prison.vehicles["Base.92fordCVPI"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.prison.vehicles["Base.92fordCVPI2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.prison.vehicles["Base.92fordCVPIunmarked"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.prison.vehicles["Base.92fordCVPIpdu"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.prison.vehicles["Base.92fordCVPI2sup"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.prison.vehicles["Base.92fordCVPI2so"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.medium.vehicles["Base.92fordCV"] = nil
		VehicleZoneDistribution.medium.vehicles["Base.92fordCVPItaxi"] = nil

		VehicleZoneDistribution.good.vehicles["Base.92fordCVPIunmarked"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.92fordCV"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.92fordCV"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.92fordCV"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.92fordCV"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.92fordCVPItaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.92fordCVPItaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.92fordCVPItaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.92fordCVPItaxi"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.92fordCV"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.92fordCVPItaxi"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("93fordElgin") then --2969343830
		VehicleZoneDistribution.parkingstall.vehicles["Base.93fordElgin"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.93fordElgin"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.93fordElgin"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.93fordElgin"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordElgin"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.fire.vehicles["Base.93fordElgin"] = nil

		VehicleZoneDistribution.advertising.vehicles["Base.93fordElgin"] = {index = -1, spawnChance = 20}
		VehicleZoneDistribution.transit.vehicles["Base.93fordElgin"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.mccoy.vehicles["Base.93fordElgin"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.fossoil.vehicles["Base.93fordElgin"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("69camaro") then --2991201484
		VehicleZoneDistribution.good.vehicles["Base.69camaroRS"] = nil
		VehicleZoneDistribution.good.vehicles["Base.69camaroSS"] = nil
		VehicleZoneDistribution.medium.vehicles["Base.69camaroRS"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.medium.vehicles["Base.69camaroSS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.bad.vehicles["Base.69camaroRS"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.bad.vehicles["Base.69camaroSS"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.69camaroSS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.69camaroSS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.69camaroSS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.69camaroSS"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.69camaroRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.69camaroRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.69camaroRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.69camaroRS"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.69camaroSS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.69camaroRS"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("93mustangSSP") then --3001592312
		VehicleZoneDistribution.prison.vehicles["Base.93mustangSSPksp"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.prison.vehicles["Base.93mustangSSPunmarked"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.prison.vehicles["Base.93mustangSSPkspCol"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93mustangSSP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93mustangSSP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93mustangSSP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93mustangSSP"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93mustangGT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93mustangGT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93mustangGT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93mustangGT"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93mustangSVTcobraR"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93mustangSVTcobraR"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93mustangSVTcobraR"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93mustangSVTcobraR"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.93mustangSSP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.93mustangGT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.93mustangSVTcobraR"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("63beetle") then --3005903549
		VehicleZoneDistribution.good.vehicles["Base.63beetleHP"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.farm.vehicles["Base.63beetleBuggy"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.bad.vehicles["Base.63beetleBuggy"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.63beetle"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.63beetle"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.63beetle"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.63beetle"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.63beetle"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("91geoMetro") then --3008795514
		VehicleZoneDistribution.medium.vehicles["Base.91geoMetro"] = nil
		
		VehicleZoneDistribution.trailerpark.vehicles["Base.91geoMetro"] = {index = -1, spawnChance = 4}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91geoMetro"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91geoMetro"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91geoMetro"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91geoMetro"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.91geoMetro"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("67gt500") then --3026723485
		VehicleZoneDistribution.good.vehicles["Base.67gt500"] = nil
		VehicleZoneDistribution.good.vehicles["Base.67gt500e"] = nil
		VehicleZoneDistribution.sport.vehicles["Base.67gt500"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.sport.vehicles["Base.67gt500e"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.67gt500"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.67gt500"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.67gt500"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.67gt500"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.67gt500e"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.67gt500e"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.67gt500e"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.67gt500e"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.67gt500"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.67gt500e"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("89dodgeCaravan") then --3034636011
		VehicleZoneDistribution.trafficjamn.vehicles["Base.89dodgeCaravan"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89dodgeCaravan"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89dodgeCaravan"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89dodgeCaravan"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89dodgeCaravanLE"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89dodgeCaravanLE"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89dodgeCaravanLE"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89dodgeCaravanLE"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89dodgeCaravanNomad"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89dodgeCaravanNomad"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89dodgeCaravanNomad"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89dodgeCaravanNomad"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.89dodgeCaravan"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.89dodgeCaravanLE"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.89dodgeCaravanNomad"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("63Type2Van") then --3041122351
		VehicleZoneDistribution.trailerpark.vehicles["Base.63Type2VanMilitary"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trailerpark.vehicles["Base.63Type2VanHippie"] = {index = -1, spawnChance = 3}
		
		VehicleZoneDistribution.trafficjams.vehicles["Base.63Type2VanMilitary"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.63Type2Van"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.63Type2Van"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.63Type2Van"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.63Type2Van"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.63Type2Van"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("87toyotaMR2") then --3052360250
		VehicleZoneDistribution.trafficjamn.vehicles["Base.87toyotaMR2"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87toyotaMR2"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87toyotaMR2"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87toyotaMR2"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.87toyotaMR2c"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87toyotaMR2c"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87toyotaMR2c"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87toyotaMR2c"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.87toyotaMR2"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.87toyotaMR2c"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("93fordF350") then --3073430075
		VehicleZoneDistribution.bad.vehicles["Base.93fordF350"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF350fd"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF350pd"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF350so"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF350utility"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF350utilityDpw"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93fordF150"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF150"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93fordF150"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93fordF150"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93fordF150S"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF150S"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93fordF150S"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93fordF150S"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93fordF250"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF250"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93fordF250"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93fordF250"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93fordF350"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF350"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93fordF350"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93fordF350"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93fordF350dually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordF350dually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93fordF350dually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93fordF350dually"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.93fordF150"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.93fordF150S"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.93fordF250"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.93fordF350"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.93fordF350dually"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("93fordTaurus") then --3088951320
		VehicleZoneDistribution.trafficjamn.vehicles["Base.93fordTaurus"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordTaurus"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93fordTaurus"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93fordTaurus"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93fordTaurusSHO"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordTaurusSHO"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93fordTaurusSHO"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93fordTaurusSHO"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93fordTaurusWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93fordTaurusWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93fordTaurusWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93fordTaurusWagon"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.93fordTaurus"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.93fordTaurusSHO"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.93fordTaurusWagon"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("87fordB700") then --3110911330
		VehicleZoneDistribution.parkingstall.vehicles["Base.87fordB700school"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["Base.87fordF700box"] = nil

		VehicleZoneDistribution.trailerpark.vehicles["Base.87fordB700military"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.87fordF700box"] = nil

		VehicleZoneDistribution.prison.vehicles["Base.87fordF700swat"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.prison.vehicles["Base.87fordB700prison"] = nil

		VehicleZoneDistribution.ranger.vehicles["Base.87fordF700swat"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.87fordB700school"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.junkyard.vehicles["Base.87fordB700military"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.87fordF700box"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjams.vehicles["Base.87fordB700military"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.87fordB700prison"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.87fordF700swat"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.87fordF700bank"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87fordF700bank"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87fordF700bank"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87fordF700bank"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.87fordB700school"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87fordB700school"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87fordB700school"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87fordB700school"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.87fordF700box"] = {index = -1, spawnChance = 30}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87fordF700box"] = {index = -1, spawnChance = 30}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87fordF700box"] = {index = -1, spawnChance = 30}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87fordF700box"] = {index = -1, spawnChance = 30}
	end


	if activatedMods:contains("90bmwE30") then --3110913021
		VehicleZoneDistribution.trafficjamn.vehicles["Base.90bmwE30cabrio"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.90bmwE30cabrio"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.90bmwE30cabrio"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.90bmwE30cabrio"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.90bmwE30m3"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.90bmwE30m3"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.90bmwE30m3"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.90bmwE30m3"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.90bmwE30sedan2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.90bmwE30sedan2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.90bmwE30sedan2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.90bmwE30sedan2"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.90bmwE30sedan4"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.90bmwE30sedan4"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.90bmwE30sedan4"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.90bmwE30sedan4"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.90bmwE30touring"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.90bmwE30touring"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.90bmwE30touring"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.90bmwE30touring"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.90bmwE30cabrio"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.90bmwE30m3"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.90bmwE30sedan2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.90bmwE30sedan4"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.90bmwE30touring"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("93chevySuburban") then --3152529790
		VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySuburbanpd"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySuburbanpdu"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySuburban"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.93chevySuburban"] = {index = -1, spawnChance = 3}

		if activatedMods:contains("93chevySuburbanExpanded") then
			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoCCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoCCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoCCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoCCdually"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoCClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoCClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoCClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoCClong"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoSC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoSC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoSC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoSC"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoSClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoSClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoSClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoSClong"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoXC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoXC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoXC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoXC"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoXClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoXClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoXClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoXClong"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoSCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoSCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoSCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoSCdually"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoCC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoCC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoCC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoCC"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoXCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoXCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoXCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoXCdually"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySuburbanDually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySuburbanDually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySuburbanDually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySuburbanDually"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoK3500flatbed"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoK3500flatbed"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoK3500flatbed"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoK3500flatbed"] = {index = -1, spawnChance = 3}

			VehicleZoneDistribution.trafficjamn.vehicles["Base.93chevySilveradoK3500wrecker"] = {index = -1, spawnChance = 1}
			VehicleZoneDistribution.trafficjams.vehicles["Base.93chevySilveradoK3500wrecker"] = {index = -1, spawnChance = 1}
			VehicleZoneDistribution.trafficjamw.vehicles["Base.93chevySilveradoK3500wrecker"] = {index = -1, spawnChance = 1}
			VehicleZoneDistribution.trafficjame.vehicles["Base.93chevySilveradoK3500wrecker"] = {index = -1, spawnChance = 1}

			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoCCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoCClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoSC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoSClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoXC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoXClong"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoSCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoCC"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoXCdually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySuburbanDually"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoK3500flatbed"] = {index = -1, spawnChance = 3}
			VehicleZoneDistribution.junkyard.vehicles["Base.93chevySilveradoK3500wrecker"] = {index = -1, spawnChance = 1}
		end

	end


	if activatedMods:contains("76chevyKseries") then --3161951724
		VehicleZoneDistribution.medium.vehicles["Base.76chevyK20BigRed"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.medium.vehicles["Base.76chevyK10spirit"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.bad.vehicles["Base.76chevyK10"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.bad.vehicles["Base.76chevyK20"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyK10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyK10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyK10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyK10"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyK20"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyK20"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyK20"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyK20"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyK30CC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyK30CC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyK30CC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyK30CC"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyK30CCdually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyK30CCdually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyK30CCdually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyK30CCdually"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyK30SCdually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyK30SCdually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyK30SCdually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyK30SCdually"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyK10spirit"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyK10spirit"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyK10spirit"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyK10spirit"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyC30CCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyC30CCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyC30CCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyC30CCwrecker"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyC30SCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyC30SCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyC30SCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyC30SCwrecker"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyK30CCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyK30CCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyK30CCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyK30CCwrecker"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyK30SCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyK30SCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyK30SCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyK30SCwrecker"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevyK30CCduallyS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevyK30CCduallyS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevyK30CCduallyS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevyK30CCduallyS"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevySuburban"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chevySuburban2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chevySuburban2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chevySuburban2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chevySuburban2"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyK10"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyK20"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyK30CC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyK30CCdually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyK30SCdually"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyK10spirit"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyC30CCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyC30SCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyK30CCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyK30SCwrecker"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevyK30CCduallyS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chevySuburban2"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("87chevySuburban") then --3196180339
		VehicleZoneDistribution.trafficjamn.vehicles["Base.87chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87chevySuburban"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.87chevySuburbanCUCV"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87chevySuburbanCUCV"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87chevySuburbanCUCV"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87chevySuburbanCUCV"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.87chevySuburbanOP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87chevySuburbanOP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87chevySuburbanOP"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87chevySuburbanOP"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.87chevySuburban"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.87chevySuburbanCUCV"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.87chevySuburbanOP"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("75grandPrix") then --3213391371
		VehicleZoneDistribution.trafficjamn.vehicles["Base.75grandPrixSJ"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.75grandPrixSJ"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.75grandPrixSJ"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.75grandPrixSJ"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.75grandPrixLJ"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.75grandPrixLJ"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.75grandPrixLJ"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.75grandPrixLJ"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.75grandPrixHurst"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.75grandPrixHurst"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.75grandPrixHurst"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.75grandPrixHurst"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.75grandPrixSJ"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.75grandPrixLJ"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.75grandPrixHurst"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("87buickRegal") then --3226885926
		VehicleZoneDistribution.trafficjamn.vehicles["Base.87buickRegalTurboT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87buickRegalTurboT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87buickRegalTurboT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87buickRegalTurboT"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.87buickRegalGNX"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.87buickRegalGNX"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.87buickRegalGNX"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.87buickRegalGNX"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.87buickRegalTurboT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.87buickRegalGNX"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("80manKat1") then --3248388837
		VehicleZoneDistribution.trailerpark.vehicles["Base.80manKat1"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.80manKat1"] = nil

		VehicleZoneDistribution.police.vehicles["Base.80manKat1"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.fire.vehicles["Base.80manKat1"] = nil

		VehicleZoneDistribution.ambulance.vehicles["Base.80manKat1"] = nil

		VehicleZoneDistribution.ranger.vehicles["Base.80manKat1"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjams.vehicles["Base.80manKat1"] = nil
	end


	if activatedMods:contains("81deloreanDMC12") then --3253385114
		VehicleZoneDistribution.trafficjamn.vehicles["Base.81deloreanDMC12"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.81deloreanDMC12"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.81deloreanDMC12"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.81deloreanDMC12"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.81deloreanDMC12"] = {index = -1, spawnChance = 1}

--		if activatedMods:contains("81deloreanDMC12BTTF") then
--
--		end

	end


	if activatedMods:contains("68firebird") then --3258343790
		VehicleZoneDistribution.good.vehicles["Base.68firebird400"] = nil
		VehicleZoneDistribution.good.vehicles["Base.68firebirdRamAir"] = nil
		VehicleZoneDistribution.medium.vehicles["Base.68firebird400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.medium.vehicles["Base.68firebirdRamAir"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.bad.vehicles["Base.68firebird350"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.68firebird350"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.68firebird350"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.68firebird350"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.68firebird350"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.68firebird400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.68firebird400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.68firebird400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.68firebird400"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.68firebirdRamAir"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.68firebirdRamAir"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.68firebirdRamAir"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.68firebirdRamAir"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.68firebirdRamAirCustom"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.68firebirdRamAirCustom"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.68firebirdRamAirCustom"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.68firebirdRamAirCustom"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.68firebird350"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.68firebird400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.68firebirdRamAir"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.68firebirdRamAirCustom"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("92jeepYJ") then --3287727378
		VehicleZoneDistribution.trafficjamn.vehicles["Base.92jeepYJs"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.92jeepYJs"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.92jeepYJs"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.92jeepYJs"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.92jeepYJse"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.92jeepYJse"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.92jeepYJse"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.92jeepYJse"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.92jeepYJranger"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.92jeepYJranger"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.92jeepYJranger"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.92jeepYJranger"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.92jeepYJs"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.92jeepYJse"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.92jeepYJranger"] = {index = -1, spawnChance = 3}

--		if activatedMods:contains("92jeepYJJP18") then
--	
--		end

	end


	if activatedMods:contains("89volvo200") then --3292659291
		VehicleZoneDistribution.medium.vehicles["Base.89volvo244sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.medium.vehicles["Base.89volvo245wagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.good.vehicles["Base.89volvo242turbo"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89volvo242turbo"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89volvo242turbo"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89volvo242turbo"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89volvo242turbo"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89volvo244sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89volvo244sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89volvo244sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89volvo244sedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89volvo245wagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89volvo245wagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89volvo245wagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89volvo245wagon"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.89volvo242turbo"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.89volvo244sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.89volvo245wagon"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("82firebird") then --3320947974
		VehicleZoneDistribution.trafficjamn.vehicles["Base.82firebird"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82firebird"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82firebird"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82firebird"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.82firebirdSE"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82firebirdSE"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82firebirdSE"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82firebirdSE"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.82firebirdTA"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82firebirdTA"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82firebirdTA"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82firebirdTA"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.82firebirdKITT"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82firebirdKITT"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82firebirdKITT"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82firebirdKITT"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.82firebird"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.82firebirdSE"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.82firebirdTA"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.82firebirdKITT"] = {index = -1, spawnChance = 1}

--		if activatedMods:contains("82firebirdKITT") then
--
--		end

	end


	if activatedMods:contains("KI5trailers") then --3330403100
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerKI5utilityLarge"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerKI5utilityMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerKI5utilitySmall"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerKI5cargoLarge"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerKI5cargoMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trailerpark.vehicles["Base.TrailerKI5cargoSmall"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5utilityLarge"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5utilityMedium"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5utilitySmall"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5cargoLarge"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5cargoMedium"] = nil
		VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5cargoSmall"] = nil

		VehicleZoneDistribution.trafficjame.vehicles["Base.TrailerKI5utilityLarge"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.TrailerKI5utilityMedium"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerKI5utilitySmall"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.TrailerKI5cargoLarge"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerKI5cargoMedium"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.TrailerKI5cargoSmall"] = nil
		
		VehicleZoneDistribution.ranger.vehicles["Base.TrailerKI5utilityLarge"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.ranger.vehicles["Base.TrailerKI5utilityMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.ranger.vehicles["Base.TrailerKI5utilitySmall"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.ranger.vehicles["Base.TrailerKI5cargoLarge"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.ranger.vehicles["Base.TrailerKI5cargoMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.ranger.vehicles["Base.TrailerKI5cargoSmall"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.mccoy.vehicles["Base.TrailerKI5utilityLarge"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.mccoy.vehicles["Base.TrailerKI5utilityMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.mccoy.vehicles["Base.TrailerKI5utilitySmall"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.mccoy.vehicles["Base.TrailerKI5cargoLarge"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.mccoy.vehicles["Base.TrailerKI5cargoMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.mccoy.vehicles["Base.TrailerKI5cargoSmall"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.farm.vehicles["Base.TrailerKI5utilityLarge"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.farm.vehicles["Base.TrailerKI5utilityMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.farm.vehicles["Base.TrailerKI5utilitySmall"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.farm.vehicles["Base.TrailerKI5cargoLarge"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.farm.vehicles["Base.TrailerKI5cargoMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.farm.vehicles["Base.TrailerKI5cargoSmall"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.radio.vehicles["Base.TrailerKI5utilityLarge"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.radio.vehicles["Base.TrailerKI5utilityMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.radio.vehicles["Base.TrailerKI5utilitySmall"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.radio.vehicles["Base.TrailerKI5cargoLarge"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.radio.vehicles["Base.TrailerKI5cargoMedium"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.radio.vehicles["Base.TrailerKI5cargoSmall"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerKI5utilityLarge"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerKI5utilityMedium"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerKI5utilitySmall"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerKI5cargoLarge"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerKI5cargoMedium"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerKI5cargoSmall"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("77firebird") then --3346905070
		VehicleZoneDistribution.trafficjamn.vehicles["Base.77firebird"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.77firebird"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.77firebird"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.77firebird"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.77firebirdES"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.77firebirdES"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.77firebirdES"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.77firebirdES"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.77firebirdFR"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.77firebirdFR"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.77firebirdFR"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.77firebirdFR"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.77firebirdTA"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.77firebirdTA"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.77firebirdTA"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.77firebirdTA"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.77firebird"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.77firebirdES"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.77firebirdFR"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.77firebirdTA"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("91fordLTD") then --3366300557
		VehicleZoneDistribution.junkyard.vehicles["Base.91fordLTDpd"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.91fordLTDunmarked"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordLTDpd"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordLTDunmarked"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91fordLTD"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordLTD"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91fordLTD"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91fordLTD"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91fordLTDwagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordLTDwagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91fordLTDwagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91fordLTDwagon"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91fordLTDtaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordLTDtaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91fordLTDtaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91fordLTDtaxi"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91fordLTDranger"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordLTDranger"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91fordLTDranger"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91fordLTDranger"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.91fordLTD"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.91fordLTDwagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.91fordLTDtaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.91fordLTDranger"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("82porsche911") then --3379334330
		VehicleZoneDistribution.trafficjamn.vehicles["Base.82porsche911turbo"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82porsche911turbo"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82porsche911turbo"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82porsche911turbo"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.82porsche911rwb"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82porsche911rwb"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82porsche911rwb"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82porsche911rwb"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.82porsche911sc"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82porsche911sc"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82porsche911sc"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82porsche911sc"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.82porsche911targa"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.82porsche911targa"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.82porsche911targa"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.82porsche911targa"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.82porsche911turbo"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.82porsche911rwb"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.82porsche911sc"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.82porsche911targa"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("84jeepXJ") then --3409287192
		VehicleZoneDistribution.junkyard.vehicles["Base.84jeepXJpd"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.84jeepXJpd"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.84jeepXJksp"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84jeepXJ2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84jeepXJ2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84jeepXJ2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84jeepXJ2"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84jeepXJ4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84jeepXJ4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84jeepXJ4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84jeepXJ4"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84jeepXJranger"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84jeepXJranger"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84jeepXJranger"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84jeepXJranger"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.84jeepXJ2"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.84jeepXJ4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.84jeepXJranger"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("85chevyCaprice") then --3413704851
		VehicleZoneDistribution.trailerpark.vehicles["Base.85chevyCapriceSedan"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.bad.vehicles["Base.85chevyCapriceSedan"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85chevyCapriceSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85chevyCapriceSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85chevyCapriceSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85chevyCapriceSedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85chevyImpalaSedanRanger"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85chevyImpalaSedanRanger"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85chevyImpalaSedanRanger"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85chevyImpalaSedanRanger"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85chevyImpalaSedanTaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85chevyImpalaSedanTaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85chevyImpalaSedanTaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85chevyImpalaSedanTaxi"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85chevyCapriceCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85chevyCapriceCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85chevyCapriceCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85chevyCapriceCoupe"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85chevyCapriceWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85chevyCapriceWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85chevyCapriceWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85chevyCapriceWagon"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85chevyCapriceWagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85chevyCapriceWagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85chevyCapriceWagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85chevyCapriceWagon2"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.85chevyCapriceSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85chevyImpalaSedanRanger"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.85chevyImpalaSedanTaxi"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.85chevyCapriceCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85chevyCapriceWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85chevyCapriceWagon2"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("85pontiacParisienne") then --3413706334
		VehicleZoneDistribution.trailerpark.vehicles["Base.85pontiacParisienneSedan"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.bad.vehicles["Base.85pontiacParisienneSedan"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85pontiacParisienneSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85pontiacParisienneSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85pontiacParisienneSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85pontiacParisienneSedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85pontiacParisienneWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85pontiacParisienneWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85pontiacParisienneWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85pontiacParisienneWagon"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85pontiacParisienneWagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85pontiacParisienneWagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85pontiacParisienneWagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85pontiacParisienneWagon2"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.85pontiacParisienneSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85pontiacParisienneWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85pontiacParisienneWagon2"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("85buickLeSabre") then --3418252689
		VehicleZoneDistribution.trailerpark.vehicles["Base.85buickLeSabreSedan"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.bad.vehicles["Base.85buickLeSabreSedan"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85buickLeSabreSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85buickLeSabreSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85buickLeSabreSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85buickLeSabreSedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85buickLeSabreCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85buickLeSabreCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85buickLeSabreCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85buickLeSabreCoupe"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85buickLeSabreWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85buickLeSabreWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85buickLeSabreWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85buickLeSabreWagon"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85buickLeSabreWagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85buickLeSabreWagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85buickLeSabreWagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85buickLeSabreWagon2"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.85buickLeSabreSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85buickLeSabreCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85buickLeSabreWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85buickLeSabreWagon2"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("85oldsmobileDelta88") then --3418253716
		VehicleZoneDistribution.trailerpark.vehicles["Base.85oldsmobileDelta88Sedan"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.bad.vehicles["Base.85oldsmobileDelta88Sedan"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85oldsmobileDelta88Sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85oldsmobileDelta88Sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85oldsmobileDelta88Sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85oldsmobileDelta88Sedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85oldsmobileDelta88Coupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85oldsmobileDelta88Coupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85oldsmobileDelta88Coupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85oldsmobileDelta88Coupe"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85oldsmobileDelta88Wagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85oldsmobileDelta88Wagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85oldsmobileDelta88Wagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85oldsmobileDelta88Wagon"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.85oldsmobileDelta88Wagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85oldsmobileDelta88Wagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85oldsmobileDelta88Wagon2"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85oldsmobileDelta88Wagon2"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.85oldsmobileDelta88Sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85oldsmobileDelta88Coupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85oldsmobileDelta88Wagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.85oldsmobileDelta88Wagon2"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("86chevyCUCV") then --3428008364
		VehicleZoneDistribution.ambulance.vehicles["Base.86chevyM1010"] = nil

		VehicleZoneDistribution.fire.vehicles["Base.86chevyM1031"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.86chevyM1031"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.TrailerM101A2cargo"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.86chevyM1008"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.86chevyM1009"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.86chevyK5pd"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.86chevyK5ksp"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.86chevyK5blazer"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.86chevyK5blazer"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.86chevyK5blazer"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.86chevyK5blazer"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.86chevyK5blazer"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("88toyotaHilux") then --3435796523
		VehicleZoneDistribution.trafficjamn.vehicles["Base.88toyotaHiluxSC"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.88toyotaHiluxSC"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.88toyotaHiluxSC"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.88toyotaHiluxSC"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.88toyotaHiluxXC"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.88toyotaHiluxXC"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.88toyotaHiluxXC"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.88toyotaHiluxXC"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.88toyotaHiluxXCS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.88toyotaHiluxXCS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.88toyotaHiluxXCS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.88toyotaHiluxXCS"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.88toyotaHiluxSC"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.88toyotaHiluxXC"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.88toyotaHiluxXCS"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("66pontiacLeMans") then --3447272250
		VehicleZoneDistribution.good.vehicles["Base.66pontiacLeMans"] = nil
		VehicleZoneDistribution.good.vehicles["Base.66pontiacLeMansConv"] = nil
		VehicleZoneDistribution.medium.vehicles["Base.66pontiacLeMans"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.bad.vehicles["Base.66pontiacLeMans"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trailerpark.vehicles["Base.66pontiacLeMans"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.66pontiacLeMans"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.66pontiacLeMans"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.66pontiacLeMans"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.66pontiacLeMans"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.66pontiacLeMansConv"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.66pontiacLeMansConv"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.66pontiacLeMansConv"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.66pontiacLeMansConv"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.66pontiacGTO"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.66pontiacGTO"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.66pontiacGTO"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.66pontiacGTO"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.66pontiacGTOconv"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.66pontiacGTOconv"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.66pontiacGTOconv"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.66pontiacGTOconv"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.66pontiacLeMans"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.66pontiacLeMansConv"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.66pontiacGTO"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.66pontiacGTOconv"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("73fordFalcon") then --3490370700
		VehicleZoneDistribution.good.vehicles["Base.73fordFalconXBGT"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.73fordFalconXBGT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.73fordFalconXBGT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.73fordFalconXBGT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.73fordFalconXBGT"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.73fordFalconXBGTlhd"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.73fordFalconXBGTlhd"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.73fordFalconXBGTlhd"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.73fordFalconXBGTlhd"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.73fordFalconPSlhd"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.73fordFalconPSlhd"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.73fordFalconPSlhd"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.73fordFalconPSlhd"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.73fordFalconXBGT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.73fordFalconXBGTlhd"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.73fordFalconPSlhd"] = {index = -1, spawnChance = 3}
--		if activatedMods:contains("73fordFalconPS") then
--
--		end

	end

	
	if activatedMods:contains("91nissan240sx") then --3504401781
		VehicleZoneDistribution.trafficjamn.vehicles["Base.91nissan240sx"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91nissan240sx"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91nissan240sx"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91nissan240sx"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91nissan240sx2"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91nissan240sx2"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91nissan240sx2"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91nissan240sx2"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.91nissan240sx"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.91nissan240sx2"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("91fordRanger") then --3539691958
		VehicleZoneDistribution.trafficjamn.vehicles["Base.91fordRangerSC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordRangerSC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91fordRangerSC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91fordRangerSC"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91fordRangerSClong"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordRangerSClong"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91fordRangerSClong"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91fordRangerSClong"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91fordRangerXC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordRangerXC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91fordRangerXC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91fordRangerXC"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91fordRangerXClong"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordRangerXClong"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91fordRangerXClong"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91fordRangerXClong"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.91fordRangerRanger"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91fordRangerRanger"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91fordRangerRanger"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91fordRangerRanger"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.91fordRangerSC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.91fordRangerSClong"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.91fordRangerXC"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.91fordRangerXClong"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.91fordRangerRanger"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("65banshee") then --3566868353
		VehicleZoneDistribution.trafficjams.vehicles["Base.65bansheeSprint"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.65bansheeXP"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.65bansheeSprint"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.65bansheeSprint"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.65bansheeSprint"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.65bansheeSprint"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.65banshee400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.65banshee400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.65banshee400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.65banshee400"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.65bansheeXP"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.65bansheeXP"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.65bansheeXP"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.65bansheeXP"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.65bansheeSprint"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.65banshee400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.65bansheeXP"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("89defender") then --3570973322
		VehicleZoneDistribution.trafficjamn.vehicles["Base.89defender90"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89defender90"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89defender90"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89defender90"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89defender90utility"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89defender90utility"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89defender90utility"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89defender90utility"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89defender110"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89defender110"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89defender110"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89defender110"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89defender110utility"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89defender110utility"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89defender110utility"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89defender110utility"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.89defender130"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.89defender130"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.89defender130"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.89defender130"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.89defender90"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.89defender90utility"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.89defender110"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.89defender110utility"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.89defender130"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("84cadillacDeVille") then --3592777775
		VehicleZoneDistribution.medium.vehicles["Base.84cadillacDeVilleSedan"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.medium.vehicles["Base.84cadillacDeVilleCoupe"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84cadillacDeVilleSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84cadillacDeVilleSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84cadillacDeVilleSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84cadillacDeVilleSedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84cadillacDeVilleCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84cadillacDeVilleCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84cadillacDeVilleCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84cadillacDeVilleCoupe"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.84cadillacDeVilleSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.84cadillacDeVilleCoupe"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("84buickElectra") then --3596903773
		VehicleZoneDistribution.trafficjamn.vehicles["Base.84buickElectraSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84buickElectraSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84buickElectraSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84buickElectraSedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84buickElectraCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84buickElectraCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84buickElectraCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84buickElectraCoupe"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.84buickElectraSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.84buickElectraCoupe"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("84oldsmobile98") then --3601417745
		VehicleZoneDistribution.trafficjamn.vehicles["Base.84oldsmobile98Sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84oldsmobile98Sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84oldsmobile98Sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84oldsmobile98Sedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84oldsmobile98Coupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84oldsmobile98Coupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84oldsmobile98Coupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84oldsmobile98Coupe"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.84oldsmobile98Sedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.84oldsmobile98Coupe"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("85chevyStepVan") then --3614034284
		VehicleZoneDistribution.trafficjamn.vehicles["Base.85chevyStepVan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.85chevyStepVan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.85chevyStepVan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.85chevyStepVan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.85chevyStepVan"] = {index = -1, spawnChance = 5}

--		if activatedMods:contains("85chevyStepVanexpanded") then --3614034284
--
--		end

	end


	if activatedMods:contains("69charger") then --3631989559
		VehicleZoneDistribution.trailerpark.vehicles["Base.69charger500"] = nil
		VehicleZoneDistribution.parkingstall.vehicles["Base.69charger500"] = {index = -1, spawnChance = 1}
		
		VehicleZoneDistribution.junkyard.vehicles["Base.69chargerDaytona"] = nil
		VehicleZoneDistribution.junkyard.vehicles["Base.69chargerRT"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.69charger500"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.69chargerRT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.69chargerRT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.69chargerRT"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.69chargerRT"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.69charger500"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.69charger500"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.69charger500"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.69charger500"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("70roadRunner") then --3642935062
		VehicleZoneDistribution.bad.vehicles["Base.70roadRunner"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.sport.vehicles["Base.70roadRunner"] = nil
		VehicleZoneDistribution.good.vehicles["Base.70roadRunner"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70roadRunner"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70roadRunner"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70roadRunner"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70roadRunner"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.70roadRunner"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("70fordEscort") then --3670063857
		VehicleZoneDistribution.trafficjamn.vehicles["Base.70fordEscortCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70fordEscortCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70fordEscortCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70fordEscortCoupe"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70fordEscortRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70fordEscortRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70fordEscortRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70fordEscortRS"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70fordEscortSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70fordEscortSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70fordEscortSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70fordEscortSedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70fordEscortWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70fordEscortWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70fordEscortWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70fordEscortWagon"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.70fordEscortCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.70fordEscortRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.70fordEscortSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.70fordEscortWagon"] = {index = -1, spawnChance = 5}
	end


	if activatedMods:contains("KI5campers") then --3670064951
		VehicleZoneDistribution.trafficjamn.vehicles["Base.Trailer87Scamp16"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.Trailer87Scamp16"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.Trailer87Scamp13"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.Trailer87Scamp13"] = nil
		VehicleZoneDistribution.trafficjamn.vehicles["Base.Trailer61Bambi16"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.Trailer61Bambi16"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.Trailer54FlyingCloud22"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.Trailer54FlyingCloud22"] = nil

		VehicleZoneDistribution.farm.vehicles["Base.Trailer87Scamp16"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.farm.vehicles["Base.Trailer87Scamp13"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.farm.vehicles["Base.Trailer54FlyingCloud22"] = {index = -1, spawnChance = 10}
		VehicleZoneDistribution.farm.vehicles["Base.Trailer61Bambi16"] = {index = -1, spawnChance = 10}
	end


	if activatedMods:contains("84corvette") then --3684254299
		VehicleZoneDistribution.parkingstall.vehicles["Base.84corvetteC4"] = nil

		VehicleZoneDistribution.medium.vehicles["Base.93corvetteC4"] = nil

		VehicleZoneDistribution.good.vehicles["Base.84corvetteC4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.good.vehicles["Base.93corvetteC4"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.sport.vehicles["Base.84corvetteC4"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.sport.vehicles["Base.93corvetteC4"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.84corvetteC4"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.84corvetteC4"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.84corvetteC4"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.84corvetteC4"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.93corvetteC4"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.93corvetteC4"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.93corvetteC4"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.93corvetteC4"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.84corvetteC4"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.93corvetteC4"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("79camaro") then --3703948448
		VehicleZoneDistribution.bad.vehicles["Base.79camaro"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.medium.vehicles["Base.79camaro"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.medium.vehicles["Base.79camaroRS"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.good.vehicles["Base.79camaroRS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.good.vehicles["Base.79camaroZ28"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.sport.vehicles["Base.79camaro"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.79camaroGhost"] = nil	

		VehicleZoneDistribution.trafficjamn.vehicles["Base.79camaro"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.79camaro"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.79camaro"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.79camaro"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.79camaroRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.79camaroRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.79camaroRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.79camaroRS"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.79camaroZ28"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.79camaroZ28"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.79camaroZ28"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.79camaroZ28"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.79camaro"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.79camaroRS"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.79camaroZ28"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("78lamboCountach") then --3726526329
		VehicleZoneDistribution.trafficjamn.vehicles["Base.78lamboCountachLP400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.78lamboCountachLP400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.78lamboCountachLP400"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.78lamboCountachLP400"] = {index = -1, spawnChance = 1}
	
		VehicleZoneDistribution.trafficjamn.vehicles["Base.78lamboCountachLP400S"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.78lamboCountachLP400S"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.78lamboCountachLP400S"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.78lamboCountachLP400S"] = nil
	
		VehicleZoneDistribution.trafficjamn.vehicles["Base.78lamboCountachLP400Scb"] = nil
		VehicleZoneDistribution.trafficjams.vehicles["Base.78lamboCountachLP400Scb"] = nil
		VehicleZoneDistribution.trafficjamw.vehicles["Base.78lamboCountachLP400Scb"] = nil
		VehicleZoneDistribution.trafficjame.vehicles["Base.78lamboCountachLP400Scb"] = nil
	end


	if activatedMods:contains("76chryslerNewYorker") then --3730833846
		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chryslerNewYorker"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chryslerNewYorker"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chryslerNewYorker"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chryslerNewYorker"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.76chryslerNewYorkerTPB"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.76chryslerNewYorkerTPB"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.76chryslerNewYorkerTPB"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.76chryslerNewYorkerTPB"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.76chryslerNewYorker"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.junkyard.vehicles["Base.76chryslerNewYorkerTPB"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("73nissanGTR") then --3743371090
		VehicleZoneDistribution.medium.vehicles["Base.73nissanGTR"] = nil
		VehicleZoneDistribution.medium.vehicles["Base.73nissanGTRlhd"] = nil

		VehicleZoneDistribution.good.vehicles["Base.73nissanGTR"] = nil
		VehicleZoneDistribution.good.vehicles["Base.73nissanGTRlhd"] = nil

		VehicleZoneDistribution.sport.vehicles["Base.73nissanGTR"] = {index = -1, spawnChance = 2}
		VehicleZoneDistribution.sport.vehicles["Base.73nissanGTRlhd"] = nil

		VehicleZoneDistribution.trafficjams.vehicles["Base.73nissanGTRlhd"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.73nissanGTRlhd"] = {index = -1, spawnChance = 1}
	end


	if activatedMods:contains("69fordMustang") then --3756938756
		VehicleZoneDistribution.sport.vehicles["Base.69fordMustangBoss302"] = nil

		VehicleZoneDistribution.trailerpark.vehicles["Base.69fordMustangEV6"] = nil
		VehicleZoneDistribution.trailerpark.vehicles["Base.69fordMustangTBC"] = nil

		VehicleZoneDistribution.junkyard.vehicles["Base.69fordMustangUBC"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.69fordMustangEV6"] = nil

		VehicleZoneDistribution.trafficjamn.vehicles["Base.69fordMustangBoss302"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.69fordMustangBoss302"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.69fordMustangBoss302"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.69fordMustangBoss302"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.69fordMustangBoss429"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.69fordMustangBoss429"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.69fordMustangBoss429"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.69fordMustangBoss429"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.69fordMustangMach1"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.69fordMustangMach1"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.69fordMustangMach1"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.69fordMustangMach1"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.junkyard.vehicles["Base.69fordMustangBoss302"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.69fordMustangBoss429"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.69fordMustangMach1"] = {index = -1, spawnChance = 1}

		if activatedMods:contains("69fordMustangExtra") then
			VehicleZoneDistribution.trailerpark.vehicles["Base.69fordMustangEV6"] = {index = -1, spawnChance = 1}
			VehicleZoneDistribution.trailerpark.vehicles["Base.69fordMustangTBC"] = {index = -1, spawnChance = 1}
			VehicleZoneDistribution.trailerpark.vehicles["Base.69fordMustangUBC"] = {index = -1, spawnChance = 1}

			VehicleZoneDistribution.junkyard.vehicles["Base.69fordMustangEV6"] = {index = -1, spawnChance = 1}
			VehicleZoneDistribution.junkyard.vehicles["Base.69fordMustangTBC"] = {index = -1, spawnChance = 1}
			VehicleZoneDistribution.junkyard.vehicles["Base.69fordMustangUBC"] = {index = -1, spawnChance = 1}
		end
	end


	if activatedMods:contains("70chevelle") then --3766571591
		VehicleZoneDistribution.bad.vehicles["Base.70elCamino"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.bad.vehicles["Base.70chevelleWagon"] = {index = -1, spawnChance = 2}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70chevelleCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70chevelleCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70chevelleCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70chevelleCoupe"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70chevelleCoupeSS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70chevelleCoupeSS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70chevelleCoupeSS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70chevelleCoupeSS"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70chevelleCoupeSSL6"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70chevelleCoupeSSL6"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70chevelleCoupeSSL6"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70chevelleCoupeSSL6"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70chevelleSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70chevelleSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70chevelleSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70chevelleSedan"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70chevelleWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70chevelleWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70chevelleWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70chevelleWagon"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70chevelleWagonSS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70chevelleWagonSS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70chevelleWagonSS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70chevelleWagonSS"] = {index = -1, spawnChance = 1}

		VehicleZoneDistribution.trafficjamn.vehicles["Base.70elCamino"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjams.vehicles["Base.70elCamino"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.70elCamino"] = {index = -1, spawnChance = 3}
		VehicleZoneDistribution.trafficjame.vehicles["Base.70elCamino"] = {index = -1, spawnChance = 3}

		VehicleZoneDistribution.junkyard.vehicles["Base.70chevelleCoupe"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.70chevelleCoupeSS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.70chevelleCoupeSSL6"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.70chevelleSedan"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.70chevelleWagon"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.junkyard.vehicles["Base.70chevelleWagonSS"] = {index = -1, spawnChance = 1}
		VehicleZoneDistribution.junkyard.vehicles["Base.70elCamino"] = {index = -1, spawnChance = 3}
	end


	if activatedMods:contains("91lexusLS400") then --3770890864
		VehicleZoneDistribution.trafficjamn.vehicles["Base.91lexusLS400"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjams.vehicles["Base.91lexusLS400"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjamw.vehicles["Base.91lexusLS400"] = {index = -1, spawnChance = 5}
		VehicleZoneDistribution.trafficjame.vehicles["Base.91lexusLS400"] = {index = -1, spawnChance = 5}

		VehicleZoneDistribution.junkyard.vehicles["Base.91lexusLS400"] = {index = -1, spawnChance = 5}
	end

end
Events.OnLoadMapZones.Add(NewVZones.RebalancingAct)
