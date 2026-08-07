-- From "Open All Containers [B42]" mod -- Author = carlesturo

local OAC_SpriteData = require("OAC_SpriteData")

local OAC_Utils = {}

-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - UTILS ****************

function OAC_Utils.isModActivated(modSubstring)
    local mods = getActivatedMods()
    for i = 0, mods:size() - 1 do
        local mod = tostring(mods:get(i))
        if mod:find(modSubstring) then
            return true
        end
    end
    return false
end

function OAC_Utils.toggleAutoCloseForContainer(obj, spriteData)
    local modData = obj:getModData()
    local enableAutoClose = not modData.forceAutoClose

    if enableAutoClose then
        modData.forceAutoClose = true
    else
        modData.forceAutoClose = nil
    end

    if spriteData.isPaired and spriteData.pairedOffset then
        local sq = obj:getSquare()
		local pairedSquare = getCell():getGridSquare(sq:getX() + spriteData.pairedOffset.x, sq:getY() + spriteData.pairedOffset.y, sq:getZ())
        if pairedSquare then
            local pairedObjects = pairedSquare:getObjects()
            for k = 0, pairedObjects:size() - 1 do
                local pairedObj = pairedObjects:get(k)
                if pairedObj and pairedObj:getSprite() then
                    local pairedSpriteName = pairedObj:getSprite():getName()
                    local pairedData = OAC_SpriteData.getSpriteDataByOriginalSprite(pairedSpriteName)
                    if pairedData and OAC_SpriteData.SpritePairs[spriteData.originalSprite] == pairedSpriteName then
                        local pairedModData = pairedObj:getModData()
                        if enableAutoClose then
                            pairedModData.forceAutoClose = true
                        else
                            pairedModData.forceAutoClose = nil
                        end
                        return
                    end
                end
            end
        end
    end
end

function OAC_Utils.playContainerSound(obj, spriteData, action)
    if not obj or not spriteData or not spriteData.soundBase then return end

    local soundEvent
    if action == "open" and spriteData.soundOpen then
        soundEvent = spriteData.soundBase .. "/" .. spriteData.soundOpen
    elseif action == "close" and spriteData.soundClose then
        soundEvent = spriteData.soundBase .. "/" .. spriteData.soundClose
    else
        return
    end

	local square = obj:getSquare()
    local emitter = getWorld():getFreeEmitter(square:getX(), square:getY(), square:getZ())
    emitter:playSound(soundEvent)
    emitter:setVolumeAll(1.0)
end

function OAC_Utils.saveAndRemoveOriginalTileOverlay(obj) -- Save and Remove Original Tile Overlay
    local modData = obj:getModData()
    local savedOverlay = nil

    local childSprites = obj:getChildSprites()
    local overlaySprite = obj:getOverlaySprite()
    local hasAnim = obj:hasAttachedAnimSprites()

    if childSprites and childSprites:size() > 0 then
        local firstChild = childSprites:get(0)
        if firstChild and firstChild:getName() then
            savedOverlay = firstChild:getName()
        end
        obj:setChildSprites(nil)

    elseif overlaySprite then
        savedOverlay = overlaySprite:getName()
        obj:setOverlaySprite(nil)

    elseif hasAnim then
        local animSprite = obj:getAttachedAnimSprite()
        if animSprite and animSprite:getName() then
            savedOverlay = animSprite:getName()
        end
        obj:setAttachedAnimSprite(nil)
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
            local sprite = IsoSpriteManager.instance:getSprite(newTileOverlay)
            if sprite then
                obj:addAttachedAnimSprite(sprite)
            end
        end
    end

    obj:transmitUpdatedSprite()
    obj:transmitModData()
end

function OAC_Utils.restoreOriginalTileOverlay(obj) -- Restore Original Tile Overlay
	local modData = obj:getModData()

	obj:setOverlaySprite(nil)
    if obj:hasAttachedAnimSprites() then
        obj:setAttachedAnimSprite(nil)
    end

    if modData.originalTileOverlay then
        local sprite = IsoSpriteManager.instance:getSprite(modData.originalTileOverlay)
        if sprite then
            obj:addAttachedAnimSprite(sprite)
        end
        modData.originalTileOverlay = nil
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