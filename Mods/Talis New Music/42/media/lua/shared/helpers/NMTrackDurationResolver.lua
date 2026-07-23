-- Shared track duration resolver for server authoritative scheduling paths.
NMTrackDurationResolver = NMTrackDurationResolver or {}

local function resolveFallbackMs(fallbackMs)
    local value = tonumber(fallbackMs) or 210000
    return math.max(1000, math.floor(value + 0.5))
end

local function coerceDurationMsFromRow(row)
    if type(row) ~= "table" then
        return nil, nil
    end
    local durationMs = tonumber(row.durationMs)
    if durationMs and durationMs > 0 then
        return math.max(1000, math.floor(durationMs + 0.5)), "durationMs"
    end
    local durationSeconds = tonumber(row.durationSeconds) or tonumber(row.lengthSeconds) or tonumber(row.duration)
    if durationSeconds and durationSeconds > 0 then
        return math.max(1000, math.floor((durationSeconds * 1000) + 0.5)), "durationSeconds"
    end
    return nil, nil
end

function NMTrackDurationResolver.resolveForState(state, fallbackMs)
    local fallback = resolveFallbackMs(fallbackMs)
    if not state or not state.mediaFullType or not NMMusic or not NMMusic.resolveTracks then
        return {
            durationMs = fallback,
            knownDuration = false,
            source = "fallback",
            trackIndex = tonumber(state and state.trackIndex) or 1,
            row = nil
        }
    end

    local ok, resolved = pcall(NMMusic.resolveTracks, state.mediaFullType)
    if not ok or type(resolved) ~= "table" or type(resolved.tracks) ~= "table" then
        return {
            durationMs = fallback,
            knownDuration = false,
            source = "fallback",
            trackIndex = tonumber(state and state.trackIndex) or 1,
            row = nil
        }
    end

    local tracks = resolved.tracks
    local count = #tracks
    if count < 1 then
        return {
            durationMs = fallback,
            knownDuration = false,
            source = "fallback",
            trackIndex = tonumber(state and state.trackIndex) or 1,
            row = nil
        }
    end

    local idx = math.max(1, math.min(tonumber(state.trackIndex) or 1, count))
    local row = tracks[idx]
    local durationMs, source = coerceDurationMsFromRow(row)
    if durationMs then
        return {
            durationMs = durationMs,
            knownDuration = true,
            source = source or "durationMs",
            trackIndex = idx,
            row = row
        }
    end

    local hintTable = type(state and state.observedTrackDurationHints) == "table" and state.observedTrackDurationHints or nil
    local hintedMs = tonumber(hintTable and hintTable[idx]) or 0
    if hintedMs > 0 then
        return {
            durationMs = math.max(1000, math.floor(hintedMs + 0.5)),
            knownDuration = true,
            source = "observed_hint",
            trackIndex = idx,
            row = row
        }
    end

    return {
        durationMs = fallback,
        knownDuration = false,
        source = "fallback",
        trackIndex = idx,
        row = row
    }
end

