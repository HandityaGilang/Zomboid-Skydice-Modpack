require "TimedActions/ISBaseTimedAction"

Hold_AddQueenAction = ISBaseTimedAction:derive("Hold_AddQueenAction")

function Hold_AddQueenAction:isValid()
    if not self.character:getInventory():contains(self.item) then return false end
    if not self.resource:isEmpty() then return false end
	return true
end

function Hold_AddQueenAction:update()
    self.item:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightWork)
    self.character:faceThisObject(self.entity)
end

function Hold_AddQueenAction:start()
	if not self:canStart() then
		self:stop()
		return
	end

    if self.queenSlot then
        self.queenSlot.actionAdd = self
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

function Hold_AddQueenAction:canStart()
	if self.resource:isFull() then
		return false
	end	
	
	if self.canAddItem and not self.canAddItem(self) then
		return false
	end
	
	return true
end

function Hold_AddQueenAction:stop()
    ISBaseTimedAction.stop(self)
    self:stopSound()
    if self.item ~= nil then
        self.item:setJobDelta(0.0)
	end
    if self.queenSlot then
        self.queenSlot.actionAdd = nil
    end
end

function Hold_AddQueenAction:perform()
    self:stopSound()
    if self.item then
		self.item:setJobDelta(0.0)
		if self.item:getContainer() and self.item:getContainer().setDrawDirty then
			self.item:getContainer():setDrawDirty(true)
		end
    end
    if self.queenSlot then
        self.queenSlot.actionAdd = nil
    end
	ISBaseTimedAction.perform(self)
end

function Hold_AddQueenAction:complete()
	if self.canAddItem and not self.canAddItem(self) then return false end

    self.resource:offerItem(self.item)
    
    local beehiveObject = SBeehiveSystem.instance:getLuaObjectOnSquare(self.entity:getSquare())
    beehiveObject:addQueen(self.item)
    
    return true
end

function Hold_AddQueenAction:getDuration()
    local base = 100
    local level = self.character:getPerkLevel(Perks.Husbandry)
    local duration = base - (level * 5)
    if duration < 1 then duration = 1 end
    return duration
end

function Hold_AddQueenAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function Hold_AddQueenAction:new(character, entity, item, resource)
    local o = ISBaseTimedAction.new(self, character)
    o.entity = entity
    o.item = item
    o.resource = resource
    o.queenSlot = nil
    o.maxTime = o:getDuration()
    o.canAddItem = nil
    return o
end