-- Zombie attraction policy helpers with context-aware occlusion handling.
NMZombieAttraction = NMZombieAttraction or {}

function NMZombieAttraction.shouldAttract(profile, state, sourceContext)
    if not profile or not state then
        return false
    end
    if state.isPlaying ~= true or state.desiredIsPlaying ~= true then
        return false
    end
    if state.isMuted == true then
        return false
    end
    if (tonumber(state.volume) or 0) <= 0 then
        return false
    end

    local deviceType = tostring(profile.deviceType or "")
    if deviceType == "walkman" or deviceType == "cdplayer" then
        return false
    end
    if deviceType == "vehicle_radio" and tostring(sourceContext or "") == "vehicle" then
        return true
    end

    local outputMode = NMDeviceProfiles.resolveOutputMode(profile, state, sourceContext, false)
    return outputMode == "world"
end

function NMZombieAttraction.computePulse(profile, state, sourceContext, windowsOpen)
    if not profile or not state then
        return nil
    end
    if not NMZombieAttraction.shouldAttract(profile, state, sourceContext) then
        return nil
    end
    local volume01 = NMCore.clamp(tonumber(state.volume) or 0.0, 0.0, 1.0)
    if volume01 <= 0.0 then
        return nil
    end

    local range = NMDeviceProfiles.computeZombieRange(profile, volume01)
    local loudness = math.floor((volume01 * 100) + 0.5)

    if tostring(sourceContext or "") == "vehicle"
        and profile.vehicleWindowOcclusion
        and windowsOpen ~= true then
        local expMult = NMOcclusionMath.resolveClosedZombieExponentMultiplier(profile)
        range = NMDeviceProfiles.computeZombieRange(profile, volume01, expMult)
        local mult = NMOcclusionMath.resolveClosedZombieRangeMultiplier(profile)
        range = range * mult
        loudness = math.floor((loudness * mult) + 0.5)
    end

    if range <= 0 or loudness <= 0 then
        return nil
    end

    local pulseMs = NMDeviceProfiles.getZombiePulseIntervalMs(profile)
    if pulseMs < 100 then
        pulseMs = 100
    end

    return {
        range = range,
        loudness = loudness,
        intervalMs = pulseMs,
        gateBaseRange = NMDeviceProfiles.getZombiePlayerGateRange(profile)
    }
end

function NMZombieAttraction.computeGateRange(profile, pulse, gateMultiplier)
    if not profile or not pulse then
        return 0
    end
    local mult = tonumber(gateMultiplier) or 1.5
    if mult < 0.1 then
        mult = 0.1
    end
    local gateRange = math.max(tonumber(pulse.range) or 0, tonumber(pulse.gateBaseRange) or 0)
    return gateRange * mult
end

function NMZombieAttraction.shouldEmitForNearestPlayer(nearestDistanceSq, gateRange)
    if nearestDistanceSq == nil then
        return false
    end
    local g = tonumber(gateRange) or 0
    if g <= 0 then
        return false
    end
    return nearestDistanceSq <= (g * g)
end



