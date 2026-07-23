--[[
    Author: Konijima
    Made for AuthenticPeach and the community.
    Date: 15/02/2022

    Fixes containers that get attached and dettached from the hotbar.
	Keeps the correct inventory weight
]]

require "ISUI/ISInventoryPage"

if ISInventoryPage and ISInventoryPage.loadWeight and not ISInventoryPage.AZB42ContainerWeightFix then
    ISInventoryPage.AZB42ContainerWeightFix = true

    local vanillaLoadWeight = ISInventoryPage.loadWeight

    function ISInventoryPage.loadWeight(inv)
    if inv and inv.getContainingItem and inv:getContainingItem() and inv.getParent and inv:getParent() and inv.setParent then
        inv:setParent(nil)
        end
        return vanillaLoadWeight(inv)
    end
end
