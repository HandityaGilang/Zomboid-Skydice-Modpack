require "ISUI/ISUIElement"

PJCK_CookerSlot = ISUIElement:derive("PJCK_CookerSlot")

-- ---------------------------------------------------------- --
-- 初始化与构造函数
-- ---------------------------------------------------------- --

function PJCK_CookerSlot:initialise()
    ISUIElement.initialise(self)
end

function PJCK_CookerSlot:new(x, y, size, parentPanel)
    local o = ISUIElement:new(x, y, size, size)
    setmetatable(o, self)
    self.__index = self
    
    o.size = size
    o.iconSize = size*0.9
    o.parentPanel = parentPanel
    
    o.slotTextures = {
        background = getTexture("media/ui/Project_Cook/Slot/Background.png"),
        backgroundHover = getTexture("media/ui/Project_Cook/Slot/Hover.png"),
        border = getTexture("media/ui/Project_Cook/Slot/Boarder.png"),
    }
    
    o.addIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_Add.png")
    o.durabilityTexture_10 = getTexture("media/ui/Project_Cook/Slot/Durability_10.png")
    o.durabilityTexture = getTexture("media/ui/Project_Cook/Slot/Durability_RoundBottom.png")
    o.poweredIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_Powered.png")
    o.gasTankIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_GasTank.png")
    o.fireIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_Cookable.png")
    
    return o
end

-- ---------------------------------------------------------- --
-- 动作检测函数
-- ---------------------------------------------------------- --

-- 获取当前正在执行的动作信息
function PJCK_CookerSlot:getCurrentAction()
    local player = self.parentPanel.player
    if not player then return nil, 0 end
    
    local queue = ISTimedActionQueue.getTimedActionQueue(player)
    if not queue or not queue.current then return nil, 0 end
    
    local currentAction = queue.current
    local progress = currentAction:getJobDelta() or 0
    
    return currentAction, progress
end

-- 检测烹饪设备相关动作
function PJCK_CookerSlot:isCookerAction(cooker)
    if not cooker then return false, 0 end
    
    local currentAction, progress = self:getCurrentAction()
    if not currentAction then return false, 0 end
    
    -- 获取动作类型名称
    local actionType = currentAction.Type or ""
    local actionClass = getmetatable(currentAction).__index
    local className = ""
    if actionClass and actionClass.Type then
        className = actionClass.Type
    end
    
    -- 检测各种烹饪设备相关的动作
    local cookerActions = {
        -- 营火相关
        "ISAddFuelAction",
        "ISLightFromKindle", 
        "ISLightFromLiterature",
        "ISLightFromPetrol",
        "ISPutOutCampfireAction",
        
        -- 壁炉相关
        "ISFireplaceLightFromKindle",
        "ISFireplaceLightFromLiterature", 
        "ISFireplaceLightFromPetrol",
        "ISFireplaceAddFuel",
        "ISFireplaceExtinguish",
        
        -- BBQ相关
        "ISBBQLightFromKindle",
        "ISBBQLightFromLiterature",
        "ISBBQLightFromPetrol", 
        "ISBBQAddFuel",
        "ISBBQExtinguish",
        "ISBBQToggle",
        "ISBBQInsertPropaneTank",
        "ISBBQRemovePropaneTank"
    }
    
    -- 检查类名或类型名是否匹配
    for _, actionName in ipairs(cookerActions) do
        if actionType == actionName or className == actionName then
            return true, progress
        end
    end
    
    return false, 0
end

-- ---------------------------------------------------------- --
-- 鼠标交互函数
-- ---------------------------------------------------------- --

function PJCK_CookerSlot:onMouseMove(dx, dy)
    return true
end

function PJCK_CookerSlot:onMouseMoveOutside(dx, dy)
    return true
end

function PJCK_CookerSlot:onMouseDown(x, y)
    return true
end

function PJCK_CookerSlot:onMouseUp(x, y)
    return true
end

-- ---------------------------------------------------------- --
-- 渲染函数
-- ---------------------------------------------------------- --

