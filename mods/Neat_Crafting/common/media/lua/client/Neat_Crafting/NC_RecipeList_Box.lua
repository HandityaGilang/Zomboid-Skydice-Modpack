require "ISUI/ISUIElement"

NC_RecipeList_Box = ISUIElement:derive("NC_RecipeList_Box")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- Before TIS allow us access xpAward , if you try to make a mod show the xpAward, Please require "Starlit Library"
-- I copy the key code just for test
 local function getFieldValue(object, fieldName)
    if not object then return nil end
    
    for i = 0, getNumClassFields(object) - 1 do
        local field = getClassField(object, i)
        local currentFieldName = string.match(tostring(field), "([^%.]+)$")
        
        if currentFieldName == fieldName then
            return getClassFieldVal(object, field)
        end
    end
    
    return nil
end

-- ---------------------------------------------------------- --
-- initialise
-- ---------------------------------------------------------- --

function NC_RecipeList_Box:initialise()
    ISUIElement.initialise(self)
    
end

function NC_RecipeList_Box:new(x, y, width, height, recipe, parentPanel)
    local o = ISUIElement:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.recipe = recipe
    o.parentPanel = parentPanel
    o.player = parentPanel.player
    o.logic = parentPanel.HandCraftPanel.logic
    o.canMakeRecipe = true
    o.entryType = "recipe"
    o.node = nil
    o.depth = 0

    o.iconSize = math.floor((height*0.8) /16)*16
    o.padding = parentPanel.padding / 2
    o.iconAreaSize = height

    o.skillTexts = {}
    o.xpTexts = {}
    o.statusIconSize = FONT_HGT_SMALL * 0.6
    
    o.skillIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Book_16.png")
    o.lightIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Light_16.png")
    o.surfaceIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Surface_16.png")
    o.walkIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Walking_16.png")
    o.favouriteIcon = getTexture("media/ui/Neat_Crafting/ICON/FavouriteYes.png")
    o.groupOpenTexture = getTexture("media/ui/Icon_RecipeGroup_Open_48x48.png")
    o.groupPartialTexture = getTexture("media/ui/Icon_RecipeGroup_Partial_48x48.png")
    o.groupClosedTexture = getTexture("media/ui/Icon_RecipeGroup_Closed_48x48.png")
    
    return o
end

-- ---------------------------------------------------------- --
-- createChildren
-- ---------------------------------------------------------- --

function NC_RecipeList_Box:createChildren()
    local rightMargin = self.padding
    local textX = self.iconAreaSize + self.padding
    local textY = self.padding
    self.maxTextWidth = self.width - textX - (self.statusIconSize + rightMargin + self.padding)
    local defaultText = ""
    self.nameLabel = ISLabel:new(textX, textY, FONT_HGT_SMALL, defaultText, 1.0, 1.0, 1.0, 1.0, UIFont.Small, true)
    self.nameLabel:initialise()
    self:addChild(self.nameLabel)
end

-- ---------------------------------------------------------- --
-- Set new recipe
-- ---------------------------------------------------------- --

function NC_RecipeList_Box:getEntryIndentOffset()
    return math.max(0, self.depth or 0) * math.floor(self.iconAreaSize * 0.45)
end

function NC_RecipeList_Box:updateLabelLayout()
    local indentOffset = self:getEntryIndentOffset()
    local textX = self.iconAreaSize + self.padding + indentOffset
    self.maxTextWidth = self.width - textX - (self.statusIconSize + self.padding * 2)
    if self.nameLabel then
        if self.nameLabel.setX then
            self.nameLabel:setX(textX)
        else
            self.nameLabel.x = textX
        end
    end
end

