local VZDUtils = require("YAPZLib/VehicleZoneDistribution")
local __utils = require("YAPZLib/Utils")
local __getSquaresInRadius = require("YAPZLib/VehicleUtils").getSquaresInRadius
local __clearSquare = require("YAPZLib/RWBase").cleanSquareForStory
local Data = require("VVR/Data")
local vehiclesBlacklist = {}

local doNoTrailers = function()
	if not VehicleZoneDistribution then return end
	if SandboxVars.VVR.NoTrailers == true then
		local trailers = {
			["Base.TrailerKI5utilityLarge"] = "KI5trailers_SpawnList",
			["Base.TrailerKI5utilityMedium"] = "KI5trailers_SpawnList",
			["Base.TrailerKI5utilitySmall"] = "KI5trailers_SpawnList",
			["Base.TrailerKI5cargoLarge"] = "KI5trailers_SpawnList",
			["Base.TrailerKI5cargoMedium"] = "KI5trailers_SpawnList",
			["Base.TrailerKI5cargoSmall"] = "KI5trailers_SpawnList",
			["Base.Trailer87Scamp13"] = "KI5campers_SpawnList",
			["Base.Trailer61Bambi16"] = "KI5campers_SpawnList",
			["Base.Trailer87Scamp16"] = "KI5campers_SpawnList",
			["Base.Trailer54FlyingCloud22"] = "KI5campers_SpawnList",
			["Base.TrailerM101A3cargo"] = "92amgeneralM998SpawnList",
		}
		
		VZDUtils.removeFromSpawnZone(trailers, "bad")
		VZDUtils.removeFromSpawnZone(trailers, "trafficjams")
	end
end

local doNoBurnt = function()
	if not VehicleZoneDistribution then return end
	if SandboxVars.VVR.NoBurnt then
		VehicleZoneDistribution.normalburnt.vehicles = VehicleZoneDistribution.trafficjams.vehicles
		VehicleZoneDistribution.specialburnt.vehicles = VehicleZoneDistribution.trafficjams.vehicles
	else
		VehicleZoneDistribution.racecar.vehicles["Base.RaceCarBurnt"] = { index = -1, spawnChance = 25 }
	end
end
	
local doBurntParams = function()
	if not VehicleZoneDistribution then return end
	if SandboxVars.VVR.NoBurnt then
		VehicleZoneDistribution.specialburnt.chanceToPartDamage = 100
		VehicleZoneDistribution.specialburnt.chanceToSpawnKey = 10
		VehicleZoneDistribution.specialburnt.baseVehicleQuality = (SandboxVars.VVR.VehiCond / 100) * 2
		VehicleZoneDistribution.normalburnt.chanceToPartDamage = 100
		VehicleZoneDistribution.normalburnt.chanceToSpawnKey = 10
		VehicleZoneDistribution.normalburnt.baseVehicleQuality = (SandboxVars.VVR.VehiCond / 100) * 2
	end
end

local getVehiclesBlacklist = function()
	local vehiclesBlacklist = {}
	
	for vehicleName in string.gmatch(SandboxVars.VVR.VehiclesBlacklist, "[^;]+") do
		vehicleName = vehicleName:match("^%s*(.-)%s*$")
		vehiclesBlacklist[vehicleName] = true
	end
	
	return vehiclesBlacklist
end

local doVehiclesBlacklist = function()
	vehiclesBlacklist = getVehiclesBlacklist()
	
	for vehicleName, state in pairs(vehiclesBlacklist) do
		if state then
			local data = Data.Find(vehicleName)
			if data then
				for scriptName, regions in pairs(data) do
					for _, region in ipairs(regions) do
						Data.Remove(scriptName, region, vehicleName, true)
					end
				end
			end
		end
	end
	
	VZDUtils.clearSpawnZones(vehiclesBlacklist, false)
end

local removeVehicle = function(vehicle)
	if not vehicle then return end
	if isMultiplayer() and not isServer() then return end
	local scriptName = vehicle:getScriptName()
	if vehiclesBlacklist[scriptName] then
		__utils.delay(function(vehicle)
			vehicle:permanentlyRemove()
		end,
		1, vehicle)
	end
end

Events.OnLoadedMapZones.Add(doVehiclesBlacklist)
Events.OnLoadMapZones.Add(doNoTrailers)
Events.OnLoadMapZones.Add(doNoBurnt)
Events.OnLoadMapZones.Add(doBurntParams)
Events.OnSpawnVehicleStart.Add(removeVehicle)