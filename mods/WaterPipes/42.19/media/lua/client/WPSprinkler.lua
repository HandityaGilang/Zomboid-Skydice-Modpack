WPSprinkler = WPSprinkler or {}

WPSprinkler.tab = {}
WPSprinkler.tick = 0

WPSprinkler.initFrame = 1 -- unused
WPSprinkler.startFrame = 360
WPSprinkler.endFrame = 720
WPSprinkler.size = 1600

-- cached textures
WPSprinkler.textures = {}
for i = WPSprinkler.startFrame, WPSprinkler.endFrame do
    local frameStr = string.format("%03d", i)
    WPSprinkler.textures[i] = getTexture("media/textures/FX/sprinkler/" ..  WPSprinkler.size .. "/" .. frameStr .. ".png")
end

-- precomputer mathdata
WPSprinkler.mathtab = {}
for i = WPSprinkler.startFrame, WPSprinkler.endFrame do
    local angle = i - WPSprinkler.startFrame
    local theta = angle * 0.0174533
    WPSprinkler.mathtab[i] = {
        theta = theta,
        cosT = math.cos(theta),
        sinT = math.sin(theta),
    }
end

WPSprinkler.Destroy = function(id)
    if WPSprinkler.tab[id] then
        local effect = WPSprinkler.tab[id]
        if effect then
            if effect.emitter1 then
                effect.emitter1:stopAll()
                effect.emitter1:setVolumeAll(0)
                effect.emitter1 = nil
            end
            if effect.emitter2 then
                effect.emitter2:stopAll()
                effect.emitter2:setVolumeAll(0)
                effect.emitter2 = nil
            end
        end
        WPSprinkler.tab[id] = nil
    end
end

WPSprinkler.Process = function()
    if not isIngameState() then return end
    if isServer() then return end

    local player = getSpecificPlayer(0)
    if player == nil then return end

    if getCore():getOptionUIRenderFPS() ~= 60 then
        getCore():setOptionUIRenderFPS(60)
    end

    local world = getWorld()
    local cm = world:getClimateManager()
    local playerNum = player:getPlayerNum()
    local px, py = player:getX(), player:getY()
    local zoom = getCore():getZoom(playerNum)
    local volume = getSoundManager():getSoundVolume()
    local volumeRain = volume * 0.7
    local volumeHiss = volume * 0.5

    local mathtab = WPSprinkler.mathtab
    local gmd = GetWPModData()

    local dls = cm:getDayLightStrength() / 2
    if dls == 0 then dls = 0.05 end

    for id, sprinkler in pairs(gmd.Sprinklers) do

        local effect = WPSprinkler.tab[id]
        if not effect then
            effect = {
                x = sprinkler.x,
                y = sprinkler.y,
                z = sprinkler.z,
                frame = WPSprinkler.startFrame + ZombRand(WPSprinkler.endFrame - WPSprinkler.startFrame),
                water = 0,
                _gen = -1,
            }
            WPSprinkler.tab[id] = effect
        end

        if not effect._gen then effect._gen = -1 end
        if sprinkler.gen and sprinkler.gen ~= effect._gen then
            effect.water = sprinkler.w
            effect._gen = sprinkler.gen
        end

        if effect.water > 0 then

            if math.abs(sprinkler.x - px) < 60 and math.abs(sprinkler.y - py) < 60 then
                local cosT = mathtab[effect.frame].cosT
                local sinT = mathtab[effect.frame].sinT

                if not effect.emitter1 then
                    effect.emitter1 = getWorld():getFreeEmitter(sprinkler.x, sprinkler.y, sprinkler.z)
                    effect.emitter1:playSoundLooped("WPSprinklerHiss")
                end
                if not effect.emitter2 then
                    effect.emitter2 = getWorld():getFreeEmitter(sprinkler.x, sprinkler.y, sprinkler.z)
                    effect.emitter2:playSoundLooped("WPSprinklerRain")
                end

                --[[
                if not effect.emitter1:isPlaying("WPSprinklerHiss") then
                    effect.emitter1:playSoundLooped("WPSprinklerHiss")
                end
                if not effect.emitter2:isPlaying("WPSprinklerRain") then
                    effect.emitter2:playSoundLooped("WPSprinklerRain")
                end]]

                if WPSprinkler.tick % 8 == 0 then
                    effect.emitter1:setVolumeAll(volumeHiss)
                    effect.emitter2:setVolumeAll(volumeRain)
                end

                local lx = effect.x + (6 * cosT)
                local ly = effect.y + (6 * sinT)
                effect.emitter2:setPos(lx, ly, effect.z)

                local size = WPSprinkler.size / zoom
                local offset = size / 2
                local tx = isoToScreenX(playerNum, effect.x, effect.y, effect.z) - offset + (24 / zoom)
                local ty = isoToScreenY(playerNum, effect.x, effect.y, effect.z) - offset - (8 / zoom)

                local tex = WPSprinkler.textures[effect.frame]
                if tex then
                    UIManager.DrawTexture(tex, tx, ty, size, size, dls)
                end
            end

            if WPSprinkler.tick % 2 == 1 then
                effect.frame = effect.frame + 1
                if effect.frame > WPSprinkler.endFrame then
                    effect.frame = WPSprinkler.startFrame
                end

                effect.water = effect.water - 1
            end
        else
            local effect = WPSprinkler.tab[id]
            if effect then
                if effect.emitter1 then
                    effect.emitter1:setVolumeAll(0)
                end
                if effect.emitter2 then
                    effect.emitter2:setVolumeAll(0)
                end
            end
        end
    end

    WPSprinkler.tick = WPSprinkler.tick + 1
    if WPSprinkler.tick == 33 then WPSprinkler.tick = 0 end
end

Events.OnPreUIDraw.Add(WPSprinkler.Process)
