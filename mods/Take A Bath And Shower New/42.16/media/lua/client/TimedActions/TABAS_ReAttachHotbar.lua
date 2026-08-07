require "TimedActions/ISBaseTimedAction"

TABAS_ReAttachHotbar = ISBaseTimedAction:derive("TABAS_ReAttachHotbar")

function TABAS_ReAttachHotbar:resolveAttachmentData()
    local hotbar = getPlayerHotbar(self.playerNum) or nil
    local data = self.attachedData
    if not (hotbar and data and data.slotType) then return false end

    local item = self.item or self.character:getInventory():getItemById(data.itemId)
    local slotIndex = data.slotIndex
    local slot = slotIndex and hotbar.availableSlot[slotIndex] or nil
    local slotType = slot and (slot.slotType or (slot.def and slot.def.type)) or nil
    if slotType ~= data.slotType then
        slotIndex = hotbar:getThisSlotIndex(data.slotType)
        slot = slotIndex and hotbar.availableSlot[slotIndex] or nil
    end
    local slotDef = slot and slot.def or nil
    local attachment = slotDef and slotDef.attachments and slotDef.attachments[item and item:getAttachmentType() or false] or nil

    if not (item and slot and slotDef and attachment) then return false end
    if not hotbar:canBeAttached(slot, item) then return false end

    self.hotbar = hotbar
    self.item = item
    self.slotIndex = slotIndex
    self.slotDef = slotDef
    self.attachment = attachment
    return true
end

function TABAS_ReAttachHotbar:isValid()
	return true
end

function TABAS_ReAttachHotbar:start()
    if not self.playAnim then return end

    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "")
    self.character:reportEvent("EventLootItem")
end

function TABAS_ReAttachHotbar:perform()
    if self:resolveAttachmentData() then
        self.hotbar:attachItem(self.item, self.attachment, self.slotIndex, self.slotDef, false)
    end
	ISBaseTimedAction.perform(self)
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

function TABAS_ReAttachHotbar:new(character, item, attachedData, playAnim)
	local o = {}
	setmetatable(o, self)
	self.__index = self
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.attachedData = attachedData
    o.item = item
    o.playAnim = playAnim
	o.maxTime = o:getDuration()
	return o
end
