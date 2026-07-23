require "runtime/NMClientInventoryItemVisualSanitizer"
require "runtime/NMClientWorldItemVisualSanitizer"
require "runtime/NMClientZombieVisualTargetCache"
require "runtime/NMClientZombieVisualProbe"
require "zombies/NMZombieVisualTargetContract"
require "zombies/NMZombieAttachedDefinitions"
require "zombies/NMZombieLiveStrategy"

-- Client bootstrap that wires engine events to modular handlers.
NMDevicesClient = NMDevicesClient or {}
NMDevicesClient._uiLagProbeAutoEnable = false
NMDevicesClient._uiAutoCloseProbeAutoEnable = false
local radialHookRetryTick = 0

local function onFillInventoryObjectContextMenu(playerNum, context, items)
    NMContextMenus.onFillInventoryObjectContextMenu(playerNum, context, items)
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    NMContextMenus.onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
end

local function onTick()
    local player = getPlayer and getPlayer() or nil
    radialHookRetryTick = (tonumber(radialHookRetryTick) or 0) + 1
    if NMVehicleRadial and NMVehicleRadial.hookInstalled ~= true then
        if (radialHookRetryTick % 120) == 1 then
            NMVehicleRadial.installHook()
        end
    end
    NMClientRegistrySync.onTick(player)
    if NMClientPlaybackTick and NMClientPlaybackTick.onTick then
        NMClientPlaybackTick.onTick(player)
    elseif NMCore and NMCore.logChannel then
        NMCore.logChannel("core", "client_playback_tick_missing", "NMClientPlaybackTick.onTick=nil")
    end
    if NMWalkmanWindow and NMWalkmanWindow.tickPersistedRestore then
        NMWalkmanWindow.tickPersistedRestore()
    end
    if NMClientWorldItemVisualSanitizer and NMClientWorldItemVisualSanitizer.onTick then
        NMClientWorldItemVisualSanitizer.onTick(player)
    end
    if NMClientInventoryItemVisualSanitizer and NMClientInventoryItemVisualSanitizer.onTick then
        NMClientInventoryItemVisualSanitizer.onTick(player)
    end
    if NMClientZombieVisualTargetCache and NMClientZombieVisualTargetCache.onTick then
        NMClientZombieVisualTargetCache.onTick()
    end
    if NMClientZombieVisualProbe and NMClientZombieVisualProbe.onTick then
        NMClientZombieVisualProbe.onTick(player)
    end
    if NMDevicesClient.onTick then
        NMDevicesClient.onTick()
    end
end

local function onServerCommand(module, command, args)
    if module == NMCore.NetModule then
        if NMClientZombieVisualTargetCache and NMClientZombieVisualTargetCache.onServerCommand and NMClientZombieVisualTargetCache.onServerCommand(command, args) == true then
            return
        end
        if NMClientSessionProjection and NMClientSessionProjection.observeServerSessionToken then
            NMClientSessionProjection.observeServerSessionToken(args and args.serverSessionToken, command)
        end
        NMClientRegistrySync.onServerCommand(command, args)
        if command == "state" then
            local player = getPlayer and getPlayer() or nil
            NMClientStateSync.onServerState(player, args)
        end
        if command == "debug_sync" then
            local enabled = args and args.enabled == true
            local scope = tostring(args and args.scope or "all")
            NMCore.setDebug(enabled, scope)
            if NMCore and NMCore.logChannel then
                NMCore.logChannel("core", "debug_sync_applied", "enabled=" .. tostring(enabled) .. " scope=" .. tostring(scope))
                NMCore.logChannel(
                    "zombieDiagnostics",
                    "client_debug_sync",
                    string.format(
                        "enabled=%s scope=%s authority=%s",
                        tostring(enabled),
                        tostring(scope),
                        tostring(NMCore.getRuntimeAuthorityMode and NMCore.getRuntimeAuthorityMode() or "unknown")
                    )
                )
                if NMCore.dumpDebugState then
                    NMCore.dumpDebugState()
                end
            end
        end
        if command == "registry_update" and args and args.op and args.payload then
            NMClientWorldSourceCache.onRegistryUpdate(args.op, args.payload, args.serverSessionToken)
        end
        if command == "media_flip_result" then
            local player = getPlayer and getPlayer() or nil
            if NMContextMenus and NMContextMenus.onMediaFlipResult then
                NMContextMenus.onMediaFlipResult(player, args or {})
            end
        end
    end
    if NMDevicesClient.onServerCommand then
        NMDevicesClient.onServerCommand(module, command, args)
    end
