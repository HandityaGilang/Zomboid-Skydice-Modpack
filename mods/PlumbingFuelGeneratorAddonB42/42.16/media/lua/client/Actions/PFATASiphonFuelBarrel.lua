require "TimedActions/ISBaseTimedAction"

PFATASiphonFuelBarrel = ISBaseTimedAction:derive("PFATASiphonFuelBarrel")

function PFATASiphonFuelBarrel:isValid()
    return self.square ~= nil
end

function PFATASiphonFuelBarrel:update()
end

function PFATASiphonFuelBarrel:start()
    self.character:faceThisObject(self.object)
    self:setActionAnim("Loot")
end

function PFATASiphonFuelBarrel:stop()
    ISBaseTimedAction.stop(self)
end

function PFATASiphonFuelBarrel:perform()
    PFAVirtual.BarrelFuelSiphon(self.x, self.y, self.z)
    ISBaseTimedAction.perform(self)
end

function PFATASiphonFuelBarrel:new(character, square, object, x, y, z)
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

return PFATASiphonFuelBarrel
