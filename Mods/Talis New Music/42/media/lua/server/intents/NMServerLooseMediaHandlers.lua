-- Server-authoritative handlers for loose-media actions that are not device intents.

NMServerLooseMediaHandlers = NMServerLooseMediaHandlers or {}

local function traceFlip(tag, detail)
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        NMCore.logChannel("runtimeProbe", tostring(tag or "flip_trace"), tostring(detail or ""))
    end
end

local function resolveOwningContainer(item, fallbackInventory)
    local container = item and item.getContainer and item:getContainer() or nil
    if container and container.DoRemoveItem and container.AddItem then
        return container
    end
    return fallbackInventory
end

function NMServerLooseMediaHandlers.flipMediaSide(player, args)
    if not player then
        return false
    end
    local inv = player.getInventory and player:getInventory() or nil
    if not inv then
        return false
    end

    local itemId = tostring(args and args.itemId or "")
    if itemId == "" then
        traceFlip("flip_server_reject", "reason=missing_item_id")
        return false
    end
    local item = NMInventoryHelpers.findItemById(inv, itemId)
    if not item or not item.getFullType then
        traceFlip("flip_server_reject", "reason=item_not_found itemId=" .. tostring(itemId))
        return false
    end

    local sourceFullType = tostring(item:getFullType() or "")
    local targetFullType = NMMediaContract and NMMediaContract.resolveMediaFlipTarget and NMMediaContract.resolveMediaFlipTarget(sourceFullType) or nil
    if not targetFullType or targetFullType == "" then
        traceFlip("flip_server_reject", "reason=no_flip_target itemId=" .. tostring(itemId) .. " source=" .. tostring(sourceFullType))
        return false
    end

    local ownerContainer = resolveOwningContainer(item, inv)
    if not ownerContainer then
        traceFlip("flip_server_reject", "reason=missing_owner itemId=" .. tostring(itemId))
        return false
    end
    -- MP safety: loose-media flip is inventory-only. World/container flips can
    -- produce identity drift and ghost interactions under replication.
    if ownerContainer ~= inv then
        traceFlip("flip_server_reject", "reason=non_inventory_container itemId=" .. tostring(itemId))
        if sendServerCommand and NMCore and NMCore.NetModule then
            sendServerCommand(player, NMCore.NetModule, "media_flip_result", {
                ok = false,
                oldItemId = itemId,
                reason = "non_inventory_container"
            })
        end
        return false
    end

    local oldRecorded = nil
    if item.getRecordedMediaIndex then
        oldRecorded = tonumber(item:getRecordedMediaIndex())
    elseif item.getRecordedMediaIndexInteger then
        oldRecorded = tonumber(item:getRecordedMediaIndexInteger())
    end

    -- Mirror the current mod's working server-side container swap path:
    -- remove authoritative source item, replicate that removal, then add the
    -- replacement item and replicate that add.
    if sendRemoveItemFromContainer then
        sendRemoveItemFromContainer(inv, item)
    end
    if inv.DoRemoveItem then
        inv:DoRemoveItem(item)
    else
        inv:Remove(item)
    end

    local swapped = NMWorldItemVisuals.addItemWithVisual and select(1, NMWorldItemVisuals.addItemWithVisual(inv, targetFullType)) or nil
    if not swapped then
        traceFlip("flip_server_reject", "reason=add_failed_after_remove itemId=" .. tostring(itemId) .. " target=" .. tostring(targetFullType))
        if sendServerCommand and NMCore and NMCore.NetModule then
            sendServerCommand(player, NMCore.NetModule, "media_flip_result", {
                ok = false,
                oldItemId = itemId
            })
        end
        return false
    end
    if oldRecorded and oldRecorded >= 0 then
        if swapped.setRecordedMediaIndex then
            pcall(swapped.setRecordedMediaIndex, swapped, oldRecorded)
        elseif swapped.setRecordedMediaIndexInteger then
            pcall(swapped.setRecordedMediaIndexInteger, swapped, oldRecorded)
        end
    end
    if sendAddItemToContainer then
        sendAddItemToContainer(inv, swapped)
    end
    traceFlip(
        "flip_server_apply",
        string.format(
            "player=%s oldItemId=%s newItemId=%s source=%s target=%s recIdx=%s",
            tostring(player and player.getUsername and player:getUsername() or "unknown"),
            tostring(itemId),
            tostring(swapped.getID and swapped:getID() or ""),
            tostring(sourceFullType),
            tostring(targetFullType),
            tostring(oldRecorded or "")
        )
    )
    if sendServerCommand and NMCore and NMCore.NetModule then
        sendServerCommand(player, NMCore.NetModule, "media_flip_result", {
            ok = true,
            oldItemId = itemId,
            newItemId = tostring(swapped.getID and swapped:getID() or ""),
            targetFullType = tostring(targetFullType or ""),
            recordedMediaIndex = oldRecorded
        })
    end
    traceFlip(
        "flip_server_ack",
        string.format(
            "oldItemId=%s newItemId=%s target=%s",
            tostring(itemId),
            tostring(swapped.getID and swapped:getID() or ""),
            tostring(targetFullType or "")
        )
    )
    return true
end

