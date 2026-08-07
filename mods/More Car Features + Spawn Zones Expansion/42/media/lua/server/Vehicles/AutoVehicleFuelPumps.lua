MoreCarFeatures = MoreCarFeatures or {}
ISVehiclePartMenu = ISVehiclePartMenu or {}

function MoreCarFeatures.scanRangeFuelStationInverse(fuelStation, side)
	local unknownNilCheck = false
	local seen = {}
	local square = fuelStation:getSquare()
	local x, y, z = square:getX(), square:getY(), square:getZ()
	for dy=-4,4 do
		for dx=-4,4 do
			local square2 = getCell():getGridSquare(x + dx, y + dy, z)
			if square2 then
				local vehicle = square2:getVehicleContainer()
				if vehicle and not seen[vehicle] then
					seen[vehicle] = true
					local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
					if vehicleMD[1] and not vehicleMD[2] and vehicleMD[3] == side then
						if vehicleMD[4] and vehicleMD[4][1] and vehicleMD[4][2] then
							local square3 = getCell():getGridSquare(vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ())
							if square3 then
								local sq3Objs = square3:getObjects()
								if sq3Objs then
									for i=0, sq3Objs:size()-1 do
										local obj = sq3Objs:get(i)
										if obj:getPipedFuelAmount() > 0 and obj == fuelStation then
											return vehicle
										end
									end
								end
							else
								unknownNilCheck = nil
							end
						end
					end
				end
			else
				unknownNilCheck = nil
			end
		end
	end
	return unknownNilCheck
end

function MoreCarFeatures.scanRangeFuelStation(vehicle, oldFuelStation)
	local unknownNilCheck = false
	local part = vehicle:getPartById("GasTank")
	local areaCenter = vehicle:getAreaCenter(part:getArea())
	local square = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
	if not square then return false end
	local x, y, z = square:getX(), square:getY(), square:getZ()
	for dy=-2,2 do
		for dx=-2,2 do
			local square2 = getCell():getGridSquare(x + dx, y + dy, z)
			if square2 then
				local sq2Objs = square2:getObjects()
				if sq2Objs then
					for i=0, sq2Objs:size()-1 do
						local obj = sq2Objs:get(i)
						if obj == oldFuelStation then
							return true
						end
					end
				end
			else
				unknownNilCheck = nil
			end
		end
	end
	return unknownNilCheck
end

local ISVehiclePartMenuGetNearbyFuelPump
if not isServer() then
	ISVehiclePartMenuGetNearbyFuelPump = ISVehiclePartMenu.getNearbyFuelPump
end
function ISVehiclePartMenu.getNearbyFuelPump(vehicle, allow)
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		return ISVehiclePartMenuGetNearbyFuelPump(vehicle)
	end
	if not allow then return nil end--Prevent unknown uses of the pump

	local part = vehicle:getPartById("GasTank")
	if not part then return nil end
	local areaCenter = vehicle:getAreaCenter(part:getArea())
	if not areaCenter then return nil end
	local square = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vehicle:getZ())
	if not square then return nil end
	local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
	local onlyReturnLinkedPump = false
	if vehicleMD[1] and not vehicleMD[2] then
		onlyReturnLinkedPump = true
	end

	local couldPumpNotNIL
	for dy=-2,2 do
		for dx=-2,2 do
			local square2 = getCell():getGridSquare(square:getX() + dx, square:getY() + dy, square:getZ())
			if square2 then
				local sq2Objs = square2:getObjects()
				if sq2Objs then
					for i=0, sq2Objs:size()-1 do
						local obj = sq2Objs:get(i)
						if obj:getPipedFuelAmount() > 0 then
							local pumps = obj:getModData().FuelPumpsInUseOrBroken or {}
							if onlyReturnLinkedPump or #pumps < 2 then
								local dir = obj:getFacing()
								local pumpSide
								if dir == IsoDirections.E then
									if areaCenter:getX() < square2:getX()+0.5 then
										pumpSide = "W"
									else
										pumpSide = "E"
									end
								elseif dir == IsoDirections.S then
									if areaCenter:getY() < square2:getY()+0.5 then
										pumpSide = "N"
									else
										pumpSide = "S"
									end
								end

								local freePump = true
								for i = #pumps, 1, -1 do
									if pumps[i][1] == pumpSide then
										freePump = false
										break
									end
								end

								if onlyReturnLinkedPump then
									if pumpSide == vehicleMD[3] and square2:getX() == vehicleMD[4][1] and square2:getY() == vehicleMD[4][2] then
										freePump = true
									else
										freePump = false
									end
								end

								if freePump then
									return obj
								end
							end

							couldPumpNotNIL = false
						end
					end
				end
			end
		end
	end

	return couldPumpNotNIL
end

if isClient() then		--Manually syncing the looped sounds is disgusting and annoying...
	MoreCarFeatures.FuelStationSoundManager = {}
	local function onServerCommand(module, command, args)
		if module == 'MoreCarFeatures' then
			if command == 'FuelPumpTransmitSoundOn' then
				local x, y, z = args.stationSquare[1], args.stationSquare[2], args.stationSquare[3]
				local emitter = getWorld():getFreeEmitter(x, y, z)
