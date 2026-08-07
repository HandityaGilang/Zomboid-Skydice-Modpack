CarBombFeature = CarBombFeature or {}

local function InteractionsBombVehicle()
if not SandboxVars.GamestaVehicleZones.interactBombVehicle then return end


function CarBombFeature.ScanVehiclesInRadius(x, y, z, radius, setBombAction)
	if not (x and y and z) then return end
	local cell = getCell()
	local seen = {}
	local r2 = radius^2
	for dx = -radius, radius do
		for dy = -radius, radius do
			local hitPoint = (dx * dx + dy * dy)
			if hitPoint <= r2 then
				local sq0 = cell:getGridSquare(x + dx, y + dy, z)
				if sq0 then
					local vehicle = sq0:getVehicleContainer()
					if vehicle and not seen[vehicle] then
						seen[vehicle] = true

						if setBombAction then
						--	local rand = newrandom()
						--	local radiusDamage = setBombAction[1]	--too inconsistent and needs more work	--Made method, work on implementing.
						--	local radiusFling = setBombAction[2]	--buggy with too much force and doesn't work outside of debug mode
						--	local radiusJump = setBombAction[3]		--doesn't work outside of debug mode	--Alternative found, adding when I have time.
							local radiusAlarm = setBombAction[4]
							if radiusAlarm and hitPoint <= radiusAlarm^2 then
								if vehicle:isAlarmed() then
									vehicle:triggerAlarm()
								end
							end
						end

					end
				end
			end
		end
	end
end

local function explodeVehicles(throwable, square)
	local bombType = throwable:getExplosionSound()
	local radius, damageType
	if bombType == "PipeBombExplode" then
		radius = 20
		damageType = {2, 5, 10, 20}
	--	if not isClient() then
	--		local vehicle = square:getVehicleContainer()
	--		if vehicle then
	--			CarBombFeature.ExplosionCalc(vehicle, throwable, square)
	--		end
	--	end
	elseif bombType == "AerosolBombExplode" then
		radius = 12
		damageType = {2, 3, 6, 12}
	elseif bombType == "MolotovCocktailExplode" then
		radius = 3
		damageType = {3, nil, nil, 2}
	elseif bombType == "FlameTrapExplode" then
		radius = 5
		damageType = {5, nil, nil, 2}
	else
		return
	end
	CarBombFeature.ScanVehiclesInRadius(square:getX(), square:getY(), square:getZ(), radius, damageType)
end
Events.OnThrowableExplode.Add(explodeVehicles)

--VehicleWindowHandleOpen
--VehicleWindowElectricOpen
--OnPlayerGetDamage

--Car bombs are activated in a variety of ways, including 
--	opening the vehicle's doors, starting the engine, remote detonation, 
--		depressing the accelerator or brake pedals, (not this one, redundant)
--			or simply lighting a fuse or setting a timing device.

function CarBombFeature.JumpVehicle(vehicle, z, dif)
	if dif < 1 then
		dif = 1
	elseif dif > 3 then
		dif = 3
	end
	local x = 0
	local tPast = 0
	local tGame = GameTime.getInstance()
	local function onTick()
		local newtPast = tPast + tGame:getTimeDelta()
		if round(tPast, 1.7) == round(newtPast, 1.7) then
			tPast = newtPast
			return
		else
			tPast = newtPast
		end
		dif = dif - 0.1
		local tempDif = dif^2
		if dif < 0 then
			tempDif = -tempDif
		end
		x = x + tempDif
		if z + x/100 > z then
			local getVehicle = getVehicleById(vehicle)
			if getVehicle then
				for seat=0, getVehicle:getMaxPassengers()-1 do
					local multiPlayer = getVehicle:getCharacter(seat)
					if multiPlayer then
						getVehicle:exit(multiPlayer)
						multiPlayer:faceThisObject(getVehicle)
						multiPlayer:setBumpType("stagger")
						multiPlayer:setVariable("BumpDone", false)
						multiPlayer:setVariable("BumpFall", true)
						multiPlayer:setVariable("BumpFallType", "pushedFront")
						triggerEvent("OnExitVehicle", multiPlayer)
					end
				end
				getVehicle:setDebugZ(z + x/100)
				getVehicle:setPhysicsActive(true)
			end
			return
		end
		Events.OnTick.Remove(onTick)
	end
	Events.OnTick.Add(onTick)
