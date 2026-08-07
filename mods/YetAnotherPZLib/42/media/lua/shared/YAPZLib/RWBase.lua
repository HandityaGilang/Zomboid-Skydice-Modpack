local __utils = require("YAPZLib/Utils")
local __vehicleUtils = require("YAPZLib/VehicleUtils")

local ISRWBase = ISBaseObject:derive("ISRWBase")

local vehiclesToReload = {}

local setPosition = function(vehicle)
	if not vehicle then return end
	local square = vehicle:getSquare()
	if vehiclesToReload[square] then
		vehicle:setPosition(vehiclesToReload[square].x, vehiclesToReload[square].y, 0.25)
		vehicle:scriptReloaded(false)
		vehiclesToReload[square] = nil
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ISRWBase.getVehicleFromZone = function(zoneName, exclude, fromChances)
	local __types = __utils.checkArgs(
		zoneName, "string", true,
		exclude, "string | list", false,
		fromChances, "boolean", false
	)
	if not __types then return end
	
	local vehicles = VehicleZoneDistribution[zoneName] ~= nil and VehicleZoneDistribution[zoneName].vehicles
	if not vehicles then return end
	
	local exluded = {}
	if exclude then
		if __types[2] == "string" then
			exluded[exclude] = true
		else
			for _, vehicleName in ipairs(exclude) do
				exluded[vehicleName] = true
			end
		end
	end
	
	if not fromChances then
		local vehiclesList = {}
		for vehicleName, _ in pairs(vehicles) do
			if not exluded[vehicleName] then
				table.insert(vehiclesList, vehicleName)
			end
		end
		
		return vehiclesList[ZombRand(#vehiclesList) + 1]
	end

	local totalChance = 0
	for vehicleName, data in pairs(vehicles) do
		if not exluded[vehicleName] then
			totalChance = totalChance + data.spawnChance
		end
	end
	
	local randomChance = ZombRandFloat(0, totalChance)
	local subTotal = 0
	
	for vehicleName, data in pairs(vehicles) do
		if not exluded[vehicleName] then
			subTotal = subTotal + data.spawnChance
			if subTotal > randomChance then
				return vehicleName
			end
		end
	end
	
	return nil
end

ISRWBase.getAllowedTrailerFromZone = function(vehicleName, zoneName, exclude, fromChances)
	local __types = __utils.checkArgs(
		vehicleName, "string", true,
		zoneName, "string", true,
		exclude, "string | list", false,
		fromChances, "boolean", false
	)
	if not __types then return end
	
	local vehicles = VehicleZoneDistribution[zoneName] ~= nil and VehicleZoneDistribution[zoneName].vehicles
	if not vehicles then return end
	
	local exluded = {}
	if exclude then
		if __types[2] == "string" then
			exluded[exclude] = true
		else
			for _, trailerName in ipairs(exclude) do
				exluded[trailerName] = true
			end
		end
	end
	
	local vehiclesList = {}
	
	for trailerName, data in pairs(vehicles) do
		if not exluded[trailerName] then
			if __vehicleUtils.checkTrailerIsAllowed(vehicleName, trailerName) then
				if not fromChances then
					table.insert(vehiclesList, trailerName)
				else
					vehiclesList[trailerName] = data.spawnChance
				end
			end
		end
	end
	
	if not fromChances then
		return vehiclesList[ZombRand(#vehiclesList) + 1]
	else
		local totalChance = 0
		for vehicleName, chance in pairs(vehiclesList) do
			totalChance = totalChance + chance
		end
		
		local randomChance = ZombRandFloat(0, totalChance)
		local subTotal = 0
		
		for vehicleName, chance in pairs(vehiclesList) do
			subTotal = subTotal + chance
			if subTotal > randomChance then
				return vehicleName
			end
		end
	end
	
	return nil
end

ISRWBase.cleanSquareForStory = function(square)
	if not __utils.checkArgs(square, "IsoGridSquare", true) then return end
	
	square:removeBlood(false, false)
	square:removeAllWorldObjects()
	
	for i = square:getObjects():size() - 1, 0, -1 do
		local obj = square:getObjects():get(i)
		if square:getFloor() ~= obj and obj:getSprite() and obj:getSprite():getProperties() and obj:getSprite():getName() then
			square:RemoveTileObject(obj)
		end
	end
	
	for i = square:getSpecialObjects():size() - 1, 0, -1 do
		local obj = square:getSpecialObjects():get(i)
		square:RemoveTileObject(obj)
	end
	
	for i = square:getStaticMovingObjects():size() - 1, 0, -1 do
		local obj = square:getStaticMovingObjects():get(i)
		if instanceof(obj, "IsoDeadBody") then
			square:removeCorpse(obj, false)
		end
	end
	
	square:RecalcProperties()
	square:RecalcAllWithNeighbours(true)
end

ISRWBase.setAttachedItem = function(zombie, location, item)
	if not __utils.checkArgs(
		zombie, "IsoZombie", true,
		location, "string", true,
		item, "string", true
	) then return end
	if item:len() == 0 then return end

	local weapon = instanceItem(item)
	if weapon then
		weapon:setCondition(ZombRand(math.max(2, weapon:getConditionMax() - 5, weapon:getConditionMax())), false)
		if instanceof(weapon, "HandWeapon") then
			weapon:randomizeBullets()
		end
		
		zombie:setAttachedItem(location, weapon)
	end
end

ISRWBase.addItemToSpawnAtDeath = function(zombie, item)
	local __types = __utils.checkArgs(
		zombie, "IsoZombie", true,
		item, "string | list", true
	)
	if not __types then return end

	if __types[3] == "string" and item:len() > 0 then
		zombie:addItemToSpawnAtDeath(instanceItem(item))
	elseif not __utils.tableIsEmpty(item) then
		for _, _item in ipairs(item) do
			if _item:len() > 0 then
				zombie:addItemToSpawnAtDeath(instanceItem(_item))
			end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ISRWBase.derive = function(self, __type)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		__type, "string", true
	) then return end
	
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.Type = __type
	return o
end

ISRWBase.getSquare = function(self, offsetX, offsetY, z)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		offsetX, "number", true,
		offsetY, "number", true,
		z, "number", true
	) then return end
	
	local offsetX, offsetY = self:calcOffset(offsetX, offsetY)
	
	return getCell():getOrCreateGridSquare(self:roundSqCoord(self.spawnPoint.x + offsetX), self:roundSqCoord(self.spawnPoint.y + offsetY), z)
end

ISRWBase.addVehicle = function(self, scriptName, offsetX, offsetY, dirAngle, skinIndex, zoneName, doFlipped)
	local __types = __utils.checkArgs(
		self, "ISRWBase", true,
		scriptName, "string | list", true,
		offsetX, "number", true,
		offsetY, "number", true,
		dirAngle, "number", false,
		skinIndex, "integer | list", false,
		zoneName, "string", false,
		doFlipped, "boolean", false
	)
	if not __types then return end
	
	local name
	if __types[2] == "list" then
		name = scriptName[ZombRand(#scriptName) + 1]
	else
		name = scriptName
	end
	if not name or not ScriptManager.instance:getVehicle(name) then return end
	
	local skin = -1
	if skinIndex then
		if __types[6] == "list" then
			skin = skinIndex[ZombRand(#skinIndex) + 1]
		else
			skin = skinIndex
		end
	end
	
	local x, y = self:calcOffset(offsetX, offsetY)
	x, y = self.spawnPoint.x + x, self.spawnPoint.y + y
	
	local square = getCell():getGridSquare(x, y, self.spawnPoint.z)
	if not square then return end
	
	if isMultiplayer() and isServer() then
		vehiclesToReload[square] = { x = x, y = y}
		Events.OnSpawnVehicleStart.Add(setPosition)
	end
	
	local vehicle = addVehicleDebug(name, IsoDirections.S, nil, square)
	if not vehicle then return end
	
	if zoneName then
		vehicle:setZone(zoneName)
	end
	
	local angle = self:calcAngle(dirAngle)
		
	if angle then
		vehicle:setAngles(vehicle:getAngleX(), angle, vehicle:getAngleZ())
	end
	
	if doFlipped then
		__utils.delay(function(vehicle)
			__vehicleUtils.flip(vehicle)
		end, 1, vehicle)
	end
	
	if skin >= 0 then
		if vehicle:getScript():getSkin(skin) then
			vehicle:setSkinIndex(skin)
		end
	end
	
	if not isMultiplayer() then
		vehicle:setPosition(x, y, 0.25)
		vehicle:scriptReloaded(false)
	else
		Events.OnSpawnVehicleStart.Remove(setPosition)
	end
	
	return vehicle
end

ISRWBase.addTrailer = function(self, scriptName, vehicle, offset, skinIndex)
	__utils.delay(function(self, name, vehicle, offset, skinIndex)
		local __types = __utils.checkArgs(
			self, "ISRWBase", true,
			scriptName, "string | list", true,
			vehicle, "BaseVehicle", true,
			offset, "number", true,
			skinIndex, "integer | table", false
		)
		
		local name
		if __types[2] == "list" then
			name = scriptName[ZombRand(#scriptName) + 1]
		else
			name = scriptName
		end
		if not name or not ScriptManager.instance:getVehicle(name) then return end

		local offsetX = vehicle:getX() - self.spawnPoint.x
		local offsetY = vehicle:getY() - self.spawnPoint.y

		if self.direction == IsoDirections.W or self.direction == IsoDirections.E then
			offsetX = offsetX + offset
		else
			offsetY = offsetY - offset
		end
		
		local zoneName = __vehicleUtils.getVehicleZone(vehicle)
		
		trailer = self:addVehicle(name, offsetX, offsetY, ZombRandFloat(-25, 25), skinIndex, zoneName, false)
		
		if trailer then
			if trailer:getPartById("DAMNSemiTrailerHook") then
				vehicle:positionTrailer(trailer)
				vehicle:breakConstraint(false, false)
				vehicle:addPointConstraint(nil, trailer, "trailerfront", "trailer")
			else
				vehicle:positionTrailer(trailer)
			end
		end
	end, 1, self, name, vehicle, offset, skinIndex)
end

ISRWBase.addZombiesOnVehicle = function(self, vehicle, totalZombies, outfit, femaleChance, doNotSpawnKey)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		vehicle, "BaseVehicle", true,
		totalZombies, "integer", true,
		outfit, "string", true,
		femaleChance, "integer", false,
		doNotSpawnKey, "boolean", false
	) then return end

	local zombies = {}
	local maxTry = 100
	local remainingZombies = totalZombies
	
	while remainingZombies > 0 do
		local tryCount = maxTry
		local spawned = false
		
		while tryCount > 0 do
			local x = vehicle:getX() + ZombRand(-4, 5)
			local y = vehicle:getY() + ZombRand(-4, 5)
			local square = getCell():getGridSquare(x, y, vehicle:getZ())
			
			if square and not square:isVehicleIntersecting() then
				remainingZombies = remainingZombies - 1
				local zombiesArray = addZombiesInOutfit(x, y, vehicle:getZ(), 1, outfit, femaleChance)
				if zombiesArray and zombiesArray:size() > 0 then
					table.insert(zombies, zombiesArray:get(0))
					spawned = true
					break
				end
			end
			
			tryCount = tryCount - 1
		end

		if not spawned then break end
	end
	
	if not doNotSpawnKey and not vehicle:getKeySpawned() and #zombies > 0 and not vehicle:getScript():neverSpawnKey() then
		local zombie = zombies[ZombRand(1, #zombies + 1)]
		zombie:addItemToSpawnAtDeath(vehicle:createVehicleKey())
	end
	
	return zombies
end

ISRWBase.addDeadBody = function(self, offsetX, offsetY, z, outfit, blood, direction, femaleChance, crawlerChance, alignToSquare)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		offsetX, "number", true,
		offsetY, "number", true,
		z, "number", true,
		outfit, "string", false,
		blood, "integer", true,
		direction, "IsoDirections", false,
		femaleChance, "integer", false,
		crawlerChance, "integer", false,
		alignToSquare, "boolean", false
	) then return end
	
	local square = self:getSquare(offsetX, offsetY, z)
	
	if not square:isVehicleIntersecting() then
		return RandomizedWorldBase.createRandomDeadBody(square, direction, alignToSquare, blood, crawlerChance, outfit, femaleChance)
	end
end

ISRWBase.addWorldInventoryItem = function(self, offsetX, offsetY, z, item, x, y, h)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		offsetX, "number", true,
		offsetY, "number", true,
		z, "number", true,
		item, "string", true,
		x, "number", true,
		y, "number", true,
		h, "number", true
	) then return end
	
	local square = self:getSquare(offsetX, offsetY, z)
	
	return square:AddWorldInventoryItem(item, x, y, h)
end

ISRWBase.addBloodSplat = function(self, offsetX, offsetY, z, num)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		offsetX, "number", true,
		offsetY, "number", true,
		z, "number", true,
		num, "integer", true
	) then return end

	local square = self:getSquare(offsetX, offsetY, z)
	
	addBloodSplat(square, num)
end

ISRWBase.addTileObject = function(self, offsetX, offsetY, z, obj, clear, dirt, inputSquare)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		offsetX, "number", true,
		offsetY, "number", true,
		z, "number", true,
		obj, "IsoObject", true,
		clear, "boolean", false,
		dirt, "boolean", false,
		inputSquare, "IsoGridSquare", false
	) then return end

	local square = inputSquare
	if not square then square = self:getSquare(offsetX, offsetY, z) end
	
	if clear then
		ISRWBase.cleanSquareForStory(square)
	end
	
	if dirt then
		square:dirtStamp()
	end
	
	if isMultiplayer() and isServer() then
		square:transmitAddObjectToSquare(obj, -1)
	else
		square:AddTileObject(obj)
	end
	
	MapObjects.newGridSquare(square)
	MapObjects.loadGridSquare(square)
	
	return obj
end

ISRWBase.addTileObjectBySpriteName = function(self, offsetX, offsetY, z, spriteName, clear, dirt)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		offsetX, "number", true,
		offsetY, "number", true,
		z, "number", true,
		spriteName, "string", true,
		clear, "boolean", false,
		dirt, "boolean", false
	) then return end
	
	local square = self:getSquare(offsetX, offsetY, z)
	
	return self:addTileObject(offsetX, offsetY, z, IsoObject.getNew(square, spriteName, nil, false), clear, dirt, square)
end

ISRWBase.addFloor = function(self, offsetX, offsetY, z, spriteName)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		offsetX, "number", true,
		offsetY, "number", true,
		z, "number", true,
		spriteName, "string", true
	) then return end
	
	local square = self:getSquare(offsetX, offsetY, z)
	
	ISRWBase.cleanSquareForStory(square)
	
	local _floor = square:addFloor(spriteName)
	
	MapObjects.newGridSquare(square)
	MapObjects.loadGridSquare(square)
	
	return _floor
end

ISRWBase.isTimeValid = function(self)
	if not __utils.checkArgs(self, "ISRWBase", true) then return end
	
	if not self.minDays then self.minDays = 0 end
	if not self.maxDays then self.maxDays = 0 end
	if self.minDays == 0 and self.maxDays == 0 then
		return true
	else
		local days = getWorld():getWorldAgeDays()
		if self.minDays > 0 and days < self.minDays then
			return false
		else
			return self.maxDays <= 0 or not (days > self.maxDays)
		end
	end
end

ISRWBase.calcAngle = function(self, angle)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		angle, "number", true
	) then return end
	
	if self.direction == IsoDirections.W or self.direction == IsoDirections.E then
		if self.direction == IsoDirections.W then
			angle = __utils.invertAngle(angle)
		end
		
		return angle - 90
	else
		if self.direction == IsoDirections.N then
			angle = __utils.invertAngle(angle)
		end
		
		return angle
	end
	
	return 0
end

ISRWBase.calcOffset = function(self, offsetX, offsetY)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		offsetX, "number", true,
		offsetY, "number", true
	) then return end
	
	if self.direction == IsoDirections.N then
		return offsetX, -offsetY
	elseif self.direction == IsoDirections.S then
		return -offsetX, offsetY
	elseif self.direction == IsoDirections.E then
		return -offsetY, -offsetX
	elseif self.direction == IsoDirections.W then
		return offsetY, offsetX
	end

	return 0, 0
end

ISRWBase.roundSqCoord = function(self, coord)
	if not __utils.checkArgs(
		self, "ISRWBase", true,
		coord, "number", true
	) then return end

	if self.direction == IsoDirections.E or self.direction == IsoDirections.S then
		return round(coord, 0) - 1
	end
	
	return round(coord, 0)
end

return ISRWBase