-- Client-side authoritative state replication apply for item and vehicle devices.
NMClientStateSync = NMClientStateSync or {}
local identityReasonSeen = identityReasonSeen or {}
local staleItemApplySeen = staleItemApplySeen or {}
local rehydrateSummarySeen = rehydrateSummarySeen or {}
local rehydrateAppliedSeen = rehydrateAppliedSeen or {}
local rehydrateRefreshSeen = rehydrateRefreshSeen or {}
local modeAckSeen = modeAckSeen or {}
local modeAckSigSeen = modeAckSigSeen or {}
local sqlAnchorDivergenceSeen = sqlAnchorDivergenceSeen or {}
local stateApplyOkSeen = stateApplyOkSeen or {}
local STALE_DROP_LOG_TTL_MS = NMRuntimeProbeAdapter.shortHeartbeatMs()
local lineageSeen = lineageSeen or {}
local payloadLineageSeen = payloadLineageSeen or {}

local function logPortableUiProbe(tag, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("portableUiProbe")) then
        return
    end
    NMCore.logChannel("portableUiProbe", tostring(tag or "portable_ui"), tostring(detail or ""))
end

local function nowRealMs()
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

local function requestFreshRegistryAfterApply(args, state)
    if not (NMClientRegistrySync and NMClientRegistrySync.requestNow and args and state) then
        return
    end
    local session = tostring(args.serverSessionToken or "")
    if session == "" then
        return
    end
    local uuid = tostring(args.uuid or state.deviceUUID or "")
    if uuid == "" then
        return
    end
    local sig = table.concat({ session, uuid }, "|")
    local nowMs = nowRealMs()
    local lastMs = tonumber(rehydrateRefreshSeen[sig]) or 0
    if (nowMs - lastMs) < NMRuntimeProbeAdapter.shortHeartbeatMs() then
        return
    end
    rehydrateRefreshSeen[sig] = nowMs
    local playerObj = getPlayer and getPlayer() or getSpecificPlayer and getSpecificPlayer(0) or nil
    NMClientRegistrySync.requestNow(playerObj, "rehydrate_state_apply")
end

local function logApplyResult(tag, detail)
    NMRuntimeProbeAdapter.emit("runtimeProbe", "runtimeProbe", tag, detail or "")
end

local function logApplyOkDedup(kind, keySig, detail, cooldownMs)
    local nowMs = nowRealMs()
    local ttl = tonumber(cooldownMs) or NMRuntimeProbeAdapter.shortHeartbeatMs()
    local key = table.concat({ tostring(kind or "unknown"), tostring(keySig or "") }, "|")
    local lastMs = tonumber(stateApplyOkSeen[key]) or 0
    if lastMs > 0 and (nowMs - lastMs) < ttl then
        return
    end
    stateApplyOkSeen[key] = nowMs
    logApplyResult("client_state_apply_ok", detail)
end

local function logSqlAnchorLineage(uuid, entry, path, reason)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")) then
        return
    end
    local nowMs = nowRealMs()
    local state = entry and entry.stateSnapshot or nil
    local isPayloadPath = tostring(path or "") == "client_upsert_payload" and tostring(reason or "") == "payload"
    if isPayloadPath then
        local payloadKey = table.concat({
            tostring(uuid or ""),
            tostring(entry and entry.sourceGeneration or 0),
            tostring(state and state.revision or 0),
            tostring(state and state.playbackEpoch or 0)
        }, "|")
        local payloadLastMs = tonumber(payloadLineageSeen[payloadKey]) or 0
        if payloadLastMs > 0 and (nowMs - payloadLastMs) < 120000 then
            return
        end
        payloadLineageSeen[payloadKey] = nowMs
    end
    local sig = table.concat({
        tostring(path or "unknown"),
        tostring(reason or "none"),
        tostring(entry and entry.sourceGeneration or 0),
        tostring(state and state.revision or 0),
        tostring(state and state.playbackEpoch or 0),
        tostring(entry and entry.vehicleSqlId or ""),
        tostring(entry and entry.vehicleSqlIdHint or ""),
        tostring(entry and entry.vehicleIdHint or "")
    }, "|")
    local dedupeKey = table.concat({ tostring(uuid or ""), sig }, "|")
    local lastMs = tonumber(lineageSeen[dedupeKey]) or 0
    local cooldownMs = isPayloadPath and 120000 or 20000
    if lastMs > 0 and (nowMs - lastMs) < cooldownMs then
        return
    end
    lineageSeen[dedupeKey] = nowMs
    NMCore.logChannel(
        "runtimeProbe",
        "sql_anchor_lineage",
        string.format(
            "uuid=%s sourceGen=%s revision=%s playbackEpoch=%s vehicleSqlId=%s vehicleSqlIdHint=%s runtimeVehicleIdHint=%s path=%s reason=%s",
            tostring(uuid or ""),
            tostring(entry and entry.sourceGeneration or 0),
            tostring(state and state.revision or 0),
            tostring(state and state.playbackEpoch or 0),
            tostring(entry and entry.vehicleSqlId or ""),
            tostring(entry and entry.vehicleSqlIdHint or ""),
            tostring(entry and entry.vehicleIdHint or ""),
            tostring(path or "unknown"),
            tostring(reason or "none")
        )
    )
end

local function logVehicleRebindTrace(tag, uuid, detail)
    if NMCore and NMCore.logVehicleRebindTrace then
        NMCore.logVehicleRebindTrace(tag, uuid, detail)
    end
end

local function logIdentityStateProbe(uuid, hasState, hasUuid, source)
    logApplyResult(
        "identity_state_probe",
        string.format(
            "uuid=%s hasState=%s hasUuid=%s source=%s",
            tostring(uuid or ""),
            tostring(hasState == true),
            tostring(hasUuid == true),
            tostring(source or "")
        )
    )
end

local function logIdentityConflict(uuid, observed, expected, stage)
    logApplyResult(
        "identity_conflict",
        string.format(
            "uuid=%s observed=%s expected=%s stage=%s",
            tostring(uuid or ""),
            tostring(observed or ""),
            tostring(expected or ""),
            tostring(stage or "")
        )
    )
end

local function logIdentityReasonOnce(uuid, sourceGen, reason, detail)
    local key = table.concat({
        tostring(uuid or ""),
        tostring(sourceGen or 0),
        tostring(reason or "")
    }, "|")
    if identityReasonSeen[key] == true then
        return
    end
    identityReasonSeen[key] = true
    logApplyResult(tostring(reason or "identity_reason"), detail or "")
end

local function shouldOverrideItemStateGuard(args)
    if type(args) ~= "table" then
        return false
    end
    if args.forceApply == true then
        return true
    end
    local rebindReason = tostring(args.rebindReason or "")
    if rebindReason ~= "" then
        return true
    end
    local transitionReason = tostring(args.transitionReason or "")
    if transitionReason == "rehydrate_override" then
        return true
    end
    return false
end

