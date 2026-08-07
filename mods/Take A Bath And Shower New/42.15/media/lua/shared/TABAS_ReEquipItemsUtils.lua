local TABAS_ReEquipItemsUtils = {}

local TABAS_Utils = require("TABAS_Utils")

local SEARCH_RADIUS = 1

function TABAS_ReEquipItemsUtils.normalizeStoredEntry(entry)
    if not entry then return nil end
    if type(entry) == "number" then
        return { itemId = entry }
    end
    return entry
end

function TABAS_ReEquipItemsUtils.storedEntryMatches(left, right)
    left = TABAS_ReEquipItemsUtils.normalizeStoredEntry(left)
    right = TABAS_ReEquipItemsUtils.normalizeStoredEntry(right)
    if not (left and right) then return false end

    if left.itemId and right.itemId then
        return left.itemId == right.itemId
    end

    if left.bodyLocation and right.bodyLocation then
        if left.bodyLocation ~= right.bodyLocation then
            return false
        end
        return (not left.fullType) or (not right.fullType) or left.fullType == right.fullType
    end

    if left.slotType and right.slotType then
        return left.slotType == right.slotType and left.slotIndex == right.slotIndex
    end

    if left.canBeEquipped and right.canBeEquipped then
        if left.canBeEquipped ~= right.canBeEquipped then
            return false
        end
        return (not left.fullType) or (not right.fullType) or left.fullType == right.fullType
    end

    if left.attachmentType and right.attachmentType then
        if left.attachmentType ~= right.attachmentType then
            return false
        end
        return (not left.fullType) or (not right.fullType) or left.fullType == right.fullType
    end

    return left.fullType and right.fullType and left.fullType == right.fullType
end

function TABAS_ReEquipItemsUtils.hasStoredEntries(equippedItems)
    if not equippedItems then return false end
    if equippedItems.Primary or equippedItems.Secondary then
        return true
    end
    if equippedItems.WornClothes and #equippedItems.WornClothes > 0 then
        return true
    end
    if equippedItems.HotbarAttachedItems and #equippedItems.HotbarAttachedItems > 0 then
        return true
    end
    return false
end

function TABAS_ReEquipItemsUtils.getPrepSquareFromStored(equippedItems)
    local prep = equippedItems and equippedItems.PrepSquare
    if not prep then return nil end
    return getCell():getGridSquare(prep.x, prep.y, prep.z)
end

function TABAS_ReEquipItemsUtils.pruneStoredEntries(character)
    if not character then return nil end

    local md = character:getModData()
    local equippedItems = md and md.tabas_EquippedItems
    if not TABAS_ReEquipItemsUtils.hasStoredEntries(equippedItems) then
        return equippedItems
    end

    local playerInv = character:getInventory()
    local wornItems = character:getWornItems()
    local hotbar = getPlayerHotbar(character:getPlayerNum())
    local modified = false

    local findInventoryItem = function(entry)
        entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(entry)
        if not entry or not entry.itemId then return nil end
        return playerInv:getItemById(entry.itemId)
    end

    local isAlreadyEquipped = function(kind, entry)
        local item = findInventoryItem(entry)
        if not item then return false end

        if kind == "Primary" then
            local primary = character:getPrimaryHandItem()
            return primary and primary:getID() == item:getID()
        end

        if kind == "Secondary" then
            local secondary = character:getSecondaryHandItem()
            return secondary and secondary:getID() == item:getID()
        end

        if kind == "WornClothes" then
            if not wornItems then return false end
            for i = 0, wornItems:size() - 1 do
                local worn = wornItems:get(i):getItem()
                if worn and worn:getID() == item:getID() then
                    return true
                end
            end
            return false
        end

        if kind == "HotbarAttachedItems" then
            return hotbar and hotbar:isItemAttached(item) or false
        end

        return false
    end

    if equippedItems.Primary and isAlreadyEquipped("Primary", equippedItems.Primary) then
        equippedItems.Primary = nil
        modified = true
    end

    if equippedItems.Secondary and isAlreadyEquipped("Secondary", equippedItems.Secondary) then
        equippedItems.Secondary = nil
        equippedItems.TwoHand = nil
        modified = true
    end

    if equippedItems.WornClothes then
        for i = #equippedItems.WornClothes, 1, -1 do
            if isAlreadyEquipped("WornClothes", equippedItems.WornClothes[i]) then
                table.remove(equippedItems.WornClothes, i)
                modified = true
            end
        end
        if #equippedItems.WornClothes == 0 then
            equippedItems.WornClothes = nil
        end
    end

    if equippedItems.HotbarAttachedItems then
        for i = #equippedItems.HotbarAttachedItems, 1, -1 do
            if isAlreadyEquipped("HotbarAttachedItems", equippedItems.HotbarAttachedItems[i]) then
                table.remove(equippedItems.HotbarAttachedItems, i)
                modified = true
            end
        end
        if #equippedItems.HotbarAttachedItems == 0 then
            equippedItems.HotbarAttachedItems = nil
        end
    end

    if modified then
        if not TABAS_ReEquipItemsUtils.hasStoredEntries(equippedItems) then
            md.tabas_EquippedItems = nil
            equippedItems = nil
        end
        character:transmitModData()
    end

    return equippedItems
