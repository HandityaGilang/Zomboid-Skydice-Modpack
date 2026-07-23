NMServerItemIntentValidation = NMServerItemIntentValidation or {}

function NMServerItemIntentValidation.resolveTrackFinishedHintMinAgeMs()
    local minAge = tonumber(
        NMRuntimeConfig and NMRuntimeConfig.get and NMRuntimeConfig.get("serverVehicleTrackHintMinAgeMs", 5000)
        or 5000
    ) or 5000
    return math.max(0, math.floor(minAge + 0.5))
end

function NMServerItemIntentValidation.resolveStartedAtForHint(state)
    local startedAtMs = tonumber(state and state.serverTrackStartedAtMs) or 0
    if startedAtMs > 0 then
        return startedAtMs, "state_started"
    end
    local dueAtMs = tonumber(state and state.serverTrackDueAtMs) or 0
    local durationMs = tonumber(state and state.serverTrackDurationMs) or 0
    if dueAtMs > 0 and durationMs > 0 then
        local derived = math.max(0, math.floor(dueAtMs - durationMs))
        if derived > 0 then
            return derived, "derived_due_minus_duration"
        end
    end
    return 0, "missing"
end

function NMServerItemIntentValidation.shouldGateWorldTrackFinished(ctx, action)
    if tostring(action or "") ~= "track_finished" then
        return false
    end
    if not (NMCore and NMCore.isMPServerAuthority and NMCore.isMPServerAuthority()) then
        return false
    end
    return tostring(ctx and ctx.state and ctx.state.playbackMode or "") == "world"
end

function NMServerItemIntentValidation.validateExpectedToken(state, args)
    local expectedRevision = tonumber(args and args.expectedRevision)
    if expectedRevision ~= nil and expectedRevision >= 0 and (tonumber(state and state.revision) or 0) ~= expectedRevision then
        return false, "stale_revision"
    end
    local expectedEpoch = tonumber(args and args.expectedPlaybackEpoch)
    if expectedEpoch ~= nil and expectedEpoch >= 0 and (tonumber(state and state.playbackEpoch) or 0) ~= expectedEpoch then
        return false, "stale_epoch"
    end
    local expectedTrack = tonumber(args and args.expectedTrackIndex)
    if expectedTrack ~= nil and expectedTrack >= 0 and (tonumber(state and state.trackIndex) or 0) ~= expectedTrack then
        return false, "stale_track"
    end
    return true, nil
end

function NMServerItemIntentValidation.canBypassStaleRevisionForTrackFinished(state, args)
    if type(state) ~= "table" or type(args) ~= "table" then
        return false
    end
    local expectedEpoch = tonumber(args.expectedPlaybackEpoch)
    local expectedTrack = tonumber(args.expectedTrackIndex)
    if expectedEpoch == nil or expectedTrack == nil then
        return false
    end
    local currentEpoch = tonumber(state.playbackEpoch) or 0
    local currentTrack = tonumber(state.trackIndex) or 0
    if currentEpoch ~= expectedEpoch or currentTrack ~= expectedTrack then
        return false
    end
    return state.isOn == true and state.isPlaying == true
end

function NMServerItemIntentValidation.resolveTarget(player, args)
    local inv = player and player.getInventory and player:getInventory() or nil
    if not inv then
        return nil, "missing_inventory"
    end

    local itemId = tostring(args and args.itemId or "")
    local uuid = tostring(args and args.uuid or "")
    local item = nil
    if itemId ~= "" then
        item = NMInventoryHelpers.findItemById(inv, itemId)
    end
    if (not item) and uuid ~= "" then
        item = NMInventoryHelpers.findItemByUuid(inv, uuid)
    end
    if (not item) and itemId ~= "" then
        item = NMInventoryHelpers.findWorldItemByIdNearPlayer(player, itemId, 8)
    end
    if (not item) and uuid ~= "" then
        item = NMInventoryHelpers.findWorldItemByUuidNearPlayer(player, uuid, 8)
    end
    if not item then
        return nil, "item_not_found"
    end

    local profile = NMDeviceProfiles.getForItem(item)
    if not profile and args and args.itemFullType and NMDeviceProfiles.getForFullType then
        profile = NMDeviceProfiles.getForFullType(tostring(args.itemFullType))
    end
    if not profile then
        return nil, "not_managed"
    end

    local state = NMDeviceState.ensure(item, profile)
    if not state then
        return nil, "missing_state"
    end
    if NMServerBootReset and NMServerBootReset.normalizeState then
        NMServerBootReset.normalizeState(state, "item", tostring(state.deviceUUID or itemId or uuid or ""))
    end

    return {
        player = player,
        inventory = inv,
        args = args or {},
        item = item,
        profile = profile,
        state = state,
        itemId = itemId,
        uuid = uuid
    }, nil
end

return NMServerItemIntentValidation

