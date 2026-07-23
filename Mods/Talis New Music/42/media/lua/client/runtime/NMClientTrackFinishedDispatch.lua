NMClientTrackFinishedDispatch = NMClientTrackFinishedDispatch or {}

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

local function buildTrackFinishedArgs(state, playbackMode, endedToken)
    local trackCount = resolveTrackCountFromMedia(state)
    local contract = NMTrackProgressionContract.resolve(state, {
        context = tostring(playbackMode or state and state.playbackMode or "world"),
        worldAuthoritative = tostring(playbackMode or state and state.playbackMode or "world") == "world"
    })
    local token = contract and contract.token or {}
    local observedDurationMs = tonumber(endedToken and endedToken.observedDurationMs) or 0
    return {
        playbackMode = tostring(playbackMode or state and state.playbackMode or "world"),
        trackCount = trackCount,
        hasTrack = trackCount > 0,
        expectedRevision = tonumber(token.revision) or 0,
        expectedPlaybackEpoch = tonumber(token.playbackEpoch) or 0,
        expectedTrackIndex = tonumber(token.trackIndex) or 0,
        observedDurationMs = observedDurationMs > 0 and math.floor(observedDurationMs + 0.5) or nil
    }
end

local function logTrackFinishedDispatch(kind, uuid, detail)
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe") then
        NMCore.logChannel(
            "progressionProbe",
            "track_finished_dispatch",
            string.format("kind=%s uuid=%s %s", tostring(kind), tostring(uuid), tostring(detail or ""))
        )
    end
end

local function shouldLogTrackFinishedConsume(uuid, sourceKind, state, consumed)
    if not (NMCore and NMCore.shouldLogEvery) then
        return consumed == true
    end
    if consumed == true then
        return true
    end
    local epoch = tonumber(state and state.playbackEpoch) or -1
    local track = tonumber(state and state.trackIndex) or -1
    local key = string.format(
        "progressionProbe.track_finished_consume.%s.%s.%s.%s",
        tostring(uuid or ""),
        tostring(sourceKind or "unknown"),
        tostring(epoch),
        tostring(track)
    )
    local nowMs = (getTimestampMs and tonumber(getTimestampMs()))
        or ((getTimestamp and tonumber(getTimestamp()) or 0) * 1000)
        or 0
    return NMCore.shouldLogEvery(key, nowMs, 1500)
end

local function logTrackFinishedArgs(kind, uuid, state, args)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")) then
        return
    end
    NMCore.logChannel(
        "progressionProbe",
        "track_finished_args",
        string.format(
            "kind=%s uuid=%s media=%s mode=%s stateTrack=%s payloadTrackCount=%s observedDurationMs=%s expectedEpoch=%s expectedTrack=%s",
            tostring(kind or "unknown"),
            tostring(uuid or ""),
            tostring(state and state.mediaFullType or "nil"),
            tostring(args and args.playbackMode or state and state.playbackMode or "nil"),
            tostring(state and state.trackIndex or -1),
            tostring(args and args.trackCount or 0),
            tostring(args and args.observedDurationMs or 0),
            tostring(args and args.expectedPlaybackEpoch or 0),
            tostring(args and args.expectedTrackIndex or 0)
        )
    )
end

local function persistDetachedSPSnapshot(uuid, entry, state)
    local source = entry and entry.source or nil
    if not source then
        return
    end
    NMWorldRegistrySnapshot.upsertSP({
        kind = "item",
        uuid = tostring(uuid),
        profileType = entry and (entry.profileType or entry.itemFullType) or nil,
        sourceMode = tostring(source.context or source.mode or "placed"),
        sourceEpoch = tonumber(state and state.sourceGeneration) or 0,
        x = tonumber(source.x) or 0,
        y = tonumber(source.y) or 0,
        z = tonumber(source.z) or 0,
        itemId = entry and entry.itemId or nil,
        itemFullType = entry and entry.itemFullType or nil,
        state = NMDeviceState.export(state),
        revision = tonumber(state and state.revision) or 0,
        playbackEpoch = tonumber(state and state.playbackEpoch) or 0
    })
end

