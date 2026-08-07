require "ISUI/ISPanel"

PJCK_CookerPanel = ISPanel:derive("PJCK_CookerPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------- --
function PJCK_CookerPanel:initialise()
    ISPanel.initialise(self)
end

function PJCK_CookerPanel:new(x, y, width, height, MainPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.MainPanel = MainPanel
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.player = MainPanel.player
    
    -- 烹饪器相关信息
    o.selectedCooker = nil
    o.CookerType = nil
    o.isPowered = false
    o.hasGasTank = false
    o.fuelAmount = 0

    -- Tracks where items came from when the global container view is used.
    -- This is transient and keyed by the item object, so cooked items can be
    -- returned to their original source container during the same session.
    o.originalContainersByItem = setmetatable({}, { __mode = "k" })
    o.originalContainersByItemId = {}

    -- 标题栏贴图
    o.titleBarTextures = {
        left = getTexture("media/ui/Project_Cook/Panel/TitleBar_Inside_L.png"),
        middle = getTexture("media/ui/Project_Cook/Panel/TitleBar_Inside_M.png"),
        right = getTexture("media/ui/Project_Cook/Panel/TitleBar_Inside_R.png")
    }
    
    -- 内容背景贴图
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
    
    return o
end

-- ----------------------------------------- --
-- 创建子面板
-- ----------------------------------------- --
function PJCK_CookerPanel:createChildren()
    -- 布局计算
    local padding = FONT_HGT_SMALL*0.4
    local cookerSelectHeight = PJCK_CookerPicker.calculateRequiredHeight()
    local bottomAreaY = padding + cookerSelectHeight + padding
    local bottomAreaHeight = self.height - bottomAreaY - padding
    local topAreaWidth = self.width - padding * 2
    
    -- 创建选择烹饪器面板
    local cookerPickerWidth = PJCK_CookerPicker.calculateRequiredWidth()
    self.cookerSelectPanel = PJCK_CookerPicker:new(
        padding,
        padding,
        cookerPickerWidth,
        cookerSelectHeight,
        self
    )
    self.cookerSelectPanel:initialise()
    self:addChild(self.cookerSelectPanel)

    -- 创建烹饪器调整面板
    local adjustmentPanelWidth = topAreaWidth - cookerPickerWidth - padding
    local adjustmentPanelX = padding + cookerPickerWidth + padding
    self.cookerAdjustmentPanel = PJCK_CookerAdjustmentPanel:new(
        adjustmentPanelX,
        padding,
        adjustmentPanelWidth,
        cookerSelectHeight,
        self
    )
    self.cookerAdjustmentPanel:initialise()
    self:addChild(self.cookerAdjustmentPanel)
    
    -- **********下方区域*********** --
    
    -- Inventory 面板
    local inventoryPanelWidth = (topAreaWidth - padding) / 2
    self.inventoryPanel = PJCK_InventoryPanel:new(
        padding,
        bottomAreaY,
        inventoryPanelWidth,
        bottomAreaHeight,
        self
    )
    self.inventoryPanel:initialise()
    self:addChild(self.inventoryPanel)
    
    -- CookerContainer 面板
    local rightPanelX = padding + inventoryPanelWidth + padding
    self.cookerContainerPanel = PJCK_CookerContainerPanel:new(
        rightPanelX,
        bottomAreaY,
        inventoryPanelWidth,
        bottomAreaHeight,
        self
    )
    self.cookerContainerPanel:initialise()
    self:addChild(self.cookerContainerPanel)

    -- If only one cooker is nearby, select it automatically for a smoother workflow.
    if self.cookerSelectPanel and self.cookerSelectPanel.selectSingleAvailableCooker then
        self.cookerSelectPanel:selectSingleAvailableCooker()
    end
end

-- ----------------------------------------- --
-- 烹饪器类型判断
-- ----------------------------------------- --

function PJCK_CookerPanel:onCookerChanged(cooker)
    self:clearSelectedCookerHighlight()

    self.CookerType = self:getCookerType(cooker)
    self:updateCookerStatus()
    self:updateSelectedCookerHighlight()

    -- 更新Cooker Container
    if self.cookerContainerPanel then
        self.cookerContainerPanel:setCooker(cooker)
    end

    -- 更新Cooker Adjustment Panel
    if self.cookerAdjustmentPanel then
        self.cookerAdjustmentPanel:setCooker(cooker)
    end

    -- 更新Inventory Panel
    if self.inventoryPanel then
        self.inventoryPanel:updateContainerButtons()
        self.inventoryPanel:selectDefaultContainer()
        self.inventoryPanel:updateFoodList()
    end
end

function PJCK_CookerPanel:getCookerType(cooker)
    if not cooker then return nil end
    
    local parentObj = cooker:getParent()
    if not parentObj then return nil end
    
    local containerType = cooker:getType()

    if containerType == "stove" or containerType == "microwave" then
        return "STOVE"
    elseif instanceof(parentObj, "IsoBarbecue") then
        if not parentObj:isPropaneBBQ() then
            return "CHARCOAL_BBQ"
        else
            return "PROPANE_BBQ"
        end
    elseif instanceof(parentObj, "IsoFireplace") then
        return "FIREPLACE"
    elseif parentObj:getName() == "Campfire" then
        return "CAMPFIRE"
    end
    
    return nil
end

-- ----------------------------------------- --
-- World highlight helpers
-- ----------------------------------------- --
function PJCK_CookerPanel:getSelectedCookerObject()
    local cooker = self.selectedCooker
    return cooker and cooker:getParent() or nil
end

function PJCK_CookerPanel:clearSelectedCookerHighlight()
    if self.highlightedCookerObject then
        self.highlightedCookerObject:setHighlighted(self.player:getPlayerNum(), false, false)
        self.highlightedCookerObject = nil
    end

    if self.inventoryPanel then
        if self.inventoryPanel.clearHoverContainerHighlight then
            self.inventoryPanel:clearHoverContainerHighlight()
        end
        if self.inventoryPanel.clearSelectedContainerHighlight then
            self.inventoryPanel:clearSelectedContainerHighlight()
        end
    end
end

function PJCK_CookerPanel:updateSelectedCookerHighlight()
    local cookerObj = self:getSelectedCookerObject()
    if not cookerObj then return end

    self.highlightedCookerObject = cookerObj
    cookerObj:setHighlightColor(self.player:getPlayerNum(), getCore():getObjectHighlitedColor())
    cookerObj:setHighlighted(self.player:getPlayerNum(), true, false)
end

-- ----------------------------------------- --
-- 烹饪器状态更新
-- ----------------------------------------- --
function PJCK_CookerPanel:updateCookerStatus()
    if not self.selectedCooker then
        self.CookerType = nil
        self.isPowered = false
        self.hasGasTank = false
        self.fuelAmount = 0
        return
    end
    
    -- STOVE:获取电力
    if self.CookerType == "STOVE" then
        self.isPowered = self.selectedCooker:isPowered()
        self.hasGasTank = false
        self.fuelAmount = 0
    -- 丙烷BBQ:获取是否有燃气罐，燃料量
    elseif self.CookerType == "PROPANE_BBQ" then
        local bbqObj = self.selectedCooker:getParent()
            self.hasGasTank = bbqObj:hasPropaneTank()
            self.fuelAmount = bbqObj:getFuelAmount()
            self.isPowered = false
    else
    -- FIREPLACE, CAMPFIRE, CHARCOAL_BBQ：获取是否已经点燃，燃料量
        self.isPowered = false
        self.hasGasTank = false
        if self.CookerType == "FIREPLACE" or self.CookerType == "CHARCOAL_BBQ" then
            local cookerObj = self.selectedCooker:getParent()
            self.fuelAmount = cookerObj and cookerObj:getFuelAmount() or 0
        elseif self.CookerType == "CAMPFIRE" then
            local cookerObj = self.selectedCooker:getParent()
            local campfire = CCampfireSystem.instance:getLuaObjectOnSquare(cookerObj:getSquare())
            self.fuelAmount = campfire and campfire.fuelAmt or 0
        else
            self.fuelAmount = 0
        end
    end
end

-- ----------------------------------------- --
-- 获取烹饪器信息的便捷方法
-- ----------------------------------------- --

-- 检查烹饪器是否点燃

function PJCK_CookerPanel:getItemContainerKey(item)
    if not item then return nil end

    -- Prefer the vanilla item ID because the Lua userdata wrapper can change
    -- after transfers or state updates while the item itself stays the same.
    if item.getID then
        local ok, itemId = pcall(function() return item:getID() end)
        if ok and itemId ~= nil then
            return tostring(itemId)
        end
    end

    return nil
end

function PJCK_CookerPanel:isContainerReferenceValid(container)
    if not container then return false end

    local ok = pcall(function()
        return container:getItems()
    end)

    return ok
end

function PJCK_CookerPanel:rememberOriginalContainer(item, container)
    if not item or not container then return end

    if not self.originalContainersByItem then
        self.originalContainersByItem = setmetatable({}, { __mode = "k" })
    end
    if not self.originalContainersByItemId then
        self.originalContainersByItemId = {}
    end

    self.originalContainersByItem[item] = container

    local key = self:getItemContainerKey(item)
    if key then
        self.originalContainersByItemId[key] = container
    end
end

function PJCK_CookerPanel:getOriginalContainer(item)
    if not item then return nil end

    local container = nil
    if self.originalContainersByItem then
        container = self.originalContainersByItem[item]
    end

    if not container then
        local key = self:getItemContainerKey(item)
        if key and self.originalContainersByItemId then
            container = self.originalContainersByItemId[key]
        end
    end

    if not self:isContainerReferenceValid(container) then
        self:clearOriginalContainer(item)
        return nil
    end

    return container
end

function PJCK_CookerPanel:clearOriginalContainer(item)
    if not item then return end

    if self.originalContainersByItem then
        self.originalContainersByItem[item] = nil
    end

    local key = self:getItemContainerKey(item)
    if key and self.originalContainersByItemId then
        self.originalContainersByItemId[key] = nil
    end
end

function PJCK_CookerPanel:isCookerLit()
    if not self.selectedCooker then return false end
    
    if self.CookerType == "STOVE" then
        return self.selectedCooker:getParent():Activated()
    elseif self.CookerType == "PROPANE_BBQ" then
        return self.selectedCooker:getParent():isLit()
    elseif self.CookerType == "FIREPLACE" or self.CookerType == "CHARCOAL_BBQ" then
        local cookerObj = self.selectedCooker:getParent()
        return cookerObj and cookerObj:isLit()
    elseif self.CookerType == "CAMPFIRE" then
        local cookerObj = self.selectedCooker:getParent()
        local campfire = CCampfireSystem.instance:getLuaObjectOnSquare(cookerObj:getSquare())
        return campfire and campfire.isLit == true
    end
    
    return false
end

-- ----------------------------------------- --
-- 更新函数
-- ----------------------------------------- --
function PJCK_CookerPanel:update()
    ISPanel.update(self)
    
    -- 更新烹饪器状态
    self:updateCookerStatus()
end

-- ----------------------------------------- --
-- 渲染函数
-- ----------------------------------------- --
function PJCK_CookerPanel:prerender()
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

return PJCK_CookerPanel