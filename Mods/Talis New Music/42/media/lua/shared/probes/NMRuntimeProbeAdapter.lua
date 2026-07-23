-- Shared runtime probe adapter for transition/heartbeat dedupe emission.
NMRuntimeProbeAdapter = NMRuntimeProbeAdapter or {}
NMRuntimeProbeAdapter.HEARTBEAT_SHORT_MS = 15000
NMRuntimeProbeAdapter.HEARTBEAT_STANDARD_MS = 20000
NMRuntimeProbeAdapter.HEARTBEAT_LONG_MS = 60000

function NMRuntimeProbeAdapter.shortHeartbeatMs()
    return NMRuntimeProbeAdapter.HEARTBEAT_SHORT_MS
end

function NMRuntimeProbeAdapter.standardHeartbeatMs()
    return NMRuntimeProbeAdapter.HEARTBEAT_STANDARD_MS
end

function NMRuntimeProbeAdapter.longHeartbeatMs()
    return NMRuntimeProbeAdapter.HEARTBEAT_LONG_MS
end

local function nowMs()
    if getTimestampMs then
        local ms = tonumber(getTimestampMs())
        if ms then
            return ms
        end
    end
    if getTimestamp then
        local ts = tonumber(getTimestamp())
        if ts then
            return ts * 1000
        end
    end
    return 0
end

local function ensureStore(store)
    if type(store) ~= "table" then
        return {}
    end
    return store
end

function NMRuntimeProbeAdapter.shouldEmitTransition(store, key, sig)
    local map = ensureStore(store)
    local k = tostring(key or "")
    local s = tostring(sig or "")
    local prev = tostring(map[k] or "")
    if prev == s then
        return false
    end
    map[k] = s
    return true
end

function NMRuntimeProbeAdapter.shouldEmitHeartbeat(store, key, intervalMs)
    local map = ensureStore(store)
    local k = tostring(key or "")
    local now = nowMs()
    local last = tonumber(map[k]) or 0
    local interval = math.max(1, tonumber(intervalMs) or 20000)
    if last > 0 and (now - last) < interval then
        return false
    end
    map[k] = now
    return true
end

function NMRuntimeProbeAdapter.shouldEmitTransitionOrHeartbeat(sigStore, msStore, key, sig, intervalMs)
    local changed = NMRuntimeProbeAdapter.shouldEmitTransition(sigStore, key, sig)
    if changed then
        NMRuntimeProbeAdapter.shouldEmitHeartbeat(msStore, key, 1)
        return true
    end
    return NMRuntimeProbeAdapter.shouldEmitHeartbeat(msStore, key, intervalMs)
end

function NMRuntimeProbeAdapter.emit(knob, channel, tag, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn(knob)) then
        return
    end
    NMCore.logChannel(tostring(channel or "runtimeProbe"), tostring(tag or "probe"), tostring(detail or ""))
end

return NMRuntimeProbeAdapter