function PJCK_CookerSlot:prerender()
    -- 绘制背景
    self:drawTextureScaled(self.slotTextures.background, 0, 0, self.width, self.height, 0.8, 0.4, 0.4, 0.4)
    -- 绘制边框
    self:drawTextureScaled(self.slotTextures.border, 0, 0, self.width, self.height, 0.8, 0.4, 0.4, 0.4)
    -- 悬浮效果
    if self:isMouseOver() then
        self:drawTextureScaled(self.slotTextures.backgroundHover, 0, 0, self.width, self.height, 0.5, 0.5, 0.5, 0.5)
    end
end

function PJCK_CookerSlot:render()
    local cooker = self.parentPanel.CookerPanel.selectedCooker

    if cooker then
        local hasCookerAction, actionProgress = self:isCookerAction(cooker)
        
        -- 绘制动作进度条
        if hasCookerAction and actionProgress > 0 then
            local fillWidth = math.floor(self.width * actionProgress)
            if fillWidth > 0 then
                self:setStencilRect(0, 0, fillWidth, self.height)
                self:drawTextureScaled(self.durabilityTexture, 0, 0, self.width, self.height, 0.8, 0.4, 0.4, 0.4)
                self:clearStencilRect()
            end
        end
        
        -- 绘制图标
        self:drawCookerIcon(cooker)
        
        -- Draw the powered icon in the upper-left corner when electricity is available.
        local isPowered = self.parentPanel.CookerPanel.isPowered
        if isPowered and self.poweredIconTexture then
            local powerIconSize = math.floor(self.width / 4)
            local margin = math.floor(self.width / 16)
            self:drawTextureScaled(self.poweredIconTexture, margin, margin, powerIconSize, powerIconSize, 1.0, 1, 1, 1)
        end

        -- Draw the lit/cooking icon in the upper-right corner for every cooker type.
        if self.parentPanel.CookerPanel:isCookerLit() and self.fireIconTexture then
            local fireIconSize = math.floor(self.width / 4)
            local margin = math.floor(self.width / 16)
            local iconX = self.width - fireIconSize - margin
            self:drawTextureScaled(self.fireIconTexture, iconX, margin, fireIconSize, fireIconSize, 1.0, 1, 1, 1)
        end
    else
        -- 绘制添加图标
        if self.addIconTexture then
            local AddIconSize = math.floor(self.size / 3)
            local iconX = (self.width - AddIconSize) / 2
            local iconY = (self.height - AddIconSize) / 2

            self:drawTextureScaled(self.addIconTexture, iconX, iconY, AddIconSize, AddIconSize, 0.6, 0.7, 0.7, 0.7)
        end
    end
end

-- 绘制烹饪设备图标
function PJCK_CookerSlot:drawCookerIcon(cooker)
    if not cooker then return end
    
    local parentObj = cooker:getParent()
    if not parentObj then return end
    
    -- 根据对象类型获取纹理名称
    local textureName
    if parentObj:getName() == "Campfire" then
        textureName = parentObj:getSpriteName()
    else
        textureName = parentObj:getTextureName()
    end
    
    local iconTexture = textureName and getTexture(textureName) or nil
    if not iconTexture then return end
    
    -- 获取纹理尺寸
    local textureWidth = iconTexture:getWidth()
    local textureHeight = iconTexture:getHeight()
    local targetSize = self.iconSize
    
    -- 计算缩放比例
    local scaleX = targetSize / textureWidth
    local scaleY = targetSize / textureHeight
    local scale = math.min(scaleX, scaleY) 
    
    -- 计算实际绘制尺寸与位置
    local drawWidth = textureWidth * scale
    local drawHeight = textureHeight * scale
    local iconX = (self.width - drawWidth) / 2
    local iconY = (self.height - drawHeight) / 2

    self:drawTextureScaled(iconTexture, iconX, iconY, drawWidth, drawHeight, 1, 1, 1, 1)
end

return PJCK_CookerSlot