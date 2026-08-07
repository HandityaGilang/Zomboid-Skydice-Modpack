local ISRVSBase = require("YAPZLib/RVSBase")

BiohazardCrash = ISRVSBase:derive("BiohazardCrash")
BiohazardCrash.name = "Biohazard Crash"
BiohazardCrash.minZoneWidth = 6
BiohazardCrash.minZoneHeight = 11
BiohazardCrash.minDays = 5
BiohazardCrash.maxDays = 90

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

BiohazardCrash.spawn = function(self)
	local vehicleName1 = ISRVSBase.getVehicleFromZone("military_vehicle_light", nil, true)
	local skins1 = vehicleName1 ~= nil and VehicleZoneDistribution.military_vehicle_light.vehicles[vehicleName1].skins
	local vehicle1 = self:addVehicle(vehicleName1, 2, 2, ZombRandFloat(-40, -20), niskins1l, "military_vehicle_light", true)
	if vehicle1 then
		vehicle1:setAlarmed(false)
		vehicle1:setGeneralPartCondition(ZombRandFloat(0.05, 0.15), ZombRand(80, 96))
		if ZombRand(3) == 0 then
			vehicle1:setHeadlightsOn(true)
			vehicle1:setLightbarLightsMode(2)
			local battery = vehicle1:getBattery()
			if battery then
				battery:setLastUpdated(0)
			end
		end
	
		if vehicle1:getAllSeatParts() then
			self:addZombiesOnVehicle(vehicle1, ZombRand(2, vehicle1:getAllSeatParts():size() + 1), "HazardSuit", 0)
		end
	end
	
	local vehicleName2 = ISRVSBase.getVehicleFromZone("military_vehicle_heavy", getExludeList(), true)
	local skins2 = vehicleName2 ~= nil and VehicleZoneDistribution.military_vehicle_heavy.vehicles[vehicleName2].skins
	local vehicle2 = self:addVehicle(vehicleName2, -1, -6, ZombRandFloat(5, 25), skins2, "military_vehicle_heavy", false)
	if vehicle2 then
		vehicle2:setAlarmed(false)
		vehicle2:setGeneralPartCondition(ZombRandFloat(0.1, 0.5), ZombRand(50, 81))
		if ZombRand(3) == 0 then
			vehicle2:setHeadlightsOn(true)
			vehicle2:setLightbarLightsMode(2)
			local battery = vehicle2:getBattery()
			if battery then
				battery:setLastUpdated(0)
			end
		end
		
		if vehicle2:getAllSeatParts() then
			self:addZombiesOnVehicle(vehicle2, ZombRand(2, vehicle2:getAllSeatParts():size() + 1), "HazardSuit", 0)
		end
	end
	
	for x = -4, 4 do
		for y = -11, 6 do
			if ZombRand(3) == 0 then
				self:addBloodSplat(x, y, self.spawnPoint.z, ZombRand(4, 10))
			end
			
			if ZombRand(8) == 0 then
				self:addDeadBody(x, y, self.spawnPoint.z, nil, ZombRand(3, 9), nil, 33, 10, false)
			end
			
			if ZombRand(33) == 0 then
				self:addWorldInventoryItem(x, y, self.spawnPoint.z, "Base.Bag_ProtectiveCaseBulkyHazard", ZombRand(100)/100, ZombRand(100)/100, 0)
			end
		end
	end
end

local initChance = function()
	BiohazardCrash.chance = 5 * SandboxVars.VMZ.RoadStoriesMultiplier
end

Events.OnInitGlobalModData.Add(initChance)