end

function TABAS_ReEquipItemsUtils.resolveStoredItem(character, equippedItems, entry)
    entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(entry)
    if not (character and entry) then return nil end

    local playerInv = character:getInventory()
    local floorInv = ISInventoryPage.floorContainer[character:getPlayerNum() + 1]
    if entry.itemId then
        local item = playerInv:getItemById(entry.itemId) or (floorInv and floorInv:getItemById(entry.itemId))
        if item then
            return item
        end
    end

    local prepSq = TABAS_ReEquipItemsUtils.getPrepSquareFromStored(equippedItems)
    if not (prepSq and entry.type) then return nil end

    local predicateNearbyItem = function(item)
        if not item then return false end
        if entry.itemId and item:getID() == entry.itemId then
            return true
        end
        if entry.fullType and item:getFullType() ~= entry.fullType then
            return false
        end
        if entry.bodyLocation and item:getBodyLocation() ~= entry.bodyLocation then
            return false
        end
        if entry.canBeEquipped and item:canBeEquipped() ~= entry.canBeEquipped then
            return false
        end
        if entry.attachmentType and item:getAttachmentType() ~= entry.attachmentType then
            return false
        end
        return entry.fullType ~= nil or entry.type ~= nil
    end

    local items = TABAS_Utils.getNearbyItems(character, prepSq, SEARCH_RADIUS, entry.type, nil, predicateNearbyItem)
    if not items or items:isEmpty() then return nil end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if entry.itemId and item and item:getID() == entry.itemId then
            return item
        end
    end

    return items:get(0)
end

function TABAS_ReEquipItemsUtils.getCurrentStoredEntry(equippedItems, kind, targetEntry)
    if not equippedItems then return nil end

    if kind == "Primary" then
        return TABAS_ReEquipItemsUtils.normalizeStoredEntry(equippedItems.Primary)
    end
    if kind == "Secondary" then
        return TABAS_ReEquipItemsUtils.normalizeStoredEntry(equippedItems.Secondary)
    end

    local list = equippedItems[kind]
    if not list then return nil end

    for i = 1, #list do
        local entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(list[i])
        if TABAS_ReEquipItemsUtils.storedEntryMatches(entry, targetEntry) then
            return entry
        end
    end
    return nil
end

function TABAS_ReEquipItemsUtils.removeStoredEntry(equippedItems, kind, currentEntry)
    if not (equippedItems and kind and currentEntry) then return end

    if kind == "Primary" then
        equippedItems.Primary = nil
        return
    end
    if kind == "Secondary" then
        equippedItems.Secondary = nil
        equippedItems.TwoHand = nil
        return
    end

    local list = equippedItems[kind]
    if not list then return end

    for i = #list, 1, -1 do
        if TABAS_ReEquipItemsUtils.storedEntryMatches(list[i], currentEntry) then
            table.remove(list, i)
            break
        end
    end
    if #list == 0 then
        equippedItems[kind] = nil
    end
end

function TABAS_ReEquipItemsUtils.hasStoredItems(character)
    if not character then return false end
    return TABAS_ReEquipItemsUtils.hasStoredEntries(TABAS_ReEquipItemsUtils.pruneStoredEntries(character))
end

function TABAS_ReEquipItemsUtils.canRun(character, maxPrepDistance)
    if not character then return false end

    local equippedItems = TABAS_ReEquipItemsUtils.pruneStoredEntries(character)
    if not TABAS_ReEquipItemsUtils.hasStoredEntries(equippedItems) then
        return false
    end

    local playerInv = character:getInventory()
    local hasInventoryItem = false
    local hasNonInventoryItem = false

    local inspectEntry = function(entry)
        entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(entry)
        if not entry then return end
        if entry.itemId and playerInv:getItemById(entry.itemId) then
            hasInventoryItem = true
        else
            hasNonInventoryItem = true
        end
    end

    inspectEntry(equippedItems.Primary)
    inspectEntry(equippedItems.Secondary)

    if equippedItems.WornClothes then
        for i = 1, #equippedItems.WornClothes do
            inspectEntry(equippedItems.WornClothes[i])
        end
    end

    if equippedItems.HotbarAttachedItems then
        for i = 1, #equippedItems.HotbarAttachedItems do
            inspectEntry(equippedItems.HotbarAttachedItems[i])
        end
    end

    if hasInventoryItem then
        return true
    end
    if not hasNonInventoryItem then
        return false
    end

    local prepSq = TABAS_ReEquipItemsUtils.getPrepSquareFromStored(equippedItems)
    local curSq = character:getCurrentSquare()
    if not (prepSq and curSq) or curSq:getZ() ~= prepSq:getZ() then
        return false
    end

    local dx = math.abs(curSq:getX() - prepSq:getX())
    local dy = math.abs(curSq:getY() - prepSq:getY())
    return math.max(dx, dy) <= (maxPrepDistance or 8)
