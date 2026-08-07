UNM_Music = UNM_Music or {
    enabled = true,
    volume = 0.4,
    handle = nil,
    alias = nil,
    owner = nil,
}

local function uiEmitter()
    if not getSoundManager then return nil end
    local manager = getSoundManager()
    return manager and manager.getUIEmitter and manager:getUIEmitter() or nil
end

function UNM_Music.stop(owner)
    if owner and UNM_Music.owner and owner ~= UNM_Music.owner then
        return
    end
    local emitter = uiEmitter()
    if UNM_Music.handle and emitter and emitter.stopSoundLocal then
        pcall(function()
            emitter:stopSoundLocal(UNM_Music.handle)
        end)
    end
    UNM_Music.handle = nil
    UNM_Music.alias = nil
    UNM_Music.owner = nil
end

function UNM_Music.forceStop()
    UNM_Music.stop()
end

function UNM_Music.applyVolume()
    local emitter = uiEmitter()
    if UNM_Music.handle and emitter and emitter.setVolume then
        pcall(function()
            emitter:setVolume(UNM_Music.handle, UNM_Music.volume)
        end)
    end
end

function UNM_Music.play(alias, owner)
    if not UNM_Music.enabled or not alias then
        UNM_Music.stop(owner)
        return
    end
    local emitter = uiEmitter()
    if UNM_Music.handle and UNM_Music.alias == alias and UNM_Music.owner == owner and emitter then
        local ok, playing = pcall(function()
            return emitter:isPlaying(UNM_Music.handle)
        end)
        if ok and playing then
            UNM_Music.applyVolume()
            return
        end
        UNM_Music.handle = nil
        UNM_Music.alias = nil
        UNM_Music.owner = nil
    end
    UNM_Music.stop()
    emitter = uiEmitter()
    if not emitter or not emitter.playSoundLoopedImpl then return end
    local ok, handle = pcall(function()
        local sound = emitter:playSoundLoopedImpl(alias)
        if sound and emitter.set3D then
            emitter:set3D(sound, false)
        end
        return sound
    end)
    if ok and handle and handle ~= 0 then
        UNM_Music.handle = handle
        UNM_Music.alias = alias
        UNM_Music.owner = owner
        UNM_Music.applyVolume()
    end
end

function UNM_Music.setEnabled(enabled)
    UNM_Music.enabled = enabled == true
    if not UNM_Music.enabled then
        UNM_Music.stop()
    end
end

function UNM_Music.setVolume(volume)
    volume = tonumber(volume) or 0
    UNM_Music.volume = math.max(0, math.min(1, volume))
    UNM_Music.applyVolume()
end
