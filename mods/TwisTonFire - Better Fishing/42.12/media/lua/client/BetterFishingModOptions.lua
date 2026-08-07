-- TwisTonFire — Better Fishing (ModOptions)

local BF = {}

BF.UID  = "TWF_BF"
BF.NAME = "TwisTonFire — Better Fishing"

local options = PZAPI.ModOptions:create(BF.UID, BF.NAME)

options:addTickBox("UseTwF_AimDist", getText("UI_TWF_BF_USE_TWF_AIMDIST"), true, getText("UI_TWF_BF_USE_TWF_AIMDIST_TT"))
options:addTickBox("UseTwF_Shore",   getText("UI_TWF_BF_USE_TWF_SHORE"),   true, getText("UI_TWF_BF_USE_TWF_SHORE_TT"))
options:addTickBox("UseTwF_Size",    getText("UI_TWF_BF_USE_TWF_SIZE"),    true, getText("UI_TWF_BF_USE_TWF_SIZE_TT"))
options:addTickBox("UseTwF_Temp",    getText("UI_TWF_BF_USE_TWF_TEMP"),    true, getText("UI_TWF_BF_USE_TWF_TEMP_TT"))
options:addTickBox("UseTwF_Weather", getText("UI_TWF_BF_USE_TWF_WEATHER"), true, getText("UI_TWF_BF_USE_TWF_WEATHER_TT"))
options:addTickBox("UseTwF_Time",    getText("UI_TWF_BF_USE_TWF_TIME"),    true, getText("UI_TWF_BF_USE_TWF_TIME_TT"))

options:addDescription(getText("UI_TWF_BF_RESTART_REQUIRED_HINT"))
options:addTickBox("UseTwF_SizeTables", getText("UI_TWF_BF_USE_TWF_SIZETABLES"), true, getText("UI_TWF_BF_USE_TWF_SIZETABLES_TT"))

options:addDescription(getText("UI_TWF_BF_SLIDER_DEPENDS_HINT"))
options:addSlider("TwF_AimDist",     getText("UI_TWF_BF_AIMDIST"),
                  16, 20, 1, 18, getText("UI_TWF_BF_AIMDIST_TT"))

options:addSlider("TwF_ShoreRadius", getText("UI_TWF_BF_SHORE_RADIUS"),
                  1, 7, 1, 2, getText("UI_TWF_BF_SHORE_RADIUS_TT"))

options:addSlider("TwF_SizeBlend",   getText("UI_TWF_BF_SIZE_BLEND"),
                  0, 100, 5, 100, getText("UI_TWF_BF_SIZE_BLEND_TT"))

options:addSlider("TwF_TempCoeff",   getText("UI_TWF_BF_TEMP_COEFF"),
                  10, 200, 5, 100, getText("UI_TWF_BF_TEMP_COEFF_TT"))

options:addSlider("TwF_FogCoeff",    getText("UI_TWF_BF_FOG_COEFF"),
                  50, 150, 5, 100, getText("UI_TWF_BF_FOG_COEFF_TT"))

options:addSlider("TwF_WindCoeff",   getText("UI_TWF_BF_WIND_COEFF"),
                  50, 150, 5, 100, getText("UI_TWF_BF_WIND_COEFF_TT"))

options:addSlider("TwF_RainCoeff",   getText("UI_TWF_BF_RAIN_COEFF"),
                  50, 200, 5, 120, getText("UI_TWF_BF_RAIN_COEFF_TT"))

options:addSlider("TwF_MornStart",   getText("UI_TWF_BF_MORN_START"),
                  3, 6, 1, 4, getText("UI_TWF_BF_MORN_START_TT"))

options:addSlider("TwF_MornEnd",     getText("UI_TWF_BF_MORN_END"),
                  7, 9, 1, 8, getText("UI_TWF_BF_MORN_END_TT"))

options:addSlider("TwF_EveStart",    getText("UI_TWF_BF_EVE_START"),
                  15, 18, 1, 16, getText("UI_TWF_BF_EVE_START_TT"))

options:addSlider("TwF_EveEnd",      getText("UI_TWF_BF_EVE_END"),
                  19, 21, 1, 20, getText("UI_TWF_BF_EVE_END_TT"))

options:addSlider("TwF_TimeCoeff",   getText("UI_TWF_BF_TIME_COEFF"),
                  50, 200, 5, 140, getText("UI_TWF_BF_TIME_COEFF_TT"))

local function _opts() return PZAPI.ModOptions:getOptions(BF.UID) end

function BF_IsTwF(featureKey)
  local map = {
    aim   = "UseTwF_AimDist",
    shore = "UseTwF_Shore",
    size  = "UseTwF_Size",
    temp  = "UseTwF_Temp",
    wx    = "UseTwF_Weather",
    time  = "UseTwF_Time",
    sizetables = "UseTwF_SizeTables",
  }
  local o = _opts(); if not o then return false end
  local opt = o:getOption(map[featureKey])
  return opt and opt:getValue() == true or false
end

local function _getNumberRaw(id, default)
  local o = _opts(); if not o then return default end
  local opt = o:getOption(id)
  local v = opt and opt:getValue()
  return type(v) == "number" and v or default
end


function BF_GetNum(id, default)
  if id == "TwF_SizeBlend" or id == "TwF_TempCoeff" or id == "TwF_FogCoeff" or id == "TwF_WindCoeff"
     or id == "TwF_RainCoeff" or id == "TwF_TimeCoeff" then
    local p = _getNumberRaw(id, default and (default * 100) or 100)
    return p / 100.0
  end
  return _getNumberRaw(id, default)
end

function BF_GetBool(id, default)
  local o = _opts(); if not o then return default end
  local opt = o:getOption(id); local v = opt and opt:getValue()
  return type(v) == "boolean" and v or default
end

return BF