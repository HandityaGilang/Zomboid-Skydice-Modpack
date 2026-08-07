local Reflection = require("Starlit/utils/Reflection")
local UI_BORDER_SPACING = 10
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_HEADING = getTextManager():getFontHeight(UIFont.Small)
local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 19; -- normalize to 1080p
local ICON_SCALE = math.max(1, (FONT_SCALE - math.floor(FONT_SCALE)) < 0.5 and math.floor(FONT_SCALE) or math.ceil(FONT_SCALE));
local LIST_ICON_SIZE = 32 * ICON_SCALE;
local LIST_SUBICON_SIZE = 16 * ICON_SCALE
local LIST_FAVICON_SIZE = 10 * ICON_SCALE
local LIST_SUBICON_SPACING = 2 * ICON_SCALE

function ISRecipeScrollingListBox:doDrawNode(y, item, _alt)
    local craftRecipe = item and item.item;
    local isInGroup = item and item.node and item.node:getParent() ~= nil;
    local xOffset = isInGroup and SUBCATEGORY_INDENT or 0;
    
    if craftRecipe then
        local favString = BaseCraftingLogic.getFavouriteModDataString(craftRecipe);
        local isFavourite = self.player:getModData()[favString] or false;

        local yActual = self:getYScroll() + y;
        if item.cachedHeight and (yActual > self.height or (yActual + item.cachedHeight) < 0) then
            -- we are outside stencil, dont draw, just return cachedHeight
            return y + item.cachedHeight;
        end

        if not item.height then item.height = self.itemheight end -- compatibililty
        local safeDrawWidth = self:getWidth() - (self.vscroll and self.vscroll:getWidth() or 0) - xOffset;

        local cheat = self.player:isBuildCheat()

        -- set colours
        local color = self:isCraftable(craftRecipe) and {r=1.0, g=1.0, b=1.0, a=1.0} or {r=0.5, g=0.5, b=0.5, a=1.0};

        if self.selected == item.index then
            self:drawSelection(0, y, self:getWidth(), item.height-1);
        elseif (self.mouseoverselected == item.index) and self:isMouseOver() and not self:isMouseOverScrollBar() then
            self:drawMouseOverHighlight(0, y, self:getWidth(), item.height-1);
        end

        self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b);

        local colGood = {
            r=getCore():getGoodHighlitedColor():getR(),
            g=getCore():getGoodHighlitedColor():getG(),
            b=getCore():getGoodHighlitedColor():getB(),
            a=getCore():getGoodHighlitedColor():getA(),
        }
        local colBad = {
            r=getCore():getBadHighlitedColor():getR(),
            g=getCore():getBadHighlitedColor():getG(),
            b=getCore():getBadHighlitedColor():getB(),
            a=getCore():getBadHighlitedColor():getA(),
        }

        if cheat then
            colBad = colGood;
        end

        local detailsLeft = UI_BORDER_SPACING + LIST_ICON_SIZE + UI_BORDER_SPACING + xOffset;
        --local detailsCentre = detailsLeft + ((safeDrawWidth - detailsLeft) / 2);
        local detailsY = 4;

        -- icons

        --if the image display size is 16x16, then this will automatically grab the 16x16 version
        local fileSize = ".png"
        if LIST_SUBICON_SIZE == 16 then
            fileSize = "_16.png"
        end

        local iconRight = safeDrawWidth - UI_BORDER_SPACING - (LIST_SUBICON_SIZE/2) - LIST_SUBICON_SPACING;
        if craftRecipe:isCanWalk() then
            local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Walking" .. fileSize);
            self:drawTextureScaledAspect(iconTexture, iconRight, y +detailsY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, color.a, color.r, color.g, color.b);
            iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING;
        end
        if not craftRecipe:canBeDoneInDark() and not self.ignoreLightIcon then
            --local iconTexture = getTexture("media/ui/craftingMenus/Icon_Moon_48x48.png");
            local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Light" .. fileSize);
            self:drawTextureScaledAspect(iconTexture, iconRight, y +detailsY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, color.a, color.r, color.g, color.b);
            iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING;
        end
        if craftRecipe:needToBeLearn() then
            local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Book" .. fileSize);
            local alpha = 1;
            if not self.player:isRecipeKnown(craftRecipe, true) then
                alpha = 0.5;
            end
            self:drawTextureScaledAspect(iconTexture, iconRight, y +detailsY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, alpha, color.r, color.g, color.b);
            iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING;
        end
        if not craftRecipe:isInHandCraftCraft() and not self.ignoreSurface then
            local iconTexture = getTexture("media/ui/craftingMenus/BuildProperty_Surface" .. fileSize);
            self:drawTextureScaledAspect(iconTexture, iconRight, y +detailsY, LIST_SUBICON_SIZE, LIST_SUBICON_SIZE, color.a, color.r, color.g, color.b);
            iconRight = iconRight - LIST_SUBICON_SIZE - LIST_SUBICON_SPACING;
        end

        -- header
        local headerAdj = (LIST_SUBICON_SIZE - FONT_HGT_HEADING) / 2;
        detailsY = detailsY + headerAdj;
        local maxTitleWidth = (iconRight - detailsLeft) - (UI_BORDER_SPACING + LIST_SUBICON_SIZE + LIST_SUBICON_SPACING); -- current gap, minus space for Favicon
        local titleStr = getTextManager():WrapText(UIFont.Small, craftRecipe:getTranslationName(), maxTitleWidth, 2, "...");
        if craftRecipe:getXPAwardCount() > 0 then
                titleStr = titleStr .. "\n"
                for i = 0, 100 do
                    local XPAward = craftRecipe:getXPAward(i)
                    if not XPAward then break end
                    local skill = Reflection.getField(XPAward, "perk")
                    local exp = Reflection.getField(XPAward, "amount")
                    titleStr =  titleStr .. "[" .. tostring(skill) .. "(+" .. exp .. ")]"
                end
            end
        if isDebugEnabled() then
            local tags = "";
            for i=0,craftRecipe:getTags():size() -1 do
                tags = tags .. craftRecipe:getTags():get(i);
                if i < craftRecipe:getTags():size()-1 then
                    tags = tags .. ",";
                end
            end
            --titleStr = titleStr .. " ( DBG:" .. craftRecipe:getTags() .. ")";
            titleStr = titleStr .. "\n (tags: " .. tags .. ")";
        end
        self:drawText(titleStr, detailsLeft, y +detailsY, color.r, color.g, color.b, color.a, UIFont.Small);

        local headerTextHeight = getTextManager():MeasureStringY(UIFont.Small, titleStr);
        detailsY = detailsY + headerTextHeight;

        -- description
        if craftRecipe:getTooltip() then
            local text = getText(craftRecipe:getTooltip());
            if self.wrapTooltipText then
                local tooltipAvailableWidth = (safeDrawWidth - detailsLeft) - (UI_BORDER_SPACING*2 + LIST_SUBICON_SPACING);
                text = text:gsub("\n", " ");    -- remove existing tooltip newlines before resplitting. This seems to be generally better for our use case - spurcival
                text = getTextManager():WrapText(UIFont.Small, text, tooltipAvailableWidth)
            end
            self:drawText(text, detailsLeft, y +detailsY, 0.5, 0.5, 0.5, color.a, UIFont.Small);
            -- add more space for each <br> (which are turned into \n)
            local split = luautils.split(text, "\n");
            for i,v in ipairs(split) do
                detailsY = detailsY + FONT_HGT_SMALL;
            end
        end

        -- skill
        if craftRecipe:getRequiredSkillCount()>0 then
            for i=0,craftRecipe:getRequiredSkillCount()-1 do
                local requiredSkill = craftRecipe:getRequiredSkill(i);
                local hasSkill = CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player);
                local lineColor = hasSkill and colGood or colBad;

                local text = getText("IGUI_CraftingWindow_Requires2").." ".. tostring(requiredSkill:getPerk():getName()).." "..getText("IGUI_CraftingWindow_Level").." " .. tostring(requiredSkill:getLevel());
                self:drawText(text, detailsLeft, y +detailsY, lineColor.r, lineColor.g, lineColor.b, lineColor.a, UIFont.Small);
                detailsY = detailsY + FONT_HGT_SMALL;
            end
        end

        local usedHeight = math.max(self.itemheight, detailsY + UI_BORDER_SPACING)
        if isFavourite then
            usedHeight = math.max(usedHeight, LIST_ICON_SIZE + (LIST_FAVICON_SIZE/2));
        end

        item.height = usedHeight;
        item.cachedHeight = usedHeight;

        -- draw icon mid-high
        local iconY = y + (usedHeight/2)-(LIST_ICON_SIZE/2);
        local texture = craftRecipe:getIconTexture()
        self:drawTextureScaledAspect(texture, UI_BORDER_SPACING + xOffset, iconY, LIST_ICON_SIZE, LIST_ICON_SIZE, color.a, color.r, color.g, color.b);

        -- favourite button
        local starIconY = iconY + (LIST_ICON_SIZE) - (LIST_FAVICON_SIZE);
        if isFavourite then
            self:drawTextureScaledAspect(self.starSetTexture, UI_BORDER_SPACING + xOffset, starIconY, LIST_FAVICON_SIZE, LIST_FAVICON_SIZE, color.a, getCore():getGoodHighlitedColor():getR(), getCore():getGoodHighlitedColor():getG(), getCore():getGoodHighlitedColor():getB());
        end

        return y + usedHeight;
    end
    return y;
end