-- Central runtime tunables for tracking, sync cadence, and guard windows.
NMRuntimeConfig = NMRuntimeConfig or {}

local function getNewMusicSandbox()
    local root = SandboxVars
    if type(root) ~= "table" then
        return nil
    end
    local page = root.NewMusic
    if type(page) ~= "table" then
        return nil
    end
    return page
end

local function resolveSandboxNumber(key)
    local page = getNewMusicSandbox()
    if not page then
        return nil
    end
    return tonumber(page[key])
end

local function resolveSandboxBoolean(key)
    local page = getNewMusicSandbox()
    if not page then
        return nil
    end
    local value = page[key]
    if value == nil then
        return nil
    end
    if value == true or value == false then
        return value
    end
    local asNumber = tonumber(value)
    if asNumber ~= nil then
        return asNumber ~= 0
    end
    local text = tostring(value):lower()
    if text == "true" or text == "yes" or text == "on" then
        return true
    end
    if text == "false" or text == "no" or text == "off" then
        return false
    end
    return nil
end

local function clampNumber(value, minValue, maxValue)
    local n = tonumber(value)
    if n == nil then
        return nil
    end
    if n < minValue then
        return minValue
    end
    if n > maxValue then
        return maxValue
    end
    return n
end

local values = {
    buildContentToken = "2026-07-14-workshop-refresh-1",
    worldTrackingCap = 1500,
    registryStaleTicks = 7200,
    registryHeartbeatIntervalTicks = 120,
    registryResyncIntervalTicks = 600,
    registryResyncMoveDistance = 48,
    registryRequestTimeoutTicks = 180,
    registryResyncCooldownMs = 3000,
    netRegistryLogThrottleTicks = 600,
    attachmentDiagnosticsThrottleTicks = 900,
    carryTruthHoldTicks = 45,
    maxActiveWorldSourcesPerClient = 10,
    serverZombiePlayerGateMultiplier = 1.5,
    authorityScope = "all_world_devices",
    attachedAuthorityGraceTicks = 180,
    serverDormancyMinutes = 5,
    serverUnresolvedGraceSeconds = 6,
    serverUnseenExpiryEnabled = false,
    serverUnseenExpiryMinutes = 30,
    emitterMissingGraceTicks = 60,
    trackEndPendingWindowMs = 1200,
    trackEndPendingFalseChecks = 3,
    trackEndPendingWindowMsByDeviceType = {},
    trackEndPendingFalseChecksByDeviceType = {},
    debugMasterEnabled = false,
    zombieLiveVisualStrategySP = "sp_runtime_attach",
    zombieLiveVisualStrategyMP = "mp_assignment_flow",
    debugKnobs = {
        core = false,
        intent = false,
        state = false,
        emitter = false,
        runtimeProbe = false,
        progressionProbe = false,
        vehicleRebindTrace = false,
        transitionProbe = false,
        items = false,
        net = false,
        registry = false,
        lootDiagnostics = false,
        zombieDiagnostics = false,
        vehicleDiagnostics = false,
        vehicleTruthProbe = false,
        uiPerfProbe = false,
        uiAutoCloseProbe = false,
        portableUiProbe = false
    },
    bootDebugPreset = "quiet",
    enableVehicleEmitterDiagnostics = true,
    vehicleEmitterJumpWarnDistance = 12,
    vehicleEmitterJumpRebindHintDistance = 48,
    allowNoHeadphonesPlaybackMutedPersonal = true,
    vehicleHybridPersonalForOccupants = true,
    vehicleOutputFlipDebounceMs = 750,
    vehicleDualEmittersEnabled = true,
    vehicleGhostWorldChannelGraceMs = 1500,
    vehicleRebindTraceUUID = "",
    serverVehicleTrackDurationMs = 210000,
    serverVehicleTrackHintMinAgeMs = 5000,
    noListenerFreezeDebounceMs = 3000,
    noListenerResumeDebounceMs = 1000,
    dualGainMinLogMs = 250,
    batteryDrainSecondsPortable = 900,
    batteryDrainSecondsVehicleEngineOff = 300,
    vehicleCustomDrainEnabled = false,
    stickySqlBindingTtlMs = 45000,
    mpResetPlaybackOnServerStart = true,
    fancyUIEnabled = true
}
NMRuntimeConfig._values = values

function NMRuntimeConfig.get(key, defaultValue)
    local v = values[key]
    if v == nil then
        return defaultValue
    end
    return v
end

function NMRuntimeConfig.getBootDebugPreset()
    return tostring(values.bootDebugPreset or "")
end

function NMRuntimeConfig.getBuildContentToken()
    return tostring(values.buildContentToken or "")
end

function NMRuntimeConfig.getFancyUIEnabled()
    local fromSandbox = resolveSandboxBoolean("FancyUI")
    if fromSandbox ~= nil then
        return fromSandbox == true
    end
    return values.fancyUIEnabled ~= false
