-- CONVERTED: AE_AnimalRegistry.lua
-- SESSION 3A: All ModData access replaced with AE_DataService calls
-- SESSION 4B: Inter-mod communication implementation

local AE_AnimalRegistry = {}

-- External dependencies (via inter-mod communication)
local Config = nil
local AE_CoreCommunication = nil
local AE_MasterConfig = nil

-- Initialization state
AE_AnimalRegistry.isInitialized = false

AE_AnimalRegistry.RegisteredCategories = {}
AE_AnimalRegistry.CoreUtilitiesModules = {}
AE_AnimalRegistry.IsoTypeToCategory = {}
AE_AnimalRegistry.ProcessedAnimals = {}

-- FrameworkInstanceID will be set during initialization
AE_AnimalRegistry.FrameworkInstanceID = "AE_Instance_Default"

-- Initialize dependencies and inter-mod communication
AE_AnimalRegistry.initialize = function()
    if AE_AnimalRegistry.isInitialized then
        return
    end
    
    -- Load AE_MasterConfig first
    local configSuccess, configResult = pcall(function()
        return require("AnimalsEssentials/ForModders/AE_MasterConfig")
    end)
    if configSuccess and configResult then
        AE_MasterConfig = configResult
        Config = AE_MasterConfig
    end
    
    -- Load CoreCommunication from same mod
    local success, result = pcall(function()
        return require("AnimalsEssentials/Communication/AE_CoreCommunication")
    end)
    if success and result then
        AE_CoreCommunication = result
        
        -- Request Config data for FrameworkInstanceID setup
        AE_CoreCommunication.requestData("Config", nil, function(response)
            if response and response.RegisteredAnimals and response.RegisteredAnimals[1] then
                local firstCategory = response.RegisteredAnimals[1].category or "Default"
                AE_AnimalRegistry.FrameworkInstanceID = "AE_Instance_" .. firstCategory
            end
        end)
    end
    
    -- Call Initialize() here to ensure Config is loaded before IsoTypeToCategory mapping
    if Config and Config.RegisteredAnimals then
        AE_AnimalRegistry.Initialize()
    end
    
    AE_AnimalRegistry.isInitialized = true
end

function AE_AnimalRegistry.LoadCoreUtilitiesModule(category)
    if not category then return nil end
    if AE_AnimalRegistry.CoreUtilitiesModules[category] then
        return AE_AnimalRegistry.CoreUtilitiesModules[category]
    end

    -- Defensive check for Config availability
    if not Config or not Config.GetCoreUtilitiesPath then
        return nil
    end

    local modulePath = Config.GetCoreUtilitiesPath(category)
    if not modulePath then
        return nil
    end

    local success, coreUtilsModule = pcall(function()
        return require(modulePath)
    end)

    if not success then
        return nil
    end

    if not coreUtilsModule.ValidAnimalScan then
        return nil
    end

    AE_AnimalRegistry.CoreUtilitiesModules[category] = coreUtilsModule

    return coreUtilsModule
end

function AE_AnimalRegistry.Initialize()
    AE_AnimalRegistry.RegisteredCategories = {}
    AE_AnimalRegistry.IsoTypeToCategory = {}
    
    -- Defensive check for Config availability
    if not Config or not Config.RegisteredAnimals then
        print("[AE_AnimalRegistry] Warning: Config not available during Initialize(), deferring registration")
        return false
    end
    
    for _, animalConfig in ipairs(Config.RegisteredAnimals) do
        local category = animalConfig.category

        AE_AnimalRegistry.RegisteredCategories[category] = true

        for _, isoType in ipairs(animalConfig.isoTypes) do
            AE_AnimalRegistry.IsoTypeToCategory[isoType] = category
        end
    end
    
    return true
end

-- CONVERTED: Use AE_DataService instead of direct ModData access
function AE_AnimalRegistry.IsFrameworkAnimal(animal)
    if not animal then return false end

    -- Type safety: Only process IsoAnimal objects
    -- Rejects IsoZombie, IsoPlayer, and other character types
    if not instanceof(animal, "IsoAnimal") then
        return false
    end

    if not AE_AnimalRegistry.isInitialized then
        return false
    end

    -- BUGFIX: Check actual animal type FIRST, not ModData presence
    -- This prevents Lives System from triggering on non-cat animals with contaminated ModData
    local category = AE_AnimalRegistry.DetermineAnimalCategory(animal)
    if not category or not AE_AnimalRegistry.RegisteredCategories[category] then
        return false  -- REJECT: Not a registered animal type (not cat)
    end

    -- Only validate animals that are registered framework animals
    if not AE_DataService.isAnimalValid(animal) then return false end

    -- Verify/set ModData for valid animals only
    local key = AE_DataConfig.ModDataKeys.AnimalType
    local namespace = "AE_DATA"
    local storedType = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    if not storedType then
        AE_NamespaceManager.setModData(animal, key, category, namespace, "AE_FrameworkData")
    end
    
    return true  -- ACCEPT: Valid cat with proper registration
