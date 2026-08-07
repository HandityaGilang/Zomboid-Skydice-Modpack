-- ===============================================--
-- If you're here, it means you need something. Text me, we'll talk.
-- Discord: danig
-- Spawn-open logic reworked together with Claude (Anthropic).
-- ===============================================--

if isClient() then return end

local function getChanceByPart(zoneType, partName)
	return SandboxVars.MoreImmersiveVehicles[zoneType .. 'Opened' .. partName .. 'Chance']
end

-- Pick the sandbox chance key for a door-type part by its id: the hood
-- (EngineDoor) and trunk (TrunkDoor / TrunkDoorOpened) get their own chances;
-- every other door (the passenger doors) uses the generic Door chance.
local function getDoorPartKey(part)
	local id = part:getId()
	if id:contains('EngineDoor') then
		return 'EngineDoor'
	elseif id:contains('Trunk') then
		return 'TrunkDoor'
	end
	return 'Door'
end

-- A vehicle is eligible if it's not a pristine "good car" and not alarmed.
local function checkVehicle(vehicle)
	return vehicle and not vehicle:isGoodCar() and not vehicle:isAlarmed()
end

-- Park = appeared in a parking-stall zone. Road = no zone or a traffic jam.
local function getZoneType(vehicle)
	local zone = getVehicleZoneAt(math.floor(vehicle:getX()), math.floor(vehicle:getY()), 0)
	if not zone or zone:getName():match("trafficjam", "i") then
		return 'Road'
	end
	return 'Park'
end

local function rollOpen(zoneType, partName)
	return ZombRand(0, 100) < getChanceByPart(zoneType, partName)
end

local function doorCanBeOpened(part)
	local door = part:getDoor()
	return part:getInventoryItem()
		and not door:isOpen()
		and not door:isLocked()
		and not door:isLockBroken()
end

local function windowCanBeOpened(part)
	local window = part:getWindow()
	local parent = part:getParent()
	return part:getInventoryItem()
		and window:isOpenable()
		and not window:isOpen()
		and parent and parent:getDoor()
		and not parent:getDoor():isLocked()
end

-- Fired once the vehicle is fully built (after createParts/initParts), so every
-- door/window already has its final lock/open state. See OnSpawnVehicleEnd in
-- BaseVehicle.createPhysics
local function onSpawnVehicleEnd(vehicle)
	if not vehicle then return end

	-- This event also fires on reload from save, not only on first spawn.
	-- Persist a flag so we open parts exactly once per vehicle.
	local md = vehicle:getModData()
	if md.MIV_processed then return end
	md.MIV_processed = true

	if not checkVehicle(vehicle) then return end

	local zoneType = getZoneType(vehicle)

	for i = 0, vehicle:getPartCount() - 1 do
		local part = vehicle:getPartByIndex(i)
		if part:getWindow() then
			if windowCanBeOpened(part) and rollOpen(zoneType, 'Window') then
				part:getWindow():setOpen(true)
				part:getWindow():setOpenDelta(1)
				vehicle:transmitPartWindow(part)
			end
		elseif part:getDoor() then
			if doorCanBeOpened(part) and rollOpen(zoneType, getDoorPartKey(part)) then
				part:getDoor():setOpen(true)
				vehicle:transmitPartDoor(part)
			end
		end
	end
end

Events.OnSpawnVehicleEnd.Add(onSpawnVehicleEnd)
