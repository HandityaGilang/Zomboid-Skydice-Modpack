---@diagnostic disable: undefined-field, inject-field
--//////////////////////////////////////////////////--
--    Reactive Sound Events - Marker Handler
--    Manages sound indicator lifecycle
--//////////////////////////////////////////////////--

require "ReactiveSE/ReactiveSE_SoundMarker"

local Config                         = require "ReactiveSE/ReactiveSE_Config"
local ModConfig                      = require "ReactiveSE/ReactiveSE_ModOptions"
local Utils                          = require "ReactiveSE/ReactiveSE_Utils"

local ReactiveSE_MarkerHandler       = {}

-- State
ReactiveSE_MarkerHandler.markers     = {} -- [playerIndex] = marker
ReactiveSE_MarkerHandler.initialized = false

-- Default duration for markers (in seconds, will be converted to tick updates)
local DEFAULT_MARKER_DURATION        = 60
local SCENE_NOTIFY_DURATION          = 30

--//////////////////////////////////////////////////--
--          Initialization                         --
--//////////////////////////////////////////////////--

---Initializes the handler and subscribes to events
function ReactiveSE_MarkerHandler.Initialize()
    if ReactiveSE_MarkerHandler.initialized then return end

    -- Subscribe to the custom sound event
    if Events.OnReactiveSoundEvent then
        Events.OnReactiveSoundEvent.Add(ReactiveSE_MarkerHandler.OnSoundEvent)
        Utils.LogInfo("[MarkerHandler] Subscribed to OnReactiveSoundEvent")
    else
        Utils.LogWarning("[MarkerHandler] OnReactiveSoundEvent not found")
    end

    -- Subscribe to scene spawn notifications
    if Events.OnSceneSpawned then
        Events.OnSceneSpawned.Add(ReactiveSE_MarkerHandler.OnSceneSpawned)
        Utils.LogInfo("[MarkerHandler] Subscribed to OnSceneSpawned")
    end

    -- Add tick update for duration countdown
    Events.OnTick.Add(ReactiveSE_MarkerHandler.OnTick)

    ReactiveSE_MarkerHandler.initialized = true
    Utils.LogInfo("[MarkerHandler] Initialized")
end

--//////////////////////////////////////////////////--
--          Event Handling                         --
--//////////////////////////////////////////////////--

---Called when a sound event occurs
---@param eventData table
function ReactiveSE_MarkerHandler.OnSoundEvent(eventData)
    if not eventData then return end

    -- Check ModOptions for indicator enabled
    if ModConfig.IndicatorEnabled == false then
        return
    end

    -- Skip marker for weather events (thunder is ambient, not directional)
    if eventData.eventType == "Weather" then
        Utils.LogInfo("[MarkerHandler] Skipping marker for Weather event (ambient sound)")
        return
    end

    -- Get position from event data
    local posX = eventData.x
    local posY = eventData.y

    if not posX or not posY then
        Utils.LogWarning("[MarkerHandler] Event missing position data")
        return
    end

    -- Get marker duration from ModConfig (fallback to default)
    local duration = ModConfig.SoundMarkerDuration or DEFAULT_MARKER_DURATION
    local eventType = eventData.eventType

    -- Show marker for all active players (split-screen support)
    local numPlayers = getNumActivePlayers()
    for i = 0, numPlayers - 1 do
        local player = getSpecificPlayer(i)
        if player then
            ReactiveSE_MarkerHandler.ShowMarker(player, i, posX, posY, duration, eventType)
        end
    end
end

---Called when a scene spawns nearby (for scene spawn notifications)
---@param sceneData table
function ReactiveSE_MarkerHandler.OnSceneSpawned(sceneData)
    if not sceneData then return end

    local posX = sceneData.x
    local posY = sceneData.y

    if not posX or not posY then
        return
    end

    -- Get marker duration from ModConfig (fallback to default)
    local duration = ModConfig.SceneMarkerDuration or SCENE_NOTIFY_DURATION

    -- Show marker for all active players with shorter duration
    local numPlayers = getNumActivePlayers()
    for i = 0, numPlayers - 1 do
        local player = getSpecificPlayer(i)
        if player then
            ReactiveSE_MarkerHandler.ShowMarker(player, i, posX, posY, duration, sceneData.type)
        end
    end

    Utils.LogInfo("[MarkerHandler] Scene spawn marker shown for " .. (sceneData.type or "Unknown"))
end

---Shows or updates a marker for a player
---@param player IsoPlayer
---@param playerIndex number
---@param posX number
---@param posY number
---@param duration number
---@param eventType string|nil
function ReactiveSE_MarkerHandler.ShowMarker(player, playerIndex, posX, posY, duration, eventType)
    local marker = ReactiveSE_MarkerHandler.markers[playerIndex]

    -- Get saved position from player mod data
    local savedPos = player:getModData()["RSE_markerPlacement"]
    local screenX = savedPos and savedPos[1] or nil
    local screenY = savedPos and savedPos[2] or nil

    if not marker then
        -- Create new marker
        marker = ReactiveSE_SoundMarker:new(duration, posX, posY, player, screenX, screenY)
        marker.maxRange = Config.Get().maxRange or 600
        marker:setEventType(eventType)
        ReactiveSE_MarkerHandler.markers[playerIndex] = marker
        Utils.LogInfo("[MarkerHandler] Created new marker for player " .. playerIndex)
    else
        -- Update existing marker
        marker.posX = posX
        marker.posY = posY
        marker:setDuration(duration)
        marker.maxRange = Config.Get().maxRange or 600
        marker:setEventType(eventType)
        marker:update(posX, posY)
    end

    marker:setVisible(true)
end

---Hides the marker for a player
---@param playerIndex number
function ReactiveSE_MarkerHandler.HideMarker(playerIndex)
    local marker = ReactiveSE_MarkerHandler.markers[playerIndex]
    if marker then
        marker:setDuration(0)
        marker:setVisible(false)
    end
end

--//////////////////////////////////////////////////--
--          Tick Update                            --
--//////////////////////////////////////////////////--

local tickCounter = 0
local TICKS_PER_SECOND = 30 -- Approximate ticks per second

---Called every game tick
function ReactiveSE_MarkerHandler.OnTick()
    tickCounter = tickCounter + 1

    -- Update roughly once per second
    if tickCounter < TICKS_PER_SECOND then return end
    tickCounter = 0

    -- Update all markers
    for playerIndex, marker in pairs(ReactiveSE_MarkerHandler.markers) do
        if marker and marker:getDuration() > 0 then
            -- Decrement duration
            marker:setDuration(marker:getDuration() - 1)

            -- Update marker state
            marker:update()

            -- Hide if expired
            if marker:getDuration() <= 0 then
                marker:setVisible(false)
            end
        end
    end
end

--//////////////////////////////////////////////////--
--          Events                                 --
--//////////////////////////////////////////////////--

Events.OnGameStart.Add(ReactiveSE_MarkerHandler.Initialize)

return ReactiveSE_MarkerHandler
