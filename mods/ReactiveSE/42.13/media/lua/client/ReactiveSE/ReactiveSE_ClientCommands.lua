--//////////////////////////////////////////////////--
--    Reactive Sound Events - Client Commands
--    Handling commands received from the server
--//////////////////////////////////////////////////--

local Constants                 = require "ReactiveSE/ReactiveSE_Constants"
local Utils                     = require "ReactiveSE/ReactiveSE_Utils"

local ReactiveSE_ClientCommands = {}

--//////////////////////////////////////////////////--
--          Command Handlers                      --
--//////////////////////////////////////////////////--

---Handler for sound event
---@param eventData table
function ReactiveSE_ClientCommands.HandlePlaySoundEvent(eventData)
    if not eventData then
        Utils.LogError("[ClientCommands] Received nil eventData from server")
        return
    end

    Utils.LogInfo("[ClientCommands] Received sound event from server: " ..
        tostring(eventData.eventType) .. " (" .. tostring(eventData.clip) .. ")")

    -- Execute event using shared logic
    Utils.ExecuteEvent(eventData)
end

---Handler for ModData synchronization
---@param syncData table
function ReactiveSE_ClientCommands.HandleModDataSync(syncData)
    if not syncData then return end

    Utils.LogInfo("[ClientCommands] Received ModData sync from server")

    local modData = ReactiveSE_Initialize.GetModData()

    -- Update synchronized data
    if syncData.totalEvents then
        modData.totalEvents = syncData.totalEvents
    end

    if syncData.lastEventType then
        modData.lastEventType = syncData.lastEventType
    end

    if syncData.lastEventTime then
        modData.lastEventTime = syncData.lastEventTime
    end
end

---Handler for event status
---@param status table
function ReactiveSE_ClientCommands.HandleEventStatus(status)
    if not status then return end

    Utils.LogInfo("[ClientCommands] Received event status from server")
end

---Handler for radio intel broadcast from server
---@param intelData table
function ReactiveSE_ClientCommands.HandleRadioIntel(intelData)
    if not intelData then return end

    Utils.LogInfo("[ClientCommands] Received radio intel from server: " ..
        tostring(intelData.x) .. "," .. tostring(intelData.y))

    -- Fire local event which RadioMarkers listens to
    if Events.OnKnoxRelayMarker then
        triggerEvent("OnKnoxRelayMarker",
            intelData.x,
            intelData.y,
            intelData.sceneType,
            intelData.sceneID
        )
    end
end

--//////////////////////////////////////////////////--
--          Client Request Functions              --
--//////////////////////////////////////////////////--

---Requests scheduler status from the server
function ReactiveSE_ClientCommands.RequestEventStatus()
    if not isClient() then
        Utils.LogWarning("[ClientCommands] Cannot request event status: not a client")
        return
    end

    sendClientCommand(
        Constants.MOD_ID,
        "RequestEventStatus",
        {}
    )

    Utils.LogInfo("[ClientCommands] Event status requested from server")
end

--//////////////////////////////////////////////////--
--          Command Dispatcher                    --
--//////////////////////////////////////////////////--

---Main dispatcher for server commands
---@param module string
---@param command string
---@param args table
local function onServerCommand(module, command, args)
    if module ~= Constants.MOD_ID then return end

    if command == Constants.NetworkCommands.PLAY_SOUND_EVENT then
        ReactiveSE_ClientCommands.HandlePlaySoundEvent(args)
    elseif command == Constants.NetworkCommands.SYNC_MODDATA then
        ReactiveSE_ClientCommands.HandleModDataSync(args)
    elseif command == Constants.NetworkCommands.RADIO_INTEL then
        ReactiveSE_ClientCommands.HandleRadioIntel(args)
    elseif command == "EventStatus" then
        ReactiveSE_ClientCommands.HandleEventStatus(args)
    else
        Utils.LogWarning("[ClientCommands] Unknown server command: " .. command)
    end
end

--//////////////////////////////////////////////////--
--          Events                                --
--//////////////////////////////////////////////////--

Events.OnServerCommand.Add(onServerCommand)
