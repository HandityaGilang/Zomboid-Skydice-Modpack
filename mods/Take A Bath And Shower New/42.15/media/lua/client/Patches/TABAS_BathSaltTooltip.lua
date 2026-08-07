if not TABAS_Compat.Starlit then return end

--- For Item Tooltip
local InventoryUI = require("Starlit/client/ui/InventoryUI")
if InventoryUI == nil then return end

local BathSaltDefs = require("TABAS_BathSaltDefs")
local function addBathSaltTooltip(tooltip, layout, item)
    if not item or not instanceof(item, "InventoryItem") then return end
    if not item:hasTag(TABAS_Tag.BathSalt) then return end

    local typeName = item:getType()
    if string.find(typeName, "Empty") then
        typeName = string.gsub(typeName, "Empty", "")
    end
    local def = BathSaltDefs.getDef(typeName)
    if not def then return end
    
    local key = getText("IGUI_TABAS_BathSalt_Benefits")
    local colour = {1,1,0.8,1}
    local benefitCategoty
    local text
    for i=1, #def.benefitCategories do
        benefitCategoty = def.benefitCategories[i]
        text = getText("IGUI_TABAS_BathBenefit_" .. benefitCategoty)
        InventoryUI.addTooltipKeyValue(layout, key, text, nil, colour)
        key = ""
    end
end

InventoryUI.onFillItemTooltip:addListener(addBathSaltTooltip)
