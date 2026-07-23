require "zombies/NMZombieLiveStrategy"
require "zombies/NMZombieAttachedDefinitions"
require "zombies/NMZombieAudioVisualSupport"
require "zombies/NMZombieVisualTargetContract"
require "zombies/NMZombieVisualTargetLedger"
require "audio/NMZombieAttraction"
require "death/NMServerZombieCorpseCarry"
require "zombies/NMServerMPZombieVisualAttach"
require "zombies/NMServerMPZombieAssignmentFlow"
require "zombies/NMServerZombieVisualTargetPublisher"
require "zombies/NMServerSPZombieAssignmentFlow"

-- Thin server bootstrap that wires engine events to modular handlers.
NMDevicesServer = NMDevicesServer or {}

local function canRunAuthoritativeWorldMutation()
    if NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() == true then
        return false
    end
    if NMAuthorityContract and NMAuthorityContract.canMutateDurableStateAtRuntime then
        return NMAuthorityContract.canMutateDurableStateAtRuntime() == true
    end
    return true
end

local function applyDefaultDebugDefaults()
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

local function logServerDebugBootstrap(stage)
    local preset = NMRuntimeConfig and NMRuntimeConfig.getBootDebugPreset and tostring(NMRuntimeConfig.getBootDebugPreset() or "") or ""
    local master = NMRuntimeConfig and NMRuntimeConfig.getDebugMasterEnabled and NMRuntimeConfig.getDebugMasterEnabled() == true or false
    if not master then
        return
    end
    local knobs = NMRuntimeConfig and NMRuntimeConfig.getDebugKnobsSnapshot and NMRuntimeConfig.getDebugKnobsSnapshot() or {}
    print(string.format(
        "[NewMusic] [DebugBootstrap] side=server stage=%s preset=%s master=%s knobs=core:%s,intent:%s,state:%s,emitter:%s,runtimeProbe:%s,transitionProbe:%s,registry:%s,progressionProbe:%s,lootDiagnostics:%s,zombieDiagnostics:%s,portableUiProbe:%s",
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
        tostring(knobs.portableUiProbe == true)
    ))
end

local function isMultiplayerRuntime()
    return NMCore and NMCore.isMultiplayerMode and NMCore.isMultiplayerMode() == true
end

local function getActiveZombieExecutor()
    local strategy = NMZombieLiveStrategy and NMZombieLiveStrategy.getLiveVisualStrategy and NMZombieLiveStrategy.getLiveVisualStrategy() or ""
    if strategy == "sp_runtime_attach" then
        return NMServerSPZombieAssignmentFlow
    end
    if strategy == "mp_runtime_attach_with_support" then
        return NMServerMPZombieVisualAttach
    end
    if strategy == "mp_assignment_flow" then
        return NMServerMPZombieAssignmentFlow
    end
    return nil
end

local function shouldRunTargetPublisher()
    return canRunAuthoritativeWorldMutation()
        and isMultiplayerRuntime()
        and NMServerZombieVisualTargetPublisher
        and NMServerZombieVisualTargetPublisher.onTick
end

local function onClientCommand(module, command, player, args)
    if NMServerIntentRouter and NMServerIntentRouter.onClientCommand then
        NMServerIntentRouter.onClientCommand(module, command, player, args)
    end
    if type(NMDevicesServer) == "table" and NMDevicesServer.onClientCommand then
        NMDevicesServer.onClientCommand(module, command, player, args)
    end
end

local function onTick()
    if NMServerVehicleTrackSchedulerTick and NMServerVehicleTrackSchedulerTick.onTick then
        NMServerVehicleTrackSchedulerTick.onTick()
    end
    if NMServerSourceRefreshTick and NMServerSourceRefreshTick.onTick then
        NMServerSourceRefreshTick.onTick()
    end
    if NMServerModeReconcile and NMServerModeReconcile.onTick then
        NMServerModeReconcile.onTick()
    end
    if NMServerZombiePulseTick and NMServerZombiePulseTick.onTick then
        NMServerZombiePulseTick.onTick()
    end
    if NMServerZombieCorpseCarry and NMServerZombieCorpseCarry.onTick and canRunAuthoritativeWorldMutation() then
        NMServerZombieCorpseCarry.onTick()
    end
    local activeZombieExecutor = getActiveZombieExecutor()
    if activeZombieExecutor and activeZombieExecutor.onTick and canRunAuthoritativeWorldMutation() then
        activeZombieExecutor.onTick()
    end
    if shouldRunTargetPublisher() then
        NMServerZombieVisualTargetPublisher.onTick()
    end
    if NMServerRegistryTick and NMServerRegistryTick.onTick then
        NMServerRegistryTick.onTick()
    end
    if type(NMDevicesServer) == "table" and NMDevicesServer.onTick then
        NMDevicesServer.onTick()
    end
