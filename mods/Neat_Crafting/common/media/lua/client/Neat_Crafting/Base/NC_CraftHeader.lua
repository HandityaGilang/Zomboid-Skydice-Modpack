-- TODO:When we can add a Custom Component ,this can be a CustomComponent

NC_CraftHeader = ISTableLayout:derive("NC_CraftHeader")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- Size clamp while dragging (integrated from XP_NC SizeClamp patch)
-- ----------------------------------------------------------------------------------------------------- --

local function clampWindowSizeAndPos(win, factor)
    -- Clamp window size and position to keep it reachable after resolution changes while dragging
    if not win or not getCore then return end

    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    if not sw or not sh then return end

    local w = win.width or (win.getWidth and win:getWidth()) or 0
    local h = win.height or (win.getHeight and win:getHeight()) or 0

    local changed = false
    local targetW, targetH = w, h

    -- Only shrink if the window is larger than the current screen
    if w > sw then
        targetW = math.floor(sw * factor)
        changed = true
    end
    if h > sh then
        targetH = math.floor(sh * factor)
        changed = true
    end

    if changed then
        -- Prefer NC layout recalculation to keep min sizes and internal layout consistent
        if win.calculateLayout then
            win:calculateLayout(targetW, targetH)
        else
            if win.setWidth then win:setWidth(targetW) end
            if win.setHeight then win:setHeight(targetH) end
        end
    end

    -- Clamp position so the window stays on-screen
    local curW = win.width or (win.getWidth and win:getWidth()) or targetW
    local curH = win.height or (win.getHeight and win:getHeight()) or targetH

    local newX = win.x or 0
    local newY = win.y or 0

    if newX < 0 then newX = 0 end
    if newY < 0 then newY = 0 end
    if (newX + curW) > sw then newX = math.max(0, sw - curW) end
    if (newY + curH) > sh then newY = math.max(0, sh - curH) end

    if newX ~= (win.x or 0) or newY ~= (win.y or 0) then
        if win.setX then win:setX(newX) else win.x = newX end
        if win.setY then win:setY(newY) else win.y = newY end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftHeader:initialise()
    ISTableLayout.initialise(self)
end

function NC_CraftHeader:new(x, y, width, height, parentWindow)
    local o = ISTableLayout:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.parentWindow = parentWindow
    o.padding = NCConfig.padding
    o.headerButtonSize = math.floor(FONT_HGT_MEDIUM)
    o.iconSize = math.floor((height * 0.8) / 4) * 4
    o.moveWithMouse = true
    o.moving = false

    -- Load header button icons
    o.CloseIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_Close.png")
    o.DebugIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_Debug.png")

    -- Load min size icon (prefer Neat Crafting icon, fallback to a generic minus icon)
    o.MinSizeIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_MinSize.png")
        or getTexture("media/ui/Neat_Crafting/ICON/Icon_Minus.png")

    return o
end


-- ----------------------------------------------------------------------------------------------------- --
-- create Children
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftHeader:createChildren()
    self:addRowFill(nil)

    local iconColumn = self:addColumn(nil)
    iconColumn.minimumWidth = self.iconSize + self.padding * 2

    local titleWidth = getTextManager():MeasureStringX(UIFont.Medium, self.parentWindow:getWindowTitle())
    local titleColumn = self:addColumn(nil)
    titleColumn.minimumWidth = titleWidth + self.padding * 2

    self:addColumnFill(nil)
    self:addColumnFill(nil)

    -- Reserve width for:
    -- - close button
    -- - min size button (always)
    -- - debug button (optional, entity only)
    local buttonWidth = self.headerButtonSize + self.padding -- close button
    buttonWidth = buttonWidth + self.headerButtonSize + self.padding/2 -- min size button
    if getDebug() and self.parentWindow and self.parentWindow.entity then
        buttonWidth = buttonWidth + self.headerButtonSize + self.padding/2 -- debug button
    end

    local buttonColumn = self:addColumn(nil)
    buttonColumn.minimumWidth = buttonWidth

    if not self.parentWindow.entity or self.parentWindow.entity:getComponent(ComponentType.CraftBench) then
        self:createSearchComponent()
    end
    self:setElement(2, 0, self.searchComponent)

    self:createButtonPanel()
    self:setElement(4, 0, self.buttonPanel)
end


function NC_CraftHeader:createSearchComponent()
    self.searchComponent = NC_SearchBox:new(0,0,200,FONT_HGT_MEDIUM,self)
    self.searchComponent:initialise()
end

function NC_CraftHeader:createButtonPanel()
    -- Base width for close button
    local panelWidth = self.headerButtonSize + self.padding
    -- Add min size button width
    panelWidth = panelWidth + self.headerButtonSize + self.padding/2
    -- Add debug button width if needed
    if getDebug() and self.parentWindow and self.parentWindow.entity then
        panelWidth = panelWidth + self.headerButtonSize + self.padding/2
    end

    self.buttonPanel = ISPanel:new(0, 0, panelWidth, self.height)
    self.buttonPanel:noBackground()
    self.buttonPanel:initialise()

    self:createDebugButtonInPanel()
    self:createXP_NC_MinSizeButtonInPanel()
    self:createCloseButtonInPanel()
end


