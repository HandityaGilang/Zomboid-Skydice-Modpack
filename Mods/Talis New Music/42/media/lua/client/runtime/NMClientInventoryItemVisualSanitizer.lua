NMClientInventoryItemVisualSanitizer = NMClientInventoryItemVisualSanitizer or {}

local SWEEP_INTERVAL_TICKS = 30

local function logRuntime(tag, detail)
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        NMCore.logChannel("runtimeProbe", tostring(tag or "inventory_item_visual"), tostring(detail or ""))
    end
end

local function sanitizeInventoryItem(item, reason)
    local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
    if not NMWorldItemVisuals or not NMWorldItemVisuals.isRelevantFullType(fullType) then
        return false
    end
    local ok, status = NMWorldItemVisuals.ensureVisual(item)
    if ok ~= true then
        logRuntime(
            "inventory_item_visual_sanitize",
            string.format(
                "reason=%s fullType=%s ok=%s status=%s",
                tostring(reason or "unknown"),
                tostring(fullType),
                tostring(ok == true),
                tostring(status or "")
            )
        )
    end
    return ok == true
end

local function sweepPlayerInventory(player, reason)
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory then
        return 0
    end
    local all = {}
    NMInventoryHelpers.collectItemsRecursive(inventory, all)
    local processed = 0
    for i = 1, #all do
        if sanitizeInventoryItem(all[i], reason) then
            processed = processed + 1
        end
    end
    return processed
end

function NMClientInventoryItemVisualSanitizer.onTick(player)
    NMClientInventoryItemVisualSanitizer._tickCounter = (tonumber(NMClientInventoryItemVisualSanitizer._tickCounter) or 0) + 1
    if NMClientInventoryItemVisualSanitizer._tickCounter == 1
        or (NMClientInventoryItemVisualSanitizer._tickCounter % SWEEP_INTERVAL_TICKS) == 0 then
        sweepPlayerInventory(player, "inventory_sweep")
    end
end

function NMClientInventoryItemVisualSanitizer.onGameStart()
    NMClientInventoryItemVisualSanitizer._tickCounter = 0
end

return NMClientInventoryItemVisualSanitizer
