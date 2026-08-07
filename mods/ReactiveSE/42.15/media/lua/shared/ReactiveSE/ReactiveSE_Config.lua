--//////////////////////////////////////////////////--
--    Reactive Sound Events - Configuration
--    Handling of SandboxVars and configuration
--//////////////////////////////////////////////////--

local Constants         = require "ReactiveSE/ReactiveSE_Constants"
local Utils             = require "ReactiveSE/ReactiveSE_Utils"

local ReactiveSE_Config = {}

-- Configuration state
local config            = {
    loaded = false,
    values = {}
}

--//////////////////////////////////////////////////--
--          Configuration Loading                 --
--//////////////////////////////////////////////////--

---Loads a sandbox value with validation
---@param category string
---@param key string
---@param defaultValue any
---@param min number|nil
---@param max number|nil
---@return any
local function loadSandboxValue(category, key, defaultValue, min, max)
    local fullKey = category .. "." .. key
    local value = SandboxVars[category] and SandboxVars[category][key]

    if value == nil then
        Utils.LogWarning("SandboxVar " .. fullKey .. " not found, using default: " .. tostring(defaultValue))
        return defaultValue
    end

    -- Validate range if numeric
    if type(defaultValue) == "number" and min and max then
        value = Utils.ValidateRange(value, min, max, defaultValue)
    end

    return value
end

---Loads cooldown configuration
---@return table
local function loadCooldownConfig()
    local minCDHours = loadSandboxValue("ReactiveSE", "MinEventCooldown",
        Constants.Defaults.MIN_COOLDOWN_HOURS, 1, 168)
    local maxCDHours = loadSandboxValue("ReactiveSE", "MaxEventCooldown",
        Constants.Defaults.MAX_COOLDOWN_HOURS, 2, 168)
    local eventChance = loadSandboxValue("ReactiveSE", "EventChance",
        Constants.Defaults.EVENT_CHANCE, 1, 100)
    local flatProbability = loadSandboxValue("ReactiveSE", "FlatProbability", true)

    -- Convert hours to minutes internally
    local minCD = minCDHours * 60
    local maxCD = maxCDHours * 60

    -- Validate that min < max
    if minCDHours >= maxCDHours then
        Utils.LogWarning("MinCD >= MaxCD, using defaults")
        minCD = Constants.Defaults.MIN_COOLDOWN_HOURS * 60
        maxCD = Constants.Defaults.MAX_COOLDOWN_HOURS * 60
    end

    return {
        minCD = minCD,
        maxCD = maxCD,
        baseChance = eventChance,
        flatProbability = flatProbability
    }
end

---Loads range configuration
---@return table
local function loadRangeConfig()
    local minRange = loadSandboxValue("ReactiveSE", "MinSoundRange",
        Constants.Defaults.MIN_RANGE, 120, 1000)
    local maxRange = loadSandboxValue("ReactiveSE", "MaxSoundRange",
        Constants.Defaults.MAX_RANGE, 120, 1000)
    local reactionRange = loadSandboxValue("ReactiveSE", "ReactionThresholdRange",
        Constants.Defaults.REACTION_RANGE, 120, 1000)

    -- Validate that min < max
    if minRange > maxRange then
        Utils.LogWarning("MinRange > MaxRange, using defaults")
        minRange = Constants.Defaults.MIN_RANGE
        maxRange = Constants.Defaults.MAX_RANGE
    end

    if reactionRange < minRange or reactionRange > maxRange then
        Utils.LogWarning("ReactionRange out of bounds, using default or midpoint")
        local default = Constants.Defaults.REACTION_RANGE
        if default < minRange or default > maxRange then
            Utils.LogWarning("ReactionRange default out of bounds, using midpoint")
            default = (maxRange + minRange) / 2
        else
            Utils.LogWarning("ReactionRange out of bounds, using default")
            reactionRange = Constants.Defaults.REACTION_RANGE
        end
    end

    return {
        minRange = minRange,
        maxRange = maxRange,
        reactionRange = reactionRange
    }
end

---Loads event types configuration
---@return table
local function loadEventTypesConfig()
    local events = {}

    for eventType, sandboxKey in pairs(Constants.EventConfigMap) do
        events[eventType] = loadSandboxValue("ReactiveSEEvents", sandboxKey, true)
    end

    return events
end

