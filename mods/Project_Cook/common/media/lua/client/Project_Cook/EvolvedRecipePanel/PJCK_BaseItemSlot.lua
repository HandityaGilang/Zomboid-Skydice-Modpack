require "ISUI/ISUIElement"
require "ISUI/ISToolTip"
require "ISUI/ISToolTipInv"

PJCK_BaseItemSlot = ISUIElement:derive("PJCK_BaseItemSlot")

-- ---------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------- --

function PJCK_BaseItemSlot:initialise()
    ISUIElement.initialise(self)
end

function PJCK_BaseItemSlot:new(x, y, width, height, parentPanel)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.parentPanel = parentPanel
    o.isDropTarget = false
    o.isInvalidDropTarget = false
    o.EvoPanel = parentPanel.EvoPanel
    o.padding = parentPanel.padding
    
    o.slotTex = {
        bg = getTexture("media/ui/Project_Cook/Button/Circle_Background.png"),
        border = getTexture("media/ui/Project_Cook/Button/Circle_Border.png"),
    }
    
    o.addIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_Plus.png")
    o.tooltip = nil
    
    return o
end

function PJCK_BaseItemSlot:isValidBaseItem(item)
    if not item then return false end
    
    local containers = ISInventoryPaneContextMenu.getContainers(self.EvoPanel.player)
    local evorecipes = RecipeManager.getEvolvedRecipe(item, self.EvoPanel.player, containers, false)

    if not evorecipes or evorecipes:size() == 0 then
        return false
    end
    
    return true
end

-- ---------------------------------------------------------- --
-- Mouse Function
-- ---------------------------------------------------------- --
function PJCK_BaseItemSlot:onMouseMove(dx, dy)
    local contextMenu = getPlayerContextMenu(self.EvoPanel.player:getPlayerNum())
    if contextMenu and contextMenu:isAnyVisible() then
        self:hideTooltip()
        return true
    end

    if ISMouseDrag.dragging then
        local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if draggedItems and #draggedItems > 0 then
            local draggedItem = draggedItems[1]
            if self:isValidBaseItem(draggedItem) then
                self.isDropTarget = true
                self.isInvalidDropTarget = false
            else
                self.isDropTarget = false
                self.isInvalidDropTarget = true
            end
        else
            self.isDropTarget = false
            self.isInvalidDropTarget = false
        end
        self:hideTooltip()
    else
        self.isDropTarget = false
        self.isInvalidDropTarget = false
        self:showTooltip()
    end
    
    return true
end


function PJCK_BaseItemSlot:onMouseMoveOutside(dx, dy)
    self.isDropTarget = false
    self:hideTooltip()
    return true
end

function PJCK_BaseItemSlot:onMouseDown(x, y)
    self:hideTooltip()
    self:showBaseItemContextMenu(x, y)
    getSoundManager():playUISound("UIActivateButton")
    return true
end

function PJCK_BaseItemSlot:onRightMouseDown(x, y)
    local baseItem = self.EvoPanel:getBaseItem()
    if not baseItem then
        return false
    end

    self:hideTooltip()
    self:showBaseItemActionMenu()
    getSoundManager():playUISound("UIActivateButton")
    return true
end

function PJCK_BaseItemSlot:showBaseItemActionMenu()
    local baseItem = self.EvoPanel:getBaseItem()
    local player = self.parentPanel.player
    if not baseItem or not player then return end

    local x = self:getAbsoluteX() + self:getWidth()
    local y = self:getAbsoluteY()
    local items = { baseItem }
    local isInPlayerInventory = baseItem:getContainer() == player:getInventory()

    ISInventoryPaneContextMenu.createMenu(player:getPlayerNum(), isInPlayerInventory, items, x, y)
    local contextMenu = getPlayerContextMenu(player:getPlayerNum()) or ISContextMenu.get(player:getPlayerNum(), x, y)
    if contextMenu then
        contextMenu:setAlwaysOnTop(true)
    end
end

