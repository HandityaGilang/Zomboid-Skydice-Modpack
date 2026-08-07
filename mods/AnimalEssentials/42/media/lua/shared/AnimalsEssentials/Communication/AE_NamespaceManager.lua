AE_NamespaceManager = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
AE_NamespaceManager.NAMESPACES = {
    KITTY = "KITTY_",           -- Cat mod exclusive
    AE_CORE = "AE_CORE_",       -- Framework core systems  
    AE_DATA = "AE_DATA_"        -- Framework data layer
}

-- Namespace permissions - which mods can access which namespaces
AE_NamespaceManager.PERMISSIONS = {
    ["AE_FrameworkData"] = {"AE_DATA", "AE_CORE"},  -- Data mod has full access
    ["AE_FrameworkCore"] = {"AE_CORE"},             -- Core mod limited to core namespace
    ["KittyMod"] = {"KITTY"},                       -- Cat mod limited to cat namespace
    ["GLOBAL"] = {"AE_DATA"}                        -- Global access for data layer only
}

-- Namespace validation and conflict prevention
function AE_NamespaceManager.validateKey(key, requiredNamespace, requestingMod)
    if not key or not requiredNamespace then
        print("[AE_NamespaceManager] ERROR: Missing key or namespace for validation")
        return false
    end
    
    -- Check if namespace exists
    local namespace = AE_NamespaceManager.NAMESPACES[requiredNamespace]
    if not namespace then
        print("[AE_NamespaceManager] ERROR: Unknown namespace: " .. requiredNamespace)
        return false
    end
    
    -- Validate key starts with correct namespace
    if string.find(key, namespace) ~= 1 then
        print("[AE_NamespaceManager] ERROR: Key '" .. key .. "' does not match namespace '" .. namespace .. "'")
        return false
    end
    
    -- Check mod permissions if provided
    if requestingMod then
        local permissions = AE_NamespaceManager.PERMISSIONS[requestingMod]
        if permissions then
            local hasPermission = false
            for _, allowedNamespace in ipairs(permissions) do
                if allowedNamespace == requiredNamespace then
                    hasPermission = true
                    break
                end
            end
            if not hasPermission then
                print("[AE_NamespaceManager] ERROR: Mod '" .. requestingMod .. "' lacks permission for namespace '" .. requiredNamespace .. "'")
                return false
            end
        end
    end
    
    return true
end

-- Safe ModData access with namespace validation
function AE_NamespaceManager.getModData(animal, key, namespace, requestingMod)
    -- Validate inputs with detailed error reporting
    if not animal then
        print("[AE_NamespaceManager] ERROR: Missing animal parameter for getModData")
        return nil
    end
    if not key then
        print("[AE_NamespaceManager] ERROR: Missing key parameter for getModData (animal: " .. tostring(animal:getID()) .. ")")
        return nil
    end
    if not namespace then
        print("[AE_NamespaceManager] ERROR: Missing namespace parameter for getModData (animal: " .. tostring(animal:getID()) .. ", key: " .. tostring(key) .. ")")
        return nil
    end
    
    -- Validate namespace permissions
    if not AE_NamespaceManager.validateKey(key, namespace, requestingMod) then
        return nil
    end
    
    -- Get ModData safely
    local success, result = pcall(function()
        return animal:getModData()[key]
    end)
    
    if not success then
        print("[AE_NamespaceManager] ERROR accessing ModData for key '" .. key .. "': " .. tostring(result))
        return nil
    end
    
    return result
end

-- Safe ModData setting with namespace validation
function AE_NamespaceManager.setModData(animal, key, value, namespace, requestingMod)
    -- Validate inputs with detailed error reporting
    if not animal then
        print("[AE_NamespaceManager] ERROR: Missing animal parameter for setModData")
        return false
    end
    if not key then
        print("[AE_NamespaceManager] ERROR: Missing key parameter for setModData (animal: " .. tostring(animal:getID()) .. ")")
        return false
    end
    if not namespace then
        print("[AE_NamespaceManager] ERROR: Missing namespace parameter for setModData (animal: " .. tostring(animal:getID()) .. ", key: " .. tostring(key) .. ", value: " .. tostring(value) .. ")")
        return false
    end
    
    -- Validate namespace permissions
    if not AE_NamespaceManager.validateKey(key, namespace, requestingMod) then
        return false
    end
    
    -- Set ModData safely
    local success, error = pcall(function()
        animal:getModData()[key] = value
    end)
    
    if not success then
        print("[AE_NamespaceManager] ERROR setting ModData for key '" .. key .. "': " .. tostring(error))
        return false
    end
    
    if AE_EnvironmentDetector.isSinglePlayer() then
        local transmitSuccess, transmitError = pcall(function()
            animal:transmitModData()
        end)
        if not transmitSuccess then
            print("[AE_NamespaceManager] WARNING: transmitModData failed for animal " .. tostring(animal:getID()) .. ": " .. tostring(transmitError))
        end
    else
        if not isClient() then
            local transmitSuccess, transmitError = pcall(function()
                animal:transmitModData()
            end)
            if not transmitSuccess then
                print("[AE_NamespaceManager] WARNING: transmitModData failed for animal " .. tostring(animal:getID()) .. ": " .. tostring(transmitError))
            end
        end
    end
    
    -- Fire update event if value changed
    if AE_EventRegistry then
        AE_EventRegistry.safeFireEvent("OnAE_StateUpdated", {
            animalID = animal:getID(),
            dataKey = key,
            namespace = namespace,
            requestingMod = requestingMod,
            timestamp = GameTime.getServerTimeMills()
        })
    end
    
    return true
