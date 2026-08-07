local TABAS_OutfitManagement = {}

local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_BodyLocations = require("NPCs/TABAS_BodyLocations")

--[[ 
tabas_OutfitData = { 
    squareData = {x,y,z},
    type = "floor",
    date = worldAgeHours,
    name = "",
    owner = "",

    clothes = [locationType] = {itemId, fullType, displayName, isFavorite, location, locationIndex, isBag},
    handItems = [primary | secondary] = {itemId, fullType, displayName, isFavorite},
    attachedItems = [attachmentKey] = {itemId, fullType, displayName, isFavorite, slotType, slotIndex},
}
]]

function TABAS_OutfitManagement.getOutfitData(playerObj)
    local md = playerObj:getModData()
    if not md then return end
    return md.tabas_OutfitData
end

function TABAS_OutfitManagement.setOutfitData(playerObj, data)
    local md = playerObj:getModData()
    if not md then return end
    md.tabas_OutfitData = data
    playerObj:transmitModData()
end

function TABAS_OutfitManagement.discardOutfitData(playerObj)
    local md = playerObj:getModData()
    if not md or not md.tabas_OutfitData then return end
    md.tabas_OutfitData = nil
    playerObj:transmitModData()
end

function TABAS_OutfitManagement.getSquareFromData(squareData)
    if not squareData then return end

    local x = squareData.x
    local y = squareData.y
    local z = squareData.z
    if x and y and z then
        return getCell():getGridSquare(x, y, z)
    end
    return nil
end

local function createStoredData(item, extraKeys)
    local list = {
        itemId = item:getID(),
        fullType = item:getFullType(),
        displayName = item:getDisplayName(),
        isFavorite = item:isFavorite()
    }
    if extraKeys then
        for k, v in pairs(extraKeys) do
            list[k] = v
        end
    end
    return list
end

function TABAS_OutfitManagement.saveOutfitData(playerObj, square, object)
    if not square then return end
    local data = {}
    data.name = "temporary data"
    data.type = "floor"
    data.squareData = {x = square:getX(), y = square:getY(), z = square:getZ()}
    data.date = TABAS_GameTimes.getWorldAgeHours()
    data.owner = playerObj:getUsername()
    data.clothes = {}
    data.attachedItems = {}
    data.handItems = {}
    data.hotbarOrder = playerObj:getModData().hotbar

    local wornItems = TABAS_OutfitManagement.getCurrentWornItems(playerObj)
    if wornItems then
        for i=1, #wornItems do
            local item = wornItems[i]
            local location = item:getBodyLocation() or item:canBeEquipped()
            if location then
                table.insert(data.clothes, createStoredData(item, {
                    location = location,
                    index = i,
                    isBag = (item:getContainer() ~= nil) and item:canBeEquipped(),
                }))
            end
        end
    end

    local attachedItems = TABAS_OutfitManagement.getCurrentAttachment(playerObj)
    if attachedItems then
        for i=1, #attachedItems do
            local attached = attachedItems[i]
            table.insert(data.attachedItems, createStoredData(attached.item, {
                slotType = attached.slotType,
                slotIndex = attached.slotIndex
            }))
        end
    end

    local primary = playerObj:getPrimaryHandItem()
    local secondary = playerObj:getSecondaryHandItem()
    local isBothHands = primary and playerObj:isItemInBothHands(primary)
    if isBothHands then
        if not playerObj:isAttachedItem(primary) then
            table.insert(data.handItems, createStoredData(primary, {
                kind = "primary",
                isBothHands = true
            }))
        end
    else
        if primary and not playerObj:isAttachedItem(primary) then
            table.insert(data.handItems, createStoredData(primary, { kind = "primary" }))
        end
        if secondary and not playerObj:isAttachedItem(secondary) then
            table.insert(data.handItems, createStoredData(secondary, { kind = "secondary" }))
        end
    end

    TABAS_OutfitManagement.setOutfitData(playerObj, data)

    return data
end

function TABAS_OutfitManagement.shouldExcludedClothing(item)
    if not item or item:isHidden() then return true end
    -- isHidden included "BANDAGE | MAKE_UP | WOUND | ZED_DMG" | any Skins

    if item:IsClothing() or item:IsInventoryContainer() then
        local bodyLocation = item:getBodyLocation() or item:canBeEquipped()
        if not bodyLocation then
            return true -- likey keyring, wallet, and flightcase
        end

        local exclude = TABAS_BodyLocations.Exclude.BodyLocations
        for i=1, #exclude do
            if bodyLocation == exclude[i] then
                return true
            end
        end
        return false
    end
    return true
