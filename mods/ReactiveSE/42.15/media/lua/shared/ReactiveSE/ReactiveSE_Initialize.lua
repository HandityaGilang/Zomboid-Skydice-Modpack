--//////////////////////////////////////////////////--
--    Reactive Sound Events - Initialization
--    Entry point and shared initial setup
--//////////////////////////////////////////////////--

local Constants       = require "ReactiveSE/ReactiveSE_Constants"
local Utils           = require "ReactiveSE/ReactiveSE_Utils"
local Config          = require "ReactiveSE/ReactiveSE_Config"
local WeaponPools     = require "ReactiveSE/ReactiveSE_WeaponPools"

ReactiveSE_Initialize = ReactiveSE_Initialize or {}

-- Global mod state
ReactiveSE_State      = ReactiveSE_State or {
    initialized = false,
    isServer = false,
    isClient = false,
    isSingleplayer = false,
    modData = nil
}

--//////////////////////////////////////////////////--
--          Mode Detection Helpers                 --
--//////////////////////////////////////////////////--

---Returns true if running on server-side (Dedicated Server, Host, or Singleplayer)
---@return boolean
function ReactiveSE_Initialize.IsServerSide()
    return isServer() or ReactiveSE_State.isSingleplayer
end

---Returns true if running as a pure client (connected to dedicated server)
---@return boolean
function ReactiveSE_Initialize.IsPureClient()
    return isClient() and not isServer()
end

---Returns true if Scenes/Radio should be enabled (SP or Host only, NOT Dedicated Server)
---@return boolean
function ReactiveSE_Initialize.IsSceneEnvEnabled()
    return ReactiveSE_State.isSingleplayer or (isServer() and isClient())
end

-- Define custom event for decoupling
if not Events.OnReactiveSoundEvent then
    LuaEventManager.AddEvent("OnReactiveSoundEvent")
end

-- Define custom event for scene spawn notifications
if not Events.OnSceneSpawned then
    LuaEventManager.AddEvent("OnSceneSpawned")
end

-- Define custom event for Knox Relay radio marker (server -> client)
if not Events.OnKnoxRelayMarker then
    LuaEventManager.AddEvent("OnKnoxRelayMarker")
end

-- Define custom event for intel marked by player (client -> server, local in Host/SP)
if not Events.OnKnoxRelayIntelMarked then
    LuaEventManager.AddEvent("OnKnoxRelayIntelMarked")
end

--//////////////////////////////////////////////////--
--          ModData Management                    --
--//////////////////////////////////////////////////--

---Initializes ModData with default values
local function initializeModData()
    local modData = ModData.getOrCreate(Constants.MOD_ID)

    local defaults = {
        version = Constants.MOD_VERSION,

        -- Player stats tracking
        kCount = 0,
        tNoKills = 0,
        _killsToday = false,

        -- Event system
        baseEventChance = 0,
        eventChance = 0,
        eventCD = 0,

        -- Event history
        lastEventType = Constants.EventTypes.ZOMBIE,
        lastClips = { "Zombies1", "Animal1", "Zombies3" },
        lastEventTime = 0,
        totalEvents = 0,

        -- Reference player (MP)
        lastReferencePlayerId = nil,

        -- Event Scenes
        scenes = {},

        -- Radio State
        radioLastBroadcastDay = -1,
        radioLastBroadcastHour = -1,
        radioMorningShowPlayedToday = false,
        radioListenedToday = {}, -- Tracks XP grants per player per day
        radioIntelQueue = {},    -- Intel queue for Dedicated Server broadcasts
    }

    -- Apply defaults only if they don't exist
    for key, value in pairs(defaults) do
        if modData[key] == nil then
            modData[key] = value
        end
    end

    -- Check mod version
    if modData.version ~= Constants.MOD_VERSION then
        Utils.LogInfo("Version mismatch detected: " ..
            tostring(modData.version) ..
            " vs " .. Constants.MOD_VERSION .. ", but skipping update to avoid PZ settings reset bug.")
    end

    -- Update base chance with current configuration
    local cfg = Config.Get()
    if cfg.baseChance then
        modData.baseEventChance = cfg.baseChance
        modData.eventChance = cfg.baseChance
    end

    ReactiveSE_State.modData = modData

    Utils.LogInfo("ModData initialized")
    return modData
end

---Gets mod ModData
---@return table
function ReactiveSE_Initialize.GetModData()
    if not ReactiveSE_State.modData then
        ReactiveSE_State.modData = ModData.getOrCreate(Constants.MOD_ID)
    end
    return ReactiveSE_State.modData
end

--//////////////////////////////////////////////////--
--          Environment Detection                 --
--//////////////////////////////////////////////////--

---Detects execution environment
local function detectEnvironment()
    local isSrv                     = isServer()
    local isCli                     = isClient()
    local isSP                      = not isSrv and not isCli

    ReactiveSE_State.isServer       = isSrv
    ReactiveSE_State.isClient       = isCli
    ReactiveSE_State.isSingleplayer = isSP

    local envType
    if isSP then
        envType = "Singleplayer"
    elseif isSrv and isCli then
        envType = "Host (Server + Client)"
    elseif isSrv then
        envType = "Dedicated Server"
    elseif isCli then
        envType = "Client"
    else
        envType = "Unknown"
    end

    Utils.LogInfo("Environment detected: " .. envType)
    Utils.LogInfo("  isServer: " .. tostring(isSrv))
    Utils.LogInfo("  isClient: " .. tostring(isCli))
    Utils.LogInfo("  isSingleplayer: " .. tostring(isSP))
end

--//////////////////////////////////////////////////--
--          Initialization                        --
--//////////////////////////////////////////////////--

---Shared initialization (executes in all contexts)
---@return boolean success
function ReactiveSE_Initialize.InitializeShared()
    if ReactiveSE_State.initialized then
        Utils.LogWarning("Mod already initialized")
        return true
    end

    Utils.LogInfo("========================================")
    Utils.LogInfo("  " .. Constants.MOD_NAME)
    Utils.LogInfo("  Version: " .. Constants.MOD_VERSION)
    Utils.LogInfo("========================================")

    -- Detect environment
    detectEnvironment()

    -- Load configuration
    Config.Load()

    -- Validate configuration
    local isValid, error = Config.Validate()
    if not isValid then
        Utils.LogError("Configuration validation failed: " .. tostring(error))
        Utils.LogError("Mod may not function correctly!")
    end

    -- Initialize ModData
    initializeModData()

    -- Initialize WeaponPools
    WeaponPools.InitializeDynamicPools()

    ReactiveSE_State.initialized = true

    Utils.LogInfo("Shared initialization complete")

    return true
end

-- Initialization event
local function onGameStart()
    ReactiveSE_Initialize.InitializeShared()
end

if isServer() then
    Events.OnServerStarted.Add(onGameStart)
else
    Events.OnGameStart.Add(onGameStart)
end
