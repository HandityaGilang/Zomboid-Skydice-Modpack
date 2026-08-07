require "TimedActions/ISBaseTimedAction"

---@class ISPlaceWiresAction : ISBaseTimedAction
ISPlaceWiresAction = ISBaseTimedAction:derive("ISPlaceWiresAction")

function ISPlaceWiresAction:isValid()
	return self.item ~= nil
end

function ISPlaceWiresAction:update()
    self.character:faceThisObject(self.item)
end

function ISPlaceWiresAction:start()
    self:setActionAnim("Build")  -- or whatever your animation name is
   -- self.character:reportEvent("EventPlaceWire")
end

function ISPlaceWiresAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISPlaceWiresAction:perform()
    
    -- Call your known sprite placement function here
    -- Example: placeWireSprite(self.character, self.location, self.wireType)
    self.func(self.data)
    ISBaseTimedAction.perform(self)
end

function ISPlaceWiresAction:new(character,location,time,item,data,func)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.location = location
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time
    o.data = data
    o.item = item
    o.func = func
    if o.character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end
