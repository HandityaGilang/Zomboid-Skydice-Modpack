NewVZones = NewVZones or {}

local smashedVehicles = {}
smashedVehicles["Base.CarLuxurySmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarLuxurySmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarLuxurySmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarLuxurySmashedFront"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.ModernCarSmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.ModernCarSmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.ModernCarSmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.ModernCarSmashedFront"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.ModernCar02SmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.ModernCar02SmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.ModernCar02SmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.ModernCar02SmashedFront"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarNormalSmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarNormalSmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarNormalSmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarNormalSmashedFront"] = {index = -1, spawnChance = 5}
--smashedVehicles["Base.CarLightsSmashedRear"] = {index = -1, spawnChance = 1}
--smashedVehicles["Base.CarLightsSmashedRight"] = {index = -1, spawnChance = 1}
--smashedVehicles["Base.CarLightsSmashedLeft"] = {index = -1, spawnChance = 1}
--smashedVehicles["Base.CarLightsSmashedFront"] = {index = -1, spawnChance = 1}
smashedVehicles["Base.CarSmallSmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarSmallSmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarSmallSmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarSmallSmashedFront"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarSmall02SmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarSmall02SmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarSmall02SmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarSmall02SmashedFront"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarStationWagonSmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarStationWagonSmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarStationWagonSmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.CarStationWagonSmashedFront"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.OffRoadSmashedRear"] = {index = -1, spawnChance = 3}
smashedVehicles["Base.OffRoadSmashedRight"] = {index = -1, spawnChance = 3}
smashedVehicles["Base.OffRoadSmashedLeft"] = {index = -1, spawnChance = 3}
smashedVehicles["Base.OffRoadSmashedFront"] = {index = -1, spawnChance = 3}
smashedVehicles["Base.PickUpTruckSmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.PickUpTruckSmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.PickUpTruckSmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.PickUpTruckSmashedFront"] = {index = -1, spawnChance = 5}
--smashedVehicles["Base.PickUpTruckLightsSmashedRear"] = {index = -1, spawnChance = 1}
--smashedVehicles["Base.PickUpTruckLightsSmashedRight"] = {index = -1, spawnChance = 1}
--smashedVehicles["Base.PickUpTruckLightsSmashedLeft"] = {index = -1, spawnChance = 1}
--smashedVehicles["Base.PickUpTruckLightsSmashedFront"] = {index = -1, spawnChance = 1}
smashedVehicles["Base.PickUpVanSmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.PickUpVanSmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.PickUpVanSmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.PickUpVanSmashedFront"] = {index = -1, spawnChance = 5}
--smashedVehicles["Base.PickUpVanLightsSmashedRear"] = {index = -1, spawnChance = 1}
--smashedVehicles["Base.PickUpVanLightsSmashedRight"] = {index = -1, spawnChance = 1}
--smashedVehicles["Base.PickUpVanLightsSmashedLeft"] = {index = -1, spawnChance = 1}
--smashedVehicles["Base.PickUpVanLightsSmashedFront"] = {index = -1, spawnChance = 1}
smashedVehicles["Base.StepVanSmashedRear"] = {index = -1, spawnChance = 3}
smashedVehicles["Base.StepVanSmashedRight"] = {index = -1, spawnChance = 3}
smashedVehicles["Base.StepVanSmashedLeft"] = {index = -1, spawnChance = 3}
smashedVehicles["Base.StepVanSmashedFront"] = {index = -1, spawnChance = 3}
smashedVehicles["Base.SUVSmashedRear"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.SUVSmashedRight"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.SUVSmashedLeft"] = {index = -1, spawnChance = 5}
smashedVehicles["Base.SUVSmashedFront"] = {index = -1, spawnChance = 5}

local burntVehicles = {}
burntVehicles["Base.CarNormalBurnt"] = {index = -1, spawnChance = 20}
burntVehicles["Base.SmallCarBurnt"] = {index = -1, spawnChance = 20}
burntVehicles["Base.SmallCar02Burnt"] = {index = -1, spawnChance = 20}
burntVehicles["Base.OffRoadBurnt"] = {index = -1, spawnChance = 10}
burntVehicles["Base.PickupBurnt"] = {index = -1, spawnChance = 20}
burntVehicles["Base.PickUpVanBurnt"] = {index = -1, spawnChance = 10}
burntVehicles["Base.SportsCarBurnt"] = {index = -1, spawnChance = 10}
burntVehicles["Base.VanSeatsBurnt"] = {index = -1, spawnChance = 10}
burntVehicles["Base.VanBurnt"] = {index = -1, spawnChance = 10}
burntVehicles["Base.ModernCarBurnt"] = {index = -1, spawnChance = 20}
burntVehicles["Base.ModernCar02Burnt"] = {index = -1, spawnChance = 20}
burntVehicles["Base.SUVBurnt"] = {index = -1, spawnChance = 20}
burntVehicles["Base.TaxiBurnt"] = {index = -1, spawnChance = 10}
burntVehicles["Base.LuxuryCarBurnt"] = {index = -1, spawnChance = 20}
burntVehicles["Base.NormalCarBurntPolice"] = {index = -1, spawnChance = 1}
burntVehicles["Base.AmbulanceBurnt"] = {index = -1, spawnChance = 1}
burntVehicles["Base.VanRadioBurnt"] = {index = -1, spawnChance = 1}
burntVehicles["Base.PickupSpecialBurnt"] = {index = -1, spawnChance = 1}
burntVehicles["Base.PickUpVanLightsBurnt"] = {index = -1, spawnChance = 1}

--car modders can add if they want to, but I usually just do it manually
NewVZones.FireTruckNoGarageZoneVehicles = NewVZones.FireTruckNoGarageZoneVehicles or {}

function NewVZones.SpecialZoneDefinitions()
	local activatedMods = getActivatedMods()
	local LargeFireTrucks = NewVZones.FireTruckNoGarageZoneVehicles

	if activatedMods:contains("90pierceArrow") then		--2942793445
		LargeFireTrucks["Base.90pierceArrow"] = true
	end
	if activatedMods:contains("86oshkoshP19A") then		--2566953935
		LargeFireTrucks["Base.86oshkoshKYFD"] = true
	end
	if activatedMods:contains("PzkVanillaPlusCarPack") then		--3217685049
		LargeFireTrucks["Base.pzkFireTruckFlatLadder"] = true
	end

	VehicleZoneDistribution.firegarage = VehicleZoneDistribution.firegarage or {}
	VehicleZoneDistribution.firegarage.vehicles = VehicleZoneDistribution.firegarage.vehicles or {}
	for vName, vData in pairs(VehicleZoneDistribution.fire.vehicles) do
		if not LargeFireTrucks[vName] then
			VehicleZoneDistribution.firegarage.vehicles[vName] = vData
		end
	end
	VehicleZoneDistribution.firegarage.chanceToSpawnNormal = 0
	VehicleZoneDistribution.firegarage.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.firegarage.randomAngle = false

	VehicleZoneDistribution.firetruck = VehicleZoneDistribution.firetruck or {}
	VehicleZoneDistribution.firetruck.vehicles = VehicleZoneDistribution.firetruck.vehicles or {}
	local checkFireTrucks = false
	for vName, _ in pairs(LargeFireTrucks) do
		VehicleZoneDistribution.firetruck.vehicles[vName] = {index = -1, spawnChance = 100}
		--VehicleZoneDistribution.firegarage.vehicles[vName] = {index = -1, spawnChance = 0} Not even added now
		if not checkFireTrucks then checkFireTrucks = true end
	end
	if not checkFireTrucks then
		VehicleZoneDistribution.firetruck.vehicles = VehicleZoneDistribution.fire.vehicles
	end
	VehicleZoneDistribution.firetruck.chanceToSpawnNormal = 0
	VehicleZoneDistribution.firetruck.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.firetruck.randomAngle = false

	VehicleZoneDistribution.modified_trfjm = VehicleZoneDistribution.modified_trfjm or {}
	VehicleZoneDistribution.modified_trfjm.vehicles = VehicleZoneDistribution.modified_trfjm.vehicles or {}

	if not (activatedMods:contains("NoVanillaVehicles") or activatedMods:contains("VVR")) then
		local trafficMixedVehicles = {}
		for k, v in pairs(VehicleZoneDistribution.trafficjams.vehicles) do
			trafficMixedVehicles[k] = v
		end
		for k, v in pairs(smashedVehicles) do
			trafficMixedVehicles[k] = v
		end

		local junkMixedVehicles = {}
		for k, v in pairs(VehicleZoneDistribution.junkyard.vehicles) do
			junkMixedVehicles[k] = v
		end
		for k, v in pairs(smashedVehicles) do
			junkMixedVehicles[k] = v
		end

		VehicleZoneDistribution.trafficjamw.vehicles = trafficMixedVehicles
		VehicleZoneDistribution.trafficjame.vehicles = trafficMixedVehicles
		VehicleZoneDistribution.trafficjamn.vehicles = trafficMixedVehicles
		VehicleZoneDistribution.trafficjams.vehicles = trafficMixedVehicles

		VehicleZoneDistribution.junkyard.vehicles = junkMixedVehicles
	end
	VehicleZoneDistribution.modified_trfjm.vehicles = VehicleZoneDistribution.trafficjams.vehicles or {}

--Large Vehicles
	VehicleZoneDistribution.special_prisonbus = VehicleZoneDistribution.special_prisonbus or {}
	VehicleZoneDistribution.special_prisonbus.vehicles = VehicleZoneDistribution.special_prisonbus.vehicles or {}
	VehicleZoneDistribution.special_prisonbus.spawnRate = 90
	VehicleZoneDistribution.special_prisonbus.chanceToSpawnKey = 100
	VehicleZoneDistribution.special_prisonbus.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.special_prisonbus.chanceToSpawnNormal = 0
	if activatedMods:contains("87fordB700") then
		VehicleZoneDistribution.special_prisonbus.vehicles["Base.87fordB700prison"] = {index = -1, spawnChance = 100}
	end
	if activatedMods:contains("PzkVanillaPlusCarPack") then
		VehicleZoneDistribution.special_prisonbus.vehicles["Base.pzkFranklinTruckBusPrison"] = {index = -1, spawnChance = 100}
	end

	VehicleZoneDistribution.special_schoolbus = VehicleZoneDistribution.special_schoolbus or {}
	VehicleZoneDistribution.special_schoolbus.vehicles = VehicleZoneDistribution.special_schoolbus.vehicles or {}
	VehicleZoneDistribution.special_schoolbus.spawnRate = 70
	VehicleZoneDistribution.special_schoolbus.chanceToSpawnKey = 10
	VehicleZoneDistribution.special_schoolbus.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.special_schoolbus.chanceToSpawnNormal = 0
	if activatedMods:contains("87fordB700") then
		VehicleZoneDistribution.special_schoolbus.vehicles["Base.87fordB700school"] = {index = -1, spawnChance = 100}
	end
	if activatedMods:contains("PzkVanillaPlusCarPack") then
		VehicleZoneDistribution.special_schoolbus.vehicles["Base.pzkFranklinTruckBus"] = {index = -1, spawnChance = 100}
	end

	VehicleZoneDistribution.special_boxtruck = VehicleZoneDistribution.special_boxtruck or {}
	VehicleZoneDistribution.special_boxtruck.vehicles = VehicleZoneDistribution.special_boxtruck.vehicles or {}
	VehicleZoneDistribution.special_boxtruck.spawnRate = 30
	VehicleZoneDistribution.special_boxtruck.chanceToSpawnKey = 50
	VehicleZoneDistribution.special_boxtruck.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.special_boxtruck.chanceToSpawnNormal = 0
	if activatedMods:contains("87fordB700") then
		VehicleZoneDistribution.special_boxtruck.vehicles["Base.87fordF700box"] = {index = -1, spawnChance = 100}
	end

	VehicleZoneDistribution.special_banktruck = VehicleZoneDistribution.special_banktruck or {}
	VehicleZoneDistribution.special_banktruck.vehicles = VehicleZoneDistribution.special_banktruck.vehicles or {}
	VehicleZoneDistribution.special_banktruck.spawnRate = 50
	VehicleZoneDistribution.special_banktruck.chanceToSpawnKey = 100
	VehicleZoneDistribution.special_banktruck.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.special_banktruck.chanceToSpawnNormal = 0
	if activatedMods:contains("87fordB700") then
		VehicleZoneDistribution.special_banktruck.vehicles["Base.87fordF700bank"] = {index = -1, spawnChance = 100}
	end

--Shipping Containers, don't want those spawning everywhere, the airports exist. It's named funny because I couldn't use have the word "container" in it whatsoever.
	VehicleZoneDistribution.special_kntnr = VehicleZoneDistribution.special_kntnr or {}
	VehicleZoneDistribution.special_kntnr.vehicles = VehicleZoneDistribution.special_kntnr.vehicles or {}
	VehicleZoneDistribution.special_kntnr.spawnRate = 70
	VehicleZoneDistribution.special_kntnr.chanceToSpawnKey = 100
	VehicleZoneDistribution.special_kntnr.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.special_kntnr.chanceToSpawnNormal = 0
	if activatedMods:contains("isoContainers") then
		VehicleZoneDistribution.special_kntnr.vehicles["Base.isoContainer2"] = {index = -1, spawnChance = 50}
		VehicleZoneDistribution.special_kntnr.vehicles["Base.isoContainer4"] = {index = -1, spawnChance = 50}
	end

--Military
	--local i = 0; for vName, vData in pairs(VehicleZoneDistribution.military.vehicles) do i = i + 1; end print(i);
	if not activatedMods:contains("VMZNEW") then
		VehicleZoneDistribution.army = VehicleZoneDistribution.army or {}
		VehicleZoneDistribution.army.vehicles = VehicleZoneDistribution.army.vehicles or {}

		VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
		VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}
		if activatedMods:contains("87fordB700") then
			VehicleZoneDistribution.military.vehicles["Base.87fordB700military"] = {index = -1, spawnChance = 5}
		end
		for vName, vData in pairs(VehicleZoneDistribution.army.vehicles) do
			VehicleZoneDistribution.military.vehicles[vName] = vData
		end
		--testing with vanilla vehicles, note that the "Louisville" "region" sets camo truck scrips to their normal skin variants
		--	VehicleZoneDistribution.military.vehicles["Base.PickUpTruck_Camo"] = {index = -1, spawnChance = 30}
		--	VehicleZoneDistribution.military.vehicles["Base.PickUpVan_Camo"] = {index = -1, spawnChance = 30}
		--	VehicleZoneDistribution.military.vehicles["Base.Trailer"] = {index = -1, spawnChance = 20}
		--	VehicleZoneDistribution.military.vehicles["Base.TrailerCover"] = {index = -1, spawnChance = 20}
		VehicleZoneDistribution.military.spawnRate = 30
		VehicleZoneDistribution.military.chanceToSpawnKey = 50
		VehicleZoneDistribution.military.chanceToSpawnSpecial = 1
		VehicleZoneDistribution.military.chanceToSpawnNormal = 0

		VehicleZoneDistribution.military_vehicles = {}
		VehicleZoneDistribution.military_vehicles.vehicles = {}
		--for vName, vData in pairs(VehicleZoneDistribution.military.vehicles) do local vNameLower = string.lower(vName); if not (vNameLower:contains("trailer") or vNameLower:contains("container") or vNameLower:contains("tanker")) then VehicleZoneDistribution.military_vehicles.vehicles[vName] = vData; end end

		for vName, vData in pairs(VehicleZoneDistribution.military.vehicles) do
			local vNameLower = string.lower(vName)
			if not (vNameLower:contains("trailer") or vNameLower:contains("container") or vNameLower:contains("tanker")) then
				VehicleZoneDistribution.military_vehicles.vehicles[vName] = vData
				--Allows the trailers, containers, and tankers, to spawn uniquely at other places, the vehicles are more valued, have this extra zone, and need to be rarer.
				VehicleZoneDistribution.trailerpark.vehicles[vName] = nil
				VehicleZoneDistribution.junkyard.vehicles[vName] = nil
				VehicleZoneDistribution.normalburnt.vehicles[vName] = nil
				VehicleZoneDistribution.specialburnt.vehicles[vName] = nil
			end
			--Do more specific per mod changes in "RebalancedVehicleZoneDefinitions.lua"
			VehicleZoneDistribution.parkingstall.vehicles[vName] = nil
			VehicleZoneDistribution.bad.vehicles[vName] = nil
			VehicleZoneDistribution.medium.vehicles[vName] = nil
			VehicleZoneDistribution.good.vehicles[vName] = nil
			VehicleZoneDistribution.sport.vehicles[vName] = nil
			VehicleZoneDistribution.trafficjamw.vehicles[vName] = nil
			VehicleZoneDistribution.trafficjame.vehicles[vName] = nil
			VehicleZoneDistribution.trafficjamn.vehicles[vName] = nil
			VehicleZoneDistribution.trafficjams.vehicles[vName] = nil
		end
		-- for vName, vData in pairs(VehicleZoneDistribution.military_vehicles.vehicles) do local vNameLower = string.lower(vName); if vNameLower:contains("trailer") or vNameLower:contains("container") or vNameLower:contains("tanker") then VehicleZoneDistribution.military_vehicles.vehicles[vName] = nil; end end
		VehicleZoneDistribution.military_vehicles.spawnRate = 50
		VehicleZoneDistribution.military_vehicles.chanceToSpawnKey = 70
		VehicleZoneDistribution.military_vehicles.chanceToSpawnSpecial = 0
		VehicleZoneDistribution.military_vehicles.chanceToSpawnNormal = 0
	end

--Gas Station Zones, can spawn with fuel pump attached
	VehicleZoneDistribution.special_gasstation = VehicleZoneDistribution.special_gasstation or {}
	VehicleZoneDistribution.special_gasstation.vehicles = VehicleZoneDistribution.special_gasstation.vehicles or {}
	VehicleZoneDistribution.special_gasstation.spawnRate = 30
	VehicleZoneDistribution.special_gasstation.chanceToSpawnKey = 100
	VehicleZoneDistribution.special_gasstation.chanceToSpawnSpecial = 5
	VehicleZoneDistribution.special_gasstation.chanceToSpawnNormal = 0
--	for vName, vData in pairs(VehicleZoneDistribution.parkingstall.vehicles) do
--		VehicleZoneDistribution.special_gasstation.vehicles[vName] = vData
--	end
	VehicleZoneDistribution.special_gasstation.vehicles = VehicleZoneDistribution.parkingstall.vehicles

--Used Cars Dealer
	VehicleZoneDistribution.usedcarsdealership = {}
	VehicleZoneDistribution.usedcarsdealership.vehicles = {}
	VehicleZoneDistribution.usedcarsdealership.spawnRate = 60
	VehicleZoneDistribution.usedcarsdealership.chanceToSpawnKey = 100
	VehicleZoneDistribution.usedcarsdealership.baseVehicleQuality = 0.6
	VehicleZoneDistribution.usedcarsdealership.chanceToPartDamage = 100
	VehicleZoneDistribution.usedcarsdealership.chanceToSpawnNormal = 0
	VehicleZoneDistribution.usedcarsdealership.chanceToSpawnSpecial = 0
	--sorted by common to least common zone type in cases of overlapping and uses "house" zones only to avoid things vehicles like vans
	for vName, vData in pairs(VehicleZoneDistribution.trailerpark.vehicles) do
		local vNameLower = string.lower(vName)
		if not (vNameLower:contains("van") or vNameLower:contains("camo") or vNameLower:contains("taxi") or vNameLower:contains("trailer") or vNameLower:contains("container") or vNameLower:contains("tanker")) then
			VehicleZoneDistribution.usedcarsdealership.vehicles[vName] = {index = vData.index, spawnChance = 6 * vData.spawnChance}
		end
	end
	for vName, vData in pairs(VehicleZoneDistribution.bad.vehicles) do
		local vNameLower = string.lower(vName)
		if not (vNameLower:contains("van") or vNameLower:contains("camo") or vNameLower:contains("taxi") or vNameLower:contains("trailer") or vNameLower:contains("container") or vNameLower:contains("tanker")) then
			VehicleZoneDistribution.usedcarsdealership.vehicles[vName] = {index = vData.index, spawnChance = 12 * vData.spawnChance}
		end
	end
	for vName, vData in pairs(VehicleZoneDistribution.parkingstall.vehicles) do
		local vNameLower = string.lower(vName)
		if not (vNameLower:contains("van") or vNameLower:contains("camo") or vNameLower:contains("taxi") or vNameLower:contains("trailer") or vNameLower:contains("container") or vNameLower:contains("tanker")) then
			VehicleZoneDistribution.usedcarsdealership.vehicles[vName] = {index = vData.index, spawnChance = 20 * vData.spawnChance}
		end
	end
	for vName, vData in pairs(VehicleZoneDistribution.medium.vehicles) do
		local vNameLower = string.lower(vName)
		if not (vNameLower:contains("van") or vNameLower:contains("camo") or vNameLower:contains("taxi") or vNameLower:contains("trailer") or vNameLower:contains("container") or vNameLower:contains("tanker")) then
			VehicleZoneDistribution.usedcarsdealership.vehicles[vName] = {index = vData.index, spawnChance = 8 * vData.spawnChance}
		end
	end
	for vName, vData in pairs(VehicleZoneDistribution.good.vehicles) do
		local vNameLower = string.lower(vName)
		if not (vNameLower:contains("van") or vNameLower:contains("camo") or vNameLower:contains("taxi") or vNameLower:contains("trailer") or vNameLower:contains("container") or vNameLower:contains("tanker")) then
			VehicleZoneDistribution.usedcarsdealership.vehicles[vName] = {index = vData.index, spawnChance = 4 * vData.spawnChance}
		end
	end
	for vName, vData in pairs(VehicleZoneDistribution.sport.vehicles) do
		local vNameLower = string.lower(vName)
		if not (vNameLower:contains("van") or vNameLower:contains("camo") or vNameLower:contains("taxi") or vNameLower:contains("trailer") or vNameLower:contains("container") or vNameLower:contains("tanker")) then
			VehicleZoneDistribution.usedcarsdealership.vehicles[vName] = {index = vData.index, spawnChance = 2 * vData.spawnChance}
		end
	end

--Knox Telecommunications (phone lines POIs)
	VehicleZoneDistribution.knoxtelecomms = {}
	VehicleZoneDistribution.knoxtelecomms.vehicles = {}
	VehicleZoneDistribution.knoxtelecomms.spawnRate = 30
	VehicleZoneDistribution.knoxtelecomms.chanceToSpawnKey = 100
	VehicleZoneDistribution.knoxtelecomms.chanceToSpawnNormal = 0
	VehicleZoneDistribution.knoxtelecomms.chanceToSpawnSpecial = 0
	if not (activatedMods:contains("NoVanillaVehicles") or activatedMods:contains("VVR")) then
		VehicleZoneDistribution.knoxtelecomms.vehicles["Base.VanKnoxCom"] = {index = -1, spawnChance = 100}
	else
		VehicleZoneDistribution.knoxtelecomms.vehicles = VehicleZoneDistribution.lectromax.vehicles
	end

end
Events.OnLoadMapZones.Add(NewVZones.SpecialZoneDefinitions)