end

function TABAS_ReEquipItemsUtils.getPrepSquare(character)
    if not character then return nil end
    return TABAS_ReEquipItemsUtils.getPrepSquareFromStored(TABAS_ReEquipItemsUtils.pruneStoredEntries(character))
end

function TABAS_ReEquipItemsUtils.needsPrepWalk(character)
    if not character then return false end

    local equippedItems = TABAS_ReEquipItemsUtils.pruneStoredEntries(character)
    if not equippedItems or not TABAS_ReEquipItemsUtils.hasStoredEntries(equippedItems) then return false end

    local playerInv = character:getInventory()
    local hasNonInventoryItem = false

    local inspectEntry = function(entry)
        entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(entry)
        if not entry then return end
        if not (entry.itemId and playerInv:getItemById(entry.itemId)) then
            hasNonInventoryItem = true
        end
    end

    inspectEntry(equippedItems.Primary)
    inspectEntry(equippedItems.Secondary)

    if equippedItems.WornClothes then
        for i = 1, #equippedItems.WornClothes do
            inspectEntry(equippedItems.WornClothes[i])
            if hasNonInventoryItem then return true end
        end
    end

    if equippedItems.HotbarAttachedItems then
        for i = 1, #equippedItems.HotbarAttachedItems do
            inspectEntry(equippedItems.HotbarAttachedItems[i])
            if hasNonInventoryItem then return true end
        end
    end

    return hasNonInventoryItem
end

function TABAS_ReEquipItemsUtils.shouldReturnToPrepSquare(character)
    if not character then return false end

    local prepSq = TABAS_ReEquipItemsUtils.getPrepSquare(character)
    local curSq = character:getCurrentSquare()
    if not (prepSq and curSq) or curSq:getZ() ~= prepSq:getZ() then
        return false
    end

    local dx = math.abs(curSq:getX() - prepSq:getX())
    local dy = math.abs(curSq:getY() - prepSq:getY())
    return (dx > 0 or dy > 0) and math.max(dx, dy) <= 1
end

function TABAS_ReEquipItemsUtils.queueAll(character)
    if not character then return false end

    local equippedItems = TABAS_ReEquipItemsUtils.pruneStoredEntries(character)
    local md = character:getModData()
    if not TABAS_ReEquipItemsUtils.hasStoredEntries(equippedItems) then
        if md then
            md.tabas_PlayHotbarReattachAnim = nil
        end
        return false
    end

    md.tabas_PlayHotbarReattachAnim = equippedItems.HotbarAttachedItems and #equippedItems.HotbarAttachedItems > 0 or nil

    local queuedEntries = {}
    if equippedItems.WornClothes then
        for i = 1, #equippedItems.WornClothes do
            queuedEntries[#queuedEntries + 1] = {
                kind = "WornClothes",
                entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(equippedItems.WornClothes[i]),
            }
        end
    end
    if equippedItems.Secondary then
        queuedEntries[#queuedEntries + 1] = {
            kind = "Secondary",
            entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(equippedItems.Secondary),
        }
    end
    if equippedItems.Primary then
        queuedEntries[#queuedEntries + 1] = {
            kind = "Primary",
            entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(equippedItems.Primary),
        }
    end
    if equippedItems.HotbarAttachedItems then
        for i = 1, #equippedItems.HotbarAttachedItems do
            queuedEntries[#queuedEntries + 1] = {
                kind = "HotbarAttachedItems",
                entry = TABAS_ReEquipItemsUtils.normalizeStoredEntry(equippedItems.HotbarAttachedItems[i]),
            }
        end
    end

    local playerInv = character:getInventory()
    local grabTime = 50
    for i = 1, #queuedEntries do
        local queuedEntry = queuedEntries[i]
        queuedEntry.item = TABAS_ReEquipItemsUtils.resolveStoredItem(character, equippedItems, queuedEntry.entry)

        if queuedEntry.item and instanceof(queuedEntry.item, "InventoryItem") and luautils.haveToBeTransfered(character, queuedEntry.item, true) then
            local src = queuedEntry.item:getContainer() or playerInv
            ISTimedActionQueue.add(ISInventoryTransferAction:new(character, queuedEntry.item, src, playerInv, grabTime))
            grabTime = 0
        end
    end

    local queued = false
    for i = 1, #queuedEntries do
        ISTimedActionQueue.add(TABAS_ReEquipItems:new(character, queuedEntries[i].kind, queuedEntries[i].entry, queuedEntries[i].item))
        queued = true
    end

    return queued
end

return TABAS_ReEquipItemsUtils
