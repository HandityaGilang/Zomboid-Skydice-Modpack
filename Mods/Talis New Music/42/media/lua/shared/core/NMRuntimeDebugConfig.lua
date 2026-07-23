-- Debug master/knob configuration API layered onto NMRuntimeConfig.
NMRuntimeConfig = NMRuntimeConfig or {}

local values = NMRuntimeConfig._values or {}

local debugKnobNames = {
    "core",
    "intent",
    "state",
    "emitter",
    "runtimeProbe",
    "progressionProbe",
    "vehicleRebindTrace",
    "transitionProbe",
    "items",
    "net",
    "registry",
    "lootDiagnostics",
    "zombieDiagnostics",
    "vehicleDiagnostics",
    "vehicleTruthProbe",
    "uiPerfProbe",
    "uiAutoCloseProbe",
    "portableUiProbe"
}

local function ensureDebugDefaults()
    values.debugKnobs = values.debugKnobs or {}
    for i = 1, #debugKnobNames do
        local key = debugKnobNames[i]
        if values.debugKnobs[key] == nil then
            values.debugKnobs[key] = false
        end
    end
    if values.debugMasterEnabled == nil then
        values.debugMasterEnabled = false
    end
end

local function hasDebugKnob(name)
    local knobs = values.debugKnobs
    return type(knobs) == "table" and knobs[tostring(name or "")] ~= nil
end

ensureDebugDefaults()

function NMRuntimeConfig.getDebugMasterEnabled()
    return values.debugMasterEnabled == true
end

function NMRuntimeConfig.setDebugMasterEnabled(enabled)
    values.debugMasterEnabled = enabled == true
    return true
end

function NMRuntimeConfig.getDebugKnob(name)
    if not hasDebugKnob(name) then
        return false
    end
    return values.debugKnobs[tostring(name)] == true
end

function NMRuntimeConfig.setDebugKnob(name, enabled)
    if not hasDebugKnob(name) then
        return false
    end
    values.debugKnobs[tostring(name)] = enabled == true
    return true
end

function NMRuntimeConfig.getDebugKnobNames()
    local out = {}
    for i = 1, #debugKnobNames do
        out[i] = debugKnobNames[i]
    end
    return out
end

function NMRuntimeConfig.getDebugKnobsSnapshot()
    local out = {}
    local knobs = values.debugKnobs or {}
    for i = 1, #debugKnobNames do
        local key = debugKnobNames[i]
        out[key] = knobs[key] == true
    end
    return out
end

function NMRuntimeConfig.applyDebugPreset(name)
    local preset = tostring(name or "quiet")
    if preset == "quiet" then
        values.debugMasterEnabled = false
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        return true
    end
    if preset == "dev" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.core = true
        values.debugKnobs.state = true
        values.debugKnobs.net = true
        values.debugKnobs.registry = true
        values.debugKnobs.emitter = true
        values.debugKnobs.lootDiagnostics = true
        values.debugKnobs.vehicleDiagnostics = true
        return true
    end
    if preset == "loot" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.core = true
        values.debugKnobs.registry = true
        values.debugKnobs.lootDiagnostics = true
        return true
    end
    if preset == "zombie_mp_validation" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.core = true
        values.debugKnobs.intent = true
        values.debugKnobs.state = true
        values.debugKnobs.runtimeProbe = true
        values.debugKnobs.transitionProbe = true
        values.debugKnobs.net = true
        values.debugKnobs.registry = true
        values.debugKnobs.lootDiagnostics = true
        values.debugKnobs.zombieDiagnostics = true
        return true
    end
    if preset == "trace" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = true
        end
        return true
    end
    if preset == "rescue" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.runtimeProbe = true
        values.debugKnobs.progressionProbe = true
        values.debugKnobs.vehicleTruthProbe = true
        return true
    end
    if preset == "track_end" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.core = true
        values.debugKnobs.runtimeProbe = true
        values.debugKnobs.progressionProbe = true
        values.debugKnobs.transitionProbe = true
        return true
    end
    if preset == "vehicle_audit" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.core = true
        values.debugKnobs.runtimeProbe = true
        values.debugKnobs.vehicleTruthProbe = true
        values.debugKnobs.vehicleDiagnostics = true
        return true
    end
    if preset == "portable_mp_validation" or preset == "portable_mp_leak" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.core = true
        values.debugKnobs.emitter = true
        values.debugKnobs.runtimeProbe = true
        values.debugKnobs.transitionProbe = true
        return true
    end
    if preset == "portable_ui_investigation" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.core = true
        values.debugKnobs.intent = true
        values.debugKnobs.runtimeProbe = true
        values.debugKnobs.portableUiProbe = true
        return true
    end
    if preset == "boombox_mp_progression" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.core = true
        values.debugKnobs.emitter = true
        values.debugKnobs.runtimeProbe = true
        values.debugKnobs.progressionProbe = true
        return true
    end
    if preset == "corpse_sp_audio" then
        values.debugMasterEnabled = true
        for i = 1, #debugKnobNames do
            values.debugKnobs[debugKnobNames[i]] = false
        end
        values.debugKnobs.core = true
        values.debugKnobs.intent = true
        values.debugKnobs.state = true
        values.debugKnobs.emitter = true
        values.debugKnobs.runtimeProbe = true
        values.debugKnobs.transitionProbe = true
        values.debugKnobs.zombieDiagnostics = true
        return true
    end
    return false
end

return NMRuntimeConfig

