require "ISUI/ISPanel"
require "Project_Cook/EvolvedRecipePanel/PJCK_NutritionBlock"


PJCK_CookingInfo = ISPanel:derive("PJCK_CookingInfo")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ---------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------- --
function PJCK_CookingInfo:initialise()
    ISPanel.initialise(self)
end

function PJCK_CookingInfo:new(x, y, width, height, EvoPanel)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.EvoPanel = EvoPanel
    o.player = EvoPanel.player
    o.titleHeight = EvoPanel.innerTitleHeight
    o.padding = EvoPanel.padding
    o.baseitem = nil
    o.blocksWidth = math.floor(FONT_HGT_SMALL *3)
    o.blocksHeight = math.floor(o.blocksWidth * 5/4)

    o.contentType = ""
    o.content = {}
    
    o.recipeBtnTex = {
        L = getTexture("media/ui/Project_Cook/Button/Tooltips_BG_L.png"),
        M = getTexture("media/ui/Project_Cook/Button/Tooltips_BG_M.png"),
        R = getTexture("media/ui/Project_Cook/Button/Tooltips_BG_R.png")
    }

    o.nutritionIcons = {
        hunger = getTexture("media/ui/Project_Cook/ICON/Icon_Hunger.png"),
        thirst = getTexture("media/ui/Project_Cook/ICON/Icon_Thirst.png"),
        calories = getTexture("media/ui/Project_Cook/ICON/Icon_Calories.png"),
        proteins = getTexture("media/ui/Project_Cook/ICON/Icon_Proteins.png"),
        lipids = getTexture("media/ui/Project_Cook/ICON/Icon_Lipids.png"),
        carbohydrates = getTexture("media/ui/Project_Cook/ICON/Icon_Carbohydrates.png"),
        boredom = getTexture("media/ui/Project_Cook/ICON/Icon_Bored.png"),
        unhappiness = getTexture("media/ui/Project_Cook/ICON/Icon_Sad.png"),
        weight = getTexture("media/ui/Project_Cook/ICON/Icon_HeavyLoad.png")
    }

    o.noItemIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Search.png")
    o.noRecipeIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Query.png")
    o.tipsIcon = getTexture("media/ui/Project_Cook/ICON/Icon_Tips.png")
    o.needWaterIcon = getTexture("media/ui/Project_Cook/ICON/Icon_NeedWater.png")
    
    return o
end

function PJCK_CookingInfo:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    local minWidth = self.blocksWidth * 3 + self.padding * 4
    local minHeight = self.titleHeight + self.blocksHeight * 3 + self.padding * 4

    width = math.max(width, minWidth)
    height = math.max(height, minHeight)

    self:relayoutChildren(width, height)

    self:setWidth(width)
    self:setHeight(height)
end

function PJCK_CookingInfo:relayoutChildren(width, height)
    if self.switchRecipeButton then
        local buttonSize = FONT_HGT_SMALL
        local buttonX = width - buttonSize - self.padding
        local buttonY = math.floor((self.titleHeight - buttonSize) / 2)
        
        self.switchRecipeButton:setX(buttonX)
        self.switchRecipeButton:setY(buttonY)
        self.switchRecipeButton:setWidth(buttonSize)
        self.switchRecipeButton:setHeight(buttonSize)
    end

    if self.contentType == "showNutrition" and self.content then
        local rowCount = 3
        local HPadding = math.floor((width - self.blocksWidth * rowCount) / (rowCount + 1))
        local VPadding = math.floor((height - self.titleHeight - self.blocksHeight * rowCount) / (rowCount + 1))

        for i, nutritionBlock in ipairs(self.content) do
            if nutritionBlock and nutritionBlock.nutritionType then
                local startY = self.titleHeight + self.padding
                local row = math.floor((i - 1) / rowCount)
                local col = (i - 1) % rowCount
                
                local blockX = HPadding + col * (self.blocksWidth + HPadding)
                local blockY = startY + row * self.blocksHeight + row * VPadding + VPadding
                
                nutritionBlock:setX(blockX)
                nutritionBlock:setY(blockY)
                nutritionBlock:setWidth(self.blocksWidth)
                nutritionBlock:setHeight(self.blocksHeight)
            end
        end
    end

    if self.contentType == "showRecipes" and self.content then
        local buttonHeight = math.floor(FONT_HGT_MEDIUM * 1.2)
        local buttonWidth = width - self.padding * 2
        local totalButtonsHeight = #self.content * buttonHeight + (#self.content - 1) * self.padding

        local availableContentHeight = height - self.titleHeight - self.padding * 2
        local centerStartY = self.titleHeight + (availableContentHeight - totalButtonsHeight) / 2
        
        local currentY = centerStartY
        for i, recipeButton in ipairs(self.content) do
            if recipeButton then
                recipeButton:setX(self.padding)
                recipeButton:setY(currentY)
                recipeButton:setWidth(buttonWidth)
                recipeButton:setHeight(buttonHeight)
                currentY = currentY + buttonHeight + self.padding
            end
        end
    end
