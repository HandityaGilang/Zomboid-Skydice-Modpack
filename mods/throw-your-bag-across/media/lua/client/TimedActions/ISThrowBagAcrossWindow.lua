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
	if self.item then
		self.item:setJobType("throwbagacrosswindow");
		self.item:setJobDelta(0.0);
	end
	if self.item2 then
		self.item2:setJobType("throwbagacrosswindow");
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
		self.character:setPrimaryHandItem(nil)
		self.character:getInventory():Remove(self.item)
	end
	if self.item2 then
		self.character:setSecondaryHandItem(nil)
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

function ISThrowBagAcrossWindow:new(character, window, handsItems)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.window = window;
	o.item = handsItems.item;
	o.item2 = handsItems.item2;
	o.stopOnWalk = false;
	o.stopOnRun = false;
	if handsItems.item and handsItems.item2 then
		o.maxTime = 10 * (handsItems.item:getWeight() + handsItems.item2:getWeight());
	elseif handsItems.item then
		o.maxTime = 10 * handsItems.item:getWeight();
	elseif handsItems.item2 then
		o.maxTime = 10 * handsItems.item2:getWeight();
	end
	if o.character:isTimedActionInstant() then o.maxTime = 1; end
	return o
end
