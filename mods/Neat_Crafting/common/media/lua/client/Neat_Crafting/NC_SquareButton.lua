require "ISUI/ISButton"

NC_SquareButton = ISButton:derive("NC_SquareButton")

-- ----------------------------------------------------------------------------------------------------- --
-- Constructor and initialization
-- ----------------------------------------------------------------------------------------------------- --

function NC_SquareButton:initialise()
    ISButton.initialise(self)
end

function NC_SquareButton:new(x, y, size, iconTexture, target, onclick)
    local o = ISButton:new(x, y, size, size, "", target, onclick)
    setmetatable(o, self)
    self.__index = self
    o:setDisplayBackground(false)
    o.iconTexture = iconTexture
    o.iconSizeRatio = 0.8

    o.buttonBgTexture = getTexture("media/ui/NeatUI/Button/Background.png")
    o.buttonBorderTexture = getTexture("media/ui/NeatUI/Button/Boarder.png")

    o.isActive = false
    o.activeColor = {r=0.95, g=0.5, b=0.1}
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Configuration methods
-- ----------------------------------------------------------------------------------------------------- --

function NC_SquareButton:setIcon(iconTexture)
    self.iconTexture = iconTexture
end

function NC_SquareButton:setIconSizeRatio(ratio)
    self.iconSizeRatio = ratio
end

function NC_SquareButton:setActive(active)
    self.isActive = active
end

function NC_SquareButton:setActiveColor(r, g, b)
    self.activeColor = {r=r, g=g, b=b}
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render function
-- ----------------------------------------------------------------------------------------------------- --

function NC_SquareButton:render()
    if self.buttonBgTexture then
        if self.isActive then
            if self.pressed then
                -- Active and pressed
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 
                    self.activeColor.r * 0.8, self.activeColor.g * 0.8, self.activeColor.b * 0.8)
            elseif self:isMouseOver() then
                -- Active and hovered
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 
                    math.min(self.activeColor.r * 1.2, 1), math.min(self.activeColor.g * 1.2, 1), math.min(self.activeColor.b * 1.2, 1))
            else
                -- Active default state
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 
                    self.activeColor.r, self.activeColor.g, self.activeColor.b)
            end
        else
            -- Inactive state
            if self.pressed then
                -- Pressed
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 0.1, 0.1, 0.1)
            elseif self:isMouseOver() then
                -- Hover
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 0.3, 0.3, 0.3)
            else
                -- Default state
                self:drawTextureScaled(self.buttonBgTexture, 0, 0, self.width, self.height, 0.8, 0.2, 0.2, 0.2)
            end
        end
    end

    if self.buttonBorderTexture then
        self:drawTextureScaled(self.buttonBorderTexture, 0, 0, self.width, self.height, 1, 0.4, 0.4, 0.4)
    end

    if self.iconTexture then
        local currentIconSize = math.floor(math.min(self.width, self.height) * self.iconSizeRatio)
        local iconX = math.floor((self.width - currentIconSize) / 2)
        local iconY = math.floor((self.height - currentIconSize) / 2)
        self:drawTextureScaled(self.iconTexture, iconX, iconY, currentIconSize, currentIconSize, 1, 0.9, 0.9, 0.9)
    end
end

return NC_SquareButton