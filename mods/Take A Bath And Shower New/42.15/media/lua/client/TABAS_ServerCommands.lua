if not isClient() then return end

local TABAS_ServerCommands = {}
local Commands = {}

local TABAS_Utils = require("TABAS_Utils")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_AnimVars = require("Bathing/TABAS_AnimVariables")

local noise = function(msg)
    TABAS_Utils.debugPrint("ServerCommands", msg)
end

--------------------- For TFC ---------------------
Commands.tabas_tfc = {}

Commands.tabas_tfc.setCustomColor = function(args)
    local mainObj = TFC_Utils.getTfcObject(args.x, args.y, args.z)
    local linkedObj = TFC_Utils.getTfcObject(args.linkedX, args.linkedY, args.z)
    local colroInfo = ColorInfo.new(args.r, args.g, args.b, args.a)
    if mainObj then
        mainObj:setCustomColor(colroInfo)
    end
    if linkedObj then
        linkedObj:setCustomColor(colroInfo)
    end
end

--------------------- For Bathing ---------------------
Commands.tabas_bathing = {}

Commands.tabas_bathing.syncVariables = function(args)
    local player = getPlayerByOnlineID(args.onlineID)
    if not player then return end

    TABAS_AnimVars.setVariables(player, args.animType, args)
end

TABAS_ServerCommands.OnServerCommand = function(module, command, args)
    if Commands[module] and Commands[module][command] then
        if TABAS_Utils.DEBUG_ENABLE then
            local argStr = ''
            if args then
                for k,v in pairs(args) do argStr = argStr..' '..k..'='..tostring(v) end
            end
            noise('received command '..module..' '..command..' argStr: '..argStr)
        end
        Commands[module][command](args)
    end
end
Events.OnServerCommand.Add(TABAS_ServerCommands.OnServerCommand)