local function logItemStateDropOnce(uuid, incomingGen, incomingRev, localGen, localRev, reason)
    local sig = table.concat({
        tostring(uuid or ""),
        tostring(incomingGen or 0),
        tostring(incomingRev or 0),
        tostring(localGen or 0),
        tostring(localRev or 0),
        tostring(reason or "unknown")
    }, "|")
    local nowMs = nowRealMs()
    local lastMs = tonumber(staleItemApplySeen[sig]) or 0
    if lastMs > 0 and (nowMs - lastMs) < STALE_DROP_LOG_TTL_MS then
        return
    end
    staleItemApplySeen[sig] = nowMs
    logApplyResult(
        "state_apply_drop_stale_item",
        string.format(
            "uuid=%s reason=%s incomingGen=%s incomingRev=%s localGen=%s localRev=%s",
            tostring(uuid or ""),
            tostring(reason or "unknown"),
            tostring(incomingGen or 0),
            tostring(incomingRev or 0),
            tostring(localGen or 0),
            tostring(localRev or 0)
        )
    )
end

local function acknowledgeModeSyncIfPresent(args, sourceGeneration)
    if not (args and args.sourceMode) then
        return
    end
    local mode = tostring(args.sourceMode or "unknown")
    local uuid = tostring(args.uuid or "nil")
    local ackKey = table.concat({ uuid, mode }, "|")
    local sig = table.concat({ "item", tostring(sourceGeneration or 0), mode }, "|")
    if NMRuntimeProbeAdapter.shouldEmitTransitionOrHeartbeat(modeAckSigSeen, modeAckSeen, ackKey, sig, NMRuntimeProbeAdapter.shortHeartbeatMs()) then
        logApplyResult(
            "mode_sync_ack",
            "kind=item uuid=" .. uuid .. " sourceMode=" .. mode
        )
    end
    if NMClientModeSync and NMClientModeSync.onAck then
        NMClientModeSync.onAck(args.uuid, args.sourceMode, tonumber(sourceGeneration) or 0)
    end
end

local function logRehydrateApplySummary(kind, status, args, state, incomingGen, incomingRev, localGen, localRev)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")) then
        return
    end
    local uuid = tostring(args and args.uuid or state and state.deviceUUID or "")
    local session = tostring(args and args.serverSessionToken or "")
    local playbackEpoch = tonumber(state and state.playbackEpoch) or 0
    local trackIndex = tonumber(state and state.trackIndex) or 0
    local statusName = tostring(status or "applied")
    if statusName == "applied" then
        local mode = tostring(state and state.authoritativeMode or args and args.sourceMode or "")
        local sig = table.concat({
            tostring(kind or "item"),
            tostring(uuid),
            tostring(session),
            tostring(playbackEpoch),
            tostring(trackIndex),
            tostring(state and state.isOn == true),
            tostring(state and state.isPlaying == true),
            tostring(mode)
        }, "|")
        local nowMs = nowRealMs()
        local lastMs = tonumber(rehydrateAppliedSeen[sig]) or 0
        if lastMs > 0 and (nowMs - lastMs) < NMRuntimeProbeAdapter.shortHeartbeatMs() then
            return
        end
        rehydrateAppliedSeen[sig] = nowMs
    else
        local sig = table.concat({
            tostring(kind or "item"),
            statusName,
            tostring(uuid),
            tostring(session),
            tostring(incomingGen or 0),
            tostring(incomingRev or 0),
            tostring(playbackEpoch),
            tostring(trackIndex)
        }, "|")
        if rehydrateSummarySeen[sig] == true then
            return
        end
        rehydrateSummarySeen[sig] = true
    end
    logApplyResult(
        "rehydrate_apply_summary",
        string.format(
            "kind=%s status=%s uuid=%s session=%s incomingGen=%s incomingRev=%s localGen=%s localRev=%s epoch=%s track=%s isOn=%s isPlaying=%s battery=%.3f",
            tostring(kind or "item"),
            tostring(status or "applied"),
            tostring(uuid),
            tostring(session ~= "" and session or "nil"),
            tostring(incomingGen or 0),
            tostring(incomingRev or 0),
            tostring(localGen or 0),
            tostring(localRev or 0),
            tostring(playbackEpoch),
            tostring(trackIndex),
            tostring(state and state.isOn == true),
            tostring(state and state.isPlaying == true),
            tonumber(state and state.batteryCharge) or 0
        )
    )
end

local function isWorldLikeItemSourceMode(sourceMode)
    local mode = tostring(sourceMode or "")
    return mode == "placed" or mode == "attached" or mode == "stowed"
end

local function isExplicitMediaRemovalApply(args)
    if type(args) ~= "table" then
        return false
    end
    local transitionReason = tostring(args.transitionReason or "")
    if transitionReason == "eject_media" or transitionReason == "remove_media" then
        return true
    end
    local rebindReason = tostring(args.rebindReason or "")
    if rebindReason == "media_eject" or rebindReason == "media_remove" then
        return true
    end
    return false
end

local function classifyItemRehydratePayload(args, state)
    if type(args) ~= "table" or type(state) ~= "table" then
        return "authoritative_complete"
    end
    local incoming = type(args.state) == "table" and args.state or nil
    if type(incoming) ~= "table" then
        return "authoritative_complete"
    end
    if not isWorldLikeItemSourceMode(args.sourceMode) then
        return "authoritative_complete"
    end
    if isExplicitMediaRemovalApply(args) then
        return "authoritative_complete"
    end
    local localMedia = tostring(state.mediaFullType or "")
    if localMedia == "" then
        return "authoritative_complete"
    end
    local incomingMedia = tostring(incoming.mediaFullType or "")
    if incomingMedia ~= "" then
        return "authoritative_complete"
    end
    local incomingSourceGen = tonumber(args.sourceGeneration) or tonumber(incoming.sourceGeneration) or 0
    local localSourceGen = tonumber(state.sourceGeneration) or 0
    if incomingSourceGen < localSourceGen then
        return "stale_or_duplicate"
    end
    local incomingEpoch = tonumber(incoming.playbackEpoch) or 0
    local localEpoch = tonumber(state.playbackEpoch) or 0
    if incomingEpoch < localEpoch then
        return "stale_or_duplicate"
    end
    if incomingSourceGen > localSourceGen then
        return "authoritative_complete"
    end
    if incomingEpoch > localEpoch then
        return "authoritative_complete"
    end
    return "transient_incomplete_media"
end

local function preserveLocalMediaAcrossIncompleteApply(args, state)
    local incoming = type(args) == "table" and type(args.state) == "table" and args.state or nil
    if not incoming or not state then
        return false
    end
    incoming.mediaFullType = state.mediaFullType
    incoming.mediaRecordedMediaIndex = state.mediaRecordedMediaIndex
    incoming.mediaDisplayName = state.mediaDisplayName
    return true
end

