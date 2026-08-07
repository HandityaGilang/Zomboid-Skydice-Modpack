require "TimedActions/ISBaseTimedAction"

TABAS_ReEquipItems = ISBaseTimedAction:derive("TABAS_ReEquipItems")

local function getInventoryItemById(character, itemData, fallbackItem)
    if not character then return nil end

    local inv = character:getInventory()
    if not inv then return nil end

    local itemId = itemData and itemData.itemId
    if not itemId and fallbackItem and instanceof(fallbackItem, "InventoryItem") then
        itemId = fallbackItem:getID()
    end
    if not itemId then return nil end

    return inv:getItemById(itemId) or inv:getItemWithID(itemId)
end

function TABAS_ReEquipItems:isValid()
    return self.item ~= nil and self.itemData ~= nil
end

function TABAS_ReEquipItems:waitToStart()
    return self.character:shouldBeTurning()
end

function TABAS_ReEquipItems:start()
    local itemData = self.itemData
    self.item = getInventoryItemById(self.character, itemData, self.item)
    if self.item then
        itemData.item = self.item
    end
    if not self.item then
        self:forceComplete()
        return
    end

    if itemData.isFavorite then
        self.item:setFavorite(true)
    end

    self:beginAddingActions()

    if self.kind == "clothes" then
        ISTimedActionQueue.add(ISWearClothing:new(self.character, self.item))
    elseif self.kind == "attachedItems" then
        ISTimedActionQueue.add(TABAS_ReAttachHotbar:new(self.character, self.item, itemData, self.doAttachAnim))
    elseif self.kind == "secondary" then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, self.item, 50, false, false))
    elseif self.kind == "primary" then
        local isBothHands = itemData.isBothHands or false
        ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, self.item, 50, true, isBothHands))
    end
    ISInventoryPage.renderDirty = true

    self:endAddingActions()

    self:forceComplete()
end

function TABAS_ReEquipItems:perform()
    
    ISBaseTimedAction.perform(self)
end

function TABAS_ReEquipItems:new(character, kind, item, itemData, doAttachAnim)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.kind = kind
    o.item = item
    o.itemData = itemData
    o.doAttachAnim = doAttachAnim == true
    o.maxTime = 0
    return o
end
