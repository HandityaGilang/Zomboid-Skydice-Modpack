require "ISUI/ISPanel"
-- Action modules are loaded defensively to keep older B42 branches tolerant if a file name changes.
pcall(require, "TimedActions/ISBBQAddFuel")
pcall(require, "TimedActions/ISBBQExtinguish")
pcall(require, "TimedActions/ISBBQLightFromKindle")
pcall(require, "TimedActions/ISBBQLightFromLiterature")
pcall(require, "TimedActions/ISBBQLightFromPetrol")
pcall(require, "TimedActions/ISToggleStoveAction")
pcall(require, "TimedActions/ISBBQToggle")
pcall(require, "ISUI/ISBBQMenu")

PJCK_CookerPicker = ISPanel:derive("PJCK_CookerPicker")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_CookerPicker:initialise()
    ISPanel.initialise(self)
end

-- 计算所需高度的静态方法
function PJCK_CookerPicker.calculateRequiredHeight()
    local titleHeight = FONT_HGT_MEDIUM * 1.2
    local Padding = FONT_HGT_SMALL / 3
    local slotSize = FONT_HGT_MEDIUM * 3.5
    
    local totalHeight = titleHeight + Padding * 2 + slotSize
    return math.floor(totalHeight)
end

function PJCK_CookerPicker:new(x, y, width, height, CookerPanel)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.CookerPanel = CookerPanel
    o.player = CookerPanel.player
    
    o.clearIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_Remove.png")
    
    return o
end

-- ---------------------------------------------------------- --
-- 创建子元素
-- ---------------------------------------------------------- --

function PJCK_CookerPicker:createChildren()
    -- 计算布局参数
    self.titleHeight = FONT_HGT_MEDIUM * 1.2
    self.padding = FONT_HGT_SMALL / 3
    self.contentY = self.titleHeight + self.padding
    self.slotSize = FONT_HGT_MEDIUM * 3.5
    
    -- 创建标题栏
    self.titleBar = ISPanel:new(0, 0, self.width, self.titleHeight)
    self.titleBar:initialise()
    self.titleBar.backgroundColor.a = 0
    self.titleBar.borderColor.a = 0
    self:addChild(self.titleBar)
    
    -- 标题文本
    local titleTextY = (self.titleHeight - FONT_HGT_SMALL) / 2
    local cookerLabel = ISLabel:new(self.padding, titleTextY, FONT_HGT_SMALL, 
                                  getText("IGUI_PJCK_SelectCooker"), 1, 1, 1, 1, UIFont.Small, true)
    cookerLabel:initialise()
    self.titleBar:addChild(cookerLabel)
    
    -- 清除按钮
    local clearButtonSize = FONT_HGT_SMALL
    self.clearButton = PJCK_SquareButton.createClearButton(
        self.width - clearButtonSize - self.padding,
        titleTextY, 
        clearButtonSize, 
        self, 
        PJCK_CookerPicker.clearCooker
    )
    self.clearButton:initialise()
    self.clearButton:setVisible(false)
    self.titleBar:addChild(self.clearButton)
    
    -- CookerSlot
    self.cookerSlot = PJCK_CookerSlot:new(self.padding, self.contentY, self.slotSize, self)
    self.cookerSlot:initialise()
    self.cookerSlot.iconSize = FONT_HGT_MEDIUM * 2
    
    self.cookerSlot.onMouseDown = function(slot)
        self:showCookerContextMenu(slot:getX() + slot.width/2, slot:getY() + slot.height/2)
        return true
    end
    self:addChild(self.cookerSlot)
end

-- 布局计算
function PJCK_CookerPicker.calculateRequiredWidth()
    local padding = FONT_HGT_SMALL / 3
    local slotSize = FONT_HGT_MEDIUM * 3.5
    local buttonSize = slotSize * 0.6
    local totalWidth = padding + slotSize + padding + buttonSize + padding
    
    return math.floor(totalWidth)
end

-- ---------------------------------------------------------- --
-- Cooker设置
-- ---------------------------------------------------------- --

function PJCK_CookerPicker:setCooker(cooker)
    -- 主UI更新
    self.CookerPanel.selectedCooker = cooker
    self.CookerPanel:onCookerChanged(cooker)
    
    -- 更新按钮
    self.clearButton:setVisible(cooker ~= nil)
    self:updateControlButton()
end

function PJCK_CookerPicker:clearCooker()
    self:setCooker(nil)
end

