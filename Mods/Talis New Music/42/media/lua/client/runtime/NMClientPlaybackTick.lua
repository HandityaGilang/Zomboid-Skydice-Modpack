-- Client playback tick orchestration for inventory devices and detached cached sources.
NMClientPlaybackTick = NMClientPlaybackTick or {}
NMClientPlaybackTick.tick = NMClientPlaybackTick.tick or 0
NMClientPlaybackTick.lastInventoryByUuid = NMClientPlaybackTick.lastInventoryByUuid or {}
NMClientPlaybackTick.vehiclePowerTickMs = NMClientPlaybackTick.vehiclePowerTickMs or {}
NMClientPlaybackTick.zombiePulseMs = NMClientPlaybackTick.zombiePulseMs or {}
NMClientPlaybackTick.zombiePulsePos = NMClientPlaybackTick.zombiePulsePos or {}
NMClientPlaybackTick.ownershipConflictState = NMClientPlaybackTick.ownershipConflictState or {}
NMClientPlaybackTick.detachedRemoveLogMs = NMClientPlaybackTick.detachedRemoveLogMs or {}
NMClientPlaybackTick.modeResolutionSigSeen = NMClientPlaybackTick.modeResolutionSigSeen or {}
NMClientPlaybackTick.modeResolutionHeartbeatMs = NMClientPlaybackTick.modeResolutionHeartbeatMs or {}
NMClientPlaybackTick.corpseInventoryReboundSeen = NMClientPlaybackTick.corpseInventoryReboundSeen or {}

local function logTransitionProbe(msg, detail)
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("transitionProbe") then
        NMCore.logChannel("transitionProbe", msg, detail)
    end
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

local function shouldLogModeResolution(uuid, signature, changed)
    if changed == true then
        return true
    end
    local key = tostring(uuid or "")
    if key == "" then
        return false
    end
    local nowMs = nowRealMs()
    local previousSig = tostring(NMClientPlaybackTick.modeResolutionSigSeen[key] or "")
    local previousMs = tonumber(NMClientPlaybackTick.modeResolutionHeartbeatMs[key]) or 0
    local currentSig = tostring(signature or "")
    if previousSig ~= currentSig or (nowMs - previousMs) >= 20000 then
        NMClientPlaybackTick.modeResolutionSigSeen[key] = currentSig
        NMClientPlaybackTick.modeResolutionHeartbeatMs[key] = nowMs
        return true
    end
    return false
end

local function _fallbackSetVehicleIdentityState(entry, liveEntry, _, nextState, _)
    local target = tostring(nextState or "")
    if target == "" then
        return
    end
    if entry then
        entry._vehicleIdentityState = target
    end
    if liveEntry and liveEntry ~= entry then
        liveEntry._vehicleIdentityState = target
    end
end

local function _fallbackResolveVehicleCanonicalGeneration(state, entry, liveEntry, _)
    local stateGen = tonumber(state and state.sourceGeneration) or 0
    local entryGen = math.max(
        tonumber(entry and entry.sourceGeneration) or 0,
        tonumber(entry and entry.sourceEpoch) or 0,
        tonumber(entry and entry.stateSnapshot and entry.stateSnapshot.sourceGeneration) or 0
    )
    local liveGen = math.max(
        tonumber(liveEntry and liveEntry.sourceGeneration) or 0,
        tonumber(liveEntry and liveEntry.sourceEpoch) or 0,
        tonumber(liveEntry and liveEntry.stateSnapshot and liveEntry.stateSnapshot.sourceGeneration) or 0
    )
    local chosen = math.max(stateGen, entryGen, liveGen)
    return chosen
end

local function _fallbackPersistVehicleCanonicalGeneration(entry, liveEntry, state, canonicalGen)
    local gen = tonumber(canonicalGen) or 0
    local function apply(target)
        if not target then
            return
        end
        target.sourceGeneration = math.max(tonumber(target.sourceGeneration) or 0, gen)
        target.sourceEpoch = math.max(tonumber(target.sourceEpoch) or 0, gen)
        if target.stateSnapshot then
            target.stateSnapshot.sourceGeneration = math.max(tonumber(target.stateSnapshot.sourceGeneration) or 0, gen)
        end
    end
    apply(entry)
    apply(liveEntry)
    if state then
        state.sourceGeneration = math.max(tonumber(state.sourceGeneration) or 0, gen)
    end
end

