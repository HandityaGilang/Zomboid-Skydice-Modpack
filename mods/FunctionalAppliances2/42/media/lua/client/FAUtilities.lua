FA = FA or {}

FA.translation = {
	sayoptionunavailable = getText("UI_FunctionalAppliances_sayoptionunavailable"),
	sayneedagenerator = getText("UI_FunctionalAppliances_sayneedagenerator"),
	sayneedstobeturnedon = getText("UI_FunctionalAppliances_sayneedstobeturnedon"),

	sayneedmissingingredients = getText("UI_FunctionalAppliances_sayneedmissingingredients"),

	saysodafountainmustbeinside = getText("UI_FunctionalAppliances_saysodafountainmustbeinside"),
	noco2tankconnected = getText("UI_FunctionalAppliances_noco2tankconnected"),
	nosyrupboxesconnected = getText("UI_FunctionalAppliances_nosyrupboxesconnected"),
	nowaterconnected = getText("UI_FunctionalAppliances_nowaterconnected"),

	dispensefrom = getText("UI_FunctionalAppliances_dispensefrom"),
	saybartapnotconnected = getText("UI_FunctionalAppliances_saybartapnotconnected"),
	saybartapconnectedtoemptykeg = getText("UI_FunctionalAppliances_saybartapconnectedtoemptykeg"),

	currentlyoffsettowarm = getText("UI_FunctionalAppliances_currentlyoffsettowarm"),
	currentlyoffsettohot = getText("UI_FunctionalAppliances_currentlyoffsettohot"),
	currentlyoffsettocold = getText("UI_FunctionalAppliances_currentlyoffsettocold"),
	currentlywarmsettooff = getText("UI_FunctionalAppliances_currentlywarmsettooff"),
	currentlywarmsettohot = getText("UI_FunctionalAppliances_currentlywarmsettohot"),
	currentlywarmsettocold = getText("UI_FunctionalAppliances_currentlywarmsettocold"),
	currentlyhotsettooff = getText("UI_FunctionalAppliances_currentlyhotsettooff"),
	currentlyhotsettowarm = getText("UI_FunctionalAppliances_currentlyhotsettowarm"),
	currentlyhotsettocold = getText("UI_FunctionalAppliances_currentlyhotsettocold"),
	currentlycoldsettooff = getText("UI_FunctionalAppliances_currentlycoldsettooff"),
	currentlycoldsettowarm = getText("UI_FunctionalAppliances_currentlycoldsettowarm"),
	currentlycoldsettohot = getText("UI_FunctionalAppliances_currentlycoldsettohot"),

	makehotdog = getText("UI_FunctionalAppliances_makehotdog"),
	cook = getText("UI_FunctionalAppliances_cook"),
	sausage = getText("UI_FunctionalAppliances_sausage"),
	hotdogwiener = getText("UI_FunctionalAppliances_hotdogwiener"),
	hotdogbun = getText("UI_FunctionalAppliances_hotdogbun"),
	slicedbread = getText("UI_FunctionalAppliances_slicedbread"),

	usepopcornmachine = getText("UI_FunctionalAppliances_usepopcornmachine"),
	sayneedcanopener = getText("UI_FunctionalAppliances_sayneedcanopener"),
	sayneedpopcornkernels = getText("UI_FunctionalAppliances_sayneedpopcornkernels"),

	dryself = getText("UI_FunctionalAppliances_dryself"),
	washself = getText("UI_FunctionalAppliances_washself"),

	thecurrenttimeis = getText("UI_FunctionalAppliances_thecurrenttimeis"),
	replacedeadbattery = getText("UI_FunctionalAppliances_replacedeadbattery"),
	sayneedabattery = getText("UI_FunctionalAppliances_sayneedabattery"),

}

FA.getJoypadData = function(playerIndex)
    	if not playerIndex then 
		playerIndex = 0 
	end

	return JoypadState.players[playerIndex + 1]
end

FA.getFrontSquare = function(square, facing)
	local frontSquare = nil
	
	-- Note that when the square is blocked, get direction commands fail
	if facing == "S" then
		frontSquare = square:getS()
	elseif facing == "E" then
		frontSquare = square:getE()
	elseif facing == "W" then
		frontSquare = square:getW()
	elseif facing == "N" then
		frontSquare = square:getN()
	end
	
	return frontSquare
end

FA.getRearSquare = function(square, facing)
	local rearSquare = nil
	
	-- This version ignores blocked squares
	if facing == "S" then
		rearSquare = getSquare(square:getX(), square:getY()-1, square:getZ())
	elseif facing == "E" then
		rearSquare = getSquare(square:getX()-1, square:getY(), square:getZ())
	elseif facing == "W" then
		rearSquare = getSquare(square:getX()+1, square:getY(), square:getZ())
	elseif facing == "N" then
		rearSquare = getSquare(square:getX(), square:getY()+1, square:getZ())
	end
	
	return rearSquare
end

FA.walkToFront = function(player, object)
	local objectSquare = object:getSquare()

	local spriteName = object:getSprite():getName()
	if not spriteName then
		return false
	end

	local facing = object:getSprite():getProperties():Val("Facing")
	-- Some objects do not have a facing to them, treat them as any direction availible
	if not facing then
		if objectSquare:getE() then
			facing = "E"
		elseif objectSquare:getS() then
			facing = "S"
		elseif objectSquare:getW() then
			facing = "W"
		elseif objectSquare:getN() then
			facing = "N"
		end
	end

	local frontSquare = FA.getFrontSquare(objectSquare, facing)
	if not frontSquare then
		return false
	end

	local turn = FA.getFrontSquare(frontSquare, facing)

	if AdjacentFreeTileFinder.privTrySquare(objectSquare, frontSquare) then
		ISTimedActionQueue.add(ISWalkToTimedAction:new(player, frontSquare))
		if turn then
			player:faceLocation(objectSquare:getX(), objectSquare:getY())
		end
		return true
	end
	return false
end

FA.walkToRear = function(player, object)
	local objectSquare = object:getSquare()

	local spriteName = object:getSprite():getName()
	if not spriteName then
		return false
	end

	local facing = object:getSprite():getProperties():Val("Facing")
	-- Some objects do not have a facing to them, treat them as any direction availible otherwise swap facing for rear
	if not facing then
		if objectSquare:getW() then
			facing = "W"
		elseif objectSquare:getN() then
			facing = "N"
		elseif objectSquare:getE() then
			facing = "E"
		elseif objectSquare:getS() then
			facing = "S"
		end
	else
		if facing == "E" then
			facing = "W"
		elseif facing == "S" then
			facing = "N"
		elseif facing == "W" then
			facing = "E"
		elseif facing == "N" then
			facing = "S"
		end

	end

	local rearSquare = FA.getFrontSquare(objectSquare, facing)
	if not rearSquare then
		return false
	end

	local turn = FA.getFrontSquare(rearSquare, facing)

	if AdjacentFreeTileFinder.privTrySquare(objectSquare, rearSquare) then
		ISTimedActionQueue.add(ISWalkToTimedAction:new(player, rearSquare))
		if turn then
			player:faceLocation(objectSquare:getX(), objectSquare:getY())
		end
		return true
	end
	return false
end