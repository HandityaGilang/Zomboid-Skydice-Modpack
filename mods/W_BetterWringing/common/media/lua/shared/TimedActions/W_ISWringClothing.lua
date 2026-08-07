require "TimedActions/ISBaseTimedAction"

ISWringClothing = ISBaseTimedAction:derive("ISWringClothing")

function ISWringClothing:isValid()
    return self.item and instanceof(self.item, "Clothing") and self.item:getWetness() > 10
end

function ISWringClothing:update()
    self.item:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
end

function ISWringClothing:start()

    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "")
    self:setOverrideHandModels(nil, nil)

    self.sound = self.character:playSound("WashClothing")
    self.character:reportEvent("EventWashClothing")
	
	self.wasEquipped = self.item:isEquipped()

end	

function ISWringClothing:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function ISWringClothing:stop()

    self:stopSound()
    self.item:setJobDelta(0.0)

    ISBaseTimedAction.stop(self)
end

function ISWringClothing:perform()

    self:stopSound()
    self.item:setJobDelta(0.0)

	if self.wasEquipped then
    ISTimedActionQueue.add(ISWearClothing:new(self.character, self.item, 50))
end

    ISBaseTimedAction.perform(self)
end

function ISWringClothing:complete()

    if instanceof(self.item, "Clothing") then

        if self.item:getBodyLocation() == "Shoes" then
            self.item:setWetness(math.min(self.item:getWetness(), 60))
        else
            self.item:setWetness(math.min(self.item:getWetness(), 10))
        end

    end

    syncItemFields(self.character, self.item)
    return true
end

function ISWringClothing:getDuration()

    if self.character:isTimedActionInstant() then
        return 1
    end

    return math.ceil(self.item:getWetness() * 5)
end

function ISWringClothing:new(character, item)

    local o = ISBaseTimedAction.new(self, character)

    o.item = item
    o.maxTime = math.ceil(item:getWetness() * 5)
    o.forceProgressBar = true

    return o
end

function ISWringClothing.DoContextMenu(player, context, items)

    local character = getSpecificPlayer(player)
    local hasWetClothing = false

    for _, item in ipairs(items) do

        local testItem = item

        if not instanceof(item, "InventoryItem") then
            testItem = item.items[1]
        end

        if instanceof(testItem, "Clothing") and testItem:getWetness() > 10 then
            hasWetClothing = true
            break
        end
    end

    if not hasWetClothing then return end

    context:addOption(getText("ContextMenu_Wring Out All Wet Clothing"), player, function()

        local inventory = character:getInventory():getItems()

        for i = 0, inventory:size() - 1 do
            local item = inventory:get(i)

            if instanceof(item, "Clothing") and item:getWetness() > 10 then

                local wasEquipped = item:isEquipped()

                if wasEquipped then
                    ISTimedActionQueue.add(ISUnequipAction:new(character, item, 50))
                end

                ISTimedActionQueue.add(ISWringClothing:new(character, item))

                if wasEquipped then
                    ISTimedActionQueue.add(ISWearClothing:new(character, item, 50))
                end

            end
        end
    end)
end

Events.OnFillInventoryObjectContextMenu.Add(ISWringClothing.DoContextMenu)