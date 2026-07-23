-- Core constants and low-level utilities shared by client and server.
NMCore = NMCore or {}

NMCore.ModId = "newmusic"
NMCore.BuildMarker = "NM_BUILD_2026-05-28_compat_probe"
NMCore.NetModule = "newmusic_device"
NMCore.StateKey = "nm_device_state"
NMCore.RegistryKey = "nm_device"
NMCore.StateVersion = 4
NMCore.Debug = false
NMCore.DebugPlayback = false
NMCore.DebugChannels = NMCore.DebugChannels or {}
NMCore.DebugThrottle = NMCore.DebugThrottle or {}
NMCore.SuppressVanillaWorldContext = true

local knownKnobs = {
    core = true,
    intent = true,
    state = true,
    emitter = true,
    runtimeProbe = true,
    progressionProbe = true,
    vehicleRebindTrace = true,
    transitionProbe = true,
    items = true,
    net = true,
    registry = true,
    lootDiagnostics = true,
    zombieDiagnostics = true,
    vehicleDiagnostics = true,
    vehicleTruthProbe = true,
    uiPerfProbe = true,
    uiAutoCloseProbe = true,
    portableUiProbe = true
}

local function toBool(v)
    return v == true
end

local function mapLogSection(channel)
    local raw = tostring(channel or "")
    local map = {
        runtimeProbe = "TimeProbe",
        progressionProbe = "TimeProbe",
        vehicleTruthProbe = "VehicleTruthProbe",
        intent = "IntentProbe",
        core = "CoreProbe",
        registry = "RegistryProbe",
        lootDiagnostics = "LootProbe",
        zombieDiagnostics = "ZombieProof",
        transitionProbe = "TransitionProbe"
        ,
        uiPerfProbe = "UiPerfProbe",
        uiAutoCloseProbe = "UiAutoCloseProbe",
        portableUiProbe = "PortableUiProbe"
    }
    if map[raw] then
        return map[raw]
    end
    local compact = raw:gsub("[^%w]+", " ")
    local words = {}
    for part in compact:gmatch("%S+") do
        words[#words + 1] = part
    end
    if #words == 0 then
        return "CoreProbe"
    end
    local out = {}
    for i = 1, #words do
        local w = words[i]
        if w:find("%u") and w:find("%l") then
            out[#out + 1] = w:sub(1, 1):upper() .. w:sub(2)
        else
            out[#out + 1] = w:sub(1, 1):upper() .. w:sub(2):lower()
        end
    end
    local joined = table.concat(out, "")
    if joined:sub(-5) ~= "Probe" then
        joined = joined .. "Probe"
    end
    return joined
end

local function debugPrint(msg)
    print("[NewMusic] [CoreProbe] " .. tostring(msg or ""))
end

local function mapScopeToKnob(scope)
    local key = tostring(scope or "")
    if key == "playback" then
        return "emitter"
    end
    if key == "all" then
        return "all"
    end
    if knownKnobs[key] then
        return key
    end
    return nil
end

local function syncLegacyDebugFields()
    local runtime = type(NMRuntimeConfig) == "table" and NMRuntimeConfig or nil
    NMCore.Debug = runtime and runtime.getDebugMasterEnabled and runtime.getDebugMasterEnabled() == true or false
    NMCore.DebugPlayback = runtime and runtime.getDebugKnob and runtime.getDebugKnob("emitter") == true or false
    NMCore.DebugChannels = NMCore.DebugChannels or {}
    for knob, _ in pairs(knownKnobs) do
        NMCore.DebugChannels[knob] = runtime and runtime.getDebugKnob and runtime.getDebugKnob(knob) == true or false
    end
end

syncLegacyDebugFields()

function NMCore.clamp(value, minValue, maxValue)
    if value == nil then
        return minValue
    end
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

function NMCore.itemId(item)
    if not item or not item.getID then
        return nil
    end
    return tostring(item:getID())
end

function NMCore.readDrainableFraction(item, defaultValue)
    if not item then
        return defaultValue
    end
    local value = nil
    if item.getCurrentUsesFloat then
        value = item:getCurrentUsesFloat()
    elseif item.getUsedDelta then
        value = item:getUsedDelta()
    elseif item.getDelta then
        value = item:getDelta()
    end
    value = tonumber(value)
    if value == nil then
        return defaultValue
    end
    return NMCore.clamp(value, 0.0, 1.0)
end


function NMCore.isDebugEnabled()
    local runtime = type(NMRuntimeConfig) == "table" and NMRuntimeConfig or nil
    return runtime and runtime.getDebugMasterEnabled and runtime.getDebugMasterEnabled() == true or false
end

function NMCore.isDebugKnobOn(knob)
    local key = mapScopeToKnob(knob)
    if not key or key == "all" then
        return false
    end
    if not NMCore.isDebugEnabled() then
        return false
    end
    local runtime = type(NMRuntimeConfig) == "table" and NMRuntimeConfig or nil
    if runtime and runtime.getDebugKnob then
        return runtime.getDebugKnob(key) == true
    end
    return false
end

function NMCore.setDebugMaster(enabled)
    local runtime = type(NMRuntimeConfig) == "table" and NMRuntimeConfig or nil
    if runtime and runtime.setDebugMasterEnabled then
        runtime.setDebugMasterEnabled(toBool(enabled))
        syncLegacyDebugFields()
        debugPrint("setDebugMaster enabled=" .. tostring(NMCore.isDebugEnabled()))
        return true
    end
    debugPrint("setDebugMaster failed runtime_missing")
    return false
end

function NMCore.setDebugKnob(knob, enabled)
    local key = mapScopeToKnob(knob)
    if not key or key == "all" then
        return false
    end
    local runtime = type(NMRuntimeConfig) == "table" and NMRuntimeConfig or nil
    if runtime and runtime.setDebugKnob then
        local ok = runtime.setDebugKnob(key, toBool(enabled))
        syncLegacyDebugFields()
        debugPrint("setDebugKnob knob=" .. tostring(key) .. " enabled=" .. tostring(NMCore.isDebugKnobOn(key)))
        return ok == true
    end
    debugPrint("setDebugKnob failed knob=" .. tostring(key) .. " runtime_missing")
    return false
end

function NMCore.setDebugPreset(name)
    local runtime = type(NMRuntimeConfig) == "table" and NMRuntimeConfig or nil
    if runtime and runtime.applyDebugPreset then
        local ok = runtime.applyDebugPreset(name)
        syncLegacyDebugFields()
        debugPrint("setDebugPreset name=" .. tostring(name) .. " ok=" .. tostring(ok == true))
        return ok == true
    end
    debugPrint("setDebugPreset failed name=" .. tostring(name) .. " runtime_missing")
    return false
end

function NMCore.dumpDebugState()
    local runtime = type(NMRuntimeConfig) == "table" and NMRuntimeConfig or nil
    local master = NMCore.isDebugEnabled()
    local knobs = runtime and runtime.getDebugKnobNames and runtime.getDebugKnobNames() or {}
    local parts = {}
    for i = 1, #knobs do
        local key = tostring(knobs[i])
        local on = runtime and runtime.getDebugKnob and runtime.getDebugKnob(key) == true
        parts[#parts + 1] = key .. "=" .. tostring(on)
    end
    debugPrint("state master=" .. tostring(master) .. " knobs={" .. table.concat(parts, ",") .. "}")
end

function NMCore.setDebug(enabled, scope)
    local value = toBool(enabled)
    local key = mapScopeToKnob(scope or "all")
    if not scope or key == "all" then
        NMCore.setDebugMaster(value)
        local runtime = type(NMRuntimeConfig) == "table" and NMRuntimeConfig or nil
        local knobs = runtime and runtime.getDebugKnobNames and runtime.getDebugKnobNames() or {}
        for i = 1, #knobs do
            if runtime and runtime.setDebugKnob then
                runtime.setDebugKnob(knobs[i], value)
            end
        end
        syncLegacyDebugFields()
        return
    end
    if not key then
        return
    end
    if value == true then
        NMCore.setDebugMaster(true)
    end
    NMCore.setDebugKnob(key, value)
end

function NMCore.isDebugChannelEnabled(channel)
    return NMCore.isDebugKnobOn(channel)
end

function NMCore.shouldLogEvery(key, nowValue, interval)
    if key == nil then
        return true
    end
    local now = tonumber(nowValue) or 0
    local step = math.max(1, tonumber(interval) or 1)
    local last = tonumber(NMCore.DebugThrottle[key])
    if last ~= nil and (now - last) < step then
        return false
    end
    NMCore.DebugThrottle[key] = now
    return true
end

function NMCore.log(msg, detail)
    if not NMCore.isDebugKnobOn("state") then
        return
    end
    local line = tostring(msg)
    if detail ~= nil then
        line = line .. " " .. tostring(detail)
    end
    print("[NewMusic] [CoreProbe] " .. line)
end

function NMCore.logChannel(channel, msg, detail)
    if not NMCore.isDebugKnobOn(channel) then
        return
    end
    local line = tostring(msg)
    if detail ~= nil then
        line = line .. " " .. tostring(detail)
    end
    local section = mapLogSection(channel)
    print("[NewMusic] [" .. tostring(section) .. "] " .. line)
end

local function trimString(v)
    local s = tostring(v or "")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

function NMCore.getVehicleRebindTraceUUID()
    local runtime = type(NMRuntimeConfig) == "table" and NMRuntimeConfig or nil
    if not (runtime and runtime.get) then
        return ""
    end
    return trimString(runtime.get("vehicleRebindTraceUUID", ""))
end

function NMCore.isVehicleRebindTraceEnabled(uuid)
    if not NMCore.isDebugKnobOn("vehicleRebindTrace") then
        return false
    end
    local filterUuid = NMCore.getVehicleRebindTraceUUID()
    if filterUuid == "" then
        return true
    end
    return trimString(uuid) == filterUuid
end

function NMCore.logVehicleRebindTrace(tag, uuid, detail)
    if not NMCore.isVehicleRebindTraceEnabled(uuid) then
        return
    end
    local line = "uuid=" .. tostring(uuid or "")
    if detail ~= nil and tostring(detail) ~= "" then
        line = line .. " " .. tostring(detail)
    end
    NMCore.logChannel("vehicleRebindTrace", tostring(tag or "trace"), line)
end

function NMCore.getRuntimeAuthorityMode()
    local world = getWorld and getWorld() or nil
    local mode = world and world.getGameMode and tostring(world:getGameMode() or "") or ""
    local isSrv = isServer and isServer() or false
    local isCli = isClient and isClient() or false
    if mode == "Multiplayer" then
        if isSrv then
            return "mp_server_host"
        end
        if isCli then
            return "mp_client"
        end
        return "mp_unknown"
    end
    return "sp_local"
end

function NMCore.isMultiplayerMode()
    local world = getWorld and getWorld() or nil
    local mode = world and world.getGameMode and tostring(world:getGameMode() or "") or ""
    return mode == "Multiplayer"
end

function NMCore.isMPServerAuthority()
    return NMCore.isMultiplayerMode() and (isServer and isServer() or false)
end

function NMCore.isMPClientRuntime()
    return NMCore.isMultiplayerMode() and (isClient and isClient() or false)
end

return NMCore