--print("FuelPumpTransmitSoundOn 1: ", emitter)
				if emitter then
					local side = args.pumpSide
					local sqNum = tostring(x) .. tostring(y) .. tostring(z)
					MoreCarFeatures.FuelStationSoundManager[sqNum] = MoreCarFeatures.FuelStationSoundManager[sqNum] or {}
--print("FuelPumpTransmitSoundOn 2: ", sqNum, " ", MoreCarFeatures.FuelStationSoundManager[sqNum][side])
					if MoreCarFeatures.FuelStationSoundManager[sqNum][side] then return end
					MoreCarFeatures.FuelStationSoundManager[sqNum][side] = {}
					MoreCarFeatures.FuelStationSoundManager[sqNum][side].emitter = emitter
					MoreCarFeatures.FuelStationSoundManager[sqNum][side].sound = emitter:playSoundLoopedImpl("VehicleAddFuelFromGasPump")
--print("FuelPumpTransmitSoundOn 3: ", MoreCarFeatures.FuelStationSoundManager[sqNum][side].sound)
				end
			elseif command == 'FuelPumpTransmitSoundOff' then
				local x, y, z = args.stationSquare[1], args.stationSquare[2], args.stationSquare[3]
				local sqNum = tostring(x) .. tostring(y) .. tostring(z)
				if MoreCarFeatures.FuelStationSoundManager[sqNum] then
					local side = args.pumpSide
					local cordSide = MoreCarFeatures.FuelStationSoundManager[sqNum][side]
--print("FuelPumpTransmitSoundOff 1: ", sqNum, " ", cordSide)
--if cordSide then
--	print("FuelPumpTransmitSoundOff 2: ", cordSide.emitter, " ", cordSide.sound)
--end
					if cordSide and cordSide.emitter and cordSide.sound then
						cordSide.emitter:stopOrTriggerSound(cordSide.sound)
						MoreCarFeatures.FuelStationSoundManager[sqNum][side] = nil
					end
				end
			end
		end
	end
	Events.OnServerCommand.Add(onServerCommand)

	return		--end file

end


