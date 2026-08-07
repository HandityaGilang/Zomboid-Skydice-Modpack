require "ISUI/ISPanel"

NC_CraftOutput_Panel = ISPanel:derive("NC_CraftOutput_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Panel:initialise()
    ISPanel.initialise(self)
end

function NC_CraftOutput_Panel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    o.titleHeight = NCConfig.titleHeight
    o.padding = HandCraftPanel.padding

    o.outputItems = {}
    o.itemSpacing = HandCraftPanel.padding
    o.itemMargin = HandCraftPanel.padding
    o.itemSize = math.floor(FONT_HGT_SMALL * 2.5)
    o.TimeIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_Clock.png")
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftOutput_Panel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    self:relayoutScrollView()

    self:setWidth(width)
    self:setHeight(height)
end

function NC_CraftOutput_Panel:relayoutScrollView()
    if self.outputScrollPanel then
        self.outputScrollPanel:setX(2)
        self.outputScrollPanel:setY(self.titleHeight)
        self.outputScrollPanel:setWidth(self.width - 4)
        self.outputScrollPanel:setHeight(self.height - self.titleHeight)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Panel:createChildren()

    local titleTextY = (self.titleHeight - FONT_HGT_SMALL) / 2
    local titleLabel = ISLabel:new(self.padding, titleTextY, FONT_HGT_SMALL, getText("IGUI_CraftingWindow_Creates"), 1, 1, 1, 1, UIFont.Small, true)
    titleLabel:initialise()
    self:addChild(titleLabel)

    self.outputScrollPanel = NIScrollView:new(2, self.titleHeight, self.width-4, self.height - self.titleHeight)
    self.outputScrollPanel:initialise()
    self.outputScrollPanel:setScrollDirection("horizontal")
    self:addChild(self.outputScrollPanel)
    self.outputScrollPanel:setWantKeyEvents(true)
end
-- ----------------------------------------------------------------------------------------------------- --
-- create Output Slot
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Panel:updateOutputItems()
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

function NC_CraftOutput_Panel:createOutputItems(outputs)
    local currentX = self.itemMargin
    
    for i = 0, outputs:size() - 1 do
        local outputScript = outputs:get(i)

        if not outputScript:isAutomationOnly() then
            local outputItem = NC_CraftOutput_Slot:new(currentX, self.padding*2, self.itemSize, self.player, outputScript, self)
            outputItem:initialise()
            
            self.outputScrollPanel:addScrollChild(outputItem)
            table.insert(self.outputItems, outputItem)
            
            currentX = currentX + self.itemSize + self.itemSpacing
        end
    end

    local totalWidth = currentX + self.itemMargin
    self.outputScrollPanel:setScrollWidth(math.max(totalWidth, self.outputScrollPanel:getWidth()))
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Panel:update()
    ISPanel.update(self)
end

function NC_CraftOutput_Panel:onRecipeChanged()
    self:updateOutputItems()
end

function NC_CraftOutput_Panel:onInputsChanged()
    for i = 1, #self.outputItems do
        if self.outputItems[i].updateOutputInfo then
            self.outputItems[i]:updateOutputInfo()
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftOutput_Panel:prerender()
    local contentBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/ContentPanel_BG.png")
    local TitleBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/InnerTitle_BG.png")
    if contentBG and TitleBG then
    contentBG:render(self:getAbsoluteX(), self:getAbsoluteY() + self.titleHeight, self.width, self.height - self.titleHeight, 0.1, 0.1, 0.1, NCConfig.slotPanelBackgroundAlpha)
    TitleBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.titleHeight, 0.2, 0.2, 0.2, NCConfig.titleBackgroundAlpha)
    end
end

function NC_CraftOutput_Panel:render()
    if not self.logic:getRecipe() or not self.player then return end
    local timeText = tostring(round(self.logic:getRecipe():getTime(self.player)/10, 2)) .. "s"
    local textWidth = getTextManager():MeasureStringX(UIFont.Small, timeText)
    
    -- Calculate icon size and position
    local iconSize = math.floor(self.titleHeight * 0.6)
    local totalWidth = textWidth + iconSize + self.padding/2
    local startX = self.width - totalWidth - self.padding
    local iconY = (self.titleHeight - iconSize) / 2
    local textY = (self.titleHeight - FONT_HGT_SMALL) / 2

    self:drawTextureScaled(self.TimeIcon, self.width - self.padding - iconSize, iconY,iconSize,iconSize, 1.0, 1.0, 1.0, 1.0)
    self:drawText(timeText, startX, textY, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
end

return NC_CraftOutput_Panel