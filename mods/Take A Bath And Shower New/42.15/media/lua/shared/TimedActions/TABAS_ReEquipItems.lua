require "TimedActions/ISBaseTimedAction"

TABAS_ReEquipItems = ISBaseTimedAction:derive("TABAS_ReEquipItems")

local TABAS_ReEquipItemsUtils = require("TABAS_ReEquipItemsUtils")

function TABAS_ReEquipItems:isValid()
    return TABAS_ReEquipItemsUtils.hasStoredItems(self.character)
end

function TABAS_ReEquipItems:waitToStart()
    if self.character:isCurrentState(ClimbOverFenceState.instance()) then
        return true
    end
    return self.character:shouldBeTurning()
end

function TABAS_ReEquipItems:start()
    local md = self.character:getModData()
    local equippedItems = md and md.tabas_EquippedItems
    local currentEntry = TABAS_ReEquipItemsUtils.getCurrentStoredEntry(equippedItems, self.kind, self.entry)
    local addedAction = false

    if not currentEntry then
        self:forceStop()
        return
    end

    local item = self.item or TABAS_ReEquipItemsUtils.resolveStoredItem(self.character, equippedItems, currentEntry)

    self:beginAddingActions()
    if item then
        if self.kind == "WornClothes" then
            ISTimedActionQueue.add(ISWearClothing:new(self.character, item))
            addedAction = true
        elseif self.kind == "Secondary" then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, item, 50, false, equippedItems.TwoHand or false))
            addedAction = true
        elseif self.kind == "Primary" then
            ISTimedActionQueue.add(ISEquipWeaponAction:new(self.character, item, 50, true, false))
            addedAction = true
        elseif self.kind == "HotbarAttachedItems" then
            local playAnim = md and md.tabas_PlayHotbarReattachAnim and TABAS_ReAttachHotbar.canAttach(self.character, currentEntry, item) or false
            ISTimedActionQueue.add(TABAS_ReAttachHotbar:new(self.character, currentEntry, item, playAnim))
            if playAnim then
                md.tabas_PlayHotbarReattachAnim = nil
            end
            addedAction = true
        end
        ISInventoryPage.renderDirty = true
    end
    self:endAddingActions()

    if addedAction then
        self:forceComplete()
    else
        self:forceStop()
    end
end

function TABAS_ReEquipItems:update()
    self:forceStop()
end

function TABAS_ReEquipItems:perform()
    ISBaseTimedAction.perform(self)
end

function TABAS_ReEquipItems:complete()
    return true
end

function TABAS_ReEquipItems:new(character, kind, entry, item)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.kind = kind
    o.entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(entry)
    o.item = item
    o.maxTime = 0
    return o
end

return TABAS_ReEquipItems
