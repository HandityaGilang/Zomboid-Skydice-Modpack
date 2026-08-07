if getActivatedMods():contains("ClimbableVehicles") then return end

local function initClimbVehicles()
if SandboxVars.GamestaVehicleZones.climbVehicles ~= true then return end

local WayMoreCarsOptions = PZAPI.ModOptions:getOptions("WayMoreCarsOptionsID")
local climbUpHatches = WayMoreCarsOptions:getOption("UpHatchesID")
local dropDownHatches = WayMoreCarsOptions:getOption("DownHatchesID")
local fallSidesHatchesConditional = WayMoreCarsOptions:getOption("SidesHatchesConditionalID")
local fallSidesHatches = WayMoreCarsOptions:getOption("SidesHatchesID")

local vehicleroof
local vehiclesize
local lengthFrontShift
local lengthBackShift
local widthShift
local heightShift
local extraTall
local playerangle
local playerangleOriginal
local playerpos
local playerpospre
local carpospre

fordB700buses_87 = {
	["Base.87fordB700school"] = true, --3, 4, 13, 14
	["Base.87fordB700prison"] = true, --3, 4, 13, 14
	["Base.87fordB700military"] = true, --3, 4, 13, 14
}
commando_67hatch = {
	["Base.67commando"] = true,
	["Base.67commandoT50"] = true,
	["Base.67commandoPolice"] = true,
}
oshkoshP19A_86hatch = {
	["Base.86oshkoshUSMC"] = true, --3
	["Base.86oshkoshKYFD"] = true, --3
	["Base.86oshkoshFRTR55"] = true, --3
}
RangeRoverClassic_91sunroof = {
	["Base.91range"] = true, --0, 1
	["Base.91range2"] = true, --0, 1
}
Limo_93sunroof = {
	["Base.93townCarLimo"] = true, --5
}
MercedesBenzW460long_84hatch = {
	["Base.84mercLWB4M"] = true, --2, 3
}
ToyotaMR2_87sunroof = {
	["Base.87toyotaMR2"] = true, --0, 1
}
Nissan240SX_91sunroof = {
	["Base.91nissan240sx2"] = true, --0, 1
}

local VehicleHatchesTables = {
	fordB700buses_87,
	commando_67hatch,
	oshkoshP19A_86hatch,
	RangeRoverClassic_91sunroof,
	Limo_93sunroof,
	MercedesBenzW460long_84hatch,
	ToyotaMR2_87sunroof,
	Nissan240SX_91sunroof,
}

local VehicleHatches = {}
for _, tableGroup in ipairs(VehicleHatchesTables) do
	for k,v in pairs(tableGroup) do
		VehicleHatches[k] = true
	end
end

local function getSpecificV(vehicle)
	local fullVName = vehicle:getScript():getFullName()
	if fordB700buses_87[fullVName] then
		return {0.7, 3.1}, 0.8, 1.2, -1.2--, 0.0
	elseif commando_67hatch[fullVName] then
		return {0.6, 1.8}, 0.8, 1.2, -0.55--, 0.25
	elseif oshkoshP19A_86hatch[fullVName] then
		return {0.5, 3.3}, 1.0, 0.9, -1.0--, 0.1
	elseif RangeRoverClassic_91sunroof[fullVName] then
		return {0.5, 1.0}, 0.01, 1.6, -0.2
	elseif Limo_93sunroof[fullVName] then
		return {0.4, 1.4}, 0.5, 1.3, 0.0
	elseif MercedesBenzW460long_84hatch[fullVName] then
		return {0.5, 1.1}, 0.3, 1.5, -0.5
	elseif ToyotaMR2_87sunroof[fullVName] then
		return {0.3, 0.3}, 0.4, 1.2, 0.3
	elseif Nissan240SX_91sunroof[fullVName] then
		return {0.3, 0.2}, 0.1, 3.0, 0.3
	end
end

local function getab(table1,table2)
	local a,b
	local c = table1[1]-table2[1]
	if c ~= 0 then
		a = (table1[2]-table2[2])/c
		b = table1[2]-a*table1[1]
		return a,b
	else 
		return false,false
	end
