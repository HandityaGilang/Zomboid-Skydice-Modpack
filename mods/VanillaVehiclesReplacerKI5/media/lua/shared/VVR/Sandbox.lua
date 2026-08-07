require "VVR/Data"
require "VVR/Utils"

VVR = VVR or {}
VVR.Sandbox = {}
VVR.Sandbox.VehiclesBlacklist = {}

function VVR.Sandbox.NoTrailers()
	if not VehicleZoneDistribution then return end
	VVR.Sandbox.NoTrailersVar = SandboxVars.VVR.NoTrailers
	if SandboxVars.VVR.NoTrailers == true then
		if getActivatedMods():contains("KI5trailers") then
			require "KI5trailers_SpawnList"
			VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5utilityLarge"] = nil
			VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5utilityMedium"] = nil
			VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5utilitySmall"] = nil
			VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5cargoLarge"] = nil
			VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5cargoMedium"] = nil
			VehicleZoneDistribution.bad.vehicles["Base.TrailerKI5cargoSmall"] = nil
			VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerKI5utilityLarge"] = nil
			VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerKI5utilityMedium"] = nil
			VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerKI5utilitySmall"] = nil
			VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerKI5cargoLarge"] = nil
			VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerKI5cargoMedium"] = nil
			VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerKI5cargoSmall"] = nil
		end
		if getActivatedMods():contains("92amgeneralM998") then
			require "92amgeneralM998SpawnList"
			VehicleZoneDistribution.trafficjams.vehicles["Base.TrailerM101A3cargo"] = nil
		end
	end
end

function VVR.Sandbox.NoBurnt()
	if not VehicleZoneDistribution then return end
	if SandboxVars.VVR.NoBurntTJ == 0 and SandboxVars.VVR.NoBurntJY == 0 and SandboxVars.VVR.NoBurntTP == 0 then
		VehicleZoneDistribution.normalburnt.vehicles = VehicleZoneDistribution.trafficjams.vehicles
		VehicleZoneDistribution.specialburnt.vehicles = VehicleZoneDistribution.trafficjams.vehicles
	else
		VehicleZoneDistribution.trafficjams.chanceToSpawnBurnt = SandboxVars.VVR.NoBurntTJ
		VehicleZoneDistribution.trafficjamn.chanceToSpawnBurnt = SandboxVars.VVR.NoBurntTJ
		VehicleZoneDistribution.trafficjamw.chanceToSpawnBurnt = SandboxVars.VVR.NoBurntTJ
		VehicleZoneDistribution.trafficjame.chanceToSpawnBurnt = SandboxVars.VVR.NoBurntTJ
		VehicleZoneDistribution.junkyard.chanceToSpawnBurnt = SandboxVars.VVR.NoBurntJY
		VehicleZoneDistribution.trailerpark.chanceToSpawnBurnt = SandboxVars.VVR.NoBurntTP
	end
end
	
function VVR.Sandbox.BurntParams()
	if not VehicleZoneDistribution then return end
	VehicleZoneDistribution.specialburnt.chanceToPartDamage = 100
	VehicleZoneDistribution.specialburnt.chanceToSpawnKey = 10
	VehicleZoneDistribution.specialburnt.baseVehicleQuality = (SandboxVars.VVR.VehiCond/100)*2
	VehicleZoneDistribution.normalburnt.chanceToPartDamage = 100
	VehicleZoneDistribution.normalburnt.chanceToSpawnKey = 10
	VehicleZoneDistribution.normalburnt.baseVehicleQuality = (SandboxVars.VVR.VehiCond/100)*2
end

function VVR.Sandbox.GetVehiclesBlacklist()
	local VehiclesBlacklist = {}
	for vehicleName in string.gmatch(SandboxVars.VVR.VehiclesBlacklist, "[^;]+") do
		vehicleName = vehicleName:match("^%s*(.-)%s*$")
		VehiclesBlacklist[vehicleName] = true
	end
	return VehiclesBlacklist
end

function VVR.Sandbox.DoVehiclesBlacklist()
	VVR.Sandbox.VehiclesBlacklist = VVR.Sandbox.GetVehiclesBlacklist()
	for vehicleName, state in pairs(VVR.Sandbox.VehiclesBlacklist) do
		if state then
			VVR.Utils.NilSpawnZones(vehicleName)
			local Data = VVR.Data.Find(vehicleName)
			for _, scriptName in ipairs(Data) do
				VVR.Data.Remove(scriptName, vehicleName, true)
			end
		end
	end
end

function VVR.Sandbox.RemoveVehicle(vehicle)
	if not vehicle then return end
	local scriptName = vehicle:getScriptName()
	if not getWorld():getGameMode() == "Multiplayer" then
		if VVR.Sandbox.VehiclesBlacklist[scriptName] then
			VVR.Delay.Add(function(vehicle)
				vehicle:permanentlyRemove()
			end, 1, { vehicle })
		end
	end
end

Events.OnLoadMapZones.Add(VVR.Sandbox.NoTrailers)
Events.OnLoadMapZones.Add(VVR.Sandbox.NoBurnt)
Events.OnLoadMapZones.Add(VVR.Sandbox.BurntParams)
Events.OnLoadMapZones.Add(VVR.Sandbox.DoVehiclesBlacklist)

function VVR.Sandbox.RemoveVehicleOnSquare(square)
	if not square then return end 
	local vehicle = square:getVehicleContainer()
	if not vehicle then return end
	if not instanceof(vehicle, "BaseVehicle") then return end
	VVR.Sandbox.RemoveVehicle(vehicle)
end

function VVR.Sandbox.RemoveVehicleOnContainer(roomType, containerType, container)
	if not container then return end
	local vehicle = container:getParent()
	if not vehicle then return end
	if not instanceof(vehicle, "BaseVehicle") then return end
	VVR.Sandbox.RemoveVehicle(vehicle)
end

Events.LoadGridsquare.Add(VVR.Sandbox.RemoveVehicleOnSquare)
Events.OnFillContainer.Add(VVR.Sandbox.RemoveVehicleOnContainer)