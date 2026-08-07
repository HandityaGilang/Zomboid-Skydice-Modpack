--//////////////////////////////////////////////////--
--    Reactive Sound Events - Server Main
--    Authoritative side initialization and coordination
--    (Server, Host and Singleplayer)
--//////////////////////////////////////////////////--

local isSP = not isServer() and not isClient()
if not isServer() and not isSP then return end

local Utils                  = require "ReactiveSE/ReactiveSE_Utils"
local Constants              = require "ReactiveSE/ReactiveSE_Constants"
local Config                 = require "ReactiveSE/ReactiveSE_Config"
local SceneManager           = require "ReactiveSE/ReactiveSE_SceneManager"
local Radio                  = require "ReactiveSE/ReactiveSE_Radio"
local EventScheduler         = require "ReactiveSE/ReactiveSE_EventScheduler"
local EventGenerator         = require "ReactiveSE/ReactiveSE_EventGenerator"

local ReactiveSE_Server      = {}

-- Distance buffer added to maxRange for filtering (tiles)
local BROADCAST_RANGE_BUFFER = 200

--//////////////////////////////////////////////////--
--          Server Initialization                 --
--//////////////////////////////////////////////////--

---Server specific initialization
---@return boolean success
local function initializeServer()
    if not ReactiveSE_State or not ReactiveSE_State.initialized then
        Utils.LogWarning("[Server] Shared initialization not complete!")
        return false
    end

    if isSP then
        Utils.LogInfo("[Server] Running in Singleplayer (server emulation mode)")
    elseif isClient() then
        Utils.LogInfo("[Server] Running in Host mode (Server + Client)")
    else
        Utils.LogInfo("[Server] Running in Dedicated Server mode")
    end

    -- Initialize dependent modules
    -- SceneManager only runs in SP/Host (needs local player for scene spawning)
    if ReactiveSE_Initialize.IsSceneEnvEnabled() then
        SceneManager.Initialize()
    else
        Utils.LogInfo("[Server/SceneManager] Skipped (Dedicated Server)")
    end

    -- Radio works in all modes (broadcasts intel)
    Radio.Initialize()

    Utils.LogInfo("[Server] Server-side initialization complete")
    return true
end

--//////////////////////////////////////////////////--
--          Server Functions                      --
--//////////////////////////////////////////////////--

---Sends event to remote clients within range
---@param eventData table
function ReactiveSE_Server.BroadcastEvent(eventData)
    if isSP then return end
    if not eventData then return end
    if not eventData.x or not eventData.y then return end

    local config = Config.Get()
    local maxRange = (config.maxRange or 600) + BROADCAST_RANGE_BUFFER

    -- Get host player to exclude (they already received via local execution)
    local hostPlayer = getPlayer()
    local hostOnlineId = hostPlayer and hostPlayer:getOnlineID() or nil

    -- Get all connected players
    local players = getOnlinePlayers()
    if not players then return end

    local sentCount = 0
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            -- Skip host player (already handled locally)
            if hostOnlineId and player:getOnlineID() == hostOnlineId then
                Utils.LogInfo("[Server] Skipping host player for broadcast (already executed locally)")
            else
                -- Calculate distance from player to event
                local distance = Utils.GetDistance(
                    player:getX(), player:getY(),
                    eventData.x, eventData.y
                )

                if distance <= maxRange then
                    sendServerCommand(
                        player,
                        Constants.MOD_ID,
                        Constants.NetworkCommands.PLAY_SOUND_EVENT,
                        eventData
                    )
                    sentCount = sentCount + 1
                    Utils.LogInfo("[Server] Event sent to " .. player:getUsername() ..
                        " (distance: " .. math.floor(distance) .. " tiles)")
                else
                    Utils.LogInfo("[Server] Player " .. player:getUsername() ..
                        " too far (" .. math.floor(distance) .. " tiles), skipping")
                end
            end
        end
    end

    Utils.LogInfo("[Server] Event broadcasted to " .. sentCount .. " players: " ..
        eventData.eventType .. " (" .. eventData.clip .. ")")
end

