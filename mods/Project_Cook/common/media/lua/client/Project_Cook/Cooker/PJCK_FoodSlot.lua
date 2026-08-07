require "ISUI/ISUIElement"
require "ISUI/ISToolTipInv"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISInventoryTransferAction"

PJCK_FoodSlot = ISUIElement:derive("PJCK_FoodSlot")

local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function PJCK_toNumber(value, fallback)
    if type(value) == "number" then return value end
    local n = tonumber(value)
    if n ~= nil then return n end
    return fallback or 0
end

local function PJCK_getPlayerThirst(playerObj)
    if not playerObj or not playerObj.getStats then return 1 end

    local stats = playerObj:getStats()
    if not stats then return 1 end

    -- B42.13+ uses CharacterStat.THIRST. B42.12 still had getThirst().
    if CharacterStat and CharacterStat.THIRST and stats.get then
        local ok, value = pcall(function()
            return stats:get(CharacterStat.THIRST)
        end)
        if ok and value ~= nil then
            return PJCK_toNumber(value, 1)
        end
    end

    if stats.getThirst then
        local ok, value = pcall(function()
            return stats:getThirst()
        end)
        if ok and value ~= nil then
            return PJCK_toNumber(value, 1)
        end
    end

    return 1
end

local function PJCK_isDrinkableFluid(fluid)
    if not fluid then return false end

    if FluidCategory and FluidCategory.Beverage and fluid.isCategory then
        local ok, value = pcall(function()
            return fluid:isCategory(FluidCategory.Beverage)
        end)
        if ok and value then return true end
    end

    if FluidType and FluidType.Bleach and fluid.getFluidType then
        local ok, value = pcall(function()
            return fluid:getFluidType() == FluidType.Bleach
        end)
        if ok and value then return true end
    end

    if fluid.getFluidTypeString then
        local ok, value = pcall(function()
            return fluid:getFluidTypeString() == "Bleach"
        end)
        if ok and value then return true end
    end

    return false
end

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_FoodSlot:initialise()
    ISUIElement.initialise(self)
end

function PJCK_FoodSlot:new(x, y, size, item, count, parentPanel)
    local o = ISUIElement:new(x, y, size, size)
    setmetatable(o, self)
    self.__index = self
    
    o.size = size
    o.ButtonHeight = size / 2.6
    o.iconSize = FONT_HGT_MEDIUM
    o.parentPanel = parentPanel
    o.item = item
    o.count = count
    o.tooltipRender = nil
    o.height = size + o.ButtonHeight
    
    -- 加载贴图资源
    o.slotTextures = {
        background = getTexture("media/ui/Project_Cook/Slot/Itemslot_Background.png"),
        backgroundHover = getTexture("media/ui/Project_Cook/Slot/Itemslot_Hover.png"),
        border = getTexture("media/ui/Project_Cook/Slot/Itemslot_Boarder.png"),
    }
    
    -- 底部按钮背景贴图
    o.bottomBarTextures = {
        left = getTexture("media/ui/Project_Cook/Slot/Itemslot_Button_BG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Slot/Itemslot_Button_BG_M.png"),
        right = getTexture("media/ui/Project_Cook/Slot/Itemslot_Button_BG_R.png")
    }
    
    o.cookableIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_Cookable.png")
    o.burntIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_Burnt.png")
    o.frozenIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_Frozen.png")
    o.PlusIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Plus.png")
    o.MinusIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Minus.png")
    o.ReturnIcon = getTexture("media/ui/Project_Cook/ICON/Icon_CraftReturn.png")

    o.progressSegments = {}
    for i=1, 12 do
        o.progressSegments[i] = getTexture("media/ui/Project_Cook/Slot/Progress/segment_" .. i .. ".png")
    end
    o.Progress_BG = getTexture("media/ui/Project_Cook/Slot/Progress/background.png")

    o.DurabilityTexture = getTexture("media/ui/Project_Cook/Slot/Durability_FlatBottom.png")
    
    return o
end

