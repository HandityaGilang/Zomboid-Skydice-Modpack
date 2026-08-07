local StormMoodCore = {}

------------------------------------------------------------
-- Ajustes (tocá acá)
------------------------------------------------------------
StormMoodCore.DESAT_TARGET               = 0.85
StormMoodCore.DEFAULT_DESAT_TARGET       = StormMoodCore.DEFAULT_DESAT_TARGET or StormMoodCore.DESAT_TARGET

StormMoodCore.DAYLIGHT_TARGET            = 0.85

StormMoodCore.RAIN_LOCK_ON               = 0.30
StormMoodCore.RAIN_LOCK_OFF              = 0.12
StormMoodCore.MIN_HOLD_MINUTES           = 5

StormMoodCore.LERP_DESAT_PER_TICK        = 0.06
StormMoodCore.LERP_DAYLIGHT_PER_TICK     = 0.06

------------------------------------------------------------
-- Estado runtime (vive en quien lo require)
------------------------------------------------------------
StormMoodCore.S = StormMoodCore.S or {
    locked = false,
    holdUntilWorldHours = 0,
    baseDesat    = nil,
    baseDaylight = nil,
    curDesat     = nil,
    curDaylight  = nil,
}

------------------------------------------------------------
-- Sandbox
------------------------------------------------------------
local function isStormMoodEnabled()
    local so = getSandboxOptions()
    if not so then return true end
    local opt = so:getOptionByName("HereGoesTheSun.EnableStormMood")
    if not opt then return true end
    local v = opt:getValue()
    return v == true or v == 1
end

local function applyPresetFromSandbox()
    local so = getSandboxOptions()
    if not so then return end

    local opt = so:getOptionByName("HereGoesTheSun.StormMoodPreset")
    if not opt then return end

    local v = opt:getValue()
    local key = v

    -- Reset a default antes de aplicar preset
    StormMoodCore.DESAT_TARGET = StormMoodCore.DEFAULT_DESAT_TARGET

    if type(v) == "number" then
        if v == 1 then key = "Soft"
        elseif v == 2 then key = "Recommended"
        else key = "NightOfTheLivingDead" end
    end

    if key == "Soft" then
        StormMoodCore.DESAT_TARGET = 0.60
    elseif key == "Recommended" then
        StormMoodCore.DESAT_TARGET = 0.85
    elseif key == "NightOfTheLivingDead" then
        StormMoodCore.DESAT_TARGET = 1.00
    end
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function clamp01(x)
    if x == nil then return nil end
    if x < 0 then return 0 end
    if x > 1 then return 1 end
    return x
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function nowWorldHours()
    local gt = getGameTime()
    if not gt then return 0 end
    if gt.getWorldAgeHours then
        return gt:getWorldAgeHours()
    end
    return (gt:getDay() * 24) + (gt:getHour() + gt:getMinutes() / 60)
end

local function getRain01(cm)
    if not cm then return 0 end
    local snow = (cm.getSnowIntensity and cm:getSnowIntensity()) or 0
    if snow > 0.01 then return 0 end

    local rain = (cm.getRainIntensity and cm:getRainIntensity()) or 0
    if cm.getPrecipitationIntensity then
        local p = cm:getPrecipitationIntensity() or 0
        rain = math.max(rain, p)
    end
    return clamp01(rain)
end

local function getFloatIds()
    local DESAT, DAY = nil, nil

    if ClimateManager then
        DESAT = ClimateManager.FLOAT_DESATURATION or DESAT
        DAY   = ClimateManager.FLOAT_DAYLIGHT_STRENGTH
            or ClimateManager.FLOAT_DAYLIGHT
            or DAY
    end

    DESAT = DESAT or rawget(_G, "FLOAT_DESATURATION")
    DAY   = DAY
        or rawget(_G, "FLOAT_DAYLIGHT_STRENGTH")
        or rawget(_G, "FLOAT_DAYLIGHT")

    return DESAT, DAY
end

local function getClimateFloat(cm, floatId)
    if not cm or not floatId then return nil end
    if not cm.getClimateFloat then return nil end
    return cm:getClimateFloat(floatId)
end

local function cfGetFinal(cf)
    if not cf then return nil end
    if cf.getFinalValue then return cf:getFinalValue() end
    if cf.getAdminValue then return cf:getAdminValue() end
    if cf.getInternalValue then return cf:getInternalValue() end
    return nil
end

------------------------------------------------------------
-- Admin/Override helpers (SERVER-ONLY)
------------------------------------------------------------
local function cfEnableAdminOverride(cf)
    if not cf then return end
    if cf.setEnableOverride then cf:setEnableOverride(true) end
    if cf.setEnableAdmin then cf:setEnableAdmin(true) end
end

local function cfDisableAdminOverride(cf)
    if not cf then return end
    if cf.setEnableAdmin then cf:setEnableAdmin(false) end
    if cf.setEnableOverride then cf:setEnableOverride(false) end
end

local function cfSetAdminValue(cf, v)
    if not cf or v == nil then return false end
    if cf.setAdminValue then
        cf:setAdminValue(v)
        return true
    end
    if cf.setOverride then
        cf:setOverride(v)
        return true
    end
    return false
end

