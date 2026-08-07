require "ISUI/ISPanel"

NC_CraftInput_Panel = ISPanel:derive("NC_CraftInput_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- Initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftInput_Panel:initialise()
    ISPanel.initialise(self)
end

function NC_CraftInput_Panel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic

    o.inputItems = {}
    o.padding = HandCraftPanel.padding
    o.SlotHeight = HandCraftPanel.inputSlotHeight
    o.SlotWidth = o.SlotHeight * 3
    o.titleHeight = HandCraftPanel.titleHeight
    o.scrollViewSpacing = HandCraftPanel.scrollViewSpacing
    
    return o
end

function NC_CraftInput_Panel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    local contentHeight = height - self.titleHeight - self.scrollViewSpacing * 2
    self.ScrollView:setWidth(width)
    self.ScrollView:setHeight(contentHeight)

    if #self.inputItems == 0 then
        self.ScrollView:setScrollHeight(self.ScrollView:getHeight())
        return
    end

    local itemsPerRow = 2
    local totalItems = #self.inputItems
    local totalRows = math.ceil(totalItems / itemsPerRow)
    local totalHeight = self.padding * 2 + totalRows * (self.SlotHeight + self.padding) - self.padding
    self.ScrollView:setScrollHeight(math.max(totalHeight, self.ScrollView:getHeight()))

    self:setWidth(width)
    self:setHeight(height)
end


-- ----------------------------------------------------------------------------------------------------- --
-- CreateChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftInput_Panel:createChildren()
    local titleTextpadding = FONT_HGT_SMALL * 0.4
    local titleTextY = (self.titleHeight - FONT_HGT_SMALL) / 2
    local titleLabel = ISLabel:new(titleTextpadding, titleTextY, FONT_HGT_SMALL, getText("IGUI_CraftingWindow_Requires"), 1, 1, 1, 1, UIFont.Small, true)
    titleLabel:initialise()
    self:addChild(titleLabel)
    
    local contentStartY = self.titleHeight
    local contentHeight = self.height - contentStartY - self.scrollViewSpacing * 2
    self.ScrollView = NIScrollView:new(0, contentStartY + self.scrollViewSpacing, self.width, contentHeight)
    self.ScrollView:initialise()
    self.ScrollView:setScrollDirection("vertical")
    self:addChild(self.ScrollView)
    self.ScrollView:setWantKeyEvents(true)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Input item management
-- ----------------------------------------------------------------------------------------------------- --

-- Update input items
function NC_CraftInput_Panel:updateInputItems()
    self:clearInputItems()
    if not self.logic:getRecipe() then return end

    local recipe = self.logic:getRecipe()
    local inputs = recipe:getInputs()
    
    if inputs and inputs:size() > 0 then
        self:createInputItems(inputs)
    end
end

-- Clear existing input items
function NC_CraftInput_Panel:clearInputItems()
    for i = 1, #self.inputItems do
        self.ScrollView:removeScrollChild(self.inputItems[i])
    end
    self.inputItems = {}
end

-- Create input item entry
function NC_CraftInput_Panel:createInputItems(inputs)
    local ReturnInputList = {}
    local RegularInputList = {}
    
    self.logic:autoPopulateInputs()

    for i = 0, inputs:size() - 1 do
        local inputScript = inputs:get(i)
        
        -- Prefer items that will be kept
        if not inputScript:isAutomationOnly() then
            if inputScript:isKeep() then
                table.insert(ReturnInputList, inputScript)
            else
                table.insert(RegularInputList, inputScript)
            end
        end
    end
    
    local allInputs = {}
    for _, inputScript in ipairs(ReturnInputList) do
        table.insert(allInputs, inputScript)
    end
    for _, inputScript in ipairs(RegularInputList) do
        table.insert(allInputs, inputScript)
    end

    self:createInputList(allInputs)
end

-- Create input list
function NC_CraftInput_Panel:createInputList(allInputs)
    local currentRow = 0
    local itemsPerRow = 2
    
    for i, inputScript in ipairs(allInputs) do
        local col = (i - 1) % itemsPerRow
        local row = math.floor((i - 1) / itemsPerRow)
        
        -- Calculate position
        local x = self.padding + col * (self.SlotWidth + self.padding)
        local y = self.padding + row * (self.SlotHeight + self.padding)
        
        local inputItem = NC_CraftInput_Slot:new(x, y, self.SlotWidth,self.SlotHeight, self.player, inputScript, self)
        inputItem:initialise()
        self.ScrollView:addScrollChild(inputItem)
        table.insert(self.inputItems, inputItem)
        currentRow = row
    end

    local totalRows = currentRow + 1
    local totalHeight = self.padding * 2 + totalRows * (self.SlotHeight + self.padding) - self.padding
    self.ScrollView:setScrollHeight(math.max(totalHeight, self.ScrollView:getHeight()))
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftInput_Panel:onRecipeChanged()
    self:updateInputItems()
end

function NC_CraftInput_Panel:onInputsChanged()
    for i = 1, #self.inputItems do
        if self.inputItems[i].updateInputInfo then
            self.inputItems[i]:updateInputInfo()
        end
    end
end

function NC_CraftInput_Panel:update()
    ISPanel.update(self)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftInput_Panel:prerender()
    local contentBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/ContentPanel_BG.png")
    local TitleBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/InnerTitle_BG.png")
    if contentBG and TitleBG then
        contentBG:render(self:getAbsoluteX(), self:getAbsoluteY() + self.titleHeight, self.width, self.height - self.titleHeight, 0.1, 0.1, 0.1, NCConfig.slotPanelBackgroundAlpha)
        TitleBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.titleHeight, 0.2, 0.2, 0.2, NCConfig.titleBackgroundAlpha)
    end
end

function NC_CraftInput_Panel:render()

end

return NC_CraftInput_Panel