local function updateVehicleCacheFromAuthority(args, state)
    if not (NMClientWorldSourceCache and state) then
        return
    end
    local uuid = tostring(state.deviceUUID or args and args.uuid or "")
    if uuid == "" then
        return
    end
    local incomingGen = tonumber(args and args.sourceGeneration) or tonumber(state.sourceGeneration) or 0
    local rebindReason = args and args.rebindReason ~= nil and tostring(args.rebindReason or "") or ""
    local allowEqualGenIdentityOverwrite = rebindReason ~= ""
    local entry = NMClientWorldSourceCache.get and NMClientWorldSourceCache.get(uuid) or nil
    if not entry then
        return
    end
    local acceptedGen = math.max(
        tonumber(entry._acceptedSourceGeneration) or 0,
        tonumber(entry.sourceEpoch) or 0
    )
    if incomingGen < acceptedGen then
        return
    end

    local incomingVehicleId = tostring(args and args.vehicleId or "")
    local incomingVehicleIdHint = tostring(args and args.vehicleIdHint or incomingVehicleId or "")
    local incomingVehicleSqlId = tostring(args and args.vehicleSqlId or "")
    local incomingVehicleSqlIdHint = tostring(args and args.vehicleSqlIdHint or incomingVehicleSqlId or "")
    local incomingOwnerId = tostring(args and args.ownerId or "")
    local currentVehicleId = tostring(entry.vehicleId or "")
    local isResolvedLocally = entry._vehicleSourceResolved == true
        or (entry.source and (entry.source._vehicleResolved == true or entry.source.vehicleResolved == true))
    if incomingGen == acceptedGen
        and isResolvedLocally
        and incomingVehicleId ~= ""
        and currentVehicleId ~= ""
        and incomingVehicleId ~= currentVehicleId
        and (not allowEqualGenIdentityOverwrite) then
        logVehicleRebindTrace(
            "authority_equal_gen_identity_guard",
            uuid,
            string.format(
                "incomingVehicleId=%s cachedVehicleId=%s sourceGen=%s action=ignore_equal_generation_overwrite",
                tostring(incomingVehicleId),
                tostring(currentVehicleId),
                tostring(incomingGen)
            )
        )
        return
    end

    entry._acceptedSourceGeneration = math.max(acceptedGen, incomingGen)
    entry.sourceEpoch = math.max(tonumber(entry.sourceEpoch) or 0, incomingGen)
    entry.sourceGeneration = math.max(tonumber(entry.sourceGeneration) or 0, incomingGen)
    if incomingVehicleIdHint ~= "" then
        entry._authorityVehicleIdHint = incomingVehicleIdHint
    end
    if incomingOwnerId ~= "" then
        entry._authorityOwnerIdHint = incomingOwnerId
        entry.ownerId = incomingOwnerId
    end
    if incomingVehicleIdHint ~= "" then
        entry.vehicleIdHint = incomingVehicleIdHint
    end
    if incomingVehicleSqlIdHint ~= "" then
        entry.vehicleSqlIdHint = incomingVehicleSqlIdHint
    end
    entry._authorityPartIdHint = tostring(args and args.partId or entry.partId or "Radio")
    entry.rebindReason = rebindReason ~= "" and rebindReason or nil
    entry.source = entry.source or {}
    entry.source.mode = "world"
    entry.source.context = "vehicle"
    entry.source.ownerId = incomingOwnerId ~= "" and incomingOwnerId or tostring(entry.source.ownerId or entry.ownerId or "")
    if incomingVehicleIdHint ~= "" then
        entry.source.vehicleIdHint = incomingVehicleIdHint
    end
    if incomingVehicleSqlIdHint ~= "" then
        entry.source.vehicleSqlIdHint = incomingVehicleSqlIdHint
    end
    if (entry.source.vehicleId == nil or tostring(entry.source.vehicleId or "") == "") and incomingVehicleIdHint ~= "" then
        entry.source.vehicleId = incomingVehicleIdHint ~= "" and incomingVehicleIdHint or incomingVehicleId or entry.vehicleId
    end
    if (entry.source.vehicleSqlId == nil or tostring(entry.source.vehicleSqlId or "") == "") and incomingVehicleSqlIdHint ~= "" then
        entry.source.vehicleSqlId = incomingVehicleSqlIdHint ~= "" and incomingVehicleSqlIdHint or incomingVehicleSqlId or entry.vehicleSqlId
    end
    entry.source._vehicleResolved = false
    entry.source.vehicleResolved = false
    NMClientWorldSourceCache.entries[uuid] = entry
    logSqlAnchorLineage(uuid, entry, "client_state_apply_cache_update", "authoritative_apply")
end

local function resolveItemTarget(player, args)
    local inv = player and player.getInventory and player:getInventory() or nil
    local item = nil
    local itemId = tostring(args and args.itemId or "")
    local uuid = tostring(args and args.uuid or "")

    if inv and itemId ~= "" then
        item = NMInventoryHelpers.findItemById(inv, itemId)
    end
    if (not item) and inv and uuid ~= "" then
        item = NMInventoryHelpers.findItemByUuid(inv, uuid)
    end
    if (not item) and itemId ~= "" then
        item = NMInventoryHelpers.findWorldItemByIdNearPlayer(player, itemId, 8)
    end
    if (not item) and uuid ~= "" then
        item = NMInventoryHelpers.findWorldItemByUuidNearPlayer(player, uuid, 8)
    end

    return item
end

local function updateDetachedCacheFromState(item, args, state, profile)
    if not (NMClientWorldSourceCache and state) then
        return
    end
    local uuid = tostring((args and args.uuid) or (state and state.deviceUUID) or "")
    if uuid == "" then
        return
    end
    if NMDeviceState and NMDeviceState.isZombieDormant and NMDeviceState.isZombieDormant(state) then
        if NMClientWorldSourceCache and NMClientWorldSourceCache.remove then
            NMClientWorldSourceCache.remove(uuid)
        end
        logApplyResult(
            "client_detached_state_skip_zombie_dormant",
            "uuid=" .. tostring(uuid)
        )
        return
    end

    local sourceMode = tostring(args and args.sourceMode or "")
    local incomingOwnerOnlineId = tostring(args and args.ownerOnlineId or "")
    local incomingOwnerUsername = tostring(args and args.ownerUsername or "")
    local incomingOwnerId = tostring(args and args.ownerId or incomingOwnerOnlineId or incomingOwnerUsername or "")
    local entry = NMClientWorldSourceCache.get(uuid)
    local worldItem = item and item.getWorldItem and item:getWorldItem() or nil
    local square = worldItem and worldItem.getSquare and worldItem:getSquare() or nil
    local profileType = profile and profile.fullType or (item and item.getFullType and item:getFullType() or nil)
    local localPlayer = getSpecificPlayer and getSpecificPlayer(0) or nil
    local localInv = localPlayer and localPlayer.getInventory and localPlayer:getInventory() or nil
    local ownsInventoryItem = item
        and item.getContainer and item:getContainer() ~= nil
        and localInv ~= nil
    local portableTracked = NMDeviceProfiles
        and NMDeviceProfiles.isPortableTrackedProfile
        and NMDeviceProfiles.isPortableTrackedProfile(profile) == true

    if portableTracked and ownsInventoryItem and (sourceMode == "attached" or sourceMode == "stowed") then
        if NMClientWorldSourceCache and NMClientWorldSourceCache.remove then
            NMClientWorldSourceCache.remove(uuid)
        end
        logApplyResult(
            "client_detached_state_skip_owner_portable",
            "uuid=" .. tostring(uuid) .. " sourceMode=" .. tostring(sourceMode)
        )
        return
    end

    if not entry and sourceMode == "placed" and square then
        entry = NMClientWorldSourceCache.upsertFromPayload({
            kind = "item",
            uuid = uuid,
            itemId = item and item.getID and tostring(item:getID() or "") or "",
            itemFullType = item and item.getFullType and tostring(item:getFullType() or "") or "",
            profileType = profileType,
            sourceMode = sourceMode,
            sourceEpoch = tonumber(state.sourceGeneration) or 0,
            ownerId = incomingOwnerId,
            ownerOnlineId = incomingOwnerOnlineId,
            ownerUsername = incomingOwnerUsername,
            x = square:getX() + 0.5,
            y = square:getY() + 0.5,
            z = square:getZ(),
            state = NMDeviceState.export(state)
        }, args and args.serverSessionToken)
    end

    if not entry then
        return
    end

    entry.stateSnapshot = NMDeviceState.export(state)
    entry.source = entry.source or {}
    if sourceMode ~= "" then
        entry.source.context = sourceMode
    end
    if incomingOwnerId ~= "" then
        entry.ownerId = incomingOwnerId
        entry.ownerOnlineId = incomingOwnerOnlineId ~= "" and incomingOwnerOnlineId or tostring(entry.ownerOnlineId or "")
        entry.ownerUsername = incomingOwnerUsername ~= "" and incomingOwnerUsername or tostring(entry.ownerUsername or "")
        entry.source.ownerId = incomingOwnerId
        entry.source.ownerOnlineId = incomingOwnerOnlineId ~= "" and incomingOwnerOnlineId or tostring(entry.source.ownerOnlineId or "")
        entry.source.ownerUsername = incomingOwnerUsername ~= "" and incomingOwnerUsername or tostring(entry.source.ownerUsername or "")
    end
    if square then
        entry.source.x = square:getX() + 0.5
        entry.source.y = square:getY() + 0.5
        entry.source.z = square:getZ()
    end
    entry.sourceEpoch = tonumber(state.sourceGeneration) or tonumber(entry.sourceEpoch) or 0
    entry.profileType = entry.profileType or profileType
    NMClientWorldSourceCache.entries[uuid] = entry
    logApplyResult(
        "client_detached_state_merge",
        "uuid=" .. tostring(uuid) .. " sourceMode=" .. tostring(sourceMode ~= "" and sourceMode or (entry.source and entry.source.context or "unknown"))
    )
