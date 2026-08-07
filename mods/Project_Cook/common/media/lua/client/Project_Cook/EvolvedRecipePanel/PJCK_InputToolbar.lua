require "ISUI/ISPanel"

PJCK_InputToolbar = ISPanel:derive("PJCK_InputToolbar")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------- --
function PJCK_InputToolbar:initialise()
    ISPanel.initialise(self)
end

function PJCK_InputToolbar:new(x, y, width, height, parentPanel, EvoPanel, panelType, slotSize)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.parentPanel = parentPanel
    o.EvoPanel = EvoPanel
    o.panelType = panelType  -- "Ingredient" or "Seasoning"
    o.player = EvoPanel.player
    o.padding = EvoPanel.padding

    o.buttonSize = slotSize
    o.buttonSpacing = o.padding

    o.slotTex = {
        bg = getTexture("media/ui/NeatUI/Button/Background.png"),
        border = getTexture("media/ui/NeatUI/Button/Boarder.png"),
    }
    
    o.randomIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Dice.png")
    o.showAllIcon = getTexture("media/ui/Project_Cook/ICON/Icon_ShowAll.png")
    o.showCanUseIcon = getTexture("media/ui/Project_Cook/ICON/Icon_ShowCanUse.png")
    o.sortIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Sort.png")
    o.infiniteIcon = getTexture("media/ui/NeatUI/numbers_outline/Infinite.png")
    
    return o
end

function PJCK_InputToolbar:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    -- Minimum size calculation
    local minWidth = self.buttonSize + self.padding * 2
    local minHeight = self.buttonSize * 4 + self.buttonSpacing * 3 + self.padding * 2

    width = math.max(width, minWidth)
    height = math.max(height, minHeight)

    self:relayoutChildren(width, height)

    self:setWidth(width)
    self:setHeight(height)
end

function PJCK_InputToolbar:relayoutChildren(width, height)
    local buttonX = (width - self.buttonSize) / 2
    local countTextHeigt = height - self.padding * 5 -self.buttonSize * 3
    local currentY = self.padding*2 + countTextHeigt

    if self.randomButton then
        self.randomButton:setX(buttonX)
        self.randomButton:setY(currentY)
        currentY = currentY + self.buttonSize + self.buttonSpacing
    end

    if self.showPossibleButton then
        self.showPossibleButton:setX(buttonX)
        self.showPossibleButton:setY(currentY)
        currentY = currentY + self.buttonSize + self.buttonSpacing
    end

    if self.sortButton then
        self.sortButton:setX(buttonX)
        self.sortButton:setY(currentY)
    end
end

