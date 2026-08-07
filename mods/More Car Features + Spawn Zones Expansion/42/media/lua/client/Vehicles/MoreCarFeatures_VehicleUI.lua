--function ISVehicleMechanics:getCarJack(player)
--	return player:getInventory():getFirstTypeRecurse(ItemKey.Normal.JACK)
--end
--	local wrench = ISVehicleMechanics:getWrench(playerObj)
--	local screwdriver = ISVehicleMechanics:getScrewdriver(playerObj)
--	local tirePump = ISVehicleMechanics:getTirePump(playerObj)
--	local jack = ISVehicleMechanics:getCarJack(playerObj)

--local vehicle = getPlayer():getNearVehicle(); for i=0, vehicle:getPartCount()-1 do  print(vehicle:getPartByIndex(i):getId()); end
--local vehicle = getPlayer():getNearVehicle(); for i=0, vehicle:getPartCount()-1 do  print(string.lower(vehicle:getPartByIndex(i):getId()):contains("")); end

local activatedMods = getActivatedMods()

local function testPathActionToPartArea(playerObj, part)
	print("test testPathActionToPartArea: ", part)
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, part:getVehicle(), part:getArea()))
end

function ISVehicleMenu.BackToVehRadialMenu(playerObj)
	getPlayerRadialMenu(playerObj:getPlayerNum()):clear()
	local waitTicks = 2
	local function waitToAddRadial()
		waitTicks = waitTicks - 1
		if waitTicks > 0 then return end
		ISVehicleMenu.showRadialMenu(playerObj)
		Events.OnTick.Remove(waitToAddRadial)
	end
	Events.OnTick.Add(waitToAddRadial)
end

function ISVehicleMenu.BackToPlantLocationMechanic(playerObj, vehicle, remote, sensor)
	getPlayerRadialMenu(playerObj:getPlayerNum()):clear()
	local waitTicks = 2
	local function waitToAddRadial()
		waitTicks = waitTicks - 1
		if waitTicks > 0 then return end
		ISVehicleMenu.PlantLocationMechanic(playerObj, vehicle, remote, sensor)
		Events.OnTick.Remove(waitToAddRadial)
	end
	Events.OnTick.Add(waitToAddRadial)
end

function ISVehicleMenu.ISUnHotwireVehicle(playerObj)
	local vehicle = playerObj:getVehicle()
	if not vehicle or not vehicle:isHotwired() then return end
	ISTimedActionQueue.add(ISUnHotwireVehicle:new(playerObj))
end

function ISVehicleMenu.notBlockedPartExit(player, part)
	local vehicle = player:getVehicle()
	if not vehicle then
		return false
	end
	local dir = player:getDir()
	local partExit = vehicle:getAreaCenter(part:getArea())
	if not partExit then
		return false
	end
	local x, y, z = partExit:getX(), partExit:getY(), vehicle:getZ()
	local square = getCell():getOrCreateGridSquare(x, y, z)

	local tryVehBlock = square:getVehicleContainer()
	if not square or
		not square:isSolidFloor() or
		not square:isCouldSee(player:getPlayerNum()) or
		(tryVehBlock and tryVehBlock ~= vehicle)
	then
		return false
	end

	local sq1, sq2, sq3, sq4
	if     (dir == IsoDirections.N) then		sq1 = {square, {"N"}}
	elseif (dir == IsoDirections.NE) then		sq1 = {square, {"N"}};				sq2 = {getCell():getOrCreateGridSquare(x+1, y, z), {"N", "W"}};			sq3 = {getCell():getOrCreateGridSquare(x+1, y-1, z), {"W"}}
	elseif (dir == IsoDirections.E) then		sq1 = {square, nil};				sq2 = {getCell():getOrCreateGridSquare(x+1, y, z), {"W"}}
	elseif (dir == IsoDirections.SE) then		sq1 = {square, nil};				sq2 = {getCell():getOrCreateGridSquare(x+1, y, z), {"W"}};				sq3 = {getCell():getOrCreateGridSquare(x, y+1, z), {"N"}};			sq4 = {getCell():getOrCreateGridSquare(x+1, y+1, z), {"N", "W"}}
	elseif (dir == IsoDirections.S) then		sq1 = {square, nil};				sq2 = {getCell():getOrCreateGridSquare(x, y+1, z), {"N"}}
	elseif (dir == IsoDirections.SW) then		sq1 = {square, {"W"}};				sq2 = {getCell():getOrCreateGridSquare(x, y-1, z), {"N", "W"}};			sq3 = {getCell():getOrCreateGridSquare(x-1, y+1, z), {"N"}}
	elseif (dir == IsoDirections.W) then		sq1 = {square, {"W"}}
	elseif (dir == IsoDirections.NW) then		sq1 = {square, {"N", "W"}};			sq2 = {getCell():getOrCreateGridSquare(x-1, y, z), {"N"}};				sq3 = {getCell():getOrCreateGridSquare(x, y-1, z), {"W"}}
	end

	local squares = {}
	if sq1 then table.insert(squares, sq1) end
	if sq2 then table.insert(squares, sq2) end
	if sq3 then table.insert(squares, sq3) end
	if sq4 then table.insert(squares, sq4) end

	for _, sq in ipairs(squares) do
		local isoObjects = sq[1]:getObjects()
		for i=0, isoObjects:size()-1 do
			local isoObj = isoObjects:get(i)
			if isoObj then
				local sqProps = isoObj:getProperties()
				if sqProps and sqProps:has(IsoFlagType.solid) or sqProps:has(IsoFlagType.solidtrans) then
					return false
				end
				local isoObjType = isoObj:getType()
				if  isoObjType == IsoObjectType.stairsTW or
					isoObjType == IsoObjectType.stairsTN or
					isoObjType == IsoObjectType.stairsMW or
					isoObjType == IsoObjectType.stairsMN or
					isoObjType == IsoObjectType.stairsBW or
					isoObjType == IsoObjectType.stairsBN
				then
					return false
				end
				local isoObjSprite = isoObj:getSprite()
				if sq[2] and isoObjSprite then
					local objSpriteProps = isoObjSprite:getProperties()
					for _, isoFlagType in ipairs(sq[2]) do
						if isoFlagType == "N" then
							if objSpriteProps:has(IsoFlagType.collideN) then
								return false
							end
						elseif isoFlagType == "W" then
							if objSpriteProps:has(IsoFlagType.collideW) then
								return false
							end
						end
					end
				end
			end
		end
	end

	return true
end

function ISVehicleMenu.onEnterTrunk(playerObj, doorPart)
	local vehicle = doorPart:getVehicle()
	local doorPartCheck = vehicle:getUseablePart(playerObj)
	if not (doorPartCheck and doorPartCheck:getDoor() and (doorPartCheck:getId() == "TrunkDoor" or doorPartCheck:getId() == "TrunkDoor2" or doorPartCheck:getId() == "DoorRear")) then
		return
	end

	if not playerObj:isBlockMovement() then
		if doorPart:getInventoryItem() then
			local door = doorPart:getDoor()
			if door:isLocked() then
				ISTimedActionQueue.add(ISUnlockVehicleDoor:new(playerObj, doorPart))
			end
			if not door:isOpen() then
				ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, vehicle, doorPart))
			end
			ISTimedActionQueue.add(ISTrunkEnterVehicle:new(playerObj, vehicle))
			ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, vehicle, doorPart))
		else
			ISTimedActionQueue.add(ISTrunkEnterVehicle:new(playerObj, vehicle))
		end
	end
end

function ISVehicleMenu.onExitTrunk(playerObj, trunkPart)
	local vehicle = trunkPart:getVehicle()
	local fullVName = vehicle:getScript():getFullName()
	local seat = vehicle:getSeat(playerObj)
	if MoreCarFeatures.canEnterExitVehicleTrunk[fullVName] then
		if not (vehicle:getMaxPassengers() <= 2 or vehicle:getPassengerArea(seat):contains("SeatRear")) then
			return
		end
	elseif MoreCarFeatures.canEnterExitVehicleTrunkKI51[fullVName] then
		if seat < 0 then
			return
		end
	elseif MoreCarFeatures.canEnterExitVehicleTrunkKI52[fullVName] then
		if not (seat == 2 or seat == 3) then
			return
		end
	elseif MoreCarFeatures.canEnterExitVehicleTrunkKI53[fullVName] then
		if not (seat == 4 or seat == 5) then
			return
		end
	else
		return
	end

	vehicle:updateHasExtendOffsetForExit(playerObj)
	if (not playerObj:isBlockMovement()) then
		if not vehicle then return end
		if vehicle:isDriver(playerObj) then
			if math.abs(vehicle:getCurrentSpeedKmHour()) > 0.8 then ISTimedActionQueue.add(ISStopVehicle:new(playerObj)) end
		else 
			if not vehicle:isStopped() then
				HaloTextHelper.addBadText(playerObj, getText("IGUI_PlayerText_CanNotExitFromMovingCar"))
				vehicle:updateHasExtendOffsetForExitEnd(playerObj)
				return 
			end
		end

		if ISVehicleMenu.notBlockedPartExit(playerObj, trunkPart) then	--Custom isExitBlocked
			local doorPart = vehicle:getPartById("TrunkDoor") or vehicle:getPartById("DoorRear")
			if doorPart and doorPart:getDoor() then
				if doorPart:getInventoryItem() then
					local door = doorPart:getDoor()
					if door:isLocked() then
						ISTimedActionQueue.add(ISUnlockVehicleDoor:new(playerObj, doorPart))
					end
					if not door:isOpen() then
						ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, vehicle, doorPart))
					end
					ISTimedActionQueue.add(ISTrunkExitVehicle:new(playerObj, vehicle, trunkPart))
					ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, vehicle, doorPart))
				else
					ISTimedActionQueue.add(ISTrunkExitVehicle:new(playerObj, vehicle, trunkPart))
				end
			end
		else
			HaloTextHelper.addBadText(playerObj, getText("IGUI_PlayerText_DoorBlocked"))
		end
	end
end

