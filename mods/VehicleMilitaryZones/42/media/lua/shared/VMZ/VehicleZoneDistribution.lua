local VZDUtils = require("YAPZLib/VehicleZoneDistribution")

if not VehicleZoneDistribution then return end
	
VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}

VehicleZoneDistribution.army = VehicleZoneDistribution.army or {}
VehicleZoneDistribution.army.vehicles = VehicleZoneDistribution.army.vehicles or {}

local vehicleZoneDistribution = function()
	VZDUtils.clearSpawnZones(VehicleZoneDistribution.military.vehicles, true)

	local SpawnRate = SandboxVars.VMZ.SpawnRate
	local VehicleCondition = (SandboxVars.VMZ.VehiCond * 2) / 100
	local DamagedPart = SandboxVars.VMZ.PartDamage
	local KeyChance = SandboxVars.VMZ.KeySpawn
	local Special = SandboxVars.VMZ.SpecCar
	
	if VehicleZoneDistribution.army.vehicles ~= nil then
		for vehicleName, vehicleData in pairs(VehicleZoneDistribution.army.vehicles) do
			if not VehicleZoneDistribution.military.vehicles[vehicleName] then
				VehicleZoneDistribution.military.vehicles[vehicleName] = vehicleData
			end
		end
	end
	
	local MilitaryBurnt = {}
	local MilitaryContainers = {}
	local MilitaryTrailers_All = {}
	local MilitaryTrailers_Light = {}
	local MilitaryTrailers_Heavy = {}
	local MilitaryVehicles_All = {}
	local MilitaryVehicles_Light = {}
	local MilitaryVehicles_Heavy = {}
	
	for vehicleName, vehicleData in pairs(VehicleZoneDistribution.military.vehicles) do
		local vehicleScript = ScriptManager.instance:getVehicle(vehicleName)
		if vehicleScript then
			local heavyPotential = (vehicleScript:getMass() * vehicleScript:getEngineForce() * vehicleScript:getEngineLoudness()) / 10 ^ 6
			if string.find(string.lower(vehicleName), "burnt") then
				MilitaryBurnt[vehicleName] = vehicleData
			elseif string.find(string.lower(vehicleName), "container") then
				MilitaryContainers[vehicleName] = vehicleData
			elseif string.find(string.lower(vehicleName), "trailer") then
				MilitaryTrailers_All[vehicleName] = vehicleData
				if vehicleScript:getOffroadEfficiency() <= 1.01 then
					MilitaryTrailers_Light[vehicleName] = vehicleData
				else
					MilitaryTrailers_Heavy[vehicleName] = vehicleData
				end
			else
				MilitaryVehicles_All[vehicleName] = vehicleData
				if heavyPotential > 425 then
					MilitaryVehicles_Heavy[vehicleName] = vehicleData
				else
					MilitaryVehicles_Light[vehicleName] = vehicleData
				end
			end
		end
	end

	--Burnt--

	VehicleZoneDistribution.military_burnt = {}
	VehicleZoneDistribution.military_burnt.vehicles = MilitaryBurnt
	VehicleZoneDistribution.military_burnt.spawnRate = SpawnRate
	VehicleZoneDistribution.military_burnt.randomAngle = true
	VehicleZoneDistribution.military_burnt.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_burnt.chanceToSpawnNormal = 0

	--Containers--

	VehicleZoneDistribution.military_container = {}
	VehicleZoneDistribution.military_container.vehicles = MilitaryContainers
	VehicleZoneDistribution.military_container.spawnRate = SpawnRate
	VehicleZoneDistribution.military_container.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_container.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_container.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_container.chanceToSpawnNormal = 0
	
	VehicleZoneDistribution.military_container_angled = {}
	VehicleZoneDistribution.military_container_angled.vehicles = MilitaryContainers
	VehicleZoneDistribution.military_container_angled.spawnRate = SpawnRate
	VehicleZoneDistribution.military_container_angled.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_container_angled.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_container_angled.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_container_angled.chanceToSpawnNormal = 0
	VehicleZoneDistribution.military_container_angled.positionAngles = { -30, -22.5, -15, -7.5, 7.5, 15, 22.5, 30 }

	--Trailers (All)--

	VehicleZoneDistribution.military_trailer = {}
	VehicleZoneDistribution.military_trailer.vehicles = MilitaryTrailers_All
	VehicleZoneDistribution.military_trailer.spawnRate = SpawnRate
	VehicleZoneDistribution.military_trailer.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_trailer.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_trailer.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_trailer.chanceToSpawnNormal = 0
	
	VehicleZoneDistribution.military_trailer_angled = {}
	VehicleZoneDistribution.military_trailer_angled.vehicles = MilitaryTrailers_All
	VehicleZoneDistribution.military_trailer_angled.spawnRate = SpawnRate
	VehicleZoneDistribution.military_trailer_angled.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_trailer_angled.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_trailer_angled.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_trailer_angled.chanceToSpawnNormal = 0
	VehicleZoneDistribution.military_trailer_angled.positionAngles = { -30, -22.5, -15, -7.5, 7.5, 15, 22.5, 30 }
	--Trailers (Light)--

	VehicleZoneDistribution.military_trailer_light = {}
	VehicleZoneDistribution.military_trailer_light.vehicles = MilitaryTrailers_Light
	VehicleZoneDistribution.military_trailer_light.spawnRate = SpawnRate
	VehicleZoneDistribution.military_trailer_light.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_trailer_light.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_trailer_light.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_trailer_light.chanceToSpawnNormal = 0
	
	VehicleZoneDistribution.military_trailer_light_angled = {}
	VehicleZoneDistribution.military_trailer_light_angled.vehicles = MilitaryTrailers_Light
	VehicleZoneDistribution.military_trailer_light_angled.spawnRate = SpawnRate
	VehicleZoneDistribution.military_trailer_light_angled.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_trailer_light_angled.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_trailer_light_angled.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_trailer_light_angled.chanceToSpawnNormal = 0
	VehicleZoneDistribution.military_trailer_light_angled.positionAngles = { -30, -22.5, -15, -7.5, 7.5, 15, 22.5, 30 }
	
	--Trailers (Heavy)--

	VehicleZoneDistribution.military_trailer_heavy = {}
	VehicleZoneDistribution.military_trailer_heavy.vehicles = MilitaryTrailers_Heavy
	VehicleZoneDistribution.military_trailer_heavy.spawnRate = SpawnRate
	VehicleZoneDistribution.military_trailer_heavy.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_trailer_heavy.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_trailer_heavy.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_trailer_heavy.chanceToSpawnNormal = 0
	
	VehicleZoneDistribution.military_trailer_heavy_angled = {}
	VehicleZoneDistribution.military_trailer_heavy_angled.vehicles = MilitaryTrailers_Heavy
	VehicleZoneDistribution.military_trailer_heavy_angled.spawnRate = SpawnRate
	VehicleZoneDistribution.military_trailer_heavy_angled.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_trailer_heavy_angled.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_trailer_heavy_angled.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_trailer_heavy_angled.chanceToSpawnNormal = 0
	VehicleZoneDistribution.military_trailer_heavy_angled.positionAngles = { -30, -22.5, -15, -7.5, 7.5, 15, 22.5, 30 }

	--Vehicles (All)--

	VehicleZoneDistribution.military_vehicle = {}
	VehicleZoneDistribution.military_vehicle.vehicles = MilitaryVehicles_All
	VehicleZoneDistribution.military_vehicle.spawnRate = SpawnRate
	VehicleZoneDistribution.military_vehicle.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_vehicle.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_vehicle.chanceToSpawnKey = KeyChance
	VehicleZoneDistribution.military_vehicle.specialCar = Special
	VehicleZoneDistribution.military_vehicle.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_vehicle.chanceToSpawnNormal = 0
	
	VehicleZoneDistribution.military_vehicle_angled = {}
	VehicleZoneDistribution.military_vehicle_angled.vehicles = MilitaryVehicles_All
	VehicleZoneDistribution.military_vehicle_angled.spawnRate = SpawnRate
	VehicleZoneDistribution.military_vehicle_angled.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_vehicle_angled.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_vehicle_angled.chanceToSpawnKey = KeyChance
	VehicleZoneDistribution.military_vehicle_angled.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_vehicle_angled.chanceToSpawnNormal = 0
	VehicleZoneDistribution.military_vehicle_angled.positionAngles = { -30, -22.5, -15, -7.5, 7.5, 15, 22.5, 30 }
	
	--Vehicles (Light)--

	VehicleZoneDistribution.military_vehicle_light = {}
	VehicleZoneDistribution.military_vehicle_light.vehicles = MilitaryVehicles_Light
	VehicleZoneDistribution.military_vehicle_light.spawnRate = SpawnRate
	VehicleZoneDistribution.military_vehicle_light.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_vehicle_light.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_vehicle_light.chanceToSpawnKey = KeyChance
	VehicleZoneDistribution.military_vehicle_light.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_vehicle_light.chanceToSpawnNormal = 0
	
	VehicleZoneDistribution.military_vehicle_light_angled = {}
	VehicleZoneDistribution.military_vehicle_light_angled.vehicles = MilitaryVehicles_Light
	VehicleZoneDistribution.military_vehicle_light_angled.spawnRate = SpawnRate
	VehicleZoneDistribution.military_vehicle_light_angled.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_vehicle_light_angled.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_vehicle_light_angled.chanceToSpawnKey = KeyChance
	VehicleZoneDistribution.military_vehicle_light_angled.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_vehicle_light_angled.chanceToSpawnNormal = 0
	VehicleZoneDistribution.military_vehicle_light_angled.positionAngles = { -30, -22.5, -15, -7.5, 7.5, 15, 22.5, 30 }
	
	--Vehicles (Heavy)--

	VehicleZoneDistribution.military_vehicle_heavy = {}
	VehicleZoneDistribution.military_vehicle_heavy.vehicles = MilitaryVehicles_Heavy
	VehicleZoneDistribution.military_vehicle_heavy.spawnRate = SpawnRate
	VehicleZoneDistribution.military_vehicle_heavy.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_vehicle_heavy.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_vehicle_heavy.chanceToSpawnKey = KeyChance
	VehicleZoneDistribution.military_vehicle_heavy.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_vehicle_heavy.chanceToSpawnNormal = 0
	
	VehicleZoneDistribution.military_vehicle_heavy_angled = {}
	VehicleZoneDistribution.military_vehicle_heavy_angled.vehicles = MilitaryVehicles_Heavy
	VehicleZoneDistribution.military_vehicle_heavy_angled.spawnRate = SpawnRate
	VehicleZoneDistribution.military_vehicle_heavy_angled.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_vehicle_heavy_angled.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_vehicle_heavy_angled.chanceToSpawnKey = KeyChance
	VehicleZoneDistribution.military_vehicle_heavy_angled.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_vehicle_heavy_angled.chanceToSpawnNormal = 0
	VehicleZoneDistribution.military_vehicle_heavy_angled.positionAngles = { -30, -22.5, -15, -7.5, 7.5, 15, 22.5, 30 }
end

Events.OnLoadMapZones.Add(vehicleZoneDistribution)