end

function CarBombFeature.ExplosionCalc(vehicle, plantType)
	local square = vehicle:getSquare()
	local sqX, sqY, sqZ = vehicle:getX(), vehicle:getY(), vehicle:getZ()
	if vehicle:getPartById(plantType) then
		local partArea = vehicle:getAreaCenter(vehicle:getPartById(plantType):getArea())
		square = getCell():getOrCreateGridSquare(partArea:getX(), partArea:getY(), sqZ)
		sqX, sqY = partArea:getX(), partArea:getY()
	end

	if not vehicle:getModData().CarBombSlots then return end
--	local bomb = square:AddWorldInventoryItem(the bomb, 0.5, 0.5, 0)
	local bomb = vehicle:getModData().CarBombSlots[plantType]
	if not bomb or not bomb[1] then return end
	local smokeBomb = instanceItem("Base.SmokeBomb")
	local attacker
	if isServer() then
		attacker = getPlayerByOnlineID(bomb[2])
	else
		attacker = getSpecificPlayer(bomb[2])
	end
	local trap = not string.contains(bomb[1], "Smoke")
	if trap then
		trap = IsoTrap.new(attacker, instanceItem(bomb[1]), square:getCell(), square)
	else
		trap = false
		smokeBomb = instanceItem(bomb[1])
	end
	local smokeEffect = IsoTrap.new(attacker, smokeBomb, square:getCell(), square)

	if trap then
		local fuelTotal = 0
		local containsExplosives = {}
		local plantTypePart = vehicle:getPartById(plantType)

		local GasTank = vehicle:getPartById("GasTank")
		local Engine = vehicle:getPartById("Engine")
		local Heater = vehicle:getPartById("Heater")

		local GasTankHasFuel = false
		if GasTank and GasTank:getContainerContentAmount() > 0 then
			fuelTotal = fuelTotal + GasTank:getContainerContentAmount()
			GasTankHasFuel = true
		end

		--explosion spreads to inner vehicle containers
		if (plantType == "Ignition" or (plantTypePart and plantTypePart:getDoor())) or GasTankHasFuel then
			for i=0, vehicle:getPartCount() do
				local part = vehicle:getPartByIndex(i)
				if part and part:getInventoryItem() then
					local itemCont = part:getItemContainer()
					if itemCont then		--Scan for more things that could explode
						local partId = part:getId()
						local it = itemCont:getItems()
						for i = 0, it:size()-1 do
							local item = it:get(i)
							if item then
								if item:isFluidContainer() then
									local fluidCont = item:getFluidContainerFromSelfOrWorldItem()
									if fluidCont:contains(Fluid.Petrol) then
									--	print("Total Petrol: ", fluidCont:getSpecificFluidAmount(Fluid.Petrol))
										fuelTotal = fuelTotal + fluidCont:getSpecificFluidAmount(Fluid.Petrol)
										containsExplosives[partId] = true
									end
									if fluidCont:contains(Fluid.Alcohol) then
									--	print("Total Alcohol: ", fluidCont:getSpecificFluidAmount(Fluid.Alcohol))
										fuelTotal = fuelTotal + fluidCont:getSpecificFluidAmount(Fluid.Alcohol)
										containsExplosives[partId] = true
									end
								elseif string.contains(item:getType(), "Propane") and item:isItemType(ItemType.Drainable) then
								--	print("Total Propane: ", round(item:getCurrentUses()/250, 2))
									fuelTotal = fuelTotal + round(item:getCurrentUses()/250, 2)
									containsExplosives[partId] = true
								end
							end
						end
						if containsExplosives[partId] then		--If container explodes, remove all items in container
							itemCont:removeAllItems()
							sendRemoveItemsFromContainer(itemCont, it)
						end
					end
				end
			end
		end

		local partAreaX, partAreaY = sqX, sqY
		for i=0, vehicle:getPartCount() do
			local part = vehicle:getPartByIndex(i)
			if part and part:getInventoryItem() then		--Damaging, Removing, and Placing Parts
				local partItem = part:getInventoryItem()
				local partId = part:getId()
				local partArea = vehicle:getAreaCenter(part:getArea())
				if containsExplosives[partId] then
					partAreaX, partAreaY = sqX, sqY
				elseif partArea then
					partAreaX, partAreaY = partArea:getX(), partArea:getY()
				elseif not (partAreaX or partAreaY) then
					partAreaX, partAreaY = part:getX(), part:getY()
				end
				local dx = partAreaX - sqX
				local dy = partAreaY - sqY
				local distToExlposion = math.sqrt(dx*dx + dy*dy)
				local newPartCond = 0
				if distToExlposion ~= 0 and distToExlposion > fuelTotal/100 then
					newPartCond = part:getCondition() - ZombRand(60,90)/(distToExlposion - fuelTotal/100)
					if newPartCond < 0 then newPartCond = 0 end
				end

				local door = part:getDoor()
				if part == GasTank then
					if GasTankHasFuel then
						part:setCondition(0)
					else
						part:setCondition(newPartCond)
					end
					part:setContainerContentAmount(0)
					vehicle:transmitPartCondition(part)
				elseif partId == plantType then
					part:setCondition(0)
					if not door then
						part:setContainerContentAmount(0)
					end
					partItem:setItemCapacity(part:getContainerContentAmount())
					part:setInventoryItem(nil)
					local partSquare = getCell():getOrCreateGridSquare(partAreaX, partAreaY, sqZ)
					partSquare:AddWorldInventoryItem(partItem, partAreaX-partSquare:getX(), partAreaY-partSquare:getY(), 0)
				elseif part:getWindow() then --or partId:contains("Windshield") then
					part:getInventoryItem():setItemCapacity(part:getContainerContentAmount())
					part:setInventoryItem(nil)
				elseif part:getWheelIndex() ~= -1 then
					part:setCondition(newPartCond)
					if newPartCond == 0 then
						partItem:setItemCapacity(part:getContainerContentAmount())
						part:setInventoryItem(nil)
					--	part:setModelVisible("InflatedTirePlusWheel", false)
					--	vehicle:setTireRemoved(part:getWheelIndex(), true)
					--	vehicle:playSound("VehicleTireExplode")
					--	player:triggerMusicIntensityEvent("VehicleTireExplode")
						local partSquare = getCell():getOrCreateGridSquare(partAreaX, partAreaY, sqZ)
						partSquare:AddWorldInventoryItem(partItem, partAreaX-partSquare:getX(), partAreaY-partSquare:getY(), 0)
					else
						part:setContainerContentAmount(0)
						vehicle:transmitPartCondition(part)
					end
				elseif door then
					part:setCondition(newPartCond)
					if newPartCond == 0 then
						partItem:setItemCapacity(part:getContainerContentAmount())
						part:setInventoryItem(nil)
						local partSquare = getCell():getOrCreateGridSquare(partAreaX, partAreaY, sqZ)
						partSquare:AddWorldInventoryItem(partItem, partAreaX-partSquare:getX(), partAreaY-partSquare:getY(), 0)
						if vehicle:getModData().CarBombSlots[partId] then
							vehicle:getModData().CarBombSlots[partId] = nil
							if isServer() then
							--	vehicle:transmitModData()
								local args = { vehicleId = vehicle:getId(), PT = partId, CarBombSlotsMD = nil }
								sendServerCommand("MoreCarFeatures", "CarBombTransmitModData", args)
							end
						end
					else
						door:setLocked(false)
						if not door:isOpen() then
							door:setOpen(true)
							vehicle:playPartAnim(part, "Open")
						end
					--	door:setLockBroken(true)
						vehicle:transmitPartCondition(part)
						if vehicle:getModData().CarBombSlots[partId] then
							CarBombFeature.ExplosionCalc(vehicle, partId)
						end
					end
				elseif partId == "Interior" then		--ignore this "part"?
				else
					part:setCondition(newPartCond)
					vehicle:transmitPartCondition(part)
				end
				vehicle:transmitPartItem(part)
			end
		end
		if Engine and (not Engine:getTable("uninstall") or Engine:getInventoryItem()) then
			partArea = vehicle:getAreaCenter(Engine:getArea())
			if partArea then
				partAreaX, partAreaY = partArea:getX(), partArea:getY()
			elseif not (partAreaX or partAreaY) then
				partAreaX, partAreaY = Engine:getX(), Engine:getY()
			end
			dx = partAreaX - sqX
			dy = partAreaY - sqY
			distToExlposion = math.sqrt(dx*dx + dy*dy)
			newPartCond = 0
			if distToExlposion ~= 0 and distToExlposion > fuelTotal/100 then
				newPartCond = (Engine:getCondition() - ZombRand(60,90)/(distToExlposion - fuelTotal/100)) / 2
				if newPartCond < 0 then newPartCond = 0 end
			end
			Engine:setCondition(newPartCond)
			vehicle:transmitPartCondition(Engine)
			vehicle:transmitPartItem(Engine)
		end
		if Heater and (not Heater:getTable("uninstall") or Heater:getInventoryItem()) then
			partArea = vehicle:getAreaCenter(Heater:getArea())
			if partArea then
				partAreaX, partAreaY = partArea:getX(), partArea:getY()
			elseif not (partAreaX or partAreaY) then
				partAreaX, partAreaY = Heater:getX(), Heater:getY()
			end
			dx = partAreaX - sqX
			dy = partAreaY - sqY
			distToExlposion = math.sqrt(dx*dx + dy*dy)
			newPartCond = 0
			if distToExlposion ~= 0 and distToExlposion > fuelTotal/100 then
				newPartCond = (Heater:getCondition() - ZombRand(60,90)/(distToExlposion - fuelTotal/100)) / 1.5
				if newPartCond < 0 then newPartCond = 0 end
			end
			Heater:setCondition(newPartCond)
			vehicle:transmitPartCondition(Heater)
			vehicle:transmitPartItem(Heater)
		end

		trap:setExplosionPower(trap:getExplosionPower()/10)
		trap:setExplosionRange(trap:getExplosionRange()/10)
		trap:setFireStartingChance(trap:getFireStartingChance()/10)
		trap:setFireStartingEnergy(trap:getFireStartingEnergy()/10)

		if fuelTotal > 0 then
			trap:setExplosionPower(trap:getExplosionPower() + fuelTotal)
			trap:setExplosionRange(trap:getExplosionRange() + fuelTotal/10)

			trap:setFireRange(trap:getFireRange() + fuelTotal/10)
			trap:setFireStartingChance(trap:getFireStartingChance() + fuelTotal/20)
			trap:setFireStartingEnergy(trap:getFireStartingEnergy() + fuelTotal/5)

			smokeEffect:setFireRange(2+fuelTotal/100)
			smokeEffect:setFireStartingChance(trap:getFireStartingEnergy()*2)
			smokeEffect:setFireStartingEnergy(trap:getFireStartingEnergy()*2)

			smokeEffect:setExplosionPower(trap:getExplosionPower()*2)
			smokeEffect:setExplosionRange(smokeEffect:getFireRange())
		end

	--	print("Fuel Total:", fuelTotal)
		local jumpHeight = 2 - (vehicle:getMass()/1000) + (trap:getExplosionPower()/100)		--1 to 3
	--	print("Jump Height: ", jumpHeight)
		if isServer() then
			local args = { vehicleId = vehicle:getId(), z = vehicle:getDebugZ(), dif = jumpHeight }
			sendServerCommand("MoreCarFeatures", "CarBombJumpVehicle", args)
		else
			CarBombFeature.JumpVehicle(vehicle:getId(), vehicle:getDebugZ(), jumpHeight)
		end

	--	square:syncIsoTrap(bomb)
	--	square:syncIsoTrap(smokeBomb)

		trap:place()		--placing it syncs the explosion sound
		trap:triggerExplosion()
		trap:removeFromWorld()
		trap:removeFromSquare()
		trap:setSquare(nil)
		square:transmitRemoveItemFromSquare(trap)
	end