function ISVehicleMenu.EfficientVehiclePartPathingSides(leftParts, rightParts, otherParts)
	table.sort(leftParts, function(a, b)
		return a.dist < b.dist
	end)
	table.sort(rightParts, function(a, b)
		return a.dist < b.dist
	end)

	local firstSide, secondSide
	if #leftParts == 0 then
		firstSide = rightParts
		secondSide = {}
	elseif #rightParts == 0 then
		firstSide = leftParts
		secondSide = {}
	elseif leftParts[1].dist > rightParts[1].dist then
		firstSide = rightParts
		secondSide = leftParts
	else
		firstSide = leftParts
		secondSide = rightParts
	end

	local partPath = {}
	for _, part in ipairs(firstSide) do
		table.insert(partPath, part.part)
	end

	local current = firstSide[#firstSide]
	while #otherParts > 0 do
		local bestIndex
		local bestDist
		for i, p in ipairs(otherParts) do
			local d = (p.x-current.x)^2 + (p.y-current.y)^2
			if not bestDist or d < bestDist then
				bestDist = d
				bestIndex = i
			end
		end
		current = table.remove(otherParts, bestIndex)
		table.insert(partPath, current.part)
	end

	if #secondSide > 0 then
		table.sort(secondSide, function(a, b)
			local da = (a.x-current.x)^2 + (a.y-current.y)^2
			local db = (b.x-current.x)^2 + (b.y-current.y)^2
			return da < db
		end)
		for _, part in ipairs(secondSide) do
			table.insert(partPath, part.part)
		end
	end

	return partPath
end

function ISVehiclePartMenu.onDeflateTireALL(playerObj, vehicle)
	local leftTires = {}
	local rightTires = {}
	local otherParts = {}
	for i = 0, vehicle:getPartCount() - 1 do
		local wheelPart = vehicle:getPartByIndex(i)
		if wheelPart and wheelPart:getCategory() == "tire"
			and wheelPart:getId():contains("Tire")
			and wheelPart:getItemType()
			and not wheelPart:getItemType():isEmpty()
			and wheelPart:getContainerContentAmount() > 0
		then
			local pos = vehicle:getAreaCenter(wheelPart:getArea())
			local dx = pos:getX() - playerObj:getX()
			local dy = pos:getY() - playerObj:getY()
			local dist = math.sqrt(dx * dx + dy * dy)
			local tire = {
				part = wheelPart,
				x = pos:getX(),
				y = pos:getY(),
				dist = dist,
			}
			if wheelPart:getId():contains("Left") then
				table.insert(leftTires, tire)
			elseif wheelPart:getId():contains("Right") then
				table.insert(rightTires, tire)
			else
				table.insert(otherParts, tire)
			end
		end
	end

	if #leftTires > 0 or #rightTires > 0 or #otherParts > 0 then
		local sortedTires = ISVehicleMenu.EfficientVehiclePartPathingSides(leftTires, rightTires, otherParts)
		for _, wheelPart in ipairs(sortedTires) do
			ISVehiclePartMenu.onDeflateTire(playerObj, wheelPart)
		end
	end
end

function ISVehiclePartMenu.onInflateTireALL(playerObj, vehicle)
	local leftTires = {}
	local rightTires = {}
	local otherParts = {}
	for i = 0, vehicle:getPartCount() - 1 do
		local wheelPart = vehicle:getPartByIndex(i)
		if wheelPart and wheelPart:getCategory() == "tire"
			and wheelPart:getId():contains("Tire")
			and wheelPart:getItemType()
			and not wheelPart:getItemType():isEmpty()
			and wheelPart:getContainerContentAmount() < wheelPart:getContainerCapacity()
		then
			local pos = vehicle:getAreaCenter(wheelPart:getArea())
			local dx = pos:getX() - playerObj:getX()
			local dy = pos:getY() - playerObj:getY()
			local dist = math.sqrt(dx * dx + dy * dy)
			local tire = {
				part = wheelPart,
				x = pos:getX(),
				y = pos:getY(),
				dist = dist,
			}
			if wheelPart:getId():contains("Left") then
				table.insert(leftTires, tire)
			elseif wheelPart:getId():contains("Right") then
				table.insert(rightTires, tire)
			else
				table.insert(otherParts, tire)
			end
		end
	end

	if #leftTires > 0 or #rightTires > 0 or #otherParts > 0 then
		local sortedTires = ISVehicleMenu.EfficientVehiclePartPathingSides(leftTires, rightTires, otherParts)
		for _, wheelPart in ipairs(sortedTires) do
			ISVehiclePartMenu.onInflateTire(playerObj, wheelPart)
		end
	end
end


function ISWorldObjectContextMenu.TakeSpecificTireFromStack(playerObj, squareCoords, spriteName, tireToTake, stackOrder)	--Unused
	local square = getCell():getGridSquare(squareCoords[1], squareCoords[2], squareCoords[3])
	if not square then return end
	local object = square:getObjectWithSprite(spriteName)
	if not object then return end

	for _, tire in ipairs(object:getModData().TireStackContents) do
		if tireToTake == tire[1] then
			if luautils.walkAdjObject(playerObj, object, false, true) then
				ISTimedActionQueue.add(ISTireStackActions:new(playerObj, object, tireToTake, "Take", stackOrder))
			end
			break
		end
	end
end

function ISWorldObjectContextMenu.AddSpecificTireToStack(playerObj, squareCoords, spriteName, tireToAdd)	--Unused
	local square = getCell():getGridSquare(squareCoords[1], squareCoords[2], squareCoords[3])
	if not square then return end
	local object = square:getObjectWithSprite(spriteName)
	if not object then return end

	if luautils.walkAdjObject(playerObj, object, false, true) then
		ISInventoryPaneContextMenu.equipWeapon(tireToAdd, true, false, playerObj:getPlayerNum())
		ISTimedActionQueue.add(ISTireStackActions:new(playerObj, object, tireToAdd, "Add"))
	end
end

local function returnTireStackType(name)
	if not name then return nil end
	if luautils.stringEnds(name, "_49") then
		return {numTires = 1, positioning = "L"}
	elseif luautils.stringEnds(name, "_48") then
		return {numTires = 1, positioning = "R"}
	elseif luautils.stringEnds(name, "_50") then
		return {numTires = 2, positioning = "M"}
	elseif luautils.stringEnds(name, "_40") then
		return {numTires = 2, positioning = "L"}
	elseif luautils.stringEnds(name, "_41") then
		return {numTires = 2, positioning = "R"}
	elseif luautils.stringEnds(name, "_51") then
		return {numTires = 3, positioning = "M"}
	elseif luautils.stringEnds(name, "_42") then
		return {numTires = 3, positioning = "L"}
	elseif luautils.stringEnds(name, "_43") then
		return {numTires = 3, positioning = "R"}
	elseif luautils.stringEnds(name, "_52") then
		return {numTires = 4, positioning = "M"}
	elseif luautils.stringEnds(name, "_45") then
		return {numTires = 4, positioning = "L"}
	elseif luautils.stringEnds(name, "_44") then
		return {numTires = 4, positioning = "R"}
	end
	return nil
end

local function returnVehicleTypeForStringName(tire, name)	--Unused
	if luautils.stringEnds(tire, "1") then
		name = getText("IGUI_VehicleType_1") .. " " .. name
	elseif luautils.stringEnds(tire, "2") then
		name = getText("IGUI_VehicleType_2") .. " " .. name
	elseif luautils.stringEnds(tire, "3") then
		name = getText("IGUI_VehicleType_3") .. " " .. name
	end
	return name
end

function ISWorldObjectContextMenu.TireStackActions(playerIndex, context, worldObjects)	--Unused
	local playerObj = getSpecificPlayer(playerIndex)
	for j=#worldObjects, 1, -1 do
		local v = worldObjects[j]
		local name = v:getTextureName()
		if name and luautils.stringStarts(name, "location_business_machinery_01") and (name:contains("_4") or name:contains("_5")) then
			local stackType = returnTireStackType(name)
			if not stackType then return end

		--	Used to Reset in Singplayer Debug
		--	if true then
		--		v:getModData().TireStackContents = nil
		--		return
		--	end

			local WarnText
			local TireStackMD = v:getModData().TireStackContents or {}
			local square = v:getSquare()
			if #TireStackMD == 0 then
				if isClient() then
					local args = {nameTireStack = name, x = square:getX(), y = square:getY(), z = square:getZ(), stackType = stackType}
					sendClientCommand('MoreCarFeatures', "SyncTireStackMD", args)
					WarnText = getText("ContextMenu_SyncingTireStackDataServerCancel")
					if true then return end	--Disabling warning text and just hiding the menu so the player right clicks again, naturally assuming they misclicked, im souprr smort
				else
					TireStackMD = MoreCarFeatures.randomizedTireStackContents(stackType)
					v:getModData().TireStackContents = TireStackMD
				end
			end

			local baseTireStackOption = context:addOption(getText("ContextMenu_TireStackOptions"), worldobjects, nil)
			baseTireStackOption.itemForTexture = instanceItem("Moveables."..name)
			if WarnText then
				baseTireStackOption.toolTip = ISInventoryPaneContextMenu.addToolTip()
				baseTireStackOption.toolTip.description = WarnText
				baseTireStackOption.notAvailable = true
			else
				local tireStackContainerMenu = ISContextMenu:getNew(context)
				context:addSubMenu(baseTireStackOption, tireStackContainerMenu)

			--	for i, tire in ipairs(TireStackMD) do	NOT this so the table is sorted from highest to lowest in the stack
				for i = #TireStackMD, 1, -1 do
					local tire = TireStackMD[i]

					local tireName = instanceItem(tire[1]):getDisplayName()
					tireName = returnVehicleTypeForStringName(tire[1], tireName)
					local text = getText("ContextMenu_Take") .. " " .. tireName
					local takeTireContainerMenu = tireStackContainerMenu:addGetUpOption(text, playerObj, ISWorldObjectContextMenu.TakeSpecificTireFromStack, {square:getX(), square:getY(), square:getZ()}, name, tire[1], i)
					takeTireContainerMenu.iconTexture = instanceItem(tire[1]):getTexture()
					takeTireContainerMenu.toolTip = ISInventoryPaneContextMenu.addToolTip()
					takeTireContainerMenu.toolTip.description = getText("IGUI_Generator_Condition", tire[2]) .. 
						"  <LINE> " .. getText("IGUI_Vehicle_ContainerCapacity_Air", tire[3]) .. "/" .. tire[4]
				end

				if stackType.numTires < 4 then
					local tiresToAdd = {}
					local it = playerObj:getInventory():getItems()
					for i=0, it:size()-1 do
						local item = it:get(i)
						if item:hasTag(ItemTag.WHOLE_TIRE) then
							table.insert(tiresToAdd, item)
						elseif item:IsInventoryContainer() and item:isEquipped() then
							local it2 = item:getInventory():getItems()
							for i2 = 0, it2:size()-1 do
								local item2 = it2:get(i2)
								if item2:hasTag(ItemTag.WHOLE_TIRE) then
									table.insert(tiresToAdd, item2)
								end
							end
						end
					end

					local dynamicContainerMenu = tireStackContainerMenu
					if #tiresToAdd > 4 then
						local text = getText("IGUI_PlayerStats_Add") .. " " .. getText("IGUI_VehiclePartCattire")
						local addTiresOption = tireStackContainerMenu:addOption(text, worldobjects, nil)
						dynamicContainerMenu = ISContextMenu:getNew(tireStackContainerMenu)
						tireStackContainerMenu:addSubMenu(addTiresOption, dynamicContainerMenu)
					end
					for _, tire in ipairs(tiresToAdd) do
						local tireName = returnVehicleTypeForStringName(tire:getScriptItem():getFullName(), tire:getDisplayName())
						local text = getText("IGUI_PlayerStats_Add") .. " " .. tireName
						local addTireContainerMenu = dynamicContainerMenu:addGetUpOption(text, playerObj, ISWorldObjectContextMenu.AddSpecificTireToStack, {square:getX(), square:getY(), square:getZ()}, name, tire)
						addTireContainerMenu.iconTexture = tire:getTexture()
						addTireContainerMenu.toolTip = ISInventoryPaneContextMenu.addToolTip()
						addTireContainerMenu.toolTip.description = getText("IGUI_Generator_Condition", tire:getCondition()) .. "  <LINE> " .. 
							getText("IGUI_Vehicle_ContainerCapacity_Air", math.max(tire:getItemCapacity(), 0)) .. "/" .. tire:getMaxCapacity()
					end
				end

			end

			break
		end
	end
end
--Events.OnFillWorldObjectContextMenu.Add(ISWorldObjectContextMenu.TireStackActions)
--Events.OnPreFillWorldObjectContextMenu.Add(ISWorldObjectContextMenu.TireStackActions)	--place on top of everything
local function returnTireStackType2(name)
	if not name then return nil end
	if luautils.stringEnds(name, "_152") or luautils.stringEnds(name, "_160") then
		return {numTires = 1, positioning = "M"}
	elseif luautils.stringEnds(name, "_153") or luautils.stringEnds(name, "_161") then
		return {numTires = 2, positioning = "M"}
	elseif luautils.stringEnds(name, "_155") or luautils.stringEnds(name, "_163") then
		return {numTires = 2, positioning = "L"}
	elseif luautils.stringEnds(name, "_154") or luautils.stringEnds(name, "_162") then
		return {numTires = 2, positioning = "R"}
	elseif luautils.stringEnds(name, "_139") or luautils.stringEnds(name, "_147") then
		return {numTires = 3, positioning = "M"}
	elseif luautils.stringEnds(name, "_141") or luautils.stringEnds(name, "_149") then
		return {numTires = 3, positioning = "L"}
	elseif luautils.stringEnds(name, "_140") or luautils.stringEnds(name, "_148") then
		return {numTires = 3, positioning = "R"}
	elseif luautils.stringEnds(name, "_136") or luautils.stringEnds(name, "_144") then
		return {numTires = 4, positioning = "M"}
	elseif luautils.stringEnds(name, "_138") or luautils.stringEnds(name, "_146") then
		return {numTires = 4, positioning = "L"}
	elseif luautils.stringEnds(name, "_137") or luautils.stringEnds(name, "_145") then
		return {numTires = 4, positioning = "R"}
	end
	return nil
end

local function instanceItemReplaceTireStack(name)
	if not name then return nil end
	if luautils.stringEnds(name, "_152") or luautils.stringEnds(name, "_160") then
		return "location_business_machinery_01_48"
	elseif luautils.stringEnds(name, "_153") or luautils.stringEnds(name, "_161") then
		return "location_business_machinery_01_50"
	elseif luautils.stringEnds(name, "_155") or luautils.stringEnds(name, "_163") then
		return "location_business_machinery_01_40"
	elseif luautils.stringEnds(name, "_154") or luautils.stringEnds(name, "_162") then
		return "location_business_machinery_01_41"
	elseif luautils.stringEnds(name, "_139") or luautils.stringEnds(name, "_147") then
		return "location_business_machinery_01_51"
	elseif luautils.stringEnds(name, "_141") or luautils.stringEnds(name, "_149") then
		return "location_business_machinery_01_43"
	elseif luautils.stringEnds(name, "_140") or luautils.stringEnds(name, "_148") then
		return "location_business_machinery_01_42"
	elseif luautils.stringEnds(name, "_136") or luautils.stringEnds(name, "_144") then
		return "location_business_machinery_01_52"
	elseif luautils.stringEnds(name, "_138") or luautils.stringEnds(name, "_146") then
		return "location_business_machinery_01_45"
	elseif luautils.stringEnds(name, "_137") or luautils.stringEnds(name, "_145") then
		return "location_business_machinery_01_44"
	end
	return nil
end

function ISWorldObjectContextMenu.TakeTirePiecesFromTireStack(playerObj, squareCoords, spriteName)
	local square = getCell():getGridSquare(squareCoords[1], squareCoords[2], squareCoords[3])
	if not square then return end
	local object = square:getObjectWithSprite(spriteName)
	if not object then return end

	local tool
	local it = playerObj:getInventory():getItems()
	for i=0, it:size()-1 do
		local item = it:get(i)
		if item:hasTag(ItemTag.METAL_SAW) or item:hasTag(ItemTag.BOLT_CUTTERS) then
			tool = item
			break
		elseif item:IsInventoryContainer() and item:isEquipped() then
			local it2 = item:getInventory():getItems()
			for i2 = 0, it2:size()-1 do
				local item2 = it2:get(i2)
				if item2:hasTag(ItemTag.METAL_SAW) or item2:hasTag(ItemTag.BOLT_CUTTERS) then
					tool = item
					break
				end
			end
			if tool then
				break
			end
		end
	end

	if not tool or tool:isBroken() or playerObj:getPerkLevel(Perks.Strength) < 2 then return end

	if luautils.walkAdjObject(playerObj, object, false, true) then
		ISInventoryPaneContextMenu.equipWeapon(tool, true, false, playerObj:getPlayerNum())
		ISTimedActionQueue.add(ISTireStackActions:new(playerObj, object, tool))
	end
end

function ISWorldObjectContextMenu.TireStackActions2(playerIndex, context, worldObjects)
	local playerObj = getSpecificPlayer(playerIndex)
	for j=#worldObjects, 1, -1 do
		local v = worldObjects[j]
		local name = v:getTextureName()
		local stackType = returnTireStackType(name) or returnTireStackType2(name)
		if stackType and (luautils.stringStarts(name, "location_business_machinery_01") or luautils.stringStarts(name, "recreational_sports_01"))then
			local sq = v:getSquare()

			local tool
			local it = playerObj:getInventory():getItems()
			for i=0, it:size()-1 do
				local item = it:get(i)
				if item:hasTag(ItemTag.METAL_SAW) or item:hasTag(ItemTag.BOLT_CUTTERS) then
					tool = item
					break
				elseif item:IsInventoryContainer() and item:isEquipped() then
					local it2 = item:getInventory():getItems()
					for i2 = 0, it2:size()-1 do
						local item2 = it2:get(i2)
						if item2:hasTag(ItemTag.METAL_SAW) or item2:hasTag(ItemTag.BOLT_CUTTERS) then
							tool = item
							break
						end
					end
					if tool then
						break
					end
				end
			end

			local text = getText("ContextMenu_TireStackTakeTirePieces", stackType.numTires*4)
			local baseTireStackOption = context:addOption(text, playerObj, ISWorldObjectContextMenu.TakeTirePiecesFromTireStack, {sq:getX(), sq:getY(), sq:getZ()}, name)
			local texName = instanceItemReplaceTireStack(name) or name
			baseTireStackOption.itemForTexture = instanceItem("Moveables."..texName)

			local hasTool = 1
			local strengthLevel = playerObj:getPerkLevel(Perks.Strength)
			if not tool or tool:isBroken() then
				hasTool = 0
				baseTireStackOption.notAvailable = true
			elseif strengthLevel < 2 then
				baseTireStackOption.notAvailable = true
			end
			baseTireStackOption.toolTip = ISInventoryPaneContextMenu.addToolTip()
			baseTireStackOption.toolTip.description = getText("Tooltip_craft_Needs")
				 .. ":  <LINE> " .. getItemDisplayName("Base.BoltCutters") .. " " .. 
				getText("ContextMenu_or") .. " " .. getItemDisplayName("Base.Saw")..": " .. hasTool.."/1"
				 .. "  <LINE> " .. getText("IGUI_perks_Strength")..": " .. strengthLevel.."/2";

			break
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(ISWorldObjectContextMenu.TireStackActions2)


function ISWorldObjectContextMenu.RefillPropaneTanks(playerObj, squareCoords, spriteName, propaneTanks, objMD)
--	local square = getCell():getGridSquare(squareCoords[1], squareCoords[2], squareCoords[3])
--	if not square then return end
--	local clickedObject = square:getObjectWithSprite(spriteName)
--	if not clickedObject then return end

	local object = MoreCarFeatures.findWholeLargePropaneTank(spriteName, squareCoords[1], squareCoords[2], squareCoords[3])
	if not object then return end
	objMD = object:getModData().MCFPropaneUnits or objMD
	if objMD <= 0 then return end

	if luautils.walkAdjObject(playerObj, object, false, true) then
		for _, propaneTank in ipairs(propaneTanks) do
			ISInventoryPaneContextMenu.equipWeapon(propaneTank, true, false, playerObj:getPlayerNum())
			ISTimedActionQueue.add(ISRefillFromLargePropaneTank:new(playerObj, object, propaneTank, objMD))
		end
	end
end
--The propane lantern bottle holds 20 times more propane than a propane tank
function ISWorldObjectContextMenu.RefillPropaneTanksOptions(playerIndex, context, worldObjects)
	local playerObj = getSpecificPlayer(playerIndex)
	for j=#worldObjects, 1, -1 do
		local v = worldObjects[j]
		local sq = v:getSquare()
		local name = v:getTextureName()
		if name then
			local object = MoreCarFeatures.findWholeLargePropaneTank(name, sq:getX(), sq:getY(), sq:getZ())
			if object then
				local objMD = object:getModData().MCFPropaneUnits or ZombRand(40, 4000)*250
				if objMD > 0 then
					local propaneTanks = {}
					local it = playerObj:getInventory():getItems()
					for i=0, it:size()-1 do
						local item = it:get(i)
						if item:getScriptItem():getFullName() == "Base.PropaneTank" then
					--	if string.contains(item:getType(), "Propane") and item:isItemType(ItemType.Drainable) then
							if round(item:getCurrentUses()/250, 2) < item:getMaxUses()/250 then
								table.insert(propaneTanks, item)
							end
						elseif item:IsInventoryContainer() and item:isEquipped() then
							local it2 = item:getInventory():getItems()
							for i2 = 0, it2:size()-1 do
								local item2 = it2:get(i2)
								if item2:getScriptItem():getFullName() == "Base.PropaneTank" then
							--	if string.contains(item2:getType(), "Propane") and item2:isItemType(ItemType.Drainable) then
									if round(item2:getCurrentUses()/250, 2) < item2:getMaxUses()/250 then
										table.insert(propaneTanks, item2)
									end
								end
							end
						end
					end

					local text = getText("ContextMenu_RefillPropaneTank")
					local basePropaneTankOption = context:addOption(text, worldobjects, nil)
					basePropaneTankOption.itemForTexture = instanceItem("Base.PropaneTank")
					if #propaneTanks == 0 then
						basePropaneTankOption.toolTip = ISInventoryPaneContextMenu.addToolTip()
						basePropaneTankOption.toolTip.description = getText("IGUI_BBQ_NeedsPropaneTank")
						basePropaneTankOption.notAvailable = true
					else
						local PropaneTankContainerMenu = ISContextMenu:getNew(context)
						context:addSubMenu(basePropaneTankOption, PropaneTankContainerMenu)

						local dynamicContainerMenu = PropaneTankContainerMenu
						if #propaneTanks > 1 then
							local text1 = getText("ContextMenu_FillAll")
							PropaneTankContainerMenu:addGetUpOption(text1, playerObj, ISWorldObjectContextMenu.RefillPropaneTanks, {sq:getX(), sq:getY(), sq:getZ()}, name, propaneTanks, objMD)

							local text2 = getText("ContextMenu_FillOne")
							local refillPropaneTankOption = PropaneTankContainerMenu:addOption(text2, worldobjects, nil)
							dynamicContainerMenu = ISContextMenu:getNew(PropaneTankContainerMenu)
							PropaneTankContainerMenu:addSubMenu(refillPropaneTankOption, dynamicContainerMenu)
						end

						for _, propaneTank in ipairs(propaneTanks) do
							local text = propaneTank:getDisplayName()
							local addSoloPropaneTankContainerMenu = dynamicContainerMenu:addGetUpOption(text, playerObj, ISWorldObjectContextMenu.RefillPropaneTanks, {sq:getX(), sq:getY(), sq:getZ()}, name, {propaneTank}, objMD)
							addSoloPropaneTankContainerMenu.iconTexture = propaneTank:getTexture()
							addSoloPropaneTankContainerMenu.toolTip = ISInventoryPaneContextMenu.addToolTip()
							local units = round(propaneTank:getCurrentUses()/25, 2)
							addSoloPropaneTankContainerMenu.toolTip.description = units .. " " .. getText("IGUI_CraftingWindow_UseMultiple")
						--	if units >= propaneTank:getMaxUses()/25 then
						--		addSoloPropaneTankContainerMenu.notAvailable = true
						--	end
						end
					end

					break

				else
					local text = getText("ContextMenu_LargePropaneTankEmpty")
					local basePropaneTankOption = context:addOption(text, worldobjects, nil)
					basePropaneTankOption.itemForTexture = instanceItem("Base.PropaneTank")
					basePropaneTankOption.notAvailable = true

					break
				end
			end
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(ISWorldObjectContextMenu.RefillPropaneTanksOptions)


local function hasReqItemsToRepairFuelPump(playerObj)
	local woodglue
	local it = playerObj:getInventory():getItems()
	for i = 0, it:size()-1 do
		local item = it:get(i)
		if item:getScriptItem():getFullName() == "Base.Woodglue" and item:getUses() == 5 then
			woodglue = item
			break
		elseif item:IsInventoryContainer() and item:isEquipped() then
			local it2 = item:getInventory():getItems()
			for i2 = 0, it2:size()-1 do
				local item2 = it2:get(i2)
				if item2:getScriptItem():getFullName() == "Base.Woodglue" and item2:getUses() == 5 then
					woodglue = item2
					break
				end
			end
			if woodglue then
				break
			end
		end
	end

	local rubberhose = playerObj:getInventory():getFirstTypeRecurse("RubberHose")
 
	if woodglue and rubberhose and playerObj:getPerkLevel(Perks.Maintenance) >= 1 then
		return woodglue, rubberhose
	end
	return nil, nil
end

function ISWorldObjectContextMenu.repairFuelPump(playerObj, fuelStation, dir)
	fuelStation:getModData().FuelPumpsInUseOrBroken = fuelStation:getModData().FuelPumpsInUseOrBroken or {}
	local pumps = fuelStation:getModData().FuelPumpsInUseOrBroken
	for i = #pumps, 1, -1 do
		if pumps[i][1] == dir then
			if not pumps[i][2] then
				HaloTextHelper.addBadText(playerObj, getText("ContextMenu_FuelPumpNotBroken"))
				return
			end
			break
		end
	end

	local woodglue, rubberhose = hasReqItemsToRepairFuelPump(playerObj)
	if not (woodglue and rubberhose) then
		HaloTextHelper.addBadText(playerObj, getText("IGUI_CraftingWindow_Error_Inputs"))
		return
	end

	local square = fuelStation:getSquare()
	local standSquare
	if dir == "N" then
		standSquare = getCell():getOrCreateGridSquare(square:getX()+0.5, square:getY()-0.5, square:getZ())
	elseif dir == "S" then
		standSquare = getCell():getOrCreateGridSquare(square:getX()+0.5, square:getY()+1.5, square:getZ())
	elseif dir == "W" then
		standSquare = getCell():getOrCreateGridSquare(square:getX()-0.5, square:getY()+0.5, square:getZ())
	elseif dir == "E" then
		standSquare = getCell():getOrCreateGridSquare(square:getX()+1.5, square:getY()+0.5, square:getZ())
	end

	ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, standSquare))
	ISInventoryPaneContextMenu.transferIfNeeded(playerObj, woodglue)
	ISInventoryPaneContextMenu.transferIfNeeded(playerObj, rubberhose)
	ISTimedActionQueue.add(ISRepairFuelPump:new(playerObj, fuelStation, standSquare, dir, woodglue, rubberhose))
