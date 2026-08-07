local __utils = require("YAPZLib/Utils")
local ISRWBase = require("YAPZLib/RWBase")

local ISRVSBase = ISRWBase:derive("ISRVSBase")

local storiesList = {}
local totalChance = 0
local storiesChance = 1000

local processList = {}
local attempts = {}
local processing = false

local function processStories()
	for i = #processList, 1, -1 do
		local ready = true
		local story = processList[i]
		local spawnSquareData = getCell():getOrCreateGridSquare(story.spawnPoint.x, story.spawnPoint.y, story.spawnPoint.z):getModData()
		if not spawnSquareData.vehicleStory then spawnSquareData.vehicleStory = story end
		if not attempts[story] then attempts[story] = 0 end
		
		if type(attempts[story]) == "number" and attempts[story] >= 500 then
			ready = false
			attempts[story] = nil
			table.remove(processList, i)
		end
		
		if ready then
			if type(attempts[story]) == "number" then attempts[story] = attempts[story] + 1 end
			
			for sx = -story.minZoneWidth, story.minZoneWidth do
				for sy = -story.minZoneHeight, story.minZoneHeight do
					ox, oy = story:calcOffset(sx, sy)
					x, y = story.spawnPoint.x + ox, story.spawnPoint.y + oy
				
					local square = getCell():getGridSquare(x, y, story.spawnPoint.z)
					if not square or not square:getChunk() then
						ready = false
						break
					elseif square:getVehicleContainer() then
						ready = false
						attempts[story] = nil
						table.remove(processList, i)
						spawnSquareData.vehicleStory = nil
						break
					end
				end
				
				if not ready then break end
			end
		end
		
		if ready then
			if attempts[story] == "spawning" then
				story:spawn()
				attempts[story] = nil
				table.remove(processList, i)
				spawnSquareData.vehicleStory = nil
			else
				__utils.delay(processStories, 5)
				attempts[story] = "spawning"
			end
		end
	end
	
	if #processList == 0 then
		processing = false
		Events.OnTick.Remove(processStories)
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ISRVSBase.initTotalChance = function()
	for i = #storiesList, 1, -1 do
		local story = __utils.getGlobalObject(storiesList[i])
		if story then
			totalChance = totalChance + story.chance
		end
	end
	
	if totalChance < 100 then totalChance = 100 end
	
	table.sort(storiesList, function(a, b)
		local story1 = __utils.getGlobalObject(a)
		local story2 = __utils.getGlobalObject(b)
		return story1.chance > story2.chance 
	end)
end

ISRVSBase.initVehicleStoriesChance = function()
	local option = getSandboxOptions():getOptionByName("VehicleStoryChance"):getValue()
	if option == 1 then
		storiesChance = false
	elseif option == 2 then
		storiesChance = 2000
	elseif option == 4 then
		storiesChance = 600
	elseif option == 5 then
		storiesChance = 350
	elseif option == 6 then
		storiesChance = 100
	elseif option == 7 then
		storiesChance = 0
	end
end

ISRVSBase.getVehicleStoriesChance = function()
	return storiesChance
end

ISRVSBase.getVehicleStoriesList = function()
	return storiesList
end

ISRVSBase.getRandomStory = function()
	local randomChance = ZombRand(totalChance)
	local subTotal = 0
	local choice
	
	for _, __type in ipairs(storiesList) do
		local story = __utils.getGlobalObject(__type):new()
		if story then
			subTotal = subTotal + story.chance
			if subTotal > randomChance then
				choice = story
				break
			end
		end
	end
	
	return choice
end

ISRVSBase.createStoryFromTable = function(tab)
	if not __utils.checkArgs(tab, "table", true) then return end

	local o = {}
	local storyTab = __utils.getGlobalObject(tab.Type)
	setmetatable(o, storyTab)
	storyTab.__index = storyTab
	
	for k, v in pairs(tab) do
		o[k] = v
	end

	return o
end

ISRVSBase.doStory = function(story, chunk, zone, force)
	if not __utils.checkArgs(
		story, "ISRVSBase", true,
		chunk, "IsoChunk", true,
		zone, "Zone", false,
		force, "boolean", false
	) then return end
	
	local zone = zone
	if not zone then
		zone = story:getValidZone(chunk, force)
	end
	
	if zone then
		local spawnPoint, direction = story:getSpawnPoint(zone, chunk)
		if spawnPoint and direction then
			story.spawnPoint = spawnPoint
			story.direction = direction
			ISRVSBase.addToProcessList(story)
		end
	end
end

ISRVSBase.addToProcessList = function(story)
	if not __utils.checkArgs(story, "ISRVSBase", true) then return end
	
	local add = true
	
	for _, pstory in ipairs(processList) do
		if pstory == story then
			add = false
			break
		end
	end
	
	if add then
		table.insert(processList, story)
	end
	
	if not processing then
		Events.OnTick.Add(processStories)
		processing = true
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ISRVSBase.derive = function(self, __type)
	if not __utils.checkArgs(
		self, "ISRVSBase", true,
		__type, "string", true
	) then return end
	
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.Type = __type
	table.insert(storiesList, __type)
	return o
end

ISRVSBase.new = function(self)
	if not __utils.checkArgs(self, "ISRVSBase", true) then return end

	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.Type = self.Type
	o.spawnPoint = false
	o.direction = false
	return o
end

