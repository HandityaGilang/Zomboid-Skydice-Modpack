-- Lightweight UI performance probe with rolling 2s summaries.
NMUIRenderProbe = NMUIRenderProbe or {}

local SUMMARY_WINDOW_MS = 2000
local DETAIL_THRESHOLD_MS = 2.0
local FRAME_THRESHOLD_MS = 12.0

local function nowMs()
    return (getTimestampMs and tonumber(getTimestampMs()))
        or (getTimeInMillis and tonumber(getTimeInMillis()))
        or 0
end

local function isEnabled()
    return NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("uiPerfProbe") == true
end

local function ensureWindowStore(window)
    if not window then return nil end
    window._nmUiPerf = window._nmUiPerf or {
        startedMs = nowMs(),
        lastFlushMs = 0,
        metrics = {},
        counters = {},
        runId = tostring(math.floor(nowMs()))
    }
    return window._nmUiPerf
end

local function ensureMetric(store, key)
    local metrics = store.metrics
    metrics[key] = metrics[key] or { count = 0, sumMs = 0.0, maxMs = 0.0 }
    return metrics[key]
end

function NMUIRenderProbe.count(window, key, delta)
    if not isEnabled() then return end
    local store = ensureWindowStore(window)
    if not store then return end
    local k = tostring(key or "unknown")
    store.counters[k] = (tonumber(store.counters[k]) or 0) + (tonumber(delta) or 1)
end

function NMUIRenderProbe.beginWindow(window)
    if not isEnabled() then return nil end
    if not ensureWindowStore(window) then return nil end
    return nowMs()
end

function NMUIRenderProbe.endWindow(window, key, startedMs)
    if not isEnabled() then return 0 end
    if not startedMs then return 0 end
    local store = ensureWindowStore(window)
    if not store then return 0 end
    local elapsed = math.max(0, nowMs() - tonumber(startedMs or 0))
    local metric = ensureMetric(store, tostring(key or "unknown"))
    metric.count = metric.count + 1
    metric.sumMs = metric.sumMs + elapsed
    if elapsed > metric.maxMs then
        metric.maxMs = elapsed
    end
    if elapsed >= DETAIL_THRESHOLD_MS and NMCore and NMCore.shouldLogEvery
        and NMCore.shouldLogEvery("uiPerf.detail." .. tostring(key), nowMs(), 350) then
        NMCore.logChannel(
            "uiPerfProbe",
            "ui_perf_detail",
            string.format("run=%s key=%s ms=%.2f", tostring(store.runId), tostring(key), elapsed)
        )
    end
    return elapsed
end

function NMUIRenderProbe.flush(window)
    if not isEnabled() then return end
    local store = ensureWindowStore(window)
    if not store then return end
    local now = nowMs()
    local lastFlushMs = tonumber(store.lastFlushMs) or 0
    if (now - lastFlushMs) < SUMMARY_WINDOW_MS then
        return
    end
    store.lastFlushMs = now
    local frame = store.metrics["device.frame"] or { count = 0, sumMs = 0, maxMs = 0 }
    local frameAvg = (frame.count > 0) and (frame.sumMs / frame.count) or 0
    local render = store.metrics["device.render"] or { count = 0, sumMs = 0, maxMs = 0 }
    local update = store.metrics["device.update"] or { count = 0, sumMs = 0, maxMs = 0 }
    local resolve = store.metrics["device.resolveContext"] or { count = 0, sumMs = 0, maxMs = 0 }
    local autoClose = store.metrics["device.autoCloseCheck"] or { count = 0, sumMs = 0, maxMs = 0 }
    local hpRender = store.metrics["slot.headphone.render"] or { count = 0, sumMs = 0, maxMs = 0 }
    local hpStyle = store.metrics["slot.headphone.render.style"] or { count = 0, sumMs = 0, maxMs = 0 }
    local hpResolveState = store.metrics["slot.headphone.render.resolve_state"] or { count = 0, sumMs = 0, maxMs = 0 }
    local hpResolveTex = store.metrics["slot.headphone.render.resolve_tex"] or { count = 0, sumMs = 0, maxMs = 0 }
    local hpDrawTex = store.metrics["slot.headphone.render.draw_tex"] or { count = 0, sumMs = 0, maxMs = 0 }
    local hpPlaceholder = store.metrics["slot.headphone.render.placeholder"] or { count = 0, sumMs = 0, maxMs = 0 }
    local counters = store.counters or {}
    NMCore.logChannel(
        "uiPerfProbe",
        "ui_perf_summary",
        string.format(
            "run=%s frame_avg_ms=%.2f frame_max_ms=%.2f frame_calls=%d render_avg_ms=%.2f update_avg_ms=%.2f resolve_calls=%d autoClose_calls=%d fastPath=%d slowPath=%d cacheHit=%d cacheMiss=%d fallback=%d dragChecks=%d candidateScans=%d hp_avg_ms=%.2f hp_max_ms=%.2f hp_style_max=%.2f hp_state_max=%.2f hp_tex_resolve_max=%.2f hp_tex_draw_max=%.2f hp_placeholder_max=%.2f",
            tostring(store.runId),
            frameAvg,
            tonumber(frame.maxMs) or 0,
            tonumber(frame.count) or 0,
            (render.count > 0) and (render.sumMs / render.count) or 0,
            (update.count > 0) and (update.sumMs / update.count) or 0,
            tonumber(resolve.count) or 0,
            tonumber(autoClose.count) or 0,
            tonumber(counters["autoclose.fast"] or 0),
            tonumber(counters["autoclose.slow"] or 0),
            tonumber(counters["context.cache_hit"] or 0),
            tonumber(counters["context.cache_miss"] or 0),
            tonumber(counters["context.fallback"] or 0),
            tonumber(counters["slot.drag_check"] or 0),
            tonumber(counters["slot.candidate_scan"] or 0),
            (hpRender.count > 0) and (hpRender.sumMs / hpRender.count) or 0,
            tonumber(hpRender.maxMs) or 0,
            tonumber(hpStyle.maxMs) or 0,
            tonumber(hpResolveState.maxMs) or 0,
            tonumber(hpResolveTex.maxMs) or 0,
            tonumber(hpDrawTex.maxMs) or 0,
            tonumber(hpPlaceholder.maxMs) or 0
        )
    )
    if frameAvg >= FRAME_THRESHOLD_MS and NMCore and NMCore.logChannel then
        NMCore.logChannel(
            "uiPerfProbe",
            "ui_perf_frame_hot",
            string.format("run=%s frame_avg_ms=%.2f frame_max_ms=%.2f", tostring(store.runId), frameAvg, tonumber(frame.maxMs) or 0)
        )
    end
    store.metrics = {}
    store.counters = {}
end

return NMUIRenderProbe
