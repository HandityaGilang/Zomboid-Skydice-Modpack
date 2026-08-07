require "BuildingObjects/TimedActions/ISBuildAction"

local perform = ISBuildAction.perform

function ISBuildAction:perform()
    perform(self)
	triggerEvent("OnBuildActionPerform", self)
end