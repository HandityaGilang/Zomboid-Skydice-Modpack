EperimentalCarFeatures = EperimentalCarFeatures or {}

if not getCore():getDebug() or isClient() or isServer() then return end

--timed action bugged, force stopped
--function ISVehicleMenu.addAnimalToVSeat(vehicle, player, animal, seatPart)
--	local seatCont = seatPart:getItemContainer()
--	print(round(animal:getWeight(),2))
--	print(seatCont:getCapacity())
--	print(seatCont:getContentsWeight())
--	if seatCont:getContentsWeight() == 0 or (seatCont:getCapacity() - seatCont:getContentsWeight() >= round(animal:getWeight(),2)) then
--		local vec = vehicle:getAreaCenter(seatPart:getArea());
--		local sq = getSquare(vec:getX(), vec:getY(), vehicle:getZ());
--		if luautils.walkAdj(player, sq) then
--			ISTimedActionQueue.add(ISInventoryTransferAction:new(player, animal, player:getInventory(), seatCont))
--		end
--	end
--end
--	local primeHandObj = playerObj:getPrimaryHandItem()
--	if primeHandObj and instanceof(primeHandObj, "AnimalInventoryItem") 
--		and not (primeHandObj:getType() == "CorpseAnimal" or primeHandObj:getDeadBodyObject())
--		and not vehicle:isBurntOrSmashed() and vehicle:getMaxPassengers() > 0
--		and doorPart and doorPart:getDoor() and (not doorPart:getInventoryItem() or doorPart:getDoor():isOpen()) 
--	then
--		for seat=0, vehicle:getMaxPassengers()-1 do
--			if vehicle:getPassengerDoor(seat) == doorPart then
--				local seatPart = vehicle:getPartForSeatContainer(seat)
--				if seatPart and seatPart:getInventoryItem() then
--					menu:addSlice(getText("ContextMenu_AddAnimal"), getTexture("media/ui/Item_SheepWhite_Lamb.png"), ISVehicleMenu.addAnimalToVSeat, vehicle, playerObj, primeHandObj, seatPart)
--				end
--				break
--			end
--		end
--	end

--For testing zombies jumping out of vehicle trunks on initial spawn, haven't really started looking into it
--local function OnZombieCreate(zombie)
--	zombie:climbOverFence(IsoDirections.S)
--end
--Events.OnZombieCreate.Add(OnZombieCreate)

local function initExperimentalCarStuff()

local WayMoreCarsExtraOptions = PZAPI.ModOptions:getOptions("WayMoreCarsExtraOptionsID")
local jumpCars = WayMoreCarsExtraOptions:getOption("jumpCarsID")
local launchCars = WayMoreCarsExtraOptions:getOption("launchCarsID")
local carsConditional = WayMoreCarsExtraOptions:getOption("carsCondID")

local scripts = getScriptManager():getAllVehicleScripts()
local burntVehicles = {}
local smashedVehicles = {}
for i = 1, scripts:size() do
	local script = scripts:get(i - 1)
	local name   = string.lower(script:getName())
	if string.find(name, "burnt") then
		table.insert(burntVehicles, script:getFullName())
	elseif string.find(name, "smashed") then
		table.insert(smashedVehicles, script:getFullName())
	end
