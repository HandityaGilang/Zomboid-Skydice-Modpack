-- Unified server-authoritative pipeline for MP item intents.

NMServerItemIntentPipeline = NMServerItemIntentPipeline or {}
local ItemIntentValidation = NMServerItemIntentValidation
NMServerItemIntentPipeline._progressionHintSig = NMServerItemIntentPipeline._progressionHintSig or {}
NMServerItemIntentPipeline._acceptedTrackFinishedToken = NMServerItemIntentPipeline._acceptedTrackFinishedToken or {}

local function isSyncAction(action)
    local name = tostring(action or "")
    return name == "sync_attached_world"
        or name == "sync_placed_world"
        or name == "sync_inventory_stowed"
        or name == "sync_portable_attached"
        or name == "sync_portable_placed"
        or name == "sync_portable_stowed"
end

local function isTransportAction(action)
    local name = tostring(action or "")
    return name == "toggle_play"
        or name == "start_playback"
        or name == "stop_playback"
end

local function mapActionToReducerEvent(action)
    local name = tostring(action or "")
    if not (NMServerCanonicalReducer and NMServerCanonicalReducer.Event) then
        return nil
    end
    if name == "start_playback" then
        return NMServerCanonicalReducer.Event.INTENT_START
    end
    if name == "stop_playback" then
        return NMServerCanonicalReducer.Event.INTENT_STOP
    end
    if name == "toggle_play" then
        return NMServerCanonicalReducer.Event.INTENT_TOGGLE
    end
    if name == "next_track" then
        return NMServerCanonicalReducer.Event.INTENT_NEXT
    end
    if name == "prev_track" then
        return NMServerCanonicalReducer.Event.INTENT_PREV
    end
    if name == "track_finished" then
        return NMServerCanonicalReducer.Event.HINT_TRACK_FINISHED
    end
    return nil
end

local function isPlaybackEpochAction(action)
    local name = tostring(action or "")
    return name == "toggle_play"
        or name == "start_playback"
        or name == "stop_playback"
        or name == "next_track"
        or name == "prev_track"
        or name == "set_playback_mode"
        or name == "power_on"
        or name == "power_off"
        or name == "toggle_power"
        or name == "track_finished"
end

local function logIntent(tag, detail)
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("intent") then
        NMCore.logChannel("intent", tag, detail)
    end
end

local function logRuntime(tag, detail)
    NMRuntimeProbeAdapter.emit("runtimeProbe", "runtimeProbe", tag, detail)
end

local function hasWorldSquare(item)
    local worldItem = item and item.getWorldItem and item:getWorldItem() or nil
    local square = worldItem and worldItem.getSquare and worldItem:getSquare() or nil
    return square ~= nil, square
end

local function isItemAttachedToPlayer(player, item, uuid)
    if not (player and item) then
        return false
    end
    local itemId = NMInventoryHelpers.getItemIdString(item)
    local stateUuid = tostring(uuid or "")

    local primary = player.getPrimaryHandItem and player:getPrimaryHandItem() or nil
    if NMAttachmentHelpers.itemMatchesTarget(primary, itemId, item, stateUuid) then
        return true
    end
    local secondary = player.getSecondaryHandItem and player:getSecondaryHandItem() or nil
    if NMAttachmentHelpers.itemMatchesTarget(secondary, itemId, item, stateUuid) then
        return true
    end

    local attachedItems = player.getAttachedItems and player:getAttachedItems() or nil
    if attachedItems then
        for i = 0, attachedItems:size() - 1 do
            local entry = attachedItems:get(i)
            local attachedItem = entry and entry.getItem and entry:getItem() or nil
            if NMAttachmentHelpers.itemMatchesTarget(attachedItem, itemId, item, stateUuid) then
                return true
            end
        end
    end

    return NMAttachmentHelpers.isItemWornOnBack(player, itemId, item, stateUuid)
end

local function continuityActive(state)
    if not state then
        return false
    end
    return NMRegistryPolicy.isWorldSyncStateActive(state)
        or tostring(state.playbackMode or "") == "world"
end

local function deriveServerSourceMode(player, item, profile, state, hintedMode)
    local hasSquare = hasWorldSquare(item)
    if hasSquare then
        if NMDeviceProfiles.canPlacedWorldPlayback(profile) or NMDeviceProfiles.isPortableTrackedProfile(profile) then
            return "placed"
        end
        return "off"
    end

    local attached = isItemAttachedToPlayer(player, item, state and state.deviceUUID)
    if attached then
        return "attached"
    end

    local hint = tostring(hintedMode or "")
    if hint == "attached" or hint == "stowed" then
        return hint
    end

    local container = item and item.getContainer and item:getContainer() or nil
    if container then
        return "stowed"
    end
    return "off"
end

local function buildAuthorityContext(player, item, profile, mode)
    local context = {}
    local ownerOnline = player and player.getOnlineID and tostring(player:getOnlineID() or "") or ""
    local ownerName = player and player.getUsername and tostring(player:getUsername() or "") or ""
    local ownerId = ownerOnline ~= "" and ownerOnline or ownerName
    local hasSquare, square = hasWorldSquare(item)
    if mode == "placed" and hasSquare then
        context.sourceX = square:getX() + 0.5
        context.sourceY = square:getY() + 0.5
        context.sourceZ = square:getZ()
        if NMDeviceProfiles.isPortableTrackedProfile(profile) then
            context.sourceOwner = ownerId
        else
            context.sourceOwner = NMCore.itemId and tostring(NMCore.itemId(item) or "") or ""
        end
    else
        context.sourceX = player and player.getX and tonumber(player:getX()) or nil
        context.sourceY = player and player.getY and tonumber(player:getY()) or nil
        context.sourceZ = player and player.getZ and tonumber(player:getZ()) or nil
        context.sourceOwner = ownerId
    end
    return context
end

local function mapModeToAuthorityIntent(mode)
    if mode == "attached" then
        return "request_attached"
    end
    if mode == "placed" then
        return "request_placed"
    end
    if mode == "stowed" then
        return "request_stowed"
    end
    return "request_off"
end

local function applyAuthorityFromMode(player, item, profile, state, mode)
    local authority = NMAuthorityV4 or NMAuthorityV3
    if not (authority and authority.applyIntent and state) then
        return false
    end

    local beforeMode = tostring(state.authoritativeMode or "off")
    local beforeGen = tonumber(state.sourceGeneration) or 0

    local intent = mapModeToAuthorityIntent(mode)
    authority.applyIntent(state, intent, buildAuthorityContext(player, item, profile, mode))

    local afterMode = tostring(state.authoritativeMode or "off")
    local afterGen = tonumber(state.sourceGeneration) or 0
    return beforeMode ~= afterMode or beforeGen ~= afterGen
