if isClient() then return end

local TABAS_ClientCommands = {}
local Commands = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_BodyGrimeUtils = require("TABAS_BodyGrimeUtils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_TubEdge = require("BuildingObjects/TABAS_TubEdge")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_AnimVars = require("Bathing/TABAS_AnimVariables")
local TABAS_STubFluidContainerSystemCommand = require("TubFluidContainer/TABAS_STubFluidContainerSystemCommand")
require "TimedActions/TABAS_ImprovedTubAction"

local noise = function(msg)
    -- TABAS_Utils.debugPrint("ClientCommands", msg)
end

--------------------- For Player ---------------------
Commands.tabas_player = {}

Commands.tabas_player.increaseWetness = function (player, args)
    if not args or not args.value then return end
    TABAS_Utils.increaseCharacterWetness(player, args.value)
end

Commands.tabas_player.decreaseWetness = function (player, args)
    if not args or not args.value then return end
    TABAS_Utils.decreaseCharacterWetness(player, args.value)
end

Commands.tabas_player.setStat = function (player, args)
    if not args or not args.statName then return end
    if CharacterStat[args.statName] == nil then return end
    player:getStats():set(CharacterStat[args.statName], args.value)
end

Commands.tabas_player.addStat = function (player, args)
    if not args or not args.statName then return end
    if CharacterStat[args.statName] == nil then return end
    player:getStats():add(CharacterStat[args.statName], args.value)
end

Commands.tabas_player.removeStat = function (player, args)
    if not args or not args.statName then return end
    if CharacterStat[args.statName] == nil then return end
    player:getStats():remove(CharacterStat[args.statName], args.value)
end

Commands.tabas_player.addFakeWorn = function(player, args)
    if not args or not args.itemType or not args.locName then return end
    TABAS_Utils.addFakeWornItem(player, args.itemType, args.locName)
end

Commands.tabas_player.removeFakeWorn = function(player, args)
    if not args or not args.locName then return end
    TABAS_Utils.removeFakeWornItem(player, args.locName)
end

Commands.tabas_player.updateBodyGrime = function(player, args)
    TABAS_BodyGrimeUtils.updateBodyGrime(player)
end

Commands.tabas_player.ensureBodyGrime = function(player, args)
    TABAS_BodyGrimeUtils.ensureBodyGrime(player)
end

Commands.tabas_player.setBodyGrime = function(player, args)
    if not args then return end
    TABAS_BodyGrimeUtils.setBodyGrime(player, args.value)
end

Commands.tabas_player.removeBodyGrime = function(player, args)
    if not args or not args.amount then return end
    TABAS_BodyGrimeUtils.removeBodyGrime(player, args.amount)
end

--------------------- For IsoObjects ---------------------
local function getObjectFromIndex(x, y, z, index)
    local sq = getCell():getGridSquare(x, y, z)
    if sq and index >= 0 and index < sq:getObjects():size() then
        local obj = sq:getObjects():get(index)
        if obj and instanceof(obj, "IsoObject") then
            return obj
        end
    else
		noise('sq is null or index is invalid')
	end
end

local function getBathObjectsFromSquares(faucetX, faucetY, tubX, tubY, z)
    local faucetSq = getCell():getGridSquare(faucetX, faucetY, z)
    local tubSq = getCell():getGridSquare(tubX, tubY, z)
    if not faucetSq or not tubSq then return nil, nil end

    local faucetObj = TABAS_Iso.getBathObjectOnSquare(faucetSq)
    local tubObj = TABAS_Iso.getBathObjectOnSquare(tubSq)
    if not faucetObj or not tubObj or not TABAS_Iso.isBathFaucet(faucetObj) then
        return nil, nil
    end
    return faucetObj, tubObj
end

local function getShowerObjectFromSquare(x, y, z)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return nil end
    return TABAS_Iso.getShowerObjectOnSquare(sq, false)
end

local function getBathtubPartInfo(object)
    if not object then return nil end
    local spriteName = object:getSpriteName()
    if not spriteName then return nil end

    local defBySprite = TABAS_Iso.getSpritesTable("Index", "BathtubDefBySprite")
    local partBySprite = TABAS_Iso.getSpritesTable("Index", "BathPartBySprite")
    local def = defBySprite and defBySprite[spriteName]
    local part = partBySprite and partBySprite[spriteName]
    if not def or not part then return nil end

    local dirKeys = { "spriteS", "spriteE", "spriteN", "spriteW" }
    for i=1, #dirKeys do
        local dir = def[dirKeys[i]]
        if type(dir) == "table" and dir[part] == spriteName then
            return def, part, dir
        end
    end
    return nil
end

local function getPairedBathSquare(object)
    if not object or not object:getSquare() then return nil end

    local props = object:getSprite() and object:getSprite():getProperties()
    local facing = props and props:has("Facing") and props:get("Facing") or object:getModData().facing
    local isExtension = props and props:has("IsGridExtensionTile")
    local dir
    if facing == "S" then
        if isExtension then dir = IsoDirections.N else dir = IsoDirections.S end
    elseif facing == "E" then
        if isExtension then dir = IsoDirections.W else dir = IsoDirections.E end
    elseif facing == "W" then
        if isExtension then dir = IsoDirections.E else dir = IsoDirections.W end
    elseif facing == "N" then
        if isExtension then dir = IsoDirections.S else dir = IsoDirections.N end
    end
    return dir and object:getSquare():getAdjacentSquare(dir) or nil
end

local function copyObjectModData(fromObj, toObj)
    if not fromObj or not toObj or not fromObj:hasModData() then return end
    local fromData = fromObj:getModData()
    local toData = toObj:getModData()
    for k, v in pairs(fromData) do
        toData[k] = v
    end
end

local function getTubModelModDataByModelType(modelType)
    local def = modelType and TABAS_Iso.getSpritesTable("Bathtub", modelType) or nil
    if not def then return nil end

    return {
        isClean = def.isClean,
        isImproved = def.isImproved,
        targetDef = def,
    }
end

local function getShowerModelModDataBySpriteName(spriteName)
    local defsBySprite = TABAS_Iso.getSpritesTable("Index", "ShowerDefBySprite")
    local def = defsBySprite and defsBySprite[spriteName]
    if not def then return nil end

    return {
        isImproved = def.isImproved,
    }
end

Commands.tabas_object = {}

Commands.tabas_object.toggleUsing = function(player, args)
    local obj = getObjectFromIndex(args.x, args.y, args.z, args.index)
    if not obj then return end

    local md = obj:getModData()
    if md then
        local using = md.using and nil or TABAS_Utils.getPlayerKey(player)
        md.using = using
        obj:transmitModData()
    end
end

-- Commands.tabas_object.addFluid = function(player, args)
--     if not args.amount then return end
--     local obj = getObjectFromIndex(args.x, args.y, args.z, args.index)
--     if not obj then return end

--     obj:addFluid(Fluid.Water, tonumber(args.amount))
-- end

Commands.tabas_object.setTubModel = function(player, args)
    if not TABAS_Utils.DEBUG_ENABLE then return end
    if not args or not args.modelType then return end

    local faucetObj, tubObj = getBathObjectsFromSquares(args.x, args.y, args.lx, args.ly, args.z)
    if not faucetObj or not tubObj then return end

    local modData = getTubModelModDataByModelType(args.modelType)
    if not modData then return false end

    TABAS_ImprovedTubAction.replaceObject(faucetObj, faucetObj:getSquare(), nil, modData)
    TABAS_ImprovedTubAction.replaceObject(tubObj, tubObj:getSquare(), nil, modData)
end

Commands.tabas_object.setShowerModel = function(player, args)
    if not TABAS_Utils.DEBUG_ENABLE then return end
    if not args or not args.spriteName then return end

    local showerObj = getShowerObjectFromSquare(args.x, args.y, args.z)
    if not showerObj then return end

    local modData = getShowerModelModDataBySpriteName(args.spriteName)
    if not modData then return false end

    TABAS_ImprovedShowerAction.replaceObject(showerObj, showerObj:getSquare(), args.spriteName, modData)
end

Commands.tabas_object.restoreOrphanBathtub = function(player, args)
    if not TABAS_Utils.DEBUG_ENABLE then return end
    if not args then return end

    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    local orphanObj = sq and TABAS_Iso.getBathObjectOnSquare(sq)
    if not orphanObj then return end

    local linkedObj = TABAS_Iso.getGridExtensionBath(orphanObj)
    if linkedObj then return end

    local def, part, dirDef = getBathtubPartInfo(orphanObj)
    local pairSq = getPairedBathSquare(orphanObj)
    if not def or not part or not dirDef or not pairSq then return end

    local pairPart = part == "faucet" and "tub" or "faucet"
    local pairSpriteName = dirDef[pairPart]
    if not pairSpriteName or not getSprite(pairSpriteName) then return end

    local existingPair = TABAS_Iso.getBathObjectOnSquare(pairSq)
    if existingPair then return end

    local pairObj = IsoObject.new(getCell(), pairSq, pairSpriteName)
    copyObjectModData(orphanObj, pairObj)
    pairObj:getModData().isClean = def.isClean
    pairObj:getModData().isImproved = def.isImproved
    pairSq:AddTileObject(pairObj)
    pairObj:transmitCompleteItemToClients()
    pairObj:transmitModData()
    triggerEvent("OnObjectAdded", pairObj)

    local faucetObj = part == "faucet" and orphanObj or pairObj
    local tubObj = part == "tub" and orphanObj or pairObj
    TABAS_TubEdge.removeTubEdgeAround(faucetObj:getSquare(), true)
    TABAS_TubEdge.removeTubEdgeAround(tubObj:getSquare(), true)
    TABAS_TubEdge.createTubEdge(faucetObj:getSquare(), faucetObj:getFacing(), true, true)
    TABAS_TubEdge.createTubEdge(tubObj:getSquare(), faucetObj:getFacing(), false, true)
    pairSq:RecalcPropertiesIfNeeded()
    orphanObj:getSquare():RecalcPropertiesIfNeeded()
end

--------------------- For Dummy Tub Edge ---------------------
Commands.tabas_object.tubEdgeReevalAt = function(player, args)
    if not args then return end
    TABAS_TubEdge.pendingAddReevalEventSq(args.x, args.y, args.z, "added")
end

Commands.tabas_object.tubEdgeInitialize = function(player, args)
    if not args then return end
    local faucetObj = getObjectFromIndex(args.x, args.y, args.z, args.index)
    local tubObj = getObjectFromIndex(args.lx, args.ly, args.z, args.lindex)
    if not faucetObj or not tubObj then return end

    local faucetSq = faucetObj:getSquare()
    local tubSq = tubObj:getSquare()
    if not faucetSq or not tubSq then return end

    TABAS_TubEdge.removeTubEdgeAround(faucetSq, true)
    TABAS_TubEdge.removeTubEdgeAround(tubSq, true)

    local facing = faucetObj:getFacing()
    TABAS_TubEdge.createTubEdge(faucetSq, facing, true, true)
    TABAS_TubEdge.createTubEdge(tubSq, facing, false, true)
end

--------------------- For Bathing System ---------------------
Commands.tabas_bathing = {}

Commands.tabas_bathing.startBathingBenefit = function(player, args)
    TABAS_BathingUtils.startBathingBenefit(player, args.mode, args.x, args.y, args.z)
end

Commands.tabas_bathing.stopBathingBenefit = function(player, args)
    TABAS_BathingUtils.stopBathingBenefit(player)
end

Commands.tabas_bathing.washCleansedBody = function(player, args)
    TABAS_BathingUtils.washCleansedBody(player, nil, args.pct, args.factor, args.makeOff)
end

Commands.tabas_bathing.wetWornItems = function(player, args)
    local wornItems = player:getWornItems()
    local increase = args.increase or 25
    TABAS_BathingUtils.wetWornItems(player, wornItems, increase)
end

Commands.tabas_bathing.showerEnded = function(player, args)
    player:setVariable("TABAS_ShowerEnded", true)
end

Commands.tabas_bathing.syncAnim = function(player, args)
    TABAS_AnimVars.syncAnim(player, args.animType, args, false)
end

-- Commands.tabas_bathing.setVariable = function(player, args)
--     player:setVariable(args.variable, args.value)
-- end

--------------------- For TFC System ---------------------

Commands.tabas_tfc = TABAS_STubFluidContainerSystemCommand.tabas_tfc

--------------------- For Debug ---------------------

Commands.tabas_debug = {}
Commands.tabas_debug.setDebugPrint = function(player, args)
    TABAS_Utils.DEBUG_PRINT = args and args.value and true or false
end

Commands.tabas_debug.removeTubEdgeAtSquare = function(player, args)
    local sq = getCell():getGridSquare(args.x, args.y, args.z)
    TABAS_TubEdge.removeTubEdgeAtSquare(sq, true)
end


TABAS_ClientCommands.OnClientCommand = function(module, command, player, args)
    if Commands[module] and Commands[module][command] then
        if TABAS_Utils.DEBUG_ENABLE then
            local argStr = ''
            if args then
                for k,v in pairs(args) do argStr = argStr..' '..k..'='..tostring(v) end
            end
            noise('received '..module..' '..command..' '..tostring(player)..argStr)
        end
        Commands[module][command](player, args)
    end
end

Events.OnClientCommand.Add(TABAS_ClientCommands.OnClientCommand)