end

function ISWorldObjectContextMenu.findAndReturnFuelPump(playerObj, fuelStation, dir)
	local pumps = fuelStation:getModData().FuelPumpsInUseOrBroken or {}
	for i = #pumps, 1, -1 do
		if pumps[i][1] == dir and pumps[i][2] then
			HaloTextHelper.addBadText(playerObj, getText("ContextMenu_FuelPumpNotMissingIsBroken"))	--Broken between clicks
			return
		end
	end

	local vehicle = MoreCarFeatures.scanRangeFuelStationInverse(fuelStation, dir)
	if vehicle then
		local part = vehicle:getPartById("GasTank")
		local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}

		if playerObj:getVehicle() then
			ISVehicleMenu.onExit(playerObj)
		end

		local action = ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea())
		action:setOnFail(ISVehiclePartMenu.onPumpGasolinePathFail, playerObj)
		ISTimedActionQueue.add(action)

		if vehicleMD[5] then
			ISTimedActionQueue.add(ISRefuelFromGasPumpToggle:new(playerObj, part, fuelStation, false))
		end

		ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, fuelStation, false))

	elseif vehicle == nil then
		HaloTextHelper.addBadText(playerObj, getText("IGUI_TradingUI_TooFarAway", getText("ContextMenu_FuelPumpTHE")))	--Not finished loading area

	else
		HaloTextHelper.addBadText(playerObj, getText("ContextMenu_FuelPumpNotMissingIsReturned"))	--Returned between clicks
	end
end

--function predicatePetrol(item)
--	return item:getFluidContainer() and item:getFluidContainer():contains(Fluid.Petrol) and (item:getFluidContainer():getAmount() >= 0.099)
--end

local function predicateStoreFuel(item)
	local fluidContainer = item:getFluidContainer()
	if not fluidContainer then
		return false
	end
	if fluidContainer:isEmpty() and not fluidContainer:isInputLocked() then
		return true
	end
	if fluidContainer:contains(Fluid.Petrol) and (fluidContainer:getAmount() < fluidContainer:getCapacity()) and not item:isBroken() then
		return true
	end
	return false
end

