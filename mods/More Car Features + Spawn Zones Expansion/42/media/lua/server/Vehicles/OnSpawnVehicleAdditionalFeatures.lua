if isClient() then return end

MoreCarFeatures = MoreCarFeatures or {}

local hasOpenVehiclePartsMod = getActivatedMods():contains("DG_MIVehicles")	--3162566044

local excludedParts = {
	Engine = true,
	Heater = true,
	GloveBox = true,
	TruckBed = true,
	PassengerCompartment = true,
	SeatFrontLeft = true
}

local rearWindowCandidates = {
	"RearWindshield",
	"RearWindshield1",
	"RearWindshield2",
	"RearWindshield3",
	"WindshieldRear",
	"WindowTrunk",
	"WindowTrunkRear",
	"WindowRear",
	"WindowRearLeft",
	"WindowRearRight",
	"WindowBack",
	"RearWindow"
}

local function removeBrokenParts(vehicle, part)
	if not instanceof(part, "VehiclePart") then return end
	local item = part:getInventoryItem()
	part:setInventoryItem(nil)
	if item then
		item:setItemCapacity(part:getContainerContentAmount())
	end
	vehicle:transmitPartItem(part)
end

local function scheduleVehicleRemoval(vehicle)
	if not vehicle then return end
	local delay = 2
	local function delayProcessRemoval()
		delay = delay - 1
		if delay > 0 then return end
		if vehicle then
			vehicle:permanentlyRemove()
		end
		Events.OnTick.Remove(delayProcessRemoval)
	end
	Events.OnTick.Add(delayProcessRemoval)
end

local function specialExceptions(vehicleName)
	if string.contains(vehicleName, "trailer") or string.contains(vehicleName, "tow") or string.contains(vehicleName, "wrecker") then
		return true
	end
	return false
end

local vZoneToFlip
local function getVZoneToFlip()
	vZoneToFlip = getVehicleZoneAt(7716, 11883, 0)
end
Events.OnLoadedMapZones.Add(getVZoneToFlip)

