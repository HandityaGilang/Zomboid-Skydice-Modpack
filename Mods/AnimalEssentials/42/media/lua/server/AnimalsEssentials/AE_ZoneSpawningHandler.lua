local AE_ZoneSpawningHandler = {}

-- Load the shared zone spawning core
local AE_ZoneSpawningCore = require("AnimalsEssentials/AE_ZoneSpawningCore")
local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

-- Environment-aware event registration and system startup
function AE_ZoneSpawningHandler.Initialize()
    print("[AE_ZoneSpawning] SERVER: Setting up event handlers")
    
    -- Initialize system on game start
    AE_ZoneSpawningCore.initialize()
    
    local function registerPlayerEvents()
        if Events.OnPlayerConnect then
            Events.OnPlayerConnect.Add(AE_ZoneSpawningCore.onPlayerJoin)
            if AE_EnvironmentDetector.isMultiplayer() then
                print("[AE_ZoneSpawning] OnPlayerConnect registered (MP)")
            else
                print("[AE_ZoneSpawning] OnPlayerConnect registered (SP - will not fire)")
            end
        else
            print("[AE_ZoneSpawning] WARNING - Events.OnPlayerConnect not available")
        end
    end
    
    -- Environment-aware timer event registration
    local function registerTimerEvents()
        if Events.EveryHours then
            Events.EveryHours.Add(AE_ZoneSpawningCore.onTimerCheck)
            print("[AE_ZoneSpawning] Timer check registered - every hour")
        else
            print("[AE_ZoneSpawning] WARNING - Events.EveryHours not available")
        end
    end
    
    -- Execute registrations with safety
    local success, result = pcall(function()
        registerPlayerEvents()
        registerTimerEvents()
        return true
    end)
    
    if not success then
        print("[AE_ZoneSpawning] ERROR: Event registration failed: " .. tostring(result))
    end
end

-- Register initialization on game start
Events.OnGameStart.Add(AE_ZoneSpawningHandler.Initialize)

return AE_ZoneSpawningHandler