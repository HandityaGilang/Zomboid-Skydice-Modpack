-- Add "Researchable" / "Already Researched" text to item tooltips
require "ISUI/ISToolTipInv"
require "ZScienceSkill/Data"
require "ZScienceSkill_ModOptions"

zdk.hook({
    ISToolTipInv = {
        render = function(orig, self, ...)
            orig(self, ...)

            -- sanity
            if not self.item then return end
        
            -- Check if tooltip option is enabled
            if not ZScienceSkillOptions.isTooltipEnabled() then return end

            -- Check if item is researchable
            local status = ZScienceSkill.getItemStatus(self.item, getSpecificPlayer(0))
            if not status then return end -- not researchable
            
            local alreadyDone = status.researched == status.total
            
            -- Choose text and color
            local text, r, g, b
            if alreadyDone then
                text = getText("IGUI_AlreadyResearched") or "Already Researched"
                r, g, b = 0.5, 0.7, 0.5  -- Muted green
            else
                text = getText("IGUI_Researchable") or "Researchable"
                r, g, b = 0.6, 0.8, 1.0  -- Light blue
            end
            
            -- Draw text above the tooltip
            local textW = getTextManager():MeasureStringX(UIFont.Small, text)
            local textH = getTextManager():MeasureStringY(UIFont.Small, text)
            local x = self.tooltip:getX() + self.tooltip:getWidth() / 2 - textW / 2
            local y = self.tooltip:getY() - textH - 2
            
            self:drawText(text, x - self:getX(), y - self:getY(), r, g, b, 1.0, UIFont.Small)
        end -- render
    } -- ISToolTipInv
}) -- zdk.hook