end

local function applyItemState(player, args)
    local item = resolveItemTarget(player, args)
    if not item then
        logApplyResult(
            "client_state_apply_miss",
            "kind=item itemId=" .. tostring(args and args.itemId or "nil") .. " uuid=" .. tostring(args and args.uuid or "nil")
        )
        return
    end

    local profile = NMDeviceProfiles.getForItem(item)
    if not profile then
        local hintedType = args and args.itemFullType or nil
        profile = NMDeviceProfiles.getForFullType(hintedType)
    end
    if not profile then
        logApplyResult(
            "client_state_apply_miss",
            "kind=item profile_missing itemId=" .. tostring(args and args.itemId or "nil") .. " uuid=" .. tostring(args and args.uuid or "nil")
        )
        return
    end

    local state = NMDeviceState.ensure(item, profile)
    if not state then
        logApplyResult(
            "client_state_apply_miss",
            "kind=item state_missing itemId=" .. tostring(args and args.itemId or "nil") .. " uuid=" .. tostring(args and args.uuid or "nil")
        )
        return
    end
    local incomingSourceGen = tonumber(args and args.sourceGeneration) or tonumber(args and args.state and args.state.sourceGeneration) or 0
    local incomingRevision = tonumber(args and args.state and args.state.revision) or 0
    local incomingPlaybackEpoch = tonumber(args and args.state and args.state.playbackEpoch) or 0
    local localSourceGen = tonumber(state.sourceGeneration) or 0
    local localRevision = tonumber(state.revision) or 0
    local localPlaybackEpoch = tonumber(state.playbackEpoch) or 0
    local allowOverride = shouldOverrideItemStateGuard(args)
    local payloadClass = classifyItemRehydratePayload(args, state)
    if payloadClass == "transient_incomplete_media" and preserveLocalMediaAcrossIncompleteApply(args, state) then
        logApplyResult(
            "client_item_rehydrate_media_hold",
            "uuid="
                .. tostring(args and args.uuid or "nil")
                .. " sourceMode="
                .. tostring(args and args.sourceMode or "nil")
                .. " sourceGen="
                .. tostring(incomingSourceGen)
                .. " playbackEpoch="
                .. tostring(incomingPlaybackEpoch)
                .. " media="
                .. tostring(state.mediaFullType or "nil")
        )
    end
    local isMPClient = NMAuthorityContract and NMAuthorityContract.isMPClientRuntime and NMAuthorityContract.isMPClientRuntime() == true
    if isMPClient and not allowOverride then
        if incomingSourceGen < localSourceGen then
            logItemStateDropOnce(args and args.uuid, incomingSourceGen, incomingRevision, localSourceGen, localRevision, "source_generation_regressed")
            logRehydrateApplySummary("item", "drop_stale", args, state, incomingSourceGen, incomingRevision, localSourceGen, localRevision)
            acknowledgeModeSyncIfPresent(args, localSourceGen)
            return
        end
        if incomingSourceGen == localSourceGen and incomingRevision <= localRevision then
            logItemStateDropOnce(args and args.uuid, incomingSourceGen, incomingRevision, localSourceGen, localRevision, "revision_regressed_or_duplicate")
            logRehydrateApplySummary("item", "drop_stale", args, state, incomingSourceGen, incomingRevision, localSourceGen, localRevision)
            acknowledgeModeSyncIfPresent(args, localSourceGen)
            return
        end
        if incomingPlaybackEpoch < localPlaybackEpoch then
            logItemStateDropOnce(args and args.uuid, incomingSourceGen, incomingRevision, localSourceGen, localRevision, "playback_epoch_regressed")
            logRehydrateApplySummary("item", "drop_stale", args, state, incomingSourceGen, incomingRevision, localSourceGen, localRevision)
            acknowledgeModeSyncIfPresent(args, localSourceGen)
            return
        end
    end
    local beforeMode = tostring(state.authoritativeMode or "")
    local beforeSourceGen = tonumber(state.sourceGeneration) or 0
    local beforeRevision = tonumber(state.revision) or 0
    local appliedItemId = tostring(args and args.itemId or "")
    local appliedUuid = tostring(args and args.uuid or "")
    NMDeviceState.import(state, args and args.state or nil)
    state._authorityAppliedAtMs = nowRealMs()
    if NMClientSessionProjection and NMClientSessionProjection.markAuthoritativeStateSeen then
        NMClientSessionProjection.markAuthoritativeStateSeen(state, args and args.serverSessionToken, args and args.uuid)
    end
    updateVehicleCacheFromAuthority(args, state)
    logApplyOkDedup(
        "item",
        table.concat({
            tostring(args and args.uuid or "nil"),
            tostring(state.sourceGeneration or 0),
            tostring(state.revision or 0),
            tostring(state.playbackEpoch or 0),
            tostring(state.trackIndex or 0),
            tostring(state.isOn == true),
            tostring(state.isPlaying == true)
        }, "|"),
        "kind=item itemId="
            .. tostring(args and args.itemId or "nil")
            .. " uuid="
            .. tostring(args and args.uuid or "nil")
            .. " isOn="
            .. tostring(state.isOn == true)
            .. " isPlaying="
            .. tostring(state.isPlaying == true)
            .. " media="
            .. tostring(state.mediaFullType or "nil"),
        NMRuntimeProbeAdapter.shortHeartbeatMs()
    )
    acknowledgeModeSyncIfPresent(args, state and state.sourceGeneration)
    local afterMode = tostring(state.authoritativeMode or "")
    local afterSourceGen = tonumber(state.sourceGeneration) or 0
    local dormantPortable = NMDeviceState
        and NMDeviceState.isZombieDormant
        and NMDeviceState.isZombieDormant(state) == true
    if dormantPortable then
        state.authoritativeMode = "off"
        state.desiredMode = "off"
        state.playbackMode = "world"
        state.isOn = false
        state.desiredIsOn = false
        state.isPlaying = false
        state.desiredIsPlaying = false
        if NMDeviceUI and NMDeviceUI.invalidateOpenItemWindow then
            logPortableUiProbe(
                "state_apply_dormant_before",
                string.format(
                    "itemId=%s uuid=%s windows=%s",
                    tostring(appliedItemId ~= "" and appliedItemId or "nil"),
                    tostring(appliedUuid ~= "" and appliedUuid or "nil"),
                    tostring(NMDeviceUI and NMDeviceUI.inspectOpenPortableWindows and #NMDeviceUI.inspectOpenPortableWindows(0) or 0)
                )
            )
            NMDeviceUI.invalidateOpenItemWindow(appliedItemId, appliedUuid)
        end
        logApplyResult(
            "client_zombie_dormant_inventory_reject",
            "uuid="
                .. tostring(appliedUuid ~= "" and appliedUuid or "nil")
                .. " itemId="
                .. tostring(appliedItemId ~= "" and appliedItemId or "nil")
                .. " incomingMode="
                .. tostring(afterMode)
        )
        logRehydrateApplySummary("item", "applied", args, state, incomingSourceGen, incomingRevision, beforeSourceGen, beforeRevision)
        return
    end
    updateDetachedCacheFromState(item, args, state, profile)
    local windowsBefore = NMDeviceUI and NMDeviceUI.inspectOpenPortableWindows and NMDeviceUI.inspectOpenPortableWindows(0) or {}
    local reboundWindow = false
    local invalidatedWindow = NMDeviceUI and NMDeviceUI.invalidateOpenItemWindow
        and NMDeviceUI.invalidateOpenItemWindow(appliedItemId, appliedUuid) == true
        or false
    local portableTracked = NMDeviceProfiles
        and NMDeviceProfiles.isPortableTrackedProfile
        and NMDeviceProfiles.isPortableTrackedProfile(profile) == true
    local pickupRebind = portableTracked
        and (afterMode == "attached" or afterMode == "stowed")
        and NMClientPortableDropHandoff
        and NMClientPortableDropHandoff.consumePickupRebind
        and NMClientPortableDropHandoff.consumePickupRebind(appliedUuid) == true
    if portableTracked
        and not dormantPortable
        and (beforeMode == "placed" or pickupRebind)
        and (afterMode == "attached" or afterMode == "stowed") then
        reboundWindow = NMDeviceUI
            and NMDeviceUI.rebindOpenPortableItemWindow
            and NMDeviceUI.rebindOpenPortableItemWindow(appliedItemId, appliedUuid) == true
            or false
        if reboundWindow then
            invalidatedWindow = true
        end
        logApplyResult(
            "client_portable_ui_rebind",
            "uuid="
                .. tostring(appliedUuid ~= "" and appliedUuid or "nil")
                .. " fromMode="
                .. tostring(beforeMode)
                .. " toMode="
                .. tostring(afterMode)
                .. " invalidated="
                .. tostring(invalidatedWindow)
                .. " rebound="
                .. tostring(reboundWindow)
        )
    end
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        NMCore.logChannel(
            "runtimeProbe",
            "client_item_state_ui_refresh",
            string.format(
                "itemId=%s uuid=%s invalidated=%s media=%s",
                tostring(appliedItemId ~= "" and appliedItemId or "nil"),
                tostring(appliedUuid ~= "" and appliedUuid or "nil"),
                tostring(invalidatedWindow),
                tostring(state and state.mediaFullType or "nil")
            )
        )
    end
    local windowsAfter = NMDeviceUI and NMDeviceUI.inspectOpenPortableWindows and NMDeviceUI.inspectOpenPortableWindows(0) or {}
    local function snapshotsToLineLocal(snaps)
        if type(snaps) ~= "table" or #snaps <= 0 then
            return "none"
        end
        local parts = {}
        for i = 1, #snaps do
            local snap = snaps[i]
            parts[#parts + 1] = string.format(
                "%s[itemId=%s uuid=%s hasRef=%s timed=%s pending=%s awaitInsert=%s awaitEject=%s]",
                tostring(snap.uiFamily or "unknown"),
                tostring(snap.itemId or ""),
                tostring(snap.uuid or ""),
                tostring(snap.hasItemRef == true),
                tostring(snap.mediaTimedAction or ""),
                tostring(snap.pendingMediaFullType or ""),
                tostring(snap.awaitingMediaInsert == true),
                tostring(snap.awaitingMediaEject == true)
            )
        end
        return table.concat(parts, " ")
    end
    logPortableUiProbe(
        "state_apply_item_refresh",
        string.format(
            "itemId=%s uuid=%s media=%s invalidated=%s rebound=%s before=%s after=%s",
            tostring(appliedItemId ~= "" and appliedItemId or "nil"),
            tostring(appliedUuid ~= "" and appliedUuid or "nil"),
            tostring(state and state.mediaFullType or "nil"),
            tostring(invalidatedWindow),
            tostring(reboundWindow),
            snapshotsToLineLocal(windowsBefore),
            snapshotsToLineLocal(windowsAfter)
        )
    )
    if beforeMode ~= afterMode then
        logApplyResult(
            "client_state_authority_delta",
            "kind=item uuid="
                .. tostring(args and args.uuid or "nil")
                .. " mode="
                .. tostring(beforeMode)
                .. "->"
                .. tostring(afterMode)
                .. " sourceGen="
                .. tostring(beforeSourceGen)
                .. "->"
                .. tostring(afterSourceGen)
        )
    end
    logRehydrateApplySummary("item", "applied", args, state, incomingSourceGen, incomingRevision, beforeSourceGen, beforeRevision)
    requestFreshRegistryAfterApply(args, state)
end

local function applyVehicleState(args)
    local incomingVehicleSqlId = tostring(args and (args.vehicleSqlId or args.vehicleSqlIdHint) or "")
    local partId = tostring(args and args.partId or "Radio")
    local incomingSourceGen = tonumber(args and args.sourceGeneration) or tonumber(args and args.state and args.state.sourceGeneration) or 0
    local incomingUuid = tostring(args and args.state and args.state.deviceUUID or args and args.uuid or "")
    local cachedEntry = incomingUuid ~= "" and NMClientWorldSourceCache and NMClientWorldSourceCache.get and NMClientWorldSourceCache.get(incomingUuid) or nil
    local resolverEntry = {
        uuid = incomingUuid,
        partId = partId,
        source = {
            x = tonumber(args and args.state and args.state.sourceX) or tonumber(cachedEntry and cachedEntry.source and cachedEntry.source.x) or 0,
            y = tonumber(args and args.state and args.state.sourceY) or tonumber(cachedEntry and cachedEntry.source and cachedEntry.source.y) or 0,
            z = tonumber(args and args.state and args.state.sourceZ) or tonumber(cachedEntry and cachedEntry.source and cachedEntry.source.z) or 0,
            vehicleId = tostring(args and args.vehicleId or cachedEntry and cachedEntry.vehicleId or ""),
            vehicleIdHint = tostring(args and args.vehicleIdHint or args and args.vehicleId or cachedEntry and cachedEntry.vehicleIdHint or "")
        },
        _authorityVehicleIdHint = tostring(args and args.vehicleIdHint or args and args.vehicleId or cachedEntry and cachedEntry._authorityVehicleIdHint or ""),
        attachedRuntimeId = tonumber(cachedEntry and cachedEntry.attachedRuntimeId)
    }
    local attach = NMClientVehicleAttachmentResolver
        and NMClientVehicleAttachmentResolver.resolveAttachment
        and NMClientVehicleAttachmentResolver.resolveAttachment(resolverEntry, {
            partId = partId,
            runtimeVehicleIdHint = args and (args.vehicleIdHint or args.vehicleId),
            targetX = tonumber(args and args.state and args.state.sourceX) or nil,
            targetY = tonumber(args and args.state and args.state.sourceY) or nil,
            targetZ = tonumber(args and args.state and args.state.sourceZ) or nil,
            radius = 30
        }) or nil

    local vehicle = attach and attach.vehicle or nil
    local part = attach and attach.part or nil
    local resolveReason = tostring(attach and attach.reason or "resolver_unavailable")
    if (not vehicle or not part) and getVehicleById then
        local runtimeVehicleId = tonumber(args and (args.vehicleIdHint or args.vehicleId))
        if runtimeVehicleId then
            local hintedVehicle = getVehicleById(runtimeVehicleId)
            local hintedPart = hintedVehicle and hintedVehicle.getPartById and hintedVehicle:getPartById(partId) or nil
            if hintedVehicle and hintedPart then
                vehicle = hintedVehicle
                part = hintedPart
                resolveReason = "runtime_hint_fallback"
            end
        end
    end

    local observedVehicleSqlId = NMVehicleHelpers and NMVehicleHelpers.getVehicleSqlIdString and NMVehicleHelpers.getVehicleSqlIdString(vehicle) or ""
    local incomingVehicleSqlHint = tostring(args and (args.vehicleSqlId or args.vehicleSqlIdHint) or "")
    local divergenceUuid = tostring(incomingUuid ~= "" and incomingUuid or args and args.uuid or "")
    if incomingVehicleSqlHint ~= "" and observedVehicleSqlId ~= "" and incomingVehicleSqlHint ~= observedVehicleSqlId then
        local divergeKey = table.concat({
            tostring(divergenceUuid),
            tostring(incomingSourceGen or 0),
            tostring(incomingVehicleSqlHint),
            tostring(observedVehicleSqlId)
        }, "|")
        if divergenceUuid ~= "" and sqlAnchorDivergenceSeen[divergeKey] ~= true then
            sqlAnchorDivergenceSeen[divergeKey] = true
            logApplyResult(
                "sql_anchor_divergence_detected",
                "uuid="
                    .. tostring(divergenceUuid)
                    .. " sourceGen="
                    .. tostring(incomingSourceGen or 0)
                    .. " incomingSqlId="
                    .. tostring(incomingVehicleSqlHint)
                    .. " observedSqlId="
                    .. tostring(observedVehicleSqlId)
                    .. " path=client_state_apply"
            )
        end
    end

    if not (vehicle and part) then
        updateVehicleCacheFromAuthority(args, args and args.state or {})
        local degradedUuid = tostring(incomingUuid ~= "" and incomingUuid or args and args.uuid or "")
        logApplyResult(
            "client_state_apply_degraded",
            "kind=vehicle uuid="
                .. tostring(degradedUuid)
                .. " reason="
                .. tostring(resolveReason)
                .. " runtimeHint="
                .. tostring(args and (args.vehicleIdHint or args.vehicleId) or "nil")
                .. " partId="
                .. tostring(partId)
        )
        return
    end

    local profile = part and NMDeviceProfiles.getVehicleProfile(part) or nil
    if not (vehicle and part and profile) then
        logApplyResult(
            "client_state_apply_miss",
            "kind=vehicle vehicleId=" .. tostring(args and args.vehicleId or "nil") .. " partId=" .. tostring(partId)
        )
        return
    end
    local state = NMDeviceState.peek and NMDeviceState.peek(part) or nil
    if not state then
        logIdentityStateProbe(args and args.uuid, false, false, "client_state_apply_vehicle")
        logIdentityReasonOnce(
            args and args.uuid,
            incomingSourceGen,
            "identity_missing_readonly",
            "kind=vehicle reason=identity_missing_readonly vehicleId=" .. tostring(args and args.vehicleId or "nil") .. " partId=" .. tostring(partId)
        )
        return
    end
    local localUuid = tostring(state.deviceUUID or "")
    logIdentityStateProbe(localUuid ~= "" and localUuid or args and args.uuid, true, localUuid ~= "", "client_state_apply_vehicle")
    if localUuid == "" then
        logIdentityReasonOnce(
            args and args.uuid,
            incomingSourceGen,
            "identity_uuid_missing_readonly",
            "kind=vehicle reason=identity_uuid_missing_readonly vehicleId=" .. tostring(args and args.vehicleId or "nil") .. " partId=" .. tostring(partId)
        )
        return
    end
    if incomingUuid ~= "" and incomingUuid ~= localUuid then
        logIdentityConflict(localUuid, incomingUuid, localUuid, "client_state_apply_vehicle")
        logIdentityReasonOnce(
            localUuid,
            incomingSourceGen,
            "identity_uuid_conflict_drop",
            "kind=vehicle vehicleId=" .. tostring(args and args.vehicleId or "nil") .. " partId=" .. tostring(partId)
        )
        return
    end
    local beforeMode = tostring(state.authoritativeMode or "")
    local beforeSourceGen = tonumber(state.sourceGeneration) or 0
    local beforeRevision = tonumber(state.revision) or 0
    local beforePlaybackEpoch = tonumber(state.playbackEpoch) or 0
    local beforeIsOn = state.isOn == true
    local beforeIsPlaying = state.isPlaying == true
    local beforeVehicleId = tostring(state.sourceVehicleId or args and args.vehicleId or "")
    local beforeVehicleSqlId = tostring(args and args.vehicleSqlId or "")
    local traceUuid = tostring(localUuid or args and args.uuid or "")
    incomingSourceGen = tonumber(args and args.sourceGeneration) or tonumber(args and args.state and args.state.sourceGeneration) or beforeSourceGen
    local incomingPlaybackEpoch = tonumber(args and args.state and args.state.playbackEpoch) or 0
    local rebindReason = args and args.rebindReason ~= nil and tostring(args.rebindReason or "") or ""
    if incomingSourceGen < beforeSourceGen then
        logApplyResult(
            "client_state_apply_drop",
            "kind=vehicle reason=source_generation_regressed vehicleId="
                .. tostring(args and args.vehicleId or "nil")
                .. " sourceGen="
                .. tostring(beforeSourceGen)
                .. "->"
                .. tostring(incomingSourceGen)
        )
        if traceUuid ~= "" then
            logVehicleRebindTrace(
                "authority_generation_regress_guard",
                traceUuid,
                string.format(
                    "action=drop incomingGen=%s currentGen=%s vehicleId=%s partId=%s",
                    tostring(incomingSourceGen),
                    tostring(beforeSourceGen),
                    tostring(args and args.vehicleId or "nil"),
                    tostring(partId)
                )
            )
        end
        logRehydrateApplySummary("vehicle", "drop_stale", args, state, incomingSourceGen, tonumber(args and args.state and args.state.revision) or 0, beforeSourceGen, beforeRevision)
        return
    end
    if incomingSourceGen == beforeSourceGen and rebindReason == "" then
        if incomingPlaybackEpoch < beforePlaybackEpoch then
            logApplyResult(
                "client_state_apply_drop",
                "kind=vehicle reason=playback_epoch_regressed vehicleId="
                    .. tostring(args and args.vehicleId or "nil")
                    .. " playbackEpoch="
                    .. tostring(beforePlaybackEpoch)
                    .. "->"
                    .. tostring(incomingPlaybackEpoch)
            )
            logRehydrateApplySummary("vehicle", "drop_stale", args, state, incomingSourceGen, tonumber(args and args.state and args.state.revision) or 0, beforeSourceGen, beforeRevision)
            return
        end
        local cacheEntry = traceUuid ~= "" and NMClientWorldSourceCache and NMClientWorldSourceCache.get and NMClientWorldSourceCache.get(traceUuid) or nil
        local cacheVehicleId = tostring(cacheEntry and cacheEntry.vehicleId or "")
        local incomingVehicleId = tostring(args and args.vehicleId or "")
        if cacheEntry and cacheVehicleId ~= "" and incomingVehicleId ~= "" and cacheVehicleId ~= incomingVehicleId then
            logVehicleRebindTrace(
                "authority_equal_gen_identity_guard",
                traceUuid,
                string.format(
                    "incomingVehicleId=%s cachedVehicleId=%s sourceGen=%s action=ignore_equal_generation_overwrite",
                    tostring(incomingVehicleId),
                    tostring(cacheVehicleId),
                    tostring(incomingSourceGen)
                )
            )
            logRehydrateApplySummary("vehicle", "drop_stale", args, state, incomingSourceGen, tonumber(args and args.state and args.state.revision) or 0, beforeSourceGen, beforeRevision)
            return
        end
    end
    NMDeviceState.import(state, args and args.state or nil)
    state._authorityAppliedAtMs = nowRealMs()
    if NMClientSessionProjection and NMClientSessionProjection.markAuthoritativeStateSeen then
        NMClientSessionProjection.markAuthoritativeStateSeen(state, args and args.serverSessionToken, traceUuid)
    end
    local cacheEntry = traceUuid ~= "" and NMClientWorldSourceCache and NMClientWorldSourceCache.get and NMClientWorldSourceCache.get(traceUuid) or nil
    if cacheEntry then
        local exportedState = NMDeviceState.export(state)
        local acceptedGen = math.max(
            tonumber(cacheEntry._acceptedSourceGeneration) or 0,
            tonumber(cacheEntry.sourceEpoch) or 0,
            tonumber(cacheEntry.sourceGeneration) or 0,
            tonumber(cacheEntry.stateSnapshot and cacheEntry.stateSnapshot.sourceGeneration) or 0,
            tonumber(cacheEntry._canonicalSourceGeneration) or 0,
            tonumber(state.sourceGeneration) or 0
        )
        local canApplyIdentity = (incomingSourceGen > acceptedGen) or rebindReason ~= ""
        local mergedGen = math.max(
            acceptedGen,
            incomingSourceGen,
            tonumber(exportedState and exportedState.sourceGeneration) or 0
        )
        state.sourceGeneration = math.max(tonumber(state.sourceGeneration) or 0, mergedGen)
        exportedState = NMDeviceState.export(state)
        cacheEntry._acceptedSourceGeneration = mergedGen
        cacheEntry._canonicalSourceGeneration = math.max(tonumber(cacheEntry._canonicalSourceGeneration) or 0, mergedGen)
        cacheEntry.sourceEpoch = mergedGen
        cacheEntry.sourceGeneration = mergedGen
        cacheEntry._authorityVehicleIdHint = tostring(args and args.vehicleIdHint or args and args.vehicleId or cacheEntry._authorityVehicleIdHint or "")
        if tostring(args and args.vehicleSqlIdHint or args and args.vehicleSqlId or "") ~= "" then
            cacheEntry._authorityVehicleSqlIdHint = tostring(args and args.vehicleSqlIdHint or args and args.vehicleSqlId or cacheEntry._authorityVehicleSqlIdHint or "")
        end
        cacheEntry._authorityPartIdHint = tostring(args and args.partId or cacheEntry._authorityPartIdHint or "Radio")
        cacheEntry._authorityOwnerIdHint = tostring(args and args.ownerId or cacheEntry._authorityOwnerIdHint or "")
        cacheEntry.ownerId = tostring(args and args.ownerId or cacheEntry.ownerId or "")
        cacheEntry.vehicleIdHint = tostring(args and args.vehicleIdHint or cacheEntry.vehicleIdHint or cacheEntry._authorityVehicleIdHint or "")
        if tostring(args and args.vehicleSqlIdHint or "") ~= "" then
            cacheEntry.vehicleSqlIdHint = tostring(args and args.vehicleSqlIdHint or cacheEntry.vehicleSqlIdHint or cacheEntry._authorityVehicleSqlIdHint or "")
        end
        cacheEntry.rebindReason = rebindReason ~= "" and rebindReason or nil
        if canApplyIdentity and cacheEntry._authorityVehicleIdHint ~= "" then
            cacheEntry.vehicleId = tostring(cacheEntry._authorityVehicleIdHint)
            cacheEntry.vehicleSqlId = tostring(cacheEntry._authorityVehicleSqlIdHint or cacheEntry.vehicleSqlId or "")
            cacheEntry.partId = tostring(cacheEntry._authorityPartIdHint or cacheEntry.partId or "Radio")
        end
        cacheEntry.sourceMode = tostring(args and args.sourceMode or cacheEntry.sourceMode or "vehicle")
        cacheEntry.stateSnapshot = exportedState
        if cacheEntry.stateSnapshot then
            cacheEntry.stateSnapshot.sourceGeneration = mergedGen
        end
        cacheEntry.source = cacheEntry.source or {}
        cacheEntry.source.mode = "world"
        cacheEntry.source.context = tostring(args and args.sourceMode or cacheEntry.source.context or "vehicle")
        if cacheEntry.source.x == nil then
            cacheEntry.source.x = tonumber(state and state.sourceX) or 0
        end
        if cacheEntry.source.y == nil then
            cacheEntry.source.y = tonumber(state and state.sourceY) or 0
        end
        if cacheEntry.source.z == nil then
            cacheEntry.source.z = tonumber(state and state.sourceZ) or 0
        end
        cacheEntry.source.vehicleId = tostring(cacheEntry.vehicleId or cacheEntry._authorityVehicleIdHint or cacheEntry.source.vehicleId or "")
        cacheEntry.source.vehicleIdHint = tostring(cacheEntry.vehicleIdHint or cacheEntry.source.vehicleIdHint or cacheEntry.source.vehicleId or "")
        cacheEntry.source.vehicleSqlId = tostring(cacheEntry.vehicleSqlId or cacheEntry._authorityVehicleSqlIdHint or cacheEntry.source.vehicleSqlId or "")
        cacheEntry.source.vehicleSqlIdHint = tostring(cacheEntry.vehicleSqlIdHint or cacheEntry.source.vehicleSqlIdHint or cacheEntry.source.vehicleSqlId or "")
        cacheEntry.source.ownerId = tostring(cacheEntry.ownerId or cacheEntry.source.ownerId or "")
        if cacheEntry.source.windowsOpen == nil and args and args.windowsOpen ~= nil then
            cacheEntry.source.windowsOpen = args.windowsOpen == true
        end
        if cacheEntry.source._vehicleResolved == nil then
            cacheEntry.source._vehicleResolved = false
        end
        if cacheEntry.source.vehicleResolved == nil then
            cacheEntry.source.vehicleResolved = false
        end
        if cacheEntry._vehicleSourceResolved == nil then
            cacheEntry._vehicleSourceResolved = false
        end
        if cacheEntry._vehicleResolutionMode == nil then
            cacheEntry._vehicleResolutionMode = "stream_authority_unresolved"
        end
        logSqlAnchorLineage(traceUuid, cacheEntry, "client_state_apply", "authoritative_vehicle_apply")
        NMClientWorldSourceCache.entries[traceUuid] = cacheEntry
    end
    logApplyOkDedup(
        "vehicle",
        table.concat({
            tostring(traceUuid),
            tostring(state.sourceGeneration or 0),
            tostring(state.revision or 0),
            tostring(state.playbackEpoch or 0),
            tostring(state.trackIndex or 0),
            tostring(state.isOn == true),
            tostring(state.isPlaying == true),
            tostring(args and args.vehicleSqlId or "")
        }, "|"),
        "kind=vehicle vehicleId="
            .. tostring(args and args.vehicleId or "nil")
            .. " vehicleSqlId="
            .. tostring(args and args.vehicleSqlId or "nil")
            .. " partId="
            .. tostring(partId)
            .. " isOn="
            .. tostring(state.isOn == true)
            .. " isPlaying="
            .. tostring(state.isPlaying == true)
            .. " media="
            .. tostring(state.mediaFullType or "nil"),
        NMRuntimeProbeAdapter.shortHeartbeatMs()
    )
    if args and args.sourceMode then
        local mode = tostring(args.sourceMode or "unknown")
        local uuid = tostring(traceUuid or args.uuid or "nil")
        local ackKey = table.concat({ "vehicle", uuid, mode }, "|")
        local sig = table.concat({ "vehicle", tostring(state.sourceGeneration or 0), tostring(state.revision or 0), mode }, "|")
        if NMRuntimeProbeAdapter.shouldEmitTransitionOrHeartbeat(modeAckSigSeen, modeAckSeen, ackKey, sig, NMRuntimeProbeAdapter.shortHeartbeatMs()) then
            logApplyResult(
                "mode_sync_ack",
                "kind=vehicle vehicleId=" .. tostring(args.vehicleId or "nil") .. " sourceMode=" .. tostring(args.sourceMode)
            )
        end
    end
    local afterMode = tostring(state.authoritativeMode or "")
    local afterSourceGen = tonumber(state.sourceGeneration) or 0
    local afterIsOn = state.isOn == true
    local afterIsPlaying = state.isPlaying == true
    local afterVehicleId = tostring(state.sourceVehicleId or args and args.vehicleId or "")
    local afterVehicleSqlId = tostring(args and args.vehicleSqlId or "")
    if traceUuid ~= ""
        and (
            beforeMode ~= afterMode
            or beforeSourceGen ~= afterSourceGen
            or beforeIsOn ~= afterIsOn
            or beforeIsPlaying ~= afterIsPlaying
            or beforeVehicleId ~= afterVehicleId
        ) then
        logVehicleRebindTrace(
            "authority_flip",
            traceUuid,
            string.format(
                "vehicleId=%s->%s mode=%s->%s sourceGen=%s->%s isOn=%s->%s isPlaying=%s->%s partId=%s",
                tostring(beforeVehicleId ~= "" and beforeVehicleId or "nil"),
                tostring(afterVehicleId ~= "" and afterVehicleId or "nil"),
                tostring(beforeMode),
                tostring(afterMode),
                tostring(beforeSourceGen),
                tostring(afterSourceGen),
                tostring(beforeIsOn),
                tostring(afterIsOn),
                tostring(beforeIsPlaying),
                tostring(afterIsPlaying),
                tostring(partId)
            )
        )
    end
    if traceUuid ~= "" and beforeVehicleSqlId ~= afterVehicleSqlId then
        logVehicleRebindTrace(
            "vehicle_id_stability",
            traceUuid,
            string.format(
                "runtimeVehicleId=%s runtimeVehicleIdAfter=%s sqlId=%s sqlIdAfter=%s sourceGen=%s",
                tostring(beforeVehicleId ~= "" and beforeVehicleId or "nil"),
                tostring(afterVehicleId ~= "" and afterVehicleId or "nil"),
                tostring(beforeVehicleSqlId ~= "" and beforeVehicleSqlId or "nil"),
                tostring(afterVehicleSqlId ~= "" and afterVehicleSqlId or "nil"),
                tostring(afterSourceGen)
            )
        )
    end
    if beforeMode ~= afterMode then
        logApplyResult(
            "client_state_authority_delta",
            "kind=vehicle vehicleId="
                .. tostring(args and args.vehicleId or "nil")
                .. " mode="
                .. tostring(beforeMode)
                .. "->"
                .. tostring(afterMode)
                .. " sourceGen="
                .. tostring(beforeSourceGen)
                .. "->"
                .. tostring(afterSourceGen)
        )
    end
    logRehydrateApplySummary(
        "vehicle",
        "applied",
        args,
        state,
        incomingSourceGen,
        tonumber(args and args.state and args.state.revision) or 0,
        beforeSourceGen,
        beforeRevision
    )
    requestFreshRegistryAfterApply(args, state)
end

function NMClientStateSync.onServerState(player, args)
    if not (args and type(args) == "table" and args.state and type(args.state) == "table") then
        return
    end
    if NMClientSessionProjection and NMClientSessionProjection.observeServerSessionToken then
        NMClientSessionProjection.observeServerSessionToken(args.serverSessionToken, "state")
    end
    if args.vehicleId ~= nil or args.vehicleSqlId ~= nil or args.vehicleSqlIdHint ~= nil then
        applyVehicleState(args)
        return
    end
    applyItemState(player, args)
end

