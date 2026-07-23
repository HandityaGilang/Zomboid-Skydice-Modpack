local AE_DataConfig = {}


AE_DataConfig.NAMESPACES = {
    KITTY = "KITTY_",
    AE_CORE = "AE_CORE_",  
    AE_DATA = "AE_DATA_"
}

AE_DataConfig.ModDataKeys = {
    Tameness = "AE_DATA_Tameness",
    IsTamed = "AE_DATA_IsTamed",
    Owner = "AE_DATA_Owner",
    AnimalName = "AE_DATA_AnimalName",
    StableID = "AE_DATA_StableID",
    SlotAssigned = "AE_DATA_SlotAssigned",
    LastFollowUpdate = "AE_DATA_LastFollowUpdate",

    CustomHunger = "AE_DATA_CustomHunger",
    CustomThirst = "AE_DATA_CustomThirst",
    LastHungerUpdate = "AE_DATA_LastHungerUpdate",

    Friendliness = "AE_DATA_Friendliness",

    RemainingLives = "AE_DATA_RemainingLives",

    EquippedItems = "AE_CORE_EquippedItems",

 
    HasBag = "AE_CORE_HasBag",
    BagInventory = "AE_CORE_BagInventory",

    CurrentCommand = "AE_CORE_CurrentCommand",
    CommandMode = "AE_CORE_CommandMode",

    BehaviorState = "AE_CORE_BehaviorState",
    LastPosition = "AE_CORE_LastPosition",

    Health = "AE_DATA_Health",
    Hunger = "AE_DATA_Hunger",
    Thirst = "AE_DATA_Thirst",

    Attachments = "AE_CORE_Attachments",

    Breed = "AE_DATA_Breed",
    Genetics = "AE_DATA_Genetics",

    IsFrameworkAnimal = "AE_DATA_IsFrameworkAnimal",
    AnimalType = "AE_DATA_AnimalType",
    
    LastSeenX = "AE_DATA_LastSeenX",
    LastSeenY = "AE_DATA_LastSeenY", 
    LastSeenZ = "AE_DATA_LastSeenZ",
    LastSeenTime = "AE_DATA_LastSeenTime",
    LastDistanceCheck = "AE_DATA_LastDistanceCheck",
    CachedHealth = "AE_DATA_CachedHealth",
    CachedHunger = "AE_DATA_CachedHunger",
    CachedThirst = "AE_DATA_CachedThirst",
    CachedFriendliness = "AE_DATA_CachedFriendliness",
}

AE_DataConfig.GlobalModDataKeys = {
    TamingData = "AE_DATA_TamingData",
    LivesData = "AE_DATA_LivesData",
    InventoryData = "AE_DATA_InventoryData",
    EquipmentData = "AE_DATA_EquipmentData",
    HomeData = "AE_DATA_GlobalHomeData",
    AnimalCacheData = "AE_DATA_AnimalCacheData",
    SessionRegistry = "AE_DATA_SessionRegistry",
    SystemStatus = "AE_DATA_SystemStatus",
}

AE_DataConfig.Persistence = {
    AutoSaveInterval = 300000,
    CacheRetention = 180,
    BackupOnModification = true,
    ValidateDataIntegrity = true,
    EnableDataMigration = true,
}

AE_DataConfig.Performance = {
    EventLatencyThreshold = 100,
    CacheUpdateBatchSize = 10,
    DataValidationInterval = 60,
    PerformanceLogging = false,
}

AE_DataConfig.Integrity = {
    ValidateOnAccess = true,
    AutoCorrectErrors = true,
    CorruptionBackups = 3,
    IntegrityCheckInterval = 300,
}

AE_DataConfig.Migration = {
    EnableKeyUnification = false,
    MigrationBatchSize = 5,
    RetainLegacyKeys = false,
    MigrationLogging = false,
}


function AE_DataConfig.GetModDataKey(keyName, namespace)
    namespace = namespace or "AE_DATA"
    local key = AE_DataConfig.ModDataKeys[keyName]
    if not key then
        print("[AE_DataConfig] ERROR: Unknown ModData key: " .. tostring(keyName))
        return nil
    end
    
    if not string.find(key, namespace) then
        print("[AE_DataConfig] WARNING: Key " .. keyName .. " not in expected namespace " .. namespace)
    end
    
    return key
end

function AE_DataConfig.GetGlobalModDataKey(keyName)
    local key = AE_DataConfig.GlobalModDataKeys[keyName]
    if not key then
        print("[AE_DataConfig] ERROR: Unknown global ModData key: " .. tostring(keyName))
        return nil
    end
    return key
end

function AE_DataConfig.ValidateNamespace(key, expectedNamespace)
    if not key or not expectedNamespace then return false end
    local namespace = AE_DataConfig.NAMESPACES[expectedNamespace]
    if not namespace then return false end
    return string.find(key, namespace) == 1
end

function AE_DataConfig.GetConfig(section, key)
    if AE_DataConfig[section] then
        return AE_DataConfig[section][key]
    end
    return nil
end

function AE_DataConfig.Validate()
    for namespace, prefix in pairs(AE_DataConfig.NAMESPACES) do
        if not prefix or prefix == "" then
            print("[AE_DataConfig] ERROR: Empty namespace prefix for: " .. namespace)
            return false
        end
    end
    
    for keyName, key in pairs(AE_DataConfig.ModDataKeys) do
        local hasValidNamespace = false
        for _, prefix in pairs(AE_DataConfig.NAMESPACES) do
            if string.find(key, prefix) == 1 then
                hasValidNamespace = true
                break
            end
        end
        if not hasValidNamespace then
            print("[AE_DataConfig] ERROR: ModData key " .. keyName .. " missing valid namespace prefix")
            return false
        end
    end
    
    return true
