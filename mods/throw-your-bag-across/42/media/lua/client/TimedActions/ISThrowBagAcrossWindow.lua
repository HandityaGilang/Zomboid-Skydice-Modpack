require "TimedActions/ISBaseTimedAction"

ISThrowBagAcrossWindow = ISBaseTimedAction:derive("ISThrowBagAcrossWindow");

function ISThrowBagAcrossWindow:isValid()
	if self.item then
		return self.character:getInventory():contains(self.item);
	end
	if self.item2 then
		return self.character:getInventory():contains(self.item2);
	end
	return false;
end

function ISThrowBagAcrossWindow:update()
	if self.item then
		self.item:setJobDelta(self:getJobDelta());
	end
	if self.item2 then
		self.item2:setJobDelta(self:getJobDelta());
	end
end

function ISThrowBagAcrossWindow:start()
	if self.item and self.item2 then
		self.item:setJobType(getText("ContextMenu_Throw_Both_Through_Window") .. " " .. self.item:getName() .. ' and ' .. self.item2:getName());
		self.item:setJobDelta(0.0);
	elseif self.item then
		self.item:setJobType(getText("ContextMenu_Throw_Primary_Through_Window") .. " " .. self.item:getName());
		self.item:setJobDelta(0.0);
	elseif self.item2 then
		self.item2:setJobType(getText("ContextMenu_Throw_Secondary_Through_Window") .. " " .. self.item2:getName());
		self.item2:setJobDelta(0.0);
	end
end

function ISThrowBagAcrossWindow:stop()
	if self.item then
		self.item:setJobDelta(0.0);
	end
	if self.item2 then
		self.item2:setJobDelta(0.0);
	end
	ISBaseTimedAction.stop(self);
end

function ISThrowBagAcrossWindow:perform()
	if self.item then
		self.item:getContainer():setDrawDirty(true);
		self.item:setJobDelta(0.0);
	end
	if self.item2 then
		self.item2:getContainer():setDrawDirty(true);
		self.item2:setJobDelta(0.0);
	end

	if self.item then
		self.character:getInventory():Remove(self.item)
	end
	if self.item2 then
		self.character:getInventory():Remove(self.item2)
	end
	self.character:getEmitter():playSound("DropBag");

	local dropSquare = ThrowYourBagAcrossClient.getTargetSquare(self.character, self.window)
	if dropSquare == nil then
		return
	end

	if self.item then
		dropSquare:AddWorldInventoryItem(self.item, 0.0, 0.0, 0.0)
	end
	if self.item2 then
		dropSquare:AddWorldInventoryItem(self.item2, 0.0, 0.0, 0.0)
	end
	ISInventoryPage.renderDirty = true
	ISBaseTimedAction.perform(self);
end

function ISThrowBagAcrossWindow:complete()
	if self.item then
		self.character:setPrimaryHandItem(nil);
		self.character:getInventory():Remove(self.item)
	end
	if self.item2 then
		self.character:setSecondaryHandItem(nil);
		self.character:getInventory():Remove(self.item2)
	end
	ISInventoryPage.renderDirty = true
	return true;
end

function ISThrowBagAcrossWindow:new(character, window, handsItems)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
	o.window = window;
	o.item = handsItems.item;
	o.item2 = handsItems.item2;
	o.stopOnWalk = false;
	o.stopOnRun = false;
	if handsItems.item and handsItems.item2 then
		o.maxTime = 10 * handsItems.item:getWeight() + 10 * handsItems.item2:getWeight();
	elseif handsItems.item then
		o.maxTime = 10 * handsItems.item:getWeight();
	elseif handsItems.item2 then
		o.maxTime = 10 * handsItems.item2:getWeight();
	end
	if o.character:isTimedActionInstant() then o.maxTime = 1; end
	return o
end
