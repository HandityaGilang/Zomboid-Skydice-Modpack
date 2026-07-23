-- Shared vehicle source position updater.
-- Client attachment decisions are stream-authority driven; SQL snapshot is diagnostics only.
NMClientVehicleSourceUpdater = NMClientVehicleSourceUpdater or {}

local function nowMs()
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

local function toNumber(v)
    local n = tonumber(v)
    if n == nil then
        return nil
    end
    return n
end

local function readWindowsOpen(vehicle, fallback)
    if vehicle and NMVehicleHelpers and NMVehicleHelpers.vehicleWindowsOpen then
        return NMVehicleHelpers.vehicleWindowsOpen(vehicle) == true
    end
    return fallback == true
end

local function getPart(vehicle, partId)
    if not vehicle or not vehicle.getPartById then
        return nil
    end
    return vehicle:getPartById(tostring(partId or "Radio"))
end

local function getRuntimeId(vehicle)
    if not vehicle then
        return ""
    end
    return tostring(NMVehicleHelpers and NMVehicleHelpers.getVehicleIdString and NMVehicleHelpers.getVehicleIdString(vehicle) or "")
end

local function getSqlId(vehicle)
    if not vehicle then
        return ""
    end
    return tostring(NMVehicleHelpers and NMVehicleHelpers.getVehicleSqlIdString and NMVehicleHelpers.getVehicleSqlIdString(vehicle) or "")
end

local function isPlaybackLatchedActive(entry)
    local state = entry and entry.stateSnapshot or nil
    return state and state.isOn == true and state.isPlaying == true
end

local function traceToken(entry)
    local s = entry and entry.stateSnapshot or nil
    return table.concat({
        tostring(entry and entry.uuid or ""),
        tostring(entry and entry.sourceGeneration or 0),
        tostring(s and s.revision or 0),
        tostring(s and s.playbackEpoch or 0)
    }, "|")
end

local function logBindingLifecycle(entry, action, oldRuntimeId, newRuntimeId, sqlId, reason)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleTruthProbe")) then
        return
    end
    local now = nowMs()
    local sig = table.concat({
        tostring(action or "unknown"),
        tostring(oldRuntimeId or ""),
        tostring(newRuntimeId or ""),
        tostring(sqlId or ""),
        tostring(reason or "none")
    }, "|")
    local lastSig = tostring(entry and entry._bindingLifecycleSig or "")
    local lastMs = tonumber(entry and entry._bindingLifecycleMs) or 0
    local changed = sig ~= lastSig
    local heartbeat = (now - lastMs) >= 20000
    if not (changed or heartbeat) then
        return
    end
    entry._bindingLifecycleSig = sig
    entry._bindingLifecycleMs = now
    local state = entry and entry.stateSnapshot or nil
    NMCore.logChannel(
        "vehicleTruthProbe",
        "vehicle_truth_binding_lifecycle",
        string.format(
            "traceToken=%s action=%s uuid=%s playbackEpoch=%s trackIndex=%s oldRuntimeId=%s newRuntimeId=%s sqlId=%s reason=%s",
            tostring(traceToken(entry)),
            tostring(action or "unknown"),
            tostring(entry and entry.uuid or ""),
            tostring(state and state.playbackEpoch or 0),
            tostring(state and state.trackIndex or 0),
            tostring(oldRuntimeId or ""),
            tostring(newRuntimeId or ""),
            tostring(sqlId or ""),
            tostring(reason or "none")
        )
    )
end

local function logAttachDecision(entry, status, reason, runtimeId, degraded)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")) then
        return
    end
    local now = nowMs()
    local sig = table.concat({
        tostring(status or ""),
        tostring(reason or ""),
        tostring(runtimeId or ""),
        tostring(degraded == true)
    }, "|")
    local lastSig = tostring(entry and entry._vehicleAttachDecisionSig or "")
    local lastMs = tonumber(entry and entry._vehicleAttachDecisionMs) or 0
    local changed = sig ~= lastSig
    local heartbeat = (now - lastMs) >= 20000
    local shouldLog = changed or (degraded == true and heartbeat)
    if not shouldLog then
        return
    end
    entry._vehicleAttachDecisionSig = sig
    entry._vehicleAttachDecisionMs = now
    NMCore.logChannel(
        "runtimeProbe",
        "vehicle_attach_decision",
        string.format(
            "uuid=%s status=%s reason=%s runtimeId=%s degraded=%s sourceGen=%s",
            tostring(entry and entry.uuid or ""),
            tostring(status or "unknown"),
            tostring(reason or "none"),
            tostring(runtimeId or ""),
            tostring(degraded == true),
            tostring(entry and entry.sourceGeneration or 0)
        )
    )
