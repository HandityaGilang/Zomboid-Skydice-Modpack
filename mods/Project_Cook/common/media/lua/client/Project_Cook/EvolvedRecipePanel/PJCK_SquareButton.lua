require "ISUI/ISButton"

PJCK_SquareButton = ISButton:derive("PJCK_SquareButton")

-- ----------------------------------------------------------------------------------------------------- --
-- 构造函数与初始化
-- ----------------------------------------------------------------------------------------------------- --

function PJCK_SquareButton:initialise()
    ISButton.initialise(self)
end

function PJCK_SquareButton:new(x, y, size, iconTexture, target, onclick, parameter1, parameter2, parameter3, parameter4)
    local o = ISButton:new(x, y, size, size, "", target, onclick, parameter1, parameter2, parameter3, parameter4)
    setmetatable(o, self)
    self.__index = self

    o.size = size
    o.iconTexture = iconTexture
    o.iconSize = size * 0.8
    o.backgroundColor.a = 0
    o.backgroundColorMouseOver.a = 0
    o.borderColor.a = 0
    o.alpha = 1

    o.buttonBgTexture = getTexture("media/ui/Project_Cook/Button/Baseitem_Button_BG.png")
    o.buttonHoverTexture = getTexture("media/ui/Project_Cook/Button/Baseitem_Button_hover.png")
    o.buttonPressTexture = getTexture("media/ui/Project_Cook/Button/Baseitem_Button_Press.png")
    
    o.bgColor = {r=1, g=1, b=1, a=1}
    o.hoverColor = {r=0.5, g=0.5, b=0.5, a=1}
    o.pressColor = {r=1, g=1, b=1, a=1}
    o.iconColor = {r=1, g=1, b=1, a=1}

    o.render = PJCK_SquareButton.customRender
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- 配置方法
-- ----------------------------------------------------------------------------------------------------- --

-- 设置图标
function PJCK_SquareButton:setIcon(iconTexture)
    self.iconTexture = iconTexture
end

-- 设置图标大小
function PJCK_SquareButton:setIconSize(iconSize)
    self.iconSize = iconSize
end

-- 设置图标大小比例
function PJCK_SquareButton:setIconSizeRatio(ratio)
    self.iconSize = self.size * ratio
end

-- 设置按钮贴图
function PJCK_SquareButton:setButtonTextures(bgTexture, hoverTexture, pressTexture)
    self.buttonBgTexture = bgTexture
    self.buttonHoverTexture = hoverTexture
    self.buttonPressTexture = pressTexture
end

-- 设置透明度
function PJCK_SquareButton:setAlpha(alpha)
    self.alpha = alpha
end

-- 设置背景颜色
function PJCK_SquareButton:setBackgroundColor(r, g, b, a)
    self.bgColor = {r=r, g=g, b=b, a=a}
end

-- 设置悬浮颜色
function PJCK_SquareButton:setHoverColor(r, g, b, a)
    self.hoverColor = {r=r, g=g, b=b, a=a}
end

-- 设置按下颜色
function PJCK_SquareButton:setPressColor(r, g, b, a)
    self.pressColor = {r=r, g=g, b=b, a=a}
end

-- 设置图标颜色
function PJCK_SquareButton:setIconColor(r, g, b, a)
    self.iconColor = {r=r, g=g, b=b, a=a}
end

-- ----------------------------------------------------------------------------------------------------- --
-- 渲染函数
-- ----------------------------------------------------------------------------------------------------- --