end

-- CONVERTED: Enhanced framework animal detection with validation
function AE_AnimalRegistry.ValidateAndRegisterFrameworkAnimal(animal)
    if not AE_DataService.isAnimalValid(animal) then return false end
    
    local category = AE_AnimalRegistry.DetermineAnimalCategory(animal)
    if category then
        -- Store animal type in modern namespace
        local key = AE_DataConfig.ModDataKeys.AnimalType
        local namespace = "AE_DATA"
        AE_NamespaceManager.setModData(animal, key, category, namespace, "AE_FrameworkData")
        return true
    end
    
    return false
end

-- CONVERTED: Use AE_DataService for animal type retrieval
function AE_AnimalRegistry.GetAnimalType(animal)
    if not AE_DataService.isAnimalValid(animal) then return nil end
    
    -- Get animal type through modern data service
    local key = AE_DataConfig.ModDataKeys.AnimalType
    local namespace = "AE_DATA"
    local animalType = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    if animalType then
        return animalType
    end
    
    -- Try to determine and set animal type if not found
    local category = AE_AnimalRegistry.DetermineAnimalCategory(animal)
    if category then
        AE_NamespaceManager.setModData(animal, key, category, namespace, "AE_FrameworkData")
        return category
    end
    
    return nil
end

function AE_AnimalRegistry.EnsureInitialized()
    if AE_AnimalRegistry.isInitialized then
        return true
    end
    
    local success = pcall(function()
        AE_AnimalRegistry.initialize()
    end)
    
    if not success then
        print("[AE_AnimalRegistry] WARNING: Lazy initialization failed")
        return false
    end
    
    return AE_AnimalRegistry.isInitialized
end

function AE_AnimalRegistry.DetermineAnimalCategory(animal)
    if not AE_AnimalRegistry.EnsureInitialized() then
        print("[AE_AnimalRegistry] ERROR: Cannot determine category - initialization failed")
        return nil
    end
    
    if not animal then return nil end
    
    local isoType = animal:getAnimalType()
    if not isoType then return nil end
    
    return AE_AnimalRegistry.IsoTypeToCategory[isoType]
end

function AE_AnimalRegistry.IsValidAnimal(animal)
    if not animal then return false end
    
    local success, result = pcall(function()
        return animal.isAnimal and animal:isAnimal()
    end)
    
    return success and result
end

-- CONVERTED: Use AE_DataService.isAnimalValid instead of direct access
function AE_AnimalRegistry.getAnimalModData(animal)
    -- CONVERTED: Use standardized validation
    return AE_DataService.isAnimalValid(animal)
end

-- CONVERTED: Complete animal registration with AE_DataService
function AE_AnimalRegistry.RegisterAnimal(animal, animalType)
    if not AE_DataService.isAnimalValid(animal) then return false end
    if not animalType then return false end
    
    -- Store animal type in modern namespace
    local key = AE_DataConfig.ModDataKeys.AnimalType
    local namespace = "AE_DATA"
    AE_NamespaceManager.setModData(animal, key, animalType, namespace, "AE_FrameworkData")
    
    -- Initialize core data if not set
    if AE_DataService.getTameness(animal) == 0 and not AE_DataService.isTamed(animal) then
        AE_DataService.setTameness(animal, 0.0)
    end
    
    if not AE_DataService.isTamed(animal) then
        AE_DataService.setTamed(animal, false)  
    end
    
    if AE_DataService.getHunger(animal) == 100 then -- Default uninitialized value
        AE_DataService.setHunger(animal, 70)
    end
    
    if AE_DataService.getThirst(animal) == 100 then -- Default uninitialized value
        AE_DataService.setThirst(animal, 70)
    end
    
    -- Initialize friendliness if available
    local friendlinessKey = AE_DataConfig.ModDataKeys.Friendliness
    local namespace = "AE_DATA"
    local friendliness = AE_NamespaceManager.getModData(animal, friendlinessKey, namespace, "AE_FrameworkData")
    if friendliness == nil then
        AE_NamespaceManager.setModData(animal, friendlinessKey, 0.0, namespace, "AE_FrameworkData")
    end
    
    -- Initialize lives system if enabled
    if Config and Config.IsSystemEnabled and Config.IsSystemEnabled("LivesSystem") then
        local livesKey = AE_DataConfig.ModDataKeys.RemainingLives
        local namespace = "AE_DATA"
        local remainingLives = AE_NamespaceManager.getModData(animal, livesKey, namespace, "AE_FrameworkData")
        if remainingLives == nil then
            local maxLives = (Config.GetSystemConfig and Config.GetSystemConfig("LivesSystem", "DefaultMaxLives")) or 1
            AE_NamespaceManager.setModData(animal, livesKey, maxLives, namespace, "AE_FrameworkData")
        end
    end
    
    return true
end

