require "TimedActions/ISBaseTimedAction"

TABAS_ReAttachHotbar = ISBaseTimedAction:derive("TABAS_ReAttachHotbar")

local function resolveAttachmentData(character, attachedItem, item)
    local hotbarEntry = attachedItem
    local hotbar = character and getPlayerHotbar(character:getPlayerNum()) or nil
    if not (hotbar and hotbarEntry and hotbarEntry.slotType) then
        return nil
    end

    local resolvedItem = item or character:getInventory():getItemById(hotbarEntry.itemId)
    local slotIndex = hotbar:getThisSlotIndex(hotbarEntry.slotType)
    local slot = slotIndex and hotbar.availableSlot[slotIndex] or nil
    local slotDef = slot and slot.def or nil
    local attachment = slotDef and slotDef.attachments and slotDef.attachments[resolvedItem and resolvedItem:getAttachmentType() or false] or nil

    if not (resolvedItem and slot and slotDef and attachment) then
        return nil
    end
    if not hotbar:canBeAttached(slot, resolvedItem) then
        return nil
    end

    return {
        hotbar = hotbar,
        item = resolvedItem,
        slotIndex = slotIndex,
        slotDef = slotDef,
        attachment = attachment,
    }
end

function TABAS_ReAttachHotbar:isValid()
	return true
end

function TABAS_ReAttachHotbar:start()
    if not self.playAnim then
        return
    end

    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "")
    self.character:reportEvent("EventLootItem")
end

function TABAS_ReAttachHotbar:perform()
    local attachData = resolveAttachmentData(self.character, self.attachedItem, self.item)
    if attachData then
        attachData.hotbar:attachItem(attachData.item, attachData.attachment, attachData.slotIndex, attachData.slotDef, false)
    end
	ISBaseTimedAction.perform(self)
end

function TABAS_ReAttachHotbar.canAttach(character, attachedItem, item)
    return resolveAttachmentData(character, attachedItem, item) ~= nil
end

function TABAS_ReAttachHotbar:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    if self.playAnim then
        return 50
    end
    return 0
end

function TABAS_ReAttachHotbar:new(character, attachedItem, item, playAnim)
	local o = {}
	setmetatable(o, self)
	self.__index = self
    o.character = character
    o.attachedItem = attachedItem
    o.item = item
    o.playAnim = playAnim and TABAS_ReAttachHotbar.canAttach(character, attachedItem, item) or false
	o.maxTime = o:getDuration()
	return o
end
