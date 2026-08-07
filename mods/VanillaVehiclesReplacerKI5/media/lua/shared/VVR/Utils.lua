VVR = VVR or {}
VVR.Utils = {}
VVR.Delay = {}
VVR.Delay.Tab = {}

VVR.Utils.VanillaZones = { "parkingstall", "trailerpark", "bad", "medium", "good", "sport", "junkyard", "trafficjams", "police", "fire", "ranger", "mccoy", "postal", "spiffo", "ambulance", "radio", "fossoil", "scarlet", "massgenfac", "transit", "network3", "kyheralds", "lectromax", "knoxdisti"}

function VVR.Utils.NilSpawnZones(vehicleName)
	if not VehicleZoneDistribution then return end
	for _, zoneName in ipairs(VVR.Utils.VanillaZones) do
		VehicleZoneDistribution[zoneName].vehicles[vehicleName] = nil
	end
end

function VVR.Utils.GetOverallCondition(vehicle)
	local sumConditions = 0
	local totalPart = 0
	for i=0, vehicle:getPartCount()-1 do
		local partCondition = vehicle:getPartByIndex(i):getCondition()
		sumConditions = sumConditions+partCondition
	end
	return sumConditions/vehicle:getPartCount()
end

function VVR.Utils.GetPartsStats(vehicle)
	local partsStats = {}
	for i=0, vehicle:getPartCount()-1 do
		local part = vehicle:getPartByIndex(i)
		if part and part:getItemType() then
			local partId = part:getId()
			if not partsStats[partId] then partsStats[partId] = {} end
			if part:getInventoryItem() then
				partsStats[partId].condition = part:getCondition()
				if part:isContainer() and not part:getItemContainer() then
					partsStats[partId].contentAmount = part:getContainerContentAmount()/part:getContainerCapacity()
				end
			else
				partsStats[partId].isMissing = true
			end
		end
	end
	return partsStats
end

function VVR.Utils.GetVehicleParams(vehicle)
	local vehicleParams = {}
	vehicleParams.partsStats = VVR.Utils.GetPartsStats(vehicle)
	vehicleParams.overallCondition = VVR.Utils.GetOverallCondition(vehicle)
	vehicleParams.isSmashed = VVR.Utils.IsSmashed(vehicle)
	vehicleParams.batteryCharge = vehicle:getBatteryCharge()
	vehicleParams.isBurnt = VVR.Utils.IsBurnt(vehicle)
	vehicleParams.isGood = vehicle:isGoodCar()
	vehicleParams.bloodIntFront = vehicle:getBloodIntensity("Front")
	vehicleParams.bloodIntRight = vehicle:getBloodIntensity("Right")
	vehicleParams.bloodIntLeft = vehicle:getBloodIntensity("Left")
	vehicleParams.bloodIntRear = vehicle:getBloodIntensity("Rear")
	vehicleParams.rust = vehicle:getRust()
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

function VVR.Utils.IsSmashed(vehicle)
	if vehicle:getScriptName():lower():find("smashed") then
		return true
	end
	return false
end

function VVR.Utils.IsBurnt(vehicle)
	if vehicle:getScriptName():lower():find("burnt") then
		return true
	end
	return false
end

function VVR.Utils.ScriptReloaded(vehicle, scriptName)
	vehicle:breakConstraint(false, false)
	for i = 0, vehicle:getPartCount() - 1 do
		local part = vehicle:getPartByIndex(i)
		part:setInventoryItem(nil)
		vehicle:transmitPartItem(part)
	end
	vehicle:setScript(scriptName)
	vehicle:createPhysics()
	for i=0, vehicle:getPartCount()-1 do
		local part = vehicle:getPartByIndex(i)
		local create = part:getLuaFunction("create")
		local init = part:getLuaFunction("init")
		if create and create:find("^Vehicles.") then
			VehicleUtils.callLua(create, vehicle, part)
		end
		if init and init:find("^Vehicles.") then
			VehicleUtils.callLua(init, vehicle, part)
		end
	end
end

function VVR.Utils.GetRearTire(vehicle)
	local part = vehicle:getPartById("TireRearLeft"):getInventoryItem() or vehicle:getPartById("TireRearRight"):getInventoryItem()
	if part then
		return instanceItem(part:getModule().."."..part:getType())
	end
	return nil
end

function VVR.Utils.GetRandomRearTire(vehicle)
	local part = vehicle:getPartById("TireRearLeft")
	for i=0, part:getItemType():size() - 1 do
		if ZombRand(100) > (100 - (100 / part:getItemType():size())) or i == part:getItemType():size() - 1 then
			itemType = part:getItemType():get(i)
			return instanceItem(itemType)
		end
	end
	return nil
end

function VVR.Utils.GetSquaresInRadius(vehicle, radius)
	local squares = {}
	local vehicleX = vehicle:getX()
	local vehicleY = vehicle:getY()
	for x = vehicleX - radius, vehicleX + radius do
		for y = vehicleY - radius, vehicleY + radius do
			if math.sqrt((x - vehicleX) ^ 2 + (y - vehicleY) ^ 2) <= radius then
				local square = getCell():getGridSquare(x, y, vehicle:getZ())
				if square then
					table.insert(squares, square)
				end
			end
		end
	end
	return squares
end

function VVR.Delay.Process()
	for i = #VVR.Delay.Tab, 1, -1 do
		local delayedFunc = VVR.Delay.Tab[i]
		local ticks = delayedFunc.ticks
		if ticks then
			delayedFunc.ticks = ticks - 1
			if delayedFunc.ticks <= 0 then
				delayedFunc.func(unpack(delayedFunc.args))
				table.remove(VVR.Delay.Tab, i)
			end
		end
	end
	
	if #VVR.Delay.Tab == 0 then
		Events.OnTick.Remove(VVR.Delay.Process)
	end
end

function VVR.Delay.Add(func, ticks, args)
	table.insert(VVR.Delay.Tab, { func = func, ticks = ticks, args = args })
	Events.OnTick.Add(VVR.Delay.Process)
end