require "ISUI/ISUIElement"

NC_CraftOutput_Slot = ISUIElement:derive("NC_CraftOutput_Slot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- Constructor and initialization
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Slot:initialise()
    ISUIElement.initialise(self)

    self:updateOutputInfo()
end

function NC_CraftOutput_Slot:new(x, y, size, player, outputScript, parentpanel)
    local o = ISUIElement:new(x, y, size, size)
    setmetatable(o, self)
    self.__index = self
    
    o.size = size
    o.iconSize = size*0.6
    o.player = player
    o.outputScript = outputScript
    o.parentpanel = parentpanel
    o.logic = parentpanel.logic
    o.tooltip = nil

    o.outputAmount = 1
    if outputScript:getResourceType() == ResourceType.Item then
        o.outputAmount = outputScript:getIntAmount()
    elseif outputScript:getResourceType() == ResourceType.Fluid then
        o.outputAmount = outputScript:getAmount()
    end
    
    o.slotTextures = {
        background = getTexture("media/ui/Neat_Crafting/Button/SquareSLTBackground.png"),
        backgroundHover = getTexture("media/ui/Neat_Crafting/Button/SquareSLTHover.png"),
        border = getTexture("media/ui/Neat_Crafting/Button/SquareSLTBoarder.png"),
    }
    
    return o
end
-------------------------------------------------------------------------------------------------- --
-- Update output item info
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Slot:updateOutputInfo()
    if not self.outputScript then return end

    self.actualOutputItem = nil
    self.itemIcon = nil

    if self.outputScript:getResourceType() == ResourceType.Item then
        if self.logic and self.logic:isManualSelectInputs() then
            local outputMapper = self.outputScript:getOutputMapper()
            if outputMapper then
                local actualOutputItem = outputMapper:getOutputItem(self.logic:getRecipeData(), true)
                if actualOutputItem and actualOutputItem:getNormalTexture() then
                    self.itemIcon = actualOutputItem:getNormalTexture()
                    self.actualOutputItem = actualOutputItem
                end
            end
        end

        if not self.itemIcon then
            local outputObjects = self.outputScript:getPossibleResultItems()
            if outputObjects and outputObjects:size() > 0 then
                local item = outputObjects:get(0)
                self.itemIcon = item:getNormalTexture()
                self.actualOutputItem = item
            end
        end
    elseif self.outputScript:getResourceType() == ResourceType.Fluid then
        self.itemIcon = getTexture("media/textures/Item_Waterdrop_Grey.png")
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Interaction handling
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Slot:onMouseMove(dx, dy)
    if self:isMouseOver() and not self.tooltip then
        self:createTooltip()
    end
    return true
end

function NC_CraftOutput_Slot:onMouseMoveOutside(dx, dy)
    self:removeTooltip()
    return true
end

function NC_CraftOutput_Slot:onMouseDown(x, y)
    self:removeTooltip()

    -- Item outputs can be inspected in the output picker. Fluid outputs keep the old passive behavior.
    if self.outputScript and self.outputScript:getResourceType() == ResourceType.Item then
        getSoundManager():playUISound("UIActivateButton")
        local handCraftPanel = self.parentpanel and self.parentpanel.HandCraftPanel
        if handCraftPanel and handCraftPanel.toggleOutputSwitchPanel then
            handCraftPanel:toggleOutputSwitchPanel(self.outputScript)
        end
    end

    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Tooltip functionality
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Slot:createTooltip()
    if self.tooltip or not self.actualOutputItem then return end
    
    local displayName = self.actualOutputItem:getDisplayName()
    
    self.tooltip = ISToolTip:new()
    self.tooltip:initialise()
    self.tooltip:instantiate()
    self.tooltip:setOwner(self)
    self.tooltip:setName(displayName)
    self.tooltip:addToUIManager()
    self.tooltip:setVisible(true)
end

function NC_CraftOutput_Slot:removeTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end
-- ---

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Slot:prerender()
    self:drawTextureScaled(self.slotTextures.background, 0, 0, self.width, self.height, 0.8, 0.4, 0.4, 0.4)

    local selected = false
    local handCraftPanel = self.parentpanel and self.parentpanel.HandCraftPanel
    if handCraftPanel and handCraftPanel.getSelectedOutputScript then
        selected = handCraftPanel:getSelectedOutputScript() == self.outputScript
    end

    local borderColor = selected and 0.5 or 0.4
    self:drawTextureScaled(self.slotTextures.border, 0, 0, self.width, self.height, 0.8, borderColor, borderColor, borderColor)
    
    if selected then
        self:drawTextureScaled(self.slotTextures.backgroundHover, 0, 0, self.width, self.height, 0.35, 0.5, 0.5, 0.5)
    elseif self:isMouseOver() then
        self:drawTextureScaled(self.slotTextures.backgroundHover, 0, 0, self.width, self.height, 0.5, 0.5, 0.5, 0.5)
    end
end

function NC_CraftOutput_Slot:render()

    local iconX = (self.width - self.iconSize) / 2
    local iconY = (self.height - self.iconSize) / 2
    if self.itemIcon then
        self:drawTextureScaledAspect(self.itemIcon, iconX, iconY, self.iconSize, self.iconSize, 1, 1, 1, 1)
    end

    -- Amount Text
    if self.outputAmount > 1 then
        local textSize = self.size/4
        local textWidth = NeatTool.measureTextWidth(tostring(self.outputAmount), textSize, true)
        
        local textX = self.width - textWidth - self.size/16
        local textY = self.height - textSize - self.size/16

        NeatTool.renderText(self, tostring(self.outputAmount), textX, textY, textSize, 1.0, 1, 1, 1, true)
    end
end

return NC_CraftOutput_Slot