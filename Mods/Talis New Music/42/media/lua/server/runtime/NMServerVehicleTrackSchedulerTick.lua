-- Server-authoritative MP vehicle track progression scheduler.
NMServerVehicleTrackSchedulerTick = NMServerVehicleTrackSchedulerTick or {}
NMServerVehicleTrackSchedulerTick._schedulerStateSig = NMServerVehicleTrackSchedulerTick._schedulerStateSig or {}
NMServerVehicleTrackSchedulerTick._dueWriteSig = NMServerVehicleTrackSchedulerTick._dueWriteSig or {}
NMServerVehicleTrackSchedulerTick._dueWriteBlockedSig = NMServerVehicleTrackSchedulerTick._dueWriteBlockedSig or {}
NMServerVehicleTrackSchedulerTick._lastAdvanceTickMs = NMServerVehicleTrackSchedulerTick._lastAdvanceTickMs or {}
NMServerVehicleTrackSchedulerTick._durationProbeSig = NMServerVehicleTrackSchedulerTick._durationProbeSig or {}
NMServerVehicleTrackSchedulerTick._dueTransitionProbeSig = NMServerVehicleTrackSchedulerTick._dueTransitionProbeSig or {}
NMServerVehicleTrackSchedulerTick._timelineRepairSig = NMServerVehicleTrackSchedulerTick._timelineRepairSig or {}
NMServerVehicleTrackSchedulerTick._unknownOpenDueBlockedSig = NMServerVehicleTrackSchedulerTick._unknownOpenDueBlockedSig or {}
NMServerVehicleTrackSchedulerTick._unknownOpenStallHeartbeatMs = NMServerVehicleTrackSchedulerTick._unknownOpenStallHeartbeatMs or {}

