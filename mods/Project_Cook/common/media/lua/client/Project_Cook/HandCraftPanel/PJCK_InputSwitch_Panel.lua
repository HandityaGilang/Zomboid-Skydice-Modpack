require "ISUI/ISPanel"

PJCK_InputSwitch_Panel = ISPanel:derive("PJCK_InputSwitch_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 位置跟随处理
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Panel:updatePosition()
    if not self.mainPanel then return end
    local ScreenPadding = FONT_HGT_SMALL * 0.2
    local newX = self.mainPanel:getX() + self.mainPanel:getWidth() + ScreenPadding
    local newY = self.mainPanel:getY()

    local screenWidth = getCore():getScreenWidth()
    
    if newX + self.width > screenWidth then
        newX = self.mainPanel:getX() - self.width - ScreenPadding
    end
    
    self:setX(newX)
    self:setY(newY)
end

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Panel:initialise()
    ISPanel.initialise(self)
    self:updatePosition()
end

function PJCK_InputSwitch_Panel:new(x, y, width, height, mainPanel, inputScript)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.mainPanel = mainPanel
    o.logic = mainPanel.HandCraftPanel.logic
    o.player = mainPanel.player
    o.currentInputScript = nil

    o.boxPadding = math.floor(FONT_HGT_SMALL * 0.2)
    o.panelPadding = o.boxPadding * 2
    o.BoxWidth = math.floor(width - o.boxPadding * 2 - FONT_HGT_SMALL * 0.6)
    o.BoxHeight = math.floor(FONT_HGT_SMALL * 2.5)
    o.BoxSpacing = math.floor(FONT_HGT_SMALL * 0.3)

    o.expandedStates = {} -- key: itemIndex, value: boolean
    o.InputscriptItems = {}
    o.savedScrollY = 0

    -- 背景贴图
    o.contentBgTextures = {
        topLeft = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_LT.png"),
        top = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_T.png"),
        topRight = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_RT.png"),
        left = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_M.png"),
        right = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_R.png"),
        bottomLeft = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_LB.png"),
        bottom = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_B.png"),
        bottomRight = getTexture("media/ui/Project_Cook/Panel/MainPanel_InsideBG_RB.png")
    }
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- 创建子元素
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Panel:createChildren()
    local contentHeight = self.height - self.panelPadding*2
    local contentWidth = self.width - self.panelPadding
    
    -- 创建滚动视图用于内容显示
    self.contentScrollView = PJCK_ScrollView:new(
        self.panelPadding, 
        self.panelPadding, 
        contentWidth, 
        contentHeight
    )
    self.contentScrollView:initialise()
    self.contentScrollView:setScrollDirection("vertical")
    self.contentScrollView:setScrollSensitivity(self.BoxHeight + self.BoxSpacing)
    self:addChild(self.contentScrollView)

    self:loadInputscriptItems()
end


-- ----------------------------------------------------------------------------------------------------- --
-- 加载InputScript
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Panel:loadInputscriptItems()
    self.InputscriptItems = {}
    self.savedScrollY = 0
    
    local currentInputScript = self.logic:getManualSelectInputScriptFilter()
    if not currentInputScript then return end
    
    -- 只有当输入脚本真正改变时才清空展开状态
    if self.currentInputScript ~= currentInputScript then
        self.expandedStates = {}
        self.currentInputScript = currentInputScript
    end
    
    local existingItemTypes = {}
    
    self:addAvailableItems(currentInputScript, existingItemTypes)
    self:addPossibleItems(currentInputScript, existingItemTypes)

    self:calculateItemStates()
    self:populate()
end

-- 添加库存中存在的物品
function PJCK_InputSwitch_Panel:addAvailableItems(inputScript, existingItemTypes)
    local inputItemNodes = self.logic:getInputItemNodesForInput(inputScript)
    
    for i = 0, inputItemNodes:size() - 1 do
        local node = inputItemNodes:get(i)
        local scriptItem = node:getScriptItem()
        local nodeItems = node:getItems()

        local AvailableItems = {}
        for j = 0, nodeItems:size() - 1 do
            table.insert(AvailableItems, nodeItems:get(j))
        end

        local InputInfo = {
            scriptItem = scriptItem,
            AvailableItems = AvailableItems,
            Count = nodeItems:size(),
            inInventory = true
        }
        
        table.insert(self.InputscriptItems, InputInfo)
        existingItemTypes[scriptItem:getFullName()] = true
    end
end

-- 添加库存中不存在但可能的物品
function PJCK_InputSwitch_Panel:addPossibleItems(inputScript, existingItemTypes)
    local allPossibleItems = inputScript:getPossibleInputItems()
    
    for i = 0, allPossibleItems:size() - 1 do
        local scriptItem = allPossibleItems:get(i)
        local itemType = scriptItem:getFullName()

        if not existingItemTypes[itemType] then
            local InputInfo = {
                scriptItem = scriptItem,
                inInventory = false
            }
            
            table.insert(self.InputscriptItems, InputInfo)
            existingItemTypes[itemType] = true
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 状态管理
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Panel:isItemExpanded(itemIndex)
    return self.expandedStates[itemIndex] or false
end

function PJCK_InputSwitch_Panel:toggleItemExpanded(itemIndex)

    self.savedScrollY = self.contentScrollView:getYScroll()
    
    local wasExpanded = self:isItemExpanded(itemIndex)
    self.expandedStates[itemIndex] = not wasExpanded

    self:populate()
end

function PJCK_InputSwitch_Panel:calculateItemStates()
    self.itemStates = {}
    
    local currentInputScript = self.logic:getManualSelectInputScriptFilter()
    if not currentInputScript then return end
    
    local inputFilterData = self.logic:getRecipeData():getDataForInputScript(currentInputScript)
    -- 添加这个重要的检查
    if not inputFilterData then return end
    
    local satisfiedItems = self.logic:getSatisfiedInputInventoryItems(currentInputScript)
    
    for i, InputInfo in ipairs(self.InputscriptItems) do
        local itemState = {
            hasSelectedItems = false,
            statusText = getText("IGUI_CraftUI_PossibleItems"),
            expandedItemStates = {}
        }
        
        if InputInfo.inInventory and InputInfo.AvailableItems then
            -- 检查是否有选中的物品
            for j = 0, satisfiedItems:size() - 1 do
                local selectedItem = satisfiedItems:get(j)
                for _, availableItem in ipairs(InputInfo.AvailableItems) do
                    if selectedItem == availableItem then
                        itemState.hasSelectedItems = true
                        break
                    end
                end
                if itemState.hasSelectedItems then break end
            end
            
            -- 计算状态文本
            local hasSelectedByCurrentInput = false
            local hasSelectedByOtherInput = false
            
            for _, item in ipairs(InputInfo.AvailableItems) do
                if self.logic:getRecipeData():containsInputItem(item) then
                    local isAssignedToThisInput = self.logic:getRecipeData():containsInputItem(inputFilterData, item)
                    if isAssignedToThisInput then
                        hasSelectedByCurrentInput = true
                    else
                        hasSelectedByOtherInput = true
                    end
                end
                
                -- 为展开列表计算每个物品的状态
                local expandedItemStatus = "normal"
                if self.logic:getRecipeData():containsInputItem(item) then
                    local isAssignedToThisInput = self.logic:getRecipeData():containsInputItem(inputFilterData, item)
                    expandedItemStatus = isAssignedToThisInput and "selected" or "usedByOther"
                end
                
                itemState.expandedItemStates[item] = expandedItemStatus
            end
            
            -- 设置状态文本
            if hasSelectedByCurrentInput then
                itemState.statusText = getText("IGUI_PJCK_InputItemSelected")
            elseif hasSelectedByOtherInput then
                itemState.statusText = getText("IGUI_CraftUI_AlreadyAssigned")
            else
                itemState.statusText = getText("IGUI_CraftUI_AvailableItems")
            end
        end
        
        self.itemStates[i] = itemState
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 物品选择处理
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Panel:onItemSelected(selectedItem)
    self.savedScrollY = self.contentScrollView:getYScroll()
    
    local currentInputScript = self.logic:getManualSelectInputScriptFilter()
    local inputFilterData = self.logic:getRecipeData():getDataForInputScript(currentInputScript)
    if not inputFilterData then return end

    if self.logic:getRecipeData():containsInputItem(selectedItem) then
        local isAssignedToThisInput = self.logic:getRecipeData():containsInputItem(inputFilterData, selectedItem)
        
        if isAssignedToThisInput then
            -- 如果已被当前输入选择，则取消选择
            self.logic:removeInputItem(selectedItem)
        else
            -- 如果被其他输入使用，先移除再添加到当前输入
            self.logic:removeInputItem(selectedItem)
            self.logic:offerInputItem(selectedItem)
        end
    else
        -- 如果未被使用，直接添加
        self.logic:offerInputItem(selectedItem)
    end

    self:calculateItemStates()
    self:populate()
end

-- ----------------------------------------------------------------------------------------------------- --
-- 列表重建
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Panel:populate()
    self:clearAllScrollChildren()
    
    local currentY = 0

    for i, InputInfo in ipairs(self.InputscriptItems) do
        if i > 1 then
            currentY = currentY + self.BoxSpacing
        end
        
        local InputBox = PJCK_InputSwitch_Box:new(
            0, currentY, self.BoxWidth, self.BoxHeight, 
            InputInfo, self, i
        )
        InputBox:initialise()
        self.contentScrollView:addScrollChild(InputBox)
        currentY = currentY + self.BoxHeight
        
        if self:isItemExpanded(i) then
            local expandedPanel = PJCK_InputSwitch_Expanded:new(0, currentY, self.BoxWidth, InputInfo.AvailableItems, self, i)
            expandedPanel:initialise()
            self.contentScrollView:addScrollChild(expandedPanel)
            
            local expandedHeight = expandedPanel:getHeight()
            currentY = currentY + expandedHeight
        end
    end

    local totalHeight = currentY + self.boxPadding
    self.contentScrollView:setScrollHeight(totalHeight)
    
    local maxScrollY = math.max(0, totalHeight - self.contentScrollView:getHeight())
    local newScrollY = math.min(self.savedScrollY, maxScrollY)
    self.contentScrollView:setYScroll(newScrollY)
end

-- 清理函数
function PJCK_InputSwitch_Panel:clearAllScrollChildren()
    if not self.contentScrollView then return end
    
    for i = #self.contentScrollView.scrollChildren, 1, -1 do
        local child = self.contentScrollView.scrollChildren[i]
        self.contentScrollView:removeScrollChild(child)
    end
end

function PJCK_InputSwitch_Panel:updateBoxVisibility()
    if not self.contentScrollView then return end
    
    local viewportTop = -self.contentScrollView:getYScroll()
    local viewportBottom = viewportTop + self.contentScrollView:getHeight()
    local buffer = self.BoxHeight*3
    
    for _, child in ipairs(self.contentScrollView.scrollChildren) do
        if child.itemInfo then
            local boxTop = child:getY() - self.contentScrollView:getYScroll()
            local boxBottom = boxTop + self.BoxHeight
            local isVisible = not (boxBottom < viewportTop - buffer or boxTop > viewportBottom + buffer)
            child:setVisible(isVisible)
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 事件处理
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Panel:onManualSelectChanged(manualSelectInputs)
    if not manualSelectInputs then
        self:Close()
    else
        self:loadInputscriptItems()
    end
end

function PJCK_InputSwitch_Panel:onShowManualSelectChanged(shouldShow)
    if not shouldShow then
        self:Close()
    end
end

function PJCK_InputSwitch_Panel:onInputsChanged()
    self:calculateItemStates()
    self:populate()
end

function PJCK_InputSwitch_Panel:Close()
    self:setVisible(false)
    self:removeFromUIManager()
    self.mainPanel.InputSwitchPanel = nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_InputSwitch_Panel:prerender()
    -- 绘制主背景
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        0,
        self.width,
        self.height,
        self.contentBgTextures,
        1.0, 0.1, 0.1, 0.1
    )
end

function PJCK_InputSwitch_Panel:render()
    self:updateBoxVisibility()
end

return PJCK_InputSwitch_Panel