function PJCK_BaseItemSlot:showBaseItemContextMenu(x, y)
    local containerItems = self:getBaseItemsByContainer()
    
    local player = self.parentPanel.player

    local slotRightX = self:getAbsoluteX() + self:getWidth()
    local slotTopY = self:getAbsoluteY()
    
    local contextMenu = ISContextMenu.get(player:getPlayerNum(), slotRightX, slotTopY)
    contextMenu:setAlwaysOnTop(true)

    if #containerItems == 0 then
        local noItemOption = contextMenu:addOption(getText("IGUI_PJCK_NoItemsAvailable"))
        noItemOption.notAvailable = true
        return
    end

    for _, containerInfo in ipairs(containerItems) do
        local containerOption = contextMenu:addOption(containerInfo.displayName)

        if containerInfo.texture then
            containerOption.iconTexture = containerInfo.texture
        end

        local subMenu = ISContextMenu:getNew(contextMenu)
        contextMenu:addSubMenu(containerOption, subMenu)

        for _, baseItem in ipairs(containerInfo.items) do
            local itemOption = subMenu:addOption(baseItem:getName(), self.EvoPanel, self.EvoPanel.setBaseItem, baseItem)
            local texture = baseItem:getTex()
            if texture then
                itemOption.iconTexture = texture
            end
        end
    end
end

function PJCK_BaseItemSlot:getBaseItemsByContainer()
    local playerObj = self.parentPanel.player
    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
    local containerItems = {}

    if not playerObj or not containers then return containerItems end

    local allItems = ArrayList.new()
    CraftRecipeManager.getAllItemsFromContainers(containers, allItems)

    local containerItemsMap = {}
    
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item and self:isValidBaseItem(item) then
            local container = item:getContainer()

            if not containerItemsMap[container] then
                local displayName = ""
                local containerTexture = nil
                local containerType = container:getType()

                if container == playerObj:getInventory() then
                    displayName = getText("IGUI_InventoryTooltip")
                    containerTexture = getTexture("media/ui/Icon_InventoryBasic.png")
                else
                    if container:getVehiclePart() then
                        displayName = getText("IGUI_VehiclePart" .. containerType)
                    else
                        displayName = getTextOrNull("IGUI_ContainerTitle_" .. containerType) or containerType
                    end

                    local containingItem = container:getContainingItem()
                    if containingItem then
                        displayName = containingItem:getName()
                        containerTexture = containingItem:getTex()
                    else
                        if ContainerButtonIcons and ContainerButtonIcons[containerType] then
                            containerTexture = ContainerButtonIcons[containerType]
                        else
                            containerTexture = getTexture("media/ui/Container_Shelf.png")
                        end
                    end
                end
                
                containerItemsMap[container] = {
                    container = container,
                    displayName = displayName,
                    texture = containerTexture,
                    items = {}
                }
            end

            table.insert(containerItemsMap[container].items, item)
        end
    end

    for _, containerInfo in pairs(containerItemsMap) do
        if #containerInfo.items > 0 then
            table.insert(containerItems, containerInfo)
        end
    end
    
    return containerItems
end

function PJCK_BaseItemSlot:showTooltip()
    if self.tooltip then return end

    local baseItem = self.EvoPanel:getBaseItem()
    if not baseItem then
        self.tooltip = ISToolTip:new()
        self.tooltip:initialise()
        self.tooltip:setOwner(self)
        self.tooltip:setName(getTextOrNull("IGUI_PJCK_AddBaseItem") or "Add base item")
        self.tooltip:setVisible(true)
        self.tooltip:setAlwaysOnTop(true)
        self.tooltip:addToUIManager()
        return
    end

    self.tooltip = ISToolTipInv:new(baseItem)
    self.tooltip:initialise()
    self.tooltip:setOwner(self)
    self.tooltip:setCharacter(self.EvoPanel.player)
    self.tooltip:setItem(baseItem)
    self.tooltip.followMouse = true
    self.tooltip:setVisible(true)
    self.tooltip:addToUIManager()
end

function PJCK_BaseItemSlot:hideTooltip()
    if self.tooltip then
        self.tooltip:setVisible(false)
        self.tooltip:removeFromUIManager()
        self.tooltip = nil
    end
end

function PJCK_BaseItemSlot:onMouseUp(x, y)
    if ISMouseDrag.dragging and self.isDropTarget then
        local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if draggedItems and #draggedItems > 0 then
            local draggedItem = draggedItems[1]
            
            if self:isValidBaseItem(draggedItem) then
                self.EvoPanel:setBaseItem(draggedItem)
                ISMouseDrag.dragging = nil
                ISMouseDrag.dragView = nil
            end
        end
    end

    self.isDropTarget = false
    
    return true
end