end

function NMRuntimeConfig.set(key, value)
    if key == nil then
        return false
    end
    values[tostring(key)] = value
    return true
end

function NMRuntimeConfig.getWorldTrackingCap()
    local fromSandbox = resolveSandboxNumber("MaxTrackingRange")
    if fromSandbox ~= nil then
        if fromSandbox <= 0 then
            return 0
        end
        return math.max(1, math.min(36000, math.floor(fromSandbox + 0.5)))
    end
    local value = tonumber(values.worldTrackingCap) or 1500
    if value <= 0 then
        return 0
    end
    return math.max(1, math.floor(value + 0.5))
end

function NMRuntimeConfig.getRegistryHeartbeatIntervalTicks()
    return tonumber(values.registryHeartbeatIntervalTicks) or 120
end

function NMRuntimeConfig.getRegistryResyncIntervalTicks()
    return tonumber(values.registryResyncIntervalTicks) or 600
end

function NMRuntimeConfig.getRegistryResyncMoveDistance()
    return tonumber(values.registryResyncMoveDistance) or 48
end

function NMRuntimeConfig.getRegistryRequestTimeoutTicks()
    return tonumber(values.registryRequestTimeoutTicks) or 180
end

function NMRuntimeConfig.getRegistryResyncCooldownMs()
    return tonumber(values.registryResyncCooldownMs) or 3000
end

function NMRuntimeConfig.getMaxActiveWorldSourcesPerClient()
    local fromSandbox = resolveSandboxNumber("ActiveDeviceLimit")
    if fromSandbox ~= nil then
        return math.max(4, math.min(50, math.floor(fromSandbox + 0.5)))
    end
    local value = tonumber(values.maxActiveWorldSourcesPerClient) or 10
    return math.max(4, math.min(50, math.floor(value + 0.5)))
end

function NMRuntimeConfig.getServerDormancyMinutes()
    return tonumber(values.serverDormancyMinutes) or 5
end

function NMRuntimeConfig.getServerUnresolvedGraceSeconds()
    return tonumber(values.serverUnresolvedGraceSeconds) or 6
end

function NMRuntimeConfig.getServerZombiePlayerGateMultiplier()
    return tonumber(values.serverZombiePlayerGateMultiplier) or 1.5
end

function NMRuntimeConfig.getAuthorityScope()
    return tostring(values.authorityScope or "all_world_devices")
end

function NMRuntimeConfig.getServerUnseenExpiryEnabled()
    return values.serverUnseenExpiryEnabled == true
end

function NMRuntimeConfig.getServerUnseenExpiryMinutes()
    return tonumber(values.serverUnseenExpiryMinutes) or 30
end

function NMRuntimeConfig.getTrackEndPendingWindowMs()
    return tonumber(values.trackEndPendingWindowMs) or 1200
end

function NMRuntimeConfig.getTrackEndPendingFalseChecks()
    return tonumber(values.trackEndPendingFalseChecks) or 3
end

function NMRuntimeConfig.getTrackEndPendingWindowMsForDeviceType(deviceType)
    local dt = tostring(deviceType or "")
    local map = values.trackEndPendingWindowMsByDeviceType
    if dt ~= "" and type(map) == "table" then
        local override = tonumber(map[dt])
        if override and override > 0 then
            return math.max(250, math.floor(override + 0.5))
        end
    end
    return NMRuntimeConfig.getTrackEndPendingWindowMs()
end

function NMRuntimeConfig.getTrackEndPendingFalseChecksForDeviceType(deviceType)
    local dt = tostring(deviceType or "")
    local map = values.trackEndPendingFalseChecksByDeviceType
    if dt ~= "" and type(map) == "table" then
        local override = tonumber(map[dt])
        if override and override > 0 then
            return math.max(1, math.floor(override + 0.5))
        end
    end
    return NMRuntimeConfig.getTrackEndPendingFalseChecks()
end

function NMRuntimeConfig.enableVehicleEmitterDiagnostics()
    if NMRuntimeConfig.getDebugKnob then
        return NMRuntimeConfig.getDebugKnob("vehicleDiagnostics") == true
    end
    return values.enableVehicleEmitterDiagnostics == true
end

function NMRuntimeConfig.getVehicleEmitterJumpWarnDistance()
    return tonumber(values.vehicleEmitterJumpWarnDistance) or 12
end

function NMRuntimeConfig.getVehicleEmitterJumpRebindHintDistance()
    return tonumber(values.vehicleEmitterJumpRebindHintDistance) or 48
end

function NMRuntimeConfig.getAllowNoHeadphonesPlaybackMutedPersonal()
    return values.allowNoHeadphonesPlaybackMutedPersonal == true
end

function NMRuntimeConfig.getVehicleHybridPersonalForOccupants()
    return values.vehicleHybridPersonalForOccupants == true
end

