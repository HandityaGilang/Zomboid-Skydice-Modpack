if isServer() then return end

local TABAS_Sounds = {}

local _Core = nil

local function getOptionVol01()
    if not _Core then
        _Core = getCore()
    end
    local v10 = _Core:getOptionSoundVolume() or 5
    return v10 * 0.1
end

function TABAS_Sounds.playPlayerVoiceSound(player, soundName)
    local sound = player:playerVoiceSound(soundName)
    if sound then
        player:getEmitter():setVolume(sound, getOptionVol01())
    end
    return sound
end

function TABAS_Sounds.playPlayerSound(player, soundName)
    local sound = player:playSound(soundName)
    if sound then
        player:getEmitter():setVolume(sound, getOptionVol01())
    end
    return sound
end

function TABAS_Sounds.playPlayerLoopSound(player, soundName)
    local emitter = player:getEmitter()
    local sound = emitter:playSoundLooped(soundName)
    if sound then
        emitter:setVolume(sound, getOptionVol01())
    end
    return sound
end

function TABAS_Sounds.playEmitterSoundImpl(emitter, soundName, owner)
    if not owner then return nil end
    local sound = emitter:playSoundImpl(soundName, owner)
    if sound then
        emitter:setVolume(sound, getOptionVol01())
    end
    return sound
end

function TABAS_Sounds.playEmitterSoundLoopedImpl(emitter, soundName)
    local sound = emitter:playSoundLoopedImpl(soundName)
    if sound then
        emitter:setVolume(sound, getOptionVol01())
    end
    return sound
end

function TABAS_Sounds.applyVolume(emitter, sound, mul)
    if not emitter or not sound then return end
    mul = mul or 1.0
    emitter:setVolume(sound, getOptionVol01() * mul)
end

return TABAS_Sounds