-- Internal helper functions for NMPlaybackRuntime.
NMPlaybackRuntimeCommon = NMPlaybackRuntimeCommon or {}

local function logTrackEndProbe(tag, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")) then
        return
    end
    NMCore.logChannel("progressionProbe", tostring(tag or "track_end_probe"), tostring(detail or ""))
end

function NMPlaybackRuntimeCommon.getNowRealMs()
    if getTimestampMs then
        local ms = tonumber(getTimestampMs())
        if ms then return ms end
    end
    if getTimestamp then
        local ts = tonumber(getTimestamp())
        if ts then return ts * 1000 end
    end
    if os and os.time then
        return (tonumber(os.time()) or 0) * 1000
    end
    return 0
end

function NMPlaybackRuntimeCommon.applyPowerDrain(powerTickMap, profile, state, tickCount)
    if not profile or not state or not state.deviceUUID then return end
    if not profile.requiresBattery then return end

    local key = tostring(state.deviceUUID)
    local nowMs = NMPlaybackRuntimeCommon.getNowRealMs()
    local lastMs = tonumber(powerTickMap[key])

    if not state.isOn then
        powerTickMap[key] = nowMs
        return
    end
    if not state.batteryPresent then
        -- Keep power-on intent/state so UI can show On(NoPower); only playback is blocked.
        state.isPlaying = false
        state.desiredIsPlaying = false
        state.lastStopReason = "battery_missing"
        powerTickMap[key] = nowMs
        return
    end

    local charge = NMCore.clamp(tonumber(state.batteryCharge) or 0.0, 0.0, 1.0)
    if charge <= 0 then
        state.batteryCharge = 0.0
        -- Keep power-on intent/state so UI can show On(NoPower); only playback is blocked.
        state.isPlaying = false
        state.desiredIsPlaying = false
        state.lastStopReason = "battery_empty"
        powerTickMap[key] = nowMs
        return
    end

    if lastMs == nil then
        powerTickMap[key] = nowMs
        return
    end

    local deltaSeconds = math.max(0, (nowMs - lastMs) / 1000.0)
    if deltaSeconds <= 0 then return end
    local drainSeconds = tonumber(NMRuntimeConfig.getBatteryDrainSecondsPortableFromSandbox and NMRuntimeConfig.getBatteryDrainSecondsPortableFromSandbox() or 86400) or 86400
    if drainSeconds <= 0 then
        powerTickMap[key] = nowMs
        return
    end

    state.batteryCharge = NMCore.clamp(charge - (deltaSeconds / drainSeconds), 0.0, 1.0)
    powerTickMap[key] = nowMs
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") and NMCore.shouldLogEvery then
        local logKey = "runtimeProbe.batteryDrain.portable." .. tostring(key)
        if NMCore.shouldLogEvery(logKey, nowMs, 5000) then
            NMCore.logChannel(
                "runtimeProbe",
                "battery_drain_tick",
                string.format(
                    "uuid=%s type=portable deltaMs=%d old=%.3f new=%.3f targetSeconds=%.0f",
                    tostring(key),
                    math.floor(math.max(0, nowMs - lastMs)),
                    charge,
                    tonumber(state.batteryCharge) or 0,
                    drainSeconds
                )
            )
        end
    end
    if state.batteryCharge <= 0 then
        state.batteryCharge = 0.0
        -- Keep power-on intent/state so UI can show On(NoPower); only playback is blocked.
        state.isPlaying = false
        state.desiredIsPlaying = false
        state.lastStopReason = "battery_empty"
    end
end

function NMPlaybackRuntimeCommon.updateTrackEndState(trackEndPendingMap, trackEndedMap, awaitingMap, uuid, state, active, profile)
    local emitter = active and active.emitter or nil
    local pending = trackEndPendingMap[uuid]
    if not emitter or not active.soundId or not emitter.isPlaying then
        return false
    end
    local playing = emitter:isPlaying(active.soundId)
    if playing ~= false then
        if pending then
            logTrackEndProbe(
                "track_end_false_cleared",
                string.format(
                    "uuid=%s type=%s epoch=%s track=%s falseCount=%s media=%s",
                    tostring(uuid),
                    tostring(profile and profile.deviceType or state and state.deviceType or "unknown"),
                    tostring(state and state.playbackEpoch or -1),
                    tostring(state and state.trackIndex or -1),
                    tostring(pending and pending.falseCount or 0),
                    tostring(state and state.mediaFullType or "nil")
                )
            )
        end
        trackEndPendingMap[uuid] = nil
        return false
    end

    local nowMs = NMPlaybackRuntimeCommon.getNowRealMs()
    local deviceType = profile and profile.deviceType or state and state.deviceType or nil
    local windowMs = math.max(250, tonumber(NMRuntimeConfig.getTrackEndPendingWindowMsForDeviceType and NMRuntimeConfig.getTrackEndPendingWindowMsForDeviceType(deviceType) or 1200) or 1200)
    local falseChecks = math.max(1, tonumber(NMRuntimeConfig.getTrackEndPendingFalseChecksForDeviceType and NMRuntimeConfig.getTrackEndPendingFalseChecksForDeviceType(deviceType) or 3) or 3)

    if not pending then
        trackEndPendingMap[uuid] = { firstFalseMs = nowMs, falseCount = 1 }
        logTrackEndProbe(
            "track_end_false_start",
            string.format(
                "uuid=%s type=%s epoch=%s track=%s windowMs=%s falseChecks=%s media=%s",
                tostring(uuid),
                tostring(deviceType or "unknown"),
                tostring(state and state.playbackEpoch or -1),
                tostring(state and state.trackIndex or -1),
                tostring(windowMs),
                tostring(falseChecks),
                tostring(state and state.mediaFullType or "nil")
            )
        )
        return false
    end

    pending.falseCount = (tonumber(pending.falseCount) or 0) + 1
    local elapsed = nowMs - (tonumber(pending.firstFalseMs) or nowMs)
    local shouldLogProgress = true
    if NMCore and NMCore.shouldLogEvery then
        local logKey = string.format(
            "progressionProbe.track_end_false_progress.%s.%s.%s",
            tostring(uuid or ""),
            tostring(state and state.playbackEpoch or -1),
            tostring(state and state.trackIndex or -1)
        )
        shouldLogProgress = NMCore.shouldLogEvery(logKey, nowMs, 250)
            or elapsed >= windowMs
            or (tonumber(pending.falseCount) or 0) == falseChecks
    end
    if shouldLogProgress then
        logTrackEndProbe(
            "track_end_false_progress",
            string.format(
                "uuid=%s type=%s epoch=%s track=%s elapsedMs=%s falseCount=%s windowMs=%s falseChecks=%s",
                tostring(uuid),
                tostring(deviceType or "unknown"),
                tostring(state and state.playbackEpoch or -1),
                tostring(state and state.trackIndex or -1),
                tostring(elapsed),
                tostring(pending.falseCount),
                tostring(windowMs),
                tostring(falseChecks)
            )
        )
    end
    if elapsed >= windowMs and (tonumber(pending.falseCount) or 0) >= falseChecks then
        trackEndPendingMap[uuid] = nil
        trackEndedMap[uuid] = {
            uuid = uuid,
            playbackEpoch = tonumber(state and state.playbackEpoch) or -1,
            trackIndex = tonumber(state and state.trackIndex) or -1,
            sourceGeneration = tonumber(state and state.sourceGeneration) or -1,
            token = tostring(uuid) .. ":" .. tostring(tonumber(state and state.playbackEpoch) or -1) .. ":" .. tostring(tonumber(state and state.trackIndex) or -1),
            observedDurationMs = math.max(0, nowMs - (tonumber(active and active.startedAtMs) or nowMs))
        }
        awaitingMap[uuid] = {
            playbackEpoch = tonumber(state and state.playbackEpoch) or -1,
            trackIndex = tonumber(state and state.trackIndex) or -1,
            sourceGeneration = tonumber(state and state.sourceGeneration) or -1,
            setAtMs = nowMs
        }
        logTrackEndProbe(
            "track_end_confirmed",
            string.format(
                "uuid=%s type=%s epoch=%s track=%s observedDurationMs=%s media=%s",
                tostring(uuid),
                tostring(deviceType or "unknown"),
                tostring(state and state.playbackEpoch or -1),
                tostring(state and state.trackIndex or -1),
                tostring(trackEndedMap[uuid] and trackEndedMap[uuid].observedDurationMs or 0),
                tostring(state and state.mediaFullType or "nil")
            )
        )
        return true
    end

    trackEndPendingMap[uuid] = pending
    return false
end

