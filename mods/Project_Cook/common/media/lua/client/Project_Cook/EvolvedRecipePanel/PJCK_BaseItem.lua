require "ISUI/ISPanel"
require "ISUI/ISContextMenu"
require "ISUI/ISToolTip"
require "Project_Cook/EvolvedRecipePanel/PJCK_BaseItemSlot"


PJCK_BaseItem = ISPanel:derive("PJCK_BaseItem")
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
-- ---------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------- --

function PJCK_BaseItem:initialise()
    ISPanel.initialise(self)
end

function PJCK_BaseItem:new(x, y, width, height, EvoPanel)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.EvoPanel = EvoPanel
    o.player = EvoPanel.player 
    o.titleHeight = EvoPanel.innerTitleHeight
    o.padding = EvoPanel.padding
    o.baseItemSlotSize = math.floor(FONT_HGT_MEDIUM * 3.5)
    o.subButtonSize = math.floor(o.baseItemSlotSize * 0.6)

    o.TrueIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_True.png")
    o.FalseIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_False.png")
    o.WaterIconTexture = getTexture("media/ui/Project_Cook/ICON/Icon_Water.png")
    o.dumpingIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Empty.png")
    o.fillWaterIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Water.png")
    o.cookIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Cook.png")
    o.starIcon = {
        Y = getTexture("media/ui/Project_Cook/ICON/Icon_Star_Y.png"),
        N = getTexture("media/ui/Project_Cook/ICON/Icon_Star_N.png")
    }
    o.waterStatusEndTime = 0 

    o.currentRating = 0
    o.starSize = math.floor(o.titleHeight * 0.6)
    
    return o
end

function PJCK_BaseItem:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    local minWidth = self.baseItemSlotSize + self.subButtonSize * 2 + self.padding * 4
    local minHeight = self.titleHeight + self.baseItemSlotSize + FONT_HGT_MEDIUM + self.padding * 3

    width = math.max(width, minWidth)
    height = math.max(height, minHeight)

    self:relayoutChildren(width, height)

    self:setWidth(width)
    self:setHeight(height)
end

function PJCK_BaseItem:relayoutChildren(width, height)
    local clearButtonSize = FONT_HGT_SMALL
    
    -- Clear Button
    if self.clearButton then
        local clearButtonX = width - clearButtonSize - self.padding
        local clearButtonY = (self.titleHeight - clearButtonSize) / 2
        
        self.clearButton:setX(clearButtonX)
        self.clearButton:setY(clearButtonY)
        self.clearButton:setWidth(clearButtonSize)
        self.clearButton:setHeight(clearButtonSize)
    end

    local slotX = (width - self.baseItemSlotSize) / 2
    local slotY = self.titleHeight + self.padding
    local subButtonY = slotY + (self.baseItemSlotSize - self.subButtonSize) / 2
    local LSubButtonX = slotX - self.subButtonSize - self.padding
    local RSubButtonX = slotX + self.baseItemSlotSize + self.padding
    
    -- BaseItem Slot
    if self.baseItemSlot then
        self.baseItemSlot:setX(slotX)
        self.baseItemSlot:setY(slotY)
        self.baseItemSlot:setWidth(self.baseItemSlotSize)
        self.baseItemSlot:setHeight(self.baseItemSlotSize)
    end
    
    -- Fill Water Button
    if self.fillWaterButton then
        self.fillWaterButton:setX(LSubButtonX)
        self.fillWaterButton:setY(subButtonY)
        self.fillWaterButton:setWidth(self.subButtonSize)
        self.fillWaterButton:setHeight(self.subButtonSize)
    end
    
    -- Dumping Button
    if self.dumpingButton then
        self.dumpingButton:setX(RSubButtonX)
        self.dumpingButton:setY(subButtonY)
        self.dumpingButton:setWidth(self.subButtonSize)
        self.dumpingButton:setHeight(self.subButtonSize)
    end
    
    -- Cook Button
    if self.cookButton then
        self.cookButton:setX(LSubButtonX)
        self.cookButton:setY(subButtonY)
        self.cookButton:setWidth(self.subButtonSize)
        self.cookButton:setHeight(self.subButtonSize)
    end
