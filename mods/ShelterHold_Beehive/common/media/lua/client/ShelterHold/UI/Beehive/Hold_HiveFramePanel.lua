require "ISUI/ISPanel"

Hold_HiveFramePanel = ISPanel:derive("Hold_HiveFramePanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveFramePanel:initialise()
    ISPanel.initialise(self)
end

function Hold_HiveFramePanel:new(x, y, width, height, hivePanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.hivePanel = hivePanel
    o.entity = hivePanel.entity
    o.player = hivePanel.player
    o.padding = hivePanel.padding
    

    o.frameSlotHeight = math.floor(FONT_HGT_SMALL * 3)
    o.frameSlotWidth = o.frameSlotHeight * 3
    o.gridCols = 2
    o.gridRows = 3

    o.minimumWidth = o.padding * 2 + o.gridCols * o.frameSlotWidth + (o.gridCols - 1) * o.padding
    o.minimumHeight = o.padding * 2 + o.gridRows * o.frameSlotHeight + (o.gridRows - 1) * o.padding

    o.frameSlots = {}
    
    return o
end

function Hold_HiveFramePanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or self.width, self.minimumWidth)
    local height = math.max(_preferredHeight or self.height, self.minimumHeight)

    local slotSpacing = math.max((width - self.frameSlotWidth * self.gridCols) / (self.gridCols + 1), self.padding)
    local totalGridWidth = self.gridCols * self.frameSlotWidth + (self.gridCols - 1) * slotSpacing
    
    local startX = (width - totalGridWidth) / 2
    local startY = self.padding

    for i = 0, 5 do
        local slot = self.frameSlots[i]
        if slot then
            local col = i % self.gridCols
            local row = math.floor(i / self.gridCols)

            local slotX = startX + col * (self.frameSlotWidth + slotSpacing)
            local slotY = startY + row * (self.frameSlotHeight + self.padding)
            
            slot:setX(slotX)
            slot:setY(slotY)
            slot:setWidth(self.frameSlotWidth)
            slot:setHeight(self.frameSlotHeight)
        end
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveFramePanel:createChildren()
    for i = 0, 5 do
        self.frameSlots[i] = Hold_HiveFrameSlot:new(0, 0, 10, 10, self, i)
        self.frameSlots[i]:initialise()
        self.frameSlots[i].frameItem = self:getFrameResource(i):peekItem()
        self.frameSlots[i].resource = self:getFrameResource(i)
        self:addChild(self.frameSlots[i])
    end
end

function Hold_HiveFramePanel:getFrameResource(slotIndex)
    if self.entity:hasComponent(ComponentType.Resources) then
        local resources = self.entity:getComponent(ComponentType.Resources)
        local targetResourceId = "hive_frame_" .. slotIndex

        return resources:getResource(targetResourceId)
    end
    
    return nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveFramePanel:update()
    ISPanel.update(self)

    if self.entity and self.entity:hasComponent(ComponentType.Resources) then
        local resources = self.entity:getComponent(ComponentType.Resources)
        local frameResources = resources:getResourcesForGroup("hive_frame")
        
        for i = 0, frameResources:size() - 1 do
            if self.frameSlots[i] then
                self.frameSlots[i].frameItem = frameResources:get(i):peekItem()
            end
        end
    end
end

function Hold_HiveFramePanel:prerender()
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerPanel_BG.png")
    if bg then
        bg:render(self:getAbsoluteX() + self.padding, self:getAbsoluteY(), self.width - self.padding * 2, self.height, 0.1, 0.1, 0.1, 1)
    end
end

function Hold_HiveFramePanel:render()
    ISPanel.render(self)
end

return Hold_HiveFramePanel