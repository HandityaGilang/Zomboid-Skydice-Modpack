require "ISUI/ISPanel"

NC_OutputSwitch_Panel = ISPanel:derive("NC_OutputSwitch_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- Update Position and follow Handcraftpanel
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Panel:updatePosition()
    if not self.HandCraftPanel then return end

    local screenPadding = FONT_HGT_SMALL * 0.2
    local newX = self.HandCraftPanel:getAbsoluteX() + self.HandCraftPanel:getWidth() + screenPadding
    local newY = self.HandCraftPanel:getAbsoluteY()
    local screenWidth = getCore():getScreenWidth()

    if newX + self.width > screenWidth then
        newX = self.HandCraftPanel:getAbsoluteX() - self.width - screenPadding
    end

    self:setX(newX)
    self:setY(newY)
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Panel:initialise()
    ISPanel.initialise(self)
    self:updatePosition()
end

function NC_OutputSwitch_Panel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.HandCraftPanel = HandCraftPanel
    o.logic = HandCraftPanel.logic
    o.player = HandCraftPanel.player
    o.currentOutputScript = nil

    o.boxPadding = math.floor(FONT_HGT_SMALL * 0.2)
    o.panelPadding = o.boxPadding * 2
    o.BoxWidth = math.floor(width - o.boxPadding * 2 - FONT_HGT_SMALL * 0.6)
    o.BoxHeight = math.floor(FONT_HGT_SMALL * 2.5)
    o.BoxSpacing = math.floor(FONT_HGT_SMALL * 0.3)

    o.OutputscriptItems = {}
    o.savedScrollY = 0

    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Panel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth
    local height = _preferredHeight

    self.BoxWidth = math.floor(width - self.boxPadding * 2 - FONT_HGT_SMALL * 0.6)
    if self.contentScrollView then
        local contentHeight = height - self.panelPadding * 2
        local contentWidth = width - self.panelPadding

        self.contentScrollView:setX(self.panelPadding)
        self.contentScrollView:setY(self.panelPadding)
        self.contentScrollView:setWidth(contentWidth)
        self.contentScrollView:setHeight(contentHeight)
        self.contentScrollView:setScrollSensitivity(self.BoxHeight + self.BoxSpacing)
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Panel:createChildren()
    local contentHeight = self.height - self.panelPadding * 2
    local contentWidth = self.width - self.panelPadding

    self.contentScrollView = NIScrollView:new(
        self.panelPadding,
        self.panelPadding,
        contentWidth,
        contentHeight
    )
    self.contentScrollView:initialise()
    self.contentScrollView:setScrollDirection("vertical")
    self.contentScrollView:setScrollSensitivity(self.BoxHeight + self.BoxSpacing)
    self:addChild(self.contentScrollView)

    self:loadOutputscriptItems()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Output helpers
-- ----------------------------------------------------------------------------------------------------- --
local function NC_OutputSwitch_GetFullName(scriptItem)
    if not scriptItem or not scriptItem.getFullName then
        return nil
    end
    return scriptItem:getFullName()
end

function NC_OutputSwitch_Panel:getCurrentOutputFullName(outputScript)
    -- Resolves the currently produced item for mapper-based outputs, then falls back to the first possible item.
    if not outputScript or outputScript:getResourceType() ~= ResourceType.Item then
        return nil
    end

    if self.logic and self.logic.isManualSelectInputs and self.logic:isManualSelectInputs() then
        local outputMapper = outputScript:getOutputMapper()
        if outputMapper then
            local actualOutputItem = outputMapper:getOutputItem(self.logic:getRecipeData(), true)
            local fullName = NC_OutputSwitch_GetFullName(actualOutputItem)
            if fullName then
                return fullName
            end
        end
    end

    local possibleItems = outputScript:getPossibleResultItems()
    if possibleItems and possibleItems:size() > 0 then
        return NC_OutputSwitch_GetFullName(possibleItems:get(0))
    end

    return nil
end

function NC_OutputSwitch_Panel:getOutputAmount(outputScript)
    if not outputScript or outputScript:getResourceType() ~= ResourceType.Item then
        return 1
    end
    return outputScript:getIntAmount() or 1
end

-- ----------------------------------------------------------------------------------------------------- --
-- Load OutputScript
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Panel:loadOutputscriptItems()
    self.OutputscriptItems = {}
    self.savedScrollY = self.contentScrollView and self.contentScrollView:getYScroll() or 0

    local currentOutputScript = self.HandCraftPanel and self.HandCraftPanel:getSelectedOutputScript() or nil
    if not currentOutputScript or currentOutputScript:getResourceType() ~= ResourceType.Item then
        self:populate()
        return
    end

    if self.currentOutputScript ~= currentOutputScript then
        self.currentOutputScript = currentOutputScript
        self.savedScrollY = 0
    end

    local currentOutputFullName = self:getCurrentOutputFullName(currentOutputScript)
    local possibleItems = currentOutputScript:getPossibleResultItems()
    local existingItemTypes = {}
    local amount = self:getOutputAmount(currentOutputScript)

    if possibleItems then
        for i = 0, possibleItems:size() - 1 do
            local scriptItem = possibleItems:get(i)
            local fullName = NC_OutputSwitch_GetFullName(scriptItem)
            if fullName and not existingItemTypes[fullName] then
                table.insert(self.OutputscriptItems, {
                    scriptItem = scriptItem,
                    amount = amount,
                    isCurrentOutput = (fullName == currentOutputFullName)
                })
                existingItemTypes[fullName] = true
            end
        end
    end

    self:populate()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Build or rebuild list
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Panel:populate()
    self:clearAllScrollChildren()
    if not self.contentScrollView then return end

    local currentY = 0
    for i, outputInfo in ipairs(self.OutputscriptItems) do
        if i > 1 then
            currentY = currentY + self.BoxSpacing
        end

        local outputBox = NC_OutputSwitch_Box:new(
            0, currentY, self.BoxWidth, self.BoxHeight,
            outputInfo, self, i
        )
        outputBox:initialise()
        self.contentScrollView:addScrollChild(outputBox)
        currentY = currentY + self.BoxHeight
    end

    local totalHeight = currentY + self.boxPadding
    self.contentScrollView:setScrollHeight(totalHeight)

    local maxScrollY = math.max(0, totalHeight - self.contentScrollView:getHeight())
    local newScrollY = math.min(self.savedScrollY or 0, maxScrollY)
    self.contentScrollView:setYScroll(newScrollY)
end

function NC_OutputSwitch_Panel:clearAllScrollChildren()
    if not self.contentScrollView then return end

    for i = #self.contentScrollView.scrollChildren, 1, -1 do
        local child = self.contentScrollView.scrollChildren[i]
        self.contentScrollView:removeScrollChild(child)
    end
end

function NC_OutputSwitch_Panel:updateBoxVisibility()
    if not self.contentScrollView then return end

    local viewportTop = -self.contentScrollView:getYScroll()
    local viewportBottom = viewportTop + self.contentScrollView:getHeight()
    local buffer = self.BoxHeight * 3

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
-- Base function
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Panel:onOutputsChanged()
    self:loadOutputscriptItems()
end

function NC_OutputSwitch_Panel:Close()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_OutputSwitch_Panel:prerender()
    if self.HandCraftPanel and not self.HandCraftPanel:isReallyVisible() then
        self:Close()
        return
    end

    local panelbackground = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/MainPanelBG_RoundTop.png")
    if panelbackground then
        panelbackground:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, NCConfig.slotPopupBackgroundAlpha)
    end
end

function NC_OutputSwitch_Panel:render()
    self:updatePosition()
    self:updateBoxVisibility()
end

return NC_OutputSwitch_Panel
