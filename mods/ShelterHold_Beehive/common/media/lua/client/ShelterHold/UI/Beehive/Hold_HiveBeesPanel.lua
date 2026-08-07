require "ISUI/ISPanel"

Hold_HiveBeesPanel = ISPanel:derive("Hold_HiveBeesPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveBeesPanel:initialise()
    ISPanel.initialise(self)
end

function Hold_HiveBeesPanel:new(x, y, width, height, hivePanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.hivePanel = hivePanel
    o.player = hivePanel.player
    o.entity = hivePanel.entity
    
    o.padding = hivePanel.padding
    o.slotSize = math.floor(FONT_HGT_MEDIUM * 3.5)
    o.infoIconSize = math.floor(FONT_HGT_SMALL * 0.7)

    o.minimumWidth = o.padding * 3 + o.slotSize * 3
    o.minimumHeight = o.padding * 3 + o.slotSize

    o.progressTex = {
        on = getTexture("media/ui/ShelterHold/Progress/Progress_Triangle_On.png"),
        off = getTexture("media/ui/ShelterHold/Progress/Progress_Triangle_Off.png")
    }

    o.beeInfoIconTex = {
        temperature = getTexture("media/ui/ShelterHold/Icon/Icon_AffectedByTemperature.png"),
        time = getTexture("media/ui/ShelterHold/Icon/Icon_AffectedByTime.png"),
        weather = getTexture("media/ui/ShelterHold/Icon/Icon_AffectedByWeather.png"),
    }

    o.arrowCount = 3
    o.arrowSize = math.floor(FONT_HGT_MEDIUM * 0.8)
    o.timerMultiplierAnim = 0
    o.animOffset = -1
    
    return o
end

function Hold_HiveBeesPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    width = math.max(width, self.minimumWidth)
    height = math.max(height, self.minimumHeight)

    if self.queenSlot then
        self.queenSlot:setX(self.padding)
        self.queenSlot:setY(self.padding)
        self.queenSlot:setWidth(self.slotSize)
        self.queenSlot:setHeight(self.slotSize)
    end

    if self.temperatureIcon and self.timeIcon and self.weatherIcon then
        local iconSpacing = self.padding / 2
        local iconY = height - self.padding/2 - self.infoIconSize
        local startX = (self.padding * 2 + self.slotSize - self.infoIconSize * 3 - 4 * iconSpacing) / 2

        self.temperatureIcon:setX(startX)
        self.temperatureIcon:setY(iconY)

        self.timeIcon:setX(startX + self.infoIconSize + iconSpacing)
        self.timeIcon:setY(iconY)

        self.weatherIcon:setX(startX + (self.infoIconSize + iconSpacing) * 2)
        self.weatherIcon:setY(iconY)
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveBeesPanel:createChildren()
    self.queenSlot = Hold_HiveQueenSlot:new(0, 0, 10, 10, self)
    self.queenSlot.resource = self:getQueenResource()
    self.queenSlot:initialise()
    self:addChild(self.queenSlot)

    self.temperatureIcon = ISImage:new(0, 0, self.infoIconSize, self.infoIconSize, self.beeInfoIconTex.temperature)
    self.temperatureIcon:initialise()
    self.temperatureIcon.autoScale = true
    self.temperatureIcon:setVisible(false)
    self:addChild(self.temperatureIcon)

    self.timeIcon = ISImage:new(0, 0, self.infoIconSize, self.infoIconSize, self.beeInfoIconTex.time)
    self.timeIcon:initialise()
    self.timeIcon.autoScale = true
    self.timeIcon:setVisible(false)
    self:addChild(self.timeIcon)

    self.weatherIcon = ISImage:new(0, 0, self.infoIconSize, self.infoIconSize, self.beeInfoIconTex.weather)
    self.weatherIcon:initialise()
    self.weatherIcon.autoScale = true
    self.weatherIcon:setVisible(false)
    self:addChild(self.weatherIcon)
end

function Hold_HiveBeesPanel:getQueenResource()

    if self.entity and self.entity:hasComponent(ComponentType.Resources) then
        local resources = self.entity:getComponent(ComponentType.Resources)
        local queenResources = resources:getResourcesForGroup("queen_bee")
        
        return queenResources and queenResources:get(0) or nil
    end
    
    return nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveBeesPanel:update()
    ISPanel.update(self)

    local bee = self:getQueenResource():peekItem()

    if bee then
        local beeInfo = self.hivePanel:getBeeInfo(bee)

        if beeInfo.affectedByTemperature then
            self.temperatureIcon:setColor(0.6, 0.6, 0.6)
            self.temperatureIcon.mouseovertext = getText("Tooltip_Beehive_AffectedByTemperature")
        else
            self.temperatureIcon:setColor(0.2, 0.8, 0.2)
            self.temperatureIcon.mouseovertext = getText("Tooltip_Beehive_NotAffectedByTemperature")
        end

        if beeInfo.affectedByTime then
            self.timeIcon:setColor(0.6, 0.6, 0.6)
            self.timeIcon.mouseovertext = getText("Tooltip_Beehive_AffectedByTime")
        else
            self.timeIcon:setColor(0.2, 0.8, 0.2)
            self.timeIcon.mouseovertext = getText("Tooltip_Beehive_NotAffectedByTime")
        end

        if beeInfo.affectedByWeather then
            self.weatherIcon:setColor(0.6, 0.6, 0.6)
            self.weatherIcon.mouseovertext = getText("Tooltip_Beehive_AffectedByWeather")
        else
            self.weatherIcon:setColor(0.2, 0.8, 0.2)
            self.weatherIcon.mouseovertext = getText("Tooltip_Beehive_NotAffectedByWeather")
        end

        self.temperatureIcon:setVisible(true)
        self.timeIcon:setVisible(true)
        self.weatherIcon:setVisible(true)
    else
        self.temperatureIcon:setVisible(false)
        self.timeIcon:setVisible(false)
        self.weatherIcon:setVisible(false)
    end
end


function Hold_HiveBeesPanel:prerender()
    local bee = self:getQueenResource():peekItem()

    -- Background
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerPanel_BG.png")
    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, 1)
    end

    -- Bee Name
    local queenName = bee and bee:getDisplayName() or getText("IGUI_Hold_Beehive_NoBees")
    local nameX = self.padding + self.slotSize + self.padding
    local nameY = self.padding
    
    self:drawText(queenName, nameX, nameY, 1, 1, 1, 1, UIFont.Medium)

    -- Production Status
    local produceFactor = self.entity:getModData().produceFactor or 0
    if produceFactor > 0 then
        local ms = UIManager.getMillisSinceLastRender()
        self.timerMultiplierAnim = self.timerMultiplierAnim + ms
        if self.timerMultiplierAnim <= 500 then
            self.animOffset = -1
        elseif self.timerMultiplierAnim <= 1000 then
            self.animOffset = 0
        elseif self.timerMultiplierAnim <= 1500 then
            self.animOffset = 1
        elseif self.timerMultiplierAnim <= 2000 then
            self.animOffset = 2
        else
            self.timerMultiplierAnim = 0
        end
    else
        self.animOffset = -1
        self.timerMultiplierAnim = 0
    end

    -- Arrow Animation Area
    local arrowAreaX = self.padding + self.slotSize + self.padding
    local arrowSpacing = self.padding

    for i = 1, self.arrowCount do
        local arrowX = arrowAreaX + (i - 1) * (self.arrowSize + arrowSpacing)
        local arrowY = self.padding + (self.slotSize - self.arrowSize) / 2
        self:drawTextureScaled(self.progressTex.off, arrowX, arrowY, self.arrowSize, self.arrowSize, 1, 1, 1, 1)
    end

    if self.animOffset > -1 and self.animOffset < self.arrowCount then
        local arrowX = arrowAreaX + self.animOffset * (self.arrowSize + arrowSpacing)
        local arrowY = self.padding + (self.slotSize - self.arrowSize) / 2
        self:drawTextureScaled(self.progressTex.on, arrowX, arrowY, self.arrowSize, self.arrowSize, 1, 1, 1, 1)
    end

    -- Factor Text
    local text = "Stop"
    if produceFactor > 0 then
        text = "x " .. math.floor(produceFactor * 10) / 10
    end
    local textX = arrowAreaX
    local textY = self.padding + (self.slotSize - self.arrowSize) / 2 + self.arrowSize + self.padding
    local color = {r = 0.7, g = 0.7, b = 0.7}
    self:drawText(text, textX, textY, color.r, color.g, color.b, 1, UIFont.Small)
end

function Hold_HiveBeesPanel:render()
    ISPanel.render(self)
end

return Hold_HiveBeesPanel