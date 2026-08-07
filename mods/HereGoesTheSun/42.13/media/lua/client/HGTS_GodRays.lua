-- HGTS_GodRays.lua (client)
-- Client-only render effect. Reads sandbox option:
--   HereGoesTheSun.EnableGodRays

local function HGTS_IsGodRaysEnabled()
    local so = getSandboxOptions()
    if not so then return true end

    local opt = so:getOptionByName("HereGoesTheSun.EnableGodRays")
    if not opt then return true end
    local v = opt:getValue()
    return v == true or v == 1
end

local sunshineE_Tex, sunshineW_Tex = nil, nil
local sunshineE_Alpha, sunshineW_Alpha = 0, 0
local screenWidth, screenHeight = getCore():getScreenWidth(), getCore():getScreenHeight()

local function HGTS_EnsureTexturesLoaded()
    if sunshineE_Tex and sunshineW_Tex then return end
    sunshineE_Tex = getTexture("media/sunshine/SunshineEast.png")
    sunshineW_Tex = getTexture("media/sunshine/SunshineWest.png")
end

local function HGTS_Sunshine()
    -- Toggle sandbox
    if not HGTS_IsGodRaysEnabled() then return end

    HGTS_EnsureTexturesLoaded()
    if not sunshineE_Tex or not sunshineW_Tex then return end

    local player = getSpecificPlayer(0)
    if not player or not player:isOutside() then return end

    local cm = getClimateManager()
    local gt = getGameTime()
    if not cm or not gt then return end

    local season = cm:getSeason()
    if not season then return end

    local nowTime = gt:getHour() + (gt:getMinutes() / 60)
    local dawnTime = season:getDawn()
    local duskTime = season:getDusk()

    local speed = 0.003 * getGameSpeed()

    -- Atenuadores naturales (nubes/niebla/ambiente)
    local cloud = cm:getCloudIntensity()
    local fog = cm:getFogIntensity()
    local ambient = cm:getAmbient()
    local dim = cloud + fog + (1 - ambient)

    local zoom = getCore():getZoom(player:getPlayerNum())
    zoom = PZMath.clampFloat(zoom, 0.0, 1.0)

    -- Amanecer (Este): ventana de 4 horas después del dawn
    if nowTime >= dawnTime and nowTime < dawnTime + 4 then
        sunshineE_Alpha = PZMath.lerp(sunshineE_Alpha, 1, speed)
    else
        sunshineE_Alpha = PZMath.lerp(sunshineE_Alpha, 0, speed)
    end

    -- Atardecer (Oeste): ventana de 4 horas centrada en dusk
    if nowTime < duskTime + 2 and nowTime > duskTime - 2 then
        sunshineW_Alpha = PZMath.lerp(sunshineW_Alpha, 1, speed)
    else
        sunshineW_Alpha = PZMath.lerp(sunshineW_Alpha, 0, speed)
    end

    local alphaW = sunshineW_Alpha - dim
    local alphaE = sunshineE_Alpha - dim

    if alphaW > 0 then
        UIManager.DrawTexture(sunshineW_Tex, 0, 0, screenWidth * zoom, screenHeight * zoom, alphaW)
    end

    local offsetX = math.abs((screenWidth * zoom) - screenWidth)
    local offsetY = math.abs((screenHeight * zoom) - screenHeight)

    if alphaE > 0 then
        UIManager.DrawTexture(sunshineE_Tex, offsetX, offsetY, screenWidth * zoom, screenHeight * zoom, alphaE)
    end
end

Events.OnPreUIDraw.Add(HGTS_Sunshine)

local function HGTS_OnResolutionChange(w, h)
    screenWidth = w
    screenHeight = h
end

Events.OnResolutionChange.Add(HGTS_OnResolutionChange)
