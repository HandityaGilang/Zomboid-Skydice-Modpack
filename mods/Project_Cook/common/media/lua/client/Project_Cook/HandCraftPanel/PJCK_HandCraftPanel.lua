require "ISUI/ISPanel"

PJCK_HandCraftPanel = ISPanel:derive("PJCK_HandCraftPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_HandCraftPanel:initialise()
    ISPanel.initialise(self)
end

function PJCK_HandCraftPanel:new(x, y, width, height, MainPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.MainPanel = MainPanel
    o.player = MainPanel.player
    o.selectedRecipe = nil
    o.lastPlayerMovingState = nil
    o.initialized = false
    
    -- 创建 HandcraftLogic 实例
    o.logic = HandcraftLogic.new(o.player, nil, nil)  -- craftBench=nil, isoObject=nil 
    o.logic:setManualSelectInputs(true)
    o.logic:addEventListener("onUpdateRecipeList", o.onLogicUpdateRecipeList, o)
    o.logic:addEventListener("onRecipeChanged", o.onLogicRecipeChanged, o)
    o.logic:addEventListener("onInputsChanged", o.onLogicInputsChanged, o)
    o.logic:addEventListener("onShowManualSelectChanged", o.onShowManualSelectChanged, o)
    o.logic:addEventListener("onRebuildInputItemNodes", o.onRebuildInputItemNodes, o)
    o.logic:addEventListener("onStartCraft", o.onStartCraft, o)
    o.logic:addEventListener("onStopCraft", o.onStopCraft, o)

    o.titleBarTextures = {
        left = getTexture("media/ui/Project_Cook/Panel/TitleBar_Inside_L.png"),
        middle = getTexture("media/ui/Project_Cook/Panel/TitleBar_Inside_M.png"),
        right = getTexture("media/ui/Project_Cook/Panel/TitleBar_Inside_R.png")
    }
    
    o.contentBgTextures = {
        topLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LT.png"),
        top = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_T.png"),
        topRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RT.png"),
        left = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_M.png"),
        right = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_R.png"),
        bottomLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LB.png"),
        bottom = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_B.png"),
        bottomRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RB.png")
    }

    o.contentBgTextures2 = {
        topLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LT2.png"),
        top = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_T2.png"),
        topRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RT2.png"),
        left = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_M.png"),
        right = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_R.png"),
        bottomLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LB.png"),
        bottom = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_B.png"),
        bottomRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RB.png")
    }
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- 创建子面板
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_HandCraftPanel:createChildren()

    self:updateIsoObject()
    self:updateContainers()
    local padding = FONT_HGT_SMALL * 0.4
    
    -- 计算布局尺寸
    local totalWidth = self.width - padding * 3 
    local recipeListWidth = math.floor(totalWidth * 0.4) 
    local rightAreaWidth = totalWidth - recipeListWidth 
    
    
    -- 计算右侧区域的布局
    self.rightAreaX = padding + recipeListWidth + padding
    self.rightAreaHeight = self.height - padding * 2
    
    -- 创建CraftInput面板
    local craftInputHeight = math.floor(self.rightAreaHeight *(5/9))
    self.craftInputPanel = PJCK_CraftInput_Panel:new(
        self.rightAreaX,
        padding,
        rightAreaWidth,
        craftInputHeight,
        self
    )
    self.craftInputPanel:initialise()
    self:addChild(self.craftInputPanel)

    -- 创建RecipeInfo面板
    local recipeInfoHeight = math.floor((self.height - padding * 2) / 6)
    local panelSpacing = padding
    local recipeInfoY = padding + craftInputHeight + panelSpacing
    
    self.recipeInfoPanel = PJCK_RecipeInfoPanel:new(
        self.rightAreaX,
        recipeInfoY,
        rightAreaWidth,
        recipeInfoHeight,
        self
    )
    self.recipeInfoPanel:initialise()
    self:addChild(self.recipeInfoPanel)
    
    -- 创建Output面板
    local outputY = recipeInfoY + recipeInfoHeight + panelSpacing
    local outputHeight = self.rightAreaHeight - (outputY - padding)
    local outputWidth = math.floor(rightAreaWidth * 3 / 5)
    self.craftoutputPanel = PJCK_CraftOutput_Panel:new(
        self.rightAreaX,
        outputY,
        outputWidth,
        outputHeight,
        self
    )
    self.craftoutputPanel:initialise()
    self:addChild(self.craftoutputPanel)
    
    -- 创建CraftAction面板
    local actionX = self.rightAreaX + outputWidth + panelSpacing
    local actionWidth = rightAreaWidth - outputWidth - panelSpacing
    self.craftActionPanel = PJCK_CraftActionPanel:new(
        actionX,
        outputY,
        actionWidth,
        outputHeight,
        self
    )
    self.craftActionPanel:initialise()
    self:addChild(self.craftActionPanel)

    -- 创建左侧配方列表面板
    self.recipeListPanel = PJCK_RecipeList_Panel:new(
        padding,
        padding,
        recipeListWidth,
        self.height - padding * 2,
        self
    )
    self.recipeListPanel:initialise()
    self:addChild(self.recipeListPanel)
end

-- ----------------------------------------------------------------------------------------------------- --
-- 配方相关方法
-- ----------------------------------------------------------------------------------------------------- --

function PJCK_HandCraftPanel:onLogicUpdateRecipeList()
    -- print("onLogicUpdateRecipeList")
    if self.recipeListPanel and self.recipeListPanel.updateRecipeList then
        self.recipeListPanel:updateRecipeList()
    end
end

-- setRecipe()时触发
function PJCK_HandCraftPanel:onLogicRecipeChanged()
    -- 关闭inputswitch面板
    self.logic:setShowManualSelectInputs(false)
    -- 更新容器
    self:updateContainers()
    -- 更新InputPanel
    self.craftInputPanel:onRecipeChanged()
    -- 更新outputPanel
    self.craftoutputPanel:onRecipeChanged()
    -- 更新InfoPanel
    self.recipeInfoPanel:onRecipeChanged()
end

-- offerInputItem(InventoryItem)，removeInputItem(InventoryItem)，autoPopulateInputs()时触发
function PJCK_HandCraftPanel:onLogicInputsChanged()
    
    self.craftInputPanel:onInputsChanged()
    
    self.craftoutputPanel:onInputsChanged()

    self.craftActionPanel:updateCraftAction()

    if self.MainPanel.InputSwitchPanel then
        self.MainPanel.InputSwitchPanel:onInputsChanged()
    end
end

-- 手动触发
function PJCK_HandCraftPanel:onShowManualSelectChanged(shouldShow)
    if shouldShow then
        self.MainPanel:showInputSwitchPanel()
    else
        self.MainPanel:closeInputSwitchPanel()
    end
end

-- setRecipe()，setContainers()，setManualSelectInputScriptFilter()时触发
function PJCK_HandCraftPanel:onRebuildInputItemNodes()
    if self.MainPanel.InputSwitchPanel then
        self.MainPanel.InputSwitchPanel:loadInputscriptItems()
    end

    if self.craftActionPanel then
        self.craftActionPanel:updateCraftAction()
    end
end

-- startCraftAction(KahluaTableImpl)时触发
function PJCK_HandCraftPanel:onStartCraft()
    if self.craftActionPanel then
        self.craftActionPanel:updateCraftAction()
    end
end

-- stopCraftAction()时触发
function PJCK_HandCraftPanel:onStopCraft()
    if self.craftActionPanel then
        self.craftActionPanel:updateCraftAction()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 更新函数
-- ----------------------------------------------------------------------------------------------------- --

function PJCK_HandCraftPanel:updateContainers()
    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    self.logic:setContainers(containers)
end

function PJCK_HandCraftPanel:updateIsoObject()
    local IsoObject = ISEntityUI.FindCraftSurface(self.player, 1)
    self.logic:setIsoObject(IsoObject)
end

function PJCK_HandCraftPanel:needUpdate()
    local currentMovingState = self.player:isPlayerMoving()

    if self.lastPlayerMovingState == true and currentMovingState == false then
        self.lastPlayerMovingState = currentMovingState
        return true
    end

    if self.lastPlayerMovingState ~= currentMovingState then
        self.lastPlayerMovingState = currentMovingState
    end
    
    return false
end


function PJCK_HandCraftPanel:update()
    ISPanel.update(self)

    if self:needUpdate() then
        local newIsoObject = ISEntityUI.FindCraftSurface(self.player, 1)
        local newContainers = ISInventoryPaneContextMenu.getContainers(self.player)
        
        self.logic:setIsoObject(newIsoObject)
        self.logic:setContainers(newContainers)

        if self.recipeListPanel then
            self.logic:sortRecipeList()
        end
        
        if self.recipeInfoPanel then
            self.recipeInfoPanel:onRecipeChanged()
        end

        if self.craftActionPanel then
            self.craftActionPanel:updateCraftAction()
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_HandCraftPanel:prerender()
    -- 绘制主背景
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        0,
        self.width,
        self.height,
        self.MainPanel.InsideBGTextures,
        1.0, 0.15, 0.15, 0.15
    )
end

function PJCK_HandCraftPanel:render()
end

return PJCK_HandCraftPanel