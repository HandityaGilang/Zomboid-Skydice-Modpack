-- Draw icon overlays for science-related items:
-- Gray "R": unread science books / unresearched specimens (Science XP available)
-- Green tick: researched specimens (optional)
require "ZScienceSkill/Data"
require "ZScienceSkill_ModOptions"

local TEX_R    = getTexture("media/ui/R_Mark_Gray.png")
local TEX_TICK = getTexture("media/ui/Tick_Mark-10.png")

zdk.hook({
    ISInventoryPane = {
        renderdetails = function(orig, self, doDragged, ...)
            orig(self, doDragged, ...)

            if not doDragged then return end

            local player = getSpecificPlayer(self.player)
            if not player then return end

            local showOverlay = ZScienceSkillOptions.isOverlayEnabled()
            local showCheckmark = ZScienceSkillOptions.isResearchedCheckmarkEnabled()
            
            if not showOverlay and not showCheckmark then return end

            local YSCROLL = self:getYScroll()
            local HEIGHT = self:getHeight()

            local y = 0
            for _, v in ipairs(self.items) do
                local item = v.items and v.items[1] or v
                local status = ZScienceSkill.getItemStatus(item, player)
                if status then
                    local texture = nil
                    if status.researched == status.total then
                        -- already fully researched, show checkmark if enabled
                        if showCheckmark then
                            texture = TEX_TICK
                        end
                    else
                        -- not fully researched, show "R" if enabled
                        if showOverlay then
                            texture = TEX_R
                        end
                    end

                    if texture then
                        local topOfItem = y * self.itemHgt + YSCROLL
                        if topOfItem + self.itemHgt >= 0 and topOfItem <= HEIGHT then
                            local xoff = 0
                            local yoff = 0
                            local texWH = math.min(self.itemHgt - 2, 32)
                            local auxDXY = self.itemHgt - (self.itemHgt - texWH) / 2 - 13
                            local texOffsetY = (y * self.itemHgt) + (self.itemHgt - texWH) / 2 + self.headerHgt + yoff
                            local texOffsetX = self.column2 - texWH - (self.itemHgt - texWH) / 2 + xoff

                            self:drawTexture(texture, texOffsetX + auxDXY, texOffsetY + auxDXY - 1, 1, 1, 1, 1)
                        end
                    end
                end -- if status
                y = y + 1
            end -- for
        end -- renderdetails
    } -- ISInventoryPane
}) -- zdk.hook