function PJCK_CookerPicker:showCookerContextMenu(x, y)
    local player = self.player
    
    local slotRightX = self:getAbsoluteX() + self.cookerSlot:getX() + self.cookerSlot:getWidth()
    local slotTopY = self:getAbsoluteY() + self.cookerSlot:getY()
    
    local contextMenu = ISContextMenu.get(player:getPlayerNum(), slotRightX, slotTopY)
    contextMenu:setAlwaysOnTop(true)
    
    local availableCookers = self:findAvailableCookers()
    
    for i = 1, #availableCookers do
        local cookerData = availableCookers[i]
        local option = contextMenu:addOption(cookerData.displayName, self, self.setCooker, cookerData.container)
        local picker = self
        option.onHighlight = function(_, menu, isHighlighted, cooker)
            picker:onCookerOptionHighlight(menu, isHighlighted, cooker)
        end
        option.onHighlightParams = { cookerData.container }

        if cookerData.iconTexture then
            option.iconTexture = cookerData.iconTexture
        end
    end
end

function PJCK_CookerPicker:onCookerOptionHighlight(contextMenu, isHighlighted, cooker)
    if not cooker then return end

    local cookerObj = cooker:getParent()
    if not cookerObj then return end

    cookerObj:setHighlightColor(self.player:getPlayerNum(), getCore():getObjectHighlitedColor())
    if not isHighlighted and self.CookerPanel and self.CookerPanel.selectedCooker == cooker then
        cookerObj:setHighlighted(self.player:getPlayerNum(), true, false)
    else
        cookerObj:setHighlighted(self.player:getPlayerNum(), isHighlighted, false)
    end
end

-- 从容器中获取可用的Cooker
function PJCK_CookerPicker:findAvailableCookers()  
    local cookers = {}
    
    local containers = self.CookerPanel.MainPanel:getContainers()
    if not containers then return cookers end
    
    for i = 0, containers:size() - 1 do
        local container = containers:get(i)
        if self:isCookingContainer(container) then
            local containerType = container:getType()
            local displayName = getTextOrNull("IGUI_ContainerTitle_" .. containerType) or containerType
            local iconTexture = ContainerButtonIcons[containerType]
            
            table.insert(cookers, {
                container = container,
                displayName = displayName,
                iconTexture = iconTexture
            })
        end
    end
    
    return cookers
end

-- 判断容器是否为烹饪设备容器
function PJCK_CookerPicker:isCookingContainer(container)
    if not container then return false end
    local parentObj = container:getParent()
    if not parentObj then return false end

    return instanceof(parentObj, "IsoStove") or
           instanceof(parentObj, "IsoFireplace") or
           instanceof(parentObj, "IsoBarbecue") or
           parentObj:getName() == "Campfire"
end

function PJCK_CookerPicker:selectSingleAvailableCooker()
    local availableCookers = self:findAvailableCookers()
    if #availableCookers == 1 then
        self:setCooker(availableCookers[1].container)
    end
end

-- ---------------------------------------------------------- --
-- Stove与丙烷BBQ
-- ---------------------------------------------------------- --
-- 创建开关按钮
function PJCK_CookerPicker:createControlButton()
    local buttonSize = self.slotSize * 0.6
    local buttonX = self.padding + self.slotSize + self.padding
    local buttonY = self.contentY + (self.slotSize - buttonSize) / 2
    
    -- 根据类型选择回调函数
    local cookerType = self.CookerPanel.CookerType
    local Onclick = cookerType == "PROPANE_BBQ" and PJCK_CookerPicker.onPropaneBBQButtonClick or PJCK_CookerPicker.onStoveButtonClick
    
    self.controlButton = PJCK_SquareButton.createOnAndOffButton(buttonX, buttonY, buttonSize, self, Onclick)
    self.controlButton:initialise()
    self:addChild(self.controlButton)
    
    return self.controlButton
end

-- IsoStove 点击处理
function PJCK_CookerPicker:onStoveButtonClick()
    local isPowered = self.CookerPanel.isPowered
    if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return end
    if not isPowered then return end

    local selectedCooker = self.CookerPanel.selectedCooker
    if not selectedCooker then return end
    
    local player = self.player
    local stoveObj = selectedCooker:getParent()
    if not stoveObj then return end

    -- Use the same timed action path as the vanilla loot/inventory button.
    -- Directly calling Toggle() can make the oven look enabled locally in MP
    -- while cooking does not start correctly on the authoritative side.
    if ISToggleStoveAction and stoveObj:getSquare() and luautils.walkAdj(player, stoveObj:getSquare()) then
        ISTimedActionQueue.add(ISToggleStoveAction:new(player, stoveObj))
        return
    end

    -- Fallback for older/changed B42 branches.
    stoveObj:Toggle()
    if stoveObj.PlayToggleSound then
        stoveObj:PlayToggleSound()
    end
    if stoveObj.sync then
        stoveObj:sync()
    end
