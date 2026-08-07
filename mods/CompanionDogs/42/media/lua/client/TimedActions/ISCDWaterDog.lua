require "TimedActions/ISCDBaseDogAction"

ISCDWaterDog = ISCDBaseDogAction:derive("ISCDWaterDog")

function ISCDWaterDog:isValid()
    local fc = self.item and self.item:getFluidContainer()
    return self.character:getInventory():containsRecursive(self.item) and fc ~= nil and not fc:isEmpty()
end

function ISCDWaterDog:doEffect()
    if self.cdDone then return end
    self.cdDone = true
    pcall(function() self.animal:getBehavior():setBlockMovement(false) end)
    -- O fluido agora e gasto no server (seguro contra anticheat, sem desync client/server); so passa o id da fonte.
    CompanionDogs.request("water", self.animal, { waterId = self.item and self.item:getID() })
end

function ISCDWaterDog:new(character, animal, item)
    local o = ISBaseTimedAction.new(self, character)
    o.animal = animal
    o.item = item
    o.handModelItem = item
    o.soundName = "GiveWaterAnimal"
    o.cdMaxTicks = 75
    o.cdDuration = 150
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