function PJCK_SquareButton:customRender()
    local bgTexture = self.buttonBgTexture
    local currentColor = self.bgColor
    
    if self.pressed then
        bgTexture = self.buttonPressTexture or self.buttonBgTexture
        currentColor = self.pressColor
    end
    
    -- 绘制背景
    if bgTexture then
        self:drawTextureScaled(bgTexture, 0, 0, self.width, self.height, 
                              self.alpha * currentColor.a, currentColor.r, currentColor.g, currentColor.b)
    end

    -- 悬浮效果
    if self:isMouseOver() and not self.pressed and self.buttonHoverTexture then
        local hoverColor = self.hoverColor
        self:drawTextureScaled(self.buttonHoverTexture, 0, 0, self.width, self.height, 
                              self.alpha * hoverColor.a, hoverColor.r, hoverColor.g, hoverColor.b)
    end

    -- 绘制图标
    if self.iconTexture then
        local iconX = (self.width - self.iconSize) / 2
        local iconY = (self.height - self.iconSize) / 2
        local iconColor = self.iconColor
        self:drawTextureScaled(self.iconTexture, iconX, iconY, self.iconSize, self.iconSize, 
                              self.alpha * iconColor.a, iconColor.r, iconColor.g, iconColor.b)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- 通用按钮
-- ----------------------------------------------------------------------------------------------------- --
-- 清除按钮
function PJCK_SquareButton.createClearButton(x, y, size, target, onclick)
    local clearIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Remove.png")
    local button = PJCK_SquareButton:new(x, y, size, clearIcon, target, onclick)
    button:setIconSizeRatio(0.8)
    button.render = function(button)
        if button.iconTexture then
            local alpha = button:isMouseOver() and 1.0 or 0.8
            local iconX = (button.width - button.iconSize) / 2
            local iconY = (button.height - button.iconSize) / 2
            button:drawTextureScaled(button.iconTexture, iconX, iconY, button.iconSize, button.iconSize, alpha, 1, 1, 1)
        end
    end
    
    return button
end

-- ----------------------------------------------------------------------------------------------------- --
-- EvoPanel按钮
-- ----------------------------------------------------------------------------------------------------- --

-- 加水按钮
function PJCK_SquareButton.createWaterButton(x, y, size, target, onclick)
    local waterIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Water.png")
    local button = PJCK_SquareButton:new(x, y, size, waterIcon, target, onclick)
    button:setIconSizeRatio(0.9)
    return button
end

-- 倒掉按钮
function PJCK_SquareButton.createEmptyButton(x, y, size, target, onclick)
    local emptyIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Empty.png")
    local button = PJCK_SquareButton:new(x, y, size, emptyIcon, target, onclick)
    button:setIconSizeRatio(0.9)
    return button
end

-- 烹饪按钮
function PJCK_SquareButton.createCookButton(x, y, size, target, onclick)
    local cookIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Cook.png")
    local button = PJCK_SquareButton:new(x, y, size, cookIcon, target, onclick)
    button:setIconSizeRatio(0.9)
    return button
end

-- 设置按钮
function PJCK_SquareButton.createSettingsButton(x, y, size, target, onclick)
    local settingsIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Setting.png")
    local button = PJCK_SquareButton:new(x, y, size, settingsIcon, target, onclick)
    
    local bgTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_BG.png")
    local hoverTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_Hover.png")
    button:setButtonTextures(bgTexture, hoverTexture, bgTexture)
    
    button:setBackgroundColor(0.5, 0.5, 0.5, 0.8)
    button:setHoverColor(0.5, 0.5, 0.5, 0.8)
    button:setPressColor(0.5, 0.5, 0.5, 0.8)
    button:setIconColor(1, 1, 1, 1)
    
    button:setIconSizeRatio(0.8)
    return button
end

-- 关闭按钮
function PJCK_SquareButton.createCloseButton(x, y, size, target, onclick)
    local closeIcon = getTexture("media/ui/Project_Cook/ICON/icon_close.png")
    local button = PJCK_SquareButton:new(x, y, size, closeIcon, target, onclick)
    
    local bgTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_BG.png")
    local hoverTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_Hover.png")
    button:setButtonTextures(bgTexture, hoverTexture, bgTexture)
    
    button:setBackgroundColor(0.5, 0.5, 0.5, 0.8)
    button:setHoverColor(0.5, 0.5, 0.5, 0.8)
    button:setPressColor(0.5, 0.5, 0.5, 0.8)
    button:setIconColor(0.6, 0.6, 0.6, 1)
    
    button:setIconSizeRatio(1)
    return button
end

