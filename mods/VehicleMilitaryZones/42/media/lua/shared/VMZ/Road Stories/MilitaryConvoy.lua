local ISRVSBase = require("YAPZLib/RVSBase")

MilitaryConvoy = ISRVSBase:derive("MilitaryConvoy")
MilitaryConvoy.name = "Military Convoy"
MilitaryConvoy.minZoneWidth = 5
MilitaryConvoy.minZoneHeight = 30
MilitaryConvoy.minDays = 5
MilitaryConvoy.maxDays = 90

local getExludeList = function()
	local exlude = {}
	
	for vehicleName, data in pairs(VehicleZoneDistribution.military_vehicle_heavy.vehicles) do
		local script = ScriptManager.instance:getVehicle(vehicleName)
		if script then
			local size = round(script:getExtents():z(), 1)
			if size >= 8 then
				table.insert(exlude, vehicleName)
			elseif script:getAttachmentById("hook") then
				table.insert(exlude, vehicleName)
			end
		else
			table.insert(exlude, vehicleName)
		end
	end
	
	return exlude
end

MilitaryConvoy.spawn = function(self)
	local offsetY2 = 0
	local offsetY1 = offsetY2 - 12
	local offsetY3 = offsetY2 + 7

	local vehicleName1 = ISRVSBase.getVehicleFromZone("military_vehicle_heavy", getExludeList(), true)

	local script = vehicleName1 ~= nil and ScriptManager.instance:getVehicle(vehicleName1)
	if script then
		local size = round(script:getExtents():z(), 1)
		if size < 5 then
		elseif size >= 5 and size < 6 then
			offsetY3 = offsetY3 + 0.25
			offsetY1 = offsetY1 - 0.25
		elseif size >= 6 and size < 7 then
			offsetY3 = offsetY3 + 0.5
			offsetY1 = offsetY1 - 0.5
		elseif size >= 7 and size < 8 then
			offsetY3 = offsetY3 + 0.75
			offsetY1 = offsetY1 - 0.75
		end
	end
	
	local skins1 = vehicleName1 ~= nil and VehicleZoneDistribution.military_vehicle_heavy.vehicles[vehicleName1].skins
	local vehicle1 = self:addVehicle(vehicleName1, 0, offsetY1, ZombRandFloat(-7.5, 7.5), skins1, "military_vehicle_heavy", false)
	if vehicle1 then
		vehicle1:setAlarmed(false)
		vehicle1:setGeneralPartCondition(ZombRandFloat(0.2, 0.7), ZombRand(40, 71))
		
		local trailerName = ISRVSBase.getAllowedTrailerFromZone(vehicleName1, "military_trailer_heavy", nil, true)
		local trailerScript = trailerName ~= nil and ScriptManager.instance:getVehicle(trailerName)
		local trailerSkins = trailerName ~= nil and VehicleZoneDistribution.military_trailer_heavy.vehicles[trailerName].skins
		if trailerScript then
			self:addTrailer(trailerName, vehicle1, (trailerScript:getPartById("DAMNSemiTrailerHook") ~= nil and 7) or 3, trailerSkins)
		end
		
		local outfit = "ArmyCamoGreen"
		if vehicle1:getZombieType() then
			outfit = vehicle1:getRandomZombieType()
		end
		
		if vehicle1:getAllSeatParts() then
			self:addZombiesOnVehicle(vehicle1, ZombRand(2, vehicle1:getAllSeatParts():size() + 1), outfit, 0)
		end
	end
	
	local vehicleName2 = ISRVSBase.getVehicleFromZone("military_vehicle_light", getExludeList(), true)
	local skins2 = vehicleName2 ~= nil and VehicleZoneDistribution.military_vehicle_light.vehicles[vehicleName2].skins
	local vehicle2 = self:addVehicle(ISRVSBase.getVehicleFromZone("military_vehicle_light", nil, true), 0, offsetY2, ZombRandFloat(-7.5, 7.5), skins2, "military_vehicle_light", false)
	if vehicle2 then
		vehicle2:setAlarmed(false)
		vehicle2:setGeneralPartCondition(ZombRandFloat(0.2, 0.5), ZombRand(50, 81))
		
		local trailerName = ISRVSBase.getVehicleFromZone("military_trailer_light", nil, true)
		local trailerSkins = trailerName ~= nil and VehicleZoneDistribution.military_trailer_light.vehicles[trailerName].skins
		self:addTrailer(trailerName, vehicle2, 3, trailerSkins)
		
		local outfit = "ArmyCamoGreen"
		if vehicle2:getZombieType() then
			outfit = vehicle2:getRandomZombieType()
		end
		
		if vehicle2:getAllSeatParts() then
			self:addZombiesOnVehicle(vehicle2, ZombRand(2, vehicle2:getAllSeatParts():size() + 1), outfit, 0)
		end
		
		for x = -2, 2 do
			for y = offsetY2 - 2, offsetY2 + 2 do
				if ZombRand(3) == 0 then
					self:addBloodSplat(x, y, self.spawnPoint.z, ZombRand(3, 9))
				end
			end
		end
	end
	
	local zoneName3 = (ZombRand(2) == 0 and "military_vehicle_light") or "military_vehicle_heavy"
	local vehicleName3 = ISRVSBase.getVehicleFromZone(zoneName3, nil, true)
	local skins3 = vehicleName3 ~= nil and VehicleZoneDistribution[zoneName3].vehicles[vehicleName3].skins
	local vehicle3 = self:addVehicle(vehicleName3, 0, offsetY3, ((ZombRand(2) == 0) and 60 or -60) + ZombRandFloat(-15, 15), skins3, zoneName3, false)
	if vehicle3 then
		vehicle3:setAlarmed(false)
		vehicle3:setGeneralPartCondition(ZombRandFloat(0.15, 0.45), ZombRand(60, 91))
		if ZombRand(3) == 0 then
			vehicle3:setHeadlightsOn(true)
			vehicle3:setLightbarLightsMode(2)
			local battery = vehicle3:getBattery()
			if battery then
				battery:setLastUpdated(0)
			end
		end
		
		local points = {}
		for x = -4, 4 do
			for y = offsetY3 - 4, offsetY3 + 4 do
				if ZombRand(3) == 0 then
					self:addBloodSplat(x, y, self.spawnPoint.z, ZombRand(5, 11))
				end
				
				if not self:getSquare(x, y, self.spawnPoint.z):isVehicleIntersecting() then
					table.insert(points, { x = x, y = y })
				end
			end
		end
		
		local outfit = "ArmyCamoGreen"
		if vehicle3:getZombieType() then
			outfit = vehicle3:getRandomZombieType()
		end
		
		local randNum = ZombRand(2, vehicle3:getAllSeatParts():size() + 1)
		for i = 1, randNum do
			local point = points[ZombRand(#points) + 1]
			self:addDeadBody(point.x, point.y, self.spawnPoint.z, outfit, ZombRand(6, 12), nil, 0, 25, false)
		end
		
		self:addZombiesOnVehicle(vehicle3, ZombRand(8, 16), "Bandit", 10, true)
	end
end

local initChance = function()
	MilitaryConvoy.chance = 10 * SandboxVars.VMZ.RoadStoriesMultiplier
end

Events.OnInitGlobalModData.Add(initChance)