require "ISUI/ISPanel"
require "ISUI/ISToolTip"

PJCK_NutritionBlock = ISPanel:derive("PJCK_NutritionBlock")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- ---------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------- --

function PJCK_NutritionBlock:initialise()
    ISPanel.initialise(self)
end

function PJCK_NutritionBlock:new(x, y, width, height, parentPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.parentPanel = parentPanel
    o.EvoPanel = parentPanel.EvoPanel

    o.nutritionType = nil
    o.icon = nil
    o.typeName = nil

    o.iconSize = round((width * 0.8)/ 16) * 16
    o.textSize = FONT_HGT_SMALL * 0.7
    
    o.bgTexture = getTexture("media/ui/Project_Cook/Button/InfoButton_BG.png")
    
    return o
end

-- ---------------------------------------------------------- --
-- Config Manager
-- ---------------------------------------------------------- --


function PJCK_NutritionBlock:getNutritionDisplayMode(baseItem, player)
    if not baseItem or not instanceof(baseItem, "Food") then
        return "hidden"
    end
    
    -- 1. Nutritionist - Show All
    if player and (player:hasTrait(CharacterTrait.NUTRITIONIST) or player:hasTrait(CharacterTrait.NUTRITIONIST2)) then
        return "full"
    end
    
    -- 2. PackFood - Show All
    if baseItem:isPackaged() then
        if player then
            if player:hasTrait(CharacterTrait.ILLITERATE) then
                return "hidden"
            end

            if player:tooDarkToRead() then
                return "hidden"
            end
        end

        if baseItem:getModData() and baseItem:getModData().NoLabel then
            return "hidden"
        end
        
        return "full"
    end
    
    -- 3. Depend on CookingLevel
    if player then
        local cookingLevel = player:getPerkLevel(Perks.Cooking)
        if cookingLevel >= 8 then
            return "full"        -- Show Full
        elseif cookingLevel >= 6 then
            return "tens"        -- Show Tens
        elseif cookingLevel >= 4 then
            return "hundreds"    -- Show Hundreds
        elseif cookingLevel >= 2 then
            return "digits"      -- Show digits
        end
    end
    
    return "hidden"
end

-- Format Value By Mode
function PJCK_NutritionBlock:formatValueByMode(value, mode)
    if mode == "hidden" then
        return "????"
    elseif mode == "full" then
        return tostring(value)
    end
    
    local absValue = math.abs(value)
    local valueStr = tostring(absValue)
    local len = string.len(valueStr)

    local hiddenDigits, minLength
    if mode == "digits" then
        hiddenDigits = len
        minLength = 999
    elseif mode == "hundreds" then
        hiddenDigits = 2
        minLength = 3
    elseif mode == "tens" then
        hiddenDigits = 1
        minLength = 2
    else
        return tostring(value)
    end
    
    local result
    if len < minLength then
        result = string.rep("?", len)
    else
        local visibleDigits = len - hiddenDigits
        result = string.sub(valueStr, 1, visibleDigits) .. string.rep("?", hiddenDigits)
    end
    
    return result
end

-- get Food Value
function PJCK_NutritionBlock:getValue(baseItem)
    if not baseItem or not instanceof(baseItem, "Food") then return nil, nil end

    local player = self.parentPanel.player
    local value = nil
    
    if self.nutritionType == "hunger" then
        local hungerChange = baseItem:getHungerChange()
        value = hungerChange and math.floor(hungerChange * 100) or nil
    elseif self.nutritionType == "thirst" then
        local thirstChange = baseItem:getThirstChange()
        value = thirstChange and math.floor(thirstChange * 100) or nil
    elseif self.nutritionType == "calories" then
        value = baseItem:getCalories() and math.floor(baseItem:getCalories()) or nil
    elseif self.nutritionType == "boredom" then
        local boredomChange = baseItem:getBoredomChange()
        value = boredomChange and math.floor(boredomChange) or nil
    elseif self.nutritionType == "unhappiness" then
        local unhappyChange = baseItem:getUnhappyChange()
        value = unhappyChange and math.floor(unhappyChange) or nil
    elseif self.nutritionType == "proteins" then
        value = baseItem:getProteins() and math.floor(baseItem:getProteins()) or nil
    elseif self.nutritionType == "lipids" then
        value = baseItem:getLipids() and math.floor(baseItem:getLipids()) or nil
    elseif self.nutritionType == "carbohydrates" then
        value = baseItem:getCarbohydrates() and math.floor(baseItem:getCarbohydrates()) or nil
    elseif self.nutritionType == "weight" then
        local actualWeight = baseItem:getActualWeight()
        value = actualWeight and math.floor(actualWeight * 100) / 100 or nil
    end

    if value == nil then return nil, nil end

    local displayValue
    if self.nutritionType == "calories" or self.nutritionType == "proteins" or 
       self.nutritionType == "lipids" or self.nutritionType == "carbohydrates" then
        local displayMode = self:getNutritionDisplayMode(baseItem, player)
        displayValue = self:formatValueByMode(value, displayMode)
    else
        displayValue = tostring(value)
    end

    return value, displayValue
end

-- ---------------------------------------------------------- --
-- Mouse Function
-- ---------------------------------------------------------- --

function PJCK_NutritionBlock:onMouseMove(dx, dy)
    self:showTooltip()
    return true
end

function PJCK_NutritionBlock:onMouseMoveOutside(dx, dy)
    self:hideTooltip()
    return true
end

function PJCK_NutritionBlock:showTooltip()
    if not self.tooltip then
        self.tooltip = ISToolTip:new()
        self.tooltip:initialise()
        self.tooltip:setOwner(self)
    end
    
    local tooltipText = self.typeName
    self.tooltip:setName(tooltipText)

    if self.nutritionType == "calories" or self.nutritionType == "proteins" or self.nutritionType == "lipids" or self.nutritionType == "carbohydrates" then

        local baseItem = self.EvoPanel:getBaseItem()
        local player = self.parentPanel.player
        
        if baseItem and instanceof(baseItem, "Food") then
            local displayMode = self:getNutritionDisplayMode(baseItem, player)
            
            if displayMode == "hidden" then
                local description = "<RGB:1,1,0>" .. "- "..getText("IGUI_perks_Cooking") .. " LV2: " .. getText("IGUI_PJCK_ShowToDigits")
                self.tooltip:setDescription(description)
            elseif displayMode == "digits" then
                local description = "<RGB:1,1,0>" .. getText("IGUI_perks_Cooking") .. " LV4: " ..getText("IGUI_PJCK_ShowToHundreds")
                self.tooltip:setDescription(description)
            elseif displayMode == "hundreds" then
                local description = "<RGB:1,1,0>" .. getText("IGUI_perks_Cooking") .. " LV6: " .. getText("IGUI_PJCK_ShowToTens")
                self.tooltip:setDescription(description)
            elseif displayMode == "tens" then
                local description = "<RGB:1,1,0>" .. getText("IGUI_perks_Cooking") .. " LV8: " .. getText("IGUI_PJCK_ShowFull")
                self.tooltip:setDescription(description)
            end
        end
    end
    
    self.tooltip:setVisible(true)
    self.tooltip:addToUIManager()
    self.tooltip:bringToTop()
end

function PJCK_NutritionBlock:hideTooltip()
    if self.tooltip and self.tooltip:isVisible() then
        self.tooltip:removeFromUIManager()
        self.tooltip:setVisible(false)
    end
end

-- ---------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------- --

function PJCK_NutritionBlock:prerender()
    local baseItem = self.EvoPanel:getBaseItem()
    if not baseItem then return end

    -- Background
    local alpha = self:isMouseOver() and 1 or 0.8
    self:drawTextureScaled(self.bgTexture, 0, 0, self.width, self.height, alpha, 0.4, 0.4, 0.4)

    -- Icon
    local iconXY = (self.width - self.iconSize) / 2
    self:drawTextureScaled(self.icon, iconXY, iconXY, self.iconSize, self.iconSize, 1, 1, 1, 1)
    
    -- Value
    local value, displayValue = self:getValue(baseItem)
    local color = {r = 1, g = 1, b = 1}

    if value == nil or displayValue == nil then
        displayValue = "-"
        color = {r = 1, g = 1, b = 1}
    elseif self.nutritionType == "hunger" or self.nutritionType == "thirst" or 
           self.nutritionType == "boredom" or self.nutritionType == "unhappiness" then
        
        displayValue = tostring(math.abs(value))

        if value > 0 then
            color = {r = 1, g = 0.4, b = 0.4}
        else
            color = {r = 0.4, g = 1, b = 0.4}
        end
    end
    
    local textWidth = getTextManager():MeasureStringX(UIFont.NewSmall, displayValue)
    local textX = (self.width - textWidth) / 2
    local textY = math.floor(self.height * 0.74)
    self:drawText(displayValue, textX, textY, color.r, color.g, color.b, 1, UIFont.NewSmall)
end

return PJCK_NutritionBlock