end

-- ---------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------- --
function PJCK_CookingInfo:createChildren()
    local buttonSize = FONT_HGT_SMALL
    self.switchRecipeButton = ISButton:new(self.width - buttonSize - self.padding, math.floor((self.titleHeight - buttonSize) / 2), buttonSize, buttonSize, "", self, self.onSwitchRecipe)
    self.switchRecipeButton:initialise()
    self.switchRecipeButton.tooltip = getTextOrNull("IGUI_PJCK_Back") or getTextOrNull("IGUI_Map_Sharing_ButtonBack") or getTextOrNull("IGUI_ScavengeUI_Back") or "Back"
    self.switchRecipeButton.prerender = function(btn)
        local color = btn:isMouseOver() and 0.3 or 0.2
        btn:drawTextureScaled(getTexture("media/ui/NeatUI/Button/Background.png"), 0, 0, btn.width, btn.height, 0.8, color, color, color)
        btn:drawTextureScaled(getTexture("media/ui/NeatUI/Button/Boarder.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        local iconSize = math.floor(btn.width * 0.8)
        btn:drawTextureScaled(getTexture("media/ui/Project_Cook/ICON/Icon_CraftReturn.png"), (btn.width - iconSize) / 2, (btn.height - iconSize) / 2, iconSize, iconSize, 1, 0.8, 0.8, 0.8)
        btn:updateTooltip()
    end
    self:addChild(self.switchRecipeButton)
end

function PJCK_CookingInfo:onSwitchRecipe()
    self.EvoPanel:setRecipe(nil)
end

function PJCK_CookingInfo:showNutritionBlocks()
    local baseItem = self.EvoPanel:getBaseItem()
    if not baseItem or not instanceof(baseItem, "Food") then return end

    local nutritionTypes = {
        {type = "hunger", icon = self.nutritionIcons.hunger, typeName = getText("Tooltip_food_Hunger")},
        {type = "thirst", icon = self.nutritionIcons.thirst, typeName = getText("Tooltip_food_Thirst")},
        {type = "calories", icon = self.nutritionIcons.calories, typeName = getText("Tooltip_food_Calories")},
        {type = "proteins", icon = self.nutritionIcons.proteins, typeName = getText("Tooltip_food_Prots")},
        {type = "lipids", icon = self.nutritionIcons.lipids, typeName = getText("Tooltip_food_Fat")},
        {type = "carbohydrates", icon = self.nutritionIcons.carbohydrates, typeName = getText("Tooltip_food_Carbs")},
        {type = "boredom", icon = self.nutritionIcons.boredom, typeName = getText("Tooltip_food_Boredom")},
        {type = "unhappiness", icon = self.nutritionIcons.unhappiness, typeName = getText("Tooltip_food_Unhappiness")},
        {type = "weight", icon = self.nutritionIcons.weight, typeName = getText("Tooltip_item_Weight")}
    }

    local rowCount = 3
    local HPadding = math.floor((self.width - self.blocksWidth * rowCount) / (rowCount + 1))
    local VPadding = math.floor((self.height - self.titleHeight - self.blocksHeight * rowCount) / (rowCount + 1))

    for i, nutritionType in ipairs(nutritionTypes) do
        local startY = self.titleHeight + VPadding
        local row = math.floor((i - 1) / rowCount)
        local col = (i - 1) % rowCount
        
        local blockX = HPadding + col * (self.blocksWidth + HPadding)
        local blockY = startY + row * self.blocksHeight + (row-1)*VPadding
        
        local block = PJCK_NutritionBlock:new(blockX, blockY + VPadding , self.blocksWidth, self.blocksHeight, self)
        block:initialise()
        block.nutritionType = nutritionType.type
        block.typeName = nutritionType.typeName
        block.icon = nutritionType.icon
        
        self:addChild(block)
        table.insert(self.content, block)
    end
end


function PJCK_CookingInfo:showRecipeButtons()
    local baseItem = self.EvoPanel:getBaseItem()
    local recipes = self.EvoPanel:getRecipes(baseItem)

    local buttonHeight = math.floor(FONT_HGT_MEDIUM*1.2)
    local buttonWidth = self.width - self.padding*2
    local totalButtonsHeight = recipes:size() * buttonHeight + (recipes:size() - 1) * self.padding

    local availableContentHeight = self.height - self.titleHeight - self.padding * 2
    local centerStartY = self.titleHeight + (availableContentHeight - totalButtonsHeight) / 2
    
    local currentY = centerStartY
    for i=0, recipes:size() - 1 do
        local recipe = recipes:get(i)
        local recipeName = getText("ContextMenu_EvolvedRecipe_" .. recipe:getUntranslatedName())
        local recipeButton = ISButton:new(self.padding, currentY, buttonWidth, buttonHeight, recipeName, self, self.onRecipeButtonClick)
        recipeButton:initialise()
        recipeButton.recipe = recipe
        recipeButton.prerender = function(btn)
            local color = btn:isMouseOver() and 0.6 or 0.4
            NeatTool.ThreePatch.drawHorizontal(btn,0, 0, btn.width, btn.height,self.recipeBtnTex.L,self.recipeBtnTex.M,self.recipeBtnTex.R,0.8, color, color, color)
            btn:updateTooltip()
        end
        
        self:addChild(recipeButton)
        table.insert(self.content, recipeButton)
        currentY = currentY + buttonHeight + self.padding
    end
end

function PJCK_CookingInfo:onRecipeButtonClick(button)
    local recipe = button.recipe
    self.EvoPanel:setRecipe(recipe)
end


-- ---------------------------------------------------------- --
-- Update
-- ---------------------------------------------------------- --

function PJCK_CookingInfo:update()
    ISPanel.update(self)
end

function PJCK_CookingInfo:clearContent()
    
    for _, element in ipairs(self.content) do
        self:removeChild(element)
    end
    self.content = {}
end

function PJCK_CookingInfo:isAddOneFirst(baseItem, recipe)
    if not recipe or not baseItem then return false end

    local resultItem = recipe:getResultItem()
    local baseItemType = baseItem:getType()

    return resultItem ~= baseItemType
end

function PJCK_CookingInfo:isNeedWater(baseItem, recipe)
    if not baseItem or not recipe or not baseItem:getFluidContainer() then return false end
    
    local fluidContainer = baseItem:getFluidContainer()
    local currentAmount = fluidContainer:getAmount()
    local containerCapacity = fluidContainer:getCapacity()

    if recipe:getMinimumWater() > 0 then
        local neededWaterAmount = recipe:getMinimumWater() * containerCapacity
        return currentAmount < neededWaterAmount
    end
    return false
end

function PJCK_CookingInfo:updateContentType()
    local baseItem = self.EvoPanel:getBaseItem()
    local newContentType = nil
    local previousContentType = self.contentType
    
    -- 1: no BaseItem
    if not baseItem then
        newContentType = "noBaseItem"
        self.switchRecipeButton:setVisible(false)
    else
        local evorecipes = self.EvoPanel:getRecipes(baseItem)
        local hasRecipes = evorecipes and evorecipes:size() > 0
        local recipe = self.EvoPanel:getRecipe()
        local shouldShowSwitch = false
        if hasRecipes and evorecipes and evorecipes:size() > 1 and recipe then
            shouldShowSwitch = true
        end
        self.switchRecipeButton:setVisible(shouldShowSwitch)
        
        -- 2: have recipes but not select recipe
        if hasRecipes and not recipe then
            newContentType = "showRecipes"
        -- 3: have recipe (already selected)
        elseif recipe then
            if self:isNeedWater(baseItem, recipe) then
                newContentType = "needWater"
            elseif self:isAddOneFirst(baseItem, recipe) then
                newContentType = "addOneFirst"
            else
                newContentType = "showNutrition"
            end
        -- 4: no recipes
        else
            newContentType = "showNutrition"
        end
    end

    if self.contentType ~= newContentType then
        self:clearContent()
        self.contentType = newContentType
        self:updateContent()

        if previousContentType == "needWater" and newContentType ~= "needWater" then
            self.EvoPanel:onUpdateRecipe()
        end
    end
end

function PJCK_CookingInfo:updateContent()
    if self.contentType == "showRecipes" then
        self:showRecipeButtons()
    elseif self.contentType == "showNutrition" then
        self:showNutritionBlocks()
    end
end

-- ---------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------- --

function PJCK_CookingInfo:prerender()
    local contentBG = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/ContentPanel_BG.png")
    local TitleBG = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerTitle_BG.png")
    if contentBG and TitleBG then
        contentBG:render(self:getAbsoluteX(), self:getAbsoluteY() + self.titleHeight, self.width, self.height - self.titleHeight, 0.1, 0.1, 0.1, 1)
        TitleBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.titleHeight, 0.2, 0.2, 0.2, 1)
    end

    local titleTextY = (self.titleHeight - FONT_HGT_SMALL) / 2
    local cookinglvText = getText("IGUI_perks_Cooking") .." Lv : " ..self.player:getPerkLevel(Perks.Cooking)
    local text = self.contentType == "showNutrition" and cookinglvText or getText("IGUI_PJCK_CookingInfo")
    self:drawText(text, self.padding, titleTextY, 1, 1, 1, 1, UIFont.Small)
end

function PJCK_CookingInfo:render()
    self:updateContentType()

    if self.contentType == "noBaseItem" then
        self:renderContent(self.noItemIcon, "IGUI_PJCK_NoBaseItemSelected")
    elseif self.contentType == "noRecipe" then
        self:renderContent(self.noRecipeIcon, "IGUI_PJCK_NotAvailable")
    elseif self.contentType == "addOneFirst" then
        self:renderContent(self.tipsIcon, "IGUI_PJCK_AddOneFirst")
    elseif self.contentType == "needWater" then
        local neededWater = 0
        local fluidContainer = self.EvoPanel:getBaseItem():getFluidContainer()
        local maxCapacity = fluidContainer:getCapacity()
        local neededWaterAmount = self.EvoPanel:getRecipe():getMinimumWater() * maxCapacity
        neededWater = math.ceil(neededWaterAmount * 1000)

        local availableHeight = self.height - self.titleHeight
        local iconSize = math.floor(self.width * 0.4)
        local textSize = FONT_HGT_SMALL
        local totalHeight = iconSize + textSize + self.padding
        local startY = self.titleHeight + (availableHeight - totalHeight) / 2

        local iconX = (self.width - iconSize) / 2
        self:drawTextureScaled(self.needWaterIcon, iconX, startY, iconSize, iconSize, 1, 1, 1, 1)
        
        local waterText = getText("IGUI_PJCK_NeedWater") .. ": " .. neededWater .. " ML"
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, waterText)
        local textX = (self.width - textWidth) / 2
        local textY = startY + iconSize + self.padding
        
        NeatTool.ThreePatch.drawHorizontal(self, textX - self.padding, textY - self.padding/2, textWidth + self.padding * 2, textSize + self.padding, self.recipeBtnTex.L, self.recipeBtnTex.M, self.recipeBtnTex.R, 0.8, 0.5, 0.5, 0.5)
        self:drawText(waterText, textX, textY, 1, 1, 1, 1, UIFont.Small)
    end
end

function PJCK_CookingInfo:renderContent(icon, textKey)
    local availableHeight = self.height - self.titleHeight
    local iconSize = math.floor(self.width * 0.4)
    local textSize = FONT_HGT_SMALL
    local totalHeight = iconSize + textSize + self.padding
    local startY = self.titleHeight + (availableHeight - totalHeight) / 2

    -- Icon
    local iconX = (self.width - iconSize) / 2
    self:drawTextureScaled(icon, iconX, startY, iconSize, iconSize, 1, 1, 1, 1)
    
    -- Text
    local textWidth = getTextManager():MeasureStringX(UIFont.Small, getText(textKey))
    local textX = (self.width - textWidth) / 2
    local textY = startY + iconSize + self.padding
    
    NeatTool.ThreePatch.drawHorizontal(self,textX - self.padding, textY - self.padding, textWidth + self.padding * 2, textSize + self.padding * 2,self.recipeBtnTex.L,self.recipeBtnTex.M,self.recipeBtnTex.R,0.8, 0.5, 0.5, 0.5)

    self:drawText(getText(textKey), textX, textY, 1, 1, 1, 1, UIFont.Small)
end

return PJCK_CookingInfo