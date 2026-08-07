WPSound = WPSound or {}

WPSound.globalEmitters = {}

WPSound.AddToObject = function(object, sound, volume)
    local x, y, z = object:getX(), object:getY(), object:getZ()
    local id = WPUtils.Coords2Id(x, y, z)

    if not WPSound.globalEmitters[id] then
        local emitter = getWorld():getFreeEmitter(x, y, z)
        local baseVolume = getSoundManager():getSoundVolume()

        WPSound.globalEmitters[id] = emitter
        emitter:playSound(sound)
        emitter:setVolumeAll(baseVolume * volume)
    end

    
end

WPSound.RemoveFromObject = function(object)
    local x, y, z = object:getX(), object:getY(), object:getZ()
    local id = WPUtils.Coords2Id(x, y, z)
    
    if WPSound.globalEmitters[id] then
        local emitter = WPSound.globalEmitters[id]
        emitter:stopAll()
        WPSound.globalEmitters[id] = nil
    end
end
