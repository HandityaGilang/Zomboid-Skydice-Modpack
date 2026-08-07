-- TwisTonFire — Better Fishing 

require "Fishing/FishingUtils"

Fishing       = Fishing or {}
Fishing.Utils = Fishing.Utils or {}

pcall(require, "BetterFishingSandBoxShim")

local function _BF_IsTwF(feature)
    local f = rawget(_G, "BF_IsTwF")
    if type(f) == "function" then
        local ok, res = pcall(f, feature)
        if ok then return res end
    end
    return false
end

local function _BF_GetNum(id, def)
    local f = rawget(_G, "BF_GetNum")
    if type(f) == "function" then
        local ok, res = pcall(f, id, def)
        if ok and res ~= nil then return res end
    end
    return def
end

local ORIG = {}
local function _cache(tbl, key)
    if tbl and tbl[key] ~= nil and ORIG[key] == nil then ORIG[key] = tbl[key] end
end

_cache(Fishing.Utils, "isAccessibleAimDist")
_cache(Fishing.Utils, "isNearShore")
_cache(Fishing.Utils, "getFishSizeChancesBySkillLevel")
_cache(Fishing.Utils, "getTemperatureParams")
_cache(Fishing.Utils, "getWeatherParams")
_cache(Fishing.Utils, "getTimeParams")
_cache(Fishing.Utils, "skillSizeLimit")
_cache(Fishing.Utils, "fishSizeChancesBySkillLevel")

local function makeSwitch(featureKey, origFn, twfFn)
    if not origFn and not twfFn then return function(...) return nil end end
    if not origFn then return function(...) return twfFn(...) end end
    if not twfFn then return function(...) return origFn(...) end end
    return function(...)
        if _BF_IsTwF(featureKey) then
            return twfFn(...)
        else
            return origFn(...)
        end
    end
end

local function TwF_isAccessibleAimDist(player)
    local maxDist = _BF_GetNum("TwF_AimDist", 18)
    local x, y = (Fishing.Utils.getAimCoords and Fishing.Utils.getAimCoords(player))
              or (ORIG.getAimCoords and ORIG.getAimCoords(player))
    if not x or not y then
        if ORIG.isAccessibleAimDist then return ORIG.isAccessibleAimDist(player) end
        return true
    end
    return IsoUtils.DistanceTo(player:getX(), player:getY(), x, y) < maxDist
end

local function TwF_isNearShore(x, y)
    local r = math.floor(math.max(0, math.min(7, _BF_GetNum("TwF_ShoreRadius", 2))))
    local c = getCell()
    x, y = math.floor(x), math.floor(y)
    for d = 1, r do
        local s = c:getGridSquare(x + d, y, 0); if s and s:getWater() and s:getWater():isActualShore() then return true end
        s = c:getGridSquare(x - d, y, 0); if s and s:getWater() and s:getWater():isActualShore() then return true end
        s = c:getGridSquare(x, y + d, 0); if s and s:getWater() and s:getWater():isActualShore() then return true end
        s = c:getGridSquare(x, y - d, 0); if s and s:getWater() and s:getWater():isActualShore() then return true end
    end
    return false
end

local function TwF_getFishSizeChancesBySkillLevel(lvl, isNearShore, fishNum)
    local tbl = Fishing.Utils.fishSizeChancesBySkillLevel
    local s, m, b
    if tbl and tbl[lvl] then
        s, m, b = tbl[lvl][1], tbl[lvl][2], tbl[lvl][3]
    elseif ORIG.getFishSizeChancesBySkillLevel then
        s, m, b = ORIG.getFishSizeChancesBySkillLevel(lvl, isNearShore, fishNum)
    else
        s, m, b = 70, 25, 5
    end

    if _BF_IsTwF("size") and isNearShore then
        local blend = math.max(0, math.min(1, _BF_GetNum("TwF_SizeBlend", 100)))
        if blend > 0 then
            local rs, rm, rb = s + (m/2) + (b/2), m/2, b/2
            s = s + (rs - s) * blend
            m = m + (rm - m) * blend
            b = b + (rb - b) * blend
        end
    end
    return s, m, b
end

local function TwF_getTemperatureParams(player)
    local temperature = getClimateManager():getAirTemperatureForCharacter(player, false)
    local coeff = _BF_GetNum("TwF_TempCoeff", 100)
    return { temperature = temperature, coeff = coeff }
end

