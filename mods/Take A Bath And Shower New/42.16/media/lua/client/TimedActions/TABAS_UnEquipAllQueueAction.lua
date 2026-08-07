require "TimedActions/ISBaseTimedAction"
require("TimedActions/TABAS_DetachHotbarItem")

TABAS_UnEquipAllQueueAction = ISBaseTimedAction:derive("TABAS_UnEquipAllQueueAction")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_OutfitManagement = require("TABAS_OutfitManagement")

local UNWERE_TIME = {25, 75, 50}
local UNWERE_TIME2 = {25, 1, 50}

function TABAS_UnEquipAllQueueAction:isValid()
    return self.square ~= nil
end

local function dropItemQueue(item, playerObj, floorContainer, unequipTime)
    if not item then return end

    if item:isFavorite() then
        item:setFavorite(false)
    end
    if isClient() then
        unequipTime = 50
    end
    if playerObj:isAttachedItem(item) then
        -- playerObj:removeAttachedItem(item)
        ISTimedActionQueue.add(TABAS_DetachHotbarItem:new(playerObj, item))
    end
    if not item:isForceDropHeavyItem() then
        if playerObj:isEquippedClothing(item) then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, item, unequipTime or 1))
        end
    end
    if floorContainer then
        ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, item:getContainer(), floorContainer))
    end
end

function TABAS_UnEquipAllQueueAction:start()
    local playerObj = self.character
    local floorContainer = ISInventoryPage.GetFloorContainer(self.playerNum)

    local unwearTime = UNWERE_TIME[self.modifyTime]
    local unwearTime2 = UNWERE_TIME2[self.modifyTime]

    self:beginAddingActions()

    local attachedItems = TABAS_OutfitManagement.getCurrentAttachment(playerObj)
    local handAttachedItems = {}
    if attachedItems then
        for i = 1, #attachedItems do
            local attached = attachedItems[i]
            local item = attached and attached.item
            if item and playerObj:isAttachedItem(item) then
                if playerObj:isHandItem(item) then
                    handAttachedItems[item:getID()] = true
                end
                dropItemQueue(item, playerObj, floorContainer)
            end
        end
    end

    local secondary = playerObj:getSecondaryHandItem()
    local primary = playerObj:getPrimaryHandItem()
    local isSameItemInBothHands = primary and secondary and primary == secondary
        and (playerObj:isItemInBothHands(primary) or playerObj:isItemInBothHands(secondary))

    if secondary and not handAttachedItems[secondary:getID()] then
        dropItemQueue(secondary, playerObj, floorContainer)
    end

    if primary and not isSameItemInBothHands and not handAttachedItems[primary:getID()] then
        dropItemQueue(primary, playerObj, floorContainer)
    end

    local wornItems = TABAS_OutfitManagement.getCurrentWornItems(playerObj)
    if wornItems then
        for i = #wornItems, 1, -1 do
            local item = wornItems[i]
            if item and playerObj:isEquipped(item) and TABAS_Utils.canAutoUnequipClothing(item, false) then
                dropItemQueue(item, playerObj, floorContainer, unwearTime)
                if unwearTime == UNWERE_TIME[self.modifyTime] then
                    unwearTime = unwearTime2
                end
            end
        end
    end

    self:endAddingActions()

    self:forceComplete()
end

function TABAS_UnEquipAllQueueAction:perform()
    ISBaseTimedAction.perform(self)
end

function TABAS_UnEquipAllQueueAction:new(character, square)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.square = square
    o.modifyTime = TABAS_Utils.ModOptionsValue("WearingActionTime")
    o.maxTime = 0
    return o
end