function NC_CraftHeader:createDebugButtonInPanel()
    if getDebug() and self.parentWindow and self.parentWindow.entity then
        local buttonY = math.floor((self.buttonPanel.height - self.headerButtonSize) / 2)
        
        self.debugButton = NC_SquareButton:new(
            0,
            buttonY,
            self.headerButtonSize,
            self.DebugIcon,
            self,
            function() self:onDebugButtonClick() end
        )
        self.debugButton:initialise()
        self.buttonPanel:addChild(self.debugButton)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Min Size button (integrated from XP_NC patch)
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftHeader:onXP_NC_MinSizeClick()
    -- Resize the parent window to minimum size by asking for a tiny preferred size.
    -- NC_HandcraftWindow:calculateLayout() will clamp to NCConfig.minPanelWidth/windowMinHeight.
    if not self.parentWindow then return end
    if self.parentWindow.calculateLayout then
        self.parentWindow:calculateLayout(1, 1)
    end
end

function NC_CraftHeader:createXP_NC_MinSizeButtonInPanel()
    -- Place this button left of closeButton, and right of debugButton (if present).
    local buttonX = 0
    if getDebug() and self.parentWindow and self.parentWindow.entity and self.debugButton then
        buttonX = self.headerButtonSize + self.padding / 2
    end

    local buttonY = math.floor((self.buttonPanel.height - self.headerButtonSize) / 2)

    self.minSizeButton = NC_SquareButton:new(
        buttonX,
        buttonY,
        self.headerButtonSize,
        self.MinSizeIcon,
        self,
        function() self:onXP_NC_MinSizeClick() end
    )
    self.minSizeButton:initialise()
    self.minSizeButton:setActive(false)

    -- Use translation key if present; otherwise keep a safe English fallback
    local tooltip = nil
    if getTextOrNull then
        tooltip = getTextOrNull("IGUI_XP_NC_SetPanelMinSize_tooltip")
    end
    if not tooltip then
        tooltip = "Set panel to minimum size"
    end
    self.minSizeButton:setTooltip(tooltip)

    self.buttonPanel:addChild(self.minSizeButton)
end


function NC_CraftHeader:createCloseButtonInPanel()
    -- Start at 0, then shift right for each button already placed on the left.
    local buttonX = 0

    if getDebug() and self.parentWindow and self.parentWindow.entity and self.debugButton then
        buttonX = buttonX + self.headerButtonSize + self.padding/2
    end

    if self.minSizeButton then
        buttonX = buttonX + self.headerButtonSize + self.padding/2
    end

    local buttonY = math.floor((self.buttonPanel.height - self.headerButtonSize) / 2)

    self.closeButton = NC_SquareButton:new(
        buttonX,
        buttonY,
        self.headerButtonSize,
        self.CloseIcon,
        self,
        function() self.parentWindow:close() end
    )
    self.closeButton:initialise()
    self.closeButton:setActive(true)
    self.closeButton:setActiveColor(0.8, 0.2, 0.2)
    self.buttonPanel:addChild(self.closeButton)
end


-- ----------------------------------------------------------------------------------------------------- --
-- Mouse function
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftHeader:onMouseDown()
    self.moving = true
    self:setCapture(true)
    return true
end

function NC_CraftHeader:onMouseMove(dx, dy)
    if self.moving and self.parentWindow then
        self.parentWindow:setX(self.parentWindow.x + dx)
        self.parentWindow:setY(self.parentWindow.y + dy)
-- Shrink oversized windows after a resolution change so edges/handles stay reachable
if getCore and self.parentWindow then
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w = self.parentWindow.width or 0
    local h = self.parentWindow.height or 0
    if sw and sh and (w > sw or h > sh) then
        clampWindowSizeAndPos(self.parentWindow, 0.90)
    end
end
        return true
    end
    return false
end

function NC_CraftHeader:onMouseMoveOutside(dx, dy)
    if self.moving and self.parentWindow then
        self.parentWindow:setX(self.parentWindow.x + dx)
        self.parentWindow:setY(self.parentWindow.y + dy)
-- Shrink oversized windows after a resolution change so edges/handles stay reachable
if getCore and self.parentWindow then
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local w = self.parentWindow.width or 0
    local h = self.parentWindow.height or 0
    if sw and sh and (w > sw or h > sh) then
        clampWindowSizeAndPos(self.parentWindow, 0.90)
    end
end
        return true
    end
    return false
end

function NC_CraftHeader:onMouseUp()
    if self.moving then
        self.moving = false
        self:setCapture(false)
        return true
    end
    return false
end

function NC_CraftHeader:onMouseUpOutside()
    if self.moving then
        self.moving = false
        self:setCapture(false)
        return true
    end
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- OnFunction
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftHeader:onSearchChanged(searchString)
    if self.parentWindow and self.parentWindow.onSearchChanged then
        self.parentWindow:onSearchChanged(searchString)
    end
end

function NC_CraftHeader:onDebugButtonClick()
    if self.parentWindow and self.parentWindow.entity then
        ISEntityViewWindow.OnOpenPanel(self.parentWindow.entity)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftHeader:prerender()

    local panelbackground = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/MainTitle_BG.png")
    if panelbackground then
        panelbackground:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.08, 0.08, 0.08, NCConfig.titleBackgroundAlpha)
    end

    self:drawRect(0, self.height - 1, self.width, 2, 1, 0, 0, 0)
end

function NC_CraftHeader:render()
    local iconCell = self:cell(0, 0)
    if iconCell then
        local icon = self.parentWindow:getWindowIcon()
        if icon then
            local iconY = iconCell.y + (iconCell.height - self.iconSize) / 2
            self:drawTextureScaled(icon, iconCell.x + self.padding, iconY, self.iconSize, self.iconSize, 1, 1, 1, 1)
        end
    end

    local titleCell = self:cell(1, 0)
    if titleCell then
        local textY = titleCell.y + (titleCell.height - FONT_HGT_MEDIUM) / 2
        self:drawText(self.parentWindow:getWindowTitle(), titleCell.x + self.padding, textY, 1, 1, 1, 1, UIFont.Medium)
    end
end