end

local function ensureRegistryEntry(item, profile, state, sourceMode)
    if not item or not profile or not state or not state.deviceUUID then
        return nil
    end
    local _, square = hasWorldSquare(item)
    local x = square and (square:getX() + 0.5) or tonumber(state.sourceX)
    local y = square and (square:getY() + 0.5) or tonumber(state.sourceY)
    local z = square and square:getZ() or tonumber(state.sourceZ)
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    if z == nil then z = 0 end
    local owner = tostring(state.sourceOwner or "")
    local ownerOnlineId = ""
    local ownerUsername = ""
    if owner ~= "" then
        if owner:match("^%-?%d+$") then
            ownerOnlineId = owner
        else
            ownerUsername = owner
        end
    end
    local entry = {
        kind = "item",
        uuid = tostring(state.deviceUUID),
        itemId = tostring(item:getID() or ""),
        itemFullType = tostring(item:getFullType() or ""),
        profileType = tostring(profile.fullType or item:getFullType() or ""),
        x = x,
        y = y,
        z = z,
        sourceMode = tostring(sourceMode or "off"),
        sourceEpoch = tonumber(state.sourceGeneration) or 0,
        sourceRebind = false,
        ownerId = owner,
        ownerOnlineId = ownerOnlineId,
        ownerUsername = ownerUsername,
        stateSnapshot = NMDeviceState.export(state)
    }
    NMServerRegistryState.worldRegistry[entry.uuid] = entry
    return entry
end

local function sendState(player, item, state, sourceMode)
    if not player or not item or not state or not sendServerCommand then
        return
    end
    local mode = tostring(sourceMode or "")
    if mode == "" then
        mode = "off"
    end
    sendServerCommand(player, NMCore.NetModule, "state", {
        itemId = tostring(item:getID() or ""),
        uuid = tostring(state.deviceUUID or ""),
        itemFullType = tostring(item:getFullType() or ""),
        sourceMode = mode,
        ownerId = tostring(state.sourceOwner or ""),
        state = NMDeviceState.export(state),
        serverSessionToken = NMServerBootReset and NMServerBootReset.getSessionToken and NMServerBootReset.getSessionToken() or nil
    })
end

local function broadcastObserverState(originPlayer, item, state, sourceMode, actionName)
    if not item or not state or not sendServerCommand then
        return 0
    end
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then
        return 0
    end

    local mode = tostring(sourceMode or "")
    if mode == "" then
        mode = "off"
    end

    local originOnlineId = originPlayer and originPlayer.getOnlineID and tostring(originPlayer:getOnlineID() or "") or ""
    local originUsername = originPlayer and originPlayer.getUsername and tostring(originPlayer:getUsername() or "") or ""
    local payload = {
        itemId = tostring(item:getID() or ""),
        uuid = tostring(state.deviceUUID or ""),
        itemFullType = tostring(item:getFullType() or ""),
        sourceMode = mode,
        ownerId = tostring(state.sourceOwner or ""),
        state = NMDeviceState.export(state),
        serverSessionToken = NMServerBootReset and NMServerBootReset.getSessionToken and NMServerBootReset.getSessionToken() or nil
    }

    local sent = 0
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p then
            local targetOnlineId = p.getOnlineID and tostring(p:getOnlineID() or "") or ""
            local targetUsername = p.getUsername and tostring(p:getUsername() or "") or ""
            local samePlayer = false
            if originOnlineId ~= "" and targetOnlineId ~= "" then
                samePlayer = originOnlineId == targetOnlineId
            elseif originUsername ~= "" and targetUsername ~= "" then
                samePlayer = originUsername == targetUsername
            end
            if not samePlayer then
                sendServerCommand(p, NMCore.NetModule, "state", payload)
                sent = sent + 1
            end
        end
    end

    if sent > 0 and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        NMCore.logChannel(
            "runtimeProbe",
            "server_item_state_observer_broadcast",
            string.format(
                "action=%s count=%s itemId=%s uuid=%s media=%s",
                tostring(actionName or "unknown"),
                tostring(sent),
                tostring(payload.itemId or ""),
                tostring(payload.uuid or ""),
                tostring(state and state.mediaFullType or "nil")
            )
        )
    end

    return sent
end

