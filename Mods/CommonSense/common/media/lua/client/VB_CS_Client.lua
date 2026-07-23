-- ************************************************************************
-- **                  ██  ██    ██ ██ ████████  █████                   **
-- **                ████  ██    ██ ██    ██   ██   ██                   **
-- **              ██  ██  ██    ██ ██    ██   ███████                   **
-- **                  ██   ██  ██  ██    ██   ██   ██                   **
-- **                  ██    ████   ██    ██   ██   ██                   **
-- **                https://steamcommunity.com/id/1vita                 **
-- ************************************************************************
-- **        The following content was crafted from the ground up,       **
-- **       writing my own lines, but also taking inspiration from       **
-- **       others' work to better understand the game's workflow.       **
-- **                So, as it should be with every mod,                 **
-- **                   >>> USE IT AS YOU PLEASE <<<                     **
-- ************************************************************************
-- **            Let's make Project Zomboid greater togheter!            **
-- ************************************************************************
-- **      This class was ported from ISEquippedItem using ChatGPT       **
-- ************************************************************************

---@param args TryReturnToolArgs
---@class TryReturnToolArgs
---@field playerId integer
---@field containerId integer?
local function tryReturnTool(args)

    local playerObj = getSpecificPlayer(args.playerId)
    if playerObj:getOnlineID() ~= getSpecificPlayer(0):getOnlineID() then return end
    local tool = playerObj:getPrimaryHandItem()
    local currentToolContainer = tool and tool:getContainer()
    if not currentToolContainer then return end
    local targetContainer = args.containerId and playerObj:getInventory():getItemWithID(args.containerId):getContainer()

    if targetContainer ~= nil and targetContainer ~= currentToolContainer then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, tool, currentToolContainer, targetContainer))
    elseif tool:isEquipped() then
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, tool, 50))
    end
end

---@param args OpenDoorOrWindowArgs
---@class OpenDoorOrWindowArgs
---@field playerId integer
---@field objectId integer
local function openDoorOrWindow(args)
    local playerObj = getSpecificPlayer(args.playerId)
    if playerObj:getOnlineID() ~= getSpecificPlayer(0):getOnlineID() then return end
    local object = playerObj:getSquare():getObjects():get(args.objectId)

    if instanceof(object, "IsoDoor") then --[[@cast object IsoDoor]]
        ISTimedActionQueue.add(ISOpenCloseDoor:new(playerObj, object))
        
    elseif instanceof(object, "IsoWindow") then --[[@cast object IsoWindow]]
        ISTimedActionQueue.add(ISOpenCloseWindow:new(playerObj, object))
    end
end

---@param args OpenVehiclePartArgs
---@class OpenVehiclePartArgs
---@field playerId integer
---@field vehicleId integer
---@field partId string
local function openVehiclePart(args)
    local playerObj = getSpecificPlayer(args.playerId)
    if playerObj:getOnlineID() ~= getSpecificPlayer(0):getOnlineID() then return end
    local vehicle = getVehicleById(args.vehicleId)
    local part = vehicle:getPartById(args.partId)

    ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, vehicle, part))
end

---@param module string
---@param command string
---@param args table?
local function onServerCommand(module, command, args)
    if module ~= "CommonSense" or not args then return end
    if command == "TryReturnTool" then
        tryReturnTool(args)
    elseif command == "OpenDoorOrWindow" then
        openDoorOrWindow(args)
    elseif command == "OpenVehiclePart" then
        openVehiclePart(args)
    end
end

Events.OnServerCommand.Add(onServerCommand)