end

local function applyBootDebugPreset()
    if not (NMRuntimeConfig and NMRuntimeConfig.applyDebugPreset) then
        return
    end
    local preset = NMRuntimeConfig.getBootDebugPreset and tostring(NMRuntimeConfig.getBootDebugPreset() or "") or ""
    if preset ~= "" then
        NMRuntimeConfig.applyDebugPreset(preset)
        return
    end
    NMRuntimeConfig.applyDebugPreset("quiet")
end

local function logClientDebugBootstrap(stage)
    local preset = NMRuntimeConfig and NMRuntimeConfig.getBootDebugPreset and tostring(NMRuntimeConfig.getBootDebugPreset() or "") or ""
    local master = NMRuntimeConfig and NMRuntimeConfig.getDebugMasterEnabled and NMRuntimeConfig.getDebugMasterEnabled() == true or false
    if not master then
        return
    end
    local knobs = NMRuntimeConfig and NMRuntimeConfig.getDebugKnobsSnapshot and NMRuntimeConfig.getDebugKnobsSnapshot() or {}
    print(string.format(
        "[NewMusic] [DebugBootstrap] side=client stage=%s preset=%s master=%s knobs=core:%s,intent:%s,state:%s,emitter:%s,runtimeProbe:%s,transitionProbe:%s,registry:%s,progressionProbe:%s,lootDiagnostics:%s,zombieDiagnostics:%s,uiAutoCloseProbe:%s,portableUiProbe:%s",
        tostring(stage or "unknown"),
        tostring(preset ~= "" and preset or "quiet"),
        tostring(master),
        tostring(knobs.core == true),
        tostring(knobs.intent == true),
        tostring(knobs.state == true),
        tostring(knobs.emitter == true),
        tostring(knobs.runtimeProbe == true),
        tostring(knobs.transitionProbe == true),
        tostring(knobs.registry == true),
        tostring(knobs.progressionProbe == true),
        tostring(knobs.lootDiagnostics == true),
        tostring(knobs.zombieDiagnostics == true),
        tostring(knobs.uiAutoCloseProbe == true),
        tostring(knobs.portableUiProbe == true)
    ))
end

local function sendDebugSet(scope, enabled)
    if sendClientCommand and NMCore and NMCore.NetModule then
        sendClientCommand(NMCore.NetModule, "debug_set", { scope = tostring(scope or "all"), enabled = enabled == true })
    end
end

local function setLocalDebug(scope, enabled)
    if NMCore and NMCore.setDebug then
        NMCore.setDebug(enabled == true, tostring(scope or "all"))
    end
end

-- Console helpers for MP UI lag forensics.
function NMDevicesClient.enableUiLagProbe()
    NMDevicesClient._uiLagProbeAutoEnable = true
    -- Local toggles must land first so client UI probes still work when server sync is gated.
    setLocalDebug("all", false)
    setLocalDebug("core", true)
    setLocalDebug("runtimeProbe", true)
    setLocalDebug("uiPerfProbe", true)

    -- Mirror the same scope to the server when allowed.
    sendDebugSet("all", false)
    sendDebugSet("core", true)
    sendDebugSet("runtimeProbe", true)
    sendDebugSet("uiPerfProbe", true)
end

function NMDevicesClient.disableUiLagProbe()
    NMDevicesClient._uiLagProbeAutoEnable = false
    setLocalDebug("all", false)
    sendDebugSet("all", false)
end

function NMDevicesClient.enableUiAutoCloseProbe()
    setLocalDebug("all", false)
    setLocalDebug("core", true)
    setLocalDebug("uiAutoCloseProbe", true)
end

function NMDevicesClient.disableUiAutoCloseProbe()
    setLocalDebug("all", false)
end