function PJCK_FoodSlot:createChildren()
    -- Inventory/Food slots keep a single + button. Cooker Container slots use
    -- two buttons: - for the currently selected target, and return for origin.
    local isInventoryPanel = self:isInInventoryPanel()

    if isInventoryPanel then
        self.actionButton = ISButton:new(0, self.size, self.size, self.ButtonHeight, "", self, self.onAddButton)
        self.actionButton:initialise()
        self.actionButton:instantiate()
        self.actionButton.prerender = function(btn) self:renderButton(btn, self.PlusIcon) end
        self:addChild(self.actionButton)
        return
    end

    local halfWidth = math.floor(self.size / 2)
    local rightWidth = self.size - halfWidth

    self.removeButton = ISButton:new(0, self.size, halfWidth, self.ButtonHeight, "", self, self.onRemoveButton)
    self.removeButton:initialise()
    self.removeButton:instantiate()
    self.removeButton.prerender = function(btn) self:renderButton(btn, self.MinusIcon) end
    self:addChild(self.removeButton)

    self.returnButton = ISButton:new(halfWidth, self.size, rightWidth, self.ButtonHeight, "", self, self.onReturnButton)
    self.returnButton:initialise()
    self.returnButton:instantiate()
    self.returnButton.prerender = function(btn) self:renderButton(btn, self.ReturnIcon or self.MinusIcon) end
    self:addChild(self.returnButton)
end

-- ---------------------------------------------------------- --
-- 辅助方法
-- ---------------------------------------------------------- --

-- 判断是否在InventoryPanel中
function PJCK_FoodSlot:isInInventoryPanel()
    -- 检查父面板的类型名称
    if self.parentPanel then
        local panelType = getmetatable(self.parentPanel).__index
        if panelType and panelType.__name then
            return panelType.__name == "PJCK_InventoryPanel"
        end
        -- 备用检查方法：检查父面板是否有特定属性
        return self.parentPanel.containerButtons ~= nil
    end
    return false
end

-- ---------------------------------------------------------- --
-- 转移物品处理
-- ---------------------------------------------------------- --

-- 加号按钮，从container中将物品移动到cooker
function PJCK_FoodSlot:onAddButton()
    if not self.item then return end
    
    local player = self.parentPanel.CookerPanel.player
    local selectedCooker = self.parentPanel.CookerPanel.selectedCooker
    
    if not selectedCooker then return end
    
    -- 检查容量是否超标
    local currentWeight, maxCapacity = self.parentPanel.CookerPanel.cookerContainerPanel:getCookerCapacityInfo()
    local itemWeight = self.item:getUnequippedWeight()
    if currentWeight + itemWeight > maxCapacity then return end
    
    -- 检查物品是否在玩家能到达的容器中
    if not self:canTransferItem(self.item, selectedCooker) then return end

    -- Remember the item's current source container before moving it into the cooker.
    -- The global container view can later use this to send cooked/unfinished items back.
    if self.parentPanel.CookerPanel.rememberOriginalContainer then
        self.parentPanel.CookerPanel:rememberOriginalContainer(self.item, self.item:getContainer())
    end
    
    ISTimedActionQueue.add(ISInventoryTransferAction:new(player, self.item, self.item:getContainer(), selectedCooker))
end

function PJCK_FoodSlot:getSelectedRemoveTargetContainer()
    if not self.parentPanel or not self.parentPanel.CookerPanel then return nil end

    local cookerPanel = self.parentPanel.CookerPanel
    local inventoryPanel = cookerPanel.inventoryPanel

    -- The - button keeps the old behavior: send to the selected Food panel
    -- container, or to the main inventory when All Containers is selected.
    if inventoryPanel and not inventoryPanel:isAllContainersSelected() and inventoryPanel.selectedContainer then
        return inventoryPanel.selectedContainer
    end

    local player = cookerPanel.player
    return player and player:getInventory() or nil
end

function PJCK_FoodSlot:getReturnTargetContainer()
    if not self.parentPanel or not self.parentPanel.CookerPanel then return nil, false end

    local cookerPanel = self.parentPanel.CookerPanel
    local inventoryPanel = cookerPanel.inventoryPanel

    -- The return button uses the newer beta9 origin-aware behavior. The item ID
    -- fallback in CookerPanel keeps this stable across transfers/refreshed wrappers.
    local originalContainer = cookerPanel.getOriginalContainer and cookerPanel:getOriginalContainer(self.item) or nil
    if originalContainer then
        return originalContainer, true
    end

    if inventoryPanel and not inventoryPanel:isAllContainersSelected() and inventoryPanel.selectedContainer then
        return inventoryPanel.selectedContainer, false
    end

    local player = cookerPanel.player
    return player and player:getInventory() or nil, false