local function doAutoFuelPumpContext(playerObj, source, context)
	local pumps = source:getModData().FuelPumpsInUseOrBroken or {}

	local fillOption = context:addOption(getText("ContextMenu_FuelPumpOptions") .. 2-#pumps .. "/2", worldobjects, nil)
	fillOption.iconTexture = getTexture("media/ui/vehicles/vehicle_refuel_from_pump_zoom.png")

	if #pumps ~= 0 then		--Only show more pump options if needed
		local containerMenu = ISContextMenu:getNew(context)
		context:addSubMenu(fillOption, containerMenu)

		local dir = source:getFacing()
		if dir == IsoDirections.S then

			local sideNorth, sideSouth
			for i = #pumps, 1, -1 do
				local pump = pumps[i]
				if pump[1] == "N" then
					sideNorth = pump[2]
				elseif pump[1] == "S" then
					sideSouth = pump[2]
				end
			end

		--North
			local northAvailabilityText, northAvailabilityTexture
			if sideNorth ~= nil then
				northAvailabilityText = getText("ContextMenu_FuelPumpUnavailable")
				if sideNorth then
					northAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_offline1.png")
				else
					northAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_offline2.png")
				end
			else
				northAvailabilityText = getText("ContextMenu_FuelPumpAvailable")
				northAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_online.png")
			end
			local northFillOption = containerMenu:addOption(getText("ContextMenu_FuelPumpStatusN") .. northAvailabilityText, worldobjects, nil)
			northFillOption.iconTexture = northAvailabilityTexture

			if sideNorth ~= nil then
				local northContainerMenu = ISContextMenu:getNew(containerMenu)
				containerMenu:addSubMenu(northFillOption, northContainerMenu)

				if sideNorth then
					local northOption2 = northContainerMenu:addGetUpOption(getText("ContextMenu_FuelPumpRepair"), playerObj, ISWorldObjectContextMenu.repairFuelPump, source, "N")
					northOption2.toolTip = ISInventoryPaneContextMenu.addToolTip()
					northOption2.toolTip.description = getText("ContextMenu_FuelPumpRepairOption")
					if hasReqItemsToRepairFuelPump(playerObj) then
						northOption2.iconTexture = getTexture("media/ui/Sidebar/64/Carpentry_On_64.png")
					else
						northOption2.iconTexture = getTexture("media/ui/Sidebar/64/Carpentry_Off_64.png")
						northOption2.notAvailable = true
					end
				else
					local northOption1 = northContainerMenu:addGetUpOption(getText("ContextMenu_FuelPumpFindReturn"), playerObj, ISWorldObjectContextMenu.findAndReturnFuelPump, source, "N")
					northOption1.toolTip = ISInventoryPaneContextMenu.addToolTip()
					northOption1.toolTip.description = getText("ContextMenu_FuelPumpFindReturnOption")
					northOption1.iconTexture = getTexture("media/ui/Sidebar/64/Search_On_64.png")
				--	northOption1.iconTexture = getTexture("media/ui/Sidebar/64/Search_Off_64.png")
				--	northOption1.notAvailable = true
				end
			end

		--South
			local southAvailabilityText, southAvailabilityTexture
			if sideSouth ~= nil then
				southAvailabilityText = getText("ContextMenu_FuelPumpUnavailable")
				if sideSouth then
					southAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_offline1.png")
				else
					southAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_offline2.png")
				end
			else
				southAvailabilityText = getText("ContextMenu_FuelPumpAvailable")
				southAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_online.png")
			end
			local southFillOption = containerMenu:addOption(getText("ContextMenu_FuelPumpStatusS") .. southAvailabilityText, worldobjects, nil)
			southFillOption.iconTexture = southAvailabilityTexture

			if sideSouth ~= nil then
				local southContainerMenu = ISContextMenu:getNew(containerMenu)
				containerMenu:addSubMenu(southFillOption, southContainerMenu)

				if sideSouth then
					local southOption2 = southContainerMenu:addGetUpOption(getText("ContextMenu_FuelPumpRepair"), playerObj, ISWorldObjectContextMenu.repairFuelPump, source, "S")
					southOption2.toolTip = ISInventoryPaneContextMenu.addToolTip()
					southOption2.toolTip.description = getText("ContextMenu_FuelPumpRepairOption")
					if hasReqItemsToRepairFuelPump(playerObj) then
						southOption2.iconTexture = getTexture("media/ui/Sidebar/64/Carpentry_On_64.png")
					else
						southOption2.iconTexture = getTexture("media/ui/Sidebar/64/Carpentry_Off_64.png")
						southOption2.notAvailable = true
					end
				else
					local southOption1 = southContainerMenu:addGetUpOption(getText("ContextMenu_FuelPumpFindReturn"), playerObj, ISWorldObjectContextMenu.findAndReturnFuelPump, source, "S")
					southOption1.toolTip = ISInventoryPaneContextMenu.addToolTip()
					southOption1.toolTip.description = getText("ContextMenu_FuelPumpFindReturnOption")
					southOption1.iconTexture = getTexture("media/ui/Sidebar/64/Search_On_64.png")
				--	southOption1.iconTexture = getTexture("media/ui/Sidebar/64/Search_Off_64.png")
				--	southOption1.notAvailable = true
				end
			end

		elseif dir == IsoDirections.E then

			local sideWest, sideEast
			for i = #pumps, 1, -1 do
				local pump = pumps[i]
				if pump[1] == "W" then
					sideWest = pump[2]
				elseif pump[1] == "E" then
					sideEast = pump[2]
				end
			end

		--West
			local westAvailabilityText, westAvailabilityTexture
			if sideWest ~= nil then
				westAvailabilityText = getText("ContextMenu_FuelPumpUnavailable")
				if sideWest then
					westAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_offline1.png")
				else
					westAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_offline2.png")
				end
			else
				westAvailabilityText = getText("ContextMenu_FuelPumpAvailable")
				westAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_online.png")
			end
			local westFillOption = containerMenu:addOption(getText("ContextMenu_FuelPumpStatusW") .. westAvailabilityText, worldobjects, nil)
			westFillOption.iconTexture = westAvailabilityTexture

			if sideWest ~= nil then
				local westContainerMenu = ISContextMenu:getNew(containerMenu)
				containerMenu:addSubMenu(westFillOption, westContainerMenu)

				if sideWest then
					local westOption2 = westContainerMenu:addGetUpOption(getText("ContextMenu_FuelPumpRepair"), playerObj, ISWorldObjectContextMenu.repairFuelPump, source, "W")
					westOption2.toolTip = ISInventoryPaneContextMenu.addToolTip()
					westOption2.toolTip.description = getText("ContextMenu_FuelPumpRepairOption")
					if hasReqItemsToRepairFuelPump(playerObj) then
						westOption2.iconTexture = getTexture("media/ui/Sidebar/64/Carpentry_On_64.png")
					else
						westOption2.iconTexture = getTexture("media/ui/Sidebar/64/Carpentry_Off_64.png")
						westOption2.notAvailable = true
					end
				else
					local westOption1 = westContainerMenu:addGetUpOption(getText("ContextMenu_FuelPumpFindReturn"), playerObj, ISWorldObjectContextMenu.findAndReturnFuelPump, source, "W")
					westOption1.toolTip = ISInventoryPaneContextMenu.addToolTip()
					westOption1.toolTip.description = getText("ContextMenu_FuelPumpFindReturnOption")
					westOption1.iconTexture = getTexture("media/ui/Sidebar/64/Search_On_64.png")
				--	westOption1.iconTexture = getTexture("media/ui/Sidebar/64/Search_Off_64.png")
				--	westOption1.notAvailable = true
				end
			end

		--East
			local eastAvailabilityText, eastAvailabilityTexture
			if sideEast ~= nil then
				eastAvailabilityText = getText("ContextMenu_FuelPumpUnavailable")
				if sideEast then
					eastAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_offline1.png")
				else
					eastAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_offline2.png")
				end
			else
				eastAvailabilityText = getText("ContextMenu_FuelPumpAvailable")
				eastAvailabilityTexture = getTexture("media/ui/vehicles/fuel_pump_online.png")
			end
			local eastFillOption = containerMenu:addOption(getText("ContextMenu_FuelPumpStatusE") .. eastAvailabilityText, worldobjects, nil)
			eastFillOption.iconTexture = eastAvailabilityTexture

			if sideEast ~= nil then
				local eastContainerMenu = ISContextMenu:getNew(containerMenu)
				containerMenu:addSubMenu(eastFillOption, eastContainerMenu)

				if sideEast then
					local eastOption2 = eastContainerMenu:addGetUpOption(getText("ContextMenu_FuelPumpRepair"), playerObj, ISWorldObjectContextMenu.repairFuelPump, source, "E")
					eastOption2.toolTip = ISInventoryPaneContextMenu.addToolTip()
					eastOption2.toolTip.description = getText("ContextMenu_FuelPumpRepairOption")
					if hasReqItemsToRepairFuelPump(playerObj) then
						eastOption2.iconTexture = getTexture("media/ui/Sidebar/64/Carpentry_On_64.png")
					else
						eastOption2.iconTexture = getTexture("media/ui/Sidebar/64/Carpentry_Off_64.png")
						eastOption2.notAvailable = true
					end
				else
					local eastOption1 = eastContainerMenu:addGetUpOption(getText("ContextMenu_FuelPumpFindReturn"), playerObj, ISWorldObjectContextMenu.findAndReturnFuelPump, source, "E")
					eastOption1.toolTip = ISInventoryPaneContextMenu.addToolTip()
					eastOption1.toolTip.description = getText("ContextMenu_FuelPumpFindReturnOption")
					eastOption1.iconTexture = getTexture("media/ui/Sidebar/64/Search_On_64.png")
				--	eastOption1.iconTexture = getTexture("media/ui/Sidebar/64/Search_Off_64.png")
				--	eastOption1.notAvailable = true
				end
			end

		end

	end
end

function ISWorldObjectContextMenu.AutoFuelPumpMod(playerIndex, context, worldObjects)
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then return end

	local playerObj = getSpecificPlayer(playerIndex)
	for j=#worldObjects, 1, -1 do
		local v = worldObjects[j]
		if v:getPipedFuelAmount() > 0 then
			local square = v:getSquare()
			if square and (SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (square:hasGridPower())
				and not square:getBuilding() ~= playerObj:getBuilding() and AdjacentFreeTileFinder.Find(square, playerObj)
			--	and (playerObj:getInventory():getAllEvalRecurse(predicateStoreFuel):isEmpty() or playerObj:hasFullInventory())
			then
				doAutoFuelPumpContext(playerObj, v, context)
			end
			break
		end
	end
end
--Events.OnFillWorldObjectContextMenu.Add(ISWorldObjectContextMenu.AutoFuelPumpMod)
Events.OnPreFillWorldObjectContextMenu.Add(ISWorldObjectContextMenu.AutoFuelPumpMod)	--place on top of everything

local ISWorldObjectContextMenuDoFillFuelMenu = ISWorldObjectContextMenu.doFillFuelMenu
ISWorldObjectContextMenu.doFillFuelMenu = function(source, playerNum, context)
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		ISWorldObjectContextMenuDoFillFuelMenu(source, playerNum, context)
		return
	end

--	local playerObj = getSpecificPlayer(playerNum)
--	local square = source:getSquare()
--	if square and not square:getBuilding() ~= playerObj:getBuilding() and AdjacentFreeTileFinder.Find(square, playerObj) then
--		doAutoFuelPumpContext(playerObj, source, context)	--To add once I can consistently add it pre doFillFuelMenu regardless of if player has container for gas
--	end

	local pumps = source:getModData().FuelPumpsInUseOrBroken or {}
	if #pumps < 2 then
		ISWorldObjectContextMenuDoFillFuelMenu(source, playerNum, context)
	end
end

--Decided all these functions needs to be written over, sorta like opening/closing a door when entering a vehicle.
local ISVehiclePartMenuOnAddGasoline = ISVehiclePartMenu.onAddGasoline
function ISVehiclePartMenu.onAddGasoline(playerObj, part)
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		ISVehiclePartMenuOnAddGasoline(playerObj, part)
		return
	end

	local vehicle = part:getVehicle()
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	local typeToItem = VehicleUtils.getItems(playerObj:getPlayerNum())
	local item = ISVehiclePartMenu.getGasCanNotEmpty(playerObj, typeToItem)
	if item then
		ISVehiclePartMenu.toPlayerInventory(playerObj, item)
		ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea()))
		local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
		if vehicleMD[1] then
			local square2
			if vehicleMD[4] and vehicleMD[4][1] and vehicleMD[4][2] then
				square2 = getCell():getOrCreateGridSquare(vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ())
			end
			local oldFuelStation
			if square2 then
				for i=0, square2:getObjects():size()-1 do
					local obj = square2:getObjects():get(i)
					if obj:getPipedFuelAmount() > 0 then
						oldFuelStation = obj
						break
					end
				end
			end
			if not vehicleMD[2] and vehicleMD[5] then
				ISTimedActionQueue.add(ISRefuelFromGasPumpToggle:new(playerObj, part, oldFuelStation, false))
			end
			ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, oldFuelStation, false))
		end
		ISInventoryPaneContextMenu.equipWeapon(item, true, false, playerObj:getPlayerNum())
		ISTimedActionQueue.add(ISAddGasolineToVehicle:new(playerObj, part, item))
	end
end

local ISVehiclePartMenuOnTakeGasoline = ISVehiclePartMenu.onTakeGasoline
function ISVehiclePartMenu.onTakeGasoline(playerObj, part)
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		ISVehiclePartMenuOnTakeGasoline(playerObj, part)
		return
	end

	local vehicle = part:getVehicle()
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	local typeToItem,tagToItem = VehicleUtils.getItems(playerObj:getPlayerNum())
	local item = ISVehiclePartMenu.getGasCanNotFull(playerObj, typeToItem)
	local hose = tagToItem[ItemTag.SIPHON_GAS] and tagToItem[ItemTag.SIPHON_GAS][1]
	if item and hose then
		ISVehiclePartMenu.toPlayerInventory(playerObj, item)
		ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea()))
		local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
		if vehicleMD[1] then
			local square2
			if vehicleMD[4] and vehicleMD[4][1] and vehicleMD[4][2] then
				square2 = getCell():getOrCreateGridSquare(vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ())
			end
			local oldFuelStation
			if square2 then
				for i=0, square2:getObjects():size()-1 do
					local obj = square2:getObjects():get(i)
					if obj:getPipedFuelAmount() > 0 then
						oldFuelStation = obj
						break
					end
				end
			end
			if not vehicleMD[2] and vehicleMD[5] then
				ISTimedActionQueue.add(ISRefuelFromGasPumpToggle:new(playerObj, part, oldFuelStation, false))
			end
			ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, oldFuelStation, false))
		end
		ISInventoryPaneContextMenu.equipWeapon(item, false, false, playerObj:getPlayerNum())
		ISInventoryPaneContextMenu.equipWeapon(hose, true, false, playerObj:getPlayerNum())
		ISTimedActionQueue.add(ISTakeGasolineFromVehicle:new(playerObj, part, item))
	end
end

local ISVehiclePartMenuOnTakeFuelNew = ISVehiclePartMenu.onTakeFuelNew
ISVehiclePartMenu.onTakeFuelNew = function(worldobjects, part, fuelContainerList, fuelContainer, player)
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		ISVehiclePartMenuOnTakeFuelNew(worldobjects, part, fuelContainerList, fuelContainer, player)
		return
	end

	local playerObj = getSpecificPlayer(player)
	local vehicle = part:getVehicle()
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	if not fuelContainer and #fuelContainerList > 1 then
		fuelContainer = table.remove(fuelContainerList, 1)
	end
	ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea()))
	if fuelContainer and part:getContainerContentAmount() > 0 then
		local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
		if vehicleMD[1] then
			local square2
			if vehicleMD[4] and vehicleMD[4][1] and vehicleMD[4][2] then
				square2 = getCell():getOrCreateGridSquare(vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ())
			end
			local oldFuelStation
			if square2 then
				for i=0, square2:getObjects():size()-1 do
					local obj = square2:getObjects():get(i)
					if obj:getPipedFuelAmount() > 0 then
						oldFuelStation = obj
						break
					end
				end
			end
			if not vehicleMD[2] and vehicleMD[5] then
				ISTimedActionQueue.add(ISRefuelFromGasPumpToggle:new(playerObj, part, oldFuelStation, false))
			end
			ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, oldFuelStation, false))
		end
		ISVehiclePartMenu.toPlayerInventory(playerObj, fuelContainer)
		ISInventoryPaneContextMenu.equipWeapon(fuelContainer, false, false, playerObj:getPlayerNum())
		ISTimedActionQueue.add(ISTakeGasolineFromVehicle:new(playerObj, part, fuelContainer, fuelContainerList))
	end
end

local ISVehiclePartMenuOnAddFuelNew = ISVehiclePartMenu.onAddFuelNew
ISVehiclePartMenu.onAddFuelNew = function(worldobjects, part, fuelContainerList, fuelContainer, player)
	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		ISVehiclePartMenuOnAddFuelNew(worldobjects, part, fuelContainerList, fuelContainer, player)
		return
	end

	local playerObj = getSpecificPlayer(player)
	local vehicle = part:getVehicle()
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	if not fuelContainer and #fuelContainerList > 1 then
		fuelContainer = table.remove(fuelContainerList, 1)
	end
	ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea()))
	if fuelContainer and part:getContainerContentAmount() < part:getContainerCapacity() then
		local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
		if vehicleMD[1] then
			local square2
			if vehicleMD[4] and vehicleMD[4][1] and vehicleMD[4][2] then
				square2 = getCell():getOrCreateGridSquare(vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ())
			end
			local oldFuelStation
			if square2 then
				for i=0, square2:getObjects():size()-1 do
					local obj = square2:getObjects():get(i)
					if obj:getPipedFuelAmount() > 0 then
						oldFuelStation = obj
						break
					end
				end
			end
			if not vehicleMD[2] and vehicleMD[5] then
				ISTimedActionQueue.add(ISRefuelFromGasPumpToggle:new(playerObj, part, oldFuelStation, false))
			end
			ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, oldFuelStation, false))
		end
		ISVehiclePartMenu.toPlayerInventory(playerObj, fuelContainer)
		ISInventoryPaneContextMenu.equipWeapon(fuelContainer, true, false, playerObj:getPlayerNum())
		ISTimedActionQueue.add(ISAddGasolineToVehicle:new(playerObj, part, fuelContainer, fuelContainerList))
	end
end

