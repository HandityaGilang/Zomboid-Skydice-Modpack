require "ISUI/ISPanel"

Hold_ExtInputPanel = ISPanel:derive("Hold_ExtInputPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtInputPanel:initialise()
    ISPanel.initialise(self)
end

function Hold_ExtInputPanel:new(x, y, width, height, extPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.extPanel = extPanel
    o.player = extPanel.player
    o.entity = extPanel.entity
    
    o.padding = extPanel.padding
    o.slotSize = math.floor(FONT_HGT_MEDIUM * 3)

    o.slotCount = 4
    o.craftTex = {
        normal = getTexture("media/ui/ShelterHold/Button/CanCraft.png"),
        press = getTexture("media/ui/ShelterHold/Button/CanCraft_Pressed.png"),
    }

    o.minimumHeight = o.padding * 3 + o.slotSize
    o.minimumWidth = o.padding * 4 + o.slotSize * o.slotCount + o.padding * (o.slotCount - 1)

    o.inputSlots = {}
    
    return o
end

function Hold_ExtInputPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height
    
    width = math.max(width, self.minimumWidth)
    height = math.max(height, self.minimumHeight)

    if self.slotCount > 0 then
        local slotPadding = math.max((width - self.padding * 2 - self.slotSize * self.slotCount) / (self.slotCount + 1),self.padding)
        local startX = self.padding + slotPadding
        local startY = self.padding

        for i = 0, self.slotCount do
            local slot = self.inputSlots[i]
            if slot then
                local slotX = startX + i * (self.slotSize + slotPadding)
                slot:setX(slotX)
                slot:setY(startY)
                slot:setWidth(self.slotSize)
                slot:setHeight(self.slotSize)
            end
        end
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtInputPanel:createChildren()
    for i = 0, self.slotCount - 1 do
        self.inputSlots[i] = Hold_InputSlot:new(0, 0, 10, 10, self, i)
        self.inputSlots[i]:initialise()
        self.inputSlots[i].extractProgress = self.extractProgress
        self.inputSlots[i].resource = self:getFrameResource(i)
        self:addChild(self.inputSlots[i])
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Helper Methods
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtInputPanel:getFrameResource(slotIndex)
    if self.entity:hasComponent(ComponentType.Resources) then
        local resources = self.entity:getComponent(ComponentType.Resources)
        local targetResourceId = "input_slot_" .. slotIndex

        return resources:getResource(targetResourceId)
    end
    return nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update and Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtInputPanel:update()
    ISPanel.update(self)
end

function Hold_ExtInputPanel:prerender()
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerPanel_BG.png")
    if bg then
        bg:render(self:getAbsoluteX() + self.padding, self:getAbsoluteY(), self.width - self.padding * 2, self.height, 0.1, 0.1, 0.1, 1)
    end
end

function Hold_ExtInputPanel:render()
end

return Hold_ExtInputPanel