-- From "Open All Containers [B41]" mod -- Author = carlesturo

local OAC_Utils = {}

-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - UTILS ****************

function OAC_Utils.saveAndRemoveOriginalTileOverlay(obj) -- Save and Remove Original Tile Overlay
    local modData = obj:getModData()
    local savedOverlay = nil

    local childSprites = obj:getChildSprites()
    if childSprites and childSprites:size() > 0 then
        local firstChild = childSprites:get(0)
        if firstChild and firstChild:getName() then
            savedOverlay = firstChild:getName()
        end
        obj:setChildSprites(nil)

    else
        local overlaySprite = obj:getOverlaySprite()
        if overlaySprite then
            savedOverlay = overlaySprite:getName()
            obj:setOverlaySprite(nil)
        end
    end

    if savedOverlay then
        modData.originalTileOverlay = savedOverlay
    end

    obj:transmitUpdatedSprite()
    obj:transmitModData()
end

function OAC_Utils.applyNewTileOverlay(obj, spriteData, overlayKey) -- Apply New Tile Overlay
    local modData = obj:getModData()
    local originalTileOverlay = modData.originalTileOverlay
    if not originalTileOverlay then
        return
    end

    local overlayTable = spriteData[overlayKey]
    if overlayTable then
        local newTileOverlay = overlayTable[originalTileOverlay]
        if newTileOverlay then
            obj:setOverlaySprite(newTileOverlay)
		end
    end

	obj:transmitUpdatedSprite()
	obj:transmitModData()
end

function OAC_Utils.restoreOriginalTileOverlay(obj) -- Restore Original Tile Overlay
	local modData = obj:getModData()
	if modData.originalTileOverlay then
		obj:setOverlaySprite(modData.originalTileOverlay)
		modData.originalTileOverlay = nil
	else
		obj:setOverlaySprite(nil)
	end

	obj:transmitUpdatedSprite()
	obj:transmitModData()
end

function OAC_Utils.replaceAllObjectsBySprite(square, oldSpriteName, newSpriteName) -- Replace All Objects by Sprite
    local objects = square:getObjects()
    local objectsToReplace = {}

    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and obj:getSprite() and obj:getSprite():getName() == oldSpriteName then
            table.insert(objectsToReplace, obj)
        end
    end

    for _, obj in ipairs(objectsToReplace) do
        obj:setSpriteFromName(newSpriteName)
		obj:transmitUpdatedSpriteToServer()
    end
end

function OAC_Utils.removeAllObjectsBySprite(square, spriteName) -- Remove All Objects by Sprite
    local objects = square:getObjects()
    local objectsToRemove = {}

    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and obj:getSprite() and obj:getSprite():getName() == spriteName then
            table.insert(objectsToRemove, obj)
        end
    end

    for _, obj in ipairs(objectsToRemove) do
        square:transmitRemoveItemFromSquare(obj)
    end

    return #objectsToRemove > 0
end

function OAC_Utils.addObjectToSquare(square, spriteName) -- Add Object to Square
    local newObj = IsoObject.new(square, spriteName, nil, false)
    square:AddTileObject(newObj)
	newObj:transmitCompleteItemToServer()
end

function OAC_Utils.removeAllAndAddObjectInSquare(square, oldSpriteName, newSpriteName) -- Remove All and Add Object in Square
    if OAC_Utils.removeAllObjectsBySprite(square, oldSpriteName) then
        OAC_Utils.addObjectToSquare(square, newSpriteName)
    end
end

-- ------------------------------------------------------------------------------------------------

return OAC_Utils