-- Shared inventory and world-item helper utilities.
NMInventoryHelpers = NMInventoryHelpers or {}

function NMInventoryHelpers.collectItemsRecursive(container, out)
    if not container or not container.getItems then return end
    local items = container:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        out[#out + 1] = item
        if item and item.IsInventoryContainer and item:IsInventoryContainer() then
            local sub = item:getInventory()
            if sub then
                NMInventoryHelpers.collectItemsRecursive(sub, out)
            end
        end
    end
end

function NMInventoryHelpers.findItemById(container, itemId)
    if not container or not itemId then return nil end
    local items = container:getItems()
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getID and tostring(item:getID()) == tostring(itemId) then
            return item
        end
        if item and item.IsInventoryContainer and item:IsInventoryContainer() then
            local found = NMInventoryHelpers.findItemById(item:getInventory(), itemId)
            if found then return found end
        end
    end
    return nil
end

function NMInventoryHelpers.findDirectItemById(container, itemId)
    if not container or not itemId then return nil end
    local items = container.getItems and container:getItems() or nil
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getID and tostring(item:getID()) == tostring(itemId) then
            return item
        end
    end
    return nil
end

function NMInventoryHelpers.getProfileRuntimeNumber(key, defaultValue)
    local getter = NMDeviceProfiles and NMDeviceProfiles[key] or nil
    if type(getter) ~= "function" then return defaultValue end
    local ok, value = pcall(getter)
    if not ok then return defaultValue end
    local num = tonumber(value)
    if num == nil then return defaultValue end
    return num
end

function NMInventoryHelpers.getItemIdString(item)
    if not item or not item.getID then return "" end
    return tostring(item:getID() or "")
end

function NMInventoryHelpers.getItemUuidString(item)
    if not item then return "" end
    if NMDeviceRegistry and NMDeviceRegistry.get then
        local ok, uuid = pcall(NMDeviceRegistry.get, item)
        if ok and uuid ~= nil and tostring(uuid) ~= "" then
            return tostring(uuid)
        end
    end
    return ""
end

function NMInventoryHelpers.getItemStateUuid(item)
    if not (item and item.getModData and NMCore and NMCore.StateKey) then
        return ""
    end
    local md = item:getModData()
    local state = md and md[NMCore.StateKey] or nil
    local uuid = state and state.deviceUUID or nil
    if uuid ~= nil and tostring(uuid) ~= "" then
        return tostring(uuid)
    end
    return NMInventoryHelpers.getItemUuidString(item)
end

function NMInventoryHelpers.squareHasGridOrGeneratorPower(square)
    if not square then return false end
    if square.haveElectricity and square:haveElectricity() then return true end
    if square.hasGridPower and square:hasGridPower() and square.getRoom and square:getRoom() then
        return true
    end
    return false
end

function NMInventoryHelpers.resolveExternalPowerAvailable(player, item, profile)
    if not NMDeviceProfiles.requiresExternalPower(profile) then
        return true
    end
    local worldItem = item and item.getWorldItem and item:getWorldItem() or nil
    local square = worldItem and worldItem.getSquare and worldItem:getSquare() or nil
    if not square then return false end
    return NMInventoryHelpers.squareHasGridOrGeneratorPower(square)
end

function NMInventoryHelpers.findWorldItemByIdNearPlayer(player, itemId, radius, floors)
    if not player or not itemId then return nil end
    local sq = player.getSquare and player:getSquare() or nil
    if not sq then return nil end
    local cell = getCell and getCell() or nil
    if not cell then return nil end

    local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
    local r = radius or 4
    local f = math.max(0, math.floor(tonumber(floors) or 0))
    local minZ = pz - f
    local maxZ = pz + f
    if getMaximumWorldLevel then
        local worldMax = tonumber(getMaximumWorldLevel()) or maxZ
        if minZ < 0 then minZ = 0 end
        if maxZ > worldMax then maxZ = worldMax end
    end

    for x = px - r, px + r do
        for y = py - r, py + r do
            for z = minZ, maxZ do
                local grid = cell:getGridSquare(x, y, z)
                if grid and grid.getWorldObjects then
                    local objs = grid:getWorldObjects()
                    if objs then
                        for i = 0, objs:size() - 1 do
                            local obj = objs:get(i)
                            local item = obj and obj.getItem and obj:getItem() or nil
                            if item and item.getID and tostring(item:getID()) == tostring(itemId) then
                                return item
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

function NMInventoryHelpers.findItemByUuid(container, uuid)
    local target = tostring(uuid or "")
    if not container or target == "" then return nil end
    local items = container:getItems()
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local itemUuid = NMInventoryHelpers.getItemStateUuid(item)
            if itemUuid ~= "" and itemUuid == target then
                return item
            end
        end
        if item and item.IsInventoryContainer and item:IsInventoryContainer() then
            local found = NMInventoryHelpers.findItemByUuid(item:getInventory(), target)
            if found then return found end
        end
    end
    return nil
end

function NMInventoryHelpers.findDirectItemByUuid(container, uuid)
    local target = tostring(uuid or "")
    if not container or target == "" then return nil end
    local items = container.getItems and container:getItems() or nil
    if not items then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local itemUuid = NMInventoryHelpers.getItemStateUuid(item)
            if itemUuid ~= "" and itemUuid == target then
                return item
            end
        end
    end
    return nil
end

function NMInventoryHelpers.resolveItemByIdOrUuid(container, itemId, uuid)
    local targetUuid = tostring(uuid or "")
    local targetId = tostring(itemId or "")
    if targetUuid ~= "" then
        local byUuid = NMInventoryHelpers.findItemByUuid(container, targetUuid)
        if byUuid then
            return byUuid
        end
    end
    if targetId ~= "" then
        return NMInventoryHelpers.findItemById(container, targetId)
    end
    return nil
end

function NMInventoryHelpers.isItemInRootInventory(inventory, item)
    if not (inventory and item) then return false end
    local container = item.getContainer and item:getContainer() or nil
    return container == inventory
end

function NMInventoryHelpers.refreshInventoryPagesForPlayer(player)
    local playerNum = player and player.getPlayerNum and tonumber(player:getPlayerNum()) or nil
    if playerNum == nil then
        return
    end
    if getPlayerInventory then
        local invPage = getPlayerInventory(playerNum)
        if invPage and invPage.refreshBackpacks then
            pcall(invPage.refreshBackpacks, invPage)
        end
    end
    if getPlayerLoot then
        local lootPage = getPlayerLoot(playerNum)
        if lootPage and lootPage.refreshBackpacks then
            pcall(lootPage.refreshBackpacks, lootPage)
        end
    end
    if ISInventoryPage then
        ISInventoryPage.renderDirty = true
    end
end

function NMInventoryHelpers.normalizeItemToMainInventory(player, itemId, uuid)
    local inv = player and player.getInventory and player:getInventory() or nil
    local targetId = tostring(itemId or "")
    local targetUuid = tostring(uuid or "")
    if not inv then
        return nil, "missing_inventory", nil
    end

    local item = NMInventoryHelpers.resolveItemByIdOrUuid(inv, targetId, targetUuid)
    if not item then
        return nil, "source_item_not_found", nil
    end
    if NMInventoryHelpers.isItemInRootInventory(inv, item) then
        return item, nil, {
            moved = false,
            deferred = false,
            inventory = inv,
            sourceContainer = inv,
            targetContainer = inv,
            sourceItem = item,
            targetItem = item,
            itemId = NMInventoryHelpers.getItemIdString(item),
            uuid = NMInventoryHelpers.getItemStateUuid(item)
        }
    end

    local sourceContainer = item.getContainer and item:getContainer() or nil
    if not (sourceContainer and sourceContainer.DoRemoveItem and inv.AddItem) then
        return nil, "source_container_unsupported", nil
    end

    if NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() then
        return item, nil, {
            moved = false,
            deferred = true,
            inventory = inv,
            sourceContainer = sourceContainer,
            targetContainer = inv,
            sourceItem = item,
            targetItem = item,
            itemId = NMInventoryHelpers.getItemIdString(item),
            uuid = NMInventoryHelpers.getItemStateUuid(item)
        }
    end

    local removedOk = pcall(sourceContainer.DoRemoveItem, sourceContainer, item)
    if not removedOk then
        return nil, "source_remove_failed", nil
    end

    local addOk, addResult = pcall(inv.AddItem, inv, item)
    if not addOk then
        if sourceContainer.AddItem then
            pcall(sourceContainer.AddItem, sourceContainer, item)
        end
        return nil, "target_add_failed", nil
    end

    local liveItem = nil
    if addResult and addResult.getID then
        liveItem = addResult
    end
    if not liveItem then
        liveItem = NMInventoryHelpers.findDirectItemByUuid(inv, targetUuid)
            or NMInventoryHelpers.findDirectItemById(inv, targetId)
    end
    if not liveItem and NMInventoryHelpers.isItemInRootInventory(inv, item) then
        liveItem = item
    end
    if not liveItem then
        return nil, "target_lookup_failed", nil
    end

    NMInventoryHelpers.refreshInventoryPagesForPlayer(player)
    return liveItem, nil, {
        moved = true,
        deferred = false,
        inventory = inv,
        sourceContainer = sourceContainer,
        targetContainer = inv,
        sourceItem = item,
        targetItem = liveItem,
        itemId = NMInventoryHelpers.getItemIdString(liveItem),
        uuid = NMInventoryHelpers.getItemStateUuid(liveItem)
    }
end

function NMInventoryHelpers.findWorldItemByUuidNearPlayer(player, uuid, radius, floors)
    local target = tostring(uuid or "")
    if not player or target == "" then return nil end
    local sq = player.getSquare and player:getSquare() or nil
    if not sq then return nil end
    local cell = getCell and getCell() or nil
    if not cell then return nil end

    local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
    local r = radius or 4
    local f = math.max(0, math.floor(tonumber(floors) or 0))
    local minZ = pz - f
    local maxZ = pz + f
    if getMaximumWorldLevel then
        local worldMax = tonumber(getMaximumWorldLevel()) or maxZ
        if minZ < 0 then minZ = 0 end
        if maxZ > worldMax then maxZ = worldMax end
    end

    for x = px - r, px + r do
        for y = py - r, py + r do
            for z = minZ, maxZ do
                local grid = cell:getGridSquare(x, y, z)
                if grid and grid.getWorldObjects then
                    local objs = grid:getWorldObjects()
                    if objs then
                        for i = 0, objs:size() - 1 do
                            local obj = objs:get(i)
                            local item = obj and obj.getItem and obj:getItem() or nil
                            if item then
                                local itemUuid = NMInventoryHelpers.getItemStateUuid(item)
                                if itemUuid ~= "" and itemUuid == target then
                                    return item
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

