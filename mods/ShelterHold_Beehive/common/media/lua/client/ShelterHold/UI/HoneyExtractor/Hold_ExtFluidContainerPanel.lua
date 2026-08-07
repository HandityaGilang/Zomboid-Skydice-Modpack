require "ISUI/ISPanel"

Hold_ExtFluidContainerPanel = ISPanel:derive("Hold_ExtFluidContainerPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtFluidContainerPanel:initialise()
    ISPanel.initialise(self)
end

function Hold_ExtFluidContainerPanel:new(x, y, width, height, extPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.extPanel = extPanel
    o.player = extPanel.player
    o.entity = extPanel.entity
    o.padding = extPanel.padding

    o.containerWidth = math.floor(math.floor(FONT_HGT_MEDIUM * 8) / 8) * 8
    o.containerHeight = math.floor(math.floor(FONT_HGT_MEDIUM * 8) / 8) * 8

    o.faucetButtonSize = o.containerHeight/4

    o.barrelTex = {
        border = getTexture("media/ui/ShelterHold/Progress/Barrel_Border.png"),
        fill = getTexture("media/ui/ShelterHold/Progress/Barrel_Fill.png"),
    }

    o.faucetTex = getTexture("media/ui/ShelterHold/Icon/Icon_Faucet.png")

    o.minimumWidth = o.containerWidth + o.padding * 2
    o.minimumHeight = o.containerHeight
    
    return o
end

function Hold_ExtFluidContainerPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height
    
    width = math.max(width, self.minimumWidth)
    height = math.max(height, self.minimumHeight)

    if self.faucet then
        self.faucet:setX(width - self.padding - self.faucetButtonSize)
        self.faucet:setY(height - self.faucetButtonSize)
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Button
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtFluidContainerPanel:createChildren()
    self.faucet = ISButton:new(0, 0, self.faucetButtonSize, self.faucetButtonSize, "", self, self.onfaucetClick)
    self.faucet:initialise()
    self.faucet.prerender = function (btn)
        local color = {r = 0.6, g = 0.6, b = 0.6}
        if self.entity:getFluidContainer():getAmount() > 0 then
            color = {r = 0.8, g = 0.5, b = 0.2}
        end
        local alpha = btn.mouseOver and 1 or 0.6
        btn:drawTextureScaled(self.faucetTex, 0, 0, btn.width, btn.height, alpha, color.r, color.g, color.b)
    end
    self:addChild(self.faucet)
end

function Hold_ExtFluidContainerPanel:onfaucetClick()
    if self.entity:getFluidContainer():getAmount() <= 0 then return end
    local fluidContainer = ISFluidContainer:new(self.entity:getFluidContainer())
    local action = ISFluidPanelAction:new(self.player, fluidContainer, ISFluidTransferUI, true)
    action.maxTime = 5
    ISTimedActionQueue.add(action)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update and Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtFluidContainerPanel:update()
    ISPanel.update(self)
end

function Hold_ExtFluidContainerPanel:prerender()
    local container = self.entity:getFluidContainer()
    local percentage = container:getAmount() / container:getCapacity()

    -- Fill
    if percentage > 0 then
        local c = container:getPrimaryFluid():getColor()
        self.javaObject:DrawTexturePercentageBottomUp(self.barrelTex.fill, percentage, self.padding, self.containerHeight/8, self.containerWidth, self.containerHeight*(27/32), c:getR(), c:getG(), c:getB(), 1)
    end
    
    -- Border
    self:drawTextureScaled(self.barrelTex.border, self.padding, 0, self.containerWidth, self.containerHeight, 1, 0.6, 0.6, 0.6)

end

return Hold_ExtFluidContainerPanel