-- ---------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------- --
function PJCK_InputToolbar:createChildren()
    -- Random Button
    self.randomButton = ISButton:new(0, 0, self.buttonSize, self.buttonSize, "", self, self.onRandomAdd)
    self.randomButton:initialise()
    self.randomButton.displayBackground = false
    self.randomButton.tooltip = getText("IGUI_PJCK_RandomAdd")
    self.randomButton.icon = self.randomIcon
    self.randomButton.render = function(btn)
        local alpha = btn:isMouseOver() and 1 or 0.8
        local iconSize = math.floor(btn.width * 0.8)
        local iconOffset = (btn.width - iconSize) / 2
        local color = {r=0.8 ,g=0.8 ,b =0.8}
        if not self.EvoPanel:canQueueIngredients() then
            color = {r=1 ,g=0.6 ,b =0.6}
            alpha = 0.4
        end

        btn:drawTextureScaled(btn.icon, iconOffset, iconOffset, iconSize, iconSize, alpha, color.r, color.g, color.b)
    end
    self:addChild(self.randomButton)
    
    -- show Possible Button
    self.showPossibleButton = ISButton:new(0, 0, self.buttonSize, self.buttonSize, "", self, self.onShowPossible)
    self.showPossibleButton:initialise()
    self.showPossibleButton.displayBackground = false
    self.showPossibleButton.tooltip = getText("IGUI_PJCK_ShowPossible")
    self.showPossibleButton.icon = self.showCanUseIcon
    self.showPossibleButton.render = function(btn)
        local alpha = btn:isMouseOver() and 1 or 0.8
        local iconSize = math.floor(btn.width * 0.8)
        local iconOffset = (btn.width - iconSize) / 2
        local color = {r=0.8 ,g=0.8 ,b =0.8}

        local icon = self.showAllIcon

        if not self.EvoPanel:getBaseItem() and not self.EvoPanel:getRecipe() then
            color = {r=1 ,g=0.6 ,b =0.6}
            alpha = 0.4
            icon = self.showCanUseIcon
        elseif not self.EvoPanel.showPossible[self.panelType] then
            icon = self.showCanUseIcon
        end

        btn:drawTextureScaled(icon, iconOffset, iconOffset, iconSize, iconSize, alpha, color.r, color.g, color.b)
    end
    self:addChild(self.showPossibleButton)
    
    -- Sort Button
    self.sortButton = ISButton:new(0, 0, self.buttonSize, self.buttonSize, "", self, self.onSort)
    self.sortButton:initialise()
    self.sortButton.displayBackground = false
    self.sortButton.tooltip = getText("IGUI_PJCK_SortInput")
    self.sortButton.icon = self.sortIcon
    self.sortButton.render = function(btn)
        local alpha = btn:isMouseOver() and 1 or 0.8
        local iconSize = math.floor(btn.width * 0.8)
        local iconOffset = (btn.width - iconSize) / 2

        btn:drawTextureScaled(btn.icon, iconOffset, iconOffset, iconSize, iconSize, alpha, 0.8, 0.8, 0.8)
    end
    self:addChild(self.sortButton)
end

-- ---------------------------------------------------------- --
-- Button Functions
-- ---------------------------------------------------------- --
function PJCK_InputToolbar:onRandomAdd()
    if not self.EvoPanel:canQueueIngredients() then return end

    local inputList = self.EvoPanel:getInputList(self.panelType)
    local availableItems = {}

    for _, itemInfo in ipairs(inputList) do
        if not itemInfo.isPossible and itemInfo.count > 0 then
            if self.parentPanel:canAddItem(itemInfo.item) then
                local maxAvailable = self.parentPanel:getMaxAvailableCount(itemInfo.item)
                local currentSelected = self.parentPanel:getSelectedCount(itemInfo.item)

                if currentSelected < maxAvailable then
                    table.insert(availableItems, itemInfo.item)
                end
            end
        end
    end

    if #availableItems > 0 then
        local randomIndex = ZombRand(#availableItems) + 1
        local selectedItem = availableItems[randomIndex]
        self.EvoPanel:addPreCookItems(selectedItem)
    end
end

function PJCK_InputToolbar:onShowPossible()
    if not self.EvoPanel:getBaseItem() and not self.EvoPanel:getRecipe() then return end
    self.EvoPanel:toggleShowPossible(self.panelType)
    self.parentPanel:updateList()
end

function PJCK_InputToolbar:onSort()
    local playerNum = self.player:getPlayerNum()
    local contextMenu = ISContextMenu.get(playerNum, self:getAbsoluteX() + self.width, self:getAbsoluteY() + self.sortButton:getY())
    local cookingLevel = self.player:getPerkLevel(Perks.Cooking)

    local nutritionSortOptions = {
        {key = "hunger", text = getText("Tooltip_food_Hunger"), requireLevel = 0},
        {key = "thirst", text = getText("Tooltip_food_Thirst"), requireLevel = 0},
        {key = "boredom", text = getText("Tooltip_food_Boredom"), requireLevel = 0},
        {key = "unhappiness", text = getText("Tooltip_food_Unhappiness"), requireLevel = 0},
        {key = "weight", text = getText("Tooltip_item_Weight"), requireLevel = 0},
        {key = "calories", text = getText("Tooltip_food_Calories"), requireLevel = 8},
        {key = "proteins", text = getText("Tooltip_food_Prots"), requireLevel = 8},
        {key = "lipids", text = getText("Tooltip_food_Fat"), requireLevel = 8},
        {key = "carbohydrates", text = getText("Tooltip_food_Carbs"), requireLevel = 8}
    }
    
    for _, option in ipairs(nutritionSortOptions) do
        local menuOption = contextMenu:addOption(option.text, self, self.applySorting, option.key)

        if cookingLevel < option.requireLevel then
            menuOption.notAvailable = true
            local toolTip = ISToolTip:new()
            toolTip:initialise()
            toolTip:setName(getText("IGUI_PJCK_RequiredCookingLevel") .. ": " .. option.requireLevel)
            menuOption.toolTip = toolTip
        end
    end
end

function PJCK_InputToolbar:applySorting(sortType)
    self.parentPanel.currentSortType = sortType
    self.parentPanel:updateList()
end

-- ---------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------- --
function PJCK_InputToolbar:prerender()
    local countTextHeight = self.height - self.padding * 4 - self.buttonSize * 3

    local bgTop = NinePatchTexture.getSharedTexture("media/ui/Project_Cook/Panel/ToolBar_Top.png")
    local bgBottom = NinePatchTexture.getSharedTexture("media/ui/Project_Cook/Panel/ToolBar_Bottom.png")
    if bgTop and bgBottom then
        bgTop:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, countTextHeight, 0.15, 0.15, 0.15, 1)
        bgBottom:render(self:getAbsoluteX(), self:getAbsoluteY() + countTextHeight, self.width, self.height - countTextHeight, 0.15, 0.15, 0.15, 1)
    end

    self:drawRect(0, 0, 1, self.height, 1, 0.05, 0.05, 0.05)
    self:renderItemCount()