local function applyDetachedTrackFinishedLocalSP(uuid, profile, state, entry)
    local payload = buildTrackFinishedArgs(state, "world")
    local changed, reason = NMDeviceTransitions.apply(profile, state, "track_finished", payload)
    if not changed then
        logTrackFinishedDispatch("detached_sp", uuid, "applied=false reason=" .. tostring(reason or "none"))
        return
    end

    NMDeviceState.bumpPlaybackEpoch(state)
    NMDeviceState.bumpRevision(state)

    local keep = NMRegistryPolicy.shouldKeepWorldSourceState(state)
    if not keep then
        local src = entry and entry.source or nil
        local sourceContext = tostring(src and src.context or src and src.mode or "")
        local worldContext = (
            sourceContext == "placed"
            or sourceContext == "vehicle"
            or sourceContext == "attached"
            or sourceContext == "stowed"
            or sourceContext == "world"
        )
        if worldContext and (state.isOn == true or state.isPlaying == true or state.desiredIsOn == true or state.desiredIsPlaying == true) then
            state.playbackMode = "world"
            keep = true
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe") then
                NMCore.logChannel(
                    "progressionProbe",
                    "detached_sp_keep_override",
                    string.format(
                        "uuid=%s reason=world_context_active ctx=%s isOn=%s isPlaying=%s",
                        tostring(uuid),
                        tostring(sourceContext),
                        tostring(state.isOn == true),
                        tostring(state.isPlaying == true)
                    )
                )
            end
        end
    end
    if keep then
        if NMClientWorldSourceCache and NMClientWorldSourceCache.upsertFromPayload then
            local source = entry and entry.source or nil
            NMClientWorldSourceCache.upsertFromPayload({
                kind = "item",
                uuid = tostring(uuid),
                profileType = entry and (entry.profileType or entry.itemFullType) or nil,
                sourceMode = tostring(source and (source.context or source.mode) or "placed"),
                x = tonumber(source and source.x) or 0,
                y = tonumber(source and source.y) or 0,
                z = tonumber(source and source.z) or 0,
                itemId = entry and entry.itemId or nil,
                itemFullType = entry and entry.itemFullType or nil,
                sourceEpoch = tonumber(state.sourceGeneration) or 0,
                state = state
            })
        end
        persistDetachedSPSnapshot(uuid, entry, state)
        logTrackFinishedDispatch("detached_sp", uuid, "applied=true keep=true")
    else
        NMClientWorldSourceCache.remove(uuid)
        NMWorldRegistrySnapshot.removeSP(uuid)
        logTrackFinishedDispatch("detached_sp", uuid, "applied=true keep=false")
    end
end

local function dispatchTrackFinishedForInventory(player, item, state, uuid, endedToken)
    if not player or not item or not state then
        return
    end
    local mode = tostring(state.playbackMode or "inventory")
    local worldAuthoritative = mode == "world"
    local action = worldAuthoritative and "track_finished_world" or "track_finished"
    local kind = worldAuthoritative and "world_item" or "inventory"
    local args = buildTrackFinishedArgs(state, mode, endedToken)
    logTrackFinishedArgs(kind, uuid, state, args)
    local ok, reason = NMClientIntentDispatch.performIntent(player, item, action, args)
    logTrackFinishedDispatch(
        kind,
        uuid,
        "ok=" .. tostring(ok == true)
            .. " reason=" .. tostring(reason or "none")
            .. " token=" .. tostring(args.expectedPlaybackEpoch or 0) .. ":" .. tostring(args.expectedTrackIndex or 0)
    )
end

