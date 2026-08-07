--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "ISUI/ISPanelJoypad"

require "ISUI/LootWindow/Handlers/AddCorpseToCampfire"
require "ISUI/LootWindow/Handlers/AddFuelOption"
require "ISUI/LootWindow/Handlers/ClothingDryerToggle"
require "ISUI/LootWindow/Handlers/ClothingWasherToggle"
require "ISUI/LootWindow/Handlers/CombinationWasherDryerSetMode"
require "ISUI/LootWindow/Handlers/CombinationWasherDryerToggle"
require "ISUI/LootWindow/Handlers/LightFuelOption"
require "ISUI/LootWindow/Handlers/MannequinSwitchOutfit"
require "ISUI/LootWindow/Handlers/MannequinWearAll"
require "ISUI/LootWindow/Handlers/MoveToFloor"
require "ISUI/LootWindow/Handlers/PropaneBarbecueAddTank"
require "ISUI/LootWindow/Handlers/PropaneBarbecueRemoveTank"
require "ISUI/LootWindow/Handlers/PropaneBarbecueToggle"
require "ISUI/LootWindow/Handlers/PutOut"
require "ISUI/LootWindow/Handlers/RemoveAll"
require "ISUI/LootWindow/Handlers/RemoveCampfire"
require "ISUI/LootWindow/Handlers/StoveSettings"
require "ISUI/LootWindow/Handlers/StoveToggle"
require "ISUI/LootWindow/Handlers/TakeAll"
require "ISUI/LootWindow/Handlers/TakeSameType"
require "ISUI/LootWindow/Handlers/VehicleCloseTrunk"
require "ISUI/LootWindow/Handlers/VehicleLockTrunk"
require "ISUI/CommonHandler/InventorySearch"
require "ISUI/CommonHandler/SortMenu"
require "ISUI/CommonHandler/CollapseAndExpand"
require "ISUI/LootWindow/Handlers/GrabCorpse"

require "ISUI/LootWindow/Handlers/FloorTakeAll"
require "ISUI/LootWindow/Handlers/FloorTakeSameType"

ISLootWindowContainerControls = ISPanelJoypad:derive("ISLootWindowContainerControls")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_ROW_PADDING = FONT_HGT_SMALL * 0.2

ISLootWindowContainerControls_HandlerList = ISLootWindowContainerControls_HandlerList or {}
ISLootWindowContainerControls_HandlerSet = ISLootWindowContainerControls_HandlerSet or {}
local UI_MARGIN = 5;

local function CleanUI_isFloorLikeLootContainer(container)
    -- Treat virtual aggregate containers like floor containers so common loot controls stay visible.
    if not container then return false end
    local containerType = container:getType()
    return containerType == "floor"
        or containerType == "proxInv" -- Proximity Inventory
        or containerType == "proximityInv" -- Better Containers proximity inventory
        or containerType == "twistInv_corpses" -- Better Containers corpse proximity inventory
        or containerType == "csrLootBag" -- Common Sense Reborn Nearby Loot virtual container
end

function ISLootWindowContainerControls.AddHandler(handlerClass, displayToRight)
    if ISLootWindowContainerControls_HandlerSet[handlerClass.Type] == handlerClass then return end
    ISLootWindowContainerControls_HandlerSet[handlerClass] = handlerClass
    handlerClass.displayToRight = displayToRight;
    local index = -1
    for index1,handlerClass1 in ipairs(ISLootWindowContainerControls_HandlerList) do
        if handlerClass.Type == handlerClass1.Type then
            index = index1
            break
        end
    end
    if index == -1 then
        table.insert(ISLootWindowContainerControls_HandlerList, handlerClass)
    else
        ISLootWindowContainerControls_HandlerList[index] = handlerClass
    end
end

-- These could go into the individual handler files, but the order would depend on file name.
-- ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_TakeAll)
-- ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_TakeSameType)
-- ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_MoveToFloor)


-----

