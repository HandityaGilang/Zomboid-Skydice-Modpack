require "TimedActions/ISBaseTimedAction"

Hold_ExtractHoneyAction = ISBaseTimedAction:derive("Hold_ExtractHoneyAction")

local function Hold_SyncHoneyExtractorEntity(entity)
    if isServer() and entity then
        entity:sendSyncEntity(nil)
    end
end

function Hold_ExtractHoneyAction:isValid()
    if not self.entity then return false end
    if not self.entity:getFluidContainer() then return false end
    if not self.entity:hasComponent(ComponentType.Resources) then return false end
    
    return true
end

function Hold_ExtractHoneyAction:update()
    self.character:faceThisObject(self.entity)
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function Hold_ExtractHoneyAction:start()
    if self.UItarget then
        self.UItarget.actionExtract = self
    end

    self:setActionAnim("disassemble")
    self:setOverrideHandModels(nil, nil)
    self.sound = self.character:playSound("CraftingSound")
end


function Hold_ExtractHoneyAction:stop()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end

    if self.UItarget then
        self.UItarget.actionExtract = nil
    end

    ISBaseTimedAction.stop(self)
end

function Hold_ExtractHoneyAction:complete()
    local damageChance = 20
    local isAddDamage = ZombRand(100) < damageChance
    local resources = self.entity:getComponent(ComponentType.Resources)
    local inputResources = resources:getResourcesForGroup("input_slot")
    local fluidContainer = self.entity:getFluidContainer()

    local frameCount = 0
    local fluidToAdd = 0

    if inputResources then
        for i = 0, inputResources:size() - 1 do
            local resource = inputResources:get(i)
            if resource and not resource:isEmpty() then
                local item = resource:peekItem()
                if item and item:getCurrentUsesFloat() >= 0.5 then
                    frameCount = frameCount + 1
                    fluidToAdd = fluidToAdd + (item:getCurrentUsesFloat() - 0.25) * 2

                    local itemCondition = item:getCondition()
                    resource:removeItem(item)
                    if isAddDamage then
                        itemCondition = itemCondition - 1
                    end
                    if itemCondition > 0 then
                        local newItem = instanceItem("Hold.HiveFrame_Wax")
                        newItem:setCondition(itemCondition)
                        newItem:setCurrentUsesFloat(0.25)
                        resource:offerItem(newItem)
                    else
                        local newItem = instanceItem("Hold.HiveFrame_Basic")
                        newItem:setCondition(itemCondition)
                        newItem:setCurrentUsesFloat(0.0)
                        resource:offerItem(newItem)
                    end

                end
            end
        end
    end

    if frameCount > 0 then
        local freeCapacity = fluidContainer:getFreeCapacity()
        local amountToAdd = math.min(fluidToAdd, freeCapacity)
        if amountToAdd > 0 then
            fluidContainer:addFluid("RawHoney", amountToAdd)
        end
        Hold_SyncHoneyExtractorEntity(self.entity)
    end

    if self.UItarget then
        self.UItarget.actionExtract = nil
    end
    
    return true
end

function Hold_ExtractHoneyAction:perform()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end

    ISBaseTimedAction.perform(self)
end

function Hold_ExtractHoneyAction:new(character, entity)
    local o = ISBaseTimedAction.new(self, character)
    
    o.entity = entity
    o.character = character
    o.maxTime = 110
    
    return o
end