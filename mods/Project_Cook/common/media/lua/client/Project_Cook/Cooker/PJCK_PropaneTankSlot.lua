require "ISUI/ISUIElement"
require "ISUI/ISBBQMenu"
-- Loaded defensively for older B42 compatibility.
pcall(require, "TimedActions/ISBBQInsertPropaneTank")
pcall(require, "TimedActions/ISBBQRemovePropaneTank")
pcall(require, "TimedActions/ISWalkToTimedAction")

PJCK_PropaneTankSlot = ISUIElement:derive("PJCK_PropaneTankSlot")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_PropaneTankSlot:initialise()
    ISUIElement.initialise(self)
end

function PJCK_PropaneTankSlot:new(x, y, size, parentPanel)
    local o = ISUIElement:new(x, y, size, size)
    setmetatable(o, self)
    self.__index = self
    
    o.size = size
    o.parentPanel = parentPanel
    o.removeButton = nil

    o.propaneTankTextures = {
        background = getTexture("media/ui/Project_Cook/Slot/Background.png"),
        backgroundHover = getTexture("media/ui/Project_Cook/Slot/Hover.png"),
        border = getTexture("media/ui/Project_Cook/Slot/Boarder.png"),
        tank = getTexture("media/ui/Project_Cook/ICON/Item_PropaneTank.png"),
        addIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Add.png"),
        durability = getTexture("media/ui/Project_Cook/Slot/Durability_RoundBottom.png")
    }
    
    return o
end

-- ---------------------------------------------------------- --
-- 创建子组件
-- ---------------------------------------------------------- --

function PJCK_PropaneTankSlot:createRemoveButton()
    local buttonSize = self.size / 4
    local padding = FONT_HGT_SMALL / 4
    
    self.removeButton = PJCK_SquareButton.createClearButton(
        self.size - buttonSize - padding, 
        padding, 
        buttonSize, 
        self, 
        PJCK_PropaneTankSlot.onRemoveTank
    )
    self.removeButton:initialise()
    self:addChild(self.removeButton)
end

function PJCK_PropaneTankSlot:removeRemoveButton()
    if self.removeButton then
        self:removeChild(self.removeButton)
        self.removeButton = nil
    end
end

-- ---------------------------------------------------------- --
-- 数据更新
-- ---------------------------------------------------------- --

function PJCK_PropaneTankSlot:updateTankStatus()
    local hasGasTank = self.parentPanel.CookerPanel.hasGasTank
    
    -- 创建或移除按钮
    if hasGasTank and not self.removeButton then
        self:createRemoveButton()
    elseif not hasGasTank and self.removeButton then
        self:removeRemoveButton()
    end
end

-- ---------------------------------------------------------- --
-- 动作处理
-- ---------------------------------------------------------- --
function PJCK_PropaneTankSlot:onMouseDown(x, y)
    local hasGasTank = self.parentPanel.CookerPanel.hasGasTank
    if hasGasTank then
        -- Let the remove button receive the click when a tank is already installed.
        return false
    end

    self:onAddTank()
    return true
end

function PJCK_PropaneTankSlot:onAddTank()
    if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then 
        return 
    end
    
    local selectedCooker = self.parentPanel.CookerPanel.selectedCooker
    if not selectedCooker then return end
    
    local player = self.parentPanel.player
    local bbqObj = selectedCooker:getParent()
    
    -- 查找气罐
    local tank = ISBBQMenu.FindPropaneTank(player, bbqObj)
    if not tank then return end
    
    -- 直接执行插入气罐操作
    self:insertPropaneTank(tank)
end

function PJCK_PropaneTankSlot:insertPropaneTank(tank)
    local player = self.parentPanel.player
    local selectedCooker = self.parentPanel.CookerPanel.selectedCooker
    local bbqObj = selectedCooker:getParent()
    
    if instanceof(tank, "IsoWorldInventoryObject") then
        if player:getSquare() ~= tank:getSquare() then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(player, tank:getSquare()))
        end
        ISTimedActionQueue.add(ISBBQInsertPropaneTank:new(player, bbqObj, tank))
    elseif luautils.walkAdj(player, bbqObj:getSquare()) then
        ISWorldObjectContextMenu.transferIfNeeded(player, tank)
        ISTimedActionQueue.add(ISBBQInsertPropaneTank:new(player, bbqObj, tank))
    end
end

function PJCK_PropaneTankSlot:onRemoveTank()
    if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then 
        return 
    end
    
    local selectedCooker = self.parentPanel.CookerPanel.selectedCooker
    if not selectedCooker then return end
    
    local player = self.parentPanel.player
    local bbqObj = selectedCooker:getParent()
    if not player or not bbqObj or not bbqObj.hasPropaneTank or not bbqObj:hasPropaneTank() then return end

    -- Prefer the vanilla BBQ handler so this button behaves like the world-object / loot UI option.
    if ISBBQMenu and ISBBQMenu.onRemovePropaneTank then
        ISBBQMenu.onRemovePropaneTank({bbqObj}, player:getPlayerNum(), bbqObj)
    elseif ISBBQRemovePropaneTank and ISBBQRemovePropaneTank.new and luautils.walkAdj(player, bbqObj:getSquare()) then
        ISTimedActionQueue.add(ISBBQRemovePropaneTank:new(player, bbqObj))
    end
end

-- ---------------------------------------------------------- --
-- 渲染
-- ---------------------------------------------------------- --

function PJCK_PropaneTankSlot:prerender()
    -- 绘制背景
    self:drawTextureScaled(self.propaneTankTextures.background, 
                          0, 0, self.width, self.height, 0.8, 0.4, 0.4, 0.4)
    
    -- 绘制边框
    self:drawTextureScaled(self.propaneTankTextures.border, 
                          0, 0, self.width, self.height, 0.8, 0.4, 0.4, 0.4)
    
    -- 悬浮效果
    local hasGasTank = self.parentPanel.CookerPanel.hasGasTank
    if self:isMouseOver() and not hasGasTank then
        self:drawTextureScaled(self.propaneTankTextures.backgroundHover, 
                              0, 0, self.width, self.height, 0.5, 0.5, 0.5, 0.5)
    end
end

function PJCK_PropaneTankSlot:render()
    local hasGasTank = self.parentPanel.CookerPanel.hasGasTank
    
    if hasGasTank then
        -- 绘制气罐图标
        local iconSize = self.size * 0.6
        local iconX = (self.width - iconSize) / 2
        local iconY = (self.height - iconSize) / 2
        
        self:drawTextureScaled(self.propaneTankTextures.tank, 
                              iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
    else
        -- 绘制添加图标
        local iconSize = self.size / 2
        local iconX = (self.width - iconSize) / 2
        local iconY = (self.height - iconSize) / 2

        self:drawTextureScaledAspect(self.propaneTankTextures.addIcon, 
                                    iconX, iconY, iconSize, iconSize, 0.6, 0.7, 0.7, 0.7)
    end
end

function PJCK_PropaneTankSlot:update()
    ISUIElement.update(self)
    self:updateTankStatus()
end

return PJCK_PropaneTankSlot