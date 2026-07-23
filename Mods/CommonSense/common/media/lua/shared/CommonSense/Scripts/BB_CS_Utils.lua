-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************
-- OVERRIDE FOR THIS SPECIFIC MOD

BB_CS_Utils = {}


---@return boolean
function BB_CS_Utils.needToCompatify(modIds)
    local activatedMods = getActivatedMods()
    if activatedMods then
        for _, modId in ipairs(modIds) do
            if activatedMods:contains(modId) then
                return true
            end
        end
    end
    return false
end

---@param obj ILuaGameCharacter
---@param soundName string
function BB_CS_Utils.TryPlaySoundClip(obj, soundName)

	if obj:getEmitter():isPlaying(soundName) then return end
    local proxy = IsoObject.getNew() ---@diagnostic disable-line: missing-parameter
    obj:getEmitter():playSoundImpl(soundName, proxy)
end

---@param obj ILuaGameCharacter
---@param soundName string
function BB_CS_Utils.TryStopSoundClip(obj, soundName)

	if not obj:getEmitter():isPlaying(soundName) then return end
	obj:getEmitter():stopSoundByName(soundName)
end

---@param playerObj IsoPlayer
---@param amount number
function BB_CS_Utils.TirePlayer(playerObj, amount)

	local stats = playerObj:getStats()
	if not stats then return end

	if stats:get(CharacterStat.ENDURANCE) < 0.21 then return end
	stats:set(CharacterStat.ENDURANCE, stats:get(CharacterStat.ENDURANCE) - (amount / (playerObj:getPerkLevel(Perks.Fitness) / 2)))
end

---@return integer
function BB_CS_Utils.GetGameSpeed()
    local speedControl = UIManager.getSpeedControls():getCurrentGameSpeed()
    local gameSpeed = {1, 5, 20, 40}
    return gameSpeed[speedControl] --[[@as integer]]
end

--- Framerate dependent
---@param func function
---@param delay integer?
---@param adaptToSpeed boolean?
function BB_CS_Utils.DelayFunction(func, delay, adaptToSpeed)

    delay = delay or 1
    local multiplier = 1
    local ticks = 0
    local canceled = false

    local function onTick()
        if adaptToSpeed then multiplier = BB_CS_Utils.GetGameSpeed() end
        if not canceled and ticks < delay then
            ticks = ticks + multiplier
            return
        end

        Events.OnTick.Remove(onTick)
        if not canceled then func() end
    end

    Events.OnTick.Add(onTick)
    return function()
        canceled = true
    end
end

---@param description string
---@param menuOption umbrella.ISContextMenu.Option
function BB_CS_Utils.addTooltip(description, menuOption)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = description
    menuOption.toolTip = tooltip
end

---@param inputstr string
---@param sep string
---@return string[]
function BB_CS_Utils.splitString(inputstr, sep)
    local strs = {} --[[@as (string[])]]
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(strs, str)
    end
    return strs
end

---@param x number
---@param y number
---@param z number
---@param radius integer
---@param doneSquare table<IsoGridSquare, boolean>
---@param result IsoGridSquare[]
function BB_CS_Utils.getSquaresInRadius(x, y, z, radius, doneSquare, result)
    local cell = getCell()
    for xx = x - radius, x + radius do
        for yy = y - radius, y + radius do
            local square = cell:getGridSquare(xx, yy, z)

            if square and not doneSquare[square] then
                doneSquare[square] = true
                table.insert(result, square)
            end
        end
    end
end

---@param context ISContextMenu
---@param name string
---@return ISContextMenu|nil
function BB_CS_Utils.getSubMenuByName(context, name)
    
    local submenu = context:getOptionFromName(name)

    if submenu and submenu.subOption then
        return context:getSubMenu(submenu.subOption)
    end
    
    return nil -- Retorna nil si no encuentra nada
end

---@param squares IsoGridSquare[]
---@param result IsoWorldInventoryObject[]
---@return ArrayList<IsoWorldInventoryObject>
---@author ChatGPT
function BB_CS_Utils.getWorldObjectsInSquares(squares, result)
    local list = ArrayList.new() --[[@as ArrayList<IsoWorldInventoryObject>]] --[[@diagnostic disable-line: missing-parameter]]
    for _, square in ipairs(squares) do
        local objects = square:getWorldObjects()
        list:addAll(objects)

        for i = 0, objects:size() - 1 do
            table.insert(result, objects:get(i))
        end
    end
    return list
end

--- Looks in the ground and inside containers.
---@param squares IsoGridSquare[]
---@param result InventoryItem[]
---@return ArrayList<InventoryItem>
---@author ChatGPT
function BB_CS_Utils.getItemsInSquares(squares, result)
    local list = ArrayList.new() --[[@as ArrayList<InventoryItem>]] --[[@diagnostic disable-line: missing-parameter]]
    for _, square in ipairs(squares) do
        local objects = square:getObjects()

        for i=0, objects:size() - 1 do
            local anyObj = objects:get(i)
            if instanceof(anyObj, "IsoWorldInventoryObject") then
                ---@cast anyObj IsoWorldInventoryObject
                local item = anyObj:getItem()
                list:add(item)
                table.insert(result, item)
            elseif anyObj:getContainer() then
                local containerItems = anyObj:getContainer():getItems()
                list:addAll(containerItems)
                for j=0, containerItems:size() - 1 do
                    local item = containerItems:get(j)
                    table.insert(result, item)
                end
            end
        end
    end
    return list
end

---@param firstObj IsoMovingObject
---@param secondObj IsoMovingObject
---@return number
function BB_CS_Utils.DistanceBetween(firstObj, secondObj)
    local x1, y1, z1 = firstObj:getX(), firstObj:getY(), firstObj:getZ()
    local x2, y2, z2 = secondObj:getX(), secondObj:getY(), secondObj:getZ()

    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2

    if dz >= 2 then
        return 999
    end

    local distance = math.sqrt(dx * dx + dy * dy)
    return distance
end