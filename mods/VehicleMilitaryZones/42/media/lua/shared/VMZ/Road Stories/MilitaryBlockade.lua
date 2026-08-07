local ISRVSBase = require("YAPZLib/RVSBase")
local invertAngle = require("YAPZLib/Utils").invertAngle

MilitaryBlockade = ISRVSBase:derive("MilitaryBlockade")
MilitaryBlockade.name = "Military Blockade"
MilitaryBlockade.minZoneWidth = 8
MilitaryBlockade.minZoneHeight = 8
MilitaryBlockade.minDays = 5
MilitaryBlockade.maxDays = 90

local calcOffset = function(zoneName, exclude, offsetX, offsetY, zoneWidth)
	local vehicleName = ISRVSBase.getVehicleFromZone(zoneName, exclude, true)
	if not vehicleName then return end
	
	local script = ScriptManager.instance:getVehicle(vehicleName)
	if script then
		local size = round(script:getExtents():z(), 1)
		
		if size >= 5 and size < 7 then
			offsetX = 2.25
			offsetY = 1.3
		elseif size >= 7 then
			offsetX = 2.9
			offsetY = 1.3
		else
			if zoneWidth >= 10 then
				offsetX = offsetX + 0.8
				offsetY = offsetY - 0.65
			end
		end
		
		return offsetX - round(ScriptManager.instance:getVehicle(vehicleName):getCenterOfMassOffset():z(), 2), offsetY, vehicleName
	end
	
	return nil
end

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

MilitaryBlockade.spawn = function(self)
	local zoneName, exclude = "military_vehicle_light", nil
	if self.zoneWidth >= 12 then
		if ZombRand(3) == 0 then
			zoneName, exclude = "military_vehicle_heavy", getExludeList()
		end
	end
	
	local offsetX1 = 1.5
	local offsetY1 = 1
	local vehicleName1 = ""
	offsetX1, offsetY1, vehicleName1 = calcOffset(zoneName, exclude, offsetX1, offsetY1, self.zoneWidth)
	if not offsetX1 or not offsetY1 or not vehicleName1 then return end
	
	local offsetX2 = 1.5
	local offsetY2 = 1
	local vehicleName2 = ""
	offsetX2, offsetY2, vehicleName2 = calcOffset(zoneName, exclude, offsetX2, offsetY2, self.zoneWidth)
	if not offsetX2 or not offsetY2 or not vehicleName2 then return end
	
	local angle1 = ((ZombRand(2) == 0) and 90 or -90) + ZombRandFloat(-7.5, 7.5)
	local skins1 = vehicleName1 ~= nil and VehicleZoneDistribution[zoneName].vehicles[vehicleName1].skins
	local vehicle1 = self:addVehicle(vehicleName1, -offsetX1, offsetY1, angle1, skins1, zoneName, false)
	if vehicle1 then
		vehicle1:setAlarmed(false)
		vehicle1:setGeneralPartCondition(ZombRandFloat(0.2, 0.7), ZombRand(40, 71))
		if ZombRand(3) == 0 then
			vehicle1:setHeadlightsOn(true)
			vehicle1:setLightbarLightsMode(2)
			local battery = vehicle1:getBattery()
			if battery then
				battery:setLastUpdated(0)
			end
		end
		
		local outfit = "ArmyCamoGreen"
		if vehicle1:getZombieType() then
			outfit = vehicle1:getRandomZombieType()
		end
		
		if vehicle1:getAllSeatParts() then
			self:addZombiesOnVehicle(vehicle1, ZombRand(2, vehicle1:getAllSeatParts():size() + 1), outfit, 0)
		end
	end
	
	local angle2 = invertAngle(angle1) + ZombRandFloat(-2.5, 2.5)
	local skins2 = vehicleName2 ~= nil and VehicleZoneDistribution[zoneName].vehicles[vehicleName2].skins
	local vehicle2 = self:addVehicle(vehicleName2, offsetX2, -offsetY2, angle2, skins2, zoneName, false)
	if vehicle2 then
		vehicle2:setAlarmed(false)
		vehicle2:setGeneralPartCondition(ZombRandFloat(0.2, 0.7), ZombRand(40, 71))
		if ZombRand(3) == 0 then
			vehicle2:setHeadlightsOn(true)
			vehicle2:setLightbarLightsMode(2)
			local battery = vehicle2:getBattery()
			if battery then
				battery:setLastUpdated(0)
			end
		end
		
		local outfit = "ArmyCamoGreen"
		if vehicle2:getZombieType() then
			outfit = vehicle2:getRandomZombieType()
		end
		
		if vehicle2:getAllSeatParts() then
			self:addZombiesOnVehicle(vehicle2, ZombRand(2, vehicle2:getAllSeatParts():size() + 1), outfit, 0)
		end
	end
end

local initChance = function()
	MilitaryBlockade.chance = 20 * SandboxVars.VMZ.RoadStoriesMultiplier
end

Events.OnInitGlobalModData.Add(initChance)