require "TimedActions/ISBaseTimedAction"

---@class TATurnOffPump : ISBaseTimedAction
TATurnOffPump = ISBaseTimedAction:derive("TATurnOffPump");

function TATurnOffPump:isValid()
    local x = self.object:getX()
    local y = self.object:getY()
    local z = self.object:getZ()
    local isoPump = WPIso.GetPump(self.square)
    local pump = WPVirtual.PumpGet(x, y, z)

    if isoPump and isoPump:isActivated() and pump and pump.active then
        return true
    else
        return false
    end
end

function TATurnOffPump:update()
    
end

function TATurnOffPump:start()
    self.character:faceThisObject(self.object)
    self:setActionAnim("RemoveCurtain")
    
end

function TATurnOffPump:stop()
    ISBaseTimedAction.stop(self)
end

function TATurnOffPump:perform()

    local x = self.object:getX()
    local y = self.object:getY()
    local z = self.object:getZ()
    local isoPump = WPIso.GetPump(self.square)
    local pump = WPVirtual.PumpGet(x, y, z)

    if isoPump and isoPump:isActivated() and pump and pump.active then
        local active = false
        isoPump:setActivated(active)
        WPVirtual.PumpActivate(x, y, z, active)
        WPSound.RemoveFromObject(isoPump)
    end

    ISBaseTimedAction.perform(self)
end


function TATurnOffPump:new(character, square, object, fresh, fuel)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    
    o.character = character
    o.stopOnWalk = false
    -- o.stopOnRun = false
    o.maxTime = 30

    -- custom fields
    o.object = object
    o.square = square
    o.fresh = fresh
    o.fuel = fuel
    return o
end

return TATurnOffPump;
