require "TimedActions/ISBaseTimedAction"


ISRepairEnginePart = ISBaseTimedAction:derive("ISRepairEnginePart")

function ISRepairEnginePart:isValid()
	return true
end

function ISRepairEnginePart:waitToStart()
	return false
end

function ISRepairEnginePart:update()
	self.item:setJobDelta(self:getJobDelta())

    self.character:setMetabolicTarget(Metabolics.MediumWork);
end

function ISRepairEnginePart:start()
    --if isClient() and self.item then
    --    self.item = self.character:getInventory():getItemById(self.item:getID())
    --end
	self.item:setJobType(self.jobType)
	self:setActionAnim("VehicleWorkOnMid")
end

function ISRepairEnginePart:stop()
	self.item:setJobDelta(0)
	ISBaseTimedAction.stop(self)
end

function ISRepairEnginePart:perform()
    local pdata = getPlayerData(self.character:getPlayerNum());
    if pdata ~= nil then
       	pdata.playerInventory:refreshBackpacks();
        pdata.lootInventory:refreshBackpacks();
    end
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
	self.item:setJobDelta(0)
end

function ISRepairEnginePart:complete()
	RepairPartSelectInternal(self.item, self.character, self.failureModeIndex, self.repairIndex)
	return true
end

function ISRepairEnginePart:getDuration()
    if self.character:isMechanicsCheat() or self.character:isTimedActionInstant() then
        return 1
    end
	return 50;
end

function ISRepairEnginePart:new(character, item, failureModeIndex, repairIndex)
	local o = ISBaseTimedAction.new(self, character)
	o.failureModeIndex = failureModeIndex;
	o.repairIndex = repairIndex;
	o.item = item

	o.maxTime = o:getDuration(); 
	o.workTime = o.maxTime;
	o.jobType = "Repairing " .. item:getDisplayName() --getText("Tooltip_Vehicle_Repairing", item:getDisplayName());
	return o
end

