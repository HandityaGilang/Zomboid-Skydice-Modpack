require "TimedActions/ISBaseTimedAction"

---@class TARepairPump : ISBaseTimedAction
TARepairPump = ISBaseTimedAction:derive("TARepairPump");

function TARepairPump:isValid()
    local x = self.object:getX()
    local y = self.object:getY()
    local z = self.object:getZ()
    local isoPump = WPIso.GetPump(self.square)
    local pump = WPVirtual.PumpGet(x, y, z)

    local scrapItem = self.character:getInventory():getFirstTypeRecurse("ScrapMetal")
    if isoPump and pump and scrapItem and pump.efficiency < 95 and not pump.active then
        return true
    else
        return false
    end
end

function TARepairPump:update()
    self.character:faceThisObject(self.object)
    self.character:setMetabolicTarget(Metabolics.UsingTools);
end

function TARepairPump:waitToStart()
    self.character:faceThisObject(self.object)
    return self.character:shouldBeTurning()
end

function TARepairPump:start()
    self:setActionAnim("RemoveCurtain")
    self.sound = self.character:playSound("GeneratorRepair")
end

function TARepairPump:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self)
end

function TARepairPump:perform()
    self.character:stopOrTriggerSound(self.sound)

    local x = self.object:getX()
    local y = self.object:getY()
    local z = self.object:getZ()
    local isoPump = WPIso.GetPump(self.square)
    local pump = WPVirtual.PumpGet(x, y, z)

    local scrapItem = self.character:getInventory():getFirstTypeRecurse("ScrapMetal")
    if isoPump and pump and scrapItem and pump.efficiency <= 95 and not pump.active then

        pump.efficiency = pump.efficiency + 5

        self.character:removeFromHands(scrapItem)
        self.character:getInventory():Remove(scrapItem)
    end

    ISBaseTimedAction.perform(self)
end


function TARepairPump:new(character, square, object)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    
    
    o.character = character
    o.stopOnWalk = false
    -- o.stopOnRun = false
    o.maxTime = 250

    -- custom fields
    o.object = object
    o.square = square
    return o
end

return TARepairPump;
