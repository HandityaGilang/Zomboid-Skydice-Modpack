require "TimedActions/ISBaseTimedAction"

local TABAS_OutfitManagement = require("TABAS_OutfitManagement")
local OutfitDataKeys = {"wearItems", "bagItems", "attachedItems", "handItems"}

----------------------------------------------------------------

TABAS_ReEquipComplete = ISBaseTimedAction:derive("TABAS_ReEquipComplete")

function TABAS_ReEquipComplete:isValid()
    return self.resolvedData ~= nil
end

function TABAS_ReEquipComplete:start()
end

function TABAS_ReEquipComplete:perform()
    local playerObj = self.character
    for i=1, #self.resolvedData do
        local data = self.resolvedData[i]
        local kind = OutfitDataKeys[i]
        for _, itemData in pairs(data) do
            if not itemData.item then
                self.keepData = true
                break
            end
            if (kind == "wearItems" or kind == "bagItems") then
                if not playerObj:isEquippedClothing(itemData.item) then
                    self.keepData = true
                    break
                end
            elseif kind == "attachedItems" then
                if not playerObj:isAttachedItem(itemData.item) then
                    self.keepData = true
                    break
                end
            elseif kind == "handItems" then
                if not playerObj:isEquipped(itemData.item) then
                    self.keepData = true
                    break
                end
            end
        end
    end
    if not self.keepData then
        TABAS_OutfitManagement.discardOutfitData(self.character)
    end
    ISBaseTimedAction.perform(self)
end

function TABAS_ReEquipComplete:new(character, resolvedData)
    local o = ISBaseTimedAction.new(self, character)
    o.resolvedData = resolvedData
    o.keepData = false
    o.maxTime = 0
    return o
end

----------------------------------------------------------------

TABAS_ReOrderHotbar = ISBaseTimedAction:derive("TABAS_ReOrderHotbar")

function TABAS_ReOrderHotbar:isValid()
    return self.outfitData ~= nil
end