end

-- PropaneBBQ 点击处理
function PJCK_CookerPicker:onPropaneBBQButtonClick()
    if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return end
    
    local hasGasTank = self.CookerPanel.hasGasTank
    local fuelAmount = self.CookerPanel.fuelAmount
    if not hasGasTank or fuelAmount <= 0 then return end

    local selectedCooker = self.CookerPanel.selectedCooker
    if not selectedCooker then return end
    
    local player = self.player
    local bbqObj = selectedCooker:getParent()
    if not bbqObj then return end

    -- Match the vanilla propane BBQ toggle path when available.
    if ISBBQMenu and ISBBQMenu.onToggle then
        ISBBQMenu.onToggle(nil, player:getPlayerNum(), bbqObj, nil)
        return
    end

    if ISBBQToggle and luautils.walkAdj(player, bbqObj:getSquare()) then
        ISTimedActionQueue.add(ISBBQToggle:new(player, bbqObj))
        return
    end

    -- Fallback for older/changed B42 branches.
    bbqObj:toggle()
    if bbqObj.sendObjectChange and IsoObjectChange and IsoObjectChange.STATE then
        bbqObj:sendObjectChange(IsoObjectChange.STATE)
    end
end

-- ---------------------------------------------------------- --
-- Fireplace & Campfire & CHARCOAL_BBQ 
-- ---------------------------------------------------------- --
-- 创建火源按钮
function PJCK_CookerPicker:createFireButton()
    local buttonSize = self.slotSize * 0.6
    local buttonX = self.padding + self.slotSize + self.padding
    local buttonY = self.contentY + (self.slotSize - buttonSize) / 2
    
    self.controlButton = PJCK_SquareButton.createFireButton(buttonX, buttonY, buttonSize, self, PJCK_CookerPicker.onFireButtonClick)
    self.controlButton:initialise()
    self:addChild(self.controlButton)
    
    return self.controlButton
end

-- 火源按钮点击处理
function PJCK_CookerPicker:onFireButtonClick()
    if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return end
    
    local selectedCooker = self.CookerPanel.selectedCooker
    if not selectedCooker then return end

    local player = self.player
    local cookerObj = selectedCooker:getParent()
    
    -- 检查当前状态决定是点燃还是扑灭
    local isLit = self.CookerPanel:isCookerLit()
    
    if isLit then
        -- 扑灭
        local cookerType = self.CookerPanel.CookerType
        if cookerType == "FIREPLACE" then
            if luautils.walkAdj(player, cookerObj:getSquare()) then
                ISTimedActionQueue.add(ISBBQExtinguish:new(player, cookerObj))
            end
        elseif cookerType == "CAMPFIRE" then
            local campfire = CCampfireSystem.instance:getLuaObjectOnSquare(cookerObj:getSquare())
            if campfire and ISCampingMenu.walkToCampfire(player, cookerObj:getSquare()) then
                ISTimedActionQueue.add(ISPutOutCampfireAction:new(player, campfire))
            end
        elseif cookerType == "CHARCOAL_BBQ" then
            if luautils.walkAdj(player, cookerObj:getSquare()) then
                ISTimedActionQueue.add(ISBBQExtinguish:new(player, cookerObj))
            end
        end
    else
        -- 点燃
        self:showLightFireContextMenu()
    end
end

-- 显示点火菜单
function PJCK_CookerPicker:showLightFireContextMenu()
    local player = self.player
    local playerNum = player:getPlayerNum()
    local selectedCooker = self.CookerPanel.selectedCooker
    local cookerObj = selectedCooker:getParent()
    
    -- 获取按钮的屏幕坐标
    local buttonRightX = self:getAbsoluteX() + self.controlButton:getX() + self.controlButton:getWidth()
    local buttonTopY = self:getAbsoluteY() + self.controlButton:getY()

    local contextMenu = ISContextMenu.get(playerNum, buttonRightX, buttonTopY)
    contextMenu:setAlwaysOnTop(true)
    
    -- 获取燃料信息
    local fuelInfo = ISCampingMenu.getNearbyFuelInfo(player)
    local cookerType = self.CookerPanel.CookerType
    local hasFuel = false
    
    if cookerType == "FIREPLACE" then
        hasFuel = cookerObj:hasFuel()
    elseif cookerType == "CAMPFIRE" then
        local campfire = CCampfireSystem.instance:getLuaObjectOnSquare(cookerObj:getSquare())
        hasFuel = campfire and campfire.fuelAmt and campfire.fuelAmt > 0
    elseif cookerType == "CHARCOAL_BBQ" then
        hasFuel = cookerObj:hasFuel()
    end
    
    local petrolAction, tinderAction, kindleAction
    if cookerType == "FIREPLACE" then
        -- B42 fireplace timed actions are handled by the BBQ action classes.
        petrolAction = ISBBQLightFromPetrol
        tinderAction = ISBBQLightFromLiterature
        kindleAction = ISBBQLightFromKindle
    elseif cookerType == "CAMPFIRE" then
        petrolAction = ISLightFromPetrol
        tinderAction = ISLightFromLiterature
        kindleAction = ISLightFromKindle
    elseif cookerType == "CHARCOAL_BBQ" then
        petrolAction = ISBBQLightFromPetrol
        tinderAction = ISBBQLightFromLiterature
        kindleAction = ISBBQLightFromKindle
    end

    if cookerType == "CAMPFIRE" then
        cookerObj = CCampfireSystem.instance:getLuaObjectOnSquare(cookerObj:getSquare())
    end
    
    ISCampingMenu.doLightFireOption(player, contextMenu, {cookerObj}, hasFuel,fuelInfo, cookerObj, petrolAction, tinderAction, kindleAction)