-- 重命名按钮
function PJCK_SquareButton.createRenameButton(x, y, size, target, onclick)
    local renameIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Rename.png")
    local button = PJCK_SquareButton:new(x, y, size, renameIcon, target, onclick)
    
    local bgTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_BG.png")
    local hoverTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_Hover.png")
    button:setButtonTextures(bgTexture, hoverTexture, bgTexture)
    
    button:setBackgroundColor(0.5, 0.5, 0.5, 0.8)
    button:setHoverColor(0.5, 0.5, 0.5, 0.8)
    button:setPressColor(0.5, 0.5, 0.5, 0.8)
    button:setIconColor(1, 1, 1, 1)
    
    button:setIconSizeRatio(0.8)
    return button
end

-- ----------------------------------------------------------------------------------------------------- --
-- Cooker按钮
-- ----------------------------------------------------------------------------------------------------- --
-- 开关按钮
function PJCK_SquareButton.createOnAndOffButton(x, y, size, target, onclick)
    local button = PJCK_SquareButton:new(x, y, size, nil, target, onclick)

    button.onAndOffTextures = {
        on = getTexture("media/ui/Project_Cook/Button/Stove_ON.png"),
        off = getTexture("media/ui/Project_Cook/Button/Stove_OFF.png"),
        noPower = getTexture("media/ui/Project_Cook/Button/Stove_NoPower.png"),
        onDown = getTexture("media/ui/Project_Cook/Button/Stove_ON_Pressed.png"),
        offDown = getTexture("media/ui/Project_Cook/Button/Stove_OFF_Pressed.png"),
        noPowerDown = getTexture("media/ui/Project_Cook/Button/Stove_NoPower_Pressed.png"),
        hover = getTexture("media/ui/Project_Cook/Button/Baseitem_Button_hover.png")
    }
    button.onAndOffState = "nopower"
    button.isUsable = true
    button.render = function(button)
        local currentTexture
        
        if button.pressed then
            if button.onAndOffState == "on" then
                currentTexture = button.onAndOffTextures.onDown
            elseif button.onAndOffState == "off" then
                currentTexture = button.onAndOffTextures.offDown
            else
                currentTexture = button.onAndOffTextures.noPowerDown
            end
        else
            if button.onAndOffState == "on" then
                currentTexture = button.onAndOffTextures.on
            elseif button.onAndOffState == "off" then
                currentTexture = button.onAndOffTextures.off
            else
                currentTexture = button.onAndOffTextures.noPower
            end
        end

        button:drawTextureScaled(currentTexture, 0, 0, button.width, button.height, 1, 1, 1, 1)

        if button:isMouseOver() and not button.pressed then
            button:drawTextureScaled(button.onAndOffTextures.hover, 0, 0, button.width, button.height, 0.2, 0.8, 0.8, 0.8)
        end
    end

    button.setOnAndOffState = function(button, state)
        button.onAndOffState = state
    end

    button.setUsable = function(button, usable)
        button.isUsable = usable
    end
    
    return button
end

 -- 点燃与扑灭按钮
function PJCK_SquareButton.createFireButton(x, y, size, target, onclick)
    local button = PJCK_SquareButton:new(x, y, size, nil, target, onclick)

    button.onAndOffTextures = {
        on = getTexture("media/ui/Project_Cook/Button/Stove_ON.png"),
        off = getTexture("media/ui/Project_Cook/Button/Stove_OFF.png"),
        onDown = getTexture("media/ui/Project_Cook/Button/Stove_ON_Pressed.png"),
        offDown = getTexture("media/ui/Project_Cook/Button/Stove_OFF_Pressed.png"),
        hover = getTexture("media/ui/Project_Cook/Button/Baseitem_Button_hover.png")
    }
    button.onAndOffState = "off"
    button.render = function(button)
        local currentTexture
        
        if button.pressed then
            if button.onAndOffState == "on" then
                currentTexture = button.onAndOffTextures.onDown
            else
                currentTexture = button.onAndOffTextures.offDown
            end
        else
            if button.onAndOffState == "on" then
                currentTexture = button.onAndOffTextures.on
            else
                currentTexture = button.onAndOffTextures.off
            end
        end

        button:drawTextureScaled(currentTexture, 0, 0, button.width, button.height, 1, 1, 1, 1)

        if button:isMouseOver() and not button.pressed then
            button:drawTextureScaled(button.onAndOffTextures.hover, 0, 0, button.width, button.height, 0.2, 0.8, 0.8, 0.8)
        end
    end

    button.setOnAndOffState = function(button, state)
        button.onAndOffState = state
    end
    
    return button
