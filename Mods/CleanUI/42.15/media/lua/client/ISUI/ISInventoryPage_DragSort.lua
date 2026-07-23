require "ISUI/ISInventoryPage"

local SORT_KEY = "ContainerSort_Priority"
local DragSort = {}

-- ----------------------------------------------------------------------------------------------------- --
-- Original Button Patch
-- ----------------------------------------------------------------------------------------------------- --
DragSort.onMouseDown = function(self, x, y)
    self.original_onMouseDown(self, x, y)

    self.dragStartMouseY = getMouseY()
    self.dragStartY = self:getY()

    local page = self:getParent():getParent()
    self.canDrag = page.onCharacter
end

DragSort.onMouseMove = function(self, dx, dy, skipOriginal)
    if not skipOriginal then
        self.original_onMouseMove(self, dx, dy)
    end
    
    if self.pressed and self.canDrag then
        local page = self:getParent():getParent()

        if math.abs(self.dragStartMouseY - getMouseY()) > page.buttonSize/6 then
            self.isDragging = true
        end
        
        if self.isDragging then
            local mouseY = getMouseY()
            local parentAbsY = self:getParent():getAbsoluteY()
            local newY = mouseY - parentAbsY - self:getHeight() / 2

            newY = math.max(0, newY)
            
            self:setY(newY)
            self:bringToTop()

            page:calculateInsertPosition(self)
        end
    end
end

DragSort.onMouseMoveOutside = function(self, dx, dy)
    self.original_onMouseMoveOutside(self, dx, dy)
    
    local page = self:getParent():getParent()

    if self.isDragging then
        DragSort.onMouseMove(self, dx, dy, true)
    end

    if self.isDragging and not isMouseButtonDown(0) then
        page.dragInsertPosition = nil
        page.draggingButton = nil
        DragSort.onMouseUp(self, 0, 0)
    end
end

DragSort.onMouseUp = function(self, x, y)
    local page = self:getParent():getParent()
    
    if self.isDragging then
        self.pressed = false
        self.isDragging = false

        page.dragInsertPosition = nil
        page.draggingButton = nil

        page:reorderContainerButtons(self)
        page:refreshBackpacks()
    else
        self.original_onMouseUp(self, x, y)
    end
end


ISInventoryPage.original_addContainerButton = ISInventoryPage.addContainerButton
function ISInventoryPage:addContainerButton(container, texture, name, tooltip)
    local button = self.original_addContainerButton(self, container, texture, name, tooltip)

    if self.onCharacter then
        if not button.original_onMouseDown then
            button.original_onMouseDown = button.onMouseDown
            button.original_onMouseMove = button.onMouseMove
            button.original_onMouseMoveOutside = button.onMouseMoveOutside
            button.original_onMouseUp = button.onMouseUp
        end

        button.onMouseDown = DragSort.onMouseDown
        button.onMouseMove = DragSort.onMouseMove
        button.onMouseMoveOutside = DragSort.onMouseMoveOutside
        button.onMouseUp = DragSort.onMouseUp
    end
    
    return button
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render Indicator
-- ----------------------------------------------------------------------------------------------------- --

function ISInventoryPage:calculateInsertPosition(draggedButton)
    if not self.onCharacter then return end
    
    self.draggingButton = draggedButton

    local buttons = {}
    for _, button in ipairs(self.backpacks) do
        if button:getIsVisible() and button ~= draggedButton then
            table.insert(buttons, button)
        end
    end
    
    if #buttons == 0 then
        self.dragInsertPosition = 0
        return
    end

    table.sort(buttons, function(a, b) return a:getY() < b:getY() end)
    
    local draggedY = draggedButton:getY() + draggedButton:getHeight() / 2

    for i, button in ipairs(buttons) do
        local buttonCenterY = button:getY() + button:getHeight() / 2
        
        if draggedY < buttonCenterY then
            self.dragInsertPosition = i - 1
            return
        end
    end

    self.dragInsertPosition = #buttons
end