end

local function logAttachSwitchApplied(entry, oldRuntimeId, newRuntimeId, reason)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")) then
        return
    end
    NMCore.logChannel(
        "runtimeProbe",
        "vehicle_attach_switch_applied",
        string.format(
            "uuid=%s oldRuntimeId=%s newRuntimeId=%s reason=%s sourceGen=%s",
            tostring(entry and entry.uuid or ""),
            tostring(oldRuntimeId or ""),
            tostring(newRuntimeId or ""),
            tostring(reason or "none"),
            tostring(entry and entry.sourceGeneration or 0)
        )
    )
end

local function preserveLastGoodPosition(source, entry)
    local lx = toNumber(entry and entry.lastGoodX)
    local ly = toNumber(entry and entry.lastGoodY)
    local lz = toNumber(entry and entry.lastGoodZ)
    if lx ~= nil then
        source.x = lx
    end
    if ly ~= nil then
        source.y = ly
    end
    if lz ~= nil then
        source.z = lz
    end
end

local function clearSquareScanBackoff(entry)
    if not entry then
        return
    end
    entry._vehicleSquareScanAttemptCount = 0
    entry._vehicleSquareScanLastAttemptMs = 0
    entry._vehicleSquareScanNextRetryMs = 0
end

local function noteSquareScanAttempt(entry, now)
    if not entry then
        return
    end
    local attemptCount = math.max(0, tonumber(entry._vehicleSquareScanAttemptCount) or 0) + 1
    local delayMs = math.min(5000, 500 * (2 ^ math.max(0, attemptCount - 1)))
    entry._vehicleSquareScanAttemptCount = attemptCount
    entry._vehicleSquareScanLastAttemptMs = tonumber(now) or 0
    entry._vehicleSquareScanNextRetryMs = (tonumber(now) or 0) + delayMs
end