-- ---------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------- --
function PJCK_BaseItemSlot:prerender()
    -- Slot Background
    local color = self:isMouseOver() and 0.3 or 0.2
    self:drawTextureScaled(self.slotTex.bg, 0, 0, self.width, self.height, 1, color, color, color)

    local baseitem = self.EvoPanel:getBaseItem()
    local iconSize = math.floor(math.max(self.width,self.height) * 0.6 / 8) * 8

    if baseitem then
        -- Progress
        self:renderDumping(baseitem)
        self:renderAddIngredient(baseitem)
        self:renderTransfer(baseitem)
        self:renderFluid(baseitem)

        -- ICON
        local iconX = (self.width - iconSize) / 2
        local iconY = (self.height - iconSize) / 2
        ISInventoryItem.renderItemIcon(self, baseitem, iconX, iconY,1,iconSize,iconSize)
    else
        local iconX = (self.width - iconSize/2) / 2
        local iconY = (self.height - iconSize/2) / 2
        local alpha = 0.6 + 0.4 * math.sin(getTimestampMs() * 0.004)

        self:drawTextureScaledAspect(self.addIconTexture, iconX, iconY, iconSize/2, iconSize/2, alpha, 0.8, 0.6, 0.2)
    end
    
    -- Border
    if self.isDropTarget then
        self:drawTextureScaled(self.slotTex.border, 0, 0, self.width, self.height, 1, 0.2, 0.8, 0.2)
    elseif self.isInvalidDropTarget then
        self:drawTextureScaled(self.slotTex.border, 0, 0, self.width, self.height, 1, 0.8, 0.2, 0.2)
    else
        self:drawTextureScaled(self.slotTex.border, 0, 0, self.width, self.height, 1, 0.1, 0.1, 0.1)
    end
end

function PJCK_BaseItemSlot:renderFluid(baseitem)
    if not baseitem or not baseitem:getFluidContainer() then 
        return 0, 0
    end
    
    local fluidContainer = baseitem:getFluidContainer()
    local totalCapacity = fluidContainer:getCapacity()
    local amount = fluidContainer:getAmount()
    local fillRatio = totalCapacity > 0 and amount / totalCapacity or 0
    
    if fillRatio > 0 then
        self.javaObject:DrawTexturePercentageBottomUp(self.slotTex.bg, fillRatio, 0, 0, self.width, self.height, 0.3, 0.7, 0.9, 0.3)
    end
    
    return amount, totalCapacity
end

function PJCK_BaseItemSlot:renderDumping(baseitem)
    if not baseitem or not baseitem:getJobType() then return end
    
    local jobType = baseitem:getJobType()
    if jobType ~= getText("IGUI_JobType_PourOut") then return end
    
    local progress = baseitem:getJobDelta()
    if progress > 0 then
        self.javaObject:DrawTexturePercentageBottomUp(self.slotTex.bg, 1 - progress, 0, 0, self.width, self.height, 0.95, 0.4, 0.2, 0.8)
    end
end

function PJCK_BaseItemSlot:renderAddIngredient(baseitem)
    if not baseitem or not baseitem:getJobType() then return end
    
    local jobType = baseitem:getJobType()
    local addingPrefix = getText("IGUI_JobType_AddingIngredient", "", ""):gsub(" .*", " ")
    
    if string.find(jobType, "^" .. addingPrefix) then
        local progress = baseitem:getJobDelta()
        if progress > 0 then
            self.javaObject:DrawTexturePercentageBottomUp(self.slotTex.bg, progress, 0, 0, self.width, self.height, 0.2, 0.8, 0.4, 0.8)
        end
    end
end

function PJCK_BaseItemSlot:renderTransfer(baseitem)
    if not baseitem or not baseitem:getJobType() then return end
    
    local jobType = baseitem:getJobType()
    local progress = baseitem:getJobDelta()
    
    if progress <= 0 then return end

    if string.find(jobType, getText("IGUI_PuttingInContainer"))
        or string.find(jobType, getText("IGUI_MovingToContainer"))
        or string.find(jobType, getText("IGUI_Packing"))
        or string.find(jobType, getText("IGUI_Unpacking")) then
        
        self.javaObject:DrawTexturePercentage(self.slotTex.bg, progress, 0, 0, self.width, self.height, 0.4, 0.4, 0.4, 0.8)

    elseif string.find(jobType, getText("IGUI_TakingFromContainer")) then
        
        self.javaObject:DrawTexturePercentage(self.slotTex.bg, 1-progress, 0, 0, self.width, self.height, 0.4, 0.4, 0.4, 0.8)
    end
end

return PJCK_BaseItemSlot