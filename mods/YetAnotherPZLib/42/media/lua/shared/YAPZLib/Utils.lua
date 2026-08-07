local __utils = {}

local __tab = {}
local processing = false

local function processTab()
	for i = #__tab, 1, -1 do
		local delayedFunc = __tab[i]
		local ticks = delayedFunc.ticks
		if ticks then
			delayedFunc.ticks = ticks - 1
			if delayedFunc.ticks <= 0 then
				if delayedFunc.args then
					delayedFunc.func(unpack(delayedFunc.args, 1, delayedFunc.args._len))
				else
					delayedFunc.func()
				end
				
				table.remove(__tab, i)
			end
		end
	end
	
	if #__tab == 0 then
		processing = false
		Events.OnTick.Remove(processTab)
	end
end

local getTableType = function(tab)
	local count = 0

	for k, _ in pairs(tab) do
		count = count + 1
		if type(k) ~= "number" then
			return "map"
		end
	end

	for i = 1, #tab do
		if tab[i] == nil then
			return "map"
		end
	end

	return "list"
end

local function tableInstanceOf(tab, __type)
	if tab.Type == __type then
		return true
	end
	
	local metaTable = getmetatable(tab)
	if metaTable and type(metaTable.__index) == "table" and metaTable.__index ~= tab then
		return tableInstanceOf(metaTable.__index, __type)
	end
	
	return false
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.debugLog = function(_log)
	if type(_log) ~= "string" then return end
	
	if isDebugEnabled() then
		print("[YAPZLib Log]: ", _log)
	end
end