end

local function localisSolidRoof()
	local cell = getCell()
	if not vehicleroof then return end

	local z0 = 0
	local baseX = math.floor(vehicleroof:getX())
	local baseY = math.floor(vehicleroof:getY())

	local maxsize = math.max(vehiclesize[1], vehiclesize[2])
	local rx = math.ceil(maxsize)+1
	local ry = rx

	solidRoofCheck = false
	for dx = -rx, rx do
		for dy = -ry, ry do
			local sx = baseX + dx
			local sy = baseY + dy
			local sq0 = cell:getGridSquare(sx, sy, z0)
			if sq0 then
				if sq0:getVehicleContainer() == vehicleroof then
					local sq1 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift-1, 1)
					if sq1:isSolidFloor() then solidRoofCheck = true return end
					local sq2 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift+1, 1)
					if sq2:isSolidFloor() then solidRoofCheck = true return end
					local sq3 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift+1, 1)
					if sq3:isSolidFloor() then solidRoofCheck = true return end
					local sq4 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift-1, 1)
					if sq4:isSolidFloor() then solidRoofCheck = true return end
				end
			end
		end
	end
end

local function solidifyRoof()
	local cell = getCell()
	if not vehicleroof then return end

	local z0 = 0
	local baseX = math.floor(vehicleroof:getX())
	local baseY = math.floor(vehicleroof:getY())

	local maxsize = math.max(vehiclesize[1], vehiclesize[2])
	local rx = math.ceil(maxsize)+1
	local ry = rx

	for dx = -rx, rx do
		for dy = -ry, ry do
			local sx = baseX + dx
			local sy = baseY + dy
			local sq0 = cell:getGridSquare(sx, sy, z0)
			if sq0 then
				if sq0:getVehicleContainer() == vehicleroof then -- use ~= nil instead if overlapping vehicles cause issues
					local sq1 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift-1, 1)
					if sq1 then sq1:setSolidFloor(true) end
					local sq2 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift+1, 1)
					if sq2 then sq2:setSolidFloor(true) end
					local sq3 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift+1, 1)
					if sq3 then sq3:setSolidFloor(true) end
					local sq4 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift-1, 1)
					if sq4 then sq4:setSolidFloor(true) end
				end
--			else (backup)
--				local objects = sq0:getLuaMovingObjectList()
--				for i, obj in ipairs(objects) do
--					print(vehicleroof)
--					print(obj)
--					if obj == vehicleroof then
--						print("yes")
--						local sq5 = cell:getOrCreateGridSquare(sx+heightShift, sy+heightShift, z)
--						if sq5 then sq5:setSolidFloor(true) end
--					else
--						print("no")
--					end
--				end
			end
		end
	end
end

local function unsolidifyRoof()
	local cell = getCell()
	if not vehicleroof then return end

	local z0 = 0
	local baseX = math.floor(vehicleroof:getX())
	local baseY = math.floor(vehicleroof:getY())

	local maxsize = math.max(vehiclesize[1], vehiclesize[2])
	local rx = math.ceil(maxsize)+1
	local ry = rx

	for dx = -rx, rx do
		for dy = -ry, ry do
			local sx = baseX + dx
			local sy = baseY + dy
			local sq0 = cell:getGridSquare(sx, sy, z0)
			if sq0 then
				if sq0:getVehicleContainer() == vehicleroof then
					local sq1 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift-1, 1)
					if sq1 then sq1:setSolidFloor(false) end
					local sq2 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift+1, 1)
					if sq2 then sq2:setSolidFloor(false) end
					local sq3 = cell:getOrCreateGridSquare(sx+heightShift-1, sy+heightShift+1, 1)
					if sq3 then sq3:setSolidFloor(false) end
					local sq4 = cell:getOrCreateGridSquare(sx+heightShift+1, sy+heightShift-1, 1)
					if sq4 then sq4:setSolidFloor(false) end
				end
			end
		end
	end
end

