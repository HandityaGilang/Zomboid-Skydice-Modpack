-- Here Goes the Sun v1
-- Seasonal dusks + bright spring/summer dawns + god rays.
-- BGR color order (B, G, R, A).

print("[HCTS] Main.lua loaded")

----------------------------------------
-- Constantes básicas
----------------------------------------
local WARM, NORMAL, CLOUDY = 0, 1, 2
local SUMMER, AUTUMN, WINTER, SPRING = 0, 1, 2, 3

local lastDay = -1
local currentDuskType = "normal"

----------------------------------------
-- Paletas de color
-- OJO: B, G, R, A (BGR!) porque PZ las pide así
----------------------------------------

-- Primavera / Verano - Dusk (lo que ya tenías)
local DuskColors_SpringSummer = {
    red = {
        -- Red Sun
        out = {0.14, 0.10, 0.90, 0.82},
        inn = {0.14, 0.10, 0.85, 0.40}
    },

    golden = {
        -- Golden hour “fílmico” (ajustado con BGR correcto)
        out = {0.14, 0.46, 0.90, 0.90},
        inn  = {0.14, 0.46, 0.90, 0.50}
    },

    normal = {
        -- Clásico atardecer cálido
        out = {0.30, 0.55, 1.00, 0.55},
        inn  = {0.30, 0.55, 1.00, 0.15}
    }
}

-- Otoño - Dusk
--   Normal      #e0cbc3 (60%)
--   Golden      #e29673 (20%)
--   Amarronado  #b28066 (20%)
local DuskColors_Autumn = {
    normal = {
        -- #e0cbc3 → BGR ≈ (0.76, 0.80, 0.88)
        out = {0.76, 0.80, 0.88, 1},
        inn  = {0.76, 0.80, 0.88, 0.30}
    },
    golden = {
        -- #e29673 → BGR ≈ (0.45, 0.59, 0.89)
        out = {0.45, 0.59, 0.89, 1},
        inn  = {0.45, 0.59, 0.89, 0.40}
    },
    brown = {
        -- #b28066 → BGR ≈ (0.40, 0.50, 0.70)
        out = {0.40, 0.50, 0.70, 1},
        inn  = {0.40, 0.50, 0.70, 0.35}
    }
}

-- Invierno - Dusk
--   Normal   #d7e1f4 (30%)
--   Gris     #d4d9e3 (30%)
--   Oscuro   #232249 (20%)
--   Gélido   #677fbf (20%)
local DuskColors_Winter = {
    normal = {
        -- #d7e1f4 → BGR ≈ (0.96, 0.88, 0.84)
        out = {0.96, 0.88, 0.84, 0.75},
        inn  = {0.96, 0.88, 0.84, 0.30}
    },
    gray = {
        -- #d4d9e3 → BGR ≈ (0.89, 0.85, 0.83)
        out = {0.89, 0.85, 0.83, 1},
        inn  = {0.89, 0.85, 0.83, 0.30}
    },
    dark = {
        -- #232249 → BGR ≈ (0.29, 0.13, 0.14)
        out = {0.73, 0.17, 0.18, 0.75},
        inn  = {0.73, 0.17, 0.18, 0.45}
    },
    cold = {
        -- #677fbf → BGR ≈ (0.75, 0.50, 0.40)
        out = {0.75, 0.50, 0.40, 1},
        inn  = {0.75, 0.50, 0.40, 0.35}
    }
}

-- Amanecer despejado para primavera/verano (tu dawn “que te achina los ojos”)
-- B, G, R, A
local Dawn_Clear_SpringSummer = {
    out = {0.63, 0.89, 1.00, 0.95}, -- exterior muy brillante
    inn  = {0.55, 0.80, 0.95, 0.65} -- interior un poco más suave
}

-- Placeholders de amanecer para otoño/invierno: blanco con alpha 0
-- visualmente no hacen nada, pero dejan el hook armado
local Dawn_Autumn = {
    out = {0.45, 0.7, 1.00, 0.45},
    inn  = {0.45, 0.7, 1.00, 0.25}
}

local Dawn_Winter = {
    out = {0.96, 0.88, 0.84, 0.75},
    inn  = {0.96, 0.88, 0.84, 0.30}
}

----------------------------------------
-- Random diario (determinístico) para MP
----------------------------------------
local function getDayRand(day)
    local a, c, m = 1103515245, 12345, 2147483648
    local seed = day % m
    seed = (seed * a + c) % m
    return (seed / m) * 100
end

----------------------------------------
-- Helpers de aplicación de color
----------------------------------------
local function applyDuskForSeason(seasonIndex, palette, duskType)
    local cm = getClimateManager()
    if not cm then return end
    local colors = palette[duskType]
    if not colors then return end

    for temp = WARM, CLOUDY do
        -- Exterior
        cm:setSeasonColorDusk(
            temp, seasonIndex,
            colors.out[1], colors.out[2], colors.out[3], colors.out[4],
            true
        )
        -- Interior
        cm:setSeasonColorDusk(
            temp, seasonIndex,
            colors.inn[1], colors.inn[2], colors.inn[3], colors.inn[4],
            false
        )
    end
end

local function applyDawnForSeason(seasonIndex, dawnColors)
    local cm = getClimateManager()
    if not cm then return end

    for temp = WARM, CLOUDY do
        -- Exterior
        cm:setSeasonColorDawn(
            temp, seasonIndex,
            dawnColors.out[1], dawnColors.out[2], dawnColors.out[3], dawnColors.out[4],
            true
        )
        -- Interior
        cm:setSeasonColorDawn(
            temp, seasonIndex,
            dawnColors.inn[1], dawnColors.inn[2], dawnColors.inn[3], dawnColors.inn[4],
            false
        )
    end
