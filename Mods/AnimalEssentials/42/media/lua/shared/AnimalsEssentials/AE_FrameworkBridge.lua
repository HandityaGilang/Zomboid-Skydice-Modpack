-- AE_FrameworkBridge.lua
-- Framework Detection and Integration Bridge for External Mods
-- DEFENSIVE ARCHITECTURE: Dormant by default, reactive only

local AE_FrameworkBridge = {}

-- Framework availability and version information
AE_FrameworkBridge.version = "1.0"
AE_FrameworkBridge.isInitialized = false

-- Supported framework features
local frameworkFeatures = {
    "dataService",
    "uiCoordination", 
    "eventSystem",
    "animalRegistry",
    "behaviorManager",
    "crossModIntegration"
}

-- Framework component availability tracking
local componentStatus = {
    dataService = nil,
    uiEventCoordinator = nil,
    eventCoordinator = nil,
    animalRegistry = nil,
    behaviorManager = nil
}

-- Initialize framework bridge (defensive pattern)
function AE_FrameworkBridge.initialize()
    if AE_FrameworkBridge.isInitialized then
        return true
    end
    
    -- Detect core framework components
    AE_FrameworkBridge.detectComponents()
    AE_FrameworkBridge.isInitialized = true
    return true
end

-- Detect available framework components (defensive loading)
function AE_FrameworkBridge.detectComponents()
    -- Detect AE_DataService
    local dataServiceSuccess, dataService = pcall(function()
        return require("AnimalsEssentials/DataServices/AE_DataService")
    end)
    componentStatus.dataService = dataServiceSuccess and dataService or nil
    
    -- Detect AE_UIEventCoordinator
    local uiCoordinatorSuccess, uiCoordinator = pcall(function()
        return require("AnimalsEssentials/UI/AE_UIEventCoordinator")
    end)
    componentStatus.uiEventCoordinator = uiCoordinatorSuccess and uiCoordinator or nil
    
    -- Detect AE_AnimalRegistry
    local registrySuccess, registry = pcall(function()
        return require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
    end)
    componentStatus.animalRegistry = registrySuccess and registry or nil
    
    -- Detect AE_BehaviorManager
    local behaviorSuccess, behavior = pcall(function()
        return require("AnimalsEssentials/CoreSystems/AE_BehaviorManager")
    end)
    componentStatus.behaviorManager = behaviorSuccess and behavior or nil
end

-- Primary framework availability check (called by external mods)
function AE_FrameworkBridge.isAvailable()
    if not AE_FrameworkBridge.isInitialized then
        AE_FrameworkBridge.initialize()
    end
    
    -- Framework is available if core components are functional
    return componentStatus.dataService ~= nil and 
           componentStatus.uiEventCoordinator ~= nil
end

-- Get framework version information
function AE_FrameworkBridge.getVersion()
    return AE_FrameworkBridge.version
end

-- Get supported framework features
function AE_FrameworkBridge.getFeatures()
    return frameworkFeatures
end

-- Get component availability status
function AE_FrameworkBridge.getComponentStatus()
    if not AE_FrameworkBridge.isInitialized then
        AE_FrameworkBridge.initialize()
    end
    
    local status = {}
    for component, instance in pairs(componentStatus) do
        status[component] = instance ~= nil
    end
    return status
end

-- Get specific framework component (defensive access)
function AE_FrameworkBridge.getComponent(componentName)
    if not AE_FrameworkBridge.isInitialized then
        AE_FrameworkBridge.initialize()
    end
    
    return componentStatus[componentName]
end

-- Validate framework integration capabilities
function AE_FrameworkBridge.validateIntegration(requiredFeatures)
    if not AE_FrameworkBridge.isAvailable() then
        return false, "Framework not available"
    end
    
    if not requiredFeatures then
        return true, "No specific requirements"
    end
    
    local missing = {}
    for _, feature in ipairs(requiredFeatures) do
        local featureAvailable = false
        for _, supportedFeature in ipairs(frameworkFeatures) do
            if feature == supportedFeature then
                featureAvailable = true
                break
            end
        end
        if not featureAvailable then
            table.insert(missing, feature)
        end
    end
    
    if #missing > 0 then
        return false, "Missing features: " .. table.concat(missing, ", ")
    end
    
    return true, "All required features available"
end

-- Framework compatibility check for external mods
function AE_FrameworkBridge.checkCompatibility(modName, requiredVersion, requiredFeatures)
    if not modName then
        return false, "Mod name required"
    end
    
    if not AE_FrameworkBridge.isAvailable() then
        return false, "AE Framework not available"
    end
    
    -- Version compatibility (simple string comparison for now)
    if requiredVersion and requiredVersion ~= AE_FrameworkBridge.version then
        return false, "Version mismatch: required " .. requiredVersion .. ", available " .. AE_FrameworkBridge.version
    end
    
    -- Feature compatibility
    local integrationValid, integrationMessage = AE_FrameworkBridge.validateIntegration(requiredFeatures)
    if not integrationValid then
        return false, integrationMessage
    end
    
    return true, "Compatible with AE Framework"
end

return AE_FrameworkBridge