local function ifOnRoof(player)
	local vx = vehicleroof:getX()
	local vy = vehicleroof:getY()
	local vz = vehicleroof:getZ()
	
	if not (vehicleroof and playerangle and playerpos) or (isKeyDown(fallSidesHatchesConditional:getValue()) and isKeyPressed(fallSidesHatches:getValue())) or (fallSidesHatchesConditional:getValue() == 0 and isKeyPressed(fallSidesHatches:getValue())) then
		carpospre = nil
		playerpospre = nil
		unsolidifyRoof()
		player:setX(player:getX()-heightShift)
		player:setY(player:getY()-heightShift)
		if extraTall then player:setZ(player:getZ()-extraTall) else player:setZ(player:getZ()-0.5) end
		player:getModData().isonHatch = { false, nil, nil, nil, nil, nil, nil, nil, nil }
		
		Events.OnPlayerUpdate.Remove(ifOnRoof)
		return
	end

	if isKeyPressed(dropDownHatches:getValue()) then
		if player:getModData().saveHatchSeatNumber then
			local part = vehicleroof:getPartForSeatContainer(player:getModData().saveHatchSeatNumber)
			if part and part:getInventoryItem() ~= nil then
				carpospre = nil
				playerpospre = nil
				unsolidifyRoof()
				player:getModData().isonHatch = { false, nil, nil, nil, nil, nil, nil, nil, nil }
				vehicleroof:enter(player:getModData().saveHatchSeatNumber, player)
				vehicleroof:setCharacterPosition(player, player:getModData().saveHatchSeatNumber, "inside")
				vehicleroof:transmitCharacterPosition(player:getModData().saveHatchSeatNumber, "inside")
				vehicleroof:playPassengerAnim(player:getModData().saveHatchSeatNumber, "idle")
				
				triggerEvent("OnEnterVehicle", player)
				triggerEvent("OnSwitchVehicleSeat", player)
				Events.OnPlayerUpdate.Remove(ifOnRoof)
				return
			end
		end
	end

	local driver = vehicleroof:getDriver()
	if driver then
		playerangle = driver:getForwardDirection():getDirection()
	end

	playerpos = {player:getX()-heightShift,player:getY()-heightShift,1}

	local vx1 = vx + vehiclesize[2]*lengthBackShift*math.cos(playerangle) + vehiclesize[1]*math.cos(playerangle+math.pi/2)
	local vy1 = vy + vehiclesize[2]*lengthBackShift*math.sin(playerangle) + vehiclesize[1]*math.sin(playerangle+math.pi/2)

	local vx2 = vx + vehiclesize[2]*lengthFrontShift*math.cos(playerangle+math.pi) + vehiclesize[1]*math.cos(playerangle+math.pi/2)
	local vy2 = vy + vehiclesize[2]*lengthFrontShift*math.sin(playerangle+math.pi) + vehiclesize[1]*math.sin(playerangle+math.pi/2)

	local vx3 = vx + vehiclesize[2]*lengthFrontShift*math.cos(playerangle+math.pi) + vehiclesize[1]*math.cos(playerangle-math.pi/2)
	local vy3 = vy + vehiclesize[2]*lengthFrontShift*math.sin(playerangle+math.pi) + vehiclesize[1]*math.sin(playerangle-math.pi/2)

	local vx4 = vx + vehiclesize[2]*lengthBackShift*math.cos(playerangle) + vehiclesize[1]*math.cos(playerangle-math.pi/2)
	local vy4 = vy + vehiclesize[2]*lengthBackShift*math.sin(playerangle) + vehiclesize[1]*math.sin(playerangle-math.pi/2)

	local pos1 = {vx1,vy1}
	local pos2 = {vx2,vy2}
	local pos3 = {vx3,vy3}
	local pos4 = {vx4,vy4}

	local postable = {pos1,pos2,pos3,pos4}

	local maxy = {0,0}
	local maxx = {0,0}
	local miny = {0,99999}
	local minx = {99999,0}

	for i=1,#postable do
		if postable[i][2] >= maxy[2] then
			maxy = {postable[i][1],postable[i][2]}
		end

		if postable[i][1] >= maxx[1] then
			maxx = {postable[i][1],postable[i][2]}
		end

		if postable[i][2] <= miny[2] then
			miny = {postable[i][1],postable[i][2]}
		end

		if postable[i][1] <= minx[1] then
			minx = {postable[i][1],postable[i][2]}
		end
	end

	local a1,b1 = getab(maxy,minx)
	local a2,b2 = getab(maxy,maxx)
	local a3,b3 = getab(maxx,miny)
	local a4,b4 = getab(minx,miny)

	local ismove = false

	if not a1 or not b1 then
		if playerpos[2]<=maxy[2] and playerpos[2]<=miny[2] and playerpos[1] <= maxx[1] and playerpos[1] >= minx[1] then
			ismove = true
		else
			ismove = false
		end
	else
		if playerpos[2]<=playerpos[1]*a1+b1 and playerpos[2] <= playerpos[1]*a2+b2 and playerpos[2] >= playerpos[1]*a3+b3 and playerpos[2] >= playerpos[1]*a4+b4 then
			ismove = true 
		else
			ismove = false
		end
	end

	solidifyRoof()
	
	if ismove then
		playerpospre = {player:getX(),player:getY()}
		if carpospre then
			if carpospre[1] ~= vx or carpospre[2] ~= vy then
				player:setX(player:getX()+vx-carpospre[1])
				player:setY(player:getY()+vy-carpospre[2])
			end
		end
	else
		if isClient() and carpospre and (carpospre[1] ~= vx or carpospre[2] ~= vy) then
			player:setX(vx+heightShift)
			player:setY(vy+heightShift)
		else
			if playerpospre ~= nil then
				player:setX(playerpospre[1])
				player:setY(playerpospre[2])
			else
				local scanStep = 0.1
				local found = false
				local foundX, foundY

				local xMin = math.min(minx[1], maxx[1], miny[1], maxy[1])
				local xMax = math.max(minx[1], maxx[1], miny[1], maxy[1])
				local yMin = math.min(minx[2], maxx[2], miny[2], maxy[2])
				local yMax = math.max(minx[2], maxx[2], miny[2], maxy[2])

				local y = yMin
				while y <= yMax and not found do
					local x = xMin
					while x <= xMax and not found do
						local testPosX = x
						local testPosY = y

						local isNowMove = false
						if not a1 or not b1 then
							if testPosY <= maxy[2] and testPosY <= miny[2] and testPosX <= maxx[1] and testPosX >= minx[1] then
								isNowMove = true
							end
						else
							if testPosY <= testPosX * a1 + b1 and
							testPosY <= testPosX * a2 + b2 and
							testPosY >= testPosX * a3 + b3 and
							testPosY >= testPosX * a4 + b4 then
								isNowMove = true
							end
						end

						if isNowMove then
							player:setX(testPosX + heightShift)
							player:setY(testPosY + heightShift)
							playerpospre = { player:getX(), player:getY() }
							found = true
							foundX, foundY = playerpospre[1], playerpospre[2]
							break
						end
						x = x + scanStep
					end
					y = y + scanStep
				end
				if not found then
					player:setX(vx + heightShift)
					player:setY(vy + heightShift)
				end
			end

		end
	end
	if player:getZ()<=0.9 then
		player:setZ(1.1)
	end
	carpospre = {vx,vy,vz}