local function TwF_getWeatherParams()
    local fog  = getClimateManager():getFogIntensity() >= 0.4
    local wind = getClimateManager():getWindPower() >= 0.5
    local rain = RainManager.isRaining()

    local fogC  = _BF_GetNum("TwF_FogCoeff",  100)
    local windC = _BF_GetNum("TwF_WindCoeff", 100)
    local rainC = _BF_GetNum("TwF_RainCoeff", 120)

    local coeff = 1.0
    -- Keep vanilla-style priority (fog/wind override rain when present),
    -- but still allow separate coefficients.
    if fog then
        coeff = fogC
    elseif wind then
        coeff = windC
    elseif rain then
        coeff = rainC
    end

    return { isFog = fog, isWind = wind, isRain = rain, coeff = coeff }
end

local function TwF_getTimeParams()
    local currentHour = math.floor(math.floor(GameTime.getInstance():getTimeOfDay() * 3600) / 3600);
    local ms = _BF_GetNum("TwF_MornStart", 4)
    local me = _BF_GetNum("TwF_MornEnd",   8)
    local es = _BF_GetNum("TwF_EveStart", 16)
    local ee = _BF_GetNum("TwF_EveEnd",   20)
    local c  = _BF_GetNum("TwF_TimeCoeff", 140)
    local inMorn = (currentHour >= ms and currentHour <= me)
    local inEve  = (currentHour >= es and currentHour <= ee)
    local coeff = (inMorn or inEve) and c or 1.0
    return { time = currentHour, coeff = coeff }
end

local TwF_Tables = {
    skillSizeLimit = {
        [0]=6,[1]=12,[2]=16,[3]=20,[4]=26,[5]=30,[6]=35,[7]=40,[8]=45,[9]=45,[10]=45,
    },
    fishSizeChancesBySkillLevel = {
        [0]={70,25,5},[1]={65,30,5},[2]={60,30,10},[3]={55,35,10},[4]={50,35,15},
        [5]={45,35,20},[6]={35,35,30},[7]={25,45,30},[8]={15,45,40},[9]={10,45,45},[10]={10,40,50},
    }
}

local function BetterFishing_ApplySizeTablesFromSandbox()
    local useTw = _BF_IsTwF("sizetables")

    if useTw then
        Fishing.Utils.skillSizeLimit = TwF_Tables.skillSizeLimit
        Fishing.Utils.fishSizeChancesBySkillLevel = TwF_Tables.fishSizeChancesBySkillLevel
        -- print("[BetterFishing] Size tables: Better Fishing")
    else
        if ORIG.skillSizeLimit then
            Fishing.Utils.skillSizeLimit = ORIG.skillSizeLimit
        end
        if ORIG.fishSizeChancesBySkillLevel then
            Fishing.Utils.fishSizeChancesBySkillLevel = ORIG.fishSizeChancesBySkillLevel
        end
        -- print("[BetterFishing] Size tables: Vanilla")
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(BetterFishing_ApplySizeTablesFromSandbox)
end

-- Safety: if this file is loaded after SandboxVars already exist (rare), apply immediately once.
if rawget(_G, "SandboxVars") then
    BetterFishing_ApplySizeTablesFromSandbox()
end

if ORIG.isAccessibleAimDist then
    Fishing.Utils.isAccessibleAimDist = makeSwitch("aim", ORIG.isAccessibleAimDist, TwF_isAccessibleAimDist)
else
    Fishing.Utils.isAccessibleAimDist = TwF_isAccessibleAimDist
end

if ORIG.isNearShore then
    Fishing.Utils.isNearShore = makeSwitch("shore", ORIG.isNearShore, TwF_isNearShore)
else
    Fishing.Utils.isNearShore = TwF_isNearShore
end

if ORIG.getFishSizeChancesBySkillLevel then
    Fishing.Utils.getFishSizeChancesBySkillLevel =
        makeSwitch("size", ORIG.getFishSizeChancesBySkillLevel, TwF_getFishSizeChancesBySkillLevel)
else
    Fishing.Utils.getFishSizeChancesBySkillLevel = TwF_getFishSizeChancesBySkillLevel
end

if ORIG.getTemperatureParams then
    Fishing.Utils.getTemperatureParams =
        makeSwitch("temp", ORIG.getTemperatureParams, TwF_getTemperatureParams)
else
    Fishing.Utils.getTemperatureParams = TwF_getTemperatureParams
end

if ORIG.getWeatherParams then
    Fishing.Utils.getWeatherParams =
        makeSwitch("wx", ORIG.getWeatherParams, TwF_getWeatherParams)
else
    Fishing.Utils.getWeatherParams = TwF_getWeatherParams
end

if ORIG.getTimeParams then
    Fishing.Utils.getTimeParams =
        makeSwitch("time", ORIG.getTimeParams, TwF_getTimeParams)
else
    Fishing.Utils.getTimeParams = TwF_getTimeParams
end