end

function PJCK_InputToolbar:renderItemCount()
    local baseItem = self.EvoPanel:getBaseItem()
    local recipe = self.EvoPanel:getRecipe()

    local countTextHeight = self.height - self.padding * 4 - self.buttonSize * 3
    local textSize = math.floor(self.buttonSize / 2 )
    
    -- default render infinite Icon
    if not baseItem or not recipe then
        local iconX = (self.width - textSize) / 2
        local iconY = countTextHeight / 2 - textSize / 2
        self:drawTextureScaled(self.infiniteIcon, iconX, iconY, textSize, textSize, 1, 0.8, 0.8, 0.8)
        return
    end
    
    local containItems = self.EvoPanel:getContainItems(baseItem, self.panelType)
    local preCookItems = self.EvoPanel:getPreCookItems(self.panelType)
    local totalCurrentCount = #containItems + #preCookItems
    
    -- render current Count
    local currentText = tostring(totalCurrentCount)
    local currentTextWidth = NeatTool.measureTextWidth(currentText, textSize, true)
    local currentTextX = (self.width - currentTextWidth) / 2
    local currentTextY = countTextHeight / 4 - textSize / 2

    NeatTool.renderText(self, currentText, currentTextX, currentTextY, textSize, 1.0, 1, 1, 1, true)
    
    -- Divider
    self:drawRect(self.padding, countTextHeight / 2, self.width - self.padding * 2, 1, 1, 0.6, 0.6, 0.6)
    
    -- render maxAvailable
    if self.panelType == "Ingredient" then
        local maxText = tostring(recipe:getMaxItems())
        local maxTextWidth = NeatTool.measureTextWidth(maxText, textSize, true)
        local maxTextX = (self.width - maxTextWidth) / 2
        local maxTextY = 3 * countTextHeight / 4 - textSize / 2
        NeatTool.renderText(self, maxText, maxTextX, maxTextY, textSize, 1.0, 0.8, 0.8, 0.8, true)
    elseif self.panelType == "Seasoning" then
        local iconX = (self.width - textSize) / 2
        local iconY = 3 * countTextHeight / 4 - textSize / 2
        self:drawTextureScaled(self.infiniteIcon, iconX, iconY, textSize, textSize, 1, 0.8, 0.8, 0.8)
    end
end

return PJCK_InputToolbar