-- Client-side mode candidate reconcile for attached/placed/stowed transitions.
NMClientModeReconcile = NMClientModeReconcile or {}
NMClientModeReconcile.authority = NMClientModeReconcile.authority or {}

local function getSlot(uuid)
    local key = tostring(uuid or "")
    if key == "" then
        return nil
    end
    local slot = NMClientModeReconcile.authority[key]
    if not slot then
        slot = {
            mode = "off",
            sourceGeneration = 0,
            noCarryStreak = 0,
            lastTick = 0
        }
        NMClientModeReconcile.authority[key] = slot
    end
    return slot
end

local function isAttached(player, item, uuid)
    local itemId = NMInventoryHelpers.getItemIdString(item)
    if itemId == "" then return false end

    -- Held devices should be treated as carried/attached, not stowed.
    local primary = player and player.getPrimaryHandItem and player:getPrimaryHandItem() or nil
    if NMAttachmentHelpers.itemMatchesTarget(primary, itemId, item, uuid) then
        return true
    end
    local secondary = player and player.getSecondaryHandItem and player:getSecondaryHandItem() or nil
    if NMAttachmentHelpers.itemMatchesTarget(secondary, itemId, item, uuid) then
        return true
    end

    local attachedItems = player and player.getAttachedItems and player:getAttachedItems() or nil
    if attachedItems then
        for i = 0, attachedItems:size() - 1 do
            local entry = attachedItems:get(i)
            local attachedItem = entry and entry.getItem and entry:getItem() or nil
            if NMAttachmentHelpers.itemMatchesTarget(attachedItem, itemId, item, uuid) then
                return true
            end
        end
    end

    if NMAttachmentHelpers.isItemWornOnBack(player, itemId, item, uuid) then
        return true
    end
    return false
end

function NMClientModeReconcile.resolveModeForItem(player, item, profile, state)
    if not player or not item or not profile or not state then
        return "off"
    end
    if NMDeviceState and NMDeviceState.isZombieDormant and NMDeviceState.isZombieDormant(state) then
        return "off"
    end

    local uuid = tostring(state.deviceUUID or "")
    local attached = isAttached(player, item, uuid)
    local worldItem = item.getWorldItem and item:getWorldItem() or nil
    local square = worldItem and worldItem.getSquare and worldItem:getSquare() or nil

    local slot = getSlot(uuid)
    if attached then
        slot.noCarryStreak = 0
    else
        slot.noCarryStreak = (tonumber(slot.noCarryStreak) or 0) + 1
    end

    if attached and (NMDeviceProfiles.canAnyWorldPlayback(profile) or NMDeviceProfiles.isPortableTrackedProfile(profile)) then
        return "attached"
    end
    if square and (NMDeviceProfiles.canPlacedWorldPlayback(profile) or NMDeviceProfiles.isPortableTrackedProfile(profile)) then
        return "placed"
    end
    if (not attached)
        and (not square)
        and NMClientPortableDropHandoff
        and NMClientPortableDropHandoff.hasPending
        and NMClientPortableDropHandoff.hasPending(uuid)
        and NMDeviceProfiles.isPortableTrackedProfile(profile) then
        return "drop_pending"
    end
    if (not attached) and (not square) and (NMDeviceProfiles.canAnyWorldPlayback(profile) or NMDeviceProfiles.isPortableTrackedProfile(profile)) then
        return "stowed"
    end
    return "off"
end

function NMClientModeReconcile.applyResolvedMode(uuid, state, mode)
    local slot = getSlot(uuid)
    if not slot or not state then
        return false
    end
    local nextMode = tostring(mode or "off")
    local prevMode = tostring(slot.mode or "off")
    if prevMode == nextMode then
        slot.lastTick = (tonumber(slot.lastTick) or 0) + 1
        return false
    end
    slot.mode = nextMode
    slot.sourceGeneration = math.max(tonumber(slot.sourceGeneration) or 0, tonumber(state.sourceGeneration) or 0)
    slot.lastTick = (tonumber(slot.lastTick) or 0) + 1
    return true
end

function NMClientModeReconcile.forEachAuthority(fn)
    if type(fn) ~= "function" then
        return
    end
    for uuid, slot in pairs(NMClientModeReconcile.authority) do
        fn(uuid, slot)
    end
end

function NMClientModeReconcile.pruneAuthority(validMap)
    for uuid, _ in pairs(NMClientModeReconcile.authority) do
        if not (validMap and validMap[uuid]) then
            NMClientModeReconcile.authority[uuid] = nil
        end
    end
end