--	smokeEffect:place()
	smokeEffect:triggerExplosion()
	smokeEffect:removeFromWorld()
--	smokeEffect:removeFromSquare()
--	smokeEffect:setSquare(nil)
--	square:transmitRemoveItemFromSquare(smokeEffect)

--	square:transmitRemoveItemFromSquare(bomb:getWorldItem())
--	square:removeWorldObject(bomb:getWorldItem())
--	bomb:setWorldItem(nil)

	vehicle:getModData().CarBombSlots[plantType] = nil
	if isServer() then
	--	vehicle:transmitModData()
		local args = { vehicleId = vehicle:getId(), PT = plantType, CarBombSlotsMD = nil }
		sendServerCommand("MoreCarFeatures", "CarBombTransmitModData", args)
	end
end

--IsoTrap
--getRemoteControlID(), setRemoteControlID(int remoteControlId), triggerRemote(IsoPlayer player, int remoteID, int range)
--HandWeapon/InventoryItem
--getRemoteControlID(), setRemoteControlID(int remoteControlId),
--getRemoteRange(), setRemoteRange(int remoteRange), canBeRemote(), setCanBeRemote(boolean canBeRemote), isRemoteController(), setRemoteController(), setActivatedRemote(),
function CarBombFeature.doRemote(playerObj, remoteID, radius)
	local cell = getCell()
	local x, y, z = playerObj:getX(), playerObj:getY(), playerObj:getZ()
	local seen = {}
	local r2 = radius^2
	for dx = -radius, radius do
		for dy = -radius, radius do
			if (dx * dx + dy * dy) <= r2 then
				local sq = cell:getGridSquare(x + dx, y + dy, z)
				if sq then
					local vehicle = sq:getVehicleContainer()
					if vehicle and not seen[vehicle] then
						seen[vehicle] = true
						local CarBombSlotsMD = vehicle:getModData().CarBombSlots
						if CarBombSlotsMD then
							local possibleCarBombSlots = {}
							table.insert(possibleCarBombSlots, "Chasis")
							for i=0, vehicle:getScript():getPartCount()-1 do
								local part = vehicle:getPartByIndex(i)
								if part then
									if part:getCategory() == "tire" and part:getId():contains("Tire") then
										table.insert(possibleCarBombSlots, part:getId())
									end
								end
							end
							for _, plantType in ipairs(possibleCarBombSlots) do
								if CarBombSlotsMD[plantType] and CarBombSlotsMD[plantType][3] == remoteID then
									CarBombFeature.ExplosionCalc(vehicle, plantType)
								end
							end
						end
					end
				end
			end
		end
	end
