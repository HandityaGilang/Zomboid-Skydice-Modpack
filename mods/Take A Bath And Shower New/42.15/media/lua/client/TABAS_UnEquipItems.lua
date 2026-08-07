local TABAS_UnEquipItems = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_ReEquipItemsUtils = require("TABAS_ReEquipItemsUtils")
require("TimedActions/TABAS_DetachHotbarItem")

local function shouldBeDrop(playerObj, item, isAttached, isBack)
    if not item then return false end

    local doDropAll = TABAS_Utils.ModOptionsValue("DropEquippedItemsAll")
    local doDropBack = TABAS_Utils.ModOptionsValue("DropEquippedItemsBack")
    local doDropContainer = TABAS_Utils.ModOptionsValue("DropEquippedItemsContainer")
    local doDropAttached = TABAS_Utils.ModOptionsValue("DropEquippedItemsAttached")
    local doDropHand = TABAS_Utils.ModOptionsValue("DropEquippedItemsHand")
    local doDropClothing = TABAS_Utils.ModOptionsValue("DropEquippedItemsClothing")
    local weightLimit = TABAS_Utils.ModOptionsValue("DropEquippedItemsWeight")

    if item:isFavorite() then return false end
    if doDropAll then return true end

    if isAttached then
        if doDropAttached or (doDropBack and isBack) then
            return true
        end
    elseif doDropBack and (item:canBeEquipped() == "Back" or item:getAttachmentReplacement() == "Bag") then
        return true
    elseif doDropContainer and item:IsInventoryContainer() then
        return true
    elseif doDropHand and playerObj:isHandItem(item) then
        return true
    elseif doDropClothing and item:IsClothing() then
        return true
    end
    return weightLimit > 0 and item:getActualWeight() >= weightLimit
end

local function collectHotbarAttachments(player)
    local hotbar = getPlayerHotbar(player)
    if not hotbar then return nil end

    local list = {}
    for i, item in pairs(hotbar.attachedItems) do
        local slot = hotbar.availableSlot[i]
        local slotDef = slot and slot.def
        if item and slotDef and slotDef.type then
            local isBack = slotDef.name == "Back"
            table.insert(list, {
                item = item,
                itemId = item:getID(),
                slotType = slotDef.type,
                slotIndex = hotbar:getThisSlotIndex(slotDef.type),
                isBack = isBack,
            })
        end
    end
    return #list > 0 and list or nil
end

local function collectWornClothes(playerObj, excludeItemType)
    local wornItems = playerObj:getWornItems()
    if not wornItems then return nil end

    local list = {}
    for i = 0, wornItems:size() - 1 do
        local item = wornItems:get(i):getItem()
        if item and (item:IsClothing() or item:IsInventoryContainer()) and TABAS_Utils.isNotExcludedClothing(item, excludeItemType) then
            table.insert(list, item)
        end
    end
    return #list > 0 and list or nil
end

local function createStoredItemEntry(item)
    if not item then return nil end

    return {
        itemId = item:getID(),
        type = item:getType(),
        fullType = item:getFullType(),
        bodyLocation = item:getBodyLocation(),
        canBeEquipped = item:canBeEquipped(),
        attachmentType = item:getAttachmentType(),
    }
end

local function appendUniqueStoredEntry(list, entry)
    if not (list and entry) then return false end

    for i = 1, #list do
        if TABAS_ReEquipItemsUtils.storedEntryMatches(list[i], entry) then
            return false
        end
    end

    list[#list + 1] = entry
    return true
end

local function storeSingleEntryIfMissing(equippedItems, key, item)
    if equippedItems[key] or not item then
        return
    end
    equippedItems[key] = createStoredItemEntry(item)
end

function TABAS_UnEquipItems.doUnequip(player, keepClothes, excludeItemType, prepSq)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local md = playerObj:getModData()
    local equippedItems = TABAS_ReEquipItemsUtils.pruneStoredEntries(playerObj) or md.tabas_EquippedItems or {}
    local modifyTime = TABAS_Utils.ModOptionsValue("WearingActionTime")
    local unequipTime = 50
    local unwearTime = 25
    local unwearTime2 = 25

    if modifyTime == 2 then
        unwearTime = 75
        unwearTime2 = 1
    elseif modifyTime == 3 then
        unwearTime = 50
        unwearTime2 = 50
    end

    local floorInv = ISInventoryPage.floorContainer[player + 1]
    local playerInv = playerObj:getInventory()

    if not equippedItems.PrepSquare and prepSq then
        equippedItems.PrepSquare = {x = prepSq:getX(), y = prepSq:getY(), z = prepSq:getZ()}
    end

    if not keepClothes then
        local hotbarItems = collectHotbarAttachments(player)
        if hotbarItems then
            equippedItems.HotbarAttachedItems = equippedItems.HotbarAttachedItems or {}
            local hotbar = getPlayerHotbar(player)

            for i = 1, #hotbarItems do
                local entry = hotbarItems[i]
                local item = entry.item

                appendUniqueStoredEntry(equippedItems.HotbarAttachedItems, {
                    itemId = entry.itemId,
                    type = item:getType(),
                    fullType = item:getFullType(),
                    attachmentType = item:getAttachmentType(),
                    slotType = entry.slotType,
                    slotIndex = entry.slotIndex,
                })

                if shouldBeDrop(playerObj, item, true, entry.isBack) and floorInv then
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, item:getContainer(), floorInv))
                else
                    ISTimedActionQueue.add(TABAS_DetachHotbarItem:new(playerObj, item))
                end
            end
        end
    end

    local secondary = playerObj:getSecondaryHandItem()
    local primary = playerObj:getPrimaryHandItem()
    local isTwoHandEquipped = secondary and secondary:isTwoHandWeapon() and playerObj:isItemInBothHands(secondary)

    if secondary then
        if isTwoHandEquipped and equippedItems.TwoHand == nil then
            equippedItems.TwoHand = true
        end
        storeSingleEntryIfMissing(equippedItems, "Secondary", secondary)

        if shouldBeDrop(playerObj, secondary, false, false) then
            ISInventoryPaneContextMenu.dropItem(secondary, player)
        else
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, secondary, unequipTime))
            unequipTime = 30
        end
    end

    if primary and not isTwoHandEquipped then
        storeSingleEntryIfMissing(equippedItems, "Primary", primary)

        if shouldBeDrop(playerObj, primary, false, false) then
            ISInventoryPaneContextMenu.dropItem(primary, player)
        else
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, primary, unequipTime))
        end
    end

    if not keepClothes then
        local wornClothes = collectWornClothes(playerObj, excludeItemType)
        if wornClothes then
            equippedItems.WornClothes = equippedItems.WornClothes or {}

            for i = 1, #wornClothes do
                appendUniqueStoredEntry(equippedItems.WornClothes, createStoredItemEntry(wornClothes[i]))
            end

            for idx = #wornClothes, 1, -1 do
                local wornItem = wornClothes[idx]
                local doDrop = shouldBeDrop(playerObj, wornItem, false, false)

                ISTimedActionQueue.add(ISUnequipAction:new(playerObj, wornItem, unwearTime))
                if doDrop and floorInv then
                    ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, wornItem, playerInv, floorInv, 0))
                end
                unwearTime = unwearTime2
            end
        end
    end

    md.tabas_EquippedItems = equippedItems
    playerObj:transmitModData()
end

return TABAS_UnEquipItems