---Loads scene types configuration (per-event scene toggles)
---@return table
local function loadSceneTypesConfig()
    return {
        EnableGunfightScene = loadSandboxValue("ReactiveSEScenes", "EnableGunfightScene", true),
        EnableGunshotScene = loadSandboxValue("ReactiveSEScenes", "EnableGunshotScene", true),
        EnableScreamScene = loadSandboxValue("ReactiveSEScenes", "EnableScreamScene", true),
        EnableVehicleCrashScene = loadSandboxValue("ReactiveSEScenes", "EnableVehicleCrashScene", true),
        EnableZombieScene = loadSandboxValue("ReactiveSEScenes", "EnableZombieScene", true),
    }
end

---Loads additional options configuration
---@return table
local function loadBehaviorOptions()
    return {
        enableZombieHearing = loadSandboxValue("ReactiveSE", "EnableZombieHearing", true),
        playerStyle = loadSandboxValue("ReactiveSEBehavior", "EnablePlayerStyle", true),
        aggKills = loadSandboxValue("ReactiveSEBehavior", "AggressiveStyleKills",
            Constants.Defaults.AGGRESSIVE_KILLS, 20, 200),
        pasDays = loadSandboxValue("ReactiveSEBehavior", "PassiveStyleDays",
            Constants.Defaults.PASSIVE_DAYS, 1, 7),
        playerPanic = loadSandboxValue("ReactiveSEBehavior", "EnablePlayerReactionPanic", true),
        playerWakeUp = loadSandboxValue("ReactiveSEBehavior", "EnablePlayerReactionWakeUp", true),

        -- DEBUG
        debugMode = loadSandboxValue(
            "ReactiveSE",
            "EnableDebugMode",
            false
        )
    }
end

---Loads scene configuration
---@return table
local function loadSceneConfig()
    local enabled = loadSandboxValue("ReactiveSEScenes", "EnableEventScenes", true)
    local chance = loadSandboxValue("ReactiveSEScenes", "EventSceneChance",
        Constants.Defaults.SCENE_CHANCE, 0, 100)
    local cleanupHours = loadSandboxValue("ReactiveSEScenes", "SceneCleanupHours",
        Constants.Defaults.SCENE_CLEANUP_HOURS, 0, 168)
    local screamZombieCount = loadSandboxValue("ReactiveSEScenes", "ScreamZombieCount",
        Constants.Defaults.SCENE_SCREAM_ZOMBIE_COUNT, 0, 10)
    local vehicleMaxCondition = loadSandboxValue("ReactiveSEScenes", "VehicleMaxCondition",
        Constants.Defaults.SCENE_VEHICLE_MAX_CONDITION, 1, 5)
    local vehicleKeyChance = loadSandboxValue("ReactiveSEScenes", "VehicleKeyChance",
        Constants.Defaults.SCENE_VEHICLE_KEY_CHANCE, 0, 100)
    local zombieSceneMin = loadSandboxValue("ReactiveSEScenes", "ZombieSceneMin",
        Constants.Defaults.ZOMBIE_SCENE_MIN, 1, 20)
    local zombieSceneMax = loadSandboxValue("ReactiveSEScenes", "ZombieSceneMax",
        Constants.Defaults.ZOMBIE_SCENE_MAX, 1, 20)
    local enableNotify = loadSandboxValue("ReactiveSEScenes", "EnableSceneSpawnNotify", true)
    local notifyText = loadSandboxValue("ReactiveSEScenes", "SceneSpawnNotifyText", true)
    local notifyMarker = loadSandboxValue("ReactiveSEScenes", "SceneSpawnNotifyMarker", false)
    local lootQuality = loadSandboxValue("ReactiveSELoot", "LootQuality",
        Constants.Defaults.SCENE_LOOT_QUALITY, 1, 4)
    local weaponMaxCondition = loadSandboxValue("ReactiveSELoot", "WeaponMaxCondition",
        Constants.Defaults.SCENE_WEAPON_MAX_CONDITION, 10, 100)
    local rangedChance = loadSandboxValue("ReactiveSELoot", "RangedWeaponChance",
        Constants.Defaults.SCENE_RANGED_CHANCE, 0, 100)
    local minBackpackStealChance = loadSandboxValue("ReactiveSELoot", "MinBackpackStealChance",
        Constants.Defaults.SCENE_BACKPACK_MIN_STEAL_CHANCE, 0, 100)
    local maxBackpackStealChance = loadSandboxValue("ReactiveSELoot", "MaxBackpackStealChance",
        Constants.Defaults.SCENE_BACKPACK_MAX_STEAL_CHANCE, 0, 100)
    local ammoScarcity = loadSandboxValue("ReactiveSELoot", "AmmoScarcity",
        Constants.Defaults.SCENE_AMMO_SCARCITY, 1, 4)
    local subKitCountMin = loadSandboxValue("ReactiveSELoot", "SubKitCountMin",
        Constants.Defaults.SCENE_SUBKIT_COUNT_MIN, 1, 10)
    local subKitCountMax = loadSandboxValue("ReactiveSELoot", "SubKitCountMax",
        Constants.Defaults.SCENE_SUBKIT_COUNT_MAX, 1, 10)
    local corpseCount = loadSandboxValue("ReactiveSEWorld", "CorpseCount",
        Constants.Defaults.SCENE_CORPSE_COUNT, 2, 8)

    -- Validate min < max
    if zombieSceneMin > zombieSceneMax then
        Utils.LogWarning("ZombieSceneMin > ZombieSceneMax, using defaults")
        zombieSceneMin = Constants.Defaults.ZOMBIE_SCENE_MIN
        zombieSceneMax = Constants.Defaults.ZOMBIE_SCENE_MAX
    end

    -- Validate that min < max
    if minBackpackStealChance > maxBackpackStealChance then
        Utils.LogWarning("MinBackpackStealChance > MaxBackpackStealChance, using defaults")
        minBackpackStealChance = Constants.Defaults.SCENE_BACKPACK_MIN_STEAL_CHANCE
        maxBackpackStealChance = Constants.Defaults.SCENE_BACKPACK_MAX_STEAL_CHANCE
    end

    return {
        enabled = enabled,
        chance = chance,
        cleanupHours = cleanupHours,
        screamZombieCount = screamZombieCount,
        vehicleMaxCondition = vehicleMaxCondition,
        vehicleKeyChance = vehicleKeyChance,
        zombieSceneMin = zombieSceneMin,
        zombieSceneMax = zombieSceneMax,
        lootQuality = lootQuality,
        weaponMaxCondition = weaponMaxCondition,
        rangedChance = rangedChance,
        minBackpackStealChance = minBackpackStealChance,
        maxBackpackStealChance = maxBackpackStealChance,
        ammoScarcity = ammoScarcity,
        subKitCountMin = subKitCountMin,
        subKitCountMax = subKitCountMax,
        corpseCount = corpseCount,
        notify = {
            enabled = enableNotify,
            text = notifyText,
            marker = notifyMarker
        }
    }
