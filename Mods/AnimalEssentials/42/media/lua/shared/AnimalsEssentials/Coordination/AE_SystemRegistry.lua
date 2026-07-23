local AE_InitializationCoordinator = require("AnimalsEssentials/Coordination/AE_InitializationCoordinator")

local AE_NamespaceManager = require("AnimalsEssentials/Communication/AE_NamespaceManager")
local AE_ModDataManager = require("AnimalsEssentials/DataServices/AE_ModDataManager")
local AE_CoreCommunication = require("AnimalsEssentials/Communication/AE_CoreCommunication")
local AE_AnimalRegistry = require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
local AE_ModDetection = require("AnimalsEssentials/Foundation/AE_ModDetection")
local AE_GracefulDegradation = require("AnimalsEssentials/Foundation/AE_GracefulDegradation")

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

local function registerPhase1Systems()
    AE_InitializationCoordinator.registerSystem(
        1,
        "AE_NamespaceManager",
        AE_NamespaceManager.initialize,
        {}
    )

    AE_InitializationCoordinator.registerSystem(
        1,
        "AE_ModDataManager",
        AE_ModDataManager.initialize,
        {}
    )

    AE_InitializationCoordinator.registerSystem(
        1,
        "AE_CoreCommunication",
        AE_CoreCommunication.initialize,
        {}
    )

    local AE_PersistentAnimalData = _G.AE_PersistentAnimalData
    if AE_PersistentAnimalData and AE_PersistentAnimalData.initialize then
        AE_InitializationCoordinator.registerSystem(
            1,
            "AE_PersistentAnimalData",
            AE_PersistentAnimalData.initialize,
            {"AE_ModDataManager"}
        )
    end

    local AE_ServerDataHandler = _G.AE_ServerDataHandler
    if AE_ServerDataHandler and AE_ServerDataHandler.initialize then
        AE_InitializationCoordinator.registerSystem(
            1,
            "AE_ServerDataHandler",
            AE_ServerDataHandler.initialize,
            {"AE_ModDataManager"}
        )
    end
end

local function registerPhase2Systems()
    AE_InitializationCoordinator.registerSystem(
        2,
        "AE_ModDetection",
        AE_ModDetection.initialize,
        {"AE_ModDataManager"}
    )

    AE_InitializationCoordinator.registerSystem(
        2,
        "AE_GracefulDegradation",
        AE_GracefulDegradation.initialize,
        {"AE_ModDetection"}
    )
end

local function registerPhase3Systems()
    AE_InitializationCoordinator.registerSystem(
        3,
        "AE_AnimalRegistry",
        AE_AnimalRegistry.initialize,
        {"AE_ModDataManager", "AE_NamespaceManager"}
    )

    local AE_BehaviorManager = _G.AE_BehaviorManager
    if AE_BehaviorManager and AE_BehaviorManager.initialize then
        AE_InitializationCoordinator.registerSystem(
            3,
            "AE_BehaviorManager",
            AE_BehaviorManager.initialize,
            {"AE_AnimalRegistry"}
        )
    end

    local AE_UnifiedStateTracker = _G.AE_UnifiedStateTracker
    if AE_UnifiedStateTracker and AE_UnifiedStateTracker.initialize then
        AE_InitializationCoordinator.registerSystem(
            3,
            "AE_UnifiedStateTracker",
            AE_UnifiedStateTracker.initialize,
            {"AE_AnimalRegistry", "AE_ModDataManager"}
        )
    end
end

local function registerPhase4Systems()
    local AE_ZoneSpawningCore = _G.AE_ZoneSpawningCore
    if AE_ZoneSpawningCore and AE_ZoneSpawningCore.initialize then
        AE_InitializationCoordinator.registerSystem(
            4,
            "AE_ZoneSpawningCore",
            AE_ZoneSpawningCore.initialize,
            {"AE_AnimalRegistry", "AE_BehaviorManager", "AE_ModDataManager"}
        )
    end

    local AE_ZoneSpawningSystem = _G.AE_ZoneSpawningSystem
    if AE_ZoneSpawningSystem and AE_ZoneSpawningSystem.Initialize then
        AE_InitializationCoordinator.registerSystem(
            4,
            "AE_ZoneSpawningSystem",
            AE_ZoneSpawningSystem.Initialize,
            {"AE_AnimalRegistry", "AE_ZoneSpawningCore"}
        )
    end

    local AE_PickupDropDetector = _G.AE_PickupDropDetector
    if AE_PickupDropDetector and AE_PickupDropDetector.initialize then
        AE_InitializationCoordinator.registerSystem(
            4,
            "AE_PickupDropDetector",
            AE_PickupDropDetector.initialize,
            {"AE_ModDataManager"}
        )
    end

    local AE_TimedActionServerHandler = _G.AE_TimedActionServerHandler
    if AE_TimedActionServerHandler and AE_TimedActionServerHandler.initialize then
        AE_InitializationCoordinator.registerSystem(
            4,
            "AE_TimedActionServerHandler",
            AE_TimedActionServerHandler.initialize,
            {"AE_PickupDropDetector"}
        )
    end

    local AE_TimedActionDetector = _G.AE_TimedActionDetector
    if AE_TimedActionDetector and AE_TimedActionDetector.initialize then
        AE_InitializationCoordinator.registerSystem(
            4,
            "AE_TimedActionDetector",
            AE_TimedActionDetector.initialize,
            {"AE_PickupDropDetector"}
        )
    end

    local AE_PickupDropPerformanceMonitor = _G.AE_PickupDropPerformanceMonitor
    if AE_PickupDropPerformanceMonitor and AE_PickupDropPerformanceMonitor.initialize then
        AE_InitializationCoordinator.registerSystem(
            4,
            "AE_PickupDropPerformanceMonitor",
            AE_PickupDropPerformanceMonitor.initialize,
            {"AE_PickupDropDetector"}
        )
    end

    local AE_DefensiveArchitectureCoordinator = _G.AE_DefensiveArchitectureCoordinator
    if AE_DefensiveArchitectureCoordinator and AE_DefensiveArchitectureCoordinator.initialize then
        AE_InitializationCoordinator.registerSystem(
            4,
            "AE_DefensiveArchitectureCoordinator",
            AE_DefensiveArchitectureCoordinator.initialize,
            {"AE_AnimalRegistry", "AE_BehaviorManager"}
        )
    end

    local AE_FrameworkBridge = _G.AE_FrameworkBridge
    if AE_FrameworkBridge and AE_FrameworkBridge.initialize then
        AE_InitializationCoordinator.registerSystem(
            4,
            "AE_FrameworkBridge",
            AE_FrameworkBridge.initialize,
            {"AE_AnimalRegistry", "AE_BehaviorManager"}
        )
    end
