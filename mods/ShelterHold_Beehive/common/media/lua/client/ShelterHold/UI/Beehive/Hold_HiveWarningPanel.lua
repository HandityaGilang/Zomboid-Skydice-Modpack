require "ISUI/ISPanel"

Hold_HiveWarningPanel = ISPanel:derive("Hold_HiveWarningPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveWarningPanel:initialise()
    ISPanel.initialise(self)
end

function Hold_HiveWarningPanel:new(x, y, width, height, hivePanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.hivePanel = hivePanel
    o.player = hivePanel.player
    
    o.padding = hivePanel.padding
    o.iconSize = math.floor(FONT_HGT_SMALL * 2 / 2) * 2

    o.minimumWidth = o.padding * 2 + o.iconSize

    o.warningIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Warning.png")
    o.checkIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Check.png")

    o.lastWarningCount = 0
    o.lastWarningHash = ""
    
    return o
end

function Hold_HiveWarningPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    local warnings = self:getActiveWarnings()

    if #warnings == 0 then
        local totalTextHeight = FONT_HGT_SMALL * 2
        local contentHeight = math.max(self.iconSize, totalTextHeight)
        local totalHeight = self.padding * 2 + contentHeight

        width = math.max(width, self.minimumWidth)
        height = math.max(height, totalHeight)

        self:setX(self.padding)
        self:setWidth(width - self.padding * 2)
        self:setHeight(height)
        return
    end

    local totalTextHeight = 0
    for i, warning in ipairs(warnings) do
        totalTextHeight = totalTextHeight + FONT_HGT_SMALL
        if warning.detail and warning.detail ~= "" then
            totalTextHeight = totalTextHeight + FONT_HGT_SMALL
        end
        if i < #warnings then
            totalTextHeight = totalTextHeight + self.padding / 2
        end
    end
    
    local contentHeight = math.max(self.iconSize, totalTextHeight)
    local totalHeight = self.padding * 2 + contentHeight

    width = math.max(width, self.minimumWidth)
    height = math.max(height, totalHeight)

    self:setX(self.padding)
    self:setWidth(width - self.padding * 2)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Status Check Methods
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveWarningPanel:getActiveWarnings()
    local warnings = {}
    local modData = self.hivePanel.entity:getModData()
    local bee = modData.queenBee
    
    -- Queen Status
    if not bee then
        table.insert(warnings, {
            text = getText("Tooltip_Beehive_NeedBee"),
            detail = getText("Tooltip_Beehive_NeedBeeInfo"),
            color = {r = 1 ,g = 0.2 ,b = 0.2},
        })
    end

    -- Entity Status
    if not modData.exterior then
        table.insert(warnings, {
            text = getText("Tooltip_Beehive_Indoor"),
            detail = getText("Tooltip_Beehive_IndoorInfo"),
            color = {r = 0.8 ,g = 0.8 ,b = 0.2},
        })
    end
    
    -- Temperature Status
    if bee then
        local temperature = self.hivePanel:getTemperature()
        if bee ~= "Bumblebee" then
            if temperature == "Cold" then
                table.insert(warnings, {
                    text = getText("Tooltip_Beehive_TooCold"),
                    detail = getText("Tooltip_Beehive_StopWorkingInfo"),
                    color = {r = 0.8 ,g = 0.8 ,b = 0.2},
                })
            elseif temperature == "Hot" then
                table.insert(warnings, {
                    text = getText("Tooltip_Beehive_TooHot"),
                    detail = getText("Tooltip_Beehive_StopWorkingInfo"),
                    color = {r = 0.8 ,g = 0.8 ,b = 0.2},
                })
            end
        end
        
        -- Time Status
        local weatherState = self.hivePanel:getWeatherState()
        if bee ~= "Zombee" then
            if not weatherState.isDayTime then
                table.insert(warnings, {
                    text = getText("Tooltip_Beehive_isNight"),
                    detail = getText("Tooltip_Beehive_isNightInfo"),
                    color = {r = 0.8 ,g = 0.8 ,b = 0.2},
                })
            end

            -- Weather Status
            if weatherState.isRaining or weatherState.isSnowing then
                table.insert(warnings, {
                    text = getText("Tooltip_Beehive_BadWeather"),
                    detail = getText("Tooltip_Beehive_StopWorkingInfo"),
                    color = {r = 0.8 ,g = 0.8 ,b = 0.2},
                })
            end
        end
    end
    
    return warnings
end

-- ----------------------------------------------------------------------------------------------------- --
-- Warning Change Detection
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveWarningPanel:getWarningHash()
    local warnings = self:getActiveWarnings()
    local hash = ""
    for _, warning in ipairs(warnings) do
        hash = hash .. warning.text .. "|"
    end
    return hash
end

function Hold_HiveWarningPanel:checkWarningChanged()
    local currentWarnings = self:getActiveWarnings()
    local currentCount = #currentWarnings
    local currentHash = self:getWarningHash()
    
    if currentCount ~= self.lastWarningCount or currentHash ~= self.lastWarningHash then
        self.lastWarningCount = currentCount
        self.lastWarningHash = currentHash
        return true
    end
    
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update and Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveWarningPanel:update()
    ISPanel.update(self)

    if self:checkWarningChanged() then
        self.hivePanel:calculateLayout()
    end
end

function Hold_HiveWarningPanel:prerender()
    -- background
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerPanel_BG.png")
    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, 1)
    end

    local warnings = self:getActiveWarnings()
    -- All Working Fine
    if #warnings == 0 then
        --Icon
        local currentX = self.padding
        self:drawTextureScaled(self.checkIcon, currentX, self.padding, self.iconSize, self.iconSize, 1, 1, 1, 1)
        currentX = currentX + self.iconSize + self.padding
        
        -- Title
        local currentY = self.padding
        local titleText = getText("Tooltip_Beehive_WorkingFine")
        local detailText = getText("Tooltip_Beehive_WorkingFineInfo")
        self:drawText(titleText, currentX, currentY, 0.2, 1, 0.2, 1, UIFont.Small)
        currentY = currentY + FONT_HGT_SMALL
        
        -- Detail
        self:drawText(detailText, currentX, currentY, 0.5, 0.5, 0.5, 0.8, UIFont.Small)
        
        return
    end
    
    -- Warning Icon
    local currentX = self.padding
    self:drawTextureScaled(self.warningIcon, currentX, self.padding, self.iconSize, self.iconSize, 1, 1, 1, 1)
    currentX = currentX + self.iconSize + self.padding
    
    local currentY = self.padding
    for i, warning in ipairs(warnings) do
        -- Warning Title
        self:drawText(warning.text, currentX, currentY, warning.color.r, warning.color.g, warning.color.b, 1, UIFont.Small)
        currentY = currentY + FONT_HGT_SMALL

        -- Warning Detail
        if warning.detail and warning.detail ~= "" then
            self:drawText(warning.detail, currentX, currentY, 0.5, 0.5, 0.5, 0.5, UIFont.Small)
            currentY = currentY + FONT_HGT_SMALL
        end

        if i < #warnings then
            currentY = currentY + self.padding / 2
        end
    end
end

return Hold_HiveWarningPanel
