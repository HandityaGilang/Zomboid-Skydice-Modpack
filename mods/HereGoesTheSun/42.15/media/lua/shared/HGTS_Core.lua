local HGTS = {}

------------------------------------------------------------
-- Paletas DUSK (B, G, R, A)
------------------------------------------------------------
HGTS.DuskColors_Summer = {
    red    = { out = {0.14, 0.10, 0.80, 0.82}, inn = {0.14, 0.10, 0.80, 0.60} },
    golden = { out = {0.14, 0.46, 0.90, 1.00}, inn = {0.14, 0.46, 0.90, 0.60} },
    normal = { out = {0.30, 0.55, 1.00, 1.00}, inn = {0.30, 0.55, 1.00, 0.45} },
}

HGTS.DuskColors_Spring = HGTS.DuskColors_Summer

HGTS.DuskColors_Fall = {
    normal = { out = {0.76, 0.79, 0.87, 0.75}, inn = {0.76, 0.79, 0.87, 0.25} },
    golden = { out = {0.39, 0.59, 0.88, 0.79}, inn = {0.39, 0.59, 0.88, 0.30} },
    brown  = { out = {0.40, 0.50, 0.70, 0.80}, inn = {0.40, 0.50, 0.70, 0.30} },
}

HGTS.DuskColors_Winter = {
    normal = { out = {0.53, 0.47, 0.43, 0.75}, inn = {0.53, 0.47, 0.43, 0.25} },
    sunny  = { out = {0.60, 0.56, 0.56, 0.53}, inn = {0.89, 0.85, 0.83, 0.25} },
    dark   = { out = {0.28, 0.13, 0.14, 0.82}, inn = {0.28, 0.13, 0.14, 0.35} },
    cold   = { out = {0.60, 0.33, 0.33, 0.88}, inn = {0.60, 0.33, 0.33, 0.40} },
}


------------------------------------------------------------
-- Paletas DAWN (B, G, R, A)
------------------------------------------------------------
HGTS.DawnColors_Summer = {
    a = { out = {0.25, 0.35, 0.90, 0.60}, inn = {0.25, 0.35, 0.90, 0.30} },
    b = { out = {0.20, 0.45, 0.95, 0.60}, inn = {0.20, 0.45, 0.95, 0.30} },
}
HGTS.DawnColors_Spring = HGTS.DawnColors_Summer

HGTS.DawnColors_Fall = {
    a = { out = {0.55, 0.55, 0.70, 0.60}, inn = {0.55, 0.55, 0.70, 0.30} },
    b = { out = {0.45, 0.60, 0.75, 0.60}, inn = {0.45, 0.60, 0.75, 0.30} },
}

HGTS.DawnColors_Winter = {
    a = { out = {0.45, 0.40, 0.40, 0.60}, inn = {0.45, 0.40, 0.40, 0.30} },
    b = { out = {0.55, 0.45, 0.45, 0.60}, inn = {0.55, 0.45, 0.45, 0.30} },
}

------------------------------------------------------------
-- Deterministic daily random (0..100) stable per day
------------------------------------------------------------
local function getDayNumber()
    local gt = getGameTime()
    if not gt then return 0 end
    local hours = gt:getWorldAgeHours()
    if not hours then return 0 end
    return math.floor(hours / 24)
end

local function dayRand01(day, salt)
    -- Simple LCG stable
    local a, c, m = 1103515245, 12345, 2147483648
    local seed = (day + (salt or 0)) % m
    seed = (seed * a + c) % m
    return seed / m
end

local function getDailyRandPercent(salt)
    local day = getDayNumber()
    return dayRand01(day, salt) * 100.0
end

------------------------------------------------------------
-- Safe setters
------------------------------------------------------------
local function setSeasonColor(cm, fnName, temp, seasonIndex, b, g, r, a, isExterior)
    if not cm or not fnName then return false end
    local fn = cm[fnName]
    if not fn then return false end
    local ok = pcall(fn, cm, temp, seasonIndex, b, g, r, a, isExterior)
    return ok
