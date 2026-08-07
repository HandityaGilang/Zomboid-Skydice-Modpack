require "ISUI/ISPanel"

PJCK_CraftInput_Panel = ISPanel:derive("PJCK_CraftInput_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Panel:initialise()
    ISPanel.initialise(self)
end

function PJCK_CraftInput_Panel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    
    -- 输入物品相关
    o.inputItems = {}  -- 统一的物品列表
    o.Slot_Padding = math.floor(FONT_HGT_SMALL * 0.5)
    o.Slot_Margin = math.floor(FONT_HGT_SMALL * 0.3)
    o.SlotHeight = math.floor(FONT_HGT_SMALL * 2.8)
    o.SlotWidth = o.SlotHeight * 3
    o.titleHeight = math.floor(FONT_HGT_MEDIUM * 1.2)
    
    o.columnCount = 2
    o.columnWidth = (width - o.Slot_Margin * 3) / 2
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- 创建子元素
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Panel:createChildren()
    
    -- 创建标题栏
    self.titleBar = ISPanel:new(0, 0, self.width, self.titleHeight)
    self.titleBar:initialise()
    self.titleBar.backgroundColor.a = 0
    self.titleBar.borderColor.a = 0
    self:addChild(self.titleBar)
    
    -- 标题文本
    local titleTextpadding = FONT_HGT_SMALL * 0.4
    local titleTextY = (self.titleHeight - FONT_HGT_SMALL) / 2
    local titleLabel = ISLabel:new(titleTextpadding, titleTextY, FONT_HGT_SMALL, getText("IGUI_CraftingWindow_Requires"), 1, 1, 1, 1, UIFont.Small, true)
    titleLabel:initialise()
    self.titleBar:addChild(titleLabel)
    
    -- 创建滚动面板
    local scrollpadding = FONT_HGT_SMALL * 0.2
    local contentStartY = self.titleHeight + scrollpadding
    local contentHeight = self.height - contentStartY - scrollpadding
    self.scrollPanel = PJCK_ScrollView:new(scrollpadding, contentStartY, self.width - scrollpadding * 2, contentHeight)
    self.scrollPanel:initialise()
    self.scrollPanel:setScrollDirection("vertical")
    self:addChild(self.scrollPanel)
    self.scrollPanel:setWantKeyEvents(true)
end

-- ----------------------------------------------------------------------------------------------------- --
-- 输入物品管理
-- ----------------------------------------------------------------------------------------------------- --

-- 更新输入物品
function PJCK_CraftInput_Panel:updateInputItems()
    self:clearInputItems()
    if not self.logic:getRecipe() then return end

    local recipe = self.logic:getRecipe()
    local inputs = recipe:getInputs()
    
    if inputs and inputs:size() > 0 then
        self:createInputItems(inputs)
    end
end

-- 清除现有的输入物品
function PJCK_CraftInput_Panel:clearInputItems()
    for i = 1, #self.inputItems do
        self.scrollPanel:removeScrollChild(self.inputItems[i])
    end
    self.inputItems = {}
end

-- 创建输入物品项
function PJCK_CraftInput_Panel:createInputItems(inputs)
    local ReturnInputList = {}
    local RegularInputList = {}
    
    self.logic:autoPopulateInputs()

    for i = 0, inputs:size() - 1 do
        local inputScript = inputs:get(i)
        
        -- 优先显示会保留的物品
        if not inputScript:isAutomationOnly() then
            if inputScript:isKeep() then
                table.insert(ReturnInputList, inputScript)
            else
                table.insert(RegularInputList, inputScript)
            end
        end
    end
    
    local allInputs = {}
    for _, inputScript in ipairs(ReturnInputList) do
        table.insert(allInputs, inputScript)
    end
    for _, inputScript in ipairs(RegularInputList) do
        table.insert(allInputs, inputScript)
    end

    self:createInputList(allInputs)
end

-- 创建输入列表
function PJCK_CraftInput_Panel:createInputList(allInputs)
    local currentRow = 0
    local itemsPerRow = 2
    
    for i, inputScript in ipairs(allInputs) do
        local col = (i - 1) % itemsPerRow
        local row = math.floor((i - 1) / itemsPerRow)
        
        -- 计算位置
        local x = self.Slot_Margin + col * (self.columnWidth + self.Slot_Padding)
        local y = self.Slot_Margin + row * (self.SlotHeight + self.Slot_Padding)
        
        local inputItem = PJCK_CraftInput_Slot:new(x, y, self.SlotWidth,self.SlotHeight, self.player, inputScript, self)
        inputItem:initialise()
        self.scrollPanel:addScrollChild(inputItem)
        table.insert(self.inputItems, inputItem)
        
        currentRow = row
    end
    
    -- 计算并设置滚动高度
    local totalRows = currentRow + 1
    local totalHeight = self.Slot_Margin * 2 + totalRows * (self.SlotHeight + self.Slot_Padding) - self.Slot_Padding
    self.scrollPanel:setScrollHeight(math.max(totalHeight, self.scrollPanel:getHeight()))
end

-- ----------------------------------------------------------------------------------------------------- --
-- 更新
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Panel:onRecipeChanged()
    self:updateInputItems()
end

function PJCK_CraftInput_Panel:onInputsChanged()
    for i = 1, #self.inputItems do
        if self.inputItems[i].updateInputInfo then
            self.inputItems[i]:updateInputInfo()
        end
    end
end

function PJCK_CraftInput_Panel:update()
    ISPanel.update(self)
end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftInput_Panel:prerender()
    -- 绘制内容区域背景
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        self.titleHeight,
        self.width,
        self.height - self.titleHeight,
        self.HandCraftPanel.contentBgTextures,
        1.0, 0.1, 0.1, 0.1
    )
    
    -- 绘制标题栏
    PJCK_UIHelper.drawThreeSlice(
        self,
        0,
        0,
        self.width,
        self.titleHeight,
        self.HandCraftPanel.titleBarTextures.left,
        self.HandCraftPanel.titleBarTextures.middle,
        self.HandCraftPanel.titleBarTextures.right,
        1.0, 0.2, 0.2, 0.2
    )
end

function PJCK_CraftInput_Panel:render()

end

return PJCK_CraftInput_Panel