-- Client-side registry snapshot sync cadence, retries, and ACK handling.
NMClientRegistrySync = NMClientRegistrySync or {}
NMClientRegistrySync.state = NMClientRegistrySync.state or {
    syncPending = false,
    syncAttempts = 0,
    syncNextTick = 0,
    inventorySyncPending = false,
    inventorySyncSent = false,
    initialSyncInFlight = false,
    initialSyncRequestTick = 0,
    resyncInFlight = false,
    resyncRequestTick = 0,
    resyncNextTick = 0,
    resyncLastRequestMs = 0,
    lastX = nil,
    lastY = nil,
    lastZ = nil,
    tick = 0
}

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

local function sendSyncRequest(player)
    if not player or not sendClientCommand then
        return false
    end
    sendClientCommand(player, NMCore.NetModule, "request_registry_sync", {})
    return true
end

function NMClientRegistrySync.requestInitialSync()
    NMClientRegistrySync.state.syncPending = NMCore.isMPClientRuntime()
    NMClientRegistrySync.state.syncAttempts = 0
    NMClientRegistrySync.state.syncNextTick = 0
    NMClientRegistrySync.state.inventorySyncPending = NMCore.isMPClientRuntime()
    NMClientRegistrySync.state.inventorySyncSent = false
    NMClientRegistrySync.state.initialSyncInFlight = false
    NMClientRegistrySync.state.initialSyncRequestTick = 0
end

function NMClientRegistrySync.requestNow(player, reason)
    if not NMCore.isMPClientRuntime() then
        return false
    end
    local s = NMClientRegistrySync.state
    local cooldownMs = math.max(500, tonumber(NMRuntimeConfig.getRegistryResyncCooldownMs and NMRuntimeConfig.getRegistryResyncCooldownMs() or 3000) or 3000)
    local nowMs = nowRealMs()
    if (nowMs - (tonumber(s.resyncLastRequestMs) or 0)) < cooldownMs then
        return false
    end
    if sendSyncRequest(player) then
        s.resyncInFlight = true
        s.resyncRequestTick = tonumber(s.tick) or 0
        s.resyncLastRequestMs = nowMs
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
            local reasonKey = tostring(reason or "unspecified")
            local gateKey = "runtimeProbe.registry_sync_request_now." .. reasonKey
            if not NMCore.shouldLogEvery or NMCore.shouldLogEvery(gateKey, nowMs, 15000) then
                NMRuntimeProbeAdapter.emit("runtimeProbe", "runtimeProbe", "registry_sync_request_now", "reason=" .. reasonKey)
            end
        end
        return true
    end
    return false
end

function NMClientRegistrySync.onServerCommand(command, args)
    if command == "registry_sync_ack" then
        NMClientRegistrySync.state.syncPending = false
        NMClientRegistrySync.state.syncAttempts = 0
        NMClientRegistrySync.state.initialSyncInFlight = false
        NMClientRegistrySync.state.initialSyncRequestTick = 0
        NMClientRegistrySync.state.resyncInFlight = false
        NMClientRegistrySync.state.resyncRequestTick = 0
    elseif command == "registry_update" then
        -- A registry_update indicates the server is actively streaming snapshot/update data.
        NMClientRegistrySync.state.syncPending = false
        NMClientRegistrySync.state.initialSyncInFlight = false
        NMClientRegistrySync.state.initialSyncRequestTick = 0
        NMClientRegistrySync.state.resyncInFlight = false
        NMClientRegistrySync.state.resyncRequestTick = 0
    end
end

function NMClientRegistrySync.onTick(player)
    if not NMCore.isMPClientRuntime() then
        return
    end

    local s = NMClientRegistrySync.state
    s.tick = (tonumber(s.tick) or 0) + 1

    local cooldownMs = math.max(500, tonumber(NMRuntimeConfig.getRegistryResyncCooldownMs and NMRuntimeConfig.getRegistryResyncCooldownMs() or 3000) or 3000)
    local interval = math.max(30, tonumber(NMRuntimeConfig.getRegistryResyncIntervalTicks and NMRuntimeConfig.getRegistryResyncIntervalTicks() or 600) or 600)
    local moveDist = math.max(1, tonumber(NMRuntimeConfig.getRegistryResyncMoveDistance and NMRuntimeConfig.getRegistryResyncMoveDistance() or 48) or 48)
    local moveDist2 = moveDist * moveDist
    local timeoutTicks = math.max(30, tonumber(NMRuntimeConfig.getRegistryRequestTimeoutTicks and NMRuntimeConfig.getRegistryRequestTimeoutTicks() or 180) or 180)

    if s.syncPending then
        if s.initialSyncInFlight == true then
            local reqTick = tonumber(s.initialSyncRequestTick) or 0
            if (s.tick - reqTick) < timeoutTicks then
                return
            end
            s.initialSyncInFlight = false
            s.initialSyncRequestTick = 0
        end
        if s.syncAttempts >= 5 then
            s.syncPending = false
        elseif s.tick >= (tonumber(s.syncNextTick) or 0) then
            local nowMs = nowRealMs()
            if (nowMs - (tonumber(s.resyncLastRequestMs) or 0)) >= cooldownMs then
                if sendSyncRequest(player) then
                    s.syncAttempts = (tonumber(s.syncAttempts) or 0) + 1
                    s.syncNextTick = s.tick + 120
                    s.initialSyncInFlight = true
                    s.initialSyncRequestTick = s.tick
                    s.resyncLastRequestMs = nowMs
                end
            else
                s.syncNextTick = s.tick + 30
            end
        end
    end

    if s.inventorySyncPending and s.inventorySyncSent ~= true then
        local nowMs = nowRealMs()
        if (nowMs - (tonumber(s.resyncLastRequestMs) or 0)) >= cooldownMs then
            if player and sendClientCommand then
                sendClientCommand(player, NMCore.NetModule, "request_inventory_state_sync", {})
                s.inventorySyncSent = true
                s.inventorySyncPending = false
                s.resyncLastRequestMs = nowMs
            end
        end
    end

    if s.resyncInFlight == true then
        local reqTick = tonumber(s.resyncRequestTick) or 0
        if (s.tick - reqTick) >= timeoutTicks then
            s.resyncInFlight = false
            s.resyncRequestTick = 0
            local nextTick = tonumber(s.resyncNextTick) or 0
            if s.tick > nextTick then
                s.resyncNextTick = s.tick
            end
        end
    end

    local sq = player and player.getSquare and player:getSquare() or nil
    if not sq then
        return
    end

    local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
    local moved = false
    if s.lastX == nil or s.lastY == nil or s.lastZ == nil then
        moved = true
    else
        local dz = math.abs((pz or 0) - (s.lastZ or 0))
        local dx = (px or 0) - (s.lastX or 0)
        local dy = (py or 0) - (s.lastY or 0)
        moved = dz > 0 or ((dx * dx) + (dy * dy)) >= moveDist2
    end

    local nowMs = nowRealMs()
    local cooldownReady = (nowMs - (tonumber(s.resyncLastRequestMs) or 0)) >= cooldownMs
    if moved and s.resyncInFlight ~= true and s.tick >= (tonumber(s.resyncNextTick) or 0) and cooldownReady then
        if sendSyncRequest(player) then
            s.resyncInFlight = true
            s.resyncRequestTick = s.tick
            s.resyncNextTick = s.tick + interval
            s.resyncLastRequestMs = nowMs
            s.lastX = px
            s.lastY = py
            s.lastZ = pz
        end
    end
end