function NC_RecipeList_Box:setEntry(entry, canMake)
    if entry and type(entry) == "table" and entry.entryType then
        local entryCanMake = entry.canMake
        self.entryType = entry.entryType
        self.node = entry.node
        self.depth = entry.depth or 0

        if entry.entryType == "group" then
            self.recipe = nil
            self.canMakeRecipe = entryCanMake ~= false
            self.skillTexts = {}
            self:updateLabelLayout()

            local groupTitle = (self.node and self.node.getTitle) and self.node:getTitle() or "Group"
            local displayName = NeatTool.truncateText(groupTitle, self.maxTextWidth, UIFont.Small, "...")
            self.nameLabel:setName(displayName)
            self.nameLabel.a = self.canMakeRecipe and 1.0 or 0.7
            return
        end

        entry = entry.recipe
        if type(canMake) ~= "boolean" then
            canMake = entryCanMake
        end
    end

    self.entryType = "recipe"
    self.node = nil
    self.recipe = entry
    self.canMakeRecipe = canMake
    self.depth = (type(self.depth) == "number") and self.depth or 0

    self:updateLabelLayout()

    local recipeName = ""
    if self.recipe then
        recipeName = self.recipe:getTranslationName()
        recipeName = NeatTool.truncateText(recipeName, self.maxTextWidth, UIFont.Small, "...")
    end
    self.nameLabel:setName(recipeName)
    self.nameLabel.a = self.canMakeRecipe and 1.0 or 0.5

    self:updateSkillTexts()
end

function NC_RecipeList_Box:setRecipe(recipe, canMake)
    self.depth = 0
    self:setEntry({ entryType = "recipe", recipe = recipe, depth = 0, canMake = canMake })
end

-- ---------------------------------------------------------- --
-- Update skill text content
-- ---------------------------------------------------------- --

function NC_RecipeList_Box:updateSkillTexts()
    self.skillTexts = {}

    if self.entryType ~= "recipe" or not self.recipe or self.recipe:getRequiredSkillCount() == 0 then return end

    for i = 0, self.recipe:getRequiredSkillCount() - 1 do
        local requiredSkill = self.recipe:getRequiredSkill(i)
        local skillText = "LV"..tostring(requiredSkill:getLevel()) .." ".. tostring(requiredSkill:getPerk():getName())
        local truncatedSkillText = NeatTool.truncateText(skillText, self.maxTextWidth, UIFont.Small, "...")

        local isMet = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player)
        
        table.insert(self.skillTexts, {
            text = truncatedSkillText,
            isMet = isMet
        })
    end
end

-- Before TIS allow us access xpAward , if you try to make a mod show the xpAward, Please require "Starlit Library"
-- I copy the key code just for test
--[[
function NC_RecipeList_Box:updateSkillTexts()
    self.skillTexts = {}
    self.unmatchedXPTexts = {}

    if not self.recipe then return end

    -- Get XP rewards
    local xpAwards = {}
    if self.recipe:getXPAwardCount() > 0 then
        for i = 0, self.recipe:getXPAwardCount() - 1 do
            local xpAward = self.recipe:getXPAward(i)
            if xpAward then
                local amount = getFieldValue(xpAward, "amount") or 0
                local perk = getFieldValue(xpAward, "perk")
                if perk then
                    xpAwards[perk] = amount
                end
            end
        end
    end

    -- Handle skill requirements
    if self.recipe:getRequiredSkillCount() > 0 then
        for i = 0, self.recipe:getRequiredSkillCount() - 1 do
            local requiredSkill = self.recipe:getRequiredSkill(i)
            local skillPerk = requiredSkill:getPerk()
            local skillName = skillPerk:getName()
            local level = requiredSkill:getLevel()

            local xpAmount = xpAwards[skillPerk]
            local skillText
            if xpAmount then
                skillText = "LV" .. level .. "(+" .. xpAmount .. ") " .. skillName
                xpAwards[skillPerk] = nil
            else
                skillText = "LV" .. level .. " " .. skillName
            end
            
            skillText = NeatTool.truncateText(skillText, self.maxTextWidth, UIFont.Small, "...")
            local isMet = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player)
            
            table.insert(self.skillTexts, {
                text = skillText,
                isMet = isMet
            })
        end
    end

    -- Handle remaining XP rewards (no matching skill requirement)
    for perk, amount in pairs(xpAwards) do
        local xpText = "+ " .. amount .. " XP " .. perk:getName()
        xpText = NeatTool.truncateText(xpText, self.maxTextWidth, UIFont.Small, "...")
        table.insert(self.unmatchedXPTexts, {
            text = xpText,
            amount = amount
        })
    end
end
]]