end

local function applyPaletteToSeason(cm, fnName, seasonIndex, paletteEntry)
    if not cm or not paletteEntry then return end

    local outB, outG, outR, outA = paletteEntry.out[1], paletteEntry.out[2], paletteEntry.out[3], paletteEntry.out[4]
    local inB,  inG,  inR,  inA  = paletteEntry.inn[1], paletteEntry.inn[2], paletteEntry.inn[3], paletteEntry.inn[4]

    for temp = 0, 2 do
        -- Exterior
        setSeasonColor(cm, fnName, temp, seasonIndex, outB, outG, outR, outA, true)
        -- Interior
        setSeasonColor(cm, fnName, temp, seasonIndex, inB,  inG,  inR,  inA,  false)
    end
end

------------------------------------------------------------
-- Picker
------------------------------------------------------------
-- DUSK chances:
-- Summer: 60 normal / 20 golden / 20 red
-- Fall:   60 normal / 20 golden / 20 brown
-- Winter: 40 normal / 20 sunny / 20 dark / 20 cold
local function pickSummerDuskType()
    local r = getDailyRandPercent(1000)
    if r < 60 then return "normal"
    elseif r < 80 then return "golden"
    else return "red" end
end

local function pickFallDuskType()
    local r = getDailyRandPercent(2000)
    if r < 60 then return "normal"
    elseif r < 80 then return "golden"
    else return "brown" end
end

local function pickWinterDuskType()
    local r = getDailyRandPercent(3000)
    if r < 40 then return "normal"
    elseif r < 60 then return "sunny"
    elseif r < 80 then return "dark"
    else return "cold" end
end

-- DAWN chances:
-- 50/50 para Summer/Spring/Fall/Winter
local function pick50_50(salt)
    local r = getDailyRandPercent(salt)
    if r < 50 then return "a" else return "b" end
end

------------------------------------------------------------
-- Apply: Dusk + Dawn
------------------------------------------------------------
local function applyDusk()
    local cm = getClimateManager()
    if not cm then return end

    local fnName = "setSeasonColorDusk"

    -- 0 Summer
    local sType = pickSummerDuskType()
    applyPaletteToSeason(cm, fnName, 0, HGTS.DuskColors_Summer[sType])

    -- 1 Fall
    local fType = pickFallDuskType()
    applyPaletteToSeason(cm, fnName, 1, HGTS.DuskColors_Fall[fType])

    -- 2 Winter
    local wType = pickWinterDuskType()
    applyPaletteToSeason(cm, fnName, 2, HGTS.DuskColors_Winter[wType])

    -- 3 Spring (misma paleta que summer, PERO slot separado)
    local spType = pickSummerDuskType() -- reutiliza distribución
    applyPaletteToSeason(cm, fnName, 3, HGTS.DuskColors_Spring[spType])
end

local function applyDawn()
    local cm = getClimateManager()
    if not cm then return end

    local fnName = "setSeasonColorDawn"

    -- 0 Summer (50/50)
    local sKey = pick50_50(1100)
    applyPaletteToSeason(cm, fnName, 0, HGTS.DawnColors_Summer[sKey])

    -- 1 Fall (50/50)
    local fKey = pick50_50(2100)
    applyPaletteToSeason(cm, fnName, 1, HGTS.DawnColors_Fall[fKey])

    -- 2 Winter (50/50)
    local wKey = pick50_50(3100)
    applyPaletteToSeason(cm, fnName, 2, HGTS.DawnColors_Winter[wKey])

    -- 3 Spring (50/50, misma paleta que summer)
    local spKey = pick50_50(4100)
    applyPaletteToSeason(cm, fnName, 3, HGTS.DawnColors_Spring[spKey])
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------
function HGTS.applyForCurrentWeather()
    applyDusk()
    applyDawn()
end

return HGTS
