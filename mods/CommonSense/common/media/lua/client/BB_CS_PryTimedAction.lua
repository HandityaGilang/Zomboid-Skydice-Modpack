-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

require "TimedActions/ISBaseTimedAction"

---@class BB_CS_PryTimedAction : ISBaseTimedAction
---@field typeTimeAction string
---@field worldObjects IsoObject[]
---@field vehicle BaseVehicle?
---@field vehicleID integer?
---@field priableObject GameEntity
---@field priableObjectID string?
---@field character IsoPlayer
---@field container ItemContainer?
---@field stopOnWalk boolean
---@field stopOnRun boolean
---@field maxTime number
---@field fromHotbar boolean
BB_CS_PryTimedAction = ISBaseTimedAction:derive("BB_CS_PryTimedAction")

---@param character IsoPlayer
---@param container ItemContainer?
local function tryReturnTool(character, container)
    local tool = character:getPrimaryHandItem()
    local currentToolContainer = tool and tool:getContainer()
    if not container or not currentToolContainer then return end

    if container ~= currentToolContainer then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(character, tool, currentToolContainer, container))
    elseif tool:isEquipped() then
        ISTimedActionQueue.add(ISUnequipAction:new(character, tool, 50))
    end
end

function BB_CS_PryTimedAction:isValid()
    local tool = BB_CS_PryUtils.GetPryingTool(self.character)
    local type = tool and tool:getFullType() or ""
    return self.character:hasEquipped(type) --[[@diagnostic disable-line: return-type-mismatch, redundant-return-value]]
end

function BB_CS_PryTimedAction:waitToStart()
    if self.vehicle then return false end
    self.character:faceThisObject(self.priableObject)
    local isFacingObj = self.character:isFacingObject(self.priableObject, 0.4) -- 70º angle room
    return not isFacingObj
end

function BB_CS_PryTimedAction:start()

    if self.typeTimeAction == "pryDoorOrWindow" then

        self:setActionAnim("RemoveBarricade")
        self:setAnimVariable("RemoveBarricade", "CrowbarMid")
        if self.character:isTimedActionInstant() then return end

        BB_CS_Utils.DelayFunction(function()
            local currentTA = ISTimedActionQueue.getTimedActionQueue(self.character).current
            if currentTA == self then 
                BB_CS_Utils.TryPlaySoundClip(self.character, BB_CS_PryUtils.GetProperSound(self.priableObject, false))
            end
        end, 35, true)
    
    elseif self.typeTimeAction == "pryVehicleDoor" then

        self:setActionAnim("RemoveBarricade")
        self:setAnimVariable("RemoveBarricade", "CrowbarMid")
        if self.character:isTimedActionInstant() then return end

        BB_CS_Utils.DelayFunction(function()
            local currentTA = ISTimedActionQueue.getTimedActionQueue(self.character).current
            if currentTA == self then 
                BB_CS_Utils.TryPlaySoundClip(self.character, "MetalBarHit")
            end
        end, 35, true)
    end
end

function BB_CS_PryTimedAction:stop()

    ISBaseTimedAction.stop(self)

    if self.typeTimeAction == "pryDoorOrWindow" then
        BB_CS_Utils.TryStopSoundClip(self.character, BB_CS_PryUtils.GetProperSound(self.priableObject, false))

    elseif self.typeTimeAction == "pryVehicleDoor" then
        BB_CS_Utils.TryStopSoundClip(self.character, "MetalBarHit")
    end
end