end

---Loads distance probability configuration
---@return table
local function loadDistanceConfig()
    local closeChance = loadSandboxValue("ReactiveSE", "CloseDistanceChance",
        Constants.DistanceDistribution.CLOSE_CHANCE, 0, 100)
    local mediumChance = loadSandboxValue("ReactiveSE", "MediumDistanceChance",
        Constants.DistanceDistribution.MEDIUM_CHANCE, 0, 100)
    local farChance = loadSandboxValue("ReactiveSE", "FarDistanceChance",
        Constants.DistanceDistribution.FAR_CHANCE, 0, 100)

    -- Validate that chances sum to 100
    local total = closeChance + mediumChance + farChance
    if total ~= 100 then
        Utils.LogWarning("Distance chances sum to " .. total .. " instead of 100, using defaults")
        closeChance = Constants.DistanceDistribution.CLOSE_CHANCE
        mediumChance = Constants.DistanceDistribution.MEDIUM_CHANCE
        farChance = Constants.DistanceDistribution.FAR_CHANCE
    end

    return {
        closeChance = closeChance,
        mediumChance = mediumChance,
        farChance = farChance
    }
end

local function loadWorldTierConfig()
    local worldTierEarlyEnd = loadSandboxValue("ReactiveSEWorld", "WorldTierEarlyEnd",
        Constants.Defaults.SCENE_WORLD_TIER_EARLY_END, 1, 365)
    local worldTierMidEnd = loadSandboxValue("ReactiveSEWorld", "WorldTierMidEnd",
        Constants.Defaults.SCENE_WORLD_TIER_MID_END, 2, 365)
    local worldTierLateEnd = loadSandboxValue("ReactiveSEWorld", "WorldTierLateEnd",
        Constants.Defaults.SCENE_WORLD_TIER_LATE_END, 3, 365)

    return {
        worldTierEarlyEnd = worldTierEarlyEnd,
        worldTierMidEnd = worldTierMidEnd,
        worldTierLateEnd = worldTierLateEnd
    }
end

