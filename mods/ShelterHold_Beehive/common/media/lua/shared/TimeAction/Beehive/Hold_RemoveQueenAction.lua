require "TimedActions/ISBaseTimedAction"
require "ShelterHold/Hold_BeehiveCompat"

Hold_RemoveQueenAction = ISBaseTimedAction:derive("Hold_RemoveQueenAction")

function Hold_RemoveQueenAction:isValid()
    if self.resource:isEmpty() then return false end
	return true
end

function Hold_RemoveQueenAction:update()
    self.character:setMetabolicTarget(Metabolics.LightWork)
    self.character:faceThisObject(self.entity)
end

function Hold_RemoveQueenAction:start()
	if self.resource:isEmpty() then
		self:stop()
		return
	end

    if self.queenSlot then
        self.queenSlot.actionRemove = self
    end

    self.item = self.targetItem or self.resource:peekItem()
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

function Hold_RemoveQueenAction:stop()
    ISBaseTimedAction.stop(self)
    self:stopSound()
    if self.item ~= nil then
        self.item:setJobDelta(0.0)
	end
    if self.queenSlot then
        self.queenSlot.actionRemove = nil
    end
end

function Hold_RemoveQueenAction:perform()
    self:stopSound()
    if self.item then
		ISInventoryPage.dirtyUI()
    end
    if self.queenSlot then
        self.queenSlot.actionRemove = nil
    end
	ISBaseTimedAction.perform(self)
end

function Hold_RemoveQueenAction:complete()
    local removedItem = nil
	if self.targetItem then
		removedItem = self.resource:removeItem(self.targetItem)
	else
		removedItem = self.resource:pollItem()
	end

	if removedItem then
		self.character:getInventory():AddItem(removedItem)
		sendAddItemToContainer(self.character:getInventory(), removedItem)
        
        local beehiveObject = SBeehiveSystem.instance:getLuaObjectOnSquare(self.entity:getSquare())
        beehiveObject:removeQueen()
	end

    self:checkBeeSting()
    return true
end

function Hold_RemoveQueenAction:checkBeeSting()
    local modData = self.entity:getModData()
    local zombeeInside = modData.queenBee == "Zombee"
    
    if not zombeeInside and not getGameTime():isDay() then return end

    if not modData.queenBee then return end

    if self:isWearingProtectSuit() then return end

    local baseChance = 40
    local skillLevel = self.character:getPerkLevel(Perks.Husbandry)
    local chance = math.max(0, (baseChance - (baseChance / 10) * skillLevel))
    if ZombRand(100) < chance then
        local bodyPart = self.character:getBodyDamage():getBodyPart(BodyPartType.getRandom())
        if bodyPart and bodyPart:getType() ~= BodyPartType.Neck then
            local bleedingTime = bodyPart:getBleedingTime()
            local oldScratchTime = bodyPart:getScratchTime()
            bodyPart:setScratched(true, false)
            bodyPart:setBleedingTime(bleedingTime)
            local newScratchTime = bodyPart:getScratchTime()
            if oldScratchTime > 0 then
                bodyPart:setScratchTime((newScratchTime - oldScratchTime) * 0.02 + oldScratchTime)
            else
                bodyPart:setScratchTime(newScratchTime * 0.02)
            end
        end

        getSoundManager():playUISound("Hold_BeePrick")
    end
end

function Hold_RemoveQueenAction:isWearingProtectSuit()
    local wornItems = self.character:getWornItems()
    if not wornItems then return false end

    local hasSpiffoSuit = false
    local hasSpiffoHat = false
    
    for i = 0, wornItems:size() - 1 do
        local wornItem = wornItems:get(i)
        local item = wornItem:getItem()
        if HoldBeehiveCompat.isHazmatSuit(item) then
            return true
        end
		local itemType = item:getFullType()
		if itemType == "Base.SpiffoSuit" then
			hasSpiffoSuit = true
		elseif itemType == "Base.Hat_Spiffo" then
			hasSpiffoHat = true
		end
    end
    
    return hasSpiffoSuit and hasSpiffoHat
end

function Hold_RemoveQueenAction:getDuration()
    local base = 100
    local level = self.character:getPerkLevel(Perks.Husbandry)
    local duration = base - (level * 5)
    if duration < 1 then duration = 1 end
    return duration
end

function Hold_RemoveQueenAction:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function Hold_RemoveQueenAction:new(character, entity, resource, item)
    local o = ISBaseTimedAction.new(self, character)
    o.entity = entity
    o.resource = resource
    o.queenSlot = nil
    o.targetItem = item
    o.maxTime = o:getDuration()
    return o
end