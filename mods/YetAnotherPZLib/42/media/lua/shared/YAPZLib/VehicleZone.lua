local __utils = require("YAPZLib/Utils")

local vehicleZone = {}

vehicleZone.changeName = function(zoneX, zoneY, zoneZ, newName, doModdedCheck)
	if not __utils.checkArgs(
		zoneX, "number", true,
		zoneY, "number", true,
		zoneZ, "number", true,
		newName, "string", true,
		doModdedCheck, "boolean", false
	) then return end

	local vehicleZone = getVehicleZoneAt(zoneX, zoneY, zoneZ)
	if vehicleZone ~= nil then
		local shouldChange = true
		if doModdedCheck then
			local cx, cy = __utils.getCellCoordinates(zoneX, zoneY)
			shouldChange = not __utils.cellIsModded(cx, cy)
		end
		if shouldChange and newName then
			vehicleZone:setName(newName)
			vehicleZone:setOriginalName(newName)
		end
	end
end

vehicleZone.changePosition = function(zoneX, zoneY, zoneZ, newX, newY, doModdedCheck)
	if not __utils.checkArgs(
		zoneX, "number", true,
		zoneY, "number", true,
		zoneZ, "number", true,
		newX, "number", false,
		newY, "number", false,
		doModdedCheck, "boolean", false
	) then return end

	local vehicleZone = getVehicleZoneAt(zoneX, zoneY, zoneZ)
	if vehicleZone ~= nil then
		local shouldChange = true
		if doModdedCheck then
			local cx, cy = __utils.getCellCoordinates(zoneX, zoneY)
			shouldChange = not __utils.cellIsModded(cx, cy)
		end
		
		if shouldChange then
			if newX ~= nil then
			vehicleZone:setX(newX)
			end
			if newY ~= nil and newX ~= nil then
				local newVehicleZone = getVehicleZoneAt(newX, zoneY, zoneZ)
				newVehicleZone:setY(newY)
			elseif newY ~= nil then
				vehicleZone:setY(newY)
			end
		end
	end
end

vehicleZone.changeSize = function(zoneX, zoneY, zoneZ, newWidth, newHeight, doModdedCheck)
	if not __utils.checkArgs(
		zoneX, "number", true,
		zoneY, "number", true,
		zoneZ, "number", true,
		newWidth, "integer", false,
		newHeight, "integer", false,
		doModdedCheck, "boolean", false
	) then return end

	local vehicleZone = getVehicleZoneAt(zoneX, zoneY, zoneZ)
	if vehicleZone ~= nil then
		local shouldChange = true
		if doModdedCheck then
			local cx, cy = __utils.getCellCoordinates(zoneX, zoneY)
			shouldChange = not __utils.cellIsModded(cx, cy)
		end
		
		if shouldChange then
			if newWidht ~= nil then
				vehicleZone:setW(newWidht)
			end
			if newHeight ~= nil then
				vehicleZone:setH(newHeight)
			end
		end
	end
end

vehicleZone.remove = function(zoneX, zoneY, zoneZ)
	if not __utils.checkArgs(
		zoneX, "number", true,
		zoneY, "number", true,
		zoneZ, "number", true
	) then return end

	local vehicleZone = getVehicleZoneAt(zoneX, zoneY, zoneZ)
	if vehicleZone ~= nil then
		vehicleZone:setW(0)
		vehicleZone:setH(0)
	end
end

vehicleZone.register = function(zoneObjs, doModdedCheck)
	if not __utils.checkArgs(
		zoneObjs, "list", true,
		doModdedCheck, "boolean", false
	) then return end

	for _, vehicleZone in ipairs(zoneObjs) do
		if vehicleZone.type == "ParkingStall" then
			local shouldRegister = true
			if doModdedCheck then
				local cx, cy = __utils.getCellCoordinates(vehicleZone.x, vehicleZone.y)
				shouldRegister = not __utils.cellIsModded(cx, cy)
			end
			
			if shouldRegister then
				local newVehicleZone = getWorld():registerVehiclesZone(vehicleZone.name, vehicleZone.type, vehicleZone.x, vehicleZone.y, vehicleZone.z, vehicleZone.width, vehicleZone.height, vehicleZone.properties)
				if newVehicleZone == nil then
					getWorld():registerZone(vehicleZone.name, vehicleZone.type, vehicleZone.x, vehicleZone.y, vehicleZone.z, vehicleZone.width, vehicleZone.height)
				end
			end
		end
	end
end

return vehicleZone