function ISVehiclePartMenu.onInsertFuelPump(playerObj, part)
	local vehicle = part:getVehicle()
	local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
	if vehicleMD[1] then return end

	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end

	local fuelStation = ISVehiclePartMenu.getNearbyFuelPump(vehicle, true)
	if fuelStation then
		local action = ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea())
		action:setOnFail(ISVehiclePartMenu.onPumpGasolinePathFail, playerObj)
		ISTimedActionQueue.add(action)
		ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, fuelStation, true))
	elseif fuelStation == false then
		HaloTextHelper.addBadText(playerObj, getText("ContextMenu_FuelPumpInUseBroken2"))
	end
end

function ISVehiclePartMenu.onRemoveFuelPump(playerObj, part)
	local vehicle = part:getVehicle()
	local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
	if not vehicleMD[1] then return end

	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end

	local square2
	if vehicleMD[4] and vehicleMD[4][1] and vehicleMD[4][2] then
		square2 = getCell():getOrCreateGridSquare(vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ())
	end
	local oldFuelStation
	if square2 then
		for i=0, square2:getObjects():size()-1 do
			local obj = square2:getObjects():get(i)
			if obj:getPipedFuelAmount() > 0 then
				oldFuelStation = obj
				break
			end
		end
	end

	local action = ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea())
	action:setOnFail(ISVehiclePartMenu.onPumpGasolinePathFail, playerObj)
	ISTimedActionQueue.add(action)

	if vehicleMD[5] then
		ISTimedActionQueue.add(ISRefuelFromGasPumpToggle:new(playerObj, part, oldFuelStation, false))
	end

	ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, oldFuelStation, false))
end

function ISVehiclePartMenu.onStopPumpGasoline(playerObj, part)
	local vehicle = part:getVehicle()
	local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
	if not vehicleMD[1] or vehicleMD[2] or not vehicleMD[5] then return end

	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end

	if vehicleMD[4] and vehicleMD[4][1] and vehicleMD[4][2] then
		local square2 = getCell():getOrCreateGridSquare(vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ())
		if square2 then
			for i=0, square2:getObjects():size()-1 do
				local obj = square2:getObjects():get(i)
				if obj:getPipedFuelAmount() > 0 then
					if MoreCarFeatures.scanRangeFuelStation(vehicle, obj) then
						local action = ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea())
						action:setOnFail(ISVehiclePartMenu.onPumpGasolinePathFail, playerObj)
						ISTimedActionQueue.add(action)
						ISTimedActionQueue.add(ISRefuelFromGasPumpToggle:new(playerObj, part, obj, false))
					end
					break
				end
			end
		end
	end
end

function ISVehiclePartMenu.onStartPumpGasoline(playerObj, part)
	local vehicle = part:getVehicle()
	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end

	local fuelStation = ISVehiclePartMenu.getNearbyFuelPump(vehicle, true)
	if fuelStation then
		local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
		if vehicleMD[5] then return end
		local square2
		if vehicleMD[4] and vehicleMD[4][1] and vehicleMD[4][2] then
			square2 = getCell():getOrCreateGridSquare(vehicleMD[4][1], vehicleMD[4][2], vehicle:getZ())
		end
		local oldFuelStation
		if square2 then
			for i=0, square2:getObjects():size()-1 do
				local obj = square2:getObjects():get(i)
				if obj:getPipedFuelAmount() > 0 then
					oldFuelStation = obj
					break
				end
			end
		end

		local action = ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea())
		action:setOnFail(ISVehiclePartMenu.onPumpGasolinePathFail, playerObj)
		ISTimedActionQueue.add(action)
		if vehicleMD[2] then
			ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, oldFuelStation, false))
			ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, fuelStation, true))
		elseif not vehicleMD[1] then
			ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, fuelStation, true))
		end
		ISTimedActionQueue.add(ISRefuelFromGasPumpToggle:new(playerObj, part, fuelStation, true))
	--	ISTimedActionQueue.add(ISInsertOrRemoveFuelPump:new(playerObj, part, oldFuelStation, false))

	elseif fuelStation == false then
		HaloTextHelper.addBadText(playerObj, getText("ContextMenu_FuelPumpInUseBroken2"))
	end
end


local insideParts = {
	"Radio",
	"SeatFrontLeft",
	"SeatFrontRight",
	"SeatMiddleLeft",
	"SeatMiddleRight",
	"SeatRearLeft",
	"SeatRearRight",
}

--function ISVehiclePartMenu.onUninstallPartInside(playerObj, part, item)
--	local tbl = part:getTable("uninstall")
--	ISVehiclePartMenu.transferRequiredItems(playerObj, part, tbl)
--	ISVehiclePartMenu.equipRequiredItems(playerObj, part, tbl)
--
--	local keyvalues = part:getTable("install")
--	local time = tonumber(keyvalues.time) or 50
--	ISTimedActionQueue.add(ISUninstallVehiclePart:new(playerObj, part, time))
--end
--
--function ISVehiclePartMenu.onInstallPartInside(playerObj, part, item)
--	local tbl = part:getTable("install")
--	ISVehiclePartMenu.transferRequiredItems(playerObj, part, tbl)
--	ISVehiclePartMenu.equipRequiredItems(playerObj, part, tbl)
--
--	local keyvalues = part:getTable("install")
--	local time = tonumber(keyvalues.time) or 50
--	ISTimedActionQueue.add(ISInstallVehiclePart:new(playerObj, part, item, time - (playerObj:getPerkLevel(Perks.Mechanics) * (time/15))))
--end

function ISVehicleMenu.TirePumpMechanic(playerObj, vehicle)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu:clear()

--	if vehicle == playerObj:getVehicle() then		--return handles after for now
	--	for _, partId in ipairs(insideParts) do
	--		local insidePart = vehicle:getPartById(partId)
	
	--	end
--	else
	if not playerObj:getVehicle() then
		local multiFULLTires = 0
		local multiFLATTires = 0
		local closestTire
		local closestWheelPart
		for i = 0, vehicle:getPartCount() - 1 do
			local wheelPart = vehicle:getPartByIndex(i)
			if wheelPart and wheelPart:getCategory() == "tire" and wheelPart:getId():contains("Tire") and wheelPart:getItemType() and not wheelPart:getItemType():isEmpty() then
				local testTire = vehicle:getAreaCenter(wheelPart:getArea())
				local dx = testTire:getX() - playerObj:getX()
				local dy = testTire:getY() - playerObj:getY()
				testTire = math.sqrt(dx*dx + dy*dy)
				if wheelPart:getContainerContentAmount() > 0 then
					multiFULLTires = multiFULLTires + 1
				end
				if wheelPart:getContainerContentAmount() < wheelPart:getContainerCapacity() then
					multiFLATTires = multiFLATTires + 1
				end
				if not closestTire or testTire < closestTire then
					closestTire = testTire
					closestWheelPart = wheelPart
				end
			end
		end
		if closestWheelPart and closestWheelPart:getInventoryItem() and closestWheelPart:getTable("uninstall") then
			if closestWheelPart:getContainerContentAmount() > 0 then
				menu:addSlice(getText("IGUI_DeflateTire"), getTexture("media/ui/vehicles/vehicle_deflate_single.png"), ISVehiclePartMenu.onDeflateTire, playerObj, closestWheelPart)
			end
			if multiFULLTires > 0 then
				menu:addSlice(getText("ContextMenu_DeflateTireALL"), getTexture("media/ui/vehicles/vehicle_deflate_multi.png"), ISVehiclePartMenu.onDeflateTireALL, playerObj, vehicle)
			end
			if closestWheelPart:getContainerContentAmount() < closestWheelPart:getContainerCapacity() then
				if ISVehicleMechanics:getTirePump(playerObj) then
					menu:addSlice(getText("IGUI_InflateTire"), getTexture("media/ui/vehicles/vehicle_inflate_single.png"), ISVehiclePartMenu.onInflateTire, playerObj, closestWheelPart)
				else
					menu:addSlice(getText("ContextMenu_ReqTirePump"), getTexture("media/ui/vehicles/vehicle_inflate_single.png"), nil, playerObj, closestWheelPart)
				end
			end
			if multiFLATTires > 0 then
				if ISVehicleMechanics:getTirePump(playerObj) then
					menu:addSlice(getText("ContextMenu_InflateTireALL"), getTexture("media/ui/vehicles/vehicle_inflate_multi.png"), ISVehiclePartMenu.onInflateTireALL, playerObj, vehicle)
				else
					menu:addSlice(getText("ContextMenu_ReqTirePump"), getTexture("media/ui/vehicles/vehicle_inflate_multi.png"), nil, playerObj, vehicle)
				end
			end
		end
		if not menu:isEmpty() then
			menu:addSlice(getText("IGUI_Emote_Back"), getTexture("media/ui/vehicles/vehicle_back_blue_button.png"), ISVehicleMenu.BackToVehRadialMenu, playerObj)
		else
			menu:addSlice(getText("ContextMenu_MissingTires"), getTexture("media/ui/vehicles/vehicle_back_red_button.png"), ISVehicleMenu.BackToVehRadialMenu, playerObj)
		end
	end

	if menu:isEmpty() then return end

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()

	getSoundManager():playUISound("UIVehicleMenuOpen")
	menu.sounds.undisplay = "UIVehicleMenuClose"

	if JoypadState.players[playerIndex+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerIndex, menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end

end

function ISVehicleMenu.LinkCarBombRemote(vehicle, playerObj, remote, plantType)
	playerObj:faceThisObject(vehicle)
	local CarBombSlotsMD = vehicle:getModData().CarBombSlots or {}
	if CarBombSlotsMD[plantType] and instanceItem(CarBombSlotsMD[plantType][1]):canBeRemote() then
		if remote:getRemoteControlID() == -1 then
			remote:setRemoteControlID(ZombRand(100000))
			remote:syncItemFields()
		end
		if isClient() then
			local args = { vehicleId = vehicle:getId(), plantPOS = plantType, remoteID = remote:getRemoteControlID() }
			sendClientCommand(playerObj, "MoreCarFeatures", "CarBombTransmitModData", args)
		else
			vehicle:getModData().CarBombSlots[plantType][3] = remote:getRemoteControlID()
		end
		local text = remote:getDisplayName() .. " " .. getText("ContextMenu_CarBombToLink")
		HaloTextHelper.addGoodText(playerObj, text)
	else
		HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombNone"))
	end
end

--TODO: Chance To Fail and Explode Yourself if Under-Leveled?
function ISVehicleMenu.FindOrPlaceCarBomb(vehicle, playerObj, bomb, plantType)
	playerObj:faceThisObject(vehicle)
	local bombRemoval
	if vehicle:getModData().CarBombSlots then
		bombRemoval = vehicle:getModData().CarBombSlots[plantType]
	end
	if bomb then
		local part = vehicle:getPartById(plantType)
		if bombRemoval and bombRemoval[1] then
			HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombSome"))
			return
		elseif plantType == "Ignition" and (vehicle:isEngineRunning() or vehicle:isEngineStarted()) then
			HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombIgnCarOn"))
			return
		elseif string.contains(bomb:getScriptItem():getFullName(), "Sensor") and (playerObj:getPerkLevel(Perks.Electricity) < 4 or playerObj:getPerkLevel(Perks.Mechanics) < 3) then
			HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombSkillPlant"))
			return
		end
		if bomb:canBeRemote() then
			bomb:setRemoteControlID(-1)
			bomb:syncItemFields()
		end
		HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombPlanting") .. "...")
		ISTimedActionQueue.add(ISRemoveOrPlaceCarBomb:new(playerObj, vehicle, bomb, plantType))
	else
		if not bombRemoval or not bombRemoval[1] then
			HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombNone"))
			return
		elseif string.contains(bombRemoval[1], "Sensor") and (playerObj:getPerkLevel(Perks.Electricity) < 5 or playerObj:getPerkLevel(Perks.Mechanics) < 2) then
			HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombSkillRemove"))
			return
		end
		HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombRemoving") .. "...")
		ISTimedActionQueue.add(ISRemoveOrPlaceCarBomb:new(playerObj, vehicle, nil, plantType))
	end
end

function ISVehicleMenu.FindOrPlaceCarBombMultiSearch(vehicle, playerObj, plantType)
	local bombRemoval
	if vehicle:getModData().CarBombSlots then
		bombRemoval = vehicle:getModData().CarBombSlots[plantType]
	end
	if not bombRemoval or not bombRemoval[1] then
		return "1"
	elseif string.contains(bombRemoval[1], "Sensor") and (playerObj:getPerkLevel(Perks.Electricity) < 5 or playerObj:getPerkLevel(Perks.Mechanics) < 2) then
		return "2"
	end
	return "3"
end

function ISVehicleMenu.CarBombMultiSearchPerEndingText(playerObj, ending)
	if ending == "1" then	--Text doesn't vanish quick enough to have this spamming per check
	--	HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombNone"))
	elseif ending == "2" then
		HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombSkillRemove"))
	elseif ending == "3" then
		HaloTextHelper.addBadText(playerObj, getText("ContextMenu_CarBombRemoving") .. "...")
	end
end

function ISVehicleMenu.PlantExplosiveDeviceAction(vehicle, playerObj, part, item, position)
	local PathAction
	if part then
		PathAction = ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea())
	else
		PathAction = ISPathFindAction:pathToVehicleAdjacent(playerObj, vehicle)
	end

	if item and item:isRemoteController() then
		PathAction:setOnComplete(ISVehicleMenu.LinkCarBombRemote, vehicle, playerObj, item, position)
	else
		PathAction:setOnComplete(ISVehicleMenu.FindOrPlaceCarBomb, vehicle, playerObj, item, position)
	end
	ISTimedActionQueue.add(PathAction)
end

function ISVehicleMenu.PlantExplosiveDeviceActionMultiSearch(vehicle, playerObj, part, position)
	local ending = ISVehicleMenu.FindOrPlaceCarBombMultiSearch(vehicle, playerObj, position)

	local PathAction
	if part then
		PathAction = ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea())
	else
		PathAction = ISPathFindAction:pathToVehicleAdjacent(playerObj, vehicle)
	end

	PathAction:setOnComplete(ISVehicleMenu.CarBombMultiSearchPerEndingText, playerObj, ending)
	ISTimedActionQueue.add(PathAction)

	if ending == "3" then
		ISTimedActionQueue.add(ISRemoveOrPlaceCarBomb:new(playerObj, vehicle, nil, position))
	end
end