end

function PJCK_FoodSlot:usesFallbackReturnTarget()
    if self:isInInventoryPanel() then return false end
    if not self.parentPanel or not self.parentPanel.CookerPanel then return false end

    -- A yellow return button means the item has no saved source container.
    -- The return action will fall back either to the selected Food container
    -- or, when All Containers is selected, to the player's main inventory.
    local targetContainer, hasOriginalContainer = self:getReturnTargetContainer()
    return targetContainer ~= nil and hasOriginalContainer == false
end

function PJCK_FoodSlot:transferCurrentItemTo(targetContainer, clearOrigin)
    if not self.item then return end
    if not self.parentPanel or not self.parentPanel.CookerPanel then return end

    local player = self.parentPanel.CookerPanel.player
    if not player or not targetContainer then return end

    -- 检查目标容器是否有空间
    if not targetContainer:hasRoomFor(player, self.item) then return end

    -- 检查物品是否可以转移
    if not self:canTransferItem(self.item, targetContainer) then return end

    if clearOrigin and self.parentPanel.CookerPanel.clearOriginalContainer then
        self.parentPanel.CookerPanel:clearOriginalContainer(self.item)
    end

    ISTimedActionQueue.add(ISInventoryTransferAction:new(player, self.item, self.item:getContainer(), targetContainer))
end

-- 减号按钮，从cooker移动物品到选中的container
function PJCK_FoodSlot:onRemoveButton()
    self:transferCurrentItemTo(self:getSelectedRemoveTargetContainer(), true)
end

-- Return button: move from cooker back to the original source container when known.
function PJCK_FoodSlot:onReturnButton()
    local targetContainer = self:getReturnTargetContainer()
    self:transferCurrentItemTo(targetContainer, true)
end

function PJCK_FoodSlot:canTransferItem(item, destContainer)
    if not item or not destContainer then return false end
    
    local sourceContainer = item:getContainer()
    if not sourceContainer then return false end

    if sourceContainer == destContainer then return false end

    if not destContainer:isItemAllowed(item) then return false end
    
    return true
end

-- ---------------------------------------------------------- --
-- 物品状态信息获取
-- ---------------------------------------------------------- --

-- 获取物品状态信息
function PJCK_FoodSlot:getFoodSatietyInfo(item)
    if not item then return 0, 0.2, 0.8, 0.2, 0.7 end
    
    local ratio = 0
    
    if item:IsDrainable() then
        ratio = math.max(0, math.min(1, item:getCurrentUsesFloat()))
    elseif instanceof(item, "Food") then
        local actualWeight = item:getActualWeight()
        local maxWeight = item:getScriptItem():getActualWeight()
        ratio = maxWeight > 0 and actualWeight / maxWeight or 0
    else
        ratio = 1
    end
    return ratio
end

-- 获取转移进度
function PJCK_FoodSlot:isTransferring(item)
    if not item then return false, 0 end
    
    if item:getJobType() then
        local jobType = item:getJobType()
        local jobDelta = item:getJobDelta()

        if jobDelta > 0 and (string.find(jobType, getText("IGUI_PuttingInContainer"))
            or string.find(jobType, getText("IGUI_MovingToContainer"))
            or string.find(jobType, getText("IGUI_Packing"))
            or string.find(jobType, getText("IGUI_Unpacking"))
            or string.find(jobType, getText("IGUI_TakingFromContainer"))) then
            return true, jobDelta
        end
    end
    
    return false, 0
end