end

-- 燃料添加按钮
function PJCK_SquareButton.createAddFuelButton(x, y, size, target, onclick)
    local button = PJCK_SquareButton:new(x, y, size, nil, target, onclick)

    button.addFuelTextures = {
        normal = getTexture("media/ui/Project_Cook/Button/Fire_AddFuel.png"),
        pressed = getTexture("media/ui/Project_Cook/Button/Fire_AddFuel_Pressed.png"),
        hover = getTexture("media/ui/Project_Cook/Button/Baseitem_Button_hover.png")
    }
    
    button.render = function(button)
        local currentTexture = button.pressed and button.addFuelTextures.pressed or button.addFuelTextures.normal
        button:drawTextureScaled(currentTexture, 0, 0, button.width, button.height, 1, 1, 1, 1)

        if button:isMouseOver() and not button.pressed then
            button:drawTextureScaled(button.addFuelTextures.hover, 0, 0, button.width, button.height, 0.2, 0.8, 0.8, 0.8)
        end
    end
    
    return button
end

-- 减号按钮
function PJCK_SquareButton.createMinusButton(x, y, size, target, onclick)
    local minusIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Minus.png")
    local button = PJCK_SquareButton:new(x, y, size, minusIcon, target, onclick)
    
    local bgTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_BG.png")
    local hoverTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_Hover.png")
    button:setButtonTextures(bgTexture, hoverTexture, bgTexture)
    
    button:setBackgroundColor(0.4, 0.4, 0.4, 0.8)
    button:setHoverColor(0.6, 0.6, 0.6, 0.8)
    button:setPressColor(0.3, 0.3, 0.3, 0.8)
    button:setIconColor(0.9, 0.9, 0.9, 1)
    
    button:setIconSizeRatio(0.6)
    return button
end

-- 加号按钮
function PJCK_SquareButton.createPlusButton(x, y, size, target, onclick)
    local plusIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Plus.png")
    local button = PJCK_SquareButton:new(x, y, size, plusIcon, target, onclick)
    
    local bgTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_BG.png")
    local hoverTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_Hover.png")
    button:setButtonTextures(bgTexture, hoverTexture, bgTexture)
    
    button:setBackgroundColor(0.4, 0.4, 0.4, 0.8)
    button:setHoverColor(0.6, 0.6, 0.6, 0.8)
    button:setPressColor(0.3, 0.3, 0.3, 0.8)
    button:setIconColor(0.9, 0.9, 0.9, 1)
    
    button:setIconSizeRatio(0.6)
    return button
end

-- ----------------------------------------------------------------------------------------------------- --
-- Handcraft按钮
-- ----------------------------------------------------------------------------------------------------- --

-- 制作按钮
function PJCK_SquareButton.createCraftButton(x, y, size, target, onclick)
    local button = PJCK_SquareButton:new(x, y, size, nil, target, onclick)

    button.craftTextures = {
        canCraft = getTexture("media/ui/Project_Cook/Button/CanCraft.png"),
        cannotCraft = getTexture("media/ui/Project_Cook/Button/CannotCraft.png"),
        canCraftPressed = getTexture("media/ui/Project_Cook/Button/CanCraft_Pressed.png"),
        cannotCraftPressed = getTexture("media/ui/Project_Cook/Button/CannotCraft_Pressed.png"),
        busyCraft = getTexture("media/ui/Project_Cook/Button/BusyCraft.png"),
        hover = getTexture("media/ui/Project_Cook/Button/Baseitem_Button_hover.png")
    }
    button.craftState = "cannot"
    
    button.render = function(button)
        local currentTexture
        
        if button.craftState == "busy" then
            currentTexture = button.craftTextures.busyCraft
        else
            if button.pressed then
                if button.craftState == "can" then
                    currentTexture = button.craftTextures.canCraftPressed
                else
                    currentTexture = button.craftTextures.cannotCraftPressed
                end
            else
                if button.craftState == "can" then
                    currentTexture = button.craftTextures.canCraft
                else
                    currentTexture = button.craftTextures.cannotCraft
                end
            end
        end

        button:drawTextureScaled(currentTexture, 0, 0, button.width, button.height, 1, 1, 1, 1)

        if button:isMouseOver() and not button.pressed and button.craftState ~= "busy" then
            button:drawTextureScaled(button.craftTextures.hover, 0, 0, button.width, button.height, 0.2, 0.8, 0.8, 0.8)
        end
    end

    button.setCraftState = function(button, state)
        button.craftState = state
    end
    
    return button
