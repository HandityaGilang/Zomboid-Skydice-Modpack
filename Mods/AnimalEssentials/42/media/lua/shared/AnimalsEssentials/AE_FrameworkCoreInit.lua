local AE_FrameworkCoreInit = {}

AE_FrameworkCoreInit.isInitialized = false

function AE_FrameworkCoreInit.initialize()
    if AE_FrameworkCoreInit.isInitialized then
        return
    end

    local coordinatorSuccess, AE_InitializationCoordinator = pcall(function()
        return require("AnimalsEssentials/Coordination/AE_InitializationCoordinator")
    end)

    if not coordinatorSuccess then
        print("[AE_FrameworkCoreInit] CRITICAL: Failed to load AE_InitializationCoordinator: " .. tostring(AE_InitializationCoordinator))
        return false
    end

    local registrySuccess, registryError = pcall(function()
        return require("AnimalsEssentials/Coordination/AE_SystemRegistry")
    end)

    if not registrySuccess then
        print("[AE_FrameworkCoreInit] CRITICAL: Failed to load AE_SystemRegistry: " .. tostring(registryError))
        return false
    end

    print("[AE_FrameworkCoreInit] New phased initialization system loaded successfully")
    print("[AE_FrameworkCoreInit] Waiting for OnPlayerMove to trigger initialization...")

    AE_FrameworkCoreInit.isInitialized = true
    return true
end

function AE_FrameworkCoreInit.getStatus()
    local coordinatorStatus = nil

    if _G.AE_InitializationCoordinator and _G.AE_InitializationCoordinator.getStatus then
        coordinatorStatus = _G.AE_InitializationCoordinator.getStatus()
    end

    return {
        initialized = AE_FrameworkCoreInit.isInitialized,
        coordinatorStatus = coordinatorStatus,
        timestamp = getTimestamp()
    }
end

Events.OnGameBoot.Add(AE_FrameworkCoreInit.initialize)

return AE_FrameworkCoreInit
