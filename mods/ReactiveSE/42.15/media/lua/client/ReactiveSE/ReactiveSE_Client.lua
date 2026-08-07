--//////////////////////////////////////////////////--
--    Reactive Sound Events - Client Main
--    Client specific initialization and coordination
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"

local ReactiveSE_Client = {}

--//////////////////////////////////////////////////--
--          Client Initialization                 --
--//////////////////////////////////////////////////--

---Client specific initialization
---@return boolean success
local function initializeClient()
    if not ReactiveSE_State or not ReactiveSE_State.initialized then
        Utils.LogWarning("[Client] Shared initialization not complete!")
        return false
    end

    Utils.LogInfo("[Client] Client-side initialization starting...")

    -- On clients, we wait for server commands
    if isClient() and not isServer() then
        Utils.LogInfo("[Client] Client will wait for events from server")
    else
        Utils.LogInfo("[Client] Running in singleplayer or host mode")
    end

    Utils.LogInfo("[Client] Client initialization complete")
    return true
end

--//////////////////////////////////////////////////--
--          Client Functions                      --
--//////////////////////////////////////////////////--

-- Event execution functions are now centralized in ReactiveSE_Utils
-- The client uses ReactiveSE_ClientCommands to receive events from the server
-- and ReactiveSE_Utils.ExecuteEvent to execute them.

--//////////////////////////////////////////////////--
--          Events                                --
--//////////////////////////////////////////////////--

local function onGameStart()
    initializeClient()
end

Events.OnGameStart.Add(onGameStart)
