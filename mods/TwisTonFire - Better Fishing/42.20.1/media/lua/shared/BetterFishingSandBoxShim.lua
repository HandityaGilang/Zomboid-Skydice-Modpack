-- TwisTonFire — Better Fishing (Sandbox options shim)
-- This mod no longer registers PZAPI.ModOptions.
-- All gameplay tuning is done via custom sandbox options (media/sandbox-options.txt).

local BF = {}

BF.UID  = "TWF_BF"
BF.NAME = "TwisTonFire — Better Fishing"

local function _sb()
    local sv = rawget(_G, "SandboxVars")
    if type(sv) ~= "table" then
        return nil
    end

    local bf = sv[BF.UID]
    if type(bf) ~= "table" then
        bf = {}
        sv[BF.UID] = bf
    end

    -- Migration: old worlds may not have these sandbox keys at all.
    -- Seed defaults only when values are missing (nil).
    if bf.UseTwF_SizeTables == nil then bf.UseTwF_SizeTables = true end

    -- Baseline defaults (so old worlds behave like new-world defaults)
    if bf.TwF_AimDist     == nil then bf.TwF_AimDist     = 16  end
    if bf.TwF_ShoreRadius == nil then bf.TwF_ShoreRadius = 7   end

    if bf.TwF_SizeBlend   == nil then bf.TwF_SizeBlend   = 100 end
    if bf.TwF_TempCoeff   == nil then bf.TwF_TempCoeff   = 100 end
    if bf.TwF_FogCoeff    == nil then bf.TwF_FogCoeff    = 80  end
    if bf.TwF_WindCoeff   == nil then bf.TwF_WindCoeff   = 80  end
    if bf.TwF_RainCoeff   == nil then bf.TwF_RainCoeff   = 120 end

    if bf.TwF_MornStart   == nil then bf.TwF_MornStart   = 4   end
    if bf.TwF_MornEnd     == nil then bf.TwF_MornEnd     = 6   end
    if bf.TwF_EveStart    == nil then bf.TwF_EveStart    = 18  end
    if bf.TwF_EveEnd      == nil then bf.TwF_EveEnd      = 20  end
    if bf.TwF_TimeCoeff   == nil then bf.TwF_TimeCoeff   = 120 end

    return bf
end

local function _num(name, default)
    local t = _sb()
    local v = t and t[name]
    return type(v) == "number" and v or default
end

local function _bool(name, default)
    local t = _sb()
    local v = t and t[name]
    return type(v) == "boolean" and v or default
end

function BF_IsTwF(featureKey)
    -- All Better Fishing logic is always active now (no enable/disable toggles),
    -- except the table selection, which is a sandbox choice.
    if featureKey == "sizetables" then
        return _bool("UseTwF_SizeTables", true)
    end
    return true
end

function BF_GetNum(id, default)
    -- Keep compatibility with BetterFishing.lua which expects these ids.
    local v = _num(id, default)

    -- Percent sliders stored as 0..200 etc, but BetterFishing.lua expects 0.0..2.0 multipliers.
    if id == "TwF_SizeBlend"
        or id == "TwF_TempCoeff"
        or id == "TwF_FogCoeff"
        or id == "TwF_WindCoeff"
        or id == "TwF_RainCoeff"
        or id == "TwF_TimeCoeff"
    then
        return (type(v) == "number" and v or (default or 100)) / 100.0
    end

    return v
end

function BF_GetBool(id, default)
    -- No longer used (kept for compatibility).
    return default
end

return BF
