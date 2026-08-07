require "ISUI/ISPanel"
require "ShelterHold/Hold_BeehiveCompat"

Hold_HiveFrameSlot = ISPanel:derive("Hold_HiveFrameSlot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveFrameSlot:initialise()
    ISPanel.initialise(self)
end

function Hold_HiveFrameSlot:new(x, y, width, height, parentPanel, slotIndex)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.parentPanel = parentPanel
    o.hivePanel = parentPanel.hivePanel
    o.player = parentPanel.player
    o.slotIndex = slotIndex
    o.frameItem = nil
    o.resource = nil
    
    o.padding = parentPanel.padding
    o.isDropTarget = false
    o.isInvalidDropTarget = false

    -- [texture] --
    o.slotBorder = getTexture("media/ui/ShelterHold/Slot/SlotBoarder.png")
    o.emptySlotIcon = getTexture("media/ui/ShelterHold/Icon/Icon_HiveFrameSearch.png")
    o.frameIcon = {
        empty = getTexture("media/ui/ShelterHold/Icon/Icon_HiveFrameEmpty.png"),
        wax = getTexture("media/ui/ShelterHold/Icon/Icon_HiveFrameWax.png"),
        full = getTexture("media/ui/ShelterHold/Icon/Icon_HiveFrameFull.png"),
    }
    o.progressBar = {
        border = getTexture("media/ui/ShelterHold/Progress/Progress_Hexagon_Border.png"),
        fill = getTexture("media/ui/ShelterHold/Progress/Progress_Hexagon_Fill.png"),
        waxCheck = getTexture("media/ui/ShelterHold/Progress/Progress_Frame_WaxCheck.png"),
        honeyCheck = getTexture("media/ui/ShelterHold/Progress/Progress_Frame_HoneyCheck.png"),
    }

    o.pickIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Pick.png")
    o.buttonBg = getTexture("media/ui/ShelterHold/Button/Small_Circle_Bg.png")
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Helper Functions
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveFrameSlot:SearchForHiveFrame()
    local hiveFrames = {}
    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    local allItems = ArrayList.new()
    CraftRecipeManager.getAllItemsFromContainers(containers, allItems)

    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item and self.hivePanel:isValidHiveFrame(item) then
            table.insert(hiveFrames, item)
        end
    end
    
    return hiveFrames
end

function Hold_HiveFrameSlot:createContextMenu(x, y)
    local context = ISContextMenu.get(self.player:getPlayerNum(), self:getAbsoluteX() + self.width, self:getAbsoluteY())
    context:setAlwaysOnTop(true)
    
    local hiveFrames = self:SearchForHiveFrame()
    
    if #hiveFrames == 0 then
        local option = context:addOption(getText("IGUI_Hold_Beehive_NoHiveFramesFound"), self, nil)
        option.notAvailable = true
    else
        for _, item in ipairs(hiveFrames) do
            local itemName = item:getDisplayName()
            local drain = math.floor(item:getCurrentUsesFloat() * 100)
            local optionText = itemName .. " (" .. drain .."%)"
            local option = context:addOption(optionText, self, self.onAddFrame, item)
            
            local itemTexture = item:getTex()
            if itemTexture then
                option.iconTexture = itemTexture
            end
        end
    end
    
    return context
end

function Hold_HiveFrameSlot:onAddFrame(item)
    if not item then return end
    
    local frameResource = self.parentPanel:getFrameResource(self.slotIndex)
    if frameResource then
        ISInventoryPaneContextMenu.transferIfNeeded(self.player, item)
        
        local action = Hold_AddHiveFrameAction:new(self.player, self.hivePanel.entity, item, self.slotIndex, frameResource)
        action.frameSlot = self
        ISTimedActionQueue.add(action)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Mouse Events
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveFrameSlot:onMouseMove(dx, dy)
    if ISMouseDrag.dragging then
        local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if draggedItems and #draggedItems > 0 then
            local draggedItem = draggedItems[1]
            if self.hivePanel:isValidHiveFrame(draggedItem) and not self.frameItem then
                self.isDropTarget = true
                self.isInvalidDropTarget = false
            else
                self.isDropTarget = false
                self.isInvalidDropTarget = not self.frameItem
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

function Hold_HiveFrameSlot:onMouseMoveOutside(dx, dy)
    self.isDropTarget = false
    self.isInvalidDropTarget = false
    return true
end

function Hold_HiveFrameSlot:onMouseUp(x, y)
    if ISMouseDrag.dragging and self.isDropTarget then
        local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if draggedItems and #draggedItems > 0 then
            local draggedItem = draggedItems[1]
            if self.hivePanel:isValidHiveFrame(draggedItem) and not self.frameItem then
                local action = Hold_AddHiveFrameAction:new(self.player, self.hivePanel.entity, draggedItem,self.slotIndex, self.resource)
                action.frameSlot = self
                ISTimedActionQueue.add(action)

                ISMouseDrag.dragging = nil
                ISMouseDrag.dragView = nil
            end
        end
    end
    
    self.isDropTarget = false
    self.isInvalidDropTarget = false
    return true
end

function Hold_HiveFrameSlot:onMouseDown(x, y)
    if self.frameItem and x <= self.height and not (self.actionAdd or self.actionRemove) then
        if  not self.resource:isEmpty() then
            local item = self.resource:peekItem()
            local action = Hold_RemoveHiveFrameAction:new(self.player, self.hivePanel.entity, self.resource, self.slotIndex, item)
            action.frameSlot = self
            ISTimedActionQueue.add(action)
            return true
        end
    end

    if not self.frameItem and not ISMouseDrag.dragging and not (self.actionAdd or self.actionRemove) then
        self:createContextMenu(x, y)
        return true
    end
    
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update and Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveFrameSlot:update()
    ISPanel.update(self)
end

function Hold_HiveFrameSlot:getFrameIcon(item)
    if not item then return self.emptySlotIcon end
    
    if HoldBeehiveCompat.isFullHiveFrame(item) then
        return self.frameIcon.full
    elseif HoldBeehiveCompat.isWaxHiveFrame(item) then
        return self.frameIcon.wax
    elseif HoldBeehiveCompat.isEmptyHiveFrame(item) then
        return self.frameIcon.empty
    end
end

function Hold_HiveFrameSlot:prerender()
    local iconAreaSize = self.height
    
    -- Background
    local r, g, b = 0.15, 0.15, 0.15
    if self:isMouseOver() then
        r, g, b = 0.2, 0.2, 0.2
    end
    
    local slotBG_IconSide = NinePatchTexture.getSharedTexture("media/ui/ShelterHold/Slot/SlotBG_IconSide.png")
    local slotBG_Right = NinePatchTexture.getSharedTexture("media/ui/ShelterHold/Slot/SlotBG_Right.png")
    local slotBG_Full = NinePatchTexture.getSharedTexture("media/ui/ShelterHold/Slot/SlotBG_Full.png")
    if slotBG_IconSide and slotBG_Right and slotBG_Full then
        if not self.frameItem then
            slotBG_Full:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, r, g, b, 0.8)
        else
            slotBG_IconSide:render(self:getAbsoluteX(), self:getAbsoluteY(), iconAreaSize, self.height, r, g, b, 0.8)
            slotBG_Right:render(self:getAbsoluteX() + iconAreaSize, self:getAbsoluteY(), self.width - iconAreaSize, self.height, r, g, b, 0.8)
        end
    end

    if self.isDropTarget then
        r, g, b = 0.2, 1, 0.2
    elseif self.isInvalidDropTarget then
        r, g, b = 1, 0.2, 0.2
    else
        r, g, b = 0.2, 0.2, 0.2
    end

    --JobDelta
    if self.actionAdd then
        local delta = self.actionAdd:getJobDelta()
        self:setStencilRect(0, 0, delta * self.width, self.height)
        slotBG_Full:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.2, 0.8, 0.2, 0.5)
        self:clearStencilRect()
    elseif self.actionRemove then
        local delta = 1 - self.actionRemove:getJobDelta()
        self:setStencilRect(0, 0, delta * self.width, self.height)
        slotBG_Full:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.8, 0.2, 0.2, 0.5)
        self:clearStencilRect()
    end
    
    local slotBoarder = NinePatchTexture.getSharedTexture("media/ui/ShelterHold/Slot/SlotBoarder.png")
    if slotBoarder then
        slotBoarder:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, r, g, b, 1)
    end

    -- ItemIcon
    local icon = self:getFrameIcon(self.frameItem)
    local iconSize = math.floor(self.height * 0.8 / 2) * 2
    if self.frameItem then
        local iconXY = (self.height - iconSize) / 2
        self:drawTextureScaled(icon, iconXY, iconXY, iconSize, iconSize, 1, 1, 1, 1)
    else
        local iconX = (self.width - iconSize) / 2
        local iconY = (self.height - iconSize) / 2
        self:drawTextureScaled(icon, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
    end

    -- PickIcon
    if self.frameItem and self:isMouseOver() and self:getMouseX() <= self.height and not (self.actionAdd or self.actionRemove) then
        local iconSize = self.height * 0.6
        local iconXY = (self.height - iconSize) / 2
        self:drawTextureScaled(self.buttonBg, iconXY, iconXY, iconSize, iconSize, 0.9, 0.1, 0.1, 0.1)
        self:drawTextureScaled(self.pickIcon, iconXY, iconXY, iconSize, iconSize, 0.8, 0.8, 0.8, 0.8)
    end

    -- Progress
    if self.frameItem then
        local currentUses = self.frameItem:getCurrentUsesFloat()
        local progressHeight = math.floor((self.height - self.padding) / 2) * 2
        local progressWidth = progressHeight * 2

        local progressX = self.height + ((self.width - self.height) - progressWidth) / 2
        local progressY = (self.height - progressHeight) / 2
        self.javaObject:DrawTexturePercentage(self.progressBar.fill, currentUses, progressX, progressY, progressWidth, progressHeight, 1, 1, 1, 1.0)
        self:drawTextureScaled(self.progressBar.border, progressX, progressY, progressWidth, progressHeight, 1, 1, 1, 1)

        if currentUses >= 0.25 then
            self:drawTextureScaled(self.progressBar.waxCheck, progressX, progressY, progressWidth, progressHeight, 1, 1, 1, 1)
        end

        if currentUses >= 0.5 then
            self:drawTextureScaled(self.progressBar.honeyCheck, progressX, progressY, progressWidth, progressHeight, 1, 1, 1, 1)
        end

        local percentText = math.floor(currentUses * 100) .. "%"
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, percentText)
        local textX = self.height + progressY + progressWidth - textWidth
        local textY = progressY + progressHeight - FONT_HGT_SMALL
        self:drawText(percentText, textX, textY, 1, 1, 1, 1, UIFont.Small)
    end
end

function Hold_HiveFrameSlot:render()
    ISPanel.render(self)
end

return Hold_HiveFrameSlot