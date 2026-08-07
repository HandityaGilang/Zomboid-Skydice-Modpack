--//////////////////////////////////////////////////--
--    Reactive Sound Events - Server Commands
--    Handling commands received from clients
--//////////////////////////////////////////////////--

if not isServer() then return end

local Utils                     = require "ReactiveSE/ReactiveSE_Utils"
local Constants                 = require "ReactiveSE/ReactiveSE_Constants"
local Scheduler                 = require "ReactiveSE/ReactiveSE_EventScheduler"
local CorpseSpawner             = require "ReactiveSE/ReactiveSE_CorpseSpawner"

local ReactiveSE_ServerCommands = {}

--//////////////////////////////////////////////////--
--          Command Handlers                      --
--//////////////////////////////////////////////////--

---Handler for client commands
---@param module string
---@param command string
---@param playerObj IsoPlayer
---@param args table
local function onClientCommand(module, command, playerObj, args)
    if module ~= Constants.MOD_ID then return end

    -- For now we don't need client specific commands
    -- But it's prepared for future expansions

    Utils.LogInfo("[ServerCommands] Received client command: " ..
    command .. " from player: " .. tostring(playerObj:getUsername()))
end

---Sends scheduler status to a specific client
---@param player IsoPlayer
function ReactiveSE_ServerCommands.SendEventStatus(player)
    if not player then return end

    local status = Scheduler.GetStatus()

    sendServerCommand(
        player,
        Constants.MOD_ID,
        "EventStatus",
        status
    )

    Utils.LogInfo("[ServerCommands] Event status sent to player: " .. tostring(player:getUsername()))
end

---Sends synchronized ModData to all clients
function ReactiveSE_ServerCommands.SyncModData()
    local modData = ReactiveSE_Initialize.GetModData()

    local syncData = {
        totalEvents = modData.totalEvents,
        lastEventType = modData.lastEventType,
        lastEventTime = modData.lastEventTime
    }

    sendServerCommand(
        Constants.MOD_ID,
        Constants.NetworkCommands.SYNC_MODDATA,
        syncData
    )

    Utils.LogInfo("[ServerCommands] ModData synced to all clients")
end

--//////////////////////////////////////////////////--
--          Events                                --
--//////////////////////////////////////////////////--

Events.OnClientCommand.Add(onClientCommand)
