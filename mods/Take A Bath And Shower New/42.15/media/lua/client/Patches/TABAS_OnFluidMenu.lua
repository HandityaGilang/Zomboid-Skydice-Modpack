local TABAS_OnFluidMenu = {}

local TABAS_Iso = require("TABAS_Iso")
local TABAS_MoveUtils = require("TABAS_MoveUtils")

local function patchWalkAdj(object)
    local objectSq = object:getSquare()
    if not objectSq then return nil end

    local oldWalkAdj = luautils.walkAdj

    luautils.walkAdj = function(playerObj, square, keepActions, excludeList)
        luautils.walkAdj = oldWalkAdj
        if square ~= objectSq then
            return oldWalkAdj(playerObj, square, keepActions, excludeList)
        end

        if TABAS_Iso.isBathObject(object) then
            return TABAS_MoveUtils.walkToAdjTub(playerObj, object, keepActions, true)
        end
        if TABAS_Iso.isShowerObject(object) then
            return luautils.walk(playerObj, square, keepActions)
        end

        return oldWalkAdj(playerObj, square, keepActions, excludeList)
    end

    return oldWalkAdj
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
    ISWorldObjectContextMenu.onWashClothing = function(playerObj, sink, soapList, washList, singleClothing, noSoap)
        if TABAS_Iso.isBathObject(sink) or TABAS_Iso.isShowerObject(sink) then
            patchWalkAdj(sink)
        end
        return old_onWashClothing(playerObj, sink, soapList, washList, singleClothing, noSoap)
    end

    -- onWashYourself
    local old_onWashYourself = ISWorldObjectContextMenu.onWashYourself
    ISWorldObjectContextMenu.onWashYourself = function(playerObj, sink, soapList)
        if TABAS_Iso.isBathObject(sink) or TABAS_Iso.isShowerObject(sink) then
            patchWalkAdj(sink)
        end
        return old_onWashYourself(playerObj, sink, soapList)
    end

    -- onDrink
    local old_onDrink = ISWorldObjectContextMenu.onDrink
    ISWorldObjectContextMenu.onDrink = function(worldobjects, waterObject, player)
        if TABAS_Iso.isBathObject(waterObject) or TABAS_Iso.isShowerObject(waterObject) then
            patchWalkAdj(waterObject)
        end
        return old_onDrink(worldobjects, waterObject, player)
    end

    -- onTakeWater
    local old_onTakeWater = ISWorldObjectContextMenu.onTakeWater
    ISWorldObjectContextMenu.onTakeWater = function(worldobjects, waterObject, waterContainerList, waterContainer, player)
        if TABAS_Iso.isBathObject(waterObject) or TABAS_Iso.isShowerObject(waterObject) then
            patchWalkAdj(waterObject)
        end
        return old_onTakeWater(worldobjects, waterObject, waterContainerList, waterContainer, player)
    end
end

return TABAS_OnFluidMenu
