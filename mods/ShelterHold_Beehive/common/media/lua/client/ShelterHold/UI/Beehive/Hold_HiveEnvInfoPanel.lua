require "ISUI/ISPanel"

Hold_HiveEnvInfoPanel = ISPanel:derive("Hold_HiveEnvInfoPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveEnvInfoPanel:initialise()
    ISPanel.initialise(self)
end

function Hold_HiveEnvInfoPanel:new(x, y, width, height, hivePanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.hivePanel = hivePanel
    o.player = hivePanel.player
    o.entity = hivePanel.entity
    o.padding = hivePanel.padding

    o.indicatorIconSize = math.floor(FONT_HGT_MEDIUM * 2.5)
    o.statusIndicatorHeight = math.ceil(o.indicatorIconSize / 3)

    o.minimumWidth = o.indicatorIconSize * 2 + o.padding * 3
    o.minimumHeight = o.padding * 2 + o.indicatorIconSize + o.statusIndicatorHeight

    o.temperatureIcon = {
        cold = getTexture("media/ui/ShelterHold/Icon/Icon_Temperature_Cold.png"),
        good = getTexture("media/ui/ShelterHold/Icon/Icon_Temperature_Good.png"),
        hot = getTexture("media/ui/ShelterHold/Icon/Icon_Temperature_Hot.png"),
    }
    o.weatherIcon = {
        sun_normal = getTexture("media/ui/ShelterHold/Icon/weather_sun_normal.png"),
        sun_rain = getTexture("media/ui/ShelterHold/Icon/weather_sun_rain.png"),
        sun_snow = getTexture("media/ui/ShelterHold/Icon/weather_sun_snow.png"),
        night_normal = getTexture("media/ui/ShelterHold/Icon/weather_moon_normal.png"),
        night_rain = getTexture("media/ui/ShelterHold/Icon/weather_moon_rain.png"),
        night_snow = getTexture("media/ui/ShelterHold/Icon/weather_moon_snow.png"),
    }

    o.statusIcon = {
        good = getTexture("media/ui/ShelterHold/Icon/Status_Good.png"),
        bad = getTexture("media/ui/ShelterHold/Icon/Status_Bad.png"),
    }
    
    return o
end

function Hold_HiveEnvInfoPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    width = math.max(width, self.minimumWidth)
    height = math.max(height, self.minimumHeight)

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Temperature
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveEnvInfoPanel:getTemperatureStatusIcon()
    if self.hivePanel:getTemperature() == "Good" then
        return self.statusIcon.good
    else
        return self.statusIcon.bad
    end
end

function Hold_HiveEnvInfoPanel:getTemperatureIcon()
    if self.hivePanel:getTemperature() == "Cold" then
        return self.temperatureIcon.cold
    elseif self.hivePanel:getTemperature() == "Hot" then
        return self.temperatureIcon.hot
    else
        return self.temperatureIcon.good
    end
end
-- ----------------------------------------------------------------------------------------------------- --
-- Weather
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveEnvInfoPanel:getWeatherIcon()
    local weatherState = self.hivePanel:getWeatherState()
    
    if weatherState.isDayTime then
        -- day
        if weatherState.isSnowing then
            return self.weatherIcon.sun_snow
        elseif weatherState.isRaining then
            return self.weatherIcon.sun_rain
        else
            return self.weatherIcon.sun_normal
        end
    else
        -- night
        if weatherState.isSnowing then
            return self.weatherIcon.night_snow
        elseif weatherState.isRaining then
            return self.weatherIcon.night_rain
        else
            return self.weatherIcon.night_normal
        end
    end
end

function Hold_HiveEnvInfoPanel:getWeatherStatusIcon()
    local weatherState = self.hivePanel:getWeatherState()

    if weatherState.isDayTime and not weatherState.isRaining and not weatherState.isSnowing then
        return self.statusIcon.good
    else
        return self.statusIcon.bad
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update and Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveEnvInfoPanel:update()
    ISPanel.update(self)
end

function Hold_HiveEnvInfoPanel:prerender()
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerPanel_BG.png")
    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, 1)
    end

    -- temperature indicator
    local tempIcon = self:getTemperatureIcon()
    if tempIcon then
        local tempX = self.padding
        local tempY = self.padding
        self:drawTextureScaled(tempIcon, tempX, tempY, self.indicatorIconSize, self.indicatorIconSize, 1, 1, 1, 1)

        -- temperature status indicator
        local tempStatusIcon = self:getTemperatureStatusIcon()
        if tempStatusIcon then
            local statusY = self.height - self.padding - self.statusIndicatorHeight
            self:drawTextureScaled(tempStatusIcon, tempX, statusY, self.indicatorIconSize, self.statusIndicatorHeight, 1, 1, 1, 1)
        end
    end

    -- weather indicator
    local weatherIcon = self:getWeatherIcon()
    if weatherIcon then
        local weatherX = self.padding + self.indicatorIconSize + self.padding
        local weatherY = self.padding
        self:drawTextureScaled(weatherIcon, weatherX, weatherY, self.indicatorIconSize, self.indicatorIconSize, 1, 1, 1, 1)
        
        -- weather status indicator
        local weatherStatusIcon = self:getWeatherStatusIcon()
        if weatherStatusIcon then
            local statusY = self.height - self.padding - self.statusIndicatorHeight
            self:drawTextureScaled(weatherStatusIcon, weatherX, statusY, self.indicatorIconSize, self.statusIndicatorHeight, 1, 1, 1, 1)
        end
    end
end

return Hold_HiveEnvInfoPanel