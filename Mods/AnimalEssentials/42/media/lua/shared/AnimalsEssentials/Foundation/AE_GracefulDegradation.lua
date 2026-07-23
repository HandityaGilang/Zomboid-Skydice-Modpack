AE_GracefulDegradation = {}

AE_GracefulDegradation.STRATEGIES = {
    ["AE_FrameworkCore"] = {
        description = "Framework Core mod missing",
        fallbackMode = "minimal",
        disabledFeatures = {"commands", "behavior", "UI"},
        alternativeMessage = "Animal framework core not available. Basic data management only."
    },
    ["KittyMod"] = {
        description = "KittyMod not available", 
        fallbackMode = "framework_only",
        disabledFeatures = {"cat_specific"},
        alternativeMessage = "Cat mod not loaded. Framework available for other animal types."
    }
}

AE_GracefulDegradation.degradationState = {
    active = false,
    missingMods = {},
    disabledFeatures = {},
    fallbackMode = "normal"
}

AE_GracefulDegradation.featureAvailability = {
    commands = true,
    behavior = true,
    UI = true,
    taming = true,
    cat_specific = true,
    data_management = true
}

function AE_GracefulDegradation.evaluateDegradation(detectionResults)
    local missingMods = {}
    local disabledFeatures = {}
    
    for modName, detected in pairs(detectionResults) do
        if not detected and AE_GracefulDegradation.STRATEGIES[modName] then
            table.insert(missingMods, modName)
            local strategy = AE_GracefulDegradation.STRATEGIES[modName]
            
            for _, feature in ipairs(strategy.disabledFeatures) do
                if not disabledFeatures[feature] then
                    disabledFeatures[feature] = {}
                end
                table.insert(disabledFeatures[feature], modName)
                AE_GracefulDegradation.featureAvailability[feature] = false
            end
        end
    end
    
    AE_GracefulDegradation.degradationState = {
        active = #missingMods > 0,
        missingMods = missingMods,
        disabledFeatures = disabledFeatures,
        fallbackMode = AE_GracefulDegradation.determineFallbackMode(missingMods)
    }
    
    if AE_GracefulDegradation.degradationState.active then
        print("[AE_GracefulDegradation] Graceful degradation activated")
        print("[AE_GracefulDegradation] Missing mods: " .. table.concat(missingMods, ", "))
        print("[AE_GracefulDegradation] Fallback mode: " .. AE_GracefulDegradation.degradationState.fallbackMode)
        
        if AE_EventRegistry then
            AE_EventRegistry.safeFireEvent("OnAE_GracefulDegradation", {
                missingMods = missingMods,
                disabledFeatures = disabledFeatures,
                fallbackMode = AE_GracefulDegradation.degradationState.fallbackMode,
                timestamp = GameTime.getServerTimeMills()
            })
        end
    else
        print("[AE_GracefulDegradation] All mods available - no degradation needed")
    end
end

function AE_GracefulDegradation.determineFallbackMode(missingMods)
    if not missingMods or #missingMods == 0 then
        return "normal"
    end
    
    local hasCoreFramework = true
    local hasSpecificMods = false
    
    for _, modName in ipairs(missingMods) do
        if modName == "AE_FrameworkCore" then
            hasCoreFramework = false
        else
            hasSpecificMods = true
        end
    end
    
    if not hasCoreFramework then
        return "minimal"
    elseif hasSpecificMods then
        return "framework_only"
    end
    
    return "normal"
end

function AE_GracefulDegradation.isFeatureAvailable(feature)
    return AE_GracefulDegradation.featureAvailability[feature] == true
end

function AE_GracefulDegradation.getAlternativeAction(feature)
    if AE_GracefulDegradation.isFeatureAvailable(feature) then
        return nil
    end
    
    local alternatives = {
        commands = "Use direct animal interaction instead of command system",
        behavior = "Animals will use default game behavior",
        UI = "Use vanilla game interfaces for animal management", 
        taming = "Basic taming through feeding only",
        cat_specific = "Generic animal framework available for other types"
    }
    
    return alternatives[feature] or "Feature not available in current configuration"
end

function AE_GracefulDegradation.executeWithFallback(featureName, primaryFunction, fallbackFunction, ...)
    if AE_GracefulDegradation.isFeatureAvailable(featureName) then
        local success, result = pcall(primaryFunction, ...)
        if success then
            return result
        else
            print("[AE_GracefulDegradation] Primary function failed for " .. featureName .. ": " .. tostring(result))
        end
    end
    
    if fallbackFunction then
        local success, result = pcall(fallbackFunction, ...)
        if success then
            return result
        else
            print("[AE_GracefulDegradation] Fallback function failed for " .. featureName .. ": " .. tostring(result))
        end
    end
    
    print("[AE_GracefulDegradation] No fallback available for " .. featureName)
    return nil
end

function AE_GracefulDegradation.getUserMessage(feature)
    if AE_GracefulDegradation.isFeatureAvailable(feature) then
        return nil
    end
    
    local disabledBy = AE_GracefulDegradation.degradationState.disabledFeatures[feature]
    if disabledBy and #disabledBy > 0 then
        local modName = disabledBy[1]
        local strategy = AE_GracefulDegradation.STRATEGIES[modName]
        if strategy then
            return strategy.alternativeMessage
        end
    end
    
    return "This feature is not available with the current mod configuration."
end

function AE_GracefulDegradation.getStatus()
    return {
        active = AE_GracefulDegradation.degradationState.active,
        fallbackMode = AE_GracefulDegradation.degradationState.fallbackMode,
        missingMods = AE_GracefulDegradation.degradationState.missingMods,
        availableFeatures = AE_GracefulDegradation.getAvailableFeatures()
    }
end

function AE_GracefulDegradation.getAvailableFeatures()
    local available = {}
    for feature, isAvailable in pairs(AE_GracefulDegradation.featureAvailability) do
        if isAvailable then
            table.insert(available, feature)
        end
    end
    return available
end

function AE_GracefulDegradation.subscribeToModDetection()
    if AE_EventRegistry and AE_EventRegistry.subscribeEvent then
        AE_EventRegistry.subscribeEvent("OnAE_ModRegistration", function(data)
            if data and data.detectedMods then
                AE_GracefulDegradation.evaluateDegradation(data.detectedMods)
            end
        end)
    end
end

function AE_GracefulDegradation.initialize()
    print("[AE_GracefulDegradation] Initializing graceful degradation system...")
    
    AE_GracefulDegradation.subscribeToModDetection()
    
    if AE_ModDetection and AE_ModDetection.detectionComplete then
        AE_GracefulDegradation.evaluateDegradation(AE_ModDetection.detectionResults)
    end
    
    print("[AE_GracefulDegradation] Graceful degradation system initialized")
end

_G.AE_GracefulDegradation = AE_GracefulDegradation

return AE_GracefulDegradation