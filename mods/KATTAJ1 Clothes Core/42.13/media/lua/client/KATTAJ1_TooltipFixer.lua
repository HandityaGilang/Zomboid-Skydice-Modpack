require "ISUI/ISToolTipInv"
print("Loading Custom ToolTip Override Code")
local old_ISToolTipInv_render = ISToolTipInv.render
function ISToolTipInv:render()
    local item = self.item
    local player = getPlayer()
    if item and instanceof( item, "Clothing") and item:getBodyLocation() and  player:getWornItem(item:getBodyLocation())
    and instanceof(  player:getWornItem(item:getBodyLocation()), "InventoryContainer") then
        print("Overriding Vanilla ToolTip")
        return false 
    end
    -- print("Using Vanilla ToolTip")
    old_ISToolTipInv_render(self)
end