end
-- ---------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------- --
function PJCK_BaseItem:createChildren()
    -- Clear Button
    self.clearButton = ISButton:new(0, 0, 10, 10, "", self, self.onClearClick)
    self.clearButton:initialise()
    self.clearButton.prerender = function(btn)
        local color = btn:isMouseOver() and 0.3 or 0.2
        btn:drawTextureScaled(getTexture("media/ui/NeatUI/Button/Background.png"), 0, 0, btn.width, btn.height, 0.8, color, color, color)
        btn:drawTextureScaled(getTexture("media/ui/NeatUI/Button/Boarder.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        local iconSize = math.floor(btn.width * 0.8)
        btn:drawTextureScaled(getTexture("media/ui/Project_Cook/ICON/Icon_Remove.png"), (btn.width - iconSize) / 2, (btn.height - iconSize) / 2, iconSize, iconSize, 1, 0.8, 0.8, 0.8)
        btn:updateTooltip()
    end
    self.clearButton.tooltip = getTextOrNull("IGUI_PJCK_ClearBaseItem") or "Clear base item"
    self:addChild(self.clearButton)
    
    -- baseItem Slot
    self.baseItemSlot = PJCK_BaseItemSlot:new(0, 0, 10, 10, self)
    self.baseItemSlot:initialise()
    self:addChild(self.baseItemSlot)
    
    -- fillWater Button
    self.fillWaterButton = ISButton:new(0, 0, 10, 10, "", self, self.onFillWater)
    self.fillWaterButton:initialise()
    self.fillWaterButton.icon = self.fillWaterIcon
    self.fillWaterButton.prerender = function(btn) self:renderButton(btn) btn:updateTooltip() end
    self.fillWaterButton.tooltip = getTextOrNull("ContextMenu_Fill") or "Fill"
    self.fillWaterButton:setVisible(false)
    self:addChild(self.fillWaterButton)
    
    -- empty Button
    self.dumpingButton = ISButton:new(0, 0, 10, 10, "", self, self.onDumping)
    self.dumpingButton:initialise()
    self.dumpingButton.icon = self.dumpingIcon
    self.dumpingButton.prerender = function(btn) self:renderButton(btn) btn:updateTooltip() end
    self.dumpingButton.tooltip = getTextOrNull("Fluid_Empty") or getTextOrNull("ContextMenu_Empty") or "Empty"
    self.dumpingButton:setVisible(false)
    self:addChild(self.dumpingButton)

    -- cook Button
    self.cookButton = ISButton:new(0, 0, 10, 10, "", self, self.onCook)
    self.cookButton:initialise()
    self.cookButton.icon = self.cookIcon
    self.cookButton.prerender = function(btn) self:renderButton(btn) btn:updateTooltip() end
    self.cookButton:setVisible(false)
    self:addChild(self.cookButton)
    
    -- Rename Button
    self.renameButton = ISButton:new(0, 0, FONT_HGT_MEDIUM, FONT_HGT_MEDIUM, "", self, self.onRenameClick)
    self.renameButton:initialise()
    self.renameButton.prerender = function(btn)
        local btnSize = math.floor(btn.width * 0.8)
        local color = btn:isMouseOver() and 0.3 or 0.2
        btn:drawTextureScaled(getTexture("media/ui/NeatUI/Button/Background.png"), 0, 0, btn.width, btn.height, 0.8, color, color, color)
        btn:drawTextureScaled(getTexture("media/ui/NeatUI/Button/Boarder.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        btn:drawTextureScaled(getTexture("media/ui/Project_Cook/ICON/Icon_Rename.png"), (btn.width - btnSize) / 2, (btn.height - btnSize) / 2, btnSize, btnSize, 1, 0.8, 0.8, 0.8)
        btn:updateTooltip()
    end
    self.renameButton:setVisible(false)
    self:addChild(self.renameButton)

    -- itemName Label
    self.itemNameLabel = ISLabel:new(0, 0, FONT_HGT_MEDIUM, "", 0.8, 0.8, 0.8, 1, UIFont.Medium, true)
    self.itemNameLabel:initialise()
    self:addChild(self.itemNameLabel)
end

function PJCK_BaseItem:getHoverButtonTooltipText(btn)
    if btn == self.fillWaterButton then
        return getTextOrNull("ContextMenu_Fill") or "Fill"
    elseif btn == self.dumpingButton then
        return getTextOrNull("Fluid_Empty") or getTextOrNull("ContextMenu_Empty") or "Empty"
    elseif btn == self.cookButton then
        local selectedCount = #self.EvoPanel:getPreCookItems()
        if selectedCount > 1 then
            return getTextOrNull("IGUI_PJCK_AddSelectedIngredients") or "Add selected ingredients"
        else
            return getTextOrNull("IGUI_PJCK_AddSelectedIngredient") or "Add selected ingredient"
        end
    end
    return nil
end

function PJCK_BaseItem:updateHoverButtonTooltip()
    -- Use the standard ISButton tooltip path for Fill/Empty buttons.
    -- A custom tooltip here would overlap with btn:updateTooltip() from the buttons' prerender.
    if self.hoverTooltip then
        if self.hoverTooltip:getIsVisible() then
            self.hoverTooltip:setVisible(false)
            self.hoverTooltip:removeFromUIManager()
        end
        self.hoverTooltip = nil
    end
end

function PJCK_BaseItem:renderButton(btn)
    local alpha = btn.alpha or 1
    local iconColor = btn.pressed and {r = 0.5, g = 0.5, b = 0.5} or {r = 1, g = 1, b = 1}

    if btn == self.fillWaterButton and self.waterStatusEndTime > 0 then
        local currentTime = getTimestampMs()
        if currentTime < self.waterStatusEndTime then
            alpha = 0.65 + 0.35 * math.sin(currentTime * 0.008)
        end
    end

    --BackGround
    local bgTex = btn.pressed and getTexture("media/ui/Project_Cook/Button/Baseitem_Button_Press.png") or getTexture("media/ui/Project_Cook/Button/Baseitem_Button_BG.png")
    btn:drawTextureScaled(bgTex, 0, 0, btn.width, btn.height, 1, 1, 1, 1)

    -- MouseOver
    if btn:isMouseOver() and not btn.pressed then
        btn:drawTextureScaled(getTexture("media/ui/Project_Cook/Button/Baseitem_Button_hover.png"), 0, 0, btn.width, btn.height, 1, 0.5, 0.5, 0.5)
    end

    -- Icon
    local iconSize = btn.width * 0.9
    btn:drawTextureScaled(btn.icon, (btn.width - iconSize) / 2, (btn.height - iconSize) / 2, iconSize, iconSize, alpha, iconColor.r, iconColor.g, iconColor.b)
end

-- ---------------------------------------------------------- --
-- Button Click
-- ---------------------------------------------------------- --
-- Clear BaseItem
function PJCK_BaseItem:onClearClick()
    self.EvoPanel:setBaseItem(nil)
end

-- Rename
function PJCK_BaseItem:onRenameClick()
    local baseItem = self.EvoPanel.resolveCurrentBaseItem and self.EvoPanel:resolveCurrentBaseItem(true) or self.EvoPanel:getBaseItem()
    if not baseItem then return end
    
    local playerNum = self.player:getPlayerNum()
    
    ISInventoryPaneContextMenu.onRenameFood(baseItem, playerNum)
end

-- Fill Water
function PJCK_BaseItem:onFillWater()
    local playerObj = self.player
    local baseItem = self.EvoPanel.resolveCurrentBaseItem and self.EvoPanel:resolveCurrentBaseItem(true) or self.EvoPanel:getBaseItem()
    -- Abort safely if the selected item has not been resolved back to a live inventory instance yet.
    if not playerObj or not baseItem or not baseItem.getContainer or not baseItem:getContainer() then
        self.fillWaterButton.icon = self.FalseIconTexture
        self.waterStatusEndTime = getTimestampMs() + 2000
        return
    end

    local cell = getCell()
    local px, py, pz = math.floor(playerObj:getX()), math.floor(playerObj:getY()), playerObj:getZ()
    local waterSource = nil

    for dx = -1, 1 do
        if waterSource then break end
        for dy = -1, 1 do
            local square = cell:getGridSquare(px + dx, py + dy, pz)
            if square then
                local objects = square:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if obj:hasWater() and not obj:isTaintedWater() then
                        waterSource = obj
                        break
                    end
                end
                if waterSource then break end
            end
        end
    end
    
    if waterSource then
        self.fillWaterButton.icon = self.TrueIconTexture
        ISWorldObjectContextMenu.onTakeWater(nil, waterSource, nil, baseItem, playerObj:getPlayerNum())
    else
        self.fillWaterButton.icon = self.FalseIconTexture
    end
    
    self.waterStatusEndTime = getTimestampMs() + 2000
end

-- Dumping
function PJCK_BaseItem:onDumping()
    local playerNum = self.player:getPlayerNum()
    local baseItem = self.EvoPanel.resolveCurrentBaseItem and self.EvoPanel:resolveCurrentBaseItem(true) or self.EvoPanel:getBaseItem()
    if not baseItem or not baseItem.getContainer or not baseItem:getContainer() then return end

    local scriptItem = baseItem.getFullType and ScriptManager.instance:FindItem(baseItem:getFullType()) or nil
    local expectedFullType = nil
    if scriptItem then
        if scriptItem:getReplaceOnUse() then
            expectedFullType = moduleDotType(scriptItem:getModuleName(), scriptItem:getReplaceOnUse())
        elseif scriptItem:isItemType(ItemType.Drainable) and scriptItem:getReplaceOnDeplete() then
            expectedFullType = moduleDotType(scriptItem:getModuleName(), scriptItem:getReplaceOnDeplete())
        end
    end
    if expectedFullType and self.EvoPanel.preparePendingBaseItemReplacement then
        self.EvoPanel:preparePendingBaseItemReplacement(expectedFullType, nil)
    end

    ISInventoryPaneContextMenu.onDumpContents(nil, baseItem, playerNum)
end

-- Cook
function PJCK_BaseItem:onCook()
    local baseItem = self.EvoPanel.resolveCurrentBaseItem and self.EvoPanel:resolveCurrentBaseItem(true) or self.EvoPanel:getBaseItem()
    local recipe = self.EvoPanel:getRecipe()
    local preCookItems = self.EvoPanel:getPreCookItems()

    if not self.EvoPanel:canQueueIngredients() then return end
    if not preCookItems or #preCookItems == 0 then return end

    self.EvoPanel:addIngredients(preCookItems, recipe, baseItem)
end

-- ---------------------------------------------------------- --
-- Rating
-- ---------------------------------------------------------- --

function PJCK_BaseItem:calculateRating()
    local baseItem = self.EvoPanel:getBaseItem()
    if not baseItem or not instanceof(baseItem, "Food") then return 0 end
    
    local rating = 0
    
    -- 1. hunger，thirst，boredom，unhappiness
    local hunger = baseItem:getHungerChange() or 0
    local thirst = baseItem:getThirstChange() or 0
    local boredom = baseItem:getBoredomChange() or 0
    local unhappiness = baseItem:getUnhappyChange() or 0
    
    if hunger < 0 and thirst < 0 and boredom < 0 and unhappiness < 0 then
        rating = rating + 1
    end
    
    -- 2. one seasoning
    local seasoningContain = self.EvoPanel:getContainItems(baseItem, "Seasoning")
    local seasoningPreCook = self.EvoPanel:getPreCookItems("Seasoning")
    local totalSeasonings = #seasoningContain + #seasoningPreCook
    
    if totalSeasonings >= 1 then
        rating = rating + 1
    end
    
    -- 3. one ingredient
    local ingredientContain = self.EvoPanel:getContainItems(baseItem, "Ingredient")
    local ingredientPreCook = self.EvoPanel:getPreCookItems("Ingredient")
    local totalIngredients = #ingredientContain + #ingredientPreCook
    
    if totalIngredients >= 1 then
        rating = rating + 1
    end
    
    -- 4. ingredients hit max
    local recipe = self.EvoPanel:getRecipe()
    if recipe then
        local maxIngredients = recipe:getMaxItems()
        if totalIngredients >= maxIngredients then
            rating = rating + 1
        end
    end
    
    -- 5. Seasonings >= 5
    if totalSeasonings >= 5 then
        rating = rating + 1
    end
    
    return rating
end

function PJCK_BaseItem:shouldShowFillWaterButton(baseItem)
    if not baseItem or not baseItem:getFluidContainer() then return false end

    local fluidContainer = baseItem:getFluidContainer()
    local currentAmount = fluidContainer:getAmount()
    local containerCapacity = fluidContainer:getCapacity()

    local function recipeNeedsWater(recipe)
        if not recipe or recipe:getMinimumWater() <= 0 then return false end
        local neededWaterAmount = recipe:getMinimumWater() * containerCapacity
        return currentAmount < neededWaterAmount
    end

    local recipe = self.EvoPanel:getRecipe()
    if recipeNeedsWater(recipe) then
        return true
    end

    local recipes = self.EvoPanel:getRecipes(baseItem)
    if recipes then
        for i = 0, recipes:size() - 1 do
            if recipeNeedsWater(recipes:get(i)) then
                return true
            end
        end
    end

    return false
end

-- ---------------------------------------------------------- --
-- Update
-- ---------------------------------------------------------- --
function PJCK_BaseItem:update()
    ISPanel.update(self)

    if self.waterStatusEndTime > 0 and getTimestampMs() > self.waterStatusEndTime then
        self.fillWaterButton.icon = self.WaterIconTexture
        self.waterStatusEndTime = 0
    end

    self:updateHoverButtonTooltip()
end

function PJCK_BaseItem:updateButtonsVisibility()
    local baseItem = self.EvoPanel:getBaseItem()
    if baseItem then
        -- Can Fill Water
        self.fillWaterButton:setVisible(self:shouldShowFillWaterButton(baseItem))

        -- Can Dumping
        local canDump = ISInventoryPaneContextMenu.canReplaceStoreWater(baseItem) and not baseItem:isWaterSource()
        self.dumpingButton:setVisible(canDump)

        -- Can Cook
        local preCookItems = self.EvoPanel:getPreCookItems()
        local selectedCount = preCookItems and #preCookItems or 0
        self.cookButton.tooltip = selectedCount > 1
            and (getTextOrNull("IGUI_PJCK_AddSelectedIngredients") or "Add selected ingredients")
            or (getTextOrNull("IGUI_PJCK_AddSelectedIngredient") or "Add selected ingredient")
        self.cookButton:setVisible(selectedCount > 0)

        -- Rename
        self.renameButton:setVisible(true)
        self.clearButton:setVisible(true)
    else
        self.fillWaterButton:setVisible(false)
        self.dumpingButton:setVisible(false)
        self.cookButton:setVisible(false)
        self.renameButton:setVisible(false)
        self.clearButton:setVisible(false)
    end
end

function PJCK_BaseItem:updateItemNameLabel()
    local baseItem = self.EvoPanel:getBaseItem()
    local labelText = baseItem and baseItem:getName() or getText("IGUI_PJCK_SelectBaseItem")
    local showRenameButton = self.renameButton and self.renameButton:isVisible()
    local buttonY = self.titleHeight + self.baseItemSlotSize + self.padding * 2

    local maxTextWidth = self.width
    if showRenameButton then
        maxTextWidth = maxTextWidth - self.renameButton:getWidth() - self.padding * 3
    end

    local finalText = NeatTool.truncateText(labelText, maxTextWidth, UIFont.Medium)
    self.itemNameLabel:setName(finalText)
    
    local textWidth = getTextManager():MeasureStringX(UIFont.Medium, finalText)
    local textX = (self.width - textWidth) / 2

    if showRenameButton then
        local buttonX = textX - self.renameButton:getWidth() - self.padding

        if buttonX < self.padding then
            buttonX = self.padding
            textX = buttonX + self.renameButton:getWidth() + self.padding
        end
        
        self.renameButton:setX(buttonX)
        self.renameButton:setY(buttonY)
    end
    
    self.itemNameLabel:setX(textX)
    self.itemNameLabel:setY(buttonY)
end

-- ---------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------- --

function PJCK_BaseItem:prerender()
    self:updateButtonsVisibility()
    self:updateItemNameLabel()

    local contentBG = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/ContentPanel_BG.png")
    local TitleBG = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerTitle_BG.png")
    if contentBG and TitleBG then
        contentBG:render(self:getAbsoluteX(), self:getAbsoluteY() + self.titleHeight, self.width, self.height - self.titleHeight, 0.1, 0.1, 0.1, 1)
        TitleBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.titleHeight, 0.2, 0.2, 0.2, 1)
    end

    local baseItem = self.EvoPanel:getBaseItem()
    if baseItem then
        self:renderStarRating()
    else
        local titleTextY = (self.titleHeight - FONT_HGT_SMALL) / 2
        self:drawText(getText("IGUI_PJCK_BaseItem"), self.padding, titleTextY, 1, 1, 1, 1, UIFont.Small)
    end
end

function PJCK_BaseItem:renderStarRating()

    self.currentRating = self:calculateRating()

    local startX = self.padding
    local startY = (self.titleHeight - self.starSize) / 2

    for i = 1, 5 do
        local starX = startX + (i - 1) * (self.starSize + math.floor(self.padding / 2))
        local icon = (i <= self.currentRating) and self.starIcon.Y or self.starIcon.N
        local color = (i <= self.currentRating) and {r = 1,g = 0.8,b = 0} or {r = 0.6,g = 0.6,b = 0.6}
        
        self:drawTextureScaled(icon, starX, startY, self.starSize, self.starSize, 1, color.r, color.g, color.b)
    end
end

return PJCK_BaseItem