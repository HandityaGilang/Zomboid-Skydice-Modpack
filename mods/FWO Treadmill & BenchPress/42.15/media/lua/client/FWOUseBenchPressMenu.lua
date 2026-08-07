--[[
    FWO Working Bench Press - Context Menu
    Version: 42.15.3

    Adds benchpress exercise option to context menu
]]

local FWOUseBenchPressMenu = {}

FWOUseBenchPressMenu.doBuildMenu = function(player, context, worldobjects)
	local benchObject = nil
	local benchGroupName = nil

	-- Check if an object is a bench (skip walkable floor tiles)
	local function isBench(obj)
		if not obj or not obj.getSprite then return false end
		local sprite = obj:getSprite()
		if not sprite then return false end
		local spriteName = sprite:getName()
		-- Skip walkable floor tiles (you stand ON these, not interact with them)
		if spriteName and (spriteName == "recreational_sports_01_45" or spriteName == "recreational_sports_01_40" or spriteName == "recreational_sports_01_43" or spriteName == "recreational_sports_01_46") then
			return false
		end
		local props = sprite:getProperties()
		if not props or not props:has("CustomName") then return false end
		if props:get("CustomName") ~= "Contraption" then return false end
		benchObject = obj
		FWOObject = obj
		if props:has("GroupName") then benchGroupName = props:get("GroupName") end
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

	-- Search a square for a bench
	local function searchSquare(sq)
		if not sq then return false end
		local objLists = { sq:getObjects(), sq:getStaticMovingObjects(), sq:getMovingObjects(), sq:getSpecialObjects() }
		for _,objList in ipairs(objLists) do
			if objList then
				for i=1,objList:size() do
					if isBench(objList:get(i-1)) then return true end
				end
			end
		end
		return false
	end

	-- Check worldobjects directly
	for _,object in ipairs(worldobjects) do
		if isBench(object) then return end
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
		if benchObject then break end
	end

	if not benchObject then return end

	local contextMenu = nil
	local actionType = nil

	if benchGroupName == "Fitness" then
		local spriteName = benchObject:getSprite():getName()
		if (spriteName == "recreational_sports_01_45") or (spriteName == "recreational_sports_01_40") or (spriteName == "recreational_sports_01_43") or (spriteName == "recreational_sports_01_46") then
			return
		end

		contextMenu = getText("IGUI_BenchPress_Tooltip") .. " ("..math.floor(getSpecificPlayer(player):getFitness():getRegularity("benchpress"))..")"
		actionType = "benchpress"
	else
		return
	end

	context:addOption(getText(contextMenu),
					  worldobjects,
					  FWOUseBenchPressMenu.onUseBench,
					  getSpecificPlayer(player),
					  benchObject,
					  actionType,
					  5760)
end

FWOUseBenchPressMenu.getFrontSquare = function(square, facing)
	local value = nil

	if facing == "S" then
		value = square:getS()
	elseif facing == "E" then
		value = square:getE()
	elseif facing == "W" then
		value = square:getW()
	elseif facing == "N" then
		value = square:getN()
	end

	return value
end

FWOUseBenchPressMenu.getFacing = function(properties)
	local facing = nil

	if properties:has("Facing") then
		facing = properties:get("Facing")
	end
	return facing
end

FWOUseBenchPressMenu.walkToFront = function(thisPlayer, benchObject)
	local spriteName = benchObject:getSprite():getName()
	if not spriteName then return false end

	local properties = benchObject:getSprite():getProperties()
	local facing = FWOUseBenchPressMenu.getFacing(properties)
	if not facing then return false end

	local frontSquare = FWOUseBenchPressMenu.getFrontSquare(benchObject:getSquare(), facing)
	if not frontSquare then
		thisPlayer:Say("Bug: please rotate and/or move the bench!")
		return false
	end

	-- If player is already on the front square, just set direction
	local playerSquare = thisPlayer:getCurrentSquare()
	if playerSquare and playerSquare == frontSquare then
		if FWOObjectFacing then thisPlayer:setDir(FWOObjectFacing) end
		return true
	end

	-- Walk to the front square
	if AdjacentFreeTileFinder.privTrySquare(benchObject:getSquare(), frontSquare) then
		ISTimedActionQueue.add(ISWalkToTimedAction:new(thisPlayer, frontSquare))
		return true
	end
	return false
end

FWOUseBenchPressMenu.onUseBench = function(worldobjects, player, machine, actionType, length)
	if not player:getInventory():contains("Base.BarBell", true) and not player:getInventory():contains("Base.BarBell_Forged", true) then
		player:Say(getText("IGUI_need_barbell"))
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
	if FWOUseBenchPressMenu.walkToFront(player, machine) then
		forceDropHeavyItems(player)

		if not SandboxVars.FWOWorkingTreadmill.BenchTreadKeepBagsOn then
			for i=0,player:getWornItems():size()-1 do
				local item = player:getWornItems():get(i):getItem()
				if item and instanceof(item, "InventoryContainer") then
					ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
					if SandboxVars.FWOWorkingTreadmill.BenchpressDropBags then
						ISTimedActionQueue.add(ISDropItemAction:new(player, item, 50))
					end
				end
			end
		end

		if player:getInventory():contains("Base.BarBell", true) then
			ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), "Base.BarBell", true, true)
		end
		if player:getInventory():contains("Base.BarBell_Forged", true) then
			ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), "BarBell_Forged", true, true)
		end

		local fitnessAction = ISFitnessAction:new(player, actionType, length, ISFitnessUI:new(0,0, 600, 350, player), FitnessExercises.exercisesType.benchpress.type)
		if FWOObjectFacing then
			fitnessAction.FWOObjectFacing = FWOObjectFacing
		end
		fitnessAction.FWOObject = machine
		ISTimedActionQueue.add(fitnessAction)
	end
end

Events.OnPreFillWorldObjectContextMenu.Add(FWOUseBenchPressMenu.doBuildMenu)