local function PJCK_clamp(value, minValue, maxValue)
    value = PJCK_toNumber(value, minValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

-- Returns a compact cooking-state value for slot badges.
-- The number is a percentage-like progress helper, not real-life seconds.
function PJCK_FoodSlot:getCookingDisplayInfo(item)
    if not item or not instanceof(item, "Food") then
        return nil
    end

    if item:isBurnt() then
        return { state = "burnt" }
    end

    if not item:isIsCookable() or item:isFrozen() or PJCK_toNumber(item:getHeat(), 0) <= 1.6 then
        return nil
    end

    local currentTime = PJCK_toNumber(item:getCookingTime(), 0)
    local cookTime = PJCK_toNumber(item:getMinutesToCook(), 0)
    local burnTime = PJCK_toNumber(item:getMinutesToBurn(), 0)

    if cookTime <= 0 then
        return nil
    end

    if currentTime < cookTime then
        local remainingPercent = ((cookTime - currentTime) / cookTime) * 100
        remainingPercent = PJCK_clamp(math.ceil(remainingPercent), 1, 100)
        return { state = "cooking", value = remainingPercent }
    end

    if burnTime > cookTime and currentTime < burnTime then
        local burnWindow = burnTime - cookTime
        local remainingPercent = ((burnTime - currentTime) / burnWindow) * 100
        remainingPercent = PJCK_clamp(math.ceil(remainingPercent), 1, 100)
        return { state = "burning", value = remainingPercent }
    end

    return { state = "burnt" }
end

-- 获取物品温度信息
function PJCK_FoodSlot:getItemTemperature(item)
    if not item then return 0, 0 end
    
    -- 根据物品类型获取温度
    local currentHeat = 1.0
    if instanceof(item, "Food") or instanceof(item, "DrainableComboItem") then
        currentHeat = item:getHeat() or 1.0
    else
        currentHeat = item:getItemHeat() or 1.0
    end
    
    -- 计算温度透明度和颜色
    local alpha = 0
    local isHot = currentHeat > 1.0
    local isCold = currentHeat < 1.0
    
    if isHot or isCold then
        alpha = math.abs(item:getInvHeat() or 0)
        alpha = math.min(0.8, alpha)
    end
    
    return currentHeat, alpha, isHot, isCold
end
-- ---------------------------------------------------------- --
-- Tooltip管理
-- ---------------------------------------------------------- --

function PJCK_FoodSlot:showTooltip()
    if not self.item then return end
    
    if not self.tooltipRender then
        self.tooltipRender = ISToolTipInv:new(self.item)
        self.tooltipRender:initialise()
        self.tooltipRender:setOwner(self)
        self.tooltipRender:setCharacter(getSpecificPlayer(0))
        self.tooltipRender.followMouse = true
    end
    self.tooltipRender:setVisible(true)
    self.tooltipRender:addToUIManager()
end

function PJCK_FoodSlot:hideTooltip()
    if self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
end

-- ---------------------------------------------------------- --
-- 右键菜单
-- ---------------------------------------------------------- --
function PJCK_FoodSlot:isItemInPlayerInventory(playerObj, item)
    if not playerObj or not item or not item.getContainer then return false end

    local container = item:getContainer()
    if not container then return false end

    if container.isInCharacterInventory then
        local ok, value = pcall(function()
            return container:isInCharacterInventory(playerObj)
        end)
        if ok then return value == true end
    end

    local playerInventory = playerObj:getInventory()
    return container == playerInventory
end

function PJCK_FoodSlot:getContextMenuItems()
    if not self.item then return {} end
    if not self.count or self.count <= 1 then return { self.item } end

    local containers = self:getContainersForStackState()
    local groupItems = {}
    local itemName = self.item:getName()

    for _, container in ipairs(containers) do
        local items = container and container.getItems and container:getItems() or nil
        if items then
            for i = 0, items:size() - 1 do
                local item = items:get(i)
                if item and item:getName() == itemName and self.parentPanel:isFoodItem(item) then
                    table.insert(groupItems, item)
                end
            end
        end
    end

    if #groupItems > 0 then
        return groupItems
    end

    return { self.item }
end

function PJCK_FoodSlot:areContextItemsInPlayerInventory(playerObj, items)
    if not items or #items == 0 then return false end

    for _, item in ipairs(items) do
        if not self:isItemInPlayerInventory(playerObj, item) then
            return false
        end
    end

    return true
end

function PJCK_FoodSlot:showItemGroupContextMenu()
    self:hideTooltip()
    if not self.item then return end
    if not self.parentPanel or not self.parentPanel.CookerPanel then return end

    local player = self.parentPanel.CookerPanel.player
    if not player then return end

    local playerNum = player:getPlayerNum()
    local playerObj = getSpecificPlayer(playerNum) or player
    local contextX = self:getAbsoluteX() + self.width
    local contextY = self:getAbsoluteY()

    -- Use the same vanilla context-menu builder as the inventory and loot panels.
    -- This keeps food, drink, transfer, crafting, mod-added options, and fluid menus
    -- consistent with the normal UI instead of maintaining a partial duplicate here.
    local contextItems = self:getContextMenuItems()
    local isInPlayerInventory = self:areContextItemsInPlayerInventory(playerObj, contextItems)
    local contextMenu = nil

    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.createMenu then
        contextMenu = ISInventoryPaneContextMenu.createMenu(playerNum, isInPlayerInventory, contextItems, contextX, contextY, self)
    else
        contextMenu = ISContextMenu.get(playerNum, contextX, contextY)
    end

    -- Keep Project Cook's stack-switch helper for grouped slots.
    if contextMenu and self.count and self.count > 1 then
        self:addSwitchItemOptions(contextMenu, playerNum)
    end
end

function PJCK_FoodSlot:getContainerForStackState()
    if not self.parentPanel then return nil end
    return self.parentPanel.selectedContainer or self.parentPanel.selectedCooker
end

function PJCK_FoodSlot:getContainersForStackState()
    if not self.parentPanel then return {} end

    if self.parentPanel.getAvailableSourceContainers and self.parentPanel:isAllContainersSelected() then
        return self.parentPanel:getAvailableSourceContainers()
    end

    local container = self:getContainerForStackState()
    return container and { container } or {}
end

function PJCK_FoodSlot:getFrozenStackState()
    if not self.item or not instanceof(self.item, "Food") then
        return false, false
    end

    local containers = self:getContainersForStackState()
    if not containers or #containers == 0 then
        return self.item:isFrozen(), self.item:isFrozen()
    end

    local total = 0
    local frozen = 0
    local itemName = self.item:getName()
    for _, container in ipairs(containers) do
        local items = container and container.getItems and container:getItems() or nil
        if items then
            for i = 0, items:size() - 1 do
                local item = items:get(i)
                if item and item:getName() == itemName and self.parentPanel:isFoodItem(item) and instanceof(item, "Food") then
                    total = total + 1
                    if item:isFrozen() then
                        frozen = frozen + 1
                    end
                end
            end
        end
    end

    if total == 0 then
        return self.item:isFrozen(), self.item:isFrozen()
    end

    return frozen > 0, frozen == total
end

-- 统一物品类型检测
function PJCK_FoodSlot:detectItemType(item)
    local itemType = {
        isFood = false,
        waterContainer = nil,
        fluidContainer = nil
    }
    
    -- 检查是否是食物
    if item:getCategory() == "Food" and not item:getScriptItem():isCantEat() then
        itemType.isFood = true
    end
    
    -- 检查是否是水/液体容器
    if item:isWaterSource() or (item:getFluidContainer() and item:getFluidContainer():getPrimaryFluid() and 
       (item:getFluidContainer():getPrimaryFluid():getFluidTypeString() == "Water" or 
        item:getFluidContainer():getPrimaryFluid():getFluidTypeString() == "CarbonatedWater")) then
        itemType.waterContainer = item
    elseif item:getFluidContainer() then
        itemType.fluidContainer = item
    end

    -- 检查世界物品
    local worldItem = item:getWorldItem()
    if worldItem then
        if worldItem:getFluidContainer() and worldItem:getFluidContainer():getPrimaryFluid() and 
           (worldItem:getFluidContainer():getPrimaryFluid():getFluidTypeString() == "Water" or 
            worldItem:getFluidContainer():getPrimaryFluid():getFluidTypeString() == "CarbonatedWater") then
            itemType.waterContainer = worldItem
        elseif worldItem:getFluidContainer() then
            itemType.fluidContainer = worldItem
        end
    end
    
    return itemType
end

-- 添加食物菜单选项
function PJCK_FoodSlot:addFoodMenuOptions(context, items, player, playerObj)
    local foodItems = ISInventoryPane.getActualItems(items)
    if not foodItems or not foodItems[1] then return end

    local hungerChange = PJCK_toNumber(foodItems[1]:getHungChange(), 0)

    if hungerChange < 0 then
        local cmd = foodItems[1]:getCustomMenuOption() or getText("ContextMenu_Eat")
        self:addPortionedFoodMenu(context, items, cmd, foodItems, player, playerObj)
    end
end

-- 添加分量食物菜单
function PJCK_FoodSlot:addPortionedFoodMenu(context, items, cmd, foodItems, player, playerObj)
    local eatOption = context:addOption(cmd, items, nil)
    eatOption.itemForTexture = foodItems[1]
    
    -- 检查是否吃太饱
    local foodEatenMoodle = MoodleType.FOOD_EATEN or MoodleType.FoodEaten
    if foodEatenMoodle and playerObj:getMoodles():getMoodleLevel(foodEatenMoodle) >= 3 then
        eatOption.notAvailable = true
        local tooltip = ISInventoryPaneContextMenu.addToolTip()
        tooltip.description = getText("Tooltip_CantEatMore")
        eatOption.toolTip = tooltip
        return
    end

    local subMenuEat = context:getNew(context)
    context:addSubMenu(eatOption, subMenuEat)
    
    -- 添加分量选项
    subMenuEat:addOption(getText("ContextMenu_Eat_All"), items, ISInventoryPaneContextMenu.onEatItems, 1, player)
    
    local baseHunger = math.abs(PJCK_toNumber(foodItems[1]:getBaseHunger(), 0) * 100) + 0.001
    local hungerChange = math.abs(PJCK_toNumber(foodItems[1]:getHungerChange(), 0) * 100) + 0.001
    
    if hungerChange >= 2 and hungerChange >= baseHunger/2 then
        subMenuEat:addOption(getText("ContextMenu_Eat_Half"), items, ISInventoryPaneContextMenu.onEatItems, 0.5, player)
    end
    if hungerChange >= 4 and hungerChange >= baseHunger/4 then
        subMenuEat:addOption(getText("ContextMenu_Eat_Quarter"), items, ISInventoryPaneContextMenu.onEatItems, 0.25, player)
    end
end

-- 添加饮料菜单选项
function PJCK_FoodSlot:addDrinkMenuOptions(context, itemType, playerNum, playerObj)
    if not context or not itemType or not playerObj then return end
    if not ISInventoryPaneContextMenu or not ISInventoryPaneContextMenu.doDrinkFluidMenu then return end

    -- Water container. Keep B42.12 and B42.13+ thirst APIs compatible.
    if itemType.waterContainer and PJCK_getPlayerThirst(playerObj) > 0.1 then
        ISInventoryPaneContextMenu.doDrinkFluidMenu(playerObj, itemType.waterContainer, context)
        return
    end

    -- Other fluid containers.
    local fluidContainerItem = itemType.fluidContainer
    if not fluidContainerItem or not fluidContainerItem.getFluidContainer then return end

    local fluidContainer = fluidContainerItem:getFluidContainer()
    if not fluidContainer or fluidContainer:isEmpty() then return end

    local fluid = fluidContainer:getPrimaryFluid()
    if PJCK_isDrinkableFluid(fluid) then
        ISInventoryPaneContextMenu.doDrinkFluidMenu(playerObj, fluidContainerItem, context)
    end
end

-- 添加切换物品选项
function PJCK_FoodSlot:addSwitchItemOptions(contextMenu, playerNum)
    local containers = self:getContainersForStackState()
    if not containers or #containers == 0 then return end
    
    -- 收集同名物品
    local sameNameItems = {}
    local itemName = self.item:getName()
    for _, selectedContainer in ipairs(containers) do
        local containerItems = selectedContainer and selectedContainer:getItems()
        if containerItems then
            for i = 0, containerItems:size() - 1 do
                local item = containerItems:get(i)
                if item:getName() == itemName and self.parentPanel:isFoodItem(item) then
                    table.insert(sameNameItems, item)
                end
            end
        end
    end

    local switchOption = contextMenu:addOption(getText("IGUI_PJCK_SwitchItem"), nil, nil)
    local subMenu = ISContextMenu:getNew(contextMenu)
    contextMenu:addSubMenu(switchOption, subMenu)
    
    -- 添加物品选项
    for _, item in ipairs(sameNameItems) do
        local ratio = self:getFoodSatietyInfo(item)
        local percentage = math.floor(ratio * 100)
        local displayText = item:getName()
        
        if instanceof(item, "Food") or item:IsDrainable() then
            displayText = displayText .. " (" .. percentage .. "%)"
        end
        
        local option = subMenu:addOption(displayText, self, self.onSelectItemFromGroup, item)
        if item:getTex() then
            option.iconTexture = item:getTex()
        end
    end
end

function PJCK_FoodSlot:onSelectItemFromGroup(selectedItem)
    self.item = selectedItem

    if self.parentPanel and self.parentPanel.updateFoodList then
        self.parentPanel:updateFoodList()
    end
end

-- ---------------------------------------------------------- --
-- 鼠标交互
-- ---------------------------------------------------------- --
function PJCK_FoodSlot:isMouseOverButtons()
    return self:getMouseY() >= self.size
end

function PJCK_FoodSlot:onMouseMove(dx, dy)
    local contextMenu = getPlayerContextMenu(self.parentPanel.CookerPanel.player:getPlayerNum())
    if contextMenu and contextMenu:isAnyVisible() then
        self:hideTooltip()
        return true
    end
    if not self:isMouseOverButtons() then
        self:showTooltip()
    else
        self:hideTooltip()
    end
    return true
end

function PJCK_FoodSlot:onMouseMoveOutside(dx, dy)
    self:hideTooltip()
    return true
end

function PJCK_FoodSlot:onMouseDown(x, y)
    return false
end

function PJCK_FoodSlot:onMouseUp(x, y)
    return false
end

function PJCK_FoodSlot:onRightMouseDown(x, y)
    if not self:isMouseOverButtons() then
        self:showItemGroupContextMenu()
        return true
    end
    return false
end

-- ---------------------------------------------------------- --
-- 优化方法 - 滚动视图可见性检测
-- ---------------------------------------------------------- --

function PJCK_FoodSlot:isInViewport()
    local scrollView = self.parentPanel.scrollView
    if not scrollView then return true end
    
    local viewWidth = scrollView:getWidth()
    local viewHeight = scrollView:getHeight()
    local slotX = self:getX()
    local slotY = self:getY()
    
    local buffer = self.size
    local viewLeft = -buffer
    local viewRight = viewWidth + buffer
    local viewTop = -buffer
    local viewBottom = viewHeight + buffer
    
    return slotX + self.size > viewLeft and slotX < viewRight and
           slotY + self.height > viewTop and slotY < viewBottom
end

function PJCK_FoodSlot:update()
    ISUIElement.update(self)
    if self.parentPanel and self.parentPanel.updateItemsVisibility then
        self.parentPanel:updateItemsVisibility()
    end
end

-- ---------------------------------------------------------- --
-- 渲染函数
-- ---------------------------------------------------------- --
function PJCK_FoodSlot:renderButton(button, icon)
    local iconSize = button.height * 0.7
    local iconX, iconY = (button.width - iconSize) / 2, (button.height - iconSize) / 2
    local alpha = button:isMouseOver() and not button.pressed and 1 or 0.6
    local r, g, b = 0.8, 0.8, 0.8

    -- A yellow return button means the item has no saved source container
    -- and will use the selected Food container/main inventory fallback.
    if icon == self.ReturnIcon and self:usesFallbackReturnTarget() then
        r, g, b = 1.0, 0.72, 0.25
    end
    
    button:drawTextureScaled(icon, iconX, iconY, iconSize, iconSize, alpha, r, g, b)
end

-- 绘制转移动作进度
function PJCK_FoodSlot:renderProgressBar(progress)

    local progressSize = self.size*0.8
    local progressX = (self.size - progressSize) / 2
    local progressY = (self.size - progressSize) / 2
    
    self:drawTextureScaled(self.Progress_BG, progressX, progressY, progressSize, progressSize, 0.8, 0.2, 0.2, 0.2)

    local totalSegments = 12
    local segmentsToShow = math.floor(progress * totalSegments)
    for i = 1, segmentsToShow do
        self:drawTextureScaled(self.progressSegments[i], progressX, progressY, progressSize, progressSize, 0.8, 0.5, 0.5, 0.5)
    end
end

function PJCK_FoodSlot:prerender()
    if not self:isInViewport() then
        return
    end
    -- 绘制背景
    self:drawTextureScaled(self.slotTextures.background, 0, 0, self.size, self.size, 0.8, 0.4, 0.4, 0.4)
    -- 绘制边框
    self:drawTextureScaled(self.slotTextures.border, 0, 0, self.size, self.size, 0.8, 0.4, 0.4, 0.4) 
    
    -- 绘制底部按钮背景
    if self.item and self.count > 0 then
        PJCK_UIHelper.drawThreeSlice(self, 0, self.size, self.size, self.ButtonHeight,
            self.bottomBarTextures.left, self.bottomBarTextures.middle, self.bottomBarTextures.right,
            1.0, 0.8, 0.8, 0.8)
    end

    -- 绘制温度指示器
    if self.item then
        local currentHeat, heatAlpha, isHot, isCold = self:getItemTemperature(self.item)
        if heatAlpha > 0 then
            local r, g, b = 1.0, 1.0, 1.0
            
            if isHot then
                if currentHeat >= 2.5 then
                    r, g, b = 0.8, 0.2, 0.1
                elseif currentHeat >= 2.0 then
                    r, g, b = 0.8, 0.5, 0.1
                else
                    r, g, b = 0.8, 0.3, 0.1
                end
            elseif isCold then
                heatAlpha = 0.4
                r, g, b = 0.6, 0.8, 1.0
            end
            
            self:drawTextureScaled(self.DurabilityTexture, 0, 0, self.size, self.size, heatAlpha, r, g, b)
        end
    end
    
    -- 悬浮效果
    if self:isMouseOver() and not self:isMouseOverButtons() then
        self:drawTextureScaled(self.slotTextures.backgroundHover, 0, 0, self.size, self.size, 0.3, 0.5, 0.5, 0.5)
    end
end

function PJCK_FoodSlot:render()
    if not self:isInViewport() then
        return
    end

    -- 绘制图标
    local iconX = (self.size - self.iconSize) / 2
    local iconY = (self.size - self.iconSize) / 2
    ISInventoryItem.renderItemIcon(self, self.item, iconX, iconY, 1, self.iconSize, self.iconSize)

    -- Draw raw-danger or burnt-state icon.
    if self.item and self.item:isFood() then
        local IconSize = math.floor(self.width / 4)
        local margin = math.floor(self.width / 12)
        if self.item:isBurnt() and self.burntIconTexture then
            self:drawTextureScaled(self.burntIconTexture, margin, margin, IconSize, IconSize, 1.0, 1, 1, 1)
        elseif self.item:isbDangerousUncooked() and not self.item:isCooked() and self.cookableIconTexture then
            self:drawTextureScaled(self.cookableIconTexture, margin, margin, IconSize, IconSize, 1.0, 1, 1, 1)
        end
    end

    -- Draw frozen-state icon for represented food stacks.
    local anyFrozen, allFrozen = self:getFrozenStackState()
    if anyFrozen and self.frozenIconTexture then
        local IconSize = math.floor(self.width / 4)
        local margin = math.floor(self.width / 12)
        local alpha = allFrozen and 1.0 or 0.45
        self:drawTextureScaled(self.frozenIconTexture, margin, self.size - IconSize - margin, IconSize, IconSize, alpha, 1, 1, 1)
    end

    -- 绘制进度条
    local isTransferring, transferProgress = self:isTransferring(self.item)
    if isTransferring and transferProgress > 0 then
        self:renderProgressBar(transferProgress)
    end
    
    -- Draw cooking/burning remaining percentage.
    -- While raw food is cooking, this is the percentage left until cooked.
    -- Once cooked food starts burning, this is the percentage left until burnt.
    if self.item then
        local cookingInfo = self:getCookingDisplayInfo(self.item)
        if cookingInfo and cookingInfo.value then
            local degreeText = tostring(cookingInfo.value)
            local textSize = self.size / 4
            local textWidth = PJCK_UIHelper.measureTextWidth(degreeText, textSize, true)
            local margin = self.size / 12
            local textX = self.size - textWidth - margin
            local textY = margin
            local r, g, b = 1, 1, 1

            if cookingInfo.state == "burning" then
                r, g, b = 1.0, 0.35, 0.25
            end

            PJCK_UIHelper.renderText(self, degreeText, textX, textY, textSize, 1, r, g, b, true)
        end
    end
    
    -- 显示数量信息
    if self.count > 1 then
        local countStr = tostring(self.count)
        local textSize = self.size / 4
        local textWidth = PJCK_UIHelper.measureTextWidth(countStr, textSize, true)
        local margin = self.size / 12

        PJCK_UIHelper.renderText(self, countStr, 
            self.size - textWidth - margin,
            self.size - textSize - margin,
            textSize, 1.0, 1, 1, 1, true)
    end
end

return PJCK_FoodSlot