function ISVehicleMenu.SearchToRemoveCarBombs(playerObj, vehicle)
	local leftParts = {}
	local rightParts = {}
	local otherParts = {}
	for i = 0, vehicle:getPartCount() - 1 do
		local part = vehicle:getPartByIndex(i)
		if part and ((part:getCategory() == "tire" and part:getId():contains("Tire")) or (part:getDoor() and (not part:getInventoryItem() or part:getDoor():isOpen()))) then
			local pos = vehicle:getAreaCenter(part:getArea())
			local dx = pos:getX() - playerObj:getX()
			local dy = pos:getY() - playerObj:getY()
			local dist = math.sqrt(dx * dx + dy * dy)
			local partInfo = {
				part = part,
				x = pos:getX(),
				y = pos:getY(),
				dist = dist,
			}
			if part:getId():contains("Left") then
				table.insert(leftParts, partInfo)
			elseif part:getId():contains("Right") then
				table.insert(rightParts, partInfo)
			else
				table.insert(otherParts, partInfo)
			end
		end
	end

	if #leftParts > 0 or #rightParts > 0 or #otherParts > 0 then
		local driverDoor = vehicle:getPassengerDoor(0)
		local sortedParts = ISVehicleMenu.EfficientVehiclePartPathingSides(leftParts, rightParts, otherParts)
		for _, part in ipairs(sortedParts) do
			ISVehicleMenu.PlantExplosiveDeviceActionMultiSearch(vehicle, playerObj, part, part:getId())
			if part == driverDoor then
				ISVehicleMenu.PlantExplosiveDeviceActionMultiSearch(vehicle, playerObj, driverDoor, "Ignition")
			end
		end
	end
	ISVehicleMenu.PlantExplosiveDeviceActionMultiSearch(vehicle, playerObj, nil, "Chasis")
end

function ISVehicleMenu.ExplosiveDeviceTypeMechanic(playerObj, vehicle, part, position)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu:clear()

--	if vehicle == playerObj:getVehicle() then		--return handles after for now
	--	for _, partId in ipairs(insideParts) do
	--		local insidePart = vehicle:getPartById(partId)
	
	--	end
--	else
	if not playerObj:getVehicle() then
		local basetext = getText("ContextMenu_CarBombSearchRemove") .. getText("ContextMenu_CarBombExplosiveDevice")
		menu:addSlice(basetext, instanceItem("Base.PipeBomb"):getTexture(), ISVehicleMenu.PlantExplosiveDeviceAction, vehicle, playerObj, part, nil, position)

		local repeatControllers = {}
		local repeatBombs = {}
		local CarBombSlotsMD = vehicle:getModData().CarBombSlots or {}
		local it = playerObj:getInventory():getItems()

		if not (position == "Ignition" or (part and part:getDoor())) then
			for i = 0, it:size()-1 do
				local item = it:get(i)
				local itemName = item:getScriptItem():getFullName()
				if item:isRemoteController() and not repeatControllers[itemName]then
					repeatControllers[itemName] = true
					local text = getText("ContextMenu_CarBombLinkTo") .. item:getDisplayName()
					menu:addSlice(text, item:getTexture(), ISVehicleMenu.PlantExplosiveDeviceAction, vehicle, playerObj, part, item, position)
				end
			end
		end

		for i = 0, it:size()-1 do
			local item = it:get(i)
			local itemName = item:getScriptItem():getFullName()
			if item:getCategory() == "Weapon" and string.contains(itemName, "Bomb") and not string.contains(itemName, "Timer") and not repeatBombs[itemName] then
				local remote, sensor = false, false
				if item:canBeRemote() then
					remote = true
				elseif string.contains(itemName, "Sensor") then
					sensor = true
				end
				local posTypeSensor = false
				if part and part:getDoor() then
					posTypeSensor = true
				end
				local add = true
				if posTypeSensor and not sensor then
					add = false
				elseif sensor and not posTypeSensor then
					add = false
				elseif not (remote or sensor) then
					add = false
				end
				if add then
					repeatBombs[itemName] = true
					local text = getText("ContextMenu_CarBombPlant") .. item:getDisplayName()
					menu:addSlice(text, item:getTexture(), ISVehicleMenu.PlantExplosiveDeviceAction, vehicle, playerObj, part, item, position)
				end
			end
		end

		if not menu:isEmpty() then
			menu:addSlice(getText("IGUI_Emote_Back"), getTexture("media/ui/vehicles/vehicle_back_blue_button.png"), ISVehicleMenu.BackToPlantLocationMechanic, playerObj, vehicle, remote, sensor)
		else
			menu:addSlice(getText("ContextMenu_CarBombNoExplosiveDevices"), getTexture("media/ui/vehicles/vehicle_back_red_button.png"), ISVehicleMenu.BackToVehRadialMenu, playerObj)
		end
	end

	if menu:isEmpty() then return end

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()

	getSoundManager():playUISound("UIVehicleMenuOpen")
	menu.sounds.undisplay = "UIVehicleMenuClose"

	if JoypadState.players[playerIndex+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerIndex, menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end

end

function ISVehicleMenu.PlantLocationMechanic(playerObj, vehicle)
	local playerIndex = playerObj:getPlayerNum()
	local menu = getPlayerRadialMenu(playerIndex)
	menu:clear()

--	if vehicle == playerObj:getVehicle() then		--return handles after for now
	--	for _, partId in ipairs(insideParts) do
	--		local insidePart = vehicle:getPartById(partId)
	
	--	end
--	else
	if not playerObj:getVehicle() then
		local basetext1 = getText("ContextMenu_CarBombPlantLink") .. getText("ContextMenu_CarBombExplosiveDeviceBR") .. getText("ContextMenu_CarBombUnderVehicle")
		menu:addSlice(basetext1, getTexture("media/ui/vehicles/vehicle_hood_under.png"), ISVehicleMenu.ExplosiveDeviceTypeMechanic, playerObj, vehicle, nil, "Chasis")

		local closestTireDist
		local closestWheelPart
		for i=0, vehicle:getScript():getPartCount()-1 do
			local wheelPart = vehicle:getPartByIndex(i)
			if wheelPart and wheelPart:getCategory() == "tire" and wheelPart:getId():contains("Tire") then
				local testTire = vehicle:getAreaCenter(wheelPart:getArea())
				local dx = testTire:getX() - playerObj:getX()
				local dy = testTire:getY() - playerObj:getY()
				testTire = math.sqrt(dx*dx + dy*dy)
				if not closestTireDist or testTire < closestTireDist then
					closestTireDist = testTire
					closestWheelPart = wheelPart
				end
			end
		end
		if closestWheelPart then
			local text = getText("ContextMenu_CarBombPlantLink") .. getText("ContextMenu_CarBombExplosiveDeviceBR") .. getText("ContextMenu_CarBombAboveWheel")
			menu:addSlice(text, getTexture("media/ui/vehicles/vehicle_wheel_model.png"), ISVehicleMenu.ExplosiveDeviceTypeMechanic, playerObj, vehicle, closestWheelPart, closestWheelPart:getId())
		end

		local doorPart = vehicle:getUseablePart(playerObj)
		if doorPart and doorPart:getDoor() then
			if doorPart == vehicle:getPassengerDoor(0) and (not doorPart:getInventoryItem() or doorPart:getDoor():isOpen()) then
				local text = getText("ContextMenu_CarBombPlant") .. getText("ContextMenu_CarBombExplosiveDeviceBR") .. getText("ContextMenu_CarBombInIgnition")
				menu:addSlice(text, getTexture("media/ui/vehicles/Ignition_unhotwiredSkill.png"), ISVehicleMenu.ExplosiveDeviceTypeMechanic, playerObj, vehicle, doorPart, "Ignition")
			end
			if not doorPart:getInventoryItem() or doorPart:getDoor():isOpen() then
				local text = getText("ContextMenu_CarBombPlant") .. getText("ContextMenu_CarBombExplosiveDeviceBR") .. getText("ContextMenu_CarBombInDoor")
				menu:addSlice(text, getTexture("media/ui/vehicles/vehicle_exit.png"), ISVehicleMenu.ExplosiveDeviceTypeMechanic, playerObj, vehicle, doorPart, doorPart:getId())
			end
		end

		local basetext2 = getText("ContextMenu_CarBombSearchRemove") .. getText("ContextMenu_CarBombExplosiveDevicePlural")
		menu:addSlice(basetext2, getTexture("media/ui/vehicles/vehicle_around.png"), ISVehicleMenu.SearchToRemoveCarBombs, playerObj, vehicle)

		if not menu:isEmpty() then
			menu:addSlice(getText("IGUI_Emote_Back"), getTexture("media/ui/vehicles/vehicle_back_blue_button.png"), ISVehicleMenu.BackToVehRadialMenu, playerObj)
		else
			menu:addSlice(getText("ContextMenu_CarBombNoPlantSpot"), getTexture("media/ui/vehicles/vehicle_back_red_button.png"), ISVehicleMenu.BackToVehRadialMenu, playerObj)
		end
	end

	if menu:isEmpty() then return end

	menu:setX(getPlayerScreenLeft(playerIndex) + getPlayerScreenWidth(playerIndex) / 2 - menu:getWidth() / 2)
	menu:setY(getPlayerScreenTop(playerIndex) + getPlayerScreenHeight(playerIndex) / 2 - menu:getHeight() / 2)
	menu:addToUIManager()

	getSoundManager():playUISound("UIVehicleMenuOpen")
	menu.sounds.undisplay = "UIVehicleMenuClose"

	if JoypadState.players[playerIndex+1] then
		menu:setHideWhenButtonReleased(Joypad.DPadUp)
		setJoypadFocus(playerIndex, menu)
		playerObj:setJoypadIgnoreAimUntilCentered(true)
	end

end

local ISVehicleMenuShowRadialMenu = ISVehicleMenu.showRadialMenu
function ISVehicleMenu.showRadialMenu(playerObj)
	ISVehicleMenuShowRadialMenu(playerObj)

	local isPaused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
	if isPaused then return end

	local vehicle = playerObj:getVehicle()
	if not vehicle then return end

	local menu = getPlayerRadialMenu(playerObj:getPlayerNum())

--Exit through vehicle trunk if accessible
	--for partIndex=1, vehicle:getPartCount() do
	--	local vehiclePart = vehicle:getPartByIndex(partIndex-1)
	--	if vehiclePart:getItemContainer() and vehicle:canAccessContainer(partIndex-1, playerObj) and vehiclePart:getId() == "TruckBed" then
	--		menu:addSlice(getText("IGUI_ExitVehicle"), getTexture("media/ui/vehicles/vehicle_cartrunkopen.png"), ISVehicleMenu.onExitTrunk, playerObj, vehiclePart)
	--		break
	--	end
	--end
	local seat = vehicle:getSeat(playerObj)

	local fullVName = vehicle:getScript():getFullName()
	if MoreCarFeatures.canEnterExitVehicleTrunk[fullVName] then
		if vehicle:getMaxPassengers() <= 2 or vehicle:getPassengerArea(seat):contains("SeatRear") then
			menu:addSlice(getText("IGUI_ExitVehicle"), getTexture("media/ui/vehicles/vehicle_cartrunkopen.png"), ISVehicleMenu.onExitTrunk, playerObj, vehicle:getPartById("TruckBed"))
		end
	elseif MoreCarFeatures.canEnterExitVehicleTrunkKI51[fullVName] then
		if seat >= 0 then
			menu:addSlice(getText("IGUI_ExitVehicle"), getTexture("media/ui/vehicles/vehicle_cartrunkopen.png"), ISVehicleMenu.onExitTrunk, playerObj, vehicle:getPartById("TruckBed"))
		end
	elseif MoreCarFeatures.canEnterExitVehicleTrunkKI52[fullVName] then
		if seat == 2 or seat == 3 then
			menu:addSlice(getText("IGUI_ExitVehicle"), getTexture("media/ui/vehicles/vehicle_cartrunkopen.png"), ISVehicleMenu.onExitTrunk, playerObj, vehicle:getPartById("TruckBed"))
		end
	elseif MoreCarFeatures.canEnterExitVehicleTrunkKI53[fullVName] then
		if seat == 4 or seat == 5 then
			menu:addSlice(getText("IGUI_ExitVehicle"), getTexture("media/ui/vehicles/vehicle_cartrunkopen.png"), ISVehicleMenu.onExitTrunk, playerObj, vehicle:getPartById("TruckBed"))
		end
	end

--Adds individual door locking/unlocking and closing/opening according to your seat in a vehicle, submenu these (only shows 2 at a time, already have just door icon for main)?
	local doorPart = vehicle:getPassengerDoor(seat)
	if doorPart and doorPart:getDoor() and doorPart:getInventoryItem() then
		local hasModForDoors = activatedMods:contains("B42FRUsedCarsAnimAlpha")	--3683878228
		if doorPart:getDoor():isOpen() then
			if not hasModForDoors then
				menu:addSlice(getText("ContextMenu_Close_door"), getTexture("media/ui/vehicles/vehicle_exit.png"), ISVehicleMenu.onCloseDoor, playerObj, doorPart)
			end
		else
			if not hasModForDoors then
				menu:addSlice(getText("ContextMenu_Open_door"), getTexture("media/ui/vehicles/vehicle_exit.png"), ISVehicleMenu.onOpenDoor, playerObj, doorPart)
			end

			if vehicle:canUnlockDoor(doorPart, playerObj) then
				menu:addSlice(getText("ContextMenu_UnlockDoor"), getTexture("media/ui/vehicles/vehicle_lockdoors.png"), ISVehicleMenu.onUnlockDoor, playerObj, doorPart)
			elseif vehicle:canLockDoor(doorPart, playerObj) then
				menu:addSlice(getText("ContextMenu_LockDoor"), getTexture("media/ui/vehicles/vehicle_lockdoors.png"), ISVehicleMenu.onLockDoor, playerObj, doorPart)
			end
		end
	end

--Adds unhotwire stuff
	if vehicle:isDriver(playerObj) and
			not vehicle:isEngineStarted() and
			not vehicle:isEngineRunning() and
			vehicle:isHotwired() then
		if playerObj:getPerkLevel(Perks.Electricity) >= 3 and playerObj:getPerkLevel(Perks.Mechanics) >= 2 then
			menu:addSlice(getText("ContextMenu_VehicleUnHotwire"), getTexture("media/ui/vehicles/Ignition_unhotwiredSkill.png"), ISVehicleMenu.ISUnHotwireVehicle, playerObj)
		else
			menu:addSlice(getText("ContextMenu_VehicleUnHotwireSkill"), getTexture("media/ui/vehicles/Ignition_hotwiredSkill.png"), nil, playerObj)
		end
	end

end

--fuel pump nozzle, ISWorldObjectContextMenu
local ISVehicleMenuFillPartMenu = ISVehicleMenu.FillPartMenu
function ISVehicleMenu.FillPartMenu(playerIndex, context, slice, vehicle)
	ISVehicleMenuFillPartMenu(playerIndex, context, slice, vehicle)

	if not SandboxVars.GamestaVehicleZones.autoVehicleFuelPumps then
		return
	end

	local playerObj = getSpecificPlayer(playerIndex)
	if playerObj:DistToProper(vehicle) >= 4 then
		return
	end

	for i = 0, vehicle:getPartCount() - 1 do
		local part = vehicle:getPartByIndex(i)
		if part:isContainer() and part:getContainerContentType() == "Gasoline" then
			local vehicleMD = vehicle:getModData().statusFuelPumpNozzle or {}
			local fuelStation = ISVehiclePartMenu.getNearbyFuelPump(vehicle, true)
			local square

			if fuelStation then
				square = fuelStation:getSquare()
				if ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (square:hasGridPower())) and part:getContainerContentAmount() < part:getContainerCapacity() then
					if not vehicleMD[5] then
						local text
						if not vehicleMD[1] then
							if slice then
								text = getText("ContextMenu_VehicleInsertEnableFuelPump1")
							else
								text = getText("ContextMenu_VehicleInsertEnableFuelPump2")
							end
						else
							if not vehicleMD[2] then
								text = getText("ContextMenu_VehicleEnableFuelPump")
							else
								if slice then
									text = getText("ContextMenu_VehicleInsertEnableFuelPump3")
								else
									text = getText("ContextMenu_VehicleInsertEnableFuelPump4")
								end
							end
						end
						if slice then
							slice:addSlice(text, getTexture("media/ui/vehicles/vehicle_start_fuel_pump.png"), ISVehiclePartMenu.onStartPumpGasoline, playerObj, part)
						else
							context:addOption(text, playerObj, ISVehiclePartMenu.onStartPumpGasoline, part)
						end
					else
						if slice then
							slice:addSlice(getText("ContextMenu_VehicleDisableFuelPump"), getTexture("media/ui/vehicles/vehicle_stop_fuel_pump.png"), ISVehiclePartMenu.onStopPumpGasoline, playerObj, part)
						else
							context:addOption(getText("ContextMenu_VehicleDisableFuelPump"), playerObj, ISVehiclePartMenu.onStopPumpGasoline, part)
						end
					end
				end
			end
			if fuelStation == false then
				if slice then
					slice:addSlice(getText("ContextMenu_FuelPumpInUseBroken1"), getTexture("media/ui/vehicles/vehicle_refuel_from_pump_zoom.png"), nil, playerObj, part)
				else
					local option = context:addOption(getText("ContextMenu_VehicleRefuelFromPump"), playerObj, nil, part)
					option.notAvailable = true
					option.toolTip = ISInventoryPaneContextMenu.addToolTip()
					option.toolTip.description = getText("ContextMenu_FuelPumpInUseBroken2")
				end
			end

			if vehicleMD[1] then
				local text
				if vehicleMD[5] then
					if slice then
						text = getText("ContextMenu_VehicleRemoveDisableFuelPump1")
					else
						text = getText("ContextMenu_VehicleRemoveDisableFuelPump2")
					end
				else
					text = getText("ContextMenu_VehicleRemoveFuelPump")
				end
				if slice then
					slice:addSlice(text, getTexture("media/ui/vehicles/vehicle_remove_fuel_pump.png"), ISVehiclePartMenu.onRemoveFuelPump, playerObj, part)
				else
					context:addOption(text, playerObj, ISVehiclePartMenu.onRemoveFuelPump, part)
				end
			elseif fuelStation then
				if slice then
					slice:addSlice(getText("ContextMenu_VehicleInsertFuelPump"), getTexture("media/ui/vehicles/vehicle_insert_fuel_pump.png"), ISVehiclePartMenu.onInsertFuelPump, playerObj, part)
				else
					context:addOption(getText("ContextMenu_VehicleInsertFuelPump"), playerObj, ISVehiclePartMenu.onInsertFuelPump, part)
				end
			end
		end
	end