-- Use separate handlers for the floor container, because there is no IsoObject parent.
ISLootWindowContainerControls_FloorHandlerList = ISLootWindowContainerControls_FloorHandlerList or {}
ISLootWindowContainerControls_FloorHandlerSet = ISLootWindowContainerControls_FloorHandlerSet or {}

function ISLootWindowContainerControls.AddFloorHandler(handlerClass)
    if ISLootWindowContainerControls_FloorHandlerSet[handlerClass.Type] == handlerClass then return end
    ISLootWindowContainerControls_FloorHandlerSet[handlerClass] = handlerClass
    local index = -1
    for index1,handlerClass1 in ipairs(ISLootWindowContainerControls_FloorHandlerList) do
        if handlerClass.Type == handlerClass1.Type then
            index = index1
            break
        end
    end
    if index == -1 then
        table.insert(ISLootWindowContainerControls_FloorHandlerList, handlerClass)
    else
        ISLootWindowContainerControls_FloorHandlerList[index] = handlerClass
    end
end

-- ISLootWindowContainerControls.AddFloorHandler(ISLootWindowFloorControlHandler_TakeAll)
-- ISLootWindowContainerControls.AddFloorHandler(ISLootWindowFloorControlHandler_TakeSameType)

function ISLootWindowContainerControls.AddCommonHandler(handlerClass)
    if ISInventoryWindowContainerControls then
        ISInventoryWindowContainerControls.AddHandler(handlerClass)
    end
    ISLootWindowContainerControls.AddHandler(handlerClass)
    ISLootWindowContainerControls.AddFloorHandler(handlerClass)
end

ISLootWindowContainerControls.AddCommonHandler(ISInventoryCommonHandler_InventorySearch)
ISLootWindowContainerControls.AddCommonHandler(ISInventoryCommonHandler_SortMenu)
ISLootWindowContainerControls.AddCommonHandler(ISInventoryCommonHandler_CollapseExpand)

ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_RemoveAll)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_MannequinWearAll, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_MannequinSwitchOutfit, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_PropaneBarbecueRemoveTank, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_PropaneBarbecueAddTank, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_PropaneBarbecueToggle, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_ClothingWasherToggle, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_ClothingDryerToggle, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_CombinationWasherDryerSetMode, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_CombinationWasherDryerToggle, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_StoveSettings, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_StoveToggle, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_VehicleLockTrunk, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_VehicleCloseTrunk, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_PutOut, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_LightFireOption, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_AddFuelOption, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_RemoveCampfire, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_AddCorpseToCampfire, true)
ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_GrabCorpse, true)

-----

function ISLootWindowContainerControls:createChildren()

end

function ISLootWindowContainerControls:checkHandler(handlerClass, object, container)
    local handler = self.handlers[handlerClass]
    if handler == nil then
        handler = handlerClass:new()
        self.handlers[handlerClass] = handler
    end
    handler.lootWindow = self.lootWindow
    handler.playerNum = self.lootWindow.player
    handler.playerObj = getSpecificPlayer(handler.playerNum)
    handler.object = object
    handler.container = container
    return handler
end

