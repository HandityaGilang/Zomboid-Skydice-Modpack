require "ISUI/ISPanel"
-- Loaded defensively for older B42 compatibility.
pcall(require, "TimedActions/ISBBQAddFuel")

PJCK_CookerAdjustmentPanel = ISPanel:derive("PJCK_CookerAdjustmentPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_CookerAdjustmentPanel:initialise()
    ISPanel.initialise(self)
end

function PJCK_CookerAdjustmentPanel:new(x, y, width, height, CookerPanel)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.CookerPanel = CookerPanel
    o.player = CookerPanel.player
    
    -- 动态按钮容器
    o.adjustmentInfo = {}
    o.fuelInfoLabel = nil
    
    -- 按钮背景贴图
    o.buttonTextures = {
        left = getTexture("media/ui/Project_Cook/Button/Button_BG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Button/Button_BG_M.png"),
        right = getTexture("media/ui/Project_Cook/Button/Button_BG_R.png")
    }
    
    return o
end

-- ---------------------------------------------------------- --
-- 创建子元素
-- ---------------------------------------------------------- --

function PJCK_CookerAdjustmentPanel:createChildren()
    local titleHeight = FONT_HGT_MEDIUM * 1.2
    local padding = FONT_HGT_SMALL * 0.4
    
    -- 创建标题栏
    self.titleBar = ISPanel:new(0, 0, self.width, titleHeight)
    self.titleBar:initialise()
    self.titleBar.backgroundColor.a = 0
    self.titleBar.borderColor.a = 0
    self:addChild(self.titleBar)
    
    -- 标题文本
    local titleTextY = (titleHeight - FONT_HGT_SMALL) / 2
    local adjustmentLabel = ISLabel:new(padding, titleTextY, FONT_HGT_SMALL, 
                                      getText("IGUI_PJCK_CookerAdjustment"), 1, 1, 1, 1, UIFont.Small, true)
    adjustmentLabel:initialise()
    self.titleBar:addChild(adjustmentLabel)
    self.titleHeight = titleHeight

end

-- ---------------------------------------------------------- --
-- Cooker设置与管理
-- ---------------------------------------------------------- --

function PJCK_CookerAdjustmentPanel:setCooker(cooker)
    -- 清除现有信息
    self:clearAdjustmentInfo()
    
    if cooker then
        local cookerType = self.CookerPanel.CookerType
        if cookerType == "FIREPLACE" or cookerType == "CAMPFIRE" or cookerType == "CHARCOAL_BBQ" then
            self:createFireInfo()
        elseif cookerType == "PROPANE_BBQ" then
            self:createPropaneInfo()
        elseif cookerType == "STOVE" then
            self:createStoveInfo()
        end
    end
end

function PJCK_CookerAdjustmentPanel:clearAdjustmentInfo()
    for _, item in ipairs(self.adjustmentInfo) do
        self:removeChild(item)
    end
    self.adjustmentInfo = {}
    self.fuelInfoLabel = nil
    self.tempSlot = nil
    self.timerSlot = nil
end

-- ---------------------------------------------------------- --
-- STOVE & MICROWAVE
-- ---------------------------------------------------------- --
-- 创建对应元素
function PJCK_CookerAdjustmentPanel:createStoveInfo()
    local padding = FONT_HGT_SMALL * 0.4
    local slotWidth = (self.width - padding * 3) / 2
    local slotHeight = FONT_HGT_MEDIUM * 3
    
    local slotY = self.titleHeight + padding
    
    -- 获取当前炉子状态
    local selectedCooker = self.CookerPanel.selectedCooker
    local stoveObj = selectedCooker and selectedCooker:getParent()
    
    -- 判断是否为微波炉
    local isMicrowave = stoveObj and stoveObj:isMicrowave()
    
    -- 调试输出
    if stoveObj then
        if stoveObj.getContainer then
            local container = stoveObj:getContainer()
            if container then
            end
        end
    end
    
    -- 创建温度调整槽位
    local tempTitle = getText("IGUI_Temperature")
    local currentTemp = stoveObj and stoveObj:getMaxTemperature() or 0
    local tempMin, tempMax, tempStep = self:getTempRange(isMicrowave)
    
    self.tempSlot = PJCK_ValueAdjustmentSlot:new(
        padding, slotY, slotWidth, slotHeight,
        tempTitle, currentTemp, tempMin, tempMax, tempStep,
        self, PJCK_CookerAdjustmentPanel.onTempChange, nil
    )
    self.tempSlot:initialise()
    self:addChild(self.tempSlot)
    table.insert(self.adjustmentInfo, self.tempSlot)
    
    -- 创建计时器调整槽位
    local timerTitle = getText("IGUI_Timer")
    local currentTimer = stoveObj and math.floor(stoveObj:getTimer() / 60)
    local timerMin, timerMax, timerStep = self:getTimerRange(isMicrowave)
    
    self.timerSlot = PJCK_ValueAdjustmentSlot:new(
        padding * 2 + slotWidth, slotY, slotWidth, slotHeight,
        timerTitle, currentTimer, timerMin, timerMax, timerStep,
        self, PJCK_CookerAdjustmentPanel.onTimerChange, PJCK_CookerAdjustmentPanel.getTimerFormatter
    )
    self.timerSlot:initialise()
    self:addChild(self.timerSlot)
    table.insert(self.adjustmentInfo, self.timerSlot)
end

-- 获取温度范围
function PJCK_CookerAdjustmentPanel:getTempRange(isMicrowave)
    if isMicrowave then
        -- 微波炉温度范围
        return 50, 130, 20
    else
        -- 烤箱温度范围
        return 50, 300, 50
    end
end

-- 获取计时器范围
function PJCK_CookerAdjustmentPanel:getTimerRange(isMicrowave)
    if isMicrowave then
        -- 微波炉计时器范围
        return 0, 60, 5
    else
        -- 烤箱计时器范围
        return 0, 120, 5
    end
end

-- 计时器格式化函数
function PJCK_CookerAdjustmentPanel.getTimerFormatter(value)
    if value <= 0 then
        return "0m"
    elseif value < 60 then
        return value .. "m"
    else
        local hours = math.floor(value / 60)
        local mins = value % 60
        if mins == 0 then
            return hours .. "h"
        else
            return hours .. "h" .. mins .. "m"
        end
    end
end

function PJCK_CookerAdjustmentPanel.syncStoveSettings(stoveObj, sync)
    if not stoveObj then return end

    if sync and stoveObj.sync then
        stoveObj:sync()
    end

    -- Vanilla ISOvenUI refreshes sprite-grid stove objects after changing
    -- temperature/timer values. Keep this guarded for older B42 branches.
    if stoveObj.syncSpriteGridObjects then
        pcall(function()
            stoveObj:syncSpriteGridObjects(false, sync == true)
        end)
    end
end

-- 温度改变回调
function PJCK_CookerAdjustmentPanel.onTempChange(slot, newValue)
    local panel = slot.parentPanel
    local selectedCooker = panel.CookerPanel.selectedCooker
    if not selectedCooker then return end
    
    local stoveObj = selectedCooker:getParent()
    if not stoveObj then return end
    
    stoveObj:setMaxTemperature(newValue)
    
    -- 发送同步信息（参考ISMicrowaveUI和ISOvenUI）
    local shouldSync = not panel.tempSlot.dragging and not panel.timerSlot.dragging
    PJCK_CookerAdjustmentPanel.syncStoveSettings(stoveObj, shouldSync)
end

-- 计时器改变回调
function PJCK_CookerAdjustmentPanel.onTimerChange(slot, newValue)
    local panel = slot.parentPanel
    local selectedCooker = panel.CookerPanel.selectedCooker
    if not selectedCooker then return end
    
    local stoveObj = selectedCooker:getParent()
    if not stoveObj then return end
    
    -- 转换分钟为秒
    stoveObj:setTimer(newValue * 60)
    
    -- 发送同步信息
    local shouldSync = not panel.tempSlot.dragging and not panel.timerSlot.dragging
    PJCK_CookerAdjustmentPanel.syncStoveSettings(stoveObj, shouldSync)
end

-- ---------------------------------------------------------- --
-- FIREPLACE & CAMPFIRE & CHARCOAL_BBQ
-- ---------------------------------------------------------- --
-- 创建对应元素
function PJCK_CookerAdjustmentPanel:createFireInfo()
    local padding = FONT_HGT_SMALL * 0.4
    local buttonSize = FONT_HGT_MEDIUM * 2
    
    local buttonY = self.titleHeight + (self.height - self.titleHeight - buttonSize) / 2
    
    -- 添加燃料按钮
    local addFuelButton = PJCK_SquareButton.createAddFuelButton(padding, buttonY, buttonSize, self, PJCK_CookerAdjustmentPanel.onAddFuelButtonClick)
    addFuelButton:initialise()
    self:addChild(addFuelButton)
    table.insert(self.adjustmentInfo, addFuelButton)
    
    -- 添加燃料信息标签
    local labelX = padding + buttonSize + FONT_HGT_SMALL * 0.5
    local labelY = buttonY + (buttonSize - FONT_HGT_SMALL) / 2
    self.fuelInfoLabel = ISLabel:new(labelX, labelY, FONT_HGT_SMALL, "", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.fuelInfoLabel:initialise()
    self:addChild(self.fuelInfoLabel)
    table.insert(self.adjustmentInfo, self.fuelInfoLabel)
end

-- 燃料添加按钮点击处理
function PJCK_CookerAdjustmentPanel:onAddFuelButtonClick()
    
    if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then 
        return 
    end
    
    local selectedCooker = self.CookerPanel.selectedCooker
    if not selectedCooker then return end
    
    local player = self.player
    local currentFuel = self:getCurrentFuelAmount()
    local cookerType = self.CookerPanel.CookerType
    
    -- 获取目标对象
    local cookerObj = selectedCooker:getParent()
    local targetObject
    if cookerType == "CAMPFIRE" then
        targetObject = CCampfireSystem.instance:getLuaObjectOnSquare(cookerObj:getSquare())
    else
        targetObject = cookerObj
    end
    
    -- 获取燃料添加动作
    local fuelAction
    if cookerType == "FIREPLACE" then
        fuelAction = ISBBQAddFuel
    elseif cookerType == "CAMPFIRE" then
        fuelAction = ISAddFuelAction
    elseif cookerType == "CHARCOAL_BBQ" then
        fuelAction = ISBBQAddFuel
    end
    
    if not fuelAction or not targetObject then return end
    
    -- 获取燃料信息
    local fuelInfo = ISCampingMenu.getNearbyFuelInfo(player)
    
    -- 创建燃料添加选项
    local playerNum = player:getPlayerNum()
    local buttonRightX = self:getAbsoluteX() + self.adjustmentInfo[1]:getX() + self.adjustmentInfo[1]:getWidth()
    local buttonTopY = self:getAbsoluteY() + self.adjustmentInfo[1]:getY()
    
    local contextMenu = ISContextMenu.get(playerNum, buttonRightX, buttonTopY)
    contextMenu:setAlwaysOnTop(true)

    ISCampingMenu.doAddFuelOption(contextMenu, {targetObject}, currentFuel, fuelInfo, targetObject, fuelAction, player)
end

-- 获取当前燃料量
function PJCK_CookerAdjustmentPanel:getCurrentFuelAmount()
    local selectedCooker = self.CookerPanel.selectedCooker
    if not selectedCooker then return 0 end
    
    local cookerType = self.CookerPanel.CookerType
    local cookerObj = selectedCooker:getParent()
    
    if cookerType == "FIREPLACE" or cookerType == "CHARCOAL_BBQ" then
        return cookerObj:getFuelAmount()
    elseif cookerType == "CAMPFIRE" then
        local campfire = CCampfireSystem.instance:getLuaObjectOnSquare(cookerObj:getSquare())
        return campfire and campfire.fuelAmt or 0
    end
    
    return 0
end

-- ---------------------------------------------------------- --
-- 丙烷BBQ
-- ---------------------------------------------------------- --
function PJCK_CookerAdjustmentPanel:createPropaneInfo()
    local padding = FONT_HGT_SMALL * 0.4
    local slotSize = FONT_HGT_MEDIUM * 2
    
    local slotY = self.titleHeight + (self.height - self.titleHeight - slotSize) / 2
    
    -- 创建气罐槽位
    local propaneSlot = PJCK_PropaneTankSlot:new(padding, slotY, slotSize, self)
    propaneSlot:initialise()
    self:addChild(propaneSlot)
    table.insert(self.adjustmentInfo, propaneSlot)
    
    -- 添加气罐信息标签
    local labelX = padding + slotSize + FONT_HGT_SMALL * 0.5
    local labelY = slotY + (slotSize - FONT_HGT_SMALL) / 2
    self.tankInfoLabel = ISLabel:new(labelX, labelY, FONT_HGT_SMALL, "", 0.8, 0.8, 0.8, 1, UIFont.Small, true)
    self.tankInfoLabel:initialise()
    self:addChild(self.tankInfoLabel)
    table.insert(self.adjustmentInfo, self.tankInfoLabel)
end

-- ---------------------------------------------------------- --
-- 更新函数
-- ---------------------------------------------------------- --

function PJCK_CookerAdjustmentPanel:update()
    ISPanel.update(self)
    
    local selectedCooker = self.CookerPanel.selectedCooker
    local cookerType = self.CookerPanel.CookerType
    
    -- 更新STOVE信息显示
    if cookerType == "STOVE" and selectedCooker then
        local stoveObj = selectedCooker:getParent()
        if stoveObj and self.tempSlot and self.timerSlot then
            -- 更新温度槽位的值
            local currentTemp = stoveObj:getMaxTemperature()
            if self.tempSlot.value ~= currentTemp then
                self.tempSlot.value = currentTemp
            end
            
            -- 更新计时器槽位的值
            local currentTimer = math.floor(stoveObj:getTimer() / 60)
            if stoveObj:isRunningFor() > 0 then
                currentTimer = math.ceil((stoveObj:getTimer() - stoveObj:isRunningFor()) / 60)
            end
            if self.timerSlot.value ~= currentTimer then
                self.timerSlot.value = currentTimer
            end
        end
    end
    
    -- 更新燃料信息显示
    if self.fuelInfoLabel and selectedCooker then
        local fuelAmount = self:getCurrentFuelAmount()
        local timeString = ISCampingMenu.timeString(round(fuelAmount))
        local displayText = getText("IGUI_BBQ_FuelAmount", timeString)
        self.fuelInfoLabel:setName(displayText)
    end
    
    -- 更新气罐信息显示
    if self.tankInfoLabel and selectedCooker and cookerType == "PROPANE_BBQ" then
        local hasGasTank = self.CookerPanel.hasGasTank
        if hasGasTank then
            local fuelAmount = self.CookerPanel.fuelAmount
            local timeString = ISCampingMenu.timeString(round(fuelAmount))
            local displayText = getText("IGUI_BBQ_FuelAmount", timeString)
            self.tankInfoLabel:setName(displayText)
        else
            self.tankInfoLabel:setName(getText("IGUI_BBQ_NeedsPropaneTank"))
        end
    end
end

-- ---------------------------------------------------------- --
-- 渲染函数
-- ---------------------------------------------------------- --

function PJCK_CookerAdjustmentPanel:prerender()
    -- 绘制内容区域背景
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        self.titleHeight,
        self.width,
        self.height - self.titleHeight,
        self.CookerPanel.contentBgTextures,
        1.0, 0.1, 0.1, 0.1
    )
    
    -- 绘制标题栏
    PJCK_UIHelper.drawThreeSlice(
        self,
        0,
        0,
        self.width,
        self.titleHeight,
        self.CookerPanel.titleBarTextures.left,
        self.CookerPanel.titleBarTextures.middle,
        self.CookerPanel.titleBarTextures.right,
        1.0, 0.2, 0.2, 0.2
    )
end

function PJCK_CookerAdjustmentPanel:render()
end

return PJCK_CookerAdjustmentPanel