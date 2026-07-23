-- Action-specific transition handlers used by NMDeviceTransitions.
NMTransitionActionHandlers = NMTransitionActionHandlers or {}

local function logTrackFinishedTransition(state, outcome, policy, trackIndex, nextTrackIndex, trackCount, observedDurationMs)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")) then
        return
    end
    NMCore.logChannel(
        "progressionProbe",
        "track_finished_transition",
        string.format(
            "uuid=%s outcome=%s policy=%s track=%s next=%s count=%s observedDurationMs=%s isOn=%s isPlaying=%s stopReason=%s",
            tostring(state and state.deviceUUID or "nil"),
            tostring(outcome or "unknown"),
            tostring(policy or "autoplay"),
            tostring(trackIndex or "nil"),
            tostring(nextTrackIndex or "nil"),
            tostring(trackCount or "nil"),
            tostring(observedDurationMs or 0),
            tostring(state and state.isOn == true),
            tostring(state and state.isPlaying == true),
            tostring(state and state.lastStopReason or "nil")
        )
    )
end

function NMTransitionActionHandlers.apply(profile, state, action, payload, ops)
    local changed = false

    if action == "insert_media" then
        if state.mediaFullType then return false, "media_present" end
        if payload.mediaCarrier ~= profile.supportedCarrier then return false, "wrong_media" end
        if not payload.mediaFullType then return false, "missing_media" end
        if payload.requiredMediaFullType and tostring(payload.requiredMediaFullType) ~= "" then
            local insertedType = payload.mediaItemFullType or payload.mediaEjectFullType or payload.mediaFullType
            local matchesRequired = false
            if NMMediaContract and NMMediaContract.areMediaEquivalent then
                matchesRequired = NMMediaContract.areMediaEquivalent(insertedType, payload.requiredMediaFullType)
            end
            if not matchesRequired and tostring(insertedType or "") ~= tostring(payload.requiredMediaFullType) then
                return false, "wrong_specific_media"
            end
        end
        state.mediaFullType = payload.mediaFullType
        state.mediaEjectFullType = payload.mediaEjectFullType or payload.mediaFullType
        if payload.requiredMediaFullType and tostring(payload.requiredMediaFullType) ~= "" then
            state.mediaEjectFullType = tostring(payload.requiredMediaFullType)
        end
        state.mediaRecordedMediaIndex = payload.mediaRecordedMediaIndex
        state.mediaDisplayName = payload.mediaDisplayName
        state.trackIndex = 1
        NMTransitionCommon.setStopped(state, nil)
        ops.consumeMediaItemId = payload.mediaItemId
        changed = true

    elseif action == "eject_media" then
        if not state.mediaFullType then return false, "no_media" end
        ops.produceMediaFullType = state.mediaEjectFullType or state.mediaFullType
        ops.produceMediaRecordedMediaIndex = state.mediaRecordedMediaIndex
        state.mediaFullType = nil
        state.mediaEjectFullType = nil
        state.mediaRecordedMediaIndex = nil
        state.mediaDisplayName = nil
        state.trackIndex = 1
        NMTransitionCommon.setStopped(state, "media_ejected")
        changed = true

    elseif action == "insert_headphones" then
        if not NMDeviceProfiles.supportsHeadphones(profile) then return false, "unsupported_headphones" end
        if state.headphoneItemFullType then return false, "headphones_present" end
        if not payload.headphoneItemFullType then return false, "missing_headphones" end
        state.headphoneItemFullType = payload.headphoneItemFullType
        if tostring(payload.headphoneItemFullType) == "Base.Headphones" then
            ops.wearHeadphoneItemId = payload.headphoneItemId
        else
            ops.consumeHeadphoneItemId = payload.headphoneItemId
        end
        changed = true

    elseif action == "eject_headphones" then
        if not NMDeviceProfiles.supportsHeadphones(profile) then return false, "unsupported_headphones" end
        if not state.headphoneItemFullType then return false, "no_headphones" end
        if tostring(state.headphoneItemFullType) == "Base.Headphones" then
            ops.unequipHeadphones = true
        else
            ops.produceHeadphoneFullType = state.headphoneItemFullType
        end
        state.headphoneItemFullType = nil
        if profile.requiresHeadphones then NMTransitionCommon.setStopped(state, "headphones_removed") end
        changed = true

    elseif action == "insert_battery" then
        if not NMDeviceProfiles.supportsBattery(profile) then return false, "unsupported_battery" end
        if state.batteryPresent then return false, "battery_present" end
        state.batteryPresent = true
        state.batteryCharge = NMCore.clamp(tonumber(payload.batteryCharge) or 0.0, 0.0, 1.0)
        ops.consumeBatteryItemId = payload.batteryItemId
        changed = true

    elseif action == "eject_battery" then
        if not NMDeviceProfiles.supportsBattery(profile) then return false, "unsupported_battery" end
        if not state.batteryPresent then return false, "no_battery" end
        ops.produceBatteryCharge = NMCore.clamp(tonumber(state.batteryCharge) or 0.0, 0.0, 1.0)
        state.batteryPresent = false
        state.batteryCharge = 0.0
        if profile.requiresBattery then
            state.isOn = false
            state.desiredIsOn = false
            NMTransitionCommon.setStopped(state, "battery_removed")
        end
        changed = true

    elseif action == "start_playback" then
        if state.isPlaying and state.desiredIsPlaying then
            return false, "already_playing"
        end
        local ok, reason = NMTransitionCommon.canPlay(profile, state, payload.hasTrack == true, payload)
        if not ok then
            NMTransitionCommon.setStopped(state, reason)
            return false, reason
        end
        state.desiredIsPlaying = true
        state.isPlaying = true
        state.lastStopReason = nil
        changed = true

    elseif action == "stop_playback" then
        if not (state.isPlaying or state.desiredIsPlaying) then
            return false, "already_stopped"
        end
        NMTransitionCommon.setStopped(state, "manual_stop")
        changed = true

    elseif action == "toggle_play" then
        local want = payload.isPlaying == true
        if want then
            local ok, reason = NMTransitionCommon.canPlay(profile, state, payload.hasTrack == true, payload)
            if not ok then
                NMTransitionCommon.setStopped(state, reason)
                return false, reason
            end
            state.desiredIsPlaying = true
            state.isPlaying = true
            state.lastStopReason = nil
            changed = true
        elseif state.isPlaying or state.desiredIsPlaying then
            NMTransitionCommon.setStopped(state, "manual_stop")
            changed = true
        end

    elseif action == "power_on" or action == "power_off" or action == "toggle_power" then
        local want = state.isOn
        if action == "power_on" then want = true
        elseif action == "power_off" then want = false
        elseif payload.isOn ~= nil then want = payload.isOn == true
        else want = not state.isOn end

        -- Power can be toggled on even without live power so UI can express On(NoPower).
        -- Actual playback viability remains enforced by canPlay()/runtime policy.
        if state.isOn ~= want or state.desiredIsOn ~= want then
            state.isOn = want
            state.desiredIsOn = want
            changed = true
        end
        if not want and (state.isPlaying or state.desiredIsPlaying) then
            NMTransitionCommon.setStopped(state, "powered_off")
            changed = true
        end

    elseif action == "set_mute" or action == "toggle_mute" then
        local want = state.isMuted == true
        if action == "set_mute" then want = payload.isMuted == true
        elseif payload.isMuted ~= nil then want = payload.isMuted == true
        else want = not want end
        local reason = want and tostring(payload.muteReason or "manual") or nil
        if state.isMuted ~= want or state.muteReason ~= reason then
            state.isMuted = want
            state.muteReason = reason
            changed = true
        end

    elseif action == "set_volume" then
        local vol = NMCore.clamp(tonumber(payload.volume) or 1.0, 0.0, 1.0)
        if state.volume ~= vol then state.volume = vol; changed = true end

    elseif action == "next_track" or action == "prev_track" then
        local count = tonumber(payload.trackCount) or 0
        if count < 1 then return false, "no_track" end
        local idx = tonumber(state.trackIndex) or 1
        idx = action == "next_track" and (idx + 1) or (idx - 1)
        if idx > count then idx = 1 end
        if idx < 1 then idx = count end
        if idx ~= state.trackIndex then state.trackIndex = idx; changed = true end

    elseif action == "set_playback_mode" then
        local mode = tostring(payload.playbackMode or "")
        if mode ~= "inventory" and mode ~= "world" then return false, "invalid_mode" end
        if mode == "world" and not NMDeviceProfiles.canAnyWorldPlayback(profile) then return false, "mode_blocked" end
        if mode == "inventory" and not (NMDeviceProfiles.canInventoryPlayback(profile) or profile.attachedPlaybackMode == "personal") then
            return false, "mode_blocked"
        end
        if state.playbackMode ~= mode then state.playbackMode = mode; changed = true end

    elseif action == "set_playback_policy" then
        local policy = tostring(payload.playbackPolicy or "")
        if policy ~= "autoplay" and policy ~= "loop_album" and policy ~= "loop_song" then return false, "invalid_policy" end
        if state.playbackPolicy ~= policy then state.playbackPolicy = policy; changed = true end

    elseif action == "track_finished" or action == "track_finished_world" then
        if not state.isPlaying then return false, "not_playing" end
        local count = tonumber(payload.trackCount) or 0
        if count < 1 then
            NMTransitionCommon.setStopped(state, "no_track")
            changed = true
        else
            local idx = math.max(1, math.min(tonumber(state.trackIndex) or 1, count))
            local policy = tostring(state.playbackPolicy or "autoplay")
            local observedDurationMs = tonumber(payload and payload.observedDurationMs) or 0
            if policy == "loop_song" then
                state.lastStopReason = nil
                logTrackFinishedTransition(state, "loop_song", policy, idx, idx, count, observedDurationMs)
                changed = true
            else
                local nextIdx = idx + 1
                if nextIdx > count then nextIdx = 1 end
                if policy == "loop_album" then
                    if nextIdx ~= state.trackIndex then state.trackIndex = nextIdx end
                    state.lastStopReason = nil
                    logTrackFinishedTransition(state, "track_advance", policy, idx, nextIdx, count, observedDurationMs)
                    changed = true
                else
                    if idx >= count then
                        state.trackIndex = 1
                        state.isOn = false
                        state.desiredIsOn = false
                        NMTransitionCommon.setStopped(state, "album_complete_power_off")
                        logTrackFinishedTransition(state, "album_complete_power_off", policy, idx, 1, count, observedDurationMs)
                        changed = true
                    else
                        state.trackIndex = nextIdx
                        state.lastStopReason = nil
                        logTrackFinishedTransition(state, "track_advance", policy, idx, nextIdx, count, observedDurationMs)
                        changed = true
                    end
                end
            end
        end

    else
        return false, "unknown_action"
    end

    return changed, nil
end

