require "TimedActions/ISBaseTimedAction"

TABAS_OpenPanelAction = ISBaseTimedAction:derive("TABAS_OpenPanelAction")

function TABAS_OpenPanelAction:isValid()
    return true
end

function TABAS_OpenPanelAction:waitToStart()
	local modData = self.character:getModData()
	if not modData.tabas_IsBathing then
		self.character:faceThisObject(self.tfc_Base.bathObject)
	end
	return self.character:shouldBeTurning()
end

function TABAS_OpenPanelAction:update()
end

function TABAS_OpenPanelAction:start()
end

function TABAS_OpenPanelAction:stop()
	ISBaseTimedAction.stop(self)
end

function TABAS_OpenPanelAction:perform()
	if self.panel then
		self.panel.OpenPanel(self.character, self.tfc_Base)
	end
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end


function TABAS_OpenPanelAction:new(character, tfc_Base)
	local o = ISBaseTimedAction.new(self, character)
    o.panel = TABAS_TubFluidContainerInfoUI
    o.tfc_Base = tfc_Base
    o.tabasAutoModeAction = true
	o.maxTime = 1
	return o
end
