CL = CL or {}
local timedActionAdd = function(data,location,obj)
    local adjacent = AdjacentFreeTileFinder.Find(location,getPlayer())
    if adjacent ~= nil then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(getPlayer(), adjacent))
        ISTimedActionQueue.add(ISPlaceWiresAction:new(getPlayer(),location, 200,obj,data,CL.setProps))
    end
end

local timedActionRemove = function(obj)
    local adjacent = AdjacentFreeTileFinder.Find(obj:getSquare(),getPlayer())
    if adjacent ~= nil then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(getPlayer(), adjacent))
        ISTimedActionQueue.add(ISRemoveWiresAction:new(getPlayer(),obj:getSquare(), 200,obj,CL.removewire))
    end
end



CL.RemoveWireContext = function(player, context, worldobjects)
    for _,i in pairs(worldobjects) do
        local obj = i
        local textureName = obj:getTextureName();
        if CL.reverseCraftSwapNames[textureName] or CL.wireNames[textureName] then
            CLDebug("WiresFound in context")
            local wireOption = context:addOption(getText("ContextMenu_RemoveLine"),obj,timedActionRemove)
            break
        end

    end
end

CL.addWireContext = function(player, context, worldobjects)
    local clToBuild = CL.searchForClotheslines(worldobjects)
    if clToBuild then
        local inventory = getPlayer():getInventory()
        if inventory:containsTypeRecurse("Base.Wire") then
            local data = CL.searchForClotheslinesArray(clToBuild)
           if not  data then return end
            local wires = inventory:getUsesTypeRecurse("Base.Wire")
            if wires then
                    --option.notAvailable
                    local wireOption = context:addOption(getText("ContextMenu_AddLine"),data,timedActionAdd,clToBuild:getSquare(),clToBuild)
                if wires < #data[1]+#data[2]  then
                    wireOption.notAvailable = true
                    wireOption.toolTip = ISToolTip:new()
                    wireOption.toolTip:initialise()
                    wireOption.toolTip:setVisible(true)
                    wireOption.toolTip:setName(getText("ContextMenu_AddLine"))
                    wireOption.toolTip.description = getText("Tooltip_AddLine")
                end
            end
        end
    end   
end
Events.OnFillWorldObjectContextMenu.Add(CL.addWireContext)
Events.OnFillWorldObjectContextMenu.Add(CL.RemoveWireContext)