function NMRuntimeConfig.getVehicleOutputFlipDebounceMs()
    return tonumber(values.vehicleOutputFlipDebounceMs) or 750
end

function NMRuntimeConfig.getVehicleDualEmittersEnabled()
    return values.vehicleDualEmittersEnabled == true
end

function NMRuntimeConfig.getServerVehicleTrackDurationMs()
    local value = tonumber(values.serverVehicleTrackDurationMs) or 210000
    return math.max(1000, math.floor(value + 0.5))
end

function NMRuntimeConfig.getBatteryDrainSecondsPortable()
    local value = tonumber(values.batteryDrainSecondsPortable) or 600
    return math.max(1, value)
end

function NMRuntimeConfig.getBatteryDrainRateHours()
    local fromSandbox = clampNumber(resolveSandboxNumber("BatteryDrainRate"), 0.02, 1000.0)
    if fromSandbox ~= nil then
        return fromSandbox
    end
    return 24.0
end

function NMRuntimeConfig.getAudioMaxRadius()
    local fromSandbox = clampNumber(resolveSandboxNumber("AudioMaxRadius"), 9, 100)
    if fromSandbox ~= nil then
        return math.max(9, math.min(100, math.floor(fromSandbox + 0.5)))
    end
    return 35
end

function NMRuntimeConfig.getDisassemblyEnabled()
    local value = resolveSandboxBoolean("Disassembly")
    if value ~= nil then
        return value
    end
    return true
end

function NMRuntimeConfig.getZomboidOSTEnabled()
    local value = resolveSandboxBoolean("ZomboidOST")
    if value ~= nil then
        return value
    end
    return true
end

function NMRuntimeConfig.getBatteryDrainSecondsPortableFromSandbox()
    return math.max(1.0, NMRuntimeConfig.getBatteryDrainRateHours() * 3600.0)
end

function NMRuntimeConfig.getNoListenerFreezeDebounceMs()
    local value = tonumber(values.noListenerFreezeDebounceMs) or 3000
    return math.max(0, math.floor(value + 0.5))
end

function NMRuntimeConfig.getNoListenerResumeDebounceMs()
    local value = tonumber(values.noListenerResumeDebounceMs) or 1000
    return math.max(0, math.floor(value + 0.5))
end

function NMRuntimeConfig.getStickySqlBindingTtlMs()
    return tonumber(values.stickySqlBindingTtlMs) or 45000
end

function NMRuntimeConfig.getBatteryDrainSecondsVehicleEngineOff()
    local value = tonumber(values.batteryDrainSecondsVehicleEngineOff) or 300
    return math.max(1, value)
end

function NMRuntimeConfig.getVehicleCustomDrainEnabled()
    return values.vehicleCustomDrainEnabled == true
end

function NMRuntimeConfig.getMPResetPlaybackOnServerStart()
    return values.mpResetPlaybackOnServerStart == true
end

function NMRuntimeConfig.getLootRate(optionKey, defaultValue)
    local fallback = tonumber(defaultValue) or 0.6
    local fromSandbox = clampNumber(resolveSandboxNumber(optionKey), 0.0, 4.0)
    if fromSandbox ~= nil then
        return fromSandbox
    end
    return fallback
end

function NMRuntimeConfig.getCassettesSpawnRate()
    return NMRuntimeConfig.getLootRate("CassettesSpawnRate", 0.6)
end

function NMRuntimeConfig.getVinylRecordsSpawnRate()
    return NMRuntimeConfig.getLootRate("VinylRecordsSpawnRate", 0.6)
end

function NMRuntimeConfig.getCDsSpawnRate()
    return NMRuntimeConfig.getLootRate("CDsSpawnRate", 0.6)
end

function NMRuntimeConfig.getWalkmanSpawnRate()
    return NMRuntimeConfig.getLootRate("WalkmanSpawnRate", 0.6)
end

function NMRuntimeConfig.getBoomboxSpawnRate()
    return NMRuntimeConfig.getLootRate("BoomboxSpawnRate", 0.6)
end

function NMRuntimeConfig.getCDPlayerSpawnRate()
    return NMRuntimeConfig.getLootRate("CDPlayerSpawnRate", 0.6)
end

function NMRuntimeConfig.getRecordPlayerSpawnRate()
    return NMRuntimeConfig.getLootRate("RecordPlayerSpawnRate", 0.6)
end

function NMRuntimeConfig.getMusicalZombiesSpawnRate()
    return NMRuntimeConfig.getLootRate("MusicalZombiesSpawnRate", 0.6)
end

function NMRuntimeConfig.snapshot()
    local out = {}
    for k, v in pairs(values) do
        if type(v) == "table" then
            local copy = {}
            for tk, tv in pairs(v) do
                copy[tk] = tv
            end
            out[k] = copy
        else
            out[k] = v
        end
    end
    return out
end

return NMRuntimeConfig