end

function AE_DataConfig.Initialize()
    if not AE_DataConfig.Validate() then
        print("[AE_DataConfig] CRITICAL: Configuration validation failed!")
        return false
    end
    
    if AE_EventRegistry then
        if not _G.AE_InitSequence then _G.AE_InitSequence = 0 end
        _G.AE_InitSequence = _G.AE_InitSequence + 1
        
        AE_EventRegistry.safeFireEvent("OnAE_DataLayerInitialized", {
            module = "AE_DataConfig",
            initSequence = _G.AE_InitSequence,
            keysRegistered = AE_DataConfig.GetKeyCount()
        })
    end
    
    print("[AE_DataConfig] Data configuration initialized successfully")
    return true
end

function AE_DataConfig.GetKeyCount()
    local count = 0
    for _ in pairs(AE_DataConfig.ModDataKeys) do
        count = count + 1
    end
    return count
end

function AE_DataConfig.GetOldKeyFormat()
    return {
        ["AE_Tameness"] = "AE_DATA_Tameness",
        ["AE_IsTamed"] = "AE_DATA_IsTamed",
        ["AE_Owner"] = "AE_DATA_Owner",
        ["AE_AnimalName"] = "AE_DATA_AnimalName",
        ["AE_StableID"] = "AE_DATA_StableID",
        ["AE_SlotAssigned"] = "AE_DATA_SlotAssigned",
        
        ["AE_CustomHunger"] = "AE_DATA_CustomHunger",
        ["AE_CustomThirst"] = "AE_DATA_CustomThirst",
        ["AE_LastHungerUpdate"] = "AE_DATA_LastHungerUpdate",
        
        ["AE_Friendliness"] = "AE_DATA_Friendliness",
        
        ["AE_RemainingLives"] = "AE_DATA_RemainingLives",
        
        ["AE_EquippedItems"] = "AE_CORE_EquippedItems",
        ["AE_HasBag"] = "AE_CORE_HasBag",
        ["AE_BagInventory"] = "AE_CORE_BagInventory",
        ["AE_CurrentCommand"] = "AE_CORE_CurrentCommand",
        ["AE_CommandMode"] = "AE_CORE_CommandMode",
        
        ["AE_IsFrameworkAnimal"] = "AE_DATA_IsFrameworkAnimal",
        ["AE_AnimalType"] = "AE_DATA_AnimalType",
        
        ["AE_LastSeenX"] = "AE_DATA_LastSeenX",
        ["AE_LastSeenY"] = "AE_DATA_LastSeenY",
        ["AE_LastSeenZ"] = "AE_DATA_LastSeenZ",
        ["AE_LastSeenTime"] = "AE_DATA_LastSeenTime",
        ["AE_LastDistanceCheck"] = "AE_DATA_LastDistanceCheck",
        ["AE_CachedHealth"] = "AE_DATA_CachedHealth",
        ["AE_CachedHunger"] = "AE_DATA_CachedHunger",
        ["AE_CachedThirst"] = "AE_DATA_CachedThirst",
        ["AE_CachedFriendliness"] = "AE_DATA_CachedFriendliness",
    }
end

function AE_DataConfig.MigrateAnimalKeys(animal)
    if not animal then return false end
    if not AE_DataConfig.Migration.EnableKeyUnification then return true end
    
    local modData = animal:getModData()
    if not modData then return false end
    
    local oldKeyMapping = AE_DataConfig.GetOldKeyFormat()
    local migrated = false
    local migratedCount = 0
    
    for oldKey, newKey in pairs(oldKeyMapping) do
        if modData[oldKey] ~= nil and modData[newKey] == nil then
            modData[newKey] = modData[oldKey]
            migratedCount = migratedCount + 1
            
            if not AE_DataConfig.Migration.RetainLegacyKeys then
                modData[oldKey] = nil
            end
            
            migrated = true
        end
    end
    
    if migrated and AE_DataConfig.Migration.MigrationLogging then
        print("[AE_DataConfig] Migrated " .. migratedCount .. " keys for animal " .. tostring(animal:getID()))
    end
    
    return migrated
end

function AE_DataConfig.NeedsKeyMigration(animal)
    if not animal or not AE_DataConfig.Migration.EnableKeyUnification then return false end
    
    local modData = animal:getModData()
    if not modData then return false end
    
    local oldKeyMapping = AE_DataConfig.GetOldKeyFormat()
    
    for oldKey, newKey in pairs(oldKeyMapping) do
        if modData[oldKey] ~= nil and modData[newKey] == nil then
            return true
        end
    end
    
    return false
end

_G.AE_DataConfig = AE_DataConfig

if not AE_DataConfig.Initialize() then
    error("[AE_DataConfig] CRITICAL: Failed to initialize data configuration during module loading")
end

Events.OnGameStart.Add(function()
    if AE_EventRegistry then
        AE_EventRegistry.safeFireEvent("OnAE_DataLayerInitialized", {
            module = "AE_DataConfig",
            initSequence = _G.AE_InitSequence or 0,
            keysRegistered = AE_DataConfig.GetKeyCount()
        })
    end
end)

return AE_DataConfig