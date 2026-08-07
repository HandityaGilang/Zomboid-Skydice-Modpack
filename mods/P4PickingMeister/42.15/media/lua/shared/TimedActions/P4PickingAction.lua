require "TimedActions/ISBaseTimedAction"

P4PickingAction = ISBaseTimedAction:derive("P4PickingAction")

function P4PickingAction:isValid()
	return true
end

function P4PickingAction:start()
	-- Play sound
	self.loopSound = self.character:getEmitter():playSound("RummageInInventory")

	-- Start action animation
	local targetContainer = self.srcParent
	self:setActionAnim("Loot")
	self:setAnimVariable("LootPosition", "")
	self:setOverrideHandModels(nil, nil)
	self.character:clearVariable("LootPosition")
	if targetContainer:getContainerPosition() then
		self:setAnimVariable("LootPosition", targetContainer:getContainerPosition())
	end
	if targetContainer:getType() == "freezer" and targetContainer:getFreezerPosition() then
		self:setAnimVariable("LootPosition", targetContainer:getFreezerPosition())
	end
	if instanceof(targetContainer:getParent(), "IsoDeadBody") or targetContainer:getType() == "floor" then
		self:setAnimVariable("LootPosition", "Low")
	end
	if targetContainer:getContainingItem() and targetContainer:getContainingItem():getWorldItem() then
		self:setAnimVariable("LootPosition", "Low")
	end
end

function P4PickingAction:stopLoopingSound()
	if self.loopSound then
		self.character:getEmitter():stopSound(self.loopSound)
		self.loopSound = nil
	end
end

function P4PickingAction:stop()
	self:stopLoopingSound()
	ISBaseTimedAction.stop(self)
end

function P4PickingAction:perform()
	self:stopLoopingSound()
	ISBaseTimedAction.perform(self)
end

function P4PickingAction:complete()
	if self:updateResources() then
		-- Remove from srcContainer with sync
		self.srcContainer:Remove(self.item)
		sendRemoveItemFromContainer(self.srcContainer, self.item)
		sendReplaceItemInContainer(self.srcParent, self.srcItem, self.srcItem)
		-- Add to destContainer with sync
		local addedItem = self.destContainer:AddItem(self.item)
		if addedItem then
			sendAddItemToContainer(self.destContainer, addedItem)
		end
	end
	return true
end

function P4PickingAction:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	if self:updateResources() then
		return self:calcDuration(self.character, self.item, self.srcContainer, self.destContainer)
	end
	return 1
end

function P4PickingAction:calcDuration(character, item, srcContainer, destContainer)
	-- The method follows the processing of ISInventoryTransferAction:new.
	local maxTime = 120
	local destCapacityDelta = 1.0
	if srcContainer == character:getInventory() then
		if destContainer:isInCharacterInventory(character) then
			destCapacityDelta = destContainer:getCapacityWeight() / destContainer:getMaxWeight()
		else
			maxTime = 50
		end
	elseif not srcContainer:isInCharacterInventory(character) then
		if destContainer:isInCharacterInventory(character) then
			maxTime = 50
		end
	end
	if destCapacityDelta < 0.4 then
		destCapacityDelta = 0.4
	end
	if item then
		local w = item:getActualWeight()
		if w > 3 then w = 3 end
		maxTime = maxTime * w * destCapacityDelta
	end
	if getCore():getGameMode() == "LastStand" then
		maxTime = maxTime * 0.3
	end
	if character:hasTrait(CharacterTrait.DEXTROUS) then
		maxTime = maxTime * 0.5
	end
	if character:hasTrait(CharacterTrait.ALL_THUMBS) or character:isWearingAwkwardGloves() then
		maxTime = maxTime * 2.0
	end
	return maxTime
end

function P4PickingAction:updateResources()
	-- Check input validity
	if not self.itemId then
		return false
	end
	if not self.srcId then
		return false
	end
	if not self.srcParent then
		return false
	end
	if not self.destContainer then
		return false
	end
	-- Initialize resources
	self.srcItem = nil
	self.srcContainer = nil
	self.item = nil
	-- Update resources
	self.srcItem = self.srcParent:getItemById(self.srcId)
	if self.srcItem then
		self.srcContainer = self.srcItem:getInventory()
		if self.srcContainer then
			self.item = self.srcContainer:getItemById(self.itemId)
			if self.item then
				return true
			end
		end
	end
	return false
end

function P4PickingAction:new(character, itemId, srcId, srcParent, destContainer)
	local o = ISBaseTimedAction.new(self, character)
	o.itemId = itemId
	o.item = nil
	o.srcId = srcId
	o.srcItem = nil
	o.srcParent = srcParent
	o.srcContainer = nil
	o.destContainer = destContainer
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = o:getDuration()
	return o
end
