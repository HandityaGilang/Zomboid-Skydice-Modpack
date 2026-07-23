-- Playback runtime state and emitter lifecycle for local and detached sources.
NMPlaybackRuntime = NMPlaybackRuntime or {}
NMPlaybackRuntime.Active = NMPlaybackRuntime.Active or {}
NMPlaybackRuntime.TrackEnded = NMPlaybackRuntime.TrackEnded or {}
NMPlaybackRuntime.TrackEndPending = NMPlaybackRuntime.TrackEndPending or {}
NMPlaybackRuntime.TrackEndAwaitingAdvance = NMPlaybackRuntime.TrackEndAwaitingAdvance or {}
NMPlaybackRuntime.MissingSinceTick = NMPlaybackRuntime.MissingSinceTick or {}
NMPlaybackRuntime.MissingSinceMs = NMPlaybackRuntime.MissingSinceMs or {}
NMPlaybackRuntime.PowerTick = NMPlaybackRuntime.PowerTick or {}
NMPlaybackRuntime._corpseAudioSeen = NMPlaybackRuntime._corpseAudioSeen or {}
local runtimeDiag = type(NMPlaybackRuntimeDiagnostics) == "table" and NMPlaybackRuntimeDiagnostics or {
    ensure = function(_) end,
    updateVehicleEmitter = function(_, _, _, _, _) end,
    logEmitterTeardown = function(_, _, _, _) end,
    snapshot = function(_) return {} end
}
runtimeDiag.ensure(NMPlaybackRuntime)

local function shouldLogLifecycleProbe(tag, uuid, signature, minIntervalMs)
    if runtimeDiag and runtimeDiag.shouldLogLifecycleProbe then
        return runtimeDiag.shouldLogLifecycleProbe(NMPlaybackRuntime, tag, uuid, signature, minIntervalMs)
    end
    return true
end

local function stopPlaybackChannel(channel)
    if channel and channel.emitter and channel.soundId then
        if channel.emitter.stopSound then
            channel.emitter:stopSound(channel.soundId)
        elseif channel.emitter.stopAll then
            channel.emitter:stopAll()
        end
    end
end

local function stopActiveInstance(active)
    if not active then
        return
    end
    if active.mode == "dual" then
        stopPlaybackChannel(active.world)
        stopPlaybackChannel(active.personal)
        return
    end
    stopPlaybackChannel(active)
end

local function stopEntry(uuid, reason)
    local key = tostring(uuid or "")
    if key == "" then return end
    local active = NMPlaybackRuntime.Active[key]
    if runtimeDiag and runtimeDiag.logEmitterTeardown then
        runtimeDiag.logEmitterTeardown(NMPlaybackRuntime, key, reason, active)
    end
    stopActiveInstance(active)
    if tostring(reason or "") ~= "track_end" then
        NMPlaybackRuntime.TrackEnded[key] = nil
        NMPlaybackRuntime.TrackEndAwaitingAdvance[key] = nil
    end
    NMPlaybackRuntime.TrackEndPending[key] = nil
    NMPlaybackRuntime.Active[key] = nil
    NMPlaybackRuntime.MissingSinceMs[key] = nil
end

local function isMPVehicleContext(context)
    return tostring(context or "") == "vehicle"
        and NMCore
        and NMCore.isMPClientRuntime
        and NMCore.isMPClientRuntime()
end

local function isMPWorldItemAuthorityContext(context, state)
    if not (NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime()) then
        return false
    end
    if tostring(state and state.playbackMode or "") ~= "world" then
        return false
    end
    local mode = tostring(context or "")
    return mode ~= "inventory" and mode ~= "vehicle"
end

local function getPlaybackEmitter(player, source, useWorldOutput)
    if useWorldOutput and source and source.x and source.y and source.z and getWorld and getWorld() and getWorld().getFreeEmitter then
        local emitter = getWorld():getFreeEmitter(source.x, source.y, source.z)
        if emitter and emitter.setPos then
            emitter:setPos(source.x, source.y, source.z)
        end
        if emitter then
            return emitter, true
        end
    end
    if player and player.getEmitter then
        local emitter = player:getEmitter()
        if emitter then
            return emitter, false
        end
    end
    return nil, false
end

local function getCurrentTrack(state)
    if not state or not state.mediaFullType or not NMMusic or not NMMusic.resolveTracks then
        return nil, nil
    end
    local ok, resolved = pcall(NMMusic.resolveTracks, state.mediaFullType)
    if not ok or type(resolved) ~= "table" or type(resolved.tracks) ~= "table" or #resolved.tracks < 1 then
        return nil, nil
    end
    local idx = tonumber(state.trackIndex) or 1
    if idx < 1 then idx = 1 end
    if idx > #resolved.tracks then idx = #resolved.tracks end
    state.trackIndex = idx
    return resolved.tracks[idx], resolved
end

local function parseModuleName(fullType)
    if not fullType then
        return nil
    end
    local s = tostring(fullType)
    local dotPos = string.find(s, "%.")
    if not dotPos then
        return nil
    end
    return string.sub(s, 1, dotPos - 1)
end

