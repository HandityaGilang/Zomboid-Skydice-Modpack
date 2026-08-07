local TABAS_Iso = require("TABAS_Iso")

local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

local old_getInfoPanelFlagsGeneral = ISMoveableSpriteProps.getInfoPanelFlagsGeneral

function ISMoveableSpriteProps:getInfoPanelFlagsGeneral( _square, _object, _player, _mode )
    old_getInfoPanelFlagsGeneral(self, _square, _object, _player, _mode )
    if _object and TABAS_Iso.isBathObject(_object) then
        local hasTfc = TFC_Utils.hasTfcData(_square)
        if hasTfc then
            if _mode and _mode == "rotate" then
                InfoPanelFlags.canRotate = false
                InfoPanelFlags.hasWater = true
            end
            if _mode == "scrap" then
                InfoPanelFlags.hasWater = true
            end
            if _mode and _mode =="pickup" then
                InfoPanelFlags.hasWater = true
            end
        end
    end
end

local old_canPickUpMoveableInternal = ISMoveableSpriteProps.canPickUpMoveableInternal
function ISMoveableSpriteProps:canPickUpMoveableInternal( _character, _square, _object, _isMulti)
    local canPickUp = old_canPickUpMoveableInternal(self, _character, _square, _object, _isMulti)
    if _object and TABAS_Iso.isBathObject(_object) then
        local hasTfc = TFC_Utils.hasTfcData(_square)
        canPickUp = not hasTfc
    end
    return canPickUp
end

local old_canRotateMoveable = ISMoveableSpriteProps.canRotateMoveable
function ISMoveableSpriteProps:canRotateMoveable( _square, _object, _origProps)
    local canRotate = old_canRotateMoveable(self, _square, _object, _origProps)
    if _object and TABAS_Iso.isBathObject(_object) then
        local hasTfc = TFC_Utils.hasTfcData(_square)
        canRotate = not hasTfc
    end
    return canRotate
end

local old_canScrapObjectInternal = ISMoveableSpriteProps.canScrapObjectInternal
function ISMoveableSpriteProps:canScrapObjectInternal(_result, _object)
    local canScrap = old_canScrapObjectInternal(self, _result, _object)
    if _object and TABAS_Iso.isBathObject(_object) then
        local square = _object:getSquare()
        local hasTfc = TFC_Utils.hasTfcData(square)
        canScrap = not hasTfc
    end
    return canScrap
end

-- local old_pickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
-- function ISMoveableSpriteProps:pickUpMoveableInternal( _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating )

--     return old_pickUpMoveableInternal( _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating )
-- end