local continuity = type(NMClientVehicleContinuity) == "table" and NMClientVehicleContinuity or {}
local detachedOrchestration = type(NMClientDetachedOrchestration) == "table" and NMClientDetachedOrchestration or {}

local setVehicleIdentityState = continuity.setVehicleIdentityState or _fallbackSetVehicleIdentityState
local resolveVehicleCanonicalGeneration = continuity.resolveVehicleCanonicalGeneration or _fallbackResolveVehicleCanonicalGeneration
local persistVehicleCanonicalGeneration = continuity.persistVehicleCanonicalGeneration or _fallbackPersistVehicleCanonicalGeneration

if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
    if not continuity.setVehicleIdentityState then
        NMCore.logChannel("runtimeProbe", "module_fallback_active", "module=NMClientVehicleContinuity")
    end
    if not detachedOrchestration.buildConflictStateKey then
        NMCore.logChannel("runtimeProbe", "module_fallback_active", "module=NMClientDetachedOrchestration")
    end
end


local function collectInventoryManaged(player, out)
    local allItems = {}
    NMInventoryHelpers.collectItemsRecursive(player:getInventory(), allItems)
    for i = 1, #allItems do
        local item = allItems[i]
        local profile = NMDeviceProfiles.getForItem(item)
        if profile then
            local state = NMDeviceState.ensure(item, profile)
            if state and state.deviceUUID then
                local itemMd = item and item.getModData and item:getModData() or nil
                if itemMd and itemMd.nmCorpseRecovered == true then
                    state._nmCorpseRecovered = true
                end
                out[#out + 1] = {
                    item = item,
                    profile = profile,
                    state = state,
                    uuid = tostring(state.deviceUUID)
                }
            end
        end
    end
end

local function consumeAndDispatchTrackFinished(player, profile, state, entry, item, sourceKind, uuid)
    NMClientTrackFinishedDispatch.consumeAndDispatchTrackFinished(player, profile, state, entry, item, sourceKind, uuid)
end

local function applySPLocalVehiclePowerGuard(profile, state, source, uuid)
    NMClientSPLocalRuntime.applyVehiclePowerGuard(profile, state, source, uuid, {
        vehiclePowerTickMs = NMClientPlaybackTick.vehiclePowerTickMs,
        nowMs = nowRealMs
    })
end

local function reconcileDroppedInventoryToPlacedSP(player, currentInventoryByUuid)
    NMClientPlaybackTick.lastInventoryByUuid = NMClientSPDropReconcile.reconcile({
        player = player,
        currentInventoryByUuid = currentInventoryByUuid,
        previousInventoryByUuid = NMClientPlaybackTick.lastInventoryByUuid,
        logTransitionProbe = logTransitionProbe
    }) or (currentInventoryByUuid or {})
end

local function normalizeCorpseRecoveredInventoryState(profile, state, uuid)
    if NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() then
        return false
    end
    if not (profile and state and uuid and uuid ~= "") then
        return false
    end
    if not (NMDeviceProfiles and NMDeviceProfiles.isPortableTrackedProfile and NMDeviceProfiles.isPortableTrackedProfile(profile) == true) then
        return false
    end
    if tostring(state.lastStopReason or "") ~= "corpse_reconcile" then
        return false
    end
    if NMClientPlaybackTick.corpseInventoryReboundSeen[uuid] == true then
        return false
    end

    NMClientPlaybackTick.corpseInventoryReboundSeen[uuid] = true
    state.authoritativeMode = "off"
    state.sourceKind = "inventory"
    state.sourceOwner = nil
    state.sourceX = nil
    state.sourceY = nil
    state.sourceZ = nil
    state.sourceGeneration = 0
    state.playbackMode = "inventory"
    state.zombieDormant = false
    state.zombieDormantReason = nil
    state.zombieDormantStrategy = nil

    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        NMCore.logChannel(
            "runtimeProbe",
            "corpse_inventory_rebind",
            string.format(
                "uuid=%s playbackMode=%s media=%s headphones=%s sourceKind=%s sourceGeneration=%s",
                tostring(uuid),
                tostring(state.playbackMode or ""),
                tostring(state.mediaFullType or "nil"),
                tostring(state.headphoneItemFullType or "nil"),
                tostring(state.sourceKind or ""),
                tostring(state.sourceGeneration or 0)
            )
        )
    end
    return true
end

