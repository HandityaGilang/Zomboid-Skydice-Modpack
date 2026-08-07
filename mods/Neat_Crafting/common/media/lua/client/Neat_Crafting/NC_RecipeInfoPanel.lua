--[[ --------------------------------------------------- --
TODO List:
1.Recipe Name and Recipe Tooltips need to be a label ,so we can set a mouseover tooltip then truncateText
-- --------------------------------------------------- --]]

require "ISUI/ISPanel"

NC_RecipeInfoPanel = ISPanel:derive("NC_RecipeInfoPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeInfoPanel:initialise()
    ISPanel.initialise(self)
end

function NC_RecipeInfoPanel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic

    o.padding = HandCraftPanel.padding/2
    o.iconSize = height *0.6

    o.skillIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Book.png")
    o.lightIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Light.png")
    o.surfaceIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Surface.png")
    o.walkIconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Walking.png")
    o.warnningIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_Warnning.png")
    o.RecipeBenefitIcon = getTexture("media/ui/Neat_Crafting/ICON/Icon_RecipeBenefit.png")

    o.skillRequirementTexture = {
        left = getTexture("media/ui/Neat_Crafting/Button/infobutton_L.png"),
        middle = getTexture("media/ui/Neat_Crafting/Button/infobutton_M.png"),
        right = getTexture("media/ui/Neat_Crafting/Button/infobutton_R.png")
    }

    o.requireIcons = {}
    o.skillRequirements = {}
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- Calculate Layout
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeInfoPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    self.iconSize = height * 0.6

    self:relayoutComponents()

    self:setWidth(width)
    self:setHeight(height)
end

function NC_RecipeInfoPanel:relayoutComponents()

    self:relayoutRequireIcons()

    self:relayoutFavouriteButton()

    if self.shortcutButton then
        self:relayoutShortcutButton()
    end

    local recipe = self.logic:getRecipe()
    if recipe then
        self:createSkillRequirementIcon(recipe)
    end
end

function NC_RecipeInfoPanel:relayoutRequireIcons()
    local statusIconSize = (self.height - (self.padding * 4)) / 4
    local iconSpacing = self.padding
    local rightMargin = self.padding
    local iconX = self.width - rightMargin - statusIconSize
    
    for i = 1, 4 do
        if self.requireIcons[i] then
            local iconY = self.padding + (i - 1) * (statusIconSize + iconSpacing)
            
            self.requireIcons[i]:setX(iconX)
            self.requireIcons[i]:setY(iconY)
            self.requireIcons[i]:setWidth(statusIconSize)
            self.requireIcons[i]:setHeight(statusIconSize)
        end
    end
end

function NC_RecipeInfoPanel:relayoutFavouriteButton()
    if self.favouriteButton then
        local buttonSize = self.height / 4
        self.favouriteButton:setX(self.padding)
        self.favouriteButton:setY(self.padding)
        self.favouriteButton:setWidth(buttonSize)
        self.favouriteButton:setHeight(buttonSize)
    end
end

function NC_RecipeInfoPanel:relayoutShortcutButton()
    if self.shortcutButton then
        local buttonSize = self.height / 4
        self.shortcutButton:setX(self.padding)
        self.shortcutButton:setY(self.height - buttonSize - self.padding)
        self.shortcutButton:setWidth(buttonSize)
        self.shortcutButton:setHeight(buttonSize)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeInfoPanel:createChildren()
    
    self:createRequireIcons()
    self:createFavouriteButton()
    if self.logic:getRecipe() then
        self:createShortcutButton()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Truncated text tooltips
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeInfoPanel:registerTruncatedTextTooltip(x, y, width, height, fullText)
    -- Store the local rectangle of text that was visually truncated this frame.
    if not fullText or fullText == "" then return end

    self.truncatedTextRegions = self.truncatedTextRegions or {}
    table.insert(self.truncatedTextRegions, {
        x = x,
        y = y,
        width = width,
        height = height,
        text = fullText
    })
end

function NC_RecipeInfoPanel:hideTruncatedTextTooltip()
    -- Remove the tooltip when the mouse leaves truncated text or the panel refreshes.
    if self.truncatedTextTooltip then
        self.truncatedTextTooltip:setVisible(false)
        self.truncatedTextTooltip:removeFromUIManager()
        self.truncatedTextTooltip = nil
        self.truncatedTextTooltipText = nil
    end
end

function NC_RecipeInfoPanel:showTruncatedTextTooltip(text)
    -- Reuse the tooltip while hovering the same truncated text.
    if not text or text == "" then return end
    if self.truncatedTextTooltip and self.truncatedTextTooltipText == text then
        return
    end

    self:hideTruncatedTextTooltip()

    self.truncatedTextTooltip = ISToolTip:new()
    self.truncatedTextTooltip:initialise()
    self.truncatedTextTooltip:instantiate()
    self.truncatedTextTooltip:setOwner(self)
    self.truncatedTextTooltip:setDescription(text)
    self.truncatedTextTooltip:addToUIManager()
    self.truncatedTextTooltip:setAlwaysOnTop(true)
    self.truncatedTextTooltip:setVisible(true)
    self.truncatedTextTooltipText = text
end

function NC_RecipeInfoPanel:updateTruncatedTextTooltip()
    -- Show the full text only when the mouse is over a text line that was actually truncated.
    if not self.truncatedTextRegions then
        self:hideTruncatedTextTooltip()
        return
    end

    local mouseX = self:getMouseX()
    local mouseY = self:getMouseY()

    for _, region in ipairs(self.truncatedTextRegions) do
        if mouseX >= region.x and mouseX <= region.x + region.width and
           mouseY >= region.y and mouseY <= region.y + region.height then
            self:showTruncatedTextTooltip(region.text)
            return
        end
    end

    self:hideTruncatedTextTooltip()
end

function NC_RecipeInfoPanel:onMouseMove(dx, dy)
    self:updateTruncatedTextTooltip()
    return true
end

function NC_RecipeInfoPanel:onMouseMoveOutside(dx, dy)
    self:hideTruncatedTextTooltip()
    return true
end

function NC_RecipeInfoPanel:createRequireIcons()
    for i = 1, 4 do
        local icon = ISImage:new(0, 0, 10, 10, self.lightIconTexture)
        icon.autoScale = true
        icon:initialise()
        icon:setVisible(false)
        self:addChild(icon)
        self.requireIcons[i] = icon
    end
end

function NC_RecipeInfoPanel:createFavouriteButton()
    self.favouriteButton = ISButton:new(0, 0, 10, 10, "", self, self.onFavouriteButtonClick)
    self.favouriteButton.displayBackground = false
    self.favouriteButton:initialise()
    self:addChild(self.favouriteButton)
    self:updateFavouriteButton()
end

function NC_RecipeInfoPanel:createSkillRequirementIcon(recipe)
    if self.skillRequirementIcon then
        self:removeChild(self.skillRequirementIcon)
        self.skillRequirementIcon = nil
    end

    if not recipe or recipe:getRequiredSkillCount() == 0 then
        return
    end
    
    local startX = self.height + self.padding
    local startY = self.padding + FONT_HGT_MEDIUM
    if recipe:getTooltip() then
        startY = startY + FONT_HGT_SMALL
    end
    if recipe:requiresSpecificWorkstation() then
        startY = startY + FONT_HGT_SMALL
    end

    local text = getText("IGUI_NC_RequiredSkills")
    local buttonWidth = getTextManager():MeasureStringX(UIFont.Small, text) + FONT_HGT_SMALL*1.5
    local buttonHeight = FONT_HGT_SMALL
    
    self.skillRequirementIcon = ISPanel:new(startX, startY, buttonWidth, buttonHeight)
    self.skillRequirementIcon:initialise()
    self.skillRequirementIcon:setVisible(true)
    self.skillRequirementIcon.tooltip = nil
    
    self.skillRequirementIcon.prerender = function(panel)
        local hasUnmetSkills = false
        local tooltipText = ""
        
        for i, skillReq in ipairs(self.skillRequirements) do
            if skillReq.isMet then
                tooltipText = tooltipText .. "<GREEN>" .. skillReq.text .. "\n"
            else
                tooltipText = tooltipText .. "<RED>" .. skillReq.text .. "\n"
                hasUnmetSkills = true
            end
        end
        
        local r, g, b = hasUnmetSkills and 1.0 or 0.3, hasUnmetSkills and 0.2 or 1.0, hasUnmetSkills and 0.2 or 0.3
        NeatTool.ThreePatch.drawHorizontal(
            panel,
            0, 0, panel.width, panel.height,
            self.skillRequirementTexture.left,
            self.skillRequirementTexture.middle,
            self.skillRequirementTexture.right,
            0.8, r * 0.5, g * 0.5, b * 0.5
        )
        local textX = panel.height
        local textY = (panel.height - FONT_HGT_SMALL) / 2
        panel:drawText(text, textX, textY, r, g, b, 1.0, UIFont.Small)
        panel.tooltipText = tooltipText
    end
    
    self.skillRequirementIcon.onMouseMove = function(panel)
        if panel:isMouseOver() and not panel.tooltip and panel.tooltipText then
            panel.tooltip = ISToolTip:new()
            panel.tooltip:initialise()
            panel.tooltip:setOwner(panel)
            panel.tooltip:setDescription(panel.tooltipText)
            panel.tooltip:addToUIManager()
            panel.tooltip:setAlwaysOnTop(true)
            panel.tooltip:setVisible(true)
        end
        return true
    end
    
    self.skillRequirementIcon.onMouseMoveOutside = function(panel)
        if panel.tooltip then
            panel.tooltip:setVisible(false)
            panel.tooltip:removeFromUIManager()
            panel.tooltip = nil
        end
        return true
    end
    
    self:addChild(self.skillRequirementIcon)
end

-- ----------------------------------------------------------------------------------------------------- --
-- For Shortcut Mod 
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeInfoPanel:createShortcutButton()
    local buttonSize = self.height / 4
    
    self.shortcutButton = ISButton:new(0, 0, buttonSize, buttonSize, "", self, NC_RecipeInfoPanel.onShortcutButtonClick)
    self.shortcutButton.borderColor.a=0
    self.shortcutButton.backgroundColor.a=0
    self.shortcutButton.backgroundColorMouseOver.a=0

    local buttonTexture = getTexture("media/ui/TheShortCut/Icon/Icon_Add.png")
    self.shortcutButton.buttonTexture = buttonTexture
    
    self.shortcutButton:initialise()
    self.shortcutButton:instantiate()
    self.shortcutButton:setVisible(false)
    self:addChild(self.shortcutButton)
    

    self.shortcutButton:setX(self.padding)
    self.shortcutButton:setY(self.height - buttonSize - self.padding)
    self.shortcutButton.render = function(button)
        if button.buttonTexture then
            local alpha = button.mouseOver and 1.0 or 0.8
            button:drawTextureScaled(button.buttonTexture, 0, 0, button:getWidth(), button:getHeight(), alpha, 1, 0.5, 0)
        end
    end

    self.shortcutButton.recipe = self.logic:getRecipe()
    self.hasShortcutButton = true
end

function NC_RecipeInfoPanel:enableShortcutButton()
    if self.shortcutButton then
        self.shortcutButton:setVisible(true)
    end
end

function NC_RecipeInfoPanel:onShortcutButtonClick()

end
-- ----------------------------------------------------------------------------------------------------- --
-- update Recipe Require
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeInfoPanel:updateRequireIcons(recipe)
    for i = 1, 4 do
        self.requireIcons[i]:setVisible(false)
    end
    
    if not recipe then return end

    local iconsToShow = {}
    
    -- need light
    if not recipe:canBeDoneInDark() then
        local tooDark = self.player:tooDarkToRead()
        table.insert(iconsToShow, {
            texture = self.lightIconTexture,
            color = tooDark and {r=1.0, g=0.2, b=0.2} or {r=1.0, g=1.0, b=1.0},
            tooltip = getText("IGUI_CraftingWindow_RequiresLight")
        })
    end

    -- need to learn recipe
    if recipe:needToBeLearn() then
        local learned = self.player:isRecipeKnown(recipe, true)
        table.insert(iconsToShow, {
            texture = self.skillIconTexture,
            color = learned and {r=1.0, g=1.0, b=1.0} or {r=1.0, g=0.2, b=0.2},
            tooltip = learned and getText("IGUI_CraftingWindow_RecipeKnown") or getText("IGUI_CraftingWindow_RequiresLearning")
        })
    end

    -- RecipeBenefit
    if recipe:couldBenefitFromRecipeAtHand(self.player) then
        if recipe:validateBenefitFromRecipeAtHand(self.player, self.logic:getContainers()) then
            table.insert(iconsToShow, {
                texture = self.RecipeBenefitIcon,
                color = {r=0.3, g=1.0, b=0.3},
                tooltip = getText("IGUI_CraftingWindow_ValidateBenefitFromRecipeAtHand")
            })
        else
            table.insert(iconsToShow, {
                texture = self.RecipeBenefitIcon,
                color = {r=1.0, g=1.0, b=0.3},
                tooltip = getText("IGUI_CraftingWindow_CouldBenefitFromRecipeAtHand")
            })
        end
    end
    
    -- Surface require
    if not recipe:isInHandCraftCraft() then
        local inRangeOfWorkbench = self.logic:isCharacterInRangeOfWorkbench()
        table.insert(iconsToShow, {
            texture = self.surfaceIconTexture,
            color = inRangeOfWorkbench and {r=1.0, g=1.0, b=1.0} or {r=1.0, g=0.2, b=0.2},
            tooltip = inRangeOfWorkbench and "Work surface available" or getText("IGUI_CraftingWindow_RequiresSurface")
        })
    end

    -- recipe can walk
    if recipe:isCanWalk() and not self.player:hasAwkwardHands() then
        table.insert(iconsToShow, {
            texture = self.walkIconTexture,
            color = {r=1.0, g=1.0, b=1.0},
            tooltip = getText("IGUI_CraftingWindow_CanWalk")
        })
    end

    for i = 1, math.min(#iconsToShow, 4) do
        local iconData = iconsToShow[i]
        local icon = self.requireIcons[i]
        icon.texture = iconData.texture
        icon:setColor(iconData.color.r, iconData.color.g, iconData.color.b)
        icon:setMouseOverText(iconData.tooltip)
        icon:setVisible(true)
    end
end

function NC_RecipeInfoPanel:updateSkillRequirements(recipe)
    self.skillRequirements = {}
    
    if not recipe or recipe:getRequiredSkillCount() == 0 then
        return
    end
    
    for i = 0, recipe:getRequiredSkillCount() - 1 do
        local requiredSkill = recipe:getRequiredSkill(i)
        local skillText = "- LV" .. tostring(requiredSkill:getLevel()) .. " " .. tostring(requiredSkill:getPerk():getName())
        local isMet = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player)
        
        table.insert(self.skillRequirements, {
            text = skillText,
            isMet = isMet,
            level = requiredSkill:getLevel(),
            perkName = requiredSkill:getPerk():getName()
        })
    end
end

function NC_RecipeInfoPanel:updateFavouriteButton()
    if not self.favouriteButton then return end
    
    local isFavourite = false
    local recipe = self.logic:getRecipe()
    if recipe then
        local favString = BaseCraftingLogic.getFavouriteModDataString(recipe)
        isFavourite = self.player:getModData()[favString] or false
    end
    
    if isFavourite then
        self.favouriteButton.image = getTexture("media/ui/Neat_Crafting/ICON/FavouriteYes.png")
        self.favouriteButton.textureColor = { 
            r = 0.8,
            g = 0.2,
            b = 0.2,
            -- r=getCore():getGoodHighlitedColor():getR(),
            -- g=getCore():getGoodHighlitedColor():getG(),
            -- b=getCore():getGoodHighlitedColor():getB(),
            a=1
        }
    else
        self.favouriteButton.image = getTexture("media/ui/Neat_Crafting/ICON/FavouriteNo.png")
        self.favouriteButton.textureColor = { r=1, g=1, b=1, a=1 }
    end
end

function NC_RecipeInfoPanel:onFavouriteButtonClick()
    if not self.logic:getRecipe() then return end

    local favString = BaseCraftingLogic.getFavouriteModDataString(self.logic:getRecipe())
    local currentFav = self.player:getModData()[favString] or false
    self.player:getModData()[favString] = not currentFav
    self:updateFavouriteButton()

    if self.HandCraftPanel.categoryPanel and self.HandCraftPanel.categoryPanel.selectedCategory == "*" then
        self.logic:filterRecipeList(self.HandCraftPanel._filterString, "*", true)
    end

    -- Sync player modData to the server in multiplayer (if the API exists)
	-- (Build 42.13.2 aligns with vanilla behavior)
    if self.player and self.player.transmitModData then
        self.player:transmitModData()
    end

end

-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeInfoPanel:onRecipeChanged()
    local recipe = self.logic:getRecipe()
    self:hideTruncatedTextTooltip()
    self:updateRequireIcons(recipe)
    self:updateSkillRequirements(recipe)
    self:createSkillRequirementIcon(recipe)
    self:updateFavouriteButton()
    if self.shortcutButton and self.shortcutButton:isVisible() then
        self.shortcutButton.recipe = recipe
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_RecipeInfoPanel:prerender()
    -- Refresh hover regions before drawing the current recipe text.
    self.truncatedTextRegions = {}

    -- Draw Background
    local panelBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/InnerPanel_BG.png")
    if panelBG then
        panelBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, NCConfig.innerBackgroundAlpha)
    end
    self:drawRect(self.height, self.padding * 2, 1, self.height - self.padding * 4, 0.3, 0.5, 0.5, 0.5)

    local recipe = self.logic:getRecipe()
    local nameX = self.height + self.padding
    local statusIconArea = (self.height - (self.padding*4 ))/3 + self.padding
    local maxWidth = self.width - nameX - statusIconArea
    local startY = self.padding
    if recipe then
        -- Draw RecipeIcon
        local iconXY = (self.height - self.iconSize) / 2
        self:drawTextureScaledAspect(recipe:getIconTexture(), iconXY, iconXY, self.iconSize, self.iconSize, 1.0, 1.0, 1.0, 1.0)
        
        -- Draw RecipeName
        local recipeName = recipe:getTranslationName()
        local displayName = NeatTool.truncateText(recipeName, maxWidth, UIFont.Medium, "...")
        self:drawText(displayName, nameX, startY, 1.0, 1.0, 1.0, 1.0, UIFont.Medium)
        if displayName ~= recipeName then
            self:registerTruncatedTextTooltip(nameX, startY, getTextManager():MeasureStringX(UIFont.Medium, displayName), FONT_HGT_MEDIUM, recipeName)
        end
        startY = startY + FONT_HGT_MEDIUM

        -- Draw Tooltips Text
        if recipe:getTooltip() then
            local recipetext = getText(recipe:getTooltip())
            local displayTooltip = NeatTool.truncateText(recipetext, maxWidth, UIFont.Small, "...")
            self:drawText(displayTooltip, nameX, startY, 0.6, 0.6, 0.6, 1.0, UIFont.Small)
            if displayTooltip ~= recipetext then
                self:registerTruncatedTextTooltip(nameX, startY, getTextManager():MeasureStringX(UIFont.Small, displayTooltip), FONT_HGT_SMALL, recipetext)
            end
            startY = startY + FONT_HGT_SMALL
        end

        -- require Specific Workstation
        if recipe:requiresSpecificWorkstation() then
            local workstationText = getText("IGUI_CraftingWindow_RequiresA")
            local moreThanOne = recipe:getTags():size() > 1
            
            for i = 0, recipe:getTags():size() - 1 do
                local tag = recipe:getTags():get(i)
                workstationText = workstationText .. " " .. getText("IGUI_CraftingWindow_" .. tag)
                if moreThanOne and i < recipe:getTags():size() - 1 then
                    if i < recipe:getTags():size() - 2 then
                        workstationText = workstationText .. ","
                    else
                        workstationText = workstationText .. " " .. getText("IGUI_CraftingWindow_Or")
                    end
                end
            end
            workstationText = workstationText .. "."
            
            local hasWorkstation = self.logic:hasRequiredWorkstation()
            local r, g, b = hasWorkstation and 0.3 or 1.0, hasWorkstation and 1.0 or 0.2, hasWorkstation and 0.3 or 0.2
            
            local displayWorkstation = NeatTool.truncateText(workstationText, maxWidth, UIFont.Small, "...")
            self:drawText(displayWorkstation, nameX, startY, r, g, b, 1.0, UIFont.Small)
            startY = startY + FONT_HGT_SMALL
        end
    end
end

return NC_RecipeInfoPanel