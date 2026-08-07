-- BUILD 41

ThrowYourBagAcrossClient = {}

function ThrowYourBagAcrossClient.getTargetSquare(player, target)
	local sq1, sq2, selected

	local playerSquare = player:getSquare()
	local px, py, pz = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()

	local targetSquare = target:getSquare()
	local wx, wy, wz = targetSquare:getX(), targetSquare:getY(), targetSquare:getZ()
    

	if (target.getNorth and target:getNorth()) or target:isNorthHoppable() or targetSquare:getHoppableWall(true) then
		sq1 = getSquare(wx, wy + 1, wz)
		sq2 = getSquare(wx, wy - 1, wz)
		selected = (py >= wy) and sq2 or sq1
	else
		sq1 = getSquare(wx + 1, wy, wz)
		sq2 = getSquare(wx - 1, wy, wz)
		selected = (px >= wx) and sq2 or sq1
	end

	local x = selected:getX()
    local y = selected:getY()

	for z = selected:getZ(), 0, -1 do
		local floorSquare = getSquare(x, y, z)
		if floorSquare:isSolidFloor() then
			return floorSquare
		end
	end
    return nil
end

function ThrowYourBagAcrossClient.onThrowThroughWindow(worldobjects, player, window, item)
	if luautils.walkAdjWindowOrDoor(player, window:getSquare(), window) then
		ISTimedActionQueue.add(ISThrowBagAcrossWindow:new(player, window, item))
	end
end

function ThrowYourBagAcrossClient.onThrowOverFence(worldobjects, player, fence, item)
	if luautils.walkAdjWindowOrDoor(player, fence:getSquare(), fence) then
		ISTimedActionQueue.add(ISThrowBagOverFence:new(player, fence, item))
	end
end

function ThrowYourBagAcrossClient.onThrow(worldobjects, player, targetSquare, item, distances)
	ISTimedActionQueue.add(ISThrowBag:new(player, targetSquare, item, distances))
end

