require "TimedActions/ISBaseTimedAction"

P4RestoreAction = ISBaseTimedAction:derive("P4RestoreAction")

function P4RestoreAction:isValid()
	local invItem = self.character:getInventory():getItemWithID(self.item:getID())
	if invItem then
		self.item = invItem
		return true
	else
		return false
	end
end

function P4RestoreAction:perform()
	ISBaseTimedAction.perform(self)
end

function P4RestoreAction:complete()
	if self.item:isActivated() ~= self.activated then
		self.item:setActivated(self.activated)
		if isServer() then
			syncItemActivated(self.character, self.item)
		end
	end
	return true
end

function P4RestoreAction:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 1
end

function P4RestoreAction:new(character, item, activated)
	local o = ISBaseTimedAction.new(self, character)
	o.item = item
	o.activated = activated
	o.stopOnWalk = false
	o.stopOnRun = false
	o.maxTime = o:getDuration()
	return o
end