-- ---------------------------------------------------------- --
-- Mouse function
-- ---------------------------------------------------------- --

function NC_RecipeList_Box:onMouseMove()
    return true
end

function NC_RecipeList_Box:onMouseMoveOutside()
    return true
end

function NC_RecipeList_Box:onMouseDown()
    getSoundManager():playUISound("UIActivateButton")

    if self.entryType == "group" then
        self.parentPanel:toggleGroupNode(self.node)
        return true
    end

    if not self.recipe then return true end
    local handCraftPanel = self.parentPanel.HandCraftPanel
    handCraftPanel.logic:setRecipe(self.recipe)
    return true
end

function NC_RecipeList_Box:onMouseUp()
    return true
end

-- ---------------------------------------------------------- --
-- Render
-- ---------------------------------------------------------- --

function NC_RecipeList_Box:prerender()
    local bgAlpha = self.canMakeRecipe and 1.0 or 0.5
    local r,g,b = 0.15, 0.15, 0.15
    if self:isMouseOver() then
        r,g,b = 0.2, 0.2, 0.2
    end
    local sloticon = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_IconSide.png")
    local slotleft = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBG_LEFT.png")
    if sloticon and slotleft then
        sloticon:render(self:getAbsoluteX(), self:getAbsoluteY(), self.height, self.height, r, g, b, bgAlpha)
        slotleft:render(self:getAbsoluteX()+self.height, self:getAbsoluteY(), self.width - self.height, self.height, r, g, b, bgAlpha)
    end

    local handCraftPanel = self.parentPanel and self.parentPanel.HandCraftPanel
    if handCraftPanel.logic:getRecipe() == self.recipe then
        r,g,b = 0.8, 0.5, 0.2
        bgAlpha = 1.0
    else
        r,g,b = 0.2, 0.2, 0.2
    end

    local slotboarder = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Button/SlotBoarder.png")
    if slotboarder then
        slotboarder:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, r, g, b, bgAlpha)
    end
end

function NC_RecipeList_Box:render()

    local indentOffset = self:getEntryIndentOffset()
    local iconAreaX = indentOffset
    local iconAreaY = 0
    local iconAreaSize = self.iconAreaSize

