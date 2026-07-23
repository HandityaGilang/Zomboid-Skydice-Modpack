-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

---@param worldObjects IsoObject[]|nil
---@param playerObj IsoPlayer
---@param obj table
local function tryEquipWeapon(worldObjects, playerObj, obj)
    if obj.square and luautils.walkAdj(playerObj, obj.square) then
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, obj.item)
        ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, obj.item, 50, true, obj.item:isTwoHandWeapon()))
	end
end

---@param worldObjects IsoObject[]|nil
---@param playerObj IsoPlayer
---@param obj table
local function tryEquipClothing(worldObjects, playerObj, obj)
    if obj.square and luautils.walkAdj(playerObj, obj.square) then
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, obj.item)
        ISTimedActionQueue.add(ISWearClothing:new(playerObj, obj.item))
	end
end

---@param worldObjects IsoObject[]|nil
---@param playerObj IsoPlayer
---@param obj table
local function tryEquipContainer(worldObjects, playerObj, obj)
    if obj.square and luautils.walkAdj(playerObj, obj.square) then
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, obj.item)
        ISTimedActionQueue.add(ISWearClothing:new(playerObj, obj.item))
	end
end

---@param playerNum integer
---@param context ISContextMenu
---@param worldObjects IsoObject[]
local function onFillWorldObjectContextMenu(playerNum, context, worldObjects)
	
	--*rework of old game snippet
	local playerObj = getSpecificPlayer(playerNum)
	local squares = {} --[[@as (IsoGridSquare[])]]
	local doneSquare = {} --[[@as table<IsoGridSquare, boolean>]]

	for _, worldObj in ipairs(worldObjects) do
		local tSquare = worldObj:getSquare()
		if tSquare and not doneSquare[tSquare] then
			doneSquare[tSquare] = true
			table.insert(squares, tSquare)
		end
	end

	local groundObjects = {} --[[@as (IsoWorldInventoryObject[])]]
	if JoypadState.players[playerNum+1] then
		for _, square in ipairs(squares) do
			local objs = square:getWorldObjects()
			for i=1, objs:size() do
				local worldObject = objs:get(i-1)
				table.insert(groundObjects, worldObject)
			end
		end
	else
		local squares2 = {} --[[@as (IsoGridSquare[])]]
		for k, v in ipairs(squares) do
			squares2[k] = v
		end

		local radius = 1
		for _, square in ipairs(squares2) do
			local worldX = screenToIsoX(playerNum, getMouseX(), getMouseY(), square:getZ())
			local worldY = screenToIsoY(playerNum, getMouseX(), getMouseY(), square:getZ())
			BB_CS_Utils.getSquaresInRadius(worldX, worldY, square:getZ(), radius, doneSquare, squares)
		end

		BB_CS_Utils.getWorldObjectsInSquares(squares, groundObjects)
	end

	if #groundObjects == 0 then return end
	--*end of snippet

    local itemList = {} --[[@as (itemTable[])]]
	for _, worldObject in ipairs(groundObjects) do
        local item = worldObject:getItem()
		if item and (item:IsWeapon() or item:IsClothing() or item:IsInventoryContainer()) then
			local itemTable = {} --[[@class itemTable]]
			itemTable.name = item:getName() or "???"
			itemTable.worldObject = worldObject
			itemTable.item = item
			itemTable.square = worldObject:getSquare()
			table.insert(itemList, itemTable)
		end
	end
	if #itemList == 0 then return end

	local equipOption = context:insertOptionBefore(getText("ContextMenu_Grab"), getText("ContextMenu_CS_Equip"), groundObjects, nil)
		or context:addOptionOnTop(getText("ContextMenu_CS_Equip"), groundObjects, nil)
	local submenu = ISContextMenu:getNew(context)
	context:addSubMenu(equipOption, submenu)

	for _, itemTable in pairs(itemList) do
		local func = nil --[[@as function?]]
        if itemTable.item:IsWeapon() then
            func = tryEquipWeapon
        elseif itemTable.item:IsClothing() then
            func = tryEquipClothing
        elseif itemTable.item:IsInventoryContainer() then
            func = tryEquipContainer
        end

		local subOpt = submenu:addOption(itemTable.name, worldObjects, func, playerObj, itemTable)
		subOpt.iconTexture = itemTable.item:getTex()
		ISWorldObjectContextMenu.initWorldItemHighlightOption(subOpt, itemTable.worldObject)
	end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)