--//////////////////////////////////////////////////--
--    Reactive Sound Events - Sound Player
--    Sound playback using emitters
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local Config = require "ReactiveSE/ReactiveSE_Config"

local ReactiveSE_SoundPlayer = {}

--//////////////////////////////////////////////////--
--          Sound Playback                        --
--//////////////////////////////////////////////////--

---Plays a sound at a specific position
---@param eventData table
function ReactiveSE_SoundPlayer.PlaySound(eventData)
    if not eventData then
        Utils.LogError("[SoundPlayer] Cannot play sound: eventData is nil")
        return
    end

    -- Validate consistent environment with audio (Client or SP)
    -- isClient() is true for clients and Host
    -- If Dedicated Server (Server=true, Client=false), do not play.
    if isServer() and not isClient() then
        return
    end

    -- Validate necessary data
    if not eventData.x or not eventData.y or not eventData.clip then
        Utils.LogError("[SoundPlayer] Invalid eventData for sound playback")
        return
    end

    -- Get free emitter
    local world = getWorld()
    if not world then
        Utils.LogError("[SoundPlayer] World not available")
        return
    end

    local emitter = world:getFreeEmitter()
    if not emitter then
        Utils.LogWarning("[SoundPlayer] No free emitter available")
        return
    end

    -- Configure and play
    emitter:setPos(eventData.x, eventData.y, 0)
    emitter:playAmbientSound(eventData.clip)

    -- If enabled, let zombies hear
    local config = Config.Get()
    if config.enableZombieHearing and eventData.radius then
        local WorldSoundManager = getWorldSoundManager()
        if WorldSoundManager then
            WorldSoundManager:addSound(
                nil,
                eventData.x,
                eventData.y,
                0,
                eventData.radius,
                eventData.radius
            )
        end
    end

    Utils.LogInfo("[SoundPlayer] Sound played: " .. eventData.clip .. " at (" ..
        eventData.x .. ", " .. eventData.y .. ")")
end

return ReactiveSE_SoundPlayer
