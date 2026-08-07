require "TimedActions/ISBaseTimedAction"

TATurnOnPump = ISBaseTimedAction:derive("TATurnOnPump");

function TATurnOnPump:isValid()
    local x = self.object:getX()
    local y = self.object:getY()
    local z = self.object:getZ()
    local isoPump = WPIso.GetPump(self.square)
    local pump = WPVirtual.PumpGet(x, y, z)

    if isoPump and not isoPump:isActivated() and pump and not pump.active and pump.efficiency > 0 and self.square:haveElectricity() then
        return true
    else
        return false
    end
end

function TATurnOnPump:update()
end

function TATurnOnPump:start()
    self.character:faceThisObject(self.object)
    self:setActionAnim("RemoveCurtain")
end

function TATurnOnPump:stop()
    ISBaseTimedAction.stop(self)
end

function TATurnOnPump:perform()
    
    local x = self.object:getX()
    local y = self.object:getY()
    local z = self.object:getZ()
    local isoPump = WPIso.GetPump(self.square)
    local pump = WPVirtual.PumpGet(x, y, z)

    if isoPump and not isoPump:isActivated() and pump and not pump.active and pump.efficiency > 0 and self.square:haveElectricity() then
        local active = true
        isoPump:setActivated(active)
        WPVirtual.PumpActivate(x, y, z, active)
        WPSound.AddToObject(isoPump, "WPWaterPumpLoop", 0.5)
    end

    ISBaseTimedAction.perform(self)
end


function TATurnOnPump:new(character, square, object)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = 60
    o.object = object
    o.square = square
    return o
end

return TATurnOnPump;
