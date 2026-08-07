
if not ISLootZed or not ISLootZed.drawDatas then return end

local uldd = ISLootZed.drawDatas
function ISLootZed:drawDatas(y, item, alt)
    local modified_y = uldd(self, y, item, alt)
    if y + self:getYScroll() + self.itemheight < 0 or y + self:getYScroll() >= self.height then
        return modified_y
    end
    
    local scriptItem = getScriptManager():FindItem(item.text)
    if scriptItem ~= nil then
        local icon = scriptItem:getIcon()
        if scriptItem:getIconsForTexture() and not scriptItem:getIconsForTexture():isEmpty() then
            icon = scriptItem:getIconsForTexture():get(0)
        end
        if icon then
            local texture = getTexture("Item_" .. icon)
            if not texture then
                local texture = tryGetTexture("Item_" .. icon)
                if texture then
                    local iconX = 4
                    local iconSize = getTextManager():getFontHeight(UIFont.Small);
                    self:drawTextureScaledAspect2(texture, self.columns[2].size + iconX, y + (self.itemheight - iconSize) / 2, iconSize, iconSize,  1, 1, 1, 1);
                end
            end
        end
    end
    
    return modified_y
end
