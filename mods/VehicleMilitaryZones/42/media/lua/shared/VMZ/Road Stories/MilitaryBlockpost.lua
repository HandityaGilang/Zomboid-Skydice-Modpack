local ISRVSBase = require("YAPZLib/RVSBase")
local createTent = require("VMZ/Road Stories/MilitaryBlockpostTent")

MilitaryBlockpost = ISRVSBase:derive("MilitaryBlockpost")
MilitaryBlockpost.name = "Military Blockpost"
MilitaryBlockpost.minZoneWidth = 12
MilitaryBlockpost.minZoneHeight = 20
MilitaryBlockpost.minDays = 5
MilitaryBlockpost.maxDays = 90

MilitaryBlockpost.spawn = function(self)
	local horizontal = self.direction == IsoDirections.W or self.direction == IsoDirections.E
	
	local vehicleName1 = ISRVSBase.getVehicleFromZone("military_vehicle_heavy", nil, true)
	local skins1 = vehicleName1 ~= nil and VehicleZoneDistribution.military_vehicle_heavy.vehicles[vehicleName1].skins
	local vehicle1 = self:addVehicle(vehicleName1, -3, 6, ZombRandFloat(-5, 5), skins1, "military_vehicle_heavy", false)
	if vehicle1 then
		vehicle1:setAlarmed(false)
		vehicle1:setGeneralPartCondition(ZombRandFloat(0.2, 0.7), ZombRand(40, 71))
		
		local trailerName = ISRVSBase.getAllowedTrailerFromZone(vehicleName1, "military_trailer_heavy", nil, true)
		local trailerScript = trailerName ~= nil and ScriptManager.instance:getVehicle(trailerName)
		local trailerSkins = trailerName ~= nil and VehicleZoneDistribution.military_trailer_heavy.vehicles[trailerName].skins
		if trailerScript then
			if ZombRand(3) == 0 then
				self:addTrailer(trailerName, vehicle1, (trailerScript:getPartById("DAMNSemiTrailerHook") ~= nil and 7) or 3, trailerSkins)
			end
		end
		
		local outfit = "ArmyCamoGreen"
		if vehicle1:getZombieType() then
			outfit = vehicle1:getRandomZombieType()
		end
		
		if vehicle1:getAllSeatParts() then
			self:addZombiesOnVehicle(vehicle1, ZombRand(2, vehicle1:getAllSeatParts():size() + 1), outfit, 0)
		end
		
		for x = -6, -2 do
			for y = 0, 4 do
				if ZombRand(3) == 0 then
					self:addBloodSplat(x, y, self.spawnPoint.z, ZombRand(3, 9))
				end
			end
		end
	end
	
	local vehicleName2 = ISRVSBase.getVehicleFromZone("military_vehicle_light", nil, true)
	local skins2 = vehicleName2 ~= nil and VehicleZoneDistribution.military_vehicle_light.vehicles[vehicleName2].skins
	local vehicle2 = self:addVehicle(vehicleName2, 3, 2, 165 + ZombRandFloat(-10, 10), skins2, "military_vehicle_light", false)
	if vehicle2 then
		vehicle2:setAlarmed(false)
		vehicle2:setGeneralPartCondition(ZombRandFloat(0.2, 0.7), ZombRand(40, 71))
		
		local outfit = "ArmyCamoGreen"
		if vehicle2:getZombieType() then
			outfit = vehicle2:getRandomZombieType()
		end
		
		if vehicle2:getAllSeatParts() then
			self:addZombiesOnVehicle(vehicle2, ZombRand(2, vehicle2:getAllSeatParts():size() + 1), outfit, 0)
		end
	end
	
	local vehicleName3 = ISRVSBase.getVehicleFromZone("military_container", nil, true)
	local skins3 = vehicleName3 ~= nil and VehicleZoneDistribution.military_container.vehicles[vehicleName3].skins
	local vehicle3 = self:addVehicle(vehicleName3, -4.5, -10, 100 + ZombRandFloat(-10, 10), skins3, "military_container", false)
	if vehicle3 then
		vehicle3:setGeneralPartCondition(ZombRandFloat(0.5, 0.9), ZombRand(50, 91))
	end
	
	self:addTileObjectBySpriteName(-6, 7, self.spawnPoint.z, "fencing_01_96", true, false)
	self:addTileObjectBySpriteName(0, 7, self.spawnPoint.z, "fencing_01_96", true, false)
	self:addTileObjectBySpriteName(5, 7, self.spawnPoint.z, "fencing_01_96", true, false)
	
	if not horizontal then
		self:addTileObjectBySpriteName(-5, -8, self.spawnPoint.z, "carpentry_02_13", true, false)
	else
		self:addTileObjectBySpriteName(-5, -8, self.spawnPoint.z, "carpentry_02_12", true, false)
	end
	
	for x = 1, 4 do
		if not horizontal then
			self:addTileObjectBySpriteName(x, 7, self.spawnPoint.z, "carpentry_02_13", true, false)
		else
			self:addTileObjectBySpriteName(x, 7, self.spawnPoint.z, "carpentry_02_12", true, false)
		end
	end
	
	for y = -7, 6 do
		if not horizontal then
			self:addTileObjectBySpriteName(-6, y, self.spawnPoint.z, "carpentry_02_12", true, false)
		else
			self:addTileObjectBySpriteName(-6, y, self.spawnPoint.z, "carpentry_02_13", true, false)
		end
	end
	
	for y = 0, 6 do
		if not horizontal then
			self:addTileObjectBySpriteName(5, y, self.spawnPoint.z, "carpentry_02_12", true, false)
		else
			self:addTileObjectBySpriteName(5, y, self.spawnPoint.z, "carpentry_02_13", true, false)
		end
	end
	
	self:addTileObjectBySpriteName(-4, -8, self.spawnPoint.z, "fencing_01_96", true, false)
	self:addTileObjectBySpriteName(-6, -8, self.spawnPoint.z, "fencing_01_96", true, false)
	self:addTileObjectBySpriteName(4, -9, self.spawnPoint.z, "location_military_generic_01_14", true, false)
	
	for x = 2, 5 do
		for y = -8, -3 do
			self:addFloor(x, y, self.spawnPoint.z, "floors_interior_tilesandwood_01_18")
		end
	end
	
	for x = 2, 5 do
		for y = -8, -3 do
			self:addFloor(x, y, self.spawnPoint.z + 1, "ceilings_01_0", true, false)
		end
	end
	
	for x = 1, 5 do
		for y = -8, -2 do
			if ZombRand(3) == 0 then
				self:addBloodSplat(x, y, self.spawnPoint.z, ZombRand(3, 9))
			end
		end
	end
	
	if ZombRand(3) == 0 then
		local offsetX, offsetY = self:calcOffset(1, -5)
		local square = getCell():getGridSquare(self:roundSqCoord(self.spawnPoint.x + offsetX), self:roundSqCoord(self.spawnPoint.y + offsetY), self.spawnPoint.z)
		square:spawnRandomGenerator()
	end
	
	local dir = tostring(self.direction)
	if createTent[dir] then createTent[dir](self) end
end

local initChance = function()
	MilitaryBlockpost.chance = 10 * SandboxVars.VMZ.RoadStoriesMultiplier
end

Events.OnInitGlobalModData.Add(initChance)