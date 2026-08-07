require "Entity/ISUI/Controls/ISTableLayout"
require "ShelterHold/Hold_BeehiveCompat"

Hold_HivePanel = ISTableLayout:derive("Hold_HivePanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HivePanel:initialise()
    ISTableLayout.initialise(self)
end

function Hold_HivePanel:new(x, y, width, height, entity, parentWindow)
    local o = ISTableLayout:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.parentWindow = parentWindow
    o.player = parentWindow.player
    o.playerNum = parentWindow.playerNum
    o.entity = entity

    o.padding = parentWindow.padding
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HivePanel:createChildren()
    self:addColumnFill(nil)

    local spacingRow0 = self:addRow(nil)
    spacingRow0.minimumHeight = self.padding

    self.warningCell = self:addRow(nil)

    local spacingRow1 = self:addRow(nil)
    spacingRow1.minimumHeight = self.padding

    self.requiredCell = self:addRow(nil)

    if self:shouldShowPlantBoostPanel() then
        local spacingRow2 = self:addRow(nil)
        spacingRow2.minimumHeight = self.padding

        self.PlantBoostCell = self:addRow(nil)
        self:createPlantBoostCell()
    end

    local spacingRow3 = self:addRow(nil)
    spacingRow3.minimumHeight = self.padding

    self.hiveFrameCell = self:addRow(nil)

    local spacingRow4 = self:addRow(nil)
    spacingRow4.minimumHeight = self.padding

    self:createWarningCell()
    self:createRequiredCell()
    self:createHiveFrameCell()
end
function Hold_HivePanel:createPlantBoostCell()
    self.plantBoostPanel = Hold_HivePlantBoostInfoPanel:new(0, 0, 10, 10, self)
    self.plantBoostPanel:initialise()
    self:setElement(0, self.PlantBoostCell:index(), self.plantBoostPanel)
end

function Hold_HivePanel:createWarningCell()
    self.warningPanel = Hold_HiveWarningPanel:new(0, 0, 10, 10, self)
    self.warningPanel:initialise()
    self:setElement(0, self.warningCell:index(), self.warningPanel)
end

function Hold_HivePanel:createRequiredCell()
    self.requiredCellPanel = Hold_HiveRequiredCell:new(0, 0, 10, 10, self)
    self.requiredCellPanel:initialise()
    self:setElement(0, self.requiredCell:index(), self.requiredCellPanel)

    self.beesPanel = self.requiredCellPanel.beesPanel
end

function Hold_HivePanel:createHiveFrameCell()
    self.hiveFramePanel = Hold_HiveFramePanel:new(0, 0, 10, 10, self)
    self.hiveFramePanel:initialise()
    self:setElement(0, self.hiveFrameCell:index(), self.hiveFramePanel)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Valid
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HivePanel:isValidQueenBee(item)
	if not item then return false end
	if HoldBeehiveCompat.isQueenBee(item) then return true end
	
	return false
end

function Hold_HivePanel:isValidHiveFrame(item)
	if not item then return false end
	if HoldBeehiveCompat.isHiveFrame(item) and item:getCondition() > 0 then return true end
	
	return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Environment Info
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HivePanel:getTemperature()
	local temperature = getClimateManager():getTemperature()
	if temperature > 32 then
		return "Hot"
	elseif temperature < 12 then
		return "Cold"
	else
		return "Good"
	end
end

function Hold_HivePanel:getWeatherState()
	return {
		isDayTime = getGameTime():isDay(),
		isRaining = getClimateManager():isRaining(),
		isSnowing = getClimateManager():isSnowing()
	}
end

function Hold_HivePanel:getBeeInfo(bee)
    if bee:getType() == "Zombee" then
        return {
            affectedByTemperature = false,
            affectedByTime = true,
            affectedByWeather = false,
        }
    elseif bee:getType() == "Bumblebee" then
        return {
            affectedByTemperature = false,
            affectedByTime = true,
            affectedByWeather = true,
        }
    elseif bee:getType() == "Honeybee" then
        return {
            affectedByTemperature = true,
            affectedByTime = true,
            affectedByWeather = true,
        }
    end
end

function Hold_HivePanel:getPlantsCountNearby()
    local range = self.entity:getModData().boostPlantArea
    if not range then return 0 end


    return false
end

function Hold_HivePanel:shouldShowPlantBoostPanel()
    local modData = self.entity:getModData()
    return modData.queenBee ~= nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HivePanel:update()
    ISTableLayout.update(self)
end

function Hold_HivePanel:prerender()
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/MainPanelBG_FlatTop.png")
    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.15, 0.15, 0.15, 1)
    end
end

function Hold_HivePanel:render()
    ISPanel.render(self)
end