function MoreCarFeatures.GamestaOnSpawnVehicleEndActions(vehicle)
	if not vehicle then return end

	local SandboxFuelPumps = SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps

	local chunk = vehicle:getChunk()
	if not chunk or not chunk:isNewChunk() then

		if SandboxFuelPumps then
			local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
			if vehicleMD[1] and not vehicleMD[2] then
				local fuelStation = ISVehiclePartMenu.getNearbyFuelPump(vehicle, true)
				local Id = vehicle:getId()
				if fuelStation then
					if isServer() then
						local args = { stationSquare = { vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ() }, pumpSide = vehicleMD[3] }
						sendServerCommand("MoreCarFeatures", "FuelPumpTransmitSoundOff", args)
					end
					MoreCarFeatures.attachedFuelPump(Id, fuelStation)
				else	--Happens when the vehicle loads before the pump because they're in different chunks
					local unknownSquare = true
					local function monitorVehiclePerChunk(chunk)
						vehicle = getVehicleById(Id)
						if vehicle then
							local sq = getCell():getGridSquare(vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ())
							if sq then
								fuelStation = ISVehiclePartMenu.getNearbyFuelPump(vehicle, true)
								unknownSquare = false
							else
								unknownSquare = true
							end
						end
					end
					Events.LoadChunk.Add(monitorVehiclePerChunk)
					local function monitorVehiclePerTick()
						if fuelStation then
							if isServer() then	--No duplicate sounds backup, just in case ya know
								local args = { stationSquare = { vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ() }, pumpSide = vehicleMD[3] }
								sendServerCommand("MoreCarFeatures", "FuelPumpTransmitSoundOff", args)
							end
							MoreCarFeatures.attachedFuelPump(Id, fuelStation)
						elseif vehicle then
							if (not vehicle:getController() or vehicle:isStopped()) and unknownSquare then return end
							vehicle:getModData().statusFuelPumpNozzle = { true, true, vehicleMD[3], vehicleMD[4], false }
							vehicle:transmitModData()
							if fuelStation then
								local pumps = fuelStation:getModData().FuelPumpsInUseOrBroken or {}
								for i = #pumps, 1, -1 do
									if pumps[i][1] == vehicleMD[3] then
										fuelStation:getModData().FuelPumpsInUseOrBroken[i][2] = true
										fuelStation:transmitModData()
										break
									end
								end
							end
						end
						Events.LoadChunk.Remove(monitorVehiclePerChunk)
						Events.OnTick.Remove(monitorVehiclePerTick)
					end
					Events.OnTick.Add(monitorVehiclePerTick)
				end
			end
		end

		return
	end

	if vehicle:isGoodCar() and SandboxVars.GamestaVehicleZones.noGoodCars then
		scheduleVehicleRemoval(vehicle)
		return
	end

	local pos = vehicle:getSquare()
	local zone = getVehicleZoneAt(pos:getX(), pos:getY(), 0)

	local atGasStation = false

	if zone then
		local zoneName = string.lower(zone:getName())

		if zoneName == "junkyard" or zoneName:contains("trafficjam") or zoneName == "modified_trfjm" then

		-- Remove Good Vehicles From These Zones
			if vehicle:isGoodCar() and not specialExceptions(string.lower(vehicle:getScriptName())) then
				scheduleVehicleRemoval(vehicle)
				return

			elseif zoneName == "junkyard" then
			-- Junkyard Handler

				if not specialExceptions(string.lower(vehicle:getScriptName())) then
					if not (vehicle:isGoodCar() or vehicle:isBurnt()) then
						local battery = vehicle:getBattery()
						if not battery then return end
						local batteryInvItem = battery:getInventoryItem()
						if not batteryInvItem then return end
						batteryInvItem:setCurrentUsesFloat(0.0)
					end

					for i = vehicle:getPartCount() - 1, 0, -1 do
						local part = vehicle:getPartByIndex(i)
						if part then
							local partName = part:getId()
							if (part:getCondition() == 0 or part:getCondition() > 45) and not excludedParts[partName] then
								if string.sub(partName, 1, 4) == "Door" then
									local doorSide = string.sub(partName, 5)
									local windowPart = vehicle:getPartById("Window" .. doorSide)
									removeBrokenParts(vehicle, part)
									if windowPart then removeBrokenParts(vehicle, windowPart) end
								elseif partName == "TrunkDoor" or partName == "DoorRear" or string.find(partName, "Trunk") or string.find(partName, "Boot") then
									removeBrokenParts(vehicle, part)
									for _, rearId in ipairs(rearWindowCandidates) do
										local rearPart = vehicle:getPartById(rearId)
										if rearPart then removeBrokenParts(vehicle, rearPart) end
									end
								elseif string.sub(partName, 1, 10) == "Suspension" or string.sub(partName, 1, 5) == "Brake" then
									removeBrokenParts(vehicle, part)
									local side = nil
									if string.sub(partName, 1, 10) == "Suspension" then
										side = string.sub(partName, 11)
									else
										side = string.sub(partName, 6)
									end
									if side and side ~= "" then
										local tirePart = vehicle:getPartById("Tire" .. side)
										if tirePart then
											removeBrokenParts(vehicle, tirePart)
										end
									end
								else
									removeBrokenParts(vehicle, part)
								end
							end
						end
					end
				elseif not SandboxVars.GamestaVehicleZones.noGoodCars then		--exceptions made for some vehicles in junkyards
					vehicle:setGoodCar(true)
				end
			
			else
			--ALL TRAFFIC JAMS

				local rand = newrandom()

				local spawnRateMTJ = SandboxVars.GamestaVehicleZones.spawnRateModifiedTrafficJams
				if spawnRateMTJ ~= -1 and rand:random(1, 100) > spawnRateMTJ then
					scheduleVehicleRemoval(vehicle)
					return
				end

			-- Car Angles
				if rand:random(0, 10) ~= 0 then
					if zoneName == "modified_trfjm" then
						local randDirYNS = rand:random(-10, 10)
						local randDirYEW = randDirYNS + 90
						--Downtown
						if zone == getVehicleZoneAt(12599, 1274, 0) then vehicle:setAngles(180, randDirYNS, 180)
						elseif zone == getVehicleZoneAt(12593, 1274, 0) then vehicle:setAngles(0, randDirYNS, 0)
						elseif zone == getVehicleZoneAt(12506, 1241, 0) then vehicle:setAngles(180, randDirYNS, 180)
						elseif zone == getVehicleZoneAt(12501, 1241, 0) then vehicle:setAngles(0, randDirYNS, 0)
						--Southern Highway
						elseif zone == getVehicleZoneAt(12635, 3442, 0) then vehicle:setAngles(180, -randDirYEW, 180)
						elseif zone == getVehicleZoneAt(12635, 3452, 0) then vehicle:setAngles(0, randDirYEW, 0)
						elseif zone == getVehicleZoneAt(15303, 3322, 0) then vehicle:setAngles(180, -randDirYEW, 180)
						elseif zone == getVehicleZoneAt(15311, 3332, 0) then vehicle:setAngles(0, randDirYEW, 0)
						end
					else
						if zoneName == "trafficjamn" then
							vehicle:setAngles(180, (rand:random(-40, 40)), 180)
						elseif zoneName == "trafficjams" then
							vehicle:setAngles(0, (rand:random(-40, 40)), 0)
						elseif zoneName == "trafficjame" then
							vehicle:setAngles(0, (rand:random(50, 130)), 0)
						elseif zoneName == "trafficjamw" then
							vehicle:setAngles(0, -(rand:random(50, 130)), 0)
						end
					end
				end

			-- Doors/Windows Open Random
				if not hasOpenVehiclePartsMod and not vehicle:isBurntOrSmashed() then
					for i=0, vehicle:getPartCount() do
						local part = vehicle:getPartByIndex(i)
						if part and part:getInventoryItem() then		--Damaging, Removing, and Placing Parts
						--	local partItem = part:getInventoryItem()
						--	local partId = part:getId()
						--	local partArea = vehicle:getAreaCenter(part:getArea())
							local door = part:getDoor()
							local window = part:getWindow()
							if door then
								if not door:isLockBroken() and not door:isLocked() then
									local doOpen = false
									if part:getId() == "EngineDoor" then
										if rand:random(1, 10) == 1 and (vehicle:getBatteryCharge() < 0.1 or not vehicle:isEngineWorking()) then
											doOpen = true
										end
								--	elseif trunk?
									elseif rand:random(1, 10) <= 3 then
										doOpen = true
									end
									if doOpen then
										door:setOpen(true)
										vehicle:transmitPartItem(part)
									end
								end
							elseif window then
								if not window:isDestroyed() and window:isOpenable() and rand:random(1, 10) <= 2 then
									window:setOpen(true)
									vehicle:transmitPartItem(part)
								end
							end
						end
					end
				end

			end

	--Gas Stations
		elseif zoneName:contains("gasstation") then
			if SandboxFuelPumps then
				atGasStation = true
				local part = vehicle:getPartById("GasTank")
				if part then
					local fuelStation = ISVehiclePartMenu.getNearbyFuelPump(vehicle, true)
					if fuelStation then
						local areaCenter = vehicle:getAreaCenter(part:getArea())
						local square = fuelStation:getSquare()
						local dir = fuelStation:getFacing()
						local pumpSide
						if dir == IsoDirections.E then
							if areaCenter:getX() < square:getX()+0.5 then
								pumpSide = "W"
							else
								pumpSide = "E"
							end
						elseif dir == IsoDirections.S then
							if areaCenter:getY() < square:getY()+0.5 then
								pumpSide = "N"
							else
								pumpSide = "S"
							end
						end
						fuelStation:getModData().FuelPumpsInUseOrBroken = fuelStation:getModData().FuelPumpsInUseOrBroken or {}
						table.insert(fuelStation:getModData().FuelPumpsInUseOrBroken, {pumpSide, false})
						fuelStation:transmitModData()
						vehicle:getModData().statusFuelPumpNozzle = { true, false, pumpSide, {math.floor(square:getX()), math.floor(square:getY())}, false }
						MoreCarFeatures.attachedFuelPump(vehicle:getId(), fuelStation)
					else
						vehicle:getModData().statusFuelPumpNozzle = { false, false, nil, {}, false }
					end
				end
			end

	-- Car Flipper (add new zone for B42.20 Stable, new prison looks cool)
		elseif zone == vZoneToFlip then		--(PRISON BUS, ROSEWOOD)
			vehicle:setDebugZ(.4)		--So it doesn't clip into the ground, raise it! 
			vehicle:setAngles(180, 120, -90)		--Flipped on right side facing SE into the guard room near the front entrance
		end

		-- Remove/Replace Oversized Vehicles Indoors (current work around is using custom zones, should use set script instead anyways)
	--	if zoneName == "firegarage" then
	--		if vehicle:getScriptName() == ("Base.90pierceArrow" or "Base.pzkFireTruckFlatLadder") then
	--			local vDir = vehicle:getForwardIsoDirection()
	--			scheduleVehicleRemoval(vehicle)
	--			if not (getActivatedMods():contains("NoVanillaVehicles") or getActivatedMods():contains("VVR")) then
	--				local fireVehicles = {"Base.PickUpVanLightsFire", "Base.PickUpTruckLightsFire"}
	--				local fire = fireVehicles[ZombRand(1, #fireVehicles + 1)]
	--				if pos:getX() and pos:getY() then
	--					vehicle = addVehicle(fire, pos:getX(), pos:getY(), 0)
	--					if vehicle then
	--						if vDir == IsoDirections.N then vehicle:setAngles(0, 180, 0)
	--						elseif vDir == IsoDirections.S then vehicle:setAngles(0, 0, 0)
	--						elseif vDir == IsoDirections.E then vehicle:setAngles(0, 90, 0)
	--						elseif vDir == IsoDirections.W then vehicle:setAngles(0, -90, 0)
	--						end
	--					end
	--				end
	--			end
	--		end
	--	end

--	else is vehicle events?

	end

	if SandboxFuelPumps then
		if not atGasStation then
			vehicle:getModData().statusFuelPumpNozzle = { false, false, nil, {}, false }
		end
		vehicle:transmitModData()
	end

end
Events.OnSpawnVehicleEnd.Add(MoreCarFeatures.GamestaOnSpawnVehicleEndActions)