end

-- ---------------------------------------------------------- --
-- 更新
-- ---------------------------------------------------------- --
-- 更新按钮状态
function PJCK_CookerPicker:updateControlButton()
    -- 移除旧按钮
    if self.controlButton then
        self:removeChild(self.controlButton)
        self.controlButton = nil
    end
    
    local cooker = self.CookerPanel.selectedCooker
    if not cooker then return end
    
    local cookerType = self.CookerPanel.CookerType
    if cookerType == "STOVE" or cookerType == "PROPANE_BBQ" then
        self:createControlButton()
    elseif cookerType == "FIREPLACE" or cookerType == "CAMPFIRE" or cookerType == "CHARCOAL_BBQ" then
        self:createFireButton()
    end
end

function PJCK_CookerPicker:updateButtonState()
    local cookerType = self.CookerPanel.CookerType
    
    if cookerType == "STOVE" or cookerType == "PROPANE_BBQ" then
        if not self.controlButton then return end
        
        local isEnabled = true
        local stateStr = "off"
        
        if cookerType == "STOVE" then
            local isPowered = self.CookerPanel.isPowered
            if not isPowered then
                stateStr = "noPower"
                isEnabled = false
            elseif self.CookerPanel:isCookerLit() then
                stateStr = "off"
            else
                stateStr = "on"
            end
        elseif cookerType == "PROPANE_BBQ" then
            local hasGasTank = self.CookerPanel.hasGasTank
            local fuelAmount = self.CookerPanel.fuelAmount
            if not hasGasTank or fuelAmount <= 0 then
                stateStr = "noPower"
                isEnabled = false
            elseif self.CookerPanel:isCookerLit() then
                stateStr = "off"
            else
                stateStr = "on"
            end
        end
        
        self.controlButton:setOnAndOffState(stateStr)
        self.controlButton:setUsable(isEnabled)

    elseif cookerType == "FIREPLACE" or cookerType == "CAMPFIRE" or cookerType == "CHARCOAL_BBQ" then
        if not self.controlButton then return end
        
        local isLit = self.CookerPanel:isCookerLit()
        self.controlButton:setOnAndOffState(isLit and "off" or "on")
    end
end

function PJCK_CookerPicker:NoNearbySelectedCooker()
    local selectedCooker = self.CookerPanel.selectedCooker
    if not selectedCooker then
        return false
    end
    
    local availableCookers = self:findAvailableCookers()

    for i = 1, #availableCookers do
        if availableCookers[i].container == selectedCooker then
            return false
        end
    end

    return true
end

function PJCK_CookerPicker:update()
    ISPanel.update(self)

    if self:NoNearbySelectedCooker() then
        self:setCooker(nil)
        return
    end
    
    self:updateButtonState()
end

-- ---------------------------------------------------------- --
-- 渲染
-- ---------------------------------------------------------- --

function PJCK_CookerPicker:prerender()
    -- 绘制背景
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        self.titleBar:getHeight(),
        self.width,
        self.height - self.titleBar:getHeight(),
        self.CookerPanel.contentBgTextures,
        1.0, 0.1, 0.1, 0.1
    )
    
    -- 绘制标题栏
    PJCK_UIHelper.drawThreeSlice(
        self,
        0,
        0,
        self.width,
        self.titleBar:getHeight(),
        self.CookerPanel.titleBarTextures.left,
        self.CookerPanel.titleBarTextures.middle,
        self.CookerPanel.titleBarTextures.right,
        1.0, 0.2, 0.2, 0.2
    )
end

function PJCK_CookerPicker:render()
    -- ISPanel.render(self)
end

return PJCK_CookerPicker