end

local function preCheckOnRoof()
	local player = getPlayer()
	if player == nil then return end
	local vehicle = player:getVehicle()
	if vehicle == nil or not VehicleHatches[vehicle:getScript():getFullName()] then return end

	local vx = vehicle:getX()
	local vy = vehicle:getY()
	local vz = vehicle:getZ()

	if isKeyPressed(climbUpHatches:getValue()) then
		if vz > 0.5 then return end
		if vehicle:getSeat(player) ~= player:getModData().saveHatchSeatNumber then return end
		vehicleroof = vehicle
		vehiclesize, lengthBackShift, lengthFrontShift, widthShift, extraTall = getSpecificV(vehicle)
		heightShift = 1.3 + widthShift
		localisSolidRoof()
		if solidRoofCheck == true then return end

		playerpos = {vx,vy,1}
		playerangle=player:getForwardDirection():getDirection()
		vehicle:exit(player)
		solidifyRoof()
		player:setX(vx+heightShift)
		player:setY(vy+heightShift)
		player:setZ(1.1)
		player:getModData().isonHatch = { true, vx, vy, vz, vehiclesize, lengthBackShift, lengthFrontShift, widthShift, extraTall }

		triggerEvent("OnExitVehicle", player)
		Events.OnTick.Remove(preCheckOnRoof)
		Events.OnPlayerUpdate.Add(ifOnRoof)
	end