local function buildSoundCandidates(track, state)
    local out = {}
    local seen = {}
    local function push(value)
        if not value then return end
        local s = tostring(value)
        if s == "" or seen[s] then return end
        seen[s] = true
        out[#out + 1] = s
    end

    local raw = track and track.sound and tostring(track.sound) or nil
    local moduleName = parseModuleName(state and state.mediaFullType)
    push(raw)
    if moduleName and raw then
        push(moduleName .. "." .. raw)
        push(moduleName .. "_" .. raw)
    end
    return out
end

local function normalizeId(soundId)
    if soundId == nil then return nil end
    if tonumber(soundId) == 0 then return nil end
    return soundId
end

local function startSoundFromCandidates(emitter, candidates)
    if not emitter or type(candidates) ~= "table" then
        return nil, nil
    end
    local soundIsoObj = nil
    if IsoObject and IsoObject.new then
        soundIsoObj = IsoObject.new()
    end
    for i = 1, #candidates do
        local candidate = candidates[i]
        local soundId = nil
        if emitter.playSoundImpl then
            soundId = normalizeId(emitter:playSoundImpl(candidate, soundIsoObj))
        end
        if emitter.playSound then
            soundId = soundId or normalizeId(emitter:playSound(candidate))
        end
        if soundId then
            return soundId, candidate
        end
    end
    return nil, nil
end

local function joinCandidates(candidates, maxCount)
    if type(candidates) ~= "table" or #candidates < 1 then
        return ""
    end
    local limit = math.max(1, tonumber(maxCount) or 6)
    local out = {}
    local count = math.min(#candidates, limit)
    for i = 1, count do
        out[#out + 1] = tostring(candidates[i])
    end
    if #candidates > count then
        out[#out + 1] = "..."
    end
    return table.concat(out, ",")
end

local function logTransitionProbe(msg, detail)
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("transitionProbe") then
        NMCore.logChannel("transitionProbe", msg, detail)
    end
end

local function logPortableTrackProgression(uuid, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")) then
        return
    end
    NMCore.logChannel(
        "progressionProbe",
        "portable_track_progression",
        string.format("uuid=%s %s", tostring(uuid or ""), tostring(detail or ""))
    )
end

local function isCorpseRecoveredState(state)
    return type(state) == "table" and (state._nmCorpseRecovered == true or tostring(state.lastStopReason or "") == "corpse_reconcile")
end

local function logCorpseAudio(uuid, tag, detail)
    local key = tostring(uuid or "") .. "|" .. tostring(tag or "")
    local sig = tostring(detail or "")
    if NMPlaybackRuntime._corpseAudioSeen[key] == sig then
        return
    end
    NMPlaybackRuntime._corpseAudioSeen[key] = sig
    print("[NewMusic] [CorpseAudio] " .. tostring(tag or "") .. " " .. tostring(detail or ""))
end

local function isVehicleDualEmitterEnabled(context)
    return tostring(context or "") == "vehicle"
        and NMRuntimeConfig.getVehicleDualEmittersEnabled
        and NMRuntimeConfig.getVehicleDualEmittersEnabled() == true
end

local function makeSingleActive(emitter, soundId, selectedSound, state, source, context, trackCount, isWorldEmitter)
    return {
        mode = "single",
        emitter = emitter,
        soundId = soundId,
        sound = selectedSound,
        epoch = tonumber(state.playbackEpoch) or 0,
        isWorldEmitter = isWorldEmitter == true,
        context = context,
        sourceGeneration = tonumber(state.sourceGeneration) or 0,
        trackIndex = tonumber(state.trackIndex) or 1,
        trackCount = tonumber(trackCount) or 1,
        startedAtMs = NMPlaybackRuntimeCommon.getNowRealMs and NMPlaybackRuntimeCommon.getNowRealMs() or 0,
        lastX = source and tonumber(source.x) or nil,
        lastY = source and tonumber(source.y) or nil,
        lastZ = source and tonumber(source.z) or nil
    }
end

local function pickDualMonitorChannel(active)
    if not active or active.mode ~= "dual" then
        return nil, false
    end
    if active.world and active.world.alive then
        return active.world, true
    end
    if active.personal and active.personal.alive then
        return active.personal, false
    end
    return nil, false
end

local function updateDualCompatFields(active)
    if not active or active.mode ~= "dual" then
        return
    end
    local monitor, world = pickDualMonitorChannel(active)
    if monitor then
        active.emitter = monitor.emitter
        active.soundId = monitor.soundId
        active.sound = monitor.sound
        active.isWorldEmitter = world == true
    else
        active.emitter = nil
        active.soundId = nil
        active.sound = nil
        active.isWorldEmitter = false
    end
end

local function startPlaybackChannel(player, source, useWorldOutput, candidates, channelName)
    local emitter, isWorldEmitter = getPlaybackEmitter(player, source, useWorldOutput)
    if not emitter then
        return nil, "emitter_missing"
    end
    local soundId, selectedSound = startSoundFromCandidates(emitter, candidates)
    if soundId == nil or tonumber(soundId) == 0 then
        return nil, "sound_start_failed"
    end
    if emitter.set3D then
        emitter:set3D(soundId, isWorldEmitter)
    end
    return {
        emitter = emitter,
        soundId = soundId,
        sound = selectedSound,
        isWorldEmitter = isWorldEmitter == true,
        channelName = channelName,
        alive = true
    }, nil
end

local function setChannelVolume(channel, value)
    if channel and channel.alive and channel.emitter and channel.soundId and channel.emitter.setVolume then
        channel.emitter:setVolume(channel.soundId, value)
    end
end

local function setChannelPos(channel, source)
    if channel and channel.alive and channel.emitter and channel.emitter.setPos and source and source.x and source.y and source.z then
        local oldX = tonumber(channel.lastX)
        local oldY = tonumber(channel.lastY)
        local oldZ = tonumber(channel.lastZ)
        channel.emitter:setPos(source.x, source.y, source.z)
        local newX = tonumber(source.x)
        local newY = tonumber(source.y)
        local newZ = tonumber(source.z)
        channel.lastX = newX
        channel.lastY = newY
        channel.lastZ = newZ
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
            local dx = (newX or 0) - (oldX or (newX or 0))
            local dy = (newY or 0) - (oldY or (newY or 0))
            local dz = (newZ or 0) - (oldZ or (newZ or 0))
            local dist = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
            local nowMs = NMPlaybackRuntimeCommon.getNowRealMs and NMPlaybackRuntimeCommon.getNowRealMs() or 0
            local lastMs = tonumber(channel._lastPosLogMs) or 0
            if dist >= 1.0 or (nowMs - lastMs) >= 60000 then
                channel._lastPosLogMs = nowMs
                NMCore.logChannel(
                    "runtimeProbe",
                    "emitter_pos_update",
                    string.format(
                        "channel=%s old=%.2f,%.2f,%.2f new=%.2f,%.2f,%.2f dist=%.2f",
                        tostring(channel.channelName or "single"),
                        tonumber(oldX) or tonumber(newX) or 0,
                        tonumber(oldY) or tonumber(newY) or 0,
                        tonumber(oldZ) or tonumber(newZ) or 0,
                        tonumber(newX) or 0,
                        tonumber(newY) or 0,
                        tonumber(newZ) or 0,
                        dist
                    )
                )
            end
        end
    end
end

local function logVehicleRebindTrace(tag, uuid, detail)
    if NMCore and NMCore.logVehicleRebindTrace then
        NMCore.logVehicleRebindTrace(tag, uuid, detail)
    end
end

local function isChannelPlaying(channel)
    if not channel or not channel.emitter or not channel.soundId or not channel.emitter.isPlaying then
        return false
    end
    local ok, playing = pcall(function()
        return channel.emitter:isPlaying(channel.soundId)
    end)
    if not ok then
        return false
    end
    return playing ~= false
end

local function tryRetargetEmitterClass(active, useWorldOutput, source, uuid)
    if not (active and active.emitter and active.soundId) then
        return false
    end
    if not active.emitter.set3D then
        return false
    end
    local targetWorld = useWorldOutput == true
    local ok = pcall(function()
        active.emitter:set3D(active.soundId, targetWorld)
    end)
    if not ok then
        return false
    end
    active.isWorldEmitter = targetWorld
    if targetWorld and source and source.x and source.y and source.z and active.emitter.setPos then
        active.emitter:setPos(source.x, source.y, source.z)
    end
    logTransitionProbe(
        "emitter_class_flip_in_place",
        string.format("uuid=%s world=%s", tostring(uuid), tostring(targetWorld))
    )
    return true
end

local function isLocalPersonalListenerAllowed(player, state, source)
    if not (NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime()) then
        return true
    end
    if not player then
        return true
    end
    local owner = tostring(
        (source and (source.ownerId or source.ownerOnlineId or source.ownerUsername))
        or (state and state.sourceOwner)
        or ""
    )
    local context = tostring(source and (source.context or source.mode) or "inventory")
    if owner == "" then
        if context ~= "inventory" and context ~= "vehicle" then
            return false
        end
        return true
    end
    local localOnlineId = player.getOnlineID and tostring(player:getOnlineID() or "") or ""
    local localUsername = player.getUsername and tostring(player:getUsername() or "") or ""
    if owner == localOnlineId or owner == localUsername then
        return true
    end
    if localUsername ~= "" and string.lower(owner) == string.lower(localUsername) then
        return true
    end
    return false
end

function NMPlaybackRuntime.syncDevice(player, profile, state, source, tickCount)
    if not profile or not state or not state.deviceUUID then
        return
    end
    local uuid = tostring(state.deviceUUID)
    if NMDeviceState and NMDeviceState.isZombieDormant and NMDeviceState.isZombieDormant(state) then
        stopEntry(uuid, "zombie_dormant")
        return
    end
    if NMAuthorityContract and NMAuthorityContract.canMutateDurableStateAtRuntime and (not NMAuthorityContract.canMutateDurableStateAtRuntime()) then
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") and NMCore.shouldLogEvery then
            local skipKey = "runtimeProbe.clientBatterySkip." .. tostring(uuid)
            if NMCore.shouldLogEvery(skipKey, tonumber(tickCount) or 0, 600) then
                NMCore.logChannel(
                    "runtimeProbe",
                    "client_battery_drain_skipped_authority",
                    string.format("uuid=%s playbackMode=%s", tostring(uuid), tostring(state.playbackMode or "nil"))
                )
            end
        end
    else
        NMPlaybackRuntimeCommon.applyPowerDrain(NMPlaybackRuntime.PowerTick, profile, state, tickCount)
    end

    local context = (source and source.context) or ((source and source.mode == "world") and "placed" or "inventory")
    local outputMode = NMDeviceProfiles.resolveOutputMode(profile, state, context, false)
    if context == "vehicle" and outputMode ~= "none" then
        -- Vehicle routing follows authoritative runtime state and never waits on identity resolver hints.
        outputMode = "world"
    end

    local configuredVolume = NMCore.clamp(tonumber(state.volume) or 0, 0, 1)
    local effectiveVolume = configuredVolume
    if outputMode == "silent" or state.isMuted == true then
        effectiveVolume = 0
    end
    local personalOwnerAllowed = true
    if outputMode == "personal" then
        personalOwnerAllowed = isLocalPersonalListenerAllowed(player, state, source)
        if not personalOwnerAllowed then
            effectiveVolume = 0
        end
    end
    local portablePolicy = NMPlaybackPortableRouting
        and NMPlaybackPortableRouting.resolvePolicy
        and NMPlaybackPortableRouting.resolvePolicy(profile, state, context, outputMode, configuredVolume, effectiveVolume, personalOwnerAllowed)
        or nil
    local routedOutputMode = portablePolicy and portablePolicy.audibility or outputMode
    local useWorldOutput = portablePolicy and portablePolicy.singleWorldOutput
        or ((outputMode == "world") or (outputMode == "silent" and context ~= "inventory"))
    local shouldPlay = portablePolicy and portablePolicy.shouldPlay
        or (state.isPlaying == true and outputMode ~= "none" and state.mediaFullType ~= nil and personalOwnerAllowed)
    local useDualVehicle = isVehicleDualEmitterEnabled(context)
    local useDualRender = useDualVehicle or (portablePolicy and portablePolicy.dualRender == true)
    local vehicleResolved = not (context == "vehicle" and source and source._vehicleResolved == false)

    if NMCore and NMCore.logChannel and NMCore.shouldLogEvery and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        local routeKey = "runtimeProbe.route." .. uuid
        if NMCore.shouldLogEvery(routeKey, tonumber(tickCount) or 0, 60) then
            NMCore.logChannel(
                "runtimeProbe",
                "route",
                string.format(
                    "uuid=%s context=%s output=%s worldOut=%s shouldPlay=%s isOn=%s isPlaying=%s muted=%s volume=%.2f effective=%.2f media=%s",
                    uuid,
                    tostring(context),
                    tostring(routedOutputMode),
                    tostring(useWorldOutput == true),
                    tostring(shouldPlay == true),
                    tostring(state.isOn == true),
                    tostring(state.isPlaying == true),
                    tostring(state.isMuted == true),
                    configuredVolume,
                    effectiveVolume,
                    tostring(state.mediaFullType or "nil")
                )
            )
        end
    end

    if routedOutputMode == "personal" and not personalOwnerAllowed then
        if isCorpseRecoveredState(state) then
            logCorpseAudio(
                uuid,
                "runtime_personal_blocked",
                string.format(
                    "uuid=%s context=%s output=%s owner=%s localOnlineId=%s localUsername=%s",
                    tostring(uuid),
                    tostring(context),
                    tostring(routedOutputMode),
                    tostring((source and (source.ownerId or source.ownerOnlineId or source.ownerUsername)) or (state and state.sourceOwner) or ""),
                    tostring(player and player.getOnlineID and player:getOnlineID() or ""),
                    tostring(player and player.getUsername and player:getUsername() or "")
                )
            )
        end
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") and NMCore.shouldLogEvery then
            local key = "runtimeProbe.personal_world_block." .. tostring(uuid)
            if NMCore.shouldLogEvery(key, tonumber(tickCount) or 0, 300) then
                NMCore.logChannel(
                    "runtimeProbe",
                    "personal_world_blocked",
                    string.format(
                        "uuid=%s context=%s owner=%s localOnlineId=%s localUsername=%s",
                        tostring(uuid),
                        tostring(context),
                        tostring((source and (source.ownerId or source.ownerOnlineId or source.ownerUsername)) or (state and state.sourceOwner) or ""),
                        tostring(player and player.getOnlineID and player:getOnlineID() or ""),
                        tostring(player and player.getUsername and player:getUsername() or "")
                    )
                )
            end
        end
    end

    local active = NMPlaybackRuntime.Active[uuid]
    if not shouldPlay then
        if isCorpseRecoveredState(state) then
            logCorpseAudio(
                uuid,
                "runtime_route_blocked",
                string.format(
                    "uuid=%s context=%s output=%s routed=%s shouldPlay=%s isOn=%s isPlaying=%s muted=%s media=%s headphones=%s batteryPresent=%s batteryCharge=%.3f",
                    tostring(uuid),
                    tostring(context),
                    tostring(outputMode),
                    tostring(routedOutputMode),
                    tostring(shouldPlay == true),
                    tostring(state and state.isOn == true),
                    tostring(state and state.isPlaying == true),
                    tostring(state and state.isMuted == true),
                    tostring(state and state.mediaFullType or "nil"),
                    tostring(state and state.headphoneItemFullType or "nil"),
                    tostring(state and state.batteryPresent == true),
                    tonumber(state and state.batteryCharge) or 0.0
                )
            )
        end
        if state.isPlaying == true and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
            NMCore.logChannel(
                "runtimeProbe",
                "route_blocked",
                string.format(
                    "uuid=%s context=%s output=%s isMuted=%s media=%s",
                    uuid,
                    tostring(context),
                    tostring(routedOutputMode),
                    tostring(state.isMuted == true),
                    tostring(state.mediaFullType or "nil")
                )
            )
        end
        stopEntry(uuid, "not_playing")
        return
    end

    local mpVehicleAuthority = isMPVehicleContext(context)
    local mpWorldItemAuthority = isMPWorldItemAuthorityContext(context, state)
    local trackEndAwait = NMPlaybackRuntime.TrackEndAwaitingAdvance[uuid]
    if trackEndAwait and mpVehicleAuthority then
        -- Keep await-map opportunistic in MP vehicle mode; client emits deduped hint and server remains authoritative.
        NMPlaybackRuntime.TrackEndAwaitingAdvance[uuid] = nil
    elseif trackEndAwait and mpWorldItemAuthority then
        local awaitingEpoch = tonumber(trackEndAwait.playbackEpoch) or -1
        local awaitingTrack = tonumber(trackEndAwait.trackIndex) or -1
        local stateEpoch = tonumber(state and state.playbackEpoch) or -1
        local stateTrack = tonumber(state and state.trackIndex) or -1
        if awaitingEpoch ~= stateEpoch or awaitingTrack ~= stateTrack then
            NMPlaybackRuntime.TrackEndAwaitingAdvance[uuid] = nil
        else
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe") and NMCore.shouldLogEvery then
                local holdKey = "progressionProbe.world.await_hold." .. tostring(uuid) .. ":" .. tostring(stateEpoch) .. ":" .. tostring(stateTrack)
                if NMCore.shouldLogEvery(holdKey, tonumber(tickCount) or 0, 240) then
                    NMCore.logChannel(
                        "progressionProbe",
                        "progression_world_replay_hold",
                        string.format("uuid=%s epoch=%s track=%s context=%s", tostring(uuid), tostring(stateEpoch), tostring(stateTrack), tostring(context))
                    )
                end
            end
            return
        end
    end

    local restart = not active or (tonumber(active and active.epoch) or -1) ~= (tonumber(state.playbackEpoch) or -1)
    if active and active.mode == "dual" and (not useDualRender) then
        restart = true
    end
    if active and active.mode ~= "dual" and useDualRender then
        restart = true
    end
    local classFlipNeeded = false
    if active and active.mode ~= "dual" and (not useDualRender) then
        classFlipNeeded = ((active.isWorldEmitter == true) ~= useWorldOutput)
        if classFlipNeeded then
            if tryRetargetEmitterClass(active, useWorldOutput, source, uuid) then
                classFlipNeeded = false
            else
                local reason = (active and active.emitter and active.emitter.set3D) and "retarget_failed" or "set3d_missing"
                logTransitionProbe(
                    "emitter_class_flip_restart",
                    string.format("uuid=%s reason=%s targetWorld=%s", tostring(uuid), tostring(reason), tostring(useWorldOutput == true))
                )
            end
        end
    end
    if classFlipNeeded then
        restart = true
    end

    if active and active.mode == "dual" then
        updateDualCompatFields(active)
    end

    local trackEndActive = active
    local trackEndMonitorChannel = "single"
    if active and active.mode == "dual" then
        local monitor = nil
        if outputMode == "personal" then
            monitor = active.personal
            trackEndMonitorChannel = "personal"
        else
            monitor = active.world
            trackEndMonitorChannel = "world"
        end
        trackEndActive = monitor and {
            emitter = monitor.emitter,
            soundId = monitor.soundId
        } or nil
    end

    if active
        and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")
        and NMDeviceProfiles and NMDeviceProfiles.isPortableTrackedContext
        and NMDeviceProfiles.isPortableTrackedContext(profile, context) == true
        and NMCore.shouldLogEvery then
        local stateEpoch = tonumber(state and state.playbackEpoch) or -1
        local stateTrack = tonumber(state and state.trackIndex) or -1
        local pending = NMPlaybackRuntime.TrackEndPending[uuid]
        local ended = NMPlaybackRuntime.TrackEnded[uuid]
        local awaiting = NMPlaybackRuntime.TrackEndAwaitingAdvance[uuid]
        local logKey = "progressionProbe.portableMonitor." .. tostring(uuid) .. ":" .. tostring(stateEpoch) .. ":" .. tostring(stateTrack)
        if NMCore.shouldLogEvery(logKey, tonumber(tickCount) or 0, 120) then
            logPortableTrackProgression(
                uuid,
                string.format(
                    "stage=monitor context=%s output=%s activeMode=%s monitor=%s shouldPlay=%s pending=%s awaiting=%s ended=%s media=%s",
                    tostring(context),
                    tostring(routedOutputMode),
                    tostring(active and active.mode or "none"),
                    tostring(trackEndMonitorChannel),
                    tostring(shouldPlay == true),
                    tostring(pending ~= nil),
                    tostring(awaiting ~= nil),
                    tostring(ended ~= nil),
                    tostring(state and state.mediaFullType or "nil")
                )
            )
        end
    end

    if active and not restart and trackEndActive then
        if NMPlaybackRuntimeCommon.updateTrackEndState(
            NMPlaybackRuntime.TrackEndPending,
            NMPlaybackRuntime.TrackEnded,
            NMPlaybackRuntime.TrackEndAwaitingAdvance,
            uuid,
            state,
            trackEndActive,
            profile) then
            logPortableTrackProgression(
                uuid,
                string.format(
                    "stage=token_set context=%s output=%s activeMode=%s monitor=%s epoch=%s track=%s",
                    tostring(context),
                    tostring(routedOutputMode),
                    tostring(active and active.mode or "none"),
                    tostring(trackEndMonitorChannel),
                    tostring(state and state.playbackEpoch or -1),
                    tostring(state and state.trackIndex or -1)
                )
            )
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe") then
                NMCore.logChannel(
                    "progressionProbe",
                    "client_track_end_token_set",
                    string.format(
                        "uuid=%s context=%s token=%s:%s",
                        tostring(uuid),
                        tostring(context),
                        tostring(state and state.playbackEpoch or -1),
                        tostring(state and state.trackIndex or -1)
                    )
                )
            end
            stopEntry(uuid, "track_end")
            return
        elseif NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("progressionProbe")
            and NMDeviceProfiles and NMDeviceProfiles.isPortableTrackedContext
            and NMDeviceProfiles.isPortableTrackedContext(profile, context) == true
            and NMCore.shouldLogEvery then
            local pending = NMPlaybackRuntime.TrackEndPending[uuid]
            local awaiting = NMPlaybackRuntime.TrackEndAwaitingAdvance[uuid]
            local stateEpoch = tonumber(state and state.playbackEpoch) or -1
            local stateTrack = tonumber(state and state.trackIndex) or -1
            local logKey = "progressionProbe.portableMonitorProgress." .. tostring(uuid) .. ":" .. tostring(stateEpoch) .. ":" .. tostring(stateTrack)
            if NMCore.shouldLogEvery(logKey, tonumber(tickCount) or 0, 180) then
                logPortableTrackProgression(
                    uuid,
                    string.format(
                        "stage=monitor_wait context=%s output=%s activeMode=%s monitor=%s pending=%s falseCount=%s awaiting=%s",
                        tostring(context),
                        tostring(routedOutputMode),
                        tostring(active and active.mode or "none"),
                        tostring(trackEndMonitorChannel),
                        tostring(pending ~= nil),
                        tostring(pending and pending.falseCount or 0),
                        tostring(awaiting ~= nil)
                    )
                )
            end
        end
    end

    if restart then
        stopEntry(uuid, "restart")

        local track, resolved = getCurrentTrack(state)
        if not track then
            state.isPlaying = false
            state.desiredIsPlaying = false
            state.lastStopReason = "no_track"
            if isCorpseRecoveredState(state) then
                logCorpseAudio(
                    uuid,
                    "runtime_no_track",
                    string.format(
                        "uuid=%s media=%s trackIndex=%d",
                        tostring(uuid),
                        tostring(state.mediaFullType or "nil"),
                        tonumber(state.trackIndex) or 1
                    )
                )
            end
            if NMCore and NMCore.logChannel then
                NMCore.logChannel(
                    "emitter",
                    "start_rejected",
                    string.format(
                        "uuid=%s reason=no_track media=%s trackIndex=%d",
                        uuid,
                        tostring(state.mediaFullType or "nil"),
                        tonumber(state.trackIndex) or 1
                    )
                )
            end
            return
        end

        local candidates = buildSoundCandidates(track, state)
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("emitter") then
            NMCore.logChannel(
                "emitter",
                "start_attempt",
                string.format(
                    "uuid=%s media=%s track=%s candidates=%s context=%s output=%s dual=%s",
                    tostring(uuid),
                    tostring(state.mediaFullType or "nil"),
                    tostring(track and track.sound or "nil"),
                    joinCandidates(candidates, 8),
                    tostring(context),
                    tostring(routedOutputMode),
                    tostring(useDualRender == true)
                )
            )
        end

        if useDualRender then
            local worldChan, worldErr = startPlaybackChannel(player, source, true, candidates, "world")
            local personalChan, personalErr = startPlaybackChannel(player, source, false, candidates, "personal")
            local worldAlive = worldChan ~= nil
            local personalAlive = personalChan ~= nil

            if not worldAlive and not personalAlive then
                state.isPlaying = false
                state.desiredIsPlaying = false
                state.lastStopReason = "sound_start_failed"
                if isCorpseRecoveredState(state) then
                    logCorpseAudio(
                        uuid,
                        "runtime_dual_start_failed",
                        string.format(
                            "uuid=%s media=%s worldErr=%s personalErr=%s",
                            tostring(uuid),
                            tostring(state.mediaFullType or "nil"),
                            tostring(worldErr or "nil"),
                            tostring(personalErr or "nil")
                        )
                    )
                end
                if NMCore and NMCore.logChannel then
                    NMCore.logChannel(
                        "emitter",
                        "start_rejected",
                        string.format(
                            "uuid=%s reason=dual_start_failed media=%s worldErr=%s personalErr=%s",
                            uuid,
                            tostring(state.mediaFullType or "nil"),
                            tostring(worldErr or "nil"),
                            tostring(personalErr or "nil")
                        )
                    )
                end
                return
            end

            active = {
                mode = "dual",
                world = worldChan or { alive = false },
                personal = personalChan or { alive = false },
                epoch = tonumber(state.playbackEpoch) or 0,
                context = context,
                sourceGeneration = tonumber(state.sourceGeneration) or 0,
                trackIndex = tonumber(state.trackIndex) or 1,
                trackCount = (resolved and resolved.tracks and #resolved.tracks) or 1,
                startedAtMs = NMPlaybackRuntimeCommon.getNowRealMs and NMPlaybackRuntimeCommon.getNowRealMs() or 0,
                lastX = source and tonumber(source.x) or nil,
                lastY = source and tonumber(source.y) or nil,
                lastZ = source and tonumber(source.z) or nil,
                lastGainRoute = nil
            }
            updateDualCompatFields(active)
            NMPlaybackRuntime.Active[uuid] = active
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                local detail = string.format(
                    "uuid=%s mode=dual context=%s output=%s token=%s:%s sourceGen=%s worldAlive=%s personalAlive=%s worldSound=%s personalSound=%s",
                    tostring(uuid),
                    tostring(context),
                    tostring(routedOutputMode),
                    tostring(active.epoch or 0),
                    tostring(active.trackIndex or 0),
                    tostring(active.sourceGeneration or 0),
                    tostring(worldAlive),
                    tostring(personalAlive),
                    tostring(worldChan and worldChan.sound or "nil"),
                    tostring(personalChan and personalChan.sound or "nil")
                )
                if shouldLogLifecycleProbe("emitter_create", uuid, detail, 3000) then
                    NMCore.logChannel("runtimeProbe", "emitter_create", detail)
                end
            end

            if NMCore and NMCore.logChannel then
                NMCore.logChannel(
                    "emitter",
                    "dual_start_result",
                    string.format(
                        "uuid=%s world=%s personal=%s worldSound=%s personalSound=%s trackIndex=%d trackCount=%d",
                        tostring(uuid),
                        tostring(worldAlive),
                        tostring(personalAlive),
                        tostring(worldChan and worldChan.sound or "nil"),
                        tostring(personalChan and personalChan.sound or "nil"),
                        tonumber(state.trackIndex) or 1,
                        (resolved and resolved.tracks and #resolved.tracks) or 1
                    )
                )
            end
            if (not worldAlive) or (not personalAlive) then
                logTransitionProbe(
                    "dual_failover",
                    string.format(
                        "uuid=%s worldAlive=%s personalAlive=%s worldErr=%s personalErr=%s",
                        tostring(uuid),
                        tostring(worldAlive),
                        tostring(personalAlive),
                        tostring(worldErr or "nil"),
                        tostring(personalErr or "nil")
                    )
                )
            end
        else
            local emitter, isWorldEmitter = getPlaybackEmitter(player, source, useWorldOutput)
            if not emitter then
                state.isPlaying = false
                state.desiredIsPlaying = false
                state.lastStopReason = "emitter_missing"
                if isCorpseRecoveredState(state) then
                    logCorpseAudio(
                        uuid,
                        "runtime_emitter_missing",
                        string.format(
                            "uuid=%s context=%s output=%s world=%s",
                            tostring(uuid),
                            tostring(context),
                            tostring(routedOutputMode),
                            tostring(useWorldOutput == true)
                        )
                    )
                end
                if NMCore and NMCore.logChannel then
                    NMCore.logChannel("emitter", "start_rejected", "uuid=" .. uuid .. " reason=emitter_missing")
                end
                return
            end

            local soundId, selectedSound = startSoundFromCandidates(emitter, candidates)
            if soundId == nil or tonumber(soundId) == 0 then
                state.isPlaying = false
                state.desiredIsPlaying = false
                state.lastStopReason = "sound_start_failed"
                if isCorpseRecoveredState(state) then
                    logCorpseAudio(
                        uuid,
                        "runtime_sound_start_failed",
                        string.format(
                            "uuid=%s media=%s track=%s candidates=%s context=%s output=%s",
                            tostring(uuid),
                            tostring(state.mediaFullType or "nil"),
                            tostring(track and track.sound or "nil"),
                            joinCandidates(candidates, 8),
                            tostring(context),
                            tostring(routedOutputMode)
                        )
                    )
                end
                if NMCore and NMCore.logChannel then
                    NMCore.logChannel(
                        "emitter",
                        "start_rejected",
                        string.format(
                            "uuid=%s reason=sound_start_failed media=%s track=%s candidates=%s",
                            uuid,
                            tostring(state.mediaFullType or "nil"),
                            tostring(track and track.sound or "nil"),
                            joinCandidates(candidates, 8)
                        )
                    )
                end
                return
            end
            if NMCore and NMCore.logChannel then
                NMCore.logChannel(
                    "emitter",
                    "start_ok",
                    string.format(
                        "uuid=%s media=%s selected=%s soundId=%s trackIndex=%d trackCount=%d world=%s context=%s output=%s",
                        uuid,
                        tostring(state.mediaFullType or "nil"),
                        tostring(selectedSound or "nil"),
                        tostring(soundId),
                        tonumber(state.trackIndex) or 1,
                        (resolved and resolved.tracks and #resolved.tracks) or 1,
                        tostring(isWorldEmitter == true),
                        tostring(context),
                        tostring(routedOutputMode)
                    )
                )
            end
            if isCorpseRecoveredState(state) then
                logCorpseAudio(
                    uuid,
                    "runtime_start_ok",
                    string.format(
                        "uuid=%s media=%s selected=%s soundId=%s context=%s output=%s world=%s",
                        tostring(uuid),
                        tostring(state.mediaFullType or "nil"),
                        tostring(selectedSound or "nil"),
                        tostring(soundId),
                        tostring(context),
                        tostring(routedOutputMode),
                        tostring(isWorldEmitter == true)
                    )
                )
            end
            if emitter.set3D then
                emitter:set3D(soundId, isWorldEmitter)
            end
            active = makeSingleActive(
                emitter,
                soundId,
                selectedSound,
                state,
                source,
                context,
                (resolved and resolved.tracks and #resolved.tracks) or 1,
                isWorldEmitter == true
            )
            NMPlaybackRuntime.Active[uuid] = active
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                local detail = string.format(
                    "uuid=%s mode=single context=%s output=%s token=%s:%s sourceGen=%s world=%s sound=%s",
                    tostring(uuid),
                    tostring(context),
                    tostring(outputMode),
                    tostring(active.epoch or 0),
                    tostring(active.trackIndex or 0),
                    tostring(active.sourceGeneration or 0),
                    tostring(active.isWorldEmitter == true),
                    tostring(active.sound or "nil")
                )
                if shouldLogLifecycleProbe("emitter_create", uuid, detail, 3000) then
                    NMCore.logChannel("runtimeProbe", "emitter_create", detail)
                end
            end
        end
    end

    if not active then
        return
    end
    active.context = context

    if active.mode == "dual" then
        setChannelPos(active.world, source)
        local routedWorld = 0
        local routedPersonal = 0
        if portablePolicy then
            routedWorld = portablePolicy.routeWorld
            routedPersonal = portablePolicy.routePersonal
        elseif outputMode == "world" then
            routedWorld = effectiveVolume
        elseif outputMode == "personal" then
            routedPersonal = effectiveVolume
        end
        local routeWorld = NMPlaybackAudibility.computeChannelVolume(profile, state, player, source, "world", routedWorld)
        local routePersonal = NMPlaybackAudibility.computeChannelVolume(profile, state, player, source, "personal", routedPersonal)
        setChannelVolume(active.world, routeWorld)
        setChannelVolume(active.personal, routePersonal)
        local nowMs = NMPlaybackRuntimeCommon.getNowRealMs and NMPlaybackRuntimeCommon.getNowRealMs() or 0
        local worldPlaying = isChannelPlaying(active.world)
        local personalPlaying = isChannelPlaying(active.personal)
        active.worldPlaying = worldPlaying
        active.personalPlaying = personalPlaying
        if worldPlaying then
            active.lastHealthyWorldMs = nowMs
        end
        updateDualCompatFields(active)

        local quant = function(v)
            return math.floor(((tonumber(v) or 0) * 20) + 0.5) / 20
        end
        local routeSig = string.format("%s|w=%.2f|p=%.2f", tostring(routedOutputMode), quant(routeWorld), quant(routePersonal))
        local routeChanged = tostring(active.lastGainRoute or "") ~= routeSig
        local nowMsForDualGain = NMPlaybackRuntimeCommon.getNowRealMs and NMPlaybackRuntimeCommon.getNowRealMs() or 0
        local lastDualGainLogMs = tonumber(active.lastDualGainLogMs) or 0
        local dualGainMinLogMs = math.max(150, tonumber(NMRuntimeConfig.get("dualGainMinLogMs", 250)) or 250)
        local canLogDualGainNow = (nowMsForDualGain - lastDualGainLogMs) >= dualGainMinLogMs
        if (routeChanged and canLogDualGainNow)
            or (NMCore and NMCore.shouldLogEvery and NMCore.shouldLogEvery("transitionProbe.dualGain." .. uuid, tonumber(tickCount) or 0, 600)) then
            logTransitionProbe(
                "dual_gain_route",
                string.format(
                    "uuid=%s output=%s world=%.3f personal=%.3f worldAlive=%s personalAlive=%s",
                    tostring(uuid),
                    tostring(routedOutputMode),
                    routeWorld,
                    routePersonal,
                    tostring(active.world and active.world.alive == true),
                    tostring(active.personal and active.personal.alive == true)
                )
            )
            active.lastDualGainLogMs = nowMsForDualGain
        end
        active.lastGainRoute = routeSig
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")
            and NMCore.shouldLogEvery and NMCore.shouldLogEvery("runtimeProbe.vehicleChannelHealth." .. uuid, tonumber(tickCount) or 0, 300) then
            NMCore.logChannel(
                "runtimeProbe",
                "dual_channel_health",
                string.format(
                    "uuid=%s output=%s resolved=%s worldPlaying=%s personalPlaying=%s routeWorld=%.3f routePersonal=%.3f",
                    tostring(uuid),
                    tostring(routedOutputMode),
                    tostring(vehicleResolved),
                    tostring(worldPlaying),
                    tostring(personalPlaying),
                    routeWorld,
                    routePersonal
                )
            )
        end
        if context == "vehicle" and routedOutputMode == "world" and routeWorld <= 0.001
            and NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")
            and NMCore.shouldLogEvery and NMCore.shouldLogEvery("runtimeProbe.vehicleSilentWorld." .. uuid, tonumber(tickCount) or 0, 60) then
            local px = player and player.getX and tonumber(player:getX()) or 0
            local py = player and player.getY and tonumber(player:getY()) or 0
            local sx = source and tonumber(source.x) or 0
            local sy = source and tonumber(source.y) or 0
            local dx = px - sx
            local dy = py - sy
            local dist = math.sqrt((dx * dx) + (dy * dy))
            NMCore.logChannel(
                "runtimeProbe",
                "vehicle_world_silent",
                string.format(
                    "uuid=%s output=%s dist=%.2f px=%.2f py=%.2f sx=%.2f sy=%.2f sourceVehicleId=%s",
                    tostring(uuid),
                    tostring(routedOutputMode),
                    dist,
                    px, py, sx, sy,
                    tostring(source and source.vehicleId or "nil")
                )
            )
        end
        local expectsWorldAudible = routedOutputMode == "world" and routeWorld > 0.001
        if context == "vehicle" and state.isPlaying == true and expectsWorldAudible and vehicleResolved then
            local lastHealthy = tonumber(active.lastHealthyWorldMs) or nowMs
            local graceMs = math.max(250, tonumber(NMRuntimeConfig.get("vehicleGhostWorldChannelGraceMs", 1500)) or 1500)
            local staleMs = math.floor(nowMs - lastHealthy)
            local currentAssertState = worldPlaying and "healthy" or ((nowMs - lastHealthy) < graceMs and "stale_pre_grace" or "stale_post_grace")
            local previousAssertState = tostring(active._vehicleChannelAssertState or "")
            if previousAssertState ~= currentAssertState then
                local emittedState = currentAssertState
                if currentAssertState == "healthy"
                    and (previousAssertState == "stale_pre_grace" or previousAssertState == "stale_post_grace") then
                    emittedState = "recovered"
                end
                active._vehicleChannelAssertState = currentAssertState
                logVehicleRebindTrace(
                    "runtime_channel_assert",
                    uuid,
                    string.format(
                        "state=%s expectWorld=%s worldPlaying=%s personalPlaying=%s routeWorld=%.3f staleMs=%d",
                        tostring(emittedState),
                        tostring(expectsWorldAudible),
                        tostring(worldPlaying),
                        tostring(personalPlaying),
                        routeWorld,
                        staleMs
                    )
                )
            end
        else
            active._vehicleChannelAssertState = nil
        end
        if (not (active.world and active.world.alive)) or (not (active.personal and active.personal.alive)) then
            local shouldLogMissing = true
            if NMCore and NMCore.shouldLogEvery then
                shouldLogMissing = NMCore.shouldLogEvery("transitionProbe.dualMissing." .. uuid, tonumber(tickCount) or 0, 120)
            end
            if shouldLogMissing then
                logTransitionProbe(
                    "dual_channel_missing",
                    string.format(
                        "uuid=%s worldAlive=%s personalAlive=%s",
                        tostring(uuid),
                        tostring(active.world and active.world.alive == true),
                        tostring(active.personal and active.personal.alive == true)
                    )
                )
            end
        end
        runtimeDiag.updateVehicleEmitter(NMPlaybackRuntime, uuid, active, source, context)
    elseif active.emitter and active.soundId then
        if active.isWorldEmitter and source and source.x and source.y and source.z and active.emitter.setPos then
            active.emitter:setPos(source.x, source.y, source.z)
            active.lastX = tonumber(source.x) or active.lastX
            active.lastY = tonumber(source.y) or active.lastY
            active.lastZ = tonumber(source.z) or active.lastZ
            runtimeDiag.updateVehicleEmitter(NMPlaybackRuntime, uuid, active, source, context)
        end
        if active.emitter.setVolume then
            local routed = active.isWorldEmitter and effectiveVolume or ((routedOutputMode == "personal") and effectiveVolume or 0)
            local channelKind = active.isWorldEmitter and "world" or "personal"
            local resolvedVolume = NMPlaybackAudibility.computeChannelVolume(profile, state, player, source, channelKind, routed)
            active.emitter:setVolume(active.soundId, resolvedVolume)
        end
    end

end
function NMPlaybackRuntime.getDiagnosticsSnapshot()
    return runtimeDiag.snapshot(NMPlaybackRuntime)
end

function NMPlaybackRuntime.stopMissing(player, validUUIDs, tickNow)
    local now = tonumber(tickNow) or 0
    local nowMs = NMPlaybackRuntimeCommon.getNowRealMs and NMPlaybackRuntimeCommon.getNowRealMs() or 0
    local grace = math.max(1, tonumber(NMRuntimeConfig.get("emitterMissingGraceTicks", 60)) or 60)
    for uuid, _ in pairs(NMPlaybackRuntime.Active) do
        if validUUIDs and validUUIDs[uuid] then
            NMPlaybackRuntime.MissingSinceTick[uuid] = nil
            NMPlaybackRuntime.MissingSinceMs[uuid] = nil
        else
            local since = tonumber(NMPlaybackRuntime.MissingSinceTick[uuid])
            local sinceMs = tonumber(NMPlaybackRuntime.MissingSinceMs[uuid])
            if since == nil then
                NMPlaybackRuntime.MissingSinceTick[uuid] = now
            end
            if sinceMs == nil then
                NMPlaybackRuntime.MissingSinceMs[uuid] = nowMs
            end
            if since ~= nil and (now - since) >= grace then
                NMPlaybackRuntime.MissingSinceTick[uuid] = nil
                NMPlaybackRuntime.MissingSinceMs[uuid] = nil
                stopEntry(uuid, "missing_timeout")
            end
        end
    end
end

function NMPlaybackRuntime.forceStop(player, uuid, reason)
    if not uuid then return end
    local key = tostring(uuid)
    NMPlaybackRuntime.MissingSinceTick[key] = nil
    NMPlaybackRuntime.MissingSinceMs[key] = nil
    stopEntry(key, tostring(reason or "force_stop"))
end

function NMPlaybackRuntime.resetPowerTick(uuid, reason)
    local key = tostring(uuid or "")
    if key == "" then
        return false
    end
    if NMPlaybackRuntime.PowerTick[key] == nil then
        return false
    end
    NMPlaybackRuntime.PowerTick[key] = nil
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        NMCore.logChannel(
            "runtimeProbe",
            "battery_powertick_reset",
            string.format("uuid=%s reason=%s", tostring(key), tostring(reason or "unspecified"))
        )
    end
    return true
end

function NMPlaybackRuntime.invalidateTrackEnded(uuid)
    local key = tostring(uuid or "")
    if key == "" then return end
    NMPlaybackRuntime.TrackEnded[key] = nil
    NMPlaybackRuntime.TrackEndAwaitingAdvance[key] = nil
end

function NMPlaybackRuntime.consumeTrackEndedToken(uuid)
    local key = tostring(uuid or "")
    if key == "" then return nil end
    local payload = NMPlaybackRuntime.TrackEnded[key]
    if payload == nil then return nil end
    NMPlaybackRuntime.TrackEnded[key] = nil
    return payload
end