end
local function getRandomFromTable(t)
	if not t or #t == 0 then return nil end
	return t[ZombRand(#t) + 1]
end

local function worldToVehicleLocal(dx, dy, vehicle)
	local theta = MoreCarFeatures.getVehicleDir(vehicle)

	local cosT = math.cos(theta)
	local sinT = math.sin(theta)

	local localX =  dx * cosT + dy * sinT
	local localY = -dx * sinT + dy * cosT

	return localX, localY
end
local function getSmashSideFromBomb(vehicle, square)
	local dx = square:getX() - vehicle:getX()
	local dy = square:getY() - vehicle:getY()

	local lx, ly = worldToVehicleLocal(dx, dy, vehicle)

	if math.abs(lx) > math.abs(ly) then
		if lx > 0 then
			return "N"
		else
			return "S"
		end
	else
		if ly > 0 then
			return "E"
		else
			return "W"
		end
	end
end

local function funcLaunchCars(vehicle, square)
	local i = -1
	local function jumpCarFirst()
		i = i + 1
		if i <= 3 then
			vehicle:onJump()
		end
		if i <= 4 then return end
		vehicle:onHitLandmine(square)
		Events.OnTick.Remove(jumpCarFirst)
	end
	Events.OnTick.Add(jumpCarFirst)
end

local function scanVehiclesInRadius(x, y, z, radius, vehicle, setBombAction, setJumpCar, setLaunchCar)
	if not (x and y and z) then return end
	local cell = getCell()
	local square = cell:getOrCreateGridSquare(x, y, z)
	local seen = {}
	local r2 = radius * radius
	for dx = -radius, radius do
		for dy = -radius, radius do
			local hitPoint = (dx * dx + dy * dy)
			if hitPoint <= r2 then
				local sq0 = cell:getGridSquare(x + dx, y + dy, z)
				if sq0 then
					local vehicles = sq0:getVehicleContainer()
					if vehicles ~= nil and not seen[vehicles] then
						seen[vehicles] = true
						if vehicle and vehicles ~= vehicle then

							if setBombAction then
				--				local rand = newrandom()
							--	print(hitPoint)
				--				local radiusDamage = setBombAction[1]
							--	print(radiusDamage^2)
				--				local radiusFling = setBombAction[2]
							--	print(radiusFling^2)
				--				local radiusJump = setBombAction[3]
							--	print(radiusJump^2)
								local radiusAlarm = setBombAction[4]
							--	print(radiusAlarm^2)
				--				if radiusDamage and hitPoint <= radiusDamage^2 then
				--					local randCarDamaged = rand:random(1, 100)
				--					if randCarDamaged <= 50 then
				--						if not vehicles:isBurnt() and not string.contains(string.lower(vehicles:getScriptName()), "trailer") then
				--							vehicles:setAlarmed(false)
				--							local vDir = { vehicles:getAngleX(), vehicles:getAngleY(), vehicles:getAngleZ(), vehicles:getDebugZ() }
				--							local vPos = { vehicles:getX(), vehicles:getY(), vehicles:getZ() }
				--							vehicles:permanentlyRemove()
				--							local i = 2
				--							local function replaceBurnt()
				--								i = i - 1
				--								if i <= 0 then
				--									vehicles = addVehicle(getRandomFromTable(burntVehicles), vPos[1], vPos[2], vPos[3])	--should pick out a burnt vehicle tied to the vehicle it matches best with
				--									vehicles:setDebugZ(vDir[4])
				--									vehicles:setAngles(vDir[1], vDir[2], vDir[3])
				--									Events.OnTick.Remove(replaceBurnt)
				--								end
				--							end
				--							Events.OnTick.Add(replaceBurnt)
				--						end
							-- works-ish, can't set smashed, but I have the correct side. Can reuse functions, burnt will do for here.
								--	elseif randCarDamaged <= 0 then
								--		local smashSide = getSmashSideFromBomb(vehicles, square)
								--		vehicles:setSmashed(smashSide)
				--					end
				--				end
				--				if radiusFling and hitPoint <= radiusFling^2 then
				--					if not vehicles:isBurnt() and not string.contains(string.lower(vehicles:getScriptName()), "trailer") then
				--						funcLaunchCars(vehicles, square)
				--					end
				--				end
								if radiusJump and hitPoint <= radiusJump^2 then
									vehicles:onJump()
								end
								if radiusAlarm and hitPoint <= radiusAlarm^2 then
									local i = 2
									local function ifReplaceBurnt()
										i = i - 1
										if i <= 0 then
											if not vehicles:isBurnt() and not vehicles:isSmashed() and not string.contains(string.lower(vehicles:getScriptName()), "trailer") then
												if vehicles:isAlarmed() then --or vehicles:areAllDoorsLocked() --extra punishing
												--	vehicles:setAlarmed(true)
													vehicles:triggerAlarm()
												end
											end
											Events.OnTick.Remove(ifReplaceBurnt)
										end
									end
									Events.OnTick.Add(ifReplaceBurnt)
								end

							elseif setJumpCar then
								vehicles:onJump()
							elseif setLaunchCar then
								funcLaunchCars(vehicles, square)
							end
							
						end
					end
				end
			end
		end
	end
end

local function explodeVehicles(throwable, square)
--	print(throwable:getExplosionSound())
--	print(throwable:getExplosionPower())
--	print(throwable:getExplosionRange())
	local bombType = throwable:getExplosionSound()		--VANILLA VALUES: power, radius
	local radius										--2 minimum (radius) because 1 is nearly impossible to hit
	local damageType
	if bombType == "PipeBombExplode" then 										--90, 7
		radius = 20	--2 set burnt, 5 to fling, 10 to jump, 20 to set off alarms
		damageType = {2, 5, 10, 20}
	elseif bombType == "AerosolBombExplode" then								--70, 6
		radius = 12	--2 set burnt, 3 to fling, 6 to jump, 12 to set off alarms
		damageType = {2, 3, 6, 12}
	elseif bombType == "MolotovCocktailExplode" then 							--0, 0
		radius = 3	--set burnt or set alarm
		damageType = {3, nil, nil, 2}
	elseif bombType == "FlameTrapExplode" then									--0, 0
		radius = 5	--set burnt or set alarm
		damageType = {5, nil, nil, 2}
--	elseif bombType == "FireCrackerExplode" then								--0, 0
--		return
--	elseif bombType == "FireCrackerSingleExplode" then							--0, 0
--		return
--	elseif bombType == "SmokeBombLoop" then										--0, 0
--		return
--	elseif bombType == "NoiseMakerActivate" then								--0, 0
--		return
	else
		return
	end
	scanVehiclesInRadius(square:getX(), square:getY(), square:getZ(), radius, nil, damageType, false, false)
end
--Events.OnThrowableExplode.Add(explodeVehicles)

local wheelParts = {
	"TireFrontLeft",
	"TireFrontRight",
	"TireRearLeft",
	"TireRearRight"
}

local piHalf = math.pi/2		-- 1.57079633
local pi34th = math.pi*(3/4)	-- 2.35619449
local pi8th = math.pi/8			-- 0.392699082

local NLrange = -piHalf-pi8th	-- -1.96349541
local NRrange = -piHalf+pi8th	-- -1.17809725
local SLrange = piHalf-pi8th	-- 1.17809725
local SRrange = piHalf+pi8th	-- 1.96349541
local WLrange = pi34th+pi8th	-- 2.74889357
local WRrange = -pi34th-pi8th	-- -2.74889357
local ELrange = -pi8th			-- -0.392699082
local ERrange = pi8th			-- 0.392699082

--local impulse = Vector3f.new(1, 1, 1)
--local pos = Vector3f.new(0, 0, 0)
--vehicle:addImpulse(impulse, pos)

local function onPlayerUpdate(player)
	if isKeyDown(carsConditional:getValue()) then
		if isKeyPressed(jumpCars:getValue()) then
			vehicle = player:getVehicle()
			if vehicle then
				scanVehiclesInRadius(vehicle:getX(), vehicle:getY(), vehicle:getZ(), 10, vehicle, nil, true, false)
			end
		elseif isKeyPressed(launchCars:getValue()) then
			vehicle = player:getVehicle()
			if vehicle then
				scanVehiclesInRadius(vehicle:getX(), vehicle:getY(), vehicle:getZ(), 10, vehicle, nil, false, true)
			end
		end
	elseif isKeyPressed(jumpCars:getValue()) then
		vehicle = player:getVehicle()
		if vehicle then
			vehicle:onJump()
		end
	elseif isKeyPressed(launchCars:getValue()) then
		vehicle = player:getVehicle()
		if vehicle then
			local square = getCell():getOrCreateGridSquare(vehicle:getX(), vehicle:getY(), vehicle:getZ())
			if square then
				vehicle:onHitLandmine(square)
			end
		end
	end

--	Auto Steering (proof of concept for trains, doesn't do diagonals)
--	local vehicle = player:getVehicle()
--	if vehicle then
--		local square = getCell():getOrCreateGridSquare(vehicle:getX(), vehicle:getY(), vehicle:getZ())
--		if square then
--			local objects = square:getObjects()
--			if objects then
--				for i = 0, objects:size() - 1 do
--					local obj = objects:get(i)
--					local sprite = obj:getSprite()
--					if sprite then
--					--	print("Object:", sprite:getName())
--						local spriteName = sprite:getName()
--						if spriteName == "industry_railroad_01_1" or spriteName == "industry_railroad_01_4" then
--							local vehicleAngle = getVehicleDir(vehicle)
--							local reversing = false
--							if vehicle:getCurrentSpeedKmHour() < 0 then reversing = true end
--							local function frac(v)
--								return v - math.floor(v)
--							end
--							local desiredFrac = 0.5
--							local centerThreshold = 0.025
--							local centerDirection = 0
--							if spriteName == "industry_railroad_01_1" then
--								local xfrac = frac(vehicle:getX())
--								local delta = xfrac - desiredFrac
--								if delta > centerThreshold then
--									centerDirection = -1
--								elseif delta < -centerThreshold then
--									centerDirection = 1
--								end
--							elseif spriteName == "industry_railroad_01_4" then
--								local yfrac = frac(vehicle:getY())
--								local delta = yfrac - desiredFrac
--								if delta > centerThreshold then
--									centerDirection = -1
--								elseif delta < -centerThreshold then
--									centerDirection = 1
--								end
--							end
--							local facingSouth = (vehicleAngle > SLrange and vehicleAngle < SRrange)
--							local facingWest = (vehicleAngle > WLrange or vehicleAngle < WRrange)
--							local invertSideForCentering = false
--							if facingSouth or facingWest then invertSideForCentering = true end
--							for _, partId in ipairs(wheelParts) do
--								local part = vehicle:getPartById(partId)
--								if part then
--									local deflatePart, inflatePart = false, false
--									local wheelIndex = part:getWheelIndex()
--									if spriteName == "industry_railroad_01_1" then
--										-- FACING NORTH LEFT
--										if vehicleAngle < -piHalf and vehicleAngle > NLrange then
--											if wheelIndex == 0 or wheelIndex == 2 then
--												if not reversing then inflatePart = true else deflatePart = true end
--											else
--												if not reversing then deflatePart = true else inflatePart = true end
--											end
--										-- FACING NORTH RIGHT
--										elseif vehicleAngle > -piHalf and vehicleAngle < NRrange then
--											if wheelIndex == 0 or wheelIndex == 2 then
--												if not reversing then deflatePart = true else inflatePart = true end
--											else
--												if not reversing then inflatePart = true else deflatePart = true end
--											end
--										end
--										-- FACING SOUTH LEFT
--										if vehicleAngle < piHalf and vehicleAngle > SLrange then
--											if wheelIndex == 0 or wheelIndex == 2 then
--												if not reversing then inflatePart = true else deflatePart = true end
--											else
--												if not reversing then deflatePart = true else inflatePart = true end
--											end
--										-- FACING SOUTH RIGHT
--										elseif vehicleAngle > piHalf and vehicleAngle < SRrange then
--											if wheelIndex == 0 or wheelIndex == 2 then
--												if not reversing then deflatePart = true else inflatePart = true end
--											else
--												if not reversing then inflatePart = true else deflatePart = true end
--											end
--										end
--									elseif spriteName == "industry_railroad_01_4" then
--										if vehicleAngle > WLrange and vehicleAngle < math.pi then
--											-- WEST LEFT
--											if wheelIndex == 0 or wheelIndex == 2 then
--												if not reversing then inflatePart = true else deflatePart = true end
--											else
--												if not reversing then deflatePart = true else inflatePart = true end
--											end
--										elseif vehicleAngle < WRrange and vehicleAngle > -math.pi then
--											-- WEST RIGHT
--											if wheelIndex == 0 or wheelIndex == 2 then
--												if not reversing then deflatePart = true else inflatePart = true end
--											else
--												if not reversing then inflatePart = true else deflatePart = true end
--											end
--										elseif vehicleAngle > ELrange and vehicleAngle < 0 then
--											-- EAST LEFT
--											if wheelIndex == 0 or wheelIndex == 2 then
--												if not reversing then inflatePart = true else deflatePart = true end
--											else
--												if not reversing then deflatePart = true else inflatePart = true end
--											end
--										elseif vehicleAngle < ERrange and vehicleAngle > 0 then
--											-- EAST RIGHT
--											if wheelIndex == 0 or wheelIndex == 2 then
--												if not reversing then deflatePart = true else inflatePart = true end
--											else
--												if not reversing then inflatePart = true else deflatePart = true end
--											end
--										end
--									end
--									if centerDirection ~= 0 then
--										local leftIs = {0,2}
--										local rightIs = {1,3}
--										if invertSideForCentering then
--											leftIs = {1,3}
--											rightIs = {0,2}
--										end
--										if centerDirection == 1 then
--											if wheelIndex == leftIs[1] or wheelIndex == leftIs[2] then
--												inflatePart = true
--												deflatePart = false
--											else
--												inflatePart = false
--												deflatePart = true
--											end
--										elseif centerDirection == -1 then
--											if wheelIndex == rightIs[1] or wheelIndex == rightIs[2] then
--												inflatePart = true
--												deflatePart = false
--											else
--												inflatePart = false
--												deflatePart = true
--											end
--										end
--									end
--									--vehicle:setAngles(0, 0, 0)
--									if inflatePart then
--										part:setContainerContentAmount(40.0, true, true)
--										vehicle:setTireInflation(wheelIndex, 1.00)
--										vehicle:transmitPartModData(part)
--										print("Inflated:", wheelIndex)
--									elseif deflatePart then
--										part:setContainerContentAmount(10.0, true, true)
--										vehicle:setTireInflation(wheelIndex, 0.25)
--										vehicle:transmitPartModData(part)
--										print("Deflated:", wheelIndex)
--									end
--								end
--							end
--						end
--					end
--				end
--			end
--		end
--	end

end
Events.OnPlayerUpdate.Add(onPlayerUpdate)

end
Events.OnInitGlobalModData.Add(initExperimentalCarStuff)
