local TABAS_Utils = require "TABAS_Utils"
local TABAS_MoveUtils = require("TABAS_MoveUtils")
local TABAS_ContextMenuCommonDebug = {}

local function toggleUsing(obj)
    local sq = obj:getSquare()
    local args = {
        x = sq:getX(), y = sq:getY(), z = sq:getZ(),
        index = obj:getObjectIndex()
    }
    sendClientCommand("tabas_object", "toggleUsing", args)
end

local function resetTubEdge(faucetObj, tubObj)
    local sq = faucetObj:getSquare()
    local sq2 = tubObj:getSquare()
    if not sq or not sq2 then return end

    local args = {
        x = sq:getX(), y = sq:getY(), z = sq:getZ(), index = faucetObj:getObjectIndex(),
        lx = sq2:getX(), ly = sq2:getY(), lindex = tubObj:getObjectIndex()
    }
    sendClientCommand("tabas_object", "tubEdgeInitialize", args)
end

local function setWaterIntoContainer(container, amount, toMax)
    if type(container) == "table" then
        container = container[1]
    end
    if not container then return end
    if type(container.getFluidContainer) ~= "function" then return end

    local fc = container:getFluidContainer()
    if fc and fc:canAddFluid(Fluid.Water) then
        local sq = container:getSquare()
        local args = {
            x = sq:getX(), y = sq:getY(), z = sq:getZ(),
            index = container:getObjectIndex(),
            amount = amount,
        }
        if toMax then
            args.amount = container:getFluidCapacity()
        end
        sendClientCommand("object", "setWaterAmount", args)
    end
end

local function setWaterIntoAllContainers(containers, amount, toMax)
    if not containers or #containers == 0 then return end

    for i=1, #containers do
        local container = containers[i]
        if container then
            setWaterIntoContainer(container, amount, toMax)
        end
    end
end

local function getExternalContainerAccessSquare(playerObj, isoObj)
    local objSq = isoObj and isoObj:getSquare()
    if not objSq then return nil end

    local playerSq = playerObj and playerObj:getCurrentSquare()
    local z = playerSq and playerSq:getZ() or objSq:getZ()
    return getCell():getGridSquare(objSq:getX(), objSq:getY(), z)
end

local function openFluidInfoForIsoObject(player, isoObj, accessObj)
    if not player or not isoObj then return end

    local playerObj = getSpecificPlayer(player)

    local fluidcontainer = isoObj:getFluidContainer()
    if not fluidcontainer then
        TABAS_Utils.debugPrint("No FluidContainer on object", tostring(isoObj))
        return
    end

    local accessSq = getExternalContainerAccessSquare(playerObj, isoObj)
    if not accessSq then return end

    local canOpen = false
    if accessObj and TABAS_MoveUtils.walkToAdjTub(playerObj, accessObj, false, true) then
        canOpen = true
    else
        canOpen = luautils.walkAdj(playerObj, accessSq)
    end

    if canOpen then
        local c = ISFluidContainer:new(fluidcontainer)
        ISTimedActionQueue.add(ISFluidPanelAction:new(playerObj, c, ISFluidInfoUI))
    end
end

local function addExternalContainersDebugMenu(player, parentMenu, object)
    local WaterReader = require("TABAS_WaterReader")
    local containers = WaterReader.getExternalContainer(object)
    if not containers or not (#containers > 0) then
        parentMenu:addOption("External Containers: none", nil, nil)
        return
    end

    local cMenu = parentMenu:addOption("External Containers")
    local cSub  = ISContextMenu:getNew(parentMenu)
    parentMenu:addSubMenu(cMenu, cSub)
    local openVanillaFluidUI = function(conts, doAll)
        if not conts or #conts == 0 then return end
        if doAll then
            for i=1, #conts do
                local cont = conts[i]
                if cont then openFluidInfoForIsoObject(player, cont, object) end
            end
        else
            local cont = conts[1]
            if cont then openFluidInfoForIsoObject(player, cont, object) end
        end
    end
    -- all
    cSub:addOption("Set Water 100 (All)", containers, setWaterIntoAllContainers, 100, false)
    cSub:addOption("Set Water Max (All)",  containers, setWaterIntoAllContainers, 0, true)

    -- each 
    cSub:addOption("--- Each Container ---", nil, nil)

    for i=1, #containers do
        local cont = containers[i]
        if cont then
            local displayName = ISWorldObjectContextMenu.getMoveableDisplayName(cont)
            if not displayName then
                displayName = cont:getSpriteName() or ("*Contaier " .. tostring(i))
            end
            local amount = round(cont:getFluidAmount(), 1)
            displayName = displayName .. " (" .. tostring(amount) .. " L)"

            local eachMenu = cSub:addOption(displayName)
            local eachSub  = ISContextMenu:getNew(cSub)
            cSub:addSubMenu(eachMenu, eachSub)

            eachSub:addOption("Open FluidInfo", {cont}, openVanillaFluidUI, false)
            eachSub:addOption("Set Water 100", cont, setWaterIntoContainer, 100, false)
            eachSub:addOption("Set Water Max",  cont, setWaterIntoContainer, 0, true)
        end
    end
end

local function test(_object, _player)
    local playerObj = getSpecificPlayer(_player)
    playerObj:faceDirection(_object:getFacing())
end

local function animTestDoExt(player)
    local playerObj = getSpecificPlayer(player)
    playerObj:reportEvent("EventDoExt")
end

function TABAS_ContextMenuCommonDebug.doDebugMenu(player, object, context, tubObj)
    local mainMenu = context:addDebugOption("TABAS Debug:")
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainMenu, subMenu)

    subMenu:addOption("Toggle Using", object, toggleUsing)
    if tubObj then
        subMenu:addOption("Reset Tub Edge", object, resetTubEdge, tubObj)
    end
    subMenu:addOption("Test", object, test, player)
    subMenu:addOption("Test DoExt", player, animTestDoExt)

    if not ISFluidContainer or not ISFluidPanelAction or not ISFluidInfoUI then return subMenu end
    if object and (not object:getModData().canBeWaterPiped) then
        addExternalContainersDebugMenu(player, subMenu, object)
    end
    return subMenu
end

return TABAS_ContextMenuCommonDebug
