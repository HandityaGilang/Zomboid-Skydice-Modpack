require "TimedActions/ISBaseTimedAction"
require "ISUI/ISLayoutManager"

TAInfoPump = ISBaseTimedAction:derive("TAInfoPump")

function TAInfoPump:isValid()
	return self.object:getObjectIndex() ~= -1
end

function TAInfoPump:perform()
	local window = ISWaterPumpInfoWindow.windows[self.character]
	if window then
		window:setObject(self.object)
	else
		local x = getPlayerScreenLeft(self.playerNum)
		local y = getPlayerScreenTop(self.playerNum)
		local w = getPlayerScreenWidth(self.playerNum)
		local h = getPlayerScreenHeight(self.playerNum)
		window = ISWaterPumpInfoWindow:new(x + 50, y + 80, self.character, self.object)
		window:initialise()
		window:addToUIManager()
		ISWaterPumpInfoWindow.windows[self.character] = window
		if self.character:getPlayerNum() == 0 then
			ISLayoutManager.RegisterWindow('waterpump', ISCollapsableWindow, window)
		end
	end
	window:setVisible(true)
	window:addToUIManager()
	local joypadData = JoypadState.players[self.playerNum+1]
	if joypadData then
		joypadData.focus = window
	end
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function TAInfoPump:new(character, object)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.maxTime = 0
	o.stopOnWalk = true
	o.stopOnRun = true
	o.character = character
	o.playerNum = character:getPlayerNum()
	o.object = object
	return o
end

return TAInfoPump;