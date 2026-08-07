require "TimedActions/ISBaseTimedAction"

Hold_AddHiveFrameAction = ISBaseTimedAction:derive("Hold_AddHiveFrameAction")

function Hold_AddHiveFrameAction:isValid()
    if not self.character:getInventory():contains(self.item) then return false end
    if not self.resource:isEmpty() then return false end
	return true
end

function Hold_AddHiveFrameAction:update()
	self.item:setJobDelta(self:getJobDelta())
	self.character:setMetabolicTarget(Metabolics.LightWork)
	self.character:faceThisObject(self.entity)
end

function Hold_AddHiveFrameAction:start()
	if not self:canStart() then
		self:stop()
		return
	end

    if self.frameSlot then
        self.frameSlot.actionAdd = self
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

function Hold_AddHiveFrameAction:canStart()
	if self.resource:isFull() then
		return false
	end	
	
	if self.canAddItem and not self.canAddItem(self) then
		return false
	end
	
	return true
end

function Hold_AddHiveFrameAction:stop()
    ISBaseTimedAction.stop(self)
    self:stopSound()
    if self.item ~= nil then
        self.item:setJobDelta(0.0)
	end
    if self.frameSlot then
        self.frameSlot.actionAdd = nil
    end
end

function Hold_AddHiveFrameAction:perform()
    self:stopSound()
    if self.item then
		self.item:setJobDelta(0.0)
		if self.item:getContainer() and self.item:getContainer().setDrawDirty then
			self.item:getContainer():setDrawDirty(true)
		end
    end
    if self.frameSlot then
        self.frameSlot.actionAdd = nil
    end
	ISBaseTimedAction.perform(self)
end

function Hold_AddHiveFrameAction:complete()
    if self.canAddItem and not self.canAddItem(self) then return false end

    self.resource:offerItem(self.item)
    
    local beehiveObject = SBeehiveSystem.instance:getLuaObjectOnSquare(self.entity:getSquare())
    beehiveObject:addFrame(self.item, self.slotIndex)
    return true
end

function Hold_AddHiveFrameAction:getDuration()
    local base = 100
    local level = self.character:getPerkLevel(Perks.Husbandry)
    local duration = base - (level * 5)
    if duration < 1 then duration = 1 end
    return duration
end

function Hold_AddHiveFrameAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function Hold_AddHiveFrameAction:new(character, entity, item, slotIndex, resource)
	local o = ISBaseTimedAction.new(self, character)
	o.entity = entity
	o.item = item
	o.resource = resource
	o.itemSlot = nil
	o.slotIndex = slotIndex
	o.maxTime = o:getDuration()
	o.canAddItem = nil
	
	return o
end