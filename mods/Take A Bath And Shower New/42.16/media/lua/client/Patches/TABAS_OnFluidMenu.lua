local TABAS_OnFluidMenu = {}

local TABAS_Iso = require("TABAS_Iso")
local TABAS_MoveUtils = require("TABAS_MoveUtils")

local function canPatchWalkAdjObject(object)
    if not object or not instanceof(object, "IsoObject") then return false end
    if TABAS_Iso.isBathObject(object) or TABAS_Iso.isShowerObject(object, true) then return true end

    local objectSq = object:getSquare()
    if not objectSq then return false end

    return TABAS_Iso.getBathObjectOnSquare(objectSq) ~= nil or TABAS_Iso.getShowerObjectOnSquare(objectSq, true) ~= nil
end

local function patchWalkAdjObject(object)
    if not object then return nil end
    local objectSq = object:getSquare()
    if not objectSq then return nil end

    local oldWalkAdjObject = luautils.walkAdjObject

    luautils.walkAdjObject = function(playerObj, targetObject, allowDiagonal, keepActions)
        luautils.walkAdjObject = oldWalkAdjObject

        if not targetObject or targetObject:getSquare() ~= objectSq then
            return oldWalkAdjObject(playerObj, targetObject, allowDiagonal, keepActions)
        end

        local bathObject = TABAS_Iso.isBathObject(object) and object or TABAS_Iso.getBathObjectOnSquare(objectSq)
        if bathObject then
            return TABAS_MoveUtils.walkToAdjTub(playerObj, bathObject, keepActions, true)
        end

        local showerObject = TABAS_Iso.isShowerObject(object, true) and object or TABAS_Iso.getShowerObjectOnSquare(objectSq, true)
        if showerObject then
            return luautils.walk(playerObj, showerObject:getSquare(), keepActions)
        end

        return oldWalkAdjObject(playerObj, targetObject, allowDiagonal, keepActions)
    end

    return oldWalkAdjObject
end

local function patchWalkAdjForFluidContainer(fluidcontainer)
    local containerSq = fluidcontainer:getGameEntity():getSquare()
    if not containerSq then return end
    local object = TABAS_Iso.getBathObjectOnSquare(containerSq)
    if not object then return end

    local oldWalkAdj = luautils.walkAdj

    luautils.walkAdj = function(playerObj, square, keepActions, excludeList)
        luautils.walkAdj = oldWalkAdj
        if square ~= containerSq then
            return oldWalkAdj(playerObj, square, keepActions, excludeList)
        end
        if TABAS_Iso.isTubFluidContainer(fluidcontainer) then
            return TABAS_MoveUtils.walkToAdjTub(playerObj, object, keepActions, true)
        end
        return oldWalkAdj(playerObj, square, keepActions, excludeList)
    end

    return oldWalkAdj
end

function TABAS_OnFluidMenu.apply()
    if TABAS_OnFluidMenu._applied then return end

    TABAS_OnFluidMenu._applied = true

    -- onFluidTransfer
    local old_onFluidTransfer = ISWorldObjectContextMenu.onFluidTransfer
    ISWorldObjectContextMenu.onFluidTransfer = function(player, fluidcontainer)
        if TABAS_Iso.isTubFluidContainer(fluidcontainer) then
            patchWalkAdjForFluidContainer(fluidcontainer)
        end
        return old_onFluidTransfer(player, fluidcontainer)
    end

    -- onWashClothing
    local old_onWashClothing = ISWorldObjectContextMenu.onWashClothing
    ISWorldObjectContextMenu.onWashClothing = function(playerObj, sink, soapList, washList, singleClothing)
        if canPatchWalkAdjObject(sink) then
            patchWalkAdjObject(sink)
        end
        return old_onWashClothing(playerObj, sink, soapList, washList, singleClothing)
    end

    -- onWashYourself
    local old_onWashYourself = ISWorldObjectContextMenu.onWashYourself
    ISWorldObjectContextMenu.onWashYourself = function(playerObj, sink, soapList)
        if canPatchWalkAdjObject(sink) then
            patchWalkAdjObject(sink)
        end
        return old_onWashYourself(playerObj, sink, soapList)
    end

    -- onDrink
    local old_onDrink = ISWorldObjectContextMenu.onDrink
    ISWorldObjectContextMenu.onDrink = function(worldobjects, waterObject, player)
        if canPatchWalkAdjObject(waterObject) then
            patchWalkAdjObject(waterObject)
        end
        return old_onDrink(worldobjects, waterObject, player)
    end

    -- onTakeWater
    local old_onTakeWater = ISWorldObjectContextMenu.onTakeWater
    ISWorldObjectContextMenu.onTakeWater = function(worldobjects, waterObject, waterContainerList, waterContainer, player)
        if canPatchWalkAdjObject(waterObject) then
            patchWalkAdjObject(waterObject)
        end
        return old_onTakeWater(worldobjects, waterObject, waterContainerList, waterContainer, player)
    end
end

return TABAS_OnFluidMenu
