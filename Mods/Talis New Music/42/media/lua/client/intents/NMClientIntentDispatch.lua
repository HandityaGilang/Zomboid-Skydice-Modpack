-- Client intent dispatch for SP-local apply and MP network send.
-- Dependencies are loaded by module bootstrap/order.

NMClientIntentDispatch = NMClientIntentDispatch or {}
NMClientIntentDispatch._corpseAudioSeen = NMClientIntentDispatch._corpseAudioSeen or {}

local function isCorpseRecoveredItemState(item, state)
    local itemMd = item and item.getModData and item:getModData() or nil
    return (type(state) == "table" and (state._nmCorpseRecovered == true or tostring(state.lastStopReason or "") == "corpse_reconcile"))
        or (type(itemMd) == "table" and itemMd.nmCorpseRecovered == true)
end

local function logCorpseAudio(tag, uuid, detail)
    local key = tostring(uuid or "")
    local sig = tostring(tag or "") .. "|" .. tostring(detail or "")
    local seenKey = key .. "|" .. tostring(tag or "")
    if NMClientIntentDispatch._corpseAudioSeen[seenKey] == sig then
        return
    end
    NMClientIntentDispatch._corpseAudioSeen[seenKey] = sig
    print("[NewMusic] [CorpseAudio] " .. tostring(tag or "") .. " " .. tostring(detail or ""))
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

local function resolveSourceOwnerIdentity(player)
    if not player then
        return nil
    end
    local onlineId = player.getOnlineID and tostring(player:getOnlineID() or "") or ""
    if onlineId ~= "" then
        return onlineId
    end
    local username = player.getUsername and tostring(player:getUsername() or "") or ""
    if username ~= "" then
        return username
    end
    return nil
end

local function applyVehicleAuthority(player, vehicle, state)
    local authority = NMAuthorityV4 or NMAuthorityV3
    if not (authority and authority.applyIntent and state) then
        return
    end
    local sourceOwner = resolveSourceOwnerIdentity(player)
    authority.applyIntent(state, "request_vehicle", {
        sourceX = vehicle and tonumber(vehicle:getX()) or nil,
        sourceY = vehicle and tonumber(vehicle:getY()) or nil,
        sourceZ = vehicle and tonumber(vehicle:getZ()) or nil,
        sourceOwner = sourceOwner
    })
end

