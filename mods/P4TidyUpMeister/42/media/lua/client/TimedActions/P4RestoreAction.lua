require "TimedActions/ISBaseTimedAction"

P4RestoreAction = ISBaseTimedAction:derive("P4RestoreAction")

function P4RestoreAction:isValid()
	return true
end

function P4RestoreAction:perform()
	if self.item:isActivated() ~= self.activated then
		self.item:setActivated(self.activated)
	end
	ISBaseTimedAction.perform(self)
end

function P4RestoreAction:new(character, item, activated, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.item = item
	o.stopOnWalk = false
	o.stopOnRun = false
	o.maxTime = time
	o.activated = activated
	return o
end