function NMClientVehicleSourceUpdater.update(entry)
    if type(entry) ~= "table" then
        return nil
    end

    local source = entry.source or {}
    local state = entry.stateSnapshot or {}
    local partId = tostring(entry.partId or entry._authorityPartIdHint or "Radio")
    local prevX = tonumber(source.x) or 0
    local prevY = tonumber(source.y) or 0
    local prevZ = tonumber(source.z) or 0
    local now = nowMs()
    local playbackActive = isPlaybackLatchedActive(entry)
    local ttlMs = tonumber(
        NMRuntimeConfig and NMRuntimeConfig.getStickySqlBindingTtlMs and NMRuntimeConfig.getStickySqlBindingTtlMs() or 45000
    ) or 45000

    local attachedRuntimeId = toNumber(entry.attachedRuntimeId or entry._stickyLastResolvedVehicleId or entry._attachedRuntimeId)
    local attachedAtMs = toNumber(entry.attachedAtMs or entry._stickySqlBindingAtMs or entry._stickyLastResolvedAtMs) or 0
    local oldRuntimeId = tostring(attachedRuntimeId or "")

    local authoritativeGen = math.max(
        tonumber(entry.sourceGeneration) or 0,
        tonumber(state and state.sourceGeneration) or 0
    )
    local previousAuthorityGen = tonumber(entry._attachAuthorityGeneration) or 0
    local authoritativeAdvanced = authoritativeGen > previousAuthorityGen
    local authorityHint = tostring(entry._authorityVehicleIdHint or entry.vehicleIdHint or source.vehicleIdHint or "")
    local authoritySqlHint = tostring(entry._authorityVehicleSqlIdHint or entry.vehicleSqlIdHint or source.vehicleSqlIdHint or "")
    local previousAuthorityHint = tostring(entry._attachAuthorityHint or "")
    local authorityHintChanged = authorityHint ~= "" and authorityHint ~= previousAuthorityHint

    local resetSig = table.concat({
        tostring(authoritativeGen),
        tostring(authorityHint),
        tostring(authoritySqlHint),
        tostring(partId),
        tostring(oldRuntimeId)
    }, "|")
    if tostring(entry._vehicleSquareScanResetSig or "") ~= resetSig then
        clearSquareScanBackoff(entry)
        entry._vehicleSquareScanResetSig = resetSig
    end

    if attachedRuntimeId and (not playbackActive) and ttlMs > 0 and attachedAtMs > 0 and (now - attachedAtMs) > ttlMs then
        logBindingLifecycle(entry, "bind_expire", oldRuntimeId, "", tostring(entry.lastResolvedVehicleSqlId or ""), "ttl_expired")
        attachedRuntimeId = nil
        oldRuntimeId = ""
        entry.attachedRuntimeId = nil
        entry.attachedPartId = nil
        entry.attachedAtMs = nil
        clearSquareScanBackoff(entry)
        entry._vehicleSquareScanResetSig = table.concat({
            tostring(authoritativeGen),
            tostring(authorityHint),
            tostring(authoritySqlHint),
            tostring(partId),
            tostring(oldRuntimeId)
        }, "|")
    end

    local nextSquareScanRetryMs = tonumber(entry._vehicleSquareScanNextRetryMs) or 0
    local allowSquareScan = nextSquareScanRetryMs <= 0 or now >= nextSquareScanRetryMs

    local resolveResult = NMClientVehicleAttachmentResolver and NMClientVehicleAttachmentResolver.resolveAttachment
        and NMClientVehicleAttachmentResolver.resolveAttachment(entry, {
            partId = partId,
            attachedRuntimeId = attachedRuntimeId,
            runtimeVehicleIdHint = entry._authorityVehicleIdHint or entry.vehicleIdHint or source.vehicleIdHint or source.vehicleId,
            targetX = source.x,
            targetY = source.y,
            targetZ = source.z,
            radius = 30,
            allowSquareScan = allowSquareScan
        }) or {
            status = "unresolved",
            reason = "attachment_resolver_missing",
            vehicle = nil,
            runtimeId = "",
            part = nil,
            degraded = true,
            candidates = {},
            candidateRuntimeIds = {},
            candidateSqlIds = {},
            squareScanAttempted = false
        }

    local resolvedCandidate = resolveResult.status == "resolved" and resolveResult.vehicle ~= nil and resolveResult.part ~= nil
    local candidateRuntimeId = tostring(resolveResult.runtimeId or "")
    local candidateVehicle = resolvedCandidate and resolveResult.vehicle or nil
    local candidatePart = resolvedCandidate and resolveResult.part or nil
    local reason = tostring(resolveResult.reason or (resolvedCandidate and "resolved" or "unresolved"))

    local resolved = false
    local degraded = false
    local chosenVehicle = nil
    local chosenPart = nil
    local chosenRuntimeId = oldRuntimeId
    local switchApplied = false
    local switchReason = ""

    if resolvedCandidate then
        local candidateChanged = oldRuntimeId ~= "" and candidateRuntimeId ~= "" and candidateRuntimeId ~= oldRuntimeId
        local allowSwitch = false
        if oldRuntimeId == "" or candidateRuntimeId == oldRuntimeId then
            allowSwitch = true
            switchReason = oldRuntimeId == "" and "initial_bind" or "same_runtime"
        elseif authoritativeAdvanced and authorityHintChanged and authorityHint == candidateRuntimeId then
            allowSwitch = true
            switchReason = "authority_generation_hint"
        else
            if tostring(entry.switchCandidateId or "") == candidateRuntimeId then
                entry.switchCandidateCount = (tonumber(entry.switchCandidateCount) or 0) + 1
            else
                entry.switchCandidateId = candidateRuntimeId
                entry.switchCandidateCount = 1
            end
            if tonumber(entry.switchCandidateCount) >= 2 then
                allowSwitch = true
                switchReason = "two_pass_confirmation"
            else
                switchReason = "hysteresis_hold"
            end
        end

        if allowSwitch then
            chosenVehicle = candidateVehicle
            chosenPart = candidatePart
            chosenRuntimeId = candidateRuntimeId
            resolved = true
            degraded = false
            clearSquareScanBackoff(entry)
            if oldRuntimeId ~= "" and chosenRuntimeId ~= "" and oldRuntimeId ~= chosenRuntimeId then
                switchApplied = true
                logAttachSwitchApplied(entry, oldRuntimeId, chosenRuntimeId, switchReason)
                logBindingLifecycle(
                    entry,
                    "bind_switch_hysteresis",
                    oldRuntimeId,
                    chosenRuntimeId,
                    tostring(getSqlId(chosenVehicle)),
                    switchReason
                )
            end
            entry.switchCandidateId = nil
            entry.switchCandidateCount = 0
        else
            resolved = false
            degraded = true
            reason = switchReason
        end
    end

    if not resolved then
        resolved = false
        degraded = true
        preserveLastGoodPosition(source, entry)
        if resolveResult.squareScanAttempted == true then
            noteSquareScanAttempt(entry, now)
        end
        if reason == "" then
            reason = "degraded_no_binding"
        end
    end

    if chosenVehicle and chosenPart then
        source.x = tonumber(chosenVehicle.getX and chosenVehicle:getX()) or prevX
        source.y = tonumber(chosenVehicle.getY and chosenVehicle:getY()) or prevY
        source.z = tonumber(chosenVehicle.getZ and chosenVehicle:getZ()) or prevZ
        source.windowsOpen = readWindowsOpen(chosenVehicle, source.windowsOpen)

        local resolvedRuntimeId = getRuntimeId(chosenVehicle)
        if resolvedRuntimeId ~= "" then
            source.vehicleId = resolvedRuntimeId
            source.vehicleIdHint = resolvedRuntimeId
            entry.vehicleId = resolvedRuntimeId
            entry.vehicleIdHint = resolvedRuntimeId
            chosenRuntimeId = resolvedRuntimeId
        end

        entry.attachedRuntimeId = toNumber(chosenRuntimeId) or entry.attachedRuntimeId
        entry.attachedPartId = tostring(partId)
        entry.attachedAtMs = now
        entry.lastGoodAtMs = now
        entry.lastGoodX = tonumber(source.x) or prevX
        entry.lastGoodY = tonumber(source.y) or prevY
        entry.lastGoodZ = tonumber(source.z) or prevZ
        entry.lastResolvedVehicleSqlId = tostring(getSqlId(chosenVehicle))

        if oldRuntimeId == "" and chosenRuntimeId ~= "" then
            logBindingLifecycle(
                entry,
                "bind_enter",
                "",
                chosenRuntimeId,
                tostring(getSqlId(chosenVehicle)),
                switchReason ~= "" and switchReason or "resolved_attach"
            )
        elseif not switchApplied then
            logBindingLifecycle(
                entry,
                "bind_refresh",
                oldRuntimeId,
                chosenRuntimeId,
                tostring(getSqlId(chosenVehicle)),
                switchReason ~= "" and switchReason or "resolved_attach"
            )
        end
    end

    entry.lastResolveReason = reason
    entry.degraded = degraded == true
    entry._stickyLastResolvedVehicleId = toNumber(entry.attachedRuntimeId)
    entry._stickyLastResolvedVehicleSqlId = tostring(entry.lastResolvedVehicleSqlId or "")
    entry._stickyLastResolvedPartId = tostring(entry.attachedPartId or "")
    entry._stickyLastResolvedAtMs = tonumber(entry.lastGoodAtMs) or 0
    entry._stickySqlBindingAtMs = tonumber(entry.attachedAtMs) or 0
    entry._stickySqlBindingActive = entry.attachedRuntimeId ~= nil
    entry._attachAuthorityGeneration = authoritativeGen
    entry._attachAuthorityHint = authorityHint

    local nx = tonumber(source.x) or prevX
    local ny = tonumber(source.y) or prevY
    local nz = tonumber(source.z) or prevZ
    local movedDist = math.sqrt(((nx - prevX) * (nx - prevX)) + ((ny - prevY) * (ny - prevY)) + ((nz - prevZ) * (nz - prevZ)))

    source._vehicleResolved = resolved == true
    source.vehicleResolved = resolved == true
    entry.source = source

    local attachStatus = resolved and "attached" or "degraded"
    logAttachDecision(entry, attachStatus, reason, tostring(chosenRuntimeId or ""), degraded == true)

    local snapshotMeta = NMClientVehicleSqlSnapshotResolver
        and NMClientVehicleSqlSnapshotResolver.getSnapshotMeta
        and NMClientVehicleSqlSnapshotResolver.getSnapshotMeta() or nil

    return {
        entry = entry,
        source = source,
        result = resolveResult,
        resolved = resolved,
        resolutionMode = resolved and "stream_authority_resolved" or "stream_authority_unresolved",
        prevX = prevX,
        prevY = prevY,
        prevZ = prevZ,
        nx = nx,
        ny = ny,
        nz = nz,
        movedDist = movedDist,
        resolutionReason = reason ~= "" and reason or (resolved and "resolved" or "unresolved"),
        attachStatus = attachStatus,
        degraded = degraded == true,
        attachedRuntimeId = tostring(chosenRuntimeId or ""),
        candidateRuntimeIds = resolveResult.candidateRuntimeIds or {},
        candidateSqlIds = resolveResult.candidateSqlIds or {},
        snapshotMeta = snapshotMeta,
        switchApplied = switchApplied,
        switchReason = switchReason
    }
end

return NMClientVehicleSourceUpdater

