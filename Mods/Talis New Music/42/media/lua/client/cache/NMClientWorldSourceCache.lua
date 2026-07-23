-- Client cache of detached world sources populated from server registry updates.
NMClientWorldSourceCache = NMClientWorldSourceCache or {}
NMClientWorldSourceCache.entries = NMClientWorldSourceCache.entries or {}
local payloadLineageSeen = payloadLineageSeen or {}
local vehicleTruthSeen = vehicleTruthSeen or {}
local vehicleTruthMsSeen = vehicleTruthMsSeen or {}
local capabilityMatrixSeen = capabilityMatrixSeen or {}

local function nowMs()
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

local function clonePayload(payload)
    local out = {}
    for k, v in pairs(payload or {}) do
        out[k] = v
    end
    return out
end

local function logSqlAnchorLineage(uuid, entry, path, reason)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")) then
        return
    end
    local nowStamp = nowMs()
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
        if payloadLastMs > 0 and (nowStamp - payloadLastMs) < 120000 then
            return
        end
        payloadLineageSeen[payloadKey] = nowStamp
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
    local key = tostring(path or "unknown")
    entry._lineageSigByPath = entry._lineageSigByPath or {}
    entry._lineageMsByPath = entry._lineageMsByPath or {}
    local lastSig = tostring(entry._lineageSigByPath[key] or "")
    local lastMs = tonumber(entry._lineageMsByPath[key]) or 0
    local cooldownMs = isPayloadPath and 120000 or 20000
    if lastSig == sig and (nowStamp - lastMs) < cooldownMs then
        return
    end
    if isPayloadPath and lastMs > 0 and (nowStamp - lastMs) < cooldownMs then
        return
    end
    entry._lineageSigByPath[key] = sig
    entry._lineageMsByPath[key] = nowStamp
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