function BB_CS_PryTimedAction:perform()

    if self.typeTimeAction == "pryDoorOrWindow" then --[[@cast self.priableObject IsoDoor|IsoWindow]]

        BB_CS_Utils.TirePlayer(self.character, 0.07)
        BB_CS_Utils.TryStopSoundClip(self.character, BB_CS_PryUtils.GetProperSound(self.priableObject, false))

        if BB_CS_PryUtils.PrySuccessfully(self.character, 0) == true then
            
            local objectSquare = self.priableObject:getSquare()
            local windowShatterChance = ZombRand(100)+1
            
            sendClientCommand(self.character, "CommonSense", "PryDoorOrWindowOpen", {
                square = {x = objectSquare:getX(), y = objectSquare:getY(), z = objectSquare:getZ()},
                index = self.priableObject:getObjectIndex(),
                windowShatterChance = windowShatterChance,
            })
            
            if instanceof(self.priableObject, "IsoDoor") then --[[@cast self.priableObject IsoDoor]]

                local garageDoorObjects = buildUtil.getGarageDoorObjects(self.priableObject)
                for i=1, #garageDoorObjects do
                    self.character:getXp():AddXP(Perks.Strength, 5)
                end

                ISTimedActionQueue.add(ISOpenCloseDoor:new(self.character, self.priableObject))
                BB_CS_Utils.TryPlaySoundClip(self.character, "BreakBarricadePlank")
                self.character:getXp():AddXP(Perks.Strength, 7)

            elseif instanceof(self.priableObject, "IsoWindow") then --[[@cast self.priableObject IsoWindow]]
                
                if windowShatterChance > SandboxVars.CommonSense.WindowShatterChance then
                    ISTimedActionQueue.add(ISOpenCloseWindow:new(self.character, self.priableObject))
                    self.character:getXp():AddXP(Perks.Strength, 4)
                else
                    BB_CS_Utils.TryPlaySoundClip(self.character, "SmashWindow")
                    self.character:getXp():AddXP(Perks.Strength, 3)
                end
            end
            tryReturnTool(self.character, self.container)
        else
            self.character:Say(getText("IGUI_CS_PryFail"))
            self.character:getXp():AddXP(Perks.Strength, 4)

            if BB_CS_PryUtils.GetProperSound(self.priableObject, true) == "Wooden" then
                BB_CS_Utils.TryPlaySoundClip(self.character, "BreakLockOnWindow")
            else
                BB_CS_Utils.TryPlaySoundClip(self.character, "MetalBarBreak")
            end
        end
    end

    if self.typeTimeAction == "pryVehicleDoor" then --[[@cast self.priableObject VehiclePart]]--[[@cast self.vehicle -?]]

        BB_CS_Utils.TirePlayer(self.character, 0.1)
        BB_CS_Utils.TryStopSoundClip(self.character, "MetalBarHit")
        
        if BB_CS_PryUtils.PrySuccessfully(self.character, 20) then
            
            sendClientCommand(self.character, "CommonSense", "PryVehicleOpen", {
                vehicleId = self.vehicleID,
                partId = self.priableObjectID,
            })

            local isTrunk = self.priableObjectID == "TrunkDoor" or self.priableObjectID == "DoorRear"
            if isTrunk then
                -- properly update the vehicle's trunk
                ISTimedActionQueue.add(ISOpenVehicleDoor:new(self.character, self.vehicle, self.priableObject))
            else
                BB_CS_Utils.TryPlaySoundClip(self.character, "VehicleDoorOpen")
            end

            self.character:getXp():AddXP(Perks.Strength, 10)
            tryReturnTool(self.character, self.container)
        else
            self.character:Say(getText("IGUI_CS_PryFail"))
            BB_CS_Utils.TryPlaySoundClip(self.character, "MetalBarBreak")
            self.character:getXp():AddXP(Perks.Strength, 3)

            if SandboxVars.CommonSense.ShatterVehicleWindows and (ZombRand(100)+1 <= SandboxVars.CommonSense.WindowShatterChance) then
                
                sendClientCommand(self.character, "CommonSense", "ShatterVehicleWindow", {
                    vehicleId = self.vehicleID,
                    partId = self.priableObjectID,
                })
            end
        end
            
        --self.vehicle:transmitPartDoor(self.priableObject)
    end

    ISBaseTimedAction.perform(self)
end


---@param worldObjects IsoObject[]
---@param priableObject IsoDoor|IsoWindow
---@param character IsoPlayer
---@param container ItemContainer?
---@param time number
---@return BB_CS_PryTimedAction
function BB_CS_PryTimedAction:PryDoorOrWindow(worldObjects, priableObject, character, container, time)

    ---@diagnostic disable: inject-field
    local action = ISBaseTimedAction.new(self, character)
    action.typeTimeAction = "pryDoorOrWindow"
    action.worldObjects = worldObjects
    action.priableObject = priableObject
    action.character = character
    action.container = container
    action.stopOnWalk = true
    action.stopOnRun = true
    action.maxTime = time
    action.fromHotbar = false

    if action.character:isTimedActionInstant() then action.maxTime = 1 end
    return action
end

---@param vehicle BaseVehicle
---@param priableObject VehiclePart
---@param character IsoPlayer
---@param container ItemContainer?
---@param time number
---@return BB_CS_PryTimedAction
function BB_CS_PryTimedAction:PryVehicleDoor(vehicle, priableObject, character, container, time)

    ---@diagnostic disable: inject-field
    local action = ISBaseTimedAction.new(self, character)
    action.typeTimeAction = "pryVehicleDoor"
    action.vehicle = vehicle
    action.vehicleID = vehicle:getId()
    action.priableObject = priableObject
    action.priableObjectID = priableObject:getId()
    action.character = character
    action.container = container
    action.stopOnWalk = true
    action.stopOnRun = true
    action.maxTime = time
    action.fromHotbar = false

    if action.character:isTimedActionInstant() then action.maxTime = 1 end
    return action
end

return BB_CS_PryTimedAction