require "TimedActions/ISBaseTimedAction"

---@class TASwitchValve : ISBaseTimedAction
TASwitchValve = ISBaseTimedAction:derive("TASwitchValve")

function TASwitchValve:isValid()
	return true
end

function TASwitchValve:update()
end

function TASwitchValve:start()
	self:setActionAnim("BuildPipe")
	self.sound = self.character:playSound("RepairWithWrench")
end

function TASwitchValve:stop()
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self);
end

function TASwitchValve:perform()
	self.character:stopOrTriggerSound(self.sound)
	
	local x = self.object:getX()
	local y = self.object:getY()
	local z = self.object:getZ()
	local c = self.closed

	WPVirtual.ValveSwitch(x, y, z, c)

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function TASwitchValve:new(character, square, object, closed)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.maxTime = 0
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = 150
	o.character = character
	o.playerNum = character:getPlayerNum()
	o.square = square
	o.object = object
	o.closed = closed
	return o
end

return TASwitchValve;