end

-- Generate namespaced key from base key
function AE_NamespaceManager.generateKey(baseKey, namespace)
    if not baseKey or not namespace then
        return nil
    end
    
    local prefix = AE_NamespaceManager.NAMESPACES[namespace]
    if not prefix then
        print("[AE_NamespaceManager] ERROR: Unknown namespace for key generation: " .. namespace)
        return nil
    end
    
    return prefix .. baseKey
end

-- Extract namespace from key
function AE_NamespaceManager.extractNamespace(key)
    if not key then return nil end
    
    for namespaceName, prefix in pairs(AE_NamespaceManager.NAMESPACES) do
        if string.find(key, prefix) == 1 then
            return namespaceName
        end
    end
    
    return "UNKNOWN"
end

-- Check for namespace conflicts
function AE_NamespaceManager.checkConflicts(keys)
    local conflicts = {}
    local seenKeys = {}
    
    for _, key in ipairs(keys or {}) do
        if seenKeys[key] then
            table.insert(conflicts, key)
        else
            seenKeys[key] = true
        end
    end
    
    return conflicts
end

-- Migration helper for legacy keys
function AE_NamespaceManager.migrateKey(animal, oldKey, newKey, namespace)
    if not animal or not oldKey or not newKey then
        return false
    end
    
    local modData = animal:getModData()
    if modData[oldKey] ~= nil then
        -- Validate new key namespace
        if AE_NamespaceManager.validateKey(newKey, namespace) then
            modData[newKey] = modData[oldKey]
            modData[oldKey] = nil
            return true
        end
    end
    
    return false
end

-- Get all keys in a namespace
function AE_NamespaceManager.getKeysInNamespace(animal, namespace)
    if not animal or not namespace then
        return {}
    end
    
    local prefix = AE_NamespaceManager.NAMESPACES[namespace]
    if not prefix then
        return {}
    end
    
    local keys = {}
    local modData = animal:getModData()
    
    for key, value in pairs(modData) do
        if string.find(key, prefix) == 1 then
            table.insert(keys, key)
        end
    end
    
    return keys
end

-- Cleanup namespace (remove all keys in namespace)
function AE_NamespaceManager.cleanupNamespace(animal, namespace)
    if not animal or not namespace then
        return false
    end
    
    local keys = AE_NamespaceManager.getKeysInNamespace(animal, namespace)
    local modData = animal:getModData()
    
    for _, key in ipairs(keys) do
        modData[key] = nil
    end
    
    return #keys > 0
end

-- Validate all namespaces for consistency
function AE_NamespaceManager.validateAllNamespaces()
    local issues = {}
    
    -- Check for duplicate prefixes
    local prefixes = {}
    for namespace, prefix in pairs(AE_NamespaceManager.NAMESPACES) do
        if prefixes[prefix] then
            table.insert(issues, "Duplicate prefix '" .. prefix .. "' for namespaces: " .. prefixes[prefix] .. ", " .. namespace)
        else
            prefixes[prefix] = namespace
        end
    end
    
    -- Check permissions reference valid namespaces
    for mod, permissions in pairs(AE_NamespaceManager.PERMISSIONS) do
        for _, permission in ipairs(permissions) do
            if not AE_NamespaceManager.NAMESPACES[permission] then
                table.insert(issues, "Mod '" .. mod .. "' has permission for unknown namespace: " .. permission)
            end
        end
    end
    
    if #issues > 0 then
        print("[AE_NamespaceManager] VALIDATION ISSUES:")
        for _, issue in ipairs(issues) do
            print("  - " .. issue)
        end
        return false
    end
    
    return true
end

-- Initialize namespace manager
function AE_NamespaceManager.initialize()
    if not AE_NamespaceManager.validateAllNamespaces() then
        print("[AE_NamespaceManager] CRITICAL: Namespace validation failed!")
        return false
    end
    
    print("[AE_NamespaceManager] Namespace manager initialized with " .. 
          AE_NamespaceManager.getNamespaceCount() .. " namespaces")
    
    -- Fire initialization event with sequence counter (MP-safe)
    if AE_EventRegistry then
        -- Global initialization sequence counter
        if not _G.AE_InitSequence then _G.AE_InitSequence = 0 end
        _G.AE_InitSequence = _G.AE_InitSequence + 1
        
        AE_EventRegistry.safeFireEvent("OnAE_SystemInitialized", {
            module = "AE_NamespaceManager",
            namespacesRegistered = AE_NamespaceManager.getNamespaceCount(),
            initSequence = _G.AE_InitSequence
        })
    end
    
    return true
end

-- Get namespace count
function AE_NamespaceManager.getNamespaceCount()
    local count = 0
    for _ in pairs(AE_NamespaceManager.NAMESPACES) do
        count = count + 1
    end
    return count
end

-- Export for global access
_G.AE_NamespaceManager = AE_NamespaceManager

return AE_NamespaceManager