__utils.debugAssert = function(_boolean, _log)
	if type(_boolean) ~= "boolean" or type(_log) ~= "string" then return end
	
	if isDebugEnabled() then
		assert(_boolean, _log)
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.checkArgs = function(...)
	local args = {...}
	local result = {}
	
	__utils.debugAssert(#args % 3 == 0, "checkArgs expects: argument, expected type definition, nil check")
	
	for i = 1, #args, 3 do
		local arg = args[i]
		local argIndex = (i - 1) / 3 + 1
		local expected = args[i + 1]
		local checkNil = args[i + 2]
		
		__utils.debugAssert(type(expected) == "string", ("argument #%d expected type definition must be string"):format(argIndex))
		__utils.debugAssert(type(checkNil) == "boolean", ("argument #%d nil check must be boolean"):format(argIndex))
		
		if checkNil and arg == nil then
			__utils.debugAssert(("argument #%d is nil"):format(argIndex))
			return false
		end
		
		local actualType
		local valid = false
		if arg ~= nil then
			local luaType = type(arg)
			local isTable = luaType == "table"
			local isJavaClass = luaType == "userdata" and arg.getClass ~= nil
			actualType = (isJavaClass and getClassSimpleName(arg)) or (isTable and arg.Type) or (isTable and getTableType(arg)) or luaType
			
			for expectedType in expected:gmatch("[^|]+") do
				expectedType = expectedType:match("^%s*(.-)%s*$")
				if expectedType == "nil" then
					valid = true
					break
				elseif isJavaClass then
					if instanceof(arg, expectedType) then
						valid = true
						break
					end
				elseif isTable then
					if expectedType == "table" then
						valid = true
						break
					elseif actualType == expectedType then
						valid = true
						break
					elseif tableInstanceOf(arg, expectedType) then
						valid = true
						break
					end
				elseif luaType == "number" then
					actualType = (arg % 1 == 0) and "integer" or "float"
					if expectedType == "number" then
						valid = true
						break
					elseif expectedType == "integer" and arg % 1 == 0 then
						valid = true
						break
					end
				else
					if actualType == expectedType then
						valid = true
						break
					end
				end
			end
		else
			actualType = "nil"
			valid = not checkNil
		end
		
		if not valid then
			__utils.debugAssert(false, ("argument #%d expected %s, got %s"):format(argIndex, expected, actualType))
			return false
		else
			result[argIndex] = actualType
		end
	end
	
	return result
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.formatCamelCase = function(str)
	if not __utils.checkArgs(str, "string", true) then return end
	
	local newString = str:gsub("(%l)(%u)", "%1 %2")
	return newString
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.tableIsEmpty = function(tab)
	if not __utils.checkArgs(tab, "table", true) then return false end
	
	for _ in pairs(tab) do
		return false
	end
	
	return true
end

function __utils.copyTable(tab)
	if not __utils.checkArgs(tab, "table", true) then return end

	local copy = {}
	for k, v in pairs(tab) do
		if type(v) == "table" then
			copy[k] = __utils.copyTable(v)
		else
			copy[k] = v
		end
	end
	
	return copy
end

function __utils.clearTable(tab)
	if not __utils.checkArgs(tab, "table", true) then return end

	for k, v in pairs(tab) do
		if type(v) == "table" then
			tab[k] = __utils.clearTable(v)
		else
			tab[k] = nil
		end
	end
end

__utils.tableHas = function(tab, arg)
	local __types = __utils.checkArgs(tab, "table", true)
	if not __types then return false end
	
	if __types[1] == "list" then
		for _, v in ipairs(tab) do
			if v == arg then
				return true
			end
		end
	else
		for k, v in pairs(tab) do
			if k == arg or v == arg then
				return true
			end
		end
	end
	
	return false
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.getGlobalObject = function(name)
	if not __utils.checkArgs(name, "string", true) then return end

	local obj = _G

	for field in name:gmatch("[^.]+") do
		obj = obj[field]
		if obj == nil then
			return nil
		end
	end

	return obj
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.invertAngle = function(angle)
	if not __utils.checkArgs(angle, "number", true) then return end
	
	local inverted = angle + 180
	if inverted > 180 then
		inverted = inverted - 360
	end
	
	return inverted
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.getSquaresInRadius = function(posx, posy, z, radius)
	if not __utils.checkArgs(
		posx, "integer", true,
		posy, "integer", true,
		z, "integer", true,
		radius, "integer", true
	) then return end

	local squares = {}
	for x = posx - radius, posx + radius do
		for y = posy - radius, posy + radius do
			if math.sqrt((x - posx) ^ 2 + (y - posy) ^ 2) <= radius then
				local square = getCell():getGridSquare(x, y, z)
				if square then
					table.insert(squares, square)
				end
			end
		end
	end
	
	return squares
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.delay = function(func, ticks, ...)
	if not __utils.checkArgs(
		func, "function", true,
		ticks, "integer", true
	) then return end
	
	local args = {...}
	args._len = select("#", ...)

	table.insert(__tab, { func = func, ticks = ticks, args = args })
	
	if not processing then
		Events.OnTick.Add(processTab)
		processing = true
	end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.cellIsModded = function(cellX, cellY)
	if not __utils.checkArgs(
		cellX, "integer", true,
		cellY, "integer", true
	) then return end

	local dirs = getLotDirectories()
	for i = dirs:size() - 1, 0, -1 do
		local dirName = dirs:get(0)
		if dirName ~= "Muldraugh, KY" then
			local lotfile = 'media/maps/'..dirName..'/'..cellX..'_'..cellY..'.lotheader'
			if fileExists(lotfile) then
				return true
			end
		end
	end
	
	return false
end

__utils.getCellCoordinates = function(x, y)
	if not __utils.checkArgs(
		x, "number", true,
		y, "number", true
	) then return end
	
	return math.floor(x / 256), math.floor(y / 256)
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

__utils.clearContainer = function(container)
	if not __utils.checkArgs(container, "ItemContainer", true) then return end

	if isMultiplayer() then
		local items = container:getItems()
		if items then
			for i = items:size() - 1, 0, -1 do
				local item = items:get(i)
				if item then
					container:DoRemoveItem(item)
					sendRemoveItemFromContainer(container, item)
				end
			end
		end
	else
		container:clear()
	end
end

__utils.refillContainer = function(obj, roomName, containerType, procName, junk)
	if not __utils.checkArgs(
		obj, "IsoObject", true,
		roomName, "string", true,
		containerType, "string", true,
		procName, "string", true,
		junk, "boolean", false
	) then return end

	local container = obj:getItemContainer()
	if container then
		__utils.clearContainer(container)
		
		containerDist = ItemPickerJava.getItemContainer(roomName, containerType, procName, junk)
		if containerDist then
			ItemPickerJava.doRollItem(containerDist, container, ItemPickerJava.getZombieDensityFactor(containerDist, container), nil, true, nil)
		end
		
		container:setExplored(false)
	end
end

return __utils