end

local function preLoadCheckOnRoof(player)
	local vehicle = player:getNearVehicle()
	playerangleOriginal = player:getForwardDirection():getDirection()
	if vehicle == nil or not VehicleHatches[vehicle:getScript():getFullName()] then
		local playerangleSpawnTest = (math.pi*.75)
		player:setTargetAndCurrentDirection(math.cos(playerangleSpawnTest), math.sin(playerangleSpawnTest))
		vehicle = player:getNearVehicle()
		if vehicle == nil or not VehicleHatches[vehicle:getScript():getFullName()] then
			playerangleSpawnTest = (-math.pi*.75)
			player:setTargetAndCurrentDirection(math.cos(playerangleSpawnTest), math.sin(playerangleSpawnTest))
			vehicle = player:getNearVehicle()
			if vehicle == nil or not VehicleHatches[vehicle:getScript():getFullName()] then
				playerangleSpawnTest = (-math.pi*.25)
				player:setTargetAndCurrentDirection(math.cos(playerangleSpawnTest), math.sin(playerangleSpawnTest))
				vehicle = player:getNearVehicle()
				if vehicle == nil or not VehicleHatches[vehicle:getScript():getFullName()] then
					playerangleSpawnTest = (math.pi*.25)
					player:setTargetAndCurrentDirection(math.cos(playerangleSpawnTest), math.sin(playerangleSpawnTest))
					vehicle = player:getNearVehicle()
					if vehicle == nil or not VehicleHatches[vehicle:getScript():getFullName()] then
						carpospre = nil
						playerpospre = nil
						unsolidifyRoof()
						player:getModData().isonVehicleHatches = { false, nil, nil, nil, nil, nil, nil, nil, nil }
						player:setTargetAndCurrentDirection(math.cos(playerangleOriginal), math.sin(playerangleOriginal))
						Events.OnPlayerUpdate.Remove(preLoadCheckOnRoof)
						return
					end
				end
			end
		end
	end
	if vehicle == nil or not VehicleHatches[vehicle:getScript():getFullName()] then
		carpospre = nil
		playerpospre = nil
		unsolidifyRoof()
		player:getModData().isonHatch = { false, nil, nil, nil, nil, nil, nil, nil, nil }
		player:setTargetAndCurrentDirection(math.cos(playerangleOriginal), math.sin(playerangleOriginal))
		Events.OnPlayerUpdate.Remove(preLoadCheckOnRoof)
		return
	end
	vehicleroof = vehicle
	vehiclesize, lengthBackShift, lengthFrontShift, widthShift, extraTall = getSpecificV(vehicle)
	heightShift = 1.3 + widthShift
	localisSolidRoof()
	if solidRoofCheck == true then
		carpospre = nil
		playerpospre = nil
		unsolidifyRoof()
		player:getModData().isonHatch = { false, nil, nil, nil, nil, nil, nil, nil, nil }
		player:setTargetAndCurrentDirection(math.cos(playerangleOriginal), math.sin(playerangleOriginal))
		Events.OnPlayerUpdate.Remove(preLoadCheckOnRoof)
		return
	end

	local vx, vy, vz = player:getModData().isonHatch[2], player:getModData().isonHatch[3], player:getModData().isonHatch[4]

	playerpos = {vx,vy,1}
	vehicle:enter(player:getModData().saveHatchSeatNumber, player)
	vehicle:transmitCharacterPosition(player:getModData().saveHatchSeatNumber, "inside")
	vehicle:playPassengerAnim(player:getModData().saveHatchSeatNumber, "idle")
	playerangle = player:getForwardDirection():getDirection()
	vehicle:exit(player)
	player:setTargetAndCurrentDirection(math.cos(playerangleOriginal), math.sin(playerangleOriginal))
	solidifyRoof()
	player:setX(vx+heightShift)
	player:setY(vy+heightShift)
	player:setZ(1.1)
	player:getModData().isonHatch = { true, vx, vy, vz, vehiclesize, lengthBackShift, lengthFrontShift, widthShift, extraTall }

	Events.OnPlayerUpdate.Add(ifOnRoof)
	Events.OnPlayerUpdate.Remove(preLoadCheckOnRoof)