end

-- 筛选按钮
function PJCK_SquareButton.createCanMakeFilterButton(x, y, size, target, onclick)
    local filterIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Canmake.png")
    local button = PJCK_SquareButton:new(x, y, size, filterIcon, target, onclick)
    
    local bgTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_BG.png")
    local hoverTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_Hover.png")
    button:setButtonTextures(bgTexture, hoverTexture, bgTexture)
    
    -- 初始状态：未激活筛选
    button.isFilterActive = false
    
    -- 设置按钮颜色 - 根据筛选状态改变
    button.updateFilterAppearance = function(button)
        if button.isFilterActive then
            -- 激活状态：绿色调
            button:setBackgroundColor(0.95, 0.5, 0.1, 0.8)
            button:setPressColor(0.95, 0.5, 0.1, 0.8)
        else
            -- 未激活状态：灰色调
            button:setBackgroundColor(0.4, 0.4, 0.4, 0.8)
            button:setHoverColor(0.6, 0.6, 0.6, 0.8)
            button:setPressColor(0.3, 0.3, 0.3, 0.8)
            button:setIconColor(0.9, 0.9, 0.9, 1)
        end
    end
    
    -- 设置筛选状态
    button.setFilterActive = function(button, active)
        button.isFilterActive = active
        button:updateFilterAppearance()
    end
    
    -- 初始化外观
    button:updateFilterAppearance()
    button:setIconSizeRatio(0.8)
    
    return button
end

-- 筛选按钮（显示已知配方）
function PJCK_SquareButton.createKnownFilterButton(x, y, size, target, onclick)
    local filterIcon = getTexture("media/ui/Project_Cook/ICON/Icon_RecipeKnow.png")
    local button = PJCK_SquareButton:new(x, y, size, filterIcon, target, onclick)
    
    local bgTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_BG.png")
    local hoverTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_Hover.png")
    button:setButtonTextures(bgTexture, hoverTexture, bgTexture)
    
    -- 初始状态：未激活筛选
    button.isFilterActive = false
    
    -- 设置按钮颜色 - 根据筛选状态改变
    button.updateFilterAppearance = function(button)
        if button.isFilterActive then
            button:setBackgroundColor(0.95, 0.5, 0.1, 0.8)
            button:setPressColor(0.95, 0.5, 0.1, 0.8)
        else
            button:setBackgroundColor(0.4, 0.4, 0.4, 0.8)
            button:setHoverColor(0.6, 0.6, 0.6, 0.8)
            button:setPressColor(0.3, 0.3, 0.3, 0.8)
            button:setIconColor(0.9, 0.9, 0.9, 1)
        end
    end
    
    -- 设置筛选状态
    button.setFilterActive = function(button, active)
        button.isFilterActive = active
        button:updateFilterAppearance()
    end
    
    -- 初始化外观
    button:updateFilterAppearance()
    button:setIconSizeRatio(0.8)
    
    return button
end

