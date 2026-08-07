require "ISUI/ISPanel"

NB_BuildingInput_Panel = ISPanel:derive("NB_BuildingInput_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- Initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInput_Panel:initialise()
    ISPanel.initialise(self)
end

function NB_BuildingInput_Panel:new(x, y, width, height, BuildingInfoPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o:noBackground()
    o.BuildingInfoPanel = BuildingInfoPanel
    o.player = BuildingInfoPanel.player
    o.logic = BuildingInfoPanel.logic

    o.inputItems = {}
    o.padding = BuildingInfoPanel.padding
    o.SlotHeight = math.floor(FONT_HGT_SMALL + o.padding + FONT_HGT_MEDIUM)
    o.SlotWidth = o.SlotHeight * 3
    o.itemsPerRow = 2
    
    return o
end

function NB_BuildingInput_Panel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or self.width)

    local totalItems = #self.inputItems
    local totalRows = math.ceil(totalItems / self.itemsPerRow)
    local height = totalRows * (self.SlotHeight + self.padding) + self.padding

    for i, inputItem in ipairs(self.inputItems) do
        local col = (i - 1) % self.itemsPerRow
        local row = math.floor((i - 1) / self.itemsPerRow)
        
        local x = self.padding + col * (self.SlotWidth + self.padding)
        local y = row * (self.SlotHeight + self.padding)
        
        inputItem:setX(x)
        inputItem:setY(y)
    end

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- CreateChildren
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInput_Panel:createChildren()
    self:updateInputItems()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Input manager
-- ----------------------------------------------------------------------------------------------------- --

function NB_BuildingInput_Panel:updateInputItems()
    self:clearInputItems()

    local recipe = self.logic:getRecipe()
    local inputs = recipe:getInputs()
    
    if inputs and inputs:size() > 0 then
        local allInputScripts = {}
        
        for i = 0, inputs:size() - 1 do
            local inputScript = inputs:get(i)
            table.insert(allInputScripts, inputScript)
        end
        
        self:createInputList(allInputScripts)
    end

    self:calculateLayout()
end

function NB_BuildingInput_Panel:clearInputItems()
    for i = 1, #self.inputItems do
        self:removeChild(self.inputItems[i])
    end
    self.inputItems = {}
end

function NB_BuildingInput_Panel:createInputList(inputScripts)
    for i, inputScript in ipairs(inputScripts) do
        local col = (i - 1) % self.itemsPerRow
        local row = math.floor((i - 1) / self.itemsPerRow)
        
        local x = self.padding + col * (self.SlotWidth + self.padding)
        local y = row * (self.SlotHeight + self.padding)
        
        local inputItem = NB_BuildingInput_Slot:new(x, y, self.SlotWidth, self.SlotHeight, self.player, inputScript, self)
        inputItem:initialise()

        self:addChild(inputItem)
        table.insert(self.inputItems, inputItem)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInput_Panel:onRecipeChanged()
    self:updateInputItems()
end

function NB_BuildingInput_Panel:update()
    ISPanel.update(self)
end


return NB_BuildingInput_Panel