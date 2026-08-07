local getVehicleOverallCondition = require("YAPZLib/VehicleUtils").getOverallCondition

local Utils = {}

Utils.GetPartsStats = function(vehicle)
	local partsStats = {}
	for i=0, vehicle:getPartCount()-1 do
		local part = vehicle:getPartByIndex(i)
		if not partsStats[part:getId()] then partsStats[part:getId()] = {} end
		partsStats[part:getId()].condition = part:getCondition()
		
		if part:isContainer() and not part:getItemContainer() then
			partsStats[part:getId()].contentAmount = part:getContainerContentAmount()/part:getContainerCapacity()
		end
		
		if part:getInventoryItem() == nil then
			partsStats[part:getId()].isMissing = true
		end
	end
	
	return partsStats
end

Utils.GetVehicleParams = function(vehicle)
	local vehicleParams = {}
	
	vehicleParams.partsStats = Utils.GetPartsStats(vehicle)
	vehicleParams.overallCondition = getVehicleOverallCondition(vehicle)
	vehicleParams.isSmashed = vehicle:isSmashed()
	vehicleParams.batteryCharge = vehicle:getBatteryCharge()
	vehicleParams.isBurnt = vehicle:isBurnt()
	vehicleParams.isGood = vehicle:isGoodCar()
	vehicleParams.bloodIntFront = vehicle:getBloodIntensity("Front")
	vehicleParams.bloodIntRight = vehicle:getBloodIntensity("Right")
	vehicleParams.bloodIntLeft = vehicle:getBloodIntensity("Left")
	vehicleParams.bloodIntRear = vehicle:getBloodIntensity("Rear")
	vehicleParams.rust = vehicle:getRust()
	vehicleParams.keySpawned = vehicle:getKeySpawned()
	
	local vzone = getVehicleZoneAt(vehicle:getX(), vehicle:getY(), vehicle:getZ())
	if vzone then
		vehicleParams.zoneName = vzone:getName()
		if vehicleParams.zoneName == "" then
			vehicleParams.zoneName = "parkingstall"
		end
	else
		vehicleParams.zoneName = nil
	end
	
	return vehicleParams
end

Utils.GetRearTire = function(vehicle)
	local part = vehicle:getPartById("TireRearLeft"):getInventoryItem() or vehicle:getPartById("TireRearRight"):getInventoryItem()
	if part then
		return instanceItem(part:getModule().."."..part:getType())
	end
	
	return nil
end

Utils.GetRandomRearTire = function(vehicle)
	local part = vehicle:getPartById("TireRearLeft")
	if part then
		for i = 0, part:getItemType():size() - 1 do
			if ZombRand(100) > (100 - (100 / part:getItemType():size())) or i == part:getItemType():size() - 1 then
				itemType = part:getItemType():get(i)
				return instanceItem(itemType)
			end
		end
	end
	
	return nil
end

Utils.AddZombieType = function(vehicleName, zombieType)
    local vehicle = ScriptManager.instance:getVehicle(vehicleName)
	if vehicle then
		vehicle:Load(vehicleName, table.concat({
			"{",
				"zombieType = ", zombieType, ",",
			"}",
		}, " "))
	end
end

return Utils