function ISLootWindowContainerControls:arrange()
    local playerObj = getSpecificPlayer(self.lootWindow.player)
    local container = self:getDisplayedContainer()
    local object = self:getDisplayedObject()
    for _,control in ipairs(self.controls) do
        control:setVisible(false)
        self:removeChild(control)
    end
    table.wipe(self.controls)
    if object then
        local x,y = BUTTON_ROW_PADDING, BUTTON_ROW_PADDING
        local xRight = -1
        local rowHgt = 0
        for _,handlerClass in ipairs(ISLootWindowContainerControls_HandlerList) do
            local handler = self:checkHandler(handlerClass, object, container)
            if handler:shouldBeVisible() then
                local control = handler:getControl()

                if not handlerClass.displayToRight and (x > 0) and (x + control:getWidth() > self.width) then
                    x = BUTTON_ROW_PADDING
                    y = y + rowHgt + BUTTON_ROW_PADDING
                    rowHgt = 0
                end
                if handlerClass.displayToRight then
                    if xRight == -1 then
                        xRight = self.lootWindow.inventoryPane.width - control:getWidth() - 1
                        control:setX(xRight)
                    else
                        control:setX(xRight - control:getWidth() - UI_MARGIN)
                        xRight = control:getX()
                    end
                else
                    control:setX(x)
                    x = control:getRight() + UI_MARGIN
                end
                control:setY(y)
                control:setVisible(true)
                self:addChild(control)
                table.insert(self.controls, control)
                rowHgt = math.max(rowHgt, control:getHeight())
            end
        end
        self:setHeight(y + rowHgt + BUTTON_ROW_PADDING)
    else
        if CleanUI_isFloorLikeLootContainer(container) then
            local x,y = BUTTON_ROW_PADDING, BUTTON_ROW_PADDING
            local rowHgt = 0
            for _,handlerClass in ipairs(ISLootWindowContainerControls_FloorHandlerList) do
                local handler = self:checkHandler(handlerClass, nil, container)
                if handler:shouldBeVisible() then
                    local control = handler:getControl()
                    if (x > 0) and (x + control:getWidth() > self.width) then
                        x = BUTTON_ROW_PADDING
                        y = y + rowHgt + BUTTON_ROW_PADDING
                        rowHgt = 0
                    end
                    control:setX(x)
                    control:setY(y)
                    control:setVisible(true)
                    self:addChild(control)
                    table.insert(self.controls, control)
                    x = control:getRight() + UI_MARGIN
                    rowHgt = math.max(rowHgt, control:getHeight())
                end
            end
            self:setHeight(y + rowHgt + BUTTON_ROW_PADDING)
        end
    end
    if #self.controls > 0 then
        self:setWidth(self.lootWindow:getWidth() - self.lootWindow.containerButtonPanel.width)
        self:setVisible(true)
        self:fixMouseOverButton()
    else
        self:setVisible(false)
        self:setHeight(0)
    end
end

function ISLootWindowContainerControls:getDisplayedContainer()
    local container = self.lootWindow.inventoryPane.inventory
    for _,cb in ipairs(self.lootWindow.backpacks) do
        if cb.inventory == container then
            return container
        end
    end
    return nil
end

function ISLootWindowContainerControls:getDisplayedObject()
    local container = self:getDisplayedContainer()
    if container == nil then return nil end
    -- Handle bags in vehicle containers being displayed separately
    local outermost = container:getOutermostContainer()
    if outermost ~= nil and outermost:getVehiclePart() ~= nil then
        return outermost:getVehiclePart():getVehicle()
    end
    if container:getContainingItem() ~= nil then
        return container:getContainingItem():getWorldItem()
    end
    return container:getParent()
end

function ISLootWindowContainerControls:handleJoypadContextMenu(context)
    local playerObj = getSpecificPlayer(self.lootWindow.player)
    local container = self:getDisplayedContainer()
    local object = self:getDisplayedObject()
    if object then
        for _,handlerClass in ipairs(ISLootWindowContainerControls_HandlerList) do
            local handler = self:checkHandler(handlerClass, object, container)
            if handler:shouldBeVisible() then
                handler:handleJoypadContextMenu(context)
            end
        end
    else
        if CleanUI_isFloorLikeLootContainer(container) then
            for _,handlerClass in ipairs(ISLootWindowContainerControls_FloorHandlerList) do
                local handler = self:checkHandler(handlerClass, nil, container)
                if handler:shouldBeVisible() then
                handler:handleJoypadContextMenu(context)
                end
            end
        end
    end
end

function ISLootWindowContainerControls:fixMouseOverButton()
    for _,control in ipairs(self.controls) do
        if control:isMouseOver() then
            control:onMouseMove(0, 0)
        end
    end
end

function ISLootWindowContainerControls:new(x,y,lootWindow)
    local o = ISPanelJoypad.new(self, x, y, 200, 20)
    o:noBackground()
    o.lootWindow = lootWindow
    o.handlers = {}
    o.controls = {}
    return o
end