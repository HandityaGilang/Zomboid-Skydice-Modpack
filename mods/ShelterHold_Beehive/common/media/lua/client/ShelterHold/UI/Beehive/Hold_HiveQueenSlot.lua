require "ISUI/ISUIElement"
require "ShelterHold/Hold_BeehiveCompat"

Hold_HiveQueenSlot = ISUIElement:derive("Hold_HiveQueenSlot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveQueenSlot:initialise()
    ISUIElement.initialise(self)
end

function Hold_HiveQueenSlot:new(x, y, width, height, parentPanel)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.parentPanel = parentPanel
    o.hivePanel = parentPanel.hivePanel
    o.player = parentPanel.player
    o.resource = nil
    
    o.padding = parentPanel.padding
    o.isDropTarget = false
    o.isInvalidDropTarget = false

    o.slotBG = getTexture("media/ui/ShelterHold/Slot/Hexagon_Background.png")
    o.slotBorder = getTexture("media/ui/ShelterHold/Slot/Hexagon_Border.png")
    o.emptySlotIcon = getTexture("media/ui/ShelterHold/Icon/Icon_QueenBeeSearch.png")
    o.addIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Plus.png")
    o.queenIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Zombee.png")
    o.pickIcon = getTexture("media/ui/ShelterHold/Icon/Icon_Pick.png")
    o.buttonBg = getTexture("media/ui/ShelterHold/Button/Small_Circle_Bg.png")

    o.beeIcon = {
        zombee = getTexture("media/ui/ShelterHold/Icon/Icon_Zombee.png"),
        honeybee = getTexture("media/ui/ShelterHold/Icon/Icon_HoneyBee.png"),
        bumblebee = getTexture("media/ui/ShelterHold/Icon/Icon_Bumblebee.png"),
    }
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Helper Functions
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveQueenSlot:onAddQueen(item)
    if not item then return end

    ISInventoryPaneContextMenu.transferIfNeeded(self.player, item)
    local action = Hold_AddQueenAction:new(self.player, self.hivePanel.entity, item, self.resource)
    action.queenSlot = self
    ISTimedActionQueue.add(action)
end

function Hold_HiveQueenSlot:SearchForQueenbee()
    local queenBees = {}
    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    local allItems = ArrayList.new()
    CraftRecipeManager.getAllItemsFromContainers(containers, allItems)

    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if HoldBeehiveCompat.isQueenBee(item) then
            table.insert(queenBees, item)
        end
    end
    
    return queenBees
end

function Hold_HiveQueenSlot:createContextMenu(x, y)
    local context = ISContextMenu.get(self.player:getPlayerNum(), x + self:getAbsoluteX() + 5, y + self:getAbsoluteY() + 5)
    context:setAlwaysOnTop(true)
    
    local queenBees = self:SearchForQueenbee()
    
    if #queenBees == 0 then
        local option = context:addOption(getText("IGUI_Hold_Beehive_NoQueenBeesFound"), self, nil)
        option.notAvailable = true
    else
        for _, item in ipairs(queenBees) do
            local itemName = item:getDisplayName()
            local option = context:addOption(itemName, self, self.onAddQueen, item)
            
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
function Hold_HiveQueenSlot:onMouseMove(dx, dy)
    if not ISMouseDrag.dragging then
        self.isDropTarget = false
        self.isInvalidDropTarget = false
        return true
    end

    local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
    local draggedItem = draggedItems[1]
    if not self.hivePanel:isValidQueenBee(draggedItem) then
        self.isDropTarget = false
        self.isInvalidDropTarget = true
        return true
    end

    -- Check if resources exist for the queen bee
    local bee = self.parentPanel.queenBee
    if bee then
        self.isDropTarget = false
        self.isInvalidDropTarget = true
    else
        self.isDropTarget = true
        self.isInvalidDropTarget = false
    end

    return true
end

function Hold_HiveQueenSlot:onMouseMoveOutside(dx, dy)
    self.isDropTarget = false
    self.isInvalidDropTarget = false
    return true
end

function Hold_HiveQueenSlot:onMouseUp(x, y)
    if ISMouseDrag.dragging and self.isDropTarget then
        local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if draggedItems and #draggedItems > 0 then
            local draggedItem = draggedItems[1]
            if self.hivePanel:isValidQueenBee(draggedItem) then
                self:onAddQueen(draggedItem)
                
                ISMouseDrag.dragging = nil
                ISMouseDrag.dragView = nil
            end
        end
    end
end

function Hold_HiveQueenSlot:onMouseDown(x, y)
    if not self.resource:isEmpty() and not (self.actionAdd or self.actionRemove) then
        local action = Hold_RemoveQueenAction:new(self.player, self.hivePanel.entity, self.resource, nil)
        action.queenSlot = self
        ISTimedActionQueue.add(action)
        return true
    end

    if self.resource:isEmpty() and not ISMouseDrag.dragging and not (self.actionAdd or self.actionRemove) then
        self:createContextMenu(x, y)
        return true
    end

    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveQueenSlot:update()
    ISUIElement.update(self)
end

function Hold_HiveQueenSlot:prerender()
    local bee = self.resource:peekItem()

    -- Background
    if self.actionAdd then
        local delta = self.actionAdd:getJobDelta()
        self.javaObject:DrawTexturePercentageBottomUp(self.slotBG, delta, 0, 0, self.width, self.height, 0.3, 0.2, 0.1, 0.8)
    elseif self.actionRemove then
        local delta = 1 - self.actionRemove:getJobDelta()
        self.javaObject:DrawTexturePercentageBottomUp(self.slotBG, delta, 0, 0, self.width, self.height, 0.3, 0.2, 0.1, 0.8)
    else
        local alpha = bee and 1 or 0.1
        self:drawTextureScaled(self.slotBG, 0, 0, self.width, self.height, alpha, 0.3, 0.2, 0.1)
    end
    
    -- Icon
    local iconSize = math.floor(self.width * 0.65 / 2) * 2
    local iconXY = (self.width - iconSize) / 2
    local icon = self.emptySlotIcon
    if bee then
        if bee:getType() == "Zombee" then
            icon = self.beeIcon.zombee
        elseif bee:getType() == "Bumblebee" then
            icon = self.beeIcon.bumblebee
        elseif bee:getType() == "Honeybee" then
            icon = self.beeIcon.honeybee
        end
    end
    self:drawTextureScaled(icon, iconXY, iconXY, iconSize, iconSize, 1, 1, 1, 1)

    --Add Icon
    local addIconSize = math.floor(self.width * 0.3 / 2) * 2
    local addIconXY = (self.width - addIconSize) / 2
    if not bee then
        local alpha = 0.7 + 0.3 * math.sin(getTimestampMs()/ 1000 * math.pi * 2)
        self:drawTextureScaled(getTexture("media/ui/ShelterHold/Icon/Icon_Plus.png"), addIconXY, addIconXY, addIconSize, addIconSize,alpha, 1, 1, 1)
    end
    
    -- Border
    if self.isDropTarget then
        self:drawTextureScaled(self.slotBorder, 0, 0, self.width, self.height, 1, 0.2, 0.8, 0.2)
    elseif self.isInvalidDropTarget then
        self:drawTextureScaled(self.slotBorder, 0, 0, self.width, self.height, 1, 0.8, 0.2, 0.2)
    else
        self:drawTextureScaled(self.slotBorder, 0, 0, self.width, self.height, 1, 0.15, 0.15, 0.15)
    end

    -- Pick
    if bee and self:isMouseOver() and not (self.actionAdd or self.actionRemove) then
        local buttonSize = math.floor(self.width / 2)
        local buttonXY = (self.width - buttonSize) / 2
        self:drawTextureScaled(self.buttonBg, buttonXY, buttonXY, buttonSize, buttonSize, 0.9, 0.1, 0.1, 0.1)
        self:drawTextureScaled(self.pickIcon, buttonXY, buttonXY, buttonSize, buttonSize, 0.8, 0.8, 0.8, 0.8)
    end
end

return Hold_HiveQueenSlot