end

--doTrunkEnterVehicles = doTrunkEnterVehicles or {}
--	local VANILLAdoTrunkEnterVehicles = {
--		["Base.CarStationWagon"] = true,
--		["Base.CarStationWagon2"] = true,
--		["Base.SmallCar"] = true,
--		["Base.OffRoad"] = true,
--	}
--		for k,v in pairs(VANILLAdoTrunkEnterVehicles) do
--			doTrunkEnterVehicles[k] = true
--		end

--noTrunkEnterVehicles = noTrunkEnterVehicles or {}
--	local VANILLAnoTrunkEnterVehicles = {
--		["Base.VanBuilder"] = true,
--		["Base.Van_CraftSupplies"] = true,
--		["Base.Van_Leather"] = true,
--		["Base.Van_Masonry"] = true,
--		["Base.VanSeats_Prison"] = true,
--	}
--		for k,v in pairs(VANILLAnoTrunkEnterVehicles) do
--			noTrunkEnterVehicles[k] = true
--		end

local ISVehicleMenuShowRadialMenuOutside = ISVehicleMenu.showRadialMenuOutside
function ISVehicleMenu.showRadialMenuOutside(playerObj)
	ISVehicleMenuShowRadialMenuOutside(playerObj)

	local menu = getPlayerRadialMenu(playerObj:getPlayerNum())

	local vehicle = playerObj:getVehicle()
	if vehicle then return end
	vehicle = ISVehicleMenu.getVehicleToInteractWith(playerObj)
	if not vehicle then return end

-- Enter Through Trunk
	local doorPart = vehicle:getUseablePart(playerObj)
	if vehicle:getMaxPassengers() > 0 and not vehicle:isBurntOrSmashed() and doorPart and doorPart:getDoor() and (doorPart:getId() == "TrunkDoor" or doorPart:getId() == "TrunkDoor2" or doorPart:getId() == "DoorRear") then
	--	local scriptVehicle = vehicle:getScript()
	--	local fullVName = scriptVehicle:getFullName()
	--	if (scriptVehicle:getMechanicType() == 2 or doTrunkEnterVehicles[fullVName]) and not (noTrunkEnterVehicles[fullVName] or string.contains(string.lower(fullVName), "pickup")) then
		local fullVName = vehicle:getScript():getFullName()
		if MoreCarFeatures.canEnterExitVehicleTrunk[fullVName] or MoreCarFeatures.canEnterExitVehicleTrunkKI51[fullVName] or MoreCarFeatures.canEnterExitVehicleTrunkKI52[fullVName] or MoreCarFeatures.canEnterExitVehicleTrunkKI53[fullVName] then
			menu:addSlice(getText("IGUI_EnterVehicle"), getTexture("media/ui/vehicles/vehicle_cartrunkopen.png"), ISVehicleMenu.onEnterTrunk, playerObj, doorPart)
		end
	end

-- Tire Pump Action Menu (ALWAYS SHOWS, could check if player has tire pump, but deflate is also a thing)
	if not vehicle:isBurnt() then
		menu:addSlice(getText("ContextMenu_QuickTirePumpAction"), getTexture("media/ui/vehicles/vehicle_tirepump_model.png"), ISVehicleMenu.TirePumpMechanic, playerObj, vehicle)
	end

-- Car Bombs
	if SandboxVars.GamestaVehicleZones.interactBombVehicle and not vehicle:isBurnt() then
		menu:addSlice(getText("ContextMenu_CarBombRadialMenu"), instanceItem("Base.PipeBomb"):getTexture(), ISVehicleMenu.PlantLocationMechanic, playerObj, vehicle)
	end

end


function ISVehiclePartMenu.addTarpToTrailer(playerObj, vehicle)
	if not vehicle or vehicle:getScriptName() ~= "Base.Trailer" then return end

	if playerObj:getPerkLevel(Perks.Mechanics) < 1 then return end

	local tarpCount = {}
	local ropeCount = {}
	local it = playerObj:getInventory():getItems()
	for i = 0, it:size()-1 do
		local item = it:get(i)
		local itemName = item:getScriptItem():getFullName()
		if #tarpCount < 2 and itemName == "Base.Tarp" then
			table.insert(tarpCount, item)
		elseif #ropeCount < 3 and itemName == "Base.Rope" then
			table.insert(ropeCount, item)
		elseif item:IsInventoryContainer() and item:isEquipped() then
			local it2 = item:getInventory():getItems()
			for i2 = 0, it2:size()-1 do
				local item2 = it2:get(i2)
				local item2Name = item2:getScriptItem():getFullName()
				if #tarpCount < 2 and item2Name == "Base.Tarp" then
					table.insert(tarpCount, item)
				elseif #ropeCount < 3 and item2Name == "Base.Rope" then
					table.insert(ropeCount, item)
				end
				if #tarpCount >= 2 and #ropeCount >= 3 then
					break
				end
			end
		end
		if #tarpCount >= 2 and #ropeCount >= 3 then
			break
		end
	end

	if #tarpCount < 2 or #ropeCount < 3 then
		return
	end
	local reqItems = ropeCount
	for _, tarp in ipairs(tarpCount) do
		table.insert(reqItems, tarp)
	end

	ISTimedActionQueue.add(ISPathFindAction:pathToVehicleAdjacent(playerObj, vehicle))
	for _, item in ipairs(reqItems) do
		ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
	end
	ISTimedActionQueue.add(ISAddRemoveTarpTrailer:new(playerObj, vehicle, reqItems))
end

function ISVehiclePartMenu.removeTarpFromTrailer(playerObj, vehicle)
	if not vehicle or vehicle:getScriptName() ~= "Base.TrailerCover" then return end
	ISTimedActionQueue.add(ISPathFindAction:pathToVehicleAdjacent(playerObj, vehicle))
	ISTimedActionQueue.add(ISAddRemoveTarpTrailer:new(playerObj, vehicle, nil))
end

local ISVehicleMechanicsDoPartContextMenu = ISVehicleMechanics.doPartContextMenu
function ISVehicleMechanics:doPartContextMenu(part, x,y)
	ISVehicleMechanicsDoPartContextMenu(self, part, x,y)

	if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return; end

	local playerObj = getSpecificPlayer(self.playerNum);
	if playerObj:getVehicle() ~= nil and not (isDebugEnabled() or (isClient() and (isAdmin() or getAccessLevel() == "moderator"))) then return end

	--Tarp Add/Remove option for the 2 vanilla trailers only
	if part:getId() == "TrailerTrunk" then
		local vehicle = part:getVehicle()
		local vsName = vehicle:getScriptName()
		if vsName == "Base.Trailer" then
			local tarpCount = 0
			local ropeCount = 0
			local it = playerObj:getInventory():getItems()
			for i = 0, it:size()-1 do
				local item = it:get(i)
				local itemName = item:getScriptItem():getFullName()
				if itemName == "Base.Tarp" then
					tarpCount = tarpCount + 1
				elseif itemName == "Base.Rope" then
					ropeCount = ropeCount + 1
				elseif item:IsInventoryContainer() and item:isEquipped() then
					local it2 = item:getInventory():getItems()
					for i2 = 0, it2:size()-1 do
						local item2 = it2:get(i2)
						local item2Name = item2:getScriptItem():getFullName()
						if item2Name == "Base.Tarp" then
							tarpCount = tarpCount + 1
						elseif item2Name == "Base.Rope" then
							ropeCount = ropeCount + 1
						end
					end
				end
			end
			local mechanicsCount = playerObj:getPerkLevel(Perks.Mechanics)
			local addTarpOption = self.context:addOption(getText("ContextMenu_VanillaVehicleAddTarpToTrailer"), playerObj, ISVehiclePartMenu.addTarpToTrailer, vehicle)
			local tarpValue = " " .. tarpCount .. "/2"
			local ropeValue = " " .. ropeCount .. "/3"
			local mechanicsValue = " " .. mechanicsCount .. "/1"
			local textColor = ISVehicleMechanics.ghs
			if tarpCount < 2 or ropeCount < 3 or mechanicsCount < 1 then
				textColor = ISVehicleMechanics.bhs
				addTarpOption.notAvailable = true
			end
			local tooltip = ISToolTip:new()
			tooltip:initialise()
			tooltip:setVisible(false)
			tooltip.description = textColor .. getText("Tooltip_craft_Needs") .. 
				":  <LINE> " .. getItemDisplayName("Base.Tarp") .. tarpValue .. 
				"  <LINE> " .. getItemDisplayName("Base.Rope") .. ropeValue ..
				"  <LINE> " .. getText("IGUI_perks_Mechanics") .. mechanicsValue;
			addTarpOption.toolTip = tooltip
		elseif vsName == "Base.TrailerCover" then
			self.context:addOption(getText("ContextMenu_VanillaVehicleRemoveTarpFromTrailer"), playerObj, ISVehiclePartMenu.removeTarpFromTrailer, vehicle)
		end
	end
end



--WARNING:	FULL OVERWRITE BELOW TO ADD WINDOW FUNCTIONALITY OVERLAPPING EXITING THROUGH SPECIFIC DOOR (direct copy-paste, check for updates, load mod before others)
--			Adds individual window opening/closing from the driver seat for every window, must hold alt in the vehicle seats ui (z) to see options

local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

function ISVehicleSeatUI:prerender()
	ISPanelJoypad.prerender(self)

	if not self.vehicle then return end
	local script = self.vehicle:getScript()

	if self.mouseOverExit then
		local altKey = (isKeyDown(Keyboard.KEY_LMENU) or isKeyDown(Keyboard.KEY_RMENU)) and not (isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT))
		local doorPart = self.vehicle:getPassengerDoor(self.mouseOverExit)
		local windowPart = VehicleUtils.getChildWindow(doorPart)
		local showOptionWindows = self.vehicle:isDriver(self.character) and altKey and (windowPart and windowPart:getWindow() and (not windowPart:getItemType() or windowPart:getInventoryItem()))
		if showOptionWindows then
			local window = windowPart:getWindow()
			if window:isOpenable() and not window:isDestroyed() then
				if window:isOpen() then
					self:drawTextCentre(getText("ContextMenu_Close_window"), self:getWidth() / 2, 6, 1, 1, 1, 1, UIFont.Medium)
				else
					self:drawTextCentre(getText("ContextMenu_Open_window"), self:getWidth() / 2, 6, 1, 1, 1, 1, UIFont.Medium)
				end
			end
		else
			self:drawTextCentre(getText("IGUI_ExitVehicle"), self:getWidth() / 2, 6, 1, 1, 1, 1, UIFont.Medium)
		end
		return
	end

	local playerSeat = self.vehicle:getSeat(self.character)

	local seat = self.joyfocus and (self.joypadSeat - 1) or self.mouseOverSeat
	if not seat then return end
	local seatname = 'Seat'..script:getPassenger(seat):getId()
	if getTextOrNull("IGUI_" .. seatname) ~= nil then
		seatname = getText("IGUI_" .. seatname);
	end
	self:drawTextCentre(seatname, self:getWidth() / 2, 6, 1, 1, 1, 1, UIFont.Medium)
	local str = nil
	-- FIXME: can player sit where there is no seat installed?
	if not self:isSeatInstalled(seat) then
		str = getText("IGUI_VehicleSeat_Uninstalled")
	elseif self.vehicle:isSeatOccupied(seat) then
		if not ISVehicleMenu.moveItemsFromSeat(self.character, self.vehicle, seat, false, false) then
			str = getText("IGUI_VehicleSeat_Items")
		else
			str = getText("IGUI_VehicleSeat_MoveItems")
		end
		if self.characterSeat == seat then
			str = getText("IGUI_VehicleSeat_Self")
		elseif self.vehicle:getCharacter(seat) then
			str = getText("IGUI_VehicleSeat_Person")
		--elseif self.vehicle:isSeatHoldingItems(seat) then
		--	str = getText("IGUI_VehicleSeat_MoveItems")
		--else
		--	str = getText("IGUI_VehicleSeat_Items")
		end
	elseif playerSeat ~= -1 and not self.vehicle:canSwitchSeat(playerSeat, seat) then
		str = getText("IGUI_VehicleSeat_ExitToSwitch")
	end
	if str then
		if str ~= self.seatText then
			self.seatText = str
			self.richText:setText(" <RED> <CENTRE> " .. str)
			self.richText.textDirty = true
		end
		self.richText:render(0, 6 + FONT_HGT_MEDIUM, self)
	end
