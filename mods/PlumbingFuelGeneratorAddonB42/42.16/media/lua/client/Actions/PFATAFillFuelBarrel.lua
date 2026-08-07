require "TimedActions/ISBaseTimedAction"

PFATAFillFuelBarrel = ISBaseTimedAction:derive("PFATAFillFuelBarrel")

function PFATAFillFuelBarrel:isValid()
    return self.square ~= nil
end

function PFATAFillFuelBarrel:update()
end

function PFATAFillFuelBarrel:start()
    self.character:faceThisObject(self.object)
    self:setActionAnim("Loot")
end

function PFATAFillFuelBarrel:stop()
    ISBaseTimedAction.stop(self)
end

function PFATAFillFuelBarrel:perform()
    PFAVirtual.BarrelFuelFill(self.x, self.y, self.z)
    ISBaseTimedAction.perform(self)
end

function PFATAFillFuelBarrel:new(character, square, object, x, y, z)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = 100
    o.object = object
    o.square = square
    o.x = x
    o.y = y
    o.z = z
    return o
end

return PFATAFillFuelBarrel
