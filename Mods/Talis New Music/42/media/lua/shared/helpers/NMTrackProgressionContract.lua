-- Shared progression contract for duration classification and track-finished token semantics.
NMTrackProgressionContract = NMTrackProgressionContract or {}

local function resolveFallbackMs(fallbackMs)
    local value = tonumber(fallbackMs) or 210000
    return math.max(1000, math.floor(value + 0.5))
end

function NMTrackProgressionContract.resolve(state, options)
    local opts = type(options) == "table" and options or {}
    local fallbackMs = resolveFallbackMs(opts.fallbackMs)
    local context = tostring(opts.context or "")
    local worldAuthoritative = opts.worldAuthoritative == true
    local resolved = NMTrackDurationResolver.resolveForState(state, fallbackMs)
    local token = {
        uuid = tostring(state and state.deviceUUID or opts.uuid or ""),
        revision = tonumber(state and state.revision) or 0,
        playbackEpoch = tonumber(state and state.playbackEpoch) or 0,
        trackIndex = tonumber(state and state.trackIndex) or 0
    }
    local knownDuration = false
    local timingMode = "unknown_open"
    return {
        durationMs = tonumber(resolved and resolved.durationMs) or fallbackMs,
        knownDuration = knownDuration,
        timingMode = timingMode,
        source = tostring(resolved and resolved.source or "fallback"),
        trackIndex = tonumber(resolved and resolved.trackIndex) or token.trackIndex,
        row = resolved and resolved.row or nil,
        hintEligible = worldAuthoritative and not knownDuration,
        context = context,
        worldAuthoritative = worldAuthoritative,
        token = token
    }
end