local function updateSPWorldSourceCache(player, item, profile, state, action, options)
    if NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() then
        return
    end
    if not (item and profile and state and state.deviceUUID) then
        return
    end

    local uuid = tostring(state.deviceUUID or "")
    if uuid == "" then
        return
    end

    local mode = NMClientModeReconcile.resolveModeForItem(player, item, profile, state)
    if mode == "attached" or mode == "placed" or mode == "stowed" then
        state.playbackMode = "world"
    else
        state.playbackMode = "inventory"
    end

    local isWorldMode = mode == "attached" or mode == "placed" or mode == "stowed"
    local shouldCacheNow = mode == "placed" or mode == "stowed"
    local isWorldActive = NMRegistryPolicy.isWorldSyncStateActive and NMRegistryPolicy.isWorldSyncStateActive(state) or false
    local keepWorldSource = isWorldMode and shouldCacheNow and isWorldActive
    local opts = type(options) == "table" and options or nil
    local isLevelOnlyAction = action == "set_volume" or action == "toggle_mute" or action == "set_mute"
    if isLevelOnlyAction
        and opts
        and opts.prevKeepWorldSource == false
        and keepWorldSource == false then
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
            NMCore.logChannel(
                "runtimeProbe",
                "sp_cache_skip_noop",
                string.format(
                    "uuid=%s action=%s prevKeep=%s keep=%s",
                    uuid, tostring(action), tostring(opts.prevKeepWorldSource), tostring(keepWorldSource)
                )
            )
        end
        return
    end

    if not keepWorldSource then
        NMClientWorldSourceCache.remove(uuid)
        NMWorldRegistrySnapshot.removeSP(uuid)
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
            NMCore.logChannel(
                "runtimeProbe",
                "sp_cache_remove",
                string.format(
                    "uuid=%s action=%s mode=%s keep=false worldMode=%s shouldCacheNow=%s worldActive=%s muted=%s isOn=%s isPlaying=%s playbackMode=%s",
                    uuid,
                    tostring(action or "unknown"),
                    tostring(mode),
                    tostring(isWorldMode),
                    tostring(shouldCacheNow),
                    tostring(isWorldActive),
                    tostring(state.isMuted == true),
                    tostring(state.isOn == true),
                    tostring(state.isPlaying == true),
                    tostring(state.playbackMode or "nil")
                )
            )
        end
        return
    end

    local sourceX, sourceY, sourceZ = 0, 0, 0
    local sourceMode = "placed"
    if mode == "placed" then
        local worldItem = item.getWorldItem and item:getWorldItem() or nil
        local square = worldItem and worldItem.getSquare and worldItem:getSquare() or nil
        if square then
            sourceX = square:getX() + 0.5
            sourceY = square:getY() + 0.5
            sourceZ = square:getZ()
        elseif player and player.getX and player.getY and player.getZ then
            sourceX = tonumber(player:getX()) or 0
            sourceY = tonumber(player:getY()) or 0
            sourceZ = tonumber(player:getZ()) or 0
            sourceMode = "attached"
        end
    else
        sourceMode = (mode == "attached" or mode == "stowed") and mode or "attached"
        if player and player.getX and player.getY and player.getZ then
            sourceX = tonumber(player:getX()) or 0
            sourceY = tonumber(player:getY()) or 0
            sourceZ = tonumber(player:getZ()) or 0
        end
    end

    NMClientWorldSourceCache.upsertFromPayload({
        uuid = uuid,
        kind = "item",
        profileType = item and item.getFullType and item:getFullType() or nil,
        state = state,
        sourceMode = sourceMode,
        x = sourceX,
        y = sourceY,
        z = sourceZ,
        itemId = NMCore.itemId and NMCore.itemId(item) or nil,
        itemFullType = item and item.getFullType and item:getFullType() or nil,
        sourceEpoch = tonumber(state.sourceGeneration) or 0
    })
    NMWorldRegistrySnapshot.upsertSP({
        kind = "item",
        uuid = uuid,
        profileType = item and item.getFullType and item:getFullType() or nil,
        sourceMode = sourceMode,
        sourceEpoch = tonumber(state.sourceGeneration) or 0,
        x = sourceX,
        y = sourceY,
        z = sourceZ,
        itemId = NMCore.itemId and NMCore.itemId(item) or nil,
        itemFullType = item and item.getFullType and item:getFullType() or nil,
        state = NMDeviceState.export(state),
        revision = tonumber(state.revision) or 0,
        playbackEpoch = tonumber(state.playbackEpoch) or 0
    })
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        NMCore.logChannel(
            "runtimeProbe",
            "sp_cache_upsert",
            string.format(
                "uuid=%s action=%s mode=%s source=%s x=%.2f y=%.2f z=%.2f isOn=%s isPlaying=%s media=%s",
                uuid,
                tostring(action or "unknown"),
                tostring(mode),
                tostring(sourceMode),
                tonumber(sourceX) or 0,
                tonumber(sourceY) or 0,
                tonumber(sourceZ) or 0,
                tostring(state.isOn == true),
                tostring(state.isPlaying == true),
                tostring(state.mediaFullType or "nil")
            )
        )
    end
end

local function buildPayload(player, item, profile, state, args)
    args = args or {}
    local trackCount = tonumber(args.trackCount) or 0
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
        externalPowerAvailable = NMInventoryHelpers.resolveExternalPowerAvailable(player, item, profile),
        trackCount = trackCount,
        hasTrack = trackCount > 0
    }

    local inv = player and player.getInventory and player:getInventory() or nil
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
        and NMMediaContract.resolveContainerMediaBinding(item and item.getFullType and item:getFullType() or nil)
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

local function normalizeIngressArgsToMainInventory(player, action, args)
    local act = tostring(action or "")
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
    return true, nil, liveItem, meta
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

