local __vehicleUtils = require("YAPZLib/VehicleUtils")
local __utils = require("YAPZLib/Utils")

local doAngledVehicleSpawnPosition = function(vehicle)
	if isMultiplayer() and not isServer() then return end
	if not __vehicleUtils.checkChunk(vehicle) then return end
	local zoneName = __vehicleUtils.getVehicleZone(vehicle)
	if not zoneName then return end
	zoneName = zoneName:lower()
	local zoneDist = VehicleZoneDistribution[zoneName]
	if zoneDist and zoneDist.positionAngles ~= nil and not zoneDist.randomAngle then
	if not zoneDist then return end
		if zoneDist.positionAngles[3] ~= true then
			local angles = zoneDist.positionAngles
			local angle = angles[ZombRand(#angles)+1]
			__vehicleUtils.rotate(vehicle, angle)
		end
	end
end

local doAngledVehicleSpawnPositionBetween = function(vehicle)
	if isMultiplayer() and not isServer() then return end
	if not __vehicleUtils.checkChunk(vehicle) then return end
	local zoneName = __vehicleUtils.getVehicleZone(vehicle)
	if not zoneName then return end
	zoneName = zoneName:lower()
	local zoneDist = VehicleZoneDistribution[zoneName]
	if zoneDist and zoneDist.positionAngles ~= nil and not zoneDist.randomAngle then
		if zoneDist.positionAngles[3] == true then
			local angle = ZombRandFloat(zoneDist.positionAngles[1], zoneDist.positionAngles[2])
			__vehicleUtils.rotate(vehicle, angle)
		end
	end
end

local doMissingParts = function(vehicle)
	if isMultiplayer() and not isServer() then return end
	if not __vehicleUtils.checkChunk(vehicle) then return end
	if vehicle:isGoodCar() or vehicle:isBurnt() then return end
	local zoneName = __vehicleUtils.getVehicleZone(vehicle)
	if not zoneName then return end
	zoneName = zoneName:lower()
	local zoneDist = VehicleZoneDistribution[zoneName]
	if not zoneDist then return end
	if not zoneDist.missingParts then return end
	if not zoneDist.missingParts.chance then zoneDist.missingParts.chance = 16 end
	if not zoneDist.missingParts.percent then zoneDist.missingParts.percent = 8 end
	__vehicleUtils.removeParts(vehicle, zoneDist.missingParts.chance, zoneDist.missingParts.percent)
end

local doMissingPartsDelay = function(vehicle)
	local delay = 5
	if isMultiplayer() then
		if not isServer() then return end
		delay = 10
	end
	
	__utils.delay(doMissingParts, delay, vehicle)
end

local doSkinIndex = function(vehicle)
	if isMultiplayer() and not isServer() then return end
	if not __vehicleUtils.checkChunk(vehicle) then return end
	local scriptName = vehicle:getScriptName()
	local skinIndex = vehicle:getSkinIndex()
	local zoneName = __vehicleUtils.getVehicleZone(vehicle)
	if not zoneName then return end
	zoneName = zoneName:lower()
	local zoneDist = VehicleZoneDistribution[zoneName]
	if not zoneDist or not zoneDist.vehicles or not zoneDist.vehicles[scriptName] then return end
	local skins = zoneDist.vehicles[scriptName].skins
	if not skins or __utils.tableIsEmpty(skins) or __utils.tableHas(skins, skinIndex) then return end
	skinIndex = skins[ZombRand(#skins) + 1]
	if skinIndex then
		vehicle:setSkinIndex(skinIndex)
	end
end

Events.OnSpawnVehicleStart.Add(doSkinIndex)
Events.OnSpawnVehicleEnd.Add(doAngledVehicleSpawnPositionBetween)
Events.OnSpawnVehicleEnd.Add(doAngledVehicleSpawnPosition)
Events.OnSpawnVehicleEnd.Add(doMissingPartsDelay)