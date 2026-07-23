-- Diagnostics helpers for vehicle emitter jump telemetry.
NMPlaybackRuntimeDiagnostics = NMPlaybackRuntimeDiagnostics or {}

function NMPlaybackRuntimeDiagnostics.ensure(runtimeTable)
    runtimeTable.Diagnostics = runtimeTable.Diagnostics or {
        vehicleJumps = {},
        vehicleRebindHints = 0,
        vehicleJumpWarnings = 0
    }
    runtimeTable._lifecycleProbeSig = runtimeTable._lifecycleProbeSig or {}
    runtimeTable._lifecycleProbeMs = runtimeTable._lifecycleProbeMs or {}
end

function NMPlaybackRuntimeDiagnostics.shouldLogLifecycleProbe(runtimeTable, tag, uuid, signature, minIntervalMs)
    local key = tostring(tag or "") .. ":" .. tostring(uuid or "")
    local nowMs = 0
    if getTimestampMs then
        nowMs = tonumber(getTimestampMs()) or 0
    elseif getTimestamp then
        nowMs = (tonumber(getTimestamp()) or 0) * 1000
    end
    local lastSig = tostring(runtimeTable._lifecycleProbeSig[key] or "")
    local lastMs = tonumber(runtimeTable._lifecycleProbeMs[key]) or 0
    local interval = math.max(500, tonumber(minIntervalMs) or 3000)
    if lastSig == tostring(signature or "") and (nowMs - lastMs) < interval then
        return false
    end
    runtimeTable._lifecycleProbeSig[key] = tostring(signature or "")
    runtimeTable._lifecycleProbeMs[key] = nowMs
    return true
end

function NMPlaybackRuntimeDiagnostics.logEmitterTeardown(runtimeTable, uuid, reason, active)
    if not (active and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")) then
        return
    end
    local detail = string.format(
        "uuid=%s reason=%s mode=%s context=%s token=%s:%s sourceGen=%s worldAlive=%s personalAlive=%s",
        tostring(uuid or ""),
        tostring(reason or "unknown"),
        tostring(active.mode or "single"),
        tostring(active.context or "unknown"),
        tostring(active.epoch or 0),
        tostring(active.trackIndex or 0),
        tostring(active.sourceGeneration or 0),
        tostring(active.world and active.world.alive == true),
        tostring(active.personal and active.personal.alive == true)
    )
    if NMPlaybackRuntimeDiagnostics.shouldLogLifecycleProbe(runtimeTable, "emitter_teardown", uuid, detail, 3000) then
        NMCore.logChannel("runtimeProbe", "emitter_teardown", detail)
    end
end

function NMPlaybackRuntimeDiagnostics.updateVehicleEmitter(runtimeTable, uuid, active, source, context)
    if context ~= "vehicle" or not source then
        return
    end
    if NMRuntimeConfig.getDebugKnob and NMRuntimeConfig.getDebugKnob("vehicleDiagnostics") ~= true then
        return
    end
    local x = tonumber(source.x)
    local y = tonumber(source.y)
    local z = tonumber(source.z)
    if not x or not y or not z then
        return
    end
    local prevX = tonumber(active.lastX)
    local prevY = tonumber(active.lastY)
    local prevZ = tonumber(active.lastZ)
    active.lastX, active.lastY, active.lastZ = x, y, z
    if not prevX or not prevY or not prevZ then
        return
    end

    local dx = x - prevX
    local dy = y - prevY
    local dz = z - prevZ
    local jumpDist = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
    local warnDist = tonumber(NMRuntimeConfig.getVehicleEmitterJumpWarnDistance and NMRuntimeConfig.getVehicleEmitterJumpWarnDistance() or 12) or 12
    local rebindHintDist = tonumber(NMRuntimeConfig.getVehicleEmitterJumpRebindHintDistance and NMRuntimeConfig.getVehicleEmitterJumpRebindHintDistance() or 48) or 48

    if jumpDist >= warnDist then
        runtimeTable.Diagnostics.vehicleJumpWarnings = (tonumber(runtimeTable.Diagnostics.vehicleJumpWarnings) or 0) + 1
        runtimeTable.Diagnostics.vehicleJumps[tostring(uuid)] = {
            distance = jumpDist,
            x = x,
            y = y,
            z = z,
            dx = dx,
            dy = dy,
            dz = dz,
            sourceGeneration = tonumber(active.sourceGeneration) or 0
        }
        if NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("emitter") and NMCore.logChannel then
            NMCore.logChannel("emitter", "vehicle emitter jump", string.format("uuid=%s dist=%.2f", tostring(uuid), jumpDist))
        end
    end
    if jumpDist >= rebindHintDist then
        active.rebindHint = true
        runtimeTable.Diagnostics.vehicleRebindHints = (tonumber(runtimeTable.Diagnostics.vehicleRebindHints) or 0) + 1
    end
end

function NMPlaybackRuntimeDiagnostics.snapshot(runtimeTable)
    local out = {
        vehicleRebindHints = tonumber(runtimeTable.Diagnostics and runtimeTable.Diagnostics.vehicleRebindHints) or 0,
        vehicleJumpWarnings = tonumber(runtimeTable.Diagnostics and runtimeTable.Diagnostics.vehicleJumpWarnings) or 0,
        vehicleJumps = {}
    }
    local rows = runtimeTable.Diagnostics and runtimeTable.Diagnostics.vehicleJumps or {}
    for uuid, row in pairs(rows) do
        out.vehicleJumps[uuid] = row
    end
    return out
end