local function encodeCandidatePool(candidates)
    local parts = {}
    local cap = math.min(#(candidates or {}), 12)
    for i = 1, cap do
        local c = candidates[i] or {}
        local distance = tonumber(c.distance)
        if distance == nil and tonumber(c.distSq) ~= nil then
            distance = math.sqrt(math.max(0, tonumber(c.distSq) or 0))
        end
        parts[#parts + 1] = string.format(
            "{runtimeId=%s,sqlId=%s,scriptName=%s,source=%s,distance=%s}",
            tostring(c.runtimeId or ""),
            tostring(c.sqlId or ""),
            tostring(c.scriptName or ""),
            tostring(c.source or ""),
            tostring(distance ~= nil and string.format("%.2f", distance) or "nil")
        )
    end
    return table.concat(parts, ";")
end

local function candidateHash(candidates)
    local parts = {}
    local cap = math.min(#(candidates or {}), 12)
    for i = 1, cap do
        local c = candidates[i] or {}
        parts[#parts + 1] = table.concat({
            tostring(c.runtimeId or ""),
            tostring(c.sqlId or ""),
            tostring(c.scriptName or "")
        }, "|")
    end
    return table.concat(parts, ";")
end

local function encodeIdList(list)
    return table.concat(list or {}, ",")
end

local function truthToken(entry)
    local s = entry and entry.stateSnapshot or nil
    return table.concat({
        tostring(entry and entry.uuid or ""),
        tostring(entry and entry.sourceGeneration or 0),
        tostring(s and s.revision or 0),
        tostring(s and s.playbackEpoch or 0)
    }, "|")
end

local function logVehicleTruth(probeName, entry, reason, detail, extraSig, ttlMs)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleTruthProbe")) then
        return
    end
    local token = truthToken(entry)
    local sig = table.concat({
        tostring(probeName or ""),
        tostring(entry and entry.uuid or ""),
        tostring(token),
        tostring(reason or ""),
        tostring(extraSig or "")
    }, "|")
    local now = nowMs()
    local ttl = tonumber(ttlMs) or 20000
    NMVehicleTruthProbeAdapter.emit(
        vehicleTruthSeen,
        vehicleTruthMsSeen,
        tostring(entry and entry.uuid or "") .. ":" .. tostring(probeName or "vehicle_truth"),
        sig,
        ttl,
        function()
            NMCore.logChannel(
                "vehicleTruthProbe",
                tostring(probeName or "vehicle_truth"),
                string.format(
                    "traceToken=%s sessionToken=%s reason=%s %s",
                    tostring(token),
                    tostring(entry and entry._lastSessionToken or "nil"),
                    tostring(reason or "none"),
                    tostring(detail or "")
                )
            )
        end
    )
end

local function logVehicleCapabilityMatrix(entry, update)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleTruthProbe")) then
        return
    end
    local state = entry and entry.stateSnapshot or {}
    local source = entry and entry.source or {}
    local candidateRuntimeIds = encodeIdList(update and update.candidateRuntimeIds or {})
    local candidateSqlIds = encodeIdList(update and update.candidateSqlIds or {})
    local attachStatus = tostring(update and update.attachStatus or "unknown")
    local sig = table.concat({
        tostring(entry and entry.uuid or ""),
        tostring(entry and entry.sourceGeneration or 0),
        tostring(state and state.revision or 0),
        tostring(state and state.playbackEpoch or 0),
        tostring(entry and entry._authorityVehicleIdHint or entry and entry.vehicleIdHint or ""),
        tostring(update and update.attachedRuntimeId or ""),
        tostring(candidateRuntimeIds),
        tostring(candidateSqlIds),
        tostring(attachStatus)
    }, "|")
    local key = tostring(entry and entry.uuid or "")
    local now = nowMs()
    local lastSig = tostring(capabilityMatrixSeen[key .. ".sig"] or "")
    local lastMs = tonumber(capabilityMatrixSeen[key .. ".ms"]) or 0
    if sig == lastSig and (now - lastMs) < 20000 then
        return
    end
    capabilityMatrixSeen[key .. ".sig"] = sig
    capabilityMatrixSeen[key .. ".ms"] = now
    NMCore.logChannel(
        "vehicleTruthProbe",
        "vehicle_id_capability_matrix",
        string.format(
            "traceToken=%s sessionToken=%s uuid=%s sourceGen=%s revision=%s playbackEpoch=%s runtimeVehicleIdHint=%s attachedRuntimeId=%s partId=%s sourceX=%.2f sourceY=%.2f sourceZ=%.2f candidateRuntimeIds=%s candidateSqlIds=%s attachStatus=%s",
            tostring(truthToken(entry)),
            tostring(entry and entry._lastSessionToken or "nil"),
            tostring(entry and entry.uuid or ""),
            tostring(entry and entry.sourceGeneration or 0),
            tostring(state and state.revision or 0),
            tostring(state and state.playbackEpoch or 0),
            tostring(entry and entry._authorityVehicleIdHint or entry and entry.vehicleIdHint or ""),
            tostring(update and update.attachedRuntimeId or ""),
            tostring(entry and entry.partId or "Radio"),
            tonumber(source and source.x) or 0,
            tonumber(source and source.y) or 0,
            tonumber(source and source.z) or 0,
            tostring(candidateRuntimeIds),
            tostring(candidateSqlIds),
            tostring(attachStatus)
        )
    )
end

function NMClientWorldSourceCache.get(uuid)
    return NMClientWorldSourceCache.entries[tostring(uuid or "")]
end

function NMClientWorldSourceCache.remove(uuid)
    local key = tostring(uuid or "")
    if key == "" then return end
    NMClientWorldSourceCache.entries[key] = nil
end

function NMClientWorldSourceCache.upsertFromPayload(payload, serverSessionToken)
    if not payload then return nil end
    local uuid = tostring(payload.uuid or "")
    if uuid == "" then return nil end

    local entry = NMClientWorldSourceCache.entries[uuid] or {}
    local previousAcceptedGen = math.max(
        tonumber(entry._acceptedSourceGeneration) or 0,
        tonumber(entry.sourceEpoch) or 0,
        tonumber(entry.stateSnapshot and entry.stateSnapshot.sourceGeneration) or 0
    )
    local incomingSourceEpoch = tonumber(payload.sourceEpoch) or tonumber(payload.sourceGeneration) or 0
    local incomingSourceGeneration = tonumber(payload.sourceGeneration) or incomingSourceEpoch
    local incomingVehicleId = tostring(payload.vehicleId or "")
    local incomingVehicleIdHint = tostring(payload.vehicleIdHint or incomingVehicleId or "")
    local incomingVehicleSqlId = tostring(payload.vehicleSqlId or "")
    local incomingVehicleSqlIdHint = tostring(payload.vehicleSqlIdHint or incomingVehicleSqlId or "")
    local hasIncomingSqlAnchor = incomingVehicleSqlId ~= "" or incomingVehicleSqlIdHint ~= ""
    local incomingOwnerOnlineId = tostring(payload.ownerOnlineId or "")
    local incomingOwnerUsername = tostring(payload.ownerUsername or "")
    local incomingOwnerId = tostring(payload.ownerId or incomingOwnerOnlineId or incomingOwnerUsername or "")
    local incomingPartId = tostring(payload.partId or entry.partId or "Radio")
    local incomingSourceMode = tostring(payload.sourceMode or (entry.kind == "vehicle" and "vehicle" or "placed"))
    local incomingRebindReason = payload.rebindReason ~= nil and tostring(payload.rebindReason or "") or ""
    local hasRebindTransition = incomingRebindReason ~= ""
    entry.uuid = uuid
    entry.kind = tostring(payload.kind or "item")
    entry.profileType = payload.profileType
    entry.stateSnapshot = payload.state
    local canReplaceIdentityAnchor = incomingSourceEpoch > previousAcceptedGen or hasRebindTransition
    local priorVehicleSqlId = tostring(entry.vehicleSqlId or "")
    local priorVehicleSqlIdHint = tostring(entry.vehicleSqlIdHint or "")
    entry.vehicleIdHint = incomingVehicleIdHint ~= "" and incomingVehicleIdHint or tostring(entry.vehicleIdHint or "")
    if incomingVehicleSqlIdHint ~= "" then
        if canReplaceIdentityAnchor or priorVehicleSqlIdHint == "" then
            entry.vehicleSqlIdHint = incomingVehicleSqlIdHint
        else
            entry.vehicleSqlIdHint = priorVehicleSqlIdHint
        end
    else
        entry.vehicleSqlIdHint = priorVehicleSqlIdHint
    end
    entry.ownerId = incomingOwnerId ~= "" and incomingOwnerId or tostring(entry.ownerId or entry.ownerOnlineId or entry.ownerUsername or "")
    entry.ownerOnlineId = incomingOwnerOnlineId ~= "" and incomingOwnerOnlineId or tostring(entry.ownerOnlineId or "")
    entry.ownerUsername = incomingOwnerUsername ~= "" and incomingOwnerUsername or tostring(entry.ownerUsername or "")
    entry.sourceGeneration = math.max(tonumber(entry.sourceGeneration) or 0, incomingSourceGeneration)
    local mergedVehicleId = tostring(entry.vehicleId or "")
    if mergedVehicleId == "" and hasIncomingSqlAnchor then
        mergedVehicleId = incomingVehicleId
    elseif incomingVehicleId ~= "" then
        if hasIncomingSqlAnchor and (incomingSourceEpoch > previousAcceptedGen or hasRebindTransition) then
            mergedVehicleId = incomingVehicleId
        end
    end
    local incomingResolvedFlag = payload.vehicleResolved == true
    local sourceVehicleSqlId = incomingVehicleSqlId ~= "" and incomingVehicleSqlId or priorVehicleSqlId
    local sourceVehicleSqlIdHint = incomingVehicleSqlIdHint ~= "" and incomingVehicleSqlIdHint or priorVehicleSqlIdHint
    if not canReplaceIdentityAnchor and priorVehicleSqlId ~= "" then
        sourceVehicleSqlId = priorVehicleSqlId
        sourceVehicleSqlIdHint = priorVehicleSqlIdHint ~= "" and priorVehicleSqlIdHint or priorVehicleSqlId
    end
    entry.source = {
        mode = "world",
        context = incomingSourceMode,
        x = tonumber(payload.x) or 0,
        y = tonumber(payload.y) or 0,
        z = tonumber(payload.z) or 0,
        vehicleId = mergedVehicleId ~= "" and mergedVehicleId or (hasIncomingSqlAnchor and incomingVehicleId or ""),
        vehicleIdHint = incomingVehicleIdHint ~= "" and incomingVehicleIdHint or tostring(entry.vehicleIdHint or ""),
        vehicleSqlId = sourceVehicleSqlId,
        vehicleSqlIdHint = sourceVehicleSqlIdHint,
        ownerId = incomingOwnerId ~= "" and incomingOwnerId or tostring(entry.ownerId or ""),
        ownerOnlineId = incomingOwnerOnlineId ~= "" and incomingOwnerOnlineId or tostring(entry.ownerOnlineId or ""),
        ownerUsername = incomingOwnerUsername ~= "" and incomingOwnerUsername or tostring(entry.ownerUsername or ""),
        windowsOpen = payload.windowsOpen == true,
        _vehicleResolved = incomingResolvedFlag
    }
    entry.itemId = payload.itemId
    entry.itemFullType = payload.itemFullType
    entry.vehicleId = mergedVehicleId ~= "" and mergedVehicleId or (hasIncomingSqlAnchor and incomingVehicleId or "")
    if incomingVehicleSqlId ~= "" then
        if canReplaceIdentityAnchor or priorVehicleSqlId == "" then
            entry.vehicleSqlId = incomingVehicleSqlId
        else
            entry.vehicleSqlId = priorVehicleSqlId
        end
    else
        entry.vehicleSqlId = priorVehicleSqlId
    end
    entry.partId = incomingPartId
    entry.sourceEpoch = incomingSourceEpoch
    entry.sourceGeneration = math.max(tonumber(entry.sourceGeneration) or 0, incomingSourceGeneration, incomingSourceEpoch)
    entry.sourceMode = incomingSourceMode
    entry.rebindReason = hasRebindTransition and incomingRebindReason or nil
    entry._authorityVehicleIdHint = incomingVehicleIdHint ~= "" and incomingVehicleIdHint or entry._authorityVehicleIdHint
    entry._authorityVehicleSqlIdHint = incomingVehicleSqlIdHint ~= "" and incomingVehicleSqlIdHint or entry._authorityVehicleSqlIdHint
    entry._authorityPartIdHint = incomingPartId ~= "" and incomingPartId or entry._authorityPartIdHint
    entry._authorityOwnerIdHint = incomingOwnerId ~= "" and incomingOwnerId or entry._authorityOwnerIdHint
    entry._authorityRebindReason = hasRebindTransition and incomingRebindReason or nil
    entry._authorityRebindEpoch = hasRebindTransition and incomingSourceGeneration or tonumber(entry._authorityRebindEpoch) or 0
    local resolvedSessionToken = tostring(serverSessionToken or payload and payload.serverSessionToken or entry._lastSessionToken or "")
    entry._lastSessionToken = resolvedSessionToken
    local stickySql = tostring(entry._stickyLastResolvedVehicleSqlId or "")
    local incomingSql = tostring(entry.vehicleSqlId or "")
    if stickySql ~= "" and incomingSql ~= "" and stickySql ~= incomingSql then
        entry._stickySqlBindingActive = false
        entry._stickyLastResolvedVehicleId = nil
        entry._stickyLastResolvedVehicleSqlId = ""
        entry._stickyLastResolvedPartId = ""
        entry._stickyLastResolvedAtMs = 0
        entry._stickySqlBindingAtMs = 0
    end
    if tostring(entry.kind or "") == "vehicle" then
        local continuityState = tostring(entry._vehicleIdentityState or "")
        if continuityState == "" then
            continuityState = (entry.source and entry.source._vehicleResolved == false) and "DETACHED_CONTINUITY" or "LIVE_RESOLVED"
        end
        entry._vehicleIdentityState = continuityState
    end
    entry._acceptedSourceGeneration = math.max(
        tonumber(entry._acceptedSourceGeneration) or 0,
        tonumber(entry.sourceGeneration) or 0,
        tonumber(entry.sourceEpoch) or 0,
        tonumber(entry.stateSnapshot and entry.stateSnapshot.sourceGeneration) or 0
    )
    entry.lastSeenRealMs = nowMs()
    NMClientWorldSourceCache.entries[uuid] = entry
    if tostring(entry.kind or "") == "vehicle"
        and NMClientVehicleSqlSnapshotResolver
        and NMClientVehicleSqlSnapshotResolver.markDirty then
        NMClientVehicleSqlSnapshotResolver.markDirty("vehicle_authority_upsert")
    end
    logSqlAnchorLineage(uuid, entry, "client_upsert_payload", tostring(payload and payload.rebindReason or "payload"))
    return entry
end

function NMClientWorldSourceCache.refreshVehicleSource(uuid)
    local key = tostring(uuid or "")
    if key == "" then return nil end
    local entry = NMClientWorldSourceCache.entries[key]
    if not entry or tostring(entry.kind or "") ~= "vehicle" then
        return entry
    end

    local update = NMClientVehicleSourceUpdater and NMClientVehicleSourceUpdater.update and NMClientVehicleSourceUpdater.update(entry) or nil
    if not update then
        return entry
    end
    entry = update.entry or entry
    local source = update.source or entry.source or {}
    local result = update.result or {}
    local resolved = update.resolved == true
    local resolutionMode = tostring(update.resolutionMode or "stream_authority_unresolved")
    local resolutionReason = tostring(update.resolutionReason or (result and (result.reason or result.stage or result.matchReason)) or "stream_authority_unresolved")
    local prevX = tonumber(update.prevX) or 0
    local prevY = tonumber(update.prevY) or 0
    local prevZ = tonumber(update.prevZ) or 0
    local nx = tonumber(update.nx) or prevX
    local ny = tonumber(update.ny) or prevY
    local nz = tonumber(update.nz) or prevZ
    local movedDist = tonumber(update.movedDist) or 0
    local degraded = update.degraded == true
    local attachStatus = tostring(update.attachStatus or (resolved and "attached" or "degraded"))
    local snapshotMeta = update.snapshotMeta or nil
    local lastResolved = entry._lastRefreshResolved
    local resolvedChanged = (lastResolved == nil) or (lastResolved ~= resolved)
    entry._lastRefreshResolved = resolved
    entry._vehicleSourceResolved = resolved == true
    entry._vehicleResolutionMode = resolutionMode
    if tostring(entry.kind or "") == "vehicle" then
        local nextState = source and source._vehicleResolved == true and "LIVE_RESOLVED" or "DETACHED_CONTINUITY"
        local prevState = tostring(entry._vehicleIdentityState or "")
        if prevState ~= nextState then
            entry._vehicleIdentityState = nextState
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                NMCore.logChannel(
                    "runtimeProbe",
                    "vehicle_identity_state_transition",
                    string.format(
                        "uuid=%s from=%s to=%s reason=%s",
                        tostring(key),
                        tostring(prevState ~= "" and prevState or "nil"),
                        tostring(nextState),
                        tostring(resolutionMode)
                    )
                )
            end
        end
    end
    if resolvedChanged then
        entry._vehicleResolutionEpoch = (tonumber(entry._vehicleResolutionEpoch) or 0) + 1
        if resolved then
            entry._vehicleLastResolvedMs = nowMs()
        else
            entry._vehicleLastUnresolvedMs = nowMs()
        end
        logVehicleTruth(
            "vehicle_truth_resolve_decision",
            entry,
            tostring(resolutionReason),
            string.format("decision=%s mode=%s", tostring(resolved and "resolved_attachment" or "unresolved_degraded"), tostring(resolutionMode)),
            tostring(resolved) .. "|" .. tostring(resolutionMode),
            0
        )
    end

    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        local resolvedVehicleId = tostring(update and update.attachedRuntimeId or source.vehicleId or entry.vehicleId or "nil")
        local attemptSig = string.format(
            "%s|%s|%s|%s",
            tostring(resolved),
            tostring(resolutionMode),
            tostring(resolvedVehicleId),
            tostring(attachStatus)
        )
        if tostring(entry._vehicleResolveAttemptSig or "") ~= attemptSig then
            entry._vehicleResolveAttemptSig = attemptSig
            NMCore.logChannel(
                "runtimeProbe",
                "vehicle_resolve_attempt",
                string.format(
                    "uuid=%s resolved=%s mode=%s reason=%s vehicleId=%s vehicleSqlId=%s sourceGen=%s degraded=%s attachStatus=%s candidateSource=%s partMatch=%s partUuid=%s",
                    tostring(key),
                    tostring(resolved),
                    tostring(resolutionMode),
                    tostring(resolutionReason),
                    tostring(resolvedVehicleId),
                    tostring(entry.vehicleSqlId or "nil"),
                    tostring(entry.sourceGeneration or 0),
                    tostring(degraded),
                    tostring(attachStatus),
                    tostring(result and result.candidateSource or ""),
                    tostring(result and result.partMatches == true),
                    tostring(result and result.partUuid or "")
                )
            )
        end
    end

    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        local shouldLog = resolvedChanged or movedDist >= 1.0
        if shouldLog then
            NMCore.logChannel(
                    "runtimeProbe",
                    "vehicle_source_refresh",
                    string.format(
                    "uuid=%s resolved=%s mode=%s old=%.2f,%.2f,%.2f new=%.2f,%.2f,%.2f vehicleId=%s degraded=%s",
                    key,
                    tostring(resolved),
                    tostring(resolutionMode),
                    prevX, prevY, prevZ,
                    nx, ny, nz,
                    tostring(source.vehicleId or entry.vehicleId or "nil"),
                    tostring(degraded)
                )
            )
        end
        local nowStamp = nowMs()
        local statusSig = table.concat({ tostring(resolved), tostring(resolutionMode), tostring(resolutionReason) }, "|")
        entry._probeSigStoreStatus = entry._probeSigStoreStatus or {}
        entry._probeMsStoreStatus = entry._probeMsStoreStatus or {}
        local statusKey = "vehicleSourceResolutionStatus." .. tostring(key)
        if NMRuntimeProbeAdapter.shouldEmitTransitionOrHeartbeat(
            entry._probeSigStoreStatus,
            entry._probeMsStoreStatus,
            statusKey,
            statusSig,
            20000
        ) then
            NMCore.logChannel(
                "runtimeProbe",
                "vehicle_source_resolution_status",
                string.format(
                    "uuid=%s status=%s mode=%s used_for_routing=false reason=%s",
                    tostring(key),
                    tostring(resolved and "resolved" or "unresolved"),
                    tostring(resolutionMode),
                    tostring(resolutionReason)
                )
            )
            if not resolved then
                local candidates = result and result.candidates or {}
                local traceState = entry and entry.stateSnapshot or nil
                logVehicleTruth(
                    "vehicle_truth_unresolved_evidence",
                    entry,
                    tostring(resolutionReason),
                    string.format(
                        "uuid=%s wantedSql=%s sourceGen=%s revision=%s playbackEpoch=%s partId=%s attachStatus=%s observedCandidates=%s",
                        tostring(key),
                        tostring(entry.vehicleSqlId or entry.vehicleSqlIdHint or ""),
                        tostring(entry and entry.sourceGeneration or 0),
                        tostring(traceState and traceState.revision or 0),
                        tostring(traceState and traceState.playbackEpoch or 0),
                        tostring(entry and entry.partId or ""),
                        tostring(attachStatus),
                        tostring(encodeCandidatePool(candidates))
                    ),
                    candidateHash(candidates),
                    20000
                )
                entry._probeSigStoreSnapshot = entry._probeSigStoreSnapshot or {}
                entry._probeMsStoreSnapshot = entry._probeMsStoreSnapshot or {}
                local snapshotSig = table.concat({ tostring(entry.sourceGeneration or 0), tostring(resolutionReason), tostring(attachStatus) }, "|")
                local snapshotKey = "sqlAnchorSnapshot." .. tostring(key)
                local shouldSnapshot = NMRuntimeProbeAdapter.shouldEmitTransitionOrHeartbeat(
                    entry._probeSigStoreSnapshot,
                    entry._probeMsStoreSnapshot,
                    snapshotKey,
                    snapshotSig,
                    20000
                )
                if shouldSnapshot then
                    NMCore.logChannel(
                        "runtimeProbe",
                        "sql_anchor_candidate_pool_snapshot",
                        string.format(
                            "uuid=%s sourceGen=%s playbackEpoch=%s wantedSql=%s reason=%s attachStatus=%s candidateCount=%d sourceSqlCell=%s sourceSqlWorldCell=%s sourceSqlSquare=%s sourceSqlFinal=%s candidates=%s",
                            tostring(key),
                            tostring(entry.sourceGeneration or 0),
                            tostring(entry.stateSnapshot and entry.stateSnapshot.playbackEpoch or 0),
                            tostring(entry.vehicleSqlId or entry.vehicleSqlIdHint or ""),
                            tostring(resolutionReason),
                            tostring(attachStatus),
                            tonumber(#candidates) or 0,
                            tostring(snapshotMeta and snapshotMeta.sourceSqlCell or ""),
                            tostring(snapshotMeta and snapshotMeta.sourceSqlWorldCell or ""),
                            tostring(snapshotMeta and snapshotMeta.sourceSqlSquare or ""),
                            tostring(snapshotMeta and snapshotMeta.sourceSqlFinal or ""),
                            tostring(encodeCandidatePool(candidates))
                        )
                    )
                end
            end
            local hasSnapshotBuild = snapshotMeta and tonumber(snapshotMeta.builtAtMs) and tonumber(snapshotMeta.builtAtMs) > 0
            if hasSnapshotBuild and NMCore and NMCore.logChannel then
                local snapshotSig = table.concat({
                    tostring(snapshotMeta.builtAtMs or 0),
                    tostring(snapshotMeta.entryCount or 0),
                    tostring(snapshotMeta.poolSource or "none"),
                    tostring(snapshotMeta.cellCount or 0),
                    tostring(snapshotMeta.worldCellCount or 0),
                    tostring(snapshotMeta.squareScanCount or 0),
                    tostring(snapshotMeta.finalCount or 0),
                    tostring(snapshotMeta.sourceSqlCell or ""),
                    tostring(snapshotMeta.sourceSqlWorldCell or ""),
                    tostring(snapshotMeta.sourceSqlSquare or ""),
                    tostring(snapshotMeta.sourceSqlFinal or "")
                }, "|")
                entry._probeSigStoreResolver = entry._probeSigStoreResolver or {}
                entry._probeMsStoreResolver = entry._probeMsStoreResolver or {}
                local snapshotStateKey = "resolverSnapshotState." .. tostring(key)
                if NMRuntimeProbeAdapter.shouldEmitTransitionOrHeartbeat(
                    entry._probeSigStoreResolver,
                    entry._probeMsStoreResolver,
                    snapshotStateKey,
                    snapshotSig,
                    20000
                ) then
                    NMCore.logChannel(
                        "runtimeProbe",
                        "resolver_snapshot_state",
                        string.format(
                            "uuid=%s builtAtMs=%s ageMs=%s entryCount=%s poolSource=%s cellCount=%s worldCellCount=%s squareScanCount=%s finalCount=%s sourceSqlCell=%s sourceSqlWorldCell=%s sourceSqlSquare=%s sourceSqlFinal=%s",
                            tostring(key),
                            tostring(snapshotMeta.builtAtMs or 0),
                            tostring(snapshotMeta.ageMs or 0),
                            tostring(snapshotMeta.entryCount or 0),
                            tostring(snapshotMeta.poolSource or "none"),
                            tostring(snapshotMeta.cellCount or 0),
                            tostring(snapshotMeta.worldCellCount or 0),
                            tostring(snapshotMeta.squareScanCount or 0),
                            tostring(snapshotMeta.finalCount or 0),
                            tostring(snapshotMeta.sourceSqlCell or ""),
                            tostring(snapshotMeta.sourceSqlWorldCell or ""),
                            tostring(snapshotMeta.sourceSqlSquare or ""),
                            tostring(snapshotMeta.sourceSqlFinal or "")
                        )
                    )
                end
                logVehicleTruth(
                    "vehicle_truth_snapshot_build",
                    entry,
                    "snapshot_state",
                    string.format(
                        "builtAtMs=%s ageMs=%s cellCount=%s worldCellCount=%s squareScanCount=%s finalCount=%s poolSource=%s",
                        tostring(snapshotMeta.builtAtMs or 0),
                        tostring(snapshotMeta.ageMs or 0),
                        tostring(snapshotMeta.cellCount or 0),
                        tostring(snapshotMeta.worldCellCount or 0),
                        tostring(snapshotMeta.squareScanCount or 0),
                        tostring(snapshotMeta.finalCount or 0),
                        tostring(snapshotMeta.poolSource or "none")
                    ),
                    table.concat({
                        tostring(snapshotMeta.cellCount or 0),
                        tostring(snapshotMeta.worldCellCount or 0),
                        tostring(snapshotMeta.squareScanCount or 0),
                        tostring(snapshotMeta.finalCount or 0),
                        tostring(snapshotMeta.poolSource or "none")
                    }, "|"),
                    20000
                )
            end
        end
    end

    logVehicleCapabilityMatrix(entry, update)
    logSqlAnchorLineage(key, entry, "client_vehicle_source_refresh", resolutionReason)
    NMClientWorldSourceCache.entries[key] = entry
    return entry
end

function NMClientWorldSourceCache.onRegistryUpdate(op, payload, serverSessionToken)
    local opName = tostring(op or "")
    if opName == "remove" then
        NMClientWorldSourceCache.remove(payload and payload.uuid)
        return nil
    end
    if opName == "upsert" then
        return NMClientWorldSourceCache.upsertFromPayload(payload, serverSessionToken)
    end
    return nil
end

function NMClientWorldSourceCache.collectInRange(player, out)
    if not player then return end

    local function distanceSqToPlayer(source)
        if not (source and player.getX and player.getY) then
            return 0
        end
        local dx = (tonumber(player:getX()) or 0) - (tonumber(source.x) or 0)
        local dy = (tonumber(player:getY()) or 0) - (tonumber(source.y) or 0)
        return (dx * dx) + (dy * dy)
    end

    local worldCandidates = {}

    for uuid, entry in pairs(NMClientWorldSourceCache.entries) do
        if tostring(entry and entry.kind or "") == "vehicle" then
            entry = NMClientWorldSourceCache.refreshVehicleSource(uuid) or entry
        end
        local source = entry and entry.source or nil
        if source then
            local profile = NMDeviceProfiles.getForFullType(entry.profileType or entry.itemFullType)
            local inRange = true
            local inFloors = true
            if profile then
                local range = NMDeviceProfiles.getWorldTrackingRange(profile)
                if range > 0 and player.getX and player.getY then
                    local dx = (tonumber(player:getX()) or 0) - (tonumber(source.x) or 0)
                    local dy = (tonumber(player:getY()) or 0) - (tonumber(source.y) or 0)
                    inRange = ((dx * dx) + (dy * dy)) <= (range * range)
                end
                local floors = NMDeviceProfiles.getWorldTrackingFloors(profile)
                if floors > 0 and player.getZ then
                    local dz = math.abs((tonumber(player:getZ()) or 0) - (tonumber(source.z) or 0))
                    inFloors = dz <= floors
                end
            end
            if tostring(entry and entry.kind or "") == "vehicle"
                and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")
                and NMCore.shouldLogEvery then
                local now = nowMs()
                local gateKey = "runtimeProbe.vehicleGate." .. tostring(uuid)
                local gateState = tostring(inRange) .. ":" .. tostring(inFloors)
                local gateChanged = entry._lastVehicleGateState ~= gateState
                entry._lastVehicleGateState = gateState
                local shouldLogGate = gateChanged or NMCore.shouldLogEvery(gateKey, now, 15000)
                if shouldLogGate then
                    NMCore.logChannel(
                        "runtimeProbe",
                        "vehicle_tracking_gate",
                        string.format(
                            "uuid=%s inRange=%s inFloors=%s x=%.2f y=%.2f z=%.2f",
                            tostring(uuid),
                            tostring(inRange),
                            tostring(inFloors),
                            tonumber(source.x) or 0,
                            tonumber(source.y) or 0,
                            tonumber(source.z) or 0
                        )
                    )
                end
            end
            if inRange and inFloors then
                worldCandidates[#worldCandidates + 1] = {
                    uuid = tostring(uuid),
                    entry = clonePayload(entry),
                    profile = profile,
                    distSq = distanceSqToPlayer(source)
                }
            end
        end
    end

    local function sortCandidates(candidates)
        table.sort(candidates, function(a, b)
            local da = tonumber(a and a.distSq) or 0
            local db = tonumber(b and b.distSq) or 0
            if da == db then
                return tostring(a and a.uuid or "") < tostring(b and b.uuid or "")
            end
            return da < db
        end)
    end

    sortCandidates(worldCandidates)
    local maxWorld = math.max(0, tonumber(NMRuntimeConfig.getMaxActiveWorldSourcesPerClient and NMRuntimeConfig.getMaxActiveWorldSourcesPerClient() or 10) or 10)

    local keptWorld = 0
    for i = 1, #worldCandidates do
        if keptWorld >= maxWorld then
            break
        end
        out[#out + 1] = worldCandidates[i]
        keptWorld = keptWorld + 1
    end

    local droppedWorld = #worldCandidates - keptWorld
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") and NMCore.shouldLogEvery then
        local now = nowMs()
        if droppedWorld > 0 and NMCore.shouldLogEvery("runtimeProbe.detachedCapDrop", now, 5000) then
            NMCore.logChannel(
                "runtimeProbe",
                "detached_cap_drop",
                string.format("kept=%d dropped=%d cap=%d", keptWorld, droppedWorld, maxWorld)
            )
        end
    end
end

function NMClientWorldSourceCache.forEach(fn)
    if type(fn) ~= "function" then return end
    for uuid, entry in pairs(NMClientWorldSourceCache.entries) do
        fn(uuid, entry)
    end
end