ISRVSBase.getSpawnPoint = function(self, zone, chunk)
	if not __utils.checkArgs(
		self, "ISRVSBase", true,
		chunk, "IsoChunk", true,
		zone, "Zone", true
	) then return end
	
	local clamp = function(value, min, max)
		if value < min then return min end
		if value > max then return max end
		return value
	end
	
	local mzw = self.minZoneWidth
	local mzh = self.minZoneHeight
	
	local squares = chunk:getSquaresForLevel(0)
	if not squares or #squares == 0 then return false end
	
	local validPoints = {}
	local processed = {}
	
	for i = 1, #squares do
		local sq = squares[i]
		if sq and sq:getZone() == zone then
			if zone:isRectangle() and not processed[zone:toString()] then
				processed[zone:toString()] = true
				
				local zw = zone:getWidth()
				local zh = zone:getHeight()
				local zx = zone:getX()
				local zy = zone:getY()
				
				if zw > 30 and zh < 15 then
					self.zoneWidth = zh
					if zw >= mzh and zh >= mzw then
						table.insert(validPoints, { coordinates = { x = clamp(sq:getX(), zx + mzh / 2, zx + zw - mzh / 2), y = zy + zh / 2, z = 0 }, dir = Vector2.getDirection(zw, 0) })
					end
				elseif zh > 30 and zw < 15 then
					self.zoneWidth = zw
					if zw >= mzw and zh >= mzh then
						table.insert(validPoints, { coordinates = { x = zx + zw / 2, y = clamp(sq:getY(), zy + mzh / 2, zy + zh - mzh / 2), z = 0 }, dir = Vector2.getDirection(0, -zh) })
					end
				end
			end
		end
	end
	
	if #validPoints == 0 then return false end
	
	local spawnPoint = validPoints[ZombRand(#validPoints) + 1]
	local dir = (ZombRand(2) == 0) and spawnPoint.dir or (spawnPoint.dir + math.pi)
	
	return spawnPoint.coordinates, IsoDirections.cardinalFromAngle(dir)
end

ISRVSBase.getValidZone = function(self, chunk, force)
	if not __utils.checkArgs(
		self, "ISRVSBase", true,
		chunk, "IsoChunk", true,
		force, "boolean", false
	) then return end

	local squares = chunk:getSquaresForLevel(0)
	if not squares then return false end

	local processed = {}

	for i = 1, #squares do
		local square = squares[i]
		if square then
			local zone = square:getZone()

			if zone and zone:getType() == "Nav" and not processed[zone:toString()] then
				processed[zone:toString()] = true

				local skip = false

				if not force then
					if zone:getLastActionTimestamp() > 0 then skip = true end
					if not skip then zone:setLastActionTimestamp(zone:getLastActionTimestamp() + 1) end
					if zone:haveCons() then skip = true end
				end

				if not skip then
					for j = 1, #squares do
						local sq = squares[j]
						if sq and sq:getZone() == zone then
							if sq:isWaterSquare() then
								skip = true
								break
							end
							
							if sq:isVehicleIntersecting() then
								skip = true
								break
							end
						end
					end
				end

				local validRoad = false

				if not skip then
					for j = 1, #squares do
						local sq = squares[j]
						if sq and sq:getZone() == zone then
							local floor = sq:getFloor()
							if floor then
								local props = floor:getProperties()
								if props and props:has("FootstepMaterial") then
									local mat = props:get("FootstepMaterial")
									if mat == "Gravel" or mat == "Sand" then
										validRoad = true
										break
									end
								end
								local sprite = floor:getSprite()
								if sprite and sprite:getName():find("street") then
									validRoad = true
									break
								end
							end
						end
					end
					if not validRoad then
						skip = true
					end
				end

				if not skip then
					local floor = square:getFloor()
					if not floor then
						skip = true
					else
						local name = floor:getSprite():getName()
						if self.needsPavement then
							if not name:find("blends_street") or name:find("blends_street_01_16") or name:find("blends_street_01_21") or name:find("blends_street_01_48") or name:find("blends_street_01_53") or name:find("blends_street_01_54") or name:find("blends_street_01_55") then
								skip = true
							end
						end
						if self.needsDirt then
							if name:find("blends_street") and not name:find("blends_street_01_16") and not name:find("blends_street_01_21") and not name:find("blends_street_01_48") and not name:find("blends_street_01_53") and not name:find("blends_street_01_54") and not name:find("blends_street_01_55") then
								skip = true
							end
						end
					end
				end

				if not skip and self.needsRegion then
					local region = square:getSquareRegion()
					if region == "General" then
						skip = true
					end
				end

				if not skip and (self.needsFarmland or self.needsRuralVegetation or self.notTown) then
					local x = square:getX()
					local y = square:getY()
					local foundFarm = false
					local foundNature = false
					local foundTown = false
					for dx = -15, 15 do
						for dy = -15, 15 do
							local sq = getCell():getGridSquare(x + dx * 10, y + dy * 10, 0)
							local zt = sq:getZoneType()

							if zt then
								if zt == "Farm" or zt == "FarmLand" or zt == "Ranch" then
									foundFarm = true
								end

								if zt == "Forest" or zt == "DeepForest" then
									foundNature = true
								end

								if zt == "TownZone" or zt == "TrailerPark" then
									foundTown = true
								end
							end
						end
					end

					if self.needsFarmland and not foundFarm then
						skip = true
					end

					if self.needsRuralVegetation and not (foundFarm or foundNature) then
						skip = true
					end

					if self.notTown and foundTown then
						skip = true
					end
				end

				if not skip then
					return zone
				end
			end
		end
	end
	
	return false
end

ISRVSBase.spawn = function(self)
	if not __utils.checkArgs(self, "ISRVSBase", true) then return end
	__utils.debugLog("Missing spawn function for "..self.name.." road story.")
end

return ISRVSBase