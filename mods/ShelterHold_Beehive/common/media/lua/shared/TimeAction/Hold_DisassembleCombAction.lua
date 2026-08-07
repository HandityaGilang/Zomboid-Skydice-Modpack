require "TimedActions/ISBaseTimedAction"

Hold_DisassembleCombAction = ISBaseTimedAction:derive("Hold_DisassembleCombAction")

function Hold_DisassembleCombAction:isValid()
    if self.item and self.character:getInventory():contains(self.item) then
        return true
    end

    return false
end

function Hold_DisassembleCombAction:start()
	self.item:setJobDelta(0.0)
    self:setActionAnim("Craft")
    self:setOverrideHandModels(nil, nil)
end

function Hold_DisassembleCombAction:update()
    self.item:setJobDelta(self:getJobDelta())
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function Hold_DisassembleCombAction:perform()
	ISBaseTimedAction.perform(self)
end

function Hold_DisassembleCombAction:complete()
    self.character:getInventory():Remove(self.item)

    if ZombRand(100) < 60 then
        local beeTypes = {"Hold.Zombee", "Hold.Honeybee", "Hold.Bumblebee"}
        local randomBeeType = beeTypes[ZombRand(#beeTypes) + 1]
        local bee = instanceItem(randomBeeType)
        self.character:getInventory():AddItem(bee)
    end

    if ZombRand(100) < 20 then
        local honey = instanceItem("Base.Honey")
        self.character:getInventory():AddItem(honey)
    end

    local beeswaxCount = ZombRand(3) + 1
    for i = 1, beeswaxCount do
        local beeswax = instanceItem("Hold.Beeswax")
        self.character:getInventory():AddItem(beeswax)
    end
end

function Hold_DisassembleCombAction:stop()
    ISBaseTimedAction.stop(self)
end

function Hold_DisassembleCombAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.maxTime = 100
    return o
end