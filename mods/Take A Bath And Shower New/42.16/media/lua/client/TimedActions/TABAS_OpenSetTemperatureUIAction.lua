require "TimedActions/ISBaseTimedAction"

TABAS_OpenSetTemperatureUIAction = ISBaseTimedAction:derive("TABAS_OpenSetTemperatureUIAction")

function TABAS_OpenSetTemperatureUIAction:isValid()
    return true
end

function TABAS_OpenSetTemperatureUIAction:start()
    local modData = self.character:getModData()
	if not modData.tabas_IsBathing then
		self.character:faceThisObject(self.bathObject)
	end
end

function TABAS_OpenSetTemperatureUIAction:stop()
    ISBaseTimedAction.stop(self)
end

function TABAS_OpenSetTemperatureUIAction:perform()
    if self.panel then
		self.panel.OpenPanel(self.character, self.bathObject)
	end
    ISBaseTimedAction.perform(self)
end

function TABAS_OpenSetTemperatureUIAction:new(character, bathObject)
    local o = ISBaseTimedAction.new(self, character)
    o.panel = TABAS_TemperatureSettingUI
    o.bathObject = bathObject
    o.maxTime = 1
    return o
end