ISInventoryPageContainerButtonPanel.original_render = ISInventoryPageContainerButtonPanel.render
function ISInventoryPageContainerButtonPanel:render()
    self.original_render(self)
    
    local page = self.inventorypage
    if page.draggingButton and page.dragInsertPosition ~= nil then
        local insertY
        
        if page.dragInsertPosition == 0 then
            insertY = page.padding / 2
        else
            local visibleButtons = {}
            for _, button in ipairs(page.backpacks) do
                if button:getIsVisible() and button ~= page.draggingButton then
                    table.insert(visibleButtons, button)
                end
            end
            
            table.sort(visibleButtons, function(a, b) return a:getY() < b:getY() end)
            
            if visibleButtons[page.dragInsertPosition] then
                local targetButton = visibleButtons[page.dragInsertPosition]
                insertY = targetButton:getY() + targetButton:getHeight() + page.padding / 2
            else
                insertY = page.padding / 2
            end
        end

        self:drawTextureScaled(getTexture("media/ui/CleanUI/Panel/ReorderIndicator.png"), 0, insertY, self.width, self.width, 1, 0.8, 0.8, 0.8)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- onMouseWheel
-- ----------------------------------------------------------------------------------------------------- --

ISInventoryPage.original_onMouseWheel = ISInventoryPage.onMouseWheel
function ISInventoryPage:onMouseWheel(del)
    local originalOrder = {}
    local hasOrder = false
    
    if self.onCharacter then
        for index, button in ipairs(self.backpacks) do
            originalOrder[button] = index
            hasOrder = true
        end

        table.sort(self.backpacks, function(a, b) return a:getY() < b:getY() end)
    end

    local result = self.original_onMouseWheel(self, del)

    if hasOrder then
        table.sort(self.backpacks, function(a, b) 
            return originalOrder[a] < originalOrder[b] 
        end)
    end
    
    return result
end

-- ----------------------------------------------------------------------------------------------------- --
-- Priority Manager
-- ----------------------------------------------------------------------------------------------------- --

function ISInventoryPage:getContainerSortPriority(container)
    local playerObj = getSpecificPlayer(self.player)
    local modData = playerObj:getModData()

    local sortKey = SORT_KEY
    if container == playerObj:getInventory() then
        sortKey = SORT_KEY .. "_MainInventory"
    else
        local item = container:getContainingItem()
        if item then
            sortKey = SORT_KEY .. "_" .. item:getID()
        end
    end

    if modData[sortKey] then
        return modData[sortKey]
    end

    for i, button in ipairs(self.backpacks) do
        if button.inventory == container then
            return 1000 + i
        end
    end
    
    return 1000
end

function ISInventoryPage:setContainerSortPriority(container, priority)
    local playerObj = getSpecificPlayer(self.player)
    local modData = playerObj:getModData()
    
    local sortKey = SORT_KEY
    if container == playerObj:getInventory() then
        sortKey = SORT_KEY .. "_MainInventory"
    else
        local item = container:getContainingItem()
        if item then
            sortKey = SORT_KEY .. "_" .. item:getID()
        end
    end
    
    modData[sortKey] = priority
end

-- ----------------------------------------------------------------------------------------------------- --
-- Reorder Handle
-- ----------------------------------------------------------------------------------------------------- --

function ISInventoryPage:reorderContainerButtons(draggedButton)
    if draggedButton and math.abs(draggedButton:getY() - draggedButton.dragStartY) <= 16 then
        draggedButton:setY(draggedButton.dragStartY)
        return
    end

    local buttonsWithY = {}
    for _, button in ipairs(self.backpacks) do
        if button:getIsVisible() then
            table.insert(buttonsWithY, {
                button = button,
                inventory = button.inventory,
                y = button:getY()
            })
        end
    end

    table.sort(buttonsWithY, function(a, b) return a.y < b.y end)

    for index, data in ipairs(buttonsWithY) do
        local priority = index * 10
        self:setContainerSortPriority(data.inventory, priority)
    end
end


function ISInventoryPage:applyContainerSort()
    if not self.onCharacter then return end

    local buttonsWithSort = {}
    for _, button in ipairs(self.backpacks) do
        if button:getIsVisible() then
            local priority = self:getContainerSortPriority(button.inventory)
            table.insert(buttonsWithSort, {
                button = button,
                priority = priority
            })
        end
    end

    table.sort(buttonsWithSort, function(a, b) return a.priority < b.priority end)

    for index, data in ipairs(buttonsWithSort) do
        local y = (index - 1) * (self.buttonSize + self.padding) + self.padding
        data.button:setY(y)
    end
end


ISInventoryPage.original_refreshBackpacks = ISInventoryPage.refreshBackpacks
function ISInventoryPage:refreshBackpacks()
    self.original_refreshBackpacks(self)

    if self.onCharacter then
        self:applyContainerSort()
    end
end