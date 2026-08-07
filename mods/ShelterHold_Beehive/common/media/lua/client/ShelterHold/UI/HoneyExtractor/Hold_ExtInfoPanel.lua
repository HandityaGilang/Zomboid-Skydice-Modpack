require "ISUI/ISPanel"

Hold_ExtInfoPanel = ISPanel:derive("Hold_ExtInfoPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtInfoPanel:initialise()
    ISPanel.initialise(self)
end

function Hold_ExtInfoPanel:new(x, y, width, height, extPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.extPanel = extPanel
    o.player = extPanel.player
    o.entity = extPanel.entity
    o.padding = extPanel.padding

    o.extButtonHeight = FONT_HGT_SMALL * 2
    o.extButtonWidth = o.extButtonHeight * 2
    o.progressHeight = math.floor(FONT_HGT_SMALL * 1.4)

    o.extractProgress = 0
    o.progressDecayRate = 0.4

    o.extTex = {
        normal = getTexture("media/ui/ShelterHold/Button/CanCraft.png"),
        press = getTexture("media/ui/ShelterHold/Button/CanCraft_Pressed.png"),
        unable = getTexture("media/ui/ShelterHold/Button/CannotCraft.png"),
    }

    o.progressBorder = {
        L = getTexture("media/ui/ShelterHold/Progress/Normal_Border_L.png"),
        M = getTexture("media/ui/ShelterHold/Progress/Normal_Border_M.png"),
        R = getTexture("media/ui/ShelterHold/Progress/Normal_Border_R.png"),
    }

    o.progressFill = {
        L = getTexture("media/ui/ShelterHold/Progress/Normal_Fill_L.png"),
        M = getTexture("media/ui/ShelterHold/Progress/Normal_Fill_M.png"),
        R = getTexture("media/ui/ShelterHold/Progress/Normal_Fill_R.png"),
    }
    
    local maxText = getText("Fluid_Stored") .. getText("Fluid_Free") .. " 1000ml"
    o.minimumWidth = getTextManager():MeasureStringX(UIFont.Small,maxText) + o.padding * 2
    o.minimumHeight = FONT_HGT_SMALL * 3 + FONT_HGT_MEDIUM + o.extButtonHeight + o.progressHeight + o.padding * 4.5
    
    return o
end

function Hold_ExtInfoPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.minimumWidth)
    local height = math.max(_preferredHeight or 0, self.minimumHeight)

    if self.extButton then
        local buttonX = (width - self.extButtonWidth) / 2
        local buttonY = height - self.extButtonHeight
        self.extButton:setX(buttonX)
        self.extButton:setY(buttonY)
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Button
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtInfoPanel:createChildren()
    self.extButton = ISButton:new(0, 0, self.extButtonWidth, self.extButtonHeight, "", self, self.onExtButtonClick)
    self.extButton.enable = false
    self.extButton:initialise()
    self.extButton.prerender = function (btn)
        local tex = btn.pressed and self.extTex.press or self.extTex.normal
        if not btn.enable then
            tex = self.extTex.unable
        end
        btn:drawTextureScaled(tex, 0, 0, btn.width, btn.height, 1, 1, 1, 1)
    end
    self:addChild(self.extButton)
end

function Hold_ExtInfoPanel:onExtButtonClick()
    self.extractProgress = math.min(self.extractProgress + 0.2, 1.0)

    if not self.extPanel:walkToEntity() then return end
    if self.extractProgress >= 1.0 then
        local action = Hold_ExtractHoneyAction:new(self.player, self.entity)
        action.UItarget = self.extPanel
        ISTimedActionQueue.add(action)
        self.extractProgress = 1
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update and Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtInfoPanel:update()
    ISPanel.update(self)
    self.extButton.enable = self.extPanel.canExtract
end

function Hold_ExtInfoPanel:prerender()
    if self.extractProgress > 0 then
        local deltaTime = getGameTime():getTimeDelta()
        self.extractProgress = math.max(0, self.extractProgress - self.progressDecayRate * deltaTime)
    end

    local textY = 0
    local textX = self.padding
    
    local fluidContainer = self.entity:getFluidContainer()
    local amount = fluidContainer:getAmount()
    local capacity = fluidContainer:getCapacity()
    local free = fluidContainer:getFreeCapacity()

    -- Type Name
    local fluidType = getText("ContextMenu_Empty")
    local color = {r = 1, g = 1, b = 1}
    if not self.entity:getFluidContainer():isEmpty() then
        fluidType = fluidContainer:getPrimaryFluid():getDisplayName()
        local c = fluidContainer:getPrimaryFluid():getColor()
        color = {r = c:getR(), g = c:getG(), b = c:getB()}
    end
    self:drawText(fluidType, textX, textY, color.r, color.g, color.b, 1, UIFont.Medium)
    textY = textY + FONT_HGT_MEDIUM + self.padding / 2

    local color = self.entity:getFluidContainer():isFull() and {r = 0.8, g = 0.2, b = 0.2} or {r = 1, g = 1, b = 1}

    -- Capacity
    local capacityText = FluidUtil.getAmountFormatted(capacity)
    self:drawText(getText("Fluid_Capacity"), textX, textY, 1, 1, 1, 1, UIFont.Small)
    self:drawTextRight(capacityText, self.width - self.padding, textY, 1, 1, 1, 1, UIFont.Small)
    textY = textY + FONT_HGT_SMALL + self.padding / 2

    -- Free
    local freeText = FluidUtil.getAmountFormatted(free)
    self:drawText(getText("Fluid_Free"), textX, textY, 1, 1, 1, 1, UIFont.Small)
    self:drawTextRight(freeText, self.width - self.padding, textY, color.r, color.g, color.b, 1, UIFont.Small)
    textY = textY + FONT_HGT_SMALL + self.padding / 2

    -- Amount
    local amoutText = FluidUtil.getAmountFormatted(amount)
    self:drawText(getText("Fluid_Stored"), textX, textY, 1, 1, 1, 1, UIFont.Small)
    self:drawTextRight(amoutText, self.width - self.padding, textY, color.r, color.g, color.b, 1, UIFont.Small)


    local progressWidth = self.width - self.padding * 2
    local progress = math.floor(progressWidth * self.extractProgress)
    local progressY = self.extButton:getY() - self.padding - self.progressHeight
    local color = self.extPanel.actionExtract and {r = 0.8, g = 0.6, b = 0.2} or {r = 0.8, g = 0.8, b = 0.8}
    NeatTool.ThreePatch.drawHorizontal(self, self.padding, progressY, progress, self.progressHeight, self.progressFill.L, self.progressFill.M, self.progressFill.R, 1, color.r, color.g, color.b)
    NeatTool.ThreePatch.drawHorizontal(self, self.padding, progressY, progressWidth, self.progressHeight, self.progressBorder.L, self.progressBorder.M, self.progressBorder.R, 1, 0.6, 0.6, 0.6)

end

function Hold_ExtInfoPanel:render()
end

return Hold_ExtInfoPanel