------------------------------------------------------------
-- Lock / hold
------------------------------------------------------------
local function updateLock(S, cm)
    local intensity = getRain01(cm)
    local t = nowWorldHours()

    if not S.locked then
        if intensity >= StormMoodCore.RAIN_LOCK_ON then
            S.locked = true
            S.holdUntilWorldHours = t + (StormMoodCore.MIN_HOLD_MINUTES / 60)
            S.baseDesat, S.baseDaylight = nil, nil
            S.curDesat,  S.curDaylight  = nil, nil
            return "LOCK_ON"
        end
        return "NO_CHANGE"
    end

    if intensity >= StormMoodCore.RAIN_LOCK_ON then
        S.holdUntilWorldHours = t + (StormMoodCore.MIN_HOLD_MINUTES / 60)
        return "HOLD_EXTEND"
    end

    if (t >= S.holdUntilWorldHours) and (intensity <= StormMoodCore.RAIN_LOCK_OFF) then
        S.locked = false
        return "LOCK_OFF"
    end

    return "NO_CHANGE"
end

------------------------------------------------------------
-- API: TickServer (aplica y devuelve si cambió algo)
------------------------------------------------------------
function StormMoodCore.TickServer()
    if not isStormMoodEnabled() then
        return StormMoodCore.ResetServer()
    end

    applyPresetFromSandbox()

    local cm = getClimateManager()
    if not cm then return false end

    local S = StormMoodCore.S
    local lockEvent = updateLock(S, cm)

    local DESAT_ID, DAY_ID = getFloatIds()
    if not DESAT_ID and not DAY_ID then return false end

    local cfDesat    = getClimateFloat(cm, DESAT_ID)
    local cfDaylight = getClimateFloat(cm, DAY_ID)

    -- Captura bases 1 vez
    if S.baseDesat == nil and cfDesat then
        local v = cfGetFinal(cfDesat)
        if v ~= nil then S.baseDesat = clamp01(v) end
    end
    if S.baseDaylight == nil and cfDaylight then
        local v = cfGetFinal(cfDaylight)
        if v ~= nil then S.baseDaylight = clamp01(v) end
    end

    if S.curDesat    == nil then S.curDesat    = S.baseDesat end
    if S.curDaylight == nil then S.curDaylight = S.baseDaylight end

    -- Admin/override mientras tocamos valores
    if cfDesat then cfEnableAdminOverride(cfDesat) end
    if cfDaylight then cfEnableAdminOverride(cfDaylight) end

    local changed = false
    local function markChanged(old, new)
        if old == nil or new == nil then return end
        if math.abs(new - old) > 0.001 then changed = true end
    end

    if S.locked then
        if cfDesat and S.curDesat ~= nil then
            local prev = S.curDesat
            S.curDesat = lerp(S.curDesat, StormMoodCore.DESAT_TARGET, StormMoodCore.LERP_DESAT_PER_TICK)
            S.curDesat = clamp01(S.curDesat)
            if cfSetAdminValue(cfDesat, S.curDesat) then markChanged(prev, S.curDesat) end
        end

        if cfDaylight and S.curDaylight ~= nil then
            local prev = S.curDaylight
            S.curDaylight = lerp(S.curDaylight, StormMoodCore.DAYLIGHT_TARGET, StormMoodCore.LERP_DAYLIGHT_PER_TICK)
            S.curDaylight = clamp01(S.curDaylight)
            if cfSetAdminValue(cfDaylight, S.curDaylight) then markChanged(prev, S.curDaylight) end
        end

        if lockEvent == "LOCK_ON" or lockEvent == "LOCK_OFF" then
            changed = true
        end

        return changed
    end

	-- NOT LOCKED: volvemos SOLO desat a base.
	-- Daylight queda estático donde esté y se suelta cuando desat termina.
	local doneD = true

	if cfDesat and S.curDesat ~= nil and S.baseDesat ~= nil then
		local prev = S.curDesat
		S.curDesat = lerp(S.curDesat, S.baseDesat, StormMoodCore.LERP_DESAT_PER_TICK)
		S.curDesat = clamp01(S.curDesat)
		cfSetAdminValue(cfDesat, S.curDesat)
		markChanged(prev, S.curDesat)
		if math.abs(S.curDesat - S.baseDesat) > 0.01 then
			doneD = false
		end
	end

	if doneD then
		if cfDesat then cfDisableAdminOverride(cfDesat) end
		if cfDaylight then cfDisableAdminOverride(cfDaylight) end

		S.baseDesat, S.baseDaylight = nil, nil
		S.curDesat,  S.curDaylight  = nil, nil
		changed = true
	end

	return changed

end

function StormMoodCore.ResetServer()
    local cm = getClimateManager()
    local DESAT_ID, DAY_ID = getFloatIds()

    if cm then
        local cfDesat    = getClimateFloat(cm, DESAT_ID)
        local cfDaylight = getClimateFloat(cm, DAY_ID)
        if cfDesat then cfDisableAdminOverride(cfDesat) end
        if cfDaylight then cfDisableAdminOverride(cfDaylight) end
    end

    local S = StormMoodCore.S
    S.locked = false
    S.holdUntilWorldHours = 0
    S.baseDesat, S.baseDaylight = nil, nil
    S.curDesat,  S.curDaylight  = nil, nil

    return true
end

return StormMoodCore