end

--VehicleWindowHandleOpen
--VehicleWindowElectricOpen
--OnPlayerGetDamage

--Car bombs are activated in a variety of ways, including 
--	opening the vehicle's doors, starting the engine, remote detonation, 
--		depressing the accelerator or brake pedals, (not this one, redundant)
--			or simply lighting a fuse or setting a timing device.

if not isClient() then
	local ClientCommands = {}
	local Commands = {}
	Commands.object = {}

	Commands.object.triggerRemote = function(player, args)
		if args.id and args.range then
		--	IsoTrap.triggerRemote(player, args.id, args.range)
			CarBombFeature.doRemote(player, args.id, args.range)
		end
	end

	ClientCommands.OnClientCommand = function(module, command, player, args)
		if Commands[module] and Commands[module][command] then
			Commands[module][command](player, args)
		end
	end
	Events.OnClientCommand.Add(ClientCommands.OnClientCommand)
end

if isServer() then
	local function onClientCommand(module, command, playerObj, args)
		if module == 'MoreCarFeatures' then
			if command == 'CarBombTransmitModData' then
				if args and args.vehicleId and args.plantPOS and args.remoteID then
					local vehicle = getVehicleById(args.vehicleId)
					if vehicle then
						local plantType = args.plantPOS
						vehicle:getModData().CarBombSlots = vehicle:getModData().CarBombSlots or {}
						if vehicle:getModData().CarBombSlots[plantType] and vehicle:getModData().CarBombSlots[plantType][1] then
							vehicle:getModData().CarBombSlots[plantType][3] = args.remoteID
							local returnArgs = { vehicleId = args.vehicleId, PT = plantType, CarBombSlotsMD = args.remoteID }
							sendServerCommand("MoreCarFeatures", "CarBombTransmitModData", returnArgs)
						end
					end
				end
			end
		end
	end
	Events.OnClientCommand.Add(onClientCommand)