end

----------------------------------------
-- Random de atardecer por estación
----------------------------------------
local function randomizeDusk()
    local gt = getGameTime()
    local day = gt:getDay()
    print("[HCTS] randomizeDusk() called. currentDuskType=", currentDuskType)

    -- Primavera / Verano: 20% red, 20% golden, 60% normal
    local randSS = getDayRand(day)
    local duskTypeSS
    if randSS < 20 then
        duskTypeSS = "red"
    elseif randSS < 40 then
        duskTypeSS = "golden"
    else
        duskTypeSS = "normal"
    end
    currentDuskType = duskTypeSS -- usado por el comentario

    applyDuskForSeason(SUMMER, DuskColors_SpringSummer, duskTypeSS)
    applyDuskForSeason(SPRING, DuskColors_SpringSummer, duskTypeSS)

    -- Otoño: 60% normal, 20% golden, 20% brown
    local randAut = getDayRand(day + 123)
    local duskTypeAut
    if randAut < 60 then
        duskTypeAut = "normal"
    elseif randAut < 80 then
        duskTypeAut = "golden"
    else
        duskTypeAut = "brown"
    end
    applyDuskForSeason(AUTUMN, DuskColors_Autumn, duskTypeAut)

    -- Invierno: 30% normal, 30% gray, 20% dark, 20% cold
    local randWin = getDayRand(day + 321)
    local duskTypeWin
    if randWin < 30 then
        duskTypeWin = "normal"
    elseif randWin < 60 then
        duskTypeWin = "gray"
    elseif randWin < 80 then
        duskTypeWin = "dark"
    else
        duskTypeWin = "cold"
    end
    applyDuskForSeason(WINTER, DuskColors_Winter, duskTypeWin)
end

----------------------------------------
-- Amanecer (mañana)
----------------------------------------
local function applyMorningTint()
    -- Primavera / Verano usan Dawn_Clear fuerte
    applyDawnForSeason(SUMMER, Dawn_Clear_SpringSummer)
    applyDawnForSeason(SPRING, Dawn_Clear_SpringSummer)

    -- Otoño / Invierno placeholders blancos (alpha 0)
    applyDawnForSeason(AUTUMN, Dawn_Autumn)
    applyDawnForSeason(WINTER, Dawn_Winter)
end

----------------------------------------
-- Actualización diaria
----------------------------------------
local function onEveryTenMinutes()
    local gt = getGameTime()
    local day = gt:getDay()
    if day ~= lastDay then
        lastDay = day
        randomizeDusk()
        applyMorningTint()
    end
end
Events.EveryTenMinutes.Add(onEveryTenMinutes)

-- Init en nueva partida / carga
Events.OnNewGame.Add(function()
    randomizeDusk()
    applyMorningTint()
end)
Events.OnLoad.Add(function()
    randomizeDusk()
    applyMorningTint()
end)

----------------------------------------
-- Sunshine God Rays (opcional por Sandbox)
----------------------------------------

local sunshineE_Tex, sunshineW_Tex = nil, nil
local sunshineE_Alpha, sunshineW_Alpha = 0, 0
local screenWidth, screenHeight = getCore():getScreenWidth(), getCore():getScreenHeight()

-- Lee SIEMPRE desde Sandbox Options (cliente), más confiable que SandboxVars acá
local function HGTS_IsGodRaysEnabled()
    local so = getSandboxOptions()
    if not so then return true end -- safe default

    local opt = so:getOptionByName("HereGoesTheSun.EnableGodRays")
    if not opt then return true end -- si no lo encuentra, no rompemos nada

    local v = opt:getValue()
    return v == true or v == 1
end

local function HGTS_EnsureTexturesLoaded()
    if sunshineE_Tex and sunshineW_Tex then return end
    sunshineE_Tex = getTexture("media/sunshine/SunshineEast.png")
    sunshineW_Tex = getTexture("media/sunshine/SunshineWest.png")
end

local function Sunshine()
    -- Si está OFF, ni cargamos texturas ni hacemos cálculos
    if not HGTS_IsGodRaysEnabled() then return end

    HGTS_EnsureTexturesLoaded()
    if not sunshineE_Tex or not sunshineW_Tex then return end

    local player = getSpecificPlayer(0)
    if not player or not player:isOutside() then return end

    local speed = 0.003 * getGameSpeed()
    local cm = getClimateManager()
    local gt = getGameTime()
    local nowTime = gt:getHour() + (gt:getMinutes() / 60)
    local season = cm:getSeason()
    local dawnTime = season:getDawn()
    local duskTime = season:getDusk()

    local intensityTable = {
        cm:getCloudIntensity(),
        cm:getFogIntensity(),
        1 - cm:getAmbient()
    }

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

    local alphaW = sunshineW_Alpha - intensityTable[1] - intensityTable[2] - intensityTable[3]
    local alphaE = sunshineE_Alpha - intensityTable[1] - intensityTable[2] - intensityTable[3]

    if alphaW > 0 then
        UIManager.DrawTexture(sunshineW_Tex, 0, 0, screenWidth * zoom, screenHeight * zoom, alphaW)
    end

    local offsetX = math.abs((screenWidth * zoom) - screenWidth)
    local offsetY = math.abs((screenHeight * zoom) - screenHeight)

    if alphaE > 0 then
        UIManager.DrawTexture(sunshineE_Tex, offsetX, offsetY, screenWidth * zoom, screenHeight * zoom, alphaE)
    end
end

Events.OnPreUIDraw.Add(Sunshine)

local function onResolutionChange(w, h)
    screenWidth = w
    screenHeight = h
end
Events.OnResolutionChange.Add(onResolutionChange)