end

function ISVehicleSeatUI:render()
	ISPanelJoypad.render(self)

	self.mouseOverSeat = nil
	self.mouseOverExit = nil

	if not self.vehicle then return end
	
	local script = self.vehicle:getScript()
	local scriptName = self.vehicle:getScriptName()
	local extents = script:getExtents()
	local ratio = extents:x() / extents:z() + 0.0
	local height = self.height * 0.7
	local width = height * ratio
	local ex = (self.width - width) / 2
	local ey = (self.height - height) / 2
	local overlayName = script:getCarMechanicsOverlay() or scriptName
	local props = ISCarMechanicsOverlay.CarList[overlayName]
	if props and props.imgPrefix then
		local tex = getTexture("media/ui/vehicles/seatui/" .. props.imgPrefix .. "base_small.png")
		if tex then
			local imageScale = ImageScale[props.imgPrefix] or 1.0
			self:drawTextureScaledUniform(tex,
				(self.width - tex:getWidthOrig() * imageScale) / 2,
				(self.height - tex:getHeightOrig() * imageScale) / 2,
				imageScale, 1,1,1,1)
		else
			self:drawRect(ex, ey, width, height, 0.8, 0.0, 0.0, 0.0)
			self:drawRectBorder(ex, ey, width, height, 1.0, 1.0, 1.0, 1.0)
		end
	else
		self:drawRect(ex, ey, width, height, 0.8, 0.0, 0.0, 0.0)
		self:drawRectBorder(ex, ey, width, height, 1.0, 1.0, 1.0, 1.0)
	end

	local playerSeat = self.vehicle:getSeat(self.character)

	local shiftKey = isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT)
	local altKey = (isKeyDown(Keyboard.KEY_LMENU) or isKeyDown(Keyboard.KEY_RMENU)) and not shiftKey

	local scale = height / extents:z()
	local sizeX,sizeY = 41,59
	for seat=1,self.vehicle:getMaxPassengers() do
		local pngr = script:getPassenger(seat-1)
		local posn = pngr:getPositionById("inside")

		local doorPart = self.vehicle:getPassengerDoor(seat-1)
		local windowPart = VehicleUtils.getChildWindow(doorPart)
		local showOptionWindows = self.vehicle:isDriver(self.character) and altKey and (windowPart and windowPart:getWindow() and (not windowPart:getItemType() or windowPart:getInventoryItem()))

		if posn then
			local offset = posn:getOffset()
			local x = self:getWidth() / 2 - offset:get(0) * scale - sizeX / 2
			local y = self:getHeight() / 2 - offset:get(2) * scale - sizeY / 2
			y = y + (SeatOffsetY[scriptName] or 0.0)
			
			x = x + (SeatOffsetX[scriptName] or 0.0)
		
			local mouseOver = (self:getMouseX() >= x and self:getMouseX() < x + sizeX and
					self:getMouseY() >= y and self:getMouseY() < y + sizeY) or
					(self.joyfocus and self.joypadSeat == seat)
			if mouseOver then
				self.mouseOverSeat = seat - 1
			end

			local fillR, fillG, fillB = 0.0, 0.0, 0.0
			local outlineR, outlineG, outlineB = 0.0, 1.0, 0.0
			local texName = "icon_vehicle_empty.png"
			local textRGB = 1.0
			local canSwitch = false
			if self.vehicle:isSeatOccupied(seat-1) then
				if self.vehicle:getCharacter(seat-1) then
					texName = "icon_vehicle_person.png"
					fillR = 0.0
					fillG = 0.0
					fillB = 1.0
				else
					fillR, fillG, fillB = 1.0, 1.0, 1.0
					textRGB = 0.0 -- black text on white background
					texName = "icon_vehicle_stuff.png"
					if ISVehicleMenu.moveItemsFromSeat(self.character, self.vehicle, seat-1, false, false) then
						canSwitch = true
					else
						
					end
				end
				if mouseOver then
					outlineR = 1.0
					outlineG = 0.0
					outlineB = 0.0
				end
			elseif self.vehicle:getPartForSeatContainer(seat-1) and
					not self.vehicle:getPartForSeatContainer(seat-1):getInventoryItem() then
				texName = "icon_vehicle_uninstalled.png"
				fillR = 0.5
				fillG = 0.5
				fillB = 0.5
				if mouseOver then
					outlineR = 1.0
					outlineG = 0.0
					outlineB = 0.0
				end
			else
				canSwitch = true
			end

			local seatRGB = 1.0
			if (playerSeat ~= -1) and (playerSeat ~= seat-1) and not self.vehicle:canSwitchSeat(playerSeat, seat - 1) then
				seatRGB = 0.5
				textRGB = textRGB * 0.5
			end
		
			local tex = getTexture("media/ui/vehicles/seatui/" .. texName)
			if tex then
				self:drawTextureScaledUniform(tex, x, y, 1, 1.0, seatRGB, seatRGB, seatRGB)
			else
				self:drawRect(x, y, sizeX, sizeY, 1.0, fillR, fillG, fillB)
				self:drawRectBorder(x, y, sizeX, sizeY, 1.0, 1.0, 1.0, 1.0)
			end

			if not altKey and not shiftKey and canSwitch and not self.joyfocus then
				self:drawTextCentre(tostring(seat), x + sizeX / 2, y + sizeY / 2 - FONT_HGT_LARGE / 2, textRGB, textRGB, textRGB, 1, UIFont.Large)
			end
			
			if mouseOver then
				self:drawRectBorder(x - 2, y - 2, sizeX + 4, sizeY + 4, 1.0, outlineR, outlineG, outlineB)
			end

			if canSwitch and self.joyfocus and self.joypadSeat == seat then
				local tex = Joypad.Texture.AButton
				local texW,texH = tex:getWidth(),tex:getHeight()
				local x = self:getWidth() / 2 - offset:get(0) * scale - texW / 2
				local y = self:getHeight() / 2 - offset:get(2) * scale - texH / 2
				x = x + (SeatOffsetX[scriptName] or 0.0)
				y = y + (SeatOffsetY[scriptName] or 0.0)
				self:drawTextureScaledUniform(tex, x, y, 1, 1,1,1,1)
			end
		end

		-- Display available exits when inside.
		if playerSeat ~= -1 and not self.joyfocus then
			local canSwitch = self.vehicle:canSwitchSeat(playerSeat, seat - 1)
			if self.vehicle:isSeatOccupied(seat - 1) then
				canSwitch = false
				-- if you can't switch because of item we check you can still move them
				if not self.vehicle:getCharacter(seat-1) then
					canSwitch = ISVehicleMenu.moveItemsFromSeat(self.character, self.vehicle, seat-1, false, false)
				end
			end
			if playerSeat == seat - 1 then canSwitch = true end
			self.vehicle:updateHasExtendOffsetForExit(self.character)
			if self.vehicle:isExitBlocked(self.character, seat - 1) then canSwitch = false end
			self.vehicle:updateHasExtendOffsetForExitEnd(self.character)
			posn = pngr:getPositionById("outside")
			if (showOptionWindows or canSwitch) and posn then
				local offset = posn:getOffset()
				local tex = getTexture("media/ui/vehicles/vehicle_exit.png")
				local texW,texH = tex:getWidthOrig(),tex:getHeightOrig()
				local x = self:getWidth() / 2 - offset:get(0) * scale - texW / 2
				local y = self:getHeight() / 2 - offset:get(2) * scale - texH / 2
				y = y + (SeatOffsetY[scriptName] or 0.0)

				local mouseOver = (self:getMouseX() >= x and self:getMouseX() < x + texW and
						self:getMouseY() >= y and self:getMouseY() < y + texH) or
						(self.joyfocus and self.joypadSeat == seat)
				if mouseOver then
					self.mouseOverExit = seat - 1
				end

				if showOptionWindows then
					local window = windowPart:getWindow()
					if window:isOpenable() and not window:isDestroyed() then
						if window:isOpen() then
							tex = getTexture("media/ui/vehicles/vehicle_windowOPEN.png")
						else
							tex = getTexture("media/ui/vehicles/vehicle_windowCLOSED.png")
						end
						texW,texH = tex:getWidthOrig(),tex:getHeightOrig()
						x = self:getWidth() / 2 - offset:get(0) * scale - texW / 2
						y = self:getHeight() / 2 - offset:get(2) * scale - texH / 2
						y = y + (SeatOffsetY[scriptName] or 0.0)
						self:drawTextureScaledUniform(tex, x, y, 1, 1,1,1,1)
					end
				elseif mouseOver or shiftKey then
					self:drawTextureScaledUniform(tex, x, y, 1, 1,1,1,1)
				else
					self:drawTextureScaledUniform(tex, x, y, 1, 0.2,1,1,1)
				end

				if showOptionWindows or shiftKey then
					self:drawRect(x + texW / 2 - 8, y + texH / 2 - FONT_HGT_LARGE / 2, 16, FONT_HGT_LARGE, 1, 0.1, 0.1, 0.1)
					self:drawTextCentre(tostring(seat), x + texW / 2, y + texH / 2 - FONT_HGT_LARGE / 2, 1, 1, 1, 1, UIFont.Large)
				end
			end
		end
		if playerSeat ~= -1 and self.joyfocus and seat == self.joypadSeat then
			local canSwitch = self.vehicle:canSwitchSeat(playerSeat, seat - 1)
			if self.vehicle:isSeatOccupied(seat - 1) then
				canSwitch = false
				-- if you can't switch because of item we check you can still move them
				if not self.vehicle:getCharacter(seat-1) then
					canSwitch = ISVehicleMenu.moveItemsFromSeat(self.character, self.vehicle, seat-1, false, false)
				end
			end
			if playerSeat == seat - 1 then canSwitch = true end
			self.vehicle:updateHasExtendOffsetForExit(self.character)
			if self.vehicle:isExitBlocked(self.character, seat - 1) then canSwitch = false end
			self.vehicle:updateHasExtendOffsetForExitEnd(self.character)
			posn = pngr:getPositionById("outside")
			if canSwitch and posn then
				local offset = posn:getOffset()
				local tex = Joypad.Texture.XButton
				local texW,texH = tex:getWidthOrig(),tex:getHeightOrig()
				local x = self:getWidth() / 2 - offset:get(0) * scale - texW / 2
				local y = self:getHeight() / 2 - offset:get(2) * scale - texH / 2
				y = y + (SeatOffsetY[scriptName] or 0.0)
				self:drawTextureScaledUniform(tex, x, y, 1, 1,1,1,1)
			end
		end
	end

	-- TODO: Allow choosing a seat to exit from
end

function ISVehicleSeatUI:rollWindowUp(windowPart)
	ISTimedActionQueue.add(ISOpenCloseVehicleWindow:new(self.character, windowPart, false))
end

function ISVehicleSeatUI:rollWindowDown(windowPart)
	ISTimedActionQueue.add(ISOpenCloseVehicleWindow:new(self.character, windowPart, true))
end

function ISVehicleSeatUI:onMouseDown(x, y)
	if self.mouseOverSeat then
		self:useSeat(self.mouseOverSeat)
		return
	end
	if self.mouseOverExit then
		local shiftKey = isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT)
		local altKey = (isKeyDown(Keyboard.KEY_LMENU) or isKeyDown(Keyboard.KEY_RMENU)) and not shiftKey
		local doorPart = self.vehicle:getPassengerDoor(self.mouseOverExit)
		local windowPart = VehicleUtils.getChildWindow(doorPart)
		local showOptionWindows = self.vehicle:isDriver(self.character) and altKey and (windowPart and windowPart:getWindow() and (not windowPart:getItemType() or windowPart:getInventoryItem()))
		if showOptionWindows then
			local window = windowPart:getWindow()
			if window:isOpenable() and not window:isDestroyed() then
				if window:isOpen() then
					self:rollWindowUp(windowPart)
				else
					self:rollWindowDown(windowPart)
				end
			end
		else
			self:exitSeat(self.mouseOverExit)
		end
		return
	end
end

function ISVehicleSeatUI:onKeyRelease(key)
	if not self.vehicle or not self.vehicle:getScript() then return end
	local numSeats = self.vehicle:getMaxPassengers()
	if key >= Keyboard.KEY_1 and key < Keyboard.KEY_1 + numSeats then
		if self.vehicle:isDriver(self.character) and (isKeyDown(Keyboard.KEY_LMENU) or isKeyDown(Keyboard.KEY_RMENU)) then
			local doorPart = self.vehicle:getPassengerDoor(key - Keyboard.KEY_1)
			local windowPart = VehicleUtils.getChildWindow(doorPart)
			if windowPart and windowPart:getWindow() and (not windowPart:getItemType() or windowPart:getInventoryItem()) then
				local window = windowPart:getWindow()
				if window:isOpenable() and not window:isDestroyed() then
					if window:isOpen() then
						self:rollWindowUp(windowPart)
					else
						self:rollWindowDown(windowPart)
					end
				end
			end
		elseif isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT) then
			self:exitSeat(key - Keyboard.KEY_1)
		else
			self:useSeat(key - Keyboard.KEY_1)
		end
	end
end