local function applyTransitionOpsLocal(player, inventory, ops)
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
        local ok, err = removeItemById(inventory, ops.consumeMediaItemId)
        if ok then applied = true else failures[#failures + 1] = "consume_media:" .. tostring(err) end
    end
    if ops.consumeHeadphoneItemId then
        local ok, err = removeItemById(inventory, ops.consumeHeadphoneItemId)
        if ok then applied = true else failures[#failures + 1] = "consume_headphones:" .. tostring(err) end
    end
    if ops.consumeBatteryItemId then
        local ok, err = removeItemById(inventory, ops.consumeBatteryItemId)
        if ok then applied = true else failures[#failures + 1] = "consume_battery:" .. tostring(err) end
    end

    if ops.produceMediaFullType then
        local out, err = addItemByFullType(inventory, ops.produceMediaFullType)
        if out then
            setRecordedMediaIndex(out, ops.produceMediaRecordedMediaIndex)
            applied = true
        else
            failures[#failures + 1] = "produce_media:" .. tostring(err)
        end
    end
    if ops.produceHeadphoneFullType then
        local out, err = addItemByFullType(inventory, ops.produceHeadphoneFullType)
        if out then
            applied = true
        else
            failures[#failures + 1] = "produce_headphones:" .. tostring(err)
        end
    end
    if ops.produceBatteryCharge ~= nil then
        local out, err = addItemByFullType(inventory, "Base.Battery")
        if out then
            if out.setUsedDelta then
                pcall(out.setUsedDelta, out, NMCore.clamp(tonumber(ops.produceBatteryCharge) or 0.0, 0.0, 1.0))
            end
            applied = true
        else
            failures[#failures + 1] = "produce_battery:" .. tostring(err)
        end
    end

    if #failures > 0 then
        return applied, table.concat(failures, ";")
    end
    return applied, nil
end

local function maybeSwapContainerVisualVariantLocal(player, item, profile, state)
    if not (player and item and profile and state and profile.isMediaContainerOnly == true) then
        return item, profile, state, false, nil
    end
    local playerInventory = player.getInventory and player:getInventory() or nil
    local ownerContainer = resolveOwningContainer(item, playerInventory)
    if not ownerContainer then
        return item, profile, state, false, "missing_inventory"
    end

    local currentFullType = tostring(item.getFullType and item:getFullType() or "")
    if currentFullType == "" then
        return item, profile, state, false, nil
    end
    local wantLoaded = state.mediaFullType ~= nil
    local targetFullType = NMMediaContract
        and NMMediaContract.resolveContainerSwapFullType
        and NMMediaContract.resolveContainerSwapFullType(currentFullType, wantLoaded)
        or nil
    targetFullType = tostring(targetFullType or "")
    if targetFullType == "" or targetFullType == currentFullType then
        return item, profile, state, false, nil
    end

    local exportedState = NMDeviceState.export(state)
    local removed, removeErr = removeItemById(ownerContainer, NMCore.itemId(item))
    if not removed then
        return item, profile, state, false, "container_swap_remove_failed:" .. tostring(removeErr or "unknown")
    end

    local swappedItem, addErr = addItemByFullType(ownerContainer, targetFullType)
    if not swappedItem then
        return item, profile, state, false, "container_swap_add_failed:" .. tostring(addErr or "unknown")
    end

    local swappedProfile = NMDeviceProfiles.getForItem(swappedItem) or profile
    local swappedState = NMDeviceState.ensure(swappedItem, swappedProfile)
    if not swappedState then
        return item, profile, state, false, "container_swap_state_failed"
    end
    NMDeviceState.import(swappedState, exportedState)
    return swappedItem, swappedProfile, swappedState, true, nil
end

function NMClientIntentDispatch.applyIntentLocal(player, item, action, args)
    local profile = NMDeviceProfiles.getForItem(item)
    if not profile then
        if NMCore and NMCore.logChannel then
            NMCore.logChannel("intent", "apply_local_rejected", "action=" .. tostring(action) .. " reason=not_managed")
        end
        return false, "not_managed"
    end

    local state = NMDeviceState.ensure(item, profile)
    local normalizedOk, normalizedErr = normalizeIngressArgsToMainInventory(player, action, args or {})
    if not normalizedOk then
        if NMCore and NMCore.logChannel then
            NMCore.logChannel("intent", "apply_local_rejected", "action=" .. tostring(action) .. " reason=" .. tostring(normalizedErr or "normalize_failed"))
        end
        return false, "normalize_failed:" .. tostring(normalizedErr or "unknown")
    end
    local prevIsOn = state and state.isOn == true
    local prevMode = NMClientModeReconcile.resolveModeForItem(player, item, profile, state)
    local prevIsWorldMode = prevMode == "attached" or prevMode == "placed" or prevMode == "stowed"
    local prevShouldCacheNow = prevMode == "placed" or prevMode == "stowed"
    local prevIsWorldActive = NMRegistryPolicy.isWorldSyncStateActive and NMRegistryPolicy.isWorldSyncStateActive(state) or false
    local prevKeepWorldSource = prevIsWorldMode and prevShouldCacheNow and prevIsWorldActive
    local stateBeforeIntent = NMDeviceState.export(state)
    local preReconcileChanged = reconcileHeadphoneWearState(player, profile, state, action, prevMode)
    local wasPlaying = state and state.isPlaying == true
    local hadHeadphones = state and state.headphoneItemFullType ~= nil
    local payload = buildPayload(player, item, profile, state, args)
    if isCorpseRecoveredItemState(item, state) then
        state._nmCorpseRecovered = true
    end
    if isCorpseRecoveredItemState(item, state) and (action == "toggle_play" or action == "start_playback" or action == "power_on" or action == "toggle_power") then
        logCorpseAudio(
            "intent_attempt",
            state.deviceUUID,
            string.format(
                "action=%s item=%s media=%s hasTrack=%s trackCount=%d mode=%s playbackMode=%s headphones=%s batteryPresent=%s batteryCharge=%.3f muted=%s isOn=%s isPlaying=%s",
                tostring(action),
                tostring(item and item.getFullType and item:getFullType() or "unknown"),
                tostring(state and state.mediaFullType or "nil"),
                tostring(payload and payload.hasTrack == true),
                tonumber(payload and payload.trackCount) or 0,
                tostring(prevMode or "unknown"),
                tostring(state and state.playbackMode or ""),
                tostring(state and state.headphoneItemFullType or "nil"),
                tostring(state and state.batteryPresent == true),
                tonumber(state and state.batteryCharge) or 0.0,
                tostring(state and state.isMuted == true),
                tostring(state and state.isOn == true),
                tostring(state and state.isPlaying == true)
            )
        )
    end
    local changed, reason, ops = NMDeviceTransitions.apply(profile, state, action, payload)
    if not changed then
        if preReconcileChanged then
            NMDeviceState.bumpRevision(state)
            updateSPWorldSourceCache(player, item, profile, state, action, {
                prevKeepWorldSource = prevKeepWorldSource
            })
        end
        if isCorpseRecoveredItemState(item, state) then
            logCorpseAudio(
                "intent_rejected",
                state.deviceUUID,
                string.format(
                    "action=%s reason=%s item=%s media=%s hasTrack=%s trackCount=%d mode=%s playbackMode=%s headphones=%s batteryPresent=%s batteryCharge=%.3f muted=%s isOn=%s isPlaying=%s",
                    tostring(action),
                    tostring(reason or "none"),
                    tostring(item and item.getFullType and item:getFullType() or "unknown"),
                    tostring(state and state.mediaFullType or "nil"),
                    tostring(payload and payload.hasTrack == true),
                    tonumber(payload and payload.trackCount) or 0,
                    tostring(prevMode or "unknown"),
                    tostring(state and state.playbackMode or ""),
                    tostring(state and state.headphoneItemFullType or "nil"),
                    tostring(state and state.batteryPresent == true),
                    tonumber(state and state.batteryCharge) or 0.0,
                    tostring(state and state.isMuted == true),
                    tostring(state and state.isOn == true),
                    tostring(state and state.isPlaying == true)
                )
            )
        end
        if NMCore and NMCore.logChannel then
            NMCore.logChannel(
                "intent",
                "apply_local_rejected",
                string.format(
                    "action=%s reason=%s item=%s media=%s isOn=%s isPlaying=%s hasTrack=%s trackCount=%d",
                    tostring(action),
                    tostring(reason or "none"),
                    tostring(item and item.getFullType and item:getFullType() or "unknown"),
                    tostring(state and state.mediaFullType or "nil"),
                    tostring(state and state.isOn == true),
                    tostring(state and state.isPlaying == true),
                    tostring(payload and payload.hasTrack == true),
                    tonumber(payload and payload.trackCount) or 0
                )
            )
        end
        return false, reason
    end

    if isCorpseRecoveredItemState(item, state) then
        logCorpseAudio(
            "intent_applied",
            state.deviceUUID,
            string.format(
                "action=%s item=%s media=%s trackIndex=%d playbackMode=%s headphones=%s batteryPresent=%s batteryCharge=%.3f muted=%s isOn=%s isPlaying=%s",
                tostring(action),
                tostring(item and item.getFullType and item:getFullType() or "unknown"),
                tostring(state and state.mediaFullType or "nil"),
                tonumber(state and state.trackIndex) or 1,
                tostring(state and state.playbackMode or ""),
                tostring(state and state.headphoneItemFullType or "nil"),
                tostring(state and state.batteryPresent == true),
                tonumber(state and state.batteryCharge) or 0.0,
                tostring(state and state.isMuted == true),
                tostring(state and state.isOn == true),
                tostring(state and state.isPlaying == true)
            )
        )
    end

    if NMCore and NMCore.logChannel then
        NMCore.logChannel(
            "intent",
            "apply_local_applied",
            string.format(
                "action=%s item=%s media=%s isOn=%s isPlaying=%s trackIndex=%d",
                tostring(action),
                tostring(item and item.getFullType and item:getFullType() or "unknown"),
                tostring(state and state.mediaFullType or "nil"),
                tostring(state and state.isOn == true),
                tostring(state and state.isPlaying == true),
                tonumber(state and state.trackIndex) or 1
            )
        )
    end
    if (action == "set_mute" or action == "toggle_mute" or action == "set_volume")
        and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("intent") then
        NMCore.logChannel(
            "intent",
            "level_change_applied",
            string.format(
                "action=%s item=%s wasPlaying=%s isPlaying=%s muted=%s volume=%.2f",
                tostring(action),
                tostring(item and item.getFullType and item:getFullType() or "unknown"),
                tostring(wasPlaying),
                tostring(state and state.isPlaying == true),
                tostring(state and state.isMuted == true),
                tonumber(state and state.volume) or 0
            )
        )
    end
    if (action == "insert_headphones" or action == "eject_headphones")
        and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("intent") then
        local mode = NMClientModeReconcile.resolveModeForItem(player, item, profile, state)
        local output = NMDeviceProfiles.resolveOutputMode(profile, state, mode, false)
        NMCore.logChannel(
            "intent",
            "headphones_change_applied",
            string.format(
                "action=%s item=%s wasPlaying=%s isPlaying=%s hadHeadphones=%s hasHeadphones=%s mode=%s output=%s",
                tostring(action),
                tostring(item and item.getFullType and item:getFullType() or "unknown"),
                tostring(wasPlaying),
                tostring(state and state.isPlaying == true),
                tostring(hadHeadphones),
                tostring(state and state.headphoneItemFullType ~= nil),
                tostring(mode or "unknown"),
                tostring(output or "none")
            )
        )
    end

    local inv = player and player.getInventory and player:getInventory() or nil
    local _, opsError = applyTransitionOpsLocal(player, inv, ops)
    if opsError and NMCore and NMCore.logChannel then
        NMCore.logChannel("intent", "apply_local_ops_failed", tostring(opsError))
        if stateBeforeIntent then
            NMDeviceState.import(state, stateBeforeIntent)
        end
        return false, "ops_failed:" .. tostring(opsError)
    end
    item, profile, state = maybeSwapContainerVisualVariantLocal(player, item, profile, state)
    local nextMode = NMClientModeReconcile.resolveModeForItem(player, item, profile, state)
    local postReconcileChanged = reconcileHeadphoneWearState(player, profile, state, action, nextMode)

    if action == "toggle_play" or action == "start_playback" or action == "stop_playback"
        or action == "next_track" or action == "prev_track" or action == "set_playback_mode"
        or action == "power_on" or action == "power_off" or action == "toggle_power"
        or action == "track_finished" or action == "track_finished_world" then
        NMDeviceState.bumpPlaybackEpoch(state)
    end
    local nowIsOn = state and state.isOn == true
    if prevIsOn and (not nowIsOn) and NMPlaybackRuntime and NMPlaybackRuntime.resetPowerTick then
        NMPlaybackRuntime.resetPowerTick(state and state.deviceUUID, "intent_power_off")
    end
    if (not prevIsOn) and nowIsOn and NMPlaybackRuntime and NMPlaybackRuntime.resetPowerTick then
        NMPlaybackRuntime.resetPowerTick(state and state.deviceUUID, "intent_power_on")
    end
    if prevIsOn and (not nowIsOn) and NMPlaybackRuntime and NMPlaybackRuntime.forceStop then
        NMPlaybackRuntime.forceStop(player, state and state.deviceUUID, "intent_power_off_immediate")
    end
    NMDeviceState.bumpRevision(state)
    updateSPWorldSourceCache(player, item, profile, state, action, {
        prevKeepWorldSource = prevKeepWorldSource
    })
    return true, nil
end

function NMClientIntentDispatch.performIntent(player, item, action, args)
    args = args or {}
    args.itemId = NMCore.itemId(item)
    args.action = tostring(action or "")
    if item and item.getFullType and args.itemFullType == nil then
        args.itemFullType = tostring(item:getFullType() or "")
    end
    if args.uuid == nil then
        local profile = NMDeviceProfiles.getForItem(item)
        local state = profile and NMDeviceState.ensure(item, profile) or nil
        if state and state.deviceUUID then
            args.uuid = tostring(state.deviceUUID)
        end
    end

    local normalizedOk, normalizedErr = normalizeIngressArgsToMainInventory(player, args.action, args)
    if not normalizedOk then
        return false, "normalize_failed:" .. tostring(normalizedErr or "unknown")
    end

    if NMCore.isMPClientRuntime() and sendClientCommand then
        sendClientCommand(player, NMCore.NetModule, "intent", args)
        return true, nil
    end

    return NMClientIntentDispatch.applyIntentLocal(player, item, args.action, args)
end

local function isPowerOnRequest(localAction, localArgs, localState)
    local name = tostring(localAction or "")
    if name == "power_on" then
        return true
    end
    if name == "toggle_power" then
        if localArgs and localArgs.isOn ~= nil then
            return localArgs.isOn == true
        end
        return not (localState and localState.isOn == true)
    end
    return false
end

function NMClientIntentDispatch.performVehicleIntent(player, vehicle, part, action, args)
    args = args or {}
    args.action = tostring(action or "")
    args.vehicleId = vehicle and tostring(vehicle:getId()) or nil
    args.partId = part and tostring(part:getId()) or "Radio"
    args.playbackMode = "world"

    local normalizedOk, normalizedErr = normalizeIngressArgsToMainInventory(player, args.action, args)
    if not normalizedOk then
        return false, "normalize_failed:" .. tostring(normalizedErr or "unknown")
    end

    if NMCore.isMPClientRuntime() and sendClientCommand then
        sendClientCommand(player, NMCore.NetModule, "intent", args)
        return true, nil
    end

    local profile = part and NMDeviceProfiles.getVehicleProfile(part) or nil
    if not profile then
        return false, "vehicle_profile_missing"
    end

    local state = NMDeviceState.ensure(part, profile)
    local stateBeforeIntent = NMDeviceState.export(state)
    local prevIsOn = state and state.isOn == true
    local trackCount = tonumber(args.trackCount) or 0
    if trackCount < 1 then
        trackCount = resolveTrackCountFromMedia(state)
    end
    local inv = player and player.getInventory and player:getInventory() or nil
    local mediaPayload = nil
    if inv and args.mediaItemId then
        local mediaItem = NMInventoryHelpers.findItemById(inv, args.mediaItemId)
        mediaPayload = NMMediaHelpers.resolveMediaInsertPayload(mediaItem)
    end
    local payload = {
        isOn = args.isOn,
        isPlaying = args.isPlaying,
        volume = args.volume,
        playbackMode = "world",
        playbackPolicy = args.playbackPolicy,
        observedDurationMs = args.observedDurationMs,
        mediaItemId = args.mediaItemId,
        mediaFullType = mediaPayload and mediaPayload.mediaFullType or args.mediaFullType,
        mediaItemFullType = mediaPayload and (mediaPayload.mediaEjectFullType or mediaPayload.mediaFullType) or args.mediaEjectFullType or args.mediaFullType,
        mediaCarrier = mediaPayload and mediaPayload.mediaCarrier or args.mediaCarrier,
        mediaEjectFullType = mediaPayload and mediaPayload.mediaEjectFullType or args.mediaEjectFullType,
        mediaCanonicalFullType = mediaPayload and mediaPayload.mediaCanonicalFullType or args.mediaCanonicalFullType,
        mediaRecordedMediaIndex = mediaPayload and mediaPayload.mediaRecordedMediaIndex or args.mediaRecordedMediaIndex,
        mediaDisplayName = mediaPayload and mediaPayload.mediaDisplayName or args.mediaDisplayName,
        externalPowerAvailable = NMVehicleHelpers.vehicleHasUsableBatteryPower and NMVehicleHelpers.vehicleHasUsableBatteryPower(vehicle, part) or NMVehicleHelpers.vehicleHasPower(vehicle, part),
        trackCount = trackCount,
        hasTrack = trackCount > 0
    }
    if isPowerOnRequest(args.action, args, state) and payload.externalPowerAvailable ~= true then
        return false, "vehicle_battery_unavailable"
    end
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("intent") then
        NMCore.logChannel(
            "intent",
            "vehicle_intent_attempt",
            string.format(
                "action=%s vehicle=%s part=%s media=%s isOn=%s isPlaying=%s trackCount=%d hasTrack=%s",
                tostring(args.action or action),
                tostring(vehicle and vehicle.getId and vehicle:getId() or "unknown"),
                tostring(part and part.getId and part:getId() or "unknown"),
                tostring(state and state.mediaFullType or "nil"),
                tostring(state and state.isOn == true),
                tostring(state and state.isPlaying == true),
                tonumber(trackCount) or 0,
                tostring(trackCount > 0)
            )
        )
    end
    local changed, reason, ops = NMDeviceTransitions.apply(profile, state, args.action, payload)
    if part and profile.vehicleUsesCarBattery and state.isOn and (not NMVehicleHelpers.vehicleHasPower(vehicle, part)) then
        state.isOn = false
        state.desiredIsOn = false
        state.isPlaying = false
        state.desiredIsPlaying = false
        state.lastStopReason = "vehicle_battery_empty"
        changed = true
    end

    if not changed then
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("intent") then
            NMCore.logChannel(
                "intent",
                "vehicle_intent_rejected",
                string.format(
                    "action=%s reason=%s vehicle=%s part=%s media=%s isOn=%s isPlaying=%s trackCount=%d",
                    tostring(args.action or action),
                    tostring(reason or "none"),
                    tostring(vehicle and vehicle.getId and vehicle:getId() or "unknown"),
                    tostring(part and part.getId and part:getId() or "unknown"),
                    tostring(state and state.mediaFullType or "nil"),
                    tostring(state and state.isOn == true),
                    tostring(state and state.isPlaying == true),
                    tonumber(trackCount) or 0
                )
            )
        end
        return false, reason
    end

    local _, opsError = applyTransitionOpsLocal(player, inv, ops)
    if opsError and NMCore and NMCore.logChannel then
        NMCore.logChannel(
            "intent",
            "vehicle_apply_local_ops_failed",
            string.format(
                "action=%s mediaItemId=%s resolvedMedia=%s opsError=%s",
                tostring(args.action or action),
                tostring(args.mediaItemId or ""),
                tostring(payload.mediaFullType or ""),
                tostring(opsError)
            )
        )
        if stateBeforeIntent then
            NMDeviceState.import(state, stateBeforeIntent)
        end
        return false, "ops_failed:" .. tostring(opsError)
    end
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("intent") then
        NMCore.logChannel(
            "intent",
            "vehicle_intent_applied",
            string.format(
                "action=%s vehicle=%s part=%s media=%s isOn=%s isPlaying=%s trackCount=%d",
                tostring(args.action or action),
                tostring(vehicle and vehicle.getId and vehicle:getId() or "unknown"),
                tostring(part and part.getId and part:getId() or "unknown"),
                tostring(state and state.mediaFullType or "nil"),
                tostring(state and state.isOn == true),
                tostring(state and state.isPlaying == true),
                tonumber(trackCount) or 0
            )
        )
    end

    if args.action == "toggle_play" or args.action == "start_playback" or args.action == "stop_playback"
        or args.action == "next_track" or args.action == "prev_track"
        or args.action == "set_playback_mode" or args.action == "power_on" or args.action == "power_off"
        or args.action == "toggle_power" or args.action == "track_finished" then
        NMDeviceState.bumpPlaybackEpoch(state)
    end
    local nowIsOn = state and state.isOn == true
    if prevIsOn and (not nowIsOn) and NMPlaybackRuntime and NMPlaybackRuntime.resetPowerTick then
        NMPlaybackRuntime.resetPowerTick(state and state.deviceUUID, "vehicle_intent_power_off")
    end
    if (not prevIsOn) and nowIsOn and NMPlaybackRuntime and NMPlaybackRuntime.resetPowerTick then
        NMPlaybackRuntime.resetPowerTick(state and state.deviceUUID, "vehicle_intent_power_on")
    end
    if prevIsOn and (not nowIsOn) and NMPlaybackRuntime and NMPlaybackRuntime.forceStop then
        NMPlaybackRuntime.forceStop(player, state and state.deviceUUID, "intent_power_off_immediate")
    end
    applyVehicleAuthority(player, vehicle, state)
    NMDeviceState.bumpRevision(state)

    local keep = NMRegistryPolicy.shouldKeepWorldSourceState(state)
    local uuid = tostring(state.deviceUUID or "")
    local vehicleRuntimeId = vehicle and NMVehicleHelpers and NMVehicleHelpers.getVehicleIdString and NMVehicleHelpers.getVehicleIdString(vehicle)
        or vehicle and tostring(vehicle:getId()) or nil
    local vehicleSqlId = vehicle and NMVehicleHelpers and NMVehicleHelpers.getVehicleSqlIdString and NMVehicleHelpers.getVehicleSqlIdString(vehicle)
        or nil
    if keep and uuid ~= "" then
        NMClientWorldSourceCache.upsertFromPayload({
            kind = "vehicle",
            uuid = uuid,
            vehicleId = vehicleRuntimeId,
            vehicleIdHint = vehicleRuntimeId,
            vehicleSqlId = vehicleSqlId,
            vehicleSqlIdHint = vehicleSqlId,
            partId = part and tostring(part:getId()) or "Radio",
            profileType = "vehicle_radio",
            x = vehicle and tonumber(vehicle:getX()) or 0,
            y = vehicle and tonumber(vehicle:getY()) or 0,
            z = vehicle and tonumber(vehicle:getZ()) or 0,
            sourceMode = "vehicle",
            windowsOpen = vehicle and NMVehicleHelpers.vehicleWindowsOpen(vehicle) or false,
            sourceEpoch = tonumber(state.sourceGeneration) or 0,
            state = state
        })
        NMWorldRegistrySnapshot.upsertSP({
            kind = "vehicle",
            uuid = uuid,
            profileType = "vehicle_radio",
            sourceMode = "vehicle",
            sourceEpoch = tonumber(state.sourceGeneration) or 0,
            x = vehicle and tonumber(vehicle:getX()) or 0,
            y = vehicle and tonumber(vehicle:getY()) or 0,
            z = vehicle and tonumber(vehicle:getZ()) or 0,
            vehicleId = vehicleRuntimeId,
            vehicleIdHint = vehicleRuntimeId,
            vehicleSqlId = vehicleSqlId,
            vehicleSqlIdHint = vehicleSqlId,
            partId = part and tostring(part:getId()) or "Radio",
            windowsOpen = vehicle and NMVehicleHelpers.vehicleWindowsOpen(vehicle) or false,
            state = NMDeviceState.export(state),
            revision = tonumber(state.revision) or 0,
            playbackEpoch = tonumber(state.playbackEpoch) or 0
        })
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
            NMCore.logChannel("runtimeProbe", "vehicle_cache_upsert", "uuid=" .. tostring(uuid) .. " vehicleId=" .. tostring(vehicle and vehicle.getId and vehicle:getId() or "unknown"))
        end
    elseif uuid ~= "" then
        NMClientWorldSourceCache.remove(uuid)
        NMWorldRegistrySnapshot.removeSP(uuid)
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
            NMCore.logChannel("runtimeProbe", "vehicle_cache_remove", "uuid=" .. tostring(uuid) .. " vehicleId=" .. tostring(vehicle and vehicle.getId and vehicle:getId() or "unknown"))
        end
    end

    if vehicle and vehicle.transmitPartModData then
        vehicle:transmitPartModData(part)
        vehicle:updateParts()
    end

    return true, nil
end
