require "TimedActions/ISBaseTimedAction"

HE_ItemSlotAddAction = ISBaseTimedAction:derive("HE_ItemSlotAddAction")

function HE_ItemSlotAddAction:isValid()
    if not self.character:getInventory():contains(self.item) then return false end
    if not self.resource:isEmpty() then return false end
	return true
end

function HE_ItemSlotAddAction:update()
	self.item:setJobDelta(self:getJobDelta())
	self.character:setMetabolicTarget(Metabolics.LightWork)

	self.character:faceThisObject(self.entity)
end

function HE_ItemSlotAddAction:start()
	if not self:canStart() then
		self:stop()
		return
	end
    if self.itemSlot then
        self.itemSlot.actionAdd = self
    end
	self.item:setJobType("Transferring")
	self.item:setJobDelta(0.0)
	self:setActionAnim("Loot")
	self:setAnimVariable("LootPosition", "")
	self:setOverrideHandModels(nil, nil)
	if self.item:getStaticModel() then
		self:setOverrideHandModels(nil, self.item:getStaticModel())
	end
    local craftBenchSounds = self.entity:getComponent(ComponentType.CraftBenchSounds)
    if craftBenchSounds ~= nil then
        local soundName = craftBenchSounds:getSoundName("AddInput", nil)
        if soundName ~= nil and soundName ~= "" then
            self.sound = self.character:playSound(soundName)
        end
    end
end

function HE_ItemSlotAddAction:stop()
    ISBaseTimedAction.stop(self)
    self:stopSound()
    if self.item ~= nil then
        self.item:setJobDelta(0.0)
	end
    if self.itemSlot then
        self.itemSlot.actionAdd = nil
    end
end

function HE_ItemSlotAddAction:perform()
    self:stopSound()
    if self.item then
		self.item:setJobDelta(0.0)
		if self.item:getContainer() and self.item:getContainer().setDrawDirty then
			self.item:getContainer():setDrawDirty(true)
		end

    end
    if self.itemSlot then
        self.itemSlot.actionAdd = nil
    end
	ISBaseTimedAction.perform(self)
end

function HE_ItemSlotAddAction:complete()
	if self.canAddItem and not self.canAddItem(self) then
		return false
	end
	
	self.resource:offerItem(self.item)
	return true
end

function HE_ItemSlotAddAction:getDuration()
	return 30+(self.item:getWeight()*3)
end

function HE_ItemSlotAddAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function HE_ItemSlotAddAction:canStart()
	if self.resource:isFull() then
		return false
	end	
	
	if self.canAddItem and not self.canAddItem(self) then
		return false
	end
	
	return true
end

function HE_ItemSlotAddAction:new(character, entity, item, resource)
	local o = ISBaseTimedAction.new(self, character)
	o.entity = entity
	o.item = item
	o.resource = resource
    o.itemSlot = nil
	o.maxTime = o:getDuration()
	o.canAddItem = nil
	
	return o
end