-- 技能筛选按钮（显示满足技能等级的配方）
function PJCK_SquareButton.createSkillFilterButton(x, y, size, target, onclick)
    local filterIcon = getTexture("media/ui/Project_Cook/ICON/Icon_CraftLV.png")
    local button = PJCK_SquareButton:new(x, y, size, filterIcon, target, onclick)
    
    local bgTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_BG.png")
    local hoverTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_Hover.png")
    button:setButtonTextures(bgTexture, hoverTexture, bgTexture)
    
    -- 初始状态：未激活筛选
    button.isFilterActive = false
    
    -- 设置按钮颜色 - 根据筛选状态改变
    button.updateFilterAppearance = function(button)
        if button.isFilterActive then
            -- 激活状态：橙色调
            button:setBackgroundColor(0.8, 0.5, 0.2, 0.8)
            button:setHoverColor(0.9, 0.6, 0.3, 0.8)
            button:setPressColor(0.7, 0.4, 0.1, 0.8)
            button:setIconColor(1, 1, 1, 1)
        else
            -- 未激活状态：灰色调
            button:setBackgroundColor(0.4, 0.4, 0.4, 0.8)
            button:setHoverColor(0.6, 0.6, 0.6, 0.8)
            button:setPressColor(0.3, 0.3, 0.3, 0.8)
            button:setIconColor(0.9, 0.9, 0.9, 1)
        end
    end
    
    -- 设置筛选状态
    button.setFilterActive = function(button, active)
        button.isFilterActive = active
        button:updateFilterAppearance()
    end
    
    -- 初始化外观
    button:updateFilterAppearance()
    button:setIconSizeRatio(0.8)
    
    return button
end

-- 搜索分类按钮
function PJCK_SquareButton.createSearchCategoryButton(x, y, size, target, onclick)
    local filterIcon = getTexture("media/ui/Project_Cook/ICON/Icon_SearchItem.png")
    local button = PJCK_SquareButton:new(x, y, size, filterIcon, target, onclick)
    
    local bgTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_BG.png")
    local hoverTexture = getTexture("media/ui/Project_Cook/Button/CommonButton_Hover.png")
    button:setButtonTextures(bgTexture, hoverTexture, bgTexture)
    
    -- 搜索模式，默认为配方名称搜索
    button.searchMode = "RecipeName"
    
    -- 定义不同搜索模式的颜色
    button.searchModeColors = {
        RecipeName = {
            bg = {r=0.4, g=0.4, b=0.4, a=0.8},
            hover = {r=0.6, g=0.6, b=0.6, a=0.8},
            press = {r=0.3, g=0.3, b=0.3, a=0.8},
            icon = {r=0.9, g=0.9, b=0.9, a=1}
        },
        InputName = {
            bg = {r=0.2, g=0.4, b=0.8, a=0.8},
            hover = {r=0.3, g=0.5, b=0.9, a=0.8},
            press = {r=0.1, g=0.3, b=0.7, a=0.8},
            icon = {r=1, g=1, b=1, a=1}
        },
        OutputName = {
            bg = {r=0.8, g=0.5, b=0.2, a=0.8},
            hover = {r=0.9, g=0.6, b=0.3, a=0.8},
            press = {r=0.7, g=0.4, b=0.1, a=0.8},
            icon = {r=1, g=1, b=1, a=1}
        }
    }
    
    -- 根据搜索模式更新外观
    button.updateFilterAppearance = function(button)
        local colors = button.searchModeColors[button.searchMode] or button.searchModeColors["RecipeName"]
        
        button:setBackgroundColor(colors.bg.r, colors.bg.g, colors.bg.b, colors.bg.a)
        button:setHoverColor(colors.hover.r, colors.hover.g, colors.hover.b, colors.hover.a)
        button:setPressColor(colors.press.r, colors.press.g, colors.press.b, colors.press.a)
        button:setIconColor(colors.icon.r, colors.icon.g, colors.icon.b, colors.icon.a)
    end
    
    -- 设置搜索模式
    button.setSearchMode = function(button, mode)
        button.searchMode = mode or "RecipeName"
        button:updateFilterAppearance()
    end
    
    -- 获取当前搜索模式
    button.getSearchMode = function(button)
        return button.searchMode
    end
    
    -- 初始化外观
    button:updateFilterAppearance()
    button:setIconSizeRatio(0.8)
    
    return button
end


return PJCK_SquareButton