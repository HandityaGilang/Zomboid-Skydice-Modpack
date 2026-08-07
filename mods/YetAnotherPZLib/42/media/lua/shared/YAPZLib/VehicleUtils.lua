local __utils = require("YAPZLib/Utils")
local __utilTables = require("YAPZLib/JustTables")

local __vehicleUtils = {}

__vehicleUtils.getVehicleZone = function(vehicle)
	if not __utils.checkArgs(vehicle, "BaseVehicle", true) then return end

	local vehicleZone = getVehicleZoneAt(vehicle:getX(), vehicle:getY(), vehicle:getZ())
	
	if vehicle:getZone() == "" then
		return nil
	end
	
	return vehicle:getZone(), vehicleZone
end

__vehicleUtils.checkChunk = function(vehicle)
	if not __utils.checkArgs(vehicle, "BaseVehicle", true) then return false end

	local chunk = vehicle:getChunk()
	
	if not chunk then return false end
	if not chunk:isNewChunk() then return false end
	
	return true
end

__vehicleUtils.removePartWithNested = function(vehicle, part, maxAmount)
	if not __utils.checkArgs(
		vehicle, "BaseVehicle", true,
		part, "VehiclePart", true,
		maxAmount, "integer", false
	) then return end

	local checked = {}
	local removedParts = {}
	
	local function removePart(partToRemove)
		if not partToRemove or not partToRemove:getInventoryItem() then return end
		local partName = partToRemove:getId()
		if checked[partName] then return end
		checked[partName] = true
		
		local uninstall = partToRemove:getTable("uninstall")
		if uninstall and uninstall.requireUninstalled then
			for _, nestedPartName in ipairs(luautils.split(uninstall.requireUninstalled), ";") do
				local nestedPart = vehicle:getPartById(nestedPartName)
				if nestedPart then
					removePart(nestedPart)
				end
			end
		end
		
		if maxAmount ~= nil and maxAmount > 0 and #removedParts >= maxAmount then return end
		if partToRemove:isContainer() and not partToRemove:getItemContainer() then
			partToRemove:setContainerContentAmount(0)
		elseif partToRemove:getItemContainer() then
			__utils.clearContainer(partToRemove:getItemContainer())
		end
		
		partToRemove:setInventoryItem(nil)
		vehicle:transmitPartItem(partToRemove)
		table.insert(removedParts, partName)
	end
	
	removePart(part)
	return (#removedParts > 0) and removedParts or nil
end

__vehicleUtils.removeParts = function(vehicle, chance, percent)
	if not __utils.checkArgs(
		vehicle, "BaseVehicle", true,
		chance, "number", true,
		percent, "number", true
	) then return end

	if ZombRand(100) + 1 <= chance then
		local installedParts = __vehicleUtils.getInstalledParts(vehicle)
		local partsToRemove = math.ceil(#installedParts * percent / 100)
		
		for i = #installedParts, 2, -1 do
			local j = ZombRand(i) + 1
			installedParts[i], installedParts[j] = installedParts[j], installedParts[i]
		end
		
		local removedParts = {}
		removedParts.count = 0
		for i = 1, #installedParts do
			if removedParts.count >= partsToRemove then return end
			local partName = installedParts[i]
			if not removedParts[partName] then
				local part = vehicle:getPartById(partName)
				if part then
					local removed = __vehicleUtils.removePartWithNested(vehicle, part, partsToRemove - removedParts.count)
					if removed then
						for _, partName in ipairs(removed) do
							if not removedParts[partName] then
								removedParts[partName] = true
								removedParts.count = removedParts.count + 1
							end
						end
					end
				end
			end
		end
	end
end

__vehicleUtils.setBatteryCharge = function(vehicle, charge)
	if not __utils.checkArgs(
		vehicle, "BaseVehicle", true,
		charge, "number", true
	) then return end

	if charge < 0 then return end
	if charge > 1 and charge <= 100 then
		charge = charge / 100
	end
	
	local battery = vehicle:getBattery()
	if battery then
		local batteryItem = battery:getInventoryItem()
		if batteryItem then
			batteryItem:setUsedDelta(charge)
		end
	end
end

__vehicleUtils.getOverallCondition = function(vehicle)
	if not __utils.checkArgs(vehicle, "BaseVehicle", true) then return end

	local sumConditions = 0
	local partCount = 0
	local allPartCount = vehicle:getPartCount()
	for i = 0, allPartCount - 1 do
		local part = vehicle:getPartByIndex(i)
		if part and part:getCategory() ~= "nodisplay" and part:getInventoryItem() then
			local partCondition = part:getCondition()
			
			sumConditions = sumConditions + partCondition
			partCount = partCount + 1
		end
	end
	
	return sumConditions / partCount
end

__vehicleUtils.rotate = function(vehicle, angle)
	if not __utils.checkArgs(
		vehicle, "BaseVehicle", true,
		angle, "number", true
	) then return end

	local dir = tostring(vehicle:getDir())
	if dir == "N" or dir == "W" or dir == "NW" or dir == "NE" then
		vehicle:setAngles(vehicle:getAngleX(), vehicle:getAngleY() + angle, vehicle:getAngleZ())
	elseif dir == "S" or dir == "E" or dir == "SW" or dir == "SE" then
		vehicle:setAngles(vehicle:getAngleX(), vehicle:getAngleY() - angle, vehicle:getAngleZ())
	end
end

__vehicleUtils.flip = function(vehicle)
	if not __utils.checkArgs(vehicle, "BaseVehicle", true) then return end

	vehicle:setDebugZ(vehicle:getScript():getExtents():y())
	local ax, ay, az = vehicle:getAngleX(), vehicle:getAngleY(), vehicle:getAngleZ()
	
	if round(ax, 0) == 0 and round(az, 0) == 0 then
		vehicle:setAngles(ax, ay, 180)
	elseif ax <= -170 or ax >= 170 then
		vehicle:setAngles(ax, ay, 0)
	elseif ax <= -80 or ax >= 80 then
		vehicle:setAngles(-180, ay, 0)
	end
end

__vehicleUtils.getSquaresInRadius = function(vehicle, radius)
	if not __utils.checkArgs(
		vehicle, "BaseVehicle", true,
		radius, "integer", true
	) then return end
	
	return __utils.getSquaresInRadius(round(vehicle:getX(), 0), round(vehicle:getY(), 0), round(vehicle:getZ(), 0), radius)
end

__vehicleUtils.isVanilla = function(vehicle)
	local __types = __utils.checkArgs(vehicle, "BaseVehicle | string", true)
	if not __types then return false end
	
	local scriptName = "???"
	if __types[1] == "BaseVehicle" then
		scriptName = vehicle:getScript():getName()
	else
		scriptName = vehicle:gsub("^%w+%.", "")
	end
	
	if __utilTables.vanillaVehiclesNormal[scriptName] or __utilTables.vanillaVehiclesBurnt[scriptName] or __utilTables.vanillaVehiclesSmashed[scriptName] then
		return true
	end
	
	return false
end

__vehicleUtils.getInstalledParts = function(vehicle)
	if not __utils.checkArgs(vehicle, "BaseVehicle", true) then return end

	local parts = {}
	for i = 0, vehicle:getPartCount() - 1 do
		local part = vehicle:getPartByIndex(i)
		if part:getCategory() ~= "nodisplay" and part:getInventoryItem() and part:getTable("uninstall") then
			table.insert(parts, part:getId())
		end
	end
	
	return parts
end

__vehicleUtils.checkTrailerIsAllowed = function(vehicle, trailer)
	local __types = __utils.checkArgs(
		vehicle, "string | BaseVehicle", true,
		trailer, "string | BaseVehicle", true
	)
	if not __types then return false end
	
	local vehicleName, trailerName
	
	if __types[1] == "BaseVehicle" then
		vehicleName = vehicle:getScriptName()
	else
		vehicleName = vehicle
	end
	
	if __types[2] == "BaseVehicle" then
		trailerName = trailer:getScriptName()
	else
		trailerName = trailer
	end
	
	if not vehicleName or not trailerName then return false end
	local trailerScript = ScriptManager.instance:getVehicle(trailerName)
	local vehicleScript = ScriptManager.instance:getVehicle(vehicleName)
	if not trailerScript or not vehicleScript then return false end
	
	if trailerScript:getPartById("DAMNSemiTrailerHook") and not vehicleScript:getPartById("DAMNSemiTrailerSaddle") then
		return false
	end
	
	return trailerScript
end

return __vehicleUtils