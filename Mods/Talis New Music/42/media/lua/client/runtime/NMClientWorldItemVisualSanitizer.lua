NMClientWorldItemVisualSanitizer = NMClientWorldItemVisualSanitizer or {}

local pendingWorldSync = {}
local SWEEP_INTERVAL_TICKS = 30
local SWEEP_RADIUS = 12
local RETRY_TICKS = 60

local function logRuntime(tag, detail)
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        NMCore.logChannel("runtimeProbe", tostring(tag or "world_item_visual"), tostring(detail or ""))
    end
end

local function isWorldInventoryObject(obj)
    return obj and instanceof and instanceof(obj, "IsoWorldInventoryObject")
end

local function getWorldItemFullType(obj)
    local item = obj and obj.getItem and obj:getItem() or nil
    return item and item.getFullType and tostring(item:getFullType() or "") or ""
end

local function queuePendingWorld(obj, reason)
    if not isWorldInventoryObject(obj) then
        return
    end
    pendingWorldSync[obj] = {
        obj = obj,
        ticks = RETRY_TICKS,
        reason = tostring(reason or "pending")
    }
end

local function sanitizeWorldObject(obj, reason)
    if not isWorldInventoryObject(obj) then
        return false
    end
    local item = obj:getItem()
    local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
    if not NMWorldItemVisuals.isRelevantFullType(fullType) then
        return false
    end
    local ok, status = NMWorldItemVisuals.ensureVisual(item)
    if ok ~= true or tostring(status or "") ~= "visual_ready" then
        logRuntime(
            "world_item_visual_sanitize",
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

local function sweepNearbyWorldItems(player)
    local square = player and player.getCurrentSquare and player:getCurrentSquare() or nil
    local cell = getCell and getCell() or nil
    if not square or not cell then
        return 0
    end

    local processed = 0
    local sx = square:getX()
    local sy = square:getY()
    local sz = square:getZ()

    for x = sx - SWEEP_RADIUS, sx + SWEEP_RADIUS do
        for y = sy - SWEEP_RADIUS, sy + SWEEP_RADIUS do
            local gridSquare = cell:getGridSquare(x, y, sz)
            if gridSquare and gridSquare.getWorldObjects then
                local worldObjects = gridSquare:getWorldObjects()
                for i = 0, worldObjects:size() - 1 do
                    local obj = worldObjects:get(i)
                    if isWorldInventoryObject(obj) then
                        local fullType = getWorldItemFullType(obj)
                        if NMWorldItemVisuals.isRelevantFullType(fullType) then
                            sanitizeWorldObject(obj, "nearby_sweep")
                            processed = processed + 1
                        end
                    end
                end
            end
        end
    end
    return processed
end

function NMClientWorldItemVisualSanitizer.onObjectAdded(obj)
    if not isWorldInventoryObject(obj) then
        return
    end
    local fullType = getWorldItemFullType(obj)
    if not NMWorldItemVisuals.isRelevantFullType(fullType) then
        return
    end
    if not sanitizeWorldObject(obj, "object_added") then
        queuePendingWorld(obj, "object_added_retry")
    end
end

function NMClientWorldItemVisualSanitizer.onTick(player)
    NMClientWorldItemVisualSanitizer._tickCounter = (tonumber(NMClientWorldItemVisualSanitizer._tickCounter) or 0) + 1

    for obj, entry in pairs(pendingWorldSync) do
        if not isWorldInventoryObject(obj) then
            pendingWorldSync[obj] = nil
        else
            entry.ticks = (tonumber(entry.ticks) or 0) - 1
            if sanitizeWorldObject(obj, entry.reason or "pending_retry") or entry.ticks <= 0 then
                pendingWorldSync[obj] = nil
            end
        end
    end

    if NMClientWorldItemVisualSanitizer._tickCounter == 1
        or (NMClientWorldItemVisualSanitizer._tickCounter % SWEEP_INTERVAL_TICKS) == 0 then
        sweepNearbyWorldItems(player)
    end
end

function NMClientWorldItemVisualSanitizer.onGameStart()
    pendingWorldSync = {}
    NMClientWorldItemVisualSanitizer._tickCounter = 0
end

return NMClientWorldItemVisualSanitizer
