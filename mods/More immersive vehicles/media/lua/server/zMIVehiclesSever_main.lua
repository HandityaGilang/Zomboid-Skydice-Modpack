-- ===============================================--
-- If you're here, it means you need something. Text me, we'll talk.
-- Discord: danig
-- ===============================================--

local vehiclesCache = {
	vehicleCheck = {},
	zoneCheck = {},
}

local getChanceByPart = function(type, partName)
	return SandboxVars.MoreImmersiveVehicles[type .. 'Opened' .. partName .. 'Chance']
end

local function checkVehicle(vehicle)
	local vehId = vehicle:getSqlId()
	if vehiclesCache.vehicleCheck[vehId] then
		return vehiclesCache.vehicleCheck[vehId]
	end
	local res = vehicle and not vehicle:isGoodCar() and not vehicle:isAlarmed()
	vehiclesCache.vehicleCheck[vehId] = res
    return res
end

local function doorCanBeOpened(part)
    return part:getInventoryItem() and checkVehicle(part:getVehicle()) and part:getDoor() and not part:getDoor():isOpen() and not part:getDoor():isLocked() and not part:getDoor():isLockBroken()
end

local function windowCanBeOpened(part)
    return part:getInventoryItem() and checkVehicle(part:getVehicle()) and part:getWindow() and part:getWindow():isOpenable() and not part:getWindow():isOpen() and part:getParent() and part:getParent():getDoor() and not part:getParent():getDoor():isLocked()
end

local function open(vehicle, partName)
	local vehId = vehicle:getSqlId()
	if vehiclesCache.zoneCheck[vehId] then
		return ZombRand(0, 100) < getChanceByPart('Park', partName)
	elseif vehiclesCache.zoneCheck[vehId] == false then
		return ZombRand(0, 100) < getChanceByPart('Road', partName)
	elseif vehiclesCache.zoneCheck[vehId] == nil then
		local zone = getVehicleZoneAt(math.floor(vehicle:getX()), math.floor(vehicle:getY()), 0)
		if not zone or zone:getName():match("trafficjam", "i") then
			vehiclesCache.zoneCheck[vehId] = false
		else
			vehiclesCache.zoneCheck[vehId] = true
			return ZombRand(0, 100) < getChanceByPart('Park', partName)
		end
	end
    return ZombRand(0, 100) < getChanceByPart('Road', partName)
end

local old_Vehicles_Create_Door = Vehicles.Create.Door
function Vehicles.Create.Door(vehicle, part)
    old_Vehicles_Create_Door(vehicle, part)
    if doorCanBeOpened(part) and open(vehicle, 'Door') then
        part:getDoor():setOpen(true)
        vehicle:transmitPartDoor(part)
    end
end

local old_Vehicles_Create_TrunkDoor = Vehicles.Create.TrunkDoor
function Vehicles.Create.TrunkDoor(vehicle, part)
    old_Vehicles_Create_TrunkDoor(vehicle, part)
    if doorCanBeOpened(part) and open(vehicle, 'TrunkDoor') then
        part:getDoor():setOpen(true)
        vehicle:transmitPartDoor(part)
    end
end

local old_Vehicles_Create_Window = Vehicles.Create.Window
function Vehicles.Create.Window(vehicle, part)
    old_Vehicles_Create_Window(vehicle, part)
    if windowCanBeOpened(part) and open(vehicle, 'Window') then
        part:getWindow():setOpen(true)
        part:getWindow():setOpenDelta(1)
        vehicle:transmitPartWindow(part)
    end
end

--[[ I consider this functionality to be unnecessary

local old_Vehicles_Create_Default = Vehicles.Create.Default 
function Vehicles.Create.Default(vehicle, part)
	old_Vehicles_Create_Default(vehicle, part)
	if part:getId():contains('EngineDoor') and doorCanBeOpened(part) and open(vehicle, SandboxVars.MoreImmersiveVehicles.OpenedEngineDoorChance) then
		local doorFrontLeft = vehicle:getPartById("DoorFrontLeft")
		if doorFrontLeft and doorFrontLeft:getDoor() and not doorFrontLeft:getDoor():isLocked() then
			print(vehicle:getScriptName() .. tostring(doorFrontLeft:getDoor():isLocked()))
			part:getDoor():setOpen(true)
			vehicle:transmitPartDoor(part)
		end
	end

	option MoreImmersiveVehicles.OpenedEngineDoorChance
	{
		type = integer, min = 0, max = 100, default = 25,
		page = MoreImmersiveVehicles, translation = OpenedEngineDoorChance,
	}

end]]
