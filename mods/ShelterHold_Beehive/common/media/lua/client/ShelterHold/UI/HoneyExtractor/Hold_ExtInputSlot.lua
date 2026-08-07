require "ISUI/ISPanel"
require "ShelterHold/Hold_BeehiveCompat"

Hold_InputSlot = ISPanel:derive("Hold_InputSlot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_InputSlot:initialise()
    ISPanel.initialise(self)
end

function Hold_InputSlot:new(x, y, width, height, inputPanel, slotId)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.inputPanel = inputPanel
    o.extPanel = inputPanel.extPanel
    o.player = inputPanel.player
    o.slotId = slotId  -- Changed from slotIndex to slotId
    o.entity = inputPanel.entity
    
    o.padding = inputPanel.padding
    o.isDropTarget = false
    o.isInvalidDropTarget = false

    o.emptySlotIcon = getTexture("media/ui/ShelterHold/Icon/Icon_HiveFrameFullNeed.png")
    o.frameIcon = {
        wax = getTexture("media/ui/ShelterHold/Icon/Icon_HiveFrameWax.png"),
        full = getTexture("media/ui/ShelterHold/Icon/Icon_HiveFrameFull.png"),
        empty = getTexture("media/ui/ShelterHold/Icon/Icon_HiveFrameEmpty.png")
    }
    
    o.pickIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Pick.png")
    o.borkenIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Borken.png")
    o.buttonBg = getTexture("media/ui/ShelterHold/Button/Small_Circle_Bg.png")
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Helper Functions
-- ----------------------------------------------------------------------------------------------------- --
function Hold_InputSlot:onAddFullFrame(item)
    if not item then return end

    ISInventoryPaneContextMenu.transferIfNeeded(self.player, item)

    if not self.extPanel:walkToEntity() then return end

    local action = HE_ItemSlotAddAction:new(self.player, self.entity, item, self.resource)
    action.itemSlot = self
    action.maxTime = 80
    ISTimedActionQueue.add(action)
end

function Hold_InputSlot:SearchForFullFrame()
    local frames = {}
    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    local allItems = ArrayList.new()
    CraftRecipeManager.getAllItemsFromContainers(containers, allItems)

    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if self.extPanel:isValidHoneyFrame(item) then
            table.insert(frames, item)
        end
    end
    
    return frames
end

function Hold_InputSlot:createContextMenu(x, y)
    local context = ISContextMenu.get(self.player:getPlayerNum(), x + self:getAbsoluteX() + 5, y + self:getAbsoluteY() + 5)
    context:setAlwaysOnTop(true)
    
    local frames = self:SearchForFullFrame()
    
    if #frames == 0 then
        local option = context:addOption(getText("IGUI_Hold_Beehive_NoFullFrameFound"), self, nil)
        option.notAvailable = true
    else
        for _, item in ipairs(frames) do
            local itemName = item:getDisplayName()
            local option = context:addOption(itemName, self, self.onAddFullFrame, item)
            
            -- Add icon if available
            local itemTexture = item:getTex()
            if itemTexture then
                option.iconTexture = itemTexture
            end
        end
    end
    
    return context
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Events
-- ----------------------------------------------------------------------------------------------------- --
function Hold_InputSlot:onMouseMove(dx, dy)
    if ISMouseDrag.dragging then
        local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if draggedItems and #draggedItems > 0 then
            local draggedItem = draggedItems[1]
            if self.extPanel:isValidHoneyFrame(draggedItem) and self.resource:isEmpty() then
                self.isDropTarget = true
                self.isInvalidDropTarget = false
            else
                self.isDropTarget = false
                self.isInvalidDropTarget = self.resource:isEmpty()
            end
        else
            self.isDropTarget = false
            self.isInvalidDropTarget = false
        end
    else
        self.isDropTarget = false
        self.isInvalidDropTarget = false
    end
    
    return true
end

function Hold_InputSlot:onMouseMoveOutside(dx, dy)
    self.isDropTarget = false
    self.isInvalidDropTarget = false
    return true
end

function Hold_InputSlot:onMouseUp(x, y)
    if ISMouseDrag.dragging and self.isDropTarget then
        local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if draggedItems and #draggedItems > 0 then
            local draggedItem = draggedItems[1]
            if self.resource:isEmpty() then
                self:onAddFullFrame(draggedItem)

                ISMouseDrag.dragging = nil
                ISMouseDrag.dragView = nil
            end
        end
    end
    
    self.isDropTarget = false
    self.isInvalidDropTarget = false
    return true
end

function Hold_InputSlot:onMouseDown(x, y)
    if not self.resource:isEmpty() then
        if not self.extPanel:walkToEntity() then return end
        local action = HE_ItemSlotRemoveAction:new(self.player, self.entity, self.resource, nil)
        action.itemSlot = self
        action.maxTime = 40
        ISTimedActionQueue.add(action)
    end

    if self.resource:isEmpty() and not ISMouseDrag.dragging and not (self.actionAdd or self.actionRemove) then
        self:createContextMenu(x, y)
        return true
    end
    
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update and Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_InputSlot:update()
    ISPanel.update(self)
end

function Hold_InputSlot:getFrameIcon(item)
    if not item then return self.emptySlotIcon end
    
    if HoldBeehiveCompat.isFullHiveFrame(item) then
        return self.frameIcon.full
    elseif HoldBeehiveCompat.isWaxHiveFrame(item) then
        return self.frameIcon.wax
    elseif HoldBeehiveCompat.isEmptyHiveFrame(item) then
        return self.frameIcon.empty
    end
end

function Hold_InputSlot:prerender()
    local item = self.resource:peekItem()
    -- Background
    local r, g, b = 0.15, 0.15, 0.15
    if self.isButtonHovered then
        r, g, b = 0.2, 0.2, 0.2
    end
    
    local slotBG = NinePatchTexture.getSharedTexture("media/ui/ShelterHold/Slot/SlotBG_IconSide.png")
    if slotBG then
        slotBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, r, g, b, 0.8)
    end

    -- Add/Remove JobDelta
    if self.actionAdd then
        local delta = self.actionAdd:getJobDelta()
        self:setStencilRect(0, 0, self.width, delta * self.height)
        slotBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.2, 0.8, 0.2, 0.5)
        self:clearStencilRect()
    elseif self.actionRemove then
        local delta = self.actionRemove:getJobDelta()
        self:setStencilRect(0, delta * self.height, self.width, self.height)
        slotBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.8, 0.2, 0.2, 0.5)
        self:clearStencilRect()
    end
    
    -- Border
    if self.isDropTarget then
        r, g, b = 0.2, 1, 0.2
    elseif self.isInvalidDropTarget or (item and not self.extPanel:isValidHoneyFrame(item)) then
        r, g, b = 1, 0.2, 0.2
    else
        r, g, b = 0.2, 0.2, 0.2
    end
    
    local slotBoarder = NinePatchTexture.getSharedTexture("media/ui/ShelterHold/Slot/SlotBoarder.png")
    if slotBoarder then
        slotBoarder:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, r, g, b, 1)
    end

    -- Icon
    local item = self.resource:peekItem()
    local icon = self:getFrameIcon(item)
    local iconSize = self.width * 0.8
    local iconXY = (self.width - iconSize) / 2
    self:drawTextureScaled(icon, iconXY, iconXY, iconSize, iconSize, 1, 1, 1, 1)

    if item and item:getCondition() <= 0 then
        local borkenIconSize = math.floor(self.width * 0.3)
        local borkenIconX = self.width - borkenIconSize - self.padding / 2
        local borkenIconY = self.height - borkenIconSize - self.padding / 2
        self:drawTextureScaled(self.borkenIcon, borkenIconX, borkenIconY, borkenIconSize, borkenIconSize, 1, 1, 1, 1)
    end

    if item and self:isMouseOver() then
        local buttonSize = math.floor(self.width / 2)
        local buttonXY = (self.width - buttonSize) / 2
        self:drawTextureScaled(self.buttonBg, buttonXY, buttonXY, buttonSize, buttonSize, 0.9, 0.1, 0.1, 0.1)
        self:drawTextureScaled(self.pickIcon, buttonXY, buttonXY, buttonSize, buttonSize, 0.8, 0.8, 0.8, 0.8)
    end

    -- Add Icon
    local addIconSize = math.floor(self.width * 0.3 / 2) * 2
    local addIconXY = (self.width - addIconSize) / 2
    if not item then
        local alpha = 0.7 + 0.3 * math.sin(getTimestampMs()/ 1000 * math.pi * 2)
        self:drawTextureScaled(getTexture("media/ui/ShelterHold/Icon/Icon_Plus.png"), addIconXY, addIconXY, addIconSize, addIconSize,alpha, 1, 1, 1)
    end
end

function Hold_InputSlot:render()
    ISPanel.render(self)
end

return Hold_InputSlot