local __utils = require("YAPZLib/Utils")
local __utilTables = require("YAPZLib/JustTables")

local __vehicleZoneDistribution = {}

__vehicleZoneDistribution.addToSpawnZone = function(vehicleName, zoneName, skinIndex, chance, _require)
	if not __utils.checkArgs(
		vehicleName, "string", true,
		zoneName, "string", true,
		skinIndex, "integer", false,
		chance, "number", true,
		_require, "string", false
	) then return end
	
	if chance <= 0 then return end
	if not skinIndex then skinIndex = -1 end

	if not VehicleZoneDistribution then return end
	if not ScriptManager.instance:getVehicle(vehicleName) then return end
	local zoneDistribution = VehicleZoneDistribution[zoneName]
	if not zoneDistribution or not zoneDistribution.vehicles then return end
	if _require then require(_require) end
	
	zoneDistribution.vehicles[vehicleName] = { index = skinIndex, spawnChance = chance }
end

__vehicleZoneDistribution.clearSpawnZones = function(vehicleNamePlusRequire, vanillaOnly)
	if not __utils.checkArgs(
		vehicleNamePlusRequire, "map", true,
		vanillaOnly, "boolean", false
	) then return end

	if not VehicleZoneDistribution then return end
	
	local zones = {}
	if vanillaOnly then
		zones = __utilTables.vanillaZones
	else
		zones = VehicleZoneDistribution
	end
	if not zones then return end
	
	local required = {}
	for vehicleName, _require in pairs(vehicleNamePlusRequire) do
		if ScriptManager.instance:getVehicle(vehicleName) then
			if not required[_require] and type(_require) == "string" and _require ~= "nil" then
				required[_require] = true
				require(_require)
			end
			
			for zoneName, _ in pairs(zones) do
				local zoneDistribution = VehicleZoneDistribution[zoneName]
				if zoneDistribution and zoneDistribution.vehicles then
					zoneDistribution.vehicles[vehicleName] = nil
				end
			end
		end
	end
end

__vehicleZoneDistribution.removeFromSpawnZone = function(vehicleNamePlusRequire, zoneName)
	if not __utils.checkArgs(
		vehicleNamePlusRequire, "map", true,
		zoneName, "string", true
	) then return end

	if not VehicleZoneDistribution then return end
	local zoneDistribution = VehicleZoneDistribution[zoneName]
	if not zoneDistribution or not zoneDistribution.vehicles then return end
	
	local required = {}
	for vehicleName, _require in pairs(vehicleNamePlusRequire) do
		if ScriptManager.instance:getVehicle(vehicleName) then
			if not required[_require] and type(_require) == "string" and _require ~= "nil" then
				required[_require] = true
				require(_require)
			end
			
			zoneDistribution.vehicles[vehicleName] = nil
		end
	end
end

__vehicleZoneDistribution.copy = function(zoneName)
	if not __utils.checkArgs(zoneName, "string", true) then return end

	local zoneDistribution = VehicleZoneDistribution[zoneName]
	if not zoneDistribution then return end
	
	return __utils.copyTable(zoneDistribution)
end

return __vehicleZoneDistribution