elseif isClient() then
	local function onServerCommand(module, command, args)
		if module == 'MoreCarFeatures' then
			if command == 'CarBombTransmitModData' then
				local vehicle = getVehicleById(args.vehicleId)
				if vehicle then
					vehicle:getModData().CarBombSlots = vehicle:getModData().CarBombSlots or {}
					if not args.CarBombSlotsMD then
						vehicle:getModData().CarBombSlots[args.PT] = nil
					else
						vehicle:getModData().CarBombSlots[args.PT][3] = args.CarBombSlotsMD
					end
				end
			elseif command == 'CarBombJumpVehicle' then
				CarBombFeature.JumpVehicle(args.vehicleId, args.z, args.dif)
			end
		end
	end
	Events.OnServerCommand.Add(onServerCommand)
end


--	CarBombFeature.JumpVehicle(vehicle:getId(), vehicle:getDebugZ(), 3)
	--	CarBombFeature.JumpVehicle(getPlayer():getVehicle():getId(), getPlayer():getVehicle():getDebugZ(), 3)
--	CarBombFeature.ExplosionCalc(vehicle, "Ignition")
	--	CarBombFeature.ExplosionCalc(getPlayer():getVehicle(), "Ignition")


local ISOpenVehicleDoorComplete = ISOpenVehicleDoor.complete
function ISOpenVehicleDoor:complete()
	local originalComplete = ISOpenVehicleDoorComplete(self)

	if self.vehicle and self.part and self.part:getDoor() and not self.part:getDoor():isLocked() then
		local CarBombSlotsMD = self.vehicle:getModData().CarBombSlots
		if CarBombSlotsMD and CarBombSlotsMD[self.part:getId()] then
			self.part:getDoor():setOpen(true)
			self.vehicle:playPartAnim(self.part, "Open")
			self.vehicle:transmitPartDoor(self.part)
			CarBombFeature.ExplosionCalc(self.vehicle, self.part:getId())
		end
	end

	return originalComplete
