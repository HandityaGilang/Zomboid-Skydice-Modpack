-- Auto-generated vanilla clone for CleanUI runtime UI mode switching.
-- Source build: 42.14.1




CleanUI_Vanilla_ISLootWindowContainerControls = ISPanelJoypad:derive("CleanUI_Vanilla_ISLootWindowContainerControls")

CleanUI_Vanilla_ISLootWindowContainerControls_HandlerList = CleanUI_Vanilla_ISLootWindowContainerControls_HandlerList or {}
CleanUI_Vanilla_ISLootWindowContainerControls_HandlerSet = CleanUI_Vanilla_ISLootWindowContainerControls_HandlerSet or {}

function CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(handlerClass)
    if CleanUI_Vanilla_ISLootWindowContainerControls_HandlerSet[handlerClass.Type] == handlerClass then return end
    CleanUI_Vanilla_ISLootWindowContainerControls_HandlerSet[handlerClass] = handlerClass
    local index = -1
    for index1,handlerClass1 in ipairs(CleanUI_Vanilla_ISLootWindowContainerControls_HandlerList) do
        if handlerClass.Type == handlerClass1.Type then
            index = index1
            break
        end
    end
    if index == -1 then
        table.insert(CleanUI_Vanilla_ISLootWindowContainerControls_HandlerList, handlerClass)
    else
        CleanUI_Vanilla_ISLootWindowContainerControls_HandlerList[index] = handlerClass
    end
end

-- These could go into the individual handler files, but the order would depend on file name.
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_TakeAll)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_TakeSameType)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_MoveToFloor)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_RemoveAll)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_MannequinSwitchOutfit)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_MannequinWearAll)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_PropaneBarbecueToggle)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_PropaneBarbecueAddTank)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_PropaneBarbecueRemoveTank)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_ClothingDryerToggle)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_ClothingWasherToggle)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_CombinationWasherDryerToggle)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_CombinationWasherDryerSetMode)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_StoveToggle)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_StoveSettings)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_VehicleCloseTrunk)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_VehicleLockTrunk)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_AddFuelOption)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_LightFireOption)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_PutOut)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_RemoveCampfire)
CleanUI_Vanilla_ISLootWindowContainerControls.AddHandler(ISLootWindowObjectControlHandler_AddCorpseToCampfire)

-- Use separate handlers for the floor container, because there is no IsoObject parent.
CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerList = CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerList or {}
CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerSet = CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerSet or {}

function CleanUI_Vanilla_ISLootWindowContainerControls.AddFloorHandler(handlerClass)
    if CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerSet[handlerClass.Type] == handlerClass then return end
    CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerSet[handlerClass] = handlerClass
    local index = -1
    for index1,handlerClass1 in ipairs(CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerList) do
        if handlerClass.Type == handlerClass1.Type then
            index = index1
            break
        end
    end
    if index == -1 then
        table.insert(CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerList, handlerClass)
    else
        CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerList[index] = handlerClass
    end
end

CleanUI_Vanilla_ISLootWindowContainerControls.AddFloorHandler(ISLootWindowFloorControlHandler_TakeAll)
CleanUI_Vanilla_ISLootWindowContainerControls.AddFloorHandler(ISLootWindowFloorControlHandler_TakeSameType)

function CleanUI_Vanilla_ISLootWindowContainerControls:createChildren()
end

function CleanUI_Vanilla_ISLootWindowContainerControls:checkHandler(handlerClass, object, container)
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

function CleanUI_Vanilla_ISLootWindowContainerControls:arrange()
    local container = self:getDisplayedContainer()
    local object = self:getDisplayedObject()
    for _,control in ipairs(self.controls) do
        control:setVisible(false)
        self:removeChild(control)
    end
    table.wipe(self.controls)
    if object then
        local x,y = 1,1
        local rowHgt = 0
        for _,handlerClass in ipairs(CleanUI_Vanilla_ISLootWindowContainerControls_HandlerList) do
            local handler = self:checkHandler(handlerClass, object, container)
            if handler:shouldBeVisible() then
                local control = handler:getControl()
                if (x > 0) and (x + control:getWidth() > self.width) then
                    x = 1
                    y = y + rowHgt + 1
                    rowHgt = 0
                end
                control:setX(x)
                control:setY(y)
                control:setVisible(true)
                self:addChild(control)
                table.insert(self.controls, control)
                x = control:getRight() + 10
                rowHgt = math.max(rowHgt, control:getHeight())
            end
        end
        self:setHeight(y + rowHgt + 1)
    else
        if container and container:getType() == "floor" then -- the only possibility is "floor"
            local x,y = 1,1
            local rowHgt = 0
            for _,handlerClass in ipairs(CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerList) do
                local handler = self:checkHandler(handlerClass, nil, container)
                if handler:shouldBeVisible() then
                    local control = handler:getControl()
                    if (x > 0) and (x + control:getWidth() > self.width) then
                        x = 1
                        y = y + rowHgt
                        rowHgt = 0
                    end
                    control:setX(x)
                    control:setY(y)
                    control:setVisible(true)
                    self:addChild(control)
                    table.insert(self.controls, control)
                    x = control:getRight() + 10
                    rowHgt = math.max(rowHgt, control:getHeight())
                end
            end
            self:setHeight(y + rowHgt + 1)
        end
    end
    if #self.controls > 0 then
        self:setX(0)
        self:setY(self.lootWindow.resizeWidget.y - self.height)
        self:setWidth(self.lootWindow:getWidth())
        self:setVisible(true)
        self:fixMouseOverButton()
    else
        self:setVisible(false)
        self:setHeight(0)
    end
end

function CleanUI_Vanilla_ISLootWindowContainerControls:getDisplayedContainer()
    local container = self.lootWindow.inventoryPane.inventory
    for _,cb in ipairs(self.lootWindow.backpacks) do
        if cb.inventory == container then
            return container
        end
    end
    return nil
end

function CleanUI_Vanilla_ISLootWindowContainerControls:getDisplayedObject()
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

function CleanUI_Vanilla_ISLootWindowContainerControls:handleJoypadContextMenu(context)
    local playerObj = getSpecificPlayer(self.lootWindow.player)
    local container = self:getDisplayedContainer()
    local object = self:getDisplayedObject()
    if object then
        for _,handlerClass in ipairs(CleanUI_Vanilla_ISLootWindowContainerControls_HandlerList) do
            local handler = self:checkHandler(handlerClass, object, container)
            if handler:shouldBeVisible() then
                handler:handleJoypadContextMenu(context)
            end
        end
    else
        if container and container:getType() == "floor" then -- the only possibility is "floor"
            for _,handlerClass in ipairs(CleanUI_Vanilla_ISLootWindowContainerControls_FloorHandlerList) do
                local handler = self:checkHandler(handlerClass, nil, container)
                if handler:shouldBeVisible() then
                handler:handleJoypadContextMenu(context)
                end
            end
        end
    end
end

function CleanUI_Vanilla_ISLootWindowContainerControls:fixMouseOverButton()
    for _,control in ipairs(self.controls) do
        if control:isMouseOver() then
            control:onMouseMove(0, 0)
        end
    end
end

function CleanUI_Vanilla_ISLootWindowContainerControls:new(lootWindow)
    local o = ISPanelJoypad.new(self, 0, 0, 200, 20)
    o:noBackground()
    o.lootWindow = lootWindow
    o.handlers = {}
    o.controls = {}
    return o
end