------ Draw RecipeIcon   ----------------------------------------------------------------------------------
    if self.entryType == "group" and self.node then
        local groupIcon = self.node:getIconTexture()
        if groupIcon then
            local iconAlpha = self.canMakeRecipe and 1.0 or 0.6
            local iconX = iconAreaX + (iconAreaSize - self.iconSize) / 2
            local iconY = iconAreaY + (iconAreaSize - self.iconSize) / 2
            self:drawTextureScaledAspect(groupIcon, iconX, iconY, self.iconSize, self.iconSize, iconAlpha, 1, 1, 1)
        end

        local groupStateTexture = self.groupClosedTexture
        if self.node:getExpandedState() == CraftRecipeListNodeExpandedState.OPEN then
            groupStateTexture = self.groupOpenTexture
        elseif self.node:getExpandedState() == CraftRecipeListNodeExpandedState.PARTIAL then
            groupStateTexture = self.groupPartialTexture
        end

        if groupStateTexture then
            local arrowSize = math.floor(self.height * 0.4)
            local arrowX = iconAreaX + self.padding
            local arrowY = (self.height - arrowSize) / 2
            self:drawTextureScaledAspect(groupStateTexture, arrowX, arrowY, arrowSize, arrowSize, 1, 1, 1, 1)
        end
        return
    end
    
    if self.recipe then
        local recipeIcon = self.recipe:getIconTexture()
        if recipeIcon then
            local Alpha = self.canMakeRecipe and 1.0 or 0.5

            local IconX = iconAreaX + (iconAreaSize - self.iconSize) / 2
            local IconY = iconAreaY + (iconAreaSize - self.iconSize) / 2
            
            self:drawTextureScaledAspect(recipeIcon, IconX, IconY, self.iconSize, self.iconSize, Alpha, 1, 1, 1)
        end

        local favString = BaseCraftingLogic.getFavouriteModDataString(self.recipe)
        if self.player:getModData()[favString] then
            local favIconSize = math.floor(self.height / 5)
            local favIconX = iconAreaX + self.padding
            local favIconY = iconAreaY + iconAreaSize - favIconSize - self.padding
            -- i dont like green heart or star :( 
            -- If change the GoodHighlitedColor, it'll also change the color for everything that means "YES."
            self:drawTextureScaledAspect(
                self.favouriteIcon, 
                favIconX, 
                favIconY, 
                favIconSize, 
                favIconSize, 
                1,0.8,0.2,0.2
                -- getCore():getGoodHighlitedColor():getR(),
                -- getCore():getGoodHighlitedColor():getG(),
                -- getCore():getGoodHighlitedColor():getB()
                )
        end
        
---------- Draw SkillsTexts  --------------------------------------------------------------------------------
        if #self.skillTexts > 0 then
            local textX = self.iconAreaSize + self.padding + indentOffset
            local textY = self.padding + FONT_HGT_SMALL
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            local zoomScale = 0.8
            
            for i = 1, math.min(#self.skillTexts,2) do
                local skillData = self.skillTexts[i]
                local r, g, b = skillData.isMet and 0.2 or 1.0, skillData.isMet and 0.8 or 0.2, 0.2
                
                self:drawTextZoomed(skillData.text, textX, textY, zoomScale, r, g, b, alpha, UIFont.Small)
                textY = textY + FONT_HGT_SMALL * zoomScale
            end
        end
        -- Before TIS allow us access xpAward , if you try to make a mod show the xpAward, Please require "Starlit Library"
        -- I copy the key code just for test
        --[[
        if #self.unmatchedXPTexts > 0 then
            local textX = self.iconAreaSize + self.padding
            local textY = self.padding + FONT_HGT_SMALL
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            local zoomScale = 0.8

            if #self.skillTexts > 0 then
                textY = textY + (#self.skillTexts * FONT_HGT_SMALL * zoomScale)
            end
            
            for i = 1, #self.unmatchedXPTexts do
                local xpData = self.unmatchedXPTexts[i]
                local r, g, b = 0.2, 1.0, 0.2
                
                self:drawTextZoomed(xpData.text, textX, textY, zoomScale, r, g, b, alpha, UIFont.Small)
                textY = textY + FONT_HGT_SMALL * zoomScale
            end
        end
        ]]
---------- Draw StatusIcon  --------------------------------------------------------------------------------
        local rightMargin = self.padding
        local iconsToShow = {}

        -- canBeDoneInDark
        if not self.recipe:canBeDoneInDark() then
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            table.insert(iconsToShow, {texture = self.lightIconTexture, alpha = alpha})
        end

        -- needToBeLearn
        if self.recipe:needToBeLearn() then
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            table.insert(iconsToShow, {texture = self.skillIconTexture, alpha = alpha})
        end

        -- need surface
        if not self.recipe:isInHandCraftCraft() then
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            table.insert(iconsToShow, {texture = self.surfaceIconTexture, alpha = alpha})
        end

        -- can walk
        if self.recipe:isCanWalk() and not self.player:hasAwkwardHands() then
            local alpha = self.canMakeRecipe and 1.0 or 0.5
            table.insert(iconsToShow, {texture = self.walkIconTexture, alpha = alpha})
        end

        local iconX = self.width - rightMargin - self.statusIconSize
        local availableHeight = self.height - self.padding * 2
        local totalIconsHeight = 3 * self.statusIconSize
        local iconSpacing = (availableHeight - totalIconsHeight) / 2

        for i = 1, #iconsToShow do
            local icon = iconsToShow[i]
            local iconY = self.padding + (i - 1) * (self.statusIconSize + iconSpacing)
            self:drawTextureScaled(icon.texture, iconX, iconY, self.statusIconSize, self.statusIconSize, icon.alpha, 1, 1, 1)
        end
    end
end

return NC_RecipeList_Box