local function dispatchTrackFinishedForVehicle(player, profile, state, entry, uuid, endedToken)
    local source = entry and entry.source or nil
    local vehicle = source and source.vehicle or nil
    if (not vehicle) and source and source.vehicleId and getVehicleById then
        vehicle = getVehicleById(tonumber(source.vehicleId))
    end
    if not vehicle then
        logTrackFinishedDispatch("vehicle", uuid, "ok=false reason=vehicle_missing")
        return
    end
    local partId = tostring(entry and entry.partId or "Radio")
    local part = vehicle.getPartById and vehicle:getPartById(partId) or nil
    if not part then
        part = vehicle.getPartById and vehicle:getPartById("Radio") or nil
    end
    if not part then
        logTrackFinishedDispatch("vehicle", uuid, "ok=false reason=part_missing")
        return
    end

    local args = buildTrackFinishedArgs(state, "world", endedToken)
    logTrackFinishedArgs("vehicle", uuid, state, args)
    local ok, reason = NMClientIntentDispatch.performVehicleIntent(player, vehicle, part, "track_finished", args)
    logTrackFinishedDispatch(
        "vehicle",
        uuid,
        "ok=" .. tostring(ok == true)
            .. " reason=" .. tostring(reason or "none")
            .. " token=" .. tostring(args.expectedPlaybackEpoch or 0) .. ":" .. tostring(args.expectedTrackIndex or 0)
    )
end

local function dispatchTrackFinishedForDetachedItem(player, profile, state, entry, uuid, endedToken)
    if not NMCore.isMPClientRuntime() then
        applyDetachedTrackFinishedLocalSP(uuid, profile, state, entry)
        return
    end

    local itemId = tostring(entry and entry.itemId or "")
    if itemId == "" then
        logTrackFinishedDispatch("detached_mp", uuid, "ok=false reason=item_id_missing")
        return
    end
    local floors = NMDeviceProfiles.getWorldTrackingFloors(profile)
    local item = NMInventoryHelpers.findWorldItemByIdNearPlayer(player, itemId, 8, floors)
    if not item then
        logTrackFinishedDispatch("detached_mp", uuid, "ok=false reason=item_not_found itemId=" .. tostring(itemId))
        return
    end
    local args = buildTrackFinishedArgs(state, "world", endedToken)
    logTrackFinishedArgs("detached_mp", uuid, state, args)
    local ok, reason = NMClientIntentDispatch.performIntent(player, item, "track_finished", args)
    logTrackFinishedDispatch(
        "detached_mp",
        uuid,
        "ok=" .. tostring(ok == true)
            .. " reason=" .. tostring(reason or "none")
            .. " token=" .. tostring(args.expectedPlaybackEpoch or 0) .. ":" .. tostring(args.expectedTrackIndex or 0)
    )
end

function NMClientTrackFinishedDispatch.consumeAndDispatchTrackFinished(player, profile, state, entry, item, sourceKind, uuid)
    local endedToken = NMPlaybackRuntime.consumeTrackEndedToken(uuid)
    if not endedToken then
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")
            and shouldLogTrackFinishedConsume(uuid, sourceKind, state, false) then
            NMCore.logChannel(
                "progressionProbe",
                "track_finished_consume",
                string.format(
                    "uuid=%s sourceKind=%s consumed=false media=%s epoch=%s track=%s",
                    tostring(uuid),
                    tostring(sourceKind or "unknown"),
                    tostring(state and state.mediaFullType or "nil"),
                    tostring(state and state.playbackEpoch or -1),
                    tostring(state and state.trackIndex or -1)
                )
            )
        end
        return
    end
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")
        and shouldLogTrackFinishedConsume(uuid, sourceKind, state, true) then
        NMCore.logChannel(
            "progressionProbe",
            "track_finished_consume",
            string.format(
                "uuid=%s sourceKind=%s consumed=true observedDurationMs=%s media=%s epoch=%s track=%s",
                tostring(uuid),
                tostring(sourceKind or "unknown"),
                tostring(endedToken and endedToken.observedDurationMs or 0),
                tostring(state and state.mediaFullType or "nil"),
                tostring(state and state.playbackEpoch or -1),
                tostring(state and state.trackIndex or -1)
            )
        )
    end
    if sourceKind == "inventory" or sourceKind == "world_item" then
        dispatchTrackFinishedForInventory(player, item, state, uuid, endedToken)
        return
    end
    if sourceKind == "vehicle" then
        dispatchTrackFinishedForVehicle(player, profile, state, entry, uuid, endedToken)
        return
    end
    dispatchTrackFinishedForDetachedItem(player, profile, state, entry, uuid, endedToken)
end

return NMClientTrackFinishedDispatch

