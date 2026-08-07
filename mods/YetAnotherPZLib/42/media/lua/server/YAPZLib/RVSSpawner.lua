local ISRVSBase = require("YAPZLib/RVSBase")

local checkStorySpawnLater = function(chunk)
	local squares = chunk:getSquaresForLevel(0)
	if not squares then return end
	for i = 1, #squares do
		local square = squares[i]
		if square then
			if square:getModData().vehicleStory then
				local story = ISRVSBase.createStoryFromTable(square:getModData().vehicleStory)
				if story then
					ISRVSBase.addToProcessList(story)
					return true
				end
			end
		end
	end
	
	return false
end

local spawnRVS = function(chunk)
	if isMultiplayer() and not isServer() then return end
	if not chunk or checkStorySpawnLater(chunk) or not chunk:isNewChunk() then return end
	local story = ISRVSBase.getRandomStory()
	if not story or not story:isTimeValid() then return end
	local zone = story:getValidZone(chunk, false)
	if zone then
		local chance = ISRVSBase.getVehicleStoriesChance()
		if chance and ZombRand(chance) <= 25 then
			ISRVSBase.doStory(story, chunk, zone, false)
		end
	end
end

Events.LoadChunk.Add(spawnRVS)
Events.OnLoadMapZones.Add(ISRVSBase.initTotalChance)
Events.OnInitGlobalModData.Add(ISRVSBase.initVehicleStoriesChance)