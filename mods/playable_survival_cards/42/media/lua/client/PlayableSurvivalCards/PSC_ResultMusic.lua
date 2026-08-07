PSC_ResultMusic = PSC_ResultMusic or {
    handle = nil,
    volume = 0.55,
    owner = nil,
}

local function uiEmitter()
    if not getSoundManager then return nil end
    local manager = getSoundManager()
    return manager and manager.getUIEmitter and manager:getUIEmitter() or nil
end

function PSC_ResultMusic.stop(owner)
    if owner and PSC_ResultMusic.owner and owner ~= PSC_ResultMusic.owner then
        return
    end
    local emitter = uiEmitter()
    if PSC_ResultMusic.handle and emitter and emitter.stopSoundLocal then
        pcall(function()
            emitter:stopSoundLocal(PSC_ResultMusic.handle)
        end)
    end
    PSC_ResultMusic.handle = nil
    PSC_ResultMusic.owner = nil
end

function PSC_ResultMusic.play(owner)
    local emitter = uiEmitter()
    if PSC_ResultMusic.handle and PSC_ResultMusic.owner == owner and emitter then
        local ok, playing = pcall(function()
            return emitter:isPlaying(PSC_ResultMusic.handle)
        end)
        if ok and playing then return end
        PSC_ResultMusic.handle = nil
        PSC_ResultMusic.owner = nil
    end
    PSC_ResultMusic.stop()
    emitter = uiEmitter()
    if not emitter or not emitter.playSoundLoopedImpl then return end
    local ok, handle = pcall(function()
        local sound = emitter:playSoundLoopedImpl("PSCVictoryMusic")
        if sound and emitter.set3D then emitter:set3D(sound, false) end
        if sound and emitter.setVolume then emitter:setVolume(sound, PSC_ResultMusic.volume) end
        return sound
    end)
    if ok and handle and handle ~= 0 then
        PSC_ResultMusic.handle = handle
        PSC_ResultMusic.owner = owner
    end
end