---Queues event for radio intel (Dedicated Server only)
---@param eventData table
function ReactiveSE_Server.QueueRadioIntel(eventData)
    local modData = ReactiveSE_Initialize.GetModData()
    modData.radioIntelQueue = modData.radioIntelQueue or {}

    local MAX_QUEUE = 10
    if #modData.radioIntelQueue >= MAX_QUEUE then
        table.remove(modData.radioIntelQueue, 1)
    end

    table.insert(modData.radioIntelQueue, {
        x = eventData.x,
        y = eventData.y,
        type = eventData.eventType,
        id = tostring(os.time()) .. "_" .. tostring(ZombRand(100)),
        timestamp = eventData.worldAge
    })

    Utils.LogInfo("[Server] Queued radio intel: " .. eventData.eventType .. " at " .. eventData.x .. "," .. eventData.y)
end

---Main pipeline
---@param eventData table
function ReactiveSE_Server.ProcessEvent(eventData)
    if not eventData then return end

    -- 1. Local Execution (Singleplayer or Host)
    -- If there is a local player, execute event immediately
    -- Utils.ExecuteEvent handles local player check
    Utils.ExecuteEvent(eventData)

    -- 2. Broadcast to remote clients (real server only)
    -- If SP, no broadcast needed
    if isServer() and not isSP then
        ReactiveSE_Server.BroadcastEvent(eventData)
    end

    -- 3. Queue for Dedicated Server radio (SceneManager is disabled there)
    local isDedicated = isServer() and not isClient() and not isSP
    if isDedicated then
        ReactiveSE_Server.QueueRadioIntel(eventData)
    end
end

--//////////////////////////////////////////////////--
--          Player Reference                     --
--//////////////////////////////////////////////////--

---Gets reference player
---@return IsoPlayer|nil
function ReactiveSE_Server.GetReferencePlayer()
    return Utils.GetReferencePlayer()
end

--//////////////////////////////////////////////////--
--          Event Tick (Orchestrator)             --
--//////////////////////////////////////////////////--

---Generates and processes a normal event
local function processNormalEvent()
    local player = Utils.GetReferencePlayer()
    if not player then
        Utils.LogWarning("[Server] No reference player available for event generation")
        return
    end

    local eventData = EventGenerator.GenerateNormalEvent(player)
    if not eventData then
        Utils.LogWarning("[Server] Failed to generate normal event")
        return
    end

    local isValid, error = EventGenerator.ValidateEventData(eventData)
    if not isValid then
        Utils.LogError("[Server] Invalid event data: " .. tostring(error))
        return
    end

    ReactiveSE_Server.ProcessEvent(eventData)
    Utils.LogInfo("[Server] Normal event processed successfully")
end

---Generates and processes a weather event
local function processWeatherEvent()
    local player = Utils.GetReferencePlayer()
    if not player then
        Utils.LogWarning("[Server] No reference player available for weather event")
        return
    end

    local eventData = EventGenerator.GenerateWeatherEvent(player)
    if not eventData then
        Utils.LogError("[Server] Failed to generate weather event")
        return
    end

    local isValid, error = EventGenerator.ValidateEventData(eventData)
    if not isValid then
        Utils.LogError("[Server] Invalid weather event data: " .. tostring(error))
        return
    end

    ReactiveSE_Server.ProcessEvent(eventData)
    Utils.LogInfo("[Server] Weather event processed successfully")
end

---Main scheduler tick handler (every 10 minutes)
local function onSchedulerTick()
    if not ReactiveSE_State or not ReactiveSE_State.initialized then
        Utils.LogWarning("[Server] Shared initialization not complete!")
        return
    end
    Utils.LogInfo("[Server] Scheduler Tick executed")

    -- Check weather events (independent of main cooldown)
    if EventScheduler.ShouldTriggerWeatherEvent() then
        processWeatherEvent()
    end

    -- Check regular events
    if EventScheduler.ShouldTriggerEvent() then
        processNormalEvent()
    end
end

--//////////////////////////////////////////////////--
--          Events                                --
--//////////////////////////////////////////////////--

local function onServerStarted()
    if initializeServer() then
        -- Register the scheduler tick
        Events.EveryTenMinutes.Add(onSchedulerTick)
        Utils.LogInfo("[Server/Scheduler] Registered EveryTenMinutes hook")
    end
end

if isServer() then
    Events.OnServerStarted.Add(onServerStarted)
else
    Events.OnGameStart.Add(onServerStarted)
end

return ReactiveSE_Server
