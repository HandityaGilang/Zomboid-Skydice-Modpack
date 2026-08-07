-- Author = ArtNod

-- Root fix: if OAC changed the sprite between right-click and dismantle click, restore the
-- original (closed) sprite before the action is created. This ensures findOnSquare() and
-- fromObject() work with the correct sprite that has CanScrap properties.

local originalDisassemble = ISDisassembleMenu.disassemble
function ISDisassembleMenu.disassemble(playerObj, _v)
    if _v and _v.object and _v.moveProps and _v.object:getSprite() then
        local currentSprite = _v.object:getSprite():getName()
        if currentSprite ~= _v.moveProps.spriteName then
            _v.object:setSpriteFromName(_v.moveProps.spriteName)
        end
    end
    originalDisassemble(playerObj, _v)
end