function NMClientPlaybackTick.onTick(player)
    if not player or not player.getInventory then
        return
    end

    NMClientPlaybackTick.tick = (tonumber(NMClientPlaybackTick.tick) or 0) + 1
    local tickCount = getGameTime and getGameTime():getWorldAgeHours() or 0
    local valid = {}
    local inventoryOwners = {}
    local currentInventoryByUuid = {}
    local spPulseCandidates = {}

    local inventory = {}
    collectInventoryManaged(player, inventory)

    for i = 1, #inventory do
        local e = inventory[i]
        normalizeCorpseRecoveredInventoryState(e.profile, e.state, e.uuid)
        local mode = NMClientModeReconcile.resolveModeForItem(player, e.item, e.profile, e.state)
        local resolvedOutputForMode = NMDeviceProfiles.resolveOutputMode(e.profile, e.state, mode, false)
        local modeChanged = NMClientModeReconcile.applyResolvedMode(e.uuid, e.state, mode)
        local modeSignature = table.concat({
            tostring(mode),
            tostring(modeChanged == true),
            tostring(e.state and e.state.isOn == true),
            tostring(e.state and e.state.isPlaying == true),
            tostring(e.state and e.state.mediaFullType or "nil")
        }, "|")
        local shouldLogMode = shouldLogModeResolution(e.uuid, modeSignature, modeChanged == true)
        if shouldLogMode then
            local worldItem = e.item and e.item.getWorldItem and e.item:getWorldItem() or nil
            logTransitionProbe(
                "mode_resolution",
                string.format(
                    "uuid=%s mode=%s changed=%s worldItem=%s isOn=%s isPlaying=%s media=%s",
                    tostring(e.uuid),
                    tostring(mode),
                    tostring(modeChanged == true),
                    tostring(worldItem ~= nil),
                    tostring(e.state and e.state.isOn == true),
                    tostring(e.state and e.state.isPlaying == true),
                    tostring(e.state and e.state.mediaFullType or "nil")
                )
            )
        end

        if NMClientModeSync and NMClientModeSync.emit then
            NMClientModeSync.emit(player, e.item, e.profile, e.state, mode)
        end

        local source = nil
        local trackedPortable = NMDeviceProfiles.isPortableTrackedProfile and NMDeviceProfiles.isPortableTrackedProfile(e.profile)
        if mode == "attached" or mode == "stowed" or mode == "drop_pending" then
            source = {
                mode = "world",
                context = mode,
                x = player.getX and player:getX() or 0,
                y = player.getY and player:getY() or 0,
                z = player.getZ and player:getZ() or 0
            }
            e.state.playbackMode = ((resolvedOutputForMode == "world" or resolvedOutputForMode == "silent") or trackedPortable) and "world" or "inventory"
        elseif mode == "placed" then
            local w = e.item.getWorldItem and e.item:getWorldItem() or nil
            local s = w and w.getSquare and w:getSquare() or nil
            if s then
                source = {
                    mode = "world",
                    context = "placed",
                    x = s:getX() + 0.5,
                    y = s:getY() + 0.5,
                    z = s:getZ()
                }
                e.state.playbackMode = ((resolvedOutputForMode == "world" or resolvedOutputForMode == "silent") or trackedPortable) and "world" or "inventory"
            end
        else
            source = { mode = "inventory", context = "inventory" }
            e.state.playbackMode = "inventory"
        end

        NMPlaybackRuntime.syncDevice(player, e.profile, e.state, source, tickCount * 60)
        local sourceKind = (source and source.mode == "world") and "world_item" or "inventory"
        consumeAndDispatchTrackFinished(player, e.profile, e.state, nil, e.item, sourceKind, e.uuid)
        valid[e.uuid] = true
        inventoryOwners[e.uuid] = true
        currentInventoryByUuid[e.uuid] = e.item
        if source and source.mode == "world" and source.x and source.y and source.z then
            spPulseCandidates[e.uuid] = {
                profile = e.profile,
                state = e.state,
                source = source
            }
        end
    end

    reconcileDroppedInventoryToPlacedSP(player, currentInventoryByUuid)

    if NMClientPortableDropHandoff and NMClientPortableDropHandoff.collectPendingPlayback then
        local pendingPlayback = {}
        NMClientPortableDropHandoff.collectPendingPlayback(player, currentInventoryByUuid, pendingPlayback)
        for i = 1, #pendingPlayback do
            local p = pendingPlayback[i]
            if p and p.uuid and p.profile and p.state and p.source then
                p.state.playbackMode = "world"
                NMPlaybackRuntime.syncDevice(player, p.profile, p.state, p.source, tickCount * 60)
                consumeAndDispatchTrackFinished(player, p.profile, p.state, nil, p.item, "drop_pending", p.uuid)
                valid[p.uuid] = true
                if tostring(p.source.context or "") == "placed"
                    and not spPulseCandidates[p.uuid]
                    and p.source.x and p.source.y and p.source.z then
                    spPulseCandidates[p.uuid] = {
                        profile = p.profile,
                        state = p.state,
                        source = p.source
                    }
                end
            end
        end
    end

    local detached = {}
    NMClientWorldSourceCache.collectInRange(player, detached)
    for i = 1, #detached do
        local d = detached[i]
        local entry = d.entry
        local state = entry and entry.stateSnapshot or nil
        local profile = d.profile
        if state and profile and state.deviceUUID then
            local uuid = tostring(state.deviceUUID)
            local liveEntry = NMClientWorldSourceCache.get and NMClientWorldSourceCache.get(uuid) or nil
            local src = entry and entry.source or nil
            local detachedContext = tostring(src and src.context or "unknown")
            local hasInventoryOwner = inventoryOwners[uuid] == true
            local allowDetachedSync = true
            local previousConflictState = NMClientPlaybackTick.ownershipConflictState[uuid]
            local nowMs = nowRealMs()
            local detachedLogKey = tostring(uuid) .. "|inventory_owner"
            local lastDetachedRemoveMs = tonumber(NMClientPlaybackTick.detachedRemoveLogMs[detachedLogKey]) or 0
            local ownershipGate = detachedOrchestration.applyInventoryOwnershipGate
                and detachedOrchestration.applyInventoryOwnershipGate({
                    hasInventoryOwner = hasInventoryOwner,
                    detachedContext = detachedContext,
                    previousConflictState = previousConflictState,
                    nowMsValue = nowMs,
                    lastDetachedRemoveMs = lastDetachedRemoveMs,
                    detachedRemoveIntervalMs = 5000
                })
                or nil
            local conflictStateKey = ownershipGate and ownershipGate.conflictStateKey
                or (tostring(hasInventoryOwner == true) .. ":" .. tostring(detachedContext or "unknown"))
            local conflictChanged = ownershipGate and ownershipGate.conflictChanged == true
                or (previousConflictState ~= conflictStateKey)
            NMClientPlaybackTick.ownershipConflictState[uuid] = conflictStateKey

            if hasInventoryOwner then
                local portableOwnedDetached = NMDeviceProfiles
                    and NMDeviceProfiles.isPortableTrackedProfile
                    and NMDeviceProfiles.isPortableTrackedProfile(profile) == true
                if conflictChanged then
                    logTransitionProbe(
                        "ownership_conflict_detected",
                        string.format("uuid=%s inventory=true detachedCtx=%s", uuid, detachedContext)
                    )
                end

                local shouldPrune = portableOwnedDetached or (ownershipGate and ownershipGate.shouldPrune == true
                    or (detachedOrchestration.shouldPruneDetachedForInventoryOwner
                        and detachedOrchestration.shouldPruneDetachedForInventoryOwner(hasInventoryOwner, detachedContext))
                    or (hasInventoryOwner == true and tostring(detachedContext or "") ~= "vehicle"))
                if shouldPrune then
                    if conflictChanged then
                        logTransitionProbe(
                            "detached_skip_inventory_owner",
                            string.format(
                                "uuid=%s detachedCtx=%s portable=%s",
                                uuid,
                                detachedContext,
                                tostring(portableOwnedDetached == true)
                            )
                        )
                    end
                    NMClientWorldSourceCache.remove(uuid)
                    if conflictChanged and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                        local shouldEmitDetachedRemove = ownershipGate and ownershipGate.shouldEmitDetachedRemove == true
                            or (detachedOrchestration.shouldEmitDetachedRemove
                                and detachedOrchestration.shouldEmitDetachedRemove(nowMs, lastDetachedRemoveMs, 5000))
                            or ((nowMs - lastDetachedRemoveMs) >= 5000)
                        if shouldEmitDetachedRemove then
                            NMClientPlaybackTick.detachedRemoveLogMs[detachedLogKey] = nowMs
                            NMCore.logChannel(
                                "runtimeProbe",
                                "detached_track_remove",
                                string.format("uuid=%s reason=inventory_owner", uuid)
                            )
                        end
                    end
                    if conflictChanged then
                        logTransitionProbe(
                            "detached_pruned_inventory_owner",
                            string.format(
                                "uuid=%s detachedCtx=%s portable=%s",
                                uuid,
                                detachedContext,
                                tostring(portableOwnedDetached == true)
                            )
                        )
                        logTransitionProbe(
                            "ownership_conflict_resolved",
                            string.format(
                                "uuid=%s winner=inventory detachedCtx=%s portable=%s",
                                uuid,
                                detachedContext,
                                tostring(portableOwnedDetached == true)
                            )
                        )
                    end
                    allowDetachedSync = false
                else
                    if conflictChanged then
                        logTransitionProbe(
                            "ownership_conflict_resolved",
                            string.format("uuid=%s winner=vehicle detachedCtx=%s", uuid, detachedContext)
                        )
                    end
                end
            end

            if allowDetachedSync then
                if detachedContext == "vehicle" then
                    local continuityResult = continuity.applyDetachedVehicleContinuity
                        and continuity.applyDetachedVehicleContinuity({
                            uuid = uuid,
                            entry = entry,
                            liveEntry = liveEntry,
                            state = state,
                            src = src,
                            detachedContext = detachedContext,
                            nowMs = nowRealMs(),
                            resolveVehicleCanonicalGeneration = resolveVehicleCanonicalGeneration,
                            persistVehicleCanonicalGeneration = persistVehicleCanonicalGeneration,
                            setVehicleIdentityState = setVehicleIdentityState
                        })
                        or nil
                    if continuityResult then
                        entry = continuityResult.entry or entry
                        liveEntry = continuityResult.liveEntry or liveEntry
                        state = continuityResult.state or state
                        src = continuityResult.src or src
                        detachedContext = tostring(continuityResult.detachedContext or detachedContext)
                    end
                end
            end

            if allowDetachedSync then
                if detachedContext == "vehicle" then
                    applySPLocalVehiclePowerGuard(profile, state, src, uuid)
                end
                if NMCore and NMCore.logChannel and NMCore.shouldLogEvery and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                    local key = detachedOrchestration.makeDetachedSyncLogKey
                        and detachedOrchestration.makeDetachedSyncLogKey(state.deviceUUID)
                        or ("runtimeProbe.detached." .. tostring(state.deviceUUID))
                    if NMCore.shouldLogEvery(key, NMClientPlaybackTick.tick, 2400) then
                        NMCore.logChannel(
                            "runtimeProbe",
                            "detached_sync",
                            detachedOrchestration.buildDetachedSyncDetail
                                and detachedOrchestration.buildDetachedSyncDetail(state, src)
                                or string.format(
                                    "uuid=%s ctx=%s x=%.2f y=%.2f z=%.2f isOn=%s isPlaying=%s media=%s",
                                    tostring(state.deviceUUID),
                                    tostring(src and src.context or "nil"),
                                    tonumber(src and src.x or 0) or 0,
                                    tonumber(src and src.y or 0) or 0,
                                    tonumber(src and src.z or 0) or 0,
                                    tostring(state.isOn == true),
                                    tostring(state.isPlaying == true),
                                    tostring(state.mediaFullType or "nil")
                                )
                        )
                    end
                end
                NMPlaybackRuntime.syncDevice(player, profile, state, entry.source, tickCount * 60)
                local sourceKind = detachedContext == "vehicle" and "vehicle" or "detached_item"
                consumeAndDispatchTrackFinished(player, profile, state, entry, nil, sourceKind, uuid)
                valid[tostring(state.deviceUUID)] = true
                if not spPulseCandidates[uuid] then
                    local detachedSource = entry and entry.source or nil
                    if detachedSource and detachedSource.x and detachedSource.y and detachedSource.z then
                        spPulseCandidates[uuid] = {
                            profile = profile,
                            state = state,
                            source = detachedSource
                        }
                    end
                end
            end
        end
    end

    NMClientSPLocalRuntime.emitZombiePulses(player, spPulseCandidates, {
        zombiePulseMs = NMClientPlaybackTick.zombiePulseMs,
        zombiePulsePos = NMClientPlaybackTick.zombiePulsePos,
        nowMs = nowRealMs
    })

    if NMClientModeSync and NMClientModeSync.prune then
        NMClientModeSync.prune(valid)
    end
    for ownedUuid, _ in pairs(NMClientPlaybackTick.ownershipConflictState or {}) do
        if not valid[ownedUuid] then
            NMClientPlaybackTick.ownershipConflictState[ownedUuid] = nil
        end
    end
    NMClientModeReconcile.pruneAuthority(valid)
    NMPlaybackRuntime.stopMissing(player, valid, NMClientPlaybackTick.tick)
end

