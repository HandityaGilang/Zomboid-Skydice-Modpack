--[[
    FWO Working Treadmill - Context Menu
    Version: 42.15.3

    Adds treadmill exercise option to context menu
]]

local FWOWorkingTreadmillMenu = {}

FWOWorkingTreadmillMenu.doBuildMenu = function(player, context, worldobjects)
	local treadmillObject = nil
	local treadmillGroupName = nil

	-- Check if an object is a treadmill (skip walkable floor tiles)
	local function isTreadmill(obj)
		if not obj or not obj.getSprite then return false end
		local sprite = obj:getSprite()
		if not sprite then return false end
		local spriteName = sprite:getName()
		-- Skip walkable floor tiles (you stand ON these, not interact with them)
		if spriteName and (spriteName == "recreational_sports_01_28" or spriteName == "recreational_sports_01_31" or spriteName == "recreational_sports_01_37" or spriteName == "recreational_sports_01_38") then
			return false
		end
		local props = sprite:getProperties()
		if not props or not props:has("CustomName") then return false end
		if props:get("CustomName") ~= "Hamster Wheel" then return false end
		treadmillObject = obj
		FWOObject = obj
		if props:has("GroupName") then treadmillGroupName = props:get("GroupName") end
		if props:has("Facing") then
			local f = props:get("Facing")
			if f == "N" then FWOObjectFacing = IsoDirections.S
			elseif f == "E" then FWOObjectFacing = IsoDirections.W
			elseif f == "S" then FWOObjectFacing = IsoDirections.N
			elseif f == "W" then FWOObjectFacing = IsoDirections.E
			end
		end
		return true
	end

	-- Search a square for a treadmill
	local function searchSquare(sq)
		if not sq then return false end
		local objLists = { sq:getObjects(), sq:getStaticMovingObjects(), sq:getMovingObjects(), sq:getSpecialObjects() }
		for _,objList in ipairs(objLists) do
			if objList then
				for i=1,objList:size() do
					if isTreadmill(objList:get(i-1)) then return true end
				end
			end
		end
		return false
	end

	-- Check worldobjects directly
	for _,object in ipairs(worldobjects) do
		if isTreadmill(object) then return end
	end

	-- Check clicked square and its 4 adjacent squares (5 total)
	local squaresToCheck = {}
	local seen = {}
	for _,object in ipairs(worldobjects) do
		local sq = object:getSquare()
		if sq then
			local key = sq:getX()..","..sq:getY()..","..sq:getZ()
			if not seen[key] then
				seen[key] = true
				table.insert(squaresToCheck, sq)
				local dirs = { IsoDirections.N, IsoDirections.S, IsoDirections.W, IsoDirections.E }
				for _,d in ipairs(dirs) do
					local adj = sq:getAdjacentSquare(d)
					if adj then
						local akey = adj:getX()..","..adj:getY()..","..adj:getZ()
						if not seen[akey] then
							seen[akey] = true
							table.insert(squaresToCheck, adj)
						end
					end
				end
			end
		end
	end

	for _,checkSq in ipairs(squaresToCheck) do
		searchSquare(checkSq)
		if treadmillObject then break end
	end

	if not treadmillObject then return end

	local contextMenu = nil
	local actionType = nil

	if treadmillGroupName == "Human" then
		contextMenu = getText("IGUI_Treadmill_Tooltip") .. " ("..math.floor(getSpecificPlayer(player):getFitness():getRegularity("treadmill"))..")"
		actionType = "treadmill"
	else
		return
	end

	context:addOption(getText(contextMenu),
					  worldobjects,
					  FWOWorkingTreadmillMenu.onUseTreadmill,
					  getSpecificPlayer(player),
					  treadmillObject,
					  actionType,
					  5760)
end

FWOWorkingTreadmillMenu.walkToFront = function(thisPlayer, treadmillObject)
	local frontSquare = nil
	local spriteName = treadmillObject:getSprite():getName()
	if not spriteName then return false end

	local properties = treadmillObject:getSprite():getProperties()
	local facing = properties:has("Facing") and properties:get("Facing") or nil
	if not facing then return false end

	if facing == "S" then
		frontSquare = treadmillObject:getSquare():getS()
	elseif facing == "E" then
		frontSquare = treadmillObject:getSquare():getE()
	elseif facing == "W" then
		frontSquare = treadmillObject:getSquare():getW()
	elseif facing == "N" then
		frontSquare = treadmillObject:getSquare():getN()
	end

	if not frontSquare then return false end

	-- If player is already on the front square, just set direction
	local playerSquare = thisPlayer:getCurrentSquare()
	if playerSquare and playerSquare == frontSquare then
		thisPlayer:setDir(FWOObjectFacing)
		return true
	end

	-- Walk to the front square
	if AdjacentFreeTileFinder.privTrySquare(treadmillObject:getSquare(), frontSquare) then
		ISTimedActionQueue.add(ISWalkToTimedAction:new(thisPlayer, frontSquare))
		return true
	end
	return false
end

FWOWorkingTreadmillMenu.onUseTreadmill = function(worldobjects, player, machine, actionType, length)
	if not ((SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier) or machine:getSquare():haveElectricity()) then
		player:Say("The treadmill needs electricity to run")
		return
	end
	if player:getMoodles():getMoodleLevel(MoodleType.ENDURANCE) > 2 then
		player:Say(getText("IGUI_low_endurance"))
		return
	end
	if player:getMoodles():getMoodleLevel(MoodleType.PAIN) > 3 then
		player:Say(getText("IGUI_pain"))
		return
	end
	if player:getMoodles():getMoodleLevel(MoodleType.HEAVY_LOAD) > 2 then
		player:Say(getText("IGUI_heavy"))
		return
	end
	if FWOWorkingTreadmillMenu.walkToFront(player, machine) then
		forceDropHeavyItems(player)
		player:setPrimaryHandItem(nil)
		player:setSecondaryHandItem(nil)

		if not SandboxVars.FWOWorkingTreadmill.BenchTreadKeepBagsOn then
			for i=0,player:getWornItems():size()-1 do
				local item = player:getWornItems():get(i):getItem()
				if item and instanceof(item, "InventoryContainer") then
					ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
					if SandboxVars.FWOWorkingTreadmill.TreadmillDropBags then
						ISTimedActionQueue.add(ISDropItemAction:new(player, item, 50))
					end
				end
			end
		end

		local fitnessAction = ISFitnessAction:new(player, actionType, length, ISFitnessUI:new(0,0, 600, 350, player), FitnessExercises.exercisesType.treadmill.type)
		if FWOObjectFacing then
			fitnessAction.FWOObjectFacing = FWOObjectFacing
		end
		fitnessAction.FWOObject = machine
		ISTimedActionQueue.add(fitnessAction)
	end
end

Events.OnPreFillWorldObjectContextMenu.Add(FWOWorkingTreadmillMenu.doBuildMenu)
