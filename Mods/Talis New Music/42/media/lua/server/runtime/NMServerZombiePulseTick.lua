-- Server authoritative zombie pulse emission from world registry sources.
NMServerZombiePulseTick = NMServerZombiePulseTick or {}

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

local function nearestPlayerDistanceSq(x, y, z, floorsLimit)
    local best = nil
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then return nil end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        local sq = p and p.getSquare and p:getSquare() or nil
        if sq then
            local dz = math.abs((sq:getZ() or 0) - (tonumber(z) or 0))
            if dz <= math.max(0, tonumber(floorsLimit) or 0) then
                local dx = (sq:getX() or 0) - (tonumber(x) or 0)
                local dy = (sq:getY() or 0) - (tonumber(y) or 0)
                local d2 = (dx * dx) + (dy * dy)
                if best == nil or d2 < best then best = d2 end
            end
        end
    end
    return best
end

local function shouldEmitPulse(nowMs, lastMs, intervalMs, lastPos, x, y, z, lastWindowsOpen, windowsOpen)
    local elapsed = nowMs - (tonumber(lastMs) or -1000000000)
    local interval = math.max(100, tonumber(intervalMs) or 1000)
    if elapsed >= interval then
        return true, "stationary_timer"
    end

    if lastWindowsOpen ~= nil and (lastWindowsOpen ~= (windowsOpen == true)) and elapsed >= 500 then
        return true, "window_state_change"
    end

    -- Movement-aware repulse: allow earlier refresh when source shifts by 2+ tiles.
    local minMoveRepulseMs = 2500
    if elapsed < minMoveRepulseMs or type(lastPos) ~= "table" then
        return false, "blocked"
    end
    local dx = (tonumber(x) or 0) - (tonumber(lastPos.x) or 0)
    local dy = (tonumber(y) or 0) - (tonumber(lastPos.y) or 0)
    if ((dx * dx) + (dy * dy)) >= 4.0 then
        return true, "movement"
    end
    return false, "blocked"
end

function NMServerZombiePulseTick.onTick()
    if not NMCore.isMPServerAuthority() or not addSound then
        return
    end

    local nowMs = nowRealMs()
    local gateMultiplier = NMRuntimeConfig and NMRuntimeConfig.getServerZombiePlayerGateMultiplier and NMRuntimeConfig.getServerZombiePlayerGateMultiplier() or 1.5

    for uuid, entry in pairs(NMServerRegistryState.worldRegistry) do
        local state = entry and entry.stateSnapshot or nil
        local profile = entry and entry.profileType and NMDeviceProfiles.getForFullType(entry.profileType) or nil
        if state and profile and NMZombieAttraction.shouldAttract(profile, state, entry.sourceMode) then
            local pulse = NMZombieAttraction.computePulse(profile, state, entry.sourceMode, entry.windowsOpen)
            if pulse then
                local floors = NMDeviceProfiles.getWorldTrackingFloors(profile)
                local nearestD2 = nearestPlayerDistanceSq(entry.x, entry.y, entry.z, floors)
                local gateRange = NMZombieAttraction.computeGateRange(profile, pulse, gateMultiplier)
                if NMZombieAttraction.shouldEmitForNearestPlayer(nearestD2, gateRange) then
                    local lastMs = tonumber(NMServerRegistryState.zombiePulse[uuid]) or -1000000000
                    local lastPos = NMServerRegistryState.zombiePulsePos[uuid]
                    local lastWindowsOpen = NMServerRegistryState.zombiePulseWindowsOpen and NMServerRegistryState.zombiePulseWindowsOpen[uuid]
                    local emit, reason = shouldEmitPulse(
                        nowMs,
                        lastMs,
                        pulse.intervalMs,
                        lastPos,
                        entry.x,
                        entry.y,
                        entry.z,
                        lastWindowsOpen,
                        entry.windowsOpen
                    )
                    if emit then
                        NMServerRegistryState.zombiePulse[uuid] = nowMs
                        NMServerRegistryState.zombiePulsePos[uuid] = {
                            x = tonumber(entry.x) or 0,
                            y = tonumber(entry.y) or 0,
                            z = tonumber(entry.z) or 0
                        }
                        NMServerRegistryState.zombiePulseWindowsOpen = NMServerRegistryState.zombiePulseWindowsOpen or {}
                        NMServerRegistryState.zombiePulseWindowsOpen[uuid] = entry.windowsOpen == true
                        addSound(nil, tonumber(entry.x) or 0, tonumber(entry.y) or 0, tonumber(entry.z) or 0, math.floor(pulse.range), pulse.loudness)
                        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("vehicleDiagnostics") then
                            NMCore.logChannel(
                                "vehicleDiagnostics",
                                "server_zpulse_emit",
                                string.format(
                                    "uuid=%s mode=%s reason=%s x=%.2f y=%.2f z=%.2f range=%d loudness=%d windowsOpen=%s",
                                    tostring(uuid),
                                    tostring(entry.sourceMode or "placed"),
                                    tostring(reason or "unknown"),
                                    tonumber(entry.x) or 0,
                                    tonumber(entry.y) or 0,
                                    tonumber(entry.z) or 0,
                                    math.floor(tonumber(pulse.range) or 0),
                                    math.floor(tonumber(pulse.loudness) or 0),
                                    tostring(entry.windowsOpen == true)
                                )
                            )
                        end
                    end
                end
            end
        end
    end
end

