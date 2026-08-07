--//////////////////////////////////////////////////--
--    Reactive Sound Events - Sound Library
--    Sound library and clip selection
--//////////////////////////////////////////////////--

local Constants               = require "ReactiveSE/ReactiveSE_Constants"
local Utils                   = require "ReactiveSE/ReactiveSE_Utils"

local ReactiveSE_SoundLibrary = {}

--//////////////////////////////////////////////////--
--          Sound Arrays                          --
--//////////////////////////////////////////////////--

local soundArrays             = {
    Animal = { "Animal1", "Animal2", "Animal3" },

    Gunfight = {
        "Gunfight1", "Gunfight2", "Gunfight3", "Gunfight4", "Gunfight5",
        "Gunfight6", "Gunfight7", "Gunfight8", "Gunfight9", "Gunfight10",
        "Gunfight11", "Gunfight12"
    },

    Gunshot = {
        "Gunshot1", "Gunshot2", "Gunshot3", "Gunshot4", "Gunshot5",
        "Gunshot6", "Gunshot7", "Gunshot8", "Gunshot9", "Gunshot10",
        "Gunshot11"
    },

    Scream = { "Screams1", "Screams2", "Screams3" },

    VehicleCrash = { "VehicleCC1", "VehicleCC2", "VehicleCC3" },

    Weather = {
        "Weather1", "Weather2", "Weather3", "Weather4",
        "Weather5", "Weather6", "Weather7", "Weather8"
    },

    Zombie = { "Zombies1", "Zombies2", "Zombies3" }
}

-- Fallback clips
local fallbackClips           = { "Screams1", "Zombies1", "Animal1" }

--//////////////////////////////////////////////////--
--          Internal Functions                    --
--//////////////////////////////////////////////////--

---Selects a random clip avoiding the last used ones
---@param array table
---@param lastClips table
---@return string
local function selectClipFromArray(array, lastClips)
    if not array or #array == 0 then
        return fallbackClips[ZombRand(1, #fallbackClips + 1)]
    end

    -- If array has few elements, we cannot avoid repetitions
    if #array <= Constants.CLIP_HISTORY_SIZE then
        return array[ZombRand(1, #array + 1)]
    end

    local clip
    local attempts = 0

    repeat
        clip = array[ZombRand(1, #array + 1)]
        attempts = attempts + 1

        -- Check if not in last used
        local isInHistory = false
        for i = 1, Constants.CLIP_HISTORY_SIZE do
            if lastClips[i] == clip then
                isInHistory = true
                break
            end
        end

        if not isInHistory then
            break
        end
    until attempts >= Constants.MAX_ATTEMPTS

    return clip
end

---Updates used clip history
---@param lastClips table
---@param newClip string
---@return table
local function updateClipHistory(lastClips, newClip)
    local newHistory = Utils.ShallowCopy(lastClips)

    -- Shift: move everything one position
    for i = Constants.CLIP_HISTORY_SIZE, 2, -1 do
        newHistory[i] = newHistory[i - 1]
    end

    newHistory[1] = newClip

    return newHistory
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Gets a clip for an event type
---@param eventType string
---@param lastClips table
---@return string clipName
---@return table updatedHistory
function ReactiveSE_SoundLibrary.GetClip(eventType, lastClips)
    lastClips = lastClips or {}

    local array = soundArrays[eventType]

    if not array then
        Utils.LogWarning("[SoundLibrary] Unknown event type: " .. tostring(eventType) .. ", using fallback")
        local fallback = fallbackClips[ZombRand(1, #fallbackClips + 1)]
        return fallback, updateClipHistory(lastClips, fallback)
    end

    local clip = selectClipFromArray(array, lastClips)
    local newHistory = updateClipHistory(lastClips, clip)

    return clip, newHistory
end

return ReactiveSE_SoundLibrary
