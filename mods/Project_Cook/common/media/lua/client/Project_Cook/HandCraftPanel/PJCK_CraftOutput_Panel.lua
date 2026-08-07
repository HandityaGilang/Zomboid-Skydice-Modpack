require "ISUI/ISPanel"

PJCK_CraftOutput_Panel = ISPanel:derive("PJCK_CraftOutput_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Panel:initialise()
    ISPanel.initialise(self)
end

function PJCK_CraftOutput_Panel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    
    -- 输出物品相关
    o.outputItems = {}
    o.itemSpacing = FONT_HGT_SMALL * 0.5
    o.itemMargin = FONT_HGT_SMALL * 0.3
    o.itemSize = FONT_HGT_SMALL * 2.5
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- 创建子元素
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Panel:createChildren()
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
    local titleLabel = ISLabel:new(padding, titleTextY, FONT_HGT_SMALL, getText("IGUI_CraftingWindow_Creates"), 1, 1, 1, 1, UIFont.Small, true)
    titleLabel:initialise()
    self.titleBar:addChild(titleLabel)
    
    self.titleHeight = titleHeight
    
    -- 计算可用区域
    local contentStartY = titleHeight + padding
    local contentHeight = self.height - contentStartY - padding
    
    -- 创建滚动视图
    self.outputScrollPanel = PJCK_ScrollView:new(padding, contentStartY, self.width - padding * 2, contentHeight)
    self.outputScrollPanel:initialise()
    self.outputScrollPanel:setScrollDirection("horizontal")
    self:addChild(self.outputScrollPanel)
    self.outputScrollPanel:setWantKeyEvents(true)
end
-- ----------------------------------------------------------------------------------------------------- --
-- 输出物品管理
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Panel:updateOutputItems()
    for i = 1, #self.outputItems do
        self.outputScrollPanel:removeScrollChild(self.outputItems[i])
    end
    self.outputItems = {}

    local recipe = self.logic:getRecipe()
    if not recipe then return end

    local outputs = recipe:getOutputs()
    if outputs and outputs:size() > 0 then
        self:createOutputItems(outputs)
    end
end

function PJCK_CraftOutput_Panel:createOutputItems(outputs)
    local currentX = self.itemMargin
    local currentY = math.floor((self.height - self.titleHeight - self.itemSize - self.itemSpacing*2)/2)
    
    for i = 0, outputs:size() - 1 do
        local outputScript = outputs:get(i)

        if not outputScript:isAutomationOnly() then
            local outputItem = PJCK_CraftOutput_Slot:new(currentX, currentY, self.itemSize, self.player, outputScript, self)
            outputItem:initialise()
            
            self.outputScrollPanel:addScrollChild(outputItem)
            table.insert(self.outputItems, outputItem)
            
            currentX = currentX + self.itemSize + self.itemSpacing
        end
    end
    
    -- 设置滚动宽度
    local totalWidth = currentX + self.itemMargin
    self.outputScrollPanel:setScrollWidth(math.max(totalWidth, self.outputScrollPanel:getWidth()))
end

-- ----------------------------------------------------------------------------------------------------- --
-- 事件处理方法
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Panel:onRecipeChanged()
    self:updateOutputItems()
end

function PJCK_CraftOutput_Panel:onInputsChanged()
    -- 更新所有输出槽位的信息
    for i = 1, #self.outputItems do
        if self.outputItems[i].updateOutputInfo then
            self.outputItems[i]:updateOutputInfo()
        end
    end
end
-- ----------------------------------------------------------------------------------------------------- --
-- 更新方法
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Panel:update()
    ISPanel.update(self)

end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CraftOutput_Panel:prerender()
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

function PJCK_CraftOutput_Panel:render()

end

return PJCK_CraftOutput_Panel