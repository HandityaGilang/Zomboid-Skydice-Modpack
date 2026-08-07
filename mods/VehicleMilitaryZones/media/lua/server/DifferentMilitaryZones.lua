local function getMaxSpeed(vehicleScript)
	local maxSpeedField = getClassField(vehicleScript, 29)
	if maxSpeedField then
		local maxSpeed = getClassFieldVal(vehicleScript, maxSpeedField)
		if maxSpeed then
			return maxSpeed
		end
	end
end

local function VMZ_DifferentMilitaryZones()
	if VehicleZoneDistribution then

	VehicleZoneDistribution.military = VehicleZoneDistribution.military or {}
	VehicleZoneDistribution.military.vehicles = VehicleZoneDistribution.military.vehicles or {}
	
	VehicleZoneDistribution.army = VehicleZoneDistribution.army or {}
	VehicleZoneDistribution.army.vehicles = VehicleZoneDistribution.army.vehicles or {}
	
	local MilitaryBurnt = {}
	local MilitaryContainers = {}
	local MilitaryTrailers_All = {}
	local MilitaryTrailers_Light = {}
	local MilitaryTrailers_Heavy = {}
	local MilitaryVehicles_All = {}
	local MilitaryVehicles_Light = {}
	local MilitaryVehicles_Heavy = {}
	
	for vehicleName, vehicleData in pairs(VehicleZoneDistribution.military.vehicles) do
		local milvehicle = ScriptManager.instance:getVehicle(vehicleName)
		if milvehicle then
			local heavyVehPotential = (milvehicle:getMass()*milvehicle:getEngineForce())/(getMaxSpeed(milvehicle)*1000)
			if string.find(string.lower(vehicleName), "burnt") then
				MilitaryBurnt[vehicleName] = vehicleData
			elseif string.find(string.lower(vehicleName), "container") then
				MilitaryContainers[vehicleName] = vehicleData
			elseif string.find(string.lower(vehicleName), "trailer") then
				MilitaryTrailers_All[vehicleName] = vehicleData
				if milvehicle:getOffroadEfficiency() <= 1.0 then
					MilitaryTrailers_Light[vehicleName] = vehicleData
				else
					MilitaryTrailers_Heavy[vehicleName] = vehicleData
				end
			else
				MilitaryVehicles_All[vehicleName] = vehicleData
				if heavyVehPotential > 60 then
					MilitaryVehicles_Heavy[vehicleName] = vehicleData
				else
					MilitaryVehicles_Light[vehicleName] = vehicleData
				end
			end
		end
	end

	--Burnt--

	VehicleZoneDistribution.military_burnt = VehicleZoneDistribution.military_burnt or {}
	VehicleZoneDistribution.military_burnt.vehicles = VehicleZoneDistribution.military_burnt.vehicles or {}
	VehicleZoneDistribution.military_burnt.vehicles = MilitaryBurnt

	--Containers--

	VehicleZoneDistribution.military_container = VehicleZoneDistribution.military_container or {}
	VehicleZoneDistribution.military_container.vehicles = VehicleZoneDistribution.military_container.vehicles or {}
	VehicleZoneDistribution.military_container.vehicles = MilitaryContainers

	--Trailers (All)--

	VehicleZoneDistribution.military_trailer = VehicleZoneDistribution.military_trailer or {}
	VehicleZoneDistribution.military_trailer.vehicles = VehicleZoneDistribution.military_trailer.vehicles or {}
	VehicleZoneDistribution.military_trailer.vehicles = MilitaryTrailers_All
	
	--Trailers (Light)--

	VehicleZoneDistribution.military_trailer_light = VehicleZoneDistribution.military_trailer_light or {}
	VehicleZoneDistribution.military_trailer_light.vehicles = VehicleZoneDistribution.military_trailer_light.vehicles or {}
	VehicleZoneDistribution.military_trailer_light.vehicles = MilitaryTrailers_Light

	--Trailers (Heavy)--

	VehicleZoneDistribution.military_trailer_heavy = VehicleZoneDistribution.military_trailer_heavy or {}
	VehicleZoneDistribution.military_trailer_heavy.vehicles = VehicleZoneDistribution.military_trailer_heavy.vehicles or {}
	VehicleZoneDistribution.military_trailer_heavy.vehicles = MilitaryTrailers_Heavy

	--Vehicles (All)--

	VehicleZoneDistribution.military_vehicle = VehicleZoneDistribution.military_vehicle or {}
	VehicleZoneDistribution.military_vehicle.vehicles = VehicleZoneDistribution.military_vehicle.vehicles or {}
	VehicleZoneDistribution.military_vehicle.vehicles = MilitaryVehicles_All
	
	--Vehicles (Light)--

	VehicleZoneDistribution.military_vehicle_light = VehicleZoneDistribution.military_vehicle_light or {}
	VehicleZoneDistribution.military_vehicle_light.vehicles = VehicleZoneDistribution.military_vehicle_light.vehicles or {}
	VehicleZoneDistribution.military_vehicle_light.vehicles = MilitaryVehicles_Light

	--Vehicles (Heavy)--

	VehicleZoneDistribution.military_vehicle_heavy = VehicleZoneDistribution.military_vehicle_heavy or {}
	VehicleZoneDistribution.military_vehicle_heavy.vehicles = VehicleZoneDistribution.military_vehicle_heavy.vehicles or {}
	VehicleZoneDistribution.military_vehicle_heavy.vehicles = MilitaryVehicles_Heavy

	end
end

Events.OnLoadMapZones.Add(VMZ_DifferentMilitaryZones)