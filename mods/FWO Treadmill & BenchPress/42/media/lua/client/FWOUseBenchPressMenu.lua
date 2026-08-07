--[[
		Developed by Codename280
		Working Bench press 41.78+
]]

FWOUseBenchPressMenu = {};
FWOUseBenchPressMenu.doBuildMenu = function(player, context, worldobjects)

	local benchObject = nil
	local benchGroupName = nil

	for _,object in ipairs(worldobjects) do
		local square = object:getSquare()
		if not square then
			return
		end
		
		for i=1,square:getObjects():size() do
			local thisObject = square:getObjects():get(i-1)
			
			if thisObject:getSprite() then
				local properties = thisObject:getSprite():getProperties()
				if properties == nil then
					return
				end
				
				local groupName =  nil;
				local CustomName =  nil;
		
				if properties:Is("GroupName") then
					groupName = properties:Val("GroupName")
				end
				
				local customName = nil
				if properties:Is("CustomName") then
					customName = properties:Val("CustomName")
				end
				
				
				if customName == "Contraption" then				
					benchObject = thisObject
					FWOObject = thisObject
					benchGroupName = groupName
					break
				end
				
			end 
		end 
	end

	if not benchObject then 
		return 
	end
	
	local contextMenu = nil
	local actionType = nil
	
	if benchGroupName == "Fitness" then
		local spriteName = benchObject:getSprite():getName()
	
	
		if (spriteName == "recreational_sports_01_45") or (spriteName == "recreational_sports_01_40") or (spriteName == "recreational_sports_01_43") or (spriteName == "recreational_sports_01_46") then
			--print("Ignore half Bench")
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
	
	if properties:Is("Facing") then
		facing = properties:Val("Facing")
	end
	return facing
end

function FWOUseBenchPressMenu.walkToFront(thisPlayer, benchObject)

	local controllerSquare = nil
	local spriteName = benchObject:getSprite():getName()
	if not spriteName then
		return false
	end

	local properties = benchObject:getSprite():getProperties()
	local facing = FWOUseBenchPressMenu.getFacing(properties)
	if facing == nil then
		return false
	end
	

	local frontSquare = FWOUseBenchPressMenu.getFrontSquare(benchObject:getSquare(), facing)
    -- BUG catch for 42.9.0 
	if frontSquare == nil then
		thisPlayer:Say("Bug: please rotate and/or move the bench ! 42.9.0")	
		return 
	end
	local turn = FWOUseBenchPressMenu.getFrontSquare(frontSquare, facing)
	--print("turn",turn)
	
	if not frontSquare then
		return false
	end
	if not controllerSquare then
		controllerSquare = benchObject:getSquare()
	end
	if AdjacentFreeTileFinder.privTrySquare(controllerSquare, frontSquare) then
		ISTimedActionQueue.add(ISWalkToTimedAction:new(thisPlayer, frontSquare))
		thisPlayer:faceLocation(turn:getX(), turn:getY())
		return true
	end
	return false
end


function FWOUseBenchPressMenu.onUseBench(worldobjects, player, machine, actionType, length)
	if not player:getInventory():contains("Base.BarBell", true) and not player:getInventory():contains("Base.BarBell_Forged", true) then
		player:Say(getText("IGUI_need_barbell"))
		return
	end
	if player:getMoodles():getMoodleLevel(MoodleType.Endurance) > 2 then
		player:Say(getText("IGUI_low_endurance"))
		return
	end
	if player:getMoodles():getMoodleLevel(MoodleType.Pain) > 3 then
		player:Say(getText("IGUI_pain"))
		return
	end
	if player:getMoodles():getMoodleLevel(MoodleType.HeavyLoad) > 2 then
		player:Say(getText("IGUI_heavy"))
		return
	end
	if FWOUseBenchPressMenu.walkToFront(player, machine) then
	
		forceDropHeavyItems(player)
		
		
		if not SandboxVars.FWOWorkingTreadmill.BenchTreadKeepBagsOn then
			for i=0,player:getWornItems():size()-1 do
				local item = player:getWornItems():get(i):getItem();
				if item and instanceof(item, "InventoryContainer") then
					ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50));
					if SandboxVars.FWOWorkingTreadmill.BenchpressDropBags then
						ISTimedActionQueue.add(ISDropItemAction:new(player, item, 50));
					end
				end
			end
		end
		
			
		if player:getInventory():contains("Base.BarBell", true) then
			ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), "Base.BarBell", true, true);
		end			
		if player:getInventory():contains("Base.BarBell_Forged", true) then
			ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), "BarBell_Forged", true, true);
		end

		ISTimedActionQueue.add(ISFitnessAction:new(player, actionType, length , ISFitnessUI:new(0,0, 600, 350, player) , FitnessExercises.exercisesType.benchpress.type ))
	end
end

Events.OnPreFillWorldObjectContextMenu.Add(FWOUseBenchPressMenu.doBuildMenu);
