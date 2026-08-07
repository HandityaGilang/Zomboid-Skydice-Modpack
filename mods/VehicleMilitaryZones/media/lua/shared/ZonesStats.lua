if not VehicleZoneDistribution then return end

local function VMZ_MilZonesStats()
	local SpawnRate = SandboxVars.VMZ.SpawnRate
	local VehicleCondition = (SandboxVars.VMZ.VehiCond*2)/100
	local DamagedPart = SandboxVars.VMZ.PartDamage
	local KeyChance = SandboxVars.VMZ.KeySpawn
	local Special = SandboxVars.VMZ.SpecCar
	
	VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
	VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}
	
	VehicleZoneDistribution.army = VehicleZoneDistribution.army or {}
	VehicleZoneDistribution.army.vehicles = VehicleZoneDistribution.army.vehicles or {}
	
	if VehicleZoneDistribution.army.vehicles ~= nil then
		for vehicleName, vehicleData in pairs(VehicleZoneDistribution.army.vehicles) do
			if not VehicleZoneDistribution.military.vehicles[vehicleName] then
				VehicleZoneDistribution.military.vehicles[vehicleName] = vehicleData
			end
		end
	end
	
	local zones = { "parkingstall", "trailerpark", "bad", "medium", "good", "sport", "junkyard", "trafficjams", "police", "fire", "ranger", "mccoy", "postal", "spiffo", "ambulance", "radio", "fossoil", "scarlet", "massgenfac", "transit", "network3", "kyheralds", "lectromax", "knoxdisti"}
	for vehicleName, _ in pairs(VehicleZoneDistribution.military.vehicles) do
		for _, zoneName in ipairs(zones) do
			VehicleZoneDistribution[zoneName].vehicles[vehicleName] = nil
		end
	end

	--Burnt--

	VehicleZoneDistribution.military_burnt = VehicleZoneDistribution.military_burnt or {}
	VehicleZoneDistribution.military_burnt.vehicles = VehicleZoneDistribution.military_burnt.vehicles or {}
	VehicleZoneDistribution.military_burnt.spawnRate = SpawnRate
	VehicleZoneDistribution.military_burnt.randomAngle = true
	VehicleZoneDistribution.military_burnt.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_burnt.chanceToSpawnNormal = 0

	--Containers--

	VehicleZoneDistribution.military_container = VehicleZoneDistribution.military_container or {}
	VehicleZoneDistribution.military_container.vehicles = VehicleZoneDistribution.military_container.vehicles or {}
	VehicleZoneDistribution.military_container.spawnRate = SpawnRate
	VehicleZoneDistribution.military_container.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_container.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_container.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_container.chanceToSpawnNormal = 0

	--Trailers (All)--

	VehicleZoneDistribution.military_trailer = VehicleZoneDistribution.military_trailer or {}
	VehicleZoneDistribution.military_trailer.vehicles = VehicleZoneDistribution.military_trailer.vehicles or {}
	VehicleZoneDistribution.military_trailer.spawnRate = SpawnRate
	VehicleZoneDistribution.military_trailer.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_trailer.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_trailer.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_trailer.chanceToSpawnNormal = 0
	
	--Trailers (Light)--

	VehicleZoneDistribution.military_trailer_light = VehicleZoneDistribution.military_trailer_light or {}
	VehicleZoneDistribution.military_trailer_light.vehicles = VehicleZoneDistribution.military_trailer_light.vehicles or {}
	VehicleZoneDistribution.military_trailer_light.spawnRate = SpawnRate
	VehicleZoneDistribution.military_trailer_light.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_trailer_light.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_trailer_light.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_trailer_light.chanceToSpawnNormal = 0
	
	--Trailers (Heavy)--

	VehicleZoneDistribution.military_trailer_heavy = VehicleZoneDistribution.military_trailer_heavy or {}
	VehicleZoneDistribution.military_trailer_heavy.vehicles = VehicleZoneDistribution.military_trailer_heavy.vehicles or {}
	VehicleZoneDistribution.military_trailer_heavy.spawnRate = SpawnRate
	VehicleZoneDistribution.military_trailer_heavy.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_trailer_heavy.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_trailer_heavy.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_trailer_heavy.chanceToSpawnNormal = 0

	--Vehicles (All)--

	VehicleZoneDistribution.military_vehicle = VehicleZoneDistribution.military_vehicle or {}
	VehicleZoneDistribution.military_vehicle.vehicles = VehicleZoneDistribution.military_vehicle.vehicles or {}
	VehicleZoneDistribution.military_vehicle.spawnRate = SpawnRate
	VehicleZoneDistribution.military_vehicle.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_vehicle.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_vehicle.chanceToSpawnKey = KeyChance
	VehicleZoneDistribution.military_vehicle.specialCar = Special
	VehicleZoneDistribution.military_vehicle.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_vehicle.chanceToSpawnNormal = 0
	
	--Vehicles (Light)--

	VehicleZoneDistribution.military_vehicle_light = VehicleZoneDistribution.military_vehicle_light or {}
	VehicleZoneDistribution.military_vehicle_light.vehicles = VehicleZoneDistribution.military_vehicle_light.vehicles or {}
	VehicleZoneDistribution.military_vehicle_light.spawnRate = SpawnRate
	VehicleZoneDistribution.military_vehicle_light.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_vehicle_light.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_vehicle_light.chanceToSpawnKey = KeyChance
	VehicleZoneDistribution.military_vehicle_light.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_vehicle_light.chanceToSpawnNormal = 0
	
	--Vehicles (Heavy)--

	VehicleZoneDistribution.military_vehicle_heavy = VehicleZoneDistribution.military_vehicle_heavy or {}
	VehicleZoneDistribution.military_vehicle_heavy.vehicles = VehicleZoneDistribution.military_vehicle_heavy.vehicles or {}
	VehicleZoneDistribution.military_vehicle_heavy.spawnRate = SpawnRate
	VehicleZoneDistribution.military_vehicle_heavy.baseVehicleQuality = VehicleCondition
	VehicleZoneDistribution.military_vehicle_heavy.chanceToPartDamage = DamagedPart
	VehicleZoneDistribution.military_vehicle_heavy.chanceToSpawnKey = KeyChance
	VehicleZoneDistribution.military_vehicle_heavy.chanceToSpawnSpecial = 0
	VehicleZoneDistribution.military_vehicle_heavy.chanceToSpawnNormal = 0
end

Events.OnLoadMapZones.Add(VMZ_MilZonesStats)