require "TimedActions/ISBaseTimedAction"

---@class ISRemoveWiresAction : ISBaseTimedAction
ISRemoveWiresAction = ISBaseTimedAction:derive("ISRemoveWiresAction")

function ISRemoveWiresAction:isValid()
	return self.item ~= nil
end

function ISRemoveWiresAction:update()
    self.character:faceThisObject(self.item)
end

function ISRemoveWiresAction:start()
    self:setActionAnim("Build")  -- or whatever your animation name is
   -- self.character:reportEvent("EventPlaceWire")
end

function ISRemoveWiresAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISRemoveWiresAction:perform()
    
    -- Call your known sprite placement function here
    -- Example: placeWireSprite(self.character, self.location, self.wireType)
    self.removeWire(self.item)
   -- CL.removewire(self.item)
    ISBaseTimedAction.perform(self)
end

function ISRemoveWiresAction:new(character,location,time,item,func)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.location = location
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time
    o.item = item
    o.removeWire = func
    if o.character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end