end

local function registerPhase5Systems()
    local AE_DataCleanupCoordinator = _G.AE_DataCleanupCoordinator
    if AE_DataCleanupCoordinator and AE_DataCleanupCoordinator.initialize then
        AE_InitializationCoordinator.registerSystem(
            5,
            "AE_DataCleanupCoordinator",
            AE_DataCleanupCoordinator.initialize,
            {"AE_ModDataManager", "AE_AnimalRegistry"}
        )
    end

    local AE_LightweightCleanupCoordinator = _G.AE_LightweightCleanupCoordinator
    if AE_LightweightCleanupCoordinator and AE_LightweightCleanupCoordinator.initialize then
        AE_InitializationCoordinator.registerSystem(
            5,
            "AE_LightweightCleanupCoordinator",
            AE_LightweightCleanupCoordinator.initialize,
            {"AE_DataCleanupCoordinator"}
        )
    end

    local AE_UIHealthCoordinator = _G.AE_UIHealthCoordinator
    if AE_UIHealthCoordinator and AE_UIHealthCoordinator.initialize then
        AE_InitializationCoordinator.registerSystem(
            5,
            "AE_UIHealthCoordinator",
            AE_UIHealthCoordinator.initialize,
            {"AE_AnimalRegistry"}
        )
    end
end

local function registerPhase6Systems()
    local AE_ContextMenuIntegration = _G.AE_ContextMenuIntegration
    if AE_ContextMenuIntegration and AE_ContextMenuIntegration.initialize then
        AE_InitializationCoordinator.registerSystem(
            6,
            "AE_ContextMenuIntegration",
            AE_ContextMenuIntegration.initialize,
            {"AE_AnimalRegistry"}
        )
    end

    local AE_UIEventCoordinator = _G.AE_UIEventCoordinator
    if AE_UIEventCoordinator and AE_UIEventCoordinator.initialize then
        AE_InitializationCoordinator.registerSystem(
            6,
            "AE_UIEventCoordinator",
            AE_UIEventCoordinator.initialize,
            {}
        )
    end

    local AE_UIPerformanceOptimizer = _G.AE_UIPerformanceOptimizer
    if AE_UIPerformanceOptimizer and AE_UIPerformanceOptimizer.initialize then
        AE_InitializationCoordinator.registerSystem(
            6,
            "AE_UIPerformanceOptimizer",
            AE_UIPerformanceOptimizer.initialize,
            {"AE_UIEventCoordinator"}
        )
    end

    local AE_UIArchitectureValidator = _G.AE_UIArchitectureValidator
    if AE_UIArchitectureValidator and AE_UIArchitectureValidator.initialize then
        AE_InitializationCoordinator.registerSystem(
            6,
            "AE_UIArchitectureValidator",
            AE_UIArchitectureValidator.initialize,
            {}
        )
    end

    local AE_UITestingFramework = _G.AE_UITestingFramework
    if AE_UITestingFramework and AE_UITestingFramework.initialize then
        AE_InitializationCoordinator.registerSystem(
            6,
            "AE_UITestingFramework",
            AE_UITestingFramework.initialize,
            {"AE_UIEventCoordinator", "AE_UIPerformanceOptimizer", "AE_UIArchitectureValidator"}
        )
    end

    local AE_UICommunication = _G.AE_UICommunication
    if AE_UICommunication and AE_UICommunication.initialize then
        AE_InitializationCoordinator.registerSystem(
            6,
            "AE_UICommunication",
            AE_UICommunication.initialize,
            {"AE_CoreCommunication"}
        )
    end
end

local function registerAllSystems()
    registerPhase1Systems()
    registerPhase2Systems()
    registerPhase3Systems()
    registerPhase4Systems()
    registerPhase5Systems()
    registerPhase6Systems()

    print("[AE_SystemRegistry] System registration complete")
end

registerAllSystems()

return true
