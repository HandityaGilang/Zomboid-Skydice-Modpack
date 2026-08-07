require "ISUI/ISPanel"
require "Project_Cook/EvolvedRecipePanel/PJCK_InputToolbar"
require "Project_Cook/EvolvedRecipePanel/PJCK_ItemSlot"


PJCK_InputPanel = ISPanel:derive("PJCK_InputPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------- --
function PJCK_InputPanel:initialise()
    ISPanel.initialise(self)
end

function PJCK_InputPanel:new(x, y, width, height, EvoPanel, panelType)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.padding = EvoPanel.padding
    o.slotWidth = math.max(48, round(FONT_HGT_SMALL*2.5))
    o.slotHeight = o.slotWidth + math.floor(o.padding + o.slotWidth / 4)
    o.slotSpacing = o.padding * 2
    o.rowHeight = o.slotWidth + o.slotSpacing
    o.scrollBarThickness = math.floor(FONT_HGT_SMALL * 0.6)

    o.toolBarSlotSize = math.max(24, math.floor(FONT_HGT_SMALL * 1.8))
    o.toolBarWidth = o.toolBarSlotSize + o.padding * 2

    o.titleText = nil
    o.titleHeight = EvoPanel.innerTitleHeight
    
    o.EvoPanel = EvoPanel
    o.panelType = panelType  -- "Ingredient" or "Seasoning"
    o.itemSlots = {}
    o.currentSortType = "hunger"

    o.slotTex = {
        bg = getTexture("media/ui/Project_Cook/Button/Background.png"),
        border = getTexture("media/ui/Project_Cook/Button/Border.png"),
        select = getTexture("media/ui/Project_Cook/Button/Select.png"),
    }

    o.TipsBg = {
        L = getTexture("media/ui/Project_Cook/Button/Tooltips_BG_L.png"),
        M = getTexture("media/ui/Project_Cook/Button/Tooltips_BG_M.png"),
        R = getTexture("media/ui/Project_Cook/Button/Tooltips_BG_R.png")
    }

    o.bottomTex = {
        L = getTexture("media/ui/Project_Cook/Button/Itemslot_Button_BG_L.png"),
        M = getTexture("media/ui/Project_Cook/Button/Itemslot_Button_BG_M.png"),
        R = getTexture("media/ui/Project_Cook/Button/Itemslot_Button_BG_R.png")
    }

    o.freshIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Fresh.png")
    o.cookableIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Cookable.png")
    o.burntIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Burnt.png")
    o.frozenIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Frozen.png")
    o.plusIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Plus.png")
    o.minusIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Minus.png")
    o.randomIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Dice.png")
    
    return o
end

function PJCK_InputPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.width)
    local height = math.max(_preferredHeight or 0, self.height)

    local minSlotColumn = 5
    local minSlotRow = 2

    if self.scrollView then
        self.scrollView:setX(0)
        self.scrollView:setY(self.titleHeight)
        self.scrollView:setWidth(width - self.toolBarWidth)
        self.scrollView:setHeight(height - self.titleHeight)
    end

    local minWidth = self.slotWidth * minSlotColumn + self.slotSpacing * (minSlotColumn + 1) + self.toolBarWidth
    local minHeight = self.titleHeight + self.slotHeight * minSlotRow + self.slotSpacing * (minSlotRow + 1) + self.scrollBarThickness

    width = math.max(width, minWidth)
    height = math.max(height, minHeight)

    if self.toolbar then
        self.toolbar:setX(width - self.toolBarWidth)
        self.toolbar:setY(0)
        self.toolbar:setWidth(self.toolBarWidth)
        self.toolbar:setHeight(height)
        self.toolbar:calculateLayout()
    end

    self:setWidth(width)
    self:setHeight(height)
    self:updateList()
end

-- ---------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------- --
function PJCK_InputPanel:createChildren()
    self.scrollView = NIGridVirtualScrollView:new(0, 0, 10, 10)
    self.scrollView:initialise()
    self.scrollView:setScrollDirection("horizontal")
    self.scrollView:setOnCreateItem(function(index) return self:onCreateSlot(index) end)
    self.scrollView:setOnUpdateItem(function(item, data, row, col) return self:onUpdateSlot(item, data, row, col) end)
    self:addChild(self.scrollView)

    self.toolbar = PJCK_InputToolbar:new(0, 0, 10, 10, self, self.EvoPanel, self.panelType, self.toolBarSlotSize)
    self.toolbar:initialise()
    self:addChild(self.toolbar)
end

function PJCK_InputPanel:onCreateSlot(index)
    local slot = PJCK_ItemSlot:new(0, 0, self.slotWidth, self.slotHeight, nil, 0, self)
    slot:initialise()
    return slot
end

function PJCK_InputPanel:onUpdateSlot(slot, itemInfo, row, col)
    slot:setItemData(itemInfo.item, itemInfo.count, itemInfo.isPossible, itemInfo.frozenPreview)
    slot.index = (row - 1) * self.scrollView.axisCount + col
end