function AE_AnimalRegistry.GetRegisteredCategories()
    return AE_AnimalRegistry.RegisteredCategories
end

function AE_AnimalRegistry.GetCategoryForIsoType(isoType)
    return AE_AnimalRegistry.IsoTypeToCategory[isoType]
end

function AE_AnimalRegistry.ProcessAnimal(animal)
    if not AE_AnimalRegistry.IsValidAnimal(animal) then return false end
    
    local animalID = animal:getOnlineID() or animal:getID()
    
    if AE_AnimalRegistry.ProcessedAnimals[animalID] then
        return true
    end
    
    local category = AE_AnimalRegistry.DetermineAnimalCategory(animal)
    if not category then return false end
    
    local success = AE_AnimalRegistry.RegisterAnimal(animal, category)
    if success then
        AE_AnimalRegistry.ProcessedAnimals[animalID] = true
        
        -- Fire registration event
        if AE_EventRegistry then
            AE_EventRegistry.safeFireEvent("OnAE_AnimalRegistered", {
                animal = animal,
                animalID = animalID,
                category = category,
                timestamp = GameTime.getServerTimeMills()
            })
        end
    end
    
    return success
end

-- CONVERTED: Use AE_DataService for framework ID checking
function AE_AnimalRegistry.GetFrameworkID(animal)
    if not AE_DataService.isAnimalValid(animal) then return nil end
    
    -- Check if animal is registered by looking for AnimalType
    local key = AE_DataConfig.ModDataKeys.AnimalType
    local namespace = "AE_DATA"
    local animalType = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    local frameworkID = animalType and AE_AnimalRegistry.FrameworkInstanceID or nil
    if frameworkID then
        return frameworkID
    end
    
    return nil
end

-- CONVERTED: Enhanced framework detection with data service
function AE_AnimalRegistry.HasFrameworkID(animal)
    if not AE_DataService.isAnimalValid(animal) then return false end
    
    -- Check if animal is registered by looking for AnimalType
    local key = AE_DataConfig.ModDataKeys.AnimalType
    local namespace = "AE_DATA"
    local animalType = AE_NamespaceManager.getModData(animal, key, namespace, "AE_FrameworkData")
    return animalType ~= nil
end

-- Mass processing functions
function AE_AnimalRegistry.ProcessAllAnimalsInWorld()
    local processedCount = 0
    
    local cell = getWorld():getCell()
    if not cell then return processedCount end
    
    for i = 0, cell:getObjectList():size() - 1 do
        local obj = cell:getObjectList():get(i)
        if obj and AE_AnimalRegistry.IsValidAnimal(obj) then
            if AE_AnimalRegistry.ProcessAnimal(obj) then
                processedCount = processedCount + 1
            end
        end
    end
    
    print("[AE_AnimalRegistry] Processed " .. processedCount .. " animals")
    return processedCount
end

function AE_AnimalRegistry.GetAllFrameworkAnimals()
    local frameworkAnimals = {}
    
    local cell = getWorld():getCell()
    if not cell then return frameworkAnimals end
    
    for i = 0, cell:getObjectList():size() - 1 do
        local obj = cell:getObjectList():get(i)
        if obj and AE_AnimalRegistry.IsValidAnimal(obj) then
            if AE_AnimalRegistry.IsFrameworkAnimal(obj) then
                table.insert(frameworkAnimals, obj)
            end
        end
    end
    
    return frameworkAnimals
end

-- Cleanup functions
function AE_AnimalRegistry.ClearProcessedAnimals()
    AE_AnimalRegistry.ProcessedAnimals = {}
end

function AE_AnimalRegistry.GetProcessedAnimalCount()
    local count = 0
    for _ in pairs(AE_AnimalRegistry.ProcessedAnimals) do
        count = count + 1
    end
    return count
end

-- PHASE 1.2: Critical missing functions for hunting system integration
function AE_AnimalRegistry.GetCategoryFromIsoType(isoType)
    if not isoType then return nil end
    return AE_AnimalRegistry.IsoTypeToCategory[isoType]
end

function AE_AnimalRegistry.GetAnimalType(animal)
    if not animal then return nil end

    local success, isoType = pcall(function()
        return animal:getAnimalType()
    end)

    if success and isoType then
        return AE_AnimalRegistry.GetCategoryFromIsoType(isoType)
    end

    return nil
end

-- Initialize category mapping from Config when available
function AE_AnimalRegistry.InitializeCategoryMapping()
    if not Config or not Config.RegisteredAnimals then
        return false
    end
    
    AE_AnimalRegistry.IsoTypeToCategory = {}
    for _, animalConfig in ipairs(Config.RegisteredAnimals) do
        local category = animalConfig.category
        if animalConfig.isoTypes then
            for _, isoType in ipairs(animalConfig.isoTypes) do
                AE_AnimalRegistry.IsoTypeToCategory[isoType] = category
            end
        end
    end
    return true
end


return AE_AnimalRegistry