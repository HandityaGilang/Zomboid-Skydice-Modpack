-- From "Snowman" mod -- Author = carlesturo

local _orig_ISMoveableSpriteProps_pickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal

function ISMoveableSpriteProps.pickUpMoveableInternal(self, _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating)
    local item = _orig_ISMoveableSpriteProps_pickUpMoveableInternal(self, _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating)

    if not _createItem or not item then return item end

    if _spriteName == "street_decoration_01_26" then
        local inv = _character:getInventory()

        if isClient() then inv:removeItemOnServer(item) end
        inv:Remove(item)

        local newItem = inv:AddItem("Base.Mov_RoadCone")
        return newItem
    end

    return item
end