end

local function onEveryOneMinute()
    if NMServerVehiclePowerTick and NMServerVehiclePowerTick.onEveryOneMinute then
        NMServerVehiclePowerTick.onEveryOneMinute()
    end
    if NMServerItemPowerTick and NMServerItemPowerTick.onEveryOneMinute then
        NMServerItemPowerTick.onEveryOneMinute()
    end
    if type(NMDevicesServer) == "table" and NMDevicesServer.onEveryOneMinute then
        NMDevicesServer.onEveryOneMinute()
    end
end

local function shouldLogProofVerbose()
    return NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("zombieDiagnostics") == true
end

if NMCore and NMCore.logChannel then
    applyDefaultDebugDefaults()
    logServerDebugBootstrap("bootstrap")
    NMCore.logChannel(
        "zombieDiagnostics",
        "server_boot",
        string.format(
            "authority=%s canMutate=%s preset=%s liveStrategy=%s",
            tostring(NMCore.getRuntimeAuthorityMode and NMCore.getRuntimeAuthorityMode() or "unknown"),
            tostring(canRunAuthoritativeWorldMutation()),
            tostring(NMRuntimeConfig and NMRuntimeConfig.getBootDebugPreset and NMRuntimeConfig.getBootDebugPreset() or ""),
            tostring(NMZombieLiveStrategy and NMZombieLiveStrategy.getLiveVisualStrategy and NMZombieLiveStrategy.getLiveVisualStrategy() or "unknown")
        )
    )
    if NMServerBootReset and NMServerBootReset.initSession then
        NMServerBootReset.initSession()
    end
end

if Events then
    if Events.OnClientCommand and Events.OnClientCommand.Add then
        Events.OnClientCommand.Add(onClientCommand)
    end
    if Events.OnTick and Events.OnTick.Add then
        Events.OnTick.Add(onTick)
    end
    if Events.EveryOneMinute and Events.EveryOneMinute.Add then
        Events.EveryOneMinute.Add(onEveryOneMinute)
    end
    if Events.OnZombieDead and Events.OnZombieDead.Add and canRunAuthoritativeWorldMutation() then
        if NMServerZombieCorpseCarry and NMServerZombieCorpseCarry.onZombieDead then
            Events.OnZombieDead.Add(NMServerZombieCorpseCarry.onZombieDead)
            if NMCore and NMCore.logChannel and shouldLogProofVerbose() then
                NMCore.logChannel("zombieDiagnostics", "hook_on_zombie_dead_registered", "handler=NMServerZombieCorpseCarry.onZombieDead")
            end
        end
    end
    if Events.OnDeadBodySpawn and Events.OnDeadBodySpawn.Add and canRunAuthoritativeWorldMutation() then
        if NMServerZombieCorpseCarry and NMServerZombieCorpseCarry.onDeadBodySpawn then
            Events.OnDeadBodySpawn.Add(NMServerZombieCorpseCarry.onDeadBodySpawn)
            if NMCore and NMCore.logChannel and shouldLogProofVerbose() then
                NMCore.logChannel("zombieDiagnostics", "hook_on_dead_body_spawn_registered", "handler=NMServerZombieCorpseCarry.onDeadBodySpawn")
            end
        end
    end
    if Events.OnZombieUpdate and Events.OnZombieUpdate.Add and canRunAuthoritativeWorldMutation() then
        local registeredAny = false
        local activeZombieExecutor = getActiveZombieExecutor()
        if activeZombieExecutor and activeZombieExecutor.onZombieUpdate then
            Events.OnZombieUpdate.Add(activeZombieExecutor.onZombieUpdate)
            registeredAny = true
        end
        if registeredAny then
            if NMCore and NMCore.logChannel then
                NMCore.logChannel(
                    "zombieDiagnostics",
                    "hook_registered",
                    "event=OnZombieUpdate strategy=" .. tostring(NMZombieLiveStrategy and NMZombieLiveStrategy.getLiveVisualStrategy and NMZombieLiveStrategy.getLiveVisualStrategy() or "unknown")
                )
            end
        elseif NMCore and NMCore.logChannel and shouldLogProofVerbose() then
            NMCore.logChannel("zombieDiagnostics", "hook_missing", "event=OnZombieUpdate")
        end
    elseif canRunAuthoritativeWorldMutation() then
        if NMCore and NMCore.logChannel and shouldLogProofVerbose() then
            NMCore.logChannel("zombieDiagnostics", "hook_missing", "event=OnZombieUpdate")
        end
    end
end