MoreCarFeatures.transferFuelPumpRate = MoreCarFeatures.transferFuelPumpRate or 1		--LITERS PER SECOND, can be changed by server side mod
function MoreCarFeatures.attachedFuelPump(vehID, fuelStation)
	local transferFuelPumpRate = MoreCarFeatures.transferFuelPumpRate
	local vehicle = getVehicleById(vehID)
	local vz = vehicle:getZ()
	local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
	local part = vehicle:getPartById("GasTank")
	local lostFuelStation = false
	local emitter
	local sound

	local tPast = 0
	local tGame = GameTime.getInstance()
	local function onTick()
		vehicle = getVehicleById(vehID)
		if vehicle then
			vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
			if vehicleMD[1] and not vehicleMD[2] then

				if not sound and vehicleMD[5] then
					emitter = getWorld():getFreeEmitter(vehicleMD[4][1], vehicleMD[4][2], vz)
					sound = emitter:playSoundLoopedImpl("VehicleAddFuelFromGasPump")
					if isServer() then
						local args = { stationSquare = { vehicleMD[4][1], vehicleMD[4][2], vz }, pumpSide = vehicleMD[3] }
						sendServerCommand("MoreCarFeatures", "FuelPumpTransmitSoundOn", args)
					end
				elseif sound and not vehicleMD[5] then
					if isServer() then
						local args = { stationSquare = { vehicleMD[4][1], vehicleMD[4][2], vz }, pumpSide = vehicleMD[3] }
						sendServerCommand("MoreCarFeatures", "FuelPumpTransmitSoundOff", args)
					end
					emitter:stopOrTriggerSound(sound)
					emitter = nil
					sound = nil
				end

				local newtPast = tPast + tGame:getTimeDelta()
				if round(tPast, 0) == round(newtPast, 0) then
					tPast = newtPast
					return
				else
					tPast = newtPast
				end

				if lostFuelStation then
					local areaCenter = vehicle:getAreaCenter(part:getArea())
					local square = getCell():getGridSquare(areaCenter:getX(), areaCenter:getY(), vz)
					local x, y, z = square:getX(), square:getY(), square:getZ()
					for dy=-2,2 do
						for dx=-2,2 do
							local square2 = getCell():getGridSquare(x + dx, y + dy, z)
							if square2 then
								local sq2Objs = square2:getObjects()
								if sq2Objs then
									for i=0, sq2Objs:size()-1 do
										local obj = sq2Objs:get(i)
										if obj:getPipedFuelAmount() > 0 then
											local pumps = obj:getModData().FuelPumpsInUseOrBroken or {}
											if #pumps ~= 0 then
												for i = #pumps, 1, -1 do
													local pump = pumps[i]
													if pump[1] == vehicleMD[3] and not pump[2] then
														fuelStation = obj
														lostFuelStation = false
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end

				local fuelStationChecker = MoreCarFeatures.scanRangeFuelStation(vehicle, fuelStation)
				if fuelStationChecker then

					if vehicleMD[5] then	--Add Fuel
						local square = fuelStation:getSquare()
						if ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (square:hasGridPower())) then
							local tankCurrent = part:getContainerContentAmount()
							local tankToFill = part:getContainerCapacity() - tankCurrent
							local pumpCurrent = fuelStation:getPipedFuelAmount()
							local toTransfer = math.min(tankToFill, pumpCurrent)
							if toTransfer <= transferFuelPumpRate then	--end of transfer, auto disable pump
								vehicle:getModData().statusFuelPumpNozzle[5] = false
								vehicle:transmitModData()
								if isServer() then
									local args = { stationSquare = { vehicleMD[4][1], vehicleMD[4][2], vz }, pumpSide = vehicleMD[3] }
									sendServerCommand("MoreCarFeatures", "FuelPumpTransmitSoundOff", args)
								end
								if sound then
									emitter:stopOrTriggerSound(sound)
									emitter = nil
									sound = nil
								end
							end
							toTransfer = math.min(toTransfer, transferFuelPumpRate)
						--	"Vehicles.JerryCanLitres" goes unused anywhere else despite claiming to exist with purpose, it only serves to make pumps last longer
							fuelStation:setPipedFuelAmount(pumpCurrent - toTransfer)
							part:setContainerContentAmount(tankCurrent + toTransfer)
							vehicle:transmitPartModData(part)
						else
							vehicle:getModData().statusFuelPumpNozzle[5] = false
							vehicle:transmitModData()
							if isServer() then
								local args = { stationSquare = { vehicleMD[4][1], vehicleMD[4][2], vz }, pumpSide = vehicleMD[3] }
								sendServerCommand("MoreCarFeatures", "FuelPumpTransmitSoundOff", args)
							end
							if sound then
								emitter:stopOrTriggerSound(sound)
								emitter = nil
								sound = nil
							end
						end
					end

					return
				elseif vehicle:isStopped() then	--nil means a square could not be found previously, aka an unknown chunk that could hold the gas pump

					if fuelStationChecker == nil then
						lostFuelStation = true
						return
					end

				end

				if vehicleMD[5] then
					--fire? leak? something...
				end

				local pumps = fuelStation:getModData().FuelPumpsInUseOrBroken or {}
				for i = #pumps, 1, -1 do
					if pumps[i][1] == vehicleMD[3] then
						fuelStation:getModData().FuelPumpsInUseOrBroken[i][2] = true
						fuelStation:transmitModData()
						break
					end
				end

				vehicle:getModData().statusFuelPumpNozzle = { true, true, vehicleMD[3], vehicleMD[4], false }
				vehicle:transmitModData()
			end

		end

		if isServer() then
			local args = { stationSquare = { vehicleMD[4][1], vehicleMD[4][2], vz }, pumpSide = vehicleMD[3] }
			sendServerCommand("MoreCarFeatures", "FuelPumpTransmitSoundOff", args)
		end
		if sound then
			emitter:stopOrTriggerSound(sound)
			emitter = nil
			sound = nil
		end

		Events.OnTick.Remove(onTick)
	end
	Events.OnTick.Add(onTick)
end


--Compatibility Patching
if not isServer() and getActivatedMods():contains("FuelTankerMod") then	--3741877969
	local function T(key, ...) return FuelTanker.getText(key, ...) end
	local function getFuelPumpInfoForVehicle(vehicle)
		if not vehicle then
			return nil, T("PumpUnavailable")
		end
		if not ISVehiclePartMenu then
			return nil, T("VehiclePartMenuNotLoaded")
		end
		if not ISVehiclePartMenuGetNearbyFuelPump then	--ISVehiclePartMenu.getNearbyFuelPump
			return nil, T("PumpLookupUnavailable")
		end
		local okPump, fuelStation = pcall(function()
			return ISVehiclePartMenuGetNearbyFuelPump(vehicle)	--ISVehiclePartMenu.getNearbyFuelPump(vehicle)
		end)
		if not okPump then
			FuelTanker.log("Pump lookup threw error: " .. tostring(fuelStation))
			return nil, T("PumpLookupFailed")
		end
		if not fuelStation then
			return nil, T("NoPumpNearTanker")
		end
		local square = nil
		pcall(function() square = fuelStation:getSquare() end)
		if not square then
			return nil, T("PumpSquareUnavailable")
		end
		local hasGridPower = false
		local hasGeneratorPower = false
		pcall(function() hasGridPower = square:hasGridPower() end)
		pcall(function()
			hasGeneratorPower = SandboxVars.AllowExteriorGenerator and square:haveElectricity()
		end)
		if not hasGridPower and not hasGeneratorPower then
			return nil, T("PumpNotPowered")
		end
		return fuelStation, nil
	end
	FuelTanker.Client.getFuelPumpInfoForVehicle = getFuelPumpInfoForVehicle
end