---Loads radio station configuration
---@return table
local function loadRadioConfig()
    local enabled = loadSandboxValue("ReactiveSERadio", "EnableRadioFeature", true)
    local mapMarker = loadSandboxValue("ReactiveSERadio", "EnableMapMarker", true)
    local morningShowXP = loadSandboxValue("ReactiveSERadio", "EnableMorningShowXP", true)

    return {
        enabled = enabled,
        mapMarker = mapMarker,
        morningShowXP = morningShowXP
    }
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Loads all configuration from SandboxVars
function ReactiveSE_Config.Load()
    if config.loaded then
        Utils.LogWarning("Config already loaded, reloading...")
    end

    Utils.LogInfo("Loading configuration from SandboxVars...")

    -- Load all sections
    local cooldown = loadCooldownConfig()
    local range = loadRangeConfig()
    local events = loadEventTypesConfig()
    local sceneTypes = loadSceneTypesConfig()
    local behavior = loadBehaviorOptions()
    local scenes = loadSceneConfig()
    local worldTier = loadWorldTierConfig()
    local distance = loadDistanceConfig()
    local radio = loadRadioConfig()

    -- Consolidate configuration
    config.values = {
        -- Cooldowns
        minCD = cooldown.minCD,
        maxCD = cooldown.maxCD,
        baseChance = cooldown.baseChance,
        flatProbability = cooldown.flatProbability,

        -- Ranges
        minRange = range.minRange,
        maxRange = range.maxRange,
        reactionRange = range.reactionRange,

        -- Distance probabilities
        closeDistanceChance = distance.closeChance,
        mediumDistanceChance = distance.mediumChance,
        farDistanceChance = distance.farChance,

        -- Events
        events = events,

        -- Behavior options
        enableZombieHearing = behavior.enableZombieHearing,
        playerStyle = behavior.playerStyle,
        aggKills = behavior.aggKills,
        pasDays = behavior.pasDays,
        playerPanic = behavior.playerPanic,
        playerWakeUp = behavior.playerWakeUp,
        debugMode = behavior.debugMode,

        -- Scenes
        scenes = scenes,
        sceneTypes = sceneTypes,
        worldTier = worldTier,

        -- Radio
        radio = radio,
    }

    config.loaded = true

    Utils.LogInfo("Configuration loaded successfully")
end

---Gets current configuration
---@return table
function ReactiveSE_Config.Get()
    if not config.loaded then
        Utils.LogError("Config not loaded yet!")
        return {}
    end
    return config.values
end

---Reloads the configuration
function ReactiveSE_Config.Reload()
    config.loaded = false
    ReactiveSE_Config.Load()
end

---Validates that the configuration is correct
---@return boolean isValid
---@return string|nil errorMessage
function ReactiveSE_Config.Validate()
    if not config.loaded then
        return false, "Config not loaded"
    end

    local cfg = config.values

    -- Validate cooldowns
    if cfg.minCD > cfg.maxCD then
        return false, "MinCD must be less than MaxCD"
    end

    -- Validate ranges
    if cfg.minRange > cfg.maxRange then
        return false, "MinRange must be less than MaxRange"
    end

    if cfg.reactionRange < cfg.minRange or cfg.reactionRange > cfg.maxRange then
        return false, "ReactionRange out of bounds"
    end

    -- Validate that at least one event type is enabled
    local hasEnabledEvent = false
    for _, enabled in pairs(cfg.events) do
        if enabled then
            hasEnabledEvent = true
            break
        end
    end

    if not hasEnabledEvent then
        return false, "At least one event type must be enabled"
    end

    -- Validate World Tier End
    local function isValidDay(value)
        return type(value) == "number" and value >= 1 and value <= 365
    end

    if not isValidDay(cfg.worldTier.worldTierEarlyEnd)
        or not isValidDay(cfg.worldTier.worldTierMidEnd)
        or not isValidDay(cfg.worldTier.worldTierLateEnd) then
        return false, "WorldTier values must be between 1 and 365"
    end

    if not (cfg.worldTier.worldTierEarlyEnd < cfg.worldTier.worldTierMidEnd
            and cfg.worldTier.worldTierMidEnd < cfg.worldTier.worldTierLateEnd) then
        return false, "WorldTier order must be: Early < Mid < Late"
    end

    return true, nil
end

---Indicates if debug mode is enabled
---@return boolean
function ReactiveSE_Config.IsDebug()
    return config.loaded and config.values.debugMode == true
end

return ReactiveSE_Config