end


if isServer() then		--Multiplayer W Key Press to Start Vehicle
	local VehicleCommands = {}
	local Commands = {}
	function Commands.startEngine(player, args)
		local vehicle = player:getVehicle()
		if vehicle then
			CarBombFeature.ExplosionCalc(vehicle, "Ignition")
		end
	end
	VehicleCommands.OnClientCommand = function(module, command, player, args)
		if module == 'vehicle' and Commands[command] then
			args = args or {}
			Commands[command](player, args)
		end
	end
	Events.OnClientCommand.Add(VehicleCommands.OnClientCommand)
elseif not isClient() then		--Singleplayer W Key Press to Start Vehicle
	local function onKeyKeepPressed(key)
		if getCore():isKey("Forward", key) then
			local player = getSpecificPlayer(0)
			if not player then return end
			local vehicle = player:getVehicle()
			if not vehicle then return end

			if vehicle:isDriver(player)
				and vehicle:isEngineWorking()
				and vehicle:getBatteryCharge() >= 0.1
				and not ( vehicle:isStarting() 
				or vehicle:isEngineRunning()
				or vehicle:isEngineStarted() )
				and ( player:getInventory():haveThisKeyId(vehicle:getKeyId()) 
				or vehicle:isKeysInIgnition() 
				or vehicle:isHotwired() )
			then
				local vehicleId = vehicle:getId()
				local delayTick = 2
				local function onTick()
					delayTick = delayTick - 1
					if delayTick > 0 then return end
					vehicle = getVehicleById(vehicleId)
					if vehicle and ( vehicle:isStarting() or vehicle:isEngineRunning() or vehicle:isEngineStarted() ) then
						CarBombFeature.ExplosionCalc(vehicle, "Ignition")
					end
					Events.OnTick.Remove(onTick)
				end
				Events.OnTick.Add(onTick)
			end
		end
	end
	Events.OnKeyKeepPressed.Add(onKeyKeepPressed)
end

local ISStartVehicleEngineComplete = ISStartVehicleEngine.complete
function ISStartVehicleEngine:complete()
	local originalComplete = ISStartVehicleEngineComplete(self)

	local vehicle = self.character:getVehicle()
	if vehicle then
		local CarBombSlotsMD = vehicle:getModData().CarBombSlots
		if CarBombSlotsMD and CarBombSlotsMD["Ignition"] then
			local haveKey = false
			if self.character:getInventory():haveThisKeyId(vehicle:getKeyId()) then
				haveKey = true
			end
			if vehicle:isDriver(self.character) and (haveKey or vehicle:isKeysInIgnition() or vehicle:isHotwired()) then
				vehicle:tryStartEngine(haveKey)
				CarBombFeature.ExplosionCalc(vehicle, "Ignition")
			end
		end
	end

	return originalComplete
end


end
Events.OnInitGlobalModData.Add(InteractionsBombVehicle)