TMRadioMTV = {}
TMRadioMTV.channelUUID = tostring(SandboxVars.TrueMusicRadio.TMRMTV)

local function comp(_str)
	return _str
end

-- FIXME: ISDebugUtils isn't loaded on the server
ISDebugUtils = ISDebugUtils or {}
function ISDebugUtils.roundNum(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function roundstring(_val)
	return tostring(ISDebugUtils.roundNum(_val,2))
end

local function roundstring100(_val)
	return tostring(ISDebugUtils.roundNum(_val,0))
end

local activity = {
	"anomalous",
	"suspicious",
	"hostile",
	"undead",
	"class 5",
	"class 4",
	"class 3",
	"survivor",
	"vehicle",
	"airborne",
	"friendly",
	"unknown",
	"neutral",
}

local zones = {
	{ name = "south", sectors = { 2, 5, 8, 9 } },
	{ name = "south-west", sectors = { 1, 3, 6, 7 } },
	{ name = "north-west", sectors = { 10, 14, 15, 18 } },
	{ name = "central", sectors = { 11, 12, 13, 19 } },
	{ name = "north", sectors = { 17, 4, 16, 23 } },
	{ name = "north-east", sectors = { 21, 25, 29, 31 } },
	{ name = "west", sectors = { 22, 24, 28, 32 } },
	{ name = "east", sectors = { 27, 30, 33, 36 } },
	{ name = "south-east", sectors = { 20, 26, 34, 35 } },
}

function TMRadioMTV.Init()
	activity = {
		getRadioText("AEBS_rand_pre_0"),
        	getRadioText("AEBS_rand_pre_1"),
        	getRadioText("AEBS_rand_pre_2"),
        	--getRadioText("AEBS_rand_pre_3"),
        	getRadioText("AEBS_rand_pre_4"),
        	getRadioText("AEBS_rand_pre_5"),
        	getRadioText("AEBS_rand_pre_6"),
        	getRadioText("AEBS_rand_pre_7"),
        	getRadioText("AEBS_rand_pre_8"),
        	getRadioText("AEBS_rand_pre_9"),
        	getRadioText("AEBS_rand_pre_10"),
        	getRadioText("AEBS_rand_pre_11"),
        	getRadioText("AEBS_rand_pre_12"),
	}

	zones = {
		{ name = getRadioText("AEBS_zone_name_s"), sectors = { 2, 5, 8, 9 } },
        	{ name = getRadioText("AEBS_zone_name_sw"), sectors = { 1, 3, 6, 7 } },
        	{ name = getRadioText("AEBS_zone_name_nw"), sectors = { 10, 14, 15, 18 } },
        	{ name = getRadioText("AEBS_zone_name_c"), sectors = { 11, 12, 13, 19 } },
        	{ name = getRadioText("AEBS_zone_name_n"), sectors = { 17, 4, 16, 23 } },
        	{ name = getRadioText("AEBS_zone_name_ne"), sectors = { 21, 25, 29, 31 } },
        	{ name = getRadioText("AEBS_zone_name_w"), sectors = { 22, 24, 28, 32 } },
        	{ name = getRadioText("AEBS_zone_name_e"), sectors = { 27, 30, 33, 36 } },
        	{ name = getRadioText("AEBS_zone_name_se"), sectors = { 20, 26, 34, 35 } },
    	}
end

function TMRadioMTV.OnLoadRadioScripts()
	TMRadioMTV.Init()
	table.insert(DynamicRadio.scripts, TMRadioMTV)
end

function TMRadioMTV.OnEveryHour(_channel, _gametime, _radio)
	local hour = _gametime:getHour()

	if hour<120 then
		local bc = TMRadioMTV.CreateBroadcast(_gametime)
		_channel:setAiringBroadcast(bc)
    	end
end

function TMRadioMTV.OnEveryTenMinutes(_channel, _gametime, _radio)
	local hour = _gametime:getHour()

	if hour<120 then
		local bc = TMRadioMTV.CreateBroadcastEveryTenMinutes(_gametime)
        	_channel:setAiringBroadcast(bc)
    	end
end

function TMRadioMTV.OnNewSong(_channel, _gametime, _radio, prettyName)
	local hour = _gametime:getHour()

	if hour<120 then	
		local bc = TMRadioMTV.CreateBroadcastNewSong(_gametime, prettyName)
		_channel:setAiringBroadcast(bc)
    	end
end

Events.OnLoadRadioScripts.Add(TMRadioMTV.OnLoadRadioScripts)

function TMRadioMTV.CreateBroadcast(_gametime)
	local bc = RadioBroadCast.new("GEN-"..tostring(ZombRand(100000,999999)),-1,-1)
	TMRadioMTV.FillBroadcast(_gametime, bc)
	return bc
end

function TMRadioMTV.CreateBroadcastEveryTenMinutes(_gametime)
	local bc = RadioBroadCast.new("GEN-"..tostring(ZombRand(100000,999999)),-1,-1)
	TMRadioMTV.FillBroadcastEveryTenMinutes(_gametime, bc)
	return bc
end

function TMRadioMTV.CreateBroadcastNewSong(_gametime, prettyName)
	local bc = RadioBroadCast.new("GEN-"..tostring(ZombRand(100000,999999)),-1,-1)
	TMRadioMTV.FillBroadcastNewSong(_gametime, bc, prettyName)
	return bc
end

function TMRadioMTV.FillBroadcast(_gametime, _bc)
	local hour = _gametime:getHour()
	local c = { r=1.0, g=1.0, b=1.0 }

	_bc:AddRadioLine( RadioLine.new("[img=music]", c.r, c.g, c.b) )

	if SandboxVars.TrueMusicRadio.TMRRadioHordeNightBroadcast then
    		TMRadioMTV.AddHordeNightNotice(c, _bc)
	end

	--if SandboxVars.TrueMusicRadio.TMRRadioWeatherBroadcast then
    	--	TMRadioMTV.AddForecasting(c, _bc, hour)
	--end

	--_bc:AddRadioLine( RadioLine.new("[img=music]", c.r, c.g, c.b) )
end

function TMRadioMTV.FillBroadcastEveryTenMinutes(_gametime, _bc)
    	local hour = _gametime:getHour()
    	local c = { r=1.0, g=1.0, b=1.0 }

    	_bc:AddRadioLine( RadioLine.new("[img=music]", c.r, c.g, c.b) )
end

function TMRadioMTV.FillBroadcastNewSong(_gametime, _bc, prettyName)
    	local hour = _gametime:getHour()
    	local c = { r=1.0, g=1.0, b=1.0 }

    	_bc:AddRadioLine( RadioLine.new("[img=music] " .. prettyName .. " [img=music]", c.r, c.g, c.b) )
end

function TMRadioMTV.AddHordeNightNotice(_c, _bc, _force)
	if not SandboxVars.TrueMusicRadio.TMRRadioHordeNightBroadcast then
		return
	end
	if not getActivatedMods():contains("HordeNight01") then
		return
	end

	local isTheHordeNightDay = false
	local HNdaysPass = math.floor(HN_getActualSpawnAgeDay())
	if HNdaysPass >= SandboxVars.HordeNightMain.FirstHordeNightDay then
		if (HNdaysPass - SandboxVars.HordeNightMain.FirstHordeNightDay) % SandboxVars.HordeNightMain.HordeNightFrequency == 0 then
			isTheHordeNightDay = true
		end
	end
    	if isTheHordeNightDay then
        	_bc:AddRadioLine( RadioLine.new("*** EAS Warning! ***", _c.r, _c.g, _c.b) )
        	_bc:AddRadioLine( RadioLine.new("*** Infected population detected in the local area. ***", _c.r, _c.g, _c.b) )
        	_bc:AddRadioLine( RadioLine.new("*** Please take proper precautions immediately. ***", _c.r, _c.g, _c.b) )
    	end
end

function TMRadioMTV.AddForecasting(_c, _bc, _hour)
    	local clim = getClimateManager()
    	local forecaster = clim:getClimateForecaster()

        -- forecast today and tomorrow
       	local forecast = forecaster:getForecast()
       	TMRadioMTV.AddForecast(_c, _bc, forecast, getRadioText("AEBS_Pre_today"), _hour<12)

       	local forecast = forecaster:getForecast(1)
       	TMRadioMTV.AddForecast(_c, _bc, forecast, getRadioText("AEBS_Pre_tomorrow"), true)

       	TMRadioMTV.AddExtremesForecasting(_c, _bc, 2)
end

function TMRadioMTV.AddForecast(_c, _bc, _forecast, _prefix, _doFog)
    	local s = _prefix
   	s = s .. TMRadioMTV.GetForecastString(1, _forecast)
    	_bc:AddRadioLine( RadioLine.new(comp(s), _c.r, _c.g, _c.b) )

    	s = TMRadioMTV.GetForecastString(2, _forecast)
    	_bc:AddRadioLine( RadioLine.new(comp(s), _c.r, _c.g, _c.b) )

    	if _doFog and _forecast:isHasFog() then
        	s = TMRadioMTV.GetForecastString(3, _forecast)
        	_bc:AddRadioLine( RadioLine.new(comp(s), _c.r, _c.g, _c.b) )
    	end

    	if _forecast:isWeatherStarts() then
        	-- a new weather period starts
        	s = TMRadioMTV.GetForecastString(4, _forecast)
        	_bc:AddRadioLine( RadioLine.new(comp(s), _c.r, _c.g, _c.b) )
    	elseif _forecast:getWeatherOverlap() then
        	-- a already started weather period overlaps this day
        	s = TMRadioMTV.GetForecastString(5, _forecast)
        	_bc:AddRadioLine( RadioLine.new(comp(s), _c.r, _c.g, _c.b) )
    	end
end

function TMRadioMTV.GetForecastString(_type, _forecast)
    	local s = ""
    	if _type==1 then
        	local v = _forecast:getTemperature()
        	local a,b,c = v:getTotalMean(), v:getTotalMin(), v:getTotalMax()
        	local d = roundstring100(_forecast:getHumidity():getTotalMean()*100)
        	s = string.format(" "..getRadioText("AEBS_temperature"), Temperature.getTemperatureString(a), Temperature.getTemperatureString(b), Temperature.getTemperatureString(c), d)
    	elseif _type==2 then
		local v = _forecast:getWindPower()
		local a,b,c = v:getTotalMean(), v:getTotalMin(), v:getTotalMax()

        	if getCore():getOptionDisplayAsCelsius() then
            		c = roundstring(ClimateManager.ToKph(c)).." KpH"
        	else
            		c = roundstring(ClimateManager.ToMph(c)).." MpH"
        	end
        	local d = _forecast:getMeanWindAngleString()
        	local dnew = getRadioText("AEBS_zone_name_"..d:lower())
        	if dnew then
            		d = dnew
        	end
        	local e = getRadioText("AEBS_clouds_0")
        	local cloudsA = _forecast:getCloudiness():getTotalMean()
        	local cloudsB = _forecast:getCloudiness():getTotalMax()

        	if cloudsA>0.7 then
            		e = getRadioText("AEBS_clouds_2")
        	elseif cloudsA>0.4 then
            		e = getRadioText("AEBS_clouds_1")
            		if cloudsB>0.7 then
                		e = e .. " "..getRadioText("AEBS_clouds_4")
            		end
        	else
            		if cloudsB>0.7 then
                		e = e .. " "..getRadioText("AEBS_clouds_4")
            		elseif cloudsB>0.4 then
                		e = e .. " "..getRadioText("AEBS_clouds_3")
            		end
        	end

        	local w = getRadioText("AEBS_wind_1")
        	if a>0.75 then
            		w = getRadioText("AEBS_wind_4")
        	elseif a>0.5 then
            		w = getRadioText("AEBS_wind_3")
        	elseif a>0.25 then
            		w = getRadioText("AEBS_wind_2")
        	end

        	s = string.format(getRadioText("AEBS_wind_0"), w, d, c, e)
    	elseif _type==3 then
        	local v = _forecast:getFogStrength()
        	if v==1 then
            		s = getRadioText("AEBS_fog_2")
        	elseif v>0.75 then
            		s = getRadioText("AEBS_fog_1")
        	else
            		s = getRadioText("AEBS_fog_0")
        	end
    	elseif _type==4 or _type==5 then
        	if _type==4 then
           		s = string.format(getRadioText("AEBS_weather_0_a"), TMRadioMTV.GetDaySegmentForHour(_forecast:getWeatherStartTime()))
        	else
            		local endTime = _forecast:getWeatherEndTime()
            		if endTime>=22 then
                		s = getRadioText("AEBS_weather_0_b")
            		else
                		s = string.format(getRadioText("AEBS_weather_0_c"), TMRadioMTV.GetDaySegmentForHour(endTime))
            		end

        	end

        	local t = {}
        	if _forecast:isHasHeavyRain() then
            		table.insert(t,getRadioText("AEBS_weather_heavy_rain"))
        	end
        	if _forecast:isHasStorm() then
            		table.insert(t,getRadioText("AEBS_weather_storm"))
        	end
        	if _forecast:isHasTropicalStorm() then
            		table.insert(t,getRadioText("AEBS_weather_tropical"))
        	end
        	if _forecast:isHasBlizzard() then
            		table.insert(t,getRadioText("AEBS_weather_blizzard"))
        	end

        	if #t>0 then
            		if #t==1 then
                		s = s .. getRadioText("AEBS_weather_predicted")..t[1]
            		else
                		s = s .. getRadioText("AEBS_weather_predicted")
                		for k,v in ipairs(t) do
                    			if k<#t then
                        			s = s .. v .. (v~=#t-1 and ", " or "")
                    			else
                        			s = s .. getRadioText("AEBS_weather_and_a") .. v .. "..."
                    			end
                		end
            		end
        	else
            		s = s .. getRadioText("AEBS_weather_light_moderate")
        	end

        	if _forecast:isChanceOnSnow() then
            		s = s..getRadioText("AEBS_weather_snowfall")
        	end
    	end
    	return s
end

function TMRadioMTV.GetDaySegmentForHour(_hour)
    	if _hour<=4 or _hour>=23 then
        	return getRadioText("AEBS_segment_night")
   	elseif _hour>=4 and _hour<8 then
        	return getRadioText("AEBS_segment_early_morning")
    	elseif _hour>=8 and _hour<12 then
        	return getRadioText("AEBS_segment_morning")
    	elseif _hour>=12 and _hour<18 then
        	return getRadioText("AEBS_segment_afternoon")
    	elseif _hour>=18 and _hour<23 then
        	return getRadioText("AEBS_segment_evening")
    	end
end

function TMRadioMTV.AddExtremesForecasting(_c, _bc, offset, _len)
    	local clim = getClimateManager()
    	local forecaster = clim:getClimateForecaster()

    	for i=offset,offset+(_len or 3) do
        	local forecast = forecaster:getForecast(i)

        	if forecast and ( forecast:isHasBlizzard() or forecast:isHasTropicalStorm() or forecast:isHasStorm() ) then
            		local type = getRadioText("AEBS_weather_storm_C")
            		if forecast:isHasTropicalStorm() then
                		type = getRadioText("AEBS_weather_tropical_C")
            		elseif forecast:isHasBlizzard() then
                		type = getRadioText("AEBS_weather_blizzard_C")
            		end

            		local s = string.format(getRadioText("AEBS_weather_warning"), type, tostring(i))
            		_bc:AddRadioLine( RadioLine.new(comp(s), _c.r, _c.g, _c.b) )
            		return
        	end
    	end
end