local function logRuntimeProbe(tag, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")) then
        return
    end
    NMCore.logChannel("progressionProbe", tostring(tag or "tag"), tostring(detail or ""))
end

local function nowRealMs()
    if getTimestampMs then
        local ms = tonumber(getTimestampMs())
        if ms then return ms end
    end
    if getTimestamp then
        local ts = tonumber(getTimestamp())
        if ts then return ts * 1000 end
    end
    return 0
end

local function resolveTrackCountFromMedia(state)
    if not state or not state.mediaFullType or not NMMusic or not NMMusic.resolveTracks then
        return 0
    end
    local ok, resolved = pcall(NMMusic.resolveTracks, state.mediaFullType)
    if not ok or type(resolved) ~= "table" or type(resolved.tracks) ~= "table" then
        return 0
    end
    return #resolved.tracks
end

local function resolveTrackCount(state, entry)
    local fromState = tonumber(state and state.trackCount) or 0
    if fromState > 0 then
        return math.max(1, math.floor(fromState))
    end
    local fromEntry = tonumber(entry and entry.trackCount) or 0
    if fromEntry > 0 then
        return math.max(1, math.floor(fromEntry))
    end
    return resolveTrackCountFromMedia(state)
end

local function resolveCurrentTrackDurationMs(state)
    local fallbackMs = tonumber(NMRuntimeConfig and NMRuntimeConfig.getServerVehicleTrackDurationMs and NMRuntimeConfig.getServerVehicleTrackDurationMs()
        or NMRuntimeConfig and NMRuntimeConfig.get and NMRuntimeConfig.get("serverVehicleTrackDurationMs", 210000)
        or 210000) or 210000
    local resolvedDuration = NMServerTrackTimeline.resolveProgressionInfo(state, "world")
    local row = resolvedDuration and resolvedDuration.row or nil

    local probeKey = table.concat({
        tostring(state and state.mediaFullType or "nil"),
        tostring(resolvedDuration and resolvedDuration.trackIndex or tonumber(state and state.trackIndex) or 1),
        tostring(row and row.durationMs or nil),
        tostring(row and row.durationSeconds or nil),
        tostring(row and row.lengthSeconds or nil),
        tostring(row and row.duration or nil),
        tostring(resolvedDuration and resolvedDuration.knownDuration == true),
        tostring(resolvedDuration and resolvedDuration.timingMode or ""),
        tostring(resolvedDuration and resolvedDuration.source or "fallback")
    }, "|")
    if tostring(NMServerVehicleTrackSchedulerTick._durationProbeSig[probeKey] or "") ~= probeKey then
        NMServerVehicleTrackSchedulerTick._durationProbeSig[probeKey] = probeKey
        logRuntimeProbe(
            "server_track_duration_probe",
            string.format(
                "media=%s idx=%s durationMs=%s durationSeconds=%s lengthSeconds=%s duration=%s fallbackMs=%s known=%s timingMode=%s source=%s resolvedMs=%s",
                tostring(state and state.mediaFullType or "nil"),
                tostring(resolvedDuration and resolvedDuration.trackIndex or tonumber(state and state.trackIndex) or 1),
                tostring(row and row.durationMs or nil),
                tostring(row and row.durationSeconds or nil),
                tostring(row and row.lengthSeconds or nil),
                tostring(row and row.duration or nil),
                tostring(math.max(1000, math.floor(fallbackMs + 0.5))),
                tostring(resolvedDuration and resolvedDuration.knownDuration == true),
                tostring(resolvedDuration and resolvedDuration.timingMode or ""),
                tostring(resolvedDuration and resolvedDuration.source or "fallback"),
                tostring(resolvedDuration and resolvedDuration.durationMs or nil)
            )
        )
    end
    return resolvedDuration and resolvedDuration.durationMs or math.max(1000, math.floor(fallbackMs + 0.5))
end

local function resolveCurrentTrackProgressionInfo(state)
    return NMServerTrackTimeline.resolveProgressionInfo(state, "world")
end

local function recipients(applyFn)
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then
        return
    end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p then
            applyFn(p)
        end
    end
end

local function resolveProgressionCause(progression)
    local timingMode = tostring(progression and progression.timingMode or "")
    local source = tostring(progression and progression.source or "")
    if timingMode == "unknown_open" then
        return "unknown_open"
    end
    if source == "observed_hint" then
        return "observed_hint_due"
    end
    return "metadata_due"
end

local function shouldEmitStateSync(entry, playerObj, state)
    return NMServerSchedulerSyncState.shouldEmitStateSync(entry, playerObj, state)
end

local function syncVehicleStateToClients(entry, state)
    if not (entry and state and sendServerCommand) then
        return
    end
    local sessionToken = NMServerBootReset and NMServerBootReset.getSessionToken and NMServerBootReset.getSessionToken() or nil
    local canonicalSourceGen = math.max(
        tonumber(entry and entry.sourceEpoch) or 0,
        tonumber(entry and entry.sourceGeneration) or 0,
        tonumber(state and state.sourceGeneration) or 0
    )
    recipients(function(playerObj)
        if not shouldEmitStateSync(entry, playerObj, state) then
            return
        end
        sendServerCommand(playerObj, NMCore.NetModule, "state", {
            vehicleId = tostring(entry.vehicleId or ""),
            vehicleIdHint = tostring(entry.vehicleIdHint or entry.vehicleId or ""),
            vehicleSqlId = tostring(entry.vehicleSqlId or ""),
            vehicleSqlIdHint = tostring(entry.vehicleSqlIdHint or entry.vehicleSqlId or ""),
            partId = tostring(entry.partId or "Radio"),
            ownerId = tostring(entry.ownerId or ""),
            sourceMode = tostring(entry.sourceMode or "vehicle"),
            state = NMDeviceState.export(state),
            sourceGeneration = canonicalSourceGen,
            transitionReason = entry.transitionReason ~= nil and tostring(entry.transitionReason) or nil,
            serverSessionToken = sessionToken
        })
    end)
end

local function syncItemStateToClients(entry, state)
    if not (entry and state and sendServerCommand) then
        return
    end
    local sessionToken = NMServerBootReset and NMServerBootReset.getSessionToken and NMServerBootReset.getSessionToken() or nil
    recipients(function(playerObj)
        if not shouldEmitStateSync(entry, playerObj, state) then
            return
        end
        sendServerCommand(playerObj, NMCore.NetModule, "state", {
            itemId = tostring(entry.itemId or ""),
            uuid = tostring(entry.uuid or ""),
            itemFullType = tostring(entry.itemFullType or ""),
            sourceMode = tostring(entry.sourceMode or "placed"),
            state = NMDeviceState.export(state),
            sourceGeneration = math.max(
                tonumber(entry.sourceEpoch) or 0,
                tonumber(entry.sourceGeneration) or 0,
                tonumber(state.sourceGeneration) or 0
            ),
            transitionReason = entry.transitionReason ~= nil and tostring(entry.transitionReason) or nil,
            serverSessionToken = sessionToken
        })
    end)
end

local function isWorldAuthoritativeEntry(entry, state)
    if type(entry) ~= "table" or type(state) ~= "table" then
        return false
    end
    if state.isOn ~= true or state.isPlaying ~= true then
        return false
    end
    local mode = tostring(state.authoritativeMode or "")
    if tostring(entry.kind or "") == "vehicle" then
        return mode == "vehicle"
    end
    if tostring(entry.kind or "") == "item" then
        return mode == "placed" or mode == "stowed" or mode == "attached"
    end
    return false
end

local function resolveProfileForEntry(entry)
    if tostring(entry and entry.kind or "") == "vehicle" then
        return NMDeviceProfiles and (
            (NMDeviceProfiles.getForFullType and NMDeviceProfiles.getForFullType("vehicle_radio"))
            or NMDeviceProfiles.VehicleRadioProfile
        ) or nil
    end
    local fullType = tostring(entry and (entry.profileType or entry.itemFullType) or "")
    if fullType ~= "" and NMDeviceProfiles and NMDeviceProfiles.getForFullType then
        return NMDeviceProfiles.getForFullType(fullType)
    end
    return nil
end

local function isOwnerOnlineForAttached(entry, state)
    if tostring(entry and entry.kind or "") ~= "item" then
        return true
    end
    if tostring(state and state.authoritativeMode or entry and entry.sourceMode or "") ~= "attached" then
        return true
    end
    local owner = tostring(state and state.sourceOwner or entry and entry.ownerOnlineId or entry and entry.ownerUsername or entry and entry.ownerId or "")
    if owner == "" then
        return false
    end
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then
        return false
    end
    local ownerLower = string.lower(owner)
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p then
            local onlineId = p.getOnlineID and tostring(p:getOnlineID() or "") or ""
            local username = p.getUsername and tostring(p:getUsername() or "") or ""
            if owner == onlineId or owner == username or ownerLower == string.lower(username) then
                return true
            end
        end
    end
    return false
end

local logDueWrite
local clearServerTrackTimeline

local function bumpAndSyncAuthoritativeState(entry, state)
    NMDeviceState.bumpRevision(state)
    local nextGen = math.max(
        tonumber(state.sourceGeneration) or 0,
        tonumber(entry.sourceEpoch) or 0,
        tonumber(entry.sourceGeneration) or 0
    ) + 1
    state.sourceGeneration = nextGen
    entry.sourceEpoch = nextGen
    entry.sourceGeneration = nextGen
    entry.stateSnapshot = NMDeviceState.export(state)
    NMServerRegistryBroadcast.broadcastEntry(
        NMServerRegistryState.worldRegistry,
        tostring(entry.uuid),
        nil,
        entry.stateSnapshot,
        "upsert",
        recipients
    )
    if tostring(entry.kind or "") == "vehicle" then
        syncVehicleStateToClients(entry, state)
    else
        syncItemStateToClients(entry, state)
    end
end

local function applyRestartResume(entry, state, nowMsValue, durationMs, dueReason)
    local newStartedAtMs = tonumber(state.serverTrackStartedAtMs) or nowMsValue
    entry.serverTrackStartedAtMs = newStartedAtMs
    entry.serverTrackDurationMs = nil
    entry.serverTrackDueAtMs = nil
    entry._serverTrackNextTransitionAtMs = nil
    logDueWrite(entry, state, dueReason, nil, nil, newStartedAtMs, nil)
    if NMServerItemPowerTick and NMServerItemPowerTick.lastDrainMs then
        NMServerItemPowerTick.lastDrainMs[tostring(entry.uuid or "")] = nowMsValue
    end
    bumpAndSyncAuthoritativeState(entry, state)
    return 0
end

local function handleAttachedOwnerPresence(entry, state, nowMsValue)
    if tostring(entry and entry.kind or "") ~= "item" then
        return false
    end
    if tostring(state and state.authoritativeMode or entry and entry.sourceMode or "") ~= "attached" then
        entry._attachedOwnerPaused = false
        entry._attachedOwnerPausedResume = false
        entry._offlineRestartPending = nil
        entry._offlineRestartToken = nil
        entry._offlineRestartResumeSig = nil
        return false
    end

    local ownerOnline = isOwnerOnlineForAttached(entry, state)
    if not ownerOnline then
        if entry._attachedOwnerPaused ~= true then
            local durationMs = math.max(1000, resolveCurrentTrackDurationMs(state))
            entry._attachedOwnerPaused = true
            entry._attachedOwnerPausedResume = (state.isOn == true and state.isPlaying == true)
            entry._offlineRestartPending = entry._attachedOwnerPausedResume == true
            entry._offlineRestartToken = string.format(
                "%s:%s",
                tostring(tonumber(state.playbackEpoch) or 0),
                tostring(tonumber(state.trackIndex) or 0)
            )
            if entry._attachedOwnerPausedResume == true then
                local changed = NMServerCanonicalReducer
                    and NMServerCanonicalReducer.dispatch
                    and NMServerCanonicalReducer.dispatch({
                        eventType = NMServerCanonicalReducer.Event and NMServerCanonicalReducer.Event.OWNER_OFFLINE_PAUSE or "OWNER_OFFLINE_PAUSE",
                        state = state
                    }) == true
                if changed then
                    clearServerTrackTimeline(entry, state)
                    entry._batteryDrainSkipUntilResume = true
                    if NMServerItemPowerTick and NMServerItemPowerTick.lastDrainMs then
                        NMServerItemPowerTick.lastDrainMs[tostring(entry.uuid or "")] = nowMsValue
                    end
                    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                        NMCore.logChannel(
                            "runtimeProbe",
                            "attached_offline_pause_applied",
                            string.format(
                                "uuid=%s restartPending=true durationMs=%s playbackEpoch=%s trackIndex=%s",
                                tostring(entry.uuid or ""),
                                tostring(math.floor(durationMs)),
                                tostring(tonumber(state.playbackEpoch) or 0),
                                tostring(tonumber(state.trackIndex) or 0)
                            )
                        )
                    end
                    bumpAndSyncAuthoritativeState(entry, state)
                end
            end
        end
        return true
    end

    if entry._attachedOwnerPaused == true then
        local hasBattery = state.batteryPresent ~= true or (tonumber(state.batteryCharge) or 0) > 0
        local shouldResume = entry._offlineRestartPending == true and state.isOn == true and hasBattery
        if shouldResume then
            local durationMs = math.max(1000, resolveCurrentTrackDurationMs(state))
            local resumeSig = string.format(
                "%s|%s|%s",
                tostring(entry._offlineRestartToken or ""),
                tostring(tonumber(state.sourceGeneration) or 0),
                tostring(tonumber(state.revision) or 0)
            )
            if tostring(entry._offlineRestartResumeSig or "") == resumeSig then
                entry._attachedOwnerPaused = false
                entry._attachedOwnerPausedResume = false
                entry._offlineRestartPending = nil
                entry._offlineRestartToken = nil
                entry._batteryDrainSkipUntilResume = nil
                return false
            end
            local changed = NMServerCanonicalReducer
                and NMServerCanonicalReducer.dispatch
                and NMServerCanonicalReducer.dispatch({
                    eventType = NMServerCanonicalReducer.Event and NMServerCanonicalReducer.Event.OWNER_ONLINE_RESUME or "OWNER_ONLINE_RESUME",
                    state = state,
                    nowMs = nowMsValue,
                    durationMs = durationMs
                }) == true
            if changed then
                entry._batteryDrainSkipUntilResume = nil
                local newDueAtMs = applyRestartResume(entry, state, nowMsValue, durationMs, "restart_attached_owner_online")
                if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                    NMCore.logChannel(
                        "runtimeProbe",
                        "attached_offline_resume_applied",
                        string.format(
                            "uuid=%s restart=true durationMs=%s dueAtMs=%s playbackEpoch=%s trackIndex=%s",
                            tostring(entry.uuid or ""),
                            tostring(math.floor(durationMs)),
                            tostring(math.floor(newDueAtMs)),
                            tostring(tonumber(state.playbackEpoch) or 0),
                            tostring(tonumber(state.trackIndex) or 0)
                        )
                    )
                end
                entry._offlineRestartResumeSig = resumeSig
            end
        end
        entry._attachedOwnerPaused = false
        entry._attachedOwnerPausedResume = false
        entry._offlineRestartPending = nil
        entry._offlineRestartToken = nil
        entry._batteryDrainSkipUntilResume = nil
    end
    return false
end

local function handleNoListenerPresence(entry, state, nowMsValue)
    if type(entry) ~= "table" or type(state) ~= "table" then
        return false
    end
    if state.isOn ~= true then
        entry._noListenerFreezeActive = nil
        entry._noListenerRestartPending = nil
        entry._noListenerFreezeToken = nil
        entry._noListenerResumeSig = nil
        entry._noListenerMissingSinceMs = nil
        entry._noListenerPresentSinceMs = nil
        return false
    end
    local mode = tostring(state.authoritativeMode or entry.sourceMode or "")
    if mode == "off" or mode == "inventory" or mode == "attached" then
        entry._noListenerFreezeActive = nil
        entry._noListenerRestartPending = nil
        entry._noListenerFreezeToken = nil
        entry._noListenerResumeSig = nil
        entry._noListenerMissingSinceMs = nil
        entry._noListenerPresentSinceMs = nil
        return false
    end

    local profile = resolveProfileForEntry(entry)
    local eval = NMServerListenerEligibility and NMServerListenerEligibility.evaluate and NMServerListenerEligibility.evaluate(entry, state, profile) or nil
    local hasEligibleListener = eval and eval.hasEligibleListener == true
    local freezeDebounceMs = tonumber(NMRuntimeConfig and NMRuntimeConfig.getNoListenerFreezeDebounceMs and NMRuntimeConfig.getNoListenerFreezeDebounceMs() or 3000) or 3000
    local resumeDebounceMs = tonumber(NMRuntimeConfig and NMRuntimeConfig.getNoListenerResumeDebounceMs and NMRuntimeConfig.getNoListenerResumeDebounceMs() or 1000) or 1000

    if not hasEligibleListener then
        entry._noListenerPresentSinceMs = nil
        if tonumber(entry._noListenerMissingSinceMs) == nil then
            entry._noListenerMissingSinceMs = nowMsValue
        end
        if (nowMsValue - (tonumber(entry._noListenerMissingSinceMs) or nowMsValue)) < math.max(0, freezeDebounceMs) then
            return false
        end
        if entry._noListenerFreezeActive ~= true then
            entry._noListenerFreezeActive = true
            entry._noListenerRestartPending = (state.isPlaying == true)
            entry._noListenerFreezeToken = string.format("%s:%s", tostring(tonumber(state.playbackEpoch) or 0), tostring(tonumber(state.trackIndex) or 0))
            if state.isPlaying == true then
                local changed = NMServerCanonicalReducer
                    and NMServerCanonicalReducer.dispatch
                    and NMServerCanonicalReducer.dispatch({
                        eventType = NMServerCanonicalReducer.Event and NMServerCanonicalReducer.Event.NO_LISTENER_FREEZE or "NO_LISTENER_FREEZE",
                        state = state
                    }) == true
                if changed then
                    clearServerTrackTimeline(entry, state)
                    entry._batteryDrainSkipNoListener = true
                    if NMServerItemPowerTick and NMServerItemPowerTick.lastDrainMs then
                        NMServerItemPowerTick.lastDrainMs[tostring(entry.uuid or "")] = nowMsValue
                    end
                    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                        NMCore.logChannel(
                            "runtimeProbe",
                            "no_listener_freeze_applied",
                            string.format(
                                "uuid=%s mode=%s playbackEpoch=%s trackIndex=%s",
                                tostring(entry.uuid or ""),
                                tostring(mode),
                                tostring(tonumber(state.playbackEpoch) or 0),
                                tostring(tonumber(state.trackIndex) or 0)
                            )
                        )
                    end
                    bumpAndSyncAuthoritativeState(entry, state)
                end
            else
                entry._batteryDrainSkipNoListener = true
            end
        end
        return true
    end

    entry._noListenerMissingSinceMs = nil
    if tonumber(entry._noListenerPresentSinceMs) == nil then
        entry._noListenerPresentSinceMs = nowMsValue
    end
    if entry._noListenerFreezeActive == true then
        if (nowMsValue - (tonumber(entry._noListenerPresentSinceMs) or nowMsValue)) < math.max(0, resumeDebounceMs) then
            return true
        end
        local hasBattery = state.batteryPresent ~= true or (tonumber(state.batteryCharge) or 0) > 0
        local shouldResume = entry._noListenerRestartPending == true and state.isOn == true and hasBattery
        if shouldResume then
            local durationMs = math.max(1000, resolveCurrentTrackDurationMs(state))
            local resumeSig = string.format(
                "%s|%s|%s",
                tostring(entry._noListenerFreezeToken or ""),
                tostring(tonumber(state.sourceGeneration) or 0),
                tostring(tonumber(state.revision) or 0)
            )
            if tostring(entry._noListenerResumeSig or "") ~= resumeSig then
                local changed = NMServerCanonicalReducer
                    and NMServerCanonicalReducer.dispatch
                    and NMServerCanonicalReducer.dispatch({
                        eventType = NMServerCanonicalReducer.Event and NMServerCanonicalReducer.Event.NO_LISTENER_RESUME_RESTART or "NO_LISTENER_RESUME_RESTART",
                        state = state,
                        nowMs = nowMsValue,
                        durationMs = durationMs
                    }) == true
                if changed then
                    entry._batteryDrainSkipNoListener = nil
                    local newDueAtMs = applyRestartResume(entry, state, nowMsValue, durationMs, "restart_no_listener_resume")
                    entry._noListenerResumeSig = resumeSig
                    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                        NMCore.logChannel(
                            "runtimeProbe",
                            "no_listener_resume_restart_applied",
                            string.format(
                                "uuid=%s mode=%s durationMs=%s dueAtMs=%s playbackEpoch=%s trackIndex=%s",
                                tostring(entry.uuid or ""),
                                tostring(mode),
                                tostring(math.floor(durationMs)),
                                tostring(math.floor(newDueAtMs)),
                                tostring(tonumber(state.playbackEpoch) or 0),
                                tostring(tonumber(state.trackIndex) or 0)
                            )
                        )
                    end
                end
            end
        end
        entry._noListenerFreezeActive = nil
        entry._noListenerRestartPending = nil
        entry._noListenerFreezeToken = nil
        entry._batteryDrainSkipNoListener = nil
        entry._noListenerPresentSinceMs = nil
        return false
    end

    return false
end

logDueWrite = function(entry, state, reason, oldDueMs, dueMs, startMs, durationMs)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")) then
        return
    end
    local uuid = tostring(entry and entry.uuid or "")
    local sig = table.concat({
        tostring(reason or "unknown"),
        tostring(math.floor(tonumber(oldDueMs) or -1)),
        tostring(math.floor(tonumber(dueMs) or -1)),
        tostring(math.floor(tonumber(startMs) or -1)),
        tostring(math.floor(tonumber(durationMs) or -1)),
        tostring(tonumber(state and state.playbackEpoch) or 0),
        tostring(tonumber(state and state.trackIndex) or 0)
    }, "|")
    local key = uuid ~= "" and uuid or tostring(entry)
    if tostring(NMServerVehicleTrackSchedulerTick._dueWriteSig[key] or "") == sig then
        return
    end
    NMServerVehicleTrackSchedulerTick._dueWriteSig[key] = sig
    NMCore.logChannel(
        "progressionProbe",
        "server_track_due_write",
        string.format(
            "uuid=%s reason=%s oldDueAtMs=%s newDueAtMs=%s startAtMs=%s durationMs=%s playbackEpoch=%s trackIndex=%s",
            tostring(uuid),
            tostring(reason or "unknown"),
            tostring(oldDueMs and math.floor(oldDueMs) or "nil"),
            tostring(dueMs and math.floor(dueMs) or "nil"),
            tostring(startMs and math.floor(startMs) or "nil"),
            tostring(durationMs and math.floor(durationMs) or "nil"),
            tostring(tonumber(state and state.playbackEpoch) or 0),
            tostring(tonumber(state and state.trackIndex) or 0)
        )
    )
end

local function canWriteDue(reason)
    return reason == "start_playback" or reason == "advance_success"
end

local function setServerTrackTimeline(entry, state, startedAtMs, durationMs, reason)
    local prior = NMServerTrackTimeline.read(entry, state)
    local oldDueMs = tonumber(prior and prior.dueAtMs)
    if not canWriteDue(reason) then
        local key = tostring(entry and entry.uuid or tostring(entry))
        local blockedSig = table.concat({
            tostring(reason or "unknown"),
            tostring(math.floor(tonumber(oldDueMs) or -1)),
            tostring(tonumber(state and state.playbackEpoch) or 0),
            tostring(tonumber(state and state.trackIndex) or 0)
        }, "|")
        if tostring(NMServerVehicleTrackSchedulerTick._dueWriteBlockedSig[key] or "") ~= blockedSig then
            NMServerVehicleTrackSchedulerTick._dueWriteBlockedSig[key] = blockedSig
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe") then
                NMCore.logChannel(
                    "progressionProbe",
                    "deadline_write_forbidden",
                    string.format(
                        "uuid=%s reason=%s oldDueAtMs=%s playbackEpoch=%s trackIndex=%s",
                        tostring(entry and entry.uuid or ""),
                        tostring(reason or "unknown"),
                        tostring(oldDueMs and math.floor(oldDueMs) or "nil"),
                        tostring(tonumber(state and state.playbackEpoch) or 0),
                        tostring(tonumber(state and state.trackIndex) or 0)
                    )
                )
            end
        end
        return oldDueMs or 0
    end
    local arm = NMServerTrackTimeline.armForReason(entry, state, startedAtMs, tostring(entry and entry.kind or "world"), reason)
    if not arm then
        return oldDueMs or 0
    end
    local dueMs = tonumber(arm and arm.dueAtMs) or 0
    local startMs = tonumber(arm and arm.startedAtMs) or math.max(0, math.floor(tonumber(startedAtMs) or 0))
    local durMs = tonumber(arm and arm.durationMs) or math.max(1000, math.floor(tonumber(durationMs) or 0))
    local timingMode = tostring(arm and arm.timingMode or "")
    local armToken = tostring(arm and arm.armToken or "")
    if tostring(arm and arm.status or "") == "skipped_duplicate" then
        logRuntimeProbe(
            "progression_arm_skipped_duplicate",
            string.format(
                "uuid=%s reason=%s token=%s dueAtMs=%s playbackEpoch=%s trackIndex=%s",
                tostring(entry and entry.uuid or ""),
                tostring(reason or "unknown"),
                tostring(armToken),
                tostring(dueMs and math.floor(dueMs) or 0),
                tostring(tonumber(state and state.playbackEpoch) or 0),
                tostring(tonumber(state and state.trackIndex) or 0)
            )
        )
        return dueMs
    end
    logRuntimeProbe(
        "progression_arm_applied",
        string.format(
            "uuid=%s reason=%s token=%s dueAtMs=%s playbackEpoch=%s trackIndex=%s",
            tostring(entry and entry.uuid or ""),
            tostring(reason or "unknown"),
            tostring(armToken),
            tostring(dueMs and math.floor(dueMs) or 0),
            tostring(tonumber(state and state.playbackEpoch) or 0),
            tostring(tonumber(state and state.trackIndex) or 0)
        )
    )
    logDueWrite(entry, state, reason or "set_timeline", oldDueMs, dueMs, startMs, durMs)
    if timingMode == "unknown_open" then
        logRuntimeProbe(
            "unknown_open_timing_armed",
            string.format(
                "uuid=%s reason=%s token=%s startedAtMs=%s dueAtMs=nil",
                tostring(entry and entry.uuid or ""),
                tostring(reason or "unknown"),
                tostring(armToken),
                tostring(math.floor(startMs))
            )
        )
    end
    return dueMs
end

clearServerTrackTimeline = function(entry, state)
    local prior = NMServerTrackTimeline.read(entry, state)
    local oldDueMs = tonumber(prior and prior.dueAtMs)
    NMServerTrackTimeline.clear(entry, state)
    if oldDueMs and oldDueMs > 0 then
        logDueWrite(entry, state, "clear_timeline", oldDueMs, nil, nil, nil)
    end
end

local function shouldLogStalled(entry, state, nowMsValue)
    local signature = table.concat({
        tostring(tonumber(state and state.playbackEpoch) or 0),
        tostring(tonumber(state and state.trackIndex) or 1),
        tostring(tonumber(state and state.trackCount) or tonumber(entry and entry.trackCount) or 0),
        tostring(state and state.playbackPolicy or entry and entry.playbackPolicy or "autoplay"),
        tostring(state and state.mediaFullType or "nil")
    }, "|")
    local lastSig = tostring(entry._serverTrackStalledSig or "")
    local lastMs = tonumber(entry._serverTrackStalledMs) or 0
    if lastSig == signature and (nowMsValue - lastMs) < 10000 then
        return false
    end
    entry._serverTrackStalledSig = signature
    entry._serverTrackStalledMs = nowMsValue
    return true
end

local function ensureTimelineInvariant(entry, state, nowMsValue)
    if not (state and state.isOn == true and state.isPlaying == true) then
        return 0, false
    end
    local valid, timeline = NMServerTrackTimeline.isValid(entry, state)
    if valid then
        return timeline and timeline.dueAtMs or 0, false
    end
    local progression = resolveCurrentTrackProgressionInfo(state)
    local repairedDueAtMs = setServerTrackTimeline(entry, state, nowMsValue, resolveCurrentTrackDurationMs(state), "start_playback")
    local sigKey = tostring(entry and entry.uuid or "")
    local sig = table.concat({
        tostring(state and state.playbackEpoch or 0),
        tostring(state and state.trackIndex or 0),
        tostring(timeline and timeline.startedAtMs or 0),
        tostring(timeline and timeline.durationMs or 0),
        tostring(timeline and timeline.dueAtMs or 0)
    }, "|")
    if sigKey ~= "" and tostring(NMServerVehicleTrackSchedulerTick._timelineRepairSig[sigKey] or "") ~= sig then
        NMServerVehicleTrackSchedulerTick._timelineRepairSig[sigKey] = sig
        logRuntimeProbe(
            "playing_without_timeline_repaired",
            string.format(
                "uuid=%s reason=missing_or_invalid_timeline context=%s cause=%s oldStart=%s oldDuration=%s oldDue=%s newDue=%s",
                tostring(sigKey),
                tostring(entry and entry.kind or "world"),
                tostring(resolveProgressionCause(progression)),
                tostring(timeline and timeline.startedAtMs or 0),
                tostring(timeline and timeline.durationMs or 0),
                tostring(timeline and timeline.dueAtMs or 0),
                tostring(repairedDueAtMs and math.floor(repairedDueAtMs) or 0)
            )
        )
    end
    return repairedDueAtMs, true
end

function NMServerVehicleTrackSchedulerTick.onTick()
    if not (NMCore and NMCore.isMPServerAuthority and NMCore.isMPServerAuthority()) then
        return
    end

    local nowMsValue = nowRealMs()
    for uuid, entry in pairs(NMServerRegistryState.worldRegistry) do
        if entry then
            local state = entry.stateSnapshot
            if type(state) == "table" then
                local blockedForAttachedOffline = handleAttachedOwnerPresence(entry, state, nowMsValue)
                if blockedForAttachedOffline then
                    NMServerRegistryState.worldRegistry[uuid] = entry
                    state = entry.stateSnapshot
                end
                local blockedForNoListener = NMServerNoListenerPolicy.handleNoListenerPresence(entry, state, nowMsValue, {
                    resolveProfileForEntry = resolveProfileForEntry,
                    resolveCurrentTrackDurationMs = resolveCurrentTrackDurationMs,
                    clearServerTrackTimeline = clearServerTrackTimeline,
                    applyRestartResume = applyRestartResume,
                    bumpAndSyncAuthoritativeState = bumpAndSyncAuthoritativeState
                })
                if blockedForNoListener then
                    NMServerRegistryState.worldRegistry[uuid] = entry
                    state = entry.stateSnapshot
                end
            end
            if isWorldAuthoritativeEntry(entry, state) then
                if (tonumber(state.trackCount) or 0) < 1 and (tonumber(entry.trackCount) or 0) > 0 then
                    state.trackCount = tonumber(entry.trackCount) or 0
                end
                local epoch = tonumber(state and state.playbackEpoch) or 0
                local trackIndex = tonumber(state and state.trackIndex) or 1
                entry._serverTrackSchedulerSig = tostring(epoch) .. ":" .. tostring(trackIndex)
                local isVehicle = tostring(entry.kind or "") == "vehicle"
                local unresolved = isVehicle and ((entry._vehicleResolved == false) or (entry._vehicleSourceResolved == false)) or false
                local dueAtMs = ensureTimelineInvariant(entry, state, nowMsValue)
                local progressionCurrent = resolveCurrentTrackProgressionInfo(state)
                local timingMode = tostring(progressionCurrent and progressionCurrent.timingMode or "known_due")
                local schedulerSig = string.format(
                    "active=true|unresolved=%s|isPlaying=%s|timing=%s|nextAt=%s",
                    tostring(unresolved),
                    tostring(state.isPlaying == true),
                    tostring(timingMode),
                    tostring(math.floor(dueAtMs))
                )
                if tostring(NMServerVehicleTrackSchedulerTick._schedulerStateSig[uuid] or "") ~= schedulerSig then
                    NMServerVehicleTrackSchedulerTick._schedulerStateSig[uuid] = schedulerSig
                    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe") then
                        NMCore.logChannel(
                            "progressionProbe",
                            "server_track_scheduler_state",
                            string.format(
                                "uuid=%s unresolved=%s isPlaying=%s nextAtMs=%s",
                                tostring(uuid),
                                tostring(unresolved),
                                tostring(state.isPlaying == true),
                                tostring(math.floor(dueAtMs))
                            )
                        )
                    end
                end
                if timingMode == "unknown_open" then
                    NMServerUnknownOpenPolicy.handleUnknownOpenState(
                        entry,
                        state,
                        dueAtMs,
                        progressionCurrent,
                        nowMsValue,
                        {
                            blockedSigStore = NMServerVehicleTrackSchedulerTick._unknownOpenDueBlockedSig,
                            heartbeatStore = NMServerVehicleTrackSchedulerTick._unknownOpenStallHeartbeatMs
                        },
                        logRuntimeProbe
                    )
                elseif dueAtMs > 0 and nowMsValue >= dueAtMs then
                    local advanceKey = tostring(uuid)
                    local lastAdvanceMs = tonumber(NMServerVehicleTrackSchedulerTick._lastAdvanceTickMs[advanceKey]) or 0
                    if lastAdvanceMs ~= nowMsValue then
                        local trackCount = resolveTrackCount(state, entry)
                        local beforeTrackIndex = tonumber(state and state.trackIndex) or 1
                        local beforePolicy = tostring(state and state.playbackPolicy or entry and entry.playbackPolicy or "autoplay")
                        local profile = resolveProfileForEntry(entry)
                        local progressionBefore = resolveCurrentTrackProgressionInfo(state)
                        local progressionCause = resolveProgressionCause(progressionBefore)
                        local changedByApply = false
                        local applyReason = "profile_missing"
                        if profile then
                            changedByApply, applyReason = NMServerCanonicalReducer.dispatch({
                                eventType = NMServerCanonicalReducer.Event.HINT_TRACK_FINISHED,
                                profile = profile,
                                state = state,
                                intentPayload = {
                                    playbackMode = "world",
                                    trackCount = trackCount,
                                    hasTrack = trackCount > 0
                                }
                            })
                            changedByApply = changedByApply == true
                        end
                        local afterTrackIndex = tonumber(state and state.trackIndex) or 1
                        local dueSig = table.concat({
                            tostring(uuid),
                            tostring(math.floor(dueAtMs)),
                            tostring(math.floor(nowMsValue)),
                            tostring(beforeTrackIndex),
                            tostring(afterTrackIndex),
                            tostring(changedByApply),
                            tostring(applyReason or "none")
                        }, "|")
                        if tostring(NMServerVehicleTrackSchedulerTick._dueTransitionProbeSig[tostring(uuid)] or "") ~= dueSig then
                            NMServerVehicleTrackSchedulerTick._dueTransitionProbeSig[tostring(uuid)] = dueSig
                            logRuntimeProbe(
                                "server_track_due_transition",
                                string.format(
                                    "uuid=%s dueAtMs=%s nowMs=%s changed=%s reason=%s cause=%s profile=%s policy=%s trackIndex=%s->%s trackCount=%s",
                                    tostring(uuid),
                                    tostring(math.floor(dueAtMs)),
                                    tostring(math.floor(nowMsValue)),
                                    tostring(changedByApply),
                                    tostring(applyReason or "none"),
                                    tostring(progressionCause),
                                    tostring(profile and profile.deviceType or "nil"),
                                    tostring(beforePolicy),
                                    tostring(beforeTrackIndex),
                                    tostring(afterTrackIndex),
                                    tostring(trackCount)
                                )
                            )
                        end

                        if changedByApply then
                            NMDeviceState.bumpPlaybackEpoch(state)
                            NMDeviceState.bumpRevision(state)
                            local canonicalGen = math.max(
                                tonumber(state.sourceGeneration) or 0,
                                tonumber(entry.sourceEpoch) or 0,
                                tonumber(entry.sourceGeneration) or 0
                            ) + 1
                            state.sourceGeneration = canonicalGen
                            entry.sourceEpoch = canonicalGen
                            entry.sourceGeneration = canonicalGen
                            entry.playbackEpoch = tonumber(state.playbackEpoch) or 0
                            entry.trackIndex = tonumber(state.trackIndex) or 1
                            entry.trackCount = math.max(trackCount, tonumber(state.trackCount) or 0)
                            state.trackCount = entry.trackCount
                            entry.playbackPolicy = tostring(state.playbackPolicy or "autoplay")
                            if changedByApply then
                                entry.transitionReason = (state.isPlaying == true)
                                    and "server_track_advance_apply"
                                    or tostring(state.lastStopReason or "album_complete_power_off")
                            end

                            local progressionAfter = nil
                            if state.isPlaying == true then
                                setServerTrackTimeline(entry, state, nowMsValue, resolveCurrentTrackDurationMs(state), "advance_success")
                                progressionAfter = resolveCurrentTrackProgressionInfo(state)
                            else
                                entry._serverTrackSchedulerSig = nil
                                clearServerTrackTimeline(entry, state)
                            end
                            entry.stateSnapshot = NMDeviceState.export(state)
                            NMServerVehicleTrackSchedulerTick._lastAdvanceTickMs[advanceKey] = nowMsValue

                            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe") then
                                NMCore.logChannel(
                                    "progressionProbe",
                                    "server_track_advance_apply",
                                    string.format(
                                        "uuid=%s kind=%s reason=%s cause=%s known=%s source=%s durationMs=%s trackIndex=%s trackCount=%s sourceGen=%s playbackEpoch=%s",
                                        tostring(uuid),
                                        tostring(entry.kind or "unknown"),
                                        tostring(entry.transitionReason or "server_track_advance"),
                                        tostring(progressionCause),
                                        tostring(progressionAfter and progressionAfter.knownDuration == true),
                                        tostring(progressionAfter and progressionAfter.source or "fallback"),
                                        tostring(progressionAfter and progressionAfter.durationMs or "nil"),
                                        tostring(entry.trackIndex or 1),
                                        tostring(entry.trackCount or 0),
                                        tostring(entry.sourceEpoch or 0),
                                        tostring(entry.playbackEpoch or 0)
                                    )
                                )
                            end

                            NMServerRegistryBroadcast.broadcastEntry(
                                NMServerRegistryState.worldRegistry,
                                tostring(uuid),
                                nil,
                                entry.stateSnapshot,
                                "upsert",
                                recipients
                            )
                            if isVehicle then
                                syncVehicleStateToClients(entry, state)
                            else
                                syncItemStateToClients(entry, state)
                            end
                        else
                            if shouldLogStalled(entry, state, nowMsValue)
                                and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe") then
                                NMCore.logChannel(
                                    "progressionProbe",
                                    "server_track_advance_stalled",
                                    string.format(
                                        "uuid=%s reason=%s profile=%s trackCount=%s policy=%s media=%s resolvedState=%s sourceGen=%s playbackEpoch=%s",
                                        tostring(uuid),
                                        tostring(applyReason or "none"),
                                        tostring(profile and profile.deviceType or "nil"),
                                        tostring(trackCount),
                                        tostring(state and state.playbackPolicy or entry and entry.playbackPolicy or "autoplay"),
                                        tostring(state and state.mediaFullType or "nil"),
                                        tostring(isVehicle and (unresolved and "vehicle_unresolved" or "vehicle_live") or "item_world"),
                                        tostring(entry and entry.sourceEpoch or state and state.sourceGeneration or 0),
                                        tostring(state and state.playbackEpoch or 0)
                                    )
                                )
                            end
                            entry.stateSnapshot = NMDeviceState.export(state)
                        end
                    end
                end
            else
                entry._serverTrackSchedulerSig = nil
                if type(state) == "table" then
                    clearServerTrackTimeline(entry, state)
                else
                    entry._serverTrackDurationMs = nil
                    entry._serverTrackStartedAtMs = nil
                    entry._serverTrackNextTransitionAtMs = nil
                    entry.serverTrackStartedAtMs = nil
                    entry.serverTrackDurationMs = nil
                    entry.serverTrackDueAtMs = nil
                end
                local schedulerSig = "active=false"
                if tostring(NMServerVehicleTrackSchedulerTick._schedulerStateSig[uuid] or "") ~= schedulerSig then
                    NMServerVehicleTrackSchedulerTick._schedulerStateSig[uuid] = schedulerSig
                    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe") then
                        NMCore.logChannel(
                            "progressionProbe",
                            "server_track_scheduler_state",
                            string.format(
                                "uuid=%s unresolved=%s isPlaying=%s nextAtMs=%s",
                                tostring(uuid),
                                tostring(tostring(entry.kind or "") == "vehicle" and ((entry._vehicleResolved == false) or (entry._vehicleSourceResolved == false)) or false),
                                tostring(state and state.isPlaying == true),
                                "nil"
                            )
                        )
                    end
                end
            end
        end
    end
end