local function onGameStart()
    applyBootDebugPreset()
    logClientDebugBootstrap("onGameStart")
    if NMCore and NMCore.logChannel then
        NMCore.logChannel(
            "zombieDiagnostics",
            "client_boot",
            string.format(
                "authority=%s isClient=%s isServer=%s preset=%s liveStrategy=%s",
                tostring(NMCore.getRuntimeAuthorityMode and NMCore.getRuntimeAuthorityMode() or "unknown"),
                tostring(isClient and isClient() or false),
                tostring(isServer and isServer() or false),
                tostring(NMRuntimeConfig and NMRuntimeConfig.getBootDebugPreset and NMRuntimeConfig.getBootDebugPreset() or ""),
                tostring(NMZombieLiveStrategy and NMZombieLiveStrategy.getLiveVisualStrategy and NMZombieLiveStrategy.getLiveVisualStrategy() or "unknown")
            )
        )
    end
    if NMDevicesClient._uiLagProbeAutoEnable == true then
        NMDevicesClient.enableUiLagProbe()
    end
    if NMDevicesClient._uiAutoCloseProbeAutoEnable == true then
        NMDevicesClient.enableUiAutoCloseProbe()
    end
    if NMClientSessionProjection and NMClientSessionProjection.onGameStart then
        NMClientSessionProjection.onGameStart()
    end
    NMClientRegistrySync.requestInitialSync()
    if not NMCore.isMPClientRuntime() then
        local player = getPlayer and getPlayer() or nil
        if player then
            local seeded = NMWorldRegistrySnapshot.seedCacheForPlayerSP(player, function(entry)
                if not entry or not entry.state then
                    return false
                end
                local sourceMode = tostring(entry.sourceMode or ((entry.kind == "vehicle") and "vehicle" or "placed"))
                local profileType = tostring(entry.profileType or ((entry.kind == "vehicle") and "vehicle_radio" or entry.itemFullType or ""))
                NMClientWorldSourceCache.upsertFromPayload({
                    kind = tostring(entry.kind or "item"),
                    uuid = tostring(entry.uuid or ""),
                    profileType = profileType ~= "" and profileType or nil,
                    sourceMode = sourceMode,
                    x = tonumber(entry.x) or 0,
                    y = tonumber(entry.y) or 0,
                    z = tonumber(entry.z) or 0,
                    sourceEpoch = tonumber(entry.sourceEpoch) or tonumber(entry.state.sourceGeneration) or 0,
                    itemId = entry.itemId,
                    itemFullType = entry.itemFullType,
                    vehicleId = entry.vehicleId,
                    vehicleIdHint = entry.vehicleIdHint,
                    vehicleSqlId = entry.vehicleSqlId,
                    vehicleSqlIdHint = entry.vehicleSqlIdHint,
                    partId = entry.partId,
                    windowsOpen = entry.windowsOpen == true,
                    state = entry.state
                })
                return true
            end)
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("core") then
                NMCore.logChannel("core", "sp_snapshot_seed", "seeded=" .. tostring(seeded or 0))
            end
        end
    end
    NMVehicleRadial.installHook()
    if NMWalkmanWindow and NMWalkmanWindow.queuePersistedRestore then
        NMWalkmanWindow.queuePersistedRestore(0)
        if NMWalkmanWindow.restorePersistedStateForPlayer then
            NMWalkmanWindow.restorePersistedStateForPlayer(0)
        end
    end
    if NMDevicesClient.onGameStart then
        NMDevicesClient.onGameStart()
    end
    if NMClientWorldItemVisualSanitizer and NMClientWorldItemVisualSanitizer.onGameStart then
        NMClientWorldItemVisualSanitizer.onGameStart()
    end
    if NMClientInventoryItemVisualSanitizer and NMClientInventoryItemVisualSanitizer.onGameStart then
        NMClientInventoryItemVisualSanitizer.onGameStart()
    end
end

local function onObjectAdded(obj)
    if NMClientWorldItemVisualSanitizer and NMClientWorldItemVisualSanitizer.onObjectAdded then
        NMClientWorldItemVisualSanitizer.onObjectAdded(obj)
    end
end

if Events then
    if Events.OnFillInventoryObjectContextMenu then
        Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
    end
    if Events.OnFillWorldObjectContextMenu then
        Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
    end
    if Events.OnTick then
        Events.OnTick.Add(onTick)
    end
    if Events.OnServerCommand then
        Events.OnServerCommand.Add(onServerCommand)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(onGameStart)
    end
    if Events.OnObjectAdded then
        Events.OnObjectAdded.Add(onObjectAdded)
    end
end