-- ---------------------------------------------------------- --
-- Item can be added
-- ---------------------------------------------------------- --

function PJCK_InputPanel:canAddItem(item)
    local recipe = self.EvoPanel:getRecipe()
    local baseItem = self.EvoPanel:getBaseItem()
    if not recipe or not baseItem then return false end

    if not self.EvoPanel:isUsableForRecipe(item, recipe) then
        return false
    end

    -- addOneFirst
    if self.EvoPanel:getCookStatus() == "addOneFirst" then
        local totalCurrentCount = #self.EvoPanel:getContainItems(baseItem, "Ingredient") + #self.EvoPanel:getContainItems(baseItem, "Seasoning")
        local totalSelectedCount = #self.EvoPanel:getPreCookItems("Ingredient") + #self.EvoPanel:getPreCookItems("Seasoning")
        return (totalCurrentCount + totalSelectedCount) < 1
    end

    -- Seasoning(no limit),Ingredients(MaxItems)
    if self.EvoPanel:isValidSeasoning(item) then
        return true
    else
        local currentCount = self.EvoPanel:getContainItems(baseItem, "Ingredient")
        local selectedCount = self.EvoPanel:getPreCookItems("Ingredient")
        return (#currentCount + #selectedCount) < recipe:getMaxItems()
    end
end

function PJCK_InputPanel:getMaxAvailableCount(item)
    if self.EvoPanel:isValidSeasoning(item) then
        return 1
    end
    
    if self.EvoPanel:getCookStatus() == "addOneFirst" then
        return 1
    end

    local recipe = self.EvoPanel:getRecipe()
    if not recipe then return 1 end
    
    local itemRecipe = recipe:getItemRecipe(item)
    if not itemRecipe then return 1 end
    
    if instanceof(item, "Food") then
        local playerObj = self.EvoPanel.player
        local cookingLvl = playerObj:getPerkLevel(Perks.Cooking)
        
        local realUse = ISInventoryPaneContextMenu.getRealEvolvedItemUse(item, recipe, cookingLvl)
        local currentHungerChange = math.floor(math.abs(item:getHungChange() * 100))
        
        if realUse > 0 and currentHungerChange > 0 then
            local itemUseTimes = math.ceil((currentHungerChange / realUse))
            return math.max(1, itemUseTimes)
        end
    end

    return 1
end

function PJCK_InputPanel:getSelectedCount(item)
    local count = 0
    local preCookItems = self.EvoPanel:getPreCookItems()
    for _, selectedItem in ipairs(preCookItems) do
        if selectedItem:getID() == item:getID() then
            count = count + 1
        end
    end
    return count
end

-- ---------------------------------------------------------- --
-- Update
-- ---------------------------------------------------------- --
function PJCK_InputPanel:onUpdateBaseItem()
    self:updateList()
end

function PJCK_InputPanel:onUpdateRecipe()
    self:updateList()
end

function PJCK_InputPanel:onUpdateContainers()
    self:updateList()
end

function PJCK_InputPanel:updateList()
    local itemList = self.EvoPanel:getInputList(self.panelType)

    if self.currentSortType then
        itemList = self:sortItemList(itemList, self.currentSortType)
    end

    self.itemSlots = {}
    local rowCount = round((self.scrollView:getHeight() - self.slotSpacing * 3 - self.scrollBarThickness) / self.slotHeight)
    self.scrollView:setConfig(self.slotWidth, self.slotHeight, rowCount)
    self.scrollView:setSpacing(self.slotSpacing, self.slotSpacing)
    self.scrollView:setDataSource(itemList, true)
end


function PJCK_InputPanel:sortItemList(itemList, sortType)
    local sortedList = {}
    for _, item in ipairs(itemList) do
        table.insert(sortedList, item)
    end
    
    -- sort by isPossible
    table.sort(sortedList, function(a, b)
        if a.isPossible ~= b.isPossible then
            return not a.isPossible
        end
        
        return self:compareByNutrition(a.item, b.item, sortType)
    end)
    
    return sortedList
end

function PJCK_InputPanel:compareByNutrition(itemA, itemB, nutritionType)
    local valueA = self:getNutritionValue(itemA, nutritionType)
    local valueB = self:getNutritionValue(itemB, nutritionType)
    
    -- sort by value
    if valueA ~= valueB then
        return valueA > valueB
    end

    return itemA:getName() < itemB:getName()
end

function PJCK_InputPanel:getNutritionValue(item, nutritionType)
    if not instanceof(item, "Food") then return 0 end
    
    if nutritionType == "hunger" then
        return -(item:getHungerChange() * 100) or 0
    elseif nutritionType == "thirst" then
        return -(item:getThirstChange() * 100) or 0
    elseif nutritionType == "boredom" then
        return -(item:getBoredomChange() * 100) or 0
    elseif nutritionType == "unhappiness" then
        return -(item:getUnhappyChange() * 100) or 0
    elseif nutritionType == "calories" then
        return item:getCalories() or 0
    elseif nutritionType == "proteins" then
        return item:getProteins() or 0
    elseif nutritionType == "lipids" then
        return item:getLipids() or 0
    elseif nutritionType == "carbohydrates" then
        return item:getCarbohydrates() or 0
    elseif nutritionType == "weight" then
        return item:getActualWeight() or 0
    end
    
    return 0
end
-- ---------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------- --
function PJCK_InputPanel:prerender()
    local contentBG = NinePatchTexture.getSharedTexture("media/ui/Project_Cook/Button/ContentPanel_BG.png")
    if contentBG then
        contentBG:render(self:getAbsoluteX()- 2, self:getAbsoluteY(), self.width - self.toolBarWidth + 2, self.height, 0.1, 0.1, 0.1, 1)
    end

    local titleTextY = (self.titleHeight - FONT_HGT_SMALL) / 2
    self:drawText(self.titleText .. " :", self.padding, titleTextY, 1, 1, 1, 1, UIFont.Small)
end

function PJCK_InputPanel:render()
    local baseItem = self.EvoPanel:getBaseItem()
    if not baseItem then return end

    self:renderAllContainItems(baseItem)

    self:renderAddingIngredient(baseItem)
end

function PJCK_InputPanel:renderAllContainItems(baseItem)
    local iconSize = math.floor(FONT_HGT_SMALL / 4) * 4
    local titleWidth = getTextManager():MeasureStringX(UIFont.Small, self.titleText)
    local startX = self.padding + titleWidth + self.padding
    local iconY = (self.titleHeight - iconSize) / 2

    local allIcons = {}
    
    -- containItems
    if baseItem then
        for _, texture in ipairs(self.EvoPanel:getContainItems(baseItem, self.panelType)) do
            if texture then
                table.insert(allIcons, {texture = texture, alpha = 1})
            end
        end
    end
    
    -- preCookItems
    local breathAlpha = 0.5 + 0.25 * math.sin(getTimestampMs() * 0.004)
    for _, item in ipairs(self.EvoPanel:getPreCookItems(self.panelType)) do
        if item then
            table.insert(allIcons, {texture = item:getTex(), alpha = breathAlpha})
        end
    end
    
    local totalIcons = #allIcons
    if totalIcons == 0 then return end
    
    -- iconsToShow
    local availableWidth = self.width - self.toolBarWidth - startX
    local singleIconWidth = iconSize + self.padding / 2
    local overflowTextWidth = getTextManager():MeasureStringX(UIFont.Small, "+99")
    
    local maxWithoutOverflow = math.floor(availableWidth / singleIconWidth)
    local iconsToShow = totalIcons > maxWithoutOverflow and math.min(totalIcons, math.floor((availableWidth - overflowTextWidth) / singleIconWidth)) or totalIcons
    
    -- Render Icons
    for i = 1, iconsToShow do
        local icon = allIcons[i]
        self:drawTextureScaledAspect(icon.texture, startX, iconY, iconSize, iconSize, icon.alpha, 1, 1, 1)
        startX = startX + singleIconWidth
    end
    
    -- Render over Count
    if totalIcons > iconsToShow then
        local textY = (self.titleHeight - FONT_HGT_SMALL) / 2
        self:drawText("+" .. (totalIcons - iconsToShow), startX, textY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
end

function PJCK_InputPanel:renderAddingIngredient(baseItem)
    local player = self.EvoPanel.player
    if not player or not baseItem then return end
    
    local queue = ISTimedActionQueue.getTimedActionQueue(player)
    if not (queue and queue.current and queue.current.Type == "ISAddItemInRecipe" and queue.current.baseItem and queue.current.baseItem:getID() == baseItem:getID()) then 
        return
    end

    local usedItem = queue.current.usedItem
    if not usedItem then return end

    local shouldShowInThisPanel = false
    if self.panelType == "Seasoning" then
        shouldShowInThisPanel = self.EvoPanel:isValidSeasoning(usedItem)
    elseif self.panelType == "Ingredient" then
        shouldShowInThisPanel = self.EvoPanel:isValidIngredient(usedItem)
    end
    
    if not shouldShowInThisPanel then return end

    local availableHeight = self.height - self.titleHeight
    local textSize = FONT_HGT_SMALL

    local textContent = getText("IGUI_JobType_AddingIngredient", usedItem:getDisplayName(), getText("IGUI_PJCK_BaseItem"))
    local textWidth = getTextManager():MeasureStringX(UIFont.Small, textContent)
    
    local textX = (self.scrollView:getWidth() - textWidth) / 2
    local textY = self.titleHeight + (availableHeight - textSize) / 2
    
    -- bg
    NeatTool.ThreePatch.drawHorizontal(self, textX - self.padding, textY - self.padding, textWidth + self.padding * 2, textSize + self.padding*2, self.TipsBg.L, self.TipsBg.M, self.TipsBg.R, 0.8, 0.5, 0.5, 0.5)

    -- text
    self:drawText(textContent, textX, textY, 1, 1, 1, 1, UIFont.Small)
end

return PJCK_InputPanel