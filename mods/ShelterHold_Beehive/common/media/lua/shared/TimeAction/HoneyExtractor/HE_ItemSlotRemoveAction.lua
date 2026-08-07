require "TimedActions/ISBaseTimedAction"

HE_ItemSlotRemoveAction = ISBaseTimedAction:derive("HE_ItemSlotRemoveAction")

function HE_ItemSlotRemoveAction:isValid()
    if self.resource:isEmpty() then return false end
	return true
end

function HE_ItemSlotRemoveAction:update()
	self.character:setMetabolicTarget(Metabolics.LightWork)
	self.character:faceThisObject(self.entity)
end

function HE_ItemSlotRemoveAction:start()
	if self.resource:isEmpty() then
		self:stop()
		return
	end
    if self.itemSlot then
        self.itemSlot.actionRemove = self
    end
    self.item = self.targetItem or self.resource:peekItem()
    self.maxTime = 30+(self.item:getWeight()*3)
	self:setActionAnim("Loot")
	self:setAnimVariable("LootPosition", "")
	self:setOverrideHandModels(nil, nil)
	if self.item:getStaticModel() then
		self:setOverrideHandModels(nil, self.item:getStaticModel())
	end
    local craftBenchSounds = self.entity:getComponent(ComponentType.CraftBenchSounds)
    if craftBenchSounds ~= nil then
        local soundName = craftBenchSounds:getSoundName("RemoveInput", nil)
        if soundName ~= nil and soundName ~= "" then
            self.sound = self.character:playSound(soundName)
        end
    end
end

function HE_ItemSlotRemoveAction:stop()
    ISBaseTimedAction.stop(self)
    self:stopSound()
    if self.item ~= nil then
        self.item:setJobDelta(0.0)
	end
    if self.itemSlot then
        self.itemSlot.actionRemove = nil
    end
end

function HE_ItemSlotRemoveAction:perform()
    self:stopSound()
    if self.item then
		ISInventoryPage.dirtyUI()
    end
    if self.itemSlot then
        self.itemSlot.actionRemove = nil
    end
	ISBaseTimedAction.perform(self)
end

function HE_ItemSlotRemoveAction:complete()
	local removedItem = nil
	if self.targetItem then
		removedItem = self.resource:removeItem(self.targetItem)
	else
		removedItem = self.resource:pollItem()
	end

	if removedItem then
		self.character:getInventory():AddItem(removedItem)
		sendAddItemToContainer(self.character:getInventory(), removedItem)
	end

	return true
end

function HE_ItemSlotRemoveAction:getDuration()
	return 30
end

function HE_ItemSlotRemoveAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function HE_ItemSlotRemoveAction:new(character, entity, resource, item)
	local o = ISBaseTimedAction.new(self, character)
	o.entity = entity
	o.resource = resource
    o.itemSlot = nil
	o.targetItem = item
	o.maxTime = o:getDuration()
	return o
end