function TABAS_ReOrderHotbar:compatibilityReorderTheHotbar(md, hotbar, newOrder)
    local order = {}
    local used = {}
    for i = 1, #newOrder do
        local slotType = newOrder[i]
        if slotType and hotbar:getThisSlotIndex(slotType) and not used[slotType] then
            order[#order + 1] = slotType
            used[slotType] = true
        end
    end
    for i = 1, #hotbar.availableSlot do
        local slot = hotbar.availableSlot[i]
        local slotType = slot and slot.slotType
        if slotType and not used[slotType] then
            order[#order + 1] = slotType
            used[slotType] = true
        end
    end
    for i = 1, #order do
        md[order[i] .. "RTH_index"] = i
    end
    hotbar.wornItems = nil
    hotbar:refresh()
end

function TABAS_ReOrderHotbar:perform()
    local newOrder = self.outfitData.hotbarOrder
    if newOrder then
        local playerObj = self.character
        local hotbar = getPlayerHotbar(playerObj:getPlayerNum())
        local md = playerObj:getModData()
        if hotbar and md then
            hotbar:reloadIcons()
            for _, item in pairs(hotbar.attachedItems) do
                if item then
                    ISBaseTimedAction.perform(self)
                    return
                end
            end

            md.hotbar = {}
            for i = 1, #newOrder do
                md.hotbar[i] = newOrder[i]
            end

            hotbar.availableSlot = {}
            hotbar:loadPosition()
            hotbar.wornItems = nil
            hotbar:refresh()

            if md["BackRTH_index"] ~= nil then
                self:compatibilityReorderTheHotbar(md, hotbar, newOrder)
            end

            playerObj:transmitModData()
        end
    end

    ISBaseTimedAction.perform(self)
end

function TABAS_ReOrderHotbar:new(character, outfitData)
    local o = ISBaseTimedAction.new(self, character)
    o.outfitData = outfitData
    o.maxTime = 0
    return o
end

----------------------------------------------------------------

TABAS_ReEquipQueueAction = ISBaseTimedAction:derive("TABAS_ReEquipQueueAction")


local function isWearItem(itemData)
    return not itemData.isBag
end

local function isBagItem(itemData)
    return itemData.isBag
end

function TABAS_ReEquipQueueAction:isValid()
    return self.outfitData ~= nil
end

function TABAS_ReEquipQueueAction:waitToStart()
    if self.skipSquareCheck then
        return false
    end
    return self.square ~= self.character:getCurrentSquare()
end

function TABAS_ReEquipQueueAction:resolveItems(dataTable, playerInv, worldItems, filter)
    if not dataTable then return {} end

    local resolvedItems = {}
    for _, itemData in ipairs(dataTable) do
        if not filter or filter(itemData) then
            local itemId = itemData.itemId
            if itemId then
                local resolved = {}
                for k, v in pairs(itemData) do
                    resolved[k] = v
                end

                local item = playerInv:getItemById(itemId)
                if item then
                    resolved.item = item
                else
                    local worldItem = TABAS_OutfitManagement.getItemByIdFromWorldItems(itemId, worldItems)
                    if worldItem then
                        resolved.worldItem = worldItem
                        resolved.item = worldItem:getItem()
                    end
                end
                table.insert(resolvedItems, resolved)
            end
        end
    end
    return resolvedItems
end

function TABAS_ReEquipQueueAction:start()
    local data = self.outfitData
    local playerObj = self.character

    self:beginAddingActions()

    local worldItems = TABAS_OutfitManagement.getWorldItemsOnSquareData(data.squareData)
    local playerInv = playerObj:getInventory()

    local wearItems = self:resolveItems(data.clothes, playerInv, worldItems, isWearItem)
    local bagItems = self:resolveItems(data.clothes, playerInv, worldItems, isBagItem)
    local attachedItems = self:resolveItems(data.attachedItems, playerInv, worldItems)
    local handItems = self:resolveItems(data.handItems, playerInv, worldItems)

    local function addPickupItemsQueue(itemsData)
        local grabTime = 50
        local isClient = isClient()
        for _, itemData in ipairs(itemsData) do
            local item = itemData.item
            if item then
                if itemData.worldItem then
                    if isClient then
                        local worldItem = itemData.worldItem:getItem()
                        ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(playerObj, worldItem, worldItem:getContainer(), playerObj:getInventory()))
                    else
                        ISTimedActionQueue.add(ISGrabItemAction:new(playerObj, itemData.worldItem, grabTime))
                        grabTime = 0
                    end
                else
                    TABAS_OutfitManagement.transferIfNeeded(playerObj, itemData.item, 25)
                end
            end
        end
    end

    if wearItems then
        table.sort(wearItems, function(a, b) return a.index < b.index end)
        addPickupItemsQueue(wearItems)
        for _, itemData in ipairs(wearItems) do
            local item = itemData.item
            if item and not playerObj:isEquippedClothing(item) then
                ISTimedActionQueue.add(TABAS_ReEquipItems:new(playerObj, "clothes", item, itemData))
            end
        end
    end

    if bagItems then
        addPickupItemsQueue(bagItems)
        for _, itemData in ipairs(bagItems) do
            local item = itemData.item
            if item and not playerObj:isEquippedClothing(item) then
                ISTimedActionQueue.add(TABAS_ReEquipItems:new(playerObj, "clothes", item, itemData))
            end
        end
    end

    ISTimedActionQueue.add(TABAS_ReOrderHotbar:new(playerObj, data))

    if attachedItems then
        addPickupItemsQueue(attachedItems)
        local doAttachAnim = true
        for _, itemData in ipairs(attachedItems) do
            local item = itemData.item
            if item and not playerObj:isAttachedItem(item) then
                ISTimedActionQueue.add(TABAS_ReEquipItems:new(playerObj, "attachedItems", item, itemData, doAttachAnim))
                if doAttachAnim then
                    doAttachAnim = false
                end
            end
        end
    end

    if handItems then
        addPickupItemsQueue(handItems)
        for _, itemData in ipairs(handItems) do
            local item = itemData.item
            local kind = itemData.kind
            if item and not playerObj:isEquipped(item) then
                ISTimedActionQueue.add(TABAS_ReEquipItems:new(playerObj, kind, item, itemData))
                if itemData.isBothHands then
                    break
                end
            end
        end
    end

    ISTimedActionQueue.add(TABAS_ReEquipComplete:new(playerObj, { wearItems, bagItems, attachedItems, handItems }))

    self:endAddingActions()

    self:forceComplete()
end

function TABAS_ReEquipQueueAction:perform()
    ISBaseTimedAction.perform(self)
end

function TABAS_ReEquipQueueAction:new(character, outfitData)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.outfitData = outfitData
    o.square = outfitData and TABAS_OutfitManagement.getSquareFromData(outfitData.squareData) or nil
    o.maxTime = 0
    return o
end