local function ThrowFillContextMenu(playerIndex, context, worldobjects, test)
    local playerObj = getSpecificPlayer(playerIndex)
    local playerPrimaryEquipped = playerObj:getPrimaryHandItem()
    local playerSecondaryEquipped = playerObj:getSecondaryHandItem()
    local playerHasBagInPrimaryHand = playerPrimaryEquipped and playerPrimaryEquipped:IsInventoryContainer()
    local playerHasBagInSecondaryHand = playerSecondaryEquipped and playerSecondaryEquipped:IsInventoryContainer()
    if not playerHasBagInPrimaryHand and not playerHasBagInSecondaryHand then
        return
    end
    local hoppableWindow = nil
    local hoppableWall = nil
    local dir = playerObj:getDir();
    for i,v in ipairs(worldobjects) do
		ISWorldObjectContextMenu.fetch(v, playerIndex, true);
    end

    if clickedSquare then
        local clickedSquarehoppableWall = clickedSquare:getHoppableWall(false)
        local clickedSquarehoppableWallNorth = clickedSquare:getHoppableWall(true)
        if clickedSquarehoppableWall then
            hoppableWall = clickedSquarehoppableWall
        end
        if clickedSquarehoppableWallNorth then
            hoppableWall = clickedSquarehoppableWallNorth
        end
    end
    if groundSquare then
        local groundSquarehoppableWall = groundSquare:getHoppableWall(false)
        local groundSquarehoppableWallNorth = groundSquare:getHoppableWall(true)
        if groundSquarehoppableWall then
            hoppableWall = groundSquarehoppableWall
        end
        if groundSquarehoppableWallNorth then
            hoppableWall = groundSquarehoppableWallNorth
        end
    end

    if window and window:canClimbThrough(playerObj) then
        hoppableWindow = window
    elseif thumpableWindow then
        local movedWindow = thumpableWindow:getSquare():getWindow(thumpableWindow:getNorth())
        if not movedWindow and thumpableWindow:canClimbThrough(playerObj) then
            hoppableWindow = thumpableWindow
        end
    elseif thump and thump:isHoppable() and thump:canClimbOver(playerObj) then
        hoppableWall = thump
    end

    if hoppableWindow or hoppableWall then
        if playerHasBagInPrimaryHand then
            if hoppableWall then
                context:addOption(getText("ContextMenu_Throw_Primary_Over"), worldobjects, ThrowYourBagAcrossClient.onThrowOverFence, playerObj, hoppableWall, { item = playerPrimaryEquipped });
            elseif hoppableWindow then
                context:addOption(getText("ContextMenu_Throw_Primary_Through_Window"), worldobjects, ThrowYourBagAcrossClient.onThrowThroughWindow, playerObj, hoppableWindow, { item = playerPrimaryEquipped });
            end
        end
        if playerHasBagInSecondaryHand then
            if hoppableWall then
                context:addOption(getText("ContextMenu_Throw_Secondary_Over"), worldobjects, ThrowYourBagAcrossClient.onThrowOverFence, playerObj, hoppableWall, { item2 = playerSecondaryEquipped });
            elseif hoppableWindow then
                context:addOption(getText("ContextMenu_Throw_Secondary_Through_Window"), worldobjects, ThrowYourBagAcrossClient.onThrowThroughWindow, playerObj, hoppableWindow, { item2 = playerSecondaryEquipped });
            end
        end
        if playerHasBagInPrimaryHand and playerHasBagInSecondaryHand then
            if hoppableWall then
                context:addOption(getText("ContextMenu_Throw_Both_Over"), worldobjects, ThrowYourBagAcrossClient.onThrowOverFence, playerObj, hoppableWall, { item = playerPrimaryEquipped, item2 = playerSecondaryEquipped });
            elseif hoppableWindow then
                context:addOption(getText("ContextMenu_Throw_Both_Through_Window"), worldobjects, ThrowYourBagAcrossClient.onThrowThroughWindow, playerObj, hoppableWindow, { item = playerPrimaryEquipped, item2 = playerSecondaryEquipped });
            end
        end
        return
    end
    
    local playerSquareBuilding = playerObj:getCurrentSquare():getBuilding()
    local clickedSquareBuilding = clickedSquare and clickedSquare:getBuilding()
    if playerSquareBuilding ~= clickedSquareBuilding then
        return
    end

    local clickedSquarePosition = clickedSquare and { x = clickedSquare:getX(), y = clickedSquare:getY(), z = clickedSquare:getZ() }
    local playerSquarePosition = { x = playerObj:getX(), y = playerObj:getY(), z = playerObj:getZ() }
    -- if clickedSquare is less than 7 tiles away from playerSquarePosition then we can throw the bag
    local distanceX = math.abs(clickedSquarePosition.x - playerSquarePosition.x)
    local distanceY = math.abs(clickedSquarePosition.y - playerSquarePosition.y)
    if clickedSquarePosition and distanceX <= 7 and distanceY <= 7 then
        if playerHasBagInPrimaryHand then
            context:addOption(getText("ContextMenu_Throw_Primary"), worldobjects, ThrowYourBagAcrossClient.onThrow, playerObj, clickedSquare, { item = playerPrimaryEquipped }, { x = distanceX, y = distanceY });
        end
        if playerHasBagInSecondaryHand then
            context:addOption(getText("ContextMenu_Throw_Secondary"), worldobjects, ThrowYourBagAcrossClient.onThrow, playerObj, clickedSquare, { item2 = playerSecondaryEquipped }, { x = distanceX, y = distanceY });
        end
        if playerHasBagInPrimaryHand and playerHasBagInSecondaryHand then
            context:addOption(getText("ContextMenu_Throw_Both"), worldobjects, ThrowYourBagAcrossClient.onThrow, playerObj, clickedSquare, { item = playerPrimaryEquipped, item2 = playerSecondaryEquipped }, { x = distanceX, y = distanceY });
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(ThrowFillContextMenu)