end

function TABAS_OutfitManagement.getCurrentWornItems(playerObj)
    local wornItems = playerObj:getWornItems()
    local list = {}
    for i = 0, wornItems:size() - 1 do
        local wornItem = wornItems:get(i):getItem()
        if wornItem and not TABAS_OutfitManagement.shouldExcludedClothing(wornItem) then
            table.insert(list, wornItem)
        end
    end
    return #list > 0 and list or nil
end

function TABAS_OutfitManagement.getCurrentAttachment(playerObj)
    local hotbar = getPlayerHotbar(playerObj:getPlayerNum())
    if not hotbar then return nil end

    local list = {}
    for i, item in pairs(hotbar.attachedItems) do
        local slot = hotbar.availableSlot[i]
        local slotDef = slot and slot.def
        if item and slotDef and slotDef.type then
            table.insert(list, {
                item = item,
                slotType = slotDef.type,
                slotIndex = i
            })
        end
    end
    return #list > 0 and list or nil
end

function TABAS_OutfitManagement.getAttachmentKey(slotType, slotIndex)
    if not slotType or not slotIndex then return nil end
    return string.format("%s#%s", slotType, slotIndex)
end

function TABAS_OutfitManagement.onUnEquipActionQueue(playerObj, square, object)
    if square and luautils.walk(playerObj, square, true) then
        TABAS_OutfitManagement.saveOutfitData(playerObj, square, object)
        ISTimedActionQueue.add(TABAS_UnEquipAllQueueAction:new(playerObj, square))
    end
end

function TABAS_OutfitManagement.hasAllOutfitItemsInInventory(playerObj, outfitData)
    if not playerObj or not outfitData then return false end

    local playerInv = playerObj:getInventory()
    if not playerInv then return false end

    local lists = { outfitData.clothes, outfitData.attachedItems, outfitData.handItems }
    for _, itemList in ipairs(lists) do
        if itemList then
            for _, itemData in ipairs(itemList) do
                local itemId = itemData and itemData.itemId
                if itemId and not playerInv:getItemById(itemId) then
                    return false
                end
            end
        end
    end

    return true
end

function TABAS_OutfitManagement.onReEquipActionQueue(playerObj, checkInventory)
    local data = TABAS_OutfitManagement.getOutfitData(playerObj)
    if not data then return end

    local queueAction = TABAS_ReEquipQueueAction:new(playerObj, data)
    if checkInventory and TABAS_OutfitManagement.hasAllOutfitItemsInInventory(playerObj, data) then
        queueAction.skipSquareCheck = true
        ISTimedActionQueue.add(queueAction)
        return
    end

    local square = TABAS_OutfitManagement.getSquareFromData(data.squareData)
    if square and luautils.walk(playerObj, square, true) then
        ISTimedActionQueue.add(queueAction)
    end
end

function TABAS_OutfitManagement.transferIfNeeded(playerObj, item, grabTime)
    if item and instanceof(item, "InventoryItem") and luautils.haveToBeTransfered(playerObj, item, true) then
        local playerInv = playerObj:getInventory()
        local src = item:getContainer()
        ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, src, playerInv, grabTime or 50))
        return true
    end
    return false
end

function TABAS_OutfitManagement.getWorldItemsOnSquareData(squareData)
    if not squareData then return {} end

    local worldItems = {}
    local z = squareData.z
    for x = -1, 1 do
        for y = -1, 1 do
            local sq = getCell():getGridSquare(squareData.x + x, squareData.y + y, z)
            if sq then
                local objs = sq:getWorldObjects()
                for i = 0, objs:size()-1 do
                    local obj = objs:get(i)
                    local item = obj and obj:getItem()
                    if item and instanceof(item, "InventoryItem") then
                        table.insert(worldItems, obj)
                    end
                end
            end
        end
    end

    return worldItems
end

function TABAS_OutfitManagement.getItemByIdFromWorldItems(itemId, worldItems)
    if not worldItems then return nil end

    for _, worldItem in pairs(worldItems) do
        local item = worldItem:getItem()
        if item and item:getID() == itemId then
            return worldItem
        end
    end
    return nil
end


return TABAS_OutfitManagement
