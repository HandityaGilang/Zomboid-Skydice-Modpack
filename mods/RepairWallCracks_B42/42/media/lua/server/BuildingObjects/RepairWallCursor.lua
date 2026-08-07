RepairWallCrackCursor = ISBuildingObject:derive("RepairWallCrackCursor")

local function predicateNotBroken(item)
    return not item:isBroken()
end

function RepairWallCrackCursor:doRepairWallCrackMenu(player, square)
    local inventory = player:getInventory()
    local shovel = inventory:getFirstTypeRecurse("Base.HandShovel") or
                   inventory:getFirstTypeRecurse("Base.MasonsTrowel") or
                   inventory:getFirstTypeRecurse("Base.PlasterTrowel") or
                   inventory:getFirstTypeRecurse("Base.MasonsTrowel_Wood")
    local plaster = inventory:getFirstTypeRecurse("BucketPlasterFull") or inventory:getFirstTypeRecurse("BucketCarvedPlasterFull")

    if shovel and plaster then
        if luautils.walkAdj(player, square) then
            ISWorldObjectContextMenu.transferIfNeeded(player, shovel)
            ISWorldObjectContextMenu.transferIfNeeded(player, plaster)

            ISInventoryPaneContextMenu.equipWeapon(shovel, true, false, player:getPlayerNum())

            ISTimedActionQueue.add(RepairWallCrackAction:new(player, square, 100))
        end
    end
end

function RepairWallCrackCursor:isValid(square)
    local inventory = self.character:getInventory()

    for i = 0, square:getObjects():size() - 1 do
        local object = square:getObjects():get(i);
        local attached = object:getAttachedAnimSprite()
        if attached then
            for n = 1, attached:size() do
                local sprite = attached:get(n - 1)
                if sprite and sprite:getParentSprite() and sprite:getParentSprite():getName() and
                    (luautils.stringStarts(sprite:getParentSprite():getName(), "d_wallcrack")) then
                    return inventory:containsTypeRecurse("BucketPlasterFull") or inventory:containsTypeRecurse("BucketCarvedPlasterFull") and (inventory:containsTypeRecurse("HandShovel")); --!!!
                end
            end
        end
    end

    return false
end
