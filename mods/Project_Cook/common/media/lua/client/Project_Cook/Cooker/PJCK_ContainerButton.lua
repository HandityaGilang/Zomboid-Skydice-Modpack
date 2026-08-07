require "ISUI/ISUIElement"

PJCK_ContainerButton = ISUIElement:derive("PJCK_ContainerButton")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_ContainerButton:initialise()
    ISUIElement.initialise(self)
end

function PJCK_ContainerButton:new(x, y, width, height, container, displayName, texture, parentPanel, isAllContainers)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.container = container
    o.displayName = displayName
    o.texture = texture
    o.parentPanel = parentPanel
    o.isSelected = false
    o.isAllContainers = isAllContainers == true
    
    -- 加载按钮背景贴图
    o.buttonTextures = {
        background = getTexture("media/ui/Project_Cook/Slot/ContainerBtn_BG.png"),
        backgroundHover = getTexture("media/ui/Project_Cook/Slot/ContainerBtn_Hover.png"),
        Selected = getTexture("media/ui/Project_Cook/Slot/ContainerBtn_Selected.png"),
    }
    
    return o
end

-- ---------------------------------------------------------- --
-- 选择状态管理
-- ---------------------------------------------------------- --

function PJCK_ContainerButton:setSelected(selected)
    self.isSelected = selected
end

function PJCK_ContainerButton:getSelected()
    return self.isSelected
end

function PJCK_ContainerButton:getContainer()
    return self.container
end

function PJCK_ContainerButton:isAllContainersButton()
    return self.isAllContainers == true
end

-- ---------------------------------------------------------- --
-- 鼠标交互
-- ---------------------------------------------------------- --

function PJCK_ContainerButton:onMouseMove(dx, dy)
    if self.parentPanel and self.parentPanel.applyHoverContainerHighlight and not self:isAllContainersButton() then
        self.parentPanel:applyHoverContainerHighlight(self.container)
    end
    return true
end

function PJCK_ContainerButton:onMouseMoveOutside(dx, dy)
    if self.parentPanel and self.parentPanel.clearHoverContainerHighlight and not self:isAllContainersButton() then
        self.parentPanel:clearHoverContainerHighlight(self.container)
    end
    return true
end

function PJCK_ContainerButton:onMouseDown(x, y)
    -- 点击容器按钮时的处理逻辑
    self:onContainerButtonClick()
    return true
end

function PJCK_ContainerButton:onMouseUp(x, y)
    return true
end

function PJCK_ContainerButton:onContainerButtonClick()
    -- 通知父面板容器被点击
    if self.parentPanel and self.parentPanel.onContainerButtonClick then
        self.parentPanel:onContainerButtonClick(self)
    end
end

-- ---------------------------------------------------------- --
-- 渲染函数
-- ---------------------------------------------------------- --

function PJCK_ContainerButton:prerender()
    -- Keep the world outline in sync from prerender too. Some scroll-view
    -- layouts can show the visual hover state without reliably firing
    -- onMouseMove/onMouseMoveOutside every frame.
    if not self:isAllContainersButton() and self.parentPanel then
        if self:isMouseOver() and self.parentPanel.applyHoverContainerHighlight then
            self.parentPanel:applyHoverContainerHighlight(self.container)
        elseif self.parentPanel.clearHoverContainerHighlight then
            self.parentPanel:clearHoverContainerHighlight(self.container)
        end
    end

    -- 绘制背景
    self:drawTextureScaled(self.buttonTextures.background, 0, 0, self.width, self.height, 0.8, 0.8, 0.8, 0.8)

    -- 选中状态效果
    if self.isSelected then
        self:drawTextureScaled(self.buttonTextures.Selected, 0, 0, self.width, self.height, 0.8, 0.8, 0.8, 0.8)
    end
    if self:isMouseOver() then
        -- 悬浮效果
        self:drawTextureScaled(self.buttonTextures.backgroundHover, 0, 0, self.width, self.height, 0.5, 0.5, 0.5, 0.5)
    end
end

function PJCK_ContainerButton:render()
    local iconSize = FONT_HGT_MEDIUM
    local iconMargin = (self.height - iconSize) / 2
    local textX = iconMargin + iconSize + FONT_HGT_SMALL / 3
    
    -- 绘制容器图标
    if self.texture then
        self:drawTextureScaledAspect(self.texture, iconMargin, iconMargin, iconSize, iconSize, 1, 1, 1, 1)
    end
    
    -- 绘制容器名称
    local textY = (self.height - FONT_HGT_SMALL) / 2
    local availableWidth = self.width - textX - iconMargin
    if availableWidth > FONT_HGT_SMALL then
        local displayText = self:shortenText(self.displayName, availableWidth, UIFont.Small)
        
        local textColor = self.isSelected and {r=1, g=1, b=1, a=1} or {r=0.8, g=0.8, b=0.8, a=1}
        
        PJCK_UIHelper.renderText(self, displayText, textX, textY, FONT_HGT_SMALL, 1.0, 
                                    textColor.r, textColor.g, textColor.b, false)
    end
end

-- ---------------------------------------------------------- --
-- 辅助方法
-- ---------------------------------------------------------- --

function PJCK_ContainerButton:shortenText(text, maxWidth, font)
    local textWidth = getTextManager():MeasureStringX(font, text)
    if textWidth <= maxWidth then
        return text
    end
    
    local ellipsis = "..."
    local ellipsisWidth = getTextManager():MeasureStringX(font, ellipsis)
    local availableWidth = maxWidth - ellipsisWidth

    local shortenedText = ""
    for i = 1, string.len(text) do
        local testText = string.sub(text, 1, i)
        local testWidth = getTextManager():MeasureStringX(font, testText)
        
        if testWidth <= availableWidth then
            shortenedText = testText
        else
            break
        end
    end

    return shortenedText .. ellipsis
end

return PJCK_ContainerButton