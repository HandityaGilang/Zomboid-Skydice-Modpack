require "ISUI/ISPanel"

Hold_HivePlantBoostInfoPanel = ISPanel:derive("Hold_HivePlantBoostInfoPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HivePlantBoostInfoPanel:initialise()
    ISPanel.initialise(self)
end

function Hold_HivePlantBoostInfoPanel:new(x, y, width, height, hivePanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.hivePanel = hivePanel
    o.player = hivePanel.player
    o.entity = hivePanel.entity
    
    o.padding = hivePanel.padding
    o.iconSize = math.floor(FONT_HGT_SMALL * 2 / 2) * 2

    o.minimumWidth = o.padding * 2 + o.iconSize

    o.plantIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Plant.png")

    o.plantCount = 0
    
    return o
end

function Hold_HivePlantBoostInfoPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    local titleText = getText("Tooltip_Beehive_NearbyPlants")
    local detailText = getText("Tooltip_Beehive_PlantBoostInfo")

    -- Calculate required height for text
    local totalTextHeight = FONT_HGT_SMALL * 2 -- Title + detail
    local contentHeight = math.max(self.iconSize, totalTextHeight)
    local totalHeight = self.padding * 2 + contentHeight

    width = math.max(width, self.minimumWidth)
    height = math.max(height, totalHeight)

    self:setX(self.padding)
    self:setWidth(width - self.padding * 2)
    self:setHeight(height)
end
function Hold_HivePlantBoostInfoPanel:createChildren()
    self:getPlantsCountNearby()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Plant Counting Logic
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HivePlantBoostInfoPanel:getPlantsCountNearby()
    if not self.entity then return 0 end
    
    local modData = self.entity:getModData()
    local range = modData.boostPlantArea
    local rangeRadius = math.floor(range / 2)
    
    local x = self.entity:getX()
    local y = self.entity:getY()
    local z = self.entity:getZ()
    
    local plantCount = 0

    for dx = -rangeRadius, rangeRadius do
        for dy = -rangeRadius, rangeRadius do
            local targetX = x + dx
            local targetY = y + dy

            if CFarmingSystem and CFarmingSystem.instance then
                local plant = CFarmingSystem.instance:getLuaObjectAt(targetX, targetY, z)
                
                if plant and plant.nextGrowing then
                    plantCount = plantCount + 1
                end
            end
        end
    end
    
    self.plantCount = plantCount
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update and Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HivePlantBoostInfoPanel:update()
    ISPanel.update(self)
end

function Hold_HivePlantBoostInfoPanel:prerender()
    
    -- Background
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerPanel_BG.png")
    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, 1)
    end

    -- Icon
    local currentX = self.padding
    self:drawTextureScaled(self.plantIcon, currentX, self.padding, self.iconSize, self.iconSize, 1, 1, 1, 1)
    currentX = currentX + self.iconSize + self.padding
    
    -- Text
    local currentY = self.padding
    local titleText = getText("Tooltip_Beehive_NearbyPlants", self.plantCount)
    local range = self.entity:getModData().boostPlantArea
    local detailText = getText("Tooltip_Beehive_PlantBoostInfo", range, range )
    local titleColor = {r = 0.2, g = 0.8, b = 0.2}

    self:drawText(titleText, currentX, currentY, titleColor.r, titleColor.g, titleColor.b, 1, UIFont.Small)
    currentY = currentY + FONT_HGT_SMALL

    self:drawText(detailText, currentX, currentY, 0.5, 0.5, 0.5, 0.8, UIFont.Small)
end

return Hold_HivePlantBoostInfoPanel