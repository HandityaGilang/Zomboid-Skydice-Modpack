require "WPUtils"
require "WPIso"
require "PFA_GMD"

local PFATAFillFuelBarrel = require("Actions/PFATAFillFuelBarrel")
local PFATASiphonFuelBarrel = require("Actions/PFATASiphonFuelBarrel")

-- mirrors vanilla ISWorldObjectContextMenu's own local predicatePetrolNotFull
local function isFuelCanNotFull(item)
    return (item:hasTag("Petrol") or item:getType() == "PetrolCan") and item:getUsedDelta() < 1
end

local function timedFillFuelBarrel(playerObj, square, object, x, y, z)
    if luautils.walkAdj(playerObj, square) then
        ISTimedActionQueue.add(PFATAFillFuelBarrel:new(playerObj, square, object, x, y, z))
    end
end

local function timedSiphonFuelBarrel(playerObj, square, object, x, y, z)
    if luautils.walkAdj(playerObj, square) then
        ISTimedActionQueue.add(PFATASiphonFuelBarrel:new(playerObj, square, object, x, y, z))
    end
end

local function onPreFillWorldObjectContextMenu(player, context, worldobjects, test)
    local fetch = ISWorldObjectContextMenu.fetchVars
    local square = fetch.clickedSquare
    if not square then return end

    local playerObj = getSpecificPlayer(player)
    local playerInv = playerObj:getInventory()
    local sx, sy, sz = square:getX(), square:getY(), square:getZ()

    local isoBarrel = WPIso.GetBarrel(square)
    if not isoBarrel then return end

    local pgmd = GetPFAModData()
    local coordId = WPUtils.Coords2Id(sx, sy, sz)
    local flowing = pgmd.FuelPipes[coordId]
    local barrel = pgmd.FuelBarrels[coordId]

    if flowing and flowing > 0 then
        local optionFill = context:addOption(getText("ContextMenu_PFA_FillBarrelFuel"), playerObj, timedFillFuelBarrel, square, isoBarrel, sx, sy, sz)
        if barrel and barrel.amount >= barrel.max then
            optionFill.notAvailable = true
            local tooltipFull = ISToolTip:new()
            tooltipFull.description = getText("Tooltip_PFA_BarrelFull")
            optionFill.toolTip = tooltipFull
        end
    end

    if barrel and barrel.amount > 0 then
        if playerInv:containsEvalRecurse(isFuelCanNotFull) then
            local optionSiphon = context:addOption(getText("ContextMenu_PFA_SiphonBarrelFuel"), playerObj, timedSiphonFuelBarrel, square, isoBarrel, sx, sy, sz)
        end

        local tooltipBarrel = ISToolTip:new()
        tooltipBarrel:setName(getText("ContextMenu_PFA_FuelBarrelInfo"))
        tooltipBarrel.description = getText("Tooltip_PFA_FuelBarrelLevel", math.floor(barrel.amount), math.floor(barrel.max))
        local optionInfo = context:addOption(getText("ContextMenu_PFA_FuelBarrelInfo"), nil, nil)
        optionInfo.notAvailable = true
        optionInfo.toolTip = tooltipBarrel
    end
end

Events.OnPreFillWorldObjectContextMenu.Add(onPreFillWorldObjectContextMenu)
