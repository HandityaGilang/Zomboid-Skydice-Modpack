require "TimedActions/ISBaseTimedAction"

ISClothingExtraAction = ISBaseTimedAction:derive("ISClothingExtraAction")

function ISClothingExtraAction:isValid()
    if not self.item then return false end
    if self.item.isBroken and self.item:isBroken() then return false end
    return isClient() or self.character:getInventory():contains(self.item)
end

function ISClothingExtraAction:waitToStart()
    return false
end

function ISClothingExtraAction:update()
    if not self.item then return end
    self.item:setJobDelta(self:getJobDelta());

    if not self.equipSound and self:getJobDelta() > 0.7 and self.item and self.item:getEquipSound() then
        self.equipSound = self.character:playSound(self.item:getEquipSound())
    end
end

function ISClothingExtraAction:start()
    if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
    
    if not self.item then return end
    
    self.item:setJobType(getText("ContextMenu_Wear"));
    self.item:setJobDelta(0.0);
    self:setActionAnim("WearClothing");
    
    if self.item:IsClothing() then
        local location = self.item:getBodyLocation()
        self:setAnimVariable("WearClothingLocation", WearClothingAnimations[location] or "")
    elseif self.item:IsInventoryContainer() and self.item:canBeEquipped() ~= "" then
        local location = self.item:canBeEquipped()
        self:setAnimVariable("WearClothingLocation", WearClothingAnimations[location] or "")
    end
    self.character:reportEvent("EventWearClothing");
end

function ISClothingExtraAction:stop()
    self:stopSound()
    if self.item then
        self.item:setJobDelta(0.0);
    end
    ISBaseTimedAction.stop(self)
end

function ISClothingExtraAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function ISClothingExtraAction:createItem(item, itemType)
    if not item or not itemType then return nil end
    local newItem = instanceItem(itemType)
    return self:createItemNew(item, newItem)
end

function copyClothingItem(item, newItem)
    if not item or not newItem then return nil end
    ISClothingExtraAction:createItemNew(item, newItem)
end

function ISClothingExtraAction:createItemNew(item, newItem)
    if not item or not newItem then return nil end
    
    local visual = item:getVisual()
    if not visual then return newItem end
    
    local newVisual = newItem:getVisual()
    if not newVisual then return newItem end
    
    -- Copiar tint com verificacao
    local clothingItem = item:getClothingItem()
    if clothingItem then
        newVisual:setTint(visual:getTint(clothingItem))
        newVisual:setDecal(visual:getDecal(clothingItem))
    end
    
    newVisual:setBaseTexture(visual:getBaseTexture())
    newVisual:setTextureChoice(visual:getTextureChoice())
    
    if newItem:IsInventoryContainer() and item:IsInventoryContainer() then
        local newContainer = newItem:getItemContainer()
        local oldContainer = item:getItemContainer()
        if newContainer and oldContainer then
            newContainer:takeItemsFrom(oldContainer)
        end
        -- Handle renamed bag
        local scriptItem = item:getScriptItem()
        if scriptItem and item:getName() ~= scriptItem:getDisplayName() then
            newItem:setName(item:getName())
        end
    end
    
    newItem:setColor(item:getColor())
    newVisual:copyDirt(visual)
    newVisual:copyBlood(visual)
    newVisual:copyHoles(visual)
    newVisual:copyPatches(visual)
    
    if newItem:IsClothing() then
        item:copyPatchesTo(newItem)
        newItem:setWetness(item:getWetness())
    end
    
    if instanceof(newItem, "AlarmClockClothing") and instanceof(item, "AlarmClockClothing") then
        newItem:setAlarmSet(item:isAlarmSet())
        newItem:setHour(item:getHour())
        newItem:setMinute(item:getMinute())
        newItem:syncAlarmClock()
        item:setAlarmSet(false)
        item:syncAlarmClock()
    end
    
    -- FluidContainer com verificacao
    local newFluidCont = newItem:getFluidContainer()
    local oldFluidCont = item:getFluidContainer()
    if newFluidCont and oldFluidCont then
        newFluidCont:copyFluidsFrom(oldFluidCont)
    end
    
    newItem:setCondition(item:getCondition())
    newItem:setFavorite(item:isFavorite())
    
    if item:hasModData() then
        newItem:copyModData(item:getModData())
    end
    
    newItem:synchWithVisual()
    return newItem
end

function ISClothingExtraAction:perform()
    self:stopSound()
    if self.item then
        self.item:setJobDelta(0.0);
    end
    
    local playerNum = self.character:getPlayerNum()
    if playerNum then
        getPlayerInventory(playerNum):refreshBackpacks();
    end
    triggerEvent("OnClothingUpdated", self.character)

    ISBaseTimedAction.perform(self)
end

function ISClothingExtraAction:complete()
    if not self.item or not self.extra then
        return false
    end
    
    self.character:removeFromHands(self.item)
    self.character:removeWornItem(self.item, false)
    self.character:getInventory():Remove(self.item)
    sendRemoveItemFromContainer(self.character:getInventory(), self.item);

    local newItem = self:createItem(self.item, self.extra)
    if not newItem then
        return false
    end
    
    self.character:getInventory():AddItem(newItem)
    sendAddItemToContainer(self.character:getInventory(), newItem);

    if newItem:IsInventoryContainer() and newItem:canBeEquipped() ~= "" then
        self.character:setWornItem(newItem:canBeEquipped(), newItem)
        sendClothing(self.character, newItem:canBeEquipped(), newItem);
    elseif newItem:IsClothing() then
        self.character:setWornItem(newItem:getBodyLocation(), newItem)
        sendClothing(self.character, newItem:getBodyLocation(), newItem);
    end

    if newItem:hasTag(ItemTag.REPLACE_PRIMARY) then
        if self.character:getPrimaryHandItem() then
            self.character:removeFromHands(self.character:getPrimaryHandItem())
        end
        self.character:setPrimaryHandItem(newItem)
        sendEquip(self.character)
    end

    return true
end

function ISClothingExtraAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    if self.item and self.character:isEquippedClothing(self.item) then
        return 1
    end

    return 50
end

function ISClothingExtraAction:new(character, item, extra)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.extra = extra
    o.maxTime = o:getDuration()
    
    -- Verificacao segura para stopOnWalk
    o.stopOnWalk = false
    if item then
        local success, result = pcall(function()
            return ISWearClothing.isStopOnWalk(item)
        end)
        if success and result ~= nil then
            o.stopOnWalk = result
        end
    end
    
    return o
end