local function logProgression(tag, key, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")) then
        return
    end
    local sigKey = tostring(key or "")
    if sigKey ~= "" then
        if tostring(NMServerItemIntentPipeline._progressionHintSig[sigKey] or "") == tostring(detail or "") then
            return
        end
        NMServerItemIntentPipeline._progressionHintSig[sigKey] = tostring(detail or "")
    end
    NMCore.logChannel("progressionProbe", tostring(tag or "progression"), tostring(detail or ""))
end

local function resolveTrackFinishedHintMinAgeMs()
    local minAge = tonumber(
        NMRuntimeConfig and NMRuntimeConfig.get and NMRuntimeConfig.get("serverVehicleTrackHintMinAgeMs", 5000)
        or 5000
    ) or 5000
    return math.max(0, math.floor(minAge + 0.5))
end

local function resolveStartedAtForHint(state)
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

local function shouldGateWorldTrackFinished(ctx, action)
    if tostring(action or "") ~= "track_finished" then
        return false
    end
    if not (NMCore and NMCore.isMPServerAuthority and NMCore.isMPServerAuthority()) then
        return false
    end
    return tostring(ctx and ctx.state and ctx.state.playbackMode or "") == "world"
end

local function validateExpectedToken(state, args)
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

local function broadcastEntry(entry, state, op)
    local function recipients(applyFn)
        local players = getOnlinePlayers and getOnlinePlayers() or nil
        if not players then return end
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            if p then applyFn(p) end
        end
    end
    NMServerRegistryBroadcast.broadcastEntry(NMServerRegistryState.worldRegistry, tostring(entry.uuid), nil, state, op, recipients)
end

local function resolveTarget(player, args)
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

local function applyObservedDurationHint(state, args)
    if type(state) ~= "table" then
        return false, nil
    end
    local observed = tonumber(args and args.observedDurationMs) or 0
    if observed <= 0 then
        return false, nil
    end
    local clamped = math.max(1000, math.floor(observed + 0.5))
    local idx = math.max(1, math.floor(tonumber(state.trackIndex) or 1))
    state.observedTrackDurationHints = state.observedTrackDurationHints or {}
    state.observedTrackDurationHints[idx] = clamped
    return true, clamped
end

local function reconcileHeadphoneWearState(player, profile, state, actionName, sourceMode)
    if not (player and profile and state and NMDeviceProfiles.supportsHeadphones(profile)) then
        return false
    end
    local action = tostring(actionName or "")
    local current = tostring(state.headphoneItemFullType or "")
    local mode = tostring(sourceMode or state.authoritativeMode or "")
    if NMInsertedHeadphonePolicy
        and NMInsertedHeadphonePolicy.isGroundContext(mode)
        and NMInsertedHeadphonePolicy.shouldDetachOnGround(current) then
        state.headphoneItemFullType = nil
        return true
    end
    local worn = NMAttachmentHelpers.findWornHeadphones and NMAttachmentHelpers.findWornHeadphones(player) or nil
    local wearingHeadphones = worn ~= nil

    if current == "" and wearingHeadphones and worn and worn.getFullType then
        local wornFullType = tostring(worn:getFullType() or "")
        if NMInsertedHeadphonePolicy
            and NMInsertedHeadphonePolicy.canAutoReattachFromAvatar(wornFullType)
            and not (NMInsertedHeadphonePolicy.isGroundContext(mode)) then
            state.headphoneItemFullType = wornFullType
            return true
        end
    end
    if NMInsertedHeadphonePolicy
        and NMInsertedHeadphonePolicy.canAutoReattachFromAvatar(current)
        and (not wearingHeadphones)
        and action ~= "insert_headphones" then
        state.headphoneItemFullType = nil
        if profile.requiresHeadphones then
            NMTransitionCommon.setStopped(state, "headphones_removed")
        end
        return true
    end
    return false
end

local function importCanonicalIfNewer(ctx)
    if not (ctx and ctx.state and ctx.state.deviceUUID and NMServerRegistryState and NMServerRegistryState.worldRegistry) then
        return false
    end
    local uuid = tostring(ctx.state.deviceUUID or "")
    if uuid == "" then
        return false
    end
    local entry = NMServerRegistryState.worldRegistry[uuid]
    local canonical = entry and entry.stateSnapshot or nil
    if type(canonical) ~= "table" then
        return false
    end

    local localGen = tonumber(ctx.state.sourceGeneration) or 0
    local localRev = tonumber(ctx.state.revision) or 0
    local localEpoch = tonumber(ctx.state.playbackEpoch) or 0
    local canonicalGen = tonumber(canonical.sourceGeneration) or 0
    local canonicalRev = tonumber(canonical.revision) or 0
    local canonicalEpoch = tonumber(canonical.playbackEpoch) or 0

    local newer = false
    if canonicalGen > localGen then
        newer = true
    elseif canonicalGen == localGen and canonicalRev > localRev then
        newer = true
    elseif canonicalGen == localGen and canonicalRev == localRev and canonicalEpoch > localEpoch then
        newer = true
    end

    if not newer then
        return false
    end

    NMDeviceState.import(ctx.state, canonical)
    logRuntime(
        "server_item_canonical_refresh_before_intent",
        string.format(
            "uuid=%s localGen=%s localRev=%s localEpoch=%s canonicalGen=%s canonicalRev=%s canonicalEpoch=%s",
            tostring(uuid),
            tostring(localGen),
            tostring(localRev),
            tostring(localEpoch),
            tostring(canonicalGen),
            tostring(canonicalRev),
            tostring(canonicalEpoch)
        )
    )
    return true
end

local function hydrateTimelineFromCanonical(ctx)
    if not (ctx and ctx.state and ctx.state.deviceUUID and NMServerRegistryState and NMServerRegistryState.worldRegistry) then
        return false
    end
    local uuid = tostring(ctx.state.deviceUUID or "")
    if uuid == "" then
        return false
    end
    local entry = NMServerRegistryState.worldRegistry[uuid]
    local canonical = entry and entry.stateSnapshot or nil
    if type(canonical) ~= "table" then
        return false
    end
    local localStarted = tonumber(ctx.state.serverTrackStartedAtMs) or 0
    local canonicalStarted = tonumber(canonical.serverTrackStartedAtMs) or 0
    if localStarted > 0 or canonicalStarted <= 0 then
        return false
    end
    ctx.state.serverTrackStartedAtMs = canonical.serverTrackStartedAtMs
    ctx.state.serverTrackDurationMs = canonical.serverTrackDurationMs
    ctx.state.serverTrackDueAtMs = canonical.serverTrackDueAtMs
    ctx.state._serverTrackTimingMode = canonical._serverTrackTimingMode
    ctx.state._serverTrackArmToken = canonical._serverTrackArmToken
    logRuntime(
        "server_item_timeline_hydrated_from_registry",
        string.format(
            "uuid=%s startedAtMs=%s dueAtMs=%s timingMode=%s",
            tostring(uuid),
            tostring(ctx.state.serverTrackStartedAtMs or 0),
            tostring(ctx.state.serverTrackDueAtMs or 0),
            tostring(ctx.state._serverTrackTimingMode or "")
        )
    )
    return true
end

local function buildPayload(ctx)
    local args = ctx.args or {}
    local inv = ctx.inventory
    local payload = {
        isOn = args.isOn,
        isPlaying = args.isPlaying,
        volume = args.volume,
        playbackMode = args.playbackMode,
        playbackPolicy = args.playbackPolicy,
        observedDurationMs = args.observedDurationMs,
        mediaItemId = args.mediaItemId,
        headphoneItemId = args.headphoneItemId,
        batteryItemId = args.batteryItemId,
        mediaFullType = nil,
        mediaCarrier = nil,
        mediaEjectFullType = nil,
        mediaCanonicalFullType = nil,
        mediaRecordedMediaIndex = nil,
        mediaDisplayName = nil,
        headphoneItemFullType = nil,
        batteryCharge = nil,
        externalPowerAvailable = NMInventoryHelpers.resolveExternalPowerAvailable(ctx.player, ctx.item, ctx.profile),
        trackCount = tonumber(args.trackCount) or 0,
        hasTrack = (tonumber(args.trackCount) or 0) > 0
    }

    if inv and args.mediaItemId then
        local media = NMInventoryHelpers.findItemById(inv, args.mediaItemId)
        local mediaPayload = NMMediaHelpers.resolveMediaInsertPayload(media)
        if mediaPayload then
            payload.mediaFullType = mediaPayload.mediaFullType
            payload.mediaItemFullType = mediaPayload.mediaEjectFullType or mediaPayload.mediaFullType
            payload.mediaCarrier = mediaPayload.mediaCarrier
            payload.mediaEjectFullType = mediaPayload.mediaEjectFullType
            payload.mediaCanonicalFullType = mediaPayload.mediaCanonicalFullType
            payload.mediaRecordedMediaIndex = mediaPayload.mediaRecordedMediaIndex
            payload.mediaDisplayName = mediaPayload.mediaDisplayName
        end
    end
    payload.requiredMediaFullType = NMMediaContract
        and NMMediaContract.resolveContainerMediaBinding
        and NMMediaContract.resolveContainerMediaBinding(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or nil)
        or nil

    if inv and args.headphoneItemId then
        local hp = NMInventoryHelpers.findItemById(inv, args.headphoneItemId)
        if hp and hp.getFullType then
            payload.headphoneItemFullType = hp:getFullType()
        end
    end
    if inv and args.batteryItemId then
        local bat = NMInventoryHelpers.findItemById(inv, args.batteryItemId)
        payload.batteryCharge = NMCore.readDrainableFraction(bat, 0.0)
    end
    return payload
end

local function replicateNormalizedItemMove(meta, liveItem)
    if not (meta and meta.moved == true and liveItem) then
        return
    end
    local sourceItem = meta.sourceItem or liveItem
    local targetItem = meta.targetItem or liveItem
    if sendRemoveItemFromContainer and meta.sourceContainer and sourceItem then
        sendRemoveItemFromContainer(meta.sourceContainer, sourceItem)
    end
    if sendAddItemToContainer and meta.targetContainer and targetItem then
        sendAddItemToContainer(meta.targetContainer, targetItem)
    end
end

local function normalizeIngressArgsToMainInventory(player, args, action)
    local act = tostring(action or (args and args.action) or "")
    local spec = nil
    if act == "insert_headphones" then
        spec = { idKey = "headphoneItemId", uuidKey = "headphoneItemUuid" }
    elseif act == "insert_media" then
        spec = { idKey = "mediaItemId", uuidKey = "mediaItemUuid" }
    elseif act == "insert_battery" then
        spec = { idKey = "batteryItemId", uuidKey = "batteryItemUuid" }
    end
    if not spec then
        return true, nil
    end
    if not (NMInventoryHelpers and NMInventoryHelpers.normalizeItemToMainInventory) then
        return false, "normalize_helper_missing"
    end
    local liveItem, err, meta = NMInventoryHelpers.normalizeItemToMainInventory(player, args and args[spec.idKey], args and args[spec.uuidKey])
    if not liveItem then
        return false, err or "normalize_failed"
    end
    args[spec.idKey] = NMCore.itemId(liveItem)
    if spec.uuidKey then
        args[spec.uuidKey] = NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(liveItem) or nil
    end
    replicateNormalizedItemMove(meta, liveItem)
    return true, nil
end

local function removeItemById(inventory, itemId)
    local id = tostring(itemId or "")
    if not inventory or id == "" then
        return false, "invalid_remove_args", nil, nil
    end
    local item = NMInventoryHelpers.findItemById(inventory, id)
    if not item then
        return false, "source_item_not_found", nil, nil
    end
    local container = item.getContainer and item:getContainer() or nil
    if container and container.DoRemoveItem then
        container:DoRemoveItem(item)
        return true, nil, container, item
    end
    if inventory.Remove then
        inventory:Remove(item)
        return true, nil, inventory, item
    end
    return false, "source_remove_failed", nil, nil
end

local function resolveOwningContainer(item, fallbackInventory)
    local container = item and item.getContainer and item:getContainer() or nil
    if container and container.DoRemoveItem and container.AddItem then
        return container
    end
    return fallbackInventory
end

local function addItemByFullType(inventory, fullType)
    if not inventory or not inventory.AddItem then
        return nil, "missing_inventory_add", nil
    end
    local typeName = tostring(fullType or "")
    if typeName == "" then
        return nil, "missing_item_type", nil
    end
    local item, err = NMWorldItemVisuals.addItemWithVisual(inventory, typeName)
    if not item then
        return nil, err or "add_item_failed", nil
    end
    return item, nil, inventory
end

local function setDrainableFraction(item, fraction)
    local value = NMCore.clamp(tonumber(fraction) or 0.0, 0.0, 1.0)
    if item and item.setCurrentUsesFloat then
        local ok = pcall(item.setCurrentUsesFloat, item, value)
        if ok then return true end
    end
    if item and item.setUsedDelta then
        local ok = pcall(item.setUsedDelta, item, value)
        if ok then return true end
    end
    if item and item.setDelta then
        local ok = pcall(item.setDelta, item, value)
        if ok then return true end
    end
    return false
end

local function setRecordedMediaIndex(item, index)
    local value = tonumber(index)
    if not item or value == nil or value < 0 then
        return false
    end
    if item.setRecordedMediaIndex then
        local ok = pcall(item.setRecordedMediaIndex, item, value)
        if ok then return true end
    end
    if item.setRecordedMediaIndexInteger then
        local ok = pcall(item.setRecordedMediaIndexInteger, item, value)
        if ok then return true end
    end
    return false
end

local function countItemIdInContainer(container, itemId)
    local id = tostring(itemId or "")
    if not container or id == "" then
        return 0
    end
    local items = container.getItems and container:getItems() or nil
    if not items then
        return 0
    end
    local count = 0
    for i = 0, items:size() - 1 do
        local entry = items:get(i)
        if entry and tostring(entry:getID() or "") == id then
            count = count + 1
        end
    end
    return count
end

local function logContainerDupGuard(kind, stage, container, item)
    local itemId = item and tostring(item:getID() or "") or ""
    if itemId == "" then
        return
    end
    local duplicateCount = countItemIdInContainer(container, itemId)
    if duplicateCount > 1 then
        logRuntime(
            "server_ops_container_dup_guard",
            string.format(
                "kind=%s stage=%s itemId=%s duplicates=%d containerType=%s",
                tostring(kind or "unknown"),
                tostring(stage or "unknown"),
                tostring(itemId),
                tonumber(duplicateCount) or 0,
                tostring(container and container.getType and container:getType() or "unknown")
            )
        )
    end
end

local function applyTransitionOps(player, inventory, ops)
    if not ops then
        return false, nil
    end
    local applied = false
    local failures = {}

    if ops.wearHeadphoneItemId then
        local ok, err = false, "wear_helper_missing"
        if NMAttachmentHelpers.equipHeadphonesByItemId then
            ok, err = NMAttachmentHelpers.equipHeadphonesByItemId(player, ops.wearHeadphoneItemId)
        end
        if ok then
            applied = true
        else
            failures[#failures + 1] = "wear_headphones:" .. tostring(err)
        end
    end
    if ops.unequipHeadphones then
        local ok, err = false, "unequip_helper_missing"
        if NMAttachmentHelpers.unequipWornHeadphones then
            ok, err = NMAttachmentHelpers.unequipWornHeadphones(player)
        end
        if ok then
            applied = true
        else
            failures[#failures + 1] = "unequip_headphones:" .. tostring(err)
        end
    end

    if ops.consumeMediaItemId then
        local ok, err, container, consumed = removeItemById(inventory, ops.consumeMediaItemId)
        if ok then
            applied = true
            if sendRemoveItemFromContainer and container and consumed then
                logContainerDupGuard("media", "before_remove_replica", container, consumed)
                sendRemoveItemFromContainer(container, consumed)
                logRuntime("server_ops_remove_replica", "kind=media itemId=" .. tostring(ops.consumeMediaItemId))
            end
        else
            failures[#failures + 1] = "consume_media:" .. tostring(err)
        end
    end
    if ops.consumeHeadphoneItemId then
        local ok, err, container, consumed = removeItemById(inventory, ops.consumeHeadphoneItemId)
        if ok then
            applied = true
            if sendRemoveItemFromContainer and container and consumed then
                logContainerDupGuard("headphones", "before_remove_replica", container, consumed)
                sendRemoveItemFromContainer(container, consumed)
                logRuntime("server_ops_remove_replica", "kind=headphones itemId=" .. tostring(ops.consumeHeadphoneItemId))
            end
        else
            failures[#failures + 1] = "consume_headphones:" .. tostring(err)
        end
    end
    if ops.consumeBatteryItemId then
        local ok, err, container, consumed = removeItemById(inventory, ops.consumeBatteryItemId)
        if ok then
            applied = true
            if sendRemoveItemFromContainer and container and consumed then
                logContainerDupGuard("battery", "before_remove_replica", container, consumed)
                sendRemoveItemFromContainer(container, consumed)
                logRuntime("server_ops_remove_replica", "kind=battery itemId=" .. tostring(ops.consumeBatteryItemId))
            end
        else
            failures[#failures + 1] = "consume_battery:" .. tostring(err)
        end
    end

    if ops.produceMediaFullType then
        local out, err, container = addItemByFullType(inventory, ops.produceMediaFullType)
        if out then
            setRecordedMediaIndex(out, ops.produceMediaRecordedMediaIndex)
            applied = true
            if sendAddItemToContainer and container then
                logContainerDupGuard("media", "before_add_replica", container, out)
                sendAddItemToContainer(container, out)
                logContainerDupGuard("media", "after_add_replica", container, out)
                logRuntime("server_ops_add_replica", "kind=media fullType=" .. tostring(ops.produceMediaFullType))
            end
        else
            failures[#failures + 1] = "produce_media:" .. tostring(err)
        end
    end
    if ops.produceHeadphoneFullType then
        local out, err, container = addItemByFullType(inventory, ops.produceHeadphoneFullType)
        if out then
            applied = true
            if sendAddItemToContainer and container then
                logContainerDupGuard("headphones", "before_add_replica", container, out)
                sendAddItemToContainer(container, out)
                logContainerDupGuard("headphones", "after_add_replica", container, out)
                logRuntime("server_ops_add_replica", "kind=headphones fullType=" .. tostring(ops.produceHeadphoneFullType))
            end
        else
            failures[#failures + 1] = "produce_headphones:" .. tostring(err)
        end
    end
    if ops.produceBatteryCharge ~= nil then
        local out, err, container = addItemByFullType(inventory, "Base.Battery")
        if out then
            setDrainableFraction(out, ops.produceBatteryCharge)
            applied = true
            if sendAddItemToContainer and container then
                logContainerDupGuard("battery", "before_add_replica", container, out)
                sendAddItemToContainer(container, out)
                logContainerDupGuard("battery", "after_add_replica", container, out)
                logRuntime("server_ops_add_replica", "kind=battery charge=" .. tostring(ops.produceBatteryCharge))
            end
        else
            failures[#failures + 1] = "produce_battery:" .. tostring(err)
        end
    end

    if #failures > 0 then
        return applied, table.concat(failures, ";")
    end
    return applied, nil
end

local function maybeSwapContainerVisualVariant(ctx)
    if not (ctx and ctx.item and ctx.profile and ctx.state and ctx.inventory) then
        return false, nil
    end
    if ctx.profile.isMediaContainerOnly ~= true then
        return false, nil
    end

    local currentFullType = tostring(ctx.item.getFullType and ctx.item:getFullType() or "")
    if currentFullType == "" then
        return false, nil
    end
    local wantLoaded = ctx.state.mediaFullType ~= nil
    local targetFullType = NMMediaContract
        and NMMediaContract.resolveContainerSwapFullType
        and NMMediaContract.resolveContainerSwapFullType(currentFullType, wantLoaded)
        or nil
    targetFullType = tostring(targetFullType or "")
    if targetFullType == "" or targetFullType == currentFullType then
        return false, nil
    end

    local ownerContainer = resolveOwningContainer(ctx.item, ctx.inventory)
    if not ownerContainer then
        return false, "container_swap_owner_missing"
    end

    local exportedState = NMDeviceState.export(ctx.state)
    local originalItemId = tostring(ctx.item.getID and ctx.item:getID() or "")
    local removed, removeErr, removeContainer, removedItem = removeItemById(ownerContainer, originalItemId)
    if not removed then
        return false, "container_swap_remove_failed:" .. tostring(removeErr or "unknown")
    end
    if sendRemoveItemFromContainer and removeContainer and removedItem then
        sendRemoveItemFromContainer(removeContainer, removedItem)
    end

    local swappedItem, addErr, addContainer = addItemByFullType(ownerContainer, targetFullType)
    if not swappedItem then
        return false, "container_swap_add_failed:" .. tostring(addErr or "unknown")
    end
    if sendAddItemToContainer and addContainer then
        sendAddItemToContainer(addContainer, swappedItem)
    end

    local swappedProfile = NMDeviceProfiles.getForItem(swappedItem) or ctx.profile
    local swappedState = NMDeviceState.ensure(swappedItem, swappedProfile)
    if not swappedState then
        return false, "container_swap_state_failed"
    end
    NMDeviceState.import(swappedState, exportedState)

    ctx.item = swappedItem
    ctx.profile = swappedProfile
    ctx.state = swappedState
    ctx.itemId = tostring(swappedItem.getID and swappedItem:getID() or "")
    return true, nil
end

local function normalizeTransportAction(action, state, args)
    local normalized = tostring(action or "")
    if normalized ~= "toggle_play" then
        return normalized
    end
    local desired = args and args.isPlaying
    if desired == nil then
        desired = not (state and state.isPlaying == true)
    end
    return desired and "start_playback" or "stop_playback"
end

local function staleRevisionRejected(ctx, action)
    if not isTransportAction(action) then
        return false
    end
    local expected = tonumber(ctx.args and ctx.args.expectedRevision)
    if expected == nil then
        return false
    end
    local current = tonumber(ctx.state and ctx.state.revision) or 0
    if expected == current then
        return false
    end
    logIntent(
        "server_transport_rejected_stale_revision",
        string.format(
            "action=%s player=%s item=%s expectedRevision=%d currentRevision=%d",
            tostring(action),
            tostring(ctx.player and ctx.player.getUsername and ctx.player:getUsername() or "unknown"),
            tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
            tonumber(expected) or -1,
            tonumber(current) or -1
        )
    )
    return true
end

local function finalizeAuthorityAndReplication(ctx, effectiveMode)
    local mode = tostring(effectiveMode or "off")
    if mode == "" then
        mode = "off"
    end

    local keep = NMRegistryPolicy.shouldKeepWorldSourceState(ctx.state)
    local worldMode = mode == "placed" or mode == "attached" or mode == "stowed"
    local playingWorld = tostring(ctx.state and ctx.state.playbackMode or "") == "world" and ctx.state and ctx.state.isPlaying == true
    if (not keep) and worldMode and playingWorld then
        keep = true
        logRuntime(
            "server_item_registry_invariant_repair",
            string.format(
                "uuid=%s action=%s mode=%s forcedKeep=true authoritativeMode=%s playbackMode=%s isOn=%s isPlaying=%s",
                tostring(ctx.state and ctx.state.deviceUUID or ""),
                tostring(ctx.action or ""),
                tostring(mode),
                tostring(ctx.state and ctx.state.authoritativeMode or ""),
                tostring(ctx.state and ctx.state.playbackMode or ""),
                tostring(ctx.state and ctx.state.isOn == true),
                tostring(ctx.state and ctx.state.isPlaying == true)
            )
        )
    end

    sendState(ctx.player, ctx.item, ctx.state, mode)
    broadcastObserverState(ctx.player, ctx.item, ctx.state, mode, ctx.action)

    local entry = ensureRegistryEntry(ctx.item, ctx.profile, ctx.state, mode)
    if entry then
        local op = keep and "upsert" or "remove"
        broadcastEntry(entry, ctx.state, op)
        if not keep then
            NMServerRegistryState.worldRegistry[tostring(entry.uuid)] = nil
        end
        logRuntime(
            "server_item_registry_upsert_remove",
            string.format(
                "uuid=%s op=%s sourceMode=%s isOn=%s isPlaying=%s",
                tostring(entry.uuid or ""),
                tostring(op),
                tostring(mode),
                tostring(ctx.state and ctx.state.isOn == true),
                tostring(ctx.state and ctx.state.isPlaying == true)
            )
        )
    end
end

local function clearZombieDormantForPlayerOwnership(ctx)
    if not (ctx and ctx.state and ctx.item and ctx.inventory) then
        return false
    end
    if not (NMDeviceState and NMDeviceState.isZombieDormant and NMDeviceState.isZombieDormant(ctx.state)) then
        return false
    end
    if isSyncAction(ctx.action) then
        return false
    end
    local container = ctx.item.getContainer and ctx.item:getContainer() or nil
    if container ~= ctx.inventory then
        return false
    end
    return NMDeviceState.setZombieDormant and NMDeviceState.setZombieDormant(ctx.state, false, nil, nil) == true or false
end

local function getIntentValidation()
    local external = ItemIntentValidation or NMServerItemIntentValidation
    if type(external) == "table"
        and type(external.resolveTarget) == "function"
        and type(external.shouldGateWorldTrackFinished) == "function"
        and type(external.validateExpectedToken) == "function"
        and type(external.resolveTrackFinishedHintMinAgeMs) == "function"
        and type(external.resolveStartedAtForHint) == "function" then
        return external
    end

    return {
        resolveTarget = resolveTarget,
        shouldGateWorldTrackFinished = shouldGateWorldTrackFinished,
        validateExpectedToken = validateExpectedToken,
        resolveTrackFinishedHintMinAgeMs = resolveTrackFinishedHintMinAgeMs,
        resolveStartedAtForHint = resolveStartedAtForHint
    }
end

function NMServerItemIntentPipeline.process(player, args)
    local validation = getIntentValidation()
    local ctx, resolveErr = validation.resolveTarget(player, args)
    if not ctx then
        if NMCore and NMCore.logChannel then
            NMCore.logChannel(
                "intent",
                "server_intent_rejected",
                string.format(
                    "action=%s reason=%s player=%s itemId=%s uuid=%s itemFullType=%s",
                    tostring(args and args.action or "unknown"),
                    tostring(resolveErr or "unknown"),
                    tostring(player and player.getUsername and player:getUsername() or "unknown"),
                    tostring(args and args.itemId or ""),
                    tostring(args and args.uuid or ""),
                    tostring(args and args.itemFullType or "nil")
                )
            )
        end
        return false, resolveErr
    end

    importCanonicalIfNewer(ctx)
    if isSyncAction(args and args.action) then
        hydrateTimelineFromCanonical(ctx)
    end

    local rawAction = tostring(ctx.args.action or "")
    ctx.action = normalizeTransportAction(rawAction, ctx.state, ctx.args)
    local modeFrom = tostring(ctx.state and ctx.state.authoritativeMode or "off")
    local modeTo = tostring(ctx.args and ctx.args.sourceMode or modeFrom)
    local preReconcileChanged = reconcileHeadphoneWearState(ctx.player, ctx.profile, ctx.state, ctx.action, modeTo)
    if isSyncAction(ctx.action)
        and ctx.state
        and ctx.state.isOn == true
        and ctx.state.isPlaying == true
        and modeFrom ~= modeTo then
        logRuntime(
            "mode_churn_transport_neutral_applied",
            string.format(
                "uuid=%s token=%s:%s fromMode=%s toMode=%s",
                tostring(ctx.state and ctx.state.deviceUUID or ""),
                tostring(ctx.state and ctx.state.playbackEpoch or 0),
                tostring(ctx.state and ctx.state.trackIndex or 0),
                tostring(modeFrom),
                tostring(modeTo)
            )
        )
    end

    if staleRevisionRejected(ctx, ctx.action) then
        local staleMode = deriveServerSourceMode(ctx.player, ctx.item, ctx.profile, ctx.state, ctx.args.sourceMode)
        local authorityChanged = applyAuthorityFromMode(ctx.player, ctx.item, ctx.profile, ctx.state, staleMode)
        if authorityChanged or preReconcileChanged then
            NMDeviceState.bumpRevision(ctx.state)
        end
        finalizeAuthorityAndReplication(ctx, staleMode)
        return false, "stale_revision"
    end

    local stateBeforeIntent = NMDeviceState.export(ctx.state)
    local changed = false
    local reason = nil
    local ops = nil

    local normalizedOk, normalizedErr = normalizeIngressArgsToMainInventory(ctx.player, ctx.args, ctx.action)
    if not normalizedOk then
        return false, "normalize_failed:" .. tostring(normalizedErr or "unknown")
    end

    if isSyncAction(ctx.action) then
        local desiredPlaybackMode = "world"
        if tostring(ctx.state.playbackMode or "") ~= desiredPlaybackMode then
            ctx.state.playbackMode = desiredPlaybackMode
            changed = true
        end
    else
        if validation.shouldGateWorldTrackFinished(ctx, ctx.action) then
            local progression = NMTrackProgressionContract.resolve(ctx.state, {
                fallbackMs = NMRuntimeConfig and NMRuntimeConfig.getServerVehicleTrackDurationMs and NMRuntimeConfig.getServerVehicleTrackDurationMs() or 210000,
                context = "world",
                worldAuthoritative = true
            })
            logProgression(
                "server_world_track_finished_hint_received",
                string.format(
                    "recv:%s:%s:%s",
                    tostring(ctx.state and ctx.state.deviceUUID or ""),
                    tostring(ctx.state and ctx.state.playbackEpoch or 0),
                    tostring(ctx.state and ctx.state.trackIndex or 0)
                ),
                string.format(
                    "uuid=%s item=%s expectedRevision=%s expectedEpoch=%s expectedTrack=%s observedDurationMs=%s timingMode=%s durationSource=%s",
                    tostring(ctx.state and ctx.state.deviceUUID or ""),
                    tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                    tostring(ctx.args and ctx.args.expectedRevision or 0),
                    tostring(ctx.args and ctx.args.expectedPlaybackEpoch or 0),
                    tostring(ctx.args and ctx.args.expectedTrackIndex or 0),
                    tostring(ctx.args and ctx.args.observedDurationMs or 0),
                    tostring(progression and progression.timingMode or ""),
                    tostring(progression and progression.source or "")
                )
            )
            local expectedOk, expectedReason = validation.validateExpectedToken(ctx.state, ctx.args)
            if not expectedOk then
                if expectedReason == "stale_revision"
                    and validation.canBypassStaleRevisionForTrackFinished
                    and validation.canBypassStaleRevisionForTrackFinished(ctx.state, ctx.args) then
                    logProgression(
                        "server_world_track_finished_hint_revision_bypass",
                        string.format("rev_bypass:%s:%s:%s", tostring(ctx.state and ctx.state.deviceUUID or ""), tostring(ctx.state and ctx.state.playbackEpoch or 0), tostring(ctx.state and ctx.state.trackIndex or 0)),
                        string.format(
                            "reason=stale_revision_bypass uuid=%s item=%s expectedRevision=%s currentRevision=%s token=%s:%s",
                            tostring(ctx.state and ctx.state.deviceUUID or ""),
                            tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                            tostring(tonumber(ctx.args and ctx.args.expectedRevision)),
                            tostring(tonumber(ctx.state and ctx.state.revision) or 0),
                            tostring(tonumber(ctx.state and ctx.state.playbackEpoch) or 0),
                            tostring(tonumber(ctx.state and ctx.state.trackIndex) or 0)
                        )
                    )
                else
                logProgression(
                    "server_world_track_finished_hint_rejected",
                    string.format("stale:%s:%s:%s:%s", tostring(expectedReason or "stale"), tostring(ctx.state and ctx.state.deviceUUID or ""), tostring(ctx.state and ctx.state.playbackEpoch or 0), tostring(ctx.state and ctx.state.trackIndex or 0)),
                    string.format(
                        "reason=%s uuid=%s item=%s trackIndex=%s playbackEpoch=%s",
                        tostring(expectedReason or "stale_state"),
                        tostring(ctx.state and ctx.state.deviceUUID or ""),
                        tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                        tostring(ctx.state and ctx.state.trackIndex or 1),
                        tostring(ctx.state and ctx.state.playbackEpoch or 0)
                    )
                )
                return false, expectedReason or "stale_state"
                end
            end
            local minHintAgeMs = validation.resolveTrackFinishedHintMinAgeMs()
            local nowMs = getTimestampMs and tonumber(getTimestampMs()) or ((getTimestamp and tonumber(getTimestamp()) or 0) * 1000)
            local startedAtMs, startedSource = validation.resolveStartedAtForHint(ctx.state)
            local ageMs = math.max(0, (tonumber(nowMs) or 0) - startedAtMs)
            local missingStartedAt = startedAtMs <= 0
            if (not missingStartedAt) and ageMs < minHintAgeMs then
                logProgression(
                    "server_world_track_finished_hint_rejected",
                    string.format("early:%s:%s:%s", tostring(ctx.state and ctx.state.deviceUUID or ""), tostring(ctx.state and ctx.state.playbackEpoch or 0), tostring(ctx.state and ctx.state.trackIndex or 0)),
                    string.format(
                        "reason=too_early uuid=%s item=%s ageMs=%s minHintAgeMs=%s startedAtMs=%s startedSource=%s",
                        tostring(ctx.state and ctx.state.deviceUUID or ""),
                        tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                        tostring(ageMs),
                        tostring(minHintAgeMs),
                        tostring(startedAtMs),
                        tostring(startedSource or "unknown")
                    )
                )
                return false, "too_early"
            end
            if missingStartedAt then
                logProgression(
                    "server_world_track_finished_hint_started_missing_bypass",
                    string.format("missing:%s:%s:%s", tostring(ctx.state and ctx.state.deviceUUID or ""), tostring(ctx.state and ctx.state.playbackEpoch or 0), tostring(ctx.state and ctx.state.trackIndex or 0)),
                    string.format("reason=started_at_missing_bypass uuid=%s item=%s", tostring(ctx.state and ctx.state.deviceUUID or ""), tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"))
                )
            end
            local dedupeToken = string.format(
                "%s:%s:%s",
                tostring(ctx.state and ctx.state.deviceUUID or ""),
                tostring(ctx.state and ctx.state.playbackEpoch or 0),
                tostring(ctx.state and ctx.state.trackIndex or 0)
            )
            if tostring(NMServerItemIntentPipeline._acceptedTrackFinishedToken[dedupeToken] or "") ~= "" then
                logProgression(
                    "server_world_track_finished_hint_rejected",
                    "dup:" .. tostring(dedupeToken),
                    string.format("reason=duplicate uuid=%s token=%s", tostring(ctx.state and ctx.state.deviceUUID or ""), tostring(dedupeToken))
                )
                return false, "duplicate"
            end
            NMServerItemIntentPipeline._acceptedTrackFinishedToken[dedupeToken] = "accepted"
            logProgression(
                "server_world_track_finished_hint_accepted",
                "ok:" .. tostring(dedupeToken),
                string.format(
                    "cause=hint_accept token=%s uuid=%s item=%s ageMs=%s minHintAgeMs=%s trackIndex=%s playbackEpoch=%s",
                    tostring(dedupeToken),
                    tostring(ctx.state and ctx.state.deviceUUID or ""),
                    tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                    tostring(ageMs),
                    tostring(minHintAgeMs),
                    tostring(ctx.state and ctx.state.trackIndex or 1),
                    tostring(ctx.state and ctx.state.playbackEpoch or 0)
                )
            )
            local hinted, hintedMs = applyObservedDurationHint(ctx.state, ctx.args)
            if hinted then
                logProgression(
                    "server_world_track_finished_hint_duration_recorded",
                    "hint_ms:" .. tostring(dedupeToken),
                    string.format(
                        "uuid=%s trackIndex=%s playbackEpoch=%s observedDurationMs=%s",
                        tostring(ctx.state and ctx.state.deviceUUID or ""),
                        tostring(ctx.state and ctx.state.trackIndex or 1),
                        tostring(ctx.state and ctx.state.playbackEpoch or 0),
                        tostring(hintedMs or 0)
                    )
                )
            end
        end
        local payload = buildPayload(ctx)
        local reducerEvent = mapActionToReducerEvent(ctx.action)
        if reducerEvent and NMServerCanonicalReducer and NMServerCanonicalReducer.dispatch then
            changed, reason, ops = NMServerCanonicalReducer.dispatch({
                eventType = reducerEvent,
                nowMs = getTimestampMs and tonumber(getTimestampMs()) or nil,
                profile = ctx.profile,
                state = ctx.state,
                intentPayload = payload
            })
        else
            changed, reason, ops = NMDeviceTransitions.apply(ctx.profile, ctx.state, ctx.action, payload)
        end
        if not changed then
            logIntent(
                "server_intent_rejected",
                string.format(
                    "action=%s reason=%s player=%s item=%s media=%s isOn=%s isPlaying=%s hasTrack=%s trackCount=%d",
                    tostring(ctx.action),
                    tostring(reason or "none"),
                    tostring(ctx.player and ctx.player.getUsername and ctx.player:getUsername() or "unknown"),
                    tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                    tostring(ctx.state and ctx.state.mediaFullType or "nil"),
                    tostring(ctx.state and ctx.state.isOn == true),
                    tostring(ctx.state and ctx.state.isPlaying == true),
                    tostring(payload and payload.hasTrack == true),
                    tonumber(payload and payload.trackCount) or 0
                )
            )
            local rejectedMode = deriveServerSourceMode(ctx.player, ctx.item, ctx.profile, ctx.state, ctx.args.sourceMode)
            local rejectedAuthorityChanged = applyAuthorityFromMode(ctx.player, ctx.item, ctx.profile, ctx.state, rejectedMode)
            if rejectedAuthorityChanged or preReconcileChanged then
                NMDeviceState.bumpRevision(ctx.state)
            end
            finalizeAuthorityAndReplication(ctx, rejectedMode)
            return false, reason
        end
    end

    local effectiveMode = deriveServerSourceMode(ctx.player, ctx.item, ctx.profile, ctx.state, ctx.args.sourceMode)
    local authorityChanged = applyAuthorityFromMode(ctx.player, ctx.item, ctx.profile, ctx.state, effectiveMode)
    local dormantCleared = clearZombieDormantForPlayerOwnership(ctx)

    local opsApplied, opsError = applyTransitionOps(ctx.player, ctx.inventory, ops)
    if opsError then
        if stateBeforeIntent then
            NMDeviceState.import(ctx.state, stateBeforeIntent)
            changed = false
            authorityChanged = false
            dormantCleared = false
        end
        logIntent(
            "server_ops_failed",
            string.format(
                "action=%s player=%s itemId=%s item=%s opsError=%s",
                tostring(ctx.action),
                tostring(ctx.player and ctx.player.getUsername and ctx.player:getUsername() or "unknown"),
                tostring(ctx.itemId),
                tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                tostring(opsError)
            )
        )
        local failedMode = deriveServerSourceMode(ctx.player, ctx.item, ctx.profile, ctx.state, ctx.args.sourceMode)
        finalizeAuthorityAndReplication(ctx, failedMode)
        return false, "ops_failed:" .. tostring(opsError)
    elseif opsApplied then
        logIntent(
            "server_ops_applied",
            string.format(
                "action=%s player=%s itemId=%s item=%s",
                tostring(ctx.action),
                tostring(ctx.player and ctx.player.getUsername and ctx.player:getUsername() or "unknown"),
                tostring(ctx.itemId),
                tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown")
            )
        )
    end

    local swappedVisual, swapErr = maybeSwapContainerVisualVariant(ctx)
    if swapErr then
        logIntent(
            "server_container_swap_failed",
            string.format(
                "action=%s player=%s item=%s err=%s",
                tostring(ctx.action),
                tostring(ctx.player and ctx.player.getUsername and ctx.player:getUsername() or "unknown"),
                tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                tostring(swapErr)
            )
        )
    elseif swappedVisual then
        logIntent(
            "server_container_swap_applied",
            string.format(
                "action=%s player=%s item=%s media=%s",
                tostring(ctx.action),
                tostring(ctx.player and ctx.player.getUsername and ctx.player:getUsername() or "unknown"),
                tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                tostring(ctx.state and ctx.state.mediaFullType or "nil")
            )
        )
    end

    local postReconcileChanged = reconcileHeadphoneWearState(ctx.player, ctx.profile, ctx.state, ctx.action, effectiveMode)

    if changed and isPlaybackEpochAction(ctx.action) then
        NMDeviceState.bumpPlaybackEpoch(ctx.state)
    end
    if changed or authorityChanged or dormantCleared or preReconcileChanged or postReconcileChanged then
        NMDeviceState.bumpRevision(ctx.state)
    end

    if changed then
        logIntent(
            "server_intent_applied",
            string.format(
                "action=%s rawAction=%s player=%s item=%s media=%s isOn=%s isPlaying=%s mode=%s trackIndex=%d",
                tostring(ctx.action),
                tostring(rawAction),
                tostring(ctx.player and ctx.player.getUsername and ctx.player:getUsername() or "unknown"),
                tostring(ctx.item and ctx.item.getFullType and ctx.item:getFullType() or "unknown"),
                tostring(ctx.state and ctx.state.mediaFullType or "nil"),
                tostring(ctx.state and ctx.state.isOn == true),
                tostring(ctx.state and ctx.state.isPlaying == true),
                tostring(effectiveMode),
                tonumber(ctx.state and ctx.state.trackIndex) or 1
            )
        )
    end

    finalizeAuthorityAndReplication(ctx, effectiveMode)

    if changed then
        return true, nil
    end
    return false, reason
end