end

local function checkUpdate(playerIndex, player)
	if player:getModData().isonHatch then
		if player:getModData().isonHatch[1] == true and not getCell():getOrCreateGridSquare(player:getX(), player:getY(), player:getZ()):isSolidFloor() then
			player:setX(player:getX()-(1.3+player:getModData().isonVehicleHatches[8]))
			player:setY(player:getY()-(1.3+player:getModData().isonVehicleHatches[8]))
			player:setZ(0)
			Events.OnPlayerUpdate.Add(preLoadCheckOnRoof)
		end
	end
end

Events.OnCreatePlayer.Add(checkUpdate)

local function OnSwitchVehicleSeatForHatch(player)
	local vehicle = player:getVehicle()
	local seatNumber = vehicle:getSeat(player)
	local fullVName = vehicle:getScript():getFullName()
	player:getModData().saveHatchSeatNumber = nil
	if fordB700buses_87[fullVName] then
		if seatNumber == 3 or seatNumber == 4 or seatNumber == 13 or seatNumber == 14 then
			player:getModData().saveHatchSeatNumber = seatNumber
			Events.OnTick.Add(preCheckOnRoof)
		end
	elseif commando_67hatch[fullVName] then
		if seatNumber == 0 or seatNumber == 1 or seatNumber == 2 or seatNumber == 3 or seatNumber == 4 or seatNumber == 5 then
			player:getModData().saveHatchSeatNumber = seatNumber
			Events.OnTick.Add(preCheckOnRoof)
		end
	elseif oshkoshP19A_86hatch[fullVName] then
		if seatNumber == 3 then
			player:getModData().saveHatchSeatNumber = seatNumber
			Events.OnTick.Add(preCheckOnRoof)
		end
	elseif RangeRoverClassic_91sunroof[fullVName] then
		if seatNumber == 0 or seatNumber == 1 then
			player:getModData().saveHatchSeatNumber = seatNumber
			Events.OnTick.Add(preCheckOnRoof)
		end
	elseif Limo_93sunroof[fullVName] then
		if seatNumber == 5 then
			player:getModData().saveHatchSeatNumber = seatNumber
			Events.OnTick.Add(preCheckOnRoof)
		end
	elseif MercedesBenzW460long_84hatch[fullVName] then
		if seatNumber == 2 or seatNumber == 3 then
			player:getModData().saveHatchSeatNumber = seatNumber
			Events.OnTick.Add(preCheckOnRoof)
		end
	elseif ToyotaMR2_87sunroof[fullVName] then
		if seatNumber == 0 or seatNumber == 1 then
			player:getModData().saveHatchSeatNumber = seatNumber
			Events.OnTick.Add(preCheckOnRoof)
		end
	elseif Nissan240SX_91sunroof[fullVName] then
		if seatNumber == 0 or seatNumber == 1 then
			player:getModData().saveHatchSeatNumber = seatNumber
			Events.OnTick.Add(preCheckOnRoof)
		end
	else
		Events.OnTick.Remove(preCheckOnRoof)
	end
--	print(player:getModData().saveHatchSeatNumber)
end

Events.OnEnterVehicle.Add(OnSwitchVehicleSeatForHatch)
Events.OnSwitchVehicleSeat.Add(OnSwitchVehicleSeatForHatch)

end
Events.OnInitGlobalModData.Add(initClimbVehicles)