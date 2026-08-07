require "TimedActions/ISBaseTimedAction"

ISThrowBag = ISBaseTimedAction:derive("ISThrowBag");

function ISThrowBag:isValid()
	if self.item then
		return self.character:getInventory():contains(self.item);
	end
	if self.item2 then
		return self.character:getInventory():contains(self.item2);
	end
	return false;
end

function ISThrowBag:update()
	if self.item then
		self.item:setJobDelta(self:getJobDelta());
	end
	if self.item2 then
		self.item2:setJobDelta(self:getJobDelta());
	end
end

function ISThrowBag:start()

	if self.item and self.item2 then
		self.item:setJobType(getText("ContextMenu_Throw_Both") .. " " .. self.item:getName() .. ' and ' .. self.item2:getName());
		self.item:setJobDelta(0.0);
	elseif self.item then
		self.item:setJobType(getText("ContextMenu_Throw_Primary") .. " " .. self.item:getName());
		self.item:setJobDelta(0.0);
	elseif self.item2 then
		self.item2:setJobType(getText("ContextMenu_Throw_Secondary") .. " " .. self.item2:getName());
		self.item2:setJobDelta(0.0);
	end
end

function ISThrowBag:stop()
	if self.item then
		self.item:setJobDelta(0.0);
	end
	if self.item2 then
		self.item2:setJobDelta(0.0);
	end
	ISBaseTimedAction.stop(self);
end

function IsItemBreakable(item)
	local breakSound = item:getBreakSound();
	if breakSound then
		return true;
	end
	return false;
end

function ISThrowBag:breakContainerItems()
	if self.item then
		self.item:getContainer():setDrawDirty(true);
		self.item:setJobDelta(0.0);
		local containerItems = self.item:getContainer():getItems();
		for i=0, containerItems:size()-1 do
			local containerItem = containerItems:get(i);
			if IsItemBreakable(containerItem) and containerItem:getCurrentCondition() < 10 then
				containerItem:Use();
			end
		end
	end
	if self.item2 then
		self.item2:getContainer():setDrawDirty(true);
		self.item2:setJobDelta(0.0);
	end
end

function ISThrowBag:perform()
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

	if self.targetSquare == nil then
		return
	end

	if self.item then
		self.targetSquare:AddWorldInventoryItem(self.item, 0.0, 0.0, 0.0)
	end
	if self.item2 then
		self.targetSquare:AddWorldInventoryItem(self.item2, 0.0, 0.0, 0.0)
	end
	ISInventoryPage.renderDirty = true
	ISBaseTimedAction.perform(self);
end

function ISThrowBag:complete()
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

function ISThrowBag:new(character, targetSquare, handsItems, distances)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
	o.item = handsItems.item;
	o.item2 = handsItems.item2;
	o.stopOnWalk = false;
	o.stopOnRun = false;
	o.targetSquare = targetSquare;
	local min = 20;
	if handsItems.item and handsItems.item2 then
		print("content weight 1: " .. handsItems.item:getContentsWeight());
		print("content weight 2: " .. handsItems.item2:getContentsWeight());
		print("content weight 1: " .. handsItems.item:getContentsWeight());
		print("content weight 2: " .. handsItems.item2:getContentsWeight());
		o.maxTime = 5 * (distances.x + distances.y) + (1 * (handsItems.item:getContentsWeight() + 1)) + (1 * (handsItems.item2:getContentsWeight() + 1));
	elseif handsItems.item then
		o.maxTime = 5 * (distances.x + distances.y) + (1 * (handsItems.item:getContentsWeight() + 1));
	elseif handsItems.item2 then
		o.maxTime = 5 * (distances.x + distances.y) + (1 * (handsItems.item2:getContentsWeight() + 1));
	end
	o.maxTime = math.max(o.maxTime, min);
	if o.character:isTimedActionInstant() then o.maxTime = 1; end
	return o
end
