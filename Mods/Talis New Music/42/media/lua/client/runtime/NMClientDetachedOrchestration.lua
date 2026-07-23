-- Detached source orchestration helpers extracted from playback tick.
NMClientDetachedOrchestration = NMClientDetachedOrchestration or {}

function NMClientDetachedOrchestration.buildConflictStateKey(hasInventoryOwner, detachedContext)
    return tostring(hasInventoryOwner == true) .. ":" .. tostring(detachedContext or "unknown")
end

function NMClientDetachedOrchestration.shouldPruneDetachedForInventoryOwner(hasInventoryOwner, detachedContext)
    if hasInventoryOwner ~= true then
        return false
    end
    return tostring(detachedContext or "") ~= "vehicle"
end

function NMClientDetachedOrchestration.shouldEmitDetachedRemove(nowMsValue, lastMs, minIntervalMs)
    local nowMs = tonumber(nowMsValue) or 0
    local prev = tonumber(lastMs) or 0
    local intervalMs = math.max(0, tonumber(minIntervalMs) or 5000)
    return (nowMs - prev) >= intervalMs
end

function NMClientDetachedOrchestration.applyInventoryOwnershipGate(args)
    local input = type(args) == "table" and args or {}
    local hasInventoryOwner = input.hasInventoryOwner == true
    local detachedContext = tostring(input.detachedContext or "unknown")
    local conflictStateKey = NMClientDetachedOrchestration.buildConflictStateKey(hasInventoryOwner, detachedContext)
    local previousConflictState = tostring(input.previousConflictState or "")
    local conflictChanged = previousConflictState ~= conflictStateKey
    local shouldPrune = NMClientDetachedOrchestration.shouldPruneDetachedForInventoryOwner(hasInventoryOwner, detachedContext)
    local shouldEmitDetachedRemove = false
    if conflictChanged and shouldPrune then
        shouldEmitDetachedRemove = NMClientDetachedOrchestration.shouldEmitDetachedRemove(
            input.nowMsValue,
            input.lastDetachedRemoveMs,
            input.detachedRemoveIntervalMs
        )
    end
    return {
        conflictStateKey = conflictStateKey,
        conflictChanged = conflictChanged,
        shouldPrune = shouldPrune,
        shouldEmitDetachedRemove = shouldEmitDetachedRemove
    }
end

function NMClientDetachedOrchestration.makeDetachedSyncLogKey(deviceUuid)
    return "runtimeProbe.detached." .. tostring(deviceUuid or "")
end

function NMClientDetachedOrchestration.buildDetachedSyncDetail(state, source)
    return string.format(
        "uuid=%s ctx=%s x=%.2f y=%.2f z=%.2f isOn=%s isPlaying=%s media=%s",
        tostring(state and state.deviceUUID or ""),
        tostring(source and source.context or "nil"),
        tonumber(source and source.x or 0) or 0,
        tonumber(source and source.y or 0) or 0,
        tonumber(source and source.z or 0) or 0,
        tostring(state and state.isOn == true),
        tostring(state and state.isPlaying == true),
        tostring(state and state.mediaFullType or "nil")
    )
end

return NMClientDetachedOrchestration

