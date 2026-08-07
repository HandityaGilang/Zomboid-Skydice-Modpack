if not isClient() then return end

local HGTS_StormMood_Client = {}
HGTS_StormMood_Client._last = nil
HGTS_StormMood_Client._tick = 0

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

local function getAdminTriplet(cm)
    if not cm or not cm.getClimateFloat then return nil end

	local DESAT_ID, DAY_ID = getFloatIds()
	local d = DESAT_ID and cm:getClimateFloat(DESAT_ID) or nil
	local l = DAY_ID   and cm:getClimateFloat(DAY_ID)   or nil

	return {
		desat = (d and d.getAdminValue and d:getAdminValue()) or 0,
		day   = (l and l.getAdminValue and l:getAdminValue()) or 0,
	}
end

local function changedEnough(prev, cur)
    if not prev or not cur then return true end
    if math.abs(cur.desat - prev.desat) > 0.01 then return true end
    if math.abs(cur.day   - prev.day)   > 0.01 then return true end
    return false
end

local function ClientUpdate()
    HGTS_StormMood_Client._tick = HGTS_StormMood_Client._tick + 1

    if HGTS_StormMood_Client._tick < 60 then return end
    HGTS_StormMood_Client._tick = 0

    local cm = getClimateManager()
    if not cm then return end

    local cur = getAdminTriplet(cm)
    if not cur then return end

    if changedEnough(HGTS_StormMood_Client._last, cur) then
        pcall(function() cm:update() end)
        pcall(function() cm:update() end)
        HGTS_StormMood_Client._last = cur
    end
end

Events.OnTick.Add(ClientUpdate)

return HGTS_StormMood_Client
