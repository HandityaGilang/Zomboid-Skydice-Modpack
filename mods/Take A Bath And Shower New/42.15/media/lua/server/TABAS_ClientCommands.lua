if isClient() then return end

local TABAS_ClientCommands = {}
local Commands = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_TubEdge = require("BuildingObjects/TABAS_TubEdge")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_AnimVars = require("Bathing/TABAS_AnimVariables")
local TABAS_STubFluidContainerSystemCommand = require("TubFluidContainer/TABAS_STubFluidContainerSystemCommand")

local noise = function(msg)
    TABAS_Utils.debugPrint("ClientCommands", msg)
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

Commands.tabas_object.revertTub = function(player, args)
    local faucetObj = getObjectFromIndex(args.x, args.y, args.z, args.index)
    local tubObj = getObjectFromIndex(args.lx, args.ly, args.z, args.lindex)
    if not faucetObj or not tubObj then return end

    local modData = {isClean = nil, isImproved = nil}
    local spriteKey = "fixtures_bathroom_01"
    TABAS_ImprovedTubAction.replaceObject(faucetObj, faucetObj:getSquare(), spriteKey, modData)
    TABAS_ImprovedTubAction.replaceObject(tubObj, tubObj:getSquare(), spriteKey, modData)
end

Commands.tabas_object.revertShower = function(player, args)
    local showerObj = getObjectFromIndex(args.x, args.y, args.z, args.index)
    if not showerObj then return end

    local showerType = TABAS_Iso.getSpriteModelType("Shower", showerObj:getSpriteName())
    if showerType == "Improved Deluxe" then
        local spriteName = TABAS_ImprovedShowerAction.getNewSpriteName(showerObj, "Deluxe")
        TABAS_ImprovedShowerAction.replaceObject(showerObj, showerObj:getSquare(), spriteName,  {isImproved = nil})
    end
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
    local wornItems = player:getWornItems()
    TABAS_BathingUtils.washCleansedBody(player, wornItems, args.pct, args.factor, args.makeOff)
end

Commands.tabas_bathing.wetWornItems = function(player, args)
    local wornItems = player:getWornItems()
    TABAS_BathingUtils.wetWornItems(player, wornItems)
end

Commands.tabas_bathing.syncAnim = function(player, args)
    TABAS_AnimVars.syncAnim(player, args.animType, args, false)
end

Commands.tabas_bathing.setVariable = function(player, args)
    player:setVariable(args.variable, args.value)
end

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
