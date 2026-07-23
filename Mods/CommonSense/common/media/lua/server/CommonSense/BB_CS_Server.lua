-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

---@param playerObj IsoPlayer
---@param args PryDoorOrWindowOpenArgs
---@class PryDoorOrWindowOpenArgs
---@field square Position3Ds
---@field index integer
---@field windowShatterChance number
local function pryDoorOrWindowOpen(playerObj, args)

    local cell = playerObj:getCell()
    local sq = cell:getGridSquare(args.square.x, args.square.y, args.square.z)
    if not sq then return end
   
    local priableObject = sq:getObjects():get(args.index)

    if instanceof(priableObject, "IsoDoor") then --[[@cast priableObject IsoDoor]]

        priableObject:setLockedByKey(false)

        local doubleDoorObjects = buildUtil.getDoubleDoorObjects(priableObject)
        for i=1, #doubleDoorObjects do
            local object = doubleDoorObjects[i] --[[@type IsoDoor]]
            object:setLockedByKey(false)
        end

        local garageDoorObjects = buildUtil.getGarageDoorObjects(priableObject)
        for i=1, #garageDoorObjects do
            local object = garageDoorObjects[i] --[[@type IsoDoor]]
            object:setLockedByKey(false)
        end

    elseif instanceof(priableObject, "IsoWindow") then --[[@cast priableObject IsoWindow]]
        
        if args.windowShatterChance > SandboxVars.CommonSense.WindowShatterChance then
            priableObject:setIsLocked(false) -- Code snippet thanks to "Buffy"!
            priableObject:setPermaLocked(false)
        else
            priableObject:setSmashed(true)
        end
    end
    priableObject:sync()
end

---@param playerObj IsoPlayer
---@param args PryVehicleOpenArgs
---@class PryVehicleOpenArgs
---@field vehicleId integer
---@field partId string
local function pryVehicleOpen(playerObj, args)
    local vehicle = getVehicleById(args.vehicleId)
    local priableObject = vehicle and vehicle:getPartById(args.partId)
    if not priableObject then return end
    priableObject:getDoor():setLocked(false)
    priableObject:getDoor():setLockBroken(false)
    vehicle:transmitPartDoor(priableObject)
    vehicle:sync()
end

---@param playerObj IsoPlayer
---@param args PryVehicleOpenArgs
local function shatterVehicleWindow(playerObj, args)
    local vehicle = getVehicleById(args.vehicleId)
    local part = vehicle and vehicle:getPartById(args.partId)
    local window = part and part:getWindow()
    if window and not window:isOpen() and not window:isDestroyed() then
        window:damage(window:getHealth())
    end
    vehicle:sync()
end

---@param playerObj IsoPlayer
---@param args RemoveResourcesArgs
---@class RemoveResourcesArgs
---@field square Position3Ds
---@field spriteName string
---@class Position3Ds
---@field x number
---@field y number
---@field z number
local function removeResources(playerObj, args)
    local cell = playerObj:getCell()
	local sq = cell:getGridSquare(args.square.x, args.square.y, args.square.z)
    if not sq then return end

    local objs = sq:getObjects()
    for n = objs:size()-1, 0, -1 do

        local obj = objs:get(n)
        local sprite =  obj:getSprite()
        local spriteName = sprite and sprite:getName() or ""
        if spriteName == args.spriteName then
            sledgeDestroy(obj)
            sq:transmitRemoveItemFromSquare(obj)
        end
    end
end

---@param playerObj IsoPlayer
---@param args GiveItemArgs
---@class GiveItemArgs
---@field itemName string
local function giveItem(playerObj, args)
    local inventory = playerObj:getInventory()
    local item = inventory:AddItem(args.itemName)
    if instanceof(item, "InventoryItem") then --[[@cast item InventoryItem]]
        sendAddItemToContainer(inventory, item)
    end
end

---@param module string
---@param command string
---@param playerObj IsoPlayer
---@param args table?
local function onClientCommand(module, command, playerObj, args)
    if module ~= "CommonSense" or not args then return end
    if command == "PryDoorOrWindowOpen" then
        pryDoorOrWindowOpen(playerObj, args)
    elseif command == "PryVehicleOpen" then
        pryVehicleOpen(playerObj, args)
    elseif command == "ShatterVehicleWindow" then
        shatterVehicleWindow(playerObj, args)
    elseif command == "RemoveResources" then
        removeResources(playerObj, args)
    elseif command == "GiveItem" then
        giveItem(playerObj, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)