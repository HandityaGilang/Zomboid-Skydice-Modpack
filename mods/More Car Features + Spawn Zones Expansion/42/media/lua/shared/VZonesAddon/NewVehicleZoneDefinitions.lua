NewVZones = NewVZones or {}
--I DO NOT UNDERSTAND THIS FILE ANYMORE, SO I AM NOT TOUCHING IT UNLESS SOMETHING BREAKS !!!
function NewVZones.GamestaSetVehicleZones()
	local activatedMods = getActivatedMods()

	for zoneName, zoneData in pairs(VehicleZoneDistribution) do
		if type(zoneData) == "table" and zoneData.vehicles then
			if zoneData == VehicleZoneDistribution.modified_trfjm then
				zoneData.spawnRate = 90
				zoneData.chanceToSpawnBurnt = 30
				zoneData.baseVehicleQuality = 0.4
				zoneData.chanceToPartDamage = 60
				zoneData.chanceToSpawnKey = 90
				zoneData.chanceToSpawnNormal = 0
				zoneData.chanceToSpawnSpecial = 0
			elseif zoneData == VehicleZoneDistribution.junkyard then
				zoneData.spawnRate = 90
				zoneData.chanceToSpawnBurnt = 50
				zoneData.baseVehicleQuality = 0.5
				zoneData.chanceToPartDamage = 100
				zoneData.chanceToSpawnNormal = 0
				zoneData.chanceToSpawnSpecial = 0
			elseif zoneData == VehicleZoneDistribution.trafficjamw
				or zoneData == VehicleZoneDistribution.trafficjame
				or zoneData == VehicleZoneDistribution.trafficjamn
				or zoneData == VehicleZoneDistribution.trafficjams
			then
				zoneData.chanceToSpawnBurnt = 20
				zoneData.chanceToSpawnKey = 80
				zoneData.baseVehicleQuality = 0.4
				zoneData.chanceToPartDamage = 100
				zoneData.chanceToSpawnNormal = 0
				zoneData.chanceToSpawnSpecial = 0
			elseif SandboxVars.GamestaVehicleZones.spawnRate >= 0 and zoneData ~= (VehicleZoneDistribution.modified_trfjm or VehicleZoneDistribution.junkyard) then
				zoneData.spawnRate = SandboxVars.GamestaVehicleZones.spawnRate
			end

			if SandboxVars.GamestaVehicleZones.spawnRateBurnt >= 0 then
				zoneData.chanceToSpawnBurnt = SandboxVars.GamestaVehicleZones.spawnRateBurnt
			elseif activatedMods:contains("TheArk") then		--3707475814 NOT "BanditsWeekOneTheArk" ON THE WORKSHOP PAGE
				zoneData.chanceToSpawnBurnt = 100
			end

			if SandboxVars.GamestaVehicleZones.baseVehicleQuality >= 0 then
				zoneData.baseVehicleQuality = SandboxVars.GamestaVehicleZones.baseVehicleQuality
			end
			if SandboxVars.GamestaVehicleZones.chanceToPartDamage >= 0 then
				zoneData.chanceToPartDamage = SandboxVars.GamestaVehicleZones.chanceToPartDamage
			end

			--This is here because setting VehicleZoneDistribution.parkingstall.randomAngle ONLY works here, not even in the same conditions elsewhere under the same folder, file, or event. The rest of them are here as well for consistency and ease of access.
			VehicleZoneDistribution.parkingstall.randomAngle = SandboxVars.GamestaVehicleZones.randomAngle
			VehicleZoneDistribution.trailerpark.randomAngle = SandboxVars.GamestaVehicleZones.randomAngle
			VehicleZoneDistribution.police.randomAngle = SandboxVars.GamestaVehicleZones.randomAngle
			VehicleZoneDistribution.ambulance.randomAngle = SandboxVars.GamestaVehicleZones.randomAngle
			VehicleZoneDistribution.fire.randomAngle = SandboxVars.GamestaVehicleZones.randomAngle
			VehicleZoneDistribution.transit.randomAngle = SandboxVars.GamestaVehicleZones.randomAngle
		end
	end
end
Events.OnLoadedMapZones.Add(NewVZones.GamestaSetVehicleZones)
